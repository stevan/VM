#!perl

use v5.40;
use experimental qw[ class ];

# pop, push

my %zero_ops = (
    Noop       => [ 0, 1 ],
    Halt       => [ 0, 0 ],

    ConstNil   => [ 0, 1 ],
    ConstTrue  => [ 0, 1 ],
    ConstFalse => [ 0, 1 ],
);

my %un_ops = (
    ConstNum    => [ 0, 1 ],
    ConstStr    => [ 0, 1 ],

    Jump        => [ 0, 0 ],
    JumpIfTrue  => [ 1, 0 ],
    JumpIfFalse => [ 1, 0 ],

    Load        => [ 0, 1 ],
    Store       => [ 1, 0 ],

    LoadArg     => [ 0, 1 ],
);

my %bin_ops = (
    Call => [ 0, 3 ]
);

my %stack_ops = (
    AddNum    => [ 2, 1 ],
    SubNum    => [ 2, 1 ],
    MulNum    => [ 2, 1 ],
    DivNum    => [ 2, 1 ],
    ModNum    => [ 2, 1 ],
    LtNum     => [ 2, 1 ],
    GtNum     => [ 2, 1 ],
    EqNum     => [ 2, 1 ],

    ConcatStr => [ 2, 1 ],
    LtStr     => [ 2, 1 ],
    GtStr     => [ 2, 1 ],
    EqStr     => [ 2, 1 ],

    AllocMem  => [ 1, 1 ],
    LoadMem   => [ 2, 1 ],
    StoreMem  => [ 3, 0 ],
    FreeMem   => [ 1, 0 ],

    Return    => [ 4, 1 ],

    Dup       => [ 0, 1 ],
    Pop       => [ 1, 0 ],
    Swap      => [ 2, 2 ],

    Print     => [ 1, 0 ],
    Warn      => [ 1, 0 ],
);

my %ops = (
    %zero_ops,
    %un_ops,
    %bin_ops,
    %stack_ops,
);

sub build_zero_ops ($name) {
    return sub () { bless [] => $name }
}

sub build_un_ops ($name) {
    return sub ($arg1) { bless [ $arg1 ] => $name }
}

sub build_bin_ops ($name) {
    return sub ($arg1, $arg2) { bless [ $arg1, $arg2 ] => $name }
}

sub build_stack_ops ($name) {
    return sub () { bless [] => $name }
}

