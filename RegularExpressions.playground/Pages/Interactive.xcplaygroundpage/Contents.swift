//: [Previous](@previous)

import AppKit
import PlaygroundSupport

// It's important we register this as early as possible since playgrounds don't properly
// print error messages for uncaught objc exceptions (rdar://38576713)
NSSetUncaughtExceptionHandler { exc in fatalError(exc.debugDescription) }


/*
 VisualRegEx.swift
 
 This file implements `LKVisualRegExViewController`, a subclass of NSViewController that can be used to visualize a regular expression.
 
 
 Notes:
 - For performance reasons, we always use `Collection.forEach(:_)` instead of `for in` loops
   Why? Xcode visualizes `for in` loops, either by counting the number of iterations or by actually logging all objects.
   This slows down the execution quite dramatically (rdar://38576884)
 
 
 */

/*
 TODO: when clicking the regex text field for the first time, the cursor goes to the beginning of the text field for a fraction of a second, before going to the end of the text field. would be nice if we could fix that
 // TODO have altrnating colors to differentiate between matches that are directly following each other
 
 // IDEA make a regex to filter all swift files in a list of filenames
 */

extension NSFont {
    func withSize(_ size: CGFloat) -> NSFont {
        return NSFont(name: self.fontName, size: size)!
    }
    
    static let menlo = NSFont(name: "Menlo", size: NSFont.systemFontSize)!
}

extension NSAppearance {
    static let dark = NSAppearance(named: NSAppearance.Name.vibrantDark)!
}

extension NSEdgeInsets {
    init(allSides value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: -value)
    }
}

extension NSColor {
    static let fullMatchLightGreen = NSColor(hexString: "#CCE7A5")!
    static let captureGroupBlue = NSColor(hexString: "#85C3FA")!
}

// https://stackoverflow.com/a/25952895/2513803
extension NSImage {
    func tinted(withColor tint: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else { return self }
        tinted.lockFocus()
        tint.set()
        
        let imageRect = NSRect(origin: NSZeroPoint, size: self.size)
        imageRect.fill(using: .sourceAtop)
        
        tinted.unlockFocus()
        return tinted
    }
}


func measure(_ title: String? = nil, _ block: () -> Void) {
    let start = Date()
    
    block()
    
    let end = Date()
    let msg = title != nil ? " \(title!)" : ""
    print("[⏱]\(msg) \(end.timeIntervalSince(start))")
}


class LKFocusAwareTextField: NSTextField {
    
    var didBecomeFirstResponderAction: (() -> Void)?
    
    override func becomeFirstResponder() -> Bool {
        let retval = super.becomeFirstResponder()
        if retval { self.didBecomeFirstResponderAction?() }
        return retval
    }
}


let SIZE = CGRect(x: 0, y: 0, width: 450, height: 600)

// NSView subclass w/ the *correct* coordinate system. UIKit ftw
class LKView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

class LKMatchHighlightView: NSView {
    
    enum Kind {
        case fullMatch
        case capturingGroup
    }
    
    let match: RegEx.Result
    let kind: Kind
    
    init(match: RegEx.Result, frame: NSRect, color: NSColor, kind: Kind) {
        self.kind = kind
        self.match = match
        super.init(frame: frame)
        
        // Setup background color
        self.layer = CALayer()
        self.layer?.backgroundColor = .white
        
        let colorView = NSView()
        colorView.layer = CALayer()
        colorView.layer?.backgroundColor = color.cgColor
        self.addSubview(colorView)
        colorView.edgesToSuperview()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
}


class LKVisualRegExViewController: NSViewController {
    // Title Bar
    let titleLabel = NSTextField(labelWithString: "Title") // "Visual RegEx"
    let subtitleLabel = NSTextField(labelWithString: "by Lukas Kollmer") // TODO make this a link?
    
    
    // Regex Text Field
    let regexTextFieldTitleLabel = NSTextField(labelWithString: "Regular Expression")
    let regexTextField = LKFocusAwareTextField()
    let regexCompilationErrorImageView = NSImageView(image: NSImage(named: .invalidDataFreestandingTemplate)!.tinted(withColor: .red))
    
