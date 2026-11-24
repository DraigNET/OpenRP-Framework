> Scope correction — 18 November 2026: existing in-game editors are sufficient. Do not duplicate gates, fuel, faction spawns, furniture, actors, objects, passpoints, attachment stores or audio tools in ACP. The inventory below is the historical audit; editor ownership in the live-configuration guide supersedes its earlier ACP proposals.

> Desktop update — 19 November 2026: the first Windows editor now uses the shared
> configuration repository with database + Manager authentication, email 2FA and
> owned local server controls. See `desktop/README.md`. Technology/scope proposals
> below are retained as the historical audit, not current implementation status.

> This document records the migration audit and intended scope. Implementation is underway; see `RUNTIME-CONFIGURATION-PROGRESS.md` and the website live-configuration guide for what is currently connected and tested.

# Runtime configuration audit

Audit date: 16 November 2026. This is an implementation inventory and proposed
design, not a claim that the listed settings already hot-reload. No gameplay
configuration or running-server state was changed during this audit. Desktop
application implementation is deferred until its requirements are discussed.

## Findings

The maintained gamemode contains 483 Pawn files excluding the local secrets file,
95 occurrences of the map-coordinate TODO marker, and 1,242 define declarations.
These are search-inventory counts, not counts of independent configurable settings.
The clean schema defines 144 tables; the existence of a table alone does not prove
the corresponding feature is active or editable through ACP.

A substantial part of world content already uses SQL. The main work is to move
remaining source configuration into structured records, expose missing editors,
and add a coordinated game-side change-application mechanism.

## 1. Already database-backed: extend the editor and reload path

| Area | Existing storage/source | Work needed |
| --- | --- | --- |
| Properties and businesses | `enex_master`, `enex_buypoint`; `gamemodes/property/` | ACP editor for placement, entrances/exits, ownership/service settings; update the affected entity safely |
| Vehicles | `vehicles` and related tables; `gamemodes/vehicle/` | ACP configuration for persistent spawn/type/job/faction assignments; preserve occupants and runtime inventories |
| Dealerships and stock | `dealerships`, `dealership_stock`; `vehicle/modules/dealer.pwn` | Editor and targeted reload; reuse existing dealership-to-GPS synchronisation |
| Factions | `factions`, member fields, `faction_spawns`; `gamemodes/faction/` | Broader faction/spawn settings UI; apply updates without replacing online member state |
| Armories and lockers | `faction_armory_types`, `faction_armories`, `faction_armory_weapons` | Coordinate/interior/world editor and automatic reload; current ACP creates unplaced lockers and relies on `/armoryplace` |
| Uniform availability | `faction_skins`; `faction/skins/header.pwn` | Creation/editing and automatic uniform-list reload; audit tier/squad enforcement separately |
| Gates and access | `gates`, `gate_factions`; `gates/data.pwn` | ACP editor, rebuild the changed gate/area and preserve access/movement state |
| Fuel points/businesses | `fuelstation`, `fuelmanager`; `vehicle/fuel/` | ACP placement, pricing and ownership tools; safely refresh pump interactions |
| Repair/refuel points | `rprf_points`; `vehicle/modules/repairrefuel.pwn` | ACP CRUD and targeted recreation |
| ATMs | `atms`; `misc/atms.pwn` | ACP placement/model settings where supported, object/label recreation |
| Attachment stores | `attachpoint`; `attachments/store/data.pwn` | Store position/type/business-link editor and live recreation |
| Furniture and world entities | `furniture`, `actors`, `admin_objects`, `passpoints`, other entity tables | Expose relevant existing fields and implement safe per-entity updates rather than a global reload |
| Permanent audio | `music_sources`; `boombox/musicsource.pwn` | ACP placement/range/source settings and listener-safe updates |
| Server settings | `server`; `config/main.pwn` | Expand the editor for existing MOTD/colour/service settings and apply cached changes |

Some modules already have reload commands, especially armories and faction skins.
They should be adapted to a common change mechanism rather than requiring staff
to remember which command to run after every save. Startup loaders must be
reviewed individually: many cannot simply be called repeatedly without duplicating
objects, clearing state or disrupting players.

## 2. Hardcoded locations and lists suitable for migration

