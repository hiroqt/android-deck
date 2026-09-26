'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { AnimatePresence, motion } from 'motion/react';
import TopNotchIsland from './components/TopNotchIsland';
import FigureShowcase from './components/FigureShowcase';
import CoreFeatures from './components/CoreFeatures';
import CtaMacbookDemo from './components/CtaMacbookDemo';
import SiteFooter from './components/SiteFooter';

function AppleLetterIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 814 1000"
      fill="currentColor"
      aria-hidden="true"
    >
      <path
        stroke="white"
        strokeWidth="24"
        strokeLinejoin="round"
        paintOrder="stroke fill"
        d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76.5 0-103.7 40.8-165.9 40.8s-105.6-57-155.5-127C46.7 790.7 0 663 0 541.8c0-194.4 126.4-297.5 250.8-297.5 66.1 0 121.2 43.4 162.7 43.4 39.5 0 101.1-46 176.3-46 28.5 0 130.9 2.6 198.3 99.2zm-234-181.5c31.1-36.9 53.1-88.1 53.1-139.3 0-7.1-.6-14.3-1.9-20.1-50.6 1.9-110.8 33.7-147.1 75.8-28.5 32.4-55.1 83.6-55.1 135.5 0 7.8 1.3 15.6 1.9 18.1 3.2.6 8.4 1.3 13.6 1.3 45.4 0 102.5-30.4 135.5-71.3z"
      />
    </svg>
  );
}

function AndroidLetterIcon({ className }: { className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 128 128"
      fill="currentColor"
      aria-hidden="true"
    >
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        stroke="white"
        strokeWidth="3.2"
        strokeLinejoin="round"
        paintOrder="stroke fill"
        d="M21.005 43.003c-4.053-.002-7.338 3.291-7.339 7.341l.005 30.736a7.338 7.338 0 007.342 7.343 7.33 7.33 0 007.338-7.342V50.34a7.345 7.345 0 00-7.346-7.337m59.193-27.602l5.123-9.355a1.023 1.023 0 00-.401-1.388 1.022 1.022 0 00-1.382.407l-5.175 9.453c-4.354-1.938-9.227-3.024-14.383-3.019-5.142-.005-10.013 1.078-14.349 3.005L44.45 5.075a1.01 1.01 0 00-1.378-.406 1.007 1.007 0 00-.404 1.38l5.125 9.349c-10.07 5.193-16.874 15.083-16.868 26.438l66.118-.008c.002-11.351-6.79-21.221-16.845-26.427M48.942 29.858a2.772 2.772 0 01.003-5.545 2.78 2.78 0 012.775 2.774 2.776 2.776 0 01-2.778 2.771m30.106-.005a2.77 2.77 0 01-2.772-2.771 2.793 2.793 0 012.773-2.778 2.79 2.79 0 012.767 2.779 2.767 2.767 0 01-2.768 2.77M31.195 44.39l.011 47.635a7.822 7.822 0 007.832 7.831l5.333.002.006 16.264c-.001 4.05 3.291 7.342 7.335 7.342 4.056 0 7.342-3.295 7.343-7.347l-.004-16.26 9.909-.003.004 16.263c0 4.047 3.293 7.346 7.338 7.338 4.056.003 7.344-3.292 7.343-7.344l-.005-16.259 5.352-.004a7.835 7.835 0 007.836-7.834l-.009-47.635-65.624.011zm83.134 5.943a7.338 7.338 0 00-7.341-7.339c-4.053-.004-7.337 3.287-7.337 7.342l.006 30.738a7.334 7.334 0 007.339 7.339 7.337 7.337 0 007.338-7.343l-.005-30.737z"
      />
    </svg>
  );
}

