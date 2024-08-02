#!perl

use v5.40;
use experimental qw[ class ];

class Option {
    use overload '""' => \&to_string;

    field $some :param = undef;

    method defined { !!$some || false }
    method empty   { !!$some || true  }

    method get { $some // die 'Runtime Error: calling get on None' }

    method get_or_else ($f) { $some // (ref $f eq 'CODE' ? $f->() : $f) }
    method or_else     ($f) { Option->new(some => $some) // (ref $f eq 'CODE' ? $f->() : $f) }

    method map ($f) { defined $some ? Option->new(some => $f->($some)) : Option->new }

    method to_string {
        return defined $some
            ? sprintf 'Some(%s)' => $some
            : 'None()';
    }
}

sub Some ($value) { Option->new(some  => $value) }
sub None ()       { Option->new }


warn Some(100);
warn None->or_else(Some(0));
warn None->get_or_else(20);

























