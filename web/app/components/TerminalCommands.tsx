'use client';

import React, { useState } from 'react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  Copy01Icon,
  Tick01Icon,
  ComputerTerminal01Icon,
  LaptopMinimalIcon,
  UsbIcon,
  Touch01Icon,
  CheckmarkCircle01Icon,
} from '@hugeicons/core-free-icons';

interface TerminalTab {
  id: string;
  name: string;
  shortLabel: string;
  command: string;
  description: string;
  prerequisites: string;
  icon: typeof ComputerTerminal01Icon;
  simulatedOutput: string[];
}

const TERMINAL_TABS: TerminalTab[] = [
  {
    id: 'mac-server',
    name: 'Start Mac Server',
    shortLabel: 'Host Server',
    command: './scripts/run_mac.sh',
    description:
      'Builds and launches the native macOS Swift daemon. Binds local loopback WebSocket server to port 8765 to receive touch packets.',
    prerequisites: 'macOS 14+ Sonoma or Sequoia, Swift 6 toolchain installed.',
    icon: ComputerTerminal01Icon,
    simulatedOutput: [
      '[INFO] Building and launching MacDeck macOS Host Agent...',
      '[INFO] Resolving project root dependencies...',
      '[INFO] Compiling Swift sources (MacDeck, WebSocketServer, ActionExecutor)...',
      '[OK] WebSocket server initialized on ws://127.0.0.1:8765',
      '[OK] Ready for client connections. Awaiting ACTION_INVOKE packets...',
    ],
  },
  {
    id: 'notchdeck',
    name: 'Launch NotchDeck',
    shortLabel: 'Notch HUD',
    command: './scripts/run_notchdeck.sh',
    description:
      'Builds and starts the native liquid-glass notch HUD. Mounts an NSPanel at .statusBar level wrapping the MacBook display camera housing.',
    prerequisites: 'macOS 14+, NotchDeck binary permissions.',
    icon: LaptopMinimalIcon,
    simulatedOutput: [
      '[INFO] Building NotchDeck (macOS Native Liquid Glass Notch Stream Deck)...',
      '[INFO] Compiling NotchDeck release binary with AppKit and SwiftUI...',
      '[OK] Build complete in 1.4s.',
      '[INFO] Launching NotchDeck at NSWindow.Level.statusBar...',
      '[OK] Snapped to screen 0 auxiliary area (MacBook Pro Notch Cutout).',
      '[OK] Profile synchronization channel active.',
    ],
  },
  {
    id: 'usb-connect',
    name: 'Connect USB',
    shortLabel: 'USB Tunnel',
    command: './scripts/usb/connect.sh',
    description:
      'Configures the ADB reverse loopback tunnel over USB-C. Forwards handset port 8765 directly to Mac port 8765 with zero network routing.',
    prerequisites: 'Android phone connected via USB with USB Debugging enabled.',
    icon: UsbIcon,
    simulatedOutput: [
      '[INFO] Using ADB binary: /opt/homebrew/bin/adb',
      '[INFO] Checking connected USB devices...',
      '[OK] Device found: 19281FDF600392 device',
      '[INFO] Setting up ADB reverse tunnel on port 8765...',
      'adb reverse tcp:8765 tcp:8765',
      '[OK] USB Tunnel Established Successfully.',
      '     Android Phone (localhost:8765) ----[USB 3.1]----> MacDeck Host (:8765)',
      '     Select "USB Mode" in Android app to connect to ws://127.0.0.1:8765',
    ],
  },
  {
    id: 'install-android',
    name: 'Install Android Client',
    shortLabel: 'Android APK',
    command: './scripts/install_android.sh',
    description:
      'Compiles the native Android Jetpack Compose client with Gradle and installs it directly to your connected device via ADB.',
    prerequisites: 'Android device connected via USB with Install via USB permitted.',
    icon: Touch01Icon,
    simulatedOutput: [
      '[INFO] Using ADB: /opt/homebrew/bin/adb',
      '[INFO] Building Android debug APK via Gradle wrapper...',
      'BUILD SUCCESSFUL in 3.8s',
      '[INFO] Installing MacDeck on connected device...',
      'Performing Streamed Install',
      'Success',
      '[INFO] Launching MacDeck on Android...',
      'Starting: Intent { cmp=com.macdeck.client/.MainActivity }',
      '[OK] Ready. Android client active and listening.',
    ],
  },
  {
    id: 'test-suite',
    name: 'Run Full Test Suite',
    shortLabel: 'Test Suite',
    command: 'cd macos/NotchDeck && swift test && ./scripts/test_protocol.sh',
    description:
      'Executes the entire verification pipeline: protocol JSON contract validation, Swift unit tests, and script permission checks.',
    prerequisites: 'Swift toolchain and Python 3 for JSON validation.',
    icon: CheckmarkCircle01Icon,
    simulatedOutput: [
      'Test Suite "NotchDeckTests" passed.',
      'Executed 8 tests, with 0 failures (0 unexpected) in 0.082s.',
      '=== 1. Validating Protocol JSON Fixtures ===',
      'Checking action_invoke.json... [OK] Valid JSON',
      'Checking profile_sync.json...   [OK] Valid JSON',
      '=== 2. Running macOS Swift Unit Tests ===',
      '[OK] Host tests passed.',
      '=== 3. Checking USB helper script permissions ===',
      '[OK] scripts/usb/connect.sh is executable',
      '[OK] All Protocol & Host Tests Passed Successfully.',
    ],
  },
];

