// ============================================================================
// File: jobs/fishing/cmds.pwn
// Fishing job: /fish to cast, catching and releasing fish, /fishes to view your catch,
// /sellfish. Includes the permit and bait checks and the key handler for reeling in.
// Commands: /fish /fishes /sellfish /putback /putallback
// ============================================================================

//E_CHARACTER_FISHINGPERMIT,
//E_CHARACTER_FISHES,
//E_CHARACTER_BIGGEST_FISH,
//E_CHARACTER_ROD,
//E_CHARACTER_BAIT

// /fish - casts a line if you're at a fishing spot (pier or boat) and have a rod and bait.
CMD:fish(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

    new vehicleid = Vehicle_GetClosestEntity(playerid);

    if ( IsPlayerInAnyVehicle(playerid))	    
		return SendClientMessage(playerid, COLOR_ERROR, "You can't fish whilst in a vehicle!");

    if(GetPVarInt(playerid, "IsFishing") == 1)
		return SendClientMessage(playerid, COLOR_ERROR, "You are already fishing!");

	//if ( !Character [ playerid ] [ E_CHARACTER_FISHINGPERMIT ] )
		//return SendClientMessage(playerid, COLOR_ERROR, "You must have a fishing permit to fish!");

	if ( !Character [ playerid ] [ E_CHARACTER_ROD ] )
		return SendClientMessage(playerid, COLOR_ERROR, "You do not have a fishing rod!");
	
	if ( Character [ playerid ] [ E_CHARACTER_BAIT ] <= 0 )
		return SendClientMessage(playerid, COLOR_ERROR, "You do not have any bait!");

    if(IsAtFishPlace(playerid))
	{
		SetPVarInt(playerid, "IsFishing", 1);
		SetPVarInt(playerid, "FishingType", 1);
		SetPlayerAttachedObject(playerid, 9, 18632, 6, 0.0, 0.0, 0.0, 0.0, 180.0, 180.0);
		ApplyAnimation(playerid,"SWORD","sword_block",50.0 ,0,1,0,1,1);
		SetTimerEx("IsFishing", 1500, false, "i", playerid);
	}
	else if(IsABoat(vehicleid))
	{
		SetPVarInt(playerid, "IsFishing", 1);
		SetPVarInt(playerid, "FishingType", 2);
		SetPlayerAttachedObject(playerid, 9, 18632, 6, 0.0, 0.0, 0.0, 0.0, 180.0, 180.0);
		ApplyAnimation(playerid,"SWORD","sword_block",50.0 ,0,1,0,1,1);
		SetTimerEx("IsFishing", 1500, false, "i", playerid);
	}
	else
	{
		SendClientMessage(playerid, COLOR_ERROR, "You're not at a fishing spot, or on a boat!");
		return 1;
	}
	return 1;
}

// /fishes - shows the fish you are carrying with their weights.
CMD:fishes(playerid, params[])
{
	for(new f = 0; f < 5; f++)
	{
		if(FishWeight[playerid][f] == -1) SendClientMessageFormatted(playerid,COLOR_BLUE, "Fish Slot %i: {FFFFFF}Name: {DAA520}n/a  {FFFFFF}Weight: {DAA520}n/a",f+1);
		else SendClientMessageFormatted(playerid,COLOR_BLUE, "Fish Slot %i: {FFFFFF}Name: {DAA520}%s  {FFFFFF}Weight: {DAA520}%i Lbs",f+1,FishName[playerid][f],FishWeight[playerid][f]);
	}
	SendClientMessageFormatted(playerid,COLOR_BLUE, "{FFFFFF}Fishing Bait: {DAA520}%i{FFFFFF}, My Biggest Fish Record: {DAA520}%i Lbs",Character [ playerid ] [ E_CHARACTER_BAIT ],Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ]);

	return true;
}

