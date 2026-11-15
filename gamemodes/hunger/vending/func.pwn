// ============================================================================
// File: hunger/vending/func.pwn
// Detects when a player walks up to or away from a vending machine.
// ============================================================================


// When a player walks up to a vending machine, shows the 'press Enter to buy' prompt.
public OnPlayerEnterDynamicArea(playerid, areaid) {


	if ( GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
		for (new i = 0; i < sizeof(sc_VendingMachines); i++) {

			if ( s_VendingMachineArea[i] == areaid ) {

				OnPlayerApproachVending(playerid, i ) ;
				break ;
			}

			else continue ;
		}
	}


	#if defined vending_OnPlayerEnterDynArea
		return vending_OnPlayerEnterDynArea(playerid, areaid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerEnterDynamicArea
	#undef OnPlayerEnterDynamicArea
#else
	#define _ALS_OnPlayerEnterDynamicArea
#endif

#define OnPlayerEnterDynamicArea vending_OnPlayerEnterDynArea
#if defined vending_OnPlayerEnterDynArea
	forward vending_OnPlayerEnterDynArea(playerid, areaid);
#endif


// When a player walks away from a vending machine, hides the prompt.
public OnPlayerLeaveDynamicArea(playerid, areaid) {

	if ( GetPlayerState(playerid) == PLAYER_STATE_ONFOOT) {
		for (new i = 0; i < sizeof(sc_VendingMachines); i++) {

			if ( s_VendingMachineArea[i] == areaid ) {

				OnPlayerLeaveVending(playerid) ;
				break ;
			}

			else continue ;
		}
	}

	#if defined vending_OnPlayerLeaveDynArea
		return vending_OnPlayerLeaveDynArea(playerid, areaid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerLeaveDynamicArea
	#undef OnPlayerLeaveDynamicArea
#else
	#define _ALS_OnPlayerLeaveDynamicArea
#endif

#define OnPlayerLeaveDynamicArea vending_OnPlayerLeaveDynArea
#if defined vending_OnPlayerLeaveDynArea
	forward vending_OnPlayerLeaveDynArea(playerid, areaid);
#endif
