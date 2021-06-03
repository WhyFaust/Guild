#pragma newdecls required

#include <gangs>
#include <gifts_core>

public Plugin myinfo =
{
	name = "[Gangs] Score Gift",
	author = "R1KO, baferpro",
	version = GANGS_VERSION
}

public int Gifts_OnPickUpGift_Post(int iClient, Handle hKeyValues)
{
	if(IsValidClient(iClient))
	{
		int iValue = KvGetNum(hKeyValues, "gangs_score", 0);
		if(iValue && Gangs_ClientHasGang(iClient))
		{
			Gangs_SetClientGangScore(iClient, iValue);
		}
	}
}