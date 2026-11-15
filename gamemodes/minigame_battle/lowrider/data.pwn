// ============================================================================
// File: minigame_battle/lowrider/data.pwn
// Lowrider battle state: creating a challenge, starting it and tracking scores. /togglelrbattle
// and /lrbattles control availability.
// Commands: /togglelrbattle /lrbattles
// ============================================================================

enum E_GAME_TYPE {
    GAME_LOWRIDER,
    GAME_DANCING
}

#define LOWRIDER_DUEL_LABEL_FORMAT "[Lowrider Battle]\n {FFFFFF}%s: %d %s: %d"
new DynamicText3D:LowriderScoreLabel[MAX_PLAYERS];

enum E_LOWRIDER_MINIGAME {

    E_LOWRIDER_RIVAL,
    bool: E_LOWRIDER_OFFER,
    bool: E_LOWRIDER_ACTIVE,

    Float:E_LOWRIDER_ORIGINAL_X,
    Float:E_LOWRIDER_ORIGINAL_Y,
    Float:E_LOWRIDER_ORIGINAL_ANGLE,

    E_LOWRIDER_SCORE,
    E_LOWRIDER_BATTLE_ID
}

/*=========================================
                Spectate Shit
===========================================*/

#define MAX_LOWRIDER_BATTLES    10
#define INVALID_BATTLE_ID       -1

enum E_BATTLE_DATA {
    E_BATTLE_PLAYER1,
    E_BATTLE_PLAYER2,
    bool:E_BATTLE_ACTIVE,
    DynamicText3D:E_BATTLE_LABEL,
    Float:E_BATTLE_POS[3]
}

new g_BattleData[MAX_LOWRIDER_BATTLES][E_BATTLE_DATA];
new bool:g_PlayerSpectating[MAX_PLAYERS][MAX_LOWRIDER_BATTLES];
new g_CurrentBattles = 0;



// Creates a lowrider battle between two drivers.
stock CreateLowriderBattle(playerid, challenger, Float:centerX, Float:centerY, Float:centerZ) {
    new battleId = INVALID_BATTLE_ID;
    
    for(new i = 0; i < MAX_LOWRIDER_BATTLES; i++) {
        if(!g_BattleData[i][E_BATTLE_ACTIVE]) {
            battleId = i;
            break;
        }
    }
    
    if(battleId == INVALID_BATTLE_ID) return INVALID_BATTLE_ID;
    
    g_BattleData[battleId][E_BATTLE_PLAYER1] = playerid;
    g_BattleData[battleId][E_BATTLE_PLAYER2] = challenger;
    g_BattleData[battleId][E_BATTLE_ACTIVE] = true;
    
    g_BattleData[battleId][E_BATTLE_POS][0] = centerX;
    g_BattleData[battleId][E_BATTLE_POS][1] = centerY;
    g_BattleData[battleId][E_BATTLE_POS][2] = centerZ;
    
    g_CurrentBattles++;
    return battleId;
}

new Lowrider[MAX_PLAYERS][E_LOWRIDER_MINIGAME];
new g_CurrentChallengePot[MAX_PLAYERS] = {0, ...};
new g_CurrentChallengePotOwner[MAX_PLAYERS] = {INVALID_PLAYER_ID, ...};

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
    
    Lowrider[playerid][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
    Lowrider[playerid][E_LOWRIDER_OFFER] = false;
    Lowrider[playerid][E_LOWRIDER_ACTIVE] = false;

    Lowrider[playerid][E_LOWRIDER_SCORE] = 0;
}

hook OnPlayerDisconnect(playerid, reason) {
    if(GetLowriderOpponent(playerid) != INVALID_PLAYER_ID) {
        
        StopLowriderChallenge(playerid, GetLowriderOpponent(playerid));
    }
    return 1;
}


