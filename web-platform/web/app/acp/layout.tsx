import './acp.css'
import Link from 'next/link'
import type { ReactNode } from 'react'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL, staffLevelTitle } from '@/lib/constants'
import AcpRail from './AcpRail'
import AcpTabs from './AcpTabs'
import AcpBreadcrumbs from './AcpBreadcrumbs'

/**
 * ACP root layout — the single auth gate for everything under /acp.
 *
 * Two-tier navigation: a slim primary rail of areas on the left, and a
 * contextual tab bar of the active area's pages above the content. Fully
 * self-contained `.acp-*` styling, independent of the UCP theme.
 */
export default async function AcpLayout({ children }: { children: ReactNode }) {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)

  return (
    <>
      <link
        rel="stylesheet"
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"
        crossOrigin="anonymous"
      />

      <div className="acp-shell">
        <AcpRail staffLevel={user.staffLevel} />

        <div className="acp-main">
          <header className="acp-topbar">
            <AcpBreadcrumbs />
            <div className="acp-topbar-right">
              <div className="acp-topbar-user">
                <span className="acp-topbar-name">{user.name}</span>
                <span className="acp-topbar-rank">{staffLevelTitle(user.staffLevel)}</span>
              </div>
              <Link href="/ucp" className="acp-btn acp-btn-sm" title="Back to UCP">
                <i className="fa-solid fa-arrow-left" /> UCP
              </Link>
            </div>
          </header>

          <AcpTabs staffLevel={user.staffLevel} />

          <div className="acp-content">{children}</div>
        </div>
      </div>
    </>
  )
}
