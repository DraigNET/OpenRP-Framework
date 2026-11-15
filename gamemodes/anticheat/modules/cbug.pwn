// ============================================================================
// File: anticheat/modules/cbug.pwn
// C-bug detection and punishment (crouch-bug abuse in gunfights).
// ============================================================================

#define PRESSED(%0) (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
#define MAX_SLOTS 48

new NotMoving[MAX_PLAYERS];
new WeaponID[MAX_PLAYERS];
new CheckCrouch[MAX_PLAYERS] = {0, ...};
new wAmmo[MAX_PLAYERS][MAX_SLOTS];
new aWeaponNames[][32] = {
	{"Fist"}, // 0
	{"Brass Knuckles"}, // 1
	{"Golf Club"}, // 2
	{"Night Stick"}, // 3
	{"Knife"}, // 4
	{"Baseball Bat"}, // 5
	{"Shovel"}, // 6
	{"Pool Cue"}, // 7
	{"Katana"}, // 8
	{"Chainsaw"}, // 9
	{"Purple Dildo"}, // 10
	{"Vibrator"}, // 11
	{"Vibrator"}, // 12
	{"Vibrator"}, // 13
	{"Flowers"}, // 14
	{"Cane"}, // 15
	{"Grenade"}, // 16
	{"Teargas"}, // 17
	{"Molotov"}, // 18
	{" "}, // 19
	{" "}, // 20
	{" "}, // 21
	{"Colt 45"}, // 22
	{"Silenced Pistol"}, // 23
	{"Deagle"}, // 24
	{"Shotgun"}, // 25
	{"Sawns"}, // 26
	{"Spas"}, // 27
	{"Uzi"}, // 28
	{"MP5"}, // 29
	{"AK47"}, // 30
	{"M4"}, // 31
	{"Tec9"}, // 32
	{"Country Rifle"}, // 33
	{"Sniper Rifle"}, // 34
	{"Rocket Launcher"}, // 35
	{"Heat-Seeking Rocket Launcher"}, // 36
	{"Flamethrower"}, // 37
	{"Minigun"}, // 38
	{"Satchel Charge"}, // 39
	{"Detonator"}, // 40
	{"Spray Can"}, // 41
	{"Fire Extinguisher"}, // 42
	{"Camera"}, // 43
	{"Night Vision Goggles"}, // 44
	{"Infrared Vision Goggles"}, // 45
	{"Parachute"}, // 46
	{"Fake Pistol"} // 47
};

// Detects the shoot-then-crouch sequence used for c-bugging with certain weapons.
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_FIRE) && (oldkeys & KEY_CROUCH) && !((oldkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) || (oldkeys & KEY_FIRE) && (newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ) {
        switch(GetPlayerWeapon(playerid)) {
		    case 24, 25, 27: {
		        if(wAmmo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
					OnPlayerCBug(playerid);
				}
				return 1;
			}
		}
	}

	if(CheckCrouch[playerid] == 1) {
		switch(WeaponID[playerid]) {
		    case 24, 25, 27: {
		    	if((newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK ) {
		    		if(wAmmo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
						OnPlayerCBug(playerid);
					}
		    	}
		    }
		}
	}

	else if(((newkeys & KEY_FIRE) && (newkeys & KEY_HANDBRAKE) && !((newkeys & KEY_SPRINT) || (newkeys & KEY_JUMP))) ||
	(newkeys & KEY_FIRE) && !((newkeys & KEY_SPRINT) || (newkeys & KEY_JUMP)) ||
	(NotMoving[playerid] && (newkeys & KEY_FIRE) && (newkeys & KEY_HANDBRAKE)) ||
	(NotMoving[playerid] && (newkeys & KEY_FIRE)) ||
	(newkeys & KEY_FIRE) && (oldkeys & KEY_CROUCH) && !((oldkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ||
	(oldkeys & KEY_FIRE) && (newkeys & KEY_CROUCH) && !((newkeys & KEY_FIRE) || (newkeys & KEY_HANDBRAKE)) ) {
		SetTimerEx("CrouchCheck", 3000, 0, "d", playerid);
		CheckCrouch[playerid] = 1;
		WeaponID[playerid] = GetPlayerWeapon(playerid);
		wAmmo[playerid][GetPlayerWeapon(playerid)] = GetPlayerAmmo(playerid);
		return 1;
	}
    #if defined cbug_OnPlayerKeyStateChange
        return cbug_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange cbug_OnPlayerKeyStateChange
#if defined cbug_OnPlayerKeyStateChange
	forward cbug_OnPlayerKeyStateChange(playerid, newkeys, oldkeys) ;
#endif


forward OnPlayerCBug(playerid);
// Called when a c-bug is detected: freezes the player briefly and warns staff.
public OnPlayerCBug(playerid) {

	new string[128];
	format(string, sizeof(string), "[!!!] [AdmWarn] %s was frozen for Crouch bugging with weapon (%s!)", ReturnPlayerName(playerid), aWeaponNames[WeaponID[playerid]]);
	SendAdminMessage(string);
	SendClientMessage(playerid, COLOR_RED, "You can't c-bug on this server.");

    TogglePlayerControllable(playerid, false);
    SetTimerEx("Cbug_UnfreezePlayer", 1000, false, "i", playerid);
	
	PlayerPlaySound(playerid,1190,0.0,0.0,0.0);
	CheckCrouch[playerid] = 0;
	return 1;
}

forward Cbug_UnfreezePlayer(playerid);
// Timer: unfreezes a player after the c-bug penalty.
public Cbug_UnfreezePlayer(playerid) {
    TogglePlayerControllable(playerid, true);
    return 1;
}


forward CrouchCheck(playerid);
// Timer: resets the crouch-check window.
public CrouchCheck(playerid) {
	CheckCrouch[playerid] = 0;
	return 1;
}

// Reads the player's keys each tick to track crouching after a shot.
public OnPlayerUpdate(playerid)
{
    new Keys, ud, lr;
	GetPlayerKeys(playerid, Keys, ud, lr);
	if(CheckCrouch[playerid] == 1) {
		switch(WeaponID[playerid]) {
		    case 24, 25, 27: {
		    	if((Keys & KEY_CROUCH) && !((Keys & KEY_FIRE) || (Keys & KEY_HANDBRAKE)) && GetPlayerSpecialAction(playerid) != SPECIAL_ACTION_DUCK ) {
		    		if(wAmmo[playerid][GetPlayerWeapon(playerid)] > GetPlayerAmmo(playerid)) {
						OnPlayerCBug(playerid);
					}
		    	}
		    	//else SendClientMessage(playerid, COLOR_RED, "Failed in onplayer update");
		    }
		}
	}

	if(!ud && !lr) { NotMoving[playerid] = 1; /*OnPlayerKeyStateChange(playerid, Keys, 0);*/ }
	else { NotMoving[playerid] = 0; /*OnPlayerKeyStateChange(playerid, Keys, 0);*/ }

	#if defined cbug_OnPlayerUpdate
		return cbug_OnPlayerUpdate(playerid) ;
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerUpdate
	#undef OnPlayerUpdate
#else
	#define _ALS_OnPlayerUpdate
#endif

#define OnPlayerUpdate cbug_OnPlayerUpdate
#if defined cbug_OnPlayerUpdate
	forward cbug_OnPlayerUpdate(playerid) ;
#endif
