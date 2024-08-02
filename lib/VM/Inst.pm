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

            CONST_TRUE
            CONST_FALSE

            CONST_INT
            CONST_FLOAT
            CONST_STR

            ADD_INT  ADD_FLOAT
            SUB_INT  SUB_FLOAT
            MUL_INT  MUL_FLOAT
            DIV_INT  DIV_FLOAT
            MOD_INT  MOD_FLOAT

            CONCAT_STR

            LT_INT   LT_FLOAT   LT_STR
            GT_INT   GT_FLOAT   GT_STR
            EQ_INT   EQ_FLOAT   EQ_STR

            JUMP
            JUMP_IF_TRUE
            JUMP_IF_FALSE

            LOAD
            STORE

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
