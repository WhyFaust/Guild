void DB_OnPluginStart()
{
	DB_Connect();
}

void DB_Connect()
{
	if (g_hDatabase != null)
		return;

	if (SQL_CheckConfig("gangs"))
	{
		Database.Connect(OnDBConnect, "gangs");
	}
	else
	{
		SetFailState("[OnDBConnect] Can not find \"gangs\" in databases.cfg ");
		return;
	}

}

public void OnDBConnect(Database hDatabase, const char[] szError, any data)
{
	if (hDatabase == null || szError[0])
	{
		SetFailState("OnDBConnect %s", szError);
		return;
	}

	g_hDatabase = hDatabase;
	
	CreateTables();
}

void CreateTables()
{
	Transaction hTxn = new Transaction();
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_group (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					name varchar(32) NOT NULL, \
					server_id int(16) NOT NULL DEFAULT 0, \
					create_date int(32) NOT NULL, \
					end_date int(32) NOT NULL, \
					extend_count int(16) NOT NULL DEFAULT 0, \
					rubles int(32) NOT NULL DEFAULT 0, \
					credits int(32) NOT NULL DEFAULT 0, \
					gold int(32) NOT NULL DEFAULT 0, \
					wcs_gold int(32) NOT NULL DEFAULT 0, \
					lk_rubles int(32) NOT NULL DEFAULT 0, \
					myjb_credits int(32) NOT NULL DEFAULT 0, \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_player (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					gang_id int(20) NOT NULL, \
					steam_id varchar(32) NOT NULL, \
					name varchar(32) NOT NULL, \
					rank int(16) NOT NULL, \
					inviter_name varchar(30) NULL DEFAULT NULL, \
					invite_date int(32) NOT NULL, \
					FOREIGN KEY (gang_id)  REFERENCES gang_group (id), \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_statistic (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					gang_id int(20) NOT NULL, \
					FOREIGN KEY (gang_id)  REFERENCES gang_group (id), \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_perk (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					gang_id int(20) NOT NULL, \
					FOREIGN KEY (gang_id)  REFERENCES gang_group (id), \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_bank_log (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					gang_id int(20) NOT NULL, \
					player_id int(20) NOT NULL, \
					log varchar(256) NOT NULL, \
					date int(32) DEFAULT NULL, \
					FOREIGN KEY (gang_id)  REFERENCES gang_group (id), \
					FOREIGN KEY (player_id)  REFERENCES gang_player (id), \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	hTxn.AddQuery("CREATE TABLE IF NOT EXISTS gang_pref (\
					id int(20) NOT NULL AUTO_INCREMENT, \
					steamid varchar(32) NOT NULL, \
					pref int(16) NOT NULL, \
					PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	g_hDatabase.Execute(hTxn, SQLCallback_TransactionSuccess, SQLCallback_TransactionFailure);

	char sQuery[300];
	FormatEx(sQuery, sizeof(sQuery), "SELECT %s \
									FROM gang_statistic;", 
									g_sDbStatisticName);
	g_hDatabase.Query(SQLCallback_CreateStatisticTables, sQuery, 7);
}

public void SQLCallback_TransactionSuccess(Database db, any data, int numQueries, Handle[] results, any[] queryData)
{
	Call_StartForward(hGangs_OnLoaded);
	Call_Finish();
}

public void SQLCallback_TransactionFailure(Database db, any data, int numQueries, const char[] sError, int failIndex, any[] queryData)
{
	if(sError[0])
	{
		LogError("[SQLCallback_TransactionFailure] Error : %s (%s)", sError, queryData[failIndex]);
		return;
	}
}

public void SQLCallback_CreateStatisticTables(Database db, DBResultSet hResults, const char[] sError, int data)
{
	if(sError[0])
	{
		if(StrContains(sError, "Duplicate column name", false))
		{
			char sQuery[300];
			FormatEx(sQuery, sizeof(sQuery), "ALTER TABLE gang_statistic \
											ADD %s int(16) NOT NULL DEFAULT 0;", 
											g_sDbStatisticName);
			g_hDatabase.Query(SQLCallback_CreateTables, sQuery, 8);
		}
		else
		{
			LogError("[SQLCallback_CreateStatisticTables] Error :  %s", sError);
		}

		return;
	}

	if(hResults.FetchRow())
		return;
}

public void SQLCallback_CreateTables(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_CreateTables] Error (%i): %s", data, error);
		return;
	}
}

/*****************************************************************
*******************	       LOAD PLAYER	      ********************
******************************************************************/
void LoadSteamID(int iClient)
{
	if(g_bPluginEnabled)
	{
		if(!IsValidClient(iClient))
			return;

		GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
		if(StrContains(ga_sSteamID[iClient], "STEAM_1", true) == -1) //if ID is invalid
		{
			CreateTimer(5.0, RefreshSteamID, iClient, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(g_hDatabase == null) //connect not loaded - retry to give it time
		{
			CreateTimer(1.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			char sQuery[1000];
			Format(sQuery, sizeof(sQuery), "SELECT player_table.id, gang_id, rank, inviter_name, invite_date \
											FROM gang_player AS player_table \
											INNER JOIN gang_group AS gang_table \
											ON player_table.gang_id = gang_table.id \
											WHERE steam_id = '%s';", 
											ga_sSteamID[iClient]);
			g_hDatabase.Query(SQLCallback_CheckSQL_Player, sQuery, iClient);
			
			if(g_bDebug)
				LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Load SteamID for %N(%i) SteamID: %s", iClient, iClient, ga_sSteamID[iClient]);

			Format(sQuery, sizeof(sQuery), "SELECT pref \
											FROM gang_pref \
											WHERE steamid = '%s';", 
											ga_sSteamID[iClient]);
			g_hDatabase.Query(SQLCallback_GetPreference, sQuery, iClient);
		}
	}
}

public void SQLCallback_GetPreference(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_GetPreference] Error (%i): %s", iClient, error);
		return;
	}
	
	if(!IsValidClient(iClient))
		return;
	
	if(results.FetchRow())
	{
		ga_bBlockInvites[iClient] = view_as<bool>(results.FetchInt(0));
	}
}

public void SQLCallback_CheckSQL_Player(Database db, DBResultSet result, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckSQL_Player] Error (%i): %s", data, error);
		return;
	}

	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		if(result.RowCount == 1)
		{
			result.FetchRow();
			
			ga_iPlayerId[iClient] = result.FetchInt(0);
			ga_iGangId[iClient] = result.FetchInt(1);
			ga_iRank[iClient] = result.FetchInt(2);
			result.FetchString(3, ga_sInvitedBy[iClient], sizeof(ga_sInvitedBy[]));
			ga_iDateJoined[iClient] = result.FetchInt(4);
			
			ga_bHasGang[iClient] = true;
			ga_bLoaded[iClient] = true;

			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT name, rubles, credits, gold, wcs_gold, lk_rubles, myjb_credits \
												FROM gang_group \
												WHERE id = %i;", 
												ga_iGangId[iClient]);
			g_hDatabase.Query(SQLCallback_CheckSQL_Groups, sQuery, iClient);
		}
		else
		{
			if(result.RowCount > 1)
			{
				LogError("Player %L has multiple entries under their ID. Running script to clean up duplicates and keep original entry (oldest)", iClient);
				CreateTimer(20.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if(g_hDatabase == null)
			{
				CreateTimer(2.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				ga_bHasGang[iClient] = false;
				ga_bLoaded[iClient] = true;
			}
		}
	}
}

public void SQLCallback_CheckSQL_Groups(Database db, DBResultSet results, const char[] error, int data)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckSQL_Groups] Error (%i): %s", data, error);
		return;
	}

	int iClient = data;
	if(!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		if(results.RowCount == 1 && results.FetchRow())
		{
			results.FetchString(0, ga_sGangName[iClient], sizeof(ga_sGangName[]));
			ga_iBankRubles[iClient] = results.FetchInt(1);
			ga_iBankCredits[iClient] = results.FetchInt(2);
			ga_iBankGold[iClient] = results.FetchInt(3);
			ga_iBankWCSGold[iClient] = results.FetchInt(4);
			ga_iBankLKRubles[iClient] = results.FetchInt(5);
			ga_iBankMyJBCredits[iClient] = results.FetchInt(6);

			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT %s \
											FROM gang_statistic \
											WHERE gang_id = %i;", 
											g_sDbStatisticName, ga_iGangId[iClient], g_iServerID);
			g_hDatabase.Query(SQLCallback_Kills, sQuery, iClient);
		}
	}
}

