// ============================================================================
// File: player/player_hooked.pwn
// The optimised OnPlayerUpdate loop and other per-player timers, plus /stats (/checkstats) and
// the optional Fear and Respect system (FEATURE_FNR). A lot of per-second checks live here.
// Commands: /stats /checkstats /giverespect /givefear /fnrstats /spoofrespect /spooffear
// /givefnrpoints /setfnrlevel /testlevelup
// ============================================================================

// A more "optimized" OnPlayerUpdate. Useful when constant 
// checks are required such as gang tag script or boombox sync.

static plrIP[16];
static plrIPMsg[128];

// Kicks players whose IP reads 255.255.255.255 (a known exploit) and alerts staff.
static CheckInvalidIP(playerid)
{
	GetPlayerIp(playerid, plrIP, sizeof(plrIP));

	if (!strcmp(plrIP, "255.255.255.255"))
	{
		format(plrIPMsg, sizeof(plrIPMsg), "[AdmWarn] (%d) %s was kicked for having an invalid IP.", playerid, ReturnRPName(playerid));
		Kick(playerid);
		SendAdminMessage(plrIPMsg);
		print(plrIPMsg);
	}
}

ptask PLAYER_CONSTANT_TICK[1000](playerid){

	if ( playerid > MAX_PLAYERS ) {
		KickPlayer ( playerid );
		return true ;
	}

	if ( ++ PlayerVar [ playerid ] [ E_PLAYER_OTHER_STUFF_TICK ] >= 5 ) 
	{
		PlayerVar [ playerid ] [ E_PLAYER_OTHER_STUFF_TICK ] = 0 ;
		CheckInvalidIP(playerid); // Temp anti invalid IP measure here
	}

	if ( PlayerVar [ playerid ] [ player_islogged ] ) {
		
		// Report Reminders
		Report_PlayerTick(playerid);
		Question_PlayerTick(playerid);

		// Trying Clothes
		TryingSkin_Tick(playerid);

		// Anticheat tick
		Anticheat_Tick ( playerid );

		// Re-apply injury animation!
		if (  PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {
			if ( GetPlayerAnimationIndex ( playerid ) != 1701 ) {

				ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);
			}
		}

		// reset crate pos on death
		if ( PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] && PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX ] != -1 ) {
			RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
			SetPlayerSpecialAction(playerid, 0);
			PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX ] = -1 ; 
			ApplyAnimation(playerid, "WUZI", "CS_Dead_Guy", 4.1, 0, 0, 0, 1, 0, 1);
		}

		Tazer_ResetTick(playerid );
		Beanbag_ResetTick(playerid) ;
		SpectateTick(playerid, PlayerVar [ playerid ] [ E_PLAYER_IS_SPECTATING ] ) ;

		if ( IsPlayerSpawned ( playerid ) ) {

			//Gym_CheckForSync(playerid) ;
			Gym_StatsUpdate(playerid);
			OnPlayerRefuelCar(playerid);

			if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_GUNBAN ] && GetPlayerWeapon ( playerid ) != 0 ) {
				if ( AC_GetPlayerWeapon(playerid) || GetPlayerCustomWeapon(playerid) != -1 ) {

					SendAdminMessage(sprintf("[GUN BAN VIOLATION] (%d) %s has a gun ban and is holding weapons! (client %d server %d)", playerid, ReturnRPName ( playerid ), AC_GetPlayerWeapon(playerid), GetPlayerCustomWeapon(playerid) )) ;
					RemovePlayerCustomWeapon(playerid, GetPlayerCustomWeapon(playerid) ) ;
					AC_RemovePlayerWeapon(playerid, AC_GetPlayerWeapon(playerid) ) ;
				}
			}

			Pool_OnPlayerUpdate(playerid);

			if ( IsPlayerPaused ( playerid ) ) {

				if ( ! PlayerVar [ playerid ] [ E_PLAYER_PAUSE_TAG_UPDATE ] ) {

					PlayerVar [ playerid ] [ E_PLAYER_PAUSE_TAG_UPDATE ] = true ;
       				//UpdateTabListForOthers ( playerid ) ;
				}
			}

			else if ( ! IsPlayerPaused ( playerid ) ) {

				if ( PlayerVar [ playerid ] [ E_PLAYER_PAUSE_TAG_UPDATE ] ) {

					PlayerVar [ playerid ] [ E_PLAYER_PAUSE_TAG_UPDATE ] = false ;
        			//UpdateTabListForOthers ( playerid ) ;
				}
			}


			if ( PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_USED ]  ) {
				if ( -- PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_TICKS ] <= 0 ) {

					PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_TICKS ] = 0 ;
					PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_USED ] = false ;

					SendClientMessage(playerid, 0xDEDEDEFF, "Your backup/panic button activation has expired.");
				}
				else
				{
					if (!PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_PROPERTY ])
					{
						// Only update if they're not in a property
						GetPlayerPos(playerid, PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 0 ], PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 1 ], PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 2 ] ) ;
					}
				}
			}

			if (PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_ACCEPTED ] )
			{
				new targetid = PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_TARGET ];
				if (IsPlayerConnected(targetid) && !PlayerVar [ targetid ] [ E_PLAYER_INJUREDMODE ] && PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_USED ])
				{
					if (PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_TICKS ] % 2 == 0)
					{
						//DisablePlayerCheckpoint(playerid);
						RemovePlayerMapIcon(playerid, 0);
						SetPlayerMapIcon(playerid, 0, PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 0 ], PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 1 ], PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_POS ] [ 2 ], 0, PlayerVar [ targetid ] [ E_PLAYER_PANIC_BUTTON_COLOR ], MAPICON_GLOBAL );
					}
				}
				else
				{
					PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_TARGET ] = INVALID_PLAYER_ID ;
					PlayerVar [ playerid ] [ E_PLAYER_PANIC_BUTTON_ACCEPTED ] = false ;
				}
			}


			Robbery_OnPlayerCooldown(playerid) ;
			ChopShop_CheckVehicleRange(playerid) ;
			Garbage_CheckVehicleRange(playerid) ;

			if ( ! IsPlayerInMinigame(playerid) && !PlayerVar[playerid][E_PLAYER_USING_HOSE] ) {

				if ( IsPlayerAttachedObjectSlotUsed ( playerid, E_ATTACH_INDEX_MINIGAME ) ) {

					RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_MINIGAME ) ;
				}
			}

			//Spike_Tick(playerid) ;
			Anticheat_NewPlayerGunCheck(playerid);

			if ( PlayerVar [ playerid ] [ E_PLAYER_WARP_AC_2 ] > 1 ) {
				PlayerVar [ playerid ] [ E_PLAYER_WARP_AC_2 ] -- ;
				if ( PlayerVar [ playerid ] [ E_PLAYER_WARP_AC_2 ] < 0 ) {
					PlayerVar [ playerid ] [ E_PLAYER_WARP_AC_2 ] = 0 ;
				}
			}


#if defined FEATURE_GANGTAGS
			// Spraytag shit
			if ( ! PlayerVar [ playerid ] [ E_PLAYER_EDITING_TAG ] )
			{
				switch ( PlayerVar [ playerid ] [ E_PLAYER_TAGS_STATE ] ) {

					case 1: SprayTag_SprayingStaticTag(playerid);
					//case 2: SprayTag_SprayingDynamicTag(playerid);
				}
			}