    // Test String Text View
    let regexTestStringTextViewTitleLabel = NSTextField(labelWithString: "Test Input")
    let regexTestStringTextViewContainingScrollView = NSScrollView()
    let regexTestStringTextView = NSTextView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    // Not actually called, but required bc we override the default initializer
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = NSView(frame: SIZE)
        self.view.layer = CALayer()
        //self.view.layer?.backgroundColor = NSColor(red: 236/255, green: 236/255, blue: 236/255, alpha: 1).cgColor
        self.view.layer?.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.alignment = .center
        
        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 15, weight: NSFont.Weight.light)
        subtitleLabel.alignment = .center
        
        // Regex Entry
        regexTextField.font = NSFont.menlo.withSize(14)
        regexTextField.placeholderString = "Enter regex here..."
        
        // Test String Entry
        regexTestStringTextView.font = NSFont.menlo.withSize(17)
        regexTestStringTextView.isRichText = false
        regexTestStringTextView.backgroundColor = NSColor.clear.withAlphaComponent(0)
        regexTestStringTextView.drawsBackground = true
        regexTestStringTextViewContainingScrollView.backgroundColor = .clear
        
        setupTextView()
        
        // Add all views
        [
            titleLabel,
            subtitleLabel,
            regexTextFieldTitleLabel,
            regexTextField,
            regexTestStringTextViewTitleLabel,
            regexTestStringTextViewContainingScrollView
        ].forEach(self.view.addSubview)
        
        //
        // Auto Layout
        //
        
        let defaultOffset: CGFloat = 12
        let defaultSpacing = defaultOffset - 7 // 5
        
        let fullWidthInsets = NSEdgeInsets(top: 0, left: defaultOffset, bottom: 0, right: -defaultOffset)
        
        // Title Label
        titleLabel.edgesToSuperview(excluding: .bottom, insets: NSEdgeInsets(top: defaultSpacing, left: 0, bottom: 0, right: 0))
        
        // TODO explain what's going on here
        // array of views, with the offset they should have to their superview
        // we start at the 2nd element
        let layout: [(view: NSView, offset: CGFloat)] = [
            (titleLabel, 0),
            (subtitleLabel, defaultSpacing),
            (regexTextFieldTitleLabel, defaultOffset),
            (regexTextField, defaultSpacing),
            (regexTestStringTextViewTitleLabel, defaultOffset),
            (regexTestStringTextViewContainingScrollView, defaultSpacing)
        ]
        
        
        layout.suffix(from: 1).enumerated().forEach { (index: Int, element: (view: NSView, offset: CGFloat)) in
            element.view.topToBottom(of: layout[index].view, offset: element.offset)
            element.view.edgesToSuperview(excluding: [.top, .bottom], insets: fullWidthInsets)
        }
        
        regexTestStringTextViewContainingScrollView.bottomToSuperview(offset: -defaultOffset)
     
        
        
        // Setup the regex compilation error indicator
        
