// ============================================================================
// File: jobs/pizza/header.pwn
// Pizza delivery job: /pizza starts a route of houses, hand over pizzas, return the scooter for
// a bonus. /endpizza cancels.
// Commands: /pizza /endpizza
// ============================================================================

// -----------------------------------------------------------------
// Pizza Delivery Job
// -----------------------------------------------------------------
// Player uses a pizza job van (assigned via /carjob 4). /pizza builds a
// route of 5 E_PROPERTY_TYPE_HOUSE properties (VW 0, interior 0) pooled
// from anywhere in Red County (see PizzaJob_IsEligible below). Drive to each house,
// get out, press Y next to the van to grab a pizza box (holding anim),
// then step into the checkpoint to deliver it for a payment. After all 5
// are delivered, return the van to its spawn/depot (in that specific
// vehicle) for a bonus. /endpizza aborts.
// -----------------------------------------------------------------

// Route rules are captured at acceptance; cache edits only affect new routes.
new PizzaRouteCount[MAX_PLAYERS], PizzaRouteMin[MAX_PLAYERS], PizzaRouteMax[MAX_PLAYERS], PizzaRouteBonus[MAX_PLAYERS];
#define PIZZA_MAX_CANDIDATES    (256)

// Red County is the whole county, not just the towns around the pizzeria: the same box the map zone
// ZONE_RED_COUNTY covers in config/data/zones.pwn (everything north of Los Santos, east of the Bone County border).
#define PIZZA_AREA_MIN_X (Runtime_Float(RT_PIZZA_MIN_X)) // Cached database setting; edit through ACP.
#define PIZZA_AREA_MIN_Y (Runtime_Float(RT_PIZZA_MIN_Y)) // Cached database setting; edit through ACP.
#define PIZZA_AREA_MAX_X (Runtime_Float(RT_PIZZA_MAX_X)) // Cached database setting; edit through ACP.
#define PIZZA_AREA_MAX_Y (Runtime_Float(RT_PIZZA_MAX_Y)) // Cached database setting; edit through ACP.

// Returns true if a coordinate lies inside the area pizza deliveries are allowed in.
static bool: PizzaJob_IsEligible(Float:x, Float:y) {

	return x >= PIZZA_AREA_MIN_X && x <= PIZZA_AREA_MAX_X && y >= PIZZA_AREA_MIN_Y && y <= PIZZA_AREA_MAX_Y;
}

#define PIZZA_CHECKPOINT_SIZE (Runtime_Float(RT_PIZZA_CHECKPOINT_SIZE)) // Cached database setting; edit through ACP.
#define PIZZA_BOX_MODEL         (1582)
#define PIZZA_ATTACH_INDEX      (E_ATTACH_INDEX_SYSTEM)
#define PIZZA_VEHICLE_RANGE (Runtime_Float(RT_PIZZA_VEHICLE_RANGE)) // Cached database setting; edit through ACP.
#define PIZZA_DELIVER_RANGE     (PIZZA_CHECKPOINT_SIZE + 1.5)
#define PIZZA_PAY_MIN (Runtime_Int(RT_PIZZA_PAY_MIN)) // Cached database setting; edit through ACP.
#define PIZZA_PAY_MAX (Runtime_Int(RT_PIZZA_PAY_MAX)) // Cached database setting; edit through ACP.
#define PIZZA_BONUS_PAY (Runtime_Int(RT_PIZZA_BONUS)) // Cached database setting; edit through ACP.

// Returns true if a vehicle is a pizza job vehicle.
IsPizzaJobVehicle(vehicleid) {

	new veh_enum_id = Vehicle_GetEnumID(vehicleid);

	if (veh_enum_id == -1) return false;

	if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_JOB
		&& Vehicle[veh_enum_id][E_VEHICLE_JOBID] == E_VEHICLE_JOB_PIZZA) {

		return true;
	}

	return false;
}

// Returns true if the player is driving a pizza job vehicle.
IsPlayerInPizzaJobVehicle(playerid) {

	new vehicleid = GetPlayerVehicleID(playerid);

	if (GetVehicleDriver(vehicleid) != playerid) return false;

	return IsPizzaJobVehicle(vehicleid);
}

