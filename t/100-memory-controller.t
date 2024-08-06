#!perl

use v5.40;
use experimental qw[ class builtin ];

use Test::More;
use Data::Dumper;

use List::Util ();

## ----------------------------------------------------------------------------

class VM::Memory::Array {
    use overload '""' => \&to_string;

    field $head :param :reader;
    field $size :param :reader;

    method region { $head->region  }
    method addr   { $head->addr    }

    method inc         { $head->inc        }
    method dec         { $head->dec        }
    method offset ($o) { $head->offset($o) }

    method to_string { sprintf '*[%d]%.1s<%04d>' => $size, $head->region, $head->addr }
}

class VM::Memory::Pointer {
    use overload '""' => \&to_string;

    field $region :param :reader;
    field $addr   :param :reader;

    # mutators

    method inc {
        return $self->clone( addr => $addr + 1 );
    }

    method dec {
        return $self->clone( addr => $addr - 1 );
    }

    method offset ($o) {
        return $self->clone( addr => $addr + $o );
    }

    # internal ...

    method clone (%changes) {
        return __CLASS__->new(
            region => ($changes{region} // $region),
            addr   => ($changes{addr}   // $addr),
        );
    }

    method to_string { sprintf '*%.1s<%04d>' => $region, $addr }
}

## ----------------------------------------------------------------------------

class VM::Memory::Region {
    use constant ROOT   => Scalar::Util::dualvar(0, 'ROOT'  );
    use constant CODE   => Scalar::Util::dualvar(1, 'CODE'  );
    use constant DATA   => Scalar::Util::dualvar(2, 'DATA'  );
    use constant STACK  => Scalar::Util::dualvar(3, 'STACK' );
    use constant HEAP   => Scalar::Util::dualvar(4, 'HEAP'  );
}

class VM::Memory {
    field $root_size  :reader = 5;
    field $code_size  :param :reader;
    field $data_size  :param :reader;
    field $stack_size :param :reader;
    field $heap_size  :param :reader;

    field $size :reader;
    field @words;

    ADJUST {
        $size = 0;

        $words[ VM::Memory::Region->ROOT ] = VM::Memory::Array->new(
            size => $root_size,
            head => VM::Memory::Pointer->new(
                region => VM::Memory::Region->ROOT,
                addr   => $size,
            )
        );

        $size += $root_size;
        $words[ VM::Memory::Region->CODE ] = VM::Memory::Array->new(
            size => $code_size,
            head => VM::Memory::Pointer->new(
                region => VM::Memory::Region->CODE,
                addr   => $size,
            )
        );

        $size += $code_size;
        $words[ VM::Memory::Region->DATA ] = VM::Memory::Array->new(
            size => $data_size,
            head => VM::Memory::Pointer->new(
                region => VM::Memory::Region->DATA,
                addr   => $size,
            )
        );

        $size += $data_size;
        $words[ VM::Memory::Region->STACK ] = VM::Memory::Array->new(
            size => $stack_size,
            head => VM::Memory::Pointer->new(
                region => VM::Memory::Region->STACK,
                addr   => $size,
            )
        );

        $size += $stack_size;
        $words[ VM::Memory::Region->HEAP ] = VM::Memory::Array->new(
            size => $heap_size,
            head => VM::Memory::Pointer->new(
                region => VM::Memory::Region->HEAP,
                addr   => $size,
            )
        );

        $size += $heap_size;

        $words[$size] = undef;
    }

    method deref ($ptr) { $words[ $ptr->addr ] }

    method peek ($addr)        { $words[$addr]         }
    method poke ($addr, $word) { $words[$addr] = $word }

    method dump { @words }
}

## ----------------------------------------------------------------------------

my $ram = VM::Memory->new(
    code_size  => 10,
    data_size  => 10,
    stack_size => 10,
    heap_size  => 10,
);

my @regions = (
    VM::Memory::Region->CODE,
    VM::Memory::Region->DATA,
    VM::Memory::Region->STACK,
    VM::Memory::Region->HEAP
);

my $root = $ram->peek( VM::Memory::Region->ROOT );

foreach my $region (@regions) {
    my $r = $ram->deref( $root->offset( $region ) );

    for (my ($p, $i) = ($r, 0); $i < $r->size; ($p, $i) = ($p->inc, $i + 1) ) {
        $ram->poke( $p->addr, sprintf "%s:%d" => $p->region, $i );
    }
}

my $data = $ram->deref( $root->offset( VM::Memory::Region->DATA ));
my $heap = $ram->deref( $root->offset( VM::Memory::Region->HEAP ));

warn $data;
warn $heap;

my ($from, $to) = ($data->head, $heap->head);
foreach my $i ( 0 .. 5 ) {
    $ram->poke( $to->addr, $from );
    ($from, $to) = ($from->inc, $to->inc);
}


my $x = 0;
say join "\n" => map {
    sprintf '%05d : %s', $x++, $_ // '~'
} $ram->dump;

















