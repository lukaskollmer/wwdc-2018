import Foundation
Playground.currentPage = "Character Sets"
/*:
 [Table of Contents](Table%20of%20Contents) • [Previous page](@previous) • [Next page](@next)

 ## Character Sets

 ### Syntax

 Character Sets allow you to define a collection of characters, any one of which will match the input. You can also use them as a shorthand for character ranges.

 You define a character set by wrapping an expression in square brackets: `[pattern]`

 For example, the regex `[xyz]` would match all characters in the string "xyz" individually
 */

/*:
 ### Character Ranges
 You can also define character ranges. For example, the character set `[a-f]` matches any of the characters "a", "b", "c", "d", "e" and "f".

 This also works for numbers: `[1-5]` matches any of the digits "1", "2", "3", "4" and "5".
 */

//: **Example:** match lowercase characters in a string, individually
//: In this example the regex returns a total of 6 matches, one for each lowercase character
let regex0 = try! RegEx("[a-z]")
regex0.matches(in: "abc123xyz").count

//: **Example:** match all lowercase parts of a string
//: Note that this uses the same character set as the example above, the only difference being an additional `+` at the end.
//: As we learned in the [first chapter](TODO LINK), the `+` matches the preceding expression 1 or more times.
//: In this example, the regex matches only two times: "abc" and "xyz"
let regex1 = try! RegEx("[a-z]+")
regex1.matches(in: "abc123xyz").count

//: ### Inverted Character Sets
//: You can invert a character set by inserting a `^` at the beginning. In this context, the `^` does not match the beginning of the input.

//: **Example:**
//: This is the reverse of the previous example: instead of matching all lowercase parts of a string, we match everything that is *not* lowercase
//: The updated regex now matches "123", because that's the only part of the string that doesn't consist of lowercase letters
//: > Try updating the string "abc123xyz" by adding other non-lowercase characters. It will match these new charcters as well.
let regex2 = try! RegEx("[^a-z]+")
regex2.matches(in: "abc123xyz") // TODO make regex matches print something nice if passed to print


/*:
 Exercise: Write a regular expression that matches a hexadecimal number (hexadecimal numbers are numbers that contain only the digits 0-9 and the letters a-f)
 */
let hexRegex = try! RegEx("^[a-f0-9]+$")
hexRegex.matches("12")
hexRegex.matches("12e4ffa")
hexRegex.matches("12e4ffax")
hexRegex.matches("12e4gffa")
