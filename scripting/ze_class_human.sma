#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ze_levels>
#include <ze_class_const>
#include <ze_class_survivor>

// Libraries
stock const LIBRARY_LEVELS[] = "ze_levels"
stock const LIBRARY_HUDINFO[] = "ze_hud_info"
stock const LIBRARY_SURVIVOR[] = "ze_class_survivor"
stock const LIBRARY_WPNMODELS[] = "ze_weap_models_api"

// Macro.
#define FIsWrongClass(%0) (ZE_CLASS_INVALID>=(%0)>=g_iNumHumans)

// Menu Timeout
const ZE_MENU_TIMEOUT = 30   // -1 = No time.

// Human Attributes.
enum _:HUMAN_ATTRIB
{
	HUMAN_NAME[MAX_NAME_LENGTH] = 0,
	HUMAN_DESC[64],
	HUMAN_MODEL[MAX_NAME_LENGTH],
	Float:HUMAN_HEALTH,
	Float:HUMAN_ARMOR,
	HUMAN_SPEED_FACTOR,
	Float:HUMAN_SPEED,
	Float:HUMAN_GRAVITY,
	HUMAN_LEVEL
}

// Colors indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

enum _:TOTAL_FORWARDS
{
	FORWARD_SELECT_CLASS_PRE = 0,
	FORWARD_SELECT_CLASS_POST
}

// Default Human Attributes.
stock const DEFAULT_HUMAN_NAME[] = "Regular Human"
stock const DEFAULT_HUMAN_DESC[] = "-= Balanced =-"
stock const DEFAULT_HUMAN_MODEL[] = "gign"
stock const Float:DEFAULT_HUMAN_HEALTH = 255.0
stock const Float:DEFAULT_HUMAN_ARMOR = 0.0
stock const DEFAULT_HUMAN_SPEED_FACTOR = 1
stock const Float:DEFAULT_HUMAN_SPEED = 25.0
stock const Float:DEFAULT_HUMAN_GRAVITY = 800.0
stock const DEFAULT_HUMAN_LEVEL = 0

// Shield Attack Sound.
new g_szShieldAttackSound[MAX_RESOURCE_PATH_LENGTH] = "player/bhit_helmet-1.wav"

// Variable.
new g_iFwResult,
	g_iNumHumans,
	g_msgWeapPickup

// Cvars.
new bool:g_bHumanShield,
	bool:g_bWeaponStrips,
	g_iHudColor[Colors]

// Arrays.
new g_iNext[MAX_PLAYERS+1],
	g_iPage[MAX_PLAYERS+1],
	g_iCurrent[MAX_PLAYERS+1],
	g_iForwards[TOTAL_FORWARDS]

// String.
new g_szText[64]

// Dynamic Array.
new Array:g_aHumanClass

