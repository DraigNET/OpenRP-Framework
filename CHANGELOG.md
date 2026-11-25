# Changelog

## Unreleased

- Removed the Discord connector from default sampctl dependencies and token
  options. Discord code remains available for explicit opt-in installation.

- Removed unused external voice integration, SDK, configuration and web-only voice
  tables from the clean schema. Core game, UCP, ACP and editor are unaffected.

## [0.1.0] - 2026-11-24

Initial framework cut, derived from a live roleplay server's gamemode.

### Removed
- All custom models, maps, interiors and custom skins.
- All factions except SAPD and FDSA.
- Server-specific secrets, Discord IDs, URLs and branding.

### Added
- `database/schema.sql` (structure + minimal seed data).
- Config-driven Discord integration (disabled by default).
- UCP, ACP, optional API and server-agent source with environment examples.
- Live database-backed configuration and an unsigned Windows desktop editor.
- Searchable documentation and editor development/database guides.
