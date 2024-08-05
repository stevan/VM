#!perl

use v5.40;
use experimental qw[ class ];

## --------------------------------------------------------

class VM::Inst::Op {
    use overload '""' => 'to_string';

    field $name :reader;

    ADJUST { ($name) = __CLASS__ =~ s/^VM::Inst::Op:://r }

    method arity { 0 }

    method to_string { $self->name }
}

class VM::Inst::Op::ZeroOp  :isa(VM::Inst::Op) {}
class VM::Inst::Op::StackOp :isa(VM::Inst::Op) {}
class VM::Inst::Op::UnOp    :isa(VM::Inst::Op) { method arity { 1 } }
class VM::Inst::Op::BinOp   :isa(VM::Inst::Op) { method arity { 2 } }

## --------------------------------------------------------

# ZeroOps
class VM::Inst::Op::NOOP          :isa(VM::Inst::Op::ZeroOp) {}
class VM::Inst::Op::HALT          :isa(VM::Inst::Op::ZeroOp) {}
class VM::Inst::Op::CONST_NIL     :isa(VM::Inst::Op::ZeroOp) {}
class VM::Inst::Op::CONST_TRUE    :isa(VM::Inst::Op::ZeroOp) {}
class VM::Inst::Op::CONST_FALSE   :isa(VM::Inst::Op::ZeroOp) {}
# UnOps
class VM::Inst::Op::CONST_NUM     :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::CONST_STR     :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::JUMP          :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::JUMP_IF_TRUE  :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::JUMP_IF_FALSE :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::LOAD          :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::STORE         :isa(VM::Inst::Op::UnOp) {}
class VM::Inst::Op::LOAD_ARG      :isa(VM::Inst::Op::UnOp) {}
# BinOps
class VM::Inst::Op::CALL          :isa(VM::Inst::Op::BinOp) {}
# StackOps
class VM::Inst::Op::ADD_NUM       :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::SUB_NUM       :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::MUL_NUM       :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::DIV_NUM       :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::MOD_NUM       :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::LT_NUM        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::GT_NUM        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::EQ_NUM        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::CONCAT_STR    :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::LT_STR        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::GT_STR        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::EQ_STR        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::ALLOC_MEM     :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::LOAD_MEM      :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::STORE_MEM     :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::FREE_MEM      :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::RETURN        :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::DUP           :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::POP           :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::SWAP          :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::PRINT         :isa(VM::Inst::Op::StackOp) {}
class VM::Inst::Op::WARN          :isa(VM::Inst::Op::StackOp) {}




