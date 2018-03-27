import AppKit

// Making `RegEx.MatchCollection` adopt `CustomPlaygroundQuickLookable` allows us to show inline visualizations of regex matches
// You can see these visualizations by clicking the Quick Look icon in the right sidebar
// You can also "pin" a preview (by clicking the button right to the Quick Look icon). Pinned previews stay visible and auto-update when the playground reloads
extension RegEx.MatchCollection: CustomPlaygroundQuickLookable {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        
        let sv = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 28))
        let tv = LKMatchResultHighlightingTextView(frame: NSRect(x: 0, y: 0, width: sv.contentSize.width, height: sv.contentSize.height))
        tv.font = .monospaced
        tv.string = self.matchedString
        tv.backgroundColor = NSColor.clear.withAlphaComponent(0)
        tv.textContainerInset = NSSize(width: 0, height: 5)
        
        sv.backgroundColor = NSColor.white
        sv.documentView = tv
        
        tv.updateHighlights(forMatches: self)
        
        return .view(sv)
    }
}
