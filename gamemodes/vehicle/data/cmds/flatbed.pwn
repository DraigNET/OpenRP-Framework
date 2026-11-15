// ============================================================================
// File: vehicle/data/cmds/flatbed.pwn
// Flatbed trucks: /loadbike, /unloadbike and /checkbike carry bikes on a tow truck.
// Commands: /loadbike /unloadbike /checkbike
// ============================================================================

#define BOXVILLE_MODEL 498
#define BIKE_VW     9999

new BikeStoredInVehicle[MAX_VEHICLES]; // rumpo → bike
new BikeStoredBy[MAX_VEHICLES];        // bike → rumpo

// =============================
// INIT
// =============================

// Sets up bike transport on flatbeds.
InitBikeTransport()
{
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        BikeStoredInVehicle[i] = INVALID_VEHICLE_ID;
        BikeStoredBy[i] = INVALID_VEHICLE_ID;
    }
    return 1;
}

// =============================
// COMMAND: /loadbike
// =============================

// /loadbike - loads a bike onto a flatbed.
CMD:loadbike(playerid, params[])
{
    if (!IsPlayerInAnyVehicle(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle.");

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be the driver.");

    new vehicleid = GetPlayerVehicleID(playerid);

    if (GetVehicleModel(vehicleid) != BOXVILLE_MODEL)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a Rumpo.");

    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInGovFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You are not on duty in a faction that can tow bikes.");

    if (BikeStoredInVehicle[vehicleid] != INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle already has a bike loaded.");

    new target;
    if (sscanf(params, "i", target))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/loadbike [vehicleid]");

    if (!IsValidVehicle(target))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid vehicle.");

    if (!IsABike(target))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This is not a bike or bicycle.");

    if (BikeStoredBy[target] != INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This bike is already stored.");

    if (IsVehicleOccupied(target))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Bike must be empty.");

    new Float:px, Float:py, Float:pz;
    new Float:bx, Float:by, Float:bz;

    GetVehiclePos(vehicleid, px, py, pz);
    GetVehiclePos(target, bx, by, bz);

    if (GetDistanceBetweenPoints(px, py, pz, bx, by, bz) > 6.0)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Bike is too far.");

    BikeStoredInVehicle[vehicleid] = target;
    BikeStoredBy[target] = vehicleid;

    SetVehicleVirtualWorld(target, BIKE_VW);

    SendServerMessage(playerid, COLOR_YELLOW, "Bike", "A3A3A3", "Bike loaded into vehicle.");
    return 1;
}

// =============================
// COMMAND: /unloadbike
// =============================

// /unloadbike - takes a bike off a flatbed.
CMD:unloadbike(playerid, params[])
{
    if (!IsPlayerInAnyVehicle(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle.");

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be the driver.");

    new vehicleid = GetPlayerVehicleID(playerid);

    if (GetVehicleModel(vehicleid) != BOXVILLE_MODEL)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a Rumpo.");

    new bike = BikeStoredInVehicle[vehicleid];

    if (bike == INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No bike stored.");

    new Float:x, Float:y, Float:z, Float:a;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, a);

    new Float:dropX, Float:dropY, Float:dropZ;
    GetPosBehindVehicle(vehicleid, dropX, dropY, dropZ);

    new vw = GetVehicleVirtualWorld(vehicleid);
    SetVehicleVirtualWorld(bike, vw);

    SetVehiclePos(bike, dropX, dropY, dropZ);
    SetVehicleZAngle(bike, a);

    BikeStoredInVehicle[vehicleid] = INVALID_VEHICLE_ID;
    BikeStoredBy[bike] = INVALID_VEHICLE_ID;

    SendServerMessage(playerid, COLOR_YELLOW, "Bike", "A3A3A3", "Bike unloaded.");
    return 1;
}

// =============================
// COMMAND: /checkbike
// =============================

// /checkbike - checks what is on a flatbed.
CMD:checkbike(playerid, params[])
{
    if (!IsPlayerInAnyVehicle(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle.");

    new vehicleid = GetPlayerVehicleID(playerid);

    if (GetVehicleModel(vehicleid) != BOXVILLE_MODEL)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a Rumpo.");

    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInGovFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You are not on duty in a faction that can tow bikes.");

    new bike = BikeStoredInVehicle[vehicleid];

    if (bike == INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No bike is currently loaded.");

    new string[128];
    format(string, sizeof(string), "Loaded bike: %s (ID %d)", ReturnVehicleName(bike), bike);

    SendServerMessage(playerid, COLOR_VEHICLE, "Bike Check", "A3A3A3", string);
    return 1;
}
