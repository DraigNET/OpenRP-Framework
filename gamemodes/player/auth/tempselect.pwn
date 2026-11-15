// ============================================================================
// File: player/auth/tempselect.pwn
// Basic character select screen written as a crash fix. By Spooky.
// ============================================================================

//------------------------------------------------------------------------------
// Temporary *Basic* Character Select (Fix for crashing)
// By Spooky (www.github.com/sporkyspork)

#include <YSI_Coding\y_hooks>

enum E_CLASS_SELECTION_DATA {

	E_PLAYER_CLASS_SEL_ACTOR_ID,
	E_PLAYER_CLASS_SEL_CHARID,
	bool: E_PLAYER_CLASS_SEL_IN_MENU
} ;

new PlayerClassSelection [ MAX_PLAYERS ] [ E_CLASS_SELECTION_DATA ];

static const VW_OFFSET = 1;         // players get set to VW_OFFSET + playerid
static CharSelDlgStr[1024];

// Sets up the character selection scene (private world and camera) for a player.
static SetupCharSelection(playerid, bool:fade=true)
{
    // Sets up the necessary per player things for char select (like pointing their cam)
    SetPlayerInterior(playerid, 1);
    SetPlayerVirtualWorld(playerid, VW_OFFSET + playerid);
    //SetPlayerCameraPos(playerid, 1528.7101, -12.3516, 1002.8298);
    //SetPlayerCameraLookAt(playerid, 1528.3658, -11.4135, 1002.5910);

    // SetPlayerCameraPos(playerid, 1.8082, -5.6132, 1000.3386);
    // SetPlayerCameraLookAt(playerid, 1.3201, -4.7420, 1000.2086);

    //2026
    // SetPlayerCameraPos(playerid, 2448.6985, -1690.5172, 1014.5659);
    // SetPlayerCameraLookAt(playerid, 2449.3438, -1691.2830, 1014.4268);
    SetPlayerCameraPos(playerid, 2538.6060, -1673.2448, 1015.4846);
    SetPlayerCameraLookAt(playerid, 2537.7869, -1673.8113, 1015.5803);

    if (fade)
    {
        UpdateZone(playerid, "Character Selection");
        BlackScreen(playerid);
        FadeIn(playerid, false);	
    }
}

// Sets up the character creation scene (private world and camera).
static SetupCharCreate(playerid)
{
    SetPlayerInterior(playerid, 18);
    SetPlayerVirtualWorld(playerid, VW_OFFSET + playerid);
    //SetPlayerCameraPos(playerid, 1521.9221, -48.3268, 1003.4403);
    //SetPlayerCameraLookAt(playerid, 1522.2780, -47.3941, 1003.2604);

    SetPlayerCameraPos(playerid, 176.1759, -89.3137, 1002.5829);
    SetPlayerCameraLookAt(playerid, 177.0978, -88.9296, 1002.4378);
    
}

