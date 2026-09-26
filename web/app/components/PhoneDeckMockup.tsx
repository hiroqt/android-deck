'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { HugeiconsIcon } from '@hugeicons/react';
import { Refresh01Icon, Settings01Icon } from '@hugeicons/core-free-icons';
import { DeckSlotItem, OrientationMode } from '../types/deck';

export interface PhoneDeckMockupProps {
  slots?: DeckSlotItem[];
  onTriggerSlot?: (slot: DeckSlotItem) => void;
  activeSlotId?: string | null;
  orientation?: OrientationMode;
  onToggleOrientation?: () => void;
  className?: string;
  showOrientationControl?: boolean;
}

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

function AppIconRenderer({ iconType, label }: { iconType: string; label: string }) {
  switch (iconType) {
    case 'terminal':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="11" fill="#181B22" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
          <path d="M13 18L20 24L13 30" stroke="#38BDF8" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" />
          <line x1="24" y1="30" x2="35" y2="30" stroke="#F1F5F9" strokeWidth="3" strokeLinecap="round" />
        </svg>
      );
    case 'code':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="11" fill="#1A1D27" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
          <rect width="48" height="48" rx="11" fill="#1A1F2C" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
          <rect width="48" height="48" rx="11" fill="#181C26" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
          <rect width="48" height="48" rx="11" fill="#20242F" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
          <rect width="48" height="48" rx="11" fill="#FA2D48" />
          <path
            d="M31 14V27.5C30.1 27.2 29.1 27 28 27C24.7 27 22 29.2 22 32C22 34.8 24.7 37 28 37C31.3 37 34 34.8 34 32V19L20 22V29.5C19.1 29.2 18.1 29 17 29C13.7 29 11 31.2 11 34C11 36.8 13.7 39 17 39C20.3 39 23 36.8 23 34V16L31 14Z"
            fill="#FFFFFF"
          />
        </svg>
      );
    case 'slack':
      return (
        <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full h-full">
          <rect width="48" height="48" rx="11" fill="#1C1F2B" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
          <rect width="48" height="48" rx="11" fill="#181B24" />
          <rect x="0.5" y="0.5" width="47" height="47" rx="10.5" stroke="#2B3245" strokeWidth="1" />
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
        <div className="w-full h-full rounded-[11px] bg-[#3B82F6]/20 border border-[#2B3245] flex items-center justify-center text-[#3B82F6] font-bold text-lg">
          {label.slice(0, 1).toUpperCase()}
        </div>
      );
  }
}

