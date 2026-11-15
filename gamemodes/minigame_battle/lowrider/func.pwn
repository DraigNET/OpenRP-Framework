// ============================================================================
// File: minigame_battle/lowrider/func.pwn
// Lowrider battle gameplay: hydraulic-bounce rhythm game with arrow keys, hit indicators and
// scoring. Developed by Tramposo.
// Commands: /stopdrag
// ============================================================================

/*
// ---------------------------------- Lowrider Minigame ---------------------------------------- //
// -------------------------- Developed by Tramposo, Dec 2024 ---------------------------------- //
// --------------------------------------------------------------------------------------------- //
*/

#include <YSI_Coding\y_hooks>

#define LOWRIDER_TD_X_MAX (575.0)
#define LOWRIDER_TD_X_MIN (270.0)
#define LOWRIDER_TD_HITZONE (306.0)
#define MAX_ARROW_TYPES 4
new arrowTypes[MAX_ARROW_TYPES][] = { "LD_BEAT:up", "LD_BEAT:down", "LD_BEAT:left", "LD_BEAT:right" };

#define INITIAL_MOVE_SPEED 2.0
#define MEDIUM_SPEED_THRESHOLD 2.5
#define FAST_SPEED_THRESHOLD 3.0

#define LOWRIDER_BEAT_PERFECT 1
#define LOWRIDER_BEAT_GOOD 2
#define LOWRIDER_BEAT_ALRIGHT 3
#define LOWRIDER_BEAT_PAST 4
#define LOWRIDER_BEAT_FUTURE 5
#define LOWRIDER_BEAT_WRONG_BUTTON 6
#define LOWRIDER_BEAT_MISTIMED_BUTTON 7



new const LowriderCameras[][] = {
    // Angle    Offset      Height
    {25,            8,           0},
    {100,            12,          2},
    {205,           10,          0},
    {160,           12,          2},
    {-30,            8,           2},
    {170,            8,           2}
};

new LastGeneratedArrow[MAX_PLAYERS] = {-1, ...};

new PlayerCurrentMoveIndex[MAX_PLAYERS]; // Saves index of new move, used to see if MAX_MOVE_TDS cap is reached
new PlayerCurrentMoveCD[MAX_PLAYERS]; // Random cooldown on creation, to add "randomness" to the game
new LowriderCreateCD[MAX_PLAYERS]; // Adds a small cooldown when a new key is spawned to avoid overlap
new LowriderMoveCD[MAX_PLAYERS]; // Adds a small cooldown when a key is being reset to the start to avoid overlap
new LowriderKeyQueue[MAX_PLAYERS]; // Determines the next free key that is getting reset to the start
new Float: LowriderKeyPos[MAX_PLAYERS][MAX_MOVE_TDS]; // Remembers the individual positions of the moving keys
// new bool: PlayerFinished[MAX_PLAYERS]; // Has the player finished the game? Unused
new PlayerArrowTypes[MAX_PLAYERS][MAX_MOVE_TDS]; // Store arrow types for each key
new LowriderCamIndex[MAX_PLAYERS]; // Stores what index of camera positions the player is at
new CamSwitchCD[MAX_PLAYERS]; // Handles time before each camera switch
new Timer:FeedbackTimer[MAX_PLAYERS]; // Stores reference to timer for hiding feedbacks
new Timer:ResultTimer[MAX_PLAYERS]; // Same as above, for results TD
new LastLabelScore[MAX_PLAYERS][2]; // [playerid][0] = own score, [1] = opponent score


#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {

    LowriderScoreLabel[playerid] = DynamicText3D:INVALID_3DTEXT_ID;
    LastLabelScore[playerid][0] = 0;
    LastLabelScore[playerid][1] = 0;

    PlayerCurrentMoveIndex[playerid] = 0;
    PlayerCurrentMoveCD[playerid] = 0;
    LowriderCreateCD[playerid] = 0;
    LowriderMoveCD[playerid] = 0;
    LowriderKeyQueue[playerid] = 0;
    LowriderExpireTimer[playerid] = 0;

    for(new m = 0; m < MAX_MOVE_TDS; m++) {
        LowriderKeyPos[playerid][m] = LOWRIDER_TD_X_MAX;
        KeyPTD[playerid][m] = INVALID_PLAYER_TEXT_DRAW;
        PlayerArrowTypes[playerid][m] = -1;
    }
}

