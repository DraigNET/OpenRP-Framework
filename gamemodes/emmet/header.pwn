// ============================================================================
// File: emmet/header.pwn
// Emmet gun-dealer entry point and /buygun. This system is optional and switched off by
// default; the guns it sold are not available unless you enable FEATURE_EMMET.
// Commands: /buygun
// ============================================================================

#include "emmet/data.pwn"
#include "emmet/func.pwn"
//#include "emmet/admin.pwn"   // Emmet gun system disabled -- admin commands off (code kept)
#include "emmet/player.pwn"
//#include "emmet/crates.pwn"

// /buygun - opens the weapon menu of the nearest dealer. The whole system is switched off unless
// EMMET_GUNS_ENABLED is true.
CMD:buygun(playerid, params[]) {

    // Emmet gun-dealer system is disabled -- guns are no longer sold through it.
    // Body kept intact; flip EMMET_GUNS_ENABLED to true to restore.
    static bool:EMMET_GUNS_ENABLED = false;
    if (!EMMET_GUNS_ENABLED)
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "The gun dealer system is currently disabled.");

    if(!CanPlayerUseGuns(playerid, 8, -1)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "You need at least 8 hours to buy a gun!");
    }

    new emmet_index = Emmet_GetClosestEntity(playerid);
    if(emmet_index == INVALID_EMMET_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "You're not near a gun dealer!");
    }

    new string[2048], title[64];

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if(!factionid) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    new faction_enum_id = Faction_GetEnumID(factionid);
    if(faction_enum_id == INVALID_FACTION_ID) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    new faction_tier = Character[playerid][E_CHARACTER_FACTIONTIER];

    if(Emmet[emmet_index][E_EMMET_OWNEDBY] != factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "This gun dealer only sells to members of their own faction!");
    }

    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_FACTION_INDEX] != Emmet[emmet_index][E_EMMET_SQLID]) {
        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "The gun dealer doesn't sell weapons to your faction!");
    }

    if(faction_tier > 3) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit any weapon purchases!");
    }

    if(Emmet[emmet_index][E_EMMET_OWNEDBY] == Character[playerid][E_CHARACTER_FACTIONID]) {
        SendClientMessage(playerid, COLOR_YELLOW, "Your faction owns this gun dealer. You will get a cut from all profits next paycheck.");
    }

    Emmet_TriggerAnims(emmet_index);
    SendClientMessage(playerid, COLOR_RED, "Warning: stacking ammo is NOT possible! If you attempt it, you will NOT be refunded!");

    new weapon_cost, weapon_timestamp[96];
    strcat(string, "{DEDEDE}Weapon Name\t{DEDEDE}Stock Left\t{DEDEDE}Time Until Refill\t{DEDEDE}Cost\n");

    if(faction_tier <= 3) {
        // Colt 45
        weapon_cost = CalculateEmmetBaseCost(WEAPON_COLT45) + (EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_TAX] * CalculateEmmetTax(WEAPON_COLT45));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == 0) format(string, sizeof(string), "%sColt 45\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == -1) format(string, sizeof(string), "%sColt 45\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sColt 45\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // Desert Eagle
        weapon_cost = CalculateEmmetBaseCost(WEAPON_DEAGLE) + (EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_TAX] * CalculateEmmetTax(WEAPON_DEAGLE));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == 0) format(string, sizeof(string), "%sDesert Eagle\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == -1) format(string, sizeof(string), "%sDesert Eagle\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sDesert Eagle\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }

    if(faction_tier <= 2) {
        // Uzi
        weapon_cost = CalculateEmmetBaseCost(WEAPON_UZI) + (EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_TAX] * CalculateEmmetTax(WEAPON_UZI));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == 0) format(string, sizeof(string), "%sUzi\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == -1) format(string, sizeof(string), "%sUzi\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sUzi\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // Tec 9
        weapon_cost = CalculateEmmetBaseCost(WEAPON_TEC9) + (EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_TAX] * CalculateEmmetTax(WEAPON_TEC9));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == 0) format(string, sizeof(string), "%sTec 9\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == -1) format(string, sizeof(string), "%sTec 9\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sTec 9\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }

    if(faction_tier <= 1) {
        // AK-47
        weapon_cost = CalculateEmmetBaseCost(WEAPON_AK47) + (EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_TAX] * CalculateEmmetTax(WEAPON_AK47));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == 0) format(string, sizeof(string), "%sAK-47\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == -1) format(string, sizeof(string), "%sAK-47\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sAK-47\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // Shotgun
        weapon_cost = CalculateEmmetBaseCost(WEAPON_SHOTGUN) + (EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_TAX] * CalculateEmmetTax(WEAPON_SHOTGUN));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == 0) format(string, sizeof(string), "%sShotgun\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == -1) format(string, sizeof(string), "%sShotgun\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sShotgun\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }

    format(title, sizeof(title), "%s's Wares", Emmet[emmet_index][E_EMMET_NAME]);
    inline Emmet_GunBuyHandler(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext, listitem, response

        if(response) {
            switch(listitem) {

                case 0: { // Colt 45
                    if(faction_tier > 3) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Colt stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Colts ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_COLT45)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Colts.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_COLT45) + (EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_TAX] * CalculateEmmetTax(WEAPON_COLT45));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_COLT45);
                    Emmet_DeclareCooldowns(WEAPON_COLT45, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Colt with 120 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Colt with 120 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_COLT45, 120, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_COLT, 120);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_COLT), 120);
                }
                case 1: { // Desert Eagle
                    if(faction_tier > 3) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Desert Eagle stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Desert Eagles ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_DEAGLE)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Desert Eagles.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_DEAGLE) + (EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_TAX] * CalculateEmmetTax(WEAPON_DEAGLE));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_DEAGLE);
                    Emmet_DeclareCooldowns(WEAPON_DEAGLE, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Desert Eagle with 48 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Desert Eagle with 48 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_DEAGLE, 48, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_DEAGLE, 40);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_DEAGLE), 48);
                }
                case 2: { // Uzi
                    if(faction_tier > 2) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Uzi stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Uzis ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_UZI)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Uzis.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_UZI) + (EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_TAX] * CalculateEmmetTax(WEAPON_UZI));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_UZI);
                    Emmet_DeclareCooldowns(WEAPON_UZI, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Uzi with 250 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought an Uzi with 250 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_UZI, 250, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_UZI, 250);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_UZI), 250);
                }
                case 3: { // Tec-9
                    if(faction_tier > 2) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Tec-9 stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Tec-9s ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_TEC9)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Tec 9s.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_TEC9) + (EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_TAX] * CalculateEmmetTax(WEAPON_TEC9));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_TEC9);
                    Emmet_DeclareCooldowns(WEAPON_TEC9, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Tec-9 with 250 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Tec-9 with 250 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_TEC9, 250, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_TEC, 250);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_TEC), 250);
                }
                case 4: { // AK-47
                    if(faction_tier > 1) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more AK-47 stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling AK-47s ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_AK47)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more AK-47s.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_AK47) + (EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_TAX] * CalculateEmmetTax(WEAPON_AK47));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_AK47);
                    Emmet_DeclareCooldowns(WEAPON_AK47, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased an AK-47 with 180 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought an AK-47 with 180 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_AK47, 180, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_AK47, 180);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_AK47), 180);
                }
                case 5: { // Shotgun
                    if(faction_tier > 1) return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "Your faction tier does not permit this purchase!");

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Shotgun stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Shotguns ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_SHOTGUN)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more shotguns.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.", GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_CD])));
                        return true;
                    }
                    weapon_cost = CalculateEmmetBaseCost(WEAPON_SHOTGUN) + (EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_TAX] * CalculateEmmetTax(WEAPON_SHOTGUN));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.", IntegerWithDelimiter(weapon_cost)));

                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_SHOTGUN);
                    Emmet_DeclareCooldowns(WEAPON_SHOTGUN, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase");

                    SendClientMessage(playerid, -1, sprintf("You've purchased a shotgun with 35 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a shotgun with 35 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    Emmet_LogPurchase(playerid, emmet_index, WEAPON_SHOTGUN, 35, weapon_cost);

                    GiveCustomWeapon(playerid, CUSTOM_SHOTGUN, 35);
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_SHOTGUN), 35);
                }
            }
            return true;
        }
    }
    Dialog_ShowCallback(playerid, using inline Emmet_GunBuyHandler, DIALOG_STYLE_TABLIST_HEADERS, title, string, "Purchase", "Close");

    return true;
}
/*CMD:buygun(playerid, params[]) {

    if(!CanPlayerUseGuns(playerid, 8, -1)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "You need at least 8 hours to buy a gun!");
    }

    new emmet_index = Emmet_GetClosestEntity(playerid);
    if(emmet_index == INVALID_EMMET_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "You're not near a gun dealer!");
    }

	new string [ 2048 ], title[64];

    // factionid, faction_enum_id, faction_tier
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;
	if ( ! factionid ) return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	new faction_enum_id = Faction_GetEnumID(factionid ); 
	if ( faction_enum_id == INVALID_FACTION_ID ) return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    new faction_tier = Character [ playerid ] [ E_CHARACTER_FACTIONTIER ];

    if(Emmet[emmet_index][E_EMMET_OWNEDBY] != factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "This gun dealer only sells to members of their own faction!");
    }
    
    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_FACTION_INDEX] != Emmet[emmet_index][E_EMMET_SQLID]) {
        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "The gun dealer doesn't sell weapons to your faction!");
    }

    if(Emmet[emmet_index][E_EMMET_OWNEDBY] == Character [ playerid ] [ E_CHARACTER_FACTIONID ]) {
        SendClientMessage(playerid, COLOR_YELLOW, "Your faction owns this gun dealer. You will get a cut from all profits next paycheck.");
    }

    new player_fnr_level = GetPlayerFnRLevel(playerid);

    Emmet_TriggerAnims(emmet_index); // random dealer anim on buy
	SendClientMessage(playerid, COLOR_RED, "Warning: stacking ammo is NOT possible! If you attempt it, you will NOT be refunded!");

    new weapon_cost, weapon_timestamp[96];
    strcat(string, "{DEDEDE}Weapon Name\t{DEDEDE}Stock Left\t{DEDEDE}Time Until Refill\t{DEDEDE}Cost\n");

    // Tier 3+ weapons (Colt, Uzi, Tec-9)
    if(faction_tier <= 3) {
        // Colt 45 - Tier 3+ | Level 1
        weapon_cost = CalculateEmmetBaseCost(WEAPON_COLT45) + (EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_TAX] * CalculateEmmetTax(WEAPON_COLT45));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX]));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == 0) format(string, sizeof(string), "%sColt 45\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == -1) format(string, sizeof(string), "%sColt 45\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sColt 45\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // Uzi - Tier 3+ | Level 3
        weapon_cost = CalculateEmmetBaseCost(WEAPON_UZI) + (EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_TAX] * CalculateEmmetTax(WEAPON_UZI));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX]));
        if(player_fnr_level < 3) format(string, sizeof(string), "%s{808080}Uzi\t{ff0000}Locked\t{ff0000}Level 3 Required\t{808080}$%s\n", string, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == 0) format(string, sizeof(string), "%sUzi\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == -1) format(string, sizeof(string), "%sUzi\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sUzi\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // Tec 9 - Tier 3+ | Level 5
        weapon_cost = CalculateEmmetBaseCost(WEAPON_TEC9) + (EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_TAX] * CalculateEmmetTax(WEAPON_TEC9));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX]));
        if(player_fnr_level < 5) format(string, sizeof(string), "%s{808080}Tec 9\t{ff0000}Locked\t{ff0000}Level 5 Required\t{808080}$%s\n", string, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == 0) format(string, sizeof(string), "%sTec 9\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == -1) format(string, sizeof(string), "%sTec 9\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sTec 9\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }
    
    // Tier 2+ weapons (Desert Eagle)
    if(faction_tier <= 2) {
        // Desert Eagle - Tier 2+ | Level 7
        weapon_cost = CalculateEmmetBaseCost(WEAPON_DEAGLE) + (EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_TAX] * CalculateEmmetTax(WEAPON_DEAGLE));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX]));
        if(player_fnr_level < 7) format(string, sizeof(string), "%s{808080}Desert Eagle\t{ff0000}Locked\t{ff0000}Level 7 Required\t{808080}$%s\n", string, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == 0) format(string, sizeof(string), "%sDesert Eagle\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == -1) format(string, sizeof(string), "%sDesert Eagle\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sDesert Eagle\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }

    // Tier 1 weapons (Shotgun, AK-47)
    if(faction_tier <= 1) {
        // Shotgun - Tier 1 | Level 9
        weapon_cost = CalculateEmmetBaseCost(WEAPON_SHOTGUN) + (EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_TAX] * CalculateEmmetTax(WEAPON_SHOTGUN));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX]));
        if(player_fnr_level < 9) format(string, sizeof(string), "%s{808080}Shotgun\t{ff0000}Locked\t{ff0000}Level 9 Required\t{808080}$%s\n", string, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == 0) format(string, sizeof(string), "%sShotgun\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == -1) format(string, sizeof(string), "%sShotgun\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sShotgun\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));

        // AK-47 - Tier 1 | Level 10
        weapon_cost = CalculateEmmetBaseCost(WEAPON_AK47) + (EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_TAX] * CalculateEmmetTax(WEAPON_AK47));
        if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX] == -1) format(weapon_timestamp, 12, "None");
        else format(weapon_timestamp, sizeof(weapon_timestamp), "%s", GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX]));
        if(player_fnr_level < 10) format(string, sizeof(string), "%s{808080}AK-47\t{ff0000}Locked\t{ff0000}Level 10 Required\t{808080}$%s\n", string, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == 0) format(string, sizeof(string), "%sAK-47\t{ffe100}Depleted\t{ead958}%s\t$%s\n", string, weapon_timestamp, IntegerWithDelimiter(weapon_cost));
        else if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == -1) format(string, sizeof(string), "%sAK-47\t{ff0000}Disabled by server\n", string);
        else format(string, sizeof(string), "%sAK-47\t%i\t%s\t$%s\n", string, EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK], weapon_timestamp, IntegerWithDelimiter(weapon_cost));
    }
    
	format ( title, sizeof ( title ), "%s's Wares", Emmet[emmet_index][E_EMMET_NAME]) ;
    inline Emmet_GunBuyHandler(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext, listitem, response

		if(response) {
            switch(listitem) {

                case 0: { // colt - Tier 3+ | Level 1

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Colt stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), 
                        EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Colts ((Admin Override))!");
                    }

                    if(!Emmet_CheckCooldowns(playerid, WEAPON_COLT45)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Colts.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_COLT45) + (EmmetPlayer[playerid][E_EMMET_PLAYER_COLT_TAX] * CalculateEmmetTax(WEAPON_COLT45));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
                    
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_COLT45);
                    Emmet_DeclareCooldowns(WEAPON_COLT45, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Colt with 40 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Colt with 40 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_COLT, 40) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_COLT), 40);
                }
                case 1:  { // uzi - Tier 3+ | Level 3

                    if(player_fnr_level < 3) {
                        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", sprintf("You need Fear & Respect Level 3 to buy this weapon! (Current: %d)", player_fnr_level));
                    }

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Uzi stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", 
                        GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Uzis ((Admin Override))!");
                    }

                    if(!Emmet_CheckCooldowns(playerid, WEAPON_UZI)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Uzis.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_UZI) + (EmmetPlayer[playerid][E_EMMET_PLAYER_UZI_TAX] * CalculateEmmetTax(WEAPON_UZI));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
                    
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_UZI);
                    Emmet_DeclareCooldowns(WEAPON_UZI, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Uzi with 200 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought an Uzi with 200 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_UZI, 200) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_UZI), 200);
                }
                case 2: { // tec - Tier 3+ | Level 5

                    if(player_fnr_level < 5) {
                        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", sprintf("You need Fear & Respect Level 5 to buy this weapon! (Current: %d)", player_fnr_level));
                    }

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Tec-9 stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", 
                        GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Tec-9s ((Admin Override))!");
                    }

                    if(!Emmet_CheckCooldowns(playerid, WEAPON_TEC9)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Tec 9s.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_TEC9) + (EmmetPlayer[playerid][E_EMMET_PLAYER_TEC_TAX] * CalculateEmmetTax(WEAPON_TEC9));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
                    
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_TEC9);
                    Emmet_DeclareCooldowns(WEAPON_TEC9, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Tec-9 with 200 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Tec-9 with 200 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_TEC, 200) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_TEC), 200);
                }
                case 3: { // deagle - Tier 2+ | Level 7

                    if(player_fnr_level < 7) {
                        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", sprintf("You need Fear & Respect Level 7 to buy this weapon! (Current: %d)", player_fnr_level));
                    }

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Desert Eagle stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", GetCountdown(gettime(), 
                        EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Desert Eagles ((Admin Override))!");
                    }

                    if(!Emmet_CheckCooldowns(playerid, WEAPON_DEAGLE)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more Desert Eagles.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_DEAGLE) + (EmmetPlayer[playerid][E_EMMET_PLAYER_DEAGLE_TAX] * CalculateEmmetTax(WEAPON_DEAGLE));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
                    
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_DEAGLE);
                    Emmet_DeclareCooldowns(WEAPON_DEAGLE, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased a Desert Eagle with 48 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a Desert Eagle with 48 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_DEAGLE, 40) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_DEAGLE), 48);
                }
                case 4: { // shotgun - Tier 1 | Level 9

                    if(player_fnr_level < 9) {
                        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", sprintf("You need Fear & Respect Level 9 to buy this weapon! (Current: %d)", player_fnr_level));
                    }

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more Shotgun stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", 
                        GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling Shotguns ((Admin Override))!");
                    }
                    if(!Emmet_CheckCooldowns(playerid, WEAPON_SHOTGUN)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more shotguns.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_SHOTGUN) + (EmmetPlayer[playerid][E_EMMET_PLAYER_SHOTGUN_TAX] * CalculateEmmetTax(WEAPON_SHOTGUN));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
 
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_SHOTGUN);
                    Emmet_DeclareCooldowns(WEAPON_SHOTGUN, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased a shotgun with 30 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought a shotgun with 30 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_SHOTGUN, 30) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_SHOTGUN), 30);
                }
                case 5:  { // ak - Tier 1 | Level 10

                    if(player_fnr_level < 10) {
                        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", sprintf("You need Fear & Respect Level 10 to buy this weapon! (Current: %d)", player_fnr_level));
                    }

                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == 0) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer has no more AK-47 stock left!");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("Come back in %s.", 
                        GetCountdown(gettime(), EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX])));
                        return true;
                    }
                    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] == -1) {
                        return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "This dealer is forbidden from selling AK-47s ((Admin Override))!");
                    }

                    if(!Emmet_CheckCooldowns(playerid, WEAPON_AK47)) {
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", "You are capped from buying more AK-47s.");
                        SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You can buy more in %s.",  GetCountdown(gettime(), EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_CD])));
                        return true;
                    }

                    weapon_cost = CalculateEmmetBaseCost(WEAPON_AK47) + (EmmetPlayer[playerid][E_EMMET_PLAYER_AK47_TAX] * CalculateEmmetTax(WEAPON_AK47));
                    if(GetPlayerCash(playerid) < weapon_cost) return SendServerMessage(playerid, COLOR_EMMET, "Gun Dealer", "DEDEDE", sprintf("You don't have enough money. You need at least $%s.",  IntegerWithDelimiter(weapon_cost)));
                    
                    Emmet_DeclarePlayerCooldowns(playerid, WEAPON_AK47);
                    Emmet_DeclareCooldowns(WEAPON_AK47, faction_enum_id, emmet_index);
                    TakePlayerCash(playerid, weapon_cost, "Weapon purchase") ;

                    SendClientMessage(playerid, -1, sprintf("You've purchased an AK-47 with 120 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));
                    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Bought an AK-47 with 120 ammo from %s costing $%s.", Emmet[emmet_index][E_EMMET_NAME], IntegerWithDelimiter(weapon_cost)));

                    GiveCustomWeapon(playerid, CUSTOM_AK47, 120) ;
                    ORP_SetPlayerAmmo(playerid, GetCustomWeaponGunId(CUSTOM_AK47), 120);
                }
            }

            return true;
		}
	}
 	Dialog_ShowCallback ( playerid, using inline Emmet_GunBuyHandler, DIALOG_STYLE_TABLIST_HEADERS, title, string, "Purchase", "Close" );


    return true;
}*/
