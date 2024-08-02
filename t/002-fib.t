#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;


my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.fib'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 0,
            VM::Inst->EQ_INT,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib.1'),
            VM::Inst->CONST_INT, 0,
            VM::Inst->RETURN,
        VM::Inst->label('.fib.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 3,
            VM::Inst->LT_INT,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib.2'),
            VM::Inst->CONST_INT, 1,
            VM::Inst->RETURN,
        VM::Inst->label('.fib.2'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 1,
            VM::Inst->SUB_INT,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_INT, 2,
            VM::Inst->SUB_INT,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->ADD_INT,
            VM::Inst->RETURN,

        VM::Inst->label('.main'),
            VM::Inst->CONST_STR, "VM: ",
            VM::Inst->CONST_INT, 5,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,
            VM::Inst->CONCAT_STR,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->compile->run;


sub fibonacci ($number) {
    if ($number < 2) { # base case
        return $number;
    }
    return fibonacci($number-1) + fibonacci($number-2);
}

say "PERL: ", fibonacci(5);




