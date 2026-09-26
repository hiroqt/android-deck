'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { DeckSlotItem } from '../types/deck';
import { AVAILABLE_MAC_APPS, AppIconRenderer } from './DesktopNotchMockup';

export interface TopNotchIslandProps {
  slots?: DeckSlotItem[];
  onClearSlot?: (slot: DeckSlotItem) => void;
  onAssignSlot?: (index: number, app: Partial<DeckSlotItem>) => void;
  onResetDefaults?: () => void;
  className?: string;
}

export const DEFAULT_NOTCH_SLOTS: DeckSlotItem[] = [
  {
    id: 'app-1',
    index: 0,
    label: 'Terminal',
    bundleId: 'com.apple.Terminal',
    iconType: 'terminal',
    isEmpty: false,
  },
  {
    id: 'app-2',
    index: 1,
    label: 'VS Code',
    bundleId: 'com.microsoft.VSCode',
    iconType: 'code',
    isEmpty: false,
  },
  {
    id: 'app-3',
    index: 2,
    label: 'Safari',
    bundleId: 'com.apple.Safari',
    iconType: 'safari',
    isEmpty: false,
  },
  {
    id: 'app-4',
    index: 3,
    label: 'Finder',
    bundleId: 'com.apple.finder',
    iconType: 'finder',
    isEmpty: false,
  },
  {
    id: 'app-5',
    index: 4,
    label: 'Settings',
    bundleId: 'com.apple.systempreferences',
    iconType: 'settings',
    isEmpty: false,
  },
  {
    id: 'app-6',
    index: 5,
    label: 'Music',
    bundleId: 'com.apple.Music',
    iconType: 'music',
    isEmpty: false,
  },
];

const NAV_LINKS = [
  { label: 'How it works', href: '#how-it-works' },
  { label: 'Requirements', href: '#requirements' },
  { label: 'Private by design', href: '#privacy' },
  { label: 'Setup', href: '#setup' },
];

