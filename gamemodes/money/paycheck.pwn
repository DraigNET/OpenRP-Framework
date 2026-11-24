// ============================================================================
// File: money/paycheck.pwn
// Paychecks: every hour a character earns a salary (by faction/job/level) plus interest, paid
// with /paycheck. Shows time to the next paycheck with /nextpaycheck. Minutes played towards
// the next paycheck are remembered when a player leaves.
// Commands: /paycheck /nextpaycheck
// ============================================================================

#define SERVER_PAYCHECK (Runtime_Int(RT_PAYCHECK_BASE)) // Cached database setting; edit through ACP.
#define MIN_PAYCHECK_MINUTES (Runtime_Int(RT_PAYCHECK_MINIMUM_MINUTES)) // Cached database setting; edit through ACP.
#define MS_PER_MINUTE		 	60000
#define PAYCHECK_INTERVAL (Runtime_Int(RT_PAYCHECK_INTERVAL_MINUTES)) // Cached database setting; edit through ACP.

new g_ServerStartTick;
new g_LastPaycheckTick, PaycheckScheduleTimer, PaycheckScheduledInterval;

new bool:PlayerQualifiedThisSession[MAX_PLAYERS];

// Minutes played towards the next paycheck are kept when a player leaves (quits, crashes or uses /logout), and
// handed back when that character comes back, as long as no paycheck has been paid in between. Without this, quitting
// at minute 37 and coming back reset the count to 0. Held in memory only, so a server restart clears it.
#define PAYCHECK_SAVE_SLOTS (64)

enum E_PAYCHECK_SAVE {
	pcs_char,
	pcs_minutes,
	pcs_cycle,
	bool:pcs_qualified
};

new Paycheck_Saved[PAYCHECK_SAVE_SLOTS][E_PAYCHECK_SAVE];
new Paycheck_NextSlot;
new Paycheck_Cycle; // goes up every time a paycheck round is paid
new bool:Paycheck_Restored[MAX_PLAYERS];


forward GlobalPaycheckTimer();
forward UpdatePaycheckTime();

// Force paycheck
CMD:paycheck(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_MANAGER ) {
		return SendServerMessage ( playerid, COLOR_RED, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	foreach(new targetid: Player) {
		PlayerVar[targetid][E_PLAYER_PAYCHECK_INCR]++;
		PaycheckTick(targetid);
		PlayerVar[targetid][E_PLAYER_PAYCHECK_TIME] = 0;
	}
	
	new string [ 85 ] ;
	format ( string, sizeof ( string ), "[PAYCHECK] (%d) %s has forced a serverwide paycheck.",  playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME]);
	SendAdminMessage ( string ) ;

	g_LastPaycheckTick = GetTickCount() / MS_PER_MINUTE;
	Paycheck_Cycle++;

	return true ;
}

// Returns the extra paycheck bonus for the player's premium level.
static stock Paycheck_GetVIPBonus(playerid)
{
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL])
    {
        case E_PREMIUM_LVL_4: return 3500; // Gold
        case E_PREMIUM_LVL_3: return 2000; // Silver
    }

    return 0;
}

// Pays a player their hourly paycheck: salary, interest, rent and bonuses, then shows the bank
// statement.
PaycheckTick(playerid) {
	SendClientMessage(playerid, COLOR_YELLOW, "BANK STATEMENT");

	// base payouts (INCR already incremented before calling)
	new paycheck_total = (SERVER_PAYCHECK * PlayerVar[playerid][E_PLAYER_PAYCHECK_INCR]);
	new salary_total = Paycheck_CalculateSalary(playerid);

	paycheck_total = Paycheck_CalculateAFKDebuff(playerid, paycheck_total, salary_total);

	Paycheck_CalculateSavings(playerid, paycheck_total);
	paycheck_total += Paycheck_CalculateIllegal(playerid);

	// VIP BONUS
	new vipBonus = Paycheck_GetVIPBonus(playerid);
	if (vipBonus > 0)
	{
		paycheck_total += vipBonus;
		SendClientMessage(playerid, 0xb3b3b3FF,
			sprintf("VIP BONUS: {7ea928}$%s",
				IntegerWithDelimiter(vipBonus)
			)
		);
	}

	Paycheck_CalculateBankReceipt(playerid, paycheck_total);


	Paycheck_IncreaseHours(playerid); // Increase hours and level if applicable
	Paycheck_CheckFightStyle(playerid); // Check how long fightstyle lasts

	return true;
}


