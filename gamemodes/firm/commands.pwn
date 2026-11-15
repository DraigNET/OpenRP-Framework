// ============================================================================
// File: firm/commands.pwn
// Player-run firms (companies): /firm, /firmhelp, /firmduty, /firmbank, /firmmembers,
// /firminvite, /firmkick, /firmrank, /firmresign and the staff tools for assigning firm
// vehicles. Also contains the field list (mechanic, lawyer, security, transit, media, used
// cars, real estate).
// Commands: /firmhelp /firm /firmduty /fc /firmbank /firmmembers /firminvite /firmkick
// /firmrank /firmokick /firmorank /firmresign /firmclose /firmcreate /firmvehicle
// ============================================================================

// Shows the list of firm commands the player can use.
ShowFirmCommands(playerid)
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    SendClientMessage(playerid, 0x5FB9D1FF, "[ ___________ Firm Commands ___________ ]");
    SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /firm, /firmhelp, /firmduty, /fc, /firmbank, /firmmembers");
    SendClientMessage(playerid, 0x58DD85FF, "[MEMBERS]:{B2FFCD} /firminvite, /firmkick, /firmrank, /firmresign, /firmclose");
    SendClientMessage(playerid, 0x58DD85FF, "[OFFLINE]:{B2FFCD} /firmokick [charid], /firmorank [charid] [1-4]");
    SendClientMessage(playerid, 0x58DD85FF, "[ADMINISTRATION]:{B2FFCD} /firmcreate [field] [abbrev] [name]");
    SendClientMessage(playerid, 0x58DD85FF, "[FIELDS]:{B2FFCD} mechanic, lawyer, security, transit, logistics, media, usedcars, realestate");

    if (Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_MECHANIC))
    {
        SendClientMessage(playerid, 0xFF8C00FF, "[MECHANIC]:{DEDEDE} /mechanic (bodywork, engine, oilchange, inspect, respray, paintjob...), /mtunestart, /mcancel, /mstats");
    }

    if (Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_TRANSIT))
    {
        SendClientMessage(playerid, 0xFFCC68FF, "[TRANSIT]:{DEDEDE} /fare, /startmeter, /stopmeter");
    }

    if (IsPlayerInFirmField(playerid, FIRM_FIELD_SECURITY, true))
    {
        SendClientMessage(playerid, 0x8FB6FFFF, "[SECURITY]:{DEDEDE} /cuff, /uncuff, /taser - available while on duty in a security firm");
    }

    if (CanUseLawyerTools(playerid))
    {
        SendClientMessage(playerid, 0xC9A0FFFF, "[LAWYER]:{DEDEDE} /inmates, /defend [playerid] [minutes] [price per minute]");
    }

    if (CanUseLogisticsTools(playerid))
    {
        SendClientMessage(playerid, 0x9ACD32FF, "[LOGISTICS]:{DEDEDE} /tradereport - see the best-paying commodity routes right now");
    }

    if (IsPlayerInFirmField(playerid, FIRM_FIELD_USEDCARS))
    {
        SendClientMessage(playerid, 0x2ECC71FF, "[USED CARS]:{DEDEDE} /usedpool (buy scrapped cars at a scrapyard), /usedcar [price/unlist/park/list]");
        SendClientMessage(playerid, 0x2ECC71FF, "[USED CARS]:{DEDEDE} /carsell (buy a car from a player for the firm)");
    }

    if (IsPlayerInFirmField(playerid, FIRM_FIELD_REALESTATE))
    {
        SendClientMessage(playerid, 0x2ECC71FF, "[REAL ESTATE]:{DEDEDE} /propertylist (houses to buy / for sale), /propertylist mine, /firmpropertybuy");
        SendClientMessage(playerid, 0x2ECC71FF, "[REAL ESTATE]:{DEDEDE} /propertyprice [price] (list a house for sale), /propertyrent, /housetiers");
    }

    if (IsPlayerInFirmField(playerid, FIRM_FIELD_MEDIA, true))
    {
        SendClientMessage(playerid, 0xFF6EC7FF, "[MEDIA]:{DEDEDE} /broadcast, /coanchor, /live, /breaking, /broadcasts, /newsroom, /broadcasthistory");
        SendClientMessage(playerid, 0xFF6EC7FF, "[MEDIA]:{DEDEDE} /reporterleaderboard, /outletleaderboard, /mybroadcaststats, /weeklyactivity");
    }

    return true;
}

