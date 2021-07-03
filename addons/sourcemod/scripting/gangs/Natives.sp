public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	CreateNative("Gangs_GetDatabase", Native_GetDatabase);
	CreateNative("Gangs_GetServerID", Native_GetServerID);
	
	CreateNative("Gangs_ReloadClient", Native_ReloadClient);
	
	CreateNative("Gangs_ClientHasGang", Native_ClientHasGang);
	CreateNative("Gangs_GetClientGangId", Native_GetClientGangId);
	CreateNative("Gangs_GetClientGangName", Native_GetClientGangName);
	CreateNative("Gangs_GetGangLvl", Native_GetGangLvl);
	CreateNative("Gangs_GetGangSize", Native_GetGangSize);
	CreateNative("Gangs_GetGangReqScore", Native_GetGangReqScore);
	CreateNative("Gangs_GetClientGangRank", Native_GetClientGangRank);
	CreateNative("Gangs_GetClientGangScore", Native_GetClientGangScore);
	CreateNative("Gangs_SetClientGangScore", Native_SetClientGangScore);
	
	CreateNative("Gangs_ShowMainMenu", Native_ShowMainMenu);
	CreateNative("Gangs_ShowPerksMenu", Native_ShowPerksMenu);
	CreateNative("Gangs_ShowGamesMenu", Native_ShowGamesMenu);
	CreateNative("Gangs_ShowStatsMenu", Native_ShowStatsMenu);
	
	CreateNative("Gangs_AddToPerkMenu", Native_AddToPerkMenu); 
	CreateNative("Gangs_DeleteFromPerkMenu", Native_DeleteFromPerkMenu);
	
	CreateNative("Gangs_AddToGamesMenu", Native_AddToGamesMenu); 
	CreateNative("Gangs_DeleteFromGamesMenu", Native_DeleteFromGamesMenu);
	
	CreateNative("Gangs_AddToStatsMenu", Native_AddToStatsMenu); 
	CreateNative("Gangs_DeleteFromStatsMenu", Native_DeleteFromStatsMenu);
	
	CreateNative("Gangs_GetClientCash", Native_GetClientCash); 
	CreateNative("Gangs_GiveClientCash", Native_GiveClientCash); 
	CreateNative("Gangs_TakeClientCash", Native_TakeClientCash); 
	
	CreateNative("Gangs_GetBankClientCash", Native_GetBankClientCash); 
	CreateNative("Gangs_GiveBankClientCash", Native_GiveBankClientCash); 
	CreateNative("Gangs_TakeBankClientCash", Native_TakeBankClientCash); 
	
	CreateNative("Gangs_DissolveGang", Native_DissolveGang); 
	CreateNative("Gangs_KickMember", Native_KickMember); 
	
	RegPluginLibrary("gangs");
	
	//Modules
	MarkNativeAsOptional("AddOptionToMainMenu");
	MarkNativeAsOptional("HexTags_ResetClientTags");
	MarkNativeAsOptional("WCS_GetGold");
	MarkNativeAsOptional("WCS_GiveGold");
	MarkNativeAsOptional("WCS_TakeGold");
	MarkNativeAsOptional("MyJailShop_GetCredits");
	MarkNativeAsOptional("MyJailShop_SetCredits");

	return APLRes_Success;
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int Native_GetServerID(Handle plugin, int numParams)
{
	return view_as<int>(g_iServerID);
}

public int Native_AddToPerkMenu(Handle hPlugin, int iNumParams)
{
	char szItemName[64];
	bool AddInDB;
	GetNativeString(1, szItemName, sizeof(szItemName));
	AddInDB = view_as<bool>(GetNativeCell(3));
	if((AddInDB && CheckDBItem(szItemName)) || !AddInDB)
	{
		Function fncCallback = GetNativeFunction(2);
		int iItemID = RegisterPerk(szItemName);
		if(iItemID != -1)
		{
			DataPack hPack = new DataPack();
			hPack.WriteCell(hPlugin);
			hPack.WriteFunction(fncCallback);
			
			g_hPerkArray.PushString(szItemName);
			g_hPerkArray.Push(hPack);
		}
		//else LogError("Gangs_AddToPerkMenu ошибка: Ключ '%s' уже занят", szItemName);
	}
	else LogError("Gangs_AddToPerkMenu ошибка: Ошибка добавление '%s' в бд", szItemName);
}

public int Native_DeleteFromPerkMenu(Handle hPlugin, int iNumParams)
{
	int index = -1;
	char szItemName[64];
	if(GetNativeString(1, szItemName, sizeof(szItemName))) return;
	UnRegisterPerk(szItemName);
	if((index = g_hPerkArray.FindString(szItemName)) != -1)
	{
		g_hPerkArray.Erase(index+1);
		g_hPerkArray.Erase(index);
	}
}

