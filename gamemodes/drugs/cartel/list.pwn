// ============================================================================
// File: drugs/cartel/list.pwn
// The supplier menu where faction leaders buy drug supplies (/buysupplies), with a purchase
// cooldown (HandleFactionPerkCD) and /factionresetperkcd for staff.
// Commands: /buysupplies /factionresetperkcd /passsupply
// ============================================================================

// /buysupplies - opens the supplier menu at a cartel location.
CMD:buysupplies(playerid, params[]) {

	new id = Cartel_GetClosestEntity(playerid);

	if (id == INVALID_DRUG_ID) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You're not near a supply point.");
	}

	switch (Cartel[id][E_CARTEL_SUPPLY_TYPE]) {
		case E_DRUG_TYPE_WEED: {
			if (!MatchPlayerFactionType(playerid, E_FACTION_EXTRA_CARTEL) && !MatchPlayerFactionType(playerid, E_FACTION_EXTRA_DRUGS_WEED)) {
				return SendClientMessage(playerid, -1, "Your faction does not have access to weed production!");
			}
		}
		case E_DRUG_TYPE_COKE: {
			if (!MatchPlayerFactionType(playerid, E_FACTION_EXTRA_CARTEL) && !MatchPlayerFactionType(playerid, E_FACTION_EXTRA_DRUGS_COKE)) {
				return SendClientMessage(playerid, -1, "Your faction does not have access to cocaine production!");
			}
		}
		case E_DRUG_TYPE_CRACK: {
			if (!MatchPlayerFactionType(playerid, E_FACTION_EXTRA_GANG) && !MatchPlayerFactionType(playerid, E_FACTION_EXTRA_DRUGS_CRACK)) {
				return SendClientMessage(playerid, -1, "Your faction does not have access to crack production!");
			}
		}
		case E_DRUG_TYPE_METH: {
			if (!MatchPlayerFactionType(playerid, E_FACTION_EXTRA_GANG) && !MatchPlayerFactionType(playerid, E_FACTION_EXTRA_DRUGS_METH)) {
				return SendClientMessage(playerid, -1, "Your faction does not have access to meth production!");
			}
		}
	}

	if (Character[playerid][E_CHARACTER_FACTIONTIER] > 1 && PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] < DEALER_RANK_STREET_BOSS)
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be a Street Boss (Dealer Rank 2) to access supply points.");

	Cartel_DisplaySupplyList(playerid, Cartel[id][E_CARTEL_SUPPLY_TYPE]);

	return true;
}


// Shows the list of supplies of one drug type with prices.
Cartel_DisplaySupplyList(playerid, type) {

	new string[1024];

	format(string, sizeof(string), "Supply Info \t Price\n");

	switch (type) {
		case E_DRUG_TYPE_WEED:  format(string, sizeof(string),
			"%sMaui Waui Seed\t$600\nNorthern Lights Seed\t$800\nO.G. Kush Seed\t$1000\nPurple Kush Seed\t$1200", string);
		case E_DRUG_TYPE_COKE:  format(string, sizeof(string),
			"%sSleigh Ride Seed\t$1200\nBlanca Flakes Seed\t$1800\nGold Dust Seed\t$2400\nParadise White Seed\t$3000", string);
		case E_DRUG_TYPE_CRACK: format(string, sizeof(string),
			"%sMoon Rocks Powder\t$1400\nGravel Balls Powder\t$2000\nBoulder Cakes Powder\t$2800\nTornado Crack Powder\t$3200", string);
		case E_DRUG_TYPE_METH: return SendClientMessage(playerid, COLOR_RED, "The creation of this drug is temporarily disbanded.");
	}

	inline Cartel_Supplies(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if (response) {

			new faction_enum_id = Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);

			if (faction_enum_id == INVALID_FACTION_ID)
				return true;

			if (!HandleFactionPerkCD(playerid)) {
				SendServerMessage(playerid, COLOR_EMMET, "Cartel", "DEDEDE", sprintf("Your faction is on a cooldown. Buy more in %s.", GetCountdown(gettime(), Faction[faction_enum_id][E_FACTION_PERK_CD])));
				return true;
			}

			switch (listitem) {
				case 0: {
					switch (type) {
						case E_DRUG_TYPE_WEED:  Drugs_AddSupplyToPlayer(playerid, type, E_WEED_TYPE_MAUI_WAUI,        600);
						case E_DRUG_TYPE_COKE:  Drugs_AddSupplyToPlayer(playerid, type, E_COKE_TYPE_SLEIGH_RIDE,     1200);
						case E_DRUG_TYPE_CRACK: Drugs_AddSupplyToPlayer(playerid, type, E_CRACK_TYPE_MOON_ROCKS,     1400);
						case E_DRUG_TYPE_METH:  Drugs_AddSupplyToPlayer(playerid, type, 0, 0);
					}
				}
				case 1: {
					switch (type) {
						case E_DRUG_TYPE_WEED:  Drugs_AddSupplyToPlayer(playerid, type, E_WEED_TYPE_NORTHERN_LIGHTS,  800);
						case E_DRUG_TYPE_COKE:  Drugs_AddSupplyToPlayer(playerid, type, E_COKE_TYPE_BLANCA_FLAKES,   1800);
						case E_DRUG_TYPE_CRACK: Drugs_AddSupplyToPlayer(playerid, type, E_CRACK_TYPE_GRAVEL_BALLS,   2000);
						case E_DRUG_TYPE_METH:  Drugs_AddSupplyToPlayer(playerid, type, 0, 0);
					}
				}
				case 2: {
					switch (type) {
						case E_DRUG_TYPE_WEED:  Drugs_AddSupplyToPlayer(playerid, type, E_WEED_TYPE_OG_KUSH,        1000);
						case E_DRUG_TYPE_COKE:  Drugs_AddSupplyToPlayer(playerid, type, E_COKE_TYPE_GOLD_DUST,      2400);
						case E_DRUG_TYPE_CRACK: Drugs_AddSupplyToPlayer(playerid, type, E_CRACK_TYPE_BOULDER_CAKES, 2800);
						case E_DRUG_TYPE_METH:  Drugs_AddSupplyToPlayer(playerid, type, 0, 0);
					}
				}
				case 3: {
					switch (type) {
						case E_DRUG_TYPE_WEED:  Drugs_AddSupplyToPlayer(playerid, type, E_WEED_TYPE_PURPLE_KUSH,    1200);
						case E_DRUG_TYPE_COKE:  Drugs_AddSupplyToPlayer(playerid, type, E_COKE_TYPE_PARADISE_WHITE, 3000);
						case E_DRUG_TYPE_CRACK: Drugs_AddSupplyToPlayer(playerid, type, E_CRACK_TYPE_TORNADO_CRACK, 3200);
						case E_DRUG_TYPE_METH:  Drugs_AddSupplyToPlayer(playerid, type, 0, 0);
					}
				}
			}
		}
	}

	Dialog_ShowCallback(playerid, using inline Cartel_Supplies, DIALOG_STYLE_TABLIST_HEADERS, "Cartel Supplies", string, "Purchase", "Cancel");

	return true;
}

