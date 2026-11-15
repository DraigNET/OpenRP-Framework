// ============================================================================
// File: furniture/header.pwn
// Furniture system entry point: /furni, /furniedit, /furnilist, /furnimode, /furniwipe and
// /reloadfurniture, plus per-player furniture limits.
// Commands: /reloadfurniture /furnimode /furni /furniedit /furnilist /furniwipe
// ============================================================================

#define COLOR_FURNITURE	0x7F75A6FF

// data
#include "furniture/furni.pwn" // mats / obj
#include "furniture/data.pwn" // saving

#include "furniture/objects.pwn" // object stuff
#include "furniture/textures.pwn" // texture stuff


#include "furniture/interiors.pwn" // blank ints

//#include "furniture/html.pwn" // prints page

// Returns the maximum furniture items a player may place, by premium level.
static stock Furniture_GetMaxForPlayer(playerid)
{
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL])
    {
        case E_PREMIUM_LVL_4: return 2000; // Gold
        case E_PREMIUM_LVL_3: return 1250; // Silver
        case E_PREMIUM_LVL_2: return 750;  // Bronze
    }

    return 500; // Regular / Early Supporter
}

Furniture_IncrementPropLimit ( playerid, property_sql ) {

	new index = -1 ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] == property_sql ) {

			index = i ;
		}

		else continue ;
	}

	if ( index == -1 ) {

		return false ;
	}

	new maxFurniture = Furniture_GetMaxForPlayer(playerid);

	if ( Property [ index ] [ E_PROPERTY_FURNI_LIMIT ] >= maxFurniture ) {
		return false;
	}

	Property [ index ] [ E_PROPERTY_FURNI_LIMIT ] ++ ;

	new query [ 128 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_furni_limit = %d WHERE property_id = %d",
		Property [ index ] [ E_PROPERTY_FURNI_LIMIT ], Property [ index ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);

	query [ 0 ] = EOS ;

	format ( query, sizeof ( query ), "Furniture added to property stock; you are currently using %d/%d furniture slots.",
		Property [ index ] [ E_PROPERTY_FURNI_LIMIT ], maxFurniture ) ;

	SendServerMessage ( playerid, COLOR_YELLOW, "Furniture", "DEDEDE", query);

	return true ;
}

Furniture_DecreasePropLimit ( playerid, property_sql ) {

	new index = -1 ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] == property_sql ) {

			index = i ;
		}

		else continue ;
	}

	if ( index == -1 ) {

		return false ;
	}


	Property [ index ] [ E_PROPERTY_FURNI_LIMIT ] -- ;

	new query [ 128 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_furni_limit = %d WHERE property_id = %d",
		Property [ index ] [ E_PROPERTY_FURNI_LIMIT ], Property [ index ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);

	query [ 0 ] = EOS ;

	new maxFurniture = Furniture_GetMaxForPlayer(playerid);

	format(query, sizeof(query),
		"Furniture removed from property stock; you are currently using %d/%d furniture slots.",
		Property[index][E_PROPERTY_FURNI_LIMIT],
		maxFurniture
	);

	SendServerMessage ( playerid, COLOR_YELLOW, "Furniture", "DEDEDE", query);

	return true ;
}

// Resets a player's furniture editing state.
Furniture_SetPlayerVariables(playerid) {
	PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] = INVALID_PROPERTY_ID ;

	PlayerVar [ playerid ] [ E_FURNI_EDITING_OBJECT ] = false ;
	PlayerVar [ playerid ] [ E_FURNI_EDITING_EXTRAID ] = -1 ;
	PlayerVar [ playerid ] [ E_FURNI_EDITING_OBJECTID ] = -1 ;
}

// /reloadfurniture - (admin) destroys and reloads all furniture from the database.
CMD:reloadfurniture(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_LEAD)
        return SendClientMessage(playerid, -1, "You are not authorised.");

    SendClientMessage(playerid, -1, "Reloading furniture...");

    SavedFurni_DestroyAll();
    SavedFurni_LoadEntities();

    SendClientMessage(playerid, -1, "Furniture reload triggered.");

    return 1;
}

// /furnimode - toggles furniture mode inside a property you own.
CMD:furnimode(playerid) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You must be inside your property, near the door." );
		return true ;
	}
	
	if ( Property [ index ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] && PlayerVar [ playerid ] [ E_PLAYER_FURNI_PERM ] != Property [ index ] [ E_PROPERTY_ID ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You need permission from the property's owner to do this." );
	}

	if ( IsPlayerInRangeOfPoint ( playerid, 5.0, Property [ index ] [ E_PROPERTY_INT_X ], Property [ index ] [ E_PROPERTY_INT_Y ], Property [ index ] [ E_PROPERTY_INT_Z ] )) {

		PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] = Property [ index ] [ E_PROPERTY_ID ] ;

		new string [ 256 ] ;

		format ( string, sizeof ( string ), "You've enabled furniture mode on property ID %d (sql %d).", index, Property [ index ] [ E_PROPERTY_ID ] ) ;

		SendServerMessage ( playerid, COLOR_FURNITURE, "Furniture", "DEDEDE", string );

		return true ;
	}

	return true ;
}

