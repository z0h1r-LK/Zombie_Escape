#include <amxmodx>
#include <engine>
#include <reapi>

#include <ze_core>

// Flags.
enum (<<=1)
{
	NVG_Human = BIT(0),
	NVG_Zombie,
	NVG_Spectator
}

// NightVision Sounds.
new const g_szNVGSounds[][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

// Cvars.
new g_szLight[2]

// Variables.
new g_bitsNvgFlags,
	g_msgNvgToggle

// Array.
new bool:g_bNVGToggle[MAX_PLAYERS+1],
	Float:g_flCooldown[MAX_PLAYERS+1]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Effects: Lighting/Night-Vision", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	new const pCvarLighting = register_cvar("ze_lighting", "")
	new const pCvarNvgFlags = register_cvar("ze_nvg_flags", "")

	set_pcvar_string(pCvarNvgFlags, "") // Fix nvg stopping working after next map or server restart.
	bind_pcvar_string(pCvarLighting, g_szLight, charsmax(g_szLight))

	hook_cvar_change(pCvarLighting, "cvar_Lightnig")
	hook_cvar_change(pCvarNvgFlags, "cvar_NVGFlags")

	// Command.
	register_clcmd("nightvision", "cmd_NightVision")

	// Initial Value.
	g_msgNvgToggle = get_user_msgid("NVGToggle")
}

public cvar_Lightnig(pCvar)
{
	emessage_begin(MSG_ALL, SVC_LIGHTSTYLE)
	ewrite_byte(0) // Light index.
	ewrite_string(g_szLight) // Light style.
	emessage_end()
}

public cvar_NVGFlags(pCvar, const szOldVal[], const szNewVal[])
{
	g_bitsNvgFlags = read_flags(szNewVal)
}

public client_putinserver(id)
{
	set_task(1.0, "set_LightStyle", id)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	if (is_user_hltv(id))
		return

	g_flCooldown[id] = 0.0
	g_bNVGToggle[id] = false
}

public ze_user_spawn_post(id)
{
	g_bNVGToggle[id] = false
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	g_bNVGToggle[iVictim] = false
}

public cmd_NightVision(const id)
{
	if (!CanUseNvg(id) && !get_member(id, m_bHasNightVision))
		return PLUGIN_HANDLED_MAIN

	new const Float:flHlTime = get_gametime()
	if (g_flCooldown[id] > flHlTime)
		return PLUGIN_HANDLED_MAIN

	// Delay 1700ms
	g_flCooldown[id] = flHlTime + 1.7

	// Switcher.
	g_bNVGToggle[id] = ~g_bNVGToggle[id]

	// Play sound for player.
	rg_send_audio(id, g_szNVGSounds[ g_bNVGToggle[id] ? 1 : 0 ], PITCH_NORM)

	// Turn On or Off NightVision.
	message_begin(MSG_ONE, g_msgNvgToggle, .player = id)
	write_byte(g_bNVGToggle[id]) // Flag.
	message_end()
	return PLUGIN_HANDLED_MAIN
}

public ze_roundend(iWinTeam)
{
	arrayset(g_bNVGToggle, false, MAX_PLAYERS+1)
}

public set_LightStyle(const id)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return

	emessage_begin(MSG_ONE, SVC_LIGHTSTYLE, _, id)
	ewrite_byte(0) // Light index.
	ewrite_string(g_szLight) // Light style.
	emessage_end()
}

/**
 * -=| Function |=-
 */
CanUseNvg(id)
{
	if (!is_user_alive(id))
	{
		if (g_bitsNvgFlags & NVG_Spectator)
			return true
	}
	else if (ze_is_user_zombie(id))
	{
		if (g_bitsNvgFlags & NVG_Zombie)
			return true
	}
	else // Human.
	{
		if (g_bitsNvgFlags & NVG_Human)
			return true
	}

	return false
}