# OpenRP Framework Editor

Windows-first desktop configuration and local server controls. It connects directly
to MariaDB, so the website, ACP, API and samp-agent do not need to be running.

## Run from source

The source, comments, tests and lockfile are included in this repository. Use a
complete framework checkout and Node.js 22.12 or newer. From `desktop/` run:

```sh
npm ci --include=dev
npm start
```

If your npm policy disables install scripts, run `npm run setup` after installing.
Windows node-pty ships
native prebuilds; its console must be able to load for local controls to work.

Enter the database host/port/name/user/password and a Manager game account
(level 7 or 8). Sessions expire after 30 minutes. Password reset, staff demotion,
active bans and changes to 2FA are rechecked on every privileged operation.
Connection setup uses Database, Manager login and optional Email / 2FA tabs. The
default form fits the supported window sizes without a long page scroll. Tabs
preserve entered values and support arrow keys; validation reveals the tab with
the first missing or invalid field.
Connections are memory-only by default. Select **Remember connection and passwords** to
save a named profile after successful Manager authentication (and email 2FA when
enabled). The last successful saved connection is selected automatically after
reopening. Database, Manager and SMTP passwords are encrypted using Windows-backed
Electron safeStorage and reused in the main process; plaintext saved passwords are
not returned to the renderer. Session tokens and email codes are never saved.
Saved credentials still go through current password/rank/ban and 2FA checks. Older
profiles need the Manager password once to add it to their encrypted payload. Use
**Forget** to delete a profile. Profiles live in the application's Windows app-data
directory as `connections.json`, not in the framework or game database, and are
tied to your Windows account. If encryption is unavailable, saving fails without
a plaintext fallback. Editing a saved database host/user requires its password
again so stored credentials are not sent to a different destination.

For a new installation, import **only `database/schema.sql`** into a new empty
database. It includes all current tables, defaults, triggers and firm routines.
Do not import individual migrations afterward. This application never imports
SQL over an existing installation or creates a database implicitly.

If no staff account exists, set `DATABASE_URL` in the process environment and run:

```sh
npm run admin:create -- --name Admin_User --email owner@example.com
```

This owner-run command refuses to replace existing staff and prints a randomly
generated password once. It checks the matching configuration baseline first.
Do not commit database URLs. The SQL account needs the configuration DML and
account/ban reads documented in the database installation guide. Use a dedicated
SQL account; database credentials are themselves privileged independently of
the app's Manager check. Verified TLS can be selected in the connection form.

## Available tools

Settings and locations use category filters and labelled cards. Vehicles have
name/ID search and cargo/priced/disabled filters. Squads are grouped by faction,
equipment uses category tabs, and audit history uses a revision timeline.

- Searchable settings with bounds and change-application hints.
- Service locations, coordinates/interiors/worlds, GPS, spawns, routes and
  polygon vertices. Core locations can be disabled, not removed.
- Stock vehicle catalogue names (searchable by name or ID), dealership category
  groups/filters (Budget, Muscle, Sports, Utility, Bikes, Aircraft, Boats and Ships),
  pricing and real cargo slot capacities. Non-dealership models appear in Other stock.
- Faction-grouped squad cards with readable capability labels; faction names and
  IDs appear in pickers and equipment details, using current database names.
- Armory types, lockers, weapons and stock uniforms with separate category tabs.
  Weapon cards/pickers use custom gun catalogue names with IDs in brackets, e.g.
  Police Glock (28), rather than GTA native weapon IDs.
- Before/after review, revision conflicts, Manager-attributed audit history and
  validated restore as a new revision.
  Bulk-import history entries are labelled Backup required; in-game-owned changes
  explain their editor boundary instead of offering an unavailable restore action.
- Game heartbeat, saved/applied revisions and game-side validation errors.
- Local open.mp folder selection, start, graceful stop, explicit force stop and
  bounded console output. The app controls only the process it launches.

Existing in-game editors keep ownership of gates, properties, vehicle parking,
dealership placement, ATMs and repair points. Crafted desktop requests and
history restores cannot bypass that boundary.

Accounts using email 2FA require your own SMTP settings in the Email / 2FA tab.
Challenges expire after five minutes, allow five guesses and can be used
once. They are separate from UCP challenges; no web authentication secret is
required. Remote SMTP requires TLS; loopback SMTP may be used for local tests.

## Local server behaviour

Select a complete Windows open.mp installation with `omp-server.exe` and
`config.json`. Configure its `mysql.ini` separately to point at the same database;
selecting an editor database does not rewrite server credentials. Compile the
matching gamemode first and supply required components and ColAndreas data.

Controls support IPv4 `network.bind`, check the configured UDP port and use a
Windows pseudo-terminal so `exit` reaches the real game console. A successful
process launch is not proof of successful game startup: check console errors and
the configuration heartbeat. Do not run another supervisor for the same server.

Normal stop waits up to ten seconds. Force stop is a distinct confirmed action
that can lose pending game state. Closing a running workspace offers graceful
stop and keeps the editor open if the server cannot be stopped. Logging out does
not kill the server; sign in again to manage it, or close to request a stop.
Unexpected editor/OS termination and recovery of orphaned processes are not
covered by this first version. Never use force stop as routine shutdown.

## Portable Windows build

From `desktop/`, after `npm ci --include=dev`:

```sh
npm run build
```

This prepares Electron, checks source/formatting, runs tests and packages Windows
x64. Close the running portable app before rebuilding it. Use `npm run package:win`
only when you have already completed the checks.

Distribute the entire generated `desktop/dist/OpenRP Framework Editor-win32-x64/`
folder, not its executable alone. The package stages only the editor, dependencies,
canonical shared configuration source, licence and credits. No server runtime,
database, private credentials or `.local-preview` data is bundled. This build is
unsigned; release signing and installer/update distribution are separate work.

Run `npm test` for authorization/2FA/ownership regression tests. The native game,
database and packaged application also require local integration checks; unit
tests alone are not release certification.

## Developer documentation

- [Build, architecture and maintenance](docs/DEVELOPMENT.md): complete source build,
  file map, process/IPC boundaries, development commands and release checks.
- [Database and editor changes](docs/DATABASE-CHANGES.md): new settings/columns,
  entity editors, schema compatibility, catalogue IDs and authentication changes.

Functions and important workflow boundaries are commented in the source. Run
`npm run format` after editing and `npm run check` before committing. Generated
`dist/`, `.build/`, dependencies and local logs are ignored; the repository carries
the editable source rather than a machine-specific installed app. The Windows CI
workflow builds the portable folder from source and uploads a workflow artifact.
