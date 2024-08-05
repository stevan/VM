#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;

my $state = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.create_array'),
            VM::Inst->LOAD_ARG, 0,
            VM::Inst->ALLOC_MEM,

            VM::Inst->CONST_NUM, 100,
            VM::Inst->CONST_NUM, 3,
            VM::Inst->LOAD, 1,
            VM::Inst->STORE_MEM,

            VM::Inst->LOAD_ARG, 0,
            VM::Inst->LOAD, 1,
            VM::Inst->RETURN, 2,

        VM::Inst->label('.main'),

            # the size of the array
            VM::Inst->CONST_NUM, 5,
            VM::Inst->CALL, VM::Inst->marker('.create_array'), 1,

            VM::Inst->PRINT, # print the size

            VM::Inst->DUP,      # dup the pointer on the stack
            VM::Inst->PRINT,    # print the pointer
            VM::Inst->FREE_MEM, # now free the pointer

            VM::Inst->HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, [ 5,'*M[5]<0000>' ], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->memory->@*), 0, '... all memory was freed');
};

done_testing;






