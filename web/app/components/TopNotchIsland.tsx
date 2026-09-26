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
    subtitle: 'USB reverse tunnel, fluid notch HUD, tactile surface',
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

  // Liquid Pull / Drag State
  const [stretchDistance, setStretchDistance] = useState<number>(0);
  const [lateralOffset, setLateralOffset] = useState<number>(0);
  const [isPulling, setIsPulling] = useState<boolean>(false);
  const [isDetached, setIsDetached] = useState<boolean>(false);
  const [floatingPos, setFloatingPos] = useState<{ x: number; y: number }>({ x: 0, y: 0 });
  const [dragProximity, setDragProximity] = useState<DockPosition | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const pointerStartRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const hasMovedRef = useRef<boolean>(false);

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

  // Window event listener to cycle dock position from external buttons
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

  // Compute exact dimensions
  const getDimensions = () => {
    if (isDetached) {
      return { width: 140, height: 36 };
    }
    if (dockPosition === 'left' || dockPosition === 'right') {
      const baseW = isExpanded ? 280 : 48;
      const baseH = isExpanded ? 380 : 116;
      return {
        width: baseW + (isPulling ? stretchDistance : 0),
        height: baseH,
      };
    }
    // Top dock
    const baseW = isExpanded ? 480 : 184;
    const baseH = isExpanded ? 220 : 32;
    return {
      width: baseW,
      height: baseH + (isPulling ? stretchDistance : 0),
    };
  };

  const { width, height } = getDimensions();
  const currentEdge: NotchEdge =
    dockPosition === 'left' ? 'left' : dockPosition === 'right' ? 'right' : 'top';

  // Generate SVG path for the exact liquid notch outline
  const notchPath = isDetached
    ? getLiquidPullPath('top', width, height, 0, 0, true)
    : isPulling && stretchDistance > 0
    ? getLiquidPullPath(
        currentEdge,
        width,
        height,
        stretchDistance,
        lateralOffset,
        false,
        isExpanded ? 24 : 18
      )
    : getSideNotchPath(
        currentEdge,
        width,
        height,
        isExpanded ? 24 : 18,
        14
      );

  // Pointer drag gesture handlers: Left click hold & follow liquid
  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    // If clicking on internal interactive navigation links in expanded view, don't drag
    if ((e.target as HTMLElement).closest('a, button:not([data-notch-trigger])')) {
      return;
    }
    pointerStartRef.current = { x: e.clientX, y: e.clientY };
    hasMovedRef.current = false;
    e.currentTarget.setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!e.currentTarget.hasPointerCapture(e.pointerId)) return;

    const dx = e.clientX - pointerStartRef.current.x;
    const dy = e.clientY - pointerStartRef.current.y;
    const dist = Math.hypot(dx, dy);

    if (dist > 4) {
      hasMovedRef.current = true;
    }

    if (isExpanded) {
      // In expanded state, check proximity for drag switching
      const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;
      if (e.clientY <= 80) setDragProximity('top');
      else if (e.clientX <= 110) setDragProximity('left');
      else if (e.clientX >= winW - 110) setDragProximity('right');
      else setDragProximity(null);
      return;
    }

    // In collapsed state: Liquid Pull Effect following the cursor!
    let stretch = 0;
    let lateral = 0;

    if (dockPosition === 'top') {
      stretch = Math.max(0, dy * 0.85);
      lateral = dx;
    } else if (dockPosition === 'left') {
      stretch = Math.max(0, dx * 0.85);
      lateral = dy;
    } else if (dockPosition === 'right') {
      stretch = Math.max(0, -dx * 0.85);
      lateral = dy;
    }

    // When pulled past 90px, detach into floating droplet following cursor directly
    if (stretch > 90 || Math.abs(dx) > 160 || isDetached) {
      if (!isDetached) setIsDetached(true);
      setFloatingPos({ x: e.clientX, y: e.clientY });
    } else {
      setIsDetached(false);
      setStretchDistance(Math.min(115, stretch));
      setLateralOffset(lateral);
      setIsPulling(stretch > 2);
    }

    // Proximity dropzone detection
    const winW = typeof window !== 'undefined' ? window.innerWidth : 1200;
    if (e.clientY <= 85) setDragProximity('top');
    else if (e.clientX <= 120) setDragProximity('left');
    else if (e.clientX >= winW - 120) setDragProximity('right');
    else setDragProximity(null);
  };

  const handlePointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!e.currentTarget.hasPointerCapture(e.pointerId)) return;
    e.currentTarget.releasePointerCapture(e.pointerId);

    const wasPulling = isPulling;
    const wasDetached = isDetached;
    const currentStretch = stretchDistance;
    const currentProximity = dragProximity;

    // Reset liquid pull states
    setIsPulling(false);
    setIsDetached(false);
    setStretchDistance(0);
    setLateralOffset(0);
    setDragProximity(null);

    // If dragged near another edge dropzone, snap into it
    if (currentProximity && currentProximity !== dockPosition) {
      setDockPosition(currentProximity);
      setIsExpanded(false);
      return;
    }

    // If pulled down/inward past 48px, snap open into the navigation view!
    if ((wasPulling && currentStretch > 48) || wasDetached) {
      setIsExpanded(true);
      return;
    }

    // Clean click without drag: Toggle Expand!
    if (!hasMovedRef.current) {
      setIsExpanded((prev) => !prev);
    }
  };

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
    if (isDetached) {
      return 'fixed z-50 select-none pointer-events-none';
    }
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

  // Calculate dynamic liquid bulb follow offset
  const getBulbFollowTransform = () => {
    if (!isPulling || stretchDistance <= 0) return 'translate(0px, 0px)';
    if (dockPosition === 'top') {
      const clampedLat = Math.max(-40, Math.min(40, lateralOffset * 0.35));
      return `translate(${clampedLat}px, ${stretchDistance * 0.82}px)`;
    }
    if (dockPosition === 'left') {
      const clampedLat = Math.max(-40, Math.min(40, lateralOffset * 0.35));
      return `translate(${stretchDistance * 0.82}px, ${clampedLat}px)`;
    }
    if (dockPosition === 'right') {
      const clampedLat = Math.max(-40, Math.min(40, lateralOffset * 0.35));
      return `translate(${-stretchDistance * 0.82}px, ${clampedLat}px)`;
    }
    return 'translate(0px, 0px)';
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
        {(isPulling || isDetached) && dragProximity && dragProximity !== dockPosition && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className={`fixed z-40 border-2 border-dashed border-emerald-400/50 bg-emerald-950/20 backdrop-blur-xs flex items-center justify-center pointer-events-none ${
              dragProximity === 'top'
                ? 'top-0 left-1/2 -translate-x-1/2 w-[480px] max-w-[90vw] h-10 rounded-b-2xl'
                : dragProximity === 'left'
                ? 'left-0 top-1/2 -translate-y-1/2 w-28 h-48 rounded-r-2xl'
                : 'right-0 top-1/2 -translate-y-1/2 w-28 h-48 rounded-l-2xl'
            }`}
          >
            <span className="text-[11px] font-mono text-emerald-300 font-medium tracking-wide">
              Release to dock
            </span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Notch Component Container */}
      <div
        ref={containerRef}
        className={`${getContainerClasses()} ${className}`}
        style={
          isDetached
            ? {
                left: floatingPos.x - width / 2,
                top: floatingPos.y - height / 2,
              }
            : undefined
        }
      >
        {/* Side Notch Hover Bubble (SideNotchBubbleView.swift - No battery percent!) */}
        <AnimatePresence>
          {!isExpanded &&
            isHovered &&
            !isPulling &&
            !isDetached &&
            (dockPosition === 'left' || dockPosition === 'right') && (
              <motion.div
                initial={{ opacity: 0, x: dockPosition === 'left' ? -6 : 6 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: dockPosition === 'left' ? -6 : 6 }}
                transition={{ duration: 0.18 }}
                className={`absolute top-1/2 -translate-y-1/2 ${
                  dockPosition === 'left' ? 'left-[56px]' : 'right-[56px]'
                } pointer-events-none z-30`}
              >
                <div className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-[#12151f]/95 border border-white/20 text-white shadow-xl backdrop-blur-xl whitespace-nowrap text-xs">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.9)]" />
                  <span className="font-semibold text-white/95">MacDeck</span>
                  <span className="text-white/40 font-bold">•</span>
                  <span className="text-white/90 font-mono font-medium">Click to navigate</span>
                </div>
              </motion.div>
            )}
        </AnimatePresence>

        {/* The Liquid Pullable Notch Element */}
        <motion.div
          onPointerDown={handlePointerDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          onPointerCancel={handlePointerUp}
          onHoverStart={() => setIsHovered(true)}
          onHoverEnd={() => setIsHovered(false)}
          layout
          transition={{
            type: 'spring',
            stiffness: 350,
            damping: 26,
            mass: 0.75,
          }}
          className={`relative touch-none transition-shadow ${
            isExpanded ? 'cursor-default' : 'cursor-pointer hover:drop-shadow-[0_8px_16px_rgba(0,0,0,0.35)]'
          }`}
          style={{ width, height }}
        >
          {/* ========================================================= */}
          {/* SVG LIQUID GLASS OUTLINE (SideNotchShape / LiquidPull)    */}
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
            <path d={notchPath} fill="url(#liquidObsidianGradient)" />

            {/* Directional Specular Reflection Rim */}
            <path
              d={notchPath}
              fill="none"
              stroke="url(#liquidSpecularRim)"
              strokeWidth="1.25"
            />

            <defs>
              <linearGradient
                id="liquidObsidianGradient"
                x1={dockPosition === 'right' ? '1' : '0'}
                y1="0"
                x2={dockPosition === 'right' ? '0' : '0'}
                y2="1"
              >
                <stop offset="0%" stopColor="#1a1e28" stopOpacity="0.98" />
                <stop offset="100%" stopColor="#080a0f" stopOpacity="0.99" />
              </linearGradient>

              <linearGradient
                id="liquidSpecularRim"
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
          {/* 1. COLLAPSED VIEW: TOP NOTCH                              */}
          {/* Content directly follows the liquid bulb on pointer drag! */}
          {/* ========================================================= */}
          {!isExpanded && !isDetached && (dockPosition === 'top' || dockPosition === 'floating') && (
            <div
              data-notch-trigger
              className="relative z-10 w-full h-full px-3.5 flex items-center justify-between text-white select-none pointer-events-auto transition-transform duration-75"
              style={{ transform: getBulbFollowTransform() }}
              title="Click or pull down to open navigation"
            >
              {/* Left: Camera Cutout & Emerald Status Dot */}
              <div className="flex items-center gap-1.5">
                <div
                  className="w-2.5 h-2.5 rounded-full bg-[#0d121d] border border-[#1b253b] flex items-center justify-center shrink-0"
                  title="FaceTime Camera Cutout"
                >
                  <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
                </div>
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_5px_rgba(52,211,153,0.85)]" />
              </div>

              {/* Center: Brand */}
              <span className="text-[11.5px] font-semibold text-white/95 tracking-tight font-poppins">
                macdeck
              </span>

              {/* Right: Drag/Pull Grip Indicator (NO battery percent!) */}
              <div
                className="flex items-center gap-0.5 opacity-40 hover:opacity-100 transition-opacity"
                title="Drag or pull down to navigate"
              >
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
                <div className="w-1 h-1 rounded-full bg-white/70" />
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* 2. COLLAPSED VIEW: SIDE NOTCH (NO BATTERY PERCENT!)       */}
          {/* Content directly follows the liquid bulb on pointer drag! */}
          {/* ========================================================= */}
          {!isExpanded && !isDetached && (dockPosition === 'left' || dockPosition === 'right') && (
            <div
              data-notch-trigger
              className="relative z-10 w-full h-full py-3 flex flex-col items-center justify-between text-white select-none pointer-events-auto transition-transform duration-75"
              style={{ transform: getBulbFollowTransform() }}
              title="Click or pull to open navigation"
            >
              {/* Top: Status Dot */}
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />

              {/* Center: Camera Lens */}
              <div
                className="w-2.5 h-2.5 rounded-full bg-[#0d121d] border border-[#1b253b] flex items-center justify-center shrink-0"
                title="Camera Lens"
              >
                <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
              </div>

              {/* Bottom: Deck Label & Grip */}
              <div className="flex flex-col items-center gap-1.5">
                <span className="text-[9px] font-semibold tracking-wider font-poppins uppercase text-white/75">
                  deck
                </span>
                <div className="flex gap-0.5 opacity-40 hover:opacity-100 transition-opacity">
                  <div className="w-1 h-1 rounded-full bg-white/70" />
                  <div className="w-1 h-1 rounded-full bg-white/70" />
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* DETACHED FLOATING DROPLET MODE (Tracks pointer directly)  */}
          {/* ========================================================= */}
          {isDetached && (
            <div className="w-full h-full px-3 flex items-center justify-between text-white select-none">
              <div className="flex items-center gap-1.5">
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_5px_rgba(52,211,153,0.85)]" />
                <span className="text-[11px] font-semibold tracking-tight text-white/95 font-poppins">
                  macdeck
                </span>
              </div>
              <span className="text-[9.5px] font-mono text-emerald-300">Drop to dock</span>
            </div>
          )}

          {/* ========================================================= */}
          {/* 3. EXPANDED VIEW: TOP NOTCH (CLICK TO SHOW NAVIGATIONS)   */}
          {/* ========================================================= */}
          {isExpanded && (dockPosition === 'top' || dockPosition === 'floating') && (
            <motion.div
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.96 }}
              transition={{ duration: 0.22 }}
              className="p-4 sm:p-5 flex flex-col justify-between h-full z-10 text-white select-none"
            >
              {/* Header Bar */}
              <div className="flex items-center justify-between pb-2.5 border-b border-white/10">
                <div className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />
                  <span className="text-xs font-semibold text-white/95">
                    MacDeck Navigation HUD
                  </span>
                  <span className="text-[10px] text-white/40 font-mono">USB Connected</span>
                </div>

                <div className="flex items-center gap-2">
                  {/* Dock Switcher */}
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

                  {/* Collapse Button */}
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

              {/* 4 Primary Navigation Cards (2x2 Grid) */}
              <div className="grid grid-cols-2 gap-2.5 my-auto">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className="p-2.5 rounded-xl bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 transition-all flex flex-col gap-0.5 text-left group cursor-pointer"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-white/95 group-hover:text-emerald-300 transition-colors">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-emerald-300 group-hover:translate-x-0.5 transition-all" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </div>
                    <span className="text-[10px] text-white/50 line-clamp-1">
                      {item.subtitle}
                    </span>
                  </a>
                ))}
              </div>

              {/* Footer Note */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[10px] text-white/40 font-mono">
                <span>Hold left click & drag to pull liquid • Press Esc to collapse</span>
                <span>v1.0</span>
              </div>
            </motion.div>
          )}

          {/* ========================================================= */}
          {/* 4. EXPANDED VIEW: SIDE NOTCH (CLICK TO SHOW NAVIGATIONS)  */}
          {/* ========================================================= */}
          {isExpanded && (dockPosition === 'left' || dockPosition === 'right') && (
            <motion.div
              initial={{ opacity: 0, scale: 0.96 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.96 }}
              transition={{ duration: 0.22 }}
              className="p-4 flex flex-col justify-between h-full z-10 text-white select-none"
            >
              {/* Header */}
              <div className="flex items-center justify-between pb-2.5 border-b border-white/10">
                <div className="flex items-center gap-1.5">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />
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
                      <span className="text-xs font-semibold text-white/95 group-hover:text-emerald-300 transition-colors">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-emerald-300 group-hover:translate-x-0.5 transition-all" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
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