// /firmhelp - shows the firm commands.
CMD:firmhelp(playerid, params[])
{
    #pragma unused params
    return ShowFirmCommands(playerid);
}

// /firm - shows information about your firm.
CMD:firm(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
        SendClientMessage(playerid, 0xA3A3A3FF, "Use /firmcreate at the Administration Building to register one.");
        return true;
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm could not be found in memory.");
    }

    new field_name[32];
    Firm_GetFieldName(Firm[firm_enum_id][E_FIRM_FIELD], field_name, sizeof(field_name));

    SendClientMessage(playerid, Firm[firm_enum_id][E_FIRM_HEXCOLOR], sprintf("[Firm] %s [%s] | Field: %s | Rank: %d | Bank: $%s | Duty: %s",
        Firm[firm_enum_id][E_FIRM_NAME],
        Firm[firm_enum_id][E_FIRM_ABBREV],
        field_name,
        PlayerFirm[playerid][E_PLAYER_FIRM_RANK],
        IntegerWithDelimiter(Firm[firm_enum_id][E_FIRM_BANK]),
        PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] ? ("On") : ("Off")));

    return true;
}

// /firmduty - goes on or off duty for your firm.
CMD:firmduty(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (!Firm_IsActive(firm_enum_id))
    {
        PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] = false;
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm is not active.");
    }

    if (!PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] && PlayerVar[playerid][E_PLAYER_FACTION_DUTY])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot go on firm duty while on faction duty.");
    }

    PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] = !PlayerFirm[playerid][E_PLAYER_FIRM_DUTY];

    Firm_SendMessage(PlayerFirm[playerid][E_PLAYER_FIRM_ID], sprintf("[Firm] %s is now %s firm duty.",
        ReturnRPName(playerid),
        PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] ? ("on") : ("off")));

    return true;
}

// /fc [text] - firm chat.
CMD:fc(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (isnull(params))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/fc [message]");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm could not be found in memory.");
    }

    Firm_SendMessage(PlayerFirm[playerid][E_PLAYER_FIRM_ID], sprintf("(( [Firm:%s] %s (%d): %s ))",
        Firm[firm_enum_id][E_FIRM_ABBREV], ReturnRPName(playerid), playerid, params));

    return true;
}

// /firmbank [deposit/withdraw] [amount] - manages your firm's bank balance.
CMD:firmbank(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm could not be found in memory.");
    }

    if (isnull(params))
    {
        return SendServerMessage(playerid, COLOR_BLUE, "Firm Bank", "A3A3A3", sprintf("Firm balance: $%s.", IntegerWithDelimiter(Firm[firm_enum_id][E_FIRM_BANK])));
    }

    new action[16], amount;

    if (sscanf(params, "s[16]i", action, amount))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmbank [deposit/withdraw] [amount]");
    }

    if (amount <= 0)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm Bank", "A3A3A3", "Amount must be greater than 0.");
    }

    if (!strcmp(action, "deposit", true))
    {
        if (GetPlayerCash(playerid) < amount)
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm Bank", "A3A3A3", sprintf("You don't have $%s in cash.", IntegerWithDelimiter(amount)));
        }

        TakePlayerCash(playerid, amount, "Firm bank deposit");
        Firm_AddBankMoney(firm_enum_id, amount, sprintf("%s deposited cash", ReturnRPName(playerid)));
        AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Deposited $%s into firm bank (%s)", IntegerWithDelimiter(amount), Firm[firm_enum_id][E_FIRM_NAME]), true);

        return SendServerMessage(playerid, COLOR_BLUE, "Firm Bank", "A3A3A3", sprintf("You deposited $%s into the firm bank.", IntegerWithDelimiter(amount)));
    }

    if (!strcmp(action, "withdraw", true))
    {
        if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_BANK))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm Bank", "A3A3A3", "You don't have permission to withdraw firm funds.");
        }

        if (!Firm_TakeBankMoney(firm_enum_id, amount, sprintf("%s withdrew cash", ReturnRPName(playerid))))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm Bank", "A3A3A3", sprintf("The firm bank doesn't have enough funds. Balance: $%s.", IntegerWithDelimiter(Firm[firm_enum_id][E_FIRM_BANK])));
        }

        GivePlayerCash(playerid, amount, "Firm bank withdrawal");
        AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Withdrew $%s from firm bank (%s)", IntegerWithDelimiter(amount), Firm[firm_enum_id][E_FIRM_NAME]), true);

        return SendServerMessage(playerid, COLOR_BLUE, "Firm Bank", "A3A3A3", sprintf("You withdrew $%s from the firm bank.", IntegerWithDelimiter(amount)));
    }

    return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmbank [deposit/withdraw] [amount]");
}

