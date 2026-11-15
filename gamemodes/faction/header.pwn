// ============================================================================
// File: faction/header.pwn
// Faction module entry point. Defines the capability check Faction_Can()/Faction_CanID() (what
// a faction is ALLOWED to do via FAC_CAP_* flags), type checks (IsFactionTypeVehicle), and
// /leavefaction. Includes the rest of the faction files.
// Commands: /leavefaction
// ============================================================================

enum   // Cross script!
{

    E_FACTION_EXTRA_NONE,
    E_FACTION_EXTRA_GUNS,
    E_FACTION_EXTRA_DRUGS_WEED,
    E_FACTION_EXTRA_DRUGS_CRACK,
    E_FACTION_EXTRA_DRUGS_COKE,
    E_FACTION_EXTRA_DRUGS_METH,
    E_FACTION_EXTRA_CARTEL,
    E_FACTION_EXTRA_GANG
}

#include "faction/data.pwn"
#include "faction/func.pwn"
#include "faction/squads.pwn"
#include "faction/admin.pwn"
#include "faction/member.pwn"
#include "faction/player.pwn"
#include "faction/spawn.pwn"
#include "faction/spawnpoints.pwn"
#include "faction/communication.pwn"
//#include "faction/memorials.pwn"

/*#include "faction/docks/dock.pwn"
#include "faction/docks/freighter.pwn"
#include "faction/docks/containers.pwn"
#include "faction/docks/cargorun.pwn"
#include "faction/docks/logisticsrun.pwn"
#include "faction/docks/scraprun.pwn"*/






#include "faction/bank/header.pwn"
#include "faction/armory.pwn"
#include "faction/skins/header.pwn"

// func IsFactionTypeVehicle
IsFactionTypeVehicle(vehicleid, factiontype)
{
    if (vehicleid == INVALID_VEHICLE_ID || !vehicleid)
    {
        return false;
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
    {
        return false;
    }

    if (Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FACTION)
    {
        for (new i, j = sizeof(Faction); i < j ; i ++)
        {
            if (Faction [ i ] [ E_FACTION_ID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] && Faction [ i ] [ E_FACTION_TYPE ] == factiontype)
            {
                return true;
            }
        }
    }

    return false;
}

// Returns true if a vehicle belongs to the given faction.
bool:IsFactionVehicle(vehicleid, factionid)
{
    if (vehicleid == INVALID_VEHICLE_ID || !vehicleid)
    {
        return false;
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
    {
        return false;
    }

    return Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FACTION && Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] == factionid;
}

// Returns true if a vehicle belongs to a government faction (police, federal, EMS, government).
bool:IsGovFactionVehicle(vehicleid)
{
    new factiontype = GetVehicleFactionType(vehicleid);
    return factiontype == FACTION_TYPE_LEO || factiontype == FACTION_TYPE_FEDERAL ||
           factiontype == FACTION_TYPE_EMS || factiontype == FACTION_TYPE_GOV;
}

// A faction vehicle's owning faction SQL id (0 if none). For targeting a
// specific faction rather than its type.
stock GetVehicleFactionID(vehicleid)
{
    if (vehicleid == INVALID_VEHICLE_ID || !vehicleid)
        return 0;

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);
    if (veh_enum_id == -1)
        return 0;

    if (Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FACTION)
        return 0;

    return Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ];
}

