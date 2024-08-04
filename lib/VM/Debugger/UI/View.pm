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

