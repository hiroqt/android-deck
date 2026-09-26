# NotchDeck --- AGENTS.md

This file defines how coding agents should work in the NotchDeck
repository.

## 1. Mission

Build NotchDeck as a secure, low-latency Android-to-macOS control surface.
Preserve the architectural rule that Android requests named actions
while macOS owns executable definitions and permissions.

Agents must optimize for: 1. correctness 2. security 3. responsiveness
4. recoverability 5. maintainability

Do not trade security for convenience.

## 2. Read Before Coding

Before changing code, read:

1.  `docs/prd.md`
2.  `docs/architecture.md`
3.  `docs/design.md`
4.  `protocol/protocol.md` if present
5.  Relevant tests in the target module

If implementation and documentation disagree, do not silently invent a
third behavior. Update the relevant design/ADR as part of the change.

## 3. Repository Ownership

``` text
/android      Android client
/macos        macOS host agent
/protocol     shared wire contract and examples
/docs         product/architecture/design decisions
/tests        cross-platform fixtures and E2E material
/scripts      development and USB helper scripts
```

Do not introduce a third backend/cloud service without an explicit
architecture decision.

## 4. Architectural Invariants

Agents MUST preserve these rules:

-   The Mac is authoritative for actions and profiles.
-   Android never sends arbitrary shell source for execution.
-   All action messages require an authenticated session.
-   All protocol messages are versioned.
-   WebSocket is persistent; do not replace action taps with one HTTP
    request per press.
-   USB and LAN share the same application protocol.
-   Secrets use Keychain/Keystore-backed storage.
-   Network receive loops never block on long-running automation.
-   The Android UI gives immediate local feedback before remote
    acknowledgement.
-   Unknown action IDs fail closed.
-   Missing macOS permissions produce typed errors.
-   Reconnect triggers state/profile resynchronization.

## 5. Coding Conventions

### Kotlin/Android

-   Prefer immutable UI state.
-   Use coroutines and Flow/StateFlow.
-   Keep network code out of Composables.
-   No blocking I/O on the main thread.
-   Keep Composables small and previewable.
-   Model connection state explicitly.
-   Serialization models belong in the protocol/model layer.
-   Do not log tokens.

### Swift/macOS

-   Use structured concurrency.
-   UI mutations belong on `MainActor`.
-   Keep action handlers behind a common protocol.
-   Do not execute `Process` directly from networking code.
-   Validate all registered action parameters before execution.
-   Wrap OS integrations behind adapters so they can be tested.
-   Do not log tokens, pairing codes, or sensitive command arguments.

## 6. Protocol Change Rules

Any wire-protocol change requires:

1.  Update protocol schema/documentation.
2.  Add or update fixture JSON.
3.  Add decoder/encoder tests on both platforms where applicable.
4.  Define backward compatibility behavior.
5.  Increment protocol version only when compatibility requires it.

Never make Android and Mac depend on undocumented field behavior.

## 7. Security Rules

Never implement:

``` text
/run?command=<arbitrary string>
```

or the WebSocket equivalent.

Instead:

``` text
action.invoke(controlId="dev-vscode", event="tap")
```

The Mac resolves the binding and registered action locally.

For registered scripts: - Store executable/script path on Mac. - Use an
allowlisted action ID. - Validate configurable arguments by declared
type. - Define timeout. - Capture bounded stdout/stderr for
diagnostics. - Do not use a shell unless shell semantics are explicitly
required. - Prefer direct process arguments over string concatenation.

## 8. Permission Rules

Do not request all macOS permissions at first launch.

Request or explain permissions when a feature needs them. The
application must remain usable for actions that do not require elevated
capabilities.

Tests should cover: - permission granted - permission denied -
permission revoked after previously being granted

## 9. Performance Rules

For touch actions: - Android pressed state must not wait for network. -
Avoid expensive recomposition of the full grid. - Reuse/cached icon
assets. - Keep action payloads small. - Avoid polling when event-driven
state is available. - Rate-limit high-frequency controls such as
sliders. - Measure latency before optimizing speculative bottlenecks.

When adding an action, consider: - serialization cost - queueing - OS
automation latency - whether execution blocks other actions

## 10. Error Contract

Prefer typed errors such as:

