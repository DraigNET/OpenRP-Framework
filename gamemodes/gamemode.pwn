// ============================================================================
// File: gamemode.pwn
// MAIN ENTRY POINT of the gamemode. This is the file the compiler is pointed at (see
// pawn.json). It sets compiler options, defines the core constants (faction types, faction ids,
// squads, capability flags, prison world), then #includes every module in a deliberate order,
// and finally implements the core callbacks: OnGameModeInit (starts every system),
// OnGameModeExit (saves and shuts down), OnPlayerConnect and main(). If you add a new module,
// include its header.pwn from here. Read this file first to see how the whole script fits
// together.
// Commands: /clearcd
// ============================================================================

// Default Pawn compiler dynamic pool (heap+stack) is only 16KB (4096 cells), which
// this gamemode's deeply nested y_dialog/y_inline callbacks and large local string
// buffers can exhaust, causing "Stack/heap collision" and cascading AMX corruption.
#pragma dynamic 65500

// legacy/colandreas.inc calls its own deprecated Iter_SafeRemove_1 internally -
// vendored third-party code, not ours to patch. Disabled early so it's active
// before the include is reached (config/header.pwn -> config/includes.pwn).
#pragma warning disable 234

#define SHORT_URL_DONATIONS		"https://example.com/donate"  // TODO: your donation URL
#define SHORT_URL_PAINTJOBS		"https://example.com/paintjobs"  // TODO: your paintjob URL

#define MAX_FACTION_TYPES       10

#define FACTION_TYPE_LEO 	0
#define FACTION_TYPE_ILLEGAL	1
#define FACTION_TYPE_LEGAL		2
#define FACTION_TYPE_EMS		3
#define FACTION_TYPE_NEWS		4
#define FACTION_TYPE_TRUCKER	5
#define FACTION_TYPE_GOV  		6
#define FACTION_TYPE_SECURITY 	7
#define FACTION_TYPE_FEDERAL 	10

// Faction SQL ids, for the rare spot that must target one specific faction
// rather than a whole type (e.g. a faction-specific vehicle livery). These are the ids of
// the core factions as created in the database.
#define FACTION_ID_SAPD 	1
#define FACTION_ID_FDSA 	2

// ---------------------------------------------------------------------------
// Faction capabilities.
//
// What a faction is ALLOWED to do, stored as a bitmask per faction row rather
// than decided by comparing its type against hardcoded lists. A new agency is
// a database row with the right bits set - no code changes, no OR/AND chains.
// Faction_Can(playerid, cap) is the single check that replaces them.
//
// Backfilled from faction_type to reproduce the default behaviour.
// ---------------------------------------------------------------------------
#define FAC_CAP_LAW         (1 << 0)    // cuff, detain, frisk, arrest, prisoners
#define FAC_CAP_FIREARMS    (1 << 1)    // armory / weapon access
#define FAC_CAP_RADIO       (1 << 2)    // faction radio
#define FAC_CAP_SIRENS      (1 << 3)    // vehicle sirens
#define FAC_CAP_CARSIGN     (1 << 4)    // vehicle car signs
#define FAC_CAP_IMPOUND     (1 << 5)    // impound vehicles
#define FAC_CAP_TICKET      (1 << 6)    // issue tickets
#define FAC_CAP_BACKUP      (1 << 7)    // request/appear in backup
#define FAC_CAP_911         (1 << 8)    // receives emergency dispatch
#define FAC_CAP_MEDICAL     (1 << 9)    // revive / heal / medical dispatch
#define FAC_CAP_MECHANIC    (1 << 10)   // faction mechanic discount / gov modshop

#define FACTION_SQUAD_NONE 0

// Squad ids used by the Government faction type's permission checks (judge, administrator,
// investigator). They are only ids: no Government faction or squad is created by default.
#define FACTION_SQUAD_GOV_DAI       1   // investigators
#define FACTION_SQUAD_GOV_ADMIN     3   // administrators
#define FACTION_SQUAD_GOV_COURT     4   // judges


