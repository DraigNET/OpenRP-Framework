// ============================================================================
// File: misc/atms.pwn
// ATMs: /atm to bank, and admin tools /createatm, /moveatm, /deleteatm, /atmnearby, /gotoatm,
// /listatms. ATMs are stored in the `atms` table.
// Commands: /createatm /deleteatm /moveatm /atmnearby /atm /listatms /gotoatm
// ============================================================================


#define COLOR_ATM       (0x198b3fFF)
#define ATM_RANGE       (2.0)
#define ATM_OBJECT_ID   (2942)
#define ATM_MAX         (125) 

enum E_ATM_DATA {
    E_ATM_DB_ID,                        
    Float: E_ATM_POS_X,
    Float: E_ATM_POS_Y,
    Float: E_ATM_POS_Z,
    Float: E_ATM_ANGLE,
    DynamicText3D: E_ATM_LABEL,
    E_ATM_OBJECT,                       
    E_ATM_ICON,                         
    bool: E_ATM_USED                    
};

static ATMData[ATM_MAX][E_ATM_DATA];
static ATMCount = 0;                    

#include <YSI_Coding\y_hooks>

// Returns the first free ATM slot.
static FindFreeATMSlot() {
    for (new i = 0; i < ATM_MAX; i++) {
        if (!ATMData[i][E_ATM_USED]) return i;
    }
    return -1;
}

// Finds an ATM by its database id.
stock FindATMByDBID(dbid) {
    for (new i = 0; i < ATM_MAX; i++) {
        if (ATMData[i][E_ATM_USED] && ATMData[i][E_ATM_DB_ID] == dbid) return i;
    }
    return -1;
}

// Removes the ATM's object and label.
static ClearATMVisuals(index) {
    if (IsValidDynamicObject(ATMData[index][E_ATM_OBJECT])) {
        DestroyDynamicObject(ATMData[index][E_ATM_OBJECT]);
    }
    ATMData[index][E_ATM_OBJECT] = INVALID_STREAMER_ID;

    if (IsValidDynamic3DTextLabel(ATMData[index][E_ATM_LABEL])) {
        DestroyDynamic3DTextLabel(ATMData[index][E_ATM_LABEL]);
    }
    ATMData[index][E_ATM_LABEL] = DynamicText3D:INVALID_STREAMER_ID;

    if (IsValidDynamicMapIcon(ATMData[index][E_ATM_ICON])) {
        DestroyDynamicMapIcon(ATMData[index][E_ATM_ICON]);
    }
    ATMData[index][E_ATM_ICON] = INVALID_STREAMER_ID;
}

// Creates the ATM's object and 3D label.
static SetATMVisuals(index) {
    ClearATMVisuals(index);

    new labelText[160];
    format(labelText, sizeof(labelText),
        "[Automated Teller Machine] {2bb358}[%i]{DEDEDE}\nType {c4a656}/atm {DEDEDE}to access your bank account.",
        ATMData[index][E_ATM_DB_ID]
    );

    ATMData[index][E_ATM_LABEL] = CreateDynamic3DTextLabel(
        labelText, COLOR_ATM,
        ATMData[index][E_ATM_POS_X],
        ATMData[index][E_ATM_POS_Y],
        ATMData[index][E_ATM_POS_Z],
        6.0
    );

    ATMData[index][E_ATM_OBJECT] = CreateDynamicObject(
        ATM_OBJECT_ID,
        ATMData[index][E_ATM_POS_X],
        ATMData[index][E_ATM_POS_Y],
        ATMData[index][E_ATM_POS_Z],
        0.0, 0.0,
        ATMData[index][E_ATM_ANGLE],
        .priority = STREAM_PRIORITY_INTERACTABLE
    );

    ATMData[index][E_ATM_ICON] = CreateDynamicMapIcon(
        ATMData[index][E_ATM_POS_X],
        ATMData[index][E_ATM_POS_Y],
        ATMData[index][E_ATM_POS_Z],
        52, 0xFFFFFFFF, .streamdistance = 75.0
    );
}

