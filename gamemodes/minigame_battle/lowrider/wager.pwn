// ============================================================================
// File: minigame_battle/lowrider/wager.pwn
// Wager system for battles (/wagerlowrider, /wagerdancing): both players stake cash, the winner
// takes the pot. Developed by Tramposo.
// Commands: /wagerlowrider /wagerdancing
// ============================================================================

/*
// ------------------------------------- Global Wager System ------------------------------------- //
// ------------------------------------ Developed by Tramposo ------------------------------------ //
*/

#define WAGER_MIN 100
#define WAGER_MAX 10000
#define MAX_WAGER_TYPES 10

enum E_WAGER_TYPES {
    WAGER_TYPE_LOWRIDER,
    WAGER_TYPE_DANCING,
}

enum E_PLAYER_WAGER_DATA {
    bool:InWagerMenu,
    WagerAmount,
    WagerTarget,
    E_WAGER_TYPES:WagerType,
    bool:WagerAccepted,
    CurrentPot,
    PotOwner
}
new PlayerWagerData[MAX_PLAYERS][E_PLAYER_WAGER_DATA];

// Records the shared wager pot for two players in a battle.
stock SetupWagerPot(playerid, targetid, totalPot) {
    PlayerWagerData[playerid][CurrentPot] = totalPot;
    PlayerWagerData[targetid][CurrentPot] = totalPot;
    
    PlayerWagerData[playerid][PotOwner] = playerid;
    PlayerWagerData[targetid][PotOwner] = playerid;

    // The stakes are taken once, when the challenge is accepted (TakePlayerCash in game.pwn).
    new msg[128];
    format(msg, sizeof(msg), "Wager of $%d confirmed. Total pot: $%d", 
        totalPot / 2, 
        totalPot
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);
    SendClientMessage(targetid, COLOR_GREEN, msg);

    return 1;
}

// Opens the wager menu where a player picks how much to stake.
ShowWagerMenu(playerid, E_WAGER_TYPES:gameType) {
    PlayerWagerData[playerid][WagerType] = gameType;
    PlayerWagerData[playerid][WagerAmount] = WAGER_MIN;
    PlayerWagerData[playerid][InWagerMenu] = true;

    new gameTypeName[32];
    GetWagerTypeName(gameType, gameTypeName);

    PlayerTextDrawSetString(playerid, WagerPTD[playerid][2], sprintf("$%d~n~~n~$%d~n~~n~$%d", 
        PlayerWagerData[playerid][WagerAmount], 
        WAGER_MIN, 
        WAGER_MAX
    ));

    for(new m = 0; m < 4; m++) {
        PlayerTextDrawShow(playerid, WagerPTD[playerid][m]);
    }

    TogglePlayerControllable(playerid, false);
    return 1;
}

// Closes the wager menu and resets the player's wager data.
HideWagerMenu(playerid) {
    for(new m = 0; m < 4; m++) {
        PlayerTextDrawHide(playerid, WagerPTD[playerid][m]);
    }

    ResetPlayerWagerData(playerid);
    TogglePlayerControllable(playerid, true);
    SetCameraBehindPlayer(playerid);
    return 1;
}


// Raises the wager by $50 (up to what the player can afford and the maximum).
IncreaseWager(playerid) {
    if(PlayerWagerData[playerid][WagerAmount] + 50 >= GetPlayerCash(playerid))
        return 0;

    if(PlayerWagerData[playerid][WagerAmount] >= WAGER_MAX)
        return 0;

    PlayerWagerData[playerid][WagerAmount] += 50;
    UpdateWagerDisplay(playerid);
    return 1;
}

// Lowers the wager by $50 (down to the minimum).
DecreaseWager(playerid) {
    if(PlayerWagerData[playerid][WagerAmount] <= WAGER_MIN)
        return 0;

    PlayerWagerData[playerid][WagerAmount] -= 50;
    UpdateWagerDisplay(playerid);
    return 1;
}

// Confirms the wager and sends the challenge to the other player.
ProceedWager(playerid) {
    if(!IsValidWagerAmount(PlayerWagerData[playerid][WagerAmount])) {
        SendClientMessage(playerid, COLOR_RED, "Invalid wager amount.");
        return 0;
    }

    new targetid = PlayerWagerData[playerid][WagerTarget];
    if(targetid == INVALID_PLAYER_ID) {
        SendClientMessage(playerid, COLOR_RED, "No wager target selected.");
        return 0;
    }

    if(!CanPlayersAffordWager(playerid, targetid, PlayerWagerData[playerid][WagerAmount])) {
        return 0;
    }

    new totalPot = PlayerWagerData[playerid][WagerAmount] * 2;
    SetupWagerPot(playerid, targetid, totalPot);

    SendWagerChallenge(playerid, targetid, PlayerWagerData[playerid][WagerType]);
    
    HideWagerMenu(playerid);
    return 1;
}