public plugin_natives()
{
	register_library("ze_class_human")
	register_native("ze_hclass_register", "__native_hclass_register")
	register_native("ze_hclass_get_current", "__native_hclass_get_current")
	register_native("ze_hclass_get_next", "__native_hclass_get_next")
	register_native("ze_hclass_is_valid", "__native_hclass_is_valid")
	register_native("ze_hclass_get_name", "__native_hclass_get_name")
	register_native("ze_hclass_get_desc", "__native_hclass_get_desc")
	register_native("ze_hclass_get_model", "__native_hclass_get_model")
	register_native("ze_hclass_get_health", "__native_hclass_get_health")
	register_native("ze_hclass_get_armor", "__native_hclass_get_armor")
	register_native("ze_hclass_is_speed_factor", "__native_hclass_is_speed_factor")
	register_native("ze_hclass_get_speed", "__native_hclass_get_speed")
	register_native("ze_hclass_get_gravity", "__native_hclass_get_gravity")
	register_native("ze_hclass_get_level", "__native_hclass_get_level")
	register_native("ze_hclass_get_index", "__native_hclass_get_index")
	register_native("ze_hclass_set_current", "__native_hclass_set_current")
	register_native("ze_hclass_set_next", "__native_hclass_set_next")
	register_native("ze_hclass_set_name", "__native_hclass_set_name")
	register_native("ze_hclass_set_desc", "__native_hclass_set_desc")
	register_native("ze_hclass_set_health", "__native_hclass_set_health")
	register_native("ze_hclass_set_armor", "__native_hclass_set_armor")
	register_native("ze_hclass_set_speed_factor", "__native_hclass_set_speed_factor")
	register_native("ze_hclass_set_speed", "__native_hclass_set_speed")
	register_native("ze_hclass_set_gravity", "__native_hclass_set_gravity")
	register_native("ze_hclass_set_level", "__native_hclass_set_level")
	register_native("ze_hclass_add_text", "__native_hclass_add_text")
	register_native("ze_hclass_show_menu", "__native_hclass_show_menu")

	set_module_filter("fw_module_filter")
	set_native_filter("fw_native_filter")

	// Create new dyn Array.
	g_aHumanClass = ArrayCreate(HUMAN_ATTRIB, 1)
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_HUDINFO) || equal(module, LIBRARY_WPNMODELS) || equal(module, LIBRARY_LEVELS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	// Read attack shield sound from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sounds", "SHIELD_ATTACK", g_szShieldAttackSound, charsmax(g_szShieldAttackSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "SHIELD_ATTACK", g_szShieldAttackSound)

	// Precache Sound.
	precache_sound(g_szShieldAttackSound)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Human", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_human_shield", "1"), g_bHumanShield)
	bind_pcvar_num(register_cvar("ze_human_weapon_strip", "1"), g_bWeaponStrips)

	bind_pcvar_num(register_cvar("ze_hud_info_human_red", "0"), g_iHudColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_human_green", "127"), g_iHudColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_human_blue", "255"), g_iHudColor[Blue])

	// Create Forwards.
	g_iForwards[FORWARD_SELECT_CLASS_PRE] = CreateMultiForward("ze_select_hclass_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_STRING, FP_STRING, FP_FLOAT, FP_FLOAT, FP_CELL, FP_FLOAT, FP_FLOAT, FP_CELL)
	g_iForwards[FORWARD_SELECT_CLASS_POST] = CreateMultiForward("ze_select_hclass_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_STRING, FP_STRING, FP_STRING, FP_FLOAT, FP_FLOAT, FP_CELL, FP_FLOAT, FP_FLOAT, FP_CELL)

	// Commands.
	register_clcmd("say /hm", "cmd_ShowClassesMenu")
	register_clcmd("say_team /hm", "cmd_ShowClassesMenu")
	register_clcmd("say /hclass", "cmd_ShowClassesMenu")
	register_clcmd("say_team /hclass", "cmd_ShowClassesMenu")

	// Initial Value.
	g_msgWeapPickup = get_user_msgid("WeapPickup")
}

public plugin_cfg()
{
	if (!g_iNumHumans)
	{
		new aArray[HUMAN_ATTRIB]

		// Default Human.
		copy(aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME, DEFAULT_HUMAN_NAME)
		copy(aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC, DEFAULT_HUMAN_DESC)
		copy(aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL, DEFAULT_HUMAN_MODEL)
		aArray[HUMAN_HEALTH] = DEFAULT_HUMAN_HEALTH
		aArray[HUMAN_ARMOR] = DEFAULT_HUMAN_ARMOR
		aArray[HUMAN_SPEED_FACTOR] = 1
		aArray[HUMAN_SPEED] = DEFAULT_HUMAN_SPEED
		aArray[HUMAN_GRAVITY] = DEFAULT_HUMAN_GRAVITY
		aArray[HUMAN_LEVEL] = DEFAULT_HUMAN_LEVEL

		// Copy Array on dyn Array.
		ArrayPushArray(g_aHumanClass, aArray)
		g_iNumHumans = 1
	}
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aHumanClass)
	DestroyForward(g_iForwards[FORWARD_SELECT_CLASS_PRE])
	DestroyForward(g_iForwards[FORWARD_SELECT_CLASS_POST])
}

