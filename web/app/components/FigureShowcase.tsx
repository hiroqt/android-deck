'use client';

import { useEffect, useRef, useState, useCallback } from 'react';

interface DemoVideoProps {
  primarySrc: string;
  fallbackSrc?: string;
  label: string;
  videoRef: React.RefObject<HTMLVideoElement | null>;
  playing: boolean;
  onToggle: () => void;
  onEnded?: () => void;
  onTimeUpdate?: () => void;
  onPlay?: () => void;
  onPause?: () => void;
}

function DemoVideo({
  primarySrc,
  fallbackSrc,
  label,
  videoRef,
  playing,
  onToggle,
  onEnded,
  onTimeUpdate,
  onPlay,
  onPause,
}: DemoVideoProps) {
  const [isHovered, setIsHovered] = useState(false);
  const followerRef = useRef<HTMLSpanElement>(null);

  const handleMouseMove = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (!followerRef.current) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    followerRef.current.style.transform = `translate3d(${x}px, ${y}px, 0)`;
  };

  const handleMouseEnter = (e: React.MouseEvent<HTMLButtonElement>) => {
    setIsHovered(true);
    if (!followerRef.current) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    followerRef.current.style.transform = `translate3d(${x}px, ${y}px, 0)`;
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
  };

  return (
    <button
      type="button"
      className={`demo-video-button ${playing ? 'is-playing' : 'is-paused'}`}
      onClick={onToggle}
      onMouseMove={handleMouseMove}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      aria-label={`${playing ? 'Pause' : 'Play'} synchronized demo`}
    >
      <video
        ref={videoRef}
        autoPlay
        muted
        playsInline
        preload="auto"
        onEnded={onEnded}
        onTimeUpdate={onTimeUpdate}
        onPlay={onPlay}
        onPause={onPause}
        aria-label={label}
      >
        <source src={primarySrc} type="video/mp4" />
        {fallbackSrc && <source src={fallbackSrc} type="video/quicktime" />}
      </video>
      <span
        ref={followerRef}
        className={`demo-cursor-follower ${isHovered ? 'is-visible' : ''}`}
        aria-hidden="true"
      >
        {playing ? (
          <svg viewBox="0 0 24 24" fill="currentColor">
            <rect x="6" y="5" width="4" height="14" rx="1.5" />
            <rect x="14" y="5" width="4" height="14" rx="1.5" />
          </svg>
        ) : (
          <svg viewBox="0 0 24 24" fill="currentColor" style={{ marginLeft: 2 }}>
            <polygon points="8,5 19,12 8,19" />
          </svg>
        )}
      </span>
    </button>
  );
}

