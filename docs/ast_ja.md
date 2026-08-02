# 概要
このモジュール lib/Interpreter/Ast.pm は、文字列で与えられた数式・式・簡易スクリプトを パース → 抽象構文木 (AST) の生成 → 評価 までをひとつのクラスで完結させた「式評価エンジン」です。

四則演算、比較、論理、三項演算子、代入、配列/ハッシュアクセス、ユーザ定義関数、組み込み的な Perl 関数（sqrt, sin, substr など）をサポート
変数はローカル (vars) とグローバル (global) に分かれ、:= でグローバル代入、= でローカル代入が行われる
タイムアウト機構（alarm(5)）と再帰深さ制限（$s->{count} > 1000）でスタックオーバーフローや無限ループを防止
デバッグ用に Data::Printer (np) で木構造をテンプレートに出力、setLog が実行ログを蓄積
以下では、ファイル全体 をセクションごとに分解し、重要なロジックと実装上のポイント・注意点を解説します。

# 1. モジュール宣言・依存
```perl
 
package Interpreter::Ast;
use Interpreter::Sugar;   # 入力式の前処理（マクロ変換等）
use strict;
use warnings;
use Carp;
use Scalar::Util qw(looks_like_number);
```
Sugar は入力文字列の「甘い」書き方を正規化するヘルパー（convert が呼ばれるだけなので実装は別ファイル）。
# 2. 定数・演算子テーブル
```perl
 
use constant {
    LEFT    => 'L',         # 結合性（左結合）
    RIGHT   => 'R',         # 右結合
    OPERATOR => 0,
    FUNCTION => 0,
    PRIORITY => 1,
    ASSOCIATIVE => 2,
    OPTION  => 3,
    UNARY   => 1,
    ASSIN   => 2,
    VAR_NAME => qr/[\p{L}_][\p{L}\p{N}_]*/u,
};
```
ここで OPERATOR〜OPTION は演算子テーブル $op の配列インデックスを名前付き定数で表すためのマジックです。
VAR_NAME は Unicode 文字を含めた変数名の正規表現です。
演算子テーブル $op
```perl
 
my $op = +{
    ';'   => [sub { $_[2]},          10,'L',0],
    '||'  => [sub {$_[1] || $_[2]},  20,'L',0],
    '&&'  => [sub {$_[1] && $_[2]},  30,'L',0],
    '?'   => [sub { },               55,'R',0],
    ':'   => [sub { },               55,'R',0],
    '='   => [sub {$_[0]->setValue('',$_[1],$_[2])}, 50,'R',2],
    ':='  => [sub {$_[0]->setValue('global',$_[1],$_[2])}, 50,'R',2],
    # 比較演算子は数値と文字列を自動判別 (cmp_auto)
    '<='  => [sub {cmp_auto($_[1], $_[2],sub {$_[1] <= $_[2]},sub{$_[0] le $_[1]})}, 60,'L',0],
    # ... (他演算子省略)
    '-'   => [sub {$_[1] - $_[2]},   70,'L',0],
    '+'   => [sub {$_[1] + $_[2]},   70,'L',0],
    '*'   => [sub {$_[1] * $_[2]},   80,'L',0],
    '/'   => [sub {$_[2]? $_[1] / $_[2] : $_[0]->_error("Zero divied!!")}, 80,'L',0],
    '%'   => [sub {$_[2]? $_[1] % $_[2] : $_[0]->_error("Zero divied!!")}, 80,'L',0],
    'NGE' => [sub { -$_[1]},         90,'R',1],      # 単項マイナス
    '!'   => [sub { $_[1] ? 0 : 1},  90,'R',1],
    # Perl 関数（sqrt, sin …）は全て単項で右結合、優先度 90
    'sqrt'=> [sub { sqrt(($_[0]->split_eval($_[1]))[0])}, 90,'R',1],
    # ... (array, hash, ++/--, logical continue/return など)
    '('   => [sub { }, -1,'L',0],
    ')'   => [sub { }, -1,'L',0],
    # 文字列結合演算子 (x)
    "x"   => [sub {$_[1] x $_[2]},   80,'L',0],
};
```
ポイント

