//: [Previous](@previous)

import AppKit
import PlaygroundSupport

print("HEY")

/*
 TODO: when clicking the regex text field for the first time, the cursor goes to the beginning of the text field for a fraction of a second, before going to the end of the text field. would be nice if we could fix that
 */


let SIZE = CGRect(x: 0, y: 0, width: 450, height: 600)

// NSView subclass w/ the *correct* coordinate system. UIKit ftw
class LKView: NSView {
    override var isFlipped: Bool {
        return true
    }
}


class LKViewController: NSViewController {
    // Title Bar
    let titleLabel = NSTextField(labelWithString: "Visual RegEx") // "Visual RegEx"
    let subtitleLabel = NSTextField(labelWithString: "by Lukas Kollmer")
    
    
    // Regex Text Field
    let regexTextFieldTitleLabel = NSTextField(labelWithString: "Regular Expression")
    let regexTextField = NSTextField()
    
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
        self.view = LKView(frame: SIZE)
        self.view.layer = CALayer()
        //self.view.layer?.backgroundColor = NSColor(red: 236/255, green: 236/255, blue: 236/255, alpha: 1).cgColor
        self.view.layer?.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let font = NSFont(name: "Menlo", size: 14)
        
        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.alignment = .center
        
        // Subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 15, weight: NSFont.Weight.light)
        subtitleLabel.alignment = .center
        
        // Regex Entry
        regexTextField.font = font
        regexTextField.placeholderString = "Enter regex here..."
        
        // Test String Entry
        regexTestStringTextView.font = font
        regexTestStringTextView.backgroundColor = NSColor.lightGray.withAlphaComponent(0.5)
        
        setupTextView()
        
        // Add all views
        // TODO put all of this on a single line?
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
        
        for (index, element) in layout.suffix(from: 1).enumerated() {
            // index is relative to the slice, meaning we can use it to access the previous element
            element.view.topToBottom(of: layout[index].view, offset: element.offset)
            element.view.edgesToSuperview(excluding: [.top, .bottom], insets: fullWidthInsets)
        }
        
        regexTestStringTextViewContainingScrollView.bottomToSuperview(offset: -defaultOffset)
     
        
        // Register observers and set default values
        
        regexTextField.delegate = self
        regexTestStringTextView.delegate = self
        
        regexTextField.stringValue = Defaults.regex
        regexTestStringTextView.string = Defaults.testInput
        
    }
    
    
    private func setupTextView() {
        // TODO for whatever reason, the scroll bar does not appear. (probably bc auto layout)
        
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
        
        
        //let textStorage = NSTextStorage()
        //textStorage.delegate = self.textStorageDelegate
        //textView.layoutManager?.replaceTextStorage(textStorage)
    }
    //private let textStorageDelegate = LKHighlighter()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // The delegates don't get called when the text is changed programmatically // TODO how the fuck is that spelled
        updateMatches()
    }
    
    
    private func updateMatches() {
        
        guard let regex = try? RegEx(self.regexTextField.stringValue) else {
            // todo reset last syntax highlighting
            // TODO show a red triangle when the regex didn't compile successfully
            return
        }
        
        let matches = regex.matches(in: self.regexTestStringTextView.string)
        
        print(matches)
        
        // TODO somehow illustrate the matched substring
        // or show a list of the matches (or both)
    }
}


extension LKViewController: NSTextFieldDelegate, NSTextViewDelegate {
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




class LKHighlighter: NSObject, NSTextStorageDelegate {
    
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        print(#function)
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


PlaygroundPage.current.liveView = LKViewController()


//: [Next](@next)

