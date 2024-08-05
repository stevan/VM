#!perl

use v5.40;
use experimental qw[ class ];

use VM::Inst;
use VM::Pointer;

class VM::Assembler {

    method assemble ($source) {
        my %labels;
        my @code;
        my @strings;

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
            my $prev_opcode;
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
                        # note the previous opcode so that
                        # we can handle the string table
                        $prev_opcode = $line;
                    }
                } else {
                    # collect the string table ...
                    if ($prev_opcode && $prev_opcode isa VM::Inst::Op::CONST_STR) {
                        # add to the string table
                        push @strings => $line;
                        # and replace it with a ref to the index
                        $line = VM::Pointer::String->new(
                             address => $#strings,
                             size    => length($line)
                        );
                    }

                    $i++;
                    push @code => $line;
                }
            }
        }

        return \@code, \%labels, \@strings;
    }
}
