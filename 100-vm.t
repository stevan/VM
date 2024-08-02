#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util;
use Time::HiRes qw[ time sleep ];

package VM::Errors {

    our @ERRORS;
    BEGIN {
        @ERRORS = qw(
            UNKNOWN_OPCODE
            ILLEGAL_DIVISION_BY_ZERO
            UNEXPECTED_END_OF_CODE
            ILLEGAL_MOD_BY_ZERO
        );

        foreach my $i (0 .. $#ERRORS) {
            no strict 'refs';
            my $error = $ERRORS[$i];
            $ERRORS[$i] = Scalar::Util::dualvar( $i, $error );
            *{__PACKAGE__."::${error}"} = sub { $ERRORS[$i] };
        }
    }
}

package VM::Inst {

    our @OPCODES;
    our %OPCODES;
    BEGIN {
        @OPCODES = qw(
            NOOP

            CONST_TRUE
            CONST_FALSE

            CONST_INT
            CONST_FLOAT
            CONST_STR

            ADD_INT  ADD_FLOAT
            SUB_INT  SUB_FLOAT
            MUL_INT  MUL_FLOAT
            DIV_INT  DIV_FLOAT
            MOD_INT  MOD_FLOAT

            CONCAT_STR

            LT_INT   LT_FLOAT   LT_STR
            GT_INT   GT_FLOAT   GT_STR
            EQ_INT   EQ_FLOAT   EQ_STR

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            LOAD
            STORE

            LOAD_ARG
            CALL
            RETURN

            DUP
            POP
            SWAP

            PRINT
            WARN

            HALT
        );


        foreach my $i (0 .. $#OPCODES) {
            no strict 'refs';
            my $opcode = $OPCODES[$i];
            $OPCODES[$i] = Scalar::Util::dualvar( $i, $opcode );
            $OPCODES{$opcode} = $OPCODES[$i];
            *{__PACKAGE__."::${opcode}"} = sub { $OPCODES[$i] };
        }
    }

    sub is_opcode ($opcode) { exists $OPCODES{$opcode} }

    class VM::Inst::Label  { field $name :param :reader }
    class VM::Inst::Marker { field $name :param :reader }

    sub label  ($, $name) { VM::Inst::Label ->new( name => $name ) }
    sub marker ($, $name) { VM::Inst::Marker->new( name => $name ) }

}

class VM {

    use constant DEBUG => $ENV{DEBUG} // 0;

    field $source :param;
    field $entry  :param;
    field $clock  :param = 0.03;

    field @code;
    field @stack;
    field %labels;

    field @stdout;
    field @stderr;

    field $pc = 0;  # program counter (points to current instruction)
    field $ic = 0;  # instruction counter (number of instructions run)
    field $fp = 0;  # frame pointer (points to the top of the current stack frame)
    field $sp = -1; # stack pointer (points to the current head of the stack)

    field $running = false;
    field $error   = undef;

    method PUSH ($v) { $stack[++$sp] = $v }
    method POP       { $stack[$sp--]      }
    method PEEK      { $stack[$sp]        }

