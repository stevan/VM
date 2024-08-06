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
    field $width  :param :reader;
    field $height :param :reader;
    field $title  :param :reader;

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
        $self->rect_width  = $width  + 4; # add four to the width for the box and indent
        $self->rect_height = $height + 4; # start at five to the stack-height for the box top and bottom
    }

    method draw_header ($) {
        ['╭─',('─' x $width),              '─╮'],
        ['│ ',(sprintf $title_fmt, $title),' │'],
        ['├─',('─' x $width),              '─┤'],
    }

    method draw_footer ($) {
        #my $footer = sprintf "${count_fmt} ... ${count_fmt} of ${count_fmt}" => $start, $end, $size;
        #['├─',('─' x $width),               '─┤'],
        #['│ ',(sprintf $title_fmt, $footer),' │'],
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
                                        if (blessed $_) {
                                            $self->format_const($vm->statics->[ $_->address ])
                                        } elsif (exists $vm->labels->{$_}) {
                                            $_
                                        } else {
                                            $self->format_const($_)
                                        }
                                    } @$args);
        } else {
            sprintf(($include_colors ? "\e[0;32m" : "")."%-".($width - 8)."s" => $name);
        }
    }

    method draw_fill_line {
        ['│ ',(sprintf "\e[0;35m${title_fmt}\e[0m" => '00000 ┊'),'   │'];
    }

    method draw {
        my $vm     = $self->snapshot;
        my @code   = $vm->code->@*;
        my %labels = $vm->labels->%*;

        my $ci_index = 0;

        my $line_num = 0;
        my @lines;
        while (@code) {
            my $code = shift @code;

            #warn "GOT CODE: $code";

            if ($code isa VM::Inst::Op) {
                #warn "GOT OP: $code";
                my @line = ($line_num, $code);

                $ci_index = scalar @lines if $vm->ci == $line_num;

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

        # do this to add the labels in ...
        my @drawn_lines = map { $self->draw_line( $vm, @$_ ) } @lines;

        # determine how much to draw
        my @lines_to_draw = @drawn_lines;

        my $num_lines = scalar @drawn_lines;

        if ($num_lines < $height) {
            foreach my $i (0 .. ($height - 1)) {
                push @lines_to_draw => $self->draw_fill_line
                    unless $drawn_lines[$i];
            }
        } else {
            my $start = $num_lines - $height;
            my $fixed = $height - 1;
            my $end   = $fixed + $start;

            if ($ci_index < $start && $ci_index < $end) {
                #warn "CI(${ci_index}) outside the view (s: $start, f: $fixed, e: $end)";
                $start = $ci_index;
                $end   = $fixed + $start;
                #warn "FIXED: CI(${ci_index}) outside the view (s: $start, f: $fixed, e: $end)";
            }
            #else {
            #    warn "CI(${ci_index}) inside the view (s: $start, f: $fixed, e: $end)";
            #}

            @lines_to_draw = @lines_to_draw[ $start .. $end ];
        }

        map { join '' => @$_ }
        $self->draw_header($vm),
        @lines_to_draw,
        $self->draw_footer($vm),
    }

}
