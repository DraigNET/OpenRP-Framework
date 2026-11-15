// ============================================================================
// File: gym/stats.pwn
// Gym stats screen and fighting styles (/fightstyle, /setfightstyle): applies fighting-style
// damage rules and expiry.
// Commands: /setfightstyle /fightstyle /spoofgymgui
// ============================================================================



// Shows a stats update on screen (energy, weight, muscle) when a stat changes.
Gym_DisplayStatsUpdate(playerid, stat, type) {

	TextDrawShowForPlayer ( playerid, E_GYM_PROGRESS_GUI ) ;

	PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][1], Gym_GetStatsSprite(playerid, stat, type ) ); 

	switch ( stat ) {

		case E_GYM_STAT_ENERGY: {

			PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][0], "Energy" ); 

			switch ( type ) {
				case false : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "-" ); 
				case true  : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "+" ); 
			}
		}
		case E_GYM_STAT_WEIGHT: {

			PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][0], "Weight" ); 

			switch ( type ) {
				case false : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "-" ); 
				case true  : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "+" ); 
			}
		}
		case E_GYM_STAT_MUSCLE: {

			PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][0], "Muscle" ); 

			switch ( type ) {
				case false : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "-" ); 
				case true  : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "+" ); 
			}
		}
		case E_GYM_STAT_HUNGER: {
			PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][0], "Hunger" ); 

			switch ( type ) {
				case false : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "-" ); 
				case true  : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "+" ); 
			}
		}
		case E_GYM_STAT_THIRST: {

			PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][0], "Thirst" ); 

			switch ( type ) {
				case false : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "-" ); 
				case true  : PlayerTextDrawSetString( playerid, E_GYM_PROGRESS_PGUI[playerid][2], "+" ); 
			}
		}
	}


	PlayerTextDrawShow( playerid, E_GYM_PROGRESS_PGUI[playerid][0] ); 
	PlayerTextDrawShow( playerid, E_GYM_PROGRESS_PGUI[playerid][1] ); 
	PlayerTextDrawShow( playerid, E_GYM_PROGRESS_PGUI[playerid][2] ); 
	Gym_SaveVariables(playerid);
	//SendClientMessage ( playerid, -1, sprintf("DEV: Showing progress update type %d, status %d.", stat, type));

	PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_SHOWN ] = true ;
	PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_UNIX ] = gettime() + 10 ;
	defer Gym_HideStatsUpdate(playerid);
}

// Timer: hides the stats update after ten seconds.
timer Gym_HideStatsUpdate[10000](playerid) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_SHOWN ] ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_UNIX ] < gettime() ) {
			TextDrawHideForPlayer ( playerid, E_GYM_PROGRESS_GUI ) ;

			PlayerTextDrawHide( playerid, E_GYM_PROGRESS_PGUI[playerid][0] ); 
			PlayerTextDrawHide( playerid, E_GYM_PROGRESS_PGUI[playerid][1] ); 
			PlayerTextDrawHide( playerid, E_GYM_PROGRESS_PGUI[playerid][2] ); 

			PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_SHOWN ] = false ;
			PlayerVar [ playerid ] [ E_PLAYER_GYM_UPDATE_UNIX ] = 0 ;
			return true ;
		}

		else {
			defer Gym_HideStatsUpdate[2500](playerid);
		}
	}

	return true ;
}