// func GetVehicleFactionType
GetVehicleFactionType(vehicleid)
{
    if (vehicleid == INVALID_VEHICLE_ID || !vehicleid)
    {
        return -1;
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
    {
        return -1;
    }

    if (Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FACTION)
    {
        for (new i, j = sizeof(Faction); i < j ; i ++)
        {
            if (Faction [ i ] [ E_FACTION_ID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ])
            {
                return Faction [ i ] [ E_FACTION_TYPE ];
            }
        }
    }

    return -1;
}

// Returns the faction type of the player's faction.
GetPlayerFactionType(playerid)
{
    if (Character [ playerid ] [ E_CHARACTER_FACTIONID ])
    {
        new faction_enum_id = Faction_GetEnumID(Character [ playerid ] [ E_CHARACTER_FACTIONID ]) ;
        return Faction_GetType(faction_enum_id);
    }

    return -1;
}

// Returns how many seconds are left on the player's faction suspension, or 0.
GetPlayerFactionSuspension(playerid)
{
    new suspended = 0;

    if (Character[playerid][E_CHARACTER_FACTIONID] && Character[playerid][E_CHARACTER_FACTION_SUSPENSION] && Character[playerid][E_CHARACTER_FACTION_SUSPENSION] > gettime())
    {
        suspended = Character[playerid][E_CHARACTER_FACTION_SUSPENSION] - gettime();
    }

    return suspended;
}

// Returns true if the player is in the given faction (and on duty when requested).
stock IsPlayerInFaction(playerid, factionid, bool:onduty = false)
{
    new faction = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;
    return faction == factionid && (!onduty || PlayerVar [ playerid ] [ E_PLAYER_FACTION_DUTY ]);
}

// ---------------------------------------------------------------------------
// Capability checks - the single answer to "may this faction do X?".
//
// Replaces every "type == POLICE || type == SHERIFF || ..." chain. Add a
// faction and set its capability bits (Schemas) and it is covered everywhere;
// no code changes and no lists to extend.
// ---------------------------------------------------------------------------
bool: Faction_CanID(faction_enum_id, cap)
{
    if (faction_enum_id == INVALID_FACTION_ID)
        return false;

    return (Faction [ faction_enum_id ] [ E_FACTION_CAPABILITIES ] & cap) == cap;
}

// Returns true if the player's faction is allowed to do something (a FAC_CAP_* flag). This is the
// main permission check for faction powers.
bool: Faction_Can(playerid, cap, bool:onduty = false)
{
    if (! Character [ playerid ] [ E_CHARACTER_FACTIONID ])
        return false;

    if (onduty && ! PlayerVar [ playerid ] [ E_PLAYER_FACTION_DUTY ])
        return false;

    new faction_enum_id = Faction_GetEnumID(Character [ playerid ] [ E_CHARACTER_FACTIONID ]);
    return Faction_CanID(faction_enum_id, cap);
}

// Returns true if the player is in a faction of a given type.
IsPlayerInFactionType(playerid, factiontype, bool:onduty = false)
{
    new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

    if (! factionid)
    {

        return false ;
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID)
    {

        return false ;
    }

    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == factiontype && (!onduty || PlayerVar [ playerid ] [ E_PLAYER_FACTION_DUTY ]))
    {

        return true ;
    }

    return false ;
}

// Returns true if the player is in any duty faction (law enforcement, medic, news, security).
IsPlayerInDutyFaction(playerid)
{
    return IsPlayerInLEAFaction(playerid) || IsPlayerInMedicFaction(playerid) || IsPlayerInNewsFaction(playerid) || IsPlayerInGovFaction(playerid) || IsPlayerInSecurityFaction(playerid);
}

// Returns true if the player is in a medical (EMS/fire) faction.
IsPlayerInMedicFaction(playerid, bool:onduty = false)
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_EMS, onduty);
}

// Returns true if the player is in a trucker faction.
IsPlayerInTruckerFaction(playerid, bool:onduty = false)
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_TRUCKER, onduty);
}

// Returns true if the player is in a government faction.
IsPlayerInGovFaction(playerid, bool:onduty = false)
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_GOV, onduty);
}

// Returns true if the player is in any government service faction.
IsPlayerInAnyGovFaction(playerid, bool:onduty = false)
{
    return IsPlayerInLEAFaction(playerid, onduty) || IsPlayerInMedicFaction(playerid, onduty) || IsPlayerInGovFaction(playerid, onduty);
}

// TODO: Move these to gov
IsPlayerGovJudge(playerid, bool:onduty = false)
{
    return IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_COURT, FACTION_TYPE_GOV, onduty);
}

// Returns true if the player is a government administrator.
IsPlayerGovAdmin(playerid, bool:onduty = false)
{
    return IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_ADMIN, FACTION_TYPE_GOV, onduty);
}

// Returns true if the player is a government cop (DAI squad).
IsPlayerGovCop(playerid, bool:onduty = false)
{
    return IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_DAI, FACTION_TYPE_GOV, onduty);
}

// Returns true if the player can use government records (judge, cop or similar).
IsPlayerGovRecords(playerid, bool:onduty = false)
{
    return IsPlayerGovJudge(playerid, onduty) || IsPlayerGovCop(playerid, onduty) || IsPlayerGovAdmin(playerid, onduty);
}

