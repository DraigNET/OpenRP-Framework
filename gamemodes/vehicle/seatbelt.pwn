// ============================================================================
// File: vehicle/seatbelt.pwn
// Seatbelts and helmets: crash injuries for occupants who are not wearing one.
// ============================================================================

// Crash injury for vehicle occupants not wearing a seatbelt/helmet.
//
// The seatbelt state (PlayerVar[][player_hasseatbelton]), the /seatbelt /sb
// command, the bike helmet attachment and the exit-clear all already live in
// vehicle/data/cmds/default.pwn and vehicle/data/native.pwn. This module only
// adds the missing penalty: a hard crash while unbelted applies injury.
//
// Detection is velocity based. Each occupant runs its own OnPlayerUpdate, so
// driver and passengers are each evaluated independently -- every unbelted
// occupant of the same crash takes injury, belted ones are skipped.

#include <YSI_Coding\y_hooks>

// Tuning. TRP_GetVehicleSpeed() ~= velocity magnitude * 90, so roughly:
//   ~30 = 60 km/h, ~45 = 90 km/h, ~60 = 120 km/h.
#define SEATBELT_CRASH_MIN_SPEED    (25)    // must have been going at least ~50 km/h
#define SEATBELT_CRASH_MIN_DELTA    (20)    // single-tick speed drop that counts as an impact
#define SEATBELT_CRASH_BASE_DAMAGE  (12.0)  // damage at the impact threshold
#define SEATBELT_CRASH_DAMAGE_SCALE (0.9)   // extra damage per speed unit over the threshold
#define SEATBELT_CRASH_MAX_DAMAGE   (70.0)  // a single crash can't outright kill
#define SEATBELT_CRASH_COOLDOWN     (2)     // seconds between crash injuries per player

// A teleport moves the player this many units or more in a single update. A real
// crash decelerates you in place (tiny position change), so anything above this is
// a warp (admin /tp, interior/property entry, ORP_SetVehiclePos, ...) and must
// never count as a crash. Normal fast driving is only a couple of units per tick,
// so this sits well clear of legitimate movement even under lag.
#define SEATBELT_TELEPORT_DIST      (80.0)

static g_SeatbeltLastSpeed[MAX_PLAYERS];
static g_SeatbeltCrashCD[MAX_PLAYERS];
static Float:g_SeatbeltLastPos[MAX_PLAYERS][3];

hook OnPlayerUpdate(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:moved = VectorSize(
        px - g_SeatbeltLastPos[playerid][0],
        py - g_SeatbeltLastPos[playerid][1],
        pz - g_SeatbeltLastPos[playerid][2]);

    new bool:teleported = (moved > SEATBELT_TELEPORT_DIST);

    g_SeatbeltLastPos[playerid][0] = px;
    g_SeatbeltLastPos[playerid][1] = py;
    g_SeatbeltLastPos[playerid][2] = pz;

    new pstate = GetPlayerState(playerid);

    if (pstate != PLAYER_STATE_DRIVER && pstate != PLAYER_STATE_PASSENGER)
    {
        g_SeatbeltLastSpeed[playerid] = 0;
        return 1;
    }

    new vehicleid = GetPlayerVehicleID(playerid);
    new speed     = TRP_GetVehicleSpeed(vehicleid);
    new lastspeed = g_SeatbeltLastSpeed[playerid];

    g_SeatbeltLastSpeed[playerid] = speed;

    // A warp can spike or zero velocity in one tick; never read that as a crash.
    // Speed is already stored above, so the next tick resumes clean.
    if (teleported) return 1;

    new delta = lastspeed - speed;

    // Only a sudden large deceleration from real speed counts as a crash.
    if (lastspeed < SEATBELT_CRASH_MIN_SPEED) return 1;
    if (delta < SEATBELT_CRASH_MIN_DELTA)     return 1;

    // Belted/helmeted occupants are protected.
    if (PlayerVar[playerid][player_hasseatbelton]) return 1;

    if (IsPlayerIncapacitated(playerid, false))    return 1;
    if (g_SeatbeltCrashCD[playerid] > gettime())   return 1;

    g_SeatbeltCrashCD[playerid] = gettime() + SEATBELT_CRASH_COOLDOWN;

    new Float:damage = SEATBELT_CRASH_BASE_DAMAGE + float(delta - SEATBELT_CRASH_MIN_DELTA) * SEATBELT_CRASH_DAMAGE_SCALE;
    if (damage > SEATBELT_CRASH_MAX_DAMAGE) damage = SEATBELT_CRASH_MAX_DAMAGE;

    // bodypart 3 = torso (injury module's BODY_PART_TORSO isn't in scope here)
    Damage_ApplyRaw(playerid, INVALID_PLAYER_ID, damage, WEAPON_COLLISION, 3,
        GetCharacterHealth(playerid), GetCharacterArmour(playerid));

    if (IsABike(vehicleid))
        SendServerMessage(playerid, COLOR_ERROR, "Crash", "A3A3A3", "You were hurt in the crash - you weren't wearing a helmet!");
    else
        SendServerMessage(playerid, COLOR_ERROR, "Crash", "A3A3A3", "You were hurt in the crash - you weren't wearing a seatbelt!");

    return 1;
}
