// ============================================================================
// File: police/detaining/arrest.pwn
// Arrests and jail: /arrest puts a suspect in a cell for a set time, /jailtime shows the
// remaining time, /releaseme releases a prisoner who has served their sentence, plus /unjail,
// /setcell, /jailforlife and the faction help desks (/ringbell). Cell, release and desk
// coordinates are 0,0,0 until you set them.
// Commands: /ringbell /prisoners /jailtime /releaseme /unjail /setcell /arrest /setarrestpos
// /arrestme /jailforlife /processjfl /removejfl
// ============================================================================

static enum E_HELPDESK_DATA
{
    E_HELPDESK_FACTION,
    E_HELPDESK_FACTYPE,
    E_HELPDESK_ICON,
    E_HELPDESK_NAME[64],
    E_HELPDESK_DESC[128],
    Float:E_HELPDESK_X,
    Float:E_HELPDESK_Y,
    Float:E_HELPDESK_Z,
    E_HELPDESK_INT,
    E_HELPDESK_VW,
    E_HELPDESK_LAST_CALLED
}

enum E_JAIL_SPAWN
{
    Float:JAIL_X,
    Float:JAIL_Y,
    Float:JAIL_Z,
    Float:JAIL_A,
    JAIL_WORLD,
    JAIL_INTERIOR,
    JAIL_CELL[4]
};

// Cell labels are stable three-character codes. Occupied cells are protected
// from relocation by the shared save service and by the live preflight below.
new JailSpawns[64][E_JAIL_SPAWN], JailSpawnCount;

Runtime_RebuildPrisonCells() {
    foreach(new playerid:Player) {
        if(!Character[playerid][E_CHARACTER_ARREST_CELL][0] || (!Character[playerid][E_CHARACTER_ARREST_TIME] && !Character[playerid][E_CHARACTER_JFL])) continue;
        new bool:found;
        for(new i; i<RuntimeLocationCount; i++) {
            if(RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_PRISON_CELL || !RuntimeLocations[i][RLOC_ENABLED] || strcmp(RuntimeLocations[i][RLOC_LABEL],Character[playerid][E_CHARACTER_ARREST_CELL],true)) continue;
            found=true;
            if(RuntimeLocations[i][RLOC_X]!=Character[playerid][E_CHARACTER_ARREST_X] || RuntimeLocations[i][RLOC_Y]!=Character[playerid][E_CHARACTER_ARREST_Y] || RuntimeLocations[i][RLOC_Z]!=Character[playerid][E_CHARACTER_ARREST_Z] || RuntimeLocations[i][RLOC_WORLD]!=Character[playerid][E_CHARACTER_ARREST_VW] || RuntimeLocations[i][RLOC_INTERIOR]!=Character[playerid][E_CHARACTER_ARREST_INT]) return 0;
        }
        if(!found) return 0;
    }
    JailSpawnCount=0;
    for(new i; i<RuntimeLocationCount; i++) {
        if(RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_PRISON_CELL || !RuntimeLocations[i][RLOC_ENABLED]) continue;
        new row=JailSpawnCount++;
        JailSpawns[row][JAIL_X]=RuntimeLocations[i][RLOC_X]; JailSpawns[row][JAIL_Y]=RuntimeLocations[i][RLOC_Y]; JailSpawns[row][JAIL_Z]=RuntimeLocations[i][RLOC_Z]; JailSpawns[row][JAIL_A]=RuntimeLocations[i][RLOC_ANGLE];
        JailSpawns[row][JAIL_WORLD]=RuntimeLocations[i][RLOC_WORLD]; JailSpawns[row][JAIL_INTERIOR]=RuntimeLocations[i][RLOC_INTERIOR];
        format(JailSpawns[row][JAIL_CELL],4,"%s",RuntimeLocations[i][RLOC_LABEL]);
    }
    return 1;
}

// The position of each desk in this list is what the IsAt...FrontDesk helpers below check for, so keep
// the HELPDESK_ defines in step with it.
#define HELPDESK_CITYHALL   (0)
#define HELPDESK_SAPD       (1)

static FacHelpDesk[][E_HELPDESK_DATA] =
{
    // TODO: set coordinates for your map (these help desks are at 0,0,0 until you do).
    // Administration Building: name changes, paying fines and tickets, registering a firm.
    { 99, FACTION_TYPE_GOV, 1239, "Administration Building", "{8D8DFF}/namechange{DEDEDE}, {8D8DFF}/firmcreate{DEDEDE}, {8D8DFF}/payfine{DEDEDE}, {8D8DFF}/paytickets",  0.0, 0.0, 0.0, 0, 0 },
    { FACTION_ID_SAPD, 0, 1247, "Police Department",   "{8D8DFF}/payfine{DEDEDE}, {8D8DFF}/prisoners, {8D8DFF}/paytickets",  0.0, 0.0, 0.0, 0, 0 } // SAPD HQ
};

#define ARREST_TIME_AWAITING_RELEASE (-1)

// Cancels a prisoner's /releaseme timer and gives back control.
static Arrest_ResetReleaseTimer(playerid, bool:restore_control = true)
{
    PlayerVar[playerid][E_PLAYER_RELEASEME_TICK] = 0;
    PlayerVar[playerid][E_PLAYER_RELEASEME_DMG]  = false;

    if (restore_control)
        TogglePlayerControllable(playerid, true);

    return true;
}

// Where a prisoner appears when they're released after serving their sentence (/releaseme).
#define PRISON_RELEASE_X (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_X])
#define PRISON_RELEASE_Y (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_Y])
#define PRISON_RELEASE_Z (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_Z])
#define PRISON_RELEASE_A (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_ANGLE])
#define PRISON_RELEASE_INT (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_INTERIOR])
#define PRISON_RELEASE_VW (RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_WORLD])

