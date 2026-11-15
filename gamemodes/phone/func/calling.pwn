// ============================================================================
// File: phone/func/calling.pwn
// Phone call logic: ringing, answering, timeouts, hanging up, static numbers (911 and other
// service numbers) and forwarding emergency calls to responders and Discord.
// ============================================================================


// Timer: connects a call once the other side has answered.
timer Phone_ConnectPlayer[1000](playerid, fromplayerid) {

    if (!IsPlayerConnected(playerid) || !IsPlayerConnected(fromplayerid) ||
        PlayerVar[playerid][E_PLAYER_PHONE_DECLINE_CALL]   ||
        PlayerVar[fromplayerid][E_PLAYER_PHONE_DECLINE_CALL])
    {
        if (IsPlayerConnected(playerid) && IsPlayerConnected(fromplayerid)) {
            if (PlayerVar[playerid][E_PLAYER_PHONE_DECLINE_CALL] ||
                PlayerVar[fromplayerid][E_PLAYER_PHONE_DECLINE_CALL])
            {
                // Explicit decline
                PhoneRecordDeclined(playerid, fromplayerid) ;
            }
            else {
                // Alert ticks ran out, missed call
                PhoneRecordMissed(playerid, fromplayerid) ;
            }
        }

        _Phone_ResetCallState(playerid) ;
        _Phone_ResetCallState(fromplayerid) ;

        SendServerMessage(playerid,    PHONE_COLOUR_BAD, "Phone", "A3A3A3", "The line died down.") ;
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "The line died down.") ;

        ApplyAnimation(fromplayerid, "PED", "phone_out", 4.1, 0, 0, 0, 0, 0) ;
        ApplyAnimation(playerid,     "PED", "phone_out", 4.1, 0, 0, 0, 0, 0) ;

        _Phone_HideConnectTextDraws(playerid, fromplayerid) ;

        return true ;
    }

    // both sides answered
    if (PlayerVar[playerid][E_PLAYER_PHONE_ACCEPT_CALL] &&
        PlayerVar[fromplayerid][E_PLAYER_PHONE_ACCEPT_CALL])
    {
        if (!PlayerVar[playerid][E_PLAYER_PHONE_HISTORY_RECORDED]) {
            PlayerVar[playerid][E_PLAYER_PHONE_HISTORY_RECORDED]    = true ;
            PlayerVar[fromplayerid][E_PLAYER_PHONE_HISTORY_RECORDED] = true ;
            PhoneRecordAnswered(playerid, fromplayerid) ;
        }
    }

    defer Phone_ConnectPlayer(playerid, fromplayerid) ;
    return true ;
}

// Resets a player's call state.
static _Phone_ResetCallState(playerid) {
    PlayerVar[playerid][player_phonecalling]             = INVALID_PLAYER_ID ;
    PlayerVar[playerid][E_PLAYER_PHONE_ACCEPT_CALL]      = false ;
    PlayerVar[playerid][E_PLAYER_PHONE_DECLINE_CALL]     = false ;
    PlayerVar[playerid][E_PLAYER_PHONE_ALERT_TICKS]      = 0 ;
    PlayerVar[playerid][E_PLAYER_PHONE_RINGTONE_TICK]    = 0 ;
    PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0) ;
    return true ;
}

// Hides the 'connecting' phone textdraws.
static _Phone_HideConnectTextDraws(playerid, fromplayerid) {

    PlayerTextDrawHide (fromplayerid, ptd_ph_design[playerid][9]) ;
    PlayerTextDrawColor(fromplayerid, ptd_ph_design[playerid][9], 0xFFFFFFFF) ;
    if (PlayerVar[fromplayerid][player_viewphone])
        PlayerTextDrawShow(fromplayerid, ptd_ph_design[playerid][9]) ;

    PlayerTextDrawHide (playerid, ptd_ph_design[playerid][9]) ;
    PlayerTextDrawColor(playerid,  ptd_ph_design[playerid][9], 0xFFFFFFFF) ;
    if (PlayerVar[playerid][player_viewphone])
        PlayerTextDrawShow(playerid, ptd_ph_design[playerid][9]) ;

    for (new i = 0, j = 3 ; i < j ; i++) {
        PlayerTextDrawHide(playerid,     ptd_ph_popup[playerid][i]) ;
        PlayerTextDrawHide(fromplayerid, ptd_ph_popup[playerid][i]) ;
    }
    return true ;
}

