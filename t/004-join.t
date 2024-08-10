#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;
use VM::Assembler::Assembly;

my $state = VM->new(
    entry  => label *main,
    source => [
        label *join,
            LOAD_ARG \0,
            LOAD_ARG \1,
            SWAP,
            CONCAT_STR,
            DUP,
            DUP,
            LOAD_ARG \2,
            CONCAT_STR,
            SWAP,
            FREE_MEM,
            RETURN,

        label *main,
            CONST_STR \'two',
            CONST_STR \'one',
            CONST_STR \', ',
            CALL(*join, \3),
            DUP,
            PRINT,
            FREE_MEM,
            HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['one, two'], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





