import * as mariadb from 'mariadb'
import bcrypt from 'bcryptjs'
import { randomBytes } from 'node:crypto'

/** One-time bootstrap, intentionally separate from schema import. No shared password ships. */
const args = process.argv.slice(2)
const option = name => { const i = args.indexOf(name); return i < 0 ? undefined : args[i + 1] }
const name = option('--name')
const email = option('--email')
if (!/^[A-Za-z0-9_]{3,24}$/.test(name ?? '') || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email ?? '')) {
  console.error('Usage: npm run admin:create -- --name Admin_User --email owner@example.com')
  process.exit(1)
}
if (!process.env.DATABASE_URL) { console.error('Set DATABASE_URL in .env.local first.'); process.exit(1) }
const url = new URL(process.env.DATABASE_URL)
const db = await mariadb.createConnection({ host: url.hostname, port: Number(url.port || 3306), user: decodeURIComponent(url.username), password: decodeURIComponent(url.password), database: url.pathname.slice(1) })
let locked = false
try {
  const [lock] = await db.query("SELECT GET_LOCK(CONCAT(DATABASE(), ':admin-bootstrap'), 10) AS held")
  if (Number(lock.held) !== 1) throw new Error('Another bootstrap is running; try again later.')
  locked = true
  await db.beginTransaction()
  const [existing] = await db.query('SELECT COUNT(*) AS total FROM accounts WHERE account_stafflevel > 0')
  if (Number(existing.total)) throw new Error('An administrator already exists. Use the ACP to manage staff.')
  const password = randomBytes(18).toString('base64url')
  await db.query('INSERT INTO accounts (account_name, account_password, account_email, account_stafflevel, account_quiz_passed, password_reset_version, account_register_date) VALUES (?, ?, ?, 8, 1, 1, UNIX_TIMESTAMP())', [name, await bcrypt.hash(password, 12), email])
  await db.commit()
  console.log('Administrator created at Developer level (8). No character or map content was seeded.')
  console.log('Username: ' + name)
  console.log('One-time generated password: ' + password)
  console.log('Save this password now. It is not written to a file. Change it after signing in.')
} catch (error) {
  await db.rollback()
  console.error(error.message)
  process.exitCode = 1
} finally {
  if (locked) await db.query("SELECT RELEASE_LOCK(CONCAT(DATABASE(), ':admin-bootstrap'))")
  await db.end()
}