#endif

			GUI_UpdateDirectionLabels(playerid);

			if ( ! Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] ) {
				Arrest_Tick(playerid);
			}

			else if (  Character [ playerid ] [ E_CHARACTER_AJAIL_TIME ] ) {

				AdminJail_Tick(playerid) ;
			}

			PlayerDrug_EffectTick ( playerid ) ;

            if (++ PlayerVar[playerid][E_PLAYER_ADDICTION_DECAY_TICK] >= 300)
            {
                PlayerVar[playerid][E_PLAYER_ADDICTION_DECAY_TICK] = 0;
                Addiction_Decay(playerid);
                //AddictionGUI_Show(playerid);
            }

            PlayerDrug_WithdrawalTick(playerid);


			if ( ++ PlayerVar [ playerid ] [ E_PLAYER_WEAPON_SAVE_TICK ] > 180 ) 
			{
				// Autosaves weapons every 3 mins
				PlayerVar [ playerid ] [ E_PLAYER_WEAPON_SAVE_TICK ] = 0 ;
				Weapon_SavePlayerWeapons(playerid) ;
			}

#if defined FEATURE_EMMET
			Emmet_PlayerCooldownTick(playerid); // emmet cooldown handler
#endif
			Weapon_AnticheatCheck ( playerid ) ;

            Mechanic_Tick(playerid);

			/*
			if ( GetPVarInt(playerid, "AprilFooled") && ! IsPlayerIncapacitated(playerid, false) )
			{
				if (random(30) == 0)
				{
					CallRemoteFunction("ORP_OnPlayerAprilFool", "dd", playerid, GetPVarInt(playerid, "AprilFooled"));
				}
			}
			*/
		}

	}

	return true ;
}
/*
// Prints a player's statistics (level, hours, cash, faction, licences...) to a viewer. (This
// variant is used when Fear & Respect is enabled.)
static ShowPlayerStatsToPlayer(playerid, showplayerid)
{
	new string [ 144 ], buffer [ 32 ] ;

	format ( string, sizeof ( string ), "|_____________| (%d) %s's statistics |_____________|", playerid, ReturnPlayerNameData ( playerid ) ) ;
	SendClientMessage(showplayerid, COLOR_SERVER, string ) ;

	format ( string, sizeof ( string ), "[Account ID: %d] [Character ID: %d] [Account Name: \"%s\"] [Character Name: \"%s\"]",

		Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], Character [ playerid ] [ E_CHARACTER_ID ],
		Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], Character [ playerid ] [ E_CHARACTER_NAME ]
	) ;
	SendClientMessage(showplayerid, COLOR_GRAD0, string);


	new year, month, day, hour, minute, second ;
	stamp2datetime(Character [ playerid ] [ E_CHARACTER_REGISTERDATE ], year, month, day, hour, minute, second, 1 ) ;

	format ( string, sizeof ( string ), "%s the %d%s of %s, %d at %d:%d:%d",
	date_dayName(day, month, year), day, date_dayOrdinal (day), date_getMonth(month), year, hour, minute, second ) ;

	format ( string, sizeof ( string ), "[Register Date: %s]", string );

	if (playerid != showplayerid)
	{
		format ( string, sizeof ( string ), "%s [Last IP Used: %s]", string, Character [ playerid ] [ E_CHARACTER_IP ] );
	}

	SendClientMessage(showplayerid, COLOR_GRAD1, string );


	format ( string, sizeof ( string ), "[Playing Hours: %d] [Hand Cash: $%s] [Bank Cash: $%s] [Savings: $%s ($%s per paycheck)] [Outstanding Fines: $%s]",
		Character [ playerid ] [ E_CHARACTER_HOURS], IntegerWithDelimiter ( Character [ playerid ] [ E_CHARACTER_CASH ] ), 
		IntegerWithDelimiter(Character [ playerid ] [ E_CHARACTER_BANKCASH ]), IntegerWithDelimiter(Character [ playerid ] [ E_CHARACTER_SAVINGS ]),
		IntegerWithDelimiter( ( Character [ playerid ] [ E_CHARACTER_SAVINGS ] / 700 ) / 2 ),
		IntegerWithDelimiter(Character [ playerid ] [ E_CHARACTER_OUTSTANDING_FINES ] ) 
	) ;

	SendClientMessage(showplayerid, COLOR_GRAD0, string );

	string [ 0 ] = EOS ;

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if (  factionid ) {
		new faction_enum_id = Faction_GetEnumID(factionid ); 

		if ( faction_enum_id != INVALID_FACTION_ID ) {

		 	format ( string, sizeof ( string ), "%s", Faction [ faction_enum_id ] [ E_FACTION_NAME ]);

		}

		else format ( string, sizeof ( string ), "None");
	}

	else format ( string, sizeof ( string ), "None");

	format (string, sizeof ( string ), "[FID SQL: %d] [Faction: \"%s\"] [Faction Rank: \"%s\"] [Faction Tier: %d]",
		factionid, string, Character [ playerid ] [ E_CHARACTER_FACTIONRANK ],  Character [ playerid ] [ E_CHARACTER_FACTIONTIER ]
	);
	SendClientMessage(showplayerid, COLOR_GRAD1, string);

	string [ 0 ] = EOS ;

	switch (PlayerVar [ playerid ] [ player_hasboombox ] ) {

		case 1:	format ( string, sizeof ( string ), "Red" ) ;
		case 2:	format ( string, sizeof ( string ), "Grey" ) ;
		case 3:	format ( string, sizeof ( string ), "Black" ) ;
		default: format ( string, sizeof ( string ), "None" ) ;
	}


	format ( string, sizeof ( string ), "[Mask ID: %d] [Phone Number: %d] [Gas Can: %s] [Toolkit: %s] [Boombox: %s] [Lockpicks: %d]", 
		Character [ playerid ] [ E_CHARACTER_MASKID ], Character [ playerid ] [ E_CHARACTER_PHONE_NUMBER ],
		(PlayerVar [ playerid ] [ E_PLAYER_HAS_GASCAN ] ? ("Yes") : ("No")),
		(PlayerVar [ playerid ] [ E_PLAYER_HAS_TOOLKIT ] ? ("Yes") : ("No")),
		string,  Character [ playerid ] [ E_CHARACTER_LOCKPICK ]
	);
	SendClientMessage(showplayerid, COLOR_GRAD0, string );

	buffer[0]=EOS;
	SprayTag_GetNameByModel( Character [ playerid ] [ E_CHARACTER_SPRAYTAG_STATIC ], buffer, sizeof ( buffer ) ) ;

	string[0]=EOS;
	SprayTag_GetDynNameByModel(Character [ playerid ] [ E_CHARACTER_SPRAYTAG_DYNAMIC ], string, sizeof(string) ) ;

	format ( string, sizeof ( string), "[Static Spray-tag: %s] [Dynamic Spray-tag: %s] [Wood: %d] [Metal: %d] [Parts: %d]", 
		buffer, string,
		Character [ playerid ] [ E_CHARACTER_GD_WOOD ], Character [ playerid ] [ E_CHARACTER_GD_METAL ],
		Character [ playerid ] [ E_CHARACTER_GD_PARTS ] ) ;

	SendClientMessage(showplayerid, COLOR_GRAD1, string);

	format ( string, sizeof ( string ), "[Fear: %d] [Respect: %d] [Passable Points: %d]",
		Character [ playerid ] [ E_CHARACTER_FEAR ], Character [ playerid ] [ E_CHARACTER_RESPECT ], Character [ playerid ] [ E_CHARACTER_FnR_GIVABLE ]
	);

	SendClientMessage(showplayerid, COLOR_GRAD0, string);
}
*/

