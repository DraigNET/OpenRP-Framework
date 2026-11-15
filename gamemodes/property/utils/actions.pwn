// ============================================================================
// File: property/utils/actions.pwn
// Door interaction commands: /doorbell, /doorknock, /doorshout, /doorme, /doordo, /mic and
// /nosound for talking through doors.
// Commands: /mic /nosound /doorshout /doorme /doordo /doorbell /doorknock
// ============================================================================

// /mic [text] - speaks through the microphone inside a property.
CMD:mic(playerid, params[]) {

	new index = PlayerVar [ playerid ] [ E_PLAYER_LAST_PROPERTY_ENTERED ] ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Property", "A3A3A3", "You're not in a business! Re-enter if you think this is a bug.");
	}

	if ( Property [ index ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ && !IsPlayerInRangeOfPoint(playerid, 10, 1377.6440,-13.9704,2550.3083 ) ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Property", "A3A3A3", "You're not in a business! Re-enter if you think this is a bug.");
	}

	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new text [ 144 ] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/mic [text]" ) ;
	}

	new string[144];
	format ( string, sizeof ( string ), "says [MIC]: %s", text ) ;

	ProxDetectorEx(playerid, 64.0, 0x9dff96AA, "", string, .showid=false, .annonated=true);
	AddLogEntry(playerid, LOG_TYPE_CHAT, sprintf("[MIC]: %s", text));

	return true;
}


// /nosound [0/1] - mutes or restores the outdoor ambience inside a property.
CMD:nosound(playerid, params[]) {

	new status;

	if ( sscanf ( params, "i", status ) ) {

		return SendClientMessage(playerid, COLOR_ERROR, "/nosound [status: 1: nothing, 0: default outdoor ambience]");
	}

	if ( status < 0 || status > 1 ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Invalid status! Choose: 1: nothing, 0: default outdoor ambience.");
	}

	PlayerPlaySound(playerid, status, 0, 0, 0);

	SendClientMessage(playerid, -1, "Reset your sound! Useful if you hear the \"air\" sound whilst in an interior." ) ;

	return true ;
}


// /doorshout [text] - shouts through the door to the people on the other side.
CMD:doorshout(playerid, params[]) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You're not near a property entrance." ) ;

	}

	new text [ 144 ], full_string[256] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/doorshout [text]" ) ;
	}

	new bool: status, final_color, color = 0xDEDEDEFF, Float: max_ratio = 1.6, Float: max_range = 20.0,  Float:range, 
		Float:range_ratio, Float:range_with_ratio, clr_r, clr_g, clr_b, Float:color_r, Float:color_g, Float:color_b 
	;

	ProxDetectorEx(playerid, 20.0, -1, "shouts (door):", text, false, false);

	color_r = float(color >> 24 & 0xFF);
	color_g = float(color >> 16 & 0xFF);
	color_b = float(color >> 8 & 0xFF);
	range_with_ratio = max_range * max_ratio;

	if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_EXT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_EXT_INT ] ) {
		
			status = false ;
		}
	}

	else if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {
		
			status = true ;
		}
	}

	AddLogEntry(playerid, LOG_TYPE_CHAT, sprintf("[door shout]: %s", text));

	foreach(new targetid: Player) {

		if ( targetid == playerid ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_EXT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_EXT_INT ] ) {

				if ( ! status ) {

					continue ;
				}

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);


				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "%s shouts (door, inside): %s", ReturnSettingsName(playerid, targetid), text ) ;

				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}

		else if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {

				if ( status ) {

					continue ;
				}

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);


				
				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "%s shouts (door, outside): %s", ReturnSettingsName(playerid, targetid), text ) ;


				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}

	}

	return true ;
}


// /doorme [text] - sends a /me action that people on the other side of the door can see.
CMD:doorme(playerid, params[]) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You're not near a property entrance." ) ;

	}

	new text [ 144 ], full_string[256] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/doorme [text]" ) ;
	}

	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", text, false, false);
	AddLogEntry(playerid, LOG_TYPE_ACTION, sprintf("[door action]: %s", text));

	new bool: status, final_color, color = COLOR_ACTION, Float: max_ratio = 1.6, Float: max_range = 20.0,  Float:range, 
		Float:range_ratio, Float:range_with_ratio, clr_r, clr_g, clr_b, Float:color_r, Float:color_g, Float:color_b 
	;

	color_r = float(color >> 24 & 0xFF);
	color_g = float(color >> 16 & 0xFF);
	color_b = float(color >> 8 & 0xFF);
	range_with_ratio = max_range * max_ratio;

	if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_EXT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_EXT_INT ] ) {
		
			status = false ;
		}
	}

	else if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {
		
			status = true ;
		}
	}

	foreach(new targetid: Player) {

		if ( targetid == playerid ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_EXT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_EXT_INT ] ) {

				if ( ! status ) {

					continue ;
				}

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_EXT_X ],  Property [ index ] [ E_PROPERTY_EXT_Y ],  Property [ index ] [ E_PROPERTY_EXT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);

				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "* (door, inside) %s %s", ReturnSettingsName(playerid, targetid), text ) ;

				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}

		else if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {

				if ( status ) {

					continue ;
				}

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);

				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "* (door, outside) %s %s", ReturnSettingsName(playerid,  targetid), text ) ;

				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}

	}

	return true ;
}

