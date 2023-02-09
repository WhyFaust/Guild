#pragma newdecls required

#include <gangs>
#include <sdkhooks>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#tryinclude <gamecms_system>
#define REQUIRE_PLUGIN

#define PerkName    "vampirism"

enum struct enum_Item
{
	int Bank;
	int SellMode;
	int Price;
	int Mode;
	int Procent;
	int HP;
	int MaxHP;
	float TimeGetHP;
	int MaxLvl;
	int NoVip;
	int ProcentSell;
	int Notification;
}
enum_Item g_Item;
int g_iPerkLvl[MAXPLAYERS + 1] = -1, m_iHealth;
bool g_bOnlyTerrorist;
int g_iMaxHP[MAXPLAYERS+1];

bool g_bVipCoreExist = false;
bool g_bGangCoreExist = false;
bool g_bGameCMSSystemExist = false;
 
public void OnAllPluginsLoaded()
{
	g_bVipCoreExist = LibraryExists("vip_core");
	g_bGangCoreExist = LibraryExists("gangs");
	g_bGameCMSSystemExist = LibraryExists("gamecms_system");
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "vip_core"))
		g_bVipCoreExist = false;
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = false;
	if (StrEqual(name, "gamecms_system"))
		g_bGameCMSSystemExist = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "vip_core"))
		g_bVipCoreExist = true;
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = true;
	if (StrEqual(name, "gamecms_system"))
		g_bGameCMSSystemExist = true;
}

public Plugin myinfo =
{
	name = "[GANGS MODULE] Vampirism",
	author = "Faust",
	version = GANGS_VERSION,
	url = "Faust#8073"
}

public void Gangs_OnPlayerLoaded(int iClient)
{
	if(IsValidClient(iClient))
		LoadPerkLvl(iClient);
}

public void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter)
{
	if(iClient != Inviter)
		g_iPerkLvl[iClient] = g_iPerkLvl[Inviter];
	else
		LoadPerkLvl(iClient)
}

public void Gangs_OnExitFromGang(int iClient)
{
	g_iPerkLvl[iClient] = -1;
}

public void OnClientDisconnect(int iClient)
{
	g_iPerkLvl[iClient] = -1;
	if(!g_Item.Mode)
		SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientPutInServer(int iClient) 
{
	if(!g_Item.Mode)
		SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void LoadPerkLvl(int iClient)
{
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		int iGangID = Gangs_GetClientGangId(iClient);
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT %s \
										FROM gang_perk \
										WHERE gang_id = %i;", 
										PerkName, iGangID);
		Database hDatabase = Gangs_GetDatabase();
		hDatabase.Query(SQLCallback_GetPerkLvl, sQuery, iClient);
		delete hDatabase;
	}
}

public void SQLCallback_GetPerkLvl(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_GetPerkLvl] Error (%i): %s", iClient, error);
		return;
	}

	if (!IsValidClient(iClient))
		return;

	if (results.FetchRow())
		g_iPerkLvl[iClient] = results.FetchInt(0);
}

public void OnPluginEnd()
{
	if(g_bGangCoreExist)
		Gangs_DeleteFromPerkMenu(PerkName);
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin works only on CS:GO");

	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");

	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");

	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);

	KFG_load();
}

public void OnMapStart()
{
	KFG_load();
}

public void Gangs_OnLoaded()
{
	Handle g_hCvar = FindConVar("sm_gangs_terrorist_only");
	if (g_hCvar != INVALID_HANDLE)
		g_bOnlyTerrorist = GetConVarBool(g_hCvar);
	AddToPerkMenu();
}

public void AddToPerkMenu()
{
	Gangs_AddToPerkMenu(PerkName, VAMPIRISM_CallBack, true);
}

public void VAMPIRISM_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	if(g_iPerkLvl[iClient] > -1)
		ShowMenuModule(iClient);
	else
		PrintToChat(iClient, "Error load lvl, reconnect");
}

