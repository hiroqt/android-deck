export type DeckIconType =
  | 'terminal'
  | 'code'
  | 'safari'
  | 'finder'
  | 'settings'
  | 'music'
  | 'slack'
  | 'figma';

export interface DeckSlotItem {
  id: string; // e.g. "app-1"
  index: number; // 0 to 5
  label: string; // e.g. "Terminal"
  bundleId: string; // e.g. "com.apple.Terminal"
  iconType: DeckIconType;
  isEmpty?: boolean;
}

export type OrientationMode = 'portrait' | 'landscape';
