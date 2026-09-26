/**
 * Exact continuous curvature geometry for macOS Notch and Liquid Pull.
 * Perfectly calibrated to eliminate degenerate control points and stroke leakage on bezel edges.
 */

export type NotchEdge = 'top' | 'left' | 'right';

const C = 0.5522847498;

export interface NotchPaths {
  fillPath: string; // Closed path for acrylic glass fill
  rimPath: string;  // Open path tracing ONLY display-facing curves (0 stroke on bezel)
}

/**
 * Returns mathematically smooth G2 continuous notch paths.
 * R1 = concave ear radius (flares from bezel)
 * R2 = convex corner radius (rounds into display)
 */
export function getNotchGeometry(
  edge: NotchEdge,
  width: number,
  height: number,
  r1 = 10,
  r2 = 14
): NotchPaths {
  const w = Math.max(1, width);
  const h = Math.max(1, height);

  if (edge === 'top') {
    const ear = Math.min(r1, w / 4, h / 2.2);
    const corner = Math.min(r2, (w - 2 * ear) / 2, h - ear);
    const wallH = h - ear - corner;

    // Rim path: starts at (0, 0), traces down through ears and bottom, ends at (w, 0).
    // NO top bezel line!
    const rimPath = [
      `M 0 0`,
      // Left concave flare into notch
      `C ${ear * C} 0, ${ear} ${ear * (1 - C)}, ${ear} ${ear}`,
      // Left vertical wall
      wallH > 0 ? `L ${ear} ${ear + wallH}` : '',
      // Bottom-left convex corner
      `C ${ear} ${h - corner * (1 - C)}, ${ear + corner * (1 - C)} ${h}, ${ear + corner} ${h}`,
      // Bottom flat edge
      `L ${w - ear - corner} ${h}`,
      // Bottom-right convex corner
      `C ${w - ear - corner * (1 - C)} ${h}, ${w - ear} ${h - corner * (1 - C)}, ${w - ear} ${ear + wallH}`,
      // Right vertical wall
      wallH > 0 ? `L ${w - ear} ${ear}` : '',
      // Right concave flare out to bezel
      `C ${w - ear} ${ear * (1 - C)}, ${w - ear * (1 - C)} 0, ${w} 0`,
    ]
      .filter(Boolean)
      .join(' ');

    const fillPath = `${rimPath} Z`;

    return { fillPath, rimPath };
  }

  if (edge === 'left') {
    // Bezel at x = 0
    const ear = Math.min(r1, h / 4, w / 2.2);
    const corner = Math.min(r2, (h - 2 * ear) / 2, w - ear);
    const wallW = w - ear - corner;

    const rimPath = [
      `M 0 0`,
      // Top concave flare
      `C 0 ${ear * C}, ${ear * (1 - C)} ${ear}, ${ear} ${ear}`,
      // Top horizontal wall
      wallW > 0 ? `L ${ear + wallW} ${ear}` : '',
      // Top-right convex corner
      `C ${w - corner * (1 - C)} ${ear}, ${w} ${ear + corner * (1 - C)}, ${w} ${ear + corner}`,
      // Right vertical edge
      `L ${w} ${h - ear - corner}`,
      // Bottom-right convex corner
      `C ${w} ${h - ear - corner * (1 - C)}, ${w - corner * (1 - C)} ${h - ear}, ${ear + wallW} ${h - ear}`,
      // Bottom horizontal wall
      wallW > 0 ? `L ${ear} ${h - ear}` : '',
      // Bottom concave flare out to bezel
      `C ${ear * (1 - C)} ${h - ear}, 0 ${h - ear * (1 - C)}, 0 ${h}`,
    ]
      .filter(Boolean)
      .join(' ');

    const fillPath = `${rimPath} Z`;
    return { fillPath, rimPath };
  }

  // Right edge: bezel at x = w
  const ear = Math.min(r1, h / 4, w / 2.2);
  const corner = Math.min(r2, (h - 2 * ear) / 2, w - ear);
  const wallW = w - ear - corner;

  const rimPath = [
    `M ${w} 0`,
    // Top concave flare
    `C ${w} ${ear * C}, ${w - ear * (1 - C)} ${ear}, ${w - ear} ${ear}`,
    // Top horizontal wall
    wallW > 0 ? `L ${corner} ${ear}` : '',
    // Top-left convex corner
    `C ${corner * (1 - C)} ${ear}, 0 ${ear + corner * (1 - C)}, 0 ${ear + corner}`,
    // Left vertical edge
    `L 0 ${h - ear - corner}`,
    // Bottom-left convex corner
    `C 0 ${h - ear - corner * (1 - C)}, ${corner * (1 - C)} ${h - ear}, ${corner} ${h - ear}`,
    // Bottom horizontal wall
    wallW > 0 ? `L ${w - ear} ${h - ear}` : '',
    // Bottom concave flare out to bezel
    `C ${w - ear * (1 - C)} ${h - ear}, ${w} ${h - ear * (1 - C)}, ${w} ${h}`,
  ]
    .filter(Boolean)
    .join(' ');

  const fillPath = `${rimPath} Z`;
  return { fillPath, rimPath };
}

