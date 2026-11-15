// ============================================================================
// File: drugs/player/use.pwn
// Using drugs: /druguse, /blunt, effects over time (PlayerDrug_EffectTick), addiction and
// withdrawal (Addiction_OnPlayerUse, Addiction_Decay) and /checkaddiction.
// Commands: /blunt /druguse /usedrug /stopdrugeffect /checkaddiction
// ============================================================================

forward Float:GetDrugAddiction(playerid, type);

static methCrashEnd[MAX_PLAYERS];

#define WITHDRAWAL_WINDOW_WEED      (3600 * 6)
#define WITHDRAWAL_WINDOW_COKE      (3600 * 4)
#define WITHDRAWAL_WINDOW_CRACK     (3600 * 2)
#define WITHDRAWAL_WINDOW_METH      (3600 * 5)

static withdrawalWindow[4] = {
    WITHDRAWAL_WINDOW_WEED,
    WITHDRAWAL_WINDOW_COKE,
    WITHDRAWAL_WINDOW_CRACK,
    WITHDRAWAL_WINDOW_METH
};

// Called periodically: applies withdrawal symptoms when an addicted player hasn't used a drug for
// a while.
PlayerDrug_WithdrawalTick(playerid)
{
    if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] > 0) return true;

    new now = gettime();
    new lastUse   = Character[playerid][E_CHARACTER_LAST_DRUG_USE];
    new timeSince = now - lastUse;

    new bool: anyWithdrawal = false;

    new bool: canMsg  = (Character[playerid][E_CHARACTER_WITHDRAWAL_MSG_CD] < now);
    new bool: canDrain = (Character[playerid][E_CHARACTER_WITHDRAWAL_HP_CD] < now);

    // Meth crash: cap HP and send periodic messages until crash window expires
    if (methCrashEnd[playerid] > 0)
    {
        if (methCrashEnd[playerid] > now)
        {
            new Float:hp = GetCharacterHealth(playerid);
            if (hp > E_METH_CRASH_HP_CAP)
                SetCharacterHealth(playerid, E_METH_CRASH_HP_CAP);

            if (canMsg)
            {
                new crashMsgs[3][] = {
                    "Your body is completely wrecked. The crash is brutal.",
                    "You feel hollow and drained of everything the meth gave you.",
                    "Your hands are shaking. Everything aches. The crash is real."
                };
                SendServerMessage(playerid, COLOR_DRUGS, "Crash", "A3A3A3", crashMsgs[random(3)]);
                Character[playerid][E_CHARACTER_WITHDRAWAL_MSG_CD] = now + 120;
            }

            anyWithdrawal = true;
            Character[playerid][E_CHARACTER_IN_WITHDRAWAL] = true;
        }
        else
        {
            methCrashEnd[playerid] = 0;
            SendServerMessage(playerid, COLOR_DRUGS, "Recovery", "A3A3A3", "The crash has passed. You slowly start to feel like yourself again.");
        }
    }

    for (new t = 0; t < 4; t++)
    {
        new Float: addiction = GetDrugAddiction(playerid, t);

        if (addiction < 30.0) continue;
        if (timeSince < withdrawalWindow[t]) continue;

        anyWithdrawal = true;
        Character[playerid][E_CHARACTER_IN_WITHDRAWAL] = true;

        new severity = 1;
        if      (addiction >= 80.0) severity = 3;
        else if (addiction >= 60.0) severity = 2;

        switch (t)
        {
            case E_DRUG_TYPE_WEED:
            {
                if (canMsg)
                {
                    new msgs[3][] = {
                        "You feel irritable and can't focus. You could really use a blunt.",
                        "Your appetite is all over the place. You feel restless.",
                        "You're snapping at everyone around you. A blunt would fix this."
                    };
                    SendServerMessage(playerid, COLOR_DRUGS, "Withdrawal", "A3A3A3", msgs[random(3)]);
                    Character[playerid][E_CHARACTER_WITHDRAWAL_MSG_CD] = now + 120; // message every 2 min
                }
            }

            case E_DRUG_TYPE_COKE:
            {
                if (canDrain)
                {
                    new Float: hp = GetCharacterHealth(playerid);
                    new Float: drain = float(severity) * 1.5; // mild=1.5, moderate=3.0, severe=4.5 per drain tick

                    if (hp > 25.0)
                        SetCharacterHealth(playerid, hp - drain);

                    if (severity >= 2)
                        SetPlayerDrunkLevel(playerid, 200 * severity);

                    Character[playerid][E_CHARACTER_WITHDRAWAL_HP_CD] = now + 120; // drain every 2 min
                }

                if (canMsg)
                {
                    new msgs[3][] = {
                        "Your nose is burning and your hands won't stop trembling.",
                        "You feel a creeping numbness. Your body craves the powder.",
                        "Cold sweat runs down your neck. You need another line."
                    };
                    SendServerMessage(playerid, COLOR_DRUGS, "Withdrawal", "A3A3A3", msgs[random(3)]);
                    Character[playerid][E_CHARACTER_WITHDRAWAL_MSG_CD] = now + 90; // message every 90 sec
                }
            }

            case E_DRUG_TYPE_CRACK:
            {
                if (canDrain)
                {
                    new Float: hp = GetCharacterHealth(playerid);
                    new Float: drain = (severity == 3) ? 6.0 : float(severity) * 2.0; // mild=2, moderate=4, severe=6

                    if (hp > 15.0)
                        SetCharacterHealth(playerid, hp - drain);

                    if (severity >= 2)
                        SetPlayerDrunkLevel(playerid, 500 * severity);

                    if (severity == 3)
                    {
                        new Float: armour = GetCharacterArmour(playerid);
                        if (armour > 0.0)
                            SetCharacterArmour(playerid, (armour - 2.0 < 0.0) ? 0.0 : (armour - 2.0));
                    }

                    Character[playerid][E_CHARACTER_WITHDRAWAL_HP_CD] = now + 60; // crack drains faster, every 1 min
                }

                if (canMsg)
                {
                    if (severity == 3 && random(100) < 30)
                    {
                        ApplyAnimation(playerid, "PED", "WALK_DRUNK", 4.0, false, false, false, false, 2000);
                        SendServerMessage(playerid, COLOR_DRUGS, "Withdrawal", "A3A3A3", "Your legs give out. Your body is completely falling apart without a hit.");
                    }
                    else
                    {
                        new msgs[3][] = {
                            "Your body is screaming for a hit. Every muscle aches.",
                            "You're sweating through your clothes. The craving is unbearable.",
                            "Nausea hits you like a freight train. You need crack. Now."
                        };
                        SendServerMessage(playerid, COLOR_DRUGS, "Withdrawal", "A3A3A3", msgs[random(3)]);
                    }
                    Character[playerid][E_CHARACTER_WITHDRAWAL_MSG_CD] = now + 90;
                }
            }

            case E_DRUG_TYPE_METH: {}
        }
    }

    if (!anyWithdrawal && Character[playerid][E_CHARACTER_IN_WITHDRAWAL])
        Character[playerid][E_CHARACTER_IN_WITHDRAWAL] = false;

    return true;
}

