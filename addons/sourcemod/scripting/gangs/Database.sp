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

	if (SQL_CheckConfig("gangs"))
	{
		Database.Connect(OnDBConnect, "gangs", 0);
	}
	else
	{
		char szError[256];
		g_hDatabase = SQLite_UseDatabase("gangs", SZF(szError));
		OnDBConnect(g_hDatabase, szError, 1);
	}
}

public void OnDBConnect(Database hDatabase, const char[] szError, any data)
{
	if (hDatabase == null || szError[0])
	{
		SetFailState("OnDBConnect %s", szError);
		UNSET_BIT(GLOBAL_INFO, IS_MySQL);
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
	
	CreateTables();
}

void CreateTables()
{
	if(GLOBAL_INFO & IS_MySQL)
	{
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_players (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											steamid varchar(32) NOT NULL, \
											playername varchar(32) NOT NULL, \
											gang varchar(32) NOT NULL, \
											server_id int(16) NOT NULL DEFAULT 0, \
											rank int(16) NOT NULL, \
											invitedby varchar(32) NOT NULL, \
											date int(11) NOT NULL, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_groups (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											gang varchar(32) NOT NULL unique, \
											server_id int(16) NOT NULL DEFAULT 0, \
											end_date int(32), \
											create_date int(32), \
											extend_count int(16) NOT NULL, \
											rubles int(32) NOT NULL DEFAULT 0, \
											credits int(32) NOT NULL DEFAULT 0, \
											gold int(32) NOT NULL DEFAULT 0, \
											wcsgold int(32) NOT NULL DEFAULT 0, \
											lk_rubles int(32) NOT NULL DEFAULT 0, \
											myjb_credits int(32) NOT NULL DEFAULT 0, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_perks (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											gang varchar(32) NOT NULL, \
											server_id int(16) NOT NULL DEFAULT 0, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_statistics (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											gang varchar(32) NOT NULL unique, \
											server_id int(16) NOT NULL DEFAULT 0, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_prefs (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											steamid varchar(32) NOT NULL, \
											pref int(16) NOT NULL, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;", 1);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_bank_logs (\
											id int(20) NOT NULL AUTO_INCREMENT, \
											gang varchar(32) NOT NULL, \
											server_id int(16) NOT NULL DEFAULT 0, \
											nick varchar(32) NOT NULL, \
											logs varchar(256) NOT NULL, \
											date int(11) DEFAULT NULL, \
											PRIMARY KEY (id)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;");
	}
	else
	{		
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_players (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											steamid TEXT(32) NOT NULL, \
											playername TEXT(32) NOT NULL, \
											gang TEXT(32) NOT NULL, \
											server_id INTEGER(16) NOT NULL DEFAULT 0, \
											rank INTEGER(16) NOT NULL, \
											invitedby TEXT(32) NOT NULL, \
											date INTEGER(11) NOT NULL);", 1);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_groups (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											gang TEXT(32) NOT NULL, \
											server_id INTEGER(16) NOT NULL DEFAULT 0, \
											end_date INTEGER(32), \
											create_date INTEGER(32), \
											extend_count INTEGER(16) NOT NULL, \
											rubles INTEGER(32) NOT NULL DEFAULT 0, \
											credits INTEGER(32) NOT NULL DEFAULT 0, \
											gold INTEGER(32) NOT NULL DEFAULT 0, \
											wcsgold INTEGER(32) NOT NULL DEFAULT 0, \
											lk_rubles INTEGER(32) NOT NULL DEFAULT 0, \
											myjb_credits INTEGER(32) NOT NULL DEFAULT 0);", 2);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_perks (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											gang TEXT(32) NOT NULL, \
											server_id INTEGER(16) NOT NULL DEFAULT 0);", 3);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_statistics (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											gang TEXT(32) NOT NULL, \
											server_id INTEGER(16) NOT NULL DEFAULT 0);", 4);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS gangs_prefs (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											steamid TEXT(32) NOT NULL, \
											pref INTEGER NOT NULL);", 5);
		g_hDatabase.Query(SQLCallback_CreateTables, "CREATE TABLE IF NOT EXISTS  gangs_bank_logs (\
											id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \
											gang TEXT(32) NOT NULL, \
											server_id INTEGER(16) NOT NULL DEFAULT 0, \
											nick TEXT(32) NOT NULL, \
											logs TEXT(256) NOT NULL, \
											date INTEGER(11) DEFAULT NULL);", 6);
	}
	char sQuery[300];
	FormatEx(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_statistics;", g_sDbStatisticName);
	g_hDatabase.Query(SQLCallback_CreateStatisticTables, sQuery, 7);
}

public void SQLCallback_CreateStatisticTables(Database db, DBResultSet hResults, const char[] sError, int data)
{
	if(sError[0]) // Если произошла ошибка
	{
		if(StrContains(sError, "Duplicate column name", false))
		{
			char szQuery[256];
			if(GLOBAL_INFO & IS_MySQL)
				FormatEx(szQuery, sizeof(szQuery), "ALTER TABLE gangs_statistics ADD %s int(16) NOT NULL DEFAULT 0;", g_sDbStatisticName);
			else
				FormatEx(szQuery, sizeof(szQuery), "ALTER TABLE gangs_statistics ADD COLUMN %s INTEGER(16) NOT NULL DEFAULT 0;", g_sDbStatisticName);
			g_hDatabase.Query(SQLCallback_CreateTables, szQuery);
		}
		else
			LogError("[SQLCallback_CreateStatisticTables] Error :  %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	if(hResults.FetchRow())
	{
		return; // Прекращаем выполнение ф-и
	}
}

public void SQLCallback_CreateTables(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("[SQLCallback_CreateTables] Error (%i): %s", data, error);
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
        {
            return;
        }
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
            char sQuery[300];
            Format(sQuery, sizeof(sQuery), "SELECT gang, rank, invitedby, date FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);
            g_hDatabase.Query(SQLCallback_CheckSQL_Player, sQuery, iClient);
            Format(sQuery, sizeof(sQuery), "SELECT pref FROM gangs_prefs WHERE steamid = '%s';", ga_sSteamID[iClient]);
            g_hDatabase.Query(SQLCallback_GetPreference, sQuery, iClient);
            if(g_bDebug)
                LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Load SteamID for %N(%i) SteamID: %s", iClient, iClient, ga_sSteamID[iClient]);
        }
    }
}

public void SQLCallback_GetPreference(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_GetPreference] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.RowCount > 0)
        {
            results.FetchRow();
            ga_bBlockInvites[iClient] = view_as<bool>(results.FetchInt(0));
            ga_bHasPref[iClient] = true;
        }
        else
        {
            ga_bBlockInvites[iClient] = false;
            ga_bHasPref[iClient] = false;
        }
    }
}

public void SQLCallback_CheckSQL_Player(Database db, DBResultSet results, const char[] error, int data)
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
        if(results.RowCount == 1)
        {
            results.FetchRow();
            

            results.FetchString(0, ga_sGangName[iClient], sizeof(ga_sGangName[]));
            ga_iRank[iClient] = results.FetchInt(1);
            results.FetchString(2, ga_sInvitedBy[iClient], sizeof(ga_sInvitedBy[]));
            ga_iDateJoined[iClient] = results.FetchInt(3);
            
            ga_bIsPlayerInDatabase[iClient] = true;
            ga_bHasGang[iClient] = true;
            ga_bLoaded[iClient] = true;
            
            int iLen = 2*strlen(ga_sGangName[iClient])+1;
            char[] szEscapedGang = new char[iLen];
            g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

            char sQuery_2[300];
            Format(sQuery_2, sizeof(sQuery_2), "SELECT end_date, extend_count, rubles, credits, gold, wcsgold, lk_rubles FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
            g_hDatabase.Query(SQLCallback_CheckSQL_Groups, sQuery_2, iClient);
        }
        else
        {
            if(results.RowCount > 1)
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
        if(results.RowCount == 1)
        {
            results.FetchRow();

            //int endtime = results.FetchInt(0);
            ga_iExtendCount[iClient] = results.FetchInt(1);
            ga_iBankRubles[iClient] = results.FetchInt(2);
            ga_iBankCredits[iClient] = results.FetchInt(3);
            ga_iBankGold[iClient] = results.FetchInt(4);
            ga_iBankWCSGold[iClient] = results.FetchInt(5);
            ga_iBankLKRubles[iClient] = results.FetchInt(6);

            int iLen = 2*strlen(ga_sGangName[iClient])+1;
            char[] szEscapedGang = new char[iLen];
            g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

            char sQuery[300];
            Format(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", g_sDbStatisticName, szEscapedGang, g_iServerID);
            g_hDatabase.Query(SQL_Callback_Kills, sQuery, iClient);
            //if(GetTime()>endtime) DissolveGang(iClient);
        }
    }
}

public void SQL_Callback_Kills(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_Kills] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.FetchRow()) // row exists
        {
            ga_iScore[iClient] = results.FetchInt(0);
        }
    }
}