// Creates a moving arrow textdraw for a lowrider battle.
CreateLowriderMovingKey(playerid, index, Float: x_pos, const key[]) {

    LowriderKeyPos[playerid][index] = x_pos; 
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
new force_tds;

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

new PlayerLowriderScore[MAX_PLAYERS];
new OpponentLowriderScore[MAX_PLAYERS];

#define MAX_FDB_MESSAGES 3
#define MAX_MESSAGE_LENGTH 32
new const FeedbackMessages[8][MAX_FDB_MESSAGES][MAX_MESSAGE_LENGTH] = {
    { "The master!", "Perfect!", "Spot on!" },                      // LOWRIDER_BEAT_PERFECT
    { "Well done!", "Nice move!", "Good job!" },                    // LOWRIDER_BEAT_GOOD
    { "Alright", "Not bad", "Keep going!" },                        // LOWRIDER_BEAT_ALRIGHT
    { "Too late!", "You're behind!", "Try to keep up!" },           // LOWRIDER_BEAT_PAST
    { "Too early!", "You're ahead!", "Slow down!" },                // LOWRIDER_BEAT_FUTURE
    { "Wrong!", "Missed it!", "Wrong button!" },                    // LOWRIDER_BEAT_WRONG_BUTTON
    { "Poor timing!", "Close!", "More precision!" },                // LOWRIDER_BEAT_MISTIMED_BUTTON
    { "Keep it up!", "Come on!", "Stay focused!" }                  // Default
};

// ==================================================================================================
// ==================================================================================================
// ==================================================================================================

// Resets a player's lowrider battle state (and wager if asked).
stock ResetLowriderPlayerState(playerid, bool:resetWager = true) {
    Lowrider[playerid][E_LOWRIDER_OFFER] = false;
    Lowrider[playerid][E_LOWRIDER_ACTIVE] = false;
    Lowrider[playerid][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
    
    if(resetWager) {
        PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
        PlayerWagerData[playerid][WagerAmount] = 0;
        PlayerWagerData[playerid][InWagerMenu] = false;
    }
}

// Updates the score text of a lowrider battle.
stock UpdateLowriderScores(playerid, playerScore, oppositionScore) {
    if(LastLabelScore[playerid][0] != playerScore || LastLabelScore[playerid][1] != oppositionScore) {
        new scoreString[32];
        format(scoreString, sizeof(scoreString), "%d~n~%d~n~", playerScore, oppositionScore);
        PlayerTextDrawSetString(playerid, SubmPTD[playerid][1], scoreString);
        
        LastLabelScore[playerid][0] = playerScore;
        LastLabelScore[playerid][1] = oppositionScore;
    }
}

// Updates the 3D label above a lowrider battle.
stock UpdateBattle3DLabel(battleId) {
    if(!g_BattleData[battleId][E_BATTLE_ACTIVE]) return;
    
    new p1 = g_BattleData[battleId][E_BATTLE_PLAYER1];
    new p2 = g_BattleData[battleId][E_BATTLE_PLAYER2];
    
    // Only update if scores changed
    static lastP1Score[MAX_LOWRIDER_BATTLES];
    static lastP2Score[MAX_LOWRIDER_BATTLES];
    
    if(lastP1Score[battleId] != Lowrider[p1][E_LOWRIDER_SCORE] || 
       lastP2Score[battleId] != Lowrider[p2][E_LOWRIDER_SCORE]) {
        
        UpdateDynamic3DTextLabelText(
            g_BattleData[battleId][E_BATTLE_LABEL],
            0x6B1D72FF,
            sprintf(LOWRIDER_DUEL_LABEL_FORMAT, 
                ReturnPlayerName(p1),
                Lowrider[p1][E_LOWRIDER_SCORE],
                ReturnPlayerName(p2),
                Lowrider[p2][E_LOWRIDER_SCORE]
            )
        );
        
        lastP1Score[battleId] = Lowrider[p1][E_LOWRIDER_SCORE];
        lastP2Score[battleId] = Lowrider[p2][E_LOWRIDER_SCORE];
    }
}

// Converts a key press to an arrow type.
GetArrowTypeFromKey(key)
{
    if(key & (KEY_ANALOG_UP)) return 0;
    if(key & (KEY_ANALOG_DOWN)) return 1;
    if(key & (KEY_ANALOG_LEFT)) return 2;
    if(key & (KEY_ANALOG_RIGHT)) return 3;

    return -1;
}

// Shows a feedback message (perfect, good, miss) for a key press.
ShowLowriderFeedback(playerid, feedbackType) {

    new messageIndex = random(MAX_FDB_MESSAGES);

    PlayerTextDrawSetString(playerid, FeedbackTD[playerid], FeedbackMessages[feedbackType][messageIndex]);

    PlayerTextDrawShow(playerid, FeedbackTD[playerid]);
    if(Timer_IsRunning(FeedbackTimer[playerid])) stop FeedbackTimer[playerid];

    FeedbackTimer[playerid] = defer HideFeedbackTD(playerid);
}

// Timer: hides the feedback message.
timer HideFeedbackTD[1000](playerid)
{
    PlayerTextDrawHide(playerid, FeedbackTD[playerid]);
}

// Shows the battle result.
ShowLowriderResult(playerid, const result[]) {
    PlayerTextDrawSetString(playerid, SubmPTD[playerid][2], result);
    PlayerTextDrawShow(playerid, SubmPTD[playerid][2]);
    
    if(Timer_IsRunning(ResultTimer[playerid])) stop ResultTimer[playerid];
    ResultTimer[playerid] = defer HideLowriderResult(playerid);
}

// Handles a key press in a lowrider battle and scores it.
OnPlayerPressLowriderKey(playerid, key)
{
    if (!force_tds && !Lowrider[playerid][E_LOWRIDER_ACTIVE]) return 0;

    new pressedArrowType = GetArrowTypeFromKey(key);
    
    if(pressedArrowType == -1) return 0;

    new bool:keyHandled = false;
    new Float:bestDistance = BAD_WINDOW + 1.0;
    new bestKeyIndex = -1;

    // Find the closest key to the hit zone that matches the pressed key
    for (new i = 0; i < MAX_MOVE_TDS; i++) {
        if (KeyPTD[playerid][i] == INVALID_PLAYER_TEXT_DRAW) continue;
        
        new Float:keyPos = LowriderKeyPos[playerid][i];
        
        if(keyPos < LOWRIDER_TD_HITZONE - BAD_WINDOW || 
           keyPos > LOWRIDER_TD_HITZONE + BAD_WINDOW) continue;
        
        new Float:distance = floatabs(keyPos - LOWRIDER_TD_HITZONE);

        // Perfect hit - cant get better so exit immediately
        if (distance <= PERFECT_WINDOW) {
            bestDistance = distance;
            bestKeyIndex = i;
            keyHandled = true;
            break;
        }

        if (distance < bestDistance) {
            bestDistance = distance;
            bestKeyIndex = i;
            keyHandled = true;
        }
    }

    if (!keyHandled || bestKeyIndex == -1) return 0;

    new feedbackType;
    new scoreChange = 0;
    new resultText[32];
    new bool:showHitIndicator = false;
    
    // Check if correct arrow type first
    if(PlayerArrowTypes[playerid][bestKeyIndex] != pressedArrowType) {
        scoreChange = -SCORE_WRONG;
        feedbackType = LOWRIDER_BEAT_WRONG_BUTTON;
        resultText = "~r~WRONG MOVE!";
        showHitIndicator = true;
    }
    else if (bestDistance <= PERFECT_WINDOW) {
        scoreChange = SCORE_PERFECT;
        feedbackType = LOWRIDER_BEAT_PERFECT;
        resultText = "~y~PERFECT!";
        showHitIndicator = true;
    }
    else if (bestDistance <= GOOD_WINDOW) {
        scoreChange = SCORE_GOOD;
        feedbackType = LOWRIDER_BEAT_GOOD;
        resultText = "~b~GOOD!";
        showHitIndicator = true;
    }
    else if (bestDistance <= ALRIGHT_WINDOW) {
        scoreChange = SCORE_ALRIGHT;
        feedbackType = LOWRIDER_BEAT_ALRIGHT;
        resultText = "~r~BAD!";
        showHitIndicator = true;
    }
    else if (bestDistance <= BAD_WINDOW) {
        scoreChange = -SCORE_BAD;
        feedbackType = LOWRIDER_BEAT_PAST;
        resultText = "~r~BAD!";
        showHitIndicator = true;
    }
    else {
        scoreChange = -SCORE_BAD;
        feedbackType = LOWRIDER_BEAT_MISTIMED_BUTTON;
        resultText = "~r~BAD!";
    }

    Lowrider[playerid][E_LOWRIDER_SCORE] += scoreChange;
    
    ShowLowriderResult(playerid, resultText);
    ShowLowriderFeedback(playerid, feedbackType);
    
    if(showHitIndicator) {
        TextDrawShowForPlayer(playerid, GameTD[GAME_LOWRIDER][1]); 
        SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
    }

    new rivalId = Lowrider[playerid][E_LOWRIDER_RIVAL];
    if(rivalId != INVALID_PLAYER_ID) {
        UpdateLowriderScores(playerid, Lowrider[playerid][E_LOWRIDER_SCORE], Lowrider[rivalId][E_LOWRIDER_SCORE]);
        
        new battleId = Lowrider[playerid][E_LOWRIDER_BATTLE_ID];
        if(battleId != INVALID_BATTLE_ID) {
            UpdateBattle3DLabel(battleId);
        }
    }

    // Remove the hit key
    PlayerTextDrawDestroy(playerid, KeyPTD[playerid][bestKeyIndex]);
    KeyPTD[playerid][bestKeyIndex] = INVALID_PLAYER_TEXT_DRAW;
    PlayerArrowTypes[playerid][bestKeyIndex] = -1;

    return 1;
}

// Cancels a lowrider challenge between two players.
stock ResetLowriderChallenge(playerid, challenger) {
    KillTimer(LowriderExpireTimer[playerid]);
    LowriderExpireTimer[playerid] = 0;
    
    ResetLowriderPlayerState(playerid);
    ResetLowriderPlayerState(challenger);
}

// Moves the camera in front of the player.
stock SetPlayerFrontCamera(playerid, Float:height)
{
    new Float: x, Float: y, Float: z , Float: ang;
	GetPlayerPos ( playerid, x, y, z ) ;
    SetPlayerCameraLookAt(playerid, x, y, z + 0.2);
	GetXYInFrontOfPlayer(playerid, x, y, height);
    GetPlayerFacingAngle(playerid, ang);

    SetPlayerCameraPos(playerid, x, y, z);
}

// Moves the camera to show the lowrider vehicle.
stock SetPlayerLowriderCamera(playerid, index)
{
    new Float: x, Float: y, Float: z , Float: ang, Float:camX, Float:camY;
	GetVehiclePos ( GetPlayerVehicleID(playerid), x, y, z ) ;
    GetVehicleZAngle( GetPlayerVehicleID(playerid), ang);

    camX = x;
    camY = y;

    camX += (LowriderCameras[index][1] * floatsin(-ang - LowriderCameras[index][0], degrees));
    camY += (LowriderCameras[index][1] * floatcos(-ang - LowriderCameras[index][0], degrees));

    SetPlayerCameraPos(playerid, camX, camY, z + LowriderCameras[index][2]);
    SetPlayerCameraLookAt(playerid, x, y, z + 0.2);

    LowriderCamIndex[playerid] = index;

    CamSwitchCD[playerid] = gettime() + 4;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if (force_tds || Lowrider[playerid][E_LOWRIDER_ACTIVE])
    {
        if (newkeys & KEY_ANALOG_UP) OnPlayerPressLowriderKey(playerid, KEY_ANALOG_UP);
        if (newkeys & KEY_ANALOG_DOWN) OnPlayerPressLowriderKey(playerid, KEY_ANALOG_DOWN);
        if (newkeys & KEY_ANALOG_LEFT) OnPlayerPressLowriderKey(playerid, KEY_ANALOG_LEFT);
        if (newkeys & KEY_ANALOG_RIGHT) OnPlayerPressLowriderKey(playerid, KEY_ANALOG_RIGHT);
    }
    
    return 1;
}

// Resets all lowrider data for a player.
ResetPlayerLowriderData(playerid)
{
    PlayerCurrentMoveIndex[playerid] = 0;
    PlayerCurrentMoveCD[playerid] = gettime();
    LowriderCreateCD[playerid] = 0;
    LowriderMoveCD[playerid] = 0;
    LowriderKeyQueue[playerid] = 0;
    PlayerLowriderScore[playerid] = 0;
    OpponentLowriderScore[playerid] = 0;
    LastGeneratedArrow[playerid] = -1;
}

// Timer: hides the lowrider result text.
timer HideLowriderResult[1000](playerid)
{
    PlayerTextDrawHide(playerid, SubmPTD[playerid][2]);
}

// Picks the next random arrow, avoiding repeats.
GetArrowType(playerid) {
    new newArrow;
    do {
        newArrow = RandomEx(0, MAX_ARROW_TYPES - 1);
    } while (newArrow == LastGeneratedArrow[playerid] && RandomEx(0, 100) < 70);
    
    LastGeneratedArrow[playerid] = newArrow;
    return newArrow;
}

ptask LowriderMinigameEx[25](playerid) {
    if (force_tds || Lowrider[playerid][E_LOWRIDER_ACTIVE]) {

        new challenger = Lowrider[playerid][E_LOWRIDER_RIVAL];

        // #Check if the challenger is still valid
        if (!IsPlayerConnected(challenger) || challenger == INVALID_PLAYER_ID) {
            StopLowriderChallenge(playerid, challenger, 0);
            //SendClientMessage(playerid, COLOR_BLUE, "Challenger valid check.");
            return 1;
        }
         // #Check vehicle status
        new vehicleid = GetPlayerVehicleID(playerid);
        new challengerVehicleId = GetPlayerVehicleID(challenger);

        // #Check if players are in vehicles
        if (!IsPlayerInAnyVehicle(playerid) || !IsPlayerInAnyVehicle(challenger)) {
            StopLowriderChallenge(playerid, challenger, 0);
            //SendClientMessage(playerid, COLOR_BLUE, "Player in Vehicle check.");

            return 1;
        }

        // #Check vehicle health
        new Float:playerVehicleHealth, Float:challengerVehicleHealth;
        GetVehicleHealth(vehicleid, playerVehicleHealth);
        GetVehicleHealth(challengerVehicleId, challengerVehicleHealth);

        if (playerVehicleHealth <= 300.0 || challengerVehicleHealth <= 300.0) {
            StopLowriderChallenge(playerid, challenger, 0);
            //SendClientMessage(playerid, COLOR_BLUE, "Vehicle valid check.");

            return 1;
        }

        // Check player health
        new Float:P_HP;
        new Float:C_HP;
        GetPlayerHealth(playerid, P_HP);
        GetPlayerHealth(challenger, C_HP);
        if (P_HP <= 10.0 || C_HP <= 10.0) 
        {
            StopLowriderChallenge(playerid, challenger, 0);
            //SendClientMessage(playerid, COLOR_BLUE, "Player Health check.");

            return 1;
        }
        
        new Float:x, Float:y, Float:z, Float:currentAngle;
        GetVehiclePos(vehicleid, x, y, z);
        GetVehicleZAngle(vehicleid, currentAngle);

        if (floatabs(x - Lowrider[playerid][E_LOWRIDER_ORIGINAL_X]) > 1.0 || 
            floatabs(y - Lowrider[playerid][E_LOWRIDER_ORIGINAL_Y]) > 1.0) {
            SetVehiclePos(vehicleid, 
                Lowrider[playerid][E_LOWRIDER_ORIGINAL_X],
                Lowrider[playerid][E_LOWRIDER_ORIGINAL_Y],
                z 
            );
        }

        if (floatabs(currentAngle - Lowrider[playerid][E_LOWRIDER_ORIGINAL_ANGLE]) > 10.0) {
            SetVehicleZAngle(vehicleid, Lowrider[playerid][E_LOWRIDER_ORIGINAL_ANGLE]);
        }

        new currentArrowCount = PlayerCurrentMoveIndex[playerid];
        new Float:moveSpeed = INITIAL_MOVE_SPEED;
        
        if (currentArrowCount > 40) {
            moveSpeed = INITIAL_MOVE_SPEED * 2.0;
        } else if (currentArrowCount > 20) {
            moveSpeed = INITIAL_MOVE_SPEED * 1.5;
        }


        if (currentArrowCount >= 100) {
            StopLowriderChallenge(playerid, Lowrider[playerid][E_LOWRIDER_RIVAL], 0);
            return 1;
        }
        
        if (PlayerCurrentMoveCD[playerid] < gettime() && PlayerCurrentMoveIndex[playerid] < MAX_MOVE_TDS) {
            PlayerCurrentMoveCD[playerid] = gettime() + random(
                max(1, 2 - (currentArrowCount / 20))
            );

            new arrowType = GetArrowType(playerid);
            PlayerArrowTypes[playerid][PlayerCurrentMoveIndex[playerid]] = arrowType;

            CreateLowriderMovingKey(playerid, PlayerCurrentMoveIndex[playerid], 
                LOWRIDER_TD_X_MAX, 
                arrowTypes[arrowType]);
                
            PlayerCurrentMoveIndex[playerid]++;

            // Update all existing keys with new speed
            for (new i = 0; i < currentArrowCount; i++) {
                if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
                    LowriderKeyPos[playerid][i] -= moveSpeed;
                    CreateLowriderMovingKey(playerid, i, LowriderKeyPos[playerid][i], 
                        arrowTypes[PlayerArrowTypes[playerid][i]]);
                }
            }
        }

        // Camera switching
        if (CamSwitchCD[playerid] < gettime())
        {
            new index = LowriderCamIndex[playerid];
            if(index >= sizeof(LowriderCameras) - 1) index = 0;
            else index++;

            SetPlayerLowriderCamera(playerid, index);
        }

        // Define the hit zone position
        const Float:HIT_ZONE_TOLERANCE = 8.0;

        // Update positions of existing TextDraws
        for (new i = 0; i < MAX_MOVE_TDS; i++) {
            if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
                // Move to the left
                LowriderKeyPos[playerid][i] -= 1.2;

                // Update the textdraw position with the same arrow type
                CreateLowriderMovingKey(playerid, i, LowriderKeyPos[playerid][i], 
                    arrowTypes[PlayerArrowTypes[playerid][i]]);

                if (LowriderKeyPos[playerid][i] <= LOWRIDER_TD_HITZONE + HIT_ZONE_TOLERANCE && 
                    LowriderKeyPos[playerid][i] >= LOWRIDER_TD_HITZONE - HIT_ZONE_TOLERANCE) {
                    TextDrawShowForPlayer(playerid, GameTD[GAME_LOWRIDER][1]);
                    SetTimerEx("HideHitIndicator", 100, false, "i", playerid);
                }

                if (LowriderKeyPos[playerid][i] < LOWRIDER_TD_X_MIN) {
                    PlayerTextDrawDestroy(playerid, KeyPTD[playerid][i]);
                    KeyPTD[playerid][i] = INVALID_PLAYER_TEXT_DRAW;
                    PlayerArrowTypes[playerid][i] = -1;
                }
            }
        }
    }
    return 1;
}
forward HideHitIndicator(playerid);
// Hides the hit indicator.
public HideHitIndicator(playerid) {
    TextDrawHideForPlayer(playerid, GameTD[GAME_LOWRIDER][1]);
}

