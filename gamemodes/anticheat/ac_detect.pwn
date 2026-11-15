// ============================================================================
// File: anticheat/ac_detect.pwn
// Central anti-cheat handler. Receives detections from the client-check module and from the
// modules in anticheat/modules (AC_CheatDetected), decides whether to warn, kick or ban, and
// runs the once-a-second Anticheat_Tick. Also contains staff-only debugging commands for
// testing detections - do not give these to normal staff.
// Commands: /startrecording /uhhset /uwset /stoprecording /savemodels /saveremovebuildings /sq
// /forcecrash /phcheck
// ============================================================================

enum
{
    // new
    CHEAT_TYPE_AMMO_SOBEIT_HACK,
    CHEAT_TYPE_ARMOUR_HACK
};

// Wrapper around GetPlayerWeapon so the anti-cheat can later swap in its own weapon tracking.
AC_GetPlayerWeapon(playerid) {

    return GetPlayerWeapon(playerid);
}

forward OnPlayerCheatDetected( playerid, detection, params ) ;
// Callback from the cheat-detection plugin: logs the detection and bans the player when the
// detection type calls for it.
public OnPlayerCheatDetected( playerid, detection, params ) {

    new string [ 512 ], query [ 512 ], reason [ 64 ] ;

    new hours ; // 10 years
    new secs = hours * 3600 ;
    new unbants = gettime() + secs;

    switch ( detection ) {
        case CHEAT_TYPE_AMMO_SOBEIT_HACK: {

            switch ( GetPlayerWeapon ( playerid ) ) {

                case 0, WEAPON_BRASSKNUCKLE, WEAPON_GOLFCLUB, WEAPON_NITESTICK, WEAPON_KNIFE, WEAPON_BAT, WEAPON_SHOVEL, WEAPON_POOLSTICK,
                WEAPON_KATANA, WEAPON_CHAINSAW, WEAPON_CANE, WEAPON_SPRAYCAN, WEAPON_CAMERA: {
                    return true ;
                }
            }

            ProxDetectorEx(playerid, 20.0, COLOR_ORANGE, "[AntiCheat]:", "has been banned for ammo hacks.", .showid = true);
            SendAntiCheatMessage(string) ;

            format ( reason, sizeof ( reason ), "Anticheat Detection: Ammo Hacking" ) ;
            SetAdminRecord ( Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], Character [ playerid ] [ E_CHARACTER_ID ], -1337, ARECORD_TYPE_BAN, reason, -1, ReturnDateTime () ) ;

            
            mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
            Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], ReturnIP ( playerid ), "Anticheat", reason, gettime(), unbants);
            mysql_tquery(mysql, query);


            format ( string, sizeof ( string ),"banip %s", ReturnIP ( playerid ));
            SendRconCommand(string);

            KickPlayer ( playerid ) ;   
        }

    }

    return 1;
}


forward Anticheat_IsPlayerSynced(playerid) ;
// Returns true if the player's reported state matches what the server expects (vehicle,
// passenger, injured...). Used to skip checks when they are out of sync.
public Anticheat_IsPlayerSynced(playerid) {

    new vehicleid = GetPlayerVehicleID(playerid) ;

    if(GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) {
        if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {

            new Float: x, Float: y, Float: z ;
            GetPlayerPos(playerid, x, y, z ) ;

            JT_RemovePlayerFromVehicle(playerid);

            TogglePlayerControllable(playerid, false );
            SetPlayerPos(playerid, x, y, z);

            // Forcing death animation, UNDER the vehicle (if need be)
            defer Injury_AppendAnimAfterEject(playerid);

            return false ;
        }
    }

    // Is player in injury mode, OR dead...
    if ( IsPlayerInAnyVehicle(playerid) ) {

        // Kick the player out, re-append animation if necessary.
        if ( vehicleid != INVALID_VEHICLE_ID ) {

            if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {

                new Float: x, Float: y, Float: z ;
                GetPlayerPos(playerid, x, y, z ) ;

                JT_RemovePlayerFromVehicle(playerid);

                TogglePlayerControllable(playerid, false );
                SetPlayerPos(playerid, x, y, z);

                // Forcing death animation, UNDER the vehicle (if need be)
                defer Injury_AppendAnimAfterEject(playerid);

                return false ;
            }
        }
    }

    return true ;
}

