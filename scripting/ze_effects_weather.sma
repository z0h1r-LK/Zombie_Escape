#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <reapi>

#include <ze_core>
#include <ini_file>

// XVars.
public x_i3DSkyEnt = 0;

public plugin_precache()
{
	new bFog = 1,
		bRain = 1,
		bSnow = 1,
		b3DSky = 0,
		i3DSkyBody = 0,
		i3DSkySkin = 0,
		szColor[16] = "0 0 0",
		szDensity[16] = "0.0016",
		szSkyName[MAX_NAME_LENGTH] = "space",
		sz3DSkyModel[MAX_RESOURCE_PATH_LENGTH] = "models/zm_es/xen_skybox1024.mdl"

	// Read weather settings from INI file.
	if (!ini_read_int(ZE_FILENAME, "Weather", "3D_SKYBOX", b3DSky))
		ini_write_int(ZE_FILENAME, "Weather", "3D_SKYBOX", b3DSky)
	if (!ini_read_int(ZE_FILENAME, "Weather", "3D_SKYBOX_BODY", i3DSkyBody))
		ini_write_int(ZE_FILENAME, "Weather", "3D_SKYBOX_BODY", i3DSkyBody)
	if (!ini_read_int(ZE_FILENAME, "Weather", "3D_SKYBOX_SKIN", i3DSkySkin))
		ini_write_int(ZE_FILENAME, "Weather", "3D_SKYBOX_SKIN", i3DSkySkin)
	if (!ini_read_string(ZE_FILENAME, "Weather", "3D_SKYBOX_MODEL", sz3DSkyModel, charsmax(sz3DSkyModel)))
		ini_write_string(ZE_FILENAME, "Weather", "3D_SKYBOX_MODEL", sz3DSkyModel)

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

	if (!b3DSky)
	{
		if (szSkyName[0])
		{
			precache_sky(szSkyName)
			set_cvar_string("sv_skyname", szSkyName)
		}
	}
	else
	{
		precache_model(sz3DSkyModel)

		if (!(iEnt = rg_create_entity("info_target")))
		{
			server_print("[ZE] Error in creating 3D sky box entity (%i)", iEnt)
		}
		else
		{
			new const szClassName[] = "3dskybox"

			set_entvar(iEnt, var_classname, szClassName)
			set_entvar(iEnt, var_solid, SOLID_NOT)
			set_entvar(iEnt, var_movetype, MOVETYPE_FLY)
			set_entvar(iEnt, var_body, i3DSkyBody)
			set_entvar(iEnt, var_skin, i3DSkySkin)
			set_entvar(iEnt, var_sequence, 0)
			set_entvar(iEnt, var_framerate, 1.0)
			set_entvar(iEnt, var_effects, EF_BRIGHTLIGHT | EF_DIMLIGHT)
			set_entvar(iEnt, var_light_level, 10.0)
			set_entvar(iEnt, var_flags, FL_PARTIALGROUND)
			entity_set_model(iEnt, sz3DSkyModel)

			x_i3DSkyEnt = iEnt

			// FakeMeta.
			register_forward(FM_AddToFullPack, "fw_AddtoFullPack_Post", 1)
			register_forward(FM_CheckVisibility, "fw_CheckVisibility_Pre")
		}
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

	if (x_i3DSkyEnt)
	{
		set_cvar_num("sv_zmax", 524288)
		set_cvar_string("sv_skyname", "")
	}
}

public fw_AddtoFullPack_Post(es, e, iEnt, iHost, iFlags, player, pSet)
{
	if (x_i3DSkyEnt)
	{
		if (iEnt == x_i3DSkyEnt)
		{
			static Float:vOrigin[3]
			get_entvar(iHost, var_origin, vOrigin);
			vOrigin[2] -= 1000.0
			set_es(es, ES_Origin, vOrigin);
			vOrigin = NULL_VECTOR
		}
	}
}

public fw_CheckVisibility_Pre(const iEnt, pSet)
{
	if (x_i3DSkyEnt)
	{
		if (iEnt == x_i3DSkyEnt)
		{
			forward_return(FMV_CELL, 1)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}