// Sends a wager challenge to another player.
stock SendWagerChallenge(playerid, targetid, E_WAGER_TYPES:gameType) {
    new gameTypeName[32], msg[128];
    GetWagerTypeName(gameType, gameTypeName);
    
    format(msg, sizeof(msg), "%s has challenged you to a %s wager for $%d!", 
        ReturnPlayerName(playerid),
        gameTypeName,
        PlayerWagerData[playerid][WagerAmount]
    );
    SendClientMessage(targetid, COLOR_GREEN, msg);
    
    // Trigger game-specific challenge
    switch(gameType) {
        case WAGER_TYPE_LOWRIDER: {
            SendLowriderChallenge(playerid, targetid, PlayerWagerData[playerid][WagerAmount] * 2);
        }
        case WAGER_TYPE_DANCING: {
            SendDanceBattle(playerid, targetid, PlayerWagerData[playerid][WagerAmount] * 2);
        }
        // more game types here
    }
    return 1;
}

// Returns true if a wager amount is within the allowed minimum and maximum.
stock IsValidWagerAmount(amount) {
    if(amount < WAGER_MIN || amount > WAGER_MAX) {
        return 0;
    }
    return 1;
}

// if both players can afford the wager amount
stock CanPlayersAffordWager(playerid, targetid, amount) {
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid)) {
        return 0;
    }

    new playerCash = GetPlayerCash(playerid);
    new targetCash = GetPlayerCash(targetid);

    if(playerCash < amount || targetCash < amount) {
        return 0;
    }

    return 1;
}


// Exits the wager menu and resets player state
stock ExitWager(playerid) {
    if(!PlayerWagerData[playerid][InWagerMenu]) {
        return 0;
    }
    
    HideWagerMenu(playerid);
    SendClientMessage(playerid, COLOR_RED, "You have cancelled the wager.");
    return 1;
}

// Gives the whole pot to the winner of a battle.
stock AwardWagerPot(winnerid, loserid) {
    if(!IsPlayerConnected(winnerid) || !IsPlayerConnected(loserid)) {
        return 0;
    }

    new potAmount = PlayerWagerData[winnerid][CurrentPot];
    if(potAmount <= 0) {
        return 0;
    }

    // Give the winner the entire pot
    GivePlayerCash(winnerid, potAmount, "Lowrider minigame winner");

    // Reset wager data for both players
    ResetPlayerWagerData(winnerid);
    ResetPlayerWagerData(loserid);

    return 1;
}

// Writes the name of a wager game type into output.
stock GetWagerTypeName(E_WAGER_TYPES:gameType, output[], len = sizeof(output)) {
    switch(gameType) {
        case WAGER_TYPE_LOWRIDER: format(output, len, "Lowrider");
        case WAGER_TYPE_DANCING: format(output, len, "Dance Battle");
        default: format(output, len, "Unknown");
    }
}

// Resets a player's wager data.
stock ResetPlayerWagerData(playerid) {
    PlayerWagerData[playerid][InWagerMenu] = false;
    PlayerWagerData[playerid][WagerAmount] = 0;
    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
    PlayerWagerData[playerid][WagerAccepted] = false;
    PlayerWagerData[playerid][CurrentPot] = 0;
    PlayerWagerData[playerid][PotOwner] = INVALID_PLAYER_ID;
}


// Refreshes the wager menu text with the current amount and game.
stock UpdateWagerDisplay(playerid) {
    new gameTypeName[32];
    GetWagerTypeName(PlayerWagerData[playerid][WagerType], gameTypeName);
    
    PlayerTextDrawSetString(playerid, WagerPTD[playerid][2], sprintf("$%d~n~~n~$%d~n~~n~$%d", 
        PlayerWagerData[playerid][WagerAmount],
        WAGER_MIN,
        WAGER_MAX
    ));
}

/*
// /wagerlowrider [player] - starts a lowrider battle with a cash wager.
CMD:wagerlowrider(playerid, params[]) {
    new targetid;
    if(sscanf(params, "u", targetid)) {
        SendClientMessage(playerid, COLOR_RED, "USAGE: /wagerlowrider [playerid]");
        return 1;
    }
    
    PlayerWagerData[playerid][WagerTarget] = targetid;
    ShowWagerMenu(playerid, WAGER_TYPE_LOWRIDER);
    return 1;
}

// /wagerdancing [player] - starts a dance battle with a cash wager.
CMD:wagerdancing(playerid, params[]) {
    new targetid;
    if(sscanf(params, "u", targetid)) {
        SendClientMessage(playerid, COLOR_RED, "USAGE: /wagerdancing [playerid]");
        return 1;
    }
    
    PlayerWagerData[playerid][WagerTarget] = targetid;
    ShowWagerMenu(playerid, WAGER_TYPE_DANCING);
    return 1;
}
*/

// Key handling
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if(PlayerWagerData[playerid][InWagerMenu]) {
        if(newkeys & KEY_JUMP) IncreaseWager(playerid);
        if(newkeys & KEY_FIRE) DecreaseWager(playerid);
        if(newkeys & KEY_SPRINT) ProceedWager(playerid);
        if(newkeys & KEY_SECONDARY_ATTACK) ExitWager(playerid);
    }
    #if defined wager_OnPlayerKeyStateChange
        return wager_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange wager_OnPlayerKeyStateChange
#if defined wager_OnPlayerKeyStateChange
	forward wager_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
#endif
