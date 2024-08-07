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

            CONST_INT
            CONST_FLOAT
            CONST_CHAR
            CONST_STR

            ADD_INT
            SUB_INT
            MUL_INT
            DIV_INT
            MOD_INT

            ADD_FLOAT
            SUB_FLOAT
            MUL_FLOAT
            DIV_FLOAT
            MOD_FLOAT

            CONCAT_STR
            FORMAT_STR

            LT_INT
            GT_INT
            EQ_INT

            LT_FLOAT
            GT_FLOAT
            EQ_FLOAT

            LT_CHAR
            GT_CHAR
            EQ_CHAR

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

            PRINTF
            WARNF

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