|項目	|意味|
|:--|:--|
|関数 ([sub {...}])	|実行時に呼び出されるコードブロック。第一引数は常にオブジェクト $self ($_[0])|
|優先度 (PRIORITY)	|小さいほど低い優先度。makeTree が「最も低い優先度の演算子」を根に選択|
|結合性 (ASSOCIATIVE)	|LEFT/RIGHT。三項演算子や右結合代入 (=) では右結合が必要|
|オプション (OPTION)_	|UNARY (1) → 単項演算子, ASSIN (2) → 代入演算子, それ以外は二項演算子|

**注意**

? : は実装上は「根が ?、右側に : を持つ二分木」になるように makeTree が特別処理しています。
= と := は setValue に委譲して変数代入を行います。
文字列リテラルは adjust で __STR__|N|__ というプレースホルダに置き換え、後で復元します。__
# 3. 補助関数
cmp_auto
```perl
 
sub cmp_auto{
    my($l,$r,$num_op,$str_op) = @_;
    if (looks_like_number($l) && looks_like_number($r)) {
        return $num_op->($l, $r);
    } else {
        return $str_op->($l, $r);
    }
}
```
数値か文字列かを自動判定し、比較演算子の意味を切り替えるユーティリティ。
<=, >=, >, <, ==, != の実装で使用。
## inc_dec
インクリメント/デクリメント（++ / --）の内部表現を処理。

```perl
 
sub inc_dec{
    my $s = shift;                # $self
    my ($val,$inc,$pre) = @_;     # 変数名、"+"|"-"、"pre"|"post"
    $val =~ s/^\((.*)\)$/$1/;     # 余計なカッコ除去
    my $var = exists $s->{global}{$val} ? 'global' : 'vars';
    my $ret = $s->{$var}{$val};   # 前置/後置用に元の値を保持
    ($inc eq '+') ? ++$s->{$var}{$val} : --$s->{$var}{$val};
    $ret = $s->{$var}{$val} if $pre eq 'pre';
    return $ret;
}
```
変数がグローバルかローカルかを自動判定し、前置 (++_pre) と 後置 (++_post) の挙動を分けている。
# 4. 主要メソッド（外部 API）

 
## メソッド	目的
ast	$self->param('calc') で渡された式を評価し、結果を stash(anser => ...) に保存
|項目	|意味|
|:--|:--|
|_ast	|実際の評価ロジック。式文字列 → adjust → item_split → makeTree → readTree|
|Astnew	|コンストラクタ風のエントリポイント。setReOps（演算子正規表現作成）→_ast を呼び出す|
|setReOps	|$op キーから正規表現 `($op1|
|newNode	|AST のノードを生成。= の左辺がハッシュでなく HASH 参照であれば関数定義 (makeFunc) を行う|
|makeFunc	|ユーザ定義関数を func ハッシュに保存|
|readTree	|AST 評価エンジン。再帰的にノードを走査し、演算子テーブルやユーザ関数を呼び出す|
|callFunc	|定義済み関数呼び出し。ローカル変数スコープをコピーして再帰呼び出し可能に|
|makeTree	|パーサ。トークン列から優先度・結合性に基づき二分木を構築|
|strip_outer	|余計な外側の丸括弧を除去（( a + b ) → a + b）|
|judge_priority	|結合性に応じた優先度比較ロジック|
|item_split	|文字列 → トークン配列（空白で分割）|
|adjust / adjust2	|入力文字列の正規化・空白挿入・リテラル保護・インクリメント/デクリメント変換などの前処理|
|setValue	|変数に値を代入（ローカル/グローバル/配列・ハッシュ要素への代入）|
|normalize_value	|文字列リテラル → 配列・ハッシュ構造へ変換|
|split_eval	|カンマ区切り引数の分解とそれぞれの評価（関数呼び出し時に利用）|
|getValue	|変数参照と文字列リテラル復元|
|_error	|エラーメッセージを croak で例外として投げる|
# 5. パーサ（makeTree）の流れ
トークン列の整形
strip_outer で不要な外側括弧を削除。
最も優先度が低い演算子（＝根）を探索
ループで $s->{ops} にマッチするトークンを走査し、現在の深さ ($depth) が 0 のときだけ評価対象にする。
 -が単項マイナスかどうかは位置情報で判定し、NGE に置き換える。
三項演算子の ? : は ? が根になるように twin で対応する : のインデックスを取得。
右側トークン列の分割
? の場合は ? と : の間をカッコで囲んで右側を @right に渡す（三項演算子の「真」側をサブツリー化）。
再帰的に子ノードを生成
makeTree を左側 (0 .. $m-1) と右側 (@right) に対して再帰呼び出し。
newNode に渡して「根」ノード（data, left, right のハッシュ）を作る。
実装上のポイント

priority が低いほど「外側に置く」＝演算子が根になる。
結合性が右結合の場合は「同優先度」でも右側が根になるように比較 (judge_priority)。
strip_outer は多重括弧 ((a+b)) を正しく除去し、内部の構造が崩れたときは例外を croak。
# 6. 評価エンジン（readTree）の流れ
```perl
 
