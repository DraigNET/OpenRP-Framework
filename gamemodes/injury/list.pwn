// ============================================================================
// File: injury/list.pwn
// /damages and /showinjuries: shows the wounds a player or corpse has (type and body part).
// Commands: /damages /showinjuries
// ============================================================================

enum WoundData {
	dmg_player,
	dmg_giver[32],
	dmg_weapon,
	dmg_bodypart,
	Float: dmg_amount
} ;

static const KO_FlavorLines[][] = {
    "Broken nose - bent out of place, blood pouring down their face. ",
	"Split lip - deep cut, already swelling and darkening.",
	"Swollen eye - puffed up and nearly shut.",
	"Cut eyebrow - bleeding freely, streaking down their skin.",
	"Jaw hit - they flinch at the slightest movement, something feels wrong.",
	"Concussion signs - barely responsive, breathing shallow and uneven.",
	"Bruised cheekbone - swelling fast under the eye.",
	"Ringing ears - disoriented, struggling to stay present.",
	"Bloody mouth - a loose tooth, blood pooling inside.",
	"Temple lump - skin tight, bruising deepening.",
	"Chin cut - open and still slowly bleeding.",
	"Neck strain - head tilting, muscles twitching uncontrollably.",
	"Scalp cut - bleeding heavily, messy but not as bad as it looks.",
	"Forehead welt - raised and raw where the skin scraped.",
	"Dazed look - eyes open but empty, not really there."
};

#define KO_FLAVOR_COUNT (15)
#define KO_FLAVOR_SHOW  (4)

#define MAX_WOUNDS	( MAX_PLAYERS * 10 )
new PlayerWounds [ MAX_WOUNDS ] [ WoundData ] ;

Wounds_LoadEntities ( ) {

	for ( new i; i < MAX_WOUNDS; i ++ ) {
		PlayerWounds [ i ] [ dmg_player ] = -1 ;
		PlayerWounds [ i ] [ dmg_giver ][0] = EOS;
		PlayerWounds [ i ] [ dmg_bodypart ] = -1 ;
		PlayerWounds [ i ] [ dmg_weapon] = -1 ;
		PlayerWounds [ i ] [ dmg_amount ] = 0.0 ;
	}

	return true ;
}

GetFreeWoundID ( ) {

	for ( new i; i < MAX_WOUNDS; i ++ ) {

		if ( PlayerWounds [ i ] [ dmg_player ] == -1 ) {

			return i ;
		}

		else continue ;
	}

	return -1 ;
}

CMD:damages(playerid, params[]) {

	return cmd_showinjuries(playerid, params);
}

static InjuriesDlgStr[2500];

