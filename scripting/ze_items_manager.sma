#include <amxmodx>
#include <ze_core>

// Macro.
#define FIsItemValid(%0) (ZE_ITEM_WRONG<(%0)<x_iMaxItems)

// Menu Timeout.
const CS_MENU_TIMEOUT = 45

enum _:ITEM_DATA
{
	ITEM_NAME[MAX_NAME_LENGTH] = 0,
	ITEM_COST,
	ITEM_LIMIT,
	ITEM_LEVEL,
	ITEM_GLIMIT
}

enum _:FORWARDS
{
	FORWARD_SELECT_ITEM_PRE = 0,
	FORWARD_SELECT_ITEM_POST
}

// CVars.
new g_iMaxPurchases,
	bool:g_bMenuSounds

// Variables.
new g_iFwReturn

// Array.
new g_iForwards[FORWARDS],
	g_iMenuPage[MAX_PLAYERS+1],
	g_iPurchases[MAX_PLAYERS+1],
	g_aItems[ZE_MAX_ITEMS][ITEM_DATA]

// String.
new g_szText[64]

// XVar.
public x_iMaxItems,
	x_bItemsDisabled

public plugin_natives()
{
	register_library("ze_items_manager")
	register_native("ze_item_register", "__native_item_register")
	register_native("ze_item_register_ex", "__native_item_register_ex")
	register_native("ze_register_item", "__native_item_register")
	register_native("ze_item_get_name", "__native_item_get_name")
	register_native("ze_item_get_cost", "__native_item_get_cost")
	register_native("ze_item_get_limit", "__native_item_get_limit")
	register_native("ze_item_get_level", "__native_item_get_level")
	register_native("ze_item_get_glimit", "__native_item_get_glimit")
	register_native("ze_item_get_num_pur", "__native_item_get_num_pur")
	register_native("ze_item_add_text", "__native_item_add_text")
	register_native("ze_item_force_buy", "__native_item_force_buy")
	register_native("ze_item_is_valid", "__native_item_is_valid")
	register_native("ze_item_set_name", "__native_item_set_name")
	register_native("ze_item_set_cost", "__native_item_set_cost")
	register_native("ze_item_set_limit", "__native_item_set_limit")
	register_native("ze_item_set_level", "__native_item_set_level")
	register_native("ze_item_set_glimit", "__native_item_set_glimit")
	register_native("ze_item_set_num_pur", "__native_item_set_num_pur")
	register_native("ze_item_show_menu", "__native_item_show_menu")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Items Manager", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_menu_sounds", "1"), g_bMenuSounds)
	bind_pcvar_num(register_cvar("ze_purchase_limits", "0"), g_iMaxPurchases)

	// Commands.
	register_clcmd("say /items", "cmd_ShowItemsMenu")
	register_clcmd("say_team /items", "cmd_ShowItemsMenu")

	// Create Forwards.
	g_iForwards[FORWARD_SELECT_ITEM_PRE] = CreateMultiForward("ze_select_item_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_SELECT_ITEM_POST] = CreateMultiForward("ze_select_item_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

public plugin_end()
{
	// Free the Memory.
	DestroyForward(g_iForwards[FORWARD_SELECT_ITEM_PRE])
	DestroyForward(g_iForwards[FORWARD_SELECT_ITEM_POST])
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id))
		return

	g_iMenuPage[id] = 0
	g_iPurchases[id] = 0
}

public ze_game_started()
{
	arrayset(g_iPurchases, 0, sizeof(g_iPurchases))
}

public cmd_ShowItemsMenu(const id)
{
	if (x_bItemsDisabled)
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "MSG_ITEMS_DISABLED")
		return PLUGIN_HANDLED
	}

	if (!is_user_alive(id))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if (g_iMaxPurchases > 0)
	{
		if (g_iPurchases[id] >= g_iMaxPurchases)
		{
			ze_colored_print(id, "%L", LANG_PLAYER, "MSG_MAX_PURCHASES", g_iMaxPurchases)
			return PLUGIN_HANDLED
		}
	}

	show_Items_Menu(id)
	return PLUGIN_CONTINUE
}

