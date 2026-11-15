// ============================================================================
// File: attachments/store/clothing.pwn
// Item lists for clothing stores (face, head, neck, misc) and the restricted SAPD and FDSA gear
// lists. Add items as { modelid, "Name" }.
// ============================================================================


new AttachStore_Clothing_Neck [ ] [ E_ATTACH_DATA ] = {

	// SA-MP
	{ 11712, "Church Cross" }
};


new AttachStore_Clothing_Head [ ] [ E_ATTACH_DATA ] = {

	{ 19093, "White Hardhat" },
	{ 19116, "Black Hardhat" },
	{ 19117, "Red Hardhat" },
	{ 19118, "Green Hardhat" },
	{ 19119, "Blue Hardhat" },
	{ 19095, "Cowboy Hat Brown" },
	{ 19096, "Cowboy Hat Black" },
	{ 19097, "Cowboy Hat Red" },
	{ 19098, "Cowboy Hat Orange" },
	{ 19421, "Headphones White" },
	{ 19422, "Headphones Black" },
	{ 19423, "Headphones Red" },
	{ 19424, "Headphones Blue" },
	{ 19554, "OG LOC Beanie" },
	{ 19553, "Straw Hat" },
	{ 19558, "Pizzastack Cap" },
	{ 19141, "Helmet Black" },
    { 19514, "Helmet Grey" },
    { 18645, "Red Motorcycle Helmet" },
    { 18976, "Blue Motorcycle Helmet" },
    { 18977, "Red Solid Motorcycle Helmet" },
    { 18978, "White Motorcycle Helmet" },
    { 18979, "Pink Motorcycle Helmet" },
    { 18638, "Builder Hat Yellow" },
    { 18639, "Black Cowboy Hat" },
    { 18891,  "Blue Bandana" },
    { 18892,  "Red Bandana" },
    { 18893,  "Red and White Bandana" },
    { 18894,  "Orange Weed Bandana" },
    { 18895,  "Skull Bandana" },
    { 18896,  "Black Rag Bandana" },
    { 18897,  "Blue Bandana" },
    { 18898,  "Green Bandana" },
    { 18899,  "Pink Bandana" },
    { 18901,  "Leopard Bandana" },
    { 18902,  "Yellow Bandana" },
    { 18903,  "Cloudy Bandana" },
    { 18904,  "Thunder Bandana" },
    { 18905,  "Gold Bandana" },
    { 18906,  "Orange Bandana" },
    { 18909,  "Cloudy Bandana 2" },
    { 18910,  "Lava Bandana" },    
    { 18921,  "Black Beret" },
    { 18922,  "Red Beret" },
    { 18923,  "Blue Beret" },
    { 18924,  "Camo Beret" },
    { 18925,  "Army Beret" },
    { 18926,  "Camo Cap" },
    { 18929,  "Green Rag Cap" },
    { 18930,  "Lava Cap" },
    { 18931,  "Thunder Cap" },
    { 18933,  "White Rag Cap" },
    { 18934,  "Pink Cap" },
    { 18935,  "Cheese Cap" },
    { 18936,  "White Helmet" },
    { 18937,  "Red Helmet" },
    { 18938,  "Galaxy Helmet" },
    { 18939,  "Thunder Backwards Cap" },
    { 18940,  "Blue Terracota Backwards Cap" },
    { 18941,  "Black Backwards Cap" },
    { 18942,  "Grey Backwards Cap" },
    { 18943,  "Green Backwards Cap" },
    { 18946,  "Bowler Hat Grey" },
    { 18947,  "Bowler Hat Black" },
    { 18948,  "Bowler Hat Blue" },
    { 18949,  "Bowler Hat Green" },
    { 18950,  "Bowler Hat Red" },
    { 18951,  "Bowler Hat Yellow" },
    { 18952,  "Boxing Helmet" },
    { 18953,  "Black Beanie" },
    { 18954,  "Grey Beanie" },
    { 18961,  "Trucker Cap" },
    { 18962,  "Black Cowboy Hat 2" },
    { 18964,  "Penis Beanie Black" },
    { 18965,  "Penis Beanie Dark Green" },
    { 18967,  "Hatman Black" },
    { 18968,  "Hatman Light Blue" }
} ;