export default function FigureShowcase() {
  const containerRef = useRef<HTMLElement>(null);
  const desktopVideoRef = useRef<HTMLVideoElement>(null);
  const mobileVideoRef = useRef<HTMLVideoElement>(null);
  const userPausedRef = useRef(false);
  const [playing, setPlaying] = useState(true);

  // Play both videos together safely
  const playTogether = useCallback(() => {
    const desktop = desktopVideoRef.current;
    const mobile = mobileVideoRef.current;
    if (!desktop || !mobile) return;

    desktop.muted = true;
    mobile.muted = true;

    const p1 = desktop.play().catch(() => {});
    const p2 = mobile.play().catch(() => {});
    void Promise.all([p1, p2]).then(() => {
      if (!userPausedRef.current) {
        setPlaying(true);
      }
    });
  }, []);

  // Synchronized restart / loop function
  const loopTogether = useCallback(() => {
    const desktop = desktopVideoRef.current;
    const mobile = mobileVideoRef.current;
    if (!desktop || !mobile) return;

    desktop.currentTime = 0;
    mobile.currentTime = 0;
    desktop.muted = true;
    mobile.muted = true;

    const p1 = desktop.play().catch(() => {});
    const p2 = mobile.play().catch(() => {});
    void Promise.all([p1, p2]).then(() => {
      if (!userPausedRef.current) {
        setPlaying(true);
      }
    });
  }, []);

  // Toggle user play / pause
  const togglePlayback = useCallback(() => {
    const desktop = desktopVideoRef.current;
    const mobile = mobileVideoRef.current;
    if (!desktop || !mobile) return;

    const isCurrentlyPaused = desktop.paused || mobile.paused;

    if (!isCurrentlyPaused) {
      userPausedRef.current = true;
      desktop.pause();
      mobile.pause();
      setPlaying(false);
    } else {
      userPausedRef.current = false;
      setPlaying(true);
      desktop.muted = true;
      mobile.muted = true;
      if (
        (desktop.duration && desktop.currentTime >= desktop.duration - 0.2) ||
        (mobile.duration && mobile.currentTime >= mobile.duration - 0.2)
      ) {
        desktop.currentTime = 0;
        mobile.currentTime = 0;
      }
      desktop.play().catch(() => {});
      mobile.play().catch(() => {});
    }
  }, []);

  // Master time update from desktop video: maintains sync and triggers seamless loop
  const handleDesktopTimeUpdate = useCallback(() => {
    const desktop = desktopVideoRef.current;
    const mobile = mobileVideoRef.current;
    if (!desktop || !mobile || userPausedRef.current) return;

    // Seamless loop: trigger restart when reaching end of desktop video
    if (desktop.duration && desktop.currentTime >= desktop.duration - 0.15) {
      loopTogether();
      return;
    }

    // Keep mobile in tight sync with desktop (within 250ms)
    if (!desktop.paused && !mobile.paused && desktop.currentTime > 0.5) {
      const diff = Math.abs(desktop.currentTime - mobile.currentTime);
      if (diff > 0.25) {
        mobile.currentTime = desktop.currentTime;
      }
    }
  }, [loopTogether]);

  // Autoplay and keep looping
  useEffect(() => {
    const desktop = desktopVideoRef.current;
    const mobile = mobileVideoRef.current;

    if (desktop) desktop.muted = true;
    if (mobile) mobile.muted = true;

    // Initial autoplay attempt
    playTogether();

    // In case videos finish buffering slightly later
    const handleCanPlay = () => {
      if (!userPausedRef.current) {
        playTogether();
      }
    };

    desktop?.addEventListener('canplay', handleCanPlay);
    mobile?.addEventListener('canplay', handleCanPlay);

    // If browser restricted autoplay until first interaction, start immediately on first gesture
    const handleFirstGesture = () => {
      if (!userPausedRef.current) {
        playTogether();
      }
      window.removeEventListener('pointerdown', handleFirstGesture);
      window.removeEventListener('keydown', handleFirstGesture);
      window.removeEventListener('scroll', handleFirstGesture);
    };

    window.addEventListener('pointerdown', handleFirstGesture, { passive: true });
    window.addEventListener('keydown', handleFirstGesture, { passive: true });
    window.addEventListener('scroll', handleFirstGesture, { passive: true });

    // Handle tab visibility changes: resume playback when user switches back to tab
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && !userPausedRef.current) {
        playTogether();
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    // IntersectionObserver: ensure demo plays smoothly when scrolled into viewport
    let observer: IntersectionObserver | null = null;
    if (typeof IntersectionObserver !== 'undefined' && containerRef.current) {
      observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting && !userPausedRef.current) {
              playTogether();
            }
          }
        },
        { threshold: 0.15 }
      );
      observer.observe(containerRef.current);
    }

    return () => {
      desktop?.removeEventListener('canplay', handleCanPlay);
      mobile?.removeEventListener('canplay', handleCanPlay);
      window.removeEventListener('pointerdown', handleFirstGesture);
      window.removeEventListener('keydown', handleFirstGesture);
      window.removeEventListener('scroll', handleFirstGesture);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      observer?.disconnect();
    };
  }, [playTogether]);

  return (
    <figure ref={containerRef} className="figure product-demo-showcase" id="live-demo">
      <div className="demo-heading-row">
        <div>
          <span className="demo-kicker">See it in action</span>
          <h2>One deck. Two perfectly synced surfaces.</h2>
        </div>
      </div>

      <div className="device-stage">
        <div className="desktop-demo">
          <div className="device-label">
            <span>01</span>
            <div>
              <strong>macOS host</strong>
              <small>Configure from the notch</small>
            </div>
          </div>
          <div className="macbook-frame">
            <div className="macbook-screen">
              <div className="macbook-camera" />
              <DemoVideo
                primarySrc="/vid/web.mp4"
                fallbackSrc="/vid/web.mov"
                label="NotchDeck running on macOS"
                videoRef={desktopVideoRef}
                playing={playing}
                onToggle={togglePlayback}
                onEnded={loopTogether}
                onTimeUpdate={handleDesktopTimeUpdate}
                onPlay={() => setPlaying(true)}
                onPause={() => {
                  if (userPausedRef.current) setPlaying(false);
                }}
              />
            </div>
            <div className="macbook-lip"><span /></div>
            <div className="macbook-foot" />
          </div>
        </div>

        <div className="mobile-demo">
          <div className="device-label">
            <span>02</span>
            <div>
              <strong>Android deck</strong>
              <small>Tap to launch instantly</small>
            </div>
          </div>
          <div className="phone-frame">
            <div className="phone-button phone-button-top" />
            <div className="phone-button phone-button-bottom" />
            <div className="phone-top-detail" aria-hidden="true">
              <span /><i />
            </div>
            <div className="phone-screen">
              <DemoVideo
                primarySrc="/vid/mobile.mp4"
                label="NotchDeck running on Android"
                videoRef={mobileVideoRef}
                playing={playing}
                onToggle={togglePlayback}
                onEnded={loopTogether}
                onPlay={() => setPlaying(true)}
                onPause={() => {
                  if (userPausedRef.current) setPlaying(false);
                }}
              />
              <div className="ip-privacy-mask" aria-label="Private network address hidden">
                <span>Private IP hidden</span>
              </div>
              <div className="phone-glass-sheen" aria-hidden="true" />
            </div>
            <div className="phone-bottom-detail" aria-hidden="true">
              <i /><i /><span /><i /><i />
            </div>
          </div>

          <p className="phone-demo-caption">
            The real NotchDeck experience — live configuration on macOS and tactile control from Android. Tap either screen to pause the demo.
          </p>
        </div>
      </div>
    </figure>
  );
}
