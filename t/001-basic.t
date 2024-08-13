#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;

use VM;
use VM::Assembler::Assembly;


sub fun :prototype(&@) ($f, @opcodes) { label $f->(), @opcodes }





my $state = VM->new(
    entry  => label *main,
    source => [
        fun {*greet}
            CONST_STR \"Hello, ",
            LOAD_ARG  \0,
            CONCAT_STR,
            CONST_STR \"... hi!",
            WARN,
            RETURN,

        fun {*main}
            CONST_STR \"Joe",
            CALL(*greet, \1),
            DUP,
            PRINT,
            FREE_MEM,
            HALT
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





