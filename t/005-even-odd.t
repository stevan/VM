#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;
use VM::Assembler::Assembly;

my $state = VM->new(
    entry  => label *main,
    source => [
        label *even,
            LOAD_ARG  \0,
            CONST_INT i(0),
            EQ_INT,
            JUMP_IF_FALSE *even::cond,
            CONST_TRUE,
            RETURN,
        label *even::cond,
            LOAD_ARG  \0,
            CONST_INT i(1),
            SUB_INT,
            CALL( *odd, \1 ),
            RETURN,

        label *odd,
            LOAD_ARG \0,
            CONST_INT i(0),
            EQ_INT,
            JUMP_IF_FALSE *odd::cond_1,
            CONST_FALSE,
            RETURN,
        label *odd::cond_1,
            LOAD_ARG  \0,
            CONST_INT i(1),
            SUB_INT,
            CALL( *even, \1 ),
            RETURN,

        label *main,
            CONST_INT i(15),
            CALL( *even, \1 ),
            JUMP_IF_FALSE *main::cond_1,
            CONST_STR \"#TRUE",
            JUMP *main::cond_2,
        label *main::cond_1,
            CONST_STR \"#FALSE",
        label *main::cond_2,
            PRINT,
            HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['#FALSE'], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