// Returns the HUD sprite for a stat level.
Gym_GetStatsSprite(playerid, stat, type ) {

	new level, sprite [ 64 ] ;
	switch ( stat ) {

		case E_GYM_STAT_ENERGY: level = Character [ playerid ] [ E_CHARACTER_GYM_ENERGY ] ;
		case E_GYM_STAT_WEIGHT: level = Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] ;
		case E_GYM_STAT_MUSCLE: level = Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] ;
		case E_GYM_STAT_HUNGER: level = Character [ playerid ] [ E_CHARACTER_GYM_HUNGER ] ;
		case E_GYM_STAT_THIRST: level = Character [ playerid ] [ E_CHARACTER_GYM_THIRST ] ;
	}

	switch ( type ) {

		case false: {

			switch ( level ) {
				case 0:		format ( sprite, sizeof ( sprite ), "mdl-22586:-0" ) ;
				case 1:		format ( sprite, sizeof ( sprite ), "mdl-22586:-1" ) ;
				case 2:		format ( sprite, sizeof ( sprite ), "mdl-22586:-2" ) ;
				case 3:		format ( sprite, sizeof ( sprite ), "mdl-22586:-3" ) ;
				case 4:		format ( sprite, sizeof ( sprite ), "mdl-22586:-4" ) ;
				case 5:		format ( sprite, sizeof ( sprite ), "mdl-22586:-5" ) ;
				case 6:		format ( sprite, sizeof ( sprite ), "mdl-22586:-6" ) ;
				case 7:		format ( sprite, sizeof ( sprite ), "mdl-22586:-7" ) ;
				case 8:		format ( sprite, sizeof ( sprite ), "mdl-22586:-8" ) ;
				case 9:		format ( sprite, sizeof ( sprite ), "mdl-22586:-9" ) ;
				case 10:	format ( sprite, sizeof ( sprite ), "mdl-22586:-10" ) ;
				case 11:	format ( sprite, sizeof ( sprite ), "mdl-22586:-11" ) ;
				case 12:	format ( sprite, sizeof ( sprite ), "mdl-22586:-12" ) ;
				case 13:	format ( sprite, sizeof ( sprite ), "mdl-22586:-13" ) ;
				case 14:	format ( sprite, sizeof ( sprite ), "mdl-22586:-14" ) ;
				case 15:	format ( sprite, sizeof ( sprite ), "mdl-22586:-15" ) ;
				case 16:	format ( sprite, sizeof ( sprite ), "mdl-22586:-16" ) ;
				case 17:	format ( sprite, sizeof ( sprite ), "mdl-22586:-17" ) ;
				case 18:	format ( sprite, sizeof ( sprite ), "mdl-22586:-18" ) ;
				case 19:	format ( sprite, sizeof ( sprite ), "mdl-22586:-19" ) ;
				case 20:	format ( sprite, sizeof ( sprite ), "mdl-22586:-20" ) ;
				case 21:	format ( sprite, sizeof ( sprite ), "mdl-22586:-21" ) ;
				case 22:	format ( sprite, sizeof ( sprite ), "mdl-22586:-22" ) ;
				case 23:	format ( sprite, sizeof ( sprite ), "mdl-22586:-23" ) ;
				case 24:	format ( sprite, sizeof ( sprite ), "mdl-22586:-24" ) ;
				case 25:	format ( sprite, sizeof ( sprite ), "mdl-22586:-25" ) ;
				default: {
					format ( sprite, sizeof ( sprite ), "mdl-22586:-0" ) ;
				}
			}
		}

		case true: {

			switch ( level ) {
				case 0:		format ( sprite, sizeof ( sprite ), "mdl-22586:0" ) ;
				case 1:		format ( sprite, sizeof ( sprite ), "mdl-22586:1" ) ;
				case 2:		format ( sprite, sizeof ( sprite ), "mdl-22586:2" ) ;
				case 3:		format ( sprite, sizeof ( sprite ), "mdl-22586:3" ) ;
				case 4:		format ( sprite, sizeof ( sprite ), "mdl-22586:4" ) ;
				case 5:		format ( sprite, sizeof ( sprite ), "mdl-22586:5" ) ;
				case 6:		format ( sprite, sizeof ( sprite ), "mdl-22586:6" ) ;
				case 7:		format ( sprite, sizeof ( sprite ), "mdl-22586:7" ) ;
				case 8:		format ( sprite, sizeof ( sprite ), "mdl-22586:8" ) ;
				case 9:		format ( sprite, sizeof ( sprite ), "mdl-22586:9" ) ;
				case 10:	format ( sprite, sizeof ( sprite ), "mdl-22586:10" ) ;
				case 11:	format ( sprite, sizeof ( sprite ), "mdl-22586:11" ) ;
				case 12:	format ( sprite, sizeof ( sprite ), "mdl-22586:12" ) ;
				case 13:	format ( sprite, sizeof ( sprite ), "mdl-22586:13" ) ;
				case 14:	format ( sprite, sizeof ( sprite ), "mdl-22586:14" ) ;
				case 15:	format ( sprite, sizeof ( sprite ), "mdl-22586:15" ) ;
				case 16:	format ( sprite, sizeof ( sprite ), "mdl-22586:16" ) ;
				case 17:	format ( sprite, sizeof ( sprite ), "mdl-22586:17" ) ;
				case 18:	format ( sprite, sizeof ( sprite ), "mdl-22586:18" ) ;
				case 19:	format ( sprite, sizeof ( sprite ), "mdl-22586:19" ) ;
				case 20:	format ( sprite, sizeof ( sprite ), "mdl-22586:20" ) ;
				case 21:	format ( sprite, sizeof ( sprite ), "mdl-22586:21" ) ;
				case 22:	format ( sprite, sizeof ( sprite ), "mdl-22586:22" ) ;
				case 23:	format ( sprite, sizeof ( sprite ), "mdl-22586:23" ) ;
				case 24:	format ( sprite, sizeof ( sprite ), "mdl-22586:24" ) ;
				case 25:	format ( sprite, sizeof ( sprite ), "mdl-22586:25" ) ;				
				default: {
					format ( sprite, sizeof ( sprite ), "mdl-22586:0" ) ;
				}
			}
		}
	}

	return sprite ;
}
// Returns the progress bar value for a gym level.
Float: Gym_GetProgressBarValue(level) {

	new Float: value ;

	switch(  level ) {

		case 0:		value = 10.0 ;
		case 1:		value = 12.5 ;
		case 2:		value = 17.5 ;
		case 3:		value = 20.0 ;
		case 4:		value = 22.5 ;
		case 5:		value = 27.5 ;
		case 6:		value = 30.0 ;
		case 7:		value = 32.5 ;
		case 8:		value = 37.5 ;
		case 9:		value = 40.0 ;
		case 10: 	value = 42.5 ;
		case 11: 	value = 47.5 ;
		case 12: 	value = 52.5 ;
		case 13: 	value = 57.5 ;
		case 14: 	value = 60.0 ;
		case 15: 	value = 62.5 ;
		case 16: 	value = 67.5 ;
		case 17: 	value = 70.0 ;
		case 18: 	value = 72.5 ;
		case 19: 	value = 77.5 ;
		case 20: 	value = 80.0 ;
		case 21: 	value = 82.5 ;
		case 22: 	value = 87.5 ;
		case 23: 	value = 90.0 ;
		case 24: 	value = 95.0 ;
		case 25: 	value = 100.0 ;
	}

	return value ;
}

