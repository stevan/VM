#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;
use VM::Assembler::Assembly;

my $state = VM->new(
    entry  => label *main,
    source => [
        label *fib,
            LOAD_ARG \0,
            CONST_INT i(0),
            EQ_INT,
            JUMP_IF_FALSE *fib::cond_1,
            CONST_INT i(0),
            RETURN,
        label *fib::cond_1,
            LOAD_ARG \0,
            CONST_INT i(3),
            LT_INT,
            JUMP_IF_FALSE *fib::cond_2,
            CONST_INT i(1),
            RETURN,
        label *fib::cond_2,
            LOAD_ARG \0,
            CONST_INT i(1),
            SUB_INT,
            CALL(*fib, \1),

            LOAD_ARG \0,
            CONST_INT i(2),
            SUB_INT,
            CALL(*fib, \1),

            ADD_INT,
            RETURN,

        label *main,
            CONST_INT i(5),
            CALL(*fib, \1),

            FORMAT_STR("VM: %d", \1),

            DUP,
            PRINT,
            FREE_MEM,
            HALT,
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['VM: 5'], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;


sub fibonacci ($number) {
    if ($number < 2) { # base case
        return $number;
    }
    return fibonacci($number-1) + fibonacci($number-2);
}

say "PERL: ", fibonacci(5);




