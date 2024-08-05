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
        $self->rect_width  = $width + 4;   # add four to the width for the box and indent
        $self->rect_height = 3;            # start with two for the height for the box
    }

    method draw {
        state $anim_state = 0;

        if ($anim_state > 3) {
            $anim_state = 0;
        } else {
            $anim_state++;
        }
        #warn $anim_state;
        my $vm    = $self->snapshot;
        my $error = $vm->error;

        map { join '' => @$_ }
       ['╭─',('─' x $width),'─╮'],
       ['│ ',sprintf(
                (($error ? "☹️ \e[0;31m" : "☺️ \e[0;32m")."%-".($width - 3)."s\e[0m"),
                ($error // ('.' x $anim_state))
            ),' │'],
       ['├─',('─' x $width),'─┤'],
       ['│ ',sprintf("     program counter = %-".($width - 23).".5d" => $vm->pc),' │'],
       ['│ ',sprintf(" instruction counter = %-".($width - 23).".5d" => $vm->ic),' │'],
       ['│ ',sprintf(" current instruction = %-".($width - 23).".5d" => $vm->ci),' │'],
       ['│ ',sprintf("       frame pointer = %-".($width - 23).".5d" => $vm->fp),' │'],
       ['│ ',sprintf("       stack pointer = %-".($width - 23).".5d" => $vm->sp),' │'],
       ['╰─',('─' x $width),'─╯'],
    }
}