// /firmmembers - lists the members of your firm.
CMD:firmmembers(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm could not be found in memory.");
    }

    new query[384];
    mysql_format(mysql, query, sizeof(query),
        "SELECT fm.character_id, fm.firm_rank, fm.firm_rank_name, fm.firm_permissions, fm.firm_last_active, c.player_name FROM firm_members fm INNER JOIN characters c ON c.player_id = fm.character_id WHERE fm.firm_id = %d ORDER BY fm.firm_rank ASC, c.player_name ASC",
        PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    inline Firm_OnMemberList()
    {
        new rows = cache_num_rows();

        if (!rows)
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "No members were found for this firm.");
        }

        SendClientMessage(playerid, Firm[firm_enum_id][E_FIRM_HEXCOLOR], sprintf("[Firm Members] %s [%s] - %d/%d",
            Firm[firm_enum_id][E_FIRM_NAME],
            Firm[firm_enum_id][E_FIRM_ABBREV],
            rows,
            Firm[firm_enum_id][E_FIRM_MEMBER_SLOTS]));

        for (new i; i < rows; i++)
        {
            new character_id, rank, permissions, last_active, name[24], status[16];

            cache_get_value_name_int(i, "character_id", character_id);
            cache_get_value_name_int(i, "firm_rank", rank);
            cache_get_value_name_int(i, "firm_permissions", permissions);
            cache_get_value_name_int(i, "firm_last_active", last_active);
            cache_get_value_name(i, "player_name", name);

            format(status, sizeof(status), "Offline");

            foreach (new targetid: Player)
            {
                if (Character[targetid][E_CHARACTER_ID] == character_id)
                {
                    if (PlayerFirm[targetid][E_PLAYER_FIRM_DUTY])
                    {
                        format(status, sizeof(status), "On Duty");
                    }
                    else
                    {
                        format(status, sizeof(status), "Online");
                    }
                    break;
                }
            }

            SendClientMessage(playerid, 0xDEDEDEFF, sprintf("%s (CharID %d) | Rank %d | Perms %d | %s | Last Active: %d",
                name, character_id, rank, permissions, status, last_active));
        }

        return true;
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnMemberList, query, "");
    return true;
}

