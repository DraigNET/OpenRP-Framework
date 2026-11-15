// ============================================================================
// File: injury/func.pwn
// Damage engine. The server owns all damage maths: validates shots, applies damage per body
// part and weapon (CalculateWeaponDamage, Damage_Apply), handles executions and logs suspicious
// desync.
// Commands: /testdeathanim
// ============================================================================


//   OnPlayerWeaponShot   - to validate shots before damage.
//   OnPlayerGiveDamage   - primary damage entry point, server owns all math.
//   OnPlayerTakeDamage   - env/edge cases only (explosions, fall, etc.)


#define DUMMY_HP                    (99.0)      // client always sees this (tested to prevent desyncs with armour)
#define MAX_WEAPON_RANGE            (120.0)     // hard cap for any weapon shot
#define AC_TRIGGER_WINDOW           (60)        // seconds before tick counter resets
#define AC_TRIGGER_THRESHOLD        (25)        // hits within window before ban
#define LEG_ANIM_COOLDOWN_MS        (3000)      // ms between leg collapse anims
#define EXECUTE_CD_MS               (3000)      // ms before execution is enabled

// https://github.com/NextGenerationGamingLLC/SA-MP-Development/blob/master/ICs/pawno/include/weapon-config.inc
// https://github.com/YashasSamaga/SAMP-Anti-Cheat/blob/master/source/WeaponInformation.h

forward Float:Gym_GetFightstyleDamageDelta(playerid, issuerid, Float:base_damage);

#define FIRERATE_PISTOL             (160)   
#define FIRERATE_SILENCED           (120)   
#define FIRERATE_DEAGLE             (120)   
#define FIRERATE_SHOTGUN            (800)   
#define FIRERATE_SAWEDOFF           (120)   
#define FIRERATE_SHOTGSPA           (120)   
#define FIRERATE_UZI                (50)    
#define FIRERATE_MP5                (90)    
#define FIRERATE_TEC9               (70)    
#define FIRERATE_AK47               (90)    
#define FIRERATE_M4                 (90)    
#define FIRERATE_SNIPER             (900)   
#define FIRERATE_RIFLE              (800)   
#define FIRERATE_KNIFE              (250)   
#define FIRERATE_DEFAULT            (200)   

const BULLET_SYNC = 206;
// Packet handler for bullet sync: checks for impossible bullets (for example from silent aim).
IPacket:BULLET_SYNC(playerid, BitStream:bs)
{
    new bulletData[PR_BulletSync];

    BS_IgnoreBits(bs, 8);
    BS_ReadBulletSync(bs, bulletData);

    new weaponid = bulletData[PR_weaponId];

    if (!(22 <= weaponid <= 38))
        return 0;

    new slot = GetWeaponSlot(weaponid);
    if (slot > 0 && Weapon[PlayerVar[playerid][E_PLAYER_WEAPON_EQUIPPED][slot]][E_WEAPON_GUNID] != weaponid)
    {
        new acstr[256];
        format(acstr, sizeof(acstr),
            "[Anticheat/RakNet]: (%d) %s fired weapon (%d) in slot %d, server expected (%d) - packet dropped.",
            playerid, ReturnRPName(playerid), weaponid, slot,
            Weapon[PlayerVar[playerid][E_PLAYER_WEAPON_EQUIPPED][slot]][E_WEAPON_GUNID]);
        SendAdminMessage(acstr, COLOR_ANTICHEAT);
        return 0; // bullet erased at network level
    }

    return 1; // legitimate shot, pass through to OnPlayerWeaponShot
}

new legShotTime[MAX_PLAYERS];
new bool:legShotCooldown[MAX_PLAYERS];

new lastShotTick[MAX_PLAYERS];


// Called when a player fires a weapon: checks the fire rate and ammo and blocks invalid shots.
public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ) {
    #pragma unused hitid

    if (!IsPlayerLogged(playerid) || !IsPlayerPlaying(playerid)) return 0;
    if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]) return 1;

    if (!CanPlayerUseGuns(playerid, 8, weaponid)) {
        if (weaponid != 0 && weaponid != 49 && weaponid != 41 && weaponid != 50) {
            AC_LogAndMitigate(playerid, weaponid, "fired unverified weapon");
            return 0;
        }
    }

    new idx = GetPlayerCustomWeapon(playerid);
    if (idx == -1) {
        AC_DesyncLog(playerid, "OnPlayerWeaponShot: custom weapon idx = -1, shot cancelled");
        return 0;
    }

    if (GetPlayerWeapon(playerid) != Weapon[idx][E_WEAPON_GUNID]) {
        AC_DesyncLog(playerid, "OnPlayerWeaponShot: weapon mismatch, shot cancelled");
        PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_WARNING]++;
        return 0;
    }

    new currentTick = GetTickCount();
    new minInterval = Weapon_GetFireRateLimit(weaponid);
    minInterval = floatround(float(minInterval) * 0.85); // allow 15% leniency for network variance
    new elapsed = GetTickDiff(currentTick, lastShotTick[playerid]);

    if (lastShotTick[playerid] != 0 && elapsed < minInterval) {
        new string[128];
        format(string, sizeof(string),
            "[AntiCheat]: (%d) %s firing too fast (WepID: %d, interval: %dms, min: %dms).",
            playerid, ReturnRPName(playerid), weaponid, elapsed, minInterval);
        SendAdminMessage(string, COLOR_ANTICHEAT);
        return 0;
    }

    lastShotTick[playerid] = currentTick;

    return 1;
}

