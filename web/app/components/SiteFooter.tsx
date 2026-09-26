'use client';

import React from 'react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  LaptopMinimalIcon,
  Touch01Icon,
  UsbIcon,
  ShieldCheckIcon,
  FileCodeIcon,
  Github01Icon,
  ComputerTerminal01Icon,
} from '@hugeicons/core-free-icons';

export default function SiteFooter() {
  return (
    <footer
      id="site-footer"
      className="bg-[#f9fafd] border-t border-[#dbe2ea] pt-14 pb-12 text-[#475467]"
      aria-label="Site Footer"
    >
      <div className="shell">
        {/* Main Footer Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 lg:gap-8 pb-12 border-b border-[#e5e9f2]">
          {/* Brand & Mission Statement (2 Columns) */}
          <div className="lg:col-span-2 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-[#101828] text-white flex items-center justify-center font-mono font-bold text-sm">
                MD
              </div>
              <span className="text-lg font-bold tracking-tight text-[#101828]">
                MacDeck & NotchDeck
              </span>
            </div>
            <p className="text-sm text-[#475467] leading-relaxed max-w-sm">
              Zero-latency physical macro controller system pairing an Android handset with
              a native macOS liquid-glass notch HUD over hardware USB loopback.
            </p>

            {/* Protocol & Connection Status Badge */}
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white border border-[#dbe2ea] text-xs font-mono text-[#344054]">
              <div
                className="w-2 h-2 rounded-full bg-[#039855]"
                aria-hidden="true"
              />
              <span className="font-semibold text-[#101828]">Protocol v1.0.0</span>
              <span className="text-[#98a2b3]">|</span>
              <span className="text-[#475467]">Local Socket 127.0.0.1:8765</span>
            </div>
          </div>

          {/* Column 1: Native Components */}
          <div className="space-y-3">
            <h4 className="font-mono text-xs font-bold uppercase tracking-wider text-[#101828]">
              Codebase
            </h4>
            <ul className="space-y-2 text-xs">
              <li>
                <a
                  href="#how-it-works"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={LaptopMinimalIcon} size={14} className="text-[#98a2b3]" />
                  <span>macOS MacDeck Host</span>
                </a>
              </li>
              <li>
                <a
                  href="#how-it-works"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={LaptopMinimalIcon} size={14} className="text-[#98a2b3]" />
                  <span>NotchDeck HUD (AppKit)</span>
                </a>
              </li>
              <li>
                <a
                  href="#architecture"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={Touch01Icon} size={14} className="text-[#98a2b3]" />
                  <span>Android Client (Compose)</span>
                </a>
              </li>
              <li>
                <a
                  href="#architecture"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={FileCodeIcon} size={14} className="text-[#98a2b3]" />
                  <span>JSON Protocol Contracts</span>
                </a>
              </li>
            </ul>
          </div>

          {/* Column 2: Scripts & Automation */}
          <div className="space-y-3">
            <h4 className="font-mono text-xs font-bold uppercase tracking-wider text-[#101828]">
              Quick Scripts
            </h4>
            <ul className="space-y-2 text-xs font-mono">
              <li>
                <a
                  href="#terminal-commands"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={ComputerTerminal01Icon} size={13} className="text-[#98a2b3]" />
                  <span>./scripts/run_mac.sh</span>
                </a>
              </li>
              <li>
                <a
                  href="#terminal-commands"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={ComputerTerminal01Icon} size={13} className="text-[#98a2b3]" />
                  <span>./scripts/run_notchdeck.sh</span>
                </a>
              </li>
              <li>
                <a
                  href="#terminal-commands"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={UsbIcon} size={13} className="text-[#98a2b3]" />
                  <span>./scripts/usb/connect.sh</span>
                </a>
              </li>
              <li>
                <a
                  href="#terminal-commands"
                  className="hover:text-[#101828] transition-colors flex items-center gap-1.5"
                >
                  <HugeiconsIcon icon={ShieldCheckIcon} size={13} className="text-[#98a2b3]" />
                  <span>./scripts/test_protocol.sh</span>
                </a>
              </li>
            </ul>
          </div>

          {/* Column 3: Platform Compatibility */}
          <div className="space-y-3">
            <h4 className="font-mono text-xs font-bold uppercase tracking-wider text-[#101828]">
              Requirements
            </h4>
            <div className="space-y-2 text-xs">
              <div className="flex flex-col">
                <span className="font-mono text-[10px] text-[#98a2b3] uppercase font-semibold">
                  Host Environment
                </span>
                <span className="font-medium text-[#101828]">
                  macOS 14+ Sonoma / Sequoia
                </span>
              </div>
              <div className="flex flex-col">
                <span className="font-mono text-[10px] text-[#98a2b3] uppercase font-semibold">
                  Device Client
                </span>
                <span className="font-medium text-[#101828]">
                  Android 10+ (API 29+)
                </span>
              </div>
              <div className="flex flex-col">
                <span className="font-mono text-[10px] text-[#98a2b3] uppercase font-semibold">
                  Physical Transport
                </span>
                <span className="font-medium text-[#101828]">
                  USB 3.1 Type-C / Wi-Fi LAN
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Bar: Copyright & Security Note */}
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs">
          <p className="text-[#475467] text-center sm:text-left">
            MacDeck & NotchDeck Open Source Project. Designed for physical desk precision.
          </p>

          <div className="flex items-center gap-4 text-[#475467]">
            <a
              href="https://github.com/arnel/android-deck"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 hover:text-[#101828] transition-colors"
            >
              <HugeiconsIcon icon={Github01Icon} size={14} className="text-[#475467]" />
              <span>GitHub</span>
            </a>
            <span className="text-[#dbe2ea]">|</span>
            <span className="font-mono text-[11px] text-[#475467]">
              MIT / Apache-2.0 License
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
}
