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
            VM::Inst->CONST_NUM, 0,

            VM::Inst->label('.fill_array.loop'),

                # ($idx == $size)
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->LOAD, 1,
                VM::Inst->EQ_NUM,
                VM::Inst->JUMP_IF_TRUE, VM::Inst->marker('.fill_array.loop.exit'),

                VM::Inst->LOAD, 1,
                VM::Inst->DUP,
                VM::Inst->LOAD_ARG, 1,
                VM::Inst->STORE_MEM,

                # increment the $idx
                VM::Inst->LOAD, 1,
                VM::Inst->CONST_NUM, 1,
                VM::Inst->ADD_NUM,
                VM::Inst->STORE, 1,

                VM::Inst->JUMP, VM::Inst->marker('.fill_array.loop'),

            VM::Inst->label('.fill_array.loop.exit'),

            VM::Inst->CONST_STR, "INNER: ",
            VM::Inst->LOAD, 1,
            VM::Inst->CONCAT_STR,
            VM::Inst->WARN,

            VM::Inst->RETURN, 0,

        VM::Inst->label('.fill_matrix'), # $inner_size, $outer_size, $ptr
            # $idx_outer
            VM::Inst->CONST_NUM, 0,

            VM::Inst->label('.fill_matrix.outer'),

                # ($idx_outer == $outer_size)
                VM::Inst->LOAD_ARG, 1,
                VM::Inst->LOAD, 1,
                VM::Inst->EQ_NUM,
                VM::Inst->JUMP_IF_TRUE, VM::Inst->marker('.fill_matrix.outer.exit'),

                # alloc inner array
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->ALLOC_MEM,

                # store it
                VM::Inst->DUP,         # inner $ptr
                VM::Inst->LOAD, 1,     # $idx_outer
                VM::Inst->LOAD_ARG, 2, # matrix $ptr
                VM::Inst->STORE_MEM,

                # call the array filler with $inner_size
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->CALL, VM::Inst->marker('.fill_array'), 2,

                # increment the $idx_outer
                VM::Inst->LOAD, 1,
                VM::Inst->CONST_NUM, 1,
                VM::Inst->ADD_NUM,
                VM::Inst->STORE, 1,

                VM::Inst->JUMP, VM::Inst->marker('.fill_matrix.outer'),

            VM::Inst->label('.fill_matrix.outer.exit'),

            VM::Inst->CONST_STR, "OUTER: ",
            VM::Inst->LOAD, 1,
            VM::Inst->CONCAT_STR,
            VM::Inst->WARN,

            VM::Inst->RETURN, 0,

        VM::Inst->label('.main'),

            # allocate 3 cells
            VM::Inst->CONST_NUM, 3,
            VM::Inst->ALLOC_MEM,

            VM::Inst->DUP,
            # the size of the array
            VM::Inst->CONST_NUM, 3,
            # the size of the sub arrays
            VM::Inst->CONST_NUM, 5,
            VM::Inst->CALL, VM::Inst->marker('.fill_matrix'), 3,

            VM::Inst->CONST_NUM, 0,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_MEM,
            VM::Inst->FREE_MEM,

            VM::Inst->CONST_NUM, 2,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_MEM,
            VM::Inst->FREE_MEM,

            VM::Inst->CONST_NUM, 1,
            VM::Inst->LOAD, 0,
            VM::Inst->LOAD_MEM,
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
    is_deeply($state->stderr, [
        'INNER: 5',
        'INNER: 5',
        'INNER: 5',
        'OUTER: 3',
    ], '... got the expected stderr');

    is((scalar grep defined, $state->pointers->@*), 0, '... all pointers were freed');
    is((scalar grep defined, $state->heap->@*), 0, '... all memory was freed');
};

done_testing;





