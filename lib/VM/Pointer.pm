#!perl

use v5.40;
use experimental qw[ class ];

class VM::Pointer {
    use overload '""' => 'to_string';

    field $address :param :reader;

    field $type :reader;
    ADJUST { ($type) = __CLASS__ =~ /^VM::Pointer::(.)/ }

    method size;

    method to_string { sprintf '*%s[%s]<%04d>' => $self->type, $self->size, $self->address }
}

class VM::Pointer::String :isa(VM::Pointer) {
    field $size :param :reader;
}

class VM::Pointer::Memory :isa(VM::Pointer) {
    field $size    :param :reader;
    field $refaddr :param :reader; # where in the pointer table does it live
}
