// ============================================================================
// File: anims/anim_choice.pwn
// Animations with several variants chosen by an argument or menu: /dance, /lean, /lay, /fall,
// /ko, /bar, /barber, /workout, /carry, /hurt and others. Based on the LS-RP animation set.
// Commands: /lean /dance /ko /fall /bat /bar /barber /lay /workout /blowjob /carry /hurt
// /injured /crack /sleep /deal /dancing /eat /recruit /gsign /salute /chat /spray /office /kiss
// /knife /cheer /strip /wave /smokeidle
// ============================================================================



// /lean [1-5] - plays one of several lean animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:lean(playerid, params[])
{
	new type;

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/lean [1-5]");

	if (type < 1 || type > 5)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (type == 1) AnimationLoop(playerid, "GANGS", "leanIDLE", 4.0, 1, 0, 0, 0, 0, 1);
	else if (type == 2) AnimationLoop(playerid, "MISC", "Plyrlean_loop", 4.0, 1, 0, 0, 0, 0, 1);
	else if (type == 3) AnimationLoop(playerid, "BAR", "BARman_idle", 4.1, 1, 0, 0, 0, 0, 1);
	else if (type == 4) AnimationLoop(playerid, "SMOKING", "m_smklean_loop", 4.1, 1, 0, 0, 0, 0, 1);
	else if (type == 5) AnimationLoop(playerid, "SMOKING", "f_smklean_loop", 4.1, 1, 0, 0, 0, 0, 1);

	return 1;
}

// /dance [1-14] - plays one of several dance animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:dance(playerid, params[])
{
	new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/dance [1-14]");

	if (type < 1 || type > 14)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE1);
	    case 2: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE2);
	    case 3: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE3);
	    case 4: SetPlayerSpecialAction(playerid, SPECIAL_ACTION_DANCE4);
		case 5: AnimationLoop(playerid, "DANCING", "DAN_Down_A", 4.1, 1, 0, 0, 1, 1, 1); 
		case 6: AnimationLoop(playerid, "DANCING", "DAN_Left_A", 4.1, 1, 0, 0, 1, 1, 1); 
		case 7: AnimationLoop(playerid, "DANCING", "DAN_Loop_A", 4.1, 1, 0, 0, 1, 1, 1); 
		case 8: AnimationLoop(playerid, "DANCING", "DAN_Right_A", 4.1, 1, 0, 0, 1, 1, 1); 
		case 9: AnimationLoop(playerid, "DANCING", "DAN_Up_A", 4.1, 1, 0, 0, 1, 1, 1); 
		case 10: AnimationLoop(playerid, "DANCING", "dnce_M_a", 4.1, 1, 0, 0, 1, 1, 1); 
		case 11: AnimationLoop(playerid, "DANCING", "dnce_M_b", 4.1, 1, 0, 0, 1, 1, 1); 
		case 12: AnimationLoop(playerid, "DANCING", "dnce_M_c", 4.1, 1, 0, 0, 1, 1, 1); 
		case 13: AnimationLoop(playerid, "DANCING", "dnce_M_d", 4.1, 1, 0, 0, 1, 1, 1); 
		case 14: AnimationLoop(playerid, "DANCING", "dnce_M_e", 4.1, 1, 0, 0, 1, 1, 1); 
	}
	return 1;
}


CMD:ko ( playerid, params [] ) {

    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new animstate ;

	if ( sscanf ( params, "i", animstate )) {

		return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/ko [1-2]") ;
	}

	if ( animstate < 1 || animstate > 2 ) {

		return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/ko [1-2]") ;
	}

	if ( animstate == 1 ) {

		return AnimationLoop(playerid,"PED","KO_SHOT_STOM", 4.1, 0, 1, 1, 1, 1, 1); 
	}

	else if ( animstate == 2 ) {

		return AnimationLoop(playerid,"PED","KO_SHOT_FACE",4.1, 0, 1, 1, 1, 1, 1); 
	}

	return true ;
}

// /fall [1-2] - plays one of several fall animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:fall(playerid, params [] ) 
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/fall [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	if (type == 1) AnimationLoop(playerid, "PED", "FLOOR_hit_f", 4.1, 0, 1, 1, 1, 0, 1); 
	else if (type == 2) AnimationLoop(playerid, "PED", "FLOOR_hit", 4.1, 0, 1, 1, 1, 0, 1); 

	return true;
}

// /bat [1-8] - plays one of several bat animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:bat(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/bat [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "BASEBALL", "Bat_1", 4.1, 0, 1, 1, 0, 0, 1);
	    case 2: ApplyAnimation(playerid, "BASEBALL", "Bat_2", 4.1, 0, 1, 1, 0, 0, 1);
	    case 3: ApplyAnimation(playerid, "BASEBALL", "Bat_3", 4.1, 0, 1, 1, 0, 0, 1);
	    case 4: ApplyAnimation(playerid, "BASEBALL", "Bat_4", 4.1, 0, 0, 0, 0, 0, 1);
	    case 5: AnimationLoop(playerid, "BASEBALL", "Bat_IDLE", 4.1, 1, 0, 0, 0, 0, 1);
	    case 6: AnimationLoop(playerid, "BASEBALL", "BAT_BLOCK", 4.1, 1, 0, 0, 0, 0, 1);
	    case 7: ApplyAnimation(playerid, "BASEBALL", "BAT_HIT_1", 4.1, 0, 0, 0, 0, 0, 1);
	    case 8: ApplyAnimation(playerid, "BASEBALL", "BAT_M", 4.1, 0, 0, 0, 0, 0, 1);


	}
	return 1;
}

