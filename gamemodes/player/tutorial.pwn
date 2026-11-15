// ============================================================================
// File: player/tutorial.pwn
// A camera tour for new players (/tutorial) made of stages with a position, text and duration.
// Currently disabled; edit the TutorialStage table and the /tutorial command to enable it.
// Commands: /tutorial
// ============================================================================


new Text:td_tutorial[3] = Text: INVALID_TEXT_DRAW ;
new PlayerText:ptd_tutorial[MAX_PLAYERS][2] = { PlayerText: INVALID_TEXT_DRAW, ... };


enum E_TUTORIAL_STAGE_DATA
{
	Float:E_TUTORIAL_STAGE_POS[3],
	Float:E_TOTORIAL_STAGE_LOOK[3],
	E_TUTORIAL_STAGE_INTERPOLATE[2],
	E_TUTORIAL_STAGE_TITLE[128],
	E_TUTORIAL_STAGE_LINE_1[256],
	E_TUTORIAL_STAGE_LINE_2[256],
	E_TUTORIAL_STAGE_LINE_3[256]
}

// Tutorial tour. TODO: set camera coordinates for your map (all 0,0,0 for now). The text is
// generic -- rewrite both to match your own server and map.
static const TutorialStage[][E_TUTORIAL_STAGE_DATA] = 
{
	{ {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {2500, 2500}, "Welcome", "Welcome to ~y~" SERVER_NAME "~w~, a text-based roleplay server.", "Please read the rules on our website before you start playing.", "Treat your character as a real person, not a game avatar." },
	{ {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {2500, 2500}, "Getting Started", "Type ~y~/help~w~ for a list of commands.~n~Type ~y~/ask~w~ if you have any questions.", "Use ~y~/gps~w~ to find common locations around the map.", "And for admin assistance, type ~y~/report~w~." },
	{ {0.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0, 0}, "Get Involved", "Join our community on ~p~Discord~w~: ~y~" SERVER_DISCORD "~w~", "Our community is welcoming, and our different teams are always looking for people to contribute.", "That's all from us, time to play!" }
};

new TutorialSkipCooldown[MAX_PLAYERS];
// /tutorial - currently disabled; remove the early return to enable the tour.
CMD:tutorial(playerid) {

	return SendClientMessage(playerid, COLOR_ERROR, "The tutorial is currently disabled." ) ;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
	TutorialSkipCooldown[playerid] = 0;
	return 1;
}

// Starts the tutorial tour for a player.
stock StartTutorial(playerid) {

	for ( new i, j = 2; i < j ; i ++ ) {

		PlayerTextDrawShow(playerid, ptd_tutorial[playerid] [ i ] );
	}

	TextDrawShowForPlayer(playerid, td_tutorial [ 0 ] );

	PlayerTextDrawSetString(playerid, ptd_tutorial[playerid][0], "Setting up tutorial..." ) ;
	PlayerTextDrawSetString(playerid, ptd_tutorial[playerid][1], "Please wait while we set up the tutorial for you." ) ;

	PlayerVar [ playerid ] [ E_PLAYER_IS_DOING_TUTORIAL ] = true ;
	PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] = 0 ;
	PlayerVar[playerid][E_PLAYER_TUTORIAL_LAST_STAGE] = 0;
	PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = false;

	TogglePlayerSpectating(playerid, true ) ;

	SetPlayerInterior ( playerid, 0 );
	SetPlayerVirtualWorld(playerid, 0 );

	SetTimerEx("Tutorial_SetupScenario", 1000, false, "i", playerid);

	return true ;
}

// Ends the tutorial and spawns the player.
FinishTutorial(playerid) {

	PlayerVar [ playerid ] [ E_PLAYER_IS_DOING_TUTORIAL ] = false ;
	PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = false;
	PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] = 0 ;
	PlayerVar[playerid][E_PLAYER_TUTORIAL_LAST_STAGE] = 0;

	Character [ playerid ] [ E_CHARACTER_TUTORIAL ] = true ;

	new query[128];
	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_tutorial = %d WHERE player_id = %d",
		Character [ playerid ] [ E_CHARACTER_TUTORIAL ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

	mysql_tquery(mysql, query);

	CancelSelectTextDraw(playerid);
	SpawnArea_Selection(playerid) ;
}

static TutString[1024];

// Shows one stage of the tutorial (camera position and text).
ShowTutorialStage(playerid, stage)
{
	new postime = TutorialStage[stage][E_TUTORIAL_STAGE_INTERPOLATE][0];


	//new looktime = TutorialStage[stage][E_TUTORIAL_STAGE_INTERPOLATE][1];
	//new last = PlayerVar[playerid][E_PLAYER_TUTORIAL_LAST_STAGE];

	/*
	if (postime && last >= 0) InterpolateCameraPos(playerid, TutorialStage[last][E_TUTORIAL_STAGE_POS][0], TutorialStage[last][E_TUTORIAL_STAGE_POS][1], TutorialStage[last][E_TUTORIAL_STAGE_POS][2], TutorialStage[stage][E_TUTORIAL_STAGE_POS][0], TutorialStage[stage][E_TUTORIAL_STAGE_POS][1], TutorialStage[stage][E_TUTORIAL_STAGE_POS][2], postime);
	else SetPlayerCameraPos(playerid, TutorialStage[stage][E_TUTORIAL_STAGE_POS][0], TutorialStage[stage][E_TUTORIAL_STAGE_POS][1], TutorialStage[stage][E_TUTORIAL_STAGE_POS][2]);

	if (looktime && last >= 0) InterpolateCameraLookAt(playerid, TutorialStage[last][E_TOTORIAL_STAGE_LOOK][0], TutorialStage[last][E_TOTORIAL_STAGE_LOOK][1], TutorialStage[last][E_TOTORIAL_STAGE_LOOK][2], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][0], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][1], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][2], looktime);
	else SetPlayerCameraLookAt(playerid, TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][0], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][1], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][2]);
	*/


	SetPlayerCameraPos(playerid, TutorialStage[stage][E_TUTORIAL_STAGE_POS][0], TutorialStage[stage][E_TUTORIAL_STAGE_POS][1], TutorialStage[stage][E_TUTORIAL_STAGE_POS][2]);
	SetPlayerCameraLookAt(playerid, TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][0], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][1], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][2]);
	Streamer_UpdateEx(playerid, TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][0], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][1], TutorialStage[stage][E_TOTORIAL_STAGE_LOOK][2], 0, 0, STREAMER_TYPE_OBJECT, -1, 0);

	TutString[0] = EOS;
	PlayerTextDrawSetString(playerid, ptd_tutorial[playerid][0], TutorialStage[stage][E_TUTORIAL_STAGE_TITLE]);
	strcat(TutString, TutorialStage[stage][E_TUTORIAL_STAGE_LINE_1]);

	if (strlen(TutorialStage[stage][E_TUTORIAL_STAGE_LINE_2]))
	{
		strcat(TutString, "~n~~n~");
		strcat(TutString, TutorialStage[stage][E_TUTORIAL_STAGE_LINE_2]);
	} 

	if (strlen(TutorialStage[stage][E_TUTORIAL_STAGE_LINE_3]))
	{
		strcat(TutString, "~n~~n~");
		strcat(TutString, TutorialStage[stage][E_TUTORIAL_STAGE_LINE_3]);
	} 

	PlayerTextDrawSetString(playerid, ptd_tutorial[playerid][1], TutString) ;
	// SelectTextDraw(playerid, 0xDEDEDEFF );

	TextDrawHideForPlayer ( playerid, td_tutorial[1] );
	TextDrawHideForPlayer ( playerid, td_tutorial[2] );

	defer Tutorial_CameraMoved[postime](playerid);
	//Tutorial_CameraMoved(playerid);
}

