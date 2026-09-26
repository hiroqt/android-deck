'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import {
  getNotchGeometry,
  getLiquidPullGeometry,
  getDetachedDropletGeometry,
  NotchPaths,
  NotchEdge,
} from './notch/NotchGeometry';

export type DockPosition = 'top' | 'left' | 'right' | 'floating';

interface TopNotchIslandProps {
  className?: string;
  defaultPosition?: DockPosition;
}

const NAV_ITEMS = [
  {
    id: 'hero',
    title: 'Live Surface',
    subtitle: 'Interactive MacBook notch & Android deck',
    href: '#main-content',
  },
  {
    id: 'how-it-works',
    title: 'Quick Setup',
    subtitle: 'Connect via USB or LAN in three simple steps',
    href: '#how-it-works',
  },
  {
    id: 'github',
    title: 'Source Code',
    subtitle: 'Open source Swift, Kotlin & Python repo',
    href: 'https://github.com',
  },
  {
    id: 'toggle-dock',
    title: 'Cycle Dock',
    subtitle: 'Move Notch: Top, Left, or Right edge',
    href: '#toggle',
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
    const handleToggle = (e: Event) => {
      const customEvent = e as CustomEvent<{ position?: 'top' | 'left' | 'right' }>;
      if (customEvent.detail?.position) {
        setDockPosition(customEvent.detail.position);
      } else {
        setDockPosition((prev) => (prev === 'top' ? 'left' : prev === 'left' ? 'right' : 'top'));
      }
      setIsExpanded(false);
    };
    window.addEventListener('notchdeck-toggle-notch', handleToggle);
    window.addEventListener('macdeck-toggle-notch', handleToggle);
    return () => {
      window.removeEventListener('notchdeck-toggle-notch', handleToggle);
      window.removeEventListener('macdeck-toggle-notch', handleToggle);
      if (typeof document !== 'undefined') {
        document.body.classList.remove('is-notch-dragging');
      }
    };
  }, []);

  // Keep the page-level helper in sync with the notch's current edge.
  useEffect(() => {
    window.dispatchEvent(
      new CustomEvent('notchdeck-position-change', { detail: { position: dockPosition } }),
    );
  }, [dockPosition]);

  // Compute exact dimensions
  const getDimensions = () => {
    if (isDetached) {
      return { width: 140, height: 38 };
    }
    if (dockPosition === 'left' || dockPosition === 'right') {
      const baseW = isExpanded ? 256 : 44;
      const baseH = isExpanded ? 276 : 108;
      return {
        width: baseW + (isPulling ? stretchDistance : 0),
        height: baseH,
      };
    }
    // Top dock
    const baseW = isExpanded ? 510 : 184;
    const baseH = isExpanded ? 244 : 32;
    return {
      width: baseW,
      height: baseH + (isPulling ? stretchDistance : 0),
    };
  };

  const { width, height } = getDimensions();
  const currentEdge: NotchEdge =
    dockPosition === 'left' ? 'left' : dockPosition === 'right' ? 'right' : 'top';

  // Generate exact liquid notch paths (closed fillPath + open rimPath with 0 bezel stroke)
  const notchPaths: NotchPaths = isDetached
    ? getDetachedDropletGeometry(width, height)
    : isPulling && stretchDistance > 0
    ? getLiquidPullGeometry(currentEdge, width, height, stretchDistance, lateralOffset)
    : getNotchGeometry(currentEdge, width, height, 0, isExpanded ? 24 : 16);

  // Pointer drag gesture handlers: Left click hold & follow liquid
  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    // If clicking on internal interactive navigation links in expanded view, don't drag
    if ((e.target as HTMLElement).closest('a, button:not([data-notch-trigger])')) {
      return;
    }
    // Prevent default browser text selection & copy highlighting across the page
    e.preventDefault();
    if (typeof document !== 'undefined') {
      document.body.classList.add('is-notch-dragging');
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

    // In collapsed state: 1:1 on-point tracking with liquid pull
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

    // When pulled past 120px or detached, follow cursor freely as floating droplet
    if (stretch > 120 || Math.abs(dx) > 160 || isDetached) {
      if (!isDetached) setIsDetached(true);
      setFloatingPos({ x: e.clientX, y: e.clientY });
    } else {
      setIsDetached(false);
      setStretchDistance(stretch);
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
    if (typeof document !== 'undefined') {
      document.body.classList.remove('is-notch-dragging');
    }
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
    if (href.startsWith('http')) {
      setIsExpanded(false);
      return;
    }
    e.preventDefault();
    if (href === '#toggle') {
      setDockPosition((prev) => (prev === 'top' ? 'left' : prev === 'left' ? 'right' : 'top'));
      return;
    }
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
      const clampedLat = Math.max(-width * 0.22, Math.min(width * 0.22, lateralOffset * 0.4));
      return `translate(${clampedLat}px, ${stretchDistance}px)`;
    }
    if (dockPosition === 'left') {
      const clampedLat = Math.max(-height * 0.22, Math.min(height * 0.22, lateralOffset * 0.4));
      return `translate(${stretchDistance}px, ${clampedLat}px)`;
    }
    if (dockPosition === 'right') {
      const clampedLat = Math.max(-height * 0.22, Math.min(height * 0.22, lateralOffset * 0.4));
      return `translate(0px, ${clampedLat}px)`;
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
                  <span className="font-semibold text-white/95">NotchDeck</span>
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
          transition={
            isPulling
              ? { duration: 0 }
              : {
                  type: 'spring',
                  stiffness: 420,
                  damping: 28,
                  mass: 0.7,
                }
          }
          className={`relative touch-none ${
            isExpanded ? 'cursor-default' : 'cursor-pointer'
          }`}
          style={{ width, height }}
        >
          {/* ========================================================= */}
          {/* SVG LIQUID GLASS OUTLINE (Zero Bezel Stroke + Acrylic)    */}
          {/* ========================================================= */}
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none overflow-visible z-0"
            viewBox={`0 0 ${width} ${height}`}
            aria-hidden="true"
          >
            {/* Deep Obsidian Acrylic Glass Fill */}
            <path d={notchPaths.fillPath} fill="url(#liquidObsidianGradient)" />

            {/* Directional Specular Reflection Rim (ONLY display facing edge, 0 stroke on bezel) */}
            <path
              d={notchPaths.rimPath}
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
                <stop offset="0%" stopColor="#141822" stopOpacity="0.99" />
                <stop offset="100%" stopColor="#080a10" stopOpacity="0.99" />
              </linearGradient>

              <linearGradient
                id="liquidSpecularRim"
                x1={dockPosition === 'right' ? '1' : '0'}
                y1="0"
                x2={dockPosition === 'top' ? '0' : dockPosition === 'left' ? '1' : '0'}
                y2={dockPosition === 'top' ? '1' : '0'}
              >
                <stop offset="0%" stopColor="rgba(255, 255, 255, 0.45)" />
                <stop offset="25%" stopColor="rgba(255, 255, 255, 0.20)" />
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
              className="absolute top-0 left-0 w-full h-[32px] px-3.5 flex items-center justify-between text-white select-none pointer-events-auto z-20"
              style={{
                transform: getBulbFollowTransform(),
                transition: isPulling ? 'none' : 'transform 0.22s cubic-bezier(0.16, 1, 0.3, 1)',
              }}
              title="Click or pull down to open navigation"
            >
              {isPulling ? (
                <div className="w-full flex items-center justify-center gap-2 pointer-events-none">
                  <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.9)] shrink-0" />
                  <span className="text-[11.5px] font-semibold text-white/95 tracking-tight font-poppins select-none">
                    notchdeck
                  </span>
                </div>
              ) : (
                <>
                  {/* Left: Camera Cutout & Emerald Status Dot */}
                  <div className="flex items-center gap-1.5 shrink-0">
                    <div
                      className="w-2.5 h-2.5 rounded-full bg-[#07090f] border border-[#1e273a] flex items-center justify-center shrink-0"
                      title="FaceTime Camera Cutout"
                    >
                      <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
                    </div>
                    <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.9)]" />
                  </div>

                  {/* Center: Brand */}
                  <span className="text-[12px] font-semibold text-white/95 tracking-tight font-poppins select-none">
                    notchdeck
                  </span>

                  {/* Right: Drag/Pull Grip Indicator (NO battery percent!) */}
                  <div
                    className="flex items-center gap-0.5 opacity-40 hover:opacity-100 transition-opacity shrink-0"
                    title="Drag or pull down to navigate"
                  >
                    <div className="w-1 h-1 rounded-full bg-white/70" />
                    <div className="w-1 h-1 rounded-full bg-white/70" />
                    <div className="w-1 h-1 rounded-full bg-white/70" />
                  </div>
                </>
              )}
            </div>
          )}

          {/* ========================================================= */}
          {/* 2. COLLAPSED VIEW: SIDE NOTCH (NO BATTERY PERCENT!)       */}
          {/* Content directly follows the liquid bulb on pointer drag! */}
          {/* ========================================================= */}
          {!isExpanded && !isDetached && (dockPosition === 'left' || dockPosition === 'right') && (
            <div
              data-notch-trigger
              className="absolute top-0 left-0 w-[44px] h-[108px] py-4 flex flex-col items-center justify-between text-white select-none pointer-events-auto z-20"
              style={{
                transform: getBulbFollowTransform(),
                transition: isPulling ? 'none' : 'transform 0.22s cubic-bezier(0.16, 1, 0.3, 1)',
              }}
              title="Click or pull to open navigation"
            >
              {/* Top: Status Dot (comfortably inside black body) */}
              <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.9)]" />

              {/* Center: Camera Lens */}
              <div
                className="w-2.5 h-2.5 rounded-full bg-[#07090f] border border-[#1e273a] flex items-center justify-center shrink-0"
                title="Camera Lens"
              >
                <div className="w-1 h-1 rounded-full bg-[#1b254b]" />
              </div>

              {/* Bottom: Deck Label & Grip */}
              <div className="flex flex-col items-center gap-1.5">
                <span className="text-[9px] font-bold tracking-widest font-poppins uppercase text-white/75">
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
            <div className="relative z-20 w-full h-full px-3 flex items-center justify-between text-white select-none">
              <div className="flex items-center gap-1.5">
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_5px_rgba(52,211,153,0.85)]" />
                <span className="text-[11px] font-semibold tracking-tight text-white/95 font-poppins">
                  notchdeck
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
              transition={{ duration: 0.2 }}
              className="relative z-20 px-5 pt-3.5 pb-3 flex flex-col justify-between w-full h-full text-white select-none"
            >
              {/* Header Bar */}
              <div className="flex items-center justify-between pb-2 border-b border-white/10 gap-2">
                <div className="flex items-center gap-2 min-w-0">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)] shrink-0" />
                  <span className="text-xs font-semibold text-white/95 truncate">
                    NotchDeck Navigation HUD
                  </span>
                  <span className="text-[10px] text-white/45 font-mono shrink-0 hidden sm:inline">
                    USB Connected
                  </span>
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  {/* Dock Switcher */}
                  <div className="flex items-center gap-0.5 bg-white/10 rounded-lg p-0.5 border border-white/10 text-[9.5px] font-mono text-white/60">
                    <button
                      type="button"
                      onClick={() => setDockPosition('top')}
                      className={`px-1.5 py-0.5 rounded cursor-pointer transition-colors ${
                        dockPosition === 'top' ? 'bg-white/25 text-white font-semibold' : 'hover:text-white'
                      }`}
                      title="Dock to top"
                    >
                      Top
                    </button>
                    <button
                      type="button"
                      onClick={() => setDockPosition('left')}
                      className="px-1.5 py-0.5 rounded cursor-pointer hover:text-white transition-colors"
                      title="Dock to left side"
                    >
                      Left
                    </button>
                    <button
                      type="button"
                      onClick={() => setDockPosition('right')}
                      className="px-1.5 py-0.5 rounded cursor-pointer hover:text-white transition-colors"
                      title="Dock to right side"
                    >
                      Right
                    </button>
                  </div>

                  {/* Collapse Button */}
                  <button
                    type="button"
                    onClick={() => setIsExpanded(false)}
                    className="w-5.5 h-5.5 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors cursor-pointer"
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
              <div className="grid grid-cols-2 gap-2 my-auto">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    target={item.href.startsWith('http') ? '_blank' : undefined}
                    rel={item.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className="p-2.5 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 hover:border-white/20 transition-all flex flex-col justify-between gap-1 text-left group cursor-pointer"
                  >
                    <div className="flex items-center justify-between gap-1">
                      <span className="text-xs font-semibold text-white group-hover:text-emerald-300 transition-colors truncate">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-emerald-300 group-hover:translate-x-0.5 transition-all shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </div>
                    <span className="text-[10.5px] text-white/70 leading-snug line-clamp-1">
                      {item.subtitle}
                    </span>
                  </a>
                ))}
              </div>

              {/* Footer Note */}
              <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[10px] text-white/45 font-mono">
                <span className="truncate">Hold left click & drag to pull liquid • Press Esc to collapse</span>
                <span className="shrink-0 pl-2">v1.0</span>
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
              transition={{ duration: 0.2 }}
              className="relative z-20 px-3.5 pt-3.5 pb-3.5 flex flex-col justify-between w-full h-full text-white select-none"
            >
              {/* Header */}
              <div className="flex items-center justify-between pb-2 border-b border-white/10">
                <div className="flex items-center gap-1.5">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 shadow-[0_0_6px_rgba(52,211,153,0.85)]" />
                  <span className="text-xs font-semibold text-white/95">NotchDeck Navigation</span>
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
              <div className="flex flex-col gap-1.5 my-auto">
                {NAV_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    target={item.href.startsWith('http') ? '_blank' : undefined}
                    rel={item.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                    onClick={(e) => handleNavClick(item.href, e)}
                    className="px-3 py-2 rounded-xl bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 hover:border-white/20 transition-all flex flex-col gap-0.5 text-left group cursor-pointer"
                  >
                    <div className="flex items-center justify-between gap-1">
                      <span className="text-xs font-semibold text-white group-hover:text-emerald-300 transition-colors truncate">
                        {item.title}
                      </span>
                      <svg className="w-3 h-3 text-white/40 group-hover:text-emerald-300 group-hover:translate-x-0.5 transition-all shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                        <polyline points="9 18 15 12 9 6" />
                      </svg>
                    </div>
                    <span className="text-[10px] text-white/70 leading-snug line-clamp-1">
                      {item.subtitle}
                    </span>
                  </a>
                ))}
              </div>
            </motion.div>
          )}
        </motion.div>
      </div>
    </>
  );
}
