// ============================================================================
// File: property/utils/advert.pwn
// Advertising: /advert, /badvert (business) and /propertyad post an ad at a cost, /rumour posts
// rumours, and /activities lists in-world events. Ads can be posted to Discord.
// Commands: /activities /activity /events /adminad /advert /arumour /adminrumour
// /propertyadvert /badvert /propad /propertyad /rumour
// ============================================================================

#if !defined ADV_POS_X
	#define ADV_POS_X (0.0) // TODO: set coordinates for your map
#endif
#if !defined ADV_POS_Y
	#define ADV_POS_Y (0.0) // TODO: set coordinates for your map
#endif
#if !defined ADV_POS_Z
	#define ADV_POS_Z (0.0) // TODO: set coordinates for your map
#endif

#if !defined ADV_PICKUP_MODEL
	#define ADV_PICKUP_MODEL 19807
#endif

#if !defined ADV_MAP_ICON
	#define ADV_MAP_ICON 36
#endif

#define MAX_ACTIVITIES 16

enum E_ACTIVITY_TYPE {
    ACTIVITY_ADVERT,
    ACTIVITY_BADVERT,
    ACTIVITY_RUMOUR,
    ACTIVITY_ADMIN_ADVERT,
    ACTIVITY_ADMIN_RUMOUR
}

enum E_ACTIVITY_DATA {
    E_ACTIVITY_TYPE:E_ACTIVITY_TYPE_ID,
    E_ACTIVITY_TEXT[144],
    E_ACTIVITY_PLAYER_NAME[MAX_PLAYER_NAME],
    E_ACTIVITY_PHONE,
    E_ACTIVITY_TIMESTAMP
}

new ActivityLog[MAX_ACTIVITIES][E_ACTIVITY_DATA];
new ActivityLogIndex = 0;
new ActivityLogCount = 0;

new adcooldown[MAX_PLAYERS]    = {0, ...};
new rumorcooldown[MAX_PLAYERS] = {0, ...};
new badcooldown[MAX_PLAYERS]   = {0, ...};

// Adds an entry (advert, rumour, property listing) to the activity feed.
stock Activity_Add(E_ACTIVITY_TYPE:type, const text[], const playername[], phone = 0) {
    ActivityLog[ActivityLogIndex][E_ACTIVITY_TYPE_ID] = type;
    format(ActivityLog[ActivityLogIndex][E_ACTIVITY_TEXT], 144, "%s", text);
    format(ActivityLog[ActivityLogIndex][E_ACTIVITY_PLAYER_NAME], MAX_PLAYER_NAME, "%s", playername);
    ActivityLog[ActivityLogIndex][E_ACTIVITY_PHONE] = phone;
    ActivityLog[ActivityLogIndex][E_ACTIVITY_TIMESTAMP] = gettime();

    ActivityLogIndex = (ActivityLogIndex + 1) % MAX_ACTIVITIES;
    if (ActivityLogCount < MAX_ACTIVITIES) ActivityLogCount++;
}

// Returns the chat colour for an activity type.
stock GetActivityColor(E_ACTIVITY_TYPE:type) {
    new color = 0xFFFFFFFF;
    switch (type) {
        case ACTIVITY_ADVERT:       color = 0xFFA500FF;
        case ACTIVITY_BADVERT:      color = 0x3FF0F3FF;
        case ACTIVITY_RUMOUR:       color = 0x058F1CFF;
        case ACTIVITY_ADMIN_ADVERT: color = 0xFF4500FF;
        case ACTIVITY_ADMIN_RUMOUR: color = 0x9AE60DFF;
    }
    return color;
}

// Writes the display name of an activity type.
stock GetActivityTypeName(E_ACTIVITY_TYPE:type, output[], size = sizeof(output)) {
    switch (type) {
        case ACTIVITY_ADVERT:       format(output, size, "Advertisement");
        case ACTIVITY_BADVERT:      format(output, size, "Business Ad");
        case ACTIVITY_RUMOUR:       format(output, size, "Rumour");
        case ACTIVITY_ADMIN_ADVERT: format(output, size, "Admin Ad");
        case ACTIVITY_ADMIN_RUMOUR: format(output, size, "Admin Rumour");
    }
}

