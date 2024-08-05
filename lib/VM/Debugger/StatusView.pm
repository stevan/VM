#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

class VM::Debugger::StatusView :isa(VM::Debugger::UI::View) {
    field $width :param :reader;

    method recalculate {
        $self->rect_width  = $width + 4;
        $self->rect_height = 15 + scalar $self->snapshot->strings->@*;
    }

    method draw {
        state $anim_state = 0;

        if ($anim_state > 3) {
            $anim_state = 0;
        } else {
            $anim_state++;
        }
        #warn $anim_state;
        my $vm      = $self->snapshot;
        my $error   = $vm->error;
        my @strings = $vm->strings->@*;

        map { join '' => @$_ }
       ['╭─',('─' x $width),'─╮'],
       ['│ ',sprintf(
                (($error ? "☹️ \e[0;31m" : "☺️ \e[0;32m")."%-".($width - 3)."s\e[0m"),
                ($error // ('.' x $anim_state))
            ),' │'],
       ['├─',('─' x $width),'─┤'],
       ['│ ',sprintf("instruction counter = %0".($width - 22)."d" => $vm->ic),' │'],
       ['│ ',sprintf("current instruction = %0".($width - 22)."d" => $vm->ci),' │'],
       ['│ ',('┄' x $width),' │'],
       ['│ ',sprintf("      frame pointer = %0".($width - 22)."d" => $vm->fp),' │'],
       ['│ ',sprintf("      stack pointer = %0".($width - 22)."d" => List::Util::max(0, $vm->sp)),' │'],
       ['├─',('─' x $width),'─┤'],
       ['│ ',sprintf("%-${width}s" => "String Table"),' │'],
       ['├─',('─' x $width),'─┤'],
       (map { ['│ ',sprintf("%05d ┊ %-".($width - 8)."s" => $_, '"'.$strings[$_].'"'),' │'] } 0 .. $#strings),
       ['╰─',('─' x $width),'─╯'],
    }
}


