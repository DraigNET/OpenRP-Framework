// ============================================================================
// File: property/data/admin.pwn
// Admin property commands: /propertycreate, /propertymove, /propertydelete, /propertygoto, set
// price/type/faction/owner and run auctions. This is how staff build houses and businesses.
// Commands: /propertycreate /propertymove /propertydelete /propertygoto /propgoto
// /propertyprice /propertytype /propertyfaction /propertyowner /propertyauction
// /propertybuytype /propertyextra /propertybuypoint /propertyintid /propintid /propertyinterior
// /propertyworld /propertyintlist /propertyinteriorlist /propertygetid
// ============================================================================

// /propertycreate [price] [type] (tier) - (admin) creates a property at your position. Type 0 =
// house, 1 = business, 2 = static.
CMD:propertycreate(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_BETA ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new price, type, tier ;

	if ( sscanf ( params, "iiI(0)", price, type, tier)) {

		// Kept short on purpose: the client silently drops chat lines over 144 characters.
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertycreate [price] [type: 0 = house, 1 = biz, 2 = static] [house tier 1-5, optional]") ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Price 0 = not buyable. A house with a tier ignores the price. /housetiers shows the tiers.") ;
	}

	if ( tier < 0 || tier > PROPERTY_MAX_TIER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Tier can't be less than 0 or more than 5. See /housetiers.") ;
	}

	if ( type < 0 || type > 2 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Type can't be less than 0 or more than 2.") ;
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos ( playerid, x, y, z ) ;

	Property_OnCreate(playerid, type, x, y, z, GetPlayerInterior ( playerid ), GetPlayerVirtualWorld ( playerid ), price, tier);

	return true ;
}

