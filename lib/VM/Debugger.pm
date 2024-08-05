#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool ];

use Scalar::Util ();
use List::Util   ();
use Time::HiRes  ();

use VM::Inst;
use VM::Error;

use VM::Debugger::CodeView;
use VM::Debugger::StackView;
use VM::Debugger::MemoryView;

use VM::Debugger::UI::ZippedViews;
use VM::Debugger::UI::StackedViews;

class VM::Debugger {

    field $root_view   :reader;
    field $stack_view  :reader;
    field $code_view   :reader;
    field $memory_view :reader;

    ADJUST {
        $code_view   = VM::Debugger::CodeView   ->new( width => 50, title => 'Code' );
        $stack_view  = VM::Debugger::StackView  ->new( width => 32, title => 'Stack', stack_height => 30 );
        $memory_view = VM::Debugger::MemoryView ->new( width => 32, title => 'Memory' );

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

