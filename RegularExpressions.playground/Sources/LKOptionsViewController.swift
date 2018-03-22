import AppKit

public class LKOptionsViewController: NSViewController {
    
    public let changeHandler: () -> Void
    
    public init(changeHandler: @escaping () -> Void) {
        self.changeHandler = changeHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    override public func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 0))
        
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

private extension NSRegularExpression.Options {
    static let all: [NSRegularExpression.Options] = [
        .caseInsensitive,
        .allowCommentsAndWhitespace,
        .ignoreMetacharacters,
        .dotMatchesLineSeparators,
        .anchorsMatchLines,
        .useUnixLineSeparators,
        .useUnicodeWordBoundaries
    ]
    
    var fancyDescription: NSAttributedString {
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
