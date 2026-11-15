// ============================================================================
// File: property/utils/robbery.pwn
// Shop robberies: clerks (actors) can be robbed with a weapon. Notifies police and tracks the
// cooldown (ActorRobbery_LoadEntities).
// ============================================================================

#if !defined KEY_AIM
	#define KEY_AIM  128
#endif

#define MAX_ROBBERY_ACTORS		(50)

#define TYPE_SUCCESS        (0)
#define TYPE_FAILED         (1)
#define TYPE_UNFINISHED     (2)

#define MIN_MONEY_ROB       1500
#define MAX_MONEY_ROB       7500
#define ROBBERY_WAIT_TIME   (5)
#define ROBBERY_CD_TIME     (15)
#define ROBBERY_CD_FINAL 	(90)

enum E_ACTOR_ROBBERY_DATA
{
	actor_skin,
	Float:actor_x,
	Float:actor_y,
	Float:actor_z,
	Float:actor_ang,
	actor_vw,
	money_min,
	money_max,

	bool:actor_created,
	actor_robbedRecently
}
static 
	robbery_data[MAX_ROBBERY_ACTORS][E_ACTOR_ROBBERY_DATA],
	i_actor = 0;

// Loads the robbable shop actors at start-up.
ActorRobbery_LoadEntities() {
	// Enex Robbable Actors
	CreateActorRobbery(184,		2329.3772,8.4197,26.5211,265.1490); // Palomino Diner
}

forward RunActorAnimationSequence(playerid, actorid, animation_pattern);
forward OnPlayerStartRobbery(playerid, actorid, robbed_recently);
forward OnPlayerFinishRobbery(playerid, actorid, robbedmoney, type);

// Returns true if the player is on a robbery cooldown.
Robbery_OnPlayerCooldown(playerid) {

	if ( Character [ playerid ] [ E_CHARACTER_ROBBERY_COOLDOWN ] ) {

		new query [ 128 ] ;

		if ( -- Character [ playerid ] [ E_CHARACTER_ROBBERY_COOLDOWN ] <= 0 ) {

			mysql_format(mysql, query, sizeof ( query ), "UPDATE characters SET player_robbery_cooldown = 0 WHERE player_id = %d",

				Character [ playerid ] [ E_CHARACTER_ID ] 
			);

		}	

		else {
			mysql_format(mysql, query, sizeof ( query ), "UPDATE characters SET player_robbery_cooldown = %d WHERE player_id = %d",

				Character [ playerid ] [ E_CHARACTER_ROBBERY_COOLDOWN ], Character [ playerid ] [ E_CHARACTER_ID ] 
			);
		}

		mysql_tquery(mysql, query);
	}

	return true ;
}

