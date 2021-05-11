#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <gangs>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#tryinclude <gamecms_system>
#define REQUIRE_PLUGIN

enum struct enum_Item
{
	int Bank;
	int SellMode;
	int Price;
	float Modifier;
	int MaxLvl;
	int NoVip;
	int ProcentSell;
	int Notification;
}

#define PerkName    "fast_reload"

enum_Item g_Item;
int g_iPerkLvl[MAXPLAYERS + 1] = -1;
bool g_bOnlyTerrorist;
bool g_bGangCoreExist = false;
bool g_bGameCMSSystemExist = false;
 
public void OnAllPluginsLoaded()
{
	g_bGangCoreExist = LibraryExists("gangs");
	g_bGameCMSSystemExist = LibraryExists("gamecms_system");
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = false;
	if (StrEqual(name, "gamecms_system"))
		g_bGameCMSSystemExist = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = true;
	if (StrEqual(name, "gamecms_system"))
		g_bGameCMSSystemExist = true;
}

public Plugin myinfo =
{
	name = "[GANGS MODULE] Fast reload",
	author = "baferpro",
	version = GANGS_VERSION
};

public void Gangs_OnLoaded()
{
	Handle g_hCvar = FindConVar("sm_gangs_terrorist_only");
	if (g_hCvar != INVALID_HANDLE)
		g_bOnlyTerrorist = GetConVarBool(g_hCvar);
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToPerkMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter)
{
	g_iPerkLvl[iClient] = g_iPerkLvl[Inviter];
}

public void Gangs_OnExitFromGang(int iClient)
{
	g_iPerkLvl[iClient] = -1;
}

public Action AddToPerkMenu(Handle timer)
{
	Gangs_AddToPerkMenu(PerkName, FAST_RELOAD_CallBack, true);
}

public void OnClientDisconnect(int iClient)
{
	g_iPerkLvl[iClient] = 0;
}

public void OnClientPutInServer(int iClient)
{
	if(g_bGangCoreExist)
		CreateTimer(2.0, LoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
	else CreateTimer(5.0, ReLoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action LoadPerkLvl(Handle hTimer, int iUserID)
{
	int iClient = iUserID;
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		char sGangName[256];
		Gangs_GetClientGangName(iClient, sGangName, sizeof(sGangName));
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", PerkName, sGangName, Gangs_GetServerID());
		Database hDatabase = Gangs_GetDatabase();
		hDatabase.Query(SQLCallback_GetPerkLvl, sQuery, iClient);
		delete hDatabase;
	}
}

public Action ReLoadPerkLvl(Handle hTimer, int iUserID)
{
	OnClientPutInServer(iUserID);
}

public void SQLCallback_GetPerkLvl(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError(error);
		return;
	}

	int iClient = data;

	if (!IsValidClient(iClient))
	{
		return;
	}

	if (results.FetchRow())
	{
		g_iPerkLvl[iClient] = results.FetchInt(0);
	}
	
	if(g_iPerkLvl[iClient] == -1)
	{
		OnClientPutInServer(iClient);
	}
}

public void OnPluginEnd()
{
	if(g_bGangCoreExist)
		Gangs_DeleteFromPerkMenu(PerkName);
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	int iEntities = GetMaxEntities();
	for(int i=MaxClients+1;i<=iEntities;i++)
	{
		// Hook shotguns.
		if(IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_reloadState"))
		{
			SDKHook(i, SDKHook_ReloadPost, Hook_OnReloadPost);
		}
	}
	
	KFG_load();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
	Gangs_OnLoaded();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Hook shotguns - they reload differently.
	if(HasEntProp(entity, Prop_Send, "m_reloadState"))
		SDKHook(entity, SDKHook_ReloadPost, Hook_OnReloadPost);
}

public void Hook_OnReloadPost(int weapon, bool bSuccessful)
{
	int iClient = Weapon_GetOwner(weapon);
	if(iClient <= 0)
		return;
		
	if(g_bOnlyTerrorist && GetClientTeam(iClient) != 2)
		return;
	
	if(GetEntProp(weapon, Prop_Send, "m_reloadState") != 2)
		return;
	
	if(IsFakeClient(iClient) || !Gangs_ClientHasGang(iClient) || g_iPerkLvl[iClient]<1)
		return;
	
	float fReloadIncrease = 1.0 / (1.0 + g_Item.Modifier);
	
	float fIdleTime = GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle");
	float fGameTime = GetGameTime();
	float fIdleTimeNew = (fIdleTime - fGameTime) * fReloadIncrease + fGameTime;

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", fIdleTimeNew);
}

public Action OnPlayerRunCmd(int iClient, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static bool ClientIsReloading[MAXPLAYERS+1];
	if(!IsClientInGame(iClient))
		return Plugin_Continue;

	char sWeapon[64];
	int iWeapon = Client_GetActiveWeaponName(iClient, sWeapon, sizeof(sWeapon));
	if(iWeapon == INVALID_ENT_REFERENCE)
		return Plugin_Continue;
	
	bool bIsReloading = Weapon_IsReloading(iWeapon);
	if(!bIsReloading && HasEntProp(iWeapon, Prop_Send, "m_reloadState") && GetEntProp(iWeapon, Prop_Send, "m_reloadState") > 0)
		bIsReloading = true;
	
	if(bIsReloading && !ClientIsReloading[iClient])
	{
		IncreaseReloadSpeed(iClient);
	}
	
	ClientIsReloading[iClient] = bIsReloading;
	
	return Plugin_Continue;
}

void IncreaseReloadSpeed(int iClient)
{
	if(IsFakeClient(iClient) || !Gangs_ClientHasGang(iClient) || g_iPerkLvl[iClient]<1)
		return;
	
	char sWeapon[64];
	int iWeapon = Client_GetActiveWeaponName(iClient, sWeapon, sizeof(sWeapon));
	
	if(iWeapon == INVALID_ENT_REFERENCE)
		return;
	
	bool bIsShotgun = HasEntProp(iWeapon, Prop_Send, "m_reloadState");
	if(bIsShotgun)
	{
		int iReloadState = GetEntProp(iWeapon, Prop_Send, "m_reloadState");
		if(iReloadState == 0)
			return;
	}
	
	float fNextAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	float fGameTime = GetGameTime();
	
	float fReloadIncrease = 1.0 / (1.0 + g_Item.Modifier);
	
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 1.0 / fReloadIncrease);
	
	int iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	if(iViewModel != INVALID_ENT_REFERENCE)
		SetEntPropFloat(iViewModel, Prop_Send, "m_flPlaybackRate", 1.0 / fReloadIncrease);
	
	float fNextAttackNew = (fNextAttack - fGameTime) * fReloadIncrease;
	
	if(bIsShotgun)
	{
		DataPack hData;
		CreateDataTimer(0.01, Timer_CheckShotgunEnd, hData, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		hData.WriteCell(EntIndexToEntRef(iWeapon));
		hData.WriteCell(GetClientUserId(iClient));
	}
	else
	{
		DataPack hData;
		CreateDataTimer(fNextAttackNew, Timer_ResetPlaybackRate, hData, TIMER_FLAG_NO_MAPCHANGE);
		hData.WriteCell(EntIndexToEntRef(iWeapon));
		hData.WriteCell(GetClientUserId(iClient));
	}
	
	fNextAttackNew += fGameTime;
	SetEntPropFloat(iWeapon, Prop_Send, "m_flTimeWeaponIdle", fNextAttackNew);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fNextAttackNew);
	SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", fNextAttackNew);
}

public Action Timer_CheckShotgunEnd(Handle timer, DataPack data)
{
	data.Reset();
	
	int iWeapon = EntRefToEntIndex(data.ReadCell());
	int iClient = GetClientOfUserId(data.ReadCell());
	
	if(iWeapon == INVALID_ENT_REFERENCE)
	{
		if(iClient > 0)
			ResetClientViewModel(iClient);
		return Plugin_Stop;
	}
	
	int iOwner = Weapon_GetOwner(iWeapon);
	if(iOwner <= 0)
	{
		if(iClient > 0)
			ResetClientViewModel(iClient);
		
		SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 1.0);
		
		return Plugin_Stop;
	}

	int iReloadState = GetEntProp(iWeapon, Prop_Send, "m_reloadState");
	
	if(iReloadState > 0)
		return Plugin_Continue;
	
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 1.0);
	
	
	if(iClient > 0)
		ResetClientViewModel(iClient);
	
	return Plugin_Stop;
}

