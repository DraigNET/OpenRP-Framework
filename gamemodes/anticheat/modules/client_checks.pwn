// ============================================================================
// File: anticheat/modules/client_checks.pwn
// Client memory checks, formerly a standalone filterscript. Results go directly to
// AC_CheatDetected in this gamemode. Memory addresses only apply to the listed clients;
// unknown client versions are skipped instead of probing invalid addresses.
// ============================================================================
#include <YSI_Coding\y_hooks>

#define MOBILE_CLIENT "ED40ED0E8089CC44C08EE9580F4C8C44EE8EE990"


new bool:ac_suspicious[MAX_PLAYERS];
new bool:ac_responded[MAX_PLAYERS];
new bool:ac_mobile[MAX_PLAYERS];
new ac_cheat_history[MAX_PLAYERS][15];
new ac_checksum[MAX_PLAYERS];
new ac_samp_addr[MAX_PLAYERS];


new ac_memory_addr[14];
static ac_scan_timer[MAX_PLAYERS];
static ac_kick_timer[MAX_PLAYERS];

enum ac_cheat_data
{
    ac_mem_addr,
    ac_expected_val,
    ac_cheat_val
}

new ac_memory[14][ac_cheat_data] =
{
    { 0x06865E, 192,  1  },   // [0]  S0beit
    { 0xA88774,  72,  2  },   // [1]  CLEO
    { 0xDB6746, 192,  3  },   // [2]  CLEO
    { 0xFDB957,  68,  4  },   // [3]  CLEO
    { 0x52D558, 196,  5  },   // [4]  CLEO / MoonLoader
    { 0xE4FC58,  64,  6  },   // [5]  CLEO / MoonLoader
    { 0x1BA246,   8,  7  },   // [6]  CLEO
    { 0xB0C56F, 200,  8  },   // [7]  SilentPatch
    { 0xF9855E, 200,  9  },   // [8]  SampFuncs
    { 0x910152, 204, 10  },   // [9]  SampFuncs
    { 0xC7FB6E, 196, 11  },   // [10] S0beit
    { 0xF4C853, 132, 12  },   // [11] Modified VorbisFile.dll
    { 0xB47E74, 132, 13  },   // [12] UltraWH
    { 0x242C52, 192, 14  }    // [13] S0beit
};

new ac_mem_offsets[9] = {
    0x0, 0x2, 0x4,
    0x6, 0x8, 0xA,
    0xC, 0xE, 0x10
};

new ac_samp_address[] = {
    0x41B04,  // 0.3.DL-R1
    0x42044,  // 0.3.7-R5
    0x41FF4,  // 0.3.7-R4
    0x41904   // 0.3.7-R3
};

enum ac_join_data
{
    ac_version,
    ac_mod,
    ac_nick_len,
    ac_nickname[24],
    ac_challenge,
    ac_auth_len,
    ac_auth_key[50],
    ac_client_ver_len,
    ac_client_version[30]
};

forward ClientAC_FinishScan(playerid);
forward AC_RunScan(playerid);
forward ClientAC_KickDelayed(playerid);

// Reorders address bytes to match the checksum returned by the client.
stock ac_reverse_address(input)
{
    new result;

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF
    #emit AND
    #emit CONST.alt 16
    #emit SHL
    #emit STOR.S.pri result

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF00
    #emit AND
    #emit LOAD.S.alt result
    #emit ADD
    #emit STOR.S.pri result

    #emit LOAD.S.pri input
    #emit CONST.alt 0xFF0000
    #emit AND
    #emit CONST.alt 16
    #emit SHR
    #emit LOAD.S.alt result
    #emit ADD
    #emit STOR.S.pri result

    return result;
}

// Requests a version-specific client integrity check.
stock ac_check_client(playerid)
{
    new version[24], samp_addr;
    GetPlayerVersion(playerid, version, sizeof(version));

    new rand_index = random(sizeof(ac_mem_offsets));
    new samp_offset = ac_mem_offsets[rand_index];

    if (strcmp(version, "0.3.DL-R1", true) == 0) samp_addr = ac_samp_address[0];
    else if (strcmp(version, "0.3.7-R5", true) == 0) samp_addr = ac_samp_address[1];
    else if (strcmp(version, "0.3.7-R4", true) == 0) samp_addr = ac_samp_address[2];
    else if (strcmp(version, "0.3.7-R3", true) == 0) samp_addr = ac_samp_address[3];

    if (!samp_addr) return 0;
    SendClientCheck(playerid, 0x45, samp_addr - samp_offset, samp_offset, 0x4);
    ac_samp_addr[playerid] = samp_addr - samp_offset;

    return 1;
}