// /firminvite [player] - invites a nearby player to your firm.
CMD:firminvite(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_INVITE))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have permission to invite firm members.");
    }

    new targetid;

    if (sscanf(params, "k<player>", targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firminvite [player]");
    }

    if (!IsPlayerConnected(targetid) || !IsPlayerLogged(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is not connected.");
    }

    if (!Firm_PlayerCanAccess(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player cannot access firm systems right now.");
    }

    if (targetid == playerid)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot invite yourself.");
    }

    if (IsPlayerInFirm(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is already in a firm.");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (!Firm_IsActive(firm_enum_id))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm is not active.");
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT COUNT(*) AS total FROM firm_members WHERE firm_id = %d",
        PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    inline Firm_OnInviteCheck()
    {
        new total;
        cache_get_value_name_int(0, "total", total);

        if (total >= Firm[firm_enum_id][E_FIRM_MEMBER_SLOTS])
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm has no free member slots.");
        }

        if (!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid) || IsPlayerInFirm(targetid))
        {
            return true;
        }

        new invite_text[256];
        format(invite_text, sizeof(invite_text), "%s has invited you to join %s [%s].\n\nRank: Employee\nField tools: Enabled",
            ReturnRPName(playerid),
            Firm[firm_enum_id][E_FIRM_NAME],
            Firm[firm_enum_id][E_FIRM_ABBREV]);

        inline Firm_InviteResponse(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused dialogid, listitem, inputtext

            if (!response)
            {
                if (IsPlayerConnected(playerid))
                {
                    SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", sprintf("%s declined your firm invite.", ReturnRPName(pid)));
                }
                return true;
            }

            if (!IsPlayerConnected(playerid) || !IsPlayerInFirm(playerid) || PlayerFirm[playerid][E_PLAYER_FIRM_ID] != Firm[firm_enum_id][E_FIRM_ID])
            {
                return SendServerMessage(pid, COLOR_ERROR, "Firm", "A3A3A3", "That firm invite is no longer valid.");
            }

            if (IsPlayerInFirm(pid))
            {
                return SendServerMessage(pid, COLOR_ERROR, "Firm", "A3A3A3", "You are already in a firm.");
            }

            if (!Firm_PlayerCanAccess(pid))
            {
                return Firm_SendAccessDenied(pid);
            }

            Firm_AddMember(Firm[firm_enum_id][E_FIRM_ID], Character[pid][E_CHARACTER_ID], 3, Firm_GetDefaultRankPerms(3));
            Firm_Log(Firm[firm_enum_id][E_FIRM_ID], Character[playerid][E_CHARACTER_ID], 3, sprintf("%s invited %s", ReturnRPName(playerid), ReturnRPName(pid)));
            AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Invited %s to firm %s", ReturnRPName(pid), Firm[firm_enum_id][E_FIRM_NAME]), true);

            Firm_SendMessage(Firm[firm_enum_id][E_FIRM_ID], sprintf("[Firm] %s has joined the firm as an Employee.", ReturnRPName(pid)));
            SendServerMessage(pid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("You joined %s. Use /firmduty to go on duty.", Firm[firm_enum_id][E_FIRM_NAME]));
            return true;
        }

        Dialog_ShowCallback(targetid, using inline Firm_InviteResponse, DIALOG_STYLE_MSGBOX, "Firm Invite", invite_text, "Accept", "Decline");
        return SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("You invited %s to the firm.", ReturnRPName(targetid)));
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnInviteCheck, query, "");
    return true;
}

// /firmkick [player] - removes a member from your firm.
CMD:firmkick(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_KICK))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have permission to kick firm members.");
    }

    new targetid;

    if (sscanf(params, "k<player>", targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmkick [player]");
    }

    if (!IsPlayerConnected(targetid) || !IsPlayerLogged(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is not connected.");
    }

    if (targetid == playerid)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Use /firmresign if you want to leave your firm.");
    }

    if (PlayerFirm[targetid][E_PLAYER_FIRM_ID] != PlayerFirm[playerid][E_PLAYER_FIRM_ID])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is not in your firm.");
    }

    if (!Firm_PlayerCanManageRank(playerid, PlayerFirm[targetid][E_PLAYER_FIRM_RANK]))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot manage a member at that rank.");
    }

    new firm_sql_id = PlayerFirm[playerid][E_PLAYER_FIRM_ID];
    Firm_RemoveMember(firm_sql_id, Character[targetid][E_CHARACTER_ID]);
    Firm_Log(firm_sql_id, Character[playerid][E_CHARACTER_ID], 4, sprintf("%s kicked %s", ReturnRPName(playerid), ReturnRPName(targetid)));
    AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Kicked %s from firm SQL %d", ReturnRPName(targetid), firm_sql_id), true);

    SendServerMessage(targetid, COLOR_ERROR, "Firm", "A3A3A3", "You have been removed from your firm.");
    Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s removed %s from the firm.", ReturnRPName(playerid), ReturnRPName(targetid)));
    return true;
}

