// ============================================================================
// File: chopshop/owner.pwn
// Chop shop ownership: a faction runs the chop shop (/chopshopfaction) and collects the
// earnings (/chopshopcollect).
// Commands: /chopshopfaction /chopshopcollect
// ============================================================================

// Loads the faction that owns the chop shop from the server settings and creates its label.
ChopShop_LoadEntities() { return UpdateChopShopLabel(); }

// Redraws the chop shop's 3D label with the owning faction's name.
UpdateChopShopLabel() {
    if(!IsValidDynamic3DTextLabel(Server[E_SERVER_CHOPSHOP_LABEL])) return 1;

	new string [ 256 ] ;

	new factionid = Server [ E_SERVER_CHOPSHOP_FACTIONID ] ;
	new faction_name [ 64 ] ;

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		format ( faction_name, sizeof ( faction_name ), "Unowned" ) ;
	}

	else format ( faction_name, sizeof ( faction_name ), "%s", Faction [ faction_enum_id ] [ E_FACTION_ABBREV ] ) ;


	format ( string, sizeof ( string ), 
		"[Chop Shop]{DEDEDE}\nAvailable Commands: /chopcar, /buylockpick" ) ;

	UpdateDynamic3DTextLabelText(Server [ E_SERVER_CHOPSHOP_LABEL ], 0x5B381FFF, 
		string
	) ;

	return true ;
}

// /chopshopfaction [faction id] - (admin) sets which faction owns the chop shop.
CMD:chopshopfaction(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new factionid ;

	if ( sscanf ( params, "i", factionid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/chopshopfaction [faction-id] (NOT SQL!)");
	}

	if ( Faction [ factionid ] [ E_FACTION_ID ] == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This faction does not exist.");	
	} 

	Server [ E_SERVER_CHOPSHOP_FACTIONID ] = Faction [ factionid ] [ E_FACTION_ID ];

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE server SET server_chopshop_factionid = %d", Server [ E_SERVER_CHOPSHOP_FACTIONID ] ) ;
	mysql_tquery(mysql, query);

	UpdateChopShopLabel() ;

	Faction_SendMessage(Faction [ factionid ] [ E_FACTION_ID], sprintf("{ [%s] The faction has taken control over the chopshop. }",

		Faction [ factionid ] [ E_FACTION_ABBREV ]
	), factionid, false ) ;

	format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has given chop-shop control to %s.", 
		ReturnRPName ( playerid ), Faction [ factionid ] [ E_FACTION_ABBREV ] ) ;
	SendAdminMessage(query) ;
	
	return true ;
}

// /chopshopcollect - lets the owning faction's leaders collect the chop shop's earnings.
CMD:chopshopcollect(playerid, params[]) {

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	if (Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] != 1 ) {
		// 1 : owner, 2: command, 3 : member

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to do this.");
	}

	if ( Faction [ faction_enum_id ] [ E_FACTION_ID ] != Server [ E_SERVER_CHOPSHOP_FACTIONID ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your faction doesn't own the chop shop.");
	}

	if ( ! Runtime_AtLocation(playerid,RT_LOC_CHOPSHOP) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near the chopshop!");
	}

	Faction_AddBankMoney(faction_enum_id, Server[E_SERVER_CHOPSHOP_COLLECT], "Chopshop Income");

	Faction_SendMessage(Faction [ faction_enum_id ] [ E_FACTION_ID], sprintf("{ [%s] %s has collected $%s from the chop-shop (faction bank). }",

		Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], ReturnRPName ( playerid ), IntegerWithDelimiter ( Server [ E_SERVER_CHOPSHOP_COLLECT ] )
	), faction_enum_id, false ) ;

	Server [ E_SERVER_CHOPSHOP_COLLECT ]  = 0 ; 

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE server SET server_chopshop_collect = 0" ) ;
	mysql_tquery(mysql, query);

	UpdateChopShopLabel() ;
	
	return true ;
}