// Cancels timers and clears stored results before a player slot is reused.
stock ac_reset_player(playerid)
{
    if (ac_scan_timer[playerid]) KillTimer(ac_scan_timer[playerid]);
    if (ac_kick_timer[playerid]) KillTimer(ac_kick_timer[playerid]);
    ac_scan_timer[playerid] = 0;
    ac_kick_timer[playerid] = 0;
    DeletePVar(playerid, "AC_IsMobile");
    for (new i; i < 15; i++) DeletePVar(playerid, sprintf("AC_CheatHistory_%d", i));
    ac_suspicious[playerid]  = false;
    ac_responded[playerid]   = false;
    ac_mobile[playerid]      = false;
    ac_checksum[playerid]    = -1;
    ac_samp_addr[playerid]   = 0x0;

    for (new i = 0; i < 15; i++)
        ac_cheat_history[playerid][i] = -1;
}

// Copies the recorded detection history into the caller's array.
stock AC_GetPlayerCheatHistory(playerid, cheathistory[], size = sizeof(cheathistory))
{
    if (playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    if (size < 15) return 0;

    for (new i = 0; i < 15; i++)
        cheathistory[i] = ac_cheat_history[playerid][i];

    return 1;
}

// Returns whether the join handshake identified the mobile client.
stock AC_IsMobilePlayer(playerid)
{
    if (playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    return ac_mobile[playerid];
}

// Precompute address checksums and clear the per-player scan state at startup.
hook OnGameModeInit()
{
    for (new i; i < sizeof(ac_memory); i++)
        ac_memory_addr[i] = ac_reverse_address(ac_memory[i][ac_mem_addr]);
    for (new i; i < MAX_PLAYERS; i++) ac_reset_player(i);
    return 1;
}

// Validates the join handshake without discarding the checksum captured by the join RPC.
hook OnPlayerConnect(playerid)
{
    // The join RPC has already reset state and captured the mobile checksum.
    new auth[43];
    gpci(playerid, auth, sizeof(auth));

    if (!strcmp(MOBILE_CLIENT, auth, true))
    {
        if (ac_checksum[playerid] == 0xBEEF)
        {
            ac_mobile[playerid]   = true;
            ac_responded[playerid] = true;
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "[AC] Mobile authentication failed. Please reconnect using a supported client.");
            ac_kick_timer[playerid] = SetTimerEx("ClientAC_KickDelayed", 2000, false, "d", playerid);
            return 1;
        }
    }


    return 1;
}

// Cancels pending scans and kicks before the player id can be assigned again.
hook OnPlayerDisconnect(playerid, reason)
{
    ac_reset_player(playerid);
    return 1;
}

// Reads the optional mobile checksum in the join handshake.
hook OnIncomingRPC(playerid, rpcid, BitStream:bs)
{
    new read_offset;
    BS_GetReadOffset(bs, read_offset);
    if (rpcid == 25)
    {
        ac_reset_player(playerid);
        new data[ac_join_data];
        new temp_checksum;
        new bool:read_success = true;

        if (!BS_ReadValue(bs,
            PR_INT32,  data[ac_version],
            PR_UINT8,  data[ac_mod],
            PR_UINT8,  data[ac_nick_len]))
        {
            read_success = false;
        }

        if (read_success && data[ac_nick_len] > 0 && data[ac_nick_len] < 24)
        {
            BS_ReadValue(bs,
                PR_STRING, data[ac_nickname],  data[ac_nick_len],
                PR_UINT32, data[ac_challenge],
                PR_UINT8,  data[ac_auth_len]
            );

            if (data[ac_auth_len] > 0 && data[ac_auth_len] < 50)
            {
                BS_ReadValue(bs,
                    PR_STRING, data[ac_auth_key], data[ac_auth_len],
                    PR_UINT8,  data[ac_client_ver_len]
                );

                if (data[ac_client_ver_len] > 0 && data[ac_client_ver_len] < 30)
                {
                    BS_ReadValue(bs, PR_STRING, data[ac_client_version], data[ac_client_ver_len]);

                    if (BS_ReadUint16(bs, temp_checksum))
                        ac_checksum[playerid] = temp_checksum;
                }
            }
        }
    }

    // Leave the packet cursor unchanged for other hooks and the server's RPC handler.
    BS_SetReadOffset(bs, read_offset);
    AC_OnIncomingRPC(playerid, rpcid);
    return 1;
}


// Collects the results of the memory checks issued after login.
hook OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    switch (actionid)
    {
        case 0x47:
        {
            if (!ac_mobile[playerid])
                ac_suspicious[playerid] = (memaddr == 0xCECECE && retndata == 255);
        }
        case 0x48:
        {
            if (!ac_mobile[playerid])
                ac_suspicious[playerid] = (memaddr == 0xDEDEDE && retndata == 255);
        }
        case 0x5:
        {
            if (!ac_mobile[playerid])
                ac_responded[playerid] = true;

            for (new i = 0; i < sizeof(ac_memory); i++)
            {
                if (memaddr == ac_memory_addr[i])
                {
                    if (retndata != ac_memory[i][ac_expected_val])
                        ac_cheat_history[playerid][i] = ac_memory[i][ac_cheat_val];

                    break;
                }
            }
        }
        case 0x45:
        {
            if (ac_samp_addr[playerid] && memaddr == ac_samp_addr[playerid] && retndata != 192)
                ac_cheat_history[playerid][14] = 15;
        }
    }
    return 1;
}