public int Native_AddToGamesMenu(Handle hPlugin, int iNumParams)
{
	char szItemName[64];
	GetNativeString(1, szItemName, sizeof(szItemName));
	Function fncCallback = GetNativeFunction(2);
	int iItemID = RegisterGame(szItemName);
	if(iItemID != -1)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(hPlugin);
		hPack.WriteFunction(fncCallback);
		
		g_hGamesArray.PushString(szItemName);
		g_hGamesArray.Push(hPack);
	}
	//else LogError("Gangs_AddToGamesMenu ошибка: Ключ '%s' уже занят", szItemName);
}

public int Native_DeleteFromGamesMenu(Handle hPlugin, int iNumParams)
{
	int index = -1;
	char szItemName[64];
	if(GetNativeString(1, szItemName, sizeof(szItemName))) return;
	UnRegisterGame(szItemName);
	if((index = g_hGamesArray.FindString(szItemName)) != -1)
	{
		g_hGamesArray.Erase(index+1);
		g_hGamesArray.Erase(index);
	}
}

public int Native_AddToStatsMenu(Handle hPlugin, int iNumParams)
{
	char szItemName[64];
	GetNativeString(1, szItemName, sizeof(szItemName));
	Function fncCallback = GetNativeFunction(2);
	int iItemID = RegisterStat(szItemName);
	if(iItemID != -1)
	{
		DataPack hPack = new DataPack();
		hPack.WriteCell(hPlugin);
		hPack.WriteFunction(fncCallback);
		
		g_hStatsArray.PushString(szItemName);
		g_hStatsArray.Push(hPack);
	}
}

public int Native_DeleteFromStatsMenu(Handle hPlugin, int iNumParams)
{
	int index = -1;
	char szItemName[64];
	if(GetNativeString(1, szItemName, sizeof(szItemName))) return;
	UnRegisterStat(szItemName);
	if((index = g_hStatsArray.FindString(szItemName)) != -1)
	{
		g_hStatsArray.Erase(index+1);
		g_hStatsArray.Erase(index);
	}
}

public int Native_GetClientGangId(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	return g_ClientInfo[iClient].gangid;
}

public int Native_GetClientGangName(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	SetNativeString(2, g_GangInfo[GetGangLocalId(iClient)].name, GetNativeCell(3));
	return 0;
}

public int Native_GetClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		return GameCMS_GetClientRubles(iClient);
	}
	else if(StrEqual(sPerk, "shop"))
	{
		if(g_bShopLoaded)
			return Shop_GetClientCredits(iClient);
		else if(g_bStoreLoaded)
			return Store_GetClientCredits(iClient);
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		return Shop_GetClientGold(iClient);
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		return WCS_GetGold(iClient);
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		return LK_GetBalance(iClient, LK_Cash);
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		return MyJailShop_GetCredits(iClient);
	}
	
	return 0;
}

public int Native_TakeClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	int Cash = GetNativeCell(3);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient)-Cash);
	}
	else if(StrEqual(sPerk, "shop"))
	{
		if(g_bShopLoaded)
			Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient)-Cash);
		else if(g_bStoreLoaded)
			Store_SetClientCredits(iClient, Store_GetClientCredits(iClient)-Cash);
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		Shop_SetClientGold(iClient, Shop_GetClientGold(iClient)-Cash);
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		WCS_TakeGold(iClient, Cash);
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		LK_ChangeBalance(iClient, LK_Cash, LK_Take, Cash);
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient)-Cash);
	}
	return 0;
}

public int Native_GiveClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	int Cash = GetNativeCell(3);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient)+Cash);
	}
	else if(StrEqual(sPerk, "shop"))
	{
		if(g_bShopLoaded)
			Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient)+Cash);
		else if(g_bStoreLoaded)
			Store_SetClientCredits(iClient, Store_GetClientCredits(iClient)+Cash);
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		Shop_SetClientGold(iClient, Shop_GetClientGold(iClient)+Cash);
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		WCS_TakeGold(iClient, Cash);
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		LK_ChangeBalance(iClient, LK_Cash, LK_Add, Cash);
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient)+Cash);
	}
	return 0;
}

public int Native_GetBankClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.rubles;
	}
	else if(StrEqual(sPerk, "shop"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.credits;
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.gold;
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold;
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles;
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		return g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits;
	}
	
	return 0;
}

