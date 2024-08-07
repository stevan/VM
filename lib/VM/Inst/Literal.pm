#!perl

use v5.40;
use experimental qw[ class ];

class VM::Inst::Literal {
    use overload '""' => 'to_string';

    method value;
    method to_string;
}

class VM::Inst::Literal::INT :isa(VM::Inst::Literal) {
    field $value :param :reader;
    method to_string { sprintf 'i(%d)' => $value }
}

class VM::Inst::Literal::FLOAT :isa(VM::Inst::Literal) {
    field $value :param :reader;
    method to_string { sprintf 'f(%f)' => $value }
}

class VM::Inst::Literal::CHAR  :isa(VM::Inst::Literal) {
    field $value :param :reader;
    method to_string { sprintf "c(%s)" => $value }
}

class VM::Inst::Literal::TRUE  :isa(VM::Inst::Literal) {
    method value     { true }
    method to_string { '#t' }
}

class VM::Inst::Literal::FALSE  :isa(VM::Inst::Literal) {
    method value     { false }
    method to_string { '#f'  }
}

class VM::Inst::Literal::NIL  :isa(VM::Inst::Literal) {
    method value     { undef  }
    method to_string { '#nil' }
}