// Runs every second for each player: checks armour, health, weapons and position against the
// server's values and flags mismatches.
Anticheat_Tick(playerid)
{
    new string[256];

    if (IsPlayerPaused(playerid))
        return true;

    if (!Anticheat_IsPlayerSynced(playerid))
        return true;

    // armour (server -> client)
    new Float:serverArmour = Character[playerid][E_CHARACTER_ARMOUR];
    new Float:clientArmour;
    GetPlayerArmour(playerid, clientArmour);


    if (PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_WARNING])
    {
        if (++PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_TICK] >= 150)
        {
            PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_TICK] = 0;
            PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_WARNING]--;
        }

        if (PlayerVar[playerid][E_PLAYER_SPOOFED_GUN_AC_WARNING] >= 3)
        {
            new reason[64];
            new hours = 87600;
            new unbants = gettime() + (hours * 3600);

            format(string, sizeof(string), "[AntiCheat]: (%d) %s suspected weapon spoofing. Banning.", playerid, ReturnRPName(playerid));
            SendAntiCheatMessage(string, COLOR_ANTICHEAT);

            ProxDetectorEx(playerid, 20.0, COLOR_ORANGE, "[AntiCheat]:", "has been banned for weapon spoofing.", .showid = true);

            format(reason, sizeof(reason), "Anticheat Detection: Weapon Hacks (Spoofed)");

            SetAdminRecord(
                Account[playerid][E_PLAYER_ACCOUNT_ID],
                Character[playerid][E_CHARACTER_ID],
                -1337, ARECORD_TYPE_BAN,
                reason, -1, ReturnDateTime());

            mysql_format(mysql, string, sizeof(string),
                "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
                Account[playerid][E_PLAYER_ACCOUNT_ID],
                Account[playerid][E_PLAYER_ACCOUNT_NAME],
                ReturnIP(playerid),
                "Anticheat",
                reason,
                gettime(),
                unbants);
            mysql_tquery(mysql, string);

            format(string, sizeof(string), "banip %s", ReturnIP(playerid));
            SendRconCommand(string);

            KickPlayer(playerid);
            return true;
        }
    }

    // Jetpack check
    if (GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
    {
        if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_BETA)
        {
            format(string, sizeof(string),
                "[AntiCheat]: (%d) %s used jetpack without permission.",
                playerid, ReturnRPName(playerid));
            SendAntiCheatMessage(string, COLOR_ANTICHEAT);

            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
        }
    }

    // validate armour
    if (IsPlayerPlaying(playerid))
    {
        if (serverArmour > 0.0)
        {
            new bool:isCrack = Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] && Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE] == E_DRUG_TYPE_CRACK;

            new bool:isLegitArmour = isCrack || PlayerVar[playerid][E_PLAYER_ADMIN_ARMOUR] ||
                IsPlayerInLEAFaction(playerid, true) ||
                IsPlayerInSecurityFaction(playerid, true) ||
                IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_DAI, FACTION_TYPE_GOV);

            if (!isLegitArmour)
            {
                format(string, sizeof(string),
                    "[AntiCheat]: (%d) %s has armour with no legitimate source (%.2f). Flagging.",
                    playerid, ReturnRPName(playerid), serverArmour);
                SendAntiCheatMessage(string, COLOR_ANTICHEAT);

                // strip it server AND client side
                PauseAC(playerid, 5);
                SetCharacterArmour(playerid, 0.0);

                if (++PlayerVar[playerid][E_PLAYER_ARMOR_AC_WARNING] >= 3)
                {
                    if (!IsAnyAdminOnline())
                    {
                        AC_BanPlayer(playerid, "Armour Hacks");
                    }
                }
            }
            else
            {
                // legitimate armour, just make sure client matches server
                if (floatabs(clientArmour - serverArmour) > 0.1)
                {
                    PauseAC(playerid, 3);
                    SetPlayerArmour(playerid, serverArmour);
                }
            }
        }
    }

    // ammo checks
    new synced_ammo = ORP_GetPlayerAmmo(playerid);
    new client_ammo = GetPlayerAmmo(playerid);
    new client_weapon = AC_GetPlayerWeapon(playerid);

    if (synced_ammo < 0 && GetPlayerWeapon(playerid) != 0)
    {
        format(string, sizeof(string),
            "[AntiCheat]: (%d) %s negative ammo (%d). Reset.",
            playerid, ReturnRPName(playerid), client_ammo);
        SendAntiCheatMessage(string, COLOR_ANTICHEAT);

        ORP_SetPlayerAmmo(playerid, client_weapon, 0);
    }

    if (synced_ammo > 9998)
    {
        new idx = GetPlayerCustomWeapon(playerid);
        if (idx != -1)
        {
            switch (Weapon[idx][E_WEAPON_GUNID])
            {
                case WEAPON_SPRAYCAN: return true;
            }
        }

        OnPlayerCheatDetected(playerid, CHEAT_TYPE_AMMO_SOBEIT_HACK, synced_ammo);
    }

    // Vehicle checks
    if (IsPlayerInAnyVehicle(playerid))
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        if (vehicleid != INVALID_VEHICLE_ID)
        {
            CheckVehicleColorMatches(vehicleid);
        }
    }

    return true;
}

