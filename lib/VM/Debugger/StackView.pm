#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Errors;

class VM::Debugger::StackView :isa(VM::Debugger::UI::View) {
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
        $sp_fmt       = "${count_fmt} %s\e[0;33m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_fmt       = "${count_fmt} %s\e[0;32m\e[4m\e[1m${value_fmt}\e[0m";
        $fp_inner_fmt = "${count_fmt} %s\e[0;32m\e[2m\e[1m${value_fmt}\e[0m";
        $above_sp_fmt = "\e[38;5;240m${count_fmt} %s${value_fmt}\e[0m";
        $above_fp_fmt = "${count_fmt} %s\e[0;33m\e[1m${value_fmt}\e[0m";
        $active_fmt   = "${count_fmt} %s\e[0;36m${value_fmt}\e[0m";
    }

    method recalculate {
        $self->rect_width  = $width  + 4;       # add four to the width for the box and indent
        $self->rect_height = $stack_height + 5; # add five to the stack-height for the box top and bottom
    }

    method draw_header ($) {
        ['╭─',('─' x $width),              '─╮'],
        ['│ ',(sprintf $title_fmt, $title),' │'],
        ['├─',('─' x $width),              '─┤'],
    }

    method draw_footer ($, $start, $end) {
        my $footer = sprintf "${count_fmt}..${count_fmt}" => $start, $end;
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

        ['│ ',(sprintf $data_fmt => $line_num, $divider, $self->format_const($data)),' │']
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
        $self->draw_footer($vm, $stack_idxs[0], $vm->sp),
    }

}
