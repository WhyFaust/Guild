#pragma newdecls required

#include <gangs>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <gangs_size>
#define REQUIRE_PLUGIN

#define StatName	"StatisticStandart"

char g_sDbStatisticName[64];
bool g_bModuleSizeExist = false;

public Plugin myinfo =
{
	name = "[GANGS MODULE] Statistic Standart",
	author = "Faust",
	version = GANGS_VERSION
};

public void OnAllPluginsLoaded()
{
	g_bModuleSizeExist = LibraryExists("gangs_size");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gangs_size"))
	{
		g_bModuleSizeExist = false;
	}
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gangs_size"))
	{
		g_bModuleSizeExist = true;
	}
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}

	Gangs_OnLoaded();
}

public void Gangs_OnLoaded()
{ 
	Handle g_hCvar = FindConVar("sm_gangs_db_statistic_name");
	if (g_hCvar != INVALID_HANDLE)
		GetConVarString(g_hCvar, g_sDbStatisticName, sizeof(g_sDbStatisticName));
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToStatMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddToStatMenu(Handle timer)
{
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
		Format(sQuery, sizeof(sQuery), "SELECT group_table.name, statistic_table.%s, statistic_table.gang_id \
										FROM gang_statistic AS statistic_table \
										INNER JOIN gang_group AS group_table \
										ON group_table.id = statistic_table.gang_id \
										ORDER BY statistic_table.%s DESC;", 
										g_sDbStatisticName, g_sDbStatisticName);
		hDatabase.Query(SQLCallback_StatMenu, sQuery, iClient);
		delete hDatabase;
	}
}

public void SQLCallback_StatMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_StatMenu] Error (%i): %s", data, error);
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
		char sGangName[128];
		int iGangAmmount = results.RowCount;
		int iGangRank = 0;
		int iScore;
		while (results.FetchRow())
		{
			results.FetchString(0, sGangName, sizeof(sGangName));
			iGangRank++;
			iScore = results.FetchInt(1);
			int gang_id = results.FetchInt(2);

			Format(sInfoString, sizeof(sInfoString), "%s;%i;%i;%i;%i", sGangName, iGangRank, iGangAmmount, iScore, gang_id);
			menu.AddItem(sInfoString, sGangName);
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
			char sQuery[300];
			char sTempArray[5][128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));

			ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[])); // 0 - GangName \ 1 - GangPosition \ 2 - Count Gangs \ 3 - Gang Score \ 4 - Gang id
			
			DataPack pack = new DataPack(); // 0 - Client \ 1 - GangPosition \ 2 - Count Gangs \ 3 - Gang Score
			pack.WriteCell(param1);
			pack.WriteCell(StringToInt(sTempArray[1]));
			pack.WriteCell(StringToInt(sTempArray[2]));
			pack.WriteCell(StringToInt(sTempArray[3]));

			Database hDatabase = Gangs_GetDatabase();
			Format(sQuery, sizeof(sQuery), "SELECT group_table.id, group_table.name, player_table.name, group_table.create_date, \
											(SELECT COUNT(*) FROM gang_player WHERE gang_id = %i) \
											FROM gang_player AS player_table \
											INNER JOIN gang_group AS group_table \
											ON group_table.id = player_table.gang_id \
											WHERE gang_id = %i AND rank = 0;", 
											StringToInt(sTempArray[4]), StringToInt(sTempArray[4]));
			hDatabase.Query(SQLCallback_GangStatistics, sQuery, pack);
			delete hDatabase;
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

public void SQLCallback_GangStatistics(Database db, DBResultSet results, const char[] error, DataPack data)
{
	if (error[0])
	{
		LogError("[SQLCallback_GangStatistics] Error (%i): %s", data, error);

		return;
	}

	char sFormattedTime[64];
	char sDisplayString[128];

	data.Reset(); // Возвращаем позицию на 0
	int iClient = data.ReadCell(); // Client
	int iGangPosition = data.ReadCell(); // GangPosition
	int iCountGangs = data.ReadCell(); // Count Gangs
	int iGangScore = data.ReadCell(); // Gang Score
	
	results.FetchRow();

	char sGangName[128], sCreatedName[128];
	int iGangId = results.FetchInt(0);
	results.FetchString(1, sGangName, sizeof(sGangName)); // Gang Name
	results.FetchString(2, sCreatedName, sizeof(sCreatedName)); // Created by
	int iDate = results.FetchInt(3); // Create Date
	int iMembersCount = results.FetchInt(4); // Members Count

	Menu menu = CreateMenu(StatMenuCallback_Void, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	char sTitleString[64];
	Format(sTitleString, sizeof(sTitleString), "%T", StatName, iClient);
	menu.SetTitle(sTitleString);

	Format(sDisplayString, sizeof(sDisplayString), "%T : %s %T", "MenuGangName", iClient, sGangName, "Level", iClient, Gangs_GetGangLvl(iClient));
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i", "Score", iClient, iGangScore, Gangs_GetGangReqScore(iGangScore));
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "NumMemb", iClient, iMembersCount
												, (g_bModuleSizeExist) ? Gangs_GetGangSize() + Gangs_Size_GetCurrectLvl(iClient) : Gangs_GetGangSize());
	Format(sGangName, sizeof(sGangName), "%i", iGangId);
	menu.AddItem(sGangName, sDisplayString);

	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%d/%m/%Y", iDate);
	Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "DateCreated", iClient, sFormattedTime);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i", "GangRank", iClient, iGangPosition, iCountGangs);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T", "CreatedBy", iClient, sCreatedName);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int StatMenuCallback_Void(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			StartOpeningMembersMenu(param1, StringToInt(sInfo));
		}
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