// Prints a player's statistics to a viewer. (This variant is used when Fear & Respect is
// disabled.)
static ShowPlayerStatsToPlayer(playerid, showplayerid)
{
	new string [ 512 ] ;

	format ( string, sizeof ( string ), "{[ _______ (%d) %s's statistics  _______ ]}", playerid, ReturnRPName ( playerid ) ) ;
	SendClientMessage(showplayerid, 0xE9691BFF, string ) ;

	format ( string, sizeof ( string ), "[ACCOUNT]:{DEDEDE} [Account ID: %d]{AAAAAA} [Character ID: %d]{DEDEDE} [Account: \"%s\"]{AAAAAA} [Character: \"%s\"]",

		Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], Character [ playerid ] [ E_CHARACTER_ID ],
		Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], Character [ playerid ] [ E_CHARACTER_NAME ]
	) ;
	SendClientMessage(showplayerid, 0xA37EBEFF, string);


	new year, month, day, hour, minute, second ;
	stamp2datetime(Character [ playerid ] [ E_CHARACTER_REGISTERDATE ], year, month, day, hour, minute, second, 1 ) ;


	format ( string, sizeof ( string ), "[SESSION]:{DEDEDE} [Registered: %02d/%02d/%04d at %02d:%02d:%02d]{AAAAAA} [Hours: %d]", 
		day, month, year, hour, minute, second, Character [ playerid ] [ E_CHARACTER_HOURS ] );

	if (playerid != showplayerid) {
		format ( string, sizeof ( string ), "%s {DEDEDE}[Last IP: %s]", string, Character [ playerid ] [ E_CHARACTER_IP ] );
	}

	else format ( string, sizeof ( string ), "%s {DEDEDE}[Last IP: {C6694C}Hidden{DEDEDE}]", string);

	SendClientMessage(showplayerid, 0x98D988FF, string );

	format ( string, sizeof ( string ), 
		"[FINANCIAL]:{DEDEDE} [Hand Cash: $%s]{AAAAAA} [Bank Cash: $%s]{DEDEDE} [Savings: $%s ($%s per paycheck)]",
		IntegerWithDelimiter ( Character [ playerid ] [ E_CHARACTER_CASH ] ), 
		IntegerWithDelimiter(Character [ playerid ] [ E_CHARACTER_BANKCASH ]), IntegerWithDelimiter(Character [ playerid ] [ E_CHARACTER_SAVINGS ]),
		IntegerWithDelimiter( ( Character [ playerid ] [ E_CHARACTER_SAVINGS ] / 700 ) / 2 )
	) ;

	SendClientMessage(showplayerid, 0xD39483FF, string );

	string [ 0 ] = EOS ;

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if (  factionid ) {
		new faction_enum_id = Faction_GetEnumID(factionid ); 

		if ( faction_enum_id != INVALID_FACTION_ID ) {

		 	format ( string, sizeof ( string ), "%s", Faction [ faction_enum_id ] [ E_FACTION_ABBREV ]);

		}

		else format ( string, sizeof ( string ), "None");
	}

	else format ( string, sizeof ( string ), "None");

	format (string, sizeof ( string ), "[FACTION]:{DEDEDE} [FID: %d]{AAAAAA} [Faction: \"%s\"]{DEDEDE} [Rank: \"%s\"]{AAAAAA} [Tier: %d]",
		factionid, string, Character [ playerid ] [ E_CHARACTER_FACTIONRANK ],  Character [ playerid ] [ E_CHARACTER_FACTIONTIER ]
	);
	SendClientMessage(showplayerid, 0x88D9D8FF, string);

	string [ 0 ] = EOS ;

	switch (PlayerVar [ playerid ] [ player_hasboombox ] ) {

		case 1:	format ( string, sizeof ( string ), "Red" ) ;
		case 2:	format ( string, sizeof ( string ), "Grey" ) ;
		case 3:	format ( string, sizeof ( string ), "Black" ) ;
		default: format ( string, sizeof ( string ), "None" ) ;
	}

	format ( string, sizeof ( string ), "[MISCELLANEOUS]:{DEDEDE} [Mask ID: %d]{AAAAAA} [Phone Number: %d]",
		Character [ playerid ] [ E_CHARACTER_MASKID ], Character [ playerid ] [ E_CHARACTER_PHONE_NUMBER ]
	);

	if (playerid != showplayerid && GetPlayerAdminLevel(playerid) >= ADMIN_LVL_HEAD) 
	{
		format ( string, sizeof ( string ), "%s {DEDEDE}[Email: %s]", string, Account [ playerid ] [ E_PLAYER_ACCOUNT_EMAIL ] );
	}
	if (GetPlayerAdminLevel(playerid) >= ADMIN_LVL_JUNIOR) 
	{
		format ( string, sizeof ( string ), "%s {DEDEDE}[World: %d]{AAAAAA} [Interior: %d]", string, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid) );
	}

	SendClientMessage(showplayerid, 0xD9C388FF, string );

    if (CanUseMechanicTools(playerid))
    {
        new next_thresh[32];
        new mech_level = Character[playerid][E_CHARACTER_MECHANIC_LEVEL];
        if (mech_level < MECHANIC_MAX_LEVEL)
            format(next_thresh, sizeof(next_thresh), "%d", MECHANIC_LEVEL_THRESHOLDS[mech_level + 1]);
        else
            format(next_thresh, sizeof(next_thresh), "MAX");

        format(string, sizeof(string),
            "{FF8C00}[MECHANIC]:{DEDEDE} [Level: %d/%d]{AAAAAA} [Jobs Done: %d]{DEDEDE} [Timer: %ds]{AAAAAA} [Next Level: %s jobs]",
            Character[playerid][E_CHARACTER_MECHANIC_LEVEL],
            MECHANIC_MAX_LEVEL,
            Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE],
            Mechanic_GetTimer(playerid),
            next_thresh
        );
        SendClientMessage(showplayerid, 0xFF8C00FF, string);
    }

#if defined FEATURE_FNR
	format ( string, sizeof ( string ), "{e63535}[Fear: {FFFFFF}%d{e63535}] {2D53BB}[Respect: {FFFFFF}%d{2D53BB}] {8c2bb5}[Passable Points: {FFFFFF}%d{8c2bb5}]",
		Character [ playerid ] [ E_CHARACTER_FEAR ], Character [ playerid ] [ E_CHARACTER_RESPECT ], Character [ playerid ] [ E_CHARACTER_FnR_GIVABLE ]
	);

	SendClientMessage(showplayerid, 0x47154EE4, string );
