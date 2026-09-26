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
  {
    id: 'how-it-works',
    title: 'How it works',
    subtitle: 'USB reverse tunnel, fluid notch HUD, tactile grid',
    href: '#how-it-works',
  },
  {
    id: 'setup',
    title: 'Setup & Commands',
    subtitle: 'Terminal host server, Notch HUD, ADB loopback',
    href: '#setup',
  },
  {
    id: 'requirements',
    title: 'Requirements',
    subtitle: 'macOS 14+ Sonoma/Sequoia, Android 10+ (API 29+)',
    href: '#requirements',
  },
  {
    id: 'privacy',
    title: 'Private by design',
    subtitle: '100% offline, hardware loopback, sandboxed token IDs',
    href: '#privacy',
  },
];

export default function TopNotchIsland({
  className = '',
  defaultPosition = 'top',
}: TopNotchIslandProps) {
  const [dockPosition, setDockPosition] = useState<DockPosition>(defaultPosition);
  const [isExpanded, setIsExpanded] = useState<boolean>(false);
  const [isHovered, setIsHovered] = useState<boolean>(false);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [dragProximity, setDragProximity] = useState<DockPosition | null>(null);

  // Elastic liquid stretch state
  const [stretchDistance, setStretchDistance] = useState<number>(0);
  const [lateralOffset, setLateralOffset] = useState<number>(0);
  const [isDetached, setIsDetached] = useState<boolean>(false);

  const containerRef = useRef<HTMLDivElement>(null);
  const dragStartPosRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Close when pressing Escape or clicking outside
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isExpanded) {
        setIsExpanded(false);
      }
    };

    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsExpanded(false);
      }
    };

    if (isExpanded) {
      document.addEventListener('keydown', handleKeyDown);
      document.addEventListener('mousedown', handleClickOutside);
    }

    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isExpanded]);

  // Window event listener to cycle or toggle notch position
  useEffect(() => {
    const handleToggle = () => {
      setDockPosition((prev) => (prev === 'top' ? 'left' : prev === 'left' ? 'right' : 'top'));
      setIsExpanded(false);
    };
    window.addEventListener('macdeck-toggle-notch', handleToggle);
    return () => {
      window.removeEventListener('macdeck-toggle-notch', handleToggle);
    };
  }, []);

  // Compute exact dimensions matching Swift implementation
  const getDimensions = () => {
    if (isDetached) {
      return { width: 76, height: 40 };
    }
    if (dockPosition === 'left' || dockPosition === 'right') {
      return {
        width: isExpanded ? 280 : 48,
        height: isExpanded ? 380 : 116,
      };
    }
    // Top
    return {
      width: isExpanded ? 480 : 184,
      height: isExpanded ? 224 : 32,
    };
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
        isExpanded ? 24 : 18
      )
    : getSideNotchPath(
        currentEdge,
        width,
        height,
        dockPosition === 'floating' || isDetached ? 20 : isExpanded ? 24 : 18,
        14
      );

  const handleNavClick = (href: string, e: React.MouseEvent) => {
    e.preventDefault();
    setIsExpanded(false);
    const target = document.querySelector(href);
    if (target) {
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

      {/* Edge Proximity Dropzone Previews */}
      <AnimatePresence>
        {isDragging && dragProximity === 'top' && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-0 left-1/2 -translate-x-1/2 w-[480px] max-w-[90vw] h-10 rounded-b-2xl border-2 border-dashed border-emerald-500/40 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
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
            className="fixed left-0 top-1/2 -translate-y-1/2 w-28 h-48 rounded-r-2xl border-2 border-dashed border-emerald-500/40 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide [writing-mode:vertical-rl] rotate-180">
              Release to dock to Left Side
            </span>
          </motion.div>
        )}

        {isDragging && dragProximity === 'right' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 20 }}
            className="fixed right-0 top-1/2 -translate-y-1/2 w-28 h-48 rounded-l-2xl border-2 border-dashed border-emerald-500/40 bg-emerald-950/20 backdrop-blur-xs z-40 flex items-center justify-center pointer-events-none"
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide [writing-mode:vertical-rl]">
              Release to dock to Right Side
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Notch Component Container */}
      <div ref={containerRef} className={`${getContainerClasses()} ${className}`}>
        {/* Side Notch Chat Bubble (SideNotchBubbleView.swift reproduced) */}
        <AnimatePresence>
          {!isExpanded &&
            isHovered &&
            !isDragging &&
            (dockPosition === 'left' || dockPosition === 'right') && (
              <motion.div
                initial={{ opacity: 0, x: dockPosition === 'left' ? -6 : 6 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: dockPosition === 'left' ? -6 : 6 }}
                transition={{ duration: 0.18 }}
                className={`absolute top-1/2 -translate-y-1/2 ${
                  dockPosition === 'left' ? 'left-[54px]' : 'right-[54px]'
                } pointer-events-none z-30`}
              >
                <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-[#12151f]/95 border border-white/20 text-white shadow-xl backdrop-blur-xl whitespace-nowrap text-xs">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.9)]" />
                  <span className="font-semibold text-white/95">Pixel 8 Pro</span>
                  <span className="text-white/40 font-bold">•</span>
                  <span className="text-white/90 font-mono font-medium">98% USB Active</span>
                </div>
              </motion.div>
            )}
        </AnimatePresence>

        {/* The Liquid Draggable Body */}
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

            // Compute elastic stretch distance
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

            // Detach if pulled past 95px
            if (stretch > 95 && !isDetached) {
              setIsDetached(true);
            }

            // Detect edge proximity for docking
            const x = info.point.x;
            const y = info.point.y;
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
              info.point.x - dragStartPosRef.current.x,
              info.point.y - dragStartPosRef.current.y
            );
            const x = info.point.x;
            const y = info.point.y;
            const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;

            if (dist > 8) {
              if (y <= 90) {
                setDockPosition('top');
              } else if (x <= 130) {
                setDockPosition('left');
              } else if (x >= winW - 130) {
                setDockPosition('right');
              } else {
                setDockPosition('floating');
              }
            }

            // Reset liquid stretch
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
          onHoverStart={() => setIsHovered(true)}
          onHoverEnd={() => setIsHovered(false)}
          className="relative cursor-grab active:cursor-grabbing transition-transform"
          style={{ width, height }}
        >
          {/* ========================================================= */}
          {/* SVG LIQUID GLASS BACKGROUND (SideNotchShape / LiquidPull) */}
          {/* ========================================================= */}
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none overflow-visible drop-shadow-[0_12px_24px_rgba(0,0,0,0.4)]"
            viewBox={`0 0 ${width} ${height}`}
            aria-hidden="true"
          >
            {/* Liquid Gooey Shadow Base */}
            <path
              d={notchPath}
              fill="rgba(0, 0, 0, 0.45)"
              transform="translate(0, 4)"
              filter="blur(6px)"
            />

            {/* Obsidian Glass Acrylic Base (LiquidGlassBackground.swift) */}
            <path
              d={notchPath}
              fill="url(#glassAcrylicGradient)"
            />

            {/* Directional Specular Reflection Rim */}
            <path
              d={notchPath}
              fill="none"
              stroke="url(#specularRimGradient)"
              strokeWidth="1.25"
            />

            {/* Gradient Definitions */}
            <defs>
              <linearGradient
                id="glassAcrylicGradient"
                x1={dockPosition === 'right' ? '1' : '0'}
                y1="0"
                x2={dockPosition === 'right' ? '0' : '0'}
                y2="1"
              >
                <stop offset="0%" stopColor="#1c202a" stopOpacity="0.98" />
                <stop offset="100%" stopColor="#080a0f" stopOpacity="0.99" />
              </linearGradient>

              <linearGradient
                id="specularRimGradient"
                x1="0"
                y1="0"
                x2={dockPosition === 'top' ? '0' : '1'}
                y2={dockPosition === 'top' ? '1' : '0'}
              >
                <stop offset="0%" stopColor="rgba(255, 255, 255, 0.45)" />
                <stop offset="25%" stopColor="rgba(255, 255, 255, 0.18)" />
                <stop offset="70%" stopColor="rgba(255, 255, 255, 0.05)" />
                <stop offset="100%" stopColor="rgba(255, 255, 255, 0.01)" />
              </linearGradient>
            </defs>
          </svg>

          {/* ========================================================= */}
          {/* 1. COLLAPSED VIEW: TOP NOTCH (CollapsedNotchView.swift)   */}
          {/* ========================================================= */}
          {!isExpanded && (dockPosition === 'top' || dockPosition === 'floating') && (
            <button
              type="button"
              onClick={() => {
                if (!isDragging) setIsExpanded(true);
              }}
              className="w-full h-full px-3 flex items-center justify-between z-10 text-white cursor-pointer select-none focus:outline-none"
              aria-label="Expand Top Notch navigation"
            >
              {/* Left: FaceTime Camera Lens Cutout */}
              <div className="flex items-center gap-1.5">
                <div
                  className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0"
                  title="FaceTime Camera Cutout"
                >
                  <div className="w-1 h-1 rounded-full bg-[#1b253b] opacity-80" />
                </div>
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_5px_rgba(52,211,153,0.8)]" />
              </div>

              {/* Center: Title */}
              <span className="text-[11px] font-semibold text-white/90 tracking-tight font-poppins">
                macdeck
              </span>

              {/* Right: Phone Battery & Status Capsule */}
              <div className="flex items-center gap-1 px-1.5 py-0.5 rounded-full bg-white/10 border border-white/12 text-[9.5px] font-mono text-white/90">
                <svg className="w-2.5 h-2.5 fill-emerald-400" viewBox="0 0 24 24">
                  <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
                </svg>
                <span>98%</span>
              </div>
            </button>
          )}

          {/* ========================================================= */}
          {/* 2. COLLAPSED VIEW: SIDE NOTCH (CollapsedNotchView.swift)  */}
          {/* ========================================================= */}
          {!isExpanded && (dockPosition === 'left' || dockPosition === 'right') && (
            <button
              type="button"
              onClick={() => {
                if (!isDragging) setIsExpanded(true);
              }}
              className="w-full h-full py-2.5 flex flex-col items-center justify-between z-10 text-white cursor-pointer select-none focus:outline-none"
              aria-label="Expand Side Notch navigation"
            >
              {/* Connection Status Indicator Dot */}
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />

              {/* Phone Charge Circular Progress Gauge (28×28) */}
              <div className="flex flex-col items-center gap-1">
                <div className="relative w-7 h-7 flex items-center justify-center">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 28 28">
                    {/* Track */}
                    <circle
                      cx="14"
                      cy="14"
                      r="11"
                      stroke="rgba(255, 255, 255, 0.12)"
                      strokeWidth="2.5"
                      fill="none"
                    />
                    {/* Progress Arc */}
                    <circle
                      cx="14"
                      cy="14"
                      r="11"
                      stroke="#34d399"
                      strokeWidth="2.5"
                      strokeDasharray={2 * Math.PI * 11}
                      strokeDashoffset={2 * Math.PI * 11 * (1 - 0.98)}
                      strokeLinecap="round"
                      fill="none"
                    />
                  </svg>
                  {/* Phone Bolt Icon in Center */}
                  <svg
                    className="absolute w-3 h-3 text-white fill-current"
                    viewBox="0 0 24 24"
                  >
                    <path d="M17 1.01L7 1c-1.1 0-2 .9-2 2v18c0 1.1.9 2 2 2h10c1.1 0 2-.9 2-2V3c0-1.1-.9-1.99-2-1.99zM17 19H7V5h10v14z" />
                  </svg>
                </div>
                <span className="text-[9.5px] font-bold font-mono text-white/90">98%</span>
              </div>

              {/* Deck Badge */}
              <span className="text-[8.5px] font-mono uppercase tracking-wider text-white/50">
                Deck
              </span>
            </button>
          )}

          {/* ========================================================= */}
          {/* 3. EXPANDED VIEW: TOP NOTCH (ExpandedDeckView.swift)      */}
          {/* ========================================================= */}
          {isExpanded && (dockPosition === 'top' || dockPosition === 'floating') && (
            <motion.div
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.96 }}
              transition={{ duration: 0.22 }}
              className="p-4 sm:p-5 flex flex-col justify-between h-full z-10 text-white"
            >
              {/* Header Bar */}
              <div className="flex items-center justify-between pb-2.5 border-b border-white/10">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.8)]" />
                  <span className="text-xs font-semibold text-white/95">
                    MacDeck Navigation HUD
                  </span>
                  <span className="text-[10px] text-white/40 font-mono">Pixel 8 Pro</span>
                </div>

                <div className="flex items-center gap-2">
                  {/* Dock Switcher Icons */}
                  <div className="flex items-center gap-1 bg-white/5 rounded-lg p-0.5 border border-white/10 text-[9.5px] font-mono text-white/60">
                    <button
                      type="button"
                      onClick={() => setDockPosition('top')}
                      className={`px-1.5 py-0.5 rounded cursor-pointer ${
                        dockPosition === 'top' ? 'bg-white/20 text-white' : 'hover:text-white'
                      }`}
                      title="Dock to top"
                    >
                      Top
                    </button>
                    <button
                      type="button"
                      onClick={() => setDockPosition('left')}
                      className="px-1.5 py-0.5 rounded hover:text-white cursor-pointer"
                      title="Dock to left side"
                    >
                      Left
                    </button>
                    <button
                      type="button"
                      onClick={() => setDockPosition('right')}
                      className="px-1.5 py-0.5 rounded hover:text-white cursor-pointer"
                      title="Dock to right side"
                    >
                      Right
                    </button>
                  </div>

                  {/* Close / Collapse Button */}
                  <button
                    type="button"
                    onClick={() => setIsExpanded(false)}
                    className="w-6 h-6 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors cursor-pointer"
                    aria-label="Collapse Notch HUD"
                  >
                    <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </button>
                </div>
              </div>

              {/* 4 Primary Navigation Cards */}
              <div className="grid grid-cols-2 gap-2.5 my-auto">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className="p-2.5 rounded-xl bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 transition-all flex flex-col gap-0.5 text-left group cursor-pointer"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-white/95 group-hover:text-cyan-300 transition-colors">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-cyan-300 group-hover:translate-x-0.5 transition-all" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </div>
                    <span className="text-[10px] text-white/50 line-clamp-1">
                      {item.subtitle}
                    </span>
                  </a>
                ))}
              </div>

              {/* Bottom Status Ribbon */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[10px] text-white/40 font-mono">
                <span>Drag notch to reposition to side or top</span>
                <span>Press Esc to collapse</span>
              </div>
            </motion.div>
          )}

          {/* ========================================================= */}
          {/* 4. EXPANDED VIEW: SIDE NOTCH (ExpandedDeckView.swift)     */}
          {/* ========================================================= */}
          {isExpanded && (dockPosition === 'left' || dockPosition === 'right') && (
            <motion.div
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.96 }}
              transition={{ duration: 0.22 }}
              className="p-4 flex flex-col justify-between h-full z-10 text-white"
            >
              {/* Header */}
              <div className="flex items-center justify-between pb-2.5 border-b border-white/10">
                <div className="flex items-center gap-1.5">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.8)]" />
                  <span className="text-xs font-semibold text-white/95">MacDeck</span>
                </div>
                <button
                  type="button"
                  onClick={() => setIsExpanded(false)}
                  className="w-5 h-5 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors cursor-pointer"
                  aria-label="Collapse Side Notch"
                >
                  <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              </div>

              {/* Vertical Stack of Navigation Tiles */}
              <div className="flex flex-col gap-2 my-auto">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className="p-2.5 rounded-xl bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 transition-all flex flex-col gap-0.5 text-left group cursor-pointer"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-white/95 group-hover:text-cyan-300 transition-colors">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-cyan-300 group-hover:translate-x-0.5 transition-all" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </div>
                    <span className="text-[9.5px] text-white/50 line-clamp-1">
                      {item.subtitle}
                    </span>
                  </a>
                ))}
              </div>

              {/* Footer Dock Controls */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[10px] text-white/40 font-mono">
                <button
                  type="button"
                  onClick={() => setDockPosition('top')}
                  className="hover:text-white transition-colors cursor-pointer"
                >
                  Dock Top
                </button>
                <span>•</span>
                <button
                  type="button"
                  onClick={() =>
                    setDockPosition((prev) => (prev === 'left' ? 'right' : 'left'))
                  }
                  className="hover:text-white transition-colors cursor-pointer"
                >
                  {dockPosition === 'left' ? 'Switch Right' : 'Switch Left'}
                </button>
              </div>
            </motion.div>
          )}
        </motion.div>
      </div>
    </>
  );
}