sub readTree {
    my ($s,$node) = @_;
    # 1. ノードがスカラ/リテラルならそのまま返す
    return $s->getValue('c',$node) if (ref($node) ne 'HASH');

    # 2. 単項演算子か？
    if ( exists $op->{$node->{data}} && $op->{$node->{data}}->[OPTION] == UNARY ) {
        return $op->{$node->{data}}->[FUNCTION]($s,
                $s->readTree($node->{'right'}));
    }

    # 3. ユーザ定義関数か？
    if ( exists $s->{func}->{$node->{data}} ) {
        return $s->callFunc($node);
    }

    # 4. 三項演算子
    if ( $node->{data} eq '?' ) {
        return $s->readTree($node->{left})
            ? $s->readTree($node->{right}->{left})
            : $s->readTree($node->{right}->{right});
    }

    # 5. 二項演算子の左右を評価（&& のショートサーキットはここで実装）
    my $newnode = {};
    do {
        $newnode->{$_} = ($_ eq 'right' && $node->{data} eq '&&' && !$newnode->{'left'})
                ? 0                                     # && の左が false の時は右側は評価しない
                : ref($node->{$_}) eq 'HASH' ? $s->readTree($node->{$_}) : $node->{$_};
    } for ('left','right');

    # 6. 代入か演算かで分岐
    return exists $op->{$node->{data}}
         ? $op->{$node->{data}}->[OPTION] == ASSIN
            ? $op->{$node->{data}}->[FUNCTION]($s,
                $s->getContainer($node->{left}),
                $s->getValue($node->{data}, $newnode->{right}))
            : $op->{$node->{data}}->[FUNCTION]($s,
                $s->getValue($node->{data}, $newnode->{left}),
                $s->getValue($node->{data}, $newnode->{right}))
         : $s->getValue('c',$node->{data});
}
```
キーとなるポイント

 
|#	|処理	|説明|
|--:|:--|:--|
|1	|リテラル	|ハッシュでない場合は変数参照・文字列リテラルとして取得 (getValue)|
|2	|単項演算子	|op->[OPTION] == UNARY → 右側だけ評価し、関数へ ($_[0] が $self)|
|3	|ユーザ関数	|callFunc がローカルスコープをコピーし、再帰的に実体 (body) を評価|
|4	|三項演算子	|? が根のノードで、左側が真か偽かで右側サブツリーを分岐|
|5	|ショートサーキット	|&& は左が偽なら右側は評価しない（$newnode->{'left'} が false のとき 0 を返す）|
|6	|代入 vs 演算	|OPTION == ASSIN → setValue に委譲して代入。そうでなければ通常の二項演算子 (+, *, == …) を実行|
# 7. 変数・スコープ管理|
スコープ構造
```perl
 
