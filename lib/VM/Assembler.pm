#!perl

use v5.40;
use experimental qw[ class ];

use VM::Inst;

class VM::Assembler {

    method assemble ($source) {
        my %labels;
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

        my @code;
        {
            my $i = 0;
            foreach my $line (@$source) {
                if (blessed $line) {
                    if ( $line isa VM::Inst::Marker ) {
                        $labels{$line->name}
                            // die "Could not find label for marker(".$line->name.")";
                        $i++;
                        push @code => Scalar::Util::dualvar(
                            $labels{$line->name},
                            $line->name
                        );
                    }
                } else {
                    $i++;
                    push @code => $line;
                }
            }
        }

        return \%labels, \@code;
    }
}
