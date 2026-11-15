// ============================================================================
// File: weapons/visible.pwn
// Shows carried weapons as holstered or slung objects on the player's body (Holster_Update).
// ============================================================================

#include <a_samp>
#include <YSI_Coding\y_hooks>

#define HOLSTER_SLOT E_ATTACH_INDEX_HOLSTER_LONGGUN
#define HOLSTER_UPDATE_MS 300

new HolsterTick[MAX_PLAYERS];
new HolsteredWeapon[MAX_PLAYERS];

// Returns true if a weapon is shown holstered on the player's body.
static stock bool:IsHolsterWeapon(weaponid)
{
    switch (weaponid)
    {
        case 25,        // Shotgun
             27,        // Combat Shotgun
             29,        // MP5
             30, 31,    // AK / M4
             33, 34:    // Rifles
            return true;
    }
    return false;
}

// Returns true if the player has this weapon with ammo.
static stock bool:PlayerHasWeaponWithAmmo(playerid, weaponid)
{
    new w, ammo;

    for (new i = 0; i < 13; i++)
    {
        GetPlayerWeaponData(playerid, i, w, ammo);
        if (w == weaponid && ammo > 0)
            return true;
    }
    return false;
}

// Returns the object model used to show a holstered weapon.
static stock GetHolsterModel(weaponid)
{
    switch (weaponid)
    {
        case 25..29: return 324 + weaponid;
        case 30: return 355;
        case 31: return 356;
        case 32: return 372;
        case 33, 34: return 324 + weaponid;
    }
    return 0;
}

// Removes the holstered weapon objects from a player.
static stock Holster_Clear(playerid)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, HOLSTER_SLOT))
        RemovePlayerAttachedObject(playerid, HOLSTER_SLOT);

    HolsteredWeapon[playerid] = 0;
    return 1;
}

// Updates which holstered weapons are shown on the player.
static stock Holster_Update(playerid)
{
    if (!IsPlayerConnected(playerid) || IsPlayerNPC(playerid))
        return 1;

    if (IsPlayerInAnyVehicle(playerid))
        return Holster_Clear(playerid);

    new held = GetPlayerWeapon(playerid);

    new best = 0;

    // Priority order (ignore what is currently held)
    // Rifles
    if (held != 31 && PlayerHasWeaponWithAmmo(playerid, 31)) best = 31;
    else if (held != 30 && PlayerHasWeaponWithAmmo(playerid, 30)) best = 30;
    else if (held != 34 && PlayerHasWeaponWithAmmo(playerid, 34)) best = 34;
    else if (held != 33 && PlayerHasWeaponWithAmmo(playerid, 33)) best = 33;

    // Shotguns
    else if (held != 27 && PlayerHasWeaponWithAmmo(playerid, 27)) best = 27;
    else if (held != 25 && PlayerHasWeaponWithAmmo(playerid, 25)) best = 25;

    // MP5 last
    else if (held != 29 && PlayerHasWeaponWithAmmo(playerid, 29)) best = 29;

    if (!best)
        return Holster_Clear(playerid);

    if (held == best)
        return Holster_Clear(playerid);

    if (HolsteredWeapon[playerid] == best)
        return 1;

    new model = GetHolsterModel(best);
    if (!model)
        return 1;

    switch (best)
    {
        case 25:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 349, 16,
                0.084126, 0.131737, 0.197423,
                176.984542, 92.569320, 14.483574,
                1.0, 1.0, 1.0);
        }
        case 26:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 350, 16,
                0.090676, 0.085271, -0.075131,
                0.000000, 289.166870, 355.209869,
                1.0, 1.0, 1.0);
        }
        case 27:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 351, 16,
                0.100795, 0.057224, -0.082939,
                180.000000, 243.483581, 180.000000,
                1.0, 1.0, 1.0);
        }
        case 28:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 352, 7,
                0.138560, -0.033982, -0.047630,
                281.671447, 276.618591, 4.068862,
                1.0, 1.0, 1.0);
        }
        case 29:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 353, 7,
                0.008329, -0.067031, -0.060214,
                289.865051, 17.391622, 7.667663,
                1.0, 1.0, 1.0);
        }
        case 30:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 355, 1,
                -0.130044, -0.127836, 0.025491,
                2.044970, 6.239807, 6.833646,
                1.0, 1.0, 1.0);
        }
        case 31:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 356, 16,
                0.019280, 0.118553, 0.396286,
                70.920410, 274.673919, 253.978057,
                1.0, 1.0, 1.0);
        }
        case 32:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 372, 7,
                0.056180, -0.008887, -0.007959,
                270.000000, 13.921591, 5.905599,
                1.0, 1.0, 1.0);
        }
        case 33:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 357, 16,
                0.000000, 0.110000, 0.420000,
                90.000000, 270.000000, 250.000000,
                1.0, 1.0, 1.0);
        }
        case 34:
        {
            SetPlayerAttachedObject(playerid, HOLSTER_SLOT, 358, 16,
                0.000000, 0.110000, 0.420000,
                90.000000, 270.000000, 250.000000,
                1.0, 1.0, 1.0);
        }
    }

    HolsteredWeapon[playerid] = best;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    Holster_Clear(playerid);
    HolsterTick[playerid] = 0;
    return 1;
}

hook OnPlayerUpdate(playerid)
{
    if (GetTickCount() - HolsterTick[playerid] >= HOLSTER_UPDATE_MS)
    {
        Holster_Update(playerid);
        HolsterTick[playerid] = GetTickCount();
    }
    return 1;
}