public void SQLCallback_Kills(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_Kills] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;
	
	if(results.FetchRow())
	{
			ga_iScore[iClient] = results.FetchInt(0);
			Call_StartForward(hGangs_OnPlayerLoaded);
			Call_PushCell(iClient);
			Call_Finish();
	}
}

/*****************************************************************
***********************	 HELPER FUNCTIONS  ***********************
******************************************************************/
void UpdateSQL(int iClient)
{
	if(ga_bHasGang[iClient])
	{
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * \
										FROM gang_group \
										WHERE name = '%s' AND server_id = %i;", 
										ga_sGangName[iClient], g_iServerID);
		g_hDatabase.Query(SQLCallback_CreateGroup, sQuery, iClient);
	}
}

public void SQLCallback_CreateGroup(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_CreateGroup] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	bool bGangInDatabase = true;
	if(results.RowCount == 0)
		bGangInDatabase = false;

	int iLen = 2*strlen(ga_sGangName[iClient])+1;
	char[] szEscapedGang = new char[iLen];
	g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

	char sQuery[300];
	if(!bGangInDatabase)
	{
		int iCreateDate = GetTime();
		int iEndDate = GetTime() + g_iCreateGangDays * 86400;
		Format(sQuery, sizeof(sQuery), "INSERT INTO gang_group \
										(name, server_id, create_date, end_date) \
										VALUES ('%s', %i, %i, %i);", 
										szEscapedGang, g_iServerID, iCreateDate, iEndDate);
		g_hDatabase.Query(SQLCallback_CheckGroupHelp, sQuery, iClient);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "SELECT id \
										FROM gang_group \
										WHERE name = '%s' AND server_id = %i;", 
										szEscapedGang, g_iServerID);
		g_hDatabase.Query(SQLCallback_CheckGroup, sQuery, iClient);
	}
}

