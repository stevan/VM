#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool created_as_string created_as_number export_lexically ];

use VM::Inst;
use VM::Inst::Op;
use VM::Inst::Literal;
use VM::Pointer;

package VM::Assembler::Assembly;

sub import {
    no strict 'refs';

    my @exports;

    my $into = caller;
    foreach my $opcode (keys %VM::Assembler::Assembly::) {
        push @exports => (
            '&'.$opcode => \&{$opcode}
        );
    }

    export_lexically @exports;

}

my sub clean_label ($label) { $label =~ s/^\*main::/*/r }

sub label :prototype($) ($label) { VM::Inst->label(clean_label($label)) }

sub i     :prototype($) ($int)   { VM::Inst::Literal::INT->new( value => $int ) }
sub f     :prototype($) ($float) { VM::Inst::Literal::FLOAT->new( value => $float ) }
sub c     :prototype($) ($char)  { VM::Inst::Literal::CHAR->new( value => $char ) }

sub NOOP          :prototype()   ()              { VM::Inst->NOOP }

sub CONST_NIL     :prototype()   ()              { VM::Inst->CONST_NIL }

sub CONST_TRUE    :prototype()   ()              { VM::Inst->CONST_TRUE }
sub CONST_FALSE   :prototype()   ()              { VM::Inst->CONST_FALSE }

sub CONST_INT     :prototype($)  ($int)         { VM::Inst->CONST_INT, $int }
sub CONST_FLOAT   :prototype($)  ($float)       { VM::Inst->CONST_FLOAT, $float }
sub CONST_CHAR    :prototype($)  ($char)        { VM::Inst->CONST_CHAR, $char }
sub CONST_STR     :prototype($)  ($str)         { VM::Inst->CONST_STR, $$str }

sub SUB_INT       :prototype()   ()              { VM::Inst->SUB_INT }
sub ADD_INT       :prototype()   ()              { VM::Inst->ADD_INT }
sub MUL_INT       :prototype()   ()              { VM::Inst->MUL_INT }
sub DIV_INT       :prototype()   ()              { VM::Inst->DIV_INT }
sub MOD_INT       :prototype()   ()              { VM::Inst->MOD_INT }

sub SUB_FLOAT     :prototype()   ()              { VM::Inst->SUB_FLOAT }
sub ADD_FLOAT     :prototype()   ()              { VM::Inst->ADD_FLOAT }
sub MUL_FLOAT     :prototype()   ()              { VM::Inst->MUL_FLOAT }
sub DIV_FLOAT     :prototype()   ()              { VM::Inst->DIV_FLOAT }
sub MOD_FLOAT     :prototype()   ()              { VM::Inst->MOD_FLOAT }

sub CONCAT_STR    :prototype()   ()              { VM::Inst->CONCAT_STR }
sub FORMAT_STR    :prototype($$) ($fmt,   $argc) { VM::Inst->FORMAT_STR, $fmt, $$argc }

sub EQ_INT        :prototype()   ()              { VM::Inst->EQ_INT }
sub LT_INT        :prototype()   ()              { VM::Inst->LT_INT }
sub GT_INT        :prototype()   ()              { VM::Inst->GT_INT }

sub EQ_FLOAT      :prototype()   ()              { VM::Inst->EQ_FLOAT }
sub LT_FLOAT      :prototype()   ()              { VM::Inst->LT_FLOAT }
sub GT_FLOAT      :prototype()   ()              { VM::Inst->GT_FLOAT }

sub EQ_CHAR       :prototype()   ()              { VM::Inst->EQ_CHAR }
sub LT_CHAR       :prototype()   ()              { VM::Inst->LT_CHAR }
sub GT_CHAR       :prototype()   ()              { VM::Inst->GT_CHAR }

sub JUMP          :prototype($)  ($label)        { VM::Inst->JUMP, VM::Inst->marker(clean_label($label)) }
sub JUMP_IF_FALSE :prototype($)  ($label)        { VM::Inst->JUMP_IF_FALSE, VM::Inst->marker(clean_label($label)) }
sub JUMP_IF_TRUE  :prototype($)  ($label)        { VM::Inst->JUMP_IF_TRUE,  VM::Inst->marker(clean_label($label)) }

sub LOAD          :prototype($)  ($idx)          { VM::Inst->LOAD, $$idx }
sub STORE         :prototype($)  ($idx)          { VM::Inst->STORE, $$idx }


sub ALLOC_MEM     :prototype()   ()              { VM::Inst->ALLOC_MEM }
sub LOAD_MEM      :prototype()   ()              { VM::Inst->LOAD_MEM }
sub STORE_MEM     :prototype()   ()              { VM::Inst->STORE_MEM }
sub FREE_MEM      :prototype()   ()              { VM::Inst->FREE_MEM }
sub CLEAR_MEM     :prototype()   ()              { VM::Inst->CLEAR_MEM }
sub COPY_MEM      :prototype()   ()              { VM::Inst->COPY_MEM }
sub COPY_MEM_FROM :prototype()   ()              { VM::Inst->COPY_MEM_FROM }

sub LOAD_ARG      :prototype($)  ($idx)          { VM::Inst->LOAD_ARG, $$idx }
sub CALL          :prototype($$) ($label, $argc) { VM::Inst->CALL, VM::Inst->marker(clean_label($label)), $$argc }
sub RETURN        :prototype()   ()              { VM::Inst->RETURN }

sub DUP           :prototype()   ()              { VM::Inst->DUP }
sub POP           :prototype()   ()              { VM::Inst->POP }
sub SWAP          :prototype()   ()              { VM::Inst->SWAP }

sub PRINT         :prototype()   ()              { VM::Inst->PRINT }
sub WARN          :prototype()   ()              { VM::Inst->WARN  }

sub PRINTF        :prototype($$) ($fmt, $argc)   { VM::Inst->PRINTF, $fmt, $$argc }
sub WARNF         :prototype($$) ($fmt, $argc)   { VM::Inst->WARNF,  $fmt, $$argc }

sub HALT          :prototype()   ()              { VM::Inst->HALT }

