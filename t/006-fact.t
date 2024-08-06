#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;

=pod

(define (factorial n)
 (if (= n 0)
    1
    (* n (factorial (- n 1)))))

=cut

my $state = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.factorial'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.factorial.1'),
            VM::Inst->CONST_NUM, 1,
            VM::Inst->RETURN, 1,
        VM::Inst->label('.factorial.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.factorial'), 1,
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->MUL_NUM,
            VM::Inst->RETURN, 1,


        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 6,
            VM::Inst->CALL, VM::Inst->marker('.factorial'), 1,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, [720], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;

sub factorial ($n) {
    return 1 if $n == 0;
    return $n * factorial($n - 1);
}

say factorial(6); #