        regexTextField.addSubview(regexCompilationErrorImageView)
        regexCompilationErrorImageView.edgesToSuperview(excluding: [.left], insets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: -5))
        regexCompilationErrorImageView.isHidden = true
        
        
        // Register observers and set default values
        
        regexTextField.delegate = self
        regexTestStringTextView.delegate = self
        
        regexTextField.stringValue = Defaults.regex
        regexTestStringTextView.string = Defaults.testInput
        
        // Hook into the regex text field to detect when it becomes first responder
        // Why is this necessary? When a NSTextField becomes first responder, AppKit adds a new subview (_NSKeyboardFocusClipView). We have to make sure that our regex compilation error image view is on top of that other view, so that it remains visible
        regexTextField.didBecomeFirstResponderAction = {
            self.keepCompilationErrorImageViewVisible()
        }
    }
    
    
    private func setupTextView() {
        // TODO for whatever reason, the scroll bar does not appear. (probably bc auto layout)
        
        // This only configures the layout-related attributes of the text view and its containing scroll view
        // Everything else is configured in `viewDidLoad`
        
        let scrollView = self.regexTestStringTextViewContainingScrollView
        let contentSize = scrollView.contentSize
        
        scrollView.borderType = .noBorder
        scrollView.hasVerticalRuler = true
        scrollView.hasHorizontalRuler = false
        scrollView.autoresizingMask = [.width, .height]
        
        let textView = self.regexTestStringTextView
        textView.frame = NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: .max, height: .max)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        
        textView.textContainer?.containerSize = NSSize(width: contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // The delegates don't get called when the text is changed programmatically // TODO how the fuck is that spelled
        updateMatches()
        
        
        
        // Addinf the tracking area to `self.view` instead of the text view means that we also get hover events when the text view isn't first responder
        let trackingArea = NSTrackingArea(rect: self.view.frame, options: [.mouseMoved, .activeAlways], owner: self, userInfo: nil)
        self.view.addTrackingArea(trackingArea)
    }
    
    var matchInfoPopover: NSPopover?
    
    var currentlyHoveredHighlightView: LKMatchHighlightView? {
        didSet {
            // show/hide depending on whether the value is nil
            guard currentlyHoveredHighlightView != oldValue else { return }
            
            if let currentlyHoveredHighlightView = currentlyHoveredHighlightView {
                // show a new highlight view
                
                matchInfoPopover?.performClose(nil)
                matchInfoPopover = nil
                
                let vc = LKMatchInfoViewController(match: currentlyHoveredHighlightView.match)
                matchInfoPopover = NSPopover()
                matchInfoPopover?.appearance = .dark
                matchInfoPopover?.contentViewController = vc
                matchInfoPopover?.behavior = .semitransient
                matchInfoPopover?.show(relativeTo: currentlyHoveredHighlightView.bounds, of: currentlyHoveredHighlightView, preferredEdge: .maxY)
            } else {
                // remove the last highlight view
                matchInfoPopover?.performClose(nil)
                matchInfoPopover = nil
            }
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = self.regexTestStringTextView.convert(event.locationInWindow, from: self.view)
        
        guard let highlightView = self.highlightViews.first(where: { $0.kind == .fullMatch &&  $0.frame.contains(location) }) else {
            // we're hovering over an un-highlighted part of the text view
            currentlyHoveredHighlightView = nil
            return
        }
        
        // we're currently hovering over *some* highlight view
        if highlightView != currentlyHoveredHighlightView {
            currentlyHoveredHighlightView = highlightView
        }
    }
    
    private func keepCompilationErrorImageViewVisible() {
        print(regexTextField.subviews)
        regexTextField.sortSubviews({ a, b, _ -> ComparisonResult in
            if a is NSImageView {
                return ComparisonResult.orderedDescending
            } else {
                return ComparisonResult.orderedAscending
            }
        }, context: nil)
        print(regexTextField.subviews)
    }
    
    
    private func updateMatches() {
        
        
        self.highlightViews.forEach { $0.removeFromSuperview() }
        self.highlightViews.removeAll()
        
        // TODO maybe show some UI to select which optinons should be enabled?
        // TODO are there any other obvious options we should enable for this UI?
        guard let regex = try? RegEx(self.regexTextField.stringValue, options: [.anchorsMatchLines]) else {
            keepCompilationErrorImageViewVisible()
            regexCompilationErrorImageView.isHidden = false
            return
        }
        
        regexCompilationErrorImageView.isHidden = true
        
        let tv = self.regexTestStringTextView
        let sv = self.regexTestStringTextViewContainingScrollView
        
        measure("process matches") {
            regex.matches(in: tv.string).forEach { match in
                // TODO can we safely force-unwrap the text container?
                
                match.enumerateCapturingGroups { index, range, content in
                    tv.layoutManager?.enumerateEnclosingRects(forGlyphRange: range, withinSelectedGlyphRange: match.range, in: tv.textContainer!) { rect, stop in
                        
                        let kind: LKMatchHighlightView.Kind = index == 0 ? .fullMatch : .capturingGroup
                        
                        
                        let color = { () -> NSColor in
                            switch kind {
                            case .fullMatch: return .fullMatchLightGreen
                            case .capturingGroup: return .captureGroupBlue
                            }
                        }()
                        
                        let highlightView = LKMatchHighlightView(match: match, frame: rect, color: color, kind: kind)
                        self.highlightViews.append(highlightView)
                    }
                }
                
            }
        }
        
        measure("insert views") {
            
            // Add the highlight views to the scroll view's view hierarchy
            // This is split up in two parts:
            // We first add all highlight views for full matches, and then all highlight views for capture groups
            // This ensures that the highlight views for capture groups are on top of the highlight views for full
            // matches and we don't have to manually rearrange the view hierarchy
            
            let addViews = { (view: NSView) -> Void in
                // the scroll view's only subview is a NSClipView, which has at least 3 subviews, the last of which is the text view
                sv.subviews.first!.addSubview(view, positioned: .below, relativeTo: tv)
            }
            
            highlightViews
                .filter { $0.kind == .fullMatch }
                .forEach(addViews)
            
            highlightViews
                .filter { $0.kind == .capturingGroup }
                .forEach(addViews)
        }
    }
    
    var highlightViews = [LKMatchHighlightView]()
    
}


