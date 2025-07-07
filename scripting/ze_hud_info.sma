#include <amxmodx>
#include <reapi>
#include <ze_core>

// Libraries.
stock const LIBRARY_COINS[] = "ze_coins_system"

// Color indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

enum _:Positions
{
	Float:POSIT_X = 0,
	Float:POSIT_Y
}

enum _:HUDs
{
	HUD_STATS[Positions] = 0,
	HUD_SPECS[Positions]
}

// Constant
const TASK_SHOWHUD = 100

// CVars.
new g_iMode,
	g_iStyle,
	g_iSpecColor[Colors]

// Variables.
new g_iHudInfoMsg

// Array.
new Float:g_flHudPosit[HUDs],
	g_iStatsColor[MAX_PLAYERS+1][Colors]

// String.
new g_szName[MAX_PLAYERS+1][MAX_NAME_LENGTH],
	g_szClass[MAX_PLAYERS+1][MAX_NAME_LENGTH]

public plugin_natives()
{
	register_library("ze_hud_info")
	register_native("ze_hud_info_set", "__native_hud_info_set")

	set_module_filter("fw_module_filter")
	set_native_filter("fw_native_filter")
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_COINS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] HUD Information's", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_hud_info_mode", "1"), g_iMode)
	bind_pcvar_num(register_cvar("ze_hud_info_style", "1"), g_iStyle)
	bind_pcvar_num(register_cvar("ze_hud_info_spectator_red", "200"), g_iSpecColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_spectator_green", "200"), g_iSpecColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_spectator_blue", "200"), g_iSpecColor[Blue])

	// Set Values.
	g_iHudInfoMsg = CreateHudSyncObj()
}

public plugin_cfg()
{
	g_flHudPosit[HUD_STATS][POSIT_X] = -1.0
	g_flHudPosit[HUD_STATS][POSIT_Y] = 0.86
	g_flHudPosit[HUD_SPECS][POSIT_X] = -1.0
	g_flHudPosit[HUD_SPECS][POSIT_Y] = 0.76

	// Read HUD positions from INI file.
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFO_SPEC_X", g_flHudPosit[HUD_SPECS][POSIT_X]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFO_SPEC_X", g_flHudPosit[HUD_SPECS][POSIT_X])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFO_SPEC_Y", g_flHudPosit[HUD_SPECS][POSIT_Y]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFO_SPEC_Y", g_flHudPosit[HUD_SPECS][POSIT_Y])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFO_STATS_X", g_flHudPosit[HUD_STATS][POSIT_X]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFO_STATS_X", g_flHudPosit[HUD_STATS][POSIT_X])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFO_STATS_Y", g_flHudPosit[HUD_STATS][POSIT_Y]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFO_STATS_Y", g_flHudPosit[HUD_STATS][POSIT_Y])
}

public client_putinserver(id)
{
	if (is_user_hltv(id))
		return

	// Get player's name.
	get_user_name(id, g_szName[id], charsmax(g_szName[]))

	// Task repeat display HUD info.
	set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, .flags = "b")
}

public client_infochanged(id)
{
	// Player disconnected?
	if (!is_user_connected(id) || is_user_hltv(id))
		return

	// Get new name of the player.
	get_user_info(id, "name", g_szName[id], charsmax(g_szName[]))
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id))
		return

	g_szName[id] = NULL_STRING
	g_szClass[id] = NULL_STRING

	// Remove task.
	remove_task(id+TASK_SHOWHUD)
}

