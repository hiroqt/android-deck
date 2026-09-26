/**
 * Exact mathematical reproduction of macOS NotchDeck's SideNotchShape and LiquidPullShape.
 * Converted directly from SwiftUI Path calculations in:
 * macos/NotchDeck/Sources/NotchDeck/Views/SideNotchShape.swift
 * macos/NotchDeck/Sources/NotchDeck/Views/LiquidPullShape.swift
 */

export type NotchEdge = 'top' | 'left' | 'right';

const CIRCLE_REACH = 0.5522847498;

/**
 * Returns the exact continuous curvature notch path with organic inverse fillet flares.
 */
export function getSideNotchPath(
  edge: NotchEdge,
  width: number,
  height: number,
  cornerRadius = 18,
  curlRadius = 14
): string {
  if (width <= 0 || height <= 0) return '';

  const w = Math.max(1, width);
  const h = Math.max(1, height);

  if (edge === 'top') {
    // Top bezel at y = 0
    const curl = Math.min(curlRadius, w / 4, h / 2);
    const corner = Math.min(cornerRadius, (w - 2 * curl) / 2, h - curl);
    const bodyBottom = h;

    return [
      `M 0 0`,
      // Left concave flare into notch
      `C ${curl * CIRCLE_REACH} 0, ${curl} ${curl * (1 - CIRCLE_REACH)}, ${curl} ${curl}`,
      // Left outer corner down to bottom
      `C ${curl} ${curl + (bodyBottom - curl - corner) * (1 - CIRCLE_REACH)}, ${curl + corner * (1 - CIRCLE_REACH)} ${bodyBottom}, ${curl + corner} ${bodyBottom}`,
      // Flat bottom edge
      `L ${w - curl - corner} ${bodyBottom}`,
      // Right outer corner turning up
      `C ${w - curl - corner * (1 - CIRCLE_REACH)} ${bodyBottom}, ${w - curl} ${curl + (bodyBottom - curl - corner) * (1 - CIRCLE_REACH)}, ${w - curl} ${curl}`,
      // Right concave flare out to bezel
      `C ${w - curl} ${curl * (1 - CIRCLE_REACH)}, ${w - curl * (1 - CIRCLE_REACH)} 0, ${w} 0`,
      // Close along bezel
      `Z`,
    ].join(' ');
  }

  if (edge === 'left') {
    // Left bezel at x = 0
    const curl = Math.min(curlRadius, h / 4, w / 2);
    const corner = Math.min(cornerRadius, (h - 2 * curl) / 2, w - curl);
    const bodyRight = w;

    return [
      `M 0 0`,
      // Top concave flare into side notch
      `C 0 ${curl * CIRCLE_REACH}, ${curl * (1 - CIRCLE_REACH)} ${curl}, ${curl} ${curl}`,
      // Top outer corner out to right
      `C ${curl + (bodyRight - curl - corner) * (1 - CIRCLE_REACH)} ${curl}, ${bodyRight} ${curl + corner * (1 - CIRCLE_REACH)}, ${bodyRight} ${curl + corner}`,
      // Flat outer edge
      `L ${bodyRight} ${h - curl - corner}`,
      // Bottom outer corner turning in
      `C ${bodyRight} ${h - curl - corner * (1 - CIRCLE_REACH)}, ${curl + (bodyRight - curl - corner) * (1 - CIRCLE_REACH)} ${h - curl}, ${curl + corner} ${h - curl}`,
      // Bottom concave flare out to bezel
      `C ${curl * (1 - CIRCLE_REACH)} ${h - curl}, 0 ${h - curl * (1 - CIRCLE_REACH)}, 0 ${h}`,
      // Close along bezel
      `Z`,
    ].join(' ');
  }

  // Right edge: bezel at x = w
  const curl = Math.min(curlRadius, h / 4, w / 2);
  const corner = Math.min(cornerRadius, (h - 2 * curl) / 2, w - curl);
  const bodyLeft = 0;

  return [
    `M ${w} 0`,
    // Top concave flare into side notch
    `C ${w} ${curl * CIRCLE_REACH}, ${w - curl * (1 - CIRCLE_REACH)} ${curl}, ${w - curl} ${curl}`,
    // Top outer corner out to left
    `C ${w - curl - (w - curl - corner) * (1 - CIRCLE_REACH)} ${curl}, ${bodyLeft} ${curl + corner * (1 - CIRCLE_REACH)}, ${bodyLeft} ${curl + corner}`,
    // Flat outer edge
    `L ${bodyLeft} ${h - curl - corner}`,
    // Bottom outer corner turning in
    `C ${bodyLeft} ${h - curl - corner * (1 - CIRCLE_REACH)}, ${w - curl - (w - curl - corner) * (1 - CIRCLE_REACH)} ${h - curl}, ${w - curl - corner} ${h - curl}`,
    // Bottom concave flare out to bezel
    `C ${w - curl * (1 - CIRCLE_REACH)} ${h - curl}, ${w} ${h - curl * (1 - CIRCLE_REACH)}, ${w} ${h}`,
    // Close along bezel
    `Z`,
  ].join(' ');
}

