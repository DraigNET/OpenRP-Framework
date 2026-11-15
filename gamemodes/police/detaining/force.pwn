// ============================================================================
// File: police/detaining/force.pwn
// /force: walk a cuffed suspect through a door or passpoint they cannot open themselves,
// checking the officer's faction access.
// Commands: /force
// ============================================================================

// ============================================================================
// /force - walking a cuffed suspect through a door they can't open themselves.
//
// Faction-restricted properties and passpoints check the FACTION OF THE PERSON
// GOING THROUGH, which is right for keeping the public out of a station, but it
// also blocks the arrest itself: an officer can reach the cells and the suspect
// can't, so there's no way to finish the escort.
//
// This moves the SUSPECT ONLY. The officer walks in under their own steam with
// /enter or /pass, which keeps the roleplay honest - you open the door and put
// them through it, you don't both blink inside at once.
//
// The gate is "could you use this door yourself": whoever is doing the forcing
// has to satisfy the same faction restriction the suspect is failing. That
// covers an officer at the station without hardcoding it to police, so a
// faction can also drag a cuffed captive into their own restricted property.
// If that's not wanted, gate Force_CanUseFaction on IsPlayerInLEAFaction.
// ============================================================================

// Door proximity deliberately mirrors the real gates rather than inventing its
// own: a passpoint uses its own configured radius, and a property uses the same
// distance /enter does. Being looser here would let you push someone through a
// door neither of you is actually stood at.
#define FORCE_REACH_PLAYER      (5.0)   // how close the suspect must be to you

// Can this player pass a faction restriction? 0 / INVALID means unrestricted.
static bool: Force_CanUseFaction(playerid, factionid) {

	if ( factionid == INVALID_PROPERTY_FACTION ) {

		return true ;
	}

	return ( Character [ playerid ] [ E_CHARACTER_FACTIONID ] == factionid ) ;
}

// Nearest passpoint, and which end of it you're standing at.
// Returns the passpoint index, or INVALID_PASSPOINT_ID. `end` comes back 0 for
// the original point and 1 for the linked one.
static Force_FindPasspoint(playerid, &end) {

	new point_id = INVALID_PASSPOINT_ID, Float: best = 99999.0, Float: dis ;

	end = 0 ;

	foreach (new i : Passpoints) {

		if ( Passpoint [ i ] [ E_PASSPOINT_SQLID ] == INVALID_PASSPOINT_ID ) {

			continue ;
		}

		if ( GetPlayerInterior(playerid) == Passpoint [ i ] [ E_PASSPOINT_INTERIOR ]
			&& GetPlayerVirtualWorld(playerid) == Passpoint [ i ] [ E_PASSPOINT_WORLD ] ) {

			dis = GetPlayerDistanceFromPoint(playerid,
				Passpoint [ i ] [ E_PASSPOINT_POS_X ],
				Passpoint [ i ] [ E_PASSPOINT_POS_Y ],
				Passpoint [ i ] [ E_PASSPOINT_POS_Z ] ) ;

			if ( dis < best && dis < Passpoint [ i ] [ E_PASSPOINT_RADIUS ] ) {

				best = dis ;
				point_id = i ;
				end = 0 ;
			}
		}

		if ( GetPlayerInterior(playerid) == Passpoint [ i ] [ E_PASSPOINT_LINKED_INTERIOR ]
			&& GetPlayerVirtualWorld(playerid) == Passpoint [ i ] [ E_PASSPOINT_LINKED_WORLD ] ) {

			dis = GetPlayerDistanceFromPoint(playerid,
				Passpoint [ i ] [ E_PASSPOINT_LINKED_X ],
				Passpoint [ i ] [ E_PASSPOINT_LINKED_Y ],
				Passpoint [ i ] [ E_PASSPOINT_LINKED_Z ] ) ;

			if ( dis < best && dis < Passpoint [ i ] [ E_PASSPOINT_RADIUS ] ) {

				best = dis ;
				point_id = i ;
				end = 1 ;
			}
		}
	}

	return point_id ;
}

