# Web Showcase for MacDeck & NotchDeck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, 100% authentic web showcase for MacDeck & NotchDeck in a dedicated `web/` directory using Next.js 15, React 19, Tailwind CSS v4, Framer Motion v12, Hugeicons, and Poppins font family, featuring Lenis smooth scrolling, precision cursor hover effects, pure solid off-white background, and side-by-side interactive mockups of the Android client and macOS NotchDeck.

**Architecture:** A static-optimized Next.js App Router application in `web/` structured around an interactive cross-device state manager. The persistent Top Notch HUD and the Hero Phone & Desktop side-by-side simulators share a unified 6-slot state: tapping an app on the Android phone immediately executes an action on the macOS screen, and modifying slots in the macOS NotchDeck immediately synchronizes the Android stream deck tiles.

**Tech Stack:** Next.js 15, React 19, TypeScript, Tailwind CSS v4 (`@tailwindcss/postcss`), `motion` (Framer Motion `motion/react`), `lenis`, `@hugeicons/react`, `@hugeicons/core-free-icons`, Poppins local webfonts.

**Spec:** [`docs/superpowers/specs/2026-09-26-web-showcase-design.md`](file:///Users/arnel/android-deck/docs/superpowers/specs/2026-09-26-web-showcase-design.md)

## Global Constraints

- Solid off-white palette `#f9fafd` across the entire page and every section. No gradient backgrounds, gradient text, or color shifts between sections.
- Strictly zero emojis in code, copy, alt texts, UI elements, or comments.
- No glowing neon LEDs, pulsating dots, or artificial sparkles.
- No pill eyebrow tags above section headings.
- 100% visual fidelity to the real Android Jetpack Compose app and the native AppKit/SwiftUI NotchDeck configurator.

---

### Task 1: Scaffolding Next.js Project & Dependencies

**Files:**
- Create: `web/package.json`
- Create: `web/tsconfig.json`
- Create: `web/next.config.ts`
- Create: `web/postcss.config.mjs`
- Create: `web/public/assets/Poppins-Regular.ttf`
- Create: `web/public/assets/Poppins-SemiBold.ttf`
- Create: `web/public/assets/Poppins-Bold.ttf`

**Interfaces:**
- Consumes: Local font binaries from `/Users/arnel/nvidia-hackathon/web/public/assets/`
- Produces: Working Next.js development environment in `web/`

- [ ] **Step 1: Create `web/package.json`**

```json
{
  "name": "macdeck-showcase",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "tsc --noEmit"
  },
  "dependencies": {
    "@hugeicons/core-free-icons": "^4.3.5",
    "@hugeicons/react": "^1.1.10",
    "lenis": "^1.3.26",
    "motion": "^12.23.24",
    "next": "^15.5.4",
    "react": "^19.1.1",
    "react-dom": "^19.1.1",
    "tailwindcss": "^4.1.13"
  },
  "devDependencies": {
    "@tailwindcss/postcss": "^4.1.13",
    "@types/node": "^22.18.6",
    "@types/react": "^19.1.13",
    "@types/react-dom": "^19.1.9",
    "typescript": "^5.9.2"
  }
}
```

- [ ] **Step 2: Create `web/tsconfig.json`, `web/next.config.ts`, and `web/postcss.config.mjs`**

`web/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

`web/next.config.ts`:
```typescript
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
};

