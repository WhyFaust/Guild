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

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("Error (%i): %s", data, error);
	}
}