// /firmrank [player] [1-4] - changes a member's firm rank.
CMD:firmrank(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_RANKS))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have permission to change firm ranks.");
    }

    new targetid, rank;

    if (sscanf(params, "k<player>i", targetid, rank))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmrank [player] [1-4]");
    }

    if (!Firm_IsValidRank(rank))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Ranks are 1 Owner, 2 Manager, 3 Employee, 4 Trainee.");
    }

    if (rank == 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Owner transfers are not available through this command.");
    }

    if (!IsPlayerConnected(targetid) || !IsPlayerLogged(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is not connected.");
    }

    if (targetid == playerid)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot change your own firm rank.");
    }

    if (PlayerFirm[targetid][E_PLAYER_FIRM_ID] != PlayerFirm[playerid][E_PLAYER_FIRM_ID])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player is not in your firm.");
    }

    if (!Firm_PlayerCanManageRank(playerid, PlayerFirm[targetid][E_PLAYER_FIRM_RANK]) || !Firm_PlayerCanManageRank(playerid, rank))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot assign or manage that rank.");
    }

    new rank_name[MAX_FIRM_RANK_NAME], firm_sql_id = PlayerFirm[playerid][E_PLAYER_FIRM_ID];
    Firm_GetRankName(rank, rank_name, sizeof(rank_name));
    Firm_UpdateMemberRank(firm_sql_id, Character[targetid][E_CHARACTER_ID], rank);
    Firm_Log(firm_sql_id, Character[playerid][E_CHARACTER_ID], 5, sprintf("%s changed %s to %s", ReturnRPName(playerid), ReturnRPName(targetid), rank_name));
    AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Set %s to firm rank %d in firm SQL %d", ReturnRPName(targetid), rank, firm_sql_id), true);

    Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s changed %s's rank to %s.", ReturnRPName(playerid), ReturnRPName(targetid), rank_name));
    return true;
}

// /firmokick [character id] - removes a member who is offline.
CMD:firmokick(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_KICK))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have permission to kick firm members.");
    }

    new character_id;

    if (sscanf(params, "i", character_id))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmokick [character_id]");
    }

    if (character_id == Character[playerid][E_CHARACTER_ID])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Use /firmresign or /firmclose for your own firm membership.");
    }

    new firm_sql_id = PlayerFirm[playerid][E_PLAYER_FIRM_ID], query[384];
    mysql_format(mysql, query, sizeof(query),
        "SELECT fm.firm_rank, c.player_name FROM firm_members fm INNER JOIN characters c ON c.player_id = fm.character_id WHERE fm.firm_id = %d AND fm.character_id = %d LIMIT 1",
        firm_sql_id, character_id);

    inline Firm_OnOfflineKick()
    {
        if (!cache_num_rows())
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "No firm member was found with that character ID.");
        }

        new target_rank, target_name[24];
        cache_get_value_name_int(0, "firm_rank", target_rank);
        cache_get_value_name(0, "player_name", target_name);

        if (!Firm_PlayerCanManageRank(playerid, target_rank))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot manage a member at that rank.");
        }

        Firm_RemoveMember(firm_sql_id, character_id);
        Firm_Log(firm_sql_id, Character[playerid][E_CHARACTER_ID], 4, sprintf("%s offline-kicked %s", ReturnRPName(playerid), target_name));
        AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Offline kicked %s (%d) from firm SQL %d", target_name, character_id, firm_sql_id), true);

        Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s removed %s from the firm.", ReturnRPName(playerid), target_name));
        return true;
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnOfflineKick, query, "");
    return true;
}