    method next_op { $code[$pc++] }

=pod

\e[0;30m    Black
\e[0;31m    Red
\e[0;32m    Green
\e[0;33m    Yellow
\e[0;34m    Blue
\e[0;35m    Purple
\e[0;36m    Cyan
\e[0;37m    White

\e[1m       Bold
\e[4m       Underline
\e[9m       Strikethrough
\e[0m       Reset

=cut

    method DEBUGGER {

        my %rev_labels = reverse %labels;

        my @out;

        push @out =>         '╭─────────────────────────╮ ╭─────────────────────────╮ ╭─────────────────────────────────╮';
        push @out => sprintf "│ Program         ic:%04d │ │ Stack                   │ │ Error \e[0;31m\e[1m%25s\e[0m │", $ic, $error // '';
        push @out =>         '├─────────────────────────┤ ├─────────────────────────┤ ╰─────────────────────────────────╯';
        foreach my $i ( 0 .. $#code ) {

            if (my $label = $rev_labels{$i}) {
                push @out =>         "├─────────────────────────┤" unless $i == 0;
                push @out => sprintf "│ \e[0;36m\e[1m%-23s\e[0m │" => $label;
                push @out =>         "├─────────────────────────┤";
            }

            if (($pc - 1) == $i) {
                push @out =>
                    sprintf "│ \e[0;33m\e[1m%04d ▶ %-16s\e[0m │" =>
                        $i,
                        $code[$i];
            } else {
                push @out =>
                    sprintf "│ %04d ┊ %s │" =>
                        $i,
                        VM::Inst::is_opcode($code[$i])
                            ? (sprintf "\e[0;32m\e[3m%-16s\e[0m" => $code[$i])
                            : exists $labels{"".$code[$i]}
                                ? (sprintf "\e[0;36m%16s\e[0m" => $code[$i])
                                : (sprintf "\e[0;34m%16s\e[0m" =>
                                    Scalar::Util::looks_like_number($code[$i])
                                        ? $code[$i]
                                        : '"'.$code[$i].'"');
            }

        }
        push @out => '╰─────────────────────────╯';

        foreach my $i ( 0 .. $#stack ) {
            $out[ $i + 3 ] .= sprintf ' │ %05d %s%s │' =>
                $i,
                ($i == $fp && $i == $sp
                    ? '▶'
                    : $i == $fp
                        ? '▷'
                        : $i == $sp
                            ? '▷'
                            : '┊'),,
                (sprintf(
                    ($i == $sp
                        ? "\e[0;33m\e[4m\e[1m%16s\e[0m"
                        : ($i == $fp
                            ? "\e[0;32m\e[4m\e[1m%16s\e[0m"
                            : ($i < $sp
                                ? ($i > $fp ? "\e[0;33m\e[1m%16s\e[0m" : "\e[0;36m%16s\e[0m")
                                : "\e[0;36m\e[2m%16s\e[0m"))),
                        is_bool($stack[$i])
                            ? ($stack[$i] ? '#t' : '#f')
                            : Scalar::Util::looks_like_number($stack[$i])
                                ? $stack[$i]
                                : '"'.$stack[$i].'"'
                    )),
                ;
        }
        $out[ $#stack + 4 ] .= ' ╰─────────────────────────╯';


        $out[ 3 ] .= ' ╭─────────────────────────────────╮';
        $out[ 4 ] .= ' │ STDOUT                          │';
        $out[ 5 ] .= ' ├─────────────────────────────────┤';
        foreach my $i ( 0 .. $#stdout ) {
            $out[ $i + 6 ] .= sprintf " │ \e[0;32m%-31s\e[0m │" => $stdout[$i];
        }
        $out[ $#stdout + 7 ] .= ' ╰─────────────────────────────────╯';

        my $offset = $#stdout + 8;

        $out[ $offset ] .= ' ╭─────────────────────────────────╮';
        $out[ $offset + 1 ] .= ' │ STDERR                          │';
        $out[ $offset + 2 ] .= ' ├─────────────────────────────────┤';
        foreach my $i ( 0 .. $#stderr ) {
            $out[ $i + $offset + 3 ] .= sprintf " │ \e[0;31m%-31s\e[0m │" => $stderr[$i];
        }
        $out[ $#stderr + $offset + 4 ] .= ' ╰─────────────────────────────────╯';

        warn "\e[2J\e[H\n";
        warn join "\n" => @out, "\n";
    }

    method compile {

        my $i = 0;
        foreach my $line (@$source) {
            if (blessed $line && $line isa VM::Inst::Label) {
                $labels{$line->name} = $i;
            }
            else {
                $i++;
            }
        }

        $i = 0;
        foreach my $line (@$source) {
            if (blessed $line) {
                if ( $line isa VM::Inst::Marker ) {
                    $labels{$line->name}
                        // die "Could not find label for marker(".$line->name.")";
                    $i++;
                    push @code => Scalar::Util::dualvar(
                        $labels{$line->name},
                        $line->name
                    );
                }
            }
            else {
                $i++;
                push @code => $line;
            }
        }

        $pc = $labels{ $entry } // die "Could not find entry point($entry) in source";

        return $self;
    }

    method run {

        $error   = undef;
        $running = true;

        while ($running) {
            my $opcode = $self->next_op;

            unless (defined $opcode) {
                $error   = VM::Errors->UNEXPECTED_END_OF_CODE;
                goto ERROR;
            }

            if ($opcode == VM::Inst->HALT) {
                $running = false;
            }
            ## ------------------------------------
            ## Constants
            ## ------------------------------------
            elsif ($opcode == VM::Inst->CONST_TRUE) {
                $self->PUSH(true);
            } elsif ($opcode == VM::Inst->CONST_FALSE) {
                $self->PUSH(false);
            } elsif ($opcode == VM::Inst->CONST_INT || $opcode == VM::Inst->CONST_FLOAT || $opcode == VM::Inst->CONST_STR) {
                my $v = $self->next_op;
                $self->PUSH($v);
            }
            ## ------------------------------------
            ## MATH
            ## ------------------------------------
            elsif ($opcode == VM::Inst->ADD_INT || $opcode == VM::Inst->ADD_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a + $b );
            } elsif ($opcode == VM::Inst->SUB_INT || $opcode == VM::Inst->SUB_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a - $b );
            } elsif ($opcode == VM::Inst->MUL_INT || $opcode == VM::Inst->MUL_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a * $b );
            } elsif ($opcode == VM::Inst->DIV_INT || $opcode == VM::Inst->DIV_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                if ( $b == 0 ) {
                    $error   = VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
                    goto ERROR;
                }
                # TODO : handle div by zero error here
                $self->PUSH( $a / $b );
            } elsif ($opcode == VM::Inst->MOD_INT || $opcode == VM::Inst->MOD_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                if ( $b == 0 ) {
                    $error   = VM::Errors->ILLEGAL_MOD_BY_ZERO;
                    goto ERROR;
                }
                $self->PUSH( $a % $b );
            }
            ## ------------------------------------
            ## String Operations
            ## ------------------------------------
            elsif ($opcode == VM::Inst->CONCAT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a . $b );
            }
            ## ------------------------------------
            ## Compariosons
            ## ------------------------------------
            elsif ($opcode == VM::Inst->LT_INT || $opcode == VM::Inst->LT_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a < $b ? true : false );
            } elsif ($opcode == VM::Inst->GT_INT || $opcode == VM::Inst->GT_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a > $b ? true : false );
            } elsif ($opcode == VM::Inst->EQ_INT || $opcode == VM::Inst->EQ_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a == $b ? true : false );
            }
            # ... for strings
            elsif ($opcode == VM::Inst->LT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a lt $b ? true : false );
            } elsif ($opcode == VM::Inst->GT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a gt $b ? true : false );
            } elsif ($opcode == VM::Inst->EQ_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a eq $b ? true : false );
            }
            ## ------------------------------------
            ## Conditionals
            ## ------------------------------------
            elsif ($opcode == VM::Inst->JUMP) {
                $pc = $self->next_op;
            } elsif ($opcode == VM::Inst->JUMP_IF_TRUE) {
                my $addr = $self->next_op;
                if ($self->POP == true) {
                    $pc = $addr;
                }
            } elsif ($opcode == VM::Inst->JUMP_IF_FALSE) {
                my $addr = $self->next_op;
                if ($self->POP == false) {
                    $pc = $addr;
                }
            }
            ## ------------------------------------
            ## Load/Store local memory
            ## ------------------------------------
            elsif ($opcode == VM::Inst->LOAD) {
                my $offset = $self->next_op;
                $self->PUSH( $stack[$fp + $offset] );
            } elsif ($opcode == VM::Inst->STORE) {
                my $v      = $self->POP;
                my $offset = $self->next_op;
                $stack[$fp + $offset] = $v;
            }
            ## ------------------------------------
            ## Call functions
            ## ------------------------------------
            elsif ($opcode == VM::Inst->LOAD_ARG) {
                my $offset = $self->next_op;
                $self->PUSH( $stack[($fp - 3) - $offset] );
            } elsif ($opcode == VM::Inst->CALL) {
                my $addr = $self->next_op; # func address to go to
                my $argc = $self->next_op; # number of args the function has ...
                # stash the context ...
                $self->PUSH($argc);
                $self->PUSH($fp);
                $self->PUSH($pc);
                # set the new context ...
                $fp = $sp;   # set the new frame pointer
                $pc = $addr; # and the program counter to the func addr

            } elsif ($opcode == VM::Inst->RETURN) {
                my $rval = $self->POP;  # get the return value
                   $sp   = $fp;         # restore stack pointer
                   $pc   = $self->POP;  # get the stashed program counter
                   $fp   = $self->POP;  # get the stashed program frame pointer
                my $argc = $self->POP;  # get the number of args
                   $sp  -= $argc;       # decrement stack pointer by num args
                $self->PUSH($rval);     # push the return value onto the stack
            }
            ## ------------------------------------
            ## Stack Manipulation
            ## ------------------------------------
            elsif ($opcode == VM::Inst->DUP) {
                $self->PUSH($self->PEEK);
            } elsif ($opcode == VM::Inst->POP) {
                $self->POP;
            } elsif ($opcode == VM::Inst->SWAP) {
                my $v1 = $self->POP;
                my $v2 = $self->POP;
                $self->PUSH($v1);
                $self->PUSH($v2);
            }
            ## ------------------------------------
            ## System Calls
            ## ------------------------------------
            elsif ($opcode == VM::Inst->PRINT) {
                my $v = $self->POP;
                push @stdout => $v;
            } elsif ($opcode == VM::Inst->WARN) {
                my $v = $self->POP;
                push @stderr => $v;
            }
            ## ------------------------------------
            else {
                $error   = VM::Errors->UNKNOWN_OPCODE;
                goto ERROR;
            }

            $ic++;

            Time::HiRes::sleep( $clock );

        ERROR:
            if ($error) {
                $running = false;
            }

            $self->DEBUGGER if DEBUG;
        }
    }

}

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.fib'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 0,
            VM::Inst->EQ_INT,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib1'),
            VM::Inst->CONST_INT, 0,
            VM::Inst->CONST_STR, "RETURNING 0",
            VM::Inst->WARN,
            VM::Inst->RETURN,
        VM::Inst->label('.fib1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 3,
            VM::Inst->LT_INT,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib2'),
            VM::Inst->CONST_INT, 1,
            VM::Inst->CONST_STR, "RETURNING 1",
            VM::Inst->WARN,
            VM::Inst->RETURN,
        VM::Inst->label('.fib2'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 1,
            VM::Inst->SUB_INT,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 2,
            VM::Inst->SUB_INT,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->ADD_INT,

            VM::Inst->DUP,
            VM::Inst->CONST_STR, "RETURNING ",
            VM::Inst->SWAP,
            VM::Inst->CONCAT_STR,
            VM::Inst->WARN,

            VM::Inst->RETURN,

        VM::Inst->label('.main'),
            VM::Inst->CONST_STR, "VM: ",
            VM::Inst->CONST_INT, 5,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,
            VM::Inst->CONCAT_STR,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->compile->run;


sub fibonacci ($number) {
    if ($number < 2) { # base case
        return $number;
    }
    return fibonacci($number-1) + fibonacci($number-2);
}

say "PERL: ", fibonacci(5);