static const DispatcherNames[11][16] = {
    "Monica", "Jacqueline", "Janette", "Kaitlin", "Shenelle",
    "Brandi", "Rosalia",    "Carlos",  "Andrea",  "Jason", "Marcus"
} ;

// Starts a call to a static number (for example 911) and shows the call screen.
Phone_OnPlayerCallStaticNumber(playerid, number) {

    if (!PlayerVar[playerid][player_viewphone]) {
        for (new i = 5, j = 13 ; i < j ; i++)
            PlayerTextDrawShow(playerid, ptd_ph_design[playerid][i]) ;
        cmd_phone(playerid) ;
    }

    cmd_phanim(playerid) ;
    SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
        "To cancel animation, do /sa. To re-do it, use /ph(one)anim.") ;

    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = number ;

    PlayerTextDrawSetString(playerid, ptd_ph_popup[playerid][1], "Requesting Connection") ;
    PlayerTextDrawColor   (playerid, ptd_ph_popup[playerid][1], PHONE_COLOUR_OK) ;
    PlayerTextDrawSetString(playerid, ptd_ph_popup[playerid][2], sprintf("%d", number)) ;

    for (new i = 0, j = 3 ; i < j ; i++) {
        PlayerTextDrawHide(playerid, ptd_ph_popup[playerid][i]) ;
        PlayerTextDrawShow(playerid, ptd_ph_popup[playerid][i]) ;
    }

    switch (number) {
        case 726: {
            SendClientMessage(playerid, COLOR_YELLOW,
                "Secretary says (phone): San Andreas Network hotline, Karen speaking.  Can I take a message?") ;
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Type your message now.") ;
        }
        case 732: {
            SendClientMessage(playerid, COLOR_YELLOW,
                "Secretary says (phone): Federal agency hotline, Max speaking.  Can I take a message?") ;
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Type your message now.") ;
        }
        case 113: {
            SendClientMessage(playerid, COLOR_YELLOW,
                "Dispatcher says (phone): Kaufman Cabs, Jane speaking.  You need a ride?") ;
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Type your message now.") ;
        }
        case 311: {
            new dispatcher = random(sizeof(DispatcherNames)) ;
            SendClientMessage(playerid, COLOR_YELLOW,
                sprintf("Line Operator says (phone): 3-1-1 Non Emergency, %s speaking.  Which department is your call for?",
                    DispatcherNames[dispatcher])) ;
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Type \"Police\", \"Medical\".") ;
        }
        case 911: {
            new dispatcher = random(sizeof(DispatcherNames)) ;
            SendClientMessage(playerid, COLOR_YELLOW,
                sprintf("Line Operator says (phone): 9-1-1 Emergency, %s speaking.  Which emergency service do you require?",
                    DispatcherNames[dispatcher])) ;
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Type \"Police\", \"Medical\".") ;
        }
        case 666: {
            SendClientMessage(playerid, COLOR_YELLOW,
                "A voice says (phone): Hello, welcome to the contract service, how may I assist you?") ;
        }
        default: {
            SendClientMessage(playerid, COLOR_ERROR,
                "You've tried to dial a static number however it failed to connect.") ;
            for (new i = 0, j = 3 ; i < j ; i++)
                PlayerTextDrawHide(playerid, ptd_ph_popup[playerid][i]) ;
            PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
        }
    }

    return true ;
}