public client_putinserver(id)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iCurrent[id] = ZE_CLASS_INVALID
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iPage[id] = 0
	g_iNext[id] = 0
	g_iCurrent[id] = 0
}

public cmd_ShowClassesMenu(const id)
{
	show_Humans_Menu(id)
	return PLUGIN_CONTINUE
}

public ze_user_humanized(id)
{
	// Ignore Survivor!
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && ze_is_user_survivor(id)) return

	// Player hasn't chosen a class yet?
	if (g_iCurrent[id] == ZE_CLASS_INVALID)
		RequestFrame("show_Humans_Menu", id)

	new iClassID = g_iNext[id]

	// Get Human attributes.
	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, iClassID, aArray)

	// ze_select_hclass_pre(param1, param2, param3, param4, string5, string6, string7, fparam8, fparam9, param10, fparam11, fparam12, param13)
	ExecuteForward(g_iForwards[FORWARD_SELECT_CLASS_PRE], g_iFwResult, id, iClassID, true, false, aArray[HUMAN_NAME], aArray[HUMAN_DESC], aArray[HUMAN_MODEL], aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], aArray[HUMAN_SPEED_FACTOR], aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY], aArray[HUMAN_LEVEL])

	if (g_iFwResult >= ZE_CLASS_UNAVAILABLE)
		return

	g_iCurrent[id] = iClassID

	set_entvar(id, var_health, aArray[HUMAN_HEALTH])
	set_entvar(id, var_max_health, aArray[HUMAN_HEALTH])
	set_entvar(id, var_gravity, (aArray[HUMAN_GRAVITY] / 800.0))

	if (g_bWeaponStrips)
	{
		// Strips all Weapons for player.
		rg_remove_all_items(id)

		// Give player Knife Weapon.
		set_msg_block(g_msgWeapPickup, BLOCK_ONCE) // This message already sent by GameDLL.
		rg_give_item(id, "weapon_knife", GT_APPEND)
	}

	ze_set_user_speed(id, aArray[HUMAN_SPEED], bool:aArray[HUMAN_SPEED_FACTOR])

	if (LibraryExists(LIBRARY_HUDINFO, LibType_Library))
	{
		ze_hud_info_set(id, aArray[HUMAN_NAME], g_iHudColor)
	}

	rg_set_user_model(id, aArray[HUMAN_MODEL], true)

	if (LibraryExists(LIBRARY_WPNMODELS, LibType_Library))
	{
		ze_remove_user_view_model(id, CSW_KNIFE)
		ze_remove_user_weap_model(id, CSW_KNIFE)
	}

	// ze_select_hclass_post(param1, param2, param3, string4, string5, string6, fparam7, fparam8, param9, fparam10, fparam11, param12)
	ExecuteForward(g_iForwards[FORWARD_SELECT_CLASS_POST], g_iFwResult, id, iClassID, true, aArray[HUMAN_NAME], aArray[HUMAN_DESC], aArray[HUMAN_MODEL], aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], aArray[HUMAN_SPEED_FACTOR], aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY], aArray[HUMAN_LEVEL])
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	if (!iInfector)
		return ZE_CONTINUE

	if (g_bHumanShield)
	{
		static Float:flArmor; flArmor = get_entvar(iVictim, var_armorvalue)

		if (flArmor - flDamage < 0.0)
		{
			set_entvar(iVictim, var_armorvalue, 0.0)
		}
		else
		{
			set_entvar(iVictim, var_armorvalue, flArmor - flDamage)

			// Attack sound.
			emit_sound(iVictim, CHAN_BODY, g_szShieldAttackSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			return ZE_BREAK // Prevent infection event.
		}
	}

	return ZE_CONTINUE
}