// Called when a player damages another: the server works out the real damage by weapon, distance
// and body part.
public OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid, bodypart) {

    if (PlayerVar[damagedid][E_PLAYER_ADMIN_DUTY]) return true;

    // Admin jail: nobody in a cell can be hurt, however they are attacked.
    if (IsPlayerInAdminJail(damagedid)) {
        Damage_SnapClientHealth(damagedid);
        return true;
    }

    if (!IsPlayerLogged(playerid) || !IsPlayerPlaying(playerid)) {
        new string[128];
        format(string, sizeof(string),
            "[AntiCheat]: Kicked (%d) %s for damaging while not logged in!",
            playerid, ReturnRPName(playerid));
        SendAdminMessage(string, COLOR_ANTICHEAT);
        Kick(playerid);
        return true;
    }

    if (playerid != damagedid) {
        PlayerLastCombatAt[playerid]  = gettime();
        PlayerLastCombatAt[damagedid] = gettime();
    }

    if (PlayerVar[playerid][E_PLAYER_TASER_EQUIPPED] && weaponid == WEAPON_SILENCED) {
        Tazer_OnPlayerGiveDamage(playerid, damagedid, weaponid);
        return true;
    }

    if (PlayerVar[playerid][E_PLAYER_BEANBAG_EQUIPPED] && weaponid == WEAPON_SHOTGUN) {
        Beanbag_OnPlayerGiveDamage(playerid, damagedid, weaponid);
        return true;
    }

    if (PlayerVar[playerid][E_PLAYER_TACKLE_ACTIVE] && weaponid == WEAPON_UNARMED) {
        Tackle_OnPlayerGiveDamage(playerid, damagedid, weaponid);
        return true;
    }

    if (PlayerVar[damagedid][E_PLAYER_INJUREDMODE]) {
        Damage_HandleExecution(playerid, damagedid, weaponid);
        return true;
    }

    switch (weaponid) {
        case 42, 49, 50, 51, 53, 54, 255: {
            Damage_SnapClientHealth(damagedid);
            return true;
        }
    }

    if (weaponid == WEAPON_SPRAYCAN) {
        Damage_ApplySpraycan(playerid, damagedid);
        return true;
    }

    if (weaponid == WEAPON_KNIFE) {
        new idx = GetPlayerCustomWeapon(playerid);
        if (idx == -1 || Weapon[idx][E_WEAPON_GUNID] != WEAPON_KNIFE) {
            new string[128];
            format(string, sizeof(string),
                "[AntiCheat]: (%d) %s used knife without having one. Spectate!",
                playerid, ReturnRPName(playerid));
            SendAdminMessage(string, COLOR_ANTICHEAT);
            PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_WARNING]++;

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            PauseAC(playerid, 3);
            SetPlayerPos(playerid, x, y, z + 4);
            PlayerPlaySound(playerid, 1190, x, y, z);
            SendClientMessage(damagedid, COLOR_RED,
                "Failed to sync clientside knife with serverside knife.");
            return true;
        }
        KnifeSync_OnPlayerTakeDamage(damagedid, playerid, amount, weaponid);
        return true;
    }

    new bool:isMelee = (weaponid >= 0 && weaponid <= 8) || (weaponid >= 10 && weaponid <= 15);

    if (isMelee)
    {
        if (IsPlayerKnockedOut(damagedid))
        {
            // victim KO'd by melee, stop damage here to prevent execution
            return true;
        }

        new Float:hp = GetCharacterHealth(damagedid);
        if (hp <= KO_HP_THRESHOLD)
        {
            KO_ApplyAnimation(damagedid);
            KO_TriggerKnockout(damagedid, playerid);
            SendClientMessage(damagedid, COLOR_INJURY, "* Use /showinjuries to see how you're hurt and roleplay accordingly.");
            return true;
        }
    }
    else if (IsPlayerKnockedOut(damagedid))
    {
        // any weapon (not melee) hitting a KO'd player -> execution
        KO_ResetPlayer(damagedid);
        OnPlayerInjuryMode(damagedid, playerid, DEATHTYPE_WEAPON, weaponid);
        return true;
    }
    
    Damage_Apply(playerid, damagedid, weaponid, bodypart); // core damage application

    return true;
}

// Called when a player takes damage from the environment (fall, fire, explosion) or an unknown
// source.
public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart) {

    if (issuerid != INVALID_PLAYER_ID) {
        Damage_SnapClientHealth(playerid);
        return true;
    }

    if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]) {
        PauseAC(playerid, 3);
        SetPlayerHealth(playerid, 100.0);
        return true;
    }

    if (IsPlayerInAdminJail(playerid)) {
        Damage_SnapClientHealth(playerid);
        return true;
    }

    if (GetPlayerState(playerid) == PLAYER_STATE_DRIVER ||
        GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) {
        new vehmodel = GetVehicleModel(GetPlayerVehicleID(playerid));
        if (vehmodel == 601 || vehmodel == 528 || vehmodel == 432) return true;
    }

    new string[128];
    format(string, sizeof(string),
        "[DESYNC-LOG]: (%d) %s took %.1f env damage (WepID: %d). ServerHP was %.1f.",
        playerid, ReturnRPName(playerid), amount,
        weaponid, Character[playerid][E_CHARACTER_HEALTH]);
    // SendAdminMessage(string, COLOR_ANTICHEAT, false); // uncomment to debug

    new Float:fCurrentHealth = GetCharacterHealth(playerid);
    new Float:fCurrentArmour = GetCharacterArmour(playerid);

    Damage_ApplyRaw(playerid, INVALID_PLAYER_ID, amount, weaponid, bodypart, fCurrentHealth, fCurrentArmour);

    return true;
}

