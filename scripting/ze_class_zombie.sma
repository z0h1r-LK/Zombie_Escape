#include <amxmodx>
#include <reapi>
#include <ze_core>

// Define.
#define CUSTOM_MODEL
#define ZOMBIE_SOUNDS

// Color indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Cvars.
new g_iZombieHealth,
	g_iZombieGravity,
	g_iHudColor[Colors],
	Float:g_flZombieSpeed

#if defined CUSTOM_MODEL
// Default Zombie knife Models.
new g_szZombieKnifeModel[MAX_RESOURCE_PATH_LENGTH] = "models/ze_es/v_knife_zombie.mdl"

// Dynamic Array.
new Array:g_aZombieModels
#endif

#if defined ZOMBIE_SOUNDS
// Dynamic Array.
new Array:g_aPainSounds,
	Array:g_aMissSlashSounds,
	Array:g_aMissWallSounds,
	Array:g_aAttackSounds,
	Array:g_aDieSounds
#endif

public plugin_precache()
{
#if defined CUSTOM_MODEL
	// Default player Model.
	new const szDefZombieModels[][] = { "ze_zombi_1", "ze_zombi_2" }

	// Create new dynamic array.
	g_aZombieModels = ArrayCreate(MAX_NAME_LENGTH, 1)

	// Load player models from INI file.
	ini_read_string_array(ZE_FILENAME, "Player Models", "ZOMBIES", g_aZombieModels)

	// Array empty?
	if (!ArraySize(g_aZombieModels))
	{
		for (new i = 0; i < sizeof(szDefZombieModels); i++)
			ArrayPushString(g_aZombieModels, szDefZombieModels[i])

		// Save player Models from INI file.
		ini_write_string_array(ZE_FILENAME, "Player Models", "ZOMBIES", g_aZombieModels)
	}

	new szPlayerModel[MAX_NAME_LENGTH], szModel[MAX_RESOURCE_PATH_LENGTH], iNumModels

	// Get the number of Models on Array.
	iNumModels = ArraySize(g_aZombieModels)


	for (new i = 0; i < iNumModels; i++)
	{
		ArrayGetString(g_aZombieModels, i, szPlayerModel, charsmax(szPlayerModel))

		// Get full path.
		formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)

		// Precache Model.
		precache_model(szModel)
	}

	// Load Zombies Knife from INI file.
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "ZOMBIES_KNIFE", g_szZombieKnifeModel, charsmax(g_szZombieKnifeModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "ZOMBIES_KNIFE", g_szZombieKnifeModel)

	// Precache Model.
	precache_model(g_szZombieKnifeModel)
#endif

