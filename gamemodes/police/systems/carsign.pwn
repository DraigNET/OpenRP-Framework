// ============================================================================
// File: police/systems/carsign.pwn
// Unit callsigns: /callsign sets your unit callsign, /carsign and /units show unit vehicles.
// Keeps the MDC unit list in sync with who is in which vehicle.
// Commands: /callsign /units /carsign
// ============================================================================

#include <YSI_Coding\y_hooks>

enum vehicle_plate_pos_enum
{
	vpp_veh_model,
	Float:vpp_x,
	Float:vpp_y,
	Float:vpp_z
}

enum E_MDC_UNIT
{
    bool:unit_active,
    unit_callsign[16],
    unit_factionid,
    unit_sql_id,

    Float:mdc_last_x,
    Float:mdc_last_y,
    Float:mdc_last_z,
    Float:mdc_last_angle,
    last_siren,

    unit_last_member_count,
    last_occupied_time
}

new VehicleUnitData[MAX_VEHICLES][E_MDC_UNIT];
static bool:g_mdcTimerStarted = false;

new vehicle_plate_pos[ ][ vehicle_plate_pos_enum ] ={
	{ 400 , -1.03 , -1.83 , -0.46 },	{ 401 , 1.08 , -1.87 , -0.11 },		{ 402 , -0.90 , -2.42 , -0.31 },	{ 404 , -0.92 , -2.45 , -0.15 },
	{ 405 , -0.96 , -2.76 , -0.20 },	{ 409 , -0.90 , -3.57 , -0.31 },	{ 410 , -0.97 , -1.67 , -0.01 },	{ 411 , -0.90 , -2.33 , -0.37 },
	{ 412 , -1.00 , -3.34 , -0.35 },	{ 413 , -0.93 , -2.64 , -0.32 },	{ 414 , -0.80 , -3.26 , -0.28 },	{ 415 , -1.00 , -2.34 , -0.07 },
	{ 418 , 1.16 , -2.08 , -0.49 },		{ 419 , 0.85 , -2.99 , -0.36 },		{ 420 , -0.80 , -2.68 , -0.32 },	{ 421 , -0.93 , -2.93 , -0.29 },
	{ 422 , -0.99 , -2.28 , -0.36 },	{ 423 , 1.00 , -2.21 , -0.62 },		{ 424 , 0.50 , -1.14 , 0.01 },		{ 426 , -0.80 , -2.68 , -0.32 },
	{ 429 , -0.80 , -2.26 , -0.26 },	{ 431 , -1.20 , -5.72 , -0.39 },	{ 433 , -0.66 , -4.30 , -0.05 },	{ 436 , -0.97 , -2.39 , -0.07 },
	{ 437 , -1.26 , -5.36 , -0.44 },	{ 438 , 0.90 , -2.64 , -0.58 },		{ 439 , -0.84 , -2.64 , -0.13 },	{ 440 , 0.93 , -2.64 , -0.63 },
	{ 442 , -1.12 , -3.06 , -0.20 },	{ 445 , -0.90 , -2.64 , -0.34 },	{ 455 , 0.66 , -4.36 , -0.25 },		{ 456 , 0.68 , -4.49 , -0.51 },
	{ 457 , 0.00 , -1.37 , -0.23 },		{ 458 , -0.97 , -2.82 , -0.24 },	{ 459 , -0.93 , -2.64 , -0.32 },	{ 464 , 0.00 , -0.77 , 0.06 },
	{ 466 , -0.90 , -2.86 , -0.31 },	{ 467 , -0.90 , -2.89 , -0.32 },	{ 470 , -0.48 , -2.54 , -0.10 },	{ 474 , 0.90 , -2.70 , -0.40 },
	{ 475 , -0.90 , -2.70 , -0.24 },	{ 477 , -0.98 , -2.74 , -0.08 },	{ 478 , -0.32 , -2.52 , -0.38 },	{ 479 , 1.05 , -2.70 , -0.27 },
	{ 480 , -0.85 , -2.20 , -0.33 },	{ 482 , -0.95 , -2.59 , -0.60 },	{ 483 , 0.89 , -2.63 , -0.72 },		{ 485 , -0.67 , -1.55 , -0.25 },
	{ 489 , -1.07 , -2.71 , -0.34 },	{ 490 , -1.07 , -3.17 , -0.34 },	{ 491 , -0.95 , -2.84 , -0.24 },	{ 492 , 0.85 , -2.90 , -0.29 },
	{ 494 , -0.93 , -2.98 , -0.29 },	{ 495 , 1.04 , -2.14 , -0.43 },		{ 496 , 1.04 , -1.73 , -0.06 },		{ 498 , -1.19 , -3.05 , -0.56 },
	{ 499 , -0.97 , -3.37 , -0.26 },	{ 500 , -0.63 , -1.88 , -0.33 },	{ 502 , -0.93 , -2.65 , -0.10 },	{ 503 , -0.89 , -2.89 , -0.25 },
	{ 504 , -0.90 , -2.86 , -0.31 },	{ 505 , -1.07 , -2.71 , -0.34 },	{ 506 , 1.05 , -2.00 , -0.18 },		{ 507 , -0.95 , -2.71 , -0.41 },
	{ 508 , 0.45 , -3.90 , -0.87 },		{ 516 , -1.02 , -2.78 , -0.17 },	{ 517 , -1.04 , -2.79 , -0.22 },	{ 518 , 0.89 , -2.80 , -0.23 },
	{ 524 , -0.02 , -3.93 , -0.23 },	{ 526 , 0.85 , -2.21 , -0.31 },		{ 527 , -0.98 , -2.30 , -0.08 },	{ 528 , -1.13 , -2.59 , -0.39 },
	{ 529 , -1.11 , -2.10 , -0.03 },	{ 533 , -0.90 , -2.35 , -0.24 },	{ 534 , -0.93 , -2.88 , -0.33 },	{ 535 , -0.90 , -2.89 , -0.37 }, { 536 , -0.90 , -2.89 , -0.37 },
	{ 540 , 1.17 , -2.21 , -0.21 },		{ 541 , 0.80 , -2.07 , -0.24 },		{ 542 , -1.02 , -2.90 , 0.06 },		{ 543 , 0.93 , -2.67 , -0.33 },
	{ 545 , 0.80 , -2.22 , -0.53 },		{ 546 , -1.14 , -2.23 , -0.05 },	{ 547 , -1.00 , -2.61 , -0.07 },	{ 549 , -0.90 , -2.49 , -0.12 },
	{ 550 , 1.15 , -2.49 , -0.29 },		{ 551 , -1.04 , -3.06 , -0.14 },	{ 554 , -0.95 , -2.94 , -0.36 },	{ 556 , 0.00 , -2.96 , 0.27 },
	{ 557 , 0.00 , -2.89 , 0.25 },		{ 558 , -1.07 , -1.76 , 0.04 },		{ 559 , 1.08 , -1.73 , 0.01 },		{ 560 , -1.05 , -1.69 , 0.03 },
	{ 561 , 1.09 , -1.76 , -0.19 },		{ 562 , 1.06 , -1.55 , -0.02 },		{ 565 , -0.94 , -1.67 , -0.06 },	{ 566 , -0.85 , -2.98 , -0.27 },
	{ 567 , -0.90 , -2.83 , -0.45 },	{ 573 , 0.74 , -3.10 , -0.73 },		{ 574 , -0.64 , -1.20 , -0.30 },	{ 575 , -0.90 , -2.69 , -0.21 },
	{ 576 , 0.90 , -3.05 , -0.27 },		{ 579 , -1.04 , -2.73 , -0.18 },	{ 580 , 1.09 , -2.84 , -0.26 },		{ 582 , -1.06 , -3.37 , -0.46 },
	{ 585 , 1.17 , -2.11 , 0.07 },		{ 587 , -1.15 , -2.45 , -0.06 },	{ 588 , -1.36 , -3.85 , -0.56 },	{ 589 , -0.98 , -2.05 , 0.01 },
	{ 596 , -0.80 , -2.68 , -0.32 },	{ 597 , -0.80 , -2.68 , -0.32 },	{ 598 , 0.90 , -2.74 , -0.20 },		{ 599 , -1.07 , -2.71 , -0.34 },
	{ 600 , -0.99 , -2.74 , -0.31 },	{ 602 , -0.90 , -2.31 , -0.36 },	{ 603 , -1.09 , -2.63 , -0.26 },	{ 604 , -0.90 , -2.86 , -0.31 },
	{ 605 , 0.93 , -2.67 , -0.33 },		{ 609 , -1.19 , -3.05 , -0.56 }
};

