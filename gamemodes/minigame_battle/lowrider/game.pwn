// ============================================================================
// File: minigame_battle/lowrider/game.pwn
// /lowrider: challenging another driver to a lowrider battle, invite expiry and validation.
// Commands: /lowrider
// ============================================================================

#define LOWRIDER_INVITE_TIMEOUT 20000 // 20 seconds

forward OnLowriderInviteExpire(playerid, targetid);
// Callback: cancels a lowrider invite that was not answered in time.
public OnLowriderInviteExpire(playerid, targetid)
{
    // #Only expire if the challenge is still pending
    if(Lowrider[playerid][E_LOWRIDER_OFFER] && Lowrider[playerid][E_LOWRIDER_RIVAL] == targetid)
    {
        ResetLowriderChallenge(playerid, targetid);
        
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your lowrider challenge invite has expired.");
        SendServerMessage(targetid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "The lowrider challenge invite has expired.");
    }
    LowriderExpireTimer[playerid] = 0;
    return 1;
}

// /lowrider [challenge/accept/cancel] - challenge another driver to a lowrider battle.
CMD:lowrider(playerid, params[]) {
    new option[10], targetid = INVALID_PLAYER_ID;
    if(sscanf(params, "s[10] ", option)){
        return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "/lowrider [challenge, accept, cancel]");
    }

    // new string[128];
    if(!strcmp(option, "challenge", true))
    {
        if(sscanf(params, "s[10] k<player>", option, targetid))
            return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "/lowrider challenge (playerid)");

        if(!IsPlayerConnected(targetid)) {
            return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "The player you challenged is not connected.");
        }

        if(!IsPlayerNearPlayer(playerid, targetid, 15.0))
            return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You must be close to the player to challenge them.");

        // if(playerid == targetid)
        //     return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You cannot challenge yourself.");

        // Are both players available and proper to do the challenge?
        if(IsChallengeValid(playerid, targetid)) 
        {
            KillTimer(LowriderExpireTimer[playerid]);

            PlayerWagerData[playerid][WagerTarget] = targetid;
            PlayerWagerData[targetid][WagerTarget] = playerid;

            // Start the expiration timer
            LowriderExpireTimer[playerid] = SetTimerEx("OnLowriderInviteExpire", LOWRIDER_INVITE_TIMEOUT, false, "ii", playerid, targetid);

            SetPlayerFrontCamera(playerid, 10.0);
            PlayerWagerData[playerid][InWagerMenu] = true;
            PlayerWagerData[playerid][WagerAmount] = WAGER_MIN;

            ShowPlayerInfoMessage(playerid, "~k~~PED_JUMPING~ Increase Wager~n~~k~~PED_FIREWEAPON~ Decrease Wager~n~~k~~PED_SPRINT~ Proceed~n~~k~~VEHICLE_ENTER_EXIT~ Exit", .height=140.0, .width=180, .showtime=6000);
            
            ShowWagerMenu(playerid, WAGER_TYPE_LOWRIDER);
        }
        // No need for an error message here - errors are handled by IsChallengeValid.
    }

    else if(!strcmp(option, "accept", true)) {

        new challenger = Lowrider[playerid][E_LOWRIDER_RIVAL];

        if(challenger != INVALID_PLAYER_ID && IsPlayerConnected(challenger)) {

            if(Lowrider[challenger][E_LOWRIDER_OFFER] && Lowrider[playerid][E_LOWRIDER_OFFER]) {

                new wagerAmount = g_CurrentChallengePot[challenger];

                if(!CanPlayersAffordWager(playerid, challenger, wagerAmount / 2))
                {
                    Lowrider[playerid][E_LOWRIDER_OFFER] = false;
                    Lowrider[challenger][E_LOWRIDER_OFFER] = false;
                    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
                    return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "One of the players cannot afford the wager.");
                }

                KillTimer(LowriderExpireTimer[challenger]);
                LowriderExpireTimer[challenger] = 0;

                TakePlayerCash(playerid, wagerAmount / 2, "Lowrider challenge wager");
                TakePlayerCash(challenger, wagerAmount / 2, "Lowrider challenge wager");

                Lowrider[challenger][E_LOWRIDER_OFFER] = false;
                Lowrider[playerid][E_LOWRIDER_OFFER] = false;

                SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You have accepted the lowrider duel challenge.");
                SendServerMessage(challenger, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "They have accepted the lowrider duel challenge.");

                StartLowriderChallenge(playerid, challenger, g_CurrentChallengePot[playerid]);
            }
            else return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Both you and your rival must have an open offer pending.");
        }
        else return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your rival has either cancelled the offer or has disconnected.");
    }
    
    else if(!strcmp(option, "cancel", true)) {
        if(!Lowrider[playerid][E_LOWRIDER_OFFER])
            return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You do not have any outsstanding challenge offers.");

        new challenger = Lowrider[playerid][E_LOWRIDER_RIVAL];
        if(challenger == INVALID_PLAYER_ID || !IsPlayerConnected(challenger))
        {
            KillTimer(LowriderExpireTimer[playerid]);
            LowriderExpireTimer[playerid] = 0;

            Lowrider[playerid][E_LOWRIDER_OFFER] = false;
            Lowrider[playerid][E_LOWRIDER_ACTIVE] = false;
            Lowrider[playerid][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerAmount] = 0;
            PlayerWagerData[challenger][WagerAmount] = 0;

            SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your rival has disconnected. You have been removed from the challenge.");
            return 1;
        }

        if(Lowrider[playerid][E_LOWRIDER_ACTIVE]) {

            // Resetting player variables
            KillTimer(LowriderExpireTimer[playerid]);
            LowriderExpireTimer[playerid] = 0;

            Lowrider[playerid][E_LOWRIDER_OFFER] = false;
            Lowrider[playerid][E_LOWRIDER_ACTIVE] = false;
            Lowrider[playerid][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[playerid][WagerAmount] = 0;


            SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You have forfeited the lowrider challenge. You lose!");

            // Resetting challenger variables
            Lowrider[challenger][E_LOWRIDER_OFFER] = false;
            Lowrider[challenger][E_LOWRIDER_ACTIVE] = false;
            Lowrider[challenger][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][WagerTarget] = INVALID_PLAYER_ID;
            PlayerWagerData[challenger][WagerAmount] = 0;
            SendServerMessage(challenger, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your rival has forfeited the lowrider challenge. You win!");

            StopLowriderChallenge(playerid, challenger, 1);
            return 1;
        }
        
        else {
            // Cancel outstanding offer.
            if(Lowrider[playerid][E_LOWRIDER_OFFER] && Lowrider[playerid][E_LOWRIDER_RIVAL] == challenger) {
                if(Lowrider[challenger][E_LOWRIDER_OFFER] && Lowrider[challenger][E_LOWRIDER_RIVAL] == playerid) {
                    
                    KillTimer(LowriderExpireTimer[playerid]);
                    LowriderExpireTimer[playerid] = 0;
                    
                    ResetLowriderPlayerState(challenger);
                    ResetLowriderPlayerState(playerid);
                    
                    SendServerMessage(challenger, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your lowrider challenge offer has been refused.");
                    SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You have refused the lowrider challenge offer.");
                    
                    return true;
                }
                else {
                    // Challenger doesn't have a valid outstanding offer, just reset the player and inform them.
                    Lowrider[playerid][E_LOWRIDER_OFFER] = false;
                    Lowrider[playerid][E_LOWRIDER_RIVAL] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][WagerAmount] = 0;
                    PlayerWagerData[playerid][WagerTarget] = INVALID_PLAYER_ID;
                    PlayerWagerData[playerid][InWagerMenu] = false;

                    return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your rival has either cancelled the offer or has disconnected.");
                }
            }
            else return SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You do not have an active offer to cancel.");
        }

    }
    return 1;
}

// Returns true if a lowrider challenge is valid (both drivers in vehicles with hydraulics, close
// enough).
IsChallengeValid(playerid, rival) {
    if(!IsLowriderVehicle(GetPlayerVehicleID(playerid))) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your vehicle is not a lowrider vehicle.");
        return false;
    }
    if(!IsLowriderVehicle(GetPlayerVehicleID(rival))) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Your opponent's vehicle is not a lowrider vehicle.");
        return false;
    }

    // Player checks
    if(Lowrider[playerid][E_LOWRIDER_ACTIVE]) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You're already in an active game. Use {A3A3A3}/lowrider cancel{DEDEDE}.");
        return false;
    }
    if(Lowrider[playerid][E_LOWRIDER_RIVAL] != INVALID_PLAYER_ID) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You already have a rival! Use {A3A3A3}/lowrider cancel{DEDEDE}.");
        return false;
    }
    if(Lowrider[playerid][E_LOWRIDER_OFFER]) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "You already have an offer! Use {A3A3A3}/lowrider accept{DEDEDE} or {A3A3A3}/lowrider cancel{DEDEDE}.");
        return false;
    }

    // Rival checks
    if(Lowrider[rival][E_LOWRIDER_ACTIVE]) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Player is already in an active game.");
        return false;
    }
    if(Lowrider[rival][E_LOWRIDER_RIVAL] != INVALID_PLAYER_ID) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Player already has a rival!");
        return false;
    }
    if(Lowrider[rival][E_LOWRIDER_OFFER]) {
        SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Player already has an offer!");
        return false;
    }
    return true;
}