// damage calculation, armour math, wound tracking, injury mode trigger.
stock Damage_Apply(issuerid, playerid, weaponid, bodypart) {

    new Float:fCurrentHealth = GetCharacterHealth(playerid);
    new Float:fCurrentArmour = GetCharacterArmour(playerid);

    // calculate final damage entirely server-side
    new Float:damage = CalculateWeaponDamage(playerid, issuerid, weaponid, bodypart);

    if (GetPlayerState(issuerid) == PLAYER_STATE_PASSENGER)
        damage *= 0.66;

    if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE] == E_DRUG_TYPE_METH && Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
        damage *= (1.0 - Meth[Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]][E_METH_DAMAGE_REDUCTION]);

    if (Character[issuerid][E_CHARACTER_DRUG_EFFECT_TYPE] == E_DRUG_TYPE_COKE && Character[issuerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
        damage += Cocaine[Character[issuerid][E_CHARACTER_DRUG_EFFECT_PARAM]][E_COKE_EXTRA_DAMAGE];

    if (damage < (fCurrentArmour + fCurrentHealth))
        LogDamageGiven(playerid, issuerid, damage, bodypart);

    PlayerVar[playerid][E_PLAYER_BRAWL_STOPANIM_ABUSE] = gettime() + 10;
    if (PlayerVar[playerid][E_PLAYER_LOOPING_ANIM]) {
        if (GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) ClearAnimations(playerid);
        PlayerVar[playerid][E_PLAYER_LOOPING_ANIM] = 0;
    }

    if (PlayerVar[playerid][E_PLAYER_LOGOUT_TICK] != 0) {
        PlayerVar[playerid][E_PLAYER_LOGOUT_DMG] = true;
        PlayerVar[playerid][E_PLAYER_LOGOUT_TICK] = 30;
    }

    if (PlayerVar[playerid][E_PLAYER_RELEASEME_TICK] != 0) {
        PlayerVar[playerid][E_PLAYER_RELEASEME_DMG] = true;
        PlayerVar[playerid][E_PLAYER_RELEASEME_TICK] = 30;
    }

    Damage_ApplyRaw(playerid, issuerid, damage, weaponid, bodypart,
        fCurrentHealth, fCurrentArmour);
}


// mutation layer, takes precalculated damage and applies it to armour first, then health. Handles injury mode transition.

stock Damage_ApplyRaw(playerid, issuerid, Float:damage, weaponid, bodypart,
    Float:fCurrentHealth, Float:fCurrentArmour) {

    if (fCurrentArmour > 0.0) {

        new idx = GetPlayerCustomWeapon(issuerid);
        if (bodypart != BODY_PART_HEAD && issuerid != INVALID_PLAYER_ID && idx != -1) {
            new ammo_const = Weapon[idx][E_WEAPON_AMMO];
            if (PlayerVar[playerid][E_PLAYER_KEVLAR_MODIFIER] > 0) {
                damage *= PlayerVar[playerid][E_PLAYER_KEVLAR_MODIFIER];
            } else if ((ammo_const == AMMO_TYPE_A && bodypart == BODY_PART_TORSO) ||
                       PlayerVar[playerid][E_PLAYER_SWAT_ACTIVE]) {
                damage *= 0.75;
            }
        }

        fCurrentArmour -= damage;

        if (fCurrentArmour <= 0.0) {
            new Float:leftover = -fCurrentArmour; // damage that bled through armour
            if (leftover > 0.0) {
                fCurrentHealth -= leftover;
            }
            fCurrentArmour = 0.0;
            PlayerVar[playerid][E_PLAYER_ADMIN_ARMOUR] = false;
        }

        PauseAC(playerid, 3);
        SetCharacterArmour(playerid, fCurrentArmour);

        if (fCurrentArmour == 0.0 && fCurrentHealth <= 0.0) {
            Damage_TriggerInjury(playerid, issuerid, weaponid);
            return;
        }

        PauseAC(playerid, 3);
        SetCharacterHealth(playerid, fCurrentHealth);
        Damage_SnapClientHealth(playerid);
        return;
    }

    // no armour, apply directly to health
    fCurrentHealth -= damage;

    if (issuerid != INVALID_PLAYER_ID) {
        SetPlayerWound(playerid, weaponid, bodypart, damage, issuerid);
    }

    new query[128];
    if (issuerid != INVALID_PLAYER_ID) {
        Character[playerid][E_CHARACTER_RECENT_DAMAGE] = gettime() + 600;
        mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_recentdamage = %d WHERE player_id = %d", Character[playerid][E_CHARACTER_RECENT_DAMAGE], Character[playerid][E_CHARACTER_ID]);
        mysql_tquery(mysql, query);
    }

    if (fCurrentHealth <= 0.0) {
        Damage_TriggerInjury(playerid, issuerid, weaponid);
        return;
    }

    PauseAC(playerid, 3);
    SetCharacterHealth(playerid, fCurrentHealth);
    Damage_SnapClientHealth(playerid);

    Damage_HandleLegShot(playerid, bodypart);
}

// Puts a player into injury mode after their health runs out.
stock Damage_TriggerInjury(playerid, issuerid, weaponid) {
    PlayerVar[playerid][E_PLAYER_IS_TAZED]    = false;
    PlayerVar[playerid][E_PLAYER_IS_BEANBAGGED] = false;
    PlayerVar[playerid][E_PLAYER_IS_TACKLED]  = false;
    TogglePlayerControllable(playerid, false);
    OnPlayerInjuryMode(playerid, issuerid, DEATHTYPE_WEAPON, weaponid);
    PauseAC(playerid, 3);
    SetCharacterHealth(playerid, 25.0);
    Damage_SnapClientHealth(playerid);
}

// Handles the 'execute' action on an injured player.
stock Damage_HandleExecution(playerid, damagedid, weaponid) {
    #pragma unused weaponid
    if (PlayerVar[damagedid][E_PLAYER_INJURED_EXECUTE_CD]) return;

    PlayerVar[damagedid][E_PLAYER_INJURY_TICK] = 0;

    new gun_name[32], gun_reason[32];
    new gunid = GetPlayerCustomWeapon(playerid);
    Weapon_GetGunName(gunid, gun_name, sizeof(gun_name));
    Weapon_GetGunReason(gunid, gun_reason, sizeof(gun_reason));

    if (!PlayerVar[damagedid][E_PLAYER_EXECUTE_MSG]) {
        SendAdminMessage(
            sprintf("[EXECUTION] (%d) %s has executed (%d) %s with a (%d) %s.",
                playerid, ReturnRPName(playerid),
                damagedid, ReturnRPName(damagedid),
                gunid, gun_name),
            COLOR_ANTICHEAT);

        AddLogEntry(damagedid, LOG_TYPE_DAMAGE,
            sprintf("Was executed by %s (%d) with %s",
                ReturnRPName(playerid), playerid, gun_reason),
            true);

        AddLogEntry(playerid, LOG_TYPE_DAMAGE,
            sprintf("Executed %s (%d) with %s",
                ReturnRPName(damagedid), damagedid, gun_reason),
            true);

        PlayerVar[damagedid][E_PLAYER_EXECUTE_MSG] = true;
    }

    PauseAC(damagedid, 3);
    SetCharacterHealth(damagedid, 5.0);
    Damage_SnapClientHealth(damagedid);
}

// Applies leg-shot effects (limp, fall) when a bullet hits a leg.
stock Damage_HandleLegShot(playerid, bodypart) {
    if (bodypart != BODY_PART_LEFT_LEG && bodypart != BODY_PART_RIGHT_LEG) return;
    if (GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_DUCK)            return;

    if (!PlayerDamage[playerid][DAMAGE_LEGS]) {
        PlayerDamage[playerid][DAMAGE_LEGS] = true;
        legShotTime[playerid]     = GetTickCount();
        legShotCooldown[playerid] = false;

        SendServerMessage(playerid, COLOR_INJURY, "Injury", "A3A3A3",
            "Your legs have been injured. You may experience trouble walking.");
        AddLogEntry(playerid, LOG_TYPE_DAMAGE, "injured their legs");
        ApplyAnimation(playerid, "ped", "fall_collapse", 4.1, 0, 1, 1, 0, 0, 1);
        return;
    }

    new currentTick = GetTickCount();
    new interval    = GetTickDiff(currentTick, legShotTime[playerid]);

    if (interval >= LEG_ANIM_COOLDOWN_MS) {
        ApplyAnimation(playerid, "ped", "fall_collapse", 4.1, 0, 1, 1, 0, 0, 1);
        legShotTime[playerid]     = currentTick;
        legShotCooldown[playerid] = false;
    }
}

// Handles the spraycan used as a weapon.
stock Damage_ApplySpraycan(issuerid, playerid) {
    #pragma unused issuerid
    new Float:fCurrentHealth = GetCharacterHealth(playerid);

    PauseAC(playerid, 3);
    if ((fCurrentHealth - 1.0) >= 50.0) {
        SetCharacterHealth(playerid, fCurrentHealth - 1.0);
    } else {
        SetCharacterHealth(playerid, fCurrentHealth);
    }
    Damage_SnapClientHealth(playerid);
}

// Re-sends the server's health to the client so it can't be changed by cheats.
stock Damage_SnapClientHealth(playerid) {
    new Float:serverHP = GetCharacterHealth(playerid);
    new Float:clientHP = (serverHP > 1.0) ? serverHP : 1.0;

    PauseAC(playerid, 3);
    SetPlayerHealth(playerid, clientHP);
    // armour is already synced by SetCharacterArmour internally, we dont touch it here
}

// Logs a suspicious damage event for staff and blocks it.
stock AC_LogAndMitigate(playerid, weaponid, const reason[]) {
    new string[128];
    format(string, sizeof(string),
        "[AntiCheat]: (%d) %s %s (WepID: %d).",
        playerid, ReturnRPName(playerid), reason, weaponid);
    SendAdminMessage(string, COLOR_ANTICHEAT);

    PauseAC(playerid, 3);
    SetCharacterHealth(playerid, GetCharacterHealth(playerid));
    Damage_SnapClientHealth(playerid);

    if (PlayerVar[playerid][E_PLAYER_AC_MITIGATE_UNIX] <= gettime()) {
        PlayerVar[playerid][E_PLAYER_AC_MITIGATE_TICK] = 0;
        PlayerVar[playerid][E_PLAYER_AC_MITIGATE_UNIX] = gettime() + AC_TRIGGER_WINDOW;
    }

    if (++PlayerVar[playerid][E_PLAYER_AC_MITIGATE_TICK] >= AC_TRIGGER_THRESHOLD) {
        AC_BanPlayer(playerid, "Suspected Weapon Hacks");
        PlayerVar[playerid][E_PLAYER_AC_MITIGATE_TICK] = 0;
        PlayerVar[playerid][E_PLAYER_AC_MITIGATE_UNIX] = gettime();
    }
}

// Logs a desync-related damage event.
stock AC_DesyncLog(playerid, const message[]) {
    new string[192];
    format(string, sizeof(string), "[DESYNC-LOG]: (%d) %s - %s", playerid, ReturnRPName(playerid), message);
    // SendAdminMessage(string, COLOR_ANTICHEAT, false);
    #pragma unused string
}

// Bans a player for an obvious damage hack.
stock AC_BanPlayer(playerid, const reason_str[]) {
    new string[192], reason[64];
    new hours   = 99999;
    new unbants = gettime() + (hours * 3600);

    format(string, sizeof(string),"[AntiCheat]: (%d) %s is suspected of %s. Banning.", playerid, ReturnRPName(playerid), reason_str);
    SendAdminMessage(string, COLOR_ANTICHEAT);

    ProxDetectorEx(playerid, 45.0, COLOR_ORANGE, "[Anticheat]:", sprintf("[AntiCheat]: (%d) %s has been banned for %s.", playerid, ReturnRPName(playerid), reason_str));

    format(reason, sizeof(reason), "Anticheat Detection: %s", reason_str);
    SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, -1, ReturnDateTime());

    mysql_format(mysql, string, sizeof(string), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)", Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "Anticheat", reason, gettime(), unbants);
    mysql_tquery(mysql, string);

    format(string, sizeof(string), "banip %s", ReturnIP(playerid));
    SendRconCommand(string);
    KickPlayer(playerid);
}

