import Foundation

/// How the strip is filled.
public enum BarLook: String { case black, glass }

/// User preferences, persisted in UserDefaults.
public final class BarSettings {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public var enabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    public var roundCorners: Bool {
        get { defaults.object(forKey: "roundCorners") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "roundCorners") }
    }

    public var cornerRadius: Double {
        get { defaults.object(forKey: "cornerRadius") as? Double ?? 8 }
        set { defaults.set(min(max(newValue, 0), Double(BarGeometry.maxCornerRadius)), forKey: "cornerRadius") }
    }

    public var look: BarLook {
        get { (defaults.string(forKey: "look")).flatMap(BarLook.init(rawValue:)) ?? .black }
        set { defaults.set(newValue.rawValue, forKey: "look") }
    }

    /// Strength of the frosted glass, in percent (1...100).
    public var glassIntensity: Double {
        get { defaults.object(forKey: "glassIntensity") as? Double ?? 60 }
        set { defaults.set(min(max(newValue, 1), 100), forKey: "glassIntensity") }
    }

    public var showMenuBarIcon: Bool {
        get { defaults.object(forKey: "showMenuBarIcon") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "showMenuBarIcon") }
    }
}