export default function PhoneDeckMockup({
  slots = DEFAULT_SLOTS,
  onTriggerSlot,
  activeSlotId = null,
  orientation: controlledOrientation,
  onToggleOrientation,
  className = '',
  showOrientationControl = true,
}: PhoneDeckMockupProps) {
  const [internalOrientation, setInternalOrientation] = useState<OrientationMode>('portrait');
  const currentOrientation = controlledOrientation ?? internalOrientation;

  const [pressedSlotId, setPressedSlotId] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [refreshDegrees, setRefreshDegrees] = useState(0);

  const toastTimerRef = useRef<NodeJS.Timeout | null>(null);

  const handleToggleOrientation = () => {
    if (onToggleOrientation) {
      onToggleOrientation();
    } else {
      setInternalOrientation((prev) => (prev === 'portrait' ? 'landscape' : 'portrait'));
    }
  };

  const showToast = (message: string) => {
    if (toastTimerRef.current) {
      clearTimeout(toastTimerRef.current);
    }
    setToastMessage(message);
    toastTimerRef.current = setTimeout(() => {
      setToastMessage(null);
    }, 1800);
  };

  useEffect(() => {
    return () => {
      if (toastTimerRef.current) {
        clearTimeout(toastTimerRef.current);
      }
    };
  }, []);

  // Sync external activeSlotId to internal feedback
  useEffect(() => {
    if (activeSlotId) {
      setPressedSlotId(activeSlotId);
      const matched = slots.find((s) => s.id === activeSlotId);
      showToast(`action_invoke: ${activeSlotId}${matched ? ` (${matched.label})` : ''}`);
      const timer = setTimeout(() => {
        setPressedSlotId(null);
      }, 180);
      return () => clearTimeout(timer);
    }
  }, [activeSlotId, slots]);

  const handleSlotTrigger = (slot: DeckSlotItem) => {
    if (slot.isEmpty) return;
    setPressedSlotId(slot.id);
    showToast(`action_invoke: ${slot.id}`);
    onTriggerSlot?.(slot);

    setTimeout(() => {
      setPressedSlotId((current) => (current === slot.id ? null : current));
    }, 180);
  };

  const handleRefreshClick = () => {
    setIsRefreshing(true);
    setRefreshDegrees((prev) => prev + 360);
    showToast('profile_refreshed: 6 slots');
    setTimeout(() => {
      setIsRefreshing(false);
    }, 800);
  };

  const handleSettingsClick = () => {
    showToast('host: 127.0.0.1:8765 (usb)');
  };

  const isLandscape = currentOrientation === 'landscape';

  return (
    <div className={`flex flex-col items-center ${className}`}>
      {/* Top Utility Controls */}
      {showOrientationControl && (
        <div className="flex items-center justify-between w-full max-w-[340px] mb-3 px-1">
          <span className="text-[12px] font-medium text-[#475467] tracking-tight">
            Android Client
          </span>
          <button
            type="button"
            onClick={handleToggleOrientation}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-medium text-[#101828] bg-[#ffffff] border border-[#dbe2ea] shadow-xs hover:bg-[#f2f4f7] active:scale-95 transition-all"
          >
            <svg
              viewBox="0 0 16 16"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              className="w-3.5 h-3.5 text-[#475467]"
            >
              <path
                d="M13.333 4.667H4.667C3.562 4.667 2.667 5.562 2.667 6.667V11.333C2.667 12.438 3.562 13.333 4.667 13.333H11.333C12.438 13.333 13.333 12.438 13.333 11.333V4.667Z"
                stroke="currentColor"
                strokeWidth="1.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M8 2.667L10.667 4.667L8 6.667"
                stroke="currentColor"
                strokeWidth="1.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
            <span>{isLandscape ? 'Landscape (3x2)' : 'Portrait (2x3)'}</span>
          </button>
        </div>
      )}

      {/* Realistic Dark Titanium Smartphone Chassis */}
      <motion.div
        layout
        transition={{ type: 'spring', damping: 28, stiffness: 280 }}
        style={{
          width: isLandscape ? 580 : 320,
          height: isLandscape ? 340 : 640,
        }}
        className="relative bg-[#161821] p-3 rounded-[44px] border-[3px] border-[#2d3345] shadow-[0_24px_50px_-12px_rgba(16,24,40,0.35),0_0_0_1px_rgba(255,255,255,0.06)] select-none transition-all"
      >
        {/* Hardware side buttons */}
        <div
          className="absolute -left-[5px] top-[95px] w-[3px] h-8 bg-[#2d3345] rounded-l"
          aria-hidden="true"
        />
        <div
          className="absolute -left-[5px] top-[140px] w-[3px] h-8 bg-[#2d3345] rounded-l"
          aria-hidden="true"
        />
        <div
          className="absolute -right-[5px] top-[115px] w-[3px] h-12 bg-[#2d3345] rounded-r"
          aria-hidden="true"
        />

        {/* Chassis Speaker Slit (Top Bezel) */}
        {!isLandscape && (
          <div
            className="w-12 h-1 bg-[#282d38] rounded-full mx-auto mb-2"
            aria-hidden="true"
          />
        )}

        {/* Screen Bezel and Display Area */}
        <div className="w-full h-full bg-[#090A0F] rounded-[34px] overflow-hidden flex flex-col relative border border-[#1d212d]">
          {/* Android Status Bar */}
          <div className="flex items-center justify-between px-4 pt-2 pb-1 text-[#9CA3AF] text-[11px] font-medium z-10 shrink-0">
            <span>09:41</span>

            {/* Front Camera Punch-Hole */}
            <div
              className="w-3.5 h-3.5 rounded-full bg-black border border-[#222836] flex items-center justify-center"
              aria-hidden="true"
            >
              <div className="w-1.5 h-1.5 rounded-full bg-[#0d1424]" />
            </div>

            {/* Wi-Fi & Battery Status */}
            <div className="flex items-center gap-1.5" aria-hidden="true">
              <svg viewBox="0 0 16 16" fill="none" className="w-3.5 h-3.5 text-[#9CA3AF]">
                <path
                  d="M2 5.5C4 3.5 12 3.5 14 5.5M4 8C6 6.5 10 6.5 12 8M6.5 10.5C7.5 9.5 8.5 9.5 9.5 10.5M8 12.5H8.01"
                  stroke="currentColor"
                  strokeWidth="1.4"
                  strokeLinecap="round"
                />
              </svg>
              <span className="text-[10px] font-semibold text-[#D1D5DB]">94%</span>
              <div className="w-4 h-2 rounded-[2px] border border-[#9CA3AF] p-[1px] flex items-center">
                <div className="w-2.5 h-full bg-[#10B981] rounded-[1px]" />
              </div>
            </div>
          </div>

          {/* Jetpack Compose Top ConnectionBar */}
          <div className="flex items-center justify-between px-3.5 py-1.5 shrink-0 z-10">
            {/* Status indicator and host label */}
            <div
              onClick={handleSettingsClick}
              className="flex items-center gap-2 px-2.5 py-1 rounded-[10px] bg-[#141721] border border-[#22293d] cursor-pointer hover:border-[#384259] transition-colors"
            >
              {/* Solid Green Status Dot */}
              <div className="w-2.5 h-2.5 rounded-full bg-[#10B981] shrink-0" />
              <span className="text-[11px] font-medium text-[#9CA3AF] tracking-tight whitespace-nowrap">
                USB Connected • 127.0.0.1:8765
              </span>
            </div>

            {/* Action Buttons: Refresh & Settings */}
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={handleRefreshClick}
                title="Refresh Deck Apps"
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#9CA3AF] hover:text-[#F3F4F6] hover:bg-[#141721] active:scale-90 transition-all cursor-pointer"
              >
                <div
                  style={{
                    transform: `rotate(${refreshDegrees}deg)`,
                    transition: isRefreshing
                      ? 'transform 0.8s cubic-bezier(0.16, 1, 0.3, 1)'
                      : 'transform 0.3s ease',
                  }}
                  className="flex items-center justify-center"
                >
                  <HugeiconsIcon
                    icon={Refresh01Icon}
                    size={17}
                    className={isRefreshing ? 'text-[#3B82F6]' : 'text-[#9CA3AF]'}
                  />
                </div>
              </button>

              <button
                type="button"
                onClick={handleSettingsClick}
                title="Connection Settings"
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#9CA3AF] hover:text-[#F3F4F6] hover:bg-[#141721] active:scale-90 transition-all cursor-pointer"
              >
                <HugeiconsIcon icon={Settings01Icon} size={17} className="text-[#9CA3AF]" />
              </button>
            </div>
          </div>

          {/* 6-Slot Stream Deck Grid */}
          <div
            className={`flex-1 overflow-hidden ${
              isLandscape
                ? 'grid grid-cols-3 grid-rows-2 gap-3 px-5 py-1.5'
                : 'grid grid-cols-2 grid-rows-3 gap-3 px-3.5 py-2.5'
            }`}
          >
            {slots.slice(0, 6).map((slot, index) => {
              const isPressed = pressedSlotId === slot.id || activeSlotId === slot.id;
              const isEmpty = slot.isEmpty;

              if (isEmpty) {
                return (
                  <div
                    key={`empty-${index}`}
                    className="rounded-[22px] bg-[#121520]/40 border border-[#22293d]/50 flex items-center justify-center"
                  >
                    <div className="w-5 h-5 rounded-full border border-[#282E42]/80 border-dashed" />
                  </div>
                );
              }

              return (
                <div
                  key={slot.id}
                  role="button"
                  tabIndex={0}
                  aria-label={`Trigger ${slot.label} via slot ${index + 1}`}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ' ') {
                      e.preventDefault();
                      handleSlotTrigger(slot);
                    }
                  }}
                  onPointerDown={() => handleSlotTrigger(slot)}
                  onPointerUp={() => setPressedSlotId(null)}
                  onPointerLeave={() => setPressedSlotId(null)}
                  style={{
                    transform: isPressed ? 'scale(0.93)' : 'scale(1)',
                    backgroundColor: isPressed ? '#1E2333' : '#121520',
                    borderColor: isPressed ? '#00d2ff' : '#22293d',
                    borderWidth: isPressed ? '2px' : '1px',
                    transition:
                      'transform 90ms cubic-bezier(0.16, 1, 0.3, 1), background-color 100ms ease, border-color 100ms ease',
                  }}
                  className="rounded-[22px] border flex flex-col items-center justify-center p-2.5 cursor-pointer select-none focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-400"
                >
                  {/* App Icon */}
                  <div
                    className={`${
                      isLandscape ? 'w-10 h-10' : 'w-12 h-12'
                    } rounded-[12px] overflow-hidden shrink-0 pointer-events-none transition-transform`}
                  >
                    <AppIconRenderer iconType={slot.iconType} label={slot.label} />
                  </div>

                  {/* App Title Label */}
                  <span className="text-[12px] font-semibold text-[#F3F4F6] text-center truncate max-w-full px-1 mt-1.5 tracking-tight pointer-events-none">
                    {slot.label}
                  </span>
                </div>
              );
            })}
          </div>

          {/* Action Invoke Event Toast / Status Pill */}
          <AnimatePresence>
            {toastMessage && (
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 8, scale: 0.95 }}
                transition={{ duration: 0.15 }}
                className="absolute bottom-5 left-1/2 -translate-x-1/2 z-30 pointer-events-none"
              >
                <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#121520]/95 border border-[#00d2ff]/60 shadow-lg backdrop-blur-md">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#00d2ff]" />
                  <span className="text-[10px] font-mono font-medium text-[#00d2ff] tracking-tight whitespace-nowrap">
                    {toastMessage}
                  </span>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Subtle Page Dots Indicator (Swipe left / right feedback from DeckScreen.kt) */}
          <div className="flex items-center justify-center gap-1.5 pb-1 z-10 shrink-0">
            <div className="w-[18px] h-[5px] rounded-[4px] bg-[#3B82F6]" />
            <div className="w-[7px] h-[5px] rounded-[4px] bg-[#282E42]" />
          </div>

          {/* Android Home Gesture Bar */}
          <div className="pb-1.5 pt-0.5 flex justify-center shrink-0 z-10">
            <div className="w-24 h-1 bg-[#475467] rounded-full" />
          </div>
        </div>
      </motion.div>
    </div>
  );
}
