// Encrypted profile boundaries with an injected test cipher; real Windows safeStorage is a separate integration check.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { randomBytes, createCipheriv, createDecipheriv } from "node:crypto";
import { ConnectionProfiles } from "../src/profiles.mjs";
async function fixture() {
  const directory = await mkdtemp(path.join(os.tmpdir(), "orp-profiles-")),
    file = path.join(directory, "connections.json"),
    key = randomBytes(32);
  const crypto = {
    available: async () => true,
    encrypt: async (text) => {
      const iv = randomBytes(12),
        cipher = createCipheriv("aes-256-gcm", key, iv);
      return Buffer.concat([
        iv,
        cipher.update(text),
        cipher.final(),
        cipher.getAuthTag(),
      ]);
    },
    decrypt: async (data) => {
      const cipher = createDecipheriv("aes-256-gcm", key, data.subarray(0, 12));
      cipher.setAuthTag(data.subarray(-16));
      return Buffer.concat([
        cipher.update(data.subarray(12, -16)),
        cipher.final(),
      ]).toString();
    },
  };
  const input = {
    host: "localhost",
    port: 3306,
    user: "editor",
    database: "omprp",
    password: "private-database-value",
    manager: "Manager",
    managerPassword: "never-store-this",
    smtp: {
      host: "localhost",
      port: 587,
      user: "mailer",
      from: "editor@example.test",
      password: "private-smtp-value",
    },
  };
  return {
    file,
    crypto,
    input,
    store: new ConnectionProfiles(file, crypto),
    cleanup: () => rm(directory, { recursive: true, force: true }),
  };
}
test("encrypted profiles survive reopening without exposing database or Manager passwords", async () => {
  const f = await fixture();
  try {
    const id = await f.store.save(f.input, undefined, "Local server"),
      text = await readFile(f.file, "utf8");
    for (const secret of [
      f.input.password,
      f.input.smtp.password,
      f.input.managerPassword,
    ])
      assert.equal(text.includes(secret), false);
    const reopened = new ConnectionProfiles(f.file, f.crypto),
      value = await reopened.publicDetails(id);
    assert.equal(value.password, undefined);
    assert.equal(value.smtp.password, undefined);
    assert.equal(value.managerPassword, undefined);
    assert.equal(value.hasPassword, true);
    assert.equal(value.hasManagerPassword, true);
    assert.equal(
      (await reopened.details(id)).managerPassword,
      f.input.managerPassword,
    );
    assert.equal(
      (
        await reopened.resolve({
          ...f.input,
          profileId: id,
          password: "",
          managerPassword: "",
        })
      ).managerPassword,
      f.input.managerPassword,
    );
    assert.equal(
      (
        await reopened.resolve({
          ...f.input,
          profileId: id,
          password: "",
          smtp: { ...f.input.smtp, password: "" },
        })
      ).password,
      f.input.password,
    );
    assert.equal((await reopened.list())[0].label, "Local server");
  } finally {
    await f.cleanup();
  }
});
test("stored passwords cannot be sent to a changed database or SMTP identity", async () => {
  const f = await fixture();
  try {
    const id = await f.store.save(f.input);
    await assert.rejects(
      f.store.resolve({
        ...f.input,
        profileId: id,
        password: "",
        host: "another-host",
      }),
      /changed/,
    );
    const value = await f.store.resolve({
      ...f.input,
      profileId: id,
      password: "",
      smtp: { ...f.input.smtp, host: "another-mail-host", password: "" },
    });
    assert.equal(value.smtp.password, "");
    await assert.rejects(
      f.store.resolve({
        ...f.input,
        profileId: id,
        password: "new-password",
        managerPassword: "",
        database: "other",
      }),
      /Manager connection changed/,
    );
    await assert.rejects(
      f.store.resolve({
        ...f.input,
        profileId: id,
        managerPassword: "",
        manager: "OtherManager",
      }),
      /Manager connection changed/,
    );
  } finally {
    await f.cleanup();
  }
});
test("profiles can be renamed, updated and forgotten", async () => {
  const f = await fixture();
  try {
    const id = await f.store.save(f.input);
    await f.store.save({ ...f.input, database: "other" }, id, "Updated");
    assert.equal((await f.store.list()).length, 1);
    assert.equal((await f.store.publicDetails(id)).database, "other");
    await f.store.remove(id);
    assert.deepEqual(await f.store.list(), []);
  } finally {
    await f.cleanup();
  }
});
test("unavailable OS encryption never falls back to plaintext", async () => {
  const f = await fixture();
  try {
    f.crypto.available = async () => false;
    await assert.rejects(f.store.save(f.input), /encryption is unavailable/);
    await assert.rejects(readFile(f.file));
  } finally {
    await f.cleanup();
  }
});
test("corrupted files are preserved instead of silently overwritten", async () => {
  const f = await fixture();
  try {
    await writeFile(f.file, "broken");
    await assert.rejects(f.store.save(f.input), /not been replaced/);
    assert.equal(await readFile(f.file, "utf8"), "broken");
  } finally {
    await f.cleanup();
  }
});
