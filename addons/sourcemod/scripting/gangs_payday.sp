#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <gangs>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#include <gamecms_system>
#define REQUIRE_PLUGIN

#define GLOBAL_INFO			g_iClientInfo[0]

#define SZF(%0) 			%0, sizeof(%0)
#define SZFA(%0,%1)         %0[%1], sizeof(%0[])

#define SET_BIT(%0,%1) 		%0 |= %1
#define UNSET_BIT(%0,%1) 	%0 &= ~%1

#define IS_STARTED					(1<<0)
#define IS_MySQL					(1<<1)
#define IS_LOADING					(1<<2)

int	g_iClientInfo[MAXPLAYERS+1];

enum struct enum_Item
{
	int Bank;
	int SellMode;
	int Price;
	int ProcentSell;
	int Notification;
	int ReqLvl;
	int Mode;
	int Time;
	int MaxLvl;
	int Modifier;
	int ModifierMode;
}

Database g_hDatabase;
Handle g_hTimer[MAXPLAYERS+1];
int g_iTimePlayer[MAXPLAYERS+1] = 0;

#define PerkName    "payday"

enum_Item g_Item;
int g_iPerkLvl[MAXPLAYERS + 1] = -1;
bool g_bGangCoreExist = false;

 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gangs"))
	{
		g_bGangCoreExist = true;
	}
}

public Plugin myinfo =
{
	name = "[GANGS MODULE] PayDay",
	author = "baferpro",
	version = GANGS_VERSION
};

public void OnAllPluginsLoaded()
{
	DB_OnPluginStart();
	g_bGangCoreExist = LibraryExists("gangs");
}

public void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter)
{
	g_iPerkLvl[iClient] = g_iPerkLvl[Inviter];
}

public void Gangs_OnExitFromGang(int iClient)
{
	g_iPerkLvl[iClient] = -1;
}

public void Gangs_OnLoaded()
{
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToPerkMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddToPerkMenu(Handle timer)
{
	Gangs_AddToPerkMenu(PerkName, PAYDAY_CallBack, true);
}

public void OnClientDisconnect(int iClient)
{
	g_iPerkLvl[iClient] = -1;
	if(g_hTimer[iClient])    // Проверяем что таймер активен
	{
		KillTimer(g_hTimer[iClient]);    // Уничтожаем таймер
		g_hTimer[iClient] = null;        // Обнуляем значения дескриптора
	}
	
	UpdateClientData(iClient);
}

public void UpdateClientData(int iClient)
{
	char sSteamID[64];
	GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "UPDATE payday_players SET time = %i WHERE steamid = '%s';", g_iTimePlayer[iClient], sSteamID);
	g_hDatabase.Query(SQLCallback_Void, sQuery, iClient);
	g_iTimePlayer[iClient] = 0;
}

public void OnClientPutInServer(int iClient)
{
	if(g_bGangCoreExist)
		CreateTimer(2.0, LoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
	else CreateTimer(5.0, ReLoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
	
	g_hTimer[iClient] = CreateTimer(60.0, TimeTimer, iClient, TIMER_REPEAT);
	
	GetClientData(iClient);
}

public Action RepeatGetClientData(Handle timer, int iClient)
{
	GetClientData(iClient);
}

public void GetClientData(int iClient)
{
	if (g_hDatabase == null) //connect not loaded - retry to give it time
	{
		CreateTimer(1.0, RepeatGetClientData, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		if(IsValidClient(iClient))
		{
			char sSteamID[64];
			GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT time FROM payday_players WHERE steamid = '%s';", sSteamID);
			g_hDatabase.Query(SQLCallback_GetClientData, sQuery, iClient);
		}
	}
}

public void SQLCallback_GetClientData(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_GetClientData] Error (%i): %s", data, error);
		return;
	}

	int iClient = data;

	if (!IsValidClient(iClient))
	{
		return;
	}
	if (results.RowCount == 0)
	{
		char sSteamID[64];
		GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
		
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "INSERT INTO payday_players (steamid) VALUES ('%s');", sSteamID);
		g_hDatabase.Query(SQLCallback_Void, sQuery, iClient);
	}
	else
	{
		results.FetchRow();
		g_iTimePlayer[iClient] = results.FetchInt(0);
	}
}