// /sellfish - sells your fish at a fish buyer for money based on weight.
CMD:sellfish(playerid, params[])
{
	new gstr[1024], sgstr[256];
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(playerid, 5.0, Property [ i ] [ E_PROPERTY_BUY_POS_X ], Property [ i ] [ E_PROPERTY_BUY_POS_Y ], Property [ i ] [ E_PROPERTY_BUY_POS_Z ] ) ) {

			if ( GetPlayerVirtualWorld(playerid ) == Property [ i ] [ E_PROPERTY_BUY_POS_VW ] && GetPlayerInterior(playerid) == Property [ i ] [ E_PROPERTY_BUY_POS_INT ] ) {

				if ( Property [ i ] [ E_PROPERTY_BUY_TYPE ] == E_BUY_TYPE_BAITSHOP) {

					inline FishSell(pid, dialogid, response, listitem, string:inputtext[])
					{

						#pragma unused pid, dialogid, listitem, inputtext

						if ( response ) {
							new tmpVal;

							if(strcmp("Sell All", inputtext, false) == 0)
							{
								new totalsell = 0;

								for(new f = 0; f < 5; f++)
								{
									if(FishWeight[playerid][f] > 0)
									{
										tmpVal = 3 * FishWeight[playerid][f];
										totalsell += tmpVal;

										format(gstr, sizeof(gstr),"You have received {4BB74C}$%i{FFFFFF} for selling the {4BB74C}%iLb %s{FFFFFF}.", tmpVal, FishWeight[playerid][f], FishName[playerid][f]);
										SendClientMessage(playerid, COLOR_WHITE, gstr);

										FishWeight[playerid][f] = -1;
										FishName[playerid][f][0] = EOS;
										GivePlayerCash(playerid, tmpVal, "Sell all fish");

										new query [ 256 ] ;
										mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fishslot%i = 'None', player_fishweight%i = -1 WHERE player_id = %d", f + 1, f + 1, Character[playerid][E_CHARACTER_ID]);
										mysql_tquery(mysql, query);
									}
								}

								format(gstr, sizeof(gstr),"Total: {4BB74C}$%i", totalsell);
								SendClientMessage(playerid, COLOR_WHITE, gstr);
								return 1;
							}
							else
							{
								new slot = -1;
								new cmpStr[128];

								for(new f = 0; f < 5; f++)
								{
									tmpVal = 3 * FishWeight[playerid][f];
									format(cmpStr,128,"%s - %iLbs - Worth $%i",FishName[playerid][f], FishWeight[playerid][f], tmpVal);
									if(strcmp(cmpStr,inputtext,true) == 0)
									{
										slot = f;

										new query [ 256 ] ;
										mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fishslot%i = 'None', player_fishweight%i = -1 WHERE player_id = %d", f + 1, f + 1, Character[playerid][E_CHARACTER_ID]);
										mysql_tquery(mysql, query);
										break;
									}
								}

								new fishValue = 3 * FishWeight[playerid][slot];
								format(gstr, sizeof(gstr),"You Have Received $%i For Selling The %iLb %s.",fishValue,FishWeight[playerid][slot],FishName[playerid][slot]);
								SendServerMessage ( playerid, COLOR_LIGHTBLUE, "Sold Fish", "DEDEDE", gstr );

								FishWeight[playerid][slot] = -1;
								FishName[playerid][slot][0] = EOS;
								GivePlayerCash(playerid, fishValue, "Sell fish");
								return 1;
							}
						}
					}

					gstr[0] = EOS;
					for(new f = 0; f < 5; f++)
					{
						if(FishWeight[playerid][f] != -1)
						{
							new fishValue = 3 * FishWeight[playerid][f];
							format(sgstr, sizeof(sgstr), "%s - %iLbs - Worth $%i\n", FishName[playerid][f], FishWeight[playerid][f], fishValue);
							strcat(gstr, sgstr);
						}
					}

					strcat(gstr, "\nSell All");

					Dialog_ShowCallback ( playerid, using inline FishSell, DIALOG_STYLE_LIST, "Sell Fish", gstr, "Sell", "Cancel" );
					return 1;
				} 

				else continue ;
			}

			else continue ;
		}

		else continue ;
	}
	SendClientMessage(playerid, COLOR_ERROR, "You need to be at a bait shop to sell fish!");
	return 1;
}

