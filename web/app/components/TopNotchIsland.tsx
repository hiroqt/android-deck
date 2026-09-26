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

export default function TopNotchIsland({
  slots: controlledSlots,
  onClearSlot,
  onAssignSlot,
  onResetDefaults,
  className = '',
}: TopNotchIslandProps) {
  const [internalSlots, setInternalSlots] = useState<DeckSlotItem[]>(controlledSlots ?? DEFAULT_NOTCH_SLOTS);
  const activeSlots = controlledSlots ?? internalSlots;

  const [isExpanded, setIsExpanded] = useState<boolean>(false);
  const [selectedSlotIndex, setSelectedSlotIndex] = useState<number | null>(null);
  const [statusNotification, setStatusNotification] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const notificationTimeoutRef = useRef<NodeJS.Timeout | null>(null);

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

  // Window broadcast listener for external HUD toggle actions (e.g. SiteHeader)
  useEffect(() => {
    const handleToggle = () => {
      setIsExpanded((prev) => !prev);
      setSelectedSlotIndex(null);
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
    setIsExpanded((prev) => !prev);
    setSelectedSlotIndex(null);
  };

  const handleClearSlot = (slot: DeckSlotItem, e: React.MouseEvent) => {
    e.stopPropagation();
    if (onClearSlot) {
      onClearSlot(slot);
    } else {
      const updated = activeSlots.map((s) =>
        s.index === slot.index ? { ...s, label: '', bundleId: '', isEmpty: true } : s
      );
      setInternalSlots(updated);
      broadcastSlots(updated);
    }
    showStatus(`Slot ${slot.index + 1} cleared`);
  };

  const handleAssignApp = (app: (typeof AVAILABLE_MAC_APPS)[0]) => {
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

    if (onAssignSlot) {
      onAssignSlot(targetIndex, updatedItem);
    } else {
      const updated = [...activeSlots];
      updated[targetIndex] = {
        id: `app-${targetIndex + 1}`,
        index: targetIndex,
        label: app.label,
        bundleId: app.bundleId,
        iconType: app.iconType,
        isEmpty: false,
      };
      setInternalSlots(updated);
      broadcastSlots(updated);
    }

    setSelectedSlotIndex(null);
    showStatus(`Slot ${targetIndex + 1} set to ${app.label}`);
  };

  const handleResetDefaults = () => {
    if (onResetDefaults) {
      onResetDefaults();
    } else {
      setInternalSlots(DEFAULT_NOTCH_SLOTS);
      broadcastSlots(DEFAULT_NOTCH_SLOTS);
    }
    showStatus('Default 6-slot profile restored');
  };

  // Ensure full 6-slot array for display
  const displaySlots: DeckSlotItem[] = [];
  for (let i = 0; i < 6; i++) {
    const existing = activeSlots.find((s) => s.index === i);
    if (existing) {
      displaySlots.push(existing);
    } else {
      displaySlots.push({
        id: `app-${i + 1}`,
        index: i,
        label: '',
        bundleId: '',
        iconType: 'terminal',
        isEmpty: true,
      });
    }
  }

  return (
    <div
      ref={containerRef}
      className={`fixed top-0 left-1/2 -translate-x-1/2 z-50 select-none ${className}`}
    >
      <motion.div
        layout
        transition={{
          type: 'spring',
          damping: 28,
          stiffness: 340,
          mass: 0.8,
        }}
        className={`bg-black text-white shadow-2xl overflow-hidden border-x border-b border-white/15 ${
          isExpanded
            ? 'w-[540px] max-w-[95vw] rounded-b-[22px] bg-[#0c1017]/95 backdrop-blur-2xl'
            : 'w-[184px] h-[32px] rounded-b-[16px] cursor-pointer hover:bg-[#11141d] active:scale-[0.99] focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400'
        }`}
        role={!isExpanded ? 'button' : undefined}
        tabIndex={!isExpanded ? 0 : undefined}
        aria-expanded={isExpanded}
        aria-label="Toggle NotchDeck HUD"
        onKeyDown={(e) => {
          if (!isExpanded && (e.key === 'Enter' || e.key === ' ')) {
            e.preventDefault();
            handleToggleExpand();
          }
        }}
        onClick={!isExpanded ? handleToggleExpand : undefined}
      >
        {/* Collapsed State */}
        {!isExpanded && (
          <div className="w-full h-full px-3 flex items-center justify-between">
            {/* Camera Lens Indicator */}
            <div
              className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0"
              title="Built-in FaceTime HD Camera"
            >
              <div className="w-1 h-1 rounded-full bg-[#050810]" />
            </div>

            {/* Status text */}
            <span className="text-[10px] font-medium tracking-tight text-white/90">
              MacDeck: USB Active
            </span>

            {/* Solid Connection Dot */}
            <div
              className="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0"
              title="Reverse ADB Socket connected (127.0.0.1:8765)"
            />
          </div>
        )}

        {/* Expanded State: 6-Slot NotchDeck HUD */}
        {isExpanded && (
          <div className="flex flex-col">
            {/* Header bar */}
            <div className="h-10 px-4 flex items-center justify-between border-b border-white/10">
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-[#111622] border border-[#232b3e] flex items-center justify-center shrink-0">
                  <div className="w-1 h-1 rounded-full bg-[#050810]" />
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="text-[11px] font-semibold text-white tracking-tight">
                    NotchDeck HUD
                  </span>
                  <span className="text-[9.5px] font-mono text-emerald-400 bg-emerald-950/60 px-1.5 py-0.5 rounded border border-emerald-800/40">
                    127.0.0.1:8765
                  </span>
                </div>
              </div>

              {/* Status Message or Controls */}
              <div className="flex items-center gap-1.5">
                {statusNotification && (
                  <span className="text-[10px] text-white/60 font-mono pr-1 truncate max-w-[140px]">
                    {statusNotification}
                  </span>
                )}

                {/* Reset button */}
                <button
                  type="button"
                  onClick={handleResetDefaults}
                  title="Reset slots to defaults"
                  className="w-6 h-6 rounded flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-colors"
                >
                  <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />
                    <path d="M3 3v5h5" />
                  </svg>
                </button>

                {/* Collapse button */}
                <button
                  type="button"
                  onClick={handleToggleExpand}
                  title="Collapse Notch HUD"
                  className="w-6 h-6 rounded flex items-center justify-center text-white/70 hover:text-white hover:bg-white/10 transition-colors"
                >
                  <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="18 15 12 9 6 15" />
                  </svg>
                </button>
              </div>
            </div>

            {/* Sub-header profile label */}
            <div className="px-4 py-1.5 flex items-center justify-between text-[9px] font-mono text-white/40">
              <span>PROFILE: STREAM_DECK_6SLOT</span>
              <span>SYNCHRONIZED WITH ANDROID</span>
            </div>

            {/* 3×2 Slot Grid */}
            <div className="px-4 pb-3.5 pt-1 grid grid-cols-3 gap-2">
              {displaySlots.map((slot) => {
                const isEmpty = slot.isEmpty || !slot.label;
                return (
                  <div key={slot.id || `notch-slot-${slot.index}`} className="relative group">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedSlotIndex(slot.index);
                      }}
                      className={`w-full h-[68px] rounded-[12px] p-1.5 flex flex-col items-center justify-center transition-all ${
                        isEmpty
                          ? 'bg-white/[0.03] hover:bg-white/[0.08] border border-dashed border-white/20 hover:border-cyan-400/60'
                          : 'bg-white/[0.05] hover:bg-white/[0.10] active:scale-[0.98] border border-white/15 hover:border-white/30 shadow-md'
                      }`}
                    >
                      {isEmpty ? (
                        <div className="flex flex-col items-center justify-center gap-1">
                          <svg className="w-3.5 h-3.5 text-white/40 group-hover:text-cyan-400 transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                            <line x1="12" y1="5" x2="12" y2="19" />
                            <line x1="5" y1="12" x2="19" y2="12" />
                          </svg>
                          <span className="text-[9px] font-medium text-white/40 group-hover:text-white/80 transition-colors">
                            Slot {slot.index + 1}
                          </span>
                        </div>
                      ) : (
                        <div className="flex flex-col items-center justify-center gap-1 w-full">
                          <div className="w-7 h-7 rounded-[6px] overflow-hidden flex items-center justify-center shrink-0">
                            <AppIconRenderer iconType={slot.iconType} label={slot.label} />
                          </div>
                          <span className="text-[10px] font-medium text-white/90 group-hover:text-white truncate max-w-[110px] tracking-tight">
                            {slot.label}
                          </span>
                        </div>
                      )}
                    </button>

                    {/* Clear Button (-) on hover */}
                    {!isEmpty && (
                      <button
                        type="button"
                        onClick={(e) => handleClearSlot(slot, e)}
                        title={`Clear Slot ${slot.index + 1}`}
                        className="absolute top-1 right-1 w-4 h-4 rounded-full bg-[#f23f43] text-white flex items-center justify-center shadow-md opacity-0 group-hover:opacity-100 transition-opacity hover:scale-110 active:scale-95 z-10"
                      >
                        <svg className="w-2.5 h-2.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
                          <line x1="5" y1="12" x2="19" y2="12" />
                        </svg>
                      </button>
                    )}
                  </div>
                );
              })}
            </div>

            {/* App Assignment Drawer */}
            <AnimatePresence>
              {selectedSlotIndex !== null && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  transition={{ duration: 0.18 }}
                  className="mx-4 mb-3 p-2.5 rounded-[12px] bg-[#141924] border border-white/20 shadow-xl overflow-hidden"
                >
                  <div className="flex items-center justify-between pb-2 border-b border-white/10">
                    <span className="text-[10.5px] font-medium text-white">
                      Assign to Slot {selectedSlotIndex + 1}
                    </span>
                    <button
                      type="button"
                      onClick={() => setSelectedSlotIndex(null)}
                      className="text-white/50 hover:text-white text-[11px] px-1"
                    >
                      Close
                    </button>
                  </div>

                  <div className="grid grid-cols-4 gap-1.5 pt-2">
                    {AVAILABLE_MAC_APPS.map((app) => (
                      <button
                        key={`island-app-${app.bundleId}`}
                        type="button"
                        onClick={() => handleAssignApp(app)}
                        className="p-1 rounded-lg bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 flex flex-col items-center gap-1 transition-all text-center group"
                      >
                        <div className="w-6 h-6 rounded-[5px] overflow-hidden shrink-0">
                          <AppIconRenderer iconType={app.iconType} label={app.label} />
                        </div>
                        <span className="text-[9px] font-medium text-white/80 group-hover:text-white truncate max-w-full">
                          {app.label}
                        </span>
                      </button>
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}
      </motion.div>
    </div>
  );
}
