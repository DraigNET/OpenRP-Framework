// ============================================================================
// File: minigame_battle/dancing/func.pwn
// Dance battle gameplay: moving arrow keys, scoring key presses, camera and the result screen.
// ============================================================================

/*
// ------------------------------------- Dancing Battle Minigame ------------------------------------- //
======================================== Developed by Tramposo ======================================= //
// --------------------------------------------------------------------------------------------------- //
*/

#include <YSI_Coding\y_hooks>

#define DANCING_TD_X_MAX (575.0)
#define DANCING_TD_X_MIN (270.0)
#define DANCING_TD_HITZONE (306.0)

#define INITIAL_MOVE_SPEED 2.0
#define MEDIUM_SPEED_THRESHOLD 2.5
#define FAST_SPEED_THRESHOLD 3.0

#define DANCING_BEAT_PERFECT 1
#define DANCING_BEAT_GOOD 2
#define DANCING_BEAT_ALRIGHT 3
#define DANCING_BEAT_PAST 4
#define DANCING_BEAT_FUTURE 5
#define DANCING_BEAT_WRONG_BUTTON 6
#define DANCING_BEAT_MISTIMED_BUTTON 7



new const DancingCameras[][] = {
    // Angle    Offset      Height
    {25,            8,           0},
    {100,            12,          2},
    {205,           10,          0},
    {160,           12,          2},
    {-30,            8,           2},
    {170,            8,           2}
};


new DancingCreateCD[MAX_PLAYERS]; // Adds a small cooldown when a new key is spawned to avoid overlap
new DancingMoveCD[MAX_PLAYERS]; // Adds a small cooldown when a key is being reset to the start to avoid overlap
new DancingKeyQueue[MAX_PLAYERS]; // Determines the next free key that is getting reset to the start
new Float: DancingKeyPos[MAX_PLAYERS][MAX_MOVE_TDS]; // Remembers the individual positions of the moving keys
new DancingCamIndex[MAX_PLAYERS]; // Stores what index of camera positions the player is at

hook OnPlayerConnect(playerid) {

    PlayerCurrentMoveIndex[playerid] = 0;
    PlayerCurrentMoveCD[playerid] = 0;
    DancingCreateCD[playerid] = 0;
    DancingMoveCD[playerid] = 0;
    DancingKeyQueue[playerid] = 0;
    for(new m = 0; m < MAX_MOVE_TDS; m++) {
        DancingKeyPos[playerid][m] = DANCING_TD_X_MAX;
        KeyPTD[playerid][m] = INVALID_PLAYER_TEXT_DRAW;
        PlayerArrowTypes[playerid][m] = -1;
    }
}

// Creates a moving key arrow textdraw for a dance battle.
stock CreateDancingMovingKey(playerid, index, Float: x_pos, const key[]) {

    DancingKeyPos[playerid][index] = x_pos; 
    if(KeyPTD[playerid][index] != INVALID_PLAYER_TEXT_DRAW) {
        PlayerTextDrawDestroy(playerid, KeyPTD[playerid][index]);
    }
    KeyPTD[playerid][index] = CreatePlayerTextDraw(playerid, x_pos, 367.000000, key);
    PlayerTextDrawBackgroundColor(playerid, KeyPTD[playerid][index], 255);
    PlayerTextDrawFont(playerid, KeyPTD[playerid][index], 4);
    PlayerTextDrawLetterSize(playerid, KeyPTD[playerid][index], 0.500000, 1.000000);
    PlayerTextDrawColor(playerid, KeyPTD[playerid][index], -1);
    PlayerTextDrawSetOutline(playerid, KeyPTD[playerid][index], 0);
    PlayerTextDrawSetProportional(playerid, KeyPTD[playerid][index], 1);
    PlayerTextDrawSetShadow(playerid, KeyPTD[playerid][index], 1);
    PlayerTextDrawUseBox(playerid, KeyPTD[playerid][index], 1);
    PlayerTextDrawBoxColor(playerid, KeyPTD[playerid][index], 255);
    PlayerTextDrawTextSize(playerid, KeyPTD[playerid][index], 32.000000, 32.000000);
    PlayerTextDrawSetSelectable(playerid, KeyPTD[playerid][index], 0);
    PlayerTextDrawShow(playerid, KeyPTD[playerid][index]);
}

