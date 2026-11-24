# Adapt the editor when your database changes

The desktop and ACP share their configuration definitions and SQL repository.
Update that contract once rather than making independent editors write different
shapes. All paths below are relative to the framework root.

## Choose the change path

| Change                                        | Main files to inspect                                                                                           |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| New scalar gameplay setting                   | `web-platform/shared/runtime-config/catalog.mjs`, `validation.mjs`, game consumer                               |
| New location field/category                   | `types.ts`, `catalog.mjs`, `validation.mjs`, `store.mjs`, desktop form and game runtime loader/adapter          |
| Existing equipment field or new editor family | `entities.mjs`, `entity-store.mjs`, desktop form helpers and game adapter                                       |
| Table/column rename                           | `database/schema.sql`, shared SQL metadata/queries, raw auth queries, web ORM and game loaders/savers           |
| Display label/category only                   | Shared catalogue or `ui/app.js`; SQL may not need to change                                                     |
| Account authentication change                 | `desktop/src/session.mjs`, `scripts/create-admin.mjs`, shared write-time Manager check, web/game authentication |
| Local saved connection change                 | `desktop/src/profiles.mjs`; this is not a game-schema migration                                                 |

## Keep the complete fresh schema current

`database/schema.sql` is the only required fresh-install import. Handwritten runtime
DDL and firm routines are maintained there. The generator reads those sections
from the same file and refreshes catalogue defaults, journal triggers and Pawn
identifiers. It neither requires nor emits a list of migration fragments.

After changing catalogue definitions or journal metadata, run from the root:

```sh
node tools/runtime-config/generate.mjs
node tools/runtime-config/generate.mjs --check
```

Do not manually edit generated Pawn catalogues or generated SQL defaults/triggers;
the next generation will overwrite them. Preserve the section markers in the full
schema. Run the check before committing so a fresh checkout does not need extra SQL
files to catch up.

Import the full schema into a **new empty database** for validation. It is not an
upgrade/reset command for an existing server. Downstream server owners with live
data must separately plan a backup and a compatible upgrade for their own changes;
the editor does not apply arbitrary schema migrations during login or saving.

## Add a scalar setting

1. Add a definition to `catalog.mjs`: persistent key, group, readable label, type,
   default and bounds. Choose a key that fits the generator's Pawn identifier rules.
2. Add cross-field rules to `validation.mjs` when the setting depends on another
   value. Check values in main/shared code, not only an HTML input's `min`/`max`.
3. Generate the complete schema/defaults and Pawn catalogue.
4. Add the actual game consumer using the runtime getter. Decide whether it applies
   immediately, to new jobs/spawns, or by rescheduling a timer; document that policy.
5. Open Server settings. Definitions supplied through `EditorSession.load()` are
   rendered automatically, including group/search and numeric bounds.
6. Test a valid save, boundary failure, cross-field failure, concurrent revision and
   game acknowledgement. Recompile after changing the game consumer/catalogue.

Adding an SQL row or UI control alone does not make a setting hot-reload.

## Change an existing entity column

For example, if your fork renames `faction_armories.armory_desc` to
`locker_description`, search the whole contract first:

```sh
rg -n "armory_desc" database gamemodes web-platform desktop
```

Update the canonical schema and `entities.mjs` field key. The shared entity store
builds SQL identifiers from that trusted metadata, so a field key is also the SQL
column name; renaming only the form label is not a column rename. Update game
load/save queries and staged reload records, any web Prisma mapping/actions, and
relevant tests/types. Regenerate journal triggers and the complete baseline.

For a longer string, align **all** limits: SQL column, shared metadata, Pawn cache
array size, query buffers and UI validation. For a numeric field, align range,
signedness and integer/float handling. Do not silently truncate user input.

The desktop equipment form is metadata driven. Use `text`, `min`, `max`, `integer`,
`allowEmpty` and `default` as the existing families do. Special named pickers are
implemented in `ui/app.js`; update them if a renamed field should still use faction
or weapon choices. Preserve the record's persistent ID and the expected-record
fingerprint when editing existing rows.

## Add a new editable table

Only add an editor if the operation is missing from the game/admin workflow.
Existing in-game placement tools keep ownership; `inGameTools` excludes their
families from desktop/ACP access and history restore.

For a genuinely new family:

