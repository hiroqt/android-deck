'use client';

import { useEffect, useRef } from 'react';

const interactiveSelector = 'a, button:not(:disabled), summary, [role="button"], input, select';
const nativeSelector = 'input, textarea, select, [contenteditable="true"], [data-native-cursor], :disabled';

export default function PrecisionCursor() {
  const rootRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);
  const dotRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = rootRef.current!;
    const ring = ringRef.current!;
    const dot = dotRef.current!;
    const pointer = window.matchMedia('(hover: hover) and (pointer: fine)');
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');

    const target = { x: 0, y: 0 };
    const follower = { x: 0, y: 0 };
    let visible = false;
    let hovering = false;
    let frame = 0;
    let lastTime = 0;

    const paint = () => {
      dot.style.transform = `translate3d(${target.x}px, ${target.y}px, 0)`;
      ring.style.transform = `translate3d(${follower.x}px, ${follower.y}px, 0)`;
    };

    const tick = (time: number) => {
      frame = 0;
      if (!visible) return;
      const dt = Math.min(time - (lastTime || time - 16.67), 40);
      lastTime = time;
      const ease = 1 - Math.exp(-dt / 45);

      follower.x += (target.x - follower.x) * ease;
      follower.y += (target.y - follower.y) * ease;

      paint();

      const unsettled = Math.hypot(target.x - follower.x, target.y - follower.y) > 0.1;
      if (unsettled) frame = requestAnimationFrame(tick);
    };

    const wake = () => {
      if (!frame && visible) {
        lastTime = 0;
        frame = requestAnimationFrame(tick);
      }
    };

    const hide = () => {
      visible = false;
      root.style.opacity = '0';
      document.documentElement.classList.remove('has-precision-cursor');
      cancelAnimationFrame(frame);
      frame = 0;
    };

    const move = (event: PointerEvent) => {
      if (!pointer.matches || reduced.matches || event.pointerType === 'touch') return hide();
      const element = event.target instanceof Element ? event.target : null;
      if (element?.closest(nativeSelector)) return hide();

      target.x = event.clientX;
      target.y = event.clientY;
      hovering = Boolean(element?.closest(interactiveSelector));

      if (!visible) {
        follower.x = target.x;
        follower.y = target.y;
        visible = true;
        paint();
        root.style.opacity = '1';
        document.documentElement.classList.add('has-precision-cursor');
      }
      root.dataset.hover = String(hovering);
      wake();
    };

    window.addEventListener('pointermove', move, { passive: true });
    window.addEventListener('pointerleave', hide);
    window.addEventListener('blur', hide);

    return () => {
      hide();
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerleave', hide);
      window.removeEventListener('blur', hide);
    };
  }, []);

  return (
    <div ref={rootRef} className="precision-cursor" aria-hidden="true">
      <div ref={ringRef} className="cursor-ring" />
      <div ref={dotRef} className="cursor-dot" />
    </div>
  );
}
