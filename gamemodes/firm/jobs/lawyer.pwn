// ============================================================================
// File: firm/jobs/lawyer.pwn
// Lawyer firm field: a lawyer offers to defend a jailed player for a fee to reduce their
// sentence (/inmates, /defend). Needs real contact between players and has hard limits.
// Commands: /inmates /defend
// ============================================================================

// Firm Lawyer field - "defend" a prisoner for a fee to shave time off their
// sentence. Deliberately structured to require real roleplay contact (a
// list, an offer, an accept) rather than a one-command discount, and capped
// hard in three independent ways so it can never trivialize a sentence:
//   - never below ARREST_TIME_MIN_REMAINING (a stay always ends with a real tail)
//   - never more than ARREST_TIME_MAX_REDUCTION_PCT of the remaining time
//   - the offer is auto-capped to what the prisoner can actually pay
//     (cash + bank, combined) - nobody ever goes negative.

#define ARREST_TIME_ELIGIBLE_THRESHOLD  (900)   // 15 min - below this, a lawyer isn't worth it (matches "stays at the station" RP)
#define ARREST_TIME_MIN_REMAINING       (900)   // 15 min - a defended sentence can never be reduced below this
#define ARREST_TIME_MAX_REDUCTION_PCT   (50)    // never reduce by more than this % of current remaining time
#define LAWYER_MIN_RATE_PER_MINUTE (Runtime_Int(RT_FIRMS_LAWYER_MINUTE_RATE)) // Cached database setting; edit through ACP.
#define DEFEND_PROXIMITY_RANGE          (10.0)  // lawyer and prisoner must be in the same room (a guard has to walk the prisoner to a visitation room) - checked on both offer and accept

// Returns true if the player is on duty in a lawyer firm.
bool:CanUseLawyerTools(playerid)
{
    return Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_LAWYER);
}

// Returns true if a prisoner can be defended (not a life sentence and still serving time).
static bool:IsEligibleForDefense(targetid)
{
    if (Character[targetid][E_CHARACTER_JFL])
    {
        return false; // life sentences are out of scope for this tool
    }

    if (Character[targetid][E_CHARACTER_ARREST_TIME] == -1) // ARREST_TIME_AWAITING_RELEASE (police/detaining/arrest.pwn), included after this file
    {
        return false; // already served
    }

    if (Character[targetid][E_CHARACTER_ARREST_TIME] < ARREST_TIME_ELIGIBLE_THRESHOLD)
    {
        return false; // short stay, no lawyer needed
    }

    return !Character[targetid][E_CHARACTER_LAWYER_USED];
}

// A separate list from /prisoners (police-facing) - only shows sentences a
// lawyer could actually act on.
CMD:inmates(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!CanUseLawyerTools(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You're not on duty in a lawyer firm.");
    }

    new string[144], count = 0;
    SendClientMessage(playerid, COLOR_BLUE, "Prisoners eligible for legal defense (15+ minutes remaining):");

    foreach (new targetid: Player)
    {
        if (!IsEligibleForDefense(targetid))
        {
            continue;
        }

        format(string, sizeof(string), "(%d) %s - %d minute(s) remaining.",
            targetid, ReturnSettingsName(targetid, playerid), Character[targetid][E_CHARACTER_ARREST_TIME] / 60);
        SendClientMessage(playerid, 0xDEDEDEFF, string);
        count++;
    }

    if (!count)
    {
        SendClientMessage(playerid, 0xA3A3A3FF, "There are no prisoners currently eligible for defense.");
    }
    else
    {
        SendClientMessage(playerid, 0xA3A3A3FF, "Use /defend [playerid] [minutes] [price per minute] to offer your services.");
    }

    return true;
}