// Checks the faction's purchase cooldown; resets the count when it has expired. Returns false if
// the faction has hit its limit.
HandleFactionPerkCD(playerid) {
    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if (!factionid) return false;

    new faction_enum_id = Faction_GetEnumID(factionid);
    if (faction_enum_id == INVALID_FACTION_ID) return false;
	// cooldown is active
    if (Faction[faction_enum_id][E_FACTION_PERK_CD] > gettime()) return false;

	// cooldown just expired, reset buys
    if (Faction[faction_enum_id][E_FACTION_PERK_CD] != 0) {
        Faction[faction_enum_id][E_FACTION_PERK_BUYS] = 0;
        Faction[faction_enum_id][E_FACTION_PERK_CD]   = 0;

        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE factions SET faction_perk_buys = 0, faction_perk_cd = 0 WHERE faction_id = %d", factionid);
        mysql_tquery(mysql, query);
    }

    if (Faction[faction_enum_id][E_FACTION_PERK_BUYS] >= 3) return false;

    if (Faction[faction_enum_id][E_FACTION_PERK_BUYS] == 2) {
        Faction[faction_enum_id][E_FACTION_PERK_CD] = gettime() + 5400;

        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE factions SET faction_perk_cd = %d WHERE faction_id = %d",
            Faction[faction_enum_id][E_FACTION_PERK_CD], factionid);
        mysql_tquery(mysql, query);
    }

    return true;
}


// /factionresetperkcd [faction id] [type] - (staff) resets a faction's supplier cooldown.
CMD:factionresetperkcd(playerid, params[]) {
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}

	new id, type;

	if (sscanf(params, "ii", id, type)) {
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/factionresetperkcd [id]");
		return true;
	}

	if (Faction[id][E_FACTION_ID] == INVALID_FACTION_ID) {
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This faction does not exist.");
	}

	Faction[id][E_FACTION_PERK_CD]   = 0;
	Faction[id][E_FACTION_PERK_BUYS] = 0;

	new query[256];
	mysql_format(mysql, query, sizeof(query),
		"UPDATE factions SET faction_perk_cd = 0, faction_perk_buys = 0 WHERE faction_id = %d",
		Faction[id][E_FACTION_ID]
	);
	mysql_tquery(mysql, query);

	SendAdminMessage(sprintf("%s has reset the faction perk cooldown for %s.", ReturnRPName(playerid), Faction[id][E_FACTION_NAME]));

	Faction_SendMessage(Faction[id][E_FACTION_ID], sprintf("{ [%s] %s has reset the faction perk cooldown. }",
		Faction[id][E_FACTION_ABBREV], ReturnRPName(playerid)), id, false
	);

	return 1;
}