#endif
    format ( string, sizeof ( string ), "{59BCF5}[Prison Stamps: {FFFFFF}%d{59BCF5}]", Character [ playerid ] [ E_CHARACTER_PRISON_STAMPS ] );

	SendClientMessage(showplayerid, 0x47154EE4, string );

    if (Character[playerid][E_CHARACTER_ARREST_TIME] || Character[playerid][E_CHARACTER_JFL])
    {
        new cellDisplay[32];

        if (Character[playerid][E_CHARACTER_ARREST_CELL][0] != EOS)
            format(cellDisplay, sizeof(cellDisplay), "Cell %s", Character[playerid][E_CHARACTER_ARREST_CELL]);
        else if (Character[playerid][E_CHARACTER_JFL])
            format(cellDisplay, sizeof(cellDisplay), "Cell %s", Character[playerid][E_CHARACTER_ARREST_CELL]);
        else
            format(cellDisplay, sizeof(cellDisplay), "On-Site");
            
        if (Character[playerid][E_CHARACTER_ARREST_TIME] != ARREST_TIME_AWAITING_RELEASE)
            format(string, sizeof(string), "[ARREST]:{DEDEDE} [Time Remaining: %d min]{AAAAAA} [Location: %s]",
                Character[playerid][E_CHARACTER_ARREST_TIME] / 60, cellDisplay);
        if (Character[playerid][E_CHARACTER_ARREST_TIME] == ARREST_TIME_AWAITING_RELEASE && !Character[playerid][E_CHARACTER_JFL])
            format(string, sizeof(string), "[ARREST]:{DEDEDE} [Status: Awaiting Release]{AAAAAA} [Location: %s]", cellDisplay);
        else
            format(string, sizeof(string), "[ARREST]: {A71D1D}LIFE SENTENCE{DBD8D8} [Location: %s]", cellDisplay);

        SendClientMessage(showplayerid, 0xFF6B6BFF, string);
    }
	
}

// /stats - shows your own statistics.
CMD:stats(playerid, params[]) 
{
	ShowPlayerStatsToPlayer(playerid, playerid);
	ZMsg_SendClientMessage(playerid, 0x297183FF, "Related commands:{DEDEDE} /mycars, /myproperties, /myguns, /mydrugs, /myslots, /myattributes");

	return true;
}


// /checkstats [player] - (staff) shows another player's statistics.
CMD:checkstats(playerid, params[]) {

	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");

	new targetid;

	if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/checkstats [player]");

	if (!IsPlayerConnected(targetid))
		return SendClientMessage(playerid, -1, "Target isn't connected.");

	ShowPlayerStatsToPlayer(targetid, playerid);

	return true ;
}


#if defined FEATURE_FNR

/////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------- FEAR AND RESPECT SYSTEM ------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

// Fear & Respect: checks (in the database) whether a player can give points to another, based on
// a cooldown.
stock bool:CanGiveFnRToPlayer(playerid, targetid) {
    new query[256];
    new giverCharID = Character[playerid][E_CHARACTER_ID]; 
    new targetCharID = Character[targetid][E_CHARACTER_ID];
    
    mysql_format(mysql, query, sizeof(query), 
        "SELECT UNIX_TIMESTAMP(last_given) as last_time FROM fnr_cooldowns WHERE giver_id = %d AND target_id = %d", 
        giverCharID, targetCharID
    );
    
    new Cache:result = mysql_query(mysql, query);
    new bool:canGive = true;
    
    if(cache_num_rows() > 0) {
        new lastGiveTime;
        cache_get_value_name_int(0, "last_time", lastGiveTime);
        
        new currentTime = gettime();
        new cooldownTime = 7200; // 2 hours in seconds
        
        if(currentTime - lastGiveTime < cooldownTime) {
            canGive = false;
        }
    }
    
    cache_delete(result);
    return canGive;
}

// Fear & Respect: returns the seconds before a player can give points to the same target again.
stock GetFnRCooldownRemaining(playerid, targetid) {
    new query[256];
    new giverCharID = Character[playerid][E_CHARACTER_ID];
    new targetCharID = Character[targetid][E_CHARACTER_ID];
    
    mysql_format(mysql, query, sizeof(query), 
        "SELECT UNIX_TIMESTAMP(last_given) as last_time FROM fnr_cooldowns WHERE giver_id = %d AND target_id = %d", 
        giverCharID, targetCharID
    );
    
    new Cache:result = mysql_query(mysql, query);
    new remaining = 0;
    
    if(cache_num_rows() > 0) {
        new lastGiveTime;
        cache_get_value_name_int(0, "last_time", lastGiveTime);
        
        new currentTime = gettime();
        new cooldownTime = 7200;  
        
        remaining = cooldownTime - (currentTime - lastGiveTime);
        if(remaining < 0) remaining = 0;
    }
    
    cache_delete(result);
    return remaining;
}

// Fear & Respect: records that a player gave points to a target, starting the cooldown.
stock UpdateFnRCooldown(playerid, targetid) {
    new query[256]; 
    new giverCharID = Character[playerid][E_CHARACTER_ID];
    new targetCharID = Character[targetid][E_CHARACTER_ID];
    
    mysql_format(mysql, query, sizeof(query), 
        "INSERT INTO fnr_cooldowns (giver_id, target_id, last_given) VALUES (%d, %d, NOW()) \
        ON DUPLICATE KEY UPDATE last_given = NOW()", 
        giverCharID, targetCharID
    );
    
    mysql_tquery(mysql, query);
}


// Adds respect points to a player.
stock AddPlayerRespect(playerid, amount)
{
    new query[256];
    
    if(!IsPlayerConnected(playerid))
        return 0;
    
    if(amount == 0)
        return 0;
    
    new oldlevel = GetPlayerFnRLevel(playerid);
    
    Character[playerid][E_CHARACTER_RESPECT] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_respect = %d WHERE player_id = %d", 
        Character[playerid][E_CHARACTER_RESPECT], 
        Character[playerid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    new text[32];
    if(amount > 0)
        format(text, sizeof(text), "~b~+%d RESPECT", amount);
    else
        format(text, sizeof(text), "~b~%d RESPECT", amount);
    GameTextForPlayer(playerid, text, 3000, 13);
    
    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("%s has %s %d respect points.", 
        ReturnPlayerName(playerid), (amount > 0) ? ("gained") : ("lost"), abs(amount))
    );
    CheckFnRLevelUp(playerid, oldlevel);
    
    return 1;
}

// Adds fear points to a player.
stock AddPlayerFear(playerid, amount)
{
    new query[256];
    
    if(!IsPlayerConnected(playerid))
        return 0;
    
    if(amount == 0)
        return 0;
    
    new oldlevel = GetPlayerFnRLevel(playerid);
    
    Character[playerid][E_CHARACTER_FEAR] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fear = %d WHERE player_id = %d", 
        Character[playerid][E_CHARACTER_FEAR], 
        Character[playerid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    new text[32];
    if(amount > 0)
        format(text, sizeof(text), "~r~+%d FEAR", amount);
    else
        format(text, sizeof(text), "~r~%d FEAR", amount);
    GameTextForPlayer(playerid, text, 3000, 13);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("%s has %s %d fear points.", 
        ReturnPlayerName(playerid), (amount > 0) ? ("gained") : ("lost"), abs(amount))
    );
    CheckFnRLevelUp(playerid, oldlevel);
    
    return 1;
}

#endif // FEATURE_FNR

forward StopPlayerTimedSound(playerid);
// Plays a sound for a player for a fixed time.
stock PlayPlayerTimedSound(playerid, soundid, duration)
{
    PlayerPlaySound(playerid, soundid, 0, 0, 0);
    SetTimerEx("StopPlayerTimedSound", duration, false, "d", playerid);
}

