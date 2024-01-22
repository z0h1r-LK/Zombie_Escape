#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>
#include <ini_file>
#include <ze_gamemodes_const>

// Macro.
#define FIsGameInvalid(%0) (ZE_GAME_INVALID>=%0>=g_iNumGames)

// HUD Event Positions
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.4

// Task IDs.
const TASK_COUNTDOWN = 100

// Constant.
const MAX_ATTEMPT = 2 // Number of Attempts trying choose a game mode.

// Custom Forwards.
enum any:FORWARDS
{
	FORWARD_GAMEMODE_CHOSEN_PRE = 0,
	FORWARD_GAMEMODE_CHOSEN
}

// Gamemode Data.
enum any:GAMEMODES
{
	GAME_NAME[MAX_NAME_LENGTH] = 0,
	GAME_FILE[256]
}

// Colors.
enum any:Colors
{
	Red = 0,
	Green,
	Blue
}

// CVars.
new g_iStartDelay,
	g_iCountdownMode,
	g_iCountdownColors[Colors],
	bool:g_bFirstRound,
	bool:g_bCountdownRandomColors

// Variables.
new g_iNext,
	g_iCurrent,
	g_iDefault,
	g_iNumGames,
	g_iFwReturn,
	g_iCountdown,
	g_iMsgCountdown

// XVars.
new g_xRoundNum,
	g_xGameChosen

// Array.
new g_iForwards[FORWARDS]

// Dynamic Array.
new Array:g_aGamemodes

public plugin_natives()
{
	register_library("ze_gamemodes")
	register_native("ze_gamemode_register", "__native_gamemode_register")
	register_native("ze_gamemode_set_default", "__native_gamemode_set_default")
	register_native("ze_gamemode_set_next", "__native_gamemode_set_next")
	register_native("ze_gamemode_get_next", "__native_gamemode_get_next")
	register_native("ze_gamemode_get_current", "__native_gamemode_get_current")
	register_native("ze_gamemode_get_name", "__native_gamemode_get_name")
	register_native("ze_gamemode_get_id", "__native_gamemode_get_id")
	register_native("ze_gamemode_get_count", "__native_gamemode_get_count")
	register_native("ze_gamemode_start", "__native_gamemode_start")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Gamemodes Manager", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_gamemodes_delay", "20"), g_iStartDelay)
	bind_pcvar_num(register_cvar("ze_gamemodes_firstround", "1"), g_bFirstRound)

	bind_pcvar_num(register_cvar("ze_countdown_mode", "2"), g_iCountdownMode)
	bind_pcvar_num(register_cvar("ze_countdown_random_color", "1"), g_bCountdownRandomColors)
	bind_pcvar_num(register_cvar("ze_countdown_red", "200"), g_iCountdownColors[Red])
	bind_pcvar_num(register_cvar("ze_countdown_green", "200"), g_iCountdownColors[Green])
	bind_pcvar_num(register_cvar("ze_countdown_blue", "200"), g_iCountdownColors[Blue])

	// Create Forwards.
	g_iForwards[FORWARD_GAMEMODE_CHOSEN_PRE] = CreateMultiForward("ze_gamemode_chosen_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_GAMEMODE_CHOSEN] = CreateMultiForward("ze_gamemode_chosen", ET_IGNORE, FP_CELL, FP_CELL)

	// Create dynamic array.
	g_aGamemodes = ArrayCreate(GAMEMODES, 1)

	// XVars.
	g_xRoundNum = get_xvar_id(X_Core_RoundNum)
	g_xGameChosen = get_xvar_id(X_Core_GamemodeBegin)

	// Set Values.
	g_iDefault = ZE_GAME_INVALID
	g_iMsgCountdown = CreateHudSyncObj()
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aGamemodes)

	DestroyForward(g_iForwards[FORWARD_GAMEMODE_CHOSEN_PRE])
	DestroyForward(g_iForwards[FORWARD_GAMEMODE_CHOSEN])
}

