//: [Previous](@previous)

import AppKit
import PlaygroundSupport

// It's important we register this as early as possible
// Why? playgrounds don't properly print error messages for uncaught objc exceptions (rdar://38576713)
// TODO should we reset regex and test string on crashes?
NSSetUncaughtExceptionHandler { exc in fatalError(exc.debugDescription) }


/*
 VisualRegEx.swift
 
 This file implements `LKVisualRegExViewController`, a subclass of NSViewController that can be used to visualize a regular expression.
 
 
 Notes:
 - For performance reasons, we always use `Collection.forEach(:_)` instead of `for in` loops
   Why? Xcode visualizes `for in` loops, either by counting the number of iterations or by actually logging all objects.
   This slows down the execution quite dramatically (rdar://38576884)
 - i'd love to make the RegEx Options popover detachable, so that it doesn't hide the text view
   and it'd be easier to see how changing individual options affects the regex matches.
   However, detached popovers don't work properly in playgrounds (the arrow doesn't disappear and there are some glitches around the close button) (rdar://38598185)
 
 TODO
 - have altrnating colors to differentiate between matches that are directly following each other
 - add a (i) button to the top right corner that shows some sort or info/about window explaining how this works / what it can do
 - it seems like the left social button isn't quite on the same line as the border of the text view // FIXME
 - the options ui should not appear on top of the text view, that'd make it easier to see how changing the options will influence the matches
 - what about a "replace" feature?
 - add some separator between matches that are directly next to each other (eg /o/ matching against 'foo')
   or give the match highlight views a border on the left and right edge?
   this could also be fixed by having alternating colors for individual matches
 
 IDEAS:
 - make a regex to filter all swift files in a list of filenames
 */



private extension NSFont {
    func with(size: CGFloat) -> NSFont {
        return NSFont(name: self.fontName, size: size)!
    }
    
    func with(sizeAdvancedBy amount: CGFloat) -> NSFont {
        return NSFont(name: self.fontName, size: self.pointSize.advanced(by: amount))!
    }
    
    static var monospaced: NSFont = {
        if let url = Bundle.main.url(forResource: "SFMono-Regular", withExtension: "otf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            return NSFont(name: "SFMono-Regular", size: 15)!
        } else {
            return NSFont(name: "Menlo", size: 15)!
        }
    }()
}

private extension NSAppearance {
    static let dark = NSAppearance(named: NSAppearance.Name.vibrantDark)!
}

private extension NSEdgeInsets {
    init(allSides value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: -value)
    }
}

private extension NSRect {
    func offset(by size: NSSize) -> NSRect {
        return self.offsetBy(dx: size.width, dy: size.height)
    }
}

private extension NSColor {
    static let fullMatchLightGreen = NSColor(hexString: "#CCE7A5")!
    static let captureGroupBlue = NSColor(hexString: "#85C3FA")!
}

// https://stackoverflow.com/a/25952895/2513803
private extension NSImage {
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

private extension NSTextView {
    @available(*, deprecated, message: "thefuck you're doing?")
    var lk_placeholderString: String? {
        get { return self.perform(NSSelectorFromString("placeholderString")).takeUnretainedValue() as? String }
        set { self.perform(NSSelectorFromString("setPlaceholderString:"), with: newValue) }
    }
}


private extension String {
    func substring(withRange range: NSRange) -> String {
        return NSString(string: self).substring(with: range)
    }
}

private extension CALayer {
    convenience init(backgroundColor color: NSColor) {
        self.init()
        self.backgroundColor = color.cgColor
    }
}


private func measure(_ title: String, _ block: () -> Void) {
    let start = Date()
    
    block()
    
    let end = Date()
    print("[⏱] '\(title)' - \(end.timeIntervalSince(start))")
}


private let SIZE = CGRect(x: 0, y: 0, width: 450, height: 600)


// Subclasses of NSScrollView and NSTextView to implement an auto-expanding multiline text view

private class LKScrollView: NSScrollView {
    override var intrinsicContentSize: NSSize {
        // TODO guard let the text container as well!
        guard
            let textView = self.documentView as? NSTextView,
            let layoutManager = textView.layoutManager
        else { return .zero }
        
        layoutManager.ensureLayout(for: textView.textContainer!)
        return layoutManager.usedRect(for: textView.textContainer!).size
    }
}


/// Subclass of NSTextView that implements:
/// - the capability to have the text view auto-expand (by overriding `intrinsicContentSize`)
/// - a placeholder string
private class LKTextView: NSTextView {
    
