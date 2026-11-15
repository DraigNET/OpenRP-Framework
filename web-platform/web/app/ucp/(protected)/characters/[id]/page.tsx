import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { formatCash, formatHeight, formatHours, formatUnixDate } from '@/lib/format'
import { GENDER, RACE, HAIR, EYES, BODY, FIGHT_STYLE, FACTION_TIER } from '@/lib/data/attributes'
import { vehicleName, vehicleImage } from '@/lib/data/vehicles'
import { weaponName } from '@/lib/data/weapons'
import Image from 'next/image'
import Link from 'next/link'

function safeSkinId(skinId: number): number {
  return Math.max(0, Math.min(311, skinId))
}

function licenseStatus(timestamp: number): { label: string; className: string } {
  const now = Math.floor(Date.now() / 1000)
  if (timestamp <= 0) return { label: 'None', className: 'char-license-none' }
  if (timestamp < now) return { label: 'Expired', className: 'char-license-expired' }
  return { label: `Valid until ${formatUnixDate(timestamp)}`, className: 'char-license-valid' }
}

export default async function CharacterProfilePage({ params }: PageProps<'/ucp/characters/[id]'>) {
  const { id } = await params
  const session = await auth()
  const accountId = session!.user.id

  const char = await prisma.character.findFirst({
    where: { player_id: Number(id), account_id: accountId },
    include: { weapons: { where: { weapon_ammo: { gt: 0 } } } },
  })
  if (!char) notFound()

  const [faction, vehicles] = await Promise.all([
    char.player_factionid > 0
      ? prisma.faction.findUnique({ where: { faction_id: char.player_factionid } })
      : null,
    prisma.vehicle.findMany({
      where: { vehicle_type: 3, vehicle_owner: char.player_id },
      orderBy: { vehicle_modelid: 'asc' },
    }),
  ])

  const skin = safeSkinId(char.player_skinid || 0)
  const healthPct = Math.min(100, Math.round(char.player_health))
  const armourPct = Math.min(100, Math.round(char.player_armour))

  const licenses = [
    { label: 'Firearm Safety Certificate', ts: char.player_gunlicense },
    { label: 'Concealed Carry Weapon', ts: char.player_ccwlicense },
    { label: 'Guard Card', ts: char.player_guardlicense },
    { label: 'Guard Card Firearms Permit', ts: char.player_guardfplicense },
  ]

  return (
    <div className="char-page">
      {/* Top summary card */}
      <div className="ucp-card char-summary-card">
        <div className="char-summary-header">
          <div className="char-avatar">
            <div className="char-avatar-inner">
              <Image src={`/img/skins/${skin}.png`} alt={`Skin ${char.player_skinid}`} width={200} height={300} className="char-avatar-img" />
              <div className="char-avatar-skin-overlay">Skin {char.player_skinid}</div>
            </div>
          </div>

          <div className="char-summary-main">
            <div className="char-summary-name">
              <h2>{char.player_name.replace('_', ' ')}</h2>
              <span className="char-summary-sub">
                Level {char.player_level} · {formatHours(char.player_hours)} · Registered {formatUnixDate(char.player_registerdate)}
              </span>
            </div>

            <div className="char-health-bars">
              <div className="char-bar-row">
                <span className="char-bar-label">Health</span>
                <div className="char-bar"><div className="char-bar-fill is-health" style={{ width: `${healthPct}%` }} /></div>
                <span className="char-bar-value">{healthPct}%</span>
              </div>
              <div className="char-bar-row">
                <span className="char-bar-label">Armour</span>
                <div className="char-bar"><div className="char-bar-fill is-armour" style={{ width: `${armourPct}%` }} /></div>
                <span className="char-bar-value">{armourPct}%</span>
              </div>
            </div>

            <div className="char-summary-grid">
              <div className="char-summary-block">
                <div className="char-summary-title">Appearance</div>
                <dl className="char-summary-list">
                  {[
                    ['Gender', GENDER[char.player_attribute_sex]],
                    ['Age', char.player_attribute_age > 0 ? String(char.player_attribute_age) : 'Unknown'],
                    ['Ethnicity', RACE[char.player_attribute_race]],
                    ['Height', formatHeight(char.player_attribute_height)],
                    ['Build', BODY[char.player_attribute_body]],
                    ['Hair', HAIR[char.player_attribute_hair]],
                    ['Eyes', EYES[char.player_attribute_eyes]],
                  ].map(([dt, dd]) => (
                    <div key={dt}><dt>{dt}</dt><dd>{dd ?? '—'}</dd></div>
                  ))}
                </dl>
              </div>

              <div className="char-summary-block">
                <div className="char-summary-title">Faction</div>
                <dl className="char-summary-list">
                  <div><dt>Faction</dt><dd>{faction?.faction_name ?? 'None'}</dd></div>
                  <div><dt>Tier</dt><dd>{FACTION_TIER[char.player_factiontier] ?? '—'}</dd></div>
                  <div><dt>Rank</dt><dd>{char.player_factionrank || '—'}</dd></div>
                </dl>
              </div>

              <div className="char-summary-block">
                <div className="char-summary-title">Wealth</div>
                <dl className="char-summary-list">
                  <div><dt>Cash</dt><dd>{formatCash(char.player_cash)}</dd></div>
                  <div><dt>Bank</dt><dd>{formatCash(char.player_bankcash)}</dd></div>
                  <div><dt>Savings</dt><dd>{formatCash(char.player_savings)}</dd></div>
                  <div><dt>Outstanding fines</dt><dd>{formatCash(char.player_outstanding_fines)}</dd></div>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {char.player_attribute_desc && char.player_attribute_desc !== 'None' && (
          <div className="char-desc-block">
            <div className="char-field-label">Character description</div>
            <div className="char-desc-text">{char.player_attribute_desc}</div>
          </div>
        )}
      </div>

      {/* Two-column layout */}
      <div className="char-main-grid">
        <div className="char-column">
          {/* Phone */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">Phone</h3>
            <div className="char-section-grid">
              <div className="char-field"><div className="char-field-label">Number</div><div className="char-field-value">{char.player_phnumber > 0 ? char.player_phnumber : 'None'}</div></div>
              <div className="char-field"><div className="char-field-label">Credit</div><div className="char-field-value">{formatCash(char.player_phcredit)}</div></div>
            </div>
          </div>

          {/* Items */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">On-Person Items</h3>
            <div className="char-section-grid">
              <div className="char-field"><div className="char-field-label">Lockpicks</div><div className="char-field-value">{char.player_lockpicks}</div></div>
              <div className="char-field"><div className="char-field-label">Mask</div><div className="char-field-value">{char.player_maskid > 0 ? `Yes (ID ${char.player_maskid})` : 'No'}</div></div>
              <div className="char-field"><div className="char-field-label">Driver&apos;s License</div><div className="char-field-value">{char.player_driverslicense > 0 ? 'Yes' : 'No'}</div></div>
            </div>
          </div>

          {/* Licenses */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">Licenses &amp; Permits</h3>
            <div className="char-section-grid">
              {licenses.map(({ label, ts }) => {
                const { label: statusLabel, className } = licenseStatus(ts)
                return (
                  <div key={label} className="char-field">
                    <div className="char-field-label">{label}</div>
                    <div className="char-field-value">
                      <span className={`char-license-status ${className}`}>{statusLabel}</span>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* Fitness */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">Fitness</h3>
            <div className="char-section-grid">
              {[
                ['Fat', Math.round(char.player_fat)],
                ['Muscle', Math.round(char.player_muscle)],
                ['Stamina', Math.round(char.player_stamina)],
                ['Fight Style', FIGHT_STYLE[char.player_fightstyle] ?? 'None'],
              ].map(([label, val]) => (
                <div key={label} className="char-field">
                  <div className="char-field-label">{label}</div>
                  <div className="char-field-value">{val}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Weapons */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">Weapons</h3>
            {char.weapons.length === 0 ? (
              <div className="char-empty">No weapons recorded for this character.</div>
            ) : (
              <table className="char-table">
                <thead><tr><th>Weapon</th><th className="char-col-small">ID</th><th className="char-col-small">Ammo</th></tr></thead>
                <tbody>
                  {char.weapons.map(w => (
                    <tr key={w.weapon_id}>
                      <td>{weaponName(w.weapon_id)}</td>
                      <td>{w.weapon_id}</td>
                      <td>{w.weapon_ammo.toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        <div className="char-column">
          {/* Vehicles */}
          <div className="ucp-card char-section-card">
            <h3 className="char-section-title">Vehicles</h3>
            {vehicles.length === 0 ? (
              <div className="char-empty">This character does not own any vehicles.</div>
            ) : (
              <div className="char-vehicle-list">
                {vehicles.map(v => (
                  <div key={v.vehicle_sqlid} className="char-asset-card char-vehicle-card">
                    <div className="char-asset-thumb">
                      <img src={vehicleImage(v.vehicle_modelid)} alt={vehicleName(v.vehicle_modelid)} />
                    </div>
                    <div className="char-asset-body">
                      <div className="char-asset-title">{vehicleName(v.vehicle_modelid)}</div>
                      <div className="char-asset-row">
                        <div className="char-asset-field"><span className="char-asset-field-label">ID</span><span className="char-asset-field-value">#{v.vehicle_sqlid}</span></div>
                        <div className="char-asset-field"><span className="char-asset-field-label">Plate</span><span className="char-asset-field-value">{v.vehicle_license || '—'}</span></div>
                        <div className="char-asset-field"><span className="char-asset-field-label">Model</span><span className="char-asset-field-value">{v.vehicle_modelid}</span></div>
                      </div>
                      <div className="char-asset-row">
                        <div className="char-asset-field"><span className="char-asset-field-label">Fuel</span><span className="char-asset-field-value">{v.vehicle_fuel}%</span></div>
                        <div className="char-asset-field"><span className="char-asset-field-label">Health</span><span className="char-asset-field-value">{Math.round(v.vehicle_health)}</span></div>
                        <div className="char-asset-field"><span className="char-asset-field-label">Mileage</span><span className="char-asset-field-value">{v.vehicle_mileage.toLocaleString()} km</span></div>
                      </div>
                      {v.vehicle_impounded === 1 && (
                        <div className="char-asset-row">
                          <span style={{ color: '#fca5a5', fontSize: 12 }}><i className="fa-solid fa-lock" /> Impounded</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="char-back-link">
        <Link href="/ucp/characters" className="char-back-link-btn">Back to Characters</Link>
      </div>
    </div>
  )
}
