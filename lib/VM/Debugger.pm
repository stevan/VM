#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

class VM::Debugger {

    field $root_view   :reader;
    field $stack_view  :reader;
    field $code_view   :reader;
    field $memory_view :reader;

    ADJUST {
        $code_view   = VM::Debugger::UI::CodeView   ->new( width => 32, title => 'Code'   );
        $stack_view  = VM::Debugger::UI::StackView  ->new( width => 32, title => 'Stack'  );
        $memory_view = VM::Debugger::UI::MemoryView ->new( width => 32, title => 'Memory' );

        $root_view = VM::Debugger::UI::ZippedViews->new(
            views => [
                $code_view,
                $stack_view,
                $memory_view,
            ]
        )
    }

    method rect_height { $root_view->rect_height }
    method rect_widht  { $root_view->rect_widht  }
    method display ($snapshot) {
        $root_view->update($snapshot);
        join "\n" => $root_view->draw;
    }
}

## ----------------------------------------------------------------------------
## Base View
## ----------------------------------------------------------------------------

class VM::Debugger::UI::View {
    field $snapshot :reader;

    field $rect_height;
    field $rect_width;

    method rect_height :lvalue { $rect_height }
    method rect_width  :lvalue { $rect_width  }

    # snapshots

    method update ($snap) {
        $snapshot = $snap;
        $self->recalculate;
    }

    # abstract methods

    method recalculate;
    method draw;

    # utilities

    method format_const ($const) {
        ref($const)
            ? (sprintf '*[%s]<%04d>' => $const->{size}, $const->{addr})
            : (not(defined($const))
                ? '~'
                : (is_bool($const)
                    ? ($const ? '#t' : '#f')
                    : (Scalar::Util::looks_like_number($const)
                        ? $const
                        : '"'.$const.'"')))
    }

    method format_opcode ($code, $labels, $width, $include_colors) {
        my $opcode_fmt = "%-${width}s";
        my $value_fmt  = "%${width}s";

        VM::Inst::is_opcode($code)
            ? (sprintf(($include_colors ? "\e[0;32m" : "")."${opcode_fmt}\e[0m" => $code))
            : (exists $labels->{"".$code}
                ? (sprintf(($include_colors ? "\e[0;36m" : "")."${value_fmt}\e[0m" => $code))
                : (sprintf(($include_colors ? "\e[0;34m" : "")."${value_fmt}\e[0m" =>
                    $self->format_const($code))))
    }
}

## ----------------------------------------------------------------------------
## Combiners
## ----------------------------------------------------------------------------

class VM::Debugger::UI::StackedViews :isa(VM::Debugger::UI::View) {
    field $views :param :reader;

    method recalculate {
        $_->update($self->snapshot) foreach @$views;

        $self->rect_height = List::Util::sum( map $_->rect_height, @$views );
        $self->rect_width  = List::Util::max( map $_->rect_width,  @$views );
    }

    method draw (@views) {
        my $max_height = $self->rect_height;

        my @out;
        foreach my $element (@$views) {
            push @out => $element->draw;
        }
        return @out;
    }
}

class VM::Debugger::UI::ZippedViews :isa(VM::Debugger::UI::View) {
    field $views   :param :reader;
    field $divider :param = ' ';

    method recalculate {
        $_->update($self->snapshot) foreach @$views;

        $self->rect_height = List::Util::max( map $_->rect_height, @$views );
        $self->rect_width  = List::Util::sum( map $_->rect_width,  @$views );
    }

    method draw (@views) {
        my $max_height = $self->rect_height;

        my @out;
        foreach my $element (@$views) {
            my @drawn = $element->draw;
            my $blank = (' ' x $element->rect_width);

            foreach my $i (0 .. $max_height) {
                if (defined $drawn[$i]) {
                    $out[$i] .= $divider . $drawn[$i];
                } else {
                    $out[$i] .= $divider . $blank;
                }
            }
        }
        return @out;
    }
}

## ----------------------------------------------------------------------------
##
## ----------------------------------------------------------------------------

