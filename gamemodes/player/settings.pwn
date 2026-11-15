// ============================================================================
// File: player/settings.pwn
// /settings menu (HUD options, name style, tips, direction compass...) and /changepass.
// ORP_OnSettingChanged is the hook other systems use to react to a setting change.
// Commands: /settings /changepass
// ============================================================================

// Sporky: Hook this elsewhere if needed (example in sirens)
forward ORP_OnSettingChanged(playerid, E_PLAYER_CHARACTER_DATA:setting);
// Hook point that runs when a player changes a setting.
public ORP_OnSettingChanged(playerid, E_PLAYER_CHARACTER_DATA:setting) 
{
	// printf("Setting %d for %s changed to: %d", _:setting, ReturnPlayerNameData(playerid), Character[playerid][setting]);
	return 1;
}

// Returns whether the player has the trademark/street HUD labels enabled.
Settings_GetTrademarkValue(playerid) {

	return Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK] ;
}
// Returns whether the vehicle alert fade is enabled for the player.
Settings_GetVehicleFadeValue(playerid) {

	return Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN] ;
}

// Returns whether the compass is enabled for the player.
Settings_GetDirectionValue(playerid) {

	return Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION ] ;
}

// Settings_GetRagOnState(playerid) {

// 	return Character [ playerid ] [ E_CHARACTER_RAG_ON ] ;
// }

// /settings - opens the settings menu (HUD options, tips, name style, etc.).
CMD:settings(playerid, params[]) {

 	new string [ 1024 ] ;

 	strcat(string, "Setting\tToggle\n");

 	inline PlayerGUISettings(pid, dialogid, response, listitem, string: inputtext[]) {
 		#pragma unused pid, dialogid, response, listitem, inputtext

 		if ( ! response ) {

 			return true ;
 		}

 		switch ( listitem ) {
 			case 0: { // watermark gui
 				if (Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK]  ) {

 					SendClientMessage(playerid, COLOR_INFO, "You've turned off the zone fadein textdraw." ) ;
 					Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK] = false ;
 				}

 				else if ( ! Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK]  ) {
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on the zone fadein textdraw." ) ;
 					Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK]  = true ;
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_trademark = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
 			}

 			case 1: { // date gui
 				if (Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN ]  ) {


 					Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN] = false ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off the vehicle fadein textdraw." ) ;
	    			PlayerTextDrawHide(playerid, vehicleTextDraw[playerid]);
	    			PlayerVehicleAlertFading [ playerid ]=false;
 				}
 				else if ( ! Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN]  ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN]  = true ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on the vehicle fadein textdraw." ) ;
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_vehfadein = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
 			}


 			case 2: {// vehicle gui

				Settings_OnVehicleToggleGUI(playerid);
				CallLocalFunction("ORP_OnSettingChanged", "dd", playerid, _:E_CHARACTER_HUD_VEHICLE); // Sporky: new, hooked by sirens
 			} 

 			case 3: { // Gangzone
 
			 	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ] == 1 ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ] = 0 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off minimap gangzones." ) ;
#if defined FEATURE_GANGZONES
 					GangZone_HideForPlayer(playerid);
#endif
			 	}

			 	else if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ] == 0 ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ] = 1 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on minimap gangzones." ) ;
#if defined FEATURE_GANGZONES
					GangZone_ShowForPlayer(playerid) ;