// Shows the character selection dialog with names and last played date.
static ShowCharSelectDialog(playerid)
{
    // printf("ShowCharSelectDialog: %d", playerid);

    format(CharSelDlgStr, sizeof(CharSelDlgStr), "ID\tName\tLast Played");
    new count = GetCharacterCount(playerid);

    new year, month, day, hour, minute, second;

    for ( new i, j = count; i < j ; i ++ )
    {
        if (CharacterBuffer[playerid][i][E_CHAR_BUFFER_LAST_LOGIN])
        {
            stamp2datetime(CharacterBuffer[playerid][i][E_CHAR_BUFFER_LAST_LOGIN], year, month, day, hour, minute, second, 1);
            format(CharSelDlgStr, sizeof(CharSelDlgStr), "%s\n%d\t%s\t%s %d, %d", CharSelDlgStr, CharacterBuffer[playerid][i][E_CHAR_BUFFER_ID], CharacterBuffer[playerid][i][E_CHAR_BUFFER_RP_NAME], date_getMonth(month), day, year);
        }
        else
        {
            format(CharSelDlgStr, sizeof(CharSelDlgStr), "%s\n%d\t%s\t%s", CharSelDlgStr, CharacterBuffer[playerid][i][E_CHAR_BUFFER_ID], CharacterBuffer[playerid][i][E_CHAR_BUFFER_RP_NAME], "Never");
        }
    }

    // Character creation is done on the UCP only.
    // if (count < MAX_CHARACTERS)
    // {
    //     strcat(CharSelDlgStr, "\n*\tCreate New Character");
    // }

    inline DlgCharSelect(pid, dialogid, response, listitem, string:inputtext[] )
    {
		#pragma unused pid, dialogid, response, listitem, inputtext

		if (!response) // Quit
        {
			KickPlayer(playerid);
			return true ;
		}

        if (listitem < count)
        {
            // Select
            return Account_LoadCharacterData(playerid, CharacterBuffer [ playerid ] [ listitem ] [ E_CHAR_BUFFER_ID ]);
        }

        // They clicked the UCP note row - character creation is on the UCP only, so just re-show the list.
        ShowCharSelectDialog(playerid);
        return true ;
    }

    Dialog_ShowCallback(playerid, using inline DlgCharSelect, DIALOG_STYLE_TABLIST_HEADERS, "Select Character", CharSelDlgStr, "Select", "Quit");
    SendClientMessage(playerid, COLOR_WHITE, "New characters can be created on the UCP - " SERVER_WEBSITE "");
    return true;
}

// Moves the player into the character selection scene.
ORP_ShowCharSelection(playerid, charid, bool:fade=true)
{
    #pragma unused charid

    // printf("ORP_ShowCharSelection: %d", playerid);
    SetupCharSelection(playerid, fade);
    PlayerVar[playerid][E_PLAYER_CREATING_CHAR] = false;

    defer OnShowCharSelection(playerid);
}

// Timer: shows the character selection dialog after the scene has loaded.
timer OnShowCharSelection[1000](playerid) 
{
    ShowCharSelectDialog(playerid);
	return 1;	
}

// Timer: shows the character creation attribute editor after the scene has loaded.
timer OnShowCharCreation[2500](playerid) 
{
	//Player_ShowSkinMenu(playerid); // old <
    ORP_ShowPlayerAttributes(playerid, playerid); // new
	return 1;	
}

// Moves the player into the character creation scene.
ORP_ShowCharCreation(playerid, charid)
{
    #pragma unused charid

    // printf("ORP_ShowCharCreation: %d", playerid);
    SetupCharCreate(playerid);
    defer OnShowCharCreation(playerid);
    PlayerVar[playerid][E_PLAYER_CREATING_CHAR] = true;
}

// Stub kept for compatibility with an older class browser UI.
ClassBrowser_HideTextDraws(playerid) 
{
    #pragma unused playerid
    return 1;
}

// Stub kept for compatibility with an older class browser UI.
ClassBrowser_LoadStaticDraws() 
{
	return 1;
}

// Stub kept for compatibility with an older class browser UI.
ClassBrowser_LoadPlayerDraws(playerid) 
{
    #pragma unused playerid
	return 1;
}

// Stub kept for compatibility with an older class browser UI.
ClassBrowser_DestroyPlayerDraws(playerid) 
{
    #pragma unused playerid
    return 1;
}

// Hook of Char Creation Attributes
hook ORP_OnEditAttributes(playerid)
{
    // Confirm creation
    if (PlayerVar[playerid][E_PLAYER_CREATING_CHAR])
    {
        new sex = 0;
        if (Character[playerid][E_CHARACTER_ATTRIB_SEX] == E_ATTRIBUTE_SEX_FEMALE) sex = 1;

        new race = 3;
        if (Character[playerid][E_CHARACTER_ATTRIB_RACE] == E_ATTRIBUTE_RACE_WHITE) race = 2;
        else if (Character[playerid][E_CHARACTER_ATTRIB_RACE] == E_ATTRIBUTE_RACE_BLACK) race = 0;
        else if (Character[playerid][E_CHARACTER_ATTRIB_RACE] == E_ATTRIBUTE_RACE_LATIN) race = 1;

        Player_SetupSpawnVariables(playerid, race, sex);
    }

    return 1;
}

