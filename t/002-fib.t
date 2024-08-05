#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;


my $state = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.fib'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib.1'),
            VM::Inst->CONST_NUM, 0,
            VM::Inst->RETURN, 1,
        VM::Inst->label('.fib.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 3,
            VM::Inst->LT_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.fib.2'),
            VM::Inst->CONST_NUM, 1,
            VM::Inst->RETURN, 1,
        VM::Inst->label('.fib.2'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 2,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,

            VM::Inst->ADD_NUM,
            VM::Inst->RETURN, 1,

        VM::Inst->label('.main'),
            VM::Inst->CONST_STR, "VM: ",
            VM::Inst->CONST_NUM, 5,
            VM::Inst->CALL, VM::Inst->marker('.fib'), 1,
            VM::Inst->CONCAT_STR,
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['VM: 5'], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->memory->@*), 0, '... all memory was freed');
};

done_testing;


sub fibonacci ($number) {
    if ($number < 2) { # base case
        return $number;
    }
    return fibonacci($number-1) + fibonacci($number-2);
}

say "PERL: ", fibonacci(5);