// Releases a prisoner: clears their sentence and teleports them to the release point.
static Arrest_ReleasePlayer(playerid)
{
    new query[256];

    Character[playerid][E_CHARACTER_ARREST_TIME]    = 0;
    Character[playerid][E_CHARACTER_ARREST_CELL][0] = EOS;
    Character[playerid][E_CHARACTER_JFL]            = 0;

    if(RuntimeLocations[RT_LOC_PRISON_RELEASE][RLOC_ENABLED]) {
        ORP_SetPlayerPos(playerid,PRISON_RELEASE_X,PRISON_RELEASE_Y,PRISON_RELEASE_Z);
        SetPlayerFacingAngle(playerid,PRISON_RELEASE_A); SetPlayerInterior(playerid,PRISON_RELEASE_INT); SetPlayerVirtualWorld(playerid,PRISON_RELEASE_VW);
    }

    if (Character[playerid][E_CHARACTER_SKIN_BEFORE] != 0)
    {
        SetPlayerSkinEx(playerid, Character[playerid][E_CHARACTER_SKIN_BEFORE]);
        Character[playerid][E_CHARACTER_SKINID]      = Character[playerid][E_CHARACTER_SKIN_BEFORE];
        Character[playerid][E_CHARACTER_SKIN_BEFORE] = 0;

        mysql_format(mysql, query, sizeof(query),
            "UPDATE characters SET player_skin_before = 0 WHERE player_id = %d",
            Character[playerid][E_CHARACTER_ID]);
        mysql_tquery(mysql, query);
    }

    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_arrest_time = 0, player_arrest_cell = '', player_jfl = 0 WHERE player_id = %d",
        Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    SendServerMessage(playerid, COLOR_BLUE, "Arrest", "A3A3A3", "You've been released from captivity.");
    return true;
}

new DynamicText3D:HelpDeskLabels[2], HelpDeskPickups[2];
new const HelpDeskSources[]={RT_LOC_ADMINISTRATION_DESK,RT_LOC_SAPD_DESK};

// Repeated loads replace tracked handles and preserve the bell cooldown.
Fine_LoadLabel() {
    new DynamicText3D:labels[2], pickups[2];
    for(new i; i<2; i++) {
        new source=HelpDeskSources[i];
        if(!RuntimeLocations[source][RLOC_ENABLED]) continue;
        labels[i]=CreateDynamic3DTextLabel(sprintf("[%s]\n%s\n{DEDEDE}/ringbell for attention.",RuntimeLocations[source][RLOC_LABEL],FacHelpDesk[i][E_HELPDESK_DESC]),0x3479E3FF,
            RuntimeLocations[source][RLOC_X],RuntimeLocations[source][RLOC_Y],RuntimeLocations[source][RLOC_Z],15.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,true,RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR]);
        if(RuntimeLocations[source][RLOC_MODEL]) pickups[i]=CreateDynamicPickup(RuntimeLocations[source][RLOC_MODEL],1,RuntimeLocations[source][RLOC_X],RuntimeLocations[source][RLOC_Y],RuntimeLocations[source][RLOC_Z],RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR]);
        if(!IsValidDynamic3DTextLabel(labels[i]) || (RuntimeLocations[source][RLOC_MODEL] && !IsValidDynamicPickup(pickups[i]))) {
            for(new n; n<2; n++) { if(IsValidDynamic3DTextLabel(labels[n])) DestroyDynamic3DTextLabel(labels[n]); if(IsValidDynamicPickup(pickups[n])) DestroyDynamicPickup(pickups[n]); }
            return 0;
        }
    }
    for(new i; i<2; i++) {
        if(IsValidDynamic3DTextLabel(HelpDeskLabels[i])) DestroyDynamic3DTextLabel(HelpDeskLabels[i]);
        if(IsValidDynamicPickup(HelpDeskPickups[i])) DestroyDynamicPickup(HelpDeskPickups[i]);
        HelpDeskLabels[i]=labels[i]; HelpDeskPickups[i]=pickups[i];
        format(FacHelpDesk[i][E_HELPDESK_NAME],64,"%s",RuntimeLocations[HelpDeskSources[i]][RLOC_LABEL]);
    }
    return 1;
}

// Disabled desks and mismatched worlds cannot serve players at the origin.
IsAtFrontDesk(playerid) {
    for(new i; i<2; i++) if(Runtime_AtLocation(playerid,HelpDeskSources[i])) return i;
    return -1;
}

IsAtGovFrontDesk(playerid)     { return IsAtFrontDesk(playerid) == HELPDESK_CITYHALL; } // Administration Building
IsAtCopFrontDesk(playerid)     { return IsAtFrontDesk(playerid) == HELPDESK_SAPD; }     // SAPD HQ