// ---------------------------------------------------------------------------
// Law-enforcement squads. Unique ids per agency so a numeric squad never means
// two different things, and a ROLE bitmask so checks test capability (tactical/
// detective) rather than a hardcoded squad number. Add an agency's squad as a
// data row in squads.pwn with the right role - no check edits anywhere.
// ---------------------------------------------------------------------------
#define SQUAD_ROLE_TACTICAL   (1 << 0)   // SWAT-equivalent: SEB / SWAT / SET
#define SQUAD_ROLE_DETECTIVE  (1 << 1)   // investigators: DB / ISU

// SAPD - San Andreas Police Department
#define SQUAD_SAPD_SWAT       10
#define SQUAD_SAPD_TSD        11   // Traffic Support Division
#define SQUAD_SAPD_DB         12   // Detective Bureau

// FDSA - Fire Department of San Andreas
#define SQUAD_FDSA_FIRE       20   // Fire suppression
#define SQUAD_FDSA_EMS        21   // Paramedics / EMS
#define SQUAD_FDSA_RESCUE     22   // Technical rescue


#define PASSWORD_RESET_REQUIRED_VERSION 1

#define PRISON_VW               644   // placeholder: stock police jail interior, see JailSpawns in police/detaining/arrest.pwn
#define PRISON_INT              6

enum E_PLAYER_NAME_STYLE
{
    PLAYER_NAME_STYLE_ROLEPLAY,   // RP name (so char name replaced with spaces, but uses mask if masked)
    PLAYER_NAME_STYLE_CHARACTER,  // Char name replaced by spaces, ignores mask
    PLAYER_NAME_STYLE_ACCOUNT,    // Account name
    PLAYER_NAME_STYLE_LEGACY,     // Old style such as Account (F. Last)
    PLAYER_NAME_STYLE_DEFAULT     // Wrapper for default GetPlayerName
}

enum E_LOG_TYPES
{
    LOG_TYPE_NONE,
    LOG_TYPE_CHAT,
    LOG_TYPE_ACTION,
    LOG_TYPE_SCRIPT,
    LOG_TYPE_GAME,
    LOG_TYPE_DAMAGE,
    LOG_TYPE_OOC,
    LOG_TYPE_PM,
    LOG_TYPE_PHONE,
    LOG_TYPE_PAGER,
    LOG_TYPE_ADMIN,
    LOG_TYPE_RADIO,
    LOG_TYPE_CMD,
    LOG_TYPE_DRUGS,
    LOG_TYPE_ANTICHEAT,
    LOG_TYPE_GRAFFITI,
    LOG_TYPE_JOB,
    LOG_TYPE_STAFFCHAT,
    LOG_TYPE_ADMIN_NC,
    LOG_TYPE_MONEY_FLOW,
    LOG_TYPE_FACTION_BANK,
    LOG_TYPE_FIRM
}

enum
{
    DEATHTYPE_WEAPON,
    DEATHTYPE_KNIFED,
    DEATHTYPE_CUSTOM
}

enum   // represents constants for /weapons/data/header.pwn
{
    CUSTOM_FIST,
    CUSTOM_BRASSKNUCKLE = 1,
    CUSTOM_GOLFCLUB,
    CUSTOM_NITESTICK,
    CUSTOM_KNIFE,
    CUSTOM_BAT,  // 5
    CUSTOM_SHOVEL,
    CUSTOM_POOLSTICK,
    CUSTOM_KATANA,
    CUSTOM_CHAINSAW,
    CUSTOM_CANE, // 10
    CUSTOM_SPRAYCAN,
    CUSTOM_COLT,
    CUSTOM_COLT_SILENCED,
    CUSTOM_DEAGLE,
    CUSTOM_UZI, // 15
    CUSTOM_TEC,
    CUSTOM_MP5,
    CUSTOM_AK47,
    CUSTOM_M4A1,
    CUSTOM_SHOTGUN, // 20
    CUSTOM_COMBAT_SHOTGUN,
    CUSTOM_SAWNOFF_SHOTGUN,
    CUSTOM_RIFLE,
    CUSTOM_SNIPER_RIFLE,
    CUSTOM_CAMERA, // 25
    CUSTOM_TAZER,
    CUSTOM_FIRE_EXTINGUISHER,
    CUSTOM_POLICE_GLOCK,
    CUSTOM_LICENSED_COLT,
    CUSTOM_LICENSED_DEAGLE, // 30
    CUSTOM_TEARGAS
}


