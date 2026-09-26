import AppKit
import SwiftUI

public final class NotchWindowController: NSObject, ObservableObject {
    public static let shared = NotchWindowController()

    public private(set) var panel: NotchPanel?
    public private(set) var settingsWindow: NSWindow?
    public private(set) var editorWindow: NSWindow?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var dragEventMonitor: Any?
    private var globalDragEventMonitor: Any?
    private var bubblePanel: NotchBubblePanel?

    @Published public private(set) var isExpanded: Bool = false
    @Published public private(set) var currentEdge: NotchEdge = .top
    @Published public private(set) var sidePositionRatio: CGFloat = 0.5
    @Published public private(set) var isDragging: Bool = false
    @Published public var dragTargetEdge: NotchEdge? = nil
    @Published public private(set) var stretchDistance: CGFloat = 0.0
    @Published public private(set) var lateralOffset: CGFloat = 0.0
    @Published public private(set) var isDetached: Bool = false

    private var dragStartMouseLocation: NSPoint = .zero
    private var dragStartWindowOrigin: NSPoint = .zero

    private struct RootWrapperView: View {
        @ObservedObject var controller: NotchWindowController
        let hasPhysicalNotch: Bool
        var physicalNotchWidth: CGFloat = 180
        var topSafeAreaInset: CGFloat = 32

        var body: some View {
            NotchDeckRootView(
                configManager: ConfigManager.shared,
                phoneDeckService: PhoneDeckService.shared,
                isExpanded: Binding(
                    get: { controller.isExpanded },
                    set: { controller.setExpanded($0) }
                ),
                edge: controller.currentEdge,
                hasPhysicalNotch: hasPhysicalNotch,
                physicalNotchWidth: physicalNotchWidth,
                topSafeAreaInset: topSafeAreaInset,
                stretchDistance: controller.stretchDistance,
                lateralOffset: controller.lateralOffset,
                isDetached: controller.isDetached,
                dragTargetEdge: controller.dragTargetEdge,
                onOpenSettings: { [weak controller] in controller?.openSettings() },
                onSelectPhoneSlot: { [weak controller] slot in controller?.openPhoneSlotEditor(slot) },
                onEditSlot: { [weak controller] slot in controller?.openSlotEditor(slot) },
                onBeginDrag: { [weak controller] in controller?.beginDragging() },
                onUpdateDrag: { [weak controller] in controller?.updateDrag() },
                onEndDrag: { [weak controller] in controller?.endDragging() }
            )
        }
    }

    public func start() {
        let loadedConfig = ConfigManager.shared.config
        self.currentEdge = loadedConfig.edge
        self.sidePositionRatio = loadedConfig.sidePositionRatio

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
        if let monitor = dragEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalDragEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let bubble = bubblePanel {
            bubble.orderOut(nil)
        }
        NotificationCenter.default.removeObserver(self)
    }