// Timer: shows the back button once the camera has moved.
timer Tutorial_CameraMoved[1000](playerid)
{
	new stage = PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] ;

	// Previous Button
	if ( stage > 0 ) TextDrawShowForPlayer ( playerid, td_tutorial[1] ) ;
	else TextDrawHideForPlayer ( playerid, td_tutorial[1] );

	// Next Button
	if ( stage + 1 < sizeof(TutorialStage)) TextDrawSetString(td_tutorial[2], "Next" );
	else TextDrawSetString(td_tutorial[2], "~y~Finish" );
	TextDrawShowForPlayer ( playerid, td_tutorial[2] ) ;

	PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = false;
	SelectTextDraw(playerid, 0xDEDEDEFF );
}	

// Sets up the player's world and camera for the tutorial.
stock Tutorial_SetupScenario(playerid) {

	if ( ! PlayerVar [ playerid ] [ E_PLAYER_IS_DOING_TUTORIAL ] ) {

		for ( new i, j = 2; i < j ; i ++ ) {

			PlayerTextDrawHide(playerid, ptd_tutorial[playerid] [ i ] );
		}
		for ( new i, j = sizeof ( td_tutorial ); i < j ; i ++ ) {

			TextDrawHideForPlayer(playerid, td_tutorial [ i ] );
		}

		PlayerVar [ playerid ] [ E_PLAYER_IS_DOING_TUTORIAL ] = false ;
		PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] = 0 ;
		PlayerVar[playerid][E_PLAYER_TUTORIAL_LAST_STAGE] = 0;
		PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = false;

		CancelSelectTextDraw(playerid);

		if ( GetPlayerState ( playerid ) == PLAYER_STATE_SPECTATING ) {
			SendClientMessage(playerid, COLOR_RED, "Tried to load tutorial whilst you've already done it. Select a spawn point!" ) ;
			Player_DisplaySpawnList(playerid);
		}

		return true ;
	}

	new stage = PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] ;

	if (stage >= sizeof(TutorialStage))
	{
		// Finish tutorial
		for ( new i, j = 2; i < j ; i ++ ) {

			PlayerTextDrawHide(playerid, ptd_tutorial[playerid] [ i ] );
		}
		for ( new i, j = sizeof ( td_tutorial ); i < j ; i ++ ) {

			TextDrawHideForPlayer(playerid, td_tutorial [ i ] );
		}

		FinishTutorial(playerid);
		return true ;
	}

	// Previous Button
	if ( stage > 0 ) TextDrawShowForPlayer ( playerid, td_tutorial[1] ) ;
	else TextDrawHideForPlayer ( playerid, td_tutorial[1] );

	// Next Button
	if ( stage + 1 < sizeof(TutorialStage)) TextDrawSetString(td_tutorial[2], "Next" );
	else TextDrawSetString(td_tutorial[2], "~g~Finish" );
	//TextDrawShowForPlayer ( playerid, td_tutorial[2] ) ;

	ShowTutorialStage(playerid, stage);
	//CancelSelectTextDraw(playerid);

	return true ;
}