// /ringbell - calls the faction from its help desk.
CMD:ringbell(playerid)
{
    new desk = IsAtFrontDesk(playerid);
    if (desk == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only do this at a faction helpdesk.");

    new facid   = FacHelpDesk[desk][E_HELPDESK_FACTION];
    new factype = FacHelpDesk[desk][E_HELPDESK_FACTYPE];

    if (FacHelpDesk[desk][E_HELPDESK_LAST_CALLED] && gettime() - FacHelpDesk[desk][E_HELPDESK_LAST_CALLED] < 900)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This reception bell has already been rung recently, try again later.");

    new str[144];
    format(str, sizeof(str), "[%s]: (%d) %s has rung the bell to request help.",
        FacHelpDesk[desk][E_HELPDESK_NAME], playerid, ReturnRPName(playerid));
    FacHelpDesk[desk][E_HELPDESK_LAST_CALLED] = gettime();

    foreach(new policeid: Player)
    {
        if (Character[policeid][E_CHARACTER_FACTIONID])
        {
            new faction_enum_id = Faction_GetEnumID(Character[policeid][E_CHARACTER_FACTIONID]);
            if (faction_enum_id != INVALID_FACTION_ID)
            {
                if (Faction[faction_enum_id][E_FACTION_ID] == facid || Faction[faction_enum_id][E_FACTION_TYPE] == factype)
                    SendClientMessage(policeid, COLOR_FACTION, str);
            }
        }
    }

    PlayerPlaySoundEx(playerid, 17802);
    ProxDetectorEx(playerid, 30.0, COLOR_ACTION, "*",
        sprintf("rings the %s bell.", FacHelpDesk[desk][E_HELPDESK_NAME]), .annonated=true);
    return true;
}

// /prisoners - lists prisoners and their remaining time (law enforcement at a desk).
CMD:prisoners(playerid, params[])
{
    if (!IsAtCopFrontDesk(playerid)
        && !IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true)
        && GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_BLUE, "Error", "A3A3A3", "You can only view the list of prisoners at the front desk of a police station.");

    new string[160];
    new count = 0;

    SendClientMessage(playerid, COLOR_BLUE, "List of prisoners:");

    foreach(new targetid: Player)
    {
        if (!Character[targetid][E_CHARACTER_ARREST_TIME] && !Character[targetid][E_CHARACTER_JFL]) continue;

        new cellStr[16];
        if (Character[targetid][E_CHARACTER_ARREST_CELL][0] != EOS)
            format(cellStr, sizeof(cellStr), " [Cell: %s]", Character[targetid][E_CHARACTER_ARREST_CELL]);
        else
            format(cellStr, sizeof(cellStr), " [Cell: N/A]");

        if (Character[targetid][E_CHARACTER_JFL])
            format(string, sizeof(string), "(%d) %s - [LIFE SENTENCE]%s", targetid, ReturnSettingsName(targetid, playerid), cellStr);
        else if (Character[targetid][E_CHARACTER_ARREST_TIME] == ARREST_TIME_AWAITING_RELEASE)
            format(string, sizeof(string), "(%d) %s - Sentence served, awaiting /releaseme.%s", targetid, ReturnSettingsName(targetid, playerid), cellStr);
        else
            format(string, sizeof(string), "(%d) %s - %d minute(s) remaining.%s", targetid, ReturnSettingsName(targetid, playerid), Character[targetid][E_CHARACTER_ARREST_TIME] / 60, cellStr);

        SendClientMessage(playerid, 0xDEDEDEFF, string);
        count++;
    }

    if (!count)
        SendClientMessage(playerid, 0xA3A3A3FF, "There are no prisoners currently.");

    return true;
}

// /jailtime - shows how much jail time you have left.
CMD:jailtime(playerid)
{
    if (Character[playerid][E_CHARACTER_JFL])
    {
        GameTextForPlayer(playerid, "~w~~n~~n~~n~~n~~n~~n~Jail Time: ~r~Life Sentence", 3000, 3);
    }
    else if (Character[playerid][E_CHARACTER_ARREST_TIME])
    {
        if (Character[playerid][E_CHARACTER_ARREST_TIME] == ARREST_TIME_AWAITING_RELEASE)
            GameTextForPlayer(playerid, "~w~~n~~n~~n~~n~~n~~n~Jail Time: ~g~Served", 3000, 3);
        else
            GameTextForPlayer(playerid, sprintf("~w~~n~~n~~n~~n~~n~~n~Jail Time: ~r~%d minutes", Character[playerid][E_CHARACTER_ARREST_TIME] / 60), 3000, 3);
    }
    return 1;
}

// /releaseme - starts the release timer after serving your sentence.
CMD:releaseme(playerid)
{
    if (Character[playerid][E_CHARACTER_JFL])
        return SendServerMessage(playerid, COLOR_ERROR, "Arrest", "A3A3A3", "You are serving a life sentence and cannot be released.");

    if (PlayerVar[playerid][E_PLAYER_RELEASEME_TICK])
        return SendClientMessage(playerid, COLOR_ERROR, "You're already being released. Wait for the timer to end.");

    if (!IsPlayerSpawned(playerid))
        return SendClientMessage(playerid, COLOR_ERROR, "You can only do this command whilst you are spawned.");

    if (Character[playerid][E_CHARACTER_ARREST_TIME] > 0)
        return SendServerMessage(playerid, COLOR_ERROR, "Arrest", "A3A3A3", "Your jail time is not up yet.");

    if (Character[playerid][E_CHARACTER_ARREST_TIME] != ARREST_TIME_AWAITING_RELEASE)
        return SendServerMessage(playerid, COLOR_ERROR, "Arrest", "A3A3A3", "You are not waiting to be released from jail.");

    SendClientMessage(playerid, COLOR_BLUE, "Release timer started: if you take damage during this time the timer will be cancelled.");

    JT_RemovePlayerFromVehicle(playerid);
    TogglePlayerControllable(playerid, false);
    SetPlayerArmedWeapon(playerid, 0);

    PlayerVar[playerid][E_PLAYER_RELEASEME_TICK] = 10;
    PlayerVar[playerid][E_PLAYER_RELEASEME_DMG]  = false;
    defer OnPlayerReleaseMe(playerid);
    return true;
}

// Timer: counts down the release; cancelled if the player is hurt or tabs out.
timer OnPlayerReleaseMe[1000](playerid)
{
    new string[144];

    if (!IsPlayerConnected(playerid))
        return true;

    if (IsPlayerPaused(playerid))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "You can't tab out while using /releaseme! You must remain ingame to avoid desync.");
        Arrest_ResetReleaseTimer(playerid);
        return true;
    }

    if (PlayerVar[playerid][E_PLAYER_RELEASEME_DMG])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "You've taken damage whilst being released. Timer cancelled.");
        Arrest_ResetReleaseTimer(playerid);
        return true;
    }

    if (Character[playerid][E_CHARACTER_ARREST_TIME] != ARREST_TIME_AWAITING_RELEASE)
    {
        Arrest_ResetReleaseTimer(playerid);
        return true;
    }

    if (--PlayerVar[playerid][E_PLAYER_RELEASEME_TICK] <= 0)
    {
        Arrest_ResetReleaseTimer(playerid);
        Arrest_ReleasePlayer(playerid);
        return true;
    }

    format(string, sizeof(string), "~w~~n~~n~~n~~n~~n~~n~Release Timer: ~n~~b~%d seconds left", PlayerVar[playerid][E_PLAYER_RELEASEME_TICK]);
    GameTextForPlayer(playerid, string, 950, 3);

    defer OnPlayerReleaseMe(playerid);
    return true;
}

// /unjail [player] - (law enforcement/staff) releases a prisoner early.
CMD:unjail(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR && !IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true))
        return SendClientMessage(playerid, COLOR_ERROR, "You don't have permission to use this command.");

    new targetid;
    if (sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_ERROR, "Usage: /unjail [playerid/name]");

    if (!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_ERROR, "That player is not connected.");

    if (!IsPlayerSpawned(targetid))
        return SendClientMessage(playerid, COLOR_ERROR, "That player is not spawned.");

    if (Character[targetid][E_CHARACTER_JFL])
        return SendServerMessage(playerid, COLOR_ERROR, "Arrest", "A3A3A3", "That player is serving a life sentence and cannot be released.");

    if (!Character[targetid][E_CHARACTER_ARREST_TIME])
        return SendServerMessage(playerid, COLOR_ERROR, "Arrest", "A3A3A3", "That player is not in jail.");

    if (PlayerVar[targetid][E_PLAYER_RELEASEME_TICK])
        Arrest_ResetReleaseTimer(targetid);

    new string[144];

    format(string, sizeof(string), "You have been released from jail by %s.", ReturnRPName(playerid));
    SendClientMessage(targetid, COLOR_BLUE, string);

    format(string, sizeof(string), "You have released %s from jail.", ReturnRPName(targetid));
    SendClientMessage(playerid, COLOR_BLUE, string);

    Arrest_ReleasePlayer(targetid);
    return true;
}

