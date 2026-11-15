// ============================================================================
// File: message/annonated.pwn
// /ame and /amy: show a roleplay action above the player's head as well as in chat.
// Commands: /ame /amy
// ============================================================================

CMD:ame(playerid, params[]) 
{
	new text [ 144 ];

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/ame [text]" ) ;
	}
	new string[150];
	format(string, sizeof(string), "> %s %s", ReturnSettingsName(playerid, playerid, .masked=true), text);

	SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 3000 + (strlen(text) * 60));
	SendClientMessage(playerid, COLOR_ACTION, sprintf("> * %s %s", ReturnSettingsName(playerid, playerid, .masked=true), text));
	
	AddLogEntry(playerid, LOG_TYPE_ACTION, string);
	return true ;
}

CMD:amy(playerid, params[]) 
{
	new text [ 144 ];

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/amy [text]" ) ;
	}
	new string[150];
	format(string, sizeof(string), "> %s's %s", ReturnSettingsName(playerid, playerid, .masked=true), text);

	SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 3000 + (strlen(text) * 60));
	SendClientMessage(playerid, COLOR_ACTION, sprintf("> * %s's %s", ReturnSettingsName(playerid, playerid, .masked=true), text));
	
	AddLogEntry(playerid, LOG_TYPE_ACTION, string);
	return true ;
}
