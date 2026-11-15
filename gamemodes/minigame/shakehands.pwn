// ============================================================================
// File: minigame/shakehands.pwn
// Handshake and greeting (/greet) plus the generic /accept command used to accept offers such
// as a handshake or a gun sale.
// Commands: /greet /accept
// ============================================================================

// Handshake script (CMD:accept and CMD:shakehands)
new PlayerShakeOffer [ MAX_PLAYERS ] ;
new PlayerShakeType [ MAX_PLAYERS ] ;

// /greet [player] [type] - greets a nearby player with a handshake or similar; they answer with
// /accept.
CMD:greet(playerid, params[])
{

    if (IsPlayerIncapacitated(playerid, false))
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;
    }

    new userid, type;

    if (sscanf(params, "k<player>d", userid, type))
    {

        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/greet [playerid, name] [type]");
        SendServerMessage(playerid, COLOR_ERROR, "Type", "A3A3A3", "{8a8a8a}1 | {A3A3A3}shake-a-lot, {8a8a8a}2 | {A3A3A3}shake n' bump, {8a8a8a}3 | {A3A3A3}double bump");
        return SendServerMessage(playerid, COLOR_ERROR, "Type", "A3A3A3", "{8a8a8a}4 | {A3A3A3}chest bump, {8a8a8a}5 | {A3A3A3}good ol' hug, {8a8a8a}6 | {A3A3A3}formal handshake");
    }

    if (!IsPlayerConnected(userid) || !IsPlayerNearPlayer(playerid, userid, 6.0))
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The specified player is disconnected or not near you.");
    }

    if (userid == playerid)
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't shake your own hand.");
    }

    if (type < 1 || type > 6)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Type can't be lower than 1, or higher than 6.");
    }

    PlayerShakeOffer [ userid ] = playerid;
    PlayerShakeType [ userid ] = type;

    SendServerMessage(userid, COLOR_INFO, "Handshake", "A3A3A3", sprintf("%s has offered to shake your hand (type \"/accept greet\")", ReturnSettingsName(playerid, userid)));
    SendServerMessage(playerid, COLOR_INFO, "Handshake", "A3A3A3", sprintf("You have offered to shake %s's hand.", ReturnSettingsName(userid, playerid)));

    return 1;
}