// /showinjuries [player] - shows someone's wounds, or those of a body next to you.
CMD:showinjuries(playerid, params[])
{
    new target;

    if (sscanf(params, "k<player>", target))
    {
        // No target given - check for a body at the player's feet instead.
        new corpse = Corpse_GetNearest(playerid, CORPSE_REMOVE_RANGE);
        if (corpse != -1)
            return Corpse_ShowDamages(playerid, corpse);

        return SendServerMessage(playerid, COLOR_INJURY, "Syntax", "A3A3A3", "/showinjuries [target] - or stand next to a body.");
    }

    if (!IsPlayerConnected(target))
        return SendServerMessage(playerid, COLOR_INJURY, "Syntax", "A3A3A3", "Target isn't connected.");

    if (!IsPlayerNearPlayer(playerid, target, 5.0) && GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
        return SendServerMessage(playerid, COLOR_INJURY, "Syntax", "A3A3A3", "You're not close enough to this player to check their injuries.");

    if (IsPlayerKnockedOut(target))
    {
		// custom dialog for knocked out players
        new dlgstr[1024];
        format(dlgstr, sizeof(dlgstr), "Location\tObservation\n");

        new picked[KO_FLAVOR_SHOW];
        new pickCount = 0;

        while (pickCount < KO_FLAVOR_SHOW)
        {
            new idx = random(KO_FLAVOR_COUNT);
            new bool:duplicate = false;

            for (new j = 0; j < pickCount; j++)
            {
                if (picked[j] == idx) { duplicate = true; break; }
            }

            if (!duplicate)
            {
                picked[pickCount++] = idx;

                new line[128];
                format(line, sizeof(line), "%s", KO_FlavorLines[idx]);

                new dashPos = -1;
                for (new c = 0; c < strlen(line) - 2; c++)
                {
                    if (line[c] == '-' && line[c-1] == ' ' && line[c+1] == ' ')
                    {
                        dashPos = c;
                        break;
                    }
                }

                if (dashPos != -1)
                {
                    new location[64], observation[96];
                    strmid(location,    line, 0,          dashPos - 1, sizeof(location));
                    strmid(observation, line, dashPos + 2, strlen(line), sizeof(observation));
                    strcat(dlgstr, sprintf("\n{7EB0D6}%s\t{FFFFFF}%s", location, observation));
                }
                else
                {
                    strcat(dlgstr, sprintf("\n{7EB0D6}Injury\t{FFFFFF}%s", line));
                }
            }
        }

        new remaining = KO_GetRemainingTicks(target);
        ShowPlayerDialog(playerid, 546, DIALOG_STYLE_TABLIST_HEADERS,
            sprintf("Injuries to %s (%d) - Knocked Out (%ds remaining)",
                ReturnSettingsName(target, playerid), target, remaining),
            dlgstr, "Close", "");

        return true;
    }

    new count;
    new Float:head, Float:torso;
    Wounds_GetWoundDamage(target, BODY_PART_HEAD,  head);
    Wounds_GetWoundDamage(target, BODY_PART_TORSO, torso);

    format(InjuriesDlgStr, sizeof(InjuriesDlgStr), "Injury\tType\tDamage");
    if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR)
    {
        strcat(InjuriesDlgStr, "\tPlayer");
    }

    for (new i; i < MAX_WOUNDS; i++)
    {
        if (PlayerWounds[i][dmg_player] != target) continue;

        new color = 0;

        if (PlayerWounds[i][dmg_bodypart] == BODY_PART_TORSO || PlayerWounds[i][dmg_bodypart] == BODY_PART_HEAD)
        {
            color = 0xFFFF00;

            if (PlayerVar[target][E_PLAYER_INJUREDMODE])
            {
                if (PlayerWounds[i][dmg_bodypart] == BODY_PART_HEAD  && head  > INJURY_CRITICAL_DMG_HEAD)  color = 0xFF0000;
                if (PlayerWounds[i][dmg_bodypart] == BODY_PART_TORSO && torso > INJURY_CRITICAL_DMG_TORSO) color = 0xFF0000;
            }
        }

        if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR)
        {
            if (color)
                strcat(InjuriesDlgStr, sprintf("\n{%06x}%s\t{%06x}%s\t{%06x}(%0.1f)\t{%06x}%s", color, GetBodyPartName(PlayerWounds[i][dmg_bodypart]), color, GetWoundType(PlayerWounds[i][dmg_weapon]), color, PlayerWounds[i][dmg_amount], color, PlayerWounds[i][dmg_giver]));
            else
                strcat(InjuriesDlgStr, sprintf("\n%s\t%s\t(%0.1f)\t%s", GetBodyPartName(PlayerWounds[i][dmg_bodypart]), GetWoundType(PlayerWounds[i][dmg_weapon]), PlayerWounds[i][dmg_amount], PlayerWounds[i][dmg_giver]));
        }
        else
        {
            if (color)
                strcat(InjuriesDlgStr, sprintf("\n{%06x}%s\t{%06x}%s\t{%06x}(%0.1f)", color, GetBodyPartName(PlayerWounds[i][dmg_bodypart]), color, GetWoundType(PlayerWounds[i][dmg_weapon]), color, PlayerWounds[i][dmg_amount]));
            else
                strcat(InjuriesDlgStr, sprintf("\n%s\t%s\t(%0.1f)", GetBodyPartName(PlayerWounds[i][dmg_bodypart]), GetWoundType(PlayerWounds[i][dmg_weapon]), PlayerWounds[i][dmg_amount]));
        }

        count++;
    }

    if (count == 0)
        return SendServerMessage(playerid, COLOR_INJURY, "Injury", "A3A3A3", sprintf("%s (%d) has no visible injuries.", ReturnSettingsName(target, playerid), target));

    ShowPlayerDialog(playerid, 546, DIALOG_STYLE_TABLIST_HEADERS,
        sprintf("Injuries to %s (%d)\n", ReturnSettingsName(target, playerid), target),
        InjuriesDlgStr, "Close", "");

    return true;
}

