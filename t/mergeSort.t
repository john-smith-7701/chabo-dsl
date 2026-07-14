use strict;
use warnings;
use Test::More;

use lib 'lib';
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

is(
    $ast->Astnew(
        formula => <<'End'
merge(l1,l2,out) = (
(length(l1) == 0 || length(l2) == 0) ? (push(out,l1);push(out,l2);return(out);) : ;
       (l2[0] < l1[0]) ? push(out,shift(l2))
                       : push(out,shift(l1)) ;
continue();
);
mergeSort(list) = (
       (length(list) <= 1) ? return(list) 
                           : merge(mergeSort(list[0..int(length(list)/2)-1])
                                  ,mergeSort(list[int(length(list)/2) .. length(list)-1])
                                  ,[]
                             )
);
list2=map($_*2-1,0..25);
push(list2,map($_*2,0..25));	
join(",",mergeSort(list2))
End
    )->{answer},
    '-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50',
    'mergeSort'
);

done_testing;