// Handles clicks on the tutorial next/back/skip buttons.
public OnPlayerClickTextDraw(playerid, Text:clickedid) {

	if ( PlayerVar[playerid][E_PLAYER_IS_DOING_TUTORIAL] && clickedid != Text:INVALID_TEXT_DRAW ) 
	{
		if ( clickedid == td_tutorial[1] ) // tutorial_back
		{ 
			if (!PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING])
			{
				PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = true;
				PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_LAST_STAGE ] = PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ];
				PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] -- ;
				Tutorial_SetupScenario( playerid ) ;
			}
		}		
		else if ( clickedid == td_tutorial[2] ) // tutorial_next
		{
			if (!PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING])
			{
				PlayerVar[playerid][E_PLAYER_TUTORIAL_WAITING] = true;
				PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_LAST_STAGE ] = PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ];
				PlayerVar [ playerid ] [ E_PLAYER_TUTORIAL_STAGE ] ++ ;
				Tutorial_SetupScenario( playerid ) ;
			}
		}
		else
		{
			SelectTextDraw(playerid, 0xDEDEDEFF );
		}
	}

	#if defined tut_OnPlayerClickTextDraw
		return tut_OnPlayerClickTextDraw(playerid, Text: clickedid );
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerClickTextDraw
	#undef OnPlayerClickTextDraw
#else
	#define _ALS_OnPlayerClickTextDraw
#endif

#define OnPlayerClickTextDraw tut_OnPlayerClickTextDraw
#if defined tut_OnPlayerClickTextDraw
	forward tut_OnPlayerClickTextDraw(playerid, Text: clickedid );
#endif

// Destroys the tutorial textdraws for a player.
TutorialGUI_DestroyPlayer(playerid) {

	for ( new i, j = sizeof ( td_tutorial ); i < j ; i ++ ) {

		TextDrawHideForPlayer(playerid, td_tutorial [ i ] ) ;
	}

	for ( new i, j = 2; i < j ; i ++ ) {

		if (ptd_tutorial[playerid] [ i ] != PlayerText:INVALID_TEXT_DRAW) {
			PlayerTextDrawDestroy(playerid, ptd_tutorial[playerid] [ i ]);
			ptd_tutorial[playerid] [ i ] = PlayerText:INVALID_TEXT_DRAW;
		}
	}

	return true ;
}