/**
 * Returns the exact elastic liquid tendon path when stretching away from screen bezel.
 * Reproduces LiquidPullShape.swift metaball tendon waist pinch and bulb equations.
 */
export function getLiquidPullPath(
  edge: NotchEdge,
  width: number,
  height: number,
  stretchDistance: number,
  lateralOffset = 0,
  isDetached = false,
  cornerRadius = 18
): string {
  const w = Math.max(1, width);
  const h = Math.max(1, height);

  if (isDetached) {
    const r = Math.min(w, h) / 2;
    return [
      `M ${r} 0`,
      `L ${w - r} 0`,
      `A ${r} ${r} 0 0 1 ${w} ${r}`,
      `A ${r} ${r} 0 0 1 ${w - r} ${h}`,
      `L ${r} ${h}`,
      `A ${r} ${r} 0 0 1 0 ${h - r}`,
      `A ${r} ${r} 0 0 1 ${r} 0`,
      `Z`,
    ].join(' ');
  }

  const stretch = Math.max(0, stretchDistance);
  if (stretch <= 1) {
    return getSideNotchPath(edge, w, h, cornerRadius, 14);
  }

  // Canonical stretch math (LiquidPullShape.swift lines 78-168)
  const maxTravel = 105.0;
  const stretchRatio = Math.min(1.0, Math.max(0.0, stretch / maxTravel));

  if (edge === 'top') {
    const baseLength = Math.max(90.0, Math.min(w * 0.95, 180.0 - 55.0 * Math.pow(stretchRatio, 0.85)));
    const baseMidX = w / 2;
    const baseLeft = Math.max(0, baseMidX - baseLength / 2);
    const baseRight = Math.min(w, baseMidX + baseLength / 2);

    const clampedLateral = Math.max(-w * 0.25, Math.min(w * 0.25, lateralOffset * 0.4));
    const bulbMidX = Math.max(36, Math.min(w - 36, baseMidX + clampedLateral));
    const bulbWidth = Math.max(64.0, 80.0 - 16.0 * stretchRatio);
    const bulbLeft = bulbMidX - bulbWidth / 2;
    const bulbRight = bulbMidX + bulbWidth / 2;
    const bulbBottom = h;
    const bulbCorner = Math.min(18, bulbWidth / 2);

    const waistProgress = 0.44 + 0.08 * stretchRatio;
    const waistY = h * waistProgress;
    const waistMidX = baseMidX + clampedLateral * 0.5;
    const waistPinch = Math.pow(stretchRatio, 0.7);
    const waistWidth = Math.max(14.0, 72.0 * (1.0 - 0.76 * waistPinch));
    const waistLeft = waistMidX - waistWidth / 2;
    const waistRight = waistMidX + waistWidth / 2;

    const dY1 = Math.max(4.0, waistY);
    const dY2 = Math.max(4.0, bulbBottom - waistY);

    return [
      `M ${baseLeft} 0`,
      // Bezel flare into left waist
      `C ${baseLeft} ${dY1 * 0.5}, ${waistLeft - dY1 * 0.4} ${waistY}, ${waistLeft} ${waistY}`,
      // Left waist into bulb left shoulder
      `C ${waistLeft + dY2 * 0.4} ${waistY}, ${bulbLeft} ${bulbBottom - bulbCorner}, ${bulbLeft} ${bulbBottom - bulbCorner}`,
      // Bulb bottom-left corner
      `C ${bulbLeft} ${bulbBottom - bulbCorner * 0.448}, ${bulbLeft + bulbCorner * 0.448} ${bulbBottom}, ${bulbLeft + bulbCorner} ${bulbBottom}`,
      // Flat bulb tip
      `L ${bulbRight - bulbCorner} ${bulbBottom}`,
      // Bulb bottom-right corner
      `C ${bulbRight - bulbCorner * 0.448} ${bulbBottom}, ${bulbRight} ${bulbBottom - bulbCorner * 0.448}, ${bulbRight} ${bulbBottom - bulbCorner}`,
      // Bulb right shoulder into right waist
      `C ${bulbRight} ${bulbBottom - bulbCorner}, ${waistRight + dY2 * 0.4} ${waistY}, ${waistRight} ${waistY}`,
      // Right waist into bezel right flare
      `C ${waistRight - dY1 * 0.4} ${waistY}, ${baseRight} ${dY1 * 0.5}, ${baseRight} 0`,
      // Close along bezel
      `Z`,
    ].join(' ');
  }

  // Vertical (Left or Right)
  const isLeft = edge === 'left';
  const baseLength = Math.max(80.0, Math.min(h * 0.95, 140.0 - 45.0 * Math.pow(stretchRatio, 0.85)));
  const baseMidY = h / 2;
  const baseTop = Math.max(0, baseMidY - baseLength / 2);
  const baseBottom = Math.min(h, baseMidY + baseLength / 2);

  const clampedLateral = Math.max(-h * 0.25, Math.min(h * 0.25, lateralOffset * 0.4));
  const bulbMidY = Math.max(30, Math.min(h - 30, baseMidY + clampedLateral));
  const bulbHeight = Math.max(48.0, 60.0 - 12.0 * stretchRatio);
  const bulbTop = bulbMidY - bulbHeight / 2;
  const bulbBottom = bulbMidY + bulbHeight / 2;
  const bulbCorner = Math.min(16, bulbHeight / 2);

  const waistProgress = 0.44 + 0.08 * stretchRatio;
  const waistX = isLeft ? w * waistProgress : w * (1 - waistProgress);
  const waistMidY = baseMidY + clampedLateral * 0.5;
  const waistPinch = Math.pow(stretchRatio, 0.7);
  const waistHeight = Math.max(14.0, 56.0 * (1.0 - 0.76 * waistPinch));
  const waistTop = waistMidY - waistHeight / 2;
  const waistBottom = waistMidY + waistHeight / 2;

  if (isLeft) {
    // Bezel at x = 0
    const dX1 = Math.max(4.0, waistX);
    const dX2 = Math.max(4.0, w - waistX);

    return [
      `M 0 ${baseTop}`,
      // Bezel flare into top waist
      `C ${dX1 * 0.5} ${baseTop}, ${waistX} ${waistTop - dX1 * 0.4}, ${waistX} ${waistTop}`,
      // Top waist into bulb top shoulder
      `C ${waistX} ${waistTop + dX2 * 0.4}, ${w - bulbCorner} ${bulbTop}, ${w - bulbCorner} ${bulbTop}`,
      // Bulb top-right corner
      `C ${w - bulbCorner * 0.448} ${bulbTop}, ${w} ${bulbTop + bulbCorner * 0.448}, ${w} ${bulbTop + bulbCorner}`,
      // Flat outer edge
      `L ${w} ${bulbBottom - bulbCorner}`,
      // Bulb bottom-right corner
      `C ${w} ${bulbBottom - bulbCorner * 0.448}, ${w - bulbCorner * 0.448} ${bulbBottom}, ${w - bulbCorner} ${bulbBottom}`,
      // Bulb bottom shoulder into bottom waist
      `C ${w - bulbCorner} ${bulbBottom}, ${waistX} ${waistBottom + dX2 * 0.4}, ${waistX} ${waistBottom}`,
      // Bottom waist into bezel bottom flare
      `C ${waistX} ${waistBottom - dX1 * 0.4}, ${dX1 * 0.5} ${baseBottom}, 0 ${baseBottom}`,
      // Close along bezel
      `Z`,
    ].join(' ');
  }

  // Right edge: Bezel at x = w
  const dX1 = Math.max(4.0, w - waistX);
  const dX2 = Math.max(4.0, waistX);

  return [
    `M ${w} ${baseTop}`,
    // Bezel flare into top waist
    `C ${w - dX1 * 0.5} ${baseTop}, ${waistX} ${waistTop - dX1 * 0.4}, ${waistX} ${waistTop}`,
    // Top waist into bulb top shoulder
    `C ${waistX} ${waistTop + dX2 * 0.4}, ${bulbCorner} ${bulbTop}, ${bulbCorner} ${bulbTop}`,
    // Bulb top-left corner
    `C ${bulbCorner * 0.448} ${bulbTop}, 0 ${bulbTop + bulbCorner * 0.448}, 0 ${bulbTop + bulbCorner}`,
    // Flat outer edge
    `L 0 ${bulbBottom - bulbCorner}`,
    // Bulb bottom-left corner
    `C 0 ${bulbBottom - bulbCorner * 0.448}, ${bulbCorner * 0.448} ${bulbBottom}, ${bulbCorner} ${bulbBottom}`,
    // Bulb bottom shoulder into bottom waist
    `C ${bulbCorner} ${bulbBottom}, ${waistX} ${waistBottom + dX2 * 0.4}, ${waistX} ${waistBottom}`,
    // Bottom waist into bezel bottom flare
    `C ${waistX} ${waistBottom - dX1 * 0.4}, ${w - dX1 * 0.5} ${baseBottom}, ${w} ${baseBottom}`,
    // Close along bezel
    `Z`,
  ].join(' ');
}
