# MacDeck E2E Planning Package

This package contains the implementation documentation for building an
old Android phone into a native, low-latency Stream Deck-style control
surface for macOS.

## Documents

-   `prd.md` --- product scope, requirements, acceptance criteria,
    security and release definition.
-   `architecture.md` --- Android/macOS architecture, protocol,
    transport, data ownership, security boundaries and testing
    architecture.
-   `design.md` --- Android deck UX, macOS menu-bar/settings UX,
    profiles, states, pairing, accessibility and dock-mode design.
-   `agents.md` --- coding-agent operating rules, invariants,
    implementation order, testing and definition of done.
-   `implementation-plan.md` --- phased end-to-end delivery plan from
    repository setup through USB, dynamic profiles, hardening and v1.0.

## Recommended stack

-   Android: Kotlin + Jetpack Compose
-   macOS: Swift + SwiftUI/AppKit
-   Transport: persistent WebSocket
-   USB: ADB TCP tunnel
-   LAN: local WebSocket fallback
-   Protocol: versioned JSON
-   Secrets: Android Keystore-backed storage + macOS Keychain
-   Configuration authority: macOS

## Start Here

Implement the LAN vertical slice first:

1.  Mac starts WebSocket server.
2.  Android connects.
3.  Mac sends a static 3x4 profile.
4.  Android renders it.
5.  Tap sends `action.invoke`.
6.  Mac resolves `launch_app`.
7.  Mac executes via native API.
8.  Mac returns `action.result`.
9.  Android gives immediate haptic/visual feedback.

After that path is stable, add pairing/authentication, core actions,
USB/ADB, server-owned profiles, and context-aware switching.