// /bar [1-8] - plays one of several bar animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:bar(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/bar [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "BAR", "Barserve_bottle", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: ApplyAnimation(playerid, "BAR", "Barserve_give", 4.1, 0, 0, 0, 0, 0, 1);
	    case 3: ApplyAnimation(playerid, "BAR", "Barserve_glass", 4.1, 0, 0, 0, 0, 0, 1);
	    case 4: ApplyAnimation(playerid, "BAR", "Barserve_in", 4.1, 0, 0, 0, 0, 0, 1);
	    case 5: ApplyAnimation(playerid, "BAR", "Barserve_order", 4.1, 0, 0, 0, 0, 0, 1);
	    case 6: AnimationLoop(playerid, "BAR", "BARman_idle", 4.1, 1, 0, 0, 0, 0, 1);
	    case 7: AnimationLoop(playerid, "BAR", "dnk_stndM_loop", 4.1, 0, 0, 0, 0, 0, 1);
	    case 8: AnimationLoop(playerid, "BAR", "dnk_stndF_loop", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /barber [1-13] - plays one of several barber animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:barber(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/barber [1-13]");

	if (type < 1 || type > 14)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) 
	{
	    case 1: ApplyAnimation(playerid, "haircuts", "brb_beard_01", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "haircuts", "brb_buy", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "haircuts", "brb_cut", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: ApplyAnimation(playerid, "haircuts", "brb_cut_in", 4.1, 0, 0, 0, 1, 0, 1); 
		case 5: ApplyAnimation(playerid, "haircuts", "brb_cut_out", 4.1, 0, 0, 0, 1, 0, 1); 
		case 6: ApplyAnimation(playerid, "haircuts", "brb_hair_01", 4.1, 0, 0, 0, 1, 0, 1);
		case 7: ApplyAnimation(playerid, "haircuts", "brb_hair_02", 4.1, 0, 0, 0, 1, 0, 1);
		case 8: ApplyAnimation(playerid, "haircuts", "brb_in", 4.1, 0, 0, 0, 1, 0, 1); 
		case 9: ApplyAnimation(playerid, "haircuts", "brb_loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 10: ApplyAnimation(playerid, "haircuts", "brb_out", 4.1, 0, 0, 0, 1, 0, 1); 
		case 11: ApplyAnimation(playerid, "haircuts", "brb_sit_in", 4.1, 0, 0, 0, 1, 0, 1); 
		case 12: ApplyAnimation(playerid, "haircuts", "brb_sit_loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 13: ApplyAnimation(playerid, "haircuts", "brb_sit_out", 4.1, 0, 0, 0, 1, 0, 1); 
	}
	return 1;
}

// /lay [1-5] - plays one of several lay animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:lay(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/lay [1-5]");

	if (type < 1 || type > 5)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "BEACH", "bather", 4.1, 1, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "BEACH", "Lay_Bac_Loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "BEACH", "ParkSit_M_loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "BEACH", "ParkSit_W_loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 5: AnimationLoop(playerid, "BEACH", "SitnWait_loop_W", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /workout [1-7] - plays one of several workout animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:workout(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/workout [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "benchpress", "gym_bp_celebrate", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "benchpress", "gym_bp_down", 4.1, 0, 0, 0, 1, 0, 1);
	    case 3: ApplyAnimation(playerid, "benchpress", "gym_bp_getoff", 4.1, 0, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "benchpress", "gym_bp_geton", 4.1, 0, 0, 0, 1, 0, 1);
	    case 5: AnimationLoop(playerid, "benchpress", "gym_bp_up_A", 4.1, 0, 0, 0, 1, 0, 1);
	    case 6: AnimationLoop(playerid, "benchpress", "gym_bp_up_B", 4.1, 0, 0, 0, 1, 0, 1);
	    case 7: AnimationLoop(playerid, "benchpress", "gym_bp_up_smooth", 4.1, 0, 0, 0, 1, 0, 1);
	}
	return 1;
}

// /blowjob [1-4] - plays one of several blowjob animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:blowjob(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/blowjob [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "BLOWJOBZ", "BJ_COUCH_LOOP_W", 4.1, 1, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "BLOWJOBZ", "BJ_COUCH_LOOP_P", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "BLOWJOBZ", "BJ_STAND_LOOP_W", 4.1, 1, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "BLOWJOBZ", "BJ_STAND_LOOP_P", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /carry [1-6] - plays one of several carry animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:carry(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/carry [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: ApplyAnimation(playerid, "CARRY", "liftup05", 4.1, 0, 0, 0, 0, 0, 1);
	    case 3: ApplyAnimation(playerid, "CARRY", "liftup105", 4.1, 0, 0, 0, 0, 0, 1);
	    case 4: ApplyAnimation(playerid, "CARRY", "putdwn", 4.1, 0, 0, 0, 0, 0, 1);
	    case 5: ApplyAnimation(playerid, "CARRY", "putdwn05", 4.1, 0, 0, 0, 0, 0, 1);
	    case 6: ApplyAnimation(playerid, "CARRY", "putdwn105", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /hurt [1-5] - plays one of several hurt animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:hurt(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/hurt [1-5]");

	if (type < 1 || type > 5)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) 
	{
	    case 1: AnimationLoop(playerid, "SWEET", "Sweet_injuredloop", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "SWAT", "gnstwall_injurd", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "CRACK", "CRCKIDLE1", 4.1, 1, 0, 0, 1, 0, 1);
		case 4: AnimationLoop(playerid, "CRACK", "CRCKIDLE3", 4.1, 1, 0, 0, 1, 0, 1);
		case 5: AnimationLoop(playerid, "heist9", "cas_g2_gasko", 4.1, 0, 0, 0, 1, 0, 1);
	}

	return 1;
}

CMD:injured(playerid, params[])
{
	return cmd_hurt(playerid, params);
}

// /crack [1-6] - plays one of several crack animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:crack(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/crack [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "CRACK", "crckdeth1", 4.1, 0, 0, 0, 1, 0, 1);
	    case 2: AnimationLoop(playerid, "CRACK", "crckdeth2", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "CRACK", "crckdeth3", 4.1, 0, 0, 0, 1, 0, 1);
	    case 4: AnimationLoop(playerid, "CRACK", "crckidle1", 4.1, 0, 0, 0, 1, 0, 1);
	    case 5: AnimationLoop(playerid, "CRACK", "crckidle2", 4.1, 0, 0, 0, 1, 0, 1);
	    case 6: AnimationLoop(playerid, "CRACK", "crckidle3", 4.1, 0, 0, 0, 1, 0, 1);
	}
	return 1;
}

