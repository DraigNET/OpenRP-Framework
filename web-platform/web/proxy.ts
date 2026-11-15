import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const PUBLIC_PATHS = [
  '/ucp/login',
  '/ucp/register',
  '/ucp/forgot',
  '/ucp/reset',
  '/ucp/verify',
  '/ucp/banned',
]

export default function proxy(req: NextRequest) {
  const { pathname } = req.nextUrl
  const isUcp = pathname.startsWith('/ucp')
  const isAcp = pathname.startsWith('/acp')
  if (!isUcp && !isAcp) return NextResponse.next()

  const isPublic = PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + '/'))
  if (isPublic) return NextResponse.next()

  // Optimistic check — Auth.js session cookie (secure prefix used in production)
  const sessionCookie =
    req.cookies.get('authjs.session-token') ??
    req.cookies.get('__Secure-authjs.session-token')

  if (!sessionCookie) {
    const loginUrl = new URL('/ucp/login', req.url)
    loginUrl.searchParams.set('callbackUrl', pathname)
    return NextResponse.redirect(loginUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|uploads|.*\\.(?:png|jpg|jpeg|webp|svg|ico|css|js)$).*)'],
}
