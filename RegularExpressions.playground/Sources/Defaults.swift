import Foundation

struct Defaults {
    private static let defaults = UserDefaults(suiteName: "me.lukaskollmer.playground.visualregex")!
    
    static var regex: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    static var testInput: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    static var regexOptions: RegEx.Options {
        get {
            let rawValue = defaults.integer(forKey: #function)
            return RegEx.Options(rawValue: UInt(rawValue))
        }
        set { defaults.set(newValue.rawValue, forKey: #function) }
    }
}
