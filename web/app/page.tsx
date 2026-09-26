'use client';

import { useState } from 'react';
import TopNotchIsland from './components/TopNotchIsland';
import FigureShowcase from './components/FigureShowcase';

export default function HomePage() {
  const [copiedCmd, setCopiedCmd] = useState<string | null>(null);

  const handleCopy = async (cmd: string) => {
    try {
      await navigator.clipboard.writeText(cmd);
      setCopiedCmd(cmd);
      setTimeout(() => setCopiedCmd(null), 2000);
    } catch {
      const textarea = document.createElement('textarea');
      textarea.value = cmd;
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
      setCopiedCmd(cmd);
      setTimeout(() => setCopiedCmd(null), 2000);
    }
  };

  const handleToggleNotch = () => {
    window.dispatchEvent(new CustomEvent('macdeck-toggle-notch'));
  };

  return (
    <div className="relative min-h-screen bg-[#f9fafd] text-[#101828]">
      {/* Draggable Top Notch Navigation & HUD Island */}
      <TopNotchIsland />

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
            <span>macdeck</span>
          </a>
          <span className="os">macOS + Android</span>
          <button
            type="button"
            onClick={handleToggleNotch}
            className="pill"
            title="Toggle Notch dock position: Top, Left, or Right"
            aria-label="Toggle Notch dock position"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            <span>Dock: Top / Side</span>
          </button>
        </div>
      </header>

      {/* Main Single-Column Stage */}
      <main className="stage" id="main-content">
        {/* Intro */}
        <div className="intro">
          <h1>Your phone is now your stream deck.</h1>
          <p className="lede">
            Zero-latency desk control over USB. Configure slots live from the notch you already
            have.
          </p>
        </div>

        {/* Action Button & Platform Note */}
        <div className="actions">
          <a className="button" href="#setup">
            <span>Get MacDeck</span>
            <span className="amount">v1.0</span>
          </a>
          <p className="note">For macOS 14+ and Android 10+ • Local loopback over USB</p>
        </div>

        {/* Breakout Figure Showcase: MacBook Notch HUD & Android Phone Deck */}
        <FigureShowcase />

        {/* Stack of Definition List Cards */}
        <div className="stack" id="stack">
          <div className="stack-scroll" id="stackScroll">
            {/* How it works */}
            <section className="card" id="how-it-works" aria-labelledby="how-it-works-title">
              <h2 id="how-it-works-title">How it works</h2>
              <dl>
                <div className="row">
                  <dt>USB reverse tunnel</dt>
                  <dd>
                    A single Type-C cable establishes an ADB loopback tunnel on port 8765. Zero WiFi
                    congestion, zero Bluetooth pairing dropouts, sub-millisecond response.
                  </dd>
                </div>
                <div className="row">
                  <dt>Fluid Notch HUD</dt>
                  <dd>
                    Click or drag the MacBook camera notch to reveal the 6-slot liquid glass
                    configurator. Reorder, assign, or clear apps instantly with native AppKit
                    performance.
                  </dd>
                </div>
                <div className="row">
                  <dt>Tactile phone grid</dt>
                  <dd>
                    Your Android screen mirrors the 6 slots as tactile squircles with physical
                    feedback. Instant sub-16ms actuation launches macOS apps via native
                    NSWorkspace.
                  </dd>
                </div>
                <div className="row">
                  <dt>Bidirectional sync</dt>
                  <dd>
                    Changes made in the macOS Notch panel reflect on the phone in real time over the
                    loopback protocol. No configuration files to reload or restart.
                  </dd>
                </div>
              </dl>
            </section>

            {/* Setup & Commands */}
            <section className="card" id="setup" aria-labelledby="setup-title">
              <h2 id="setup-title">Setup &amp; Commands</h2>
              <dl>
                <div className="row">
                  <dt>1. Start Mac host</dt>
                  <dd className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <span>Run the local loopback WebSocket server on port 8765:</span>
                    <button
                      type="button"
                      onClick={() => handleCopy('./scripts/run_mac.sh')}
                      className="cursor-pointer text-left"
                      title="Click to copy command"
                    >
                      <code className="inline-cmd">
                        ./scripts/run_mac.sh
                        <span className="text-[10px] text-[#667085] ml-1">
                          {copiedCmd === './scripts/run_mac.sh' ? 'Copied' : 'Copy'}
                        </span>
                      </code>
                    </button>
                  </dd>
                </div>

                <div className="row">
                  <dt>2. Launch Notch HUD</dt>
                  <dd className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <span>Attach the liquid glass panel to your MacBook camera notch:</span>
                    <button
                      type="button"
                      onClick={() => handleCopy('./scripts/run_notchdeck.sh')}
                      className="cursor-pointer text-left"
                      title="Click to copy command"
                    >
                      <code className="inline-cmd">
                        ./scripts/run_notchdeck.sh
                        <span className="text-[10px] text-[#667085] ml-1">
                          {copiedCmd === './scripts/run_notchdeck.sh' ? 'Copied' : 'Copy'}
                        </span>
                      </code>
                    </button>
                  </dd>
                </div>

                <div className="row">
                  <dt>3. Connect USB</dt>
                  <dd className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <span>Reverse the ADB port to route local traffic between devices:</span>
                    <button
                      type="button"
                      onClick={() => handleCopy('./scripts/usb/connect.sh')}
                      className="cursor-pointer text-left"
                      title="Click to copy command"
                    >
                      <code className="inline-cmd">
                        ./scripts/usb/connect.sh
                        <span className="text-[10px] text-[#667085] ml-1">
                          {copiedCmd === './scripts/usb/connect.sh' ? 'Copied' : 'Copy'}
                        </span>
                      </code>
                    </button>
                  </dd>
                </div>

                <div className="row">
                  <dt>4. Install Android</dt>
                  <dd className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <span>Deploy the Jetpack Compose client to your device:</span>
                    <button
                      type="button"
                      onClick={() => handleCopy('./scripts/install_android.sh')}
                      className="cursor-pointer text-left"
                      title="Click to copy command"
                    >
                      <code className="inline-cmd">
                        ./scripts/install_android.sh
                        <span className="text-[10px] text-[#667085] ml-1">
                          {copiedCmd === './scripts/install_android.sh' ? 'Copied' : 'Copy'}
                        </span>
                      </code>
                    </button>
                  </dd>
                </div>
              </dl>
            </section>

            {/* Requirements */}
            <section className="card" id="requirements" aria-labelledby="requirements-title">
              <h2 id="requirements-title">Requirements</h2>
              <dl>
                <div className="row">
                  <dt>macOS</dt>
                  <dd>macOS 14 Sonoma or macOS 15 Sequoia. Apple Silicon or Intel.</dd>
                </div>
                <div className="row">
                  <dt>Android</dt>
                  <dd>
                    Android 10 (API 29) or higher with USB debugging enabled. Tested on Pixel,
                    Samsung Galaxy, and OnePlus.
                  </dd>
                </div>
                <div className="row">
                  <dt>Connection</dt>
                  <dd>
                    Standard USB-C to USB-C or USB-A to USB-C cable. No internet access or cloud
                    relay required.
                  </dd>
                </div>
                <div className="row">
                  <dt>Toolchain</dt>
                  <dd>
                    Swift 5.9+ for the AppKit notch client, Python 3.10+ for the host server,
                    Android SDK 34+ for the Compose app.
                  </dd>
                </div>
              </dl>
            </section>

            {/* Private by design */}
            <section className="card" id="privacy" aria-labelledby="privacy-title">
              <h2 id="privacy-title">Private by design</h2>
              <dl>
                <div className="row">
                  <dt>100% Offline</dt>
                  <dd>
                    All telemetry stays strictly on the hardware loopback (127.0.0.1). Zero outbound
                    network calls, zero analytics tracking.
                  </dd>
                </div>
                <div className="row">
                  <dt>Sandboxed actions</dt>
                  <dd>
                    The Android deck transmits only abstract token IDs (such as app-1). Arbitrary
                    shell commands cannot be injected over the wire.
                  </dd>
                </div>
                <div className="row">
                  <dt>No account</dt>
                  <dd>No cloud login, no registration, no subscription. Free and open source.</dd>
                </div>
                <div className="row">
                  <dt>Open source</dt>
                  <dd>
                    Full source code for the Swift AppKit Notch, Python host server, and Kotlin
                    Compose client is auditable and open.
                  </dd>
                </div>
              </dl>
            </section>

            {/* Clean Bendy-Style Footer */}
            <footer>
              <span>© 2026 MacDeck</span>
              <nav className="links" aria-label="Footer Navigation">
                <a href="#how-it-works">How it works</a>
                <a href="#setup">Setup</a>
                <a href="#requirements">Requirements</a>
                <a href="#privacy">Privacy</a>
                <a
                  href="https://github.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  aria-label="Source code on GitHub (opens in a new tab)"
                >
                  Source
                </a>
              </nav>
            </footer>
          </div>
        </div>
      </main>
    </div>
  );
}