// /propertymove [id] - (admin) moves a property's entrance to your position.
CMD:propertymove(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id ;

	if ( sscanf ( params, "i", id ) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertymove [id]") ;

	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

    if(Runtime_PropertyEntranceInUse(id)) return SendClientMessage(playerid,COLOR_ERROR,"Wait for active deliveries and burglary sessions before moving this entrance.");
	new Float: x, Float: y, Float: z ;
	GetPlayerPos ( playerid, x, y, z ) ;

	Property [id ] [ E_PROPERTY_EXT_X ] = x;
	Property [id ] [ E_PROPERTY_EXT_Y ] = y;
	Property [id ] [ E_PROPERTY_EXT_Z ] = z;

	Property [id ] [ E_PROPERTY_EXT_VW ] = GetPlayerVirtualWorld(playerid) ;
	Property [id ] [ E_PROPERTY_EXT_INT ] = GetPlayerInterior(playerid) ;

	Property_SetupVisualEntities(id);

	new query [ 1024 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_ext_x = '%f', property_ext_y = '%f', property_ext_z = '%f', property_ext_vw = %d, property_ext_int = %d WHERE property_id = %d",

		Property [id ] [ E_PROPERTY_EXT_X ],
		Property [id ] [ E_PROPERTY_EXT_Y ],
		Property [id ] [ E_PROPERTY_EXT_Z ],
		Property [id ] [ E_PROPERTY_EXT_VW ],
		Property [id ] [ E_PROPERTY_EXT_INT ],
		Property [id ] [ E_PROPERTY_ID ]

	) ;

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've moved property ID %d to your location.", id ) ) ;

	return true ;
}

// /propertydelete [id] - (admin) deletes a property and refunds its owner.
CMD:propertydelete(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id ;

	if ( sscanf ( params, "i", id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertydelete [id]") ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "This property is owned (by a player or a firm)! Use /propertyauction first!") ;
	}


	Furniture_WipeAllContent ( playerid, Property [ id ] [ E_PROPERTY_ID ] ) ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "DELETE FROM `properties` WHERE property_id = %d",

		Property [id ] [ E_PROPERTY_ID ]
	) ;

	mysql_tquery(mysql, query );


	if ( IsValidDynamicPickup( Property [ id ] [ E_PROPERTY_PICKUP ] [ 0 ] ) ) {
		DestroyDynamicPickup(Property [ id ] [ E_PROPERTY_PICKUP ] [ 0 ] ) ;
	}
	Property [ id ] [ E_PROPERTY_PICKUP ] [ 0 ] = INVALID_STREAMER_ID;

	if ( IsValidDynamicPickup( Property [ id ] [ E_PROPERTY_PICKUP ] [ 1 ] ) ) {
		DestroyDynamicPickup(Property [ id ] [ E_PROPERTY_PICKUP ] [ 1 ] ) ;
	}
	Property [ id ] [ E_PROPERTY_PICKUP ] [ 1 ]= INVALID_STREAMER_ID;

	if ( IsValidDynamicArea( Property [ id ] [ E_PROPERTY_AREA ] ) ) {
		DestroyDynamicArea( Property [ id ] [ E_PROPERTY_AREA ] ) ;
	}
	Property [ id ] [ E_PROPERTY_AREA ]= INVALID_STREAMER_ID;
	
	Iter_Remove(Properties, id);

	Property [ id ] [ E_PROPERTY_ID ] = INVALID_PROPERTY_ID ;

	Property [ id ] [ E_PROPERTY_PICKUP ] [ 0 ] = -1 ;
	Property [ id ] [ E_PROPERTY_PICKUP ] [ 1 ] = -1 ;
	Property [ id ] [ E_PROPERTY_AREA ] = -1 ;

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've deleted property ID %d.", id ) ) ;

	return true ;
}

// /propertygoto [id] - (admin) teleports to a property.
CMD:propertygoto(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}


	new id ;

	if ( sscanf ( params, "i", id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertygoto [id]") ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	PauseAC(playerid, 3);
	SetPlayerPos(playerid, Property [ id ] [ E_PROPERTY_EXT_X], Property [ id ] [ E_PROPERTY_EXT_Y], Property [ id ] [ E_PROPERTY_EXT_Z]);
	SetPlayerInterior(playerid, Property [ id ] [ E_PROPERTY_EXT_INT ] ) ;
	SetPlayerVirtualWorld(playerid, Property [ id ] [ E_PROPERTY_EXT_VW ] ) ;

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've teleported to property ID %d", id) ) ;
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("teleported to Property %d (SQL: %d)", id, Property[id][E_PROPERTY_ID]));
	return true ;
}

CMD:propgoto(playerid, params[])
{
	return cmd_propertygoto(playerid, params);
}

// Defined in property/utils/realestate.pwn
forward RealEstate_SetListingPrice(playerid, const params[]);
forward RealEstate_ReturnToServer(index, bool: refund);

// /propertyprice [id] [price] - sets a property's price (0 disables buying it). Real estate
// agents can use it at a door.
CMD:propertyprice(playerid, params[]) {

	// One number is a real estate firm pricing the house at the door, an id and a price is the admin command.
	// Real estate only deals with houses. A senior admin standing at a business (or any non-house) with
	// just a price prices that property directly, instead of being sent down the real estate path.
	new door_params [ 64 ] ;

	format ( door_params, sizeof ( door_params ), "%s", params ) ;

	if ( ! strlen ( params ) || strfind ( params, " " ) == -1 ) {

		new door = Property_GetClosestEntity ( playerid, PROPERTY_NEAR_ENTER ), door_price ;

		if ( door != INVALID_PROPERTY_ID && Property [ door ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE
			&& GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_SENIOR && ! sscanf ( params, "i", door_price ) ) {

			format ( door_params, sizeof ( door_params ), "%d %d", door, door_price ) ;
		}

		else {

			return RealEstate_SetListingPrice ( playerid, params ) ;
		}
	}

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, price ;

	if ( sscanf ( door_params, "ii", id, price) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertyprice [id] [price] (0 disables buying it)") ;
	}

	if ( (price < 2500 || price > 1000000) && price != 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Price can't be less than 2,500 or more than 1,000,000.") ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	new tier = Property [ id ] [ E_PROPERTY_TIER ] ;

	if ( price != 0 && tier > 0 && Property [ id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER && ( price < Property_GetTierMinPrice ( tier ) || price > Property_GetTierMaxPrice ( tier ) ) ) {

		new tier_name [ 24 ] ;
		Property_GetTierName ( tier, tier_name, sizeof ( tier_name ) ) ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", sprintf ( "A tier %d (%s) house has to cost between $%s and $%s.", tier, tier_name, IntegerWithDelimiter ( Property_GetTierMinPrice ( tier ) ), IntegerWithDelimiter ( Property_GetTierMaxPrice ( tier ) ) ) ) ;
	}

	new query [ 256 ] ;

	Property [id ] [ E_PROPERTY_PRICE ] = price ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_price = %d WHERE property_id = %d",

		Property [id ] [ E_PROPERTY_PRICE ],
		Property [id ] [ E_PROPERTY_ID ]

	) ;

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've changed property ID %d's price to $%s", id, IntegerWithDelimiter(price) ) ) ;

	return true ;
}
// /propertytype [id] [type] - (admin) changes a property between house, business and static.
CMD:propertytype(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, type ;

	if ( sscanf ( params, "ii", id, type) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertytype [id] [type]") ;
		SendClientMessage(playerid, 0xDEDEDEFF, "Types: 0) house, 1) business, 2) static");

		return true ;
	}

	
	if ( type < E_PROPERTY_TYPE_HOUSE || type > E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", sprintf("Type can't be less than %d or more than %d.", E_PROPERTY_TYPE_HOUSE, E_PROPERTY_TYPE_STATIC )) ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}
 
	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	new query [ 256 ] ;

	Property [id ] [ E_PROPERTY_TYPE ] = type ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_type = %d WHERE property_id = %d",

		Property [id ] [ E_PROPERTY_TYPE ],
		Property [id ] [ E_PROPERTY_ID ]

	) ;

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've changed property ID %d's type to %d", id, Property [id ] [ E_PROPERTY_TYPE ] ) ) ;

	Property_SetupVisualEntities(id);
	
	return true ;
}

// /propertyfaction [id] [faction] - (admin) restricts a property to a faction.
CMD:propertyfaction(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, factionid;

	if ( sscanf ( params, "ii", id, factionid) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertyfaction [id] [faction SQL id]") ;
	}
	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	new query [ 256 ] ;
	Property [id ] [ E_PROPERTY_FACTION ] = factionid;
	if (factionid > 0) {
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("Changed faction of Property %d (SQL: %d) to %d (%s)", id, Property [ id ] [ E_PROPERTY_ID ], factionid, Faction [ factionid-1 ] [ E_FACTION_NAME ])) ;
		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Changed faction of Property %d (SQL: %d) to %d (%s)", id, Property [ id ] [ E_PROPERTY_ID ], factionid, Faction [ factionid-1 ] [ E_FACTION_NAME ]));
	} else {
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("Changed faction of Property %d (SQL: %d) to %d (None)", id, Property [ id ] [ E_PROPERTY_ID ], factionid)) ;
		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Changed faction of Property %d (SQL: %d) to %d (None)", id, Property [ id ] [ E_PROPERTY_ID ], factionid));
	}

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_faction = %d WHERE property_id = %d", Property [id ] [ E_PROPERTY_FACTION ], Property [id ] [ E_PROPERTY_ID ]);
	mysql_tquery(mysql, query);


	return true ;
}

// /propertyowner [id] [character id] - (admin) sets a property's owner.
CMD:propertyowner(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, owner;

	if ( sscanf ( params, "ii", id, owner) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertyowner [id] [char id]") ;
	}
	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if (owner <= 0)
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid owner char ID entered!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	new query [ 256 ] ;
	inline ReturnCharName() 
	{
		if (!cache_num_rows()) 
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Couldn't find a character with this ID.");
		}

		new charname[32];
		cache_get_value_name(0, "player_name", charname);
		Property [id ] [ E_PROPERTY_OWNER ] = owner;

		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Changed owner of Property %d (SQL: %d) to %s (SQL: %d)", id, Property [ id ] [ E_PROPERTY_ID ], charname, owner));
		SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s changed the owner of Property %d to %s.", playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], id, charname));

		mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d", Property [id ] [ E_PROPERTY_OWNER ], Property [id ] [ E_PROPERTY_ID ]);
		mysql_tquery(mysql, query);
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT `player_name` FROM `characters` WHERE `player_id` = %d", owner ) ;
	MySQL_TQueryInline(mysql, using inline ReturnCharName, query, "");

	return true ;
}

// /propertyauction [id] - (admin) puts a property up for auction.
CMD:propertyauction(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
 
	new id ;

	if ( sscanf ( params, "i", id) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertyauction [id]") ;
	}
	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	// A real estate firm's property: the firm gets what it paid back and the server takes it.
	if ( Property_IsFirmOwned ( id ) ) {

		RealEstate_ReturnToServer ( id, true ) ;

		return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf ( "Property ID %d was taken from its real estate firm, which was refunded.", id ) ) ;
	}

	foreach(new targetid: Player) {

		if ( Character [ targetid ] [ E_CHARACTER_ID ] == Property [ id ] [ E_PROPERTY_OWNER ] ) {

			SendClientMessage(targetid, COLOR_YELLOW, sprintf("WARNING: Your property with ID %d has been sold by an administrator!", id));
			SendClientMessage(targetid, COLOR_RED, "If this was not intended, take a screenshot IMMEDIATELY. To get refunded, relog.");
			SendClientMessage(targetid, COLOR_GRAD0, "The system will automatically refund you a portion of the buy price when you next log in.");
			break ;
		}
	}

	new query [ 256 ] ;

// Setting variable so player gets msg upon logging in & refund
	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_soldproperty = %d WHERE player_id = %d",

		Property [ id ] [ E_PROPERTY_ID ],
		Property [ id ] [ E_PROPERTY_OWNER ]
	);

	mysql_tquery(mysql, query );

	query [ 0 ] = EOS ;

	Property [id ] [ E_PROPERTY_OWNER ] = INVALID_PROPERTY_OWNER ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d",

		Property [id ] [ E_PROPERTY_OWNER ],
		Property [id ] [ E_PROPERTY_ID ]
	) ;

	mysql_tquery(mysql, query );

	
	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've admin sold property ID %d.", id ) ) ;

	return true ;
}