    // Auto Layout stuff
    override var intrinsicContentSize: NSSize {
        guard let manager = textContainer?.layoutManager else { return .zero }
        
        manager.ensureLayout(for: textContainer!)
        return manager.usedRect(for: textContainer!).size
    }
    
    var placeholder: String = "" {
        didSet { self.needsDisplay = true } // tell AppKit to redraw the text view
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if self.string.isEmpty {
            NSString(string: placeholder).draw(at: NSPoint.init(x: 5, y: -5), withAttributes: [
                NSAttributedStringKey.font: self.font!,
                NSAttributedStringKey.foregroundColor: NSColor.gray
            ])
        }
    }
}


/// LKTextView subclass that can highlight the matches of a regular expression
// TODO: Provide extensions for Array<RegEx.Result> that return this view highlighting the matches in the initial string
// That'd allow us to visualize regex matches inline in the playground pages
// something like this: `regex.matches(in: "").preview`
private class LKMatchResultHighlightingTextView: LKTextView {
    
    /// NSView subclass to highlight part of a regex match in a text view
    private class LKMatchHighlightView: NSView {
        
        enum Kind {
            case fullMatch
            case captureGroup
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
    
    func updateHighlights(forMatches matches: [RegEx.Result]) {
        // Remove all old highlights
        self.highlightViews.forEach { $0.removeFromSuperview() }
        self.highlightViews.removeAll()
        
        
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
                    
                    let color = { () -> NSColor in
                        switch kind {
                        case .fullMatch: return .fullMatchLightGreen
                        case .captureGroup: return .captureGroupBlue
                        }
                    }()
                    
                    let frame = rect.offset(by: self.textContainerInset)
                    
                    self.highlightViews.append(LKMatchHighlightView(match: match, frame: frame, color: color, kind: kind))
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



/// View Controller to visualize a regular expression and its matches in some test input
class LKVisualRegExViewController: NSViewController, NSTextViewDelegate {
    
    // Title Bar
    private let titleLabel = NSTextField(labelWithString: "Title") // "Visual RegEx"
    private let subtitleLabel = NSTextField(labelWithString: "by Lukas Kollmer")
    
    
    // Regex Text Field
    private let regexTextFieldTitleLabel = NSTextField(labelWithString: "Regular Expression")
    private let regexTextView = LKTextView()
    private let regexTextViewContainingScrollView = LKScrollView()
    private let regexCompilationErrorImageView = NSImageView(image: NSImage(named: .invalidDataFreestandingTemplate)!.tinted(withColor: .red))
    
    // Test String Text View
    private let regexTestStringTextViewTitleLabel = NSTextField(labelWithString: "Test Input")
    private let regexTestStringTextViewContainingScrollView = NSScrollView()
    private let regexTestStringTextView = LKMatchResultHighlightingTextView()
    
    // Settings
    private let regexOptionsButton = NSButton(title: "RegEx Options", target: nil, action: nil)
    
    // Social Row
    private let leftSocialButton  = NSButton(title: "lukaskollmer.me", target: nil, action: nil)
    private let rightSocialButton = NSButton(title: "github.com/lukaskollmer", target: nil, action: nil)
    
    
    // MARK: View Controller lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    // Not actually called, but required bc we override the default initializer
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = NSView(frame: SIZE)
        self.view.layer = CALayer(backgroundColor: .white)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.alignment = .center
        
        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 15, weight: .light)
        subtitleLabel.alignment = .center
        
        // Regex Entry
        regexTextView.font = .monospaced
        regexTextView.placeholder = "Enter a regular expression"
        
        // Test String Entry
        regexTestStringTextView.font = .monospaced
        regexTestStringTextView.placeholder = "Enter some test input"
        regexTestStringTextView.isRichText = false
        regexTestStringTextView.backgroundColor = NSColor.clear.withAlphaComponent(0)
        regexTestStringTextView.drawsBackground = true
        regexTestStringTextViewContainingScrollView.backgroundColor = .clear
        
        
        // Regex / test string title labels
        [self.regexTextFieldTitleLabel, self.regexTestStringTextViewTitleLabel].forEach {
            $0.font = NSFont.systemFont(ofSize: 13.5, weight: NSFont.Weight.medium)
        }
        
        setupTextView(regexTestStringTextView, inScrollView: regexTestStringTextViewContainingScrollView)
        
        regexTextView.translatesAutoresizingMaskIntoConstraints = false
        regexTextViewContainingScrollView.documentView = regexTextView
        
        // Add all views
        [
            titleLabel,
            subtitleLabel,
            regexTextFieldTitleLabel,
            regexTextViewContainingScrollView,
            regexTestStringTextViewTitleLabel,
            regexTestStringTextViewContainingScrollView,
            regexOptionsButton,
            leftSocialButton, rightSocialButton
        ].forEach(self.view.addSubview)
        
        //
        // Auto Layout
        //
        
        let defaultOffset: CGFloat = 12
        let defaultSpacing = defaultOffset - 7 // 5
        
        let fullWidthInsets = NSEdgeInsets(top: 0, left: defaultOffset, bottom: 0, right: -defaultOffset)
        
        // Title Label
        titleLabel.edgesToSuperview(excluding: .bottom, insets: NSEdgeInsets(top: defaultSpacing, left: 0, bottom: 0, right: 0))
        
        // What's going on here?
        // We create auto layout constraints for all views in the array below, stacking them up on top of each other
        // We start at the second entry and attach each view to the bottom of the view in the previous element in the array
        // The second value specifies the offset a view should have to the one it's being attached to
        let layout: [(view: NSView, offset: CGFloat)] = [
            (titleLabel, 0),
            (subtitleLabel, defaultSpacing),
            (regexTextFieldTitleLabel, defaultOffset),
            (regexTextViewContainingScrollView, defaultSpacing),
            (regexTestStringTextViewTitleLabel, defaultOffset),
            (regexTestStringTextViewContainingScrollView, defaultSpacing)
        ]
        layout.suffix(from: 1).enumerated().forEach { (index: Int, element: (view: NSView, offset: CGFloat)) in
            element.view.topToBottom(of: layout[index].view, offset: element.offset)
            element.view.edgesToSuperview(excluding: [.top, .bottom], insets: fullWidthInsets)
        }
        
        regexTextViewContainingScrollView.borderType = .bezelBorder
        
        // Disable all scrolling in the regex text view. the goal is to make this seem like it is a multiline text field
        regexTextViewContainingScrollView.hasHorizontalScroller = false
        regexTextViewContainingScrollView.hasVerticalScroller = false
        regexTextViewContainingScrollView.verticalScrollElasticity = .none
        regexTextViewContainingScrollView.horizontalScrollElasticity = .none
        
        // Make sure that the regex text view pushes down the other views when it expands
        regexTextViewContainingScrollView.setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
        
        // Make sure the regex text view's containing scroll view resizes when the regex tezt view's dimensions change
        regexTextViewContainingScrollView.height(to: regexTextView, offset: 2)
        regexTextViewContainingScrollView.width(to: regexTextView, offset: 2)
        
        
        // Settings
        regexOptionsButton.topToBottom(of: regexTextViewContainingScrollView, offset: 6)
        regexOptionsButton.rightToSuperview(offset: defaultOffset)
        regexOptionsButton.target = self
        regexOptionsButton.action = #selector(showOptions(_:))
        
        
        // Setup the social row
        
        [leftSocialButton, rightSocialButton].forEach {
            $0.target = self
            $0.action = #selector(didPressSocialButton(_:))
            
            $0.isBordered = false
            
            let title = NSMutableAttributedString(string: $0.title)
            let attributes: [NSAttributedStringKey: Any] = [
                .foregroundColor: NSColor.darkGray,
                .font: NSFont.systemFont(ofSize: 12)
            ]
            title.setAttributes(attributes, range: NSRange(location: 0, length: title.length))
            $0.attributedTitle = title
            $0.height(20)
            
            $0.bottomToSuperview(offset: -defaultSpacing / 2)
            $0.topToBottom(of: regexTestStringTextViewContainingScrollView, offset: defaultSpacing / 2)
        }
        
        leftSocialButton.leftToSuperview(offset: defaultOffset)
        rightSocialButton.rightToSuperview(offset: defaultOffset)
        
        
        // Setup the regex compilation error indicator
        regexTextView.addSubview(regexCompilationErrorImageView)
        regexCompilationErrorImageView.edgesToSuperview(excluding: [.left], insets: NSEdgeInsets(top: 0, left: 0, bottom: 0, right: -5))
        regexCompilationErrorImageView.isHidden = true
        
        
        // Register observers and set default values
        
        regexTextView.delegate = self
        regexTestStringTextView.delegate = self
        
        regexTextView.string = Defaults.regex
        regexTestStringTextView.string = Defaults.testInput
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Ensure that the text is laid out properly
        // If we omit this call, long regular expressions that wrap over multiple lines won't appear as expected
        // (The scroll view doesn't resize and only shows the first line of the pattern)
        regexTextViewContainingScrollView.invalidateIntrinsicContentSize()
    
        // We have to manually start the initial regex matching
        updateMatches()
        
        // Adding the tracking area to `self.view` instead of the text view means that we also get hover events when the text view isn't first responder
        let trackingArea = NSTrackingArea(rect: self.view.frame, options: [.mouseMoved, .activeAlways], owner: self, userInfo: nil)
        self.view.addTrackingArea(trackingArea)
    }
    
    
    // MARK: UI
    
