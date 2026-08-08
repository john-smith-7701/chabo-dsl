# chabo-dsl Language Reference

## Overview

**chabo-dsl** is a lightweight scripting language centered around expression evaluation.

Its main features are:

* Numeric operations
* String manipulation
* Comparison operations
* Logical operations
* Ternary operator
* Variables
* Global variables
* Arrays
* Hashes
* User-defined functions
* Recursive calls
* Built-in functions
* Unicode variable names

---

## Data Types

### Numbers

Both integers and floating-point numbers can be used.

```text
123
3.14
-10
```

#### Example

```text
1 + 2 * 3
```

Result:

```text
7
```

### Strings

Strings can be enclosed in either single quotes or double quotes.

```text
"hello"
'world'
```

#### Example

```text
"abc"
```

---

## Variables

Variables are defined by assignment.

```text
x = 10;
arr = [1, 2, 3];
has = {a: 1, b: 2};
```

### Local Variables

Normal assignments are treated as local variables.

```text
a = 10;
b = a + 5;
```

### Global Variables

Using `:=` stores a variable in the global scope.

```text
a := 10;
```

---

## Arrays

Arrays are defined using `[]`.

```text
[1, 2, 3]
```

### Accessing Array Elements

```text
a[0]
```

Internally, this is converted to the following form:

```text
array(a, 0)
```

---

## Hashes

Hashes are defined using `{}`.

```text
{
    name: "john",
    age: 20
}
```

### Accessing Hash Values

```text
user{name}
```

Internally, this is converted to the following form:

```text
hash(user, name)
```

---

# Operators

Operators have precedence.

**The smaller the precedence value, the weaker the operator.**

## Statement Separator

Statements are separated by `;`.

```text
a = 1;
b = 2;
a + b
```

Result:

```text
3
```

---

## Logical Operators

### OR

```text
||
```

Example:

```text
a || b
```

### AND

```text
&&
```

Example:

```text
a && b
```

Logical operators use **short-circuit evaluation**.

---

## Assignment Operators

### Assignment

```text
=
```

Example:

```text
a = 10;
```

### Addition Assignment

```text
+=
```

Example:

```text
count += 1;
```

### Global Assignment

```text
:=
```

Example:

```text
a := 10;
```

---

## Comparison Operators

The following comparison operators are available.

| Operator | Meaning                  |
| -------- | ------------------------ |
| `!=`     | Not equal                |
| `<`      | Less than                |
| `<=`     | Less than or equal to    |
| `>`      | Greater than             |
| `>=`     | Greater than or equal to |

### Automatic Type Detection for Comparisons

When performing a comparison, `looks_like_number()` is used to automatically determine whether the operands are numbers or strings.

For numbers:

```text
10 < 20
```

For strings, the following comparisons corresponding to Perl's string comparison operators are used.

| Comparison               | Operator |
| ------------------------ | -------- |
| Less than                | `lt`     |
| Greater than             | `gt`     |
| Less than or equal to    | `le`     |
| Greater than or equal to | `ge`     |
| Equal                    | `eq`     |
| Not equal                | `ne`     |

---

## Arithmetic Operators

### Multiplication

```text
*
```

### Division

```text
/
```

If division by zero occurs, a `Zero divied!!` exception is raised.

### Modulo

```text
%
```

### Exponentiation

```text
**
```

Example:

```text
2 ** 8
```

Result:

```text
256
```

---

## Unary Operators

### Sign Negation

```text
-x
```

Internal representation:

```text
NGE
```

### Negation

```text
!x
```

---

## Ternary Operator

Returns one of two values depending on a condition.

### Syntax

```text
condition ? true_value : false_value
```

### Example

```text
age >= 20 ? "adult" : "child"
```

---

## Increment and Decrement

### Prefix

```text
++x
--x
```

### Postfix

```text
x++
x--
```

---

# User-Defined Functions

## Defining a Function

User-defined functions can be defined using the following syntax.

