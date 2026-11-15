import 'server-only'
import { cache } from 'react'
import { redirect, notFound } from 'next/navigation'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { ADMIN_LVL } from '@/lib/constants'

/**
 * Data Access Layer — the single place authorization and ownership checks live.
 *
 * Pages/actions should call these instead of hitting prisma directly for
 * session-scoped data, so a column or an auth rule can never be forgotten in
 * one corner of the app. Reads are wrapped in React's `cache()` so calling the
 * same helper in both a layout and its page only queries once per request.
 */

export interface SessionUser {
  id: number
  name: string
  staffLevel: number
  passwordResetRequired: boolean
  twoFaEnabled: boolean
}

/**
 * Current time in ms, fixed once per request. Server components render once on
 * the server, so a single "now" keeps all relative-time math on a page
 * consistent (and keeps it out of render-purity lint rules meant for the client).
 */
export const serverNow = cache((): number => Date.now())

/** Returns the session user, or null if not signed in. Memoised per request.
 *
 * staffLevel is read live from the DB rather than trusted from the login-time
 * JWT, so promotions/demotions take effect immediately — a demoted or revoked
 * admin loses ACP access on their next request instead of waiting for the token
 * to expire. (`cache()` keeps this to one query per request.) */
export const getSessionUser = cache(async (): Promise<SessionUser | null> => {
  const session = await auth()
  if (!session) return null
  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_stafflevel: true },
  })
  if (!account) return null
  return {
    id: session.user.id,
    name: session.user.name ?? '',
    staffLevel: account ? account.account_stafflevel : 0,
    passwordResetRequired: session.user.passwordResetRequired,
    twoFaEnabled: session.user.twoFaEnabled,
  }
})

/** Requires a signed-in user; redirects to login otherwise. */
export const requireUser = cache(async (): Promise<SessionUser> => {
  const user = await getSessionUser()
  if (!user) redirect('/ucp/login')
  return user
})

/** Loads any account by id for ACP views (memoised per request). */
export const getAccountById = cache(async (id: number) => {
  if (!Number.isInteger(id) || id <= 0) return null
  return prisma.account.findUnique({ where: { account_id: id } })
})

/** Loads any character by id for ACP views (memoised per request). */
export const getCharacterById = cache(async (id: number) => {
  if (!Number.isInteger(id) || id <= 0) return null
  return prisma.character.findUnique({ where: { player_id: id } })
})

/** Loads any faction by id for ACP views (memoised per request). */
export const getFactionById = cache(async (id: number) => {
  if (!Number.isInteger(id) || id <= 0) return null
  return prisma.faction.findUnique({ where: { faction_id: id } })
})

/** Requires a signed-in staff member at or above `level`; otherwise redirect. */
export async function requireStaff(level: number = ADMIN_LVL.JUNIOR): Promise<SessionUser> {
  const user = await requireUser()
  if (user.staffLevel < level) redirect('/ucp')
  return user
}

/** True if the current user is staff at or above `level`. */
export async function isStaff(level: number = ADMIN_LVL.JUNIOR): Promise<boolean> {
  const user = await getSessionUser()
  return !!user && user.staffLevel >= level
}

/**
 * Loads a character the current user owns, or null. Centralises the
 * "find character WHERE player_id=? AND account_id=session" pattern.
 */
export const getOwnedCharacter = cache(async (playerId: number) => {
  const user = await getSessionUser()
  if (!user) return null
  return prisma.character.findFirst({
    where: { player_id: playerId, account_id: user.id },
  })
})

/** Like getOwnedCharacter but 404s if it doesn't exist / isn't owned. */
export async function requireOwnedCharacter(playerId: number) {
  const char = await getOwnedCharacter(playerId)
  if (!char) notFound()
  return char
}

/**
 * Loads an owned character that is in a faction (factionid > 0), 404 otherwise.
 * Used by every faction sub-page.
 */
export async function requireFactionCharacter(playerId: number) {
  const char = await requireOwnedCharacter(playerId)
  if (char.player_factionid <= 0) notFound()
  return char
}