    private func setupTextView(_ textView: NSTextView, inScrollView scrollView: NSScrollView) {
        // TODO for whatever reason, the scroll bar does not appear. (probably bc auto layout)
        // TODO how much of this can we get rid of before it stops working? surely not all of this is actually needed, right?
        
        // This only configures the layout-related attributes of the text view and its containing scroll view
        // Everything else is configured in `viewDidLoad`
        
        let contentSize = scrollView.contentSize
        
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalRuler = true
        scrollView.hasHorizontalRuler = false
        scrollView.autoresizingMask = [.width, .height]
        
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
    
    
    // MARK: Event handling (social buttons, mouse hover, NSTextViewDelegate)
    
    @objc private func didPressSocialButton(_ sender: NSButton) {
        let url = URL(string: "https://" + sender.title)!
        NSWorkspace.shared.open(url)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = self.regexTestStringTextView.convert(event.locationInWindow, from: self.view)
        self.regexTestStringTextView.didHover(over: location)
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        
        if textView == self.regexTextView {
            // https://stackoverflow.com/a/44062950/2513803
            textView.invalidateIntrinsicContentSize()
            Defaults.regex = textView.string
            updateMatches()
        } else if textView == self.regexTestStringTextView {
            Defaults.testInput = textView.string
            updateMatches()
        }
    }
    
    // prevent newlines in the regex text view
    // TODO is this really necessary? what if whitespaces are expliciely allowed?
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        return textView == self.regexTextView && replacementString == "\n" ? false : true
    }
    
