import type { Metadata } from 'next';
import Link from 'next/link';
import FaqAccordion from '../components/FaqAccordion';
import SiteFooter from '../components/SiteFooter';

export const metadata: Metadata = {
  title: 'Customer Support & Help Center — NotchDeck',
  description:
    'Customer care, license activation assistance, hardware troubleshooting, and direct support for NotchDeck macOS and Android control surface.',
};

export default function SupportPage() {
  return (
    <div className="relative min-h-dvh bg-[#f9fafd] text-[#101828]">
      {/* Top Header */}
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

          <nav className="support-header-nav" aria-label="Support Navigation">
            <Link href="/" className="support-back-link" data-lenis-prevent="true">
              <span aria-hidden="true">←</span>
              <span>Back to Home</span>
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Support Stage */}
      <main className="support-stage" id="main-content">
        {/* Intro */}
        <section className="support-intro" aria-labelledby="support-title">
          <h1 id="support-title">Help &amp; Customer Support</h1>
          <p className="support-lede">
            Get help with your license, device setup, hardware troubleshooting, and direct
            assistance from the developer.
          </p>
        </section>

        {/* Commercial Licensing & Activation */}
        <section className="support-section" aria-labelledby="licensing-title">
          <h2 id="licensing-title">Licensing &amp; purchases</h2>
          <p className="support-section-desc">
            Answers regarding your NotchDeck license, device activation, and purchase protection.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Lifetime License &amp; Device Usage</h3>
                <p>
                  Every NotchDeck purchase includes a perpetual, lifetime license. Your single license
                  covers your primary Mac and companion Android touchscreen devices, including all
                  maintenance updates within the major version.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Transferring to a New Mac or Phone</h3>
                <p>
                  Upgrading your workstation? You can transfer your NotchDeck license to a new Mac
                  or Android device at any time. Simply install the app on your new machine and
                  enter your license key. There are no transfer fees.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Lost License Key Recovery</h3>
                <p>
                  Can&apos;t find your purchase confirmation receipt or license key? Send a quick email
                  from your purchase address to <strong>arnelbaylon15@gmail.com</strong>, and I will
                  resend your key right away.
                </p>
              </div>
              <a href="mailto:arnelbaylon15@gmail.com" className="support-hairline-link">
                <span>Resend My Key</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>7-Day Money-Back Guarantee</h3>
                <p>
                  I want you to love your desk setup. If NotchDeck does not fit into your daily
                  workflow or perform to your satisfaction, contact me within 7 days of purchase
                  for a 100% full refund—no questions asked.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Quick Troubleshooting Guide */}
        <section className="support-section" aria-labelledby="troubleshoot-title">
          <h2 id="troubleshoot-title">Hardware &amp; connection troubleshooting</h2>
          <p className="support-section-desc">
            Standard checks to quickly resolve USB, Wi-Fi, or display permission issues.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>USB Connection Not Detected</h3>
                <p>
                  Confirm you are using a certified USB data cable rather than a charge-only cable.
                  On Android, ensure Developer Options is enabled and USB Debugging is turned on.
                  When prompted on your Mac, tap &ldquo;Allow Accessory to Connect&rdquo;.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Local Wi-Fi Discovery</h3>
                <p>
                  Ensure your Mac and Android phone are on the exact same Wi-Fi network.
                  Make sure your phone is not on a separate guest network and any VPN that blocks
                  local device discovery is temporarily turned off.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>External Monitors &amp; Notchless Displays</h3>
                <p>
                  NotchDeck automatically detects your screen. If your Mac is connected to
                  an external monitor or does not have a physical camera notch, NotchDeck neatly
                  appears as a docked control bar right below your menu bar.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>App Shortcut Permissions</h3>
                <p>
                  When launching Mac applications from your phone deck, macOS may ask for
                  Accessibility permissions for NotchDeck in System Settings &gt;
                  Privacy &amp; Security. Granting this allows instant slot launching.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Frequently Asked Questions Accordion */}
        <FaqAccordion
          className="support-faq"
          title="Frequently asked questions."
          subtitle="Details on connectivity, physical notch detection, sandboxed security, and offline operation."
        />

        {/* Direct Contact & Developer Help */}
        <section className="support-section" aria-labelledby="help-title">
          <h2 id="help-title">Direct developer support</h2>
          <p className="support-section-desc">
            I personally build and maintain NotchDeck, and I am here to help you get the best setup.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Direct Email Support</h3>
                <p>
                  Have a question about setting up a shortcut, connecting your devices, or your license?
                  Send me an email directly and I will get back to you promptly.
                </p>
              </div>
              <a href="mailto:arnelbaylon15@gmail.com" className="support-hairline-link">
                <span>arnelbaylon15@gmail.com</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Feature Requests &amp; Ideas</h3>
                <p>
                  Have a suggestion for a new shortcut integration, widget, or layout idea?
                  I shape future updates around your direct feedback.
                </p>
              </div>
              <a href="mailto:arnelbaylon15@gmail.com" className="support-hairline-link">
                <span>Share Feedback</span>
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
