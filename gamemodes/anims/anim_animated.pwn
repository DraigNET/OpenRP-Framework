// ============================================================================
// File: anims/anim_animated.pwn
// Animations that also attach a prop or have a timed effect: /smoke, /exhale, /piss, /puke,
// /shakebottle, /time (check watch).
// Commands: /time /piss /puke /shakebottle /exhale /smoke
// ============================================================================


#define SMOKE_OBJECT_ID 18677
#define E_ATTACH_INDEX_SYSTEM 5

CMD:time ( playerid, params [] ) {
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "PLAYIDLES", "time", 4.1, 0, 0, 0, 0, 0, 1);

	/*new string [ 128 ] ;
	format ( string, sizeof ( string ), "[Watch]: {DEDEDE}The time is %.0d:%02d on %s %d, 2005.",
		Server [ E_SERVER_TIME_HOURS ], Server [ E_SERVER_TIME_MINUTES ], 
		date_getMonth(Server [ E_SERVER_TIME_MONTHS ]), Server [ E_SERVER_TIME_DAYS ]
	);

	SendClientMessage ( playerid, COLOR_HINT, string ) ;*/

	return true ;
}


/*CMD:shit ( playerid, params [] ) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "PED", "cower", 4.1, 0, 0, 0, 1, 0, 1);
    SetPlayerAttachedObject ( playerid, 9, 18722,1, -1.773999, 0.234999,-0.091000, 2.300002, 88.499984, 0.0, 1.0, 1.0, 1.0 ) ;
    
    return true ;
}*/

// /piss - plays the urinate special action.
CMD:piss(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	SetPlayerSpecialAction(playerid, 68);
	return 1;
}

// /puke - plays a vomiting animation followed by a vomit particle effect.
CMD:puke(playerid, params[]) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "FOOD", "EAT_Vomit_P", 4.1, 0, 0, 0, 1, 0, 1);
	defer AnimatedAnim_Puke(playerid);

	return true ;
}

// Timer: attaches the vomit effect once the puke animation reaches the right frame.
timer AnimatedAnim_Puke[3750](playerid) {

	if ( GetPlayerAnimationIndex(playerid) == 539 ) {
    	SetPlayerAttachedObject ( playerid, E_ATTACH_INDEX_MISC, 18722,E_ATTACH_BONE_HEAD, 0.0, 1.75, 0.0, 90.0, 0.0, 0.0,  1.000000, 1.000000, 1.000000 ) ;
    	defer AnimatedAnim_Clear(playerid);
    }	

    return true ;
}

new PlayerBottleAnimation [ MAX_PLAYERS ] ;
// /shakebottle - shakes a champagne bottle (attached prop with an animation).
CMD:shakebottle(playerid, params[]) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	SetPlayerAttachedObject ( playerid, E_ATTACH_INDEX_MISC, 19820,E_ATTACH_BONE_HAND_R, 0.051001, 0.037000, -0.000999, -3.499976, 63.500053, -3.400005, 1.000000, 1.000000, 1.258999 ) ;
	SetPlayerAttachedObject ( playerid, E_ATTACH_INDEX_SYSTEM, 18706,E_ATTACH_BONE_HAND_R, -1.334998, -0.005000, -0.679999, -3.499975, 63.500053, -3.400005, 1.000000, 1.000000, 1.258998 ) ;

   	ApplyAnimation(playerid, "BUDDY", "buddy_reload", 4.1, 0, 0, 0, 1, 0, 1);


   	PlayerBottleAnimation [ playerid ] = 0 ;
   	defer AnimatedAnim_Bottle[1500](playerid);
   	return true ;
}

// Timer: runs the bottle-shaking animation and removes the prop when it ends.
timer AnimatedAnim_Bottle[800](playerid) {

   	switch ( GetPlayerAnimationIndex(playerid) ) {

   		case 224: {
			if ( PlayerBottleAnimation [ playerid ] ++ >= 60 ) {

				RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_MISC);
				RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
				return true ;
			}
		}

		default: {
			RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_MISC);
			RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);

			return true ;
		}
	}
 
	defer AnimatedAnim_Bottle(playerid);

	return true ;
}

// /exhale - blows out smoke while smoking.
CMD:exhale(playerid, params[])
{
    if (!AnimationCheck(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

    IsSmoking[playerid] = true;

    defer AnimatedAnim_Exhale_Loop[3500](playerid);

    return true;
}

// /smoke [1-4] - starts smoking a cigarette with a held prop; there are four styles.
CMD:smoke(playerid, params[])
{
    new type;

    if (!AnimationCheck(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

    if (sscanf(params, "d", type))
        return SendServerMessage(playerid, COLOR_RED, "Animation", "DEDEDE", "/smoke [1-4]");

    if (type < 1 || type > 4)
        return SendServerMessage(playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

    IsSmoking[playerid] = true;

    switch (type) {
		case 1: ApplyAnim(playerid, "GANGS", "smkcig_prtl", 	4.1, true, 0, 0, 1, 1, 1);
		case 2: ApplyAnim(playerid, "GANGS", "smkcig_prtl_F", 	4.1, true, 0, 0, 1, 1, 1);
		case 3: ApplyAnim(playerid, "PED", "pass_Smoke_in_car", 4.1, true, 0, 0, 1, 1, 1);
		case 4: ApplyAnim(playerid, "PED", "smoke_in_car", 		4.1, true, 0, 0, 1, 1, 1);
	}

    defer AnimatedAnim_Exhale_Loop[3500](playerid);

    return true;
}

// Timer: loops the smoke effect while the player is smoking.
timer AnimatedAnim_Exhale_Loop[3500](playerid)
{
    if (!IsPlayerConnected(playerid) || !IsSmoking[playerid])
        return 0;

    SetPlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM, SMOKE_OBJECT_ID, E_ATTACH_BONE_HEAD,
        0.0, 1.75, 0.0, 90.0, 0.0, 0.0, 1.0, 1.0, 1.0);

    defer AnimatedAnim_Clear[3000](playerid);
    defer AnimatedAnim_Exhale_Loop[7000](playerid);

    return true;
}

// Timer: removes the temporary prop once an animation has finished.
timer AnimatedAnim_Clear[3000](playerid)
{
    if (IsPlayerConnected(playerid))
        RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
    return true;
}
