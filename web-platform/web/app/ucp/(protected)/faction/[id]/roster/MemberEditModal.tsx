'use client'

import { useState, useActionState, useTransition, useEffect } from 'react'
import { editMember, kickMember, type EditMemberState } from './actions'
import { FACTION_TIER_ID } from '@/lib/constants'
import { FACTION_TIER } from '@/lib/data/attributes'

export interface RosterMember {
  player_id: number
  player_name: string
  player_factionrank: string
  player_factiontier: number
  player_factionbadge: number
  player_factionsquad: number
  player_factionsquad2: number
  player_factionsquad3: number
  player_online: number
  player_logindate: number
}

interface Props {
  charPlayerId: number
  myTier: number
  isGang: boolean
  squadMap: Record<number, string>
  members: RosterMember[]
}

const INIT: EditMemberState = { error: '', ok: false }

function lastActiveText(logindate: number) {
  if (!logindate) return { text: 'Never', color: 'var(--text-2)' }
  const daysAgo = Math.floor((Date.now() / 1000 - logindate) / 86400)
  const text = daysAgo === 0 ? 'Today' : `${daysAgo}d ago`
  const color = daysAgo <= 7 ? '#86efac' : daysAgo <= 14 ? '#fde68a' : '#fca5a5'
  return { text, color }
}

function canEditMember(myTier: number, member: RosterMember, myPlayerId: number) {
  if (myTier > FACTION_TIER_ID.COMMAND) return false
  if (member.player_online === 1) return false
  const isOwner = myTier === FACTION_TIER_ID.OWNER
  if (isOwner) return member.player_id !== myPlayerId
  return member.player_factiontier >= FACTION_TIER_ID.MEMBER
}

export function RosterClient({ charPlayerId, myTier, isGang, squadMap, members }: Props) {
  const [editing, setEditing] = useState<RosterMember | null>(null)
  const [state, action, pending] = useActionState(editMember, INIT)
  const [kickPending, startKick] = useTransition()

  const myMember = members.find(m => m.player_id === charPlayerId)
  const myPlayerId = myMember?.player_id ?? -1

  const tierOptions: [string, string][] = myTier === FACTION_TIER_ID.OWNER
    ? Object.entries(FACTION_TIER) as [string, string][]
    : (Object.entries(FACTION_TIER) as [string, string][]).filter(([k]) => Number(k) >= FACTION_TIER_ID.MEMBER)

  const squadEntries = Object.entries(squadMap).map(([k, v]) => [Number(k), v] as [number, string])
  const canManage = myTier <= FACTION_TIER_ID.COMMAND

  useEffect(() => {
    if (state.ok) setEditing(null)
  }, [state.ok])

  return (
    <>
      <div className="ucp-card">
        <h3>Faction Roster</h3>
        <div style={{ overflowX: 'auto', marginTop: 10 }}>
          <table className="ucp-table">
            <thead>
              <tr>
                <th>Rank</th>
                <th>Name</th>
                <th>Tier</th>
                <th>Last Active</th>
                <th>Status</th>
                {canManage && <th></th>}
              </tr>
            </thead>
            <tbody>
              {members.map(m => {
                const isOnline = m.player_online === 1
                const { text, color } = lastActiveText(m.player_logindate)
                const editable = canEditMember(myTier, m, myPlayerId)
                return (
                  <tr key={m.player_id}>
                    <td>{m.player_factionrank || '—'}</td>
                    <td>{m.player_name.replace(/_/g, ' ')}</td>
                    <td>{FACTION_TIER[m.player_factiontier] ?? `Tier ${m.player_factiontier}`}</td>
                    <td><span style={{ color }}>{text}</span></td>
                    <td>
                      {isOnline
                        ? <span style={{ color: '#86efac' }}>Online</span>
                        : <span style={{ color: 'var(--text-2)' }}>Offline</span>}
                    </td>
                    {canManage && (
                      <td style={{ textAlign: 'right' }}>
                        {editable && (
                          <button
                            type="button"
                            className="ucp-btn ucp-btn-outline"
                            style={{ fontSize: 12, padding: '3px 10px' }}
                            onClick={() => setEditing(m)}
                          >
                            Edit
                          </button>
                        )}
                      </td>
                    )}
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {editing && (
        <div
          style={{
            position: 'fixed', inset: 0,
            background: 'rgba(0,0,0,0.7)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 9999,
          }}
          onClick={(e) => { if (e.target === e.currentTarget && !pending) setEditing(null) }}
        >
          <div style={{
            background: 'var(--bg-surface)',
            border: '1px solid var(--border-sub)',
            borderRadius: 'var(--r-card)',
            padding: 24,
            width: 380,
            maxWidth: '90vw',
          }}>
            <h3 style={{ margin: '0 0 4px', fontSize: 16 }}>
              {editing.player_name.replace(/_/g, ' ')}
            </h3>
            <p style={{ margin: '0 0 16px', fontSize: 13, color: 'var(--text-2)' }}>
              {FACTION_TIER[editing.player_factiontier]} · Edit Member
            </p>

            {state.error && (
              <div className="ucp-alert ucp-alert-danger" style={{ marginBottom: 12, fontSize: 13 }}>
                {state.error}
              </div>
            )}

            <form action={action} className="ucp-form" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <input type="hidden" name="char_player_id" value={charPlayerId} />
              <input type="hidden" name="member_id" value={editing.player_id} />

              <label>
                Rank
                <input name="player_factionrank" defaultValue={editing.player_factionrank} maxLength={64} />
              </label>

              <label>
                Tier
                <select name="player_factiontier" defaultValue={editing.player_factiontier}>
                  {tierOptions.map(([k, label]) => (
                    <option key={k} value={k}>{label}</option>
                  ))}
                </select>
              </label>

              {!isGang && (
                <>
                  <label>
                    Badge #
                    <input name="player_factionbadge" type="number" min={0} max={99999} defaultValue={editing.player_factionbadge} />
                  </label>

                  {squadEntries.length > 0 && (
                    <>
                      <label>
                        Squad 1
                        <select name="player_factionsquad" defaultValue={editing.player_factionsquad}>
                          <option value={0}>None</option>
                          {squadEntries.map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                        </select>
                      </label>
                      <label>
                        Squad 2
                        <select name="player_factionsquad2" defaultValue={editing.player_factionsquad2}>
                          <option value={0}>None</option>
                          {squadEntries.map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                        </select>
                      </label>
                      <label>
                        Squad 3
                        <select name="player_factionsquad3" defaultValue={editing.player_factionsquad3}>
                          <option value={0}>None</option>
                          {squadEntries.map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                        </select>
                      </label>
                    </>
                  )}
                </>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                <button type="button" className="ucp-btn ucp-btn-outline" onClick={() => setEditing(null)} disabled={pending}>
                  Cancel
                </button>
                <button type="submit" className="ucp-btn ucp-btn-primary" disabled={pending}>
                  {pending ? 'Saving…' : 'Save'}
                </button>
              </div>
            </form>

            <hr style={{ border: 'none', borderTop: '1px solid var(--border-sub)', margin: '16px 0' }} />

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 13, color: 'var(--text-2)' }}>Remove from faction</span>
              <button
                type="button"
                className="ucp-btn ucp-btn-danger"
                style={{ fontSize: 12 }}
                disabled={kickPending}
                onClick={() => {
                  if (confirm(`Kick ${editing.player_name.replace(/_/g, ' ')} from the faction?`)) {
                    startKick(() => kickMember(charPlayerId, editing.player_id))
                  }
                }}
              >
                {kickPending ? 'Kicking…' : 'Kick'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
