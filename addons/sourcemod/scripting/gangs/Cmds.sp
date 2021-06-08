void RegAllCmds()
{
	RegConsoleCmd("gangs_config_reload", Command_Gang_Config_Reload, "Reload config file!");
	if (!g_bInviteStyle)
	{
		RegConsoleCmd("sm_accept", Command_Accept, "Accept an invitation!");
	}
}

public Action Command_Accept(int iClient, int args)
{
	if (!g_bPluginEnabled)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "DisabledPlugin");
		return Plugin_Handled;
	}
	if (g_bInviteStyle)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "DisabledAcceptCommand");
		return Plugin_Handled;
	}

	if (!IsValidClient(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (g_bTerroristOnly && GetClientTeam(iClient) != 2)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "WrongTeam");
		return Plugin_Handled;
	}
	if (ga_bHasGang[iClient])
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "AlreadyInGang");
		return Plugin_Handled;
	}
	if (ga_iInvitation[iClient] == -1)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "NotInvited");
		return Plugin_Handled;
	}
	
	int sender = ga_iInvitation[iClient];
	if (ga_iGangSize[sender] >= g_iSize + Gangs_Size_GetCurrectLvl(sender))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "GangIsFull");
		return Plugin_Handled;
	}

	ga_sGangName[iClient] = ga_sGangName[sender];
	ga_iDateJoined[iClient] = GetTime();
	ga_bHasGang[iClient] =	true;
	ga_bSetName[iClient] = false;

	char szName[MAX_NAME_LENGTH];
	GetClientName(sender, szName, sizeof(szName));
	
	ga_iScore[iClient] = ga_iScore[sender];
	ga_iBankRubles[iClient] = ga_iBankRubles[sender];
	ga_iBankCredits[iClient] = ga_iBankCredits[sender];
	ga_iBankGold[iClient] = ga_iBankGold[sender];
	ga_iBankWCSGold[iClient] = ga_iBankWCSGold[sender];
	ga_iBankLKRubles[iClient] = ga_iBankLKRubles[sender];
	ga_iExtendCount[iClient] = ga_iExtendCount[sender];
	ga_iSize[iClient] = ga_iSize[sender];
	ga_iGangSize[iClient] = ++ga_iGangSize[sender];
	
	ga_bInvitationSent[sender] = false;

	ga_sInvitedBy[iClient] = szName;
	ga_iRank[iClient] = GetLastConfigRank();
	UpdateSQL(iClient);
	GetClientName(iClient, szName, sizeof(szName));
	CPrintToChatAll("%t %t", "Prefix", "GangJoined", szName, ga_sGangName[iClient]);
	return Plugin_Handled;
}

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

public Action Command_Gang_Config_Reload(int iClient, int args)
{
    OnMapStart();
    return Plugin_Handled;
}