// Chooses the houses for a new route (a nearby group picked at random).
PizzaJob_BuildRoute(playerid) {
    PizzaRouteCount[playerid]=Runtime_Int(RT_PIZZA_DELIVERIES);
    PizzaRouteMin[playerid]=PIZZA_PAY_MIN; PizzaRouteMax[playerid]=PIZZA_PAY_MAX; PizzaRouteBonus[playerid]=PIZZA_BONUS_PAY;

	// Pool every house in Red County together and pick PizzaRouteCount[playerid] of them at random.
	new candidates[PIZZA_MAX_CANDIDATES], count = 0;

	foreach (new i : Properties) {

		if (Property[i][E_PROPERTY_TYPE] != E_PROPERTY_TYPE_HOUSE) continue;
		if (Property[i][E_PROPERTY_EXT_VW]  != 0) continue;
		if (Property[i][E_PROPERTY_EXT_INT] != 0) continue;

		if (!PizzaJob_IsEligible(Property[i][E_PROPERTY_EXT_X], Property[i][E_PROPERTY_EXT_Y])) continue;

		if (count < sizeof(candidates)) candidates[count] = i;
		count++;
	}

	if (count < PizzaRouteCount[playerid]) return false;

	new pool = (count < sizeof(candidates)) ? count : sizeof(candidates);

	// Partial Fisher-Yates shuffle to pick PizzaRouteCount[playerid] unique houses.
	for (new s = 0; s < PizzaRouteCount[playerid]; s++) {

		new r = s + random(pool - s);

		new tmp = candidates[s];
		candidates[s] = candidates[r];
		candidates[r] = tmp;

		PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOUSES][s] = candidates[s];
	}

	return true;
}

// Puts a checkpoint and map marker on the next house to deliver to.
PizzaJob_SetHouseCheckpoint(playerid) {

	new idx  = PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX];
	new prop = PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOUSES][idx];

	new Float: x = Property[prop][E_PROPERTY_EXT_X];
	new Float: y = Property[prop][E_PROPERTY_EXT_Y];
	new Float: z = Property[prop][E_PROPERTY_EXT_Z];

	SetPlayerCheckpoint(playerid, x, y, z, PIZZA_CHECKPOINT_SIZE);

	new zone[MAX_MAP_ZONE_NAME];
	GetCoords2DZone(x, y, zone);

	GPS_MarkLocation(playerid, sprintf("~g~Pizza delivery~w~ (%d/%d) in %s.", idx + 1, PizzaRouteCount[playerid], zone),
		E_GPS_COLOR_JOB, x, y, z);

	ShowPlayerInfoMessage(playerid, sprintf("Drive to house %d/%d. Get out, press ~k~~CONVERSATION_YES~ next to the Pizzaboy to grab a pizza, then enter the ~g~checkpoint~w~.", idx + 1, PizzaRouteCount[playerid]),
		.height = 167.5, .width = 180, .showtime = 7000);
}

// Starts the final leg: return the vehicle to the depot for the bonus.
PizzaJob_BeginReturn(playerid) {

	PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING] = true;

	new vehicleid   = PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE];
	new veh_enum_id = Vehicle_GetEnumID(vehicleid);

	if (veh_enum_id == -1) {

		// Van is gone - nothing to return to, just finish out.
		SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "Your Pizzaboy is missing. The job has been ended.");
		PizzaJob_ClearState(playerid);
		return;
	}

	new Float: x = Vehicle[veh_enum_id][E_VEHICLE_POS_X];
	new Float: y = Vehicle[veh_enum_id][E_VEHICLE_POS_Y];
	new Float: z = Vehicle[veh_enum_id][E_VEHICLE_POS_Z];

	SetPlayerCheckpoint(playerid, x, y, z, PIZZA_CHECKPOINT_SIZE);
	GPS_MarkLocation(playerid, "Return the ~g~Pizzaboy~w~ to its depot for your bonus.", E_GPS_COLOR_JOB, x, y, z);

	ShowPlayerInfoMessage(playerid, "All pizzas delivered! Drive the Pizzaboy back to its ~g~depot~w~ to collect your bonus.",
		.height = 167.5, .width = 180, .showtime = 8000);
}

