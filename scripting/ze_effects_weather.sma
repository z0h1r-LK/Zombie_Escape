#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <reapi>

#include <ze_core>
#include <ini_file>

public plugin_precache()
{
	new bFog = 1,
		bRain = 1,
		bSnow = 1,
		szColor[16] = "0 0 0",
		szDensity[16] = "0.0016",
		szSkyName[MAX_NAME_LENGTH] = "space"

	// Read weather settings from INI file.
	if (!ini_read_int(ZE_FILENAME, "Weather", "RAIN", bRain))
		ini_write_int(ZE_FILENAME, "Weather", "RAIN", bRain)
	if (!ini_read_int(ZE_FILENAME, "Weather", "SNOW", bSnow))
		ini_write_int(ZE_FILENAME, "Weather", "SNOW", bSnow)
	if (!ini_read_int(ZE_FILENAME, "Weather", "FOG", bFog))
		ini_write_int(ZE_FILENAME, "Weather", "FOG", bFog)
	if (!ini_read_string(ZE_FILENAME, "Weather", "FOG_COLOR", szColor, charsmax(szColor)))
		ini_write_string(ZE_FILENAME, "Weather", "FOG_COLOR", szColor)
	if (!ini_read_string(ZE_FILENAME, "Weather", "FOG_DENSITY", szDensity, charsmax(szDensity)))
		ini_write_string(ZE_FILENAME, "Weather", "FOG_DENSITY", szDensity)
	if (!ini_read_string(ZE_FILENAME, "Weather", "SKYNAME", szSkyName, charsmax(szSkyName)))
		ini_write_string(ZE_FILENAME, "Weather", "SKYNAME", szSkyName)

	new iEnt

	if (bFog)
	{
		if ((iEnt = rg_create_entity("env_fog", true)))
		{
			DispatchKeyValue(iEnt, "density", szDensity)
			DispatchKeyValue(iEnt, "rendercolor", szColor)
		}
		else
		{
			server_print("[ZE] Error in creating env_fog (%i)", iEnt)
		}
	}

	if (bRain)
	{
		if (!(iEnt = rg_create_entity("env_rain", true)))
		{
			server_print("[ZE] Error in creating env_rain (%i)", iEnt)
		}
	}

	if (bSnow)
	{
		if (!(iEnt = rg_create_entity("env_snow", true)))
		{
			server_print("[ZE] Error in creating env_snow (%i)", iEnt)
		}
	}

	if (szSkyName[0])
	{
		precache_sky(szSkyName)
		set_cvar_string("sv_skyname", szSkyName)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Effects: Weather", ZE_VERSION, ZE_AUTHORS)

	// Disable some Cvars.
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
}