// Finds a saved paycheck-minutes entry for a character who left.
static Paycheck_FindSaved(char_id) {

	for (new i; i < PAYCHECK_SAVE_SLOTS; i++) {

		if (Paycheck_Saved[i][pcs_char] == char_id) return i;
	}

	return -1;
}

// Called when a character leaves (disconnect or /logout). Remembers their minutes for this paycheck round.
static Paycheck_SaveMinutes(playerid) {

	new char_id = Character[playerid][E_CHARACTER_ID];

	if (char_id <= 0 || !IsPlayerLogged(playerid) || !IsPlayerPlaying(playerid)) return;

	new minutes = PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME];

	if (minutes <= 0 && !PlayerQualifiedThisSession[playerid]) return;

	new slot = Paycheck_FindSaved(char_id);

	if (slot == -1) {

		slot = Paycheck_NextSlot;
		Paycheck_NextSlot = (Paycheck_NextSlot + 1) % PAYCHECK_SAVE_SLOTS;
	}

	Paycheck_Saved[slot][pcs_char] = char_id;
	Paycheck_Saved[slot][pcs_minutes] = minutes;
	Paycheck_Saved[slot][pcs_cycle] = Paycheck_Cycle;
	Paycheck_Saved[slot][pcs_qualified] = PlayerQualifiedThisSession[playerid];
}

// Once a player has a character in the game, gives back what they had before they left (same paycheck round only).
static Paycheck_TryRestore(playerid) {

	if (Paycheck_Restored[playerid]) return;

	new char_id = Character[playerid][E_CHARACTER_ID];

	if (char_id <= 0 || !IsPlayerLogged(playerid) || !IsPlayerPlaying(playerid)) return;

	Paycheck_Restored[playerid] = true;

	new slot = Paycheck_FindSaved(char_id);

	if (slot == -1) return;

	if (Paycheck_Saved[slot][pcs_cycle] == Paycheck_Cycle) {

		PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME] += Paycheck_Saved[slot][pcs_minutes];

		if (Paycheck_Saved[slot][pcs_qualified]) PlayerQualifiedThisSession[playerid] = true;

		SendClientMessage(playerid, COLOR_INFO, sprintf("Your %d minutes played towards the next paycheck from before you left have been kept.", Paycheck_Saved[slot][pcs_minutes]));
	}

	Paycheck_Saved[slot][pcs_char] = 0;
}

#include <YSI_Coding\y_hooks>

hook ORP_OnCloseConnection(playerid, reason) {

	Paycheck_SaveMinutes(playerid);

	// The next person to take this player id starts from scratch.
	PlayerQualifiedThisSession[playerid] = false;
	Paycheck_Restored[playerid] = false;

	return 1;
}

