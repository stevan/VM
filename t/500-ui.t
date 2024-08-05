#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Debugger;
use VM::Debugger::IOView;

say join "\n" => VM::Debugger::IOView->new(
    width  => 40,
    title  => 'STDOUT',
)->update(
    VM::Snapshot->new(
        code    => [
                VM::Inst->CONST_STR, "Hello, ",
                VM::Inst->LOAD_ARG, 0,
                VM::Inst->CONCAT_STR,
                VM::Inst->CONST_STR, "... hi!",
                VM::Inst->WARN,
                VM::Inst->RETURN,
                VM::Inst->CONST_STR, "Joe",
                VM::Inst->CALL, 0, 1,
                VM::Inst->PRINT,
                VM::Inst->HALT
        ],
        stack   => [
            0,0,0,0,0,0,
            100,
            100,
            2,
            0,   # ~
            555, # fp
            10 .. 50,
        ],
        memory  => undef,
        labels  => {
            '.main'  => 9,
            '.greet' => 0,
        },

        stdout  => [ 1 .. 10 ],
        stderr  => undef,

        pc      => 9,
        ic      => 9,
        ci      => 5,
        fp      => 10,
        sp      => 13,

        running => undef,
        error   => undef,
    )
)->draw;



