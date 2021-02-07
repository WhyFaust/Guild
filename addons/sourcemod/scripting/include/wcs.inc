#if defined _wcs_included
 #endinput
#endif
#define _wcs_included

/**
 * GetRealSpeed, GetRealGravity, GetRealAlpha, GetRealHealth
 * ¬озвращают значени€, включа€ прибавки скиллов.
 * ј GetRealModel возвращает значение,
 * которое было до установки скиллов.
 */

/**
 * Get client's Anti Ultimate Status.
 *
 * @param index    An integer.
 * @return        Anti Ultimate Status.
 */
native bool WCS_GetAntiUlt(int index);

/**
 * Get client's Anti Aura Status.
 *
 * @param index    An integer.
 * @return        Anti Aura Status.
 */
native bool WCS_GetAntiAura(int index);

/**
 * Get client's Anti Totem Status.
 *
 * @param index    An integer.
 * @return        Anti Totem Status.
 */
native bool WCS_GetAntiTotem(int index);

/**
 * Get client's credits.
 *
 * @param index    An integer.
 * @return        Client's credits.
 */
native int WCS_GetCredits(int index);

/**
 * Get client's gold.
 *
 * @param index    An integer.
 * @return        Client's gold.
 */
native int WCS_GetGold(int index);

/**
 * Get client's lvl.
 *
 * @param index    An integer.
 * @return        Client's lvl.
 */
native int WCS_GetLvl(int index);

/**
 * Get client's race lvl.
 *
 * @param index    An integer.
 * @return        Client's race lvl.
 */
native int WCS_GetCLvl(int index);

/**
 * Get client's Level Bank lvl.
 *
 * @param index    An integer.
 * @return        Client's Level Bank lvl.
 */
native int WCS_GetLBlvl(int index);

/**
 * Get client's vip status.
 * 
 * @param index    An integer.
 * @return        true on success, false otherwise.
 */
native bool WCS_GetVip(int index);

/**
 * Get client's xp.
 *
 * @param index    An integer.
 * @return        Client's xp.
 */
native int WCS_GetXp(int index);

/**
 * Get client's xp difference.
 *
 * @param index    An integer.
 * @return        Client's xp.
 */
native int WCS_GetXpDifference(int index);

/**
 * Get client's race name.
 *
 * @param index    An integer.
 * @param race	   An string.
 * @params size    An integer.
 * @return        true on success.
 */
native bool WCS_GetRace(int index, char[] race, int size);

/**
 * Get client's real speed.
 *
 * @param index    An integer.
 * @return        Client's speed.
 */
native float WCS_GetRealSpeed(int index);

/**
 * Get client's real gravity.
 *
 * @param index    An integer.
 * @return        Client's speed.
 */
native float WCS_GetRealGravity(int index);

/**
 * Get client's real alpha.
 *
 * @param index    An integer.
 * @return        Client's alpha.
 */
native int WCS_GetRealAlpha(int index);

/**
 * Get client's real health.
 *
 * @param index    An integer.
 * @return        Client's health.
 */
native int WCS_GetRealHealth(int index);

/**
 * Get client's real model.
 *
 * @param index    An integer.
 * @param model    An string.
 * @param size     An integer.
 * @return        true on success, false otherwise.
 */
native bool WCS_GetRealModel(int index, char[] model, int size);

/**
 * Get random client between radius.
 *
 * @param client    An integer.
 * @param radius    An float.
 * @param checkImmun An bool.
 * @return        random client on true.
 */
native int WCS_GetRandomPosition(int client, float radius, bool checkImmun);

/**
 * Get nearest client between radius.
 *
 * @param client    An integer.
 * @param radius    An float.
 * @param checkImmun An bool.
 * @return        nearest client on true.
 */
native int WCS_GetBestPosition(int client, float radius, bool checkImmun);

/**
 * Get client is admin.
 *
 * @param client    An integer.
 * @return        true if client is admin, false otherwise.
 */
native bool WCS_GetWcsAdmin(int client);

/**
 * Init Effects to client & attacker [optional].
 * If you want to use effect only for client:
 * InitEffects(int client, client, effect);
 *
 * @param client    An integer.
 * @param victim    An integer.
 * @param effect    An string.
 * @return        true on success.
 */
native bool WCS_InitEffects(int client, int victim, const char[] effect);

/**
 * Give client credits.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_GiveCredits(int client, int value);

/**
 * Give client gold.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_GiveGold(int client, int value);

/**
 * Give client lvl.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_GiveLvl(int client, int value);

/**
 * Give client race lvl.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_GiveCLvl(int client, int value);

/**
 * Give client Level Bank lvl.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_GiveLBlvl(int client, int value);

/**
 * Give client xp.
 *
 * @param client    An integer.
 * @param value     An integer.
 * @param announce  An bool.
 * @return        true on success.
 */
native bool WCS_GiveXp(int client, int value, bool announce = true);

/**
 * Take client credits.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_TakeCredits(int client, int value);

/**
 * Take client gold.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_TakeGold(int client, int value);

/**
 * Take client Level Bank lvl.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success.
 */
native bool WCS_TakeLBlvl(int client, int value);

/**
 * Set client real speed.
 *
 * @param client    An integer.
 * @param value    An float.
 * @return        true on success.
 */
