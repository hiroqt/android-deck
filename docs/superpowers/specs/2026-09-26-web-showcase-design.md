# Web Showcase Architecture & Design Specification: MacDeck & NotchDeck

**Date**: 2026-09-26  
**Status**: Approved  
**Author**: Pair Programming AI & User  

---

## 1. Executive Summary & Goals

The goal of this project is to build an authentic, high-craft web showcase for **MacDeck & NotchDeck** inside a dedicated `web/` directory.

The website mirrors the smooth Lenis scrolling, spring physics, and aesthetic refinement of the sample landing page, while adhering to strict design constraints:
1. **Pure Off-White Palette**: `#f9fafd` solid background across the entire page and every section. Strictly no gradient fills, gradient text, glowing neon LEDs, pulse animations, or eyebrow tags.
2. **Zero Emojis**: Every visual element is rendered using authentic UI representations, typography, or clean Hugeicons (`@hugeicons/react`).
3. **100% Authentic Dual Mockups**: Side-by-side interactive mockups of both the **macOS NotchDeck** (camera notch expanding into a 6-slot liquid glass configurator) and the **Android MacDeck** client (exact Jetpack Compose 6-tile stream deck surface).
4. **Live Cross-Device Sync**: Tapping an app on the phone fires an instant Mac application launch event. Reassigning or clearing a slot in the Mac notch immediately updates the phone's 6 tiles over a simulated WebSocket wire protocol.
5. **Modern Tech Stack**: React 19, Next.js 15 App Router, Tailwind CSS v4, `motion` (Framer Motion v12), Hugeicons, and local Poppins typography.

---

## 2. Directory Structure

```text
web/
├── app/
│   ├── layout.tsx                # Root layout: Poppins font, Lenis smooth scroll, Custom Cursor
│   ├── page.tsx                  # Showcase landing page combining all sections
│   ├── globals.css               # Pure off-white palette, Tailwind v4 tokens
│   └── components/
│       ├── SmoothScroll.tsx      # Lenis smooth scroll provider
│       ├── PrecisionCursor.tsx   # Geometric dual-ring cursor follower with inertia
│       ├── TopNotchIsland.tsx    # Interactive top notch: expands to 6-slot HUD
│       ├── DualInteractiveStage.tsx # Side-by-side Mac & Android phone simulator
│       ├── DesktopNotchMockup.tsx# 100% authentic macOS NotchDeck UI
│       ├── PhoneDeckMockup.tsx   # 100% authentic Android MacDeck Jetpack Compose UI
│       ├── HowItWorks.tsx        # 3-step physical workflow cards
│       ├── ArchitectureGrid.tsx  # Core engineering pillars
│       ├── TerminalCommands.tsx  # Interactive command runner with one-click copy
│       ├── FaqAccordion.tsx      # Clean accordion for technical questions
│       └── SiteFooter.tsx        # Minimal footer with version specs and links
├── public/
│   └── assets/
│       ├── Poppins-Regular.ttf
│       ├── Poppins-SemiBold.ttf
│       └── Poppins-Bold.ttf
├── package.json
├── tsconfig.json
├── next.config.ts
└── postcss.config.mjs
```

---

## 3. Visual System & Aesthetic Tokens

* **Background**: Solid `#f9fafd` across all sections.
* **Cards & Surfaces**: Clean white `#ffffff` with `1px solid #e7ebf2` borders, rounded squircle corners (`24px` to `32px`), and subtle diffused shadows (`0 12px 30px rgba(16, 25, 47, 0.05)`).
* **Typography**: Poppins (Regular 400, SemiBold 600, Bold 700).
* **Primary Inks**: Headings `#101828`, body text `#475467`, metadata `#98a2b3`.
* **Solid Accents**: Graphite `#1d2939` for primary actions; emerald `#039855` for solid connection indicators.
* **Prohibitions**: No emojis, no gradient backgrounds, no pulsating glows, no neon lighting, no pill eyebrow banners.

---

## 4. Component Details & Interactive Behavior

### 4.1 Top Notch Island (`TopNotchIsland.tsx`)
* Anchored at top-center of the browser viewport.
* Collapsed: `184px × 34px` pill with simulated camera lens and solid connection status (`USB Connected`).
* Expanded: Springs open downward to `540px × 196px` revealing the 6-slot configurator HUD.
* Allows adding and clearing apps; updates broadcast to the interactive phone simulator.

### 4.2 Dual Interactive Stage (`DualInteractiveStage.tsx`)
* **Desktop Frame (`DesktopNotchMockup.tsx`)**:
  * Shows authentic macOS NotchDeck HUD with 6 slots (`3×2` grid).
  * Each card has macOS app icon, slot title, bundle ID, and red minus (`-`) badge to clear slot.
  * Empty slot has dashed border and plus (`+`) button to assign an app.
  * Displays real-time macOS execution toast when an app is triggered from the phone.
* **Phone Frame (`PhoneDeckMockup.tsx`)**:
  * Shows authentic Android MacDeck client matching Jetpack Compose implementation (`DeckScreen.kt`, `ConnectionBar.kt`, `DeckAppTile.kt`).
  * Top bar shows `USB Connected • 127.0.0.1:8765`, rotating sync icon, settings icon.
  * 6 large app tiles with authentic icons.
  * Immediate mechanical press animation (`scale: 0.93`, active border, elevation drop in <16ms).
  * Toggle between Portrait (2×3) and Landscape (3×2).

### 4.3 Smooth Scrolling & Precision Cursor
* `lenis` v1.3+ integration with `lerp: 0.085`.
* Geometric SVG ring and center dot cursor with inertia and magnetic scaling on interactive buttons.

---

## 5. Page Sections & Content Flow

1. **Top Notch Island**: Persistent interactive HUD at top of screen.
2. **Site Header**: Brand `macdeck.`, anchor links, Launch HUD trigger.
3. **Hero & Dual Stage**: Bold headline, copy-command button, and the side-by-side interactive Mac and Phone mockups.
4. **How It Works**: 3 physical workflow steps (Connect, Configure in Notch, Tap to Execute).
5. **Architecture & Engineering Pillars**: 4 technical cards (Native AppKit, ADB Reverse Tunnel, Action ID Sandboxing, Adaptive Grid Engine).
6. **Terminal Command Palette**: Tabbed terminal with one-click copy (`run_mac.sh`, `run_notchdeck.sh`, `connect.sh`, `install_android.sh`, test suite).
7. **FAQ Accordion**: 5 technical questions with clean Hugeicon toggles.
8. **Footer**: Platform support, protocol version `v1.0.0`, GitHub link.

---

## 6. Verification Plan

* TypeScript compilation (`tsc --noEmit`).
* Next.js build verification (`next build`).
* Automated emoji audit to guarantee 0 emojis across all files.
* Palette audit ensuring pure `#f9fafd` background consistency.
* Cross-device synchronization verification between Mac Notch and Phone tiles.
