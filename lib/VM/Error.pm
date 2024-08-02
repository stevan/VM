#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util;

package VM::Errors {

    our @ERRORS;
    BEGIN {
        @ERRORS = qw(
            UNKNOWN_OPCODE
            ILLEGAL_DIVISION_BY_ZERO
            UNEXPECTED_END_OF_CODE
            ILLEGAL_MOD_BY_ZERO
        );

        foreach my $i (0 .. $#ERRORS) {
            no strict 'refs';
            my $error = $ERRORS[$i];
            $ERRORS[$i] = Scalar::Util::dualvar( $i, $error );
            *{__PACKAGE__."::${error}"} = sub { $ERRORS[$i] };
        }
    }
}
