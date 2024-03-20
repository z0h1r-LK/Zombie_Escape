#include <amxmodx>
#include <ze_core>

// Macro.
#define FIsItemValid(%0) (ZE_ITEM_WRONG<(%0)<x_iMaxItems)

enum _:ITEM_DATA
{
	ITEM_NAME[MAX_NAME_LENGTH] = 0,
	ITEM_COST,
	ITEM_LIMIT
}

enum _:FORWARDS
{
	FORWARD_SELECT_ITEM_PRE = 0,
	FORWARD_SELECT_ITEM_POST
}

// Menu Sounds.
new g_szSelectSound[MAX_RESOURCE_PATH_LENGTH] = "buttons/lightswitch2.wav"
new g_szDisplaySound[MAX_RESOURCE_PATH_LENGTH] = "buttons/lightswitch2.wav"

// CVars.
new bool:g_bMenuSounds

// Variables.
new g_iFwReturn

// Array.
new g_iForwards[FORWARDS],
	g_iMenuPage[MAX_PLAYERS+1],
	g_aItems[ZE_MAX_ITEMS][ITEM_DATA]

// String.
new g_szText[64]

// XVar.
public x_iMaxItems,
	x_bItemsDisabled

public plugin_natives()
{
	register_native("ze_item_register", "__native_item_register")
	register_native("ze_register_item", "__native_item_register")
	register_native("ze_item_get_name", "__native_item_get_name")
	register_native("ze_item_get_cost", "__native_item_get_cost")
	register_native("ze_item_get_limit", "__native_item_get_limit")
	register_native("ze_item_add_text", "__native_item_add_text")
	register_native("ze_item_force_buy", "__native_item_force_buy")
	register_native("ze_item_show_menu", "__native_item_show_menu")
}

public plugin_precache()
{
	// Read menu sounds from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sounds", "MENU_SELECT", g_szSelectSound, charsmax(g_szSelectSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "MENU_SELECT", g_szSelectSound)
	if (!ini_read_string(ZE_FILENAME, "Sounds", "MENU_DISPLAY", g_szDisplaySound, charsmax(g_szDisplaySound)))
		ini_write_string(ZE_FILENAME, "Sounds", "MENU_DISPLAY", g_szDisplaySound)

	// Precache Sounds.
	precache_generic(g_szSelectSound)
	precache_generic(g_szDisplaySound)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Items Manager", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_menu_sounds", "1"), g_bMenuSounds)

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

	show_Items_Menu(id)
	return PLUGIN_CONTINUE
}

public show_Items_Menu(const id)
{
	new szLang[64]

	// Menu Title.
	formatex(szLang, charsmax(szLang), "%L %L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_ITEMS_TITLE")

	new iMenu = menu_create(szLang, "handler_Items_Menu")
	new iItemData[2]
	for (new iItem = 0; iItem < x_iMaxItems; iItem++)
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
	{
		client_cmd(id, "speak ^"%s^"", g_szDisplaySound)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	// Show menu for the player.
	menu_display(id, iMenu, g_iMenuPage[id])
}

public handler_Items_Menu(id, iMenu, iKey)
{
	if (g_bMenuSounds)
	{
		client_cmd(id, "spk ^"%s^"", g_szSelectSound)
	}

	if (iKey == MENU_EXIT)
	{
		goto CLOSE_MENU
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
	menu_item_getinfo(iMenu, iKey, .info = iItemData, .infolen = charsmax(iItemData))

	// Get item index.
	new iItem = iItemData[0]

	// Buy item.
	buy_Item(id, iItem, false)

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
	new iLimit
	if ((iLimit = get_param(3)) < 0)
		iLimit = 0

	// Read Item Name, Cost and Limit from INI file.
	if (!ini_read_string(ZE_ET_FILENAME, szName, "NAME", szItemName, charsmax(szItemName)))
		ini_write_string(ZE_ET_FILENAME, szName, "NAME", szItemName)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "COST", iCost))
		ini_write_int(ZE_ET_FILENAME, szName, "COST", iCost)
	if (!ini_read_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit))
		ini_write_int(ZE_ET_FILENAME, szName, "LIMIT", iLimit)

	// Copy item data on Array.
	copy(g_aItems[x_iMaxItems][ITEM_NAME], charsmax(g_aItems[]) - ITEM_NAME, szItemName)
	g_aItems[x_iMaxItems][ITEM_COST] = iCost
	g_aItems[x_iMaxItems][ITEM_LIMIT] = iLimit

	// New Item.
	return ++x_iMaxItems - 1
}

public __native_item_get_name(const plugin_id, const num_params)
{
	new iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return 0
	}

	return set_string(1, g_aItems[iItem][ITEM_NAME], get_param(3))
}

public __native_item_get_cost(const plugin_id, const num_params)
{
	new iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_COST]
}

public __native_item_get_limit(const plugin_id, const num_params)
{
	new iItem = get_param(1)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return ZE_GAME_INVALID
	}

	return g_aItems[iItem][ITEM_LIMIT]
}

public __native_item_add_text(const plugin_id, const num_params)
{
	get_string(1, g_szText, charsmax(g_szText))
	vdformat(g_szText, charsmax(g_szText), 1, 2)
}

public __native_item_force_buy(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new iItem = get_param(2)

	if (!FIsItemValid(iItem))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", iItem)
		return false
	}

	new bool:bIgnoreCost = get_param(3) ? true : false

	buy_Item(id, iItem, bIgnoreCost)
	return true
}

public __native_item_show_menu(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Item id (%d)", id)
		return false
	}

	if (!cmd_ShowItemsMenu(id))
		return false

	return true
}