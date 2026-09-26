'use client';

interface RequirementItem {
  id: string;
  title: string;
  primary: string;
  description: string;
}

const REQUIREMENTS: RequirementItem[] = [
  {
    id: 'mac',
    title: 'Mac computer',
    primary: 'macOS 14 Sonoma or macOS 15 Sequoia',
    description:
      'Compatible with both Apple Silicon (M1, M2, M3, M4) and Intel Macs. Automatically matches your MacBook camera notch, or floats cleanly under the menu bar on external displays.',
  },
  {
    id: 'android',
    title: 'Android device',
    primary: 'Android 10.0 (API Level 29) or higher',
    description:
      'Works on any standard phone or tablet with touch support. The 6-slot deck dynamically rearranges itself for portrait or landscape orientation.',
  },
  {
    id: 'connection',
    title: 'Connection',
    primary: 'Standard USB cable or local Wi-Fi',
    description:
      'Plug in via USB for instant sub-millisecond tactile response, or connect wirelessly when both devices share the same local Wi-Fi or LAN network.',
  },
  {
    id: 'device-setup',
    title: 'Device setup',
    primary: 'USB debugging enabled on your phone',
    description:
      'Only required if you choose to connect over a USB cable. No rooting, bootloader unlocking, or special third-party drivers needed.',
  },
  {
    id: 'privacy',
    title: 'Permissions & privacy',
    primary: 'Local macOS Accessibility access',
    description:
      'Enables NotchDeck to launch and switch your selected Mac apps smoothly. No user accounts, cloud servers, or external tracking—everything stays 100% on your desk.',
  },
];

export default function RequirementsSection() {
  return (
    <section
      className="requirements-section"
      id="requirements"
      aria-labelledby="requirements-title"
    >
      <div className="section-heading">
        <span className="section-kicker">System requirements</span>
        <h2 id="requirements-title">Everything you need to run NotchDeck.</h2>
        <p>
          Works with your current Mac and Android phone using standard cables and local
          network connections.
        </p>
      </div>

      <ul className="requirements-list" role="list">
        {REQUIREMENTS.map((item) => (
          <li key={item.id}>
            <h3 className="requirement-title">{item.title}</h3>
            <div className="requirement-content">
              <p className="requirement-primary">{item.primary}</p>
              <p className="requirement-desc">{item.description}</p>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
