'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { HugeiconsIcon } from '@hugeicons/react';
import {
  LaptopMinimalIcon,
  Download01Icon,
  Menu01Icon,
  Cancel01Icon,
  ArrowRight01Icon,
} from '@hugeicons/core-free-icons';

interface NavItem {
  label: string;
  href: string;
}

const NAV_ITEMS: NavItem[] = [
  { label: 'Live Demo', href: '#live-demo' },
  { label: 'Workflow', href: '#how-it-works' },
  { label: 'Architecture', href: '#architecture' },
  { label: 'Commands', href: '#terminal-commands' },
  { label: 'FAQ', href: '#faq' },
];

export interface SiteHeaderProps {
  className?: string;
  onToggleNotch?: () => void;
}

export default function SiteHeader({ className = '', onToggleNotch }: SiteHeaderProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Close mobile menu on resize to desktop viewports
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth >= 1024) {
        setMobileMenuOpen(false);
      }
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const handleToggleNotch = () => {
    if (onToggleNotch) {
      onToggleNotch();
    } else {
      window.dispatchEvent(new CustomEvent('macdeck-toggle-notch'));
    }
  };

  return (
    <header
      className={`sticky top-0 z-40 w-full bg-[#f9fafd]/95 backdrop-blur-md border-b border-[#e5e9f2] transition-colors ${className}`}
      role="banner"
    >
      <div className="shell flex items-center justify-between h-16">
        {/* Brand Mark: macdeck. in Poppins bold with a solid slate dot */}
        <div className="flex items-center gap-3">
          <a
            href="#top"
            className="flex items-baseline gap-0.5 group focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828] rounded-md px-1 py-0.5"
            aria-label="MacDeck Home"
          >
            <span className="font-bold text-xl tracking-tight text-[#101828] font-['Poppins']">
              macdeck
            </span>
            <span
              className="w-1.5 h-1.5 rounded-full bg-[#344054] inline-block ml-0.5 self-baseline"
              aria-hidden="true"
            />
          </a>
          <span className="hidden xl:inline-flex items-center px-2 py-0.5 text-[10px] font-mono font-medium rounded bg-[#f2f4f7] border border-[#e4e7ec] text-[#475467]">
            macOS &amp; Android Control
          </span>
        </div>

        {/* Desktop Anchor Navigation: Live Demo, Workflow, Architecture, Commands, FAQ */}
        <nav
          className="hidden md:flex items-center gap-1 lg:gap-2"
          aria-label="Primary Navigation"
        >
          {NAV_ITEMS.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="px-3 py-1.5 rounded-lg text-xs lg:text-sm font-medium text-[#475467] hover:text-[#101828] hover:bg-[#f2f4f7] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828]"
            >
              {item.label}
            </a>
          ))}
        </nav>

        {/* Action Buttons */}
        <div className="hidden sm:flex items-center gap-2.5">
          <button
            type="button"
            onClick={handleToggleNotch}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#dbe2ea] bg-white text-xs font-mono font-medium text-[#101828] shadow-[0_1px_2px_rgba(16,24,40,0.04)] hover:bg-[#f2f4f7] hover:border-[#b9c6d5] active:scale-[0.98] transition-all cursor-pointer focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828]"
            aria-label="Toggle Top Notch HUD"
          >
            <HugeiconsIcon icon={LaptopMinimalIcon} size={14} className="text-[#475467]" />
            <span>Toggle Notch HUD</span>
          </button>

          <a
            href="#terminal-commands"
            className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-[#101828] hover:bg-[#1d2939] text-xs font-mono font-semibold text-white shadow-[0_1px_2px_rgba(16,24,40,0.08)] active:scale-[0.98] transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828] focus-visible:ring-offset-2"
          >
            <HugeiconsIcon icon={Download01Icon} size={14} className="text-white" />
            <span>Download Portal</span>
          </a>
        </div>

        {/* Mobile Menu Button */}
        <div className="flex md:hidden items-center gap-2">
          <button
            type="button"
            onClick={handleToggleNotch}
            className="sm:hidden inline-flex items-center p-2 rounded-lg border border-[#dbe2ea] bg-white text-[#101828] shadow-xs hover:bg-[#f2f4f7] active:scale-95 transition-all"
            aria-label="Toggle Notch HUD"
          >
            <HugeiconsIcon icon={LaptopMinimalIcon} size={16} className="text-[#101828]" />
          </button>

          <button
            type="button"
            onClick={() => setMobileMenuOpen((prev) => !prev)}
            className="inline-flex items-center justify-center p-2 rounded-lg border border-[#dbe2ea] bg-white text-[#101828] hover:bg-[#f2f4f7] active:scale-95 transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[#101828]"
            aria-expanded={mobileMenuOpen}
            aria-label={mobileMenuOpen ? 'Close Navigation Menu' : 'Open Navigation Menu'}
          >
            <HugeiconsIcon
              icon={mobileMenuOpen ? Cancel01Icon : Menu01Icon}
              size={18}
              className="text-[#101828]"
            />
          </button>
        </div>
      </div>

      {/* Mobile Dropdown Menu */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="md:hidden border-t border-[#e5e9f2] bg-[#f9fafd] px-4 pt-3 pb-5 space-y-3"
          >
            <nav className="flex flex-col space-y-1">
              {NAV_ITEMS.map((item) => (
                <a
                  key={item.href}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="px-3 py-2 rounded-lg text-sm font-medium text-[#344054] hover:text-[#101828] hover:bg-[#f2f4f7] transition-colors"
                >
                  {item.label}
                </a>
              ))}
            </nav>

            <div className="pt-3 border-t border-[#e5e9f2] flex flex-col gap-2">
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  handleToggleNotch();
                }}
                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl border border-[#dbe2ea] bg-white text-xs font-mono font-medium text-[#101828] shadow-xs active:scale-[0.98] transition-all cursor-pointer"
              >
                <HugeiconsIcon icon={LaptopMinimalIcon} size={15} className="text-[#475467]" />
                <span>Toggle Notch HUD</span>
              </button>

              <a
                href="#terminal-commands"
                onClick={() => setMobileMenuOpen(false)}
                className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-[#101828] text-white text-xs font-mono font-semibold shadow-xs active:scale-[0.98] transition-all"
              >
                <HugeiconsIcon icon={Download01Icon} size={15} className="text-white" />
                <span>Download Portal</span>
                <HugeiconsIcon icon={ArrowRight01Icon} size={13} className="text-white/70" />
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
}
