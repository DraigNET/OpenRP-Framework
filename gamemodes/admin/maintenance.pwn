// ============================================================================
// File: admin/maintenance.pwn
// Scheduled server maintenance: /maintenance starts a countdown, warns players, saves everyone
// and shuts the server down cleanly (Maintenance, FinishMaintenance, ShutDown).
// Commands: /maintenance
// ============================================================================

#include <YSI_Coding\y_hooks>

new SystemUpdate, SystemTimer;
new Text:UpdateIn[2] = Text: INVALID_TEXT_DRAW ;

hook OnGameModeInit() {
	UpdateIn[0] = TextDrawCreate(465, 431.007720, "Server_update_in:");
	TextDrawLetterSize(UpdateIn[0], 0.424666, 1.612444);
	TextDrawAlignment(UpdateIn[0], 1);
	TextDrawColor(UpdateIn[0], -1);
	TextDrawSetShadow(UpdateIn[0], 0);
	TextDrawSetOutline(UpdateIn[0], 1);
	TextDrawBackgroundColor(UpdateIn[0], 255);
	TextDrawFont(UpdateIn[0], 1);
	TextDrawSetProportional(UpdateIn[0], 1);
	TextDrawSetShadow(UpdateIn[0], 0);

	UpdateIn[1] = TextDrawCreate(595.0, 431.007720, "00:00");
	TextDrawLetterSize(UpdateIn[1], 0.424666, 1.612444);
	TextDrawAlignment(UpdateIn[1], 1);
	TextDrawColor(UpdateIn[1], -1);
	TextDrawSetShadow(UpdateIn[1], 0);
	TextDrawSetOutline(UpdateIn[1], 1);
	TextDrawBackgroundColor(UpdateIn[1], 255);
	TextDrawFont(UpdateIn[1], 1);
	TextDrawSetProportional(UpdateIn[1], 1);
	TextDrawSetShadow(UpdateIn[1], 0);
	return 1;
}

hook OnPlayerConnect(playerid) {
	if(SystemUpdate > 0) {
		TextDrawShowForPlayer(playerid, UpdateIn[0]);
		TextDrawShowForPlayer(playerid, UpdateIn[1]);
	}
}

// /maintenance - (lead admin+) schedules server maintenance with a countdown; players are warned
// to log out.
CMD:maintenance(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendClientMessage ( playerid, COLOR_ERROR, "You're not authorized to perform this action." ) ;
	}

	inline MaintenanceHandler(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext, listitem
		new string [ 256 ] ;

		if(response) {
			if(isnull(inputtext)) {

				return SendClientMessage(playerid, COLOR_ERROR, "Enter a valid value." ) ;
			}

			if (strval(inputtext) == 0 && SystemUpdate != 0)
			{
				TextDrawHideForAll(UpdateIn[0]);
				TextDrawHideForAll(UpdateIn[1]);
				KillTimer(SystemTimer);
				SystemUpdate = 0;

				format ( string, sizeof ( string ), "[!!!] [AdmWarn] %s has cancelled the scheduled maintenance.", Account[playerid][E_PLAYER_ACCOUNT_NAME] ) ;
				SendAdminMessage(string) ;
				return true;
			}

			if(!(30 <= strval(inputtext) < 21600)) {

				return SendClientMessage ( playerid, COLOR_ERROR, "Timer can't be less than 30 or longer than 21600.");
			}

			if(SystemUpdate == 0)
			{
				SendClientMessageToAll(-1, "" ) ;
				SendClientMessageToAll(-1, "" ) ;
				SendClientMessageToAll(COLOR_BLUE, "* The server will be going down for Scheduled Maintenance. (See bottom right screen)");
				SendClientMessageToAll(COLOR_YELLOW, "! End your scenes A.S.A.P. and don't engage in new activities until after the restart !") ;
				SendClientMessageToAll(-1, "" ) ;
				SendClientMessageToAll(-1, "" ) ;

				GameTextForAll("~n~~n~~n~~n~~y~] Scheduled Maintenance Alert ]", 5000, 3);
			}
			
		    SystemUpdate = strval(inputtext);
		    format(string, sizeof(string), "%s", STimeConvert(SystemUpdate));
		    TextDrawShowForAll(UpdateIn[0]);
		    TextDrawSetString(UpdateIn[1], string);
		    TextDrawShowForAll(UpdateIn[1]);
		    if(SystemUpdate != 0) KillTimer(SystemTimer);
		    SystemTimer = SetTimer("MaintenanceTimer", 1000, true);

	    	format ( string, sizeof ( string ), "[!!!] [AdmWarn] %s has scheduled server maintenance in %d seconds.", Account[playerid][E_PLAYER_ACCOUNT_NAME], strval(inputtext) ) ;
			SendAdminMessage(string) ;

			AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Scheduled server maintenance in %d seconds.", strval(inputtext)));
		}
		else SendClientMessage(playerid, COLOR_WHITE, "You have cancelled doing a maintenance restart.");
	}

	Dialog_ShowCallback ( playerid, using inline MaintenanceHandler, DIALOG_STYLE_INPUT, "How long should the timer run?", "Please specify in seconds how long before the server kicks all users & shuts down?\n\nWARNING: This action can't be undone!", "Shutdown", "Exit");

    return 1;
}