```text
add(a, b) = a + b
```

## Calling a Function

```text
add(1, 2)
```

Result:

```text
3
```

---

# Function Calls

Functions are called using the following syntax.

```text
func(arg1, arg2)
```

Example:

```text
sqrt(9)
```

---

# Control Constructs

## `return`

Exits a user-defined function.

```text
return(expr)
```

Example:

```text
fact(n) =
    n <= 1
    ? 1
    : n * fact(n - 1)

return(fact(5))
```

---

## `continue`

Returns to the beginning of a user-defined function.

```text
continue()
```

---

# Recursion

User-defined functions can call themselves recursively.

Example:

```text
fact(n) =
    n <= 1
    ? 1
    : n * fact(n - 1)
```

In this example, `fact()` calls itself.

---

# Built-in Functions

## Mathematical Functions

### `sqrt`

```text
sqrt(x)
```

Returns the square root.

### `sin`

```text
sin(x)
```

### `cos`

```text
cos(x)
```

### `int`

```text
int(x)
```

---

## String Functions

### `uc`

```text
uc(text)
```

Converts a string to uppercase.

### `lc`

```text
lc(text)
```

Converts a string to lowercase.

### `length`

```text
length(x)
```

Returns the length of a string or array.

### `substr`

```text
substr(text, start, length)
```

Returns a portion of a string.

### `split`

```text
split(regex, text)
```

Splits a string using a regular expression.

Return value:

```text
Array
```

### `join`

```text
join(sep, array)
```

Concatenates the elements of an array using the specified separator.

Example:

```text
join(",", ["a", "b", "c"])
```

Result:

```text
"a,b,c"
```

### `match`

```text
match(regex, text)
```

Returns a list of strings matching the regular expression.

Return value:

```text
Array
```

### `replace`

```text
replace(regex, replacement, text)
```

Replaces portions matching the regular expression.

Example:

```text
replace("a", "X", "abc")
```

Result:

```text
Xbc
```

---

# Array Manipulation Functions

### `push`

```text
push(arr, value)
```

Adds an element to the end of an array.

### `pop`

```text
pop(arr)
```

Removes and returns an element from the end of an array.

### `shift`

```text
shift(arr)
```

Removes and returns an element from the beginning of an array.

### `unshift`

```text
unshift(arr, value)
```

Adds an element to the beginning of an array.

---

# Range Operator

The `..` operator generates an array of consecutive numbers.

```text
1 .. 10
```

Result:

```text
[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
```

---

# Index Access

## Array

```text
arr[3]
```

## Hash

```text
user{name}
```

---

# Hash Manipulation Functions

## `keys`

```text
keys(hash)
```

Returns a list of the hash keys.

Return value:

```text
Array
```

---

# `map`

`map` applies an expression to each element of an array and returns the results as an array.

### Syntax

```text
map(expr, array)
```

### Special Variable

`$_` contains the array element currently being processed.

### Example

```text
map($_ * 2, [1, 2, 3])
```

Result:

```text
[2, 4, 6]
```

---

# Execution Limits

chabo-dsl has execution limits to prevent infinite recursion and excessively long-running programs.

## Recursion Limit

If recursive calls exceed 1000 levels, the following exception is raised:

```text
stack over!
```

## Execution Timeout

If execution takes longer than 5 seconds, an `AST::Timeout` exception is raised.

---

# Variable Names

Variable names support Unicode.

Variable names can contain Unicode letters, numbers, and underscores.

Expected format:

```regex
[\p{L}_][\p{L}\p{N}_]*
```

## Valid Variable Names

```text
foo
_bar
数量
売上2025
```

## Contribution

Bug reports and suggestions are welcome.

## Licence

This software is released under the same terms as Perl itself. See the LICENSE file for details.

## Author

john smith [john.smith.7701@gmail.com](mailto:john.smith.7701@gmail.com)

http://park15.wakwak.com/~k-lovely/cgi-bin/wiki/wiki.cgi

