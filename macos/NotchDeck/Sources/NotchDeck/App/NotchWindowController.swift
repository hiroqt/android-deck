import AppKit
import SwiftUI

public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()

    public private(set) var panel: NotchPanel?
    public private(set) var settingsWindow: NSWindow?
    public private(set) var editorWindow: NSWindow?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    @Published public private(set) var isExpanded: Bool = false

    private struct RootWrapperView: View {
        @ObservedObject var controller: NotchWindowController
        let hasPhysicalNotch: Bool

        var body: some View {
            NotchDeckRootView(
                isExpanded: Binding(
                    get: { controller.isExpanded },
                    set: { controller.setExpanded($0) }
                ),
                hasPhysicalNotch: hasPhysicalNotch,
                onOpenSettings: { [weak controller] in controller?.openSettings() },
                onSelectPhoneSlot: { [weak controller] slot in controller?.openPhoneSlotEditor(slot) },
                onEditSlot: { [weak controller] slot in controller?.openSlotEditor(slot) }
            )
        }
    }

    public func start() {
        setupWindow()
        setupEventMonitors()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NotificationCenter.default.removeObserver(self)
    }

    private func setupWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let geo = ScreenGeometry(
            screenWidth: screen.frame.width,
            screenHeight: screen.frame.height,
            topSafeAreaInset: screen.safeAreaInsets.top
        )

        let initialSize = geo.notchCollapsedSize
        let margin = NotchPanel.shadowMargin
        let panelWidth = initialSize.width + margin * 2
        let panelHeight = initialSize.height + margin
        let panelX = screen.frame.midX - panelWidth / 2
        let panelY = screen.frame.maxY - panelHeight

        let contentRect = NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight)
        let panel = NotchPanel(contentRect: contentRect)

        let rootView = RootWrapperView(
            controller: self,
            hasPhysicalNotch: geo.hasPhysicalNotch
        )

        panel.contentView = NotchHostingView(rootView: rootView)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    public func setExpanded(_ expanded: Bool) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setExpanded(expanded)
            }
            return
        }

        guard self.isExpanded != expanded else { return }

        guard let screen = NSScreen.main ?? NSScreen.screens.first,
              let panel = self.panel else {
            self.isExpanded = expanded
            return
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.76, blendDuration: 0.1)) {
            self.isExpanded = expanded
        }

        let contentSize = expanded ? CGSize(width: 480, height: 224) : CGSize(width: 180, height: max(32, screen.safeAreaInsets.top))
        let margin = NotchPanel.shadowMargin
        let targetWidth = contentSize.width + margin * 2
        let targetHeight = contentSize.height + margin
        let targetX = screen.frame.midX - targetWidth / 2
        let targetY = screen.frame.maxY - targetHeight

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.38
            // Liquid spring-like cubic bezier matching SwiftUI spring timing
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().setFrame(NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight), display: true)
        }
    }

    private var activeNotchRectOnScreen: NSRect? {
        guard let panel = self.panel else { return nil }
        let f = panel.frame
        let margin = NotchPanel.shadowMargin
        return NSRect(
            x: f.origin.x + margin,
            y: f.origin.y + margin,
            width: max(0, f.width - margin * 2),
            height: max(0, f.height - margin)
        )
    }

    private func setupEventMonitors() {
        // Outside click detector
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isExpanded else { return }
            // Do NOT collapse if editor window or settings window is currently active/open
            if self.editorWindow != nil || self.settingsWindow != nil { return }

            let mouseLoc = NSEvent.mouseLocation
            if let activeRect = self.activeNotchRectOnScreen, !activeRect.contains(mouseLoc) {
                DispatchQueue.main.async {
                    self.setExpanded(false)
                }
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isExpanded else { return event }
            // Do NOT collapse if editor window or settings window is currently active/open
            if self.editorWindow != nil || self.settingsWindow != nil { return event }

            let mouseLoc = NSEvent.mouseLocation
            if let activeRect = self.activeNotchRectOnScreen, !activeRect.contains(mouseLoc) {
                DispatchQueue.main.async {
                    self.setExpanded(false)
                }
            }
            return event
        }
    }

    public func openSettings() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchDeck Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: SettingsView())

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            if self?.settingsWindow === window {
                self?.settingsWindow = nil
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.settingsWindow = window
    }

    public func openPhoneSlotEditor(_ slot: PhoneDeckSlot) {
        if let existing = editorWindow {
            existing.close()
            self.editorWindow = nil
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 290),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Select App for Slot \(slot.index + 1)"
        window.center()
        window.isReleasedWhenClosed = false

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            if self?.editorWindow === window {
                self?.editorWindow = nil
                self?.setExpanded(true)
            }
        }

        let sheet = PhoneAppPickerSheet(
            slotIndex: slot.index,
            currentBundleId: slot.bundleId,
            onSelectApp: { [weak self, weak window] app in
                PhoneDeckService.shared.setSlotApp(index: slot.index, app: app)
                window?.close()
                self?.editorWindow = nil
                // Keep the notch expanded after saving is done!
                self?.setExpanded(true)
            },
            onCancel: { [weak self, weak window] in
                window?.close()
                self?.editorWindow = nil
                // Keep the notch expanded when cancelled
                self?.setExpanded(true)
            }
        )
        window.contentView = NSHostingView(rootView: sheet)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.editorWindow = window
    }

    public func openSlotEditor(_ slot: DeckSlot) {
        if let existing = editorWindow {
            existing.close()
            self.editorWindow = nil
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Edit Slot"
        window.center()
        window.isReleasedWhenClosed = false

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            if self?.editorWindow === window {
                self?.editorWindow = nil
                self?.setExpanded(true)
            }
        }

        var currentSlot = slot
        let sheet = InlineSlotEditorSheet(
            slot: Binding(get: { currentSlot }, set: { currentSlot = $0 }),
            onSave: { [weak self, weak window] updated in
                ConfigManager.shared.updateSlot(updated)
                window?.close()
                self?.editorWindow = nil
                // Keep the notch expanded after saving is done!
                self?.setExpanded(true)
            },
            onCancel: { [weak self, weak window] in
                window?.close()
                self?.editorWindow = nil
                // Keep the notch expanded when cancelled
                self?.setExpanded(true)
            }
        )
        window.contentView = NSHostingView(rootView: sheet)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.editorWindow = window
    }

    @objc private func screenParametersChanged() {
        guard let screen = NSScreen.main, let panel = self.panel else { return }
        let contentSize = isExpanded ? CGSize(width: 480, height: 224) : CGSize(width: 180, height: max(32, screen.safeAreaInsets.top))
        let margin = NotchPanel.shadowMargin
        let targetWidth = contentSize.width + margin * 2
        let targetHeight = contentSize.height + margin
        let targetX = screen.frame.midX - targetWidth / 2
        let targetY = screen.frame.maxY - targetHeight
        panel.setFrame(NSRect(x: targetX, y: targetY, width: targetWidth, height: targetHeight), display: true)
    }
}