public show_Items_Menu(const id)
{
	// Menu Title.
	new iMenu = menu_create(fmt("%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_ITEMS_TITLE"), "handler_Items_Menu")

	new iItemData[2]
	for (new szLang[64], iItem = 0; iItem < x_iMaxItems; iItem++)
	{
		g_szText = NULL_STRING

		// Call forward ze_select_item_pre(param1, param2, param3, param4)
		ExecuteForward(g_iForwards[FORWARD_SELECT_ITEM_PRE], g_iFwReturn, id, iItem, false, true)

		if (g_iFwReturn >= ZE_ITEM_DONT_SHOW)
		{
			continue
		}
		else if (g_iFwReturn >= ZE_ITEM_UNAVAILABLE)
		{
			formatex(szLang, charsmax(szLang), "\d%s %d %s", g_aItems[iItem][ITEM_NAME], g_aItems[iItem][ITEM_COST], g_szText)
		}
		else
		{
			formatex(szLang, charsmax(szLang), "\w%s \y%d %s", g_aItems[iItem][ITEM_NAME], g_aItems[iItem][ITEM_COST], g_szText)
		}

		iItemData[0] = iItem

		// Add item name to Menu.
		menu_additem(iMenu, szLang, iItemData)
	}

	if (!menu_items(iMenu))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "MSG_NO_ITEMS")

		// Free the Memory.
		menu_destroy(iMenu)
		return
	}

	if (g_bMenuSounds)
		ze_res_menu_sound(id, ZE_MENU_DISPLAY)

	// Next, Back, Exit.
	menu_setprop(iMenu, MPROP_NEXTNAME, fmt("%L", LANG_PLAYER, "NEXT"))
	menu_setprop(iMenu, MPROP_BACKNAME, fmt("%L", LANG_PLAYER, "BACK"))
	menu_setprop(iMenu, MPROP_EXITNAME, fmt("%L", LANG_PLAYER, "EXIT"))

	if (menu_pages(iMenu) < g_iMenuPage[id]+1)
		g_iMenuPage[id] = 0

	// Show menu for the player.
	menu_display(id, iMenu, g_iMenuPage[id], CS_MENU_TIMEOUT)
}

public handler_Items_Menu(id, iMenu, iKey)
{
	if (g_bMenuSounds)
		ze_res_menu_sound(id, ZE_MENU_SELECT)

	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CLOSE_MENU
		}
	}

	if (x_bItemsDisabled)
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "MSG_ITEMS_DISABLED")
		goto CLOSE_MENU
	}

	if (!is_user_alive(id))
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "CMD_NOT_ALIVE")
		goto CLOSE_MENU
	}

	new iItemData[2]
	menu_item_getinfo(iMenu, iKey, _, iItemData, charsmax(iItemData))

	// Buy item.
	buy_Item(id, iItemData[0], false)
	g_iMenuPage[id] = iKey / 7

	// Free the Memory.
	CLOSE_MENU:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

/**
 * -=| Function |=-
 */
buy_Item(const id, iItem, bool:bIgnoreCost)
{
	// Call forward ze_select_item_pre(param1, param2, param3, param4)
	ExecuteForward(g_iForwards[FORWARD_SELECT_ITEM_PRE], g_iFwReturn, id, iItem, bIgnoreCost, false)

	if (g_iFwReturn >= ZE_ITEM_UNAVAILABLE)
		return false

	// Call forward ze_select_item_post(param1, param2)
	g_iPurchases[id]++
	ExecuteForward(g_iForwards[FORWARD_SELECT_ITEM_POST], g_iFwReturn, id, iItem, bIgnoreCost)
	return true
}

/**
 * -=| Natives |=-
 */
public __native_item_register(const plugin_id, const num_params)
{
	if (x_iMaxItems >= ZE_MAX_ITEMS)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't override maximum items (Max: %d)", ZE_MAX_ITEMS)
		return ZE_ITEM_WRONG
	}

	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register an item without name.")
		return ZE_ITEM_WRONG
	}

	for (new iItem = 0; iItem < x_iMaxItems; iItem++)
	{
		if (equal(szName, g_aItems[iItem][ITEM_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't register an item with exist name.")
			return ZE_ITEM_WRONG
		}
	}

	new szItemName[MAX_NAME_LENGTH]
	copy(szItemName, charsmax(szItemName), szName)

	// Cost.
	new iCost
	if ((iCost = get_param(2)) < 0)
		iCost = 0

	// Limit
	new iLimit, iGLimit, iLevel
	if ((iLimit = get_param(3)) < 0)
		iLimit = 0

	// Read Item Name, Cost and Limit from INI file.
	if (!ini_read_string(ZE_ET_FILENAME, szName, "NAME", szItemName, charsmax(szItemName)))
		ini_write_string(ZE_ET_FILENAME, szName, "NAME", szItemName)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "COST", iCost))
		ini_write_int(ZE_ET_FILENAME, szName, "COST", iCost)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit))
		ini_write_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "LEVEL", iLevel))
		ini_write_int(ZE_ET_FILENAME, szName, "LEVEL", iLevel)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "GLOBAL_LIMIT", iGLimit))
		ini_write_int(ZE_ET_FILENAME, szName, "GLOBAL_LIMIT", iGLimit)

	// Copy item data on Array.
	copy(g_aItems[x_iMaxItems][ITEM_NAME], charsmax(g_aItems[]) - ITEM_NAME, szItemName)
	g_aItems[x_iMaxItems][ITEM_COST] = iCost
	g_aItems[x_iMaxItems][ITEM_LIMIT] = iLimit
	g_aItems[x_iMaxItems][ITEM_LEVEL] = iLevel
	g_aItems[x_iMaxItems][ITEM_GLIMIT] = iGLimit

	// New Item.
	return ++x_iMaxItems - 1
}

