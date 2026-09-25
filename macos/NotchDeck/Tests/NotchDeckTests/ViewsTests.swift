import XCTest
import SwiftUI
import AppKit
@testable import NotchDeck

final class ViewsTests: XCTestCase {

    func testVisualEffectViewHostingAndProperties() {
        let visualEffectView = VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        XCTAssertEqual(visualEffectView.material, .hudWindow)
        XCTAssertEqual(visualEffectView.blendingMode, .behindWindow)

        let hostingView = NSHostingView(rootView: visualEffectView)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testLiquidGlassBackgroundDefaultAndCustomInits() {
        let defaultBg = LiquidGlassBackground()
        XCTAssertEqual(defaultBg.cornerRadius, 24.0)
        XCTAssertEqual(defaultBg.specularIntensity, 0.45)
        XCTAssertTrue(defaultBg.isExpanded)
        XCTAssertNotNil(defaultBg.body)

        let customBg = LiquidGlassBackground(cornerRadius: 18.0, specularIntensity: 0.75, isExpanded: false)
        XCTAssertEqual(customBg.cornerRadius, 18.0)
        XCTAssertEqual(customBg.specularIntensity, 0.75)
        XCTAssertFalse(customBg.isExpanded)
        XCTAssertNotNil(customBg.body)

        let settings = GlassAppearanceSettings(
            blurMaterial: "hud",
            specularIntensity: 0.6,
            ambientBacklightEnabled: true,
            cornerRadius: 28.0
        )
        let settingsBg = LiquidGlassBackground(settings: settings, isExpanded: true)
        XCTAssertEqual(settingsBg.cornerRadius, 28.0)
        XCTAssertEqual(settingsBg.specularIntensity, 0.6)
        XCTAssertTrue(settingsBg.isExpanded)
        XCTAssertNotNil(settingsBg.body)

        let hostingView = NSHostingView(rootView: settingsBg)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testDeckSlotTileViewSelectionAndEditCallbacks() {
        let slot = DeckSlot(
            index: 0,
            title: "Terminal",
            actionType: .appLauncher,
            target: "com.apple.Terminal",
            iconName: "terminal"
        )

        var selected = false
        var edited = false

        let normalTile = DeckSlotTileView(
            slot: slot,
            isEditing: false,
            onSelect: { selected = true },
            onEdit: { edited = true }
        )

        XCTAssertEqual(normalTile.slot.title, "Terminal")
        XCTAssertFalse(normalTile.isEditing)
        XCTAssertNotNil(normalTile.body)

        normalTile.onSelect()
        XCTAssertTrue(selected)
        XCTAssertFalse(edited)

        let editTile = DeckSlotTileView(
            slot: slot,
            isEditing: true,
            onSelect: { selected = true },
            onEdit: { edited = true }
        )

        XCTAssertTrue(editTile.isEditing)
        XCTAssertNotNil(editTile.body)

        editTile.onEdit()
        XCTAssertTrue(edited)

        let hostingView = NSHostingView(rootView: normalTile)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }

    func testDeckSlotTileViewDifferentActionTypes() {
        let mediaSlot = DeckSlot(
            index: 1,
            title: "Play/Pause",
            actionType: .mediaControl,
            target: "playPause",
            iconName: "playpause.fill"
        )
        let mediaTile = DeckSlotTileView(slot: mediaSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(mediaTile.body)

        let micSlot = DeckSlot(
            index: 2,
            title: "Mic Mute",
            actionType: .systemToggle,
            target: "micMute",
            iconName: "mic.slash"
        )
        let micTile = DeckSlotTileView(slot: micSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(micTile.body)

        let fallbackSlot = DeckSlot(
            index: 3,
            title: "Generic",
            actionType: .shellScript,
            target: "echo hello",
            iconName: nil
        )
        let fallbackTile = DeckSlotTileView(slot: fallbackSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(fallbackTile.body)

        let bookmarkSlot = DeckSlot(
            index: 4,
            title: "Docs",
            actionType: .urlBookmark,
            target: "https://apple.com",
            iconName: "safari"
        )
        let bookmarkTile = DeckSlotTileView(slot: bookmarkSlot, onSelect: {}, onEdit: {})
        XCTAssertNotNil(bookmarkTile.body)

        let hostingView = NSHostingView(rootView: bookmarkTile)
        hostingView.layout()
        XCTAssertNotNil(hostingView)
    }
}
