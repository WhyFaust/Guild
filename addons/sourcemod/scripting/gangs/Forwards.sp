void CreateForwards()
{
	hGangs_OnLoaded = CreateGlobalForward("Gangs_OnLoaded", ET_Ignore);

	hGangs_OnPlayerLoaded = CreateGlobalForward("Gangs_OnPlayerLoaded", ET_Ignore, Param_Cell);
	
	g_hOnGangGoToGang = CreateGlobalForward("Gangs_OnGoToGang", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	
	g_hOnGangExitFromGang = CreateGlobalForward("Gangs_OnExitFromGang", ET_Ignore, Param_Cell);
}

void API_OnGoToGang(int iClient, char[] sGang, int Inviter) {
    if(Inviter == -1)
        Inviter = iClient;
    Call_StartForward(g_hOnGangGoToGang);
    Call_PushCell(iClient);
    Call_PushString(sGang);
    Call_PushCell(Inviter);
    Call_Finish();
}

void API_OnExitFromGang(int iClient) {
    Call_StartForward(g_hOnGangExitFromGang);
    Call_PushCell(iClient);
    Call_Finish();
}