// Applies the effects of a drug a player has just used (health, armour, drunk level, addiction).
Drugs_OnPlayerUse(playerid, type, param, Float: amount)
{
	new drug_name[32], drug_type[32];
	Drugs_GetParamName(type, param, drug_name);
	Drugs_GetTypeName(type, drug_type);

	AddLogEntry(playerid, LOG_TYPE_DRUGS, sprintf("Has used %0.2fgr of %s (%s).",
		amount, drug_type, drug_name)
	);

	switch (type)
	{
		case E_DRUG_TYPE_WEED:
		{
			SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "DEDEDE", "To smoke weed, use /blunt. Use F to cancel and save the blunt for later.");

			new ticks = floatround(Weed[param][E_WEED_TICKS] / amount);

			if (ticks > 500) {
				ticks = ticks / 2;
			}

			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = ticks;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = param;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = type;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_CD]     = 0;
		}

		case E_DRUG_TYPE_COKE:
		{
			new ticks = floatround(Cocaine[param][E_COKE_TICKS] / amount);

			if (ticks > 500) {
				ticks = ticks / 2;
			}

			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = ticks;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = param;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = type;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = false;
		}

		case E_DRUG_TYPE_CRACK:
		{
			new ticks = floatround(Crack[param][E_CRACK_TICKS] / amount);

			if (ticks > 500) {
				ticks = ticks / 2;
			}

			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = ticks;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = param;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = type;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = false;
		}

		case E_DRUG_TYPE_METH:
		{
			new ticks = floatround(Meth[param][E_METH_TICKS] / amount);

			if (ticks > 500) {
				ticks = ticks / 2;
			}

			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = ticks;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = param;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = type;
			Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = false;
		}
	}

	Character[playerid][E_CHARACTER_LAST_DRUG_USE] = gettime();

	Addiction_OnPlayerUse(playerid, type, amount);

	new query[512];
	mysql_format(mysql, query, sizeof(query),
		"UPDATE characters SET \
			player_drug_effect_ticks = %d, \
			player_drug_effect_active = %d, \
			player_drug_effect_param = %d, \
			player_drug_effect_type = %d, \
			player_last_drug_use = %d \
		WHERE player_id = %d",
		Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE],
		Character[playerid][E_CHARACTER_LAST_DRUG_USE],
		Character[playerid][E_CHARACTER_ID]
	);

	mysql_tquery(mysql, query);

	return true;
}

