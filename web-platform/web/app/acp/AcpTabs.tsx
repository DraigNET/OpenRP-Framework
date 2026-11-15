'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { findActiveArea, activeItemHref } from './nav'

/** Contextual tab bar: the pages of the active area, shown horizontally. Hidden
 *  for single-page areas (e.g. Overview) where tabs would be noise. */
export default function AcpTabs({ staffLevel }: { staffLevel: number }) {
  const pathname = usePathname()
  const area = findActiveArea(pathname, staffLevel)
  if (!area || area.items.length <= 1) return null

  const current = activeItemHref(area, pathname)

  return (
    <nav className="acp-tabbar">
      {area.items.map(item => (
        <Link
          key={item.href}
          href={item.href}
          className={`acp-tab${item.href === current ? ' is-active' : ''}`}
        >
          {item.label}
        </Link>
      ))}
    </nav>
  )
}