public void SQLCallback_CheckGroupHelp(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckGroupHelp] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT id \
									FROM gang_group \
									WHERE name = '%s' AND server_id = %i;", 
									ga_sGangName[iClient], g_iServerID);
	g_hDatabase.Query(SQLCallback_CheckGroup, sQuery, iClient);
}

public void SQLCallback_CheckGroup(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckGroup] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	if (results.FetchRow())
	{
		ga_iGangId[iClient] = results.FetchInt(0);

		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * \
										FROM gang_statistic \
										WHERE gang_id = %i;", 
										ga_iGangId[iClient], g_iServerID);
		g_hDatabase.Query(SQLCallback_LoadStatistic, sQuery, iClient);
	}
}

public void SQLCallback_LoadStatistic(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_LoadStatistic] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	bool bGangInDatabase = true;
	if(results.RowCount == 0)
		bGangInDatabase = false;

	char sQuery[300];
	if(!bGangInDatabase)
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO gang_statistic \
										(gang_id, %s) \
										VALUES(%i, %i)", 
										g_sDbStatisticName, ga_iGangId[iClient], ga_iScore[iClient]);
		g_hDatabase.Query(SQLCallback_Void, sQuery, 3);
	}

	Format(sQuery, sizeof(sQuery), "SELECT * \
									FROM gang_perk \
									WHERE gang_id = %i;", 
									ga_iGangId[iClient], g_iServerID);
	g_hDatabase.Query(SQLCallback_LoadPerks, sQuery, iClient);
}

public void SQLCallback_LoadPerks(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_LoadPerks] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	bool bGangInDatabase = true;
	if(results.RowCount == 0)
		bGangInDatabase = false;

	char sQuery[300];
	if(!bGangInDatabase)
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO gang_perk \
										(gang_id) \
										VALUES (%i);", 
										ga_iGangId[iClient]);
		g_hDatabase.Query(SQLCallback_Void, sQuery, 4);
	}

	GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
	Format(sQuery, sizeof(sQuery), "SELECT * \
									FROM gang_player \
									WHERE steam_id = '%s' AND gang_id = %i;", 
									ga_sSteamID[iClient], ga_iGangId[iClient]);
	g_hDatabase.Query(SQLCallback_CheckIfInDatabase_Player, sQuery, iClient);
}