enum   // gym stats
{

    E_GYM_STAT_ENERGY,
    E_GYM_STAT_WEIGHT,
    E_GYM_STAT_MUSCLE,
    E_GYM_STAT_HUNGER,
    E_GYM_STAT_THIRST
} ;

enum   // gps colors
{
    E_GPS_COLOR_DEFAULT = 0x9E1A1AFF, // red
    E_GPS_COLOR_SCRIPT = 0x2D3E77FF, // blue
    E_GPS_COLOR_JOB = 0x318635FF // green
} ;

enum E_SERVER_DATA
{

    // Non saving
    E_SERVER_UPTIME,

    E_SERVER_TIME_HOURS,
    E_SERVER_TIME_MINUTES,

    E_SERVER_TIME_DAYS,
    E_SERVER_TIME_MONTHS,
    E_SERVER_TIME_YEARS,

    E_SERVER_WEATHER_TICK,
    E_SERVER_WEATHER,

    E_SERVER_OOC_ENABLED,
    //E_SERVER_RC_ENABLED, // respected
    E_SERVER_DC_ENABLED, // donator
    E_SERVER_SC_ENABLED, // strawman
    E_SERVER_TOLLS_LOCKED,

    E_SERVER_ADMIN_HEX,
    E_SERVER_HELPER_HEX,

    // motd
    E_SERVER_MOTD_STRING_1 [ 96 ],
    E_SERVER_MOTD_STRING_2 [ 96 ],
    E_SERVER_MOTD_STRING_3 [ 96 ],
    E_SERVER_MOTD_EDITOR   [ 24 ],
    E_SERVER_MOTD_EDIT_TIME,

    E_SERVER_ADMIN_MOTD_STRING_1 [ 96 ],
    E_SERVER_ADMIN_MOTD_STRING_2 [ 96 ],
    E_SERVER_ADMIN_MOTD_STRING_3 [ 96 ],
    E_SERVER_ADMIN_MOTD_EDITOR   [ 24 ],
    E_SERVER_ADMIN_MOTD_EDIT_TIME,

    E_SERVER_TEXTDRAW_TICK,

    E_SERVER_CHOPSHOP_FACTIONID,
    E_SERVER_CHOPSHOP_COLLECT,

    DynamicText3D:
        E_SERVER_CHOPSHOP_LABEL,

        // Random help msgs
        E_SERVER_RAND_MSG,

        // For casinos
        E_SERVER_SLOTS_JACKPOT,
        DynamicText3D:
        E_SERVER_SLOTS_JACKPOTLABEL [ 3 ],

        Float:
        E_SERVER_LAST_911_POS_X,
        Float:
        E_SERVER_LAST_911_POS_Y,
        Float:
        E_SERVER_LAST_911_POS_Z,
        E_SERVER_LAST_911_TYPE,


        Float:
        E_SERVER_POLICE_KIOSK_X,
        Float:
        E_SERVER_POLICE_KIOSK_Y,
        Float:
        E_SERVER_POLICE_KIOSK_Z,
        E_SERVER_POLICE_KIOSK_INT,
        E_SERVER_POLICE_KIOSK_VW,
        DynamicText3D:
        POLICE_KIOSK_LABEL,

        E_SERVER_SONG_URL[128],
        E_SERVER_ACCS_DISABLED_UNTIL,

        bool:
        E_SERVER_IS_DS_OFF

    } ;

new Server [ E_SERVER_DATA ] ;

