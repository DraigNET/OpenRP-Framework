'use client'

import { useEffect, useRef, useCallback } from 'react'

export interface TurfZone {
  x: number; y: number; w: number; h: number
  fill: string; faction: string; contested: boolean
}

const IMG_SIZE = 6144

export default function TurfMap({ zones }: { zones: TurfZone[] }) {
  const containerRef = useRef<HTMLDivElement>(null)
  const stageRef = useRef<HTMLDivElement>(null)
  const tooltipRef = useRef<HTMLDivElement>(null)
  const view = useRef({ scale: 1, minScale: 1, maxScale: 2.5, x: 0, y: 0 })
  const drag = useRef({ active: false, sx: 0, sy: 0, ox: 0, oy: 0 })

  const clampAndApply = useCallback(() => {
    const container = containerRef.current
    const stage = stageRef.current
    if (!container || !stage) return
    const v = view.current
    const cw = container.clientWidth, ch = container.clientHeight
    const sw = IMG_SIZE * v.scale, sh = IMG_SIZE * v.scale
    v.x = sw <= cw ? (cw - sw) / 2 : Math.max(cw - sw, Math.min(0, v.x))
    v.y = sh <= ch ? (ch - sh) / 2 : Math.max(ch - sh, Math.min(0, v.y))
    stage.style.transform = `translate(${v.x}px, ${v.y}px) scale(${v.scale})`
  }, [])

  const resetView = useCallback(() => {
    const container = containerRef.current
    if (!container) return
    const v = view.current
    v.minScale = Math.max(container.clientWidth / IMG_SIZE, container.clientHeight / IMG_SIZE)
    v.scale = v.minScale
    v.x = (container.clientWidth - IMG_SIZE * v.scale) / 2
    v.y = (container.clientHeight - IMG_SIZE * v.scale) / 2
    clampAndApply()
  }, [clampAndApply])

  useEffect(() => {
    resetView()
    window.addEventListener('resize', resetView)
    return () => window.removeEventListener('resize', resetView)
  }, [resetView])

  const zoomAt = useCallback((factor: number, clientX: number, clientY: number) => {
    const container = containerRef.current
    if (!container) return
    const rect = container.getBoundingClientRect()
    const mx = clientX - rect.left, my = clientY - rect.top
    const v = view.current
    const old = v.scale
    v.scale = Math.max(v.minScale, Math.min(v.maxScale, v.scale * factor))
    v.x = mx - (mx - v.x) * (v.scale / old)
    v.y = my - (my - v.y) * (v.scale / old)
    clampAndApply()
  }, [clampAndApply])

  // Register wheel as a non-passive native listener so preventDefault() actually
  // stops the page from scrolling while zooming (React's onWheel is passive).
  useEffect(() => {
    const container = containerRef.current
    if (!container) return
    const onWheel = (e: WheelEvent) => {
      e.preventDefault()
      zoomAt(e.deltaY < 0 ? 1.12 : 0.88, e.clientX, e.clientY)
    }
    container.addEventListener('wheel', onWheel, { passive: false })
    return () => container.removeEventListener('wheel', onWheel)
  }, [zoomAt])

  function onPointerDown(e: React.PointerEvent) {
    if ((e.target as HTMLElement).closest('#turf-zoom-controls')) return
    if (e.button !== 0) return
    drag.current = { active: true, sx: e.clientX, sy: e.clientY, ox: view.current.x, oy: view.current.y }
    containerRef.current?.setPointerCapture(e.pointerId)
  }
  function onPointerMove(e: React.PointerEvent) {
    if (!drag.current.active) return
    view.current.x = drag.current.ox + (e.clientX - drag.current.sx)
    view.current.y = drag.current.oy + (e.clientY - drag.current.sy)
    clampAndApply()
  }
  function onPointerUp() { drag.current.active = false }

  function showTooltip(text: string, clientX: number, clientY: number) {
    const container = containerRef.current
    const tip = tooltipRef.current
    if (!container || !tip) return
    const rect = container.getBoundingClientRect()
    tip.textContent = text
    tip.style.opacity = '1'
    let left = clientX - rect.left + 12
    let top = clientY - rect.top - 16
    left = Math.max(8, Math.min(rect.width - tip.offsetWidth - 8, left))
    top = Math.max(8, Math.min(rect.height - tip.offsetHeight - 8, top))
    tip.style.left = `${left}px`
    tip.style.top = `${top}px`
  }
  function hideTooltip() {
    if (tooltipRef.current) tooltipRef.current.style.opacity = '0'
  }

  return (
    <div id="turf-map" ref={containerRef}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerUp}
      onDragStart={e => e.preventDefault()}>

      <div id="turf-zoom-controls">
        <button type="button" onClick={() => { const r = containerRef.current!.getBoundingClientRect(); zoomAt(1.2, r.left + r.width / 2, r.top + r.height / 2) }} aria-label="Zoom in">+</button>
        <button type="button" onClick={() => { const r = containerRef.current!.getBoundingClientRect(); zoomAt(1 / 1.2, r.left + r.width / 2, r.top + r.height / 2) }} aria-label="Zoom out">−</button>
      </div>

      <div id="turf-tooltip" ref={tooltipRef} role="tooltip" />

      <div id="turf-stage" ref={stageRef}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/img/turfmap.png" alt="San Andreas Map" draggable={false} />
        <svg id="turf-overlay" width={IMG_SIZE} height={IMG_SIZE} viewBox={`0 0 ${IMG_SIZE} ${IMG_SIZE}`} xmlns="http://www.w3.org/2000/svg">
          {zones.map((z, i) => (
            <rect key={i}
              x={z.x} y={z.y} width={z.w} height={z.h}
              fill={z.fill} fillOpacity={0.55}
              stroke="#ffffff" strokeOpacity={0.55} strokeWidth={1}
              strokeDasharray={z.contested ? '6,4' : undefined}
              className="turf-rect"
              onMouseEnter={e => showTooltip(z.faction + (z.contested ? ' (Contested)' : ''), e.clientX, e.clientY)}
              onMouseMove={e => showTooltip(z.faction + (z.contested ? ' (Contested)' : ''), e.clientX, e.clientY)}
              onMouseLeave={hideTooltip}
            />
          ))}
        </svg>
      </div>
    </div>
  )
}
