#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util;
use Time::HiRes qw[ time sleep ];

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

            CALL
            RETURN

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

        sub is_opcode ($opcode) { exists $OPCODES{$opcode} }
    }
}

class VM {

    use constant DEBUG => $ENV{DEBUG} // 0;

    field $code :param;
    field $pc   :param;

    field @stack;
    field @locals;

    field $ic = 0;
    field $fp = 0;
    field $sp = -1;

    method PUSH ($v) { $stack[++$sp] = $v }
    method POP       { $stack[$sp--]      }

    method next_op { $code->[$pc++] }

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
        my @out;

        push @out =>         '╭─────────────────────────╮ ╭─────────────╮';
        push @out => sprintf '│ Program         ic:%04d │ │ Stack       │', $ic;
        push @out =>         '├─────────────────────────┤ ├─────────────┤';
        foreach my $i ( 0 .. $#{$code} ) {
            if (($pc - 1) == $i) {
                push @out =>
                    sprintf "│ \e[1m\e[0;33m%04d ▶ %-16s\e[0m │" =>
                        $i,
                        $code->[$i];
            } else {
                push @out =>
                    sprintf "│ %04d ┊ %s │" =>
                        $i,
                        VM::Inst::is_opcode($code->[$i])
                            ? (sprintf "\e[0;36m%-16s\e[0m" => $code->[$i])
                            : (sprintf "\e[0;34m%16s\e[0m" => $code->[$i]);
            }

        }
        push @out => '╰─────────────────────────╯';

        foreach my $i ( 0 .. $#stack ) {
            $out[ $i + 3 ] .= sprintf ' │ %05d %s%s│' =>
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
                        ? "\e[0;33m\e[1m\e[4m%5s\e[0m"
                        : ($i == $fp
                            ? "\e[0;32m\e[1m\e[4m%5s\e[0m"
                            : ($i < $sp
                                ? ($i > $fp ? "\e[0;33m\e[1m%5s\e[0m" : "\e[0;36m%5s\e[0m")
                                : "\e[0;35m%5s\e[0m"))),
                        is_bool($stack[$i])
                            ? ($stack[$i] ? '#t' : '#f')
                            : $stack[$i]
                    )),
                ;
        }
        $out[ $#stack + 4 ] .= ' ╰─────────────╯';

        warn "\e[2J\e[H\n";
        warn join "\n" => @out, "\n";
        Time::HiRes::sleep(0.3);
    }

    method run {

        while (1) {
            my $opcode = $self->next_op;

            last unless defined $opcode;

            $self->DEBUGGER if DEBUG;

            if ($opcode == VM::Inst->HALT) {
                last;
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
                # TODO : handle div by zero error here
                $self->PUSH( $a / $b );
            } elsif ($opcode == VM::Inst->MOD_INT || $opcode == VM::Inst->MOD_FLOAT) {
                my $b = $self->POP;
                my $a = $self->POP;
                # TODO : handle div by zero error here
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
            elsif ($opcode == VM::Inst->CALL) {
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
            ## System Calls
            ## ------------------------------------
            elsif ($opcode == VM::Inst->PRINT) {
                my $v = $self->POP;
                say $v;
            } elsif ($opcode == VM::Inst->WARN) {
                my $v = $self->POP;
                warn "$v\n";
            }
            ## ------------------------------------
            else {
                die "OPCODE($opcode)";
            }

            $ic++;
        }
    }

}



my $start = time;

my $fib = 0;
my $vm = VM->new(
    pc   => 38,
    code => [
        VM::Inst->LOAD, -3,
        VM::Inst->CONST_INT, 0,
        VM::Inst->EQ_INT,
        VM::Inst->JUMP_IF_FALSE, 10,
        VM::Inst->CONST_INT, 0,
        VM::Inst->RETURN,

        VM::Inst->LOAD, -3,
        VM::Inst->CONST_INT, 3,
        VM::Inst->LT_INT,
        VM::Inst->JUMP_IF_FALSE, 20,
        VM::Inst->CONST_INT, 1,
        VM::Inst->RETURN,

        VM::Inst->LOAD, -3,
        VM::Inst->CONST_INT, 1,
        VM::Inst->SUB_INT,
        VM::Inst->CALL, $fib, 1,

        VM::Inst->LOAD, -3,
        VM::Inst->CONST_INT, 2,
        VM::Inst->SUB_INT,
        VM::Inst->CALL, $fib, 1,

        VM::Inst->ADD_INT,
        VM::Inst->RETURN,

        VM::Inst->CONST_INT, 5,
        VM::Inst->CALL, $fib, 1,
        VM::Inst->PRINT,
        VM::Inst->HALT
    ]
)->run;
say $start - time();

sub fibonacci ($number) {
    if ($number < 2) { # base case
        return $number;
    }
    return fibonacci($number-1) + fibonacci($number-2);
}

$start = time();
say "PERL: ", fibonacci(5);
say $start - time();




