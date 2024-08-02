#!perl

use v5.40;
use experimental qw[ class ];

use VM::Debugger;


my $p = VM::Debugger::UI::Panel->new(
    width    => 20,
    height   => 5,
    title    => 'Program',
    contents => [
        map { sprintf '%03d : %0.3f', $_, rand } (0 .. 10)
    ]
);

say join "\n" => $p->draw;


