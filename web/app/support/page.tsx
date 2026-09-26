import type { Metadata } from 'next';
import FaqAccordion from '../components/FaqAccordion';

export const metadata: Metadata = {
  title: 'Support & FAQ — NotchDeck',
  description:
    'Frequently asked questions, setup help, and troubleshooting for NotchDeck macOS and Android control surface.',
};

export default function SupportPage() {
  return (
    <div className="relative min-h-dvh bg-[#f9fafd] text-[#101828]">
      {/* Top Header Only - Notch is strictly excluded */}
      <header className="support-header" aria-label="Brand Header">
        <div className="support-header-inner">
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

          <nav className="support-header-nav" aria-label="Support Navigation">
            <a href="/" className="support-back-link">
              <span aria-hidden="true">←</span>
              <span>Back to Home</span>
            </a>
          </nav>
        </div>
      </header>

      {/* Main Support Stage - Zero Cards, Zero Eyebrows, Zero Badges */}
      <main className="support-stage" id="main-content">
        {/* Intro */}
        <section className="support-intro" aria-labelledby="support-title">
          <h1 id="support-title">Support &amp; FAQ</h1>
          <p className="support-lede">
            Everything you need to know about setting up NotchDeck, hardware notch behavior,
            latency, sandboxed security, and troubleshooting.
          </p>
        </section>

        {/* Frequently Asked Questions Accordion */}
        <FaqAccordion
          className="support-faq"
          title="Frequently asked questions."
          subtitle="Details on connectivity, physical notch detection, sandboxed security, and offline operation."
        />

        {/* Quick Troubleshooting Guide */}
        <section className="support-section" aria-labelledby="troubleshoot-title">
          <h2 id="troubleshoot-title">Quick troubleshooting</h2>
          <p className="support-section-desc">
            Standard checks to quickly resolve connection or display issues.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>USB Connection Not Detected</h3>
                <p>
                  Confirm you are using a certified USB data cable rather than a charge-only cable.
                  On Android, ensure Developer Options is enabled and USB Debugging is turned on.
                  When prompted on your Mac, tap Allow Accessory to Connect.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Local Wi-Fi Discovery</h3>
                <p>
                  Ensure your Mac and Android phone are on the exact same Wi-Fi network and subnet.
                  Verify that router client isolation (AP isolation) and active VPNs that block
                  local UDP multicast traffic are disabled.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>External Monitors &amp; Notchless Displays</h3>
                <p>
                  NotchDeck automatically detects display geometry. If your MacBook is connected to
                  an external monitor or lacks a physical camera cutout, NotchDeck presents as a
                  docked status bar HUD directly underneath your top menu bar.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>App Shortcut Permissions</h3>
                <p>
                  When launching Mac applications from your phone deck, macOS may ask for
                  Automation or Accessibility permissions for NotchDeck in System Settings &gt;
                  Privacy &amp; Security. Granting this allows instant slot launching.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Direct Contact & Resources */}
        <section className="support-section" aria-labelledby="help-title">
          <h2 id="help-title">Need more assistance?</h2>
          <p className="support-section-desc">
            Explore our open-source codebase, submit bug reports, or contact the team directly.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>GitHub Issues</h3>
                <p>
                  Encountered a bug or want to request support for new slot actions? Open an issue
                  on our GitHub repository.
                </p>
              </div>
              <a
                href="https://github.com/arnel/android-deck/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="support-hairline-link"
              >
                <span>Open GitHub Issue</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Source Repository &amp; Architecture</h3>
                <p>
                  Review the native Swift daemon source, Android client APK, and the local immutable
                  token sandbox protocol.
                </p>
              </div>
              <a
                href="https://github.com/arnel/android-deck"
                target="_blank"
                rel="noopener noreferrer"
                className="support-hairline-link"
              >
                <span>View Repository</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Direct Inquiries</h3>
                <p>
                  Have questions about enterprise deployment, custom builds, or contributing? Send
                  an email to our project maintainers.
                </p>
              </div>
              <a href="mailto:support@notchdeck.app" className="support-hairline-link">
                <span>support@notchdeck.app</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>
          </ul>
        </section>

        {/* Matching Clean Footer */}
        <footer>
          <span>© 2026 NotchDeck</span>
          <nav className="links" aria-label="Footer Navigation">
            <a href="/">Home</a>
            <a href="/#features">Features</a>
            <a href="/#how-it-works">How it works</a>
            <a href="/#requirements">Requirements</a>
            <a href="/support">Support</a>
          </nav>
        </footer>
      </main>
    </div>
  );
}