// Stores an ATM loaded from the database and creates its visuals.
static RegisterATM(dbid, Float:x, Float:y, Float:z, Float:angle) {
    new index = FindFreeATMSlot();
    if (index == -1) {
        printf("[ATM] ERROR: No free slot for DB id %d", dbid);
        return -1;
    }

    ATMData[index][E_ATM_DB_ID]   = dbid;
    ATMData[index][E_ATM_POS_X]   = x;
    ATMData[index][E_ATM_POS_Y]   = y;
    ATMData[index][E_ATM_POS_Z]   = z;
    ATMData[index][E_ATM_ANGLE]   = angle;
    ATMData[index][E_ATM_USED]    = true;

    SetATMVisuals(index);
    ATMCount++;
    return index;
}

// Removes an ATM from memory.
static UnregisterATM(index) {
    if (!ATMData[index][E_ATM_USED]) return;
    ClearATMVisuals(index);
    ATMData[index][E_ATM_USED]  = false;
    ATMData[index][E_ATM_DB_ID] = 0;
    ATMCount--;
}

// Loads every ATM from the `atms` table.
LoadATMs() {
    for (new i = 0; i < ATM_MAX; i++) {
        ATMData[i][E_ATM_USED] = false;
    }

    print(" * [ATM] Loading all ATMs...");

    inline ATM_OnDataLoad() {
        for (new i = 0, r = cache_num_rows(); i < r; ++i) {
            new dbid;
            new Float:x, Float:y, Float:z, Float:angle;

            cache_get_value_name_int  (i, "id", dbid);
            cache_get_value_name_float(i, "pos_x", x);
            cache_get_value_name_float(i, "pos_y", y);
            cache_get_value_name_float(i, "pos_z", z);
            cache_get_value_name_float(i, "angle", angle);

            RegisterATM(dbid, x, y, z, angle);
        }

        printf(" * [ATM] Loaded %d ATM(s).", cache_num_rows());
    }

    new query[128];
    mysql_format(mysql, query, sizeof(query), "SELECT `id`,`pos_x`,`pos_y`,`pos_z`,`angle` FROM `atms`");
    MySQL_TQueryInline(mysql, using inline ATM_OnDataLoad, query, "");
}

// Inserts a new ATM into the database.
CreateATMInDB(playerid, Float:x, Float:y, Float:z, Float:angle) {
    new query[256];
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `atms` (`pos_x`,`pos_y`,`pos_z`,`angle`) VALUES (%.4f,%.4f,%.4f,%.4f)", x, y, z, angle);
    mysql_tquery(mysql, query, "OnATMCreated", "iffff", playerid, x, y, z, angle);
}

forward OnATMCreated(playerid, Float:x, Float:y, Float:z, Float:angle);
public  OnATMCreated(playerid, Float:x, Float:y, Float:z, Float:angle) {
    new dbid = cache_insert_id();
    new index = RegisterATM(dbid, x, y, z, angle);

    if (index == -1) return 1;

    new zone[64];
    GetCoords2DZone(x, y, zone, sizeof(zone));

    SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE",
        sprintf("ATM #%d created in %s. Total ATMs: %d", dbid, zone, ATMCount));

    AddLogEntry(playerid, LOG_TYPE_SCRIPT,
        sprintf("Created ATM #%d at %.2f, %.2f, %.2f (zone: %s)", dbid, x, y, z, zone));

    return 1;
}

// Deletes an ATM from the database.
DeleteATMFromDB(playerid, index) {
    new dbid = ATMData[index][E_ATM_DB_ID];

    new query[128];
    mysql_format(mysql, query, sizeof(query),
        "DELETE FROM `atms` WHERE `id` = %d LIMIT 1", dbid
    );
    mysql_tquery(mysql, query, "OnATMDeleted", "iii", playerid, index, dbid);
}

forward OnATMDeleted(playerid, index, dbid);
public  OnATMDeleted(playerid, index, dbid) {
    UnregisterATM(index);
    SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE",
        sprintf("ATM #%d has been deleted. Total ATMs: %d", dbid, ATMCount));
    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Deleted ATM #%d", dbid));
    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnStartSQL() {
    LoadATMs();
    return 1;
}

