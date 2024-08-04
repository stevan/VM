#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

class VM::Debugger::CodeView :isa(VM::Debugger::UI::View) {
    field $width       :param :reader;
    field $title       :param :reader;
    field $code_height :param;

    field $title_fmt;
    field $count_fmt;
    field $value_fmt;

    field $label_fmt;
    field $active_fmt;
    field $inactive_fmt;
    field $deadcode_fmt;

    ADJUST {
        $count_fmt    = "%05d";
        $title_fmt    = "%-${width}s";
        $value_fmt    = "%".($width - 8)."s"; # remove 8, 5 for counter and 3 for divider

        $label_fmt    = "\e[0;36m\e[4m${title_fmt}\e[0m";
        $active_fmt   = "\e[0;33m\e[1m${count_fmt} ▶ ${value_fmt}\e[0m";
        $inactive_fmt = "${count_fmt} ┊ ${value_fmt}";
        $deadcode_fmt = "\e[38;5;240m${count_fmt} ┊ ${value_fmt}\e[0m";

    }

    method recalculate {
        $self->rect_width  = $width  + 4;      # add four to the width for the box and indent
        $self->rect_height = $code_height + 5; # add five to the stack-height for the box top and bottom
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

        return ['│ ',(sprintf $deadcode_fmt => $line_num, ' '),' │'] unless defined $data;

        my %labels     = $vm->labels->%*;
        my %rev_labels = reverse %labels;

        my @out;

        if (exists $rev_labels{$line_num}) {
            push @out => ['│ ',(sprintf $label_fmt => $rev_labels{$line_num}),' │'],;
        }

        if ($vm->ci == $line_num) {
            push @out => ['│ ',
                (sprintf $active_fmt => $line_num, $self->format_opcode($data, \%labels, ($width - 8), false)),
            ' │']
        } else {
            push @out => ['│ ',
                (sprintf $inactive_fmt => $line_num, $self->format_opcode($data, \%labels, ($width - 8), true)),
            ' │']
        }

        return @out;
    }

    method draw {
        my $vm     = $self->snapshot;
        my @code   = $vm->code->@*;

        my $code_size  = scalar @code;
        my $fixed_size = $code_height - 1;

        my @code_idxs;
        if ($code_size <= $code_height) {
            # if it is smaller than the height,
            # then we have no worries
            @code_idxs = (0 .. $fixed_size);
        } else {
            #warn "CI: ".$vm->ci;
            my $offset = 0;

            if ($vm->ci > $code_height) {
                $offset = $vm->ci - $fixed_size;
            }

            @code_idxs = ($offset .. ($fixed_size + $offset));
        }

        my %labels     = $vm->labels->%*;
        my %rev_labels = reverse %labels;

        my $num_labels = scalar grep defined, @rev_labels{ @code_idxs };
        if ($num_labels) {
            #warn "BEFORE -($num_labels): ", join ", " => @code_idxs;
            splice @code_idxs, -$num_labels;
            #warn "AFTER: ", join ", " => @code_idxs;
        }

        map { join '' => @$_ }
        $self->draw_header($vm),
        (map {
            $self->draw_line( $vm, $_, ($_ < @code ? $code[$_] : undef) )
        } @code_idxs),
        $self->draw_footer($vm, $code_idxs[0], $code_idxs[-1], $#code),
    }

}
