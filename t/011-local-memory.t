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

            # add the values to the stack
            VM::Inst->CONST_STR, "Joe",
            VM::Inst->CONST_NUM, 10,
            VM::Inst->CONST_TRUE,
            # construct the tuple on the top of the stack
            VM::Inst->CREATE_ARRAY, 3,

            # fetch the Pointer to the top of the stack
            VM::Inst->LOAD, 0,

            # store it in our local fetching the
            # pointer then the value
            VM::Inst->STORE_LOCAL,

            # load tuple from the local
            # and extract value from it
            # and do this for each item
            # in the tuple
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->ARRAY_INDEX, 0,
            VM::Inst->PRINT,

            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->ARRAY_INDEX, 1,
            VM::Inst->PRINT,

            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_LOCAL,
            VM::Inst->ARRAY_INDEX, 2,
            VM::Inst->PRINT,

            VM::Inst->LOAD, 0,
            VM::Inst->FREE_LOCAL,

            VM::Inst->HALT
    ]
)->assemble->run;





