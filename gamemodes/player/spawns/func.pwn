// ============================================================================
// File: player/spawns/func.pwn
// New-character spawning: the starter message dialog, spawn area selection and skin menu.
// ============================================================================

new Player_LastSpawnPage[MAX_PLAYERS];

// Shows the skin choice menu for a new character.
Player_ShowSkinMenu(playerid ) { 

	new Player_RaceSelection, Player_GenderSelection ;

	inline RaceSelection(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if ( response ) {

			Player_RaceSelection = listitem ;

			inline GenderSelection(pidx, dialogidx, responsex, listitemx, string:inputtextx[]) {
				#pragma unused pidx, dialogidx, inputtextx

				if ( responsex) {

					Player_GenderSelection = listitemx ; 

					Player_SetupSpawnVariables(playerid, Player_RaceSelection, Player_GenderSelection );
					return true ;
				}
			}


   			Dialog_ShowCallback ( playerid, using inline GenderSelection, DIALOG_STYLE_LIST, "Select your character's sex", "Male\nFemale", "Continue" );
		}
	}

   	Dialog_ShowCallback ( playerid, using inline RaceSelection, DIALOG_STYLE_LIST, "Select your character's race", "Black\nLatino\nWhite\nAsian", "Continue" );

   	return true ;
}

// Chooses default starter skins from the character's race and gender.
Player_SetupSpawnVariables(playerid, race, gender) {

	new skinid ;

	new skins_male_black [ ] [ ] = {
		7, 14, 19, 20, 21, 22, 24, 25, 28, 66, 67, 136, 142, 143, 144, 176, 180, 182, 183, 262
	} ;

	new skins_male_latin [ ] [ ] = {
		30, 44, 47, 48, 50, 58, 179, 184, 241, 242, 273
	} ;

	new skins_male_white [ ] [ ] = {
		8, 27, 29, 72, 73, 98, 95, 101, 177, 188, 202, 206, 217, 240, 250, 258, 259, 261
	} ;

	new skins_male_asian [ ] [ ] = {
		59, 60, 120, 186, 187, 227, 228, 229 
	} ;

	new skins_female_black [ ] [ ] = {
		9, 13, 65, 69, 148, 190, 195, 245
	} ;
	new skins_female_latin [ ] [ ] = {
		12, 40, 41, 214, 216
	} ;

	new skins_female_white [ ] [ ] = {
		55, 56, 91, 93, 150, 191, 192, 211, 226, 233
	} ;
	new skins_female_asian [ ] [ ] = {
		169, 193, 225, 224, 263
	};

	switch ( race ) {

		case 0: { // SKIN_RACE_BLACK ;

			if ( ! gender ) {

				skinid = skins_male_black [ random ( sizeof ( skins_male_black ) ) ] [ 0 ] ;
			}

			else skinid = skins_female_black [ random ( sizeof ( skins_female_black ) ) ] [ 0 ] ;
		}

		case 1: { // SKIN_RACE_LATIN ;

			if ( ! gender ) {

				skinid = skins_male_latin [ random ( sizeof ( skins_male_latin ) ) ] [ 0 ] ;
			}

			else skinid = skins_female_latin [ random ( sizeof ( skins_female_latin ) ) ] [ 0 ] ;
		}

		case 2: { // SKIN_RACE_WHITE ;

			if ( ! gender ) {

				skinid = skins_male_white [ random ( sizeof ( skins_male_white ) ) ] [ 0 ] ;
			}

			else skinid = skins_female_white [ random ( sizeof ( skins_female_white ) ) ] [ 0 ] ;
		}

		case 3: { // SKIN_RACE_ASIAN ;

			if ( ! gender ) {

				skinid = skins_male_asian [ random ( sizeof ( skins_male_asian ) ) ] [ 0 ] ;
			}

			else skinid = skins_female_asian [ random ( sizeof ( skins_female_asian ) ) ] [ 0 ] ;
		}
	}

	SetPlayerSkinEx ( playerid, skinid );

	Character [ playerid ] [ E_CHARACTER_FRESH_SPAWN ] = true ;

	Player_LastSpawnPage [ playerid ] = 1 ;
	SpawnArea_Selection(playerid);
	return true ;
}