// Timer callback that stops the timed sound.
public StopPlayerTimedSound(playerid)
{
    PlayerPlaySound(playerid, 0, 0, 0, 0);
}

#if defined FEATURE_FNR

forward OnPlayerReceiveFnRGivable(playerid, amount, const source[]);
forward OnPlayerGiveFearRespect(playerid, targetid, type, amount);

// Gives a player Fear & Respect points they can later give to others.
stock GiveFnRPoints(playerid, amount, const source[] = "Unknown", bool:notify = true)
{
    new string[256];
    new query[256];
    
    if(!IsPlayerConnected(playerid))
        return 0;
    
    if(amount <= 0)
        return 0;
    
    if(CallLocalFunction("OnPlayerReceiveFnRGivable", "dds", playerid, amount, source) == 0)
        return 0;
    
    Character[playerid][E_CHARACTER_FnR_GIVABLE] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fnr_givable = %d WHERE player_id = %d", 
        Character[playerid][E_CHARACTER_FnR_GIVABLE], 
        Character[playerid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    if(notify)
    {
        format(string, sizeof(string), "~p~+%d~w~ FnR Points", amount);
        GameTextForPlayer(playerid, string, 3000, 17);
        
        // format(string, sizeof(string), "{90EE90}You have received {FFFFFF}%d {90EE90}FnR Points from: {FFFFFF}%s", 
        //     amount, source);
        // SendClientMessage(playerid, COLOR_WHITE, string);
        
        PlayerPlaySound(playerid, 1083, 0, 0, 0);
    }
    
    // format(string, sizeof(string), "[FnR] %s received %d Points from: %s (Total: %d)", 
    //     ReturnPlayerName(playerid), 
    //     amount, 
    //     source,
    //     Character[playerid][E_CHARACTER_FnR_GIVABLE]
    // );
    // print(string);
    
    return 1;
}

// A player gives respect points to another player.
stock GivePlayerRespect(playerid, targetid, amount)
{
    //new string[128];
    new query[256];
    
    if(!IsPlayerConnected(targetid))
        return 0;
    
    if(amount <= 0)
        return 0;
    
    if(Character[playerid][E_CHARACTER_FnR_GIVABLE] < amount)
        return 0;
    
    if(CallLocalFunction("OnPlayerGiveFearRespect", "dddd", playerid, targetid, 0, amount) == 0)
        return 0;
    
    new oldlevel = GetPlayerFnRLevel(targetid);
    
    Character[playerid][E_CHARACTER_FnR_GIVABLE] -= amount;
    Character[targetid][E_CHARACTER_RESPECT] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fnr_givable = %d WHERE player_id = %d", 
        Character[playerid][E_CHARACTER_FnR_GIVABLE], 
        Character[playerid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_respect = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_RESPECT], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    ProxDetectorEx(playerid, 30.0, COLOR_ACTION, "**", 
        sprintf("has given %d respect points to %s.", amount, ReturnMixedName(targetid))
    );

    GameTextForPlayer(targetid, "You have been given respect, you gangsta!", 6500, 16);
    PlayerPlaySound(targetid, 1083, 0, 0, 0);
    
    CheckFnRLevelUp(targetid, oldlevel);
    
    /*
    ShowPlayerSubtitle(targetid, 
        sprintf("You have got ~b~+%d Respect points~w~ from ~r~%s~w~.", amount, ReturnPlayerName(playerid)), 
        .showtime=5000
    );
    */
    return 1;
}

// A player gives fear points to another player.
stock GivePlayerFear(playerid, targetid, amount)
{
    //new string[128];
    new query[256];
    
    if(!IsPlayerConnected(targetid))
        return 0;
    
    if(amount <= 0)
        return 0;
    
    if(Character[playerid][E_CHARACTER_FnR_GIVABLE] < amount)
        return 0;
    
    if(CallLocalFunction("OnPlayerGiveFearRespect", "dddd", playerid, targetid, 1, amount) == 0)
        return 0;
    
    new oldlevel = GetPlayerFnRLevel(targetid);
    
    Character[playerid][E_CHARACTER_FnR_GIVABLE] -= amount;
    Character[targetid][E_CHARACTER_FEAR] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fnr_givable = %d WHERE player_id = %d", 
        Character[playerid][E_CHARACTER_FnR_GIVABLE], 
        Character[playerid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fear = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_FEAR], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    ProxDetectorEx(playerid, 30.0, COLOR_ACTION, "**", 
        sprintf("has given %d fear points to %s.", amount, ReturnMixedName(targetid))
    );
    
    GameTextForPlayer(targetid, "You have been given fear, you gangsta!", 6500, 16);
    PlayerPlaySound(targetid, 1083, 0, 0, 0);
    
    CheckFnRLevelUp(targetid, oldlevel);
    
    /*
    ShowPlayerSubtitle(targetid, 
        sprintf("You have got ~r~+%d Fear points~w~ from ~b~%s~w~.", amount, ReturnPlayerName(playerid)), 
        .showtime=5000
    );
    */
    return 1;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------- LEVEL SYSTEM FUNCTIONS ------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

static const FnR_LevelThresholds[] = {
    0,     // Level 1  - Street Rookie
    100,   // Level 2  - Block Hustler
    300,   // Level 3  - Hood Soldier
    700,   // Level 4  - Street Captain
    2000,  // Level 5  - Block Lieutenant
    3000,  // Level 6  - Hood Commander
    4000,  // Level 7  - Street Veteran
    5000,  // Level 8  - Block Enforcer
    6000,  // Level 9  - Hood Legend
    7000,  // Level 10 - Street Boss
    8000   // Level 11 - Kingpin (MAX)
};

#define MAX_FnR_LEVEL 11

forward OnPlayerFnRLevelUp(playerid, newlevel, oldlevel);
forward OnPlayerFnRLevelCheck(playerid, &level, totalpoints);


// Returns respect + fear points of a player.
stock GetPlayerTotalFnRPoints(playerid)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    return Character[playerid][E_CHARACTER_RESPECT] + Character[playerid][E_CHARACTER_FEAR];
}

// Returns the Fear & Respect level of a player.
stock GetPlayerFnRLevel(playerid)
{
    if(!IsPlayerConnected(playerid))
        return 0;
    
    new totalpoints = GetPlayerTotalFnRPoints(playerid);
    new level = 1;
    
    for(new i = 0; i < sizeof(FnR_LevelThresholds); i++)
    {
        if(totalpoints >= FnR_LevelThresholds[i])
            level = i + 1;
        else
            break;
    }
    
    if(level > MAX_FnR_LEVEL)
        level = MAX_FnR_LEVEL;
    
    CallLocalFunction("OnPlayerFnRLevelCheck", "ddd", playerid, level, totalpoints);
    
    return level;
}

// Returns how many points the player has and how many are needed for the next level.
stock GetFnRProgress(playerid, &current, &required)
{
    new level = GetPlayerFnRLevel(playerid);
    new totalpoints = GetPlayerTotalFnRPoints(playerid);
    
    if(level >= MAX_FnR_LEVEL)
    {
        current = totalpoints;
        required = FnR_LevelThresholds[MAX_FnR_LEVEL - 1];
        return 0;
    }
    
    current = totalpoints - FnR_LevelThresholds[level - 1];
    required = FnR_LevelThresholds[level] - FnR_LevelThresholds[level - 1];
    
    return 1;
}

// Checks if a player has gone up a level and announces it.
stock CheckFnRLevelUp(playerid, oldlevel)
{
    if(!IsPlayerConnected(playerid)) return 0;
    
    new newlevel = GetPlayerFnRLevel(playerid);
    
    if(newlevel > oldlevel)
    {
        new string[128];
        new gametext[256];
        
        switch(newlevel)
        {
            case 2: gametext = "Respect - Upgraded.~n~You're making a name for yourself in these streets!";
            case 3: gametext = "Respect - Upgraded.~n~You can now purchase Uzis from gun dealers.";
            case 4: gametext = "Respect - Upgraded.~n~You're coming up in the world playa! You're well known in these cold streets.";
            case 5: gametext = "Respect - Upgraded.~n~The streets know your name!";
            case 6: gametext = "Respect - Upgraded.~n~You're an OG out here! Keep building that reputation.";
            case 7: gametext = "Respect - Upgraded.~n~Your street credit speaks for itself!";
            case 8: gametext = "Respect - Upgraded.~n~You're a legend in these streets!";
            case 9: gametext = "Respect - Upgraded.~n~The whole city knows your name!";
            case 10: gametext = "Respect - Upgraded.~n~You're running these streets now, boss!";
            case 11: gametext = "Respect - Upgraded.~n~Kingpin status achieved! The entire hood bows to you!";
            default: 
            {
                format(gametext, sizeof(gametext), "Respect - Upgraded.~n~You are now a %s.", GetFnRLevelName(newlevel));
            }
        }
        
        GameTextForPlayer(playerid, gametext, 6500, 16);
        GameTextForPlayer(playerid, "~w~RESPECT+", 6500, 0);
        PlayPlayerTimedSound(playerid, 183, 6500);
        
        format(string, sizeof(string), "{FFD700}» {FFFFFF}You have reached {FFD700}Fear & Respect Level %d{FFFFFF}!", newlevel);
        SendClientMessage(playerid, -1, string);
        
        CallLocalFunction("OnPlayerFnRLevelUp", "ddd", playerid, newlevel, oldlevel);
        
        return 1;
    }
    
    return 0;
}

// Returns the title for a Fear & Respect level (Street Rookie, Block Hustler...).
stock GetFnRLevelName(level)
{
    new levelname[32];
    
    switch(level)
    {
        case 1: levelname = "Street Rookie";
        case 2: levelname = "Block Hustler";
        case 3: levelname = "Hood Soldier";
        case 4: levelname = "Street Captain";
        case 5: levelname = "Block Lieutenant";
        case 6: levelname = "Hood Commander";
        case 7: levelname = "Street Veteran";
        case 8: levelname = "Block Enforcer";
        case 9: levelname = "Hood Legend";
        case 10: levelname = "Street Boss";
        case 11: levelname = "Kingpin";
        default: levelname = "Unknown";
    }
    
    return levelname;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------ COMMANDS ----------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

// /giverespect [player] [amount] - gives respect points.
CMD:giverespect(playerid, params[]) {
    new targetid, amount;
    new string[128];
    
    if(sscanf(params, "ud", targetid, amount))
    {
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /giverespect [playerid/name] [amount]");
    }
    
    if(!IsPlayerConnected(targetid))
    {
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    }
    
    if(playerid == targetid)
    {
        return SendClientMessage(playerid, COLOR_GREY, "You cannot give respect to yourself.");
    }
    
    if(!IsPlayerNearPlayer(playerid, targetid, 5.0))
        return SendClientMessage(playerid, COLOR_GREY, "You must be close to the target to give them respect.");
    
    if(!CanGiveFnRToPlayer(playerid, targetid)) {
        new timeRemaining = GetFnRCooldownRemaining(playerid, targetid);
        new timeString[32];
        FormatCooldownTime(timeRemaining, timeString, sizeof(timeString));
        format(string, sizeof(string), "{908E8E}You can give respect to this player again in: {703879}%s", timeString);
        return SendClientMessage(playerid, COLOR_GREY, string);
    }
    
    if(amount <= 0) {
        return SendClientMessage(playerid, COLOR_GREY, "Amount must be greater than 0.");
    }
    
    if(Character[playerid][E_CHARACTER_FnR_GIVABLE] < amount) {
        format(string, sizeof(string), "{908E8E}You only have {703879}%d {908E8E}respect points to give.", Character[playerid][E_CHARACTER_FnR_GIVABLE]);
        return SendClientMessage(playerid, COLOR_GREY, string);
    }
    
    if(!GivePlayerRespect(playerid, targetid, amount))
        return SendClientMessage(playerid, COLOR_GREY, "Failed to give respect points.");
    
    UpdateFnRCooldown(playerid, targetid);
    
    return 1;
}

// /givefear [player] [amount] - gives fear points.
CMD:givefear(playerid, params[]) {
    new targetid, amount;
    new string[128];
    
    if(sscanf(params, "ud", targetid, amount)) {
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /givefear [playerid/name] [amount]");
    }
    
    if(!IsPlayerConnected(targetid)) {
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    }
    
    if(playerid == targetid) {
        return SendClientMessage(playerid, COLOR_GREY, "You cannot give fear to yourself.");
    }
    
    if(!IsPlayerNearPlayer(playerid, targetid, 5.0)) {
        return SendClientMessage(playerid, COLOR_GREY, "You must be close to the target to give them fear.");
    }
    
    if(!CanGiveFnRToPlayer(playerid, targetid)) {
        new timeRemaining = GetFnRCooldownRemaining(playerid, targetid);
        new timeString[32];
        FormatCooldownTime(timeRemaining, timeString, sizeof(timeString));
        format(string, sizeof(string), "{908E8E}You can give fear to this player again in: {703879}%s", timeString);
        return SendClientMessage(playerid, COLOR_GREY, string);
    }
    
    if(amount <= 0) {
        return SendClientMessage(playerid, COLOR_GREY, "Amount must be greater than 0.");
    }
    
    if(Character[playerid][E_CHARACTER_FnR_GIVABLE] < amount) {
        format(string, sizeof(string), "{908E8E}You only have {703879}%d {908E8E}fear points to give.", Character[playerid][E_CHARACTER_FnR_GIVABLE]);
        return SendClientMessage(playerid, COLOR_WHITE, string);
    }
    
    if(!GivePlayerFear(playerid, targetid, amount)) {
        return SendClientMessage(playerid, COLOR_GREY, "Failed to give fear points.");
    }
    
    UpdateFnRCooldown(playerid, targetid);
    
    return 1;
}

// /fnrstats [player] - shows Fear & Respect statistics.
CMD:fnrstats(playerid, params[])
{
    new targetid = playerid;
    
    if(sscanf(params, "U(-1)", targetid))
        targetid = playerid;
    
    if(targetid == -1)
        targetid = playerid;
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    new level = GetPlayerFnRLevel(targetid);
    new totalpoints = GetPlayerTotalFnRPoints(targetid);
    new current, required;
    GetFnRProgress(targetid, current, required);
    
    new string[1024];
    
    format(string, sizeof(string),
        "{FFFFFF}Player: {BF1C0D}%s\n\n\
        {FFD700}Level: {FFFFFF}%d {888888}(%s)\n\
        {9D4EDD}Total Points: {FFFFFF}%d\n\
        {4A90E2}Respect: {FFFFFF}%d\n\
        {E74C3C}Fear: {FFFFFF}%d\n\
        {90EE90}Available Points: {FFFFFF}%d\n\n",
        ReturnPlayerName(targetid),
        level, GetFnRLevelName(level),
        totalpoints,
        Character[targetid][E_CHARACTER_RESPECT],
        Character[targetid][E_CHARACTER_FEAR],
        Character[targetid][E_CHARACTER_FnR_GIVABLE]
    );
    
    if(level < MAX_FnR_LEVEL)
    {
        format(string, sizeof(string), "%s{BF1C0D}Progress to Next Level:\n{FFFFFF}Level %d: {FFD700}%d{FFFFFF}/{FFD700}%d", 
            string, level + 1, current, required);
    }
    else
    {
        format(string, sizeof(string), "%s{71165A}STATUS: MAX LEVEL REACHED!", string);
    }
    
    inline DlgFnRStats(pid, dialogid, response, listitem, string:inputtext[]) 
    {
        #pragma unused pid, dialogid, inputtext, listitem, response
    }
    
    Dialog_ShowCallback(playerid, using inline DlgFnRStats, DIALOG_STYLE_MSGBOX, 
        "{BF1C0D}Fear & Respect Statistics", string, "Close", "");
    
    return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------- ADMIN/TEST COMMANDS ---------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

// /spoofrespect [player] [amount] - (developer) sets respect for testing.
CMD:spoofrespect(playerid, params[])
{
    new targetid, amount;
    new string[128];
    
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
        return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
    
    
    if(sscanf(params, "ud", targetid, amount))
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /spoofrespect [playerid/name] [amount]");
    
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    if(amount <= 0)
        return SendClientMessage(playerid, COLOR_GREY, "Amount must be greater than 0.");
    
    
    new oldlevel = GetPlayerFnRLevel(targetid);
    new query[256];
    Character[targetid][E_CHARACTER_RESPECT] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_respect = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_RESPECT], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    format(string, sizeof(string), "You have given %d respect points to %s.", 
        amount, ReturnPlayerName(targetid));
    SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
    
    GameTextForPlayer(targetid, "You have been given respect, you gangsta!", 6500, 16);
    PlayerPlaySound(targetid, 1083, 0, 0, 0);
    
    format(string, sizeof(string), "Admin %s has given you %d respect points.", 
        ReturnPlayerName(playerid), amount);
    SendClientMessage(targetid, COLOR_LIGHTBLUE, string);
    
    format(string, sizeof(string), "[ADMIN] %s used /spoofrespect on %s (amount: %d)", 
        ReturnPlayerName(playerid), ReturnPlayerName(targetid), amount);
    print(string);

    if (AnimationCheck(targetid, true))
    {
        if (random(2) == 0)
            ApplyAnimation(targetid, "GHANDS", "gsign5LH", 4.1, 0, 0, 0, 0, 0);
        else
            ApplyAnimation(targetid, "GANGS", "prtial_hndshk_01", 4.1, 0, 0, 0, 0, 0);
    }
    
    CheckFnRLevelUp(targetid, oldlevel);
    
    return 1;
}

// /spooffear [player] [amount] - (developer) sets fear for testing.
CMD:spooffear(playerid, params[])
{
    new targetid, amount;
    new string[128];
    
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
        return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
    
    
    if(sscanf(params, "ud", targetid, amount))
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /spooffear [playerid/name] [amount]");
    
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    
    if(amount <= 0)
        return SendClientMessage(playerid, COLOR_GREY, "Amount must be greater than 0.");
    
    
    new oldlevel = GetPlayerFnRLevel(targetid);
    new query[256];
    Character[targetid][E_CHARACTER_FEAR] += amount;
    
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_fear = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_FEAR], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    format(string, sizeof(string), "You have given %d fear points to %s.", 
        amount, ReturnPlayerName(targetid));
    SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
    
    GameTextForPlayer(targetid, "You have been given fear, you gangsta!", 6500, 16);
    PlayerPlaySound(targetid, 1083, 0, 0, 0);
    
    format(string, sizeof(string), "Admin %s has given you %d fear points.", 
        ReturnPlayerName(playerid), amount);
    SendClientMessage(targetid, COLOR_LIGHTBLUE, string);
    
    format(string, sizeof(string), "[ADMIN] %s used /spooffear on %s (amount: %d)", 
        ReturnPlayerName(playerid), ReturnPlayerName(targetid), amount);
    print(string);

    if (AnimationCheck(targetid, true))
    {
        if (random(2) == 0)
            ApplyAnimation(targetid, "GHANDS", "gsign5LH", 4.1, 0, 0, 0, 0, 0);
        else
            ApplyAnimation(targetid, "GANGS", "prtial_hndshk_01", 4.1, 0, 0, 0, 0, 0);
    }
    
    CheckFnRLevelUp(targetid, oldlevel);
    
    return 1;
}

// /givefnrpoints [player] [amount] [reason] - (staff) awards givable points.
CMD:givefnrpoints(playerid, params[])
{
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
        return SendClientMessage(playerid, COLOR_GREY, "Insufficient permissions.");
    
    new targetid, amount, reason[64];
    if(sscanf(params, "uds[64]", targetid, amount, reason))
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /givefnrpoints [playerid] [amount] [reason]");
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    new source[128];
    format(source, sizeof(source), "Admin Reward: %s", reason);
    GiveFnRPoints(targetid, amount, source);
    
    new string[128];
    format(string, sizeof(string), "You gave %s %d FnR Points.", ReturnPlayerName(targetid), amount);
    SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
    
    return 1;
}

// /setfnrlevel [player] [level] - (developer) sets a player's level.
CMD:setfnrlevel(playerid, params[])
{
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
        return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
    
    new targetid, targetlevel;
    new string[128];
    
    if(sscanf(params, "ud", targetid, targetlevel))
        return SendClientMessage(playerid, COLOR_GREY, "USAGE: /setfnrlevel [playerid/name] [level 1-11]");
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    if(targetlevel < 1 || targetlevel > MAX_FnR_LEVEL)
    {
        format(string, sizeof(string), "Level must be between 1 and %d.", MAX_FnR_LEVEL);
        return SendClientMessage(playerid, COLOR_GREY, string);
    }
    
    new requiredpoints = FnR_LevelThresholds[targetlevel - 1];
    new currentpoints = GetPlayerTotalFnRPoints(targetid);
    new difference = requiredpoints - currentpoints;
    
    if(difference > 0)
    {
        Character[targetid][E_CHARACTER_RESPECT] += difference;
    }
    else if(difference < 0)
    {
        Character[targetid][E_CHARACTER_RESPECT] += difference;
        if(Character[targetid][E_CHARACTER_RESPECT] < 0)
            Character[targetid][E_CHARACTER_RESPECT] = 0;
    }
    
    new query[256];
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_respect = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_RESPECT], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    new newlevel = GetPlayerFnRLevel(targetid);
    
    format(string, sizeof(string), "You have set %s's FnR level to %d (%s).", 
        ReturnPlayerName(targetid), newlevel, GetFnRLevelName(newlevel));
    SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
    
    format(string, sizeof(string), "Respect - Upgraded.~n~You are now a %s.", GetFnRLevelName(newlevel));
    GameTextForPlayer(targetid, string, 6500, 16);
    PlayPlayerTimedSound(targetid, 183, 6500);
    
    format(string, sizeof(string), "{AE3D3B}» {FFFFFF}Your Fear & Respect level has been set to {242898}%d {FFFFFF}by an admin!", newlevel);
    SendClientMessage(targetid, -1, string);
    
    format(string, sizeof(string), "[ADMIN] %s set %s's FnR level to %d", 
        ReturnPlayerName(playerid), ReturnPlayerName(targetid), newlevel);
    print(string);
    
    return 1;
}

