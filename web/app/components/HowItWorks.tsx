'use client';

import React from 'react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  UsbIcon,
  LaptopMinimalIcon,
  Touch01Icon,
  Wifi01Icon,
  CheckmarkCircle01Icon,
} from '@hugeicons/core-free-icons';

interface StepCardProps {
  stepNumber: string;
  title: string;
  tagline: string;
  description: string;
  icon: typeof UsbIcon;
  badge: string;
  diagram: React.ReactNode;
  specs: { label: string; value: string }[];
  highlights: string[];
}

function StepCard({
  stepNumber,
  title,
  tagline,
  description,
  icon,
  badge,
  diagram,
  specs,
  highlights,
}: StepCardProps) {
  return (
    <article className="flex flex-col bg-white rounded-2xl border border-[#dbe2ea] p-6 sm:p-7 shadow-[0_2px_8px_rgba(16,24,40,0.04)] hover:border-[#b9c6d5] transition-colors h-full">
      {/* Step Header */}
      <div className="flex items-center justify-between gap-3 mb-5">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-[#101828] text-white font-mono text-xs font-bold flex items-center justify-center shrink-0">
            {stepNumber}
          </div>
          <span className="font-mono text-xs font-semibold text-[#475467] tracking-wider uppercase">
            Step {stepNumber}
          </span>
        </div>
        <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-[#f2f4f7] border border-[#e4e7ec] text-[11px] font-mono font-medium text-[#344054]">
          <HugeiconsIcon icon={icon} size={13} className="text-[#475467]" />
          <span>{badge}</span>
        </div>
      </div>

      {/* Title & Description */}
      <h3 className="text-xl font-bold tracking-tight text-[#101828] mb-1">
        {title}
      </h3>
      <p className="text-xs font-mono font-medium text-[#039855] mb-3">
        {tagline}
      </p>
      <p className="text-sm text-[#475467] leading-relaxed mb-6">
        {description}
      </p>

      {/* Tactile Visual Diagram Box */}
      <div className="w-full bg-[#f9fafd] border border-[#e5e9f2] rounded-xl p-4 mb-6">
        {diagram}
      </div>

      {/* Specifications Grid */}
      <div className="grid grid-cols-2 gap-2 pt-4 border-t border-[#f2f4f7] mb-4 text-xs">
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

      {/* Bullet Highlights */}
      <ul className="mt-auto space-y-2 pt-2 text-xs text-[#475467]">
        {highlights.map((item) => (
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

export default function HowItWorks() {
  return (
    <section
      id="how-it-works"
      className="py-16 sm:py-24 bg-[#f9fafd] border-b border-[#e5e9f2]"
      aria-label="How It Works"
    >
      <div className="shell">
        {/* Section Heading - No Pill Eyebrows */}
        <div className="max-w-3xl mb-12 sm:mb-16">
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-[#101828] mb-4">
            How It Works
          </h2>
          <p className="text-base sm:text-lg text-[#475467] leading-relaxed">
            Three physical steps from plug-in to tactile desk control. Zero cloud relays,
            zero account logins, and sub-millisecond local execution.
          </p>
        </div>

        {/* 3 Physical Workflow Steps */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 sm:gap-8 items-stretch">
          {/* Step 1: High-Speed Connection */}
          <StepCard
            stepNumber="01"
            title="High-Speed Connection"
            tagline="USB ADB reverse tunnel 127.0.0.1:8765 or Wi-Fi LAN fallback"
            description="Plug in your Android handset via USB-C. A single loopback reverse tunnel bridges your phone directly to the native macOS agent over 10 Gbps hardware bus."
            icon={UsbIcon}
            badge="Physical Wire"
            diagram={
              <div className="flex flex-col gap-2.5 font-mono text-[11px]">
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">Transport:</span>
                  <span className="font-semibold text-[#101828]">USB 3.1 Type-C</span>
                </div>
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">Tunnel Rule:</span>
                  <span className="font-semibold text-[#101828]">adb reverse tcp:8765</span>
                </div>
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">Round-Trip:</span>
                  <span className="font-semibold text-[#039855]">&lt; 0.8ms latency</span>
                </div>
                <div className="flex items-center justify-between text-[#475467]">
                  <span className="flex items-center gap-1">
                    <HugeiconsIcon icon={Wifi01Icon} size={12} className="text-[#475467]" />
                    <span>LAN Fallback:</span>
                  </span>
                  <span className="font-semibold text-[#101828]">ws://[mac-ip]:8765 (~8ms)</span>
                </div>
              </div>
            }
            specs={[
              { label: 'Primary Link', value: 'USB 3.1 Loopback' },
              { label: 'Port', value: 'TCP 8765' },
              { label: 'Credentials', value: 'Zero Config' },
              { label: 'Jitter', value: '0.04ms Max' },
            ]}
            highlights={[
              'Direct hardware socket bypasses home routers and firewalls.',
              'Automatic reconnect watchdog detects plug events in under 500ms.',
              'Seamless fallback to local Wi-Fi when unplugging from desk.',
            ]}
          />

          {/* Step 2: Fluid Notch HUD */}
          <StepCard
            stepNumber="02"
            title="Fluid Notch HUD"
            tagline="Configure 6 slots instantly from the top of your Mac without losing focus"
            description="The NotchDeck liquid-glass HUD nests directly around the camera housing of your MacBook Pro. Assign or modify app slots without opening auxiliary configuration windows."
            icon={LaptopMinimalIcon}
            badge="Native AppKit"
            diagram={
              <div className="flex flex-col gap-2 font-mono text-[11px]">
                {/* Simulated Notch Bar */}
                <div className="w-full bg-[#101828] text-white rounded-lg p-2.5 flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <div className="w-2.5 h-2.5 rounded-full bg-[#1d2939] border border-[#344054] flex items-center justify-center">
                      <div className="w-1 h-1 rounded-full bg-[#039855]" />
                    </div>
                    <span className="text-[10px] text-[#98a2b3]">NotchDeck HUD</span>
                  </div>
                  <span className="text-[9px] px-1.5 py-0.5 rounded bg-[#1d2939] text-[#98a2b3]">
                    6 Slots Active
                  </span>
                </div>
                {/* Mini Slot Badges */}
                <div className="grid grid-cols-3 gap-1 text-[10px] text-center">
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    Terminal
                  </div>
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    VS Code
                  </div>
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    Safari
                  </div>
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    Finder
                  </div>
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    Settings
                  </div>
                  <div className="bg-white border border-[#dbe2ea] rounded py-1 font-semibold text-[#101828]">
                    Music
                  </div>
                </div>
              </div>
            }
            specs={[
              { label: 'Window Class', value: 'NSPanel' },
              { label: 'Window Level', value: 'statusBar' },
              { label: 'Space Policy', value: 'canJoinAllSpaces' },
              { label: 'Sync Channel', value: 'JSON Frame Broadcast' },
            ]}
            highlights={[
              'Non-activating panel stays visible across full-screen spaces.',
              'Real-time socket updates propagate to Android with zero delay.',
              'Physical notch detection snaps precisely to Apple hardware radii.',
            ]}
          />

          {/* Step 3: Sub-16ms Desk Control */}
          <StepCard
            stepNumber="03"
            title="Sub-16ms Desk Control"
            tagline="Physical tactile compression with instant macOS execution"
            description="Tap any slot on your desk-mounted Android phone. Jetpack Compose delivers immediate tactile haptic feedback while macOS launches your application in sub-millisecond time."
            icon={Touch01Icon}
            badge="Hardware Click"
            diagram={
              <div className="flex flex-col gap-2 font-mono text-[11px]">
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">Android Touch Polling:</span>
                  <span className="font-semibold text-[#101828]">~3.2ms</span>
                </div>
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">USB Cable Transfer:</span>
                  <span className="font-semibold text-[#101828]">~0.8ms</span>
                </div>
                <div className="flex items-center justify-between pb-2 border-b border-[#e5e9f2]">
                  <span className="text-[#475467]">AppKit NSWorkspace:</span>
                  <span className="font-semibold text-[#101828]">~2.1ms</span>
                </div>
                <div className="flex items-center justify-between text-[#039855] font-semibold">
                  <span>Total Response Time:</span>
                  <span>~6.1ms (&lt; 16ms budget)</span>
                </div>
              </div>
            }
            specs={[
              { label: 'Frame Budget', value: '60 FPS Target' },
              { label: 'Execution', value: 'NSWorkspace API' },
              { label: 'Security', value: 'Action ID Whitelist' },
              { label: 'Orientation', value: '2x3 or 3x2 Auto' },
            ]}
            highlights={[
              'Haptic impulse confirms tap before finger leaves phone glass.',
              'Android cannot execute raw shell code: strictly sends abstract IDs.',
              'Runs quietly in the background without stealing current focus.',
            ]}
          />
        </div>
      </div>
    </section>
  );
}