// Refunds a property's stored items and furniture to its owner when it is removed.
Property_RefundPlayer(playerid, id) {


	if ( id > 0 || id < MAX_PROPERTIES ) {
		if ( id >= MAX_PROPERTIES ) {

			return true ;
		} 

		new amount = Property [ id ] [ E_PROPERTY_PRICE ]  ;

		SendClientMessage(playerid, -1, " " ) ;
		SendClientMessage(playerid, COLOR_YELLOW, sprintf("WARNING:{DEDEDE} Your property (ID %d) was sold whilst you were offline. You have been refunded $%s.",
			id, IntegerWithDelimiter ( amount ) ) ) ;
		SendClientMessage(playerid, COLOR_RED, "If you think this was a mistake, post a refund requests with the property ID. ");
		SendClientMessage(playerid, -1, " " ) ;
		
		GivePlayerCash ( playerid, amount, "Auto property refund" ) ;
		Character [ playerid ] [ E_CHARACTER_SOLD_PROPERTY ] = INVALID_PROPERTY_ID ;

		new query [ 256 ] ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_soldproperty = 0 WHERE player_id = %d",
			Character [ playerid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

	}

	return true ;
}


// /propertybuytype [id] [type] - (admin) sets what a business sells (see /buypointtypes).
CMD:propertybuytype(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");


	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, type ;

	if ( sscanf ( params, "ii", id, type ) ) {
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertybuytype [id] [type]") ;
		SendClientMessage(playerid, 0xDEDEDEFF, "Types: Use /buypointtypes");
		return true ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}
	Property [ id ] [ E_PROPERTY_BUY_TYPE ] = type ;


	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_buy_type = %d WHERE property_id = %d", 

		Property [ id ] [ E_PROPERTY_BUY_TYPE ], Property [ id ] [ E_PROPERTY_ID ] ) ;

	mysql_tquery(mysql, query);

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("Set property buy ID %d to type %d.", id, type ) ) ;
	
	Property_SetupVisualEntities(id);
	return true ;
}

