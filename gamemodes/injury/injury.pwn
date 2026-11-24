// ============================================================================
// File: injury/injury.pwn
// What happens when a player is injured or dies: injury animations, the option to /acceptdeath,
// the respawn location list, hospital billing and weapon confiscation.
// Commands: /acceptdeath
// ============================================================================


// Timer: applies the bike-fall animation if the player was thrown from a motorcycle.
timer Injury_ApplyBikeAnimation[750](playerid, vehicleid) {
// This re-appends the bike falloff animation.

	new Float:vx, Float:vy, Float:vz;
	GetVehicleVelocity(vehicleid, vx, vy, vz);

	JT_RemovePlayerFromVehicle(playerid);

	if (vx*vx + vy*vy + vz*vz >= 0.4) {
		Injury_ApplyAnim(playerid, "PED", "BIKE_fallR", 0);
	} else {
		Injury_ApplyAnim(playerid, "PED", "BIKE_fall_off", 0);
	}

	return true ;
}

// Timer: plays the death animation after the player has been ejected from a vehicle.
timer Injury_AppendAnimAfterEject[750](playerid) {

	//ApplyAnimation(playerid,"PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0);
	ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);

	return true ;
}
 
// /acceptdeath - lets an injured player give up and respawn.
CMD:acceptdeath(playerid) {
	if ( ! PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {

		SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", "You're not in injury mode and can't do this command." ) ;
		return true ;
	}

	if (!PlayerVar [ playerid ] [ E_PLAYER_EXECUTE_MSG ])
	{
		if (PlayerVar [ playerid ] [ E_PLAYER_INJURY_MIN_TICK ] > 0)
		{
			SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", sprintf("You must wait %d seconds before doing this.", PlayerVar [ playerid ] [ E_PLAYER_INJURY_MIN_TICK ]) ) ;
			return true;
		}

		if (PlayerVar [ playerid ] [ E_PLAYER_INJURY_TICK ] > 0)
		{
			new Float:x, Float:y, Float:z;
			GetPlayerPos(playerid, x, y, z);

			foreach ( new i : Player ) 
			{
				if (i == playerid) continue;
				if (IsPlayerInRangeOfPoint(i, 7.5, x, y, z) && IsPlayerInAnyGovFaction(i, true))
				{
					SendServerMessage( playerid, COLOR_RED, "Injury", "A3A3A3",  "You can't do this while the emergency services are beside you." );
					return SendServerMessage( playerid, COLOR_RED, "Injury", "A3A3A3",  sprintf("Note that you will be automatically respawned in %d seconds if they do not revive you.", PlayerVar [ playerid ] [ E_PLAYER_INJURY_TICK ]) );
				}
			}
		}
	}
	
	Injury_OnPlayerDeath(playerid) ;
	return true ;
}

// Timer: counts down the injury time each second and shows the bleed-out bubble.
timer Injury_TickCountdown[1000](playerid) {
	if ( ! PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {

		SetPlayerChatBubble(playerid," ", 0xFFFFFFFF, 7.5, 10000);
		return false ;
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_INJURY_MIN_TICK ] > 0 ) 
	{
		// Allow player to accept death
		if ( -- PlayerVar [ playerid ] [ E_PLAYER_INJURY_MIN_TICK ] == 0)
		{
			if (IsPlayerInMetroTraining(playerid) || IsPlayerInSEBTraining(playerid))
			{
				SendClientMessage( playerid, COLOR_RED, "You can now type {AA3333}/acceptdeath{ff6347} to respawn back at the facility entrance.");
			}
			else
			{
				SendClientMessage( playerid, COLOR_RED, "You can now type {AA3333}/acceptdeath{ff6347} to respawn if nobody is interacting with you.");
				SendServerMessage( playerid, COLOR_INJURY, "Injury", "A3A3A3", "If you respawn, you will not remember what happened or anyone involved.");
			}
		}
	}

	if ( -- PlayerVar [ playerid ] [ E_PLAYER_INJURY_TICK ] <= 0 ) {

		// Kill player
		
		SetPlayerChatBubble(playerid, "(( THIS PLAYER IS DEAD ))", COLOR_YELLOW, 7.5, 900000);
		ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);
		Weapon_ResetPlayerWeapons(playerid);

		/*
		SendClientMessage(playerid, COLOR_YELLOW, "You are now dead. To continue, use /acceptdeath. You will not remember anything that happened");
		SendClientMessage(playerid, COLOR_YELLOW, "leading up to the event of your death. You may not take revenge against those who killed you.");
		*/

		PlayerVar [ playerid ] [ E_PLAYER_INJURY_MIN_TICK ] = 0;

		SendClientMessage(playerid, COLOR_RED, "You passed out and have been transported to recover in hospital.");
		SendServerMessage(playerid, COLOR_INJURY_LIGHT, "Injury", "A3A3A3", "The hospital staff will confiscate any weapons and bill you for the care you receive.");
		SendServerMessage(playerid, COLOR_INJURY_LIGHT, "Injury", "A3A3A3", "You can no longer be revived and will not remember what happened or anyone inolved.");
		cmd_acceptdeath(playerid);

		//ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);
	
		return true ;
		//CancelBloodPuddle ( playerid ) ;
	}	

	else {

		/*GameTextForPlayer(playerid, sprintf("~w~~n~~n~~n~~n~~n~~n~Injured: ~r~%d", 
			PlayerVar [ playerid ] [ E_PLAYER_INJURY_TICK ]), 950, 3 ) ;*/

		if (strlen(PlayerVar [ playerid ] [ E_PLAYER_INJURY_REASON ]) > 1)
		{
			SetPlayerChatBubble(playerid, sprintf("(( This player has been injured by %s [ /damages %d ] ))", PlayerVar [ playerid ] [ E_PLAYER_INJURY_REASON ], playerid), COLOR_INJURY, 7.5, 1500);
		}
		else
		{
			SetPlayerChatBubble(playerid, sprintf("(( This player is injured [ /damages %d ] ))", playerid), COLOR_INJURY, 7.5, 1500);
		}
		

		defer Injury_TickCountdown(playerid);
	}

	return true ;
}

