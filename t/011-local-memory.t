#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.main'),

            # add the values to the stack
            VM::Inst->CONST_STR, "Joe",
            VM::Inst->CONST_NUM, 10,
            VM::Inst->CONST_TRUE,
            # construct the tuple
            VM::Inst->CREATE_TUPLE, 3,
            # store it in our local
            VM::Inst->STORE_LOCAL, 0,

            # load tuple from the local
            # and extract value from it
            # and do this for each item
            # in the tuple
            VM::Inst->LOAD_LOCAL, 0,
            VM::Inst->TUPLE_INDEX, 0,
            VM::Inst->PRINT,

            VM::Inst->LOAD_LOCAL, 0,
            VM::Inst->TUPLE_INDEX, 1,
            VM::Inst->PRINT,

            VM::Inst->LOAD_LOCAL, 0,
            VM::Inst->TUPLE_INDEX, 2,
            VM::Inst->PRINT,

            VM::Inst->FREE_LOCAL, 0,

            VM::Inst->HALT
    ]
)->assemble->run;





