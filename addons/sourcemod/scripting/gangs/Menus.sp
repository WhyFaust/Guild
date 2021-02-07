public Action Command_Gang(int iClient, int args)
{
	if (!IsValidClient(iClient))
	{
		ReplyToCommand(iClient, "[SM] %t", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (g_bTerroristOnly && GetClientTeam(iClient) != 2)
	{
		ReplyToCommand(iClient, "[SM] %t", "WrongTeam");
		return Plugin_Handled;
	}
	StartOpeningGangMenu(iClient);
	return Plugin_Handled;
}

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
		Format(sQuery, sizeof(sQuery), "SELECT end_date FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
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
			Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_players WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
			g_hDatabase.Query(SQLCallback_TwoOpenGangMenu, sQuery, iClient);
		}
	}
}

public void SQLCallback_TwoOpenGangMenu(Database db, DBResultSet results, const char[] error, int data)
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
	else 
	{
		ga_iGangSize[iClient] = results.RowCount;
		OpenGangsMenu(iClient);
	}
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
				{
					Format(sString, sizeof(sString), "%s%T N/A\n", sString
												, "rubles", iClient);
				}
				else
				{
					Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "rubles", iClient, GameCMS_GetClientRubles(iClient));
				}
			}
			else
			{
				Format(sString, sizeof(sString), "%s%T %i\n", sString
											, "rubles", iClient, GameCMS_GetClientRubles(iClient));
			}
		}
		else if(g_bMenuValue == 2)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "shop", iClient, Shop_GetClientCredits(iClient));
		}
		else if(g_bMenuValue == 3 && g_bLShopGoldExist)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "shopgold", iClient, Shop_GetClientGold(iClient));
		}
		else if(g_bMenuValue == 4)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "wcsgold", iClient, WCS_GetGold(iClient));
		}
		else if(g_bMenuValue == 5 && g_bLKLoaded)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "lkrubles", iClient, LK_GetClientCash(iClient));
		}
		else if(g_bMenuValue == 6 && g_bMyJBShopExist)
		{
			Format(sString, sizeof(sString), "%s%T %i\n", sString
												, "myjb", iClient, MyJailShop_GetCredits(iClient));
		}
		
		if(ga_bHasGang[iClient])
		{
			Format(sString, sizeof(sString), "%s%T \n", sString, "CurrentGang", iClient, ga_sGangName[iClient], "Level", GetGangLvl(ga_iScore[iClient]));
			int days= (ga_iEndTime[iClient]-GetTime())/86400;
			if(days<0) days = 0;
			Format(sString, sizeof(sString), "%s%T \n", sString, "GangExpired", iClient, days);
		}
		else
			Format(sString, sizeof(sString), "%s%T", sString, "NoGang", iClient);
		
		SetMenuTitle(menu, sString);
		
		char sDisplayBuffer[128];
		
		if(!ga_bHasGang[iClient])
		{
			if(g_bCreateGangSellMode == 0 && g_bGameCMSExist)
			{
				int Discount;
				if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
					Discount = GameCMS_GetGlobalDiscount();
				else Discount = GameCMS_GetClientDiscount(iClient);
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T (%T %i%%)", "CreateAGang", iClient, Colculate(iClient, g_iCreateGangPrice, Discount), "rubles", iClient, "Sale", Discount);
				menu.AddItem("create", sDisplayBuffer, (GameCMS_GetClientRubles(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
			}
			else if(g_bCreateGangSellMode == 1)
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "CreateAGang", iClient, g_iCreateGangPrice, "shop");
				menu.AddItem("create", sDisplayBuffer, (Shop_GetClientCredits(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
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
				menu.AddItem("create", sDisplayBuffer, (LK_GetClientCash(iClient) < g_iCreateGangPrice)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
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
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "BlockInvites", iClient);
			}
			else
			{
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "UnblockInvites", iClient);
			}
			
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
		{
			SetFailState("[Gangs] Error opening info file (addons/sourcemod/configs/gangs/info.ini)");
		}
	
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
		case MenuAction_End:	// Меню завершилось
			delete hPanel;
		case MenuAction_Select:
		{
			if(option == 1)
			{
				char sSteamID[64];
				GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID));
				CPrintToChat(iClient, "%t Ваш SteamID: %s", "Prefix", sSteamID);
			}
			else if(option == 2)
				CPrintToChat(iClient, "%t Всего доброго ♥", "Prefix");
			else if(option == 3)
				StartOpeningTopGangsMenu(iClient);
		}
	}
}

