// ============================================================================
// File: tags/names.pwn
// Name formatting: ReturnTagName, ReturnMixedName, ReturnSettingsName and CapitalizeName build
// the names shown above heads, in chat and in lists, respecting masks, faction colours and each
// viewer's name-style setting.
// ============================================================================

ReturnRPName ( playerid, bool:masked=false, bool:applyGangColor=false) 
{ // Returns "Firstname_Lastname"
    new name[64];
    

    if(PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ]) {
        format(name, sizeof(name), "{E8871B}[Admin] %s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
        return name;
    } else if (PlayerVar [playerid] [E_PLAYER_HELPER_DUTY]) {
        format(name, sizeof(name), "{38C751}[Helper] %s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
        return name;
    } else if (IsPlayerMasked(playerid) && masked) {        
        format ( name, sizeof ( name ), "Stranger %d", GetPlayerMaskID(playerid) ) ;
        return name;
    } else if (IsPlayerFakeName(playerid)) {
        format ( name, sizeof ( name ), PlayerVar[playerid][E_PLAYER_FAKENAME] ) ;
        for (new i = 0, len = strlen(name); i < len; i ++) 
        {
            if (name[i] == '_') name[i] = ' ';
        }
        return name;
    }

    format(name, sizeof(name), Character[playerid][E_CHARACTER_NAME]);

    for (new i = 0, len = strlen(name); i < len; i ++) 
    {
        if (name[i] == '_') name[i] = ' ';
    }
    
    // gang color if rag is on
    if(applyGangColor && Character[playerid][E_CHARACTER_RAG_ON]) {
        new faction_sql_id = Character[playerid][E_CHARACTER_FACTIONID];
        if(faction_sql_id) {
            new faction_enum_id = Faction_GetEnumID(faction_sql_id);
            if(faction_enum_id != -1) {
                new factionTag[32], factionColor[16];
                format(factionTag, sizeof(factionTag), "%s", Faction_GetTag(faction_sql_id, true));
                
                new colorEnd = strfind(factionTag, "}");
                if(colorEnd != -1) {
                    strmid(factionColor, factionTag, 0, colorEnd + 1);
                    format(name, sizeof(name), "%s%s", factionColor, name);
                }
            }
        }
    }
    
    return name;
}

// Returns the name tag of a player, respecting masks (coloured if asked).
stock ReturnTagName(playerid,color=true, bool:masked=false) 
{ // Returns "[LSB]Account"
    new name[64], faction_enum_id, faction_sql_id = Character[playerid][E_CHARACTER_FACTIONID];

    if(PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ]) {
        format(name, sizeof(name), "{E8871B}[Admin] %s{%06x}", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    } else if(PlayerVar [ playerid ] [ E_PLAYER_HELPER_DUTY ]) {
        format(name, sizeof(name), "{38C751}[Helper] %s{%06x}", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    } 
    else if (!IsPlayerMasked(playerid) || !masked) {
        if (faction_sql_id) {
            faction_enum_id = Faction_GetEnumID(faction_sql_id) ;

            if(faction_enum_id != -1) {
                if(Character[playerid][E_CHARACTER_RAG_ON]) {
                    new factionTag[32], factionColor[16];
                    format(factionTag, sizeof(factionTag), "%s", Faction_GetTag(faction_sql_id, color));
                    
                    new colorEnd = strfind(factionTag, "}");
                    if(colorEnd != -1) {
                        strmid(factionColor, factionTag, 0, colorEnd + 1);
                        format(name, sizeof(name), "%s%s", factionColor, Account[playerid][E_PLAYER_ACCOUNT_NAME]);
                    }
                    else {
                        format(name, sizeof(name), "%s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
                    }
                }
                else {
                    format(name, sizeof(name), "%s%s", Faction_GetTag(faction_sql_id, color), Account[playerid][E_PLAYER_ACCOUNT_NAME]); 
                }
            }
        }
        else format(name, sizeof(name), "%s", Account [playerid][E_PLAYER_ACCOUNT_NAME]);
    }
    else if(IsPlayerMasked(playerid) && masked) 
    { 
        format (name, sizeof (name), "Stranger %d", GetPlayerMaskID(playerid)) ;
    }

    new nameEx[64];
    format(nameEx, sizeof(nameEx), "%s", name);
    return nameEx;
}

// Returns the player's name mixing the roleplay name and the mask.
stock ReturnMixedName(playerid) 
{ // Returns "Account (F. Lastname)"
	new name[64], shortname[MAX_PLAYER_NAME];
	format(shortname, sizeof ( shortname ), "%s", Character [ playerid ] [ E_CHARACTER_NAME ] ) ;
    strdel(shortname, 0, strfind(shortname,"_",true) + 1);

    format(name, sizeof(name), "%s (%.1s. %s)", Account[playerid][E_PLAYER_ACCOUNT_NAME], Character[playerid][E_CHARACTER_NAME], shortname ) ;
    return name;
}

// Function to capitalise the first and last name
stock CapitalizeName(display_name[]) {
    new iPos;

    // Replace each underscore with a space
    while ((iPos = strfind(display_name, "_", false, iPos)) != -1) {
        display_name[iPos] = ' ';
    }
    
    // Capitalise the first letter of the first word (before the first space)
    display_name[0] = toupper(display_name[0]);

    // Capitalise the first letter of the second word (after the space)
    iPos = strfind(display_name, " ", false, 0); // Find the space
    if (iPos != -1 && display_name[iPos + 1] != '\0') {
        display_name[iPos + 1] = toupper(display_name[iPos + 1]); // Capitalise the first letter after the space
    }
}

// Returns the name one player sees for another based on their name style setting.
ReturnSettingsName(fromplayerid, toplayerid, bool:color=false, bool:masked=true) 
{ // Returns either one of the above, depending on setting.
    new name[64];
    if (IsPlayerPlaying(fromplayerid) && Character[fromplayerid][E_CHARACTER_ID] > 0) {
        switch(GetPlayerNametagPreference(toplayerid)) {
            case 999: format(name, sizeof(name), "%s", ReturnTagName(fromplayerid, color, masked));
            case 0:	format(name, sizeof(name), "%s", ReturnRPName(fromplayerid, masked, color));
            case 1:	format(name, sizeof(name), "%s", ReturnRPName(fromplayerid, masked, color));
        }
    }
    else format(name, sizeof(name), "%s", TEMP_ReturnPlayerName(fromplayerid));
    return name;
}