export default nextConfig;
```

`web/postcss.config.mjs`:
```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  },
};
```

- [ ] **Step 3: Copy Poppins font binaries and install npm dependencies**

Run:
```bash
mkdir -p web/public/assets
cp /Users/arnel/nvidia-hackathon/web/public/assets/Poppins-*.ttf web/public/assets/
cd web && npm install
```

- [ ] **Step 4: Verify package setup**

Run:
```bash
cd web && ls -la public/assets/Poppins*.ttf && npm ls next react tailwindcss
```
Expected: All three font files present, packages resolved without errors.

- [ ] **Step 5: Commit**

```bash
git add web/package.json web/tsconfig.json web/next.config.ts web/postcss.config.mjs web/public/assets
git commit -m "chore(web): initialize Next.js 15 project with dependencies and Poppins fonts"
```

---

### Task 2: Design Tokens, Global CSS, Smooth Scrolling & Precision Cursor

**Files:**
- Create: `web/app/globals.css`
- Create: `web/app/components/SmoothScroll.tsx`
- Create: `web/app/components/PrecisionCursor.tsx`
- Create: `web/app/layout.tsx`

**Interfaces:**
- Consumes: Poppins TTF files, `lenis`, Tailwind v4
- Produces: Base layout, smooth scroll mechanics, and geometric cursor follower

- [ ] **Step 1: Write `web/app/globals.css`**

Configure `@font-face` for Poppins, Tailwind v4 `@import "tailwindcss";`, pure off-white color variables, and cursor styling:
```css
@import "tailwindcss";

@font-face {
  font-family: 'Poppins';
  src: url('/assets/Poppins-Regular.ttf') format('truetype');
  font-style: normal;
  font-weight: 400;
  font-display: swap;
}

@font-face {
  font-family: 'Poppins';
  src: url('/assets/Poppins-SemiBold.ttf') format('truetype');
  font-style: normal;
  font-weight: 600;
  font-display: swap;
}

@font-face {
  font-family: 'Poppins';
  src: url('/assets/Poppins-Bold.ttf') format('truetype');
  font-style: normal;
  font-weight: 700;
  font-display: swap;
}

:root {
  --bg-page: #f9fafd;
  --surface-white: #ffffff;
  --border-subtle: #e5e9f2;
  --border-card: #dbe2ea;
  --ink-primary: #101828;
  --ink-secondary: #475467;
  --ink-muted: #98a2b3;
  --ink-slate: #1d2939;
  --accent-green: #039855;
  --font-poppins: 'Poppins', -apple-system, BlinkMacSystemFont, sans-serif;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
  scroll-padding-top: 80px;
  overflow-x: hidden;
  background-color: var(--bg-page);
}

body {
  margin: 0;
  background-color: var(--bg-page);
  color: var(--ink-primary);
  font-family: var(--font-poppins);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  overflow-x: hidden;
}

.shell {
  width: min(1200px, calc(100% - 48px));
  margin-inline: auto;
}

/* Precision Geometric Cursor */
.precision-cursor {
  position: fixed;
  inset: 0;
  z-index: 10000;
  pointer-events: none;
  opacity: 0;
  transition: opacity 0.25s ease;
}

.cursor-ring {
  position: absolute;
  width: 32px;
  height: 32px;
  margin: -16px;
  border-radius: 50%;
  border: 1.5px solid rgba(29, 41, 57, 0.45);
  pointer-events: none;
  will-change: transform;
  transition: width 0.2s cubic-bezier(0.16, 1, 0.3, 1),
              height 0.2s cubic-bezier(0.16, 1, 0.3, 1),
              margin 0.2s cubic-bezier(0.16, 1, 0.3, 1),
              border-color 0.2s ease;
}

.cursor-dot {
  position: absolute;
  width: 5px;
  height: 5px;
  margin: -2.5px;
  border-radius: 50%;
  background: var(--ink-slate);
  pointer-events: none;
  will-change: transform;
}

.precision-cursor[data-hover="true"] .cursor-ring {
  width: 48px;
  height: 48px;
  margin: -24px;
  border-color: rgba(29, 41, 57, 0.85);
  background: rgba(29, 41, 57, 0.05);
}

@media (hover: hover) and (pointer: fine) and (prefers-reduced-motion: no-preference) {
  html.has-precision-cursor,
  html.has-precision-cursor * {
    cursor: none !important;
  }
  html.has-precision-cursor :is(input, textarea, [contenteditable="true"]) {
    cursor: text !important;
  }
}
```

- [ ] **Step 2: Create `web/app/components/SmoothScroll.tsx`**

Integrates Lenis with reduced motion checks and data-native-scroll attribute support:
```tsx
'use client';

import { useEffect } from 'react';
import Lenis from 'lenis';