// Locations (make these dynamic eventually... /createpoint [type: chopshop/dmv/...], /movepoint, /deletepoint, /setpoint?)
#define CHOPSHOP_X (RuntimeLocations[RT_LOC_CHOPSHOP][RLOC_X]) // Cached database setting; edit through ACP.
#define CHOPSHOP_Y (RuntimeLocations[RT_LOC_CHOPSHOP][RLOC_Y]) // Cached database setting; edit through ACP.
#define CHOPSHOP_Z (RuntimeLocations[RT_LOC_CHOPSHOP][RLOC_Z]) // Cached database setting; edit through ACP.

#define SERVER_DMV_X (RuntimeLocations[RT_LOC_DMV][RLOC_X]) // Cached database setting; edit through ACP.
#define SERVER_DMV_Y (RuntimeLocations[RT_LOC_DMV][RLOC_Y]) // Cached database setting; edit through ACP.
#define SERVER_DMV_Z (RuntimeLocations[RT_LOC_DMV][RLOC_Z]) // Cached database setting; edit through ACP.


// Forwards
forward bool:IsFactionVehicle(vehicleid, factionid);
forward bool:IsGovFactionVehicle(vehicleid);
forward bool:Faction_CanID(faction_enum_id, cap);
forward bool:IsPlayerInFirm(playerid, firm_sql_id = 0);
forward bool:CanUseLawyerTools(playerid);
forward Float:SP_GetWeaponDamageFromDistance(weaponid, Float:distance);
forward Float:
GetAngleToPos(Float: PX, Float: PY, Float: X, Float: Y);


#define CGEN_MEMORY 50000

#define OVERRIDE_NATIVE_GAMETEXT // This line should be added before including GameText+!
#include <gametext_plus>
#include "config/secrets.pwn" // gitignored, see config/secrets.example.pwn
#include "config/header.pwn"
#include <removebuilding>
#include "browser/header.pwn"

#include "discord/header.pwn"
#include "player/header.pwn"
#include "tags/header.pwn" // up to date (2024)
#include "visuals/header.pwn"
#include "admin/header.pwn"
#include "attachments/header.pwn"
#include "anims/header.pwn" // up to date (2024)
#include "money/header.pwn" // up to date (2024)
#include "vehicle/header.pwn"
#include "carjack/header.pwn"
#include "faction/header.pwn"
#include "firm/header.pwn"
#include "weapons/header.pwn"
#include "drugs/header.pwn"
#if defined FEATURE_EMMET
#include "emmet/header.pwn" // up to date (2024) - rewrite needed later for /buygun
#endif
#include "hunger/header.pwn" // up to date (2024)
//#include "hitman/header.pwn"
#include "gym/header.pwn"
#include "skins/header.pwn"
#include "property/header.pwn"// up to date (2024)
#include "gps/header.pwn" // up to date (2024)
#include "furniture/header.pwn"
#include "passpoints/header.pwn"// up to date (2024)
#include "police/header.pwn"// up to date (2024)
#include "news/header.pwn"// up to date (2024)
#include "boombox/header.pwn"
#include "adminobjects/header.pwn"
#include "gates/header.pwn"
#include "injury/header.pwn"
#include "message/header.pwn" // up to date (2024)
#include "phone/header.pwn" // up to date (2024)
#include "config/time_weather.pwn" // up to date (2024)
#include "config/native.pwn"
#include "money/paycheck.pwn" // up to date (2024)
#include "jobs/header.pwn"
#include "minigame/header.pwn"
#include "minigame_battle/header.pwn"
#include "anticheat/header.pwn" // up to date (2024) - minor remodularisation needed
#include "admin/fly.pwn"
#include "helpers/header.pwn"
#include "misc/header.pwn"
#if defined FEATURE_GANGZONES
#include "gangzones/header.pwn"
#endif
#include "paynspray/header.pwn" // up to date (2024)
#include "modshops/header.pwn"
#include "chopshop/header.pwn"
#include "admin/refunds.pwn"
#include "licenses/header.pwn"
//#include "lowrider/header.pwn"