void ShowMenuModule(int iClient)
{
	char sTitle[256];
	int ClientCash;
	if(g_Item.Bank)
	{
		switch(g_Item.SellMode)
		{
			case 0:
				ClientCash = Gangs_GetBankClientCash(iClient, "rubles");
			case 1:
				ClientCash = Gangs_GetBankClientCash(iClient, "shop");
			case 2:
				ClientCash = Gangs_GetBankClientCash(iClient, "shopgold");
			case 3:
				ClientCash = Gangs_GetBankClientCash(iClient, "wcsgold");
			case 4:
				ClientCash = Gangs_GetBankClientCash(iClient, "lkrubles");
			case 5:
				ClientCash = Gangs_GetBankClientCash(iClient, "myjb");
		}
	}
	else
	{
		switch(g_Item.SellMode)
		{
			case 0:
				ClientCash = Gangs_GetClientCash(iClient, "rubles");
			case 1:
				ClientCash = Gangs_GetClientCash(iClient, "shop");
			case 2:
				ClientCash = Gangs_GetClientCash(iClient, "shopgold");
			case 3:
				ClientCash = Gangs_GetClientCash(iClient, "wcsgold");
			case 4:
				ClientCash = Gangs_GetClientCash(iClient, "lkrubles");
			case 5:
				ClientCash = Gangs_GetClientCash(iClient, "myjb");
		}
	}
	Format(sTitle, sizeof(sTitle), "%T [%i/%i]", "vampirism", iClient, g_iPerkLvl[iClient], g_Item.MaxLvl);
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.SetTitle(sTitle);
	hMenu.ExitBackButton = true;
	char sItem[128];
	switch(g_Item.SellMode)
	{
		case 0:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "rubles", iClient);
		case 1:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "shop", iClient);
		case 2:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "shopgold", iClient);
		case 3:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "wcsgold", iClient);
		case 4:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "lkrubles", iClient);
		case 5:
			Format(sItem, sizeof(sItem), "%T [%i %T]", "buy", iClient, g_Item.Price, "myjb", iClient);
	}
	hMenu.AddItem("buy", sItem, (ClientCash >= g_Item.Price && g_iPerkLvl[iClient] < g_Item.MaxLvl) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	if(g_Item.ProcentSell == -1)
	{
		Format(sItem, sizeof(sItem), "%T", "sell", iClient);
		hMenu.AddItem("sell", sItem, (g_iPerkLvl[iClient] > 0 && Gangs_GetClientGangRank(iClient) == 0) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_MainMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
        {
			char sInfo[16];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			int iGangID = Gangs_GetClientGangId(iClient);
			if(StrEqual(sInfo, "buy"))
			{
				g_iPerkLvl[iClient] += 1;
				for (int i = 1; i <= MaxClients; i++)
					if (IsValidClient(i))
						if (iGangID == Gangs_GetClientGangId(i))
							g_iPerkLvl[i] = g_iPerkLvl[iClient];

				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gang_perk \
												SET %s = %i \
												WHERE gang_id = %i;", 
												PerkName, g_iPerkLvl[iClient], iGangID);
				Database hDatabase = Gangs_GetDatabase();
				hDatabase.Query(SQLCallback_Void, sQuery);
				delete hDatabase;
				
				if(g_Item.Bank)
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_TakeBankClientCash(iClient, "rubles", g_Item.Price);
						case 1:
							Gangs_TakeBankClientCash(iClient, "shop", g_Item.Price);
						case 2:
							Gangs_TakeBankClientCash(iClient, "shopgold", g_Item.Price);
						case 3:
							Gangs_TakeBankClientCash(iClient, "wcsgold", g_Item.Price);
						case 4:
							Gangs_TakeBankClientCash(iClient, "lkrubles", g_Item.Price);
						case 5:
							Gangs_TakeBankClientCash(iClient, "myjb", g_Item.Price);
					}
				}
				else
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_TakeClientCash(iClient, "rubles", g_Item.Price);
						case 1:
							Gangs_TakeClientCash(iClient, "shop", g_Item.Price);
						case 2:
							Gangs_TakeClientCash(iClient, "shopgold", g_Item.Price);
						case 3:
							Gangs_TakeClientCash(iClient, "wcsgold", g_Item.Price);
						case 4:
							Gangs_TakeClientCash(iClient, "lkrubles", g_Item.Price);
						case 5:
							Gangs_TakeClientCash(iClient, "myjb", g_Item.Price);
					}
				}
				if(g_Item.Notification && g_bGameCMSSystemExist)
				{
					char sMessage[256], sProfileName[128];
					GameCMS_GetClientName(iClient, sProfileName, sizeof(sProfileName));
					Format(sMessage, sizeof(sMessage), "%s, поздравляем с успешной покупкой %T", sProfileName, PerkName, iClient);
					GameCMS_SendNotification(iClient, sMessage);
				}
				ShowMenuModule(iClient);
			}
			else if(StrEqual(sInfo, "sell"))
			{
				g_iPerkLvl[iClient] -= 1;
				for (int i = 1; i <= MaxClients; i++)
					if (IsValidClient(i))
						if (iGangID == Gangs_GetClientGangId(i))
							g_iPerkLvl[i] = g_iPerkLvl[iClient];

				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gang_perk \
												SET %s = %i \
												WHERE gang_id = %i;", 
												PerkName, g_iPerkLvl[iClient], iGangID);
				Database hDatabase = Gangs_GetDatabase();
				hDatabase.Query(SQLCallback_Void, sQuery);
				delete hDatabase;
				int NewPrice = RoundToFloor(float(g_Item.Price)*(float(g_Item.ProcentSell)/100.0));
				if(g_Item.Bank)
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_GiveBankClientCash(iClient, "rubles", NewPrice);
						case 1:
							Gangs_GiveBankClientCash(iClient, "shop", NewPrice);
						case 2:
							Gangs_GiveBankClientCash(iClient, "shopgold", NewPrice);
						case 3:
							Gangs_GiveBankClientCash(iClient, "wcsgold", NewPrice);
						case 4:
							Gangs_GiveBankClientCash(iClient, "lkrubles", NewPrice);
						case 5:
							Gangs_GiveBankClientCash(iClient, "myjb", NewPrice);
					}
				}
				else
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_GiveClientCash(iClient, "rubles", NewPrice);
						case 1:
							Gangs_GiveClientCash(iClient, "shop", NewPrice);
						case 2:
							Gangs_GiveClientCash(iClient, "shopgold", NewPrice);
						case 3:
							Gangs_GiveClientCash(iClient, "wcsgold", NewPrice);
						case 4:
							Gangs_GiveClientCash(iClient, "lkrubles", NewPrice);
						case 5:
							Gangs_GiveClientCash(iClient, "myjb", NewPrice);
					}
				}
				ShowMenuModule(iClient);
			}
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
				Gangs_ShowPerksMenu(iClient);
		}
	}
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i)) 
			CreateTimer(g_Item.TimeGetHP, TIMER_PlayerSpawn, i);
} 