// block mapstealers

// Honeypot: a command used by a known map-stealer cheat. Anyone who types it is kicked and staff
// are alerted.
CMD:startrecording(playerid, params[]){

    new string [ 192 ];
    format(string, sizeof(string), "[!!!] [AdmWarn] (%d) %s has just tried a common map stealer command. They have been kicked as a precaution.", playerid, ReturnRPName(playerid));
    SendAdminMessage(string);
    AddLogEntry ( playerid, LOG_TYPE_SCRIPT, "has been kicked for trying a map stealer command.");
    ProxDetectorEx(playerid, 45.0, COLOR_ORANGE, "[AntiCheat]:", "has been kicked by the anticheat.", .showid = true);
    Kick(playerid);
    return true;
}
// Honeypot: a command used by a known wall-hack cheat. Anyone who types it is kicked and staff
// are alerted.
CMD:uhhset(playerid, params[]){

    new string [ 192 ];
    format(string, sizeof(string), "[!!!] [AdmWarn] (%d) %s has just tried a common wall-hack command. They have been kicked as a precaution.", playerid, ReturnMixedName(playerid));
    SendAdminMessage(string);
    AddLogEntry ( playerid, LOG_TYPE_SCRIPT, "has been kicked for trying a wall-hack command.");
    ProxDetectorEx(playerid, 45.0, COLOR_ORANGE, "[AntiCheat]:", "has been kicked by the anticheat.", .showid = true);
    Kick(playerid);
    return true;
}
// Honeypot: a command used by a known wall-hack cheat. Anyone who types it is kicked and staff
// are alerted.
CMD:uwset(playerid, params[]){

    new string [ 192 ];
    format(string, sizeof(string), "[!!!] [AdmWarn] (%d) %s has just tried a common wall-hack command. They have been kicked as a precaution.", playerid, ReturnMixedName(playerid));
    SendAdminMessage(string);
    AddLogEntry ( playerid, LOG_TYPE_SCRIPT, "has been kicked for trying a wall-hack command.");
    ProxDetectorEx(playerid, 45.0, COLOR_ORANGE, "[AntiCheat]:", "has been kicked by the anticheat.", .showid = true);
    Kick(playerid);
    return true;
}
CMD:stoprecording(playerid, params[]){
    return cmd_startrecording(playerid, params);
}

CMD:savemodels(playerid, params[]){
    return cmd_startrecording(playerid, params);
}

CMD:saveremovebuildings(playerid, params[]){
    return cmd_startrecording(playerid, params);
}

