# MacDeck --- End-to-End Implementation Plan

## 1. Delivery Strategy

Build MacDeck as vertical slices. Each phase should leave the product
runnable rather than producing disconnected subsystems.

The critical path is:

``` text
Build apps
  -> define protocol
  -> connect over LAN
  -> execute one safe action
  -> secure pairing/auth
  -> add core actions
  -> add USB
  -> server-owned profiles
  -> dynamic context
  -> harden/release
```

## 2. Prerequisites

### Hardware

-   Mac development machine.
-   Android phone.
-   USB data cable.
-   Same local network for early LAN development.

### macOS development

-   Xcode.
-   Swift toolchain.
-   Apple developer signing setup when distribution work begins.
-   Android platform-tools (`adb`) for USB phase.

### Android development

-   Android Studio.
-   Android SDK matching the chosen minimum/target SDK.
-   USB debugging enabled on the test phone.
-   Developer Options enabled.

### Repository

-   Git.
-   CI provider of choice.
-   No cloud runtime dependency is required.

## 3. Phase 0 --- Repository and Build Foundation

### Tasks

-   Create monorepo structure.
-   Create Android app.
-   Create macOS menu-bar app.
-   Add `docs/`.
-   Add `protocol/`.
-   Add `.editorconfig`, ignore files, contribution/build instructions.
-   Add structured logging wrappers.
-   Add CI jobs that compile/test platform projects where runners allow.
-   Decide minimum Android and macOS versions based on actual target
    devices.

### Exit criteria

-   Android debug build installs and opens.
-   Mac app builds and appears in menu bar.
-   CI can run basic unit tests.
-   Both apps display build/version information.

## 4. Phase 1 --- Protocol v1

### Tasks

Define the envelope:

``` json
{
  "protocolVersion": 1,
  "type": "hello",
  "requestId": "uuid",
  "payload": {}
}
```

Define: - hello - ping/pong - profile.snapshot - action.invoke -
action.result - error

Add JSON fixtures and tests on both platforms.

### Exit criteria

-   Both apps decode the same fixtures.
-   Invalid type/version/payload produces deterministic errors.
-   Maximum message size is enforced.

## 5. Phase 2 --- LAN Vertical Slice

### macOS

-   Start WebSocket listener on configurable local port, e.g. 8765.
-   Add connection/session manager.
-   Add static profile provider.
-   Add action router.
-   Implement `launch_app` using bundle identifier.

### Android

-   Add Mac address/port dev configuration.
-   Add WebSocket client.
-   Implement connection state machine.
-   Receive profile.
-   Render 3x4 grid.
-   Send `action.invoke`.
-   Show immediate pressed state and haptic.
-   Handle `action.result`.

### E2E

Tap VS Code/Finder/Terminal and verify launch.

### Exit criteria

-   100 consecutive taps/actions do not crash either side.
-   Reopening Android reconnects.
-   Mac restart produces a recoverable Android state.
-   Median local action latency is recorded as a baseline.

## 6. Phase 3 --- Pairing and Authentication

### macOS

-   Pairing mode.
-   Short-lived six-digit code.
-   Random device token generation.
-   Keychain persistence.
-   Device record and revocation.
-   Reject action messages before auth.

### Android

-   Pairing screen.
-   Token persistence using Keystore-backed mechanism.
-   Auth handshake.
-   Re-pair UI for revoked/invalid credentials.

### Security tests

-   Wrong code.
-   Expired code.
-   Missing token.
-   Invalid token.
-   Revoked token.
-   Action before auth.
-   Oversized payload.

### Exit criteria

No action executes without an authenticated session.

## 7. Phase 4 --- Core Action Framework

Implement common handler protocol and registry.

### Actions

1.  `launch_app`
2.  `open_url`
3.  `keypress`
4.  `media_control`
5.  `volume`
6.  `system_action`
7.  `run_shortcut`
8.  `run_script` for pre-registered scripts only

### Permission manager

