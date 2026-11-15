// ============================================================================
// File: police/systems/radio.pwn
// Faction radio. Each faction has five channel slots (set in Radio_SetupFactionChannels);
// /radio, /r1-/r5, /r, /radiolow and /channel manage transmission. Edit this file to change
// channel names for SAPD and FDSA.
// Commands: /radio /r1 /r2 /r3 /r4 /r5 /r /radiolow /rlow /channel /ch /channels /chs /scanner
// /department /dep /d /hq
// ============================================================================

// ============================================================================
// Radio System - Per-Faction 5-Slot Model
//
// Each faction gets 5 configurable slots. Configure them in
// Radio_SetupFactionChannels() below, keyed by faction DB ID.
//
// Slot flags:
//   repeated  - all on-duty faction members receive the transmission
//   encrypted - blocks scanner intercept
//
// /radio [1-5] [msg]     send on a specific slot
// /r [msg]               send on currently tuned slot (default: slot 1)
// /r1 .. /r5             shortcuts to send on a specific slot
// /channel [1-5]         tune to a slot (affects /r and non-repeated receipt)
// /channels (/chs)       show this faction's slots
// /radiolow (/rlow)      low-range variant
// ============================================================================

#define RADIO_SLOTS 5

enum E_RADIO_SLOT {
    E_RS_NAME[32],
    bool:E_RS_ENABLED,
    bool:E_RS_REPEATED,    // true = broadcast to all on-duty faction members
    bool:E_RS_ENCRYPTED,   // true = scanner cannot intercept
}

new FactionRadioSlots[MAX_FACTIONS][RADIO_SLOTS][E_RADIO_SLOT];

// ── Slot initialiser ─────────────────────────────────────────────────────────

// Sets the name and flags of one faction radio channel slot.
static Radio_SetSlot(enum_id, slot, const name[], bool:enabled, bool:repeated, bool:encrypted = false)
{
    format(FactionRadioSlots[enum_id][slot][E_RS_NAME], 32, "%s", name);
    FactionRadioSlots[enum_id][slot][E_RS_ENABLED]   = enabled;
    FactionRadioSlots[enum_id][slot][E_RS_REPEATED]  = repeated;
    FactionRadioSlots[enum_id][slot][E_RS_ENCRYPTED] = encrypted;
}

// ── Hardcoded channel config ──────────────────────────────────────────────────
// Called for every faction after the DB load (see faction/data.pwn).
// Add a case per faction DB ID. All unlisted factions get no radio access.

// ── Slot lookups ─────────────────────────────────────────────────────────────
// Everything that reads a slot goes through these.

// Returns whether a faction radio slot is enabled.
static bool:Radio_SlotEnabled(enum_id, slot)
{
    return FactionRadioSlots[enum_id][slot][E_RS_ENABLED];
}

// Returns whether a radio slot repeats to other units.
static bool:Radio_SlotRepeated(enum_id, slot)
{
    return FactionRadioSlots[enum_id][slot][E_RS_REPEATED];
}

// Returns whether a radio slot is encrypted.
static bool:Radio_SlotEncrypted(enum_id, slot)
{
    return FactionRadioSlots[enum_id][slot][E_RS_ENCRYPTED];
}

// Writes the name of a radio slot into name.
static Radio_SlotName(enum_id, slot, name[], len = sizeof(name))
{
    format(name, len, "%s", FactionRadioSlots[enum_id][slot][E_RS_NAME]);
}

