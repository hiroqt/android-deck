'use client';

import { useEffect, useRef, useState, useCallback } from 'react';

export default function CtaMacbookDemo() {
  const containerRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const followerRef = useRef<HTMLSpanElement>(null);
  const userPausedRef = useRef(false);
  const [playing, setPlaying] = useState(true);
  const [isHovered, setIsHovered] = useState(false);

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

  const startPlayback = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    video.muted = true;
    video.play().then(() => {
      if (!userPausedRef.current) {
        setPlaying(true);
      }
    }).catch(() => {});
  }, []);

  const handleLoop = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    video.currentTime = 0;
    video.muted = true;
    video.play().then(() => {
      if (!userPausedRef.current) {
        setPlaying(true);
      }
    }).catch(() => {});
  }, []);

  const togglePlayback = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;

    if (!video.paused) {
      userPausedRef.current = true;
      video.pause();
      setPlaying(false);
    } else {
      userPausedRef.current = false;
      setPlaying(true);
      video.muted = true;
      if (video.duration && video.currentTime >= video.duration - 0.2) {
        video.currentTime = 0;
      }
      video.play().catch(() => {});
    }
  }, []);

  useEffect(() => {
    const video = videoRef.current;
    if (video) {
      video.muted = true;
    }

    startPlayback();

    const handleCanPlay = () => {
      if (!userPausedRef.current) {
        startPlayback();
      }
    };

    video?.addEventListener('canplay', handleCanPlay);

    const handleFirstGesture = () => {
      if (!userPausedRef.current) {
        startPlayback();
      }
      window.removeEventListener('pointerdown', handleFirstGesture);
      window.removeEventListener('keydown', handleFirstGesture);
      window.removeEventListener('scroll', handleFirstGesture);
    };

    window.addEventListener('pointerdown', handleFirstGesture, { passive: true });
    window.addEventListener('keydown', handleFirstGesture, { passive: true });
    window.addEventListener('scroll', handleFirstGesture, { passive: true });

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible' && !userPausedRef.current) {
        startPlayback();
      }
    };
    document.addEventListener('visibilitychange', handleVisibilityChange);

    let observer: IntersectionObserver | null = null;
    if (typeof IntersectionObserver !== 'undefined' && containerRef.current) {
      observer = new IntersectionObserver(
        (entries) => {
          for (const entry of entries) {
            if (entry.isIntersecting && !userPausedRef.current) {
              startPlayback();
            }
          }
        },
        { threshold: 0.15 }
      );
      observer.observe(containerRef.current);
    }

    return () => {
      video?.removeEventListener('canplay', handleCanPlay);
      window.removeEventListener('pointerdown', handleFirstGesture);
      window.removeEventListener('keydown', handleFirstGesture);
      window.removeEventListener('scroll', handleFirstGesture);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      observer?.disconnect();
    };
  }, [startPlayback]);

  return (
    <div ref={containerRef} className="cta-macbook-container">
      <div className="macbook-frame">
        <div className="macbook-screen">
          <div className="macbook-camera" />
          <button
            type="button"
            className={`demo-video-button ${playing ? 'is-playing' : 'is-paused'}`}
            onClick={togglePlayback}
            onMouseMove={handleMouseMove}
            onMouseEnter={handleMouseEnter}
            onMouseLeave={handleMouseLeave}
            aria-label={`${playing ? 'Pause' : 'Play'} desktop notch demo`}
          >
            <video
              ref={videoRef}
              autoPlay
              loop
              muted
              playsInline
              preload="auto"
              onEnded={handleLoop}
              onPlay={() => setPlaying(true)}
              onPause={() => {
                if (userPausedRef.current) setPlaying(false);
              }}
              aria-label="NotchDeck camera notch running on macOS desktop"
            >
              <source src="/vid/desktop_notch.mp4" type="video/mp4" />
              <source src="/vid/desktop_notch.mov" type="video/quicktime" />
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
        </div>
        <div className="macbook-lip"><span /></div>
        <div className="macbook-foot" />
      </div>
    </div>
  );
}
