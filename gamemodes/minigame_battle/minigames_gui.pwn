// ============================================================================
// File: minigame_battle/minigames_gui.pwn
// Shared battle textdraws: moving arrows, hit feedback, wager display and results. Developed by
// Tramposo.
// ============================================================================

/*
// ------------------------------------- Minigame GUI System ------------------------------------- //
// ------------------------------------ Developed by Tramposo ------------------------------------ //
*/

#define MAX_MOVE_TDS (100)
#define FEEDBACK_MESSAGES_COUNT (4)

new Text:GameTD[E_GAME_TYPE:2][2]; // [gameType][tdIndex]
new PlayerText:KeyPTD[MAX_PLAYERS][MAX_MOVE_TDS];
new PlayerText:SubmPTD[MAX_PLAYERS][3];
new PlayerText:WagerPTD[MAX_PLAYERS][4];
new PlayerText:FeedbackTD[MAX_PLAYERS];


#include <YSI_Coding\y_hooks>

hook OnGameModeInit() {
    GameTD[GAME_LOWRIDER][0] = TextDrawCreate(292.000000, 350.000000, "LD_BEAT:cring");
    SetupGameTD(GameTD[GAME_LOWRIDER][0]);
    
    GameTD[GAME_LOWRIDER][1] = TextDrawCreate(292.000000, 350.000000, "LD_BEAT:chit");
    SetupHitTD(GameTD[GAME_LOWRIDER][1]);
    
    GameTD[GAME_DANCING][0] = TextDrawCreate(292.000000, 350.000000, "LD_BEAT:cring");
    SetupGameTD(GameTD[GAME_DANCING][0]);
    
    GameTD[GAME_DANCING][1] = TextDrawCreate(292.000000, 350.000000, "LD_BEAT:chit");
    SetupHitTD(GameTD[GAME_DANCING][1]);
    
    return 1;
}

hook OnPlayerConnect(playerid) {
    // movement TextDraws
    for(new m = 0; m < MAX_MOVE_TDS; m++) {
        KeyPTD[playerid][m] = PlayerText:INVALID_PLAYER_TEXT_DRAW;
    }
    
    CreateSubmissionTDs(playerid);
    CreateWagerTDs(playerid);
    CreateFeedbackTD(playerid);
    
    return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
    // Cleanup movement
    for(new m = 0; m < MAX_MOVE_TDS; m++) {
        if(KeyPTD[playerid][m] != INVALID_PLAYER_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, KeyPTD[playerid][m]);
            KeyPTD[playerid][m] = PlayerText:INVALID_PLAYER_TEXT_DRAW;
        }
    }
    
    // Cleanup submission
    for(new i = 0; i < 3; i++) {
        if(SubmPTD[playerid][i] != INVALID_PLAYER_TEXT_DRAW) {
            PlayerTextDrawDestroy(playerid, SubmPTD[playerid][i]);
            SubmPTD[playerid][i] = PlayerText:INVALID_PLAYER_TEXT_DRAW;
        }
    }
    
    // Cleanup feedback
    PlayerTextDrawDestroy(playerid, FeedbackTD[playerid]);
    
    return 1;
}

// set up game TextDraw properties
stock SetupGameTD(Text:tdid) {
    TextDrawBackgroundColor(tdid, 255);
    TextDrawFont(tdid, 4);
    TextDrawLetterSize(tdid, 0.500000, 1.000000);
    TextDrawColor(tdid, -1);
    TextDrawSetOutline(tdid, 0);
    TextDrawSetProportional(tdid, 1);
    TextDrawSetShadow(tdid, 1);
    TextDrawUseBox(tdid, 1);
    TextDrawBoxColor(tdid, 255);
    TextDrawTextSize(tdid, 64.000000, 64.000000);
    TextDrawSetSelectable(tdid, 0);
}

// set up hit TextDraw properties
stock SetupHitTD(Text:tdid) {
    TextDrawBackgroundColor(tdid, 255);
    TextDrawFont(tdid, 4);
    TextDrawLetterSize(tdid, 0.500000, 1.000000);
    TextDrawColor(tdid, -181);
    TextDrawSetOutline(tdid, 0);
    TextDrawSetProportional(tdid, 1);
    TextDrawSetShadow(tdid, 1);
    TextDrawUseBox(tdid, 1);
    TextDrawBoxColor(tdid, 255);
    TextDrawTextSize(tdid, 64.000000, 64.000000);
    TextDrawSetSelectable(tdid, 0);
}