// /propertyextra [id] [type] - (admin) sets a business's extra point type.
CMD:propertyextra(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");


	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, type ;

	if ( sscanf ( params, "ii", id, type ) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertyextra [id] [type]") ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	switch ( Property [ id ] [ E_PROPERTY_BUY_TYPE ] ) {
		case E_BUY_TYPE_DEALERSHIP: {

			SendClientMessage(playerid, COLOR_YELLOW, "This will set the type of cars the business will sell.");
			SendClientMessage(playerid, COLOR_RED, "It also sets the position where the cars will spawn! Make sure to place it proper!");

			new Float: x, Float: y, Float: z ;
			GetPlayerPos(playerid, x, y, z ) ;

			Property [ id ] [ E_PROPERTY_EXTRA_TYPE ] = type ;

			Property [ id ] [ E_PROPERTY_EXTRA_POS_X ] = x ;
			Property [ id ] [ E_PROPERTY_EXTRA_POS_Y ] = y ;
			Property [ id ] [ E_PROPERTY_EXTRA_POS_Z ] = z ;

			Property [ id ] [ E_PROPERTY_EXTRA_POS_INT ] = GetPlayerInterior(playerid);
			Property [ id ] [ E_PROPERTY_EXTRA_POS_VW ] = GetPlayerVirtualWorld(playerid);

			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("Property ID %d 's extra type has been set to %d.",
				id, type )) ;

			new query [ 256 ] ;

			mysql_format(mysql, query, sizeof ( query ) , "UPDATE properties SET property_extra_type = %d, property_extra_pos_x = '%f',\
				property_extra_pos_y = '%f', property_extra_pos_z = '%f', property_extra_pos_int = %d, property_extra_pos_vw = %d WHERE property_id = %d",
					Property [ id ] [ E_PROPERTY_EXTRA_TYPE ],
					Property [ id ] [ E_PROPERTY_EXTRA_POS_X ],
					Property [ id ] [ E_PROPERTY_EXTRA_POS_Y ],
					Property [ id ] [ E_PROPERTY_EXTRA_POS_Z ],
					Property [ id ] [ E_PROPERTY_EXTRA_POS_INT ],
					Property [ id ] [ E_PROPERTY_EXTRA_POS_VW ],
					Property [ id ] [ E_PROPERTY_ID]
				);

			mysql_tquery(mysql, query);

			return true ;
		}
	}
	
	SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "The business ID you entered can't have extras assigned to them.") ;

	return true ;
}

