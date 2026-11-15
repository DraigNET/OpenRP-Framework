// ============================================================================
// File: gangzones/drugnpc/interface.pwn
// Dialogs for the dealer NPC system: managing stock, setting prices and viewing business stats.
// ============================================================================


new bool: PlayerIsBuying[MAX_PLAYERS];

// Writes the name of a drug variety (tier) into output.
GetDrugTierName(drug_type, tier, output[], len) {
    switch(drug_type) {
        case E_DRUG_TYPE_WEED:  format(output, len, "%s", Weed[tier][E_WEED_NAME]);
        case E_DRUG_TYPE_CRACK: format(output, len, "%s", Crack[tier][E_CRACK_NAME]);
        case E_DRUG_TYPE_COKE:  format(output, len, "%s", Cocaine[tier][E_COKE_NAME]);
        default:                format(output, len, "Unknown");
    }
}

// Writes the generic drug name (Weed, Crack, Cocaine) into output.
GetDrugGenericName(drug_type, output[], len) {
    switch(drug_type) {
        case E_DRUG_TYPE_WEED:  format(output, len, "Weed");
        case E_DRUG_TYPE_CRACK: format(output, len, "Crack");
        case E_DRUG_TYPE_COKE:  format(output, len, "Cocaine");
        default:                format(output, len, "Unknown");
    }
}

// Writes the colour tag used to display a drug type.
GetDrugColorTag(drug_type, output[], len) {
    switch(drug_type) {
        case E_DRUG_TYPE_WEED:  format(output, len, "{6BBF8E}");
        case E_DRUG_TYPE_CRACK: format(output, len, "{7A9FBB}");
        case E_DRUG_TYPE_COKE:  format(output, len, "{A9B4BE}");
        default:                format(output, len, "{C4CBD2}");
    }
}

// Returns the price per gram a street boss NPC charges for a drug.
stock GetNPCDrugPrice(npc_slot, drug_type) {
    switch(drug_type) {
        case E_DRUG_TYPE_WEED:  return StreetBossNPC[npc_slot][E_STREET_NPC_WEED_PRICE];
        case E_DRUG_TYPE_CRACK: return StreetBossNPC[npc_slot][E_STREET_NPC_CRACK_PRICE];
        case E_DRUG_TYPE_COKE:  return StreetBossNPC[npc_slot][E_STREET_NPC_COCAINE_PRICE];
    }
    return 0;
}

// Junkies dont care about tier they just want Weed / Crack / Cocaine