// /putback [slot] - releases one fish back into the water.
CMD:putback(playerid, params[])
{
	new gstr[1024];
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	if(GetPVarInt(playerid, "IsFishing") == 1)
		return SendClientMessage(playerid, COLOR_ERROR, "You are currently fishing.");

	new vehicleid = Vehicle_GetClosestEntity(playerid);

    if ( IsPlayerInAnyVehicle(playerid))	    
		return SendClientMessage(playerid, COLOR_ERROR, "You can't do this whilst in a vehicle!");

	new atFishSpot = 0;
	if(IsAtFishPlace(playerid) || IsABoat(vehicleid)) atFishSpot = 1;
	if(atFishSpot == 0) return SendClientMessage(playerid, COLOR_ERROR, "You must be at a fishing spot or on a boat to put fish back.");

	if(FishWeight[playerid][0] == -1 && FishWeight[playerid][1] == -1 && FishWeight[playerid][2] == -1 && FishWeight[playerid][3] == -1 && FishWeight[playerid][4] == -1) return SendClientMessage(playerid, COLOR_ERROR, "You have no fish.");

	new SlotToUse;
	if(sscanf(params, "i", SlotToUse)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /putback [fish number] *Hint: Uses /fishes for fish numbers*");
	if(SlotToUse > 5 || SlotToUse < 1) return SendClientMessage(playerid, COLOR_ERROR, "Invalid Fish Id! (1 to 5 only)");

	SlotToUse --;
	if(FishWeight[playerid][SlotToUse] == -1) return SendClientMessage(playerid, COLOR_ERROR, "No fish in that slot.");

	format(gstr, sizeof(gstr),"throws a %s back in the water. *",FishName[playerid][SlotToUse]);
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
	format(gstr, sizeof(gstr),"You put the %i Lb %s back into the water.",FishWeight[playerid][SlotToUse],FishName[playerid][SlotToUse]);
	SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);

	FishWeight[playerid][SlotToUse] = -1;
	FishName[playerid][SlotToUse][0] = EOS;

	new query[256], str[32];
	for(new x = 0; x < 5; x++)
	{
		format(str, sizeof(str), "player_fishslot%i", x + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = '%s' WHERE player_id = %d", str, FishName[playerid][x], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		format(str, sizeof(str), "player_fishweight%i", x + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = %d WHERE player_id = %d", str, FishWeight[playerid][x], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);
	}
	return true;
}

// /putallback - releases every fish you are carrying.
CMD:putallback(playerid, params[])
{
	new gstr[1024];
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	if(GetPVarInt(playerid, "IsFishing") == 1)
		return SendClientMessage(playerid, COLOR_ERROR, "You are currently fishing.");

	new vehicleid = Vehicle_GetClosestEntity(playerid);

    if ( IsPlayerInAnyVehicle(playerid))	    
		return SendClientMessage(playerid, COLOR_ERROR, "You can't do this whilst in a vehicle!");

	new atFishSpot = 0;
	if(IsAtFishPlace(playerid) || IsABoat(vehicleid)) atFishSpot = 1;
	if(atFishSpot == 0) return SendClientMessage(playerid, COLOR_ERROR, "You must be at a fishing spot or on a boat to put fish back.");

	if(FishWeight[playerid][0] == -1 && FishWeight[playerid][1] == -1 && FishWeight[playerid][2] == -1 && FishWeight[playerid][3] == -1 && FishWeight[playerid][4] == -1) return SendClientMessage(playerid, COLOR_ERROR, "You have no fish.");

	new query[256], str[32];
	new FishCount = 0;
	for(new F = 0; F < 5; F++)
	{
		if(FishWeight[playerid][F] != -1)
		{
			FishWeight[playerid][F] = -1;
			FishName[playerid][F][0] = EOS;

			format(str, sizeof(str), "player_fishslot%i", F + 1);
			mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = '%s' WHERE player_id = %d", str, FishName[playerid][F], Character[playerid][E_CHARACTER_ID]);
			mysql_tquery(mysql, query);

			format(str, sizeof(str), "player_fishweight%i", F + 1);
			mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = %d WHERE player_id = %d", str, FishWeight[playerid][F], Character[playerid][E_CHARACTER_ID]);
			mysql_tquery(mysql, query);

			FishCount++;
		}
	}
	format(gstr, sizeof(gstr),"throws %i fish back in the water. *", FishCount);
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
	format(gstr, sizeof(gstr),"You put %i fish back into the water.",FishCount);
	SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);
	return true;
}