/*****************************************************************
***********************	 HELPER FUNCTIONS  ***********************
******************************************************************/
void UpdateSQL(int iClient)
{
    if(ga_bHasGang[iClient])
    {
        GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
        
        char sQuery[300];
        Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);

        g_hDatabase.Query(SQLCallback_CheckIfInDatabase_Player, sQuery, iClient);
    }
}

public void SQLCallback_CheckIfInDatabase_Player(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_CheckIfInDatabase_Player] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }
    if(results.RowCount == 0)
    {
        ga_bIsPlayerInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsPlayerInDatabase[iClient] = true;
    }
    
    char sQuery[300];
    
    char sName[MAX_NAME_LENGTH];
    GetClientName(iClient, sName, sizeof(sName));
    int iLen = 2*strlen(sName)+1;
    char[] szEscapedName = new char[iLen];
    g_hDatabase.Escape(GetFixString(sName), szEscapedName, iLen);

    iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] sEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), sEscapedGang, iLen);
    
    if(!ga_bIsPlayerInDatabase[iClient])
    {
        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_players (gang, server_id, invitedby, rank, date, steamid, playername) VALUES('%s', '%i', '%s', '%i', '%i', '%s', '%s');", sEscapedGang, g_iServerID, ga_sInvitedBy[iClient], ga_iRank[iClient], ga_iDateJoined[iClient], ga_sSteamID[iClient], szEscapedName);
    }
    else
    {
        Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET gang = '%s', invitedby = '%s', playername = '%s', rank = '%i', date = '%i' WHERE steamid = '%s' AND server_id = %i;", sEscapedGang, ga_sInvitedBy[iClient], szEscapedName, ga_iRank[iClient], ga_iDateJoined[iClient], ga_sSteamID[iClient], g_iServerID);
    }
    if(IsValidClient(iClient))
    {
        API_OnGoToGang(iClient, ga_sGangName[iClient], ga_iInvitation[iClient]);
    }
    g_hDatabase.Query(SQLCallback_Void, sQuery, 111);

    Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", sEscapedGang, g_iServerID);
    
    g_hDatabase.Query(SQLCALLBACK_GROUPS, sQuery, iClient);
}

