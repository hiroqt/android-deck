import XCTest
import AppKit
import SwiftUI
@testable import NotchDeck

final class ScreenGeometryTests: XCTestCase {
    func testPhysicalNotchDetectedWhenTopInsetLarge() {
        let geo = ScreenGeometry(screenWidth: 1512, screenHeight: 982, topSafeAreaInset: 32)
        XCTAssertTrue(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 32)
        XCTAssertEqual(geo.notchCollapsedSize.width, 180)
        XCTAssertEqual(geo.notchExpandedSize.width, 480)
        XCTAssertEqual(geo.notchExpandedSize.height, 224)
    }

    func testExternalDisplayTreatedAsSimulatedNotch() {
        let geo = ScreenGeometry(screenWidth: 2560, screenHeight: 1440, topSafeAreaInset: 0)
        XCTAssertFalse(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 34)
        XCTAssertEqual(geo.notchCollapsedSize.width, 180)
        XCTAssertEqual(geo.notchExpandedSize.width, 480)
        XCTAssertEqual(geo.notchExpandedSize.height, 224)
    }

    func testPhysicalNotchWithCustomHeightAboveMinimum() {
        let geo = ScreenGeometry(screenWidth: 1728, screenHeight: 1117, topSafeAreaInset: 44)
        XCTAssertTrue(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 44)
    }

    func testNotchEdgeProperties() {
        XCTAssertFalse(NotchEdge.top.isVertical)
        XCTAssertTrue(NotchEdge.left.isVertical)
        XCTAssertTrue(NotchEdge.right.isVertical)

        XCTAssertEqual(NotchEdge.top.title, "Top")
        XCTAssertEqual(NotchEdge.left.title, "Left")
        XCTAssertEqual(NotchEdge.right.title, "Right")

        XCTAssertEqual(NotchEdge.top.outwardVector, CGPoint(x: 0, y: -1))
        XCTAssertEqual(NotchEdge.left.outwardVector, CGPoint(x: -1, y: 0))
        XCTAssertEqual(NotchEdge.right.outwardVector, CGPoint(x: 1, y: 0))
    }

    func testScreenGeometrySizesForEdges() {
        let geo = ScreenGeometry(screenWidth: 1728, screenHeight: 1117, topSafeAreaInset: 34)

        // Collapsed sizes
        let topCollapsed = geo.collapsedSize(for: .top)
        XCTAssertEqual(topCollapsed.width, 180)
        XCTAssertEqual(topCollapsed.height, 34)

        let rightCollapsed = geo.collapsedSize(for: .right)
        XCTAssertEqual(rightCollapsed.width, 48)
        XCTAssertEqual(rightCollapsed.height, 116)

        let leftCollapsed = geo.collapsedSize(for: .left)
        XCTAssertEqual(leftCollapsed.width, 48)
        XCTAssertEqual(leftCollapsed.height, 116)

        // Expanded sizes
        let topExpanded = geo.expandedSize(for: .top)
        XCTAssertEqual(topExpanded.width, 480)
        XCTAssertEqual(topExpanded.height, 224)

        let rightExpanded = geo.expandedSize(for: .right)
        XCTAssertEqual(rightExpanded.width, 280)
        XCTAssertEqual(rightExpanded.height, 380)

        let leftExpanded = geo.expandedSize(for: .left)
        XCTAssertEqual(leftExpanded.width, 280)
        XCTAssertEqual(leftExpanded.height, 380)
    }

    func testScreenGeometryPanelFrames() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let geo = ScreenGeometry(screenWidth: 1000, screenHeight: 800, topSafeAreaInset: 32)

        // Top frame
        let topFrame = geo.panelFrame(for: .top, isExpanded: false, shadowMargin: 24, screenRect: screen)
        XCTAssertEqual(topFrame.width, 180 + 48)
        XCTAssertEqual(topFrame.maxX, 500 + 114)
        XCTAssertEqual(topFrame.maxY, 800)

        // Right frame (docked to right screen edge)
        let rightFrame = geo.panelFrame(for: .right, isExpanded: false, sidePositionRatio: 0.5, shadowMargin: 24, screenRect: screen)
        XCTAssertEqual(rightFrame.width, 48 + 24)
        XCTAssertEqual(rightFrame.maxX, 1000)

