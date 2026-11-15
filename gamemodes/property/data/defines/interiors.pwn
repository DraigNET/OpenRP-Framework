// ============================================================================
// File: property/data/defines/interiors.pwn
// Table of selectable interiors for properties: a name, interior id and entry position for
// every stock GTA:SA interior (houses, 24/7s, offices...). Add your own map interiors here.
// ============================================================================

enum E_INTERIOR_DATA {

	E_PROP_INT_DESC [ 64 ],
	E_PROP_INT_VW,
	E_PROP_INT_INT,
	Float: E_PROP_INT_POS_X,
	Float: E_PROP_INT_POS_Y,
	Float: E_PROP_INT_POS_Z
}
new InteriorData [ ] [ E_INTERIOR_DATA ] = {
	{ "Los Santos", 0, 0,  1763.67004, -1920.79480, 13.39839 },
	{ "Cj's house", 0,  3,  2496.049804,-1695.238159,1014.742187  },
	{ "Og Loc's house", 0,  3,  513.882507,-11.269994,1001.565307  },
	{ "Ryders house", 0,  2,  2454.717041,-1700.871582,1013.515197  },
	{ "Sweet's house", 0,  1,  2527.654052,-1679.388305,1015.498596  },
	{ "Denise room", 0,  1,  244.411987,305.032989,999.148437  },
	{ "Michelle room", 0,  4,  302.180999,300.722991,999.148437  },
	{ "Trailer", 0,  2,  1.8013,-3.2560,999.4284  },	
	{ "Large/2 story/3 bedrooms/clone of House 9", 0, 3,	235.508994,	1189.169897,	1080.339966 },
	{ "Medium/1 story/1 bedroom", 0, 2,	225.756989,	1240.000000,	1082.149902 },
	{ "Small/1 story/1 bedroom", 0, 1,	223.043991,	1289.259888,	1082.199951 },
	{ "VERY Large/2 story/4 bedrooms", 0, 7,	225.630997,	1022.479980,	1084.069946 },
	{ "Small/1 story/2 bedrooms", 0, 15,	295.138977,	1474.469971	,1080.519897, },
	{ "Small/1 story/2 bedrooms", 0, 15,	328.493988,	1480.589966,	1084.449951, },
	{ "Small/1 story/1 bedroom/NO BATHROOM!", 0, 15,	385.803986,	1471.769897,	1080.209961 },
	{ "Hashbury House",	0, 10,	2260.76,	-1210.45,	1049.02	 },
	{ "Red Bed Motel Room", 0,	10,	2262.83,	-1137.71,	1050.63 },
	{ "Verdant Bluffs Safehouse", 0, 8,	2365.42,	-1131.85,	1050.88 },
	{ "Golden Bed Motel Room", 0,	9,	2251.85,	-1138.16,	1050.63 },
	{ "Woozies Apartment", 0, 1,	-2158.72,	641.29,	1052.38 },
	{ "24/7 1", 0,  17,  -25.884498,-185.868988,1003.546875  },
	{ "24/7 2", 0,  10,  6.091179,-29.271898,1003.549438   },
	{ "24/7 3", 0,  18,  -30.946699,-89.609596,1003.546875  },
	{ "24/7 4", 0,  16,  -25.132598,-139.066986,1003.546875  },
	{ "24/7 5", 0,  4,  -27.312299,-29.277599,1003.557250  },
	{ "24/7 6", 0,  6,  -26.691598,-55.714897,1003.546875  },
	{ "Airport ticket desk", 0,  14,  -1827.147338,7.207417,1061.143554  },
	{ "Airport baggage reclaim", 0, 14,  -1861.936889,54.908092,1061.143554 },
	{ "Shamal", 0,  1,  1.808619,32.384357,1199.593750   },
	{ "Andromada", 0,  9,  315.745086,984.969299,1958.919067  },
	{ "Ammunation 1", 0,  1,  286.148986,-40.644397,1001.515625  },
	{ "Ammunation 2", 0,  4,  286.800994,-82.547599,1001.515625  },
	{ "Ammunation 3", 0,  6,  296.919982,-108.071998,1001.515625  },
	{ "Ammunation 4", 0,  7,  314.820983,-141.431991,999.601562  },
	{ "Ammunation 5", 0,  6,  316.524993,-167.706985,999.593750  },
	{ "Ammunation booths", 0,  7,  302.292877,-143.139099,1004.062500  },
	{ "Ammunation range", 0,  7,  298.507934,-141.647048,1004.054748  },
	{ "Blastin fools hallway", 0, 3,  1038.531372,0.111030,1001.284484 },
	{ "Budget inn motel room", 0, 12,  444.646911,508.239044,1001.419494 },
	{ "Jefferson motel", 0,  15,  2215.454833,-1147.475585,1025.796875  },
	{ "Off track betting shop", 0, 3,  833.269775,10.588416,1004.179687 },
	{ "Sex shop", 0,  3,  -103.559165,-24.225606,1000.718750  },
	{ "Meat factory", 0,  1,  963.418762,2108.292480,1011.030273  },
	{ "Zero's RC shop", 0,  6,  -2240.468505,137.060440,1035.414062  },
	{ "Dillimore gas station", 0, 0,  663.836242,-575.605407,16.343263 },
	{ "Catigula's basement", 0,  1,  2169.461181,1618.798339,999.976562  },
	{ "FDC Janitors room", 0,  10,  1889.953369,1017.438293,31.882812  },
	{ "Woozie's office", 0,  1,  -2159.122802,641.517517,1052.381713  },
	{ "Binco", 0,  15,  207.737991,-109.019996,1005.132812  },
	{ "Didier sachs", 0,  14,  204.332992,-166.694992,1000.523437  },
	{ "Prolaps", 0,  3,  207.054992,-138.804992,1003.507812  },
	{ "Suburban", 0,  1,  203.777999,-48.492397,1001.804687  },
	{ "Victim", 0,  5,  226.293991,-7.431529,1002.210937  },
	{ "Zip", 0,   18,  161.391006,-93.159156,1001.804687   },
	{ "Club", 0,   17,  493.390991,-22.722799,1000.679687  },
	{ "Bar", 0,   11,  501.980987,-69.150199,998.757812   },
	{ "Lil' probe inn", 0,  18,  -227.027999,1401.229980,27.765625  },
	{ "Jay's diner", 0,  4,  457.304748,-88.428497,999.554687  },
	{ "Gant bridge diner", 0,  5,  454.973937,-110.104995,1000.077209  },
	{ "Secret valley diner", 0,  6,  435.271331,-80.958938,999.554687  },
	{ "World of coq", 0,  1,  452.489990,-18.179698,1001.132812  },
	{ "Welcome pump", 0,  1,  681.557861,-455.680053,-25.609874  },
	{ "Burger shot", 0,  10,  375.962463,-65.816848,1001.507812  },
	{ "Cluckin' bell", 0,  9,  369.579528,-4.487294,1001.858886  },
	{ "Well stacked pizza", 0,  5,  373.825653,-117.270904,1001.499511  },
	{ "Rusty browns donuts", 0,  17,  381.169189,-188.803024,1000.632812  },
	{ "Katie room", 0,  2,  271.884979,306.631988,999.148437  },
	{ "Helena room", 0,  3,  291.282989,310.031982,999.148437  },
	{ "Barbara room", 0,  5,  322.197998,302.497985,999.148437  },
	{ "Millie room", 0,  6,  346.870025,309.259033,999.155700  },
	{ "Sherman dam", 0,  17,  -959.564392,1848.576782,9.000000  },
	{ "Planning dept.", 0,  3,  384.808624,173.804992,1008.382812  },
	{ "Area 51", 0,  0,  223.431976,1872.400268,13.734375  },
	{ "LS gym", 0,  5,  772.111999,-3.898649,1000.728820  },
	{ "SF gym", 0,  6,  774.213989,-48.924297,1000.585937  },
	{ "LV gym", 0,  7,  773.579956,-77.096694,1000.655029  },
	{ "Madd Doggs mansion", 0,  5,  1267.663208,-781.323242,1091.906250  },
	{ "Crack factory", 0,  2,  2543.462646,-1308.379882,1026.728393  },
	{ "Big spread ranch", 0,  3,  1212.019897,-28.663099,1000.953125  },
	{ "Fanny batters", 0,  6,  761.412963,1440.191650,1102.703125  },
	{ "Strip club", 0,  2,  1204.809936,-11.586799,1000.921875  },
	{ "Strip club private room", 0, 2,  1204.809936,13.897239,1000.921875  },
	{ "Unnamed brothel", 0,  3,  942.171997,-16.542755,1000.929687  },
	{ "Tiger skin brothel", 0,  3,  964.106994,-53.205497,1001.124572  },
	{ "Pleasure domes", 0,  3,  -2640.762939,1406.682006,906.460937  },
	{ "Liberty city outside", 0,  1,  -729.276000,503.086944,1371.971801  },
	{ "Liberty city inside", 0,  1,  -794.806396,497.738037,1376.195312  },
	{ "Gang house", 0,  5,  2350.339843,-1181.649902,1027.976562  },
	{ "Colonel Furhberger's", 0,  8,  2807.619873,-1171.899902,1025.570312  },
	{ "Crack den", 0,  5,  318.564971,1118.209960,1083.882812  },
	{ "Warehouse 1", 0,  1,  1412.639892,-1.787510,1000.924377  },
	{ "Warehouse 2", 0,  18,  1302.519897,-1.787510,1001.028259  },
	{ "Sweets garage", 0,  0,  2522.000000,-1673.383911,14.866223  },
	{ "Lil' probe inn toilet", 0, 18,  -221.059051,1408.984008,27.773437  },
	{ "Unused safe house", 0,  12,  2324.419921,-1145.568359,1050.710083  },
	{ "RC Battlefield", 0,  10,  -975.975708,1060.983032,1345.671875  },
	{ "Barber 1", 0,  2,  411.625976,-21.433298,1001.804687  },
	{ "Barber 2", 0,  3,  418.652984,-82.639793,1001.804687  },
	{ "Barber 3", 0,  12,  412.021972,-52.649898,1001.898437  },
	{ "Tatoo parlour 1", 0,  16,  -204.439987,-26.453998,1002.273437  },
	{ "Tatoo parlour 2", 0,  17,  -204.439987,-8.469599,1002.273437  },
	{ "Tatoo parlour 3", 0,  3,  -204.439987,-43.652496,1002.273437  },
	{ "LS police HQ", 0,  6,  246.783996,63.900199,1003.640625  },
	{ "SF police HQ", 0,  10,  246.375991,109.245994,1003.218750  },
	{ "LV police HQ", 0,  3,  288.745971,169.350997,1007.171875  },
	{ "Car school", 0,  3,  -2029.798339,-106.675910,1035.171875  },
	{ "8-Track", 0,  7,  -1398.065307,-217.028900,1051.115844  },
	{ "Bloodbowl", 0,  15,  -1398.103515,937.631164,1036.479125  },
	{ "Dirt track", 0,  4,  -1444.645507,-664.526000,1053.572998  },
	{ "Kickstart", 0,  14,  -1465.268676,1557.868286,1052.531250  },
	{ "Vice stadium", 0,  1,  -1401.829956,107.051300,1032.273437  },
	{ "SF Garage", 0,  0,  -1790.378295,1436.949829,7.187500  },
	{ "LS Garage", 0,  0,  1643.839843,-1514.819580,13.566620  },
	{ "SF Bomb shop", 0,  0,  -1685.636474,1035.476196,45.210937  },
	{ "Blueberry warehouse", 0,  0,  76.632553,-301.156829,1.578125  },
	{ "LV Warehouse 1", 0,  0,  1059.895996,2081.685791,10.820312  },
	{ "LV Warehouse 2 (hidden part)", 0, 0,  1059.180175,2148.938720,10.820312  },
	{ "Catigula's hidden room", 0, 1,  2131.507812,1600.818481,1008.359375  },
	{ "Bank", 0,   0,  2315.952880,-1.618174,26.742187  },
	{ "Bank (behind desk)", 0,  0,  2319.714843,-14.838361,26.749565  },
	{ "LS Atruim", 0,  18,  1710.433715,-1669.379272,20.225049  },
	{ "Bike School", 0,  3,  1494.325195,1304.942871,1093.289062 },
	{ "B Dup's house", 0,  3,  1527.229980,-11.574499,1002.097106  },
	{ "B Dup's crack pad", 0,  2,  1523.509887,-47.821197,1002.130981  },
	{ "----- DEL'S BUSINESS INTS -----", 0,  0,  0.0,0.0,0.0  },
	{ "GTA 3 Bar", 0, 1, 2273.2449,-1480.9895,1799.1697  },    // GTA3Bar *
	{ "Big Bar", 0, 1, 800.2217,2517.9983,1502.3461  },    // Bigbar
	{ "Drusillas", 0, 1, 1804.6256,-1249.0679,2514.8628  },    // Drusillas
	{ "Chinese Restaurant", 0, 1, -1418.7527,2098.9641,4503.4380  },    // ChineseHugeRestaurant
	{ "Brothel", 0, 1, 359.3353,2964.1589,2509.2581  },    // Brothel
	{ "Coffee Shop", 0, 1, 1534.0529,-1360.9407,1614.3477  },    // CoffeeShop
	{ "Hay Church", 0, 1, 2351.4692,-1958.3691,1601.7155  },    // Hay Church
	{ "Workshop", 0, 1, 1080.2185,937.0941,1605.5409  },    // Workshop
	{ "Stripclub 3", 0, 1, 613.8376,-32.7297,1269.3250  },    // StripClub 3
	{ "Stripclub 2", 0, 1, -730.4365,1309.5204,4231.7188  },    // StripClub 2
	{ "Stripclub 1", 0, 1, 550.9149,-67.2787,1002.3815  },    // StripClub 1
	{ "Seed Shop", 0, 1, -1064.4119,-1208.2854,1880.0555  },    // SeedShop
	{ "Nightclub 1", 0, 1, 2232.6621,-2038.4781,2402.7319  },    // NightClub 1
	{ "Nightclub 2", 0, 1, 1447.4342,-1855.6747,1737.0134  },    // NightClub 2
	{ "Nightclub 3", 0, 1, 1480.9073,893.7755,1018.2128  },    // NightClub 3
	{ "Nightclub 4", 0, 1, 493.2249,-6.4949,964.8364  },    // NightClub 4 LGBT
	{ "Nightclub 5", 0, 1, -1188.7756,-158.3294,2.3870  },    // NightClub 5 Splash
	{ "Bar 1", 0, 1, 291.0585,-86.4995,2102.2314  },    // Bar 1
	{ "Bar 2", 0, 1, 446.6123,-91.9021,1024.8097  },    // Bar 2
	{ "Bar 3", 0, 17, -84.1228,-57.3359,954.2733  },    // Bar 3
	{ "Bar 4", 1, 1, 1364.8824,-2.9440,1002.0153  },    // Bar 4
	{ "Bar 5", 0, 12, 2480.9995,-1799.4836,2744.2773  },    // Bar 5
	{ "Bar 6", 0, 1, 1375.6016,320.8106,650.0384  },    // Bar 6
	{ "Bar 7", 0, 1, 2324.8506,-1634.5238,3002.2507  },    // Bar 7
	{ "Bar 8", 0, 1, 2581.2832,-1650.5221,1359.3368  },    // Bar 8
	{ "Bar 9", 0, 1, 1005.7799,487.8716,1157.2601  },    // Bar 9
	{ "Bar 10", 0, 1, 2403.8831,-1498.2083,2797.0593  },    // Bar 10
	{ "Restaurant 1", 0, 1, 1087.2334,1003.7917,1601.8154  },    // Restaurant 1
	{ "Restaurant 2", 0, 1, 361.5339,2238.0061,3702.2820  },    // Restaurant 2
	{ "Restaurant 3", 0, 1, -147.2467,2168.3704,-13.8409  },    // Restaurant 3
	{ "Restaurant 4", 0, 1, 413.2989,149.0370,1026.6985  },    // Restaurant 4
	{ "Restaurant 5", 0, 1, 2422.6287,-1497.3676,-52.2366  },    // Restaurant 5
	{ "Restaurant 6", 0, 1, 1953.5598,-1992.2592,1064.5247  },    // Restaurant 6
	{ "Restaurant 7", 0, 1, 1385.7740,229.2461,861.4269  },    // Restaurant 7
	{ "Hospital", 0, 1, 1172.0703,-1335.6526,3001.5999  },    // Hospital1
	{ "Locker", 0, 1, 1664.9639,1110.7831,2688.5823  },    // Locker 1
	{ "Court 1", 0, 1, 913.8074,-2176.7949,2527.9324  },    // Court1
	{ "Court 2", 0, 1, -2299.7693,-2305.3899,4501.7930  },    // Court2
	{ "Gym 1", 0, 1, 720.6577,1474.3674,3002.2839  },    // Gym1
	{ "Gym 2", 0, 1, 2509.5969,-2152.8977,3102.7908  },    // Gym2
	{ "Gym 3 Fight Club", 0, 1, 2002.0576,1105.3453,2331.1934  },    // Gym3Fightclub
	{ "Clothing Store 1", 0, 1, 1529.6586,1563.5204,1511.8169  },    // ClothesStoreBig
	{ "Clothing Store 2", 0, 1, -400.6317,2227.1631,1802.0205  },    // ClothesStore 2
	{ "Clothing Store 3", 0, 1, 180.9088,-90.5320,2501.6184  },    // ClothesStore 3
	{ "Clothing Store 4", 0, 1, 1084.2451,1006.1131,2001.8693  },    // ClothesStore 4
	{ "Recording Garage", 0, 1, 2157.0400,-1734.1870,3001.9451  },    // RecordGarage
	{ "Recording Studio", 0, 1, 996.1412,999.8840,2001.7711   },   // RecordingStudio
	{ "Office 1", 0, 1, 986.4647,-1522.6566,2202.0508  },    // Office 1
	{ "Office 2", 0, 1, 3314.9124,707.6592,5123.9995  },   // Office2
	{ "Office 3", 0, 1, 887.2397,2260.2681,2239.1238   },   // Office 3
	{ "Office 4", 0, 1, 1569.1367,-1234.8895,1090.7777  },    // Office 4
	{ "News HQ", 0, 1, 2578.5996,1249.2504,2946.0984   },   // SAN HQ
	{ "Pawn Shop 1", 0, 1, 2096.3435,-1931.7961,1094.4520  },    // Pawnshop 1
	{ "Pawn Shop 2", 0, 1, -1701.8381,-686.9859,1001.7107  },    // Pawnshop 2
	{ "Pawn Shop 3", 0, 1, 2510.7766,-1757.2231,1447.3331  },    // Pawnshop 3
	{ "Pawn Shop 4", 0, 1, 1528.1620,1434.2334,3011.5168   },   // Pawnshop 4
	{ "Factory 1", 0, 1, 1916.6263,-2351.1462,1610.4548  },    // Factory 1
	{ "Factory 2", 0, 1, 2453.9429,-2559.7175,-33.1224   },   // Factory 2
	{ "24/7 1", 0, 1, 2509.0876,1221.8544,1802.2830   },   // 24/7 1
	{ "24/7 2", 0, 1, 2589.1777,1422.5802,1801.9977   },   // 24/7 2 Huge
	{ "24/7 3", 0, 1, 670.3856,-579.0205,1702.0925   },   // 24/7 3
	{ "24/7 4", 0, 1, 2508.8628,-41.8898,587.9999   },   // 24/7 4
	{ "Furniture Shop", 0, 1, 934.044555,1653.372680,2535.381835  }, // FurnitureShop
	{ "DMV 1", 0, 1, 735.3796,3113.9678,2085.6208  },    // DMV 1
	{ "DMV 2", 0, 1, -302.9924,1773.0839,3002.1184  },    // DMV 2
	{ "DMV 3", 0, 1, 1167.9226,-1326.3259,1222.9753  },    // DMV 3
	{ "DMV 4", 0, 1, 2230.8301,-1923.0038,-44.6547  },    // DMV 4
	{ "Modern DS", 0, 1, -2071.8855,-91.1339,4301.6812   },   // ModernDS
	{ "Drug 1", 0, 1, -153.1346,1015.1711,2767.7708   },   // Drug 1
	{ "Drug 2", 0, 1, -135.6961,1050.6473,2737.7161   },   // Drug 2
	{ "Drug 3", 0, 1, 2315.0271,-1786.7715,1601.8328  },    // Drug 3
	{ "Barber Shop", 0, 1, 257.0819,1701.3433,3002.2617   },   // Barbershop
	{ "Archives", 0, 1, 2269.4905,-71.9864,1001.9550   },   // Archives
	{ "Info Center", 0, 1, 1234.8601,188.1241,2093.1912  },    // InfoCenter
	{ "Truck Office", 0, 1, 601.4999,1687.0906,-8.0835   },   // TruckOffice
	{ "Art Studio", 0, 1, -2574.0486,144.3843,3074.8799   },   // ArtStudioRevamp
	{ "Bank", 0, 1, 195.5539,-52.4031,4111.6167   },   // Bank
	{ "DS Office", 1, 1, 1410.3322,-11.4730,1007.7297   },   // DSOffice
	{ "Electronic Store 1", 0, 1, 1639.3333,326.3484,1087.4449  },    // ElectronicStore
	{ "Electronic Store 2", 0, 1, 184.1213,1928.2004,2051.9219  },    // ElectronicStore
	{ "Chinese Restaurant 2", 0, 1, 956.1195,752.8566,1211.7379   },   // ChineseRestaurant 3
	{ "Chinese Stripclub", 0, 1, 1149.6505,561.8663,5549.8164  },    // Chinese Stripclub

	{ "----- DEL'S HOUSE INTS -----", 0,  0,  0.0,0.0,0.0  },
	{ "Complex 1", 0, 1, 2210.4758,1865.7574,-68.0571  },    // Complex1
	{ "Complex 2", 0, 1, 1989.8632,1067.8206,-71.7498   },   // Complex 2
	{ "Complex 3", 0, 1, 1171.2406,-239.7676,1179.6224   },   // Complex 3
	{ "Complex 4", 0, 1, 1168.6182,-438.9774,1130.0347  },    // Complex 4
	{ "Complex 5", 0, 1, 2789.2275,739.8632,1501.0013  },    // Complex 5
	{ "Complex 6", 0, 1, 1897.4014,740.3871,1501.2316  }, // Complex 6
	{ "Complex 7", 0, 1, 321.1049,1159.7836,1082.9302  }, // Complex 7
	{ "Complex 8", 0, 1, 2796.7466,-2156.4238,3001.5610  }, // Complex 8
	{ "Complex 9", 0, 2, 1400.4620,-17.2363,1001.4073  }, // Complex 9
	{ "Complex 10", 0, 1, 2402.6016,-176.0470,1736.7772  }, // Complex 10
	{ "Complex 11", 0, 1, 1487.1323,1523.3840,1603.4261  }, // Complex 11
	{ "Apartment 1", 0, 1, 1843.8546,-2361.0588,2487.6294  }, // Apartment 1
	{ "Apartment 2", 0, 1, 2618.3408,-1815.2076,617.4919  }, // Apartment 2
	{ "Apartment 3", 0, 1, 2178.8264,-666.1164,442.3491  }, // Apartment 3
	{ "Apartment 4", 0, 1, 723.7535,-1428.1183,1202.0721  }, // Apartment 4
	{ "Apartment 5", 0, 1, 2188.2688,-1665.8885,2502.5593  }, // Apartment 5
	{ "Trailer 1", 0, 1, 1473.8297,-215.3166,1937.5388  }, // Trailer1
	{ "Trailer 2", 0, 1, 2511.4895,-1727.9388,779.3510  }, // Trailer2
	{ "Trailer 3", 0, 1, 2332.5002,-1048.4272,1045.0232  }, // Trailer3
	{ "Trailer 4", 0, 1, 1311.9780,1263.0730,1501.9403  }, // Trailer4
	{ "Trailer 5", 0, 1, 1333.3636,1261.4926,1502.1198  }, // Trailer5
	{ "Trailer 6", 0, 1, 1287.7584,1258.2716,1502.5531  }, // Trailer6
	{ "Trailer 7", 0, 1, 2214.9761,-464.2764,1024.7301  }, // Trailer7
	{ "Gang HQ 1", 0, 1, -725.2900,2401.8767,1501.9838  }, // VagosHQ
	{ "Gang HQ 2", 0, 1, -719.4052,2235.3372,1501.7385  }, // VagosHQ 2
	{ "House 1", 0, 1, 2746.1519,431.6871,1579.4985  }, // House1
	{ "House 2 (Mansion)", 0, 1, 1443.2800,-1066.7719,1602.8243  }, // House 2 mansion
	{ "House 3 (Mansion)", 0, 1, -1206.4120,2382.4626,1502.4351  }, // House 3 mansion
	{ "House 4", 0, 1, -1513.4395,2722.0825,1501.9766  }, // House 4 big
	{ "House 5", 0, 1, 2216.6270,2078.8489,1601.0787  }, // House 5
	{ "House 6", 0, 1, 1409.1124,-5.5639,2502.2571  }, // House 6 big
	{ "House 7", 0, 1, -1563.9719,-252.8627,1501.7155  }, // House 7 big
	{ "House 8 (Cabin)", 0, 1, 729.8820,1799.6466,1603.4083  }, // House 8 Cabin
	{ "House 9", 0, 1, 2216.8679,2079.0950,2601.6563  }, // House 9
	{ "House 10", 0, 1, 1971.6770,-1548.1030,2452.9343  }, // House 10
	{ "House 11", 0, 1, 2439.8689,-101.2453,1147.8069  }, // House 11
	{ "House 12", 0, 1, 2435.8206,-1621.4635,1569.6183  }, // House 12
	{ "House 13", 0, 1, 846.6713,19.6871,994.7552  }, // House 13
	{ "House 14", 0, 1, 856.6798,31.1193,582.3383  }, // House 14
	{ "House 15", 0, 1, -1486.4183,-378.8898,1154.2606  }, // House 15
	{ "House 16", 0, 1, -1049.7173,-1182.3622,1119.4387  }, // House 16
	{ "House 17 (Catalina)", 0, 1, 871.8015,-22.9988,54.7635  }, // House 17 (Catalina)
	{ "Garage 1", 0, 1, 2246.4604,33.1872,1639.8688  }, // Garage1
	{ "Garage 2", 0, 1, 549.1351,-96.5841,2999.5066  }, // Garage2
	{ "Garage 3", 0, 1, 722.1710,-243.6343,3001.8945  }, // Garage3
	{ "Garage 4", 0, 1, 756.9140,65.8938,3003.5833  }, // Garage4
	{ "Empty House 1", 0, 1, 2435.3130,-1621.9636,1569.4135  }, // EmptyHouse1
	{ "Empty House 2", 0, 1, 237.6488,242.1796,1000.1683  }, // EmptyHouse2
	{ "Empty House 3", 0, 1, 260.7400,1239.1252,1089.4569  }, // EmptyHouse3
	{ "Sewers 1", 0, 1, -769.0294,444.1798,17.0868  }, // Sewers1
	{ "Sewer 2", 0, 1, 116.3221,344.6188,102.8071  }, // Sewers2
	{ "SD 2", 0, 1, 1612.3967,-1629.3032,3084.3250  },    // SD2
	{ "SD 1", 0, 1, 1214.9083,1939.5902,4507.5854  }    // SD1

} ;

