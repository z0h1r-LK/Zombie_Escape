#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>
#include <ze_gamemodes>

// Libraryies.
stock const LIBRARY_RESOURCES[] = "ze_resources"

// Define.
#define GAMEMODE_NAME "Escape"
//#define SMARTRANDOM_OLD_METHOD

// Custom Forwards.
enum any:FORWARDS
{
	FORWARD_ZOMBIE_APPEAR = 0,
	FORWARD_ZOMBIE_RELEASE
}

// Task IDs.
enum (+=100)
{
	TASK_RELEASETIME = 100,
	TASK_RELEASEDHUD
}

// Colors
enum any:Colors
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
	HUD_EVENT[Positions] = 0,
	HUD_TIMER[Positions]
}

// CVars.
new g_iChance,
	g_iMsgNotice,
	g_iNoticeMode,
	g_iReleaseTime,
	g_iReleaseTimeMode,
	g_iFirstZombiesHealth,
	g_iNoticeColors[Colors],
	g_iReleaseTimeColors[Colors],
	bool:g_bSounds,
	bool:g_bEnabled,
	bool:g_bFreezeMode,
	bool:g_bBackToSpawn,
	bool:g_bSmartRandom,
	bool:g_bRespawnAsZombie

// Variables.
new g_iCountdown,
	bool:g_bReleaseTime,
	bool:g_bFreezeZombie

// XVar.
new g_xFixSpawn,
	g_xRespawnAsZombie

// Array.
new g_iForwards[FORWARDS],
	Float:g_flHUDPosit[HUDs]

// String.
#if !defined SMARTRANDOM_OLD_METHOD
new g_szAuthID[MAX_PLAYERS+1][MAX_AUTHID_LENGTH]
#endif

// Trie's.
new Trie:g_tChosen

// Dynamic Arrays.
new Array:g_aSounds

// Hook Handle.
new HookChain:g_hPMHook,
	HookChain:g_hPMAirHook,
	HookChain:g_hTraceAttack

public plugin_natives()
{
	register_library("ze_gescape_mode")
	register_native("ze_is_zombie_frozen", "__native_is_zombie_frozen")

	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_RESOURCES))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	new const szEscapeModeSound[][] = {"zm_es/ze_escape_1.wav"}

	// Create new dyn Array.
	g_aSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read game mode sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "ESCAPE_MODE", g_aSounds)

	new i

	if (!ArraySize(g_aSounds))
	{
		for (i = 0; i < sizeof(szEscapeModeSound); i++)
			ArrayPushString(g_aSounds, szEscapeModeSound[i])

		// Write game mode sounds from INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "ESCAPE_MODE", g_aSounds)
	}

	new szSound[MAX_RESOURCE_PATH_LENGTH]

	// Precache Sounds
	new iFiles = ArraySize(g_aSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aSounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}

	if (LibraryExists(LIBRARY_RESOURCES, LibType_Library))
	{
		new const szEscapeAmbienceSound[] = "zm_es/ze_amb_escape.mp3"
		const iEscapeAmbienceLength = 150

		// Registers new Ambience sound.
		ze_res_ambx_register(GAMEMODE_NAME, szEscapeAmbienceSound, iEscapeAmbienceLength)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Gamemode: Escape", ZE_VERSION, ZE_AUTHORS)

	// Hook Chain.
	g_hPMHook = RegisterHookChain(RG_PM_Move, "fw_PM_Movement")
	g_hPMAirHook = RegisterHookChain(RG_PM_AirMove, "fw_PM_Movement")
	g_hTraceAttack = RegisterHookChain(RG_CBasePlayer_TraceAttack, "fw_TraceAttack_Pre")
	rp_hook_status()

	// CVars.
	bind_pcvar_num(register_cvar("ze_escape_enable", "1"), g_bEnabled)
	bind_pcvar_num(register_cvar("ze_escape_mode", "1"), g_bFreezeMode)
	bind_pcvar_num(register_cvar("ze_escape_chance", "20"), g_iChance)
	bind_pcvar_num(register_cvar("ze_escape_notice", "3"), g_iNoticeMode)
	bind_pcvar_num(register_cvar("ze_escape_notice_red", "200"), g_iNoticeColors[Red])
	bind_pcvar_num(register_cvar("ze_escape_notice_green", "100"), g_iNoticeColors[Green])
	bind_pcvar_num(register_cvar("ze_escape_notice_blue", "0"), g_iNoticeColors[Blue])
	bind_pcvar_num(register_cvar("ze_escape_sound", "1"), g_bSounds)
	bind_pcvar_num(register_cvar("ze_escape_spawn", "1"), g_bBackToSpawn)

	bind_pcvar_num(register_cvar("ze_release_time", "3"), g_iReleaseTime)
	bind_pcvar_num(register_cvar("ze_smart_random", "1"), g_bSmartRandom)
	bind_pcvar_num(register_cvar("ze_respawn_as_zombie", "1"), g_bRespawnAsZombie)
	bind_pcvar_num(register_cvar("ze_first_zombies_health", "15000"), g_iFirstZombiesHealth)

	bind_pcvar_num(register_cvar("ze_releasetime_mode", "1"), g_iReleaseTimeMode)
	bind_pcvar_num(register_cvar("ze_releasetime_red", "200"), g_iReleaseTimeColors[Red])
	bind_pcvar_num(register_cvar("ze_releasetime_green", "100"), g_iReleaseTimeColors[Green])
	bind_pcvar_num(register_cvar("ze_releasetime_blue", "50"), g_iReleaseTimeColors[Blue])

	// New Mode (Set Escape default mode).
	ze_gamemode_set_default(ze_gamemode_register(GAMEMODE_NAME))

	// Create Forwards.
	g_iForwards[FORWARD_ZOMBIE_APPEAR] = CreateMultiForward("ze_zombie_appear", ET_IGNORE, FP_ARRAY, FP_CELL)
	g_iForwards[FORWARD_ZOMBIE_RELEASE] = CreateMultiForward("ze_zombie_release", ET_IGNORE)

	// XVars.
	g_xFixSpawn = get_xvar_id("x_bFixSpawn")
	g_xRespawnAsZombie = get_xvar_id("x_bRespawnAsZombie")

	// Set Values.
	g_iMsgNotice = CreateHudSyncObj()
}

