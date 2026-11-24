// ============================================================================
// File: paynspray/header.pwn
// Includes the Pay 'n' Spray files.
// ============================================================================

#define DIALOG_PNS_MAIN             5000
#define DIALOG_PNS_COLOR_INT        5001
#define DIALOG_PNS_COLOR_EXT        5002
#define DIALOG_PNS_PAINTJOB         5003
#define DIALOG_MECHANIC_COLOR_EXT   5004
#define DIALOG_MECHANIC_COLOR_INT   5005
#define DIALOG_MECHANIC_PAINTJOB    5006

#define PNS_BODYKIT_COST (Runtime_Int(RT_REPAIRS_BODYKIT_FEE)) // Cached database setting; edit through ACP.
#define PNS_ENGINE_COST (Runtime_Int(RT_REPAIRS_ENGINE_FEE)) // Cached database setting; edit through ACP.

#include "paynspray/locations.pwn"
#include "paynspray/natives.pwn"
#include "firm/jobs/mechanic.pwn"
#include "paynspray/cmds.pwn"