native bool WCS_SetRealSpeed(int client, float value);

/**
 * Set client real gravity.
 *
 * @param client    An integer.
 * @param value    An float.
 * @return        true on success.
 */
native bool WCS_SetRealGravity(int client, float value);

/**
 * Set client real alpha.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success, false otherwise.
 */
native bool WCS_SetRealAlpha(int client, int value);

/**
 * Set client real health.
 *
 * @param client    An integer.
 * @param value    An integer.
 * @return        true on success, false otherwise.
 */
native bool WCS_SetRealHealth(int client, int value);

/**
 * Set client's real model.
 *
 * @param index    An integer.
 * @param model    An string.
 * @return        true on success, false otherwise.
 */
native bool WCS_SetRealModel(int index, const char[] model);

/**
 * Set client's race.
 *
 * @param index    An integer.
 * @param race     An String.
 * @param suicide  An bool. (Check or not CVAR 'wcs_cr_suicide' = 1 then client will be killed)
 * @return        true on success, false otherwise.
 */
native bool WCS_SetRace(int index, const char[] race, bool suicide = true);

/**
 * Reset client's skills.
 *
 * @param index    An integer.
 * @param fully    An bool. (if true then dont reuse skills after this operation)
 * @return        true on success, false otherwise.
 */
native bool WCS_ResetSkills(int client, bool fully);

/**
 * Reset client ultimate cooldown.
 *
 * @param client    An integer.
 * @return        true on success.
 */
native bool WCS_ResetUltCld(int client);

/**
 * Reset client ability cooldown.
 *
 * @param client    An integer.
 * @return        true on success, false otherwise.
 */
native bool WCS_ResetAbilityCld(int client);

/**
 * Checks if the race is private
 *
 * @param racename	An string. [64]
 * @return			true on success, false otherwise.
 */
native bool WCS_IsRacePrivate(const char[] RaceName);

/**
 * Gives a private race to client
 *
 * @param steamid	An string. [64]
 * @param racename	An string. [64]
 * @return			true on success, false otherwise.
 */
native bool WCS_GivePrivateRace(const char[] SteamId, const char[] RaceName);

/**
 * Take a private race from client
 *
 * @param steamid	An string. [64]
 * @param racename	An string. [64]
 * @return			true on success, false otherwise.
 */
native bool WCS_TakePrivateRace(const char[] SteamId, const char[] RaceName);

/**
 * Get required lvl for race
 *
 * @param racename	An string. [64]
 * @return			required lvl on success, -1 otherwise.
 */
native int WCS_GetRaceReqLvl(const char[] RaceName);

/**
 * Get client's totems count that he can use (every use totem this value will decreased and restored on special events [this value = GetClientTotemsMax on special events])
 *
 * @param client	An integer.
 * @return			Amount of totems.
 */
native int WCS_GetClientTotems(int client);

/**
 * Get client's totems count maximum
 *
 * @param client	An integer.
 * @return			Amount of maximum totems.
 */
native int WCS_GetClientTotemsMax(int client);

/**
 * Called on client skill lvl up
 *
 */
forward void WCS_OnSkillLvlUp(int client, int skilllvl, const char[] skillname);

/**
 * Called on client lvl up
 *
 */
forward void WCS_OnLvlUp(int client, int lvl);

/**
 * Called on client ultimate cooldown has finished
 *
 */
forward void WCS_OnUltimateCld(int client);

/**
 * Called on client ability cooldown has finished
 *
 */
forward void WCS_OnAbilityCld(int client);

/**
 * Called on client skills has resetted
 *
 */
forward void WCS_OnSkillsReset(int client);

/**
 * Called on client xp gain
 *
 */
forward void WCS_OnXpGain(int client, int xp, bool lvlup);

/**
 * Called on client gold gain
 *
 */
forward void WCS_OnGoldGain(int client, int gold);

/**
 * Called on client ultimate pre
 *
 */
forward Action WCS_OnUltimatePre(int client, const char[] ultimate);

/**
 * Called on client ultimate post
 *
 */
forward void WCS_OnUltimatePost(int client);

/**
 * Called on client ability pre
 *
 */
forward Action WCS_OnAbilityPre(int client, const char[] ability);

/**
 * Called on client ability post
 *
 */
forward void WCS_OnAbilityPost(int client);

/**
 * Called on client change race pre
 *
 */
forward Action WCS_OnRaceChangePre(int client, const char[] OldRace, const char[] NewRace);

/**
 * Called on client change race post
 *
 */
forward void WCS_OnRaceChangePost(int client);

/**
 * Called on client item purchase pre
 *
 * PaymentType -- "cash" или "gold"
 */
forward Action WCS_OnItemPurchasePre(int client, const char[] ItemName, const char[] BlockName, int ItemCost, const char[] PaymentType);

/**
 * Called on client item purchase post
 *
 */
forward void WCS_OnItemPurchasePost(int client);

/**
 * Called on client skills just set pre
 *
 */
forward Action WCS_OnSkillsSetPre(int client, const char[] Race);

/**
 * Called on client skills just set
 *
 */
forward void WCS_OnSkillsSet(int client, const char[] Race);

/**
 * Called on client loaded
 *
 */
forward void WCS_OnClientLoaded(int client);