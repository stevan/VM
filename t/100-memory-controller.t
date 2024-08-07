#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;
use Data::Dumper;

use List::Util ();

## ----------------------------------------------------------------------------

class VM::Pointer {
    use overload '""' => \&to_string;

    field $memory :param :reader;
    field $addr   :param :reader;

    method inc { __CLASS__->new( addr => $addr + 1, memory => $memory ) }
    method dec { __CLASS__->new( addr => $addr - 1, memory => $memory ) }

    method offset ($offset) { __CLASS__->new( addr => $addr + $offset, memory => $memory ) }

    method read         { $memory->at( $addr ) }
    method write ($val) { $memory->at( $addr ) = $val }

    method to_string { sprintf '*<%04d>' => $addr }
}

class VM::Memory {
    field @words;

    method alloc ($size, $init=0E0) {
        my $addr = scalar @words;
        $words[ $addr + $_ ] = $init foreach 0 .. ($size - 1);
        return VM::Pointer->new( addr => $addr, memory => $self );
    }

    method at :lvalue ($addr) { $words[$addr] }

    method dump { @words }
}

## ----------------------------------------------------------------------------

class VM::Program::Region {
    use constant CODE   => Scalar::Util::dualvar(0, 'CODE'  );
    use constant DATA   => Scalar::Util::dualvar(1, 'DATA'  );
    use constant STACK  => Scalar::Util::dualvar(2, 'STACK' );
    use constant HEAP   => Scalar::Util::dualvar(3, 'HEAP'  );
}

my @regions = (
    VM::Program::Region->CODE,
    VM::Program::Region->DATA,
    VM::Program::Region->STACK,
    VM::Program::Region->HEAP
);

my $mem = VM::Memory->new;

my $root = $mem->alloc(scalar @regions);

foreach my $region (@regions) {
    $root->offset($region)->write( $mem->alloc(10, $region) );
}

my $data = $root->offset(VM::Program::Region->DATA)->read;
my $heap = $root->offset(VM::Program::Region->HEAP)->read;

foreach (0 .. 3) {
    $data->write( $heap );
    $data = $data->inc;
    $heap = $heap->inc;
}

my $x = 0;
say join "\n" => map {
    sprintf '%05d : %s', $x++, $_ // '~'
} $mem->dump;

















