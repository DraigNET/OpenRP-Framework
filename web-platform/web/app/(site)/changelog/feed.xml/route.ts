import { siteConfig as site } from '@/lib/site-config'
const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
/** Atom feed for this community's configured updates; contains no inherited server history. */
export function GET(req: Request) {
  const origin = site.siteUrl || new URL(req.url).origin
  const page = origin + '/changelog'
  const entries = site.updates.map(u => '<entry><title>' + esc(u.title) + '</title><id>' + esc(page + '#' + encodeURIComponent(u.date + '-' + u.title)) + '</id><updated>' + u.date + 'T00:00:00Z</updated><content type="text">' + esc(u.body) + '</content></entry>').join('')
  const updated = site.updates[0]?.date ? site.updates[0].date + 'T00:00:00Z' : new Date().toISOString()
  return new Response('<?xml version="1.0" encoding="utf-8"?><feed xmlns="http://www.w3.org/2005/Atom"><title>' + esc(site.name + ' updates') + '</title><id>' + esc(page) + '</id><link href="' + esc(page) + '"/><link rel="self" href="' + esc(origin + '/changelog/feed.xml') + '"/><updated>' + updated + '</updated>' + entries + '</feed>', { headers: { 'Content-Type': 'application/atom+xml; charset=utf-8', 'Cache-Control': 'public, max-age=600' } })
}