// Updates the day name on the gym stats screen.
UpdateGymStatsDay() {
	// Cross hooked from "gui_datetime". This updates the "day" when a player views their gym stats.

	new day [ 64 ] ;
	format ( day, sizeof ( day ), "%s", date_dayName ( Server[ E_SERVER_TIME_DAYS ], Server[ E_SERVER_TIME_MONTHS ], 2005 ) ) ;
	TextDrawSetString(E_GYM_STATS_GUI[7], day);
}

// Rebalanced fighting styles a bit:
// Kung Fu - strong attack, less defense
// Boxing - good attack, average defense
// Grabkick - less attack, good defense

// Adds fighting-style bonus damage to melee hits.
stock Gym_ApplyFightstyleDamage(playerid, issuerid, & Float: final_damage) {

	// Extra damage for ISSUER that has a fightstyle
	switch (  Character [ issuerid ] [ E_CHARACTER_FIGHTSTYLE ] ) 
	{
		case FIGHT_STYLE_GRABKICK: final_damage += 1.0;
		case FIGHT_STYLE_BOXING:  final_damage += 1.25 ;
		case FIGHT_STYLE_KUNGFU:  final_damage += 2.0 ;
	}

	// Lesser damage if PLAYERID has a fightstyle...
	switch (  Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] ) 
	{
		case FIGHT_STYLE_GRABKICK: final_damage -= 1.25 ;
		case FIGHT_STYLE_BOXING:  final_damage -= 1.0 ;
		case FIGHT_STYLE_KUNGFU:  final_damage -= 0.5 ;
	}

	if ( final_damage <= 1 ) 
	{
		final_damage = 0.5 ;
	}
}