SetPlayerWound ( playerid, weaponid, bodypart, Float: amount, giver=-1) {

	if ( weaponid == 0 || weaponid == 41 ) {

		return true ;
	}

	new woundid = GetFreeWoundID ( ) ;

	if ( woundid == -1 ) {

		return printf("Tried setting wound for player %s (%d) [DATA: wep %d amount %.02f] but GetFreeWoundID() returned -1.", ReturnRPName ( playerid ), playerid, weaponid, amount ) ;
	}

	PlayerWounds [ woundid ] [ dmg_player ] 	= playerid ;
	PlayerWounds [ woundid ] [ dmg_weapon ] 	= weaponid ;
	PlayerWounds [ woundid ] [ dmg_bodypart ] 	= bodypart ;
	format(PlayerWounds [ woundid ] [ dmg_giver ], 32, ReturnRPName(giver));
	PlayerWounds [ woundid ] [ dmg_amount ]		= amount ;

	return true ;
}

// Returns how many wounds a player has on a body part.
Wounds_GetWoundCount(playerid, bodypart) {

	new count = 0 ;

	for ( new i; i < sizeof ( PlayerWounds ); i ++ ) {

		if ( PlayerWounds [ i ] [ dmg_player ] == playerid ) {

			if ( PlayerWounds [ i ] [ dmg_bodypart ] == bodypart ) {

				count ++ ;
			}

			else continue ;
		}

		else continue ;
	}

	return count ;
}


// Returns the damage a player has taken on a body part.
Wounds_GetWoundDamage(playerid, bodypart, &Float:damage) {

	damage = 0.0;

	for ( new i; i < sizeof ( PlayerWounds ); i ++ ) {

		if ( PlayerWounds [ i ] [ dmg_player ] == playerid ) {

			if ( PlayerWounds [ i ] [ dmg_bodypart ] == bodypart ) {

				damage += PlayerWounds [ i ] [ dmg_amount ];
			}

			else continue ;
		}

		else continue ;
	}
}

ResetPlayerWounds ( playerid ) {

	for ( new i; i < sizeof ( PlayerWounds ); i ++ ) {

		if ( PlayerWounds [ i ] [ dmg_player ] == playerid ) {

			PlayerWounds [ i ] [ dmg_player ] 	= -1 ;

			PlayerWounds [ i ] [ dmg_weapon ] 	= -1 ;
			PlayerWounds [ i ] [ dmg_bodypart ] = -1 ;
			PlayerWounds [ i ] [ dmg_giver ] = -1 ;

			PlayerWounds [ i ] [ dmg_amount ]	= 0.0 ;

		}

		else continue ;
	}

	return true ;
}

GetWoundType ( weaponid ) {

	new woundtype [ 25 ] ;

	switch ( weaponid ) {

		case 0: woundtype = "Fist";
		case 1 .. 3, 5 .. 7, 10 .. 15: woundtype = "Blunt Trauma" ;
		case 4, 8 .. 9: woundtype = "Stab Wound" ;
		case 22 .. 34: woundtype = "Gunshot Wound" ;
		case 18, 35 .. 37, 16, 39 .. 40: woundtype = "Burn Wound" ;
		default: woundtype = "Unknown";
	}

	return woundtype ;
}

GetBodyPartName ( bodypart ) {
	new bodypartname [ 25 ] ;

	switch ( bodypart ) {
		case BODY_PART_GROIN: 		bodypartname = "Groin" ;
		case BODY_PART_TORSO: 		bodypartname = "Torso" ;
		case BODY_PART_LEFT_ARM:	bodypartname = "Left Arm" ;
		case BODY_PART_RIGHT_ARM:	bodypartname = "Right Arm" ;
		case BODY_PART_LEFT_LEG: 	bodypartname = "Left Leg" ;
		case BODY_PART_RIGHT_LEG:	bodypartname = "Right Leg" ;
		case BODY_PART_HEAD:		bodypartname = "Head" ;
		default: {

			bodypartname = "Unknown";
		}
	}

	return bodypartname ;
}