// Hourly timer: runs the paycheck for every player who played enough minutes.
public GlobalPaycheckTimer() {
	new non_qualifying_players[MAX_PLAYERS];
	new non_qualifying_count = 0;
	
	g_LastPaycheckTick = GetTickCount() / MS_PER_MINUTE;

	foreach(new playerid : Player) Paycheck_TryRestore(playerid);

	// Everyone's minutes start again after this round (saved ones from before it no longer count).
	Paycheck_Cycle++;

	foreach(new playerid : Player) {
		if(PlayerQualifiedThisSession[playerid] || PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME] >= MIN_PAYCHECK_MINUTES) {

			if(!PlayerQualifiedThisSession[playerid]) {
				PlayerQualifiedThisSession[playerid] = true;
				SendClientMessage(playerid, COLOR_GREEN, "You've qualified for automatic hourly paychecks for the rest of your session!");
			}
			// Give the paycheckn    
			PlayerVar[playerid][E_PLAYER_PAYCHECK_INCR]++;
			PaycheckTick(playerid);
			PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME] = 0;
		} else {
			non_qualifying_players[non_qualifying_count++] = playerid;
		}
	}
	
	for(new i = 0; i < non_qualifying_count; i++) {
		new playerid = non_qualifying_players[i];
		new minutes_played = PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME];
		
		SendClientMessage(playerid, COLOR_YELLOW, "PAYCHECK MISSED");
		SendClientMessage(playerid, COLOR_RED, sprintf("You only played %d/%d minutes and did not qualify for a full paycheck.", 
			minutes_played, MIN_PAYCHECK_MINUTES));
		
		PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME] = 0;
	}
}

// playtime accumulator (1 minute intervals)
public UpdatePaycheckTime() {
	foreach(new playerid : Player) {
		Paycheck_TryRestore(playerid);

		PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME]++;
			
		// if player just reached the minimum minutes and is eligible for paycheck
		if(PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME] == MIN_PAYCHECK_MINUTES) {
			new current_time = GetTickCount() / MS_PER_MINUTE;
			new time_since_last_paycheck = current_time - g_LastPaycheckTick;
			if(time_since_last_paycheck > (PAYCHECK_INTERVAL * 0.75)) {
				SendClientMessage(playerid, COLOR_GREEN, "You've reached the minimum playtime for the next paycheck!");
				SendClientMessage(playerid, COLOR_INFO, sprintf("Paycheck will be distributed in approximately %d minutes.", 
					PAYCHECK_INTERVAL - time_since_last_paycheck));
			}
		}
	}
}

// Reschedule only when the interval changes. Minutes already earned are retained.
// An overdue cycle runs on the next tick instead of producing a burst of payments.
Paycheck_Reschedule(bool:initial=false) {
    if (!initial && (!PaycheckScheduleTimer || PaycheckScheduledInterval==PAYCHECK_INTERVAL)) return 1;
    if (PaycheckScheduleTimer) KillTimer(PaycheckScheduleTimer);
    new elapsed=initial ? 0 : (GetTickCount()/MS_PER_MINUTE)-g_LastPaycheckTick;
    new remaining=PAYCHECK_INTERVAL-elapsed;
    if (remaining<1) remaining=1;
    PaycheckScheduledInterval=PAYCHECK_INTERVAL;
    PaycheckScheduleTimer=SetTimer("Runtime_PaycheckCycle",remaining*MS_PER_MINUTE,false);
    return 1;
}
forward Runtime_PaycheckCycle();
public Runtime_PaycheckCycle() {
    GlobalPaycheckTimer();
    PaycheckScheduleTimer=0;
    return Paycheck_Reschedule(true);
}

// Starts the paycheck timers.
InitializePaycheckSystem() {
	Paycheck_Reschedule(true);
	SetTimer("UpdatePaycheckTime", 60000, true);
	g_LastPaycheckTick = GetTickCount() / MS_PER_MINUTE;
}

// On start-up: starts the paycheck system.
public OnGameModeInit() {
	g_ServerStartTick = GetTickCount() / MS_PER_MINUTE;
	InitializePaycheckSystem();

	#if defined pay_OnGameModeInit
		return pay_OnGameModeInit();
	#else
		return 1;
	#endif
}
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif

#define OnGameModeInit pay_OnGameModeInit
#if defined pay_OnGameModeInit
	forward pay_OnGameModeInit();
#endif

