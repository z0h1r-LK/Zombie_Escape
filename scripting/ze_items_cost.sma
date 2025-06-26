#include <amxmodx>

#include <ze_core>

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Items: Cost", ZE_VERSION, ZE_AUTHORS)
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	if (!bIgnoreCost)
	{
		new const iCost = ze_item_get_cost(iItem)

		if (iCost > 0)
		{
			if (iCost > ze_get_user_coins(id))
			{
				if (!bInMenu)
				{
					ze_colored_print(id, "%L", LANG_PLAYER, "MSG_NO_COINS_ENOUGH")
				}

				return ZE_ITEM_UNAVAILABLE
			}
		}
	}

	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, iItem, bool:bIgnoreCost)
{
	if (!bIgnoreCost)
	{
		new const iCost = ze_item_get_cost(iItem)

		if (iCost > 0)
		{
			ze_set_user_coins(id, ze_get_user_coins(id) - iCost)
			ze_show_coins_message(id, "%L", LANG_PLAYER, "MSG_ITEM_PURCHASED", iCost)
		}
	}
}