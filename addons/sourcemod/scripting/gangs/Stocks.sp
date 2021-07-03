stock bool PerkNameAlreadyExist(const char[] ItemName)
{
	return g_hPerkName.FindString(ItemName) > -1;
}

stock void UnRegisterPerk(const char[] ItemName)
{
	int index = g_hPerkName.FindString(ItemName);
	if(index < 0) return;
	g_iPerksCount -= 1;
	g_hPerkName.Erase(index);
	g_hPerkID.Erase(index);
	RestartSortTimer();
}

stock int RegisterPerk(const char[] ItemName)
{
	if(PerkNameAlreadyExist(ItemName)) return -1;
	int ItemID = CreateItemID();
	g_hPerkName.PushString(ItemName);
	g_hPerkID.Push(ItemID);
	g_iPerksCount += 1;
	RestartSortTimer();
	return ItemID;
}

stock bool GameNameAlreadyExist(const char[] ItemName)
{
	return g_hGameName.FindString(ItemName) > -1;
}

stock void UnRegisterGame(const char[] ItemName)
{
	int index = g_hGameName.FindString(ItemName);
	if(index < 0) return;
	g_iGamesCount -= 1;
	g_hGameName.Erase(index);
	g_hGameID.Erase(index);
	RestartSortTimer1();
}

stock int RegisterGame(const char[] ItemName)
{
	if(GameNameAlreadyExist(ItemName)) return -1;
	int ItemID = CreateItemID();
	g_hGameName.PushString(ItemName);
	g_hGameID.Push(ItemID);
	g_iGamesCount += 1;
	RestartSortTimer1();
	return ItemID;
}

stock bool StatNameAlreadyExist(const char[] ItemName)
{
	return g_hStatName.FindString(ItemName) > -1;
}

stock void UnRegisterStat(const char[] ItemName)
{
	int index = g_hStatName.FindString(ItemName);
	if(index < 0) return;
	g_iStatsCount -= 1;
	g_hStatName.Erase(index);
	g_hStatID.Erase(index);
	RestartSortTimer2();
}

stock int RegisterStat(const char[] ItemName)
{
	if(StatNameAlreadyExist(ItemName)) return -1;
	int ItemID = CreateItemID();
	g_hStatName.PushString(ItemName);
	g_hStatID.Push(ItemID);
	g_iStatsCount += 1;
	RestartSortTimer2();
	return ItemID;
}

stock bool CheckDBItem(const char[] ItemName)
{
	if(AddItemInDB(ItemName))
	{
		return true;
	}
	else return false;
}

stock bool AddItemInDB(const char[] ItemName)
{
	char sQuery[300];
	FormatEx(sQuery, sizeof(sQuery), "SELECT %s \
										FROM gang_perk;", 
										ItemName);
	
	DataPack hPack = new DataPack();
	hPack.WriteString(ItemName);
	g_hDatabase.Query(SQLCallback_CheckPerk, sQuery, hPack);
	return true;
}

public void SQLCallback_CheckPerk(Database db, DBResultSet hResults, const char[] sError, any iDataPack)
{
	DataPack hPack = view_as<DataPack>(iDataPack);
	hPack.Reset();
	
	char ItemName[64];
	hPack.ReadString(ItemName, sizeof(ItemName));
	
	delete hPack;

	if(sError[0])
	{
		if(StrContains(sError, "Duplicate column name", false))
		{
			char szQuery[256];
			FormatEx(szQuery, sizeof(szQuery), "ALTER TABLE gang_perk \
												ADD COLUMN %s int(32) NOT NULL DEFAULT 0;", 
												ItemName);
			g_hDatabase.Query(SQLCallback_Void, szQuery, 33);
		}
		else
		{
			LogError("[SQLCallback_CheckPerk] Error :  %s", sError);
		}

		return;
	}
	
	if(hResults.FetchRow())
		return;
}

stock int CreateItemID()
{
	static int id = 1;
	id += 1;
	return id;
}

stock void RestartSortTimer()
{
	if(hSortTimer) KillTimer(hSortTimer, false);
	hSortTimer = CreateTimer(2.0, SortTimer_CallBack, _);
}

public Action SortTimer_CallBack(Handle hTimer)
{
	hSortTimer = null;
	ArrayList hName = new ArrayList(ByteCountToCells(50));
	ArrayList hPerksID = new ArrayList(ByteCountToCells(1));
	hName = g_hPerkName.Clone();
	hPerksID = g_hPerkID.Clone();
	int ItemsCount = hName.Length;
	if(ItemsCount < 1) return Plugin_Stop;
	char file[255];
	BuildPath(Path_SM, file, sizeof(file), "configs/gangs/perks_sort.ini");
	if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
	File hFile = OpenFile(file, "r");
	if(hFile)
	{
		int index;
		char ItemName[52];
		ArrayList hNewItemName = new ArrayList(ByteCountToCells(50));
		ArrayList hNewItemID = new ArrayList(ByteCountToCells(1));
		while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, 50))
		{
			if(TrimString(ItemName) > 0 && hNewItemName.FindString(ItemName) < 0 && (index = hName.FindString(ItemName)) > -1)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hPerksID.Get(index, 0, false));
			}
		}
		for(int i = 0; i < ItemsCount; i++)
		{
			hName.GetString(i, ItemName, 50);
			if(hNewItemName.FindString(ItemName) < 0)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hPerksID.Get(i, 0, false));
			}
		}
		g_hPerkName = hNewItemName.Clone();
		g_hPerkID = hNewItemID.Clone();
		g_iPerksCount = g_hPerkName.Length;
		delete hFile;
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