// /propertybuypoint [id] - (admin) moves a business's buy point to your position.
CMD:propertybuypoint(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id ;

	if ( sscanf ( params, "i", id ) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertybuypoint [id]") ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	switch ( Property [ id ] [ E_PROPERTY_BUY_TYPE ] ) {
		case E_BUY_TYPE_DEALERSHIP, E_BUY_TYPE_GASSTATION, E_BUY_TYPE_MODSHOP: {
			return SendClientMessage(playerid, -1, "This business can't have buytypes assigned.");
		}
	}

	if ( Property [ id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ  ) {

		return SendClientMessage(playerid, -1, "Only businesses can sell wares.");
	}

	if ( ! Property [ id ] [ E_PROPERTY_BUY_TYPE ] ) {

		return SendClientMessage(playerid, -1, "This property isn't permitted to sell wares.");
	}

	new Float: x , Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	Property [ id ] [ E_PROPERTY_BUY_POS_X ] = x;
	Property [ id ] [ E_PROPERTY_BUY_POS_Y ] = y;
	Property [ id ] [ E_PROPERTY_BUY_POS_Z ] = z;

	Property [ id ] [ E_PROPERTY_BUY_POS_VW ] = GetPlayerVirtualWorld(playerid);
	Property [ id ] [ E_PROPERTY_BUY_POS_INT ] = GetPlayerInterior(playerid);

	Property_SetupVisualEntities(id);

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_buy_pos_x = '%f',\
		property_buy_pos_y = '%f', property_buy_pos_z = '%f', property_buy_pos_vw = %d, property_buy_pos_int = %d WHERE property_id = %d", 
			Property [ id ] [ E_PROPERTY_BUY_POS_X ],
			Property [ id ] [ E_PROPERTY_BUY_POS_Y ],
			Property [ id ] [ E_PROPERTY_BUY_POS_Z ],
			Property [ id ] [ E_PROPERTY_BUY_POS_VW ],
			Property [ id ] [ E_PROPERTY_BUY_POS_INT ],

		Property [ id ] [ E_PROPERTY_ID ] ) ;

	mysql_tquery(mysql, query);

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "Moved property's buy point to your location." ) ;

	return true ;
}

