/* Gang expired */
public Action Timer_CheckGangEnd(Handle timer)
{
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Check Gang End");
    
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "SELECT gang, end_date FROM gangs_groups;");
    g_hDatabase.Query(SQLCallback_Check_Gangs_End, sQuery);	
}

public void SQLCallback_Check_Gangs_End(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_Check_Gangs_End] Error (%i): %s", data, error);
        return;
    }
    
    while(results.FetchRow())
    {
        char GangName[128];
        results.FetchString(0, GangName, sizeof(GangName));
        int endtime = results.FetchInt(1);
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "(%i>%i, %s) - Check gang end time", GetTime(), endtime, GangName);
        if(GetTime()>endtime) DissolveGang(GangName);
    }
}
/*       end       */

public Action RefreshSteamID(Handle hTimer, int iUserID)
{
    int iClient = iUserID;
    if(!IsValidClient(iClient))
    {
        return;
    }

    GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
    
    if(StrContains(ga_sSteamID[iClient], "STEAM_1", true) == -1) //still invalid - retry again
    {

        CreateTimer(5.0, RefreshSteamID, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        LoadSteamID(iClient);
    }
}

public Action Timer_AlertGang(Handle hTimer, int userid)
{
    int iClient = userid;
    
    if(!IsValidClient(iClient))
    {
        return;
    }
    
    char szName[MAX_NAME_LENGTH];
    GetClientName(iClient, szName, sizeof(szName));
    PrintToGang(iClient, false, "%T", "GangAlert", iClient, szName);
}

void DissolveGang(char[] GangName)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_players WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_bank_logs WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && StrEqual(ga_sGangName[i], GangName))
        {
            API_OnExitFromGang(i);
            ResetVariables(i);
        }
    }
}

public Action RepeatCheckRank(Handle timer, int iUserID)
{
    int iClient = iUserID;
    LoadSteamID(iClient);
}

public bool CheckBadNameGang(const char[] sName)
{
    bool bTrue = true;
    char file[255];
    BuildPath(Path_SM, file, sizeof(file), "configs/gangs/bad_names.ini");
    if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
    File hFile = OpenFile(file, "r");
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "----------START CHECK BAD NAME----------");
    if(hFile)
    {
        char ItemName[52];
        while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, sizeof(ItemName)))
        {
            ReplaceString(ItemName, sizeof(ItemName), "\n", "");
            PrintToConsoleAll("'%s' : '%s' <-> %d", sName, ItemName, StrContains(sName, ItemName, false));
            if(g_bDebug)
                LogToFile("addons/sourcemod/logs/gangs_debug.txt", "'%s' : '%s' <-> %d", sName, ItemName, StrContains(sName, ItemName, false));
            if(StrContains(sName, ItemName, false) != -1)
            {
                bTrue = false;
                CloseHandle(hFile);
                return bTrue;
            }
        }
    }
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "----------END CHECK BAD NAME----------");
    CloseHandle(hFile);
    return bTrue;
}

void PrintToGang(int iClient, bool bPrintToClient = false, const char[] sMsg, any ...)
{
    if(!IsValidClient(iClient))
    {
        return;
    }
    char sFormattedMsg[256];
    VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 4); 

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[iClient]) && !StrEqual(ga_sGangName[iClient], ""))
        {
            if(bPrintToClient)
            {
                CPrintToChat(i, sFormattedMsg);
            }
            else
            {
                if(i != iClient)
                {
                    CPrintToChat(i, sFormattedMsg);
                }
            }
        }
    }
}

void SetTimeEndGang(char[] gang, int time)
{
    char szQuery[256];
    Format( szQuery, sizeof( szQuery ),"UPDATE gangs_groups SET end_date = '%i' WHERE gang = '%s' AND server_id = %i;", time, gang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, szQuery);
}