// /firmorank [character id] [1-4] - changes the rank of a member who is offline.
CMD:firmorank(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (!Firm_PlayerHasPerm(playerid, FIRM_PERM_RANKS))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have permission to change firm ranks.");
    }

    new character_id, rank;

    if (sscanf(params, "ii", character_id, rank))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmorank [character_id] [1-4]");
    }

    if (!Firm_IsValidRank(rank))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Ranks are 1 Owner, 2 Manager, 3 Employee, 4 Trainee.");
    }

    if (rank == 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Owner transfers are not available through this command.");
    }

    if (character_id == Character[playerid][E_CHARACTER_ID])
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot change your own firm rank.");
    }

    new firm_sql_id = PlayerFirm[playerid][E_PLAYER_FIRM_ID], query[384];
    mysql_format(mysql, query, sizeof(query),
        "SELECT fm.firm_rank, c.player_name FROM firm_members fm INNER JOIN characters c ON c.player_id = fm.character_id WHERE fm.firm_id = %d AND fm.character_id = %d LIMIT 1",
        firm_sql_id, character_id);

    inline Firm_OnOfflineRank()
    {
        if (!cache_num_rows())
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "No firm member was found with that character ID.");
        }

        new target_rank, target_name[24];
        cache_get_value_name_int(0, "firm_rank", target_rank);
        cache_get_value_name(0, "player_name", target_name);

        if (!Firm_PlayerCanManageRank(playerid, target_rank) || !Firm_PlayerCanManageRank(playerid, rank))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You cannot assign or manage that rank.");
        }

        new rank_name[MAX_FIRM_RANK_NAME];
        Firm_GetRankName(rank, rank_name, sizeof(rank_name));
        Firm_UpdateMemberRank(firm_sql_id, character_id, rank);
        Firm_Log(firm_sql_id, Character[playerid][E_CHARACTER_ID], 5, sprintf("%s offline-ranked %s to %s", ReturnRPName(playerid), target_name, rank_name));
        AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Offline set %s (%d) to firm rank %d in firm SQL %d", target_name, character_id, rank, firm_sql_id), true);

        Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s changed %s's rank to %s.", ReturnRPName(playerid), target_name, rank_name));
        return true;
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnOfflineRank, query, "");
    return true;
}

// /firmresign - leave your firm.
CMD:firmresign(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (PlayerFirm[playerid][E_PLAYER_FIRM_RANK] == 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Firm owners cannot resign until ownership transfer or closure is added.");
    }

    new firm_sql_id = PlayerFirm[playerid][E_PLAYER_FIRM_ID];
    Firm_RemoveMember(firm_sql_id, Character[playerid][E_CHARACTER_ID]);
    Firm_Log(firm_sql_id, Character[playerid][E_CHARACTER_ID], 6, sprintf("%s resigned", ReturnRPName(playerid)));
    AddLogEntry(playerid, LOG_TYPE_FIRM, sprintf("Resigned from firm SQL %d", firm_sql_id), true);

    Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s resigned from the firm.", ReturnRPName(playerid)));
    SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", "You resigned from your firm.");
    return true;
}