// Hands over a pizza when the player is in the checkpoint and pays them.
PizzaJob_TryDeliver(playerid) {

	if (!PlayerVar[playerid][E_PLAYER_PIZZAJOB]) return;
	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING]) return;

	if (!PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING]) {

		ShowPlayerFooter(playerid, "Grab a pizza from your Pizzaboy (press Y next to it) before delivering.", 3500);
		return;
	}

	new idx  = PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX];
	new prop = PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOUSES][idx];

	if (!IsPlayerInRangeOfPoint(playerid, PIZZA_DELIVER_RANGE,
		Property[prop][E_PROPERTY_EXT_X], Property[prop][E_PROPERTY_EXT_Y], Property[prop][E_PROPERTY_EXT_Z])) {

		// Grabbed a pizza but not at the door yet - wait for the checkpoint.
		return;
	}

	new pay = PizzaRouteMin[playerid] + random(PizzaRouteMax[playerid] - PizzaRouteMin[playerid] + 1);
	GivePlayerCash(playerid, pay, "Pizza delivery payout");

	// Drop the box / stop carrying. The carry anim is applied frozen+looped, so a bare
	// ClearAnimations doesn't reliably reset the pose - re-apply a neutral stance after,
	// same fix /stopanim uses for the same class of stuck animation.
	RemovePlayerAttachedObject(playerid, PIZZA_ATTACH_INDEX);
	ClearAnimations(playerid, 1);
	ApplyAnimation(playerid, "PED", "IDLE_STANCE", 4.0, 0, 0, 0, 0, 1, 1);
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING] = false;

	PlayerVar[playerid][E_PLAYER_PIZZAJOB_DELIVERED]++;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX]++;

	DisablePlayerCheckpoint(playerid);

	GameTextForPlayer(playerid, sprintf("~g~Pizza delivered!~n~~w~$%s", IntegerWithDelimiter(pay)), 3000, 6);

	AddLogEntry(playerid, LOG_TYPE_JOB, sprintf("delivered a pizza (%d/%d) for %d.",
		PlayerVar[playerid][E_PLAYER_PIZZAJOB_DELIVERED], PizzaRouteCount[playerid], pay));

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX] >= PizzaRouteCount[playerid]) {

		PizzaJob_BeginReturn(playerid);
	}
	else {

		PizzaJob_SetHouseCheckpoint(playerid);
	}
}

// Completes the job when the vehicle is returned and pays the bonus.
PizzaJob_CompleteReturn(playerid) {

	if (!IsPlayerInAnyVehicle(playerid)
		|| GetPlayerState(playerid) != PLAYER_STATE_DRIVER
		|| GetPlayerVehicleID(playerid) != PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE]) {

		ShowPlayerFooter(playerid, "Return in your own Pizzaboy to collect the bonus.", 3500);
		return;
	}

	GivePlayerCash(playerid, PizzaRouteBonus[playerid], "Pizza route bonus");
	GiveFnRPoints(playerid, 1, "Pizza delivery job");

	GameTextForPlayer(playerid, sprintf("~y~Route complete!~n~~w~Bonus $%s", IntegerWithDelimiter(PizzaRouteBonus[playerid])), 4000, 6);

	AddLogEntry(playerid, LOG_TYPE_JOB, sprintf("completed a pizza route and earned a %d bonus.", PizzaRouteBonus[playerid]));

	SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "You've completed the route! Use /pizza to start another.");

	PizzaJob_ClearState(playerid);
}

// Resets the pizza job state and checkpoints for a player.
PizzaJob_ClearState(playerid) {

	PlayerVar[playerid][E_PLAYER_PIZZAJOB]           = false;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING] = false;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX]     = 0;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_DELIVERED] = 0;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE]   = INVALID_VEHICLE_ID;

	for (new i = 0; i < 20; i++) {
		PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOUSES][i] = INVALID_PROPERTY_ID;
	}

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING]) {
		ClearAnimations(playerid, 1);
		ApplyAnimation(playerid, "PED", "IDLE_STANCE", 4.0, 0, 0, 0, 0, 1, 1);
	}

	PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING] = false;
	RemovePlayerAttachedObject(playerid, PIZZA_ATTACH_INDEX);

	DisablePlayerCheckpoint(playerid);
	GPS_ClearCheckpoint(playerid);
}

// /pizza - starts a pizza delivery route in a pizza job vehicle.
CMD:pizza(playerid, params[]) {

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB]) {

		return SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "You're already on a pizza route. Use /endpizza to stop.");
	}

	if (!IsPlayerInPizzaJobVehicle(playerid)) {

		return SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "You must be in the driver's seat of a Pizzaboy.");
	}

	if (!PizzaJob_BuildRoute(playerid)) {

		return SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "Couldn't find a neighbourhood with enough houses right now. Try again later.");
	}

	new veh_enum_id = Vehicle_GetEnumID(GetPlayerVehicleID(playerid));

	PlayerVar[playerid][E_PLAYER_PIZZAJOB]           = true;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE]   = Vehicle[veh_enum_id][E_VEHICLE_ID];
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_INDEX]     = 0;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_DELIVERED] = 0;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING] = false;
	PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING]   = false;

	SetEngineStatus(Vehicle[veh_enum_id][E_VEHICLE_ID], true);

	AddLogEntry(playerid, LOG_TYPE_JOB, "started the pizza delivery job");

	SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", sprintf("Deliver %d pizzas around Red County. Head to the first checkpoint.", PizzaRouteCount[playerid]));

	PizzaJob_SetHouseCheckpoint(playerid);

	return true;
}