new callsignList[128][128]; // Stores callsigns with player names
    new callsignCount[128]; // Counts how many players per callsign
    new callsignIndex = 0;

// Returns the offset of a vehicle's licence plate for its model.
stock v_GetVhiclePlatePos( veh_model, &Float:X, &Float:Y, &Float:Z) {
	X = 0.0;
	Y = -2.20;
	Z = 0.0;
	new vpp_sizeof = sizeof( vehicle_plate_pos );
	for( new i; i < vpp_sizeof; i++ ) {
		if( veh_model == vehicle_plate_pos[ i ][ vpp_veh_model ] )
		{
			X = vehicle_plate_pos[ i ][ vpp_x ];
			Y = vehicle_plate_pos[ i ][ vpp_y ];
			Z = vehicle_plate_pos[ i ][ vpp_z ];
			break;
		}
	}
	return;
}

// /callsign [callsign] - sets your unit's callsign.
CMD:callsign(playerid, params[])
{
    new factionid = Character[playerid][E_CHARACTER_FACTIONID];

    if (!factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID!");
    }

    if (!Faction_CanID(faction_enum_id, FAC_CAP_CARSIGN))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a government faction.");
    }

    new input[16];

    if (sscanf(params, "s[16]", input))
    {
        PlayerVar[playerid][E_PLAYER_CALLSIGN][0] = EOS;

        new vehicleid = GetPlayerVehicleID(playerid);

        if (vehicleid != 0)
        {
            new veh_enum_id = Vehicle_GetEnumID(vehicleid);

            if (veh_enum_id != INVALID_VEHICLE_ID &&
                VehicleUnitData[veh_enum_id][unit_sql_id] > 0)
            {
                new query[160];
                mysql_format(mysql, query, sizeof(query),
                    "UPDATE mdc_unit_members SET callsign = '' WHERE unit_id = %d AND character_id = %d",
                    VehicleUnitData[veh_enum_id][unit_sql_id],
                    Character[playerid][E_CHARACTER_ID]);
                mysql_tquery(mysql, query);
            }
        }

        return SendServerMessage(playerid, COLOR_BLUE, "Callsign", "A3A3A3", "You removed your callsign.");
    }

    if (strlen(input) == 0 || strlen(input) > 15)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Callsign must be 1-15 characters.");
    }

    format(PlayerVar[playerid][E_PLAYER_CALLSIGN], 16, "%s", input);

    // Update MDC instantly if inside unit vehicle
    new vehicleid = GetPlayerVehicleID(playerid);

    if (vehicleid != 0)
    {
        new veh_enum_id = Vehicle_GetEnumID(vehicleid);

        if (veh_enum_id != INVALID_VEHICLE_ID &&
            VehicleUnitData[veh_enum_id][unit_sql_id] > 0)
        {
            new query[160];
            mysql_format(mysql, query, sizeof(query),
                "UPDATE mdc_unit_members SET callsign = '%e' WHERE unit_id = %d AND character_id = %d",
                PlayerVar[playerid][E_PLAYER_CALLSIGN],
                VehicleUnitData[veh_enum_id][unit_sql_id],
                Character[playerid][E_CHARACTER_ID]);
            mysql_tquery(mysql, query);
        }
    }

    new string[128];
    format(string, sizeof(string), "You are now assigned to callsign %s", input);
    SendServerMessage(playerid, COLOR_BLUE, "Callsign", "A3A3A3", string);

    return 1;
}