public Action SetBankRubles(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET rubles = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i рублей", iClient, shilings-ga_iBankRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i рублей", iClient, ga_iBankRubles[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    
    bool check;int money;
    if(ga_iBankRubles[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankRubles[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankRubles[iClient] - shilings;
    }
    
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i рублей ( Было %i, стало %i)", iClient, money, ga_iBankRubles[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i рублей ( Было %i, стало %i)", iClient, money, ga_iBankRubles[iClient], shilings);
    }
        
    ga_iBankRubles[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankRubles[i]=ga_iBankRubles[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankCredits(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET credits = %i WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>=ga_iBankCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i кредитов", iClient, shilings-ga_iBankCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i кредитов", iClient, ga_iBankCredits[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', %d, %i);", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankCredits[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankCredits[i]=ga_iBankCredits[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankGold(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET gold = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i голды", iClient, shilings-ga_iBankGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i голды", iClient, ga_iBankGold[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankGold[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankGold[i]=ga_iBankGold[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankWCSGold(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET wcsgold = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankWCSGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i WCS голды", iClient, shilings-ga_iBankWCSGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i WCS голды", iClient, ga_iBankWCSGold[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankWCSGold[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankWCSGold[i]=ga_iBankWCSGold[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankLKRubles(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET lk_rubles = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankLKRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i LK рубли", iClient, shilings-ga_iBankLKRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i LK рубли", iClient, ga_iBankLKRubles[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankLKRubles[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankLKRubles[i]=ga_iBankLKRubles[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankMyJBCredits(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET myjb_credits = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankMyJBCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i MyJB Кредиты", iClient, shilings-ga_iBankMyJBCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i MyJB Кредиты", iClient, ga_iBankMyJBCredits[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankMyJBCredits[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankMyJBCredits[i]=ga_iBankMyJBCredits[iClient];
            }
        }
    }
    
    return;
}

void RemoveFromGang(int iClient)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    if(ga_iRank[iClient] == 0)
    {

        char sQuery[300];
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_players WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_bank_logs WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "GangDisbanded", szName, szEscapedGang);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[iClient]) && i != iClient)
            {
                API_OnExitFromGang(i);
                ResetVariables(i, false);
            }
        }
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
    }
    else
    {
        char sQuery1[128];
        Format(sQuery1, sizeof(sQuery1), "DELETE FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery1);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "LeftGang", szName, ga_sGangName[iClient]);
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
    }
}

void ResetVariables(int iClient, bool full = true)
{
    ga_iRank[iClient] = -1;
    ga_iGangSize[iClient] = -1;
    ga_iInvitation[iClient] = -1;
    ga_iDateJoined[iClient] = -1;
    ga_iSize[iClient] = 0;
    ga_iScore[iClient] = 0;
    ga_iBankRubles[iClient] = 0;
    ga_iBankCredits[iClient] = 0;
    ga_iBankGold[iClient] = 0;
    ga_iBankWCSGold[iClient] = 0;
    ga_iExtendCount[iClient] = 0;
    ga_iTempInt1[iClient] = 0;
    ga_iTempInt2[iClient] = 0;
    ga_sGangName[iClient] = "";
    ga_sInvitedBy[iClient] = "";
    ga_bSetName[iClient] = false;
    ga_bIsPlayerInDatabase[iClient] = false;
    ga_bIsGangInDatabase[iClient] = false;
    ga_bHasGang[iClient] = false;
    ga_bRename[iClient] = false;
    ga_iEndTime[iClient] = -1;
    ga_bInvitationSent[iClient] = false;
    g_iBankCountType[iClient] = 0;
    if(full)
    {
        ga_sSteamID[iClient] = "";
        //ga_iProfileID[iClient] = -1;
        //ga_sProfileName[iClient] = "";
        //ga_iProfileSale[iClient] = 0;
        //ga_iDiscount[iClient] = 0;
        //ga_iPlayerShilings[iClient] = 0;
        ga_bBlockInvites[iClient] = false;
        ga_bHasPref[iClient] = false;
        ga_bLoaded[iClient] = false;
    }
}