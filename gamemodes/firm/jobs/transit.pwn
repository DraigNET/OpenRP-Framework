// ============================================================================
// File: firm/jobs/transit.pwn
// Transit firm field: taxi and limo fare meter (/startmeter, /stopmeter, /fare).
// Commands: /fare /startmeter /stopmeter
// ============================================================================

#include <YSI_Coding\y_hooks>

new
    Float:TransitLastPos[MAX_PLAYERS][3],
    TransitDistance[MAX_PLAYERS] = {0, ...};

// Returns true if the vehicle is a taxi or limo model.
bool:Transit_IsTaxiVehicle(vehicleid)
{
    new modelid = GetVehicleModel(vehicleid);
    return modelid == 420 || modelid == 438;
}

// Returns true if the player is on taxi duty with a licence.
bool:Transit_IsOnService(playerid)
{
    return PlayerVar[playerid][E_PLAYER_TAXIDUTY] && CanUseTransitTools(playerid);
}

// Takes the player off taxi duty and removes the taxi sign.
Transit_StopService(playerid, bool:send_message = true, vehicleid = INVALID_VEHICLE_ID)
{
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        vehicleid = GetPlayerVehicleID(playerid);
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    PlayerVar[playerid][E_PLAYER_TAXIDUTY] = false;
    PlayerVar[playerid][E_PLAYER_TAXIMETER] = false;
    PlayerVar[playerid][E_PLAYER_TAXIFARE] = 0;
    TransitDistance[playerid] = 0;

    if (veh_enum_id != -1)
    {
        Vehicle_DestroyTaxiSign(veh_enum_id);
    }

    if (send_message)
    {
        SendServerMessage(playerid, COLOR_JOB, "Transit Firm", "DEDEDE", "You are now off duty as a transit driver.");
    }

    return true;
}

// Repeating task (every second): charges taxi passengers by distance or time while the meter runs.
task TransitMeterTick[1000]()
{
    foreach (new i: Player)
    {
        if (!PlayerVar[i][E_PLAYER_TAXIDUTY])
        {
            continue;
        }

        if (!CanUseTransitTools(i))
        {
            Transit_StopService(i, true);
            continue;
        }

        if (!PlayerVar[i][E_PLAYER_TAXIMETER])
        {
            continue;
        }

        new vehicleid = GetPlayerVehicleID(i);
        new veh_enum_id = Vehicle_GetEnumID(vehicleid);

        if (veh_enum_id == -1 || !Transit_IsTaxiVehicle(vehicleid))
        {
            Transit_StopService(i, true);
            continue;
        }

        new taxi_dist = floatround(GetPlayerDistanceFromPoint(i, TransitLastPos[i][0], TransitLastPos[i][1], TransitLastPos[i][2]));
        TransitDistance[i] += taxi_dist;

        new fare = PlayerVar[i][E_PLAYER_TAXIFARE];
        new total_fare = (TransitDistance[i] / 30) * fare;

        new str_fare[64];
        format(str_fare, sizeof(str_fare), "{FFFF00}Fare: {FFFFFF}$%d\n{FFFF00}Meter: {FFFFFF}$%d", fare, total_fare);

        if (IsValidDynamic3DTextLabel(Vehicle[veh_enum_id][E_VEHICLE_TAXISIGN]))
        {
            UpdateDynamic3DTextLabelText(Vehicle[veh_enum_id][E_VEHICLE_TAXISIGN], 0x00FFFFFF, str_fare);
        }

        Streamer_Update(i, STREAMER_TYPE_3D_TEXT_LABEL);
        GetPlayerPos(i, TransitLastPos[i][0], TransitLastPos[i][1], TransitLastPos[i][2]);
    }
}

// /fare [fee] - sets the fare for your taxi.
CMD:fare(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    new fare;

    if (sscanf(params, "d", fare))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/fare [fee]");
    }

    if (PlayerVar[playerid][E_PLAYER_TAXIDUTY])
    {
        return Transit_StopService(playerid, true);
    }

    if (!CanUseTransitTools(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You must be on duty with a transit firm to use scripted fares.");
    }

    new vehicleid = GetPlayerVehicleID(playerid);

    if (!Transit_IsTaxiVehicle(vehicleid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You need to be in a Taxi or Cabbie.");
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You must be the driver.");
    }

    if (fare < 1 || fare > 5)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "Fare price must be between $1 and $5.");
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "This vehicle cannot be used for scripted fares.");
    }

    PlayerVar[playerid][E_PLAYER_TAXIFARE] = fare;
    PlayerVar[playerid][E_PLAYER_TAXIDUTY] = true;
    PlayerVar[playerid][E_PLAYER_TAXIMETER] = false;
    TransitDistance[playerid] = 0;

    Vehicle_DestroyTaxiSign(veh_enum_id);

    new str_fare[64];
    format(str_fare, sizeof(str_fare), "{FFFF00}Fare: {FFFFFF}$%d\n{FFFF00}Meter: {FFFFFF}$0", fare);
    Vehicle[veh_enum_id][E_VEHICLE_TAXISIGN] = CreateDynamic3DTextLabel(str_fare, 0x00FFFFFF, 0.0, 0.0, 0.0, 20.0, INVALID_PLAYER_ID, vehicleid, 0, -1, -1, -1, 200.0);

    Streamer_Update(playerid, STREAMER_TYPE_3D_TEXT_LABEL);
    SendServerMessage(playerid, COLOR_JOB, "Transit Firm", "A3A3A3", "You are now on duty as a transit driver.");

    return true;
}

// /startmeter - starts the taxi meter.
CMD:startmeter(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    new vehicleid = GetPlayerVehicleID(playerid);

    if (!Transit_IsTaxiVehicle(vehicleid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You need to be in a Taxi or Cabbie.");
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You must be the driver.");
    }

    if (!Transit_IsOnService(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You are not on duty with a transit firm.");
    }

    if (PlayerVar[playerid][E_PLAYER_TAXIMETER])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "The meter is already running.");
    }

    GetPlayerPos(playerid, TransitLastPos[playerid][0], TransitLastPos[playerid][1], TransitLastPos[playerid][2]);
    TransitDistance[playerid] = 0;

    PlayerVar[playerid][E_PLAYER_TAXIMETER] = true;
    SendServerMessage(playerid, COLOR_JOB, "Transit Firm", "A3A3A3", "The meter is now on.");
    ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", "starts running the taxi meter.", false, true);

    return true;
}

// /stopmeter - stops the taxi meter.
CMD:stopmeter(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    new vehicleid = GetPlayerVehicleID(playerid);

    if (!Transit_IsTaxiVehicle(vehicleid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You need to be in a Taxi or Cabbie.");
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You must be the driver.");
    }

    if (!Transit_IsOnService(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "You are not on duty with a transit firm.");
    }

    if (!PlayerVar[playerid][E_PLAYER_TAXIMETER])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Transit Firm", "A3A3A3", "The meter isn't running.");
    }

    PlayerVar[playerid][E_PLAYER_TAXIMETER] = false;
    SendServerMessage(playerid, COLOR_JOB, "Transit Firm", "A3A3A3", "The meter is now off.");
    ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", "stops running the taxi meter.", false, true);

    return true;
}

hook OnPlayerExitVehicle(playerid, vehicleid)
{
    if (PlayerVar[playerid][E_PLAYER_TAXIDUTY])
    {
        Transit_StopService(playerid, true, vehicleid);
        Streamer_Update(playerid, STREAMER_TYPE_3D_TEXT_LABEL);
    }

    return true;
}
