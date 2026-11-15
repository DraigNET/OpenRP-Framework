// ============================================================================
// File: jobs/dockworker/data.pwn
// Dockworker job data and initialisation. Disabled by default.
// ============================================================================



enum E_DOCKWORKER_COLLECT_DATA {

	E_DOCK_COLLECT_DESC [ 64 ],
	Float: E_DOCK_COLLECT_POS_X,
	Float: E_DOCK_COLLECT_POS_Y,
	Float: E_DOCK_COLLECT_POS_Z
} ;

new Dockworker_Collect[ ] [ E_DOCKWORKER_COLLECT_DATA ] = {

	{ "Malt Brewery", -959.0002,-1442.8022,11.9708 },
	{ "Textile Factory", -989.9063,-1422.5759,11.6029 },
	{ "Plank Sawmill", -1040.1691,-1447.0833,11.8034 }
} ;

enum E_DOCKWORKER_STORE_DATA {

	E_DOCK_STORE_MODEL,
	E_DOCK_STORE_DESC [ 64 ],
	Float: E_DOCK_STORE_POS_X,
	Float: E_DOCK_STORE_POS_Y,
	Float: E_DOCK_STORE_POS_Z
} ;

new Dockworker_Store [ ] [ E_DOCKWORKER_STORE_DATA ] = {
 	{1579, "Blue Warehouse", -916.4863,-1500.1895,12.0927 }, // blue_hangar
 	{1578, "Green Warehouse", -887.9313,-1511.0985,12.0887 }, // green_hangar
 	{1580, "Red Warehouse", -945.1185,-1488.0452,12.0939 } // red_hangar
} ;


// Creates the dockworker job labels and loads its data.
Job_Dockworker_Init() {

	for ( new i, j = sizeof ( Dockworker_Collect ); i < j ; i ++ ) {

		CreateDynamic3DTextLabel(sprintf("Dockworker Job\n{CBAE3D}[%s]{DEDEDE}\nAvailable commands: /cargocollect",

			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_DESC ] ), COLOUR_JOB, 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_X ], 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Y ], 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Z ],
		 	25.0 
		) ;
 
		CreateDynamicPickup(2912, 1, 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_X ], 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Y ], 
			Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Z ]
		) ;

		CreateDynamicMapIcon( Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_X ], Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Y ], Dockworker_Collect [ i ] [ E_DOCK_COLLECT_POS_Z ], 9, 0xA3A3A3FF);
	}

	for ( new i, j = sizeof ( Dockworker_Store ); i < j ; i ++ ) {

		CreateDynamic3DTextLabel(sprintf("Dockworker Job\n{CBAE3D}[%s]{DEDEDE}\nAvailable commands: /cargostore",

			Dockworker_Store [ i ] [ E_DOCK_STORE_DESC ] ), COLOUR_JOB, 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_X ], 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_Y ], 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_Z ],
		 	25.0 
		) ;
 
		CreateDynamicPickup(Dockworker_Store [ i ] [ E_DOCK_STORE_MODEL ], 1, 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_X ], 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_Y ], 
			Dockworker_Store [ i ] [ E_DOCK_STORE_POS_Z ]
		) ;

	}
}
