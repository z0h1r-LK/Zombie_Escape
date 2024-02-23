#include <amxmodx>
#include <ze_core>
#define LIBRARY_COINS "ze_coins_system"

// HUD Position.
const Float:HUD_SPEC_X = -1.0
const Float:HUD_SPEC_Y = 0.76

const Float:HUD_STATS_X = -1.0
const Float:HUD_STATS_Y = 0.86

// Color indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
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
new g_iStatsColor[MAX_PLAYERS+1][Colors]

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

public client_putinserver(id)
{
	// Get player's name.
	get_user_name(id, g_szName[id], charsmax(g_szName[]))

	// Task repeat display HUD info.
	set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, .flags = "b")
}

public client_infochanged(id)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return

	// HLTV Proxy?
	if (!is_user_hltv(id))
		return

	// Get new name of the player.
	get_user_info(id, "name", g_szName[id], charsmax(g_szName[]))
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	g_szName[id] = NULL_STRING
	g_szClass[id] = NULL_STRING

	// Remove task.
	remove_task(id+TASK_SHOWHUD)
}

public ShowHUD(taskid)
{
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

	if (id != target)
	{
		switch (g_iMode)
		{
			case 1:
			{
				set_hudmessage(g_iSpecColor[Red], g_iSpecColor[Green], g_iSpecColor[Blue], HUD_SPEC_X, HUD_SPEC_Y, 0, 1.0, 1.0, 0.0, 0.1)

				switch (g_iStyle)
				{
					case 0: // Disabled.
					{
						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_SPEC", g_szName[target], get_user_health(target), get_user_armor(target), g_szClass[target], ze_get_user_coins(target))
					}
					case 1: // Commas.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						AddCommas(get_user_health(target), szHP, charsmax(szHP))
						AddCommas(get_user_armor(target), szAP, charsmax(szAP))
						AddCommas(ze_get_user_coins(target), szEC, charsmax(szEC))

						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_SPEC_COMMAS", g_szName[target], szHP, szAP, g_szClass[target], szEC)
					}
					case 2: // Numeric Abbreviations.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						NumAbbrev(get_user_health(target), szHP, charsmax(szHP))
						NumAbbrev(get_user_armor(target), szAP, charsmax(szAP))
						NumAbbrev(ze_get_user_coins(target), szEC, charsmax(szEC))

						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_SPEC_NUM_ABBR", g_szName[target], szHP, szAP, g_szClass[target], szEC)
					}
				}
			}
			case 2:
			{
				set_dhudmessage(g_iSpecColor[Red], g_iSpecColor[Green], g_iSpecColor[Blue], HUD_SPEC_X, HUD_SPEC_Y, 0, 1.0, 1.0, 0.0, 0.1)

				switch (g_iStyle)
				{
					case 0: // Disabled.
					{
						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_SPEC", g_szName[target], get_user_health(target), get_user_armor(target), g_szClass[target], ze_get_user_coins(target))
					}
					case 1: // Commas.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						AddCommas(get_user_health(target), szHP, charsmax(szHP))
						AddCommas(get_user_armor(target), szAP, charsmax(szAP))
						AddCommas(ze_get_user_coins(target), szEC, charsmax(szEC))

						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_SPEC_COMMAS", g_szName[target], szHP, szAP, g_szClass[target], szEC)
					}
					case 2: // Numeric Abbreviations.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						NumAbbrev(get_user_health(target), szHP, charsmax(szHP))
						NumAbbrev(get_user_armor(target), szAP, charsmax(szAP))
						NumAbbrev(ze_get_user_coins(target), szEC, charsmax(szEC))

						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_SPEC_NUM_ABBR", g_szName[target], szHP, szAP, g_szClass[target], szEC)
					}
				}
			}
		}
	}
	else // Alive?
	{
		switch (g_iMode)
		{
			case 1:
			{
				set_hudmessage(g_iStatsColor[id][Red], g_iStatsColor[id][Green], g_iStatsColor[id][Blue], HUD_STATS_X, HUD_STATS_Y, 0, 1.0, 1.0, 0.0, 0.1)

				switch (g_iStyle)
				{
					case 0: // Disabled.
					{
						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_STATS", g_szName[id], get_user_health(id), get_user_armor(id), g_szClass[target], ze_get_user_coins(target))
					}
					case 1: // Commas.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						AddCommas(get_user_health(id), szHP, charsmax(szHP))
						AddCommas(get_user_armor(id), szAP, charsmax(szAP))
						AddCommas(ze_get_user_coins(id), szEC, charsmax(szEC))

						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_STATS_COMMAS", g_szName[id], szHP, szAP, g_szClass[id], szEC)
					}
					case 2: // Numeric Shortcuts.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						NumAbbrev(get_user_health(id), szHP, charsmax(szHP))
						NumAbbrev(get_user_armor(id), szAP, charsmax(szAP))
						NumAbbrev(ze_get_user_coins(id), szEC, charsmax(szEC))

						ShowSyncHudMsg(id, g_iHudInfoMsg, "%L", LANG_PLAYER, "HUD_INFO_STATS_NUM_ABBR", g_szName[id], szHP, szAP, g_szClass[id], szEC)
					}
				}
			}
			case 2:
			{
				set_dhudmessage(g_iStatsColor[id][Red], g_iStatsColor[id][Green], g_iStatsColor[id][Blue], HUD_STATS_X, HUD_STATS_Y, 0, 1.0, 1.0, 0.0, 0.1)

				switch (g_iStyle)
				{
					case 0: // Disabled.
					{
						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_STATS", g_szName[target], get_user_health(target), get_user_armor(target), g_szClass[target], ze_get_user_coins(target))
					}
					case 1: // Commas.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						AddCommas(get_user_health(id), szHP, charsmax(szHP))
						AddCommas(get_user_armor(id), szAP, charsmax(szAP))
						AddCommas(ze_get_user_coins(id), szEC, charsmax(szEC))

						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_STATS_COMMAS", g_szName[id], szHP, szAP, g_szClass[id], szEC)
					}
					case 2: // Numeric Shortcuts.
					{
						static szHP[32], szAP[32], szEC[32]
						szHP = NULL_STRING, szAP = NULL_STRING, szEC = NULL_STRING

						NumAbbrev(get_user_health(id), szHP, charsmax(szHP))
						NumAbbrev(get_user_armor(id), szAP, charsmax(szAP))
						NumAbbrev(ze_get_user_coins(id), szEC, charsmax(szEC))

						show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_INFO_STATS_NUM_ABBR", g_szName[id], szHP, szAP, g_szClass[id], szEC)
					}
				}
			}
		}
	}
}

/**
 * -=| Natives |=-
 */
public __native_hud_info_set(const plugin_id, const num_params)
{
	new id = get_param(1)

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