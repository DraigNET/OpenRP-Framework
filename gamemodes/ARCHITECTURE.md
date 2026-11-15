# Gamemode architecture

A guide to how `gamemodes/` fits together, for people new to the codebase. Every `.pwn` file starts with a header
comment saying what it does, so you can also just open any file and read the top.

## 1. How it starts

`gamemode.pwn` is the only file the compiler is pointed at (see `pawn.json`). Everything else is pulled in with
`#include`, **in a deliberate order** (later files may use things defined by earlier ones):

1. Compiler settings and the core constants (faction types, faction ids, capability flags, squad ids).
2. `config/` (libraries, helpers, HUD, clock/weather) and `config/secrets.pwn` (your local secrets).
3. One `header.pwn` per module (`player/`, `admin/`, `vehicle/`, `faction/`, `police/`, `property/`, `jobs/`...).
4. `config/server-native.pwn` and `player/player_hooked.pwn` last, because they wrap functions from everything above.

Each module folder has a `header.pwn` that `#include`s the folder's other files. **To add a module, create a folder with
a `header.pwn` and include it from `gamemode.pwn`.**

### Start-up order
Server start-up happens in `main()` in `gamemode.pwn` (not in `OnGameModeInit`). It connects to MySQL (`MySQL_Init`),
runs the `OnStartSQL`, `OnModelsPreload` and `OnRemoveBuilding` callbacks, loads the settings row, then calls every
system's `*_LoadEntities()` function so it can read its tables (vehicles, factions, firms, gates, drugs, jobs...).
If you add a system that loads from the database, call its loader from `main()`.

Modules can *also* use `hook OnGameModeInit()` (see below) for their own set-up.

## 2. The four ideas you need

