import type { Metadata } from 'next';
import Link from 'next/link';
import SiteFooter from '../components/SiteFooter';

export const metadata: Metadata = {
  title: 'Requirements & Compatibility — NotchDeck',
  description:
    'Hardware specifications, operating system compatibility, connectivity standards, and permissions required for NotchDeck.',
};

export default function RequirementsPage() {
  return (
    <div className="relative min-h-dvh bg-[#f9fafd] text-[#101828]">
      {/* Top Header - Same as Support */}
      <header className="support-header" aria-label="Brand Header">
        <div className="support-header-inner">
          <div className="brand">
            <Link className="wordmark" href="/" data-lenis-prevent="true">
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
            </Link>
            <span className="os">macOS + Android</span>
          </div>

          <nav className="support-header-nav" aria-label="Requirements Navigation">
            <Link href="/" className="support-back-link" data-lenis-prevent="true">
              <span aria-hidden="true">←</span>
              <span>Back to Home</span>
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Requirements Stage */}
      <main className="support-stage" id="main-content">
        {/* Intro */}
        <section className="support-intro" aria-labelledby="req-page-title">
          <h1 id="req-page-title">Requirements &amp; Specs</h1>
          <p className="support-lede">
            Hardware compatibility, operating system requirements, and network specifications for
            running NotchDeck locally between your Mac and Android device.
          </p>
        </section>

        {/* Section 1: Core Prerequisites */}
        <section className="support-section" aria-labelledby="core-reqs-title">
          <h2 id="core-reqs-title">Core requirements</h2>
          <p className="support-section-desc">
            The 6 essential requirements needed to run NotchDeck on your desk.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>1. Mac Host Computer</h3>
                <p>
                  <strong>macOS 14 Sonoma or newer</strong> (including macOS 15 Sequoia).
                  Fully compatible with Apple Silicon (M1, M2, M3, M4) and Intel-based MacBooks, Mac mini,
                  Mac Studio, and Mac Pro. Memory footprint is under 25 MB with ~0.1% idle CPU.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>2. Android Touchscreen Device</h3>
                <p>
                  <strong>Android 10.0 or higher</strong> (API level 29+). Works on standard Android
                  smartphones and tablets from Google, Samsung, Xiaomi, OnePlus, Motorola, and other
                  manufacturers. Supports both vertical portrait stands and horizontal desk docks.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>3. Desk Connection Bridge</h3>
                <p>
                  <strong>USB data cable or local Wi-Fi network</strong>. Any standard USB-C or USB-A
                  data cable delivers instant 0.8ms wired response. Alternatively, both devices can connect
                  wirelessly across the same local 2.4 GHz or 5 GHz Wi-Fi network.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>4. Android Phone Setup</h3>
                <p>
                  <strong>USB Debugging enabled</strong> in Android Developer Options. Required for
                  wired 0.8ms zero-latency USB communication. Does not require root access, bootloader
                  unlocking, or third-party system modifications.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>5. macOS App Permissions</h3>
                <p>
                  <strong>Accessibility permission</strong> in macOS System Settings &gt; Privacy &amp; Security.
                  Enables NotchDeck to switch application windows, execute chosen keyboard shortcuts,
                  and adjust system volume when buttons are tapped on your phone.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>6. Privacy &amp; Local Network</h3>
                <p>
                  <strong>100% offline and sandboxed</strong>. No user accounts, registration, cloud servers,
                  or internet connectivity required. All touch events, slot configurations, and telemetry stay
                  strictly between your Mac and phone on your desk.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 2: Display & Hardware Adaptation */}
        <section className="support-section" aria-labelledby="display-support-title">
          <h2 id="display-support-title">Display &amp; notch adaptation</h2>
          <p className="support-section-desc">
            How the macOS liquid glass HUD behaves across different Mac displays and monitors.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>MacBook Displays with Camera Notch</h3>
                <p>
                  On 14-inch and 16-inch MacBook Pro models with a physical camera notch, NotchDeck
                  hugs the notch contours with fluid spring animations, expanding smoothly when configured.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>External Monitors &amp; Notchless Macs</h3>
                <p>
                  On external monitors, Apple Studio Displays, or notchless Macs (Mac mini, Mac Studio,
                  MacBook Air M1), NotchDeck gracefully docks directly beneath the top menu bar as a
                  minimalist pill HUD with custom position controls.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>OLED &amp; Battery Protection on Android</h3>
                <p>
                  The Android client uses an ultra-deep black theme (`#000000`) optimized for OLED and
                  AMOLED screens, preventing burn-in and minimizing power consumption during all-day desk use.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 3: Connection Standards & Performance */}
        <section className="support-section" aria-labelledby="latency-title">
          <h2 id="latency-title">Connection standards &amp; speed</h2>
          <p className="support-section-desc">
            Technical performance metrics and network protocols used by NotchDeck.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Wired USB Connection (Recommended)</h3>
                <p>
                  Uses high-speed local ADB socket forwarding (`tcp:8421`). Delivers an ultra-responsive
                  <strong>0.8ms round-trip latency</strong>. Functions completely without an internet connection
                  or active Wi-Fi router.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Wireless Local Wi-Fi</h3>
                <p>
                  Uses zero-configuration UDP multicast for automatic discovery on your local network.
                  Typically delivers <strong>3ms to 8ms latency</strong> depending on your Wi-Fi environment.
                  Ensure router AP isolation is turned off so local devices can communicate.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Corporate VPNs &amp; Firewalls</h3>
                <p>
                  If you are connected to a corporate VPN that blocks local subnet traffic, the wired USB
                  mode continues to function seamlessly because it operates via direct hardware loopback.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 4: Quick Setup Checklist */}
        <section className="support-section" aria-labelledby="setup-checklist-title">
          <h2 id="setup-checklist-title">Quick setup checklist</h2>
          <p className="support-section-desc">
            Follow these 4 steps to get NotchDeck running on your desk in under 2 minutes.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Step 1: Install Mac App</h3>
                <p>
                  Download and move <code>NotchDeck.app</code> to your Mac's Applications folder.
                  Launch it to see the liquid glass HUD dock to your camera notch or menu bar.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Step 2: Install Android App</h3>
                <p>
                  Install <code>NotchDeck.apk</code> on your Android phone or tablet. Launch the app and place
                  your phone in your desk stand.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Step 3: Connect via USB or Wi-Fi</h3>
                <p>
                  Plug your phone into your Mac with a USB cable (with USB debugging ON), or connect both
                  devices to the same Wi-Fi network. The deck connects automatically.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Step 4: Grant Accessibility &amp; Start Tapping</h3>
                <p>
                  When prompted on your Mac, toggle NotchDeck ON in System Settings &gt; Privacy &amp; Security &gt;
                  Accessibility. Customize your 6 slots and start controlling your Mac instantly.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Resources & Support Links */}
        <section className="support-section" aria-labelledby="resources-title">
          <h2 id="resources-title">Need help with setup?</h2>
          <p className="support-section-desc">
            Check our troubleshooting guide or get in touch with the community.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Support &amp; Troubleshooting Guide</h3>
                <p>
                  Find answers to common questions about USB discovery, notch behavior, and shortcut automation.
                </p>
              </div>
              <a href="/support" className="support-hairline-link">
                <span>Go to Support</span>
                <span aria-hidden="true">→</span>
              </a>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Technical &amp; Hardware Compatibility</h3>
                <p>
                  Have questions about a specific Android model, multi-display Mac desk setup, or USB cable?
                  Reach out directly and I will be happy to help you verify your setup.
                </p>
              </div>
              <a href="mailto:arnelbaylon15@gmail.com" className="support-hairline-link">
                <span>arnelbaylon15@gmail.com</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>
          </ul>
        </section>

        {/* Reusable Clean Site Footer */}
        <SiteFooter />
      </main>
    </div>
  );
}