// /doordo [text] - sends a /do action that people on the other side of the door can see.
CMD:doordo(playerid, params[]) {
    new index = Property_GetClosestEntity(playerid, PROPERTY_NEAR_ENTER);

    if (index == INVALID_PROPERTY_ID) {
        return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You're not near a property entrance.");
    }

    new text[144], full_string[256];

    if (sscanf(params, "s[144]", text)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/doordo [text]");
    }

    ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", text, .inverted = true);
    AddLogEntry(playerid, LOG_TYPE_ACTION, sprintf("[door do]: %s", text));

    new bool:status, final_color, color = COLOR_ACTION, Float:max_ratio = 1.6, Float:max_range = 20.0, Float:range,
        Float:range_ratio, Float:range_with_ratio, clr_r, clr_g, clr_b, Float:color_r, Float:color_g, Float:color_b;

    color_r = float(color >> 24 & 0xFF);
    color_g = float(color >> 16 & 0xFF);
    color_b = float(color >> 8 & 0xFF);
    range_with_ratio = max_range * max_ratio;

    if (IsPlayerInRangeOfPoint(playerid, max_range, Property[index][E_PROPERTY_EXT_X], Property[index][E_PROPERTY_EXT_Y], Property[index][E_PROPERTY_EXT_Z])) {
        if (GetPlayerVirtualWorld(playerid) == Property[index][E_PROPERTY_EXT_VW] && GetPlayerInterior(playerid) == Property[index][E_PROPERTY_EXT_INT]) {
            status = true;
        }
    }
    else if (IsPlayerInRangeOfPoint(playerid, max_range, Property[index][E_PROPERTY_INT_X], Property[index][E_PROPERTY_INT_Y], Property[index][E_PROPERTY_INT_Z])) {
        if (GetPlayerVirtualWorld(playerid) == Property[index][E_PROPERTY_INT_VW] && GetPlayerInterior(playerid) == Property[index][E_PROPERTY_INT_INT]) {
            status = false;
        }
    }

    foreach(new targetid: Player) {
        if (targetid == playerid) {
            continue;
        }

        if (IsPlayerInRangeOfPoint(targetid, max_range, Property[index][E_PROPERTY_EXT_X], Property[index][E_PROPERTY_EXT_Y], Property[index][E_PROPERTY_EXT_Z])) {
            if (GetPlayerVirtualWorld(targetid) == Property[index][E_PROPERTY_EXT_VW] && GetPlayerInterior(targetid) == Property[index][E_PROPERTY_EXT_INT]) {
                // skip if status doesnt match (inside trying to send to outside or vice versa)
                if (!status) {
                    continue;
                }

                range = GetPlayerDistanceFromPoint(targetid, Property[index][E_PROPERTY_EXT_X], Property[index][E_PROPERTY_EXT_Y], Property[index][E_PROPERTY_EXT_Z]);
                
                range_ratio = (range_with_ratio - range) / range_with_ratio;
                clr_r = floatround(range_ratio * color_r);
                clr_g = floatround(range_ratio * color_g);
                clr_b = floatround(range_ratio * color_b);

                final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24);
                format(full_string, sizeof(full_string), "* %s (( %s, door, inside ))", text, ReturnSettingsName(playerid, targetid));

                ZMsg_SendClientMessage(targetid, final_color, full_string);
            }
        }
        else if (IsPlayerInRangeOfPoint(targetid, max_range, Property[index][E_PROPERTY_INT_X], Property[index][E_PROPERTY_INT_Y], Property[index][E_PROPERTY_INT_Z])) {
            if (GetPlayerVirtualWorld(targetid) == Property[index][E_PROPERTY_INT_VW] && GetPlayerInterior(targetid) == Property[index][E_PROPERTY_INT_INT]) {
                if (status) {
                    continue;
                }

                range = GetPlayerDistanceFromPoint(targetid, Property[index][E_PROPERTY_INT_X], Property[index][E_PROPERTY_INT_Y], Property[index][E_PROPERTY_INT_Z]);

                range_ratio = (range_with_ratio - range) / range_with_ratio;
                clr_r = floatround(range_ratio * color_r);
                clr_g = floatround(range_ratio * color_g);
                clr_b = floatround(range_ratio * color_b);

                final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24);
                format(full_string, sizeof(full_string), "* %s (( %s, door, outside ))", text, ReturnSettingsName(playerid, targetid));

                ZMsg_SendClientMessage(targetid, final_color, full_string);
            }
        }
    }

    return true;
}


