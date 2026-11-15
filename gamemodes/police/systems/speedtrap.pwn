// ============================================================================
// File: police/systems/speedtrap.pwn
// /speedtrap: officers place a radar that records vehicles passing above a speed.
// Commands: /speedtrap
// ============================================================================

#include <YSI_Coding\y_hooks>

// Storage for trap state
new Float:gSpeedTrapX[MAX_PLAYERS];
new Float:gSpeedTrapY[MAX_PLAYERS];
new Float:gSpeedTrapZ[MAX_PLAYERS];
new gSpeedTrapArea[MAX_PLAYERS] = { -1, ... };

// Utility: 3D distance
Float:GetDistanceBetweenCoords(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    return floatsqroot((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1) + (z2 - z1)*(z2 - z1));
}

// /speedtrap - places or removes a radar speed trap that records vehicles passing too fast.
CMD:speedtrap(playerid, params[])
{
    // Toggle: if trap exists, destroy it
    if (gSpeedTrapArea[playerid] != -1)
    {
        DestroyDynamicArea(gSpeedTrapArea[playerid]);
        gSpeedTrapArea[playerid] = -1;
        SendServerMessage(playerid, COLOR_YELLOW, "Speed Trap", "A3A3A3", "Speed trap deactivated.");

        DisablePlayerCheckpoint(playerid);
        return 1;
    }

    if ( IsPlayerIncapacitated(playerid, false) ) 
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	if (!IsPlayerInLEAFaction(playerid, true))
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement." ) ;
	}

    if (Character[ playerid ] [ E_CHARACTER_FACTIONTIER ] > 3)
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You are unable to use this command." ) ;
	}

	if ( ! IsPlayerInAnyVehicle(playerid)) {

		return SendClientMessage(playerid, COLOR_ERROR, "You must be in a vehicle to use the speed trap.");
	}

    // Create trap at officer's current location
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    gSpeedTrapX[playerid] = x;
    gSpeedTrapY[playerid] = y;
    gSpeedTrapZ[playerid] = z;

    gSpeedTrapArea[playerid] = CreateDynamicSphere(x, y, z, 8.0); // Radius: 8.0
    SendServerMessage(playerid, COLOR_YELLOW, "Speed Trap", "A3A3A3", "Speed trap activated.");

    SetPlayerCheckpoint(playerid, x, y, z, 8.0); // Red checkpoint, radius 8.0
    return 1;
}

hook OnPlayerEnterDynamicArea(playerid, areaid)
{
    if (!IsPlayerInAnyVehicle(playerid)) return 1;

    new vehicleid = GetPlayerVehicleID(playerid);
    if (GetPlayerVehicleSeat(playerid) != 0) return 1; // 0 = driver seat

    // Find which officer owns this trap
    foreach (new officerid : Player)
    {
        if (gSpeedTrapArea[officerid] == areaid)
        {
            new Float:vx, Float:vy, Float:vz;
            GetVehicleVelocity(vehicleid, vx, vy, vz);
            new speed = floatround(floatsqroot(vx*vx + vy*vy + vz*vz) * 90); // MPH conversion

            new licenseplate[32];
            new veh_enum_id = Vehicle_GetEnumID(vehicleid);
	        format(licenseplate, sizeof(licenseplate), "%s", Vehicle[veh_enum_id][E_VEHICLE_LICENSE]);

            new msg[128];
            format(msg, sizeof(msg), "{FFFF00}Vehicle {FFFFFF}%s {FFFF00}entered the trap at {FFFFFF}%d {FFFF00}mph!", licenseplate, speed);
            SendServerMessage(officerid, COLOR_YELLOW, "Speed Trap", "A3A3A3", msg);

            // 🔊 Play sound effect for the officer
            PlayerPlaySound(officerid, 6400, 0.0, 0.0, 0.0); // Sound ID 1130 = radar beep
            break;
        }
    }
    return 1;
}

// Check if officer moved too far from their trap
hook OnPlayerUpdate(playerid)
{
    if(!IsPlayerPlaying( playerid )) return 1;

    if (gSpeedTrapArea[playerid] != -1)
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        new Float:dist = GetDistanceBetweenCoords(x, y, z, gSpeedTrapX[playerid], gSpeedTrapY[playerid], gSpeedTrapZ[playerid]);
        if (dist > 100.0)
        {
            DestroyDynamicArea(gSpeedTrapArea[playerid]);
            gSpeedTrapArea[playerid] = -1;
            SendServerMessage(playerid, COLOR_YELLOW, "Speed Trap", "A3A3A3", "Speed trap removed (you moved too far).");

            DisablePlayerCheckpoint(playerid);
        }
    }
    return 1;
}