| Area | Current source | Proposed editable data | Application behaviour |
| --- | --- | --- | --- |
| DMV | `gamemode.pwn`, `vehicle/modules/dmv.pwn`, `gps/data.pwn` | Position, angle if needed, interior/world, range, label, enabled flag, fee | Recreate tracked pickup/label, update command checks and GPS together |
| Public/new-character spawns | `player/spawns/header.pwn` | Named spawn list with position, facing, interior/world, order, enabled | New spawn selections use new records; existing players stay where they are |
| Admin jail and staff room | `admin/ajail.pwn` | Origin, interior/world, cell offsets/facing, room configuration | Rebuild tracked stock objects/containment area; explicitly handle current inmates |
| Prison cells and release | `police/detaining/arrest.pwn`, main prison constants | Named cells, prison interior/world and release destination | Preserve sentences/cell identity; plan relocation for occupied cells |
| Agency/administration help desks | `police/detaining/arrest.pwn` | Position, interior/world, label/icon, faction/type association, bell cooldown | Recreate handles and update range checks without losing unrelated state |
| Trucker depot | `jobs/trucker/header.pwn` | Depot position/name, ranges, enabled flag | Rebuild depot interaction and update new-order checks; define active-delivery handling |
| GPS destinations | `gps/data.pwn` | Independent destinations plus references to services/entities | Derive a service's GPS location from its actual record; avoid a second coordinate copy |
| Garbage collection points | `jobs/garbage/data.pwn` | Ordered/enabled pickup points and route areas | Use stable IDs and preserve or safely retire active route targets |
| Fishing areas | `jobs/fishing/data.pwn` | Polygon/zone records with ordered vertices | Replace tracked areas; recompute player area membership |
| Pizza coverage | `jobs/pizza/header.pwn` | Delivery region/bounds and route parameters | Houses already come from properties; do not create another duplicate destination list |
| Pay'n'Spray garages | `paynspray/locations.pwn` | Named garage locations, range, interior/world | Recreate labels/icons and GPS links; do not append duplicates |
| Land/boat/air scrapyards | `vehicle/modules/carscrap.pwn` | Yard type, location, marker and service settings | Refresh interaction checks and tracked indicators |
| Chop-shop service point | Main constants and `chopshop/` | Drop-off position/range and associated settings | Keep in-progress theft/delivery state coherent |
| Advertisement service point | `property/utils/advert.pwn` | Position, interior/world and service restrictions | Update interaction checks and indicators |
| Medical recovery | `injury/injury.pwn` and related modules | Recovery destinations and treatment/service points where currently fixed | Future recoveries use new data; do not unexpectedly teleport recovering players |
| Gyms | `config/data/header.pwn`, `gym/header.pwn`, `gym/gyms.pwn` | Entrances/exits and machine positions/rotations/areas | More involved: fixed machine interaction coordinates must also be migrated; an existing `gym` table is not enough |

The active DMV implementation is a theory quiz, despite comments describing a
practical test. Migration should follow the executable behaviour rather than
assuming a driving route exists. Its pickup and label currently lack retained
handles for repeated destruction/recreation, and `/taketest` checks XYZ without
a matching interior/world check. Both must be addressed for correct relocation.

Dockworker and boatyard includes are commented out in `jobs/header.pwn`. They
should not be presented as active ACP-configurable jobs until deliberately
reactivated and tested.

## 3. Scalar settings and catalogues suitable for migration

### Economy and service charges

Examples found in source:

- DMV/rental fees: `config/header.pwn`.
- Pilot licence fee: `vehicle/modules/pilot.pwn`.
- Impound fee: `vehicle/modules/impounding.pwn`.
- Name-change fee: `admin/namechanges.pwn`.
- Firm creation fee: `firm/header.pwn`.
- Base paycheck, qualifying minutes and interval: `money/paycheck.pwn`.
- Toll fee and cargo-slot charge: `gates/header.pwn`.
- Surgery/bandage charges and medical billing formula bounds: `injury/`.
- Repair/bodywork/engine prices and percentages: `paynspray/`.
- Modshop and wardrobe charges: `modshops/save.pwn`, `property/utils/wardrobe.pwn`.
- Dealership wholesale percentage, used-car price bounds and lawyer minimum rate:
  `vehicle/modules/dealer.pwn`, `firm/jobs/usedcars.pwn`, `firm/jobs/lawyer.pwn`.

Changing a recurring interval must reschedule the relevant timer deliberately.
An already displayed price must be honoured or reconfirmed if it changes before
the player accepts; silently charging a new amount is not acceptable.

### Jobs

Trucking can expose crate pay, distance pay, loading/drop ranges, checkpoint size,
eligible business products and model-specific cargo capacity. Pizza can expose
delivery count, payment bounds, completion bonus and coverage area. Garbage and
fishing can expose their payout and eligibility parameters as well as locations.