``` text
AUTH_REQUIRED
AUTH_INVALID
ACTION_UNKNOWN
ACTION_DISABLED
PERMISSION_REQUIRED
APP_NOT_FOUND
SCRIPT_TIMEOUT
INVALID_PAYLOAD
PROTOCOL_UNSUPPORTED
INTERNAL_ERROR
```

Android should map these to human-readable UI. Raw platform exceptions
should not cross the protocol boundary.

## 11. Testing Expectations

Every feature should add the smallest useful test layer.

### Required before merge

-   Unit tests for business logic.
-   Protocol fixture test for new message shapes.
-   Integration test for networking/auth changes.
-   Manual E2E checklist entry for OS-level automation.

### Critical E2E flows

1.  Fresh pairing.
2.  Reconnect.
3.  Token revocation.
4.  LAN action execution.
5.  USB/ADB action execution.
6.  Profile sync.
7.  Foreground-app profile change.
8.  Permission-denied action.
9.  Registered script execution.
10. Malformed/unknown action rejection.

## 12. Definition of Done

A task is not done until:

-   Code compiles on its target platform.
-   Relevant tests pass.
-   No new secret or unsafe command path exists.
-   Errors are surfaced intentionally.
-   Documentation is updated if behavior changed.
-   Manual test steps are recorded for OS/device-dependent behavior.
-   No debug-only endpoint is enabled in release configuration.

## 13. Commit Strategy

Prefer small vertical commits:

``` text
feat(protocol): add action result envelope
feat(macos): implement launch app handler
feat(android): render action result feedback
test(e2e): cover launch app over websocket
```

Avoid combining broad refactors with new protocol behavior unless
necessary.

## 14. Implementation Order for Agents

Agents should work in this order unless a task explicitly says
otherwise:

### Phase 0 --- Foundation

-   Monorepo structure.
-   Build both apps.
-   Shared protocol documentation/fixtures.
-   Logging conventions.
-   CI build/test skeleton.

### Phase 1 --- LAN vertical slice

-   Mac WebSocket server.
-   Android WebSocket client.
-   Connection state machine.
-   Static 3x4 grid.
-   `launch_app`.
-   action result acknowledgement.

### Phase 2 --- Trust

-   Pairing.
-   Token issuance/storage.
-   Auth handshake.
-   Device revocation.
-   Payload validation.

### Phase 3 --- Core actions

-   URL.
-   Keypress.
-   Media.
-   Volume.
-   Lock/sleep.
-   Registered script.
-   Permission manager.

### Phase 4 --- USB

-   ADB helper scripts.
-   USB transport selection.
-   No-LAN E2E test.
-   reconnect/unplug behavior.

### Phase 5 --- Server-owned configuration

-   Profile model.
-   Profile snapshot.
-   revisioning.
-   Android dynamic rendering.
-   local persistence.

### Phase 6 --- Dynamic context

-   foreground app observer.
-   app-profile rules.
-   profile pinning.
-   state updates.

### Phase 7 --- Daily-driver hardening

-   start at login.
-   diagnostics.
-   timeout/cancellation.
-   installers/signing.
-   performance instrumentation.
-   battery/display dock mode.
-   documentation.

## 15. Do Not Overbuild

For v1, avoid: - cloud accounts - public internet access - plugin
marketplace - scripting language embedded in Android - complex database
infrastructure - animated dashboard framework - full mouse/keyboard
remote control

Prove the 12-button daily-driver experience first.

## 16. Agent Handoff Template

When handing work to another agent, provide:

``` text
Goal:
Files changed:
Protocol impact:
Security impact:
Permissions impact:
Tests added/run:
Manual test remaining:
Known limitations:
Next recommended task:
```

## 17. First Vertical Slice

The first complete slice is:

``` text
Mac starts WebSocket server
        ↓
Android connects over LAN
        ↓
Mac sends static Developer profile
        ↓
Android renders 3x4 grid
        ↓
Tap "VS Code"
        ↓
action.invoke(controlId)
        ↓
Mac resolves registered launch_app
        ↓
NSWorkspace launches app
        ↓
action.result(success)
        ↓
Android confirms with haptic/visual feedback
```

Do not add USB, dynamic profiles, or shell actions until this path is
stable and tested.
