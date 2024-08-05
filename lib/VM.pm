#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

use VM::Assembler;
use VM::Debugger;

class VM::Snapshot {
    field $code    :param :reader;
    field $stack   :param :reader;
    field $memory  :param :reader;
    field $labels  :param :reader;

    field $stdout  :param :reader;
    field $stderr  :param :reader;

    field $pc      :param :reader;
    field $ic      :param :reader;
    field $ci      :param :reader;
    field $fp      :param :reader;
    field $sp      :param :reader;

    field $running :param :reader;
    field $error   :param :reader;
}

class VM {
    use constant DEBUG => $ENV{DEBUG} // 0;

    # TODO:
    # add STACK_SIZE & MEM_SIZE constant
    # (with %ENV override) and add checks
    # for it everywhere that it is needed

    field $source  :param;
    field $entry   :param;
    field $clock   :param = $ENV{CLOCK};

    field @code;
    field @stack;
    field @memory;
    field %labels;

    field @stdout;
    field @stderr;

    field $pc =  0; # program counter (points to current instruction)
    field $ic =  0; # instruction counter (number of instructions run)
    field $ci =  0; # pointer to the current instruction
    field $fp =  0; # frame pointer (points to the top of the current stack frame)
    field $sp = -1; # stack pointer (points to the current head of the stack)

    field $running :reader = false;
    field $error   :reader = undef;

    field $debugger;
    field $assembler;

    ADJUST {
        $debugger  = VM::Debugger->new if DEBUG;
        $assembler = VM::Assembler->new;
    }

    ## --------------------------------

    method PUSH ($v) { $stack[++$sp] = $v }
    method POP       { $stack[$sp--]      }
    method PEEK      { $stack[$sp]        }

    method next_op { $code[$pc++] }

    ## --------------------------------

    method snapshot {
        return VM::Snapshot->new(
            code    =>  [ @code   ],
            stack   =>  [ @stack  ],
            memory  =>  [ @memory ],
            labels  => +{ %labels },
            stdout  =>  [ @stdout ],
            stderr  =>  [ @stderr ],
            pc      => $pc,
            ic      => $ic,
            ci      => $ci,
            fp      => $fp,
            sp      => $sp,
            running => $running,
            error   => $error,
        )
    }

    method reset {
        @code   = ();
        @stack  = ();
        @memory = ();
        %labels = ();

        @stdout = ();
        @stderr = ();

        $pc =  0;
        $ic =  0;
        $ci =  0;
        $fp =  0;
        $sp = -1;

        $running = false;
        $error   = undef;
    }

    method assemble {
        my ($labels, $code) = $assembler->assemble($source);
        $self->reset;
        %labels = %$labels;
        @code   = @$code;
        $pc     = $labels{ $entry } // die "Could not find entry point($entry) in source";
        return $self;
    }

    ## --------------------------------