public void SQLCallback_CheckIfInDatabase_Player(Database db, DBResultSet results, const char[] error, int iClient)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckIfInDatabase_Player] Error (%i): %s", iClient, error);
		return;
	}

	if(!IsValidClient(iClient))
		return;

	bool bPlayerInDatabase = true;
	if(results.RowCount == 0)
		bPlayerInDatabase = false;
	
	char sQuery[300];
	char sName[MAX_NAME_LENGTH];
	GetClientName(iClient, sName, sizeof(sName));
	int iLen = 2*strlen(sName)+1;
	char[] szEscapedName = new char[iLen];
	g_hDatabase.Escape(GetFixString(sName), szEscapedName, iLen);
	
	if(!bPlayerInDatabase)
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO gang_player \
										(gang_id, steam_id, name, rank, inviter_name, invite_date) \
										VALUES (%i, '%s', '%s', %i, '%s', %i);", 
										ga_iGangId[iClient], ga_sSteamID[iClient], szEscapedName, ga_iRank[iClient], ga_sInvitedBy[iClient], ga_iDateJoined[iClient]);
		g_hDatabase.Query(SQLCallback_Void, sQuery, 1);
		API_OnGoToGang(iClient, ga_sGangName[iClient], ga_iInvitation[iClient]);
		ga_iInvitation[iClient] = -1;
	}


}