public show_Humans_Menu(const id)
{
	new szLang[MAX_MENU_LENGTH], iLevel

	// Title.
	formatex(szLang, charsmax(szLang), "\r%L \y%L:", LANG_PLAYER, "MENU_PREFIX", LANG_PLAYER, "MENU_HUMANS_TITLE")
	new iMenu = menu_create(szLang, "handler_Humans_Menu")
	new const fLevel = LibraryExists(LIBRARY_LEVELS, LibType_Library)

	if (fLevel)
		iLevel = ze_get_user_level(id)

	for (new aArray[HUMAN_ATTRIB], iItemData[2], i = 0; i < g_iNumHumans; i++)
	{
		g_szText = NULL_STRING
		ArrayGetArray(g_aHumanClass, i, aArray)

		// ze_select_hclass_pre(param1, param2, param3, param4, string5, string6, string7, fparam8, fparam9, param10, fparam11, fparam12, param13)
		ExecuteForward(g_iForwards[FORWARD_SELECT_CLASS_PRE], g_iFwResult, id, i, false, true, aArray[HUMAN_NAME], aArray[HUMAN_DESC], aArray[HUMAN_MODEL], aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], aArray[HUMAN_SPEED_FACTOR], aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY], aArray[HUMAN_LEVEL])

		if (g_iFwResult >= ZE_CLASS_DONT_SHOW)
			continue

		if (g_iFwResult == ZE_CLASS_UNAVAILABLE)
			formatex(szLang, charsmax(szLang), "\d%s • %s%s", aArray[HUMAN_NAME], aArray[HUMAN_DESC], g_szText)
		else if (fLevel && iLevel < aArray[HUMAN_LEVEL])
			formatex(szLang, charsmax(szLang), "\d%s • %s%s \r[\r%L\d: \y%i\r]", aArray[HUMAN_NAME], aArray[HUMAN_DESC], g_szText, LANG_PLAYER, "MENU_LEVEL", aArray[HUMAN_LEVEL])
		else if (i == g_iCurrent[id])
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s%s \d[\r%L\d]", aArray[HUMAN_NAME], aArray[HUMAN_DESC], g_szText, LANG_PLAYER, "CURRENT")
		else if (i == g_iNext[id])
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s%s \d[\r%L\d]", aArray[HUMAN_NAME], aArray[HUMAN_DESC], g_szText, LANG_PLAYER, "NEXT")
		else
			formatex(szLang, charsmax(szLang), "\w%s \d• \y%s%s", aArray[HUMAN_NAME], aArray[HUMAN_DESC], g_szText)

		iItemData[0] = i

		menu_additem(iMenu, szLang, iItemData)
	}

	// Next, Back, Exit.
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "NEXT")
	menu_setprop(iMenu, MPROP_NEXTNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "BACK")
	menu_setprop(iMenu, MPROP_BACKNAME, szLang)
	formatex(szLang, charsmax(szLang), "%L", LANG_PLAYER, "EXIT")
	menu_setprop(iMenu, MPROP_EXITNAME, szLang)

	// Show the Menu for player.
	menu_display(id, iMenu, g_iPage[id], ZE_MENU_TIMEOUT)
}

