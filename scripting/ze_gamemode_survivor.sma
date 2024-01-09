#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ze_class_survivor>
#define LIBRARY_SURVIVOR "ze_class_survivor"
#define LIBRARY_RESOURCES "ze_resources"

// Defines.
#define GAMEMODE_NAME "Survivor"

#define X_Wpn_WeaponsDisabled "x_bWeaponsDisabled"

// HUD Event Position.
const Float:HUD_EVENT_X = -1.0
const Float:HUD_EVENT_Y = 0.4

// Colors
enum any:Colors
{
	Red = 0,
	Green,
	Blue
}

// CVars.
new g_iChance,
	g_iNoticeMode,
	g_iMinPlayers,
	g_iNoticeColors[Colors],
	bool:g_bSounds,
	bool:g_bEnabled,
	bool:g_bBackToSpawn

// Variables.
new g_iAmbHandle

// XVar.
new g_xFixSpawn,
	g_xWeaponsDisabled

// Dynamic Array.
new Array:g_aSounds

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_RESOURCES))
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
	new const szSurvivorModeSound[][] = {"zm_es/ze_survivor_1.wav"}

	// Create new dyn Array.
	g_aSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read spread sound from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "SURVIVOR_MODE", g_aSounds)

	if (!ArraySize(g_aSounds))
	{
		for (new i = 0; i < sizeof(szSurvivorModeSound); i++)
			ArrayPushString(g_aSounds, szSurvivorModeSound[i])

		// Write spread sound from INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "SURVIVOR_MODE", g_aSounds)
	}

	new szSound[MAX_RESOURCE_PATH_LENGTH]

	// Precache Sounds.
	new iFiles = ArraySize(g_aSounds)
	for (new i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aSounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}


	if (module_exists(LIBRARY_RESOURCES))
	{
		new const szSurvivorAmbienceSound[] = "zm_es/ze_amb_survivor.wav"
		const iSurvivorAmbienceSound = 200

		// Registers new Ambience on game.
		g_iAmbHandle = ze_res_ambience_register(GAMEMODE_NAME, szSurvivorAmbienceSound, iSurvivorAmbienceSound)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Gamemodes: Survivor", ZE_VERSION, ZE_AUTHORS)

	// CVars.
	bind_pcvar_num(register_cvar("ze_survivor_enable", "1"), g_bEnabled)
	bind_pcvar_num(register_cvar("ze_survivor_chance", "20"), g_iChance)
	bind_pcvar_num(register_cvar("ze_survivor_minplayers", "4"), g_iMinPlayers)
	bind_pcvar_num(register_cvar("ze_survivor_notice", "3"), g_iNoticeMode)
	bind_pcvar_num(register_cvar("ze_survivor_notice_red", "0"), g_iNoticeColors[Red])
	bind_pcvar_num(register_cvar("ze_survivor_notice_green", "55"), g_iNoticeColors[Green])
	bind_pcvar_num(register_cvar("ze_survivor_notice_blue", "255"), g_iNoticeColors[Blue])
	bind_pcvar_num(register_cvar("ze_survivor_sound", "1"), g_bSounds)
	bind_pcvar_num(register_cvar("ze_survivor_spawn", "1"), g_bBackToSpawn)

	// New's Mode.
	ze_gamemode_register(GAMEMODE_NAME)

	// Set Values.
	g_xFixSpawn = get_xvar_id(X_Core_FixSpawn)
	g_xWeaponsDisabled = get_xvar_id(X_Wpn_WeaponsDisabled)
}

public ze_gamemode_chosen_pre(game_id, target, bool:bSkipCheck)
{
	if (!g_bEnabled)
		return ZE_GAME_IGNORE

	if (!bSkipCheck)
	{
		// ze_class_survivor not Loaded!
		if (!module_exists(LIBRARY_SURVIVOR))
			return ZE_GAME_IGNORE

		// This is not round of Nemesis?
		if (random_num(1, g_iChance) != 1)
			return ZE_GAME_IGNORE

		if (get_playersnum_ex(GetPlayers_ExcludeDead) < g_iMinPlayers)
			return ZE_GAME_IGNORE
	}

	// Continue starting game mode: Nemesis
	return ZE_GAME_CONTINUE
}

public ze_gamemode_chosen(game_id, target)
{
	new iPlayers[MAX_PLAYERS], iAliveNum

	// Get index of all Alive Players.
	get_players(iPlayers, iAliveNum, "a")

	// Fix call the Spawn function when respawn player.
	set_xvar_num(g_xFixSpawn, 1)

	if (!target)
	{
		target = iPlayers[random_num(0, iAliveNum - 1)]
	}

	// Turn a player to Survivor.
	ze_set_user_survivor(target)

	for (new id, i = 0; i < iAliveNum; i++)
	{
		id = iPlayers[i]

		// Survivor?
		if (id == target)
			continue

		if (g_bBackToSpawn)
		{
			// Back player to Spawn Point.
			rg_round_respawn(id)
		}

		// Turn a player to Zombie?
		ze_set_user_zombie(id)
	}

	// Disable it.
	set_xvar_num(g_xFixSpawn)

	// Disable Weapons Menu for everyone.
	set_xvar_num(g_xWeaponsDisabled, 1)

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
			client_print(0, print_center, "%L", LANG_PLAYER, "HUD_SURVIVOR")
		}
		case 2: // HUD.
		{
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 1, 3.0, 3.0, 0.1, 1.0)
			show_hudmessage(0, "%L", LANG_PLAYER, "HUD_SURVIVOR")
		}
		case 3: // DHUD.
		{
			set_dhudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_EVENT_X, HUD_EVENT_Y, 1, 3.0, 3.0, 0.1, 1.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "HUD_SURVIVOR")
		}
	}

	if (module_exists(LIBRARY_RESOURCES))
	{
		// Plays ambience sound for everyone.
		ze_res_ambience_play(g_iAmbHandle)
	}
}

public ze_roundend(iWinTeam)
{
	set_xvar_num(g_xWeaponsDisabled, 0)
}