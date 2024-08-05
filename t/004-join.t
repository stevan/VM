#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.join'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->LOAD_ARG, 1,
            VM::Inst->SWAP,
            VM::Inst->CONCAT_STR,
            VM::Inst->LOAD_ARG, 2,
            VM::Inst->CONCAT_STR,
            VM::Inst->RETURN, 1,

        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 20,
            VM::Inst->CONST_NUM, 10,
            VM::Inst->CONST_STR, ', ',
            VM::Inst->CALL, VM::Inst->marker('.join'), 3,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;