stock void RestartSortTimer1()
{
	if(hSortTimer1) KillTimer(hSortTimer1, false);
	hSortTimer1 = CreateTimer(2.0, SortTimer_CallBack1, _);
}

public Action SortTimer_CallBack1(Handle hTimer)
{
	hSortTimer1 = null;
	ArrayList hName = new ArrayList(ByteCountToCells(50));
	ArrayList hGameID = new ArrayList(ByteCountToCells(1));
	hName = g_hGameName.Clone();
	hGameID = g_hGameID.Clone();
	int ItemsCount = hName.Length;
	if(ItemsCount < 1) return Plugin_Stop;
	char file[255];
	BuildPath(Path_SM, file, sizeof(file), "configs/gangs/games_sort.ini");
	if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
	File hFile = OpenFile(file, "r");
	if(hFile)
	{
		int index;
		char ItemName[52];
		ArrayList hNewItemName = new ArrayList(ByteCountToCells(50));
		ArrayList hNewItemID = new ArrayList(ByteCountToCells(1));
		while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, 50))
		{
			if(TrimString(ItemName) > 0 && hNewItemName.FindString(ItemName) < 0 && (index = hName.FindString(ItemName)) > -1)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hGameID.Get(index, 0, false));
			}
		}
		for(int i = 0; i < ItemsCount; i++)
		{
			hName.GetString(i, ItemName, 50);
			if(hNewItemName.FindString(ItemName) < 0)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hGameID.Get(i, 0, false));
			}
		}
		g_hGameName = hNewItemName.Clone();
		g_hGameID = hNewItemID.Clone();
		g_iGamesCount = g_hGameName.Length;
		delete hFile;
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

stock void RestartSortTimer2()
{
	if(hSortTimer2) KillTimer(hSortTimer2, false);
	hSortTimer2 = CreateTimer(2.0, SortTimer_CallBack2, _);
}

public Action SortTimer_CallBack2(Handle hTimer)
{
	hSortTimer2 = null;
	ArrayList hName = new ArrayList(ByteCountToCells(50));
	ArrayList hStatID = new ArrayList(ByteCountToCells(1));
	hName = g_hStatName.Clone();
	hStatID = g_hStatID.Clone();
	int ItemsCount = hName.Length;
	if(ItemsCount < 1) return Plugin_Stop;
	char file[255];
	BuildPath(Path_SM, file, sizeof(file), "configs/gangs/stats_sort.ini");
	if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
	File hFile = OpenFile(file, "r");
	if(hFile)
	{
		int index;
		char ItemName[52];
		ArrayList hNewItemName = new ArrayList(ByteCountToCells(50));
		ArrayList hNewItemID = new ArrayList(ByteCountToCells(1));
		while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, 50))
		{
			if(TrimString(ItemName) > 0 && hNewItemName.FindString(ItemName) < 0 && (index = hName.FindString(ItemName)) > -1)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hStatID.Get(index, 0, false));
			}
		}
		for(int i = 0; i < ItemsCount; i++)
		{
			hName.GetString(i, ItemName, 50);
			if(hNewItemName.FindString(ItemName) < 0)
			{
				hNewItemName.PushString(ItemName);
				hNewItemID.Push(hStatID.Get(i, 0, false));
			}
		}
		g_hStatName = hNewItemName.Clone();
		g_hStatID = hNewItemID.Clone();
		g_iStatsCount = g_hStatName.Length;
		delete hFile;
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

stock Handle CreateFile(const char[] path, const char[] mode = "w+")
{
	char dir[8][PLATFORM_MAX_PATH];
	int count = ExplodeString(path, "/", dir, 8, sizeof(dir[]));
	for(int i = 0; i < count-1; i++)
	{
		if(i > 0)
			Format(dir[i], sizeof(dir[]), "%s/%s", dir[i-1], dir[i]);
			
		if(!DirExists(dir[i]))
			CreateDirectory(dir[i], 511);
	}
	
	return OpenFile(path, mode);
}

stock bool IsCallValid(Handle hPlugin, Function ptrFunction) 
{
	return (ptrFunction != INVALID_FUNCTION && IsPluginValid(hPlugin));
}

