#if defined gangs_size_include
  #endinput
#endif
#define gangs_size_include

/**
 *
 * Возвращает значение максимального уровня перка
 *
 * @return int
 *
 */
native int Gangs_Size_GetMaxLvl();

/**
 *
 * Возвращает текущий уровень перка
 *
 * @return int
 *
 */
native int Gangs_Size_GetCurrectLvl(int client);

public SharedPlugin __pl_gangs  =
{
	name = "gangs_size",
	file = "gangs_size.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gangs_size_SetNTVOptional()
{
	MarkNativeAsOptional("Gangs_Size_GetMaxLvl");
	MarkNativeAsOptional("Gangs_Size_GetCurrectLvl");
}
#endif