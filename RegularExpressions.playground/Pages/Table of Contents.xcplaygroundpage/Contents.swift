/*:
 # Regular Expressions
 
 By [Lukas Kollmer][Lukas Kollmer] • Spring 2018
 
 ## Table of Contents
 - [Introduction](Introduction)
 - [Capturing Groups](Capturing%20Groups)
 - [Character Sets](Character%20Sets)
 - todo
 
 ## Meta
 - This playground was developed and tested with Xcode 9.2 (Swift 4.0.3) TODO UPDATE
 - The `RegEx` class uses in this playground is a light wrapper around [`NSRegularExpression`][NSRegularExpression] and its related APIs, to make working with regular expressions in swift easier
 
 > Since Swift doesn't support raw string literals (string literals where escape characters are not processed), this playground uses a little hack to keep regular expressions simple and easy to read.
 > The `RegEx` class has two initializers
 - `init(_ pattern: String, options: RegEx.Options = [])` takes a string, in which backslashes need to be escaped)
 - `init(line: Int = #line, column: Int = #column)` this initializer expects a comment between its parenteses. it reads the source code of the calling file and extracts the contents of that comment, which will be used as the regex's pattern. the obvious advantage of this approach is that you don't need to escape any characters in the pattern and can for example write `\w` instead of `\\w`. This makes it a lot easier to understand the patterns, especially for beginners
 
 [Lukas Kollmer]:       https://lukaskollmer.github.io
 [NSRegularExpression]: https://developer.apple.com/documentation/foundation/nsregularexpression
 
 [Next page](@next)
*/

import Foundation

// TODO if we require the playground be run from desktop, we can get the current username at runtime and get rid of this one
Playground.currentPage = "Table of Contents"

let regeximg = RegEx(/*(\d+)x(\d+)*/)
regeximg.matches(in: "44x55, 10x12").forEach { print($0) }

/*
postfix operator ...=>
postfix func ...=><T: Collection>(lhs: T) {
    lhs.forEach { print($0) }
}


/*****     EXAMPLES     *****/

 
 // extract price from text
let priceRegex = RegEx(/*Price: \$(\d+)*/)
priceRegex.matches(in: "Price: $12").first!.contents(ofCapturingGroup: 1)




/// Extract the subdomain from a url

let subdomainRegex = RegEx("(?:https?://)?([^.]+)")
subdomainRegex.matches(in: "http://files.lukaskollmer.me")[0].contents(ofCapturingGroup: 1)
"https://lukas.kollmer.me".replacing(regularExpression: subdomainRegex, withTemplate: "$1 ___")




/// Split a sentence into an array of words

RegEx("\\w+").matches(in: "this is insane")




/// Split a name string into first and last name, and replace with a template string

let firstAndLastNameRegex = RegEx("(\\w+)\\s(\\w+)")
firstAndLastNameRegex.replace(in: "David Tennant", withTemplate: "$2, $1")
"David Tennant".replacing(regularExpression: firstAndLastNameRegex, withTemplate: "$2, $1")

let williamHartnellResult = firstAndLastNameRegex.matches(in: "William Hartnell")[0]
williamHartnellResult[0]
williamHartnellResult[1]
williamHartnellResult[2]




/// Extract the video id from a YouTube link
/// How does this work? We simply match alphanumeric characters, starting at the end of the url

RegEx("\\w+$").matches(in: "https://www.youtube.com/watch?v=DLzxrzFCyOs")[0].string



/// Split an arbitrarily delimited string-array (names) into an array of strings, then reverse the names to [[LAST_NAME, FIRST_NAME]]
let input = "Christopher Eccleston ;David Tennant; Matt Smith ; Peter Capaldi ; Jodie Whittaker"
let names = RegEx("\\s*;\\s*").split(input)
    .map { RegEx("(\\w+)\\s+(\\w+)").replace(in: $0, withTemplate: "$2, $1") }

input.split(regularExpression: "\\s*;\\s*")



/// Extract the first 2 words (a name) and a number from a string, then map these extracted values into a nice array

let sentences = [
    "Jodie Whittaker will be the 13th doctor",
    "Peter Capaldi is the 12th doctor",
    "Matt Smith was the 11th doctor",
    "David Tennant was the 10th doctor",
    "Christoper Eccleston was the 9th doctor",
]

// A regex that saves the first two words of a sentence in its first capturing group
let extractNameRegex = RegEx("^((?:\\S+\\s+){1}\\S+).*")
// A regex that saves the first two words of a sentence in its first capturing group and the first number in its second capturing group
let extractNameAndNumberRegex = RegEx("^((?:\\S+\\s+){1}\\S+).* (\\d+)")

let combinations: [(Int, String)] = sentences.map { s -> (Int, String) in
    let match = extractNameAndNumberRegex.matches(in: s)[0]
    
    let name = match.contents(ofCapturingGroup: 1)
    let number = Int(match.contents(ofCapturingGroup: 2))!
    
    // old code that uses a separate regex to extract the number
    //let name = extractNameRegex.matches(in: s)[0].contents(ofCapturingGroup: 1)
    //let number = Int("\\d+"/.matches(in: s)[0].string)!
    
    return (number, name)
    }.sorted { $0.0 < $1.0 }

combinations...=>





*/

