#!perl

use v5.40;
use experimental qw[ class builtin ];

use builtin qw[ is_bool created_as_string created_as_number ];

use VM::Inst;
use VM::Inst::Op;
use VM::Inst::Literal;
use VM::Pointer;

class VM::Assembler {

    method assemble ($source) {
        my %labels;
        my @code;
        my @statics;

        {
            my $i = 0;
            foreach my $line (@$source) {
                if (blessed $line && $line isa VM::Inst::Label) {
                    $labels{$line->name} = $i;
                } else {
                    $i++;
                }
            }
        }


        {
            my $i = 0;
            my $prev_inst;
            foreach my $line (@$source) {
                if (blessed $line) {
                    # replace markers with dualvar (to make display easier)
                    # TODO: replace this dualvar silliness and make it part
                    # of the Marker class
                    if ( $line isa VM::Inst::Marker ) {
                        $labels{$line->name}
                            // die "Could not find label for marker(".$line->name.")";
                        $i++;
                        push @code => Scalar::Util::dualvar(
                            $labels{$line->name},
                            $line->name
                        );
                    # handle any ops here ...
                    } elsif ($line isa VM::Inst::Op) {
                        $i++;
                        push @code => $line;

                        $prev_inst = $line;
                    }
                } else {
                    # collect the string table ...
                    if (created_as_string($line) && length($line) != 1) {
                        # and replace it with a ref to the index
                        my $ptr = VM::Pointer::Static->new(
                            address => scalar(@statics),
                            size    => length($line),
                        );

                        #warn "(${line})";

                        # add to the string table
                        push @statics => map { VM::Inst::Literal::CHAR->new( value => $_ ) } split '', $line;

                        $line = $ptr;
                    # convert all the values
                    } else {
                        if ($prev_inst && $prev_inst isa VM::Inst::Op::CONST_INT) {
                            $line = VM::Inst::Literal::INT->new( value => $line );
                        } elsif ($prev_inst && $prev_inst isa VM::Inst::Op::CONST_FLOAT) {
                            $line = VM::Inst::Literal::FLOAT->new( value => $line );
                        } elsif ($prev_inst && $prev_inst isa VM::Inst::Op::CONST_CHAR) {
                            $line = VM::Inst::Literal::CHAR->new( value => $line );
                        }

                        $prev_inst = undef;
                    }

                    $i++;
                    push @code => $line;
                }
            }
        }

        return \@code, \%labels, \@statics;
    }
}
