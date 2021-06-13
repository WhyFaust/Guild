/* Gang expired */
public Action Timer_CheckGangEnd(Handle timer)
{
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Check Gang End");
    
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "SELECT id, end_date \
                                    FROM gang_group;");
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
        int gangid = results.FetchInt(0);
        int endtime = results.FetchInt(1);
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "(%i>%i, %i) - Check gang end time", GetTime(), endtime, gangid);
        if(GetTime()>endtime) DissolveGang(gangid);
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

public Action Timer_AlertGang(Handle hTimer, int iClient)
{
    if(!IsValidClient(iClient))
        return;
    
    char szName[MAX_NAME_LENGTH];
    GetClientName(iClient, szName, sizeof(szName));
    PrintToGang(iClient, false, "%T", "GangAlert", iClient, szName);
}

void DissolveGang(int gangid)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 34);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_statistic \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 35);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_bank_log \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 36);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_perk \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 37);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_group \
                                    WHERE id = %i AND server_id = %i;", 
                                    gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 38);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && ga_iGangId[i] == gangid)
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
        return;

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
                    CPrintToChat(i, sFormattedMsg);
            }
        }
    }
}

void SetTimeEndGang(int iClient, int iTime)
{				
    ga_iExtendCount[iClient]++;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(ga_iGangId[i] == ga_iGangId[iClient])
                ga_iExtendCount[i]++;

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET end_date = %i, extend_count = %i \
                                    WHERE id = %i;", 
                                    iTime, ga_iExtendCount[iClient], ga_iGangId[iClient]);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 6);
}

public Action SetBankRubles(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET rubles = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 7);

    char log[300];
    if(shilings > ga_iBankRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i рублей", iClient, shilings-ga_iBankRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i рублей", iClient, ga_iBankRubles[iClient]-shilings);

    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 8);
    
    bool check;
    int money;
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
        
    ga_iBankRubles[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankRubles[i] = ga_iBankRubles[iClient];
    
    return;
}