// /sleep [1-2] - plays one of several sleep animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:sleep(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/sleep [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "CRACK", "crckdeth4", 4.1, 0, 0, 0, 1, 0, 1);
	    case 2: AnimationLoop(playerid, "CRACK", "crckidle4", 4.1, 0, 0, 0, 1, 0, 1);
	}
	return 1;
}


// /deal [1-6] - plays one of several deal animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:deal(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/deal [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "DEALER", "DEALER_DEAL", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: ApplyAnimation(playerid, "DEALER", "DRUGS_BUY", 4.1, 0, 0, 0, 0, 0, 1);
	    case 3: ApplyAnimation(playerid, "DEALER", "shop_pay", 4.1, 0, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "DEALER", "DEALER_IDLE_01", 4.1, 1, 0, 0, 0, 0, 1);
	    case 5: AnimationLoop(playerid, "DEALER", "DEALER_IDLE_02", 4.1, 1, 0, 0, 0, 0, 1);
	    case 6: AnimationLoop(playerid, "DEALER", "DEALER_IDLE_03", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /dancing [1-10] - plays one of several dancing animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:dancing(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/dancing [1-10]");

	if (type < 1 || type > 10)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "DANCING", "dance_loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "DANCING", "DAN_Left_A", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "DANCING", "DAN_Right_A", 4.1, 1, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "DANCING", "DAN_Loop_A", 4.1, 1, 0, 0, 0, 0, 1);
	    case 5: AnimationLoop(playerid, "DANCING", "DAN_Up_A", 4.1, 1, 0, 0, 0, 0, 1);
	    case 6: AnimationLoop(playerid, "DANCING", "DAN_Down_A", 4.1, 1, 0, 0, 0, 0, 1);
	    case 7: AnimationLoop(playerid, "DANCING", "dnce_M_a", 4.1, 1, 0, 0, 0, 0, 1);
	    case 8: AnimationLoop(playerid, "DANCING", "dnce_M_e", 4.1, 1, 0, 0, 0, 0, 1);
	    case 9: AnimationLoop(playerid, "DANCING", "dnce_M_b", 4.1, 1, 0, 0, 0, 0, 1);
	    case 10: AnimationLoop(playerid, "DANCING", "dnce_M_c", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /eat [1-3] - plays one of several eat animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:eat(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/eat [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnim(playerid, "FOOD", "EAT_Burger", 4.1, true, 0, 0, 1, 1, 1);
	    case 2: ApplyAnim(playerid, "FOOD", "EAT_Chicken", 4.1, true, 0, 0, 1, 1, 1);
	    case 3: ApplyAnim(playerid, "FOOD", "EAT_Pizza", 4.1, true, 0, 0, 1, 1, 1);
	}
	return 1;
}

// /recruit [1-2] - plays one of several recruit animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:recruit(playerid, params[]) {
	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/recruit [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GANGS", "Invite_No", 	 4.1, true, 0, 0, 1, 1);
		case 2: ApplyAnim(playerid, "GANGS", "Invite_Yes",  4.1, true, 0, 0, 1, 1);
	}
	return 1;
}

// /gsign [1-9] - plays one of several gsign animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:gsign(playerid, params[])
{ 
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/gsign [1-9]");

	if (type < 1 || type > 9)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GHANDS", "gsign1", 	 4.1, true, 0, 0, 1, 1);
		case 2: ApplyAnim(playerid, "GHANDS", "gsign1LH", 	 4.1, true, 0, 0, 1, 1);
		case 3: ApplyAnim(playerid, "GHANDS", "gsign2", 	 4.1, true, 0, 0, 1, 1);
		case 4: ApplyAnim(playerid, "GHANDS", "gsign2LH", 	 4.1, true, 0, 0, 1, 1);
		case 5: ApplyAnim(playerid, "GHANDS", "gsign3",		 4.1, true, 0, 0, 1, 1);
		case 6: ApplyAnim(playerid, "GHANDS", "gsign3LH", 	 4.1, true, 0, 0, 1, 1);
		case 7: ApplyAnim(playerid, "GHANDS", "gsign4", 	 4.1, true, 0, 0, 1, 1);
		case 8: ApplyAnim(playerid, "GHANDS", "gsign4LH", 	 4.1, true, 0, 0, 1, 1);
		case 9: ApplyAnim(playerid, "GHANDS", "gsign5", 	 4.1, true, 0, 0, 1, 1);
	}
	return 1;
}

// /salute - plays the salute animation.
CMD:salute(playerid, params[])
{
	if (!AnimationCheck(playerid))
	    return SendServerMessage(playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	ApplyAnim(playerid, "GHANDS", "gsign5LH", 4.1, true, 0, 0, 1, 1);
	return 1;
}

// /chat [1-6] - plays one of several chat animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:chat(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/chat [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkA", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkB", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkE", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkF", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkG", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: ApplyAnimation(playerid, "GANGS", "prtial_gngtlkH", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}


// /spray [1-2] - plays one of several spray animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:spray(playerid, params[])
{
	new type;

    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/spray [1-2]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "SPRAYCAN", "spraycan_fire", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "SPRAYCAN", "spraycan_full", 4.1, 0, 0, 0, 0, 0, 1);
	}
 	
	return 1;
}


