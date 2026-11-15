// ============================================================================
// File: injury/knockout.pwn
// Knockout system: heavy hits can knock a player out for a few seconds (KO_TriggerKnockout /
// KO_RecoverPlayer). By Tramposo.
// ============================================================================

// ------------------------------------------------------------------------------
// Knockout system for injury gamemode - Tramposo Oct 2025
// ------------------------------------------------------------------------------

#define KO_HP_THRESHOLD         (20.0)      // HP at or below which a fist hit triggers KO
#define KO_DURATION_TICKS       (90)        // seconds the KO phase lasts
#define KO_HELPUP_MIN_TICK      (60)        // seconds before /helpup is allowed
#define KO_HEAL_INTERVAL        (5)         // heal 1 HP every N seconds
#define KO_CHAT_COLOR           (0x7EB0D6FF)
#define KO_ANIM_COUNT           (6)         // number of KO animations available

new KO_Tick[MAX_PLAYERS];               // countdown from KO_DURATION_TICKS
new KO_HealAccum[MAX_PLAYERS];          // accumulates seconds since last heal tick

// Plays a random knockout animation.
stock KO_ApplyAnimation(playerid)
{
    new anim = (random(KO_ANIM_COUNT) + 1);
    switch (anim)
    {
        case 1: ApplyAnimation(playerid, "CRACK", "crckdeth1", 4.1, 0, 0, 0, 1, 0, 1);
        case 2: ApplyAnimation(playerid, "CRACK", "crckdeth2", 4.1, 1, 0, 0, 0, 0, 1);
        case 3: ApplyAnimation(playerid, "CRACK", "crckdeth3", 4.1, 0, 0, 0, 1, 0, 1);
        case 4: ApplyAnimation(playerid, "CRACK", "crckidle1", 4.1, 0, 0, 0, 1, 0, 1);
        case 5: ApplyAnimation(playerid, "CRACK", "crckidle2", 4.1, 0, 0, 0, 1, 0, 1);
        case 6: ApplyAnimation(playerid, "CRACK", "crckidle3", 4.1, 0, 0, 0, 1, 0, 1);
    }
}

// called from OnPlayerGiveDamage

// Knocks a player out for a short time after a heavy melee hit.
stock KO_TriggerKnockout(playerid, issuerid)
{
    if (PlayerVar[playerid][E_PLAYER_KNOCKED_OUT]) return;

    PlayerVar[playerid][E_PLAYER_KNOCKED_OUT] = true;
    KO_Tick[playerid]          = KO_DURATION_TICKS;
    KO_HealAccum[playerid]     = 0;

    TogglePlayerControllable(playerid, false);
    KO_ApplyAnimation(playerid);

    SetPlayerChatBubble(playerid,
        "(( This player is knocked out ))",
        KO_CHAT_COLOR, 7.5, 1500);

    Damage_SnapClientHealth(playerid);

    SendClientMessage(playerid, COLOR_RED,
        sprintf("You've been knocked out by %s (%d). You will recover in %d seconds.",
            ReturnRPName(issuerid), issuerid, KO_DURATION_TICKS));

    SendClientMessage(issuerid, COLOR_RED,
        sprintf("You knocked out %s (%d).",
            ReturnRPName(playerid), playerid));

    SendAdminMessage(
        sprintf("[KNOCKOUT]: (%d) %s has knocked out (%d) %s.",
            issuerid, ReturnRPName(issuerid),
            playerid, ReturnRPName(playerid)),
        COLOR_ANTICHEAT);

    AddLogEntry(playerid, LOG_TYPE_DAMAGE, sprintf("Knocked out by %s (%d)",  ReturnRPName(issuerid), issuerid));
    AddLogEntry(issuerid, LOG_TYPE_DAMAGE, sprintf("Knocked out %s (%d)",     ReturnRPName(playerid), playerid));

    defer KO_TickCountdown(playerid);
}

// Wakes a knocked-out player up.
stock KO_RecoverPlayer(playerid)
{
    if (!PlayerVar[playerid][E_PLAYER_KNOCKED_OUT]) return;

    PlayerVar[playerid][E_PLAYER_KNOCKED_OUT] = false;
    KO_Tick[playerid]          = 0;
    KO_HealAccum[playerid]     = 0;

    TogglePlayerControllable(playerid, true);
    ApplyAnimation(playerid, "PED", "getup_front", 4.1, 0, 0, 0, 0, 0, true);
    SetPlayerChatBubble(playerid, " ", KO_CHAT_COLOR, 7.5, 1000);

    Weapon_SetSkillLevel(playerid, 999);
}

// Timer: counts down the knockout and recovers some health.
timer KO_TickCountdown[1000](playerid)
{
    if (!PlayerVar[playerid][E_PLAYER_KNOCKED_OUT]) return;

    SetPlayerChatBubble(playerid,
        "(( This player is knocked out ))",
        KO_CHAT_COLOR, 7.5, 1500);

    KO_HealAccum[playerid]++;
    if (KO_HealAccum[playerid] >= KO_HEAL_INTERVAL)
    {
        KO_HealAccum[playerid] = 0;
        new Float:hp = GetCharacterHealth(playerid);
        SetCharacterHealth(playerid, hp + 1.0);
        Damage_SnapClientHealth(playerid);
    }

    KO_Tick[playerid]--;

    if (KO_Tick[playerid] <= 0)
    {
        KO_RecoverPlayer(playerid);

        SendClientMessage(playerid, COLOR_RED,
            "You've regained consciousness and are back on your feet.");
        return;
    }

    if (KO_Tick[playerid] % 10 == 0)
    {
        KO_ApplyAnimation(playerid);
    }

    defer KO_TickCountdown(playerid);
}

// Returns true if the player is knocked out.
stock IsPlayerKnockedOut(playerid)
{
    return PlayerVar[playerid][E_PLAYER_KNOCKED_OUT];
}

// Returns how many seconds of knockout are left.
stock KO_GetRemainingTicks(playerid)
{
    return KO_Tick[playerid];
}

// Clears a player's knockout state.
stock KO_ResetPlayer(playerid)
{
    PlayerVar[playerid][E_PLAYER_KNOCKED_OUT] = false;
    KO_Tick[playerid]          = 0;
    KO_HealAccum[playerid]     = 0;
}
