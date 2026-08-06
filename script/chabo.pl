#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open qw(:std :encoding(UTF-8));

use lib 'lib';
use Interpreter::Ast;
my $ast = Interpreter::Ast->new;

my $src = do { local $/;join '',<>};

$ast->ast( $src );
print $ast->run(),"\n";