public plugin_cfg()
{
	g_flHUDPosit[HUD_EVENT][POSIT_X] = -1.0
	g_flHUDPosit[HUD_EVENT][POSIT_Y] = 0.4
	g_flHUDPosit[HUD_TIMER][POSIT_X] = -1.0
	g_flHUDPosit[HUD_TIMER][POSIT_Y] = 0.6

	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_GAMEEVENT_X", g_flHUDPosit[HUD_EVENT][POSIT_X]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_GAMEEVENT_X", g_flHUDPosit[HUD_EVENT][POSIT_X])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_GAMEEVENT_Y", g_flHUDPosit[HUD_EVENT][POSIT_Y]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_GAMEEVENT_Y", g_flHUDPosit[HUD_EVENT][POSIT_Y])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_RELEASETIME_X", g_flHUDPosit[HUD_TIMER][POSIT_X]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_RELEASETIME_X", g_flHUDPosit[HUD_TIMER][POSIT_X])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_RELEASETIME_Y", g_flHUDPosit[HUD_TIMER][POSIT_Y]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_RELEASETIME_Y", g_flHUDPosit[HUD_TIMER][POSIT_Y])

	// Create new Hash Map.
	g_tChosen = TrieCreate()
}

public plugin_end()
{
	// Free the Memory.
	TrieDestroy(g_tChosen)
}

#if !defined SMARTRANDOM_OLD_METHOD
public ze_user_authorized(id, const szAuthID[], RClientAuth:iClType, bool:bUnauthorized, Float:flAuthTime)
{
	if (iClType == ZE_AUTH_PROXY)
		return

	copy(g_szAuthID[id], charsmax(g_szAuthID[]), szAuthID)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id))
		return

	// Clear string.
	g_szAuthID[id] = NULL_STRING
}
#endif

public ze_frost_freeze_start(id)
{
	if (g_bReleaseTime && g_bFreezeZombie)
		return ZE_STOP
	return ZE_CONTINUE
}

public ze_fire_burn_start(id)
{
	if (g_bReleaseTime && g_bFreezeZombie)
		return ZE_STOP
	return ZE_CONTINUE
}

public fw_PM_Movement(const id)
{
	// Player is Zombie?
	if (!ze_is_user_zombie(id))
		return

	// Freeze the player.
	set_pmove(pm_maxspeed, 1.00)
}