// Calculations
Paycheck_CalculateSalary(playerid) {

	new salary = 0;
	new salary_total = 0;
	new duty_bonus = 0;
	
	if (IsPlayerInLEAFaction(playerid)) 	{ salary = 225; duty_bonus = 250; }
	//else if (IsPlayerInMedicFaction(playerid)) 		{ salary = 200; duty_bonus = 250; }
	else if (IsPlayerInNewsFaction(playerid)) 		{ salary = 250;	duty_bonus = 150; }
	else if (IsPlayerInGovFaction(playerid)) 		{ salary = 250; duty_bonus = 100; }
	else if (IsPlayerInTruckerFaction(playerid)) 	{ salary = 250; duty_bonus = 0;	  }
	else if (IsPlayerInAnyGovFaction(playerid))		{ salary = 200; duty_bonus = 100; }

	if (salary)
	{
		if (Character[playerid][E_CHARACTER_FACTIONTIER] == 1) salary += 175;
		if (Character[playerid][E_CHARACTER_FACTIONTIER] == 2) salary += 100;
		if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3) salary -= 50; // tier 4 or higher gets less
		if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3 && IsPlayerInLEAFaction(playerid)) salary = 0; // LEA Volunteers get no salary

		salary_total = salary * PlayerVar [ playerid ] [ E_PLAYER_PAYCHECK_INCR ] ;
	}

	

	// Send them salary message
	if (salary_total) 
	{
		new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ], faction_enum_id = Faction_GetEnumID(factionid), salarystr[128];
		if (PlayerVar[playerid][ E_PLAYER_FACTION_DUTY] && duty_bonus > 0)
		{
			format(salarystr, sizeof(salarystr), "%s SALARY: {7ea928}$%s {b3b3b3}(Tier %d){b3b3b3} || DUTY BONUS: {7ea928}$%s", Faction[faction_enum_id][E_FACTION_ABBREV], IntegerWithDelimiter(salary_total), Character[playerid][E_CHARACTER_FACTIONTIER], IntegerWithDelimiter(duty_bonus));
			salary_total += duty_bonus;
		}
		else format(salarystr, sizeof(salarystr), "%s SALARY: {7ea928}$%s {b3b3b3}(Tier %d)", Faction[faction_enum_id][E_FACTION_ABBREV], IntegerWithDelimiter(salary_total), Character[playerid][E_CHARACTER_FACTIONTIER]);
		SendClientMessage(playerid, 0xb3b3b3FF, salarystr);
	}

	return salary_total;
}