// /testlevelup [player] - (developer) tests the level-up notification.
CMD:testlevelup(playerid, params[])
{
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
        return SendClientMessage(playerid, COLOR_GREY, "You are not authorized to use this command.");
    
    new targetid;
    
    if(sscanf(params, "u", targetid))
        targetid = playerid;
    
    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_GREY, "Player not connected.");
    
    new currentlevel = GetPlayerFnRLevel(targetid);
    
    if(currentlevel >= MAX_FnR_LEVEL)
        return SendClientMessage(playerid, COLOR_GREY, "Target is already at max level.");
    
    new currentpoints = GetPlayerTotalFnRPoints(targetid);
    new requiredpoints = FnR_LevelThresholds[currentlevel];
    new pointsneeded = requiredpoints - currentpoints + 1;
    
    Character[targetid][E_CHARACTER_RESPECT] += pointsneeded;
    
    new query[256];
    mysql_format(mysql, query, sizeof(query), 
        "UPDATE characters SET player_respect = %d WHERE player_id = %d", 
        Character[targetid][E_CHARACTER_RESPECT], 
        Character[targetid][E_CHARACTER_ID]
    );
    mysql_tquery(mysql, query);
    
    CheckFnRLevelUp(targetid, currentlevel);
    
    new string[128];
    format(string, sizeof(string), "Triggered level up for %s (Level %d -> %d)", 
        ReturnPlayerName(targetid), currentlevel, GetPlayerFnRLevel(targetid));
    SendClientMessage(playerid, COLOR_LIGHTBLUE, string);
    
    return 1;
}

