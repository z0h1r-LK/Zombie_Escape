#include <amxmodx>
#include <reapi>

#include <ze_core>

// Cvars.
new g_iFragsEscapeSuccess,
	g_iFragsHumanInfect,
	g_iFragsZombieKilled,
	g_iDeathsZombieKilled,
	g_iDeathsHumanInfect

// Variables.
new g_iMsgScoreInfo

// Arrays.
new g_iFrags[MAX_PLAYERS+1],
	g_iDeaths[MAX_PLAYERS+1]

public plugin_natives()
{
	register_native("ze_add_user_frags", "__native_add_user_frags")
	register_native("ze_add_user_deaths", "__native_add_user_deaths")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Effects: Frags/Deaths", ZE_VERSION, ZE_AUTHORS)

	// Messages.
	register_message(get_user_msgid("ScoreInfo"), "fw_ScoreInfo_Msg")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_frags_escape_success", "10"), g_iFragsEscapeSuccess)
	bind_pcvar_num(register_cvar("ze_frags_infect_human", "2"), g_iFragsHumanInfect)
	bind_pcvar_num(register_cvar("ze_frags_killed_zombie", "4"), g_iFragsZombieKilled)
	bind_pcvar_num(register_cvar("ze_deaths_killed_zombie", "1"), g_iDeathsZombieKilled)
	bind_pcvar_num(register_cvar("ze_deaths_infect_human", "1"), g_iDeathsHumanInfect)

	// Set Values.
	g_iMsgScoreInfo = get_user_msgid("ScoreInfo")
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_iFrags[id] = 0
	g_iDeaths[id] = 0
}

public fw_ScoreInfo_Msg(msg_id, msg_dest, entity)
{
	// Get client index.
	static player; player = get_msg_arg_int(1)

	if (!is_user_connected(player))
		return PLUGIN_HANDLED

	// Update Frags and Deaths on Scoreboard.
	set_msg_arg_int(2, ARG_SHORT, g_iFrags[player])
	set_msg_arg_int(3, ARG_SHORT, g_iDeaths[player])
	return PLUGIN_CONTINUE
}

public ze_user_infected(iVictim, iInfector)
{
	// Server?
	if (!iInfector)
		return

	// +1 Frag.
	if (g_iFragsHumanInfect > 0)
	{
		g_iFrags[iInfector] += g_iFragsHumanInfect

		// Update Frags on Server.
		set_entvar(iInfector, var_frags, float(g_iFrags[iInfector]))

		// Update Frags on Scoreboard ( Client Side ).
		UpdateScore(iInfector)
	}

	if (g_iDeathsHumanInfect > 0)
	{
		// +1 Death.
		g_iDeaths[iVictim] += g_iDeathsHumanInfect

		// Update Deaths on Server.
		set_member(iVictim, m_iDeaths, g_iDeaths[iVictim])

		// Update Deaths on Scoreboard ( Client Side ).
		UpdateScore(iVictim)
	}
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	if (!is_user_connected(iAttacker))
		return

	// Victim is Zombie?
	if (ze_is_user_zombie(iVictim))
	{
		if (g_iDeathsZombieKilled > 0)
		{
			g_iDeaths[iVictim] += g_iDeathsZombieKilled

			// Update Deaths on Server.
			set_member(iVictim, m_iDeaths, g_iDeaths[iVictim])

			// Update Deaths on Scoreboard ( Client Side ).
			UpdateScore(iVictim)
		}

		if (g_iFragsZombieKilled > 0)
		{
			g_iFrags[iAttacker] += g_iFragsZombieKilled

			// Update Frags on Server.
			set_entvar(iAttacker, var_frags, float(g_iFrags[iAttacker]))

			// Update Frags on Scoreboard ( Client Side ).
			UpdateScore(iAttacker)
		}
	}
}

public ze_roundend(iWinTeam)
{
	if (iWinTeam == ZE_TEAM_HUMAN)
	{
		if (g_iFragsEscapeSuccess > 0)
		{
			new iPlayers[MAX_PLAYERS], iAliveNum
			get_players(iPlayers, iAliveNum, "a")

			for (new id, i = 0; i < iAliveNum; i++)
			{
				id = iPlayers[i]

				// Is Zombie?
				if (ze_is_user_zombie(id))
					continue

				g_iFrags[id] += g_iFragsEscapeSuccess
				UpdateScore(id)
			}
		}
	}
}

/**
 * -=| Function |=-
 */
UpdateScore(id)
{
	// Update Frags and Deaths on Scoreboard (client side).
	message_begin(MSG_ALL, g_iMsgScoreInfo)
	write_byte(id) // Client index.
	write_short(g_iFrags[id]) // Frags.
	write_short(g_iDeaths[id]) // Deaths.
	write_short(0) // ClassID (useless).
	write_short(get_user_team(id)) // Team ID.
	message_end()
}

/**
 * -=| Natives |=-
 */
public __native_add_user_frags(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (get_param(3))
		g_iFrags[id] += get_param(2)
	else
		g_iFrags[id] = get_param(2)
	UpdateScore(id)
	return true
}

public __native_add_user_deaths(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	if (get_param(3))
		g_iDeaths[id] += get_param(2)
	else
		g_iDeaths[id] = get_param(2)
	UpdateScore(id)
	return true
}