forward MaintenanceTimer();
// Timer: ticks the maintenance countdown once a second, warns players at 15 seconds and starts
// Maintenance() at zero.
public MaintenanceTimer() {
	new string[6];
	if(--SystemUpdate <= 0) KillTimer(SystemTimer), Maintenance();
	if(SystemUpdate == 15) GameTextForAll("~n~~n~~n~~n~~w~Please ~r~log out ~w~now to ensure ~y~account data ~w~has been ~g~saved~w~!", 5000, 3);
	if(SystemUpdate < 0) SystemUpdate = 0;
	format(string, sizeof(string), "%s", STimeConvert(SystemUpdate));
	TextDrawSetString(UpdateIn[1], string);
	TextDrawShowForAll(UpdateIn[1]);
	return 1;
}

// Converts a number of seconds into a MM:SS string for the countdown.
STimeConvert(time) {
    new jmin;
    new jsec;
    new string[128];
	if(time > 59 && time < 3600){
        jmin = floatround(time/60);
        jsec = floatround(time - jmin*60);
        format(string,sizeof(string),"%02d:%02d",jmin,jsec);
    }
    else{
        jsec = floatround(time);
        format(string,sizeof(string),"00:%02d",jsec);
    }
    return string;
}

forward Maintenance();
// Starts maintenance: freezes players, tells them to log out and locks the server with the
// password from config/secrets.pwn.
public Maintenance()
{
    foreach(new i: Player)
	{
		TogglePlayerControllable(i, false);
		GameTextForPlayer(i, "Scheduled Maintenance..~n~~n~~w~Please ~r~log out ~w~now to ensure ~y~account data ~w~has been ~g~saved~w~!", 66000, 5);

	}

	SendRconCommand("password " SERVER_PASSWORD); // set in config/secrets.pwn
	SendRconCommand(sprintf("hostname [!] %s -> Restarting", SERVER_NAME));
	SetTimer("FinishMaintenance", 60000, false);

	return 1;
}

forward FinishMaintenance();
// Finishes maintenance: marks every character offline in the database, saves the server, then
// shuts the server down.
public FinishMaintenance()
{
    new query[128];

    // ----------------------------------------
    // Force all characters offline
    // ----------------------------------------
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_online = 0 WHERE player_online = 1"
    );
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET player_on_duty = 0 WHERE player_on_duty = 1"
    );
    mysql_tquery(mysql, query);

    // ----------------------------------------
    // Force all accounts offline (IMPORTANT)
    // ----------------------------------------
    mysql_format(mysql, query, sizeof(query),
        "UPDATE accounts SET account_online = 0 WHERE account_online = 1"
    );
    mysql_tquery(mysql, query);

    // ----------------------------------------
    // Kick all connected players
    // ----------------------------------------
    foreach (new i : Player)
    {
        SendClientMessage(i, COLOR_RED,
            "You've been kicked from the server because the server is restarting."
        );
        KickPlayer(i);
    }

    SetTimer("ShutDown", 5000, false);
    return 1;
}


forward ShutDown();
// Shuts the server down with the `exit` rcon command.
public ShutDown()
{
	return SendRconCommand("exit");
}
