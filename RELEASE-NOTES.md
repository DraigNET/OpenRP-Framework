# OpenRP Framework v0.1.0

Initial public release for open.mp. Adopt the framework as a whole and extend its
systems; modules share database structures, account state and callbacks and are
not standalone drop-in libraries for unrelated gamemodes.

## Included

- Pawn gamemode source and sampctl dependency manifest.
- Complete blank `database/schema.sql` with starter configuration, SAPD and FDSA.
- UCP, ACP, optional API and server-agent source and environment examples.
- Desktop editor source, tests and build/database development guides.
- Separate portable Windows x64 editor download, including offline guides.
- Separately packaged framework website and searchable documentation source.

Start with `SETUP.md`. Configure your own database credentials, account email
delivery and public spawn before inviting players. The release contains no test
administrator or active public spawn. Do not import local preview backups.

The compiled AMX is provided separately for convenience. Install the matching
open.mp runtime/plugins and generate the required ColAndreas data as documented;
the source archive does not bundle local runtime binaries or generated game data.
Build your own AMX after changing compile-time settings or secrets.

## Initial-release limits

The Windows editor is unsigned and portable: extract its entire folder. Linux
desktop support, an installer and automatic updates are not included. Linux,
Docker/EasyPanel deployments and full multiplayer gameplay have not been verified
end to end here. Startup can report slow callbacks in the debug gamemode.

Report bugs with reproduction steps, component/version and redacted logs. Never
include passwords, tokens, private configuration or player database dumps.
