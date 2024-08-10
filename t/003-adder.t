#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;
use VM::Assembler::Assembly;

my $state = VM->new(
    entry  => label *main,
    source => [
        label *doubler,
            LOAD_ARG \0,
            DUP,
            ADD_INT,
            RETURN,

        label *main,
            CONST_INT i(10),
            CALL(*doubler, \1),
            PRINT,
            HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, [20], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





