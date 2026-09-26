import type { Metadata } from 'next';
import Link from 'next/link';
import SiteFooter from '../components/SiteFooter';

export const metadata: Metadata = {
  title: 'Privacy Policy — NotchDeck',
  description:
    'NotchDeck privacy policy: fully private, zero tracking, and no cloud servers. Your shortcuts and controls stay directly between your Mac and phone.',
};

export default function PrivacyPage() {
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

          <nav className="support-header-nav" aria-label="Privacy Navigation">
            <Link href="/" className="support-back-link" data-lenis-prevent="true">
              <span aria-hidden="true">←</span>
              <span>Back to Home</span>
            </Link>
          </nav>
        </div>
      </header>

      {/* Main Privacy Stage */}
      <main className="support-stage" id="main-content">
        {/* Intro */}
        <section className="support-intro" aria-labelledby="privacy-title">
          <h1 id="privacy-title">Privacy Policy</h1>
          <p className="support-lede">
            NotchDeck is built with a simple promise: your actions, shortcuts, and personal setup
            stay strictly between your Mac and your phone. There is no tracking, no account
            requirement, and no cloud server listening in.
          </p>
          <p className="text-xs font-mono text-[#667085] mt-3">Last updated: September 2026</p>
        </section>

        {/* Section 1: No Tracking & No Cloud */}
        <section className="support-section" aria-labelledby="privacy-principles-title">
          <h2 id="privacy-principles-title">Our privacy principles</h2>
          <p className="support-section-desc">
            How NotchDeck protects your workspace privacy by keeping everything local.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>No Analytics or Activity Tracking</h3>
                <p>
                  NotchDeck does not track what apps you use, how many times you tap a shortcut, or
                  when you work. There are no tracking scripts, advertising trackers, or background
                  analytics in either the Mac app or the Android app.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>No Cloud Middleman</h3>
                <p>
                  Your phone connects directly to your Mac. When you tap a button on your phone, the
                  signal goes straight to your Mac across your desk—never through any external cloud
                  server or web service.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Works Completely Offline</h3>
                <p>
                  You do not need an internet connection to use NotchDeck. If your Wi-Fi is down or
                  your Mac is completely disconnected from the internet, your deck works normally.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 2: Direct Connection Between Your Devices */}
        <section className="support-section" aria-labelledby="connection-title">
          <h2 id="connection-title">How your devices connect</h2>
          <p className="support-section-desc">
            Direct communication right at your workspace.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Connecting Over USB Cable</h3>
                <p>
                  When you plug your phone into your Mac with a USB cable, taps and app updates
                  travel directly through the physical cable. Nothing ever leaves your desk.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Connecting Over Local Wi-Fi</h3>
                <p>
                  When connecting wirelessly, your phone and Mac talk directly to each other over
                  your private home or office Wi-Fi network. No data is sent out to the broader
                  internet.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Safe Device Pairing</h3>
                <p>
                  When you first pair your phone, your Mac remembers your device so that only your
                  authorized phone can trigger shortcuts on your Mac.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 3: System Permissions Explained */}
        <section className="support-section" aria-labelledby="permissions-title">
          <h2 id="permissions-title">Device permissions explained</h2>
          <p className="support-section-desc">
            Why NotchDeck requests permissions on your Mac and Android phone.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Opening Apps &amp; Shortcuts on Mac</h3>
                <p>
                  macOS may ask for permission so NotchDeck can open the apps you assign and bring
                  them to the front when tapped. NotchDeck never reads your screen text, logs your
                  keystrokes, or inspects personal files.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Local Network on Mac &amp; Android</h3>
                <p>
                  Needed so your phone and Mac can find and talk to each other when you choose to
                  connect wirelessly over Wi-Fi.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>USB Connection on Android</h3>
                <p>
                  When connecting by cable, Android asks for standard USB debugging permission
                  so the phone can communicate with your Mac with instant response times.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 4: What Is Saved on Your Mac */}
        <section className="support-section" aria-labelledby="storage-title">
          <h2 id="storage-title">What is saved on your computer</h2>
          <p className="support-section-desc">
            All your choices stay on your own machine.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Your 6 Assigned Shortcuts</h3>
                <p>
                  Which apps you put in your six slots and your layout preferences are saved
                  directly in your personal Mac user folder. You can change or clear them whenever you
                  like.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>App Icons</h3>
                <p>
                  The app icons shown on your phone screen are copied directly from the apps on your
                  Mac and kept on your phone only so they load instantly when you tap.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 5: Purchases & Personal Info */}
        <section className="support-section" aria-labelledby="purchases-title">
          <h2 id="purchases-title">Purchases &amp; personal information</h2>
          <p className="support-section-desc">
            How orders and support messages are handled.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Safe Payment Checkout</h3>
                <p>
                  Purchases are handled through secure payment processors. Your credit card details
                  are processed by them directly and are never seen or stored by NotchDeck.
                </p>
              </div>
            </li>

            <li className="support-hairline-item">
              <div>
                <h3>Your Email Address</h3>
                <p>
                  When you purchase a license or reach out for help, your email address is used
                  solely to send your license key and reply to your questions. You will never receive
                  marketing spam or promotional newsletters.
                </p>
              </div>
            </li>
          </ul>
        </section>

        {/* Section 6: Contact the Developer */}
        <section className="support-section" aria-labelledby="contact-title">
          <h2 id="contact-title">Questions or privacy concerns?</h2>
          <p className="support-section-desc">
            I am a solo developer building NotchDeck, and I am always happy to answer your questions.
          </p>

          <ul className="support-hairline-list">
            <li className="support-hairline-item">
              <div>
                <h3>Direct Email to Developer</h3>
                <p>
                  If you have questions about your privacy, need help with your license, or want your
                  email history deleted, please email me directly.
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