// /firmclose - closes your firm permanently (owner only).
CMD:firmclose(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are not in a firm.");
    }

    if (PlayerFirm[playerid][E_PLAYER_FIRM_RANK] != 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Only the firm owner can close the firm.");
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Your firm could not be found in memory.");
    }

    new firm_sql_id = Firm[firm_enum_id][E_FIRM_ID], firm_name[MAX_FIRM_NAME];
    format(firm_name, sizeof(firm_name), "%s", Firm[firm_enum_id][E_FIRM_NAME]);

    inline Firm_CloseConfirm(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem, inputtext

        if (!response)
        {
            return true;
        }

        if (!IsPlayerInFirm(pid) || PlayerFirm[pid][E_PLAYER_FIRM_ID] != firm_sql_id || PlayerFirm[pid][E_PLAYER_FIRM_RANK] != 1)
        {
            return SendServerMessage(pid, COLOR_ERROR, "Firm", "A3A3A3", "You can no longer close this firm.");
        }

        new close_enum_id = Firm_GetEnumID(firm_sql_id);

        if (close_enum_id == INVALID_FIRM_ID)
        {
            return SendServerMessage(pid, COLOR_ERROR, "Firm", "A3A3A3", "This firm is no longer loaded.");
        }

        Firm_SendMessage(firm_sql_id, sprintf("[Firm] %s has closed %s.", ReturnRPName(pid), firm_name));
        Firm_Log(firm_sql_id, Character[pid][E_CHARACTER_ID], 7, sprintf("%s closed the firm", ReturnRPName(pid)));
        AddLogEntry(pid, LOG_TYPE_FIRM, sprintf("Closed firm %s SQL %d", firm_name, firm_sql_id), true);
        Firm_Close(close_enum_id);

        SendServerMessage(pid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("You closed %s.", firm_name));
        return true;
    }

    Dialog_ShowCallback(playerid, using inline Firm_CloseConfirm, DIALOG_STYLE_MSGBOX, "Close Firm",
        sprintf("Close %s?\n\nThis disables the firm and removes active member access. This cannot be undone by player command.", firm_name),
        "Close", "Cancel");
    return true;
}

// /firmcreate [field] [abbrev] [name] - registers a new firm (pays the field's creation fee).
CMD:firmcreate(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    new field_input[16], abbrev[MAX_FIRM_ABBREV], name[MAX_FIRM_NAME];

    if (sscanf(params, "s[16]s[8]s[64]", field_input, abbrev, name))
    {
        SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/firmcreate [field] [abbrev] [name]");
        return SendClientMessage(playerid, 0xA3A3A3FF, "Fields: mechanic, lawyer, security, transit, logistics, media, usedcars, realestate. Names cannot contain spaces yet.");
    }

    if (!IsAtGovFrontDesk(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You must be at the Administration Building front desk to create a firm.");
    }

    if (IsPlayerInFirm(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You are already in a firm.");
    }

    new field = Firm_ParseField(field_input);

    if (!Firm_IsValidField(field))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Invalid field. Use /firmhelp for valid fields.");
    }

    if (!Firm_IsValidName(name))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Firm names must be 3-63 characters and cannot contain color codes.");
    }

    if (!Firm_IsValidAbbrev(abbrev))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Firm abbreviations must be 2-7 characters and cannot contain color codes.");
    }

    new fee = Firm_GetCreateFee(field);

    if (GetPlayerCash(playerid) < fee)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", sprintf("You need $%s in cash to register this firm.", IntegerWithDelimiter(fee)));
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT firm_id FROM firms WHERE (firm_name = '%e' OR firm_owner_char_id = %d) AND firm_status != %d LIMIT 1",
        name, Character[playerid][E_CHARACTER_ID], FIRM_STATUS_CLOSED);

    inline Firm_OnCreateCheck()
    {
        if (cache_num_rows())
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That name is taken or you already own a non-closed firm.");
        }

        // Used car and real estate firms don't need an Administration Building license, anyone can start one.
        if (field == FIRM_FIELD_USEDCARS || field == FIRM_FIELD_REALESTATE)
        {
            Firm_Create(playerid, name, abbrev, field);
            return true;
        }

        new license_query[256];

        switch (field)
        {
            case FIRM_FIELD_TRANSIT:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'transit' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
            case FIRM_FIELD_MECHANIC:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'mechanic' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
            case FIRM_FIELD_SECURITY:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'security_guard' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
            case FIRM_FIELD_LAWYER:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'lawyer' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
            case FIRM_FIELD_LOGISTICS:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'logistics' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
            case FIRM_FIELD_MEDIA:
            {
                mysql_format(mysql, license_query, sizeof(license_query),
                    "SELECT id FROM character_licenses WHERE character_id = %d AND license_type = 'media' LIMIT 1",
                    Character[playerid][E_CHARACTER_ID]);
            }
        }

        inline Firm_OnLicenseCheck()
        {
            if (!cache_num_rows())
            {
                new required_license[32];
                Firm_GetRequiredLicenseName(field, required_license, sizeof(required_license));
                return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", sprintf("You need an approved %s license from the Administration Building before creating this firm.", required_license));
            }

            Firm_Create(playerid, name, abbrev, field);
            return true;
        }

        MySQL_TQueryInline(mysql, using inline Firm_OnLicenseCheck, license_query, "");
        return true;
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnCreateCheck, query, "");
    return true;
}

