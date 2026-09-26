import React from 'react';
import Link from 'next/link';

export interface SiteFooterProps {
  className?: string;
  hideHome?: boolean;
}

export default function SiteFooter({ className = '', hideHome = false }: SiteFooterProps) {
  return (
    <footer className={className}>
      <span>© 2026 NotchDeck</span>
      <nav className="links" aria-label="Footer Navigation">
        {!hideHome && (
          <Link href="/" data-lenis-prevent="true">
            Home
          </Link>
        )}
        <Link href="/#features" data-lenis-prevent="true">
          Features
        </Link>
        <Link href="/#how-it-works" data-lenis-prevent="true">
          How it works
        </Link>
        <Link href="/requirements" data-lenis-prevent="true">
          Requirements
        </Link>
        <Link href="/support" data-lenis-prevent="true">
          Support
        </Link>
        <Link href="/privacy" data-lenis-prevent="true">
          Privacy
        </Link>
        <Link href="/terms" data-lenis-prevent="true">
          Terms
        </Link>
      </nav>
    </footer>
  );
}