// Turns a timestamp into text such as '5 minutes ago'.
stock GetTimeAgo(timestamp, output[], size = sizeof(output)) {
    new diff = gettime() - timestamp;

    if      (diff < 60)    format(output, size, "%ds ago",  diff);
    else if (diff < 3600)  format(output, size, "%dm ago",  diff / 60);
    else if (diff < 86400) format(output, size, "%dh ago",  diff / 3600);
    else                   format(output, size, "%dd ago",  diff / 86400);
}

// Returns the advert discount percent for the player (for example news staff).
static stock Advert_GetDiscountPercent(playerid) {
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL]) {
        case E_PREMIUM_LVL_4: return 75; // Gold
        case E_PREMIUM_LVL_3: return 50; // Silver
    }
    return 0;
}

// Clears a player's advert/rumour cooldowns.
stock Advert_ResetPlayerCooldowns(playerid) {
    adcooldown[playerid]    = 0;
    rumorcooldown[playerid] = 0;
    badcooldown[playerid]   = 0;
}

// Sets up the advert system at start-up.
Advert_Init() {
    print(" * [ADVERTISEMENTS] Loaded advertisements.");

    CreateDynamic3DTextLabel(
        "[Advertisement Location]\n{DEDEDE}Available commands: /advert, /rumour",
        COLOR_BLUE, ADV_POS_X, ADV_POS_Y, ADV_POS_Z, 10.0, .testlos = 1
    );

    CreateDynamicPickup(_:ADV_PICKUP_MODEL, 1, ADV_POS_X, ADV_POS_Y, ADV_POS_Z);
    CreateDynamicMapIcon(ADV_POS_X, ADV_POS_Y, ADV_POS_Z, ADV_MAP_ICON, 0);
}

// /activities - shows the recent adverts, rumours and listings.
CMD:activities(playerid, params[]) {
    if (ActivityLogCount == 0) {
        return SendServerMessage(playerid, COLOR_ERROR, "Activities", "DEDEDE", "No recent activities found.");
    }

    new ActDlgStr[8192];
    new ActDlgLine[384];
    format(ActDlgStr, sizeof(ActDlgStr), "Type\tPlayer\tTime\tText");

    new startIdx = (ActivityLogIndex - 1 + MAX_ACTIVITIES) % MAX_ACTIVITIES;

    for (new i = 0; i < ActivityLogCount; i++) {
        new idx = (startIdx - i + MAX_ACTIVITIES) % MAX_ACTIVITIES;

        new typename[32], timeago[32];
        GetActivityTypeName(ActivityLog[idx][E_ACTIVITY_TYPE_ID], typename);
        GetTimeAgo(ActivityLog[idx][E_ACTIVITY_TIMESTAMP], timeago);

        new color = GetActivityColor(ActivityLog[idx][E_ACTIVITY_TYPE_ID]);

        if (ActivityLog[idx][E_ACTIVITY_PHONE] > 0) {
            format(ActDlgLine, sizeof(ActDlgLine), "\n{%06x}%s\t{FFFFFF}%s\t{FFFFFF}%s\t{%06x}%s (Ph: %d)",
                color >>> 8, typename,
                ActivityLog[idx][E_ACTIVITY_PLAYER_NAME],
                timeago,
                color >>> 8, ActivityLog[idx][E_ACTIVITY_TEXT],
                ActivityLog[idx][E_ACTIVITY_PHONE]);
        } else {
            format(ActDlgLine, sizeof(ActDlgLine), "\n{%06x}%s\t{FFFFFF}%s\t{FFFFFF}%s\t{%06x}%s",
                color >>> 8, typename,
                ActivityLog[idx][E_ACTIVITY_PLAYER_NAME],
                timeago,
                color >>> 8, ActivityLog[idx][E_ACTIVITY_TEXT]);
        }

        if ((strlen(ActDlgStr) + strlen(ActDlgLine)) < sizeof(ActDlgStr) - 1) {
            strcat(ActDlgStr, ActDlgLine);
        }
    }

    inline DlgShowActivities(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext, listitem, response
    }

    Dialog_ShowCallback(playerid, using inline DlgShowActivities, DIALOG_STYLE_TABLIST_HEADERS,
        sprintf("Server Activities (%d/%d)", ActivityLogCount, MAX_ACTIVITIES), ActDlgStr, "Close", "");

    return true;
}

