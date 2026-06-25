use strict;
use warnings;
use Test::More;

use lib 'lib';
use utf8;
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

is(
    $ast->Astnew(
        formula => q{
            青=1;緑=2;赤=3;黄=4;
            信号=黄;
            もし信号が青か緑ならすすめ以外で、
            もし信号が黄なら注意以外は止まれ。
        }
    )->{answer},
    '注意',
    'Japanese DSL'
);

done_testing;

