#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

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
        $self;
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
}