### Hooks (`hook`)
The script uses [y_hooks](https://github.com/pawn-lang/YSI-Includes). Many files can react to the same callback:

```pawn
#include <YSI_Coding\y_hooks>

hook OnPlayerConnect(playerid) {
    MyVariable[playerid] = 0;   // runs for every module that hooked OnPlayerConnect
    return 1;
}
```
Never write `public OnPlayerConnect` in a module (a few core files still do); use `hook`.

Custom hooks are used too: `ORP_OnLoadCharacter` (a character was loaded), `ORP_OnCloseConnection` (a player left or
logged out), `ORP_OnPlayerSpawn`, `OnStartSQL`, `OnModelsPreload`, `OnRemoveBuilding`.

### Commands (`CMD:`)
Commands use [zcmd](https://github.com/Southclaws/zcmd):

```pawn
CMD:hello(playerid, params[]) {
    return SendServerMessage(playerid, COLOR_BLUE, "Hello", "DEDEDE", "Hi there!");
}
```
A command is `/hello`. Aliases are separate `CMD:` lines that call the first one. `config/native.pwn` runs before every
command and blocks it for players who are not logged in or are incapacitated.

### Player data: `Account`, `Character`, `PlayerVar`
All defined in `player/auth/data.pwn`:

| Array | What it holds | Saved? |
|---|---|---|
| `Account[playerid][E_PLAYER_ACCOUNT_*]` | The login account: name, password hash, staff level, settings | yes (`accounts`) |
| `Character[playerid][E_CHARACTER_*]` | The character being played: cash, faction, skills, licences, hunger... | yes (`characters`) |
| `PlayerVar[playerid][...]` | Temporary per-session state: cooldowns, menus, "am I carrying a crate" | **no** |

To add a **saved** field: add it to `E_PLAYER_CHARACTER_DATA`, add the column to `database/schema.sql`, read it in
`Account_LoadCharacterData` (`player/auth/character.pwn`) and write it with an `UPDATE characters ...` query when it changes.
For a **temporary** field, add it to `PlayerVars` instead and reset it in `player/logout.pwn` (`Logout_ResetVariables`).

Other global tables follow the same pattern: `Vehicle[]` / `VehicleVar[]` (vehicles), `Property[]`, `Faction[]`,
`Firm[]`, `Gate[]`... Each is an array of an `enum`, loaded from its database table at start-up.

### The database
One global MySQL handle named `mysql`. Queries are asynchronous:

```pawn
mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_cash = %d WHERE player_id = %d", cash, id);
mysql_tquery(mysql, query);
```
`%e` escapes strings. For queries whose result you need, the script uses `MySQL_TQueryInline(mysql, using inline Name, query)`
with a `inline Name()` block that reads the result with `cache_get_value_name_*`. The structure is in `database/schema.sql`.

## 3. Conventions

- **`ORP_` prefix**: functions that wrap a SA-MP native with extra tracking, for example
  `ORP_SetPlayerPos`, `ORP_SetVehicleHealth`, `ORP_SetVehicleToRespawn`. Always use the wrapper, not the raw native, so
  anti-cheat and cleanup keep working.
- **Messages:** `SendServerMessage(playerid, COLOR_x, "Prefix", "hexcolour", "text")` for system messages,
  `SendClientMessage` for plain lines, `ShowPlayerFooter` / `ShowPlayerInfoMessage` for HUD hints.
- **Money:** `GivePlayerCash` / `TakePlayerCash` (never `GivePlayerMoney`). The reason string is logged.
- **Logging:** `AddLogEntry(playerid, LOG_TYPE_x, "what happened")` writes to the player log staff can search.
- **Permissions:** `GetPlayerAdminLevel(playerid) >= ADMIN_LVL_x`. For factions use `Faction_Can(playerid, FAC_CAP_x)` and
  the `IsPlayerIn...Faction()` helpers instead of comparing faction ids.
- **Entity ids:** most things have two ids. The *SQL id* lives in the database; the *enum id* is the index in the Pawn array.
  Functions named `..._GetEnumID` convert. Mixing them up is the most common bug.
- **Feature flags** in `config/header.pwn` (`FEATURE_EMMET`, `FEATURE_FNR`, `FEATURE_GANGZONES`, `FEATURE_GANGTAGS`)
  compile optional systems in or out.
- **TODOs for you:** search for `TODO: set coordinates for your map`. Those places are set to 0,0,0 until you place them.

## 4. Folder map

| Folder | What lives there |
|---|---|
| `config/` | Libraries, constants, helpers, HUD, clock/weather, `secrets.pwn` |
| `player/` | Login, characters, spawning, settings, help, logout, the central data arrays |
| `admin/` `adminobjects/` `helpers/` `anticheat/` | Staff tools, reports/questions, bans, admin objects, anti-cheat |
| `faction/` `police/` `skins/` `licenses/` | Factions, armories, uniforms, arrests, MDC, radio, licences and badges |
| `vehicle/` `carjack/` `modshops/` `paynspray/` `chopshop/` | Vehicles, fuel, dealerships, theft, tuning, repair |
| `property/` `furniture/` `gates/` `passpoints/` `visuals/` | Houses and businesses, furniture, gates, doors/teleports, maps and models |
| `jobs/` `firm/` `money/` | Jobs, player-run firms, paychecks and banking |
| `injury/` `weapons/` `hunger/` `gym/` `drugs/` | Damage and death, guns, food, fitness, drugs |
| `phone/` `message/` `news/` `boombox/` `discord/` | Phone, chat, news, music, Discord |
| `minigame/` `minigame_battle/` `anims/` `misc/` | Pool, basketball, battles, animations, holdables, missions |
| `attachments/` `browser/` `tags/` `gps/` `web/` `donator/` | Toys and stores, model browser, names and masks, GPS, website commands, premium |
| `gangzones/` `emmet/` `hitman/` | Optional/disabled systems |

## 5. Recipes

**Add a command:** put a `CMD:` in the module's file (or a new file included from its `header.pwn`) and list it in
`player/help.pwn`.

**Add a faction:** insert a row in `factions` (or use `/factioncreate`), pick a type (`FACTION_TYPE_*`) and set its
capability bitmask (`FAC_CAP_*`). Add radio channels in `police/systems/radio.pwn` if it needs them. See the comment in
`gamemode.pwn`.

**Add a job:** copy `jobs/pizza/header.pwn` or `jobs/trucker/header.pwn`, include it from `jobs/header.pwn` and call its
loader from `Jobs_Init`.

**Add a map:** copy `visuals/maps/template.pwn`, put your objects in it and include it from `visuals/maps/header.pwn`.
Then set the `TODO` coordinates.

**Add a custom model:** register it in `visuals/models.pwn` with `AddSimpleModel` and add the files to your server's
artwork folder.

### Integrated admin flight and client checks

`admin/fly.pwn` provides `/afly` and `/surfly` for on-duty administrators (or RCON admins).
`anticheat/modules/client_checks.pwn` handles client checks in the gamemode and calls the central
anti-cheat handler directly. The memory checks only run for recognised client versions.
Both modules use YSI hooks; no external filterscripts are required.
