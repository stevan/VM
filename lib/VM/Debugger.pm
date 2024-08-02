#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

class VM::Debugger::UI {

}


class VM::Debugger::UI::Panel {
    field $width    :param :reader;
    field $height   :param :reader = 0;

    field $align_right :param :reader = false;

    field $title    :param :reader = undef;
    field $contents :param :reader = [];

    field $rect;

    field $fmt;

    ADJUST {
        $height = List::Util::max($height, $#{$contents});
        $fmt    = "%".($align_right ? '' : '-').$width."s";

        $rect = [
            ($width  + 2),         # add two to the height for the box
            ($height + 2)          # add two to the height for the box
                + ($title ? 2 : 0) # add two to the height for the title
        ];
    }

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