// Sets up a faction's five radio channels by faction id. Add channel names for your own factions
// here.
Radio_SetupFactionChannels(faction_enum_id, factionid)
{
    for (new i = 0; i < RADIO_SLOTS; i++)
        Radio_SetSlot(faction_enum_id, i, "Unused", false, false);

    switch (factionid)
    {
		// ID, slot, name, enabled, repeated, encrypted
        case FACTION_ID_SAPD: { // San Andreas Police Department
            Radio_SetSlot(faction_enum_id, 0, "Central Dispatch", true,  true,  false);
            Radio_SetSlot(faction_enum_id, 1, "Patrol",           true,  false, false);
            Radio_SetSlot(faction_enum_id, 2, "SWAT",             true,  false, true);
            Radio_SetSlot(faction_enum_id, 3, "Traffic (TSD)",    true,  false, false);
            Radio_SetSlot(faction_enum_id, 4, "Detectives (DB)",  true,  false, true);
        }
        case FACTION_ID_FDSA: { // Fire Department of San Andreas
            Radio_SetSlot(faction_enum_id, 0, "Central Dispatch", true,  true,  false);
            Radio_SetSlot(faction_enum_id, 1, "Fireground",       true,  false, false);
            Radio_SetSlot(faction_enum_id, 2, "EMS / Medical",    true,  false, false);
            Radio_SetSlot(faction_enum_id, 3, "Command",          true,  false, false);
            Radio_SetSlot(faction_enum_id, 4, "Rescue",           true,  false, false);
        }
    }
}

// ── Faction radio access check ────────────────────────────────────────────────

// Returns true if a faction can use the radio (FAC_CAP_RADIO).
bool:IsRadioFaction(fac_enumid)
{
    return Faction_CanID(fac_enumid, FAC_CAP_RADIO);
}

// Returns true if the player's faction can use the radio.
bool:IsInRadioFaction(playerid)
{
    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if (!factionid) return false;
    return IsRadioFaction(Faction_GetEnumID(factionid));
}

// ── Player tuning ─────────────────────────────────────────────────────────────
// E_PLAYER_PD_RADIO_CHANNEL stores 0–4 (0-indexed slot) or -1 when not set.

// Tunes a player to their default radio channel.
Radio_InitializePlayer(playerid)
{
    PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL] = -1;

    if (!IsInRadioFaction(playerid)) return;

    new fid      = Character[playerid][E_CHARACTER_FACTIONID];
    new enum_id  = Faction_GetEnumID(fid);
    if (enum_id == INVALID_FACTION_ID) return;

    for (new i = 0; i < RADIO_SLOTS; i++) {
        if (Radio_SlotEnabled(enum_id, i)) {
            PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL] = i;
            break;
        }
    }
}

hook ORP_OnLoadCharacter(playerid, character_id)
{
    Radio_InitializePlayer(playerid);

    new slot = PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL];
    if (slot != -1 && PlayerVar[playerid][E_PLAYER_FACTION_DUTY]) {
        new enum_id = Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);
        new slotname[32];
        Radio_SlotName(enum_id, slot, slotname);
        SendServerMessage(playerid, COLOR_FACTION, "Radio", "A3A3A3",
            sprintf("Your radio was automatically tuned to Channel %d \"%s\".",
                slot + 1, slotname));
    }

    return 1;
}

// ── Message delivery check ────────────────────────────────────────────────────

// Returns true if a target should hear a radio message from a sender.
static bool:IsRadioMessageReceiver(senderid, targetid, slot, faction_enum_id)
{
    if (!PlayerVar[targetid][E_PLAYER_FACTION_DUTY]) return false;
    if (Character[targetid][E_CHARACTER_FACTIONID] != Character[senderid][E_CHARACTER_FACTIONID]) return false;

    // The sender always hears their own transmission, even when tuned elsewhere.
    if (senderid == targetid) return true;

    if (Radio_SlotRepeated(faction_enum_id, slot)) return true;

    return PlayerVar[targetid][E_PLAYER_PD_RADIO_CHANNEL] == slot;
}

// ── Core send ─────────────────────────────────────────────────────────────────

static ChannelDlgStr[2048];
static ChannelSlotIndex[RADIO_SLOTS];

