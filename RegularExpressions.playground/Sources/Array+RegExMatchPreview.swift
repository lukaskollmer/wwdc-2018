import AppKit

extension Array where Element == RegEx.Result {
    /// `Array<RegEx.Result>` extension to provide an inline preview of regex matches
    /// ````
    /// let regex = try! RegEx("[A-Z]+")
    /// regex.matches(in: "abc123xyz").preview
    /// ````
    public var preview: NSView {
        // NOTE: We can't use auto layout in this view because Xcode's inline preview only renders views w/ a fixed layout // TODO file radar
        
        let sv = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 28))
        let tv = LKMatchResultHighlightingTextView(frame: NSRect(x: 0, y: 0, width: sv.contentSize.width, height: sv.contentSize.height))
        tv.font = .monospaced
        tv.backgroundColor = NSColor.clear.withAlphaComponent(0)
        tv.textContainerInset = NSSize(width: 0, height: 5)
        sv.backgroundColor = NSColor.white
        
        if let match = first {
            tv.string = match.initialString
        } else {
            // Collection of empty results.
            // This is a bit problematic: we get the string we were matched against from the first match
            // meaning that if there were 0 matches, we can't get the string we were matched against
            tv.string = "(no matches)"
            tv.textColor = .gray
        }
        
        sv.documentView = tv
        tv.updateHighlights(forMatches: self)
        
        return sv
    }
}