#if defined ZOMBIE_SOUNDS
	new const szPainSounds[][] = {"zm_es/zombie_pain_1.wav", "zm_es/zombie_pain_2.wav"}
	new const szMissSlashSounds[][] = {"zm_es/zombie_miss_slash_1.wav", "zm_es/zombie_miss_slash_2.wav", "zm_es/zombie_miss_slash_3.wav"}
	new const szMissWallSounds[][] = {"zm_es/zombie_miss_wall_1.wav", "zm_es/zombie_miss_wall_2.wav", "zm_es/zombie_miss_wall_3.wav"}
	new const szAttackSounds[][] = {"zm_es/zombie_attack_1.wav", "zm_es/zombie_attack_2.wav", "zm_es/zombie_attack_3.wav"}
	new const szDieSounds[][] = {"zm_es/zombie_death.wav", "zm_es/zombie_death_1.wav"}

	// Create new dyn Arrays.
	g_aPainSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aMissSlashSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aMissWallSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aAttackSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aDieSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Zombie sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "PAIN", g_aPainSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "MISS_SLASH", g_aMissSlashSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "MISS_WALL", g_aMissWallSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "ATTACK", g_aAttackSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "DIE", g_aDieSounds)

	if (!ArraySize(g_aPainSounds))
	{
		for (new i = 0; i < sizeof(szPainSounds); i++)
			ArrayPushString(g_aPainSounds, szPainSounds[i])

		// Write Pain sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "PAIN", g_aPainSounds)
	}

	if (!ArraySize(g_aMissSlashSounds))
	{
		for (new i = 0; i < sizeof(szMissSlashSounds); i++)
			ArrayPushString(g_aMissSlashSounds, szMissSlashSounds[i])

		// Write Miss Slash sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "MISS_SLASH", g_aMissSlashSounds)
	}

	if (!ArraySize(g_aMissWallSounds))
	{
		for (new i = 0; i < sizeof(szMissWallSounds); i++)
			ArrayPushString(g_aMissWallSounds, szMissWallSounds[i])

		// Write Miss Wall sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "MISS_WALL", g_aMissWallSounds)
	}

	if (!ArraySize(g_aAttackSounds))
	{
		for (new i = 0; i < sizeof(szAttackSounds); i++)
			ArrayPushString(g_aAttackSounds, szAttackSounds[i])

		// Write Attack sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "ATTACK", g_aAttackSounds)
	}

	if (!ArraySize(g_aDieSounds))
	{
		for (new i = 0; i < sizeof(szDieSounds); i++)
			ArrayPushString(g_aDieSounds, szDieSounds[i])

		// Write Die sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "DIE", g_aDieSounds)
	}

	new szSound[MAX_RESOURCE_PATH_LENGTH], iNumSounds

	// Precache Sounds.
	iNumSounds = ArraySize(g_aPainSounds)
	for (new i = 0; i < iNumSounds; i++)
	{
		ArrayGetString(g_aPainSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}

	iNumSounds = ArraySize(g_aMissSlashSounds)
	for (new i = 0; i < iNumSounds; i++)
	{
		ArrayGetString(g_aMissSlashSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}

	iNumSounds = ArraySize(g_aMissWallSounds)
	for (new i = 0; i < iNumSounds; i++)
	{
		ArrayGetString(g_aMissWallSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}

	iNumSounds = ArraySize(g_aAttackSounds)
	for (new i = 0; i < iNumSounds; i++)
	{
		ArrayGetString(g_aAttackSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}

	iNumSounds = ArraySize(g_aDieSounds)
	for (new i = 0; i < iNumSounds; i++)
	{
		ArrayGetString(g_aDieSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
#endif
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Zombie", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_zombie_health", "20000"), g_iZombieHealth)
	bind_pcvar_num(register_cvar("ze_zombie_gravity", "640"), g_iZombieGravity)
	bind_pcvar_float(register_cvar("ze_zombie_speed", "320.0"), g_flZombieSpeed)

	bind_pcvar_num(register_cvar("ze_hud_info_zombie_red", "255"), g_iHudColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_zombie_green", "127"), g_iHudColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_zombie_blue", "0"), g_iHudColor[Blue])
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aPainSounds)
	ArrayDestroy(g_aMissSlashSounds)
	ArrayDestroy(g_aMissWallSounds)
	ArrayDestroy(g_aAttackSounds)
	ArrayDestroy(g_aDieSounds)
	#if defined CUSTOM_MODEL
	ArrayDestroy(g_aZombieModels)
	#endif
}

public ze_user_infected(iVictim, iInfector)
{
	// Health.
	if (g_iZombieHealth > 0)
	{
		new Float:fHealth = float(g_iZombieHealth)
		set_entvar(iVictim, var_health, fHealth)
		set_entvar(iVictim, var_max_health, fHealth)
	}

	// Gravity.
	if (g_iZombieGravity > 0)
	{
		set_entvar(iVictim, var_gravity, float(g_iZombieGravity) / 800.0)
	}

	// Speed.
	if (g_flZombieSpeed > 0.0)
	{
		ze_set_user_speed(iVictim, g_flZombieSpeed)
	}

	// Info HUD.
	ze_hud_info_set(iVictim, "CLASS_ZOMBIE", g_iHudColor, true)

#if defined CUSTOM_MODEL
	new szModel[MAX_NAME_LENGTH]

	// Get random model name from dyn Array.
	ArrayGetString(g_aZombieModels, random_num(0, ArraySize(g_aZombieModels) - 1), szModel, charsmax(szModel))

	// Set player new Zombie Model.
	rg_set_user_model(iVictim, szModel, true)

	// Set player Knife Model.
	ze_set_user_view_model(iVictim, CSW_KNIFE, g_szZombieKnifeModel)
	ze_set_user_weap_model(iVictim, CSW_KNIFE, "")
#endif
}

#if defined ZOMBIE_SOUNDS
public ze_res_fw_zombie_sound(const id, iSnd, szSound[64])
{
	switch (iSnd)
	{
		case ZE_SND_PAIN: ArrayGetString(g_aPainSounds, random_num(0, ArraySize(g_aPainSounds) - 1), szSound, charsmax(szSound))
		case ZE_SND_SLASH: ArrayGetString(g_aMissSlashSounds, random_num(0, ArraySize(g_aMissSlashSounds) - 1), szSound, charsmax(szSound))
		case ZE_SND_WALL: ArrayGetString(g_aMissWallSounds, random_num(0, ArraySize(g_aMissWallSounds) - 1), szSound, charsmax(szSound))
		case ZE_SND_ATTACK: ArrayGetString(g_aAttackSounds, random_num(0, ArraySize(g_aAttackSounds) - 1), szSound, charsmax(szSound))
		case ZE_SND_DIE: ArrayGetString(g_aDieSounds, random_num(0, ArraySize(g_aDieSounds) - 1), szSound, charsmax(szSound))
	}
}
#endif