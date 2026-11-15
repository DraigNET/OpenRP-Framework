// ============================================================================
// File: minigame_battle/dancing/game.pwn
// /dancebattle: challenging another player to a dance battle, invite expiry and validation.
// Commands: /dancebattle
// ============================================================================

new Dancing_ExpireTimer[MAX_PLAYERS];
#define DANCING_INVITE_TIMEOUT 20000 // 20 seconds

forward onDancingInviteExpire(playerid, targetid);
// Timer callback: cancels a dance battle invite that was not answered.
public onDancingInviteExpire(playerid, targetid)
{
    // #Only expire if the challenge is still pending
    if(mgDancing[playerid][E_DANCING_OFFER] && mgDancing[playerid][E_DANCING_RIVAL] == targetid)
    {
        mgDancing[playerid][E_DANCING_OFFER] = false;
        mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
        PlayerWagerData[playerid][WagerAmount] = 0;
        PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
        PlayerWagerData[playerid][InWagerMenu] = false;
        
        mgDancing[targetid][E_DANCING_OFFER] = false;
        mgDancing[targetid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
        PlayerWagerData[targetid][WagerAmount] = 0;
        PlayerWagerData[targetid][WagerAmount] = INVALID_PLAYER_ID;
        PlayerWagerData[targetid][InWagerMenu] = false;

        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your dance battle invite has expired.");
        SendServerMessage(targetid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "The dance battle invite has expired.");
    }
    return 1;
}

// /dancebattle [challenge/accept/cancel] - challenge another player to a dance battle.
CMD:dancebattle(playerid, params[]) {
    new option[10], targetid = INVALID_PLAYER_ID;
    if(sscanf(params, "s[10] ", option)){
        return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "/dancebattle [challenge, accept, cancel]");
    }

    // new string[128];
    if(!strcmp(option, "challenge", true))
    {
        if(sscanf(params, "s[10] k<player>", option, targetid))
            return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "/dancebattle challenge (playerid)");

        if(!IsPlayerConnected(targetid)) {
            return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "The player you challenged is not connected.");
        }

        if(!IsPlayerNearPlayer(playerid, targetid, 15.0))
            return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You must be close to the player to challenge them.");

        // if(playerid == targetid)
        //     return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You cannot challenge yourself.");

        // Are both players available and proper to do the challenge?
        if(IsDanceBattleValid(playerid, targetid)) 
        {
            if(Dancing_ExpireTimer[playerid] != 0) 

            {
                KillTimer(Dancing_ExpireTimer[playerid]);
                Dancing_ExpireTimer[playerid] = 0;
            }

            PlayerWagerData[playerid][WagerTarget] = targetid;
            PlayerWagerData[playerid][WagerAmount] = playerid;

            // Start the expiration timer
            Dancing_ExpireTimer[playerid] = SetTimerEx("onDancingInviteExpire", LOWRIDER_INVITE_TIMEOUT, false, "ii", playerid, targetid);

            SetPlayerFrontCamera(playerid, 10.0);
            PlayerWagerData[playerid][InWagerMenu] = true;
            PlayerWagerData[playerid][WagerAmount] = WAGER_MIN;

            ShowPlayerInfoMessage(playerid, "~k~~PED_JUMPING~ Increase Wager~n~~k~~PED_FIREWEAPON~ Decrease Wager~n~~k~~PED_SPRINT~ Proceed~n~~k~~VEHICLE_ENTER_EXIT~ Exit", .height=140.0, .width=180, .showtime=6000);
            
            ShowWagerMenu(playerid, WAGER_TYPE_DANCING);
        }
        // No need for an error message here - errors are handled by IsDanceBattleValid.
    }

    else if(!strcmp(option, "accept", true)) {

        new challenger = mgDancing[playerid][E_DANCING_RIVAL];

        if(challenger != INVALID_PLAYER_ID && IsPlayerConnected(challenger)) {

            if(mgDancing[challenger][E_DANCING_OFFER] && mgDancing[playerid][E_DANCING_OFFER]) {

                new challengerid = mgDancing[playerid][E_DANCING_RIVAL];
                new wagerAmount = g_CurrentChallengePot[challengerid];

                if(!CanPlayersAffordWager(playerid, challengerid, wagerAmount / 2))
                {
                    mgDancing[playerid][E_DANCING_OFFER] = false;
                    mgDancing[challengerid][E_DANCING_OFFER] = false;
                    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[challengerid][WagerTarget] = INVALID_PLAYER_ID;
                    return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "One of the players cannot afford the wager.");
                }

                if(Dancing_ExpireTimer[challenger] != 0) {  
                    KillTimer(Dancing_ExpireTimer[challenger]);
                    Dancing_ExpireTimer[challenger] = 0;
                }

                TakePlayerCash(playerid, wagerAmount / 2, "Dance battle challenge wager");
                TakePlayerCash(challenger, wagerAmount / 2, "Dance battle challenge wager");

                mgDancing[challenger][E_DANCING_OFFER] = false;
                mgDancing[playerid][E_DANCING_OFFER] = false;

                SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You have accepted the dance battle challenge.");
                SendServerMessage(challenger, COLOR_DANCING, "Dance-Battle", "DEDEDE", "They have accepted the dance battle challenge.");

                StartDanceBattle(playerid, challenger, g_CurrentChallengePot[playerid]);
            }
            else return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Both you and your rival must have an open offer pending.");
        }
        else return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your rival has either cancelled the offer or has disconnected.");
    }
    
    else if(!strcmp(option, "cancel", true)) {
        if(!mgDancing[playerid][E_DANCING_OFFER])
            return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You do not have any outsstanding challenge offers.");

        new challenger = mgDancing[playerid][E_DANCING_RIVAL];
        if(challenger == INVALID_PLAYER_ID || !IsPlayerConnected(challenger))
        {
            if(Dancing_ExpireTimer[playerid] != 0) 
            {
                KillTimer(Dancing_ExpireTimer[playerid]);
                Dancing_ExpireTimer[playerid] = 0;
            }

            mgDancing[playerid][E_DANCING_OFFER] = false;
            mgDancing[playerid][E_DANCING_ACTIVE] = false;
            mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerAmount] = 0;
            PlayerWagerData[challenger][InWagerMenu] = false;

            SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your rival has disconnected. You have been removed from the challenge.");
            return 1;
        }

        if(mgDancing[playerid][E_DANCING_ACTIVE]) {

            // Resetting player variables
            if(Dancing_ExpireTimer[playerid] != 0) 
            {
                KillTimer(Dancing_ExpireTimer[playerid]);
                Dancing_ExpireTimer[playerid] = 0;
            }
            mgDancing[playerid][E_DANCING_OFFER] = false;
            mgDancing[playerid][E_DANCING_ACTIVE] = false;
            mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerAmount] = 0;


            SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You have forfeited the dance battle. You lose!");

            // Resetting challenger variables
            mgDancing[challenger][E_DANCING_OFFER] = false;
            mgDancing[challenger][E_DANCING_ACTIVE] = false;
            mgDancing[challenger][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][InWagerMenu] = false;
            SendServerMessage(challenger, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your rival has forfeited the dance battle. You win!");

            StopDanceBattle(playerid, challenger, 1);
            return 1;
        }
        
        else {
            // Cancel outstanding offer.
            if(mgDancing[playerid][E_DANCING_OFFER] && mgDancing[playerid][E_DANCING_RIVAL] == challenger) {
                if(mgDancing[challenger][E_DANCING_OFFER] && mgDancing[challenger][E_DANCING_RIVAL] == playerid) {
                    
                    // Resetting challenger variables
                    if(Dancing_ExpireTimer[playerid] != 0) 
                    {
                        KillTimer(Dancing_ExpireTimer[playerid]);
                        Dancing_ExpireTimer[playerid] = 0;
                    }                   
                    mgDancing[challenger][E_DANCING_OFFER] = false;
                    mgDancing[challenger][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
                    PlayerWagerData[challenger][WagerAmount] = 0;
                    PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[challenger][InWagerMenu] = false;
                    SendServerMessage(challenger, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your dance battle offer has been refused.");

                    // Resetting player variables
                    mgDancing[playerid][E_DANCING_OFFER] = false;
                    mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][WagerAmount] = 0;
                    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][InWagerMenu] = false;
                    SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You have refused the dance battle offer.");
                    
                    return true;
                }
                else {
                    // Challenger doesn't have a valid outstanding offer, just reset the player and inform them.
                    mgDancing[playerid][E_DANCING_OFFER] = false;
                    mgDancing[playerid][E_DANCING_RIVAL] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][WagerAmount] = 0;
                    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][InWagerMenu] = false;

                    return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Your rival has either cancelled the offer or has disconnected.");
                }
            }
            else return SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You do not have an active offer to cancel.");
        }

    }
    return 1;
}

