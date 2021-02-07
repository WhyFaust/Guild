#if defined gangs_adminmenu_include
  #endinput
#endif
#define gangs_adminmenu_include

/**
*
* Админ распустил банду
*    -
* @param iClient             Индекс админа
* @param sGangName           Название распущенной банды
*
*/
forward void Gangs_AdminDissolveGang(int iClient, char[] sGangName);

public SharedPlugin __pl_gangs_adminmenu  =
{
	name = "gangs_adminmenu",
	file = "gangs_adminmenu.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};