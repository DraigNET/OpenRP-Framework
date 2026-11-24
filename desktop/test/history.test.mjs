// History ownership and bulk-import policy; tests only pure eligibility decisions.
import { test } from "node:test";
import assert from "node:assert/strict";
import { restoreAvailability } from "../src/history.mjs";
test("bulk imports clearly require a database backup before offering restore", () => {
  const result = restoreAvailability(
    {
      source: "database",
      description:
        "Anonymised local demo content import; use the SQL backup for full rollback",
    },
    { entities: [{ type: "vehicle_spawn", id: 1 }] },
  );
  assert.equal(result.restoreAvailable, false);
  assert.equal(result.restoreLabel, "Backup required");
  assert.match(result.restoreReason, /SQL backup/);
});
test("in-game-owned changes keep their editor boundary", () => {
  assert.equal(
    restoreAvailability({}, { entities: [{ type: "atm", id: 1 }] })
      .restoreAvailable,
    false,
  );
});
test("ordinary settings and supported equipment changes remain restorable", () => {
  assert.equal(
    restoreAvailability({}, { settings: { "dmv.fee": 250 } }).restoreAvailable,
    true,
  );
  assert.equal(
    restoreAvailability({}, { entities: [{ type: "locker", id: 1 }] })
      .restoreAvailable,
    true,
  );
});