// /office [1-6] - plays one of several office animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:office(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/office [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Bored_Loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Crash", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Drink", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Read", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Type_Loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid, "INT_OFFICE", "OFF_Sit_Watch", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /kiss [1-6] - plays one of several kiss animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:kiss(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/kiss [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "KISSING", "Grlfrd_Kiss_01", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "KISSING", "Grlfrd_Kiss_02", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "KISSING", "Grlfrd_Kiss_03", 4.1, 0, 0, 0, 0, 0, 1);
		case 4: ApplyAnimation(playerid, "KISSING", "Playa_Kiss_01", 4.1, 0, 0, 0, 0, 0, 1);
		case 5: ApplyAnimation(playerid, "KISSING", "Playa_Kiss_02", 4.1, 0, 0, 0, 0, 0, 1);
		case 6: ApplyAnimation(playerid, "KISSING", "Playa_Kiss_03", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /knife [1-8] - plays one of several knife animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:knife(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/knife [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "KNIFE", "knife_1", 4.1, 0, 1, 1, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "KNIFE", "knife_2", 4.1, 0, 1, 1, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "KNIFE", "knife_3", 4.1, 0, 1, 1, 0, 0, 1);
		case 4: ApplyAnim(playerid, "KNIFE", "knife_4", 4.1, true, 0, 0, 1, 1, 1);
		case 5: AnimationLoop(playerid, "KNIFE", "WEAPON_knifeidle", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Player", 4.1, 0, 0, 0, 0, 0, 1);
		case 7: ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Damage", 4.1, 0, 0, 0, 0, 0, 1);
		case 8: ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Die", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /cheer [1-8] - plays one of several cheer animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:cheer(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/cheer [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "ON_LOOKERS", "shout_01", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "ON_LOOKERS", "shout_02", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "ON_LOOKERS", "shout_in", 4.1, 0, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "RIOT", "RIOT_ANGRY_B", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: ApplyAnimation(playerid, "RIOT", "RIOT_CHANT", 4.1, 0, 0, 0, 0, 0, 1);
		case 6: ApplyAnimation(playerid, "RIOT", "RIOT_shout", 4.1, 0, 0, 0, 0, 0, 1);
		case 7: ApplyAnimation(playerid, "STRIP", "PUN_HOLLER", 4.1, 0, 0, 0, 0, 0, 1);
		case 8: ApplyAnimation(playerid, "OTB", "wtchrace_win", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /strip [1-7] - plays one of several strip animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:strip(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/strip [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "STRIP", "strip_A", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "STRIP", "strip_B", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "STRIP", "strip_C", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "STRIP", "strip_D", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid, "STRIP", "strip_E", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid, "STRIP", "strip_F", 4.1, 1, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid, "STRIP", "strip_G", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}


// /wave [1-3] - plays one of several wave animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:wave(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/wave [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: ApplyAnimation(playerid, "PED", "endchat_03", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: ApplyAnimation(playerid, "KISSING", "gfwave2", 4.1, 0, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "ON_LOOKERS", "wave_loop", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /smokeidle [0-3] - plays one of several smokeidle animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:smokeidle(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/smokeidle [0-3]");

	if (type < 0 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 0: ApplyAnimation(playerid, "SHOP", "Smoke_RYD", 4.1, 0, 0, 0, 0, 0, 1);
	    case 1: ApplyAnimation(playerid, "SMOKING", "M_smk_drag", 4.1, 0, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "SMOKING", "M_smklean_loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "SMOKING", "M_smkstnd_loop", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /reloadanim [1-4] - plays one of several reloadanim animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:reloadanim(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/reloadanim [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "BUDDY", "buddy_reload", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "UZI", "UZI_reload", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "COLT45", "colt45_reload", 4.1, 0, 0, 0, 0, 0, 1);
		case 4: ApplyAnimation(playerid, "RIFLE", "rifle_load", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}


// /wank [1-3] - plays one of several wank animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:wank(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/wank [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "PAULNMAC", "wank_loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "PAULNMAC", "wank_in", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "PAULNMAC", "wank_out", 4.1, 0, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /tired [1-2] - plays one of several tired animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:tired(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/tired [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "PED", "IDLE_tired", 4.1, 1, 0, 0, 0, 0, 1);
	    case 2: AnimationLoop(playerid, "FAT", "IDLE_tired", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /sit [1-7] - plays one of several sit animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:sit(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/sit [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CRIB", "PED_Console_Loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "INT_HOUSE", "LOU_In", 4.1, 0, 0, 0, 1, 0, 1);
		case 3: AnimationLoop(playerid, "MISC", "SEAT_LR", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "MISC", "Seat_talk_01", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid, "MISC", "Seat_talk_02", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid, "ped", "SEAT_down", 4.1, 0, 0, 0, 1, 0, 1);
		case 7: AnimationLoop(playerid, "jst_buisness", "girl_02", 4.1, 0, 0, 0, 1, 0, 1);
	}
	return 1;
}

// /crossarms [1-4] - plays one of several crossarms animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:crossarms(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/crossarms [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "COP_AMBIENT", "Coplook_loop", 4.1, 0, 1, 1, 1, 0, 1);
	    case 2: AnimationLoop(playerid, "GRAVEYARD", "prst_loopa", 4.1, 1, 0, 0, 0, 0, 1);
	    case 3: AnimationLoop(playerid, "GRAVEYARD", "mrnM_loop", 4.1, 1, 0, 0, 0, 0, 1);
	    case 4: AnimationLoop(playerid, "DEALER", "DEALER_IDLE", 4.1, 0, 1, 1, 1, 0, 1);
	}
	return 1;
}


// /walk [1-16] - plays one of several walk animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:walk(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/walk [1-16]");

	if (type < 1 || type > 17)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "FAT", "FatWalk", 4.1, 1, 1, 1, 1, 1, 1);
	    case 2: AnimationLoop(playerid, "MUSCULAR", "MuscleWalk", 4.1, 1, 1, 1, 1, 1, 1);
	    case 3: AnimationLoop(playerid, "PED", "WALK_armed", 4.1, 1, 1, 1, 1, 1, 1);
	    case 4: AnimationLoop(playerid, "PED", "WALK_civi", 4.1, 1, 1, 1, 1, 1, 1);
	    case 5: AnimationLoop(playerid, "PED", "WALK_fat", 4.1, 1, 1, 1, 1, 1, 1);
	    case 6: AnimationLoop(playerid, "PED", "WALK_fatold", 4.1, 1, 1, 1, 1, 1, 1);
	    case 7: AnimationLoop(playerid, "PED", "WALK_gang1", 4.1, 1, 1, 1, 1, 1, 1);
	    case 8: AnimationLoop(playerid, "PED", "WALK_gang2", 4.1, 1, 1, 1, 1, 1, 1);
	    case 9: AnimationLoop(playerid, "PED", "WALK_player", 4.1, 1, 1, 1, 1, 1, 1);
	    case 10: AnimationLoop(playerid, "PED", "WALK_old", 4.1, 1, 1, 1, 1, 1, 1);
	    case 11: AnimationLoop(playerid, "PED", "WALK_wuzi", 4.1, 1, 1, 1, 1, 1, 1);
	    case 12: AnimationLoop(playerid, "PED", "WOMAN_walkbusy", 4.1, 1, 1, 1, 1, 1, 1);
	    case 13: AnimationLoop(playerid, "PED", "WOMAN_walkfatold", 4.1, 1, 1, 1, 1, 1, 1);
	    case 14: AnimationLoop(playerid, "PED", "WOMAN_walknorm", 4.1, 1, 1, 1, 1, 1, 1);
	    case 15: AnimationLoop(playerid, "PED", "WOMAN_walksexy", 4.1, 1, 1, 1, 1, 1, 1);
	    case 16: AnimationLoop(playerid, "PED", "WOMAN_walkshop", 4.1, 1, 1, 1, 1, 1, 1);
	}
	return 1;
}

// /point [1-4] - plays one of several point animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:point(playerid, params[])
{
    new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/point [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
	    case 1: AnimationLoop(playerid, "PED", "ARRESTgun", 4.1, 0, 0, 0, 1, 0, 1);
	    case 2: AnimationLoop(playerid, "SHOP", "ROB_Loop_Threat", 4.1, 1, 0, 0, 0, 0, 1);
    	case 3: AnimationLoop(playerid, "ON_LOOKERS", "point_loop", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "ON_LOOKERS", "Pointup_loop", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}


// /hitchhike [left/right] - plays one of several hitchhike animations (pick the number). Blocked
// when animations are not allowed (AnimationCheck).
CMD:hitchhike(playerid, params[]){
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");


	// Straight from LS-RP (but better)!
	if(! strcmp(params, "left", true)) {

		ApplyAnimation(playerid,"MISC", "Hiker_Pose_L", 4.0, 1, 0, 0, 0, 0); // hitch hike
	}	
	else if(! strcmp(params, "right", true)) {

		ApplyAnimation(playerid,"MISC", "Hiker_Pose", 4.0, 1, 0, 0, 0, 0); // hitch hike
	}
	else return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/hitchhike [left/right]");
	
	return true ;
}

// /drink [1-2] - plays one of several drink animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:drink(playerid, params[]) {

	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/drink [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GANGS", "drnkbr_prtl", 4.1, true, 0, 0, 1, 1, 1);
		case 2: ApplyAnim(playerid, "GANGS", "drnkbr_prtl_F", 4.1, true, 0, 0, 1, 1, 1);
	}

	return true ;
}

// /ganghands [1-7] - plays one of several ganghands animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:ganghands(playerid, params[])
{
	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/ganghands [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKB", 4.1, true, 0, 0, 1, 1);
		case 2: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKC", 4.1, true, 0, 0, 1, 1);
		case 3: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKD", 4.1, true, 0, 0, 1, 1);
		case 4: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKE", 4.1, true, 0, 0, 1, 1);
		case 5: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKF", 4.1, true, 0, 0, 1, 1);
		case 6: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKG", 4.1, true, 0, 0, 1, 1);
		case 7: ApplyAnim(playerid, "LOWRIDER", "PRTIAL_GNGTLKH", 4.1, true, 0, 0, 1, 1);
	}
	return 1;
}

// /playidle [1-3] - plays one of several playidle animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:playidle(playerid, params[])
{
	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/playidle [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "PLAYIDLES", "SHIFT", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "PLAYIDLES", "SHLDR", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "PLAYIDLES", "STRETCH", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}


// /carlook [1-8] - plays one of several carlook animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:carlook(playerid, params[])
{
	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/carlook [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC1_BL", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC1_BR", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC1_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC1_FR", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC2_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC3_BR", 4.1, 1, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC3_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 8: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC3_FR", 4.1, 1, 0, 0, 0, 0, 1);
	}
	return 1;
}

// /caranim [relax/tap] - plays one of several caranim animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:caranim( playerid, cmdtext[] ) {

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if(isnull(cmdtext)) {
		return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/caranim [relax/tap]");
	}
	
	if(!strcmp(cmdtext, "relax", true, strlen(cmdtext))) {
		AnimationLoop(playerid, "CAR", "sit_relaxed", 4.1, 1, 0, 0, 0, 0, 1);
	}
	else if(!strcmp(cmdtext, "tap", true, strlen(cmdtext))) {	
		AnimationLoop(playerid, "CAR", "Tap_hand", 4.1, 1, 0, 0, 0, 0, 1);	
	}
	else{
		return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/caranim [relax/tap]");
	}

	return 1;
}

// /balcony [1-3] - plays one of several balcony animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:balcony(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/balcony [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "BD_FIRE", "BD_PANIC_02", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "BD_FIRE", "BD_PANIC_03", 4.1, 0, 0, 0, 0, 0, 1);
		case 3:  ApplyAnimation(playerid, "FOOD", "SHP_THANK", 4.1, 0, 0, 0, 0, 0, 1);
	}

	return 1;
}


// /bikepunch [1-2] - plays one of several bikepunch animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:bikepunch(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/bikepunch [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "BIKES", "BIKES_SNATCH_L", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "BIKES", "BIKES_SNATCH_R", 4.1, 0, 0, 0, 0, 0, 1);
	}

	return 1;
}



