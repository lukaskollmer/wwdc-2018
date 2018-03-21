LKVisualRegExViewController.show()
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
let regex = try! RegEx("func [a-zA-Z]+\\(\\) -> ([A-Za-z]+)")
let matches = regex.matches(in: "func foo() -> String")
let returnType = matches[0].contents(ofCaptureGroup: 1)
matches.preview // Click the Quick Look button in the right sidebar to view a visualization of the matches
/*:
 ### Template Substitution

 Capture groups are also useful when replacing matches of a regular expression in a string
 Template string that can access via `$X` notation/syntax
 Consider the following example, where we extract a last and first name from a string and bring them in the correct order

 **Example**
 Regex that matches a string, captures a last and first name and reverses it
 */
let nameRegex = try! RegEx("(\\w+), (\\w+)")
nameRegex.replace(in: "Tennant, David", withTemplate: "$2 $1")



let nameRegex2 = try! RegEx("(?<last>\\w+), (?<first>\\w+)")
nameRegex2.replace(in: "Tennant, David", withTemplate: "${first} ${last}")
nameRegex2.replace(in: "Tennant, David", withTemplate: "$2 $1")


