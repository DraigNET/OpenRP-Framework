// ============================================================================
// File: news/header.pwn
// News faction/outlet helpers: IsPlayerInNewsFaction() and GetPlayerOutletName(). Created by
// Sporky.
// ============================================================================

//------------------------------------------------------------------------------
// Legal RP Project - RP News Faction
// Created by Sporky (www.github.com/sporkyspork)

#include "news/broadcast.pwn" // talkshow system
#include "news/breaking.pwn" // breaking news announcement

IsPlayerInNewsFaction(playerid, bool:onduty=false)
{
	return IsPlayerInFactionType(playerid, FACTION_TYPE_NEWS, onduty) || (IsPlayerInFirmField(playerid, FIRM_FIELD_MEDIA, onduty) && Firm_PlayerHasPerm(playerid,FIRM_PERM_FIELD_TOOLS));
}

// The outlet a reporter is currently reporting for - a Media firm's
// abbreviation if they're in one, otherwise their News faction's
// abbreviation, otherwise empty. Captured at broadcast-start time and stored
// per-broadcast so history/leaderboards stay accurate even if someone later
// leaves the firm they were reporting for.
GetPlayerOutletName(playerid, name[], len = sizeof(name))
{
	if (IsPlayerInFirm(playerid))
	{
		new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

		if (Firm_IsValid(firm_enum_id) && Firm[firm_enum_id][E_FIRM_FIELD] == FIRM_FIELD_MEDIA)
		{
			format(name, len, "%s", Firm[firm_enum_id][E_FIRM_ABBREV]);
			return true;
		}
	}

	if (Character[playerid][E_CHARACTER_FACTIONID])
	{
		new faction_enum_id = Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);

		if (faction_enum_id != INVALID_FACTION_ID && Faction[faction_enum_id][E_FACTION_TYPE] == FACTION_TYPE_NEWS)
		{
			format(name, len, "%s", Faction[faction_enum_id][E_FACTION_ABBREV]);
			return true;
		}
	}

	name[0] = EOS;
	return false;
}

//format seconds as Xh YYm  ("1h 04m")
stock FormatAirTime(seconds, output[], maxlen)
{
    format(output, maxlen, "%dh %02dm", seconds / 3600, (seconds % 3600) / 60);
}

