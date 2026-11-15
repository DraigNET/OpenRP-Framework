// ============================================================================
// File: attachments/store/browser.pwn
// The /buytoys store UI. Opens the model browser for the attach point type the player is
// standing at, and handles the purchase.
// Commands: /buytoys
// ============================================================================

// /buytoys - opens the model browser of the shop you are standing at (clothing, jewelry, barber,
// faction gear).
CMD:buytoys(playerid, params[]) {

	new idx = AttachPoint_GetNearestEntity(playerid) ;

	if ( idx == INVALID_ATTACH_POINT_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "You're not near an attach or buytoys point." ) ;
	}

	// Faction toy sets are gated to one specific faction (by SQL id), so each
	// agency only opens its own - see AttachPoint_RequiredFaction.
	new required_fac = AttachPoint_RequiredFaction(AttachPoint [ idx ] [ E_ATTACH_POINT_TYPE ]) ;

	if (required_fac != 0 && Character [ playerid ] [ E_CHARACTER_FACTIONID ] != required_fac)
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "These toys are restricted to another faction." ) ;
	}

	ModelBrowser_ClearData(playerid);


	new title [ 64 ] ;

	switch ( AttachPoint [ idx ] [ E_ATTACH_POINT_TYPE ] ) {

		case ATTACH_TYPE_FACE: {
			format ( title, sizeof ( title ), "Facewear" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_Face ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_Face [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_Face [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_HEAD: {
			format ( title, sizeof ( title ), "Headwear" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_Head ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_Head [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_Head [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_NECK: {
			format ( title, sizeof ( title ), "Neckwear" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_Neck ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_Neck [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_Neck [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_MISC: {
			format ( title, sizeof ( title ), "Miscellaneous" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_MISC ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_MISC [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_MISC [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_SAPD: {
			format ( title, sizeof ( title ), "Police Restricted" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_SAPD ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_SAPD [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_SAPD [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_FDSA: {
			format ( title, sizeof ( title ), "Fire Restricted" ) ;

			for ( new i, j = sizeof ( AttachStore_Clothing_FDSA ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Clothing_FDSA [ i ] [ E_ATTACH_MODEL ], AttachStore_Clothing_FDSA [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_CHAINS: {
			format ( title, sizeof ( title ), "Chains" ) ;

			for ( new i, j = sizeof ( AttachStore_Jewelry_Chains ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Jewelry_Chains [ i ] [ E_ATTACH_MODEL ], AttachStore_Jewelry_Chains [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_WATCHES: {
			format ( title, sizeof ( title ), "Watches" ) ;

			for ( new i, j = sizeof ( AttachStore_Jewelry_Watches ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Jewelry_Watches [ i ] [ E_ATTACH_MODEL ], AttachStore_Jewelry_Watches [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_RINGS: {
			format ( title, sizeof ( title ), "Rings" ) ;

			for ( new i, j = sizeof ( AttachStore_Jewelry_Rings ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Jewelry_Rings [ i ] [ E_ATTACH_MODEL ], AttachStore_Jewelry_Rings [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_JEWEL_MISC: {
			format ( title, sizeof ( title ), "Miscellaneous" ) ;

			for ( new i, j = sizeof ( AttachStore_Jewelry_Extra ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Jewelry_Extra [ i ] [ E_ATTACH_MODEL ], AttachStore_Jewelry_Extra [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}

		case ATTACH_TYPE_BARBER: {
			format ( title, sizeof ( title ), "Hairstyles" ) ;

			for ( new i, j = sizeof ( AttachStore_Barber ); i < j ; i ++ ) {

				ModelBrowser_AddData(playerid, AttachStore_Barber [ i ] [ E_ATTACH_MODEL ], AttachStore_Barber [ i ] [ E_ATTACH_NAME ] ) ;
			}
		}
	}

	ModelBrowser_SetupTiles(playerid, title, "Menu_BuyToy");

	return true ;
}

// Model browser callback: charges the player and lets them pick the bone for the toy they
// selected.
mBrowser:Menu_BuyToy(playerid, response, row, model, name[]) {

	if ( response ) {

		new string [ 256 ] ;

		format ( string, sizeof ( string ), "BuyToy: Selected row %d, having model %d and name %s. Type: %d.",
			row, model, name, Attach_GetType(model)
		) ;

		SendServerMessage ( playerid, COLOR_ATTACH, "Attach", "DEDEDE", string);

		new a_name[64], bone [ 64 ], type ;

		inline PlayerToyList_Use(pidx, dialogidx, responsex, listitemx, string:inputtextx[]) {
			#pragma unused pidx, dialogidx, inputtextx
			if ( responsex ) {

				type = Attach_GetType(PlayerAttachments [ playerid ] [ E_PLAYER_ATTACH_MODEL ] [ listitemx ]);
				Attach_GetName(type, PlayerAttachments [ playerid ] [ E_PLAYER_ATTACH_MODEL ] [ listitemx ], a_name, sizeof ( a_name ) ) ;

				format ( string, sizeof ( string ), "You will be replacing your \"%s\" in slot %d.", a_name, listitemx ) ;
				SendServerMessage ( playerid, COLOR_ATTACH, "Attach", "DEDEDE", string);

				Attach_ShowBoneList ( playerid, model, listitemx, true ) ;
			}
		}

		format ( string, sizeof ( string ), "Slot \t Name \t Bone\n" ) ;

		for ( new i, j = MAX_PLAYER_ATTACHMENTS; i < j ; i ++ ) {

			type = Attach_GetType(PlayerAttachments [ playerid ] [ E_PLAYER_ATTACH_MODEL ] [ i ]);

			Attach_GetBoneName ( PlayerAttachments [ playerid ] [ E_PLAYER_ATTACH_BONE ] [ i ], bone, sizeof ( bone ) ) ;
			Attach_GetName(type, PlayerAttachments [ playerid ] [ E_PLAYER_ATTACH_MODEL ] [ i ], a_name, sizeof ( a_name ) ) ;
			
			format ( string, sizeof ( string ), "%s%d \t %s \t %s\n", string, i, a_name, bone ) ;

		}

		Dialog_ShowCallback ( playerid, using inline PlayerToyList_Use, DIALOG_STYLE_TABLIST_HEADERS, "Attachments: Owned", string, "Select", "Close" );

	}

	return true ;
}
