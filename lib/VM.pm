#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;
use VM::Pointer;

use VM::Assembler;
use VM::Debugger;

use VM::MemoryBlocks;

class VM::State {
    field $code     :param :reader;
    field $stack    :param :reader;
    field $heap     :param :reader;
    field $labels   :param :reader;
    field $static   :param :reader;
    field $pointers :param :reader;

    field $stdout   :param :reader;
    field $stderr   :param :reader;

    field $pc       :param :reader;
    field $ic       :param :reader;
    field $ci       :param :reader;
    field $fp       :param :reader;
    field $sp       :param :reader;

    field $running  :param :reader;
    field $error    :param :reader;
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

    field @memory_blocks;

    field @code;
    field @stack;
    field @heap;
    field %labels;
    field @static;
    field @pointers;

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

        # setup the memory blocks
        $memory_blocks[VM::MemoryBlocks->NULL]   = VM::Pointer::Null->new;
        $memory_blocks[VM::MemoryBlocks->STACK]  = \@stack;
        $memory_blocks[VM::MemoryBlocks->HEAP]   = \@heap;
        $memory_blocks[VM::MemoryBlocks->CODE]   = \@code;
        $memory_blocks[VM::MemoryBlocks->STATIC] = \@static;
    }

    ## --------------------------------

    method PUSH ($v) { $stack[++$sp] = $v }
    method POP       { $stack[$sp--]      }
    method PEEK      { $stack[$sp]        }

    method next_op { $code[$pc++] }

    ## --------------------------------

    method assemble {
        my ($code, $labels, $static) = $assembler->assemble($source);
        $self->reset;
        @code   = @$code;
        %labels = %$labels;
        @static = @$static;
        $pc     = $labels{ $entry } // die "Could not find entry point($entry) in source";
        return $self;
    }

    ## --------------------------------

    method snapshot {
        return VM::State->new(
            code     =>  [ @code    ],
            stack    =>  [ @stack   ],
            heap     =>  [ @heap  ],
            labels   => +{ %labels  },
            static   =>  [ @static ],
            pointers =>  [ @pointers ],
            stdout   =>  [ @stdout  ],
            stderr   =>  [ @stderr  ],
            pc       => $pc,
            ic       => $ic,
            ci       => $ci,
            fp       => $fp,
            sp       => $sp,
            running  => $running,
            error    => $error,
        )
    }

    method restore ($state) {
        @code     = $state->code->@*;
        @stack    = $state->stack->@*;
        @heap     = $state->heap->@*;
        %labels   = $state->labels->%*;
        @static   = $state->static->@*;
        @pointers = $state->pointers->@*;

        @stdout = $state->stdout->@*;
        @stderr = $state->stderr->@*;

        $pc = $state->pc;
        $ic = $state->ic;
        $ci = $state->ci;
        $fp = $state->fp;
        $sp = $state->sp;

        $running = $state->running;
        $error   = $state->error;
    }

    method reset {
        @code     = ();
        @stack    = ();
        @heap     = ();
        %labels   = ();
        @static   = ();
        @pointers = ();

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

    ## --------------------------------

    method run {
        $SIG{INT} = sub { die "Interuptted!"; };

        $error   = undef;
        $running = true;

        while ($running) {
            $ci = $pc;
            my $opcode = $self->next_op;

            if ($error = $self->run_opcode( $opcode )) {
                $running = false;
            }

            $ic++;

            if (DEBUG) {
                print "\e[2J\e[H\n";
                say $debugger->display( $self->snapshot );

                if ($clock) {
                    Time::HiRes::sleep( $clock );
                } else {
                    my $x = <>;
                }
            }
        }

        return $self->snapshot;
    }

    method run_opcode($opcode) {

        unless (defined $opcode) {
            return VM::Errors->UNEXPECTED_END_OF_CODE;
        }

        if ($opcode isa VM::Inst::Op::HALT) {
            $running = false;
            $sp = -1;
            $fp = 0;
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
        } elsif ($opcode isa VM::Inst::Op::CONST_NUM) {
            my $v = $self->next_op;
            $self->PUSH($v);
        } elsif ($opcode isa VM::Inst::Op::CONST_STR) {
            my $str_ptr = $self->next_op;

            # TODO: throw an error if ...
            # - make sure it is a STATICS type
            # - check for bounds issues

            $self->PUSH( $static[ $str_ptr->address ] );
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
                return VM::Errors->ILLEGAL_DIVISION_BY_ZERO;
            }
            # TODO : handle div by zero error here
            $self->PUSH( $a / $b );
        } elsif ($opcode isa VM::Inst::Op::MOD_NUM) {
            my $b = $self->POP;
            my $a = $self->POP;
            if ( $b == 0 ) {
                return VM::Errors->ILLEGAL_MOD_BY_ZERO;
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
        ## Load/Store stack heap
        ## ------------------------------------
        elsif ($opcode isa VM::Inst::Op::LOAD) {
            my $offset = $self->next_op;

            # TODO: throw an error if ...
            # - check for bounds issues

            $self->PUSH( $stack[$fp + $offset] );
        } elsif ($opcode isa VM::Inst::Op::STORE) {
            my $v      = $self->POP;
            my $offset = $self->next_op;

            # TODO: throw an error if ...
            # - check for bounds issues

            $stack[$fp + $offset] = $v;
        }
        ## ------------------------------------
        ## Load/Store local heap
        ## ------------------------------------
        elsif ($opcode isa VM::Inst::Op::ALLOC_MEM) {

            my $size = $self->POP;
            my $addr = scalar @heap;

            $heap[$addr + $_] = undef
                foreach 0 .. ($size - 1);

            my $ptr_addr = scalar @pointers;
            $pointers[$ptr_addr] = VM::Pointer::Heap->new(
                address  => $addr,
                size     => $size,
                ptr_addr => $ptr_addr,
            );

            $self->PUSH( $pointers[$ptr_addr] );

        } elsif ($opcode isa VM::Inst::Op::LOAD_MEM) {
            my $ptr    = $self->POP;
            my $offset = $self->POP;

            # TODO: throw an error if ...
            # - make sure it is the right HEAP type

            unless (defined $pointers[ $ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            if ($offset >= $ptr->size) {
                return VM::Errors->MEMORY_ACCESS_OUT_OF_BOUNDS;
            }

            $self->PUSH( $heap[ $ptr->address + $offset ] );

        } elsif ($opcode isa VM::Inst::Op::STORE_MEM) {
            my $ptr    = $self->POP;
            my $offset = $self->POP;
            my $value  = $self->POP;

            # TODO: throw an error if ...
            # - make sure it is the right HEAP type

            unless (defined $pointers[ $ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            if ($offset >= $ptr->size) {
                return VM::Errors->MEMORY_ACCESS_OUT_OF_BOUNDS;
            }

            $heap[ $ptr->address + $offset ] = $value;

        } elsif ($opcode isa VM::Inst::Op::CLEAR_MEM) {
            my $ptr = $self->POP;

            # TODO: throw an error if ...
            # - make sure it is the right HEAP type

            unless (defined $pointers[ $ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            $heap[ $ptr->address + $_ ] = undef
                foreach 0 .. ($ptr->size - 1);

        } elsif ($opcode isa VM::Inst::Op::FREE_MEM) {
            my $ptr = $self->POP;

            # TODO: throw an error if ...
            # - make sure it is the right HEAP type

            unless (defined $pointers[ $ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            $heap[ $ptr->address + $_ ] = undef
                foreach 0 .. ($ptr->size - 1);

            $pointers[ $ptr->ptr_addr ] = undef;

        } elsif ($opcode isa VM::Inst::Op::COPY_MEM) {
            my $from_ptr = $self->POP;
            my $to_ptr   = $self->POP;

            # TODO: throw an error if ...
            # - make sure it is the right HEAP type

            unless (defined $pointers[ $from_ptr->ptr_addr ]
                &&  defined $pointers[ $from_ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            if ($to_ptr->size != $from_ptr->size) {
                return VM::Errors->INCOMPATIBLE_POINTERS;
            }

            $heap[ $to_ptr->address + $_ ] = $heap[ $from_ptr->address + $_ ]
                foreach 0 .. ($to_ptr->size - 1);
        }
        elsif ($opcode isa VM::Inst::Op::COPY_MEM_FROM) {
            my $size     = $self->POP;
            my $offset   = $self->POP;
            my $from_ptr = $self->POP;
            my $to_ptr   = $self->POP;

            # TODO: throw an error if ...
            # - make the to it is the right HEAP type
            # - but the other one can be from another
            #   memory region if we want, but for now
            #   it also needs to be a memory one

            unless (defined $pointers[ $from_ptr->ptr_addr ]
                &&  defined $pointers[ $from_ptr->ptr_addr ]) {
                return VM::Errors->MEMORY_ALREADY_FREED;
            }

            if ($size > $to_ptr->size
            && ($offset + ($size - 1)) > $from_ptr->size) {
                return VM::Errors->MEMORY_ACCESS_OUT_OF_BOUNDS;
            }

            $heap[ $to_ptr->address + $_ ] = $heap[ ($from_ptr->address + $offset) + $_ ]
                foreach 0 .. ($size - 1);
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
            my $rvalc = $self->next_op;

            my @rvals;
            if ($rvalc) {
                foreach my $i ( 0 .. ($rvalc - 1)) {
                    push @rvals => $self->POP;  # get the return values
                }
            }

            $sp    = $fp;         # restore stack pointer
            $pc    = $self->POP;  # get the stashed program counter
            $fp    = $self->POP;  # get the stashed program frame pointer

            my $argc  = $self->POP;  # get the number of args
               $sp   -= $argc;       # decrement stack pointer by num args

            foreach my $rval (@rvals) {
                $self->PUSH($rval);     # push the return values onto the stack
            }
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
            return VM::Errors->UNKNOWN_OPCODE;
        }

        return;
    }

}
