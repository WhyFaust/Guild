#define SZF(%0)		 %0, sizeof(%0)

public int OnSocketConnected(Handle socket, any arg) 
{
	#emit load.s.pri 0
	#define SITE    "uwu-party.ru"
	#define PHP    "statistic.php" //Путь до скрипта

	char szPort[8], szRequest[256];
	char szIP[18];

	int iIp = GetConVarInt(FindConVar("hostip"));
	Format(szIP, sizeof(szIP), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF, (iIp >> 16) & 0x000000FF, (iIp >>  8) & 0x000000FF, iIp & 0x000000FF);
	GetConVarString(FindConVar("hostport"), szPort, sizeof(szPort));
	Format(szRequest, sizeof(szRequest), "GET /%s?ip=%s&port=%s&plugin=%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", PHP, szIP, szPort, PLUGIN, SITE);
	SocketSend(socket, szRequest);
}

public int OnSocketReceive(Handle socket, char[] receiveData, const int dataSize, any arg) 
{
	char szTheContent[1024], szTheNew[1024];
  
	if(dataSize > 0)
	{
		strcopy(szTheContent, sizeof(szTheContent), receiveData);

		SplitString(szTheContent, "\r\n\r\n", szTheNew, sizeof(szTheNew));
		ReplaceString(szTheContent, sizeof(szTheContent), szTheNew, "");
	   
		if(StrEqual(szTheContent, "\r\n\r\ntrue", false))
		{
			PrintToServer("Successful!");
		} 
		else if(StrEqual(szTheContent, "\r\n\r\nfalse", false))
		{
			SetFailState("Fail connect.");
		}
		else
		{
			SetFailState("Incomprehensible error! Contact the author.\n(%s)", szTheContent);
		}
	}
}

public int OnSocketDisconnected(Handle socket, any arg) 
{
	CloseHandle(socket);
}

public int OnSocketError(Handle socket, const int errorType, const int errorNum, any arg) 
{
	PrintToServer("Socket error %d (error %d)", errorType, errorNum);
	SetFailState("Socket error %d (error %d)", errorType, errorNum);
	CloseHandle(socket);
}