// /blunt - smokes from the active drug effect (cannabis) for a short boost.
CMD:blunt(playerid, params[])
{
	if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "You've got no active drug.");
	}

	new type = Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE];

	if (type == E_DRUG_TYPE_WEED)
	{
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_SMOKE_CIGGY);
		SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "You've lit up a fat blunt. Smoke some weed.");
	}

	return true;
}

// Ends the current drug effect when its time is up and restores the player to normal.
ResetPlayerDrugEffectTick(playerid)
{
	if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0)
	{
		SetPlayerDrunkLevel(playerid, 0);

		if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true))
		{
			// Don't reset armor for on duty cops/security
			SetCharacterArmour(playerid, 0.0);
		}

		new bool:methCrash = false;
		if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE] == E_DRUG_TYPE_METH && Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
		{
			new crashParam = Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM];
			methCrashEnd[playerid] = gettime() + Meth[crashParam][E_METH_CRASH_DURATION];
			methCrash = true;
		}

		Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = 0;
		Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = 0;
		Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = -1;
		Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = false;
		Character[playerid][E_CHARACTER_DRUG_EFFECT_CD]     = 0;

		new query[512];

		mysql_format(mysql, query, sizeof(query),
			"UPDATE characters SET \
				player_drug_effect_ticks = %d, \
				player_drug_effect_active = %d, \
				player_drug_effect_param = %d, \
				player_drug_effect_type = %d \
			WHERE player_id = %d",
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS],
			Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE],
			Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM],
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE],
			Character[playerid][E_CHARACTER_ID]
		);

		mysql_tquery(mysql, query);

		if (methCrash)
			SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "The meth wears off. A heavy crash is setting in...");
		else
			SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "You feel the effects of the drug you used waning away.");

		return true;
	}

	return true;
}