// Anti Force Crash
CMD:sq(playerid) {
    new string [ 192 ];
    format(string, sizeof(string), "[!!!] [AdmWarn] (%d) %s has just tried a force crash command.", playerid, ReturnMixedName(playerid));
    SendAdminMessage(string);

    AddLogEntry ( playerid, LOG_TYPE_SCRIPT, "tried to force crash.");
    ProxDetectorEx(playerid, 45.0, COLOR_ORANGE, "[AntiCheat]:", "has just tried a common force crash command.", .showid = true);

    return true;
}

CMD:forcecrash(playerid) {
    return cmd_sq(playerid);
}

forward AC_CheatDetected(playerid, cheattype);
forward AC_OnIncomingRPC(playerid, rpcid);

// Called by the client-check module when it finds a cheat (s0beit, CLEO, SampFuncs,
// aimbot...). Warns staff and kicks or bans depending on the cheat type.
public AC_CheatDetected(playerid, cheattype)
{
    //printf("[AC GAMEMODE] Cheat detected for player %d, type: %d", playerid, cheattype);
    
    //new string[256];
    
    switch (cheattype)
    {
        case 0: // S0beit
        {
            /*
            new hours = 99999;
            new secs = hours * 3600;
            new unbants = gettime() + secs;
            new query[256];
            new reason[24] = "S0beit";
            mysql_escape_string(reason, reason, 64);
            mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
                Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "The Server", reason, gettime(), unbants);
            mysql_tquery(mysql, query);
            SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, hours, ReturnDateTime());
            format(query, sizeof(query), "banip %s", ReturnIP(playerid));
            SendRconCommand(query);
            */
            
            ZMsg_SendClientMessageToAll(0x740A03FF, sprintf("[AntiCheat]: %s was kicked for using a suspicious mod.", GetPlayerNameEx(playerid)));
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "Was kicked for using a suspicious mod. (SOBEIT) ");
            DCC_SendAntiCheatMessage(sprintf("%s was detected using S0beit.", ReturnPlayerName(playerid)));
            SetTimerEx("DelayedKick", 100, false, "i", playerid);
        }        
        case 1: // CLEO
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO!", playerid, ReturnPlayerName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 2: // CLEO
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO!", playerid, ReturnPlayerName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 3: // CLEO
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO!", playerid, ReturnPlayerName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 4: // CLEO / MoonLoader
        {
            //SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO / MoonLoader!", playerid, ReturnPlayerName(playerid)));
            //SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO / MoonLoader.");
            //SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 5: // CLEO / MoonLoader
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO / MoonLoader!", playerid, ReturnPlayerName(playerid)));
            SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO / MoonLoader.");
            //DCC_SendAntiCheatMessage(sprintf("%s was detected using CLEO / MoonLoader.", ReturnPlayerName(playerid)));
        }
        case 6: // CLEO
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using CLEO!", playerid, ReturnPlayerName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using CLEO.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 7: // SilentPatch
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using SilentPatch!", playerid, ReturnPlayerName(playerid)));
            SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using SilentPatch.");
            //SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 8: // SampFuncs
        {
            // new hours = 99999;
            // new secs = hours * 3600;
            // new unbants = gettime() + secs;
            // new query[256];
            // new reason[24] = "SampFuncs";

            // mysql_escape_string(reason, reason, 64);
            // mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
            //     Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "The Server", reason, gettime(), unbants);

            // mysql_tquery(mysql, query);
            // SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, hours, ReturnDateTime());

            // format(query, sizeof(query), "banip %s", ReturnIP(playerid));
            // SendRconCommand(query);
            // KickPlayer(playerid);
            
            // ZMsg_SendClientMessageToAll(0x740A03FF, sprintf("[AntiCheat]: %s was banned for using SampFuncs.", ReturnPlayerName(playerid)));
            // AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Was banned for using SampFuncs."));
            SetTimerEx("DelayedKick", 1000, false, "i", playerid);
            SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s was kicked for using SampFuncs!", playerid, ReturnRPName(playerid)));
            SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using SampFuncs. Remove it to avoid a ban.");
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "Was kicked for using SampFuncs.");
            DCC_SendAntiCheatMessage(sprintf("%s was detected using SampFuncs.", ReturnPlayerName(playerid)));

        }
        case 9: // SampFuncs
        {
            // new hours = 99999;
            // new secs = hours * 3600;
            // new unbants = gettime() + secs;
            // new query[256];
            // new reason[24] = "SampFuncs";

            // mysql_escape_string(reason, reason, 64);
            // mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
            //     Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "The Server", reason, gettime(), unbants);

            // mysql_tquery(mysql, query);
            // SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, hours, ReturnDateTime());

            // format(query, sizeof(query), "banip %s", ReturnIP(playerid));
            // SendRconCommand(query);
            // KickPlayer(playerid);
            
            // ZMsg_SendClientMessageToAll(0x740A03FF, sprintf("[AntiCheat]: %s was banned for using SampFuncs.", GetPlayerNameEx(playerid)));
            // AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("%s Was banned for using SampFuncs.", GetPlayerNameEx(playerid)));
            //SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s was kicked for using SampFuncs!", playerid, ReturnRPName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using SampFuncs. Remove it to avoid a ban.");
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "using SampFuncs.");
            //SetTimerEx("DelayedKick", 100, false, "i", playerid);
        }
        case 10: // S0beit
        {
            /*
            new hours = 99999;
            new secs = hours * 3600;
            new unbants = gettime() + secs;
            new query[256];
            new reason[24] = "S0beit";
            mysql_escape_string(reason, reason, 64);
            mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
                Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "The Server", reason, gettime(), unbants);
            mysql_tquery(mysql, query);
            SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, hours, ReturnDateTime());
            format(query, sizeof(query), "banip %s", ReturnIP(playerid));
            SendRconCommand(query);
            */
            
            ZMsg_SendClientMessageToAll(0x740A03FF, sprintf("[AntiCheat]: %s was kicked for using a suspicious mod.", GetPlayerNameEx(playerid)));
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "Was kicked for using a suspicious mod. (SOBEIT) ");
            SetTimerEx("DelayedKick", 1000, false, "i", playerid);
            DCC_SendAntiCheatMessage(sprintf("%s was detected using S0beit.", ReturnPlayerName(playerid)));
        }
        case 11: // Modified VorbisFile.dll
        {
            // SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using Modified VorbisFile.dll!", playerid, ReturnPlayerName(playerid)));
            // SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using Modified VorbisFile.dll.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
        }
        case 12: // UltraWH
        {
            SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using a suspicious mod/hack!", playerid, ReturnPlayerName(playerid)));
            SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using a suspicious mod. Contact an admin on Discord immediately to avoid a ban.");
            SendClientMessage(playerid, COLOR_ORANGE, "If you're unsure what's causing this, uninstall suspicious mods and try again.");
            SetTimerEx("DelayedKick", 1000, false, "i", playerid);
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "UltraWH/BulletTracer detection.");
            DCC_SendAntiCheatMessage(sprintf("%s was detected using UltraWH/Bullet Tracers.", ReturnPlayerName(playerid)));
        }
        case 13: // S0beit
        {
            /*
            new hours = 99999;
            new secs = hours * 3600;
            new unbants = gettime() + secs;
            new query[256];
            new reason[24] = "S0beit";
            mysql_escape_string(reason, reason, 64);
            mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
                Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "The Server", reason, gettime(), unbants);
            mysql_tquery(mysql, query);
            SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, hours, ReturnDateTime());
            format(query, sizeof(query), "banip %s", ReturnIP(playerid));
            SendRconCommand(query);
            */
            
            ZMsg_SendClientMessageToAll(0x740A03FF, sprintf("[AntiCheat]: %s was kicked for using a suspicious mod.", ReturnPlayerName(playerid)));
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "Was kicked for using a suspicious mod. (SOBEIT) ");
            KickPlayer(playerid);
            DCC_SendAntiCheatMessage(sprintf("%s was detected using S0beit.", ReturnPlayerName(playerid)));
        }
        case 14: // Silent Aim
        {
            SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s is using Silent Aim!", playerid, ReturnPlayerName(playerid)));
            //SendClientMessage(playerid, 0x740A03FF, "You have been flagged for using Silent Aim.");
            // SendClientMessage(playerid, COLOR_WHITE, "Any modification that grants you advantages over other players will get you banned.");
            AddLogEntry(playerid, LOG_TYPE_ADMIN, "Silent Aim detection.");
            DCC_SendAntiCheatMessage(sprintf("%s was detected using Silent Aim.", ReturnPlayerName(playerid)));
        }
    }
    return 1;
}

