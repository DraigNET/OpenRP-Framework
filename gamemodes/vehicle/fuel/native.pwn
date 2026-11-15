// ============================================================================
// File: vehicle/fuel/native.pwn
// Fuel callbacks: entering pump areas, key presses and removing the default GTA pumps.
// ============================================================================

hook OnPlayerEditDynObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float: rx, Float: ry, Float:rz) {
	
	if ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELSTATION ] ) {

		if ( IsValidDynamicObject(PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ]) ) {

			if ( objectid == PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] ) {

				new Float: obj_x, Float: obj_y, Float: obj_z ;
				GetDynamicObjectPos ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ], obj_x, obj_y, obj_z ) ;
				if ( GetPlayerDistanceFromPoint(playerid, x, y, z ) > 7.5 ) {

					PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELSTATION ] = false ;

					DestroyDynamicObject ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] ) ;
					PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] = INVALID_OBJECT_ID ;

					PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_TYPE ] = 0 ;

					SendClientMessage ( playerid, -1, "You're too far away from the placeholder object. Resetting state...");
				}

				switch ( response ) {
					case EDIT_RESPONSE_CANCEL  : {

						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELSTATION ] = false ;

						DestroyDynamicObject ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] ) ;
						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] = INVALID_OBJECT_ID ;

						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_TYPE ] = 0 ;

						SendClientMessage ( playerid, -1, "You've cancelled the creation of a new pump.");
					}

					case EDIT_RESPONSE_FINAL   : {


						Fuel_OnCreateStation(PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_TYPE ], x, y, z, rx, ry, rz, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid));

						SendClientMessage(playerid, -1, "Created fuel station at designated location.");

						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELSTATION ] = false ;

						DestroyDynamicObject ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] ) ;
						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ] = INVALID_OBJECT_ID ;

						PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_TYPE ] = 0 ;

					}

					case EDIT_RESPONSE_UPDATE  : {

						SetDynamicObjectPos ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ], x, y, z ) ;
						SetDynamicObjectRot ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ], rx, ry, rz ) ;
					}
				}
			}
		}
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_EDITING_FUELSTATION ] ) {

		new idx = PlayerVar [ playerid ] [ E_PLAYER_EDITING_FUELSTATION_ID ] ;

		if ( IsValidDynamicObject( FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ] ) ) {

			if ( FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ] == objectid ) {

				new Float: obj_x, Float: obj_y, Float: obj_z ;
				GetDynamicObjectPos ( PlayerVar [ playerid ] [ E_PLAYER_PLACING_FUELST_OBJID ], obj_x, obj_y, obj_z ) ;
				if ( GetPlayerDistanceFromPoint(playerid, x, y, z ) > 7.5 ) {

					PlayerVar [ playerid ] [ E_PLAYER_EDITING_FUELSTATION ] = false ;

					SetDynamicObjectPos(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
						 FuelPump [ idx ] [ E_FUEL_PUMP_POS_X ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_Y ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_Z ]);

					SetDynamicObjectRot(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
						 FuelPump [ idx ] [ E_FUEL_PUMP_POS_RX ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_RY ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_RZ ]);

					SendClientMessage ( playerid, -1, "You're too far away from the placeholder object. Resetting state...");
				}

				switch ( response ) {
					case EDIT_RESPONSE_CANCEL  : {

						SetDynamicObjectPos(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
							 FuelPump [ idx ] [ E_FUEL_PUMP_POS_X ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_Y ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_Z ]);

						SetDynamicObjectRot(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
							 FuelPump [ idx ] [ E_FUEL_PUMP_POS_RX ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_RY ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_RZ ]);

						SendClientMessage ( playerid, -1, sprintf("You've cancelled the editing of pump SQL ID %d.", FuelPump [ idx ] [ E_FUEL_PUMP_ID ] ));
					}

					case EDIT_RESPONSE_FINAL   : {

						SendClientMessage(playerid, -1, sprintf("You have moved fuel station SQL ID %d.", FuelPump [ idx ] [ E_FUEL_PUMP_ID ]));

						PlayerVar [ playerid ] [ E_PLAYER_EDITING_FUELSTATION ] = false ;

						FuelPump [ idx ] [ E_FUEL_PUMP_POS_X ] = x;
						FuelPump [ idx ] [ E_FUEL_PUMP_POS_Y ] = y ;
						FuelPump [ idx ] [ E_FUEL_PUMP_POS_Z ] = z ;
						FuelPump [ idx ] [ E_FUEL_PUMP_POS_RX ] = rx ;
						FuelPump [ idx ] [ E_FUEL_PUMP_POS_RY ] = ry ;
						FuelPump [ idx ] [ E_FUEL_PUMP_POS_RZ ] = rz ;

						SetDynamicObjectPos(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
							FuelPump [ idx ] [ E_FUEL_PUMP_POS_X ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_Y ],  
							FuelPump [ idx ] [ E_FUEL_PUMP_POS_Z ]
						);

						SetDynamicObjectRot(FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ],
							FuelPump [ idx ] [ E_FUEL_PUMP_POS_RX ],  FuelPump [ idx ] [ E_FUEL_PUMP_POS_RY ],  
							FuelPump [ idx ] [ E_FUEL_PUMP_POS_RZ ]
						);

						new query [ 512 ] ;

						mysql_format(mysql, query, sizeof(query), "UPDATE fuelstation SET fuelstation_pos_x = '%f', fuelstation_pos_y = '%f', fuelstation_pos_z = '%f'\
							fuelstation_pos_rx = '%f', fuelstation_pos_ry = '%f', fuelstation_pos_rz = '%f' WHERE fuelstation_id = %d ", 
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_X ],
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_Y ],
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_Z ],
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_RX ],
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_RY ],
								FuelPump [ idx ] [ E_FUEL_PUMP_POS_RZ ],
								FuelPump [ idx ] [ E_FUEL_PUMP_ID ]
						) ;

						mysql_tquery(mysql, query);
					}

					case EDIT_RESPONSE_UPDATE  : {

						SetDynamicObjectPos ( FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ], x, y, z ) ;
						SetDynamicObjectRot ( FuelPump [ idx ] [ E_FUEL_PUMP_OBJECTID ], rx, ry, rz ) ;
					}
				}
			}
		}

	}
}

