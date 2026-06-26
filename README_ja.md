# Name

_chabo-dsl_ -- chabo Domain Specific Language

## Overview

Perlでゼロから実装した AST ベースのインタプリタです。
日本語DSL（Sugar.pm）を実装例として同梱しています。

Tokenizer、Parser、AST Evaluator、スコープ管理、関数システムを備えています。
Tokenizer、Parser、AST Builder、Evaluator、スコープ管理を含む本体は、POD込み約750行。全体像を1ファイルで追える規模に収まっています。

※ "Chabo" はプロジェクト内で親しみを込めて付けた名前であり、日本語DSLそのものを指すものではありません。

## Description

日本語DSLは Sugar.pm として実装されており、エンジン本体は自然言語に依存しません。Sugar.pm を置き換えることで、他言語風のDSLを実装できます。

- Perl製・ゼロから実装
- Tokenizer（字句解析）
- Parser（構文解析）
- AST生成と評価実行
- ユーザー定義関数
- 再帰呼び出し
- スコープ管理
- continue / return などの制御構文
- 配列・ハッシュアクセス
- 日本語DSL対応
- Mojolicious非依存
- POD込み約750行（2026/6時点）

## Demo

Web実行デモ
https://qweer.info/api/Ast/ast

* [1 + 2 * 3](https://qweer.info/api/Ast/ast?calc=1%2b2*3)
* [2 ** 3 ** 2](https://qweer.info/api/Ast/ast?calc=2**3**2)
* [(1+2)(3+4)](https://qweer.info/api/Ast/ast?calc=(1%2b2)(3%2b4))
* 最大公約数を求める
```perl
gcd(a,b) = b?gcd(b,a % b):a;
gcd(72,30);
```
* [フィボナッチ数列を計算](https://qweer.info/api/Ast/ast?calc=%EF%BD%86%EF%BD%82%EF%BC%88%EF%BD%98%EF%BC%8C%EF%BD%99%EF%BC%8C%EF%BD%9A%EF%BC%89%EF%BC%9D%EF%BD%98%EF%BC%9C%EF%BC%91%EF%BC%9F%EF%BD%9A%EF%BC%9A%EF%BD%86%EF%BD%82%EF%BC%88%EF%BD%98%EF%BC%8D%EF%BC%91%EF%BC%8C%EF%BD%99%EF%BC%8B%EF%BD%9A%EF%BC%8C%EF%BD%99%EF%BC%89%EF%BC%9B%EF%BD%8A%EF%BD%8F%EF%BD%89%EF%BD%8E%EF%BC%88%22%EF%BC%8C%22%EF%BC%8C%EF%BD%8D%EF%BD%81%EF%BD%90%EF%BC%88%EF%BD%86%EF%BD%82%EF%BC%88%EF%BC%84%EF%BC%BF%EF%BC%8C%EF%BC%91%EF%BC%8C%EF%BC%90%EF%BC%89%EF%BC%8C%EF%BC%90%EF%BC%8E%EF%BC%8E%EF%BC%93%EF%BC%90%EF%BC%89%EF%BC%89%EF%BC%9B)
```perl
fb(x,y,z) = x < 1?z:fb(x-1,y+z,y);
join(",",map(fb($_,1,0),0..30));
```
* 日本語DSL
```
ans={};
t=[];
【ハッシュを配列に変換】
keyVal(k)=(
 a=length(k) ? shift(k):return();
 push(t,a); push(t,ans{a}); continue();
);
【計算の定義】
・単価と数量で金額を求めるには単価*数量。
・単価と数量と税率で税込金額には単価*数量*(1+税率/100)。

ans{金額}=金額を求める(100,24);
ans{税込み}=税込金額(100,3,8);

青=1;緑=2;赤=3;黄=4;
信号=黄;
ans{交差点}= もし信号が青か緑ならすすめ以外で、もし信号が黄なら注意以外は止まれ。

key:=keys(ans);
keyVal(key);
join(":",t);

---> 交差点:注意:金額:2400:税込み:324
```
## Requirement

## Usage
```perl
  my $ast = Interpreter::Ast->new;
  my $node = $ast->Astnew('formula'=>'1 + 2 * 3');
  my $val  = $node->{answer};
```
## Install
This project currently consists of standalone Perl modules.
Clone the repository and add the `lib` directory to `@INC`.
## Contribution
Bug reports and suggestions are welcome.
## Licence

This software is released under the same terms as Perl itself.
See the LICENSE file for details.

## Author

john smith <john.smith.7701@gmail.com>

http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi

