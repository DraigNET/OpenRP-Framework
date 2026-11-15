// ============================================================================
// File: jobs/boatyard/data.pwn
// Freight transport (boatyard) job data and payout. Disabled by default - uncomment the include
// in jobs/header.pwn to use it.
// ============================================================================

#define FTJ_STAGE_NONE      0
#define FTJ_STAGE_TO_LV     1
#define FTJ_STAGE_RETURN_LS 2

#define FTJ_LS_POS_X        (0.0) // TODO: set coordinates for your map
#define FTJ_LS_POS_Y        (0.0) // TODO: set coordinates for your map
#define FTJ_LS_POS_Z        (0.0) // TODO: set coordinates for your map
#define FTJ_LS_RADIUS       250.0

#define FTJ_FREIGHT_CUT_DIV 10

enum E_FTJ_DEST { Float:E_FTJ_X, Float:E_FTJ_Y, Float:E_FTJ_Z, Float:E_FTJ_R }

static const FTJ_Destinations[][E_FTJ_DEST] = {
    {-1608.89,  226.67,  0.5, 8.0},
    {-2953.33,  520.00,  0.5, 8.0},
    {-2361.31,  2226.11, 0.5, 8.0}
};

// Resets the freight job state when a player connects.
FTJ_OnPlayerConnect(playerid) {
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB] = false;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_STAGE] = FTJ_STAGE_NONE;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE] = INVALID_VEHICLE_ID;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA] = -1;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_DEST] = -1;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_COUNT] = 0;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_TIMEOUT] = 0;
    return 1;
}

// Destroys the checkpoint areas used during the freight job.
static FTJ_CleanAreas(playerid) {
    if (IsValidDynamicArea(PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA])) {
        DestroyDynamicArea(PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA]);
        PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA] = -1;
    }
}

// Picks a random destination for the next freight delivery.
FTJ_SetStageLV(playerid) {
    FTJ_CleanAreas(playerid);
    new dest = random(sizeof(FTJ_Destinations));
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_DEST] = dest;
    GPS_MarkLocation(playerid, "Deliver the ~g~cargo~w~ to the Marked Port.", E_GPS_COLOR_JOB, FTJ_Destinations[dest][E_FTJ_X], FTJ_Destinations[dest][E_FTJ_Y], FTJ_Destinations[dest][E_FTJ_Z]);
    ShowPlayerInfoMessage(playerid, "Navigate to the ~g~Marked Port~w~ and sail into the delivery area to drop off the cargo.", .height = 167.5, .width = 200, .showtime = 7000);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA] = CreateDynamicCircle(FTJ_Destinations[dest][E_FTJ_X], FTJ_Destinations[dest][E_FTJ_Y], FTJ_Destinations[dest][E_FTJ_R], -1, -1, playerid);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_STAGE] = FTJ_STAGE_TO_LV;
}

// Sets the return leg: sail back to the yard to be paid.
FTJ_SetStageReturn(playerid) {
    FTJ_CleanAreas(playerid);
    GPS_MarkLocation(playerid, "Return to the ~g~LS Freighter Yard~w~ to collect your payout.", E_GPS_COLOR_JOB, FTJ_LS_POS_X, FTJ_LS_POS_Y, FTJ_LS_POS_Z);
    ShowPlayerInfoMessage(playerid, "Cargo delivered! Sail back to the ~g~LS Freighter Yard~w~ to collect your payout.", .height = 167.5, .width = 200, .showtime = 7000);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA] = CreateDynamicCircle(FTJ_LS_POS_X, FTJ_LS_POS_Y, FTJ_LS_RADIUS, -1, -1, playerid);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_STAGE] = FTJ_STAGE_RETURN_LS;
}
// Pays the player for a delivery based on distance.
FTJ_Payout(playerid) {
    if (!PlayerVar[playerid][E_PLAYER_BOATYARDJOB]) return false;

    new dest = PlayerVar[playerid][E_PLAYER_BOATYARDJOB_DEST];
    new Float:dist = GetPlayerDistanceFromPoint(playerid, FTJ_Destinations[dest][E_FTJ_X], FTJ_Destinations[dest][E_FTJ_Y], FTJ_Destinations[dest][E_FTJ_Z]);
    new Float:ratio = dist / 5500.0;
    if (ratio > 1.0) ratio = 1.0;

    new payout = 5000 + floatround(ratio * 1500.0) + random(501);
    new freightCut = payout / FTJ_FREIGHT_CUT_DIV;
    new playerPayout = payout - freightCut;

    if (DockEntity[DOCK_ENTITY_FREIGHTER][E_DOCK_FACTION_ID] != -1) {
        DockEntity[DOCK_ENTITY_FREIGHTER][E_DOCK_BANK] += freightCut;
        new query[256];
        mysql_format(mysql, query, sizeof(query), "UPDATE dock_entities SET entity_bank = %d WHERE entity_slot = %d", DockEntity[DOCK_ENTITY_FREIGHTER][E_DOCK_BANK], DOCK_ENTITY_FREIGHTER);
        mysql_tquery(mysql, query);
        DockEntity_AddMission(DOCK_ENTITY_FREIGHTER);
    }

    // 15 mins cooldown
    new cooldownEnd = gettime() + (15 * 60);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_TIMEOUT] = cooldownEnd;
    new query2[256];
    mysql_format(mysql, query2, sizeof(query2), "UPDATE characters SET ftj_cooldown = %d WHERE character_id = %d", cooldownEnd, Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query2);


#if defined FEATURE_FNR
    GameTextForPlayer(playerid, sprintf("~y~Delivery complete~n~~w~$%s~n~~w~Respect +", IntegerWithDelimiter(playerPayout)), 3500, 6);
#else
    GameTextForPlayer(playerid, sprintf("~y~Delivery complete~n~~w~$%s", IntegerWithDelimiter(playerPayout)), 3500, 6);
#endif
    GivePlayerCash(playerid, playerPayout, "Freight transport job payout");
    GiveFnRPoints(playerid, 1, "Freight transport job");
    AddLogEntry(playerid, LOG_TYPE_JOB, sprintf(" earned %i from freight transport job (freight cut: %i).", playerPayout, freightCut));
    ShowPlayerInfoMessage(playerid, "Job complete! Use ~g~/freighttransport~w~ again to run another haul.", .height = 167.5, .width = 200, .showtime = 7000);
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_COUNT]++;
    return true;
}

// Handles the player reaching a destination or the yard.
FTJ_OnPlayerEnterArea(playerid, STREAMER_TAG_AREA:areaid) {
    if (!PlayerVar[playerid][E_PLAYER_BOATYARDJOB]) return 0;
    if (areaid != PlayerVar[playerid][E_PLAYER_BOATYARDJOB_AREA]) return 0;
    if (GetPlayerVehicleID(playerid) != PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE]) return ShowPlayerInfoMessage(playerid, "You must be in your freight vessel to proceed!", .height = 167.5, .width = 180, .showtime = 5000), 0;

    switch (PlayerVar[playerid][E_PLAYER_BOATYARDJOB_STAGE]) {
        case FTJ_STAGE_TO_LV: FTJ_SetStageReturn(playerid);
        case FTJ_STAGE_RETURN_LS: { FTJ_CleanAreas(playerid); FTJ_Payout(playerid); FTJ_ResetPlayerState(playerid); }
    }
    return 1;
}

// Resets the freight job state.
FTJ_ResetPlayerState(playerid) {
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB] = false;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_STAGE] = FTJ_STAGE_NONE;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_DEST] = -1;
    FTJ_CleanAreas(playerid);
    if (IsValidVehicle(PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE])) {
        new veh_enum_id = Vehicle_GetEnumID(PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE]);
        SetEngineStatus(Vehicle[veh_enum_id][E_VEHICLE_ID], false);
        SetDoorStatus(Vehicle[veh_enum_id][E_VEHICLE_ID], false);
    }
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE] = INVALID_VEHICLE_ID;
    cmd_nocp(playerid);
}
