// ============================================================================
// File: anims/stopanim.pwn
// /stopanim (/sa) clears the player's current animation, and AnimationCheck() decides whether a
// player is allowed to start one (not cuffed, injured, in a vehicle...).
// Commands: /sa /stopanim
// ============================================================================


new bool:IsSmoking[MAX_PLAYERS];

CMD:sa(playerid, params[]) {

	return cmd_stopanim(playerid, params);
}
 
CMD:stopanim ( playerid, const params [] ) {

	if ( IsPlayerIncapacitated ( playerid, true ) ) {

	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You don't need to use this command right now." );
	}

	if ( gettime () < PlayerVar [ playerid ] [ E_PLAYER_BRAWL_STOPANIM_ABUSE ] ) {
		SendAdminMessage(sprintf("[!!!] [AdmWarn] %d %s has abused /s(top)a(nim) within 10 seconds of being damaged (anim abuse).",
			playerid, ReturnRPName(playerid) )) ;

	    return SendServerMessage( playerid, COLOR_RED, "Anticheat", "DEDEDE", "Don't abuse /s(top)a(nim) in fights." );
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_PIZZAJOB_HOLDING ] ) {

		return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't stop your animation while carrying a pizza." );
	}

	PlayerVar [ playerid ] [ E_PLAYER_LOOPING_ANIM ] = 0;

	IsSmoking[playerid] = false;

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE ) ;

	if (IsPlayerInAnyVehicle(playerid))
	{
		return ApplyAnimation(playerid, "PED", "CAR_SIT", 4.0, 0, 0, 0, 0, 1, 1);
	}
	else  
	{
		ClearAnimations(playerid, 1);
		ApplyAnimation(playerid, "PED", "IDLE_STANCE", 4.0, 0, 0, 0, 0, 1, 1);
		ApplyAnimation(playerid, "PED", "IDLE_CHAT", 4.0, 0, 0, 0, 0, 1, 1);
		ApplyAnimation(playerid, "PED", "WALK_PLAYER", 4.0, 0, 0, 0, 0, 1, 1);
	}

	if (GetPVarInt(playerid, "CUFFED") == 1)
	{
		// re-cuff anyone that was cuffed
		ORP_SetPlayerCuffed(playerid, true, false);
		// Police_OnPlayerCuffResponse(playerid, true);
	}

/*
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE ) ;
	ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.0, 0, 0, 0, 0, 0); // Leave animation
	ClearAnimations(playerid);
*/

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, "Used /stopanim");

	return true ;
}

// Returns true if the player is allowed to start an animation right now (not knocked out, brawl
// abuse, cuffed when checkCuffs is true...).
stock AnimationCheck(playerid, bool:checkCuffs=false)
{
    if (PlayerVar[playerid][E_PLAYER_BRAWL_STOPANIM_ABUSE])
    {
        if (gettime() < (PlayerVar[playerid][E_PLAYER_BRAWL_STOPANIM_ABUSE] - 5))
        {
            return false;
        }
    }

    if (PlayerVar[playerid][E_PLAYER_KNOCKED_OUT])
    {
        return false;
    }

    if (IsPlayerIncapacitated(playerid, !checkCuffs))
    {
        return false;
    }

    return true;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
	IsSmoking[playerid] = false;
	return 1;
}
#include <YSI_Coding\y_hooks>
hook OnPlayerDisconnect(playerid, reason) {
	IsSmoking[playerid] = false;
	return 1;
}
