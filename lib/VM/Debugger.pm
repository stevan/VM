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

    field $vm :param;

    field $ui;

    ADJUST {
        $ui = VM::Debugger::UI::Zipped->new(
            elements => [
                VM::Debugger::UI::StackView->new(
                    vm    => $vm,
                    width => 32,
                    title => 'Stack'
                ),
                VM::Debugger::UI::CodeView->new(
                    vm    => $vm,
                    width => 32,
                    title => 'Code'
                ),
                VM::Debugger::UI::Stacked->new(
                    elements => [
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'Error',
                            contents => [ $vm->error ]
                        ),
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'STDOUT',
                            contents => [ $vm->stdout ]
                        ),
                        VM::Debugger::UI::Panel->new(
                            width    => 32,
                            title    => 'STDERR',
                            contents => [ $vm->stderr ]
                        ),
                    ]
                )
            ]
        );
    }

    method rect_height { $ui->rect_height }
    method rect_widht  { $ui->rect_widht  }
    method draw        { $ui->draw        }
}


class VM::Debugger::UI::Element {
    method rect_width;
    method rect_height;
    method draw;
}

class VM::Debugger::UI::Stacked :isa(VM::Debugger::UI::Element) {
    field $elements :param :reader;

    field $rect_height :reader;
    field $rect_width  :reader;

    ADJUST {
        $rect_height = List::Util::sum( map $_->rect_height, @$elements );
        $rect_width  = List::Util::max( map $_->rect_width,  @$elements );
    }

    method draw (@elements) {
        my $max_height = $rect_height;

        my @out;
        foreach my $element (@$elements) {
            push @out => $element->draw;
        }
        return @out;
    }
}

class VM::Debugger::UI::Zipped :isa(VM::Debugger::UI::Element) {
    field $elements :param :reader;
    field $divider  :param = ' ';

    field $rect_height :reader;
    field $rect_width  :reader;

    ADJUST {
        $rect_height = List::Util::max( map $_->rect_height, @$elements );
        $rect_width  = List::Util::sum( map $_->rect_width,  @$elements );
    }

    method draw (@elements) {
        my $max_height = $rect_height;

        #die join ', ' => (map $_->rect_height, @$elements), ":", $max_height;

        my @out;
        foreach my $element (@$elements) {
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

class VM::Debugger::UI::Panel :isa(VM::Debugger::UI::Element) {
    field $width       :param;
    field $height      :param = 0;
    field $title       :param :reader = undef;
    field $contents    :param :reader = [];

    field @rect;
    field $fmt;

    ADJUST {
        $height = List::Util::max($height, $#{$contents});
        $fmt    = "%-".$width."s";

        @rect = (
            ($width  + 4),         # add four to the height for the box and indent
            ($height + 2)          # add two to the height for the box
                + ($title ? 2 : 0) # add two to the height for the title
        );
    }

    method rect_width  { $rect[0] }
    method rect_height { $rect[1] }

    method draw {
        map { join '' => @$_ }
        ['╭─',('─' x $width),'─╮'],
        ($title
            ? (['│ ',(sprintf $fmt, $title),' │'],
               ['├─',('─' x $width),                '─┤'])
            : ()),
        (map {
            if (defined(my $v = $contents->[$_])) {
                ['│ ',(sprintf $fmt, $v),' │']
            } else {
                ['│ ',(' ' x $width),' │']
            }
        } 0 .. $height),
        ['╰─',('─' x $width),'─╯'],
    }
}

class VM::Debugger::UI::StackView :isa(VM::Debugger::UI::Element) {
    field $vm    :param;
    field $width :param;
    field $title :param :reader = undef;

    field $height = 0;
    field @rect;

    ADJUST {
        $height = List::Util::max($height, scalar($vm->stack));

        @rect = (
            ($width  + 4),         # add four to the height for the box and indent
            ($height + 2)          # add two to the height for the box
                + ($title ? 2 : 0) # add two to the height for the title
        );
    }

    method rect_width  { $rect[0] }
    method rect_height { $rect[1] }

    method draw {
        my @stack = $vm->stack;

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
                            not(defined($stack[$_]))
                                ? '~'
                                : is_bool($stack[$_])
                                    ? ($stack[$_] ? '#t' : '#f')
                                    : Scalar::Util::looks_like_number($stack[$_])
                                        ? $stack[$_]
                                        : '"'.$stack[$_].'"'
                        ))),
                ' │'
            ]
        } 0 .. $height),
        ['╰─',('─' x $width),'─╯'],
    }
}


class VM::Debugger::UI::CodeView :isa(VM::Debugger::UI::Element) {
    field $vm    :param;
    field $width :param;
    field $title :param :reader = undef;

    field $rect_height :reader;
    field $rect_width  :reader;

    ADJUST {
        $rect_width  = $width + 4;   # add four to the width for the box and indent
        $rect_height = 2;            # start with two for the height for the box
        $rect_height += 2 if $title; # add two for the height of the title bar

        my @code   = $vm->code;
        my %labels = $vm->labels;
        my @labels = keys %labels;

        $rect_height += scalar @code;
        $rect_height += (scalar(@labels) * 3);
    }

    method draw {
        my @code       = $vm->code;
        my %labels     = $vm->labels;
        my %rev_labels = reverse %labels;

        my $full_fmt   = "%-".$width."s";
        my $opcode_fmt = "%-".($width - 7)."s";
        my $value_fmt  = "%".($width - 7)."s";
        my $count_fmt  = "%04d";

        my sub formatted_code ($code, $include_colors) {
            VM::Inst::is_opcode($code)
                ? (sprintf(($include_colors ? "\e[0;32m" : "")."${opcode_fmt}\e[0m" => $code))
                : (exists $labels{"".$code}
                    ? (sprintf(($include_colors ? "\e[0;36m" : "")."${value_fmt}\e[0m" => $code))
                    : (sprintf(($include_colors ? "\e[0;34m" : "")."${value_fmt}\e[0m" =>
                        (Scalar::Util::looks_like_number($code)
                            ? $code
                            : '"'.$code.'"'))))
        }

        map { join '' => @$_ }
        ['╭─',('─' x $width),'─╮'],
        ($title
            ? (['│ ',(sprintf $full_fmt, $title),' │'],
               ['├─',('─' x $width),              '─┤'])
            : ()),
        (map {

            my @out;
            if (my $label = $rev_labels{$_}) {
                push @out => ['├─',('─' x $width),'─┤'] unless $_ == 0;
                push @out => ['│ ',(sprintf "\e[0;36m\e[1m${full_fmt}\e[0m" => $label),' │'];
                push @out => ['├─',('─' x $width),'─┤'];
            }

            if (($vm->pc - 1) == $_) {
                push @out => ['│ ',
                    (sprintf "\e[0;33m\e[1m${count_fmt} ▶ %s" => $_, formatted_code($code[$_], false)),
                ' │'];
            } else {
                push @out => ['│ ',
                    (sprintf "${count_fmt} ┊ %s" => $_, formatted_code($code[$_], true)),
                ' │'];
            }

            @out;
        } 0 .. $#code),
        ['╰─',('─' x $width),'─╯'],
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