// ==================================================
// Store arrow types for each key
#define SCORE_PERFECT   100
#define SCORE_GOOD      50
#define SCORE_ALRIGHT   20
#define SCORE_BAD       25 // Will be deducted
#define SCORE_WRONG     50 // Will be deducted

// Timing windows (in units of position difference)
#define PERFECT_WINDOW 5.0
#define GOOD_WINDOW    8.0
#define ALRIGHT_WINDOW 12.0
#define BAD_WINDOW 16.0

new PlayerDanceBattleScore[MAX_PLAYERS];
new OpponentDanceBattleScore[MAX_PLAYERS];

// ==================================================================================================
// ==================================================================================================
// ==================================================================================================

// Updates the score text of a dance battle.
UpdateDanceBattleScore(playerid, playerScore, oppositionScore) {
    new scoreString[32];
    format(scoreString, sizeof(scoreString), "%d~n~%d~n~", playerScore, oppositionScore);
    PlayerTextDrawSetString(playerid, SubmPTD[playerid][1], scoreString);
}

// Shows the result (win/lose/draw) of a dance battle.
ShowDanceBattleResult(playerid, const result[]) {
    PlayerTextDrawSetString(playerid, SubmPTD[playerid][2], result);
    PlayerTextDrawShow(playerid, SubmPTD[playerid][2]);
    
    if(Timer_IsRunning(ResultTimer[playerid])) stop ResultTimer[playerid];
    ResultTimer[playerid] = defer HideDanceBattleResult(playerid);
}

// Handles a key press during a dance battle and scores it.
OnPlayerPressDanceBattleKey(playerid, key)
{
    if (!force_tds && !mgDancing[playerid][E_DANCING_ACTIVE]) 
        return 0;

    new bool:keyHandled = false;
    new Float:bestDistance = 999.0;
    new bestKeyIndex = -1;
    
    // Find the closest key to the hit zone that matches the pressed key
    for (new i = 0; i < MAX_MOVE_TDS; i++) {
        if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW)
        {
            // Calculate distance from hit zone
            new Float:distance = floatabs(DancingKeyPos[playerid][i] - DANCING_TD_HITZONE); 
            
            if (distance < bestDistance && distance <= DANCING_TD_X_MAX) {
                bestDistance = distance;
                bestKeyIndex = i;
                keyHandled = true;
            }
        }
    }

    if (keyHandled && bestKeyIndex != -1) {
        if(PlayerArrowTypes[playerid][bestKeyIndex] != GetArrowTypeFromKey(key))
        {
            mgDancing[playerid][E_DANCING_SCORE] -= SCORE_WRONG;
            ShowDanceBattleResult(playerid, "~r~WRONG MOVE!");
            TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]); 
            SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
        }
        else if (bestDistance <= PERFECT_WINDOW) {
            mgDancing[playerid][E_DANCING_SCORE] += SCORE_PERFECT;
            ShowDanceBattleResult(playerid, "~y~PERFECT!");
            TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]); 
            SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
        }
        else if (bestDistance <= GOOD_WINDOW) {
            mgDancing[playerid][E_DANCING_SCORE] += SCORE_GOOD;
            ShowDanceBattleResult(playerid, "~b~GOOD!");
            TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]); 
            SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
        }
        else if (bestDistance <= ALRIGHT_WINDOW) {
            mgDancing[playerid][E_DANCING_SCORE] += SCORE_ALRIGHT;
            ShowDanceBattleResult(playerid, "~r~ALRIGHT!");
            TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]); 
            SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
        }
        else if (bestDistance <= BAD_WINDOW) {
            mgDancing[playerid][E_DANCING_SCORE] -= SCORE_BAD;
            ShowDanceBattleResult(playerid, "~r~BAD!");
            TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]); 
            SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
        }
        else {
            ShowDanceBattleResult(playerid, "~r~BAD!");
            mgDancing[playerid][E_DANCING_SCORE] -= SCORE_BAD;
        }

        UpdateDanceBattleScore(playerid, mgDancing[playerid][E_DANCING_SCORE], mgDancing[mgDancing[playerid][E_DANCING_RIVAL]][E_DANCING_SCORE]);

        // Remove the hit key
        PlayerTextDrawDestroy(playerid, KeyPTD[playerid][bestKeyIndex]);
        KeyPTD[playerid][bestKeyIndex] = INVALID_PLAYER_TEXT_DRAW;
        PlayerArrowTypes[playerid][bestKeyIndex] = -1;

    }
    return 1;
}