// /furni - opens the furniture catalogue to buy items.
CMD:furni(playerid) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You're not in furniture mode! Head to the EXIT point and do /furnimode. (don't do /exit).");
	}
		
	if ( GetPlayerVirtualWorld(playerid) == 0 ) {

		CancelEdit(playerid);
		return SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE",  "You can't create furniture outside a house!" ) ;
	}

	Furni_ListCategory(playerid);

	return true ;
}

// /furniedit - lets you click a furniture object to edit it.
CMD:furniedit(playerid) {
	if ( PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You're not in furniture mode! Head to the EXIT point and do /furnimode. (don't do /exit).");
	}

	SendServerMessage ( playerid, COLOR_FURNITURE, "Furniture", "DEDEDE", "Select a furniture item you wish to edit using the 3D mouse. You can only select furniture items." ) ;

	SelectObject(playerid);

	return true ;
}

// /furnilist [yards] - lists furniture within a radius of you.
CMD:furnilist(playerid, params[]) {

    new Float: yards;

    if (sscanf(params, "f", yards)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Furniture", "DEDEDE", "/furnilist [yards]{A3A3A3} (min: 2.5 / max: 15.0)");
    }

    if (yards < 2.5 || yards > 15.0) {
        return SendServerMessage(playerid, COLOR_ERROR, "Furniture", "DEDEDE", "/furnilist [yards]{A3A3A3} (min: 2.5 / max: 15.0)");
    }

    if (PlayerVar[playerid][E_PLAYER_FURNI_MODE] == INVALID_PROPERTY_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You're not in furniture mode! Head to the EXIT point and do /furnimode. (don't do /exit).");
    }

    new vw = GetPlayerVirtualWorld(playerid);
    new index[20], index_count = 0, index_max = 20, bool: max_limit;
    new list_string[2048];
    strcat(list_string, "Index\tModel\tName\tDistance\n");
	//new tick_start = GetTickCount();

    for (new i = 0, j = sizeof(Furniture); i < j; i++) {

        if (Furniture[i][E_FURNI_VW] != vw) continue;
        if (Furniture[i][E_FURNI_SQL_ID] == INVALID_FURNI_SAVED_ID) continue;

        if (index_count >= index_max) {
            max_limit = true;
            break;
        }

        new Float: dist = GetPlayerDistanceFromPoint(playerid,
            Furniture[i][E_FURNI_POS_X],
            Furniture[i][E_FURNI_POS_Y],
            Furniture[i][E_FURNI_POS_Z]);

        if (dist > yards) continue;

        new furni_id = Furniture_FetchIDFromModel(Furniture[i][E_FURNI_MODEL]);
        new furni_name[64];
        Furniture_FetchName(furni_id, furni_name, sizeof(furni_name));

        format(list_string, sizeof(list_string), "%s%d\t%d\t%s\t%.2f yds\n",
            list_string, i, Furniture[i][E_FURNI_MODEL], furni_name, dist);

        index[index_count] = i;
        index_count++;
    }

    if (index_count == 0) {
        return SendServerMessage(playerid, COLOR_ERROR, "Furniture", "DEDEDE", "No furniture found within that range.");
    }

    if (max_limit) {
        SendClientMessage(playerid, COLOR_YELLOW, sprintf("Showing first %d results only.", index_max));
    }

    new dialog_title[64];
    format(dialog_title, sizeof(dialog_title), "All furniture within %.2f yards", yards);

    inline furni_list_display(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        if (!response) return true;

        new selection = index[listitem];

        new cb_furni_id = Furniture_FetchIDFromModel(Furniture[selection][E_FURNI_MODEL]);
        new cb_furni_name[64];
        Furniture_FetchName(cb_furni_id, cb_furni_name, sizeof(cb_furni_name));

        new cb_msg[128];
        format(cb_msg, sizeof(cb_msg), "Selected index %d | model %d | %s",
            selection, Furniture[selection][E_FURNI_MODEL], cb_furni_name);

        SendServerMessage(playerid, COLOR_FURNITURE, "Furniture", "DEDEDE", cb_msg);

        new objectid = Furniture [ selection ] [ E_FURNI_OBJECTID ] ;
		new extra_id = Furniture [ selection ] [ E_FURNI_EXTRA_ID ] ;

		Furniture_ViewMenu(playerid, objectid, extra_id ) ;
        return true;
    }

	//printf("[FURNILIST] loop took %dms", GetTickCount() - tick_start); // It's taking 300ms for fuck's sake.. this shit's bad, convert max furniture per hourse to something less than 1k PLEASE

    Dialog_ShowCallback(playerid, using inline furni_list_display, DIALOG_STYLE_TABLIST_HEADERS, dialog_title, list_string, "Select", "Back");
    return true;
}