public ze_game_started_pre()
{
	g_iNext = ZE_GAME_INVALID
	g_iCurrent = ZE_GAME_INVALID

	// Remove countdown task.
	remove_task(TASK_COUNTDOWN)

	// Reset XVar.
	set_xvar_num(g_xGameChosen)

	// Pause all game modes plug-ins.
	new aArray[GAMEMODES]
	for (new i = 0; i < g_iNumGames; i++)
	{
		ArrayGetArray(g_aGamemodes, i, aArray)
		pause("ac", aArray[GAME_FILE])
	}
}

public ze_game_started()
{
	g_iCountdown = g_iStartDelay

	// Delay before start the game.
	set_task(1.0, "show_CountdownMsg", TASK_COUNTDOWN, .flags = "b")
}

public show_CountdownMsg(taskid)
{
	if (g_iCountdown <= 1)
	{
		remove_task(taskid)

		// Choose a game mode.
		choose_Gamemode()
	}
	else
	{
		g_iCountdown--
	}

	switch (g_iCountdownMode)
	{
		case 1: // Text Message.
		{
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_COUNTDOWN", g_iCountdown)
		}
		case 2: // HUD.
		{
			if (g_bCountdownRandomColors)
				set_hudmessage(random(256), random(256), random(256), HUD_EVENT_X, HUD_EVENT_Y, 0, 1.0, 1.0, 0.0, 0.0, 4)
			else
				set_hudmessage(g_iCountdownColors[Red], g_iCountdownColors[Green], g_iCountdownColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 0, 1.0, 1.0, 0.0, 0.0, 4)
			ShowSyncHudMsg(0, g_iMsgCountdown, "%L", LANG_PLAYER, "HUD_COUNTDOWN", g_iCountdown)
		}
		case 3: // DHUD.
		{
			if (g_bCountdownRandomColors)
				set_dhudmessage(random(256), random(256), random(256), HUD_EVENT_X, HUD_EVENT_Y, 0, 1.0, 1.0, 0.0, 0.0)
			else
				set_dhudmessage(g_iCountdownColors[Red], g_iCountdownColors[Green], g_iCountdownColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 0, 1.0, 1.0, 0.0, 0.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_COUNTDOWN", g_iCountdown)
		}
	}
}

public choose_Gamemode()
{
	if (get_xvar_num(g_xRoundNum) == 1 && g_bFirstRound)
	{
		goto FIRST_ROUND
	}

	if (g_iNext != ZE_GAME_INVALID)
	{
		start_Gamemode(g_iNext, 0, true)
	}
	else
	{
		new iChance, i

		while (++iChance < MAX_ATTEMPT)
		{
			for (i = 0; i < g_iNumGames; i++)
			{
				if (start_Gamemode(i))
				{
					return // Game mode chosen.
				}
			}
		}

		FIRST_ROUND:

		if (g_iDefault != ZE_GAME_INVALID)
		{
			// Turn the default game mode.
			if (!start_Gamemode(g_iDefault, 0, true))
			{
				// Print message on server console.
				server_print("[ZE] Error starting default game mode !")

				// Send message in console to everyone.
				console_print(0, "[ZE] Error starting default game mode !")
			}
		}
		else
		{
			// Print message on server console.
			server_print("[ZE] Invalid default game mode !")

			// Send message in console to everyone.
			console_print(0, "[ZE] Invalid default game mode !")
		}
	}
}

public ze_roundend(iWinTeam)
{
	set_xvar_num(g_xGameChosen)

	// Remove countdown task.
	remove_task(TASK_COUNTDOWN)
}

/**
 * -=| Function |=-
 */
start_Gamemode(const game_id, target = 0, bool:bSkipCheck = false)
{
	new aArray[GAMEMODES]
	ArrayGetArray(g_aGamemodes, game_id, aArray)

	// Unpause plug-in first.
	unpause("c", aArray[GAME_FILE])

	// Call forward ze_gamemode_chosen_pre(param1, param2, param3) and get return value.
	ExecuteForward(g_iForwards[FORWARD_GAMEMODE_CHOSEN_PRE], g_iFwReturn, game_id, target, bSkipCheck)

	if (g_iFwReturn >= ZE_GAME_IGNORE)
	{
		// Re-pause plug-in again.
		pause("ac", aArray[GAME_FILE])
		return 0
	}

	// Call forward ze_gamemode_chosen(param1, param2)
	g_iCurrent = game_id
	set_xvar_num(g_xGameChosen, 1)
	ExecuteForward(g_iForwards[FORWARD_GAMEMODE_CHOSEN], _/* Ignore return value */, game_id, target)

	// Remove Countdown Task.
	remove_task(TASK_COUNTDOWN)
	return 1
}

/**
 * -=| Natives |=-
 */
public __native_gamemode_register(const plugin_id, const num_params)
{
	new szName[MAX_NAME_LENGTH]

	// Get gamemode name.
	get_string(1, szName, charsmax(szName))

	if (!strlen(szName))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register game mode without name.")
		return ZE_GAME_INVALID
	}

	new aArray[GAMEMODES]

	for (new i = 0; i < g_iNumGames; i++)
	{
		ArrayGetArray(g_aGamemodes, i, aArray)

		if (equal(szName, aArray[GAME_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Can't register game mode with existing name.")
			return ZE_GAME_INVALID
		}
	}

	new szFile[256]

	// Get plug-in name.
	get_plugin(plugin_id, szFile, charsmax(szFile))

	// Copy name and file name in Array.
	copy(aArray[GAME_NAME], charsmax(aArray) - GAME_NAME, szName)
	copy(aArray[GAME_FILE], charsmax(aArray) - GAME_FILE, szFile)

	// Copy Array on dynamic array.
	ArrayPushArray(g_aGamemodes, aArray)

	// Gamemode index.
	return ++g_iNumGames - 1
}

public __native_gamemode_set_default(const plugin_id, const num_params)
{
	new const game_id = get_param(1)

	if (FIsGameInvalid(game_id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid game mode id (%d)", game_id)
		return 0
	}

	g_iDefault = game_id
	return 1
}

public __native_gamemode_get_current(const plugin_id, const num_params)
{
	new const game_id = get_param(1)

	if (FIsGameInvalid(game_id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid game mode id (%d)", game_id)
		return ZE_GAME_INVALID
	}

	return g_iCurrent
}

public __native_gamemode_set_next(const plugin_id, const num_params)
{
	new const game_id = get_param(1)

	if (FIsGameInvalid(game_id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid game mode id (%d)", game_id)
		return 0
	}

	g_iNext = game_id
	return 1
}

public __native_gamemode_get_next(const plugin_id, const num_params)
{
	return g_iNext
}

public __native_gamemode_get_name(const plugin_id, const num_params)
{
	new const game_id = get_param(1)

	if (FIsGameInvalid(game_id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid game mode id (%d)", game_id)
		return 0
	}

	new aArray[GAMEMODES]
	ArrayGetArray(g_aGamemodes, game_id, aArray)
	return set_string(2, aArray[GAME_NAME], get_param(3))
}

public __native_gamemode_get_id(const plugin_id, const num_params)
{
	new szName[MAX_NAME_LENGTH]
	if (!get_string(1, szName, charsmax(szName)))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't find on game mode id without name.")
		return ZE_GAME_INVALID
	}

	for (new aArray[GAMEMODES], i = 0; i < g_iNumGames; i++)
	{
		ArrayGetArray(g_aGamemodes, i, aArray)
		if (equal(szName, aArray[GAME_NAME]))
		{
			return i
		}
	}

	return ZE_GAME_INVALID
}

public __native_gamemode_start(const plugin_id, const num_params)
{
	new const game_id = get_param(1)

	if (FIsGameInvalid(game_id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid game mode id (%d)", game_id)
		return 0
	}

	new const target = get_param(2)

	if (target != 0)
	{
		if (!is_user_connected(target))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", target)
			return 0
		}
	}

	start_Gamemode(game_id, target, true)
	return 1
}

public __native_gamemode_get_count(const plugin_id, const num_params)
{
	return g_iNumGames
}