// Repeating tick while a drug is active: drains the effect timer and applies visual and health
// effects.
PlayerDrug_EffectTick(playerid)
{
	new param = Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM];
	new type  = Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE];

	#pragma unused param

	switch (type)
	{
		case E_DRUG_TYPE_WEED:
		{
			if (Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE]) {
				//SetPlayerDrunkLevel(playerid, 2000 + Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]);
			}

			if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] &&
				GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_SMOKE_CIGGY)
			{
				Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]--;

				if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0)
				{
					ResetPlayerDrugEffectTick(playerid);
					return true;
				}

				if (random(350) < 80)
				{
					// If cooldown is active, don't heal.
					if (Character[playerid][E_CHARACTER_DRUG_EFFECT_CD])
					{
						Character[playerid][E_CHARACTER_DRUG_EFFECT_CD]--;
						return true;
					}

					new Float: health = GetCharacterHealth(playerid);

					health += Weed[param][E_WEED_HEALING];

					if (health >= 100.0) {
						SetCharacterHealth(playerid, 100.0);
					}
					else {
						SetCharacterHealth(playerid, health);
					}

					Character[playerid][E_CHARACTER_DRUG_EFFECT_CD] = 3;

					SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "You feel rejuvenated after hitting the blunt.");
				}
			}
		}

		case E_DRUG_TYPE_CRACK:
		{
			if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS])
			{
				if (!Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
				{
					Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = true;

					new Float: armour = GetCharacterArmour(playerid);
					new Float: amount = Crack[param][E_CRACK_ARMOUR];

					armour += amount;
					if (armour >= 100.0) {
						armour = 100.0;
					}

					SetCharacterArmour(playerid, armour);
					SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "You feel unstoppable after smoking the crack rocks.");
					new query[512];
					mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_drug_effect_active = 1 WHERE player_id = %d", Character[playerid][E_CHARACTER_ID]);
					mysql_tquery(mysql, query);
				}

				new totalTicks = Crack[param][E_CRACK_TICKS];
				new Float: totalLoss = Crack[param][E_CRACK_HP_LOSS];
				new ticksRemaining = Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS];

				new Float: ticksElapsed = float(totalTicks - ticksRemaining);
				// new Float: expectedDrained = (ticksElapsed / float(totalTicks)) * totalLoss;
				// new Float: actualDrained = totalLoss - (totalLoss * (float(ticksRemaining) / float(totalTicks)));

				// #pragma unused actualDrained
				// #pragma unused expectedDrained

				// drain 1 HP at evenly spaced intervals
				new drainInterval = floatround(float(totalTicks) / totalLoss);

				if (drainInterval > 0 && (totalTicks - ticksRemaining) % drainInterval == 0 && ticksElapsed > 0.0)
				{
					new Float: health = GetCharacterHealth(playerid);

					if (health > 1.0)
					{
						SetCharacterHealth(playerid, health - 1.0);
					}
				}


				Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]--;

				if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0)
				{
					ResetPlayerDrugEffectTick(playerid);
					return true;
				}
			}
		}

		case E_DRUG_TYPE_COKE:
		{
			if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS])
			{
				if (!Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
				{
					Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = true;
					SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "Your heart pounds. You feel an intense rush of confidence and aggression.");
					new query[512];
					mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_drug_effect_active = 1 WHERE player_id = %d", Character[playerid][E_CHARACTER_ID]);
					mysql_tquery(mysql, query);
				}

				Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]--;

				if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0)
				{
					ResetPlayerDrugEffectTick(playerid);
					return true;
				}
			}
		}

		case E_DRUG_TYPE_METH:
		{
			if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS])
			{
				if (!Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE])
				{
					Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = true;
					SendServerMessage(playerid, COLOR_DRUGS, "Drug Effect", "A3A3A3", "Your senses sharpen. You feel fast, focused, and almost invincible.");
					new query[512];
					mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_drug_effect_active = 1 WHERE player_id = %d", Character[playerid][E_CHARACTER_ID]);
					mysql_tquery(mysql, query);
				}

				new totalTicks = Meth[param][E_METH_TICKS];
				new elapsed    = totalTicks - Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS];
				new interval   = Meth[param][E_METH_REGEN_INTERVAL];

				if (interval > 0 && elapsed > 0 && elapsed % interval == 0)
				{
					new Float:hp = GetCharacterHealth(playerid);
					if (hp < 100.0)
						SetCharacterHealth(playerid, (hp + 1.0 > 100.0) ? 100.0 : hp + 1.0);
				}

				Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]--;

				if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] <= 0)
				{
					ResetPlayerDrugEffectTick(playerid);
					return true;
				}
			}
		}
	}

	return true;
}

CMD:druguse(playerid, params[]) {
	return cmd_usedrug(playerid, params);
}

// /usedrug [slot] [amount] - uses a drug from your inventory.
CMD:usedrug(playerid, params[])
{
	new slot, Float: amount;

	if (sscanf(params, "if", slot, amount)) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "/usedrug [slot] [amount]");
	}

	if (slot < 0 || slot >= MAX_PLAYER_DRUGS) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("Slot can't be less than 0 or higher than %d", MAX_PLAYER_DRUGS));
	}

	if (amount < 0.5) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can't use less than 0.5 grams.");
	}

	if (amount > 1.0) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can't take more than one gram - you might die!");
	}

	if (PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT] < amount) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("You don't have that much of this drug - you only have %0.2f.", PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT]));
	}

	new type = PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE];

	if (type == E_DRUG_TYPE_NONE) {
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "This slot has no valid drug in it.");
	}

	if (Character[playerid][E_CHARACTER_RECENT_DAMAGE] > gettime()) {
		new cdStr[16];
		FormatCooldownTime(Character[playerid][E_CHARACTER_RECENT_DAMAGE] - gettime(), cdStr, sizeof(cdStr));
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3",sprintf("You've recently been in a fight. You can't use drugs for another %s.", cdStr));
	}

	if (Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS])
	{
		SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("You already have a drug effect active. Wait for it to pass! (%d ticks left).",
			Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]
		));
		SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "If your current drug is weed, you MUST consume it via /blunt to make the effect pass.");
		SendClientMessage(playerid, 0xA3A3A3FF, "Alternatively you can use /stopdrugeffect which will reset your used drug. This will NOT refund the amount used.");

		return true;
	}

	new drug_name[32], drug_type[32], package_name[32];

	Drugs_GetParamName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE], PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM], drug_name);
	Drugs_GetPackageName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_CONTAINER], package_name);
	Drugs_GetTypeName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE], drug_type);

	Drugs_OnPlayerUse(playerid, PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE], PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM], amount);

	switch (PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE])
	{
		case E_DRUG_TYPE_WEED, E_DRUG_TYPE_CRACK:
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("withdraws %0.2f of %s from a %s and smokes it.", amount, drug_name, package_name), .annonated=true);
		case E_DRUG_TYPE_COKE:
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("withdraws %0.2f of %s from a %s and snorts it.", amount, drug_name, package_name), .annonated=true);
		case E_DRUG_TYPE_METH:
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("withdraws %0.2f of %s from a %s and smokes it.", amount, drug_name, package_name), .annonated=true);
	}

	PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT] -= amount;
	PlayerDrugs_Save(playerid);

	if (PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT] <= 0.01)
	{
		PlayerDrugs[playerid][slot][E_PLAYER_DRUG_SQLID]    = -1;
		PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE]     = 0;
		PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM]    = 0;
		PlayerDrugs[playerid][slot][E_PLAYER_DRUG_CONTAINER] = 0;
		PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT]   = 0.0;

		SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You've used the very last grams of your drug. Your batch has ran out.");
		PlayerDrugs_Save(playerid);
	}

	return true;
}