// Shows the page-based starting area list (SpawnArea table).
SpawnArea_Selection(playerid) {
    if (!SpawnAreaCount) return SendClientMessage(playerid,COLOR_ERROR,"No public spawn is configured. Ask an administrator to enable a spawn in the ACP.");
    new menuRevision=RuntimeRevision;
    if (Player_LastSpawnPage[playerid]<1 || (Player_LastSpawnPage[playerid]-1)*10>=SpawnAreaCount) Player_LastSpawnPage[playerid]=1;

	if ( Player_LastSpawnPage [ playerid ] == 0 ) {
		Player_LastSpawnPage [ playerid ] = 1 ;
	}


	new MAX_ITEMS_ON_PAGE = 10, string [ 512 ], bool: nextpage ;

    new pages = floatround ( SpawnAreaCount / MAX_ITEMS_ON_PAGE, floatround_floor ) + 1, 
    	resultcount = ( ( MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) - MAX_ITEMS_ON_PAGE ) ;

    strcat(string, "Area Name\n");

    for ( new i = resultcount; i < SpawnAreaCount; i ++ ) {

		resultcount ++ ;

        if ( resultcount <= MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) {

			format(string, sizeof(string), "%s\t%s\n", string, SpawnArea [ i ] [ E_SPAWN_AREA_DESC ]); 
        }

     	if ( resultcount > MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) {

            nextpage = true;
            break;
        }
	}

    if ( nextpage ) {
    	strcat(string, "Next Page >>" ) ;
    }
  
	inline CenterList(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if ( ! response ) 
		{
			if ( Player_LastSpawnPage [ playerid ] > 1 ) {

				Player_LastSpawnPage [ playerid ] -- ;
				return SpawnArea_Selection ( playerid ) ;
			}

			// If they aren't spawned as char allow them to go back
			if (!PlayerVar[pid][E_PLAYER_SPAWNED_CHARACTER] && PlayerVar[playerid][E_PLAYER_SPAWN_OPTIONS_COUNT])
			{
				return Player_DisplaySpawnList(playerid);
			}

			// Otherwise it's safe to close
			// return SpawnArea_Selection ( playerid ) ;
			
		}

		else if ( response ) {

			if ( listitem == MAX_ITEMS_ON_PAGE) {

				Player_LastSpawnPage [ playerid ] ++ ;
				return SpawnArea_Selection ( playerid ) ;
			}

			else if ( listitem < MAX_ITEMS_ON_PAGE ) {

				new selection = ( ( MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) - MAX_ITEMS_ON_PAGE ) + listitem;
                if (menuRevision!=RuntimeRevision || selection<0 || selection>=SpawnAreaCount) return SpawnArea_Selection(playerid);
                new source=SpawnSource[selection];

 				PlayerPlaySound ( playerid, 1085, 0.0, 0.0, 0.0 ) ;

 				//SendClientMessage(playerid, -1, sprintf("Selected %s %s", SpawnArea [ selection ] [ E_SPAWN_AREA_DESC ], SpawnArea [ selection ] [ E_SPAWN_AREA_DESC_EXTRA ] ) ) ;
 				//SendClientMessage(playerid, -1, sprintf("You spawned in %s.", SpawnArea [ selection ] [ E_SPAWN_AREA_DESC ]) ) ;

				if (PlayerVar[playerid][E_PLAYER_FIRST_SPAWN])
				{
					// This is an actual spawn
					SetSpawnInfo(playerid, 0, 264, SpawnArea [ selection ] [ E_SPAWN_AREA_POS_X ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Y ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Z ], SpawnArea[selection][E_SPAWN_AREA_ROT_Z], 0, 0, 0, 0, 0, 0);
					CS_SpawnPlayer(playerid);
				}
				else
				{
					// This is a respawn
					PauseAC(playerid, 3);
					SetPlayerPos(playerid, SpawnArea [ selection ] [ E_SPAWN_AREA_POS_X ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Y ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Z ] );
				}

 				SetPlayerFacingAngle(playerid,RuntimeLocations[source][RLOC_ANGLE]);
                SetCameraBehindPlayer(playerid);
 				SetPlayerInterior(playerid, RuntimeLocations[source][RLOC_INTERIOR]);
				SetPlayerVirtualWorld(playerid, RuntimeLocations[source][RLOC_WORLD]);
				TogglePlayerControllable(playerid, true);

				PlayerVar[playerid][E_PLAYER_FRESH_SPAWN_MSG_CD] = gettime () + 5;
				Player_OnSpawnRegisterCheck(playerid);
				
				// Must call this
				// (playerid, !PlayerVar[playerid][E_PLAYER_FIRST_SPAWN]);
 				return true ;
			}
		}
	}
	if ( Player_LastSpawnPage [ playerid ] > 1 ) {
   		Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Spawn Selection: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Spawn", "Previous" );
   	}
   	else
	{
		if (!PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER])
		{	
			if (PlayerVar[playerid][E_PLAYER_SPAWN_OPTIONS_COUNT]) Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Spawn Selection: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Spawn", "Back" );
			else Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Spawn Selection: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Spawn", "" );
		}
		else
		{
			Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Spawn Selection: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Spawn", "Close" );
		}
	} 
	   
	   
 

    return true ;
}

static msgstringg[2048]; //2048
//static countdown[MAX_PLAYERS];

