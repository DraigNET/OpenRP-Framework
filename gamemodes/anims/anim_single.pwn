// ============================================================================
// File: anims/anim_single.pwn
// One-off animation commands with no variants (/handsup, /facepalm, /wash, /jump, /getup, /stop
// and many more). ForcedLoopingAnim() is used for looping ones.
// Commands: /flip /facepalm /stop /getup /gkick /handsup /camcrouch /riflehold /carryidle /wash
// /bomb /jump /goggles /throw /swipe /cpr /slapass /taichi /cover /drunk /fucku /skate /plunger
// /slide /driverko /gunhold /cmon /squat /flagdrop /liftdown
// ============================================================================



// /flip - cancels the current animation and flips a coin style gesture (clears animations).
CMD:flip(playerid){
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");


	ClearAnimations(playerid); 
	ApplyAnimation(playerid,"ped", "KD_right", 4.0, 0, 0, 0, 1, 0);

	return true ;
}

// /facepalm - plays the "plyr_shkhead" animation (MISC library).
CMD:facepalm( playerid, cmdtext[] )
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "MISC", "plyr_shkhead", 4.1, 0, 0, 0, 0, 0, 1);

	return 1;
}


CMD:stop ( playerid, params [] ) {

    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "POLICE", "CopTraf_Stop", 4.0, 1, 0, 0, 0, 0, 1);

	return true ;
}


CMD:getup ( playerid, params [] ) {

    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "PED", "getup", 4.1, 0, 0, 0, 0, 0, 1);

	return true ;
}


CMD:gkick ( playerid, params [] ) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "FIGHT_D", "FightD_1", 4.1, 0, 0, 0, 0, 0, 1);

	return true ;
}

// /handsup - raises the player's hands (special action).
CMD:handsup(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_HANDSUP);
	return 1;
}

CMD:camcrouch ( playerid, params [] ) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");


	AnimationLoop(playerid, "CAMERA", "camcrch_idleloop", 4.1, 1, 0, 0, 0, 0, 1);

	return true ;
}

CMD:riflehold ( playerid, params [] ) {

    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "PED", "Gun_2_IDLE", 4.1, 0, 1, 1, 1, 1, 1); 

	return true ;
}


CMD:carryidle ( playerid, params [] ) {

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

 	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY ) ;

	return true ;
}


// /wash - plays the "wash_up" animation (BD_FIRE library).
CMD:wash(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "BD_FIRE", "wash_up", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /bomb - plays the "BOM_Plant" animation (BOMBER library).
CMD:bomb(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /jump - plays the "Crush_Jump" animation (DODGE library).
CMD:jump(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "DODGE", "Crush_Jump", 4.1, 0, 1, 1, 0, 0, 1);
	return 1;
}


// /goggles - plays the "goggles_put_on" animation (goggles library).
CMD:goggles(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "goggles", "goggles_put_on", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /throw - plays the "WEAPON_throw" animation (GRENADE library).
CMD:throw(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "GRENADE", "WEAPON_throw", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}

// /swipe - plays the "Use_SwipeCard" animation (HEIST9 library).
CMD:swipe(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "HEIST9", "Use_SwipeCard", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /cpr - plays the "CPR" animation (MEDIC library).
CMD:cpr(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "MEDIC", "CPR", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /slapass - plays the "sweet_ass_slap" animation (SWEET library).
CMD:slapass( playerid, params [] ) {

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

 	return AnimationLoop(playerid, "SWEET", "sweet_ass_slap", 4.1, 0, 0, 0, 0, 0, 1); // Ass Slapping
}


// /taichi - plays the "Tai_Chi_Loop" animation (PARK library).
CMD:taichi(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "PARK", "Tai_Chi_Loop", 4.1, 1, 0, 0, 0, 0, 1);
	return 1;
}


// /cover - plays the "cower" animation (PED library).
CMD:cover(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "PED", "cower", 4.1, 0, 0, 0, 1, 0, 1);
	return 1;
}

// /drunk - plays the "WALK_drunk" animation (PED library).
CMD:drunk(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "PED", "WALK_drunk", 4.1, 1, 1, 1, 1, 1, 1);
	return 1;
}


// /fucku - plays the "fucku" animation (PED library).
CMD:fucku(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "PED", "fucku", 4.1, 0, 0, 0, 0, 0);
	return 1;
}



// /skate - plays the "skate_idle" animation (SKATE library).
CMD:skate(playerid, params[]) {
	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "SKATE", "skate_idle", 4.1, 1, 0, 0, 0, 0, 1);

	return 1;
}