// Called when a player starts robbing a shop actor.
public OnPlayerStartRobbery(playerid, actorid, robbed_recently)
{
    new string[128];
    if(robbed_recently)
    {
        SendServerMessage ( playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", "This store has been robbed recently, please try again later!");
        return 0;
    }

    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**", sprintf("has begun robbing the property."), .annonated=true);

	new Float: x, Float: y, Float: z;
	GetActorPos(actorid, x, y, z);

	new interior = GetPlayerInterior(playerid);
	new world = GetActorVirtualWorld(playerid);

	switch ( random ( 5 ) ) {

		case 0: ProxDetectorXYZ ( x, y, z, interior, world, 15.0, 0xDEDEDEFF, "Shopkeeper says: W-woah! Don't point that thing at me! I ain't done nuffin'!");
		case 1: ProxDetectorXYZ ( x, y, z, interior, world, 15.0, 0xDEDEDEFF, "Shopkeeper says: Please señor don't shoot me, I got a wife and kids...");
		case 2: ProxDetectorXYZ ( x, y, z, interior, world, 15.0, 0xDEDEDEFF, "Shopkeeper says: Don't shoot! Take the cash, it ain't mine anyway!");
		case 3: ProxDetectorXYZ ( x, y, z, interior, world, 15.0, 0xDEDEDEFF, "Shopkeeper says: You makin' a big mistake.. Just take the cash and don't shoot!");
		case 4: ProxDetectorXYZ ( x, y, z, interior, world, 15.0, 0xDEDEDEFF, "Shopkeeper says: Please don't take my money! I need to feed my children!");
	}

	Robbery_SendPoliceAlert(actorid, playerid) ;


    format ( string, sizeof ( string ), "[!!][Robbery] (%d) %s has started robbing actor ID %d ",
    	playerid, ReturnRPName ( playerid ), actorid
    ) ;

    SendAdminMessage ( string );

    return 1;
}


// Called when a robbery finishes (pays out and alerts police).
public OnPlayerFinishRobbery(playerid, actorid, robbedmoney, type) {
    new string[128];

	new Float: x, Float: y, Float: z;
	GetActorPos(actorid, x, y, z);

    switch(type) {
        case TYPE_SUCCESS: {
            format(string, sizeof(string), "You managed to steal %s from the property.", IntegerWithDelimiter(robbedmoney));
       		SendServerMessage ( playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", string);

			ProxDetectorXYZ ( x, y, z, GetPlayerInterior(playerid), GetActorVirtualWorld(actorid), 20.0, 0xDEDEDEFF, sprintf("** The cashier has given %s $%s out of the till.", ReturnRPName(playerid), IntegerWithDelimiter(robbedmoney)));
 
            format(string, sizeof(string), "~w~You stole~n~~g~$%i", robbedmoney);
            GameTextForPlayer(playerid, string, 6000, 1);   

            GivePlayerCash(playerid, robbedmoney, "Store robbery payout");
			//AddPlayerRespect(playerid, 2);
			AddPlayerFear(playerid, 2);
        }/*
        case TYPE_FAILED: {
        	format(string, sizeof(string), "* The cashier refuses to give %s the till's money.", ReturnPlayerNameData(playerid));
    		ProxDetectorActor(actorid, 20.0, COLOR_ACTION, string, .streamer=false);

       		SendServerMessage ( playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", "The cashier refused to give you the money and triggered the alarm! Run!");
            GameTextForPlayer(playerid, "~r~Robbery Failed", 6000, 1);
        }*/
        case TYPE_UNFINISHED: {    

			
			ProxDetectorXYZ ( x, y, z, GetPlayerInterior(playerid), GetActorVirtualWorld(actorid), 20.0, 0xDEDEDEFF, "** The cashier triggers the alarm and calls 911 because the robber ran off.");
   
        	SendServerMessage ( playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", "You have gone too far away from the cashier, he managed to call 911! RUN!");
            GameTextForPlayer(playerid, "~y~Robbery Cancelled", 6000, 1);
			//AddPlayerRespect(playerid, -2);
			AddPlayerFear(playerid, -2);
        }
    }

    format ( string, sizeof ( string ), "[!!][Robbery] (%d) %s has robbed actor %d - result %d - haul: $%s",
    	playerid, ReturnRPName ( playerid ), actorid, type, IntegerWithDelimiter ( robbedmoney ) 
    ) ;

    SendAdminMessage ( string );

    return 1;
}


// Creates a shop actor that can be robbed.
stock CreateActorRobbery(skinid, Float:x, Float:y, Float:z, Float:ang, actor_vwid = 0, r_moneymin = MIN_MONEY_ROB, r_moneymax = MAX_MONEY_ROB)
{

	if ( skinid == 6 ) {

		return -1 ;
	}

	new actorid = GetActorFreeID();

	if(actorid == -1)
	{
		print("ERROR: MAX_ROBBERY_ACTOR reached, increase the limit size.");
		return -1;
	}

	CreateActor(skinid, x, y, z, ang);
	SetActorVirtualWorld(actorid, actor_vwid);

	robbery_data[actorid][actor_created] = true;
	robbery_data[actorid][actor_skin] = skinid;
	robbery_data[actorid][actor_x] = x;
	robbery_data[actorid][actor_y] = y;
	robbery_data[actorid][actor_z] = z;
	robbery_data[actorid][actor_ang] = ang;
	robbery_data[actorid][actor_vw] = actor_vwid;
	robbery_data[actorid][money_min] = r_moneymin;
	robbery_data[actorid][money_max] = r_moneymax;

	return (++ i_actor - 1); 
}

// Reads back the data of a robbery actor.
stock GetActorRobberyData(actorid, &skinid, &Float:x, &Float:y, &Float:z, &Float:ang, &actor_vwid, &r_moneymin, &r_moneymax)
{
	if(actorid == INVALID_ACTOR_ID)
		return 1;

	skinid = robbery_data[actorid][actor_skin];
	x = robbery_data[actorid][actor_x];
	y = robbery_data[actorid][actor_y];
	z = robbery_data[actorid][actor_z] ;
	ang = robbery_data[actorid][actor_ang] ;
	actor_vwid = robbery_data[actorid][actor_vw];
	r_moneymin = robbery_data[actorid][money_min];
	r_moneymax = robbery_data[actorid][money_max];
	return 1;
}

// Finds a free slot for a robbery actor.
static GetActorFreeID() 
{
	for(new i = 0; i < MAX_ROBBERY_ACTORS; i++) 
	{ 
		if(!robbery_data[i][actor_created]) return i;
	}
	return -1;
}

// Timer: resets the alarm sound after a robbery.
timer ActorRobbery_ResetSound[60000](playerid, Float: x, Float: y, Float: z ) {
	
	if (!IsPlayerConnected(playerid))
        return 0;

	PlayerPlaySound ( playerid, 0, x, y, z ) ;
	printf("Reset robbery sound for %s (%d), at %0.3f, %0.3f, %0.3f.",
		TEMP_ReturnPlayerName(playerid), playerid, x, y, z ) ;

	return true ;
}

// Plays the actor's animation steps during a robbery.
public RunActorAnimationSequence(playerid, actorid, animation_pattern)
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	switch(animation_pattern)
	{
		case 0:
		{
			ClearActorAnimations(actorid);
			ApplyActorAnimation(actorid, "SHOP", "SHP_Rob_HandsUp", 4.1, 0, 1, 1, 1, 0);
		
			//SetTimerEx("RunActorAnimationSequence", 1000 * ROBBERY_WAIT_TIME, false, "iii", playerid, actorid, 1);
			SetTimerEx("RunActorAnimationSequence", 2500 * ROBBERY_WAIT_TIME, false, "iii", playerid, actorid, 1);
		
		
			foreach(new i: Player) {
				if ( ! IsPlayerLogged ( i ) || ! IsPlayerSpawned ( i ) ) {

					continue ;
				}

				if ( IsPlayerInRangeOfPoint(i, 25.0, x, y, z ) ) {
					PlayerPlaySound(i, 3401, x, y, z);
					//#warning May cause overflow and crash server...
					defer ActorRobbery_ResetSound(playerid, x, y, z ) ;
				}
			}
		}
		case 1:
		{
			if(!IsPlayerInRangeOfPoint(playerid, 7.5, robbery_data[actorid][actor_x], robbery_data[actorid][actor_y], robbery_data[actorid][actor_z]))
			{
				OnPlayerFinishRobbery(playerid, actorid, 0, TYPE_UNFINISHED);
			}
			else 
			{

				ClearActorAnimations(actorid);
				ApplyActorAnimation(actorid, "SHOP", "SHP_Rob_GiveCash", 4.1, 1, 1, 1, 1, 0);

				ProxDetectorXYZ ( x, y, z, GetPlayerInterior(playerid), GetActorVirtualWorld(actorid), 20.0, 0xDEDEDEFF, "* The cashier begins putting the till money in a bag.");
       			SendServerMessage ( playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", "The cashier is doing his best to fill the bag. Please wait for them to finish.");

				SetTimerEx("RunActorAnimationSequence", 2500 * ROBBERY_CD_TIME, false, "iii", playerid, actorid, 2);
			}
		}
		case 2:
		{
			if(!IsPlayerInRangeOfPoint(playerid, 7.5, robbery_data[actorid][actor_x], robbery_data[actorid][actor_y], robbery_data[actorid][actor_z]))
			{
				OnPlayerFinishRobbery(playerid, actorid, 0, TYPE_UNFINISHED);
			}
			else 
			{
				new base_money = (random(robbery_data[actorid][money_max] - robbery_data[actorid][money_min]) + robbery_data[actorid][money_min]);
				new fnr_level = GetPlayerFnRLevel(playerid);
				new bonus_percentage = 0;

				switch(fnr_level)
				{
					case 1..2: bonus_percentage = 0;      	// normal
					case 3..4: bonus_percentage = 15;      	// +15%
					case 5..6: bonus_percentage = 30;     	// +30%
					case 7..8: bonus_percentage = 50;     	// +50%
					case 9..10: bonus_percentage = 70;    	// +70%
					case 11: bonus_percentage = 100;       	// +100%
				}

				new bonus_money = floatround(float(base_money) * float(bonus_percentage) / 100.0);
				new total_money = base_money + bonus_money;

				if(bonus_percentage > 0)
				{
					new string[128];
    				format(string, sizeof(string), "{BE2727}» Fear Bonus: {FFFFFF}+$%d (%d%% boost)", bonus_money, bonus_percentage);
					SendClientMessage(playerid, -1, string);
				}

				OnPlayerFinishRobbery(playerid, actorid, total_money, TYPE_SUCCESS);
			}
		
			//new 
			//robberyChance = random(100);
			//if(robberyChance > 50)
			//{
			
			//}
			//else OnPlayerFinishRobbery(playerid, actorid, 0, TYPE_FAILED);
		}
		case 3:
		{
			// Force hard reset anims:
			ClearActorAnimations(actorid);
			ApplyActorAnimation(actorid, "PED", "IDLE_STANCE", 4.0, 0, 0, 0, 0, 1);
			ApplyActorAnimation(actorid, "PED", "IDLE_CHAT", 4.0, 0, 0, 0, 0, 1);
			ApplyActorAnimation(actorid, "PED", "WALK_PLAYER", 4.0, 0, 0, 0, 0, 1);

			PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
		}

	}
	return 1;
}

// Key handler: aiming at a shop actor starts a robbery.
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_AIM) == KEY_AIM && GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
    {
        switch (GetPlayerWeapon(playerid))
        {
            case 22 .. 33:
            {
                new actorid = GetPlayerCameraTargetActor(playerid);
                if (actorid == INVALID_ACTOR_ID || IsPlayerInAnyGovFaction(playerid))
                    return 1;

                if (robbery_data[actorid][actor_created])
                {
                    new query[128];

                    if (Character[playerid][E_CHARACTER_ROBBERY_COOLDOWN])
                    {
                        format(query, sizeof(query),
                            "You're on a robbing cooldown! Try again in %d seconds!",
                            Character[playerid][E_CHARACTER_ROBBERY_COOLDOWN]);

                        SendServerMessage(playerid, COLOR_PROPERTY, "Robbery", "DEDEDE", query);
                        return 0;
                    }

                    if (Character[playerid][E_CHARACTER_LEVEL] <= 1)
                    {
                        SendServerMessage(playerid, COLOR_PROPERTY, "Robbery", "DEDEDE",
                            "You must be at least level two to rob a store.");
                        return 0;
                    }

                    // If store recently robbed, let the callback handle the message
                    if (gettime() - robbery_data[actorid][actor_robbedRecently] < 60 * ROBBERY_CD_FINAL)
                    {
                        return OnPlayerStartRobbery(playerid, actorid, 1);
                    }

                    // ---- REQUIRE AT LEAST ONE ON-DUTY POLICE ----
					new bool:policeOnDuty = false;

					foreach (new idx : Player)
					{
						if (!IsPlayerInPoliceFaction(idx)) continue;
						if (!PlayerVar[idx][E_PLAYER_FACTION_DUTY]) continue;

						policeOnDuty = true;
						break;
					}

					if (!policeOnDuty)
					{
						SendServerMessage(playerid, COLOR_PROPERTY, "Robbery", "DEDEDE",
							"You cannot rob this store unless at least one police officer is on duty.");
						return 0;
					}
					// ---------------------------------------------

                    if (!OnPlayerStartRobbery(playerid, actorid, 0))
                    {
                        return 0;
                    }

                    // Only reaches here if robbery is allowed

                    robbery_data[actorid][actor_robbedRecently] = gettime();
                    Character[playerid][E_CHARACTER_ROBBERY_COOLDOWN] = 1800; // 30 min

                    mysql_format(mysql, query, sizeof(query),
                        "UPDATE characters SET player_robbery_cooldown = %d WHERE player_id = %d",
                        Character[playerid][E_CHARACTER_ROBBERY_COOLDOWN],
                        Character[playerid][E_CHARACTER_ID]);

                    mysql_tquery(mysql, query);

                    RunActorAnimationSequence(playerid, actorid, 0);
                    return 1;
                }
            }
        }
    }

    #if defined actorrob_OnPlayerKeyStateChange
        return actorrob_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange actorrob_OnPlayerKeyStateChange
#if defined actorrob_OnPlayerKeyStateChange
	forward actorrob_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
#endif
