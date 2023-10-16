#include <amxmodx>
#include <reapi>
#include <ze_core>

enum _:iItems
{
	Frost = 0,
	Fire
}

// Purchase Ammo Sound.
new const g_szPurchaseSound[] = "items/9mmclip1.wav"

// Variable.
new g_msgAmmoPickup

// Array.
new g_iItem[iItems]

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Extra-Item: Grenades", ZE_VERSION, ZE_AUTHORS)

	// New Item's.
	g_iItem[Frost] = ze_item_register("Frost Nade", 10, 0)
	g_iItem[Fire] = ze_item_register("Fire Nade", 10, 0)

	// Set Value.
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	// We will prevent it on post-forward.
	if (iItem == g_iItem[Frost])
	{
		if (ze_is_user_zombie(id))
			return ZE_ITEM_DONT_SHOW
		return ZE_ITEM_AVAILABLE
	}
	else if (iItem == g_iItem[Fire])
	{
		if (ze_is_user_zombie(id))
			return ZE_ITEM_DONT_SHOW
		return ZE_ITEM_AVAILABLE
	}

	// Item allowed for Humans.
	return ZE_ITEM_UNAVAILABLE
}

public ze_select_item_post(id, iItem)
{
	if (iItem == g_iItem[Frost])
	{
		new iAmount = rg_get_user_bpammo(id, WEAPON_FLASHBANG)

		if (!iAmount)
		{
			rg_give_item(id, "weapon_flashbang", GT_APPEND)
		}
		else
		{
			send_AmmoPickup_Msg(id, 11, 1)
			rg_send_audio(id, g_szPurchaseSound, PITCH_NORM)
			rg_set_user_bpammo(id, WEAPON_FLASHBANG, iAmount + 1)
		}
	}
	else if (iItem == g_iItem[Fire])
	{
		new iAmount = rg_get_user_bpammo(id, WEAPON_HEGRENADE)

		if (!iAmount)
		{
			rg_give_item(id, "weapon_hegrenade", GT_APPEND)
		}
		else
		{
			send_AmmoPickup_Msg(id, 12, 1)
			rg_send_audio(id, g_szPurchaseSound, PITCH_NORM)
			rg_set_user_bpammo(id, WEAPON_HEGRENADE, iAmount + 1)
		}
	}
}

/**
 * -=| Function |=-
 */
send_AmmoPickup_Msg(id, iAmmoId, iAmount)
{
	if (iAmount < 1)
		return 0

	// Send AmmoPickup message to client.
	message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, .player = id)
	write_byte(iAmmoId) // Ammo ID.
	write_byte(iAmount) // Amount.
	message_end()
	return 1
}