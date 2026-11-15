// ============================================================================
// File: admin/fly.pwn
// /afly and /surfly toggle admin flight. Use forward to fly in the camera direction,
// Fire/Sprint to rise, Aim/Walk to descend and Jump to accelerate; Enter stops flight.
// Requires admin duty (or RCON admin). Health stays managed by the injury system.
// ============================================================================
#include <YSI_Coding\y_hooks>

new bool:OnFly[MAX_PLAYERS];
forward SurflyMode(playerid);

// Initialises flight state for a new connection.
hook OnPlayerConnect(playerid)
{
    OnFly[playerid] = false;
    return 1;
}

// Clears flight state before the player id is reused.
hook OnPlayerDisconnect(playerid, reason)
{
    OnFly[playerid] = false;
    return 1;
}

// Stops flight after death.
hook OnPlayerDeath(playerid, killerid, reason)
{
	OnFly[playerid] = false;
    return 1;
}

// Toggles flight for an on-duty administrator; run again to land.
CMD:afly(playerid, params[])
{
    #pragma unused params
    if (!OnFly[playerid] && !IsPlayerAdmin(playerid)
        && (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR || !PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]))
        return SendClientMessage(playerid, COLOR_ERROR, "Go on admin duty to use /afly.");
    if (!IsPlayerLogged(playerid) || !IsPlayerSpawned(playerid) || IsPlayerInAnyVehicle(playerid))
        return SendClientMessage(playerid, COLOR_ERROR, "You must be spawned and on foot to use /afly.");
    return SurflyMode(playerid);
}

// Alternate name for /afly.
CMD:surfly(playerid, params[]) return cmd_afly(playerid, params);

// Stops flight when Enter/Exit is pressed.
hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK)) // ENTER
	{
		if(OnFly[playerid]) SurflyMode(playerid);// disable surfly
	}
	return 1;
}

// Applies flight velocity and animation while flight is active.
hook OnPlayerUpdate(playerid)
{
    if (OnFly[playerid] && (!IsPlayerLogged(playerid) || !IsPlayerSpawned(playerid) || IsPlayerInAnyVehicle(playerid)))
    {
        SurflyMode(playerid);
        return 1;
    }
    if (OnFly[playerid] && !IsPlayerAdmin(playerid)
        && (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR || !PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]))
        SurflyMode(playerid);
	if(OnFly[playerid])
	{
		new k, ud,lrk;
		GetPlayerKeys(playerid,k,ud,lrk);
		new Float:v_x,Float:v_y,Float:v_z,
			Float:x,Float:y,Float:z;
		if(ud < 0)	// forward
		{
			GetPlayerCameraFrontVector(playerid,x,y,z);
			v_x = x+0.1;
			v_y = y+0.1;
		}
		if(k & 128)	// down
			v_z = -0.4;
		else if(k & KEY_FIRE)	// up
			v_z = 0.2;
		if(k & KEY_JUMP)	// fast
		{
			v_x *=4.0;
			v_y *=4.0;
			v_z *=4.0;
		}
		if(k & KEY_SPRINT)	// up
		{
			v_z = 0.2;
		}
		if(k & KEY_WALK)	// down
		{
			v_z = -0.4;
		}
		if(v_z == 0.0) 
			v_z = 0.025;
		SetPlayerVelocity(playerid,v_x,v_y,v_z);
		if(v_x == 0 && v_y == 0)
		{	
			if(GetPlayerAnimationIndex(playerid) == 959)	
				ApplyAnimation(playerid,"PARACHUTE","PARA_steerR",6.1,1,1,1,1,0,1);
		}
		else 
		{
			GetPlayerCameraFrontVector(playerid,v_x,v_y,v_z);
			GetPlayerCameraPos(playerid,x,y,z);
			AdminFly_LookAt(playerid,v_x*500.0+x,v_y*500.0+y);
			if(GetPlayerAnimationIndex(playerid) != 959)
				ApplyAnimation(playerid,"PARACHUTE","FALL_SkyDive_Accel",6.1,1,1,1,1,0,1);
		}
	}
	return 1;
}

// Enables or stops flight; leaves health and damage handling to the existing admin system.
public SurflyMode(playerid)
{
	new Float:x,Float:y,Float:z;
	if(OnFly[playerid])
	{
		OnFly[playerid] = false;
		GetPlayerPos(playerid,x,y,z);
		SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);
        ClearAnimations(playerid);
        PauseAC(playerid, 3);
		
		GameTextForPlayer(playerid, "~r~ADMIN~w~ FLY", 3000, 5);
	} else {
		OnFly[playerid] = true;
		GetPlayerPos(playerid,x,y,z);
		PauseAC(playerid, 3);
        ORP_SetPlayerPos(playerid,x,y,z+5.0,false);
		ApplyAnimation(playerid,"PARACHUTE","PARA_steerR",6.1,1,1,1,1,0,1);
		
		GameTextForPlayer(playerid, "~g~ADMIN~w~ FLY", 3000, 5);
		SendClientMessage(playerid, -1,
		"You have entered surfly mode. {FF0000}F / ENTER{FFFFFF} - exit flight mode");
		GameTextForPlayer(playerid, 
		"~r~<LMB/KEY_SPRINT>~w~ - increase height~n~\
		~r~<RMB/KEY_WALK>~w~ - reduce height~n~\
		~r~<KEY_JUMP>~w~ - accelerate", 5000, 5);
	}
	return true;
}

// Faces the player towards a point, guarding against a vertical direction.
stock AdminFly_LookAt(playerid,Float:x,Float:y)
{
	new Float:Px, Float:Py, Float: Pa;
	GetPlayerPos(playerid, Px, Py, Pa);
	if (floatabs(x - Px) < 0.001) {
        SetPlayerFacingAngle(playerid, y >= Py ? 0.0 : 180.0);
        return;
    }
    Pa = floatabs(atan((y-Py)/(x-Px)));
	if (x <= Px && y >= Py) 		Pa = floatsub(180.0, Pa);
	else if (x < Px && y < Py) 		Pa = floatadd(Pa, 180.0);
	else if (x >= Px && y <= Py)	Pa = floatsub(360.0, Pa);
	Pa = floatsub(Pa, 90.0);
	if (Pa >= 360.0) 
		Pa = floatsub(Pa, 360.0);
	SetPlayerFacingAngle(playerid, Pa);
	return;
}