extension LKVisualRegExViewController: NSTextFieldDelegate, NSTextViewDelegate {
    
    
    override func controlTextDidChange(_ notification: Notification) {
        guard notification.object as? NSTextField == self.regexTextField else { return }
        Defaults.regex = regexTextField.stringValue
        updateMatches()
    }
    
    func textDidChange(_ notification: Notification) {
        guard notification.object as? NSTextView == self.regexTestStringTextView else { return }
        Defaults.testInput = regexTestStringTextView.string
        updateMatches()
    }
}


extension String {
    func substring(withRange range: NSRange) -> String {
        return NSString.init(string: self).substring(with: range)
    }
}


class LKMatchInfoViewController: NSViewController {
    
    let match: RegEx.Result
    
    init(match: RegEx.Result) {
        self.match = match
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = NSView(frame: .zero)
        self.view.appearance = .dark
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let table = TextTable(numberOfColumns: 3)
        
        match.enumerateCapturingGroups { index, range, content in
            table.addRow(values: "#\(index)", "range: \(range)", "content: '\(content)'")
        }
        
        let content = """
        Match: #\(match.index)
        Range: \(match.range) '\(match.initialString.substring(withRange: match.range))'
        Capture Groups:
        \(table.stringValue)
        """
        
        let label = NSTextField(labelWithString: content)
        label.font = .menlo
        label.isSelectable = true
        
        self.view.addSubview(label)
        label.edgesToSuperview(insets: NSEdgeInsets(allSides: 5)) // This automatically resizes the superview to fit the entire label
    }
}



/// Simple string table generator. Used when displaying match infos
class TextTable {
    let numberOfColumns: Int
    
    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
    }
    
    private var rows = [[String]]()
    
    func addRow(values: String...) {
        precondition(values.count == numberOfColumns, "Attempted to add a row with the wrong numbe of columns (got \(values.count), expected \(numberOfColumns))")
        
        rows.append(values)
    }
    
    
    var stringValue: String {
        var rowStrings = [String](repeating: "", count: rows.count)
        
        (0..<numberOfColumns).forEach { column in
            let columnValues = rows.map { $0[column] }
            let maxLength = columnValues.reduce(0, { max($0, $1.count) })
            
            columnValues.enumerated().forEach { index, columnValue in
                rowStrings[index] += columnValue.padding(toLength: maxLength + 1, withPad: " ", startingAt: 0)
            }
        }
        
        return rowStrings.joined(separator: "\n")
    }
    
}


struct Defaults {
    private static let defaults = UserDefaults(suiteName: "me.lukaskollmer.playground.visualregex")! // TODO can we safely unwrap this?
    static var regex: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    static var testInput: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
}

PlaygroundPage.current.liveView = LKVisualRegExViewController()


//: [Next](@next)

