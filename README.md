# Name

_chabo-dsl_ -- chabo Domain Specific Language

## Overview
A tiny AST-based DSL engine written in Perl, featuring Japanese DSL support.

Features:

- Tokenizer
- Parser
- AST Evaluator
- Scope Management
- User-defined functions
- Japanese DSL support via Sugar.pm

### Demo

https://qweer.info/api/Ast/ast

* [1 + 2 * 3](https://qweer.info/api/Ast/ast?calc=1%2b2*3)
* [2 ** 3 ** 2](https://qweer.info/api/Ast/ast?calc=2**3**2)
* [(1+2)(3+4)](https://qweer.info/api/Ast/ast?calc=(1%2b2)(3%2b4))
* Greatest common divisor (GCD)
```perl
gcd(a,b) = b?gcd(b,a % b):a;
gcd(72,30);
```
* [Fibonacci sequence](https://qweer.info/api/Ast/ast?calc=%EF%BD%86%EF%BD%82%EF%BC%88%EF%BD%98%EF%BC%8C%EF%BD%99%EF%BC%8C%EF%BD%9A%EF%BC%89%EF%BC%9D%EF%BD%98%EF%BC%9C%EF%BC%91%EF%BC%9F%EF%BD%9A%EF%BC%9A%EF%BD%86%EF%BD%82%EF%BC%88%EF%BD%98%EF%BC%8D%EF%BC%91%EF%BC%8C%EF%BD%99%EF%BC%8B%EF%BD%9A%EF%BC%8C%EF%BD%99%EF%BC%89%EF%BC%9B%EF%BD%8A%EF%BD%8F%EF%BD%89%EF%BD%8E%EF%BC%88%22%EF%BC%8C%22%EF%BC%8C%EF%BD%8D%EF%BD%81%EF%BD%90%EF%BC%88%EF%BD%86%EF%BD%82%EF%BC%88%EF%BC%84%EF%BC%BF%EF%BC%8C%EF%BC%91%EF%BC%8C%EF%BC%90%EF%BC%89%EF%BC%8C%EF%BC%90%EF%BC%8E%EF%BC%8E%EF%BC%93%EF%BC%90%EF%BC%89%EF%BC%89%EF%BC%9B)
```perl
fb(x,y,z) = x < 1?z:fb(x-1,y+z,y);
join(",",map(fb($_,1,0),0..30));
```


See README_ja.md for details.