Interior_ListNatives (playerid ) {


	if ( PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] <= 0 ) {
		PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] = 1 ;
	}


	// Pagination stuff
	new MAX_ITEMS_ON_PAGE = 10, string [ 1024 ], bool: nextpage ;
    new resultcount = ( ( MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] ) - MAX_ITEMS_ON_PAGE ) ;

    strcat(string, "Interior ID\t Description\n");

    for ( new i = resultcount; i < sizeof (  InteriorData ); i ++ ) {

		resultcount ++ ;

        if ( resultcount <= MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] ) {

			format(string, sizeof(string), "%s%d \t %s\n", string, 
				i,
				InteriorData [ i ] [ E_PROP_INT_DESC ] ); 
        }

     	if ( resultcount >= MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] ) {

            nextpage = true;
            break;
        }
	}

	new pages = floatround ( resultcount / MAX_ITEMS_ON_PAGE, floatround_floor ) + 1 ;

    if ( nextpage ) {
    	strcat(string, "Next Page >>" ) ;
    }

	inline interior_list_data(pid, dialogid, response, listitem, string: inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		new selection = ( ( MAX_ITEMS_ON_PAGE * PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] ) - MAX_ITEMS_ON_PAGE ) + listitem;

		if ( ! response ) {

			if ( PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] > 1 ) {

				PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] -- ;
				return Interior_ListNatives (playerid ) ;
			}
		}

		if ( response ) {

			if ( listitem >= MAX_ITEMS_ON_PAGE) {

				PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] ++ ;
				return Interior_ListNatives (playerid ) ;
			}

			else if ( listitem < MAX_ITEMS_ON_PAGE ) {

				SetPlayerInterior(playerid, InteriorData [ selection ] [ E_PROP_INT_INT ] ) ;
				SetPlayerVirtualWorld(playerid, InteriorData [ selection ] [ E_PROP_INT_VW ] ) ;
				PauseAC(playerid, 3);
				SetPlayerPos(playerid, InteriorData [ selection ] [ E_PROP_INT_POS_X ], InteriorData [ selection ] [ E_PROP_INT_POS_Y ], InteriorData [ selection ] [ E_PROP_INT_POS_Z ] ) ;

				SendClientMessage(playerid, -1, sprintf("You've teleported to \"%s\".",
					InteriorData [ selection ] [ E_PROP_INT_DESC ] ) ) ;

 				return true ;
			}
		}
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ] > 1 ) {
		Dialog_ShowCallback ( playerid, using inline interior_list_data, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Property Interior List: Page %d of %d", PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ], pages), string, "Select", "Previous" ) ;
	}

	else Dialog_ShowCallback ( playerid, using inline interior_list_data, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Property Interior List: Page %d of %d", PlayerVar [ playerid ] [ E_PLAYER_INT_LIST_PAGE ], pages), string, "Select", "Back" ) ;

	return true ;
}