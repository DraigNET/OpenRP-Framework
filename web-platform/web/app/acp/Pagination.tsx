import Link from 'next/link'

/** Shared log/list pager: « First ‹ Prev 1 2 3 … Next › Last ». Server component. */
export default function Pagination({ page, totalPages, hrefFor }: {
  page: number
  totalPages: number
  hrefFor: (p: number) => string
}) {
  if (totalPages <= 1) return null

  const win = 2
  const from = Math.max(1, page - win)
  const to = Math.min(totalPages, page + win)
  const nums: number[] = []
  for (let p = from; p <= to; p++) nums.push(p)

  return (
    <div className="acp-pagination">
      <Link href={hrefFor(1)} className={page <= 1 ? 'is-disabled' : ''}>« First</Link>
      <Link href={hrefFor(page - 1)} className={page <= 1 ? 'is-disabled' : ''}>‹ Prev</Link>
      {from > 1 && <span className="acp-page-info">…</span>}
      {nums.map(p => p === page
        ? <span key={p} className="is-current">{p}</span>
        : <Link key={p} href={hrefFor(p)}>{p}</Link>)}
      {to < totalPages && <span className="acp-page-info">…</span>}
      <Link href={hrefFor(page + 1)} className={page >= totalPages ? 'is-disabled' : ''}>Next ›</Link>
      <Link href={hrefFor(totalPages)} className={page >= totalPages ? 'is-disabled' : ''}>Last »</Link>
    </div>
  )
}
