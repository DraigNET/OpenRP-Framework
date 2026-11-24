// A desktop session needs both SQL credentials and a current Manager account.
// Session passwords/challenges stay in memory; optional profiles are protected
// separately by the main-process OS-backed credential store.
import bcrypt from "bcryptjs";
import vehicleNames from "../../web-platform/shared/runtime-config/vehicle-names.json" with { type: "json" };
import weaponNames from "../../web-platform/shared/runtime-config/weapon-names.json" with { type: "json" };
import vehicleCatalogue from "../../web-platform/shared/runtime-config/vehicle-catalog.json" with { type: "json" };
import { restoreAvailability } from "./history.mjs";
import { randomInt, createHash, timingSafeEqual } from "node:crypto";
import {
  settings,
  locationCategories,
  locations,
} from "../../web-platform/shared/runtime-config/catalog.mjs";
import {
  acpEntityTypes,
  assertACPEntityType,
  assertACPEntityChanges,
} from "../../web-platform/shared/runtime-config/acp-entities.mjs";
import {
  getConfiguration,
  getHistory,
  saveConfiguration,
  restoreConfiguration,
} from "../../web-platform/shared/runtime-config/store.mjs";
import { getEntities } from "../../web-platform/shared/runtime-config/entity-store.mjs";

const digest = (value) => createHash("sha256").update(value).digest();
const now = () => Math.floor(Date.now() / 1000);
/**
 * Convert untrusted connection-form values into a fixed MariaDB option set. Never
 * accept driver flags, arbitrary SQL or a caller-supplied TLS verifier.
 */
export function connectionOptions(input) {
  if (
    !input ||
    typeof input.host !== "string" ||
    !input.host.trim() ||
    typeof input.database !== "string" ||
    !input.database.trim() ||
    typeof input.user !== "string" ||
    !input.user.trim() ||
    typeof input.password !== "string"
  )
    throw new Error("Enter the database host, name, user and password.");
  const port = Number(input.port || 3306);
  if (!Number.isInteger(port) || port < 1 || port > 65535)
    throw new Error("Database port must be from 1 to 65535.");
  return {
    host: input.host.trim(),
    port,
    database: input.database.trim(),
    user: input.user.trim(),
    password: input.password,
    ssl: input.tls ? { rejectUnauthorized: true } : undefined,
    connectTimeout: 5000,
    queryTimeout: 10000,
    socketTimeout: 15000,
    multipleStatements: false,
  };
}

/**
 * Own an expiring Manager session independently of Electron. Inject SQL, email and time
 * dependencies so authorization can be tested without a live database.
 */