1. Add the full table definition to `database/schema.sql`.
2. Register a trusted family in `entities.mjs`: label, table, primary-key column,
   capacity and explicit field definitions. Never accept table/column names supplied
   by the renderer. Declare faction/type/squad references when applicable.
3. Extend `entity-store.mjs` for relationship, occupancy or lifecycle rules that
   cannot be expressed as field bounds. Preserve atomic auditing, change events
   and rollback. Decide whether records support create/delete or edit-only.
4. Implement a corresponding native runtime loader/staging/apply adapter. Preserve
   occupants, inventories and active jobs where those are unrelated to the change.
5. Regenerate triggers/defaults and update the game's trigger/revision handling.
6. Verify `acp-entities.mjs` exposes only the intended ownership. Desktop tabs are
   driven by these definitions, but add readable card titles/help and any special
   form controls in `ui/app.js`.
7. Add tests for relationships, failure rollback, stale records and restore; run
   actual game acknowledgement checks before advertising live application.

An arbitrary SQL table without an adapter is not safe to expose as a live editor.

## Change the configuration snapshot shape

`store.mjs` maps SQL rows into stable renderer/game concepts such as `world`,
`enabled`, `settings`, `models` and `squads`. Update its read and save paths
together. Preserve numeric conversion, null semantics and the distinction between
an enabled point at `0,0,0` and a disabled point. Update shared types/declarations,
validation, frontend consumers and game staging in the same change.

The current contract checks `runtime_config_state.schema_version` against version 4. That value is a **compatibility contract**, not a cosmetic release number. If a
new incompatible shape requires a version bump, update schema initialization,
shared checks and game checks together. Do not bypass a version rejection or bump
only the database row to make incompatible code connect.

History stores before/after snapshots. If you change their shape, define how old
entries are interpreted or marked unsupported. A normal restore is a validated new
revision. A bulk SQL import cannot be undone by restoring only a subset of runtime
entities; `desktop/src/history.mjs` labels that case Backup required.

## Catalogues and IDs

- `vehicle-catalog.json` supplies dealership categories and baseline prices;
  runtime SQL overrides editable price/cargo/enabled values. A model outside the
  dealership catalogue appears in Other stock.
- `vehicle-names.json` indexes stock vehicle names by `modelId - 400`.
- `weapon-names.json` indexes the **custom** `Weapon[]` table in
  `gamemodes/weapons/data/header.pwn`. These are not GTA native weapon IDs:
  Shotgun is custom ID 20 and Police Glock is custom ID 28 in this baseline.
- When adding custom gun entries, update the Pawn table, labels and shared/native
  ID limits together. The desktop catalogue parity test detects mismatched names;
  do not insert a row in the middle of persistent weapon IDs.
- Faction names come from SQL; do not hardcode a name for a numeric faction ID in
  the UI. Squad IDs remain persistent and shared across factions.

## Authentication table changes

Account ID/name/password/staff level, password-reset version, MFA state and bans
are read through explicit queries in `desktop/src/session.mjs`. The shared store
also verifies current Manager rank **inside a write transaction**. A rename must
update both checks; changing the desktop read query alone is insufficient.

Update `scripts/create-admin.mjs` for renamed required fields and keep its first-
administrator lock/refusal to overwrite existing staff. If replacing bcrypt,
coordinate the verifier and bootstrap hash implementation with the web and game.
Saved Manager passwords are only credentials supplied to this authentication
flow, not authorization to skip it.

## Validation before sharing your fork

From `desktop/`, run `npm run format`, `npm run check`, `npm test` and
`npm run build`. From the root, check the generator and shared tests:

```sh
node tools/runtime-config/generate.mjs --check
node --test web-platform/shared/runtime-config/*.test.mjs
```

For database contract changes, follow `tools/runtime-config/README.md` and run its
fresh-schema integration tests against an empty disposable `orp_test_*` database.
If you changed web ORM fields, run the web schema-coverage check and build too.
Compile the gamemode when Pawn consumers changed. Then verify the relevant desktop
forms, permissions, revision conflict, rollback, history policy and actual game
acknowledgement. Update operator/developer documentation with the same commit.

Keep example data, real accounts, credentials, SQL backups and local encrypted
profiles out of the source export. The shipped schema remains the full blank
baseline regardless of which populated database you used during development.
