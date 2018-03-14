/*:
 [Table of contents](Table%20of%20Contents) • [Previous page](@previous) • [Next page](@next)


 ## Introduction

 ### What are Regular Expressions?
 Regular Expressions are string matching patterns
 Also abbreviated as "regex"

 A Regular Expression is not limited to a single match in a string. Instead, it returns as many matches as it can find.

 ## Syntax and Usage

 Regular Expressions consist of "simple" and "special" characters: Simple characters are characters that are matched literally, special characters offer you a way to "refine" your pattern and convey some additional information.

 ### Simple Characters

```
hello
```
This simple regex matches all occurrences of the pattern `hello`. For example, in the string "hello world", it would match the first 5 characters.



 ### Special Characters

 - `^` Matches the beginning of the input. Example: `^h` matches the 'h' in 'how are you', but it does not match the 'h' in 'this is nice'
 - `$` Matches the end of the input. Example: `!$` only matches the very last '!' in 'hey! good to see you!'
 - `.` Matches any single character. Example: `^.` matches the very first character of the input
 - `*` Matches the preceding pattern 0 or more times
 - `+` Matches the preceding pattern 1 or more times
 - `?` Matches the preceding pattern 0 or 1 times
 - `a|b` Matches either `a` or `b`. Example: `how|you` matches both 'how' and 'you' in 'how are you?' // TODO Chapter
 - `(x)` Matches `x` and remembers the match. Explained in depth in [chapter x](TODO LINK)
 - `\d` matches any single digit character


 #### Examples

 **Match**
 ```
 x
 ```


 ## Commom Misconceptions / Mistakes //TODO which one

 There are some easy mistakes to be made working with regular expressions:
 - A Regular Expression matches all occurrences in a string, meaning that if you want a regex to match an entire string, you have to ensure it starts with `^` and ends with `$`. (As mentioned above, `^` matches the beginning of the input string and `$` matches the end of the input string)


 */