// Creates the score/result textdraws shared by the battle minigames.
stock CreateSubmissionTDs(playerid) {
    SubmPTD[playerid][0] = CreatePlayerTextDraw(playerid, 519.000000, 135.000000, "_");
    PlayerTextDrawAlignment(playerid, SubmPTD[playerid][0], 3);
    PlayerTextDrawBackgroundColor(playerid, SubmPTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, SubmPTD[playerid][0], 2);
    PlayerTextDrawLetterSize(playerid, SubmPTD[playerid][0], 0.380000, 1.600000);
    PlayerTextDrawColor(playerid, SubmPTD[playerid][0], -1278086145);
    PlayerTextDrawSetOutline(playerid, SubmPTD[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, SubmPTD[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, SubmPTD[playerid][0], 0);

    SubmPTD[playerid][1] = CreatePlayerTextDraw(playerid, 604.000000, 150.000000, "~n~0");
    PlayerTextDrawAlignment(playerid, SubmPTD[playerid][1], 3);
    PlayerTextDrawBackgroundColor(playerid, SubmPTD[playerid][1], 255);
    PlayerTextDrawFont(playerid, SubmPTD[playerid][1], 2);
    PlayerTextDrawLetterSize(playerid, SubmPTD[playerid][1], 0.380000, 1.600000);
    PlayerTextDrawColor(playerid, SubmPTD[playerid][1], -1278086145);
    PlayerTextDrawSetOutline(playerid, SubmPTD[playerid][1], 1);
    PlayerTextDrawSetProportional(playerid, SubmPTD[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, SubmPTD[playerid][1], 0);

    SubmPTD[playerid][2] = CreatePlayerTextDraw(playerid, 320.000000, 60.000000, "~r~bad");
    PlayerTextDrawAlignment(playerid, SubmPTD[playerid][2], 2);
    PlayerTextDrawBackgroundColor(playerid, SubmPTD[playerid][2], 255);
    PlayerTextDrawFont(playerid, SubmPTD[playerid][2], 3);
    PlayerTextDrawLetterSize(playerid, SubmPTD[playerid][2], 1.039999, 3.599998);
    PlayerTextDrawColor(playerid, SubmPTD[playerid][2], -1);
    PlayerTextDrawSetOutline(playerid, SubmPTD[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, SubmPTD[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, SubmPTD[playerid][2], 0);
}

// Create wager TextDraws for a player
stock CreateWagerTDs(playerid) {
    WagerPTD[playerid][0] = CreatePlayerTextDraw(playerid, 29.9999, 219.5182, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, WagerPTD[playerid][0], 128.0000, 170.5103);
    PlayerTextDrawAlignment(playerid, WagerPTD[playerid][0], 1);
    PlayerTextDrawColor(playerid, WagerPTD[playerid][0], 150);
    PlayerTextDrawBackgroundColor(playerid, WagerPTD[playerid][0], 255);
    PlayerTextDrawFont(playerid, WagerPTD[playerid][0], 4);
    PlayerTextDrawSetProportional(playerid, WagerPTD[playerid][0], 0);
    PlayerTextDrawSetShadow(playerid, WagerPTD[playerid][0], 0);

    WagerPTD[playerid][1] = CreatePlayerTextDraw(playerid, 38.3333, 240.2111, "This_Wager~n~~n~Min_Wager~n~~n~Max_Wager"); 
    PlayerTextDrawLetterSize(playerid, WagerPTD[playerid][1], 0.4713, 2.5076);
    PlayerTextDrawAlignment(playerid, WagerPTD[playerid][1], 1);
    PlayerTextDrawColor(playerid, WagerPTD[playerid][1], 1971823103);
    PlayerTextDrawBackgroundColor(playerid, WagerPTD[playerid][1], 255);
    PlayerTextDrawFont(playerid, WagerPTD[playerid][1], 1);
    PlayerTextDrawSetProportional(playerid, WagerPTD[playerid][1], 1);
    PlayerTextDrawSetShadow(playerid, WagerPTD[playerid][1], 2);

    WagerPTD[playerid][2] = CreatePlayerTextDraw(playerid, 38.3333, 262.7110, "$150~n~~n~$150~n~~n~$5000"); 
    PlayerTextDrawLetterSize(playerid, WagerPTD[playerid][2], 0.4713, 2.5076);
    PlayerTextDrawAlignment(playerid, WagerPTD[playerid][2], 1);
    PlayerTextDrawColor(playerid, WagerPTD[playerid][2], -1263225601);
    PlayerTextDrawBackgroundColor(playerid, WagerPTD[playerid][2], 255);
    PlayerTextDrawFont(playerid, WagerPTD[playerid][2], 1);
    PlayerTextDrawSetProportional(playerid, WagerPTD[playerid][2], 1);
    PlayerTextDrawSetShadow(playerid, WagerPTD[playerid][2], 2);

    WagerPTD[playerid][3] = CreatePlayerTextDraw(playerid, 39.1666, 203.9999, "Wager"); 
    PlayerTextDrawLetterSize(playerid, WagerPTD[playerid][3], 1.0080, 2.7318);
    PlayerTextDrawAlignment(playerid, WagerPTD[playerid][3], 1);
    PlayerTextDrawColor(playerid, WagerPTD[playerid][3], -1);
    PlayerTextDrawSetOutline(playerid, WagerPTD[playerid][3], 2);
    PlayerTextDrawBackgroundColor(playerid, WagerPTD[playerid][3], 255);
    PlayerTextDrawFont(playerid, WagerPTD[playerid][3], 0);
    PlayerTextDrawSetProportional(playerid, WagerPTD[playerid][3], 1);
    PlayerTextDrawSetShadow(playerid, WagerPTD[playerid][3], 0);
}

// Creates the centre-screen feedback text (perfect, good, miss).
stock CreateFeedbackTD(playerid) {
    FeedbackTD[playerid] = CreatePlayerTextDraw(playerid, 320.000000, 110.00, "KEEP IT UP");
    PlayerTextDrawFont(playerid, FeedbackTD[playerid], 2);
    PlayerTextDrawLetterSize(playerid, FeedbackTD[playerid], 0.520833, 2.949999);
    PlayerTextDrawTextSize(playerid, FeedbackTD[playerid], 439.000000, 175.000000);
    PlayerTextDrawSetOutline(playerid, FeedbackTD[playerid], 1);
    PlayerTextDrawSetShadow(playerid, FeedbackTD[playerid], 0);
    PlayerTextDrawAlignment(playerid, FeedbackTD[playerid], 2);
    PlayerTextDrawColor(playerid, FeedbackTD[playerid], -1);
    PlayerTextDrawBackgroundColor(playerid, FeedbackTD[playerid], 255);
    PlayerTextDrawBoxColor(playerid, FeedbackTD[playerid], 50);
    PlayerTextDrawUseBox(playerid, FeedbackTD[playerid], 0);
    PlayerTextDrawSetProportional(playerid, FeedbackTD[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, FeedbackTD[playerid], 0);
}

forward ShowBattleTDs(playerid, challenger, E_GAME_TYPE:gameType);
// Shows the battle HUD for the two players.
public ShowBattleTDs(playerid, challenger, E_GAME_TYPE:gameType) {
    new playerName[MAX_PLAYER_NAME], challengerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));
    GetPlayerName(challenger, challengerName, sizeof(challengerName));

    new playerDisplay[MAX_PLAYER_NAME + 20];
    new challengerDisplay[MAX_PLAYER_NAME + 20];
    format(playerDisplay, sizeof(playerDisplay), "~n~%s~n~%s~n~", playerName, challengerName);
    format(challengerDisplay, sizeof(challengerDisplay), "~n~%s~n~%s~n~", challengerName, playerName);

    PlayerTextDrawSetString(playerid, SubmPTD[playerid][0], playerDisplay);
    PlayerTextDrawShow(playerid, SubmPTD[playerid][0]);
    PlayerTextDrawSetString(playerid, SubmPTD[playerid][1], "0~n~0~n~");
    PlayerTextDrawShow(playerid, SubmPTD[playerid][1]);
    TextDrawShowForPlayer(playerid, GameTD[gameType][0]);

    PlayerTextDrawSetString(challenger, SubmPTD[challenger][0], challengerDisplay);
    PlayerTextDrawShow(challenger, SubmPTD[challenger][0]);
    PlayerTextDrawSetString(challenger, SubmPTD[challenger][1], "0~n~0~n~");
    PlayerTextDrawShow(challenger, SubmPTD[challenger][1]);
    TextDrawShowForPlayer(challenger, GameTD[gameType][0]);
}

