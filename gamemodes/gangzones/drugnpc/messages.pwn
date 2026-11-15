// ============================================================================
// File: gangzones/drugnpc/messages.pwn
// Random lines junkie NPCs say to nearby players.
// ============================================================================


new JunkieWeedMessages[][128] = {
    "~w~Yo, you got ~g~that green? ~w~The boys been asking...",
    "~w~Hey, we need some of that ~g~sticky icky ~w~tonight.",
    "~w~Psst... you holding? Got customers waiting for ~g~herb~w~.",
    "~w~Word is you got the ~g~best weed ~w~in the hood.",
    "~w~My people are dry, man. You got any fire ~g~kush?"
};

new JunkieCrackMessages[][128] = {
    "~w~The fiends been asking for ~b~~h~rocks ~w~all day...",
    "~w~Yo, you got any ~b~~h~hard~w~? Got steady customers.",
    "~w~Been getting calls all morning for some ~b~~h~good crack~w~.",
    "~w~My corner's been dry. ~w~You got any ~b~~h~rocks ~w~to move?",
    "~w~People desperate for ~b~~h~hard stuff~w~. You got what they need?"
};

new JunkieCocaineMessages[][128] = {
    "~w~High-end clientele asking for some ~y~pure white~w~...",
    "~w~You got any ~y~premium powder~w~? Rich customers waiting.",
    "~w~The uptown folks want ~y~quality blow~w~. You connected?",
    "~w~My VIP clients need ~y~clean cocaine~w~. You got the goods?",
    "~w~Getting requests for ~y~uncut white~w~. You dealing quality?"
};

// Picks a random line a junkie says depending on which drug they want.
GetRandomJunkieMessage(junkie_slot, output[], len) {
    if(JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND] > 0)
        format(output, len, "%s", JunkieWeedMessages[random(sizeof(JunkieWeedMessages))]);
    else if(JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND] > 0)
        format(output, len, "%s", JunkieCrackMessages[random(sizeof(JunkieCrackMessages))]);
    else if(JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND] > 0)
        format(output, len, "%s", JunkieCocaineMessages[random(sizeof(JunkieCocaineMessages))]);
    else
        format(output, len, "~w~Ain't looking for nothing right now.");
}


hook OnPlayerEnterDynamicArea(playerid, areaid) {
    for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
        if(!JunkieActor[i][E_JUNKIE_CREATED]) continue;
        if(JunkieActor[i][E_JUNKIE_AREA_ID] != areaid) continue;

        if(PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER]) {
            GameTextForPlayer(playerid, "~w~Press ~y~Y ~w~to interact", JUNKIE_INTERACT_HINT_TIME, 16);

            if(gettime() - PlayerLastJunkieMsg[playerid] >= JUNKIE_MSG_COOLDOWN) {
                new msg[128];
                GetRandomJunkieMessage(i, msg, sizeof(msg));
                GameTextForPlayer(playerid, msg, JUNKIE_MSG_DISPLAY_TIME, 17);
                PlayerLastJunkieMsg[playerid] = gettime();
            }
        } else {
            GameTextForPlayer(playerid,
                "~w~Stranger: I ain't here for you, keep walking...",
                JUNKIE_MSG_DISPLAY_TIME, 17);
        }

        return 1;
    }

    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        if(!StreetBossNPC[i][E_STREET_NPC_CREATED]) continue;
        if(StreetBossNPC[i][E_STREET_NPC_AREA] != areaid) continue;

        if(StreetBossNPC[i][E_STREET_NPC_OWNER] == Character[playerid][E_CHARACTER_ID])
            GameTextForPlayer(playerid, "~w~Press ~y~Y ~w~to manage your dealer", JUNKIE_INTERACT_HINT_TIME, 16);
        else
            GameTextForPlayer(playerid, "~w~Press ~y~Y ~w~to buy drugs", JUNKIE_INTERACT_HINT_TIME, 16);

        return 1;
    }

    return 1;
}

hook OnPlayerConnect(playerid) {
    PlayerLastJunkieMsg[playerid] = 0;
    return 1;
}