-   Detect/report required capabilities.
-   Add menu-bar/settings permission status.
-   Return `PERMISSION_REQUIRED`.

### Registered script design

Example:

``` json
{
  "id": "start-present-po",
  "type": "run_script",
  "executable": "/usr/bin/env",
  "arguments": ["npm", "run", "dev"],
  "workingDirectory": "/Users/.../project",
  "timeoutSeconds": 30
}
```

This definition lives only on Mac. Android sees `start-present-po`.

### Exit criteria

Core actions have typed results and cannot be used to smuggle arbitrary
shell input.

## 8. Phase 5 --- Reconnection and Reliability

### Tasks

-   Heartbeat.
-   Stale connection detection.
-   Bounded exponential reconnect.
-   Session restoration.
-   Last-known profile cache.
-   Profile revision.
-   Request correlation.
-   Duplicate request handling policy.
-   Timeouts.
-   App missing/error handling.

### Exit criteria

Test: - disable/enable Wi-Fi. - sleep/wake phone. - sleep/wake Mac. -
stop/restart MacDeck. - change Mac IP. - reconnect without app restart
where possible.

## 9. Phase 6 --- USB/ADB Transport

Do this only after LAN behavior is stable.

### Tasks

-   Install/document platform-tools.
-   Determine tested ADB tunnel direction based on the final listener
    topology.
-   Add helper script such as `scripts/usb/connect.sh`.
-   Android connects to the tunneled localhost endpoint.
-   Add transport selector: Auto / USB / LAN.
-   Detect USB loss.
-   Optional fallback to LAN.

### Test matrix

-   USB only; Wi-Fi disabled.
-   Unplug while connected.
-   Replug.
-   Android authorization revoked.
-   Bad USB cable/data unavailable.
-   Mac agent restart.
-   ADB process restart.

### Exit criteria

A full action flow works with Wi-Fi disabled.

## 10. Phase 7 --- Mac-Owned Profiles

### Models

-   Profile
-   Page
-   Control
-   Binding
-   RegisteredAction
-   AppProfileRule

### Tasks

-   JSON persistence.
-   Schema validation.
-   Profile revisions.
-   `profile.snapshot`.
-   `profile.changed`.
-   Android generic rendering.
-   Last-known-good profile fallback.
-   Starter profiles.

### Exit criteria

Change a profile on Mac and update Android without rebuilding the APK.

## 11. Phase 8 --- Dynamic Context

### macOS

Use NSWorkspace/appropriate observers to identify foreground app.

### Tasks

-   Bundle-ID-to-profile rules.
-   Priority/conflict behavior.
-   Debounce rapid changes.
-   `profile.changed`.
-   Android transition.
-   Manual profile pin.
-   Disable auto-switch option.

### Exit criteria

Switch between VS Code and browser and observe deterministic profile
changes.

## 12. Phase 9 --- Rich Controls and State

After buttons are stable:

-   Long press.
-   Double tap.
-   Sliders.
-   Toggle controls.
-   Mac-to-phone state changes.
-   Volume state.
-   Active app.
-   Optional media metadata.
-   Optional CPU/RAM widgets.

For high-frequency controls, rate-limit intermediate values and send a
final value on release.

## 13. Phase 10 --- Mac Configuration UX

Start simple; avoid blocking the product on a sophisticated editor.

### v0

JSON-backed configuration + validation.

### v1

Native editor: - Profile list. - Grid preview. - Add/remove/reorder
control. - Icon/label. - Choose registered action. - Configure event
binding. - App-profile rules. - Import/export.

### Exit criteria

A normal user can create a profile without editing source code.

## 14. Phase 11 --- Diagnostics

### Android diagnostics

-   App version.
-   Protocol version.
-   Connection state.
-   Transport.
-   Last error.
-   Latency sample.
-   Mac identity.
-   Clear/re-pair.

### Mac diagnostics

-   App version.
-   Listening endpoint.
-   Connected device.
-   Auth state.
-   Permission state.
-   Last action result.
-   Latency timing.
-   Sanitized logs.