new AttachStore_Clothing_Face [ ] [ E_ATTACH_DATA ] = {
	{ 19006, "Red Glasses" },
	{ 19007, "Orange Glasses" },
	{ 19008, "Green Glasses" },
	{ 19009, "Blue Glasses" },
	{ 19010, "Pink Glasses" },
	{ 19011, "White Glasses" },
	{ 19012, "Grey Glasses" },
	{ 19013, "Black Glasses" },
	{ 19015, "Clear Glasses" },
	{ 19016, "Disco Glasses Orange" },
	{ 19022, "Disco Glasses White" },
	{ 19023, "Disco Glasses Cyan" },
	{ 19024, "Disco Glasses Purple" },
	{ 19025, "Disco Glasses Pink" },
	{ 19026, "Disco Glasses Red" },
	{ 19027, "Disco Glasses Orange" },
	{ 19028, "Disco Glasses Yellow" },
	{ 19029, "Disco Glasses Green" },
	{ 19030, "Clear Glasses 1" },
	{ 19031, "Clear Glasses 2" },
	{ 19032, "Clear Glasses 3" },
	{ 19034, "Clear Glasses 4" },
	{ 19035, "Thunder Glasses" },
	{ 19138, "Black Locs Glasses" },
	{ 19139, "Red Locs Glasses" },
	{ 19140, "Blue Locs Glasses" },
	{ 19033, "Black Glasses" },
	{ 19036, "White Hocker Mask" },
	{ 19037, "Red Hocker Mask" },
	{ 19038, "Green Hocker Mask" },
	{ 19472, "Gasmask" },
	{ 11704, "Devil Mask" },
    { 18911,  "Skull Mouth Bandana" },
    { 18912,  "Black Mouth Bandana" },
    { 18913,  "Green Mouth Bandana" },
    { 18914,  "Camo Mouth Bandana" },
    { 18915,  "Pink Mouth Bandana" },
    { 18916,  "Yellow Mouth Bandana" },
    { 18918,  "Green Mouth Bandana" },
    { 18919,  "White Mouth Bandana" }
};


new AttachStore_Clothing_MISC [ ] [ E_ATTACH_DATA ] = {
	{ 19555, "Boxing Glove Left" },
	{ 19556, "Boxing Glove Right" },
	{ 19559, "Travel Pack" },
	{ 19624, "Suitcase/Briefcase" },
	{ 19942, "Portable Radio" },
    { 2919, "Dufflebag" },
    { 11745, "Dufflebag 2" },
    { 371, "Backpack" },
    { 19893, "Laptop" },
    { 19893, "Laptop" },
    { 19773, "Gun holster" },
    { 11736, "First Aid Kit (Green)" },
    { 11738, "First Aid Kit (Red)" },    
    { 19572, "Pissh Crate" },
    { 3052, "Ammo Crate" },
    { 18633, "Wrench" },
    { 18634, "Crowbar" },
    { 18635, "Hammer" },
    { 18644, "Screwdriver" },
    { 18875, "Pager" }
};


// Stock accessory models; add faction-specific selections here if needed.

new AttachStore_Clothing_SAPD [ ] [ E_ATTACH_DATA ] = {


	{ 11749, "[SAPD] Handcuffs" },
	{ 11750, "[SAPD] Folded Handcuffs" },
	{ 19142, "[SAPD] SWAT Armour" },
	{ 19141, "[SAPD] SWAT Helmet"},
	{ 334, "[SAPD] Nightstick"},
	{ 19942, "[SAPD] Radio"},
	{ 18641, "[SAPD] Flashlight" },
	{ 19773, "[SAPD] Gun Holster"},
	{ 19472, "[SAPD] Gas Mask"}

};


new AttachStore_Clothing_FDSA [ ] [ E_ATTACH_DATA ] = {
	{ 366, "[FDSA] Fire Extinguisher" },
	{ 19330, "[FDSA] Firefighter Helmet" },
	{ 19942, "[FDSA] Radio"},
	{ 19472, "[FDSA] Gas Mask"},
	{ 19631, "[FDSA] Sledgehammer"},
	{ 18634, "[FDSA] Crowbar"},
	{ 11738, "[FDSA] Red Medical Box"},
	{ 11736, "[FDSA] First Aid Kit"}
};