// /propertyintid [id] [interior world] - (admin) sets only the interior id of a property's inside.
CMD:propertyintid(playerid, params[]) 
{
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id, interior;
	if ( sscanf ( params, "dd", id, interior ) ) 
	{
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertyintid [property id] [interior world id]") ;
		return SendClientMessage(playerid, 0xDEDEDEFF, "This sets only the interior ID.");
	}

	if ( id < 0 || id >= MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	Property [ id ] [ E_PROPERTY_INT_INT ] = interior;
	new query [ 128 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_int_int = %d WHERE property_id = %d",
		Property [ id ] [ E_PROPERTY_INT_INT ],
		Property [ id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);
	SendClientMessage(playerid, COLOR_GRAD1, sprintf("You changed the interior ID of property %d to %d.", id, interior));

	return true;
}

CMD:propintid(playerid, params[]) {

	return cmd_propertyintid(playerid, params);
}

// /propertyinterior [id] - (admin) sets a property's interior to where you are standing.
CMD:propertyinterior(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new id; 

	if ( sscanf ( params, "i", id ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertyint(erior) [id]") ;
		return SendClientMessage(playerid, 0xDEDEDEFF, "Warning: this sets your current location (+ interior) to the entered ID's interior!");
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	Property [ id ] [ E_PROPERTY_INT_X ] = x;
	Property [ id ] [ E_PROPERTY_INT_Y ] = y;
	Property [ id ] [ E_PROPERTY_INT_Z ] = z;
	Property [ id ] [ E_PROPERTY_INT_INT ] = GetPlayerInterior(playerid) ;

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("Property %d's interior location has been set to your current position.", id ) ) ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_int_x = '%f', property_int_y = '%f', property_int_z = '%f', property_int_int = %d, property_int_vw = %d WHERE property_id = %d",
		Property [ id ] [ E_PROPERTY_INT_X ],
		Property [ id ] [ E_PROPERTY_INT_Y ],
		Property [ id ] [ E_PROPERTY_INT_Z ],
		Property [ id ] [ E_PROPERTY_INT_INT ],
		Property [ id ] [ E_PROPERTY_INT_VW ],
		Property [ id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);

	PauseAC(playerid, 3);
	SetPlayerPos(playerid, Property [ id ] [ E_PROPERTY_EXT_X ], Property [ id ] [ E_PROPERTY_EXT_Y ], Property [ id ] [ E_PROPERTY_EXT_Z ] ) ;
	SetPlayerInterior(playerid, Property [ id ] [ E_PROPERTY_EXT_INT ] );
	SetPlayerVirtualWorld(playerid, Property [ id ] [ E_PROPERTY_EXT_VW ] );

	SendClientMessage(playerid, COLOR_GRAD1, "Warning: You've been teleported to the front door for security measures.");

	return true ;
}

// /propertyworld [id] [vw] - (admin) sets a property's interior virtual world.
CMD:propertyworld(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is applying. Try again shortly.");

    if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

        return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
    }

    new id, vw;

    if ( sscanf ( params, "ii", id, vw ) ) {

        SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertyworld [id] [vw]") ;
        return SendClientMessage(playerid, 0xDEDEDEFF, "Sets the property's interior virtual world.");
    }

    Property[id][E_PROPERTY_INT_VW] = vw;

    // Sync player immediately (so no desync issues)
    SetPlayerVirtualWorld(playerid, vw);

    SendServerMessage(playerid, COLOR_PROPERTY, "Property", "A3A3A3",
        sprintf("Property %d's virtual world has been set to %d.", id, vw)
    );

    new query[128];

    mysql_format(mysql, query, sizeof(query),
        "UPDATE properties SET property_int_vw = %d WHERE property_id = %d",
        vw,
        Property[id][E_PROPERTY_ID]
    );

    mysql_tquery(mysql, query);

    return true;
}

CMD:propertyintlist(playerid, params[]) {

	return cmd_propertyinteriorlist(playerid, params);
}
// /propertyinteriorlist - (admin) lists the stock interiors to pick from.
CMD:propertyinteriorlist(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	SendClientMessage(playerid, COLOR_GRAD1, "Click on the list to teleport to the interior.");
	SendClientMessage(playerid, COLOR_GRAD1, "Use /propertysetint to set the interior to your location.");

	Interior_ListNatives (playerid ) ;

	return true ;
}

// /propertygetid [SQL id] - (admin) converts a property's SQL id to its in-game id.
CMD:propertygetid(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new sqlid; 
	if ( sscanf ( params, "i", sqlid ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "DEDEDE", "/propertygetid [SQL id]") ;
	}

	new id = Property_GetEnumID(sqlid);
	if (id == INVALID_PROPERTY_ID) SendClientMessage(playerid, COLOR_GRAD1, "Invalid property SQL ID.");
	
	return SendClientMessage(playerid, COLOR_GRAD1, sprintf("Property ID of SQL ID %d is %d.", sqlid, id));
}