public handler_Humans_Menu(const id, iMenu, iKey)
{
	switch (iKey)
	{
		case MENU_TIMEOUT, MENU_EXIT:
		{
			goto CloseMenu
		}
		default:
		{
			new iItemData[2]
			menu_item_getinfo(iMenu, iKey, .info = iItemData, .infolen = charsmax(iItemData))
			new const i = iItemData[0]

			if (assign_PlayerClassID(id, i))
				g_iPage[id] = iKey / 7
		}
	}

	CloseMenu:
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public assign_PlayerClassID(const id, iClassID)
{
	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, iClassID, aArray)

	// ze_select_hclass_pre(param1, param2, param3, param4, string5, string6, string7, fparam8, fparam9, param10, fparam11, fparam12, param13)
	ExecuteForward(g_iForwards[FORWARD_SELECT_CLASS_PRE], g_iFwResult, id, iClassID, false, false, aArray[HUMAN_NAME], aArray[HUMAN_DESC], aArray[HUMAN_MODEL], aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], aArray[HUMAN_SPEED_FACTOR], aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY], aArray[HUMAN_LEVEL])

	if (g_iFwResult >= ZE_CLASS_UNAVAILABLE)
		return 0

	if (LibraryExists(LIBRARY_LEVELS, LibType_Library) && ze_get_user_level(id) < aArray[HUMAN_LEVEL])
	{
		ze_colored_print(id, "%L", LANG_PLAYER, "MSG_LVL_NOT_ENOUGH")
		return 0
	}

	// ze_select_hclass_post(param1, param2, param3, string4, string5, string6, fparam7, fparam8, param9, fparam10, fparam11, param12)
	ExecuteForward(g_iForwards[FORWARD_SELECT_CLASS_POST], g_iFwResult, id, iClassID, false, aArray[HUMAN_NAME], aArray[HUMAN_DESC], aArray[HUMAN_MODEL], aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], aArray[HUMAN_SPEED_FACTOR], aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY], aArray[HUMAN_LEVEL])
	g_iNext[id] = iClassID

	// Send colored message on chat for player.
	ze_colored_print(id, "%L", LANG_PLAYER, "MSG_HUMAN_NAME", aArray[HUMAN_NAME])
	ze_colored_print(id, "%L", LANG_PLAYER, "MSG_HUMAN_INFO", aArray[HUMAN_HEALTH], aArray[HUMAN_ARMOR], LANG_PLAYER, aArray[HUMAN_SPEED_FACTOR] ? "DYNAMIC" : "STATIC", aArray[HUMAN_SPEED], aArray[HUMAN_GRAVITY])
	return 1
}

/**
 * -=| Natives |=-
 */
public __native_hclass_register(const plugin_id, const num_params)
{
	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register new class without name.")
		return ZE_CLASS_INVALID
	}

	new aArray[HUMAN_ATTRIB]
	for (new i = 0; i < g_iNumHumans; i++)
	{
		ArrayGetArray(g_aHumanClass, i, aArray)

		if (equal(szName, aArray[HUMAN_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't register new class with exist name.")
			return ZE_CLASS_INVALID
		}
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "NAME", aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME))
	{
		copy(aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME, szName)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "NAME", aArray[HUMAN_NAME])
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "DESC", aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC))
	{
		get_string(2, aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "DESC", aArray[HUMAN_DESC])
	}

	if (!ini_read_string(ZE_FILENAME_HCLASS, szName, "MODEL", aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL))
	{
		get_string(3, aArray[HUMAN_MODEL], charsmax(aArray) - HUMAN_MODEL)
		ini_write_string(ZE_FILENAME_HCLASS, szName, "MODEL", aArray[HUMAN_MODEL])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "HEALTH", aArray[HUMAN_HEALTH]))
	{
		aArray[HUMAN_HEALTH] = get_param_f(4)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "HEALTH", aArray[HUMAN_HEALTH])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "ARMOR", aArray[HUMAN_ARMOR]))
	{
		aArray[HUMAN_ARMOR] = get_param_f(5)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "ARMOR", aArray[HUMAN_ARMOR])
	}

	if (!ini_read_int(ZE_FILENAME_HCLASS, szName, "SPEED_FACTOR", aArray[HUMAN_SPEED_FACTOR]))
	{
		aArray[HUMAN_SPEED_FACTOR] = get_param(6)
		ini_write_int(ZE_FILENAME_HCLASS, szName, "SPEED_FACTOR", aArray[HUMAN_SPEED_FACTOR])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "SPEED", aArray[HUMAN_SPEED]))
	{
		aArray[HUMAN_SPEED] = get_param_f(7)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "SPEED", aArray[HUMAN_SPEED])
	}

	if (!ini_read_float(ZE_FILENAME_HCLASS, szName, "GRAVITY", aArray[HUMAN_GRAVITY]))
	{
		aArray[HUMAN_GRAVITY] = get_param_f(8)
		ini_write_float(ZE_FILENAME_HCLASS, szName, "GRAVITY", aArray[HUMAN_GRAVITY])
	}

	if (!ini_read_int(ZE_FILENAME_HCLASS, szName, "LEVEL", aArray[HUMAN_LEVEL]))
	{
		aArray[HUMAN_LEVEL] = get_param(9)
		ini_write_int(ZE_FILENAME_HCLASS, szName, "LEVEL", aArray[HUMAN_LEVEL])
	}

	new szModel[MAX_RESOURCE_PATH_LENGTH]

	// Precache Models.
	formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", aArray[HUMAN_MODEL], aArray[HUMAN_MODEL])
	precache_model(szModel)

	// Copy array on dyn Array.
	ArrayPushArray(g_aHumanClass, aArray)
	return ++g_iNumHumans - 1
}

