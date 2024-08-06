#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util ();

class VM::MemoryBlocks {
    use constant NULL   => Scalar::Util::dualvar(0, 'NULL'  );
    use constant STACK  => Scalar::Util::dualvar(1, 'STACK' );
    use constant HEAP   => Scalar::Util::dualvar(2, 'HEAP'  );
    use constant CODE   => Scalar::Util::dualvar(3, 'CODE'  );
    use constant STATIC => Scalar::Util::dualvar(4, 'STATIC');
}
