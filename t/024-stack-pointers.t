#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.create_array'),

            VM::Inst->LOAD_ARG, 0,
            VM::Inst->ALLOC_MEM,

            VM::Inst->CONST_NUM, 100,
            VM::Inst->CONST_NUM, 3,
            VM::Inst->LOAD, 1,
            VM::Inst->STORE_MEM,

            VM::Inst->LOAD, 1,
            VM::Inst->RETURN,

        VM::Inst->label('.main'),

            # the size of the array
            VM::Inst->CONST_NUM, 5,
            VM::Inst->CALL, VM::Inst->marker('.create_array'), 1,

            VM::Inst->HALT
    ]
)->assemble->run;