// Rings the other phone (alert tick loop) and shows the incoming call.
Phone_OnPlayerReceiveAlert(playerid, fromplayerid, type) {

    if (PlayerVar[playerid][E_PLAYER_INJUREDMODE]) {
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "You can't reach the recipient.") ;
        return true ;
    }

    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) {
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "You can't reach the recipient.") ;
        return true ;
    }

    if (PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL]) {
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "The number you're trying to call is currently occupied. Try again later.") ;
        return true ;
    }

    if (PlayerVar[playerid][player_phonecalling] != INVALID_PLAYER_ID) {
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "The number you're trying to call is currently occupied. Try again later.") ;
        return true ;
    }

    if (!PlayerVar[playerid][E_PLAYER_PHONE_STATUS] || !IsPlayerConnected(playerid)) {
        SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "You can't reach the recipient.") ;
        _Phone_ResetCallState(playerid) ;
        return true ;
    }

    _Phone_EnsureVisible(playerid) ;
    _Phone_EnsureVisible(fromplayerid) ;

    if (PlayerVar[playerid][E_PLAYER_PHONE_ALERT_TICKS] != 0) {
        switch (type) {
            case PHONE_ALERT_SMS: {
                PlayerTextDrawHide (playerid, ptd_ph_design[playerid][8]) ;
                PlayerTextDrawColor(playerid, ptd_ph_design[playerid][8], PHONE_COLOUR_MED) ;
                PlayerTextDrawShow (playerid, ptd_ph_design[playerid][8]) ;
                SendServerMessage(playerid, PHONE_COLOUR_MED, "Phone", "A3A3A3",
                    "You've received a text message whilst your phone was ringing.") ;
            }
            case PHONE_ALERT_CALL: {
                SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    "The number you're trying to call is currently occupied. Try again later.") ;
            }
        }
        return true ;
    }

    switch (type) {
        case PHONE_ALERT_SMS: {
            PlayerVar[playerid][E_PLAYER_PHONE_ALERT_TICKS] = 10 ;

            PlayerTextDrawSetString(playerid, ptd_ph_popup[playerid][1], "New Text Message") ;
            PlayerTextDrawColor   (playerid, ptd_ph_popup[playerid][1], PHONE_COLOUR_MED) ;
            PlayerTextDrawHide    (playerid, ptd_ph_design[playerid][8]) ;
            PlayerTextDrawColor   (playerid, ptd_ph_design[playerid][8], PHONE_COLOUR_MED) ;
            PlayerTextDrawShow    (playerid, ptd_ph_design[playerid][8]) ;

            PlayerTextDrawSetString(fromplayerid, ptd_ph_popup[playerid][1], "Text Message Sent") ;
            PlayerTextDrawColor   (fromplayerid,  ptd_ph_popup[playerid][1], PHONE_COLOUR_OK) ;
            PlayerTextDrawHide    (fromplayerid,  ptd_ph_design[playerid][8]) ;
            PlayerTextDrawColor   (fromplayerid,  ptd_ph_design[playerid][8], 0xFFFFFFFF) ;
            PlayerTextDrawShow    (fromplayerid,  ptd_ph_design[playerid][8]) ;
        }

        case PHONE_ALERT_CALL: {
			// reset the answered-flag so a fresh call starts clean.
            PlayerVar[playerid][E_PLAYER_PHONE_HISTORY_RECORDED]    = false ;
            PlayerVar[fromplayerid][E_PLAYER_PHONE_HISTORY_RECORDED] = false ;

            PlayerVar[playerid][E_PLAYER_PHONE_ALERT_TICKS] = 25 ;

            PlayerTextDrawSetString(playerid, ptd_ph_popup[playerid][1], "Incoming Call From") ;
            PlayerTextDrawColor   (playerid, ptd_ph_popup[playerid][1], PHONE_COLOUR_MED) ;
            PlayerTextDrawHide    (playerid, ptd_ph_design[playerid][9]) ;
            PlayerTextDrawColor   (playerid, ptd_ph_design[playerid][9], PHONE_COLOUR_MED) ;
            PlayerTextDrawShow    (playerid, ptd_ph_design[playerid][9]) ;

            cmd_phanim(fromplayerid) ;
            SendServerMessage(fromplayerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                "To cancel animation, do /sa. To re-do it, use /ph(one)anim.") ;

            PlayerTextDrawSetString(fromplayerid, ptd_ph_popup[playerid][1], "Requesting Connection") ;
            PlayerTextDrawColor   (fromplayerid,  ptd_ph_popup[playerid][1], PHONE_COLOUR_OK) ;
            PlayerTextDrawHide    (fromplayerid,  ptd_ph_design[playerid][9]) ;
            PlayerTextDrawColor   (fromplayerid,  ptd_ph_design[playerid][9], PHONE_COLOUR_MED) ;
            PlayerTextDrawShow    (fromplayerid,  ptd_ph_design[playerid][9]) ;
        }
    }

    defer Phone_FlashAlert(playerid, type, 0, fromplayerid) ;

    PlayerTextDrawSetString(playerid,    ptd_ph_popup[playerid][2],
        sprintf("%d", Character[fromplayerid][E_CHARACTER_PHONE_NUMBER])) ;
    PlayerTextDrawSetString(fromplayerid, ptd_ph_popup[playerid][2],
        sprintf("%d", Character[playerid][E_CHARACTER_PHONE_NUMBER])) ;

    for (new i = 0, j = 3 ; i < j ; i++) {
        PlayerTextDrawHide(playerid,    ptd_ph_popup[playerid][i]) ;
        PlayerTextDrawShow(playerid,    ptd_ph_popup[playerid][i]) ;
        PlayerTextDrawHide(fromplayerid, ptd_ph_popup[playerid][i]) ;
        PlayerTextDrawShow(fromplayerid, ptd_ph_popup[playerid][i]) ;
    }

    return true ;
}

