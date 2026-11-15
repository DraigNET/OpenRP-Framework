// ============================================================================
// File: gps/data.pwn
// The /gps location list. Each row is { name, x, y, z, in-jurisdiction }. Rows at 0,0 are
// hidden until you set coordinates. Dealership and Pay 'n' Spray rows are filled in from the
// database/other tables at runtime.
// ============================================================================

enum E_GPS_DATA {

    E_GPS_DESC [ 64 ],
    Float:
        E_GPS_POS_X,
        Float:
        E_GPS_POS_Y,
        Float:
        E_GPS_POS_Z,

        E_GPS_JURISDICTION
    } ;

new GPS [ ] [ E_GPS_DATA ] =
{
    {"Police Department (SAPD)", 	 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    {"Hospital", 		 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    {"Department of Motor Vehicles (DMV)", 	 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    //{"Realty Listings", 				1360.1354,206.0129,19.5547, true }, // for /listings
    {"Advert Agency", 					ADV_POS_X, ADV_POS_Y, ADV_POS_Z, true}, // /advert

    {"Car Scrapyard", 					 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    {"Boat Scrapyard", 					 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    {"Plane Scrapyard", 				 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map
    {"Administration Building",			 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map

    //{"Ocean Docks - Dockworker Job", 	2753.4329, -2453.7937, 13.6432, true },
    {"Blueberry - Garbageman Job",	     0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map

    {"Truck Stop - Fuel Station",		 0.0, 0.0, 0.0, true }, // TODO: set coordinates for your map

    {"Chop Shop", 						CHOPSHOP_X, CHOPSHOP_Y, CHOPSHOP_Z, true},

    //{"Aztecas Gun Dealer",1691.9714,-1972.4589,8.8253, true}, // ec_dealer
    //{"Families Gun Dealer",2444.0278,-1965.5500,13.5469, true}, // emmet_families
    //{"Vagos Gun Dealer",2611.7861,-1394.2970,34.9903, true}, // emmet_vagos
    //{"Ballas Gun Dealer",2168.7156,-1507.5477,23.9246, true}, // ballas_emmet

    // One placeholder row per possible dealership (MAX_DEALERSHIPS). GPS_SyncDealerships() names and positions them from
    // the `dealerships` table, so /gps lists each dealership by its own name. Unused rows have no coordinates and aren't listed.
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Dealership",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map

    //{"Gym: East Los Santos", 			LS_GYM_EXT_X, LS_GYM_EXT_Y, LS_GYM_EXT_Z, true},
    //{"Gym: South Los Santos", 			LV_GYM_EXT_X, LV_GYM_EXT_Y, LV_GYM_EXT_Z, true},
    //{"Gym: West Los Santos", 			BEACH_GYM_EXT_X, BEACH_GYM_EXT_Y, BEACH_GYM_EXT_Z, true},
    // Re-enable once GANTON_GYM_EXT_* in config/data/header.pwn hold real coords again (currently 0.0 placeholders).
    //{"Gym: Central Los Santos", 		GANTON_GYM_EXT_X, GANTON_GYM_EXT_Y, GANTON_GYM_EXT_Z, true},

    // Pay 'N' Spray rows are placeholders too: LoadPayNSpray() names them and sets their coordinates from
    // E_PNS_LOCATIONS, in order. Spare rows stay empty and aren't listed, so add a row here when you add a location.
    {"Pay 'N' Spray",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Pay 'N' Spray",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Pay 'N' Spray",  0.0, 0.0, 0.0, true}, // TODO: set coordinates for your map
    {"Pay 'N' Spray",  0.0, 0.0, 0.0, true} // TODO: set coordinates for your map
} ;

// A GPS row with no coordinates has nothing to point at, so it isn't offered.
bool: GPS_IsAvailable(index)
{
    return ( GPS [ index ] [ E_GPS_POS_X ] != 0.0 || GPS [ index ] [ E_GPS_POS_Y ] != 0.0 ) ;
}

// Names and positions the dealership rows from the real dealerships, one row per dealership, in table order.
// Called whenever a dealership is loaded, created, moved, renamed or deleted, so the GPS never drifts from them.
GPS_SyncDealerships()
{
    static base = -1 ;

    if ( base == -1 ) {

        for ( new g ; g < sizeof ( GPS ) ; g ++ ) {

            if ( ! strcmp ( GPS [ g ] [ E_GPS_DESC ], "Dealership" ) ) {

                base = g ;
                break ;
            }
        }

        if ( base == -1 ) return false ;
    }

    new row = base ;

    for ( new d ; d < MAX_DEALERSHIPS && row < sizeof ( GPS ) ; d ++ ) {

        if ( ! Dealerships [ d ] [ dealership_sqlid ] ) continue ;

        format ( GPS [ row ] [ E_GPS_DESC ], 64, "%s", Dealerships [ d ] [ dealership_name ] ) ;
        GPS [ row ] [ E_GPS_POS_X ] = Dealerships [ d ] [ dealership_pos_x ] ;
        GPS [ row ] [ E_GPS_POS_Y ] = Dealerships [ d ] [ dealership_pos_y ] ;
        GPS [ row ] [ E_GPS_POS_Z ] = Dealerships [ d ] [ dealership_pos_z ] ;
        row ++ ;
    }

    // Rows left over (deleted dealerships) go back to unused.
    for ( new end = base + MAX_DEALERSHIPS ; row < end && row < sizeof ( GPS ) ; row ++ ) {

        format ( GPS [ row ] [ E_GPS_DESC ], 64, "Dealership" ) ;
        GPS [ row ] [ E_GPS_POS_X ] = 0.0 ;
        GPS [ row ] [ E_GPS_POS_Y ] = 0.0 ;
        GPS [ row ] [ E_GPS_POS_Z ] = 0.0 ;
    }

    return true ;
}

// Shows the paged /gps list of server locations.
GPS_ShowServerHotspots(playerid)
{

    if (PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] == 0)
    {
        PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] = 1 ;
    }

    // Pagination stuff
    new MAX_ITEMS_ON_PAGE = 10, string [ 1024 ], bool:nextpage ;
    new resultcount = ((MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ]) - MAX_ITEMS_ON_PAGE) ;


    strcat(string, "Description\tDistance\n");

    new Float:dist ;

    // Only rows that have somewhere to point at are listed.
    new visible [ sizeof ( GPS ) ], visible_count ;

    for (new g = 0; g < sizeof(GPS); g ++)
    {
        if (GPS_IsAvailable(g)) visible [ visible_count ++ ] = g ;
    }

    for (new i = resultcount, j = visible_count; i < j; i ++)
    {
        new g = visible [ i ] ;

        resultcount ++ ;

        if (resultcount <= MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ])
        {
            dist = GetPlayerDistanceFromPoint(playerid, GPS [ g ] [ E_GPS_POS_X ], GPS [ g ] [ E_GPS_POS_Y ], GPS [ g ] [ E_GPS_POS_Z ]) ;

            format(string, sizeof(string), "%s%s\t%0.3f yds\n", string, GPS [ g ] [ E_GPS_DESC ], dist);
        }

        if (resultcount >= MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ])
        {

            nextpage = true;
            break;
        }
    }

    new pages = floatround(resultcount / MAX_ITEMS_ON_PAGE, floatround_floor) + 1 ;

    if (nextpage)
    {
        strcat(string, "Next Page >>") ;
    }

    inline gps_show_list(pid, dialogid, response, listitem, string: inputtext[])
    {
		#pragma unused pid, dialogid, inputtext

        new pick = ((MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ]) - MAX_ITEMS_ON_PAGE) + listitem;
        new selection = ( pick < visible_count ) ? visible [ pick ] : 0 ;

        if (! response)
        {

            if (PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] > 1)
            {

                PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] -- ;
                return GPS_ShowServerHotspots(playerid) ;
            }

            else return true ;
        }

        if (response)
        {

            if (listitem >= MAX_ITEMS_ON_PAGE)
            {

                PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] ++ ;
                return GPS_ShowServerHotspots(playerid) ;
            }

            else if (listitem < MAX_ITEMS_ON_PAGE)
            {

                /*
                DisablePlayerCheckpoint(playerid);

                GPS_MarkLocation ( playerid, "~r~Point of Interest~w~ has been marked on your ~r~minimap~w~.", E_GPS_COLOR_DEFAULT, GPS [ selection ] [ E_GPS_POS_X ], GPS [ selection ] [ E_GPS_POS_Y ], GPS [ selection ] [ E_GPS_POS_Z ] ) ;

                if ( ! GPS [ selection ] [ E_GPS_JURISDICTION ] ) {
                	//InformPlayer ( playerid, E_PLAYER_INFORM_BOX, "The location you want to reach is outside of the city of Los Santos's control!", -1, 1083, 6000, "The BCSD has no power here and the area may be crime contested!" ) ;

                	//ShowPlayerSubtitle(playerid, "The BCSD has no power here and the area may be crime contested!", .showtime=6000 ) ;
                	ShowPlayerInfoMessage(playerid, "The location you want to reach is outside of government control.", .height=167.5, .width=180, .showtime=6000);

                }
                */

                GPS_ShowHotspot(playerid, selection, GetPlayerAdminLevel(playerid) > ADMIN_LVL_NONE);

                return true ;
            }
        }
    }

    if (PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ] > 1)
    {
        Dialog_ShowCallback(playerid, using inline gps_show_list, DIALOG_STYLE_TABLIST_HEADERS, sprintf("GPS: Page %d of %d", PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ], pages), string, "Select", "Previous") ;
    }

    else Dialog_ShowCallback(playerid, using inline gps_show_list, DIALOG_STYLE_TABLIST_HEADERS, sprintf("GPS: Page %d of %d", PlayerVar [ playerid ] [ E_PLAYER_GPSLIST_PAGE ], pages), string, "Select", "Back") ;

    //SendClientMessage(playerid, COLOR_YELLOW, "To disable your gps use /nocp." ) ;

    return true ;
}