// Returns the minimum time between shots for a weapon (fire rate limit).
stock Weapon_GetFireRateLimit(weaponid) {
    switch (weaponid) {
        case WEAPON_COLT45:         return FIRERATE_PISTOL;
        case WEAPON_SILENCED:       return FIRERATE_SILENCED;
        case WEAPON_DEAGLE:         return FIRERATE_DEAGLE;
        case WEAPON_SHOTGUN:        return FIRERATE_SHOTGUN;
        case WEAPON_SAWEDOFF:       return FIRERATE_SAWEDOFF;
        case WEAPON_SHOTGSPA:       return FIRERATE_SHOTGSPA;
        case WEAPON_UZI:            return FIRERATE_UZI;
        case WEAPON_MP5:            return FIRERATE_MP5;
        case WEAPON_TEC9:           return FIRERATE_TEC9;
        case WEAPON_AK47:           return FIRERATE_AK47;
        case WEAPON_M4:             return FIRERATE_M4;
        case WEAPON_SNIPER:         return FIRERATE_SNIPER;
        case WEAPON_RIFLE:          return FIRERATE_RIFLE;
        case WEAPON_KNIFE:          return FIRERATE_KNIFE;
    }
    return FIRERATE_DEFAULT;
}

// Records damage a player gave in the damage log.
LogDamageGiven(playerid, killerid, Float:amount, bodypart) {
    new gun_name[32], gun_reason[32];
    new gunid = GetPlayerCustomWeapon(killerid);

    Weapon_GetGunName(gunid, gun_name, sizeof(gun_name));
    Weapon_GetGunReason(gunid, gun_reason, sizeof(gun_reason));

    AddLogEntry(playerid, LOG_TYPE_DAMAGE,
        sprintf("Was damaged by %s (%d) with %s (%0.3f damage at %s)",
            ReturnRPName(killerid), killerid, gun_reason,
            amount, GetBodyPartName(bodypart)));

    AddLogEntry(killerid, LOG_TYPE_DAMAGE,
        sprintf("Damaged %s (%d) with %s (%0.3f damage %s)",
            ReturnRPName(playerid), playerid, gun_reason,
            amount, GetBodyPartName(bodypart)));
}

