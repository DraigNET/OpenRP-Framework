import { DRUG_STATS, ADDICTION_THRESHOLDS, formatGrowTime } from '@/lib/data/drug-stats'

export default function DrugStatsPage() {
  return (
    <>
      <div className="ucp-card">
        <h2>Drug Reference Sheet</h2>
        <p className="ucp-muted">
          Overview of all drugs available in-game — effects, grow/cook times, addiction rates, and withdrawal consequences.
          Use <strong>/checkaddiction</strong>{' '}
          in-game to view your current addiction levels.
        </p>
      </div>

      {DRUG_STATS.map(drug => (
        <div key={drug.id} className="ucp-card">
          <div className="drug-header">
            <span className={`drug-badge ${drug.colorClass}`}>{drug.name}</span>
            <span className="ucp-muted drug-method">
              <i className="fa-solid fa-syringe" /> {drug.consumedBy}
            </span>
          </div>

          <p className="drug-desc">{drug.description}</p>

          {drug.crash && (
            <div className="drug-crash-note">
              <i className="fa-solid fa-triangle-exclamation" /> <strong>Crash:</strong> {drug.crash}
            </div>
          )}

          <div className="drug-effects-list">
            {drug.effectSummary.map((line, i) => (
              <div key={i} className="drug-effect-line">
                <i className="fa-solid fa-circle-dot" /> {line}
              </div>
            ))}
          </div>

          <div className="drug-supply-note">
            <i className="fa-solid fa-location-dot" /> <strong>Supply point:</strong> {drug.supplyLocation}
            {drug.supplyNote && <span className="drug-wip"> — {drug.supplyNote}</span>}
          </div>

          <table className="weapon-table drug-table">
            <thead>
              <tr>
                <th>Grade / Strain</th>
                <th>Supply Cost</th>
                <th>Grow / Cook Time</th>
                <th>Haul (gr)</th>
                <th>{drug.statLabel}</th>
              </tr>
            </thead>
            <tbody>
              {drug.variants.map(v => (
                <tr key={v.name}>
                  <td className="weapon-name">{v.name}</td>
                  <td>{v.supplyCost === 0 ? <span className="ucp-muted">N/A</span> : `$${v.supplyCost.toLocaleString()}`}</td>
                  <td className={v.growMins === 0 ? 'ucp-muted' : ''}>{formatGrowTime(v.growMins)}</td>
                  <td>{v.minHaul} – {v.maxHaul}</td>
                  <td className="drug-stat">{v.stat}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="drug-addiction-row">
            <div className="drug-addiction-item">
              <span className="drug-addiction-label">Addiction rate</span>
              <span className="drug-addiction-value">+{drug.addiction.ratePerGram} / gram</span>
            </div>
            <div className="drug-addiction-item">
              <span className="drug-addiction-label">Addiction decay</span>
              <span className="drug-addiction-value">−{drug.addiction.decayPerHour} / hour</span>
            </div>
            <div className="drug-addiction-item">
              <span className="drug-addiction-label">Withdrawal after</span>
              <span className="drug-addiction-value">{drug.addiction.windowHours}h without use</span>
            </div>
          </div>

          <div className="drug-withdrawal-effects">
            <div className="drug-withdrawal-label">Withdrawal effects:</div>
            {drug.addiction.withdrawalEffects.map((e, i) => (
              <div key={i} className="drug-effect-line ucp-muted">
                <i className="fa-solid fa-circle-dot" /> {e}
              </div>
            ))}
          </div>
        </div>
      ))}

      <div className="ucp-card">
        <h3>Addiction Severity Levels</h3>
        <p className="ucp-muted">
          Addiction builds per gram used and decays passively over time. Use <strong>/checkaddiction</strong>{' '}
          in-game to see your exact levels.
          Cross-addiction exists between cocaine and crack — using one raises the other.
        </p>
        <table className="weapon-table">
          <thead>
            <tr>
              <th>Level</th>
              <th>Score Range</th>
              <th>Effects</th>
            </tr>
          </thead>
          <tbody>
            {ADDICTION_THRESHOLDS.map(t => (
              <tr key={t.label}>
                <td><span className={`ammo-tag ${t.color}`}>{t.label}</span></td>
                <td>{t.range}</td>
                <td>{t.effects}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="drug-cross-addiction">
          <i className="fa-solid fa-arrow-right-arrow-left" />
          {' '}<strong>Cross-addiction:</strong>{' '}
          Using cocaine adds to your crack addiction score (×3 per gram) and vice versa (×2 per gram).
        </div>
      </div>
    </>
  )
}
