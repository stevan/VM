#!perl

use v5.40;
use experimental qw[ class ];

## --------------------------------------------------------

class Source {
    method next;
    method has_next;
}

class Operation {
    method next;
    method has_next;
}

class Terminal {
    method apply;
}

## --------------------------------------------------------

class ArraySource :isa(Source) {
    field $values :param;
    field $index = 0;

    method next     { $values->[$index++] }
    method has_next { $index < scalar @$values }
}

class ForEach :isa(Terminal) {
    field $source :param;
    field $f      :param;

    method apply {
        while ($source->has_next) {
            $f->($source->next)
        }
        return;
    }
}

class Map :isa(Operation) {
    field $source :param;
    field $f      :param;

    method next     { $f->($source->next) }
    method has_next { $source->has_next   }
}

class Peek :isa(Operation) {
    field $source :param;
    field $f      :param;

    method next     { my $n = $source->next; $f->($n); $n }
    method has_next { $source->has_next }
}

## --------------------------------------------------------

class Stream {
    field $source :param = undef;

    method from_list (@list) {
        $source = ArraySource->new( values => [ @list ] );
        return $self;
    }

    method map ($f) {
        return
            Stream->new( source =>
                Map->new( source => $source, f => $f ))
    }

    method peek ($f) {
        return
            Stream->new( source =>
                Peek->new( source => $source, f => $f ))
    }

    method foreach ($f) {
        ForEach->new( source => $source, f => $f )->apply;
        return;
    }
}

## --------------------------------------------------------

Stream
    ->new
    ->from_list(0 .. 10)
    ->peek    (sub ($x) { say "BEFORE: $x" })
    ->map     (sub ($x) { $x * 2 })
    ->peek    (sub ($x) { say "AFTER: $x" })
    ->foreach (sub ($x) { say $x })
;





