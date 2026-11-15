/**
 * Changelog model + derived views for the community changelog.
 * Public updates are configured in lib/site-config.ts.
 */

export type ChangeType = 'Added' | 'Changed' | 'Fixed' | 'Removed'
export type Stage = 'Development' | 'Open Beta' | 'Launch'

/** [title, description] - the title may be empty for a plain line. */
export type Item = [title: string, body: string]

export interface Section {
  type: ChangeType
  items: Item[]
}

export interface Release {
  version: string
  /** ISO date the release went live. */
  date: string
  stage: Stage
  /** Work that is written up but not live yet - shown as "In development", never as Latest. */
  unreleased?: boolean
  summary?: string
  sections: Section[]
}

/** The plain-data shape the client page receives (fully derived, JSON-safe). */
export interface ReleaseView {
  version: string
  slug: string
  date: string
  stage: Stage
  unreleased: boolean
  summary: string | null
  isLatest: boolean
  total: number
  counts: Record<ChangeType, number>
  sections: Section[]
}

export const CHANGE_TYPES: ChangeType[] = ['Added', 'Changed', 'Fixed', 'Removed']

export const slugOf = (version: string) => `v${version.replace(/\./g, '-')}`

export function buildViews(releases: Release[]): ReleaseView[] {
  const latestIndex = releases.findIndex(r => !r.unreleased)
  return releases.map((r, i) => {
    const counts: Record<ChangeType, number> = { Added: 0, Changed: 0, Fixed: 0, Removed: 0 }
    for (const s of r.sections) counts[s.type] += s.items.length
    return {
      version: r.version,
      slug: slugOf(r.version),
      date: r.date,
      stage: r.stage,
      unreleased: !!r.unreleased,
      summary: r.summary ?? null,
      isLatest: i === latestIndex,
      total: CHANGE_TYPES.reduce((a, t) => a + counts[t], 0),
      counts,
      sections: r.sections,
    }
  })
}