stock bool IsPluginValid(Handle hPlugin)
{
	Handle hIterator = GetPluginIterator();
	bool bIsValid = false;
	
	while(MorePlugins(hIterator))
	{
		if(hPlugin == ReadPlugin(hIterator))
		{
			bIsValid = (GetPluginStatus(hPlugin) == Plugin_Running);
			break;
		}
	}
	
	delete hIterator;
	return bIsValid;
}

stock void CreateArrays()
{
            
	g_iPerksCount = 0;
	g_iGamesCount = 0;
	g_iStatsCount = 0;
	g_hPerkName = new ArrayList(ByteCountToCells(50));
	g_hPerkID = new ArrayList(ByteCountToCells(1));
	g_hPerkArray = new ArrayList(ByteCountToCells(64));
	g_hGameName = new ArrayList(ByteCountToCells(50));
	g_hGameID = new ArrayList(ByteCountToCells(1));
	g_hGamesArray = new ArrayList(ByteCountToCells(64));
	g_hStatName = new ArrayList(ByteCountToCells(50));
	g_hStatID = new ArrayList(ByteCountToCells(1));
	g_hStatsArray = new ArrayList(ByteCountToCells(64));

}

stock void ClearArrays()
{
	g_hPerkName.Clear();
	g_hPerkID.Clear();
	
	int iSize;
	iSize = g_hPerkArray.Length;
	for(int i = 1; i < iSize; i+=2)
	{
		CloseHandle(view_as<Handle>(g_hPerkArray.Get(i)));
	}
	g_hPerkArray.Clear();
	
	g_hGameName.Clear();
	g_hGameID.Clear();
	
	iSize = g_hGamesArray.Length;
	for(int i = 1; i < iSize; i+=2)
	{
		CloseHandle(view_as<Handle>(g_hGamesArray.Get(i)));
	}
	g_hGamesArray.Clear();
	
	g_hStatName.Clear();
	g_hStatID.Clear();
	
	iSize = g_hStatsArray.Length;
	for(int i = 1; i < iSize; i+=2)
	{
		CloseHandle(view_as<Handle>(g_hStatsArray.Get(i)));
	}
	g_hStatsArray.Clear();
}

stock bool GetClientRightStatus(int iClient, char[] sRights)
{
	if(IsValidClient(iClient))
	{
		KeyValues ConfigRanks;
		ConfigRanks = new KeyValues("Ranks");
		char szBuffer[256];
		BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
		ConfigRanks.ImportFromFile(szBuffer);
		ConfigRanks.Rewind();
		char buffer[16];
		IntToString(g_ClientInfo[iClient].rank, buffer, sizeof(buffer));
		if(ConfigRanks.JumpToKey(buffer)) // Попытка перейти к ключу
		{
			ConfigRanks.GetString("rights", szBuffer, sizeof(szBuffer));
			char help[10][64];
			ExplodeString(szBuffer, ";", help, sizeof(help), sizeof(help[]));
			for(int i = 0; i < sizeof(help); i++)
			{
				if(StrEqual(help[i], sRights) || StrEqual(help[i], "all"))
					return true;
			}
			return false;
		}
		else
		{
			delete ConfigRanks;
			return false;
		}
	}
	return false;
}

stock int GetLastConfigRank()
{
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
		} while (ConfigRanks.GotoNextKey());
	}
	delete ConfigRanks;
	return StringToInt(szBuffer);
}

stock bool CheckRankImmune(int ClientRank, char[] ReqRank)
{
	bool Status = false;
	
	char buffer[16];
	IntToString(ClientRank, buffer, sizeof(buffer));
	
	if(StrEqual(buffer, ReqRank))
		return Status;
	
	KeyValues ConfigRanks;
	ConfigRanks = new KeyValues("Ranks");
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
	ConfigRanks.ImportFromFile(szBuffer);
	ConfigRanks.Rewind();
	bool FindedClientRank = false;
	if(ConfigRanks.GotoFirstSubKey())
	{
		do
		{
			ConfigRanks.GetSectionName(szBuffer, sizeof(szBuffer));
			if(StrEqual(buffer, szBuffer))
				FindedClientRank = true;
			if(StrEqual(ReqRank, szBuffer) && FindedClientRank)
				Status = true;
		} while (ConfigRanks.GotoNextKey());
	}
	
	return Status;
}

stock char[] GetFixString(char[] sText)
{
	char sNewText[2*MAX_NAME_LENGTH+1];
	strcopy(sNewText, sizeof(sNewText), sText);

	for(int i = 0, iLen = strlen(sNewText), CharBytes; i < iLen;)
	{
		if((CharBytes = GetCharBytes(sNewText[i])) == 4)
		{
			iLen -= 4;
			for(int u = i; u <= iLen; u++)
			{
				sNewText[u] = sNewText[u+4];
			}
		}
		else i += CharBytes;
	}
	return sNewText;
}

stock int Colculate(int iClient, int Number, int Discount)
{
    int Sale = RoundToNearest((float(Number) * float(Discount))/100.0);
    
    return Number-Sale;
}