// /units - lists active units and their callsigns.
CMD:units(playerid, params[])
{
    new factionid = Character[playerid][E_CHARACTER_FACTIONID];

    if (!factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    }

    if (Faction[faction_enum_id][E_FACTION_TYPE] != FACTION_TYPE_GOV &&
        Faction[faction_enum_id][E_FACTION_TYPE] != FACTION_TYPE_LEO &&
        Faction[faction_enum_id][E_FACTION_TYPE] != FACTION_TYPE_FEDERAL &&
        Faction[faction_enum_id][E_FACTION_TYPE] != FACTION_TYPE_EMS &&
        Faction[faction_enum_id][E_FACTION_TYPE] != FACTION_TYPE_SECURITY) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a government faction.");
    }

    // **Reset Callsign Storage**
    callsignIndex = 0;
    for (new i = 0; i < 128; i++) {
        callsignList[i][0] = '\0';
        callsignCount[i] = 0;
    }

    // **Loop through all players (including yourself)**
    for (new i = 0; i < MAX_PLAYERS; i++) {
        if (!IsPlayerConnected(i)
            || strlen(PlayerVar[i][E_PLAYER_CALLSIGN]) == 0
            || Character[i][E_CHARACTER_FACTIONID] != factionid)
        {
            continue;
        }

        new bool:found = false;
        for (new j = 0; j < callsignIndex; j++) {
            if (strcmp(callsignList[j], PlayerVar[i][E_PLAYER_CALLSIGN], true) == 0) {
                // Append player to the existing callsign group
                if (i == playerid) {
                    strcat(callsignList[j], ", ");
                    strcat(callsignList[j], ReturnRPName(i)); // Your name
                } else {
                    strcat(callsignList[j], ", ");
                    strcat(callsignList[j], ReturnRPName(i)); // Player name
                }
                callsignCount[j]++;
                found = true;
                break;
            }
        }

        // If callsign is new, add it to the list
        if (!found && callsignIndex < 128) {
            if (i == playerid) {
                format(callsignList[callsignIndex], sizeof(callsignList[]), "%s - %s", PlayerVar[i][E_PLAYER_CALLSIGN], ReturnRPName(i));
            } else {
                format(callsignList[callsignIndex], sizeof(callsignList[]), "%s - %s", PlayerVar[i][E_PLAYER_CALLSIGN], ReturnRPName(i));
            }
            callsignCount[callsignIndex] = 1;
            callsignIndex++;
        }
    }

    // **Output the List of Active Units**
    if (callsignIndex == 0) {
        return SendServerMessage(playerid, COLOR_INFO, "Units", "A3A3A3", "No active units with assigned callsigns.");
    }

    SendClientMessage(playerid, COLOR_POLICE, "Active Units:");
    for (new i = 0; i < callsignIndex; i++) {
        SendClientMessage(playerid, COLOR_BLUE, callsignList[i]);
    }

    return 1;
}

