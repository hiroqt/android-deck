'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { DeckSlotItem, DeckIconType } from '../types/deck';

export interface ActionExecution {
  label: string;
  bundleId: string;
  timestamp: number;
}

export interface DesktopNotchMockupProps {
  slots?: DeckSlotItem[];
  onClearSlot?: (slot: DeckSlotItem) => void;
  onAssignSlot?: (index: number, app: Partial<DeckSlotItem>) => void;
  onResetDefaults?: () => void;
  lastActionExecution?: ActionExecution | null;
  isExpanded?: boolean;
  onToggleExpanded?: () => void;
  className?: string;
}

export const AVAILABLE_MAC_APPS: {
  label: string;
  bundleId: string;
  iconType: DeckIconType;
  description: string;
}[] = [
  {
    label: 'Terminal',
    bundleId: 'com.apple.Terminal',
    iconType: 'terminal',
    description: 'macOS Command Line Interface',
  },
  {
    label: 'VS Code',
    bundleId: 'com.microsoft.VSCode',
    iconType: 'code',
    description: 'Code Editor & IDE',
  },
  {
    label: 'Safari',
    bundleId: 'com.apple.Safari',
    iconType: 'safari',
    description: 'Apple Web Browser',
  },
  {
    label: 'Finder',
    bundleId: 'com.apple.finder',
    iconType: 'finder',
    description: 'macOS File Manager',
  },
  {
    label: 'Settings',
    bundleId: 'com.apple.systempreferences',
    iconType: 'settings',
    description: 'System Preferences',
  },
  {
    label: 'Music',
    bundleId: 'com.apple.Music',
    iconType: 'music',
    description: 'Apple Music Audio Player',
  },
  {
    label: 'Slack',
    bundleId: 'com.tinyspeck.slackmacgap',
    iconType: 'slack',
    description: 'Team Chat & Messaging',
  },
  {
    label: 'Figma',
    bundleId: 'com.figma.Desktop',
    iconType: 'figma',
    description: 'Interface Design Application',
  },
];

const DEFAULT_SLOTS: DeckSlotItem[] = [
  {
    id: 'app-1',
    index: 0,
    label: 'VS Code',
    bundleId: 'com.microsoft.VSCode',
    iconType: 'code',
  },
  {
    id: 'app-2',
    index: 1,
    label: 'Terminal',
    bundleId: 'com.apple.Terminal',
    iconType: 'terminal',
  },
  {
    id: 'app-3',
    index: 2,
    label: 'Safari',
    bundleId: 'com.apple.Safari',
    iconType: 'safari',
  },
  {
    id: 'app-4',
    index: 3,
    label: 'Finder',
    bundleId: 'com.apple.finder',
    iconType: 'finder',
  },
  {
    id: 'app-5',
    index: 4,
    label: 'Settings',
    bundleId: 'com.apple.systempreferences',
    iconType: 'settings',
  },
  {
    id: 'app-6',
    index: 5,
    label: 'Music',
    bundleId: 'com.apple.Music',
    iconType: 'music',
  },
];

