# MacDeck --- Product Requirements Document (PRD)

**Status:** Implementation-ready v1 plan\
**Product:** MacDeck\
**Platforms:** Android client + macOS host agent\
**Primary mode:** Local-only, USB-first with Wi-Fi fallback\
**Target:** Reuse an old Android phone as a fast, persistent Stream Deck
/ macOS command dock.

## 1. Product Summary

MacDeck turns an Android phone into a dedicated touchscreen control
surface for a Mac. The Android device renders configurable controls; the
macOS agent owns configuration, permissions, automation, execution,
state observation, and security.

The core product principle is simple:

> The phone requests named actions. The Mac decides what is allowed and
> executes them.

No cloud service is required for v1.

## 2. Problem

A spare Android phone has a touchscreen, battery, haptics, Wi-Fi, USB,
and enough compute to make an excellent programmable control surface.
Existing mobile Stream Deck products may depend on subscriptions, Wi-Fi,
third-party ecosystems, or generic interfaces.

MacDeck should provide:

-   Very low perceived input latency.
-   Reliable USB operation for a permanently docked phone.
-   Wi-Fi fallback for development and convenience.
-   Native Android performance on older hardware.
-   Deep macOS automation.
-   Dynamic profiles based on the foreground Mac application.
-   A secure execution model that does not expose arbitrary shell
    execution to the phone.
-   A configuration model that can evolve without rebuilding the Android
    application.

## 3. Goals

### MVP goals

1.  Android connects to the Mac over a persistent WebSocket.
2.  Mac authenticates the Android device.
3.  Mac sends the current deck/profile definition.
4.  Android renders a responsive 3x4 or configurable grid.
5.  A tap sends an action ID.
6.  Mac validates and executes the registered action.
7.  Mac returns success/failure and optional state.
8.  Android gives immediate visual and haptic feedback.
9.  Core actions include:
    -   Launch application
    -   Open URL
    -   Keyboard shortcut
    -   Media play/pause, previous, next
    -   Volume up/down/mute
    -   Lock Mac
    -   Run a pre-registered script
10. USB operation works through ADB TCP forwarding.
11. Wi-Fi can be used as a fallback transport.
12. Mac agent can run as a menu-bar application and optionally start at
    login.

### Post-MVP goals

-   Sliders and knobs.
-   Long press and double tap.
-   Multiple pages/folders.
-   Automatic profile switching by foreground application.
-   Mac-to-phone live state updates.
-   CPU/RAM/battery/media widgets.
-   Drag-and-drop profile editor on macOS.
-   Custom icons.
-   Import/export profiles.
-   Additional automation adapters such as Shortcuts and AppleScript.
-   Optional plugin SDK.

## 4. Non-goals for v1

-   Cloud synchronization.
-   Remote control over the public internet.
-   Multi-user/team management.
-   Full Elgato plugin compatibility.
-   Arbitrary shell commands supplied directly by Android.
-   Android-to-Mac file transfer.
-   Video streaming or screen mirroring.
-   Full mouse/trackpad replacement.

## 5. Target User

Primary user: a developer or power user with an old Android device and a
Mac who wants a permanently docked, programmable control surface for
development, media, productivity, and system controls.

## 6. Representative Use Cases

### Dock profile

Launch Finder, browser, VS Code, Terminal, ChatGPT, music, and other
frequently used applications.

### Developer profile

Open project, open terminal, start/stop a registered dev server, Git
pull/status, run tests, open localhost, or invoke a registered developer
script.

### System profile

Mute, volume, media playback, screenshot, lock, sleep, and other
approved system operations.

### Context-aware profile

When VS Code becomes the foreground app, MacDeck can switch the Android
UI to a VS Code-specific profile. When a browser becomes active, the
deck can switch to browser controls.

## 7. Functional Requirements

### FR-01 Connection

The Android app SHALL connect to the macOS agent using a persistent
WebSocket.

### FR-02 USB

The system SHALL support a USB path using ADB TCP forwarding so the
WebSocket can traverse the USB connection.

### FR-03 Wi-Fi

The system SHALL support local-LAN WebSocket connectivity as a fallback.

### FR-04 Pairing

The Mac SHALL require explicit first-time pairing. A short-lived pairing
code is acceptable for v1.

### FR-05 Authentication

After pairing, the Mac SHALL issue a cryptographically random device
token. The token SHALL be stored using Android Keystore-backed storage
and macOS Keychain.

### FR-06 Deck synchronization

After authentication, the Mac SHALL send the active profile/deck
configuration to Android.

### FR-07 Action execution

Android SHALL send an action identifier and event type, not an
unrestricted command string.

### FR-08 Action registry

The Mac SHALL resolve action IDs against a local action registry and
reject unknown or disabled actions.

### FR-09 Feedback

Every accepted action SHALL receive an acknowledgement containing
request ID, status, and optional error information.

### FR-10 Reconnection

Android SHALL reconnect automatically using bounded exponential backoff
and resynchronize state after reconnecting.

### FR-11 Foreground app

The Mac SHALL be able to observe foreground application changes and
optionally map them to profiles.

### FR-12 Permissions

