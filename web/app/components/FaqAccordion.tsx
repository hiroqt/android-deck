'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  ArrowDown01Icon,
  UsbIcon,
  LaptopMinimalIcon,
  ShieldCheckIcon,
  Wifi01Icon,
  CpuIcon,
} from '@hugeicons/core-free-icons';

interface FaqItem {
  id: string;
  category: string;
  categoryIcon: typeof UsbIcon;
  question: string;
  answer: string;
  keyMetric: string;
}

const FAQ_ITEMS: FaqItem[] = [
  {
    id: 'latency-transport',
    category: 'Latency & Bus',
    categoryIcon: UsbIcon,
    question:
      'What is the real-world latency difference between USB reverse ADB tunneling and Wi-Fi LAN fallback?',
    answer:
      'When connected via USB-C, the ADB reverse tunnel operates across an in-memory loopback socket (127.0.0.1:8765). Round-trip transit averages 0.8 milliseconds with virtually zero packet jitter (max recorded 0.04ms). In Wi-Fi LAN fallback mode, packets route across your local 802.11 network via mDNS discovery, resulting in 8 to 12 milliseconds of latency. Both operational modes operate well within the standard 16.6ms 60fps frame budget, guaranteeing zero perceptible delay.',
    keyMetric: '0.8ms USB / 8-12ms Wi-Fi',
  },
  {
    id: 'notch-detection',
    category: 'AppKit & Hardware',
    categoryIcon: LaptopMinimalIcon,
    question:
      'How does NotchDeck detect and handle the physical MacBook display notch?',
    answer:
      'NotchDeck utilizes native AppKit screen geometry APIs (NSScreen.auxiliaryTopLeftArea and NSScreen.auxiliaryTopRightArea) to query the physical dimensions of the camera housing cutout. It pins an NSPanel at NSWindow.Level.statusBar matching Apples hardware curvature. On external monitors, Studio Displays, or notchless MacBooks, NotchDeck automatically detects the absence of a camera housing and adapts into a refined, floating status bar HUD beneath the top menu bar.',
    keyMetric: 'Sub-pixel hardware snapping',
  },
  {
    id: 'sandboxed-security',
    category: 'Security Model',
    categoryIcon: ShieldCheckIcon,
    question:
      'Why is Android strictly prohibited from transmitting shell commands or binary paths?',
    answer:
      'MacDeck implements an immutable Action ID Sandboxing model to eliminate command injection vectors. The Android handset only sends lightweight, abstract identifier tokens (such as action_invoke with slot_id app-1). It possesses zero knowledge of filesystem paths or executable binaries. The macOS host daemon maintains sole execution authority: it validates the slot ID against a user-configured local whitelist and invokes applications via official system APIs (NSWorkspace.shared.openApplication).',
    keyMetric: 'Zero shell injection surface',
  },
  {
    id: 'zero-config-pairing',
    category: 'Networking',
    categoryIcon: Wifi01Icon,
    question:
      'Do I need an online account, cloud servers, Bluetooth pairing, or open router ports?',
    answer:
      'No. MacDeck requires no user accounts, no cloud relays, no Bluetooth pairing, and no port forwarding on your router. Communication is entirely peer-to-peer over local hardware loopback (127.0.0.1:8765) or private subnet LAN sockets. When operating in USB mode, you can disconnect your computer and phone from the internet entirely, and MacDeck will function with complete zero-latency autonomy.',
    keyMetric: '100% Offline & Air-gapped capable',
  },
  {
    id: 'platform-compatibility',
    category: 'Compatibility',
    categoryIcon: CpuIcon,
    question:
      'Which operating systems and hardware configurations are supported?',
    answer:
      'The host agent runs natively on macOS 14.0 Sonoma and macOS 15.0 Sequoia, compiled for both Apple Silicon (M1, M2, M3, M4) and Intel x86_64 architectures. The client application runs on Android 10.0 (API Level 29) or newer and is built with Jetpack Compose. It dynamically adapts its 6-slot matrix across smartphone and tablet screens in both portrait (2x3) and landscape (3x2) orientations.',
    keyMetric: 'macOS 14+ & Android 10+',
  },
];

