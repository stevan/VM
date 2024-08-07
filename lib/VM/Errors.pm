#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util;

package VM::Errors {

    our @ERRORS;
    BEGIN {
        @ERRORS = qw(
            FATAL_ERROR

            UNKNOWN_OPCODE
            UNEXPECTED_END_OF_CODE

            ILLEGAL_DIVISION_BY_ZERO
            ILLEGAL_MOD_BY_ZERO

            MEMORY_ACCESS_OUT_OF_BOUNDS
            INCOMPATIBLE_POINTERS
            MEMORY_ALREADY_FREED
        );

        foreach my $i (0 .. $#ERRORS) {
            no strict 'refs';
            my $error = $ERRORS[$i];
            $ERRORS[$i] = Scalar::Util::dualvar( $i, $error );
            *{__PACKAGE__."::${error}"} = sub { $ERRORS[$i] };
        }
    }
}