/**
 * Returns dynamic liquid pull paths with authentic metaball waist and trailing bulb.
 */
export function getLiquidPullGeometry(
  edge: NotchEdge,
  width: number,
  height: number,
  stretchDistance: number,
  lateralOffset = 0
): NotchPaths {
  const w = Math.max(1, width);
  const h = Math.max(1, height);
  const stretch = Math.max(0, stretchDistance);

  if (stretch <= 1) {
    return getNotchGeometry(edge, w, h);
  }

  const stretchRatio = Math.min(1.0, stretch / 110.0);

  if (edge === 'top') {
    const baseLength = Math.max(76.0, Math.min(w * 0.95, 170.0 - 50.0 * Math.pow(stretchRatio, 0.85)));
    const baseMidX = w / 2;
    const baseLeft = Math.max(0, baseMidX - baseLength / 2);
    const baseRight = Math.min(w, baseMidX + baseLength / 2);

    const clampedLat = Math.max(-w * 0.22, Math.min(w * 0.22, lateralOffset * 0.4));
    const bulbMidX = Math.max(40, Math.min(w - 40, baseMidX + clampedLat));
    const bulbW = Math.max(68.0, 84.0 - 16.0 * stretchRatio);
    const bulbLeft = bulbMidX - bulbW / 2;
    const bulbRight = bulbMidX + bulbW / 2;
    const bulbCorner = Math.min(16, bulbW / 2);

    const waistProgress = 0.44 + 0.08 * stretchRatio;
    const waistY = h * waistProgress;
    const waistMidX = baseMidX + clampedLat * 0.5;
    const waistPinch = Math.pow(stretchRatio, 0.7);
    const waistW = Math.max(16.0, 74.0 * (1.0 - 0.76 * waistPinch));
    const waistLeft = waistMidX - waistW / 2;
    const waistRight = waistMidX + waistW / 2;

    const dY1 = Math.max(4.0, waistY);
    const dY2 = Math.max(4.0, h - waistY);

    const rimPath = [
      `M ${baseLeft} 0`,
      // Bezel flare into left waist
      `C ${baseLeft} ${dY1 * 0.5}, ${waistLeft - dY1 * 0.35} ${waistY}, ${waistLeft} ${waistY}`,
      // Left waist into bulb left shoulder
      `C ${waistLeft + dY2 * 0.35} ${waistY}, ${bulbLeft} ${h - bulbCorner}, ${bulbLeft} ${h - bulbCorner}`,
      // Bulb bottom-left corner
      `C ${bulbLeft} ${h - bulbCorner * (1 - C)}, ${bulbLeft + bulbCorner * (1 - C)} ${h}, ${bulbLeft + bulbCorner} ${h}`,
      // Bulb flat bottom tip
      `L ${bulbRight - bulbCorner} ${h}`,
      // Bulb bottom-right corner
      `C ${bulbRight - bulbCorner * (1 - C)} ${h}, ${bulbRight} ${h - bulbCorner * (1 - C)}, ${bulbRight} ${h - bulbCorner}`,
      // Bulb right shoulder into right waist
      `C ${bulbRight} ${h - bulbCorner}, ${waistRight + dY2 * 0.35} ${waistY}, ${waistRight} ${waistY}`,
      // Right waist into bezel right flare
      `C ${waistRight - dY1 * 0.35} ${waistY}, ${baseRight} ${dY1 * 0.5}, ${baseRight} 0`,
    ].join(' ');

    const fillPath = `${rimPath} Z`;
    return { fillPath, rimPath };
  }

  // Vertical (Left or Right)
  const isLeft = edge === 'left';
  const baseLength = Math.max(68.0, Math.min(h * 0.95, 130.0 - 40.0 * Math.pow(stretchRatio, 0.85)));
  const baseMidY = h / 2;
  const baseTop = Math.max(0, baseMidY - baseLength / 2);
  const baseBottom = Math.min(h, baseMidY + baseLength / 2);

  const clampedLat = Math.max(-h * 0.22, Math.min(h * 0.22, lateralOffset * 0.4));
  const bulbMidY = Math.max(28, Math.min(h - 28, baseMidY + clampedLat));
  const bulbH = Math.max(48.0, 58.0 - 10.0 * stretchRatio);
  const bulbTop = bulbMidY - bulbH / 2;
  const bulbBottom = bulbMidY + bulbH / 2;
  const bulbCorner = Math.min(14, bulbH / 2);

  const waistProgress = 0.44 + 0.08 * stretchRatio;
  const waistX = isLeft ? w * waistProgress : w * (1 - waistProgress);
  const waistMidY = baseMidY + clampedLat * 0.5;
  const waistPinch = Math.pow(stretchRatio, 0.7);
  const waistH = Math.max(16.0, 56.0 * (1.0 - 0.76 * waistPinch));
  const waistTop = waistMidY - waistH / 2;
  const waistBottom = waistMidY + waistH / 2;

  if (isLeft) {
    const dX1 = Math.max(4.0, waistX);
    const dX2 = Math.max(4.0, w - waistX);

    const rimPath = [
      `M 0 ${baseTop}`,
      // Bezel flare into top waist
      `C ${dX1 * 0.5} ${baseTop}, ${waistX} ${waistTop - dX1 * 0.35}, ${waistX} ${waistTop}`,
      // Top waist into bulb top shoulder
      `C ${waistX} ${waistTop + dX2 * 0.35}, ${w - bulbCorner} ${bulbTop}, ${w - bulbCorner} ${bulbTop}`,
      // Bulb top-right corner
      `C ${w - bulbCorner * (1 - C)} ${bulbTop}, ${w} ${bulbTop + bulbCorner * (1 - C)}, ${w} ${bulbTop + bulbCorner}`,
      // Flat outer edge
      `L ${w} ${bulbBottom - bulbCorner}`,
      // Bulb bottom-right corner
      `C ${w} ${bulbBottom - bulbCorner * (1 - C)}, ${w - bulbCorner * (1 - C)} ${bulbBottom}, ${w - bulbCorner} ${bulbBottom}`,
      // Bulb bottom shoulder into bottom waist
      `C ${w - bulbCorner} ${bulbBottom}, ${waistX} ${waistBottom + dX2 * 0.35}, ${waistX} ${waistBottom}`,
      // Bottom waist into bezel bottom flare
      `C ${waistX} ${waistBottom - dX1 * 0.35}, ${dX1 * 0.5} ${baseBottom}, 0 ${baseBottom}`,
    ].join(' ');

    const fillPath = `${rimPath} Z`;
    return { fillPath, rimPath };
  }

  // Right edge
  const dX1 = Math.max(4.0, w - waistX);
  const dX2 = Math.max(4.0, waistX);

  const rimPath = [
    `M ${w} ${baseTop}`,
    // Bezel flare into top waist
    `C ${w - dX1 * 0.5} ${baseTop}, ${waistX} ${waistTop - dX1 * 0.35}, ${waistX} ${waistTop}`,
    // Top waist into bulb top shoulder
    `C ${waistX} ${waistTop + dX2 * 0.35}, ${bulbCorner} ${bulbTop}, ${bulbCorner} ${bulbTop}`,
    // Bulb top-left corner
    `C ${bulbCorner * (1 - C)} ${bulbTop}, 0 ${bulbTop + bulbCorner * (1 - C)}, 0 ${bulbTop + bulbCorner}`,
    // Flat outer edge
    `L 0 ${bulbBottom - bulbCorner}`,
    // Bulb bottom-left corner
    `C 0 ${bulbBottom - bulbCorner * (1 - C)}, ${bulbCorner * (1 - C)} ${bulbBottom}, ${bulbCorner} ${bulbBottom}`,
    // Bulb bottom shoulder into bottom waist
    `C ${bulbCorner} ${bulbBottom}, ${waistX} ${waistBottom + dX2 * 0.35}, ${waistX} ${waistBottom}`,
    // Bottom waist into bezel bottom flare
    `C ${waistX} ${waistBottom - dX1 * 0.35}, ${w - dX1 * 0.5} ${baseBottom}, ${w} ${baseBottom}`,
  ].join(' ');

  const fillPath = `${rimPath} Z`;
  return { fillPath, rimPath };
}
/**
 * Returns geometry for detached floating droplet pill.
 */