// Moves the camera to show the dance battle.
stock SetPlayerDancingCamera(playerid, index)
{
    new Float: x, Float: y, Float: z , Float: ang, Float:camX, Float:camY;
	GetPlayerPos ( playerid, x, y, z ) ;
    GetPlayerFacingAngle( playerid, ang);

    camX = x;
    camY = y;

    camX += (DancingCameras[index][1] * floatsin(-ang - DancingCameras[index][0], degrees));
    camY += (DancingCameras[index][1] * floatcos(-ang - DancingCameras[index][0], degrees));

    SetPlayerCameraPos(playerid, camX, camY, z + DancingCameras[index][2]);
    SetPlayerCameraLookAt(playerid, x, y, z + 0.2);

    DancingCamIndex[playerid] = index;

    CamSwitchCD[playerid] = gettime() + 4;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if (force_tds || mgDancing[playerid][E_DANCING_ACTIVE])
    {
        if (newkeys & KEY_ANALOG_UP) OnPlayerPressDanceBattleKey(playerid, KEY_ANALOG_UP);
        if (newkeys & KEY_ANALOG_DOWN) OnPlayerPressDanceBattleKey(playerid, KEY_ANALOG_DOWN);
        if (newkeys & KEY_ANALOG_LEFT) OnPlayerPressDanceBattleKey(playerid, KEY_ANALOG_LEFT);
        if (newkeys & KEY_ANALOG_RIGHT) OnPlayerPressDanceBattleKey(playerid, KEY_ANALOG_RIGHT);
    }
    
    return 1;
}

// Resets all dance battle data for a player.
ResetPlayerDancingData(playerid)
{
    PlayerCurrentMoveIndex[playerid] = 0;
    PlayerCurrentMoveCD[playerid] = gettime();
    DancingCreateCD[playerid] = 0;
    DancingMoveCD[playerid] = 0;
    DancingKeyQueue[playerid] = 0;
    PlayerDanceBattleScore[playerid] = 0;
    OpponentDanceBattleScore[playerid] = 0;
    LastGeneratedArrow[playerid] = -1;
}

// Timer: hides the dance battle result text.
timer HideDanceBattleResult[1000](playerid)
{
    PlayerTextDrawHide(playerid, SubmPTD[playerid][2]);
}

// ptask DanceBattleMinigameEx[25](playerid) {
//     if (force_tds || mgDancing[playerid][E_DANCING_ACTIVE]) {

//         new challenger = mgDancing[playerid][E_DANCING_RIVAL];

//         // #Check if the challenger is still valid
//         if (!IsPlayerConnected(challenger) || challenger == INVALID_PLAYER_ID) {
//             StopDanceBattle(playerid, challenger, 0);
//             return 1;
//         }

//         // Check player health
//         new Float:P_HP;
//         new Float:C_HP;
//         GetPlayerHealth(playerid, P_HP);
//         GetPlayerHealth(challenger, C_HP);
//         if (P_HP <= 10.0 || C_HP <= 10.0) 
//         {
//             StopDanceBattle(playerid, challenger, 0);
//             return 1;
//         }

//         new currentArrowCount = PlayerCurrentMoveIndex[playerid];
//         new Float:moveSpeed = INITIAL_MOVE_SPEED;
        
//         if (currentArrowCount > 40) {
//             moveSpeed = INITIAL_MOVE_SPEED * 2.0;
//         } else if (currentArrowCount > 20) {
//             moveSpeed = INITIAL_MOVE_SPEED * 1.5;
//         }


//         if (currentArrowCount >= 100) {
//             StopDanceBattle(playerid, mgDancing[playerid][E_DANCING_RIVAL], 0);
//             return 1;
//         }
        
//         if (PlayerCurrentMoveCD[playerid] < gettime() && PlayerCurrentMoveIndex[playerid] < MAX_MOVE_TDS) {
//             PlayerCurrentMoveCD[playerid] = gettime() + random(
//                 max(1, 2 - (currentArrowCount / 20))
//             );