// /endpizza - cancels the pizza job and returns the vehicle.
CMD:endpizza(playerid, params[]) {

	if (!PlayerVar[playerid][E_PLAYER_PIZZAJOB]) {

		return SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "You're not currently doing the pizza delivery job.");
	}

	new vehicleid = PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE];

	if (IsValidVehicle(vehicleid)) {
		ORP_SetVehicleToRespawn(vehicleid, "/endpizza");
	}

	PizzaJob_ClearState(playerid);

	AddLogEntry(playerid, LOG_TYPE_JOB, "ended the pizza delivery job early");
	SendServerMessage(playerid, COLOR_JOB, "Pizza Job", "DEDEDE", "You've ended the pizza delivery job. The Pizzaboy has been returned to its depot.");

	return true;
}

#include <YSI_Coding\y_hooks>

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB]
		&& !PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING]
		&& (newkeys & KEY_YES)) {

		if (PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING]) {

			// Already holding one - maybe standing in the checkpoint now.
			PizzaJob_TryDeliver(playerid);
			return 1;
		}

		if (IsPlayerInAnyVehicle(playerid)) {

			ShowPlayerFooter(playerid, "Get off the Pizzaboy to grab a pizza.", 3000);
			return 1;
		}

		new vehicleid = Vehicle_GetClosestEntity(playerid, PIZZA_VEHICLE_RANGE);

		if (vehicleid == INVALID_VEHICLE_ID
			|| Vehicle_GetEnumID(vehicleid) == -1
			|| Vehicle[Vehicle_GetEnumID(vehicleid)][E_VEHICLE_ID] != PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE]) {

			ShowPlayerFooter(playerid, "Stand next to your Pizzaboy to grab a pizza.", 3000);
			return 1;
		}

		ApplyAnimation(playerid, "CARRY", "crry_prtial", 4.1, 1, 1, 1, 1, 1, 1);
		SetPlayerAttachedObject(playerid, PIZZA_ATTACH_INDEX, PIZZA_BOX_MODEL, 1,
			0.002953, 0.469660, -0.009797, 269.851104, 88.443557, 0.000000, 0.804894, 1.000000, 0.822361);

		PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING] = true;

		ShowPlayerFooter(playerid, "Carry the pizza into the checkpoint to deliver it.", 4000);

		// In case they grabbed it while already standing at the door.
		PizzaJob_TryDeliver(playerid);
	}

	return 1;
}

hook OnPlayerEnterCheckpoint(playerid) {

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB]) {

		if (PlayerVar[playerid][E_PLAYER_PIZZAJOB_RETURNING]) {

			PizzaJob_CompleteReturn(playerid);
		}
		else {

			PizzaJob_TryDeliver(playerid);
		}
	}

	return 1;
}

hook OnPlayerDeath(playerid, killerid, reason) {

	// Dying drops the pizza you were carrying (you keep the route).
	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB] && PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING]) {

		RemovePlayerAttachedObject(playerid, PIZZA_ATTACH_INDEX);
		PlayerVar[playerid][E_PLAYER_PIZZAJOB_HOLDING] = false;
	}

	return 1;
}

hook OnPlayerDisconnect(playerid, reason) {

	if (PlayerVar[playerid][E_PLAYER_PIZZAJOB]) {

		new vehicleid = PlayerVar[playerid][E_PLAYER_PIZZAJOB_VEHICLE];

		if (IsValidVehicle(vehicleid)) {
			ORP_SetVehicleToRespawn(vehicleid, "pizzajob disconnect");
		}

		PlayerVar[playerid][E_PLAYER_PIZZAJOB] = false;
	}

	return 1;
}
// Keep every remaining accepted pizza stop at its current entrance until the
// route finishes or is cancelled; its checkpoint and distance checks must agree.
Pizza_PropertyInUse(propertyIndex) {
    foreach(new player:Player) if(PlayerVar[player][E_PLAYER_PIZZAJOB] && !PlayerVar[player][E_PLAYER_PIZZAJOB_RETURNING]) {
        for(new routeSlot=PlayerVar[player][E_PLAYER_PIZZAJOB_INDEX];routeSlot<PizzaRouteCount[player];routeSlot++) if(PlayerVar[player][E_PLAYER_PIZZAJOB_HOUSES][routeSlot]==propertyIndex) return 1;
    }
    return 0;
}
