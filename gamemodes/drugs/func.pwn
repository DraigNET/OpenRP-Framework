// ============================================================================
// File: drugs/func.pwn
// Handles the object editor response when a player positions a plant or lab
// (OnPlayerEditDynamicObject).
// ============================================================================

 
// Handles the object editor when a player positions a plant or drug lab: confirm saves it, cancel
// removes it.
public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz) {
	if ( PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ] == objectid ) {
		switch ( response ) {

			case EDIT_RESPONSE_CANCEL: {

				ORP_DestroyObject(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], "Drugs/EditDynamicObject Cancel", true ) ;

				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ] = -1 ;
				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_NONE ;
				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = E_DRUG_TYPE_NONE ;
				
				CancelEdit(playerid) ;
			}

			case EDIT_RESPONSE_FINAL: {
				new free_id = Drugs_GetFreeID(), type = PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ],
				param = PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] ;

				ORP_DestroyObject(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], "Drugs/EditDynamicObject Final", true ) ;
				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ] = -1 ;
				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_NONE ;
				PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = E_DRUG_TYPE_NONE ;

				if ( free_id == INVALID_DRUG_ID ) {

					return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Couldn't create new drug entity - free ID returned -1" ) ;
				}

				Drugs [ free_id ] [ E_DRUG_TYPE ] = type ;
				Drugs [ free_id ] [ E_DRUG_PARAM ] = param ;
				Drugs [ free_id ] [ E_DRUG_OBJECT ] = INVALID_STREAMER_ID ;
				Drugs [ free_id ] [ E_DRUG_OBJECT_EXTRA ] = INVALID_STREAMER_ID ;
				Drugs [ free_id ] [ E_DRUG_LABEL ] = DynamicText3D:INVALID_STREAMER_ID ;
			
				Drugs [ free_id ] [ E_DRUG_STAGE ] = E_DRUG_STAGE_START ;

				Drugs [ free_id ] [ E_DRUG_POS_X ] = x ;
				Drugs [ free_id ] [ E_DRUG_POS_Y ] = y ;
				Drugs [ free_id ] [ E_DRUG_POS_Z ] = z ;
			
				Drugs [ free_id ] [ E_DRUG_ROT_X ] = rx ;
				Drugs [ free_id ] [ E_DRUG_ROT_Y ] = ry ;
				Drugs [ free_id ] [ E_DRUG_ROT_Z ] = rz ;
			
				Drugs [ free_id ] [ E_DRUG_INTERIOR ] = GetPlayerInterior(playerid);
				Drugs [ free_id ] [ E_DRUG_WORLDID ] = GetPlayerVirtualWorld(playerid) ;

				new query [ 512 ] ;

				mysql_format(mysql, query, sizeof ( query ), 
					"INSERT INTO drugs_player_stations(drug_type, drug_param, drug_stage, drug_pos_x, drug_pos_y, drug_pos_z, \
					drug_rot_x, drug_rot_y, drug_rot_z, drug_world, drug_interior) VALUES (%d, %d, %d, %f, %f, %f, %f, %f, %f, %d, %d)",

					Drugs [ free_id ] [ E_DRUG_TYPE ], Drugs [ free_id ] [ E_DRUG_PARAM ], Drugs [ free_id ] [ E_DRUG_STAGE ],
					Drugs [ free_id ] [ E_DRUG_POS_X ], Drugs [ free_id ] [ E_DRUG_POS_Y ], Drugs [ free_id ] [ E_DRUG_POS_Z ],
					Drugs [ free_id ] [ E_DRUG_ROT_X ], Drugs [ free_id ] [ E_DRUG_ROT_Y ], Drugs [ free_id ] [ E_DRUG_ROT_Z ],
					Drugs [ free_id ] [ E_DRUG_WORLDID ], Drugs [ free_id ] [ E_DRUG_INTERIOR ]
				) ;

				inline DrugStation_OnDBInsert() {

					Drugs [ free_id ] [ E_DRUG_SQLID ]  = cache_insert_id ();
					printf(" * [DRUG STATION] Created station (%d) with ID %d.", 
						free_id, Drugs [ free_id ] [ E_DRUG_SQLID ] ) ;

					new drug_type [ 64 ] ;
					Drugs_GetTypeName ( Drugs [ free_id ] [ E_DRUG_TYPE ], drug_type ) ;

					AddLogEntry(playerid, LOG_TYPE_DRUGS, sprintf("Created a %s station (sql ID %d)",
						drug_type, Drugs [ free_id ] [ E_DRUG_SQLID ])
					);

					Drug_RemoveSupplyFromPlayer ( playerid, type, param ) ;
					Drugs_UpdateObject ( free_id ) ;
				} 

				MySQL_TQueryInline(mysql, using inline DrugStation_OnDBInsert, query, "");

			}

			case EDIT_RESPONSE_UPDATE: {

				SetDynamicObjectPos(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], Float:x, Float:y, Float:z);
				SetDynamicObjectRot(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], Float:rx, Float:ry, Float:rz) ;
			}
		}
	}

	#if defined drugs_OnPlayerEditDynamicObject
		return drugs_OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerEditDynamicObject
	#undef OnPlayerEditDynamicObject
#else
	#define _ALS_OnPlayerEditDynamicObject
#endif

#define OnPlayerEditDynamicObject drugs_OnPlayerEditDynamicObject
#if defined drugs_OnPlayerEditDynamicObject
	forward drugs_OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
#endif