// /plunger - plays the "PLUNGER_01" animation (MISC library).
CMD:plunger(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "MISC", "PLUNGER_01", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /slide - plays the "THRW_BARL_THRW" animation (AIRPORT library).
CMD:slide(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "AIRPORT", "THRW_BARL_THRW", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}



// /driverko - plays the "STRUGGLE_DRIVER" animation (BIKELEAP library).
CMD:driverko(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "BIKELEAP", "STRUGGLE_DRIVER", 4.1, 1, 0, 0, 0, 0, 1);	
	return 1;
}


// /gunhold - plays the "BUDDY_RELOAD" animation (BUDDY library).
CMD:gunhold(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "BUDDY", "BUDDY_RELOAD", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}

// /cmon - plays the "CAMCRCH_CMON" animation (CAMERA library).
CMD:cmon(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "CAMERA", "CAMCRCH_CMON", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}

// /squat - plays the "CAMCRCH_TO_CAMSTND" animation (CAMERA library).
CMD:squat(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "CAMERA", "CAMCRCH_TO_CAMSTND", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /flagdrop - plays the "FLAG_DROP" animation (CAR library).
CMD:flagdrop(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "CAR", "FLAG_DROP", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /liftdown - plays the "PUTDWN" animation (CARRY library).
CMD:liftdown(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "CARRY", "PUTDWN", 4.1, 0, 0, 0, 0, 0, 1);
	return 1;
}


// /press - plays the "CRIB_USE_SWITCH" animation (CRIB library).
CMD:press(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "CRIB", "CRIB_USE_SWITCH",  4.1, 0, 0, 0, 0, 0, 1);

	return 1;
}


// /handstand - plays the "DAM_DIVE_LOOP" animation (DAM_JUMP library).
CMD:handstand(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "DAM_JUMP", "DAM_DIVE_LOOP",  4.1, 0, 0, 0, 1, 0, 1);

	return 1;
}


// /gethit - plays the "DILDO_HIT_1" animation (DILDO library).
CMD:gethit(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "DILDO", "DILDO_HIT_1",  4.1, 0, 0, 0, 0, 0, 1);

	return 1;
}
// /knifehold - plays the "DILDO_IDLE" animation (DILDO library).
CMD:knifehold(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "DILDO", "DILDO_IDLE",  4.1, 1, 0, 0, 0, 0, 1);

	return 1;
}


// /pointgun - plays the "FATIDLE_ROCKET" animation (FAT library).
CMD:pointgun(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	AnimationLoop(playerid, "FAT", "FATIDLE_ROCKET",  4.1, 1, 0, 0, 0, 0, 1);

	return 1;
}
// /pistolwhip - plays the "FLOWER_ATTACK_M" animation (FLOWERS library).
CMD:pistolwhip(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "FLOWERS", "FLOWER_ATTACK_M",  4.1, 0, 0, 0, 0, 0, 1);

	return 1;
}


// /laugh - plays the "Laugh_01" animation (RAPPING library).
CMD:laugh(playerid, params[]) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnim(playerid, "RAPPING", "Laugh_01", 4.1, false, 0, 0, 0, 0, 1);

	return true ;
}
// /cry - plays the "mrnF_loop" animation (GRAVEYARD library).
CMD:cry(playerid, params[]) {
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnim(playerid,  "GRAVEYARD", "mrnF_loop", 4.1, true, 0, 0, 0, 0, 1);

	return true ;
}


// /angry - plays the "RIOT_ANGRY" animation (RIOT library).
CMD:angry(playerid, params[]){

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnim(playerid, "RIOT", "RIOT_ANGRY", 4.1, true, false, false, false, 0, false); // dj 1

	return true;
}

// /patdown - plays the "plc_drgbst_01" animation (POLICE library).
CMD:patdown(playerid)
{
	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnimation(playerid, "POLICE", "plc_drgbst_01", 4.1, 0, 0, 0, 0, 2000, 1);
	return true;
}


// Plays the same animation several times in a row so it sticks (used by animations that get
// cancelled easily).
static ForcedLoopingAnim(playerid, const animlib[], const animname[], Float:Speed, looping, lockx, locky, lockz, lp)
{
    for (new i = 0; i < 10; i++)
    {
		AnimationLoop(playerid, animlib, animname, Speed, looping, lockx, locky, lockz, lp, 1);
	}
}

// /jogging - makes the character jog using a male or female walking style.
CMD:jogging(playerid)
{
	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (IsPlayerMale(playerid))
	{
		ForcedLoopingAnim(playerid, "PED", "JOG_maleA", 4.0, 1, 1, 1, 1, 100);
	}
	else
	{
		ForcedLoopingAnim(playerid, "PED", "JOG_femaleA", 4.0, 1, 1, 1, 1, 100);
	}

	return true;
}

CMD:jog(playerid) return cmd_jogging(playerid);
