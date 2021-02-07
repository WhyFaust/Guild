#if defined gamecms_system_include
  #endinput
#endif
#define gamecms_system_include


native Database GameCMS_GetDatabase();

native bool GameCMS_Registered(int iClient);

native int GameCMS_GetClientID(int iClient);

native int GameCMS_GetClientRating(int iClient);

native void GameCMS_GetClientName(int iClient, char[] sBuffer, int MaxLength);

native int GameCMS_GetClientRubles(int iClient);

native void GameCMS_SetClientRubles(int iClient, int Rubles);

native int GameCMS_GetClientDiscount(int iClient);

native int GameCMS_GetGlobalDiscount();

native int GameCMS_SendNotification(int iClient, char[] sMessage);

public SharedPlugin __pl_gamecms_system  =
{
	name = "gamecms_system",
	file = "gamecms_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gamecms_system_SetNTVOptional()
{
	MarkNativeAsOptional("GameCMS_GetDatabase");
	MarkNativeAsOptional("GameCMS_Registered");
	MarkNativeAsOptional("GameCMS_GetClientID");
	MarkNativeAsOptional("GameCMS_GetClientName");
	MarkNativeAsOptional("GameCMS_GetClientRubles");
	MarkNativeAsOptional("GameCMS_SetClientRubles");
	MarkNativeAsOptional("GameCMS_GetClientDiscount");
	MarkNativeAsOptional("GameCMS_GetGlobalDiscount");
	MarkNativeAsOptional("GameCMS_SendNotification");
}
#endif