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
    func testNotchWindowControllerOpenSettingsAndEditor() {
        let controller = NotchWindowController.shared
        controller.openSettings()
        XCTAssertNotNil(controller.settingsWindow)
        XCTAssertEqual(controller.settingsWindow?.title, "NotchDeck Preferences")

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

        // Point inside the bottom shadow margin (y < 24) should return nil
        let bottomShadowPoint = NSPoint(x: 100, y: 10)
        XCTAssertNil(hostingView.hitTest(bottomShadowPoint))

        // Point inside the left shadow margin (x < 24) should return nil
        let leftShadowPoint = NSPoint(x: 10, y: 40)
        XCTAssertNil(hostingView.hitTest(leftShadowPoint))

        // Point inside the active notch rect should return the hit view
        let activePoint = NSPoint(x: 100, y: 40)
        XCTAssertNotNil(hostingView.hitTest(activePoint))
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
}
