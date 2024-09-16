#include <amxmodx>
#include <ze_core>
#include <ze_levels>
#define LIBRARY_LEVELS "ze_levels"

public plugin_natives()
{
	set_module_filter("fw_module_filter")
	set_native_filter("fw_native_filter")
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equali(module, LIBRARY_LEVELS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Items: Level", ZE_VERSION, ZE_AUTHORS)
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	new const iReqLevel = ze_item_get_level(iItem)

	if (iReqLevel > 0)
	{
		new const iLevel = ze_get_user_level(id)

		if (iLevel < iReqLevel)
		{
			if (bInMenu)
			{
				ze_item_add_text("\d[\r%L\d: \y%d\d]", LANG_PLAYER, "MENU_LEVEL", iReqLevel)
			}
			else
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "MSG_LVL_NOT_ENOUGH")
			}

			return ZE_ITEM_UNAVAILABLE
		}
	}

	return ZE_ITEM_AVAILABLE
}