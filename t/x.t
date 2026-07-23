use strict;
use warnings;
use Test::More;

use lib 'lib';
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

is(
    $ast->Astnew(formula => '1')->{answer},
    1,
    'operator precedence'
);

done_testing;