/////////////////////////////////////////////////////////////////////////////////////////////
// -------------------------------- CALLBACK HOOKS --------------------------------------- //
/////////////////////////////////////////////////////////////////////////////////////////////

new LastFnRTarget[MAX_PLAYERS];
new LastFnRTime[MAX_PLAYERS];

// Called when a player gives Fear & Respect points (logging hook).
public OnPlayerGiveFearRespect(playerid, targetid, type, amount)
{
    // type: 0 = respect, 1 = fear
    
    /*
    new logstring[128];
    format(logstring, sizeof(logstring), "[FnR] %s gave %d %s points to %s", 
        ReturnPlayerName(playerid), 
        amount, 
        (type == 0) ? ("respect") : ("fear"),
        ReturnPlayerName(targetid)
    );
    print(logstring);
    */

    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("%s gave %d %s points to %s", 
        ReturnPlayerName(playerid),
        amount, 
        (type == 0) ? ("respect") : ("fear"),
        ReturnPlayerName(targetid))
    );

    
    if(LastFnRTarget[playerid] == targetid)
    {
        new elapsed = GetTickCount() - LastFnRTime[playerid];
        if(elapsed < 300000) // 5min
        {
            new remaining = (300000 - elapsed) / 1000;
            new string[128];
            format(string, sizeof(string), "You must wait %d seconds before giving to %s again.", 
                remaining, ReturnPlayerName(targetid));
            SendClientMessage(playerid, COLOR_GREY, string);
            return 0;
        }
    }
    
    LastFnRTarget[playerid] = targetid;
    LastFnRTime[playerid] = GetTickCount();

    if (AnimationCheck(targetid, true))
    {
        if (random(2) == 0)
            ApplyAnimation(targetid, "GHANDS", "gsign5LH", 4.1, 0, 0, 0, 0, 0);
        else
            ApplyAnimation(targetid, "GANGS", "prtial_hndshk_01", 4.1, 0, 0, 0, 0, 0);
    }
    
    return 1; 
}

