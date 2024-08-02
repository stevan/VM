#!perl

use v5.40;
use experimental qw[ class ];

class Result {
    use overload '""' => \&to_string;

    field $ok    :param :reader = undef;
    field $error :param :reader = undef;

    method failure { !! $error }
    method success { !! $ok    }

    method get_or_else ($f) { $ok // (ref $f eq 'CODE' ? $f->() : $f) }
    method or_else     ($f) { defined $ok ? Result->new(ok => $ok) : (ref $f eq 'CODE' ? $f->() : $f) }

    method map ($f) { defined $ok ? Result->new(ok => $f->($ok)) : Result->new(error => $error) }

    method to_string {
        return defined $ok
            ? sprintf 'Ok(%s)'    => $ok
            : sprintf 'Error(%s)' => $error;
    }
}

sub Ok    ($value) { Result->new(ok    => $value) }
sub Error ($error) { Result->new(error => $error) }

sub divide ($x, $y) {
    return Error('Cannot divide by zero') if $y == 0;
    return Ok( $x / $y );
}

warn divide(1, 0)->or_else(Ok(0));
warn divide(1, 2)->map(sub ($x) { $x * 10 });

