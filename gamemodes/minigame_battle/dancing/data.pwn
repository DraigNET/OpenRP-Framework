// ============================================================================
// File: minigame_battle/dancing/data.pwn
// Dance battle state: starting a battle between two players (StartDanceBattle) and reading its
// status and scores.
// ============================================================================

enum E_DANCING_MINIGAME {

    E_DANCING_RIVAL,
    bool: E_DANCING_OFFER,
    bool: E_DANCING_ACTIVE,

    Float:E_DANCING_ORIGINAL_X,
    Float:E_DANCING_ORIGINAL_Y,
    Float:E_DANCING_ORIGINAL_ANGLE,

    E_DANCING_SCORE
}

new mgDancing[MAX_PLAYERS][E_DANCING_MINIGAME];

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
    
    mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
    mgDancing[playerid][E_DANCING_OFFER] = false;
    mgDancing[playerid][E_DANCING_ACTIVE] = false;

    mgDancing[playerid][E_DANCING_SCORE] = 0;
}

hook ORP_OnCloseConnection(playerid) {
    if(GetDancingBattleOpponent(playerid) != INVALID_PLAYER_ID) {
        
        StopDanceBattle(playerid, GetDancingBattleOpponent(playerid));
    }
    return 1;
}


// This function will start the dancing battle between two players. The moment E_DANCING_ACTIVE is true, the timer will tick for them.
StartDanceBattle(playerid, challenger, wagerPot) {

    ShowBattleTDs(playerid, challenger, GAME_DANCING);

    new challengeSound = random(3) + 179;
    PlayerPlaySound(playerid, challengeSound, 0.0, 0.0, 0.0);
    PlayerPlaySound(challenger, challengeSound, 0.0, 0.0, 0.0);

    ResetPlayerDancingData(playerid);
    ResetPlayerDancingData(challenger);

    new Float:x, Float:y, Float:angle;
    new Float:cx, Float:cy, Float:cAngle;

    mgDancing[playerid][E_DANCING_ORIGINAL_X] = x;
    mgDancing[playerid][E_DANCING_ORIGINAL_Y] = y;
    mgDancing[playerid][E_DANCING_ORIGINAL_ANGLE] = angle;

    mgDancing[challenger][E_DANCING_ORIGINAL_X] = cx;
    mgDancing[challenger][E_DANCING_ORIGINAL_Y] = cy;
    mgDancing[challenger][E_DANCING_ORIGINAL_ANGLE] = cAngle;
    

    // This will start the timer for the players. Call it last once everything else is set up.
    mgDancing[challenger][E_DANCING_ACTIVE] = true;
    mgDancing[playerid][E_DANCING_ACTIVE] = true;

    mgDancing[playerid][E_DANCING_SCORE] = 0;
    mgDancing[challenger][E_DANCING_SCORE] = 0;

    SetupWagerPot(playerid, challenger, wagerPot);

    return 1;
}




/////////////////////////////////////////////////////
////////////// Other helper functions: //////////////
/////////////////////////////////////////////////////

// Returns a player's dance battle opponent.
GetDancingBattleOpponent(playerid) {
    return mgDancing[playerid][E_DANCING_RIVAL];
}

// Returns the opponent's score in a dance battle.
stock GetDancingBattleOpponentScore(playerid) {
    if(GetDancingBattleOpponent(playerid) == INVALID_PLAYER_ID) return 0;
    return mgDancing[GetDancingBattleOpponent(playerid)][E_DANCING_SCORE];
}

// Returns whether the player is in an active dance battle.
stock GetDancingBattleStatus(playerid) {
    return mgDancing[playerid][E_DANCING_ACTIVE];
}

// Returns true if two players are battling each other.
stock ArePlayersDanceBattling(playerid, challenger) {
    if(!IsPlayerConnected(challenger)) return false;
    return ((GetDancingBattleStatus(playerid) && GetDancingBattleOpponent(playerid) == challenger) && (GetDancingBattleStatus(challenger) && GetDancingBattleOpponent(challenger) == playerid));
}
