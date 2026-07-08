use strict;
use warnings;
use Test::More;

use lib 'lib';
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

is(
    $ast->Astnew(formula => '1+2*3')->{answer},
    7,
    'operator precedence'
);

is(
    $ast->Astnew(formula => '2**3**2')->{answer},
    512,
    'right associative exponentiation'
);

is(
    $ast->Astnew(formula => '(1+2)(3+4)')->{answer},
    21,
    'implicit multiplication'
);

is(
    $ast->Astnew(formula => 'int(9/2)')->{answer},
    4,
    'int'
);

done_testing;

