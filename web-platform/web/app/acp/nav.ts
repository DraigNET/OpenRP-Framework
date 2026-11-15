import { ADMIN_LVL } from '@/lib/constants'

/**
 * Shared ACP navigation model — consumed by both the primary rail (areas) and
 * the contextual tab bar (the active area's pages). Two tiers: a short list of
 * areas, each holding the pages that surface as horizontal tabs once you're in
 * it. Levels mirror the gamemode/PHP source of truth.
 *
 * NOTE: per-page gates for Donators / Careers / Custom Skins are best-guess from
 * the old PHP and should be reconfirmed when each page is built.
 */
export interface AcpNavItem { href: string; label: string; min: number }
export interface AcpArea { id: string; label: string; icon: string; items: AcpNavItem[] }

export const ACP_AREAS: AcpArea[] = [
  {
    id: 'overview', label: 'Overview', icon: 'fa-gauge-high',
    items: [
      { href: '/acp', label: 'Dashboard', min: ADMIN_LVL.JUNIOR },
      { href: '/acp/command-reference', label: 'Command Reference', min: ADMIN_LVL.JUNIOR },
    ],
  },
  {
    id: 'players', label: 'Players', icon: 'fa-users',
    items: [
      { href: '/acp/players', label: 'Search', min: ADMIN_LVL.JUNIOR },
{ href: '/acp/players/penalties', label: 'Active Penalties', min: ADMIN_LVL.GENERAL },
      { href: '/acp/bans', label: 'Bans', min: ADMIN_LVL.JUNIOR },
      { href: '/acp/bans/samp', label: 'bans.json', min: ADMIN_LVL.MANAGER },
      { href: '/acp/shared-ips', label: 'Shared IPs', min: ADMIN_LVL.GENERAL },
      { href: '/acp/whitelist', label: 'Whitelist', min: ADMIN_LVL.MANAGER },
      { href: '/acp/vpn-whitelist', label: 'VPN Whitelist', min: ADMIN_LVL.GENERAL },
    ],
  },
  {
    id: 'factions', label: 'Factions', icon: 'fa-shield-halved',
    items: [
      { href: '/acp/factions', label: 'Factions', min: ADMIN_LVL.GENERAL },
      { href: '/acp/factions/activity', label: 'Activity', min: ADMIN_LVL.GENERAL },
      { href: '/acp/factions/armory', label: 'Armory', min: ADMIN_LVL.GENERAL },
      { href: '/acp/factions/lockers', label: 'Lockers', min: ADMIN_LVL.GENERAL },
      { href: '/acp/factions/conflicts', label: 'Conflicts', min: ADMIN_LVL.SENIOR },
      { href: '/acp/faction-skins', label: 'Faction Skins', min: ADMIN_LVL.MANAGER },
    ],
  },
  {
    id: 'operations', label: 'Operations', icon: 'fa-sliders',
    items: [
      { href: '/acp/server', label: 'Server Control', min: ADMIN_LVL.LEAD },
      { href: '/acp/commands', label: 'Commands', min: ADMIN_LVL.LEAD },
      { href: '/acp/donators', label: 'Donators', min: ADMIN_LVL.GENERAL },
      { href: '/acp/skins', label: 'Custom Skins', min: ADMIN_LVL.MANAGER },
    ],
  },
  {
    id: 'audit', label: 'Audit', icon: 'fa-scroll',
    items: [
      { href: '/acp/logs/players', label: 'Player Logs', min: ADMIN_LVL.GENERAL },
      { href: '/acp/logs/sms', label: 'SMS', min: ADMIN_LVL.GENERAL },
      { href: '/acp/logs/reports', label: 'Reports', min: ADMIN_LVL.GENERAL },
      { href: '/acp/logs/staff-activity', label: 'Staff Activity', min: ADMIN_LVL.GENERAL },
      { href: '/acp/logs/admin-actions', label: 'Admin Actions', min: ADMIN_LVL.MANAGER },
      { href: '/acp/logs/refunds', label: 'Refund Logs', min: ADMIN_LVL.LEAD },
    ],
  },
]

const matches = (href: string, pathname: string) =>
  href === '/acp' ? pathname === '/acp' : pathname === href || pathname.startsWith(href + '/')

/** Areas (and their items) the given staff level may see; empty areas dropped. */
export function visibleAreas(staffLevel: number): AcpArea[] {
  return ACP_AREAS
    .map(a => ({ ...a, items: a.items.filter(i => staffLevel >= i.min) }))
    .filter(a => a.items.length > 0)
}

/** The area the current path belongs to (longest matching page wins). */
export function findActiveArea(pathname: string, staffLevel: number): AcpArea | undefined {
  const areas = visibleAreas(staffLevel)
  let best: { area: AcpArea; len: number } | undefined
  for (const area of areas) {
    for (const item of area.items) {
      if (matches(item.href, pathname) && (!best || item.href.length > best.len)) {
        best = { area, len: item.href.length }
      }
    }
  }
  if (best) return best.area
  // A detail page under an area root that isn't itself a tab (e.g. /acp/players/5)
  // still resolves via the prefix above; this only falls through for /acp itself.
  return areas.find(a => a.id === 'overview')
}

/** Href of the active page (tab) within an area, by longest prefix match. */
export function activeItemHref(area: AcpArea, pathname: string): string {
  let href = ''
  for (const item of area.items) {
    if (matches(item.href, pathname) && item.href.length > href.length) href = item.href
  }
  return href
}

/** Where clicking an area in the rail lands — its first visible page. */
export const defaultHref = (area: AcpArea): string => area.items[0]?.href ?? '/acp'
