#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;
use Data::Dumper;

use List::Util   ();
use Scalar::Util ();


class VM::Memory::Error {
    BEGIN {
        my $x = 0;
        map {
            constant->import($_ => Scalar::Util::dualvar(++$x, $_))
        } qw[
            MEM_UNDERFLOW
            MEM_OVERFLOW

            ILLEGAL_INSTRUCTON
        ];
    }
}

## ----------------------------------------------------------------------------

class VM::Memory {
    field $capacity :param :reader;

    field @words;
    field $free;

    ADJUST {
        $words[$capacity - 1] = undef;
        $free                 = 0;
    }

    method alloc ($size, $init=0E0) {
        die VM::Memory::Error->ILLEGAL_INSTRUCTON if $size < 0;
        die VM::Memory::Error->OVERFLOW           if ($free + $size) > $capacity;

        my $addr = $free;
        $words[ $free++ ] = $init foreach 0 .. ($size - 1);

        $self->pointer_to( $addr )
    }

    method pointer_to ($addr) {
        die VM::Memory::Error->OVERFLOW  if $addr > $capacity;
        die VM::Memory::Error->UNDERFLOW if $addr < 0;
        VM::Pointer->new( addr => $addr, mem => $self )
    }

    method at :lvalue ($addr) {
        die VM::Memory::Error->OVERFLOW  if $addr > $capacity;
        die VM::Memory::Error->UNDERFLOW if $addr < 0;
        $words[$addr]
    }

    method dump {
        my $x = 0;
        join "\n" => "FREE  : $free", map { sprintf '%05d : %s', $x++, $_ // '~' } @words;
    }
}

class VM::Pointer {
    use overload '""' => \&to_string;

    field $mem  :param :reader;
    field $addr :param :reader;

    # navigating ...

    method inc          { $addr++;   $self }
    method dec          { $addr--;   $self }
    method move_by ($s) { $addr+=$s; $self }

    # dereferencing ...

    method index :lvalue ($idx) { $mem->at( $addr + $idx ) }
    method deref :lvalue        { $mem->at( $addr )        }

    # copying ...

    method offset ($o) { VM::Pointer->new( addr => ($addr + $o), mem => $mem ) }
    method copy        { VM::Pointer->new( addr => $addr,        mem => $mem ) }

    method to_string { sprintf '*<%04d>' => $addr }
}

## ----------------------------------------------------------------------------

class VM::Program::Region {
    use constant CODE   => Scalar::Util::dualvar(0, 'CODE'  );
    use constant DATA   => Scalar::Util::dualvar(1, 'DATA'  );
    use constant STACK  => Scalar::Util::dualvar(2, 'STACK' );
    use constant HEAP   => Scalar::Util::dualvar(3, 'HEAP'  );

    our @REGIONS = (
        VM::Program::Region->CODE,
        VM::Program::Region->DATA,
        VM::Program::Region->STACK,
        VM::Program::Region->HEAP
    );
}

my $mem = VM::Memory->new( capacity => 45 );

my $root = $mem->alloc(scalar @VM::Program::Region::REGIONS);

foreach my $region (@VM::Program::Region::REGIONS) {
    $root->index($region) = $mem->alloc(10, $region);
}

my $data = $root->index(VM::Program::Region->DATA);
my $heap = $root->index(VM::Program::Region->HEAP);

foreach (0 .. 3) {
    $data->deref = $heap->copy;
    $data->inc;
    $heap->inc;
}

my $code  = $root->index(VM::Program::Region->CODE);
my $stack = $root->index(VM::Program::Region->STACK);

foreach my $i (0 .. 3) {
    $stack->index($i) = $code->offset($i);
}

say $mem->dump;


