        // Left frame (docked to left screen edge)
        let leftFrame = geo.panelFrame(for: .left, isExpanded: false, sidePositionRatio: 0.5, shadowMargin: 24, screenRect: screen)
        XCTAssertEqual(leftFrame.width, 48 + 24)
        XCTAssertEqual(leftFrame.minX, 0)
    }

    func testTargetEdgeDetectionWithHysteresis() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

        // Near right edge
        let rightPoint = CGPoint(x: 950, y: 400)
        XCTAssertEqual(ScreenGeometry.targetEdge(for: rightPoint, screenFrame: screen, currentEdge: .top), .right)

        // Near left edge
        let leftPoint = CGPoint(x: 50, y: 400)
        XCTAssertEqual(ScreenGeometry.targetEdge(for: leftPoint, screenFrame: screen, currentEdge: .top), .left)

        // Near top edge
        let topPoint = CGPoint(x: 500, y: 780)
        XCTAssertEqual(ScreenGeometry.targetEdge(for: topPoint, screenFrame: screen, currentEdge: .right), .top)

        // Sliding along right edge should stay right due to hysteresis
        let slidingPoint = CGPoint(x: 880, y: 650)
        XCTAssertEqual(ScreenGeometry.targetEdge(for: slidingPoint, screenFrame: screen, currentEdge: .right), .right)
    }

    @MainActor
    func testNotchPanelConfiguration() {
        let frame = NSRect(x: 100, y: 100, width: 180, height: 32)
        let panel = NotchPanel(contentRect: frame)
        XCTAssertTrue(panel.isFloatingPanel)
        XCTAssertEqual(panel.level, .statusBar)
        XCTAssertTrue(panel.styleMask.contains(.borderless))
        XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
        XCTAssertFalse(panel.isOpaque)
        XCTAssertFalse(panel.hasShadow)
        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertFalse(panel.isMovable)
        XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    @MainActor
    func testNotchWindowControllerStartAndExpansion() {
        let controller = NotchWindowController.shared
        controller.start()
        XCTAssertNotNil(controller.panel)

        controller.setExpanded(true)
        XCTAssertTrue(controller.isExpanded)

        controller.setExpanded(false)
        XCTAssertFalse(controller.isExpanded)
    }

    @MainActor
    func testNotchWindowControllerMoveToEdgeAndDragging() {
        let controller = NotchWindowController.shared
        controller.start()

        // Move to right edge
        controller.moveTo(edge: .right, positionRatio: 0.5, animated: false)
        XCTAssertEqual(controller.currentEdge, .right)
        XCTAssertEqual(ConfigManager.shared.config.edge, .right)

        // Move to left edge
        controller.moveTo(edge: .left, positionRatio: 0.6, animated: false)
        XCTAssertEqual(controller.currentEdge, .left)
        XCTAssertEqual(ConfigManager.shared.config.edge, .left)

        // Drag lifecycle
        controller.beginDragging()
        XCTAssertTrue(controller.isDragging)

        controller.updateDrag()
        XCTAssertTrue(controller.isDragging)

        controller.endDragging()
        XCTAssertFalse(controller.isDragging)

        // Return to top
        controller.moveTo(edge: .top, positionRatio: 0.5, animated: false)
        XCTAssertEqual(controller.currentEdge, .top)
    }

    @MainActor
    func testNotchWindowControllerOpenSettingsAndEditor() {
        let controller = NotchWindowController.shared
        controller.openSettings()
        XCTAssertNotNil(controller.settingsWindow)
        XCTAssertEqual(controller.settingsWindow?.title, "NotchDeck Preferences")
        XCTAssertGreaterThanOrEqual(controller.settingsWindow!.frame.width, 500)
        XCTAssertGreaterThanOrEqual(controller.settingsWindow!.frame.height, 500)

        let slot = DeckSlot(index: 0, title: "Test", actionType: .mediaControl, target: "playPause", iconName: "play.fill")
        controller.openSlotEditor(slot)
        XCTAssertNotNil(controller.editorWindow)
        XCTAssertEqual(controller.editorWindow?.title, "Edit Slot")
    }

    @MainActor
    func testNotchHostingViewHitTestPassThrough() {
        let dummyView = SwiftUI.Text("Test")
        let hostingView = NotchHostingView(rootView: dummyView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 228, height: 56)
        hostingView.currentEdge = .top

        // Top edge: Point inside the bottom shadow margin (y > 32 in flipped coordinates) should return nil
        let bottomShadowPoint = NSPoint(x: 100, y: 45)
        XCTAssertNil(hostingView.hitTest(bottomShadowPoint))

        // Point inside the left shadow margin (x < 24) should return nil
        let leftShadowPoint = NSPoint(x: 10, y: 16)
        XCTAssertNil(hostingView.hitTest(leftShadowPoint))

        // Point inside the right shadow margin (x > 204) should return nil
        let rightShadowPoint = NSPoint(x: 215, y: 16)
        XCTAssertNil(hostingView.hitTest(rightShadowPoint))

        // Points inside the active notch rect should return the hit view
        let topNotchPoint = NSPoint(x: 100, y: 5)
        XCTAssertNotNil(hostingView.hitTest(topNotchPoint))

        let centerNotchPoint = NSPoint(x: 100, y: 16)
        XCTAssertNotNil(hostingView.hitTest(centerNotchPoint))

        let nearBottomNotchPoint = NSPoint(x: 100, y: 30)
        XCTAssertNotNil(hostingView.hitTest(nearBottomNotchPoint))

        // Test right edge hit test
        hostingView.currentEdge = .right
        hostingView.frame = NSRect(x: 0, y: 0, width: 72, height: 228)
        // Leading margin (x < 24) should return nil
        XCTAssertNil(hostingView.hitTest(NSPoint(x: 10, y: 100)))
        // Content area (x >= 24) should return view
        XCTAssertNotNil(hostingView.hitTest(NSPoint(x: 48, y: 100)))

        // Test left edge hit test
        hostingView.currentEdge = .left
        hostingView.frame = NSRect(x: 0, y: 0, width: 72, height: 228)
        // Trailing margin (x > 48) should return nil
        XCTAssertNil(hostingView.hitTest(NSPoint(x: 60, y: 100)))
        // Content area (x <= 48) should return view
        XCTAssertNotNil(hostingView.hitTest(NSPoint(x: 24, y: 100)))
    }

    @MainActor
    func testNotchWindowControllerOpenPhoneSlotEditor() {
        let controller = NotchWindowController.shared
        let slot = PhoneDeckSlot(id: "app-1", index: 0, label: "VS Code", bundleId: "com.microsoft.VSCode")
        controller.openPhoneSlotEditor(slot)
        XCTAssertNotNil(controller.editorWindow)
        XCTAssertTrue(controller.editorWindow?.title.contains("Slot 1") == true)
        controller.editorWindow?.close()
    }

    @MainActor
    func testNotchHostingViewDetachedHitTest() {
        let dummyView = SwiftUI.Text("Test")
        let hostingView = NotchHostingView(rootView: dummyView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 120, height: 88)
        hostingView.isDetached = true

        // Margin area (x < 24 or y < 24) should return nil
        XCTAssertNil(hostingView.hitTest(NSPoint(x: 10, y: 10)))
        // Droplet center area should return view
        XCTAssertNotNil(hostingView.hitTest(NSPoint(x: 60, y: 44)))
    }

    @MainActor
    func testNotchWindowControllerLiquidDragState() {
        let controller = NotchWindowController.shared
        controller.start()
        XCTAssertNotNil(controller.panel)
        XCTAssertEqual(controller.stretchDistance, 0.0)
        XCTAssertEqual(controller.lateralOffset, 0.0)
        XCTAssertFalse(controller.isDetached)

        // Drag start resets stretch state
        controller.beginDragging()
        XCTAssertTrue(controller.isDragging)
        XCTAssertEqual(controller.stretchDistance, 0.0)
        XCTAssertFalse(controller.isDetached)

        controller.updateDrag()
        controller.endDragging()
        XCTAssertFalse(controller.isDragging)
        XCTAssertEqual(controller.stretchDistance, 0.0)
        XCTAssertFalse(controller.isDetached)
    }

    func testDockingEdgeDetection() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)

        // Near top edge (y = 750, 50pt from top 800) -> .top
        let nearTop = CGPoint(x: 500, y: 750)
        XCTAssertEqual(ScreenGeometry.dockingEdge(for: nearTop, screenFrame: screen, currentEdge: .top), .top)

        // Near left edge (x = 40, 40pt from left 0) -> .left
        let nearLeft = CGPoint(x: 40, y: 400)
        XCTAssertEqual(ScreenGeometry.dockingEdge(for: nearLeft, screenFrame: screen, currentEdge: .top), .left)

        // Near right edge (x = 960, 40pt from right 1000) -> .right
        let nearRight = CGPoint(x: 960, y: 400)
        XCTAssertEqual(ScreenGeometry.dockingEdge(for: nearRight, screenFrame: screen, currentEdge: .top), .right)

        // Open screen space (center of screen, x = 500, y = 400) -> nil (freely follows cursor)
        let openCenter = CGPoint(x: 500, y: 400)
        XCTAssertNil(ScreenGeometry.dockingEdge(for: openCenter, screenFrame: screen, currentEdge: .top))

        // Open screen space near bottom (x = 500, y = 50) -> nil
        let nearBottom = CGPoint(x: 500, y: 50)
        XCTAssertNil(ScreenGeometry.dockingEdge(for: nearBottom, screenFrame: screen, currentEdge: .top))
    }
}
