'use client'

import { useTransition } from 'react'
import { useRouter } from 'next/navigation'

interface BanEntry {
  address: string
  name: string
  time: string
  reason: string
}

async function removeBan(address: string) {
  await fetch(`/api/samp/bans?address=${encodeURIComponent(address)}`, { method: 'DELETE' })
}

function UnbanButton({ address }: { address: string }) {
  const router = useRouter()
  const [pending, start] = useTransition()
  return (
    <button
      className="acp-btn acp-btn-danger acp-btn-sm"
      disabled={pending}
      onClick={() => {
        if (!confirm(`Remove ban for ${address}?`)) return
        start(async () => { await removeBan(address); router.refresh() })
      }}
    >
      {pending ? '…' : 'Remove'}
    </button>
  )
}

export default function BansJsonClient({ bans }: { bans: BanEntry[] }) {
  return (
    <div>
      <div className="acp-panel-head" style={{ marginBottom: 14 }}>
        <span>bans.json — {bans.length} {bans.length === 1 ? 'entry' : 'entries'}</span>
      </div>

      {bans.length === 0 ? (
        <div className="acp-panel">
          <div style={{ padding: '32px 16px', textAlign: 'center', color: 'var(--acp-text-2)', fontSize: 13 }}>
            No entries in bans.json.
          </div>
        </div>
      ) : (
        <div className="acp-panel">
          <table className="acp-table">
            <thead>
              <tr>
                <th>IP Address</th>
                <th>Name</th>
                <th>Reason</th>
                <th>Banned At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {bans.map((ban) => (
                <tr key={ban.address}>
                  <td><code>{ban.address}</code></td>
                  <td>{ban.name || <span style={{ color: 'var(--acp-text-2)' }}>—</span>}</td>
                  <td>{ban.reason || <span style={{ color: 'var(--acp-text-2)' }}>—</span>}</td>
                  <td style={{ color: 'var(--acp-text-2)', fontSize: 12 }}>
                    {ban.time ? new Date(ban.time).toLocaleString() : '—'}
                  </td>
                  <td><UnbanButton address={ban.address} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
