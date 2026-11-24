import 'server-only'

/**
 * Validated environment access. Fail fast at first use with a clear message
 * instead of a cryptic downstream error when a required var is missing.
 * Import `env.X` rather than reading process.env scattered across the app.
 */
function required(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`Missing required environment variable: ${name}`)
  return v
}

function optional(name: string, fallback = ''): string {
  return process.env[name] ?? fallback
}

export const env = {
  get databaseUrl() { return required('DATABASE_URL') },
  get authSecret() { return required('AUTH_SECRET') },
  get siteUrl() { return optional('AUTH_URL', 'http://localhost:3000').replace(/\/$/, '') },
  get customSkinsEnabled() { return process.env.CUSTOM_SKINS_ENABLED === 'true' },
  // Discord is opt-in and requires the full OAuth/bot configuration.
  get discordEnabled() { return process.env.DISCORD_ENABLED === 'true' && ['AUTH_DISCORD_ID', 'AUTH_DISCORD_SECRET', 'DISCORD_BOT_TOKEN', 'DISCORD_GUILD_ID', 'DISCORD_UCP_ROLE_ID'].every(name => !!process.env[name]?.trim()) },
  // Discord OAuth
  get discordClientId() { return required('AUTH_DISCORD_ID') },
  get discordClientSecret() { return required('AUTH_DISCORD_SECRET') },
  get discordGuildId() { return optional('DISCORD_GUILD_ID') },
  get discordBotToken() { return optional('DISCORD_BOT_TOKEN') },
  get discordRoleId() { return optional('DISCORD_UCP_ROLE_ID') },
  // Game server query
  get sampQueryHost() { return optional('SAMP_QUERY_HOST', optional('RCON_HOST', '127.0.0.1')) },
  get rconPort() { return Number(optional('RCON_PORT', '7777')) },

}
