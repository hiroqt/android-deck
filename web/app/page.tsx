'use client';

import TopNotchIsland from './components/TopNotchIsland';
import FigureShowcase from './components/FigureShowcase';

export default function HomePage() {
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
          <a className="button" href="#specs">
            <span>View Specifications</span>
            <span className="amount">v1.0</span>
          </a>
          <p className="note">For macOS 14+ and Android 10+ • Local loopback over USB</p>
        </div>

        {/* Breakout Figure Showcase: MacBook Notch HUD & Android Phone Deck */}
        <FigureShowcase />

        {/* Precision Technical Specifications Sheet */}
        <section className="spec-sheet" id="specs" aria-labelledby="specs-title">
          <div className="spec-sheet-header">
            <div className="spec-sheet-tag">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              <span>System &amp; Hardware Specifications</span>
            </div>
            <h2 className="spec-sheet-title" id="specs-title">
              Engineered for Zero-Latency Desk Control.
            </h2>
            <p className="spec-sheet-desc">
              Direct hardware loopback bridging native macOS AppKit and Android Jetpack Compose
              without cloud mediators, wireless pairing dropouts, or background telemetry.
            </p>
          </div>

          {/* 4-Quadrant Precision Spec Matrix */}
          <div className="spec-matrix">
            {/* 1. macOS Host */}
            <div className="spec-block">
              <div>
                <div className="spec-block-top">
                  <div className="spec-block-title-wrap">
                    <span className="spec-block-category">Host System</span>
                    <h3 className="spec-block-name">macOS Engine</h3>
                  </div>
                  <span className="spec-chip emerald">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    Sonoma / Sequoia
                  </span>
                </div>

                <div className="spec-row-list">
                  <div className="spec-item">
                    <span className="spec-item-label">Supported Architecture</span>
                    <span className="spec-item-val">
                      Universal Binary • <strong>Apple Silicon (M1–M4)</strong> &amp; <strong>Intel x86_64</strong>
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Display &amp; Notch HUD</span>
                    <span className="spec-item-val">
                      Native AppKit panel attached to MacBook camera notch or side dock
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Actuation Engine</span>
                    <span className="spec-item-val">
                      Direct <code className="spec-item-code">NSWorkspace</code> application launch with sub-16ms actuation
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Privilege Level</span>
                    <span className="spec-item-val">
                      Standard user permissions • <strong>Zero KEXTs or system extensions</strong>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* 2. Android Device */}
            <div className="spec-block">
              <div>
                <div className="spec-block-top">
                  <div className="spec-block-title-wrap">
                    <span className="spec-block-category">Client Deck</span>
                    <h3 className="spec-block-name">Android Surface</h3>
                  </div>
                  <span className="spec-chip emerald">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    API 29–35
                  </span>
                </div>

                <div className="spec-row-list">
                  <div className="spec-item">
                    <span className="spec-item-label">Minimum OS Version</span>
                    <span className="spec-item-val">
                      <strong>Android 10.0 (Q)</strong> or newer • API Level 29 through 35+
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Surface Interface</span>
                    <span className="spec-item-val">
                      Jetpack Compose adaptive squircle grid with real-time slot state sync
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Touchscreen Actuation</span>
                    <span className="spec-item-val">
                      Haptic confirmation with physical pulse feedback on tap actuation
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Hardware Tested</span>
                    <span className="spec-item-val">
                      Google Pixel series, Samsung Galaxy, OnePlus, Xiaomi devices
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* 3. Hardware Bus */}
            <div className="spec-block">
              <div>
                <div className="spec-block-top">
                  <div className="spec-block-title-wrap">
                    <span className="spec-block-category">Hardware Bus</span>
                    <h3 className="spec-block-name">USB Loopback Transit</h3>
                  </div>
                  <span className="spec-chip">
                    <span className="w-1.5 h-1.5 rounded-full bg-blue-500" />
                    Port 8765
                  </span>
                </div>

                <div className="spec-row-list">
                  <div className="spec-item">
                    <span className="spec-item-label">Physical Interface</span>
                    <span className="spec-item-val">
                      Standard USB-C to USB-C or USB-A to USB-C data cable
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Network Transport</span>
                    <span className="spec-item-val">
                      ADB reverse socket tunnel over local hardware loopback (<code className="spec-item-code">127.0.0.1</code>)
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">In-Transit Delay</span>
                    <span className="spec-item-val">
                      <strong>&lt; 0.8ms round-trip</strong> packet transport with zero WiFi jitter
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Data Privacy</span>
                    <span className="spec-item-val">
                      <strong>100% Offline</strong> • Zero analytics, zero cloud relays, fully air-gapped
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* 4. Toolchain */}
            <div className="spec-block">
              <div>
                <div className="spec-block-top">
                  <div className="spec-block-title-wrap">
                    <span className="spec-block-category">Runtime &amp; Build</span>
                    <h3 className="spec-block-name">Native Toolchain</h3>
                  </div>
                  <span className="spec-chip">
                    <span className="w-1.5 h-1.5 rounded-full bg-purple-500" />
                    Open Source
                  </span>
                </div>

                <div className="spec-row-list">
                  <div className="spec-item">
                    <span className="spec-item-label">macOS Notch HUD</span>
                    <span className="spec-item-val">
                      <strong>Swift 5.9+</strong> with native AppKit, CoreAnimation &amp; Combine
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Host Bridge Server</span>
                    <span className="spec-item-val">
                      <strong>Python 3.10+</strong> asyncio daemon with lightweight WebSocket protocol
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Android Deck Client</span>
                    <span className="spec-item-val">
                      <strong>Kotlin 2.0+</strong>, Jetpack Compose Material3, Coroutines, OkHttp
                    </span>
                  </div>
                  <div className="spec-item">
                    <span className="spec-item-label">Distribution &amp; Security</span>
                    <span className="spec-item-val">
                      MIT License • Fully auditable source code with sandboxed action tokens
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Precision Spec Status Bar */}
          <div className="spec-footer-bar">
            <div className="spec-footer-item">
              <span className="w-2 h-2 rounded-full bg-emerald-500 shadow-[0_0_6px_rgba(16,185,129,0.7)]" />
              <span>Status: <span className="code-accent">ALL SPECIFICATIONS VERIFIED</span></span>
            </div>
            <div className="spec-footer-item">
              <span className="text-[#98a2b3]">Protocol:</span>
              <span className="code-accent">ADB Loopback :8765</span>
            </div>
            <div className="spec-footer-item">
              <span className="text-[#98a2b3]">Actuation:</span>
              <span className="code-accent">&lt; 0.8ms Direct Bus</span>
            </div>
            <div className="spec-footer-item">
              <span className="text-[#98a2b3]">Architecture:</span>
              <span className="code-accent">Zero-Driver Plug &amp; Play</span>
            </div>
          </div>
        </section>

        {/* Clean Bendy-Style Footer */}
        <footer>
          <span>© 2026 MacDeck</span>
          <nav className="links" aria-label="Footer Navigation">
            <a href="#specs">Specifications</a>
            <a
              href="https://github.com"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="Source code on GitHub (opens in a new tab)"
            >
              GitHub
            </a>
          </nav>
        </footer>
      </main>
    </div>
  );
}