    lazy var optionsPopover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = LKOptionsViewController(changeHandler: self.updateMatches)
        popover.behavior = .semitransient
        popover.appearance = NSAppearance(named: .vibrantLight)
        return popover
    }()
    
    @objc private func showOptions(_ sender: NSButton) {
        if optionsPopover.isShown {
            optionsPopover.close()
        } else {
            optionsPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
        }
    }
    
    
    // MARK: Regex Matching
    
    private func updateMatches() {
        
        let regex: RegEx
        do {
            regex = try RegEx(Defaults.regex, options: Defaults.regexOptions)
        } catch {
            regexCompilationErrorImageView.isHidden = regexTextView.string.isEmpty
            regexCompilationErrorImageView.toolTip = "Error compiling regular expression: \(error.localizedDescription)"
            return
        }
        
        self.regexTestStringTextView.updateHighlights(forMatches: regex.matches(in: self.regexTestStringTextView.string))
        
        regexCompilationErrorImageView.isHidden = true
        regexCompilationErrorImageView.toolTip = nil
    }
}


private class LKMatchInfoViewController: NSViewController {
    
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
        
        let groupNames = match.regex.namedCaptureGroups
        let hasGroupNameColumn = !groupNames.isEmpty
        
        var table = TextTable(numberOfColumns: hasGroupNameColumn ? 4 : 3)
        
