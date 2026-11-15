# OpenRP Framework

Full searchable documentation: [OpenRP Framework documentation](https://openrp.draignet.uk/docs/).

**OpenRP Framework** (ORP Framework for short) is an empty, ready-to-extend **roleplay gamemode** for **open.mp**, written in Pawn. It may run on SA-MP with some changes, but that is untested.

It contains the systems every serious RP server ends up needing -- accounts and characters, a full admin suite,
vehicles, properties, businesses, jobs, injuries, phone, police and fire factions -- but **none of the content**
of any particular server: no custom models, no maps, no interiors and no custom skins.
You bring your own map, models and lore.

> **Status:** blank framework with optional integrations. See [SETUP.md](SETUP.md) for installation and the remaining runtime validation requirements.

New to the code? Read [gamemodes/ARCHITECTURE.md](gamemodes/ARCHITECTURE.md) first.

UCP, ACP, optional API and server-agent source: [web-platform/README.md](web-platform/README.md).

## What you get

- Account / character system with bcrypt passwords, MySQL persistence and a UCP-friendly schema
- Admin system (levels, duty, reports, jail, bans, spectate, noclip, logging)
- Vehicles (ownership, dealerships, fuel, impound, mods, tickets), properties, businesses/firms, furniture
- Jobs (a simple trucker delivery run, garbage, pizza, fishing, ...), economy and paychecks
- Injury / medical system, phone, radio, MDC, 911, arrests and cuffs
- Optional systems behind feature flags (`gamemodes/config/header.pwn`): gangs, gang zones, Emmet gun dealers, fear & respect

## What is deliberately *not* included

| Removed | Notes |
|---|---|
| Custom models / maps / interiors | Only stock GTA:SA models remain. Add your own in `gamemodes/visuals/` |
| Custom skins & faction skin models | Stock skins 0-311 by default; optional upload/model support is disabled (`gamemodes/skins/`) |

## Default factions

Created by `database/schema.sql`:

| id | Name | Type |
|---|---|---|
| 1 | San Andreas Police Department (`SAPD`) | law enforcement |
| 2 | Fire Department of San Andreas (`FDSA`) | EMS / fire |

The ids are referenced by `FACTION_ID_SAPD` / `FACTION_ID_FDSA` in `gamemodes/gamemode.pwn`. More factions are just
rows in the `factions` table (use the in-game `/f(action)create` admin commands).

## Requirements

- open.mp server (SA-MP 0.3.7 may work but is untested and will likely need changes) -- <https://www.open.mp>
- MariaDB 10.5+ (clean imports tested on MariaDB 10.5)
- [sampctl](https://github.com/Southclaws/sampctl) for dependencies and builds; install it separately on Windows or Linux
- Pawn compiler 3.10.10

## Setup

Follow [SETUP.md](SETUP.md). Linux with EasyPanel is recommended; Windows and Linux
standalone deployments are supported by the source. The schema ships no accounts:
bootstrap your own Developer-level administrator with a unique generated password.
Custom skins, voice and Discord are opt-in and disabled by default.

## Adding your own content

| I want to... | Look at |
|---|---|
| Add a map | `gamemodes/visuals/maps/template.pwn`, then include it from `visuals/maps/header.pwn` |
| Remove default buildings | `gamemodes/visuals/remove.pwn` |
| Add custom models | `gamemodes/visuals/models.pwn` (and `config/modelconstants.pwn` for base ids) |
| Add attachment items | `gamemodes/attachments/store/*.pwn` |
| Add a faction | `factions` table, `FACTION_TYPE_*` in `gamemode.pwn`, `police/systems/radio.pwn` for radio channels, `faction/squads.pwn` for squads |
| Turn on Discord logging | `gamemodes/config/secrets.example.pwn` |

## Known gaps

- **UI sprite sheets** for the phone, licence cards and gym HUD ship in `models/` and are registered in `gamemodes/visuals/models.pwn`. Players download them automatically (see `artwork` in `config.json`). Replace the `.txd` files to restyle those screens.
- **Map-specific coordinates** are set to 0,0,0 with a `TODO: set coordinates for your map` comment (search the code for it): DMV, admin jail, jail cells and release point, help desks, mugshot rooms, scrapyards, chop shop, advert agency, trucker depot, default spawn, GPS entries, faction spawns.
- The burglary job still loads its house layouts from `scriptfiles/burglary/*.map` (stock objects).
- Static data in `jobs/`, `hunger/vending`, `gym/` etc. uses stock-map coordinates from the original server.

## Credits

OpenRP Framework is based on the SP-RP gamemode. See [CREDITS.md](CREDITS.md) for everyone who contributed,
including the licence notice that must stay with the original code. Individual files carry their original
authors' headers -- please keep them.
Third-party libraries (YSI, streamer, sscanf, ...) are pulled in via `pawn.json` under their own licences.
See [LICENSE](LICENSE) for the retained BSD 3-Clause notice.