public void SQLCallback_CheckName(Database db, DBResultSet results, const char[] error, DataPack data)
{
	if(error[0])
	{
		LogError("[SQLCallback_CheckName] Error (%i): %s", data, error);
		return;
	}

	char sText[64];
	int iClient = data.ReadCell();
	data.ReadString(sText, sizeof(sText));
	delete data;

	if(!IsValidClient(iClient))
	{
		return;
	}
	else
	{
		if(ga_bSetName[iClient])
		{
			if(results.RowCount == 0)
			{
				strcopy(ga_sGangName[iClient], sizeof(ga_sGangName[]), sText);
				if(CheckBadNameGang(ga_sGangName[iClient]))
				{
					ga_bHasGang[iClient] = true;
					ga_iDateJoined[iClient] = GetTime();
					ga_sInvitedBy[iClient] = "N/A";
					ga_iRank[iClient] = 0;
					ga_iGangSize[iClient] = 1;

					
					ga_iExtendCount[iClient] = 0;
					
					ga_iBankRubles[iClient] = 0;
					ga_iBankCredits[iClient] = 0;
					ga_iBankGold[iClient] = 0;
					ga_iBankWCSGold[iClient] = 0;
					ga_iBankLKRubles[iClient] = 0;
					
					UpdateSQL(iClient);
					
					if(g_bCreateGangSellMode == 0 && g_bGameCMSExist)
					{
						int Discount;
						if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
							Discount = GameCMS_GetGlobalDiscount();
						else Discount = GameCMS_GetClientDiscount(iClient);
						GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, g_iCreateGangPrice, Discount));
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i рублей", iClient, ga_sGangName[iClient], Colculate(iClient, g_iCreateGangPrice, Discount));
					}
					else if(g_bCreateGangSellMode == 1)
					{
						if(g_bShopLoaded)
						{
							Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iCreateGangPrice);
						}
						else if(g_bStoreLoaded)
						{
							Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - g_iCreateGangPrice);
						}
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i кредитов", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
					}
					else if(g_bCreateGangSellMode == 2 && g_bLShopGoldExist)
					{
						Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - g_iCreateGangPrice);
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i голды", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
					}
					//else if(g_bCreateGangSellMode == 3 && g_bWCSLoaded)
					else if(g_bCreateGangSellMode == 3)
					{
						WCS_TakeGold(iClient, g_iCreateGangPrice);
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i WCS голды", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
					}
					else if(g_bCreateGangSellMode == 4 && g_bLKLoaded)
					{
						LK_ChangeBalance(iClient, LK_Cash, LK_Take, g_iCreateGangPrice);
									
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i MyJailShop Creditss", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
					}
					else if(g_bCreateGangSellMode == 5 && g_bMyJBShopExist)
					{
						MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - g_iCreateGangPrice);
									
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i LK рублей", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
					}
					else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
					
					CreateTimer(0.2, Timer_OpenGangMenu, iClient, TIMER_FLAG_NO_MAPCHANGE);
					
					char szName[MAX_NAME_LENGTH];
					GetClientName(iClient, szName, sizeof(szName));
					CPrintToChatAll("%t %t", "Prefix", "GangCreated", szName, ga_sGangName[iClient]);
				}
				else
				{
					CPrintToChat(iClient, "%t %t", "Prefix", "BadName");
				}
			}
			else 
			{
				CPrintToChat(iClient, "%t %t", "Prefix", "NameAlreadyUsed");
			}
			
			ga_bSetName[iClient] = false;
		}
		else if(ga_bRename[iClient])
		{
			if(results.RowCount == 0)
			{
				strcopy(ga_sGangName[iClient], sizeof(ga_sGangName[]), sText);
				if(CheckBadNameGang(ga_sGangName[iClient]))
				{
					for(int i = 1; i <= MaxClients; i++)
					{
						if(IsValidClient(i) && ga_iGangId[i] == ga_iGangId[iClient])
						{
							strcopy(ga_sGangName[i], sizeof(ga_sGangName[]), sText);
						}
					}
					char sQuery[300];
					Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
													SET `name` = '%s' \
													WHERE id = %i AND server_id = %i;", 
													sText, ga_iGangId[iClient], g_iServerID);
					g_hDatabase.Query(SQLCallback_Void, sQuery, 5);
					
					if(g_bRenamePriceSellMode == 0 && g_bGameCMSExist)
					{
						int Discount;
						if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
							Discount = GameCMS_GetGlobalDiscount();
						else Discount = GameCMS_GetClientDiscount(iClient);
						
						if(g_bEnableBank && g_bRenameBank)
							SetBankRubles(iClient, ga_iBankRubles[iClient] - Colculate(iClient, g_iRenamePrice, Discount));
						else
							GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, g_iRenamePrice, Discount));
						
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i рублей", iClient, sText, Colculate(iClient, g_iRenamePrice, Discount));
					}
					else if(g_bRenamePriceSellMode == 1)
					{
						if(g_bEnableBank && g_bBankShop && g_bRenameBank)
							SetBankCredits(iClient, ga_iBankCredits[iClient] - g_iRenamePrice);
						else
						{
							if(g_bShopLoaded)
								Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
							else if(g_bStoreLoaded)
								Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - g_iRenamePrice);
						}
						
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i кредитов", iClient, sText, g_iRenamePrice);
					}
					else if(g_bRenamePriceSellMode == 2 && g_bLShopGoldExist)
					{
						if(g_bEnableBank && g_bBankShopGold && g_bRenameBank)
							SetBankGold(iClient, ga_iBankGold[iClient] - g_iRenamePrice);
						else
							Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - g_iRenamePrice);
						
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i голды", iClient, sText, g_iRenamePrice);
					}
					//else if(g_bRenamePriceSellMode == 3 && g_bWCSLoaded)
					else if(g_bRenamePriceSellMode == 3)
					{
						if(g_bEnableBank && g_bBankWcsGold && g_bRenameBank)
							SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] - g_iRenamePrice);
						else
							WCS_TakeGold(iClient, g_iRenamePrice);
						
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i WCS голды", iClient, sText, g_iRenamePrice);
					}
					else if(g_bRenamePriceSellMode == 4 && g_bLKLoaded)
					{
						if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
							SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] - g_iRenamePrice);
						else
							LK_ChangeBalance(iClient, LK_Cash, LK_Take, g_iRenamePrice);
									
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i LK рублей", iClient, sText, g_iRenamePrice);
					}
					else if(g_bRenamePriceSellMode == 5 && g_bMyJBShopExist)
					{
						if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
							SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] - g_iRenamePrice);
						else
							MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - g_iRenamePrice);
									
						if(g_bLog)
							LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды на %s за %i LK рублей", iClient, sText, g_iRenamePrice);
					}
					else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
					
					char szName[MAX_NAME_LENGTH];
					GetClientName(iClient, szName, sizeof(szName));
					CPrintToChatAll("%t %t", "Prefix", "GangNameChange", szName, sText);

					StartOpeningGangMenu(iClient);
				}
				else 
				{
					CPrintToChat(iClient, "%t %t", "Prefix", "BadName");
				}
			}
			else
			{
				CPrintToChat(iClient, "%t %t", "Prefix", "NameAlreadyUsed");
			}
			
			ga_bRename[iClient] = false;
		}
	}
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_Void] Error (%i): %s", data, error);
	}
}