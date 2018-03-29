import AppKit

private extension NSEdgeInsets {
    init(allSides value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: -value)
    }
}

/// View Controller showing info about a regex match
/// This info includes the matched range, substring, and the info about all capture groups
/// This is the view controller shown in a popover when hovering over match results
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
        
        let groupNames = match.regex.namedCaptureGroups
        let hasGroupNameColumn = !groupNames.isEmpty
        
        var table = LKTextTable(numberOfColumns: hasGroupNameColumn ? 4 : 3)
        
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