$self->{vars}   # ローカル（デフォルト）
$self->{global} # グローバル（:= で代入されたもの）
```
代入は setValue が担う。

第1引数 scope が空文字列の場合は「グローバルに同名変数があれば global、無ければ vars」へ代入。
第2引数 out は変数名、配列要素、ハッシュ要素を受け取る形 ('a'、['a',1]、['hash', 'key'])。
第3引数は代入したい式の文字列。normalize_value が配列・ハッシュリテラルかどうか判定し、必要に応じて topSplit で分解。
配列・ハッシュアクセスは array / hash キーが演算子テーブルに登録され、split_eval で引数を評価し、$s->{vars}/$s->{global} のデータ構造へアクセス。

# 8. 補助的な文字列・リテラル処理
adjust → adjust2
文字列リテラル保護
"..." や '...' を  __STR__|N|__ というトークンに置換し、途中で誤って分割されないようにする。
インクリメント・デクリメント変換
++a → ++_pre(a)、a++ → ++_post(a) の形に変換し、newNode で関数名として認識させる。
配列/ハッシュアクセスの内部表現化
a[1] → array(a,1)、h{key} → hash(h,key) に変換。
演算子間にスペース挿入
正規表現 $s->{ops} を使って + - * / などの前後に空白を入れ、item_split が単純に空白でトークン化できるようにする。
暗黙の乗算補完
)( の間に * を自動挿入（例：(1+2)(3+4) → (1+2)*(3+4))*
split_eval
カンマ区切り引数を 括弧の深さ を考慮しつつ分割し、各要素を 再帰的に makeTree → readTree で評価。
返り値は評価済みスカラ／リファレンスのリスト。
# 9. エラーハンドリング・安全策

 
|仕組み	|説明|
|:--|:--|
|_error	|croak で例外を投げ、$self->{ret} にエラーメッセージも格納|
|alarm(5) + $SIG{ALRM}	|評価が 5 秒を超えたら AST::Timeout 例外をスロー|
|再帰カウンタ $self->{count}	|関数呼び出しが 1000 回を超えると return $self->{ret}（スタックオーバーフロー防止）|
|深さチェック (strip_outer, makeTree)	|括弧のバランスが崩れたら _error|
# 10. デバッグ・可視化
```perl
 
$s->stash(tree => np( $s->{root}, colored => 0 ));
```
np（Data::Printer）で AST の構造体（ハッシュ）を人が読める形に変換し、Mojolicious の stash に入れてビューへ渡す想定です。
setLog が $self->{global}->{LOG} に文字列を積み上げ、$self->{logText} にも同様に保持（adjust 時にも呼ばれる）。
# 11. 使い方例
```perl
 
use Interpreter::Ast;

my $ast = Interpreter::Ast->new;

# 1) 単純な四則演算
my $node = $ast->Astnew( formula => '1 + 2 * 3' );
say $node->{anser};          # → 7

# 2) 変数代入と使用
$ast->Astnew( formula => 'x = 10; y = x + 5' );
say $ast->{vars}{x};        # → 10
say $ast->{vars}{y};        # → 15

# 3) 三項演算子 + 関数呼び出し
$ast->Astnew( formula => 'a = 5; b = 10; a > b ? "big" : "small"' );
say $ast->{anser};          # → "small"

# 4) ユーザ定義関数
$ast->Astnew( formula => 'f(a,b) = a*b; f(3,4)' );
say $ast->{anser};          # → 12
```
例では Astnew が内部で adjust → makeTree → readTree の流れを走ります。
setValue でローカル変数が更新され、$ast->{vars} に結果が残ります。