public __native_hclass_get_current(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return ZE_CLASS_INVALID
	}

	return g_iCurrent[id]
}

public __native_hclass_get_next(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return ZE_CLASS_INVALID
	}

	return g_iNext[id]
}

public __native_hclass_is_valid(const plugin_id, const num_params)
{
	if (FIsWrongClass(get_param(1)))
		return false
	return true
}

public __native_hclass_get_name(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return 0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	return set_string(2, aArray[HUMAN_NAME], get_param(3))
}

public __native_hclass_get_desc(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return 0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	return set_string(2, aArray[HUMAN_DESC], get_param(3))
}

public __native_hclass_get_model(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return 0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)

	// Copy Name on new Buffer.
	return set_string(2, aArray[HUMAN_MODEL], get_param(3))
}

public Float:__native_hclass_get_health(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_HEALTH]
}

public Float:__native_hclass_get_armor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_ARMOR]
}

public __native_hclass_is_speed_factor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return ZE_CLASS_INVALID
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_SPEED_FACTOR]
}

public Float:__native_hclass_get_speed(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_SPEED]
}

public Float:__native_hclass_get_gravity(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return -1.0
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_GRAVITY]
}

public __native_hclass_get_level(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return ZE_CLASS_INVALID
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	return aArray[HUMAN_LEVEL]
}

public __native_hclass_get_index(const plugin_id, const num_params)
{
	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't search class index without name !")
		return ZE_CLASS_INVALID
	}

	for (new aArray[HUMAN_ATTRIB], i = 0; i < g_iNumHumans; i++)
	{
		ArrayGetArray(g_aHumanClass, i, aArray)
		if (equal(szName, aArray[HUMAN_NAME]))
			return i
	}

	return ZE_CLASS_INVALID
}

public __native_hclass_set_current(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new const i = get_param(2)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	g_iCurrent[id] = i

	if (get_param(3))
	{
		ze_set_user_zombie(id)
	}

	return true
}

public __native_hclass_set_next(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new const i = get_param(2)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	g_iNext[id] = i
	return true
}

public __native_hclass_set_name(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	get_string(2, aArray[HUMAN_NAME], charsmax(aArray) - HUMAN_NAME)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_desc(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	get_string(2, aArray[HUMAN_DESC], charsmax(aArray) - HUMAN_DESC)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_health(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_HEALTH] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_armor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_ARMOR] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_speed_factor(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_SPEED_FACTOR] = get_param(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_speed(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_SPEED] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_gravity(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_GRAVITY] = get_param_f(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_set_level(const plugin_id, const num_params)
{
	new const i = get_param(1)

	if (FIsWrongClass(i))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Class ID (%d)", i)
		return false
	}

	new aArray[HUMAN_ATTRIB]
	ArrayGetArray(g_aHumanClass, i, aArray)
	aArray[HUMAN_LEVEL] = get_param(2)
	ArraySetArray(g_aHumanClass, i, aArray)
	return true
}

public __native_hclass_add_text(const plugin_id, const num_params)
{
	get_string(1, g_szText, charsmax(g_szText))
	return vdformat(g_szText, charsmax(g_szText), 1, 2)
}

public __native_hclass_show_menu(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	show_Humans_Menu(id)
	return true
}