#include <amxmodx>
#include <reapi>
#include <nvault>
#include <ze_core>

// Vault Name.
new const g_szVaultName[] = "Coins"

// CVars.
new g_iSaveType,
	g_iDmgReward,
	g_iWinsReward,
	g_iStartCoins,
	g_iInfectReward,
	g_iZombieKilled,
	bool:g_bDmgEnabled,
	bool:g_bEarnMessage,
	Float:g_flReqDamage

// Variables.
new g_iVaultHandle

// Array.
new g_iCoins[MAX_PLAYERS+1],
	Float:g_flDamage[MAX_PLAYERS+1]

// String.
new g_szAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH]

// Trie.
new Trie:g_tTempVault

public plugin_natives()
{
	register_library("ze_coins_system")
	register_native("ze_get_user_coins", "__native_get_user_coins")
	register_native("ze_set_user_coins", "__native_set_user_coins")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Coins System", ZE_VERSION, ZE_AUTHORS)

	// Hook Chain.
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "fw_TakeDamage_Post", 1)

	// CVars.
	bind_pcvar_num(register_cvar("ze_coins_save", "1"), g_iSaveType)
	bind_pcvar_num(register_cvar("ze_coins_wins", "10"), g_iWinsReward)
	bind_pcvar_num(register_cvar("ze_coins_infect", "2"), g_iInfectReward)
	bind_pcvar_num(register_cvar("ze_coins_killed", "15"), g_iZombieKilled)
	bind_pcvar_num(register_cvar("ze_coins_dmg", "1"), g_bDmgEnabled)
	bind_pcvar_num(register_cvar("ze_coins_dmg_rw", "1"), g_iDmgReward)
	bind_pcvar_num(register_cvar("ze_coins_start", "10"), g_iStartCoins)
	bind_pcvar_float(register_cvar("ze_coins_dmg_req", "800.0"), g_flReqDamage)
	bind_pcvar_num(register_cvar("ze_earn_coins_message", "1"), g_bEarnMessage)

	// Create new hash map.
	g_tTempVault = TrieCreate()
}

public plugin_end()
{
	// Free the Memory.
	TrieDestroy(g_tTempVault)
}

public client_putinserver(id)
{
	if (is_user_hltv(id))
		return

	if (!g_iSaveType)
		return

	// Get player's steamid.
	get_user_authid(id, g_szAuth[id], charsmax(g_szAuth[]))

	// Load player's coins.
	read_Coins(id)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id))
		return

	if (!g_iSaveType)
		return

	// Save player's coins.
	write_Coins(id)

	// Reset var.
	g_iCoins[id] = 0
	g_flDamage[id] = 0.0
	g_szAuth[id] = NULL_STRING
}

public ze_user_infected(iVictim, iInfector)
{
	// Server?
	if (!iInfector)
		return

	g_iCoins[iInfector] += g_iInfectReward
	ze_colored_print(iInfector, "%L", LANG_PLAYER, "MSG_COINS_INFECTED", g_iInfectReward)
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	// Not player?
	if (!is_user_connected(iAttacker))
		return

	// Victim is Zombie?
	if (!ze_is_user_zombie(iVictim))
		return

	g_iCoins[iAttacker] += g_iZombieKilled
	ze_colored_print(iAttacker, "%L", LANG_PLAYER, "MSG_COINS_KILLED", g_iZombieKilled)
}

public fw_TakeDamage_Post(const iVictim, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	if (!g_bDmgEnabled)
		return

	// Is Zombie?
	if (iVictim == iAttacker || !ze_is_user_zombie(iVictim) || ze_is_user_zombie(iAttacker))
		return

	// This for avoid loop without stop!
	if (g_flReqDamage > 0.0)
	{
		g_flDamage[iAttacker] += flDamage

		while (g_flDamage[iAttacker] >= g_flReqDamage)
		{
			// +1 Coin.
			g_iCoins[iAttacker] += g_iDmgReward
			g_flDamage[iAttacker] -= g_flReqDamage
		}
	}
}

public ze_roundend(iWinTeam)
{
	if (iWinTeam == ZE_TEAM_HUMAN)
	{
		if (g_iWinsReward > 0)
		{
			new iPlayers[MAX_PLAYERS], iAliveNum
			get_players(iPlayers, iAliveNum, "a")

			for (new id, i = 0; i < iAliveNum; i++)
			{
				id = iPlayers[i]

				// Is Zombie?
				if (ze_is_user_zombie(id))
					continue

				g_iCoins[id] += g_iWinsReward
				ze_colored_print(id, "%L", LANG_PLAYER, "MSG_COINS_WINS", g_iWinsReward)
			}
		}
	}
}

/**
 * -=| Functions |=-
 */
read_Coins(const id)
{
	switch (g_iSaveType)
	{
		case 1: // Trie.
		{
			if (!TrieGetCell(g_tTempVault, g_szAuth[id], g_iCoins[id]))
			{
				g_iCoins[id] = g_iStartCoins
			}
		}
		case 2: // nVault.
		{
			// Open the Vault.
			if ((g_iVaultHandle = nvault_open(g_szVaultName)) != INVALID_HANDLE)
			{
				new szCoins[32]

				if (nvault_get(g_iVaultHandle, g_szAuth[id], szCoins, charsmax(szCoins)))
				{
					g_iCoins[id] = str_to_num(szCoins)
				}
				else
				{
					g_iCoins[id] = g_iStartCoins
				}

				// Close the Vault.
				nvault_close(g_iVaultHandle)
			}
		}
	}
}

write_Coins(const id)
{
	switch (g_iSaveType)
	{
		case 1: // Trie.
		{
			// Save player's coins on Trie.
			TrieSetCell(g_tTempVault, g_szAuth[id], g_iCoins[id])
		}
		case 2: // nVault.
		{
			if ((g_iVaultHandle = nvault_open(g_szVaultName)) != INVALID_HANDLE)
			{
				new szCoins[32]

				// Convert Integer to String.
				num_to_str(g_iCoins[id], szCoins, charsmax(szCoins))
				nvault_pset(g_iVaultHandle, g_szAuth[id], szCoins)

				// Close the Vault.
				nvault_close(g_iVaultHandle)
			}
		}
	}
}

/**
 * -=| Natives |=-
 */
public __native_get_user_coins(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return NULLENT
	}

	return g_iCoins[id]
}

public __native_set_user_coins(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (!get_param(3))
		g_iCoins[id] = get_param(2)
	else
		g_iCoins[id] += get_param(2)
	return true
}