#include "player/player_hooked.pwn"
#include "config/server-native.pwn"
#include "visuals/loadtextdraws.pwn"

#include "web/commands.pwn"

//#include "event_christmas.pwn"
//#include "event_easter.pwn"
//#include "event_halloween.pwn"

// Placement adapters depend on the completed job and property modules.
#include "property/runtime.pwn"
#include "vehicle/runtime.pwn"
#include "config/runtime/loader.pwn"
#include "config/runtime/world.pwn"

forward OnStartSQL();
// Callback used as a hook point that runs once the database is connected.
public OnStartSQL()
{
    // You can hook this
    return 1;
}

forward OnModelsPreload();
// Called while custom models load: loads static maps and attachment models.
public OnModelsPreload()
{
    LoadStaticMaps();
    Attachments_LoadEntities();
    return 1;
}

// Removes the default GTA buildings for each connecting player (so your map can replace them).
public OnPlayerConnect(playerid)
{
    RemoveBuildingsForPlayer(playerid);
    return 1;
}

// Server start-up. Connects to MySQL, runs OnStartSQL/OnModelsPreload/OnRemoveBuilding and then
// loads every system in order.
main()
{
    printf("[DEBUG] 1 start");
    if (!MySQL_Init()) { SendRconCommand("exit"); return 0; }
    if (!RuntimeConfig_Init()) { print("[FATAL] Apply runtime migrations 001 through 005 from database/migrations/."); SendRconCommand("exit"); return 0; }
    printf("[DEBUG] 2 MySQL_Init");
    CallLocalFunction("OnStartSQL", "");            printf("[DEBUG] 3 OnStartSQL");
    if (!CA_Init()) {
        print("[FATAL] ColAndreas collision data is missing or invalid. Generate scriptfiles/colandreas/ColAndreas.cadb with the ColAndreas Wizard; see SETUP.md.");
        SendRconCommand("exit");
        return 0;
    }
    printf("[DEBUG] 3b CA_Init");
    #if FEATURE_CUSTOM_SKINS
        CustomSkins_LoadModels();
    #endif
    CallLocalFunction("OnModelsPreload", "");       printf("[DEBUG] 4 OnModelsPreload");
    CallLocalFunction("OnRemoveBuilding", "");      printf("[DEBUG] 5 OnRemoveBuilding");
    Streamer_SetTickRate(30);                       printf("[DEBUG] 6 Streamer");
    Main_LoadDatabaseSettings();                    printf("[DEBUG] 7 DBSettings");
    Main_LoadServerSettings();                      printf("[DEBUG] 8 SrvSettings");
    OnLoadTextdraws();                              printf("[DEBUG] 9 Textdraws");
    Fine_LoadLabel();                               printf("[DEBUG] 10 Fine");
    Vehicle_LoadEntities();                         printf("[DEBUG] 11 Vehicles");
    SavedFurni_LoadEntities();                      printf("[DEBUG] 12 Furni");
    Tune_LoadEntities();                            printf("[DEBUG] 13 Tune");
    Faction_LoadEntities();                         printf("[DEBUG] 14 Factions");
    Firm_LoadEntities();                            printf("[DEBUG] 15 Firms");
    Dealership_LoadEntities();                      printf("[DEBUG] 15b Dealerships");
    Wounds_LoadEntities();                          printf("[DEBUG] 16 Wounds");
#if defined FEATURE_EMMET
    Emmet_LoadEntities();                           printf("[DEBUG] 17 Emmet");
#endif
    ScrapYard_LoadEntities();                       printf("[DEBUG] 18 Scrapyard");
    Gate_LoadEntities();                            printf("[DEBUG] 19 Gates");
    Drugs_LoadEntities();                           printf("[DEBUG] 20 Drugs");
    Jobs_Init();                                    printf("[DEBUG] 21 Jobs");
    Advert_Init();                                  printf("[DEBUG] 22 Adverts");
    Minigames_LoadEntities();                       printf("[DEBUG] 23 Minigames");
    RPRF_LoadEntities();                            printf("[DEBUG] 24 RPRF");
    Respray_LoadEntities();                         printf("[DEBUG] 25 Respray");
    Toll_LoadEntities();                            printf("[DEBUG] 26 Tolls");
    Impound_LoadEntities();                         printf("[DEBUG] 27 Impound");
    ActorRobbery_LoadEntities();                    printf("[DEBUG] 28 ActorRobbery");
#if defined FEATURE_GANGZONES
    GangZone_LoadEntities();                        printf("[DEBUG] 29 GangZones");
#endif
    Boombox_LoadEntities();                         printf("[DEBUG] 30 Boombox");
    MusicSource_LoadEntities();                     printf("[DEBUG] 30b MusicSources");
    RealEstate_LoadDesks();                         printf("[DEBUG] 30c RealEstate desks");
    ChopShop_LoadEntities();                        printf("[DEBUG] 31 ChopShop");
    Fuel_OnScriptInit();                            printf("[DEBUG] 32 Fuel");
    Realty_LoadEntities();                          printf("[DEBUG] 33 Realty");
    Notes_Load();                                   printf("[DEBUG] 34 Notes");
    LoadPayNSpray();                                printf("[DEBUG] 35 PayNSpray");
    LoadActors();                                   printf("[DEBUG] 36 Actors");
    InitBikeTransport();                            printf("[DEBUG] 37 Bikes");
    AdminObject_LoadEntities();                     printf("[DEBUG] 38 AdminObjects");
    //Memorial_LoadModels();                          printf("[DEBUG] 40 Memorial");
    LoadVPNWhitelist();                             printf("[DEBUG] 41 VPN");
    mysql_tquery(mysql, "DELETE FROM player_weapons WHERE weapon_ammo = 0");
    mysql_tquery(mysql, "UPDATE characters SET player_online = 0");
    mysql_tquery(mysql, "UPDATE accounts SET account_online = 0");
    mysql_tquery(mysql, "UPDATE characters SET player_on_duty = 0");   printf("[DEBUG] 42 MySQL queries");
    AddPlayerClass(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);                  printf("[DEBUG] 43 PlayerClass");
    SetTimer("FactionActivity_Tick", 60000, true);
    SetTimer("WebCommands_Poll", 2000, true);
    defer ASCII_Print[5000]();
    defer UpdateTablist();                          printf("[DEBUG] 44 complete");
    return true;
}