function NotchClickHint() {
  const [isTopDocked, setIsTopDocked] = useState(true);

  useEffect(() => {
    const handlePositionChange = (event: Event) => {
      const { position } = (event as CustomEvent<{ position: string }>).detail;
      setIsTopDocked(position === 'top' || position === 'floating');
    };

    window.addEventListener('notchdeck-position-change', handlePositionChange);
    return () => window.removeEventListener('notchdeck-position-change', handlePositionChange);
  }, []);

  return (
    <AnimatePresence>
      {isTopDocked && (
        <motion.div
          className="notch-click-hint"
          initial={{ opacity: 0, y: -4 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -4 }}
          transition={{ duration: 0.18, ease: 'easeOut' }}
          aria-hidden="true"
        >
          <svg viewBox="0 0 34 40" fill="none">
            <path d="M28 35C17 29 11 21 10 8" />
            <path d="M4 15L10 7L17 13" />
          </svg>
          <span>grab me to the sides</span>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export default function HomePage() {
  return (
    <div className="relative min-h-dvh bg-[#f9fafd] text-[#101828]">
      {/* Draggable Top Notch Navigation & HUD Island */}
      <TopNotchIsland />
      <NotchClickHint />

      {/* Topbar: Wordmark & Notch Trigger */}
      <header className="topbar" aria-label="Brand Header">
        <div className="brand">
          <a className="wordmark" href="/">
            <svg
              className="w-5 h-5 text-[#101828]"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.2"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <rect x="2" y="3" width="20" height="14" rx="2" />
              <line x1="8" y1="21" x2="16" y2="21" />
              <line x1="12" y1="17" x2="12" y2="21" />
            </svg>
            <span>notchdeck</span>
          </a>
          <span className="os">macOS + Android</span>
        </div>
      </header>

      {/* Main Single-Column Stage */}
      <main className="stage" id="main-content">
        {/* Intro */}
        <section className="hero" aria-labelledby="hero-title">
          <div className="intro">
            <h1 id="hero-title">
              <span className="hero-line">
                Your{' '}
                <span className="platform-word macbook-word">
                  M<AppleLetterIcon className="inline-letter-icon apple-letter-icon" />cBook
                </span>{' '}
                notch.
              </span>
              <span className="hero-line">
                Your{' '}
                <span className="platform-word android-word">
                  <AndroidLetterIcon className="inline-letter-icon android-letter-icon" />ndroid
                </span>{' '}
                control deck.
              </span>
            </h1>
            <p className="lede">
              Choose Mac shortcuts in the camera notch, then launch them from your phone.
            </p>
          </div>

          <div className="actions">
            <div className="hero-actions-row">
              <button
                type="button"
                className="button cursor-pointer"
                onClick={() => {
                  window.dispatchEvent(new CustomEvent('notchdeck-try-notch'));
                }}
              >
                <span>Try notch</span>
                <span className="amount" aria-hidden="true">✦</span>
              </button>
              <a
                className="secondary-button"
                href="/downloads/NotchDeck.dmg"
                download="NotchDeck.dmg"
              >
                <AppleLetterIcon className="w-3.5 h-3.5 inline-block -mt-0.5 mr-1" />
                <span>Download</span>
                <span aria-hidden="true">↓</span>
              </a>
            </div>
            <div className="flex items-center gap-2 text-[12px] text-[#526077] pt-3 font-medium">
              <span className="inline-flex items-center justify-center px-1.5 py-0.5 rounded bg-emerald-100 text-emerald-800 text-[10.5px] font-semibold tracking-wide uppercase">
                Android APK
              </span>
              <span>Install Mac app, then scan the QR in Settings to download the phone APK</span>
            </div>
          </div>
        </section>

        {/* Breakout Figure Showcase: MacBook Notch HUD & Android Phone Deck */}
        <FigureShowcase />

        {/* 6 Core Superpower Features in 2x3 Squircle Grid */}
        <CoreFeatures />

        <section className="how-section" id="how-it-works" aria-labelledby="how-title">
          <div className="section-heading">
            <span className="section-kicker">How does it work?</span>
            <h2 id="how-title">Ready in three simple steps.</h2>
            <p>Keep your most-used Mac apps and controls within easy reach on your phone.</p>
          </div>

          <ol className="steps-list">
            <li>
              <span className="step-number" aria-hidden="true">1</span>
              <div>
                <h3>Download NotchDeck for Mac</h3>
                <p>
                  Download <code>NotchDeck.dmg</code>, drag it to Applications, and launch.
                  It runs automatically with zero terminal commands.
                </p>
              </div>
              <span className="step-detail">macOS .dmg</span>
            </li>
            <li>
              <span className="step-number" aria-hidden="true">2</span>
              <div>
                <h3>Scan QR to download phone APK</h3>
                <p>
                  Open NotchDeck Preferences on your Mac, click the Android App tab, and
                  scan the QR code with your phone camera to download the APK.
                </p>
              </div>
              <span className="step-detail">Scan QR</span>
            </li>
            <li>
              <span className="step-number" aria-hidden="true">3</span>
              <div>
                <h3>Connect &amp; tap your shortcuts</h3>
                <p>
                  Connect via USB cable or local Wi-Fi. Your 6 shortcuts synchronize
                  live between your camera notch and your phone.
                </p>
              </div>
              <span className="step-detail">Instant</span>
            </li>
          </ol>

          <aside className="privacy-note" aria-label="Privacy information">
            <span className="privacy-icon" aria-hidden="true">✓</span>
            <div>
              <strong>Your shortcuts stay private.</strong>
              <p>No account or cloud service is needed. Your phone talks directly to your Mac.</p>
            </div>
          </aside>
        </section>

        <section className="closing-section" id="get-started" aria-labelledby="closing-title">
          <div className="closing-header">
            <div>
              <span className="section-kicker">Ready to get started?</span>
              <h2 id="closing-title">Your everyday shortcuts, one tap away.</h2>
              <p>Set up six controls for the apps and actions you reach for all day.</p>
            </div>
            <a className="button" href="/downloads/NotchDeck.dmg" download="NotchDeck.dmg">
              <span>Get NotchDeck</span>
              <span className="amount" aria-hidden="true">↓</span>
            </a>
          </div>
          <CtaMacbookDemo />
        </section>

        {/* Reusable Clean Site Footer */}
        <SiteFooter hideHome />
      </main>
    </div>
  );
}
