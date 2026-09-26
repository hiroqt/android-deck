'use client';

import React from 'react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  LaptopMinimalIcon,
  UsbIcon,
  ShieldCheckIcon,
  Grid02Icon,
  CheckmarkCircle01Icon,
} from '@hugeicons/core-free-icons';

interface PillarCardProps {
  pillarNumber: string;
  title: string;
  tagline: string;
  description: string;
  icon: typeof LaptopMinimalIcon;
  codeSnippet: string;
  codeLanguage: string;
  specs: { label: string; value: string }[];
  guarantees: string[];
}

function PillarCard({
  pillarNumber,
  title,
  tagline,
  description,
  icon,
  codeSnippet,
  codeLanguage,
  specs,
  guarantees,
}: PillarCardProps) {
  return (
    <article className="flex flex-col bg-white rounded-2xl border border-[#dbe2ea] p-6 sm:p-7 shadow-[0_2px_8px_rgba(16,24,40,0.04)] hover:border-[#b9c6d5] transition-colors h-full">
      {/* Pillar Badge & Icon */}
      <div className="flex items-center justify-between gap-3 mb-4">
        <div className="flex items-center gap-2">
          <span className="font-mono text-xs font-bold text-[#101828] tracking-wider uppercase px-2 py-0.5 rounded bg-[#f2f4f7] border border-[#e4e7ec]">
            {pillarNumber}
          </span>
          <span className="font-mono text-xs font-semibold text-[#475467]">
            Core Pillar
          </span>
        </div>
        <div className="w-8 h-8 rounded-lg bg-[#f9fafd] border border-[#dbe2ea] flex items-center justify-center text-[#101828]">
          <HugeiconsIcon icon={icon} size={16} className="text-[#101828]" />
        </div>
      </div>

      {/* Title & Tagline */}
      <h3 className="text-lg sm:text-xl font-bold tracking-tight text-[#101828] mb-1">
        {title}
      </h3>
      <p className="text-xs font-mono font-medium text-[#039855] mb-3">
        {tagline}
      </p>

      {/* Description */}
      <p className="text-sm text-[#475467] leading-relaxed mb-5">
        {description}
      </p>

      {/* Code Snippet Box */}
      <div className="w-full bg-[#101828] text-[#f2f4f7] rounded-xl p-3.5 mb-5 border border-[#1d2939] overflow-x-auto">
        <div className="flex items-center justify-between pb-2 mb-2 border-b border-[#2d3345] text-[10px] font-mono text-[#98a2b3]">
          <span>{codeLanguage}</span>
          <span className="text-[#039855]">Verified Native</span>
        </div>
        <pre className="font-mono text-xs leading-relaxed text-[#e4e7ec]">
          <code>{codeSnippet}</code>
        </pre>
      </div>

      {/* Specifications */}
      <div className="grid grid-cols-2 gap-2.5 pt-4 border-t border-[#f2f4f7] mb-4 text-xs">
        {specs.map((spec) => (
          <div key={spec.label} className="flex flex-col">
            <span className="font-mono text-[10px] uppercase text-[#98a2b3] font-medium">
              {spec.label}
            </span>
            <span className="font-mono text-xs font-semibold text-[#101828] truncate">
              {spec.value}
            </span>
          </div>
        ))}
      </div>

      {/* Architectural Guarantees */}
      <ul className="mt-auto space-y-2 pt-2 text-xs text-[#475467]">
        {guarantees.map((item) => (
          <li key={item} className="flex items-start gap-2">
            <HugeiconsIcon
              icon={CheckmarkCircle01Icon}
              size={14}
              className="text-[#039855] shrink-0 mt-0.5"
            />
            <span className="leading-snug">{item}</span>
          </li>
        ))}
      </ul>
    </article>
  );
}