/*
// /passsupply [player] [slot] - a tier 1 faction member hands one of their supplies to a nearby
// member.
CMD:passsupply(playerid, params[]) {

    if (Character[playerid][E_CHARACTER_FACTIONTIER] != 1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Only Tier 1 members can pass supplies.");

    new targetid, slot;

    if (sscanf(params, "ui", targetid, slot))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/passsupply [playerid] [slot 0-2]");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is not connected.");

    if (targetid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You cannot pass supplies to yourself.");

    if (Character[targetid][E_CHARACTER_FACTIONID] != Character[playerid][E_CHARACTER_FACTIONID])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is not in your faction.");

    if (Character[targetid][E_CHARACTER_FACTIONTIER] != 2)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only pass supplies to a Tier 2 member.");

    new Float: tx, Float: ty, Float: tz ;
	GetPlayerPos ( targetid, tx, ty, tz ) ;

	if ( ! IsPlayerInRangeOfPoint ( playerid, 2.5, tx, ty, tz ) ) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be closer to that player.");

    if (slot < 0 || slot > 2)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid slot. Use 0, 1 or 2.");

    new supplySubType, drugType = -1;

    if (Character[playerid][E_CHARACTER_WEED_SUPPLIES][slot]) {
        drugType     = E_DRUG_TYPE_WEED;
        supplySubType = Character[playerid][E_CHARACTER_WEED_SUPPLIES][slot];
    }
    else if (Character[playerid][E_CHARACTER_COKE_SUPPLIES][slot]) {
        drugType     = E_DRUG_TYPE_COKE;
        supplySubType = Character[playerid][E_CHARACTER_COKE_SUPPLIES][slot];
    }
    else if (Character[playerid][E_CHARACTER_CRACK_SUPPLIES][slot]) {
        drugType     = E_DRUG_TYPE_CRACK;
        supplySubType = Character[playerid][E_CHARACTER_CRACK_SUPPLIES][slot];
    }
    else if (Character[playerid][E_CHARACTER_METH_SUPPLIES][slot]) {
        drugType     = E_DRUG_TYPE_METH;
        supplySubType = Character[playerid][E_CHARACTER_METH_SUPPLIES][slot];
    }

    if (drugType == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You have no supply in that slot.");

    new targetSlot = -1;

    switch (drugType) {
        case E_DRUG_TYPE_WEED: {
            for (new i = 0; i < 3; i++) {
                if (!Character[targetid][E_CHARACTER_WEED_SUPPLIES][i]) {
                    targetSlot = i;
                    break;
                }
            }
            if (targetSlot == -1)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player has no free weed supply slots.");

            Character[targetid][E_CHARACTER_WEED_SUPPLIES][targetSlot] = supplySubType;
            Character[playerid][E_CHARACTER_WEED_SUPPLIES][slot]       = 0;
        }
        case E_DRUG_TYPE_COKE: {
            for (new i = 0; i < 3; i++) {
                if (!Character[targetid][E_CHARACTER_COKE_SUPPLIES][i]) {
                    targetSlot = i;
                    break;
                }
            }
            if (targetSlot == -1)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player has no free coke supply slots.");

            Character[targetid][E_CHARACTER_COKE_SUPPLIES][targetSlot] = supplySubType;
            Character[playerid][E_CHARACTER_COKE_SUPPLIES][slot]       = 0;
        }
        case E_DRUG_TYPE_CRACK: {
            for (new i = 0; i < 3; i++) {
                if (!Character[targetid][E_CHARACTER_CRACK_SUPPLIES][i]) {
                    targetSlot = i;
                    break;
                }
            }
            if (targetSlot == -1)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player has no free crack supply slots.");

            Character[targetid][E_CHARACTER_CRACK_SUPPLIES][targetSlot] = supplySubType;
            Character[playerid][E_CHARACTER_CRACK_SUPPLIES][slot]       = 0;
        }
        case E_DRUG_TYPE_METH: {
            for (new i = 0; i < 3; i++) {
                if (!Character[targetid][E_CHARACTER_METH_SUPPLIES][i]) {
                    targetSlot = i;
                    break;
                }
            }
            if (targetSlot == -1)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player has no free meth supply slots.");

            Character[targetid][E_CHARACTER_METH_SUPPLIES][targetSlot] = supplySubType;
            Character[playerid][E_CHARACTER_METH_SUPPLIES][slot]       = 0;
        }
    }

    new supplyName[32];

    switch (drugType) {
        case E_DRUG_TYPE_WEED:  format(supplyName, sizeof(supplyName), "%s", Weed[supplySubType][E_WEED_NAME]);
        case E_DRUG_TYPE_COKE:  format(supplyName, sizeof(supplyName), "%s", Cocaine[supplySubType][E_COKE_NAME]);
        case E_DRUG_TYPE_CRACK: format(supplyName, sizeof(supplyName), "%s", Crack[supplySubType][E_CRACK_NAME]);
    }

    SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("You passed your %s (slot %d) to %s.", supplyName, slot, ReturnRPName(targetid)));
    SendServerMessage(targetid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("%s passed you a %s.", ReturnRPName(playerid), supplyName));

    return 1;
}
*/
