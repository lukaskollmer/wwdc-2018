//LKVisualRegExViewController.show()

/*
 TODO
 - consistent capitalization?
 */

/*:
 # TITLE
 by [Lukas Kollmer](https://lukaskollmer.me) • Spring 2018
 
 ## Table of Contents
 - About this playground
 - What are regular expressions
 - Syntax and usage
 - Character Sets
 - Capture Groups
 - TODO?
 - Exercises
 - TODO?
 
 ## About this playground
 This playground consists of three parts:
 1. this general overview of what regular expressions are and how they work
 2. some regex exercises (and solutions)
 3. a powerful live regex visualizer displayed in the playground's live view
 
 > There is a bug in Xcode where compiling complex playgrounds can fail multiple times in a row, even though the playground's source code doesn't contain any compile-time errors (rdar://38615696).\
If that happens, you have to manually click the "Run" button to trigger a new compilation.\
I'm very sorry about this, but sadly there is nothing I can do to prevent it from happening.
 
 ### About the RegEx type
 The `RegEx` struct is a light wrapper around [`NSRegularExpression`](https://developer.apple.com/documentation/foundation/nsregularexpression) that implements a swift-friendly API and some helper methods, as well as a couple of additional features.\
 The playground also provides an extension on `Array<RegEx.Result>` to display an inline visualization of regex matches. When you get an array of matches, simply access the `preview` property and click the Quick Look icon in the right sidebar to show a little preview of the matches:*/
try! RegEx("hello").matches(in: "hello world").preview // click the Quick Look icon in the right sidebar
/*:
 ### About the live view
 The live view allows you to visualize a regular expression's matches in a given test string.\
 As you type, the entered regex is matched against the entered test string and all matches are highlighted by adding a green background to the matched ranges. The contents of capture groups are highlighted with blue backgrounds.\
 You can hover the mouse over the highlighted areas to get additional infos about that match, like the contents of the individual capture groups.\
 Click the "RegEx Options" button to further specify the regular expression's behaviour.
 
 > If you already know how regular expressions work, I recommend you skip forward to the "Exercises" section
 */
/*:
 ## What are regular expressions
 
 In short, regular expressions (also abbreviated as "regex") are string matching patterns.\
 You can use a regular expression to check whether a string matches a specific pattern, get substrings that match a pattern or extract parts of a match from a string.
 
 Regular expressions consist of "simple" and "special" characters. Simple Characters are matched literally, while special characters (also called metacharacters) convey some meaning as to how the pattern should behave when matching against a string.
 
 ### Simple Characters
 
 - Example:\
**Matching the string "hello" literally**\
As you can see in the Quick Look preview, the following regex simply matches every "o" in the text "Doctor Who"*/
try! RegEx("o").matches(in: "Doctor Who").preview
/*:
 ### Special Characters
 
 - `^` Matches the beginning of the input
 - `$` Matches the end of the input
 - `.` Matches any single character
 - `*` Matches the preceding expression 0 or more times
 - `+` Matches the preceding expression 1 or more times
 - `?` Matches the preceding expression 0 or 1 times
 - `a|b` Matches either `a` or `b`
 - `(x)` Matches `x` and remembers the match. (Explained in depth in the Capture Groups section)
 - `[pattern]` Matches any single character from the pattern. (Explained in depth in the Character Sets section)\
 You can also define character ranges, like `[a-z]` or `[0-9]`
 - `\b` Matches a word boundary
 - `\d` Matches any single digit character. This is equivalent to `[0-9]`
 - `\D` Matches any single non-digit character. This is equivalent to `[^0-9]`
 - `\n` Matches any single newline
 - `\s` Matches any single whitespace character (including, space, tab, newline and some others)
 - `\S` Matches any single non-whitespace character
 - `\t` Matches any single tab character
 - `\w` Matches any single word character (including the underscore). This is equivalent to `[A-Za-z0-9_]`
 - `\W` Matches any single non-word character (including the underscore). This is equivalent to `[^A-Za-z0-9_]`
 
 _(This is by no means an exhaustive list, you can view all metacharacters [here](http://userguide.icu-project.org/strings/regexp#TOC-Regular-Expression-Metacharacters))_
 */
