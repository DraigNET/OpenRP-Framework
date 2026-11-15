// ============================================================================
// File: emmet/func.pwn
// Emmet pricing and stock helpers (base cost, refill cap, refill timer, tax) and /scrapgun for
// turning a weapon back into parts.
// Commands: /scrapgun
// ============================================================================


new pFirstScrapGun[MAX_PLAYERS] = {1, ...};
bool:IsValidEmmetWeapon(weaponid);

// Records a gun purchase in the database for auditing.
Emmet_LogPurchase(playerid, emmet_index, weapon_constant, ammo, price)
{
    new query[512], emmet_weapon_name[32];

    GetWeaponName(weapon_constant, emmet_weapon_name, sizeof(emmet_weapon_name));

    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `emmet_purchase_logs` (`faction_id`, `emmet_sqlid`, `emmet_name`, `buyer_character_id`, `buyer_account_id`, `buyer_character_name`, `buyer_account_name`, `buyer_faction_tier`, `weapon_id`, `weapon_name`, `weapon_ammo`, `purchase_price`) VALUES (%d, %d, '%e', %d, %d, '%e', '%e', %d, %d, '%e', %d, %d)",
        Emmet[emmet_index][E_EMMET_OWNEDBY],
        Emmet[emmet_index][E_EMMET_SQLID],
        Emmet[emmet_index][E_EMMET_NAME],
        Character[playerid][E_CHARACTER_ID],
        Account[playerid][E_PLAYER_ACCOUNT_ID],
        Character[playerid][E_CHARACTER_NAME],
        Account[playerid][E_PLAYER_ACCOUNT_NAME],
        Character[playerid][E_CHARACTER_FACTIONTIER],
        weapon_constant,
        emmet_weapon_name,
        ammo,
        price
    );
    mysql_tquery(mysql, query);
}

// Starts the refill and tax cooldowns after a weapon is bought.
Emmet_DeclareCooldowns(weapon_constant, faction_enum_id, emmet_index) {
    new refill_unix = CalculateEmmetRefillUnix(weapon_constant);
    //new refill_unix = gettime() + 60; // 1 min (testing purposes) 
    new query[256];

    switch(weapon_constant) {
        case WEAPON_COLT45: {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX] = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] = 0;
            }
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_colt45_stock = %i, emmet_colt45_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }

        case WEAPON_DEAGLE: {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX] = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] = 0;
            }
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_deagle_stock = %i, emmet_deagle_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }

        case WEAPON_UZI: {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX]  = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] = 0;
            }
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_uzi_stock = %i, emmet_uzi_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }

        case WEAPON_TEC9: {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX]  = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] = 0;
            }
            
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_tec_stock = %i, emmet_tec_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }

        case WEAPON_AK47:  {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX]  = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] = 0;
            }
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_ak47_stock = %i, emmet_ak47_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }

        case WEAPON_SHOTGUN: {

            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX]  = refill_unix;
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] --;

            if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] <= 0) {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] = 0;
            }
            mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_shotgun_stock = %i, emmet_shotgun_unix = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
            EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK], EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_UNIX], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
            mysql_tquery(mysql, query);
        }
    }
}

// Returns the time at which a weapon's stock refills.
CalculateEmmetRefillUnix(weapon_constant) {
    new unix;
    switch(weapon_constant) {
        case WEAPON_COLT45: unix = (gettime() + (3600 * 4)); // 4 hours
        case WEAPON_DEAGLE: unix = (gettime() + (3600 * 6)); // 6 hours
        case WEAPON_UZI: unix = (gettime() + (3600 * 6)); // 6 hours
        case WEAPON_TEC9: unix = (gettime() + (3600 * 6)); // 6 hours
        case WEAPON_AK47: unix = (gettime() + (3600 * 30)); // 30 hours
        case WEAPON_SHOTGUN: unix = (gettime() + (3600 * 30)); // 30 hours
    }
    return unix;
}

// Returns the maximum stock a dealer refills to for a weapon.
CalculateEmmetRefillCap(weapon_constant) {
    new cap;
    switch(weapon_constant) {
        case WEAPON_COLT45: cap = 25; // 65 ammo
        case WEAPON_DEAGLE: cap = 7; //
        case WEAPON_UZI: cap = 12; // 200 ammo
        case WEAPON_TEC9: cap = 12; // 200 ammo
        case WEAPON_AK47: cap = 2; // 120 ammo
        case WEAPON_SHOTGUN: cap = 3; // 30 ammo
    }
    return cap;
}