// Returns true if a dance battle can start between two players.
IsDanceBattleValid(playerid, rival) {
    // Player checks
    if(mgDancing[playerid][E_DANCING_ACTIVE]) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You're already in an active game. Use {A3A3A3}/dancebattle cancel{DEDEDE}.");
        return false;
    }
    if(mgDancing[playerid][E_DANCING_RIVAL] != INVALID_PLAYER_ID) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You already have a rival! Use {A3A3A3}/dancebattle cancel{DEDEDE}.");
        return false;
    }
    if(mgDancing[playerid][E_DANCING_OFFER]) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "You already have an offer! Use {A3A3A3}/dancebattle accept{DEDEDE} or {A3A3A3}/dancebattle cancel{DEDEDE}.");
        return false;
    }

    // Rival checks
    if(mgDancing[rival][E_DANCING_ACTIVE]) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Player is already in an active game.");
        return false;
    }
    if(mgDancing[rival][E_DANCING_RIVAL] != INVALID_PLAYER_ID) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Player already has a rival!");
        return false;
    }
    if(mgDancing[rival][E_DANCING_OFFER]) {
        SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Player already has an offer!");
        return false;
    }
    return true;
}

// Sends a dance battle challenge with the wager pot.
stock SendDanceBattle(playerid, challenger, pot)
{
    g_CurrentChallengePot[playerid] = pot;
    g_CurrentChallengePot[challenger] = pot;
    mgDancing[playerid][E_DANCING_OFFER] = true;
    mgDancing[playerid][E_DANCING_RIVAL] = challenger;
    mgDancing[challenger][E_DANCING_OFFER] = true;
    mgDancing[challenger][E_DANCING_RIVAL] = playerid;

    new string[128];
    format(string, sizeof(string), "%s{DEDEDE} has challenged you to a dance battle with a wager of $%d.", ReturnSettingsName(playerid, challenger, true, true), pot / 2);
    SendServerMessage(challenger, COLOR_DANCING, "Dance-Battle", "DEDEDE", string);
    SendServerMessage(challenger, COLOR_DANCING, "Dance-Battle", "DEDEDE", "Use {F5B350}/dancebattle accept{DEDEDE} or {F5B350}/dancebattle cancel.");
    
    format(string, sizeof(string), "Waiting for response from %s{DEDEDE}. Wager locked at $%d. To cancel type {9C7A07}/dancebattle cancel", ReturnSettingsName(challenger, playerid, true, true), pot / 2);
    SendServerMessage(playerid, COLOR_DANCING, "Dance-Battle", "DEDEDE", string);
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(Dancing_ExpireTimer[playerid] != 0) {
        KillTimer(Dancing_ExpireTimer[playerid]);
        Dancing_ExpireTimer[playerid] = 0;
    }
    return 1;
}
