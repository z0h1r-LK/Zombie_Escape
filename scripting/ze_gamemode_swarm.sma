#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <ze_core>
#include <ze_gamemodes>

// Define.
#define GAMEMODE_NAME "Swarm"

// HUD Event Position.
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.4

const Float:HUD_TIMER_X = -1.0
const Float:HUD_TIMER_Y = 0.6

// Custom Forwards.
enum _:FORWARDS
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

// CVars.
new g_iChance,
	g_iMsgNotice,
	g_iMinPlayers,
	g_iNoticeMode,
	g_iReleaseTime,
	g_iReleaseTimeMode,
	g_iNoticeColors[Colors],
	g_iReleaseTimeColors[Colors],
	bool:g_bSounds,
	bool:g_bEnabled,
	bool:g_bFreezeMode,
	bool:g_bBackToSpawn,
	bool:g_bRespawnAsZombie,
	Float:g_flRatio,
	Float:g_flMultiDamage

// Variables.
new g_iAmbHandle,
	g_iCountdown,
	bool:g_bIsSwarm,
	bool:g_bReleaseTime,
	bool:g_bFreezeZombie

// Arrays.
new g_iForwards[FORWARDS]

// XVar.
new g_xFixSpawn,
	g_xRespawnAsZombie

// Dynamic Arrays.
new Array:g_aSounds

public plugin_precache()
{
	new const szSwarmModeSound[][] = {"zm_es/ze_swarm_1.wav"}

	// Create new dyn Array.
	g_aSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read game mode sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "SWARM_MODE", g_aSounds)

	new i

	if (!ArraySize(g_aSounds))
	{
		for (i = 0; i < sizeof(szSwarmModeSound); i++)
			ArrayPushString(g_aSounds, szSwarmModeSound[i])

		// Write game mode sounds from INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "SWARM_MODE", g_aSounds)
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

	new const szAmbienceSound[] = "zm_es/ze_amb_swarm.mp3"
	const iAmbienceLength = 150

	// Registers new Ambience sound.
	g_iAmbHandle = ze_res_ambience_register(GAMEMODE_NAME, szAmbienceSound, iAmbienceLength)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Gamemode: Swarm", ZE_VERSION, ZE_AUTHORS)

	// Hook Chain.
	RegisterHookChain(RG_PM_Move, "fw_PM_Movement", 0)
	RegisterHookChain(RG_PM_AirMove, "fw_PM_Movement", 0)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "fw_TraceAttack_Pre", 0)

	// CVars.
	bind_pcvar_num(register_cvar("ze_swarm_enable", "1"), g_bEnabled)
	bind_pcvar_num(register_cvar("ze_swarm_mode", "1"), g_bFreezeMode)
	bind_pcvar_num(register_cvar("ze_swarm_chance", "20"), g_iChance)
	bind_pcvar_num(register_cvar("ze_swarm_minplayers", "4"), g_iMinPlayers)
	bind_pcvar_num(register_cvar("ze_swarm_notice", "3"), g_iNoticeMode)
	bind_pcvar_num(register_cvar("ze_swarm_notice_red", "0"), g_iNoticeColors[Red])
	bind_pcvar_num(register_cvar("ze_swarm_notice_green", "255"), g_iNoticeColors[Green])
	bind_pcvar_num(register_cvar("ze_swarm_notice_blue", "0"), g_iNoticeColors[Blue])
	bind_pcvar_num(register_cvar("ze_swarm_sound", "1"), g_bSounds)
	bind_pcvar_num(register_cvar("ze_swarm_spawn", "1"), g_bBackToSpawn)
	bind_pcvar_float(register_cvar("ze_swarm_damage", "2.0"), g_flMultiDamage)

	bind_pcvar_float(register_cvar("ze_swarm_ratio", "0.25"), g_flRatio)

	bind_pcvar_num(register_cvar("ze_release_time", "3"), g_iReleaseTime)
	bind_pcvar_num(register_cvar("ze_respawn_as_zombie", "1"), g_bRespawnAsZombie)

	bind_pcvar_num(register_cvar("ze_releasetime_mode", "1"), g_iReleaseTimeMode)
	bind_pcvar_num(register_cvar("ze_releasetime_red", "200"), g_iReleaseTimeColors[Red])
	bind_pcvar_num(register_cvar("ze_releasetime_green", "100"), g_iReleaseTimeColors[Green])
	bind_pcvar_num(register_cvar("ze_releasetime_blue", "50"), g_iReleaseTimeColors[Blue])

	// New Mode (Set Escape default mode).
	ze_gamemode_register(GAMEMODE_NAME)

	// Create Forwards.
	g_iForwards[FORWARD_ZOMBIE_APPEAR] = CreateMultiForward("ze_zombie_appear", ET_IGNORE, FP_ARRAY, FP_CELL)
	g_iForwards[FORWARD_ZOMBIE_RELEASE] = CreateMultiForward("ze_zombie_release", ET_IGNORE)

	// XVars.
	g_xFixSpawn = get_xvar_id("x_bFixSpawn")
	g_xRespawnAsZombie = get_xvar_id("x_bRespawnAsZombie")

	// Set Values.
	g_iMsgNotice = CreateHudSyncObj()
}

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