forward AC_OnFinishDetection(playerid);
// Called when the client-side cheat scan finishes: reminds the player that advantage mods are not
// allowed.
public AC_OnFinishDetection(playerid) {
    SendClientMessage(playerid, COLOR_WHITE, "");
    SendClientMessage(playerid, 0xBF4646FF, "[!!!] Any modification that grants you advantages over other players will get you banned.");
    return 1;
}

// Hook for incoming RPCs; currently allows everything.
public AC_OnIncomingRPC(playerid, rpcid)
{
    return 1;
}

// /phcheck [player] - checks whether a player's client looks like a mobile or modified client.
CMD:phcheck(playerid, params[])
{
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) 
        return SendClientMessage(playerid, 0x740A03FF, "You don't have permission to use this command!");
    
    new targetid;
    if(sscanf(params, "u", targetid)) 
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /phcheck [playerid]");
    
    if(!IsPlayerConnected(targetid)) 
        return SendClientMessage(playerid, 0x740A03FF, "Player is not connected!");

    // Get cheat history from the client-check module
    new cheathistory[15];
    for(new i = 0; i < 15; i++) cheathistory[i] = 0;
    
    // Use GetPVarInt to retrieve the data from the client-check module
    // The client-check module sets these PVars
    for(new i = 0; i < 15; i++)
    {
        cheathistory[i] = GetPVarInt(targetid, sprintf("AC_CheatHistory_%d", i));
    }
    
    new isMobile = GetPVarInt(targetid, "AC_IsMobile");

    new string[512];
    format(string, sizeof(string), "Cheat History for %s:\n\n", ReturnPlayerName(targetid));

    if(isMobile) strcat(string, "{00FF00}» Mobile Player\n\n");

    if(cheathistory[0] == 1) strcat(string, "{FF0000}» S0beit detected\n");
    if(cheathistory[1]== 1) strcat(string, "{FF0000}» CLEO detected\n");
    if(cheathistory[2]== 1) strcat(string, "{FF0000}» CLEO detected\n");
    if(cheathistory[3]== 1) strcat(string, "{FF0000}» CLEO detected\n");
    if(cheathistory[4]== 1) strcat(string, "{FF0000}» CLEO / MoonLoader detected\n");
    if(cheathistory[5]== 1) strcat(string, "{FF0000}» CLEO / MoonLoader detected\n");
    if(cheathistory[6]== 1) strcat(string, "{FF0000}» CLEO detected\n");
    if(cheathistory[7]== 1) strcat(string, "{FF0000}» SilentPatch detected\n");
    if(cheathistory[8]== 1) strcat(string, "{FF0000}» SampFuncs detected\n");
    if(cheathistory[9] == 1) strcat(string, "{FF0000}» SampFuncs detected\n");
    if(cheathistory[10] == 1) strcat(string, "{FF0000}» S0beit detected\n");
    if(cheathistory[11] == 1) strcat(string, "{FF0000}» Modified VorbisFile.dll detected\n");
    if(cheathistory[12] == 1) strcat(string, "{FF0000}» UltraWH detected\n");
    if(cheathistory[13] == 1) strcat(string, "{FF0000}» S0beit detected\n");
    if(cheathistory[14] == 1) strcat(string, "{FF0000}» Silent Aim detected\n");

    if(strlen(string) <= 45) strcat(string, "{00FF00}No cheats detected\n");

    ShowPlayerDialog(playerid, 9998, DIALOG_STYLE_MSGBOX, "Player Cheat History", string, "Close", "");
    return 1;
}