#endif
			 	}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_setting_gangzones = %d WHERE account_id = %d",
					Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ]) ;

 				mysql_tquery(mysql, string);
				
 			}

 			case 4: { // voiceline sound

 				if ( Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND] ) {

					PlayerPlaySound(playerid, 0, 0, 0, 0);
 					Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND] = false ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off voiceline sounds." ) ;
 				}

 				else if ( ! Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND] ) {

 					Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND] = true ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on voiceline sounds." ) ;
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_voicelines = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
 			}

 			case 5: { // minigame tds

 				if ( Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ] ) {

					PlayerPlaySound(playerid, 0, 0, 0, 0);
 					Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ] = false ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off the minigame hud." ) ;
 				}

 				else if ( ! Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ] ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ] = true ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on the minigame hud." ) ;
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_minigame = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
				HideMinigameHelpBox ( playerid ) ;

				PlayerVar [ playerid ] [ E_PLAYER_MINIGAME_MSG_CD ] = false ;
				PlayerVar [ playerid ] [ E_PLAYER_MINIGAME_MSG_CD_2 ] = false ;
 			}
			
 			/*case 6: { // nametag style

			 	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ] ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ] = 0 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've switched your namestyle to gang tags." ) ;
			 	}

			 	else if ( !Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ] ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ] = 1 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've switched your namestyle to Firstname_Lastname." ) ;
			 	}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_namestyle = %d WHERE account_id = %d",
					Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ]) ;

 				mysql_tquery(mysql, string);

 				UpdateTabListForPlayer ( playerid ) ;	
    			//UpdateTabListForPlayers(playerid);
 			}*/

 			case 6: { // tips

			 	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ] == 1 ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ] = 0 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off server tips / helpful messages." ) ;
			 	}

			 	else if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ] == 0 ) {

			 		Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ] = 1 ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on server tips / helpful messages." ) ;
			 	}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_setting_tips = %d WHERE account_id = %d",
					Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ]) ;

 				mysql_tquery(mysql, string);
 			} 

			case 7: { // blinkers

				if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ] == 1 ) {

					Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ] = 0 ;
					SendClientMessage(playerid, COLOR_INFO, "You've turned off the vehicle blinker keys.  You can still use /carblink" ) ;
				}

				else if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ] == 0 ) {

					Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ] = 1 ;
					SendClientMessage(playerid, COLOR_INFO, "You've turned on the vehicle blinker keys.  Press Y or N in a vehicle." ) ;
				}

				string [ 0 ] = EOS ;

				mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_setting_blinkers = %d WHERE account_id = %d",
					Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ]) ;

				mysql_tquery(mysql, string);
			} 									
 			case 8: { // date gui
 				if (Character [ playerid ] [ E_CHARACTER_HUD_CLOCK ]  ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_CLOCK] = false ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off the server clock textdraw." ) ;
					TextDrawHideForPlayer(playerid, hud_time ) ; 
 				}
 				else if ( ! Character [ playerid ] [ E_CHARACTER_HUD_CLOCK]  ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_CLOCK]  = true ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on the server clock textdraw." ) ;
					TextDrawShowForPlayer(playerid, hud_time ) ; 
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_clock = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_HUD_CLOCK], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
 			}

 			case 9: { // directional gui v2
				if (Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION ]  ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION] = false ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned off the directional compass textdraw." ) ;

					PlayerTextDrawHide(playerid, gui_direction [ playerid ] [ 0 ] );
					PlayerTextDrawHide(playerid, gui_direction [ playerid ] [ 1 ] );
 				}
 				else if ( ! Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION]  ) {

 					Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION]  = true ;
 					SendClientMessage(playerid, COLOR_INFO, "You've turned on the directional compass textdraw." ) ;

 					if(GetPlayerState(playerid)==PLAYER_STATE_DRIVER) {
						PlayerTextDrawShow(playerid, gui_direction [ playerid ] [ 0 ] );
						PlayerTextDrawShow(playerid, gui_direction [ playerid ] [ 1 ] );
					}
 				}

 				string [ 0 ] = EOS ;

 				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_direction = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

 				mysql_tquery(mysql, string);
 			}

 			case 10: { // rag on/off toggle
				if ( IsPlayerIncapacitated(playerid, false) ) {
					SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
					return true;
				}

				if ( Character[playerid][E_CHARACTER_ARREST_TIME] > 0 ) {
					SendServerMessage ( playerid, COLOR_ERROR, "Incarcerated", "A3A3A3", "You do not have your rag in prison." ) ;
					return true;
				}

				if (GetPlayerFactionType(playerid) != FACTION_TYPE_ILLEGAL) {
					SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Only gang members can enable gang colours.");
					return true;
				}

				if (Character [ playerid ] [ E_CHARACTER_RAG_ON]) {
					Character [ playerid ] [ E_CHARACTER_RAG_ON] = false;
					SendClientMessage(playerid, COLOR_INFO, "You've turned off gang colours." );
					
					new roffText[96], roffLogString[150];
					new Float: range = 15.0, color = COLOR_ACTION;
					format(roffText, sizeof(roffText), "takes off their rag.");
					format(roffLogString, sizeof(roffLogString), "%s", roffText);
					ProxDetectorEx(playerid, range, color, "*", roffLogString);
					format(roffLogString, sizeof(roffLogString), "* %s", roffText);
					AddLogEntry(playerid, LOG_TYPE_ACTION, roffLogString);
				}
				else {
					Character [ playerid ] [ E_CHARACTER_RAG_ON] = true;
					SendClientMessage(playerid, COLOR_INFO, "You've turned on gang colours." );
					
					new ronText[96], ronLogString[150];
					new Float: range = 15.0, color = COLOR_ACTION;
					format(ronText, sizeof(ronText), "puts on their rag.");
					format(ronLogString, sizeof(ronLogString), "%s", ronText);
					ProxDetectorEx(playerid, range, color, "*", ronLogString);
					format(ronLogString, sizeof(ronLogString), "* %s", ronText);
					AddLogEntry(playerid, LOG_TYPE_ACTION, ronLogString);
				}

				UpdateTabListForOthers(playerid);

				string [ 0 ] = EOS ;

				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_rag_on = %d WHERE player_id = %d",
					Character [ playerid ] [ E_CHARACTER_RAG_ON], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

				mysql_tquery(mysql, string);
				
				CallLocalFunction("ORP_OnSettingChanged", "dd", playerid, _:E_CHARACTER_RAG_ON);
			}
			case 11: {
				if (Character[playerid][E_CHARACTER_HUD_PROPERTY_ICONS])
				{
					Character[playerid][E_CHARACTER_HUD_PROPERTY_ICONS] = false;
					SendClientMessage(playerid, COLOR_INFO, "You've turned off property icons.");
				}
				else
				{
					Character[playerid][E_CHARACTER_HUD_PROPERTY_ICONS] = true;
					SendClientMessage(playerid, COLOR_INFO, "You've turned on property icons.");
				}

				Property_UpdatePlayerVisibility(playerid);

				string[0] = EOS;
				mysql_format(mysql, string, sizeof(string), "UPDATE characters SET player_hud_property_icons = %d WHERE player_id = %d",
					Character[playerid][E_CHARACTER_HUD_PROPERTY_ICONS], Character[playerid][E_CHARACTER_ID]);
				mysql_tquery(mysql, string);
			}
 		}

 	}

 	format(string, sizeof(string), "%sZone Fadein GUI:\t%s\n", 	string, (Character [ playerid ] [ E_CHARACTER_HUD_TRADEMARK] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sVehicle Fadein GUI:\t%s\n",string, (Character [ playerid ] [ E_CHARACTER_HUD_VEH_FADEIN] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sVehicle GUI:\t%s\n", 		string, (Character [ playerid ] [ E_CHARACTER_HUD_VEHICLE]  ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sHUD Gangzone:\t%s\n",string, (Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sVoiceline Sound:\t%s\n", 	string, (Character [ playerid ] [ E_CHARACTER_VOICELINE_SOUND] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sMinigame HUD:\t%s\n", 	string, (Character [ playerid ] [ E_CHARACTER_HUD_MINIGAME ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;

	//if(Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ] == 0) format(string, sizeof(string), "%sNametag Style:\t{5DB145}ORP\n", string) ;
	//else format(string, sizeof(string), "%sNametag Style:\t{B14545}Firstname_Lastname\n", string) ;


 	format(string, sizeof(string), "%sServer Tips:\t%s\n", string, (Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
	format(string, sizeof(string), "%sVehicle Blink Keys:\t%s\n", string, (Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sServer Clock:\t%s\n", string, (Character [ playerid ] [ E_CHARACTER_HUD_CLOCK ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sDirectional HUD:\t%s\n", string, (Character [ playerid ] [ E_CHARACTER_HUD_DIRECTION ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
 	format(string, sizeof(string), "%sGang Colours:\t%s\n", string, (Character [ playerid ] [ E_CHARACTER_RAG_ON ] ) ? ("{5DB145}On") : ("{B14545}Off")  ) ;
	format(string, sizeof(string), "%sProperty Icons:\t%s\n", string, (Character[playerid][E_CHARACTER_HUD_PROPERTY_ICONS]) ? ("{5DB145}On") : ("{B14545}Off"));
	Dialog_ShowCallback ( playerid, using inline PlayerGUISettings, DIALOG_STYLE_TABLIST_HEADERS, "Player Settings", string, "Toggle", "Cancel" ) ;

	SendClientMessage(playerid, COLOR_YELLOW, "Also view /toghelp. Use /setchat to control talking animations." ) ;
 
	return true ;
}


// /changepass [current password] - starts changing your account password.
CMD:changepass(playerid, params[]) {
	new pass [ MAX_PASSWORD_LENGTH ];

	if ( sscanf ( params, "s[64]", pass ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/changepass [current password]") ;
	}

	if ( strlen ( pass ) > sizeof ( pass ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Password can't be longer than 64 characters.") ;
	}

	bcrypt_verify(playerid, "OnPlayerAttemptPassChange", pass, Account[playerid][E_PLAYER_ACCOUNT_PASSWORD]);

	return true ;
}

forward OnPlayerAttemptPassChange(playerid, bool:success);
// bcrypt callback: the current password was checked - asks for the new one.
public OnPlayerAttemptPassChange(playerid, bool:success)
{
	if(!success) return SendServerMessage(playerid, COLOR_ERROR, "ERROR", "A3A3A3", "The password does not match your current password.");

	inline ChangePass(pid, dialogid, response, listitem, string: inputtext[]) {
 		#pragma unused pid, dialogid, response, listitem

		if(!response) return SendServerMessage(playerid, COLOR_ERROR, "ERROR", "A3A3A3", "Password change attempt cancelled.");
		if ( strlen ( inputtext ) > MAX_PASSWORD_LENGTH ) {
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Password can't be longer than 64 characters.") ;
		}
		
		bcrypt_hash(playerid, "OnPlayerChangePassword", inputtext, BCRYPT_COST);
	}
	Dialog_ShowCallback ( playerid, using inline ChangePass, DIALOG_STYLE_PASSWORD, "Change Password", "Enter your new password below:", "Change", "Cancel" ) ;
	return 1;
}

forward OnPlayerChangePassword(playerid);
// bcrypt callback: saves the new password hash.
public OnPlayerChangePassword(playerid)
{
	new hash[BCRYPT_HASH_LENGTH], query[256];
	bcrypt_get_hash(hash);

	format ( query, sizeof ( query ), "[PLAYER]: %s has changed their account password.", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
	SendAdminMessage( query ) ;

	SendServerMessage ( playerid, COLOR_ERROR, "PASSWORD", "A3A3A3", "You have successfully changed your password." );
	format(Account[playerid][E_PLAYER_ACCOUNT_PASSWORD], MAX_PASSWORD_LENGTH, hash);

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE `accounts` SET account_password = '%e' WHERE account_name = '%e'", hash, Account[playerid][E_PLAYER_ACCOUNT_NAME]) ;
	mysql_tquery(mysql, query);
}