// /setfightstyle [player] [style] [paychecks] - (admin) gives a player a fighting style.
CMD:setfightstyle(playerid, const params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}
	
	new targetid, choice[64], fsPaychecks;

	if ( sscanf ( params, "ds[64]d", targetid, choice, fsPaychecks ) ) {

		SendClientMessage ( playerid, COLOR_ERROR, "Syntax:{FFE000} /setfightstyle [player] [choice] [paychecks]");
		SendClientMessage ( playerid, COLOR_ERROR, "Choices:{DEDEDE} normal, grabkick, boxing, kungfu");

		return true ;
	}

	new option = FIGHT_STYLE_NORMAL ;

	if ( ! strcmp ( choice, "normal", true ) ) {
		option = FIGHT_STYLE_NORMAL ;
	}
	else if ( ! strcmp ( choice, "grabkick", true ) ) {
		option = FIGHT_STYLE_GRABKICK ;
	}
	else if ( ! strcmp ( choice, "boxing", true ) ) {
		option = FIGHT_STYLE_BOXING ;
	}
	else if ( ! strcmp ( choice, "kungfu", true ) ) {
		option = FIGHT_STYLE_KUNGFU ;
	}
	else {
		// Invalid choice entered, send syntax error.
		return cmd_setfightstyle(playerid, "");
	}

	if (!IsPlayerPlaying(targetid))
	{
		return SendClientMessage(playerid, -1, "Invalid player target.");
	}

	if (fsPaychecks < 0 || fsPaychecks > 999)
	{
		return SendClientMessage(playerid, COLOR_ERROR, "Paychecks must be between 0 and 999.");
	}

	Character [ targetid ] [ E_CHARACTER_FIGHTSTYLE ] = option ;
	Character [ targetid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = fsPaychecks ; // 50 is the standard

	SetPlayerFightingStyle(targetid, Character [ targetid ] [ E_CHARACTER_FIGHTSTYLE ]);
	Gym_SaveVariables(targetid);

	SendAdminMessage(sprintf("[!!!][AdmWarn] Admin %s has set the fighting style of (%d) %s to %d for %s paychecks.", Account[playerid][E_PLAYER_ACCOUNT_NAME], targetid, ReturnRPName(targetid), option, fsPaychecks));
	SendServerMessage(targetid, COLOR_INFO, "Attributes", "A3A3A3", sprintf("Your character's fighting style was changed to %d for %d paychecks by (%d) %s.", option, fsPaychecks, playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME]));

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Set the fighting style of %s to %d for %d paychecks", ReturnRPName(targetid), option, fsPaychecks));
	AddLogEntry(targetid, LOG_TYPE_ADMIN, sprintf("Fighting style set to %d for %d paychecks by %s", option, fsPaychecks, Account[playerid][E_PLAYER_ACCOUNT_NAME]));

    return true;
}

