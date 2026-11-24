// ============================================================================
// File: police/systems/breathalyzer.pwn
// /breathalyzer: test another player's alcohol level over a few seconds.
// Commands: /breathalyzer /cancelbreathalyzer
// ============================================================================

#define BREATHALYZER_DISTANCE       3.0
#define BREATHALYZER_TEST_TIME      8
#define BREATHALYZER_COOLDOWN (Runtime_Int(RT_POLICE_BREATHALYZER_COOLDOWN)) // Cached database setting; edit through ACP.
#define BREATHALYZER_DETECT_WINDOW  3600

#define BREATHALYZER_ANIM_LIB       "PLAYIDLES" // might change later for a better one
#define BREATHALYZER_ANIM_NAME      "time"


enum E_BREATHALYZER_DATA {
    E_BREATH_BEING_TESTED,
    E_BREATH_TESTER,
    E_BREATH_TIMER,
    E_BREATH_LAST_TESTED,
    E_BREATH_LAST_TESTER[MAX_PLAYER_NAME]
}
static BreathData[MAX_PLAYERS][E_BREATHALYZER_DATA];

hook OnPlayerConnect(playerid)
{
    BreathData[playerid][E_BREATH_BEING_TESTED]    = false;
    BreathData[playerid][E_BREATH_TESTER]          = INVALID_PLAYER_ID;
    BreathData[playerid][E_BREATH_TIMER]           = -1;
    BreathData[playerid][E_BREATH_LAST_TESTED]     = 0;
    BreathData[playerid][E_BREATH_LAST_TESTER][0]  = EOS;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if (BreathData[playerid][E_BREATH_BEING_TESTED])
    {
        new officerid = BreathData[playerid][E_BREATH_TESTER];

        if (BreathData[playerid][E_BREATH_TIMER] != -1)
        {
            KillTimer(BreathData[playerid][E_BREATH_TIMER]);
            BreathData[playerid][E_BREATH_TIMER] = -1;
        }

        if (IsPlayerConnected(officerid))
        {
            ClearAnimations(officerid);
            SendServerMessage(officerid, 0x6C3275FF, "Breathalyzer", "A3A3A3", "The subject disconnected. Test cancelled.");
        }

        BreathData[playerid][E_BREATH_BEING_TESTED] = false;
        BreathData[playerid][E_BREATH_TESTER]       = INVALID_PLAYER_ID;
    }

    foreach (new i: Player)
    {
        if (BreathData[i][E_BREATH_TESTER] == playerid && BreathData[i][E_BREATH_BEING_TESTED])
        {
            if (BreathData[i][E_BREATH_TIMER] != -1)
            {
                KillTimer(BreathData[i][E_BREATH_TIMER]);
                BreathData[i][E_BREATH_TIMER] = -1;
            }

            ClearAnimations(i);
            SendServerMessage(i, 0x6C3275FF, "Breathalyzer", "A3A3A3", "The testing officer disconnected. Test cancelled.");

            BreathData[i][E_BREATH_BEING_TESTED] = false;
            BreathData[i][E_BREATH_TESTER]       = INVALID_PLAYER_ID;
        }
    }
    return 1;
}

