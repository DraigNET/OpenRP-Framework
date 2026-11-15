/** A permanent ban has no expiry. Keep this identical across all login methods. */
export function activeBanWhere(accountId: number, now = Math.floor(Date.now() / 1000)) {
  return { account_id: accountId, OR: [{ unban_time: 0 }, { unban_time: { gt: now } }] }
}

/** Only allow internal callback URLs; reject protocol-relative URLs and browser-normalised backslashes. */
export function safeCallbackUrl(value: unknown): string {
  if (typeof value !== 'string' || !value.startsWith('/') || value.startsWith('//') || /[\\\u0000-\u0020]/.test(value)) return '/ucp'
  const url = new URL(value, 'https://local.invalid')
  return url.origin === 'https://local.invalid' ? url.pathname + url.search + url.hash : '/ucp'
}
