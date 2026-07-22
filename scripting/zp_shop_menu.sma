#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_x/zp_packs_system>
#include <zombie_plague_x/zp_points_system>
#include <zombie_plague_x/zombie_plague_x>

#define PLUGIN "[ZP] Packs Shop"
#define VERSION "1.0"
#define AUTHOR "DadoDz"

#define COST_PACKS_150 200
#define COST_PACKS_350 375
#define COST_PACKS_500 550
#define COST_PACKS_750 825
#define COST_PACKS_1000 1150

#define REWARD_PACKS_150 150
#define REWARD_PACKS_350 350
#define REWARD_PACKS_500 500
#define REWARD_PACKS_750 750
#define REWARD_PACKS_1000 1000

#define SHOP_OPEN_START 22
#define SHOP_OPEN_END 10

#define BUY_SOUND "items/tr_kevlar.wav"

const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_0
const PACK_TIERS = 5

new bool:g_BoughtPack[33][PACK_TIERS];

new g_MsgSync;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_MsgSync = CreateHudSyncObj()

	register_menu("Packs Shop", KEYSMENU, "menu_shop")

	register_clcmd("say /packs", "cmd_show_packs_shop")
	register_clcmd("say packs", "cmd_show_packs_shop")
	register_clcmd("say /shop", "cmd_show_packs_shop")
	register_clcmd("say shop", "cmd_show_packs_shop")
}

public plugin_natives() register_native("show_menu_shop", "show_menu_shop", 1);

public cmd_show_packs_shop(id)
{
	show_menu_shop(id)
	return PLUGIN_HANDLED;
}

public show_menu_shop(id)
{
	if (!is_user_connected(id))
		return;

	if (!is_shop_open())
	{
		client_print_color(id, print_team_default, "^x04[^x01ZP^x04]^x01 Packs^x03 Shop^x01 is available^x04 only^x01 from^x03 22:00^x01 to^x03 10:00^x01.")
		return;
	}

	static menu[512], len;
	len = 0;

	len += formatex(menu[len], charsmax(menu) - len, "\r[\yPacks Shop\r]^n^n")

	AddPackItem(menu, charsmax(menu), len, id, 0, REWARD_PACKS_150, COST_PACKS_150)
	AddPackItem(menu, charsmax(menu), len, id, 1, REWARD_PACKS_350, COST_PACKS_350)
	AddPackItem(menu, charsmax(menu), len, id, 2, REWARD_PACKS_500, COST_PACKS_500)
	AddPackItem(menu, charsmax(menu), len, id, 3, REWARD_PACKS_750, COST_PACKS_750)
	AddPackItem(menu, charsmax(menu), len, id, 4, REWARD_PACKS_1000, COST_PACKS_1000)

	len += formatex(menu[len], charsmax(menu) - len, "^n\r[\y0\r]\w Exit")

	if (pev_valid(id) == 2)
		set_pdata_int(id, 205, 0, 5)

	show_menu(id, KEYSMENU, menu, -1, "Packs Shop")
}

public menu_shop(id, key)
{
	if (!is_user_connected(id) || key == 9)
		return PLUGIN_HANDLED;

	if (!is_shop_open())
	{
		client_print_color(id, print_team_default, "^x04[^x01ZP^x04]^x01 Packs Shop is available only from ^x0322:00^x01 to ^x0310:00^x01.")
		return PLUGIN_HANDLED;
	}

	set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.85, 0, 6.0, 2.25, 0.1, 0.2, -1)

	switch (key)
	{
		case 0: buy_packs(id, 0, COST_PACKS_150, REWARD_PACKS_150)
		case 1: buy_packs(id, 1, COST_PACKS_350, REWARD_PACKS_350)
		case 2: buy_packs(id, 2, COST_PACKS_500, REWARD_PACKS_500)
		case 3: buy_packs(id, 3, COST_PACKS_750, REWARD_PACKS_750)
		case 4: buy_packs(id, 4, COST_PACKS_1000, REWARD_PACKS_1000)
	}

	return PLUGIN_HANDLED;
}

buy_packs(id, item_id, points_cost, packs_reward)
{
	if (g_BoughtPack[id][item_id] == true)
	{
		client_print_color(id, print_team_default, "^x04[^x01ZP^x04]^x01 You can buy this^x03 item^x04 only^x03 once^x01 per^x03 map^x01.")
		return;
	}

	if (!take_points(id, points_cost))
		return;

	zp_set_user_packs(id, zp_get_user_packs(id) + packs_reward)
	g_BoughtPack[id][item_id] = true;

	client_cmd(id, "spk %s", BUY_SOUND)
	ShowSyncHudMsg(id, g_MsgSync, "* YOU BOUGHT %d PACKS *", packs_reward)
}

stock AddPackItem(menu[], maxlen, &len, id, item, reward, cost)
{
	new szBuffer[96];

	if (g_BoughtPack[id][item])
		formatex(szBuffer, charsmax(szBuffer), "\d[%d] %d Packs \r[\dSOLD\r]", item + 1, reward);
	else if (zp_get_user_points(id) >= cost)
		formatex(szBuffer, charsmax(szBuffer), "\r[\y%d\r]\w %d Packs \r[\y%d Points\r]", item + 1, reward, cost);
	else
		formatex(szBuffer, charsmax(szBuffer), "\d[%d] %d Packs \r[\y%d Points\r]", item + 1, reward, cost);
		
	len += formatex(menu[len], maxlen - len, "%s^n", szBuffer);
}

bool:is_shop_open()
{
	new hour[3];
	get_time("%H", hour, charsmax(hour))

	new current_hour = str_to_num(hour);
	return (current_hour >= SHOP_OPEN_START || current_hour < SHOP_OPEN_END)
}

bool:take_points(id, points_cost)
{
	if (zp_get_user_points(id) < points_cost)
	{
		client_print_color(id, print_team_default, "^x04[^x01ZP^x04]^x01 You dont have enough^x03 points^x01.")
		return false;
	}

	zp_set_user_points(id, zp_get_user_points(id) - points_cost)
	return true;
}