// /carsign - manages the roof sign / callsign of a unit vehicle.
CMD:carsign(playerid, params[])
{
    new vehicleid = GetPlayerVehicleID(playerid);

    if (!IsEngineVehicle(vehicleid)) {
        return SendClientMessage(playerid, COLOR_ERROR, "You are not in any vehicle.");
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) {
        return SendClientMessage(playerid, COLOR_ERROR, "You can't do this as you're not the driver.");
    }

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];

    if (!factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    }

    if (!Faction_CanID(faction_enum_id, FAC_CAP_CARSIGN))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a government faction.");
    }

    new input[75];

    // ================= REMOVE CAR SIGN =================
    if (sscanf(params, "s[75]", input))
    {
        Vehicle_DestroyLabel(veh_enum_id);

        // REMOVE UNIT COMPLETELY
        Unit_StopByVehicleEnum(veh_enum_id);

        return SendServerMessage(playerid, COLOR_BLUE, "Carsign", "A3A3A3", "Carsign removed!");
    }

    if (strlen(input) == 0 || strlen(input) > 15)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "Callsign must be between 1 and 15 characters.");
    }

    new veh_model = GetVehicleModel(vehicleid), Float:r_x, Float:r_y, Float:r_z;
    v_GetVhiclePlatePos(veh_model, r_x, r_y, r_z);

    // ================= UPDATE LABEL =================
    Vehicle_DestroyLabel(veh_enum_id);

    Vehicle[veh_enum_id][E_VEHICLE_LABEL] = CreateDynamic3DTextLabel(
        input,
        0xDEDEDEFF,
        r_x, r_y, r_z,
        20.0,
        INVALID_PLAYER_ID,
        vehicleid,
        0, -1, -1, -1,
        200.0
    );

    Streamer_Update(playerid, STREAMER_TYPE_3D_TEXT_LABEL);

    // ================= MOVE EXISTING UNIT WITH SAME CARSIGN =================
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (!VehicleUnitData[i][unit_active])
            continue;

        if (i == veh_enum_id)
            continue;

        if (strcmp(VehicleUnitData[i][unit_callsign], input, true) == 0)
        {
            Vehicle_DestroyLabel(i);

            Unit_StopByVehicleEnum(i);
            break;
        }
    }

    // ================= UNIT LOGIC =================
    new unit_id = VehicleUnitData[veh_enum_id][unit_sql_id];

    // CREATE UNIT
    if (unit_id <= 0)
    {
        new query[256];
        new modelid = GetVehicleModel(vehicleid);

        mysql_format(mysql, query, sizeof(query),
            "INSERT INTO mdc_units (vehicle_sql_id, vehicle_model, callsign, faction_id, active) \
            VALUES (%d, %d, '%e', %d, 1)",
            Vehicle[veh_enum_id][E_VEHICLE_SQLID],
            modelid,
            input,
            factionid);

        mysql_tquery(mysql, query, "MDC_OnUnitCreated", "d", veh_enum_id);

        VehicleUnitData[veh_enum_id][unit_active] = true;
        VehicleUnitData[veh_enum_id][unit_factionid] = factionid;
        format(VehicleUnitData[veh_enum_id][unit_callsign], 16, "%s", input);
        VehicleUnitData[veh_enum_id][last_occupied_time] = gettime();
    }
    else
    {
        // UPDATE EXISTING UNIT
        new query[256];

        mysql_format(mysql, query, sizeof(query),
            "UPDATE mdc_units SET callsign = '%e' WHERE id = %d",
            input,
            unit_id);

        mysql_tquery(mysql, query);

        format(VehicleUnitData[veh_enum_id][unit_callsign], 16, "%s", input);
    }

    // ================= FACTION MESSAGE =================
    Faction_SendMessage(
        factionid,
        sprintf("{ [%s] %s has set their vehicle to \"%s\" }",
            Faction[faction_enum_id][E_FACTION_ABBREV],
            ReturnRPName(playerid),
            input
        ),
        faction_enum_id,
        false
    );

    return 1;
}

