import type { Metadata } from 'next';
import Link from 'next/link';
import SiteFooter from '../components/SiteFooter';

export const metadata: Metadata = {
  title: 'Terms & Conditions — NotchDeck',
  description:
    'Terms and Conditions for NotchDeck: lifetime license, 7-day money-back guarantee, and simple guidelines for using the app.',
};

export default function TermsPage() {
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

          <nav className="support-header-nav" aria-label="Terms Navigation">
            <Link href="/" className="support-back-link" data-lenis-prevent="true">
              <span aria-hidden="true">←</span>
              <span>Back to Home</span>
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Terms Stage */}
      <main className="support-stage" id="main-content">
        {/* Intro */}
        <section className="support-intro" aria-labelledby="terms-title">
          <h1 id="terms-title">Terms &amp; Conditions</h1>
          <p className="support-lede">
            Simple, honest terms for using NotchDeck on your Mac and Android phone. By downloading,
            purchasing, or using NotchDeck, you agree to these straightforward guidelines.
          </p>
          <p className="text-xs font-mono text-[#667085] mt-3">Last updated: September 2026</p>
        </section>

        {/* Section 1: Lifetime License & Usage */}
        <section className="support-section" aria-labelledby="license-title">
          <h2 id="license-title">Your lifetime license</h2>
          <p className="support-section-desc">
            What you get when you purchase NotchDeck.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>One-Time Purchase, Lifetime Use</h3>
                <p>
                  When you buy NotchDeck, it is yours to keep forever. There are no monthly
                  subscriptions or hidden fees. Your purchase includes all regular updates and
                  improvements.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Use Across Your Own Devices</h3>
                <p>
                  Your single license covers your primary Mac workstation and your companion
                  Android phones or tablets.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Free Machine Transfers</h3>
                <p>
                  Upgrading to a new Mac or buying a new phone? You can move your license to your new
                  devices anytime at no extra cost.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 2: User Responsibility */}
        <section className="support-section" aria-labelledby="shortcuts-title">
          <h2 id="shortcuts-title">Your shortcuts &amp; actions</h2>
          <p className="support-section-desc">
            You stay in full control of what runs on your computer.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>You Choose What Runs</h3>
                <p>
                  NotchDeck simply launches the Mac apps and shortcuts you choose when you tap your
                  phone screen. Because these actions run directly on your Mac, you are responsible
                  for the applications and custom commands you set up.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Safe &amp; Respectful Use</h3>
                <p>
                  Please use NotchDeck responsibly and do not configure it to run harmful scripts or
                  disrupt other people&apos;s devices.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 3: 7-Day Guarantee */}
        <section className="support-section" aria-labelledby="refunds-title">
          <h2 id="refunds-title">7-Day money-back guarantee</h2>
          <p className="support-section-desc">
            Try NotchDeck completely risk-free.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>100% Full Refund</h3>
                <p>
                  I want you to love having this on your desk. If NotchDeck does not fit into your
                  daily workflow or perform the way you hoped, simply email me within 7 days of your
                  purchase for a prompt, full refund—no questions asked.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>How to Request a Refund</h3>
                <p>
                  Just send a quick email from your purchase address to{' '}
                  <strong>arnelbaylon15@gmail.com</strong>, and I will take care of it right away.
                </p>
              </div>
              <a href="mailto:arnelbaylon15@gmail.com" className="support-hairline-link">
                <span>arnelbaylon15@gmail.com</span>
                <span aria-hidden="true">↗</span>
              </a>
            </li>
          </ul>
        </section>

        {/* Section 4: Fair Use & Software Rights */}
        <section className="support-section" aria-labelledby="fairuse-title">
          <h2 id="fairuse-title">Fair use &amp; ownership</h2>
          <p className="support-section-desc">
            Keeping things fair between the user and the creator.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Personal Use</h3>
                <p>
                  Please do not resell, redistribute, or share cracked copies of NotchDeck. I am an
                  independent developer building this tool with care, and your purchase directly
                  supports ongoing development.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Design &amp; Code</h3>
                <p>
                  All designs, graphics, and software code for NotchDeck belong to the developer.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 5: Platform Disclaimers */}
        <section className="support-section" aria-labelledby="disclaimer-title">
          <h2 id="disclaimer-title">Platform notes</h2>
          <p className="support-section-desc">
            Independent software built for your favorite devices.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Independent Project</h3>
                <p>
                  Apple, macOS, and MacBook are trademarks of Apple Inc. Android is a trademark of
                  Google LLC. NotchDeck is an independent tool and is not affiliated with or endorsed
                  by Apple or Google.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Software Warranty</h3>
                <p>
                  NotchDeck is provided as-is. I work hard to make it fast, stable, and reliable, but
                  cannot guarantee it will be completely error-free across every future third-party
                  operating system update.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 6: Support from the Developer */}
        <section className="support-section" aria-labelledby="contact-title">
          <h2 id="contact-title">Direct developer support</h2>
          <p className="support-section-desc">
            I personally handle all customer questions and support.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Questions, Ideas &amp; Help</h3>
                <p>
                  Have a suggestion for a feature, need help setting up your desk, or want to ask
                  anything about your license? Reach out to me directly anytime.
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
