# NotchDeck --- Product & Interaction Design

## 1. Design Principles

NotchDeck should feel like a physical control surface, not a
remote-control webpage.

1.  **Immediate:** touch feedback occurs instantly.
2.  **Glanceable:** a control's purpose should be understood without
    reading paragraphs.
3.  **Stable:** controls should not move unexpectedly.
4.  **Low-noise:** avoid unnecessary animation and decoration.
5.  **Contextual:** the deck may adapt to the foreground Mac app, but
    profile changes must be predictable.
6.  **Recoverable:** connection problems must be visible and
    self-healing.
7.  **Safe:** dangerous actions require deliberate configuration on the
    Mac.

## 2. Android Information Architecture

``` text
App
├── Pairing
├── Deck
│   ├── Profile
│   ├── Page
│   └── Controls
└── Settings
    ├── Connection
    ├── Haptics
    ├── Keep Awake
    └── Diagnostics
```

The normal daily experience should open directly into the last deck.

## 3. Main Deck

Example 3x4 developer-oriented layout:

``` text
┌─────────┬─────────┬─────────┐
│ VS Code │Terminal │ Browser │
│    ◻    │   >_    │    ◉    │
├─────────┼─────────┼─────────┤
│  Git    │  Codex  │  Tests  │
│         │         │         │
├─────────┼─────────┼─────────┤
│  Mute   │  Play   │  Next   │
│   🔇    │   ▶     │   »     │
├─────────┼─────────┼─────────┤
│ Desktop │  Lock   │  More   │
│         │         │    ›    │
└─────────┴─────────┴─────────┘
```

The grid should adapt to screen size while preserving large touch
targets.

## 4. Control States

Every button supports:

-   `idle`
-   `pressed`
-   `pending` only when execution is meaningfully slow
-   `success` optional short pulse
-   `error`
-   `disabled`

Interaction sequence:

``` text
Finger down
  -> pressed visual immediately
  -> optional haptic
Finger up
  -> send action
  -> return to idle
Result error
  -> short error state + optional message
```

Do not wait for the Mac acknowledgement before showing pressed feedback.

## 5. Connection UX

A small status indicator is enough during normal operation:

``` text
● USB
● LAN
○ Reconnecting
! Pairing required
```

When disconnected, preserve the deck so the UI does not flash or
rebuild. Controls can become visually unavailable while the connection
manager retries.

## 6. Pairing Flow

### Mac

1.  User chooses **Pair New Device**.
2.  Mac displays device discovery/pairing state.
3.  Mac generates a short-lived six-digit code.
4.  Mac shows the Android device name when a request arrives.
5.  User confirms.
6.  Mac stores device trust and shows **Connected**.

### Android

1.  First launch shows **Connect to Mac**.
2.  User selects discovered Mac or enters address in development mode.
3.  Android asks for pairing code.
4.  Pairing succeeds.
5.  Deck opens immediately.

Do not expose permanent tokens to the user.

## 7. Profile Design

Suggested built-in starter profiles:

### Dock

-   Finder
-   Browser
-   VS Code
-   Terminal
-   ChatGPT
-   Music
-   Settings
-   Lock

### Developer

-   Open project
-   Terminal here
-   Start dev server
-   Stop dev server
-   Git status
-   Git pull
-   Run tests
-   Open localhost
-   Codex/AI launcher

### Media/System

-   Previous
-   Play/Pause
-   Next
-   Mute
-   Volume -
-   Volume +
-   Screenshot
-   Lock
-   Sleep

These are templates only; the architecture must not hard-code them.

## 8. Context-Aware Profiles

When automatic switching is enabled:

``` text
Foreground Mac app changes
        ↓
Mac resolves AppProfileRule
        ↓
profile.changed
        ↓
Android transitions to profile
```

Design constraints: - Do not switch while the user is actively holding a
control. - Avoid animated transitions longer than \~150--200 ms. - Allow
a manual "pin profile" mode. - Display the profile name briefly after an
automatic switch. - Manual navigation should remain possible.

## 9. Long Press, Double Tap, Sliders

Add after the tap MVP.

A control can map different events:

``` json
{
  "tap": "media-play-pause",
  "longPress": "open-music",
  "doubleTap": "media-next"
}
```

Sliders should rate-limit network updates, for example send at a
controlled interval while dragging and send a final exact value on
release.

## 10. Mac Menu-Bar Design

Suggested menu:

``` text
MacDeck
────────────────────────
● Android Phone
  Connected via USB

Active Profile: Developer

Pair New Device…
Manage Profiles…
Permissions…
Diagnostics…

Start at Login       ✓
Enable LAN           ✓

Quit MacDeck
```

A settings window can later provide full profile editing.

## 11. Profile Editor

Post-MVP editor layout:

``` text
┌──────────────┬─────────────────────────┬─────────────────┐
│ Profiles     │ Deck Preview            │ Inspector       │
│              │                         │                 │
│ Dock         │ [VS] [Term] [Browser]   │ Label           │
│ Developer  ● │ [Git][Test] [Local]     │ Icon            │
│ Media        │ [..] [..]   [..]        │ Action          │
│              │                         │ Tap/Long press  │
└──────────────┴─────────────────────────┴─────────────────┘
```

Configuration belongs on the Mac because the Mac owns executable actions
and security.

## 12. Visual System

For an old Android device: - Prefer solid backgrounds. - Avoid
blur/glass effects. - Avoid constantly animated gradients. - Use vector
icons where practical. - Keep icon assets cached. - Use a small number
of text sizes. - Ensure high contrast. - Support dark mode first because
the device may remain on for long periods.

Recommended dimensions are responsive rather than hard-coded. Minimum
touch target should follow Android accessibility guidance and should be
larger where screen space allows.

## 13. Haptics

Default: - light haptic on successful touch registration. - optional
stronger/error haptic for failed action. - global haptics toggle.

Haptics communicate that the phone received the touch even if the Mac
action itself takes longer.

## 14. Error Design

Errors should be specific:

-   `Mac disconnected`
-   `Permission required on Mac`
-   `Application not found`
-   `Action disabled`
-   `Script timed out`
-   `Pairing expired`
-   `Unsupported protocol version`

Do not expose stack traces or raw shell stderr in the normal deck UI.
Diagnostics can expose sanitized details.

## 15. Accessibility

-   Large controls.
-   Content descriptions for icons.
-   Do not encode state only by color.
-   Support text scaling within reasonable bounds.
-   Maintain contrast.
-   Provide haptics as enhancement, not the only feedback.
-   Make destructive actions visually distinct and optionally require
    long press.

## 16. Device Longevity

The product should include a "Dock Mode": - Keep screen awake while
connected. - Optional screen dim after inactivity. - Optional
black/saver screen after a configurable period. - Wake on touch. - Avoid
static high-brightness UI where possible.

This helps reduce OLED burn-in and heat for a permanently connected old
phone.

## 17. MVP Screen Inventory

Android: 1. Pair/connect. 2. Main deck. 3. Connection/settings. 4.
Diagnostics.

macOS: 1. Menu-bar menu. 2. Pairing sheet. 3. Permissions sheet. 4.
Basic device/settings window. 5. Minimal profile/action configuration,
even if JSON-backed initially.

## 18. UX Acceptance Tests

-   User can identify connection mode at a glance.
-   Tap feedback is visible immediately.
-   Losing connection never freezes the UI.
-   Reconnection requires no manual reload.
-   A failed Mac action is understandable.
-   Pairing can be completed without copying long credentials.
-   Auto profile switching can be disabled or pinned.
-   Old Android hardware can render the deck smoothly without decorative
    effects.
