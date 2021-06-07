void CreateForwards()
{
	hGangs_OnLoaded = CreateGlobalForward("Gangs_OnLoaded", ET_Ignore);
	
	g_hOnGangGoToGang = CreateGlobalForward("Gangs_OnGoToGang", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	
	g_hOnGangExitFromGang = CreateGlobalForward("Gangs_OnExitFromGang", ET_Ignore, Param_Cell);
}