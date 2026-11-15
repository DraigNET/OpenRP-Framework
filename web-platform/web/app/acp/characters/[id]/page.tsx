import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getCharacterById } from '@/lib/dal'
import { ADMIN_LVL, FACTION_TIER_ID } from '@/lib/constants'
import { formatCash, formatHours, formatUnixDate, formatUnixDateTime } from '@/lib/format'

export const dynamic = 'force-dynamic'

const TIER: Record<number, string> = {
  [FACTION_TIER_ID.OWNER]: 'Owner', [FACTION_TIER_ID.COMMAND]: 'Command',
  [FACTION_TIER_ID.MEMBER]: 'Member', [FACTION_TIER_ID.RECRUIT]: 'Recruit',
}
const SEX: Record<number, string> = { 0: 'Male', 1: 'Female' }

export default async function CharacterProfile({ params }: PageProps<'/acp/characters/[id]'>) {
  const viewer = await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  const c = await getCharacterById(id)
  if (!c) notFound()
  const canEdit = viewer.staffLevel >= ADMIN_LVL.MANAGER
  const canInvestigate = viewer.staffLevel >= ADMIN_LVL.GENERAL

  const [account, faction] = await Promise.all([
    prisma.account.findUnique({ where: { account_id: c.account_id }, select: { account_id: true, account_name: true } }),
    c.player_factionid > 0 ? prisma.faction.findUnique({ where: { faction_id: c.player_factionid }, select: { faction_id: true, faction_name: true } }) : null,
  ])

  const yn = (v: number) => v === 1 ? <span className="acp-badge is-green">Yes</span> : <span className="acp-badge is-off">No</span>

  return (
    <>
      <div className="acp-hub-head">
        <div className="acp-hub-avatar">{c.player_name.charAt(0).toUpperCase()}</div>
        <div className="acp-hub-id">
          <div className="acp-hub-name">
            {c.player_name.replace(/_/g, ' ')}
            {c.player_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}
            {faction && <span className="acp-badge is-amber">{faction.faction_name}</span>}
          </div>
          <div className="acp-hub-meta">
            Character #{c.player_id} · {account
              ? <Link href={`/acp/players/${account.account_id}`} className="acp-link">{account.account_name}</Link>
              : 'unknown account'}
          </div>
        </div>
        {(canEdit || canInvestigate) && (
          <div className="acp-hub-actions">
            {canInvestigate && <Link href={`/acp/characters/${id}/investigate`} className="acp-btn"><i className="fa-solid fa-user-secret" /> Investigate</Link>}
            {canEdit && <Link href={`/acp/characters/${id}/edit`} className="acp-btn acp-btn-primary"><i className="fa-solid fa-pen" /> Edit Character</Link>}
          </div>
        )}
      </div>

      <div className="acp-grid-2">
        <section className="acp-panel">
          <div className="acp-panel-head"><span>Character</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>Name</span><b>{c.player_name.replace(/_/g, ' ')}</b></div>
            <div className="acp-kv-row"><span>Level</span><b>{c.player_level}</b></div>
            <div className="acp-kv-row"><span>Played</span><b>{formatHours(c.player_hours)}</b></div>
            <div className="acp-kv-row"><span>Sex / Age</span><b>{SEX[c.player_attribute_sex] ?? '—'} · {c.player_attribute_age}</b></div>
            <div className="acp-kv-row"><span>Registered</span><b>{formatUnixDate(c.player_registerdate)}</b></div>
            <div className="acp-kv-row"><span>Last Login</span><b>{formatUnixDateTime(c.player_logindate)}</b></div>
          </div>
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Finances</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>Cash</span><b>{formatCash(c.player_cash)}</b></div>
            <div className="acp-kv-row"><span>Bank</span><b>{formatCash(c.player_bankcash)}</b></div>
            <div className="acp-kv-row"><span>Savings</span><b>{formatCash(c.player_savings)}</b></div>
            <div className="acp-kv-row"><span>Outstanding Fines</span><b>{formatCash(c.player_outstanding_fines)}</b></div>
            <div className="acp-kv-row"><span>Phone Number</span><b className="acp-mono">{c.player_phnumber || '—'}</b></div>
          </div>
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Faction</span></div>
          {c.player_factionid > 0 ? (
            <div className="acp-kv">
              <div className="acp-kv-row"><span>Faction</span><b>{faction ? <Link href={`/acp/factions/${faction.faction_id}`} className="acp-link">{faction.faction_name}</Link> : `#${c.player_factionid}`}</b></div>
              <div className="acp-kv-row"><span>Rank</span><b>{c.player_factionrank || '—'}</b></div>
              <div className="acp-kv-row"><span>Tier</span><b>{TIER[c.player_factiontier] ?? '—'}</b></div>
              <div className="acp-kv-row"><span>Squad</span><b>{c.player_factionsquad || '—'}</b></div>
            </div>
          ) : <div className="acp-empty"><i className="fa-solid fa-user" />Not in a faction.</div>}
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Licenses &amp; Status</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>Driver License</span><b>{yn(c.player_driverslicense)}</b></div>
            <div className="acp-kv-row"><span>Gun License</span><b>{yn(c.player_gunlicense)}</b></div>
            <div className="acp-kv-row"><span>CCW License</span><b>{yn(c.player_ccwlicense)}</b></div>
            <div className="acp-kv-row"><span>Health / Armour</span><b>{Math.round(c.player_health)} / {Math.round(c.player_armour)}</b></div>
            <div className="acp-kv-row"><span>Admin Jail</span><b>{c.player_ajail_time > 0 ? `${Math.round(c.player_ajail_time / 60)} min` : 'No'}</b></div>
          </div>
        </section>
      </div>
    </>
  )
}
