// Compare persistent custom gun IDs to the Pawn table and verify shared input bounds.
import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import names from "../../web-platform/shared/runtime-config/weapon-names.json" with { type: "json" };
import { validateEntityPatch } from "../../web-platform/shared/runtime-config/entity-store.mjs";
test("armory labels follow custom gun table IDs rather than GTA weapon IDs", () => {
  const pawn = fs.readFileSync(
      new URL("../../gamemodes/weapons/data/header.pwn", import.meta.url),
      "utf8",
    ),
    block = pawn.match(
      /new Weapon\s*\[32\]\s*\[E_WEAPON_DATA\]\s*=\s*\{([\s\S]*?)\}\s*;/,
    )[1];
  assert.deepEqual(
    names,
    [...block.matchAll(/\{[^,]+,\s*"([^"]+)"/g)].map((match) => match[1]),
  );
  assert.equal(names[28], "Police Glock");
  assert.equal(names[20], "Shotgun");
  const record = {
    faction_id: 1,
    armory_type_id: 0,
    weapon_id: 20,
    weapon_ammo: 100,
    tier_limit: 0,
    squad_id: 0,
    off_duty_allowed: 0,
    weapon_enabled: 1,
    sort_order: 0,
  };
  assert.doesNotThrow(() =>
    validateEntityPatch({ type: "armory_weapon", id: 0, record }),
  );
  assert.throws(() =>
    validateEntityPatch({
      type: "armory_weapon",
      id: 0,
      record: { ...record, weapon_id: 32 },
    }),
  );
});
