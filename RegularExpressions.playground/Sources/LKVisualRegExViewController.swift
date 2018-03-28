import AppKit
import PlaygroundSupport

/*
 LKVisualRegExViewController.swift
 
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


// based on https://stackoverflow.com/a/25952895/2513803
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



private let SIZE = CGRect(x: 0, y: 0, width: 450, height: 600)


/// View Controller to visualize a regular expression and its matches in some test input
public class LKVisualRegExViewController: NSViewController, NSTextViewDelegate {
    
    // Title Bar
    private let titleLabel = NSTextField(labelWithString: "Visual RegEx")
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
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    // Not actually called, but required bc we override the default initializer
    public required init?(coder: NSCoder) { fatalError() }
    
    override public func loadView() {
        self.view = NSView(frame: SIZE)
        self.view.layer = CALayer(backgroundColor: .white)
    }
    
    override public func viewDidLoad() {
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
        regexTextView.isRichText = false
        
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
    
    override public func viewWillAppear() {
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
        // https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html
        
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
    
    override public func mouseMoved(with event: NSEvent) {
        let location = self.regexTestStringTextView.convert(event.locationInWindow, from: self.view)
        self.regexTestStringTextView.didHover(over: location)
    }
    
    public func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        
        if textView == self.regexTextView {
            textView.invalidateIntrinsicContentSize()
            Defaults.regex = textView.string
            updateMatches()
        } else if textView == self.regexTestStringTextView {
            Defaults.testInput = textView.string
            updateMatches()
        }
    }
    
    // prevent newlines in the regex text view
    public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
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
            // remove old highlights from the last pattern
            regexTestStringTextView.removeAllHighlights()
            
            // show an error indicator in the regex text view
            regexCompilationErrorImageView.isHidden = regexTextView.string.isEmpty
            regexCompilationErrorImageView.toolTip = "Error compiling regular expression: \(error.localizedDescription)"
            return
        }
        
        regexTestStringTextView.updateHighlights(forMatches: regex.matches(in: Defaults.testInput))
        
        regexCompilationErrorImageView.isHidden = true
        regexCompilationErrorImageView.toolTip = nil
    }
}


public extension LKVisualRegExViewController {
    static func show() {
        NSSetUncaughtExceptionHandler { exc in fatalError(exc.debugDescription) }
        PlaygroundPage.current.liveView = LKVisualRegExViewController()
    }
}

