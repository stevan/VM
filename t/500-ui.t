#!perl

use v5.40;
use experimental qw[ class builtin ];

use VM;
use VM::Debugger;


class StackView :isa(VM::Debugger::UI::View) {
    field $width        :param :reader;
    field $title        :param :reader;
    field $stack_height :param;

    field $title_fmt;
    field $count_fmt;
    field $value_fmt;

    field $sp_fmt;
    field $fp_fmt;

    field $fp_inner_fmt;
    field $above_sp_fmt;
    field $above_fp_fmt;

    field $active_fmt;

    my $double_arrow = '▶';
    my $single_arrow = '▷';
    my $divider_line = '┊';

    ADJUST {
        $count_fmt    = "%05d";
        $title_fmt    = "%-${width}s";
        $value_fmt    = "%".($width - 7)."s"; # remove 7, 5 for counter and 2 for divider
        $sp_fmt       = "\e[0;33m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_fmt       = "\e[0;32m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_inner_fmt = "\e[0;32m\e[2m\e[1m${value_fmt}\e[0m";
        $above_sp_fmt = "\e[0;36m\e[2m${value_fmt}\e[0m";
        $above_fp_fmt = "\e[0;33m\e[1m${value_fmt}\e[0m";
        $active_fmt   = "\e[0;36m${value_fmt}\e[0m";
    }

    method recalculate {
        $self->rect_width  = $width  + 4;       # add four to the width for the box and indent
        $self->rect_height = $stack_height + 4; # add four to the stack-height for the box top and bottom
    }

    method draw_header ($) {
        ['╭─',('─' x $width),              '─╮'],
        ['│ ',(sprintf $title_fmt, $title),' │'],
        ['├─',('─' x $width),              '─┤'],
    }

    method draw_footer ($, $start, $end, $size) {
        my $footer = sprintf "${count_fmt} ... ${count_fmt} of ${count_fmt}" => $start, $end, $size;
        ['├─',('─' x $width),               '─┤'],
        ['│ ',(sprintf $title_fmt, $footer),' │'],
        ['╰─',('─' x $width),               '─╯'],
    }

    method draw_line ($vm, $line_num, $data) {
        my $divider = ($_ == $vm->fp && $_ == $vm->sp
                        ? $double_arrow
                        : $_ == $vm->fp
                            ? $single_arrow
                            : $_ == $vm->sp ? $single_arrow : $divider_line);

        my $data_fmt = ($_ == $vm->sp
                            ? $sp_fmt
                            : ($_ == $vm->fp
                                ? $fp_fmt
                                : ($_ < $vm->sp
                                    ? ($_ > $vm->fp
                                        ? $above_fp_fmt
                                        : ($_ > ($vm->fp - 3)
                                            ? $fp_inner_fmt
                                            : $active_fmt))
                                    : $above_sp_fmt)));

        ['│ ',(sprintf "${count_fmt} %s${data_fmt}" => $line_num, $divider, $self->format_const($data)),' │']
    }

    method draw {
        my $vm    = $self->snapshot;
        my @stack = $vm->stack->@*;

        #warn scalar @stack;

        my $stack_size = scalar @stack;
        my $fixed_size = $stack_height - 1;

        my @stack_idxs;
        if ($stack_size <= $stack_height) {
            # if it is smaller than the height,
            # then we have no worries
            @stack_idxs = (0 .. $fixed_size);
        } else {
            my $offset = $stack_size - $stack_height;

            if ($vm->fp <= $offset) {
                $offset = $vm->fp
                    ? $vm->fp - ($stack[ $vm->fp - 2 ] + 2)
                    : 0;
            }

            @stack_idxs = ($offset .. ($fixed_size + $offset));
        }

        map { join '' => @$_ }
        $self->draw_header($vm),
        (map {
            $self->draw_line( $vm, $_, ($_ < @stack ? $stack[$_] : undef) )
        } reverse @stack_idxs),
        $self->draw_footer($vm, $stack_idxs[0], $stack_idxs[-1], $#stack),
    }

}


say join "\n" => StackView->new(
    width => 40,
    title => 'Stack',

    stack_height => 20,
)->update(
    VM::Snapshot->new(
        code    => undef,
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
        labels  => undef,

        stdout  => undef,
        stderr  => undef,

        pc      => undef,
        ic      => undef,
        ci      => undef,
        fp      => 10,
        sp      => 13,

        running => undef,
        error   => undef,
    )
)->draw;



=pod

╭──────────────────────────────────╮
│ Stack                            │
├──────────────────────────────────┤
│ 00117 ┊                        ~ │
│ 00116 ┊                        ~ │
│ 00115 ┊                        ~ │
│ 00114 ┊                        ~ │
│ 00113 ┊                        ~ │
│ 00112 ┊                        ~ │
│ 00111 ┊                        ~ │
│ 00110 ┊                        ~ │
│ 00109 ┊                        ~ │
│ 00108 ┊                        ~ │
│ 00107 ┊                        ~ │
│ 00106 ▷                        3 │
│ 00105 ┊                       72 │
│ 00104 ┊                        0 │
│ 00103 ▷                        3 │
│ 00102 ┊                        5 │
│ 00101 ┊                        3 │
│ 00100 ┊               *[3]<0000> │
│ 00099 ┊               *[3]<0000> │
│ 00099 ┊               *[3]<0000> │
├──────────────────────────────────┤
│ Stack                            │
╰──────────────────────────────────╯









        map { join '' => @$_ }
        ['╭─',('─' x $width),'─╮'],
        ($title
            ? (['│ ',(sprintf $title_fmt, $title),' │'],
               ['├─',('─' x $width),              '─┤'])
            : ()),
        (map {
            [
                '│ ',
                (sprintf '%05d %s%s' =>
                    $_,
                    ($_ == $vm->fp && $_ == $vm->sp
                        ? '▶'
                        : $_ == $vm->fp
                            ? '▷'
                            : $_ == $vm->sp
                                ? '▷'
                                : '┊'),,
                    (sprintf(
                        ($_ == $vm->sp
                            ? "\e[0;33m\e[4m\e[1m${value_fmt}\e[0m"
                            : ($_ == $vm->fp
                                ? "\e[0;32m\e[4m\e[1m${value_fmt}\e[0m"
                                : ($_ < $vm->sp
                                    ? ($_ > $vm->fp
                                        ? "\e[0;33m\e[1m${value_fmt}\e[0m"
                                        : "\e[0;36m${value_fmt}\e[0m")
                                    : "\e[0;36m\e[2m${value_fmt}\e[0m"))),
                            $self->format_const($stack[$_])
                        ))),
                ' │'
            ]
        } 0 .. $#stack),
        ['╰─',('─' x $width),'─╯'],
=cut
