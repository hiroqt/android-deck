'use client';

import { useState, useEffect, useRef } from 'react';
import { DeckSlotItem, OrientationMode } from '../types/deck';
import PhoneDeckMockup from './PhoneDeckMockup';
import DesktopNotchMockup, { ActionExecution } from './DesktopNotchMockup';
import { DEFAULT_STAGE_SLOTS } from './DualInteractiveStage';

export default function FigureShowcase() {
  const [slots, setSlots] = useState<DeckSlotItem[]>(DEFAULT_STAGE_SLOTS);
  const [lastActionExecution, setLastActionExecution] = useState<ActionExecution | null>(null);
  const [activePhoneSlotId, setActivePhoneSlotId] = useState<string | null>(null);
  const [phoneOrientation, setPhoneOrientation] = useState<OrientationMode>('portrait');

  const activeSlotTimerRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    return () => {
      if (activeSlotTimerRef.current) clearTimeout(activeSlotTimerRef.current);
    };
  }, []);

  // Listen for slot changes broadcast from TopNotchIsland or other sources
  useEffect(() => {
    const handleBroadcast = (event: Event) => {
      const customEvent = event as CustomEvent<DeckSlotItem[]>;
      if (Array.isArray(customEvent.detail)) {
        setSlots(customEvent.detail);
      }
    };
    window.addEventListener('macdeck-slots-sync', handleBroadcast);
    return () => {
      window.removeEventListener('macdeck-slots-sync', handleBroadcast);
    };
  }, []);

  const broadcastSlots = (updated: DeckSlotItem[]) => {
    window.dispatchEvent(new CustomEvent('macdeck-slots-sync', { detail: updated }));
  };

  // User taps an app tile on the Phone
  const handlePhoneTriggerSlot = (slot: DeckSlotItem) => {
    if (slot.isEmpty || !slot.bundleId) return;

    setActivePhoneSlotId(slot.id);
    const execution: ActionExecution = {
      label: slot.label,
      bundleId: slot.bundleId,
      timestamp: Date.now(),
    };
    setLastActionExecution(execution);

    if (activeSlotTimerRef.current) clearTimeout(activeSlotTimerRef.current);
    activeSlotTimerRef.current = setTimeout(() => {
      setActivePhoneSlotId(null);
    }, 240);
  };

  // User clears a slot in Desktop Notch HUD
  const handleClearSlot = (slot: DeckSlotItem) => {
    const updated = slots.map((s) =>
      s.index === slot.index ? { ...s, label: '', bundleId: '', isEmpty: true } : s
    );
    setSlots(updated);
    broadcastSlots(updated);
  };

  // User assigns an app to a slot in Desktop Notch HUD
  const handleAssignSlot = (index: number, app: Partial<DeckSlotItem>) => {
    const updated = [...slots];
    updated[index] = {
      id: `app-${index + 1}`,
      index,
      label: app.label || '',
      bundleId: app.bundleId || '',
      iconType: app.iconType || 'terminal',
      isEmpty: false,
    };
    setSlots(updated);
    broadcastSlots(updated);
  };

  const handleToggleOrientation = () => {
    setPhoneOrientation((prev) => (prev === 'portrait' ? 'landscape' : 'portrait'));
  };

  return (
    <figure className="figure">
      <div className="flex flex-col lg:flex-row items-center justify-center gap-8 lg:gap-10 w-full">
        {/* Left: macOS MacBook Display Frame with Notch HUD */}
        <div className="w-full max-w-[620px] shrink-0">
          <DesktopNotchMockup
            slots={slots}
            onClearSlot={handleClearSlot}
            onAssignSlot={handleAssignSlot}
            lastActionExecution={lastActionExecution}
          />
        </div>

        {/* Right: Android Phone Stream Deck */}
        <div className="shrink-0 flex flex-col items-center">
          <PhoneDeckMockup
            slots={slots}
            onTriggerSlot={handlePhoneTriggerSlot}
            activeSlotId={activePhoneSlotId}
            orientation={phoneOrientation}
            onToggleOrientation={handleToggleOrientation}
          />
        </div>
      </div>

      <figcaption className="caption">
        Touch the tiles on the phone. Watch macOS apps launch instantly, configured live from the notch.
      </figcaption>
    </figure>
  );
}