// Timer: finishes the respawn after accepting death.
timer Injury_FinalizeRespawn[7500](playerid) {


	PlayerVar [ playerid ] [ E_PLAYER_EXECUTE_MSG ] = false ;

	SetCameraBehindPlayer(playerid);
	TogglePlayerControllable(playerid, true);

	if (PlayerVar [ playerid ] [ E_PLAYER_IS_MASKED ])
	{
		PlayerVar [ playerid ] [ E_PLAYER_IS_MASKED ] = false;
		ToggleMask(playerid, false);
	}

	SetPlayerChatBubble(playerid, " ", -1, 7.5, 1000);

	if ( Character [ playerid ] [ E_CHARACTER_ARREST_TIME ] ) {

		SetCameraBehindPlayer(playerid);

		// New: preload the arrest position with streamer_update
		SetPlayerVirtualWorld ( playerid, Character [ playerid ] [ E_CHARACTER_ARREST_VW ] );
		SetPlayerInterior(playerid, Character [ playerid ] [ E_CHARACTER_ARREST_INT ] );
		//Streamer_UpdateEx(playerid, Character [ playerid ] [ E_CHARACTER_ARREST_X ], Character [ playerid ] [ E_CHARACTER_ARREST_Y ], Character [ playerid ] [ E_CHARACTER_ARREST_Z ], Character [ playerid ] [ E_CHARACTER_ARREST_VW ], Character [ playerid ] [ E_CHARACTER_ARREST_INT ], STREAMER_TYPE_OBJECT, 1000, 1);
		
		ORP_SetPlayerPos ( playerid, Character [ playerid ] [ E_CHARACTER_ARREST_X ], Character [ playerid ] [ E_CHARACTER_ARREST_Y ], Character [ playerid ] [ E_CHARACTER_ARREST_Z ] );
		SetPlayerHealth(playerid, Character [ playerid ] [ E_CHARACTER_HEALTH ] ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Arrest", "A3A3A3", "You've been teleported back to your cell." ) ;
		Weapon_ResetPlayerWeapons(playerid);
		SendClientMessage(playerid, 0xA3A3A3FF, "Your weapons have been confiscated.");
		Weapon_SavePlayerWeapons(playerid);
	}

	
	if(Character[playerid][E_CHARACTER_AJAIL_TIME] > 0) {
		
		SetCameraBehindPlayer(playerid);
		SetPlayerIntoAdminJail(playerid);
		SetPlayerHealth(playerid, Character [ playerid ] [ E_CHARACTER_HEALTH ] ) ;

		SendClientMessage(playerid, 0xA3A3A3FF, "You were teleported back to admin jail.");
		Weapon_ResetPlayerWeapons(playerid);
		SendClientMessage(playerid, 0xA3A3A3FF, "Your weapons have been confiscated.");
		Weapon_SavePlayerWeapons(playerid);
		return true;
	}

	return true ;
}
// Called when a player's injury ends in death: confiscates weapons, bills them and moves them to
// a hospital.
Injury_OnPlayerDeath(playerid) 
{
	if (IsPlayerInMetroTraining(playerid))
	{
		PauseAC(playerid, 3);
		SetPlayerPos(playerid, 1932.4357,-2301.5842,13.6028);
		SetPlayerVirtualWorld(playerid, 6003);
		SetPlayerInterior(playerid, 7);
		SetCharacterHealth(playerid, 100.0);
		TogglePlayerControllable(playerid, true);
		SetCameraBehindPlayer(playerid);
		Injury_RemoveData(playerid) ;
		Injury_FinalizeRespawn(playerid);

		SendClientMessage(playerid, 0xA3A3A3FF, "You were respawned back at the training center.");
		return true;
	}

	if (IsPlayerInSEBTraining(playerid))
	{
		PauseAC(playerid, 3);
		SetPlayerPos(playerid, 1932.4357,-2301.5842,13.6028);
		SetPlayerVirtualWorld(playerid, 6004);
		SetPlayerInterior(playerid, 7);
		SetCharacterHealth(playerid, 100.0);
		TogglePlayerControllable(playerid, true);
		SetCameraBehindPlayer(playerid);
		Injury_RemoveData(playerid) ;
		Injury_FinalizeRespawn(playerid);

		SendClientMessage(playerid, 0xA3A3A3FF, "You were respawned back at the training center.");
		return true;
	}

	// Leave a corpse where they died - must happen before the hospital teleport
	// below moves them. Training deaths (above) intentionally leave no corpse.
	Corpse_Spawn(playerid);

    // A disabled hospital leaves the player at their existing valid position.
    // Configure a recovery point in the ACP before opening the server to players.
    if (RuntimeLocations[RT_LOC_HOSPITAL][RLOC_ENABLED]) {
        PauseAC(playerid,3);
        SetPlayerInterior(playerid,RuntimeLocations[RT_LOC_HOSPITAL][RLOC_INTERIOR]);
        SetPlayerVirtualWorld(playerid,RuntimeLocations[RT_LOC_HOSPITAL][RLOC_WORLD]);
        SetPlayerPos(playerid,RuntimeLocations[RT_LOC_HOSPITAL][RLOC_X],RuntimeLocations[RT_LOC_HOSPITAL][RLOC_Y],RuntimeLocations[RT_LOC_HOSPITAL][RLOC_Z]);
        SetPlayerFacingAngle(playerid,RuntimeLocations[RT_LOC_HOSPITAL][RLOC_ANGLE]);
    }
    SetCameraBehindPlayer(playerid);

	TogglePlayerControllable(playerid, false);
	SetCharacterHealth(playerid, 75.0);

	SetPlayerChatBubble(playerid,"(( This player recently died and respawned ))", COLOR_BLUE, 7.5, 10000);

	defer Injury_FinalizeRespawn[7500](playerid) ;

	/* FUCK YOU FUCK YOU FUCK YOU FUCK YOU
	// Restore spraycan / camera
	if(DoesPlayerHaveWeapon(playerid, WEAPON_CAMERA)) {
		SetPlayerArmedWeapon(playerid, WEAPON_CAMERA);
		InjuryRestoreCamera[playerid] = GetPlayerAmmo(playerid);
	}

	if(DoesPlayerHaveWeapon(playerid, WEAPON_SPRAYCAN)) {
		SetPlayerArmedWeapon(playerid, WEAPON_SPRAYCAN);
		InjuryRestoreSpraycan[playerid] = GetPlayerAmmo(playerid);
	}*/

	// If a player dies due to an explosion, don't confiscate their shit.
	if( ! PlayerVar [ playerid ] [ E_PLAYER_ONPLAYERDEATH ] ) {

		// Now clear it.
		Weapon_ResetPlayerWeapons(playerid);
		SendClientMessage(playerid, 0xA3A3A3FF, "Your weapons have been confiscated by the hospital staff.");
		Weapon_SavePlayerWeapons(playerid);

		// Also bill them for the fine american healthcare they receive - max once every 30 mins
		if (!PlayerVar[playerid][E_PLAYER_LAST_HOSPITAL_BILL_AT] || gettime() - PlayerVar[playerid][E_PLAYER_LAST_HOSPITAL_BILL_AT] > 1800)
		{
			new worth = Character[playerid][E_CHARACTER_BANKCASH] + Character[playerid][E_CHARACTER_CASH];
            // Use floating-point multiplication to avoid truncating low balances.
            new cost=clamp(floatround(float(worth)*Runtime_Float(RT_MEDICAL_BILL_PERCENT)/100.0),Runtime_Int(RT_MEDICAL_BILL_MIN),Runtime_Int(RT_MEDICAL_BILL_MAX));

			if (IsPlayerInAnyGovFaction(playerid))
			{
				SendClientMessage(playerid, 0xA3A3A3FF, sprintf("Your hospital bill of $%s was paid by your government health insurance.", IntegerWithDelimiter(cost)));
			}
			else if (worth < Runtime_Int(RT_MEDICAL_BILL_MIN))
			{
				SendClientMessage(playerid, 0xA3A3A3FF, sprintf("Your hospital bill of $%s was paid by the government as you couldn't afford it.", IntegerWithDelimiter(cost)));
			}
			else
			{
				TakePlayerCash(playerid, cost, "Hospital bill");
				PlayerVar[playerid][E_PLAYER_LAST_HOSPITAL_BILL_AT] = gettime();
				SendClientMessage(playerid, 0xA3A3A3FF, sprintf("You were billed $%s by the hospital for your medical care.", IntegerWithDelimiter(cost)));
			}
		}
	}

	// They died clientwise - let's refund their shit.
	else {

		new idx  ;

		for ( new i, j = MAX_WEAPON_SLOTS; i < j ; i ++ ) {
			idx = PlayerVar [ playerid ] [ E_PLAYER_WEAPON_EQUIPPED ][ i ] ;

			if ( idx != -1 || idx != 0 ) {

				GivePlayerWeapon(playerid, Weapon [ idx ] [ E_WEAPON_GUNID ], PlayerVar [ playerid ] [ E_PLAYER_AMMO_TEMP ] [ i ] ) ;
				ORP_SetPlayerAmmo(playerid, Weapon [ idx ] [ E_WEAPON_GUNID ], PlayerVar [ playerid ] [ E_PLAYER_AMMO_TEMP ] [ i ] ) ; // hard setting ammo
			}

			PlayerVar [ playerid ] [ E_PLAYER_AMMO_TEMP ] [ i ] = 0 ;
		}
	}

	Injury_RemoveData(playerid) ;
	
	// Lvl 15+ gets to choose their spawn location after death
	if (Character[playerid][E_CHARACTER_LEVEL] >= 15 && !Character[playerid][E_CHARACTER_ARREST_TIME] && !Character[playerid][E_CHARACTER_AJAIL_TIME])
	{
		SendClientMessage(playerid, COLOR_INJURY_LIGHT, "As a level 15+ player, you may choose where to respawn.");
		Player_DisplayDeathSpawnList(playerid);
	}
	else
	{
		SetPlayerCameraPos(playerid, 1264.9146, 366.0338, 42.6425);
		SetPlayerCameraLookAt(playerid, 1264.5085, 365.1031, 42.2775);

		PauseAC(playerid, 3);
		SetPlayerPos(playerid, 1244.3533, 332.2185, 19.5547) ;
		SetPlayerFacingAngle(playerid, 334.9928);

		SetPlayerVirtualWorld(playerid, 0);
		SetPlayerInterior(playerid, 0);

		TogglePlayerControllable(playerid, false);
		SetCharacterHealth(playerid, 75.0);

		SetPlayerChatBubble(playerid,"(( This player recently died and respawned ))", COLOR_BLUE, 7.5, 10000);
		defer Injury_FinalizeRespawn[7500](playerid);
	}

	return true;
}

// Shows the list of places a dead player can respawn.
Player_DisplayDeathSpawnList(playerid)
{
	inline DeathSpawnPick(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, listitem, inputtext

		if (!response)
		{
			SetPlayerCameraPos(pid, 2001.6575, -1451.1865, 28.0661);
			SetPlayerCameraLookAt(pid, 2002.2876, -1450.4061, 27.8411);

			PauseAC(pid, 3);
			SetPlayerPos(pid, 2009.9967, -1437.8395, 13.5547);
			SetPlayerFacingAngle(pid, 131.1139);

			SetPlayerVirtualWorld(pid, 0);
			SetPlayerInterior(pid, 0);

			TogglePlayerControllable(pid, false);
			SetCharacterHealth(pid, 75.0);

			SetPlayerChatBubble(pid, "(( This player recently died and respawned ))", COLOR_BLUE, 7.5, 10000);
			defer Injury_FinalizeRespawn[7500](pid);
			return true;
		}

		if (listitem == 0)
		{
			SetPlayerCameraPos(pid, 2001.6575, -1451.1865, 28.0661);
			SetPlayerCameraLookAt(pid, 2002.2876, -1450.4061, 27.8411);

			PauseAC(pid, 3);
			SetPlayerPos(pid, 2009.9967, -1437.8395, 13.5547);
			SetPlayerFacingAngle(pid, 131.1139);

			SetPlayerVirtualWorld(pid, 0);
			SetPlayerInterior(pid, 0);

			TogglePlayerControllable(pid, false);
			SetCharacterHealth(pid, 75.0);

			SetPlayerChatBubble(pid, "(( This player recently died and respawned ))", COLOR_BLUE, 7.5, 10000);
			defer Injury_FinalizeRespawn[7500](pid);
		}
		else
		{
			PlayerSpawnOptions[pid][0] = PLAYER_SPAWN_TYPE_PROPERTY;
			PlayerSpawnSelection(pid, listitem - 1, true);
		}

		return true;
	}

	new dlgstr[512];
	format(dlgstr, sizeof(dlgstr), "Type\tOption\n");
	strcat(dlgstr, "{EF9A9A}Hospital\tRespawn at the hospital\n");

	new properties = GetPlayerPropertyCount(playerid);
	if (properties)
	{
		strcat(dlgstr, "{80CBC4}Your Properties\tSelect a property...\n");
	}

	Dialog_ShowCallback(playerid, using inline DeathSpawnPick, DIALOG_STYLE_TABLIST_HEADERS, "Respawn Location", dlgstr, "Select", "Hospital");

	return true;
}

// Clears the injury data of a player.
Injury_RemoveData(playerid)
{
    TogglePlayerControllable(playerid, true);
    Injury_RemoveVariables(playerid);
    KO_ResetPlayer(playerid);          

    Weapon_SetSkillLevel(playerid, 999);

    SetPlayerChatBubble(playerid, " ", COLOR_INJURY, 7.5, 1000);
    ApplyAnimation(playerid, "PED", "getup_front", 4.1, 0, 0, 0, 0, 0, true);

    SetCharacterHealth(playerid, 100);

    ResetPlayerWounds(playerid);
    ORP_SetPlayerCuffed(playerid, false);
    return true;
}

// Clears the injury data when the player disconnects.
Injury_RemoveData_Player(playerid)
{
    TogglePlayerControllable(playerid, true);
    KO_ResetPlayer(playerid);          

    PlayerVar[playerid][E_PLAYER_INJUREDMODE]      = false;
    PlayerVar[playerid][E_PLAYER_INJURED_LAST_VEH] = 0;
    PlayerVar[playerid][E_PLAYER_INJURY_TICK]      = 60;

    Weapon_SetSkillLevel(playerid, 999);

    SetPlayerChatBubble(playerid, " ", COLOR_INJURY, 7.5, 1000);
    ApplyAnimation(playerid, "PED", "getup_front", 4.1, 0, 0, 0, 0, 0, true);

    SetCharacterHealth(playerid, 50);

    return true;
}