Add an exportable diagnostics bundle only if needed later; redact
secrets.

## 15. Phase 12 --- Performance Pass

Instrument:

``` text
T0 touch received
T1 message queued
T2 message sent
T3 Mac received
T4 validation complete
T5 action started
T6 action completed
T7 result sent
T8 Android received
```

Optimize based on measurements.

Likely priorities: - keep WebSocket alive. - avoid main-thread
blocking. - minimize Compose recomposition. - cache icons. - keep
payloads small. - avoid spawning shell processes for actions that have
native APIs. - avoid excessive state polling.

## 16. Phase 13 --- Security Hardening

Checklist: - Threat-model LAN attacker. - Validate JSON/schema. - Cap
payload size. - Rate-limit pairing attempts. - Expire pairing codes. -
Random high-entropy device tokens. - Keychain/Keystore. - Revoke
devices. - No tokens in logs. - No arbitrary remote shell. - Validate
URL schemes. - Validate registered script parameters. - Time out child
processes. - Review macOS entitlements. - Disable debug endpoints in
release. - Document local-network exposure.

## 17. Phase 14 --- Packaging and Daily-Driver Release

### macOS

-   App icon.
-   Menu-bar behavior.
-   Start at login.
-   Code signing/notarization if distributed.
-   Clear permission onboarding.
-   Upgrade-safe configuration.

### Android

-   Release build.
-   Stable package ID.
-   Keep-awake/dock mode.
-   Battery optimization guidance where necessary.
-   Reconnect after process recreation.
-   Orientation policy.
-   Old-device performance check.

## 18. Test Matrix

  Area          Test
  ------------- ------------------------------
  Pairing       new device succeeds
  Pairing       wrong/expired code fails
  Auth          valid token succeeds
  Auth          revoked token fails
  Protocol      malformed JSON rejected
  Protocol      unsupported version rejected
  Action        launch app
  Action        keypress
  Action        media
  Action        volume
  Action        registered script
  Permission    missing Accessibility
  Reliability   Mac restart
  Reliability   Android restart
  Reliability   Wi-Fi drop
  USB           Wi-Fi disabled
  USB           cable unplug/replug
  Profiles      update without APK rebuild
  Context       active app changes profile
  Security      unknown action rejected
  Performance   latency measurement
  Device        screen awake/dim behavior

## 19. Suggested Sprint Breakdown

### Sprint 1

Repo, Android shell, Mac menu-bar shell, protocol fixtures.

### Sprint 2

LAN WebSocket + static deck + launch app.

### Sprint 3

Pairing/auth + reconnect.

### Sprint 4

Core action registry + permissions.

### Sprint 5

USB/ADB transport.

### Sprint 6

Mac-owned profiles + Android dynamic rendering.

### Sprint 7

Foreground-app switching + profile pinning.

### Sprint 8

Rich controls, diagnostics, performance/security pass.

### Sprint 9

Editor, packaging, release hardening.

## 20. First 12-Button MVP

``` text
┌────────┬────────┬────────┐
│ VSCode │ Browser│ Finder │
├────────┼────────┼────────┤
│Terminal│ ChatGPT│ Music  │
├────────┼────────┼────────┤
│ Mute   │ Play   │ Next   │
├────────┼────────┼────────┤
│Desktop │ Lock   │ Sleep  │
└────────┴────────┴────────┘
```

For the earliest vertical slice, implement only the first row if needed.
The goal is to prove the entire path before broadening action coverage.

## 21. Definition of v1.0

MacDeck v1.0 is ready when: - Android and Mac install cleanly. - Pairing
is explicit and secure. - USB works without Wi-Fi. - LAN fallback is
reliable. - Profiles are Mac-owned and editable. - Core actions are
stable. - Foreground-app profile switching is reliable. - Permissions
are understandable. - Arbitrary remote shell execution is impossible by
design. - Reconnect/restart scenarios recover automatically. - Measured
interaction latency feels immediate on the target old Android phone. -
Documentation and E2E test checklist are current.
