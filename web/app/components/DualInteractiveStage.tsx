'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { DeckSlotItem, OrientationMode } from '../types/deck';
import PhoneDeckMockup from './PhoneDeckMockup';
import DesktopNotchMockup, { ActionExecution } from './DesktopNotchMockup';

export interface DualInteractiveStageProps {
  slots?: DeckSlotItem[];
  onSlotsChange?: (slots: DeckSlotItem[]) => void;
  className?: string;
}

export const DEFAULT_STAGE_SLOTS: DeckSlotItem[] = [
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

interface WirePacket {
  id: string;
  direction: 'phone-to-mac' | 'mac-to-phone';
  type: string;
  payload: string;
  latency: string;
  timestamp: number;
}

export default function DualInteractiveStage({
  slots: controlledSlots,
  onSlotsChange,
  className = '',
}: DualInteractiveStageProps) {
  const [internalSlots, setInternalSlots] = useState<DeckSlotItem[]>(
    controlledSlots ?? DEFAULT_STAGE_SLOTS
  );
  const activeSlots = controlledSlots ?? internalSlots;

  const [lastActionExecution, setLastActionExecution] = useState<ActionExecution | null>(null);
  const [activePhoneSlotId, setActivePhoneSlotId] = useState<string | null>(null);
  const [phoneOrientation, setPhoneOrientation] = useState<OrientationMode>('portrait');
  const [packetCount, setPacketCount] = useState<number>(0);
  const [activePacket, setActivePacket] = useState<WirePacket | null>(null);
  const [isWireActive, setIsWireActive] = useState<boolean>(false);

  const packetTimerRef = useRef<NodeJS.Timeout | null>(null);
  const activeSlotTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    return () => {
      if (packetTimerRef.current) clearTimeout(packetTimerRef.current);
      if (activeSlotTimerRef.current) clearTimeout(activeSlotTimerRef.current);
    };
  }, []);

  // Sync internal state when external controlledSlots change
  useEffect(() => {
    if (controlledSlots) {
      setInternalSlots(controlledSlots);
    }
  }, [controlledSlots]);

  // Window broadcast listener for cross-component synchronisation with TopNotchIsland
  useEffect(() => {
    const handleBroadcast = (event: Event) => {
      const customEvent = event as CustomEvent<DeckSlotItem[]>;
      if (!controlledSlots && Array.isArray(customEvent.detail)) {
        setInternalSlots(customEvent.detail);
      }
    };
    window.addEventListener('notchdeck-slots-sync', handleBroadcast);
    window.addEventListener('macdeck-slots-sync', handleBroadcast);
    return () => {
      window.removeEventListener('notchdeck-slots-sync', handleBroadcast);
      window.removeEventListener('macdeck-slots-sync', handleBroadcast);
    };
  }, [controlledSlots]);

  useEffect(() => {
    return () => {
      if (packetTimerRef.current) clearTimeout(packetTimerRef.current);
    };
  }, []);

  const broadcastSlots = (updated: DeckSlotItem[]) => {
    window.dispatchEvent(new CustomEvent('notchdeck-slots-sync', { detail: updated }));
    window.dispatchEvent(new CustomEvent('macdeck-slots-sync', { detail: updated }));
    if (onSlotsChange) {
      onSlotsChange(updated);
    }
  };

  const triggerWirePacket = (packet: Omit<WirePacket, 'id' | 'timestamp'>) => {
    const newPacket: WirePacket = {
      ...packet,
      id: `pkt-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
      timestamp: Date.now(),
    };
    setActivePacket(newPacket);
    setIsWireActive(true);
    setPacketCount((prev) => prev + 1);

    if (packetTimerRef.current) clearTimeout(packetTimerRef.current);
    packetTimerRef.current = setTimeout(() => {
      setIsWireActive(false);
    }, 2400);
  };

  // Triggered when user taps an app tile on the Phone
  const handlePhoneTriggerSlot = (slot: DeckSlotItem) => {
    if (slot.isEmpty || !slot.bundleId) return;

    setActivePhoneSlotId(slot.id);
    const execution: ActionExecution = {
      label: slot.label,
      bundleId: slot.bundleId,
      timestamp: Date.now(),
    };
    setLastActionExecution(execution);

    triggerWirePacket({
      direction: 'phone-to-mac',
      type: 'ACTION_INVOKE',
      payload: JSON.stringify({
        cmd: 'launch_application',
        bundleId: slot.bundleId,
        slotIndex: slot.index,
        label: slot.label,
      }),
      latency: '0.8ms',
    });

    if (activeSlotTimerRef.current) clearTimeout(activeSlotTimerRef.current);
    activeSlotTimerRef.current = setTimeout(() => {
      setActivePhoneSlotId(null);
    }, 240);
  };

  // Triggered when user clears a slot in Desktop Notch HUD
  const handleClearSlot = (slot: DeckSlotItem) => {
    const updated = activeSlots.map((s) =>
      s.index === slot.index ? { ...s, label: '', bundleId: '', isEmpty: true } : s
    );
    if (!controlledSlots) {
      setInternalSlots(updated);
    }
    broadcastSlots(updated);

    triggerWirePacket({
      direction: 'mac-to-phone',
      type: 'CONFIG_SYNC (CLEAR)',
      payload: JSON.stringify({
        event: 'CLEAR_SLOT',
        index: slot.index,
      }),
      latency: '0.6ms',
    });
  };

  // Triggered when user assigns an app to a slot in Desktop Notch HUD
  const handleAssignSlot = (index: number, app: Partial<DeckSlotItem>) => {
    const updated = [...activeSlots];
    updated[index] = {
      id: `app-${index + 1}`,
      index,
      label: app.label || '',
      bundleId: app.bundleId || '',
      iconType: app.iconType || 'terminal',
      isEmpty: false,
    };
    if (!controlledSlots) {
      setInternalSlots(updated);
    }
    broadcastSlots(updated);

    triggerWirePacket({
      direction: 'mac-to-phone',
      type: 'CONFIG_SYNC (ASSIGN)',
      payload: JSON.stringify({
        event: 'ASSIGN_SLOT',
        index,
        bundleId: app.bundleId,
        label: app.label,
      }),
      latency: '0.6ms',
    });
  };

  // Triggered when defaults are reset
  const handleResetDefaults = () => {
    if (!controlledSlots) {
      setInternalSlots(DEFAULT_STAGE_SLOTS);
    }
    broadcastSlots(DEFAULT_STAGE_SLOTS);

    triggerWirePacket({
      direction: 'mac-to-phone',
      type: 'PROFILE_RESTORE',
      payload: JSON.stringify({
        event: 'RESTORE_DEFAULT_PROFILE',
        slotCount: 6,
      }),
      latency: '0.7ms',
    });
  };

  const handleToggleOrientation = () => {
    setPhoneOrientation((prev) => (prev === 'portrait' ? 'landscape' : 'portrait'));
  };

  return (
    <section className={`w-full py-10 ${className}`}>
      {/* Interactive Controls & Wire Telemetry Header */}
      <div className="w-full max-w-6xl mx-auto px-4 mb-6">
        <div className="bg-[#10141e] border border-[#222a3a] rounded-2xl p-4 shadow-lg flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          {/* Core Wire Indicator (Brief Specification Match) */}
          <div className="flex flex-col gap-1">
            <div className="flex items-center gap-2">
              <div
                className={`w-2 h-2 rounded-full transition-colors ${
                  isWireActive ? 'bg-cyan-400' : 'bg-emerald-400'
                }`}
              />
              <span className="text-xs font-semibold text-white tracking-wide">
                USB Reverse ADB Tunnel • ws://127.0.0.1:8765 • 0.8ms latency
              </span>
            </div>
            <div className="text-[11px] text-white/50 font-mono flex items-center gap-3">
              <span>Transport: USB 3.1 Type-C Loopback</span>
              <span className="hidden sm:inline">•</span>
              <span className="hidden sm:inline">Frames Dispatched: {packetCount}</span>
            </div>
          </div>

          {/* Quick Simulation Controls */}
          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={handleToggleOrientation}
              className="text-xs px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-white/80 transition-colors flex items-center gap-1.5"
            >
              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <rect x="5" y="2" width="14" height="20" rx="2" />
                <path d="M12 18h.01" />
              </svg>
              <span>{phoneOrientation === 'portrait' ? 'View Landscape' : 'View Portrait'}</span>
            </button>

            <button
              type="button"
              onClick={handleResetDefaults}
              className="text-xs px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 border border-white/10 text-white/80 transition-colors"
            >
              Reset 6 Slots
            </button>
          </div>
        </div>

        {/* Live Packet Telemetry Drawer */}
        <AnimatePresence>
          {activePacket && (
            <motion.div
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -6 }}
              transition={{ duration: 0.2 }}
              className="mt-2 bg-[#090c13] border border-cyan-500/30 rounded-xl px-3.5 py-2 flex flex-col sm:flex-row sm:items-center justify-between gap-2 shadow-inner"
            >
              <div className="flex items-center gap-2.5 overflow-hidden">
                <span
                  className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded border shrink-0 ${
                    activePacket.direction === 'phone-to-mac'
                      ? 'bg-blue-950/80 text-blue-300 border-blue-700/50'
                      : 'bg-emerald-950/80 text-emerald-300 border-emerald-700/50'
                  }`}
                >
                  {activePacket.direction === 'phone-to-mac'
                    ? 'TX → RX (Android → Mac)'
                    : 'RX ← TX (Mac → Android)'}
                </span>
                <span className="text-[11px] font-mono text-cyan-300 truncate">
                  [{activePacket.type}] {activePacket.payload}
                </span>
              </div>
              <span className="text-[10px] font-mono text-white/40 shrink-0 self-end sm:self-auto">
                RTT: {activePacket.latency}
              </span>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Side-by-Side Live Devices Stage */}
      <div className="w-full max-w-7xl mx-auto px-4">
        <div className="flex flex-col xl:flex-row items-center justify-center gap-8 xl:gap-10">
          {/* Left Device: Android Phone Mockup (Client) */}
          <div className="flex flex-col items-center w-full max-w-[calc(100vw-32px)] sm:max-w-none">
            <div className="w-full flex items-center justify-between pb-2.5 px-2">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="text-xs font-semibold text-[#101828]">
                  Android Deck Client
                </span>
              </div>
              <span className="text-[11px] text-[#475467] font-mono">
                Jetpack Compose
              </span>
            </div>

            <PhoneDeckMockup
              slots={activeSlots}
              onTriggerSlot={handlePhoneTriggerSlot}
              activeSlotId={activePhoneSlotId}
              orientation={phoneOrientation}
              onToggleOrientation={handleToggleOrientation}
              showOrientationControl={false}
              className="shadow-2xl"
            />

            <div className="mt-3 text-center text-xs text-[#475467]">
              Tap any tile to dispatch action across the USB bridge
            </div>
          </div>

          {/* Central Physical Bridge Wire (Visible on Desktop) */}
          <div className="hidden xl:flex flex-col items-center justify-center py-10 w-16">
            <div className="w-[2px] h-20 bg-[#222a3a] relative overflow-hidden">
              {isWireActive && (
                <motion.div
                  initial={{ y: activePacket?.direction === 'phone-to-mac' ? -20 : 80 }}
                  animate={{ y: activePacket?.direction === 'phone-to-mac' ? 80 : -20 }}
                  transition={{ duration: 0.6, repeat: 1, ease: 'linear' }}
                  className="w-full h-5 bg-cyan-300 shadow-sm"
                />
              )}
            </div>
            <div className="my-2 p-1.5 rounded-full bg-[#10141e] border border-[#222a3a] text-white/70">
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="7 13 12 18 17 13" />
                <polyline points="7 6 12 11 17 6" />
              </svg>
            </div>
            <div className="w-[2px] h-20 bg-[#222a3a]" />
          </div>

          {/* Right Device: macOS Desktop Mockup (Host + NotchDeck HUD) */}
          <div className="flex flex-col items-center w-full max-w-[660px]">
            <div className="w-full flex items-center justify-between pb-2.5 px-2">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-emerald-500" />
                <span className="text-xs font-semibold text-[#101828]">
                  macOS Host Simulator
                </span>
              </div>
              <span className="text-[11px] text-[#475467] font-mono">
                AppKit Daemon + NotchDeck
              </span>
            </div>

            <DesktopNotchMockup
              slots={activeSlots}
              onClearSlot={handleClearSlot}
              onAssignSlot={handleAssignSlot}
              onResetDefaults={handleResetDefaults}
              lastActionExecution={lastActionExecution}
              className="w-full shadow-2xl"
            />

            <div className="mt-3 text-center text-xs text-[#475467]">
              Hover over a slot in NotchDeck to clear (-) or click to reassign
            </div>
          </div>
        </div>
      </div>

      {/* Explanatory Caption Under the Stage Explaining Architecture */}
      <div className="w-full max-w-5xl mx-auto px-4 mt-14">
        <div className="bg-white border border-[#e5e9f2] rounded-2xl p-6 sm:p-8 shadow-sm">
          <div className="border-b border-[#e5e9f2] pb-4 mb-6">
            <h3 className="text-base sm:text-lg font-bold text-[#101828] tracking-tight">
              Hardware-Direct Protocol Architecture
            </h3>
            <p className="text-xs sm:text-sm text-[#475467] mt-1">
              Deterministic sub-millisecond execution over physical USB reverse socket tunneling
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Pillar 1: ADB Reverse Tunnel */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[#101828] text-white flex items-center justify-center font-mono text-xs font-bold shrink-0">
                  01
                </div>
                <h4 className="text-xs sm:text-sm font-semibold text-[#101828]">
                  USB Reverse ADB Tunnel
                </h4>
              </div>
              <p className="text-xs text-[#475467] leading-relaxed">
                A single command creates a bidirectional TCP proxy between macOS loopback and the Android handset. Packets travel over high-speed USB 3.1 Type-C at 10 Gbps with no router hops, zero Wi-Fi packet drop, and zero cloud dependency.
              </p>
            </div>

            {/* Pillar 2: Native AppKit Daemon */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[#101828] text-white flex items-center justify-center font-mono text-xs font-bold shrink-0">
                  02
                </div>
                <h4 className="text-xs sm:text-sm font-semibold text-[#101828]">
                  Native AppKit Execution
                </h4>
              </div>
              <p className="text-xs text-[#475467] leading-relaxed">
                The lightweight Swift daemon binds to 127.0.0.1:8765, parsing touch payloads into direct NSWorkspace application activations and AppleScript keystrokes in under 0.8 milliseconds, without electron or browser overhead.
              </p>
            </div>

            {/* Pillar 3: Bidirectional HUD Sync */}
            <div className="flex flex-col gap-2">
              <div className="flex items-center gap-2">
                <div className="w-6 h-6 rounded-md bg-[#101828] text-white flex items-center justify-center font-mono text-xs font-bold shrink-0">
                  03
                </div>
                <h4 className="text-xs sm:text-sm font-semibold text-[#101828]">
                  Real-Time Notch Synchronization
                </h4>
              </div>
              <p className="text-xs text-[#475467] leading-relaxed">
                Profile edits performed inside the liquid-glass macOS NotchDeck HUD are framed into compact binary JSON packets and pushed downstream across the socket. The Android Jetpack Compose deck updates immediately with zero layout flicker.
              </p>
            </div>
          </div>

          {/* Wire Protocol Specifications */}
          <div className="mt-6 pt-4 border-t border-[#f2f4f7] flex flex-wrap items-center justify-between gap-3 text-[11px] font-mono text-[#475467]">
            <div className="flex items-center gap-2">
              <span className="text-[#98a2b3]">TUNNEL:</span>
              <span className="text-[#101828] font-semibold">adb reverse tcp:8765 tcp:8765</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[#98a2b3]">SOCKET:</span>
              <span className="text-[#101828] font-semibold">ws://127.0.0.1:8765</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-[#98a2b3]">BENCHMARK LATENCY:</span>
              <span className="text-[#039855] font-semibold">&lt; 0.8 ms</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
