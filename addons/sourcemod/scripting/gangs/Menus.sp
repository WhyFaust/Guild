/*****************************************************************
*********************** MAIN GANG MENU	**************************
******************************************************************/
void StartOpeningGangMenu(int iClient)
{
	if (ga_bHasGang[iClient])
	{
		int iLen = 2*strlen(ga_sGangName[iClient])+1;
		char[] szEscapedGang = new char[iLen];
		g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT end_date \
										FROM gang_group \
										WHERE id = %i AND server_id = %i;", 
										ga_iGangId[iClient], g_iServerID);
		g_hDatabase.Query(SQLCallback_OneOpenGangMenu, sQuery, iClient);
	}
	else
	{
		OpenGangsMenu(iClient);
	}
}

public void SQLCallback_OneOpenGangMenu(Database db, DBResultSet results, const char[] error, int data)
{	
	if (results == null)
	{
		LogError(error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		if (results.FetchRow() && results.RowCount == 1)
		{
			ga_iEndTime[iClient] = results.FetchInt(0);
			
			int iLen = 2*strlen(ga_sGangName[iClient])+1;
			char[] szEscapedGang = new char[iLen];
			g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT * \
											FROM gang_player \
											WHERE gang_id = %i;", 
											ga_iGangId[iClient]);
			g_hDatabase.Query(SQLCallback_TwoOpenGangMenu, sQuery, iClient);
		}
	}
}

public void SQLCallback_TwoOpenGangMenu(Database db, DBResultSet results, const char[] error, int iClient)
{
	if (error[0])
	{
		LogError(error);
		return;
	}

	if (!IsValidClient(iClient))
		return;

	ga_iGangSize[iClient] = results.RowCount;
	OpenGangsMenu(iClient);
}

