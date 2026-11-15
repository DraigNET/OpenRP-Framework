'use client'

import { useEffect, useRef, useState, useCallback } from 'react'

interface Region { x: number; y: number; w: number; h: number }
interface ChatSeg { color: string; text: string }

const clamp = (v: number, min: number, max: number) => Math.max(min, Math.min(max, v))

function parseLineForColors(raw: string): ChatSeg[] | null {
  const defaultColor = '#FFFFFF'
  const actionColor = '#D0AEEB'
  const radioColor = '#c99e2a'
  const doColor = '#9ad7ff'

  const line = raw.replace(/\[\d{1,2}:\d{2}:\d{2}\]\s*/, '')
  if (line.trim() === '') return null
  if (line.startsWith('**[')) return [{ color: radioColor, text: line.trim() }]
  if (line.startsWith('* ')) return [{ color: actionColor, text: line.trim() }]
  if (line.toLowerCase().startsWith('/do ')) return [{ color: doColor, text: line.replace(/^\/do\s+/i, '').trim() }]
  if (line.includes('says:')) return [{ color: defaultColor, text: line.trim() }]
  return null
}

export default function ScreenshotTool() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const wrapRef = useRef<HTMLDivElement>(null)
  const chatRef = useRef<HTMLTextAreaElement>(null)

  const [cropMode, setCropMode] = useState(false)
  const [hasPending, setHasPending] = useState(false)
  const [canUndo, setCanUndo] = useState(false)
  const [status, setStatus] = useState('Upload an image to begin.')
  const [fontSize, setFontSize] = useState(0)
  const [chatBg, setChatBg] = useState(false)
  const [filters, setFilters] = useState({ brightness: 0, contrast: 0, saturation: 0, sepia: 0, grayscale: 0 })

  // Mutable rendering state kept in a ref (doesn't trigger re-renders)
  const st = useRef({
    img: null as HTMLImageElement | null,
    imgW: 0, imgH: 0,
    zoom: 1, panX: 0, panY: 0,
    isPanning: false, panStartX: 0, panStartY: 0,
    cropMode: false, isCropping: false, cropStartX: 0, cropStartY: 0,
    activeRegion: null as Region | null,
    pendingCrop: null as Region | null,
    cropStack: [] as Region[],
  })

  // Keep ref's cropMode in sync with state
  useEffect(() => { st.current.cropMode = cropMode }, [cropMode])

  const filterString = useCallback(() => {
    const f = filters
    return `brightness(${100 + f.brightness}%) contrast(${100 + f.contrast}%) saturate(${100 + f.saturation}%) sepia(${f.sepia}%) grayscale(${f.grayscale}%)`
  }, [filters])

  const getDrawRegion = useCallback((): Region => {
    const s = st.current
    return s.activeRegion ? { ...s.activeRegion } : { x: 0, y: 0, w: s.imgW, h: s.imgH }
  }, [])

  const getChatLines = useCallback((): ChatSeg[][] => {
    const raw = chatRef.current?.value ?? ''
    return raw.split('\n')
      .map(l => l.trimEnd())
      .filter(l => l.trim() !== '')
      .map(parseLineForColors)
      .filter((l): l is ChatSeg[] => l !== null)
  }, [])

  const drawChatOverlay = useCallback((tctx: CanvasRenderingContext2D, _outW: number, outH: number, fontPx: number) => {
    const padding = Math.round(fontPx * 0.85)
    const lineHeight = Math.round(fontPx * 1.25)
    const lines = getChatLines()
    if (lines.length === 0) return

    tctx.save()
    tctx.font = `bold ${fontPx}px Tahoma`
    tctx.textBaseline = 'top'
    tctx.lineJoin = 'round'
    tctx.shadowColor = 'transparent'

    const totalHeight = lines.length * lineHeight
    const startY = outH - totalHeight - padding
    const startX = padding

    if (chatBg) {
      const boxPadding = Math.round(fontPx * 0.65)
      let maxW = 0
      for (const segs of lines) {
        let w = 0
        for (const seg of segs) w += tctx.measureText(seg.text).width
        maxW = Math.max(maxW, w)
      }
      tctx.fillStyle = 'rgba(0, 0, 0, 0.35)'
      tctx.fillRect(startX - boxPadding, startY - boxPadding, Math.round(maxW + boxPadding * 2), Math.round(totalHeight + boxPadding * 2))
    }

    let y = startY
    for (const segs of lines) {
      let x = startX
      for (const seg of segs) {
        tctx.lineWidth = Math.max(2, Math.round(fontPx / 7))
        tctx.strokeStyle = '#000000'
        tctx.strokeText(seg.text, x, y)
        tctx.fillStyle = seg.color
        tctx.fillText(seg.text, x, y)
        x += tctx.measureText(seg.text).width
      }
      y += lineHeight
    }
    tctx.restore()
  }, [chatBg, getChatLines])

  const render = useCallback(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const rect = canvas.getBoundingClientRect()
    ctx.clearRect(0, 0, rect.width, rect.height)
    const s = st.current
    if (!s.img) return

    const region = getDrawRegion()

    ctx.save()
    ctx.filter = filterString()
    ctx.translate(s.panX, s.panY)
    ctx.scale(s.zoom, s.zoom)
    ctx.drawImage(s.img, region.x, region.y, region.w, region.h, 0, 0, region.w, region.h)
    ctx.restore()

    let baseFont: number
    if (fontSize === 0) baseFont = clamp(Math.round(region.h * 0.020), 14, 28)
    else baseFont = fontSize

    ctx.save()
    ctx.translate(s.panX, s.panY)
    ctx.scale(s.zoom, s.zoom)
    drawChatOverlay(ctx, region.w, region.h, baseFont)
    ctx.restore()

    // crop preview
    if (s.cropMode && s.pendingCrop) {
      const r = s.pendingCrop
      const sx = s.panX + (r.x - region.x) * s.zoom
      const sy = s.panY + (r.y - region.y) * s.zoom
      const sw = r.w * s.zoom, sh = r.h * s.zoom
      ctx.save()
      ctx.fillStyle = 'rgba(0, 0, 0, 0.45)'
      ctx.fillRect(0, 0, rect.width, rect.height)
      ctx.filter = filterString()
      ctx.drawImage(s.img, r.x, r.y, r.w, r.h, sx, sy, sw, sh)
      ctx.filter = 'none'
      ctx.strokeStyle = '#ffffff'
      ctx.lineWidth = 2
      ctx.strokeRect(sx, sy, sw, sh)
      ctx.restore()
    }

    setHasPending(!!s.pendingCrop)
    setCanUndo(s.cropStack.length > 0)
    setStatus('Ready.')
  }, [filterString, fontSize, drawChatOverlay, getDrawRegion])

  const resizeCanvas = useCallback(() => {
    const canvas = canvasRef.current
    const wrap = wrapRef.current
    if (!canvas || !wrap) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const rect = wrap.getBoundingClientRect()
    const dpr = window.devicePixelRatio || 1
    canvas.width = Math.max(1, Math.floor(rect.width * dpr))
    canvas.height = Math.max(1, Math.floor(rect.height * dpr))
    canvas.style.width = `${rect.width}px`
    canvas.style.height = `${rect.height}px`
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  }, [])

  const resetView = useCallback(() => {
    const canvas = canvasRef.current
    const s = st.current
    if (!canvas || !s.img) return
    const rect = canvas.getBoundingClientRect()
    const region = getDrawRegion()
    const fit = Math.min(rect.width / region.w, rect.height / region.h)
    s.zoom = fit
    s.panX = (rect.width - region.w * fit) / 2
    s.panY = (rect.height - region.h * fit) / 2
    render()
  }, [getDrawRegion, render])

  const screenToImage = useCallback((sx: number, sy: number) => {
    const canvas = canvasRef.current!
    const rect = canvas.getBoundingClientRect()
    const s = st.current
    const region = getDrawRegion()
    const localX = (sx - rect.left - s.panX) / s.zoom
    const localY = (sy - rect.top - s.panY) / s.zoom
    return { x: region.x + localX, y: region.y + localY }
  }, [getDrawRegion])

  // Re-render whenever filters / fontSize / chatBg change
  useEffect(() => { render() }, [render])

  // Initial setup + global mouse listeners
  useEffect(() => {
    resizeCanvas()
    // (status already defaults to "Upload an image to begin." — no setState needed here)

    const onResize = () => { if (st.current.img) render(); else resizeCanvas() }
    window.addEventListener('resize', onResize)

    const onMove = (e: MouseEvent) => {
      const s = st.current
      if (!s.img) return
      if (s.isCropping && s.cropMode && s.pendingCrop) {
        const p = screenToImage(e.clientX, e.clientY)
        s.pendingCrop = {
          x: Math.min(s.cropStartX, p.x), y: Math.min(s.cropStartY, p.y),
          w: Math.abs(s.cropStartX - p.x), h: Math.abs(s.cropStartY - p.y),
        }
        render()
        return
      }
      if (!s.isPanning) return
      s.panX = e.clientX - s.panStartX
      s.panY = e.clientY - s.panStartY
      render()
    }
    const onUp = () => {
      const s = st.current
      if (!s.img) { s.isPanning = false; s.isCropping = false; return }
      if (s.isCropping && s.cropMode) {
        s.isCropping = false
        if (s.pendingCrop && (s.pendingCrop.w < 10 || s.pendingCrop.h < 10)) s.pendingCrop = null
        render()
        return
      }
      s.isPanning = false
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('resize', onResize)
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [render, resizeCanvas, screenToImage])

  function onUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = () => {
      const img = new Image()
      img.onload = () => {
        const s = st.current
        s.img = img; s.imgW = img.width; s.imgH = img.height
        s.activeRegion = { x: 0, y: 0, w: img.width, h: img.height }
        s.pendingCrop = null; s.cropStack = []
        setStatus('Image loaded.')
        resetView()
      }
      img.src = reader.result as string
    }
    reader.readAsDataURL(file)
  }

  function onWheel(e: React.WheelEvent) {
    const s = st.current
    if (!s.img) return
    const canvas = canvasRef.current!
    const zoomFactor = Math.sign(e.deltaY) > 0 ? 0.90 : 1.10
    const before = screenToImage(e.clientX, e.clientY)
    const region = getDrawRegion()
    const bLocalX = before.x - region.x, bLocalY = before.y - region.y
    s.zoom = clamp(s.zoom * zoomFactor, 0.05, 15)
    const rect = canvas.getBoundingClientRect()
    const afterX = bLocalX * s.zoom + s.panX, afterY = bLocalY * s.zoom + s.panY
    s.panX += (e.clientX - rect.left) - afterX
    s.panY += (e.clientY - rect.top) - afterY
    render()
  }

  function onMouseDown(e: React.MouseEvent) {
    const s = st.current
    if (!s.img) return
    if (s.cropMode) {
      s.isCropping = true
      const p = screenToImage(e.clientX, e.clientY)
      s.cropStartX = p.x; s.cropStartY = p.y
      s.pendingCrop = { x: p.x, y: p.y, w: 0, h: 0 }
      render()
      return
    }
    s.isPanning = true
    s.panStartX = e.clientX - s.panX
    s.panStartY = e.clientY - s.panY
  }

  function toggleCrop() {
    const s = st.current
    const next = !cropMode
    s.cropMode = next; s.isCropping = false
    if (!next) s.pendingCrop = null
    setCropMode(next)
    render()
  }

  function applyCrop() {
    const s = st.current
    if (!s.img || !s.pendingCrop) return
    s.cropStack.push(getDrawRegion())
    const r = s.pendingCrop
    r.x = clamp(r.x, 0, s.imgW - 1); r.y = clamp(r.y, 0, s.imgH - 1)
    r.w = clamp(r.w, 1, s.imgW - r.x); r.h = clamp(r.h, 1, s.imgH - r.y)
    s.activeRegion = { ...r }
    s.pendingCrop = null; s.cropMode = false
    setCropMode(false)
    resetView()
  }

  function cancelCrop() {
    const s = st.current
    s.pendingCrop = null; s.cropMode = false; s.isCropping = false
    setCropMode(false)
    render()
  }

  function undoCrop() {
    const s = st.current
    if (s.cropStack.length === 0) return
    s.activeRegion = s.cropStack.pop()!
    s.pendingCrop = null; s.cropMode = false
    setCropMode(false)
    resetView()
  }

  function resetFilters() {
    setFilters({ brightness: 0, contrast: 0, saturation: 0, sepia: 0, grayscale: 0 })
  }

  function download() {
    const s = st.current
    if (!s.img) { alert('Please upload an image first.'); return }
    const region = getDrawRegion()
    const out = document.createElement('canvas')
    out.width = region.w; out.height = region.h
    const octx = out.getContext('2d')!
    octx.save()
    octx.filter = filterString()
    octx.drawImage(s.img, region.x, region.y, region.w, region.h, 0, 0, region.w, region.h)
    octx.restore()
    const fontPx = fontSize === 0 ? clamp(Math.round(region.h * 0.020), 18, 36) : fontSize
    drawChatOverlay(octx, region.w, region.h, fontPx)
    const n = new Date()
    const p = (x: number) => String(x).padStart(2, '0')
    const filename = `sampscreen_${p(n.getDate())}_${p(n.getMonth() + 1)}_${n.getFullYear()}_${p(n.getHours())}_${p(n.getMinutes())}_${p(n.getSeconds())}.png`
    const link = document.createElement('a')
    link.href = out.toDataURL('image/png')
    link.download = filename
    link.click()
  }

  const sliderRow = (label: string, key: keyof typeof filters, min = -100, max = 100) => (
    <div>
      <div className="panel-range-row">
        <span className="panel-label">{label}</span>
        <span className="panel-range-val">{filters[key]}</span>
      </div>
      <input type="range" className="panel-range" min={min} max={max} value={filters[key]}
        onChange={e => setFilters(f => ({ ...f, [key]: Number(e.target.value) }))} />
    </div>
  )

  return (
    <div className="shot-layout">
      {/* INPUT PANEL */}
      <div className="shot-panel">
        <div className="panel-title">Input</div>
        <span className="panel-label">Screenshot</span>
        <input type="file" accept="image/*" className="panel-input" onChange={onUpload} />
        <span className="panel-label">Chat Log</span>
        <textarea ref={chatRef} className="panel-textarea" placeholder="Paste chat here…" onChange={render} />
        <p className="panel-hint">Displays /me, /do, /r (radio) and IC chat (lines ending with &quot;says:&quot;).</p>
        <div className="panel-buttons">
          <button className={`panel-btn ${cropMode ? 'panel-btn-primary' : ''}`} onClick={toggleCrop}>
            {cropMode ? 'Crop Mode: ON' : 'Crop Mode'}
          </button>
          {cropMode && hasPending && <button className="panel-btn panel-btn-primary" onClick={applyCrop}>Apply Crop</button>}
          {cropMode && hasPending && <button className="panel-btn" onClick={cancelCrop}>Cancel Crop</button>}
          {canUndo && <button className="panel-btn" onClick={undoCrop}>Undo Crop</button>}
          <button className="panel-btn" onClick={resetView}>Reset View</button>
          <button className="panel-btn panel-btn-primary" onClick={download}>Download PNG</button>
        </div>
      </div>

      {/* CANVAS */}
      <div className="shot-canvas">
        <div className="canvas-topbar">
          <span className="canvas-status">{status}</span>
          <span className="canvas-tip">Mouse wheel: zoom • Drag: pan • Crop Mode: drag a box</span>
        </div>
        <div className="canvas-wrap" ref={wrapRef}>
          <canvas id="resultCanvas" ref={canvasRef} onWheel={onWheel} onMouseDown={onMouseDown}
            style={{ cursor: cropMode ? 'crosshair' : 'grab' }} />
        </div>
      </div>

      {/* FILTERS */}
      <div className="shot-panel">
        <div className="panel-title">Filters</div>
        {sliderRow('Brightness', 'brightness')}
        {sliderRow('Contrast', 'contrast')}
        {sliderRow('Saturation', 'saturation')}
        {sliderRow('Sepia', 'sepia', 0, 100)}
        {sliderRow('Grayscale', 'grayscale', 0, 100)}
        <div>
          <div className="panel-range-row">
            <span className="panel-label">Font Size</span>
            <span className="panel-range-val">{fontSize === 0 ? 'Auto' : `${fontSize}px`}</span>
          </div>
          <input type="range" className="panel-range" min={0} max={48} value={fontSize}
            onChange={e => setFontSize(Number(e.target.value))} />
        </div>
        <label className="panel-check">
          <input type="checkbox" checked={chatBg} onChange={e => setChatBg(e.target.checked)} />
          Chat background box
        </label>
        <div className="panel-buttons">
          <button className="panel-btn" onClick={resetFilters}>Reset Filters</button>
        </div>
      </div>
    </div>
  )
}
