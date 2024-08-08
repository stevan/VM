#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;

my $state = VM->new(
    entry  => '.main',
    source => [
        VM::Inst->label('.fill_array'),
            # $idx
            VM::Inst->CONST_INT, 0,

            VM::Inst->label('.fill_array.loop'),

                # ($idx == $size)
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->LOAD, 1,
                VM::Inst->EQ_INT,
                VM::Inst->JUMP_IF_TRUE, VM::Inst->marker('.fill_array.loop.exit'),

                VM::Inst->LOAD, 1,
                VM::Inst->DUP,
                VM::Inst->LOAD_ARG, 1,
                VM::Inst->STORE_MEM,

                # increment the $idx
                VM::Inst->LOAD, 1,
                VM::Inst->CONST_INT, 1,
                VM::Inst->ADD_INT,
                VM::Inst->STORE, 1,

                VM::Inst->JUMP, VM::Inst->marker('.fill_array.loop'),

            VM::Inst->label('.fill_array.loop.exit'),

            VM::Inst->RETURN, # TODO: make this void

        VM::Inst->label('.main'),

            # allocate 3 cells
            VM::Inst->CONST_INT, 3,
            VM::Inst->ALLOC_MEM, VM::Inst->type_of_INT,

            # allocate 3 cells
            VM::Inst->CONST_INT, 3,
            VM::Inst->ALLOC_MEM, VM::Inst->type_of_INT,

            # allocate 5 cells
            VM::Inst->CONST_INT, 5,
            VM::Inst->ALLOC_MEM, VM::Inst->type_of_INT,

            # .. make one the arg
            VM::Inst->DUP,
            # the size of the array
            VM::Inst->CONST_INT, 5,
            VM::Inst->CALL, VM::Inst->marker('.fill_array'), 2,

            VM::Inst->LOAD, 0,
            VM::Inst->LOAD, 2,
            VM::Inst->COPY_MEM_FROM, 1, 3,

            VM::Inst->LOAD, 1,
            VM::Inst->LOAD, 0,
            VM::Inst->COPY_MEM,

            VM::Inst->LOAD, 2,
            VM::Inst->FREE_MEM,

            VM::Inst->LOAD, 1,
            VM::Inst->FREE_MEM,

            VM::Inst->LOAD, 0,
            VM::Inst->FREE_MEM,

            VM::Inst->HALT
    ]
)->assemble->run;

subtest '... testing the vm end state' => sub {
    ok(!$state->error, '... we did not get an error');
    ok(!$state->running, '... and we are no longer running');

    is_deeply($state->stdout, [], '... got the expected stdout');
    is_deeply($state->stderr, [], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





