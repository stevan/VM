#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Errors;


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