// /accept [what] - accepts an offer made to you (handshake, gun sale, trade, etc.).
CMD:accept(playerid, params[])
{

    if (IsPlayerIncapacitated(playerid, false))
    {

        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;
    }

    if (isnull(params))
    {
        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/accept [param]");
        SendClientMessage(playerid, COLOR_BLUE, "[PARAMS]:{DEDEDE} greet, cuffs, gun, frisk, tie, defend");
        return 1;
    }

    //OldLog ( playerid, "accept", sprintf("(%d) %s used /accept with PREFIX %s", playerid, ReturnPlayerNameData ( playerid ), params )) ;

    if (!strcmp(params, "greet", true) && PlayerShakeOffer [ playerid ] != INVALID_PLAYER_ID)
    {

        if (IsPlayerInAnyVehicle(playerid))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;
        }

        new targetid = PlayerShakeOffer [ playerid ], type = PlayerShakeType [ playerid ];

        if (!IsPlayerNearPlayer(playerid, targetid, 6.0))
        {

            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You are not near that player.");
        }

        SetPlayerToFacePlayer(targetid, playerid);
        SetPlayerToFacePlayer(playerid, targetid);

        PlayerShakeOffer [ playerid ] = INVALID_PLAYER_ID;
        PlayerShakeType [ playerid ] = 0;

        switch (type)
        {
            case 1:
            {
                ApplyAnimation(playerid, "GANGS", "hndshkaa", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "hndshkaa", 4.0, 0, 0, 0, 0, 0, 1);
            }
            case 2:
            {
                ApplyAnimation(playerid, "GANGS", "hndshkba", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "hndshkba", 4.0, 0, 0, 0, 0, 0, 1);
            }
            case 3:
            {
                ApplyAnimation(playerid, "GANGS", "hndshkda", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "hndshkda", 4.0, 0, 0, 0, 0, 0, 1);
            }
            case 4:
            {
                ApplyAnimation(playerid, "GANGS", "hndshkea", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "hndshkea", 4.0, 0, 0, 0, 0, 0, 1);
            }
            case 5:
            {
                ApplyAnimation(playerid, "GANGS", "hndshkfa", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "hndshkfa", 4.0, 0, 0, 0, 0, 0, 1);
            }
            case 6:
            {
                ApplyAnimation(playerid, "GANGS", "prtial_hndshk_biz_01", 4.0, 0, 0, 0, 0, 0, 1);
                ApplyAnimation(targetid, "GANGS", "prtial_hndshk_biz_01", 4.0, 0, 0, 0, 0, 0, 1);
            }
        }

        SendServerMessage(playerid, COLOR_INFO, "Handshake", "A3A3A3", sprintf("You have accepted %s's handshake.", ReturnSettingsName(targetid, playerid)));
        SendServerMessage(targetid, COLOR_INFO, "Handshake", "A3A3A3", sprintf("%s has accepted your handshake..", ReturnSettingsName(playerid, targetid)));
    }

    else if (!strcmp(params, "cuffs", true))
    {

        Police_OnPlayerCuffResponse(playerid) ;

        return 1;
    }

    else if (!strcmp(params, "tie", true))
    {

        Police_OnPlayerCuffResponse(playerid) ;

        return 1;
    }

    else if (!strcmp(params, "frisk", true))
    {

        Police_OnPlayerFriskResponse(playerid) ;

        return 1;
    }

    else if (!strcmp(params, "defend", true))
    {

        Lawyer_OnPlayerDefendResponse(playerid) ;

        return 1;
    }

    else if (!strcmp(params, "gun", true))
    {

        if (IsPlayerInAnyVehicle(playerid))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;
        }

        if (GetPVarInt(playerid, "GUNREQUEST") == 1)
        {

            // giver = player who offered gun, playerid = target
            new giver = GetPVarInt(playerid, "GUNREQUEST_TARGET") ;
            Weapon_PassGunResponse(giver, playerid);

            SetPVarInt(playerid, "GUNREQUEST", 0);
            SetPVarInt(playerid, "GUNREQUEST_TARGET", INVALID_PLAYER_ID);

            return 1;
        }
        return 1;
    }

    else if (!strcmp(params, "cigarette", true))
    {

        if (GetPVarInt(playerid, "CIGARETTEREQUEST") != 1)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a pending cigarette offer.");

        new giver  = GetPVarInt(playerid, "CIGARETTEREQUEST_FROM");
        new amount = GetPVarInt(playerid, "CIGARETTEREQUEST_AMOUNT");

        if (!IsPlayerConnected(giver))
        {
            SetPVarInt(playerid, "CIGARETTEREQUEST", 0);
            SetPVarInt(playerid, "CIGARETTEREQUEST_FROM", INVALID_PLAYER_ID);
            SetPVarInt(playerid, "CIGARETTEREQUEST_AMOUNT", 0);
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The offering player is no longer connected.");
        }

        if (!IsPlayerNearPlayer(playerid, giver, 5.0))
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're no longer near that player.");

        if (PlayerVar[giver][E_PLAYER_COMMISSARY_CIGS] < amount)
        {
            SetPVarInt(playerid, "CIGARETTEREQUEST", 0);
            SetPVarInt(playerid, "CIGARETTEREQUEST_FROM", INVALID_PLAYER_ID);
            SetPVarInt(playerid, "CIGARETTEREQUEST_AMOUNT", 0);
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The offering player no longer has enough cigarettes.");
        }

        PlayerVar[giver][E_PLAYER_COMMISSARY_CIGS]  -= amount;
        PlayerVar[playerid][E_PLAYER_COMMISSARY_CIGS] += amount;

        new cigquery[256];
        mysql_format(mysql, cigquery, sizeof(cigquery),
            "UPDATE characters SET player_commissary_cigs = %d WHERE player_id = %d",
            PlayerVar[giver][E_PLAYER_COMMISSARY_CIGS], Character[giver][E_CHARACTER_ID]);
        mysql_tquery(mysql, cigquery);

        mysql_format(mysql, cigquery, sizeof(cigquery),
            "UPDATE characters SET player_commissary_cigs = %d WHERE player_id = %d",
            PlayerVar[playerid][E_PLAYER_COMMISSARY_CIGS], Character[playerid][E_CHARACTER_ID]);
        mysql_tquery(mysql, cigquery);

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);
        ProxDetectorXYZ(px, py, pz, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid), 5.0, 0xA3A3A3FF,
                        sprintf("* %s slips %s %d %s.", ReturnRPName(giver), ReturnRPName(playerid), amount, amount == 1 ? "cigarette" : "cigarettes"));

        new giverMsg[128], receiverMsg[128];
        format(giverMsg,    sizeof(giverMsg),    "You passed %d %s to %s. You now have %d left.", amount, amount == 1 ? "cigarette" : "cigarettes", ReturnSettingsName(playerid, giver),    PlayerVar[giver][E_PLAYER_COMMISSARY_CIGS]);
        format(receiverMsg, sizeof(receiverMsg),  "%s passed you %d %s. You now have %d.", amount == 1 ? "cigarette" : "cigarettes", ReturnSettingsName(giver, playerid), amount, PlayerVar[playerid][E_PLAYER_COMMISSARY_CIGS]);

        SendServerMessage(giver,    COLOR_BLUE, "Commissary", "A3A3A3", giverMsg);
        SendServerMessage(playerid, COLOR_BLUE, "Commissary", "A3A3A3", receiverMsg);

        SetPVarInt(playerid, "CIGARETTEREQUEST", 0);
        SetPVarInt(playerid, "CIGARETTEREQUEST_FROM", INVALID_PLAYER_ID);
        SetPVarInt(playerid, "CIGARETTEREQUEST_AMOUNT", 0);

        return 1;
    }



    return true ;
}
