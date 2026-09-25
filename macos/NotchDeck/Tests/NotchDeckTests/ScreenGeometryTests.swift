import XCTest
import AppKit
@testable import NotchDeck

final class ScreenGeometryTests: XCTestCase {
    func testPhysicalNotchDetectedWhenTopInsetLarge() {
        let geo = ScreenGeometry(screenWidth: 1512, screenHeight: 982, topSafeAreaInset: 32)
        XCTAssertTrue(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 32)
        XCTAssertEqual(geo.notchCollapsedSize.width, 180)
        XCTAssertEqual(geo.notchExpandedSize.width, 520)
        XCTAssertEqual(geo.notchExpandedSize.height, 172)
    }

    func testExternalDisplayTreatedAsSimulatedNotch() {
        let geo = ScreenGeometry(screenWidth: 2560, screenHeight: 1440, topSafeAreaInset: 0)
        XCTAssertFalse(geo.hasPhysicalNotch)
        XCTAssertEqual(geo.notchCollapsedSize.height, 34)
        XCTAssertEqual(geo.notchCollapsedSize.width, 180)
        XCTAssertEqual(geo.notchExpandedSize.width, 520)
        XCTAssertEqual(geo.notchExpandedSize.height, 172)
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
}