        match.enumerateCaptureGroups { index, range, content in
            var groupName: String?
            
            groupNames.forEach { name in
                if match.result.range(withName: name) == range {
                    groupName = "{\(name)}"
                }
            }
            
            var columns = ["#\(index)", "range: \(range)", "content: '\(content)'"]
            
            if hasGroupNameColumn {
                columns.insert(groupName ?? "", at: 2)
            }
            
            table.addRow(values: columns)
        }
        
        let content = """
        Match: #\(match.index)
        Range: \(match.range) '\(match.initialString.substring(withRange: match.range))'
        Capture Groups:
        \(table.stringValue)
        """
        
        let label = NSTextField(labelWithString: content)
        label.font = NSFont.monospaced.with(sizeAdvancedBy: -2)
        label.isSelectable = true
        
        self.view.addSubview(label)
        label.edgesToSuperview(insets: NSEdgeInsets(allSides: 5)) // This automatically resizes the superview to fit the entire label
    }
}


private class LKOptionsViewController: NSViewController {
    
    let changeHandler: () -> Void
    
    init(changeHandler: @escaping () -> Void) {
        self.changeHandler = changeHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = NSView(frame: NSRect.init(x: 0, y: 0, width: 400, height: 0))
        
        let container = NSView()
        view.addSubview(container)
        
        container.edgesToSuperview(insets: NSEdgeInsets(top: 12, left: 8, bottom: 8, right: -8))
        
        
        let buttons: [NSButton] = NSRegularExpression.Options.all.map { option in
            let button = NSButton()
            button.setButtonType(.switch)
            button.attributedTitle = option.fancyDescription
            button.target = self
            button.action = #selector(optionsChanged(_:))
            button.tag = Int(option.rawValue)
            button.state = Defaults.regexOptions.contains(option) ? .on : .off
            return button
        }
        
        buttons.forEach(container.addSubview)
        container.stack(buttons, axis: .vertical, spacing: 12.5)
        
        // For some reason the first button is a couple of pixels out of view
        // We correct this by fixing its size to 30 points (fun fact: the button's size is 30pt anyway
        // but explicitly telling AppKit to render it w/ 30 points height seems to fix the bug)
        buttons.first!.height(30)
    }
    
    @objc private func optionsChanged(_ sender: NSButton) {
        let option = NSRegularExpression.Options(rawValue: UInt(sender.tag))
        
        if sender.state == .on {
            Defaults.regexOptions.insert(option)
        } else {
            Defaults.regexOptions.remove(option)
        }
        
        changeHandler()
    }
}

extension NSRegularExpression.Options {
    fileprivate static let all: [NSRegularExpression.Options] = [
        .caseInsensitive,
        .allowCommentsAndWhitespace,
        .ignoreMetacharacters,
        .dotMatchesLineSeparators,
        .anchorsMatchLines,
        .useUnixLineSeparators,
        .useUnicodeWordBoundaries
    ]
    