// Returns the index of the ATM the player is standing next to, or -1.
static IsNearATM(playerid) {
    for (new i = 0; i < ATM_MAX; i++) {
        if (!ATMData[i][E_ATM_USED]) continue;
        if (IsPlayerInRangeOfPoint(playerid, ATM_RANGE,
            ATMData[i][E_ATM_POS_X],
            ATMData[i][E_ATM_POS_Y],
            ATMData[i][E_ATM_POS_Z]))
        {
            return i;
        }
    }
    return -1;
}

// /createatm - (admin) places an ATM at your position.
CMD:createatm(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);

    CreateATMInDB(playerid, x, y, z - 0.32, angle);
    return 1;
}

// /deleteatm - (admin) removes the nearest ATM.
CMD:deleteatm(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new index = IsNearATM(playerid);
    if (index == -1) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE",  "You are not near an ATM!");
    }

    inline ConfirmDelete(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem, inputtext
        if (response) {
            DeleteATMFromDB(playerid, index);
        }
    }
    Dialog_ShowCallback(playerid, using inline ConfirmDelete, DIALOG_STYLE_MSGBOX,
        "Delete ATM",
        sprintf("Are you sure you want to delete ATM #%d?", ATMData[index][E_ATM_DB_ID]),
        "Yes", "No"
    );
    return 1;
}

// /moveatm - (admin) moves the nearest ATM to your position.
CMD:moveatm(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new index = IsNearATM(playerid);
    if (index == -1) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", "You are not near an ATM!");
    }

    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    z -= 0.32;

    ATMData[index][E_ATM_POS_X] = x;
    ATMData[index][E_ATM_POS_Y] = y;
    ATMData[index][E_ATM_POS_Z] = z;
    ATMData[index][E_ATM_ANGLE] = angle;
    SetATMVisuals(index);

    new query[256], dbid = ATMData[index][E_ATM_DB_ID];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE `atms` SET `pos_x`=%.4f,`pos_y`=%.4f,`pos_z`=%.4f,`angle`=%.4f WHERE `id`=%d LIMIT 1",
        x, y, z, angle, dbid
    );
    mysql_tquery(mysql, query);

    SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", sprintf("ATM #%d has been moved to your position.", dbid));
    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Moved ATM #%d to %.2f, %.2f, %.2f", dbid, x, y, z));
    return 1;
}

// /atmnearby - (admin) lists ATMs near you.
CMD:atmnearby(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new str[1024], count;
    for (new i = 0; i < ATM_MAX; i++) {
        if (!ATMData[i][E_ATM_USED]) continue;
        new Float:dist = GetPlayerDistanceFromPoint(playerid,
            ATMData[i][E_ATM_POS_X], ATMData[i][E_ATM_POS_Y], ATMData[i][E_ATM_POS_Z]);
        if (dist <= 50.0) {
            format(str, sizeof(str), "%s#%d - %.1fm\n", str, ATMData[i][E_ATM_DB_ID], dist);
            count++;
        }
    }

    if (!count) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE",
            "No ATMs within 50m.");
    }

    Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Nearby ATMs", str, "OK", "");
    return 1;
}

// /atm - use the ATM next to you to deposit, withdraw or check your balance.
CMD:atm(playerid, params[]) {
    new index = IsNearATM(playerid);
    if (index == -1) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE",
            "You are not near an ATM!");
    }
    OnPlayerUseATM(playerid);
    return 1;
}

// /listatms - (admin) lists every ATM.
CMD:listatms(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new count;

    for (new i = 0; i < ATM_MAX; i++) {
        if (!ATMData[i][E_ATM_USED]) continue;
        count++;
    }

    if (!count) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", "There are no ATMs currently loaded.");
    }

    SendClientMessage(playerid, 0x198b3fff, "-------- Automated Teller Machines --------");

    for (new i = 0; i < ATM_MAX; i++) {
        if (!ATMData[i][E_ATM_USED]) continue;

        new zone[64];
        GetCoords2DZone(ATMData[i][E_ATM_POS_X], ATMData[i][E_ATM_POS_Y], zone, sizeof(zone));

        SendClientMessage(playerid, 0xDEDEDEFF, sprintf("{2bb358}#%d {DEDEDE}- %s", ATMData[i][E_ATM_DB_ID], zone));
    }

    return 1;
}