// Cancels a breathalyzer test (officer left, target moved...).
static CancelBreathalyzerTest(targetid, officerid, const reason[])
{
    if (BreathData[targetid][E_BREATH_TIMER] != -1)
    {
        KillTimer(BreathData[targetid][E_BREATH_TIMER]);
        BreathData[targetid][E_BREATH_TIMER] = -1;
    }

    ClearAnimations(targetid);

    if (IsPlayerConnected(officerid))
    {
        ClearAnimations(officerid);
        SendServerMessage(officerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", reason);
    }

    SendServerMessage(targetid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "The breathalyzer test was cancelled.");

    BreathData[targetid][E_BREATH_BEING_TESTED] = false;
    BreathData[targetid][E_BREATH_TESTER]       = INVALID_PLAYER_ID;
}

// Completes a breathalyzer test and tells the officer the alcohol reading.
static BreathalyzerComplete(playerid, officerid)
{
    BreathData[playerid][E_BREATH_TIMER]        = -1;
    BreathData[playerid][E_BREATH_BEING_TESTED] = false;
    BreathData[playerid][E_BREATH_TESTER]       = INVALID_PLAYER_ID;
    BreathData[playerid][E_BREATH_LAST_TESTED]  = gettime();

    GetPlayerName(officerid, BreathData[playerid][E_BREATH_LAST_TESTER], MAX_PLAYER_NAME);

    ClearAnimations(playerid);
    if (IsPlayerConnected(officerid))
        ClearAnimations(officerid);

    if (!IsPlayerConnected(officerid))
        return;

    new str[200];
    new lastuse  = Character[playerid][E_CHARACTER_LAST_DRUG_USE];
    new elapsed  = gettime() - lastuse;
    new positive = (lastuse != 0 && elapsed < BREATHALYZER_DETECT_WINDOW);

    if (positive)
    {
        new minutes = elapsed / 60;

        ProxDetectorEx(officerid, 5.0, COLOR_ACTION, "*",
            sprintf("holds up the breathalyzer towards %s - the device beeps red.", ReturnRPName(playerid)),
            .annonated=true);

        format(str, sizeof(str), "{8B1D1D}[POSITIVE] {FFFFFF}%s has used drugs in the last hour. {7E3E7D}(%d minute(s) ago)",
            ReturnRPName(playerid), minutes);
        SendServerMessage(officerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", str);

        SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3",
            "The breathalyzer test came back POSITIVE. An active substance was detected.");

        format(str, sizeof(str), "[BREATHALYZER] %s tested %s - Result: POSITIVE (used %d min ago).",
            ReturnRPName(officerid), ReturnRPName(playerid), minutes);

        new Float:ox, Float:oy, Float:oz;
        GetPlayerPos(officerid, ox, oy, oz);

        foreach (new i: Player)
        {
            if (i == officerid || i == playerid) continue;
            if (!IsPlayerInLEAFaction(i, true)) continue;
            if (GetPlayerDistanceFromPoint(i, ox, oy, oz) > 20.0) continue;
            SendClientMessage(i, COLOR_SERVER, str);
        }

        AddLogEntry(officerid, LOG_TYPE_SCRIPT,
            sprintf("[breathalyzer] %s tested %s - POSITIVE (used %d min ago)", ReturnRPName(officerid), ReturnRPName(playerid), minutes));
    }
    else
    {
        ProxDetectorEx(officerid, 5.0, COLOR_ACTION, "*",
            sprintf("holds up the breathalyzer towards %s - the device beeps green.", ReturnRPName(playerid)),
            .annonated=true);

        format(str, sizeof(str), "{4A8D20}[NEGATIVE]{FFFFFF} %s shows no recent substance use.", ReturnRPName(playerid));
        SendServerMessage(officerid, COLOR_SERVER, "Breathalyzer", "A3A3A3", str);

        SendServerMessage(playerid, COLOR_SERVER, "Breathalyzer", "A3A3A3",
            "The breathalyzer test came back negative. No active substance detected.");

        AddLogEntry(officerid, LOG_TYPE_SCRIPT,
            sprintf("[breathalyzer] %s tested %s - NEGATIVE", ReturnRPName(officerid), ReturnRPName(playerid)));
    }
}

forward BreathalyzerTimer(playerid, officerid);
// Timer: runs the breathalyzer test step by step.
public BreathalyzerTimer(playerid, officerid)
{
    if (!IsPlayerConnected(officerid))
    {
        CancelBreathalyzerTest(playerid, officerid, "Test cancelled - officer disconnected.");
        return;
    }

    new Float:ox, Float:oy, Float:oz;
    GetPlayerPos(officerid, ox, oy, oz);

    if (GetPlayerDistanceFromPoint(playerid, ox, oy, oz) > BREATHALYZER_DISTANCE * 3.0)
    {
        CancelBreathalyzerTest(playerid, officerid, "You moved too far away. Test cancelled.");
        return;
    }

    BreathalyzerComplete(playerid, officerid);
}

// /breathalyzer [player] - tests a nearby player's alcohol level.
CMD:breathalyzer(playerid, params[])
{
    if (!IsPlayerInLEAFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "You must be on duty in a law enforcement faction.");

    new targetid;
    if (sscanf(params, "k<player>", targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/breathalyzer [player]");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "That player is not connected.");

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);

    if (!IsPlayerInRangeOfPoint(playerid, BREATHALYZER_DISTANCE, tx, ty, tz))
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "You must be closer to the subject to administer a test.");

    if (BreathData[targetid][E_BREATH_BEING_TESTED])
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "This player is already being tested by another officer.");

    new lasttest = BreathData[targetid][E_BREATH_LAST_TESTED];
    new timerest = gettime() - lasttest;

    if (lasttest != 0 && timerest < BREATHALYZER_COOLDOWN)
    {
        new remaining = BREATHALYZER_COOLDOWN - timerest;
        new cdstr[12];
        FormatCooldownTime(remaining, cdstr, sizeof(cdstr));
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3",
            sprintf("This subject was recently tested by %s. Wait %s before testing again.",
                BreathData[targetid][E_BREATH_LAST_TESTER], cdstr));
    }

    if (IsPlayerIncapacitated(targetid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "You can't administer a test to an incapacitated person.");

    BreathData[targetid][E_BREATH_BEING_TESTED] = true;
    BreathData[targetid][E_BREATH_TESTER]       = playerid;

    ApplyAnimation(playerid, BREATHALYZER_ANIM_LIB, BREATHALYZER_ANIM_NAME, 4.1, true, false, false, false, 0);
    ApplyAnimation(targetid, "PED", "IDLE_TIRED", 4.1, true, false, false, false, 0);

    ProxDetectorEx(playerid, 10.0, COLOR_ACTION, "*",
        sprintf("produces a breathalyzer and begins administering a drug test on %s.", ReturnRPName(targetid)),
        .annonated=true);

    SendServerMessage(targetid, COLOR_SERVER, "Breathalyzer", "A3A3A3",
        sprintf("%s is administering a breathalyzer test on you. Please remain still. (%ds)",
            ReturnRPName(playerid), BREATHALYZER_TEST_TIME));

    SendServerMessage(playerid, COLOR_SERVER, "Breathalyzer", "A3A3A3",
        sprintf("Administering breathalyzer test on %s. Please wait %d seconds...",
            ReturnRPName(targetid), BREATHALYZER_TEST_TIME));

    BreathData[targetid][E_BREATH_TIMER] = SetTimerEx("BreathalyzerTimer",
        BREATHALYZER_TEST_TIME * 1000, false, "ii", targetid, playerid);

    return true;
}

// /cancelbreathalyzer - cancels the test you started.
CMD:cancelbreathalyzer(playerid, params[])
{
    new targetid = INVALID_PLAYER_ID;
    foreach (new i: Player)
    {
        if (BreathData[i][E_BREATH_TESTER] == playerid && BreathData[i][E_BREATH_BEING_TESTED])
        {
            targetid = i;
            break;
        }
    }

    if (targetid == INVALID_PLAYER_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Breathalyzer", "A3A3A3", "You don't have an active breathalyzer test to cancel.");

    ProxDetectorEx(playerid, 10.0, COLOR_ACTION, "*",
        sprintf("lowers the breathalyzer and cancels the test on %s.", ReturnRPName(targetid)),
        .annonated=true);

    CancelBreathalyzerTest(targetid, playerid, "You cancelled the breathalyzer test.");
    return true;
}
