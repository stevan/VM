#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;

my $state = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.even'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.even.1'),
            VM::Inst->CONST_TRUE,
            VM::Inst->RETURN, 1,
        VM::Inst->label('.even.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.odd'), 1,
            VM::Inst->RETURN, 1,

        VM::Inst->label('.odd'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 0,
            VM::Inst->EQ_NUM,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.odd.1'),
            VM::Inst->CONST_FALSE,
            VM::Inst->RETURN, 1,
        VM::Inst->label('.odd.1'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->CONST_NUM, 1,
            VM::Inst->SUB_NUM,
            VM::Inst->CALL, VM::Inst->marker('.even'), 1,
            VM::Inst->RETURN, 1,

        VM::Inst->label('.main'),
            VM::Inst->CONST_NUM, 15,
            VM::Inst->CALL, VM::Inst->marker('.even'), 1,
            VM::Inst->JUMP_IF_FALSE, VM::Inst->marker('.main.1'),
            VM::Inst->CONST_STR, "#TRUE",
            VM::Inst->JUMP, VM::Inst->marker('.main.2'),
        VM::Inst->label('.main.1'),
            VM::Inst->CONST_STR, "#FALSE",
        VM::Inst->label('.main.2'),
            VM::Inst->PRINT,
            VM::Inst->HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, ['#FALSE'], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->memory->@*), 0, '... all memory was freed');
};

done_testing;