    fileprivate var fancyDescription: NSAttributedString {
        switch self {
        case .caseInsensitive:
            return makeAttributedString(
                title: "Case-insensitive",
                subtitle: "Match letters in the pattern independent of case"
            )
        case .allowCommentsAndWhitespace:
            return makeAttributedString(
                title: "Allow comments and whitespace",
                subtitle: "Ignore whitespace and #-prefixed comments in the pattern"
            )
        case .ignoreMetacharacters:
            return makeAttributedString(
                title: "Ignore metacharacters",
                subtitle: "Treat the entire pattern as a literal string"
            )
        case .dotMatchesLineSeparators:
            return makeAttributedString(
                title: "Dot matches line separators",
                subtitle: "Allow . to match any character, including line separators"
            )
        case .anchorsMatchLines:
            return makeAttributedString(
                title: "Anchors match lines",
                subtitle: "Allow ^ and $ to match the start and end of lines"
            )
        case .useUnixLineSeparators:
            return makeAttributedString(
                title: "Use unix line separators",
                subtitle: "Treat only \\n as a line separator"
            )
        case .useUnicodeWordBoundaries:
            return makeAttributedString(
                title: "Use unicode word boundaries",
                subtitle: "Use Unicode TR#29 to specify word boundaries"
            )
        default:
            // should never reach here
            fatalError()
        }
    }
    
    private func makeAttributedString(title: String, subtitle: String) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        let attributedTitle = NSAttributedString(string: title)
        let attributedSubtitle = NSAttributedString(string: subtitle, attributes: [
            .foregroundColor: NSColor.darkGray
        ])
        
        string.append(attributedTitle)
        string.append(NSAttributedString(string: "\n"))
        string.append(attributedSubtitle)
        
        return string.copy() as! NSAttributedString
    }
}


/// Simple string table generator. Used when displaying match infos
private struct TextTable {
    let numberOfColumns: Int
    private var rows = [[String]]()
    
    init(numberOfColumns: Int) {
        self.numberOfColumns = numberOfColumns
    }
    
    mutating func addRow(values: [String]) {
        precondition(values.count == numberOfColumns, "Attempted to add a row with the wrong numbe of columns (got \(values.count), expected \(numberOfColumns))")
        rows.append(values)
    }
    
    var stringValue: String {
        var rowStrings = [String](repeating: "", count: rows.count)
        
        (0..<numberOfColumns).forEach { column in
            let columnValues = rows.map { $0[column] }
            let maxLength = columnValues.reduce(0) { max($0, $1.count) }
            
            columnValues.enumerated().forEach { index, columnValue in
                rowStrings[index] += columnValue.padding(toLength: maxLength + 1, withPad: " ", startingAt: 0)
            }
        }
        return rowStrings.joined(separator: "\n")
    }
}


private struct Defaults {
    private static let defaults = UserDefaults(suiteName: "me.lukaskollmer.playground.visualregex")! // TODO can we safely unwrap this?
    static var regex: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    static var testInput: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    static var regexOptions: NSRegularExpression.Options {
        get {
            let rawValue = defaults.integer(forKey: #function)
            return NSRegularExpression.Options(rawValue: UInt(rawValue))
        }
        set { defaults.set(newValue.rawValue, forKey: #function) }
    }
}

PlaygroundPage.current.liveView = LKVisualRegExViewController()


extension Array where Element == RegEx.Result {
    /// `Array<RegEx.Result>` extension to provide an inline preview of regex matches
    /// ````
    /// let regex = try! RegEx("[A-Z]+")
    /// regex.matches(in: "abc123xyz").preview
    /// ````
    var preview: NSView {
        let sv = NSScrollView(frame: .init(x: 0, y: 0, width: 300, height: 100))
        
        let tv = LKMatchResultHighlightingTextView(frame: NSRect(x: 0, y: 0, width: sv.contentSize.width, height: sv.contentSize.height))
        tv.font = .monospaced
        tv.backgroundColor = NSColor.clear.withAlphaComponent(0)
        tv.textContainerInset = NSSize(width: 5, height: 5)
        
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


try! RegEx("[a-z]+").matches(in: "abc123xyz").preview



//: [Next](@next)