public Action TimeTimer(Handle hTimer, int iUserID)
{
	int iClient = iUserID;
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient) && g_iPerkLvl[iClient] > 0)
	{
		g_iTimePlayer[iClient]++;
		if(g_iTimePlayer[iClient] == g_Item.Time)
		{
			//ВЫДАЧА
			int iPrice = 0;
			if(g_Item.Mode)
			{
					char path[128];
					KeyValues kfg = new KeyValues("GANGS_MODULE");
					BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_payday.ini");
					if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][PayDay] - Configuration file not found");
					kfg.Rewind();
					
					if(kfg.JumpToKey("Ranks"))
					{
						char sRank[129];
						IntToString(Gangs_GetClientGangRank(iClient), sRank, sizeof(sRank));
						char szBuffer[256];
						kfg.GetString(sRank, szBuffer, sizeof(szBuffer));
						int iModifier = StringToInt(szBuffer);
						iPrice = iModifier*g_iPerkLvl[iClient];
					}
					
					delete kfg;
			}
			else
				iPrice = g_Item.Modifier*g_iPerkLvl[iClient];
				
			if(iPrice>0)
			{
				switch(g_Item.ModifierMode)
				{
					case 0:
					{
						Gangs_GiveClientCash(iClient, "rubles", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "rubles");
					}
					case 1:
					{
						Gangs_GiveClientCash(iClient, "shop", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "shop");
					}
					case 2:
					{
						Gangs_GiveClientCash(iClient, "shopgold", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "shopgold");
					}
					case 3:
					{
						Gangs_GiveClientCash(iClient, "wcsgold", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "wcsgold");
					}
					case 4:
					{
						Gangs_GiveClientCash(iClient, "lkrubles", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "lkrubles");
					}
					case 5:
					{
						Gangs_GiveClientCash(iClient, "myjb", iPrice);
						CPrintToChat(iClient, "%t %t", "Prefix", "PaydayGive", iPrice, "myjb");
					}
				}
			}
			//
			g_iTimePlayer[iClient] = 0;
			
			char sSteamID[64];
			GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
			
			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "UPDATE payday_players SET time = %i WHERE steamid = '%s';", g_iTimePlayer[iClient], sSteamID);
			g_hDatabase.Query(SQLCallback_Void, sQuery, iClient);
		}
	}
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

		Database db = Gangs_GetDatabase();
		db.Query(SQLCallback_GetPerkLvl, sQuery, iClient);
		delete db;
	}
}

public Action ReLoadPerkLvl(Handle hTimer, int iUserID)
{
	OnClientPutInServer(iUserID);
}

public void SQLCallback_GetPerkLvl(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_GetPerkLvl] Error (%i): %s", data, error);
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
	Gangs_DeleteFromPerkMenu(PerkName);
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	KFG_load();
}

public void OnMapStart()
{
	KFG_load();
}

public void PAYDAY_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	ShowMenuModule(iClient);
}