export default function SmoothScroll() {
  useEffect(() => {
    const preference = window.matchMedia('(prefers-reduced-motion: reduce)');
    let scroll: Lenis | undefined;

    const configure = () => {
      scroll?.destroy();
      scroll = undefined;
      if (!preference.matches) {
        scroll = new Lenis({
          autoRaf: true,
          lerp: 0.085,
          smoothWheel: true,
          syncTouch: false,
          anchors: true,
          prevent: (element) => element.hasAttribute('data-native-scroll'),
        });
      }
    };

    configure();
    preference.addEventListener('change', configure);
    return () => {
      scroll?.destroy();
      preference.removeEventListener('change', configure);
    };
  }, []);

  return null;
}
```

- [ ] **Step 3: Create `web/app/components/PrecisionCursor.tsx`**

Implements smooth dual-ring geometric tracking with inertia without emojis:
```tsx
'use client';

import { useEffect, useRef } from 'react';

const interactiveSelector = 'a, button:not(:disabled), summary, [role="button"], input, select';
const nativeSelector = 'input, textarea, select, [contenteditable="true"], [data-native-cursor], :disabled';

export default function PrecisionCursor() {
  const rootRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const dotRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = rootRef.current!;
    const ring = ringRef.current!;
    const dot = dotRef.current!;
    const pointer = window.matchMedia('(hover: hover) and (pointer: fine)');
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');

    const target = { x: 0, y: 0 };
    const follower = { x: 0, y: 0 };
    let visible = false;
    let hovering = false;
    let frame = 0;
    let lastTime = 0;

    const paint = () => {
      dot.style.transform = `translate3d(${target.x}px, ${target.y}px, 0)`;
      ring.style.transform = `translate3d(${follower.x}px, ${follower.y}px, 0)`;
    };

    const tick = (time: number) => {
      frame = 0;
      if (!visible) return;
      const dt = Math.min(time - (lastTime || time - 16.67), 40);
      lastTime = time;
      const ease = 1 - Math.exp(-dt / 45);

      follower.x += (target.x - follower.x) * ease;
      follower.y += (target.y - follower.y) * ease;

      paint();

      const unsettled = Math.hypot(target.x - follower.x, target.y - follower.y) > 0.1;
      if (unsettled) frame = requestAnimationFrame(tick);
    };

    const wake = () => {
      if (!frame && visible) {
        lastTime = 0;
        frame = requestAnimationFrame(tick);
      }
    };

    const hide = () => {
      visible = false;
      root.style.opacity = '0';
      document.documentElement.classList.remove('has-precision-cursor');
      cancelAnimationFrame(frame);
      frame = 0;
    };

    const move = (event: PointerEvent) => {
      if (!pointer.matches || reduced.matches || event.pointerType === 'touch') return hide();
      const element = event.target instanceof Element ? event.target : null;
      if (element?.closest(nativeSelector)) return hide();

      target.x = event.clientX;
      target.y = event.clientY;
      hovering = Boolean(element?.closest(interactiveSelector));

      if (!visible) {
        follower.x = target.x;
        follower.y = target.y;
        visible = true;
        paint();
        root.style.opacity = '1';
        document.documentElement.classList.add('has-precision-cursor');
      }
      root.dataset.hover = String(hovering);
      wake();
    };

    window.addEventListener('pointermove', move, { passive: true });
    window.addEventListener('pointerleave', hide);
    window.addEventListener('blur', hide);

    return () => {
      hide();
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerleave', hide);
      window.removeEventListener('blur', hide);
    };
  }, []);

  return (
    <div ref={rootRef} className="precision-cursor" aria-hidden="true">
      <div ref={ringRef} className="cursor-ring" />
      <div ref={dotRef} className="cursor-dot" />
    </div>
  );
}
```

- [ ] **Step 4: Create `web/app/layout.tsx`**

```tsx
import type { Metadata, Viewport } from 'next';
import './globals.css';
import 'lenis/dist/lenis.css';
import SmoothScroll from './components/SmoothScroll';
import PrecisionCursor from './components/PrecisionCursor';

