#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

use VM::Debugger;

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    field $source  :param;
    field $entry   :param;
    field $clock   :param = $ENV{CLOCK};

    field @code    :reader;
    field @stack   :reader;
    field %labels  :reader;

    field @stdout  :reader;
    field @stderr  :reader;

    field $pc      :reader = 0;  # program counter (points to current instruction)
    field $ic      :reader = 0;  # instruction counter (number of instructions run)
    field $fp      :reader = 0;  # frame pointer (points to the top of the current stack frame)
    field $sp      :reader = -1; # stack pointer (points to the current head of the stack)

    field $running :reader = false;
    field $error   :reader = undef;

    method PUSH ($v) { $stack[++$sp] = $v }
    method POP       { $stack[$sp--]      }
    method PEEK      { $stack[$sp]        }

    method next_op { $code[$pc++] }

    method DEBUGGER {
        my $ui = VM::Debugger::UI::Zipped->new(
            elements => [
                VM::Debugger::UI::StackView->new(
                    vm    => $self,
                    width => 32,
                    title => 'Stack'
                ),
                VM::Debugger::UI::CodeView->new(
                    vm    => $self,
                    width => 32,
                    title => 'Code'
                ),
                VM::Debugger::UI::Stacked->new(
                    elements => [
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'Error',
                            contents => [ $error ]
                        ),
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'STDOUT',
                            contents => [ @stdout ]
                        ),
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'STDERR',
                            contents => [ @stderr ]
                        ),
                    ]
                )
            ]
        );

        warn "\e[2J\e[H\n";
        warn join "\n" => $ui->draw, "\n";
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

            if (DEBUG) {
                $self->DEBUGGER;
                if ($clock) {
                    Time::HiRes::sleep( $clock );
                } else {
                    my $x = <>;
                }
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
            } elsif ($opcode == VM::Inst->CONST_NUM || $opcode == VM::Inst->CONST_STR) {
                my $v = $self->next_op;
                $self->PUSH($v);
            }
            ## ------------------------------------
            ## MATH
            ## ------------------------------------
            elsif ($opcode == VM::Inst->ADD_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a + $b );
            } elsif ($opcode == VM::Inst->SUB_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a - $b );
            } elsif ($opcode == VM::Inst->MUL_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a * $b );
            } elsif ($opcode == VM::Inst->DIV_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                if ( $b == 0 ) {
                    $error   = VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
                    goto ERROR;
                }
                # TODO : handle div by zero error here
                $self->PUSH( $a / $b );
            } elsif ($opcode == VM::Inst->MOD_NUM) {
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
            elsif ($opcode == VM::Inst->LT_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a < $b ? true : false );
            } elsif ($opcode == VM::Inst->GT_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a > $b ? true : false );
            } elsif ($opcode == VM::Inst->EQ_NUM) {
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

        ERROR:
            if ($error) {
                $running = false;
                $self->DEBUGGER if DEBUG;
            }
        }
    }

}