export default function ArchitectureGrid() {
  return (
    <section
      id="architecture"
      className="py-16 sm:py-24 bg-[#f9fafd] border-b border-[#e5e9f2]"
      aria-label="System Architecture"
    >
      <div className="shell">
        {/* Section Heading - Strictly No Pill Eyebrows */}
        <div className="max-w-3xl mb-12 sm:mb-16">
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-[#101828] mb-4">
            System Architecture
          </h2>
          <p className="text-base sm:text-lg text-[#475467] leading-relaxed">
            Built from the hardware bus up using native AppKit and low-level loopback tunneling.
            Zero cloud intermediaries, zero web-view wrappers, and absolute execution security.
          </p>
        </div>

        {/* 4 Architectural Pillars Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8 items-stretch">
          {/* Pillar 1: Native AppKit & SwiftUI Engine */}
          <PillarCard
            pillarNumber="Pillar 01"
            title="Native AppKit & SwiftUI Engine"
            tagline="NSPanel at .statusBar level across all macOS spaces"
            description="Zero Electron bloat and zero web-view overhead. NotchDeck is built in native Swift, configuring an NSPanel with canJoinAllSpaces and nonactivatingPanel attributes to float persistently without stealing keyboard focus or disrupting active IDEs."
            icon={LaptopMinimalIcon}
            codeLanguage="Swift 6 / AppKit"
            codeSnippet={`panel.level = .statusBar
panel.collectionBehavior = [
    .canJoinAllSpaces,
    .fullScreenAuxiliary
]
panel.styleMask = [.borderless, .nonactivatingPanel]`}
            specs={[
              { label: 'Runtime', value: 'Swift 6 Native' },
              { label: 'Memory Footprint', value: '< 38 MB RSS' },
              { label: 'Window Level', value: 'NSWindow.Level.statusBar' },
              { label: 'CPU Usage (Idle)', value: '< 0.1%' },
            ]}
            guarantees={[
              'Persistent across Mission Control and full-screen Xcode/VS Code workspaces.',
              'Snaps to physical MacBook display camera notch using auxiliary area geometry.',
              'No background Chromium helper processes or V8 garbage collection pauses.',
            ]}
          />

          {/* Pillar 2: Reverse ADB Tunneling */}
          <PillarCard
            pillarNumber="Pillar 02"
            title="Reverse ADB Tunneling"
            tagline="Zero-configuration USB socket proxy over loopback TCP"
            description="Binding the Android client loopback to the macOS host daemon via adb reverse tcp:8765 tcp:8765 bypasses Wi-Fi latency, home router NAT, and local firewalls. Packets transit physical USB 3.1 Type-C cabling at hardware bus speed with 0.8ms round-trip latency."
            icon={UsbIcon}
            codeLanguage="Bash / ADB Protocol"
            codeSnippet={`# Forward Android localhost to macOS host loopback
adb reverse tcp:8765 tcp:8765

# Android connects directly to ws://127.0.0.1:8765`}
            specs={[
              { label: 'Physical Bus', value: 'USB 3.1 Gen 2 (10 Gbps)' },
              { label: 'Loopback Target', value: '127.0.0.1:8765' },
              { label: 'Round-Trip Latency', value: '0.8ms Average' },
              { label: 'Handshake Time', value: '< 20ms' },
            ]}
            guarantees={[
              'Zero pairing passwords, zero QR codes, and zero Bluetooth discovery delay.',
              'Completely air-gapped from local network traffic when operating in USB mode.',
              'Automatic watchdog reconnects instantly if USB cable is temporarily unplugged.',
            ]}
          />

          {/* Pillar 3: Sandboxed Action Protocol */}
          <PillarCard
            pillarNumber="Pillar 03"
            title="Sandboxed Action Protocol"
            tagline="Android emits abstract IDs; Mac retains binary execution authority"
            description="NotchDeck eliminates arbitrary code execution risks by enforcing an immutable Action ID abstraction. The phone never transmits raw shell commands, binary paths, or scripts. It transmits structured slot IDs (app-1 to app-6) which the macOS host maps to validated NSWorkspace invocations."
            icon={ShieldCheckIcon}
            codeLanguage="JSON Protocol v1.0.0"
            codeSnippet={`{
  "type": "action_invoke",
  "slot_id": "app-1",
  "timestamp": 1727334800
}
// Host maps "app-1" -> NSWorkspace.openApplication`}
            specs={[
              { label: 'Protocol Contract', value: 'Strict JSON Schema' },
              { label: 'Client Authority', value: 'Abstract Slot ID' },
              { label: 'Host Authority', value: 'NSWorkspace Validation' },
              { label: 'Security Model', value: 'Zero Command Injection' },
            ]}
            guarantees={[
              'Untrusted client input cannot execute arbitrary terminal commands on your Mac.',
              'Slot assignments remain strictly stored on macOS under local security boundaries.',
              'Full AppleScript keystroke emulation requires explicit user Accessibility approval.',
            ]}
          />

          {/* Pillar 4: Adaptive Grid Engine */}
          <PillarCard
            pillarNumber="Pillar 04"
            title="Adaptive Grid Engine"
            tagline="Auto-transitions between Portrait 2x3 and Landscape 3x2"
            description="Whether propped upright on a desktop MagSafe stand or laid horizontally beneath an external display, the Jetpack Compose engine dynamically adapts layout metrics across device orientation changes, maintaining tactile pad sizing and muscle memory."
            icon={Grid02Icon}
            codeLanguage="Kotlin / Jetpack Compose"
            codeSnippet={`val columns = if (isLandscape) {
    GridCells.Fixed(3) // 3 cols x 2 rows
} else {
    GridCells.Fixed(2) // 2 cols x 3 rows
}
LazyVerticalGrid(columns = columns) { ... }`}
            specs={[
              { label: 'Portrait Matrix', value: '2 Columns x 3 Rows' },
              { label: 'Landscape Matrix', value: '3 Columns x 2 Rows' },
              { label: 'Haptic Feedback', value: 'Jetpack HapticFeedback' },
              { label: 'Tile Re-layout', value: '< 1ms Recomposition' },
            ]}
            guarantees={[
              'Smooth fluid reflow preserves active slot index without socket disconnect.',
              'Physical press scale compression (0.96x) delivers tactile tactile feedback.',
              'Responsive design scales proportionally across 5-inch to 13-inch displays.',
            ]}
          />
        </div>
      </div>
    </section>
  );
}