// Creates the tutorial textdraws for a player.
TutorialGUI_CreatePlayer(playerid) {
	TutorialGUI_DestroyPlayer(playerid);

	ptd_tutorial[playerid][0] = CreatePlayerTextDraw(playerid, 194.0000, 285.0000, "title");
	if (ptd_tutorial[playerid][0] == PlayerText:INVALID_TEXT_DRAW) {
		TutorialGUI_DestroyPlayer(playerid);
		return 0;
	}
	PlayerTextDrawFont(playerid, ptd_tutorial[playerid][0], 0);
	PlayerTextDrawLetterSize(playerid, ptd_tutorial[playerid][0], 0.5000, 1.7500);
	PlayerTextDrawColor(playerid, ptd_tutorial[playerid][0], -1);
	PlayerTextDrawSetShadow(playerid, ptd_tutorial[playerid][0], 0);
	PlayerTextDrawSetOutline(playerid, ptd_tutorial[playerid][0], 1);
	PlayerTextDrawBackgroundColor(playerid, ptd_tutorial[playerid][0], 255);
	PlayerTextDrawSetProportional(playerid, ptd_tutorial[playerid][0], 1);
	PlayerTextDrawTextSize(playerid, ptd_tutorial[playerid][0], 500.0000, 0.0000);

	ptd_tutorial[playerid][1] = CreatePlayerTextDraw(playerid, 207.0000, 305.0000, "text");
	if (ptd_tutorial[playerid][1] == PlayerText:INVALID_TEXT_DRAW) {
		TutorialGUI_DestroyPlayer(playerid);
		return 0;
	}
	PlayerTextDrawFont(playerid, ptd_tutorial[playerid][1], 1);
	PlayerTextDrawLetterSize(playerid, ptd_tutorial[playerid][1], 0.2500, 1.0000);
	PlayerTextDrawColor(playerid, ptd_tutorial[playerid][1], -1);
	PlayerTextDrawSetShadow(playerid, ptd_tutorial[playerid][1], 0);
	PlayerTextDrawSetOutline(playerid, ptd_tutorial[playerid][1], 0);
	PlayerTextDrawBackgroundColor(playerid, ptd_tutorial[playerid][1], 255);
	PlayerTextDrawSetProportional(playerid, ptd_tutorial[playerid][1], 1);
	PlayerTextDrawTextSize(playerid, ptd_tutorial[playerid][1], 450.0000, 0.0000);
	return 1;
}

// Creates the shared tutorial textdraws once.
TutorialGUI_CreateStatic() {

	td_tutorial[0] = TextDrawCreate(200.0000, 297.5000, "_");
	TextDrawFont(td_tutorial[0], 1);
	TextDrawLetterSize(td_tutorial[0], 0.2500, 10.0000);
	TextDrawColor(td_tutorial[0], -1);
	TextDrawSetShadow(td_tutorial[0], 0);
	TextDrawSetOutline(td_tutorial[0], 0);
	TextDrawBackgroundColor(td_tutorial[0], 255);
	TextDrawSetProportional(td_tutorial[0], 1);
	TextDrawUseBox(td_tutorial[0], 1);
	TextDrawBoxColor(td_tutorial[0], 170);
	TextDrawTextSize(td_tutorial[0], 450.0000, 0.0000);

	td_tutorial[1] = TextDrawCreate(213.5000, 377.5000, "Back");
	TextDrawFont(td_tutorial[1], 3);
	TextDrawLetterSize(td_tutorial[1], 0.2500, 1.0000);
	TextDrawAlignment(td_tutorial[1], 2);
	TextDrawColor(td_tutorial[1], -1);
	TextDrawSetShadow(td_tutorial[1], 0);
	TextDrawSetOutline(td_tutorial[1], 1);
	TextDrawBackgroundColor(td_tutorial[1], 255);
	TextDrawSetProportional(td_tutorial[1], 1);
	TextDrawUseBox(td_tutorial[1], 1);
	TextDrawBoxColor(td_tutorial[1], 170);
	TextDrawTextSize(td_tutorial[1], 25.0000, 25.0000);
	TextDrawSetSelectable(td_tutorial[1], true);

	td_tutorial[2] = TextDrawCreate(436.5000, 377.5000, "Next");
	TextDrawFont(td_tutorial[2], 3);
	TextDrawLetterSize(td_tutorial[2], 0.2500, 1.0000);
	TextDrawAlignment(td_tutorial[2], 2);
	TextDrawColor(td_tutorial[2], -1);
	TextDrawSetShadow(td_tutorial[2], 0);
	TextDrawSetOutline(td_tutorial[2], 1);
	TextDrawBackgroundColor(td_tutorial[2], 255);
	TextDrawSetProportional(td_tutorial[2], 1);
	TextDrawUseBox(td_tutorial[2], 1);
	TextDrawBoxColor(td_tutorial[2], 170);
	TextDrawTextSize(td_tutorial[2], 25.0000, 25.0000);
	TextDrawSetSelectable(td_tutorial[2], true);
}