// /stopdrugeffect - ends the active drug effect early.
CMD:stopdrugeffect(playerid, params[])
{
	if (!Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS] && Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE] == -1)
    	return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You have no active drug effect.");

	SetPlayerDrunkLevel(playerid, 0);
	SetCharacterArmour(playerid, 0.0);

	Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS]  = 0;
	Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM]  = 0;
	Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE]   = -1;
	Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE] = false;
	Character[playerid][E_CHARACTER_DRUG_EFFECT_CD]     = 0;

	SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You've cancelled your drug effect. Your used grams are not refunded.");

	new query[512];

	mysql_format(mysql, query, sizeof(query),
		"UPDATE characters SET \
			player_drug_effect_ticks = %d, \
			player_drug_effect_active = %d, \
			player_drug_effect_param = %d, \
			player_drug_effect_type = %d \
		WHERE player_id = %d",
		Character[playerid][E_CHARACTER_DRUG_EFFECT_TICKS],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_ACTIVE],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_PARAM],
		Character[playerid][E_CHARACTER_DRUG_EFFECT_TYPE],
		Character[playerid][E_CHARACTER_ID]
	);

	mysql_tquery(mysql, query);

	AddLogEntry(playerid, LOG_TYPE_DRUGS, sprintf("Has cancelled their drug effect."));

	return true;
}

static Float: decayRate[4] = {
    4.0,    // weed  - fades fastest
    2.0,    // coke
    0.8,    // crack - very sticky, barely decays
    1.5     // meth
};

// Slowly reduces a player's addiction levels over time.
Addiction_Decay(playerid)
{
    new now  = gettime();
    new last = Character[playerid][E_CHARACTER_LASTADDICTION_DECAY];

    if (last == 0)
    {
        Character[playerid][E_CHARACTER_LASTADDICTION_DECAY] = now;
        SaveDrugAddiction(playerid);
        return true;
    }

    new Float: hoursPassed = float(now - last) / 3600.0;

    // cap to 72 hours to avoid huge offline decay jumps
    if (hoursPassed > 72.0) hoursPassed = 72.0;

    for (new t = 0; t < 4; t++)
    {
        new Float: val = GetDrugAddiction(playerid, t);
        if (val <= 0.0) continue;

        val -= decayRate[t] * hoursPassed;
        SetDrugAddiction(playerid, t, val);
    }

    Character[playerid][E_CHARACTER_LASTADDICTION_DECAY] = now;
    SaveDrugAddiction(playerid);
    return true;
}

// Saves the player's addiction levels to the database.
SaveDrugAddiction(playerid)
{
    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET \
            player_addiction_weed = %f, \
            player_addiction_coke = %f, \
            player_addiction_crack = %f, \
            player_addiction_meth = %f, \
            player_last_addiction_decay = %d \
        WHERE player_id = %d",
        Character[playerid][E_CHARACTER_ADDICTION_WEED],
        Character[playerid][E_CHARACTER_ADDICTION_COKE],
        Character[playerid][E_CHARACTER_ADDICTION_CRACK],
        Character[playerid][E_CHARACTER_ADDICTION_METH],
        Character[playerid][E_CHARACTER_LASTADDICTION_DECAY],
        Character[playerid][E_CHARACTER_ID]
    );

    mysql_tquery(mysql, query);
    return true;
}