void OpenGangsMenu(int iClient)
{
	if((g_bMenuInfo && (g_bGameCMSExist && GameCMS_Registered(iClient))) || !g_bGameCMSExist || !g_bMenuInfo)
	{
		Menu menu = CreateMenu(GangsMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		
		char sString[256];
		Format(sString, sizeof(sString), "%T\n", "GangsMenuTitle", iClient);
		
		if(g_bMenuValue == 1 && g_bGameCMSExist)
		{
			if(!g_bMenuInfo)
			{
				if(g_bGameCMSExist && !GameCMS_Registered(iClient))
					Format(sString, sizeof(sString), "%s%T N/A\n", sString, "rubles", iClient);
				else
					Format(sString, sizeof(sString), "%s%T %i\n", sString, "rubles", iClient, GameCMS_GetClientRubles(iClient));
			}
			else
			{
				Format(sString, sizeof(sString), "%s%T %i\n", sString, "rubles", iClient, GameCMS_GetClientRubles(iClient));
			}
		}
		else if(g_bMenuValue == 2)
		{
			if(g_bShopLoaded)
				Format(sString, sizeof(sString), "%s%T %i\n", sString, "shop", iClient, Shop_GetClientCredits(iClient));
			else if(g_bStoreLoaded)
				Format(sString, sizeof(sString), "%s%T %i\n", sString, "shop", iClient, Store_GetClientCredits(iClient));
		}
		else if(g_bMenuValue == 3 && g_bLShopGoldExist)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString, "shopgold", iClient, Shop_GetClientGold(iClient));
		}
		else if(g_bMenuValue == 4)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString, "wcsgold", iClient, WCS_GetGold(iClient));
		}
		else if(g_bMenuValue == 5 && g_bLKLoaded)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString, "lkrubles", iClient, LK_GetBalance(iClient, LK_Cash));
		}
		else if(g_bMenuValue == 6 && g_bMyJBShopExist)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString, "myjb", iClient, MyJailShop_GetCredits(iClient));
		}
		
		if(ga_bHasGang[iClient])
		{
			Format(sString, sizeof(sString), "%s%T \n", sString, "CurrentGang", iClient, ga_sGangName[iClient], "Level", GetGangLvl(ga_iScore[iClient]));
			if(g_iCreateGangDays>0)
			{
				int days= (ga_iEndTime[iClient]-GetTime())/86400;
				if(days<0) 
					days = 0;
				Format(sString, sizeof(sString), "%s%T \n", sString, "GangExpired", iClient, days);
			}
		}
		else
		{
			Format(sString, sizeof(sString), "%s%T", sString, "NoGang", iClient);
		}
		
		SetMenuTitle(menu, sString);
		
		char sDisplayBuffer[128];
		
		if(!ga_bHasGang[iClient])
		{
			if(g_bCreateGangSellMode == 0 && g_bGameCMSExist)
			{
				int Discount;
				if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
					Discount = GameCMS_GetGlobalDiscount();
				else 
					Discount = GameCMS_GetClientDiscount(iClient);
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T (%T %i%%)", "CreateAGang", iClient, Colculate(iClient, g_iCreateGangPrice, Discount), "rubles", iClient, "Sale", Discount);
				menu.AddItem("create", sDisplayBuffer, (GameCMS_GetClientRubles(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 1)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "shop");
				if(g_bShopLoaded)
					menu.AddItem("create", sDisplayBuffer, (Shop_GetClientCredits(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
				else if(g_bStoreLoaded)
					menu.AddItem("create", sDisplayBuffer, (Store_GetClientCredits(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 2 && g_bLShopGoldExist)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "shopgold");
				menu.AddItem("create", sDisplayBuffer, (Shop_GetClientGold(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 3)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "wcsgold");
				menu.AddItem("create", sDisplayBuffer, (WCS_GetGold(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 4 && g_bLKLoaded)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "lkrubles");
				menu.AddItem("create", sDisplayBuffer, (LK_GetBalance(iClient, LK_Cash) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 5 && g_bMyJBShopExist)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "myjb");
				menu.AddItem("create", sDisplayBuffer, (MyJailShop_GetCredits(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
		}
		else if(ga_bHasGang[iClient] && g_bEnableBank)
		{
			Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Bank", iClient);
			menu.AddItem("bank", sDisplayBuffer, ITEMDRAW_DEFAULT);
		}
		
		if(ga_bHasGang[iClient])
		{
			Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Stat", iClient);
			menu.AddItem("stat", sDisplayBuffer, ITEMDRAW_DEFAULT);
		}
		
		//Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%t", "GangMembers");
		//menu.AddItem("members", sDisplayBuffer, (ga_bHasGang[iClient])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		if(g_iPerksCount > -1)
		{
			Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangPerks", iClient);
			menu.AddItem("perks", sDisplayBuffer, (ga_bHasGang[iClient])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		
		if(g_iGamesCount > -1)
		{
			Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangGames", iClient);
			menu.AddItem("games", sDisplayBuffer, (ga_bHasGang[iClient])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangAdmin", iClient);
		menu.AddItem("admin", sDisplayBuffer, (ga_bHasGang[iClient] && ((GetClientRightStatus(iClient, "extend") || GetClientRightStatus(iClient, "rename")) || ga_iRank[iClient] == 0))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "LeaveGang", iClient);
		menu.AddItem("leave", sDisplayBuffer, (ga_bHasGang[iClient] && ga_iRank[iClient] != 0)?	ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		if(g_iStatsCount > -1)
		{
			Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "TopGangs", iClient);
			menu.AddItem("topgangs", sDisplayBuffer);
		}

		if(!ga_bHasGang[iClient])
		{
			if (!ga_bBlockInvites[iClient])
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "BlockInvites", iClient);
			else
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "UnblockInvites", iClient);
			
			menu.AddItem("blockinvites", sDisplayBuffer);
		}
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
	else if(g_bMenuInfo)
	{
		char sString[256];
		
		Format(sString, sizeof(sString), "%T", "GangsMenuTitle", iClient);
		
		Panel hPanel = new Panel();
		hPanel.SetTitle(sString);
		hPanel.DrawText(" ");
		hPanel.DrawItem("Узнать свой SteamID");
		hPanel.DrawText(" ");
		hPanel.DrawItem("Выход");
		hPanel.DrawText(" ");
		hPanel.DrawItem("Лучшие банды");
		hPanel.DrawText(" ");
	
		Handle file = OpenFile(g_sFile, "r");
		if (file == INVALID_HANDLE)
			SetFailState("[Gangs] Error opening info file (addons/sourcemod/configs/gangs/info.ini)");
	
		if(!IsEndOfFile(file)) 
		{
			ReadFileLine(file, sString, sizeof(sString));
			ReplaceString(sString, strlen(sString), "{N}", "\n", false);
			hPanel.DrawText(sString);
		}
		
		CloseHandle(file);
		
		hPanel.Send(iClient, Handler_NoDustupPanel, 20);
	}
}

public int Handler_NoDustupPanel(Handle hPanel, MenuAction action, int iClient, int option)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hPanel;
		}
		case MenuAction_Select:
		{
			if(option == 1)
			{
				char sSteamID[64];
				GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
				CPrintToChat(iClient, "%t Ваш SteamID: %s", "Prefix", sSteamID);
			}
			else if(option == 2)
			{
				CPrintToChat(iClient, "%t Всего доброго ♥", "Prefix");
			}
			else if(option == 3)
			{
				StartOpeningTopGangsMenu(iClient);
			}
		}
	}
}

public int GangsMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (!IsValidClient(param1))
		return;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "create"))
			{
				StartGangCreation(param1);
			}
			else if (StrEqual(sInfo, "bank"))
			{
				DisplayBankMenu(param1);
			}
			else if (StrEqual(sInfo, "stat"))
			{
				StartOpeningStatMenu(param1);
			}
			else if (StrEqual(sInfo, "perks"))
			{
				StartOpeningPerkMenu(param1);
			}
			else if (StrEqual(sInfo, "games"))
			{
				StartOpeningGamesMenu(param1);
			}
			else if (StrEqual(sInfo, "admin"))
			{
				OpenAdministrationMenu(param1);
			}
			else if (StrEqual(sInfo, "leave"))
			{
				OpenLeaveConfirmation(param1);
			}
			else if (StrEqual(sInfo, "topgangs"))
			{
				StartOpeningTopGangsMenu(param1);
			}
			else if (StrEqual(sInfo, "blockinvites"))
			{
				BlockInvites(param1);
			}

		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

void BlockInvites(int iClient)
{
	if (!IsValidClient(iClient))
		return;
	
	ga_bBlockInvites[iClient] = !ga_bBlockInvites[iClient]; // toggle
	
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT pref \
									FROM gang_pref \
									WHERE steamid = '%s';", 
									ga_sSteamID[iClient]);
	g_hDatabase.Query(SQLCallback_CheckPreference, sQuery, iClient);
}

public void SQLCallback_CheckPreference(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckPreference] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	char sQuery[300];
	if(results.FetchRow())
	{
		Format(sQuery, sizeof(sQuery), "UPDATE gang_pref \
										SET pref = '%i' \
										WHERE steamid = '%s';", 
										ga_bBlockInvites[iClient], ga_sSteamID[iClient]);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO gang_pref \
										(pref, steamid) \
										VALUES('%i', '%s');", 
										ga_bBlockInvites[iClient], ga_sSteamID[iClient]);
	}
	g_hDatabase.Query(SQLCallback_Void, sQuery, 25);
	StartOpeningGangMenu(iClient);
}

/*****************************************************************
***********************	   PERK MENU	 *************************
******************************************************************/
public void StartOpeningPerkMenu(int iClient)
{
	char ItemName[52], text[76];
	Menu hMenu = new Menu(ShowPerkMenu_CallBack);
	
	char sTitleString[64];
	Format(sTitleString, sizeof(sTitleString), "%T", "GangPerks", iClient);
	hMenu.SetTitle(sTitleString);
	
	for(int i; i < g_iPerksCount; i++)
	{
		char sInfo[128];
		g_hPerkName.GetString(i, ItemName, sizeof(ItemName));
		FormatEx(text, sizeof(text), "%T", ItemName, iClient);
		FormatEx(sInfo, sizeof(sInfo), "%i;%s", g_hPerkID.Get(i, 0, false), ItemName);
		hMenu.AddItem(sInfo, text);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int ShowPerkMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			char sInfo[128], sBuffers[2][64];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ";", sBuffers, 2, 64);
			int index = -1;
			if((index = g_hPerkArray.FindString(sBuffers[1])) != -1)
			{
				DataPack hPack;
				hPack = g_hPerkArray.Get(index+1);
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();
				if(IsCallValid(hPlugin, fncCallback))
				{
					Call_StartFunction(hPlugin, fncCallback);
					Call_PushCell(iClient);
					Call_PushCell(StringToInt(sBuffers[0]));
					Call_PushString(sBuffers[1]);
					Call_Finish();
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
				StartOpeningGangMenu(iClient);
		}
	}
}

/*****************************************************************
***********************	   GAMES MENU	 *************************
******************************************************************/
public void StartOpeningGamesMenu(int iClient)
{
	char ItemName[52], text[76];
	Menu hMenu = new Menu(ShowGamesMenu_CallBack);
	
	char sTitleString[64];
	Format(sTitleString, sizeof(sTitleString), "%T", "GangGames", iClient);
	hMenu.SetTitle(sTitleString);
	
	for(int i; i < g_iGamesCount; i++)
	{
		char sInfo[128];
		g_hGameName.GetString(i, ItemName, sizeof(ItemName));
		FormatEx(text, sizeof(text), "%T", ItemName, iClient);
		FormatEx(sInfo, sizeof(sInfo), "%i;%s", g_hGameID.Get(i, 0, false), ItemName);
		hMenu.AddItem(sInfo, text);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int ShowGamesMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete hMenu;
		}
		case MenuAction_Select:
		{
			char sInfo[128], sBuffers[2][64];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ";", sBuffers, 2, 64);
			int index = -1;
			if((index = g_hGamesArray.FindString(sBuffers[1])) != -1)
			{
				DataPack hPack;
				hPack = g_hGamesArray.Get(index+1);
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();
				if(IsCallValid(hPlugin, fncCallback))
				{
					Call_StartFunction(hPlugin, fncCallback);
					Call_PushCell(iClient);
					Call_PushCell(StringToInt(sBuffers[0]));
					Call_PushString(sBuffers[1]);
					Call_Finish();
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
				StartOpeningGangMenu(iClient);
		}
	}
}

/*****************************************************************
***********************	   STAT MENU	 *************************
******************************************************************/
void StartOpeningStatMenu(int iClient)
{
	if (IsValidClient(iClient))
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT group_table.name, statistic_table.%s \
										FROM gang_statistic AS statistic_table \
										INNER JOIN gang_group AS group_table \
										ON group_table.id = statistic_table.gang_id \
										ORDER BY %s DESC;", 
										g_sDbStatisticName, g_sDbStatisticName);
		g_hDatabase.Query(SQLCallback_StatMenu, sQuery, iClient);
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
		char sGangName[128];
		g_iGangAmmount = 0;
		ga_iTempInt2[iClient] = 1;
		bool status = false;
		while (results.FetchRow())
		{
			g_iGangAmmount++;
			results.FetchString(0, sGangName, sizeof(sGangName));
			if(!StrEqual(sGangName, ga_sGangName[iClient], true) && !status)
				ga_iTempInt2[iClient]++;
			else
				status = true;
			
			if(StrEqual(sGangName, ga_sGangName[iClient], true))
				ga_iTempInt1[iClient] = results.FetchInt(1);
		}
		DisplayStatMenu(iClient);
	}
}

public void DisplayStatMenu(int iClient)
{
	if (IsValidClient(iClient))
	{
		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT gang_table.name, player_table.name, gang_table.create_date \
										FROM gang_player AS player_table \
										INNER JOIN gang_group AS gang_table \
										ON player_table.gang_id = gang_table.id \
										WHERE gang_id = %i AND rank = 0 AND server_id = %i;", 
										ga_iGangId[iClient], g_iServerID);
		g_hDatabase.Query(SQLCallback_OpenStatistics, sQuery, iClient);
	}
}

public void SQLCallback_OpenStatistics(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_OpenStatistics] Error (%i): %s", data, error);
		return;
	}

	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else
	{
		char sTempArray[2][128]; // Gang Name | Player Name 
		char sFormattedTime[64];
		char sDisplayString[128];
		
		results.FetchRow();


		results.FetchString(0, sTempArray[0], sizeof(sTempArray[]));
		results.FetchString(1, sTempArray[1], sizeof(sTempArray[]));
		int iDate = results.FetchInt(2);

		Menu menu = CreateMenu(StatMenuCallback_Void, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		char sTitleString[64];
		Format(sTitleString, sizeof(sTitleString), "%T %s", "Stat", iClient, sTempArray[0]);
		menu.SetTitle(sTitleString);

		//Format(sDisplayString, sizeof(sDisplayString), "%T : %s %t", "MenuGangName", iClient, sTempArray[0], "Level", GetGangLvl(ga_iScore[iClient]));
		//menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i %T", "Score", iClient, ga_iTempInt1[iClient], g_iScoreExpInc*GetGangLvl(ga_iScore[iClient]), "Level", iClient, GetGangLvl(ga_iScore[iClient]));
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		if(g_bStatisticRating)
		{
			Format(sDisplayString, sizeof(sDisplayString), "%T : %i", "Rating", iClient, Gangs_StatisticRating_GetClientRating(iClient));
			menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);
		}
		
		if(g_bModuleSizeExist)
		{
			Format(sDisplayString, sizeof(sDisplayString), "%T", "NumMemb", iClient, ga_iGangSize[iClient]
														, g_iSize + Gangs_Size_GetCurrectLvl(iClient));
			menu.AddItem("members", sDisplayString);
		}
		else
		{
			Format(sDisplayString, sizeof(sDisplayString), "%T", "NumMemb", iClient, ga_iGangSize[iClient], g_iSize);
			menu.AddItem("members", sDisplayString);
		}

		FormatTime(sFormattedTime, sizeof(sFormattedTime), "%d/%m/%Y", iDate);
		Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "DateCreated", iClient, sFormattedTime);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i", "GangRank", iClient, ga_iTempInt2[iClient], g_iGangAmmount);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T", "CreatedBy", iClient, sTempArray[1]);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		menu.ExitBackButton = true;
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int StatMenuCallback_Void(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if(StrEqual(sInfo, "members"))
			{
				StartOpeningMembersMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
*********************** MEMBER LIST MENU *************************
******************************************************************/
void StartOpeningMembersMenu(int iClient)
{
	if(!StrEqual(ga_sGangName[iClient], ""))
	{
		char sQuery[1000];
		Format(sQuery, sizeof(sQuery), "SELECT player_table.id, player_table.steam_id, player_table.name, player_table.inviter_name, player_table.rank, player_table.invite_date, gang_table.id \
										FROM gang_player AS player_table \
										INNER JOIN gang_group AS gang_table \
										ON player_table.gang_id = gang_table.id \
										WHERE gang_id = %i;", 
										ga_iGangId[iClient], g_iServerID);
		g_hDatabase.Query(SQLCallback_OpenMembersMenu, sQuery, iClient);
	}
}

public void SQLCallback_OpenMembersMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_OpenMembersMenu] Error (%i): %s", data, error);
		return;
	}
	
	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(MemberListMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
		
		char sTitleString[128];
		Format(sTitleString, sizeof(sTitleString), "%T", "MemberList", iClient);
		SetMenuTitle(menu, sTitleString);
		
		char sDisplayString[128];
		Format(sDisplayString, sizeof(sDisplayString), "%T\n \n", "InviteToGang", iClient);
		if(g_bModuleSizeExist)
			menu.AddItem("invite", sDisplayString, (GetClientRightStatus(iClient, "invite") && (ga_iGangSize[iClient] < g_iSize + Gangs_Size_GetCurrectLvl(iClient)))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("invite", sDisplayString, (GetClientRightStatus(iClient, "invite")	 && (ga_iGangSize[iClient] < g_iSize))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		
		while(results.FetchRow())
		{
			char a_sTempArray[7][128]; // 0 - Player ID | 1 - SteamID | 2 - Name | 3 - Invited Nane | 4 - Rank | 5 - Date (UTF) | 6 - Gang ID
			IntToString(results.FetchInt(0), a_sTempArray[0], sizeof(a_sTempArray[])); // Rank
			results.FetchString(1, a_sTempArray[1], sizeof(a_sTempArray[])); // Steam-ID
			results.FetchString(2, a_sTempArray[2], sizeof(a_sTempArray[])); // Player Name
			results.FetchString(3, a_sTempArray[3], sizeof(a_sTempArray[])); // Inviter Name
			IntToString(results.FetchInt(4), a_sTempArray[4], sizeof(a_sTempArray[])); // Rank
			IntToString(results.FetchInt(5), a_sTempArray[5], sizeof(a_sTempArray[])); // Date
			results.FetchString(6, a_sTempArray[6], sizeof(a_sTempArray[])); // Gang ID


			char sInfoString[1024];

			Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%s;%s;%s;%s", a_sTempArray[0], a_sTempArray[1], a_sTempArray[2], a_sTempArray[3], a_sTempArray[4], a_sTempArray[5], a_sTempArray[6]);

			KeyValues ConfigRanks;
			ConfigRanks = new KeyValues("Ranks");
			char szBuffer[256];
			BuildPath(Path_SM, szBuffer, 256, "configs/gangs/ranks.txt");
			ConfigRanks.ImportFromFile(szBuffer);
			ConfigRanks.Rewind();
			if(ConfigRanks.JumpToKey(a_sTempArray[4]))
			{
				ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
				Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[2], szBuffer, iClient);
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
			if(StrEqual(sInfo, "invite"))
				OpenInvitationMenu(param1);
			else
				OpenIndividualMemberMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
			if(param2 == MenuCancel_ExitBack)
				StartOpeningGangMenu(param1);
		case MenuAction_End:
			delete menu;
	}
	return;
}

void OpenIndividualMemberMenu(int iClient, char[] sInfo)
{
	Menu menu = CreateMenu(IndividualMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	SetMenuTitle(menu, "Информация : ");

	char sTempArray[7][128]; // 0 - Player ID | 1 - SteamID | 2 - Name | 3 - Inviter Name | 4 - Rank | 5 - Date (UTF) | 6 - Gang ID
	char sDisplayBuffer[64];

	ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "Name", iClient, sTempArray[2]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "Steam ID: %s", sTempArray[1]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "InvitedBy", iClient, sTempArray[3]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	KeyValues ConfigRanks;
	ConfigRanks = new KeyValues("Ranks");
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
	ConfigRanks.ImportFromFile(szBuffer);
	ConfigRanks.Rewind();
	if(ConfigRanks.JumpToKey(sTempArray[4]))
	{
		ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", iClient, szBuffer, iClient);
	}
	delete ConfigRanks;
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	char sFormattedTime[64];
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%x", StringToInt(sTempArray[5]));
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "DateJoined", iClient, sFormattedTime);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);
	
	if(GetClientRightStatus(iClient, "kick") || GetClientRightStatus(iClient, "ranks") || GetClientRightStatus(iClient, "bank_logs") || ga_iRank[iClient] == 0)
	{
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Management", iClient);
		menu.AddItem(sInfo, sDisplayBuffer);
	}

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int IndividualMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int iClient = param1;
			char sInfo[1024];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			char sTempArray[7][128]; // 0 - Player Id | 1 - SteamID | 2 - Name | 3 - Inviter Name | 4 - Rank | 5 - Date (UTF) | 6 - Gang ID
			ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));
			
			Menu menu1 = CreateMenu(IndividualManagementMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
			SetMenuTitle(menu1, "%T:", "Management", iClient);
			char sDisplayBuffer[64];
			if(GetClientRightStatus(iClient, "kick") && !StrEqual(sTempArray[4], "0") && CheckRankImmune(ga_iRank[iClient], sTempArray[4]))
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "KickAMember", iClient);
				Format(sInfo, sizeof(sInfo), "kick;%s;%s", sTempArray[0], sTempArray[2]);
				menu1.AddItem(sInfo, sDisplayBuffer);
			}
			if(GetClientRightStatus(iClient, "ranks") && !StrEqual(sTempArray[4], "0") && CheckRankImmune(ga_iRank[iClient], sTempArray[4]))
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Promote", iClient);
				Format(sInfo, sizeof(sInfo), "ranks;%s;%s;%s;%s", sTempArray[1], sTempArray[2], sTempArray[3], sTempArray[6]);
				menu1.AddItem(sInfo, sDisplayBuffer);
			}
			if(ga_iRank[iClient] == 0)
			{
				if(!StrEqual(ga_sSteamID[iClient], sTempArray[0]))
				{
					Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "TransferLeader", iClient);
					Format(sInfo, sizeof(sInfo), "transferleader;%s;%s;%s", sTempArray[0], sTempArray[2], sTempArray[4]);
					menu1.AddItem(sInfo, sDisplayBuffer);
				}
			}
			if(GetClientRightStatus(iClient, "bank_logs"))
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Logs", iClient);
				Format(sInfo, sizeof(sInfo), "bank_logs;%s;%s", sTempArray[0], sTempArray[6]);
				menu1.AddItem(sInfo, sDisplayBuffer, (GetClientRightStatus(iClient, "bank_logs"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			}
			

			menu1.ExitBackButton = true;


			menu1.Display(iClient, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			StartOpeningMembersMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

public int IndividualManagementMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int iClient = param1;
			char sInfo[1024];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			char sTempArray[5][128];
			ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));
			if(StrEqual(sTempArray[0], "kick"))
			{	
				char sQuery[256];
				Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
												WHERE id = %s;", 
												sTempArray[1]);
				g_hDatabase.Query(SQLCallback_Void, sQuery, 26);
				
				CPrintToChatAll("%t %t", "Prefix", "GangMemberKick", sTempArray[2], ga_sGangName[iClient]);
				
				for(int i = 1; i <= MaxClients; i++)
					if(IsValidClient(i))
						if(StringToInt(sTempArray[1]) == ga_iPlayerId[i])
						{
							API_OnExitFromGang(i);
							ResetVariables(i, false);
						}
			}
			else if(StrEqual(sTempArray[0], "ranks"))
			{	
				Format(sInfo, sizeof(sInfo), "%s;%s;%s;%s", sTempArray[1], sTempArray[2], sTempArray[3], sTempArray[4]);
				OpenPromoteDemoteMenu(iClient, sInfo);
			}
			else if(StrEqual(sTempArray[0], "transferleader"))
			{	
				int iTarget = FindTarget(0, sTempArray[2], true, false);
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gang_player \
												SET rank = '%s' \
												WHERE player_id = %i;", 
												sTempArray[3], ga_iPlayerId[iClient]);
				g_hDatabase.Query(SQLCallback_Void, sQuery, 27);

				ga_iRank[iClient] = StringToInt(sTempArray[3]);

				Format(sQuery, sizeof(sQuery), "UPDATE gang_player \
												SET rank = 0 \
												WHERE player_id = %s;", 
												sTempArray[1]);
				g_hDatabase.Query(SQLCallback_Void, sQuery, 28);
				
				if(iTarget != -1)
					ga_iRank[iTarget] = 0;
				char szName[MAX_NAME_LENGTH];
				GetClientName(iClient, szName, sizeof(szName));
				CPrintToChatAll("%t %t", "Prefix", "LeaderTransfered", szName, sTempArray[2]);
			}
			else if(StrEqual(sTempArray[0], "bank_logs"))
			{	
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "SELECT player_table.name, bank_log_table.log, bank_log_table.date \
												FROM gang_bank_log AS bank_log_table \
												INNER JOIN gang_player AS player_table \
												ON player_table.id = bank_log_table.player_id \
												WHERE bank_log_table.gang_id = %s AND bank_log_table.player_id = %s \
												ORDER BY bank_log_table.id DESC LIMIT 21;", 
												sTempArray[2], sTempArray[1]);
				g_hDatabase.Query(SQLCallback_OpenBankLogsMenu, sQuery, iClient);
			}
			
		}
		case MenuAction_Cancel:
		{
			StartOpeningMembersMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
***********************    BANK LOGS    **************************
******************************************************************/
public void SQLCallback_OpenBankLogsMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_OpenBankLogsMenu] Error (%i): %s", data, error);
		return;
	}
	
	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		Menu menu = new Menu(MenuHandler_BankLogs, MenuAction_End|MenuAction_Cancel|MenuAction_Select|MenuAction_DrawItem);

		char title[100];
		Format(title, sizeof(title), "%T", "Logs", iClient);
		SetMenuTitle(menu, title);
		SetMenuExitBackButton(menu, true);
		int i = 0;
		while(results.FetchRow())
		{
			char sPunkt[256], sTime[64], sSetchik[32];
			FormatTime(sTime, sizeof(sTime), "%d/%m/%Y (%I:%M:%S)", results.FetchInt(2));
			char sName[128];
			results.FetchString(0, sName, sizeof(sName));
			Format(sPunkt, sizeof(sPunkt), "%s - %s", sName, sTime);
			Format(sSetchik, sizeof(sSetchik), "%i", i);
			menu.AddItem(sSetchik, sPunkt);
			i++;
			//Format(sPunkt, sizeof(sPunkt), "%s", results.FetchInt(1));
			results.FetchString(1, sPunkt, sizeof(sPunkt));
			Format(sSetchik, sizeof(sSetchik), "%i", i);
			menu.AddItem(sSetchik, sPunkt);
			i++;
		}
		if(i == 0)
		{
			char sInfo[128];
			Format(sInfo, sizeof(sInfo), "%T", "NoLogs", iClient);
			menu.AddItem("", sInfo, ITEMDRAW_DISABLED);
		}
			
		DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_BankLogs(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			StartOpeningMembersMenu(param1);
		}
	}
	else if(action == MenuAction_DrawItem)
	{
		return ITEMDRAW_DISABLED;
	}
	return 0;
}

