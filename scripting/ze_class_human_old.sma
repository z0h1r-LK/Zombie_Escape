#include <amxmodx>
#include <reapi>
#include <ze_core>
#define LIBRARY_HUDINFO "ze_hud_info"
#define LIBRARY_WPNMODELS "ze_weap_models_api"

// Define.
#define CUSTOM_MODEL

// Color indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Shield Attack Sound.
new g_szShieldAttackSound[MAX_RESOURCE_PATH_LENGTH] = "player/bhit_helmet-1.wav"

// CVars.
new g_iHumanHealth,
	g_iHumanArmor,
	g_iHumanGravity,
	g_iHudColor[Colors],
	bool:g_bHumanShield,
	bool:g_bWeaponStrips,
	Float:g_flHumanSpeed,
	Float:g_flHumanSpeedFactor

// Variable.
new g_msgWeapPickup

public plugin_natives()
{
	set_module_filter("fw_module_filter")
	set_native_filter("fw_native_filter")
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_WPNMODELS) || equal(module, LIBRARY_HUDINFO))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

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

		// Read attack shield sound from INI file.
		if (!ini_read_string(ZE_FILENAME, "Sounds", "SHIELD_ATTACK", g_szShieldAttackSound, charsmax(g_szShieldAttackSound)))
			ini_write_string(ZE_FILENAME, "Sounds", "SHIELD_ATTACK", g_szShieldAttackSound)

		// Precache Sound.
		precache_sound(g_szShieldAttackSound)
	}
#endif

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Human (OLD)", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_human_health", "250"), g_iHumanHealth)
	bind_pcvar_num(register_cvar("ze_human_armor", "0"), g_iHumanArmor)
	bind_pcvar_num(register_cvar("ze_human_gravity", "800"), g_iHumanGravity)

	bind_pcvar_num(register_cvar("ze_human_weapon_strip", "0"), g_bWeaponStrips)

	bind_pcvar_float(register_cvar("ze_human_speed", "0"), g_flHumanSpeed)
	bind_pcvar_float(register_cvar("ze_human_speed_factor", "25.0"), g_flHumanSpeedFactor)

	bind_pcvar_num(register_cvar("ze_human_shield", "1"), g_bHumanShield)

	bind_pcvar_num(register_cvar("ze_hud_info_human_red", "0"), g_iHudColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_human_green", "127"), g_iHudColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_human_blue", "255"), g_iHudColor[Blue])

	// Initial Value.
	g_msgWeapPickup = get_user_msgid("WeapPickup")
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
		set_msg_block(g_msgWeapPickup, BLOCK_ONCE) // This message already sent by GameDLL.
		rg_give_item(id, "weapon_knife", GT_APPEND)
	}

	// HUD Info.
	if (module_exists(LIBRARY_HUDINFO))
	{
		ze_hud_info_set(id, "CLASS_HUMAN", g_iHudColor, true)
	}

#if defined CUSTOM_MODEL
	new szModel[MAX_NAME_LENGTH]

	// Get random Models from Array.
	ArrayGetString(g_aHumanModels, random_num(0, ArraySize(g_aHumanModels) - 1), szModel, charsmax(szModel))

	// Set player Model.
	rg_set_user_model(id, szModel, true)

	if (module_exists(LIBRARY_WPNMODELS))
	{
		// Remove player Zombie Knife.
		ze_remove_user_view_model(id, CSW_KNIFE)
		ze_remove_user_weap_model(id, CSW_KNIFE)
	}
#endif
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	if (!iInfector)
		return ZE_CONTINUE

	if (g_bHumanShield)
	{
		static Float:flArmor; flArmor = get_entvar(iVictim, var_armorvalue)

		if (flArmor - flDamage <= 0.0)
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