// /setcell [player] [cell] - assigns a prisoner to a cell (for example A01).
CMD:setcell(playerid, params[])
{
    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true) && GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement.");

    new targetid, cellName[4];
    if (sscanf(params, "k<player>s[4]", targetid, cellName))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setcell [playerid] [cell] (e.g. A01, B12)");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player isn't connected.");

    if (!Character[targetid][E_CHARACTER_ARREST_TIME] && !Character[targetid][E_CHARACTER_JFL])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is not currently imprisoned.");

    new cellIndex = -1;
    for (new i = 0; i < JailSpawnCount; i++)
    {
        if (!strcmp(JailSpawns[i][JAIL_CELL], cellName, true))
        {
            cellIndex = i;
            break;
        }
    }

    if (cellIndex == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid cell name. Use a valid cell (e.g. A01, B12).");

    new Float:x = JailSpawns[cellIndex][JAIL_X];
    new Float:y = JailSpawns[cellIndex][JAIL_Y];
    new Float:z = JailSpawns[cellIndex][JAIL_Z];

    Character[targetid][E_CHARACTER_ARREST_X]   = x;
    Character[targetid][E_CHARACTER_ARREST_Y]   = y;
    Character[targetid][E_CHARACTER_ARREST_Z]   = z;
    Character[targetid][E_CHARACTER_ARREST_VW]  = JailSpawns[cellIndex][JAIL_WORLD];
    Character[targetid][E_CHARACTER_ARREST_INT] = JailSpawns[cellIndex][JAIL_INTERIOR];
    strcopy(Character[targetid][E_CHARACTER_ARREST_CELL], JailSpawns[cellIndex][JAIL_CELL], 4);

    SetPlayerVirtualWorld(targetid, JailSpawns[cellIndex][JAIL_WORLD]);
    SetPlayerInterior(targetid, JailSpawns[cellIndex][JAIL_INTERIOR]);
    SetPlayerPos(targetid, x, y, z);
    SetPlayerFacingAngle(targetid, JailSpawns[cellIndex][JAIL_A]);

    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_arrest_x = '%f', player_arrest_y = '%f', player_arrest_z = '%f', \
        player_arrest_vw = %d, player_arrest_int = %d, player_arrest_cell = '%e' WHERE player_id = %d",
        x, y, z, JailSpawns[cellIndex][JAIL_WORLD], JailSpawns[cellIndex][JAIL_INTERIOR],
        Character[targetid][E_CHARACTER_ARREST_CELL],
        Character[targetid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    SendClientMessage(playerid, COLOR_BLUE,  sprintf("You've moved (%d) %s to cell %s.", targetid, ReturnRPName(targetid), cellName));
    SendClientMessage(targetid, COLOR_ERROR, sprintf("Officer (%d) %s has moved you to cell %s.", playerid, ReturnRPName(playerid), cellName));
    return true;
}

// /arrest [player] [minutes] - law enforcement arrests a cuffed suspect and moves them to a cell.
CMD:arrest(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    new targetid, time;
    new factionid       = Character[playerid][E_CHARACTER_FACTIONID];
    new faction_enum_id = Faction_GetEnumID(factionid);

    if (sscanf(params, "k<player>i", targetid, time))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/arrest [targetid] [time (in minutes)]");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your target isn't connected.");

    if (!IsPlayerNearPlayer(playerid, targetid, 10.0))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near this player.");

    if (!PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] || GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
    {
        if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true))
            return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement.");

        if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not a high enough tier of employee to do this.");

        if (time < 10)       return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "You can't arrest someone for less than 10 minutes.");
        else if (time > 300) return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "You can't arrest someone for more than 3 hours (180 minutes).");

        if (targetid == playerid)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't arrest yourself.");
    }

    new Float:x, Float:y, Float:z;
    //new vw       = GetPlayerVirtualWorld(targetid);
    //new interior = GetPlayerInterior(targetid);
    new query[1024];

    /*if (time > 15)
    {
        new rand = random(JailSpawnCount);

        strcopy(Character[targetid][E_CHARACTER_ARREST_CELL], JailSpawns[rand][JAIL_CELL], 4);
        
        x = JailSpawns[rand][JAIL_X];
        y = JailSpawns[rand][JAIL_Y];
        z = JailSpawns[rand][JAIL_Z];
        vw       = JailSpawns[rand][JAIL_WORLD];
        interior = JailSpawns[rand][JAIL_INTERIOR];

        SetPlayerVirtualWorld(targetid, vw);
        SetPlayerInterior(targetid, interior);
        ORP_SetPosWithFade(targetid, x, y, z, sprintf("Prison Cell %s", Character[targetid][E_CHARACTER_ARREST_CELL]));
        SetPlayerFacingAngle(targetid, JailSpawns[rand][JAIL_A]);

        if (Character[targetid][E_CHARACTER_ARREST_TIME] <= 0)
        {
            Character[targetid][E_CHARACTER_SKIN_BEFORE] = GetPlayerSkin(targetid);
            mysql_format(mysql, query, sizeof(query),
                "UPDATE characters SET player_skin_before = %d WHERE player_id = %d",
                Character[targetid][E_CHARACTER_SKIN_BEFORE], Character[targetid][E_CHARACTER_ID]);
            mysql_tquery(mysql, query);
        }

        new skin;
        if (Character[targetid][E_CHARACTER_ATTRIB_SEX] == E_ATTRIBUTE_SEX_FEMALE)
            skin = PrisonSkinsFemale[random(sizeof(PrisonSkinsFemale))];
        else
            skin = PrisonSkinsMale[random(sizeof(PrisonSkinsMale))];

        SetPlayerSkinEx(targetid, skin);
        Character[targetid][E_CHARACTER_SKINID] = skin;
    }
    else
    {
        GetPlayerPos(targetid, x, y, z);
        Character[targetid][E_CHARACTER_ARREST_CELL][0] = EOS;
    }*/

    GetPlayerPos(targetid, x, y, z);
    Character[targetid][E_CHARACTER_ARREST_CELL][0] = EOS;

    if (PlayerVar[targetid][E_PLAYER_RELEASEME_TICK])
        Arrest_ResetReleaseTimer(targetid);

    Character[targetid][E_CHARACTER_ARREST_TIME] = time * 60;
    Character[targetid][E_CHARACTER_LAWYER_USED] = 0; // fresh sentence - eligible for a lawyer again
    Character[targetid][E_CHARACTER_ARREST_X]    = x;
    Character[targetid][E_CHARACTER_ARREST_Y]    = y;
    Character[targetid][E_CHARACTER_ARREST_Z]    = z;
    Character[targetid][E_CHARACTER_ARREST_VW]   = GetPlayerVirtualWorld(targetid);
    Character[targetid][E_CHARACTER_ARREST_INT]  = GetPlayerInterior(targetid);

    Weapon_ResetPlayerWeapons(targetid);
    SendServerMessage(targetid, COLOR_FACTION, "Arrest", "A3A3A3",
        sprintf("You have been imprisoned for %d minutes by %s %s (%d).",
            time, Character[playerid][E_CHARACTER_FACTIONRANK], ReturnRPName(playerid), playerid));
    Weapon_SavePlayerWeapons(targetid);

    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_arrest_x = '%f', player_arrest_y = '%f', player_arrest_z = '%f', \
        player_arrest_vw = %d, player_arrest_int = %d, player_arrest_time = %d, player_arrest_cell = '%e', player_lawyer_used = 0 WHERE player_id = %d",
        Character[targetid][E_CHARACTER_ARREST_X], Character[targetid][E_CHARACTER_ARREST_Y],
        Character[targetid][E_CHARACTER_ARREST_Z], Character[targetid][E_CHARACTER_ARREST_VW],
        Character[targetid][E_CHARACTER_ARREST_INT], Character[targetid][E_CHARACTER_ARREST_TIME],
        Character[targetid][E_CHARACTER_ARREST_CELL],
        Character[targetid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    new days = 259200;
    mysql_format(mysql, query, sizeof(query),
        "UPDATE `criminalfines` SET `fine_status` = 2, `fine_revoker` = 'The System' \
        WHERE `fine_status` = 0 AND `fine_player_name` LIKE '%e' \
        AND DATE_ADD(`fine_date`, INTERVAL %d second) < CURRENT_TIMESTAMP",
        Character[targetid][E_CHARACTER_NAME], days);

    inline Ticket_OnAutoRevoke()
    {
        new affected = cache_affected_rows();
        if (affected)
        {
            SendClientMessage(targetid, 0xA3A3A3FF, sprintf("The %d ticket(s) that you failed to pay in time were automatically revoked.", affected));
            SendClientMessage(playerid, 0xA3A3A3FF, sprintf("The %d ticket(s) that they failed to pay in time were automatically revoked.", affected));
        }
    }
    MySQL_TQueryInline(mysql, using inline Ticket_OnAutoRevoke, query, "");

    Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has arrested (%d) %s for %d minutes (%d seconds). }",
        Faction[faction_enum_id][E_FACTION_ABBREV],
        playerid, ReturnRPName(playerid),
        targetid, ReturnRPName(targetid),
        time, time * 60), faction_enum_id, false);

    if (faction_enum_id != -1)
        Faction_AddBankMoney(faction_enum_id, 2500, "Suspect Arrested");

    SendClientMessage(targetid, 0xA3A3A3FF, "Type \"/jailtime\" to see how long you have left in jail.");
    return true;
}