public void SQLCALLBACK_GROUPS(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCALLBACK_GROUPS] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
    {
        int created = GetTime();
        int ended = created+2629743;

        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_groups (gang, server_id, create_date, end_date, extend_count) VALUES('%s', '%i', '%i', '%i', '%i');", szEscapedGang, g_iServerID, created, ended, ga_iExtendCount[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 222);
    }


    Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQL_Callback_LoadStatistics, sQuery, iClient);

}

public void SQL_Callback_LoadStatistics(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_LoadStatistics] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
        Format(sQuery, sizeof(sQuery), "INSERT INTO `gangs_statistics` (`gang`, `server_id`, `%s`) VALUES('%s', '%i', '%i');", g_sDbStatisticName, szEscapedGang, g_iServerID, ga_iScore[iClient]);
    else
        Format(sQuery, sizeof(sQuery), "UPDATE `gangs_statistics` SET `%s` = '%i' WHERE gang= '%s' AND `server_id` = %i;", g_sDbStatisticName, ga_iScore[iClient], szEscapedGang, g_iServerID);

    g_hDatabase.Query(SQLCallback_Void, sQuery, 333);

    Format(sQuery, sizeof(sQuery), "SELECT * FROM `gangs_perks` WHERE `gang` = '%s' AND `server_id` = %i;", szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQL_Callback_LoadPerks, sQuery, iClient);
}

public void SQL_Callback_LoadPerks(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_LoadPerks] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
    {
        int iLen = 2*strlen(ga_sGangName[iClient])+1;
        char[] szEscapedGang = new char[iLen];
        g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_perks (gang, server_id) VALUES('%s', '%i');", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 444);
    }

}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("Error (%i): %s", data, error);
	}
}