// /doorbell - rings the doorbell of the property you are at.
CMD:doorbell(playerid, params[]) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You're not near a property entrance." ) ;

	}

	new full_string[256] ;

	new final_color, color = COLOR_ACTION, Float: max_ratio = 1.6, Float: max_range = 20.0,  Float:range, 
		Float:range_ratio, Float:range_with_ratio, clr_r, clr_g, clr_b, Float:color_r, Float:color_g, Float:color_b 
	;

	color_r = float(color >> 24 & 0xFF);
	color_g = float(color >> 16 & 0xFF);
	color_b = float(color >> 8 & 0xFF);
	range_with_ratio = max_range * max_ratio;

	if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {
		
			return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You can't ring the doorbell from the inside, are you stupid?" ) ;
		}
	}

	//ProxDetectorNameTag(playerid, 15.0, COLOR_ACTION, "rings the doorbell.", "", 1,  .customcolor=false, .invert_action=false ) ;
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", "rings the doorbell.", .annonated=true);
	AddLogEntry(playerid, LOG_TYPE_ACTION, sprintf("rings the doorbell of %i", index));

	foreach(new targetid: Player) {

		if ( targetid == playerid ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);

				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "* %s rings the doorbell (outside).", ReturnSettingsName(playerid, targetid)) ;

				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}
	}

	return true ;
}

// /doorknock - knocks on the door of the property you are at.
CMD:doorknock(playerid, params[]) {

	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You're not near a property entrance." ) ;

	}

	new full_string[256] ;

	new final_color, color = COLOR_ACTION, Float: max_ratio = 1.6, Float: max_range = 20.0,  Float:range, 
		Float:range_ratio, Float:range_with_ratio, clr_r, clr_g, clr_b, Float:color_r, Float:color_g, Float:color_b 
	;

	color_r = float(color >> 24 & 0xFF);
	color_g = float(color >> 16 & 0xFF);
	color_b = float(color >> 8 & 0xFF);
	range_with_ratio = max_range * max_ratio;

	if ( IsPlayerInRangeOfPoint(playerid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

		if ( GetPlayerVirtualWorld(playerid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( playerid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {
		
			return SendServerMessage(playerid, COLOR_PROPERTY, "Property", "DEDEDE", "You can't knock the door from the inside, are you stupid?" ) ;
		}
	}
	
    //ProxDetectorNameTag(playerid, 15.0, COLOR_ACTION, "knocks on the door.", "", 1,  .customcolor=false, .invert_action=false ) ;
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", "knocks on the door.", .annonated=true);
	AddLogEntry(playerid, LOG_TYPE_ACTION, sprintf("knocks on the door of of %i", index));

	foreach(new targetid: Player) {

		if ( targetid == playerid ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(targetid, max_range, Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ] ) ) {

			if ( GetPlayerVirtualWorld(targetid) ==  Property [ index ] [ E_PROPERTY_INT_VW ] && GetPlayerInterior ( targetid ) ==  Property [ index ] [ E_PROPERTY_INT_INT ] ) {

				range = GetPlayerDistanceFromPoint(targetid,  Property [ index ] [ E_PROPERTY_INT_X ],  Property [ index ] [ E_PROPERTY_INT_Y ],  Property [ index ] [ E_PROPERTY_INT_Z ]);

				range_ratio = (range_with_ratio - range) / range_with_ratio;
				clr_r = floatround(range_ratio * color_r);
				clr_g = floatround(range_ratio * color_g);
				clr_b = floatround(range_ratio * color_b);

				final_color = (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24) ;
				format ( full_string, sizeof ( full_string ), "* %s knocks on the door (outside).", ReturnSettingsName(playerid, targetid)) ;

				ZMsg_SendClientMessage(targetid, final_color, full_string);
			}
		}
	}

	return true ;
}
