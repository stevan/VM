#!perl

use v5.40;
use experimental qw[ class ];

use VM::MemoryBlocks;

class VM::Pointer {
    use overload '""' => 'to_string';

    method address;
    method block;
    method size;

    method to_string {
        sprintf '*%.1s[%s]<%04d>' => $self->block, $self->size, $self->address
    }
}

class VM::Pointer::Null :isa(VM::Pointer) {
    use constant address => 0x00;
    use constant block   => VM::MemoryBlocks->NULL;
    use constant size    => 0;
}

class VM::Pointer::Static :isa(VM::Pointer) {
    use constant block => VM::MemoryBlocks->STATIC;

    field $address :param :reader;
    field $size    :param :reader = 1;
}

class VM::Pointer::Heap :isa(VM::Pointer) {
    use constant block => VM::MemoryBlocks->HEAP;

    field $address  :param :reader;
    field $size     :param :reader;
    field $ptr_addr :param :reader;
}