export function AppIconRenderer({ iconType, label }: { iconType: string; label: string }) {
  switch (iconType) {
    case 'terminal':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#181B22" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <path d="M13 18L20 24L13 30" stroke="#38BDF8" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
          <line x1="24" y1="30" x2="35" y2="30" stroke="#F1F5F9" strokeWidth="3" strokeLinecap="round" />
        </svg>
      );
    case 'code':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#1A1D27" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <path d="M35 11L25.8 19.4L18.8 14.1L12.5 18.2V29.8L18.8 33.9L25.8 28.6L35 37L37.5 35.5V12.5L35 11Z" fill="#0066B8" />
          <path d="M35 11L25.8 19.4L35 26.8L37.5 25.2V12.5L35 11Z" fill="#007ACC" />
          <path d="M35 37L25.8 28.6L18.8 33.9L12.5 29.8L15.2 27.8L25.8 35.5L35 37Z" fill="#1F8AD2" />
          <path d="M18.8 14.1L12.5 18.2L24.2 27.5L25.8 26.2L18.8 14.1Z" fill="#005A9E" />
          <path d="M35 11L37.5 12.5V35.5L35 37L25.8 29.5V18.5L35 11Z" fill="#29B6F6" />
        </svg>
      );
    case 'safari':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#1A1F2C" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <circle cx="24" cy="24" r="15" fill="#0071E3" />
          <circle cx="24" cy="24" r="13.5" stroke="rgba(255,255,255,0.35)" strokeWidth="1" strokeDasharray="2 2" />
          <polygon points="24,12 28,24 24,22 20,24" fill="#FF3B30" />
          <polygon points="24,36 28,24 24,26 20,24" fill="#FFFFFF" />
          <circle cx="24" cy="24" r="2" fill="#FFFFFF" />
        </svg>
      );
    case 'finder':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#181C26" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <g transform="translate(7.5, 7.5) scale(0.69)">
            <rect width="48" height="48" rx="10" fill="#45B0EC" />
            <path d="M24 0C37.25 0 48 10.75 48 24C48 37.25 37.25 48 24 48V0Z" fill="#1A67B6" />
            <path d="M24 8V28C24 30.5 22 32.5 19.5 32.5H18" stroke="#0F3A66" strokeWidth="2.5" strokeLinecap="round" />
            <circle cx="16" cy="20" r="3" fill="#0F3A66" />
            <circle cx="32" cy="20" r="3" fill="#0F3A66" />
            <path d="M14 36C18 41 30 41 34 36" stroke="#0F3A66" strokeWidth="2.5" strokeLinecap="round" />
          </g>
        </svg>
      );
    case 'settings':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#20242F" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <circle cx="24" cy="24" r="13" fill="#374151" />
          <path
            d="M24 13V16M24 32V35M13 24H16M32 24H35M16.2 16.2L18.4 18.4M29.6 29.6L31.8 31.8M16.2 31.8L18.4 29.6M29.6 18.4L31.8 16.2"
            stroke="#9CA3AF"
            strokeWidth="3"
            strokeLinecap="round"
          />
          <circle cx="24" cy="24" r="4.5" fill="#1F2430" stroke="#9CA3AF" strokeWidth="2" />
        </svg>
      );
    case 'music':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#FA2D48" />
          <path
            d="M31 14V27.5C30.1 27.2 29.1 27 28 27C24.7 27 22 29.2 22 32C22 34.8 24.7 37 28 37C31.3 37 34 34.8 34 32V19L20 22V29.5C19.1 29.2 18.1 29 17 29C13.7 29 11 31.2 11 34C11 36.8 13.7 39 17 39C20.3 39 23 36.8 23 34V16L31 14Z"
            fill="#FFFFFF"
          />
        </svg>
      );
    case 'slack':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#1C1F2B" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <g transform="translate(11, 11) scale(0.54)">
            <path d="M10.8 17.5C10.8 19.8 8.9 21.7 6.6 21.7C4.3 21.7 2.4 19.8 2.4 17.5C2.4 15.2 4.3 13.3 6.6 13.3H10.8V17.5Z" fill="#36C5F0" />
            <path d="M13.3 17.5C13.3 15.2 15.2 13.3 17.5 13.3C19.8 13.3 21.7 15.2 21.7 17.5V28.3C21.7 30.6 19.8 32.5 17.5 32.5C15.2 32.5 13.3 30.6 13.3 28.3V17.5Z" fill="#36C5F0" />
            <path d="M17.5 10.8C15.2 10.8 13.3 8.9 13.3 6.6C13.3 4.3 15.2 2.4 17.5 2.4C19.8 2.4 21.7 4.3 21.7 6.6V10.8H17.5Z" fill="#2EB67D" />
            <path d="M17.5 13.3C19.8 13.3 21.7 15.2 21.7 17.5C21.7 19.8 19.8 21.7 17.5 21.7H6.6C4.3 21.7 2.4 19.8 2.4 17.5C2.4 15.2 4.3 13.3 6.6 13.3H17.5Z" fill="#2EB67D" />
            <path d="M37.2 30.5C37.2 28.2 39.1 26.3 41.4 26.3C43.7 26.3 45.6 28.2 45.6 30.5C45.6 32.8 43.7 34.7 41.4 34.7H37.2V30.5Z" fill="#E01E5A" />
            <path d="M34.7 30.5C34.7 32.8 32.8 34.7 30.5 34.7C28.2 34.7 26.3 32.8 26.3 30.5V19.7C26.3 17.4 28.2 15.5 30.5 15.5C32.8 15.5 34.7 17.4 34.7 19.7V30.5Z" fill="#E01E5A" />
            <path d="M30.5 37.2C32.8 37.2 34.7 39.1 34.7 41.4C34.7 43.7 32.8 45.6 30.5 45.6C28.2 45.6 26.3 43.7 26.3 41.4V37.2H30.5Z" fill="#ECB22E" />
            <path d="M30.5 34.7C28.2 34.7 26.3 32.8 26.3 30.5C26.3 28.2 28.2 26.3 30.5 26.3H41.4C43.7 26.3 45.6 28.2 45.6 30.5C45.6 32.8 43.7 34.7 41.4 34.7H30.5Z" fill="#ECB22E" />
          </g>
        </svg>
      );
    case 'figma':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="10" fill="#181B24" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="9.5" stroke="#2B3245" strokeWidth="1" />
          <g transform="translate(13, 8) scale(0.68)">
            <path d="M8 0H16V16H8C3.58 16 0 12.42 0 8C0 3.58 3.58 0 8 0Z" fill="#F24E1E" />
            <path d="M16 0H24C28.42 0 32 3.58 32 8C32 12.42 28.42 16 24 16H16V0Z" fill="#FF7262" />
            <path d="M16 16H24C28.42 16 32 19.58 32 24C32 28.42 28.42 32 24 32C19.58 32 16 28.42 16 24V16Z" fill="#1ABCFE" />
            <path d="M8 32C12.42 32 16 28.42 16 24V32H8C3.58 32 0 35.58 0 40C0 44.42 3.58 48 8 48C12.42 48 16 44.42 16 40V32H8C3.58 32 0 28.42 0 24C0 19.58 3.58 16 8 16H16V24H8C3.58 24 0 27.58 0 32C0 36.42 3.58 40 8 40" fill="#0ACF83" />
            <path d="M8 16H16V32H8C3.58 32 0 28.42 0 24C0 19.58 3.58 16 8 16Z" fill="#A259FF" />
          </g>
        </svg>
      );
    default:
      return (
        <div className="w-full h-full rounded-[10px] bg-sky-500/20 border border-slate-700 flex items-center justify-center text-sky-400 font-bold text-sm">
          {label.slice(0, 1).toUpperCase()}
        </div>
      );
  }
}