// Starts injury mode when a player is killed: ragdoll, wounds, the wait to bleed out or be healed.
OnPlayerInjuryMode(playerid, killerid, deathtype, weaponid) {
    if (PlayerVar[playerid][E_PLAYER_INJUREDMODE]) return true;

    // Admin jail: can't be injured or killed (an admin kill still goes through).
    if (IsPlayerInAdminJail(playerid) && deathtype != DEATHTYPE_CUSTOM) {
        Damage_SnapClientHealth(playerid);
        return true;
    }

    if (PlayerVar[playerid][E_PLAYER_LOOPING_ANIM]) {
        PlayerVar[playerid][E_PLAYER_LOOPING_ANIM] = 0;
    }

    Minigame_ResetVariables(playerid);

    new gun_name[32], gun_reason[32];
    new gunid = GetPlayerCustomWeapon(killerid);

    if (deathtype == DEATHTYPE_CUSTOM) {
        SendAdminMessage(
            sprintf("[INJURED] (%d) %s admin-killed (%d) %s with \"%s\".",
                killerid, ReturnRPName(killerid),
                playerid, ReturnRPName(playerid),
                PlayerVar[playerid][E_PLAYER_INJURY_REASON]),
            COLOR_ANTICHEAT);
        SendClientMessage(playerid, COLOR_RED,
            sprintf("You've been injured by %s", PlayerVar[playerid][E_PLAYER_INJURY_REASON]));
    } else {
        Weapon_GetGunName(gunid, gun_name, sizeof(gun_name));
        Weapon_GetGunReason(gunid, gun_reason, sizeof(gun_reason));
        format(PlayerVar[playerid][E_PLAYER_INJURY_REASON], 64, "%s", gun_reason);

        SendAdminMessage(
            sprintf("[INJURED] (%d) %s has injured (%d) %s with a (%d) %s.",
                killerid, ReturnRPName(killerid),
                playerid, ReturnRPName(playerid),
                gunid, gun_name),
            COLOR_ANTICHEAT);

        SendClientMessage(playerid, COLOR_RED,
            sprintf("You've been injured with %s by %s (%d)",
                gun_reason, ReturnSettingsName(killerid, playerid), killerid));
    }

    Phone_ForceHidePhone(playerid);

    PlayerVar[playerid][E_PLAYER_INJURED_EXECUTE_CD] = true;
    PlayerVar[playerid][E_PLAYER_INJUREDMODE]        = true;
    PlayerVar[playerid][E_PLAYER_PHONE_DECLINE_CALL] = true;

    new INJURY_MODE_MIN_TIME = 180;
    new INJURY_MODE_MAX_TIME = 300;

    switch (weaponid) {
        case 2  .. 15:      INJURY_MODE_MAX_TIME = 450;
        case 22, 23, 24:    INJURY_MODE_MAX_TIME = 360;
        case 25, 26, 27:    INJURY_MODE_MAX_TIME = 300;
        case 28, 32:        INJURY_MODE_MAX_TIME = 300;
        case 29, 30, 31:    INJURY_MODE_MAX_TIME = 240;
        case 33, 34:        INJURY_MODE_MAX_TIME = 180;
    }

    if (IsPlayerInMetroTraining(playerid) || IsPlayerInSEBTraining(playerid)) {
        INJURY_MODE_MIN_TIME = 10;
        INJURY_MODE_MAX_TIME = 30;
    }

    PlayerVar[playerid][E_PLAYER_INJURY_TICK]     = INJURY_MODE_MAX_TIME;
    PlayerVar[playerid][E_PLAYER_INJURY_MIN_TICK] = INJURY_MODE_MIN_TIME;

    SendServerMessage(playerid, COLOR_INJURY, "Injury", "A3A3A3",
        sprintf("After %d seconds, you will be allowed to 'accept death' if nobody is interacting with you.",
            INJURY_MODE_MIN_TIME));
    SendServerMessage(playerid, COLOR_INJURY, "Injury", "A3A3A3",
        sprintf("If you do not, you will automatically pass out and be respawned after %d seconds.",
            INJURY_MODE_MAX_TIME));

    defer Injury_TickCountdown(playerid);

    if (playerid != killerid) {
        SendClientMessage(killerid, COLOR_RED,
            sprintf("You injured %s (%d) with %s.",
                ReturnSettingsName(playerid, killerid), playerid,
                PlayerVar[playerid][E_PLAYER_INJURY_REASON]));
    }

    PlayerVar[playerid][E_PLAYER_IS_BEANBAGGED]        = false;
    PlayerVar[playerid][E_PLAYER_IS_TAZED]             = false;
    PlayerVar[playerid][E_PLAYER_IS_TACKLED]           = false;
    PlayerVar[playerid][E_PLAYER_IS_TAZED_TIME]        = 0;
    PlayerVar[playerid][E_PLAYER_IS_BEANBAGGED_TIME]   = 0;

    AddLogEntry(playerid, LOG_TYPE_DAMAGE,
        sprintf("Was injured by %s (%d) with %s",
            ReturnRPName(killerid), killerid,
            PlayerVar[playerid][E_PLAYER_INJURY_REASON]));
    AddLogEntry(killerid, LOG_TYPE_DAMAGE,
        sprintf("Injured %s (%d) with %s",
            ReturnRPName(playerid), playerid,
            PlayerVar[playerid][E_PLAYER_INJURY_REASON]));

    TogglePlayerControllable(playerid, false);
    defer Injury_ApplyDeathAnimation(playerid, deathtype == DEATHTYPE_KNIFED, weaponid);
    defer Injury_RemoveExecuteCD(playerid);

    return true;
}