void ShowMenuModule(int iClient)
{
	char sTitle[256], sItem[128]; int ClientCash;
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
	Format(sTitle, sizeof(sTitle), "%T [%i/%i]", "payday", iClient, g_iPerkLvl[iClient], g_Item.MaxLvl);
	Menu hMenu = new Menu(MenuHandler_MainMenu);
	hMenu.SetTitle(sTitle);
	hMenu.ExitBackButton = true;
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
	hMenu.AddItem("buy", sItem, (ClientCash >= g_Item.Price && g_iPerkLvl[iClient] < g_Item.MaxLvl && Gangs_GetGangLvl(Gangs_GetClientGangScore(iClient)) >= g_Item.ReqLvl) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	Format(sItem, sizeof(sItem), "%T", "sell", iClient);
	hMenu.AddItem("sell", sItem, (g_iPerkLvl[iClient] > 0 && Gangs_GetClientGangRank(iClient) == 0) ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
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
				
				Database db = Gangs_GetDatabase();
				db.Query(SQLCallback_Void, sQuery);
				delete db;

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
				if(g_Item.Notification)
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
				
				Database db = Gangs_GetDatabase();
				db.Query(SQLCallback_Void, sQuery);
				delete db;

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
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_payday.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][PayDay] - Configuration file not found");
	kfg.Rewind();
	g_Item.Bank = kfg.GetNum("bank", 0);
	g_Item.SellMode = kfg.GetNum("sell_mode", 1);
	g_Item.Price = kfg.GetNum("price", 15000);
	g_Item.ProcentSell = kfg.GetNum("procent_sell", 50);
	if(g_Item.ProcentSell > 100)
		g_Item.ProcentSell = 100;
	else if(g_Item.ProcentSell < 0)
		g_Item.ProcentSell = 0;
	g_Item.Notification = kfg.GetNum("notification", 0);
	g_Item.ReqLvl = kfg.GetNum("req_lvl", 5);
	g_Item.Mode = kfg.GetNum("mode", 0);
	g_Item.Time = kfg.GetNum("time", 60);
	g_Item.MaxLvl = kfg.GetNum("max", 0);
	if(g_Item.Mode)
		g_Item.Modifier = kfg.GetNum("modifier", 0);
	g_Item.ModifierMode = kfg.GetNum("modifier_mode", 1);
	delete kfg;
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_Void] Error (%i): %s", data, error);
	}
}

void DB_OnPluginStart()
{
	DB_Connect();
}

void DB_Connect()
{
	//DebugMessage("DB_Connect")
	
	if (GLOBAL_INFO & IS_LOADING)
	{
		return;
	}

	if (g_hDatabase != null)
	{
		UNSET_BIT(GLOBAL_INFO, IS_LOADING);
		return;
	}
	
	SET_BIT(GLOBAL_INFO, IS_LOADING);

	if (SQL_CheckConfig("payday"))
	{
		Database.Connect(OnDBConnect, "payday", 0);
	}
	else
	{
		char szError[256];
		g_hDatabase = SQLite_UseDatabase("payday", SZF(szError));
		OnDBConnect(g_hDatabase, szError, 1);
	}
}

public void OnDBConnect(Database hDatabase, const char[] szError, any data)
{
	if (hDatabase == null || szError[0])
	{
		SetFailState("OnDBConnect %s", szError);
		UNSET_BIT(GLOBAL_INFO, IS_MySQL);
	//	CreateTimer(5.0, Timer_DB_Reconnect);
		return;
	}

	g_hDatabase = hDatabase;
	
	if (data == 1)
	{
		UNSET_BIT(GLOBAL_INFO, IS_MySQL);
	}
	else
	{
		char szDriver[8];
		g_hDatabase.Driver.GetIdentifier(SZF(szDriver));

		if (strcmp(szDriver, "mysql", false) == 0)
		{
			SET_BIT(GLOBAL_INFO, IS_MySQL);
		}
		else
		{
			UNSET_BIT(GLOBAL_INFO, IS_MySQL);
		}
	}
	
	//DebugMessage("OnDBConnect %x, %u - > (MySQL: %b)", g_hDatabase, g_hDatabase, GLOBAL_INFO & IS_MySQL)
	
	CreateTables();
}

void CreateTables()
{
	g_hDatabase.Query(SQLCallback_Void, "CREATE TABLE IF NOT EXISTS payday_players (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											steamid TEXT(32) NOT NULL, \
											time INTEGER(16) NOT NULL DEFAULT 0);", 1);
}