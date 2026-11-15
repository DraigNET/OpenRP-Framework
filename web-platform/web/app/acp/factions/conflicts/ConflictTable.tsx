'use client'

import { useEffect, useState } from 'react'

export interface ConflictRow {
  id: number
  status: 'active' | 'expired'
  faction: string
  type: string
  enemy: string
  attackerDeaths: number
  defenderDeaths: number
  outcome: string
  location: string
  loggedBy: string
  time: string
  loggedAt: string
  description: string
}

export default function ConflictTable({ rows }: { rows: ConflictRow[] }) {
  const [active, setActive] = useState<ConflictRow | null>(null)

  useEffect(() => {
    if (!active) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') setActive(null) }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [active])

  if (rows.length === 0) {
    return <div className="acp-empty"><i className="fa-solid fa-fire" />No conflict logs found for this view.</div>
  }

  return (
    <>
      <table className="acp-table acp-table-click">
        <thead>
          <tr>
            <th>Status</th><th>Faction</th><th>Type</th><th>Opposing Gang</th>
            <th>Deaths</th><th>Outcome</th><th>Location</th><th>Logged By</th>
            <th>Conflict Time</th><th>Logged At</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(r => (
            <tr key={r.id} onClick={() => setActive(r)} title="View details">
              <td><span className={`acp-badge ${r.status === 'active' ? 'is-amber' : 'is-green'}`}>{r.status === 'active' ? 'On Cooldown' : 'Expired'}</span></td>
              <td className="acp-td-name"><b>{r.faction}</b></td>
              <td><span className="acp-badge is-off">{r.type}</span></td>
              <td className="acp-td-name">{r.enemy}</td>
              <td className="acp-td-muted">{r.attackerDeaths} / {r.defenderDeaths}</td>
              <td className="acp-td-muted">{r.outcome}</td>
              <td className="acp-td-detail" title={r.location}>{r.location || '—'}</td>
              <td className="acp-td-muted">{r.loggedBy}</td>
              <td className="acp-td-muted">{r.time}</td>
              <td className="acp-td-muted">{r.loggedAt}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {active && (
        <div className="acp-modal-backdrop" role="presentation" onClick={e => { if (e.target === e.currentTarget) setActive(null) }}>
          <div className="acp-panel acp-modal" role="dialog" aria-modal="true" aria-label="Conflict details" style={{ maxWidth: 560 }}>
            <div className="acp-panel-head">
              <span><i className="fa-solid fa-fire" style={{ marginRight: 8, color: 'var(--acp-accent)' }} />Conflict #{active.id}</span>
              <button type="button" className="acp-modal-close" onClick={() => setActive(null)} aria-label="Close"><i className="fa-solid fa-xmark" /></button>
            </div>
            <div className="acp-modal-body">
              <div className="acp-kv">
                <div className="acp-kv-row"><span>Faction</span><b>{active.faction}</b></div>
                <div className="acp-kv-row"><span>Type</span><b>{active.type}</b></div>
                <div className="acp-kv-row"><span>Status</span><b>{active.status === 'active' ? 'Active Cooldown' : 'Cooldown Expired'}</b></div>
                <div className="acp-kv-row"><span>Opposing Gang</span><b>{active.enemy}</b></div>
                <div className="acp-kv-row"><span>Deaths</span><b>{active.attackerDeaths} attacker / {active.defenderDeaths} defender</b></div>
                <div className="acp-kv-row"><span>Outcome</span><b>{active.outcome}</b></div>
                <div className="acp-kv-row"><span>Location</span><b>{active.location || '—'}</b></div>
                <div className="acp-kv-row"><span>Logged By</span><b>{active.loggedBy}</b></div>
                <div className="acp-kv-row"><span>Conflict Time</span><b>{active.time}</b></div>
                <div className="acp-kv-row"><span>Logged At</span><b>{active.loggedAt}</b></div>
              </div>
              <div style={{ padding: 14 }}>
                <div style={{ fontSize: 11, color: 'var(--acp-text-3)', textTransform: 'uppercase', letterSpacing: 0.5, fontWeight: 700, marginBottom: 6 }}>Description</div>
                <p style={{ margin: 0, lineHeight: 1.55, color: 'var(--acp-text-2)', fontSize: 12.5 }}>{active.description || 'No description provided.'}</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