// /furniwipe - removes all furniture from the property you are in and refunds it.
CMD:furniwipe(playerid) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "You must be inside your property, near the door." );
		return true ;
	}
	
	if ( Property [ index ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Furniture", "DEDEDE", "Only the property owner can do this." );
	}

	if ( IsPlayerInRangeOfPoint ( playerid, 5.0, Property [ index ] [ E_PROPERTY_INT_X ], Property [ index ] [ E_PROPERTY_INT_Y ], Property [ index ] [ E_PROPERTY_INT_Z ] )) {


		Furniture_WipeAllContent ( playerid, Property [ index ] [ E_PROPERTY_ID ] ) ;
	}

	return true ;
}

// Removes all furniture from a property and refunds the owner.
Furniture_WipeAllContent(playerid, property_sql_id ) {
	new query [ 256 ], total_refund ;

	for ( new i, j = sizeof ( Furniture ); i < j ; i ++ ) {

		if ( Furniture [ i ] [ E_FURNI_SQL_ID ] != -1 ) {

			if ( Furniture [ i ] [ E_FURNI_EXTRA_ID ] == property_sql_id ) {

				if ( IsValidDynamicObject(Furniture [ i ] [ E_FURNI_OBJECTID ] ) ) {

					DestroyDynamicObject( Furniture [ i ] [ E_FURNI_OBJECTID ] ) ;
					Furniture [ i ] [ E_FURNI_OBJECTID ] = -1 ;
				}

				mysql_format(mysql, query, sizeof(query), "DELETE FROM furniture WHERE furniture_sqlid = %d", Furniture [ i ] [ E_FURNI_SQL_ID ] ) ;
				mysql_tquery(mysql, query);

				total_refund += Furniture_GetPrice(i);

				Furniture [ i ] [ E_FURNI_SQL_ID ] = -1 ;
				Furniture [ i ] [ E_FURNI_EXTRA_ID ] = -1 ;
			}

			else continue ;
		}

		else continue ;
	}

	new property_index = INVALID_PROPERTY_ID ;

	foreach(new i: Properties) {
		if ( Property [ i ] [ E_PROPERTY_ID ] == property_sql_id ) {

			Property [ i ] [ E_PROPERTY_FURNI_LIMIT ] = 0 ;

			mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_furni_limit = 0 WHERE property_id = %d",
				Property [ i ] [ E_PROPERTY_ID ]
			);

			mysql_tquery(mysql, query);

			property_index = i ;

			break ;
		}

		else continue ;
	}

	if ( IsPlayerConnected ( playerid ) ) {

		total_refund = total_refund / 2;
		
		SendClientMessage(playerid, COLOR_YELLOW, 
			sprintf("All your furniture has been wiped. You have been refunded $%s (half the total value of the items).",
				IntegerWithDelimiter ( total_refund ) 
			) 
		) ;

		GivePlayerCash ( playerid, total_refund, "Furniture wipe" ) ;
		total_refund = 0 ;
	}

	else if ( ! IsPlayerConnected ( playerid ) ) {

		if ( property_index != INVALID_PROPERTY_ID ) {

			mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_soldfurni=%d WHERE player_id = %d", 
				total_refund, Property [ property_index ] [ E_PROPERTY_OWNER ] ) ;
			mysql_tquery(mysql, query );
		}

	}
	
	return true ;
}

ptask FurniMode_Check[5000](playerid) {

	if ( IsPlayerLogged ( playerid ) && IsPlayerSpawned ( playerid ) ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] != INVALID_PROPERTY_ID ) {

			new Float: MAX_FURNI_MODE_RANGE = 150.0, bool: disclosed = false ;

			foreach(new i: Properties) {

				if ( PlayerVar [ playerid ] [ E_PLAYER_FURNI_MODE ] == Property [ i ] [ E_PROPERTY_ID ] ) {

					if ( IsPlayerInRangeOfPoint ( playerid, MAX_FURNI_MODE_RANGE, Property [ i ] [ E_PROPERTY_INT_X ], Property [ i ] [ E_PROPERTY_INT_Y ], Property [ i ] [ E_PROPERTY_INT_Z ] )) {
						if ( GetPlayerVirtualWorld(playerid) ==  Property [ i ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ i ] [ E_PROPERTY_INT_INT ] ) {

							disclosed = true ;
							break ;
						}

						else continue ;
					}

					else continue ;
				}

				else continue ;
			}

			if ( GetPlayerVirtualWorld(playerid) == 0 ) {

				disclosed=false;
			}

			if ( ! disclosed ) {
				SendServerMessage ( playerid, COLOR_FURNITURE, "Furniture", "DEDEDE", "You've travelled too far away from your furnimode point. It has been disabled." ) ;
			
				Furniture_SetPlayerVariables(playerid) ;
				CancelEdit(playerid);
			}
		}
	}
		
	return true ;
}