class VM::Debugger::UI::MemoryView :isa(VM::Debugger::UI::View) {
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

class VM::Debugger::UI::StackView :isa(VM::Debugger::UI::View) {
    field $width :param;
    field $title :param :reader = undef;

    method recalculate {
        $self->rect_width   = $width + 4;   # add four to the width for the box and indent
        $self->rect_height  = 2;            # start with two for the height for the box
        $self->rect_height += 2 if $title; # add two for the height of the title bar
        # add the number of stack elements to it
        $self->rect_height += scalar $self->snapshot->stack->@*;
    }

    method draw {
        my $vm    = $self->snapshot;
        my @stack = $vm->stack->@*;

        my $title_fmt = "%-".$width."s";
        my $value_fmt = "%".($width - 7)."s";

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
    }
}


class VM::Debugger::UI::CodeView :isa(VM::Debugger::UI::View) {
    field $width :param;
    field $title :param :reader = undef;

    method recalculate {
        $self->rect_width   = $width + 4;   # add four to the width for the box and indent
        $self->rect_height  = 2;            # start with two for the height for the box
        $self->rect_height += 2 if $title; # add two for the height of the title bar

        # add the stuff needed here ...
        $self->rect_height = 60;
    }

    use Data::Dumper;

    method draw {
        my $vm         = $self->snapshot;
        my @code       = $vm->code->@*;
        my %labels     = $vm->labels->%*;
        my %rev_labels = reverse %labels;

        my @sorted_idxs = sort { $a <=> $b } keys %rev_labels;
        my @sorted_lbls = @rev_labels{ @sorted_idxs };

        my $code_length = $#code;

        my @collected;

        if (scalar @sorted_idxs == 1) {
            push @collected => [ $sorted_lbls[0], 0, $code_length ];
        }
        else {
            while (@sorted_idxs) {
                my $left_idx  = shift   @sorted_idxs;
                my $right_idx = defined $sorted_idxs[0] ? $sorted_idxs[0] - 1 : $code_length;
                my $label     = shift   @sorted_lbls;

                #warn "label: $label, l: $left_idx r: $right_idx";

                push @collected => [ $label, $left_idx, $right_idx ];
            }
        }

        #warn Dumper \@collected;

        my $top        = ['╭─',('─' x $width),'─╮'];
        my $bottom     = ['╰─',('─' x $width),'─╯'];
        my $full_fmt   = "%-".$width."s";
        my $count_fmt  = "%04d";

        my sub draw_title ($t) {
            (['│ ',(sprintf "\e[0;36m\e[1m${full_fmt}\e[0m" => $t),' │'],
             ['├─',('─' x $width),                                 '─┤'])
        }

        my sub draw_code ($i) {
            my @out;
            if ($vm->ci == $i) {
                push @out => ['│ ',
                    (sprintf "\e[0;33m\e[1m${count_fmt} ▶ %s" => $i, $self->format_opcode($code[$i], \%labels, ($width - 7), false)),
                ' │'];
            } else {
                push @out => ['│ ',
                    (sprintf "${count_fmt} ┊ %s" => $i, $self->format_opcode($code[$i], \%labels, ($width - 7), true)),
                ' │'];
            }
            return @out;
        }

        my sub draw_labels {
            my @out;
            foreach my $group (@collected) {
                my ($label, $start, $end) = @$group;

                push @out => $top;
                push @out => draw_title($label);
                #warn join ', ' => $vm->ci, $label, $start, $end;
                if ($vm->ci > $start && $vm->ci <= $end) {
                    push @out => map { draw_code($_) } ($start .. $end);
                    push @out => $bottom;
                } else {
                    pop @out;
                    push @out => $bottom;
                }
            }
            return @out;
        }

        map { join '' => @$_ } draw_labels();
    }
}

__END__

=pod

\e[0;30m    Black
\e[0;31m    Red
\e[0;32m    Green
\e[0;33m    Yellow
\e[0;34m    Blue
\e[0;35m    Purple
\e[0;36m    Cyan
\e[0;37m    White

\e[1m       Bold
\e[4m       Underline
\e[9m       Strikethrough
\e[0m       Reset

=cut

