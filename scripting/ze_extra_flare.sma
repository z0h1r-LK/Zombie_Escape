#include <amxmodx>
#include <reapi>

#include <ze_core>

// Item Info.
stock const ZE_ITEM_NAME[] = "Flare Nade"
stock const ZE_ITEM_COST = 10
stock const ZE_ITEM_LIMIT = 0

// SmokeGrenade: Ammo ID.
const ammo_smokegrenade = 13

// Purchase sound.
new const g_szAmmoSound[] = "items/9mmclip1.wav"
new const g_szPurchaseSound[] = "items/gunpickup2.wav"

// Variable.
new g_iItemID,
	g_msgAmmoPickup,
	bool:g_bEnabled

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Extra Item: Flare Nade", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_num(register_cvar("ze_extra_flare", "1"), g_bEnabled)

	// New Item's.
	g_iItemID = ze_item_register(ZE_ITEM_NAME, ZE_ITEM_COST, ZE_ITEM_LIMIT)

	// Initial Value.
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}

public ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu)
{
	if (iItem != g_iItemID)
		return ZE_ITEM_AVAILABLE

	// Item not Allowed for Zombies!
	if (ze_is_user_zombie(id))
		return ZE_ITEM_DONT_SHOW

	// Item disabled?
	if (!g_bEnabled)
		return ZE_ITEM_DONT_SHOW

	// Item not Allowed for Humans.
	return ZE_ITEM_AVAILABLE
}

public ze_select_item_post(id, iItem, bool:bIgnoreCost)
{
	// Wrong Item?
	if (iItem != g_iItemID)
		return

	new const iAmount = rg_get_user_bpammo(id, WEAPON_SMOKEGRENADE)

	// Give SG for player.
	if (iAmount)
	{
		rg_set_user_bpammo(id, WEAPON_SMOKEGRENADE, iAmount + 1)

		// Purchase ammo (HUD/Sound).
		send_MsgAmmoX(id, ammo_smokegrenade, 1)
		rg_send_audio(id, g_szAmmoSound, PITCH_NORM)
	}
	else
	{
		// Give player SG.
		rg_give_item(id, "weapon_smokegrenade", GT_APPEND)

		// Play pick up sound.
		rg_send_audio(id, g_szPurchaseSound, PITCH_NORM)
	}
}

/**
 * -=| Function |=-
 */
send_MsgAmmoX(const id, ammo_id, amount)
{
	if (id == 0)
		return

	message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
	write_byte(ammo_id) // Ammo ID.
	write_byte(amount) // Amount.
	message_end()
}