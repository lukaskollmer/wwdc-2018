import AppKit

private extension NSColor {
    static let fullMatchGreen   = NSColor(red: 204/255, green: 231/255, blue: 165/255, alpha: 1)
    static let captureGroupBlue = NSColor(red: 133/255, green: 195/255, blue: 250/255, alpha: 1)
}

private extension NSRect {
    func offset(by size: NSSize) -> NSRect {
        return self.offsetBy(dx: size.width, dy: size.height)
    }
}


/// Subclasses of NSScrollView that implements an auto-expanding multiline text view
class LKScrollView: NSScrollView {
    override var intrinsicContentSize: NSSize {
        guard
            let textView = self.documentView as? NSTextView,
            let textContainer = textView.textContainer,
            let layoutManager = textView.layoutManager
        else { return .zero }
        
        layoutManager.ensureLayout(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size
    }
}


/// Subclass of NSTextView that implements:
/// - the capability to have the text view auto-expand (by overriding `intrinsicContentSize`)
/// - a placeholder string
class LKTextView: NSTextView {
    
    // Auto Layout stuff
    override var intrinsicContentSize: NSSize {
        guard
            let textContainer = self.textContainer,
            let layoutManager = self.layoutManager
        else { return .zero }
        
        layoutManager.ensureLayout(for: textContainer)
        return layoutManager.usedRect(for: textContainer).size
    }
    
    public var placeholder: String = "" {
        didSet { self.needsDisplay = true } // tell AppKit to redraw the text view
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if string.isEmpty && !placeholder.isEmpty {
            NSString(string: placeholder).draw(at: NSPoint(x: 5, y: -5), withAttributes: [
                .font: self.font!,
                .foregroundColor: NSColor.gray
            ])
        }
    }
}


/// LKTextView subclass that can highlight the matches of a regular expression
class LKMatchResultHighlightingTextView: LKTextView {
    
    /// NSView subclass to highlight part of a regex match in a text view
    private class LKMatchHighlightView: NSView {
        
        enum Kind {
            case fullMatch
            case captureGroup
            
            var color: NSColor {
                switch self {
                case .fullMatch:    return .fullMatchGreen
                case .captureGroup: return .captureGroupBlue
                }
            }
        }
        
        let match: RegEx.Result
        let kind: Kind
        
        init(match: RegEx.Result, frame: NSRect, color: NSColor, kind: Kind) {
            self.kind = kind
            self.match = match
            super.init(frame: frame)
            
            // Setup background color
            self.layer = CALayer(backgroundColor: .white)
            
            let colorView = NSView(frame: self.bounds)
            colorView.layer = CALayer(backgroundColor: color)
            self.addSubview(colorView)
        }
        
        required init?(coder decoder: NSCoder) { fatalError() }
    }
    
    // MARK: Match highlighting
    private var highlightViews = [LKMatchHighlightView]()
    private var matchInfoPopover: NSPopover?
    
    private var currentlyHoveredHighlightView: LKMatchHighlightView? {
        didSet {
            // show/hide depending on whether the value is nil
            guard currentlyHoveredHighlightView != oldValue else { return }
            
            if let currentlyHoveredHighlightView = currentlyHoveredHighlightView {
                // show a new highlight view
                
                matchInfoPopover?.performClose(nil)
                matchInfoPopover = nil
                
                matchInfoPopover = NSPopover()
                matchInfoPopover?.appearance = .dark
                matchInfoPopover?.contentViewController = LKMatchInfoViewController(match: currentlyHoveredHighlightView.match)
                matchInfoPopover?.behavior = .semitransient
                matchInfoPopover?.show(relativeTo: currentlyHoveredHighlightView.bounds, of: currentlyHoveredHighlightView, preferredEdge: .maxY)
            } else {
                // remove the last highlight view
                matchInfoPopover?.performClose(nil)
                matchInfoPopover = nil
            }
        }
    }
    
    func removeAllHighlights() {
        self.highlightViews.forEach { $0.removeFromSuperview() }
        self.highlightViews.removeAll()
    }
    
    func updateHighlights(forMatches matches: RegEx.MatchCollection) {
        // Remove all old highlights
        self.removeAllHighlights()
        
        guard
            let sv = self.superview?.superview, // The NSScrollView containing this text view
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer,
            (sv as? NSScrollView)?.documentView == self
        else {
            // The layout manager and the text container are always nonnull
            // This is just about checking that the view hierarchy is correct
            print("unable to get the text view's containing scroll view")
            return
        }
        
        matches.forEach { match in
            match.enumerateCaptureGroups { index, range, content in
                layoutManager.enumerateEnclosingRects(forGlyphRange: range, withinSelectedGlyphRange: match.range, in: textContainer) { rect, stop in
                    let kind: LKMatchHighlightView.Kind = index == 0 ? .fullMatch : .captureGroup
                    let frame = rect.offset(by: self.textContainerInset)
                    
                    self.highlightViews.append(LKMatchHighlightView(match: match, frame: frame, color: kind.color, kind: kind))
                }
            }
        }
        
        
        // Add the highlight views to the scroll view's view hierarchy
        // This is split up in two parts:
        // We first add all highlight views for full matches, and then all highlight views for capture groups
        // This ensures that the highlight views for capture groups are on top of the highlight views for full
        // matches and we don't have to manually rearrange the view hierarchy
        
        let addViews = { (view: NSView) -> Void in
            // the scroll view's only subview is a NSClipView, which has at least 3 subviews, the last of which is the text view
            sv.subviews.first!.addSubview(view, positioned: .below, relativeTo: self)
        }
        
        highlightViews
            .filter { $0.kind == .fullMatch }
            .forEach(addViews)
        
        highlightViews
            .filter { $0.kind == .captureGroup }
            .forEach(addViews)
        
    }
    
    
    func didHover(over point: NSPoint) {
        guard let highlightView = self.highlightViews.first(where: { $0.kind == .fullMatch && $0.frame.contains(point) }) else {
            // we're hovering over an un-highlighted part of the text view
            currentlyHoveredHighlightView = nil
            return
        }
        
        // we're currently hovering over *some* highlight view
        if highlightView != currentlyHoveredHighlightView {
            currentlyHoveredHighlightView = highlightView
        }
    }
}