// Called when a player receives givable Fear & Respect points.
public OnPlayerReceiveFnRGivable(playerid, amount, const source[])
{
    // COULD CAP daily earnings in the future
    // if(DailyFnRGivable[playerid] + amount > 100)
    // {
    //     SendClientMessage(playerid, COLOR_ORANGE, "You've reached your daily FnR Points limit.");
    //     return 0;
    // }
    // DailyFnRGivable[playerid] += amount;
    
    // PlayerStats[playerid][TotalFnRGivableEarned] += amount;
    
    return 1;
}

// Called when a player levels up in Fear & Respect.
public OnPlayerFnRLevelUp(playerid, newlevel, oldlevel)
{
    // to unlock perks
    
    new string[128];
    format(string, sizeof(string), "[FnR] %s leveled up from %d to %d (%s)", 
        ReturnPlayerName(playerid), oldlevel, newlevel, GetFnRLevelName(newlevel));
    print(string);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("%s leveled up from %d to %d (%s)", 
        ReturnPlayerName(playerid), oldlevel, newlevel, GetFnRLevelName(newlevel))
    );
    
    switch(newlevel)
    {
        case 2:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» Level 2! Keep grinding, the streets are watching.");
        }
        case 3:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» Level 3! You're making moves out here.");
        }
        case 5:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» Level 5! Halfway there, don't stop now.");
        }
        case 7:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» Level 7! The block knows your name.");
        }
        case 10:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» Level 10! You run these streets now.");
        }
        case 11:
        {
            SendClientMessage(playerid, COLOR_GOLD, "» MAX LEVEL! You are now a KINGPIN. The city is yours.");
        }
    }
    
    // - Unlock weapons
    // - Increase stats
    // - Give rewards
    
    return 1;
}

// Hook point to adjust a player's Fear & Respect level.
public OnPlayerFnRLevelCheck(playerid, &level, totalpoints)
{
    // this hook allows external scripts to modify level calculation
    // you could add bonus levels from VIP status or whatnot
    
    // EX: VIP players get +1 level bonus
    // if(PlayerInfo[playerid][pVIP] > 0 && level < MAX_FnR_LEVEL)
    // {
    //     level += 1;
    // }
    
    return 1;
}

#else // FEATURE_FNR

// Fear & Respect is disabled. These stubs keep existing callers (jobs, robbery, minigames,
// graffiti) compiling and make them no-ops. Define FEATURE_FNR in config/header.pwn to restore it.
stock GiveFnRPoints(playerid, amount, const source[] = "Unknown", bool:notify = true)
{
    #pragma unused playerid, amount, source, notify
    return 0;
}

// Stub used when Fear & Respect is disabled: does nothing.
stock AddPlayerRespect(playerid, amount)
{
    #pragma unused playerid, amount
    return 0;
}

// Stub used when Fear & Respect is disabled: does nothing.
stock AddPlayerFear(playerid, amount)
{
    #pragma unused playerid, amount
    return 0;
}

// Stub used when Fear & Respect is disabled: always returns level 1.
stock GetPlayerFnRLevel(playerid)
{
    #pragma unused playerid
    return 1;
}

#endif // FEATURE_FNR
