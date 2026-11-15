// ============================================================================
// File: property/func/gui.pwn
// Property HUD: the name and address label shown when a player nears an entrance.
// ============================================================================

#include <YSI_Coding\y_hooks>

// Set from OnPlayerGiveDamage when two players hurt each other; checked in Property_Enter.
new PlayerLastCombatAt[MAX_PLAYERS];

hook OnPlayerDisconnect(playerid, reason) {

    PlayerLastCombatAt[playerid] = 0;

    PlayerTextDrawDestroy(playerid, house_info_box[playerid]);
	return 1;
}

hook OnPlayerConnect(playerid) {

	house_info_box[playerid] = CreatePlayerTextDraw(playerid, 330.0000, 395.0000, "_");
	PlayerTextDrawFont(playerid, house_info_box[playerid], 1);
	PlayerTextDrawLetterSize(playerid, house_info_box[playerid], 0.2500, 1.0000);
	PlayerTextDrawAlignment(playerid, house_info_box[playerid], 2);
	PlayerTextDrawColor(playerid, house_info_box[playerid], -1);
	PlayerTextDrawSetShadow(playerid, house_info_box[playerid], 0);
	PlayerTextDrawSetOutline(playerid, house_info_box[playerid], 1);
	PlayerTextDrawBackgroundColor(playerid, house_info_box[playerid], 255);
	PlayerTextDrawSetProportional(playerid, house_info_box[playerid], 1);
	PlayerTextDrawTextSize(playerid, house_info_box[playerid], 0.0000, 500.0000);

    return 1;
}

hook OnPlayerEnterDynArea(playerid, STREAMER_TAG_AREA:areaid) {
	// name holds "~x~" (3) + property name (up to 64) + "~w~" (3) = up to 70 chars;
	// address is later rebuilt as name + "~n~" + address, so both need headroom
	// or the trailing tilde code gets truncated -> "Unmatched tilde" on render.
	new name[80], address [ 160 ], zone [ 64 ], city[32] ;

	new Float: z ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] != -1 ) {

			if ( Property [ i ] [ E_PROPERTY_AREA ] == areaid ) {

				// Fix against the hud showing up wehn you're under / above the point
				GetPlayerPos ( playerid, z, z, z ) ;

				if ( (z - 1.5 ) > Property [ i ] [ E_PROPERTY_EXT_Z ] ) {

					return false ;
				}

				if ( (z + 1.5 ) < Property [ i ] [ E_PROPERTY_EXT_Z ] ) {

					return false ;
				}

				GetCoords2DZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
				GetPlayerAddress(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], address );
				GetCoords2DMainZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], city, sizeof ( city ) ) ;

				PlayerVar[playerid][E_PLAYER_PROPERTY_ENTER_IDX] = i;
				PlayerVar[playerid][E_PLAYER_AT_PROPERTY_ENTER] = true;

				if (strlen(Property [ i ] [ E_PROPERTY_NAME ]) && strcmp(Property [ i ] [ E_PROPERTY_NAME ], "Undefined", true))
				{
					new name_style[4];
					format ( name_style, sizeof ( name_style ), "~w~" ) ;

					switch(Property [ i ] [ E_PROPERTY_NAME_COLOR ]) 
					{
						case 1: format ( name_style, sizeof ( name_style ), "~r~" ) ;
						case 2: format ( name_style, sizeof ( name_style ), "~g~" ) ;
						case 3: format ( name_style, sizeof ( name_style ), "~b~" ) ;
						case 4: format ( name_style, sizeof ( name_style ), "~y~" ) ;
						case 5: format ( name_style, sizeof ( name_style ), "~p~" ) ;
						case 6: format ( name_style, sizeof ( name_style ), "~l~" ) ;
					}

					format(name, sizeof(name), "%s%s~w~", name_style, Property [ i ] [ E_PROPERTY_NAME ]);
					format(address, sizeof(address), "%s~n~%s", name, address);
				}

				if ( Property_IsFirmOwned ( i ) && ! Property_HasAccess ( playerid, i ) ) {

					new firm_name [ 64 ] ;
					Firm_GetName ( Property [ i ] [ E_PROPERTY_FIRM ], firm_name, sizeof ( firm_name ) ) ;

					if ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] > 0 ) {

						PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~r~For Sale: $%s~n~~g~%s", address, i, zone, city, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_FIRM_PRICE ]), firm_name ) ) ;
					}

					else PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~g~Owned by %s", address, i, zone, city, firm_name ) ) ;
				}

				else if ( Property [ i ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER && Property [ i ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_HOUSE ) {

					PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~%s", address, i, zone, city, ( Property [ i ] [ E_PROPERTY_TIER ] > 0 ) ? ("~y~Real estate firms only") : ("~r~Not available") ) ) ;
				}

				else if ( Property [ i ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

					if ( Property [ i ] [ E_PROPERTY_PRICE ] > 0 ) 
					{
						PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~r~For Sale: $%s", address, i, zone, city, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_PRICE ]) ) ) ;
					}
					else 
					{
						if ( Property [ i ] [ E_PROPERTY_FEE ] > 0 ) 
						{
							PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~p~Entry Fee: $%s", address, i, zone, city, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_FEE ])) ) ;
						}
						else 
						{
							PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~Press ~p~~k~~GROUP_CONTROL_BWD~~w~ to enter", address, i, zone, city) ) ;
						}
					}
				}

				else {

					if ( Property_HasAccess ( playerid, i ) ) {
						if ( Property [ i ] [ E_PROPERTY_FEE ] > 0 ) {

							PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~b~This is your property~n~~p~Entry Fee: $%s", address, i, zone, city, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_FEE ])) ) ;
						}

						else PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~b~This is your property~n~~w~Press ~p~~k~~GROUP_CONTROL_BWD~~w~ to enter", address, i, zone, city ) ) ;
						SendClientMessage(playerid, -1, sprintf("You own this property (%d). Use /propertyhelp to manage it.", i ) ) ;
					}

					else {
						if ( Property [ i ] [ E_PROPERTY_FEE ] > 0 ) {

							PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~g~Player Owned~n~~p~Entry Fee: $%s", address, i, zone, city, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_FEE ])) ) ;
						}

						else PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, %s~n~~g~Player Owned", address, i, zone, city ) ) ;	
					}
				}

				PlayerTextDrawShow(playerid, house_info_box[playerid] );

				if ( Property [ i ] [ E_PROPERTY_RENT ] ) {

					if ( PlayerVar [ playerid ] [ E_PLAYER_RENT_WARNING ] != i ) {

						if ( Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] != i ) {

							ShowPlayerInfoMessage( playerid, 
								sprintf("This property (%d) is rentable for $%s! Use /rentroom to rent it.",
									i, IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_RENT ]) ) , 
							.showtime = 6000 ) ;
						}

						else if ( Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] == i ) {
							ShowPlayerInfoMessage( playerid, 
								sprintf("You're renting this property for $%s. To unrent use /unrentroom.", 
									IntegerWithDelimiter(Property [ i ] [ E_PROPERTY_RENT ] )) ,
							 .showtime = 6000 ) ;
						}

						PlayerVar [ playerid ] [ E_PLAYER_RENT_WARNING ] = i ;
					}
				}

				Streamer_Update(playerid, STREAMER_TYPE_PICKUP ) ;
			}

			else continue ;
		}

		else continue ;
	}

	return 1;
}