// /look [1-2] - plays one of several look animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:look(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/look [1-2]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "CAMERA", "CAMSTND_LKABT", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "ON_LOOKERS", "LKAROUND_LOOP", 4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}


// /undercar [1-3] - plays one of several undercar animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:undercar(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/undercar [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CAR", "FIXN_CAR_LOOP", 4.1, 1, 0, 0, 0, 0, 1);	
		case 2: ApplyAnimation(playerid, "CAR", "FIXN_CAR_OUT", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid, "BENCHPRESS", "GYM_BP_GETON", 4.1, 0, 0, 0, 1, 0, 1);	
	}

	return 1;
}

// /liftup [1-3] - plays one of several liftup animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:liftup(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/liftup [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "FOOD", "SHP_TRAY_LIFT", 4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "CARRY", "LIFTUP", 4.1, 0, 0, 0, 0, 0, 1);
		case 3: ApplyAnimation(playerid, "BOX", "CATCH_BOX", 4.1, 0, 0, 0, 0, 0, 1);
	}

	return 1;
}

// /carphone [1-3] - plays one of several carphone animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:carphone(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/carphone [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CAR_CHAT", "CARFONE_IN",  4.1, 0, 0, 0, 0, 1, 1);
		case 2: AnimationLoop(playerid,"CAR_CHAT", "CARFONE_LOOPA",  4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,"CAR_CHAT", "CARFONE_LOOPA_TO_B", 4.1, 0, 0, 0, 1, 0, 1);
	}

	return 1;
}