// Timer: lifts the cooldown that stops repeated executions.
timer Injury_RemoveExecuteCD[EXECUTE_CD_MS](playerid) {
    PlayerVar[playerid][E_PLAYER_INJURED_EXECUTE_CD] = false;
}

// Timer: plays the death animation after being shot (knifed deaths have their own).
timer Injury_ApplyDeathAnimation[500](playerid, knifed, weaponid) {
    new vehicleid = GetPlayerVehicleID(playerid);

    if (vehicleid) {
        new modelid = GetVehicleModel(vehicleid);
        new seat    = GetPlayerVehicleSeat(playerid);

        switch (modelid) {
            case 509, 481, 510, 462, 448, 581, 522,
                 461, 521, 523, 463, 586, 468, 471: {
                new Float:vx, Float:vy, Float:vz;
                GetVehicleVelocity(vehicleid, vx, vy, vz);
                JT_RemovePlayerFromVehicle(playerid);

                if (vx*vx + vy*vy + vz*vz >= 0.4) {
                    Injury_ApplyAnim(playerid, "PED", "BIKE_fallR", 0);
                } else {
                    Injury_ApplyAnim(playerid, "PED", "BIKE_fall_off", 0);
                }

                defer Injury_ApplyBikeAnimation[750](playerid, vehicleid);
            }
            default: {
                if (seat & 1) Injury_ApplyAnim(playerid, "PED", "CAR_dead_LHS");
                else          Injury_ApplyAnim(playerid, "PED", "CAR_dead_RHS");
            }
        }
        return;
    }

    // On foot
    if (knifed) {
        Injury_ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Damage", _, 5200);
        return;
    }

    switch (weaponid) {
        case WEAPON_DEAGLE: {
            ApplyAnimation(playerid, "PED",   "FLOOR_hit_f",       4.1, 0, 0, 0, 1, 0, 1);
        }
        case WEAPON_COLT45, WEAPON_SILENCED: {
            ApplyAnimation(playerid, "WUZI",  "CS_Dead_Guy",        4.1, 0, 0, 0, 1, 0, 1);
        }
        case WEAPON_SHOTGUN, WEAPON_SAWEDOFF, WEAPON_SHOTGSPA: {
            ApplyAnimation(playerid, "PED",   "FLOOR_hit_b",        4.1, 0, 0, 0, 1, 0, 1);
        }
        case WEAPON_M4, WEAPON_AK47, WEAPON_TEC9, WEAPON_UZI, WEAPON_MP5: {
            ApplyAnimation(playerid, "PED",   "FLOOR_hit_f",        4.1, 0, 0, 0, 1, 0, 1);
        }
        case WEAPON_SNIPER, WEAPON_RIFLE: {
            ApplyAnimation(playerid, "SWEET", "Sweet_injuredloop",  4.1, 0, 0, 0, 1, 0, 1);
        }
        default: {
            ApplyAnimation(playerid, "WUZI",  "CS_Dead_Guy",        4.1, 0, 0, 0, 1, 0, 1);
        }
    }
}

