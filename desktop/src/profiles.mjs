// Profiles are local application preferences, never game database records.
// Secret payloads are encrypted by Electron's OS-backed safeStorage in main.
import { readFile, writeFile, mkdir, rename, rm, stat } from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { connectionOptions } from "./session.mjs";

/**
 * Whitelist the encrypted profile payload. Session tokens and email codes never become
 * profile fields; connection options use the same normalization as login.
 */
export function profileDetails(input) {
  const options = connectionOptions(input);
  const string = (value) =>
    typeof value === "string" ? value.slice(0, 512) : "";
  return {
    host: options.host,
    port: options.port,
    database: options.database,
    user: options.user,
    password: options.password,
    tls: Boolean(input.tls),
    manager: string(input.manager),
    managerPassword: string(input.managerPassword),
    smtp: {
      host: string(input.smtp?.host),
      port: Number(input.smtp?.port) || 587,
      user: string(input.smtp?.user),
      password: string(input.smtp?.password),
      from: string(input.smtp?.from),
      secure: Boolean(input.smtp?.secure),
    },
  };
}
/**
 * Store named local connections through an injected OS-crypto adapter. Only labels/IDs
 * are public on disk; all connection credentials live in the encrypted payload.
 */
export class ConnectionProfiles {
  /**
   * Bind a trusted app-data path and encrypt/decrypt/availability adapter. The renderer
   * cannot supply arbitrary filesystem paths.
   */
  constructor(file, crypto) {
    this.file = file;
    this.crypto = crypto;
  }
  /**
   * Read bounded versioned profile metadata. Preserve corrupt or newer files rather than
   * silently replacing credentials with an empty list.
   */
  async read() {
    try {
      if ((await stat(this.file)).size > 1048576)
        throw Error("Saved connection file is too large.");
      const data = JSON.parse(await readFile(this.file, "utf8"));
      if (
        data.version !== 1 ||
        !Array.isArray(data.profiles) ||
        data.profiles.length > 50 ||
        data.profiles.some(
          (row) =>
            !row ||
            typeof row.id !== "string" ||
            typeof row.label !== "string" ||
            typeof row.encrypted !== "string",
        )
      )
        throw Error("Invalid saved connection file.");
      return data.profiles;
    } catch (error) {
      if (error.code === "ENOENT") return [];
      throw Error(
        "Could not read saved connections. Your existing file has not been replaced.",
      );
    }
  }
  /**
   * Replace the profile file atomically using a same-directory temporary file, cleaning
   * up partial writes on failure.
   */
  async write(rows) {
    await mkdir(path.dirname(this.file), { recursive: true });
    const temporary = this.file + "." + randomUUID() + ".tmp";
    try {
      await writeFile(
        temporary,
        JSON.stringify({ version: 1, profiles: rows }),
        { mode: 0o600 },
      );
      await rename(temporary, this.file);
    } finally {
      await rm(temporary, { force: true });
    }
  }
  /**
   * Return safe picker metadata only, in least-to-most recently used order. Passwords are
   * never decrypted for a plain profile list.
   */
  async list() {
    return (await this.read()).map(({ id, label }) => ({ id, label }));
  }
  /**
   * Decrypt one selected profile inside the main process. Failure is explicit; there is
   * no plaintext or cross-Windows-user fallback.
   */
  async details(id) {
    const row = (await this.read()).find((row) => row.id === id);
    if (!row)
      throw Error(
        "Saved connection no longer exists. Select another connection.",
      );
    if (!(await this.crypto.available()))
      throw Error(
        "Windows credential encryption is unavailable. Enter the connection manually.",
      );
    try {
      return profileDetails(
        JSON.parse(
          await this.crypto.decrypt(Buffer.from(row.encrypted, "base64")),
        ),
      );
    } catch {
      throw Error(
        "This saved connection cannot be decrypted by this Windows account. Forget it and connect again.",
      );
    }
  }
  /**
   * Expose connection fields and password-presence flags, not stored password values. The
   * renderer shows placeholders for protected credentials.
   */
  async publicDetails(id) {
    const value = await this.details(id);
    const { password, managerPassword, ...details } = value;
    const { password: smtpPassword, ...smtp } = value.smtp;
    return {
      ...details,
      smtp,
      hasPassword: password.length > 0,
      hasManagerPassword: managerPassword.length > 0,
      hasSmtpPassword: smtpPassword.length > 0,
    };
  }
  // Never return stored passwords to the renderer. Reuse them only for the
  // original connection identity; editing a host must not disclose credentials.
  /**
   * Merge typed fields with protected saved credentials only for the original
   * database/Manager/SMTP identity, preventing password disclosure to a changed
   * destination.
   */
  async resolve(input) {
    if (!input?.profileId) return input;
    const saved = await this.details(input.profileId),
      entered = profileDetails(input);
    if (!input.password) {
      if (
        ["host", "port", "database", "user", "tls"].some(
          (key) => entered[key] !== saved[key],
        )
      )
        throw Error(
          "Connection details changed. Enter the database password again.",
        );
      entered.password = saved.password;
    }
    if (
      !input.smtp?.password &&
      ["host", "port", "user", "from", "secure"].every(
        (key) => entered.smtp[key] === saved.smtp[key],
      )
    )
      entered.smtp.password = saved.smtp.password;
    if (!input.managerPassword && saved.managerPassword) {
      if (
        ["host", "port", "database", "user", "tls", "manager"].some(
          (key) => entered[key] !== saved[key],
        )
      )
        throw Error(
          "Manager connection changed. Enter the Manager password again.",
        );
      entered.managerPassword = saved.managerPassword;
    }
    return { ...input, ...entered };
  }
  /**
   * Encrypt and create/update a bounded named profile after authentication. Updating an
   * existing ID prevents duplicate profiles on each successful connection.
   */
  async save(input, id, label) {
    const details = profileDetails(input),
      rows = await this.read();
    if (!(await this.crypto.available()))
      throw Error(
        "Windows credential encryption is unavailable; connection was not saved.",
      );
    if (id && !rows.some((row) => row.id === id))
      throw Error("Saved connection no longer exists.");
    if (!id && rows.length >= 50)
      throw Error("At most 50 saved connections are supported.");
    const name = String(
      label || `${details.database} @ ${details.host}`,
    ).trim();
    if (!name || name.length > 64 || /[\u0000-\u001f]/.test(name))
      throw Error("Use a connection name of 1–64 characters.");
    const row = {
      id: id || randomUUID(),
      label: name,
      encrypted: (await this.crypto.encrypt(JSON.stringify(details))).toString(
        "base64",
      ),
    };
    await this.write([...rows.filter((value) => value.id !== row.id), row]);
    return row.id;
  }
  /**
   * Forget a local profile without touching accounts, SQL data or an existing editor
   * session.
   */
  async remove(id) {
    const rows = await this.read();
    await this.write(rows.filter((row) => row.id !== id));
    return true;
  }
  /**
   * Move the successfully used profile to the end without changing its encrypted
   * credentials; startup selects this last-used entry.
   */
  async touch(id) {
    const rows = await this.read(),
      row = rows.find((row) => row.id === id);
    if (row) await this.write([...rows.filter((row) => row.id !== id), row]);
  }
}
