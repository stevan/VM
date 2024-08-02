#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;

=pod

(define (factorial n)
 (if (= n 0)
    1
    (* n (factorial (- n 1)))))

=cut

my $vm = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.factorial'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.factorial.1'),
            VM::Inst->CONST_NUM, 1,
            VM::Inst->RETURN,
        VM::Inst->label('.factorial.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.factorial'), 1,
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->MUL_NUM,
            VM::Inst->RETURN,


        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 6,
            VM::Inst->CALL, VM::Inst->marker('.factorial'), 1,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->compile->run;

sub factorial ($n) {
    return 1 if $n == 0;
    return $n * factorial($n - 1);
}

say factorial(6); #


