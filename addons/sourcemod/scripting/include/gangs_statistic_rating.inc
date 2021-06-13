#if defined gangs_statistic_rating_include
  #endinput
#endif
#define gangs_statistic_rating_include

/**
 *
 * Возвращает текущий рейтинг игрока
 *
 * @return int
 *
 */
native int Gangs_StatisticRating_GetClientRating(int iClient);

/**
 *
 * Устанавливает рейтинг игроку
 *
 * @no return
 *
 */
native int Gangs_StatisticRating_SetClientRating(int iClient, int iRating);

public SharedPlugin __pl_gangs_statistic_rating  =
{
	name = "gangs_statistic_rating",
	file = "gangs_statistic_rating.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_gangs_statistic_rating_SetNTVOptional()
{
	MarkNativeAsOptional("Gangs_StatisticRating_GetClientRating");
	MarkNativeAsOptional("Gangs_StatisticRating_SetClientRating");
}
#endif