CMD:activity(playerid, params[]) return cmd_activities(playerid, params);
CMD:events(playerid, params[])   return cmd_activities(playerid, params);

// /adminad [text] - (staff) posts an admin advert for free.
CMD:adminad(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "DEDEDE", "You don't have access to this command.");
    }

    new text[128];
    if (sscanf(params, "s[128]", text)) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "/adminad [advert text]");
    }
    if (strlen(text) < 6 || strlen(text) > 128) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "Your text can't have less than 6 or more than 128 characters.");
    }

    new string[144];
    format(string, sizeof(string), "[Advertisement] %s", text);
    ZMsg_SendClientMessageToAll(COLOR_ADV, string);

    Activity_Add(ACTIVITY_ADMIN_ADVERT, text, Character[playerid][E_CHARACTER_NAME]);
    SendAdminMessage(sprintf("[Last /adminad was done by (%d) %s [%s].]",
        playerid, Character[playerid][E_CHARACTER_NAME], Account[playerid][E_PLAYER_ACCOUNT_NAME]));

    return true;
}

// /advert [text] - pays to post a public advert.
CMD:advert(playerid, params[]) {
    new bool:isNewsDuty = bool:IsPlayerInNewsFaction(playerid, true);

    if (!isNewsDuty) {
        if (!IsPlayerInRangeOfPoint(playerid, 5.0, ADV_POS_X, ADV_POS_Y, ADV_POS_Z) && GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
            return SendServerMessage(playerid, COLOR_ERROR, "Advert", "DEDEDE", "You're not in range of the advertisement place!");
        }

        if (adcooldown[playerid] && (gettime() - adcooldown[playerid]) < 300) {
            SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
                sprintf("You must wait %d seconds until another advertisement can be placed.",
                    300 - (gettime() - adcooldown[playerid])));
            return SendClientMessage(playerid, COLOR_INFO, "Tip: You can \"/call 726\" to contact SAN, who can broadcast ads for you instead.");
        }
    }

    new text[128];
    if (sscanf(params, "s[128]", text)) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "/advert [text] (you will be charged for text length)");
    }
    if (strlen(text) < 6 || strlen(text) > 128) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "Your text can't have less than 6 or more than 128 characters.");
    }
    if (!CanPlayerUseGuns(playerid, 3)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "DEDEDE", "Your account is too new! You can't use this feature yet.");
    }
    if (!Character[playerid][E_CHARACTER_PHONE_NUMBER]) {
        SendServerMessage(playerid, 0xE83A2BFF, "Phone", "A3A3A3", "You don't have a phone! How will people contact you? Buy one in an electronics store.");
        return true;
    }

    if (!isNewsDuty) {
        new basePrice = 500;
        new discountPercent = Advert_GetDiscountPercent(playerid);
        new finalPrice = basePrice;

        if (discountPercent > 0) {
            finalPrice = (basePrice * (100 - discountPercent)) / 100;
        }

        if (GetPlayerCash(playerid) < finalPrice) {
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE",
                sprintf("You don't have enough money for this advertisement! You need at least $%s.",
                    IntegerWithDelimiter(finalPrice)));
        }

        TakePlayerCash(playerid, finalPrice, "Advert fee");

        if (discountPercent > 0) {
            SendClientMessage(playerid, COLOR_GREEN,
                sprintf("VIP Discount Applied: %d%% off. You paid $%s instead of $%s.",
                    discountPercent,
                    IntegerWithDelimiter(finalPrice),
                    IntegerWithDelimiter(basePrice)));
        }
    }

    new string[256];
    if (isNewsDuty)
        format(string, sizeof(string), "[Advertisement] %s [By: SAN News]", text);
    else
        format(string, sizeof(string), "[Advertisement] %s [By: %d]", text, Character[playerid][E_CHARACTER_PHONE_NUMBER]);

    ZMsg_SendClientMessageToAll(COLOR_ADV, string);
    DCC_SendAdvertisementMessage(0, string);
    Activity_Add(ACTIVITY_ADVERT, text, Character[playerid][E_CHARACTER_NAME], Character[playerid][E_CHARACTER_PHONE_NUMBER]);
    SendAdminMessage(sprintf("[Last /advert was done by (%d) %s [%s].]", playerid, Character[playerid][E_CHARACTER_NAME], Account[playerid][E_PLAYER_ACCOUNT_NAME]));

    if (!isNewsDuty) {
        adcooldown[playerid] = gettime();
    }

    return true;
}

