# Perl and the Dangerous Temptation of Regular Expressions
## 1. chabo-dsl Is Not Just a Small Language
It Is Also a Playground for Regular Expressions

[chabo-dsl](https://github.com/john-smith-7701/chabo-dsl/tree/main) is an AST-based DSL engine implemented entirely in Perl from scratch.

It includes a tokenizer, a parser, AST construction, an evaluator, scope management, user-defined functions, and even recursion. Yet the whole thing fits into roughly 750 lines of code, even counting the POD documentation.

The Japanese DSL layer is implemented separately through Sugar.pm, which means that by replacing that module, one can create DSLs that look like entirely different languages.

That small size is important.

Once you step into the world of parser generators, things tend to grow rapidly:

```
 Grammar
 ↓
 Lexer
 ↓
 Parser
 ↓
 AST
 ↓
 Evaluator
```
Before long, you have a respectable piece of language engineering.

And there is absolutely nothing wrong with that.

In chabo-dsl, however, things are a little less formal.

More like this:

```
Text
↓
Regular Expression
↓
A Few More Regular Expressions
↓
AST
↓
Evaluation
```

That "a few more" happens to be Perl.

And that makes all the difference.

The goal was never to compete with industrial-strength language tooling.

The goal was simply to see how far one could go with a handful of regular expressions, some recursive tree construction, and a healthy amount of Perl stubbornness.

As it turns out, surprisingly far.

In that sense, chabo-dsl is not merely a DSL engine.

It is also a small experimental field where regular expressions are allowed to wander around unsupervised and occasionally pretend to be parts of a compiler.

Sometimes they even succeed.

## 2. Everything Starts with a Regular Expression
Even Variable Names

Somewhere inside Ast.pm, there is a definition that looks roughly like this:

```perl
VAR_NAME => qr/
[\p{L}_]
[\p{L}\p{N}_]*
/u,
```
And that's pretty much it.

Just one line.

Yet an unreasonable amount of chabo-dsl's philosophy is hiding inside that single regular expression.

The rule is simple:

```
[\p{L}_]
```

A variable name must begin with either a letter or an underscore.

Then:

```
[\p{L}\p{N}_]*
```

Any number of letters, digits, or underscores may follow.

Nothing particularly clever.

Nothing particularly complicated.

Just Unicode-aware character classes quietly doing their job.

And because they are Unicode-aware, Japanese identifiers require no special treatment whatsoever.

Variables such as:

```
金額
税込み
交差点
信号
```

are not exceptions.

As far as the regular expression is concerned, they are simply variable names.

That is an important distinction.

Many language implementations would approach the problem from the opposite direction.

They might say:

"Since this is a Japanese DSL, we need to teach the parser what Japanese identifiers look like."

chabo-dsl takes a much lazier approach.

Or perhaps a much more practical one.

Instead, it tells the regular expression engine:

"Letters are Unicode, right?"

And then walks away.

Problem solved.

No special grammar rules.

No separate Japanese mode.

No giant table of character ranges.

Just Unicode.

And a regular expression.

There is something delightfully Perl-ish about that.

Perl has always had a tendency to look at a complicated problem and ask:

"Are we absolutely certain this needs to be complicated?"

Sometimes the answer is yes.

Sometimes it is no.

And sometimes a single qr// quietly eliminates an entire category of future work.

This is one of those times.

Of course, none of this makes the parser magically simpler.

Eventually an AST still has to be built.

Expressions still need to be evaluated.

Operators still require precedence rules.

Reality catches up sooner or later.

But it is pleasant when a whole class of problems can be dismissed with a single line of code.

That is one of the small joys of working in Perl.

You spend half an hour expecting a difficult engineering task.

Then Unicode-aware regular expressions wander into the room and casually solve it before lunch.

And somehow, that still feels a little magical.
## 3. Even the Operators Become Regular Expressions

Things get more interesting when we reach setReOps().

Somewhere inside the code, there is a piece that looks roughly like this:

```Perl
$s->{ops} = join(
'|',
map {
s/(\W)/\\$1/g;
$_;
}
sort { length $b <=> length $a }
(keys %$op, @_)
);
$s->{ops} = '(' . $s->{ops} . ')';
```

The first time you see it, you may think:

Ah, this is where the parser learns about operators.

Not quite.

What's actually happening is slightly more mischievous.

The parser is not being taught individual operators one by one.

Nobody is manually writing rules for:

```
+
-
*
/
%
==
!=
<=
>=
&&
||
```

Instead, the operator table itself is used to generate the regular expression that recognizes operators.

The list of operators exists.

The regular expression is built from that list.

Which means that if the operator table grows, the regular expression grows with it.

No additional parser rules required.

What laziness.

Or, depending on your mood, what automation.

Perl often makes it difficult to tell the difference.

One of my favorite details is this line:

```Perl
sort { length $b <=> length $a }
```

Longer operators are placed before shorter ones.

That may sound trivial.

It is not.

Suppose the language contains both:

```
<
<=
```

If the parser recognizes  first, then <= immediately becomes a problem.

The parser happily consumes the first character and leaves the second one behind looking confused.

That tends not to end well.

So the solution is refreshingly direct:

Eat the longer operators first.

No grand theory.

No academic paper.

Just common sense encoded into a sorting operation.

And somehow that is enough.

This is one of the things I enjoy about small language implementations.

In larger systems, operator recognition is often hidden behind layers of lexer generators, grammar definitions, token specifications, and build pipelines.

Again, there is absolutely nothing wrong with that.

But here, the whole mechanism is sitting in plain sight.

You can point at the code and say:

That's the part that teaches the language its operators.

And the answer is:

Yes.

It's a regular expression.

There is also something pleasingly self-referential about it.

The language contains operators.

The operators generate a regular expression.

The regular expression recognizes the operators.

The system is, in a small way, describing itself.

Many parser generators can achieve the same result.

They will likely do it more formally.

Possibly more elegantly.

Certainly with more documentation.

But there is a particular joy in watching a few lines of Perl construct part of a parser from nothing more than a hash table and a stubborn belief that this really ought to work.

And the annoying thing is:

It does.

Quite well, in fact.

At moments like this, it becomes difficult to remember whether chabo-dsl is a DSL engine that happens to use regular expressions,

or a collection of regular expressions that accidentally grew into a DSL engine.

Honestly, I'm still not entirely sure.

And I suspect Perl likes it that way.
## 4. Feeding Japanese to a Parser?
No. We Spoil It with Regular Expressions First.

One of my favorite parts of chabo-dsl is that the parser itself does not need to understand Japanese.

In fact, it is probably better that way.

The job of handling Japanese belongs to Sugar.pm.

The name is appropriate.

Not Translator.

Not Preprocessor.

Not NaturalLanguageEngine.

Just:

```
Sugar
```

A layer of sweetness applied before the language reaches the machinery underneath.

The idea is simple.

Rather than teaching the parser how to understand Japanese directly, we gently transform Japanese expressions into ordinary chabo-dsl syntax before the parser ever sees them.

In other words:

```
Japanese
↓
Sugar.pm
↓
chabo-dsl syntax
↓
Parser
```

The parser remains blissfully ignorant.

And that ignorance is a feature.

Consider a sentence like:

```
もし信号が青か緑なら進んでも良い以外で
その他の行を表示する
```

The parser does not need to understand what "if" means in Japanese.

It does not need to know what "green" means.

It does not need to care about nuances of Japanese grammar.

By the time the expression reaches the parser, it has already been transformed into something closer to:

```
信号 == 青 || 信号 == 緑
? 進んでも良い
:
```

The parser simply handles a conditional expression.

As far as it is concerned, it is just another AST.

The interesting part is how we get there.

At the heart of the transformation sits a regular expression that looks roughly like this:

```Perl
$text =~ s/
もし(.+?)
(?:なら|の場合|の時|時)
(?:は)*
(.+?)
以外(?:(?:は|で))?
/
...
/gex;
```

Whenever I see code like this, I experience three reactions in rapid succession.

First:

That's impressive.

Then:

That's slightly terrifying.

And finally:

That's beautiful.

Not necessarily in that order.

What the expression is doing is actually quite straightforward.

It looks for:

```
"もし"
↓
a condition
↓
some variation of "なら"
↓
the true branch
↓
"以外"
```

Then Perl takes the captured pieces and constructs a conditional expression.

Nothing mystical.

Nothing supernatural.

Just pattern matching.

And yet, by the time the substitution finishes, a piece of Japanese-like syntax has quietly become executable DSL code.

That transformation feels almost unfair.

A parser generator would probably prefer a proper grammar.

A language theorist might raise an eyebrow.

Perl, meanwhile, shrugs and starts another substitution.

The real trick here is philosophical.

The parser is not becoming smarter.

Japanese is becoming simpler.

Rather than expanding the parser's understanding of the world, we reshape the input until it fits a world the parser already understands.

That distinction matters.

Because once you adopt this approach, the parser no longer belongs to Japanese.

Or English.

Or any human language.

It belongs to the language underneath.

Sugar.pm simply teaches humans how to speak to it.

And honestly, that may be the most Perl solution imaginable.

When confronted with a difficult problem, Perl rarely asks:

"How can we make the parser understand this?"

Instead, it often asks:

"How can we rewrite this so the parser doesn't have to?"

Sometimes the answer is another layer of abstraction.

Sometimes it is an entire compiler front-end.

And sometimes it is a slightly alarming regular expression followed by s///gex.

chabo-dsl chooses the latter more often than it probably should.

I think that's part of its charm.

## 5. Let Regular Expressions Absorb the Ambiguity

Most programming languages enjoy a luxury that Japanese does not.

They get to be precise.

An if is an if.

That's the rule.

End of discussion.

No synonyms.

No alternative phrasings.

No subtle differences in tone.

The keyword exists, the parser recognizes it, and everyone goes home happy.

Japanese has other ideas.

Suppose we want to express a condition.

A speaker might write:

```
なら
```

Or:

```
の場合
```

Or:

```
の時
```

Or simply:

```
時
```

To a human reader, these are all perfectly reasonable variations.

To a parser, however, they are four entirely different character sequences.

And parsers are not known for their appreciation of linguistic nuance.

This is where Sugar.pm becomes useful.

Rather than forcing users to memorize a single rigid form, it accepts several ways of saying essentially the same thing:

```Perl
(?:なら|の場合|の時|時)
```

When I first wrote that, I realized it was less a grammar rule and more a statement of attitude.

It roughly translates to:

"Sure. Let's just call all of these 'if'."

And honestly, that works surprisingly well.

One of the recurring themes in chabo-dsl is that Japanese is not treated as something to be strictly parsed.

It is treated as something to be gently normalized.

That is an important difference.

The goal is not to fully understand natural language.

The goal is merely to reduce variation until the parser sees something manageable.

You could describe the process as:

```
Human expression
↓
Regular expression
↓
A slightly less human expression
↓
Parser
```

The parser remains happy because it receives a predictable structure.

The user remains happy because they are allowed to speak somewhat naturally.

And somewhere in the middle, a regular expression quietly takes the blame for making those two worlds compatible.

There is something oddly fitting about this.

Human language is inherently fuzzy.

Regular expressions are often accused of being overly rigid.

Put them together carefully, and they form an unexpected partnership.

The human provides ambiguity.

The regular expression absorbs just enough of that ambiguity to keep the machinery running.

Not all of it, of course.

That would be impossible.

Eventually language becomes complicated enough that regular expressions begin to protest.

Sometimes loudly.

But for small DSLs, where the range of expression is intentionally limited, this approach can be remarkably effective.

In fact, it feels almost natural.

Japanese allows multiple ways to express the same intention.

The DSL accepts multiple ways to express the same construct.

The regular expression simply acts as a diplomatic interpreter between them.

Not a linguist.

Not an AI.

Not a language model.

Just a pattern matcher trying its best.

And that is precisely why I like it.

Because the solution is not pretending to be smarter than it really is.

The code does not claim to understand Japanese.

It merely says:

"I've seen enough of these phrases to know they probably mean the same thing."

There is a certain humility in that approach.

And, perhaps surprisingly, it is often all a small language needs.

After all, one of Perl's oldest habits is looking at a messy real-world problem and saying:

"Let's not solve the entire problem today.

Let's just make this case work first."

A regular expression like:

```Perl
(?:なら|の場合|の時|時)
```

is exactly that philosophy rendered in code.

A tiny compromise.

A tiny convenience.

A tiny act of mercy.

And somehow, a tiny act of mercy can make a language feel a great deal more human.
## 6. Even Comparison Operators Learn Japanese

At some point, every language needs to answer a simple question:

How do we compare things?

Most programming languages solve this with symbols.

```
<
<=
>
>=
==
!=
```

Short.

Efficient.

Completely unreadable to anyone who has never programmed before.

Japanese speakers, meanwhile, often prefer words.

And honestly, that seems reasonable.

Saying:

```
金額が100以上
```

feels far more natural than writing:

```
金額 >= 100
```

At least if you're thinking in Japanese.

So Sugar.pm quietly acts as a translator.

It contains a mapping that looks something like this:

```Perl
my %jp_op = (
'未満' => '<',
'以下' => '<=',
'超える' => '>',
'以上' => '>=',
'等しい' => '==',
'異なる' => '!=',
'以外' => '!=',
'じゃない' => '!=',
'でない' => '!=',
);
```

At first glance, this may not look particularly exciting.

It is just a hash table.

A very ordinary hash table.

But hidden inside it is a small act of language design.

Consider:

```
金額が100以上
```

After translation, it becomes:

```
金額 >= 100
```

Nothing magical happened.

No grammar trees were expanded.

No parser rules were added.

No semantic analysis engine was awakened.

A phrase simply turned into an operator.

And the parser remained completely unaware that Japanese had ever been involved.

That is a recurring pattern throughout chabo-dsl.

Whenever possible, complexity is removed before the parser sees it.

The parser never has to learn Japanese.

Japanese learns how to speak parser.

The same idea applies to logical operators.

There is another translation table:

```Perl
my %jp_logical = (
'で' => '&&',
'かつ' => '&&',
'か' => '||',
'または' => '||',
);
```

Which means an expression like:

```
信号が青か緑
```

becomes:

```
信号 == 青 || 信号 == 緑
```

The resulting expression is no longer uniquely Japanese.

It is simply an expression.

Something the AST builder already knows how to handle.

Something the evaluator already understands.

Something the parser can process without having to know anything about Japanese conjunctions.

And this is where regular expressions stop looking like search tools and start looking like language transformers.

That might sound grandiose.

Perhaps it is.

But there is a meaningful distinction here.

Most people encounter regular expressions as a way to find text.

Match a pattern.

Extract a value.

Replace a substring.

Done.

In Sugar.pm, they are doing something slightly different.

They are rewriting one language into another.

Not a completely different language.

Just a nearby dialect.

Close enough that the parser feels at home.

Far enough that humans feel comfortable writing it.

I find that fascinating.

Because suddenly a regular expression is no longer asking:

"Does this text match a pattern?"

It is asking:

"Can this sentence become something more useful?"

That is a surprisingly powerful role for a tool that many people still think of as glorified text search.

Of course, nobody would mistake this for a full natural-language processing system.

And that is precisely the point.

The goal is not to understand every possible Japanese sentence.

The goal is not linguistic perfection.

The goal is merely to support a small, pleasant vocabulary that maps cleanly onto a small, pleasant DSL.

Nothing more.

But also nothing less.

There is a certain beauty in that restraint.

The language does not attempt to understand all of Japanese.

It only understands the pieces it needs.

And whenever a phrase can be translated into a familiar operator, it quietly hands the problem over to the parser and moves on.

No drama.

No ceremony.

Just another substitution.

Another regular expression.

Another reminder that, given enough determination, Perl will happily turn words into operators and continue as if this were the most normal thing in the world.

And somehow, after a while, you start to believe it.
## 7. s///gex: One of Perl's Most Dangerous Ideas

There are many features in Perl that make people nervous.

Some deserve the reputation.

Some do not.

And then there is this:

```Perl
s/PATTERN/REPLACEMENT/gex;
```

A small collection of letters that has probably launched thousands of questionable ideas.

It is also one of my favorite things in the language.

To understand why, let's break it apart.

```Perl
g
```

means:

Find all matches.

```Perl
e
```

means:

Treat the replacement as Perl code and execute it.

And:

```Perl
x
```

means:

Let the regular expression breathe a little.

Add whitespace.

Make it readable.

Individually, these flags are useful.

Together, they become something else.

Something slightly alarming.

Because now the substitution is no longer replacing text with text.

It is replacing text with the result of running code.

At that point, calling it a "replacement" feels almost dishonest.

It starts looking more like a tiny compiler stage.

Consider the general form:

```Perl
s/
pattern
/
do {
...
...
...
}
/gex;
```

The regular expression identifies a structure.

The Perl code examines what was captured.

The replacement generates a new structure.

Input becomes output.

One representation becomes another.

A transformation takes place.

That is suspiciously close to what language processors do.

You begin with text.

You recognize a pattern.

You extract meaning.

You produce a new representation.

This may technically be "just a substitution."

But only in the same sense that a chainsaw is "just a knife."

The mechanism has evolved beyond its original purpose.

And Perl is perfectly happy about that.

One of the reasons Sugar.pm works so well is that s///gex allows pattern matching and transformation to live in the same place.

Instead of writing:

```
Match something
↓
Store temporary state
↓
Call helper functions
↓
Construct replacement text
```

you can simply write:

```Perl
s/.../.../gex;
```

The pattern and the transformation become parts of a single thought.

That is incredibly convenient.

It is also incredibly tempting.

Because once you realize you can do this, every problem begins to look vaguely replaceable.

You start innocently enough.

Perhaps a small syntax transformation.

Perhaps a little bit of sugar.

Nothing dangerous.

Then a second transformation appears.

Then a third.

Soon you find yourself building a language feature through a chain of substitutions and wondering whether you've become the sort of person who debugs parsers with regular expressions.

The answer is usually yes.

And at that point, it is already too late.

One of the things I enjoy about chabo-dsl is that it embraces this tendency rather than pretending it doesn't exist.

Some languages keep parsing and transformation strictly separated.

There are good reasons for doing that.

Very good reasons.

Professional reasons.

Responsible reasons.

Perl, however, occasionally asks:

What if the transformation lived right next to the pattern?

And then hands you s///gex.

The result is both elegant and slightly reckless.

A combination Perl has always seemed strangely fond of.

Of course, this does not mean regular expressions can solve every parsing problem.

They cannot.

Eventually you encounter nested structures, recursive constructs, precedence rules, or situations where the problem stubbornly refuses to resemble a string substitution.

Reality always returns.

ASTs still need to be built.

Trees still need to be traversed.

Languages still need actual structure.

But before that moment arrives, s///gex can carry an astonishing amount of weight.

Enough weight, occasionally, to make you feel clever.

And that may be the most dangerous part of all.

Because after you've transformed a few pieces of syntax with a single substitution, the brain begins whispering:

Perhaps the next language feature could be another regex.

Then another.

Then another.

And before long, an entire DSL is standing in front of you.

At which point you have two choices.

You can step back and redesign everything with proper compiler architecture.

Or you can look at the growing pile of regular expressions and think:

Honestly, this is working better than it has any right to.

chabo-dsl tends to choose the second option.

I think Perl approves.

And, if I'm being honest, so do I.
## 8. What Is a Tokenizer, Anyway?

In most textbooks on language implementation, the story begins like this:

```
Source Code
↓
Lexer
↓
Token Stream
```

Clean.

Orderly.

Respectable.

The lexer examines the input, identifies meaningful pieces, and produces a sequence of tokens for the parser.

Everyone agrees on the terminology.

Everyone nods approvingly.

And then chabo-dsl shows up and makes things slightly awkward.

Because in practice, the flow looks more like this:

```
Source Code
↓
adjust()
↓
item_split()
↓
Tokens
```

And somewhere between those steps, an alarming number of regular expressions are quietly doing most of the work.

This raises an interesting question.

If a collection of regexes and string manipulations performs lexical analysis, is it still a tokenizer?

I would argue that it is.

Whether or not it dresses like one.

The job remains the same.

Text goes in.

Tokens come out.

The machinery in the middle is merely a matter of implementation.

What happens during that journey?

Quite a lot, actually.

Strings need protection.

Whitespace needs adjustment.

Operators need separation.

Sequences like:

```
++
--
```

need special treatment.

Parentheses need attention.

Ambiguous boundaries need clarification.

Characters that seemed harmless five minutes ago suddenly become important.

Little by little, the raw input is transformed into something the parser can safely consume.

None of these operations are particularly glamorous.

Nobody writes conference papers about trimming whitespace.

Yet language implementations spend an astonishing amount of time doing exactly these sorts of things.

The reality of parsing is that before a parser can be clever, somebody has to do the housekeeping.

And housekeeping is rarely elegant.

Fortunately, regular expressions have never cared much about elegance.

They are perfectly content to perform the repetitive work.

Find this.

Replace that.

Protect those characters.

Separate these operators.

Move on.

No ceremony.

No philosophy.

Just relentless text processing.

One of the things I like about chabo-dsl is that it does not pretend otherwise.

There is no giant lexical-analysis subsystem standing proudly between the source text and the parser.

Instead, there is a collection of small operations that gradually coax structure out of a string.

Each operation does a little.

Together they accomplish something larger.

That approach feels very Perl.

Perl has always excelled at solving practical problems through accumulation.

Not necessarily with one grand mechanism.

Often with many small ones.

The result can look improvised.

Sometimes it is improvised.

But that does not make it ineffective.

In fact, many tokenizers are ultimately doing the same kinds of transformations.

They simply hide them behind more formal abstractions.

chabo-dsl leaves them in plain sight.

And there is a certain honesty in that.

You can follow the process almost step by step:

```
Protect a string.
Separate an operator.
Normalize some spacing.
Split an expression.
Repeat.
```

Eventually, tokens emerge.

Not because a majestic lexer descended from the heavens and bestowed order upon the text.

But because a long series of very ordinary operations gradually reduced the chaos.

That may sound less impressive.

Perhaps it is.

Yet language processing often works that way.

Complexity is rarely defeated in one heroic battle.

More often, it is worn down by countless small decisions.

A regular expression here.

A string adjustment there.

Another split operation around the corner.

And before long, what began as an arbitrary sequence of characters has quietly become a token stream.

At that point, people start calling it a tokenizer.

Which is perfectly reasonable.

After all, if it walks like a tokenizer and produces tokens like a tokenizer, arguing about terminology may be less important than acknowledging what it has already accomplished.

And chabo-dsl, characteristically, seems content to let the regular expressions do the talking.
## 19. And That Is Why I Think It's Fine

Every now and then, someone will look at chabo-dsl and ask a perfectly reasonable question:

"Wouldn't this be better with a proper parser?"

Perhaps.

In fact, it probably could be.

The lexer could become a separate component.

The grammar could be expressed in BNF.

A parser generator could be introduced.

AST construction could move into its own set of classes.

The architecture could become cleaner.

More formal.

More academically respectable.

There is nothing wrong with any of that.

Quite the opposite.

Those are all valid directions.

Some of them are very good directions.

But chabo-dsl has something that those alternatives would not necessarily preserve.

Namely, the peculiar charm of its current shape.

The distance between idea and implementation is remarkably short.

Consider the overall flow:

```
Text
↓
Regular Expression
↓
A Little Transformation
↓
Another Regular Expression
↓
Tokens
↓
AST
↓
Perl
```

That is not a grand architecture diagram.

It is more like a trail of breadcrumbs.

A developer can look at a piece of input and think:

"First I'll split this here..."

"Then I'll normalize that..."

"Then I'll build a tree from what's left..."

And then simply do exactly that.

The code follows the thought process almost directly.

There is very little distance between intention and implementation.

I find that appealing.

Perhaps more appealing than it should be.

Large language-processing systems often gain power through layers of abstraction.

Small language-processing systems sometimes gain power by avoiding layers whenever possible.

chabo-dsl belongs firmly in the second category.

It is not trying to become a compiler framework.

It is not trying to become an academic demonstration of parsing theory.

It is not trying to impress anyone with architectural sophistication.

Instead, it embraces a much simpler idea:

Take a string.

Understand it just enough.

Build an AST.

Let Perl handle the rest.

And somehow, that works.

More importantly, it remains enjoyable.

That last part matters.

Software engineering literature often focuses on correctness, maintainability, extensibility, and performance.

Those things matter.

They matter a great deal.

But there is another quality that receives less attention:

fun.

Not every project exists to solve enterprise-scale problems.

Not every parser needs to survive a decade of feature growth.

Sometimes a language exists because building it is entertaining.

Sometimes a parser exists because somebody looked at a string and wondered:

"Could I make this work?"

chabo-dsl contains a lot of that energy.

You can feel it in the regular expressions.

You can feel it in the syntax transformations.

You can feel it in the AST construction.

The code often feels less like a carefully negotiated treaty between software components and more like a conversation between a programmer and a piece of text.

A slightly stubborn conversation.

A very Perl conversation.

Which is why, when people suggest replacing everything with a more sophisticated parsing infrastructure, my reaction is not disagreement.

It is appreciation.

That would be interesting too.

But it would also be a different project.

A better project?

Perhaps.

A more scalable project?

Almost certainly.

A more enjoyable project?

That is harder to answer.

Because part of chabo-dsl's identity comes from this unusual closeness:

```
Text
↓
Regex
↓
Regex
↓
Token
↓
AST
↓
Perl
```

No vast machinery.

No towering framework.

Just a handful of transformations, accumulating until a language quietly emerges.

There is something satisfying about that.

Something deeply Perl-like.

And so, when I look at the code and find myself thinking:

"The tokenizer and parser are mostly regular expressions."

I arrive at the same conclusion every time.

Yes.

They are.

And honestly?

I think that's fine.
!!20. Regular Expressions Are Not Black Magic

Regular expressions are often accused of being black magic.

To be fair, they do not always make a convincing case for their innocence.

When someone encounters something like:

```Perl
s/
もし(.+?)
(?:なら|の場合|の時|時)
(?:は)*
(.+?)
以外(?:(?:は|で))?
/
...
/gex;
```

for the first time, taking a cautious step backward is a perfectly understandable reaction.

I would not blame them.

There is a certain look that large regular expressions acquire after they have grown beyond a reasonable size.

A look that suggests they may have been assembled during a thunderstorm by a programmer who had not slept properly in several days.

From a distance, they can appear almost supernatural.

But if you look closely, something interesting happens.

The mystery begins to disappear.

Because the expression is not actually performing dark magic.

It is doing something surprisingly mundane.

It is looking for:

```
"もし"
↓
some condition
↓
a variation of "なら"
↓
a true branch
↓
"以外"
```

And then transforming those pieces into a conditional expression.

That is all.

No hidden demons.

No secret compiler theory.

No forbidden knowledge passed down through generations of Perl programmers.

Just pattern recognition.

The illusion comes from compression.

The regular expression takes a sequence of very ordinary steps and compresses them into a compact piece of syntax.

Humans tend to trust long explanations.

We become suspicious when the same logic fits into a few symbols.

And regular expressions are extremely good at making ordinary logic look suspicious.

Perhaps too good.

This is one reason they earned their reputation.

Not because they are inherently magical.

But because they often hide simplicity behind unfamiliar notation.

Once you expand them mentally, the structure is usually straightforward:

```
Find this.
Capture that.
Ignore those variants.
Extract these values.
Rewrite the result.
```

None of that is especially mysterious.

In fact, most parsers perform similar operations.

They simply spread them across more files, more functions, and more abstractions.

A regular expression tends to place everything in one location and say:

"Here.

It's all happening right here."

That concentration can be intimidating.

But intimidation and complexity are not the same thing.

Of course, Perl occasionally complicates matters.

A regular expression by itself is one thing.

A regular expression combined with:

```Perl
/gex
```

is something else entirely.

At that point, pattern matching, code execution, and transformation are all happening in the same construct.

Even seasoned programmers sometimes stare at such expressions for a moment before deciding whether they admire them or fear them.

The answer is often both.

And perhaps that is part of the fun.

Because learning regular expressions is a little like learning a strange dialect.

At first, everything looks cryptic.

Then patterns begin to emerge.

Gradually, symbols that once appeared incomprehensible start feeling familiar.

Eventually you stop seeing:

```Perl
(.+?)
```

and start seeing:

"Ah. That's the thing we're trying to capture."

The notation disappears.

The intention remains.

That is usually the moment when a programmer crosses an invisible line.

Before that point, regular expressions look like black magic.

After that point, they look like a tool.

An occasionally dangerous tool.

An occasionally reckless tool.

A tool capable of producing unreadable horrors when handled carelessly.

But still just a tool.

And chabo-dsl depends heavily on that distinction.

It does not treat regular expressions as magical.

It treats them as practical.

They normalize text.

They recognize operators.

They absorb linguistic variation.

They transform Japanese-like syntax into parser-friendly expressions.

They help prepare the input for the AST builder.

Nothing more.

And, importantly, nothing less.

Because sometimes the most impressive thing about a regular expression is not that it performs an impossible task.

It is that it performs an ordinary task so efficiently that it briefly appears impossible.

That is where the illusion comes from.

Not from magic.

Not from mystery.

Just from a lot of work being compressed into a surprisingly small space.

Of course, Perl regular expressions have occasionally wandered close enough to black magic that the distinction becomes difficult to defend.

I am willing to concede that point.

But at their best, regular expressions are not mysterious at all.

They are simply a concise way of describing patterns.

A language for talking about structure.

And in chabo-dsl, they spend most of their time doing exactly that.

Quietly.

Relentlessly.

Turning strings into something a parser can understand.

Which, when you think about it, is already quite impressive without involving magic at all.
## 21. The Game of Writing Parsers with Regular Expressions

When people talk about language implementation, they often imagine something enormous.

Something architectural.

Something that arrives carrying an entire vocabulary of serious terminology:

```
Lexer
Parser
AST
Semantic Analysis
Code Generation
```

The words themselves sound important.

And rightly so.

These are the foundations of real compilers and real programming languages.

If you follow that path far enough, you eventually arrive in a world full of grammar specifications, parser generators, optimization passes, and large systems built by people far smarter than I am.

It is a fascinating world.

It is also, occasionally, an intimidating one.

Because when you're standing at the entrance, it can feel as though language implementation requires a vast amount of machinery before anything interesting can happen.

But that is not entirely true.

Sometimes the first step looks more like this:

```Perl
$text =~ s/.../.../;
```

Just a substitution.

Nothing grand.

Nothing academic.

Just a string becoming a slightly different string.

And yet something important has already happened.

A pattern has been recognized.

A structure has been transformed.

A decision has been made about what the text means.

That may not be a compiler.

But it is moving in the same direction.

Soon another transformation appears.

Then a token list.

Then perhaps a small recursive function.

Then an AST.

And one day, almost accidentally, you discover that:

```
1 + 2 * 3
```

evaluates to:

```
7
```

At that moment, something remarkable has occurred.

A language has come to life.

Not a large language.

Not an industrial language.

Not a language with a standards committee.

Just a small language.

But a language nonetheless.

I have always liked that moment.

There is a particular satisfaction in watching meaning emerge from machinery that did not exist a few hours earlier.

A string becomes tokens.

Tokens become a tree.

The tree becomes a calculation.

And suddenly the computer is no longer processing characters.

It is processing ideas.

That transition feels a little magical every time.

Not because it is mysterious.

Quite the opposite.

Because it becomes understandable.

You can trace every step.

You can point at the code and say:

"That regex recognized the operator."

"That function split the expression."

"That recursive call built the subtree."

The entire language fits inside your head.

And that is an enormously enjoyable place to be.

Large language systems often require abstraction because no one person can hold the entire design in memory.

Small language systems have the opposite luxury.

You can understand all of it.

Every transformation.

Every shortcut.

Every questionable decision.

Especially the questionable decisions.

And if you happen to be using Perl, there is a good chance that some of those decisions involve regular expressions.

Perhaps more of them than strictly necessary.

Which brings us back to the idea of writing parsers with regexes.

Strictly speaking, that phrase usually starts arguments.

Someone points out the limitations of regular expressions.

Someone else mentions context-free grammars.

A third person begins drawing diagrams.

Soon everybody is discussing what regexes can and cannot do.

They are usually correct.

Regular expressions are not a complete solution to parsing.

They were never meant to be.

Eventually you need structure.

Eventually you need trees.

Eventually you need recursion.

Reality insists upon these things.

But none of that diminishes the joy of the first few steps.

The moment when a pattern match turns into a token.

The moment when a token stream turns into an AST.

The moment when an expression finally evaluates correctly.

Those moments are fun.

And fun matters.

Sometimes we talk about language implementation as though it were purely an engineering discipline.

But it is also a kind of play.

A kind of exploration.

A way of asking:

"What happens if I teach a computer to understand this?"

chabo-dsl exists largely because of that question.

Not because the world desperately needed another DSL.

Not because Perl was the obvious strategic choice.

But because it was interesting.

Because building little languages is enjoyable.

Because regular expressions are surprisingly capable.

And because there is an undeniable thrill in watching a simple idea grow into something that can actually execute.

That is why I think of chabo-dsl as more than a DSL engine.

It is also an experiment.

A reminder that language implementation does not always have to begin with a mountain of infrastructure.

Sometimes it begins with a regex.

Then another regex.

Then a token array.

Then a tree.

And eventually, before you quite realize what has happened, a language is standing there in front of you.

Looking perfectly natural.

As though it had been there all along.

And that, to me, is one of the most enjoyable games a programmer can play.
!!22. Finally: A Love Letter to Perl and Regular Expressions

Look through the code of chabo-dsl and you will find all the usual suspects.

There is:

```Perl
qr//
```

There is:

```Perl
s///
```

There is:

```Perl
split
```

There are:

```Perl
$1
$2
```

And scattered throughout the code, you'll find flags like:

```Perl
/g
/e
/x
```

Waiting patiently for an opportunity to cause trouble.

And somewhere beyond all of that, eventually, there is an AST.

None of this happened by accident.

The whole thing feels like the result of three independent forces somehow deciding to cooperate.

Perl arrives with its eternal desire:

"I just need to manipulate this string a little."

Regular expressions respond immediately:

"Then let me handle it."

And the AST, standing quietly in the corner, eventually says:

"Fine.

Once you're done turning strings into pieces, I'll turn the pieces into a tree."

Somehow, against all reasonable expectations, the arrangement works.

That is essentially the story of chabo-dsl.

Not a grand architectural vision.

Not a carefully orchestrated compiler project.

Just a collection of ideas that happened to fit together remarkably well.

Which is why, when people ask what kind of project chabo-dsl really is, I hesitate.

Because it is certainly a DSL engine.

But it is also something else.

It is a record of a particular way of thinking.

A very Perl way of thinking.

A way of looking at a string and immediately wondering:

"Could a regex do this?"

Not because a regex should do this.

Not because it is always the correct choice.

But because curiosity asks the question before caution has a chance to intervene.

Perl programmers know this feeling.

Or at least many of them do.

You begin with a harmless pattern.

Then another.

Then a substitution.

Then a capture group.

Before long, a surprising amount of language processing has emerged from what originally looked like a text manipulation problem.

At some point, an AST appears.

At another point, evaluation starts working.

And eventually you're forced to admit that what you built is no longer merely a collection of regexes.

It has become a language.

A small one, perhaps.

An unconventional one, certainly.

But undeniably a language.

And that realization is deeply satisfying.

Because language implementation is often presented as something enormous.

Something requiring layers of formalism and sophisticated tooling.

Those things are valuable.

They matter.

But there is another path.

A smaller path.

A messier path.

A path where you sweeten some Japanese expressions, recognize a few operators, protect a few strings, chase a few parentheses, and gradually assemble an AST.

And somehow, at the end of that journey, computation happens.

The AST evaluates.

The program runs.

The language lives.

All from a surprisingly small collection of moving parts.

That is what I find beautiful.

Not that regular expressions can do everything.

They cannot.

Not that Perl is the perfect language.

It is not.

But that a handful of simple ideas, combined with enough persistence, can produce something far more substantial than their individual pieces suggest.

Perhaps that is why I never quite agreed with the claim that regular expressions are merely a tool.

In projects like this, they become characters.

They participate.

They interfere.

They make suggestions.

Occasionally, they lead you into bad decisions.

Occasionally, they lead you somewhere wonderful.

And once you start listening to them, it becomes surprisingly difficult to stop.

That, I suspect, is the real danger.

Not complexity.

Not maintainability.

Not performance.

Curiosity.

The moment you write:

```Perl
$text =~ s/.../.../
```

and realize it worked.

The moment a small transformation becomes a parser feature.

The moment a parser feature becomes part of a language.

Those are the moments that pull you forward.

One step at a time.

One regex at a time.

Until eventually there is no turning back.

And honestly?

I think that's fine.

Because it's Perl.

Because they're regular expressions.

And because, in the end,

that's what chabo-dsl is.