// Shows the dialog where a player sells drugs to a junkie NPC.
ShowJunkieDialog(playerid, junkie_slot) {
    if(junkie_slot < 0 || junkie_slot >= MAX_ACTIVE_JUNKIES ||
       !JunkieActor[junkie_slot][E_JUNKIE_CREATED]) return 0;

    //per-player sell cooldown check
    new current_time = gettime();
    if(PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] > current_time) {
        new remaining = PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] - current_time;
        new cd_str[16];
        FormatCooldownTime(remaining, cd_str, sizeof(cd_str));
        SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}You're on a sell cooldown. You can sell again in {C8A45A}%s{D0D5DA}.", cd_str));
        return 0;
    }

    new Float: player_weed = 0.0, Float: player_crack = 0.0, Float: player_cocaine = 0.0;
    for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
        if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] == E_DRUG_TYPE_NONE) continue;
        switch(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE]) {
            case E_DRUG_TYPE_WEED:  player_weed    += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
            case E_DRUG_TYPE_CRACK: player_crack   += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
            case E_DRUG_TYPE_COKE:  player_cocaine += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
        }
    }

    new dialog_str[1024], temp_str[128];
    new bool: has_demands = false;

    format(dialog_str, sizeof(dialog_str), "Drug\tWanted\tPrice/g\tYou Have\tAction\n");

    if(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND] > 0) {
        format(temp_str, sizeof(temp_str), "{6BBF8E}Weed\t%dg\t$%d\t%.1fg\t%s\n",
            JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND],
            JunkieActor[junkie_slot][E_JUNKIE_WEED_PRICE],
            player_weed,
            (player_weed >= float(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND])) ? "{7EC8A4}SELL" : "{C47070}Not enough"
        );
        strcat(dialog_str, temp_str);
        has_demands = true;
    }

    if(JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND] > 0) {
        format(temp_str, sizeof(temp_str), "{7A9FBB}Crack\t%dg\t$%d\t%.1fg\t%s\n",
            JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND],
            JunkieActor[junkie_slot][E_JUNKIE_CRACK_PRICE],
            player_crack,
            (player_crack >= float(JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND])) ? "{7EC8A4}SELL" : "{C47070}Not enough"
        );
        strcat(dialog_str, temp_str);
        has_demands = true;
    }

    if(JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] > 0) {
        format(temp_str, sizeof(temp_str), "{A9B4BE}Cocaine\t%dg\t$%d\t%.1fg\t%s",
            JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND],
            JunkieActor[junkie_slot][E_JUNKIE_COCAINE_PRICE],
            player_cocaine,
            (player_cocaine >= float(JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND])) ? "{7EC8A4}SELL" : "{C47070}Not enough"
        );
        strcat(dialog_str, temp_str);
        has_demands = true;
    }

    if(!has_demands) {
        SendClientMessage(playerid, COLOR_RED, "* This junkie is not looking for any drugs right now.");
        return 0;
    }

    inline OnJunkieDialogResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        if(!response) return 1;

        new drug_type       = -1;
        new Float: required = 0.0;
        new price_per_gram  = 0;
        new demand_field    = 0; // 0=weed 1=crack 2=cocaine - used to zero the demand
        new line            = 0;

        if(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND] > 0) {
            if(listitem == line) {
                drug_type      = E_DRUG_TYPE_WEED;
                required       = float(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND]);
                price_per_gram = JunkieActor[junkie_slot][E_JUNKIE_WEED_PRICE];
                demand_field   = 0;
            }
            line++;
        }
        if(JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND] > 0) {
            if(listitem == line) {
                drug_type      = E_DRUG_TYPE_CRACK;
                required       = float(JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND]);
                price_per_gram = JunkieActor[junkie_slot][E_JUNKIE_CRACK_PRICE];
                demand_field   = 1;
            }
            line++;
        }
        if(JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] > 0) {
            if(listitem == line) {
                drug_type      = E_DRUG_TYPE_COKE;
                required       = float(JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND]);
                price_per_gram = JunkieActor[junkie_slot][E_JUNKIE_COCAINE_PRICE];
                demand_field   = 2;
            }
        }

        if(drug_type == -1) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid selection.");
            return 1;
        }

        new Float: player_amount = 0.0;
        for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
            if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] == drug_type)
                player_amount += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
        }

        if(player_amount < required) {
            SendClientMessage(playerid, COLOR_RED, "* You don't have enough of this drug to sell.");
            return 1;
        }

        new Float: remaining = required;
        for(new i = 0; i < MAX_PLAYER_DRUGS && remaining > 0.0; i++) {
            if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] == drug_type &&
               PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] > 0.0) {
                if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] <= remaining) {
                    remaining -= PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
                    PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] = 0.0;
                    PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE]   = E_DRUG_TYPE_NONE;
                } else {
                    PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] -= remaining;
                    remaining = 0.0;
                }
            }
        }

        new total_payment = floatround(required * float(price_per_gram));
        GivePlayerCash(playerid, total_payment, "Drug NPC sale");

        new Float: px, Float: py, Float: pz;
        GetPlayerPos(playerid, px, py, pz);
        ProxDetectorXYZ(px, py, pz, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid),
            6.0, 0x87CEEBFF,
            sprintf("* %s hands something to a person on the street.", ReturnRPName(playerid))
        );

        PlayerDrugDealer[playerid][E_PLAYER_DRUG_SALES_TODAY]++;
        PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES]++;
        PlayerDrugDealer[playerid][E_PLAYER_LAST_SALE_TIME] = gettime();

        JunkieActor[junkie_slot][E_JUNKIE_HAD_SALE] = true;

        ApplyDealTransactionAnimations(playerid, JunkieActor[junkie_slot][E_JUNKIE_ACTOR_ID]);

        if(CanPlayerRankUp(playerid)) {
            PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK]++;
            SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}Congratz! You've been promoted to {FFD700}%s{D0D5DA}!", GetRankName(PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK])));

            UpdateDrugDealerLabel(playerid, PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK]);
        }

        switch(demand_field) {
            case 0: JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND]    = 0;
            case 1: JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND]   = 0;
            case 2: JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] = 0;
        }

        new bool: junkie_fully_satisfied = (
            JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND]    == 0 &&
            JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND]   == 0 &&
            JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] == 0
        );

        if(junkie_fully_satisfied) {
            // 1: junkie despawns after this sale - cooldown triggers immediately
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] = gettime() + JUNKIE_PLAYER_COOLDOWN_TIME;
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]   = false;
        } else if(PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]) {
            // 2: junkie still alive, but player already sold once before without a despawn - second sale hits, cooldown triggers now
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] = gettime() + JUNKIE_PLAYER_COOLDOWN_TIME;
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]   = false;
        } else {
            // 3: junkie still alive, first sale - mark pending, no cooldown yet
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE] = true;
        }

        SavePlayerDrugDealerData(playerid);
        PlayerDrugs_Save(playerid);

        new generic_name[16];
        GetDrugGenericName(drug_type, generic_name, sizeof(generic_name));
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}You sold {7EC8A4}%.1fg {D0D5DA}of {7EC8A4}%s {D0D5DA}for {7EC8A4}$%s{D0D5DA} to this junkie!",
            required, generic_name, IntegerWithDelimiter(total_payment))
        );
        
        if(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND]    == 0 &&
           JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND]   == 0 &&
           JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] == 0) {
            SendClientMessage(playerid, 0x87CEEBFF, "{87CEEB}* {D0D5DA}The junkie is satisfied and disappears.");
            SetTimerEx("DelayedDespawnJunkie", 2000, false, "ii", junkie_slot, 1);
        }

        if(PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] > gettime()) {
            new cd_str[16];
            FormatCooldownTime(JUNKIE_PLAYER_COOLDOWN_TIME, cd_str, sizeof(cd_str));
            SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}You're now on a {C8A45A}%s{D0D5DA} sell cooldown.", cd_str));
        }

        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnJunkieDialogResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Street Junkie",
        dialog_str, "Sell", "Cancel");

    return 1;
}


