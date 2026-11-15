'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { ADMIN_LVL } from '@/lib/constants'

interface Props {
  staffLevel: number
}

type ServerState = 'checking' | 'running' | 'offline' | 'error'

export default function ServerConsole({ staffLevel }: Props) {
  const canStart   = staffLevel >= ADMIN_LVL.LEAD
  const canStop    = staffLevel >= ADMIN_LVL.MANAGER
  const canConsole = staffLevel >= ADMIN_LVL.DEVELOPER

  const [serverState, setServerState] = useState<ServerState>('checking')
  const [actionBusy, setActionBusy]   = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)

  // scheduleFireAt: Unix ms timestamp from server, null = no schedule
  const [scheduleFireAt, setScheduleFireAt] = useState<number | null>(null)
  const [scheduleInput, setScheduleInput]   = useState('30')
  const [scheduleModal, setScheduleModal]   = useState(false)
  // Client-side display counter derived from scheduleFireAt
  const [remaining, setRemaining] = useState<number | null>(null)
  const countdownRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const [logs, setLogs]       = useState<string[]>([])
  const [cmd, setCmd]         = useState('')
  const [cmdBusy, setCmdBusy] = useState(false)
  const logEndRef = useRef<HTMLDivElement>(null)
  const esRef     = useRef<EventSource | null>(null)

  // ── Status polling ──────────────────────────────────────────
  const fetchStatus = useCallback(async () => {
    try {
      const res  = await fetch('/api/samp/status', { cache: 'no-store' })
      const data = await res.json()
      if (!res.ok) { setServerState('error'); return }
      setServerState(data.running ? 'running' : 'offline')
    } catch {
      setServerState('error')
    }
  }, [])

  useEffect(() => {
    const id = setInterval(fetchStatus, 3_000)
    setTimeout(fetchStatus, 0)
    return () => clearInterval(id)
  }, [fetchStatus])

  // ── Sync schedule from server on mount ─────────────────────
  useEffect(() => {
    fetch('/api/samp/schedule', { cache: 'no-store' })
      .then(r => r.json())
      .then(data => { if (data.fireAt) setScheduleFireAt(data.fireAt) })
      .catch(() => {})
  }, [])

  // ── Drive the countdown display from scheduleFireAt ────────
  useEffect(() => {
    if (countdownRef.current) { clearInterval(countdownRef.current); countdownRef.current = null }
    if (!scheduleFireAt) { setTimeout(() => setRemaining(null), 0); return }

    function tick() {
      const secs = Math.max(0, Math.round((scheduleFireAt! - Date.now()) / 1000))
      setRemaining(secs)
      if (secs <= 0) {
        clearInterval(countdownRef.current!)
        countdownRef.current = null
        setScheduleFireAt(null)
        setTimeout(fetchStatus, 2000)
      }
    }
    tick()
    countdownRef.current = setInterval(tick, 1000)
    return () => { if (countdownRef.current) clearInterval(countdownRef.current) }
  }, [scheduleFireAt, fetchStatus])

  // ── SSE console stream (Developer only) ────────────────────
  useEffect(() => {
    if (!canConsole) return

    const es = new EventSource('/api/samp/stream')
    esRef.current = es

    es.onmessage = (e) => {
      try {
        const line = JSON.parse(e.data) as string
        if (line.includes('[agent] SAMP started')) setServerState('running')
        if (line.includes('[agent] SAMP exited'))  setServerState('offline')
        setLogs((prev) => [...prev.slice(-999), line])
      } catch { /* ignore malformed */ }
    }

    es.onerror = () => {
      setLogs((prev) => [...prev, '[console] Connection lost — reconnecting…'])
    }

    return () => { es.close(); esRef.current = null }
  }, [canConsole])

  // Auto-scroll log to bottom
  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [logs])

  // ── Actions ─────────────────────────────────────────────────
  async function runAction(endpoint: string) {
    setActionBusy(true)
    setActionError(null)
    try {
      const res  = await fetch(`/api/samp/${endpoint}`, { method: 'POST' })
      const data = await res.json()
      if (!res.ok || data.ok === false) {
        setActionError(data.error ?? 'Unknown error')
      } else {
        setTimeout(fetchStatus, 1500)
      }
    } catch {
      setActionError('Request failed')
    } finally {
      setActionBusy(false)
    }
  }

  async function startSchedule() {
    const secs = parseInt(scheduleInput, 10)
    if (!secs || secs < 1) return
    setScheduleModal(false)
    try {
      const res  = await fetch('/api/samp/schedule', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ seconds: secs }),
      })
      const data = await res.json()
      if (data.fireAt) setScheduleFireAt(data.fireAt)
    } catch { /* ignore */ }
  }

  async function cancelSchedule() {
    await fetch('/api/samp/schedule', { method: 'DELETE' }).catch(() => {})
    setScheduleFireAt(null)
  }

  function fmtCountdown(s: number) {
    const m = Math.floor(s / 60).toString().padStart(2, '0')
    const sec = (s % 60).toString().padStart(2, '0')
    return `${m}:${sec}`
  }

  async function sendCmd(e: React.FormEvent) {
    e.preventDefault()
    const trimmed = cmd.trim()
    if (!trimmed || cmdBusy) return
    setCmdBusy(true)
    try {
      await fetch('/api/samp/cmd', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: trimmed }),
      })
      setCmd('')
    } finally {
      setCmdBusy(false)
    }
  }

  // ── Render helpers ──────────────────────────────────────────
  const statusDot = serverState === 'running' ? 'is-green'
    : serverState === 'checking'             ? 'is-amber'
    : 'is-red'

  const statusLabel = {
    running:  'RUNNING',
    offline:  'OFFLINE',
    checking: 'CHECKING…',
    error:    'UNREACHABLE',
  }[serverState]

  return (
    <div className="samp-page">

      {/* ── Status + controls ── */}
      <div className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head">
          <span>Server Control</span>
        </div>

        <div className="acp-kv">
          <div className="acp-kv-row">
            <span>Status</span>
            <b>
              <span className={`acp-dot ${statusDot}`} />
              {statusLabel}
            </b>
          </div>
        </div>

        <div style={{ padding: '12px 14px', display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
          {canStart && (
            <button
              className="acp-btn acp-btn-success"
              disabled={actionBusy || serverState === 'running'}
              onClick={() => runAction('start')}
            >
              <i className="fa-solid fa-play" /> Start Server
            </button>
          )}
          {canStart && serverState !== 'running' && remaining === null && (
            <button
              className="acp-btn"
              style={{ background: '#c96a00', color: '#fff', borderColor: '#c96a00' }}
              disabled={actionBusy}
              onClick={() => setScheduleModal(true)}
            >
              <i className="fa-solid fa-clock" /> Schedule Start
            </button>
          )}
          {remaining !== null && (
            <>
              <span style={{ fontVariantNumeric: 'tabular-nums', fontSize: 13, color: 'var(--acp-text-1)' }}>
                <i className="fa-solid fa-clock" style={{ marginRight: 6, color: '#e07b00' }} />
                Starting in <b>{fmtCountdown(remaining)}</b>
              </span>
              <button className="acp-btn acp-btn-danger" style={{ padding: '4px 10px', fontSize: 12 }} onClick={cancelSchedule}>
                Cancel
              </button>
            </>
          )}
          {canStop && (
            <button
              className="acp-btn acp-btn-danger"
              disabled={actionBusy || serverState !== 'running'}
              onClick={() => runAction('stop')}
            >
              <i className="fa-solid fa-stop" /> Stop Server
            </button>
          )}
          {actionBusy && <span style={{ color: 'var(--acp-text-2)', alignSelf: 'center', fontSize: 12 }}>Working…</span>}
          {actionError && <span className="acp-badge is-red" style={{ alignSelf: 'center' }}>{actionError}</span>}
        </div>
      </div>

      {/* ── Schedule Start modal ── */}
      {scheduleModal && (
        <div
          style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}
          onClick={() => setScheduleModal(false)}
        >
          <div
            style={{ background: 'var(--acp-panel-bg)', border: '1px solid var(--acp-border)', borderRadius: 8, padding: 24, minWidth: 280, boxShadow: '0 8px 32px rgba(0,0,0,0.5)' }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ fontWeight: 600, fontSize: 15, marginBottom: 16 }}>
              <i className="fa-solid fa-clock" style={{ marginRight: 8, color: '#e07b00' }} />
              Schedule Server Start
            </div>
            <label style={{ fontSize: 12, color: 'var(--acp-text-2)', display: 'block', marginBottom: 6 }}>Start in (seconds)</label>
            <input
              type="number"
              min={1}
              autoFocus
              value={scheduleInput}
              onChange={(e) => setScheduleInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && startSchedule()}
              style={{ width: '100%', padding: '8px 10px', borderRadius: 4, border: '1px solid var(--acp-border)', background: 'var(--acp-input-bg)', color: 'var(--acp-text-1)', fontSize: 15, marginBottom: 16, boxSizing: 'border-box' }}
            />
            <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
              <button className="acp-btn" onClick={() => setScheduleModal(false)}>Cancel</button>
              <button
                className="acp-btn"
                style={{ background: '#c96a00', color: '#fff', borderColor: '#c96a00' }}
                onClick={startSchedule}
              >
                Start Timer
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Console (Developer only) ── */}
      {canConsole && (
        <div className="acp-panel">
          <div className="acp-panel-head">
            <span>Console</span>
            <button
              className="acp-btn"
              style={{ fontSize: 11, padding: '4px 10px' }}
              onClick={() => setLogs([])}
            >
              Clear
            </button>
          </div>

          <div className="samp-console-output">
            {logs.length === 0 && (
              <div className="samp-console-empty">Waiting for output…</div>
            )}
            {logs.map((line, i) => (
              <div key={i} className="samp-console-line">{line}</div>
            ))}
            <div ref={logEndRef} />
          </div>

          <form onSubmit={sendCmd} className="samp-console-input-row">
            <span className="samp-console-prompt">&gt;</span>
            <input
              className="samp-console-input"
              type="text"
              placeholder="Enter RCON command…"
              value={cmd}
              onChange={(e) => setCmd(e.target.value)}
              disabled={cmdBusy || serverState !== 'running'}
              autoComplete="off"
              spellCheck={false}
            />
            <button
              className="acp-btn acp-btn-primary"
              type="submit"
              disabled={cmdBusy || !cmd.trim() || serverState !== 'running'}
            >
              Send
            </button>
          </form>
        </div>
      )}
    </div>
  )
}
