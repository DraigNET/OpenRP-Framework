// ============================================================================
// File: player/spawns/header.pwn
// The SpawnArea table (named starting locations) and /respawnplayer for staff. Coordinates are
// 0,0,0 until you set them.
// Commands: /respawnplayer /rpl
// ============================================================================



enum E_SPAWN_AREA_DATA {

	E_SPAWN_AREA_DESC[64],
	Float: E_SPAWN_AREA_POS_X,
	Float: E_SPAWN_AREA_POS_Y,
	Float: E_SPAWN_AREA_POS_Z,
	Float: E_SPAWN_AREA_ROT_X,
	Float: E_SPAWN_AREA_ROT_Y,
	Float: E_SPAWN_AREA_ROT_Z,

	E_SPAWN_AREA_DESC_EXTRA[64],
};

// Compact menu rows retain their source key for safe selections during reloads.
new SpawnArea[64][E_SPAWN_AREA_DATA], SpawnAreaCount, SpawnSource[64];

Runtime_RebuildSpawns() {
    SpawnAreaCount=0;
    for(new i; i<RuntimeLocationCount && SpawnAreaCount<64; i++) {
        if(RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_SPAWN || !RuntimeLocations[i][RLOC_ENABLED]) continue;
        new row=SpawnAreaCount++;
        SpawnSource[row]=i;
        format(SpawnArea[row][E_SPAWN_AREA_DESC],64,"%s",RuntimeLocations[i][RLOC_LABEL]);
        SpawnArea[row][E_SPAWN_AREA_POS_X]=RuntimeLocations[i][RLOC_X]; SpawnArea[row][E_SPAWN_AREA_POS_Y]=RuntimeLocations[i][RLOC_Y]; SpawnArea[row][E_SPAWN_AREA_POS_Z]=RuntimeLocations[i][RLOC_Z];
        SpawnArea[row][E_SPAWN_AREA_ROT_Z]=RuntimeLocations[i][RLOC_ANGLE];
    }
    return 1;
}

#define COLOUR_BUS	0xC0CD82FF

// Start-up for the spawn module (the bus stop code is commented out).
public OnGameModeInit() {

	/*for(new i, j = SpawnAreaCount; i < j ; i ++ ) {

		CreateDynamicObject(1257, SpawnArea [ i ] [ E_SPAWN_AREA_POS_X ], SpawnArea [ i ] [ E_SPAWN_AREA_POS_Y ], 
			SpawnArea [ i ] [ E_SPAWN_AREA_POS_Z ], SpawnArea [ i ] [ E_SPAWN_AREA_ROT_X ], SpawnArea [ i ] [ E_SPAWN_AREA_ROT_Y ],
		    SpawnArea [ i ] [ E_SPAWN_AREA_ROT_Z ] 
		);

		CreateDynamic3DTextLabel(sprintf("%s Bus Stop\n{DEDEDE}Use /bus to travel.",SpawnArea [ i ] [ E_SPAWN_AREA_DESC ]), COLOUR_BUS, SpawnArea [ i ] [ E_SPAWN_AREA_POS_X ], 
			SpawnArea [ i ] [ E_SPAWN_AREA_POS_Y ], SpawnArea [ i ] [ E_SPAWN_AREA_POS_Z ], 15.0);
	}*/

	//CreateDynamic3DTextLabel("Dillimore Bus Stop\n{DEDEDE}Use /bus to travel\nFare: $150", COLOUR_BUS, 688.4519,-501.6273,16.3359, 15.0);
	//CreateDynamic3DTextLabel("Angel Pine Bus Stop\n{DEDEDE}Use /bus to travel\nFare: $150", COLOUR_BUS, -2208.6614,-2260.7751,30.6250, 15.0);
	
	#if defined skin_OnGameModeInit
		return skin_OnGameModeInit();
	#else
		return 1;
	#endif
}
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif

#define OnGameModeInit skin_OnGameModeInit
#if defined skin_OnGameModeInit
	forward skin_OnGameModeInit();
#endif

#include "player/spawns/func.pwn"

/*CMD:bus(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	if ( Character [ playerid ] [ E_CHARACTER_CASH ] < 150 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have the correct bus fare!");
	}

	PlayerPlaySound ( playerid, 1085, 0.0, 0.0, 0.0 ) ;
	new string[64];
	if(IsPlayerInRangeOfPoint(playerid, 4.0, 688.4519,-501.6273,16.3359))
	{
		format ( string, sizeof ( string ), "has taken a coach to Angel Pine." ) ;
		ProxDetectorEx(playerid,15.0, COLOR_ACTION, "*", string, .showid = false);
		SetPlayerInterior(playerid, RuntimeLocations[source][RLOC_INTERIOR]);
		SetPlayerVirtualWorld(playerid, RuntimeLocations[source][RLOC_WORLD]);
		ORP_SetPosWithFade(playerid, -2208.6614, -2260.7751, 30.6250);

		SetPlayerFacingAngle(playerid,RuntimeLocations[source][RLOC_ANGLE]);
                SetCameraBehindPlayer(playerid);
		PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER] = true;
		TakePlayerCash ( playerid, 150 ) ;
	}
	else if(IsPlayerInRangeOfPoint(playerid, 4.0, -2208.6614, -2260.7751, 30.6250))
	{
		format ( string, sizeof ( string ), "has taken a coach to Dillimore." ) ;
		ProxDetectorEx(playerid,15.0, COLOR_ACTION, "*", string, .showid = false);
		SetPlayerInterior(playerid, RuntimeLocations[source][RLOC_INTERIOR]);
		SetPlayerVirtualWorld(playerid, RuntimeLocations[source][RLOC_WORLD]);
		ORP_SetPosWithFade(playerid, 688.4519,-501.6273,16.3359);

		SetCameraBehindPlayer(playerid);
		PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER] = true;
		TakePlayerCash ( playerid, 150 ) ;
	}

	return true ;
}*/

