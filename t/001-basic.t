#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;

my $state = VM->new(
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
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['Hello, Joe'], '... got the expected stdout');
    is_deeply($state->stderr, ['... hi!'], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





