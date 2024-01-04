#include <amxmodx>

#include <ze_core>

// Array.
new g_iLimit[MAX_PLAYERS+1][ZE_MAX_ITEMS]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Items: Limit", ZE_VERSION, ZE_AUTHORS)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]))
}

public ze_game_started()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		arrayset(g_iLimit[id], 0, sizeof(g_iLimit[]))
	}
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	new const iLimit = ze_item_get_limit(iItem)

	if (iLimit > 0)
	{
		if (bInMenu)
		{
			ze_item_add_text("\r[%d/%d]", g_iLimit[id][iItem], iLimit)
		}

		if (g_iLimit[id][iItem] >= iLimit)
		{
			if (!bInMenu)
			{
				ze_colored_print(id, "%L", LANG_PLAYER, "MSG_LIMIT_REACHED")
			}

			return ZE_ITEM_UNAVAILABLE
		}
	}

	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, iItem)
{
	new const iLimit = ze_item_get_limit(iItem)

	if (iLimit > 0)
	{
		g_iLimit[id][iItem]++
	}
}