export const metadata: Metadata = {
  title: 'MacDeck & NotchDeck - Native macOS & Android Control Surface',
  description: 'Turn your Android phone into a high-performance touchscreen stream deck. Configure slots in real-time with the native macOS NotchDeck liquid glass HUD.',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#f9fafd',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <SmoothScroll />
        <PrecisionCursor />
        {children}
      </body>
    </html>
  );
}
```

- [ ] **Step 5: Verify build & lint**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 6: Commit**

```bash
git add web/app/globals.css web/app/components/SmoothScroll.tsx web/app/components/PrecisionCursor.tsx web/app/layout.tsx
git commit -m "feat(web): configure design tokens, layout, smooth scroll, and precision cursor"
```

---

### Task 3: 100% Identical Android MacDeck Client Mockup (`PhoneDeckMockup.tsx`)

**Files:**
- Create: `web/app/components/PhoneDeckMockup.tsx`
- Create: `web/app/types/deck.ts`

**Interfaces:**
- Consumes: Slot model (`DeckSlotItem`)
- Produces: Interactive smartphone chassis with authentic Jetpack Compose UI (`ConnectionBar.kt`, `DeckAppTile.kt`), tactile click feedback, and orientation toggle

- [ ] **Step 1: Define shared types in `web/app/types/deck.ts`**

```typescript
export interface DeckSlotItem {
  id: string; // e.g. "app-1"
  index: number; // 0 to 5
  label: string; // e.g. "Terminal"
  bundleId: string; // e.g. "com.apple.Terminal"
  iconType: 'terminal' | 'code' | 'safari' | 'finder' | 'settings' | 'music' | 'slack' | 'figma';
  isEmpty?: boolean;
}

export type OrientationMode = 'portrait' | 'landscape';
```

- [ ] **Step 2: Create `web/app/components/PhoneDeckMockup.tsx`**

Implement the exact Android UI from `android/app/src/main/java/com/macdeck/client/ui/deck/`:
- Top ConnectionBar (`ConnectionBar.kt`): `USB Connected • 127.0.0.1:8765`, solid green dot, rotating refresh icon, settings icon.
- 6 App Tiles (`DeckAppTile.kt`): 22px squircle shape, `#121520` background, `#22293d` border, app icon, title, and sub-16ms tactile press (`scale: 0.93`, active border `#00d2ff`).
- Orientation toggle button: switches between Portrait (2×3) and Landscape (3×2).
- Executes `onTriggerSlot(slot: DeckSlotItem)` prop on tap.

- [ ] **Step 3: Verify TypeScript typing**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/app/types/deck.ts web/app/components/PhoneDeckMockup.tsx
git commit -m "feat(web): build 100% authentic Android MacDeck phone mockup"
```

---

### Task 4: 100% Identical macOS NotchDeck Mockup (`DesktopNotchMockup.tsx`)

**Files:**
- Create: `web/app/components/DesktopNotchMockup.tsx`

**Interfaces:**
- Consumes: Slot model (`DeckSlotItem`), active triggered app state
- Produces: Authentic macOS screen mockup with MacBook camera notch, expanding 6-slot liquid glass HUD, app picker sheet, slot clear badge, and execution indicator toast

- [ ] **Step 1: Create `web/app/components/DesktopNotchMockup.tsx`**

Implement the exact AppKit/SwiftUI layout from `macos/NotchDeck/Sources/NotchDeck/Views/`:
- Hardware camera notch at the top center of the Mac display frame.
- Expand / Collapse physics (`motion.div` with spring `response: 0.36, damping: 0.74`).
- Expanded HUD:
  - Header: Device pill `Pixel 8 Pro (Connected)` with green status dot and battery `94%`, profile title `Standard Productivity`, close button.
  - 3×2 Grid of macOS App Cards (`14px` squircle corners, frosted glass background, specular rim stroke).
  - Configured Card: App icon (`32×32`), bold app label, slot number (`Slot 1` to `Slot 6`), and a red minus (`-`) badge in top-right to clear the slot.
  - Empty Card: Subtle dashed outline, plus (`+`) icon, `Slot N`. Clicking opens an inline app picker sheet to assign an app.
- Execution Toast: When an app is triggered from the phone, the Mac screen mockup displays an authentic macOS system notification banner: `Terminal Launched via NSWorkspace`.

- [ ] **Step 2: Verify TypeScript typing**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add web/app/components/DesktopNotchMockup.tsx
git commit -m "feat(web): build 100% authentic macOS NotchDeck desktop mockup"
```