// /defend [player] [minutes] [price per minute] - a lawyer offers to reduce a prisoner's sentence
// for a fee.
CMD:defend(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
    {
        return Firm_SendAccessDenied(playerid);
    }

    if (!CanUseLawyerTools(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You're not on duty in a lawyer firm.");
    }

    new targetid, minutes, price;
    if (sscanf(params, "k<player>ii", targetid, minutes, price))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/defend [playerid] [minutes] [price per minute]");
    }

    if (!IsPlayerConnected(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player isn't connected.");
    }

    if (!IsEligibleForDefense(targetid))
    {
        SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That player isn't eligible for defense (not jailed 15+ minutes, already served, or a life sentence).");
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "They may also have already used a lawyer this sentence.");
    }

    if (!IsPlayerNearPlayer(playerid, targetid, DEFEND_PROXIMITY_RANGE))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You need to be with your client - have a guard walk them to a visitation room first.");
    }

    if (minutes < 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "Minutes must be at least 1.");
    }

    if (price < LAWYER_MIN_RATE_PER_MINUTE)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", sprintf("Your price can't be below $%s per minute.", IntegerWithDelimiter(LAWYER_MIN_RATE_PER_MINUTE)));
    }

    if (GetPVarInt(targetid, "DEFENDREQUEST") != 0)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "This player already has a pending defense offer.");
    }

    // Cap 1: never reduce below 15 minutes remaining.
    new max_minutes_floor = (Character[targetid][E_CHARACTER_ARREST_TIME] / 60) - (ARREST_TIME_MIN_REMAINING / 60);

    // Cap 2: never more than 50% of the current remaining time.
    new max_minutes_pct = (Character[targetid][E_CHARACTER_ARREST_TIME] / 60) * ARREST_TIME_MAX_REDUCTION_PCT / 100;

    new max_minutes = max_minutes_floor < max_minutes_pct ? max_minutes_floor : max_minutes_pct;

    // Cap 3: never more than the prisoner can actually pay (cash + bank).
    new affordable = GetPlayerCash(targetid) + Character[targetid][E_CHARACTER_BANKCASH];
    new max_minutes_affordable = affordable / price;

    if (max_minutes > max_minutes_affordable)
    {
        max_minutes = max_minutes_affordable;
    }

    if (max_minutes < 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "This player can't afford even a single minute at that price, and/or their sentence is already too short to reduce further.");
    }

    if (minutes > max_minutes)
    {
        minutes = max_minutes;
        SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("Your offer was capped to %d minute(s) (sentence floor, the 50%% cap, or what they can afford).", minutes));
    }

    new fee = minutes * price;

    SetPVarInt(targetid, "DEFENDREQUEST", 1);
    SetPVarInt(targetid, "DEFENDREQUEST_LAWYER", playerid);
    SetPVarInt(targetid, "DEFENDREQUEST_MINUTES", minutes);
    SetPVarInt(targetid, "DEFENDREQUEST_FEE", fee);

    SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("You've offered to defend %s for $%s, reducing their sentence by %d minute(s).",
        ReturnSettingsName(targetid, playerid), IntegerWithDelimiter(fee), minutes));

    SendServerMessage(targetid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("%s has offered to defend you for $%s, reducing your sentence by %d minute(s). Type \"/accept defend\" to accept.",
        ReturnSettingsName(playerid, targetid), IntegerWithDelimiter(fee), minutes));

    defer DefendRequestExpire(targetid);
    return true;
}

// Timer: cancels an unanswered defence offer after 30 seconds.
timer DefendRequestExpire[30000](targetid)
{
    SetPVarInt(targetid, "DEFENDREQUEST", 0);
    return 1;
}

// Called from CMD:accept (minigame/shakehands.pwn) on "/accept defend".
Lawyer_OnPlayerDefendResponse(playerid)
{
    if (GetPVarInt(playerid, "DEFENDREQUEST") != 1)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have a pending defense offer.");
    }

    new lawyerid = GetPVarInt(playerid, "DEFENDREQUEST_LAWYER");
    new minutes  = GetPVarInt(playerid, "DEFENDREQUEST_MINUTES");
    new fee      = GetPVarInt(playerid, "DEFENDREQUEST_FEE");

    SetPVarInt(playerid, "DEFENDREQUEST", 0);

    if (!IsPlayerConnected(lawyerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "That lawyer is no longer connected.");
    }

    if (!IsEligibleForDefense(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You're no longer eligible for defense (sentence changed).");
    }

    if (!IsPlayerNearPlayer(playerid, lawyerid, DEFEND_PROXIMITY_RANGE))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You're no longer with your lawyer - stay together until this is settled.");
    }

    // Cash first, then bank for the remainder - never goes negative, this
    // was already guaranteed affordable when the offer was made.
    new cash = GetPlayerCash(playerid);
    new from_cash = cash < fee ? cash : fee;
    new from_bank = fee - from_cash;

    if (from_cash > 0)
    {
        TakePlayerCash(playerid, from_cash, "Legal defense fee");
    }

    if (from_bank > 0)
    {
        Character[playerid][E_CHARACTER_BANKCASH] -= from_bank;

        new query[192];
        mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_bankcash = %d WHERE player_id = %d",
            Character[playerid][E_CHARACTER_BANKCASH], Character[playerid][E_CHARACTER_ID]);
        mysql_tquery(mysql, query);
    }

    GivePlayerCash(lawyerid, fee, "Legal defense fee");

    Character[playerid][E_CHARACTER_ARREST_TIME] -= minutes * 60;
    Character[playerid][E_CHARACTER_LAWYER_USED] = 1;

    new query2[192];
    mysql_format(mysql, query2, sizeof(query2), "UPDATE characters SET player_arrest_time = %d, player_lawyer_used = 1 WHERE player_id = %d",
        Character[playerid][E_CHARACTER_ARREST_TIME], Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query2);

    SendServerMessage(playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("%s reduced your sentence by %d minute(s). %d minute(s) remaining.",
        ReturnSettingsName(lawyerid, playerid), minutes, Character[playerid][E_CHARACTER_ARREST_TIME] / 60));
    SendServerMessage(lawyerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf("%s accepted your offer. You were paid $%s.",
        ReturnSettingsName(playerid, lawyerid), IntegerWithDelimiter(fee)));

    AddLogEntry(lawyerid, LOG_TYPE_JOB, sprintf("defended (%d) for $%d, reducing their sentence by %d minute(s)", playerid, fee, minutes));
    return true;
}