// Shows the buy menu of a street boss NPC.
ShowStreetBossNPCDialog(playerid, npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS ||
       !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED]) return 0;

    new dialog_str[1024], temp_str[128];
    new bool: has_stock = false;

    format(dialog_str, sizeof(dialog_str), "Drug\tStock\tPrice/g\tAction\n");

    new entry_map[MAX_NPC_STOCK_ENTRIES];
    new entry_count = 0;

    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] <= 0.0) continue;

        new drug_type = NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE];
        new tier      = NPCStock[npc_slot][i][E_STOCK_TIER];

        new tier_name[32], color_tag[12];
        GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));
        GetDrugColorTag(drug_type, color_tag, sizeof(color_tag));

        format(temp_str, sizeof(temp_str), "%s%s\t%.1fg\t$%d\t{7EC8A4}BUY\n",
            color_tag, tier_name,
            NPCStock[npc_slot][i][E_STOCK_AMOUNT],
            NPCStock[npc_slot][i][E_STOCK_PRICE]
        );
        strcat(dialog_str, temp_str);
        entry_map[entry_count] = i;
        entry_count++;
        has_stock = true;
    }

    if(!has_stock) {
        SendClientMessage(playerid, COLOR_RED, "* This dealer is out of stock.");
        return 0;
    }

    inline OnStreetNPCResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) return 1;
        if(listitem < 0 || listitem >= entry_count) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid selection.");
            return 1;
        }
        ShowCustomBuyDialog(playerid, npc_slot, entry_map[listitem]);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnStreetNPCResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Street Dealer - Buy Drugs",
        dialog_str, "Buy", "Cancel");

    return 1;
}
// Shows the dialog to buy a custom amount of a drug from an NPC.
ShowCustomBuyDialog(playerid, npc_slot, entry_idx) {
    if(PlayerIsBuying[playerid]) {
        SendClientMessage(playerid, COLOR_RED, "* You already have a purchase in progress.");
        return 0;
    }

    if(NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT] <= 0.0) {
        SendClientMessage(playerid, COLOR_RED, "* This drug is no longer in stock.");
        ShowStreetBossNPCDialog(playerid, npc_slot);
        return 0;
    }

    new drug_type = NPCStock[npc_slot][entry_idx][E_STOCK_DRUG_TYPE];
    new tier = NPCStock[npc_slot][entry_idx][E_STOCK_TIER];
    new Float: avail_stock = NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT];
    new price_per_gram     = NPCStock[npc_slot][entry_idx][E_STOCK_PRICE];

    new drug_name[32];
    GetDrugTierName(drug_type, tier, drug_name, sizeof(drug_name));

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Buy %s\n\n{D0D5DA}Available Stock: {7EC8A4}%.1f grams\n{D0D5DA}Price: {7EC8A4}$%d per gram\n\n Enter the amount you want to buy:",
        drug_name, avail_stock, price_per_gram
    );

    PlayerIsBuying[playerid] = true;

    inline OnCustomBuyResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem

        if(!response) {
            PlayerIsBuying[playerid] = false;
            ShowStreetBossNPCDialog(playerid, npc_slot);
            return 1;
        }

        new Float: live_stock = NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT];
        if(live_stock <= 0.0) {
            PlayerIsBuying[playerid] = false;
            SendClientMessage(playerid, COLOR_RED, "* This drug is no longer in stock.");
            ShowStreetBossNPCDialog(playerid, npc_slot);
            return 1;
        }

        new Float: amount = floatstr(inputtext);

        amount = float(floatround(amount, floatround_floor));
        if(amount < 1.0 || amount > live_stock) {
            PlayerIsBuying[playerid] = false;
            SendClientMessage(playerid, COLOR_RED, "* Invalid amount. Enter a value between 1 and the available stock.");
            ShowCustomBuyDialog(playerid, npc_slot, entry_idx);
            return 1;
        }

        new total_cost = floatround(amount * float(price_per_gram));
        if(GetPlayerCash(playerid) < total_cost) {
            PlayerIsBuying[playerid] = false;
            SendClientMessage(playerid, COLOR_RED, "* You don't have enough money.");
            ShowCustomBuyDialog(playerid, npc_slot, entry_idx);
            return 1;
        }

        new added = PlayerDrugs_AddSimple(playerid, drug_type, amount, tier);
        if(!added) {
            PlayerIsBuying[playerid] = false;
            SendClientMessage(playerid, COLOR_RED, "* Your drug inventory is full.");
            ShowCustomBuyDialog(playerid, npc_slot, entry_idx);
            return 1;
        }

        TakePlayerCash(playerid, total_cost, "Drug NPC buy");

        StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS]    += total_cost;
        StreetBossNPC[npc_slot][E_STREET_NPC_TOTAL_SALES]++;

        new Float: pd_x, Float: pd_y, Float: pd_z;
        GetPlayerPos(playerid, pd_x, pd_y, pd_z);
        ProxDetectorXYZ(pd_x, pd_y, pd_z, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid),
            6.0, 0x87CEEBFF,
            sprintf("* %s buys something from a street dealer.", ReturnRPName(playerid))
        );

        ApplyDealTransactionAnimations(playerid, StreetBossNPC[npc_slot][E_STREET_NPC_ID]);
        SetTimerEx("DelayedApplyIdleAnimation", 3000, false, "i", npc_slot);

        NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT] -= amount;
        if(NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT] <= 0.0)
            DeleteNPCStockEntry(npc_slot, entry_idx);
        else
            SaveNPCStockEntry(npc_slot, entry_idx);

        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE `street_boss_npcs` SET `earnings` = %d, `total_sales` = %d WHERE `id` = %d",
            StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS],
            StreetBossNPC[npc_slot][E_STREET_NPC_TOTAL_SALES],
            StreetBossNPC[npc_slot][E_STREET_NPC_SQLID]
        );
        mysql_tquery(mysql, query);

        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}You bought {7EC8A4}%.1fg {D0D5DA}of {7EC8A4}%s {D0D5DA}for {7EC8A4}$%s{D0D5DA}!", amount, drug_name, IntegerWithDelimiter(total_cost))
        );

        PlayerIsBuying[playerid] = false;
        ShowStreetBossNPCDialog(playerid, npc_slot);
        return 1;
    }

    new buy_title[48];
    format(buy_title, sizeof(buy_title), "Buy %s", drug_name);
    Dialog_ShowCallback(playerid, using inline OnCustomBuyResponse,
        DIALOG_STYLE_INPUT, buy_title, dialog_str, "Buy", "Back");

    return 1;
}

