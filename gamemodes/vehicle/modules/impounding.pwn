// ============================================================================
// File: vehicle/modules/impounding.pwn
// Impound lot: /impound lets law enforcement impound a vehicle and /unimpound lets the owner
// pay to get it back.
// Commands: /unimpound /impound
// ============================================================================

#define COLOR_IMPOUND	0x1F85DEFF
#define IMPOUND_FEE (Runtime_Int(RT_VEHICLES_IMPOUND_FEE)) // Cached database setting; edit through ACP.
#define DIALOG_UNIMPOUND_CONFIRM 8000

// Loads the impound lot points.
Impound_LoadEntities() { return 1; } // Runtime_RebuildServices owns the handles.

// /unimpound - pays to get an impounded vehicle back.
CMD:unimpound(playerid, params[])
{
    if (!Runtime_AtLocation(playerid,RT_LOC_IMPOUND))
    {
        return SendServerMessage(playerid, COLOR_IMPOUND, "Impound", "A3A3A3",
            "You must be at the unimpound point! Check for a \"?\" on your minimap.");
    }

    new vehicleid = GetPlayerVehicleID(playerid);
    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
        return SendClientMessage(playerid, COLOR_ERROR, "You're not in a proper vehicle.");

    // -----------------------------
    // Ownership / permission logic
    // -----------------------------
    new type = Vehicle[veh_enum_id][E_VEHICLE_TYPE];

    if (type == E_VEHICLE_TYPE_PLAYER)
    {
        if (Vehicle[veh_enum_id][E_VEHICLE_OWNER] != Character[playerid][E_CHARACTER_ID])
            return SendClientMessage(playerid, COLOR_ERROR, "You do not own this vehicle!");
    }
    else if (type == E_VEHICLE_TYPE_FACTION)
    {
        new playerFaction = Character[playerid][E_CHARACTER_FACTIONID];
        new vehicleFaction = Vehicle[veh_enum_id][E_VEHICLE_OWNER]; // assumes faction ID stored here

        if (playerFaction != vehicleFaction)
            return SendClientMessage(playerid, COLOR_ERROR, "This is not your faction vehicle!");

        new tier = Character[playerid][E_CHARACTER_FACTIONTIER];

        if (tier > 2)
            return SendClientMessage(playerid, COLOR_ERROR, "Only supervisors may retrieve faction vehicles from impound.");
    }
    else
    {
        return SendClientMessage(playerid, COLOR_ERROR, "This vehicle cannot be unimpounded.");
    }

    if (!Vehicle[veh_enum_id][E_VEHICLE_IMPOUNDED])
        return SendClientMessage(playerid, COLOR_ERROR, "This vehicle isn't impounded!");

    new fines = VehicleOutstandingFines[veh_enum_id];
    new total = IMPOUND_FEE + fines;

    new message[256];
    format(message, sizeof(message),
        "Impound Fee: $%s\nOutstanding Fines: $%s\n\nTotal Due: $%s\n\nWould you like to proceed?",
        IntegerWithDelimiter(IMPOUND_FEE),
        IntegerWithDelimiter(fines),
        IntegerWithDelimiter(total)
    );

    inline UnimpoundConfirm(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem, inputtext

        if (!response)
            return 1;

        if (GetPlayerCash(pid) < total)
        {
            return SendClientMessage(pid, COLOR_ERROR,
                sprintf("You need $%s to retrieve this vehicle.",
                IntegerWithDelimiter(total)));
        }

        TakePlayerCash(pid, total, "Unimpound fee");

        // Only base impound fee goes to faction
        Faction_AddBankMoneyPerType(9, IMPOUND_FEE / 2, "Vehicle Impound Fee");
        Faction_AddBankMoneyPerType(0, IMPOUND_FEE / 2, "Vehicle Impound Fee");

        new vehicle_sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];

        // Clear fines
        if (fines > 0)
        {
            VehicleTickets_ClearForVehicle(vehicle_sqlid);
        }

        // Unimpound vehicle
        Vehicle[veh_enum_id][E_VEHICLE_IMPOUNDED] = 0;

        Vehicle[veh_enum_id][E_VEHICLE_POS_X] = 1154.5194;
        Vehicle[veh_enum_id][E_VEHICLE_POS_Y] = -1726.2858;
        Vehicle[veh_enum_id][E_VEHICLE_POS_Z] = 13.8784;
        Vehicle[veh_enum_id][E_VEHICLE_POS_A] = 189.2765;

        Vehicle[veh_enum_id][E_VEHICLE_VW] = 0;
        Vehicle[veh_enum_id][E_VEHICLE_INT] = 0;

        SetVehiclePos(vehicleid,
            Vehicle[veh_enum_id][E_VEHICLE_POS_X],
            Vehicle[veh_enum_id][E_VEHICLE_POS_Y],
            Vehicle[veh_enum_id][E_VEHICLE_POS_Z]);

        SetVehicleZAngle(vehicleid,
            Vehicle[veh_enum_id][E_VEHICLE_POS_A]);

        SendClientMessage(pid, COLOR_YELLOW,
            "You retrieved your vehicle from the lot. All citations cleared.");

        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE vehicles SET vehicle_pos_x = '%f', vehicle_pos_y = '%f', vehicle_pos_z = '%f', vehicle_pos_a = '%f', vehicle_vw = '%d', vehicle_int = '%d', vehicle_impounded = '0' WHERE vehicle_sqlid = %d",
            Vehicle[veh_enum_id][E_VEHICLE_POS_X],
            Vehicle[veh_enum_id][E_VEHICLE_POS_Y],
            Vehicle[veh_enum_id][E_VEHICLE_POS_Z],
            Vehicle[veh_enum_id][E_VEHICLE_POS_A],
            Vehicle[veh_enum_id][E_VEHICLE_VW],
            Vehicle[veh_enum_id][E_VEHICLE_INT],
            vehicle_sqlid
        );
        mysql_tquery(mysql, query);

        AddLogEntry(pid, LOG_TYPE_SCRIPT,
            sprintf("Unimpounded %s (SQL ID: %d) - Paid $%s",
            ReturnVehicleName(vehicleid),
            vehicle_sqlid,
            IntegerWithDelimiter(total)));

        return 1;
    }

    Dialog_ShowCallback(playerid, using inline UnimpoundConfirm,
        DIALOG_STYLE_MSGBOX,
        "Vehicle Impound",
        message,
        "Pay",
        "Cancel");

    return 1;
}

