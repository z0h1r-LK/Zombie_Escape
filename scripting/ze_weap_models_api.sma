#include <amxmodx>
#include <hamsandwich>
#include <reapi>

#include <ze_stocks>
#include <ze_core_const>

// Boolean's.
new bool:g_bCustomViewModelPath[MAX_PLAYERS+1][MAX_WEAPONS]
new bool:g_bCustomWeapModelPath[MAX_PLAYERS+1][MAX_WEAPONS]

// Strings (Triple Rows)
new g_szCustomViewModelsPath[MAX_PLAYERS+1][MAX_WEAPONS][MAX_RESOURCE_PATH_LENGTH]
new g_szCustomWeapModelsPath[MAX_PLAYERS+1][MAX_WEAPONS][MAX_RESOURCE_PATH_LENGTH]

public plugin_natives()
{
	register_library("ze_weap_models_api")

	register_native("ze_set_user_view_model", "__native_set_user_view_model")
	register_native("ze_set_user_weap_model", "__native_set_user_weap_model")

	register_native("ze_remove_user_view_model", "__native_remove_user_view_model")
	register_native("ze_remove_user_weap_model", "__native_remove_user_weap_model")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Weapon Models APIs", ZE_VERSION, ZE_AUTHORS)

	// Hook Chain.
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "fw_PlayerWeapon_DefaultDeploy")
}

public client_putinserver(id)
{
	for (new iWeaponID = 0; iWeaponID <= CSW_LAST_WEAPON; iWeaponID++)
	{
		// Reset boolean.
		g_bCustomViewModelPath[id][iWeaponID] = false
		g_bCustomWeapModelPath[id][iWeaponID] = false

		// Reset string.
		g_szCustomViewModelsPath[id][iWeaponID] = NULL_STRING
		g_szCustomWeapModelsPath[id][iWeaponID] = NULL_STRING
	}
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// Reset strings.
	for (new iWeaponID = 0; iWeaponID <= CSW_LAST_WEAPON; iWeaponID++)
	{
		// Reset boolean.
		g_bCustomViewModelPath[id][iWeaponID] = false
		g_bCustomWeapModelPath[id][iWeaponID] = false

		// Reset string.
		g_szCustomViewModelsPath[id][iWeaponID] = NULL_STRING
		g_szCustomWeapModelsPath[id][iWeaponID] = NULL_STRING
	}
}

public fw_PlayerWeapon_DefaultDeploy(iEnt, const szViewModel[], const szWeaponModel[], iAnim, const szAnimExt[], iSkipLocal)
{
	if (is_nullent(iEnt))
		return HC_CONTINUE

	// Weapon owner.
	static id; id = get_member(iEnt, m_pPlayer)

	// Weapon ID.
	static iWeaponID; iWeaponID = get_member(iEnt, m_iId)

	if (g_bCustomViewModelPath[id][iWeaponID])
	{
		SetHookChainArg(2, ATYPE_STRING, g_szCustomViewModelsPath[id][iWeaponID])
	}

	if (g_bCustomWeapModelPath[id][iWeaponID])
	{
		SetHookChainArg(3, ATYPE_STRING, g_szCustomWeapModelsPath[id][iWeaponID])
	}

	return HC_CONTINUE
}

/**
 * -=| Natives |=-
 */
public __native_set_user_view_model(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new iWeaponID = get_param(2)

	if (CSW_P228 > iWeaponID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Weapon ID (%d)", iWeaponID)
		return false
	}

	new szModel[MAX_RESOURCE_PATH_LENGTH]

	get_string(3, szModel, charsmax(szModel))
	copy(g_szCustomViewModelsPath[id][iWeaponID], charsmax(g_szCustomViewModelsPath[][]), szModel)
	g_bCustomViewModelPath[id][iWeaponID] = true

	if (is_user_alive(id))
	{
		// Current Weapon?
		new iEnt = get_member(id, m_pActiveItem)
		if (!is_nullent(iEnt))
		{
			if (get_member(iEnt, m_iId) == iWeaponID)
			{
				set_entvar(id, var_viewmodel, szModel)
			}
		}
	}

	return true
}

public __native_set_user_weap_model(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new iWeaponID = get_param(2)

	if (CSW_P228 > iWeaponID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Weapon ID (%d)", iWeaponID)
		return false
	}

	new szModel[MAX_RESOURCE_PATH_LENGTH]
	get_string(3, szModel, charsmax(szModel))
	copy(g_szCustomWeapModelsPath[id][iWeaponID][0], charsmax(g_szCustomWeapModelsPath[][]), szModel)
	g_bCustomWeapModelPath[id][iWeaponID] = true

	if (is_user_alive(id))
	{
		// Current Weapon?
		new iEnt = get_member(id, m_pActiveItem)
		if (!is_nullent(iEnt))
		{
			if (get_member(iEnt, m_iId) == iWeaponID)
			{
				set_entvar(id, var_weaponmodel, szModel)
			}
		}
	}

	return true
}

public __native_remove_user_view_model(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	new iWeaponID = get_param(2)

	if (CSW_P228 > iWeaponID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Weapon ID (%d)", iWeaponID)
		return false
	}

	// Already Disabled?
	if (!g_bCustomViewModelPath[id][iWeaponID])
		return true

	g_bCustomViewModelPath[id][iWeaponID] = false
	g_szCustomViewModelsPath[id][iWeaponID] = NULL_STRING

	if (is_user_alive(id))
	{
		// Current Weapon?
		new iEnt = get_member(id, m_pActiveItem)
		if (!is_nullent(iEnt))
		{
			if (get_member(iEnt, m_iId) == iWeaponID)
			{
				ExecuteHamB(Ham_Item_Deploy, iEnt)
			}
		}
	}

	return true
}

public __native_remove_user_weap_model(plugin_id, num_params)
{
	// Get client index.
	new id = get_param(1)

	// Player not on game?
	if (!is_user_connected(id))
	{
		// Print error message on server console.
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	// Get weapon ID.
	new iWeaponID = get_param(2)

	// Weapon not found on game.
	if (CSW_P228 > iWeaponID > CSW_LAST_WEAPON)
	{
		// Print error message on server console.
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Weapon ID (%d)", iWeaponID)
		return false
	}

	// Already Disabled?
	if (!g_bCustomWeapModelPath[id][iWeaponID])
		return true

	g_bCustomWeapModelPath[id][iWeaponID] = false
	g_szCustomWeapModelsPath[id][iWeaponID] = NULL_STRING

	if (is_user_alive(id))
	{
		// // Current Weapon?
		new iEnt = get_member(id, m_pActiveItem)
		if (!is_nullent(iEnt))
		{
			if (get_member(iEnt, m_iId) == iWeaponID)
			{
				ExecuteHamB(Ham_Item_Deploy, iEnt)
			}
		}
	}

	return true
}