// /fightstyle [style] - choose a fighting style you have unlocked.
CMD:fightstyle(playerid, const params[]) {

	new choice[64];

	if ( sscanf ( params, "s[64]", choice ) ) {

		SendClientMessage ( playerid, COLOR_ERROR, "Syntax:{FFE000} /fightstyle [choice]");
		SendClientMessage ( playerid, COLOR_ERROR, "Choices:{DEDEDE} grabkick, boxing, kungfu");

		return true ;
	}

	new option = FIGHT_STYLE_NORMAL ;

	if ( ! strcmp ( choice, "grabkick", true ) ) {
		option = FIGHT_STYLE_GRABKICK ;
	}
	else if ( ! strcmp ( choice, "boxing", true ) ) {
		option = FIGHT_STYLE_BOXING ;
	}
	else if ( ! strcmp ( choice, "kungfu", true ) ) {
		option = FIGHT_STYLE_KUNGFU ;
	}

	else {
		// Invalid choice entered, send syntax error.
		return cmd_fightstyle(playerid, "");
	}

	new bool: in_range = false ;

	if ( IsPlayerInRangeOfPoint ( playerid, 5.0, 2246.5261,-1695.0239,	13.5370000)) in_range = true ; // gantongym_fightstylepoint
	else if ( IsPlayerInRangeOfPoint ( playerid, 5.0, 766.1618,	-76.0280,	1000.65630)) in_range = true ; // pacedo_fightstylepoint
	else if ( IsPlayerInRangeOfPoint ( playerid, 5.0, 766.5807,	11.0302,	1000.70600)) in_range = true ; // elsgym/lsgym_fightstylepoint
	else if ( IsPlayerInRangeOfPoint ( playerid, 5.0, 669.2167,	-1867.1255,	5.45370000)) in_range = true ; // beachgym_fightstylepoint

	if ( ! in_range ) {
		return SendClientMessage( playerid, COLOR_ERROR, "You're not near the right area! Go visit a gym and look for the floating boxing gloves.");
	}

	if ( !Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] && Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] == option ) {

		ShowPlayerInfoMessage(playerid, 
			"You've ~g~extended your ~r~fightstyle~w~ for another 15 paychecks. Remember, if you don't maintain your skills you will lose it!", 
			.showtime=6500, .height=167.5, .width=180
		);

		Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = option ;
		Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = 15 ; // 15 paychecks protected

		SetPlayerFightingStyle(playerid, Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] );

		Gym_SaveVariables(playerid);

		return true ;
	}

	if (  Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ]  ) {
	
		new string [ 256 ] ;

		format ( string, sizeof ( string ), "Your fightstyle is ~g~protected~w~ for another %d paychecks. Come back afterwards if you want to ~r~change~w~ or ~b~extend~w~ it.", Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] ) ;

		ShowPlayerInfoMessage(playerid, string, .showtime=6500, .height=167.5, .width=180 );

		return true ;
	}
	
	switch ( option ) {
		case FIGHT_STYLE_GRABKICK: {
			//if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 15 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 10 ) {
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_GRABKICK ;
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = 15 ; // 15 paychecks protected
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"You've unlocked the ~b~grab kick~w~ fightstyle.~n~~n~Your fightstyle is protected for ~b~15 paychecks.~w~ Afterwards you risk ~r~losing it~w~ if you don't maintain your skills.", 
					.showtime=6500, .height=167.5, .width=180
				);
			//}

			/*else {

				ShowPlayerInfoMessage(playerid, 
					"To unlock the ~b~grab kick~w~ fightstyle you must have less than ~r~15 weight~w~ and more than ~r~10 muscle~w~.", 
					.showtime=6500, .height=167.5, .width=180
				);	

				return true ;
			}*/
		}

		case FIGHT_STYLE_BOXING: {

			if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 10 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 15 ) {
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_BOXING ;
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = 15 ; // 15 paychecks protected
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"You've unlocked the ~b~boxing~w~ fightstyle.~n~~n~Your fightstyle is protected for ~b~15 paychecks.~w~ Afterwards you risk ~r~losing it~w~ if you don't maintain your skills.", 
					.showtime=6500, .height=167.5, .width=180
				);
			}

			else {

				ShowPlayerInfoMessage(playerid, 
					"To unlock the ~b~boxing~w~ fightstyle you must have less than ~r~10 weight~w~ and more than ~r~15 muscle~w~.", 
					.showtime=6500, .height=167.5, .width=180
				);	

				return true ;
			}
		}

		case FIGHT_STYLE_KUNGFU: {

			if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 7 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 12 ) {
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_KUNGFU ;
				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = 15 ; // 15 paychecks protected
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"You've unlocked the ~b~kungfu~w~ fightstyle.~n~~n~Your fightstyle is protected for ~b~15 paychecks.~w~ Afterwards you risk ~r~losing it~w~ if you don't maintain your skills.", 
					.showtime=6500, .height=167.5, .width=180
				);
			}

			else {

				ShowPlayerInfoMessage(playerid, 
					"To unlock the ~b~kungfu~w~ fightstyle you must have less than ~r~7 weight~w~ and more than ~r~12 muscle~w~.", 
					.showtime=6500, .height=167.5, .width=180
				);	

				return true ;
			}
		}
	}

	return true ;
}


