# Chabo-DSL: Could It Support Multiple Languages?

Chabo-DSL is a small DSL that I am building from scratch in Perl.

Right now, it supports a Japanese-style DSL.

...but one day, I suddenly had a thought:

> **Wait... couldn't this work with other languages too?**

I only speak Japanese. 😄

So honestly, I don't really know English, Korean, Chinese, let alone Arabic very well.

But when I looked at the internal design of Chabo-DSL, I noticed something interesting:

**The parts that depend on natural language and the parts that don't are fairly cleanly separated.**

---

## Ast.pm Doesn't Know Natural Languages

At the heart of Chabo-DSL is `Ast.pm`.

Basically, `Ast.pm` doesn't know anything about natural languages.

For example, if it receives:

```text
(Age >= 18) ? Adult : Minor
```

it can parse the expression into an AST and evaluate it.

The important thing here is that `Ast.pm` doesn't understand English just because the identifiers happen to be English.

From the point of view of `Ast.pm`, these are simply **identifiers and values**.

So this:

```text
Age
Adult
Minor
```

could just as well be:

```text
나이
성인
미성년자
```

or:

```text
年龄
成年人
未成年人
```

or even:

```text
العمر
بالغ
قاصر
```

As far as `Ast.pm` is concerned, they're all just identifiers and values.

---

# So Where Does the Natural Language Live?

That's where `Sugar.pm` comes in.

With the Japanese DSL, for example, a human-friendly expression like:

```text
もし年齢が18以上なら成人以外未成年
```

can be converted by `Sugar.pm` into:

```text
(年齢 >= 18) ? 成人 : 未成年
```

In other words:

```text
Human-friendly language
          ↓
      Sugar.pm
          ↓
 Common Chabo-DSL expression
          ↓
       Ast.pm
          ↓
       Execution
```

And this separation between `Sugar.pm` and `Ast.pm` might lead to something rather interesting.

---

# Could English Work Too?

Suppose we created an English version of Sugar.

Input:

```text
If Age is greater than or equal to 18 then Adult else Minor
```

After Sugar conversion:

```text
(Age >= 18) ? Adult : Minor
```

Then we could pass that to `Ast.pm` just like we do with Japanese.

`Ast.pm` would basically say:

> "English? What's that?"

and simply continue doing its job. 😄

---

# What About Korean?

For example:

```text
나이가 18 이상이면 성인 아니면 미성년자
```

could be converted into:

```text
(나이 >= 18) ? 성인 : 미성년자
```

Then it could be passed to the same `Ast.pm`.

---

# What About Chinese?

For example:

```text
如果年龄大于等于18则成年人否则未成年人
```

could become:

```text
(年龄 >= 18) ? 成年人 : 未成年人
```

Again, the AST engine doesn't really care.

---

# And Then There's Arabic...

At this point, I was getting a little carried away. 😄

For example:

```text
إذا كان العمر أكبر من أو يساوي 18 فبالغ وإلا قاصر
```

could be converted into:

```text
(العمر >= 18) ? بالغ : قاصر
```

And then...

**Ast.pm still doesn't particularly care.**

Japanese:

```text
年齢
```

English:

```text
Age
```

Korean:

```text
나이
```

Chinese:

```text
年龄
```

Arabic:

```text
العمر
```

From the perspective of `Ast.pm`, they're all just variable names.

---

# Unicode Variable Names Are Already Supported

This is where the variable-name definition in `Ast.pm` becomes interesting.

```perl
VAR_NAME => qr/[\p{L}_][\p{L}\p{N}_]*/u
```

`\p{L}` represents Unicode letters, while `\p{N}` represents Unicode numbers.

That means variable names such as:

```text
年齢
Age
나이
年龄
العمر
```

can be handled by the same basic mechanism.

So, for example:

```text
年齢 = 20
Age = 20
나이 = 20
年龄 = 20
العمر = 20
```

could potentially all be handled by the same AST engine.

---

# Sugar.pm Becomes a "Translator"

Thinking about it this way makes the role of `Sugar.pm` rather interesting.

Instead of thinking of `Sugar.pm` as the language implementation itself, we could think of it as:

> **A translation layer that converts human-friendly language into a common representation understood by `Ast.pm`.**

For example:

```text
Japanese
   ↓
Sugar.ja.pm
   ↓
(年齢 >= 18) ? 成人 : 未成年
   ↓
Ast.pm
```

For English:

```text
English
   ↓
Sugar.en.pm
   ↓
(Age >= 18) ? Adult : Minor
   ↓
Ast.pm
```

For Korean:

```text
한국어
   ↓
Sugar.ko.pm
   ↓
(나이 >= 18) ? 성인 : 미성년자
   ↓
Ast.pm
```

And the `Ast.pm` waiting at the bottom is the **same one**.

That's the interesting part.

---

# Separating "Language" from "Runtime"

If we look at it this way, the architecture could become something like:

```text
             Japanese
                 │
             Sugar.ja
                 │
                 ↓
              ┌─────┐
English  →    │     │    ← Korean
              │Ast.pm│
Chinese  →    │     │    ← Arabic
              └─────┘
```

When adding a new language, we wouldn't necessarily need to modify `Ast.pm`.

Instead:

**Add a Sugar implementation that converts that language into the common Chabo-DSL representation.**

That's the idea.

---

# Of Course, This Is Still Just a "What If?" 😄

This part is important.

The English, Korean, Chinese, and Arabic examples above don't mean that I have actually implemented Sugar versions for those languages.

They're just experiments based on a simple question:

> **If `Ast.pm` doesn't depend on natural language, could we create a multilingual DSL simply by implementing a Sugar layer for each language?**

In practice, there would be plenty of things to think about:

* Syntax parsing for each language
* Word order
* Particles and prepositions
* Inflection
* Plural forms
* String literals
* Comments
* Operator expressions
* Statement separators
* Function names
* Error messages

And once we get to Arabic...

Honestly, I'm completely out of my depth. 😄

---

# But the Design Is Kind of Interesting

One of the things I found interesting while building Chabo-DSL was this:

**I started out thinking I was building a Japanese programming language.**

But once I separated the Japanese-specific parts, I realized that underneath them was actually a fairly ordinary language-processing engine.

The Japanese DSL lives in:

```text
Sugar.pm
```

—the "human-friendly" part.

Underneath that, there are components such as:

```text
Tokenizer
Parser
AST
Evaluator
Scope
Function
```

and none of those fundamentally need to know what natural language the source code was written in.

So perhaps...

> **I thought I was building a Japanese DSL, but maybe I was actually building the foundation for a multilingual DSL.**

That's a thought I couldn't help having.

It's still an experiment, though. 😄