export default function DesktopNotchMockup({
  slots: controlledSlots,
  onClearSlot,
  onAssignSlot,
  onResetDefaults,
  lastActionExecution = null,
  isExpanded: controlledIsExpanded,
  onToggleExpanded,
  className = '',
}: DesktopNotchMockupProps) {
  const [internalSlots, setInternalSlots] = useState<DeckSlotItem[]>(controlledSlots ?? DEFAULT_SLOTS);
  const activeSlots = controlledSlots ?? internalSlots;

  const [internalExpanded, setInternalExpanded] = useState<boolean>(true);
  const isExpanded = controlledIsExpanded !== undefined ? controlledIsExpanded : internalExpanded;

  const [selectedSlotIndex, setSelectedSlotIndex] = useState<number | null>(null);
  const [activeToast, setActiveToast] = useState<ActionExecution | null>(null);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const syncTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const toastTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Watch lastActionExecution changes
  useEffect(() => {
    if (lastActionExecution) {
      setActiveToast(lastActionExecution);
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
      toastTimeoutRef.current = setTimeout(() => {
        setActiveToast(null);
      }, 4500);
    }
    return () => {
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    };
  }, [lastActionExecution]);

  useEffect(() => {
    return () => {
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
      if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
    };
  }, []);


  const triggerWireSync = (msg: string) => {
    setSyncStatus(msg);
    if (syncTimeoutRef.current) clearTimeout(syncTimeoutRef.current);
    syncTimeoutRef.current = setTimeout(() => {
      setSyncStatus(null);
    }, 3200);
  };

  const handleToggleExpand = () => {
    if (onToggleExpanded) {
      onToggleExpanded();
    } else {
      setInternalExpanded((prev) => !prev);
    }
  };

  const handleRemoveSlot = (slot: DeckSlotItem, e: React.MouseEvent) => {
    e.stopPropagation();
    if (onClearSlot) {
      onClearSlot(slot);
    } else {
      setInternalSlots((prev) =>
        prev.map((s) =>
          s.index === slot.index
            ? { ...s, label: '', bundleId: '', isEmpty: true }
            : s
        )
      );
    }
    triggerWireSync(`Slot ${slot.index + 1} cleared (wire packet sync)`);
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

    if (onAssignSlot) {
      onAssignSlot(targetIndex, updatedItem);
    } else {
      setInternalSlots((prev) => {
        const next = [...prev];
        next[targetIndex] = {
          id: `app-${targetIndex + 1}`,
          index: targetIndex,
          label: app.label,
          bundleId: app.bundleId,
          iconType: app.iconType,
          isEmpty: false,
        };
        return next;
      });
    }

    setSelectedSlotIndex(null);
    triggerWireSync(`Slot ${targetIndex + 1} assigned: ${app.label}`);
  };

  const handleResetDefaults = () => {
    if (onResetDefaults) {
      onResetDefaults();
    } else {
      setInternalSlots(DEFAULT_SLOTS);
    }
    triggerWireSync('Profile restored to defaults (6 slots synced)');
  };

  // Ensure exactly 6 display items matching ExpandedDeckView.swift
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
    <div className={`relative w-full select-none ${className}`}>
      {/* Outer MacBook Display Frame with Aluminum Rim */}
      <div className="relative mx-auto w-full max-w-[690px] rounded-[22px] p-[9px] bg-[#1a1b22] border border-[#303440] shadow-2xl ring-1 ring-black/70">
        {/* Inner Screen Panel */}
        <div className="relative w-full aspect-[16/10] min-h-[430px] rounded-[14px] overflow-hidden bg-[#0a0d16] flex flex-col border border-white/5 shadow-inner">
          {/* macOS Desktop Wallpaper Background */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#0c1427] via-[#10182f] to-[#080b14]">
            {/* Ambient dusk gradient arcs */}
            <div className="absolute top-0 right-0 w-[380px] h-[320px] bg-indigo-600/10 rounded-full blur-3xl pointer-events-none" />
            <div className="absolute bottom-0 left-0 w-[420px] h-[280px] bg-blue-700/10 rounded-full blur-3xl pointer-events-none" />
          </div>

          {/* Top macOS Menu Bar */}
          <div className="relative w-full h-[30px] px-3.5 bg-black/40 backdrop-blur-md border-b border-white/10 flex items-center justify-between text-[11px] text-white/80 z-20">
            {/* Left Menu Items */}
            <div className="flex items-center gap-3.5">
              {/* Apple Logo */}
              <svg className="w-3.5 h-3.5 fill-white/90 cursor-default" viewBox="0 0 170 170">
                <path d="M150.37 130.25c-2.45 5.66-5.35 10.87-8.71 15.66-4.58 6.53-8.33 11.05-11.22 13.56-4.48 4.12-9.28 6.23-14.42 6.35-3.69 0-8.14-1.05-13.32-3.18-5.19-2.12-9.97-3.17-14.34-3.17-4.58 0-9.49 1.05-14.75 3.17-5.26 2.13-9.5 3.24-12.74 3.35-4.35.13-9.16-1.9-14.42-6.08-3.7-3.04-7.58-7.7-11.64-13.98-5.75-8.87-10.22-19.16-13.41-29.87-3.19-10.71-4.79-20.94-4.79-30.68 0-14.86 3.65-27.18 10.95-36.96 7.3-9.78 16.63-14.77 27.99-14.98 5.63.13 11.45 1.57 17.47 4.34 6.01 2.76 10.02 4.18 12.03 4.25 1.63 0 5.86-1.52 12.69-4.56 6.83-3.04 12.69-4.42 17.58-4.14 13.45.65 24.36 5.86 32.73 15.63-11.72 7.07-17.47 16.96-17.25 29.67.22 10 4.12 18.25 11.71 24.75 7.59 6.5 16.48 10.09 26.68 10.77-2.61 8.04-5.87 16.4-9.78 25.07zM119.22 31.84c0-7.39 2.66-14.32 7.98-20.78 5.32-6.46 11.95-10.51 19.89-12.16.87 7.61-1.63 14.76-7.5 21.45-5.87 6.69-12.65 10.73-20.37 12.13-.22-.22-.44-.43-.64-.64z" />
              </svg>
              <span className="font-semibold text-white tracking-tight">Finder</span>
              <span className="hidden sm:inline hover:text-white cursor-default">File</span>
              <span className="hidden sm:inline hover:text-white cursor-default">Edit</span>
              <span className="hidden sm:inline hover:text-white cursor-default">View</span>
              <span className="hidden md:inline hover:text-white cursor-default">Go</span>
              <span className="hidden md:inline hover:text-white cursor-default">Window</span>
              <span className="hidden md:inline hover:text-white cursor-default">Help</span>
            </div>

            {/* Right Status Menu Extras */}
            <div className="flex items-center gap-3">
              {/* Spotlight search */}
              <svg className="w-3.5 h-3.5 text-white/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="7" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              {/* Control Center */}
              <svg className="w-3.5 h-3.5 text-white/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                <line x1="4" y1="8" x2="20" y2="8" />
                <circle cx="8" cy="8" r="2.5" fill="currentColor" />
                <line x1="4" y1="16" x2="20" y2="16" />
                <circle cx="16" cy="16" r="2.5" fill="currentColor" />
              </svg>
              {/* Wi-Fi */}
              <svg className="w-3.5 h-3.5 text-white/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12.55a11 11 0 0 1 14.08 0" />
                <path d="M1.42 9a16 16 0 0 1 21.16 0" />
                <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
                <circle cx="12" cy="20" r="1" fill="currentColor" />
              </svg>
              {/* Battery Status */}
              <div className="flex items-center gap-1">
                <span className="text-[10px] font-medium text-white/80">100%</span>
                <svg className="w-4 h-2.5" viewBox="0 0 24 14" fill="none" stroke="currentColor" strokeWidth="1.6">
                  <rect x="1" y="1" width="18" height="12" rx="3" />
                  <path d="M21 5v4" strokeLinecap="round" />
                  <rect x="3" y="3" width="14" height="8" rx="1.5" fill="currentColor" />
                </svg>
              </div>
              {/* Clock */}
              <span className="text-[10.5px] font-medium tracking-tight text-white/90">Fri Sep 26 09:41 AM</span>
            </div>
          </div>

          {/* Centered Camera Notch and NotchDeck HUD */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 z-30 flex flex-col items-center">
            {/* The Hardware Notch Body */}
            <motion.div
              layout
              transition={{
                type: 'spring',
                stiffness: 380,
                damping: 28,
              }}
              className={`relative bg-black shadow-2xl transition-all border-x border-b border-white/10 ${
                isExpanded
                  ? 'w-[476px] max-w-[calc(100%-16px)] rounded-b-[22px] pb-4 bg-[#0a0c13]/95 backdrop-blur-2xl'
                  : 'w-[194px] h-[31px] rounded-b-[16px] px-3 flex items-center justify-between cursor-pointer hover:bg-[#11131a]'
              }`}
              onClick={!isExpanded ? handleToggleExpand : undefined}
            >
              {/* Top Camera Lens Dot and Microphone Hole */}
              <div className="absolute top-[3px] left-1/2 -translate-x-1/2 flex items-center gap-2 pointer-events-none">
                <div className="w-2.5 h-2.5 rounded-full bg-[#050608] border border-[#232733] flex items-center justify-center">
                  <div className="w-1 h-1 rounded-full bg-[#1b253b] opacity-80" />
                </div>
              </div>

              {!isExpanded ? (
                /* Collapsed Notch Bar View (CollapsedNotchView.swift) */
                <div className="w-full flex items-center justify-between pt-1">
                  {/* Left: Connection Status */}
                  <div className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    <span className="text-[10.5px] font-semibold text-white/90 tracking-tight">Deck</span>
                  </div>

                  {/* Right: Phone Battery */}
                  <div className="flex items-center gap-1 bg-white/10 px-1.5 py-0.5 rounded-full border border-white/10">
                    <svg className="w-2.5 h-2.5 text-white/80" viewBox="0 0 24 14" fill="none" stroke="currentColor" strokeWidth="2">
                      <rect x="1" y="1" width="18" height="12" rx="3" />
                      <path d="M21 5v4" strokeLinecap="round" />
                      <rect x="3" y="3" width="12" height="8" rx="1.5" fill="currentColor" />
                    </svg>
                    <span className="text-[9.5px] font-bold text-white/90">94%</span>
                  </div>
                </div>
              ) : (
                /* Expanded NotchDeck HUD (ExpandedDeckView.swift) */
                <div className="w-full flex flex-col pt-3">
                  {/* Header Bar */}
                  <div className="w-full px-5 flex items-center justify-between pb-2.5">
                    {/* Notch Deck Brand */}
                    <div className="flex items-center gap-1.5">
                      <svg className="w-3 h-3 text-cyan-400" viewBox="0 0 24 24" fill="currentColor">
                        <rect x="3" y="3" width="8" height="8" rx="2" />
                        <rect x="13" y="3" width="8" height="8" rx="2" />
                        <rect x="3" y="13" width="8" height="8" rx="2" />
                        <rect x="13" y="13" width="8" height="8" rx="2" />
                      </svg>
                      <span className="text-[11px] font-bold tracking-wider text-white/90 font-mono">
                        NOTCH DECK
                      </span>
                    </div>

                    {/* Center: Device Pill (Pixel 8 Pro • Connected • 94%) */}
                    <div className="flex items-center gap-1.5 bg-white/10 border border-white/15 px-2.5 py-1 rounded-full shadow-sm">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                      <svg className="w-2.5 h-3 text-white/90" viewBox="0 0 24 32" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="2" y="2" width="20" height="28" rx="4" />
                        <line x1="9" y1="6" x2="15" y2="6" />
                        <line x1="9" y1="26" x2="15" y2="26" />
                      </svg>
                      <span className="text-[10px] font-medium text-white tracking-tight">Pixel 8 Pro (Connected)</span>
                      <div className="flex items-center gap-0.5 text-emerald-400 pl-1 border-l border-white/20">
                        <svg className="w-2 h-2 fill-current" viewBox="0 0 24 24">
                          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
                        </svg>
                        <span className="text-[9.5px] font-bold text-white/90">94%</span>
                      </div>
                    </div>

                    {/* Right: Controls (Preset, Reset, Settings, Collapse) */}
                    <div className="flex items-center gap-2">
                      {/* Reset defaults */}
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

                      {/* Settings gear */}
                      <button
                        type="button"
                        onClick={() => triggerWireSync('Preferences: USB Daemon active on 127.0.0.1:8765')}
                        title="Preferences"
                        className="w-6 h-6 rounded flex items-center justify-center text-white/60 hover:text-white hover:bg-white/10 transition-colors"
                      >
                        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <circle cx="12" cy="12" r="3" />
                          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
                        </svg>
                      </button>

                      {/* Collapse chevron button */}
                      <button
                        type="button"
                        onClick={handleToggleExpand}
                        title="Collapse HUD"
                        className="w-6 h-6 rounded flex items-center justify-center text-white/70 hover:text-white hover:bg-white/10 transition-colors"
                      >
                        <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                          <polyline points="18 15 12 9 6 15" />
                        </svg>
                      </button>
                    </div>
                  </div>

                  {/* Profile Indicator */}
                  <div className="px-5 pb-2 flex items-center justify-between text-[9.5px] text-white/40">
                    <span className="font-medium tracking-wide uppercase">Profile: Standard Productivity</span>
                    <span className="font-mono">Sync Mode: Bidirectional</span>
                  </div>

                  {/* 3×2 Grid of macOS App Cards (DeckSlotCardView.swift) */}
                  <div className="px-5 grid grid-cols-3 gap-2.5">
                    {displaySlots.map((slot) => {
                      const isEmpty = slot.isEmpty || !slot.label;
                      return (
                        <div
                          key={slot.id || `slot-${slot.index}`}
                          className="relative group"
                        >
                          <button
                            type="button"
                            onClick={() => {
                              setSelectedSlotIndex(slot.index);
                            }}
                            className={`w-full h-[74px] rounded-[14px] p-2 flex flex-col items-center justify-center transition-all ${
                              isEmpty
                                ? 'bg-white/[0.03] hover:bg-white/[0.08] border border-dashed border-white/20 hover:border-cyan-400/60'
                                : 'bg-white/[0.05] hover:bg-white/[0.10] active:scale-[0.98] border border-white/15 hover:border-white/30 shadow-md'
                            }`}
                          >
                            {isEmpty ? (
                              /* Empty Slot (+) */
                              <div className="flex flex-col items-center justify-center gap-1">
                                <svg className="w-4 h-4 text-white/40 group-hover:text-cyan-400 transition-colors" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                                  <line x1="12" y1="5" x2="12" y2="19" />
                                  <line x1="5" y1="12" x2="19" y2="12" />
                                </svg>
                                <span className="text-[9.5px] font-medium text-white/40 group-hover:text-white/80 transition-colors">
                                  Slot {slot.index + 1}
                                </span>
                              </div>
                            ) : (
                              /* Configured App Slot */
                              <div className="flex flex-col items-center justify-center gap-1 w-full">
                                <div className="w-8 h-8 rounded-[7px] overflow-hidden shadow-sm flex items-center justify-center">
                                  <AppIconRenderer iconType={slot.iconType} label={slot.label} />
                                </div>
                                <span className="text-[10.5px] font-medium text-white/90 group-hover:text-white truncate max-w-[100px] tracking-tight">
                                  {slot.label}
                                </span>
                              </div>
                            )}
                          </button>

                          {/* Minus Badge (-) shown on hover to clear the slot */}
                          {!isEmpty && (
                            <button
                              type="button"
                              onClick={(e) => handleRemoveSlot(slot, e)}
                              title="Clear app from slot"
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

                  {/* Inline Mac App Picker Drawer (when a slot is clicked for assignment) */}
                  <AnimatePresence>
                    {selectedSlotIndex !== null && (
                      <motion.div
                        initial={{ opacity: 0, y: 8 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, y: 8 }}
                        transition={{ duration: 0.2 }}
                        className="mx-5 mt-2.5 p-3 rounded-[14px] bg-[#141824]/95 border border-white/20 shadow-2xl flex flex-col"
                      >
                        <div className="flex items-center justify-between pb-2 border-b border-white/10">
                          <span className="text-[11px] font-semibold text-white">
                            Assign macOS App to Slot {selectedSlotIndex + 1}
                          </span>
                          <button
                            type="button"
                            onClick={() => setSelectedSlotIndex(null)}
                            className="text-white/50 hover:text-white text-xs px-1"
                          >
                            Cancel
                          </button>
                        </div>

                        {/* Grid of Available Apps */}
                        <div className="grid grid-cols-4 gap-2 pt-2.5">
                          {AVAILABLE_MAC_APPS.map((app) => (
                            <button
                              key={app.bundleId}
                              type="button"
                              onClick={() => handleSelectApp(app)}
                              className="p-1.5 rounded-lg bg-white/[0.04] hover:bg-white/[0.12] border border-white/10 flex flex-col items-center gap-1 transition-all text-center group"
                            >
                              <div className="w-7 h-7 rounded-[6px] overflow-hidden">
                                <AppIconRenderer iconType={app.iconType} label={app.label} />
                              </div>
                              <span className="text-[9.5px] font-medium text-white/80 group-hover:text-white truncate max-w-full">
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

          {/* Authentic macOS Notification Banner: Execution Toast ("What Really Happens on the Mac") */}
          <AnimatePresence>
            {activeToast && (
              <motion.div
                initial={{ opacity: 0, x: 50, scale: 0.95 }}
                animate={{ opacity: 1, x: 0, scale: 1 }}
                exit={{ opacity: 0, x: 50, scale: 0.95 }}
                transition={{ type: 'spring', stiffness: 400, damping: 28 }}
                className="absolute top-11 right-3.5 z-40 w-[290px] rounded-2xl bg-[#1c202d]/95 backdrop-blur-2xl border border-white/15 p-3 shadow-2xl"
              >
                <div className="flex items-start gap-2.5">
                  {/* App Icon */}
                  <div className="w-8 h-8 rounded-lg overflow-hidden shrink-0 shadow-md">
                    {/* Find app icon if matching known bundle */}
                    {(() => {
                      const matched = AVAILABLE_MAC_APPS.find((a) => a.bundleId === activeToast.bundleId);
                      return (
                        <AppIconRenderer
                          iconType={matched ? matched.iconType : 'terminal'}
                          label={activeToast.label}
                        />
                      );
                    })()}
                  </div>

                  {/* Notification Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between text-[10px] text-white/50 mb-0.5">
                      <span className="font-semibold uppercase tracking-wider text-cyan-400">NotchDeck</span>
                      <span>now</span>
                    </div>
                    <p className="text-[11.5px] font-bold text-white tracking-tight leading-snug">
                      {activeToast.label} launched
                    </p>
                    <p className="text-[10px] text-white/70 leading-normal">
                      via NSWorkspace.shared.openApplication
                    </p>
                    <div className="mt-1">
                      <span className="inline-block text-[8.5px] font-mono text-cyan-300 bg-cyan-950/60 border border-cyan-800/50 px-1.5 py-0.5 rounded max-w-full truncate">
                        {activeToast.bundleId}
                      </span>
                    </div>
                  </div>

                  {/* Dismiss close */}
                  <button
                    type="button"
                    aria-label="Dismiss notification"
                    onClick={() => setActiveToast(null)}
                    className="text-white/40 hover:text-white"
                  >
                    <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Wire Sync Packet Confirmation Indicator */}
          <AnimatePresence>
            {syncStatus && (
              <motion.div
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 12 }}
                className="absolute bottom-16 left-1/2 -translate-x-1/2 z-30 bg-[#0d101a]/90 backdrop-blur-xl border border-cyan-500/30 px-3 py-1.5 rounded-full shadow-lg flex items-center gap-2"
              >
                <span className="w-2 h-2 rounded-full bg-cyan-400" />
                <span className="text-[10px] font-mono text-cyan-200">{syncStatus}</span>
              </motion.div>
            )}
          </AnimatePresence>

          {/* macOS Floating Dock at the Bottom of the Screen */}
          <div className="mt-auto mb-2 mx-auto z-10">
            <div className="flex items-center gap-1.5 bg-white/10 backdrop-blur-2xl border border-white/20 rounded-2xl px-2.5 py-1.5 shadow-2xl">
              {/* Finder */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="finder" label="Finder" />
                </div>
                <div className="w-1 h-1 rounded-full bg-white/80 mt-0.5" />
              </div>

              {/* Safari */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="safari" label="Safari" />
                </div>
                <div className="w-1 h-1 rounded-full bg-white/80 mt-0.5" />
              </div>

              {/* VS Code */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="code" label="VS Code" />
                </div>
                <div className="w-1 h-1 rounded-full bg-white/80 mt-0.5" />
              </div>

              {/* Terminal */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="terminal" label="Terminal" />
                </div>
                <div className="w-1 h-1 rounded-full bg-white/80 mt-0.5" />
              </div>

              {/* Music */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="music" label="Music" />
                </div>
              </div>

              {/* Settings */}
              <div className="relative group/dock flex flex-col items-center">
                <div className="w-7 h-7 rounded-[7px] overflow-hidden shadow-sm hover:scale-110 transition-transform">
                  <AppIconRenderer iconType="settings" label="Settings" />
                </div>
              </div>

              {/* Separator */}
              <div className="w-px h-5 bg-white/20 mx-1" />

              {/* Trash */}
              <div className="w-7 h-7 rounded-[7px] bg-slate-800/80 border border-white/10 flex items-center justify-center hover:scale-110 transition-transform">
                <svg className="w-3.5 h-3.5 text-slate-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="3 6 5 6 21 6" />
                  <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        {/* Laptop Bottom Lip / Hinge Notch */}
        <div className="h-2.5 mx-auto max-w-[280px] bg-gradient-to-b from-[#252833] to-[#1a1b22] rounded-b-md border-t border-white/5 flex items-center justify-center">
          <div className="w-14 h-1 bg-[#101217] rounded-full" />
        </div>
      </div>
    </div>
  );
}
