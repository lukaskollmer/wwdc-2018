import Foundation


private extension String {
    var range: NSRange {
        return NSRange(location: 0, length: self.count)
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
        init(result: NSTextCheckingResult, initialString: String, index: Int, regex: RegEx) {
            self.result = result
            self.initialString = initialString
            self.index = index
            self.regex = regex
        }


        /// Access the contents of a specific capture group
        public subscript(index: Int) -> String {
            get { return contents(ofCaptureGroup: index) }
        }

        /// Access the contents of a specific capture group
        public subscript(name: String) -> String {
            get { return contents(ofCaptureGroup: name) }
        }


        /// Access the contents of the capture group w/ a specific index
        /// Passing the index of a non-existent capture group is UB
        public func contents(ofCaptureGroup groupIndex: Int) -> String {
            return initialString.substring(withRange: range(ofCaptureGroup: groupIndex))
        }

        /// Access the contents of the capture group w/ a specific name
        /// Passing the name of a non-existent capture group is UB
        public func contents(ofCaptureGroup groupName: String) -> String {
            return initialString.substring(withRange: range(ofCaptureGroup: groupName))
        }
        
        /// Get the total number of capture groups
        public var numberOfCaptureGroups: Int {
            return self.result.numberOfRanges
        }
        
        /// Get the range of the group with the specified index
        public func range(ofCaptureGroup groupIndex: Int) -> NSRange {
            return self.result.range(at: groupIndex)
        }
        
        /// Get the range of the group with the specified name
        public func range(ofCaptureGroup groupName: String) -> NSRange {
            return self.result.range(withName: groupName)
        }
        
        /// Enumerate all capture groups
        /// The block takes 3 parameters: groupIndex, groupRange and groupContents
        public func enumerateCaptureGroups(block: (Int, NSRange, String) -> Void) {
            (0..<self.numberOfCaptureGroups).forEach { index in
                guard self.range(ofCaptureGroup: index) != NSRange(location: NSNotFound, length: 0) else { return }
                block(index, self.range(ofCaptureGroup: index), self.contents(ofCaptureGroup: index))
            }
        }
        
        public var description: String {
            return "<RegEx.Result range=\(NSStringFromRange(range)) string='\(string)'>"
        }
    }


    public let regex: NSRegularExpression
    
    /// Create a new RegEx from a pattern and some options
    public init(_ pattern: String, options: RegEx.Options = []) throws {
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }

    /// Create a new RegEx object from a NSRegularExpression object
    public init(_ regularExpression: NSRegularExpression) {
        self.regex = regularExpression
    }

    /// Match a regular expression against a string
    public func matches(in string: String) -> RegEx.MatchCollection {
        let matches = self.regex.matches(in: string, options: [], range: string.range).enumerated().map {
            return RegEx.Result(result: $1, initialString: string, index: $0, regex: self)
        }
        
        return RegEx.MatchCollection(matches: matches, matchedString: string)
    }
    
    /// Check whether a regular expression matches a string
    public func matches(_ string: String) -> Bool {
        return !self.matches(in: string).isEmpty
    }

    /// String substitution w/ named capture support
    public func replace(in string: String, withTemplate template: String) -> String {
        // Instead of forwarding the `replace` call to -[NSRegularExpression stringByReplacingMatchesInString:options:range:withTemplate:]
        // we implement parts of this ourselves to detect and properly handle named capture groups.
        // Why? NSRegularExpression doesn't (yet?) fully support named capture (you can use named groups in the regex and the matches, but template substitution will ignore named groups). See also DTS #686210772 and radar://38426586
        
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
        let pattern = """
        (?<!\\\\)                 # negative lookahead - only match unescaped opening parentheses
        \\(                       # opening parentheses of the group
          (?:
            \\?<                  # start of the group name
            (?<\(groupName)>\\w+) # capture the group name
            >                     # end of the group name
          )?                      # match either 0 or 1 group names
          .*                      # match the rest of the group's contents
        \\)                       # closing parentheses of the group
        """
        let namedGroupsRegex = try! RegEx(pattern, options: .allowCommentsAndWhitespace)
        
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


extension RegEx {
    /// A Collection of regex matches
    ///
    /// Instead of simply returning Array<RegEx.Result>, we return a custom sequence that also stores the string the regex was matched against
    /// This allows us to still get access to the matched string, even if the regex produces 0 matches in the string
    /// Why do we need this? The inline preview (see RegExMatchCollection+CustomPlaygroundQuickLookable.swift) needs to know the string the pattern was matched against, in order to highlight the matches
    /// We could access the string via one of the matches, but that means that we can't get it when there are 0 matches
    public struct MatchCollection: RandomAccessCollection {
        public typealias Element  = RegEx.Result
        public typealias Index    = Int
        public typealias Iterator = IndexingIterator<[Element]>
        
        fileprivate let backing: [Element]
        let matchedString: String
        
        init(matches: [Element], matchedString: String) {
            self.backing = matches
            self.matchedString = matchedString
        }
        
        public func makeIterator() -> RegEx.MatchCollection.Iterator {
            return backing.makeIterator()
        }
        
        public var startIndex: Index { return backing.startIndex }
        public var endIndex: Index { return backing.endIndex }
        
        public func index(after i: Index) -> Index {
            return backing.index(after: i)
        }
        
        public func index(before i: Index) -> Index {
            return backing.index(before: i)
        }
        
        public subscript(position: Index) -> Element {
            return backing[position]
        }
    }
}


// MARK: RegEx + Comment Initialization (experimental, unused)
extension RegEx {
    private static let filepath = "/Users/" + NSUserName() + "/Desktop/RegularExpressions.playground/Contents.swift"

    /// This implements an alternative initializer for the `RegEx` struct.
    /// Instead of passing a string literal (which needs to be escaped), you put a comment between the initializer's opening and closing parentheses
    /// The contents of that comment will be used as the regex's pattern
    /// **Note** for this to work, the playground has to be called "RegularExpressions.playground" and be stored at ~/Desktop
    ///
    /// Example:
    /// `let regex = try! RegEx(/*(\w+)*/)`
    public init(line: Int = #line, column: Int = #column) throws {
        let data = FileManager.default.contents(atPath: RegEx.filepath)!
        let contents = String(data: data, encoding: .utf8)!.components(separatedBy: "\n")
        let lineContents = NSString(string: contents[line-1])

        let scanner = Scanner(string: lineContents.substring(from: column))
        scanner.scanLocation += 2 // skip the opening '/*'

        // TODO this only works as long as the regex doesn't contain '*/' (which probably would break all of this anyway)
        var dest: NSString?
        scanner.scanUpTo("*/", into: &dest)

        //value = dest! as String
        try self.init(dest! as String)
    }
}