// /carfuss [1-10] - plays one of several carfuss animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:carfuss(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/carfuss [1-10]");

	if (type < 1 || type > 10)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CAR_CHAT", "CAR_SC1_BL", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC1_BR", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC1_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC1_FR", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC2_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC3_BR", 4.1, 1, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC3_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 8: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC4_BR", 4.1, 1, 0, 0, 0, 0, 1);
		case 9: AnimationLoop(playerid,	"CAR_CHAT", "CAR_SC4_FL", 4.1, 1, 0, 0, 0, 0, 1);
		case 10: AnimationLoop(playerid,"CAR_CHAT", "CAR_SC4_FR", 4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}


// /cartalk [1-3] - plays one of several cartalk animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:cartalk(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/cartalk [1-3]");

	if (type < 1 || type > 3)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CAR_CHAT", "CAR_TALKM_IN", 4.1, 0, 0, 0, 1, 0, 1);
		case 2: AnimationLoop(playerid,	"CAR_CHAT", "CAR_TALKM_LOOP", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	"CAR_CHAT", "CAR_TALKM_OUT", 4.1, 0, 0, 0, 1, 0, 1);
	}

	return 1;
}
// /casino [1-5] - plays one of several casino animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:casino(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/casino [1-5]");

	if (type < 1 || type > 5)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CASINO", "CARDS_LOOP", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid,	"CASINO", "ROULETTE_BET", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	"CASINO", "ROULETTE_LOSE", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid,	"CASINO", "SLOT_PLYR", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid,	"CASINO", "SLOT_WIN_OUT", 4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}

// /clothes [1-6] - plays one of several clothes animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:clothes(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/clothes [1-6]");

	if (type < 1 || type > 6)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "CLOTHES", "CLO_BUY", 4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid,	"CLOTHES", "CLO_POSE_LEGS", 4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	"CLOTHES", "CLO_POSE_LOOP",  4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid,	"CLOTHES", "CLO_POSE_SHOES", 4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid,	"CLOTHES", "CLO_POSE_WATCH", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid,	"CLOTHES", "CLO_POSE_TORSO", 4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}

// /copambient [1-7] - plays one of several copambient animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:copambient(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/copambient [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid,  "COP_AMBIENT", "COPBROWSE_LOOP",	4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid,	 "COP_AMBIENT", "COPBROWSE_NOD", 	4.1, 1, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	 "COP_AMBIENT", "COPBROWSE_SHAKE",	4.1, 1, 0, 0, 0, 0, 1);
		case 4: AnimationLoop(playerid,	 "COP_AMBIENT", "COPLOOK_LOOP", 	4.1, 1, 0, 0, 0, 0, 1);
		case 5: AnimationLoop(playerid,	 "COP_AMBIENT", "COPLOOK_SHAKE", 	4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid,	 "COP_AMBIENT", "COPLOOK_THINK", 	4.1, 1, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid,	 "COP_AMBIENT", "COPLOOK_WATCH", 	4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}


