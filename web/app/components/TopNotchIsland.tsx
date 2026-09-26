'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { getSideNotchPath, getLiquidPullPath, NotchEdge } from './notch/NotchGeometry';

export type DockPosition = 'top' | 'left' | 'right' | 'floating';

interface TopNotchIslandProps {
  className?: string;
  defaultPosition?: DockPosition;
}

const NAV_ITEMS = [
  { id: 'how-it-works', label: 'How it works', href: '#how-it-works' },
  { id: 'setup', label: 'Setup & Commands', href: '#setup' },
  { id: 'requirements', label: 'Requirements', href: '#requirements' },
  { id: 'privacy', label: 'Private by design', href: '#privacy' },
];

export default function TopNotchIsland({
  className = '',
  defaultPosition = 'top',
}: TopNotchIslandProps) {
  const [dockPosition, setDockPosition] = useState<DockPosition>(defaultPosition);
  const [dragProximity, setDragProximity] = useState<DockPosition | null>(null);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [activeSection, setActiveSection] = useState<string>('how-it-works');

  // Elastic liquid stretch state
  const [stretchDistance, setStretchDistance] = useState<number>(0);
  const [lateralOffset, setLateralOffset] = useState<number>(0);
  const [isDetached, setIsDetached] = useState<boolean>(false);

  const containerRef = useRef<HTMLDivElement>(null);
  const dragStartPosRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Scroll spy to highlight current active section
  useEffect(() => {
    const handleScroll = () => {
      const scrollPos = window.scrollY + 220;
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

  // Window event listener to cycle dock position from external buttons
  useEffect(() => {
    const handleToggle = () => {
      setDockPosition((prev) => (prev === 'top' ? 'left' : prev === 'left' ? 'right' : 'top'));
    };
    window.addEventListener('macdeck-toggle-notch', handleToggle);
    return () => {
      window.removeEventListener('macdeck-toggle-notch', handleToggle);
    };
  }, []);

  // Compute exact dimensions
  const getDimensions = () => {
    if (isDetached) {
      return { width: 340, height: 42 };
    }
    if (dockPosition === 'left' || dockPosition === 'right') {
      return { width: 160, height: 236 };
    }
    // Top dock: comfortably houses camera, brand, and all navigation links
    return { width: 510, height: 38 };
  };

  const { width, height } = getDimensions();
  const currentEdge: NotchEdge =
    dockPosition === 'left' ? 'left' : dockPosition === 'right' ? 'right' : 'top';

  // Generate SVG path for the exact liquid notch outline
  const notchPath = isDragging && stretchDistance > 0 && !isDetached
    ? getLiquidPullPath(
        currentEdge,
        width + (currentEdge === 'top' ? 0 : stretchDistance),
        height + (currentEdge === 'top' ? stretchDistance : 0),
        stretchDistance,
        lateralOffset,
        false,
        18
      )
    : getSideNotchPath(
        currentEdge,
        width,
        height,
        dockPosition === 'floating' || isDetached ? 21 : 18,
        14
      );

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

  // Fixed container coordinate anchors
  const getContainerClasses = () => {
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

      {/* Edge Proximity Dropzone Previews (Visible while dragging near an edge) */}
      <AnimatePresence>
        {isDragging && dragProximity === 'top' && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-0 left-1/2 -translate-x-1/2 w-[510px] max-w-[92vw] h-10 rounded-b-2xl border-2 border-dashed border-emerald-500/50 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide">
              Release to dock to Top Notch
            </span>
          </motion.div>
        )}

        {isDragging && dragProximity === 'left' && (
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="fixed left-0 top-1/2 -translate-y-1/2 w-44 h-60 rounded-r-2xl border-2 border-dashed border-emerald-500/50 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide [writing-mode:vertical-rl] rotate-180">
              Release to dock to Left Side Notch
            </span>
          </motion.div>
        )}

        {isDragging && dragProximity === 'right' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            className="fixed right-0 top-1/2 -translate-y-1/2 w-44 h-60 rounded-l-2xl border-2 border-dashed border-emerald-500/50 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide [writing-mode:vertical-rl]">
              Release to dock to Right Side Notch
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Draggable Notch Component Container */}
      <div ref={containerRef} className={`${getContainerClasses()} ${className}`}>
        <motion.div
          drag
          dragMomentum={false}
          dragElastic={0.2}
          onDragStart={(_e, info) => {
            dragStartPosRef.current = { x: info.point.x, y: info.point.y };
            setIsDragging(true);
          }}
          onDrag={(_e, info) => {
            const dx = info.point.x - dragStartPosRef.current.x;
            const dy = info.point.y - dragStartPosRef.current.y;
            const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;

            let stretch = 0;
            let lateral = 0;

            if (dockPosition === 'top') {
              stretch = Math.max(0, dy);
              lateral = dx;
            } else if (dockPosition === 'left') {
              stretch = Math.max(0, dx);
              lateral = dy;
            } else if (dockPosition === 'right') {
              stretch = Math.max(0, -dx);
              lateral = dy;
            }

            setStretchDistance(stretch);
            setLateralOffset(lateral);

            // Detach when pulled past 90px
            if (stretch > 90 && !isDetached) {
              setIsDetached(true);
            }

            // Proximity dropzone detection
            const x = info.point.x;
            const y = info.point.y;
            if (y <= 85) {
              setDragProximity('top');
            } else if (x <= 120) {
              setDragProximity('left');
            } else if (x >= winW - 120) {
              setDragProximity('right');
            } else {
              setDragProximity('floating');
            }
          }}
          onDragEnd={(_e, info) => {
            const dist = Math.hypot(
              info.point.x - dragStartPosRef.current.x,
              info.point.y - dragStartPosRef.current.y
            );
            const x = info.point.x;
            const y = info.point.y;
            const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;

            if (dist > 8) {
              if (y <= 95) {
                setDockPosition('top');
              } else if (x <= 140) {
                setDockPosition('left');
              } else if (x >= winW - 140) {
                setDockPosition('right');
              } else {
                setDockPosition('floating');
              }
            }

            setStretchDistance(0);
            setLateralOffset(0);
            setIsDetached(false);
            setDragProximity(null);
            setTimeout(() => setIsDragging(false), 50);
          }}
          layout
          transition={{
            type: 'spring',
            stiffness: 340,
            damping: 26,
            mass: 0.75,
          }}
          className="relative cursor-grab active:cursor-grabbing transition-transform max-w-[96vw]"
          style={{ width, height }}
        >
          {/* ========================================================= */}
          {/* SVG LIQUID GLASS BACKGROUND (SideNotchShape / LiquidPull) */}
          {/* ========================================================= */}
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none overflow-visible drop-shadow-[0_12px_28px_rgba(0,0,0,0.45)]"
            viewBox={`0 0 ${width} ${height}`}
            aria-hidden="true"
          >
            {/* Ambient Shadow Blur */}
            <path
              d={notchPath}
              fill="rgba(0, 0, 0, 0.45)"
              transform="translate(0, 4)"
              filter="blur(6px)"
            />

            {/* Deep Obsidian Acrylic Glass Fill */}
            <path d={notchPath} fill="url(#notchObsidianGradient)" />

            {/* Directional Specular Reflection Rim */}
            <path
              d={notchPath}
              fill="none"
              stroke="url(#notchRimGradient)"
              strokeWidth="1.2"
            />

            <defs>
              <linearGradient
                id="notchObsidianGradient"
                x1={dockPosition === 'right' ? '1' : '0'}
                y1="0"
                x2={dockPosition === 'right' ? '0' : '0'}
                y2="1"
              >
                <stop offset="0%" stopColor="#191c24" stopOpacity="0.98" />
                <stop offset="100%" stopColor="#07090e" stopOpacity="0.99" />
              </linearGradient>

              <linearGradient
                id="notchRimGradient"
                x1="0"
                y1="0"
                x2={dockPosition === 'top' ? '0' : '1'}
                y2={dockPosition === 'top' ? '1' : '0'}
              >
                <stop offset="0%" stopColor="rgba(255, 255, 255, 0.45)" />
                <stop offset="30%" stopColor="rgba(255, 255, 255, 0.18)" />
                <stop offset="70%" stopColor="rgba(255, 255, 255, 0.05)" />
                <stop offset="100%" stopColor="rgba(255, 255, 255, 0.01)" />
              </linearGradient>
            </defs>
          </svg>

          {/* ========================================================= */}
          {/* 1. TOP NOTCH: ALWAYS VISIBLE WITH NAVIGATIONS INSIDE      */}
          {/* ========================================================= */}
          {(dockPosition === 'top' || dockPosition === 'floating') && (
            <div className="relative z-10 flex items-center justify-between w-full h-full px-3.5 sm:px-4 text-white">
              {/* Left: Camera & Brand */}
              <div
                className="flex items-center gap-2 shrink-0 cursor-grab active:cursor-grabbing"
                title="Drag notch anywhere to dock on sides or top"
              >
                {/* Camera Lens Dot */}
                <div
                  className="w-2.5 h-2.5 rounded-full bg-[#0d121d] border border-[#1b253b] flex items-center justify-center shrink-0"
                  title="FaceTime Camera Cutout"
                >
                  <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
                </div>
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />
                <span className="text-[11.5px] font-semibold tracking-tight text-white/95 font-poppins">
                  macdeck
                </span>
              </div>

              {/* Vertical subtle divider */}
              <div className="w-[1px] h-3 bg-white/15 mx-1" aria-hidden="true" />

              {/* Center: Directly Displayed Navigation Links */}
              <nav
                className="flex items-center gap-0.5 sm:gap-1 text-[11px] sm:text-[11.5px] font-medium"
                aria-label="Liquid Notch Navigation"
              >
                {NAV_ITEMS.map((item) => {
                  const isActive = activeSection === item.id;
                  return (
                    <a
                      key={item.id}
                      href={item.href}
                      onClick={(e) => handleNavClick(item.href, e)}
                      className={`relative px-2 sm:px-2.5 py-0.5 rounded-full transition-colors whitespace-nowrap cursor-pointer ${
                        isActive
                          ? 'text-white font-semibold'
                          : 'text-white/65 hover:text-white'
                      }`}
                    >
                      {isActive && (
                        <motion.span
                          layoutId="active-notch-nav-pill"
                          className="absolute inset-0 bg-white/15 border border-white/20 rounded-full -z-10 shadow-xs"
                          transition={{ type: 'spring', stiffness: 380, damping: 28 }}
                        />
                      )}
                      <span>{item.label}</span>
                    </a>
                  );
                })}
              </nav>

              {/* Right: Drag Handle */}
              <div
                className="flex items-center gap-0.5 opacity-40 hover:opacity-100 transition-opacity cursor-grab active:cursor-grabbing pl-1.5"
                title="Drag notch to reposition to side or top"
              >
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* 2. SIDE NOTCH: ALWAYS VISIBLE WITH NAVIGATIONS INSIDE     */}
          {/* ========================================================= */}
          {(dockPosition === 'left' || dockPosition === 'right') && (
            <div className="relative z-10 flex flex-col justify-between w-full h-full p-3 text-white">
              {/* Top Header: Camera Lens, Brand, & Drag Grip */}
              <div className="flex items-center justify-between pb-2 border-b border-white/10">
                <div className="flex items-center gap-1.5">
                  <div className="w-2.5 h-2.5 rounded-full bg-[#0d121d] border border-[#1b253b] flex items-center justify-center shrink-0">
                    <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
                  </div>
                  <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />
                  <span className="text-[11px] font-semibold text-white/95 tracking-tight font-poppins">
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

              {/* Vertical Stack: Directly Displayed Navigation Links */}
              <nav
                className="flex flex-col gap-1 my-auto text-[11px] font-medium"
                aria-label="Side Notch Navigation"
              >
                {NAV_ITEMS.map((item) => {
                  const isActive = activeSection === item.id;
                  return (
                    <a
                      key={item.id}
                      href={item.href}
                      onClick={(e) => handleNavClick(item.href, e)}
                      className={`relative px-2 py-1.5 rounded-lg transition-colors flex items-center justify-between text-left cursor-pointer ${
                        isActive
                          ? 'text-white font-semibold bg-white/15 border border-white/12'
                          : 'text-white/65 hover:text-white hover:bg-white/8'
                      }`}
                    >
                      <span className="truncate">{item.label}</span>
                      {isActive && (
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_5px_rgba(52,211,153,0.8)] shrink-0 ml-1" />
                      )}
                    </a>
                  );
                })}
              </nav>

              {/* Bottom Footer: Quick Dock Switchers */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-around text-[10px] text-white/45 font-mono">
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
