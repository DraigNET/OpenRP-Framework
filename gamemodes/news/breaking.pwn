// ============================================================================
// File: news/breaking.pwn
// Breaking news announcements to every player (/breaking for news staff, /adminbreaking for
// admins).
// Commands: /adminbreaking /breaking
// ============================================================================


static breakingcooldown = 0;

// /adminbreaking [text] - (staff) sends a breaking news line to everyone.
CMD:adminbreaking(playerid, params[])
{
    new text[128], str[144];

    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) return SendServerMessage (playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this." );

	if (sscanf ( params, "s[128]", text )) 
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/adminbreaking [text]" ) ;

	format ( str, sizeof ( str ), "[BREAKING NEWS] %s", text ) ;
	new dc_str[128];
	format ( dc_str, sizeof ( dc_str ), "Anonymous Reporter: %s", text ) ;

	foreach(new targetid: Player) 
    {
		ZMsg_SendClientMessage ( targetid, 0xff2a00FF, str);
	}

	DCC_SendBreakingMessage(dc_str);

    SendAdminMessage(sprintf("[Last /adminbreaking was done by (%d) %s [%s].]", playerid, Character [ playerid ] [ E_CHARACTER_NAME ], Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ] ) ) ;
	return true ;
}


// /breaking [text] - a news faction member sends a breaking news line to everyone (and Discord).
CMD:breaking(playerid, params[])
{
    new text[128], str[176], dc_str[176];

	if (sscanf ( params, "s[128]", text ))
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/breaking [text]" ) ;

    if (!IsPlayerInNewsFaction(playerid, true))
        return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a news faction." ) ;

    if (breakingcooldown && (gettime() - breakingcooldown) < 60)
        return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You must wait before sending another breaking news alert." ) ;

	new outlet[MAX_BROADCAST_OUTLET];
	GetPlayerOutletName(playerid, outlet, sizeof(outlet));

	if (outlet[0] != EOS)
	{
		format ( str, sizeof ( str ), "[BREAKING NEWS] %s (%s): %s", ReturnRPName(playerid), outlet, text ) ;
		format ( dc_str, sizeof ( dc_str ), "Reporter %s (%s): %s", ReturnRPName(playerid), outlet, text ) ;
	}
	else
	{
		format ( str, sizeof ( str ), "[BREAKING NEWS] %s: %s", ReturnRPName(playerid), text ) ;
		format ( dc_str, sizeof ( dc_str ), "Reporter %s: %s", ReturnRPName(playerid), text ) ;
	}

	foreach(new targetid: Player)
    {
		ZMsg_SendClientMessage ( targetid, 0xff2a00FF, str);
	}

	DCC_SendBreakingMessage(dc_str);
    breakingcooldown = gettime();
	
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("[breaking news]: %s", text));
	return true ;
}