// Shows the street boss's management menu for their NPC.
ShowStreetBossManagementDialog(playerid, npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS ||
       !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED] ||
       StreetBossNPC[npc_slot][E_STREET_NPC_OWNER] != Character[playerid][E_CHARACTER_ID]) return 0;

    new dialog_str[1024];
    format(dialog_str, sizeof(dialog_str),
        "Option\tInformation\n{C8A45A}Business Statistics\t{D0D5DA}View earnings and sales data\n{8BAFC4}Inventory Management\t{C4CBD2}Manage stock and pricing\n{7EC8A4}Quick Restock\t{C4CBD2}Add all drugs from inventory\n{C8A45A}Collect Earnings\t{C4CBD2}Withdraw $%s in profits\n{C47070}Dismiss Dealer\t{C4CBD2}Remove dealer permanently",
        IntegerWithDelimiter(StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS])
    );

    inline OnManagementResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) return 1;

        switch(listitem) {
            case 0: ShowBusinessStatsDialog(playerid, npc_slot);
            case 1: ShowInventoryManagementDialog(playerid, npc_slot);
            case 2: ShowQuickRestockDialog(playerid, npc_slot);
            case 3: {
                if(StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS] <= 0) {
                    SendClientMessage(playerid, COLOR_RED, "* No earnings to collect.");
                    ShowStreetBossManagementDialog(playerid, npc_slot);
                    return 1;
                }
                new earnings = StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS];
                GivePlayerCash(playerid, earnings, "Drug NPC earnings collect");
                StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS] = 0;

                new query[128];
                mysql_format(mysql, query, sizeof(query),
                    "UPDATE `street_boss_npcs` SET `earnings` = 0 WHERE `id` = %d",
                    StreetBossNPC[npc_slot][E_STREET_NPC_SQLID]
                );
                mysql_tquery(mysql, query);

                SendClientMessage(playerid, 0xC8A45AFF,
                    sprintf("{C8A45A}* {D0D5DA}You collected {7EC8A4}$%s {D0D5DA}from your dealer!", IntegerWithDelimiter(earnings)));
                ShowStreetBossManagementDialog(playerid, npc_slot);
            }
            case 4: {
                ReturnAllNPCStockToPlayer(npc_slot, playerid);
                new earnings = StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS];
                if(earnings > 0) {
                    GivePlayerCash(playerid, earnings, "Drug NPC earnings collect");
                    SendClientMessage(playerid, 0xC8A45AFF,
                        sprintf("{C8A45A}* {D0D5DA}You collected {7EC8A4}$%s {D0D5DA}before dismissing your dealer.", IntegerWithDelimiter(earnings)));
                }
                DestroyStreetBossNPC(npc_slot);
                SendClientMessage(playerid, 0xC8A45AFF, "{C8A45A}* {D0D5DA}Your street dealer has been dismissed.");
            }
        }
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnManagementResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Street Dealer Management",
        dialog_str, "Select", "Cancel");

    return 1;
}