public Action Timer_ResetPlaybackRate(Handle timer, DataPack data)
{
	data.Reset();
	
	int iWeapon = EntRefToEntIndex(data.ReadCell());
	int iClient = GetClientOfUserId(data.ReadCell());
	
	if(iWeapon != INVALID_ENT_REFERENCE)	
		SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 1.0);
	
	if(iClient > 0)
		ResetClientViewModel(iClient);
	
	return Plugin_Stop;
}

public void OnMapStart()
{
	KFG_load();
}

public void FAST_RELOAD_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	if(g_iPerkLvl[iClient] > -1)
		ShowMenuModule(iClient);
	else
		PrintToChat(iClient, "Error load lvl, reconnect");
}

void ShowMenuModule(int iClient)
{
	char sTitle[256]; int ClientCash;
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
	Format(sTitle, sizeof(sTitle), "%T [%i/%i]", "fast_reload", iClient, g_iPerkLvl[iClient], g_Item.MaxLvl);
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
	if(g_Item.ProcentSell==-1)
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
			//int LvlCount = 1;
			char sGangName1[256], sGangName2[256];
			Gangs_GetClientGangName(iClient, sGangName1, sizeof(sGangName1));
			if(StrEqual(sInfo, "buy"))
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						Gangs_GetClientGangName(i, sGangName2, sizeof(sGangName2));
						if (StrEqual(sGangName1, sGangName2))
							g_iPerkLvl[i]+=1;
					}
				}
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gangs_perks SET %s=%i WHERE gang='%s' AND server_id=%i;", PerkName, g_iPerkLvl[iClient], sGangName1, Gangs_GetServerID());
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
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						Gangs_GetClientGangName(i, sGangName2, sizeof(sGangName2));
						if (StrEqual(sGangName1, sGangName2))
							g_iPerkLvl[i]-=1;
					}
				}
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gangs_perks SET %s=%i WHERE gang='%s' AND server_id=%i;", PerkName, g_iPerkLvl[iClient], sGangName1, Gangs_GetServerID());
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
			if(iItem == MenuCancel_ExitBack)
				Gangs_ShowPerksMenu(iClient);
	}
}

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("GANGS_MODULE");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_fast_reload.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][FastReload] - Configuration file not found");
	kfg.Rewind();
	g_Item.Bank = kfg.GetNum("bank");
	g_Item.SellMode = kfg.GetNum("sell_mode");
	g_Item.Price = kfg.GetNum("price");
	g_Item.Modifier = kfg.GetFloat("modifier");
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
	if (db == null)
	{
		LogError("Error (%i): %s", data, error);
	}
}

stock void ResetClientViewModel(int iClient)
{
	int iViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	if(iViewModel != INVALID_ENT_REFERENCE)
		SetEntPropFloat(iViewModel, Prop_Send, "m_flPlaybackRate", 1.0);
}