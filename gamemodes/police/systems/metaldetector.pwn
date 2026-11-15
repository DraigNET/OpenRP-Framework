// ============================================================================
// File: police/systems/metaldetector.pwn
// Metal detector gates: place them in the world, they sound an alarm when a player carrying a
// weapon walks through.
// ============================================================================

//------------------------------------------------------
// POLICE SYSTEM: METAL DETECTOR
//------------------------------------------------------

#include <YSI_Coding\y_hooks>

//------------------------------------------------------
// CONFIGURATION
//------------------------------------------------------

#define MAX_METAL_DETECTORS   (20)
#define METAL_DETECTOR_MODEL  (19302) // stock model; swap for a custom detector model if you add one
#define METAL_RANGE           (1.2)
#define METAL_COOLDOWN_MS     (5000)
#define METAL_DETECTOR_Y      (0.4695)

//------------------------------------------------------
// DATA STRUCTURE
//------------------------------------------------------

enum E_METAL_DETECTOR_DATA
{
    Float:mdX,
    Float:mdY,
    Float:mdZ,
    Float:mdRot,
    mdInterior,
    mdVW
};

//------------------------------------------------------
// ADD DETECTORS HERE
//------------------------------------------------------

new MetalDetectorData[][E_METAL_DETECTOR_DATA] =
{
    // City Hall (your existing one)
    {1522.189941, -1787.057983, 18.7355, 180.0, 0, 0}
};

//------------------------------------------------------
// RUNTIME STORAGE
//------------------------------------------------------

new MetalDetectorObjects[MAX_METAL_DETECTORS];
new metalCooldown[MAX_PLAYERS];
new metalStopTimer[MAX_PLAYERS];

//------------------------------------------------------
// INITIALIZE
//------------------------------------------------------

hook OnGameModeInit()
{
    LoadMetalDetectors();
    return 1;
}

// Creates the metal detector objects from the MetalDetectorData table.
stock LoadMetalDetectors()
{
    for(new i = 0; i < sizeof(MetalDetectorData); i++)
    {
        MetalDetectorObjects[i] = CreateDynamicObject(
            METAL_DETECTOR_MODEL,
            MetalDetectorData[i][mdX],
            MetalDetectorData[i][mdY],
            MetalDetectorData[i][mdZ]+METAL_DETECTOR_Y,
            0.0,
            0.0,
            MetalDetectorData[i][mdRot],
            MetalDetectorData[i][mdVW],
            MetalDetectorData[i][mdInterior],
            .priority = STREAM_PRIORITY_INTERACTABLE
        );
    }
    return 1;
}

//------------------------------------------------------
// WEAPON CHECKER
//------------------------------------------------------

// Returns true if the player is carrying any weapon.
stock Player_HasAnyWeapon(playerid)
{
    new idx, gunid, ammo;

    for(new i = 0; i < 12; i++)
    {
        idx = PlayerVar[playerid][E_PLAYER_WEAPON_EQUIPPED][i];
        GetPlayerWeaponData(playerid, i, gunid, ammo);

        if(idx != 0 && ammo > 0)
        {
            return 1;
        }
    }
    return 0;
}

//------------------------------------------------------
// DETECTION LOOP
//------------------------------------------------------

hook OnPlayerUpdate(playerid)
{
    if(GetTickCount() < metalCooldown[playerid])
        return 1;

    for(new i = 0; i < sizeof(MetalDetectorData); i++)
    {
        // Interior / VW check
        if(GetPlayerInterior(playerid) != MetalDetectorData[i][mdInterior])
            continue;

        if(GetPlayerVirtualWorld(playerid) != MetalDetectorData[i][mdVW])
            continue;

        if(IsPlayerInRangeOfPoint(
            playerid,
            METAL_RANGE,
            MetalDetectorData[i][mdX],
            MetalDetectorData[i][mdY],
            MetalDetectorData[i][mdZ]
        ))
        {
            if(Player_HasAnyWeapon(playerid))
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(playerid, name, sizeof(name));

                new msg[144];
                format(msg, sizeof(msg), "* The metal detector beeps loudly as %s passes through it.", name);

                ProxDetectorEx(playerid,10.0,0xFF4444FF, "ALERT",msg,false,false,false,false,true,false);
                MetalDetector_PlayAlarm(
                    MetalDetectorData[i][mdX],
                    MetalDetectorData[i][mdY],
                    MetalDetectorData[i][mdZ]
                );

                metalCooldown[playerid] = GetTickCount() + METAL_COOLDOWN_MS;
            }
            break;
        }
    }

    return 1;
}

forward MetalDetector_StopSound(playerid);

// Stops the alarm sound for a player.
public MetalDetector_StopSound(playerid)
{
    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
    metalStopTimer[playerid] = 0;
    return 1;
}

// Plays the metal detector alarm for players within range.
stock MetalDetector_PlayAlarm(Float:x, Float:y, Float:z)
{
    foreach (new i : Player)
    {
        if (IsPlayerInRangeOfPoint(i, 15.0, x, y, z))
        {
            PlayerPlaySound(i, 42801, x, y, z);

            // Cancel previous stop timer if exists
            if (metalStopTimer[i])
                KillTimer(metalStopTimer[i]);

            // Stop the looping sound after 3 sirens
            metalStopTimer[i] = SetTimerEx("MetalDetector_StopSound",2250,false,"i",i);
        }
    }
    return 1;
}
