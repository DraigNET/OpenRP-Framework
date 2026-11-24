// Authorization/MFA regression tests inject SQL, email and clock adapters; no real accounts or inboxes are used.
import { test } from "node:test";
import assert from "node:assert/strict";
import bcrypt from "bcryptjs";
import { EditorSession, connectionOptions } from "../src/session.mjs";

async function fixture() {
  let time = 1000,
    code,
    banned = false,
    closed = 0,
    history = {};
  const row = {
    account_id: 1,
    account_name: "Manager",
    account_stafflevel: 7,
    account_password: await bcrypt.hash("test-only-password", 4),
    password_reset_version: 1,
    twofa_enabled: 0,
    account_email: "manager@example.test",
  };
  const query = async (sql) => {
    if (sql.includes("SELECT account_id FROM accounts"))
      return [{ account_id: 1 }];
    if (sql.includes("FROM accounts WHERE account_id")) return [{ ...row }];
    if (sql.includes("FROM bans")) return banned ? [{ ban_id: 1 }] : [];
    if (sql.includes("SELECT before_json"))
      return [{ before_json: JSON.stringify(history) }];
    if (sql.includes("FROM runtime_config_state"))
      return [
        {
          revision: 1,
          applied_revision: 1,
          last_heartbeat: time,
          last_error: "",
          schema_version: 4,
        },
      ];
    return [];
  };
  const session = new EditorSession({
    clock: () => time,
    connect: async () => ({
      query,
      beginTransaction: async () => {},
      commit: async () => {},
      rollback: async () => {},
      end: async () => {
        closed++;
      },
    }),
    sendCode: async (_smtp, _email, value) => {
      code = value;
    },
  });
  const input = {
    host: "127.0.0.1",
    database: "orp_test",
    user: "editor",
    password: "",
    manager: "Manager",
    managerPassword: "test-only-password",
  };
  return {
    session,
    input,
    row,
    code: () => code,
    ban: () => {
      banned = true;
    },
    advance: (seconds) => {
      time += seconds;
    },
    closed: () => closed,
    history: (value) => {
      history = value;
    },
  };
}

test("connection options whitelist driver flags and require verified TLS when selected", () => {
  const config = connectionOptions({
    host: "localhost",
    database: "orp",
    user: "editor",
    password: "secret",
    tls: true,
    multipleStatements: true,
    ssl: { rejectUnauthorized: false },
  });
  assert.equal(config.multipleStatements, false);
  assert.equal(config.ssl.rejectUnauthorized, true);
  assert.throws(() =>
    connectionOptions({
      host: "localhost",
      database: "orp",
      user: "u",
      password: "",
      port: 65536,
    }),
  );
});
test("database credentials alone cannot expose data or local controls", async () => {
  const f = await fixture();
  await assert.rejects(f.session.load(), /expired/);
  await assert.rejects(
    f.session.login({ ...f.input, managerPassword: "wrong" }),
    /credentials/,
  );
  await assert.rejects(
    f.session.authorized(() => true),
    /expired/,
  );
});
test("Manager login uses PHP bcrypt compatibility and closes database connections", async () => {
  const f = await fixture();
  f.row.account_password = f.row.account_password.replace("$2b$", "$2y$");
  assert.equal((await f.session.login(f.input)).challenge, false);
  assert.equal((await f.session.load()).name, "Manager");
  assert.equal(f.closed(), 2);
});
test("demotion and active bans block subsequent operations", async () => {
  const f = await fixture();
  await f.session.login(f.input);
  f.row.account_stafflevel = 6;
  await assert.rejects(f.session.status(), /Manager/);
  f.row.account_stafflevel = 7;
  f.ban();
  await assert.rejects(f.session.status(), /banned/);
});
test("password reset, MFA changes and absolute session expiry revoke access", async () => {
  for (const mutate of [
    (f) => f.row.password_reset_version++,
    (f) => (f.row.twofa_enabled = 1),
    (f) => f.advance(1801),
  ]) {
    const f = await fixture();
    await f.session.login(f.input);
    mutate(f);
    await assert.rejects(f.session.load(), /changed|expired/);
  }
});
test("MFA requires a single-use code, bounds guesses and expires", async () => {
  const f = await fixture();
  f.row.twofa_enabled = 1;
  assert.equal((await f.session.login(f.input)).challenge, true);
  await assert.rejects(f.session.load(), /expired/);
  await assert.rejects(f.session.verify("000000"), /Invalid/);
  await f.session.verify(f.code());
  assert.equal((await f.session.load()).name, "Manager");
  await assert.rejects(f.session.verify(f.code()), /expired/);
  await f.session.login(f.input);
  f.advance(301);
  await assert.rejects(f.session.verify(f.code()), /expired/);
  await f.session.login(f.input);
  for (let i = 0; i < 5; i++)
    await assert.rejects(f.session.verify("000000"), /Invalid/);
  await assert.rejects(f.session.verify(f.code()), /expired/);
});
test("failed credentials are throttled within the editor process", async () => {
  const f = await fixture();
  for (let i = 0; i < 5; i++)
    await assert.rejects(
      f.session.login({ ...f.input, managerPassword: "wrong" }),
    );
  await assert.rejects(f.session.login(f.input), /Wait one minute/);
  f.advance(61);
  await f.session.login(f.input);
});
test("desktop cannot bypass in-game editor ownership", async () => {
  const f = await fixture();
  await f.session.login(f.input);
  for (const type of [
    "gate",
    "atm",
    "repair_refuel",
    "property_placement",
    "vehicle_spawn",
    "dealership_placement",
  ]) {
    await assert.rejects(f.session.entities(type));
    await assert.rejects(
      f.session.save({ entities: [{ type, id: 1, record: null }] }),
    );
  }
});
test("history preview and restore cannot bypass in-game editor ownership", async () => {
  const f = await fixture();
  await f.session.login(f.input);
  f.history({ entities: [{ type: "atm", id: 1, record: null }] });
  await assert.rejects(f.session.previewRestore(2), /in-game editor/);
  await assert.rejects(f.session.restore(2, 1), /in-game editor/);
});
test("SMTP failure cannot leave an authorized desktop session", async () => {
  const f = await fixture();
  f.row.twofa_enabled = 1;
  f.session.sendCode = async () => {
    throw Error("SMTP unavailable");
  };
  await assert.rejects(f.session.login(f.input), /SMTP/);
  await assert.rejects(f.session.load(), /expired/);
});
