#include <amxmodx>
#include <ze_core>

// Cvars.
new g_szLight[2]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Effects: Lighting/Night-Vision", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	new const pCvarLighting = register_cvar("ze_lighting", "n")

	bind_pcvar_string(pCvarLighting, g_szLight, charsmax(g_szLight))

	hook_cvar_change(pCvarLighting, "cvar_Lightnig")
}

public cvar_Lightnig(pCvar)
{
	emessage_begin(MSG_ALL, SVC_LIGHTSTYLE)
	ewrite_byte(0) // Light index.
	ewrite_string(g_szLight) // Light style.
	emessage_end()
}