public int GangsMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	if (!IsValidClient(param1))
	{
		return;
	}
	
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "create"))
			{
				//LK_LogMSG("Игрок %s купил банду за %i рублей",param1,g_iCreateGangPrice);
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
			//else if (StrEqual(sInfo, "members"))
			//{
			//	StartOpeningMembersMenu(param1);
			//}
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
	{
		return;
	}
	
	ga_bBlockInvites[iClient] = !ga_bBlockInvites[iClient]; // toggle
	
	char sQuery[128];
	if (!ga_bHasPref[iClient])
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_prefs (pref, steamid) VALUES('%i', '%s');", ga_bBlockInvites[iClient], ga_sSteamID[iClient]);
		ga_bHasPref[iClient] = true;
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE gangs_prefs SET pref = '%i' WHERE steamid = '%s';", ga_bBlockInvites[iClient], ga_sSteamID[iClient]);
	}
	g_hDatabase.Query(SQLCallback_Void, sQuery);
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
			delete hMenu;
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
			if(iItem == MenuCancel_ExitBack)
				StartOpeningGangMenu(iClient);
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
			delete hMenu;
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
			if(iItem == MenuCancel_ExitBack)
				StartOpeningGangMenu(iClient);
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
		Format(sQuery, sizeof(sQuery), "SELECT gang, %s FROM gangs_statistics ORDER BY %s DESC;", g_sDbStatisticName, g_sDbStatisticName);
		g_hDatabase.Query(SQL_Callback_StatMenu, sQuery, iClient);
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
		char sGangName[128];
		g_iGangAmmount = 0;
		ga_iTempInt2[iClient] = 1;
		bool status = false;
		while (results.FetchRow())
		{
			g_iGangAmmount++;
			results.FetchString(0, sGangName, sizeof(sGangName));
			if(!StrEqual(sGangName,ga_sGangName[iClient],true) && !status)
				ga_iTempInt2[iClient]++;
			else
			{
				status = true;
			}
			
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
		int iLen = 2*strlen(ga_sGangName[iClient])+1;
		char[] szEscapedGang = new char[iLen];
		g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

		char sQuery[256];
		Format(sQuery, sizeof(sQuery), "SELECT gang, playername, date FROM gangs_players WHERE gang = '%s' AND rank = 0 AND server_id = %i;", szEscapedGang, g_iServerID);
		g_hDatabase.Query(SQL_Callback_OpenStatistics, sQuery, iClient);
	}
}

public void SQL_Callback_OpenStatistics(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQL_Callback_OpenStatistics] Error (%i): %s", data, error);
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
		//menu.SetTitle("Лучшие банды");
		char sTitleString[64];
		Format(sTitleString, sizeof(sTitleString), "%T %s", "Stat", iClient, sTempArray[0]);
		menu.SetTitle(sTitleString);

		//Format(sDisplayString, sizeof(sDisplayString), "%T : %s %t", "MenuGangName", iClient, sTempArray[0], "Level", GetGangLvl(ga_iScore[iClient]));
		//menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i %T", "Score", iClient, ga_iTempInt1[iClient], ((g_iScoreExpInc*GetGangLvl(ga_iScore[iClient])/2)*(GetGangLvl(ga_iScore[iClient])+1)), "Level", iClient, GetGangLvl(ga_iScore[iClient]));
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		if(g_bStatisticRating)
		{
			Format(sDisplayString, sizeof(sDisplayString), "%T : %i", "Rating", iClient, Gangs_StatisticRating_GetClientRating(iClient));
			menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);
		}

		//int days= (ga_iEndTime[iClient]-GetTime())/86400;
		//if(days<0) days = 0;
		//Format(sDisplayString, sizeof(sDisplayString), "%t", "GangExpired", days);
		//menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);
		
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