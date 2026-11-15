'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { editMember, type EditMemberState } from './actions'
import { KickButton } from './KickButton'

const INIT: EditMemberState = { error: '', ok: false }

export interface MemberFormValues {
  player_id: number
  player_factionrank: string
  player_factiontier: number
  player_factionbadge: number
  player_factionsquad: number
  player_factionsquad2: number
  player_factionsquad3: number
}

export function EditMemberForm({ charPlayerId, member, memberName, isGang, squadMap, tierOptions }: {
  charPlayerId: number
  member: MemberFormValues
  memberName: string
  isGang: boolean
  squadMap: Record<number, string>
  tierOptions: [string, string][]
}) {
  const [state, action, pending] = useActionState(editMember, INIT)
  const squadEntries = Object.entries(squadMap).map(([k, v]) => [Number(k), v] as [number, string])

  // A named dropdown when the faction has squads, the raw id box otherwise.
  const squadField = (name: 'player_factionsquad' | 'player_factionsquad2' | 'player_factionsquad3', label: string) => (
    <div className="ucp-form-group">
      <label className="ucp-label">{label}</label>
      {squadEntries.length > 0 ? (
        <select name={name} defaultValue={member[name]} className="ucp-input">
          <option value={0}>None</option>
          {squadEntries.map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
      ) : (
        <input name={name} type="number" defaultValue={member[name]} className="ucp-input" />
      )}
    </div>
  )

  return (
    <>
      <div className="ucp-card" style={{ marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 15, fontWeight: 600 }}>Edit Member — {memberName}</div>
            <div className="ucp-muted" style={{ fontSize: 13, marginTop: 3 }}>Character #{member.player_id}</div>
          </div>
          <Link href={`/ucp/faction/${charPlayerId}/roster`} className="ucp-btn ucp-btn-outline">← Back</Link>
        </div>
      </div>

      <div className="ucp-card" style={{ marginBottom: 12 }}>
        {state.error && <div className="ucp-alert ucp-alert-danger" style={{ marginBottom: 12 }}>{state.error}</div>}
        {state.ok && <div className="ucp-alert ucp-alert-success" style={{ marginBottom: 12 }}>Member updated.</div>}

        <form action={action}>
          <input type="hidden" name="char_player_id" value={charPlayerId} />
          <input type="hidden" name="member_id" value={member.player_id} />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
            <div className="ucp-form-group">
              <label className="ucp-label">Rank</label>
              <input name="player_factionrank" defaultValue={member.player_factionrank} maxLength={64} className="ucp-input" />
            </div>
            <div className="ucp-form-group">
              <label className="ucp-label">Tier</label>
              <select name="player_factiontier" defaultValue={member.player_factiontier} className="ucp-input">
                {tierOptions.map(([k, label]) => (
                  <option key={k} value={k}>{label}</option>
                ))}
              </select>
            </div>
          </div>

          {!isGang && (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12, marginBottom: 12 }}>
                {squadField('player_factionsquad', 'Squad 1')}
                {squadField('player_factionsquad2', 'Squad 2')}
                {squadField('player_factionsquad3', 'Squad 3')}
              </div>
              <div style={{ maxWidth: 200, marginBottom: 12 }}>
                <div className="ucp-form-group">
                  <label className="ucp-label">Badge #</label>
                  <input name="player_factionbadge" type="number" min={0} max={99999} defaultValue={member.player_factionbadge} className="ucp-input" />
                </div>
              </div>
            </>
          )}

          <button type="submit" className="ucp-btn ucp-btn-primary" disabled={pending}>
            {pending ? 'Saving…' : 'Save Changes'}
          </button>
        </form>
      </div>

      <div className="ucp-card">
        <div className="ucp-section-title" style={{ color: 'var(--red, #ef4444)' }}>Danger Zone</div>
        <p className="ucp-muted" style={{ fontSize: 13, marginBottom: 12 }}>
          Kicking {memberName} will remove them from the faction and reset their rank, tier, squads, and badge.
        </p>
        <KickButton charPlayerId={charPlayerId} memberId={member.player_id} memberName={memberName} />
      </div>
    </>
  )
}