// Server shutdown: closes the MySQL connection.
public OnGameModeExit()
{

    RuntimeConfig_Shutdown();
    mysql_close(mysql);

    return true ;
}




stock HandleTestingProps(playerid)   // Make sure this is disabled on runtime.
{
    Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] = ADMIN_LVL_MANAGER;
    SendClientMessage(playerid, -1, " ");
    SendClientMessage(playerid, COLOR_YELLOW, "Welcome to the test server of " SERVER_NAME ".");
    SendClientMessage(playerid, COLOR_YELLOW, "Use /help and /staffhelp for command lists.");
    SendClientMessage(playerid, COLOR_ERROR, "It is HIGHLY discouraged to do anything other than testing.");
    SendClientMessage(playerid, COLOR_ERROR, "If you impede people from doing their testing tasks, you will be sanctioned.");
    SendClientMessage(playerid, COLOR_ERROR, "If you leak the IP address, you will be permanently banned.");
    SendClientMessage(playerid, -1, " ");
}

/*CMD:testadmin(playerid, params[]) {
	Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] = 0;
	SendClientMessage(playerid, COLOR_YELLOW, "Temporarily removed your admin.");
	return 1;
}*/


// Timer: prints a 'server is ready' banner once start-up has finished.
timer ASCII_Print[5000]()
{

    //printf("[Buildings] Removed %d objects globally", CountRemovedObjects());
    print(" * Server is ready for connections.");
    printf("[RemoveBuilding] Removed %d objects globally", GetRemovedBuildingCount());
    //PrintRemovedBuildings();
    new string[64];
    format(string, sizeof(string), "[Server] Server has been started and is ready for connections.") ;
    //SendAdminMessage(string) ;
}

