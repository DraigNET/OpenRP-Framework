'use client'

import { usePathname } from 'next/navigation'
import { useEffect } from 'react'
import Link from 'next/link'
import { staffLevelTitle } from '@/lib/constants'
import { ADMIN_NAV, PLAYER_NAV, TOOLS_NAV, type NavItem } from './nav'

interface SidebarProps {
  username: string
  staffLevel: number
  logoutAction: () => Promise<void>
}

export default function Sidebar({ username, staffLevel, logoutAction }: SidebarProps) {
  const pathname = usePathname()

  useEffect(() => {
    const layout = document.getElementById('ucpLayout')
    if (!layout) return
    try {
      if (localStorage.getItem('ucpSidebarCollapsed') === '1') layout.classList.add('sidebar-collapsed')
    } catch { /* private mode */ }
  }, [])

  // Close the mobile drawer after navigating.
  useEffect(() => {
    document.getElementById('ucpLayout')?.classList.remove('mob-open')
  }, [pathname])

  const isActive = (item: NavItem) =>
    (item.match === 'exact' ? pathname === item.href : pathname.startsWith(item.href)) ? ' active' : ''

  const link = (item: NavItem, extra = '') => (
    <li key={item.href + item.label}>
      <Link href={item.href} data-tooltip={item.label} className={`${extra}${isActive(item)}`.trim()}>
        <i className={`fa-solid ${item.icon}`} />
        <span className="nav-label">{item.label}</span>
      </Link>
    </li>
  )

  return (
    <nav className="ucp-nav">
      <div className="ucp-logo">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/favicon.png" alt="OpenRP Framework" className="ucp-logo-img" />
        <span className="ucp-brand-name">OpenRP <small>Framework</small></span>
      </div>

      <div className="ucp-nav-scroll">
        <ul className="ucp-nav-list">
          <li className="ucp-nav-heading">Player</li>
          {PLAYER_NAV.map(i => link(i))}

          <li className="ucp-nav-heading">Tools &amp; Utilities</li>
          {TOOLS_NAV.map(i => link(i))}

          {staffLevel >= (ADMIN_NAV.staffOnly ?? 0) && link(ADMIN_NAV, 'ucp-nav-admin')}
        </ul>
      </div>

      <div className="ucp-me">
        <div className="ucp-me-avatar">{(username[0] ?? '?').toUpperCase()}</div>
        <div className="ucp-me-text">
          <b>{username}</b>
          <small>{staffLevel >= 1 ? staffLevelTitle(staffLevel) : 'Player'}</small>
        </div>
        <form action={logoutAction}>
          <button type="submit" className="ucp-me-out" title="Log out" aria-label="Log out">
            <i className="fa-solid fa-arrow-right-from-bracket" />
          </button>
        </form>
      </div>
    </nav>
  )
}