// Hides the lowrider textdraws.
stock HideLowriderTD(playerid)
{
    TextDrawHideForPlayer(playerid, GameTD[GAME_LOWRIDER][0]);
    TextDrawHideForPlayer(playerid, GameTD[GAME_LOWRIDER][1]);
    
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
StopLowriderChallenge(playerid, challenger, cancelled = 0)
{
    new playername[MAX_PLAYER_NAME], challengername[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playername, sizeof(playername));
    GetPlayerName(challenger, challengername, sizeof(challengername));
    if(!cancelled)
    {
        // new string[128];
        if(Lowrider[playerid][E_LOWRIDER_SCORE] > Lowrider[challenger][E_LOWRIDER_SCORE]) // playerid won
        {
            new pot = g_CurrentChallengePot[playerid];
            AwardWagerPot(playerid, challenger);
            new winner[MAX_PLAYER_NAME];

            GetPlayerName(playerid, winner, sizeof(winner));

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            
            ShowPlayerMinigameResult(playerid, "WINNER!", pot, .showtime = 5000);
            GiveFnRPoints(playerid, 5, "Lowrider Victory", false);
            AddPlayerRespect(playerid, 2);
            //format(string, sizeof(string), "Tough luck! You ~r~lost ~w~the challenge!~n~Your Score: ~r~%d ~w~Opponent's Score: ~b~~h~~h~%d", Lowrider[challenger][E_LOWRIDER_SCORE], Lowrider[playerid][E_LOWRIDER_SCORE]);
            
            ShowPlayerMinigameResult(challenger, "~r~ mission failed!", 0, .showtime = 5000);
            ShowPlayerSubtitle(challenger, sprintf("~r~You lost $%d to %s in a lowrider duel.", pot / 2, winner), .showtime = 5000);
            AddPlayerRespect(challenger, -2);
        }
        else if(Lowrider[playerid][E_LOWRIDER_SCORE] < Lowrider[challenger][E_LOWRIDER_SCORE]) // challenger won
        {
            new pot = g_CurrentChallengePot[playerid];
            AwardWagerPot(challenger, playerid);
            new winner[MAX_PLAYER_NAME];

            GetPlayerName(challenger, winner, sizeof(winner));
            //format(string, sizeof(string), "You ~g~won ~w~the challenge!~n~Your Score: ~b~~h~~h~%d ~w~Opponent's Score: ~r~%d", Lowrider[challenger][E_LOWRIDER_SCORE], Lowrider[playerid][E_LOWRIDER_SCORE]);

            ShowPlayerMinigameResult(challenger, "WINNER!", pot, .showtime = 5000);
            GiveFnRPoints(challenger, 5, "Lowrider Victory", false);
            AddPlayerRespect(challenger, 2);
            //format(string, sizeof(string), "Tough luck! You ~r~lost ~w~the challenge!~n~Your Score: ~r~%d ~w~Opponent's Score: ~b~~h~~h~%d", Lowrider[playerid][E_LOWRIDER_SCORE], Lowrider[challenger][E_LOWRIDER_SCORE]);

            ShowPlayerMinigameResult(playerid, "~r~ mission failed!", 0, .showtime = 5000);
            ShowPlayerSubtitle(playerid, sprintf("~r~You lost $%d to %s in a lowrider duel.", pot / 2, winner), .showtime = 5000);
            AddPlayerRespect(playerid, -2);
        }
        else // Draw
        {
            new pot = g_CurrentChallengePot[playerid];
            
            new halfPot = pot / 2;
            
            GivePlayerCash(playerid, halfPot, "Lowrider minigame draw");
            GivePlayerCash(challenger, halfPot, "Lowrider minigame draw");


            ShowPlayerMinigameResult(playerid, "draw!", halfPot, .showtime = 5000);
            ShowPlayerMinigameResult(challenger, "draw!", halfPot, .showtime = 5000);
            

            // if (playerid != challenger) {
            //     AddPlayerRespect(playerid, 2);
            //     AddPlayerRespect(challenger, 2);
            //     GiveFnRPoints(playerid, 2, "Lowrider Draw");
            //     GiveFnRPoints(challenger, 2, "Lowrider Draw");
            // }
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
            // The loser's stake was taken when the duel was accepted, so the winner just collects the pot.
            GivePlayerCash(challenger, pot, "Lowrider minigame winner (Cancel)"); 

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
    if(Lowrider[playerid][E_LOWRIDER_SCORE] > Lowrider[challenger][E_LOWRIDER_SCORE]) {
        format(winnerMsg, sizeof(winnerMsg), "%s won the lowrider battle against %s!", playername, challengername);
    }
    else if(Lowrider[challenger][E_LOWRIDER_SCORE] > Lowrider[playerid][E_LOWRIDER_SCORE]) {
        format(winnerMsg, sizeof(winnerMsg), "%s won the lowrider battle against %s!", challengername, playername);
    }
    else {
        format(winnerMsg, sizeof(winnerMsg), "The lowrider battle between %s and %s ended in a tie!", playername, challengername);
    }


    HideLowriderTD(playerid);
    HideLowriderTD(challenger);

    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
    PlayerPlaySound(challenger, 0, 0.0, 0.0, 0.0);
    
    SetEngineStatus(GetPlayerVehicleID(playerid), true);
    SetEngineStatus(GetPlayerVehicleID(challenger), true);

    SetCameraBehindPlayer(playerid);
    ShowVehicleGUI(playerid);
    
    SetCameraBehindPlayer(challenger);
    ShowVehicleGUI(challenger);

    ResetLowriderPlayerState(playerid, false);
    Lowrider[playerid][E_LOWRIDER_SCORE] = 0;

    ResetLowriderPlayerState(challenger, false);
    Lowrider[challenger][E_LOWRIDER_SCORE] = 0;

    new battleId = Lowrider[playerid][E_LOWRIDER_BATTLE_ID];
    if(battleId != INVALID_BATTLE_ID) {
        if(g_BattleData[battleId][E_BATTLE_LABEL] != DynamicText3D:INVALID_3DTEXT_ID) {
            DestroyDynamic3DTextLabel(g_BattleData[battleId][E_BATTLE_LABEL]);
        }
        g_BattleData[battleId][E_BATTLE_ACTIVE] = false;
        g_BattleData[battleId][E_BATTLE_PLAYER1] = INVALID_PLAYER_ID;
        g_BattleData[battleId][E_BATTLE_PLAYER2] = INVALID_PLAYER_ID;
        g_BattleData[battleId][E_BATTLE_LABEL] = DynamicText3D:INVALID_3DTEXT_ID;
        g_CurrentBattles--;
    }

    return 1;
}

// ========================================== Testing Development
// ==============================================================

/*CMD:testdrag(playerid) 
{
    if(force_tds == 0) return 1;
    force_tds = 1;

    // Reset player-specific variables
    PlayerCurrentMoveIndex[playerid] = 0;
    PlayerCurrentMoveCD[playerid] = gettime();
    LowriderCreateCD[playerid] = 0;
    LowriderMoveCD[playerid] = 0;
    LowriderKeyQueue[playerid] = 0;
    PlayerLowriderScore[playerid] = 0;
    OpponentLowriderScore[playerid] = 0;
    LastGeneratedArrow[playerid] = -1;


    // Initialize TextDraws
    for (new i = 0; i < MAX_MOVE_TDS; i++) {
        LowriderKeyPos[playerid][i] = LOWRIDER_TD_X_MAX;
        if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, KeyPTD[playerid][i]);
        }
        KeyPTD[playerid][i] = INVALID_PLAYER_TEXT_DRAW;
        PlayerArrowTypes[playerid][i] = -1;
    }

    // if (FeedbackTD[playerid] != INVALID_TEXT_DRAW) {
    //     InitializeFeedbackTextDraw();
    // }

    // Show the game interface
    TextDrawShowForPlayer(playerid, GameTD[GAME_LOWRIDER][0]);
    
    // Show score displays
    PlayerTextDrawShow(playerid, SubmPTD[playerid][0]);
    PlayerTextDrawSetString(playerid, SubmPTD[playerid][1], "0~n~0~n~");
    PlayerTextDrawShow(playerid, SubmPTD[playerid][1]);

    SendClientMessage(playerid, -1, "You have started the Lowrider GUI test with 60 arrows. Use arrow keys to hit the notes!");
    PlayerPlaySound(playerid, 180, 0.0, 0.0, 0.0);
    Lowrider[playerid][E_LOWRIDER_ACTIVE] = true;

    SetPlayerLowriderCamera(playerid, 0);
    HideVehicleGUI(playerid);

    return 1;
}

// /stopdrag - stops the minigame early.
CMD:stopdrag(playerid) {
    if(force_tds == 0) return 1;
    if (!force_tds) return SendClientMessage(playerid, -1, "The lowrider minigame is not active!");
    
    force_tds = 0;
    
    // Hide game interface
    TextDrawHideForPlayer(playerid, GameTD[GAME_LOWRIDER][0]);
    TextDrawHideForPlayer(playerid, GameTD[GAME_LOWRIDER][1]);
    
    // Hide score displays
    PlayerTextDrawHide(playerid, SubmPTD[playerid][0]);
    PlayerTextDrawHide(playerid, SubmPTD[playerid][1]);
    PlayerTextDrawHide(playerid, SubmPTD[playerid][2]);
    
    // Destroy all arrow textdraws
    for (new i = 0; i < MAX_MOVE_TDS; i++) {
        if (KeyPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, KeyPTD[playerid][i]);
            KeyPTD[playerid][i] = INVALID_PLAYER_TEXT_DRAW;
        }
    }
    
    Lowrider[playerid][E_LOWRIDER_ACTIVE] = false;
    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
    SendClientMessage(playerid, -1, "You have stopped the Lowrider GUI test.");

    SetCameraBehindPlayer(playerid);
    ShowVehicleGUI(playerid);

    return 1;
}

*/
