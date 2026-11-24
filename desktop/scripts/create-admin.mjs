/**
 * Owner-run first-administrator bootstrap. Read DATABASE_URL from the process
 * environment, verify the current schema and serialize creation with an advisory lock.
 * Refuse to overwrite existing staff and print a newly generated password once; never
 * ship shared credentials.
 */
// Owner-run first-account bootstrap. No web server or seeded shared password.
import mariadb from "mariadb";
import bcrypt from "bcryptjs";
import { randomBytes } from "node:crypto";
import { getConfiguration } from "../../web-platform/shared/runtime-config/store.mjs";
const args = process.argv.slice(2),
  option = (name) => args[args.indexOf(name) + 1];
const name = args.includes("--name") ? option("--name") : "",
  email = args.includes("--email") ? option("--email") : "";
if (
  !/^[A-Za-z0-9_]{3,24}$/.test(name) ||
  !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
  !process.env.DATABASE_URL
) {
  console.error(
    "Set DATABASE_URL in your process environment, then run npm run admin:create -- --name Admin_User --email owner@example.com",
  );
  process.exit(1);
}
const url = new URL(process.env.DATABASE_URL);
const db = await mariadb.createConnection({
  host: url.hostname,
  port: Number(url.port || 3306),
  database: url.pathname.slice(1),
  user: decodeURIComponent(url.username),
  password: decodeURIComponent(url.password),
  connectTimeout: 5000,
});
let locked = false;
try {
  await getConfiguration(db);
  const [lock] = await db.query(
    "SELECT GET_LOCK(CONCAT(DATABASE(), ':admin-bootstrap'),10) AS held",
  );
  if (Number(lock.held) !== 1)
    throw Error("Another administrator bootstrap is running.");
  locked = true;
  await db.beginTransaction();
  const [existing] = await db.query(
    "SELECT COUNT(*) AS total FROM accounts WHERE account_stafflevel>0",
  );
  if (Number(existing.total))
    throw Error("An administrator already exists. Use your existing account.");
  const password = randomBytes(18).toString("base64url");
  await db.query(
    "INSERT INTO accounts(account_name,account_password,account_email,account_stafflevel,account_quiz_passed,password_reset_version,account_register_date) VALUES(?,?,?,8,1,1,UNIX_TIMESTAMP())",
    [name, await bcrypt.hash(password, 12), email],
  );
  await db.commit();
  console.log(
    "Administrator: " +
      name +
      "\nGenerated password: " +
      password +
      "\nSave this now; it is not written to a profile. Change it after signing in.",
  );
} catch (error) {
  await db.rollback();
  console.error(
    error.sqlState
      ? "Database bootstrap failed; check the matching schema and permissions."
      : error.message,
  );
  process.exitCode = 1;
} finally {
  if (locked)
    await db.query(
      "SELECT RELEASE_LOCK(CONCAT(DATABASE(), ':admin-bootstrap'))",
    );
  await db.end();
}