// Returns true if the player is inside a fishing area.
stock IsAtFishPlace(playerid)
{
	if(IsPlayerConnected(playerid)) {
		for(new x; x < FishAreaCount; x++) {
			if(IsPlayerInDynamicArea(playerid, FishArea[x]))
			{
				return 1;
			}
		}
	}
	return 0;
}

forward IsFishing(playerid);
// Starts waiting for a bite: the player is frozen, uses a bait, and a timer decides when a fish
// bites.
public IsFishing(playerid)
{
	TogglePlayerControllable(playerid, false);
	//ApplyAnimation(playerid,"SAMP","FishingIdle",4.1,1,0,0,0,0,1);
	SetPVarInt(playerid, "HookedFish", SetTimerEx("HookedFish", 10000, false, "i", playerid));
	Character [ playerid ] [ E_CHARACTER_BAIT ] --;

	new query [ 256 ] ;
	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_bait = %d WHERE player_id = %d", 
		Character [ playerid ] [ E_CHARACTER_BAIT ], 
		Character [ playerid ] [ E_CHARACTER_ID ] ) ;

	mysql_tquery(mysql, query);
	return 1;
}

forward HookedFish(playerid);
// Timer: a fish is hooked - the player has a few seconds to press Y to reel it in.
public HookedFish(playerid)
{
	//ApplyAnimation(playerid,"SAMP","fish_struggle",4.1,1,0,0,0,0,1);
	SendClientMessage(playerid, COLOR_YELLOW, "Fish hooked! Press 'Y' to reel in.");
	SetPVarInt(playerid, "FishHooked", 1);
	SetPVarInt(playerid, "FishEscape", SetTimerEx("FishEscape", 5000, false, "i", playerid));
	return 1;
}

forward FishEscape(playerid);
// Timer: the player was too slow and the fish escapes.
public FishEscape(playerid)
{
	StopFishing(playerid);
	SendClientMessage(playerid, COLOR_WARNING, "Fish got away.");
	return 1;
}

forward StopFishing(playerid);
// Ends fishing and clears the fishing state.
public StopFishing(playerid)
{
	DeletePVar(playerid, "IsFishing");
	DeletePVar(playerid, "FishEscape");
	DeletePVar(playerid, "HookedFish");
	DeletePVar(playerid, "FishingType");
	TogglePlayerControllable(playerid, true);
	RemovePlayerAttachedObject(playerid, 9);

    ApplyAnimation(playerid, "CARRY", "crry_prtial", 1.0, 0, 0, 0, 0, 0);
    TRP_ClearAnimations(playerid);
    cmd_stopanim(playerid, "");
	return 1;
}