public Action TIMER_PlayerSpawn(Handle timer, int iClient)
{
	g_iMaxHP[iClient] = GetEntData(iClient, m_iHealth);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(g_Item.Mode)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
		if (IsValidClient(attacker) && Gangs_ClientHasGang(attacker) && attacker != victim)
		{
			if(g_bOnlyTerrorist && GetClientTeam(victim) != 3 && GetClientTeam(attacker) != 2)
				return;
			if(g_Item.NoVip && g_bVipCoreExist && VIP_IsClientVIP(attacker))
				return;
			
			int iHealth = GetEntData(attacker, m_iHealth) + g_Item.HP*g_iPerkLvl[attacker];
			if(g_Item.MaxHP > 0)
				if(iHealth > g_Item.MaxHP)
					iHealth = g_Item.MaxHP;
			if(g_Item.MaxHP == -1)
				if(iHealth > g_iMaxHP[attacker])
					iHealth = g_iMaxHP[attacker];
			SetEntData(attacker, m_iHealth, iHealth);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (IsValidClient(attacker) && IsValidClient(victim) && Gangs_ClientHasGang(attacker) && attacker != victim && GetClientTeam(attacker) != GetClientTeam(victim))
	{
		if(g_bOnlyTerrorist && GetClientTeam(victim) != 3 && GetClientTeam(attacker) != 2)
			return Plugin_Continue;
		if(g_Item.NoVip && g_bVipCoreExist && VIP_IsClientVIP(attacker))
			return Plugin_Continue;
		int iHealth = GetEntData(attacker, m_iHealth) + RoundFloat(damage * g_Item.Procent/100.0)*g_iPerkLvl[attacker];
		if(g_Item.MaxHP > 0)
			if(iHealth > g_Item.MaxHP)
				iHealth = g_Item.MaxHP;
		if(g_Item.MaxHP == -1)
			if(iHealth > g_iMaxHP[attacker])
				iHealth = g_iMaxHP[attacker];
		SetEntData(attacker, m_iHealth, iHealth);
	}

	return Plugin_Continue;
} 

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("GANGS_MODULE");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_vampirism.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Vampirism] - Configuration file not found");
	kfg.Rewind();
	g_Item.Bank = kfg.GetNum("bank");
	g_Item.SellMode = kfg.GetNum("sell_mode");
	g_Item.Price = kfg.GetNum("price");
	g_Item.Mode = kfg.GetNum("mode");
	g_Item.Procent = kfg.GetNum("procent");
	g_Item.HP = kfg.GetNum("hp");
	g_Item.MaxHP = kfg.GetNum("max_hp");
	g_Item.TimeGetHP = kfg.GetFloat("get_hp_timer");
	g_Item.MaxLvl = kfg.GetNum("max");
	g_Item.NoVip = kfg.GetNum("no_vip");
	g_Item.ProcentSell = kfg.GetNum("procent_sell");
	if(g_Item.ProcentSell > 100)
		g_Item.ProcentSell = 100;
	else if(g_Item.ProcentSell < 0)
		if(g_Item.ProcentSell == -1)
			g_Item.ProcentSell = -1;
		else
			g_Item.ProcentSell = 0;
	g_Item.Notification = kfg.GetNum("notification");
	delete kfg;
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_Void] Error (%i): %s", data, error);
	}
}