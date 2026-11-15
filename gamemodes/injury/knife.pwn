// ============================================================================
// File: injury/knife.pwn
// Knife damage sync fix (OnPlayerGiveDamage/TakeDamage) so melee hits register consistently.
// ============================================================================

// Hook point for initialising the knife sync fix.
public OnGameModeInit()
{
	// No knife-sync plugin is needed: open.mp's own sync layer handles it.

	#if defined knife_OnGameModeInit
		return knife_OnGameModeInit();
	#else
		return 1;
	#endif
}
#if defined _ALS_OnGameModeInit
	#undef OnGameModeInit
#else
	#define _ALS_OnGameModeInit
#endif

#define OnGameModeInit knife_OnGameModeInit
#if defined knife_OnGameModeInit
	forward knife_OnGameModeInit();
#endif


forward WC_SecondKnifeAnim(playerid);

// Timer callback that plays the second part of the knife-kill animation.
public WC_SecondKnifeAnim(playerid)
{
    ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Die", 4.1, 0, 1, 1, 1, 3000, 1);
    return 1;
}

// Handles a knife hit given: applies the knife-kill animation and damage.
KnifeSync_OnPlayerGiveDamage(playerid, damagedid, Float:amount, weaponid) {
	if (PlayerVar [ damagedid ] [ E_PLAYER_INJUREDMODE ] ) {
		return 0;
	}

	if (PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {
		return 0;
	}

	// From stealth knife, can be any weapon
	if (_:amount == _:1833.33154296875) {
		return 0;
	}

	if (weaponid == WEAPON_KNIFE) {
		if (_:amount == _:0.0) {

			ClearAnimations(damagedid, 1);
			Injury_ApplyAnimation(damagedid, "KNIFE", "KILL_Knife_Ped_Damage", _, 5200);
			SetTimerEx("WC_SecondKnifeAnim", 2200, false, "i", damagedid);

			//SendClientMessage(damagedid, -1, sprintf( "being knifed by %d", playerid));
			//SendClientMessage(playerid, -1, sprintf( "knifing %d", damagedid));

			new Float:x, Float:y, Float:z, Float:a;

			GetPlayerFacingAngle(damagedid, a);
			SetPlayerFacingAngle(playerid, a);
			KnifeSync_PosInFront(damagedid, -1.0, x, y, z);

			SetPlayerVelocity(damagedid, 0.0, 0.0, 0.0);
			SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);

			new forcesync = 2;
			new anim = GetPlayerAnimationIndex(playerid);
			if (anim > 747 && anim < 748) {
				//SendClientMessage(playerid, -1, sprintf( "applying knife anim for you too (current: %d)", GetPlayerAnimationIndex(playerid)));

				forcesync = 1;
			}

			ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Player", 4.1, 0, 1, 1, 0, 1800, forcesync);

			PlayerVar [ damagedid ] [ E_PLAYER_IS_TAZED ] = false ;
			PlayerVar [ damagedid ] [ E_PLAYER_IS_BEANBAGGED ] = false ;
			PlayerVar [ damagedid ] [ E_PLAYER_IS_TACKLED ] = false ;
			TogglePlayerControllable(damagedid, false);
			//defer Injury_ApplyDeathAnimation(damagedid, playerid, -1, weaponid);
			OnPlayerInjuryMode(damagedid, playerid, DEATHTYPE_KNIFED, weaponid);
			SetCharacterHealth(damagedid, 25.0);
			SetPlayerWound ( damagedid, WEAPON_KNIFE, 9, 100.0, playerid ) ;

	    	AddLogEntry(playerid, LOG_TYPE_DAMAGE, sprintf("knifed %s from behind", ReturnRPName ( damagedid )));

			return 0;
		}
	}

	return true ;
}

// Handles a knife hit taken: applies damage and the victim's animation.
KnifeSync_OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid)
{
	if(playerid==INVALID_PLAYER_ID || IsPlayerNPC(playerid)) return 0;
	// Being knifed client-side
	if (weaponid == WEAPON_KNIFE) {
		if (PlayerVar [ playerid ] [ E_PLAYER_INJUREDMODE ] ) {
			return 0;
		}

		if (PlayerVar [ issuerid ] [ E_PLAYER_INJUREDMODE ] ) {
			return 0;
		}

		// With the plugin, this part is never actually used (it can't happen)
		if (_:amount == _:0.0) {

			if (issuerid == INVALID_PLAYER_ID) {
				KnifeSync_ResyncPlayer(playerid);

				return 0;
			}

			// Make sure the values were not modified
			weaponid = WEAPON_KNIFE;
			amount = 0.0;

			Injury_ApplyAnimation(playerid, "KNIFE", "KILL_Knife_Ped_Die", _, 4000 - GetPlayerPing(playerid));

			SetCharacterHealth(playerid, 10);

			//SendClientMessage(playerid, -1, sprintf( "being knifed by %d", issuerid) );
			//SendClientMessage(issuerid, -1, sprintf( "knifing %d", playerid) );

			new Float:x, Float:y, Float:z, Float:a;

			GetPlayerFacingAngle(playerid, a);
			SetPlayerFacingAngle(issuerid, a);
			KnifeSync_PosInFront(playerid, -1.0, x, y, z);

			SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);
			SetPlayerVelocity(issuerid, 0.0, 0.0, 0.0);

			/*
			new forcesync = 2;

			if (GetPlayerAnimationIndex(issuerid) != 747) {
				//SendClientMessage(issuerid, -1, sprintf( "applying knife anim for you too (current: %d)", GetPlayerAnimationIndex(issuerid)));

				forcesync = 1;
			}*/

			return 0;
		}
	}

	return true ;
}

// Applies an injury animation while taking care of any special action the player is in.
Injury_ApplyAnimation(playerid, const animlib[32], const animname[32], anim_lock = 0, anim_freeze = 1 )
{
	new action = GetPlayerSpecialAction(playerid);

	if (action && action != SPECIAL_ACTION_DUCK) {
		if (action == SPECIAL_ACTION_USEJETPACK) {
			ClearAnimations(playerid);
		}

		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

		if (action == SPECIAL_ACTION_USEJETPACK) {
			new Float:vx, Float:vy, Float:vz;
			GetPlayerVelocity(playerid, vx, vy, vz);
			SetPlayerVelocity(playerid, vx, vy, vz);
		}
	}

	if (animlib[0] && animname[0]) {
		ApplyAnimation(playerid, animlib, animname, 4.1, 0, anim_lock, anim_lock, anim_freeze, 0, 1);
	}

}

// Returns a position in front of the player at a given distance.
KnifeSync_PosInFront(playerid, Float:distance, &Float:x, &Float:y, &Float:z)
{
	new Float:a;

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, a);

	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

// Re-syncs the player's position and skin after a knife attack.
KnifeSync_ResyncPlayer(playerid) {
	new Float:x, Float:y, Float:z, Float:r;

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, r);

	SetSpawnInfo(playerid, 0xFE, GetPlayerSkin(playerid), x, y, z, r, 0, 0, 0, 0, 0, 0);

	SpawnPlayer(playerid);
}
