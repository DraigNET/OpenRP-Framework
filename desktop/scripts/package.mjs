// Stage the editor and the canonical shared source together; never package the
// framework checkout, its private configs, databases or downloaded game files.
import { cp, mkdir, rm, writeFile, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { packager } from "@electron/packager";
const root = fileURLToPath(new URL("../", import.meta.url));
const stage = path.join(root, ".build", "app");
// Recreate only this script-owned staging directory, not the framework checkout.
await rm(stage, { recursive: true, force: true });
await mkdir(path.join(stage, "desktop"), { recursive: true });
for (const directory of ["src", "ui"])
  await cp(path.join(root, directory), path.join(stage, "desktop", directory), {
    recursive: true,
  });
const lock = JSON.parse(
  await readFile(path.join(root, "package-lock.json"), "utf8"),
);
// Production lockfile entries exclude build tools and the Electron npm installer.
// Electron's actual runtime is supplied by packager separately.
for (const [directory, entry] of Object.entries(lock.packages)) {
  if (!directory || entry.dev || !directory.startsWith("node_modules/"))
    continue;
  const destination = path.join(stage, "desktop", directory);
  await mkdir(path.dirname(destination), { recursive: true });
  await cp(path.join(root, directory), destination, { recursive: true });
}
await cp(
  path.join(root, "..", "web-platform", "shared", "runtime-config"),
  path.join(stage, "web-platform", "shared", "runtime-config"),
  { recursive: true },
);
const pkg = JSON.parse(await readFile(path.join(root, "package.json"), "utf8"));
// Retain the relative desktop/shared layout expected by source imports. The new
// manifest changes the entry point, never an operator's runtime configuration.
await writeFile(
  path.join(stage, "package.json"),
  JSON.stringify({
    name: pkg.name,
    productName: "OpenRP Framework Editor",
    version: pkg.version,
    type: "module",
    main: "desktop/src/main.mjs",
    private: true,
  }),
);
await cp(path.join(root, "..", "LICENSE"), path.join(stage, "LICENSE"));
await cp(path.join(root, "..", "CREDITS.md"), path.join(stage, "CREDITS.md"));
const applications = await packager({
  dir: stage,
  out: path.join(root, "dist"),
  platform: "win32",
  arch: "x64",
  name: "OpenRP Framework Editor",
  electronVersion: pkg.devDependencies.electron,
  overwrite: true,
  prune: false,
  // Native .node/DLL/console-helper files need real filesystem paths at runtime.
  asar: { unpackDir: "**/node-pty/**" },
});
// Keep the readable guides beside the portable app, where operators can open
// them without extracting ASAR. Preserve Electron's own LICENSE filename.
for (const directory of applications) {
  await cp(path.join(root, "README.md"), path.join(directory, "README.md"));
  await cp(path.join(root, "docs"), path.join(directory, "docs"), {
    recursive: true,
  });
  await cp(
    path.join(root, "..", "LICENSE"),
    path.join(directory, "OPENRP-LICENSE"),
  );
  await cp(
    path.join(root, "..", "CREDITS.md"),
    path.join(directory, "CREDITS.md"),
  );
}
console.log(
  "Portable Windows app created in desktop/dist/. Distribute the whole generated app folder.",
);