// Adds savings interest to the player's savings and returns the amount.
Paycheck_CalculateSavings(playerid, current_pay) {
	
	new savings_calc = ( Character [ playerid ] [ E_CHARACTER_SAVINGS ] / 700 ) / 2 ;
	Character [ playerid ] [ E_CHARACTER_SAVINGS ] += savings_calc ;

	new query [ 144 ] ;
	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_savings = %d WHERE player_id = %d", 
		Character [ playerid ] [ E_CHARACTER_SAVINGS ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;

	mysql_tquery(mysql, query);

	format ( query, sizeof ( query ), "UNIVERSAL INCOME: {7ea928}$%s {b3b3b3}|| SAVINGS INTEREST: {7ea928}$%s{b3b3b3} ($%s total)", IntegerWithDelimiter(current_pay), IntegerWithDelimiter(savings_calc), IntegerWithDelimiter(Character[playerid][E_CHARACTER_SAVINGS])); 
	SendClientMessage(playerid, 0xb3b3b3FF, query);
	return savings_calc;
}

// Adds income from illegal sources (turf, etc.) to the paycheck.
Paycheck_CalculateIllegal(playerid) {
	new total_illegal_pay = 0;
	if (GetPlayerFactionType(playerid) != -1 || Character[playerid][E_CHARACTER_FACTIONID] > 0) {

#if defined FEATURE_GANGZONES
		new turf_pay = Gangzone_Paycheck(playerid);
		if(turf_pay) {

			SendClientMessage(playerid, 0xb3b3b3FF, sprintf("ILLEGAL (GANG ZONES): {7ea928}$%s{b3b3b3} (%d owned)", IntegerWithDelimiter(turf_pay), Gangzone_Count(Character[playerid][E_CHARACTER_FACTIONID]) ));
			total_illegal_pay += turf_pay;
		}
#endif
#if defined FEATURE_EMMET
		new emmet_pay = Emmet_HandlePaycheck(playerid);
		if(emmet_pay) {
			SendClientMessage(playerid, 0xb3b3b3FF, sprintf("ILLEGAL (GUN DEALER PROFITS): {7ea928}$%s", IntegerWithDelimiter(emmet_pay)));
			total_illegal_pay += emmet_pay;

		}
#endif
	}
	return total_illegal_pay;
}

// Works out the rent due on a rented room and takes it from the paycheck.
Paycheck_CalculateRent(playerid) {
	
	// E_CHARACTER_RENTEDHOUSE is the property's SQL id, not its index in Property[].
	new renting = Property_LinkSQLToEnum ( Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] ), rent, query[144] ;

	if ( renting != -1 ) {
		// Player is using rented room
		if ( Character [ playerid ] [ E_CHARACTER_PROPERTYSPAWN ] == 1 ) {

			rent = Property [ renting ] [ E_PROPERTY_RENT ] ;

			// A real estate firm's rent goes straight into the firm bank instead of the landlord's collect pile.
			if ( Property_IsFirmOwned ( renting ) ) {

				new firm_enum_id = Firm_GetEnumID ( Property [ renting ] [ E_PROPERTY_FIRM ] ) ;

				if ( Firm_IsValid ( firm_enum_id ) && rent > 0 ) {

					Firm_AddBankMoney ( firm_enum_id, rent, sprintf ( "Rent for property %d from %s", Property [ renting ] [ E_PROPERTY_ID ], ReturnRPName ( playerid ) ) ) ;
				}
			}

			else Property [ renting ] [ E_PROPERTY_COLLECT ] += rent ;

			mysql_format(mysql, query, sizeof ( query ), "UPDATE properties SET property_collect = %d WHERE property_id = %d", Property [ renting ] [ E_PROPERTY_COLLECT ], Property [ renting ] [ E_PROPERTY_ID ] );
			mysql_tquery(mysql, query );
		}

		// Player isn't using rented room
		else if ( Character [ playerid ] [ E_CHARACTER_PROPERTYSPAWN ] == 0 ) {
			rent = 0 ;
		}
	}
	 
	if (rent > 0) SendClientMessage(playerid, 0xb3b3b3FF, sprintf("RENT:{a43e2c} $%d", rent) ) ;
	return rent;
}

// Adds the paycheck to the player's bank account and logs a receipt.
Paycheck_CalculateBankReceipt(playerid, amount) {
	new old_balance = Character [ playerid ] [ E_CHARACTER_BANKCASH ], query [ 256 ] ;
	
	Character [ playerid ] [ E_CHARACTER_BANKCASH ] += amount ;
	Character [ playerid ] [ E_CHARACTER_BANKCASH ] -= Paycheck_CalculateRent(playerid) ;
	AddLogEntry(playerid, LOG_TYPE_MONEY_FLOW, sprintf("Bank Credit: Paycheck - Amount: $%d", amount));

	SendClientMessage(playerid, 0xb3b3b3FF, sprintf("OLD BALANCE:{2ebae8} $%d{b3b3b3} || NEW BALANCE:{2ebae8} $%d{b3b3b3}", old_balance, Character [ playerid ] [ E_CHARACTER_BANKCASH ] ) ) ;

	Character [ playerid ] [ E_CHARACTER_PAYCHECK ] = 0 ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_bankcash = %d, player_paycheck = 0 WHERE player_id = %d", Character [ playerid ] [ E_CHARACTER_BANKCASH ], Character [ playerid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;
}

// Reduces the paycheck for players who have been in the game for a long time.
Paycheck_CalculateAFKDebuff(playerid, paycheck_total, salary_total) {
	new final_amount = 0;
	if ( PlayerVar [ playerid ] [ E_PLAYER_PAYCHECK_INCR ] >= 6 ) 
	{
		SendClientMessage(playerid, COLOR_YELLOW, "You've been ingame for a long time! Your paycheck has been limited to avoid money farming.");
		paycheck_total = SERVER_PAYCHECK - (SERVER_PAYCHECK / PlayerVar [ playerid ] [ E_PLAYER_PAYCHECK_INCR ]) ;
		salary_total = (salary_total - (salary_total / PlayerVar [ playerid ] [ E_PLAYER_PAYCHECK_INCR ]));
	}

	// Add the salary to the paycheck
	final_amount = (paycheck_total + salary_total);
	return final_amount;
}

