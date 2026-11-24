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

// Filled from service records and dealerships by Runtime_RebuildGPS.
new GPS[256][E_GPS_DATA];

new bool:GPS_Available[sizeof GPS], GPS_DealerBase;

// Availability is explicit so an enabled location at the origin remains valid.
bool:GPS_IsAvailable(index) {
    return index >= 0 && index < sizeof GPS && GPS_Available[index];
}

// Rebuild the destination list from the same snapshot used by service markers.
// Interior/private-world locations cannot be reached by an outdoor GPS route.
Runtime_RebuildGPS() {
    for (new i; i < sizeof GPS; i++) { GPS_Available[i] = false; GPS[i][E_GPS_DESC][0] = EOS; }
    new row;
    for (new i; i < RuntimeLocationCount && row < sizeof GPS - MAX_DEALERSHIPS; i++) {
        if (!RuntimeLocations[i][RLOC_ENABLED] || !RuntimeLocations[i][RLOC_GPS] || RuntimeLocations[i][RLOC_INTERIOR] || RuntimeLocations[i][RLOC_WORLD]) continue;
        format(GPS[row][E_GPS_DESC],64,"%s",RuntimeLocations[i][RLOC_LABEL]);
        GPS[row][E_GPS_POS_X]=RuntimeLocations[i][RLOC_X]; GPS[row][E_GPS_POS_Y]=RuntimeLocations[i][RLOC_Y]; GPS[row][E_GPS_POS_Z]=RuntimeLocations[i][RLOC_Z];
        GPS[row][E_GPS_JURISDICTION]=1; GPS_Available[row++]=true;
    }
    GPS_DealerBase=row;
    return GPS_SyncDealerships();
}

// Dealership changes update only the reserved tail of the GPS list.
GPS_SyncDealerships() {
    for (new row=GPS_DealerBase; row<sizeof GPS; row++) GPS_Available[row]=false;
    new row=GPS_DealerBase;
    for(new d; d<MAX_DEALERSHIPS && row<sizeof GPS; d++) {
        if(!Dealerships[d][dealership_sqlid] || Dealerships[d][dealership_interior] || Dealerships[d][dealership_world]) continue;
        format(GPS[row][E_GPS_DESC],64,"%s",Dealerships[d][dealership_name]);
        GPS[row][E_GPS_POS_X]=Dealerships[d][dealership_pos_x]; GPS[row][E_GPS_POS_Y]=Dealerships[d][dealership_pos_y]; GPS[row][E_GPS_POS_Z]=Dealerships[d][dealership_pos_z];
        GPS[row][E_GPS_JURISDICTION]=1; GPS_Available[row++]=true;
    }
    return 1;
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
    new menuRevision=RuntimeRevision;
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

        if(response && menuRevision!=RuntimeRevision) return GPS_ShowServerHotspots(playerid);
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
    if (!GPS_IsAvailable(selection)) return GPS_ShowServerHotspots(playerid);
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

    new menuRevision=RuntimeRevision;
    inline gps_showhotspot(pid, dialogid, response, listitem, string:inputtext[])
    {
		#pragma unused pid, dialogid, inputtext

        if (!response)
        {
            return GPS_ShowServerHotspots(playerid);
        }

        if(menuRevision!=RuntimeRevision) return GPS_ShowServerHotspots(playerid);
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