---

### Task 5: Dual Interactive Live Stage & Top Notch Island

**Files:**
- Create: `web/app/components/DualInteractiveStage.tsx`
- Create: `web/app/components/TopNotchIsland.tsx`

**Interfaces:**
- Consumes: `PhoneDeckMockup`, `DesktopNotchMockup`, `DeckSlotItem`
- Produces: Side-by-side synchronized interactive stage and top-of-browser Notch HUD

- [ ] **Step 1: Create `web/app/components/DualInteractiveStage.tsx`**

Implement synchronized cross-device state:
- Maintains default 6 slots:
  1. Terminal (`com.apple.Terminal`)
  2. VS Code (`com.microsoft.VSCode`)
  3. Safari (`com.apple.Safari`)
  4. Finder (`com.apple.finder`)
  5. Settings (`com.apple.systempreferences`)
  6. Music (`com.apple.Music`)
- When a user taps a slot on the Phone, it logs an action payload and triggers the Mac execution banner.
- When a user clears or modifies a slot on the Mac Notch HUD, it flashes a sync packet indicator and instantly updates the Phone mockup.

- [ ] **Step 2: Create `web/app/components/TopNotchIsland.tsx`**

- Pinned to the top-center of the browser viewport.
- Collapsed state: Minimal notch pill with camera dot and `MacDeck: USB Active`.
- Clicking expands to reveal the quick NotchDeck configurator with 6 slots.
- Synchronized with the same live slots state as the dual stage.

