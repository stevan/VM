#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util ();

class VM::MemoryBlocks {
    use constant NULL   => Scalar::Util::dualvar( undef, 'NULL'  );
    use constant STACK  => Scalar::Util::dualvar( 0,     'STACK' );
    use constant HEAP   => Scalar::Util::dualvar( 1,     'HEAP'  );
    use constant CODE   => Scalar::Util::dualvar( 2,     'CODE'  );
    use constant STATIC => Scalar::Util::dualvar( 3,     'STATIC');
}
