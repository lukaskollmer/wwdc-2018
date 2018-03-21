LKVisualRegExViewController.show()
/*:
 [Table of contents](Table%20of%20Contents) • [Previous page](@previous) • [Next page](@next)

 ## Introduction
 
 [link](#examples)

 ### What are Regular Expressions?
 Regular Expressions are string matching patterns

 Also abbreviated as "regex"

 Regular Expressions are case-sensitive

 A Regular Expression is not limited to a single match in a string. Instead, it returns as many matches as it can find.

 ## Syntax and Usage

 Regular Expressions consist of "simple" and "special" characters: Simple characters are characters that are matched literally, special characters offer you a way to "refine" your pattern and convey some additional information and conditions.

 ### Simple Characters

```
hello
```
This regex matches all occurrences of the pattern `hello`. For example, in the string "hello world", it matches the first 5 characters.



 ### Special Characters

 This might seem a bit overwhelming at a first glance, but chances are you're just going to work with a rather limited subset. We're also going to explore a bunch of them in depth over the next couple of chapters. And there's lots of examples.

 - `^` Matches the beginning of the input
 - `$` Matches the end of the input
 - `.` Matches any single character
 - `*` Matches the preceding expression 0 or more times
 - `+` Matches the preceding expression 1 or more times
 - `?` Matches the preceding expression 0 or 1 times
 - `a|b` Matches either `a` or `b`
 - `(x)` Matches `x` and remembers the match. (Explained in depth in [Capture Groups](Capture%20Groups))
 - `[pattern]` Matches any single character from the pattern. (Explained in depth in [Character Sets](Character%20Sets))

 - `\b` Matches a word boundary
 - `\d` Matches any single digit character. This is equivalent to `[0-9]`
 - `\D` Matches any single non-digit character. This is equivalent to `[^0-9]`
 - `\n` Matches any single newline. You probably already know this one :)
 - `\s` Matches any single whitespace character (including, space, tab, newline and some others)
 - `\S` Matches any single non-whitespace character
 - `\t` Matches any single tab character
 - `\w` Matches any single word character (including the underscore). This is equivalent to `[A-Za-z0-9_]`
 - `\W` Matches any single non-word character (including the underscore). This is equivalent to `[^A-Za-z0-9_]`

 (Not an exhaustive list, you can view all special characters [here][docs-special-characters])


 ## Examples

 **Match beginning of input**
 ```
 ^h
 ```
 Matches the first "h" in "how are you?", but does not match the "h" in "this is so cool!".

 **Match entire string**
 ```
 ^hello world$
 ```
 Matches only strings that are exactly "hello world". Does not match "hello world!", since that has an additional exclamation mark at the end.

 **Matching an expression a variable number of times**
 ```
 colou?r
 ```
 This pattern matches both the british and the american spelling of the word "color" (or "colour", depending on where you grew up :)

 **Matching an expression one or more times**
 ```
 thank you!+
 ```
 This regex matches both "thank you!" and "thank you!!!!!", as well as all other permutations with a different number of exclamation marks.

 **Matching any single character**
 ```
 .ow
 ```
 Matches both "cow" and "how", as well as "low" in "slow".

 **Match one of multiple expressions**
 ```
 lu(k|c)as
 ```
 Matches both "lukas" and "lucas". Note that we have to wrap the option between `k` and `c` in parentheses. If we omit the parentheses, it would match either "luk" or "cas".



 [docs-special-characters]: https://developer.apple.com/documentation/foundation/nsregularexpression?language=objc#1661042
 */
