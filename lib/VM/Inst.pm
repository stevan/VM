#!perl

use v5.40;
use experimental qw[ class ];

use Scalar::Util;

package VM::Inst {

    our @OPCODES;
    our %OPCODES;
    BEGIN {
        @OPCODES = qw(
            NOOP

            CONST_NIL

            CONST_TRUE
            CONST_FALSE

            CONST_NUM
            CONST_STR

            CREATE_ARRAY
            ARRAY_INDEX

            ADD_NUM
            SUB_NUM
            MUL_NUM
            DIV_NUM
            MOD_NUM

            CONCAT_STR

            LT_NUM LT_STR
            GT_NUM GT_STR
            EQ_NUM EQ_STR

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            LOAD
            STORE

            ALLOC_LOCAL
            LOAD_LOCAL
            STORE_LOCAL
            FREE_LOCAL

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
            my $opcode = $OPCODES[$i];
            $OPCODES[$i] = Scalar::Util::dualvar( $i, $opcode );
            $OPCODES{$opcode} = $OPCODES[$i];
            *{__PACKAGE__."::${opcode}"} = sub { $OPCODES[$i] };
        }
    }

    sub is_opcode ($opcode) { exists $OPCODES{$opcode} }

    class VM::Inst::Label  { field $name :param :reader }
    class VM::Inst::Marker { field $name :param :reader }

    sub label  ($, $name) { VM::Inst::Label ->new( name => $name ) }
    sub marker ($, $name) { VM::Inst::Marker->new( name => $name ) }

}
