// ============================================================================
// File: vehicle/modules/pilot.pwn
// Pilot's licence: a ground-school quiz (/takepilottest) required to fly player-owned or rented
// aircraft.
// Commands: /takepilottest
// ============================================================================

// ------------------------------------------------------------------------------
// Pilot's license: a ground-school quiz taken at the aircraft dealership, modelled on the DMV driving test.
// Without the license you can't take the controls of a player-owned or rented aircraft (see
// Pilot_CanFlyVehicle, used by OnPlayerEnterVehicle). Faction, job and firm aircraft are not affected.

#define PILOT_LICENSE_REQUIRED 	( true )
#define SERVER_PILOT_FEE (Runtime_Int(RT_LICENSES_PILOT_FEE)) // Cached database setting; edit through ACP.
#define PILOT_TEST_X 			( 1957.5844 )
#define PILOT_TEST_Y 			( -2183.7864 )
#define PILOT_TEST_Z 			( 13.5469 )

#define TOTAL_PILOT_DIALOGS 8

static PilotQuestion[MAX_PLAYERS] = 0;
static PilotScore[MAX_PLAYERS] = -1;
static PilotAnswer[MAX_PLAYERS] = -2;

static PilotDialogStr[1400];

static const PilotQuestions[TOTAL_PILOT_DIALOGS][128] =
{
	"{FFEE00}Where may you take off and land an aircraft?",
	"{FFEE00}How should you fly over a town or city?",
	"{FFEE00}What should you do before you take off?",
	"{FFEE00}You are told to leave a restricted area. What do you do?",
	"{FFEE00}What should you do if you have an emergency in the air?",
	"{FFEE00}Are you allowed to fly after taking drugs or alcohol?",
	"{FFEE00}Another aircraft is flying towards you. What do you do?",
	"{FFEE00}Who is allowed to fly an aircraft?"
};

static enum PilotAnswerData
{
	pQuestionId,
	bool:pIsCorrect,
	pAnswerText[128]
}

static const PilotAnswers[TOTAL_PILOT_DIALOGS*4][PilotAnswerData] =
{
	{0, true, "Only at an airfield or a runway meant for aircraft"},
	{0, false, "Anywhere that looks flat enough"},
	{0, false, "On a busy road, if there are no cars"},
	{0, false, "On the roof of any tall building"},
	{1, true, "At a safe height, away from people and buildings"},
	{1, false, "As low as possible, to get a better view"},
	{1, false, "Circle low over busy areas for fun"},
	{1, false, "Fly between the buildings"},
	{2, true, "Check your fuel, your aircraft and the airspace around you"},
	{2, false, "Nothing, just take off"},
	{2, false, "Turn your lights off so nobody sees you"},
	{2, false, "Wait for a passenger to start the engine"},
	{3, true, "Leave the area immediately and follow the instructions given"},
	{3, false, "Ignore it and carry on flying"},
	{3, false, "Circle the area until they stop asking"},
	{3, false, "Land wherever you are"},
	{4, true, "Stay calm, land as safely as you can and call for help"},
	{4, false, "Keep flying as fast as possible"},
	{4, false, "Crash the aircraft on purpose"},
	{4, false, "Turn off the engine and wait"},
	{5, true, "No, you cannot fly or control an aircraft while impaired"},
	{5, false, "Yes, if the weather is good"},
	{5, false, "Yes, but only for a short flight"},
	{5, false, "Yes, it helps you relax"},
	{6, true, "Change course in good time and keep clear of the other aircraft"},
	{6, false, "Fly straight at it"},
	{6, false, "Speed up and race it"},
	{6, false, "Nothing, they will move"},
	{7, true, "Only people who have a valid pilot's license"},
	{7, false, "Anyone who can afford a plane"},
	{7, false, "Anyone with a driver's license"},
	{7, false, "Anyone who has watched a plane take off"}
};

