#include <amxmodx>
#include <engine>
#include <reapi>
#include <ze_core>

// Libraries.
stock const LIBRARY_HUDINFO[] = "ze_hud_info"
stock const LIBRARY_WPNMODELS[] = "ze_weap_models_api"

// Define.
#define CUSTOM_MODEL

// Macro.
#define is_user_survivor(%0) flag_get_boolean(g_bitsIsSurvivor, %0)

// Weapon Models.
enum _:WEAPON_MODELS
{
	V_WEAPON[MAX_RESOURCE_PATH_LENGTH] = 0,
	P_WEAPON[MAX_RESOURCE_PATH_LENGTH]
}

// Colors indexes.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Weapon Models.
new g_v_szWeaponModel[MAX_RESOURCE_PATH_LENGTH] = "models/v_m249.mdl"
new g_p_szWeaponModel[MAX_RESOURCE_PATH_LENGTH] = "models/p_m249.mdl"

// CVars.
new g_iHealth,
	g_iArmor,
	g_iGravity,
	g_iWeaponUID,
	g_iGlowAmount,
	g_iHudColor[Colors],
	g_iGlowColors[Colors],
	bool:g_bBlockWeapon,
	bool:g_bGlowEnabled,
	bool:g_bBlockExtraItems,
	bool:g_bUnlimitedAmmo,
	Float:g_flSpeed,
	Float:g_flSpeedFactor,
	g_szWeaponName[MAX_NAME_LENGTH]

// Variables.
new g_bitsIsSurvivor,
	g_msgWeapPickup

// Dynamic Arrays.
new Array:g_aSurvivorModel

public plugin_natives()
{
	register_library("ze_class_survivor")
	register_native("ze_is_user_survivor", "__native_is_user_survivor")
	register_native("ze_set_user_survivor", "__native_set_user_survivor")
	register_native("ze_remove_user_survivor", "__native_remove_user_survivor")

	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_HUDINFO) || equal(module, LIBRARY_WPNMODELS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

#if defined CUSTOM_MODEL
public plugin_precache()
{
	// Default Survivor Models.
	new const szSurvivorModel[][] = {"ze_survivor"}

	// Create new dyn Array.
	g_aSurvivorModel = ArrayCreate(MAX_NAME_LENGTH, 1)

	// Read Survivor Models from INI file.
	ini_read_string_array(ZE_FILENAME, "Player Models", "SURVIVOR", g_aSurvivorModel)

	new i

	if (!ArraySize(g_aSurvivorModel))
	{
		for (i = 0; i < sizeof(szSurvivorModel); i++)
			ArrayPushString(g_aSurvivorModel, szSurvivorModel[i])

		// Write Survivor Models on INI file.
		ini_write_string_array(ZE_FILENAME, "Player Models", "SURVIVOR", g_aSurvivorModel)
	}

	// Read Survivor Weapon Models from INI file.
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "V_WEAPON_SURVIVOR", g_v_szWeaponModel, charsmax(g_v_szWeaponModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "V_WEAPON_SURVIVOR", g_v_szWeaponModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "P_WEAPON_SURVIVOR", g_p_szWeaponModel, charsmax(g_p_szWeaponModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "P_WEAPON_SURVIVOR", g_p_szWeaponModel)

	new szPlayerModel[MAX_NAME_LENGTH], szModel[MAX_RESOURCE_PATH_LENGTH], iFiles

	// Precache Models.
	iFiles = ArraySize(g_aSurvivorModel)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aSurvivorModel, i, szPlayerModel, charsmax(szPlayerModel))
		formatex(szModel, charsmax(szModel), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModel)
	}

	// Precache Models.
	precache_model(g_v_szWeaponModel)
	precache_model(g_p_szWeaponModel)
}
#endif

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Survivor", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "fw_HasRestrictItem_Pre")

	// Events.
	register_event("CurWeapon", "fw_CurWeapon_Event", "be", "2!0", "3=1")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_survivor_health", "6000"), g_iHealth)
	bind_pcvar_num(register_cvar("ze_survivor_armor", "0"), g_iArmor)
	bind_pcvar_num(register_cvar("ze_survivor_gravity", "640"), g_iGravity)

	bind_pcvar_float(register_cvar("ze_survivor_speed", "0.0"), g_flSpeed)
	bind_pcvar_float(register_cvar("ze_survivor_speed_factor", "50.0"), g_flSpeedFactor)

	bind_pcvar_num(register_cvar("ze_survivor_block_weapon", "1"), g_bBlockWeapon)
	bind_pcvar_num(register_cvar("ze_survivor_unlimited_ammo", "1"), g_bUnlimitedAmmo)
	bind_pcvar_num(register_cvar("ze_survivor_block_buy", "1"), g_bBlockExtraItems)

	bind_pcvar_num(register_cvar("ze_survivor_glow", "1"), g_bGlowEnabled)
	bind_pcvar_num(register_cvar("ze_survivor_glow_red", "0"), g_iGlowColors[Red])
	bind_pcvar_num(register_cvar("ze_survivor_glow_green", "0"), g_iGlowColors[Green])
	bind_pcvar_num(register_cvar("ze_survivor_glow_blue", "200"), g_iGlowColors[Blue])
	bind_pcvar_num(register_cvar("ze_survivor_glow_amount", "16"), g_iGlowAmount)

	bind_pcvar_num(register_cvar("ze_survivor_weapon_uid", "0"), g_iWeaponUID)
	bind_pcvar_string(register_cvar("ze_survivor_weapon", "weapon_m249"), g_szWeaponName, charsmax(g_szWeaponName))

	bind_pcvar_num(register_cvar("ze_hud_info_survivor_red", "0"), g_iHudColor[Red])
	bind_pcvar_num(register_cvar("ze_hud_info_survivor_green", "55"), g_iHudColor[Green])
	bind_pcvar_num(register_cvar("ze_hud_info_survivor_blue", "255"), g_iHudColor[Blue])

	// Commands.
	register_clcmd("drop", "cmd_DropWeapon")

	// Initial Value.
	g_msgWeapPickup = get_user_msgid("WeapPickup")
}

