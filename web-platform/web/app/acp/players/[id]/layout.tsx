import type { ReactNode } from 'react'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById, serverNow } from '@/lib/dal'
import { ADMIN_LVL, staffLevelTitle } from '@/lib/constants'
import PlayerTabs from './PlayerTabs'

export const dynamic = 'force-dynamic'

export default async function PlayerHubLayout({
  children,
  params,
}: {
  children: ReactNode
  params: Promise<{ id: string }>
}) {
  const viewer = await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  const account = await getAccountById(id)
  if (!account) notFound()

  const now = Math.floor(serverNow() / 1000)
  const ban = await prisma.ban.findFirst({
    where: { account_id: id, OR: [{ unban_time: 0 }, { unban_time: { gt: now } }] },
    orderBy: { ban_time: 'desc' },
  })

  return (
    <>
      <div className="acp-hub-head">
        <div className="acp-hub-avatar">{account.account_name.charAt(0).toUpperCase()}</div>
        <div className="acp-hub-id">
          <div className="acp-hub-name">
            {account.account_name}
            {account.account_stafflevel > 0 && (
              <span className="acp-badge is-amber">{staffLevelTitle(account.account_stafflevel)}</span>
            )}
            {account.account_online === 1
              ? <span className="acp-badge is-green">Online</span>
              : <span className="acp-badge is-off">Offline</span>}
            {ban && <span className="acp-badge is-red">Banned</span>}
          </div>
          <div className="acp-hub-meta">Account #{account.account_id} · {account.account_email || 'no email'}</div>
        </div>
      </div>

      <PlayerTabs id={id} canManage={viewer.staffLevel >= ADMIN_LVL.MANAGER} />
      {children}
    </>
  )
}