// Shows the welcome message for a fresh character and registers their first spawn.
Player_OnSpawnRegisterCheck(playerid) {
	if ( Character [ playerid ] [ E_CHARACTER_FRESH_SPAWN ] ) {

		inline Spawn_IntroMsg(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused pid, inputtext, listitem, dialogid, response

			
			if ( PlayerVar [ playerid ] [ E_PLAYER_FRESH_SPAWN_MSG_CD ] > gettime() ) // 3 second cd
			{ 
				ShowPlayerSubtitle(playerid, "~r~Please wait before closing this box.", .showtime = 3000 ) ;
				Player_OnSpawnRegisterCheck(playerid);
				return true ;
			}

			SendAdminMessage(sprintf("[AdmWarn]: (%d) %s has just registered to the server.", playerid, ReturnRPName(playerid) ));	

			Character [ playerid ] [ E_CHARACTER_FRESH_SPAWN ] = false ;
			Character [ playerid ] [ E_CHARACTER_REGISTERED ] = true ;

			new query [ 256 ] ;

			mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_registered = 1 WHERE player_id = %d",
			 Character [ playerid ] [ E_CHARACTER_ID ] ) ;
			mysql_tquery(mysql, query ) ;

			mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_freshspawn = 0 WHERE player_id = %d",
			 Character [ playerid ] [ E_CHARACTER_ID ] ) ;
			mysql_tquery(mysql, query ) ;

			if(Character [ playerid ] [ E_CHARACTER_HOURS ] == 0) {
				SetPlayerCash ( playerid, 500 ) ;

				// Default value is automatically 500 in database no need to save
				Character [ playerid ] [ E_CHARACTER_BANKCASH ] = 250 ;

				mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_cash = 500 WHERE player_id = %d",
				Character [ playerid ] [ E_CHARACTER_ID ] ) ;
				mysql_tquery(mysql, query ) ;

				mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_bankcash = 250 WHERE player_id = %d",
				Character [ playerid ] [ E_CHARACTER_ID ] ) ;
				mysql_tquery(mysql, query ) ;
			}
			
			//Player_NametagChoice(playerid);
		}

		format(msgstringg, sizeof(msgstringg), "{FFFFFF}Thanks for joining {297183}%s{FFFFFF}, %s.\n", SERVER_NAME, Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ]);

		strcat(msgstringg, "\n{FFFF91}Useful Commands:\n");
		strcat(msgstringg, "{FFFFFF}- {8D8DFF}/gps{FFFFFF} - Interactive list of common locations.\n");
		strcat(msgstringg, "{FFFFFF}- {8D8DFF}/ask{FFFFFF} - Ask a question or for help.\n");
		strcat(msgstringg, "{FFFFFF}- {8D8DFF}/report{FFFFFF} - Report something to an admin.\n");

		strcat(msgstringg, "\n{ADBEE6}You can type {8D8DFF}/help{ADBEE6} to view the main help menu at any time.\n");
		
		strcat(msgstringg, "\n{FFFF91}Joining the Community:\n");
		strcat(msgstringg, "{FFFFFF}We openly invite you to join our community on Discord at: {8D8DFF}" SERVER_DISCORD "\n");
		strcat(msgstringg, "{ADBEE6}Please also look at our main forums where you can find faction topics and full server rules.\n");

		strcat(msgstringg, "\n{FFFF91}Important Notes & Rules:\n");
		strcat(msgstringg, "{FFFFFF}Our community is friendly and open, but please remember that we are a serious roleplaying server.\n");
		strcat(msgstringg, "{ADBEE6}It's expected that you act realistically, follow the rules and roleplay to the best of your ability.\n");
		strcat(msgstringg, "Our rules are similar to most heavy roleplay servers, but please do give them a quick look on our website.\n");
		strcat(msgstringg, "We are set in the year 2005, and take inspiration from Los Angeles County.\n");
		
		strcat(msgstringg, "\n{FFFFFF}Press {AA3333}Play{FFFFFF} to get started.\n");
		strcat(msgstringg, "{ADBEE6}Note that you've been assigned some random clothes. To change, visit any clothing store.");


		Dialog_ShowCallback ( playerid, using inline Spawn_IntroMsg, DIALOG_STYLE_MSGBOX, "Introduction", msgstringg, "Play" );


	}

	return true ;
}

/*

	for ( new i, j = sizeof ( player_skin_array ); i < j ; i ++ ) {

		if ( ! IsValidSkin ( i ) ) {

			continue ;
		}

		if ( GetSkinRace ( i ) == race && GetSkinGender ( i ) == gender ) {

			if ( GetSkinGang ( i ) == SKIN_GANG_NONE && GetSkinService ( i ) == SKIN_SERVICE_NONE ) {

				if ( GetSkinGroup(i) == SKIN_GROUP_MISSION ) {
					// This way people won't get big smoke & other cutscene peds

					continue ;
				}

				player_skin_array [ skin_count ++ ] = i;
			}

			else continue ;
		}

		else continue ;
	}

	skin_index = player_skin_array [ random ( skin_count ) ] ;

*/