// Works out how much damage a weapon should do, from the weapon, the distance and the body part.
Float:CalculateWeaponDamage(playerid, issuerid, weaponid, bodypart) {
    #pragma unused bodypart

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    new Float:distance    = GetPlayerDistanceFromPoint(issuerid, x, y, z);
    new Float:damage      = SP_GetWeaponDamageFromDistance(weaponid, distance);
    new custom_gun        = GetPlayerCustomWeapon(issuerid);
    new Float:ammo_damage = Weapon_GetAmmoDamage(custom_gun);

    if (custom_gun == 67) ammo_damage = 9.0;   // PD deagle bonus
    else if (custom_gun == 64) ammo_damage = 0.0; // Emmet's colt nerf

    new Float:final_damage = damage;

    if (weaponid != 41) {
        final_damage += ammo_damage;
    }

    // Melee + cocaine bonus
    if (weaponid >= 0 && weaponid != 9 && weaponid < 15) {
        if (Character[issuerid][E_CHARACTER_DRUG_EFFECT_ACTIVE]) {
            if (Character[issuerid][E_CHARACTER_DRUG_EFFECT_TYPE] == E_DRUG_TYPE_COKE) {
                final_damage += Cocaine[Character[issuerid][E_CHARACTER_DRUG_EFFECT_PARAM]][E_COKE_EXTRA_DAMAGE];
            }
        }
        new Float:gym_delta = Gym_GetFightstyleDamageDelta(playerid, issuerid, final_damage);
        final_damage += gym_delta;
    }

    if (custom_gun == -1) final_damage = 0.0;

    return final_damage;
}

// Returns true if the player has been shot in the head enough to be critically wounded.
stock IsPlayerCriticallyWounded(playerid) {
    new headshot_count, Float:headshot_dmg;
    headshot_count = Wounds_GetWoundCount(playerid, BODY_PART_HEAD);
    Wounds_GetWoundDamage(playerid, BODY_PART_HEAD, headshot_dmg);
    #pragma unused headshot_count

    new torso_count, Float:torso_dmg;
    torso_count = Wounds_GetWoundCount(playerid, BODY_PART_TORSO) +
                  Wounds_GetWoundCount(playerid, BODY_PART_GROIN);
    Wounds_GetWoundDamage(playerid, BODY_PART_TORSO, torso_dmg);
    #pragma unused torso_count

    return PlayerVar[playerid][E_PLAYER_INJURY_TICK] <= 0 ||
           headshot_dmg > INJURY_CRITICAL_DMG_HEAD    ||
           torso_dmg    > INJURY_CRITICAL_DMG_TORSO;
}

