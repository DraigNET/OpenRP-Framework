/**
 * Placeholder for ACP sections not yet rebuilt. This is a catch-all: any real
 * page added at a specific path (e.g. /acp/players/page.tsx) automatically takes
 * precedence over this, so it quietly disappears section-by-section as the
 * rewrite progresses. It lets the reorganised navigation be fully clickable now.
 */
function titleFromSlug(slug: string[]): string {
  const last = slug[slug.length - 1] ?? ''
  if (/^\d+$/.test(last)) return `Record #${last}`
  return last.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) || 'Section'
}

export default async function AcpComingSoon({ params }: PageProps<'/acp/[...slug]'>) {
  const { slug } = await params
  const title = titleFromSlug(slug)

  return (
    <div className="acp-coming-soon">
      <div className="acp-coming-icon"><i className="fa-solid fa-helmet-safety" /></div>
      <h1>{title}</h1>
      <p>This section is part of the ACP rebuild and isn&apos;t wired up yet.</p>
      <p className="acp-coming-path"><i className="fa-solid fa-link" /> /acp/{slug.join('/')}</p>
    </div>
  )
}
