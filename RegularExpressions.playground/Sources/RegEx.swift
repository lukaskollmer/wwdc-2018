import Foundation

postfix operator /
public postfix func /(pattern: String) -> RegEx {
    return RegEx(pattern)
}


extension String {
    var range: NSRange {
        return NSRange(location: 0, length: self.count)
    }

    public func replacing(regularExpression: RegEx, withTemplate template: String) -> String {
        return regularExpression.replace(in: self, withTemplate: template)
    }

    public func split(regularExpression: RegEx) -> [String] {
        return regularExpression.split(self)
    }
}

// TODO make this a class
/// A Regular Expression
public struct RegEx {

    public typealias Options = NSRegularExpression.Options
    public typealias MatchingOptions = NSRegularExpression.MatchingOptions

    /// The Result of evaluating a regular expression against a string
    public struct Result: CustomStringConvertible {

        /// The range of the match
        public var range: NSRange {
            return result.range
        }

        /// The string within the range of the match
        public var string: String {
            return NSString(string: initialString).substring(with: range)
        }

        /// The regular expression this match is the result of
        public var regex: RegEx {
            return RegEx(result.regularExpression!)
        }

        public var description: String {
            return "<RegEx.Result range=\(NSStringFromRange(range)) string='\(string)'>"
        }

        /// The full text the regex was matched against
        public let initialString: String // The string this regex was matched against
        public let result: NSTextCheckingResult


        /// Create a new RegEx.Result from a NSTextCheckingResult object
        ///
        /// - Parameters:
        ///   - result: The result this match represents
        ///   - initialString: The full string the regex was matched against
        init(result: NSTextCheckingResult, initialString: String) {
            self.result = result
            self.initialString = initialString
        }


        /// Access the value of a specific capture group
        /// eg, `result[1]` returns the value of the first capture group
        ///
        /// - Parameter key: A capture group index
        public subscript(index: Int) -> String {
            get {
                return self.contents(ofCapturingGroup: index)
            }
        }

        public subscript(name: String) -> String {
            get {
                return self.contents(ofCapturingGroup: name)
            }
        }


        /// Access the value of a specific capture group
        ///
        /// - Parameter group: The index of the capturing group
        /// - Returns: The value/contents of the capturing group
        public func contents(ofCapturingGroup groupIndex: Int) -> String {
            return NSString(string: initialString).substring(with: self.result.range(at: groupIndex))
        }

        public func contents(ofCapturingGroup groupName: String) -> String {
            return NSString(string: initialString).substring(with: self.result.range(withName: groupName))
        }
    }


    public let regex: NSRegularExpression

    /// Create a new RegEx from a pattern and some options
    ///
    /// - Parameters:
    ///   - pattern: The regular expression's pattern
    ///   - options: Some options
    public init(_ pattern: String, options: RegEx.Options = []) {
        self.regex = try! NSRegularExpression(pattern: pattern, options: options)
    }

    /// Create a new RegEx object from a NSRegularExpression objecr
    ///
    /// - Parameter regularExpression: A NSRegularExpression object
    public init(_ regularExpression: NSRegularExpression) {
        self.regex = regularExpression
    }

    /// Match a regular expression against a string
    ///
    /// - Parameters:
    ///   - string: The string to match againsr
    ///   - options: Matching options
    /// - Returns: An array of matches
    public func matches(in string: String) -> [RegEx.Result] {
        return self.regex.matches(in: string, options: [], range: string.range).map { result in
            return RegEx.Result(result: result, initialString: string)
        }
    }
    
    public func matches(_ string: String) -> Bool {
        return !self.matches(in: string).isEmpty
    }

    /// String substitution w/ named capture support
    public func replace(in string: String, withTemplate template: String) -> String {
        // Instead of forwarding the `replace` call to -[NSRegularExpression stringByReplacingMatchesInString:options:range:withTemplate:]
        // we implement parts of this ourselves to detect named capture groups and properly handle them.
        // NSRegularExpression doesn't yet fully support named capture (you can use named groups in the regex and the matches, but template substitution will ignore named groups). See also DTS #686210772 and radar #38426586

        typealias Substitution = (groupName: String, beginning: Int, end: Int)

        var string_ = NSString(string: string)

        for match in self.matches(in: string).reversed() {
            var result = NSString(string: self.regex.stringByReplacingMatches(in: string, options: [], range: match.range, withTemplate: template))

            var substitutions = [Substitution]()

            var lastPosition = 0
            while lastPosition <= result.length {
                let scanner = Scanner(string: result as String)

                scanner.scanLocation = lastPosition
                scanner.scanUpTo("${", into: nil)

                if scanner.isAtEnd {
                    break
                }

                let startIndex = scanner.scanLocation
                scanner.scanLocation += 2

                var groupName: NSString?
                scanner.scanUpTo("}", into: &groupName)
                lastPosition = scanner.scanLocation

                if let name = groupName as String? {
                    substitutions.append((name, startIndex, lastPosition + 1))
                }
            }

            for sub in substitutions.reversed() {
                let range = NSRange(location: sub.beginning, length: sub.end - sub.beginning)
                result = result.replacingCharacters(in: range, with: match[sub.groupName]) as NSString
            }

            string_ = string_.replacingCharacters(in: match.range, with: result as String) as NSString
        }

        return string_ as String


    }

    public func split(_ string: String) -> [String] {
        let _string = NSString(string: string)

        var splitComponents: [String] = []
        var lastEnd = 0

        for match in self.matches(in: string) {
            splitComponents.append(_string.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd)))
            lastEnd = match.range.location + match.range.length
        }

        splitComponents.append(_string.substring(with: NSRange(location: lastEnd, length: string.count - lastEnd)))
        return splitComponents
    }

}

extension RegEx : ExpressibleByStringLiteral {
    /// Create a regular expression from a string literal
    ///
    /// - Parameter value: A string literal containing the (escaped) pattern of the regular expression
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

public struct Playground {
    /// Name of the current Playground Page
    public static var currentPage = ""

    /// Filepath of the Playground
    public static let directory = "/Users/" + NSUserName() + "/Developer/wwdc-2018/RegularExpressions.playground"
}

extension RegEx {
    public init(line: Int = #line, column: Int = #column) {
        let path = Playground.directory + "/Pages/" + Playground.currentPage + ".xcplaygroundpage/Contents.swift"

        let data = FileManager.default.contents(atPath: path)!
        let contents = String(data: data, encoding: .utf8)!.components(separatedBy: "\n")
        let lineContents = NSString.init(string: contents[line-1])

        let scanner = Scanner(string: lineContents.substring(from: column))
        scanner.scanLocation += 2 // skip the opening '/*'

        // TODO this only works as long as the regex doesn't contain '*/' (which probably would break all of this anyway)
        var dest: NSString?
        scanner.scanUpTo("*/", into: &dest)

        //value = dest! as String
        self.init(dest! as String)
    }
}
