'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';

interface FaqItem {
  id: string;
  question: string;
  answer: string;
}

const FAQ_ITEMS: FaqItem[] = [
  {
    id: 'latency-transport',
    question: 'What is the latency difference between USB and Wi-Fi?',
    answer:
      'Connecting over a standard USB cable uses a direct hardware tunnel with an average round-trip latency of 0.8 milliseconds, giving you instant tactile response with zero perceptible delay. Over local Wi-Fi, responses take about 8 to 12 milliseconds—well within the standard 60 frames-per-second budget. Both modes feel fast and fluid, letting you choose between maximum speed or wireless convenience.',
  },
  {
    id: 'notch-detection',
    question: 'How does NotchDeck handle external monitors or MacBooks without a notch?',
    answer:
      'NotchDeck automatically inspects your active display geometry. If your MacBook has a physical camera notch, NotchDeck contours snugly around the hardware cutout. When you use an external monitor, Studio Display, or a notchless MacBook, NotchDeck automatically transforms into a sleek, floating status bar HUD docked directly below your top menu bar.',
  },
  {
    id: 'sandboxed-security',
    question: 'Is NotchDeck secure? Can my Android phone run terminal commands on my Mac?',
    answer:
      'No. NotchDeck uses an immutable token sandbox model specifically to prevent command injection. Your phone only transmits lightweight slot numbers (such as Slot 1 or Slot 2) and has zero knowledge of filesystem paths or terminal commands. Your Mac holds sole execution authority, verifying each slot against your personal configuration and opening apps exclusively through official macOS system APIs.',
  },
  {
    id: 'zero-config-pairing',
    question: 'Do I need to sign up for an account, log in, or stay connected to the internet?',
    answer:
      'No account or internet connection is required. NotchDeck operates completely peer-to-peer over your local USB cable or private home and office Wi-Fi. No data is ever sent to the cloud, and you can run NotchDeck in an entirely air-gapped, offline environment with complete privacy.',
  },
  {
    id: 'platform-compatibility',
    question: 'Which versions of macOS and Android are supported?',
    answer:
      'NotchDeck runs natively on macOS 14 Sonoma and macOS 15 Sequoia, compiled for both Apple Silicon (M1, M2, M3, M4) and Intel processors. On Android, it supports Android 10.0 (API Level 29) or newer. The deck interface automatically scales to fit both smartphones and tablets in either portrait or landscape orientation.',
  },
  {
    id: 'shortcut-customization',
    question: 'How do I customize the 6 shortcuts on my deck?',
    answer:
      'Whenever NotchDeck is running, click the camera notch or status bar HUD on your Mac to open the configurator. Click any empty slot to choose an installed Mac application, or click the minus icon on any assigned app to remove it. Any change you make appears on your Android screen in real time.',
  },
  {
    id: 'usb-troubleshooting',
    question: 'What should I do if my Mac does not detect my Android phone over USB?',
    answer:
      'Make sure you are using a USB data cable rather than a charge-only cable. On your Android device, enable Developer Options and turn on USB Debugging. When connected, tap "Allow USB Debugging" on your phone. If macOS asks to allow the accessory to connect, click Allow.',
  },
  {
    id: 'wifi-discovery',
    question: 'How does wireless pairing over Wi-Fi work?',
    answer:
      'Both your Mac and Android phone must be connected to the same local Wi-Fi network or subnet. NotchDeck uses local mDNS multicast discovery to find your Mac automatically without manual IP configuration. Make sure your router does not have client/AP isolation enabled.',
  },
];

export interface FaqAccordionProps {
  className?: string;
  title?: string;
  subtitle?: string;
}

export default function FaqAccordion({
  className = '',
  title = 'Frequently asked questions.',
  subtitle = 'Details on connectivity, physical notch detection, sandboxed security, and offline operation.',
}: FaqAccordionProps) {
  const [openId, setOpenId] = useState<string | null>('latency-transport');

  const toggleItem = (id: string) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <section className={`faq-section ${className}`} id="faq" aria-labelledby="faq-title">
      <div className="section-heading">
        <h2 id="faq-title">{title}</h2>
        {subtitle && <p>{subtitle}</p>}
      </div>

      <div className="faq-list" role="region" aria-label="FAQ Accordion">
        {FAQ_ITEMS.map((item) => {
          const isOpen = openId === item.id;
          return (
            <div key={item.id} className="faq-item">
              <button
                type="button"
                id={`faq-trigger-${item.id}`}
                onClick={() => toggleItem(item.id)}
                aria-expanded={isOpen}
                aria-controls={`faq-answer-${item.id}`}
                className="faq-trigger"
              >
                <h3 className="faq-question">{item.question}</h3>
                <span className="faq-icon-indicator" aria-hidden="true">
                  <motion.svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2.2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    animate={{ rotate: isOpen ? 180 : 0 }}
                    transition={{ duration: 0.2, ease: 'easeInOut' }}
                  >
                    <polyline points="6 9 12 15 18 9" />
                  </motion.svg>
                </span>
              </button>

              <AnimatePresence initial={false}>
                {isOpen && (
                  <motion.div
                    id={`faq-answer-${item.id}`}
                    role="region"
                    aria-labelledby={`faq-trigger-${item.id}`}
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.22, ease: [0.16, 1, 0.3, 1] }}
                    className="faq-answer-collapse"
                  >
                    <div className="faq-answer-inner">
                      <p>{item.answer}</p>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          );
        })}
      </div>
    </section>
  );
}