// Start-up for the pilot test.
Pilot_Init()
{
	CreateDynamicPickup(1581, 1, PILOT_TEST_X, PILOT_TEST_Y, PILOT_TEST_Z );
	CreateDynamic3DTextLabel("Pilot Ground School\n{DEDEDE}Available commands: /takepilottest", COLOR_VEHICLE, PILOT_TEST_X, PILOT_TEST_Y, PILOT_TEST_Z + 0.5, 15.0 );
}

// Can this player take the controls of this vehicle? Only player-owned and rented aircraft need the license.
Pilot_CanFlyVehicle(playerid, vehicleid)
{
	if ( ! PILOT_LICENSE_REQUIRED || ! IsAircraft ( vehicleid ) ) return true ;
	if ( Character [ playerid ] [ E_CHARACTER_PILOTSLICENSE ] || PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] ) return true ;

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid ) ;

	if ( veh_enum_id == -1 ) return true ;

	switch ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] ) {
		case E_VEHICLE_TYPE_PLAYER, E_VEHICLE_TYPE_RENTAL: return false ;
	}

	return true ;
}

forward DlgPilotTestFail(playerid, dialogid, response, listitem, string:inputtext[]);
// Dialog: the pilot test was failed.
public DlgPilotTestFail(playerid, dialogid, response, listitem, string:inputtext[])
{
	if (response)
	{
		cmd_takepilottest(playerid);
	}

	return 1;
}

forward DlgPilotTestPass(playerid, dialogid, response, listitem, string:inputtext[]);
// Dialog: the pilot test was passed.
public DlgPilotTestPass(playerid, dialogid, response, listitem, string:inputtext[])
{
	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_pilotslicense = 1 WHERE player_id = %d", Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	Character [ playerid ] [ E_CHARACTER_PILOTSLICENSE ] = 1 ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Aviation", "A3A3A3", "Congratulations! You've passed your test and been given a pilot's license." ) ;
}

forward DlgPilotTest(playerid, dialogid, response, listitem, string:inputtext[]);
// Dialog: the player answers a pilot question.
public DlgPilotTest(playerid, dialogid, response, listitem, string:inputtext[])
{
	if (!response)
	{
		// Show them it again
		ShowPilotQuestion(playerid, PilotQuestion[playerid]);
		return 1;
	}

	if (PilotAnswer[playerid] == listitem)
	{
		PilotScore[playerid] ++;
	}

	if ((PilotQuestion[playerid] + 1) >= TOTAL_PILOT_DIALOGS)
	{
		if (PilotScore[playerid] == TOTAL_PILOT_DIALOGS)
		{
			Dialog_ShowCallback(playerid, using public DlgPilotTestPass<iiiis>, DIALOG_STYLE_MSGBOX, "Pilot Test Result", sprintf("You passed the pilot test with %d/%d correct answers.\n{FFFFFF}Press 'OK' to be issued with your pilot's license.", PilotScore[playerid], TOTAL_PILOT_DIALOGS), "OK");
		}
		else
		{
			Dialog_ShowCallback(playerid, using public DlgPilotTestFail<iiiis>, DIALOG_STYLE_MSGBOX, "Pilot Test Result", sprintf("You failed the pilot test with %d/%d correct answers.\n{FFFFFF}Press 'Retry' to take the test again. You will need to pay the fee again.", PilotScore[playerid], TOTAL_PILOT_DIALOGS), "Retry", "Back");
		}

		return 1;
	}

	ShowPilotQuestion(playerid, PilotQuestion[playerid] + 1);

	return 1;
}

// Returns true if a value is in the list of right answers.
static bool:Pilot_IsInAnswersArray(const array[4], value)
{
	for (new i = 0; i < sizeof(array); i++)
	{
		if (array[i] == value)
		{
			return true;
		}
	}

	return false;
}