// Removes a fighting style when the player no longer meets its weight or muscle requirement.
Gym_CheckFightStyleExpiration(playerid) {

	switch ( Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] ) {
		case FIGHT_STYLE_GRABKICK: {
			if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 15 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 10 ) {
				
				return true ;
			}

			else { // Fight style expired (no protection + stats are wrong.)

				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_NORMAL ;				
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"Your fight style has ~r~expired~w~. For the ~b~grabkick~w~ style, you need to have less than ~r~15 weight~w~ and more than ~r~10 muscle~w~. To get it back, visit a gym.", 
					.showtime=6500, .height=167.5, .width=180
				);
				
				return true ;
			}
		}

		case FIGHT_STYLE_BOXING: {

			if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 10 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 15 ) {

				return true ;
			}

			else {// Fight style expired (no protection + stats are wrong.)


				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_NORMAL ;				
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"Your fight style has ~r~expired~w~. For the ~b~grabkick~w~ style, you need to have less than ~r~10 weight~w~ and more than ~r~15 muscle~w~. To get it back, visit a gym.", 
					.showtime=6500, .height=167.5, .width=180
				);
				
				return true ;
			}
		}

		case FIGHT_STYLE_KUNGFU: {

			if ( Character [ playerid ] [ E_CHARACTER_GYM_WEIGHT ] < 7 && Character [ playerid ] [ E_CHARACTER_GYM_MUSCLE ] > 12 ) {

				return true ;
			}

			else {// Fight style expired (no protection + stats are wrong.)

				Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_NORMAL ;				
				Gym_SaveVariables(playerid);

				ShowPlayerInfoMessage(playerid, 
					"Your fight style has ~r~expired~w~. For the ~b~kungfu~w~ style, you need to have less than ~r~7 weight~w~ and more than ~r~12 muscle~w~. To get it back, visit a gym.", 
					.showtime=6500, .height=167.5, .width=180
				);
				
				return true ;
			}
		}
	}

	return true ;
}

/*
// To test the GUI:
CMD:spoofgymgui(playerid, params[]) {


	new stat, decr ;

	if ( sscanf ( params, "ii", stat, decr ) ) {

		SendClientMessage ( playerid, -1, "/spoofgymgui [stat] [0: negative, 1: positive" ) ;
		SendClientMessage ( playerid, -1, sprintf("Stats: [%d: Energy | %d: Weight | %d: Muscle | %d: Hunger | %d: Thirst] ",

			E_GYM_STAT_ENERGY,
			E_GYM_STAT_WEIGHT,
			E_GYM_STAT_MUSCLE,
			E_GYM_STAT_HUNGER,
			E_GYM_STAT_THIRST 
		)) ;

		return true ;
	}

	if ( decr < 0 || decr > 1 ) {

		return SendClientMessage ( playerid, -1, "Valid values are TRUE (1) or FALSE (0)");
	}

	Gym_DisplayStatsUpdate(playerid, stat, decr);

	return true ;
}*/
