import Foundation

public enum ActionType: String, Codable, CaseIterable {
    case appLauncher
    case mediaControl
    case systemToggle
    case shellScript
    case urlBookmark
}
