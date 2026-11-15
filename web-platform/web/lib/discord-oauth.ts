import 'server-only'
import { env } from './env'

export interface DiscordUser {
  id: string
  username: string
  discriminator: string
  displayName: string
}

/** Exchanges a Discord OAuth code for an access token. Returns null on failure. */
export async function exchangeDiscordCode(
  code: string,
  redirectUri: string,
): Promise<string | null> {
  const res = await fetch('https://discord.com/api/oauth2/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: env.discordClientId,
      client_secret: env.discordClientSecret,
      grant_type: 'authorization_code',
      code,
      redirect_uri: redirectUri,
    }),
  })
  if (!res.ok) return null
  const data = await res.json()
  return data.access_token ?? null
}

/** Fetches the Discord user profile using a Bearer token. Returns null on failure. */
export async function fetchDiscordUser(accessToken: string): Promise<DiscordUser | null> {
  const res = await fetch('https://discord.com/api/users/@me', {
    headers: { Authorization: `Bearer ${accessToken}` },
  })
  if (!res.ok) return null
  const u = await res.json()
  if (!u.id) return null
  const discrim = u.discriminator && u.discriminator !== '0' ? `#${u.discriminator}` : ''
  return {
    id: u.id,
    username: u.username,
    discriminator: u.discriminator ?? '0',
    displayName: `${u.username}${discrim}`,
  }
}

/**
 * Checks if a Discord user is in the configured guild via the bot token.
 * Returns true if:
 *   - no guild is configured (check disabled)
 *   - the bot token is missing/invalid (fail-open)
 *   - the user IS a member (200)
 * Returns false only on a definitive 404 (not a member).
 */
export async function isInGuild(discordId: string): Promise<boolean> {
  const { discordGuildId: guildId, discordBotToken: botToken } = env
  if (!guildId) return true
  if (!botToken) return true
  try {
    const res = await fetch(
      `https://discord.com/api/guilds/${guildId}/members/${discordId}`,
      { headers: { Authorization: `Bot ${botToken}` } },
    )
    if (res.status === 200) return true
    if (res.status === 404) return false
    return true // 401/403 = bot config issue, fail open
  } catch {
    return true
  }
}

/** Assigns the UCP Verified role. Non-blocking — failure is silently ignored. */
export function assignUcpRole(discordId: string): void {
  const { discordGuildId: guildId, discordBotToken: botToken, discordRoleId: roleId } = env
  if (!guildId || !botToken || !roleId) return
  fetch(
    `https://discord.com/api/guilds/${guildId}/members/${discordId}/roles/${roleId}`,
    { method: 'PUT', headers: { Authorization: `Bot ${botToken}`, 'Content-Length': '0' } },
  ).catch(() => {})
}

/** Removes the UCP Verified role. Non-blocking — failure is silently ignored. */
export function removeUcpRole(discordId: string): void {
  const { discordGuildId: guildId, discordBotToken: botToken, discordRoleId: roleId } = env
  if (!guildId || !botToken || !roleId) return
  fetch(
    `https://discord.com/api/guilds/${guildId}/members/${discordId}/roles/${roleId}`,
    { method: 'DELETE', headers: { Authorization: `Bot ${botToken}` } },
  ).catch(() => {})
}