public fw_TraceAttack_Pre(const iVictim, iAttacker, Float:flDamage, Float:vDirection[3], pTrace, bitsDamageType)
{
	// Zombie?
	if (!ze_is_user_zombie(iVictim))
		return HC_CONTINUE

	// Prevent Trace Attack.
	return HC_SUPERCEDE
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	// Server?
	if (!iInfector)
		return ZE_CONTINUE

	if (g_bReleaseTime)
		return ZE_BREAK

	return ZE_CONTINUE
}

public ze_game_started_pre()
{
	rp_hook_status()
	g_bReleaseTime = false
	g_bFreezeZombie = false

	// Remove task.
	remove_task(TASK_RELEASETIME)
	remove_task(TASK_RELEASEDHUD)

	// Disable xvar.
	set_xvar_num(g_xRespawnAsZombie)
}

public ze_gamemode_chosen_pre(game_id, target, bool:bSkipCheck)
{
	if (!g_bEnabled)
		return ZE_GAME_IGNORE

	if (!bSkipCheck)
	{
		// This is not round of this game mode.
		if (random_num(1, g_iChance) != 1)
			return ZE_GAME_IGNORE
	}

	// Continue starting the game mode.
	return ZE_GAME_CONTINUE
}

public ze_gamemode_chosen(game_id, target)
{
	new iPlayers[MAX_PLAYERS], iZombies[MAX_PLAYERS], iReqZombie, iNumZombie, iAliveNum, id

#if defined SMARTRANDOM_OLD_METHOD
	new szAuthID[MAX_AUTHID_LENGTH]
#endif

	if (!target)
	{
		// Get index of all Alive Players.
		get_players(iPlayers, iAliveNum, "a")

		// Fix call the Spawn function when respawn player.
		set_xvar_num(g_xFixSpawn, 1)

		// Get required Zombies.
		iReqZombie = GetRequiredZombies(iAliveNum)

		while (iNumZombie < iReqZombie)
		{
			// Get randomly player.
			id = iPlayers[random_num(0, iAliveNum - 1)]

			// Player already Zombie!
			if (ze_is_user_zombie(id))
				continue

			// Player was Zombie in previous Rounds?
#if defined SMARTRANDOM_OLD_METHOD
			if (g_bSmartRandom && get_user_authid(id, szAuthID, charsmax(szAuthID)) && TrieKeyExists(g_tChosen, szAuthID))
				continue
#endif

#if !defined SMARTRANDOM_OLD_METHOD
			if (g_bSmartRandom && g_szAuthID[id][0] && TrieKeyExists(g_tChosen, g_szAuthID[id]))
				continue
#endif

			if (g_bBackToSpawn)
			{
				// Respawn the player.
				rg_round_respawn(id)
			}

			// Infect player.
			ze_set_user_zombie(id)

			// Custom Health for first Zombies.
			if (g_iFirstZombiesHealth > 0)
			{
				set_entvar(id, var_health, float(g_iFirstZombiesHealth))
			}

			// New Zombie.
			iZombies[iNumZombie++] = id
		}

		// Disable it.
		set_xvar_num(g_xFixSpawn)
	}
	else
	{
		iZombies[iNumZombie++] = target

		// Infect player.
		ze_set_user_zombie(target)
	}

	if (g_bFreezeMode)
	{
		rp_hook_status(true)
		g_bFreezeZombie = true
	}

	if (g_bRespawnAsZombie)
	{
		set_xvar_num(g_xRespawnAsZombie, 1)
	}

	if (iNumZombie > 0)
	{
		// Call forward ze_zombie_appear(array[], param2)
		ExecuteForward(g_iForwards[FORWARD_ZOMBIE_APPEAR], _/* Ignore return value */, PrepareArray(iZombies, MAX_PLAYERS), iNumZombie)
	}

	if (g_bSmartRandom)
	{
		// Clear Trie first.
		TrieClear(g_tChosen)

		// Remember infected players.
		for (new i = 0; i < iNumZombie; i++)
		{
			id = iZombies[i]

			// Store AuthID of the player in Trie.
#if defined SMARTRANDOM_OLD_METHOD
			if (get_user_authid(id, szAuthID, charsmax(szAuthID)))
				TrieSetCell(g_tChosen, szAuthID, 0)
#endif

#if !defined SMARTRANDOM_OLD_METHOD
			if (g_szAuthID[id][0])
				TrieSetCell(g_tChosen, g_szAuthID[id], 0)
#endif
		}
	}

	// Release time
	g_bReleaseTime = true

	if (g_iReleaseTime < 1)
	{
		release_Zombies()
	}
	else
	{
		g_iCountdown = g_iReleaseTime

		// Task for release time.
		set_task(1.0, "show_ReleaseTime", TASK_RELEASETIME, .flags = "b")
	}

	if (g_bSounds)
	{
		// Play sound for everyone.
		new szSound[MAX_RESOURCE_PATH_LENGTH]
		ArrayGetString(g_aSounds, random_num(0, ArraySize(g_aSounds) - 1), szSound, charsmax(szSound))
		PlaySound(0, szSound)
	}

	switch (g_iNoticeMode)
	{
		case 1: // Text Center.
		{
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_ESCAPE")
		}
		case 2: // HUD.
		{
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_EVENT][POSIT_X], g_flHUDPosit[HUD_EVENT][POSIT_Y], 1, 3.0, 3.0, 0.1, 1.0)
			show_hudmessage(0, "%L", LANG_PLAYER, "HUD_ESCAPE")
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_EVENT][POSIT_X], g_flHUDPosit[HUD_EVENT][POSIT_Y], 1, 3.0, 3.0, 0.1, 1.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_ESCAPE")
		}
	}

	if (LibraryExists(LIBRARY_RESOURCES, LibType_Library))
	{
		// Plays ambience sound for everyone.
		ze_res_ambx_play(GAMEMODE_NAME)
	}
}

