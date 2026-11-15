import bcrypt from 'bcryptjs'

const BCRYPT_ROUNDS = 10

/**
 * Verifies a plaintext password against a stored bcrypt hash.
 * PHP stores hashes with the `$2y$` identifier, which bcryptjs doesn't
 * recognise — they're otherwise identical to `$2b$`, so we normalise first.
 */
export async function verifyPassword(plain: string, stored: string): Promise<boolean> {
  const hash = stored.startsWith('$2y$') ? '$2b$' + stored.slice(4) : stored
  return bcrypt.compare(plain, hash)
}

/** Hashes a new password for storage (emits the standard `$2b$` identifier). */
export async function hashPassword(plain: string): Promise<string> {
  return bcrypt.hash(plain, BCRYPT_ROUNDS)
}