CMD:arumour(playerid, params[])      return cmd_adminrumour(playerid, params);
// /adminrumour [text] - (staff) posts a rumour for free.
CMD:adminrumour(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "You don't have access to this command.");
    }

    new text[144];
    if (sscanf(params, "s[144]", text)) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "/adminrumour [text]");
    }

    new string[256];
    format(string, sizeof(string), "[Rumour] %s", text);
    ZMsg_SendClientMessageToAll(0x2B8CC8FF, string);

    Activity_Add(ACTIVITY_ADMIN_RUMOUR, text, Character[playerid][E_CHARACTER_NAME]);
    SendAdminMessage(sprintf("Last /adminrumour was done by (%d) %s [%s].",
        playerid, Character[playerid][E_CHARACTER_NAME], Account[playerid][E_PLAYER_ACCOUNT_NAME]));

    return true;
}

// /propertyadvert - advertises a property for sale.
CMD:propertyadvert(playerid, params[]) {
    new property_enum_id = Property_GetClosestEntity(playerid, PROPERTY_NEAR_EXIT);

    if (property_enum_id == INVALID_PROPERTY_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be inside your property, near the door.");
    }
    if (Property[property_enum_id][E_PROPERTY_TYPE] != E_PROPERTY_TYPE_BIZ) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only use this feature in a business.");
    }
    if (Property[property_enum_id][E_PROPERTY_OWNER] != Character[playerid][E_CHARACTER_ID]) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Only the business owner can post advertisements.");
    }

    if (badcooldown[playerid] && (gettime() - badcooldown[playerid]) < 600) {
        SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("You must wait %d seconds until another business advertisement can be placed.", 600 - (gettime() - badcooldown[playerid])));
        return SendClientMessage(playerid, COLOR_INFO, "Tip: You can \"/call 726\" to contact SAN, who can broadcast ads for you instead.");
    }

    new text[128];
    if (sscanf(params, "s[128]", text)) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "/bad(vert) [text] (you will be charged for text length)");
    }
    if (strlen(text) < 16 || strlen(text) > 100) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "Your text can't have less than 16 or more than 100 characters.");
    }
    if (Character[playerid][E_CHARACTER_HOURS] < 3) {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "DEDEDE", "Your account is too new! You can't use this feature yet.");
    }
    if (!Character[playerid][E_CHARACTER_PHONE_NUMBER]) {
        SendServerMessage(playerid, 0xE83A2BFF, "Phone", "A3A3A3", "You don't have a phone! How will people contact you? Buy one in an electronics store.");
        return true;
    }

    new price = 8 * strlen(text);
    new discountPercent = Advert_GetDiscountPercent(playerid);
    if (discountPercent > 0) {
        price -= (price * discountPercent / 100);
    }

    if (GetPlayerCash(playerid) < price) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", sprintf("You don't have enough money for this advertisement! You need at least $%s.", IntegerWithDelimiter(price)));
    }

    TakePlayerCash(playerid, price, "Property advert fee");

    new string[256];
    if (strcmp(Property[property_enum_id][E_PROPERTY_NAME], "Undefined", true))
        format(string, sizeof(string), "[%s] %s ((/propfind %d))", Property[property_enum_id][E_PROPERTY_NAME], text, property_enum_id);
    else
        format(string, sizeof(string), "[Business] %s ((/propfind %d))", text, property_enum_id);

    ZMsg_SendClientMessageToAll(COLOR_BADV, string);
    DCC_SendAdvertisementMessage(1, string);

    Activity_Add(ACTIVITY_BADVERT, text, Character[playerid][E_CHARACTER_NAME], Character[playerid][E_CHARACTER_PHONE_NUMBER]);
    SendAdminMessage(sprintf("[Last /propertyad was done by (%d) %s.]",
        playerid, Character[playerid][E_CHARACTER_NAME]));

    badcooldown[playerid] = gettime();

    return true;
}

