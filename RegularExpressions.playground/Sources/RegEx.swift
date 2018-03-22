import Foundation


extension String {
    public var range: NSRange {
        return NSRange(location: 0, length: self.count)
    }

    public func replacing(regularExpression: RegEx, withTemplate template: String) -> String {
        return regularExpression.replace(in: self, withTemplate: template)
    }

    public func split(regularExpression: RegEx) -> [String] {
        return regularExpression.split(self)
    }
}


/// A Regular Expression
public struct RegEx {

    public typealias Options = NSRegularExpression.Options
    public typealias MatchingOptions = NSRegularExpression.MatchingOptions

    /// The Result of evaluating a regular expression against a string
    public struct Result: CustomStringConvertible {
        
        /// The index of the match
        public let index: Int

        /// The range of the match
        public var range: NSRange {
            return result.range
        }

        /// The string within the range of the match
        public var string: String {
            return NSString(string: initialString).substring(with: range)
        }
        
        /// The regular expression this match is a result of
        public let regex: RegEx

        /// The full text the regex was matched against
        public let initialString: String // The string this regex was matched against
        public let result: NSTextCheckingResult


        /// Create a new RegEx.Result from a NSTextCheckingResult object
        ///
        /// - Parameters:
        ///   - result: The result this match represents
        ///   - initialString: The full string the regex was matched against
        init(result: NSTextCheckingResult, initialString: String, index: Int, regex: RegEx) {
            self.result = result
            self.initialString = initialString
            self.index = index
            self.regex = regex
        }


        /// Access the contents of a specific capture group
        public subscript(index: Int) -> String {
            get { return self.contents(ofCaptureGroup: index) }
        }

        /// Access the contents of a specific capture group
        public subscript(name: String) -> String {
            get { return self.contents(ofCaptureGroup: name) }
        }


        /// Access the contents of the capture group w/ a specific index
        /// Passing the index of a non-existent capture group is UB
        public func contents(ofCaptureGroup groupIndex: Int) -> String {
            return NSString(string: initialString).substring(with: self.result.range(at: groupIndex))
        }

        /// Access the contents of the capture group w/ a specific name
        /// Passing the name of a non-existent capture group is UB
        public func contents(ofCaptureGroup groupName: String) -> String {
            return NSString(string: initialString).substring(with: self.result.range(withName: groupName))
        }
        
        /// Get the total number of capture groups
        public var numberOfCaptureGroups: Int {
            return self.result.numberOfRanges
        }
        
        public func range(ofCaptureGroup groupIndex: Int) -> NSRange {
            return self.result.range(at: groupIndex)
        }
        
        /// Enumerate all capture groups
        /// The block takes 3 parameters: groupIndex, groupRange and groupContents
        public func enumerateCaptureGroups(block: (Int, NSRange, String) -> Void) {
            (0..<self.numberOfCaptureGroups).forEach { index in
                block(index, self.range(ofCaptureGroup: index), self.contents(ofCaptureGroup: index))
            }
        }
        
        public var description: String {
            return "<RegEx.Result range=\(NSStringFromRange(range)) string='\(string)'>"
        }
    }


    public let regex: NSRegularExpression
    

    /// Create a new RegEx from a pattern and some options
    ///
    /// - Parameters:
    ///   - pattern: The regular expression's pattern
    ///   - options: Some options
    public init(_ pattern: String, options: RegEx.Options = []) throws {
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
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
        return self.regex.matches(in: string, options: [], range: string.range).enumerated().map {
            return RegEx.Result(result: $1, initialString: string, index: $0, regex: self)
        }
    }
    
    /// Check whether a regular expression matches a string
    public func matches(_ string: String) -> Bool {
        return !self.matches(in: string).isEmpty
    }

    /// String substitution w/ named capture support
    public func replace(in string: String, withTemplate template: String) -> String {
        // Instead of forwarding the `replace` call to -[NSRegularExpression stringByReplacingMatchesInString:options:range:withTemplate:]
        // we implement parts of this ourselves to detect and proprtly handle named capture groups.
        // Why? NSRegularExpression doesn't yet fully support named capture (you can use named groups in the regex and the matches, but template substitution will ignore named groups). See also DTS #686210772 and radar://38426586
        
        typealias Substitution = (groupName: String, beginning: Int, end: Int)
        
        let retval = NSMutableString(string: string)
        
        for match in self.matches(in: string).reversed() {
            let result = NSMutableString(string: self.regex.stringByReplacingMatches(in: string, options: [], range: match.range, withTemplate: template))
            
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
                result.replaceCharacters(in: range, with: match[sub.groupName])
            }
            
            retval.replaceCharacters(in: match.range, with: result as String)
        }
        
        return retval as String
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
    
    /// The names defined in the pattern's named capture groups
    public var namedCaptureGroups: [String] {
        let groupName = "groupName"
        
        // Regular expression that matches a capture group and - if that capture group specifies a name - remembers that name
        let namedGroupsRegex = try! RegEx("(?<!\\\\) (?: \\((?:\\?<(?<\(groupName)>\\w+)>)? .*? \\) )", options: [.allowCommentsAndWhitespace])
        
        return namedGroupsRegex.matches(in: self.regex.pattern)
            .filter { $0.result.range(withName: groupName) != NSRange(location: NSNotFound, length: 0) }
            .map { $0.contents(ofCaptureGroup: groupName) }
    }

}

extension RegEx : ExpressibleByStringLiteral {
    /// Create a regular expression from a string literal
    ///
    /// - Parameter value: A string literal containing the (escaped) pattern of the regular expression
    public init(stringLiteral value: String) {
        try! self.init(value)
    }
}

// MARK: RegEx + Comment Initialization (expreimental) // TODO remove?

public struct Playground {
    /// Name of the current Playground Page
    public static var currentPage = ""

    /// Filepath of the Playground
    public static let directory = "/Users/" + NSUserName() + "/Developer/wwdc-2018/RegularExpressions.playground"
}

extension RegEx {
    public init(line: Int = #line, column: Int = #column) throws {
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
        try self.init(dest! as String)
    }
}
