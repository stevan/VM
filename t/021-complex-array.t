#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.fill_array'),
            # $idx
            VM::Inst->CONST_NUM, 0,

            VM::Inst->label('.fill_array.loop'),

                # ($idx == $size)
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->LOAD, 1,
                VM::Inst->EQ_NUM,
                VM::Inst->JUMP_IF_TRUE, VM::Inst->marker('.fill_array.loop.exit'),

                VM::Inst->LOAD, 1,
                VM::Inst->DUP,
                VM::Inst->LOAD_ARG, 1,
                VM::Inst->STORE_MEM,

                # increment the $idx
                VM::Inst->LOAD, 1,
                VM::Inst->CONST_NUM, 1,
                VM::Inst->ADD_NUM,
                VM::Inst->STORE, 1,

                VM::Inst->JUMP, VM::Inst->marker('.fill_array.loop'),

            VM::Inst->label('.fill_array.loop.exit'),

            VM::Inst->RETURN, 0,

        VM::Inst->label('.main'),

            # allocate 3 cells
            VM::Inst->CONST_NUM, 3,
            VM::Inst->ALLOC_MEM,

            # allocate 5 cells
            VM::Inst->CONST_NUM, 5,
            VM::Inst->ALLOC_MEM,

            # .. make one the arg
            VM::Inst->DUP,
            # the size of the array
            VM::Inst->CONST_NUM, 5,
            VM::Inst->CALL, VM::Inst->marker('.fill_array'), 2,

            # load the 3 item array
            VM::Inst->LOAD, 0,
            # the size of the array
            VM::Inst->CONST_NUM, 3,
            VM::Inst->CALL, VM::Inst->marker('.fill_array'), 2,

            VM::Inst->LOAD, 1,
            VM::Inst->CLEAR_MEM,

            # load the 3 item array
            VM::Inst->LOAD, 1,
            # the size of the array
            VM::Inst->CONST_NUM, 2,
            VM::Inst->CALL, VM::Inst->marker('.fill_array'), 2,

            VM::Inst->LOAD, 0,
            VM::Inst->FREE_MEM,

            VM::Inst->LOAD, 1,
            VM::Inst->FREE_MEM,

            VM::Inst->HALT
    ]
)->assemble->run;