public ShowHUD(taskid)
{
	if (!g_iMode) // Disabled?
		return

	static target, id

	id = target = taskid - TASK_SHOWHUD

	if (!is_user_alive(id))
	{
		if (get_entvar(id, var_iuser1) == OBS_ROAMING)
		{
			get_user_aiming(id, target)
		}
		else
		{
			target = get_entvar(id, var_iuser2)
		}

		if (!is_user_alive(target))
		{
			return
		}
	}

	static szMsg[256], szHealth[32], szShield[32], szCoins[32]

	if (id != target)
	{
		switch (g_iStyle)
		{
			case 0: // Disabled.
			{
				num_to_str(get_user_health(target), szHealth, charsmax(szHealth))
				num_to_str(get_user_armor(target), szShield, charsmax(szShield))
				num_to_str(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(target) : 0, szCoins, charsmax(szCoins))
			}
			case 1: // Commas.
			{
				AddCommas(get_user_health(target), szHealth, charsmax(szHealth))
				AddCommas(get_user_armor(target), szShield, charsmax(szShield))
				AddCommas(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(target) : 0, szCoins, charsmax(szCoins))
			}
			case 2: // Numeric Abbreviations.
			{
				NumAbbrev(get_user_health(target), szHealth, charsmax(szHealth))
				NumAbbrev(get_user_armor(target), szShield, charsmax(szShield))
				NumAbbrev(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(target) : 0, szCoins, charsmax(szCoins))
			}
		}

		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "HUD_INFO_SPEC")

		replace_string(szMsg, charsmax(szMsg), "{$name}", g_szName[target], false) // Name.
		replace_string(szMsg, charsmax(szMsg), "{$health}", szHealth, false) // Health.
		replace_string(szMsg, charsmax(szMsg), "{$shield}", szShield, false) // Shield.
		replace_string(szMsg, charsmax(szMsg), "{$class}", g_szClass[target], false) // Class.
		replace_string(szMsg, charsmax(szMsg), "{$coins}", szCoins, false) // Escape Coins.

		switch (g_iMode)
		{
			case 1: // HUD.
			{
				set_hudmessage(g_iSpecColor[Red], g_iSpecColor[Green], g_iSpecColor[Blue], g_flHudPosit[HUD_SPECS][POSIT_X], g_flHudPosit[HUD_SPECS][POSIT_Y], 0, 1.0, 1.0, 0.0, 0.1)
				ShowSyncHudMsg(id, g_iHudInfoMsg, szMsg)
			}
			case 2: // Director HUD.
			{
				set_dhudmessage(g_iSpecColor[Red], g_iSpecColor[Green], g_iSpecColor[Blue], g_flHudPosit[HUD_SPECS][POSIT_X], g_flHudPosit[HUD_SPECS][POSIT_Y], 0, 1.0, 1.0, 0.0, 0.1)
				show_dhudmessage(id, szMsg)
			}
		}
	}
	else // Alive?
	{
		switch (g_iStyle)
		{
			case 0: // Disabled.
			{
				num_to_str(get_user_health(id), szHealth, charsmax(szHealth))
				num_to_str(get_user_armor(id), szShield, charsmax(szShield))
				num_to_str(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(id) : 0, szCoins, charsmax(szCoins))
			}
			case 1: // Commas.
			{
				AddCommas(get_user_health(id), szHealth, charsmax(szHealth))
				AddCommas(get_user_armor(id), szShield, charsmax(szShield))
				AddCommas(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(id) : 0, szCoins, charsmax(szCoins))
			}
			case 2: // Numeric Abbreviations.
			{
				NumAbbrev(get_user_health(id), szHealth, charsmax(szHealth))
				NumAbbrev(get_user_armor(id), szShield, charsmax(szShield))
				NumAbbrev(LibraryExists(LIBRARY_COINS, LibType_Library) ? ze_get_user_coins(id) : 0, szCoins, charsmax(szCoins))
			}
		}

		formatex(szMsg, charsmax(szMsg), "%L", LANG_PLAYER, "HUD_INFO_STATS")

		replace_string(szMsg, charsmax(szMsg), "{$name}", g_szName[target], false) // Name.
		replace_string(szMsg, charsmax(szMsg), "{$health}", szHealth, false) // Health.
		replace_string(szMsg, charsmax(szMsg), "{$shield}", szShield, false) // Shield.
		replace_string(szMsg, charsmax(szMsg), "{$class}", g_szClass[target], false) // Class.
		replace_string(szMsg, charsmax(szMsg), "{$coins}", szCoins, false) // Escape Coins.

		switch (g_iMode)
		{
			case 1: // HUD.
			{
				set_hudmessage(g_iStatsColor[id][Red], g_iStatsColor[id][Green], g_iStatsColor[id][Blue], g_flHudPosit[HUD_STATS][POSIT_X], g_flHudPosit[HUD_STATS][POSIT_Y], 0, 1.0, 1.0, 0.0, 0.1)
				ShowSyncHudMsg(id, g_iHudInfoMsg, szMsg)
			}
			case 2: // Director HUD.
			{
				set_dhudmessage(g_iStatsColor[id][Red], g_iStatsColor[id][Green], g_iStatsColor[id][Blue], g_flHudPosit[HUD_STATS][POSIT_X], g_flHudPosit[HUD_STATS][POSIT_Y], 0, 1.0, 1.0, 0.0, 0.1)
				show_dhudmessage(id, szMsg)
			}
		}
	}
}

/**
 * -=| Natives |=-
 */
public __native_hud_info_set(const plugin_id, const num_params)
{
	new const id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new szClass[MAX_NAME_LENGTH]
	get_string(2, szClass, charsmax(szClass))

	// Class[].
	if (get_param(4))
	{
		if (!strlen(szClass))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] There is no translation key in class name !")
			return false
		}

		formatex(g_szClass[id], charsmax(g_szClass[]), "%L", LANG_PLAYER, szClass)
	}
	else
	{
		copy(g_szClass[id], charsmax(g_szClass[]), szClass)
	}

	// Color[3].
	get_array(3, g_iStatsColor[id], Colors)
	return true
}