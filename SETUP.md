# Installing OpenRP Framework

Full searchable documentation: [OpenRP Framework documentation](https://openrp.draignet.uk/docs/).

The framework starts with empty player, vehicle, property and gang-zone data.
SAPD and FDSA are the starter factions. Coordinates marked
`TODO: set coordinates for your map` need configuring before play.

## Common preparation

Discord is disabled by default. The default sampctl manifest does not install or
load its connector. To enable game-side Discord later, add
`maddinat0r/samp-discord-connector:v0.3.5` to `pawn.json` dependencies, install the
matching runtime plugin, configure your own bot token and channel/role values,
and enable `DISCORD_ENABLED` in your local secrets before recompiling. Keep those
credentials out of version control.

Use open.mp, Pawn compiler 3.10.10, sampctl, Node.js 22.12 or newer, and MariaDB
10.5 or newer. Clean imports are tested on MariaDB 10.5. Install matching runtime
and plugin builds: Windows DLLs do not run on Linux. See the official
[open.mp installation guide](https://open.mp/docs/server/Installation).
SA-MP compatibility is not certified.

1. Install sampctl separately. Run `sampctl ensure` and `sampctl build` using the
   dependency/compiler settings in `pawn.json`. The Windows compiler also exists
   in `pawno/`; manual builds must use the dependency include versions.
2. Import `database/schema.sql` with a MariaDB client. It creates `omprp`:
   `mariadb -u root -p < database/schema.sql` in a shell supporting redirection.
   On Windows, open the client and run `source F:/path/to/project/database/schema.sql`.
3. Generate the stock collision database with the [ColAndreas Wizard](https://github.com/Pottus/ColAndreas) using your own GTA: San Andreas installation. Put the resulting file at `scriptfiles/colandreas/ColAndreas.cadb`. It is an external runtime prerequisite; the game stops with a clear error if it is absent.
4. Create a database user with access to `omprp`. Copy `mysql.example.ini` to `mysql.ini` and `config.example.json` to `config.json`, then configure your connection.
   Copy `gamemodes/config/secrets.example.pwn` to the ignored `secrets.pwn`, replace
   placeholders and set branding in `gamemodes/config/header.pwn`.
5. Copy `web-platform/web/.env.example` to `.env.local`. Set `DATABASE_URL` to the
   same database and generate a random `AUTH_SECRET`, for example:
   `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`.
   Set `AUTH_URL` to the actual website origin. Configure SMTP for email verification,
   password recovery and email 2FA. No external credentials are supplied.
6. In `web-platform/web`, run `npm ci`, `npm run db:generate`, then
   `npm run admin:create -- --name Admin_User --email owner@example.com`.
   Save the generated password. The bootstrap assigns Developer level 8, refuses
   to run while any administrator exists, and creates no character. Create your
   character through the UCP. Later staff are managed through the ACP.
7. Set community details in `web-platform/web/lib/site-config.ts`. Publish your own
   rules and policies before accepting public registrations.

## Runtime configuration setup

Import `database/schema.sql` into a new empty database using an account with
ALTER, TRIGGER, CREATE ROUTINE and ALTER ROUTINE privileges. The full schema includes current runtime defaults
and journal triggers; do not apply separate numbered SQL files afterward.
Keep the trigger definer account available and deploy matching gamemode and web code.
After initial startup, supported configuration edits apply live.

Use ACP → Configuration with Manager level 7 or higher to place and enable core
services. A saved revision is not ready until the game reports Applied. Startup
acknowledgement also waits for connected entity validation. Configure a public spawn,
hospital, jail/cells and release destination before gameplay. See the searchable
[configuration guide](https://openrp.draignet.uk/docs/configuration/live-configuration)
and [current implementation coverage](RUNTIME-CONFIGURATION-PROGRESS.md).

## Windows without Docker

Use the Windows open.mp runtime and the matching components/plugins listed in
`config.json`. Run `omp-server.exe` from the project root after configuring MySQL.
Do not run a second copy over the same files and port.

For local web development run `npm run dev` inside `web-platform/web` and open
`http://localhost:3000`. For a built deployment run `npm run build`,
then `npm start`. Supervise the web process for unattended operation.

For ACP process control, copy the agent's `.env.example` to `.env`. Set `SAMP_DIR`
to the absolute game directory and `SAMP_BIN=./omp-server.exe`. Set a random
`SAMP_AGENT_KEY`; use the same key and agent URL in the web environment. In
`web-platform/samp-agent`, run `npm install`, `npm run check`, `npm test`, then
`npm start`. `node-pty` is native and may require the build tools appropriate to
your Node version. Stop a manually started game before using Start in ACP: the
agent must own the process it controls.

## Linux without Docker

Use Linux open.mp and matching `.so` plugin builds. Follow the official
[Linux installation guide](https://open.mp/docs/server/LinuxServerInstallation)
for 32-bit runtime libraries and a dedicated service account. Check each plugin
with `ldd`. Give the service account write access to runtime data and logs.

Run `./omp-server` from the game root for a foreground startup check. For ACP
control, let the agent spawn it instead. Set `SAMP_DIR` to the absolute game
directory and `SAMP_BIN=./omp-server`. Adapt `samp-agent.service` and enable it
with systemd. Do not also start a second game process in another service.
Supervise the built web application independently.

## Linux with EasyPanel — recommended

Use separate services for MariaDB, the website and a **game + agent** container.
Keep the game and its agent in the same container/process namespace: mounting
files into a separate agent container does not give it process ownership.

Build the web service with `web-platform/web/Dockerfile` (Dockerfile path `web/Dockerfile` within the context), using
`web-platform` as its build context. Supply environment variables through
EasyPanel and use the private database hostname in `DATABASE_URL`. Import the
schema and bootstrap the administrator before opening the website. Keep real
credentials out of Dockerfiles and image layers.

Build the game/agent image with Linux open.mp, Linux plugins, Node.js and the
required 32-bit libraries. The agent supervises the game process. Use
`AGENT_BIND=0.0.0.0` only on the private container network, and point the web's
`SAMP_AGENT_URL` at that service's internal name. Do not publish port 7001
publicly. Persist database and game runtime data. Use one game/agent replica.

Use **Domains** for web HTTP/HTTPS to port 3000. Use direct **Ports** for game
UDP 7777 and the configured artwork HTTP port when downloads are enabled;
these use separate protocols. See current
[EasyPanel App documentation](https://easypanel.io/docs/services/app) for domains,
TCP/UDP publishing and persistent mounts. Linux container deployment has not
been executed from this Windows checkout; test the target image before release.

## Docker without EasyPanel

Use the same private networking and process ownership arrangement. Publish
only intended player/web ports and persist runtime data. A web Dockerfile is
included; a prevalidated game/agent image or all-in-one Compose stack is not.

## Server control and optional systems

The ACP calls server-side `/api/samp/*` proxies. Agent keys never belong in
browser code. Start requires Lead, Stop requires Manager, and console commands
and streaming require Developer. Set a non-placeholder RCON password and enable
RCON only when needed; match it in `SAMP_RCON_PASSWORD`. The agent reads `log.txt`;
ACP player/admin audit screens read database log tables.

Discord, voice and custom skins are disabled by default. In-game Discord verification is also off; enable FEATURE_REQUIRE_DISCORD_VERIFIED only after configuring account linking. Email 2FA requires
working SMTP and a verified email. Its codes expire after five minutes, allow
five attempts, are single-use and have a one-minute resend cooldown. Password
changes revoke web sessions. Accounts requiring a password reset cannot log in
until recovery completes; the bootstrap creates a fresh account with a random
password and does not require recovery before its first login.

For optional custom skins, enable `CUSTOM_SKINS_ENABLED=true` on web and
`FEATURE_CUSTOM_SKINS=1` in Pawn. No models are seeded. The ACP uploads DFF/TXD
pairs through the agent. Fully restart the game after uploads, deletions or model
changes. Faction models use 20000–24999; personal model IDs are 25000 plus record
ID (1–4999). Each family loads at most 500 models. Use `/customskin [record id]`
for a personal skin; faction uniforms use the existing faction skin/locker system.
The in-game command is compiled only when the feature is enabled.

Fuel-pump, vending-machine and basketball stock replacements are intentionally
retained. Graffiti removal is opt-in. YSI uses `scriptfiles/callbackfix.amx`.
`geoip.db` is retained for optional offline lookups; VPN exceptions use the
`vpn_whitelist` database table, not an INI file.

## Verification

The complete fresh-install schema includes the required web tables and columns.
Generate Prisma after importing it. Do not run `prisma db push`: the web ORM
models only a subset of the full game schema.

Run `npm run db:check`, `npm test`, and a production build in web; run the agent's
checks/tests. Compile stock and enabled optional Pawn features. Verify registration,
SMTP, 2FA, bans, character creation, faction permissions, crate slots and process
control in a private game session. Full GTA-client gameplay testing remains required.

Exclude real credentials, `.env*`, `secrets.pwn`, configured `mysql.ini`, dumps,
`.local-preview/`, logs and uploads from release archives. Build from intended
source/runtime files rather than zipping the working directory.
