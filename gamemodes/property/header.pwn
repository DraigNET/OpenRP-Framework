// ============================================================================
// File: property/header.pwn
// Property module entry point: includes data, functions and utils.
// ============================================================================

new PlayerText: house_info_box[MAX_PLAYERS] = PlayerText: INVALID_TEXT_DRAW ; //  CROSS REFERENCED --- managed in property/func/gui.pwn

enum _:PROPERTY_ENTER_TYPES {
	PROPERTY_NEAR_ENTER,
	PROPERTY_NEAR_EXIT,
	PROPERTY_NEAR_ANYWHERE
}

// Property commands use the late-loaded placement adapter.
forward Runtime_PropertyEntranceInUse(index);

#include "property/data/header.pwn"
#include "property/func/header.pwn"
#include "property/utils/header.pwn"