// From Tramposo's fork, currently unnecessary
CMD:testdeathanim(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_DEVELOPER)
        return SendClientMessage(playerid, COLOR_RED, "* You don't have permission to use this command.");

    new option[32], weaponid;
    if (sscanf(params, "s[32]I(0)", option, weaponid)) {
        SendClientMessage(playerid, COLOR_YELLOW, "Usage: /testdeathanim [option] [weaponid]");
        SendClientMessage(playerid, COLOR_WHITE,  "Options:");
        SendClientMessage(playerid, COLOR_GREY,   "» knife   - Knife death animation");
        SendClientMessage(playerid, COLOR_GREY,   "» deagle  - Desert Eagle death");
        SendClientMessage(playerid, COLOR_GREY,   "» pistol  - Pistol deaths (COLT45/SILENCED)");
        SendClientMessage(playerid, COLOR_GREY,   "» shotgun - Shotgun deaths");
        SendClientMessage(playerid, COLOR_GREY,   "» rifle   - Rifle/automatic deaths");
        SendClientMessage(playerid, COLOR_GREY,   "» sniper  - Sniper rifle deaths");
        SendClientMessage(playerid, COLOR_GREY,   "» bike    - Bike fall (get on a bike first)");
        SendClientMessage(playerid, COLOR_GREY,   "» car     - Car death (get in a car first)");
        SendClientMessage(playerid, COLOR_GREY,   "» all     - Cycle through all animations");
        SendClientMessage(playerid, COLOR_GREY,   "» stop    - Stop current animation");
        return 1;
    }

    if (!strcmp(option, "knife", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing knife death animation...");
        Injury_ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Damage", _, 5200);
    }
    else if (!strcmp(option, "deagle", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing Desert Eagle death animation...");
        ApplyAnimation(playerid, "PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0, 1);
    }
    else if (!strcmp(option, "pistol", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing pistol death animation...");
        ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);
    }
    else if (!strcmp(option, "shotgun", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing shotgun death animation...");
        ApplyAnimation(playerid, "PED", "FLOOR_hit_b", 4.1, 0, 0, 0, 1, 0, 1);
    }
    else if (!strcmp(option, "rifle", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing rifle/automatic death animation...");
        ApplyAnimation(playerid, "PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0, 1);
    }
    else if (!strcmp(option, "sniper", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Testing sniper death animation...");
        ApplyAnimation(playerid, "SWEET", "Sweet_injuredloop", 4.1, 0, 0, 0, 1, 0, 1);
    }
    else if (!strcmp(option, "bike", true)) {
        new vehicleid = GetPlayerVehicleID(playerid);
        if (!vehicleid)
            return SendClientMessage(playerid, COLOR_RED, "* Get on a bike first!");

        new modelid = GetVehicleModel(vehicleid), isBike = false;
        switch (modelid) {
            case 509, 481, 510, 462, 448, 581, 522, 461, 521, 523, 463, 586, 468, 471:
                isBike = true;
        }
        if (!isBike)
            return SendClientMessage(playerid, COLOR_RED, "* You need to be on a motorcycle/bike!");

        SendClientMessage(playerid, COLOR_GREEN, "* Testing bike fall animation...");
        JT_RemovePlayerFromVehicle(playerid);

        new Float:vx, Float:vy, Float:vz;
        GetVehicleVelocity(vehicleid, vx, vy, vz);
        if (vx*vx + vy*vy + vz*vz >= 0.4) {
            Injury_ApplyAnim(playerid, "PED", "BIKE_fallR", 0);
            SendClientMessage(playerid, COLOR_YELLOW, "* High speed bike fall");
        } else {
            Injury_ApplyAnim(playerid, "PED", "BIKE_fall_off", 0);
            SendClientMessage(playerid, COLOR_YELLOW, "* Low speed bike fall");
        }
    }
    else if (!strcmp(option, "car", true)) {
        new vehicleid = GetPlayerVehicleID(playerid);
        if (!vehicleid)
            return SendClientMessage(playerid, COLOR_RED, "* Get in a car first!");

        new seat = GetPlayerVehicleSeat(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "* Testing car death animation...");
        if (seat & 1) {
            Injury_ApplyAnim(playerid, "PED", "CAR_dead_LHS");
            SendClientMessage(playerid, COLOR_YELLOW, "* Left side");
        } else {
            Injury_ApplyAnim(playerid, "PED", "CAR_dead_RHS");
            SendClientMessage(playerid, COLOR_YELLOW, "* Right side");
        }
    }
    else if (!strcmp(option, "all", true)) {
        SendClientMessage(playerid, COLOR_GREEN, "* Starting animation cycle...");
        SetPVarInt(playerid, "AnimTestCycle", 1);
        SetPVarInt(playerid, "AnimTestStep",  0);
        defer TestAnimationCycle[100](playerid);
    }
    else if (!strcmp(option, "stop", true)) {
        ClearAnimations(playerid);
        DeletePVar(playerid, "AnimTestCycle");
        DeletePVar(playerid, "AnimTestStep");
        SendClientMessage(playerid, COLOR_GREEN, "* Stopped.");
    }
    else if (weaponid > 0) {
        SendClientMessage(playerid, COLOR_GREEN,
            sprintf("* Testing death animation for weapon ID %d...", weaponid));
        switch (weaponid) {
            case WEAPON_DEAGLE: {
                ApplyAnimation(playerid, "PED",   "FLOOR_hit_f",      4.1, 0, 0, 0, 1, 0, 1);
            }
            case WEAPON_COLT45, WEAPON_SILENCED: {
                ApplyAnimation(playerid, "WUZI",  "CS_Dead_Guy",       4.1, 0, 0, 0, 1, 0, 1);
            }
            case WEAPON_SHOTGUN, WEAPON_SAWEDOFF, WEAPON_SHOTGSPA: {
                ApplyAnimation(playerid, "PED",   "FLOOR_hit_b",       4.1, 0, 0, 0, 1, 0, 1);
            }
            case WEAPON_M4, WEAPON_AK47, WEAPON_TEC9, WEAPON_UZI, WEAPON_MP5: {
                ApplyAnimation(playerid, "PED",   "FLOOR_hit_f",       4.1, 0, 0, 0, 1, 0, 1);
            }
            case WEAPON_SNIPER, WEAPON_RIFLE: {
                ApplyAnimation(playerid, "SWEET", "Sweet_injuredloop", 4.1, 0, 0, 0, 1, 0, 1);
            }
            default: {
                ApplyAnimation(playerid, "WUZI",  "CS_Dead_Guy",       4.1, 0, 0, 0, 1, 0, 1);
            }
        }
    }

    return 1;
}

// Developer test timer that cycles through death animations.
timer TestAnimationCycle[3000](playerid) {
    if (!GetPVarInt(playerid, "AnimTestCycle")) return;

    new step = GetPVarInt(playerid, "AnimTestStep");
    switch (step) {
        case 0: {
            SendClientMessage(playerid, COLOR_BLUE, "→ Desert Eagle (FLOOR_hit_f)");
            ApplyAnimation(playerid, "PED",   "FLOOR_hit_f",       4.1, 0, 0, 0, 1, 0, 1);
        }
        case 1: {
            SendClientMessage(playerid, COLOR_BLUE, "→ Pistol (CS_Dead_Guy)");
            ApplyAnimation(playerid, "WUZI",  "CS_Dead_Guy",        4.1, 0, 0, 0, 1, 0, 1);
        }
        case 2: {
            SendClientMessage(playerid, COLOR_BLUE, "→ Shotgun (FLOOR_hit_b)");
            ApplyAnimation(playerid, "PED",   "FLOOR_hit_b",        4.1, 0, 0, 0, 1, 0, 1);
        }
        case 3: {
            SendClientMessage(playerid, COLOR_BLUE, "→ Sniper (Sweet_injuredloop)");
            ApplyAnimation(playerid, "SWEET", "Sweet_injuredloop",  4.1, 0, 0, 0, 1, 0, 1);
        }
        case 4: {
            SendClientMessage(playerid, COLOR_BLUE, "→ Knife (KILL_Knife_Ped_Damage)");
            Injury_ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Damage", _, 5200);
        }
        default: {
            SendClientMessage(playerid, COLOR_GREEN, "* Cycle complete.");
            ClearAnimations(playerid);
            DeletePVar(playerid, "AnimTestCycle");
            DeletePVar(playerid, "AnimTestStep");
            return;
        }
    }

    SetPVarInt(playerid, "AnimTestStep", step + 1);
    defer TestAnimationCycle[3000](playerid);
}

// Returns the extra damage a fighting style adds to a hit.
stock Float:Gym_GetFightstyleDamageDelta(playerid, issuerid, Float:base_damage) {
    new Float:delta = 0.0;

    switch (Character[issuerid][E_CHARACTER_FIGHTSTYLE]) {
        case FIGHT_STYLE_GRABKICK: delta += 1.0;
        case FIGHT_STYLE_BOXING:   delta += 1.25;
        case FIGHT_STYLE_KUNGFU:   delta += 2.0;
    }

    switch (Character[playerid][E_CHARACTER_FIGHTSTYLE]) {
        case FIGHT_STYLE_GRABKICK: delta -= 1.25;
        case FIGHT_STYLE_BOXING:   delta -= 1.0;
        case FIGHT_STYLE_KUNGFU:   delta -= 0.5;
    }


    if ((base_damage + delta) <= 1.0) {
        delta = 0.5 - base_damage;
    }

    return delta;
}