public cmd_DropWeapon(const id)
{
	// Player isn't Survivor?
	if (!is_user_survivor(id))
		return PLUGIN_CONTINUE

	// Player isn't Alive?
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE

	if (g_bBlockWeapon)
		return PLUGIN_HANDLED

	// Allow drop Guns.
	return PLUGIN_CONTINUE
}

public ze_user_humanized_pre(id)
{
	unset_User_Survivor(id)

	// Reset player view and weapon Models.
	ze_remove_user_view_model(id, CSW_M249)
	ze_remove_user_weap_model(id, CSW_M249)
}

public ze_user_infected_pre(iVictim, iInfector, Float:flDamage)
{
	// Server ID?
	if (!iInfector)
		return ZE_CONTINUE

	// Survivor?
	if (flag_get_boolean(g_bitsIsSurvivor, iVictim))
		return ZE_STOP // Prevent infection, keep taken damage.

	return ZE_CONTINUE
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	unset_User_Survivor(iVictim)
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	// All items unallowed for Survivors?
	if (g_bBlockExtraItems && is_user_survivor(id))
		return ZE_ITEM_DONT_SHOW
	return ZE_ITEM_AVAILABLE
}

public fw_HasRestrictItem_Pre(const id, pItem)
{
	// Player ins't Survivor?
	if (!is_user_survivor(id))
		return HC_CONTINUE

	// Block pick up weapon.
	SetHookChainReturn(ATYPE_BOOL, true)
	return HC_SUPERCEDE
}

public fw_CurWeapon_Event(const id)
{
	if (!g_bUnlimitedAmmo)
		return

	// Player isn't Survivor?
	if (!is_user_survivor(id))
		return

	new iMaxClip
	if ((iMaxClip = rg_get_weapon_info(read_data(2), WI_GUN_CLIP_SIZE)) < 0)
		return

	// Reloaded!
	set_member(get_member(id, m_pActiveItem), m_Weapon_iClip, iMaxClip)
}

/**
 * -=| Functions |=-
 */
set_User_Survivor(id)
{
	// Is Zombie?
	if (ze_is_user_zombie(id))
		ze_force_set_user_human(id)

	// Is not Survivor?
	if (!is_user_survivor(id))
		flag_set(g_bitsIsSurvivor, id)

	// Health.
	if (g_iHealth > 0)
	{
		new Float:flHealth = float(g_iHealth)
		set_entvar(id, var_health, flHealth)
		set_entvar(id, var_max_health, flHealth)
	}

	// Armor.
	if (g_iArmor > 0)
	{
		rg_set_user_armor(id, g_iArmor, ARMOR_VESTHELM)
	}

	// Gravity.
	if (g_iGravity > 0)
	{
		set_entvar(id, var_gravity, float(g_iGravity)/800.0)
	}

	// Speed.
	if (g_flSpeed > 0.0)
	{
		ze_set_user_speed(id, g_flSpeed)
	}
	else if (g_flSpeedFactor > 0.0)
	{
		ze_set_user_speed(id, g_flSpeedFactor, true)
	}

	// GlowShell rendering.
	if (g_bGlowEnabled)
	{
		set_ent_rendering(id, kRenderFxGlowShell, g_iGlowColors[Red], g_iGlowColors[Green], g_iGlowColors[Blue], kRenderNormal, g_iGlowAmount)
	}

	// Remove player All items.
	rg_remove_all_items(id)

	// Knife allowed.
	set_msg_block(g_msgWeapPickup, BLOCK_ONCE)
	rg_give_item(id, "weapon_knife", GT_APPEND)

	// Survivor Weapon.
	if (g_szWeaponName[0])
	{
		// Special Weapon.
		rg_give_custom_item(id, g_szWeaponName, GT_DROP_AND_REPLACE, g_iWeaponUID)
	}

	// HUD information's color.
	if (LibraryExists(LIBRARY_HUDINFO, LibType_Library))
	{
		ze_hud_info_set(id, "CLASS_SURVIVOR", g_iHudColor, true)
	}

#if defined CUSTOM_MODEL
	// Player model.
	new szModel[MAX_RESOURCE_PATH_LENGTH]
	ArrayGetString(g_aSurvivorModel, random_num(0, ArraySize(g_aSurvivorModel) - 1), szModel, charsmax(szModel))
	rg_set_user_model(id, szModel, true)

	if (LibraryExists(LIBRARY_WPNMODELS, LibType_Library))
	{
		// Weapon model.
		new iWeaponID = get_weaponid(g_szWeaponName)
		ze_set_user_view_model(id, iWeaponID, g_v_szWeaponModel)
		ze_set_user_weap_model(id, iWeaponID, g_p_szWeaponModel)
	}
#endif
}

unset_User_Survivor(id)
{
	// Remove player Flag Survivor.
	flag_unset(g_bitsIsSurvivor, id)

	// Reset player Max-Speed.
	ze_reset_user_speed(id)

	// Reset player rendering.
	set_ent_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
}

/**
 * -=| Natives |=-
 */
public __native_is_user_survivor(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	return flag_get_boolean(g_bitsIsSurvivor, id)
}

public __native_set_user_survivor(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	set_User_Survivor(id)
	return true
}

public __native_remove_user_survivor(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	unset_User_Survivor(id)

	if (get_param(1))
	{
		ze_set_user_zombie(id)
	}
	else
	{
		ze_set_user_human(id)
	}

	return true
}