'use client'

import { useMemo, useState } from 'react'
import { ADMIN_CATEGORIES, type AdminCategory, type AdminCommand, type AdminTier } from '@/lib/data/admin-commands'

const SHORT_TITLE: Record<number, string> = {
  2: 'Junior', 3: 'General', 4: 'Senior', 5: 'Lead', 6: 'Head', 7: 'Manager', 8: 'Developer',
}

const matches = (c: AdminCommand, q: string) => {
  const hay = [c.name, c.usage ?? '', c.desc, c.note ?? '', c.cat, ...(c.aliases ?? [])].join(' ').toLowerCase()
  return q.split(/\s+/).every(term => hay.includes(term.replace(/^\//, '')))
}

function CommandRow({ cmd }: { cmd: AdminCommand }) {
  return (
    <li className="acp-cmd">
      <div className="acp-cmd-sig">
        <code className="acp-cmd-name">/{cmd.name}</code>
        {cmd.usage && <span className="acp-cmd-usage">{cmd.usage}</span>}
        {cmd.beta && <span className="acp-badge is-amber" title="Beta Testers can use this too">Beta+</span>}
      </div>
      <p className="acp-cmd-desc">{cmd.desc}</p>
      {cmd.aliases && cmd.aliases.length > 0 && (
        <p className="acp-cmd-meta">Also: {cmd.aliases.map(a => `/${a}`).join('  ')}</p>
      )}
      {cmd.note && (
        <p className="acp-cmd-meta"><i className="fa-solid fa-circle-info" /> {cmd.note}</p>
      )}
    </li>
  )
}

function Groups({ commands }: { commands: AdminCommand[] }) {
  const groups = ADMIN_CATEGORIES
    .map(cat => ({ cat, items: commands.filter(c => c.cat === cat) }))
    .filter(g => g.items.length > 0)

  return (
    <>
      {groups.map(g => (
        <section key={g.cat} className="acp-cmd-group">
          <h3 className="acp-cmd-group-head">{g.cat}<span>{g.items.length}</span></h3>
          <ul className="acp-cmd-list">
            {g.items.map(c => <CommandRow key={c.name} cmd={c} />)}
          </ul>
        </section>
      ))}
    </>
  )
}

export default function CommandReference({ tiers, staffLevel }: { tiers: AdminTier[]; staffLevel: number }) {
  const [tabId, setTabId] = useState(tiers[0].id)
  const [cat, setCat] = useState<AdminCategory | null>(null)
  const [query, setQuery] = useState('')

  const q = query.trim().toLowerCase()
  const total = tiers.reduce((n, t) => n + t.commands.length, 0)
  const tier = tiers.find(t => t.id === tabId) ?? tiers[0]

  const results = useMemo(
    () => (q ? tiers.map(t => ({ tier: t, items: t.commands.filter(c => matches(c, q)) })).filter(r => r.items.length) : []),
    [q, tiers],
  )
  const resultCount = results.reduce((n, r) => n + r.items.length, 0)

  const catCounts = useMemo(() => {
    const counts = new Map<AdminCategory, number>()
    for (const c of tier.commands) counts.set(c.cat, (counts.get(c.cat) ?? 0) + 1)
    return counts
  }, [tier])

  const visible = cat ? tier.commands.filter(c => c.cat === cat) : tier.commands

  const pickTab = (id: string) => { setTabId(id); setCat(null) }

  return (
    <>
      <div className="acp-toolbar">
        <div className="acp-search">
          <i className="fa-solid fa-magnifying-glass" />
          <input
            type="search"
            value={query}
            onChange={e => setQuery(e.target.value)}
            placeholder={`Search all ${total} commands by name, alias or description`}
            aria-label="Search commands"
          />
        </div>
        <span className="acp-cmd-hint">Each rank can also use every command listed under the ranks below it.</span>
      </div>

      {q ? (
        <div className="acp-panel">
          <div className="acp-panel-head">
            <span>{resultCount} result{resultCount === 1 ? '' : 's'} for &ldquo;{query.trim()}&rdquo;</span>
            <button className="acp-btn acp-btn-sm" onClick={() => setQuery('')}>Clear</button>
          </div>
          {results.length === 0 ? (
            <div className="acp-empty"><i className="fa-solid fa-terminal" />No commands match that search.</div>
          ) : (
            <div className="acp-cmd-body">
              {results.map(r => (
                <section key={r.tier.id} className="acp-cmd-group">
                  <h3 className="acp-cmd-group-head">
                    {SHORT_TITLE[r.tier.level]} <span>{r.items.length}</span>
                  </h3>
                  <ul className="acp-cmd-list">
                    {r.items.map(c => <CommandRow key={c.name} cmd={c} />)}
                  </ul>
                </section>
              ))}
            </div>
          )}
        </div>
      ) : (
        <>
          <nav className="acp-hubtabs" role="tablist" aria-label="Admin rank">
            {tiers.map(t => (
              <button
                key={t.id}
                role="tab"
                aria-selected={t.id === tabId}
                className={`acp-hubtab acp-cmd-tab${t.id === tabId ? ' is-active' : ''}`}
                onClick={() => pickTab(t.id)}
              >
                {SHORT_TITLE[t.level]}
                <span className="acp-cmd-tab-count">{t.commands.length}</span>
                {staffLevel < t.level && <i className="fa-solid fa-lock acp-cmd-lock" title="Above your rank" />}
              </button>
            ))}
          </nav>

          <div className="acp-panel">
            <div className="acp-panel-head">
              <span>{SHORT_TITLE[tier.level]} &middot; {tier.commands.length} commands</span>
            </div>
            <p className="acp-cmd-blurb">{tier.blurb}</p>

            <div className="acp-cmd-chips" role="group" aria-label="Filter by category">
              <button className={`acp-cmd-chip${cat === null ? ' is-active' : ''}`} onClick={() => setCat(null)}>
                All <span>{tier.commands.length}</span>
              </button>
              {ADMIN_CATEGORIES.filter(k => catCounts.has(k)).map(k => (
                <button key={k} className={`acp-cmd-chip${cat === k ? ' is-active' : ''}`} onClick={() => setCat(cat === k ? null : k)}>
                  {k} <span>{catCounts.get(k)}</span>
                </button>
              ))}
            </div>

            <div className="acp-cmd-body">
              <Groups commands={visible} />
            </div>
          </div>
        </>
      )}
    </>
  )
}
