import Foundation
Playground.currentPage = "Character Sets"
/*:
 [Table of Contents](Table%20of%20Contents) • [Previous page](@previous) • [Next page](@next)
 
 ## Character Sets
 
 TODO what are character sets
 
 ### Syntax
 TODO
 
 */
// Match all lowercase letters
let regex = RegEx(/*[a-z]*/)
regex.matches(in: "aaa")



/*:
 Exercise: Write a regular expression that matches a hexadecimal number (hexadecimal numbers are numbers that contain only the digits 0-9 and the letters a-f)
 */
let hexRegex = RegEx("^[a-f0-9]+$")
hexRegex.matches("12")
hexRegex.matches("12e4ffa")
hexRegex.matches("12e4ffax")
hexRegex.matches("12e4gffa")
