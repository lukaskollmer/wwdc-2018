import AppKit


// This would be an excellent use case for conditional conformance
// However, Xcode 9.2 (the latest GM as of March 2018) doesn't yet ship w/ Swift 4.1
extension Array: CustomPlaygroundQuickLookable {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        guard let _self = self as? Array<RegEx.Result> else { return .text(self.description) }
        return .view(preview(forMatches: _self))
    }
}

private func preview(forMatches matches: [RegEx.Result]) -> NSView {
    let sv = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 28))
    let tv = LKMatchResultHighlightingTextView(frame: NSRect(x: 0, y: 0, width: sv.contentSize.width, height: sv.contentSize.height))
    tv.font = .monospaced
    tv.backgroundColor = NSColor.clear.withAlphaComponent(0)
    tv.textContainerInset = NSSize(width: 0, height: 5)
    sv.backgroundColor = NSColor.white
    
    if let match = matches.first {
        tv.string = match.initialString
    } else {
        // Collection of empty results.
        // This is a bit problematic: we get the string we were matched against from the first match
        // meaning that if there were 0 matches, we can't get the string we were matched against
        tv.string = "(no matches)"
        tv.textColor = .gray
    }
    
    sv.documentView = tv
    tv.updateHighlights(forMatches: matches)
    
    return sv
}