// Shows the NPC's sales and stock statistics.
ShowBusinessStatsDialog(playerid, npc_slot) {
    new Float: weed_total    = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_WEED);
    new Float: crack_total   = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_CRACK);
    new Float: cocaine_total = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_COKE);

    new dialog_str[512];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Business Statistics\n\n{D0D5DA}Total Earnings: {7EC8A4}$%s\n{D0D5DA}Total Sales Made: {7EC8A4}%d transactions\n\n{8BAFC4}Current Stock Levels:\n{6BBF8E}» Weed: {D0D5DA}%.1f grams ({6BBF8E}$%d{D0D5DA}/g)\n{7A9FBB}» Crack: {D0D5DA}%.1f grams ({7A9FBB}$%d{D0D5DA}/g)\n{A9B4BE}» Cocaine: {D0D5DA}%.1f grams ({A9B4BE}$%d{D0D5DA}/g)",
        IntegerWithDelimiter(StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS]),
        StreetBossNPC[npc_slot][E_STREET_NPC_TOTAL_SALES],
        weed_total,    StreetBossNPC[npc_slot][E_STREET_NPC_WEED_PRICE],
        crack_total,   StreetBossNPC[npc_slot][E_STREET_NPC_CRACK_PRICE],
        cocaine_total, StreetBossNPC[npc_slot][E_STREET_NPC_COCAINE_PRICE]
    );

    inline OnStatsResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem, inputtext
        if(response) ShowStreetBossManagementDialog(playerid, npc_slot);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnStatsResponse,
        DIALOG_STYLE_MSGBOX, "Business Statistics",
        dialog_str, "Back", "Close");

    return 1;
}

// Shows the NPC's inventory list so the owner can edit entries.
ShowInventoryManagementDialog(playerid, npc_slot) {
    new dialog_str[1024], temp_str[128];
    format(dialog_str, sizeof(dialog_str), "Drug / Tier\tStock\tPrice/g\tAction\n");

    new entry_map[MAX_NPC_STOCK_ENTRIES + 1];
    new entry_count = 0;

    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] <= 0.0) continue;

        new drug_type = NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE];
        new tier      = NPCStock[npc_slot][i][E_STOCK_TIER];
        new tier_name[32], color_tag[12];
        GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));
        GetDrugColorTag(drug_type, color_tag, sizeof(color_tag));

        format(temp_str, sizeof(temp_str), "%s%s\t%.1fg\t$%d\t{C8A45A}MANAGE\n",
            color_tag, tier_name, NPCStock[npc_slot][i][E_STOCK_AMOUNT], NPCStock[npc_slot][i][E_STOCK_PRICE]);
        strcat(dialog_str, temp_str);
        entry_map[entry_count] = i;
        entry_count++;
    }

    strcat(dialog_str, "{7EC8A4}+ Add Stock\t\t\t");
    entry_map[entry_count] = -1;

    inline OnInventoryResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) { ShowStreetBossManagementDialog(playerid, npc_slot); return 1; }
        if(listitem < 0 || listitem > entry_count) { ShowInventoryManagementDialog(playerid, npc_slot); return 1; }
        if(listitem == entry_count) { ShowAddStockDialog(playerid, npc_slot); return 1; }
        ShowStockEntryManagementDialog(playerid, npc_slot, entry_map[listitem]);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnInventoryResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Inventory Management",
        dialog_str, "Select", "Back");

    return 1;
}