// Makes sure the phone screen is shown during a call.
static _Phone_EnsureVisible(playerid) {
    if (!PlayerVar[playerid][player_viewphone]) {
        for (new i = 5, j = 13 ; i < j ; i++)
            PlayerTextDrawShow(playerid, ptd_ph_design[playerid][i]) ;
        cmd_phone(playerid) ;
    }
    return true ;
}

// Handles what a player says during a call: talking to a person or to the 911 operator
// (police/medical dispatch).
HandlePlayerPhoneCall(playerid, text[]) {

    new string[256], services[64] ;

    if (PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL]) {

        switch (PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL]) {

            case 311: {
                if (!strcmp(text, "Police", true) || !strcmp(text, "Police Department", true)) {
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY]   = 1 ;
                    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 312 ;
                }
                else if (!strcmp(text, "Medical", true) || !strcmp(text, "Medic", true) ||
                         !strcmp(text, "EMS",     true) || !strcmp(text, "Paramedics", true)) {
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY]   = 2 ;
                    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 312 ;
                }
                else if (!strcmp(text, "City Services", true) || !strcmp(text, "Government", true)) {
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY]   = 3 ;
                    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 312 ;
                }
                else {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Sorry, I don't understand.  Which department do you wish to contact?") ;
                    SendServerMessage(playerid, 0xE83A2BFF, "Phone", "A3A3A3", "Type \"Police\", \"Medical\".") ;
                    return 0 ;
                }

                text[0] = toupper(text[0]) ;
                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Line Operator says (phone): Thank you, please leave your message now.") ;
                return 0 ;
            }

            case 312: {
                if (strlen(text) < 4) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Sorry, I didn't hear you.  Please leave your message again.") ;
                    return 0 ;
                }

                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;

                new address[64], zone[64], Float:x, Float:y, Float:z ;
                GetPlayerPos(playerid, x, y, z) ;
                if (GetPlayerVirtualWorld(playerid) > 0) {
                    new property = Property_GetInside(playerid) ;
                    if (property != INVALID_PROPERTY_ID) {
                        x = Property[property][E_PROPERTY_EXT_X] ;
                        y = Property[property][E_PROPERTY_EXT_Y] ;
                        z = Property[property][E_PROPERTY_EXT_Z] ;
                    }
                }
                GetCoords2DZone(x, y, zone, sizeof(zone)) ;
                GetPlayerAddress(x, y, address) ;

                Server[E_SERVER_LAST_911_POS_X] = x ;
                Server[E_SERVER_LAST_911_POS_Y] = y ;
                Server[E_SERVER_LAST_911_POS_Z] = z ;
                Server[E_SERVER_LAST_911_TYPE]  = 0 ;

                format(string, sizeof(string), "[Message]: %s", text) ;

                new color = COLOR_FACTION ;
                if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) color = COLOR_FIRE ;

                foreach (new policeid: Player) {
                    if (Character[policeid][E_CHARACTER_FACTIONID]) {
                        new faction_enum_id = Faction_GetEnumID(Character[policeid][E_CHARACTER_FACTIONID]) ;
                        if (faction_enum_id != INVALID_FACTION_ID) {
                            // Police calls (type 1) go to law enforcement; medical
                            // calls (type 2) go to EMS, with law enforcement copied in.
                            if ((Faction_CanID(faction_enum_id, FAC_CAP_911)     && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1) ||
                                (Faction_CanID(faction_enum_id, FAC_CAP_MEDICAL) && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) ||
                                (Faction_CanID(faction_enum_id, FAC_CAP_911)     && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2))
                            {
                                SendClientMessage(policeid, color,
                                    sprintf("[311 Non-Emergency Call]: From: %d (Location: %s, %s)",
                                        Character[playerid][E_CHARACTER_PHONE_NUMBER], address, zone)) ;
                                ZMsg_SendClientMessage(policeid, color, string) ;
                                SendClientMessage(policeid, color,
                                    "To track this 311 call, type /lastalarm. (Puts GPS blip on map)") ;
                            }
                            else if (IsPlayerInGovFaction(policeid) &&
                                     PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 3)
                            {
                                SendClientMessage(policeid, color,
                                    sprintf("[311 Non-Emergency Call]: From: %d (Location: %s, %s)",
                                        Character[playerid][E_CHARACTER_PHONE_NUMBER], address, zone)) ;
                                ZMsg_SendClientMessage(policeid, color, string) ;
                            }
                        }
                    }
                }

                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Line Operator says (phone): Thank you.  Your chosen department has been notified of your call.") ;
                SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected.") ;
                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                cmd_phone(playerid) ;
                cmd_stopanim(playerid, "") ;
                return 0 ;
            }

            case 726: {
                if (strlen(text) < 4) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Secretary says (phone): Sorry, I didn't hear you.  Please leave your message again.") ;
                    return 0 ;
                }
                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;

                new address[64], zone[64], Float:x, Float:y, Float:z ;
                GetPlayerPos(playerid, x, y, z) ;
                if (GetPlayerVirtualWorld(playerid) > 0) {
                    new property = Property_GetInside(playerid) ;
                    if (property != INVALID_PROPERTY_ID) {
                        x = Property[property][E_PROPERTY_EXT_X] ;
                        y = Property[property][E_PROPERTY_EXT_Y] ;
                        z = Property[property][E_PROPERTY_EXT_Z] ;
                    }
                }
                GetCoords2DZone(x, y, zone, sizeof(zone)) ;
                GetPlayerAddress(x, y, address) ;
                new color = COLOR_FACTION ;

                foreach (new i: Player) {
                    if (IsPlayerInNewsFaction(i)) {
                        SendClientMessage(i, color,
                            sprintf("[Secretary Forwards SAN (7-2-6) Hotline Call]: From %d",
                                Character[playerid][E_CHARACTER_PHONE_NUMBER])) ;
                        SendClientMessage(i, color, sprintf("[Call Location]: %s, %s", address, zone)) ;
                        ZMsg_SendClientMessage(i, color, sprintf("[Message]: %s", text)) ;
                    }
                }

                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Secretary says (phone): Thank you, your message has been passed on to the news desk.") ;
                SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected.") ;
                cmd_phone(playerid) ;
                cmd_stopanim(playerid, "") ;
                return 0 ;
            }

            case 732: {
                if (strlen(text) < 4) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Secretary says (phone): Sorry, I didn't hear you.  Please leave your message again.") ;
                    return 0 ;
                }
                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;

                new address[64], zone[64], Float:x, Float:y, Float:z ;
                GetPlayerPos(playerid, x, y, z) ;
                if (GetPlayerVirtualWorld(playerid) > 0) {
                    new property = Property_GetInside(playerid) ;
                    if (property != INVALID_PROPERTY_ID) {
                        x = Property[property][E_PROPERTY_EXT_X] ;
                        y = Property[property][E_PROPERTY_EXT_Y] ;
                        z = Property[property][E_PROPERTY_EXT_Z] ;
                    }
                }
                GetCoords2DZone(x, y, zone, sizeof(zone)) ;
                GetPlayerAddress(x, y, address) ;
                new color = COLOR_FACTION ;

                foreach (new i: Player) {
                    if (IsPlayerInFederalFaction(i)) {
                        SendClientMessage(i, color,
                            sprintf("[Secretary Forwards Federal (7-3-2) Hotline Call]: From %d",
                                Character[playerid][E_CHARACTER_PHONE_NUMBER])) ;
                        SendClientMessage(i, color, sprintf("[Call Location]: %s, %s", address, zone)) ;
                        ZMsg_SendClientMessage(i, color, sprintf("[Message]: %s", text)) ;
                    }
                }

                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Secretary says (phone): Thank you, your message has been passed on to agency dispatch.") ;
                SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected.") ;
                cmd_phone(playerid) ;
                cmd_stopanim(playerid, "") ;

                format(string,   sizeof(string),   "**[Message]:** %s", text) ;
                format(services, sizeof(services),  "**[Services Requested]:** Federal Agency") ;
                new disMsg[512] ;
                format(disMsg, sizeof(disMsg),
                    "**[Caller Information]:** From %d\n**[Location]:** %s, %s\n%s\n%s",
                    Character[playerid][E_CHARACTER_PHONE_NUMBER], address, zone, services, string) ;
                return 0 ;
            }

            case 113: {
                if (strlen(text) < 4) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Dispatcher says (phone): Sorry, I didn't hear you.  Please leave your message again.") ;
                    return 0 ;
                }

                new bool:taxiAvailable = false ;
                foreach (new i: Player) {
                    if (Transit_IsOnService(i)) { taxiAvailable = true ; break ; }
                }
                if (!taxiAvailable) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Dispatcher says (phone): Sorry, there are no available transit drivers right now.") ;
                    return 0 ;
                }

                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;

                new address[64], zone[64], Float:x, Float:y, Float:z ;
                GetPlayerPos(playerid, x, y, z) ;
                if (GetPlayerVirtualWorld(playerid) > 0) {
                    new property = Property_GetInside(playerid) ;
                    if (property != INVALID_PROPERTY_ID) {
                        x = Property[property][E_PROPERTY_EXT_X] ;
                        y = Property[property][E_PROPERTY_EXT_Y] ;
                        z = Property[property][E_PROPERTY_EXT_Z] ;
                    }
                }
                GetCoords2DZone(x, y, zone, sizeof(zone)) ;
                GetPlayerAddress(x, y, address) ;
                new color = COLOR_FACTION ;

                foreach (new i: Player) {
                    if (Transit_IsOnService(i)) {
                        SendClientMessage(i, color,
                            sprintf("[Dispatcher Forwards Transit (1-1-3) Hotline Call]: From %d",
                                Character[playerid][E_CHARACTER_PHONE_NUMBER])) ;
                        SendClientMessage(i, color, sprintf("[Call Location]: %s, %s", address, zone)) ;
                        ZMsg_SendClientMessage(i, color, sprintf("[Message]: %s", text)) ;
                    }
                }

                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Dispatcher says (phone): Thank you, your request has been passed to a taxi driver.") ;
                SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected.") ;
                cmd_phone(playerid) ;
                cmd_stopanim(playerid, "") ;
                return 0 ;
            }

            case 911: {
                if (!strcmp(text, "Police", true)) {
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY]   = 1 ;
                    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 912 ;
                }
                else if (!strcmp(text, "Fire",    true) || !strcmp(text, "Medical",    true) ||
                         !strcmp(text, "EMS",     true) || !strcmp(text, "Medic",      true) ||
                         !strcmp(text, "Paramedics", true)) {
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY]   = 2 ;
                    PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 912 ;
                }
                else {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Sorry, I don't understand.  Which emergency service do you require?") ;
                    SendServerMessage(playerid, 0xE83A2BFF, "Phone", "A3A3A3", "Type \"Police\", \"Medical\".") ;
                    return 0 ;
                }

                text[0] = toupper(text[0]) ;
                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;
                SendClientMessage(playerid, COLOR_YELLOW,
                    "Line Operator says (phone): And, what is your emergency?") ;
                return 0 ;
            }

            /*case 666:
			{
				// HItman Hotline
				if (strlen(text) < 4)
				{
					SendClientMessage(playerid, COLOR_YELLOW, "Receptionist says (phone): Sorry, I didn't hear you.  Please leave your message again.");
					return 0;
				}

				format(string, sizeof(string), "says (phone): %s", text);
				ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string);

				new address [ 64 ], zone [ 64 ], Float: x, Float: y, Float: z  ;
				GetPlayerPos ( playerid, x, y, z ) ;
				
				if (GetPlayerVirtualWorld(playerid) > 0)
				{
					// They are probably in a property, so use the exterior of that if they are
					new property = Property_GetInside(playerid);
					if (property != INVALID_PROPERTY_ID)
					{
						x = Property [ property ] [ E_PROPERTY_EXT_X ]; 
						y = Property [ property ] [ E_PROPERTY_EXT_Y ]; 
						z = Property [ property ] [ E_PROPERTY_EXT_Z ];
					}
				}

				GetCoords2DZone(x, y, zone, sizeof ( zone ));
				GetPlayerAddress(x, y, address );
				new color = COLOR_FACTION;

				foreach(new i: Player) 
				{
					if ( IsPlayerHitman ( i ) ) {
						SendClientMessage(i, color, sprintf("[Receptionist Forwards Contract Service (6-6-6) Hotline Call]: From %d", Character [ playerid ] [ E_CHARACTER_PHONE_NUMBER ] ) ) ;
						SendClientMessage(i, color, sprintf("[Call Location]: %s, %s", address, zone ) ) ;
						ZMsg_SendClientMessage(i, color, sprintf("[Message]: %s", text ) ) ;
					}
				}

				Phone_HideCallTextDraws(playerid);
				PlayerVar [ playerid ] [ E_PLAYER_PHONE_STATIC_CALL ] = 0 ;

				SendClientMessage(playerid, COLOR_YELLOW, "Receptionist says (phone): Thank you, your reservation has been booked.");
				SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected." );
				
				cmd_phone(playerid);
				cmd_stopanim(playerid, "");

				return 0;
			}*/

            case 912: {
                if (strlen(text) < 4) {
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Sorry, I didn't hear you.  What is your emergency?") ;
                    return 0 ;
                }

                format(string, sizeof(string), "says (phone): %s", text) ;
                ProxDetectorEx(playerid, (GetPlayerVirtualWorld(playerid) == 0 ? 15.0 : 10.0), 0xDEDEDEFF, "", string) ;

                new address[64], zone[64], city[64], Float:x, Float:y, Float:z ;
                GetPlayerPos(playerid, x, y, z) ;
                if (GetPlayerVirtualWorld(playerid) > 0) {
                    new property = Property_GetInside(playerid) ;
                    if (property != INVALID_PROPERTY_ID) {
                        x = Property[property][E_PROPERTY_EXT_X] ;
                        y = Property[property][E_PROPERTY_EXT_Y] ;
                        z = Property[property][E_PROPERTY_EXT_Z] ;
                    }
                }
                GetCoords2DZone(x,     y, zone, sizeof(zone)) ;
                GetPlayerAddress(x,    y, address) ;
                GetCoords2DMainZone(x, y, city, sizeof(city)) ;

                Server[E_SERVER_LAST_911_POS_X] = x ;
                Server[E_SERVER_LAST_911_POS_Y] = y ;
                Server[E_SERVER_LAST_911_POS_Z] = z ;
                Server[E_SERVER_LAST_911_TYPE]  = 0 ;

                format(string,   sizeof(string),   "[Emergency]: %s", text) ;
                format(services, sizeof(services),  "[Services Requested]: %s",
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1 ? "Police" :
                    PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2 ? "Medical" : "Unknown") ;

                new color = COLOR_FACTION ;
                if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) color = COLOR_FIRE ;

                foreach (new policeid: Player) {
                    if (Character[policeid][E_CHARACTER_FACTIONID]) {
                        new faction_enum_id = Faction_GetEnumID(Character[policeid][E_CHARACTER_FACTIONID]) ;
                        if (faction_enum_id != INVALID_FACTION_ID) {
                            // Police calls (type 1) reach law enforcement; medical
                            // calls (type 2) reach EMS, with law enforcement copied in.
                            if ((Faction_Can(policeid, FAC_CAP_911)     && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1) ||
                                (Faction_Can(policeid, FAC_CAP_MEDICAL) && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) ||
                                (Faction_Can(policeid, FAC_CAP_911)     && PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2))
                            {
                                SendClientMessage(policeid, color,
                                    sprintf("[Dispatch Forwards 911 Call]: From %d",
                                        Character[playerid][E_CHARACTER_PHONE_NUMBER])) ;
                                SendClientMessage(policeid, color,
                                    sprintf("[Location]: %s, %s", address, zone)) ;
                                ZMsg_SendClientMessage(policeid, color, services) ;
                                ZMsg_SendClientMessage(policeid, color, string) ;
                                SendClientMessage(policeid, color,
                                    "To track this 911 call, type /lastalarm. (Puts GPS blip on map)") ;
                            }
                        }
                    }
                }

                if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1) {
                    format(string,   sizeof(string),   "**[Emergency]:** %s", text) ;
                    format(services, sizeof(services),  "**[Services Requested]:** Police") ;
                    new disMsg[512] ;
                    format(disMsg, sizeof(disMsg),
                        "**[Dispatch Forwards 911 Call]:** From %d\n**[Location]:** %s, %s, %s\n%s\n%s",
                        Character[playerid][E_CHARACTER_PHONE_NUMBER], address, zone, city, services, string) ;
                    DCC_Send911PoliceMessage(disMsg) ;
                    Log911Call(playerid, 1, text, x, y, z, address, zone, city) ;
                }
                else if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) {
                    format(string,   sizeof(string),   "**[Emergency]:** %s", text) ;
                    format(services, sizeof(services),  "**[Services Requested]:** Medical") ;
                    new disMsg[512] ;
                    format(disMsg, sizeof(disMsg),
                        "**[Dispatch Forwards 911 Call]:** From %d\n**[Location]:** %s, %s, %s\n%s\n%s",
                        Character[playerid][E_CHARACTER_PHONE_NUMBER], address, zone, city, services, string) ;
                    DCC_Send911MedicMessage(disMsg) ;
                    Log911Call(playerid, 2, text, x, y, z, address, zone, city) ;
                }

                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;

                if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1)
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Thank you, the police have been notified of your location.") ;
                else
                    SendClientMessage(playerid, COLOR_YELLOW,
                        "Line Operator says (phone): Thank you, the fire and medical services have been notified of your location.") ;

                SendClientMessage(playerid, COLOR_ACTION, "** The line has been disconnected.") ;
                Phone_HideCallTextDraws(playerid) ;
                PlayerVar[playerid][E_PLAYER_PHONE_STATIC_CALL] = 0 ;
                cmd_phone(playerid) ;
                cmd_stopanim(playerid, "") ;
                return 0 ;
            }
        }
    }
    return 1 ;
}