Record the applied job settings with each accepted job where needed. Shrinking
capacity must not delete existing loaded crates; new limits can take effect for
new loads/jobs or be blocked until the vehicle is empty. Do not change the value
of an accepted delivery halfway through unloading without an explicit policy.

### Factions, catalogues and presentation

- Move squad definitions into records with stable IDs, faction ownership, display
  names and supported role flags. Both Pawn and web currently define squad lists;
  adding a normal squad should not require changing both sources.
- Move supported vehicle catalogue prices, sale/category flags and configurable
  cargo capacities into a shared source. Web catalogue capacity values already
  differ from the current trucker model table.
- Consider stock item/attachment store catalogues, service labels, supported
  uniform configuration and configurable gameplay eligibility limits.
- Move ordinary branding/message settings, configurable server-browser identity,
  time/weather policy and appropriate gameplay cooldowns into runtime data.
  Replacing string macros requires changing call sites, including adjacent Pawn
  string literals; it is not a safe global search-and-replace.
- Review new-character defaults and configurable account/character limits across
  web and Pawn together. Numeric type IDs and structural limits remain code.

Do not expose arbitrary expressions, SQL, Pawn code, permission code or unknown
capability bitmasks as editable settings. Expose known behaviours with typed
values and explicit ranges.

## 4. Shared reload design

1. Keep existing entity tables. Add a typed configuration catalogue for global
   settings and shared service-location/list records where no table exists.
2. Define types, defaults, limits, descriptions, permissions and application policy
   once in a shared specification. Generate or validate the Pawn definitions from
   it; make ACP and the future desktop editor use the same schema/validation.
3. Save a validated batch and its revision/change record in one database
   transaction. Use optimistic concurrency so two editors cannot silently
   overwrite one another. Keep before/after audit history and an authorised
   restore operation.
4. Have the game check a small revision record at a bounded interval (for example,
   every 1-2 seconds), then fetch only affected data. Keep applied values in memory;
   do not query SQL during every command/distance check/frame.
5. Read/validate a consistent snapshot before applying it. On failure, retain the
   last working configuration and report the failure instead of half-applying a
   batch. Every loader must have explicit create/update/delete/cleanup behaviour.
6. Acknowledge the applied revision from the running game. The editor can show
   Saved, Waiting for server, Applied, Deferred or Failed. A committed SQL write
   alone must not be labelled successfully applied to the live world.
7. When the game is offline, save normally and load the latest valid settings at
   next startup. The future desktop editor therefore does not require a web app,
   agent HTTP endpoint or running game merely to configure the database.

Polling SQL is the common path: it works for local desktop edits and remote ACP
edits without opening RCON or creating a second unauthenticated control channel.
Keep instance identity explicit if multiple game instances share one database.

## 5. The DMV acceptance test

- Edit its coordinates, interior/world, label, range and optional fee in ACP.
- Save once; show the pending revision until the server acknowledges it.
- Confirm the old pickup/label disappears and the new pair exists exactly once.
- Confirm `/taketest` works at the new location in the right interior/world and
  rejects the old location/wrong world.
- Confirm GPS points to the same record, not a separately edited coordinate.
- Preserve an already started quiz and its paid fee; handle an unconfirmed price
  dialog safely.
- Repeat saves/moves, including concurrent edits and invalid input. No duplicate
  entities, leaked handles, server restart or recompilation should occur.
- Stop the game, save another edit, restart and verify persistence.

## 6. Deliberate boundaries

Keep startup secrets and database credentials outside the database they initialise.
Changing listen addresses/ports, native plugins/components, schema/code behaviour
or compile-time memory/array limits is not a live setting change. Existing
`#if defined` features cannot be switched on by writing SQL when their code was
compiled out; they require an initial runtime-feature refactor.

The current custom-model registration path is startup-driven. DFF/TXD changes
should retain a restart requirement unless an independently tested asset lifecycle
is implemented. Stock mapping objects can be made editable with cleanup, but
stock building removals are a separate per-client lifecycle and must not be
advertised as universally reversible without reconnecting.

## Recommended order

1. Shared typed settings, revisions, audit/apply status and the DMV end-to-end.
2. General service locations, GPS, spawns and configurable economy/job values.
3. ACP editors and safe per-entity updates for existing SQL-backed world data.
4. Faction squads, catalogues, routes and more complex spatial/machine systems.
5. Scope the desktop UI with the user, then connect it to the same data/validation
   contract rather than creating a second configuration system.

Desktop technology, screens, authentication, packaging and credential-storage
behaviour remain open requirements; no desktop implementation is included in this
audit.