public fw_PM_Movement(id)
{
	if (g_bFreezeZombie)
	{
		// Player is Zombie?
		if (!ze_is_user_zombie(id))
			return HC_CONTINUE

		// Freeze the player.
		set_pmove(pm_maxspeed, 1.00)
	}

	return HC_CONTINUE
}

public fw_TraceAttack_Pre(const iVictim, iAttacker, Float:flDamage, Float:vDirection[3], pTrace, bitsDamageType)
{
	if (!g_bFreezeZombie)
		return HC_CONTINUE

	// Zombie?
	if (!ze_is_user_zombie(iVictim))
		return HC_CONTINUE

	// Prevent Trace Attack.
	return HC_SUPERCEDE
}

public fw_TakeDamage_Pre(const iVictim, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	if (!g_bIsSwarm)
		return HC_CONTINUE

	if (iVictim == iAttacker || !is_user_connected(iAttacker))
		return HC_CONTINUE

	// Attacker is Zombie?
	if (!ze_is_user_zombie(iAttacker))
		return HC_CONTINUE

	// Multiple Damage.
	SetHookChainArg(4, ATYPE_FLOAT, flDamage * g_flMultiDamage)
	return HC_CONTINUE
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	// Server?
	if (!iInfector)
		return ZE_CONTINUE

	if (g_bReleaseTime)
		return ZE_BREAK // Prevent infection and damage.

	if (g_bIsSwarm)
		return ZE_STOP // Prevent infection event, Keep taken damage.

	return ZE_CONTINUE
}

public ze_game_started_pre()
{
	g_bIsSwarm = false
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

		if (get_playersnum_ex(GetPlayers_ExcludeDead) < g_iMinPlayers)
			return ZE_GAME_IGNORE
	}

	// Continue starting the game mode.
	return ZE_GAME_CONTINUE
}

public ze_gamemode_chosen(game_id, target)
{
	new iPlayers[MAX_PLAYERS], iZombies[MAX_PLAYERS], iReqZombie, iNumZombie, iAliveNum, id

	// Get index of all Alive Players.
	get_players(iPlayers, iAliveNum, "a")

	// Fix call the Spawn function when respawn player.
	set_xvar_num(g_xFixSpawn, 1)

	// Get required Zombies.
	if ((iReqZombie = floatround(get_playersnum_ex(GetPlayers_ExcludeDead) * g_flRatio, floatround_ceil)) <= 0)
		iReqZombie = 1

	// Block infection.
	g_bIsSwarm = true

	while (iNumZombie < iReqZombie)
	{
		// Get randomly player.
		id = iPlayers[random_num(0, iAliveNum - 1)]

		// Player already Zombie!
		if (ze_is_user_zombie(id))
			continue

		if (g_bBackToSpawn)
		{
			// Respawn the player.
			rg_round_respawn(id)
		}

		// Infect player.
		ze_set_user_zombie(id)

		// New Zombie.
		iZombies[iNumZombie++] = id
	}

	// Disable it.
	set_xvar_num(g_xFixSpawn)

	if (g_bFreezeMode)
	{
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

	// Release time
	g_bReleaseTime = true

	if (g_iReleaseTime <= 1)
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
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_SWARM")
		}
		case 2: // HUD.
		{
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 1, 3.0, 3.0, 0.1, 1.0)
			show_hudmessage(0, "%L", LANG_PLAYER, "HUD_SWARM")
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 1, 3.0, 3.0, 0.1, 1.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_SWARM")
		}
	}

	// Plays ambience sound for everyone.
	ze_res_ambience_play(g_iAmbHandle)
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
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_TIMER_X, HUD_TIMER_Y, 1, 0.0, 1.0, 0.0, 0.0, 4)
			ShowSyncHudMsg(0, g_iMsgNotice, "%L", LANG_PLAYER, "HUD_RELEASETIME", g_iCountdown)
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_TIMER_X, HUD_TIMER_Y, 1, 0.0, 1.0, 0.0, 0.0)
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
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_TIMER_X, HUD_TIMER_Y, 1, 0.0, 1.0, 0.0, 0.0, 4)
			ShowSyncHudMsg(0, g_iMsgNotice, "%L", LANG_PLAYER, "HUD_RELEASED")
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_TIMER_X, HUD_TIMER_Y, 1, 0.0, 1.0, 0.0, 0.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_RELEASED")
		}
	}

	// Call forward ze_zombie_release().
	ExecuteForward(g_iForwards[FORWARD_ZOMBIE_RELEASE])

	// Release Zombie.
	g_bReleaseTime = false
	g_bFreezeZombie = false
}

public ze_roundend(iWinTeam)
{
	g_bIsSwarm = false

	// Remove task.
	remove_task(TASK_RELEASEDHUD)
	remove_task(TASK_RELEASETIME)

	// Disable XVar.
	set_xvar_num(g_xRespawnAsZombie)
}