// Sends a lowrider challenge with the wager pot.
stock SendLowriderChallenge(playerid, challenger, pot)
{
    g_CurrentChallengePot[playerid] = pot;
    g_CurrentChallengePot[challenger] = pot;
    Lowrider[playerid][E_LOWRIDER_OFFER] = true;
    Lowrider[playerid][E_LOWRIDER_RIVAL] = challenger;
    Lowrider[challenger][E_LOWRIDER_OFFER] = true;
    Lowrider[challenger][E_LOWRIDER_RIVAL] = playerid;

    new string[128];
    format(string, sizeof(string), "%s{DEDEDE} has challenged you to lowrider duel with a wager of $%d.", ReturnSettingsName(playerid, challenger, true, true), pot / 2);
    SendServerMessage(challenger, COLOR_LOWRIDER, "Lowrider", "DEDEDE", string);
    SendServerMessage(challenger, COLOR_LOWRIDER, "Lowrider", "DEDEDE", "Use {B780D1}/lowrider accept{DEDEDE} or {B780D1}/lowrider cancel.");
    
    format(string, sizeof(string), "Waiting for response from %s{DEDEDE}. Wager locked at $%d. To cancel type {815396}/lowrider cancel", ReturnSettingsName(challenger, playerid, true, true), pot / 2);
    SendServerMessage(playerid, COLOR_LOWRIDER, "Lowrider", "DEDEDE", string);
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT)
    {
        if(Lowrider[playerid][E_LOWRIDER_ACTIVE])
        {
            StopLowriderChallenge(playerid, Lowrider[playerid][E_LOWRIDER_RIVAL], 0);
        }
    }
}

hook OnPlayerDisconnect(playerid, reason)
{
    KillTimer(LowriderExpireTimer[playerid]);
    LowriderExpireTimer[playerid] = 0;
    return 1;
}
