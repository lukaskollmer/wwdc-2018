import AppKit


extension NSAppearance {
    static let dark = NSAppearance(named: NSAppearance.Name.vibrantDark)!
}

extension String {
    func substring(withRange range: NSRange) -> String {
        return NSString(string: self).substring(with: range)
    }
}

extension CALayer {
    convenience init(backgroundColor color: NSColor) {
        self.init()
        self.backgroundColor = color.cgColor
    }
}

extension NSFont {
    func with(size: CGFloat) -> NSFont {
        return NSFont(name: self.fontName, size: size)!
    }
    
    func with(sizeAdvancedBy amount: CGFloat) -> NSFont {
        return NSFont(name: self.fontName, size: self.pointSize.advanced(by: amount))!
    }
    
    static var monospaced: NSFont = {
        if let url = Bundle.main.url(forResource: "SFMono-Regular", withExtension: "otf"),
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) {
            return NSFont(name: "SFMono-Regular", size: 15)!
        } else {
            return NSFont(name: "Menlo", size: 15)!
        }
    }()
}
