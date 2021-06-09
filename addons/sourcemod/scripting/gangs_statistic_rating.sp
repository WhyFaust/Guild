#pragma newdecls required

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
	author = "Faust",
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

	int gangid = Gangs_GetClientGangId(iClient);
	char sQuery[300];
	Database hDatabase = Gangs_GetDatabase();
	Format(sQuery, sizeof(sQuery), "UPDATE gang_statistic \
									SET rating = %i \
									WHERE gang_id = %i;", 
									iRating, gangid);
	hDatabase.Query(SQLCallback_Void, sQuery, iClient);
	delete hDatabase;

	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			if(gangid == Gangs_GetClientGangId(i))
				g_iRating[i] = iRating;

	return 0;
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin works only on CS:GO");

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
		int gangid = Gangs_GetClientGangId(iClient);
		char sQuery[300];
		Database hDatabase = Gangs_GetDatabase();
		Format(sQuery, sizeof(sQuery), "SELECT rating \
										FROM gang_statistic \
										WHERE gang_id = %i;", 
										gangid);
		hDatabase.Query(SQLCallback_GetGangRating, sQuery, iClient);
		delete hDatabase;
	}
}

public Action ReLoadPerkLvl(Handle hTimer, int iUserID)
{
	OnClientPutInServer(iUserID);
}

public void SQLCallback_GetGangRating(Database db, DBResultSet results, const char[] error, int iClient)
{
	if (error[0])
	{
		LogError(error);
		return;
	}

	if (!IsValidClient(iClient))
		return;

	if (results.FetchRow())
		g_iRating[iClient] = results.FetchInt(0);
	
	if(g_iRating[iClient] == -1)
		OnClientPutInServer(iClient);
}

public void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter)
{
	if (!IsValidClient(iClient))
		return;

	if(g_iRating[Inviter] == -1)
		OnClientPutInServer(iClient);
	else
		g_iRating[iClient] = g_iRating[Inviter];
}

public void Gangs_OnLoaded()
{ 
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToStatMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddToStatMenu(Handle timer)
{
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT rating \
									FROM gang_statistic;");
	Database hDatabase = Gangs_GetDatabase();
	g_hDatabase.Query(SQLCallback_CheckTable, sQuery);
	delete hDatabase;
	Gangs_AddToStatsMenu(StatName, STATSTANDART_CallBack);
}

public void SQLCallback_CheckTable(Database db, DBResultSet hResults, const char[] sError, any data)
{
	if(sError[0])
	{
		if(StrContains(sError, "Duplicate column name", false))
		{
			char sQuery[300];
			if(Gangs_GetDatabaseDriver())
				Format(sQuery, sizeof(sQuery), "ALTER TABLE gang_statistic \
												ADD COLUMN rating int(32) NOT NULL DEFAULT 0;");
			else
				Format(sQuery, sizeof(sQuery), "ALTER TABLE gang_statistic \
												ADD COLUMN rating INTEGER(32) NOT NULL DEFAULT 0;");
			Database hDatabase = Gangs_GetDatabase();
			hDatabase.Query(SQLCallback_Void, sQuery);
			delete hDatabase;
		}
		else
		{
			LogError("[SQLCallback_CheckTable] Error :  %s", sError);
		}

		return;
	}
	
	if(hResults.FetchRow())
		return;
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
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT group_table.name, statistic_table.rating \
										FROM gang_statistic AS statistic_table \
										INNER JOIN gang_group AS group_table \
										ON group_table.id = statistic_table.gang_id \
										ORDER BY rating DESC;");
		hDatabase.Query(SQL_Callback_StatMenu, sQuery, iClient);
		delete hDatabase;
	}
}

public void SQL_Callback_StatMenu(Database db, DBResultSet results, const char[] error, int iClient)
{
	if (error[0])
	{
		LogError("[SQL_Callback_StatMenu] Error (%i): %s", iClient, error);
		return;
	}

	if (!IsValidClient(iClient))
		return;

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
	char sBuffer[256];
	while (results.FetchRow())
	{
		char sGangName[128];
		results.FetchString(0, sGangName, sizeof(sGangName));
		int iRating = results.FetchInt(1);

		Format(sBuffer, sizeof(sBuffer), "%s;%i", sGangName, iRating);
		Format(sInfoString, sizeof(sInfoString), "%s [%i]", sGangName, iRating);
		menu.AddItem(sBuffer, sInfoString, ITEMDRAW_DISABLED);
	}   

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
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
	if (error[0])
		LogError("[SQLCallback_Void] Error (%i): %s", data, error);

}