    public func currentScreenGeometry(for screen: NSScreen) -> ScreenGeometry {
        var notchWidth: CGFloat? = nil
        if #available(macOS 12.0, *) {
            if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
                let w = right.minX - left.maxX
                if w > 50 {
                    notchWidth = w
                }
            }
        }
        return ScreenGeometry(
            screenWidth: screen.frame.width,
            screenHeight: screen.frame.height,
            topSafeAreaInset: screen.safeAreaInsets.top,
            physicalNotchWidth: notchWidth
        )
    }

    private func setupWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let geo = currentScreenGeometry(for: screen)

        let initialFrame = geo.panelFrame(
            for: currentEdge,
            isExpanded: isExpanded,
            sidePositionRatio: sidePositionRatio,
            shadowMargin: NotchPanel.shadowMargin,
            screenRect: screen.frame
        )

        let panel = NotchPanel(contentRect: initialFrame)

        let rootView = RootWrapperView(
            controller: self,
            hasPhysicalNotch: geo.hasPhysicalNotch,
            physicalNotchWidth: geo.physicalNotchWidth,
            topSafeAreaInset: geo.topSafeAreaInset
        )

        let hostingView = NotchHostingView(rootView: rootView)
        hostingView.currentEdge = currentEdge
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        self.panel = panel
    }

    public func moveTo(edge: NotchEdge, positionRatio: CGFloat, animated: Bool = true) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.moveTo(edge: edge, positionRatio: positionRatio, animated: animated)
            }
            return
        }

        hideSideNotchBubble()
        self.currentEdge = edge
        self.sidePositionRatio = positionRatio

        // Update config persistence
        var currentCfg = ConfigManager.shared.config
        currentCfg.edge = edge
        currentCfg.sidePositionRatio = positionRatio
        try? ConfigManager.shared.saveConfig(currentCfg)

        guard let screen = panel?.screen ?? NSScreen.main ?? NSScreen.screens.first,
              let panel = self.panel else { return }

        if let hostingView = panel.contentView as? NotchHostingView<RootWrapperView> {
            hostingView.currentEdge = edge
        }

        let geo = currentScreenGeometry(for: screen)

        let targetRect = geo.panelFrame(
            for: edge,
            isExpanded: isExpanded,
            sidePositionRatio: positionRatio,
            shadowMargin: NotchPanel.shadowMargin,
            screenRect: screen.frame
        )

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.32
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(targetRect, display: true)
            }
        } else {
            panel.setFrame(targetRect, display: true)
        }
    }

    public func setExpanded(_ expanded: Bool) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setExpanded(expanded)
            }
            return
        }

        guard self.isExpanded != expanded else { return }
        hideSideNotchBubble()

        guard let screen = panel?.screen ?? NSScreen.main ?? NSScreen.screens.first,
              let panel = self.panel else {
            self.isExpanded = expanded
            return
        }

        withAnimation(.easeInOut(duration: 0.26)) {
            self.isExpanded = expanded
        }

        let geo = currentScreenGeometry(for: screen)

        let targetRect = geo.panelFrame(
            for: currentEdge,
            isExpanded: expanded,
            sidePositionRatio: sidePositionRatio,
            shadowMargin: NotchPanel.shadowMargin,
            screenRect: screen.frame
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.26
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetRect, display: true)
        }
    }

    // MARK: - Dragging Support

    public func beginDragging() {
        guard let panel = self.panel else { return }
        hideSideNotchBubble()
        self.isDragging = true
        self.isDetached = false
        self.stretchDistance = 0.0
        self.lateralOffset = 0.0
        self.dragStartMouseLocation = NSEvent.mouseLocation

        // If currently expanded, collapse immediately so pulling acts as a liquid droplet
        if self.isExpanded {
            self.isExpanded = false
            if let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first {
                let geo = currentScreenGeometry(for: screen)
                let collapsedFrame = geo.panelFrame(
                    for: currentEdge,
                    isExpanded: false,
                    sidePositionRatio: sidePositionRatio,
                    shadowMargin: NotchPanel.shadowMargin,
                    screenRect: screen.frame
                )
                panel.setFrame(collapsedFrame, display: true)
            }
        }
        self.dragStartWindowOrigin = panel.frame.origin

        // Register local and global mouse drag monitors to ensure unbroken cursor tracking
        if let monitor = dragEventMonitor {
            NSEvent.removeMonitor(monitor)
            dragEventMonitor = nil
        }
        if let monitor = globalDragEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalDragEventMonitor = nil
        }

        dragEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self, self.isDragging else { return event }
            if event.type == .leftMouseDragged {
                self.updateDrag()
            } else if event.type == .leftMouseUp {
                self.endDragging()
            }
            return event
        }

        globalDragEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self, self.isDragging else { return }
            DispatchQueue.main.async {
                if event.type == .leftMouseDragged {
                    self.updateDrag()
                } else if event.type == .leftMouseUp {
                    self.endDragging()
                }
            }
        }
    }

    public func updateDrag() {
        guard isDragging, let panel = self.panel,
              let screen = panel.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - dragStartMouseLocation.x
        let deltaY = currentMouse.y - dragStartMouseLocation.y

        let pullInward: CGFloat
        let lateral: CGFloat

        switch currentEdge {
        case .top:
            pullInward = max(0, -deltaY)
            lateral = deltaX
        case .right:
            pullInward = max(0, -deltaX)
            lateral = deltaY
        case .left:
            pullInward = max(0, deltaX)
            lateral = deltaY
        }

        let detachThreshold: CGFloat = 100.0

        if !isDetached && pullInward < detachThreshold {
            // --- Phase 1: Elastic Liquid Stretch Anchored to Screen Bezel ---
            self.stretchDistance = pullInward
            self.lateralOffset = lateral

            let geo = currentScreenGeometry(for: screen)
            let baseFrame = geo.panelFrame(
                for: currentEdge,
                isExpanded: false,
                sidePositionRatio: sidePositionRatio,
                shadowMargin: NotchPanel.shadowMargin,
                screenRect: screen.frame
            )

            var stretchedFrame = baseFrame
            switch currentEdge {
            case .top:
                stretchedFrame.size.height = baseFrame.height + pullInward
                stretchedFrame.origin.y = screen.frame.maxY - stretchedFrame.size.height
            case .right:
                stretchedFrame.size.width = baseFrame.width + pullInward
                stretchedFrame.origin.x = screen.frame.maxX - stretchedFrame.size.width
            case .left:
                stretchedFrame.size.width = baseFrame.width + pullInward
                stretchedFrame.origin.x = screen.frame.minX
            }

            if let hostingView = panel.contentView as? NotchHostingView<RootWrapperView> {
                hostingView.isDetached = false
            }
            panel.setFrame(stretchedFrame, display: true)
        } else {
            // --- Phase 2: Detached Floating Droplet Following Mouse Cursor ---
            if !isDetached {
                self.isDetached = true
                self.stretchDistance = 0.0
                self.lateralOffset = 0.0
                if let hostingView = panel.contentView as? NotchHostingView<RootWrapperView> {
                    hostingView.isDetached = true
                }
            }

            let dropletWidth: CGFloat = 76.0 + NotchPanel.shadowMargin * 2
            let dropletHeight: CGFloat = 40.0 + NotchPanel.shadowMargin * 2

            let newOrigin = NSPoint(
                x: currentMouse.x - dropletWidth / 2,
                y: currentMouse.y - dropletHeight / 2
            )
            panel.setFrame(NSRect(origin: newOrigin, size: CGSize(width: dropletWidth, height: dropletHeight)), display: true)

            let candidateEdge = ScreenGeometry.dockingEdge(
                for: currentMouse,
                screenFrame: screen.frame,
                currentEdge: currentEdge,
                dockZoneThreshold: 110.0
            )
            if dragTargetEdge != candidateEdge {
                dragTargetEdge = candidateEdge
            }
        }
    }

    public func endDragging() {
        if let monitor = dragEventMonitor {
            NSEvent.removeMonitor(monitor)
            dragEventMonitor = nil
        }
        if let monitor = globalDragEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalDragEventMonitor = nil
        }

        guard isDragging, let screen = panel?.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            isDragging = false
            isDetached = false
            stretchDistance = 0.0
            lateralOffset = 0.0
            dragTargetEdge = nil
            return
        }

        let wasDetached = self.isDetached
        self.isDragging = false
        self.isDetached = false
        self.stretchDistance = 0.0
        self.lateralOffset = 0.0

        if let hostingView = panel?.contentView as? NotchHostingView<RootWrapperView> {
            hostingView.isDetached = false
        }

        if wasDetached {
            let currentMouse = NSEvent.mouseLocation
            let dockEdge = self.dragTargetEdge ?? ScreenGeometry.dockingEdge(
                for: currentMouse,
                screenFrame: screen.frame,
                currentEdge: currentEdge,
                dockZoneThreshold: 110.0
            )

            if let targetEdge = dockEdge {
                // Docked to side or top edge
                var newRatio = self.sidePositionRatio
                if targetEdge.isVertical {
                    let availableTravel = max(10, screen.frame.height - 240)
                    let relativeY = currentMouse.y - screen.frame.minY - 120
                    newRatio = max(0.05, min(0.95, relativeY / availableTravel))
                } else {
                    newRatio = 0.5
                }

                self.dragTargetEdge = nil
                moveTo(edge: targetEdge, positionRatio: newRatio, animated: true)
            } else {
                // Released in open screen space (not placed in side or top dock)
                // Retract smoothly back to the current edge dock
                self.dragTargetEdge = nil
                let geo = currentScreenGeometry(for: screen)
                let homeRect = geo.panelFrame(
                    for: currentEdge,
                    isExpanded: false,
                    sidePositionRatio: sidePositionRatio,
                    shadowMargin: NotchPanel.shadowMargin,
                    screenRect: screen.frame
                )
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.35
                    context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                    self.panel?.animator().setFrame(homeRect, display: true)
                }
            }
        } else {
            // Retract elastic stretch smoothly back into bezel (no bounce)
            self.dragTargetEdge = nil
            let geo = currentScreenGeometry(for: screen)
            let targetRect = geo.panelFrame(
                for: currentEdge,
                isExpanded: false,
                sidePositionRatio: sidePositionRatio,
                shadowMargin: NotchPanel.shadowMargin,
                screenRect: screen.frame
            )

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.panel?.animator().setFrame(targetRect, display: true)
            }
        }
    }

    private var activeNotchRectOnScreen: NSRect? {
        guard let panel = self.panel else { return nil }
        let f = panel.frame
        let margin = NotchPanel.shadowMargin

        if isDetached {
            return NSRect(
                x: f.origin.x + margin,
                y: f.origin.y + margin,
                width: max(0, f.width - margin * 2),
                height: max(0, f.height - margin * 2)
            )
        }

        switch currentEdge {
        case .top:
            return NSRect(
                x: f.origin.x + margin,
                y: f.origin.y,
                width: max(0, f.width - margin * 2),
                height: max(0, f.height - margin)
            )
        case .right:
            return NSRect(
                x: f.origin.x + margin,
                y: f.origin.y + margin,
                width: max(0, f.width - margin),
                height: max(0, f.height - margin * 2)
            )
        case .left:
            return NSRect(
                x: f.origin.x,
                y: f.origin.y + margin,
                width: max(0, f.width - margin),
                height: max(0, f.height - margin * 2)
            )
        }
    }

    private func setupEventMonitors() {
        // Outside click detector
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isExpanded else { return }
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
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "NotchDeck Preferences"
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 500)
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
                self?.setExpanded(true)
            },
            onCancel: { [weak self, weak window] in
                window?.close()
                self?.editorWindow = nil
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
                self?.setExpanded(true)
            },
            onCancel: { [weak self, weak window] in
                window?.close()
                self?.editorWindow = nil
                self?.setExpanded(true)
            }
        )
        window.contentView = NSHostingView(rootView: sheet)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.editorWindow = window
    }

    // MARK: - Side Notch Hover Extended Chat Bubble

    public func setSideNotchHovered(_ hovered: Bool) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.setSideNotchHovered(hovered)
            }
            return
        }

        guard currentEdge.isVertical, !isExpanded, !isDragging else {
            hideSideNotchBubble()
            return
        }

        if hovered {
            showSideNotchBubble()
        } else {
            hideSideNotchBubble()
        }
    }

    private func showSideNotchBubble() {
        guard let panel = self.panel, currentEdge.isVertical, !isExpanded, !isDragging else { return }

        let bubble: NotchBubblePanel
        if let existing = self.bubblePanel {
            bubble = existing
            if let hosting = bubble.contentView as? NSHostingView<SideNotchBubbleView> {
                hosting.rootView = SideNotchBubbleView(phoneDeckService: PhoneDeckService.shared, edge: currentEdge)
            }
        } else {
            let newBubble = NotchBubblePanel()
            let hosting = NSHostingView(rootView: SideNotchBubbleView(phoneDeckService: PhoneDeckService.shared, edge: currentEdge))
            newBubble.contentView = hosting
            self.bubblePanel = newBubble
            bubble = newBubble
        }

        // Measure fitting size for dynamic text length
        let fittingSize = bubble.contentView?.fittingSize ?? CGSize(width: 160, height: 28)
        let bubbleWidth = max(130, fittingSize.width)
        let bubbleHeight = max(26, fittingSize.height)

        let notchFrame = panel.frame
        let shadowMargin = NotchPanel.shadowMargin

        let bubbleX: CGFloat
        if currentEdge == .right {
            // Sits to the left of the right notch (tail points right towards notch)
            bubbleX = notchFrame.minX + shadowMargin - bubbleWidth - 4
        } else {
            // Sits to the right of the left notch (tail points left towards notch)
            bubbleX = notchFrame.maxX - shadowMargin + 4
        }

        let bubbleY = notchFrame.midY - bubbleHeight / 2
        let targetFrame = NSRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)

        bubble.setFrame(targetFrame, display: true)
        bubble.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            bubble.animator().alphaValue = 1.0
        }
    }

    private func hideSideNotchBubble() {
        guard let bubble = bubblePanel, bubble.alphaValue > 0 else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            bubble.animator().alphaValue = 0.0
        }, completionHandler: {
            if bubble.alphaValue == 0 {
                bubble.orderOut(nil)
            }
        })
    }

    @objc private func screenParametersChanged() {
        hideSideNotchBubble()
        guard let screen = panel?.screen ?? NSScreen.main ?? NSScreen.screens.first,
              let panel = self.panel else { return }
        let geo = currentScreenGeometry(for: screen)
        if let hostingView = panel.contentView as? NotchHostingView<RootWrapperView> {
            hostingView.rootView = RootWrapperView(
                controller: self,
                hasPhysicalNotch: geo.hasPhysicalNotch,
                physicalNotchWidth: geo.physicalNotchWidth,
                topSafeAreaInset: geo.topSafeAreaInset
            )
        }
        let targetRect = geo.panelFrame(
            for: currentEdge,
            isExpanded: isExpanded,
            sidePositionRatio: sidePositionRatio,
            shadowMargin: NotchPanel.shadowMargin,
            screenRect: screen.frame
        )
        panel.setFrame(targetRect, display: true)
    }
}