// NEW 04/04/20

// /batidle [1-2] - plays one of several batidle animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:batidle(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/batidle [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid,  "CRACK", "BBALBAT_IDLE_01",	4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid,	 "CRACK", "BBALBAT_IDLE_02", 	4.1, 1, 0, 0, 0, 0, 1);
	}

	return 1;
}



// /guardstance [1-2] - plays one of several guardstance animations (pick the number). Blocked
// when animations are not allowed (AnimationCheck).
CMD:guardstance(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/guardstance [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: AnimationLoop(playerid, "FIGHT_B", "FIGHTB_IDLE",  4.1, 1, 0, 0, 0, 0, 1);
		case 2: AnimationLoop(playerid, "FIGHT_D", "FIGHTD_IDLE",  4.1, 1, 0, 0, 0, 0, 1);
	}
	
	return 1;
}

// /fight [1-7] - plays one of several fight animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:fight(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/fight [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "FIGHT_B", "HITB_1",	4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "FIGHT_B", "HITB_2", 	4.1, 0, 0, 0, 0, 0, 1);
		case 3: AnimationLoop(playerid,	 "FIGHT_C", "FIGHTC_G", 4.1, 1, 0, 0, 0, 0, 1);
		case 4: ApplyAnimation(playerid, "FIGHT_D", "FIGHTD_1", 4.1, 0, 0, 0, 0, 0, 1);
		case 5: ApplyAnimation(playerid, "FIGHT_D", "FIGHTD_2", 4.1, 0, 0, 0, 0, 0, 1);
		case 6: ApplyAnimation(playerid, "FIGHT_D", "FIGHTD_3", 4.1, 0, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid, "FIGHT_D", "FIGHTD_G", 4.1, true, 0, 0, 0, 0, 1);
	}

	return 1;
}

// /switchseat [1-2] - plays one of several switchseat animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:switchseat(playerid, params[])
{
    if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/switchseat [1-2]");

	if (type < 1 || type > 2)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnimation(playerid, "FINALE2", "FIN_SWITCH_P",  4.1, 0, 0, 0, 0, 0, 1);
		case 2: ApplyAnimation(playerid, "FINALE2", "FIN_SWITCH_S",  4.1, 0, 0, 0, 0, 0, 1);
	}
	
	return 1;
}


// /bop [1-4] - plays one of several bop animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:bop(playerid, params[]) {

	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/bop [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GYMNASIUM", "GYM_TREAD_CELEBRATE", 	4.1, true, 0, 0, 1, 1, 1);
		case 2: ApplyAnim(playerid, "LOWRIDER", "RAP_A_LOOP",	4.1, true, 0, 0, 1, 1, 1);
		case 3: ApplyAnim(playerid, "LOWRIDER", "RAP_B_LOOP", 4.1, true, 0, 0, 1, 1, 1);
		case 4: ApplyAnim(playerid, "LOWRIDER", "RAP_C_LOOP",	4.1, true, 0, 0, 1, 1, 1);
	}

	return true ;
}

// /lowrideranim [1-15] - plays one of several lowrideranim animations (pick the number). Blocked
// when animations are not allowed (AnimationCheck).
CMD:lowrideranim(playerid, params[]) {
	new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/lowrideranim [1-15]");

	if (type < 1 || type > 15)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_BDBNCE",	4.1, true, 0, 0, 1, 1, 1);
		case 2: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_HAIR",	4.1, true, 0, 0, 1, 1, 1);
		case 3: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_HURRY",	4.1, true, 0, 0, 1, 1, 1);
		case 4: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_IDLELOOP",	4.1, true, 0, 0, 1, 1, 1);
		case 5: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_IDLE_TO_L0",	4.1, true, 0, 0, 1, 1, 1);
		case 6: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L0_BNCE",	4.1, true, 0, 0, 1, 1, 1);
		case 7: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L0_TO_L1",	4.1, true, 0, 0, 1, 1, 1);
		case 8: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L12_TO_L0",	4.1, true, 0, 0, 1, 1, 1);
		case 9: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L1_TO_L2",	4.1, true, 0, 0, 1, 1, 1);
		case 10: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L2_BNCE",	4.1, true, 0, 0, 1, 1, 1);
		case 11: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L2_TO_L3",	4.1, true, 0, 0, 1, 1, 1);
		case 12: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L3_BNCE",	4.1, true, 0, 0, 1, 1, 1);
		case 13: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L3_LOOP",	4.1, true, 0, 0, 1, 1, 1);
		case 14: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L4_BNCE",	4.1, true, 0, 0, 1, 1, 1);
		case 15: ApplyAnim(playerid, "LOWRIDER", "LRGIRL_L4_LOOP",	4.1, true, 0, 0, 1, 1, 1);
	}

	return true ;
}

// /gfunk [1-4] - plays one of several gfunk animations (pick the number). Blocked when animations
// are not allowed (AnimationCheck).
CMD:gfunk(playerid, params[]) {

	new type;

	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/gfunk [1-4]");

	if (type < 1 || type > 4)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GFUNK", "DANCE_G3", 4.1, true, false, false, false, 0, false); // gfunk 1
		case 2: ApplyAnim(playerid, "GFUNK", "DANCE_G4", 4.1, true, false, false, false, 0, false); // gfunk 2
		case 3: ApplyAnim(playerid, "GFUNK", "DANCE_G7", 4.1, false, false, false, false, 0, false); // gfunk 3
		case 4: ApplyAnim(playerid, "GFUNK", "DANCE_G7", 4.1, true, false, false, false, 0, false); // gfunk 4
	}

	return true ;
}