public __native_item_register_ex(const plugin_id, const num_params)
{
	if (x_iMaxItems >= ZE_MAX_ITEMS)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't override maximum items (Max: %d)", ZE_MAX_ITEMS)
		return ZE_ITEM_WRONG
	}

	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register an item without name.")
		return ZE_ITEM_WRONG
	}

	for (new iItem = 0; iItem < x_iMaxItems; iItem++)
	{
		if (equal(szName, g_aItems[iItem][ITEM_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't register an item with exist name.")
			return ZE_ITEM_WRONG
		}
	}

	new szItemName[MAX_NAME_LENGTH]
	copy(szItemName, charsmax(szItemName), szName)

	// Cost.
	new iCost
	if ((iCost = get_param(2)) < 0)
		iCost = 0

	// Limit.
	new iLimit
	if ((iLimit = get_param(3)) < 0)
		iLimit = 0

	// Level.
	new iLevel
	if ((iLevel = get_param(4)) < 0)
		iLevel = 0

	// Global limit.
	new iGLimit
	if ((iGLimit = get_param(5)) < 0)
		iGLimit = 0

	// Read Item Name, Cost and Limit from INI file.
	if (!ini_read_string(ZE_ET_FILENAME, szName, "NAME", szItemName, charsmax(szItemName)))
		ini_write_string(ZE_ET_FILENAME, szName, "NAME", szItemName)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "COST", iCost))
		ini_write_int(ZE_ET_FILENAME, szName, "COST", iCost)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit))
		ini_write_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "LEVEL", iLevel))
		ini_write_int(ZE_ET_FILENAME, szName, "LEVEL", iLevel)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "GLOBAL_LIMIT", iGLimit))
		ini_write_int(ZE_ET_FILENAME, szName, "GLOBAL_LIMIT", iGLimit)

	// Copy item data on Array.
	copy(g_aItems[x_iMaxItems][ITEM_NAME], charsmax(g_aItems[]) - ITEM_NAME, szItemName)
	g_aItems[x_iMaxItems][ITEM_COST] = iCost
	g_aItems[x_iMaxItems][ITEM_LIMIT] = iLimit
	g_aItems[x_iMaxItems][ITEM_LEVEL] = iLevel
	g_aItems[x_iMaxItems][ITEM_GLIMIT] = iGLimit

	// New Item.
	return ++x_iMaxItems - 1
}

public __native_item_get_name(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return 0
	}

	return set_string(2, g_aItems[iItem][ITEM_NAME], get_param(3))
}

public __native_item_get_cost(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_COST]
}

public __native_item_get_limit(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_LIMIT]
}

public __native_item_get_level(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_LEVEL]
}

public __native_item_get_glimit(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_GLIMIT]
}

public __native_item_get_num_pur(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return -1
	}

	return g_iPurchases[id]
}

public __native_item_add_text(const plugin_id, const num_params)
{
	get_string(1, g_szText, charsmax(g_szText))
	return vdformat(g_szText, charsmax(g_szText), 1, 2)
}

public __native_item_force_buy(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new const iItem = get_param(2)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	new const bool:bIgnoreCost = get_param(3) ? true : false

	buy_Item(id, iItem, bIgnoreCost)
	return true
}

public __native_item_set_name(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return 0
	}

	new szName[MAX_NAME_LENGTH]
	if (!get_string(2, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't change item name without a name.")
		return 0
	}

	for (new i = 0; i < x_iMaxItems; i++)
	{
		if (equal(szName, g_aItems[i][ITEM_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't change an item name with duplicate one.")
			return 0
		}
	}

	return copy(g_aItems[iItem][ITEM_NAME], charsmax(g_aItems[]), szName)
}

public __native_item_set_cost(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	g_aItems[iItem][ITEM_COST] = get_param(2)
	return true
}

public __native_item_set_limit(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	g_aItems[iItem][ITEM_LIMIT] = get_param(3)
	return true
}

public __native_item_set_level(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	g_aItems[iItem][ITEM_LEVEL] = get_param(3)
	return true
}

public __native_item_set_glimit(const plugin_id, const num_params)
{
	new const iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	g_aItems[iItem][ITEM_GLIMIT] = get_param(3)
	return true
}

public __native_item_is_valid(const plugin_id, const num_params)
{
	if (FIsItemValid(get_param(1)))
		return true
	return false
}

public __native_item_set_num_pur(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (bool: get_param(3))
		g_iPurchases[id] += get_param(2)
	else
		g_iPurchases[id] = get_param(2)
	return true
}

public __native_item_show_menu(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", id)
		return false
	}

	if (!cmd_ShowItemsMenu(id))
		return false

	return true
}