// Admin tool - hands the vehicle the player is standing in to a firm (by
// abbreviation), or takes it back off a firm. Mirrors /cartype + /carowner
// (vehicle/data/cmds/admin.pwn) at the same admin level; there's no
// self-service player version of this - firms don't buy/spawn their own
// vehicles yet, so a player-facing command would have nothing valid to claim.
CMD:firmvehicle(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_LEAD)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    if (!IsPlayerInAnyVehicle(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle for this to work.");
    }

    new vehicleid = GetPlayerVehicleID(playerid);
    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a proper vehicle.");
    }

    new abbrev[MAX_FIRM_ABBREV];
    if (sscanf(params, "s[8]", abbrev))
    {
        SendClientMessage(playerid, COLOR_RED, "/firmvehicle [firm abbrev]");
        SendClientMessage(playerid, 0xA3A3A3FF, "Use \"none\" to unassign the vehicle from whatever firm currently owns it.");
        return true;
    }

    new query[256];

    if (!strcmp(abbrev, "none", true))
    {
        if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_FIRM)
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "This vehicle isn't owned by a firm.");
        }

        Vehicle[veh_enum_id][E_VEHICLE_TYPE] = E_VEHICLE_TYPE_DEFAULT;
        Vehicle[veh_enum_id][E_VEHICLE_OWNER] = -1;

        mysql_format(mysql, query, sizeof(query), "UPDATE vehicles SET vehicle_type = %d, vehicle_owner = %d WHERE vehicle_sqlid = %d",
            Vehicle[veh_enum_id][E_VEHICLE_TYPE], Vehicle[veh_enum_id][E_VEHICLE_OWNER], Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
        mysql_tquery(mysql, query);

        SendAdminMessage(sprintf("[CAR/MAN] %s (%d) unassigned vehicle SQL %d from its firm.", Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Vehicle[veh_enum_id][E_VEHICLE_SQLID]));
        return SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", "This vehicle is no longer owned by a firm.");
    }

    new firm_enum_id = INVALID_FIRM_ID;
    for (new i; i < MAX_FIRMS; i++)
    {
        if (Firm[i][E_FIRM_ID] != INVALID_FIRM_ID && !strcmp(Firm[i][E_FIRM_ABBREV], abbrev, true))
        {
            firm_enum_id = i;
            break;
        }
    }

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "No firm found with that abbreviation.");
    }

    new firm_sql_id = Firm[firm_enum_id][E_FIRM_ID];

    Vehicle[veh_enum_id][E_VEHICLE_TYPE] = E_VEHICLE_TYPE_FIRM;
    Vehicle[veh_enum_id][E_VEHICLE_OWNER] = firm_sql_id;

    mysql_format(mysql, query, sizeof(query), "UPDATE vehicles SET vehicle_type = %d, vehicle_owner = %d WHERE vehicle_sqlid = %d",
        Vehicle[veh_enum_id][E_VEHICLE_TYPE], Vehicle[veh_enum_id][E_VEHICLE_OWNER], Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
    mysql_tquery(mysql, query);

    SendAdminMessage(sprintf("[CAR/MAN] %s (%d) assigned vehicle SQL %d to firm %s [%s].",
        Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Vehicle[veh_enum_id][E_VEHICLE_SQLID], Firm[firm_enum_id][E_FIRM_NAME], Firm[firm_enum_id][E_FIRM_ABBREV]));
    return SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("This vehicle is now owned by %s [%s].", Firm[firm_enum_id][E_FIRM_NAME], Firm[firm_enum_id][E_FIRM_ABBREV]));
}