//             new arrowType = GetArrowType(playerid);
//             PlayerArrowTypes[playerid][PlayerCurrentMoveIndex[playerid]] = arrowType;

//             CreateDancingMovingKey(playerid, PlayerCurrentMoveIndex[playerid], 
//                 DANCING_TD_X_MAX, 
//                 arrowTypes[arrowType]);
                
//             PlayerCurrentMoveIndex[playerid]++;

//             // Update all existing keys with new speed
//             for (new i = 0; i < currentArrowCount; i++) {
//                 if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
//                     DancingKeyPos[playerid][i] -= moveSpeed;
//                     CreateDancingMovingKey(playerid, i, DancingKeyPos[playerid][i], 
//                         arrowTypes[PlayerArrowTypes[playerid][i]]);
//                 }
//             }
//         }

//         // Camera switching
//         if (CamSwitchCD[playerid] < gettime())
//         {
//             new index = DancingCamIndex[playerid];
//             if(index >= sizeof(DancingCameras) - 1) index = 0;
//             else index++;

//             SetPlayerDancingCamera(playerid, index);
//         }

//         // Define the hit zone position
//         const Float:HIT_ZONE_TOLERANCE = 8.0;

//         // Update positions of existing TextDraws
//         for (new i = 0; i < MAX_MOVE_TDS; i++) {
//             if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
//                 // Move to the left
//                 DancingKeyPos[playerid][i] -= 1.2;

//                 // Update the textdraw position with the same arrow type
//                 CreateDancingMovingKey(playerid, i, DancingKeyPos[playerid][i], 
//                     arrowTypes[PlayerArrowTypes[playerid][i]]);

//                 if (DancingKeyPos[playerid][i] <= DANCING_TD_HITZONE + HIT_ZONE_TOLERANCE && 
//                     DancingKeyPos[playerid][i] >= DANCING_TD_HITZONE - HIT_ZONE_TOLERANCE) {
//                     TextDrawShowForPlayer(playerid, GameTD[GAME_DANCING][1]);
//                     SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
//                 }

//                 if (DancingKeyPos[playerid][i] < DANCING_TD_X_MIN) {
//                     PlayerTextDrawDestroy(playerid, KeyPTD[playerid][i]);
//                     KeyPTD[playerid][i] = INVALID_PLAYER_TEXT_DRAW;
//                     PlayerArrowTypes[playerid][i] = -1;
//                 }
//             }
//         }
//     }
//     return 1;
// }

// Hides the dance battle textdraws.
stock HideDanceBattleTD(playerid)
{
    TextDrawHideForPlayer(playerid, GameTD[GAME_DANCING][0]);
    TextDrawHideForPlayer(playerid, GameTD[GAME_DANCING][1]);
    
    PlayerTextDrawHide(playerid, SubmPTD[playerid][0]);
    PlayerTextDrawHide(playerid, SubmPTD[playerid][1]);
    PlayerTextDrawHide(playerid, SubmPTD[playerid][2]);
    
    for (new i = 0; i < MAX_MOVE_TDS; i++) {
        if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, KeyPTD[playerid][i]);
            KeyPTD[playerid][i] = INVALID_PLAYER_TEXT_DRAW;
        }
    }

    PlayerTextDrawHide(playerid, FeedbackTD[playerid]);
}