// Shows the options for one stock entry (change price, take stock back).
ShowStockEntryManagementDialog(playerid, npc_slot, entry_idx) {
    if(entry_idx < 0 || entry_idx >= MAX_NPC_STOCK_ENTRIES ||
       NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT] <= 0.0) {
        ShowInventoryManagementDialog(playerid, npc_slot);
        return 1;
    }

    new drug_type     = NPCStock[npc_slot][entry_idx][E_STOCK_DRUG_TYPE];
    new tier          = NPCStock[npc_slot][entry_idx][E_STOCK_TIER];
    new Float: amount = NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT];
    new price         = NPCStock[npc_slot][entry_idx][E_STOCK_PRICE];
    new tier_name[32], color_tag[12];
    GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));
    GetDrugColorTag(drug_type, color_tag, sizeof(color_tag));

    new dialog_str[512], temp_str[128];
    format(temp_str, sizeof(temp_str), "{707880}  Stock: {D0D5DA}%.1fg\n", amount);         strcat(dialog_str, temp_str);
    format(temp_str, sizeof(temp_str), "{707880}  Price: {C8A45A}$%d per gram\n", price);   strcat(dialog_str, temp_str);
    strcat(dialog_str, "{C8A45A}Set Price\n");
    strcat(dialog_str, "{C47070}Remove Stock (return to me)");

    inline OnEntryMgmtResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) { ShowInventoryManagementDialog(playerid, npc_slot); return 1; }

        if(listitem == 2) {
            ShowEntrySetPriceDialog(playerid, npc_slot, entry_idx);
        } else if(listitem == 3) {
            PlayerDrugs_AddSimple(playerid, drug_type, amount, tier);
            PlayerDrugs_Save(playerid);
            DeleteNPCStockEntry(npc_slot, entry_idx);

            new local_tier_name[32];
            GetDrugTierName(drug_type, tier, local_tier_name, sizeof(local_tier_name));
            SendClientMessage(playerid, 0xC8A45AFF,
                sprintf("{C8A45A}* {D0D5DA}Returned {7EC8A4}%.1fg {D0D5DA}of {7EC8A4}%s {D0D5DA}to your inventory.", amount, local_tier_name));
            ShowInventoryManagementDialog(playerid, npc_slot);
        } else {
            ShowStockEntryManagementDialog(playerid, npc_slot, entry_idx);
        }
        return 1;
    }

    new entry_title[64];
    format(entry_title, sizeof(entry_title), "%s%s Management", color_tag, tier_name);
    Dialog_ShowCallback(playerid, using inline OnEntryMgmtResponse,
        DIALOG_STYLE_LIST, entry_title, dialog_str, "Select", "Back");

    return 1;
}

// Shows the dialog to set the price of an existing stock entry.
ShowEntrySetPriceDialog(playerid, npc_slot, entry_idx) {
    new drug_type     = NPCStock[npc_slot][entry_idx][E_STOCK_DRUG_TYPE];
    new tier          = NPCStock[npc_slot][entry_idx][E_STOCK_TIER];
    new current_price = NPCStock[npc_slot][entry_idx][E_STOCK_PRICE];
    new tier_name[32];
    GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Set Price - %s\n\n{D0D5DA}Current Price: {7EC8A4}$%d per gram\n\nEnter the new price per gram:",
        tier_name, current_price
    );

    inline OnEntrySetPriceResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem
        if(!response) { ShowStockEntryManagementDialog(playerid, npc_slot, entry_idx); return 1; }

        new new_price = strval(inputtext);
        if(new_price < 1 || new_price > 10000) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid price. Enter a value between $1 and $10,000.");
            ShowEntrySetPriceDialog(playerid, npc_slot, entry_idx);
            return 1;
        }

        NPCStock[npc_slot][entry_idx][E_STOCK_PRICE] = new_price;
        SaveNPCStockEntry(npc_slot, entry_idx);

        new local_tier_name[32];
        GetDrugTierName(drug_type, tier, local_tier_name, sizeof(local_tier_name));
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Set {7EC8A4}%s {D0D5DA}price to {7EC8A4}$%d{D0D5DA} per gram!", local_tier_name, new_price));
        ShowStockEntryManagementDialog(playerid, npc_slot, entry_idx);
        return 1;
    }

    static price_title[64];
    format(price_title, sizeof(price_title), "Set Price: %s", tier_name);
    Dialog_ShowCallback(playerid, using inline OnEntrySetPriceResponse,
        DIALOG_STYLE_INPUT, price_title, dialog_str, "Set", "Back");

    return 1;
}

// Shows the drugs the player can add to the NPC's stock.
ShowAddStockDialog(playerid, npc_slot) {
    new dialog_str[1024], temp_str[128];
    format(dialog_str, sizeof(dialog_str), "Drug / Tier\tYou Have\tAction\n");

    new player_slot_map[MAX_PLAYER_DRUGS];
    new slot_count = 0;

    for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
        if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] == E_DRUG_TYPE_NONE) continue;
        if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] <= 0.0) continue;

        new drug_type = PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE];
        new tier      = PlayerDrugs[playerid][i][E_PLAYER_DRUG_PARAM];
        new tier_name[32], color_tag[12];
        GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));
        GetDrugColorTag(drug_type, color_tag, sizeof(color_tag));

        format(temp_str, sizeof(temp_str), "%s%s\t%.1fg\t{7EC8A4}ADD\n",
            color_tag, tier_name, PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT]);
        strcat(dialog_str, temp_str);
        player_slot_map[slot_count] = i;
        slot_count++;
    }

    if(slot_count == 0) {
        SendClientMessage(playerid, COLOR_RED, "* You don't have any drugs in your inventory.");
        ShowInventoryManagementDialog(playerid, npc_slot);
        return 1;
    }

    inline OnAddStockSelectResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) { ShowInventoryManagementDialog(playerid, npc_slot); return 1; }
        if(listitem < 0 || listitem >= slot_count) { ShowInventoryManagementDialog(playerid, npc_slot); return 1; }
        ShowAddStockAmountDialog(playerid, npc_slot, player_slot_map[listitem]);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnAddStockSelectResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Add Stock - Select Drug",
        dialog_str, "Select", "Back");

    return 1;
}