//--
CMD:leavefaction(playerid, params[])
{

    new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

    if (! factionid)
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id != INVALID_FACTION_ID)
    {
        Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has left the faction. }",
                                               Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], playerid, ReturnRPName(playerid)), faction_enum_id, false) ;
    }

    // Disarm them as a precaution
    if (IsPlayerInDutyFaction(playerid))
    {
        Weapon_ResetPlayerWeapons(playerid);
    }

    Character [ playerid ] [ E_CHARACTER_FACTIONID ] = 0 ;
    Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] = 3 ;
    Character [ playerid ] [ E_CHARACTER_FACTION_SUSPENSION ] = 0 ;
    Character [ playerid ] [ E_CHARACTER_FACTIONRANK ] [ 0 ] = EOS ;
    strcat(Character [ playerid ] [ E_CHARACTER_FACTIONRANK ], "None") ;

    Character [playerid] [E_CHARACTER_RAG_ON] = false;
    UpdateTabListForOthers(playerid);

    new query [ 512 ] ;

    mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_factionid = 0, player_factiontier = 3, player_factionrank = 'None', player_factionsuspension = 0 WHERE player_id = %d", Character [ playerid ] [ E_CHARACTER_ID ]) ;
    mysql_tquery(mysql, query);

    SendClientMessage(playerid, 0xA3A3A3FF, "You've left your faction.");
    return true ;
}


// Shows the list of commands the player's faction can use.
ShowFactionCommands(playerid)
{

    new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

    if (! factionid)
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new  faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID)
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    }

    SendClientMessage(playerid, 0x5FB9D1FF, "[ ___________ Faction Commands  ___________ ]");
    SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /f(action), /(un)invite, /settier, /setrank, /setsquad, /nofac, /ftow");
    SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /fvehicles (/fcars, /fveh, /fvehs), /fpark, /fskins, /fspawn");
    SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /fspawnicon, /fspawntog /nofac, /fcarcolor, /factionbank, /fbank deposit/withdraw");
    SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /leavefaction, /suspend, /fonline, /foffline");

    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_ILLEGAL)
    {

        SendClientMessage(playerid, 0x7a8ea1FF, "[GANG]: {B2FFCD}/ragon, /ragoff");
    }

    // Is player police
    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_LEO ||
            Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_FEDERAL)
    {

		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/duty, /kevlar(off), /armory, /radio [1-5] [msg], /r [msg], /r1-/r5, /rlow, /channels, /ch, /dep, /hq, /m, /cuff");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/(un)cuff, /taser, /beanbag, /tackle, /carcheck, /searchaddress, /vticket");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/takelicense, /frisk, /disarm, /confiscate, /breakincar, /tolls, /arrest, /unjail");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/charge, /writeticket, /giveticket, /driverwarn, /breathalyzer, /cancelbreathalyzer");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/prisoners, /viewairspace, /atc, /setsquad, /setbadge, /showbadge, /lastalarm");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/p(anic)b(utton), /b(ac)k(up), /backupall, /cancelpanic, /cancelbk, /cad, /units, /swat, /spikes");
		SendClientMessage(playerid, 0x77BBFAFF, "[LEA]: {BBDEFF}/destroyplant - Destroy a nearby drug plant (must be within 3 units)");
	}

    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_GOV)
    {

		SendClientMessage(playerid, 0x7a8ea1FF, "[GOV]: {BBDEFF}/duty, /radio [1-5] [msg], /r1-/r5, /rlow, /channels, /dep, /hq, /armory, /setbadge, /showbadge");

        if (IsPlayerGovCop(playerid))
        {
            SendClientMessage(playerid, 0x7a8ea1FF, "[GOV Investigator]: {BBDEFF}/kevlar(off), /(un)cuff, /tackle, /charge");
        }
    }


    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_EMS)
    {

		SendClientMessage(playerid, 0xF87070FF, "[FD]: {FDBCBC}/duty, /radio [1-5] [msg], /r1-/r5, /rlow, /channels, /hq, /armory, /setbadge, /showbadge");
		SendClientMessage(playerid, 0xF87070FF, "[FD]: {FDBCBC}/m, /atc, /revive, /heal, /lastalarm, /panic");
	}

    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_LEO)
    {

        SendClientMessage(playerid, 0xF87070FF, "[EMS]: {FDBCBC}/revive, /heal, /panic");
    }

    if (Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_NEWS)
    {

        SendClientMessage(playerid, 0x24ADE8FF, "[NEWS]: {2ED8F6}/pager, /atc, /showbadge, /breaking, /broadcast, /live, /newsroom");
        SendClientMessage(playerid, 0x24ADE8FF, "[NEWS]: {2ED8F6}/coanchor, /broadcasthistory, /reporterleaderboard, /mybroadcaststats, /weeklyactivity");
    }


	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > ADMIN_LVL_NONE ) {
		SendClientMessage(playerid, 0x58DD85FF, "[ADMIN]:{B2FFCD} /afjoin, /f(action)name, /f(action)create, /fskinadd, /fhex");
	}

	return true ;
}
