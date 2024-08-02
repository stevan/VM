#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.greet'),
            VM::Inst->CONST_STR, "Hello, ",
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONCAT_STR,
            VM::Inst->CONST_STR, "... hi!",
            VM::Inst->WARN,
            VM::Inst->RETURN,

        VM::Inst->label('.main'),
            VM::Inst->CONST_STR, "Joe",
            VM::Inst->CALL, VM::Inst->marker('.greet'), 1,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->compile->run;