// This function will start the lowrider challenge between two players. The moment E_LOWRIDER_ACTIVE is true, the timer will tick for them.
StartLowriderChallenge(playerid, challenger, wagerPot) 
{

    ShowBattleTDs(playerid, challenger, GAME_LOWRIDER);

    new challengeSound = random(3) + 179;
    PlayerPlaySound(playerid, challengeSound, 0.0, 0.0, 0.0);
    PlayerPlaySound(challenger, challengeSound, 0.0, 0.0, 0.0);

    ResetPlayerLowriderData(playerid);
    ResetPlayerLowriderData(challenger);

    new Float:x, Float:y, Float:z, Float:angle;
    new Float:cx, Float:cy, Float:cz, Float:cAngle;

    GetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
    GetVehiclePos(GetPlayerVehicleID(challenger), cx, cy, cz);
    GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
    GetVehicleZAngle(GetPlayerVehicleID(challenger), cAngle);
    

    Lowrider[playerid][E_LOWRIDER_ORIGINAL_X] = x;
    Lowrider[playerid][E_LOWRIDER_ORIGINAL_Y] = y;
    Lowrider[playerid][E_LOWRIDER_ORIGINAL_ANGLE] = angle;

    Lowrider[challenger][E_LOWRIDER_ORIGINAL_X] = cx;
    Lowrider[challenger][E_LOWRIDER_ORIGINAL_Y] = cy;
    Lowrider[challenger][E_LOWRIDER_ORIGINAL_ANGLE] = cAngle;
    

    // This will start the timer for the players. Call it last once everything else is set up.
    Lowrider[challenger][E_LOWRIDER_ACTIVE] = true;
    Lowrider[playerid][E_LOWRIDER_ACTIVE] = true;

    Lowrider[playerid][E_LOWRIDER_SCORE] = 0;
    Lowrider[challenger][E_LOWRIDER_SCORE] = 0;

    new battleId = CreateLowriderBattle(playerid, challenger, (x + cx) / 2.0, (y + cy) / 2.0, (z + cz) / 2.0);
    if(battleId == INVALID_BATTLE_ID) return 0;

    g_BattleData[battleId][E_BATTLE_LABEL] = CreateDynamic3DTextLabel(
        sprintf(LOWRIDER_DUEL_LABEL_FORMAT, 
            ReturnPlayerName(playerid),
            Lowrider[playerid][E_LOWRIDER_SCORE],
            ReturnPlayerName(challenger),
            Lowrider[challenger][E_LOWRIDER_SCORE]
        ),
        0x6B1D72FF,
        g_BattleData[battleId][E_BATTLE_POS][0],
        g_BattleData[battleId][E_BATTLE_POS][1],
        g_BattleData[battleId][E_BATTLE_POS][2],
        12.5,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        false
    );


    Lowrider[playerid][E_LOWRIDER_BATTLE_ID] = battleId;
    Lowrider[challenger][E_LOWRIDER_BATTLE_ID] = battleId;

    SetEngineStatus(GetPlayerVehicleID(playerid), false);
    SetEngineStatus(GetPlayerVehicleID(challenger), false);

    SetupWagerPot(playerid, challenger, wagerPot);

    return 1;
}

// /togglelrbattle [battle id] - (staff) enables or disables a battle.
CMD:togglelrbattle(playerid, params[]) {
    new battleId;
    if(sscanf(params, "d", battleId)) return SendClientMessage(playerid, COLOR_GREY, "USAGE: /togglelrbattle [battle id]");
    
    if(battleId < 0 || battleId >= MAX_LOWRIDER_BATTLES)
        return SendClientMessage(playerid, COLOR_RED, "Invalid battle ID!");
        
    if(!g_BattleData[battleId][E_BATTLE_ACTIVE])
        return SendClientMessage(playerid, COLOR_RED, "This battle is not active!");
    
    g_PlayerSpectating[playerid][battleId] = !g_PlayerSpectating[playerid][battleId];
    
    if(g_PlayerSpectating[playerid][battleId]) {
        Streamer_ToggleItem(playerid, STREAMER_TYPE_3D_TEXT_LABEL, g_BattleData[battleId][E_BATTLE_LABEL], true);
        SendClientMessage(playerid, COLOR_GREEN, "You are now spectating this lowrider battle!");
    } else {
        Streamer_ToggleItem(playerid, STREAMER_TYPE_3D_TEXT_LABEL, g_BattleData[battleId][E_BATTLE_LABEL], false);
        SendClientMessage(playerid, COLOR_RED, "You are no longer spectating this lowrider battle!");
    }
    return 1;
}

// /lrbattles - lists the active lowrider battles.
CMD:lrbattles(playerid) {
    if(g_CurrentBattles == 0)
        return SendClientMessage(playerid, COLOR_RED, "There are no active lowrider battles!");
        
    new string[128], count = 0;
    for(new i = 0; i < MAX_LOWRIDER_BATTLES; i++) {
        if(g_BattleData[i][E_BATTLE_ACTIVE]) {
            format(string, sizeof(string), "Battle ID: %d | %s vs %s", 
                i,
                ReturnPlayerName(g_BattleData[i][E_BATTLE_PLAYER1]),
                ReturnPlayerName(g_BattleData[i][E_BATTLE_PLAYER2])
            );
            SendClientMessage(playerid, COLOR_WHITE, string);
            count++;
        }
    }
    
    format(string, sizeof(string), "Total: %d active battle%s", count, (count == 1) ? "" : "s");
    SendClientMessage(playerid, COLOR_GREY, string);
    return 1;
}



/////////////////////////////////////////////////////
////////////// Other helper functions: //////////////
/////////////////////////////////////////////////////

// Returns a player's lowrider battle opponent.
GetLowriderOpponent(playerid) {
    return Lowrider[playerid][E_LOWRIDER_RIVAL];
}

// Returns the opponent's score.
stock GetLowriderOpponentScore(playerid) {
    if(GetLowriderOpponent(playerid) == INVALID_PLAYER_ID) return 0;
    return Lowrider[GetLowriderOpponent(playerid)][E_LOWRIDER_SCORE];
}

// Returns whether the player is in an active lowrider battle.
stock GetLowriderStatus(playerid) {
    return Lowrider[playerid][E_LOWRIDER_ACTIVE];
}

// Returns true if two players are battling each other.
stock ArePlayersBattling(playerid, challenger) {
    if(!IsPlayerConnected(challenger)) return false;
    return ((GetLowriderStatus(playerid) && GetLowriderOpponent(playerid) == challenger) && (GetLowriderStatus(challenger) && GetLowriderOpponent(challenger) == playerid));
}
