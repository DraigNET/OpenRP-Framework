import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import Link from 'next/link'
import { MAX_CHARACTERS_PER_ACCOUNT } from '@/lib/constants'
import { formatCash } from '@/lib/format'
import { levelProgress, timeAgo } from '@/lib/ucp-extra'

const skinSrc = (id: number) => `/img/skins/${Math.max(0, Math.min(311, id))}.png`

export default async function CharactersPage() {
  const session = await auth()
  const accountId = session!.user.id

  const [characters, factions] = await Promise.all([
    prisma.character.findMany({ where: { account_id: accountId }, orderBy: { player_name: 'asc' } }),
    prisma.faction.findMany({ select: { faction_id: true, faction_name: true, faction_abbrev: true } }),
  ])

  const factionMap = Object.fromEntries(factions.map(f => [f.faction_id, { name: f.faction_name, short: f.faction_abbrev || f.faction_name }]))
  const canCreate = characters.length < MAX_CHARACTERS_PER_ACCOUNT
  const slotsLeft = MAX_CHARACTERS_PER_ACCOUNT - characters.length

  return (
    <div className="ucp-stack">
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 26 }}>Your characters</h2>
          <span className="ucp-muted">{characters.length} of {MAX_CHARACTERS_PER_ACCOUNT} slots used</span>
        </div>
        <Link
          href={canCreate ? '/ucp/characters/create' : '#'}
          className={`ucp-btn ${canCreate ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}
          style={{ marginLeft: 'auto', ...(!canCreate ? { opacity: 0.45, cursor: 'not-allowed', pointerEvents: 'none' } : {}) }}
          aria-disabled={!canCreate}
        >
          <i className="fa-solid fa-plus" /> Create Character
        </Link>
      </div>

      <div className="ucp-char-grid">
        {characters.map(c => {
          const faction = c.player_factionid > 0 ? (factionMap[c.player_factionid] ?? { name: 'Unknown', short: 'Unknown' }) : null
          const lvl = levelProgress(c.player_hours)
          return (
            <article className="ucp-card ucp-char-card" key={c.player_id}>
              <div className="ucp-char-top">
                <span className={`ucp-chip ${faction ? 'ucp-chip-acc' : ''}`} title={faction?.name}>
                  <i className={`fa-solid ${faction ? 'fa-shield-halved' : 'fa-user'}`} /> {faction?.short ?? 'Civilian'}
                </span>
                <span className="ucp-chip lvl">Lvl {c.player_level}</span>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={skinSrc(c.player_skinid)} alt="" />
              </div>
              <div className="ucp-char-body">
                <h3>{c.player_name.replace(/_/g, ' ')}</h3>
                <small>{c.player_factionid > 0 && c.player_factionrank ? c.player_factionrank : c.player_online ? 'Online now' : 'Offline'}</small>
                <div className="ucp-kv">
                  <div><small>Cash</small><b className="ucp-mono">{formatCash(c.player_cash)}</b></div>
                  <div><small>Bank</small><b className="ucp-mono">{formatCash(c.player_bankcash)}</b></div>
                  <div><small>Playtime</small><b>{c.player_hours} h</b></div>
                  <div><small>Last seen</small><b>{c.player_online ? 'Now' : timeAgo(c.player_logindate)}</b></div>
                </div>
                <div className="ucp-muted" style={{ fontSize: 12, display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                  <span>Level {c.player_level}</span>
                  <span>{lvl.into} / {lvl.needed} h to level {c.player_level + 1}</span>
                </div>
                <div className="ucp-bar"><i style={{ width: `${lvl.pct}%` }} /></div>
                <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
                  <Link href={`/ucp/characters/${c.player_id}`} className="ucp-btn ucp-btn-primary" style={{ flex: 1, padding: '7px 14px' }}>
                    View profile
                  </Link>
                </div>
              </div>
            </article>
          )
        })}

        {canCreate && (
          <Link href="/ucp/characters/create" className="ucp-card ucp-char-card ucp-char-new">
            <div>
              <div className="ucp-char-new-plus"><i className="fa-solid fa-plus" /></div>
              <b style={{ fontSize: 17 }}>New character</b>
              <div className="ucp-muted" style={{ fontSize: 13, marginTop: 4 }}>{slotsLeft} slot{slotsLeft === 1 ? '' : 's'} remaining</div>
            </div>
          </Link>
        )}
      </div>

      {characters.length === 0 && <p className="ucp-muted">You have no characters yet.</p>}
    </div>
  )
}