forward CaughtFish(playerid);
// Works out what the player caught (fish type, weight or junk) and adds it to their slots.
public CaughtFish(playerid)
{
	new gstr[256];
	new Caught;
    Caught = random(16);

	if(GetPVarInt(playerid, "FishingType") == 1) // Pier
	{
		if(Caught == 1)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in some seaweed. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 3)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a rusty can. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 4)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in an old smashed TV. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 5)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a flat car tire. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 7)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a propeller. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 8)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a broken fire extinguisher. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 9)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in glass bottle. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 11)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a dead fish. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 13)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a plank of wood. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 14)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a Cola bottle. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 15)
		{
			new CashRand = random(500);
			format(gstr, sizeof(gstr),"You have reeled in a bag of money. You found $%i.",CashRand);
			SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);
			GivePlayerCash(playerid,CashRand, "Fishing job bag of money");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}

		new FishNameId,WeightRegion,Weight;
		FishNameId = random(sizeof(FishNames));
		WeightRegion = random(3);

		if(WeightRegion == 0)
		{
			format(gstr, sizeof(gstr),"has caught a small sized %s. *",FishNames[FishNameId]);
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
			Weight = random(7) + random(7) + 1; //max 15
		}
		else if(WeightRegion == 1)
		{
			format(gstr, sizeof(gstr),"has caught a reasonably sized %s. *",FishNames[FishNameId]);
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
			Weight = random(10) + random(10) + 10; //max 30
		}
		else if(WeightRegion == 2)
		{
			format(gstr, sizeof(gstr),"has caught a large sized %s. *",FishNames[FishNameId]);
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
			Weight = random(20) + random(20) + 20; //max 60
		}

		format(gstr, sizeof(gstr),"You have caught a %s weighing %i Lbs.",FishNames[FishNameId],Weight);
		SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);

		if(Weight > Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ])
		{
			format(gstr, sizeof(gstr),"You have beaten your biggest fish record: Was %i Lbs, Now %i Lbs",Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH],Weight);
			SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);
			Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ] = Weight;
			
			new query [ 256 ] ;
			mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_biggestfish = %d WHERE player_id = %d", 
				Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ], 
				Character [ playerid ] [ E_CHARACTER_ID ] ) ;

			mysql_tquery(mysql, query);
		}

		new SlotToUse = -1;
		if(FishWeight[playerid][0] == -1) SlotToUse = 0;
		else if(FishWeight[playerid][1] == -1) SlotToUse = 1;
		else if(FishWeight[playerid][2] == -1) SlotToUse = 2;
		else if(FishWeight[playerid][3] == -1) SlotToUse = 3;
		else if(FishWeight[playerid][4] == -1) SlotToUse = 4;
		else {
			StopFishing(playerid);
			return SendClientMessage(playerid, COLOR_ERROR, "You don't have space for any more fish.");
		}

		FishWeight[playerid][SlotToUse] = Weight;

		format(gstr, sizeof(gstr), "You put the %s into fish slot %i. Type /fishes to view all your caught fish.",FishNames[FishNameId],SlotToUse+1);
		SendClientMessage(playerid, COLOR_LIGHTBLUE, gstr);
		StopFishing(playerid);
		new str[32];
		new query [ 256 ] ;

		format(FishName[playerid][SlotToUse], 12, FishNames[FishNameId]);

		format(str, sizeof(str), "player_fishslot%i", SlotToUse + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = '%s' WHERE player_id = %d", str, FishNames[FishNameId], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		format(str, sizeof(str), "player_fishweight%i", SlotToUse + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = %d WHERE player_id = %d", str, FishWeight[playerid][SlotToUse], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);
		return 1;
	}

	if(GetPVarInt(playerid, "FishingType") == 2) // Boat
	{
		if(Caught <= 5)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in some seaweed. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 6)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a rusty can. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 7)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a flat car tire. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 8)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "You have reeled in a dead fish. You throw it back in.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 9)
		{
			SendClientMessage(playerid, COLOR_LIGHTBLUE, "Line Snapped! You put a new Line on the Rod.");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}
		else if(Caught == 15)
		{
			new CashRand = random(1000);
			format(gstr, sizeof(gstr),"You have reeled in a bag of money. You found $%i.",CashRand);
			SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);
			GivePlayerCash(playerid,CashRand, "Fishing job bag of money");
			TogglePlayerControllable(playerid,1);
			StopFishing(playerid);
			return true;
		}

		new Weight, WeightRegion, FishNameId, whalechance, bool:haswhale = false,
			ReeferFishNames[5][12] = {"Shark", "Mackerel", "Swordfish", "Bass", "Pollack"};

		FishNameId = random(sizeof(ReeferFishNames));
		WeightRegion = random(5);
		whalechance = random(1500);

		if(whalechance == 69)
		{
			format(gstr, sizeof(gstr),"has caught a colossal sized whale. *");
			ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
			Weight = random(50000) + random(50000) + 50000; //max 150,000

			haswhale = true;
			format(gstr, sizeof(gstr), "You have caught a whale weighing %i Lbs.", Weight);
			SendClientMessage(playerid, COLOR_LIGHTBLUE, gstr);
		}

		if(!haswhale)
		{
			if(WeightRegion == 0 || WeightRegion == 1)
			{
				format(gstr, sizeof(gstr),"has caught a large sized %s. *",ReeferFishNames[FishNameId]);
				ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
				Weight = random(20) + random(15) + 15; //max 30ish
			}
			else if(WeightRegion == 2 || WeightRegion == 3)
			{
				format(gstr, sizeof(gstr),"has caught a very large sized %s. *",ReeferFishNames[FishNameId]);
				ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
				Weight = random(25) + random(25) + 15; //max 60ish
			}
			else if(WeightRegion == 4)
			{
				format(gstr, sizeof(gstr),"has caught a MASSIVE %s. *",ReeferFishNames[FishNameId]);
				ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", gstr);
				Weight = random(50) + random(50) + 50; //max 150
			}
			format(gstr, sizeof(gstr), "You have caught a %s weighing %i Lbs.",ReeferFishNames[FishNameId],Weight);
			SendClientMessage(playerid, COLOR_LIGHTBLUE, gstr);
		}

		if(Weight > Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ])
		{
			format(gstr, sizeof(gstr),"You have beaten your biggest fish record: Was %i Lbs, Now %i Lbs",Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH],Weight);
			SendClientMessage(playerid,COLOR_LIGHTBLUE,gstr);
			Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ] = Weight;
			
			new query [ 256 ] ;
			mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_biggestfish = %d WHERE player_id = %d", 
				Character [ playerid ] [ E_CHARACTER_BIGGEST_FISH ], 
				Character [ playerid ] [ E_CHARACTER_ID ] ) ;

			mysql_tquery(mysql, query);
		}

		new SlotToUse = -1;
		if(FishWeight[playerid][0] == -1) SlotToUse = 0;
		else if(FishWeight[playerid][1] == -1) SlotToUse = 1;
		else if(FishWeight[playerid][2] == -1) SlotToUse = 2;
		else if(FishWeight[playerid][3] == -1) SlotToUse = 3;
		else if(FishWeight[playerid][4] == -1) SlotToUse = 4;
		else {
			StopFishing(playerid);
			return SendClientMessage(playerid, COLOR_ERROR, "You don't have space for any more fish.");
		}

		FishWeight[playerid][SlotToUse] = Weight;
		format(FishName[playerid][SlotToUse], 12, ReeferFishNames[FishNameId]);

		new str[32];
		new query [ 256 ] ;

		format(str, sizeof(str), "player_fishslot%i", SlotToUse + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = '%s' WHERE player_id = %d", str, ReeferFishNames[FishNameId], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		format(str, sizeof(str), "player_fishweight%i", SlotToUse + 1);
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET %s = %d WHERE player_id = %d", str, FishWeight[playerid][SlotToUse], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		format(gstr, sizeof(gstr), "You put the %s into fish slot %i. Type /fishes to view all your caught fish.",ReeferFishNames[FishNameId],SlotToUse+1);
		SendClientMessage(playerid, COLOR_LIGHTBLUE, gstr);
		StopFishing(playerid);
	}

	return 1;
}

// Key handler: pressing Y while a fish is hooked reels it in.
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {

	// Fishing
    if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
        if(GetPVarInt(playerid, "FishHooked") == 1) {
            DeletePVar(playerid, "FishHooked");
            KillTimer(GetPVarInt(playerid, "FishEscape"));
            ApplyAnimation(playerid,"SAMP","fish_pull",4.1,1,0,0,0,0,1);
            SetTimerEx("CaughtFish", 1500, 0, "i", playerid);
            return 1;
        }
    }

	#if defined fishing_OnPlayerKeyStateChange
		return fishing_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange fishing_OnPlayerKeyStateChange
#if defined fishing_OnPlayerKeyStateChange
	forward fishing_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
#endif