// /respawnplayer [player] - (staff) sends a player back to the spawn menu.
CMD:respawnplayer(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < 2 && Account[playerid][E_PLAYER_ACCOUNT_SUPPORTER] < 2 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new targetid;
	if ( sscanf ( params, "k<player>", targetid ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/respawnplayer [player]");
	}

	if (!IsPlayerConnected(targetid) || !IsPlayerLogged(playerid)) return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't connected.");
	//Spawn_Newbie(targetid);

	Player_DisplaySpawnList(targetid, true);
	new string [ 128 ] ;

	format(string, sizeof(string), "showed the spawn selection options to (%d) %s", targetid, ReturnRPName(targetid));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, string);

	format ( string, sizeof ( string ), "(%d) %s has shown you the spawn selection screen.", playerid, ReturnRPName(playerid)) ;
	SendClientMessage(targetid, -1, string );

	return true;
}

CMD:rpl(playerid, params[])
{
	return cmd_respawnplayer(playerid, params);
}

// Shows the starting area list for a new character.
SpawnArea_SelectionEx(playerid) {
    if (!SpawnAreaCount) return SendClientMessage(playerid,COLOR_ERROR,"No public spawn is configured. Ask an administrator to enable a spawn in the ACP.");
    new menuRevision=RuntimeRevision;
    if (Player_LastSpawnPage[playerid]<1 || (Player_LastSpawnPage[playerid]-1)*10>=SpawnAreaCount) Player_LastSpawnPage[playerid]=1;

	new MAX_ITEMS_ON_PAGE = 10, string [ 512 ], bool: nextpage ;

    new pages = floatround ( SpawnAreaCount / MAX_ITEMS_ON_PAGE, floatround_floor ) + 1, 
    	resultcount = ( ( MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) - MAX_ITEMS_ON_PAGE ) ;

    strcat(string, "Area Name\n");

    for ( new i = resultcount; i < SpawnAreaCount; i ++ ) {

		resultcount ++ ;

        if ( resultcount <= MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) {

			//format(string, sizeof(string), "%s\t%s{dedede}%s\n", string, SpawnArea [ i ] [ E_SPAWN_AREA_DESC_EXTRA ], SpawnArea [ i ] [ E_SPAWN_AREA_DESC ]); 
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

		if ( ! response ) {

			if ( Player_LastSpawnPage [ playerid ] > 1 ) {

				Player_LastSpawnPage [ playerid ] -- ;
				return SpawnArea_SelectionEx(playerid) ;
			}
		}

		else if ( response ) {

			if ( listitem == MAX_ITEMS_ON_PAGE) {

				Player_LastSpawnPage [ playerid ] ++ ;
				return SpawnArea_SelectionEx ( playerid ) ;
			}

			else if ( listitem < MAX_ITEMS_ON_PAGE ) {

				new selection = ( ( MAX_ITEMS_ON_PAGE * Player_LastSpawnPage [ playerid ] ) - MAX_ITEMS_ON_PAGE ) + listitem;
                if (menuRevision!=RuntimeRevision || selection<0 || selection>=SpawnAreaCount) return SpawnArea_SelectionEx(playerid);
                new source=SpawnSource[selection];

 				PlayerPlaySound ( playerid, 1085, 0.0, 0.0, 0.0 ) ;

 				string[0]=EOS;
				format ( string, sizeof ( string ), "has taken the bus to %s. ", SpawnArea [ selection ] [ E_SPAWN_AREA_DESC ] ) ;
				ProxDetectorEx(playerid,15.0, COLOR_ACTION, "*", string, .showid = false);

 				//SendClientMessage(playerid, -1, sprintf("You've spawning in %s - %s territory!", SpawnArea [ selection ] [ E_SPAWN_AREA_DESC ], SpawnArea [ selection ] [ E_SPAWN_AREA_DESC_EXTRA ] ) ) ;
				//SendClientMessage(playerid, -1, sprintf("You've spawned in %s.", SpawnArea [ selection ] [ E_SPAWN_AREA_DESC ] ) ) ;
				//SetPlayerPos(playerid, SpawnArea [ selection ] [ E_SPAWN_AREA_POS_X ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Y ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Z ] );
				
				SetPlayerInterior(playerid, RuntimeLocations[source][RLOC_INTERIOR]);
				SetPlayerVirtualWorld(playerid, RuntimeLocations[source][RLOC_WORLD]);
				ORP_SetPosWithFade(playerid, SpawnArea [ selection ] [ E_SPAWN_AREA_POS_X ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Y ], SpawnArea [ selection ] [ E_SPAWN_AREA_POS_Z ]);
 				SetCameraBehindPlayer(playerid);
				PlayerVar[playerid][E_PLAYER_SPAWNED_CHARACTER] = true;

 				return true ;
			}
		}
	}
	if ( Player_LastSpawnPage [ playerid ] > 1 ) {
   		Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Bus Stop: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Travel", "Previous" );
   	}

	else Dialog_ShowCallback ( playerid, using inline CenterList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Bus Stop: Page %d of %d", Player_LastSpawnPage [ playerid ], pages), string, "Travel", "Close" );

    return true ;
}
