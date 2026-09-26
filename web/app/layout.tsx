import type { Metadata, Viewport } from 'next';
import './globals.css';
import 'lenis/dist/lenis.css';
import SmoothScroll from './components/SmoothScroll';
import PrecisionCursor from './components/PrecisionCursor';

export const metadata: Metadata = {
  title: 'NotchDeck - Native macOS & Android Control Surface',
  description: 'Turn your Android phone into a high-performance touchscreen stream deck. Configure slots in real-time with the native macOS NotchDeck liquid glass HUD.',
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#f9fafd',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <SmoothScroll />
        <PrecisionCursor />
        {children}
      </body>
    </html>
  );
}