// Shows a pilot test question.
ShowPilotQuestion(playerid, questionid)
{
	new count = 0;
	format(PilotDialogStr, sizeof(PilotDialogStr), "%s", "");

	new possibleAnswers[4];
	new shuffledAnswers[4];
	new answers[4] = {-1, ...};

	for (new i = 0; i < sizeof(PilotAnswers); i++)
	{
		if (PilotAnswers[i][pQuestionId] != questionid) continue;
		possibleAnswers[count] = i;
		count ++;
	}

	for (new i = 0; i < sizeof(answers); i++)
	{
		new answer = random(4);

		while (Pilot_IsInAnswersArray(answers, answer))
		{
			answer = random(4);
		}

		shuffledAnswers[i] = possibleAnswers[answer];
		answers[i] = answer;
	}

	count = 0;
	for (new i = 0; i < sizeof(shuffledAnswers); i++)
	{
		if (PilotAnswers[shuffledAnswers[i]][pIsCorrect])
		{
			PilotAnswer[playerid] = i;
		}

		strcat(PilotDialogStr, PilotAnswers[shuffledAnswers[i]][pAnswerText]);

		count ++;
		if (count < 4) strcat(PilotDialogStr, "\n");
	}

	PilotQuestion[playerid] = questionid;
	if (questionid == 0) PilotScore[playerid] = 0;

	Dialog_ShowCallback(playerid, using public DlgPilotTest<iiiis>, DIALOG_STYLE_LIST, PilotQuestions[questionid], PilotDialogStr, "Select");
}

// /takepilottest - starts the pilot licence test.
CMD:takepilottest(playerid)
{
	if ( ! IsPlayerInRangeOfPoint ( playerid, 5.0, PILOT_TEST_X, PILOT_TEST_Y, PILOT_TEST_Z ) ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Aviation", "A3A3A3", "You're not at the pilot ground school! It's at the Aircraft Dealership, use /gps." ) ;
	}

	if ( Character [ playerid ] [ E_CHARACTER_PILOTSLICENSE ] ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Aviation", "A3A3A3", "You already have a pilot's license." ) ;
	}

	if ( ! Character [ playerid ] [ E_CHARACTER_DRIVERSLICENSE ] ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Aviation", "A3A3A3", "You need a driver's license before you can train as a pilot. Visit the DMV first." ) ;
	}

	if ( GetPlayerCash ( playerid ) < SERVER_PILOT_FEE )
	{
		return SendServerMessage ( playerid, COLOR_BLUE, "Aviation", "A3A3A3", sprintf("You don't have enough money to take the test. You need at least $%s.", IntegerWithDelimiter ( SERVER_PILOT_FEE ) )) ;
	}

	format(PilotDialogStr, sizeof(PilotDialogStr), "{FFFFFF}You are about to take the pilot test.");
	strcat(PilotDialogStr, "\n{ADBEE6}You will be asked eight questions about flying safely and legally.\n\n");

	strcat(PilotDialogStr, "{FFFFFF}Pilot Test Instructions:{ADBEE6}");
	strcat(PilotDialogStr, "\n- You must answer all eight questions correctly to pass the test.");
	strcat(PilotDialogStr, "\n- You can't fly after taking drugs or alcohol.");
	strcat(PilotDialogStr, "\n- Take off and land only at airfields and runways.");
	strcat(PilotDialogStr, "\n- Flying recklessly or into restricted areas is a felony.\n\n");

	format(PilotDialogStr, sizeof(PilotDialogStr), "%s{FFFFFF}Press {AA3333}OK{FFFFFF} to pay {AA3333}$%s{FFFFFF} and take the pilot test.\n", PilotDialogStr, IntegerWithDelimiter(SERVER_PILOT_FEE));
	strcat(PilotDialogStr, "{ADBEE6}Please only start the test if you have read the above information.");

	inline DlgPilotTestStart(pid, dialogid, response, listitem, string:inputtext[]) {

		#pragma unused pid, dialogid, inputtext, listitem
		if (response)
		{
			if ( GetPlayerCash ( playerid ) < SERVER_PILOT_FEE ) return true ;

			TakePlayerCash(playerid, SERVER_PILOT_FEE, "Pilot test fee");

			PilotQuestion[playerid] = 0;
			ShowPilotQuestion(playerid, PilotQuestion[playerid]);
		}
	}

	Dialog_ShowCallback ( playerid, using inline DlgPilotTestStart, DIALOG_STYLE_MSGBOX, "Pilot Test Information", PilotDialogStr, "OK", "Back" );
	return true;
}