// Asks how many grams of a drug to add to the NPC's stock.
ShowAddStockAmountDialog(playerid, npc_slot, player_slot) {
    new drug_type         = PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_TYPE];
    new tier              = PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_PARAM];
    new Float: max_amount = PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT];
    new tier_name[32];
    GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Add %s\n\n{D0D5DA}You have: {7EC8A4}%.1f grams\n\nEnter the amount to add to your dealer:",
        tier_name, max_amount
    );

    inline OnAddAmountResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem
        if(!response) { ShowAddStockDialog(playerid, npc_slot); return 1; }
        new Float: amount = floatstr(inputtext);
        if(amount <= 0.0 || amount > max_amount) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid amount.");
            ShowAddStockAmountDialog(playerid, npc_slot, player_slot);
            return 1;
        }
        ShowAddStockPriceDialog(playerid, npc_slot, player_slot, drug_type, tier, amount);
        return 1;
    }

    static amount_title[64];
    format(amount_title, sizeof(amount_title), "Add Stock: %s", tier_name);
    Dialog_ShowCallback(playerid, using inline OnAddAmountResponse,
        DIALOG_STYLE_INPUT, amount_title, dialog_str, "Next", "Back");

    return 1;
}

// Asks the price per gram for stock being added.
ShowAddStockPriceDialog(playerid, npc_slot, player_slot, drug_type, tier, Float: amount) {
    new tier_name[32];
    GetDrugTierName(drug_type, tier, tier_name, sizeof(tier_name));

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Set Price - %s\n\n{D0D5DA}Adding: {7EC8A4}%.1f grams\n\nEnter the price per gram for this stock:",
        tier_name, amount
    );

    inline OnAddPriceResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem
        if(!response) { ShowAddStockAmountDialog(playerid, npc_slot, player_slot); return 1; }

        new price = strval(inputtext);
        if(price < 1 || price > 10000) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid price. Enter a value between $1 and $10,000.");
            ShowAddStockPriceDialog(playerid, npc_slot, player_slot, drug_type, tier, amount);
            return 1;
        }

        new Float: to_take = amount;
        if(PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT] < to_take)
            to_take = PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT];

        PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT] -= to_take;
        if(PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT] <= 0.0) {
            PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_AMOUNT] = 0.0;
            PlayerDrugs[playerid][player_slot][E_PLAYER_DRUG_TYPE]   = E_DRUG_TYPE_NONE;
        }
        PlayerDrugs_Save(playerid);
        AddNPCStock(npc_slot, drug_type, tier, to_take, price);

        new Float: pd_x, Float: pd_y, Float: pd_z;
        GetPlayerPos(playerid, pd_x, pd_y, pd_z);
        ProxDetectorXYZ(pd_x, pd_y, pd_z, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid), 6.0, 0x87CEEBFF,
            sprintf("* %s discreetly hands something to their dealer.", ReturnRPName(playerid)));

        new local_tier_name[32];
        GetDrugTierName(drug_type, tier, local_tier_name, sizeof(local_tier_name));
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Added {7EC8A4}%.1fg {D0D5DA}of {7EC8A4}%s {D0D5DA}to your dealer's stock at {7EC8A4}$%d/g{D0D5DA}!", to_take, local_tier_name, price));
        ShowInventoryManagementDialog(playerid, npc_slot);
        return 1;
    }

    static price_title[64];
    format(price_title, sizeof(price_title), "Set Price: %s", tier_name);
    Dialog_ShowCallback(playerid, using inline OnAddPriceResponse,
        DIALOG_STYLE_INPUT, price_title, dialog_str, "Confirm", "Back");

    return 1;
}

