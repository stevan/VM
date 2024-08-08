#!perl

use v5.40;
use experimental qw[ class ];

use VM::MemoryBlocks;

class VM::Pointer::Type {
    use constant ANY   => Scalar::Util::dualvar( 0, 'any'   );
    use constant INT   => Scalar::Util::dualvar( 1, 'int'   );
    use constant FLOAT => Scalar::Util::dualvar( 2, 'float' );
    use constant CHAR  => Scalar::Util::dualvar( 3, 'char'  );
}

class VM::Pointer {
    use overload '""' => 'to_string';

    field $type    :param :reader;
    field $address :param :reader;
    field $block   :param :reader;
    field $size    :param :reader;
    field $backref :param :reader = undef;

    method to_string {
        sprintf '*%.1s[%s]<%04d:%.1s>' => $self->type, $self->size, $self->address, $self->block
    }
}

