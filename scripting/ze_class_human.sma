#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>
#include <ini_file>
#include <ze_weap_models_api>

// Define.
#define CUSTOM_MODEL

// CVars.
new g_iHumanHealth,
	g_iHumanArmor,
	g_iHumanGravity,
	bool:g_bWeaponStrips,
	Float:g_flHumanSpeed,
	Float:g_flHumanSpeedFactor

#if defined CUSTOM_MODEL
	// Dynamic Array.
	new Array:g_aHumanModels

	public plugin_precache()
	{
		// Default player Model.
		new const szDefHumanModels[][] = { "terror", "sas" }

		// Create new dynamic array.
		g_aHumanModels = ArrayCreate(MAX_NAME_LENGTH, 1)

		// Load player models from INI file.
		ini_read_string_array(ZE_FILENAME, "Player Models", "HUMANS", g_aHumanModels)

		new iNum

		// Array empty?
		if (!ArraySize(g_aHumanModels))
		{
			for (iNum = 0; iNum < sizeof(szDefHumanModels); iNum++)
				ArrayPushString(g_aHumanModels, szDefHumanModels[iNum])

			// Save player Models from INI file.
			ini_write_string_array(ZE_FILENAME, "Player Models", "HUMANS", g_aHumanModels)
		}

		new szPlayerModel[MAX_NAME_LENGTH], szModel[MAX_RESOURCE_PATH_LENGTH], iModelsNum

		// Get the number of Models on Array.
		iModelsNum = ArraySize(g_aHumanModels)


		for (iNum = 0; iNum < iModelsNum; iNum++)
		{
			ArrayGetString(g_aHumanModels, iNum, szPlayerModel, charsmax(szPlayerModel))

			// Get full path.
			formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)

			// Precache Model.
			precache_model(szModel)
		}
	}
#endif

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Human", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_human_health", "250"), g_iHumanHealth)
	bind_pcvar_num(register_cvar("ze_human_armor", "0"), g_iHumanArmor)
	bind_pcvar_num(register_cvar("ze_human_gravity", "800"), g_iHumanGravity)

	bind_pcvar_num(register_cvar("ze_human_weapon_strip", "0"), g_bWeaponStrips)

	bind_pcvar_float(register_cvar("ze_human_speed", "0"), g_flHumanSpeed)
	bind_pcvar_float(register_cvar("ze_human_speed_factor", "25.0"), g_flHumanSpeedFactor)
}

public ze_user_humanized(id)
{
	// Health.
	if (g_iHumanHealth > 0)
	{
		new Float:fHealth = float(g_iHumanHealth)
		set_entvar(id, var_health, fHealth)
		set_entvar(id, var_max_health, fHealth)
	}

	// Armor.
	if (g_iHumanArmor > 0)
	{
		if (g_iHumanArmor > get_user_armor(id))
		{
			rg_set_user_armor(id, g_iHumanArmor, ARMOR_KEVLAR)
		}
	}

	// Max-Speed.
	if (g_flHumanSpeed > 0.0)
	{
		ze_set_user_speed(id, g_flHumanSpeed)
	}
	else if (g_flHumanSpeedFactor > 0.0)
	{
		ze_set_user_speed(id, g_flHumanSpeedFactor, true)
	}

	// Gravity.
	if (g_iHumanGravity > 0)
	{
		set_entvar(id, var_gravity, float(g_iHumanGravity) / 800.0)
	}

	if (g_bWeaponStrips)
	{
		// Strips all Weapons for player.
		rg_remove_all_items(id)

		// Give player Knife Weapon.
		rg_give_item(id, "weapon_knife", GT_APPEND)
	}

#if defined CUSTOM_MODEL
	new szModel[MAX_NAME_LENGTH]

	// Get random Models from Array.
	ArrayGetString(g_aHumanModels, random_num(0, ArraySize(g_aHumanModels) - 1), szModel, charsmax(szModel))

	// Set player Model.
	rg_set_user_model(id, szModel, true)

	// Remove player Zombie Knife.
	ze_remove_user_view_model(id, CSW_KNIFE)
	ze_remove_user_weap_model(id, CSW_KNIFE)
#endif
}