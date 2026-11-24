# Changelog

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
