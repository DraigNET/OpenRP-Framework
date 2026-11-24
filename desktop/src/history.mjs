import { assertACPEntityChanges } from "../../web-platform/shared/runtime-config/acp-entities.mjs";
// Decide before offering an action; a bulk SQL import is not a single desktop
// configuration change, and in-game-only entities retain their editor ownership.
export function restoreAvailability(row, snapshot) {
  if (
    row.source === "database" &&
    /bulk|demo content import|SQL backup/i.test(row.description || "")
  )
    return {
      restoreAvailable: false,
      restoreReason:
        "Bulk data import: restore the SQL backup to undo this change.",
      restoreLabel: "Backup required",
    };
  try {
    assertACPEntityChanges(snapshot.entities);
  } catch {
    return {
      restoreAvailable: false,
      restoreReason:
        "This change belongs to an in-game editor and cannot be restored from the desktop.",
      restoreLabel: "In-game tools required",
    };
  }
  if (snapshot.entities?.length > 100)
    return {
      restoreAvailable: false,
      restoreReason:
        "This batch is too large for an individual editor restore. Use a database backup.",
      restoreLabel: "Backup required",
    };
  return { restoreAvailable: true };
}