// Called when a player enters a pump area.
public OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {

	foreach(new fuelid: FuelPump) {

		if ( FuelPump [ fuelid ] [ E_FUEL_PUMP_AREAID ] == areaid ) {

			PlayerVar [ playerid ] [ E_PLAYER_NEAR_FUELSTATION ] = true ;
		}
	}

	#if defined fuelst_OnPlayerEnterDynamicArea
		return fuelst_OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerEnterDynamicArea
	#undef OnPlayerEnterDynamicArea
#else
	#define _ALS_OnPlayerEnterDynamicArea
#endif

#define OnPlayerEnterDynamicArea fuelst_OnPlayerEnterDynamicArea
#if defined fuelst_OnPlayerEnterDynamicArea
	forward fuelst_OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid);
#endif

// Called when a player leaves a pump area.
public OnPlayerLeaveDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {

	foreach(new fuelid: FuelPump) {

		if ( FuelPump [ fuelid ] [ E_FUEL_PUMP_AREAID ] == areaid ) {

			PlayerVar [ playerid ] [ E_PLAYER_NEAR_FUELSTATION ] = false ;

			if ( PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] ) {

				PlayerVar [ playerid ] [ E_PLAYER_USING_NOZZLE ] = false ;
				Fuel_FinalizePayment(playerid);
			}
		}
	}

	#if defined fuelst_OnPlayerLeaveDynamicArea
		return fuelst_OnPlayerLeaveDynamicArea(playerid, STREAMER_TAG_AREA:areaid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerLeaveDynamicArea
	#undef OnPlayerLeaveDynamicArea
#else
	#define _ALS_OnPlayerLeaveDynamicArea
#endif

#define OnPlayerLeaveDynamicArea fuelst_OnPlayerLeaveDynamicArea
#if defined fuelst_OnPlayerLeaveDynamicArea
	forward fuelst_OnPlayerLeaveDynamicArea(playerid, STREAMER_TAG_AREA:areaid);
#endif


// Key handler for refuelling at a pump.
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {

	// Refueling is now driven entirely by /refuel - see vehicle/fuel/header.pwn.
	#pragma unused playerid, newkeys, oldkeys

	#if defined fuels_OnPlayerKeyStateChange
		return fuels_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerKeyStateChange
	#undef OnPlayerKeyStateChange
#else
	#define _ALS_OnPlayerKeyStateChange
#endif

#define OnPlayerKeyStateChange fuels_OnPlayerKeyStateChange
#if defined fuels_OnPlayerKeyStateChange
	forward fuels_OnPlayerKeyStateChange(playerid, newkeys, oldkeys);
#endif

#include <YSI_Coding\y_hooks>
hook OnRemoveBuilding() {
	// Idlewood Gas
	RemoveBuilding( 1676, 1941.6563, -1778.4531, 14.1406, 0.25);
	RemoveBuilding( 1676, 1941.6563, -1774.3125, 14.1406, 0.25);
	RemoveBuilding( 1676, 1941.6563, -1771.3438, 14.1406, 0.25);
	RemoveBuilding( 1676, 1941.6563, -1767.2891, 14.1406, 0.25);

	// Flint Gas
	RemoveBuilding( 1676, -92.1016, -1161.7891, 2.9609, 0.25);
	RemoveBuilding( 1676, -97.0703, -1173.7500, 3.0313, 0.25);
	RemoveBuilding( 1676, -85.2422, -1165.0313, 2.6328, 0.25);
	RemoveBuilding( 1676, -90.1406, -1176.6250, 2.6328, 0.25);

	// Dillimore Gas
	RemoveBuilding( 1686, 655.6641, -571.2109, 15.3594, 0.25);
	RemoveBuilding( 1686, 655.6641, -569.6016, 15.3594, 0.25);
	RemoveBuilding( 1686, 655.6641, -558.9297, 15.3594, 0.25);
	RemoveBuilding( 1686, 655.6641, -560.5469, 15.3594, 0.25);
	
	return true;
}
// Resets fuel variables when a player connects.
public OnPlayerConnect(playerid) {

	#pragma unused playerid

	#if defined fuel_OnPlayerConnect
		return fuel_OnPlayerConnect(playerid);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerConnect
	#undef OnPlayerConnect
#else
	#define _ALS_OnPlayerConnect
#endif

#define OnPlayerConnect fuel_OnPlayerConnect
#if defined fuel_OnPlayerConnect
	forward fuel_OnPlayerConnect(playerid);
#endif

// Cleans up fuel variables when a player leaves.
public OnPlayerDisconnect(playerid, reason) {

	#pragma unused playerid, reason

	#if defined fuel_OnPlayerDisconnect
		return fuel_OnPlayerDisconnect(playerid, reason);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerDisconnect
	#undef OnPlayerDisconnect
#else
	#define _ALS_OnPlayerDisconnect
#endif

#define OnPlayerDisconnect fuel_OnPlayerDisconnect
#if defined fuel_OnPlayerDisconnect
	forward fuel_OnPlayerDisconnect(playerid, reason);
#endif
