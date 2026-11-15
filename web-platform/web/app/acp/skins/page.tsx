import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'
import CustomSkinForm from './CustomSkinForm'
import DeleteSkinButton from './DeleteSkinButton'

export const dynamic = 'force-dynamic'

interface Row {
  player_skin_id: number
  player_skin_charid: number
  player_skin_baseid: number
  player_skin_dff: string
  player_skin_txd: string
  player_skin_lastused: number | bigint
  player_skin_disabled: number
  player_name: string | null
}

export default async function CustomSkins() {
  await requireStaff(ADMIN_LVL.MANAGER)

  if (!env.customSkinsEnabled) return <div className="acp-empty">Custom skins are disabled. Enable CUSTOM_SKINS_ENABLED in the web environment and FEATURE_CUSTOM_SKINS in the gamemode, then restart both services.</div>
  const rows = await prisma.$queryRaw<Row[]>`
    SELECT s.player_skin_id, s.player_skin_charid, s.player_skin_baseid, s.player_skin_dff,
           s.player_skin_txd, s.player_skin_lastused, s.player_skin_disabled, c.player_name
    FROM player_skins s
    LEFT JOIN characters c ON c.player_id = s.player_skin_charid
    ORDER BY s.player_skin_id DESC LIMIT 150`

  return (
    <>
    <div className="acp-fs-grid">
      <section className="acp-panel">
        <div className="acp-panel-head"><span>Upload Custom Skin</span></div>
        <div style={{ padding: 14 }}><CustomSkinForm /></div>
      </section>
      <section className="acp-panel">
        <div className="acp-panel-head"><span>Deployment Notes</span></div>
        <div style={{ padding: '12px 14px', fontSize: 11.5, color: 'var(--acp-text-3)', lineHeight: 1.7 }}>
          • Personal record IDs map to stable custom model IDs (25000 + record ID).<br />
          • DFF + TXD must be uploaded together (16 MB max each).<br />
          • Files deploy to <span className="acp-mono">customskins/&lt;charId&gt;/</span> on the SA-MP server.<br />
          • Restart the game server after uploads or deletions. Use /customskin [record id] in-game to equip a personal upload.
        </div>
      </section>
    </div>

    <section className="acp-panel" style={{ marginTop: 14 }}>
      <div className="acp-panel-head"><span>Custom Skins — latest {rows.length}</span></div>
      {rows.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-shirt" />No custom skins on record.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th style={{ width: 56 }}>ID</th><th>Character</th><th>Base</th><th>DFF</th><th>TXD</th><th>Last Used</th><th>Status</th><th style={{ width: 90 }}></th></tr></thead>
          <tbody>
            {rows.map(r => (
              <tr key={r.player_skin_id}>
                <td className="acp-td-muted">{r.player_skin_id}</td>
                <td>{r.player_name ? r.player_name.replace(/_/g, ' ') : <span className="acp-td-muted">#{r.player_skin_charid}</span>}</td>
                <td className="acp-td-muted">{r.player_skin_baseid}</td>
                <td className="acp-mono acp-td-muted">{r.player_skin_dff || '—'}</td>
                <td className="acp-mono acp-td-muted">{r.player_skin_txd || '—'}</td>
                <td className="acp-td-muted">{formatUnixDate(Number(r.player_skin_lastused))}</td>
                <td>{r.player_skin_disabled === 1 ? <span className="acp-badge is-red">Disabled</span> : <span className="acp-badge is-green">Active</span>}</td>
                <td><DeleteSkinButton skinId={r.player_skin_id} label={`${r.player_skin_dff} (${r.player_name ?? '#' + r.player_skin_charid})`} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
    </>
  )
}