// /setarrestpos [player] - sets the place where someone is booked.
CMD:setarrestpos(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement.");

    new targetid;
    if (sscanf(params, "k<player>", targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setarrestpos [targetid]");

    if (targetid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't arrest yourself.");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your target isn't connected.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);

    Character[targetid][E_CHARACTER_ARREST_X]   = x;
    Character[targetid][E_CHARACTER_ARREST_Y]   = y;
    Character[targetid][E_CHARACTER_ARREST_Z]   = z;
    Character[targetid][E_CHARACTER_ARREST_VW]  = GetPlayerVirtualWorld(targetid);
    Character[targetid][E_CHARACTER_ARREST_INT] = GetPlayerInterior(targetid);

    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_arrest_x = '%f', player_arrest_y = '%f', player_arrest_z = '%f', \
        player_arrest_vw = %d, player_arrest_int = %d WHERE player_id = %d",
        Character[targetid][E_CHARACTER_ARREST_X], Character[targetid][E_CHARACTER_ARREST_Y],
        Character[targetid][E_CHARACTER_ARREST_Z], Character[targetid][E_CHARACTER_ARREST_VW],
        Character[targetid][E_CHARACTER_ARREST_INT], Character[targetid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    SendClientMessage(playerid, COLOR_BLUE,  sprintf("You've updated the arrest spawn location of (%d) %s.", targetid, ReturnSettingsName(targetid, playerid)));
    SendClientMessage(targetid, COLOR_ERROR, sprintf("Officer (%d) %s has updated your arrest spawn location.", playerid, ReturnSettingsName(playerid, targetid)));
    return true;
}

// Called every second: counts down a prisoner's jail time.
Arrest_Tick(playerid)
{
    if (Character[playerid][E_CHARACTER_JFL]) return;

    if (Character[playerid][E_CHARACTER_ARREST_TIME] > 0)
    {
        if (--Character[playerid][E_CHARACTER_ARREST_TIME] <= 0)
        {
            new query[256];
            Character[playerid][E_CHARACTER_ARREST_TIME] = ARREST_TIME_AWAITING_RELEASE;
            mysql_format(mysql, query, sizeof(query),
                "UPDATE characters SET player_arrest_time = %d WHERE player_id = %d",
                ARREST_TIME_AWAITING_RELEASE, Character[playerid][E_CHARACTER_ID]);
            mysql_tquery(mysql, query);

            SendServerMessage(playerid, COLOR_BLUE, "Arrest", "A3A3A3", "Your jail time is up. Type /releaseme to be released from jail.");
        }
    }
}

// Spawn handler used when a player logs in while jailed: puts them back in their cell.
Spawn_ArrestJail(playerid, bool:isrespawn)
{
    #pragma unused isrespawn

    SetSpawnInfo(playerid, 0, 264,
        Character[playerid][E_CHARACTER_ARREST_X], Character[playerid][E_CHARACTER_ARREST_Y],
        Character[playerid][E_CHARACTER_ARREST_Z], 0.0, 0, 0, 0, 0, 0, 0);

    CS_SpawnPlayer(playerid);
    SetCameraBehindPlayer(playerid);

    SetPlayerVirtualWorld(playerid, Character[playerid][E_CHARACTER_ARREST_VW]);
    SetPlayerInterior(playerid,     Character[playerid][E_CHARACTER_ARREST_INT]);
    SetPlayerHealth(playerid,       Character[playerid][E_CHARACTER_HEALTH]);

    ORP_SetPosWithFade(playerid,
        Character[playerid][E_CHARACTER_ARREST_X],
        Character[playerid][E_CHARACTER_ARREST_Y],
        Character[playerid][E_CHARACTER_ARREST_Z]);

    SendServerMessage(playerid, COLOR_BLUE, "Arrest", "A3A3A3", "You've been returned back to your cell.");
    Weapon_SavePlayerWeapons(playerid);
    Attach_LoadPlayerEntities(playerid);

    if (Character[playerid][E_CHARACTER_JFL])
        SendClientMessage(playerid, 0xA3A3A3FF, "You are serving a life sentence. There is no release.");
    else if (Character[playerid][E_CHARACTER_ARREST_TIME] == ARREST_TIME_AWAITING_RELEASE)
        SendClientMessage(playerid, 0xA3A3A3FF, "Your jail time is up. Type \"/releaseme\" to start your release timer.");
    else
        SendClientMessage(playerid, 0xA3A3A3FF, "Type \"/jailtime\" to see how long you have left in jail.");

    return true;
}

// /arrestme [minutes] - arrests yourself (a staff testing tool).
CMD:arrestme(playerid, params[])
{
    if(!JailSpawnCount) return SendClientMessage(playerid,COLOR_ERROR,"Enable at least one prison cell in the ACP first.");
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to use this command.");

    new time = 60;
    if (!isnull(params)) sscanf(params, "i", time);
    if (time < 1)   time = 1;
    if (time > 999) time = 999;

    Character[playerid][E_CHARACTER_SKIN_BEFORE] = GetPlayerSkin(playerid);

    new skin;
    if (Character[playerid][E_CHARACTER_ATTRIB_SEX] == E_ATTRIBUTE_SEX_FEMALE)
        skin = PrisonSkinsFemale[random(sizeof(PrisonSkinsFemale))];
    else
        skin = PrisonSkinsMale[random(sizeof(PrisonSkinsMale))];

    new rand    = random(JailSpawnCount);
    new Float:x = JailSpawns[rand][JAIL_X];
    new Float:y = JailSpawns[rand][JAIL_Y];
    new Float:z = JailSpawns[rand][JAIL_Z];

    SetPlayerSkinEx(playerid, skin);
    Character[playerid][E_CHARACTER_SKINID]      = skin;
    Character[playerid][E_CHARACTER_ARREST_TIME] = time * 60;
    Character[playerid][E_CHARACTER_ARREST_X]    = x;
    Character[playerid][E_CHARACTER_ARREST_Y]    = y;
    Character[playerid][E_CHARACTER_ARREST_Z]    = z;
    Character[playerid][E_CHARACTER_ARREST_VW]   = JailSpawns[rand][JAIL_WORLD];
    Character[playerid][E_CHARACTER_ARREST_INT]  = JailSpawns[rand][JAIL_INTERIOR];
    strcopy(Character[playerid][E_CHARACTER_ARREST_CELL], JailSpawns[rand][JAIL_CELL], 4);

    
    SetPlayerVirtualWorld(playerid, JailSpawns[rand][JAIL_WORLD]);
    SetPlayerInterior(playerid, JailSpawns[rand][JAIL_INTERIOR]);
    ORP_SetPosWithFade(playerid, x, y, z, sprintf("Prison Cell %s", Character[playerid][E_CHARACTER_ARREST_CELL]));
    SetPlayerFacingAngle(playerid, JailSpawns[rand][JAIL_A]);

    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_skin_before = %d, player_arrest_x = '%f', player_arrest_y = '%f', player_arrest_z = '%f', \
        player_arrest_vw = %d, player_arrest_int = %d, player_arrest_time = %d, player_arrest_cell = '%e' WHERE player_id = %d",
        Character[playerid][E_CHARACTER_SKIN_BEFORE],
        x, y, z, JailSpawns[rand][JAIL_WORLD], JailSpawns[rand][JAIL_INTERIOR],
        Character[playerid][E_CHARACTER_ARREST_TIME],
        Character[playerid][E_CHARACTER_ARREST_CELL],
        Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    Weapon_ResetPlayerWeapons(playerid);
    Weapon_SavePlayerWeapons(playerid);

    SendServerMessage(playerid, COLOR_FACTION, "Arrest", "A3A3A3", sprintf("[TEST] You've self-arrested for %d minutes. Use /clockin at the podium.", time));
    SendClientMessage(playerid, 0xA3A3A3FF, "Type \"/jailtime\" to see how long you have left.");
    return true;
}

// Asks a player to confirm a Jail For Life request.
static PlayerJailForLife(playerid, const error[] = EOS)
{
    inline PlayerJailForLifeDlg(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, listitem

        if (!response) return true;

        new reason[128];
        format(reason, sizeof(reason), "%s", inputtext);

        if (!strlen(reason))
            return PlayerJailForLife(playerid, "You must provide a reason for your request.");

        format(PlayerVar[playerid][E_PLAYER_JFL_REASON], 128, "%s", reason);
        PlayerVar[playerid][E_PLAYER_JFL_REQUEST] = 1;

        new msg[256];
        format(msg, sizeof(msg),
            "{5984BD}[JFL] (%d) %s has requested a jail-for-life sentence for their own character - Reason: %s",
            playerid, Character[playerid][E_CHARACTER_NAME], reason);
        SendAdminMessage(msg);

        format(msg, sizeof(msg), "{5984BD}To confirm or deny, type {E8EBF0}/processjfl %d [accept/deny]", playerid);
        SendAdminMessage(msg);

        SendServerMessage(playerid, COLOR_BLUE, "Jail For Life", "A3A3A3",
            "Your request has been submitted. A general admin will review it. This action is permanent and irreversible.");
        return true;
    }

    new dlgstr[640];
    format(dlgstr, sizeof(dlgstr),
        "{FFFFFF}You are requesting a {AA3333}Jail For Life{FFFFFF} sentence for your character:\n\n{ADBEE6}Character: {FFFFFF}%s\n\n{FF4444}[!!!] {FFFFFF}This is {AA3333}permanent and completely irreversible{FFFFFF}.\n{FFFFFF}Your character will be locked in prison forever with no possibility of release.\n\n", Character[playerid][E_CHARACTER_NAME]);

    if (strlen(error))
        format(dlgstr, sizeof(dlgstr), "%s{FF0000}%s\n\n", dlgstr, error);

    strcat(dlgstr, "{FFFFFF}Enter your reason for this request and press {AA3333}OK{FFFFFF} to submit.");
    strcat(dlgstr, "\n{ADBEE6}A general admin must approve this before it takes effect.");

    Dialog_ShowCallback(playerid, using inline PlayerJailForLifeDlg, DIALOG_STYLE_INPUT,
        "Jail For Life - Reason Required", dlgstr, "Submit", "Cancel");
    return true;
}

// Applies a Jail For Life sentence: puts the prisoner in a random cell.
static Arrest_ApplyJailForLife(playerid)
{
    if(!JailSpawnCount) return 0;
    new rand    = random(JailSpawnCount);
    new Float:x = JailSpawns[rand][JAIL_X];
    new Float:y = JailSpawns[rand][JAIL_Y];
    new Float:z = JailSpawns[rand][JAIL_Z];

    Character[playerid][E_CHARACTER_ARREST_TIME] = ARREST_TIME_AWAITING_RELEASE;
    Character[playerid][E_CHARACTER_ARREST_X]    = x;
    Character[playerid][E_CHARACTER_ARREST_Y]    = y;
    Character[playerid][E_CHARACTER_ARREST_Z]    = z;
    Character[playerid][E_CHARACTER_ARREST_VW]   = JailSpawns[rand][JAIL_WORLD];
    Character[playerid][E_CHARACTER_ARREST_INT]  = JailSpawns[rand][JAIL_INTERIOR];
    Character[playerid][E_CHARACTER_JFL]         = 1;
    strcopy(Character[playerid][E_CHARACTER_ARREST_CELL], JailSpawns[rand][JAIL_CELL], 4);

    if (!Character[playerid][E_CHARACTER_SKIN_BEFORE])
        Character[playerid][E_CHARACTER_SKIN_BEFORE] = GetPlayerSkin(playerid);

    new skin;
    if (Character[playerid][E_CHARACTER_ATTRIB_SEX] == E_ATTRIBUTE_SEX_FEMALE)
        skin = PrisonSkinsFemale[random(sizeof(PrisonSkinsFemale))];
    else
        skin = PrisonSkinsMale[random(sizeof(PrisonSkinsMale))];

    SetPlayerSkinEx(playerid, skin);
    Character[playerid][E_CHARACTER_SKINID] = skin;

    SetPlayerVirtualWorld(playerid, JailSpawns[rand][JAIL_WORLD]);
    SetPlayerInterior(playerid, JailSpawns[rand][JAIL_INTERIOR]);
    ORP_SetPosWithFade(playerid, x, y, z, sprintf("Prison Cell %s", Character[playerid][E_CHARACTER_ARREST_CELL]));
    SetPlayerFacingAngle(playerid, JailSpawns[rand][JAIL_A]);

    Weapon_ResetPlayerWeapons(playerid);
    Weapon_SavePlayerWeapons(playerid);

    new query[640];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_arrest_x = '%f', player_arrest_y = '%f', player_arrest_z = '%f', \
        player_arrest_vw = %d, player_arrest_int = %d, player_arrest_time = %d, \
        player_arrest_cell = '%e', player_skin_before = %d, player_skinid = %d, player_jfl = %d WHERE player_id = %d",
        x, y, z, JailSpawns[rand][JAIL_WORLD], JailSpawns[rand][JAIL_INTERIOR],
        ARREST_TIME_AWAITING_RELEASE,
        Character[playerid][E_CHARACTER_ARREST_CELL],
        Character[playerid][E_CHARACTER_SKIN_BEFORE],
        skin,
        Character[playerid][E_CHARACTER_JFL],
        Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);

    return true;
}

// /jailforlife - requests a permanent jail sentence for your own character.
CMD:jailforlife(playerid, params[])
{
    #pragma unused params

    if (!IsPlayerSpawned(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be spawned to use this command.");

    if (Character[playerid][E_CHARACTER_JFL])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your character is already serving a life sentence.");

    if (PlayerVar[playerid][E_PLAYER_JFL_REQUEST])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You already have a pending JFL request.");

    return PlayerJailForLife(playerid);
}

// /processjfl [player] [accept/deny] - (staff) approves or denies a Jail For Life request.
CMD:processjfl(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You need to be a general admin to process JFL requests.");

    new targetid, option[7], reason[64];
    if (sscanf(params, "k<player>s[7]S[64](0)", targetid, option, reason))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/processjfl [playerid] [accept/deny] [reason if denied]");

    if (!PlayerVar[targetid][E_PLAYER_JFL_REQUEST])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This player has no pending JFL request.");

    new query[256];

    if (!strcmp(option, "accept", true))
    {
        if(!JailSpawnCount) return SendClientMessage(playerid,COLOR_ERROR,"Enable at least one prison cell in the ACP first.");
        Arrest_ApplyJailForLife(targetid);
        PlayerVar[targetid][E_PLAYER_JFL_REQUEST]    = 0;
        PlayerVar[targetid][E_PLAYER_JFL_REASON][0]  = EOS;

        SendServerMessage(targetid, COLOR_ERROR, "Jail For Life", "A3A3A3",
            sprintf("Your jail-for-life sentence has been confirmed by (%d) %s. This is permanent.",
                playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME]));

        SendServerMessage(playerid, COLOR_BLUE, "Jail For Life", "A3A3A3",
            sprintf("You've confirmed the JFL sentence for (%d) %s.", targetid, Character[targetid][E_CHARACTER_NAME]));

        format(query, sizeof(query), "[JFL] (%d) %s ACCEPTED JFL for (%d) %s - Reason: %s",
            playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME],
            targetid, Character[targetid][E_CHARACTER_NAME],
            PlayerVar[targetid][E_PLAYER_JFL_REASON]);
        SendAdminMessage(query);

        AddLogEntry(targetid, LOG_TYPE_ADMIN_NC, sprintf("self-requested JAIL FOR LIFE - Accepted by %s - Reason: %s",
            Account[playerid][E_PLAYER_ACCOUNT_NAME], PlayerVar[targetid][E_PLAYER_JFL_REASON]));
    }
    else if (!strcmp(option, "deny", true))
    {
        new denyReason[64];
        format(denyReason, sizeof(denyReason), "%s", strlen(reason) ? reason : "No reason specified.");

        SendServerMessage(targetid, COLOR_BLUE, "Jail For Life", "A3A3A3",
            sprintf("Your JFL request was denied by (%d) %s: %s",
                playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], denyReason));

        SendServerMessage(playerid, COLOR_BLUE, "Jail For Life", "A3A3A3",
            sprintf("You've denied the JFL request for (%d) %s: %s",
                targetid, Character[targetid][E_CHARACTER_NAME], denyReason));

        format(query, sizeof(query), "[JFL] (%d) %s DENIED JFL for (%d) %s - Reason: %s",
            playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME],
            targetid, Character[targetid][E_CHARACTER_NAME], denyReason);
        SendAdminMessage(query);

        PlayerVar[targetid][E_PLAYER_JFL_REQUEST]   = 0;
        PlayerVar[targetid][E_PLAYER_JFL_REASON][0] = EOS;
    }
    else
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/processjfl [playerid] [accept/deny] [reason if denied]");
    }

    return true;
}