//: - Example:\
//: **Matching all numbers in a string**
try! RegEx("\\d+").matches(in: "abc123xyz").preview
//: ### Character Sets
//:
//: **Syntax**\
//: Character Sets allow you to define a collection of characters, any one of which will match the input. You can also use a set as a shorthand for character ranges.\
//: You define a character set by wrapping an expression in square brackets: `[pattern]`\
//: For example, the pattern `[xyz]` would match all characters in the string "xyz" individually
try! RegEx("[xyz]").matches(in: "xyz").count // as you can see in the sidebar, the pattern produces 3 matches in the string
//: **Character Ranges**\
//: You can also define character ranges. For example, the character set `[a-f]` matches any of the characters a, b, c, d, e and f.\
//: This also works for numbers: `[1-5]` matches any of the digits 1, 2, 3, 4 and 5.
//: - Example:\
//:**Matching all lowercase characters in a string**\
//:As you can see in the Quick Look preview, only "abc" and "xyz" are matched
try! RegEx("[a-z]+").matches(in: "abc123xyz ABC123XYZ").preview
//: **Inverted Character Sets**\
//: You can invert a character set by inserting `^` at the beginning. The set will then match everything, except the characters defined in the set.
//: > The meaning of `^` depends on its context:\
//: • When used outside a character set, it matches the beginning of the input\
//: • When used inside a character set, it inverts the set
//: - Example:\
//:**Matching all non-lowercase characters**\
//:As you can see in the Quick Look preview, only "123", "ABC" and "XYZ" are matched.\
//:Since we match everything that's not a lowercase character, the space between the two words is also matched.
try! RegEx("[^a-z]+").matches(in: "abc123xyz ABC123XYZ").preview
//: ### Capture Groups
//: Capture groups allow you to "remember" parts of a match. This is useful if you want to extract parts of the match from a string\
//:
//: **Syntax**\
//: Create a capture group by wrapping a part of the pattern in parentheses. Prefix the pattern in the parentheses with `?:` to create a non-capturing group\
//:\
//: There are multiple kinds of capture groups:
//: - `(x)` matches `x` and remembers the match
//: - `(?:x)` matches `x` but does not remember the match
//: - `(?<name>x)` matches `x` and remembers the match under the name `name`
//:
//: **Indexed capture groups**\
//: Capture groups are indexed in the order in which they appear in the pattern, starting at 1 (capture group 0 is always the entire match)
//: - Example:\
//:**Extract a person's first name**\
//:The regex below matches two words that are separated by a space. The capture group captures the first word, but excludes everything else.\
//:As you can see in the sidebar, the content of the first capture group is "Lukas".
try! RegEx("(\\w+) \\w+").matches(in: "Lukas Kollmer")[0].contents(ofCaptureGroup: 1)
//: **Named capture groups**\
//: By using the `(?<name>x)` syntax, you can give a capture group a name:
try! RegEx("(?<first>\\w+) \\w+").matches(in: "Lukas Kollmer")[0].contents(ofCaptureGroup: "first")
//: **Template substitution**\
//: Capture groups are also useful when using regular expressions for template substitution.\
//: You can refer to the capture group's contents by the group's index or name.
//: - Example:\
//:**Replacing a person's first name**\
//:In both examples below the regex remembers the last name and inserts it into the template string.
try! RegEx("\\w+ (\\w+)")       .replace(in: "Lukas Kollmer", withTemplate: "Lucas $1")
try! RegEx("\\w+ (?<last>\\w+)").replace(in: "Lukas Kollmer", withTemplate: "Lucas ${last}")























//: ## Exercises
//:
//: ### Character set exercises
//:
//: - Callout(Exercise): **Matching uppercase characters**\
//:Create a regular expression that matches all uppercase characters in a string. Use a character set to define uppercase characters
/*:
 - Callout(Solution):\
`[A-Z]`*/
try! RegEx("[A-Z]").matches(in: "I Am The Doctor").preview
/*:
 - Callout(Exercice): **Matching hexadecimal numbers**\
Create a regular expression that checks whether a string is a hexadecimal number.\
Reminder: Hexadecimal numbers consist of the digits 0-9, as well as the letters a-f.\
Here are some numbers you can check your regex against:\
`123`\
`123a`\
`caffbd6e`\
`-aab123fc`\
`12ff6x1`\
`15ffacex`\
(Only the first 4 are valid hexadecimal numbers)
 > **Hints**:\
• Use `^` and `$` to make sure the entire string matches the pattern\
• Don't forget to support negative numbers\
• Be sure to check the "Anchors match lines" option in the live view's "RegEx Options" menu. If enabled, `^` and `$` will match the beginning and end of lines, instead of the beginning and end of the entire text
 */
/*:
 - Callout(Solution):\
`^-?[0-9a-f]+$`\
_(Copy the pattern and sample numbers from above into the live view to see the regex in action)_\
\
**Explanation**:\
• We use `^` and `$` make sure that the entire string matches the pattern\
• We use the `?` operator to match between 0 and 1 minus signs (`-`)\
• We use a character set to specify the valid characters for a hexadecimal number\
• We use the `+` operator to match as many characters as possible*/
/*:
 ### Capture group exercises
 
 - Callout(Exercice): **Extract the return type from a Swift function signature**\
Create a regular expression that matches a swift function signature and captures the return type\
Example of a valid function signature:\
`func foo() -> String`
 > **Hints**:\
• Use character sets to define valid characters for the function name and the return type name\
• Keep in mind that function and typenames can contain both lower- and uppercase characters. You don't have to take numbers into account\
• Don't forget that you have to escape parentheses in your pattern in order to match them literally
 */
/*:
 - Callout(Solution):\
 `func [a-zA-Z]+\(\) -> ([a-zA-Z]+)`\
 \
 **Explanation**:\
 • We use `^` and `$` make sure that the entire string matches the pattern\
 • We use a character set to specify the valid characters for a hexadecimal number\
 • We use the `+` operator to match as many characters as possible
 
 See it in action below:*/
// Click the Quick Look icon in the sidebar to open the preview
// You can see that the regex matched the entire function signature and captured the return type
try! RegEx("func [a-zA-Z]+\\(\\) -> ([a-zA-Z]+)").matches(in: "func foo() -> String").preview


/*
 xcode markup bugs:
 - lists in callout blocks
 - callout block indentation
 - it's way too easy to accidentally delete entire blocks of content in the rendered mode
 */

//print("success")