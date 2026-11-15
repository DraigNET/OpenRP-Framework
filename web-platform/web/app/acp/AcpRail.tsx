'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { visibleAreas, findActiveArea, defaultHref } from './nav'

/** Slim primary navigation rail: the five areas as icon + label, plus a return
 *  to the UCP. The active area is derived from the current path. */
export default function AcpRail({ staffLevel }: { staffLevel: number }) {
  const pathname = usePathname()
  const areas = visibleAreas(staffLevel)
  const active = findActiveArea(pathname, staffLevel)

  return (
    <nav className="acp-rail">
      <Link href="/acp" className="acp-rail-brand" title="OpenRP Framework ACP">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/favicon.png" alt="OpenRP Framework" />
      </Link>

      <div className="acp-rail-items">
        {areas.map(area => (
          <Link
            key={area.id}
            href={defaultHref(area)}
            className={`acp-rail-item${active?.id === area.id ? ' is-active' : ''}`}
            title={area.label}
          >
            <i className={`fa-solid ${area.icon}`} />
            <span>{area.label}</span>
          </Link>
        ))}
      </div>

      <div className="acp-rail-footer">
        <Link href="/ucp" className="acp-rail-foot" title="Back to UCP">
          <i className="fa-solid fa-arrow-left" />
          <span>UCP</span>
        </Link>
      </div>
    </nav>
  )
}
