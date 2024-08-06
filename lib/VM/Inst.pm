#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util;

use VM::Inst::Op;

class VM::Inst::Label  { field $name :param :reader }
class VM::Inst::Marker { field $name :param :reader }

package VM::Inst {

    our @OPCODES;
    BEGIN {
        @OPCODES = qw(
            NOOP

            CONST_NIL

            CONST_TRUE
            CONST_FALSE

            CONST_NUM
            CONST_STR

            ADD_NUM
            SUB_NUM
            MUL_NUM
            DIV_NUM
            MOD_NUM

            CONCAT_STR
            FORMAT_STR

            LT_NUM LT_STR
            GT_NUM GT_STR
            EQ_NUM EQ_STR

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            LOAD
            STORE

            ALLOC_MEM
            LOAD_MEM
            STORE_MEM
            FREE_MEM
            CLEAR_MEM
            COPY_MEM
            COPY_MEM_FROM

            LOAD_ARG
            CALL
            RETURN

            DUP
            POP
            SWAP

            PRINT
            WARN

            HALT
        );


        foreach my $i (0 .. $#OPCODES) {
            no strict 'refs';
            my $opcode   = $OPCODES[$i];
            $OPCODES[$i] = ('VM::Inst::Op::'.$opcode)->new;
            *{__PACKAGE__."::${opcode}"} = sub { $OPCODES[$i] };
        }
    }

    sub label  ($, $name) { VM::Inst::Label ->new( name => $name ) }
    sub marker ($, $name) { VM::Inst::Marker->new( name => $name ) }

}
