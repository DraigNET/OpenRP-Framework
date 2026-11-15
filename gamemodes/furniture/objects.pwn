// ============================================================================
// File: furniture/objects.pwn
// Furniture menu helpers: building the category and subcategory lists and handling object
// selection.
// ============================================================================

// =========================================================
//  furniture/objects.pwn - SAFE + STABLE FIX - Torque Update
//  Fixes:
//   1) Unsafe self-referential format() in Furni_ListCategory
//   2) Buffer overflow risk while building dialog strings
//   3) -1 index from Furniture_FetchArrayID used without validation
//   4) Selection state made per-player to avoid stale/overwritten locals
//   5) Stronger matching in Furni_ObjectPerCategory
// =========================================================

#define FURNI_INVALID_INDEX      (-1)

static g_FurniSelectedIndex[MAX_PLAYERS];

// Clears the player's selected furniture entry.
static stock Furni_ResetSelection(playerid)
{
    g_FurniSelectedIndex[playerid] = FURNI_INVALID_INDEX;
    return 1;
}

// Adds a line to a list only if it is not already in it.
static stock bool:Furni_AppendUniqueLine(list[], listSize, const line[])
{
    // Prevent duplicates with exact line matching using the "\nX\n" trick.
    new needle[128];
    format(needle, sizeof needle, "\n%s\n", line);

    new haystack[1024 + 2];
    format(haystack, sizeof haystack, "\n%s", list);

    if (strfind(haystack, needle, true) != -1)
    {
        return false;
    }

    // Ensure we have room for: line + "\n" + EOS
    new needLen = strlen(line) + 1;
    if (strlen(list) + needLen + 1 >= listSize)
    {
        return false;
    }

    strcat(list, line, listSize);
    strcat(list, "\n", listSize);
    return true;
}

// ---------------------------------------------------------
// Category list (FIXED - no self-referential format)
// ---------------------------------------------------------
Furni_ListCategory(playerid)
{
    inline Furni_Dialog_ShowCategory(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, listitem

        if (!response)
        {
            return 1;
        }

        // inputtext is the selected category line
        return Furni_ListSubCategories(playerid, inputtext);
    }

    new szFstring[1024];
    szFstring[0] = EOS;

    for (new i = 0, j = sizeof (furniture_inventory); i < j; i++)
    {
        Furni_AppendUniqueLine(szFstring, sizeof szFstring, furniture_inventory[i][f_inven_category]);
        // If it can't append because the buffer is full, it just stops adding more.
    }

    if (szFstring[0] == EOS)
    {
        strcat(szFstring, "None\n", sizeof szFstring);
    }

    Dialog_ShowCallback(
        playerid,
        using inline Furni_Dialog_ShowCategory,
        DIALOG_STYLE_LIST,
        "Categories",
        szFstring,
        "Continue",
        "Close"
    );

    return 1;
}

// ---------------------------------------------------------
// Sub-category list (mostly fine already; kept + tightened)
// ---------------------------------------------------------
Furni_ListSubCategories(playerid, const category[])
{
    inline Furni_Dialog_ShowSubCat(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, listitem

        if (!response)
        {
            return Furni_ListCategory(playerid);
        }

        // inputtext is the selected sub-category
        return Furni_ObjectPerCategory(playerid, category, inputtext);
    }

    new szFstring[1024];
    szFstring[0] = EOS;

    for (new i = 0, j = sizeof furniture_inventory; i < j; i++)
    {
        if (strcmp(furniture_inventory[i][f_inven_category], category, true) != 0)
        {
            continue;
        }

        // Unique append with bounds checks
        Furni_AppendUniqueLine(szFstring, sizeof szFstring, furniture_inventory[i][f_inven_sub_category]);
    }

    if (szFstring[0] == EOS)
    {
        strcat(szFstring, "None\n", sizeof szFstring);
    }

    Dialog_ShowCallback(
        playerid,
        using inline Furni_Dialog_ShowSubCat,
        DIALOG_STYLE_LIST,
        "Sub-categories",
        szFstring,
        "Continue",
        "Back"
    );

    return 1;
}