// /removejfl [player] [reason] - (staff) removes a Jail For Life sentence.
CMD:removejfl(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You need to be a general admin to remove a JFL sentence.");

    new targetid, reason[64];
    if (sscanf(params, "k<player>s[64]", targetid, reason))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/removejfl [playerid] [reason]");

    if (!Character[targetid][E_CHARACTER_JFL])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This player is not serving a jail-for-life sentence.");

    Arrest_ReleasePlayer(targetid);

    SendServerMessage(targetid, COLOR_BLUE, "Jail For Life", "A3A3A3",
        sprintf("Your jail-for-life sentence has been removed by (%d) %s. Reason: %s",
            playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason));

    SendServerMessage(playerid, COLOR_BLUE, "Jail For Life", "A3A3A3",
        sprintf("You've removed the JFL sentence for (%d) %s. Reason: %s",
            targetid, Character[targetid][E_CHARACTER_NAME], reason));

    new logMsg[256];
    format(logMsg, sizeof(logMsg), "[JFL] (%d) %s REMOVED JFL for (%d) %s - Reason: %s",
        playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME],
        targetid, Character[targetid][E_CHARACTER_NAME],
        reason);
    SendAdminMessage(logMsg);

    AddLogEntry(targetid, LOG_TYPE_ADMIN_NC, sprintf("JAIL FOR LIFE removed by %s - Reason: %s",
        Account[playerid][E_PLAYER_ACCOUNT_NAME], reason));

    return true;
}
