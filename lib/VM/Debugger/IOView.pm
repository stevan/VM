#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Errors;

class VM::Debugger::IOView :isa(VM::Debugger::UI::View) {
    field $width :param :reader;
    field $title :param :reader;
    field $from  :param :reader;

    method recalculate {
        $self->rect_width   = $width + 4;   # add four to the width for the box and indent
        $self->rect_height  = 2;            # start with two for the height for the box
        $self->rect_height += 2 if $title; # add two for the height of the title bar
        # add the number of memory cells to it
        $self->rect_height += scalar $self->snapshot->$from->@*;
    }

    method draw {
        my @lines = $self->snapshot->$from->@*;

        map { join '' => @$_ }
               ['╭─',('─' x $width),                 '─╮'],
               ['│ ',(sprintf "%-${width}s", $title),' │'],
               ['├─',('─' x $width),                 '─┤'],
        (map { ['│ ',(sprintf "%-${width}.${width}s" => $_),  ' │'] } @lines),
               ['╰─',('─' x $width),                 '─╯'],
    }
}
