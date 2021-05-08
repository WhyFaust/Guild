#pragma newdecls required

#include <sourcemod>
#include <gangs>
#include <csgocolors>

#define StatName	"StatisticRating"

int g_iRating[MAXPLAYERS+1] = -1;

bool g_bGangCoreExist = false;
 
public void OnAllPluginsLoaded()
{
	g_bGangCoreExist = LibraryExists("gangs");
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = true;
}

public Plugin myinfo =
{
	name = "[GANGS MODULE] Statistic Rating",
	author = "baferpro",
	version = GANGS_VERSION
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	CreateNative("Gangs_StatisticRating_GetClientRating", Native_StatisticRating_GetClientRating);
	CreateNative("Gangs_StatisticRating_SetClientRating", Native_StatisticRating_SetClientRating);

	RegPluginLibrary("gangs_statistic_rating");

	return APLRes_Success;
}

public int Native_StatisticRating_GetClientRating(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	return view_as<int>(g_iRating[iClient]);
}

public int Native_StatisticRating_SetClientRating(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	int iRating = GetNativeCell(2);

	char sGangName[256];
	Gangs_GetClientGangName(iClient, sGangName, sizeof(sGangName));
	char sQuery[300];
	Database hDatabase = Gangs_GetDatabase();
	Format(sQuery, sizeof(sQuery), "UPDATE gangs_statistics SET rating = %i WHERE gang = '%s' AND server_id = %i;", iRating, sGangName, Gangs_GetServerID());
	hDatabase.Query(SQLCallback_Void, sQuery, iClient);
	delete hDatabase;

	char sGangName1[256];
	for(int i = 1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			Gangs_GetClientGangName(i, sGangName1, sizeof(sGangName1));
			if(StrEqual(sGangName, sGangName1))
				g_iRating[iClient] = iRating;
		}
	}

	return 0;
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}

	Gangs_OnLoaded();
}

public void OnClientConnected(int iClient)
{
	g_iRating[iClient] = -1;
}

public void OnClientDisconnect(int iClient)
{
	g_iRating[iClient] = -1;
}

public void OnClientPutInServer(int iClient)
{
	if(g_bGangCoreExist)
		CreateTimer(2.0, GetGangRating, iClient, TIMER_FLAG_NO_MAPCHANGE);
	else CreateTimer(5.0, ReLoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action GetGangRating(Handle hTimer, int iUserID)
{
	int iClient = iUserID;
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		char sGangName[256];
		Gangs_GetClientGangName(iClient, sGangName, sizeof(sGangName));
		char sQuery[300];
		Database hDatabase = Gangs_GetDatabase();
		Format(sQuery, sizeof(sQuery), "SELECT rating FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", sGangName, Gangs_GetServerID());
		hDatabase.Query(SQLCallback_GetGangRating, sQuery, iClient);
		delete hDatabase;
	}
}

public Action ReLoadPerkLvl(Handle hTimer, int iUserID)
{
	OnClientPutInServer(iUserID);
}

public void SQLCallback_GetGangRating(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
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
		g_iRating[iClient] = results.FetchInt(0);
	}
	
	if(g_iRating[iClient] == -1)
	{
		OnClientPutInServer(iClient);
	}
}

public void Gangs_OnLoaded()
{ 
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToStatMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddToStatMenu(Handle timer)
{
	Database hDatabase = Gangs_GetDatabase();
	char sQuery[300];
	if(Gangs_GetDatabaseDriver())
		Format(sQuery, sizeof(sQuery), "ALTER TABLE gangs_statistics ADD COLUMN rating int(32) NOT NULL DEFAULT 0;");
	else
		Format(sQuery, sizeof(sQuery), "ALTER TABLE gangs_statistics ADD COLUMN rating INTEGER(32) NOT NULL DEFAULT 0;");
	hDatabase.Query(SQLCallback_Void, sQuery);
	delete hDatabase;
	Gangs_AddToStatsMenu(StatName, STATSTANDART_CallBack);
}

public void STATSTANDART_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	StartOpeningStatMenu(iClient);
}

void StartOpeningStatMenu(int iClient)
{
	if (IsValidClient(iClient))
	{
		Database hDatabase = Gangs_GetDatabase();
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT gang, rating FROM gangs_statistics ORDER BY rating DESC;");
		hDatabase.Query(SQL_Callback_StatMenu, sQuery, iClient);
		delete hDatabase;
	}
}

public void SQL_Callback_StatMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQL_Callback_StatMenu] Error (%i): %s", data, error);
		return;
	}

	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else
	{		
		Menu menu = CreateMenu(StatisticStandartMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		
		char menuTitle[64];
		Format(menuTitle, sizeof(menuTitle), "%T", StatName, iClient);
		menu.SetTitle(menuTitle);
		if (results.RowCount == 0)
		{
			CPrintToChat(iClient, "%t %t", "Prefix", "NoGangs");
			
			delete menu;
			return;
		}

		char sInfoString[256];
		while (results.FetchRow())
		{
			char sGangName[128];
			results.FetchString(0, sGangName, sizeof(sGangName));
			int iRating = results.FetchInt(1);

			//Format(sInfoString, sizeof(sInfoString), "%s;%i", sGangName, iRating);
			Format(sInfoString, sizeof(sInfoString), "%s [%i]", sGangName, iRating);
			menu.AddItem(sInfoString, sInfoString, ITEMDRAW_DISABLED);
		}   

		menu.ExitBackButton = true;

		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int StatisticStandartMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[300];
			char sTempArray[2][128];
			char sDisplayString[128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

			Menu menu1 = CreateMenu(StatMenuCallback_Void, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
			char sTitleString[64];
			Format(sTitleString, sizeof(sTitleString), "%T", StatName, param1);
			menu1.SetTitle(sTitleString);

			Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "MenuGangName", param1, sTempArray[0]);
			menu1.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

			Format(sDisplayString, sizeof(sDisplayString), "%T : %i", "Rating", param1, StringToInt(sTempArray[1]));
			menu1.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

			menu1.ExitBackButton = true;
			menu1.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Gangs_ShowMainMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

public int StatMenuCallback_Void(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			StartOpeningStatMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		LogError("Error (%i): %s", data, error);
	}
}