// ============================================================================
// File: visuals/remove.pwn
// Comment-only guide to removing default GTA buildings with a hook on OnRemoveBuilding.
// ============================================================================

// Add RemoveBuilding(...) calls for your own maps inside a hook of this form:
//
//   hook OnRemoveBuilding() {
//       RemoveBuilding(1432, 2104.0156, -1812.4219, 12.6719, 50.0);
//   }