    method run {

        $SIG{INT} = sub { die "Interuptted!"; };

        $error   = undef;
        $running = true;

        while ($running) {
            $ci = $pc;
            my $opcode = $self->next_op;

            unless (defined $opcode) {
                $error = VM::Errors->UNEXPECTED_END_OF_CODE;
                goto ERROR;
            }

            if ($opcode isa VM::Inst::Op::HALT) {
                $running = false;
            }
            ## ------------------------------------
            ## Constants
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::CONST_NIL) {
                $self->PUSH(undef);
            } elsif ($opcode isa VM::Inst::Op::CONST_TRUE) {
                $self->PUSH(true);
            } elsif ($opcode isa VM::Inst::Op::CONST_FALSE) {
                $self->PUSH(false);
            } elsif ($opcode isa VM::Inst::Op::CONST_NUM || $opcode isa VM::Inst::Op::CONST_STR) {
                my $v = $self->next_op;
                $self->PUSH($v);
            }
            ## ------------------------------------
            ## MATH
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::ADD_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a + $b );
            } elsif ($opcode isa VM::Inst::Op::SUB_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a - $b );
            } elsif ($opcode isa VM::Inst::Op::MUL_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a * $b );
            } elsif ($opcode isa VM::Inst::Op::DIV_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                if ( $b == 0 ) {
                    $error = VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
                    goto ERROR;
                }
                # TODO : handle div by zero error here
                $self->PUSH( $a / $b );
            } elsif ($opcode isa VM::Inst::Op::MOD_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                if ( $b == 0 ) {
                    $error = VM::Errors->ILLEGAL_MOD_BY_ZERO;
                    goto ERROR;
                }
                $self->PUSH( $a % $b );
            }
            ## ------------------------------------
            ## String Operations
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::CONCAT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a . $b );
            }
            ## ------------------------------------
            ## Compariosons
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::LT_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a < $b ? true : false );
            } elsif ($opcode isa VM::Inst::Op::GT_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a > $b ? true : false );
            } elsif ($opcode isa VM::Inst::Op::EQ_NUM) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a == $b ? true : false );
            }
            # ... for strings
            elsif ($opcode isa VM::Inst::Op::LT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a lt $b ? true : false );
            } elsif ($opcode isa VM::Inst::Op::GT_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a gt $b ? true : false );
            } elsif ($opcode isa VM::Inst::Op::EQ_STR) {
                my $b = $self->POP;
                my $a = $self->POP;
                $self->PUSH( $a eq $b ? true : false );
            }
            ## ------------------------------------
            ## Conditionals
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::JUMP) {
                $pc = $self->next_op;
            } elsif ($opcode isa VM::Inst::Op::JUMP_IF_TRUE) {
                my $addr = $self->next_op;
                if ($self->POP == true) {
                    $pc = $addr;
                }
            } elsif ($opcode isa VM::Inst::Op::JUMP_IF_FALSE) {
                my $addr = $self->next_op;
                if ($self->POP == false) {
                    $pc = $addr;
                }
            }
            ## ------------------------------------
            ## Load/Store stack memory
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::LOAD) {
                my $offset = $self->next_op;
                $self->PUSH( $stack[$fp + $offset] );
            } elsif ($opcode isa VM::Inst::Op::STORE) {
                my $v      = $self->POP;
                my $offset = $self->next_op;
                $stack[$fp + $offset] = $v;
            }
            ## ------------------------------------
            ## Load/Store local memory
            ## ------------------------------------
            # TODO: add memory error handling here
            # - OOM
            # - BOUNDS ERROR
            elsif ($opcode isa VM::Inst::Op::ALLOC_MEM) {

                my $size = $self->POP;
                my $addr = scalar @memory;

                $memory[$addr + $_] = undef
                    foreach 0 .. ($size - 1);

                $self->PUSH( +{ addr => $addr => size => $size } );

            } elsif ($opcode isa VM::Inst::Op::LOAD_MEM) {
                my $ptr    = $self->POP;
                my $offset = $self->POP;

                # TODO: add check that offset is not greater than length

                $self->PUSH( $memory[ $ptr->{addr} + $offset ] );

            } elsif ($opcode isa VM::Inst::Op::STORE_MEM) {
                my $ptr    = $self->POP;
                my $offset = $self->POP;
                my $value  = $self->POP;

                #warn "ptr: $ptr offset: $offset value: $value";

                # TODO: add check that offset is not greater than length

                $memory[ $ptr->{addr} + $offset ] = $value;

            } elsif ($opcode isa VM::Inst::Op::FREE_MEM) {
                my $ptr = $self->POP;

                $memory[ $ptr->{addr} + $_ ] = undef
                    foreach 0 .. ($ptr->{size} - 1);
            }
            ## ------------------------------------
            ## Call functions
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::LOAD_ARG) {
                my $offset = $self->next_op;
                $self->PUSH( $stack[($fp - 3) - $offset] );
            } elsif ($opcode isa VM::Inst::Op::CALL) {
                my $addr = $self->next_op; # func address to go to
                my $argc = $self->next_op; # number of args the function has ...
                # stash the context ...
                $self->PUSH($argc);
                $self->PUSH($fp);
                $self->PUSH($pc);
                # set the new context ...
                $fp = $sp;   # set the new frame pointer
                $pc = $addr; # and the program counter to the func addr

            } elsif ($opcode isa VM::Inst::Op::RETURN) {
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
            elsif ($opcode isa VM::Inst::Op::DUP) {
                $self->PUSH($self->PEEK);
            } elsif ($opcode isa VM::Inst::Op::POP) {
                $self->POP;
            } elsif ($opcode isa VM::Inst::Op::SWAP) {
                my $v1 = $self->POP;
                my $v2 = $self->POP;
                $self->PUSH($v1);
                $self->PUSH($v2);
            }
            ## ------------------------------------
            ## System Calls
            ## ------------------------------------
            elsif ($opcode isa VM::Inst::Op::PRINT) {
                my $v = $self->POP;
                push @stdout => $v;
            } elsif ($opcode isa VM::Inst::Op::WARN) {
                my $v = $self->POP;
                push @stderr => $v;
            }
            ## ------------------------------------
            else {
                $error = VM::Errors->UNKNOWN_OPCODE;
                goto ERROR;
            }

            $ic++;

        ERROR:
            if ($error) {
                $running = false;
            }

            if (DEBUG) {
                say "\e[2J\e[H\n";
                say $debugger->display( $self->snapshot );

                if ($clock) {
                    Time::HiRes::sleep( $clock );
                } else {
                    my $x = <>;
                }
            }
        }

    }

}
