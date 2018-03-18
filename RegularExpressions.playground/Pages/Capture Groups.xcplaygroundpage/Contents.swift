import Foundation
Playground.currentPage = "Capture Groups"
/*:
 [Table of Contents](Table%20of%20Contents) • [Previous page](@previous) • [Next page](@next)

 ## Capture Groups

 You can use capture groups to extract a part of the match from the string.

 ### Syntax
 Create a capture group by wrapping a part of the regex in parentheses. Prefix the pattern in the parentheses with `?:` to create a non-capturing group

 - `(x)` matches `x` and remembers the match
 - `(?:x)` matches `x` but does not remember the match

 */
/*:

 ### Indexed Capture Groups
 Capture groups are indexed in the order in which they appear in the regex, starting at 1 (capture group 0 is always the entire match)

 **Example**
 Extract the return type from a function signature
 */
let regex = try! RegEx(/*func [a-zA-Z]+\(\) -> ([A-Za-z]+)*/)
let match = regex.matches(in: "func foo() -> String").first!
let returnType = match.contents(ofCaptureGroup: 1)
/*:
 ### Template Substitution

 Capture groups are also useful when replacing matches of a regular expression in a string
 Template string that can access via `$X` notation/syntax
 Consider the following example, where we extract a last and first name from a string and bring them in the correct order

 **Example**
 Regex that matches a string, captures a last and first name and reverses it
 */
let nameRegex = try! RegEx(/*(\w+), (\w+)*/)
nameRegex.replace(in: "Tennant, David", withTemplate: "$2 $1")


/*:
 ### Named Capture Groups
 You can also name the individual capture groups

 The syntax for this is the following (`GROUP_NAME` being the name of that capture group and `x` being the some pattern you want to match
 ```
 (?<GROUP_NAME>x)
 ```

 > this is a relatively new feature and might not yet be fully supported by all regex implementations

 **Example**
 In the example below, the capture group indexes `1` and `2` are redundant with the capture group names `last` and `first`
 */
let nameRegex2 = try! RegEx(/*(?<last>\w+), (?<first>\w+)*/)
nameRegex2.replace(in: "Tennant, David", withTemplate: "${first} ${last}")
nameRegex2.replace(in: "Tennant, David", withTemplate: "$2 $1")
