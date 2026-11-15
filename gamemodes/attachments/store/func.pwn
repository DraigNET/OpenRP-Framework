// ============================================================================
// File: attachments/store/func.pwn
// Store helpers: prices per store type (Attach_DetermineCost), and lookups from model id to
// store type and item name. Documents the ATTACH_TYPE_* numbering.
// ============================================================================

// Attachment store helpers.
//
// Store types (stored in attachpoint.attach_point_type):
//   0 Facewear      1 Headwear     2 Neckwear     3 Miscellaneous
//   4 Police (SAPD) 5 Fire (FDSA)
//   6 Chains        7 Watches      8 Rings        9 Jewelry misc
//   10 Barbershop hairstyles

#define ATTACH_TYPE_FACE       (0)
#define ATTACH_TYPE_HEAD       (1)
#define ATTACH_TYPE_NECK       (2)
#define ATTACH_TYPE_MISC       (3)
#define ATTACH_TYPE_SAPD       (4)
#define ATTACH_TYPE_FDSA       (5)
#define ATTACH_TYPE_CHAINS     (6)
#define ATTACH_TYPE_WATCHES    (7)
#define ATTACH_TYPE_RINGS      (8)
#define ATTACH_TYPE_JEWEL_MISC (9)
#define ATTACH_TYPE_BARBER     (10)
#define ATTACH_TYPE_MAX        (10)

// Runs `%2` for the entry in array %0 whose model matches %1.
#define ATTACH_FIND(%0,%1,%2) \
	for ( new _ai, _aj = sizeof ( %0 ); _ai < _aj ; _ai ++ ) { \
		if ( %0 [ _ai ] [ E_ATTACH_MODEL ] == %1 ) { %2 } \
	}

// Returns the price of one item for a store type.
Attach_DetermineCost(type) {

	switch ( type ) {

		case ATTACH_TYPE_FACE:       return 150 ;
		case ATTACH_TYPE_HEAD:       return 500 ;
		case ATTACH_TYPE_NECK:       return 250 ;
		case ATTACH_TYPE_MISC:       return 200 ;
		case ATTACH_TYPE_SAPD:       return 0 ;
		case ATTACH_TYPE_FDSA:       return 0 ;
		case ATTACH_TYPE_CHAINS:     return 9000 ;
		case ATTACH_TYPE_WATCHES:    return 8000 ;
		case ATTACH_TYPE_RINGS:      return 8500 ;
		case ATTACH_TYPE_JEWEL_MISC: return 8000 ;
		case ATTACH_TYPE_BARBER:     return 300 ;
	}

	return 125 ;
}

// Finds which store type a model belongs to by searching every item list. Returns -1 if it is not
// a store item.
Attach_GetType(modelid) {

	ATTACH_FIND(AttachStore_Clothing_Face,   modelid, return ATTACH_TYPE_FACE ;)
	ATTACH_FIND(AttachStore_Clothing_Head,   modelid, return ATTACH_TYPE_HEAD ;)
	ATTACH_FIND(AttachStore_Clothing_Neck,   modelid, return ATTACH_TYPE_NECK ;)
	ATTACH_FIND(AttachStore_Clothing_MISC,   modelid, return ATTACH_TYPE_MISC ;)
	ATTACH_FIND(AttachStore_Clothing_SAPD,   modelid, return ATTACH_TYPE_SAPD ;)
	ATTACH_FIND(AttachStore_Clothing_FDSA,   modelid, return ATTACH_TYPE_FDSA ;)
	ATTACH_FIND(AttachStore_Jewelry_Chains,  modelid, return ATTACH_TYPE_CHAINS ;)
	ATTACH_FIND(AttachStore_Jewelry_Watches, modelid, return ATTACH_TYPE_WATCHES ;)
	ATTACH_FIND(AttachStore_Jewelry_Rings,   modelid, return ATTACH_TYPE_RINGS ;)
	ATTACH_FIND(AttachStore_Jewelry_Extra,   modelid, return ATTACH_TYPE_JEWEL_MISC ;)
	ATTACH_FIND(AttachStore_Barber,          modelid, return ATTACH_TYPE_BARBER ;)

	return -1;
}

// Writes the display name of a store item (by store type and model id) into name.
Attach_GetName(type, modelid, name[], len=sizeof(name)) {

	switch ( type ) {

		case ATTACH_TYPE_FACE:       { ATTACH_FIND(AttachStore_Clothing_Face,   modelid, format ( name, len, "%s", AttachStore_Clothing_Face   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_HEAD:       { ATTACH_FIND(AttachStore_Clothing_Head,   modelid, format ( name, len, "%s", AttachStore_Clothing_Head   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_NECK:       { ATTACH_FIND(AttachStore_Clothing_Neck,   modelid, format ( name, len, "%s", AttachStore_Clothing_Neck   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_MISC:       { ATTACH_FIND(AttachStore_Clothing_MISC,   modelid, format ( name, len, "%s", AttachStore_Clothing_MISC   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_SAPD:       { ATTACH_FIND(AttachStore_Clothing_SAPD,   modelid, format ( name, len, "%s", AttachStore_Clothing_SAPD   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_FDSA:       { ATTACH_FIND(AttachStore_Clothing_FDSA,   modelid, format ( name, len, "%s", AttachStore_Clothing_FDSA   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_CHAINS:     { ATTACH_FIND(AttachStore_Jewelry_Chains,  modelid, format ( name, len, "%s", AttachStore_Jewelry_Chains  [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_WATCHES:    { ATTACH_FIND(AttachStore_Jewelry_Watches, modelid, format ( name, len, "%s", AttachStore_Jewelry_Watches [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_RINGS:      { ATTACH_FIND(AttachStore_Jewelry_Rings,   modelid, format ( name, len, "%s", AttachStore_Jewelry_Rings   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_JEWEL_MISC: { ATTACH_FIND(AttachStore_Jewelry_Extra,   modelid, format ( name, len, "%s", AttachStore_Jewelry_Extra   [ _ai ] [ E_ATTACH_NAME ] ) ;) }
		case ATTACH_TYPE_BARBER:     { ATTACH_FIND(AttachStore_Barber,          modelid, format ( name, len, "%s", AttachStore_Barber          [ _ai ] [ E_ATTACH_NAME ] ) ;) }

		default: {
			format ( name, len, "None" ) ;
		}
	}
}