// Returns the Character field that stores addiction for a drug type, or -1.
stock GetDrugAddictionField(type)
{
    switch (type)
    {
        case E_DRUG_TYPE_WEED:  return E_CHARACTER_ADDICTION_WEED;
        case E_DRUG_TYPE_COKE:  return E_CHARACTER_ADDICTION_COKE;
        case E_DRUG_TYPE_CRACK: return E_CHARACTER_ADDICTION_CRACK;
        case E_DRUG_TYPE_METH:  return E_CHARACTER_ADDICTION_METH;
    }
    return -1;
}

// Returns the player's addiction level (0-100) for a drug type.
Float: GetDrugAddiction(playerid, type)
{
    new field = GetDrugAddictionField(type);
    if (field == -1) return 0.0;
    return Float:Character[playerid][E_CHARACTER_DATA:field];
}

// Sets the player's addiction level for a drug type (clamped to 0-100).
SetDrugAddiction(playerid, type, Float:value)
{
    new field = GetDrugAddictionField(type);
    if (field == -1) return;

    if (value < 0.0) value = 0.0;
    if (value > 100.0) value = 100.0;

    Character[playerid][E_CHARACTER_DATA:field] = _:value;
}

// Writes a text label (None, Mild, Moderate, Severe) for an addiction level.
stock GetDrugAddictionLabel(Float:level, label[], len)
{
    if      (level < 30.0)  strcat(label, "None",     len);
    else if (level < 60.0)  strcat(label, "Mild",     len);
    else if (level < 80.0)  strcat(label, "Moderate", len);
    else                    strcat(label, "Severe",   len);
}

// Raises the player's addiction when they use a drug.
Addiction_OnPlayerUse(playerid, type, Float:amount)
{
    static Float: addictionRate[4] = {
        2.5,    // weed
        8.0,    // coke
        15.0,   // crack
        10.0    // meth
    };

    if (type == E_DRUG_TYPE_COKE)
    {
        new Float: crackSpillover = amount * 3.0;
        new Float: currentCrack = GetDrugAddiction(playerid, E_DRUG_TYPE_CRACK);
        SetDrugAddiction(playerid, E_DRUG_TYPE_CRACK, currentCrack + crackSpillover);
    }
    else if (type == E_DRUG_TYPE_CRACK)
    {
        new Float: cokeSpillover = amount * 2.0;
        new Float: currentCoke = GetDrugAddiction(playerid, E_DRUG_TYPE_COKE);
        SetDrugAddiction(playerid, E_DRUG_TYPE_COKE, currentCoke + cokeSpillover);
    }

    new Float: gain = addictionRate[type] * amount;
    new Float: current = GetDrugAddiction(playerid, type);
    SetDrugAddiction(playerid, type, current + gain);

    // suppress withdrawal now that theyve used the drug
    Character[playerid][E_CHARACTER_IN_WITHDRAWAL] = false;

    SaveDrugAddiction(playerid);
    return true;
}

// /checkaddiction - shows your addiction level for each drug.
CMD:checkaddiction(playerid, params[])
{
    new bool: anyAddiction = false;

    SendClientMessage(playerid, 0xDEDEDEFF, "____________ Addiction Levels ____________");

    for (new i = 0; i < 4; i++)
    {
        new Float: val = GetDrugAddiction(playerid, i);

        new label[16];
        GetDrugAddictionLabel(val, label, sizeof(label));

        new color;
        if      (val >= 80.0) color = 0xE24B4AFF;
        else if (val >= 60.0) color = 0xEF9F27FF;
        else if (val >= 30.0) color = 0x97C459FF;
        else                  color = 0x888780FF;
        new drug_type[32];
        Drugs_GetTypeName(i, drug_type);
        SendClientMessage(playerid, color, sprintf("  %s: %.0f/100 (%s)", drug_type, val, label));

        if (val >= 30.0) anyAddiction = true;
    }

    if (!anyAddiction)
        SendClientMessage(playerid, 0x888780FF, "  You are not currently addicted to any substance.");

    SendClientMessage(playerid, 0xDEDEDEFF, "______________________________");

    // AddictionGUI_Show(playerid);

    return true;
}