// Stops a unit that was tied to a vehicle.
stock Unit_StopByVehicleEnum(veh_enum_id)
{
    if (!VehicleUnitData[veh_enum_id][unit_active])
        return;

    new unit_id = VehicleUnitData[veh_enum_id][unit_sql_id];

    if (unit_id > 0)
    {
        new query[256];

        // Remove members first
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM mdc_unit_members WHERE unit_id = %d",
            unit_id);
        mysql_tquery(mysql, query);

        // Remove unit row
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM mdc_units WHERE id = %d",
            unit_id);
        mysql_tquery(mysql, query);
    }

    VehicleUnitData[veh_enum_id][unit_active] = false;
    VehicleUnitData[veh_enum_id][unit_callsign][0] = EOS;
    VehicleUnitData[veh_enum_id][unit_factionid] = 0;
    VehicleUnitData[veh_enum_id][unit_sql_id] = 0;
}

forward MDC_OnUnitCreated(veh_enum_id);
// MySQL callback: stores the new unit's database id.
public MDC_OnUnitCreated(veh_enum_id)
{
    VehicleUnitData[veh_enum_id][unit_sql_id] = cache_insert_id();
    return 1;
}

forward MDC_UpdateUnitPositions();
// Repeating update of unit positions shown on the MDC.
public MDC_UpdateUnitPositions()
{
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (!VehicleUnitData[i][unit_active])
            continue;

        if (VehicleUnitData[i][unit_sql_id] <= 0)
            continue;

        new vehicleid = Vehicle[i][E_VEHICLE_ID];

        if (!IsValidVehicle(vehicleid))
            continue;

        new Float:x, Float:y, Float:z, Float:angle;
        GetVehiclePos(vehicleid, x, y, z);
        GetVehicleZAngle(vehicleid, angle);

        new sirenActive = 0;

        if (GetVehicleParamsSirenState(vehicleid) == 1)
        {
            sirenActive = 1;
        }

        new occupantCount = 0;

        for (new p = 0; p < MAX_PLAYERS; p++)
        {
            if (!IsPlayerConnected(p))
                continue;

            if (Character[p][E_CHARACTER_FACTIONID] != VehicleUnitData[i][unit_factionid])
                continue;

            if (GetPlayerVehicleID(p) != vehicleid)
                continue;

            occupantCount++;

            VehicleUnitData[i][last_occupied_time] = gettime();
        }

        // Auto-cleanup after 30 minutes of no occupants
        if (occupantCount == 0)
        {
            if (VehicleUnitData[i][last_occupied_time] > 0 &&
                (gettime() - VehicleUnitData[i][last_occupied_time]) > 1800)
            {
                Unit_StopByVehicleEnum(i);
                continue; // IMPORTANT: skip rest of loop
            }
        }

        // If empty, keep the unit alive but clear members
        if (occupantCount == 0)
        {
            new clearQuery[128];
            mysql_format(mysql, clearQuery, sizeof(clearQuery),
                "DELETE FROM mdc_unit_members WHERE unit_id = %d",
                VehicleUnitData[i][unit_sql_id]);
            mysql_tquery(mysql, clearQuery);

            new bool:positionChanged = !(
                floatabs(x - VehicleUnitData[i][mdc_last_x]) < 0.05 &&
                floatabs(y - VehicleUnitData[i][mdc_last_y]) < 0.05 &&
                floatabs(z - VehicleUnitData[i][mdc_last_z]) < 0.05 &&
                floatabs(angle - VehicleUnitData[i][mdc_last_angle]) < 1.0 &&
                sirenActive == VehicleUnitData[i][last_siren]
            );

            if (positionChanged)
            {
                new query[256];
                new modelid = GetVehicleModel(vehicleid);

                mysql_format(mysql, query, sizeof(query),
                    "UPDATE mdc_units \
                    SET pos_x = %.4f, pos_y = %.4f, pos_z = %.4f, angle = %.2f, vehicle_model = %d, siren_active = %d \
                    WHERE id = %d",
                    x, y, z, angle,
                    modelid,
                    sirenActive,
                    VehicleUnitData[i][unit_sql_id]);
                mysql_tquery(mysql, query);
            }

            VehicleUnitData[i][mdc_last_x] = x;
            VehicleUnitData[i][mdc_last_y] = y;
            VehicleUnitData[i][mdc_last_z] = z;
            VehicleUnitData[i][mdc_last_angle] = angle;
            VehicleUnitData[i][last_siren] = sirenActive;

            continue;
        }

        new clearQuery[128];
        mysql_format(mysql, clearQuery, sizeof(clearQuery),
            "DELETE FROM mdc_unit_members WHERE unit_id = %d",
            VehicleUnitData[i][unit_sql_id]);
        mysql_tquery(mysql, clearQuery);

        for (new p = 0; p < MAX_PLAYERS; p++)
        {
            if (!IsPlayerConnected(p))
                continue;

            if (Character[p][E_CHARACTER_FACTIONID] != VehicleUnitData[i][unit_factionid])
                continue;

            if (GetPlayerVehicleID(p) != vehicleid)
                continue;

            new insertQuery[160];
            mysql_format(mysql, insertQuery, sizeof(insertQuery),
                "INSERT INTO mdc_unit_members (unit_id, character_id, callsign) VALUES (%d, %d, '%e')",
                VehicleUnitData[i][unit_sql_id],
                Character[p][E_CHARACTER_ID],
                PlayerVar[p][E_PLAYER_CALLSIGN]);
            mysql_tquery(mysql, insertQuery);
        }

        new bool:positionChanged = !(
            floatabs(x - VehicleUnitData[i][mdc_last_x]) < 0.05 &&
            floatabs(y - VehicleUnitData[i][mdc_last_y]) < 0.05 &&
            floatabs(z - VehicleUnitData[i][mdc_last_z]) < 0.05 &&
            floatabs(angle - VehicleUnitData[i][mdc_last_angle]) < 1.0 &&
            sirenActive == VehicleUnitData[i][last_siren]
        );

        if (positionChanged)
        {
            new query[256];
            new modelid = GetVehicleModel(vehicleid);

            mysql_format(mysql, query, sizeof(query),
                "UPDATE mdc_units \
                SET pos_x = %.4f, pos_y = %.4f, pos_z = %.4f, angle = %.2f, vehicle_model = %d, siren_active = %d \
                WHERE id = %d",
                x, y, z, angle,
                modelid,
                sirenActive,
                VehicleUnitData[i][unit_sql_id]);
            mysql_tquery(mysql, query);
        }

        VehicleUnitData[i][mdc_last_x] = x;
        VehicleUnitData[i][mdc_last_y] = y;
        VehicleUnitData[i][mdc_last_z] = z;
        VehicleUnitData[i][mdc_last_angle] = angle;
        VehicleUnitData[i][last_siren] = sirenActive;
    }

    return 1;
}

hook OnStartSQL()
{
    printf("[MDC] Clearing runtime unit tables...");

    mysql_tquery(mysql, "DELETE FROM mdc_unit_members");
    mysql_tquery(mysql, "DELETE FROM mdc_units");

    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        VehicleUnitData[i][unit_active] = false;
        VehicleUnitData[i][unit_callsign][0] = EOS;
        VehicleUnitData[i][unit_factionid] = 0;
        VehicleUnitData[i][unit_sql_id] = 0;
        VehicleUnitData[i][unit_last_member_count] = 0;
    }

	if (!g_mdcTimerStarted)
	{
		SetTimer("MDC_UpdateUnitPositions", 1000, true);
		g_mdcTimerStarted = true;
	}

    return 1;
}
