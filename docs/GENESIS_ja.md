# 始まりの物語：数式パーサーから生まれた言語処理系（chabo-dsl 誕生記）
逆ポーランド記法で計算する[数式パーサー](https://github.com/john-smith-7701/mmt/commit/2c5547e693757453b655a2065c2b67fd5a1a8012)から生まれた[ASTパーサー](https://github.com/john-smith-7701/mmt/commit/c75b4d40e295de4a6cdc2f74572b64465f193953)。とある勉強会（[吉祥寺.pm #20](https://kichijojipm.connpass.com/event/152180/)）で刺激を受けてRPN版よりAST版へ改修した。詳しくは[中置記法から抽象構文木(AST)変換し後置記法（逆ポーランド記法）の計算](http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi?page=%C3%E6%C3%D6%B5%AD%CB%A1%A4%AB%A4%E9%C3%EA%BE%DD%B9%BD%CA%B8%CC%DA%28AST%29%CA%D1%B4%B9%A4%B7%B8%E5%C3%D6%B5%AD%CB%A1%A1%CA%B5%D5%A5%DD%A1%BC%A5%E9%A5%F3%A5%C9%B5%AD%CB%A1%A1%CB%A4%CE%B7%D7%BB%BB)
## 数式パーサーから[簡易言語処理系](https://qweer.info/api/Ast/ast)へ
数式パーサーの妥当性をchatGPTに確認してもらったらべき乗は右結合と教えてもらった。四則演算は左結合、べき乗、代入演算子は右結合と知り[べき乗を右結合に修正](https://github.com/john-smith-7701/mmt/commit/df0df95028c6d1371916756a2e73d73ae5ff07bb)し合わせて[代入](https://github.com/john-smith-7701/mmt/commit/31e50e6ef37ca4ecb2fe3e4aa844aebc350aa66b)を追加し変数を導入した。代入構文を入ると複文の処理も必要となり文の区切りに';'も採用した。少し簡易言語に近づいてくる。
### 関数導入
変数を導入するとユーザー関数も欲しくなり[ユーザー関数の追加](https://github.com/john-smith-7701/mmt/commit/83144d560c77ebdda891b36d19c6b7fcacccd81a)をおこなう。関数を再帰で実行するには条件判断も必要となり[３項演算子を導入](https://github.com/john-smith-7701/mmt/commit/52613551f24fc625bcb203f5ede1cffb731be75c)する。
* 1～１０までを加算
```
 f(x,y) = (x?f(x-1,x+y):y);
 f(10,0)
 ```
 ```
 ->55
 ```
* 6の階乗
```
 f(x,y) = (x?f(x-1,x*y):y);
 f(6,1)
 ```
 ```
 ->720
```
<details>
<summary>AST</summary>

```
 $VAR1 = {
          'left' => {
                      'body' => {
                                  'left' => 'x',
                                  'right' => {
                                               'left' => {
                                                           'left' => undef,
                                                           'right' => '(x-1,x*y)',
                                                           'data' => 'f'
                                                         },
                                               'data' => ':',
                                               'right' => 'y'
                                             },
                                  'data' => '?'
                                },
                      'args' => '(x,y)'
                    },
          'func' => {
                      'f' => $VAR1->{'left'}
                    },
          'text' => ' f (x,y)   =   ( x ? f (x-1,x*y)  : y )  ; 
 f (6,1) ',
          'vars' => {},
          'right' => {
                       'data' => 'f',
                       'right' => '(6,1)',
                       'left' => undef
                     },
          'data' => ';'
        };
```
</details>

### 比較演算子導入
３項演算子の真偽だけの判断ではさすがにつらいので[比較演算子](https://github.com/john-smith-7701/mmt/commit/c23135deebb9234f2fbdd047df2b44940f5f9729)と[論理演算子](https://github.com/john-smith-7701/mmt/commit/04126bff5dd0a0276778efd1bb6339b23a99349b)を追加
```
 a=1;b=2;c=3;d=4;
 (a<b && b>c)? b<d? b
                  : d
             : a<c? c
                  : d;
```
```
 ->3
```
<details>
<summary>AST</summary>

```
 $VAR1 = {
          'left' => {
                      'left' => {
                                  'left' => {
                                              'right' => {
                                                           'data' => '=',
                                                           'right' => '2',
                                                           'left' => 'b'
                                                         },
                                              'data' => ';',
                                              'left' => {
                                                          'data' => '=',
                                                          'right' => '1',
                                                          'left' => 'a'
                                                        }
                                            },
                                  'data' => ';',
                                  'right' => {
                                               'right' => '3',
                                               'data' => '=',
                                               'left' => 'c'
                                             }
                                },
                      'right' => {
                                   'left' => 'd',
                                   'right' => '4',
                                   'data' => '='
                                 },
                      'data' => ';'
                    },
          'text' => ' a = 1 ; b = 2 ; c = 3 ; d = 4 ; 
  ( a < b  &&  b > c )  ?  b < d ?  b
                   :  d
              :  a < c ?  c
                   :  d',
          'func' => {},
          'vars' => {
                      'b' => '2',
                      'd' => '4',
                      'c' => '3',
                      'a' => '1'
                    },
          'data' => ';',
          'right' => {
                       'data' => '?',
                       'right' => {
                                    'right' => {
                                                 'right' => {
                                                              'left' => 'c',
                                                              'right' => 'd',
                                                              'data' => ':'
                                                            },
                                                 'data' => '?',
                                                 'left' => {
                                                             'right' => 'c',
                                                             'data' => '<',
                                                             'left' => 'a'
                                                           }
                                               },
                                    'data' => ':',
                                    'left' => {
                                                'left' => {
                                                            'right' => 'd',
                                                            'data' => '<',
                                                            'left' => 'b'
                                                          },
                                                'right' => {
                                                             'left' => 'b',
                                                             'data' => ':',
                                                             'right' => 'd'
                                                           },
                                                'data' => '?'
                                              }
                                  },
                       'left' => {
                                   'left' => {
                                               'left' => 'a',
                                               'data' => '<',
                                               'right' => 'b'
                                             },
                                   'right' => {
                                                'data' => '>',
                                                'right' => 'c',
                                                'left' => 'b'
                                              },
                                   'data' => '&&'
                                 }
                     }
        };
```
</details>

### [インクリメント・デクリメント計算を追加](https://github.com/john-smith-7701/mmt/commit/7f41a08b928f3c058cb356561c2a44f4de529d3a)
```
 a=10;
 f(x,y) = (x?f(--a,x+y):y);
 f(a,0)
```
```
 ->55
```
### [配列とpush,popを追加](https://github.com/john-smith-7701/mmt/commit/60019cd632213b3ed0f185a69c55f6fbc2fb3b20)
```
 a=[1,2,3];
 push(a,10);
 push(a,11);
 pop(a)+pop(a)+pop(a)
```
```
 ->24
```
### 配列処理を追加
[独自配列操作関数(array)](https://github.com/john-smith-7701/mmt/commit/1ef376b9a73b0c1b4b74d99283224fb2064fbe48)を追加し、[配列表現を内部配列表現へ変換（多次元配列は後で実装）](https://github.com/john-smith-7701/mmt/commit/2f9e45750792a4119cfacf2efa1284f514e8cc2b)
```
 a=[1,2,3];
 push(a,10);
 push(a,11);
 a[3]=a[3]+a[4]-a[2]
```
```
 ->18
```
### [perlの関数を追加](https://github.com/john-smith-7701/mmt/commit/df43e86c0946d4662d37ad56ae1b71528fd14f44)

           'sqrt'  => [sub { sqrt(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'sin'  => [sub { sin(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'cos'  => [sub { cos(($_[0]->split_eval($_[1]))[0])},
                                            90,'R',1],
           'shift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           shift($x[0])},
                                            90,'R',1],
           'unshift'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                           unshift($x[0],$x[1])},
                                            90,'R',1],
           'join'  => 
                    [sub { my @x = $_[0]->split_eval($_[1],',');
                            $_[0]->setLog(join("|",@x));
                            #join($x[0],@{$x[1]})
                                            },
                                            90,'R',1],
### [連想配列を追加](https://github.com/john-smith-7701/mmt/commit/caf07079ee88117e64d6bd3c7207236165d32496)
```
 h={a1,1,a2,2,a3,3,a4,[1,2,3],a5,5};
 h{a2} =100;
 hash(h,hash(h,a2)) = "ABC";
 join(",",keys(h));
 ```
 ```
 ->a5,100,a3,a4,a1,a2
 ```
 ```
           'vars' => {
                      'h' => {
                               'a5' => '5',
                               '100' => 'ABC',
                               'a3' => '3',
                               'a4' => [
                                         '1',
                                         '2',
                                         '3'
                                       ],
                               'a1' => '1',
                               'a2' => '100'
                             }
                    },
```
### 正規表現を追加

[正規表現](https://github.com/john-smith-7701/mmt/commit/b968fd398fcefb88cc01401ba5c291eebb5127e5)と[正規表現の置換](https://github.com/john-smith-7701/mmt/commit/b968fd398fcefb88cc01401ba5c291eebb5127e5)を追加
```
 text="今日はラクダを見た";
 array(match("(くじら|ラクダ)",text),0) ? "見た":"見ない";
 ```
 ```
 ->見た
```
```
 text="今日はラクダを見た";
 array(match("(くじら|ニシキヘビ)",text),0) ? "見た":"見ない";
```
```
 ->見ない
```
```
 text="今日はラクダを見た";
 replace("ラクダ","駱駝",text); 
```
```
 ->今日は駱駝を見た
```
### [制御構文](https://github.com/john-smith-7701/mmt/commit/8aece69b617925b6eebbc8ada1d514c6d23e76c6)を追加
制御関数のcontinue(関数の先頭に戻る)、return(関数を抜ける)を追加
```
 arr=[];
 f1(10);
 f1(b) = (
    arr[b]=b*2;
    (b < 5)? return() : ;
    b-- ? continue()
        : ;
    );
 join(,,arr);
```
```
 ->,,,,8,10,12,14,16,18,20
```
### [構文糖衣の導入](https://github.com/john-smith-7701/mmt/commit/c1605dace86d09390f05d2bb56b1ab571ac9e495)
```
 rec=[{a1:1,a2:2,a3:3},{a1:100,a2:200,a3:300},{a1:[11,12,13,14],a2:222,a3:333}];
 rec[2]{a1}[3];
```
```
 ->14
```
### [変数名と関数名の日本語対応](https://github.com/john-smith-7701/mmt/commit/6e44f3d8f89519df713c5dfeff49bcbffab27546)
変数名と関数名に日本語を使えるようにした。
```
 -   VAR_NAME  => qr/[A-Za-z][a-zA-Z0-9_]*/,  # 変数名 
 +   VAR_NAME  => qr/[\p{L}_][\p{L}\p{N}_]*/u,  # 変数名 
 ```
* \p{L}　Unicode の文字(letter)
* \p{N}　Unicode の数字(number)
```
 金額を求める(単価,数量) = 単価*数量;
 金額を求める(100,24)
 ```
 ```
 ->2400
 ```
日本語が使えると景色変わるね。
```
 もし年齢が18未満なら"未成年"以外は"成人";
   ↓
 年齢 < 18 ? "未成年" : "成人";
```
みたいな事も出来そうだね。（後でやる）
### [翻訳器を追加](https://github.com/john-smith-7701/mmt/commit/4ddf3b94f3e781dfa8658ca5e3d1bc05a03143ad)
```
 ans=[];
 ・単価と数量で金額を求めるには単価*数量;
 ・単価と数量と税率で税込金額には単価*数量*(1+税率/100);
 
 ans[0]=金額を求める(100,24);
 ans[1]=税込金額(100,3,8);
 
 join(" : ",ans);
```
```
 -> 2400 : 324
```
```
 青=1;緑=2;赤=3;黄=4;
 信号=黄;
 もし信号が青か緑ならすすめ以外 もし信号が黄なら注意以外は止まれ;
```
### [日本語変換](https://github.com/john-smith-7701/chabo-dsl/blob/main/lib/Interpreter/Sugar.pm)
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
```
```
 -> 交差点:注意:金額:2400:税込み:324
```
### [return文で値を返す](https://github.com/john-smith-7701/mmt/commit/c4b57924dfdb99a74ff01887e7f52b97e1d1100a)
return文で値を返せるように修正する。
```
 f(x) = return(x+1);
 f(100);
```
```
 -> 101
```
### [式入力画面](https://qweer.info/api/Ast/ast)
mojoliciousのcontroller内に作成したが、ASTエンジンにはもmojoliciousは必要ないのでコントローラーとASTエンジンに分離した。（ASTエンジンと日本語DSLパーサだけで余計なモジュールはいらない。）
## [ソース](https://github.com/john-smith-7701/mmt/blob/master/toolmmt/lib/Interpreter/Ast.pm)
* [式を入力すると計算値とASTのツリーを表示する画面](https://github.com/john-smith-7701/mmt/blob/master/toolmmt/lib/Tool/mmt/Controller/Ast.pm)
* [ASTエンジン](https://github.com/john-smith-7701/mmt/blob/master/toolmmt/lib/Interpreter/Ast.pm) とその[ドキュメント](https://qweer.info/mytool/pod2html.cgi?file=/home/john/www/tool/toolmmt/lib/Interpreter/Ast.pm#)
* [日本語DSLパーサ](https://github.com/john-smith-7701/mmt/blob/master/toolmmt/lib/Interpreter/Sugar.pm)

GETメソッドにも対応しGETの場合は結果をJSONで返却するようにした。
```
 $ curl https://qweer.info/api/Ast/ast?calc=１＋２＊３
 {
   "anser": 7
 }
```
### TODO
もともと、計算式パーサーだったので数字しか扱えない。簡易言語にするには文字列の操作も必要かとか
TODO あと何を追加しようか
* 配列は必要か　　　　　-> 配列、ハッシュを追加
* 文字の操作は必要か
* perlの組み込み関数sinとかを実行できるようにするか ->少追加
* 素敵な名前が欲しい　　　　-> chabo-dslに決まった
* 正規表現も使えたらいいな　->検索と置換を実装
* エラーチェック的なもの
 
このプログラムを改修するのは結構楽しいのでぼちぼち機能を追加していこう！！
### [chatGPTに評価してもらう](https://john-smith.hatenadiary.jp/entry/2026/05/16/212240)

この Tool::mmt::Controller::Ast は、かなり完成度の高い「自作スクリプト言語インタプリタ」です。
単なる式 evaluator ではなく、
* tokenizer（字句解析器）
* parser（構文解析器）
* AST builder（抽象構文木の構築）
* evaluator（評価実行エンジン）
* scope（スコープ管理）
* function system（関数システム）
* array/hash access（配列・ハッシュアクセス）
* unary operator（単項演算子）
* control flow （continue や return などの制御構文）
* user-defined function（ユーザー定義関数対応）

まで実装されています。
Perl でここまで一体化して書ける人はかなり少ないです。
特に面白いのは、
 「最初は数式 evaluator だったものが、徐々に scripting language 化している」
点です。