// Shows the quick restock menu (add everything of one drug).
ShowQuickRestockDialog(playerid, npc_slot) {
    new dialog_str[1024], temp_str[128];
    format(dialog_str, sizeof(dialog_str), "Drug\tYou Have\tNPC Stock\tAction\n");

    new Float: pw = 0.0, Float: pc = 0.0, Float: pco = 0.0;
    for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
        switch(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE]) {
            case E_DRUG_TYPE_WEED:  pw  += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
            case E_DRUG_TYPE_CRACK: pc  += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
            case E_DRUG_TYPE_COKE:  pco += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
        }
    }

    format(temp_str, sizeof(temp_str), "{6BBF8E}Weed\t%.1fg\t%.1fg\t%s\n",   pw,  GetNPCTotalStock(npc_slot, E_DRUG_TYPE_WEED),  (pw  > 0.0) ? "{7EC8A4}GIVE ALL" : "{C47070}None"); strcat(dialog_str, temp_str);
    format(temp_str, sizeof(temp_str), "{7A9FBB}Crack\t%.1fg\t%.1fg\t%s\n",  pc,  GetNPCTotalStock(npc_slot, E_DRUG_TYPE_CRACK), (pc  > 0.0) ? "{7EC8A4}GIVE ALL" : "{C47070}None"); strcat(dialog_str, temp_str);
    format(temp_str, sizeof(temp_str), "{A9B4BE}Cocaine\t%.1fg\t%.1fg\t%s",  pco, GetNPCTotalStock(npc_slot, E_DRUG_TYPE_COKE),  (pco > 0.0) ? "{7EC8A4}GIVE ALL" : "{C47070}None"); strcat(dialog_str, temp_str);

    inline OnQuickRestockResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) { ShowStreetBossManagementDialog(playerid, npc_slot); return 1; }

        new drug_type = -1;
        new Float: total = 0.0;
        switch(listitem) {
            case 0: { drug_type = E_DRUG_TYPE_WEED;  total = pw;  }
            case 1: { drug_type = E_DRUG_TYPE_CRACK; total = pc;  }
            case 2: { drug_type = E_DRUG_TYPE_COKE;  total = pco; }
        }

        if(drug_type == -1 || total <= 0.0) {
            SendClientMessage(playerid, COLOR_RED, "* You don't have any of this drug.");
            ShowQuickRestockDialog(playerid, npc_slot);
            return 1;
        }
        ShowQuickRestockPriceDialog(playerid, npc_slot, drug_type);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnQuickRestockResponse,
        DIALOG_STYLE_TABLIST_HEADERS, "Quick Restock Dealer",
        dialog_str, "Give All", "Back");

    return 1;
}

// Asks the price when quick-restocking a drug.
ShowQuickRestockPriceDialog(playerid, npc_slot, drug_type) {
    new Float: total = 0.0;
    for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
        if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] == drug_type &&
           PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] > 0.0)
            total += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
    }

    new generic[16];
    GetDrugGenericName(drug_type, generic, sizeof(generic));

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "{C8A45A}Quick Restock - Set Price\n\n{D0D5DA}Giving all {7EC8A4}%.1fg{D0D5DA} of %s to your dealer.\n\nEnter the price per gram for this stock:",
        total, generic
    );

    inline OnQuickPriceResponse(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem
        if(!response) { ShowQuickRestockDialog(playerid, npc_slot); return 1; }

        new price = strval(inputtext);
        if(price < 1 || price > 10000) {
            SendClientMessage(playerid, COLOR_RED, "* Invalid price. Enter a value between $1 and $10,000.");
            ShowQuickRestockPriceDialog(playerid, npc_slot, drug_type);
            return 1;
        }

        switch(drug_type) {
            case E_DRUG_TYPE_WEED:  StreetBossNPC[npc_slot][E_STREET_NPC_WEED_PRICE]    = price;
            case E_DRUG_TYPE_CRACK: StreetBossNPC[npc_slot][E_STREET_NPC_CRACK_PRICE]   = price;
            case E_DRUG_TYPE_COKE:  StreetBossNPC[npc_slot][E_STREET_NPC_COCAINE_PRICE] = price;
        }

        new Float: total_given = 0.0;
        for(new i = 0; i < MAX_PLAYER_DRUGS; i++) {
            if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE] != drug_type) continue;
            if(PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] <= 0.0)    continue;
            AddNPCStock(npc_slot, drug_type,
                PlayerDrugs[playerid][i][E_PLAYER_DRUG_PARAM],
                PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT], price);
            total_given += PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT];
            PlayerDrugs[playerid][i][E_PLAYER_DRUG_AMOUNT] = 0.0;
            PlayerDrugs[playerid][i][E_PLAYER_DRUG_TYPE]   = E_DRUG_TYPE_NONE;
        }
        PlayerDrugs_Save(playerid);

        new local_generic[16];
        GetDrugGenericName(drug_type, local_generic, sizeof(local_generic));
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Gave {7EC8A4}%.1fg {D0D5DA}of {7EC8A4}%s {D0D5DA}to your dealer at {7EC8A4}$%d/g{D0D5DA}!", total_given, local_generic, price));

        new Float: pd_x, Float: pd_y, Float: pd_z;
        GetPlayerPos(playerid, pd_x, pd_y, pd_z);
        ProxDetectorXYZ(pd_x, pd_y, pd_z, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid), 6.0, 0x87CEEBFF,
            sprintf("* %s discreetly hands something to their dealer.", ReturnRPName(playerid)));

        ShowQuickRestockDialog(playerid, npc_slot);
        return 1;
    }

    static price_title[48];
    format(price_title, sizeof(price_title), "Quick Restock: %s", generic);
    Dialog_ShowCallback(playerid, using inline OnQuickPriceResponse,
        DIALOG_STYLE_INPUT, price_title, dialog_str, "Set & Restock", "Back");

    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerDisconnect(playerid, reason) {
    PlayerIsBuying[playerid] = false;
    return 1;
}
