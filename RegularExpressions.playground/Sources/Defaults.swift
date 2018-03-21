import Foundation

public struct Defaults {
    private static let defaults = UserDefaults(suiteName: "me.lukaskollmer.playground.visualregex")! // TODO can we safely unwrap this?
    public static var regex: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    public static var testInput: String {
        get { return defaults.string(forKey: #function) ?? "" }
        set { defaults.set(newValue, forKey: #function) }
    }
    
    public static var regexOptions: NSRegularExpression.Options {
        get {
            let rawValue = defaults.integer(forKey: #function)
            return NSRegularExpression.Options(rawValue: UInt(rawValue))
        }
        set { defaults.set(newValue.rawValue, forKey: #function) }
    }
}