// Misc functions
Paycheck_IncreaseHours(playerid) {
	Character [ playerid ] [ E_CHARACTER_HOURS ] ++ ;

	if (IsPlayerArrested(playerid))
	{
		Character[playerid][E_CHARACTER_PRISON_STAMPS]++;
		SendClientMessage(playerid, COLOR_BLUE, sprintf("You have served another hour in prison. You now have {FFFFFF}%d stamp%s.",
			Character[playerid][E_CHARACTER_PRISON_STAMPS],
			(Character[playerid][E_CHARACTER_PRISON_STAMPS] == 1) ? ("") : ("s")));
	}

	new old_level = Character [ playerid ] [ E_CHARACTER_LEVEL ] ;
	new level = Character [ playerid ] [ E_CHARACTER_HOURS ] / 8 ;

	level = level + 1; // starting level is 1, not 0

	Character [ playerid ] [ E_CHARACTER_LEVEL ] = level ;
	SetPlayerScore(playerid, Character [ playerid ] [ E_CHARACTER_LEVEL ] ) ;

	if ( old_level != level ) {
		SendClientMessage(playerid, COLOR_BLUE, sprintf("You've now played for %d hours and have advanced to Level %d.", Character [ playerid ] [ E_CHARACTER_HOURS ], level));
		Notify_Character(Character [ playerid ] [ E_CHARACTER_ID ], "level", "Level up!",
			sprintf("You've reached level %d after %d hours played.", level, Character [ playerid ] [ E_CHARACTER_HOURS ]), "/ucp/characters");

#if defined FEATURE_FNR
		Character[playerid][E_CHARACTER_FnR_GIVABLE] += 3;

		Character[playerid][E_CHARACTER_FEAR] += 1;

		Character[playerid][E_CHARACTER_RESPECT] += 3;
#endif
	}

	new query [ 256 ] ;
	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_hours = %d, player_level=%d WHERE player_id=%d",
		Character [ playerid ] [ E_CHARACTER_HOURS ], Character [ playerid ] [ E_CHARACTER_LEVEL ], Character [ playerid ] [ E_CHARACTER_ID ]
	);
	
	mysql_tquery(mysql, query);
	
#if defined FEATURE_FNR
	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fnr_givable = %d WHERE player_id = %d",
		Character[playerid][E_CHARACTER_FnR_GIVABLE], Character[playerid][E_CHARACTER_ID]);
	mysql_tquery(mysql, query);

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_respect = %d WHERE player_id = %d",
		Character[playerid][E_CHARACTER_RESPECT], Character[playerid][E_CHARACTER_ID]);
	mysql_tquery(mysql, query);

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fear = %d WHERE player_id = %d",
        Character[playerid][E_CHARACTER_FEAR], Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);
#endif

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_prison_stamps = %d WHERE player_id = %d",
        Character[playerid][E_CHARACTER_PRISON_STAMPS], Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);
}

// Checks whether a fighting style has expired at paycheck time.
Paycheck_CheckFightStyle(playerid) {

	new bool: recent_removal = false ;
	if ( Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ]  ) {
		Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] -- ;

		SendClientMessage ( playerid, COLOR_BLUE, sprintf("Your fightstyle is protected for %d more paychecks.", Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] ));
		if ( Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] <= 0 ) {

			SendClientMessage ( playerid, COLOR_ERROR, "Your fightstyle protection is now gone. If you do not maintain your skills from this point forward, you will LOSE the fightstyle!");
			SendClientMessage(playerid, COLOR_YELLOW, "If you have the proper stats required for your fightstyle, you can go back to any gym to \"extend\" this protection.");
			Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE_TICK ] = 0 ;
			Character [ playerid ] [ E_CHARACTER_FIGHTSTYLE ] = FIGHT_STYLE_NORMAL ;
		}

		recent_removal = true ;
		Gym_SaveVariables(playerid);
	}

	else {
		if (! recent_removal ) {
			Gym_CheckFightStyleExpiration(playerid);
		}
	}
}

