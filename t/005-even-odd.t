#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.even'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.even.1'),
            VM::Inst->CONST_TRUE,
            VM::Inst->RETURN,
        VM::Inst->label('.even.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.odd'), 1,
            VM::Inst->RETURN,

        VM::Inst->label('.odd'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.odd.1'),
            VM::Inst->CONST_FALSE,
            VM::Inst->RETURN,
        VM::Inst->label('.odd.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.even'), 1,
            VM::Inst->RETURN,

        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 15,
            VM::Inst->CALL, VM::Inst->marker('.even'), 1,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.main.1'),
            VM::Inst->CONST_STR, "#TRUE",
            VM::Inst->JUMP, VM::Inst->marker('.main.2'),
        VM::Inst->label('.main.1'),
            VM::Inst->CONST_STR, "#FALSE",
        VM::Inst->label('.main.2'),
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;