export function getDetachedDropletGeometry(width: number, height: number): NotchPaths {
  const w = Math.max(1, width);
  const h = Math.max(1, height);
  const r = Math.min(h / 2, w / 2, 16);
  const path = `M ${r} 0 L ${w - r} 0 A ${r} ${r} 0 0 1 ${w} ${r} L ${w} ${h - r} A ${r} ${r} 0 0 1 ${w - r} ${h} L ${r} ${h} A ${r} ${r} 0 0 1 0 ${h - r} L 0 ${r} A ${r} ${r} 0 0 1 ${r} 0 Z`;
  return { fillPath: path, rimPath: path };
}

/**
 * Returns fill path string for side/top notch.
 */
export function getSideNotchPath(
  edge: NotchEdge,
  width: number,
  height: number,
  r1 = 10,
  r2 = 14
): string {
  return getNotchGeometry(edge, width, height, r1, r2).fillPath;
}

/**
 * Returns fill path string for liquid pull tendon.
 */
export function getLiquidPullPath(
  edge: NotchEdge,
  width: number,
  height: number,
  stretchDistance: number,
  lateralOffset = 0,
  isDetached = false,
  _cornerRadius = 18
): string {
  if (isDetached) {
    return getDetachedDropletGeometry(width, height).fillPath;
  }
  return getLiquidPullGeometry(edge, width, height, stretchDistance, lateralOffset).fillPath;
}