// Misc unused shit
/*DCC_SendAdminPunishmentMessage(const msg[]) print(msg);
DCC_SendAdvertisementMessage(type, const msg[]) {
	printf("%d - %s", type, msg);
}
stock DCC_SendAntiCheatMessage(const title[], const msg[]) {
	printf("%s - %s", title, msg);
}
DCC_SendCharityLogMessage(const msg[]) print(msg);
DCC_SendAdminLogMessage(const msg[]) print(msg);*/

// /clearcd - (rcon admin) resets your own chop shop and robbery cooldowns for testing.
CMD:clearcd(playerid, params[])
{
    if (!IsPlayerAdmin(playerid)) return 0;

    Character [ playerid ] [ E_CHARACTER_CHOPSHOP_CD ] = 0;
    Character [ playerid ] [ E_CHARACTER_ROBBERY_COOLDOWN ] = 0;
    SendClientMessage(playerid, COLOR_YELLOW, sprintf("Developer (%d) %s has reset your cooldowns. This does NOT save and is for testing purposes only.", playerid, ReturnMixedName(playerid))) ;

    return 1;
}


forward OnRemoveBuilding();
// Hook point where maps remove default buildings.
public OnRemoveBuilding()
{
    return 1;
}

// ------------------------------------------------------------ Hotkeys ------------------------------------------------------------ //
static bool:LightsCooldown[MAX_PLAYERS];
hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    new bool:inVehicle = (GetPlayerVehicleSeat(playerid) != -1);
    // H on foot - enter/exit
    if(PRESSED(KEY_CTRL_BACK) && !inVehicle) {
        if (GetPlayerVirtualWorld(playerid) != 0) {

            if ( IsPlayerIncapacitated(playerid, true) ) return 1 ;
            if (IsPlayerFading(playerid)) return 1;
            if (!Gym_Exit(playerid) ) return Property_Exit(playerid);

        } else return Property_Enter(playerid);
        
    }

    if(!inVehicle) return 1;

    // RMB on vehicle - lights
    /*if(PRESSED(KEY_FIRE) && !LightsCooldown[playerid]) {
        LightsCooldown[playerid] = true;
        cmd_lights(playerid);
        SetTimerEx("ResetLightsCooldown", 1000, false, "i", playerid);
    }*/

    // 2 on vehicle - engine
    /*if(PRESSED(KEY_LOOK_BEHIND)) {
        cmd_engine(playerid);
    }*/

    return 1;
}

forward ResetLightsCooldown(playerid);
// Timer helper: ends the vehicle lights cooldown.
public ResetLightsCooldown(playerid) {
    LightsCooldown[playerid] = false;
}

#pragma unused Attachments_CountBone
#pragma unused CanUseSecurityTools
#pragma unused ClassBrowser_HideTextDraws
#pragma unused FactionSkin_LoadEntities
#pragma unused Firm_GetField
#pragma unused Firm_GetName
#pragma unused Faction_GetHex
#pragma unused Faction_GetName
#pragma unused Faction_SendTypeMessage
#pragma unused GetPlayerPenaltyCount
#pragma unused HasPropertyDuplicateKey
#pragma unused IsFirmVehicle
#pragma unused IsGovVehicle
#pragma unused IsPlayerOnFirmDuty
#pragma unused IsPlayerContributor
#pragma unused PlayerClassSelection
#pragma unused Player_ShowSkinMenu
#pragma unused Property_GetSQLID
#pragma unused Property_GetType
#pragma unused ORP_IsPropertyRenter
#pragma unused illegal_nos_vehicle
#pragma unused KnifeSync_OnPlayerGiveDamage
#pragma warning disable 213