export class EditorSession {
  /**
   * Accept trusted service adapters; credentials and actor state are initialized
   * separately for each login.
   */
  constructor({ connect, sendCode, clock = now }) {
    this.connect = connect;
    this.sendCode = sendCode;
    this.clock = clock;
    this.clear();
    this.failed = 0;
    this.retryAt = 0;
  }
  /**
   * Forget the active database/session/challenge. Saved encrypted profiles belong to
   * ConnectionProfiles and are deliberately unaffected by logout.
   */
  clear() {
    this.options = null;
    this.actor = null;
    this.challenge = null;
    this.expires = 0;
  }
  /**
   * Open a bounded connection for one operation and always close it. Shared repositories
   * manage their own transactions; avoid nesting those transactions.
   */
  async withDatabase(operation) {
    if (!this.options) throw new Error("Connect and sign in first.");
    const db = await this.connect(this.options);
    try {
      return await operation(db);
    } finally {
      await db.end();
    }
  }
  /**
   * Re-read current staff rank, password version and active bans. An earlier successful
   * login is not sufficient authority after an account changes.
   */
  async account(db, id) {
    const [row] = await db.query(
      "SELECT account_id,account_name,account_password,account_stafflevel,password_reset_version,twofa_enabled,account_email FROM accounts WHERE account_id=?",
      [id],
    );
    if (!row || row.account_stafflevel < 7 || row.password_reset_version < 1)
      throw new Error(
        "A current Manager account with a valid password is required.",
      );
    const [ban] = await db.query(
      "SELECT ban_id FROM bans WHERE account_id=? AND (unban_time=0 OR unban_time>?) LIMIT 1",
      [id, this.clock()],
    );
    if (ban) throw new Error("This account is banned.");
    return row;
  }
  /**
   * Authenticate database access and the Manager password, verify schema compatibility,
   * then require email 2FA when enabled. No actor is usable before the challenge
   * succeeds.
   */
  async login(input) {
    if (this.clock() < this.retryAt)
      throw new Error(
        "Too many unsuccessful attempts. Wait one minute before signing in again.",
      );
    this.clear();
    this.options = connectionOptions(input);
    try {
      return await this.withDatabase(async (db) => {
        if (
          typeof input.manager !== "string" ||
          typeof input.managerPassword !== "string" ||
          input.managerPassword.length > 256
        )
          throw new Error("Enter your Manager account and password.");
        const [found] = await db.query(
          "SELECT account_id FROM accounts WHERE account_name=?",
          [input.manager],
        );
        if (!found) throw new Error("Invalid Manager credentials.");
        const account = await this.account(db, found.account_id);
        const hash = account.account_password.replace(/^\$2y\$/, "$2b$");
        if (!(await bcrypt.compare(input.managerPassword, hash)))
          throw new Error("Invalid Manager credentials.");
        // Fail on incompatible schemas before exposing either configuration or controls.
        await getConfiguration(db);
        this.actor = {
          id: account.account_id,
          name: account.account_name,
          source: "desktop",
          passwordVersion: account.password_reset_version,
          hash: account.account_password,
          twofa: account.twofa_enabled,
        };
        if (account.twofa_enabled === 1) {
          const code = String(randomInt(100000, 1000000));
          this.challenge = {
            hash: digest(code),
            expires: this.clock() + 300,
            attempts: 0,
          };
          await this.sendCode(input.smtp, account.account_email, code);
          return { challenge: true };
        }
        this.expires = this.clock() + 1800;
        this.failed = 0;
        return { challenge: false, name: account.account_name };
      });
    } catch (error) {
      this.clear();
      if (++this.failed >= 5) {
        this.retryAt = this.clock() + 60;
        this.failed = 0;
      }
      throw error;
    }
  }
  /**
   * Consume a bounded, expiring, single-use email challenge, then revalidate the account
   * before opening the desktop session.
   */
  async verify(code) {
    const challenge = this.challenge;
    if (
      !challenge ||
      challenge.expires <= this.clock() ||
      challenge.attempts >= 5
    ) {
      this.clear();
      throw new Error("Email challenge expired. Sign in again.");
    }
    challenge.attempts++;
    if (
      typeof code !== "string" ||
      !/^\d{6}$/.test(code) ||
      !timingSafeEqual(challenge.hash, digest(code))
    )
      throw new Error("Invalid email code.");
    this.challenge = null;
    this.expires = this.clock() + 1800;
    this.failed = 0;
    await this.authorized((db) => db.query("SELECT 1"));
    return { name: this.actor.name };
  }
  // Every operation rechecks demotion, bans, password changes and MFA state.
  /**
   * Guard every configuration/process operation with the absolute session deadline and
   * current account security state. Password, name or 2FA changes invalidate the session.
   */
  async authorized(operation) {
    if (!this.actor || this.challenge || this.expires <= this.clock())
      throw new Error("Your desktop session expired. Sign in again.");
    return this.withDatabase(async (db) => {
      const row = await this.account(db, this.actor.id);
      if (
        row.account_name !== this.actor.name ||
        row.password_reset_version !== this.actor.passwordVersion ||
        row.account_password !== this.actor.hash ||
        row.twofa_enabled !== this.actor.twofa
      ) {
        this.clear();
        throw new Error("Account security changed. Sign in again.");
      }
      return operation(db);
    });
  }
  /**
   * Attach restore eligibility to history metadata before the UI offers an action. Do not
   * send large before/after snapshots with the ordinary history list.
   */
  async history(db) {
    const entries = await getHistory(db);
    for (const row of entries) {
      const [saved] = await db.query(
        "SELECT before_json FROM runtime_config_audit WHERE revision=?",
        [row.revision],
      );
      const snapshot =
        typeof saved?.before_json === "string"
          ? JSON.parse(saved.before_json)
          : saved?.before_json || {};
      Object.assign(row, restoreAvailability(row, snapshot));
    }
    return entries;
  }
  /**
   * Compose the renderer snapshot: shared configuration, history eligibility, faction
   * names and read-only catalogues. This is the main display contract to update after
   * schema changes.
   */
  async load() {
    return this.authorized(async (db) => ({
      configuration: await getConfiguration(db),
      history: await this.history(db),
      factions: await db.query(
        "SELECT faction_id AS id,faction_name AS name,faction_abbrev AS abbreviation FROM factions ORDER BY faction_id",
      ),
      settings,
      locationCategories,
      coreLocations: locations.map((row) => row.key),
      vehicleNames,
      weaponNames,
      vehicleCategories: Object.fromEntries(
        vehicleCatalogue.map((row) => [
          row.model,
          [
            "Budget",
            "Muscle",
            "Sports",
            "Utility",
            "Bikes",
            "Aircraft",
            "Boats",
            "Ships",
          ][row.type],
        ]),
      ),
      entityTypes: acpEntityTypes,
      name: this.actor.name,
    }));
  }
  /**
   * Read a historical before-snapshot only after checking identity, revision syntax and
   * restore ownership. This method never writes SQL.
   */
  async previewRestore(revision) {
    if (!Number.isInteger(revision) || revision < 1)
      throw new Error("Invalid history revision.");
    return this.authorized(async (db) => {
      const [row] = await db.query(
        "SELECT before_json,source,description FROM runtime_config_audit WHERE revision=?",
        [revision],
      );
      if (!row) throw new Error("History entry does not exist.");
      const before =
        typeof row.before_json === "string"
          ? JSON.parse(row.before_json)
          : row.before_json;
      const availability = restoreAvailability(row, before);
      if (!availability.restoreAvailable)
        throw new Error(availability.restoreReason);
      return before;
    });
  }
  /**
   * Read lightweight saved/applied revision and heartbeat data for polling without
   * replacing an open form’s draft snapshot.
   */
  async status() {
    return this.authorized(async (db) => {
      const [row] = await db.query(
        "SELECT revision,applied_revision,last_heartbeat,last_error FROM runtime_config_state WHERE id=1",
      );
      return row;
    });
  }
  /**
   * List a whitelisted desktop-editable family. In-game-owned placement families must
   * stay blocked even if a crafted IPC request names them.
   */
  async entities(type) {
    assertACPEntityType(type);
    return this.authorized((db) => getEntities(db, type));
  }
  /**
   * Pass an authenticated desktop actor and a revision-checked patch to the shared
   * transactional repository. All SQL writes and audit entries commit together.
   */
  async save(patch) {
    assertACPEntityChanges(patch?.entities);
    return this.authorized((db) => saveConfiguration(db, patch, this.actor));
  }
  /**
   * Recheck restore eligibility on the write path; hiding a button is not authorization.
   * The shared repository restores as a new revision, never a counter rewind.
   */
  async restore(revision, expectedRevision) {
    // Historical snapshots may contain entities owned by in-game editors.
    // Do not turn restore into a bypass of the desktop's editor scope.
    return this.authorized(async (db) => {
      const [row] = await db.query(
        "SELECT before_json,source,description FROM runtime_config_audit WHERE revision=?",
        [revision],
      );
      if (row) {
        const before =
          typeof row.before_json === "string"
            ? JSON.parse(row.before_json)
            : row.before_json;
        const availability = restoreAvailability(row, before);
        if (!availability.restoreAvailable)
          throw new Error(availability.restoreReason);
      }
      return restoreConfiguration(db, revision, expectedRevision, this.actor);
    });
  }
}