CMD:badvert(playerid, params[])     return cmd_propertyadvert(playerid, params);
CMD:propad(playerid, params[])      return cmd_propertyadvert(playerid, params);
CMD:propertyad(playerid, params[])  return cmd_propertyadvert(playerid, params);

// /rumour [text] - pays to post an anonymous rumour.
CMD:rumour(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
        if (!IsPlayerInRangeOfPoint(playerid, 5.0, ADV_POS_X, ADV_POS_Y, ADV_POS_Z)) {
            return SendServerMessage(playerid, COLOR_ERROR, "Advert", "DEDEDE", "You're not in range of the advertisement place!");
        }
    }

    if (rumorcooldown[playerid] && (gettime() - rumorcooldown[playerid]) < 600) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            sprintf("You must wait %d seconds until another rumour can be sent.",
                600 - (gettime() - rumorcooldown[playerid])));
    }

    new text[144];
    if (sscanf(params, "s[144]", text)) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "/rumour [text] (you will be charged for text length)");
    }
    if (strlen(text) < 5 || strlen(text) > 144) {
        return SendServerMessage(playerid, COLOR_RED, "Syntax", "A3A3A3", "Your text can't have less than 5 or more than 144 characters.");
    }
    if (!CanPlayerUseGuns(playerid, 3)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "DEDEDE", "Your account is too new! You can't use this feature yet.");
    }
    if (!Character[playerid][E_CHARACTER_PHONE_NUMBER]) {
        SendServerMessage(playerid, 0xE83A2BFF, "Phone", "A3A3A3", "You don't have a phone! How will people contact you? Buy one in an electronics store.");
        return true;
    }

    new price = 7 * strlen(text);

    if (GetPlayerCash(playerid) < price) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", sprintf("You don't have enough money for this rumour! You need at least $%s.", IntegerWithDelimiter(price)));
    }

    inline RumourAbuseWarning(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem, inputtext

        if (response) {
            TakePlayerCash(playerid, price, "Rumour fee");

            new string[256];
            format(string, sizeof(string), "[Rumour] %s", text);
            ZMsg_SendClientMessageToAll(0x2B8CC8FF, string);

            Activity_Add(ACTIVITY_RUMOUR, text, Character[playerid][E_CHARACTER_NAME], Character[playerid][E_CHARACTER_PHONE_NUMBER]);

            rumorcooldown[playerid] = gettime();

            SendAdminMessage(sprintf("[Last /rumour was done by (%d) %s [%s]. If not related to events, punish them.]",
                playerid, Character[playerid][E_CHARACTER_NAME], Account[playerid][E_PLAYER_ACCOUNT_NAME]));
        }
    }

    new string[512] = "{D63C3C}WARNING:{DEDEDE} /rumour is only meant to be used for events.\n\n\
        It can not be used to defame another faction or to send random messages or adverts to the server.\n\n\
        If you are abusing this feature, you will be punished severely. Admins can see who use it.\n\n\
        Thanks for understanding.";

    Dialog_ShowCallback(playerid, using inline RumourAbuseWarning, DIALOG_STYLE_MSGBOX,
        "{D63C3C}RUMOUR ABUSE WARNING:{DEDEDE}", string, "Proceed", "Cancel");

    return true;
}