// Sends a radio message on a slot to every unit who hears it.
Radio_SendMessage(playerid, slot, const msg[], bool:low_range)
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    new factionid      = Character[playerid][E_CHARACTER_FACTIONID];
    new faction_enum_id = Faction_GetEnumID(factionid);

    if (!factionid || faction_enum_id == INVALID_FACTION_ID || !IsInRadioFaction(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction with a radio.");

    if (!PlayerVar[playerid][E_PLAYER_FACTION_DUTY])
        return SendServerMessage(playerid, COLOR_ERROR, "Radio", "A3A3A3", "You must be on duty to use your faction radio.");

    if (!Radio_SlotEnabled(faction_enum_id, slot))
        return SendServerMessage(playerid, COLOR_ERROR, "Radio", "A3A3A3", "That channel slot is not enabled for your faction.");

    new string[256];
    new badge = Character[playerid][E_CHARACTER_FACTION_BADGE];
    new slotName[32];
    Radio_SlotName(faction_enum_id, slot, slotName);
    new bool:slot_encrypted = Radio_SlotEncrypted(faction_enum_id, slot);

    if (low_range)
        format(string, sizeof(string), "** [CH %d: %s] (Low) %s #%05d: %s", slot + 1, slotName, ReturnRPName(playerid), badge, msg);
    else
        format(string, sizeof(string), "** [CH %d: %s] %s #%05d: %s", slot + 1, slotName, ReturnRPName(playerid), badge, msg);

    foreach (new targetid: Player) {
        if (!IsPlayerPlaying(targetid)) continue;

        // Scanner intercept (unencrypted only)
        if (IsPlayerInAnyVehicle(targetid)) {
            new vehicleid = GetPlayerVehicleID(targetid);
            if (vehicleid && VehicleVar[vehicleid][E_VEHICLE_SCANNER_CHANNEL] == (slot + 1)
                && !slot_encrypted) {
                ZMsg_SendClientMessage(targetid, COLOR_POLICE, string);
            }
        }

        if (!Character[targetid][E_CHARACTER_FACTIONID] || !PlayerVar[targetid][E_PLAYER_FACTION_DUTY]) continue;
        if (!IsRadioMessageReceiver(playerid, targetid, slot, faction_enum_id)) continue;

        if (PlayerVar[targetid][E_PLAYER_PD_RADIO_CHANNEL] == slot)
            ZMsg_SendClientMessage(targetid, 0xFFEC8BFF, string);
        else
            ZMsg_SendClientMessage(targetid, 0xDFD6A6FF, string);
    }

    AddLogEntry(playerid, LOG_TYPE_RADIO, string);
    return true;
}

// ── Commands ──────────────────────────────────────────────────────────────────

// /radio [1-5] [message] - transmits on a radio channel.
CMD:radio(playerid, params[])
{
    new slot, msg[144];
    if (sscanf(params, "ds[144]", slot, msg))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/radio [1-5] [message]");

    if (slot < 1 || slot > RADIO_SLOTS)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("Slot must be between 1 and %d.", RADIO_SLOTS));

    return Radio_SendMessage(playerid, slot - 1, msg, false);
}

// Helper that turns /r1../r5 into /radio.
static Radio_Shortcut(playerid, slot, const params[])
{
    new fwd[150];
    format(fwd, sizeof(fwd), "%d %s", slot, params);
    return cmd_radio(playerid, fwd);
}

// /r1 [message] - transmits on radio channel 1.
CMD:r1(playerid, params[]) { return Radio_Shortcut(playerid, 1, params); }
// /r2 [message] - transmits on radio channel 2.
CMD:r2(playerid, params[]) { return Radio_Shortcut(playerid, 2, params); }
// /r3 [message] - transmits on radio channel 3.
CMD:r3(playerid, params[]) { return Radio_Shortcut(playerid, 3, params); }
// /r4 [message] - transmits on radio channel 4.
CMD:r4(playerid, params[]) { return Radio_Shortcut(playerid, 4, params); }
// /r5 [message] - transmits on radio channel 5.
CMD:r5(playerid, params[]) { return Radio_Shortcut(playerid, 5, params); }

// /r [message] - transmits on the channel you're tuned to.
CMD:r(playerid, params[])
{
    new slot = PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL];
    if (slot == -1) slot = 0; // default to slot 1 if not yet tuned
    return Radio_Shortcut(playerid, slot + 1, params);
}

// /radiolow [1-5] [message] - transmits quietly so only people very close hear it.
CMD:radiolow(playerid, params[])
{
    new slot, msg[144];
    if (sscanf(params, "ds[144]", slot, msg))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/radiolow [1-5] [message]");

    if (slot < 1 || slot > RADIO_SLOTS)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("Slot must be between 1 and %d.", RADIO_SLOTS));

    return Radio_SendMessage(playerid, slot - 1, msg, true);
}