void StartOpeningMembersMenu(int iClient, int iGangId)
{
	Database hDatabase = Gangs_GetDatabase();
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT player_table.steam_id, player_table.name, player_table.inviter_name, player_table.rank, player_table.invite_date, group_table.name \
									FROM gang_player AS player_table \
									INNER JOIN gang_group AS group_table \
									ON player_table.gang_id = group_table.id \
									WHERE player_table.gang_id = %i;", 
									iGangId);
	hDatabase.Query(SQLCallback_OpenMembersMenu, sQuery, iClient);
	delete hDatabase;
}

public void SQLCallback_OpenMembersMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_OpenMembersMenu] Error (%i): %s", data, error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(MemberListMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
		
		char sDisplayString[128];
		char sTitleString[128];
		Format(sTitleString, sizeof(sTitleString), "%T", "MemberList", iClient);
		SetMenuTitle(menu, sTitleString);
		
		while (results.FetchRow())
		{
			char a_sTempArray[6][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
			results.FetchString(0, a_sTempArray[0], sizeof(a_sTempArray[])); // Steam-ID
			results.FetchString(1, a_sTempArray[1], sizeof(a_sTempArray[])); // Player Name
			results.FetchString(2, a_sTempArray[2], sizeof(a_sTempArray[])); // Invited By
			IntToString(results.FetchInt(3), a_sTempArray[3], sizeof(a_sTempArray[])); // Rank
			IntToString(results.FetchInt(4), a_sTempArray[4], sizeof(a_sTempArray[])); // Date
			results.FetchString(5, a_sTempArray[5], sizeof(a_sTempArray[])); // Gang


			char sInfoString[1024];

			Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%i;%i;%s", a_sTempArray[0], a_sTempArray[1], a_sTempArray[2], StringToInt(a_sTempArray[3]), StringToInt(a_sTempArray[4]), a_sTempArray[5]);

			KeyValues ConfigRanks;
			ConfigRanks = new KeyValues("Ranks");
			char szBuffer[256];
			BuildPath(Path_SM, szBuffer, 256, "configs/gangs/ranks.txt");
			ConfigRanks.ImportFromFile(szBuffer);
			ConfigRanks.Rewind();
			if(ConfigRanks.JumpToKey(a_sTempArray[3]))
			{
				ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
				Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[1], szBuffer, iClient);
			}
			delete ConfigRanks;
			
			menu.AddItem(sInfoString, sDisplayString);
		}
		
		menu.ExitBackButton = true;

		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int MemberListMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			OpenIndividualMemberMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
			if(param2 == MenuCancel_ExitBack)
				StartOpeningStatMenu(param1);
		case MenuAction_End:
			delete menu;
	}
	return;
}

void OpenIndividualMemberMenu(int iClient, char[] sInfo)
{
	Menu menu = CreateMenu(IndividualMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	SetMenuTitle(menu, "Информация : ");

	char sTempArray[6][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF) | 5 - Gang
	char sDisplayBuffer[64];

	ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "Name", iClient, sTempArray[1]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "Steam ID: %s", sTempArray[0]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "InvitedBy", iClient, sTempArray[2]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	KeyValues ConfigRanks;
	ConfigRanks = new KeyValues("Ranks");
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
	ConfigRanks.ImportFromFile(szBuffer);
	ConfigRanks.Rewind();
	if(ConfigRanks.JumpToKey(sTempArray[3])) // Попытка перейти к ключу
	{
		ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", iClient, szBuffer, iClient);
	}
	delete ConfigRanks;
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	char sFormattedTime[64];
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%x", StringToInt(sTempArray[4]));
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "DateJoined", iClient, sFormattedTime);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int IndividualMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
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