export default function FaqAccordion() {
  const [openId, setOpenId] = useState<string | null>('latency-transport');

  const toggleItem = (id: string) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <section
      id="faq"
      className="py-16 sm:py-24 bg-[#f9fafd] border-b border-[#e5e9f2]"
      aria-label="Frequently Asked Questions"
    >
      <div className="shell">
        {/* Section Heading - Strictly No Pill Eyebrows */}
        <div className="max-w-3xl mb-12 sm:mb-16">
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold tracking-tight text-[#101828] mb-4">
            Frequently Asked Questions
          </h2>
          <p className="text-base sm:text-lg text-[#475467] leading-relaxed">
            Technical details on network transport, physical notch detection, sandboxed
            security boundaries, and system requirements.
          </p>
        </div>

        {/* Accordion Container */}
        <div className="max-w-4xl mx-auto space-y-4">
          {FAQ_ITEMS.map((item) => {
            const isOpen = openId === item.id;
            return (
              <div
                key={item.id}
                className="bg-white rounded-2xl border border-[#dbe2ea] shadow-[0_2px_6px_rgba(16,24,40,0.03)] hover:border-[#b9c6d5] transition-colors overflow-hidden"
              >
                {/* Accordion Trigger Header */}
                <button
                  type="button"
                  onClick={() => toggleItem(item.id)}
                  aria-expanded={isOpen}
                  aria-controls={`faq-answer-${item.id}`}
                  className="w-full flex items-center justify-between p-5 sm:p-6 text-left gap-4 cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828] focus-visible:ring-offset-2"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-3 flex-1 min-w-0">
                    <span className="inline-flex items-center gap-1.5 self-start px-2 py-0.5 rounded bg-[#f2f4f7] border border-[#e4e7ec] font-mono text-[10px] font-semibold text-[#475467] uppercase tracking-wider shrink-0">
                      <HugeiconsIcon
                        icon={item.categoryIcon}
                        size={12}
                        className="text-[#475467]"
                      />
                      <span>{item.category}</span>
                    </span>
                    <h3 className="text-base sm:text-lg font-bold text-[#101828] leading-snug">
                      {item.question}
                    </h3>
                  </div>

                  <div className="shrink-0 flex items-center gap-2">
                    <div
                      className={`w-7 h-7 rounded-lg bg-[#f9fafd] border border-[#dbe2ea] flex items-center justify-center transition-transform duration-200 ${
                        isOpen ? 'rotate-180 bg-[#101828] text-white border-[#101828]' : 'text-[#475467]'
                      }`}
                    >
                      <HugeiconsIcon
                        icon={ArrowDown01Icon}
                        size={14}
                        className={isOpen ? 'text-white' : 'text-[#475467]'}
                      />
                    </div>
                  </div>
                </button>

                {/* Collapsible Answer Body */}
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      id={`faq-answer-${item.id}`}
                      role="region"
                      aria-labelledby={`faq-header-${item.id}`}
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }}
                      className="overflow-hidden"
                    >
                      <div className="px-5 sm:px-6 pb-6 pt-1 border-t border-[#f2f4f7]">
                        <p className="text-sm text-[#475467] leading-relaxed mb-4">
                          {item.answer}
                        </p>
                        <div className="flex items-center gap-2 pt-3 border-t border-[#f2f4f7] font-mono text-xs">
                          <span className="text-[#98a2b3] uppercase text-[10px] font-medium">
                            Benchmark Specification:
                          </span>
                          <span className="text-[#039855] font-semibold bg-[#edfcf2] border border-[#a6f4c5] px-2 py-0.5 rounded text-[11px]">
                            {item.keyMetric}
                          </span>
                        </div>
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