public show_ReleaseTime(taskid)
{
	switch (g_iReleaseTimeMode)
	{
		case 1: // Center Text.
		{
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_RELEASETIME", g_iCountdown)
		}
		case 2: // HUD.
		{
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_TIMER][POSIT_X], g_flHUDPosit[HUD_TIMER][POSIT_Y], 1, 0.0, 1.0, 0.0, 0.0, 4)
			ShowSyncHudMsg(0, g_iMsgNotice, "%L", LANG_PLAYER, "HUD_RELEASETIME", g_iCountdown)
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_TIMER][POSIT_X], g_flHUDPosit[HUD_TIMER][POSIT_Y], 1, 0.0, 1.0, 0.0, 0.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_RELEASETIME", g_iCountdown)
		}
	}

	if (g_iCountdown <= 1)
	{
		set_task(1.0, "release_Zombies", TASK_RELEASEDHUD)

		// Remove task.
		remove_task(taskid)
	}
	else
	{
		g_iCountdown--
	}
}

public release_Zombies()
{
	switch (g_iReleaseTimeMode)
	{
		case 1: // Center Text.
		{
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_RELEASED")
		}
		case 2: // HUD.
		{
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_TIMER][POSIT_X], g_flHUDPosit[HUD_TIMER][POSIT_Y], 1, 0.0, 1.0, 0.0, 0.0, 4)
			ShowSyncHudMsg(0, g_iMsgNotice, "%L", LANG_PLAYER, "HUD_RELEASED")
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHUDPosit[HUD_TIMER][POSIT_X], g_flHUDPosit[HUD_TIMER][POSIT_Y], 1, 0.0, 1.0, 0.0, 0.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_RELEASED")
		}
	}

	// Call forward ze_zombie_release().
	ExecuteForward(g_iForwards[FORWARD_ZOMBIE_RELEASE])

	// Release Zombie.
	rp_hook_status()
	g_bReleaseTime = false
	g_bFreezeZombie = false
}

public ze_roundend(iWinTeam)
{
	rp_hook_status()

	// Remove task.
	remove_task(TASK_RELEASEDHUD)
	remove_task(TASK_RELEASETIME)

	// Disable XVar.
	set_xvar_num(g_xRespawnAsZombie)
}

/**
 * -=| Function |=-
 */
rp_hook_status(const bool:status = false)
{
	if (status)
	{
		EnableHookChain(g_hPMHook)
		EnableHookChain(g_hPMAirHook)
		EnableHookChain(g_hTraceAttack)
	}
	else
	{
		DisableHookChain(g_hPMHook)
		DisableHookChain(g_hPMAirHook)
		DisableHookChain(g_hTraceAttack)
	}
}

/**
 * -=| Natives |=-
 */
public __native_is_zombie_frozen(const plugin_id, const num_params)
{
	return g_bFreezeZombie
}