// /rlow [message] - quiet transmission on your current channel.
CMD:rlow(playerid, params[])
{
    new slot = PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL];
    if (slot == -1) slot = 0;
    return Radio_SendMessage(playerid, slot, params, true);
}

// /channel [1-5] - tunes your radio to a channel.
CMD:channel(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    if (!IsInRadioFaction(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction that can use the radio.");

    new factionid      = Character[playerid][E_CHARACTER_FACTIONID];
    new faction_enum_id = Faction_GetEnumID(factionid);
    new current        = PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL];

    new slot;
    if (sscanf(params, "d", slot) || slot < 1 || slot > RADIO_SLOTS) {
        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/ch(annel) [1-5]");
        if (current >= 0 && faction_enum_id != INVALID_FACTION_ID)
        {
            new curname[32];
            Radio_SlotName(faction_enum_id, current, curname);
            SendClientMessage(playerid, 0xDEDEDEFF, sprintf("Current slot: %d (%s). Use /channels to view all.", current + 1, curname));
        }
        return true;
    }

    slot -= 1;

    if (faction_enum_id == INVALID_FACTION_ID || !Radio_SlotEnabled(faction_enum_id, slot))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That slot is not enabled for your faction.");

    new slotname[32];
    Radio_SlotName(faction_enum_id, slot, slotname);
    PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL] = slot;
    SendServerMessage(playerid, COLOR_FACTION, "Radio", "A3A3A3",
        sprintf("Tuned to channel %d (%s).", slot + 1, slotname));
    return true;
}

CMD:ch(playerid, params[]) { return cmd_channel(playerid, params); }

// /channels - lists the radio channels of your faction.
CMD:channels(playerid)
{
    if (!IsInRadioFaction(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction that uses the radio.");

    new factionid      = Character[playerid][E_CHARACTER_FACTIONID];
    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Faction error. Contact a developer.");

    new current = PlayerVar[playerid][E_PLAYER_PD_RADIO_CHANNEL];

    // Build a parallel index so listitem maps back to the real slot number
    new numRows = 0;
    format(ChannelDlgStr, sizeof(ChannelDlgStr), "Slot\tName\tBroadcast\tEncrypted");

    for (new i = 0; i < RADIO_SLOTS; i++) {
        if (!Radio_SlotEnabled(faction_enum_id, i)) continue;
        new rowname[32];
        Radio_SlotName(faction_enum_id, i, rowname);
        ChannelSlotIndex[numRows++] = i;
        format(ChannelDlgStr, sizeof(ChannelDlgStr), "%s\n%s%d\t%s\t%s\t%s",
            ChannelDlgStr,
            (current == i) ? "{FFD700}" : "",
            i + 1,
            rowname,
            Radio_SlotRepeated(faction_enum_id, i)  ? "Yes" : "No",
            Radio_SlotEncrypted(faction_enum_id, i) ? "Yes" : "No");
    }

    inline DlgChannels(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext
        if (response && listitem >= 0 && listitem < numRows) {
            new slot = ChannelSlotIndex[listitem];
            PlayerVar[pid][E_PLAYER_PD_RADIO_CHANNEL] = slot;
            new fid2 = Character[pid][E_CHARACTER_FACTIONID];
            new eid2 = Faction_GetEnumID(fid2);
            new tunedname[32];
            Radio_SlotName(eid2, slot, tunedname);
            SendServerMessage(pid, COLOR_FACTION, "Radio", "A3A3A3",
                sprintf("Tuned to channel %d (%s).", slot + 1, tunedname));
        }
    }

    Dialog_ShowCallback(playerid, using inline DlgChannels, DIALOG_STYLE_TABLIST_HEADERS,
        sprintf("Radio Channels — %s", Faction[faction_enum_id][E_FACTION_ABBREV]),
        ChannelDlgStr, "Tune", "Close");
    return true;
}

CMD:chs(playerid) { return cmd_channels(playerid); }

// ── Scanner ───────────────────────────────────────────────────────────────────
// Intercepts unencrypted transmissions on a given slot number (1–5).

// /scanner [1-5] - news and federal staff listen to a faction's channel with a scanner.
CMD:scanner(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid) && !IsPlayerInFederalFaction(playerid)) return false;

    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    new vehicleid = GetPlayerVehicleID(playerid);
    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (!IsPlayerInAnyVehicle(playerid) || !vehicleid || veh_enum_id == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle equipped with a radio scanner.");

    new slotstr[4];
    sscanf(params, "s[4]", slotstr);

    if (strlen(slotstr)) {
        if (!strcmp(slotstr, "off", true)) {
            VehicleVar[vehicleid][E_VEHICLE_SCANNER_CHANNEL] = 0;
            SendClientMessage(playerid, COLOR_FACTION, "You turned the radio scanner off.");
            return true;
        }

        new slot = strval(slotstr);
        if (IsNumeric(slotstr) && slot >= 1 && slot <= RADIO_SLOTS) {
            VehicleVar[vehicleid][E_VEHICLE_SCANNER_CHANNEL] = slot;
            SendClientMessage(playerid, COLOR_FACTION, sprintf("Scanner tuned to slot %d. Encrypted channels will not be audible.", slot));
            return true;
        }
    }

    SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/scanner [1-5] or \"off\"");
    return true;
}