// Returns the tax added to a weapon's price.
CalculateEmmetTax(weapon_constant) {
    new tax;
    switch(weapon_constant) {
        case WEAPON_COLT45: tax = 250;
        case WEAPON_DEAGLE: tax = 400;
        case WEAPON_UZI: tax = 600;
        case WEAPON_TEC9: tax = 600;
        case WEAPON_AK47: tax = 2500;
        case WEAPON_SHOTGUN: tax = 1250;
    }
    return tax;
}
// Returns a weapon's base price.
CalculateEmmetBaseCost(weapon_constant) {
    new base_cost;
    switch(weapon_constant) {
        case WEAPON_COLT45: base_cost = 2750;
        case WEAPON_DEAGLE: base_cost = 3500;
        case WEAPON_UZI: base_cost = 6000;
        case WEAPON_TEC9: base_cost = 6000;
        case WEAPON_AK47: base_cost = 15000;
        case WEAPON_SHOTGUN: base_cost = 10000;
    }
    return base_cost;
}

// bool:EmmetSellsToFaction(emmet_index, faction_index)
// {
//     if(EmmetFaction[faction_index][emmet_index][E_EMMET_SHOTGUN_STOCK] == -1 && EmmetFaction[faction_index][emmet_index][E_EMMET_COLT45_STOCK] == -1 &&
//     EmmetFaction[faction_index][emmet_index][E_EMMET_UZI_STOCK] == -1 && EmmetFaction[faction_index][emmet_index][E_EMMET_TEC_STOCK] == -1 && 
//     EmmetFaction[faction_index][emmet_index][E_EMMET_AK47_STOCK] == -1 && EmmetFaction[faction_index][emmet_index][E_EMMET_DEAGLE_STOCK] == -1 ) return false;

//     return true;
// }
Emmet_ScrapeWeapon(playerid, emmet_index)
{
    new customweapon = GetPlayerCustomWeapon(playerid);
    if(!IsValidEmmetWeapon(customweapon))
        return SendClientMessage(playerid, COLOR_ERROR, "You must be holding a valid weapon to scrap.");
    
    new weapon = GetPlayerWeapon(playerid);
    new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;
    
    if ( ! factionid )
        return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    
    new faction_enum_id = Faction_GetEnumID(factionid );
    
    if(EmmetFaction[faction_enum_id][emmet_index][E_EMMET_FACTION_INDEX] != Emmet[emmet_index][E_EMMET_SQLID])
        return SendClientMessage(playerid, COLOR_ERROR, "This weapon dealer doesn't accept scrapped weapons from your faction.");
    
    new base_cost = CalculateEmmetBaseCost(weapon);
    new refund = base_cost / 3; // 33% refund
    new query[256];
    
    //printf("[DEBUG] Entering switch with customweapon: %d", customweapon);
    //printf("[DEBUG] faction_enum_id: %d, emmet_index: %d", faction_enum_id, emmet_index);
    
    switch (customweapon)
    {
        case CUSTOM_COLT:
        {
            //printf("[DEBUG] Current COLT stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK],CalculateEmmetRefillCap(WEAPON_COLT45));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK] < CalculateEmmetRefillCap(WEAPON_COLT45))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK]++;
                //printf("[DEBUG] After increment COLT stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_colt45_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_COLT45_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] COLT SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] COLT stock not incremented - above cap");
            }
        }
        case CUSTOM_DEAGLE:
        {
            //printf("[DEBUG] Current DEAGLE stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK],CalculateEmmetRefillCap(WEAPON_DEAGLE));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK] < CalculateEmmetRefillCap(WEAPON_DEAGLE))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK]++;
                //printf("[DEBUG] After increment DEAGLE stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_deagle_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_DEAGLE_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] DEAGLE SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] DEAGLE stock not incremented - above cap");
            }
        }
        case CUSTOM_UZI:
        {
            //printf("[DEBUG] Current UZI stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK],CalculateEmmetRefillCap(WEAPON_UZI));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK] < CalculateEmmetRefillCap(WEAPON_UZI))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK]++;
                //printf("[DEBUG] After increment UZI stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_uzi_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_UZI_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] UZI SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] UZI stock not incremented - above cap");
            }
        }
        case CUSTOM_TEC:
        {
            //printf("[DEBUG] Current TEC stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK],CalculateEmmetRefillCap(WEAPON_TEC9));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK] < CalculateEmmetRefillCap(WEAPON_TEC9))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK]++;
                //printf("[DEBUG] After increment TEC stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_tec_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_TEC_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] TEC SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] TEC stock not incremented - above cap");
            }
        }
        case CUSTOM_AK47:
        {
            //printf("[DEBUG] Current AK47 stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK],CalculateEmmetRefillCap(WEAPON_AK47));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK] < CalculateEmmetRefillCap(WEAPON_AK47))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK]++;
                //printf("[DEBUG] After increment AK47 stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_ak47_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_AK47_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] AK47 SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] AK47 stock not incremented - above cap");
            }
        }
        case CUSTOM_SHOTGUN:
        {
            //printf("[DEBUG] Current SHOTGUN stock: %d, Refill Cap: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK],CalculateEmmetRefillCap(WEAPON_SHOTGUN));
            if (EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK] < CalculateEmmetRefillCap(WEAPON_SHOTGUN))
            {
                EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK]++;
                //printf("[DEBUG] After increment SHOTGUN stock: %d", EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK]);
                mysql_format(mysql, query, sizeof(query), "UPDATE emmet_factions SET emmet_shotgun_stock = %i WHERE emmet_faction_index = %i AND emmet_faction_fid = %i",
                    EmmetFaction[faction_enum_id][emmet_index][E_EMMET_SHOTGUN_STOCK], Emmet[emmet_index][E_EMMET_SQLID], Faction[faction_enum_id][E_FACTION_ID]);
                //printf("[DEBUG] SHOTGUN SQL Query: %s", query);
                mysql_tquery(mysql, query);
            }
            else
            {
                //printf("[DEBUG] SHOTGUN stock not incremented - above cap");
            }
        }
        default:
        {
            //printf("[DEBUG] Invalid weapon type: %d", customweapon);
        }
    }
    
    //printf("[DEBUG] Exiting switch statement");
    
    // Remove player's weapon
    RemovePlayerCustomWeapon(playerid, customweapon );
    GivePlayerCash(playerid, refund, "Emmet scrap gun");
    SendClientMessage(playerid, COLOR_INFO, sprintf("You've scrapped your weapon and received $%d in return.", refund));
    
    return 1;
}