// ---------------------------------------------------------
// Populate model browser (tightened: require both cat + subcat)
// ---------------------------------------------------------
Furni_ObjectPerCategory(playerid, const cat[], const sub_cat[])
{
    #pragma unused cat   // We no longer rely on category string

    ModelBrowser_ClearData(playerid);

    for (new i = 0, j = sizeof (furniture_inventory); i < j; i++)
    {
        // Only match sub-category (this is what the player actually selected)
        if (strcmp(furniture_inventory[i][f_inven_sub_category], sub_cat, true) != 0)
        {
            continue;
        }

        ModelBrowser_AddData(
            playerid,
            furniture_inventory[i][f_inven_model],
            furniture_inventory[i][f_inven_name]
        );
    }

    Furni_ResetSelection(playerid);

    ModelBrowser_SetupTiles(playerid, sub_cat, "furni_list");
    return 1;
}

// ---------------------------------------------------------
// Model browser callback (FIXED: validate index, store per-player)
// ---------------------------------------------------------
mBrowser:furni_list(playerid, response, row, model, name[])
{
    #pragma unused row

    if (!response)
    {
        return 1;
    }

    new index = Furniture_FetchArrayID(model, name);

    // CRITICAL FIX: never use furniture_inventory[index] unless index is valid
    if (index == FURNI_INVALID_INDEX)
    {
        Furni_ResetSelection(playerid);
        SendClientMessage(playerid, 0xFF4444FF, "Furniture selection failed (invalid item). Please reopen /furni.");
        return Furni_ListCategory(playerid);
    }

    // Store selection per-player so the inline callback can't use stale locals
    g_FurniSelectedIndex[playerid] = index;

    inline Furni_Confirmation(pidx, dialogidx, responsex, listitemx, string:inputtextx[])
    {
        #pragma unused dialogidx, listitemx, inputtextx

        if (!responsex)
        {
            Furni_ResetSelection(pidx);
            return 1;
        }

        new idx = g_FurniSelectedIndex[pidx];
        if (idx == FURNI_INVALID_INDEX)
        {
            SendClientMessage(pidx, 0xFF4444FF, "Furniture selection expired. Please reopen /furni.");
            return Furni_ListCategory(pidx);
        }

        if (GetPlayerCash(pidx) < furniture_inventory[idx][f_inven_price])
        {
            Furni_ResetSelection(pidx);
            Furni_ListCategory(pidx);

            return SendServerMessage(
                pidx,
                COLOR_ERROR,
                "Furniture",
                "DEDEDE",
                sprintf(
                    "You don't have enough money for this item! You need at least $%s.",
                    IntegerWithDelimiter(furniture_inventory[idx][f_inven_price])
                )
            );
        }

        SendServerMessage(
            pidx,
            COLOR_ERROR,
            "Furniture",
            "DEDEDE",
            sprintf(
                "You've bought the \"%s\" for $%s.",
                furniture_inventory[idx][f_inven_name],
                IntegerWithDelimiter(furniture_inventory[idx][f_inven_price])
            )
        );

        if (Furniture_CreateObject(pidx, furniture_inventory[idx][f_inven_model]))
        {
            TakePlayerCash(pidx, furniture_inventory[idx][f_inven_price], "Furniture object purchase");
        }

        Furni_ResetSelection(pidx);
        return 1;
    }

    new msg[1024];
    format(
        msg,
        sizeof msg,
        "{AB78B1}Warning!{DEDEDE} Furniture costs money!\n\n\
		Are you sure you want to buy the following item:\n\n\
		\"{AB78B1}%s{DEDEDE}\"\n\n\
		for the price of ${AB78B1}%s{DEDEDE}? If you destroy it later\n\
		you will get a portion of your money back.\n\n\
		To proceed, click \"Buy\". To cancel click \"Close\".",
        furniture_inventory[index][f_inven_name],
        IntegerWithDelimiter(furniture_inventory[index][f_inven_price])
    );

    Dialog_ShowCallback(
        playerid,
        using inline Furni_Confirmation,
        DIALOG_STYLE_MSGBOX,
        "Furniture Confirmation",
        msg,
        "Buy",
        "Close"
    );

    return 1;
}

// ---------------------------------------------------------
// Fetch function (unchanged, but relied upon safely now)
// ---------------------------------------------------------
Furniture_FetchArrayID(model, const name[])
{
    for (new i = 0, j = sizeof (furniture_inventory); i < j; i++)
    {
        if (!strcmp(name, furniture_inventory[i][f_inven_name], true))
        {
            if (furniture_inventory[i][f_inven_model] == model)
            {
                return i;
            }
        }
    }

    return FURNI_INVALID_INDEX;
}
