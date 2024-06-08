using CounterStrikeSharp.API;
using CounterStrikeSharp.API.Core;
using CounterStrikeSharp.API.Core.Attributes.Registration;
using CounterStrikeSharp.API.Modules.Admin;
using CounterStrikeSharp.API.Modules.Commands;
using CounterStrikeSharp.API.Modules.Cvars;
using CounterStrikeSharp.API.Modules.Entities;
using Dapper;
using Microsoft.Extensions.Logging;
using MySqlConnector;
using System.Data;
using System.Data.Common;
using System.Text;
using static Dapper.SqlMapper;

namespace Guild;

public partial class Guild
{
	private void RegisterEvents()
	{
		RegisterListener<Listeners.OnMapStart>(OnMapStart);
        RegisterListener<Listeners.OnClientAuthorized>(OnClientAuthorized);
		//RegisterListener<Listeners.OnClientConnected>(OnClientConnected);
		//RegisterListener<Listeners.OnClientDisconnect>(OnClientDisconnect);
		AddCommandListener("say", OnCommandSay);
		AddCommandListener("say_team", OnCommandSay);

        RegisterListener<Listeners.OnMapEnd>(() => 
        {
            foreach(var gang in GangList)
            {
                Task.Run(async () =>
                {
                    try
                    {
                        await using (var connection = new MySqlConnection(dbConnectionString))
                        {
                            await connection.OpenAsync();
                            await connection.QueryAsync(@"
                                UPDATE gangs_group SET exp = @exp WHERE id = @id", 
                                new { exp = gang.Exp,
                                    id = gang.DatabaseID});
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.LogError($"{ex.Message}");
                        throw;
                    }
                });
            }
        });
	}

    private void OnClientAuthorized(int playerSlot, SteamID steamID)
	{
		CCSPlayerController? player = Utilities.GetPlayerFromSlot(playerSlot);

		if (player == null || !player.IsValid || player.IsBot || player.IsHLTV)
			return;

		if (player.AuthorizedSteamID == null)
		{
			AddTimer(3.0f, () =>
			{
				OnClientAuthorized(playerSlot, steamID);
			});
			return;
		}

        string nickname = player.PlayerName;
        string steamid = steamID.SteamId2;
        Task.Run(async () => 
        {
            try
            {
                await using (var connection = new MySqlConnection(dbConnectionString))
                {
                    await connection.OpenAsync();
                    var command = connection.CreateCommand();
                    string sql = $"SELECT player_table.* FROM `gang_player` AS `player_table` INNER JOIN `gang_group` AS `gang_table` ON player_table.gang_id = gang_table.id WHERE player_table.steam_id = '{steamid}' AND gang_table.server_id = {Config.ServerId};";
                    command.CommandText = sql;
                    var reader = await command.ExecuteReaderAsync();
                    if(await reader.ReadAsync())
                    {
                        userInfo[playerSlot] = new UserInfo{
                            SteamID = reader.GetString(2),
                            Status = 0,
                            DatabaseID = reader.GetInt32(0),
                            GangId = reader.GetInt32(1),
                            Rank = reader.GetInt32(4),
                            InviterName = reader.GetString(5),
                            InviteDate = reader.GetInt32(6)
                        };
                        if(!String.Equals(reader.GetString(3), nickname))
                        {
                            sql = $"UPDATE `gang_player` SET `name` = '{nickname}' WHERE `id` = '{reader.GetInt32(0)}'";
                            command.CommandText = sql;
                            await command.ExecuteNonQueryAsync();
                        }
                    }
                    else
                    {
                        userInfo[playerSlot] = new UserInfo{ SteamID = steamid };
                    }
                    reader.Close();
                        
                };
            }
            catch (Exception ex)
            {
                Logger.LogError("{OnClientAuthorized} Failed get info in database | " + ex.Message);
                Logger.LogDebug(ex.Message);
                throw new Exception("[Guild] Failed get info in database! | " + ex.Message);
            }
        });
	}


	[GameEventHandler]
	public HookResult OnClientDisconnect(EventPlayerDisconnect @event, GameEventInfo info)
	{		
        CCSPlayerController? player = @event.Userid;

		if (player is null
			|| string.IsNullOrEmpty(player.IpAddress) || player.IpAddress.Contains("127.0.0.1")
			|| player.IsBot || player.IsHLTV || !player.UserId.HasValue) return HookResult.Continue;

        Array.Clear(userInfo, player.Slot, 1);

		return HookResult.Continue;
	}

	public HookResult OnCommandSay(CCSPlayerController? player, CommandInfo info)
	{
        if (player == null || !player.IsValid || player.IsBot || player.IsHLTV)
			return HookResult.Continue;

        var slot = player.Slot;

        if(userInfo[slot].Status == 1 || userInfo[slot].Status == 2)
        {
            var message = info.ArgString;
            message = message.Trim('"');
            if(String.Equals(info.ArgString,"cancel"))
            {
                userInfo[slot].Status = 0;
                return HookResult.Handled;
            }

            if(message.Length > 16)
            {
                player.PrintToChat($" {TextColor.Green}Название слишком длинное");
                return HookResult.Handled;
            }
            else if(message.Length < 3)
            {
                player.PrintToChat($" {TextColor.Green}Название слишком короткое");
                return HookResult.Handled;
            }
            else if(message.Length == 0)
            {
                return HookResult.Handled;
            }
            var playerName = player.PlayerName;
            var createDate = Helper.GetNowUnixTime();
            var addDay = Helper.ConvertUnixToDateTime(createDate).AddDays(Convert.ToInt32(Config.CreateCost.Days));
            var endDate = (int)(addDay.ToUniversalTime() - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds;
            Task.Run(async () =>
            {
                try
                {
                    await using (var connection = new MySqlConnection(dbConnectionString))
                    {
                        await connection.OpenAsync();
        
                        var command = connection.CreateCommand();
                        string sql = $"SELECT `name` FROM `gang_group` WHERE name = '{message}' AND server_id = {Config.ServerId}";
                        command.CommandText = sql;
                        var reader = await command.ExecuteReaderAsync();
                        if (await reader.ReadAsync() == false)
                        {
                            reader.Close();
                            if(userInfo[slot].Status == 1)
                            {
                                sql = $"INSERT INTO `gang_group` (`name`, `server_id`, `create_date`, `end_date`) VALUES ('{message}', {Config.ServerId}, {createDate}, {endDate});";
                                await connection.ExecuteAsync(sql);
                                sql = $"SELECT `id` FROM `gang_group` WHERE name = '{message}' AND server_id = {Config.ServerId}";
                                command.CommandText = sql;
                                var reader2 = await command.ExecuteReaderAsync();
                                if (await reader2.ReadAsync())
                                {
                                    var gangId = reader2.GetInt32(0);
                                    reader2.Close();
                                    GangList.Add(new Gang(
                                        message,
                                        Config.ServerId,
                                        createDate,
                                        endDate,
                                        new(),
                                        new(),
                                        0,
                                        gangId));
                                    
                                    sql = $"INSERT INTO `gang_perk` (`gang_id`) VALUES ('{gangId}');";
                                    await connection.ExecuteAsync(sql);
                                    sql = $"INSERT INTO `gang_player` (`gang_id`, `steam_id`, `name`, `rank`, `inviter_name`, `invite_date`) VALUES ('{gangId}', '{userInfo[slot].SteamID}', '{playerName}', 0, '{playerName}', {createDate});";
                                    await connection.ExecuteAsync(sql);

                                    sql = $"SELECT `id` FROM `gang_player` WHERE gang_id = '{gangId}' AND steam_id = '{userInfo[slot].SteamID}'";
                                    command.CommandText = sql;
                                    var reader3 = await command.ExecuteReaderAsync();
                                    if (await reader3.ReadAsync())
                                    {
                                        var steamID = userInfo[slot].SteamID;
                                        userInfo[slot] = new UserInfo
                                        {
                                            SteamID = steamID,
                                            Status = 0,
                                            DatabaseID = reader3.GetInt32(0),
                                            GangId = gangId,
                                            Rank = 0,
                                            InviterName = playerName,
                                            InviteDate = createDate
                                        };
                                        var gang = GangList.Find(x => x.DatabaseID == userInfo[slot].GangId);
                                        if (gang != null) gang.MembersList.Add(userInfo[slot]);
                                        if (Config.CreateCost.Value > 0) 
                                        {
                                            if(Config.CreateCost.Mode == 0 && _shopApi != null) _shopApi.SetClientCredits(player, _shopApi.GetClientCredits(player) - Config.CreateCost.Value);
                                        }
                                        Server.NextFrame(() =>
                                        {
                                            if (gang != null) _api!.OnGuildCreated(player, gang.DatabaseID);
                                            Server.PrintToChatAll($" {TextColor.Red}{playerName}{TextColor.Green} создал банду {TextColor.Red}{message}");
                                        });
                                    }
                                    reader3.Close();
                                }
                            }
                            else if(userInfo[slot].Status == 2)
                            {
                                sql = $"UPDATE `gang_group` SET `name` = '{message}' WHERE `id` = '{userInfo[player.Slot].GangId}'";
                                await connection.ExecuteAsync(sql);
                                var gang = GangList.Find(x=>x.DatabaseID == userInfo[player.Slot].GangId);
                                if (gang != null) gang.Name = message;
                                userInfo[player.Slot].Status = 0;
                                if (Config.RenameCost.Value > 0) 
                                {
                                    if(Config.RenameCost.Mode == 0 && _shopApi != null) _shopApi.SetClientCredits(player, _shopApi.GetClientCredits(player) - Config.RenameCost.Value);
                                }
                                Server.NextFrame(() =>
                                {
                                    Server.PrintToChatAll($" {TextColor.Red}{playerName}{TextColor.Green} переименовал банду на {TextColor.Red}{message}");
                                });
                            }
                        }
                        else
                        {
                            Server.NextFrame(() => player.PrintToChat($" {TextColor.Green}Название уже используется"));
                        }
                    }
                }
                catch (Exception ex)
                {
                    Logger.LogError("{OnCommandSay} Failed create in database | " + ex.Message);
                    Logger.LogDebug(ex.Message);
                    throw new Exception("[Guild] Failed create in database! | " + ex.Message);
                }
            });
            return HookResult.Continue;
        }

        return HookResult.Continue;
	}

	private void OnMapStart(string mapName)
	{
        Task.Run(async () =>
        {
            try
            {   
                await using (var connection = new MySqlConnection(dbConnectionString))
                {
                    await connection.OpenAsync();
                    var command = connection.CreateCommand();
                    string sql = $"SELECT `name`, `create_date`, `end_date`, `exp`, `id` FROM `gang_group` WHERE server_id = {Config.ServerId};";
                    command.CommandText = sql;
                    var reader = await command.ExecuteReaderAsync();
                    while(await reader.ReadAsync())
                    {
                        GangList.Add(new Gang(
                            reader.GetString(0),
                            Config.ServerId,
                            reader.GetInt32(1),
                            reader.GetInt32(2),
                            new(),
                            new(),
                            reader.GetInt32(3),
                            reader.GetInt32(4)
                        ));
                    }
                    reader.Close();
                    sql = $"SELECT * FROM `gang_perk`;";
                    command.CommandText = sql;
                    reader = await command.ExecuteReaderAsync();
                    while(await reader.ReadAsync())
                    {
                        var cols = reader.GetColumnSchema();
                        DataTable dt = new DataTable();
                        foreach(var item in cols)
                        {
                            if(!item.ColumnName.Equals("id") && !item.ColumnName.Equals("gang_id") && item.DataType != null)
                                dt.Columns.Add(item.ColumnName, item.DataType);
                        }
                        var gang = GangList.Find(x=>x.DatabaseID==(int)reader["gang_id"]);
                        if(gang != null)
                        {
                            foreach(DataColumn item in dt.Columns)
                            {
                                var skill = gang.SkillList.Find(x=>x.Name.Equals(item.ColumnName));
                                if(skill != null) skill.Level = (int)reader[item.ColumnName];
                            }
                        }
                    }
                    reader.Close();
                }
            }
            catch (Exception ex)
            {
                    Logger.LogError("{OnMapStart} Failed load map in database | " + ex.Message);
                    Logger.LogDebug(ex.Message);
                    throw new Exception("[Guild] Failed load map in database! | " + ex.Message);
            }
        });
	}

	[GameEventHandler]
	public HookResult OnPlayerHurt(EventPlayerHurt @event, GameEventInfo info)
	{
		return HookResult.Continue;
	}
}