// The name of wherever the suspect is about to come out, for the fade text.
static Force_PasspointDest(point_id, end, dest[], len) {

	// Same trap as the label: a ternary cannot pick between two arrays in Pawn,
	// so this branches properly instead.
	if ( end == 0 ) {

		// Going to the linked end, which may carry its own name.
		if ( Passpoint [ point_id ] [ E_PASSPOINT_LINKED_DESC ] [ 0 ] == EOS ) {

			format(dest, len, "%s", Passpoint [ point_id ] [ E_PASSPOINT_DESC ] ) ;
		}

		else {

			format(dest, len, "%s", Passpoint [ point_id ] [ E_PASSPOINT_LINKED_DESC ] ) ;
		}
	}

	else {

		format(dest, len, "%s", Passpoint [ point_id ] [ E_PASSPOINT_DESC ] ) ;
	}

	return 1 ;
}

// /force [player] - walks a cuffed suspect through the door or passpoint you're at, checking your
// faction's access.
CMD:force(playerid, params[]) {

	new targetid ;

	if ( sscanf(params, "k<player>", targetid) ) {

		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/force [player]") ;

		return SendClientMessage(playerid, COLOR_GREY,
			"Puts a cuffed suspect through the door you're stood at. You still go through yourself with /enter or /pass.") ;
	}

	if ( targetid == INVALID_PLAYER_ID || ! IsPlayerConnected(targetid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "Invalid player.") ;
	}

	if ( targetid == playerid ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "You can't force yourself through a door.") ;
	}

	if ( GetPVarInt(targetid, "CUFFED") != 1 ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "This player isn't cuffed.") ;
	}

	// Same side of the door as you, and within arm's reach of it.
	if ( GetPlayerInterior(targetid) != GetPlayerInterior(playerid)
		|| GetPlayerVirtualWorld(targetid) != GetPlayerVirtualWorld(playerid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "They aren't with you.") ;
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos(targetid, x, y, z) ;

	if ( ! IsPlayerInRangeOfPoint(playerid, FORCE_REACH_PLAYER, x, y, z) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "You're too far away from this player.") ;
	}

	new name [ MAX_PLAYER_NAME ] ;
	format(name, sizeof ( name ), "%s", ReturnPlayerRPName(targetid) ) ;

	// --- a passpoint? -------------------------------------------------------
	new end, point_id = Force_FindPasspoint(playerid, end) ;

	if ( point_id != INVALID_PASSPOINT_ID ) {

		if ( Passpoint [ point_id ] [ E_PASSPOINT_TYPE ] != 0 ) {

			return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE",
				"That passpoint is for vehicles - use /detain and drive them through.") ;
		}

		if ( ! Force_CanUseFaction(playerid, Passpoint [ point_id ] [ E_PASSPOINT_FACTION ] ) ) {

			return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE",
				"You don't have access to this passpoint yourself.") ;
		}

		if ( Passpoint [ point_id ] [ E_PASSPOINT_LOCKED ]
			&& Passpoint [ point_id ] [ E_PASSPOINT_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

			return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "This passpoint is locked.") ;
		}

		new dest [ 64 ] ;
		Force_PasspointDest(point_id, end, dest, sizeof ( dest ) ) ;

		if ( end == 0 ) {

			SetPlayerVirtualWorld(targetid, Passpoint [ point_id ] [ E_PASSPOINT_LINKED_WORLD ] ) ;
			SetPlayerInterior(targetid, Passpoint [ point_id ] [ E_PASSPOINT_LINKED_INTERIOR ] ) ;
			ORP_SetPosWithFade(targetid,
				Passpoint [ point_id ] [ E_PASSPOINT_LINKED_X ],
				Passpoint [ point_id ] [ E_PASSPOINT_LINKED_Y ],
				Passpoint [ point_id ] [ E_PASSPOINT_LINKED_Z ], dest) ;
			SetPlayerFacingAngle(targetid, Passpoint [ point_id ] [ E_PASSPOINT_LINKED_A ] ) ;
		}

		else {

			SetPlayerVirtualWorld(targetid, Passpoint [ point_id ] [ E_PASSPOINT_WORLD ] ) ;
			SetPlayerInterior(targetid, Passpoint [ point_id ] [ E_PASSPOINT_INTERIOR ] ) ;
			ORP_SetPosWithFade(targetid,
				Passpoint [ point_id ] [ E_PASSPOINT_POS_X ],
				Passpoint [ point_id ] [ E_PASSPOINT_POS_Y ],
				Passpoint [ point_id ] [ E_PASSPOINT_POS_Z ], dest) ;
			SetPlayerFacingAngle(targetid, Passpoint [ point_id ] [ E_PASSPOINT_POS_A ] ) ;
		}

		Force_Announce(playerid, targetid, name, dest) ;

		AddLogEntry(playerid, LOG_TYPE_SCRIPT,
			sprintf("Forced %s through Passpoint %d \"%s\" (SQL: %d)",
				name, point_id, Passpoint [ point_id ] [ E_PASSPOINT_DESC ],
				Passpoint [ point_id ] [ E_PASSPOINT_SQLID ] ) ) ;

		return 1 ;
	}

	// --- a property? --------------------------------------------------------
	new bool: going_in = true ;
	new index = Property_GetClosestEntity(playerid, PROPERTY_NEAR_ENTER) ;

	if ( index == INVALID_PROPERTY_ID ) {

		index = Property_GetClosestEntity(playerid, PROPERTY_NEAR_EXIT) ;
		going_in = false ;
	}

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE",
			"You're not stood at a property entrance or a passpoint.") ;
	}

	if ( ! Force_CanUseFaction(playerid, Property [ index ] [ E_PROPERTY_FACTION ] ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE",
			"You don't have access to this property yourself.") ;
	}

	if ( going_in && Property [ index ] [ E_PROPERTY_LOCKED ] ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "This property is locked.") ;
	}

	new dest [ 64 ] ;

	if ( going_in ) {

		format(dest, sizeof ( dest ), "%s", FormatPropertyName(index) ) ;

		SetPlayerInterior(targetid, Property [ index ] [ E_PROPERTY_INT_INT ] ) ;
		SetPlayerVirtualWorld(targetid, Property [ index ] [ E_PROPERTY_INT_VW ] ) ;
		ORP_SetPosWithFade(targetid,
			Property [ index ] [ E_PROPERTY_INT_X ],
			Property [ index ] [ E_PROPERTY_INT_Y ],
			Property [ index ] [ E_PROPERTY_INT_Z ], dest) ;

		PlayerVar [ targetid ] [ E_PLAYER_LAST_PROPERTY_ENTERED ] = index ;
	}

	else {

		format(dest, sizeof ( dest ), "outside") ;

		SetPlayerInterior(targetid, Property [ index ] [ E_PROPERTY_EXT_INT ] ) ;
		SetPlayerVirtualWorld(targetid, Property [ index ] [ E_PROPERTY_EXT_VW ] ) ;
		SetPlayerWeather(targetid, Server [ E_SERVER_WEATHER ] ) ;
		SetPlayerTime(targetid, Server [ E_SERVER_TIME_HOURS ], Server [ E_SERVER_TIME_MINUTES ] ) ;

		if ( IsPlayerListeningToAudioStream(targetid) ) {

			ORP_StopAudioStreamForPlayer(targetid) ;
		}

		ORP_SetPosWithFade(targetid,
			Property [ index ] [ E_PROPERTY_EXT_X ],
			Property [ index ] [ E_PROPERTY_EXT_Y ],
			Property [ index ] [ E_PROPERTY_EXT_Z ], dest) ;
	}

	Force_Announce(playerid, targetid, name, dest) ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT,
		sprintf("Forced %s %s Property %d \"%s\"",
			name, going_in ? ("into") : ("out of"), index, Property [ index ] [ E_PROPERTY_NAME ] ) ) ;

	return 1 ;
}

