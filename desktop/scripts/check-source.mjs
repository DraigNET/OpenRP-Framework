/** Catch incomplete source exports and syntax errors before building a binary.
 * The renderer is syntax-checked, not executed as Node; its APIs exist in Electron.
 */
import { readdirSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
const root = fileURLToPath(new URL("../", import.meta.url));
const framework = path.resolve(root, "..");
for (const relative of [
  "database/schema.sql",
  "LICENSE",
  "CREDITS.md",
  "gamemodes/weapons/data/header.pwn",
  "web-platform/shared/runtime-config/store.mjs",
  "web-platform/shared/runtime-config/entity-store.mjs",
  "web-platform/shared/runtime-config/catalog.mjs",
  "web-platform/shared/runtime-config/vehicle-names.json",
  "web-platform/shared/runtime-config/weapon-names.json",
]) {
  if (!existsSync(path.join(framework, relative)))
    throw Error(
      "Use a complete framework source checkout. Missing: " + relative,
    );
}
/** Walk only first-party source folders; skip node_modules and build output. */
function files(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) =>
    entry.isDirectory()
      ? files(path.join(directory, entry.name))
      : [path.join(directory, entry.name)],
  );
}
const sources = ["src", "ui", "scripts", "test"]
  .flatMap((directory) => files(path.join(root, directory)))
  .filter((file) => /\.(mjs|cjs|js)$/.test(file));
for (const file of sources)
  execFileSync(process.execPath, ["--check", file], { stdio: "inherit" });
console.log(
  "Checked " +
    sources.length +
    " JavaScript source files and required repository dependencies.",
);
