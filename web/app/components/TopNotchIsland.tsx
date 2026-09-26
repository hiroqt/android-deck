'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';

export type DockPosition = 'top' | 'left' | 'right' | 'floating';

interface TopNotchIslandProps {
  className?: string;
  defaultPosition?: DockPosition;
}

const NAV_ITEMS = [
  { id: 'how-it-works', label: 'How it works', href: '#how-it-works' },
  { id: 'setup', label: 'Setup', href: '#setup' },
  { id: 'requirements', label: 'Requirements', href: '#requirements' },
  { id: 'privacy', label: 'Privacy', href: '#privacy' },
];

export default function TopNotchIsland({
  className = '',
  defaultPosition = 'top',
}: TopNotchIslandProps) {
  const [dockPosition, setDockPosition] = useState<DockPosition>(defaultPosition);
  const [dragProximity, setDragProximity] = useState<DockPosition | null>(null);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [activeSection, setActiveSection] = useState<string>('');
  const [hoveredNav, setHoveredNav] = useState<string | null>(null);

  const dragStartRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Scroll spy to highlight active section in the notch
  useEffect(() => {
    const handleScroll = () => {
      const scrollPos = window.scrollY + 180;
      for (const item of NAV_ITEMS) {
        const el = document.getElementById(item.id);
        if (el) {
          const top = el.offsetTop;
          const height = el.offsetHeight;
          if (scrollPos >= top && scrollPos < top + height) {
            setActiveSection(item.id);
            return;
          }
        }
      }
      if (window.scrollY < 200) {
        setActiveSection('');
      }
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    handleScroll();
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Listen for toggle / dock commands from external triggers
  useEffect(() => {
    const handleToggle = () => {
      setDockPosition((prev) => (prev === 'top' ? 'left' : prev === 'left' ? 'right' : 'top'));
    };
    window.addEventListener('macdeck-toggle-notch', handleToggle);
    return () => {
      window.removeEventListener('macdeck-toggle-notch', handleToggle);
    };
  }, []);

  const handleNavClick = (href: string, e: React.MouseEvent) => {
    if (isDragging) {
      e.preventDefault();
      return;
    }
    const target = document.querySelector(href);
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth' });
    }
  };

  // Determine container placement based on dockPosition
  const getContainerPlacement = () => {
    switch (dockPosition) {
      case 'left':
        return 'fixed left-0 top-1/2 -translate-y-1/2 z-50 select-none';
      case 'right':
        return 'fixed right-0 top-1/2 -translate-y-1/2 z-50 select-none';
      case 'floating':
        return 'fixed top-24 left-1/2 -translate-x-1/2 z-50 select-none';
      case 'top':
      default:
        return 'fixed top-0 left-1/2 -translate-x-1/2 z-50 select-none';
    }
  };

  return (
    <>
      {/* SVG Gooey Liquid Filter for Molten Glass Edge Blending */}
      <svg className="absolute w-0 h-0 overflow-hidden pointer-events-none" aria-hidden="true">
        <defs>
          <filter id="notch-liquid-goo">
            <feGaussianBlur in="SourceGraphic" stdDeviation="5" result="blur" />
            <feColorMatrix
              in="blur"
              mode="matrix"
              values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 19 -8"
              result="goo"
            />
            <feComposite in="SourceGraphic" in2="goo" operator="atop" />
          </filter>
        </defs>
      </svg>

      {/* Proximity Liquid Dock Dropzone Previews (Visible while dragging near an edge) */}
      <AnimatePresence>
        {isDragging && dragProximity === 'top' && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-0 left-1/2 -translate-x-1/2 w-[520px] max-w-[90vw] h-10 rounded-b-2xl border-2 border-dashed border-cyan-500/40 bg-cyan-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-cyan-300 font-medium tracking-wide">
              Release to dock to top notch
            </span>
          </motion.div>
        )}

        {isDragging && dragProximity === 'left' && (
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="fixed left-0 top-1/2 -translate-y-1/2 w-36 h-64 rounded-r-2xl border-2 border-dashed border-cyan-500/40 bg-cyan-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-cyan-300 font-medium tracking-wide [writing-mode:vertical-rl] rotate-180">
              Release to dock to left side
            </span>
          </motion.div>
        )}

        {isDragging && dragProximity === 'right' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            className="fixed right-0 top-1/2 -translate-y-1/2 w-36 h-64 rounded-l-2xl border-2 border-dashed border-cyan-500/40 bg-cyan-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-cyan-300 font-medium tracking-wide [writing-mode:vertical-rl]">
              Release to dock to right side
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Draggable Liquid Notch Navigation Element */}
      <div className={`${getContainerPlacement()} ${className}`}>
        <motion.div
          drag
          dragMomentum={false}
          dragElastic={0.16}
          onDragStart={(_e, info) => {
            dragStartRef.current = { x: info.point.x, y: info.point.y };
            setIsDragging(true);
          }}
          onDrag={(_e, info) => {
            const x = info.point.x;
            const y = info.point.y;
            const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;

            if (y <= 75) {
              setDragProximity('top');
            } else if (x <= 110) {
              setDragProximity('left');
            } else if (x >= winW - 110) {
              setDragProximity('right');
            } else {
              setDragProximity('floating');
            }
          }}
          onDragEnd={(_e, info) => {
            const dist = Math.hypot(
              info.point.x - dragStartRef.current.x,
              info.point.y - dragStartRef.current.y
            );
            const x = info.point.x;
            const y = info.point.y;
            const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;

            if (dist > 8) {
              if (y <= 90) {
                setDockPosition('top');
              } else if (x <= 140) {
                setDockPosition('left');
              } else if (x >= winW - 140) {
                setDockPosition('right');
              } else {
                setDockPosition('floating');
              }
            }
            setTimeout(() => {
              setIsDragging(false);
              setDragProximity(null);
            }, 60);
          }}
          layout
          transition={{
            type: 'spring',
            stiffness: 340,
            damping: 26,
            mass: 0.75,
          }}
          className={`relative bg-black text-white shadow-2xl transition-shadow cursor-grab active:cursor-grabbing border-white/10 ${
            dockPosition === 'top'
              ? 'rounded-b-[20px] px-3.5 py-1.5 h-[38px] border-b border-x'
              : dockPosition === 'left'
              ? 'rounded-r-[20px] px-3 py-3.5 w-[142px] border-y border-r'
              : dockPosition === 'right'
              ? 'rounded-l-[20px] px-3 py-3.5 w-[142px] border-y border-l'
              : 'rounded-full px-4 py-2 border shadow-[0_16px_36px_rgba(0,0,0,0.5)]'
          }`}
          style={{
            willChange: 'transform, border-radius',
          }}
        >
          {/* ========================================================= */}
          {/* LIQUID CONCAVE CORNER FILLET EARS (G2 CONTINUOUS BLEND)   */}
          {/* ========================================================= */}

          {/* Top Dock Liquid Concave Fillet Ears */}
          {dockPosition === 'top' && (
            <>
              {/* Left Concave Fillet Ear */}
              <svg
                className="absolute -left-[14px] top-0 w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 14 0 L 14 14 C 14 6.27 7.73 0 0 0 Z" />
              </svg>

              {/* Right Concave Fillet Ear */}
              <svg
                className="absolute -right-[14px] top-0 w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 0 0 L 0 14 C 0 6.27 6.27 0 14 0 Z" />
              </svg>
            </>
          )}

          {/* Left Side Notch Liquid Concave Fillet Ears */}
          {dockPosition === 'left' && (
            <>
              {/* Top Concave Fillet Ear */}
              <svg
                className="absolute left-0 -top-[14px] w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 0 14 L 14 14 C 6.27 14 0 7.73 0 0 Z" />
              </svg>

              {/* Bottom Concave Fillet Ear */}
              <svg
                className="absolute left-0 -bottom-[14px] w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 0 0 L 14 0 C 6.27 0 0 6.27 0 14 Z" />
              </svg>
            </>
          )}

          {/* Right Side Notch Liquid Concave Fillet Ears */}
          {dockPosition === 'right' && (
            <>
              {/* Top Concave Fillet Ear */}
              <svg
                className="absolute right-0 -top-[14px] w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 14 14 L 0 14 C 7.73 14 14 7.73 14 0 Z" />
              </svg>

              {/* Bottom Concave Fillet Ear */}
              <svg
                className="absolute right-0 -bottom-[14px] w-[14px] h-[14px] fill-black pointer-events-none"
                viewBox="0 0 14 14"
                aria-hidden="true"
              >
                <path d="M 14 0 L 0 0 C 7.73 0 14 6.27 14 14 Z" />
              </svg>
            </>
          )}

          {/* ========================================================= */}
          {/* HORIZONTAL NOTCH LAYOUT (TOP DOCK OR FLOATING)            */}
          {/* ========================================================= */}
          {(dockPosition === 'top' || dockPosition === 'floating') && (
            <div className="flex items-center gap-3 sm:gap-4 h-full">
              {/* Hardware Camera Notch Cutout & Brand */}
              <div
                className="flex items-center gap-2 pl-0.5 cursor-grab active:cursor-grabbing"
                title="Drag to dock to screen sides or top"
              >
                {/* Camera Lens Dot */}
                <div
                  className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0"
                  title="FaceTime Camera Cutout"
                >
                  <div className="w-1 h-1 rounded-full bg-[#1b253b] opacity-80" />
                </div>

                {/* Brand Wordmark */}
                <span className="text-[11.5px] font-semibold text-white/90 tracking-tight font-poppins">
                  macdeck
                </span>
              </div>

              {/* Subtle Vertical Divider */}
              <div className="w-[1px] h-3.5 bg-white/15" aria-hidden="true" />

              {/* Primary Direct Navigation Links */}
              <nav
                className="flex items-center gap-1 sm:gap-1.5 text-[11.5px] font-medium"
                aria-label="Liquid Notch Navigation"
              >
                {NAV_ITEMS.map((item) => {
                  const isActive = activeSection === item.id;
                  const isHovered = hoveredNav === item.id;

                  return (
                    <a
                      key={item.id}
                      href={item.href}
                      onClick={(e) => handleNavClick(item.href, e)}
                      onMouseEnter={() => setHoveredNav(item.id)}
                      onMouseLeave={() => setHoveredNav(null)}
                      className={`relative px-2 sm:px-2.5 py-0.5 rounded-full transition-colors whitespace-nowrap cursor-pointer ${
                        isActive
                          ? 'text-white font-semibold'
                          : isHovered
                          ? 'text-white'
                          : 'text-white/60'
                      }`}
                    >
                      {/* Active / Hover Background Pill */}
                      {isActive && (
                        <motion.span
                          layoutId="active-notch-pill"
                          className="absolute inset-0 bg-white/15 border border-white/20 rounded-full -z-10"
                          transition={{ type: 'spring', stiffness: 360, damping: 30 }}
                        />
                      )}
                      <span>{item.label}</span>
                    </a>
                  );
                })}
              </nav>

              {/* Drag Grip Handle */}
              <div
                className="flex items-center gap-0.5 opacity-40 hover:opacity-100 transition-opacity pl-1 cursor-grab active:cursor-grabbing"
                title="Drag to dock to left/right side or top"
              >
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* VERTICAL NOTCH LAYOUT (LEFT OR RIGHT SIDE DOCK)           */}
          {/* ========================================================= */}
          {(dockPosition === 'left' || dockPosition === 'right') && (
            <div className="flex flex-col gap-3 w-full">
              {/* Top Row: Camera Lens, Brand & Drag Grip */}
              <div className="flex items-center justify-between pb-2 border-b border-white/10">
                <div className="flex items-center gap-2">
                  <div
                    className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0"
                    title="Camera Lens"
                  >
                    <div className="w-1 h-1 rounded-full bg-[#1b253b] opacity-80" />
                  </div>
                  <span className="text-[11px] font-semibold text-white/90 tracking-tight font-poppins">
                    macdeck
                  </span>
                </div>

                <div
                  className="flex items-center gap-0.5 opacity-40 hover:opacity-100 transition-opacity cursor-grab active:cursor-grabbing"
                  title="Drag anywhere"
                >
                  <div className="w-1 h-1 rounded-full bg-white/70" />
                  <div className="w-1 h-1 rounded-full bg-white/70" />
                </div>
              </div>

              {/* Vertical Navigation Links */}
              <nav
                className="flex flex-col gap-1 text-[11.5px] font-medium"
                aria-label="Side Notch Navigation"
              >
                {NAV_ITEMS.map((item) => {
                  const isActive = activeSection === item.id;
                  const isHovered = hoveredNav === item.id;

                  return (
                    <a
                      key={item.id}
                      href={item.href}
                      onClick={(e) => handleNavClick(item.href, e)}
                      onMouseEnter={() => setHoveredNav(item.id)}
                      onMouseLeave={() => setHoveredNav(null)}
                      className={`relative px-2.5 py-1.5 rounded-lg transition-colors flex items-center justify-between text-left cursor-pointer ${
                        isActive
                          ? 'text-white font-semibold bg-white/15'
                          : isHovered
                          ? 'text-white bg-white/8'
                          : 'text-white/60 hover:text-white'
                      }`}
                    >
                      <span>{item.label}</span>
                      {isActive && <span className="w-1 h-1 rounded-full bg-emerald-400" />}
                    </a>
                  );
                })}
              </nav>

              {/* Quick Dock Switcher Footer */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-around text-[10px] text-white/40">
                <button
                  type="button"
                  onClick={() => setDockPosition('top')}
                  className="hover:text-white transition-colors cursor-pointer"
                  title="Dock to top"
                >
                  Top
                </button>
                <span>•</span>
                <button
                  type="button"
                  onClick={() =>
                    setDockPosition((prev) => (prev === 'left' ? 'right' : 'left'))
                  }
                  className="hover:text-white transition-colors cursor-pointer"
                  title="Switch sides"
                >
                  {dockPosition === 'left' ? 'Right' : 'Left'}
                </button>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </>
  );
}