// The suspect vanishes through a door while the officer stays put, so anyone
// watching needs to be told what happened or it reads as a desync.
static Force_Announce(playerid, targetid, const name[], const dest[]) {

	// Property names arrive carrying gametext colour codes (~y~ and friends),
	// which are for the on-screen fade, not chat - in a chat line they'd print
	// literally. Strip them for the messages; the fade keeps its colour.
	new clean [ 64 ] ;
	format(clean, sizeof ( clean ), "%s", dest) ;

	strreplace(clean, "~r~", "") ; strreplace(clean, "~g~", "") ;
	strreplace(clean, "~b~", "") ; strreplace(clean, "~y~", "") ;
	strreplace(clean, "~p~", "") ; strreplace(clean, "~l~", "") ;
	strreplace(clean, "~w~", "") ; strreplace(clean, "~h~", "") ;

	SendServerMessage(playerid, COLOUR_JOB, "Force", "DEDEDE",
		sprintf("You put %s through into %s. Follow them in yourself.", name, clean) ) ;

	SendServerMessage(targetid, COLOUR_JOB, "Force", "DEDEDE",
		sprintf("%s puts you through into %s.", ReturnPlayerRPName(playerid), clean) ) ;

	ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
		sprintf("takes %s by the arm and puts them through the door.", name), .annonated=true) ;

	return 1 ;
}