public Action SetBankCredits(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET credits = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 9);

    char log[300];
    if(shilings > ga_iBankCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i кредитов", iClient, shilings-ga_iBankCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i кредитов", iClient, ga_iBankCredits[iClient]-shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES(%i, %i, '%s', %d);", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 10);
    
    bool check;
    int money;
    if(ga_iBankCredits[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankCredits[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankCredits[iClient] - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i кредитов ( Было %i, стало %i)", iClient, money, ga_iBankCredits[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i кредитов ( Было %i, стало %i)", iClient, money, ga_iBankCredits[iClient], shilings);
    }

    ga_iBankCredits[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankCredits[i] = ga_iBankCredits[iClient];
    
    return;
}

public Action SetBankGold(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET gold = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 11);

    char log[300];
    if(shilings > ga_iBankGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i голды", iClient, shilings-ga_iBankGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i голды", iClient, ga_iBankGold[iClient]-shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 12);
    
    bool check;
    int money;
    if(ga_iBankGold[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankGold[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankGold[iClient] - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i голды ( Было %i, стало %i)", iClient, money, ga_iBankGold[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i голды ( Было %i, стало %i)", iClient, money, ga_iBankGold[iClient], shilings);
    }

    ga_iBankGold[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankGold[i] = ga_iBankGold[iClient];
    
    return;
}

public Action SetBankWCSGold(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET wcsgold = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 13);

    char log[300];
    if(shilings > ga_iBankWCSGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i WCS голды", iClient, shilings-ga_iBankWCSGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i WCS голды", iClient, ga_iBankWCSGold[iClient]-shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 14);
    
    bool check;
    int money;
    if(ga_iBankWCSGold[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankWCSGold[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankWCSGold[iClient] - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i wcs голды ( Было %i, стало %i)", iClient, money, ga_iBankWCSGold[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i wcs голды ( Было %i, стало %i)", iClient, money, ga_iBankWCSGold[iClient], shilings);
    }

    ga_iBankWCSGold[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankWCSGold[i] = ga_iBankWCSGold[iClient];
    
    return;
}

public Action SetBankLKRubles(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET lk_rubles = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 15);

    char log[300];
    if(shilings > ga_iBankLKRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i LK рубли", iClient, shilings - ga_iBankLKRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i LK рубли", iClient, ga_iBankLKRubles[iClient] - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES(%i, %i, '%s', '%d');", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 16);
    
    bool check;
    int money;
    if(ga_iBankLKRubles[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankLKRubles[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankLKRubles[iClient] - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i LK рублей ( Было %i, стало %i)", iClient, money, ga_iBankLKRubles[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i LK рублей ( Было %i, стало %i)", iClient, money, ga_iBankLKRubles[iClient], shilings);
    }

    ga_iBankLKRubles[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankLKRubles[i] = ga_iBankLKRubles[iClient];
    
    return;
}

public Action SetBankMyJBCredits(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET myjb_credits = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, ga_iGangId[iClient], g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 17);

    char log[300];
    if(shilings > ga_iBankMyJBCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i MyJB Кредиты", iClient, shilings - ga_iBankMyJBCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i MyJB Кредиты", iClient, ga_iBankMyJBCredits[iClient] - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    ga_iGangId[iClient], ga_iPlayerId[iClient], log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 18);
    
    bool check;
    int money;
    if(ga_iBankMyJBCredits[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankLKRubles[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankMyJBCredits[iClient] - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i MyJB кредитов ( Было %i, стало %i)", iClient, money, ga_iBankMyJBCredits[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i MyJB кредитов ( Было %i, стало %i)", iClient, money, ga_iBankMyJBCredits[iClient], shilings);
    }

    ga_iBankMyJBCredits[iClient] = shilings;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && iClient != i)
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                ga_iBankMyJBCredits[i] = ga_iBankMyJBCredits[iClient];
    
    return;
}

void RemoveFromGang(int iClient)
{
    char sQuery[300];
    if(ga_iRank[iClient] == 0)
    {
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                        WHERE gang_id = %i;", 
                                        ga_iGangId[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 19);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_statistic \
                                        WHERE gang_id = %i;", 
                                        ga_iGangId[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 20);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_bank_log \
                                        WHERE gang_id = %i;", 
                                        ga_iGangId[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 21);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_perk \
                                        WHERE gang_id = %i;", 
                                        ga_iGangId[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 22);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_group \
                                        WHERE id = %i AND server_id = %i;", 
                                        ga_iGangId[iClient], g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 23);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "GangDisbanded", szName, ga_sGangName[iClient]);
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
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                        WHERE id = %i AND gang_id = %i;", 
                                        ga_iPlayerId[iClient], ga_iGangId[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 24);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "LeftGang", szName, ga_sGangName[iClient]);
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
    }
}

/*****************************************************************
***********************	 GANG CREATION	**************************
******************************************************************/
void StartGangCreation(int iClient)
{
    if(!IsValidClient(iClient))
    {
        ReplyToCommand(iClient, "[SM] %t", "PlayerNotInGame", iClient);
        return;
    }
    if(g_bTerroristOnly && GetClientTeam(iClient) != 2)
    {
        ReplyToCommand(iClient, "[SM] %t", "WrongTeam", iClient);
        return;
    }
    for(int i = 0; i <= 5; i++)
    {
        CPrintToChat(iClient, "%t %t", "Prefix", "GangName");
    }
    ga_bSetName[iClient] = true;
}

/*****************************************************************
***********************	     OTHER	    **************************
******************************************************************/
public Action Timer_OpenGangMenu(Handle hTimer, int userid)
{
    int iClient = userid;

    if(IsValidClient(iClient))
        StartOpeningGangMenu(iClient);
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
    ga_iGangId[iClient] = -1;
    ga_sGangName[iClient] = "";
    ga_sInvitedBy[iClient] = "";
    ga_bSetName[iClient] = false;
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
        ga_bLoaded[iClient] = false;
    }
}