export default function TerminalCommands() {
  const [activeTabIdx, setActiveTabIdx] = useState(0);
  const [copied, setCopied] = useState(false);

  const activeTab = TERMINAL_TABS[activeTabIdx];

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(activeTab.command);
      setCopied(true);
      setTimeout(() => {
        setCopied(false);
      }, 2000);
    } catch {
      // Fallback if clipboard API is restricted
      const textarea = document.createElement('textarea');
      textarea.value = activeTab.command;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <section
      id="terminal-commands"
      className="py-16 sm:py-24 bg-[#f9fafd] border-b border-[#e5e9f2]"
      aria-label="Terminal Commands and Quickstart"
    >
      <div className="shell">
        {/* Section Heading - Strictly No Pill Eyebrows */}
        <div className="max-w-3xl mb-12 sm:mb-16">
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-[#101828] mb-4">
            Terminal Quickstart & Commands
          </h2>
          <p className="text-base sm:text-lg text-[#475467] leading-relaxed">
            Run, connect, and inspect the entire MacDeck and NotchDeck stack with simple,
            transparent shell scripts. Click any command to copy it directly to your clipboard.
          </p>
        </div>

        {/* Tab Selection Bar */}
        <div className="flex flex-wrap items-center gap-2 mb-6 border-b border-[#dbe2ea] pb-3">
          {TERMINAL_TABS.map((tab, idx) => {
            const isActive = idx === activeTabIdx;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => {
                  setActiveTabIdx(idx);
                  setCopied(false);
                }}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs sm:text-sm font-medium transition-all cursor-pointer ${
                  isActive
                    ? 'bg-[#101828] text-white shadow-sm'
                    : 'bg-white border border-[#dbe2ea] text-[#475467] hover:text-[#101828] hover:bg-[#f2f4f7]'
                }`}
              >
                <HugeiconsIcon
                  icon={tab.icon}
                  size={15}
                  className={isActive ? 'text-white' : 'text-[#475467]'}
                />
                <span className="hidden sm:inline">{tab.name}</span>
                <span className="sm:hidden">{tab.shortLabel}</span>
              </button>
            );
          })}
        </div>

        {/* Command Context Overview */}
        <div className="bg-white rounded-2xl border border-[#dbe2ea] p-5 sm:p-6 mb-6 shadow-[0_2px_8px_rgba(16,24,40,0.04)]">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="space-y-1">
              <h3 className="text-lg font-bold text-[#101828]">
                {activeTab.name}
              </h3>
              <p className="text-sm text-[#475467] leading-relaxed">
                {activeTab.description}
              </p>
            </div>
            <div className="shrink-0 text-left sm:text-right">
              <span className="font-mono text-[10px] uppercase text-[#98a2b3] font-medium block">
                Prerequisites
              </span>
              <span className="font-mono text-xs text-[#344054] font-medium">
                {activeTab.prerequisites}
              </span>
            </div>
          </div>
        </div>

        {/* High-Precision macOS Terminal Window */}
        <div className="bg-[#101828] rounded-2xl border border-[#1d2939] shadow-[0_12px_32px_rgba(16,24,40,0.2)] overflow-hidden">
          {/* Terminal Title Bar */}
          <div className="flex items-center justify-between px-4 py-3 bg-[#161f30] border-b border-[#243048]">
            {/* Window Traffic Lights */}
            <div className="flex items-center gap-2">
              <div
                className="w-3 h-3 rounded-full bg-[#ef4444]"
                aria-label="Close"
              />
              <div
                className="w-3 h-3 rounded-full bg-[#f59e0b]"
                aria-label="Minimize"
              />
              <div
                className="w-3 h-3 rounded-full bg-[#10b981]"
                aria-label="Zoom"
              />
              <span className="ml-2 font-mono text-xs text-[#98a2b3] hidden sm:inline">
                terminal — zsh — 80x24
              </span>
            </div>

            {/* Title / Action */}
            <div className="flex items-center gap-3">
              <span className="font-mono text-xs text-[#98a2b3] truncate max-w-[200px] sm:max-w-none">
                {activeTab.command}
              </span>
              {/* Copy Button */}
              <button
                type="button"
                onClick={handleCopy}
                title="Copy Command to Clipboard"
                className="flex items-center gap-1.5 px-3 py-1 rounded-md bg-[#243048] hover:bg-[#2e3e5c] text-white text-xs font-mono transition-colors cursor-pointer"
              >
                <HugeiconsIcon
                  icon={copied ? Tick01Icon : Copy01Icon}
                  size={14}
                  className={copied ? 'text-[#10b981]' : 'text-[#cbd5e1]'}
                />
                <span className={copied ? 'text-[#10b981] font-semibold' : 'text-[#f2f4f7]'}>
                  {copied ? 'Copied' : 'Copy'}
                </span>
              </button>
            </div>
          </div>

          {/* Terminal Code Body */}
          <div className="p-4 sm:p-6 font-mono text-xs sm:text-sm text-[#f2f4f7] leading-relaxed space-y-4 overflow-x-auto">
            {/* Command Prompt Line */}
            <div className="flex items-start gap-2 text-white">
              <span className="text-[#10b981] select-none font-bold">user@macbook-pro</span>
              <span className="text-[#98a2b3] select-none">android-deck %</span>
              <span className="font-semibold text-white selection:bg-[#344054]">
                {activeTab.command}
              </span>
            </div>

            {/* Command Output Log */}
            <div className="space-y-1.5 pt-2 border-t border-[#1d2939] text-[#cbd5e1] text-xs font-mono">
              {activeTab.simulatedOutput.map((line, i) => {
                const isSuccess = line.startsWith('[OK]');
                const isInfo = line.startsWith('[INFO]');
                return (
                  <div
                    key={i}
                    className={`leading-relaxed ${
                      isSuccess
                        ? 'text-[#10b981]'
                        : isInfo
                        ? 'text-[#94a3b8]'
                        : 'text-[#e2e8f0]'
                    }`}
                  >
                    {line}
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Quick Reference Grid Below Terminal */}
        <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div className="bg-white rounded-xl border border-[#dbe2ea] p-4 text-xs">
            <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
              Local Socket Target
            </div>
            <div className="font-mono font-bold text-[#101828]">
              ws://127.0.0.1:8765
            </div>
            <p className="text-[#475467] text-[11px] mt-1">
              Binds strictly to loopback interface on macOS host.
            </p>
          </div>

          <div className="bg-white rounded-xl border border-[#dbe2ea] p-4 text-xs">
            <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
              Hardware Wire Spec
            </div>
            <div className="font-mono font-bold text-[#101828]">
              USB 3.1 Type-C 10 Gbps
            </div>
            <p className="text-[#475467] text-[11px] mt-1">
              Sub-millisecond packet latency with zero wireless interference.
            </p>
          </div>

          <div className="bg-white rounded-xl border border-[#dbe2ea] p-4 text-xs sm:col-span-2 lg:col-span-1">
            <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
              Validation Protocol
            </div>
            <div className="font-mono font-bold text-[#101828]">
              Strict JSON Schema v1.0.0
            </div>
            <p className="text-[#475467] text-[11px] mt-1">
              All touch actions are cryptographically verified and sandboxed.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
