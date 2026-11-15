// ============================================================================
// File: injury/corpse.pwn
// Corpses: when a player dies or accepts death, an actor with their skin lies where they fell
// for a while. /removebody (/removecorpse) is for staff.
// Commands: /removebody /removecorpse
// ============================================================================

// ============================================================================
// Corpse system - when a player is executed or accepts death, an actor with
// their skin is left lying at the death spot. It stays for CORPSE_LIFETIME
// or until an on-duty medic removes it with /removecorpse.
// Spawned from Injury_OnPlayerDeath, before the hospital teleport moves the
// player away from where they died.
// ============================================================================

// MAX_CORPSES / CORPSE_LIFETIME / CORPSE_REMOVE_RANGE / MAX_CORPSE_WOUNDS are
// defined in injury/header.pwn, before the includes - list.pwn (compiled
// earlier) needs CORPSE_REMOVE_RANGE for the no-target /damages fallback.

enum E_CORPSE_DATA {
	E_CORPSE_ACTOR,
	DynamicText3D: E_CORPSE_LABEL,
	E_CORPSE_EXPIRES, // unix
	bool: E_CORPSE_ACTIVE,
	E_CORPSE_NAME [ MAX_PLAYER_NAME + 1 ],
	Float: E_CORPSE_X,
	Float: E_CORPSE_Y,
	Float: E_CORPSE_Z,
	E_CORPSE_VW,
	E_CORPSE_WOUNDS
}

new Corpse [ MAX_CORPSES ] [ E_CORPSE_DATA ] ;

// Wound snapshot, copied from PlayerWounds at death - the live records are
// wiped once the victim respawns, but the body still shows what happened.
new CorpseWoundPart   [ MAX_CORPSES ] [ MAX_CORPSE_WOUNDS ] ;
new CorpseWoundWeapon [ MAX_CORPSES ] [ MAX_CORPSE_WOUNDS ] ;
new Float: CorpseWoundAmount [ MAX_CORPSES ] [ MAX_CORPSE_WOUNDS ] ;
new CorpseWoundGiver  [ MAX_CORPSES ] [ MAX_CORPSE_WOUNDS ] [ 32 ] ;

// Removes a corpse actor and frees its slot.
Corpse_Destroy(slot) {

	if ( ! Corpse [ slot ] [ E_CORPSE_ACTIVE ] ) return true ;

	if ( IsValidDynamicActor(Corpse [ slot ] [ E_CORPSE_ACTOR ]) ) {

		DestroyDynamicActor(Corpse [ slot ] [ E_CORPSE_ACTOR ]) ;
	}

	if ( IsValidDynamic3DTextLabel(Corpse [ slot ] [ E_CORPSE_LABEL ]) ) {

		DestroyDynamic3DTextLabel(Corpse [ slot ] [ E_CORPSE_LABEL ]) ;
	}

	Corpse [ slot ] [ E_CORPSE_ACTOR ] = -1 ;
	Corpse [ slot ] [ E_CORPSE_ACTIVE ] = false ;
	Corpse [ slot ] [ E_CORPSE_WOUNDS ] = 0 ;

	return true ;
}

// Nearest active corpse within range of the player (same virtual world), or -1.
Corpse_GetNearest(playerid, Float: range) {

	new slot = -1 ;
	new Float: nearest = range + 1.0 ;

	for ( new i = 0 ; i < MAX_CORPSES ; i ++ ) {

		if ( ! Corpse [ i ] [ E_CORPSE_ACTIVE ] ) continue ;
		if ( Corpse [ i ] [ E_CORPSE_VW ] != GetPlayerVirtualWorld(playerid) ) continue ;

		new Float: dist = GetPlayerDistanceFromPoint(playerid, Corpse [ i ] [ E_CORPSE_X ], Corpse [ i ] [ E_CORPSE_Y ], Corpse [ i ] [ E_CORPSE_Z ]) ;

		if ( dist < nearest ) {

			nearest = dist ;
			slot = i ;
		}
	}

	return slot ;
}