// Resets a vehicle's scanner channel.
Scanner_Reset(vehicleid)
{
    VehicleVar[vehicleid][E_VEHICLE_SCANNER_CHANNEL] = 0;
}

// ── Department & HQ (unchanged) ───────────────────────────────────────────────

// /department [text] - sends a message to every government department.
CMD:department(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if (!factionid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3)
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You are unable to use this command.");

    new faction_enum_id = Faction_GetEnumID(factionid);
    if (faction_enum_id == INVALID_FACTION_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");

    new text[144];
    if (sscanf(params, "s[144]", text)) {
        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/dep(artment) [text]");
        return true;
    }

    new string[256], vehicleid;

    if (IsPlayerInAnyGovFaction(playerid, true))
        format(string, sizeof(string), "** [DEP] %s: %s", ReturnRPName(playerid), text);
    else
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a government faction.");

    foreach (new targetid: Player) {
        if (IsPlayerInAnyGovFaction(targetid, true)) {
            ZMsg_SendClientMessage(targetid, 0x88D0C5FF, string);
        } else {
            if (IsPlayerInAnyVehicle(playerid)) {
                vehicleid = GetPlayerVehicleID(targetid);
                if (vehicleid && VehicleVar[vehicleid][E_VEHICLE_SCANNER_CHANNEL])
                    ZMsg_SendClientMessage(targetid, COLOR_POLICE, string);
            }
        }
    }

    AddLogEntry(playerid, LOG_TYPE_RADIO, sprintf("[DEP/%s] %s", Faction[faction_enum_id][E_FACTION_ABBREV], text));
    return true;
}

CMD:dep(playerid, params[]) { return cmd_department(playerid, params); }
CMD:d(playerid, params[])   { return cmd_department(playerid, params); }

// /hq [text] - sends a message to your faction's headquarters.
CMD:hq(playerid, params[])
{
    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if (!factionid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");

    if (!IsPlayerInDutyFaction(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a government faction.");

    new faction_enum_id = Faction_GetEnumID(factionid);
    if (faction_enum_id == INVALID_FACTION_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 2)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have the correct privileges to perform this action.");

    new input[144];
    if (sscanf(params, "s[144]", input))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/hq [text]");

    new string[256], hq_rank[64];
    format(hq_rank, sizeof(hq_rank), "%s", Character[playerid][E_CHARACTER_FACTIONRANK]);
    format(string, sizeof(string), "{[ [%s/HQ] [ID %d] %s %s: %s ]}",
        Faction[faction_enum_id][E_FACTION_ABBREV], playerid, hq_rank, ReturnSettingsName(playerid, playerid), input);

    Faction_SendMessage(factionid, string, faction_enum_id, true, true, .color = 0xE86C00FF);
    return true;
}
