#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.main'),

            # reserve three cells,
            # this will put the address
            # of the first cell on the
            # top of the stack
            VM::Inst->CONST_NUM, 3,
            VM::Inst->ALLOC_LOCAL,

            # add the values to the array
            VM::Inst->CONST_STR, "Joe",
            VM::Inst->CONST_NUM, 0,
            VM::Inst->LOAD, 0,
            VM::Inst->STORE_LOCAL,

            VM::Inst->CONST_NUM, 10,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->LOAD, 0,
            VM::Inst->STORE_LOCAL,

            VM::Inst->CONST_TRUE,
            VM::Inst->CONST_NUM, 2,
            VM::Inst->LOAD, 0,
            VM::Inst->STORE_LOCAL,

            # now print them ..
            VM::Inst->CONST_NUM, 2,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->PRINT,

            VM::Inst->CONST_NUM, 1,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->PRINT,

            VM::Inst->CONST_NUM, 0,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->PRINT,

            # free the array
            VM::Inst->LOAD, 0,
            VM::Inst->FREE_LOCAL,

            VM::Inst->HALT
    ]
)->assemble->run;




