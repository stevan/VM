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

    field $title_fmt;
    field $count_fmt;
    field $value_fmt;

    field $active_fmt;
    field $inactive_fmt;
    field $label_fmt;

    ADJUST {
        $count_fmt = "%05d";
        $title_fmt = "%-${width}s";
        $value_fmt = "%-".($width - 8)."s"; # remove 8, 5 for counter and 3 for divider

        $active_fmt   = "\e[0;33m\e[7m ${count_fmt} ▶ ${value_fmt} \e[0m";
        $inactive_fmt = " ${count_fmt} ┊ ${value_fmt} \e[0m";
        $label_fmt    = "\e[0;96m\e[4m\e[1m${title_fmt}  \e[0m";
    }

    method recalculate {
        $self->rect_width  = $width + 4; # add four to the width for the box and indent
        $self->rect_height = 5; # start at five to the stack-height for the box top and bottom

        my $vm = $self->snapshot;
        $self->rect_height += (
            (scalar grep { blessed $_ && $_->isa('VM::Inst::Op') } $vm->code->@*)
            + (scalar keys $vm->labels->%*)
        );
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

    method draw_line ($vm, $line_num, $opcode, @args) {
        my %rev_labels = reverse $vm->labels->%*;
        my @out;

        if (exists $rev_labels{ $line_num }) {
            push @out => ['│',(sprintf $label_fmt => $rev_labels{$line_num}),'│'],;
        }

        if ($vm->ci == $line_num) {
            push @out => ['│',(sprintf $active_fmt   => $line_num, $self->format_opcode($vm, $opcode, \@args, false)),'│'];
        } else {
            push @out => ['│',(sprintf $inactive_fmt => $line_num, $self->format_opcode($vm, $opcode, \@args, true )),'│'];
        }

        return @out;
    }

    method format_opcode ($vm, $opcode, $args, $include_colors) {
        my $name = $opcode->name;

        my $op_fmt  = "%-s";
        my $val_fmt = "%".(($width - 8) - length $name)."s";

        if ($opcode->arity) {
            sprintf(($include_colors ? "\e[0;32m" : "").$op_fmt.
                    ($include_colors ? "\e[0;34m" : "").$val_fmt
                        => $name, join ', ' => map {
                                        if (exists $vm->labels->{$_}) {
                                            $_
                                        } else {
                                            $self->format_const($_)
                                        }
                                    } @$args);
        } else {
            sprintf(($include_colors ? "\e[0;32m" : "")."%-".($width - 8)."s" => $name);
        }
    }

    method draw {
        my $vm     = $self->snapshot;
        my @code   = $vm->code->@*;
        my %labels = $vm->labels->%*;

        my $line_num = 0;
        my @lines;
        while (@code) {
            my $code = shift @code;

            #warn "GOT CODE: $code";

            if ($code isa VM::Inst::Op) {
                #warn "GOT OP: $code";
                my @line = ($line_num, $code);
                if (my $arity = $code->arity) {
                    #warn "GOT ARITY: $arity";
                    while ($arity--) {
                        push @line => shift @code;
                        $line_num++;
                    }
                }
                push @lines => \@line;
                $line_num++;
            }
        }

        map { join '' => @$_ }
        $self->draw_header($vm),
        (map { $self->draw_line( $vm, @$_ ) } @lines),
        $self->draw_footer($vm, $lines[0]->[0], $lines[-1]->[0], $line_num - 1),

    }

}
