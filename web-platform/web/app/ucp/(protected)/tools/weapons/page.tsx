import { WEAPON_STATS, AMMO_BONUSES, calcDamage, ammoClass, dmgClass } from '@/lib/data/weapon-stats'

export default function WeaponStatsPage() {
  return (
    <>
      <div className="ucp-card">
        <h2>Weapon Specification Sheet</h2>
        <p className="ucp-muted">
          Damage is calculated using: <strong>Base Damage + Ammo Bonus</strong>. Distance reduces base damage before ammo is applied.
        </p>
      </div>

      <div className="ucp-card">
        <table className="weapon-table">
          <thead>
            <tr>
              <th>Weapon</th><th>Type</th><th>Ammo</th><th>Clip</th>
              <th>Close</th><th>Mid</th><th>Long</th><th>Range</th>
            </tr>
          </thead>
          <tbody>
            {WEAPON_STATS.map(w => {
              const bonus = AMMO_BONUSES[w.ammo] ?? 0
              const d = calcDamage(w.minDmg, w.maxDmg, bonus)
              const closeAvg = (d.closeMin + d.closeMax) / 2
              const midAvg = (d.midMin + d.midMax) / 2
              const farAvg = (d.farMin + d.farMax) / 2
              return (
                <tr key={w.name}>
                  <td className="weapon-name">{w.name}</td>
                  <td>{w.type}</td>
                  <td>
                    <span className={`ammo-tag ${ammoClass(w.ammo)}`}>
                      {w.ammo} <small>+{bonus}</small>
                    </span>
                  </td>
                  <td>{w.clip}</td>
                  <td className={dmgClass(closeAvg)}>{d.closeMin}–{d.closeMax}</td>
                  <td className={dmgClass(midAvg)}>{d.midMin}–{d.midMax}</td>
                  <td className={dmgClass(farAvg)}>{d.farMin}–{d.farMax}</td>
                  <td className="range">{w.minRange}–{w.maxRange}m</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <div className="ucp-card">
        <h3>Ammo Bonuses</h3>
        <table className="weapon-table">
          <thead><tr><th>Ammo</th><th>Flat Damage Bonus</th></tr></thead>
          <tbody>
            {Object.entries(AMMO_BONUSES).map(([name, bonus]) => (
              <tr key={name}><td>{name}</td><td>+{bonus}</td></tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}
