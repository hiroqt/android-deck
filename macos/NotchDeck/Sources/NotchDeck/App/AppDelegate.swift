import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotchWindowController.shared.start()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchDeck")
        }

        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Toggle Notch Deck", action: #selector(toggleDeck), keyEquivalent: "d")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit NotchDeck", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func toggleDeck() {
        let isExpanded = NotchWindowController.shared.panel?.frame.height ?? 0 > 50
        NotchWindowController.shared.setExpanded(!isExpanded)
    }

    @objc private func openPreferences() {
        NotchWindowController.shared.openSettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