void DisplayBankMenu(int iClient)
{
	Menu menu = new Menu(MenuHandler_Bank);

	char title[100];
	Format(title, sizeof(title), "%T\n%T:", "Bank", iClient, "Balance", iClient);
	if(g_bBankRubles && g_bGameCMSExist)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankRubles[iClient], "rubles", iClient);
	}
	if(g_bBankShop)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankCredits[iClient], "shop", iClient);
	}
	if(g_bBankShopGold && g_bLShopGoldExist)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankGold[iClient], "shopgold", iClient);
	}
	//if(g_bBankWcsGold && g_bWCSLoaded)
	if(g_bBankWcsGold)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankWCSGold[iClient], "wcsgold", iClient);
	}
	if(g_bBankLkRubles && g_bLKLoaded)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankLKRubles[iClient], "lkrubles", iClient);
	}
	if(g_bBankMyJBCredits && g_bMyJBShopExist)
	{
		Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankMyJBCredits[iClient], "myjb", iClient);
	}
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	if(g_bBankRubles && g_bGameCMSExist)
	{
		Format(title, sizeof(title), "%T", "PRub", iClient);
		menu.AddItem("1", title, ((!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)) || !GetClientRightStatus(iClient, "bang_give"))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		Format(title, sizeof(title), "%T", "PURub", iClient);
		menu.AddItem("2", title, ((!GetClientRightStatus(iClient, "bank_take")) || ((!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient))))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	if(g_bBankShop)
	{
		Format(title, sizeof(title), "%T", "PCred", iClient);
		menu.AddItem("3", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		Format(title, sizeof(title), "%T", "PUCred", iClient);
		menu.AddItem("4", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	if(g_bBankShopGold && g_bLShopGoldExist)
	{
		Format(title, sizeof(title), "%T", "PGold", iClient);
		menu.AddItem("5", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		Format(title, sizeof(title), "%T", "PUGold", iClient);
		menu.AddItem("6", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	//if(g_bBankWcsGold && g_bWCSLoaded)
	if(g_bBankWcsGold)
	{
		Format(title, sizeof(title), "%T", "PWCSGold", iClient);
		menu.AddItem("7", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		Format(title, sizeof(title), "%T", "PUWCSGold", iClient);
		menu.AddItem("8", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	//if(g_bLKLoaded || g_bLKSystemLoaded)
	if(g_bBankLkRubles && g_bLKLoaded)
	{
		Format(title, sizeof(title), "%T", "PLKRub", iClient);
		menu.AddItem("9", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		Format(title, sizeof(title), "%T", "PULKRub", iClient);
		menu.AddItem("10", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	if(g_bBankMyJBCredits && g_bMyJBShopExist)
	{
		Format(title, sizeof(title), "%T", "PMyJBCredits", iClient);
		menu.AddItem("11", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		Format(title, sizeof(title), "%T", "PUMyJBCredits", iClient);
		menu.AddItem("12", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	//Format(title, sizeof(title), "%t", "Logs");
	//menu.AddItem("13", title, (GetClientRightStatus(iClient, "bank_logs"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_Bank(Handle menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));

			if(StrEqual(info ,"1"))
				g_iBankCountType[param1] = 1;
			else if(StrEqual(info ,"2"))
				g_iBankCountType[param1] = 2;
			else if(StrEqual(info ,"3"))
				g_iBankCountType[param1] = 3;
			else if(StrEqual(info ,"4"))
				g_iBankCountType[param1] = 4;
			else if(StrEqual(info ,"5"))
				g_iBankCountType[param1] = 5;
			else if(StrEqual(info ,"6"))
				g_iBankCountType[param1] = 6;
			else if(StrEqual(info ,"7"))
				g_iBankCountType[param1] = 7;
			else if(StrEqual(info ,"8"))
				g_iBankCountType[param1] = 8;
			else if(StrEqual(info ,"9"))
				g_iBankCountType[param1] = 9;
			else if(StrEqual(info ,"10"))
				g_iBankCountType[param1] = 10;
			else if(StrEqual(info ,"11"))
				g_iBankCountType[param1] = 11;
			else if(StrEqual(info ,"12"))
				g_iBankCountType[param1] = 12;

			CPrintToChat(param1, "%t %t", "Prefix", "BankAction");
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete(menu);
		}
	}
}

/*****************************************************************
*********************** INVITATION MENU **************************
******************************************************************/
void OpenInvitationMenu(int iClient)
{
	Menu menu = CreateMenu(InvitationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	
	char sInfoString[64];
	char sDisplayString[64];
	char sMenuString[64];
	
	Format(sMenuString, sizeof(sMenuString), "%T", "InviteToGang", iClient);
	SetMenuTitle(menu, sMenuString);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && i != iClient)
		{
			Format(sInfoString, sizeof(sInfoString), "%i", i);
			Format(sDisplayString, sizeof(sDisplayString), "%N", i);
			menu.AddItem(sInfoString, sDisplayString, (ga_bHasGang[i] || ga_bBlockInvites[i])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}

	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);

}

public int InvitationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{					 
	switch (action)
	{
		case MenuAction_Select:
		{
			if(!ga_bInvitationSent[param1])
			{
				char sInfo[64];
				GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
				int iUserID = StringToInt(sInfo);

				ga_iInvitation[iUserID] = param1;
				ga_bInvitationSent[param1] = true;

				if(g_bModuleSizeExist)
				{
					if(ga_iGangSize[param1] >= g_iSize + Gangs_Size_GetCurrectLvl(param1))
					{
						CPrintToChat(param1, "%t %t", "Prefix", "GangIsFull");
						return;
					}
				}
				else
				{
					if(ga_iGangSize[param1] >= g_iSize)
					{
						CPrintToChat(param1, "%t %t", "Prefix", "GangIsFull");
						return;
					}
				}

				if(!g_bInviteStyle)
				{
					CPrintToChat(iUserID, "%t %t", "Prefix", "AcceptInstructions", ga_sGangName[param1]);
					DataPack data = new DataPack();
					data.WriteCell(param1);
					data.WriteCell(iUserID);
					data.Reset();
					CreateTimer(15.0, AcceptTimer, data);
				}
				else
				{
					OpenGangInvitationMenu(iUserID);
				}
				CPrintToChat(param1, "%t %t", "Prefix", "InvitationSent");
				StartOpeningGangMenu(param1);
			}
			else
			{
				CPrintToChat(param1, "%t %t", "Prefix", "InvitationSended");
				return;
			}
			
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return;
}

public Action AcceptTimer(Handle timer, DataPack data)
{
	int iClient = data.ReadCell();
	int iTarget = data.ReadCell();
	delete data;
	if (IsValidClient(iClient) && IsValidClient(iTarget))
	{
		if (ga_bInvitationSent[iClient])
		{
			char sName[64];
			GetClientName(iTarget, sName, sizeof(sName));
			ga_bInvitationSent[iClient] = false;
			CPrintToChat(iClient, "%t %t", "Prefix", "AcceptTimeoutSender", sName);
		}
		if (ga_iInvitation[iTarget] != -1)
		{
			ga_iInvitation[iTarget] = -1;
			CPrintToChat(iClient, "%t %t", "Prefix", "AcceptTimeoutReceiver", ga_sGangName[iClient]);
		}
	}
		
}


void OpenGangInvitationMenu(int iClient)
{
	if(!IsValidClient(iClient))
	{
		return;
	}
	Menu menu = CreateMenu(SentInviteMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	char sDisplayString[64];
	char sTitleString[64];
	
	Format(sTitleString, sizeof(sTitleString), "%T", "GangInvitation", iClient);
	SetMenuTitle(menu, sTitleString);

	int sender = ga_iInvitation[iClient];
	char szName[MAX_NAME_LENGTH];
	GetClientName(sender, szName, sizeof(szName));

	Format(sDisplayString, sizeof(sDisplayString), "%T", "InviteString", iClient, szName);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T", "WouldYouLikeToJoin", iClient, ga_sGangName[sender]);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldLikeTo", iClient);
	menu.AddItem("yes", sDisplayString);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldNotLikeTo", iClient);
	menu.AddItem("no", sDisplayString);

	menu.Display(iClient, 15);
}

public int SentInviteMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if(!IsValidClient(param1))
	{
		return;
	}
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			int sender = ga_iInvitation[param1];
			
			if(StrEqual(sInfo, "yes"))
			{
				ga_sGangName[param1] = ga_sGangName[sender];
				ga_iDateJoined[param1] = GetTime();
				ga_bHasGang[param1] =  true;
				ga_bSetName[param1] = false;
				
				ga_iScore[param1] = ga_iScore[sender];
				ga_iBankRubles[param1] = ga_iBankRubles[sender];
				ga_iBankCredits[param1] = ga_iBankCredits[sender];
				ga_iBankGold[param1] = ga_iBankGold[sender];
				ga_iBankWCSGold[param1] = ga_iBankWCSGold[sender];
				ga_iBankLKRubles[param1] = ga_iBankLKRubles[sender];
				ga_iExtendCount[param1] = ga_iExtendCount[sender];
				ga_iGangSize[param1] = ++ga_iGangSize[sender];
				
				ga_bInvitationSent[sender] = false;

				char szName[MAX_NAME_LENGTH];
				GetClientName(sender, szName, sizeof(szName));
				ga_sInvitedBy[param1] = szName;
				ga_iRank[param1] = GetLastConfigRank();
				UpdateSQL(param1);
				
				GetClientName(param1, szName, sizeof(szName));
				
				CPrintToChatAll("%t %t", "Prefix", "GangJoined", szName, ga_sGangName[param1]);
			}
			else if(StrEqual(sInfo, "no"))		
			{
				ga_bInvitationSent[sender] = false;
			}
		}
		case MenuAction_Cancel:
		{
			int sender = ga_iInvitation[param1];
			ga_bInvitationSent[sender] = false;
			
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			int sender = ga_iInvitation[param1];
			ga_bInvitationSent[sender] = false;
			
			delete menu;
		}
	}
	return;
}

/*****************************************************************
**********************	TOP GANGS MENU	**************************
******************************************************************/
public void StartOpeningTopGangsMenu(int iClient)
{
	char ItemName[52], text[76];
	Menu hMenu = new Menu(ShowStatisticMenu_CallBack);
	
	char sTitleString[64];
	Format(sTitleString, sizeof(sTitleString), "%T", "TopGangs", iClient);
	hMenu.SetTitle(sTitleString);
	
	for(int i; i < g_iStatsCount; i++)
	{
		char sInfo[128];
		g_hStatName.GetString(i, ItemName, sizeof(ItemName));
		FormatEx(text, sizeof(text), "%T", ItemName, iClient);
		FormatEx(sInfo, sizeof(sInfo), "%i;%s", g_hStatID.Get(i, 0, false), ItemName);
		hMenu.AddItem(sInfo, text);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}

public int ShowStatisticMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: 
			delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[128], sBuffers[2][64];
			hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, ";", sBuffers, 2, 64);
			int index = -1;
			if((index = g_hStatsArray.FindString(sBuffers[1])) != -1)
			{
				DataPack hPack;
				hPack = g_hStatsArray.Get(index+1);
				hPack.Reset();
				Handle hPlugin = hPack.ReadCell();
				Function fncCallback = hPack.ReadFunction();
				if(IsCallValid(hPlugin, fncCallback))
				{
					Call_StartFunction(hPlugin, fncCallback);
					Call_PushCell(iClient);
					Call_PushCell(StringToInt(sBuffers[0]));
					Call_PushString(sBuffers[1]);
					Call_Finish();
				}
			}
		}
		case MenuAction_Cancel:
			if(iItem == MenuCancel_ExitBack)
				StartOpeningGangMenu(iClient);
	}
}

/*****************************************************************
*********************	DISBAND MENU	**************************
******************************************************************/
void OpenDisbandMenu(int iClient)
{
	Menu menu = CreateMenu(DisbandMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempString[256];
	
	Format(tempString, sizeof(tempString), "%T", "DisbandGang", iClient);
	SetMenuTitle(menu, tempString);

	Format(tempString, sizeof(tempString), "%T", "DisbandConfirmation", iClient);
	menu.AddItem("", tempString, ITEMDRAW_DISABLED);
	
	Format(tempString, sizeof(tempString), "%T", "YesDisband", iClient);
	menu.AddItem("disband", tempString);

	Format(tempString, sizeof(tempString), "%T", "NoDisband", iClient);
	menu.AddItem("no", tempString);

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int DisbandMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if(StrEqual(sInfo, "disband"))
			{
				RemoveFromGang(param1);
			}
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
*******************	 ADMIN PROMOTION MENU  ***********************
******************************************************************/
void OpenPromoteDemoteMenu(int iClient, const char[] sInfo)
{
	char sTempArray[4][128];
	ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

	Menu menu = CreateMenu(AdministrationPromoDemoteMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	Format(tempBuffer, sizeof(tempBuffer), "%T", "GangMembersRanks", iClient);
	SetMenuTitle(menu, tempBuffer);
	
	char sInfoString[1025];
	
	KeyValues ConfigRanks;
	ConfigRanks = new KeyValues("Ranks");
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
	ConfigRanks.ImportFromFile(szBuffer);
	ConfigRanks.Rewind();
	if(ConfigRanks.GotoFirstSubKey())
	{
		do
		{
			ConfigRanks.GetSectionName(szBuffer, sizeof(szBuffer));
			if(!StrEqual("0", szBuffer))
			{
				Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%s", szBuffer, sTempArray[0], sTempArray[3], sTempArray[1]);
				char sName[128];
				ConfigRanks.GetString("Name", sName, sizeof(sName));
				Format(tempBuffer, sizeof(tempBuffer), "%T", sName, iClient);
				menu.AddItem(sInfoString, tempBuffer, (StrEqual(sTempArray[2], szBuffer))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
		} while(ConfigRanks.GotoNextKey());
	}
	delete ConfigRanks;
	
	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AdministrationPromoDemoteMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			char sTempArray[4][128];
			ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

			char sQuery[300];
			
			Format(sQuery, sizeof(sQuery), "UPDATE gang_player \
											SET rank = '%s' \
											WHERE steam_id = '%s';", 
											sTempArray[0], sTempArray[1]);
			g_hDatabase.Query(SQLCallback_Void, sQuery, 29);
			
			char sRank[128];
			KeyValues ConfigRanks;
			ConfigRanks = new KeyValues("Ranks");
			char szBuffer[256];
			BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
			ConfigRanks.ImportFromFile(szBuffer);
			ConfigRanks.Rewind();
			if(ConfigRanks.JumpToKey(sTempArray[0])) // Попытка перейти к ключу
			{
				ConfigRanks.GetString("Name", sRank, sizeof(sRank));
			}
			delete ConfigRanks;
			
			char sSteamID[32];
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i))
				{
					if(StrEqual(ga_sGangName[i],sTempArray[2]))
					{
						CPrintToChat(i, "%t %t", "Prefix", "ChangeRank", sTempArray[3], sRank);
					}
					GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
					if(StrEqual(sSteamID, sTempArray[0]))
					{
						LoadSteamID(i);
						break;
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
*********************  ADMIN MAIN MENU	**************************
******************************************************************/
void OpenAdministrationMenu(int iClient)
{
	if(!IsValidClient(iClient))
	{
		return;
	}
	Menu menu = CreateMenu(AdministrationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	Format(tempBuffer, sizeof(tempBuffer), "%T", "GangAdmin", iClient);
	SetMenuTitle(menu, tempBuffer);
	
	char sDisplayString[128];
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "InviteToGang", iClient);
	//if(g_bModuleSizeExist)
	//	menu.AddItem("invite", sDisplayString, (ga_bHasGang[iClient] && GetClientRightStatus(iClient, "invite") && (ga_iGangSize[iClient] < g_iSize + Gangs_Size_GetCurrectLvl(iClient)))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	//else
	//	menu.AddItem("invite", sDisplayString, (ga_bHasGang[iClient] && GetClientRightStatus(iClient, "invite")	 && (ga_iGangSize[iClient] < g_iSize))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	//Format(sDisplayString, sizeof(sDisplayString), "%T", "KickAMember", iClient);
	//menu.AddItem("kick", sDisplayString, (GetClientRightStatus(iClient, "kick"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	if(g_bRenamePriceSellMode == 0 && g_bGameCMSExist)
	{
		int Discount;
		if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
			Discount = GameCMS_GetGlobalDiscount();
		else Discount = GameCMS_GetClientDiscount(iClient);
		
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, Colculate(iClient, g_iRenamePrice, Discount), "rubles", iClient);
		if(g_bEnableBank && g_bBankRubles && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (!GetClientRightStatus(iClient, "rename") || ga_iBankRubles[iClient] < g_iRenamePrice || (!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		else
			menu.AddItem("rename", sDisplayString, (!GetClientRightStatus(iClient, "rename") || GameCMS_GetClientRubles(iClient) < g_iRenamePrice || (!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}
	else if(g_bRenamePriceSellMode == 1)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "shop", iClient);
		if(g_bEnableBank && g_bBankShop && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankCredits[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
		{
			if(g_bShopLoaded)
				menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && Shop_GetClientCredits(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			else if(g_bStoreLoaded)
				menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && Store_GetClientCredits(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
	}
	else if(g_bRenamePriceSellMode == 2 && g_bLShopGoldExist)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "shopgold", iClient);
		if(g_bEnableBank && g_bBankShopGold && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankGold[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && Shop_GetClientGold(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_bRenamePriceSellMode == 3)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "wcsgold", iClient);
		if(g_bEnableBank && g_bBankWcsGold && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankWCSGold[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && WCS_GetGold(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_bRenamePriceSellMode == 4 && g_bLKLoaded)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "lkrubles", iClient);
		if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankLKRubles[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && LK_GetBalance(iClient, LK_Cash) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_bRenamePriceSellMode == 5 && g_bMyJBShopExist)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "myjb", iClient);
		if(g_bEnableBank && g_bBankMyJBCredits && g_bRenameBank)
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankMyJBCredits[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && MyJailShop_GetCredits(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	//Format(sDisplayString, sizeof(sDisplayString), "%T", "Promote", iClient);
	//menu.AddItem("promote", sDisplayString, (GetClientRightStatus(iClient, "ranks"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "Disband", iClient);
	menu.AddItem("disband", sDisplayString, (ga_iRank[iClient] == 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

	if(g_iCreateGangDays > 0)
	{
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Extend", iClient);
		menu.AddItem("extend", sDisplayString, (GetClientRightStatus(iClient, "extend"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	//Format(sDisplayString, sizeof(sDisplayString), "%T", "TransferLeader", iClient);
	//menu.AddItem("transferleader", sDisplayString, (ga_iRank[iClient] == 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);

}

public int AdministrationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if(!IsValidClient(param1))
	{
		return;
	}
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			//if(StrEqual(sInfo, "kick"))
			//{
			//	OpenAdministrationKickMenu(param1);
			//}
			if(StrEqual(sInfo, "rename"))
			{
				for(int i = 1; i <= 5; i++)
				{
					CPrintToChat(param1, "%t %t", "Prefix", "GangName");
				}
				ga_bRename[param1] = true;
			}
			//else if(StrEqual(sInfo, "promote"))
			//{
			//	OpenAdministrationPromotionMenu(param1);
			//}
			else if(StrEqual(sInfo, "disband"))
			{
				OpenDisbandMenu(param1);
			}
			else if(StrEqual(sInfo, "extend"))
			{
				char szQuery[256];
				Format( szQuery, sizeof( szQuery ),"SELECT end_date FROM gangs_groups WHERE gang = '%s' AND server_id = %i", ga_sGangName[param1], g_iServerID);
				g_hDatabase.Query(SQLCallback_OpenExtendMenu, szQuery, param1);
			}
			//else if(StrEqual(sInfo, "transferleader"))
			//{
			//	OpenTransferLeaderMenu(param1);
			//}
			//else if(StrEqual(sInfo, "invite"))
			//{
			//	OpenInvitationMenu(param1);
			//}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

public void SQLCallback_OpenExtendMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_OpenExtendMenu] Error (%i): %s", data, error);
		return;
	}
	
	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		while(results.FetchRow())
		{
			OpenAdministrationMenuExtendGang(iClient, results.FetchInt(0));
		}
	}
}

void OpenAdministrationMenuExtendGang(int iClient, int endtime)
{
	if(!IsValidClient(iClient))
	{
		return;
	}
	Menu menu = CreateMenu(AdministrationMenuExtend_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[512], sDisplayString[128];
	
	int days = (endtime - GetTime())/86400;
	if(days<0) days = 0;
	
	int iPrice;
	if(g_bExtendCostFormula)
		iPrice = g_iExtendCostPrice+g_iExtendModifier*GetGangLvl(ga_iScore[iClient]);
	else 
		iPrice = g_iExtendCostPrice;
		
	if(g_iExtendPriceSellMode == 0 && g_bGameCMSExist && GameCMS_Registered(iClient))
	{
		int Discount;
		if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
			Discount = GameCMS_GetGlobalDiscount();
		else Discount = GameCMS_GetClientDiscount(iClient);
		
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T\n%T", "GangExtend", iClient, days, Colculate(iClient, iPrice, Discount), "rubles", iClient, "Want?", iClient, "YourDiscount", iClient, Discount);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankRubles && g_bExtendBank)
			menu.AddItem("yes", sDisplayString, (ga_iBankRubles[iClient] >= Colculate(iClient, iPrice, Discount))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("yes", sDisplayString, (GameCMS_GetClientRubles(iClient) >= Colculate(iClient, iPrice, Discount))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_iExtendPriceSellMode == 1)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "shop", iClient, "Want?", iClient);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankShop && g_bExtendBank)
		{
			menu.AddItem("yes", sDisplayString, (ga_iBankCredits[iClient] >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		else
		{
			if(g_bShopLoaded)
				menu.AddItem("yes", sDisplayString, (Shop_GetClientCredits(iClient) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			else if(g_bStoreLoaded)
				menu.AddItem("yes", sDisplayString, (Store_GetClientCredits(iClient) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
	}
	else if(g_iExtendPriceSellMode == 2 && g_bLShopGoldExist)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "shopgold", iClient, "Want?", iClient);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankShopGold && g_bExtendBank)
			menu.AddItem("yes", sDisplayString, (ga_iBankGold[iClient] >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("yes", sDisplayString, (Shop_GetClientGold(iClient) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_iExtendPriceSellMode == 3)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "wcsgold", iClient, "Want?", iClient);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankWcsGold && g_bExtendBank)
			menu.AddItem("yes", sDisplayString, (ga_iBankWCSGold[iClient] >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("yes", sDisplayString, (WCS_GetGold(iClient) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_iExtendPriceSellMode == 4 && g_bLKLoaded)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "lkrubles", iClient, "Want?", iClient);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankLkRubles && g_bExtendBank)
			menu.AddItem("yes", sDisplayString, (ga_iBankLKRubles[iClient] >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("yes", sDisplayString, (LK_GetBalance(iClient, LK_Cash) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else if(g_iExtendPriceSellMode == 5 && g_bMyJBShopExist)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "myjb", iClient, "Want?", iClient);		
	
		//if(days>7)
		//    Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
		SetMenuTitle(menu, tempBuffer);
	
		Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
		
		if(g_bEnableBank && g_bBankMyJBCredits && g_bExtendBank)
			menu.AddItem("yes", sDisplayString, (ga_iBankMyJBCredits[iClient] >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		else
			menu.AddItem("yes", sDisplayString, (MyJailShop_GetCredits(iClient) >= iPrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
	
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "No", iClient);
	menu.AddItem("no", sDisplayString);
	

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AdministrationMenuExtend_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if(!IsValidClient(param1))
	{
		return;
	}
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if(StrEqual(sInfo, "yes"))
			{
				char szQuery[256];
				Format( szQuery, sizeof( szQuery ),"SELECT end_date FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", ga_sGangName[param1], g_iServerID);
				g_hDatabase.Query(SQLCallback_ExtendGang, szQuery, param1);
			}
			else if(StrEqual(sInfo, "no"))
			{
				OpenAdministrationMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

public void SQLCallback_ExtendGang(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_ExtendGang] Error (%i): %s", data, error);
		return;
	}
	
	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		while(results.FetchRow())
		{
			SetTimeEndGang(ga_iGangId[iClient], GetTime()+2629743);
			CPrintToChat(iClient, "%t %t", "Prefix", "GangExtended");
			char sQuery[300];
			int iPrice;
			if(g_bExtendCostFormula)
				iPrice = g_iExtendCostPrice+g_iExtendModifier*GetGangLvl(ga_iScore[iClient]);
			else 
				iPrice = g_iExtendCostPrice;
			if(g_iExtendPriceSellMode == 0 && g_bGameCMSExist)
			{
				int Discount;
				if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
					Discount = GameCMS_GetGlobalDiscount();
				else 
					Discount = GameCMS_GetClientDiscount(iClient);
				
				if(g_bEnableBank && g_bBankRubles && g_bExtendBank)
					SetBankRubles(iClient, ga_iBankRubles[iClient] - Colculate(iClient, iPrice, Discount));
				else
					GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, iPrice, Discount));
			
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i рублей", iClient, Colculate(iClient, iPrice, Discount));
			}
			else if(g_iExtendPriceSellMode == 1)
			{
				if(g_bEnableBank && g_bBankShop && g_bExtendBank)
					SetBankCredits(iClient, ga_iBankCredits[iClient] - iPrice);
				else
				{
					if(g_bShopLoaded)
						Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - iPrice);
					else if(g_bStoreLoaded)
						Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - iPrice);
				}
			
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i кредитов", iClient, iPrice);
			}
			else if(g_iExtendPriceSellMode == 2 && g_bLShopGoldExist)
			{
				if(g_bEnableBank && g_bBankShopGold && g_bExtendBank)
					SetBankGold(iClient, ga_iBankGold[iClient] - iPrice);
				else
					Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - iPrice);
			
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i голды", iClient, iPrice);
			}
			//else if(g_iExtendPriceSellMode == 3 && g_bWCSLoaded)
			else if(g_iExtendPriceSellMode == 3)
			{
				if(g_bEnableBank && g_bBankWcsGold && g_bExtendBank)
					SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] - iPrice);
				else
					WCS_TakeGold(iClient, iPrice);
			
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i WCS голды", iClient, iPrice);
			}
			else if(g_iExtendPriceSellMode == 4 && g_bLKLoaded)
			{
				if(g_bEnableBank && g_bBankLkRubles && g_bExtendBank)
					SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] - iPrice);
				else
					LK_ChangeBalance(iClient, LK_Cash, LK_Take, iPrice);
							
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i lk рублей", iClient, iPrice);
			}
			else if(g_iExtendPriceSellMode == 5 && g_bMyJBShopExist)
			{
				if(g_bEnableBank && g_bBankMyJBCredits && g_bExtendBank)
					SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] - iPrice);
				else
					MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - iPrice);
							
				if(g_bLog)
					LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i lk рублей", iClient, iPrice);
			}
			else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
			
			ga_iExtendCount[iClient]++;
			for(int i = 1; i <= MaxClients; i++)
				if(IsValidClient(i) && iClient != i)
					if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
						ga_iExtendCount[i]++;

			Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
											SET extend_count = '%i' \
											WHERE id = %i AND server_id = %i;", 
											ga_iExtendCount[iClient], ga_iGangId[iClient], g_iServerID);
			g_hDatabase.Query(SQLCallback_Void, sQuery, 30);
		}
	}
}

/*****************************************************************
*******************	   LEAVE CONFIRMATION	  ********************
******************************************************************/
void OpenLeaveConfirmation(int iClient)
{
	Menu menu = CreateMenu(LeaveConfirmation_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "LeaveGang", iClient);
	SetMenuTitle(menu, tempBuffer);
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "AreYouSure", iClient);
	menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
	if(ga_iRank[iClient] == 0)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T", "OwnerWarning", iClient);
		menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
	}

	Format(tempBuffer, sizeof(tempBuffer), "%T", "YesLeave", iClient);
	menu.AddItem("yes", tempBuffer);
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "NoLeave", iClient);
	menu.AddItem("no", tempBuffer);

	menu.ExitBackButton = true;

	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int LeaveConfirmation_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if(StrEqual(sInfo, "yes"))
			{
				RemoveFromGang(param1);
			}
			else if(StrEqual(sInfo, "no"))
			{
				StartOpeningGangMenu(param1);
			}

		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}