// /gotoatm [id] - (admin) teleports to an ATM.
CMD:gotoatm(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3",
            "You don't have access to this command.");
    }

    new id;
    if (sscanf(params, "i", id)) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", "Usage: {c4a656}/gotoatm {DEDEDE}[id]");
    }

    new index = FindATMByDBID(id);
    if (index == -1) {
        return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", 
            sprintf("ATM {2bb358}#%d {DEDEDE}does not exist.", id));
    }

    SetPlayerPos(playerid, 
        ATMData[index][E_ATM_POS_X], 
        ATMData[index][E_ATM_POS_Y], 
        ATMData[index][E_ATM_POS_Z] + 0.5
    );
    SetPlayerFacingAngle(playerid, ATMData[index][E_ATM_ANGLE]);

    new zone[64];
    GetCoords2DZone(ATMData[index][E_ATM_POS_X], ATMData[index][E_ATM_POS_Y], zone, sizeof(zone));

    SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", 
        sprintf("Teleported to ATM {2bb358}#%d {DEDEDE}in %s.", id, zone));

    return 1;
}

// Shows the ATM main menu (balance, withdraw).
static OnPlayerUseATM(playerid) {
    inline ViewATMMenu(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if (response) {
            switch (listitem) {
                case 0: ShowATMWithdrawList(playerid);
                case 1: ShowATMBalance(playerid);
            }
        }
    }
    Dialog_ShowCallback(playerid, using inline ViewATMMenu, DIALOG_STYLE_LIST,
        "Automatic Teller Machine", "Withdraw\nBalance", "Select", "Back");
}

// Shows the list of amounts a player can withdraw.
static ShowATMWithdrawList(playerid) {
    inline OnATMWithdraw(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, listitem
        if (!response) {
            OnPlayerUseATM(playerid);
            return 1;
        }

        new amount = strval(inputtext);
        if (amount <= 0 || amount > Character[playerid][E_CHARACTER_BANKCASH]) {
            OnPlayerUseATM(playerid);
            return SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", "You don't have that much money!");
        }

        Character[playerid][E_CHARACTER_BANKCASH] -= amount;
        GivePlayerCash(playerid, amount, "ATM withdraw");

        new query[256];
        mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_bankcash = %d WHERE player_id = %d",  Character[playerid][E_CHARACTER_BANKCASH], Character[playerid][E_CHARACTER_ID]
        );
        mysql_tquery(mysql, query);

        SendServerMessage(playerid, COLOR_ATM, "ATM", "DEDEDE", sprintf("You have withdrawn %s from your bank account.", IntegerWithDelimiter(amount)));

        AddLogEntry(playerid, LOG_TYPE_SCRIPT,  sprintf("Withdrew $%s from an ATM (New balance: $%s)", IntegerWithDelimiter(amount), IntegerWithDelimiter(Character[playerid][E_CHARACTER_BANKCASH])));

        OnPlayerUseATM(playerid);
        return 1;
    }
    Dialog_ShowCallback(playerid, using inline OnATMWithdraw, DIALOG_STYLE_LIST, "Select the amount you wish to withdraw", "150\n250\n500\n750\n1000\n1500\n2500\n5000\n7500\n10000", "Select", "Back");
    return 1;
}

// Shows the player's bank balance and savings.
static ShowATMBalance(playerid) {
    new string[512];
    format(string, sizeof(string),
        "Bank Account: $%s\nSavings: $%s ($%s per paycheck)",
        IntegerWithDelimiter(Character[playerid][E_CHARACTER_BANKCASH]),
        IntegerWithDelimiter(Character[playerid][E_CHARACTER_SAVINGS]),
        IntegerWithDelimiter((Character[playerid][E_CHARACTER_SAVINGS] / 700) / 2)
    );

    inline ViewATMMenu(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext, listitem
        if (!response || response) {
            OnPlayerUseATM(playerid);
            return 1;
        }
    }
    Dialog_ShowCallback(playerid, using inline ViewATMMenu, DIALOG_STYLE_MSGBOX,
        "Your bank balance", string, "Select", "Back");
    return 1;
}
