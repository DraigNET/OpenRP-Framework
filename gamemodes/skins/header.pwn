// ============================================================================
// File: skins/header.pwn
// Player skins: SetPlayerSkinEx() changes and saves the character's skin, ORP_SetPlayerSkin()
// applies the saved skin on spawn. Stock skins by default; optional ACP models require FEATURE_CUSTOM_SKINS.
// ============================================================================

// Stock skins (0-311) by default. Optional ACP models are loaded by skins/custom.pwn.

#include <YSI_Coding\y_hooks>
#include "skins/custom.pwn"

SetPlayerSkinEx(playerid, skinid, bool:add_wardrobe = false) {


    if (skinid >= 20000) {
        #if FEATURE_CUSTOM_SKINS
            new base = CustomSkins_AllowedBase(playerid, skinid);
            if (base == -1) return 0;
            SetPlayerSkin(playerid, skinid);
        #else
            return 0;
        #endif
    } else {
        if (skinid < 0 || skinid > 311 || skinid == 74) return 0;
        SetPlayerSkin(playerid, skinid);
    }

	Character [ playerid ] [ E_CHARACTER_SKINID ] = skinid ;
	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_skinid = %d WHERE player_id = %d",
		skinid, Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query);

	if (add_wardrobe)
	{
		mysql_format(mysql, query, sizeof(query), "INSERT INTO player_wardrobes (`player_wardrobe_char_id`, `player_wardrobe_skin_id`) VALUES (%d, %d) ON DUPLICATE KEY UPDATE `player_wardrobe_skin_lastused` = CURRENT_TIMESTAMP", Character[playerid][E_CHARACTER_ID], skinid);
		mysql_tquery(mysql, query);
	}

	// Keep the wardrobe's "last used" up to date
	mysql_format(mysql, query, sizeof ( query ), "UPDATE player_wardrobes SET player_wardrobe_skin_lastused = CURRENT_TIMESTAMP WHERE player_wardrobe_skin_id = %d AND player_wardrobe_char_id = %d", skinid, Character[playerid][E_CHARACTER_ID]);
	mysql_tquery(mysql, query);
    return 1;
}

// Applies the character's saved skin.
ORP_SetPlayerSkin(playerid) {
    new skinid = Character[playerid][E_CHARACTER_SKINID];
    if (skinid >= 20000) {
        #if FEATURE_CUSTOM_SKINS
            if (CustomSkins_AllowedBase(playerid, skinid) != -1) { SetPlayerSkin(playerid, skinid); return 1; }
        #endif
        skinid = 0;
    }
    SetPlayerSkin(playerid, skinid);
    return 1;
}

public OnPlayerSpawn(playerid) {
	// Don't set the saved skin anywhere else; doing it on spawn avoids skipped spawn functions.
	ORP_SetPlayerSkin(playerid);
	return 1;
}

Skin_GetName(skinid) {
	new name[64];
	GetSkinName(skinid, name, sizeof(name));
	return name;
}
