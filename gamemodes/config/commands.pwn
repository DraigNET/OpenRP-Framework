// ============================================================================
// File: config/commands.pwn
// Small general-purpose player commands: /credits, clearing your chat (/cc, /cls...),
// /servertime and /viewmotd.
// Commands: /credits /clearmychat /cmc /clearchat /chatclear /cls /clear /servertime /viewmotd
// ============================================================================

#define LOGIN_DIV   "{555555}----------------------------------------"

// /credits - lists the people who contributed to the script.
CMD:credits(playerid) {

	SendClientMessage(playerid, COLOR_ORANGE, "OpenRP Framework is based on SP-RP. Thanks to everyone who contributed to it:" ) ;

	SendClientMessage(playerid, COLOR_BLUE, "[Project lead]:" ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "Torque:{DEDEDE} project lead, and the bulk of the major reworked code, including the UCP and ACP." ) ;

	SendClientMessage(playerid, COLOR_BLUE, "[Original gamemode]:" ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "DignitySAMP (PXL-DavyL):{DEDEDE} creator of the original SP-RP gamemode." ) ;

	SendClientMessage(playerid, COLOR_BLUE, "[Major contributions]:" ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "Spooky/Sporky:{DEDEDE} QoL changes and a large part of the early rewrite." ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "Rusu:{DEDEDE} bug fixes and QoL changes throughout the project." ) ;

	SendClientMessage(playerid, COLOR_BLUE, "[Minor contributions]:" ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "Matz:{DEDEDE} basketball. LorenC: pool script." ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "LS-RP (DamianC):{DEDEDE} the early furniture list. Shabo/plsegott: the old food and drink prop system." ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "PatrickGTR, Kubi and Patryk:{DEDEDE} open sourcing small systems used here." ) ;
	SendClientMessage(playerid, COLOR_ORANGE, "DTVSamp:{DEDEDE} minor QoL changes." ) ;

	return true ;
}




// /clearmychat (/cc, /cls) - clears your own chat window.
CMD:clearmychat(playerid) 
{
	for (new i, j = 10; i < j; i ++ ) 
	{
		SendClientMessage(playerid, -1, " " );
	}

	return true;
}

CMD:cmc(playerid) return cmd_clearmychat(playerid);
CMD:clearchat(playerid) return cmd_clearmychat(playerid);
CMD:chatclear(playerid) return cmd_clearmychat(playerid);
CMD:cls(playerid) return cmd_clearmychat(playerid);
CMD:clear(playerid) return cmd_clearmychat(playerid);

CMD:servertime ( playerid, params [] ) {

	new string [ 128 ] ;

	format ( string, sizeof ( string ), "The current OOC server date/time is %s(GMT +1)", ReturnDateTime () ) ;
	SendClientMessage ( playerid, 0xDEDEDEFF, string ) ;
	string[0] = EOS ;

	format ( string, sizeof ( string ), "The IC date is the OOC date. You can use the server time to specify" ) ;
	SendClientMessage ( playerid, 0xDEDEDEFF, string ) ;
	format ( string, sizeof ( string ), "the time of events of business opening etc. But use the IC time for roleplay." ) ;
	SendClientMessage ( playerid, 0xDEDEDEFF, string ) ;
	/*format ( string, sizeof ( string ), "The current IC [[roleplay universe]] date/time is %.02d/%.02d/2025 %.0d:%.02d",
		Server [ E_SERVER_TIME_DAYS ], Server [ E_SERVER_TIME_MONTHS ],
		Server [ E_SERVER_TIME_HOURS ], Server [ E_SERVER_TIME_MINUTES ]

	);
	SendClientMessage ( playerid, 0xDEDEDEFF, string ) ;*/


	return true ;
}

// /viewmotd - shows the message of the day.
CMD:viewmotd(playerid) {

	SendClientMessage(playerid, 0xD1B68DFF, "===={DBB275}===={D5A04E}===={DE921F}===={DEDEDE} [{C87900} MOTD {DEDEDE} ] {DE921F}===={D5A04E}===={DBB275}===={D1B68D}====" ) ;

	if ( strlen ( Server [ E_SERVER_MOTD_STRING_1 ] ) > 1) {
		SendClientMessage(playerid, -1, Server [ E_SERVER_MOTD_STRING_1 ] );
	}

	if ( strlen ( Server [ E_SERVER_MOTD_STRING_2 ] ) > 1) {
		SendClientMessage(playerid, -1, Server [ E_SERVER_MOTD_STRING_2 ] );
	}

	if ( strlen ( Server [ E_SERVER_MOTD_STRING_3 ] ) > 1) {
		SendClientMessage(playerid, -1, Server [ E_SERVER_MOTD_STRING_3 ] );
	}

	SendClientMessage(playerid, 0xD1B68DFF, "===={DBB275}===={D5A04E}===={DE921F}===={C87900}========{DE921F}===={D5A04E}===={DBB275}===={D1B68D}====" ) ;

	SendClientMessage(playerid, 0xDEDEDEAA, sprintf("Last updated by %s.", Server [ E_SERVER_MOTD_EDITOR ] ) ) ;

	return true ;
}
