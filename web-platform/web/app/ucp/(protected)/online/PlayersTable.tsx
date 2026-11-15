'use client'

import { useMemo, useState } from 'react'

export interface PlayerRow {
  id: number
  name: string
  faction: string | null
  isLaw: boolean
  score: number
  ping: number | null
}

const HUES = [32, 8, 150, 205, 265, 330, 50, 180, 300, 20]

function PingBars({ ping }: { ping: number | null }) {
  if (ping === null) return <span className="ucp-muted">—</span>
  const bars = ping < 60 ? 4 : ping < 100 ? 3 : ping < 140 ? 2 : 1
  const cls = ping < 60 ? '' : ping < 120 ? 'mid' : 'bad'
  return (
    <>
      <span className={`ucp-ping ${cls}`}>
        {[1, 2, 3, 4].map(b => <i key={b} className={b <= bars ? 'on' : ''} style={{ height: `${b * 25}%` }} />)}
      </span>
      {ping} ms
    </>
  )
}

export default function PlayersTable({ rows }: { rows: PlayerRow[] }) {
  const [q, setQ] = useState('')
  const [tab, setTab] = useState<'all' | 'law' | 'civ'>('all')

  const shown = useMemo(() => rows.filter(r => {
    if (tab === 'law' && !r.isLaw) return false
    if (tab === 'civ' && r.isLaw) return false
    return r.name.toLowerCase().includes(q.toLowerCase())
  }), [rows, q, tab])

  return (
    <div className="ucp-card">
      <div className="ucp-toolbar">
        <input className="ucp-input" placeholder="Search players…" value={q} onChange={e => setQ(e.target.value)} />
        <div className="ucp-seg">
          <button className={tab === 'all' ? 'on' : ''} onClick={() => setTab('all')}>All</button>
          <button className={tab === 'law' ? 'on' : ''} onClick={() => setTab('law')}>Law enforcement</button>
          <button className={tab === 'civ' ? 'on' : ''} onClick={() => setTab('civ')}>Civilians</button>
        </div>
        <span className="ucp-chip ucp-chip-good" style={{ marginLeft: 'auto' }}><i className="ucp-pulse" style={{ color: 'var(--good)' }} /> Auto-refreshing · 10s</span>
      </div>

      {shown.length === 0 ? (
        <div className="ucp-muted" style={{ padding: 20, textAlign: 'center' }}>No players match.</div>
      ) : (
        <table className="ucp-table">
          <thead><tr><th>Player</th><th>Faction</th><th>Score</th><th>Ping</th></tr></thead>
          <tbody>
            {shown.map(r => (
              <tr key={r.id}>
                <td>
                  <div className="ucp-pl">
                    <div className="ucp-av" style={{ background: `hsl(${HUES[r.id % HUES.length]} 60% 65%)` }}>{r.name[0]?.toUpperCase()}</div>
                    <b style={{ color: 'var(--text-1)' }}>{r.name.replace(/_/g, ' ')}</b>
                  </div>
                </td>
                <td><span className={`ucp-chip ${r.faction ? 'ucp-chip-acc' : ''}`}>{r.faction ?? 'Civilian'}</span></td>
                <td className="ucp-mono">{r.score}</td>
                <td><PingBars ping={r.ping} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
