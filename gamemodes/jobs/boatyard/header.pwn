// ============================================================================
// File: jobs/boatyard/header.pwn
// /freighttransport: load and unload boats at a harbour. Disabled by default.
// Commands: /freighttransport
// ============================================================================

#include "jobs/boatyard/data.pwn"

CMD:freighttransport(playerid, params[]) {
    #pragma unused params

    if (PlayerVar[playerid][E_PLAYER_BOATYARDJOB]) {
        SendClientMessage(playerid, COLOR_ERROR, "* You have cancelled the freight transport job.");
        AddLogEntry(playerid, LOG_TYPE_JOB, "cancelled the freight transport job.");
        FTJ_ResetPlayerState(playerid);
        return 1;
    }

    if (PlayerVar[playerid][E_PLAYER_BOATYARDJOB_TIMEOUT] > gettime() && GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
        new remaining = PlayerVar[playerid][E_PLAYER_BOATYARDJOB_TIMEOUT] - gettime();
        new cooldownStr[32];
        FormatCooldownTime(remaining, cooldownStr, sizeof(cooldownStr));
        new msg[128];
        format(msg, sizeof(msg), "You are on cooldown for this job. Try again in %s.", cooldownStr);
        return SendServerMessage(playerid, COLOR_JOB, "Freight Transport", "DEDEDE", msg);
    }

    if (!FTJ_IsPlayerInJobVehicle(playerid))
        return SendServerMessage(playerid, COLOR_JOB, "Freight Transport", "DEDEDE", "You must be inside and driving a freight transport vessel to start this job.");

    new veh_enum_id = Vehicle_GetEnumID(GetPlayerVehicleID(playerid));
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB] = true;
    PlayerVar[playerid][E_PLAYER_BOATYARDJOB_VEHICLE] = Vehicle[veh_enum_id][E_VEHICLE_ID];
    SetEngineStatus(Vehicle[veh_enum_id][E_VEHICLE_ID], true);
    AddLogEntry(playerid, LOG_TYPE_JOB, "started the freight transport job.");
    FTJ_SetStageLV(playerid);
    return 1;
}

FTJ_IsPlayerInJobVehicle(playerid) {
    new vehicleid = GetPlayerVehicleID(playerid);
    new veh_enum_id = Vehicle_GetEnumID(vehicleid);
    if (veh_enum_id == -1) return false;
    if (GetVehicleDriver(vehicleid) != playerid) return false;
    if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_JOB && Vehicle[veh_enum_id][E_VEHICLE_JOBID] == E_VEHICLE_JOB_BOATYARDJOB) return true;
    return false;
}

stock FTJ_IsJobVehicle(vehicleid) {
    new veh_enum_id = Vehicle_GetEnumID(vehicleid);
    if (veh_enum_id == -1) return false;
    if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_JOB && Vehicle[veh_enum_id][E_VEHICLE_JOBID] == E_VEHICLE_JOB_BOATYARDJOB) return true;
    return false;
}