// Helper function
stock GetPlayerCharacterLevel(playerid) {
	new level = Character [ playerid ] [ E_CHARACTER_HOURS ] / 8 ;
	return level + 1;
}

// /nextpaycheck - shows how many minutes until the next paycheck.
CMD:nextpaycheck(playerid, params[]) {
	new current_time = GetTickCount() / MS_PER_MINUTE;
	new time_since_last_paycheck = current_time - g_LastPaycheckTick;
	new minutesLeft = PAYCHECK_INTERVAL - time_since_last_paycheck;
	if(minutesLeft < 0) minutesLeft = 0; // Safeguard against negative values
	
	new currentPlaytime = PlayerVar[playerid][E_PLAYER_PAYCHECK_TIME];
	new requiredMinutes = MIN_PAYCHECK_MINUTES - currentPlaytime;
	if(requiredMinutes < 0) requiredMinutes = 0;
	
	new fightstyleTicks = Character[playerid][E_CHARACTER_FIGHTSTYLE_TICK];
	new afkDebuff = (PlayerVar[playerid][E_PLAYER_PAYCHECK_INCR] >= 6) ? 1 : 0;
	
	SendClientMessage(playerid, COLOR_YELLOW, "=== NEXT PAYCHECK INFORMATION ===");
	
	SendClientMessage(playerid, COLOR_INFO, sprintf("Time until next paycheck: {00FF00}%d minutes", minutesLeft));
	SendClientMessage(playerid, COLOR_INFO, sprintf("Current playtime this cycle: {00FF00}%d/%d minutes", 
		currentPlaytime, 
		MIN_PAYCHECK_MINUTES
	));
	
	if(currentPlaytime >= MIN_PAYCHECK_MINUTES) {
		SendClientMessage(playerid, COLOR_GREEN, "Status: {00FF00}Eligible for next paycheck");
		
		new estimated_paycheck = SERVER_PAYCHECK;
		new estimated_salary = 0;
		
		if(Character[playerid][E_CHARACTER_FACTIONID] > 0) {
			estimated_salary = Paycheck_CalculateSalary(playerid);
		}
		
		SendClientMessage(playerid, COLOR_INFO, sprintf("Estimated paycheck: {00FF00}$%d", 
			Paycheck_CalculateAFKDebuff(playerid, estimated_paycheck, estimated_salary)));
	} else {
		SendClientMessage(playerid, COLOR_RED, sprintf("Status: {FF0000}Need %d more minutes", requiredMinutes));
	}
	
	SendClientMessage(playerid, COLOR_INFO, sprintf("Total paychecks received: {00FF00}%d", PlayerVar[playerid][E_PLAYER_PAYCHECK_INCR]));
	SendClientMessage(playerid, COLOR_INFO, sprintf("Current level: {00FF00}%d", GetPlayerCharacterLevel(playerid)));
	SendClientMessage(playerid, COLOR_INFO, sprintf("Total hours played: {00FF00}%d", Character[playerid][E_CHARACTER_HOURS]));
	
	if(fightstyleTicks > 0) {
		SendClientMessage(playerid, COLOR_INFO, sprintf("Fightstyle protection: {00FF00}%d paychecks remaining", fightstyleTicks));
	}
	if(afkDebuff) {
		SendClientMessage(playerid, COLOR_RED, "WARNING: {FF0000}AFK Debuff active - Reduced paycheck income!");
	}
	
	return 1;
}

// Returns how many minutes the server has been running.
stock GetServerUptimeMinutes() {
	return (GetTickCount() / MS_PER_MINUTE) - g_ServerStartTick;
}
