/** Verify the host toolchain and install Electron if npm skipped its install hook.
 * This command prepares development dependencies only; it never connects to SQL.
 */
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
const root = fileURLToPath(new URL("../", import.meta.url));
const require = createRequire(new URL("../package.json", import.meta.url));
const [major, minor] = process.versions.node.split(".").map(Number);
if (major < 22 || (major === 22 && minor < 12))
  throw Error(
    "Install Node.js 22.12 or newer before building the desktop editor.",
  );
let executable;
try {
  executable = require("electron");
} catch {
  /* A managed npm policy can skip postinstall. */
}
if (!executable || !existsSync(executable)) {
  console.log("Downloading the pinned Electron runtime (no database access).");
  execFileSync(process.execPath, ["node_modules/electron/install.js"], {
    cwd: root,
    stdio: "inherit",
  });
}
if (process.platform === "win32") {
  try {
    require("node-pty");
  } catch {
    throw Error(
      "Windows console prebuilds could not load. Run npm ci again; custom node-pty builds may need native build tools.",
    );
  }
}
console.log("Desktop development dependencies are ready.");