// Marks a chosen location on the player's map; staff also get a teleport option.
GPS_ShowHotspot(playerid, selection, bool:options = false)
{
    if (!options)
    {
        DisablePlayerCheckpoint(playerid);
        GPS_MarkLocation(playerid, sprintf("~r~%s~w~ has been marked on your ~r~minimap~w~.", GPS[selection][E_GPS_DESC]), E_GPS_COLOR_DEFAULT, GPS [ selection ] [ E_GPS_POS_X ], GPS [ selection ] [ E_GPS_POS_Y ], GPS [ selection ] [ E_GPS_POS_Z ]);
        SendClientMessage(playerid, COLOR_YELLOW, "To disable your gps marker use /cleargps.");

        if (! GPS [ selection ] [ E_GPS_JURISDICTION ])
        {
            ShowPlayerInfoMessage(playerid, "The location you want to reach is outside of government control.", .height = 167.5, .width = 180, .showtime = 5000);
        }

        return true;
    }

    inline gps_showhotspot(pid, dialogid, response, listitem, string:inputtext[])
    {
		#pragma unused pid, dialogid, inputtext

        if (!response)
        {
            return GPS_ShowServerHotspots(playerid);
        }

        if (listitem == 0)
        {
            // Just do normal gps route
            return GPS_ShowHotspot(playerid, selection, false);
        }
        else
        {
            // Admin teleport
            SetPlayerVirtualWorld(playerid, 0);
            SetPlayerInterior(playerid, 0);
            ORP_SetPosWithFade(playerid, GPS [ selection ] [ E_GPS_POS_X ], GPS [ selection ] [ E_GPS_POS_Y ], GPS [ selection ] [ E_GPS_POS_Z ]);
            AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("teleported to %s", GPS[selection][E_GPS_DESC]));
        }
    }

    Dialog_ShowCallback(playerid, using inline gps_showhotspot, DIALOG_STYLE_LIST, sprintf("GPS: %s", GPS[selection][E_GPS_DESC]), "Mark on minimap\nTeleport to (Admin)", "Select", "Back") ;
    return true;
}