The Mac agent SHALL report which required macOS permissions are missing
and degrade gracefully when an action cannot execute.

### FR-13 Local configuration

Profiles, buttons, and registered actions SHALL be stored locally on the
Mac.

### FR-14 Safety

Shell execution SHALL only reference scripts/actions already registered
on the Mac.

### FR-15 Device mode

Android SHALL provide a keep-awake mode suitable for a docked device.

## 8. Initial Action Types

  Type              Example                     Permission profile
  ----------------- --------------------------- ------------------------------------------
  `launch_app`      Launch VS Code              Usually no Accessibility
  `open_url`        Open localhost              Usually no Accessibility
  `keypress`        Cmd+Shift+4                 Accessibility/Input Monitoring may apply
  `media_control`   Play/pause                  Depends on implementation
  `volume`          Mute/up/down                System API/automation dependent
  `run_shortcut`    Run macOS Shortcut          Automation may apply
  `run_script`      Run registered dev script   Explicit local allowlist
  `window_action`   Minimize/focus              Accessibility may apply
  `system_action`   Lock/sleep                  API/automation dependent

## 9. Performance Requirements

The system should optimize for perceived immediacy.

-   Touch feedback on Android: immediate, before network
    acknowledgement.
-   Target local action request dispatch: \< 16 ms after tap processing
    where practical.
-   Target USB round-trip for lightweight actions: \< 50 ms on typical
    hardware.
-   Target LAN round-trip: \< 100 ms on a healthy local network.
-   No HTTP connection setup per button press.
-   WebSocket stays open while the deck is active.
-   UI must remain responsive during reconnects and Mac action
    execution.
-   Expensive Mac actions must not block the WebSocket receive loop.

These are engineering targets, not hard guarantees across all old
Android devices and Mac configurations.

## 10. Reliability Requirements

-   Connection heartbeat/ping.
-   Detect stale sessions.
-   Automatic reconnect.
-   Idempotent handling for messages that can safely be retried.
-   Request IDs to correlate action results.
-   Versioned protocol.
-   Profile resync after reconnect.
-   Structured local logs on both platforms.
-   No crash when a target application is missing.

## 11. Security Requirements

-   Bind Wi-Fi server to local interfaces only unless explicitly
    changed.
-   Never expose an unauthenticated command endpoint.
-   Pairing requires user confirmation on the Mac.
-   Tokens are random, revocable, and device-specific.
-   Secrets never appear in normal logs.
-   Reject protocol versions that cannot be safely handled.
-   Validate all message fields and maximum payload sizes.
-   Maintain a strict action allowlist.
-   Registered scripts store local paths/arguments on Mac; Android
    references only their IDs.
-   Sensitive macOS capabilities should be disabled until required
    permissions are granted.
-   Provide a "Revoke device" control.

## 12. UX Requirements

### Android

-   Large touch targets.
-   Fast pressed-state animation.
-   Optional haptic feedback.
-   Connection indicator.
-   Offline/reconnecting state that does not destroy the current layout.
-   Portrait and landscape support where practical.
-   Dark UI suitable for a permanently docked display.
-   Configurable low-brightness/keep-awake behavior.
-   Avoid expensive blur, excessive animation, and constant
    recomposition on old hardware.

### macOS

-   Menu-bar agent.
-   Connection status.
-   Connected device list.
-   Pair/revoke controls.
-   Permission status.
-   Start-at-login option.
-   Transport status: USB / LAN.
-   Basic profile/action editor by v1.x.

## 13. Data Model

Core entities:

-   `Device`
-   `Profile`
-   `Page`
-   `Control`
-   `Action`
-   `ActionBinding`
-   `ConnectionSession`
-   `AppProfileRule`
-   `Settings`

A `Control` references an `ActionBinding`; the actual executable
definition lives on the Mac.

## 14. MVP Acceptance Criteria

The MVP is complete when all of the following pass:

1.  Fresh Mac install launches a menu-bar agent.
2.  Fresh Android install can pair over LAN.
3.  A 12-button profile appears on Android.
4.  Launch-app works for at least Finder, Terminal, and a configured
    third-party app.
5.  Keyboard shortcut execution works after permission grant.
6.  Media and volume actions work.
7.  Disconnecting Wi-Fi shows reconnecting state without crashing.
8.  Reconnection restores the active profile.
9.  USB ADB forwarding works without LAN connectivity.
10. Unknown action IDs are rejected.
11. A revoked Android token can no longer authenticate.
12. A registered script can execute, but an arbitrary script path from
    Android cannot.
13. Foreground app changes can switch between at least two profiles.
14. Logs make failed actions diagnosable without exposing secrets.

## 15. Release Definition

### v0.1 --- Vertical slice

LAN WebSocket, static 3x4 deck, launch-app action.

### v0.2 --- Useful deck

Authentication, keypress, media, volume, lock, reconnect.

### v0.3 --- USB-first

ADB forwarding, transport detection, USB test suite.

### v0.4 --- Dynamic deck

Mac-owned profiles, synchronization, foreground-app switching.

### v1.0 --- Daily-driver

Security hardening, permissions UX, persistent configuration, logs,
recovery behavior, installer/signing strategy, performance validation,
documentation.
