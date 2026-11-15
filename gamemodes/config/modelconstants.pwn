// ============================================================================
// File: config/modelconstants.pwn
// Constants for stock models used by built-in systems (fuel pumps, vending machines,
// turn-signal light) and the base model ids used when registering custom models.
// ============================================================================

// Custom model helpers.
//
// The framework ships with no custom models. These are the stock "base" model
// IDs commonly used as the baseid argument of AddSimpleModel when you add your own.
#define CUSTOM_OBJECT_BASEID    (1923) // poker chip, no col
#define BASEID 19379	// default (retains COL of object ID if no COL attached to custom model)
#define ALPHA 19478		// particles not visible. Best for plants, wires etc. (BACKFACE ENABLED)
#define SALPHA 19325	// ability to see particles through alpha textures e.g. windows (BACKFACE ENABLED)
#define VALPHA 11680	// custom models with vertex alpha and/or textures with low opacity e.g. shadows (BACKFACE DISABLED)
#define DOOR 1499

// Stock models used by built-in systems. Swap these for custom models if you add your own.
#define FUELSYS_PUMP_1          (1676)  // Stock fuel pump (regular)
#define FUELSYS_PUMP_2          (1686)  // Stock fuel pump
#define FUELSYS_PUMP_3          (1676)
#define FUELSYS_PUMP_4          (1686)
#define TDW_SIGNAL_OBJECT_ID    (18650) // Stock yellow neon tube, used as the vehicle turn-signal light
#define E_VENDING_MACHINE_SPRUNK (955)  // Stock Sprunk vending machine
#define E_VENDING_MACHINE_ECOLA  (956)  // Stock snack/soda vending machine
#define E_VENDING_CAN_SPRUNK_SMALL (2601) // Stock soda can
#define E_VENDING_CAN_SPRUNK_BIG   (2601)
#define E_VENDING_CAN_ECOLA_SMALL  (1546) // Stock soda can
#define E_VENDING_CAN_ECOLA_BIG    (1546)
