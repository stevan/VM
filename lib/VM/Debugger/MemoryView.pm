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
        $self->rect_height +=
            (scalar $self->snapshot->memory->@*) + 5 +
            (scalar $self->snapshot->pointers->@*);

    }

    method draw {
        state @ptr_colors;
        state @memory_colors;
        state @memory_pointers;

        my @memory   = $self->snapshot->memory->@*;
        my @pointers = $self->snapshot->pointers->@*;

        my $title_fmt = "%-".$width."s";
        my $value_fmt = "%".($width - 7)."s";

        my @ptrs = (map {
            my $a = $_;
            my $c = $ptr_colors[$a] //= join ':' => map { int(rand($_)) } (175, 50, 255);
            my $p = $pointers[$a];
            if (defined $p) {
                map {
                    $memory_colors   [$_] = $c;
                    $memory_pointers [$_] = $a;
                } ($p->address .. ($p->address + ($p->size - 1)));
                ['│ ',(sprintf "\e[48:2:${c}m%05d ┊${value_fmt}\e[0m" => $_, $self->format_const($p)),' │'];
            } else {
                ['│ ',(sprintf "%05d ┊${value_fmt}" => $_, '~'),' │'];
            }
        } 0 .. $#pointers);

        map { join '' => @$_ }
        ['╭─',('─' x $width),'─╮'],
        ($title
            ? (['│ ',(sprintf $title_fmt, $title),' │'],
               ['├─',('─' x $width),              '─┤'])
            : ()),
        (map {
            my $c = $memory_colors[$_];
            my $p = $pointers[$memory_pointers[$_]];
            my $m = $memory[$_];
            if (defined $p) {
                ['│ ',(sprintf "\e[48:2:${c}m%05d ┊${value_fmt}\e[0m" => $_, $self->format_const($m)),' │']
            } else {
                ['│ ',(sprintf "%05d ┊${value_fmt}" => $_, '~'),' │']
            }
        } 0 .. $#memory),
        ['├─',('─' x $width),'─┤'],
        ['│ ',(sprintf $title_fmt, 'Pointers'),' │'],
        ['├─',('─' x $width),'─┤'],
        @ptrs,
        ['╰─',('─' x $width),'─╯'],
    }
}
