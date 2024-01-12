#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ze_class_survivor>
#define LIBRARY_NEMESIS "ze_class_nemesis"
#define LIBRARY_SURVIVOR "ze_class_survivor"

// Defines.
#define CLASS_ZOMBIE 0
#define CLASS_NEMESIS 1
#define CLASS_SURVIVOR 2

// Cvars.
new g_iEnable[3],
	g_iForce[3],
	Float:g_flHeight[3],
	Float:g_flCooldown[3]

// Variable.
new g_bitsFirstZombie

// Array.
new Float:g_flLastTime[MAX_PLAYERS+1]

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Long Jump", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_CBasePlayer_PreThink, "fw_PlayerPreThink")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_leap_zombie", "1"), g_iEnable[CLASS_ZOMBIE])
	bind_pcvar_num(register_cvar("ze_leap_zombie_force", "500"), g_iForce[CLASS_ZOMBIE])
	bind_pcvar_float(register_cvar("ze_leap_zombie_height", "300.0"), g_flHeight[CLASS_ZOMBIE])
	bind_pcvar_float(register_cvar("ze_leap_zombie_cooldown", "5.0"), g_flCooldown[CLASS_ZOMBIE])

	if (module_exists(LIBRARY_NEMESIS))
	{
		bind_pcvar_num(register_cvar("ze_leap_nemesis", "1"), g_iEnable[CLASS_NEMESIS])
		bind_pcvar_num(register_cvar("ze_leap_nemesis_force", "500"), g_iForce[CLASS_NEMESIS])
		bind_pcvar_float(register_cvar("ze_leap_nemesis_height", "300.0"), g_flHeight[CLASS_NEMESIS])
		bind_pcvar_float(register_cvar("ze_leap_nemesis_cooldown", "5.0"), g_flCooldown[CLASS_NEMESIS])
	}

	if (module_exists(LIBRARY_SURVIVOR))
	{
		bind_pcvar_num(register_cvar("ze_leap_survivor", "1"), g_iEnable[CLASS_SURVIVOR])
		bind_pcvar_num(register_cvar("ze_leap_survivor_force", "500"), g_iForce[CLASS_SURVIVOR])
		bind_pcvar_float(register_cvar("ze_leap_survivor_height", "300.0"), g_flHeight[CLASS_SURVIVOR])
		bind_pcvar_float(register_cvar("ze_leap_survivor_cooldown", "5.0"), g_flCooldown[CLASS_SURVIVOR])
	}
}

public ze_user_humanized(id)
{
	flag_unset(g_bitsFirstZombie, id)
}

public ze_zombie_appear(const iZombies[], iZombiesNum)
{
	for (new i = 0; i < iZombiesNum; i++)
	{
		flag_set(g_bitsFirstZombie, iZombies[i])
	}
}

public fw_PlayerPreThink(const id)
{
	// Player is not Alive?
	if (!is_user_alive(id))
		return

	static Float:flMaxSpeed
	get_entvar(id, var_maxspeed, flMaxSpeed)

	// Frozen?
	if (flMaxSpeed == 1.0)
		return

	// Is not doing Long Jump?
	if (!(get_entvar(id, var_button) & (IN_JUMP|IN_DUCK) == (IN_JUMP|IN_DUCK)))
		return

	// Get player's velocity.
	static Float:vSpeed[3]
	get_entvar(id, var_velocity, vSpeed)

	// Player not on ground or not enough speed?
	if (!(get_entvar(id, var_flags) & FL_ONGROUND) || vector_length(vSpeed) < 80.0)
		return

	static Float:flRefTime; flRefTime = get_gametime()

	// Cooldown time not over yet?
	if (g_flLastTime[id] > flRefTime)
		return

	static Float:flCooldown, Float:flHeight, iForce

	if (module_exists(LIBRARY_NEMESIS) && ze_is_user_nemesis(id))
	{
		if (!g_iEnable[CLASS_NEMESIS])
			return

		iForce = g_iForce[CLASS_ZOMBIE]
		flHeight = g_flHeight[CLASS_ZOMBIE]
		flCooldown = g_flCooldown[CLASS_ZOMBIE]
	}
	else if (module_exists(LIBRARY_SURVIVOR) && ze_is_user_survivor(id))
	{
		iForce = g_iForce[CLASS_SURVIVOR]
		flHeight = g_flHeight[CLASS_SURVIVOR]
		flCooldown = g_flCooldown[CLASS_SURVIVOR]
	}
	else
	{
		// Player is Zombie?
		if (!ze_is_user_zombie(id))
			return

		switch (g_iEnable[CLASS_ZOMBIE])
		{
			case 1: // All.
			{
				iForce = g_iForce[CLASS_ZOMBIE]
				flHeight = g_flHeight[CLASS_ZOMBIE]
				flCooldown = g_flCooldown[CLASS_ZOMBIE]
				goto LEAP
			}
			case 2: // First Zombie.
			{
				if (flag_get_boolean(g_bitsFirstZombie, id))
				{
					iForce = g_iForce[CLASS_ZOMBIE]
					flHeight = g_flHeight[CLASS_ZOMBIE]
					flCooldown = g_flCooldown[CLASS_ZOMBIE]
					goto LEAP
				}
			}
			case 3: // Last Zombie.
			{
				if (ze_is_last_zombie() == id)
				{
					iForce = g_iForce[CLASS_ZOMBIE]
					flHeight = g_flHeight[CLASS_ZOMBIE]
					flCooldown = g_flCooldown[CLASS_ZOMBIE]
					goto LEAP
				}
			}
		}

		return
	}

	LEAP:

	// Make velocity vector
	velocity_by_aim(id, iForce, vSpeed)

	// Set custom height
	vSpeed[2] = flHeight

	// Apply the new velocity
	set_entvar(id, var_velocity, vSpeed)

	// Cooldown time.
	g_flLastTime[id] = flRefTime + flCooldown
}