- [ ] **Step 3: Verify TypeScript typing**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/app/components/DualInteractiveStage.tsx web/app/components/TopNotchIsland.tsx
git commit -m "feat(web): implement dual interactive stage with cross-device state sync"
```

---

### Task 6: Narrative Showcase Sections (Workflow, Architecture, Terminal Commands, FAQ, Footer)

**Files:**
- Create: `web/app/components/HowItWorks.tsx`
- Create: `web/app/components/ArchitectureGrid.tsx`
- Create: `web/app/components/TerminalCommands.tsx`
- Create: `web/app/components/FaqAccordion.tsx`
- Create: `web/app/components/SiteFooter.tsx`

**Interfaces:**
- Consumes: Hugeicons, solid off-white tokens
- Produces: Responsive content sections with zero emojis, pure off-white cards, and one-click copy commands

- [ ] **Step 1: Create `web/app/components/HowItWorks.tsx`**

3-step tactile physical cards:
- `01 / High-Speed Connection`: USB ADB reverse tunnel `127.0.0.1:8765` or zero-config Wi-Fi LAN fallback.
- `02 / Fluid Notch HUD`: Configure 6 slots instantly from the top of your Mac without losing focus.
- `03 / Sub-16ms Desk Control`: Physical tactile compression with instant macOS execution.

- [ ] **Step 2: Create `web/app/components/ArchitectureGrid.tsx`**

4 clean architectural pillars:
- Native AppKit & SwiftUI engine (`NSPanel` at `.statusBar` level across all spaces).
- Reverse ADB Tunneling (instant USB socket communication without pairing passwords).
- Sandboxed Action Protocol (Android sends abstract IDs; Mac retains binary execution authority).
- Adaptive Grid Engine (Auto-transitions between Portrait 2×3 and Landscape 3×2).

- [ ] **Step 3: Create `web/app/components/TerminalCommands.tsx`**

Interactive tabbed shell interface with one-click copy and clipboard confirmation:
- Tab 1: Start Mac Server (`./scripts/run_mac.sh`)
- Tab 2: Launch NotchDeck (`./scripts/run_notchdeck.sh`)
- Tab 3: Connect USB (`./scripts/usb/connect.sh`)
- Tab 4: Install Android Client (`./scripts/install_android.sh`)
- Tab 5: Run Full Test Suite (`cd macos/NotchDeck && swift test && ./scripts/test_protocol.sh`)

- [ ] **Step 4: Create `web/app/components/FaqAccordion.tsx`**

Collapsible technical FAQ on latency, notch detection, security, and wireless support with clean Hugeicon toggles.

- [ ] **Step 5: Create `web/app/components/SiteFooter.tsx`**

Clean footer displaying platform compatibility (`macOS 14+ Sonoma/Sequoia`, `Android 10+`), protocol version `v1.0.0`, and repository links.

- [ ] **Step 6: Verify TypeScript typing**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 7: Commit**

```bash
git add web/app/components/HowItWorks.tsx web/app/components/ArchitectureGrid.tsx web/app/components/TerminalCommands.tsx web/app/components/FaqAccordion.tsx web/app/components/SiteFooter.tsx
git commit -m "feat(web): build workflow, architecture, terminal commands, faq, and footer sections"
```

---

### Task 7: Assemble Root Page (`page.tsx`), Site Header & Navigation

**Files:**
- Create: `web/app/page.tsx`
- Create: `web/app/components/SiteHeader.tsx`

**Interfaces:**
- Consumes: All components from Tasks 2-6
- Produces: Complete showcase landing page with smooth spring scroll progress bar and coordinated top notch HUD

- [ ] **Step 1: Create `web/app/components/SiteHeader.tsx`**

- Brand mark: `macdeck.` in Poppins bold with a solid slate dot.
- Desktop navigation links: `Live Demo`, `Workflow`, `Architecture`, `Commands`, `FAQ`.
- Action buttons: Quick toggle for Top Notch HUD and a link to the Android APK portal.

- [ ] **Step 2: Create `web/app/page.tsx`**

- Assembles `TopNotchIsland`, `SiteHeader`, Hero section with `DualInteractiveStage`, `HowItWorks`, `ArchitectureGrid`, `TerminalCommands`, `FaqAccordion`, and `SiteFooter`.
- Includes a smooth spring-animated scroll progress bar (`motion.div` with `scaleX`).

- [ ] **Step 3: Verify TypeScript typing**

Run:
```bash
cd web && npm run lint
```
Expected: Clean pass with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add web/app/components/SiteHeader.tsx web/app/page.tsx
git commit -m "feat(web): assemble landing page with header and scroll progress"
```

---

### Task 8: Verification & Strict Design Audit

**Files:**
- Read / Scan: `web/`

**Interfaces:**
- Consumes: Next.js build tool, grep audit tools
- Produces: Verified production build and passed audit report

- [ ] **Step 1: Build Verification**

Run:
```bash
cd web && npm run build
```
Expected: Next.js production build completes with exit code 0.

- [ ] **Step 2: Zero-Emoji Audit**

Scan all source code and assets in `web/` to guarantee no emojis exist:
Run:
```bash
grep -rnP '[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{1F700}-\x{1F77F}\x{1F780}-\x{1F7FF}\x{1F800}-\x{1F8FF}\x{1F900}-\x{1F9FF}\x{1FA00}-\x{1FA6F}\x{1FA70}-\x{1FAFF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]' web/app/ web/public/ || echo "ZERO EMOJIS FOUND - AUDIT PASSED"
```
Expected: Zero emojis found.

- [ ] **Step 3: Background Purity Audit**

Scan `globals.css` and all component inline styles to verify background consistency:
Run:
```bash
grep -rn "background.*gradient" web/app/ || echo "ZERO GRADIENT BACKGROUNDS - AUDIT PASSED"
```
Expected: Zero background gradients found.

- [ ] **Step 4: Commit and Finish**

```bash
git add web/
git commit -m "chore(web): complete build verification and strict constraint audits"
```
