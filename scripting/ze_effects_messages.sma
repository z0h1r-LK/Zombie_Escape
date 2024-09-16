#include <amxmodx>
#include <reapi>
#include <ze_core>

// Defines.
#define TASK_SHOWHUD 100

// HUD Position.
const Float:HUD_WIN_X = -1.0
const Float:HUD_WIN_Y = 0.4
const Float:HUD_SCORE_X = -1.0
const Float:HUD_SCORE_Y = 0.0

// Colors.
enum _:Colors
{
	Red = 0,
	Green,
	Blue
}

// Team ID.
enum _:Teams
{
	Human = 0,
	Zombie
}

// Cvars.
new g_iWinMsgMode,
	g_iScoreMsgMode,
	g_iScoreMsgColors[Colors],
	g_iWinMsgColors[Teams][Colors],
	Float:g_flWinMsgDuration

// Variables.
new g_iHumanWins,
	g_iZombieWins,
	g_iMsgScoreHUD

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Effects: Messages", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_scoremsg_mode", "2"), g_iScoreMsgMode)
	bind_pcvar_num(register_cvar("ze_scoremsg_red", "200"), g_iScoreMsgColors[Red])
	bind_pcvar_num(register_cvar("ze_scoremsg_green", "100"), g_iScoreMsgColors[Green])
	bind_pcvar_num(register_cvar("ze_scoremsg_blue", "50"), g_iScoreMsgColors[Blue])
	bind_pcvar_num(register_cvar("ze_winmsg_mode", "2"), g_iWinMsgMode)
	bind_pcvar_num(register_cvar("ze_winmsg_hm_red", "0"), g_iWinMsgColors[Human][Red])
	bind_pcvar_num(register_cvar("ze_winmsg_hm_green", "127"), g_iWinMsgColors[Human][Green])
	bind_pcvar_num(register_cvar("ze_winmsg_hm_blue", "255"), g_iWinMsgColors[Human][Blue])
	bind_pcvar_num(register_cvar("ze_winmsg_zm_red", "255"), g_iWinMsgColors[Zombie][Red])
	bind_pcvar_num(register_cvar("ze_winmsg_zm_green", "0"), g_iWinMsgColors[Zombie][Green])
	bind_pcvar_num(register_cvar("ze_winmsg_zm_blue", "0"), g_iWinMsgColors[Zombie][Blue])
	bind_pcvar_float(get_cvar_pointer("mp_round_restart_delay"), g_flWinMsgDuration)

	// Set Values.
	g_iMsgScoreHUD = CreateHudSyncObj()
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// Remove tasks.
	remove_task(id+TASK_SHOWHUD)
}

public ze_game_started()
{
	g_iHumanWins = get_member_game(m_iNumCTWins)
	g_iZombieWins = get_member_game(m_iNumTerroristWins)
}

public ze_user_spawn_post(id)
{
	// Task repeat display score message.
	if (!task_exists(id+TASK_SHOWHUD))
	{
		set_task(1.0, "show_ScoreMessage", id+TASK_SHOWHUD, .flags = "b")
	}
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	// Remove tasks.
	remove_task(iVictim+TASK_SHOWHUD)
}

public show_ScoreMessage(id)
{
	id -= TASK_SHOWHUD
	switch (g_iScoreMsgMode)
	{
		case 1: // HUD.
		{
			set_hudmessage(g_iScoreMsgColors[Red], g_iScoreMsgColors[Green], g_iScoreMsgColors[Blue], HUD_SCORE_X, HUD_SCORE_Y, 0, 1.0, 1.0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_iMsgScoreHUD, "%L", LANG_PLAYER, "HUD_SCOREMESSAGE", g_iHumanWins, g_iZombieWins)
		}
		case 2: // DHUD.
		{
			set_dhudmessage(g_iScoreMsgColors[Red], g_iScoreMsgColors[Green], g_iScoreMsgColors[Blue], HUD_SCORE_X, HUD_SCORE_Y, 0, 1.0, 1.0, 0.1, 0.1)
			show_dhudmessage(id, "%L", LANG_PLAYER, "HUD_SCOREMESSAGE", g_iHumanWins, g_iZombieWins)
		}
	}
}

public ze_roundend(iWinTeam)
{
	if (iWinTeam != ZE_TEAM_UNA)
	{
		if (g_iWinMsgMode != 0)
		{
			new szTransKey[24], iMsgColor[Colors]

			switch (iWinTeam)
			{
				case ZE_TEAM_HUMAN:
				{
					iMsgColor[Red] = g_iWinMsgColors[Human][Red]
					iMsgColor[Green] = g_iWinMsgColors[Human][Green]
					iMsgColor[Blue] = g_iWinMsgColors[Human][Blue]
					szTransKey = "HUD_ESCAPE_SUCCESS"
				}
				case ZE_TEAM_ZOMBIE:
				{
					iMsgColor[Red] = g_iWinMsgColors[Zombie][Red]
					iMsgColor[Green] = g_iWinMsgColors[Zombie][Green]
					iMsgColor[Blue] = g_iWinMsgColors[Zombie][Blue]
					szTransKey = "HUD_ESCAPE_FAIL"
				}
			}

			switch (g_iWinMsgMode)
			{
				case 1: // Chat.
				{
					ze_colored_print(0, "%L", LANG_PLAYER, szTransKey)
				}
				case 2: // Text Message.
				{
					client_print(0, print_center, "%L", LANG_PLAYER, szTransKey)
				}
				case 3: // HUD.
				{
					set_hudmessage(iMsgColor[Red], iMsgColor[Green], iMsgColor[Blue], HUD_WIN_X, HUD_WIN_Y, 2, g_flWinMsgDuration, g_flWinMsgDuration, 0.05, 0.0)
					show_hudmessage(0, "%L", LANG_PLAYER, szTransKey)
				}
				case 4: // DHUD.
				{
					set_dhudmessage(iMsgColor[Red], iMsgColor[Green], iMsgColor[Blue], HUD_WIN_X, HUD_WIN_Y, 2, g_flWinMsgDuration, g_flWinMsgDuration, 0.05, 0.0)
					show_dhudmessage(0, "%L", LANG_PLAYER, szTransKey)
				}
			}
		}
	}
}