#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

class VM::Debugger::MemoryView :isa(VM::Debugger::UI::View) {
    field $width :param;
    field $title :param :reader = undef;

    method recalculate {
        $self->rect_width   = $width + 4;   # add four to the width for the box and indent
        $self->rect_height  = 2;            # start with two for the height for the box
        $self->rect_height += 2 if $title; # add two for the height of the title bar
        # add the number of memory cells to it
        $self->rect_height += scalar $self->snapshot->memory->@*;
    }

    method draw {
        my @memory = $self->snapshot->memory->@*;

        my $title_fmt = "%-".$width."s";
        my $value_fmt = "%".($width - 7)."s";

        map { join '' => @$_ }
        ['╭─',('─' x $width),'─╮'],
        ($title
            ? (['│ ',(sprintf $title_fmt, $title),' │'],
               ['├─',('─' x $width),              '─┤'])
            : ()),
        (map {
            ['│ ',(sprintf "%05d ┊${value_fmt}" => $_, $self->format_const($memory[$_])),' │']
        } 0 .. $#memory),
        ['╰─',('─' x $width),'─╯'],
    }
}
