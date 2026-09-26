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
    title: 'Mac',
    primary: 'macOS 14 Sonoma or later',
    description: 'Apple Silicon & Intel Macs. Fits camera notch or floats under menu bar.',
  },
  {
    id: 'android',
    title: 'Android',
    primary: 'Android 10.0 or later',
    description: 'Phones and tablets. Responsive portrait and landscape layouts.',
  },
  {
    id: 'connection',
    title: 'Connection',
    primary: 'USB cable or local Wi-Fi',
    description: '0.8ms wired USB tunnel, or wireless on the same local network.',
  },
  {
    id: 'device-setup',
    title: 'Phone setup',
    primary: 'USB debugging enabled',
    description: 'Required for wired USB mode. No root or extra drivers needed.',
  },
  {
    id: 'privacy',
    title: 'Permissions',
    primary: 'macOS Accessibility',
    description: 'Enables launching apps. 100% local, no account or cloud data.',
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
        <span className="section-kicker">Requirements</span>
        <h2 id="requirements-title">Simple hardware setup.</h2>
        <p>Runs locally on your everyday Mac and Android device.</p>
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
