#!perl

use v5.40;
use experimental qw[ class ];

use Test::More;

use VM::Inst;

my $op1 = VM::Inst->CALL;
my $op2 = VM::Inst->CALL;

is(refaddr $op1, refaddr $op2, '... got the same thing');

done_testing;
