#!perl

use v5.40;
use experimental qw[ class ];

use VM::Debugger;

my $ui = VM::Debugger::UI::Zipped->new(
    elements => [
        VM::Debugger::UI::Panel->new(
            width    => 20,
            height   => 5,
            title    => 'Program',
            contents => [
                map { sprintf '%03d : %0.3f', $_, rand } (0 .. 10)
            ]
        ),
        VM::Debugger::UI::Panel->new(
            width    => 30,
            height   => 5,
            title    => 'Stack',
            contents => [
                map '~', (0 .. 15)
            ]
        ),
        VM::Debugger::UI::Stacked->new(
            elements => [
                VM::Debugger::UI::Panel->new(
                    width    => 10,
                    title    => 'Error',
                ),
                VM::Debugger::UI::Panel->new(
                    width    => 10,
                    title    => 'STDOUT',
                ),
                VM::Debugger::UI::Panel->new(
                    width    => 10,
                    title    => 'STDERR',
                )
            ]
        )
    ]
);

say join "\n" => $ui->draw;


