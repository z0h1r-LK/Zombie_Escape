#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ini_file>
#include <ze_weap_models_api>

// Define.
#define CUSTOM_MODEL

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
	new g_szZombieKnifeModel[MAX_RESOURCE_PATH_LENGTH] = "models/ze/v_knife_zombie.mdl"

	// Dynamic Array.
	new Array:g_aZombieModels

	public plugin_precache()
	{
		// Default player Model.
		new const szDefZombieModels[][] = { "ze_zombi_1", "ze_zombi_2" }

		// Create new dynamic array.
		g_aZombieModels = ArrayCreate(MAX_NAME_LENGTH, 1)

		// Load player models from INI file.
		ini_read_string_array(ZE_FILENAME, "Player Models", "ZOMBIES", g_aZombieModels)

		new iNum

		// Array empty?
		if (!ArraySize(g_aZombieModels))
		{
			for (iNum = 0; iNum < sizeof(szDefZombieModels); iNum++)
				ArrayPushString(g_aZombieModels, szDefZombieModels[iNum])

			// Save player Models from INI file.
			ini_write_string_array(ZE_FILENAME, "Player Models", "ZOMBIES", g_aZombieModels)
		}

		new szPlayerModel[MAX_NAME_LENGTH], szModel[MAX_RESOURCE_PATH_LENGTH], iNumModels

		// Get the number of Models on Array.
		iNumModels = ArraySize(g_aZombieModels)


		for (iNum = 0; iNum < iNumModels; iNum++)
		{
			ArrayGetString(g_aZombieModels, iNum, szPlayerModel, charsmax(szPlayerModel))

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
	}
#endif

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