// This handles the clean up for the challenge: resetting variables and removing textdraws for both players.
StopDanceBattle(playerid, challenger, cancelled = 0)
{
    new playername[MAX_PLAYER_NAME], challengername[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playername, sizeof(playername));
    GetPlayerName(challenger, challengername, sizeof(challengername));
    if(!cancelled)
    {
        // new string[128];
        if(mgDancing[playerid][E_DANCING_SCORE] > mgDancing[challenger][E_DANCING_SCORE]) // playerid won
        {
            new pot = g_CurrentChallengePot[playerid];
            AwardWagerPot(playerid, challenger);
            new winner[MAX_PLAYER_NAME];

            GetPlayerName(playerid, winner, sizeof(winner));

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            
            ShowPlayerMinigameResult(playerid, "WINNER!", pot, .showtime = 5000);            
            ShowPlayerMinigameResult(challenger, "~r~ mission failed!", 0, .showtime = 5000);
            ShowPlayerSubtitle(challenger, sprintf("~r~You lost $%d to %s in a lowrider duel.", pot / 2, winner), .showtime = 5000);
        }
        else if(mgDancing[playerid][E_DANCING_SCORE] < mgDancing[challenger][E_DANCING_SCORE]) // challenger won
        {
            new pot = g_CurrentChallengePot[playerid];
            AwardWagerPot(challenger, playerid);
            new winner[MAX_PLAYER_NAME];

            GetPlayerName(challenger, winner, sizeof(winner));
            ShowPlayerMinigameResult(challenger, "WINNER!", pot, .showtime = 5000);
            ShowPlayerMinigameResult(playerid, "~r~ mission failed!", 0, .showtime = 5000);
            ShowPlayerSubtitle(playerid, sprintf("~r~You lost $%d to %s in a lowrider duel.", pot / 2, winner), .showtime = 5000);
        }
        else // Draw
        {
            new pot = g_CurrentChallengePot[playerid];
            
            new halfPot = pot / 2;
            
            GivePlayerCash(playerid, halfPot, "Dancing minigame draw");
            GivePlayerCash(challenger, halfPot, "Dancing minigame draw");


            ShowPlayerMinigameResult(playerid, "draw!", halfPot, .showtime = 5000);
            ShowPlayerMinigameResult(challenger, "draw!", halfPot, .showtime = 5000);

        }
        g_CurrentChallengePot[playerid] = 0;
        g_CurrentChallengePot[challenger] = 0;
        g_CurrentChallengePotOwner[playerid] = INVALID_PLAYER_ID;
        g_CurrentChallengePotOwner[challenger] = INVALID_PLAYER_ID;
    }
    else // cancellation 
    {
        new pot = g_CurrentChallengePot[playerid];
        if (pot > 0)
        {
            // The loser's stake was taken when the battle was accepted, so the winner just collects the pot.
            GivePlayerCash(challenger, pot, "Dancing minigame winner"); 

            new msg[128];
            format(msg, sizeof(msg), "The challenge was cancelled. You forfeited your $%d stake to your rival.", pot / 2);
            SendClientMessage(playerid, COLOR_RED, msg);

            format(msg, sizeof(msg), "Your rival cancelled the challenge. You received $%d.", pot);
            SendClientMessage(challenger, COLOR_GREEN, msg);

            g_CurrentChallengePot[playerid] = 0;
            g_CurrentChallengePot[challenger] = 0;
            g_CurrentChallengePotOwner[playerid] = INVALID_PLAYER_ID;
            g_CurrentChallengePotOwner[challenger] = INVALID_PLAYER_ID;
        }
    }

    new winnerMsg[128];
    if(mgDancing[playerid][E_DANCING_SCORE] > mgDancing[challenger][E_DANCING_SCORE]) {
        format(winnerMsg, sizeof(winnerMsg), "%s won the lowrider battle against %s!", playername, challengername);
    }
    else if(mgDancing[challenger][E_DANCING_SCORE] > mgDancing[playerid][E_DANCING_SCORE]) {
        format(winnerMsg, sizeof(winnerMsg), "%s won the lowrider battle against %s!", challengername, playername);
    }
    else {
        format(winnerMsg, sizeof(winnerMsg), "The lowrider battle between %s and %s ended in a tie!", playername, challengername);
    }


    HideDanceBattleTD(playerid);
    HideDanceBattleTD(challenger);

    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
    PlayerPlaySound(challenger, 0, 0.0, 0.0, 0.0);
    
    SetEngineStatus(GetPlayerVehicleID(playerid), true);
    SetEngineStatus(GetPlayerVehicleID(challenger), true);

    SetCameraBehindPlayer(playerid);    
    SetCameraBehindPlayer(challenger);

    mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
    mgDancing[playerid][E_DANCING_OFFER] = false;
    mgDancing[playerid][E_DANCING_ACTIVE] = false;

    mgDancing[playerid][E_DANCING_SCORE] = 0;

    mgDancing[challenger][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
    mgDancing[challenger][E_DANCING_OFFER] = false;
    mgDancing[challenger][E_DANCING_ACTIVE] = false;

    mgDancing[challenger][E_DANCING_SCORE] = 0;
    return 1;
}
