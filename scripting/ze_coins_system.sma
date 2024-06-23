#include <amxmodx>
#include <nvault>
#include <reapi>
#include <sqlx>
#include <ze_core>

// Contants.
new const g_szVaultName[] = "ZE_Coins"
new const g_szLogFile[] = "SQL_Coins.log"

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
new g_iVaultCoins

// Array.
new g_iCoins[MAX_PLAYERS+1],
	Float:g_flDamage[MAX_PLAYERS+1]

// String.
new g_szAuth[MAX_PLAYERS+1][MAX_AUTHID_LENGTH]

// Trie.
new Trie:g_tTempVault

// SQL handle.
new Handle:g_hTuple

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

	// Initial Value.
	g_hTuple = Empty_Handle
	g_tTempVault = Invalid_Trie
	g_iVaultCoins = INVALID_HANDLE
}

public plugin_cfg()
{
	switch (g_iSaveType)
	{
		case 1: // Trie.
		{
			// Create new hash map.
			g_tTempVault = TrieCreate()
		}
		case 2: // nVault.
		{
			// Open the Vault.
			if ((g_iVaultCoins = nvault_open(g_szVaultName)) == INVALID_HANDLE)
				set_fail_state("Error in opening the nVault (-1)")
		}
		case 3: // SQL.
		{
			SQL_Init()
		}
	}
}

public plugin_end()
{
	switch (g_iSaveType)
	{
		case 1: // Trie.
		{
			// Free the Memory.
			if (g_tTempVault != Invalid_Trie)
				TrieDestroy(g_tTempVault)
		}
		case 2: // nVault.
		{
			// Close the Vault.
			if (g_iVaultCoins != INVALID_HANDLE)
				nvault_close(g_iVaultCoins)
		}
		case 3: // SQL.
		{
			if (g_hTuple != Empty_Handle)
				SQL_FreeHandle(g_hTuple)
		}
	}
}

public SQL_Init()
{
	new szHost[64], szUser[64], szPass[64], szDB[64], szType[16]

	// sql.cfg
	get_pcvar_string(register_cvar("amx_sql_host", "127.0.0.1", FCVAR_PROTECTED), szHost, charsmax(szHost))
	get_pcvar_string(register_cvar("amx_sql_user", "root", FCVAR_PROTECTED), szUser, charsmax(szUser))
	get_pcvar_string(register_cvar("amx_sql_pass", "", FCVAR_PROTECTED), szPass, charsmax(szPass))
	get_pcvar_string(register_cvar("amx_sql_db", "amx", FCVAR_PROTECTED), szDB, charsmax(szDB))
	get_pcvar_string(register_cvar("amx_sql_type", "mysql", FCVAR_PROTECTED), szType, charsmax(szType))
	new const iTimeOut = get_pcvar_num(register_cvar("amx_sql_timeout", "60", FCVAR_PROTECTED))

	new szDriver[16]
	SQL_GetAffinity(szDriver, charsmax(szDriver))

	if (!equali(szType, szDriver))
	{
		if (!SQL_SetAffinity(szType))
		{
			set_fail_state("[SQL] Failed to set affinity from %s to %s.", szDriver, szType);
		}
	}

	g_hTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB, iTimeOut)

	new Handle:hSQLConnection, szError[256], iError

	// Connect to SQL database.
	hSQLConnection = SQL_Connect(g_hTuple, iError, szError, charsmax(szError))

	if (hSQLConnection != Empty_Handle)
	{
		log_amx("[SQL][Coins] Successfully connected to SQL database: %s (ALL IS OK).", szDB)

		// Frees SQL handle.
		SQL_FreeHandle(hSQLConnection)
	}
	else
	{
		// Disable plugin.
		set_fail_state("[SQL][Coins] Failed to connect to SQL database: %s.", szError)
	}

	new szTable[200]
	if (equali(szType, "mysql"))
	{
		szTable = "CREATE TABLE IF NOT EXISTS `ze_coins` ( `AuthID` varchar(64) NOT NULL DEFAULT '', `Amount` int(32) NOT NULL DEFAULT 0, PRIMARY KEY (AuthID));"
	}
	else if (equali(szType, "sqlite"))
	{
		szTable = "CREATE TABLE IF NOT EXISTS `ze_coins` ( `AuthID` TEXT NOT NULL DEFAULT '', `Amount` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (AuthID));"
	}

	// Create Table.
	SQL_ThreadQuery(g_hTuple, "query_CreateTable", szTable)
}

public query_CreateTable(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
}

public client_authorized(id, const authid[])
{
	if (is_user_hltv(id))
		return

	if (!g_iSaveType)
		return

	// Get player's steamid.
	copy(g_szAuth[id], charsmax(g_szAuth[]), authid)

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
	if (iVictim == iAttacker || !is_user_connected(iAttacker))
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

	// Damage himself or player not on game?
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return

	if (!ze_is_user_zombie(iVictim) || ze_is_user_zombie(iAttacker))
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

public read_Coins(const id)
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
			new szCoins[32]

			if (nvault_get(g_iVaultCoins, g_szAuth[id], szCoins, charsmax(szCoins)))
			{
				g_iCoins[id] = str_to_num(szCoins)
			}
			else
			{
				g_iCoins[id] = g_iStartCoins
			}
		}
		case 3: // SQL.
		{
			new szQuery[128], szData[4]
			formatex(szQuery, charsmax(szQuery), "SELECT * FROM `ze_coins` WHERE `AuthID` = '%s';", g_szAuth[id])

			num_to_str(id, szData, charsmax(szData))
			SQL_ThreadQuery(g_hTuple, "query_SelectData", szQuery, szData, charsmax(szData))
		}
	}
}

public query_SelectData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	if (SQL_IsFail(iFailState, iError, szError, g_szLogFile))
		return

	new const id = str_to_num(szData)

	if (!SQL_NumResults(hQuery))
	{
		g_iCoins[id] = g_iStartCoins
	}
	else
	{
		g_iCoins[id] = SQL_ReadResult(hQuery, 1)
	}
}

public write_Coins(const id)
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
			new szCoins[32]

			// Convert Integer to String.
			num_to_str(g_iCoins[id], szCoins, charsmax(szCoins))
			nvault_pset(g_iVaultCoins, g_szAuth[id], szCoins)
		}
		case 3: // SQL.
		{
			new szQuery[128]
			formatex(szQuery, charsmax(szQuery), "REPLACE INTO `ze_coins` (`AuthID`, `Amount`) VALUES ('%s', %d);", g_szAuth[id], g_iCoins[id])
			SQL_ThreadQuery(g_hTuple, "query_SetData", szQuery)
		}
	}
}

public query_SetData(iFailState, Handle:hQuery, szError[], iError, szData[], iSize, Float:flQueueTime)
{
	SQL_IsFail(iFailState, iError, szError, g_szLogFile)
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