// Leaves a corpse (actor with the player's skin and wounds) at the place a player died.
Corpse_Spawn(playerid) {

	// Free slot, or fall back to recycling the corpse closest to expiring so a
	// death never goes corpse-less.
	new slot = -1, oldest = 0 ;

	for ( new i = 0 ; i < MAX_CORPSES ; i ++ ) {

		if ( ! Corpse [ i ] [ E_CORPSE_ACTIVE ] ) {

			slot = i ;
			break ;
		}

		if ( Corpse [ i ] [ E_CORPSE_EXPIRES ] < Corpse [ oldest ] [ E_CORPSE_EXPIRES ] ) {

			oldest = i ;
		}
	}

	if ( slot == -1 ) {

		Corpse_Destroy(oldest) ;
		slot = oldest ;
	}

	new Float: x, Float: y, Float: z, Float: angle ;

	GetPlayerPos(playerid, x, y, z) ;
	GetPlayerFacingAngle(playerid, angle) ;

	Corpse [ slot ] [ E_CORPSE_ACTOR ] = CreateDynamicActor(Character [ playerid ] [ E_CHARACTER_SKINID ], x, y, z, angle,
		true, 100.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), -1) ;

	ApplyDynamicActorAnimation(Corpse [ slot ] [ E_CORPSE_ACTOR ], "PED", "FLOOR_hit_f", 4.1, 0, 0, 0, 1, 0) ;

	Corpse [ slot ] [ E_CORPSE_ACTIVE ] = true ;
	Corpse [ slot ] [ E_CORPSE_EXPIRES ] = gettime() + CORPSE_LIFETIME ;
	Corpse [ slot ] [ E_CORPSE_X ] = x ;
	Corpse [ slot ] [ E_CORPSE_Y ] = y ;
	Corpse [ slot ] [ E_CORPSE_Z ] = z ;
	Corpse [ slot ] [ E_CORPSE_VW ] = GetPlayerVirtualWorld(playerid) ;

	format(Corpse [ slot ] [ E_CORPSE_NAME ], MAX_PLAYER_NAME + 1, "%s", ReturnRPName(playerid)) ;

	Corpse [ slot ] [ E_CORPSE_LABEL ] = CreateDynamic3DTextLabel(
		sprintf("(( This is the body of %s [ /damages ] ))", Corpse [ slot ] [ E_CORPSE_NAME ]),
		COLOR_INJURY, x, y, z, 15.0, .testlos = false,
		.worldid = GetPlayerVirtualWorld(playerid), .interiorid = GetPlayerInterior(playerid)) ;

	// Snapshot the wounds - the live records get wiped when the victim respawns.
	Corpse [ slot ] [ E_CORPSE_WOUNDS ] = 0 ;

	for ( new i = 0 ; i < MAX_WOUNDS && Corpse [ slot ] [ E_CORPSE_WOUNDS ] < MAX_CORPSE_WOUNDS ; i ++ ) {

		if ( PlayerWounds [ i ] [ dmg_player ] != playerid ) continue ;

		new w = Corpse [ slot ] [ E_CORPSE_WOUNDS ] ;

		CorpseWoundPart   [ slot ] [ w ] = PlayerWounds [ i ] [ dmg_bodypart ] ;
		CorpseWoundWeapon [ slot ] [ w ] = PlayerWounds [ i ] [ dmg_weapon ] ;
		CorpseWoundAmount [ slot ] [ w ] = PlayerWounds [ i ] [ dmg_amount ] ;
		format(CorpseWoundGiver [ slot ] [ w ], 32, "%s", PlayerWounds [ i ] [ dmg_giver ]) ;

		Corpse [ slot ] [ E_CORPSE_WOUNDS ] ++ ;
	}

	return true ;
}

// The /damages view for a body - same layout as a live player's injury list,
// with the attacker column visible to admins only.
Corpse_ShowDamages(playerid, slot) {

	if ( ! Corpse [ slot ] [ E_CORPSE_WOUNDS ] ) {

		return SendServerMessage(playerid, COLOR_INJURY, "Injury", "A3A3A3",
			sprintf("The body of %s has no visible injuries.", Corpse [ slot ] [ E_CORPSE_NAME ])) ;
	}

	new bool: show_giver = GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR ;
	new string [ 2500 ] ;

	strcat(string, "Injury\tType\tDamage") ;
	if ( show_giver ) strcat(string, "\tPlayer") ;

	for ( new w = 0 ; w < Corpse [ slot ] [ E_CORPSE_WOUNDS ] ; w ++ ) {

		if ( show_giver ) {

			strcat(string, sprintf("\n%s\t%s\t(%0.1f)\t%s",
				GetBodyPartName(CorpseWoundPart [ slot ] [ w ]),
				GetWoundType(CorpseWoundWeapon [ slot ] [ w ]),
				CorpseWoundAmount [ slot ] [ w ],
				CorpseWoundGiver [ slot ] [ w ])) ;
		}

		else {

			strcat(string, sprintf("\n%s\t%s\t(%0.1f)",
				GetBodyPartName(CorpseWoundPart [ slot ] [ w ]),
				GetWoundType(CorpseWoundWeapon [ slot ] [ w ]),
				CorpseWoundAmount [ slot ] [ w ])) ;
		}
	}

	ShowPlayerDialog(playerid, 546, DIALOG_STYLE_TABLIST_HEADERS,
		sprintf("Injuries to the body of %s", Corpse [ slot ] [ E_CORPSE_NAME ]),
		string, "Close", "") ;

	return true ;
}

// Every minute: removes corpses that have expired.
task Corpse_ExpiryTick[60000]() {

	for ( new i = 0 ; i < MAX_CORPSES ; i ++ ) {

		if ( Corpse [ i ] [ E_CORPSE_ACTIVE ] && gettime() >= Corpse [ i ] [ E_CORPSE_EXPIRES ] ) {

			Corpse_Destroy(i) ;
		}
	}
}

CMD:removebody(playerid) return cmd_removecorpse(playerid);

// /removecorpse - on-duty medical staff can remove the nearest corpse.
CMD:removecorpse(playerid) {

	if ( ! IsPlayerInMedicFaction(playerid, .onduty = true) && ! GetPlayerAdminLevel(playerid) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Only on-duty medics can remove a body.") ;
	}

	new slot = Corpse_GetNearest(playerid, CORPSE_REMOVE_RANGE) ;

	if ( slot == -1 ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "There's no body near you.") ;
	}

	ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
		sprintf("covers up the body of %s and has it taken away.", Corpse [ slot ] [ E_CORPSE_NAME ]), .annonated=true) ;

	SendServerMessage(playerid, COLOR_INJURY_LIGHT, "Medic", "A3A3A3",
		sprintf("You've removed the body of %s.", Corpse [ slot ] [ E_CORPSE_NAME ])) ;

	Corpse_Destroy(slot) ;

	return true ;
}
