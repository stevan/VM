#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.doubler'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->DUP,
            VM::Inst->ADD_NUM,
            VM::Inst->RETURN, 1,

        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 10,
            VM::Inst->CALL, VM::Inst->marker('.doubler'), 1,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;





