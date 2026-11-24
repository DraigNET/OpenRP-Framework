// Owned-process lifecycle tests use disposable Node children, never a community game server.
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import dgram from "node:dgram";
import { LocalServer } from "../src/server.mjs";

async function fixture(options = {}) {
  const directory = await mkdtemp(path.join(os.tmpdir(), "orp-desktop-test-"));
  await writeFile(
    path.join(directory, "omp-server.exe"),
    "test fixture, never executed",
  );
  await writeFile(
    path.join(directory, "config.json"),
    JSON.stringify({ network: { port: 7788 } }),
  );
  const server = new LocalServer({
    platform: "win32",
    checkPort: async () => {},
    launch: (_executable, _args, settings) =>
      spawn(
        process.execPath,
        [
          "-e",
          "console.log('ready');process.stdin.on('data',d=>{if(d.toString().includes('exit'))process.exit(0)})",
        ],
        settings,
      ),
    ...options,
  });
  await server.select(directory);
  return {
    server,
    directory,
    cleanup: async () => {
      if (server.child) await server.stop(true);
      await rm(directory, { recursive: true, force: true });
    },
  };
}
test("launches only its own child, refuses duplicate starts and stops gracefully", async () => {
  const f = await fixture();
  try {
    await f.server.start();
    assert.equal(f.server.status().running, true);
    await assert.rejects(f.server.start(), /already/);
    await assert.rejects(f.server.select(f.directory), /Stop/);
    await f.server.stop();
    assert.equal(f.server.status().running, false);
    assert.match(f.server.status().log, /Server exited/);
  } finally {
    await f.cleanup();
  }
});
test("refuses a busy game port before launching any process", async () => {
  const socket = dgram.createSocket("udp4");
  await new Promise((resolve) => socket.bind(0, "127.0.0.1", resolve));
  const f = await fixture({ checkPort: undefined });
  try {
    await writeFile(
      path.join(f.directory, "config.json"),
      JSON.stringify({ network: { port: socket.address().port } }),
    );
    await assert.rejects(f.server.start(), /port is unavailable/);
    assert.equal(f.server.child, null);
  } finally {
    socket.close();
    await f.cleanup();
  }
});
test("bounded console output and explicit force stop", async () => {
  const f = await fixture();
  try {
    f.server.append("a".repeat(250000));
    assert.equal(f.server.log.length, 200000);
    await f.server.start();
    await f.server.stop(true);
    assert.equal(f.server.status().running, false);
  } finally {
    await f.cleanup();
  }
});
test("invalid config and missing runtime fail without launching", async () => {
  const f = await fixture();
  try {
    await writeFile(path.join(f.directory, "config.json"), "{}");
    await f.server.start();
    await f.server.stop(true);
    await writeFile(path.join(f.directory, "config.json"), "{bad");
    await assert.rejects(f.server.start());
    await rm(path.join(f.directory, "omp-server.exe"));
    await assert.rejects(f.server.start());
    assert.equal(f.server.child, null);
  } finally {
    await f.cleanup();
  }
});