// Returns true if a weapon is one a dealer can sell.
bool:IsValidEmmetWeapon(weaponid)
{
    switch(weaponid)
    {
        case CUSTOM_COLT, CUSTOM_UZI, CUSTOM_TEC, CUSTOM_AK47, CUSTOM_SHOTGUN, CUSTOM_DEAGLE: return true;
    }
    return false;
}

// /scrapgun - sells a weapon back to a dealer for a third of its value.
CMD:scrapgun(playerid) {

    if(pFirstScrapGun[playerid]) {
        return ShowFirstScrapGunDlg(playerid);
    }
    new emmet_index = Emmet_GetClosestEntity(playerid);
    if(emmet_index == INVALID_EMMET_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Gun Dealer", "DEDEDE", "You're not near a gun dealer!");
        
    return Emmet_ScrapeWeapon(playerid, emmet_index);
}

// Shows the first-time introduction to gun scrapping.
ShowFirstScrapGunDlg(playerid)
{
    new ScrapGunDlgStr[2256];
    
    format(ScrapGunDlgStr, sizeof(ScrapGunDlgStr), "{FFFFFF}Introduction to Gun Scrapping:{ADBEE6}\n");
    strcat(ScrapGunDlgStr, "- Gun scrapping allows you to turn in weapons to dealers for a partial refund of their value.\n");
    strcat(ScrapGunDlgStr, "- You'll receive {20BB12}33% {ADBEE6}of the weapon's original value when scrapping.\n");
    
    strcat(ScrapGunDlgStr, "\n{FFFFFF}How It Works:{ADBEE6}\n");
    strcat(ScrapGunDlgStr, "- Visit any gun dealer that works with your faction\n");
    strcat(ScrapGunDlgStr, "- Hold the weapon you want to scrap\n");
    strcat(ScrapGunDlgStr, "- Use the command to turn in your weapon\n");
    strcat(ScrapGunDlgStr, "- The dealer will add it to their stock and give you money\n");
    
    strcat(ScrapGunDlgStr, "\n{FFFFFF}Press {AA3333}OK{FFFFFF} to continue.\n");
    strcat(ScrapGunDlgStr, "{AA3333}This will allow you to scrap your current weapon.");
    
    inline FirstScrapGunDlg(pid, dialogid, response, listitem, string:inputtext[]) 
    {
        #pragma unused pid, dialogid, inputtext, listitem
        
        if (response)
        {
            pFirstScrapGun[playerid] = 0; // Set flag that theyve seen the dlg
            cmd_scrapgun(playerid);
        }
    }
    
    Dialog_ShowCallback(playerid, using inline FirstScrapGunDlg, DIALOG_STYLE_MSGBOX, "Gun Scrapping", ScrapGunDlgStr, "OK", "Back");
    return 1;
}


// On connect: marks that the player has not seen the scrap-gun introduction yet.
public OnPlayerConnect(playerid)
{
    pFirstScrapGun[playerid] = 1;
    
    #if defined emmet_OnPlayerConnect
        return emmet_OnPlayerConnect(playerid);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif

#define OnPlayerConnect emmet_OnPlayerConnect
#if defined emmet_OnPlayerConnect
    forward emmet_OnPlayerConnect(playerid);
#endif
