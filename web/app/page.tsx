'use client';

import React, { useState } from 'react';
import { motion, useScroll, useSpring } from 'motion/react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  LaptopMinimalIcon,
  Copy01Icon,
  Tick01Icon,
  ArrowRight01Icon,
  ComputerTerminal01Icon,
} from '@hugeicons/core-free-icons';

import TopNotchIsland from './components/TopNotchIsland';
import SiteHeader from './components/SiteHeader';
import DualInteractiveStage from './components/DualInteractiveStage';
import HowItWorks from './components/HowItWorks';
import ArchitectureGrid from './components/ArchitectureGrid';
import TerminalCommands from './components/TerminalCommands';
import FaqAccordion from './components/FaqAccordion';
import SiteFooter from './components/SiteFooter';

export default function HomePage() {
  const [copiedSnippet, setCopiedSnippet] = useState(false);

  // Spring-animated scroll progress bar
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 120,
    damping: 30,
    restDelta: 0.001,
  });

  const handleCopySnippet = async () => {
    const cmd = './scripts/run_notchdeck.sh';
    try {
      await navigator.clipboard.writeText(cmd);
      setCopiedSnippet(true);
      setTimeout(() => setCopiedSnippet(false), 2000);
    } catch {
      const textarea = document.createElement('textarea');
      textarea.value = cmd;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopiedSnippet(true);
      setTimeout(() => setCopiedSnippet(false), 2000);
    }
  };

  const handleToggleNotch = () => {
    window.dispatchEvent(new CustomEvent('macdeck-toggle-notch'));
  };

  return (
    <div className="relative min-h-screen bg-[#f9fafd] text-[#101828] flex flex-col">
      {/* Spring-animated scroll progress bar across the entire top edge */}
      <motion.div
        className="fixed top-0 left-0 right-0 h-[2px] bg-[#101828] origin-left z-[60] pointer-events-none"
        style={{ scaleX }}
        aria-hidden="true"
      />

      {/* Top Notch HUD Island (Fixed at top-center) */}
      <TopNotchIsland />

      {/* Site Header & Navigation */}
      <SiteHeader onToggleNotch={handleToggleNotch} />

      <main className="flex-1 flex flex-col" id="main-content">
        {/* Hero Section */}
        <section
          className="pt-12 sm:pt-16 lg:pt-20 pb-10 border-b border-[#e5e9f2] bg-[#f9fafd]"
          aria-label="Overview & Hero"
        >
          <div className="shell flex flex-col items-center text-center">
            {/* Headline - Strictly No Pill Eyebrows */}
            <h1 className="text-3xl sm:text-5xl lg:text-6xl font-bold tracking-tight text-[#101828] leading-[1.1] max-w-4xl mb-6">
              Desktop Control Surface.
              <span className="block sm:inline text-[#344054]">
                {' '}
                Engineered for Mac and Android.
              </span>
            </h1>

            {/* Subtitle Description */}
            <p className="text-base sm:text-lg lg:text-xl text-[#475467] leading-relaxed max-w-3xl mb-8">
              Turn your Android phone into a high-performance touchscreen stream deck with physical
              tactile response. Configure slots in real-time with the native macOS NotchDeck liquid
              glass HUD over hardware USB loopback.
            </p>

            {/* Quick Action Buttons */}
            <div className="flex flex-wrap items-center justify-center gap-3 sm:gap-4 mb-8">
              <a
                href="#live-demo"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#101828] hover:bg-[#1d2939] text-white text-sm font-semibold shadow-xs active:scale-[0.98] transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828] focus-visible:ring-offset-2"
              >
                <span>Explore Live Demo</span>
                <HugeiconsIcon icon={ArrowRight01Icon} size={15} className="text-white/80" />
              </a>

              <button
                type="button"
                onClick={handleToggleNotch}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#dbe2ea] bg-white hover:bg-[#f2f4f7] hover:border-[#b9c6d5] text-[#101828] text-sm font-mono font-medium shadow-xs active:scale-[0.98] transition-all cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828]"
              >
                <HugeiconsIcon icon={LaptopMinimalIcon} size={16} className="text-[#475467]" />
                <span>Toggle Notch HUD</span>
              </button>

              <a
                href="#terminal-commands"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#dbe2ea] bg-white hover:bg-[#f2f4f7] hover:border-[#b9c6d5] text-[#101828] text-sm font-mono font-medium shadow-xs active:scale-[0.98] transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828]"
              >
                <HugeiconsIcon icon={ComputerTerminal01Icon} size={16} className="text-[#475467]" />
                <span>Terminal Quickstart</span>
              </a>
            </div>

            {/* Copy Command Snippet */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2 p-1.5 bg-white border border-[#dbe2ea] rounded-xl shadow-[0_1px_3px_rgba(16,24,40,0.05)] w-full max-w-xl mb-12">
              <div className="flex items-center gap-2 px-3 py-1.5 text-xs font-mono text-[#344054] flex-1 overflow-x-auto text-left">
                <span className="text-[#98a2b3] select-none">$</span>
                <span className="font-semibold text-[#101828]">./scripts/run_notchdeck.sh</span>
              </div>
              <button
                type="button"
                onClick={handleCopySnippet}
                className="inline-flex items-center justify-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-[#f2f4f7] hover:bg-[#e4e7ec] active:bg-[#d0d5dd] text-xs font-mono font-medium text-[#101828] transition-colors cursor-pointer shrink-0"
                aria-label="Copy run notchdeck command"
              >
                <HugeiconsIcon
                  icon={copiedSnippet ? Tick01Icon : Copy01Icon}
                  size={14}
                  className={copiedSnippet ? 'text-[#039855]' : 'text-[#475467]'}
                />
                <span>{copiedSnippet ? 'Copied' : 'Copy'}</span>
              </button>
            </div>

            {/* Hardware Capability Metrics Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4 w-full max-w-4xl text-left">
              <div className="bg-white border border-[#dbe2ea] rounded-xl p-3.5 sm:p-4 shadow-[0_1px_2px_rgba(16,24,40,0.03)]">
                <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
                  Loopback Transit
                </div>
                <div className="text-base sm:text-lg font-bold font-mono text-[#101828] mb-0.5">
                  &lt; 0.8ms
                </div>
                <div className="text-[11px] text-[#475467]">USB 3.1 Type-C Bus</div>
              </div>

              <div className="bg-white border border-[#dbe2ea] rounded-xl p-3.5 sm:p-4 shadow-[0_1px_2px_rgba(16,24,40,0.03)]">
                <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
                  Security Model
                </div>
                <div className="text-base sm:text-lg font-bold font-mono text-[#101828] mb-0.5">
                  Sandboxed
                </div>
                <div className="text-[11px] text-[#475467]">Abstract Action IDs</div>
              </div>

              <div className="bg-white border border-[#dbe2ea] rounded-xl p-3.5 sm:p-4 shadow-[0_1px_2px_rgba(16,24,40,0.03)]">
                <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
                  macOS Integration
                </div>
                <div className="text-base sm:text-lg font-bold font-mono text-[#101828] mb-0.5">
                  Liquid Glass
                </div>
                <div className="text-[11px] text-[#475467]">AppKit Notch Panel</div>
              </div>

              <div className="bg-white border border-[#dbe2ea] rounded-xl p-3.5 sm:p-4 shadow-[0_1px_2px_rgba(16,24,40,0.03)]">
                <div className="font-mono text-[10px] uppercase text-[#98a2b3] font-semibold mb-1">
                  Local Autonomy
                </div>
                <div className="text-base sm:text-lg font-bold font-mono text-[#101828] mb-0.5">
                  100% Offline
                </div>
                <div className="text-[11px] text-[#475467]">Zero Cloud Relays</div>
              </div>
            </div>
          </div>
        </section>

        {/* Live Interactive Dual Stage Section */}
        <section id="live-demo" className="scroll-mt-16 bg-[#f9fafd] border-b border-[#e5e9f2]">
          <div className="shell pt-12 pb-6">
            <div className="max-w-3xl mb-4">
              <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-[#101828] mb-3">
                Live Interactive Stage
              </h2>
              <p className="text-base sm:text-lg text-[#475467] leading-relaxed">
                Interact with the phone touchscreen and desktop notch HUD below. Configuration
                changes propagate bi-directionally over the simulated USB packet telemetry bus.
              </p>
            </div>
          </div>
          <DualInteractiveStage />
        </section>

        {/* Workflow Section (Step 1, Step 2, Step 3) */}
        <div id="workflow" className="scroll-mt-16" />
        <HowItWorks />

        {/* System Architecture Section */}
        <ArchitectureGrid />

        {/* Terminal Commands & Quickstart Section */}
        <div id="commands" className="scroll-mt-16" />
        <TerminalCommands />

        {/* Frequently Asked Questions */}
        <FaqAccordion />
      </main>

      {/* Site Footer */}
      <SiteFooter />
    </div>
  );
}