// /dj [1-8] - plays one of several dj animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:dj(playerid, params[]) {

	new type;

	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/dj [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type) {
		case 1: ApplyAnim(playerid, "GFUNK", "DANCE_G10", 4.1, true, false, false, false, 0, false); // dj 1
		case 2: ApplyAnim(playerid, "GFUNK", "DANCE_G11", 4.1, true, false, false, false, 0, false); // dj 2
		case 3: ApplyAnim(playerid, "GFUNK", "DANCE_G12", 4.1, true, false, false, false, 0, false); // dj 3
		case 4: ApplyAnim(playerid, "GFUNK", "DANCE_G13", 4.1, true, false, false, false, 0, false); // dj 4
		case 5: AnimationLoop(playerid, "SCRATCHING", "scdldlp", 4.1, 1, 0, 0, 0, 0, 1);
		case 6: AnimationLoop(playerid, "SCRATCHING", "scdlulp", 4.1, 1, 0, 0, 0, 0, 1);
		case 7: AnimationLoop(playerid, "SCRATCHING", "scdrdlp", 4.1, 1, 0, 0, 0, 0, 1);
		case 8: AnimationLoop(playerid, "SCRATCHING", "scdrulp", 4.1, 1, 0, 0, 0, 0, 1);
	}

	return true ;
}


// NEW by Sporks

// /aim [1-7] - plays one of several aim animations (pick the number). Blocked when animations are
// not allowed (AnimationCheck).
CMD:aim(playerid, params[])
{
    if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/aim [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type)
	{
		case 1: AnimationLoop(playerid, "SHOP", "ROB_Loop_Threat", 4.0, 1, 0, 0, 0, 0);
		case 2: AnimationLoop(playerid, "PED", "gang_gunstand", 4.0, 1, 0, 0, 0, 0);
		case 3: AnimationLoop(playerid, "SHOP", "SHP_GUN_AIM", 4.1, 0, 1, 1, 1, 1000);
		case 4: AnimationLoop(playerid, "SHOP", "SHP_DUCK_FIRE", 4.1, 0, 1, 1, 1, 1000);
		case 5: AnimationLoop(playerid, "PED", "gun_stand", 4.1, 1, 0, 0, 0, 0);
		case 6: AnimationLoop(playerid, "POLICE", "COP_getoutcar_lhs", 4.1, 0, 1, 1, 1, 1000);
		case 7: AnimationLoop(playerid, "POOL", "POOL_IDLE_STANCE", 4.1, 1, 0, 0, 0, 0);
	}

	return true;
}

CMD:aimgun(playerid, params[]) return cmd_aim(playerid, params);


// /foodsit [1-8] - plays one of several foodsit animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:foodsit(playerid, params[])
{
	if (!AnimationCheck(playerid))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/foodsit [1-8]");

	if (type < 1 || type > 8)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type)
	{
		case 1: AnimationLoop(playerid,"FOOD", "FF_Sit_Eat1", 4.1, 1, 0, 0, 0, 0);
		case 2: AnimationLoop(playerid,"FOOD", "FF_Sit_Eat2", 4.1, 1, 0, 0, 0, 0);
		case 3: AnimationLoop(playerid,"FOOD", "FF_Sit_Eat3", 4.1, 1, 0, 0, 0, 0);
		case 4: AnimationLoop(playerid,"FOOD", "FF_Sit_In", 4.1, 0, 0, 0, 1, 0);
		case 5: AnimationLoop(playerid,"FOOD", "FF_Sit_In_L", 4.1, 0, 0, 0, 1, 0);
		case 6: AnimationLoop(playerid,"FOOD", "FF_Sit_In_R", 4.1, 0, 0, 0, 1, 0);
		case 7: AnimationLoop(playerid,"FOOD", "FF_Sit_Look", 4.1, 1, 0, 0, 0, 0);
		case 8: AnimationLoop(playerid,"FOOD", "FF_Sit_Loop", 4.1, 1, 0, 0, 0, 0);
	}

	return true;
}

CMD:siteat(playerid, params[]) return cmd_foodsit(playerid, params);
CMD:sitfood(playerid, params[]) return cmd_foodsit(playerid, params);

// /swatraid [1-7] - plays one of several swatraid animations (pick the number). Blocked when
// animations are not allowed (AnimationCheck).
CMD:swatraid(playerid, params[])
{
	if (!AnimationCheck(playerid, true)) // don't allow while cuffed
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "You can't perform animations at the moment.");

	new type ;
	if (sscanf(params, "d", type))
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "/swatraid [1-7]");

	if (type < 1 || type > 7)
	    return SendServerMessage( playerid, COLOR_RED, "Animation", "DEDEDE", "Invalid type specified.");

	switch (type)
	{
		case 1: ApplyAnim(playerid,"SWAT","swt_breach_01",4.0,0,1, 1, 1, 4000);
		case 2: ApplyAnim(playerid,"SWAT","swt_breach_02",4.0,0,1, 1, 1, 4000);
		case 3: ApplyAnim(playerid,"SWAT","swt_breach_03",4.0,0,1, 1, 1, 4000);
		case 4: ApplyAnim(playerid,"SWAT","swt_wllshoot_in_L",4.0,0,1, 1, 1, 1000);
		case 5: ApplyAnim(playerid,"SWAT","swt_wllshoot_out_L",4.0,0,1, 1, 1, 1000);
		case 6: ApplyAnim(playerid,"SWAT","swt_wllshoot_in_R",4.0,0,1, 1, 1, 1000);
		case 7: ApplyAnim(playerid,"SWAT","swt_wllshoot_out_R",4.0,0,1, 1, 1, 1000);
	}

	return true;
}
