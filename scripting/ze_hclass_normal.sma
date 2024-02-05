#include <amxmodx>

#include <ze_core>
#include <ze_class_human>

public plugin_precache()
{
	new const szHumanName[] = "Regular"
	new const szHumanDesc[] = "-= Solider =-"
	new const szHumanModel[] = "sas"
	const Float:flHumanHealth = 250.0
	const Float:flHumanArmor = 0.0
	const bool:bHumanSpeedFactor = true
	const Float:flHumanSpeed = 25.0
	const Float:flHumanGravity = 800.0

	// Registers new Class.
	ze_hclass_register(szHumanName, szHumanDesc, szHumanModel, flHumanHealth, flHumanArmor, bHumanSpeedFactor, flHumanSpeed, flHumanGravity)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Class: Solider", ZE_VERSION, ZE_AUTHORS)
}