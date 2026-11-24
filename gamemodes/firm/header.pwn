// ============================================================================
// File: firm/header.pwn
// Firm module entry point: constants (FIRM_FIELD_*, creation fee) and includes for the firm
// files.
// ============================================================================

#if !defined INVALID_FIRM_ID
    #define INVALID_FIRM_ID         (-1)
#endif

#define MAX_FIRMS                   (100)
#define MAX_FIRM_NAME               (64)
#define MAX_FIRM_ABBREV             (8)
#define MAX_FIRM_RANK_NAME          (32)

#define FIRM_FIELD_NONE             (0)
#define FIRM_FIELD_MECHANIC         (1)
#define FIRM_FIELD_SECURITY         (2)
#define FIRM_FIELD_LAWYER           (3)
#define FIRM_FIELD_TRANSIT          (4)
#define FIRM_FIELD_LOGISTICS        (5)
#define FIRM_FIELD_MEDIA            (6)
#define FIRM_FIELD_USEDCARS         (7)
#define FIRM_FIELD_REALESTATE       (8)

#define FIRM_STATUS_PENDING         (0)
#define FIRM_STATUS_ACTIVE          (1)
#define FIRM_STATUS_SUSPENDED       (2)
#define FIRM_STATUS_CLOSED          (3)

#define FIRM_PERM_INVITE            (1)
#define FIRM_PERM_KICK              (2)
#define FIRM_PERM_RANKS             (4)
#define FIRM_PERM_BANK              (8)
#define FIRM_PERM_FIELD_TOOLS       (16)
#define FIRM_PERM_VEHICLES          (32)
#define FIRM_PERM_SETTINGS          (64)
#define FIRM_PERM_PROPERTIES        (128)   // real estate: buy, price, rent and manage the firm's properties
#define FIRM_PERM_ALL               (255)

#define FIRM_CREATE_BASE_FEE (Runtime_Int(RT_FIRMS_CREATION_FEE)) // Cached database setting; edit through ACP.
#define USEDCARS_DEFAULT_SLOTS      (15)    // lot size a new used car firm starts with

#include "firm/data.pwn"
#include "firm/func.pwn"
#include "firm/workflow.pwn"
#include "firm/commands.pwn"
#include "firm/jobs/transit.pwn"
#include "firm/jobs/lawyer.pwn"
#include "firm/jobs/usedcars.pwn"