export default function TopNotchIsland({
  slots: controlledSlots,
  onClearSlot,
  onAssignSlot,
  onResetDefaults,
  className = '',
}: TopNotchIslandProps) {
  const [internalSlots, setInternalSlots] = useState<DeckSlotItem[]>(
    controlledSlots ?? DEFAULT_NOTCH_SLOTS
  );
  const activeSlots = controlledSlots ?? internalSlots;

  const [isExpanded, setIsExpanded] = useState<boolean>(false);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [selectedSlotIndex, setSelectedSlotIndex] = useState<number | null>(null);
  const [statusNotification, setStatusNotification] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const notificationTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const dragStartPosRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Sync internal slots if controlledSlots prop changes
  useEffect(() => {
    if (controlledSlots) {
      setInternalSlots(controlledSlots);
    }
  }, [controlledSlots]);

  // Window broadcast listener for cross-component synchronisation
  useEffect(() => {
    const handleBroadcast = (event: Event) => {
      const customEvent = event as CustomEvent<DeckSlotItem[]>;
      if (!controlledSlots && Array.isArray(customEvent.detail)) {
        setInternalSlots(customEvent.detail);
      }
    };
    window.addEventListener('macdeck-slots-sync', handleBroadcast);
    return () => {
      window.removeEventListener('macdeck-slots-sync', handleBroadcast);
    };
  }, [controlledSlots]);

  // Window listener for toggling notch open/close
  useEffect(() => {
    const handleToggle = () => {
      setIsExpanded((prev) => !prev);
    };
    window.addEventListener('macdeck-toggle-notch', handleToggle);
    return () => {
      window.removeEventListener('macdeck-toggle-notch', handleToggle);
    };
  }, []);

  const broadcastSlots = (updated: DeckSlotItem[]) => {
    window.dispatchEvent(new CustomEvent('macdeck-slots-sync', { detail: updated }));
  };

  // Close when clicking outside or pressing Escape
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsExpanded(false);
        setSelectedSlotIndex(null);
      }
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setIsExpanded(false);
        setSelectedSlotIndex(null);
      }
    };

    if (isExpanded) {
      document.addEventListener('mousedown', handleClickOutside);
      document.addEventListener('keydown', handleKeyDown);
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [isExpanded]);

  const showStatus = (msg: string) => {
    setStatusNotification(msg);
    if (notificationTimeoutRef.current) clearTimeout(notificationTimeoutRef.current);
    notificationTimeoutRef.current = setTimeout(() => {
      setStatusNotification(null);
    }, 2800);
  };

  useEffect(() => {
    return () => {
      if (notificationTimeoutRef.current) clearTimeout(notificationTimeoutRef.current);
    };
  }, []);

  const handleToggleExpand = () => {
    if (isDragging) return;
    setIsExpanded((prev) => !prev);
    setSelectedSlotIndex(null);
  };

  const handleClearSlot = (slot: DeckSlotItem, e: React.MouseEvent) => {
    e.stopPropagation();
    const updated = activeSlots.map((s) =>
      s.index === slot.index ? { ...s, label: '', bundleId: '', isEmpty: true } : s
    );

    if (onClearSlot) {
      onClearSlot(slot);
    } else {
      setInternalSlots(updated);
    }
    broadcastSlots(updated);
    showStatus(`Slot ${slot.index + 1} cleared`);
  };

  const handleSelectApp = (app: (typeof AVAILABLE_MAC_APPS)[0]) => {
    if (selectedSlotIndex === null) return;
    const targetIndex = selectedSlotIndex;

    const updatedItem: Partial<DeckSlotItem> = {
      id: `app-${targetIndex + 1}`,
      index: targetIndex,
      label: app.label,
      bundleId: app.bundleId,
      iconType: app.iconType,
      isEmpty: false,
    };

    const updated = activeSlots.map((s) =>
      s.index === targetIndex
        ? {
            ...s,
            label: app.label,
            bundleId: app.bundleId,
            iconType: app.iconType,
            isEmpty: false,
          }
        : s
    );

    if (onAssignSlot) {
      onAssignSlot(targetIndex, updatedItem);
    } else {
      setInternalSlots(updated);
    }
    broadcastSlots(updated);
    setSelectedSlotIndex(null);
    showStatus(`Slot ${targetIndex + 1}: ${app.label}`);
  };

  const handleReset = () => {
    if (onResetDefaults) {
      onResetDefaults();
    } else {
      setInternalSlots(DEFAULT_NOTCH_SLOTS);
      broadcastSlots(DEFAULT_NOTCH_SLOTS);
    }
    showStatus('Restored default 6 slots');
  };

  return (
    <div
      ref={containerRef}
      className={`fixed top-0 left-1/2 -translate-x-1/2 z-50 select-none ${className}`}
    >
      <motion.div
        drag
        dragMomentum={false}
        dragElastic={0.12}
        onDragStart={(_e, info) => {
          dragStartPosRef.current = { x: info.point.x, y: info.point.y };
          setIsDragging(true);
        }}
        onDragEnd={(_e, info) => {
          const dist = Math.hypot(
            info.point.x - dragStartPosRef.current.x,
            info.point.y - dragStartPosRef.current.y
          );
          // If moved less than 5px, treat as a click rather than drag
          if (dist < 5) {
            setIsDragging(false);
          } else {
            setTimeout(() => setIsDragging(false), 50);
          }
        }}
        layout
        transition={{
          type: 'spring',
          damping: 28,
          stiffness: 340,
          mass: 0.8,
        }}
        className={`bg-black text-white shadow-2xl overflow-hidden border-x border-b border-white/15 cursor-grab active:cursor-grabbing ${
          isExpanded
            ? 'w-[560px] max-w-[96vw] rounded-b-[24px] bg-[#0c1017]/95 backdrop-blur-2xl'
            : 'w-[230px] h-[34px] rounded-b-[18px] hover:bg-[#11141d]'
        }`}
        role={!isExpanded ? 'button' : undefined}
        tabIndex={!isExpanded ? 0 : undefined}
        aria-expanded={isExpanded}
        aria-label="Notch Navigation and Stream Deck HUD"
        onKeyDown={(e) => {
          if (!isExpanded && (e.key === 'Enter' || e.key === ' ')) {
            e.preventDefault();
            handleToggleExpand();
          }
        }}
        onClick={!isExpanded ? handleToggleExpand : undefined}
      >
        {/* Collapsed State: Hardware Notch with Navigation & Drag Grip */}
        {!isExpanded && (
          <div className="w-full h-full px-3 flex items-center justify-between">
            {/* Left: Drag Grip Handle */}
            <div className="flex items-center gap-1.5" title="Drag notch to reposition anywhere">
              <div className="flex flex-col gap-0.5 opacity-40 hover:opacity-100 transition-opacity">
                <span className="w-1 h-1 rounded-full bg-white/70" />
                <span className="w-1 h-1 rounded-full bg-white/70" />
              </div>
              <div
                className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0"
                title="FaceTime Camera Cutout"
              >
                <div className="w-1 h-1 rounded-full bg-[#1b253b] opacity-80" />
              </div>
            </div>

            {/* Center: Brand & Navigation Indicator */}
            <span className="text-[11px] font-semibold text-white/90 tracking-tight">
              macdeck <span className="text-white/40 text-[9px] font-mono">menu</span>
            </span>

            {/* Right: Quick Action Pill */}
            <div className="flex items-center gap-1 bg-white/10 px-1.5 py-0.5 rounded-full border border-white/10 text-[9.5px] font-bold text-white/90">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
              <span>HUD</span>
            </div>
          </div>
        )}

        {/* Expanded State: Full Navigation + 6-Slot Liquid Glass HUD */}
        {isExpanded && (
          <div className="p-4 sm:p-5 flex flex-col gap-4">
            {/* Header: Draggable Grip Bar & Primary Navigation */}
            <div className="flex items-center justify-between pb-3 border-b border-white/10">
              <div className="flex items-center gap-2">
                {/* Drag Handle Bar */}
                <div
                  className="flex items-center gap-1 py-1 px-1.5 rounded bg-white/10 text-white/60 cursor-grab active:cursor-grabbing text-[10px] font-mono"
                  title="Drag anywhere"
                >
                  <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="9" cy="6" r="1.5" fill="currentColor" />
                    <circle cx="15" cy="6" r="1.5" fill="currentColor" />
                    <circle cx="9" cy="12" r="1.5" fill="currentColor" />
                    <circle cx="15" cy="12" r="1.5" fill="currentColor" />
                    <circle cx="9" cy="18" r="1.5" fill="currentColor" />
                    <circle cx="15" cy="18" r="1.5" fill="currentColor" />
                  </svg>
                  <span className="text-[9px]">Drag</span>
                </div>

                {/* Device Status */}
                <div className="flex items-center gap-1.5 text-xs font-semibold text-white/90">
                  <span className="w-2 h-2 rounded-full bg-emerald-400" />
                  <span>MacDeck</span>
                </div>
              </div>

              {/* Integrated Navigation Links */}
              <nav className="flex items-center gap-3 sm:gap-4 text-xs font-medium" aria-label="Notch Navigation">
                {NAV_LINKS.map((link) => (
                  <a
                    key={link.href}
                    href={link.href}
                    onClick={() => setIsExpanded(false)}
                    className="text-white/70 hover:text-white transition-colors"
                  >
                    {link.label}
                  </a>
                ))}
              </nav>

              {/* Close Button */}
              <button
                type="button"
                onClick={() => setIsExpanded(false)}
                className="w-6 h-6 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-colors"
                aria-label="Collapse Notch HUD"
              >
                <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <line x1="18" y1="6" x2="6" y2="18" />
                  <line x1="6" y1="6" x2="18" y2="18" />
                </svg>
              </button>
            </div>

            {/* 6-Slot App Configurator Grid (3x2) */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-[11px] font-semibold text-white/50 tracking-wider uppercase font-mono">
                  Stream Deck Slots (Synced to Phone)
                </span>
                <button
                  type="button"
                  onClick={handleReset}
                  className="text-[10px] text-white/60 hover:text-white transition-colors font-mono"
                >
                  Reset Defaults
                </button>
              </div>

              <div className="grid grid-cols-3 gap-2.5">
                {activeSlots.slice(0, 6).map((slot) => {
                  const isEmpty = slot.isEmpty;

                  if (isEmpty) {
                    return (
                      <button
                        key={slot.index}
                        type="button"
                        onClick={() => setSelectedSlotIndex(slot.index)}
                        className="h-16 rounded-[14px] border border-dashed border-white/20 bg-white/[0.02] hover:bg-white/[0.08] hover:border-cyan-400/60 transition-all flex flex-col items-center justify-center gap-1 group text-center cursor-pointer"
                      >
                        <div className="w-5 h-5 rounded-full border border-white/40 flex items-center justify-center text-white/60 group-hover:border-cyan-400 group-hover:text-cyan-300">
                          <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                            <line x1="12" y1="5" x2="12" y2="19" />
                            <line x1="5" y1="12" x2="19" y2="12" />
                          </svg>
                        </div>
                        <span className="text-[10px] font-mono text-white/50 group-hover:text-white/80">
                          Slot {slot.index + 1}
                        </span>
                      </button>
                    );
                  }

                  return (
                    <div
                      key={slot.index}
                      className="relative h-16 rounded-[14px] border border-white/15 bg-white/[0.05] p-2 flex items-center gap-2.5 group hover:bg-white/[0.09] transition-all"
                    >
                      {/* App Icon */}
                      <div className="w-9 h-9 rounded-[8px] overflow-hidden shrink-0">
                        <AppIconRenderer iconType={slot.iconType} label={slot.label} />
                      </div>

                      {/* App Details */}
                      <div className="flex-1 min-w-0 flex flex-col">
                        <span className="text-xs font-semibold text-white/95 truncate">
                          {slot.label}
                        </span>
                        <span className="text-[9.5px] font-mono text-white/40">
                          Slot {slot.index + 1}
                        </span>
                      </div>

                      {/* Remove / Clear Badge */}
                      <button
                        type="button"
                        onClick={(e) => handleClearSlot(slot, e)}
                        className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-[#181D2A] border border-rose-500/80 text-rose-300 hover:bg-rose-600 hover:text-white flex items-center justify-center shadow-md transition-all cursor-pointer opacity-90 group-hover:opacity-100"
                        title="Clear Slot"
                        aria-label={`Clear slot ${slot.index + 1}`}
                      >
                        <svg className="w-2.5 h-2.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                          <line x1="5" y1="12" x2="19" y2="12" />
                        </svg>
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* App Assignment Drawer */}
            <AnimatePresence>
              {selectedSlotIndex !== null && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  className="pt-2 border-t border-white/10 flex flex-col gap-2"
                >
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-mono text-cyan-300">
                      Select App for Slot {selectedSlotIndex + 1}:
                    </span>
                    <button
                      type="button"
                      onClick={() => setSelectedSlotIndex(null)}
                      className="text-[10px] text-white/40 hover:text-white"
                    >
                      Cancel
                    </button>
                  </div>

                  <div className="grid grid-cols-4 gap-1.5">
                    {AVAILABLE_MAC_APPS.map((app) => (
                      <button
                        key={app.bundleId}
                        type="button"
                        onClick={() => handleSelectApp(app)}
                        className="flex items-center gap-1.5 p-1.5 rounded-lg bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 transition-colors text-left cursor-pointer"
                      >
                        <div className="w-5 h-5 rounded overflow-hidden shrink-0">
                          <AppIconRenderer iconType={app.iconType} label={app.label} />
                        </div>
                        <span className="text-[10.5px] font-medium text-white/90 truncate">
                          {app.label}
                        </span>
                      </button>
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Status Feedback Toast */}
            {statusNotification && (
              <div className="text-center text-[10px] font-mono text-cyan-300 bg-cyan-950/40 border border-cyan-800/40 rounded-full py-1 px-3 self-center">
                {statusNotification}
              </div>
            )}
          </div>
        )}
      </motion.div>
    </div>
  );
}
