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

        {/* Editorial Architecture & Specifications Section (Zero Cards, nvidia-hackathon layout) */}
        <section className="editorial-specs-section" id="specs" aria-labelledby="specs-title">
          <div className="editorial-specs-grid">
            {/* Left Column: Lead Narrative & Checklist */}
            <div className="editorial-specs-lead">
              <div className="specs-eyebrow">
                <span className="dot" />
                <span>Architecture &amp; System Specs</span>
              </div>
              <h2 className="editorial-specs-title" id="specs-title">
                Zero latency. <em>Zero cards.</em><br />
                Direct hardware desk control.
              </h2>
              <p className="editorial-specs-desc">
                MacDeck connects your MacBook and Android device through a direct, high-throughput
                hardware loopback over USB Type-C. No wireless pairing jitter, no cloud relay servers,
                and zero third-party drivers.
              </p>

              <div className="specs-checklist">
                <div className="specs-check-item">
                  <span className="specs-check-icon" aria-hidden="true">✓</span>
                  <div>
                    <strong>Sub-0.8ms deterministic transit</strong>
                    <div className="text-[13px] text-[#667085]">
                      Hardware ADB reverse loopback tunnel routed strictly through local port 8765.
                    </div>
                  </div>
                </div>

                <div className="specs-check-item">
                  <span className="specs-check-icon" aria-hidden="true">✓</span>
                  <div>
                    <strong>100% Offline &amp; Private by design</strong>
                    <div className="text-[13px] text-[#667085]">
                      Air-gapped telemetry bus. Transmits only abstract action tokens with zero outbound network calls.
                    </div>
                  </div>
                </div>

                <div className="specs-check-item">
                  <span className="specs-check-icon" aria-hidden="true">✓</span>
                  <div>
                    <strong>Native AppKit &amp; Compose integration</strong>
                    <div className="text-[13px] text-[#667085]">
                      Swift liquid glass camera notch HUD paired with Kotlin tactile squircle feedback.
                    </div>
                  </div>
                </div>

                <div className="specs-check-item">
                  <span className="specs-check-icon" aria-hidden="true">✓</span>
                  <div>
                    <strong>Zero-driver plug &amp; play</strong>
                    <div className="text-[13px] text-[#667085]">
                      Standard user-space permissions. No kernel extensions, KEXTs, or system modifications.
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Right Column: Clean Editorial Technical Breakdown (Lines & Dividers, No Boxes) */}
            <div className="specs-breakdown">
              <div className="specs-breakdown-row">
                <div className="specs-row-header">
                  <h3>macOS Host System</h3>
                  <span className="specs-pill-badge">Sonoma 14+ / Sequoia 15+</span>
                </div>
                <p>
                  Universal Binary compiled natively for <strong>Apple Silicon (M1–M4)</strong> and <strong>Intel x86_64</strong>.
                  Renders the liquid notch panel via native AppKit and triggers applications through direct <code>NSWorkspace</code> actuation in under 16ms.
                </p>
              </div>

              <div className="specs-breakdown-row">
                <div className="specs-row-header">
                  <h3>Android Touch Surface</h3>
                  <span className="specs-pill-badge">Android 10.0+ (API 29–35)</span>
                </div>
                <p>
                  Built with modern <strong>Jetpack Compose Material3</strong>. Features custom tactile squircles with physical haptic impulse actuation. Verified and tested across Pixel, Samsung Galaxy, OnePlus, and Xiaomi hardware.
                </p>
              </div>

              <div className="specs-breakdown-row">
                <div className="specs-row-header">
                  <h3>Hardware Physical Bus</h3>
                  <span className="specs-pill-badge">Port 8765 Loopback</span>
                </div>
                <p>
                  Standard USB-C to USB-C or USB-A to USB-C data cable. Routes traffic over ADB reverse socket binding to <code>127.0.0.1:8765</code>, eliminating Wi-Fi congestion and Bluetooth pairing dropouts.
                </p>
              </div>

              <div className="specs-breakdown-row">
                <div className="specs-row-header">
                  <h3>Native Toolchain &amp; Licensing</h3>
                  <span className="specs-pill-badge">MIT Open Source</span>
                </div>
                <p>
                  Architected with <strong>Swift 5.9+</strong>, <strong>Kotlin 2.0+</strong>, and a lightweight <strong>Python 3.10+</strong> asyncio daemon. Complete code is auditable and open for inspection.
                </p>
              </div>
            </div>
          </div>

          {/* Bottom Editorial Meta Bar */}
          <div className="editorial-specs-footer">
            <span>
              <span className="w-2 h-2 rounded-full bg-emerald-500 shadow-[0_0_6px_rgba(16,185,129,0.7)]" />
              <span>Status: <code>VERIFIED READY FOR DESK</code></span>
            </span>
            <span>Loopback Route: <code>127.0.0.1:8765</code></span>
            <span>Transit Delay: <code>&lt; 0.8ms Direct Bus</code></span>
            <span>Distribution: <code>Free &amp; Open Source</code></span>
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
