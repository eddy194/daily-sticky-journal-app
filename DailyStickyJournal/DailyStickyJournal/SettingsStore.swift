import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    enum Keys {
        static let templateText = "templateText"
        static let alwaysOnTop = "alwaysOnTop"
        static let showOnAllSpaces = "showOnAllSpaces"
        static let launchAtLogin = "launchAtLogin"
        static let lockPanelPosition = "lockPanelPosition"
        static let windowFrame = "windowFrame"
    }

    private let defaults: UserDefaults

    @Published var templateText: String {
        didSet { defaults.set(templateText, forKey: Keys.templateText) }
    }

    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: Keys.alwaysOnTop) }
    }

    @Published var showOnAllSpaces: Bool {
        didSet { defaults.set(showOnAllSpaces, forKey: Keys.showOnAllSpaces) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var lockPanelPosition: Bool {
        didSet { defaults.set(lockPanelPosition, forKey: Keys.lockPanelPosition) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let defaultTemplate = """
        LSEG:
        •
        •

        KA:
        •
        •

        METRO:
        •
        •

        SMARTX:
        •
        •
        """

        let loaded = defaults.string(forKey: Keys.templateText) ?? defaultTemplate
        self.templateText = Self.normalizeTemplate(loaded)
        self.alwaysOnTop = defaults.object(forKey: Keys.alwaysOnTop) as? Bool ?? true
        self.showOnAllSpaces = defaults.object(forKey: Keys.showOnAllSpaces) as? Bool ?? false
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        self.lockPanelPosition = defaults.object(forKey: Keys.lockPanelPosition) as? Bool ?? false
    }

    private static func normalizeTemplate(_ template: String) -> String {
        // Migrate users who entered literal "\n" sequences instead of real newlines.
        // Only convert if the template doesn't already contain real line breaks.
        if template.contains("\\n"), !template.contains("\n") {
            return template
                .replacingOccurrences(of: "\\r\\n", with: "\n")
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
        }
        return template
    }

    func loadWindowFrame() -> CGRect? {
        guard let raw = defaults.string(forKey: Keys.windowFrame) else { return nil }
        return NSRectFromString(raw)
    }

    func saveWindowFrame(_ frame: CGRect) {
        defaults.set(NSStringFromRect(frame), forKey: Keys.windowFrame)
    }
}