// /impound - law enforcement impounds a vehicle.
CMD:impound(playerid, params[]) {

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];

    if (!factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    }

    if (!Faction_CanID(faction_enum_id, FAC_CAP_IMPOUND)) {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a parking enforcement faction.");
    }

    // -----------------------------
    // NEW: Parse vehicle ID
    // -----------------------------
    new vehicleid;

    if (sscanf(params, "d", vehicleid)) {
        return SendClientMessage(playerid, COLOR_ERROR, "Usage: /impound [vehicleid]");
    }

    if (!IsValidVehicle(vehicleid)) {
        return SendClientMessage(playerid, COLOR_ERROR, "Invalid vehicle ID.");
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1) {
        return SendClientMessage(playerid, COLOR_ERROR, "This vehicle is not registered.");
    }

    // Optional (recommended): Range check so they can't impound from across map
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);

    if (GetDistanceBetweenPoints(px, py, pz, vx, vy, vz) > 10.0) {
        return SendClientMessage(playerid, COLOR_ERROR, "You must be near the vehicle to impound it.");
    }

    if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_PLAYER &&
        Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_FACTION) {

        return SendClientMessage(playerid, COLOR_ERROR, "You can only impound player or faction owned vehicles!");
    }

    if (!IsPlayerInRangeOfPoint(playerid, 30.0, 1080.7576, -1754.0604, 13.3918)) {
        return SendClientMessage(playerid, COLOR_ERROR, "You can only do this at the impound lot.");
    }

    new Float:x, Float:y, Float:z, Float:a;

    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, a);

    Vehicle[veh_enum_id][E_VEHICLE_POS_X] = x;
    Vehicle[veh_enum_id][E_VEHICLE_POS_Y] = y;
    Vehicle[veh_enum_id][E_VEHICLE_POS_Z] = z;
    Vehicle[veh_enum_id][E_VEHICLE_POS_A] = a;

    Vehicle[veh_enum_id][E_VEHICLE_VW] = 0;
    Vehicle[veh_enum_id][E_VEHICLE_INT] = 0;

    Vehicle[veh_enum_id][E_VEHICLE_IMPOUNDED] = 1;

    SetDoorStatus(vehicleid, true);
    SetEngineStatus(vehicleid, false);

    // Remove any driver safely
    foreach (new i : Player) {
        if (IsPlayerInVehicle(i, vehicleid)) {
            JT_RemovePlayerFromVehicle(i);
        }
    }

    new query[256];

    mysql_format(mysql, query, sizeof(query),
        "UPDATE vehicles SET vehicle_pos_x = '%f', vehicle_pos_y = '%f', vehicle_pos_z = '%f', vehicle_pos_a = '%f', vehicle_vw = '%d', vehicle_int = '%d', vehicle_impounded = '%d' WHERE vehicle_sqlid = %d",
        Vehicle[veh_enum_id][E_VEHICLE_POS_X],
        Vehicle[veh_enum_id][E_VEHICLE_POS_Y],
        Vehicle[veh_enum_id][E_VEHICLE_POS_Z],
        Vehicle[veh_enum_id][E_VEHICLE_POS_A],
        Vehicle[veh_enum_id][E_VEHICLE_VW],
        Vehicle[veh_enum_id][E_VEHICLE_INT],
        Vehicle[veh_enum_id][E_VEHICLE_IMPOUNDED],
        Vehicle[veh_enum_id][E_VEHICLE_SQLID]
    );

    mysql_tquery(mysql, query);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT,
        sprintf("Used /impound on a %s (SQL ID: %d)",
        ReturnVehicleName(vehicleid),
        Vehicle[veh_enum_id][E_VEHICLE_SQLID])
    );

    Faction_SendMessage(factionid,
        sprintf("{ [%s] (%d) %s has impounded a (%d) %s. }",
        Faction_GetAbbreviationByID(faction_enum_id),
        playerid,
        ReturnRPName(playerid),
        vehicleid,
        ReturnVehicleName(vehicleid)
    ), faction_enum_id, false);

    SendClientMessage(playerid, COLOR_YELLOW,
        "You've impounded the vehicle. Turned off the engine and locked it for safety. Good work officer.");

    foreach (new targetid : Player) {
        if (IsPlayerConnected(targetid) && IsPlayerSpawned(targetid)) {
            if (Vehicle[veh_enum_id][E_VEHICLE_OWNER] == Character[targetid][E_CHARACTER_ID]) {

                SendClientMessage(targetid, COLOR_YELLOW, "Your vehicle has been impounded. To retrieve it, spawn it and do /carfind.");
                SendClientMessage(targetid, COLOR_YELLOW, "Enter the premises, enter your car and make your way to the icon and do /unimpound.");
                SendClientMessage(targetid, COLOR_YELLOW, "Once you are outside the lot, /cardespawn your car at your desired spawn location.");
            }
        }
    }

    return true;
}

// Clears the tickets on a vehicle (after impound or sale).
stock VehicleTickets_ClearForVehicle(vehicle_sqlid)
{
    new veh_enum = Vehicle_GetEnumIDFromSQLID(vehicle_sqlid);
    if (veh_enum == -1)
        return 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_vehicle_sqlid] == vehicle_sqlid &&
            VehicleTicketData[i][vt_status] == TICKET_STATUS_UNPAID)
        {
            VehicleTicketData[i][vt_status] = TICKET_STATUS_PAID;
        }
    }

    VehicleOutstandingFines[veh_enum] = 0;

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE vehicle_tickets SET vt_status = %d, vt_paid_date = NOW() WHERE vt_vehicle_sqlid = %d AND vt_status = %d",
        TICKET_STATUS_PAID,
        vehicle_sqlid,
        TICKET_STATUS_UNPAID
    );
    mysql_tquery(mysql, query);

    return 1;
}