hook OnPlayerLeaveDynArea(playerid, STREAMER_TAG_AREA:areaid) 
{
	if (PlayerVar[playerid][E_PLAYER_AT_PROPERTY_ENTER])
	{
		if (!IsPlayerInDynamicArea(playerid, Property[PlayerVar[playerid][E_PLAYER_PROPERTY_ENTER_IDX]][E_PROPERTY_AREA], true))
		{
			PlayerTextDrawSetString(playerid, house_info_box[playerid], "_" ) ;
			PlayerTextDrawHide(playerid, house_info_box[playerid]);
			PlayerVar[playerid][E_PLAYER_AT_PROPERTY_ENTER] = false;
		}
	}


	return 1;
}

// Builds the display name of a property (custom name or address, with colour).
FormatPropertyName(index)
{
	new returnstr[128], zone[64], name_style[4];
	
	if (strlen(Property[index][E_PROPERTY_NAME]) > 1 && strcmp(Property[index][E_PROPERTY_NAME], "Undefined") && strcmp(Property[index][E_PROPERTY_NAME], "NULL"))
	{
		switch (Property [ index ] [ E_PROPERTY_NAME_COLOR ]) 
		{
			case 1: format ( name_style, sizeof ( name_style ), "~r~" ) ;
			case 2: format ( name_style, sizeof ( name_style ), "~g~" ) ;
			case 3: format ( name_style, sizeof ( name_style ), "~b~" ) ;
			case 4: format ( name_style, sizeof ( name_style ), "~y~" ) ;
			case 5: format ( name_style, sizeof ( name_style ), "~p~" ) ;
			case 6: format ( name_style, sizeof ( name_style ), "~l~" ) ;
			default: format ( name_style, sizeof ( name_style ), "~w~" ) ;
		}

		format(returnstr, sizeof(returnstr), "%s%s", name_style, Property[index][E_PROPERTY_NAME]);
	}
	else
	{
		new address_id = GetAddressID(Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ]);
		
		if (address_id >= 0)
		{
			GetAddressFromID(address_id, zone, sizeof(zone));
			format(returnstr, sizeof(returnstr), "%d %s", index, zone);
		}
		else
		{
			GetCoords2DZone(Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
			format(returnstr, sizeof(returnstr), "%d %s", index, zone);
		}
	}

	return returnstr;
}
