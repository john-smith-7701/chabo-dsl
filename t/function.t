use strict;
use warnings;
use Test::More;

use lib 'lib';
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

is(
    $ast->Astnew(
        formula => 'gcd(a,b)=b?gcd(b,a%b):a; gcd(72,30);'
    )->{answer},
    6,
    'recursive gcd'
);
is(
    $ast->Astnew(
        formula => 'gcd(a,b)=b?gcd(b,a%b):a;lcm(a,b)=a*b/gcd(a,b);lcm(72,30);'
    )->{answer},
    360,
    'recursive lcm'
);

done_testing;