// Starts the memory checks after login for supported client versions.
public AC_RunScan(playerid)
{
    if (!IsPlayerConnected(playerid)) return 0;

    new version[24];
    GetPlayerVersion(playerid, version, sizeof(version));
    if (strcmp(version, "0.3.DL-R1", true) && strcmp(version, "0.3.7-R5", true)
        && strcmp(version, "0.3.7-R4", true) && strcmp(version, "0.3.7-R3", true)) return 1;

    SendClientCheck(playerid, 0x47, 0, 0, 0x4);
    SendClientCheck(playerid, 0x48, 0, 0, 0x4);

    for (new i = 0; i < sizeof(ac_memory); i++)
        SendClientCheck(playerid, 0x5, ac_memory_addr[i], 0x0, 0x4);

    ac_check_client(playerid);

    if (ac_scan_timer[playerid]) KillTimer(ac_scan_timer[playerid]);
    ac_scan_timer[playerid] = SetTimerEx("ClientAC_FinishScan", 2900, false, "i", playerid);

    return 1;
}


// Evaluates responses and passes detections to the central anti-cheat handler.
public ClientAC_FinishScan(playerid)
{
    ac_scan_timer[playerid] = 0;
    if (!IsPlayerConnected(playerid)) return 0;

    if (ac_mobile[playerid])
    {
        SetPVarInt(playerid, "AC_IsMobile", 1);
        return 1;
    }

    if (!ac_responded[playerid])
    {
        SendClientMessage(playerid, 0xFF0000FF, "[AC] System detected no response from client. Possible mod usage.");
        ac_kick_timer[playerid] = SetTimerEx("ClientAC_KickDelayed", 2000, false, "d", playerid);
        return 1;
    }

    if (ac_suspicious[playerid])
    {
        SendClientMessage(playerid, 0xFF0000FF, "[AC] You are suspected of using external mods. Contact an admin on Discord if this is a mistake.");
        ac_kick_timer[playerid] = SetTimerEx("ClientAC_KickDelayed", 2000, false, "d", playerid);
        return 1;
    }

    for (new i = 0; i < 15; i++)
        SetPVarInt(playerid, sprintf("AC_CheatHistory_%d", i), (ac_cheat_history[playerid][i] != -1) ? 1 : 0);

    for (new i = 0; i < 15; i++)
    {
        if (ac_cheat_history[playerid][i] != -1)
        {
            new cheat_index = ac_cheat_history[playerid][i] - 1;
            if (cheat_index >= 0)
                AC_CheatDetected(playerid, cheat_index);
        }
    }

    return 1;
}

// Delayed disconnect so the warning message reaches the player.
public ClientAC_KickDelayed(playerid)
{
    ac_kick_timer[playerid] = 0;
    if (IsPlayerConnected(playerid))
        Kick(playerid);
    return 1;
}