public int Native_TakeBankClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	int Cash = GetNativeCell(3);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		SetBankRubles(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.rubles - Cash);
	}
	else if(StrEqual(sPerk, "shop"))
	{
		SetBankCredits(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.credits - Cash);
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		SetBankGold(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.gold - Cash);
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		SetBankWCSGold(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold - Cash);
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		SetBankLKRubles(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles - Cash);
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		SetBankMyJBCredits(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits - Cash);
	}
	return 0;
}

public int Native_GiveBankClientCash(Handle plugin, int numParams)
{
	char sPerk[64];
	int iClient = GetNativeCell(1);
	GetNativeString(2, sPerk, sizeof(sPerk));
	int Cash = GetNativeCell(3);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	if(StrEqual(sPerk, "rubles"))
	{
		SetBankRubles(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.rubles + Cash);
	}
	else if(StrEqual(sPerk, "shop"))
	{
		SetBankCredits(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.credits + Cash);
	}
	else if(StrEqual(sPerk, "shopgold"))
	{
		SetBankGold(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.gold + Cash);
	}
	else if(StrEqual(sPerk, "wcsgold"))
	{
		SetBankWCSGold(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold + Cash);
	}
	else if(StrEqual(sPerk, "lkrubles"))
	{
		SetBankLKRubles(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles + Cash);
	}
	else if(StrEqual(sPerk, "myjb"))
	{
		SetBankMyJBCredits(iClient, g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits + Cash);
	}
	return 0;
}

public int Native_DissolveGang(Handle plugin, int numParams)
{
	int iGangID = GetNativeCell(1);
	DissolveGang(iGangID);
	
	return 0;
}

public int Native_KickMember(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
									WHERE id = %i;", 
									g_ClientInfo[iClient].id, g_iServerID);
	g_hDatabase.Query(SQLCallback_Void, sQuery, 31);
	API_OnExitFromGang(iClient);
	ResetVariables(iClient, false);
	
	return 0;
}

public int Native_GetClientGangRank(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}

	return view_as<int>(g_ClientInfo[iClient].rank);
}

public int Native_GetGangLvl(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);

	return view_as<int>(g_GangInfo[GetGangLocalId(iClient)].level);
}

public int Native_GetGangSize(Handle plugin, int numParams)
{
	return view_as<int>(g_iSize);
}

public int Native_GetGangReqScore(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);

	return view_as<int>(g_iScoreExpInc*g_GangInfo[GetGangLocalId(iClient)].level);
}

public int Native_ClientHasGang(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	
	return view_as<int>(g_ClientInfo[iClient].gangid >= 0);
}

public int Native_ShowMainMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) StartOpeningGangMenu(iClient);
	else LogError("Gangs_ShowMainMenu ошибка: Игрок не найден");
}

public int Native_ShowPerksMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) StartOpeningPerkMenu(iClient);
	else LogError("Native_ShowPerksMenu ошибка: Игрок не найден");
}

public int Native_ShowGamesMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) 
		StartOpeningTopGangsMenu(iClient);
	else 
		LogError("Native_ShowGamesMenu ошибка: Игрок не найден");
}

public int Native_ShowStatsMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(IsValidClient(iClient)) 
		StartOpeningStatMenu(iClient);
	else 
		LogError("Native_ShowStatsMenu ошибка: Игрок не найден");
}

public int Native_ReloadClient(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	LoadSteamID(iClient);
	
	return 0;
}

public int Native_GetClientGangScore(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsValidClient(iClient))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	}
	
	return g_GangInfo[GetGangLocalId(iClient)].exp;
}

public int Native_SetClientGangScore(Handle plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	int iValue = GetNativeCell(2);
	
	if (!IsValidClient(iClient))
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid iClient index (%i)", iClient);
	
	g_GangInfo[GetGangLocalId(iClient)].exp = iValue;
	while(g_GangInfo[GetGangLocalId(iClient)].exp >= g_iScoreExpInc*g_GangInfo[GetGangLocalId(iClient)].level)
	{
		g_GangInfo[GetGangLocalId(iClient)].exp -= g_iScoreExpInc*g_GangInfo[GetGangLocalId(iClient)].level;
		g_GangInfo[GetGangLocalId(iClient)].level++;
	}

	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "UPDATE gang_groups \
									SET exp = %i, level = %i \
									WHERE id = %i;", 
									g_GangInfo[GetGangLocalId(iClient)].exp, g_GangInfo[GetGangLocalId(iClient)].level, g_ClientInfo[iClient].gangid);
	g_hDatabase.Query(SQLCallback_Void, sQuery, 32);

	return 0;
}