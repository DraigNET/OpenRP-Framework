# Runtime configuration tools

Run commands from the framework root. Install web dependencies first with `npm ci`
in `web-platform/web`; the database checks use its MariaDB driver and admin bootstrap.

- `node tools/runtime-config/generate.mjs` regenerates Pawn catalogues, defaults,
  entity journal triggers and the runtime section of the blank schema. Recompile
  after changing definitions or game consumers.
- `node --test web-platform/shared/runtime-config/validation.test.mjs web-platform/shared/runtime-config/entity-store.test.mjs`
  checks bounds, relationships expressible without SQL and malformed input.
- `node tools/runtime-config/integration-test.mjs` runs transactional database checks.

For integration tests, create a **new empty database** named `orp_test_<suffix>`
and set `ORP_TEST_DATABASE_URL` to its MariaDB URL (`mysql://user:password@host:3306/orp_test_example`).
Use a dedicated test account with schema creation, DML, ALTER, TRIGGER, CREATE ROUTINE, ALTER ROUTINE and EXECUTE permissions on
that database. Supply the URL through your shell/environment manager; do not commit
credentials. The runner rejects other names and any nonempty database before
importing the schema. It does not create/drop databases or clean up test rows.
Afterward, remove the disposable database yourself. Never use a production database.

The test runner imports the blank schema, creates an administrator with a generated
password that is not printed, checks current-account permissions, stale writes,
rollback, occupied sentences, audit/restore, entity restrictions and the database
change journal. It leaves fixtures for inspection. A second run against that same
nonempty database is intentionally refused.

These checks do not launch the game or prove client rendering. Compile both stock
and optional-custom-skin variants, then verify server acknowledgement and client
behaviour on a separate staging server. Preserve active jobs, issued equipment,
owned vehicles and player state when adding an adapter.

Run `node tools/runtime-config/generate.mjs --check` before release to verify the
complete baseline and generated Pawn/default files without modifying them. A stale
file fails the check; regenerate and commit the full `database/schema.sql` together.

`database/schema.sql` is the single canonical SQL baseline, including handwritten
runtime DDL and firm routines. The generator reads those sections from the same
file and refreshes catalogue defaults and journal triggers in place. It neither
requires nor emits separate migration files. New users import this file only.
Whenever configuration definitions change, regenerate that schema and update
the corresponding Website documentation in the same change.

The integration runner also checks the firm lifecycle routines: licences, atomic
registration/fees/owner membership, active identity uniqueness, concurrent final-slot
invitations, closure requirements, re-registration and injected membership failures.
Firm routines live directly in `database/schema.sql`. Runtime users need EXECUTE.
