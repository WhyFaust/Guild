using CounterStrikeSharp.API.Core;
using GuildAPI;

namespace Guild.Api;
public class ApiGuild: IGuildApi
{
    public event Action? CoreReady;
    public event Action<CCSPlayerController, int>? GuildCreated;
    public event Action<CCSPlayerController, int>? ClientJoinGang;
    private readonly Guild _guild;
    public string dbConnectionString { get; }
    public ApiGuild(Guild guild)
    {
        _guild = guild;
        dbConnectionString = guild.dbConnectionString;
    }
    public async Task RegisterSkill(string skillName, int maxLevel, int price)
    {
        await _guild.AddSkillInDB(skillName, maxLevel, price);
    }
    public async Task RegisterSkill(int gangID, string skillName, int maxLevel, int price)
    {
        await _guild.AddSkillInDB(gangID, skillName, maxLevel, price);
    }
    public bool UnRegisterSkill(string skillName)
    {
        foreach(var gang in _guild.GangList)
        {
            var skill = gang.SkillList.Find(x=>x.Name.Equals(skillName));
            if(skill != null) gang.SkillList.Remove(skill);
        }
        return true;
    }
    public int GetSkillLevel(CCSPlayerController player, string skillName)
    {
        var gang = _guild.GangList.Find(x=>x.DatabaseID == _guild.userInfo[player.Slot].GangId);
        if(gang == null) return -1;
        var skill = gang.SkillList.Find(x=>x.Name.Equals(skillName));
        if(skill != null) return skill.Level;
        else return -1;
    }
    public void OnCoreReady()
    {
        CoreReady?.Invoke();
    }
    public void OnGuildCreated(CCSPlayerController player, int GangId)
    {
        GuildCreated?.Invoke(player, GangId);
    }
    public void OnClientJoinGang(CCSPlayerController player, int GangId)
    {
        ClientJoinGang?.Invoke(player, GangId);
    }
    public void OnClientBuySkill(CCSPlayerController player, int GangId)
    {
        ClientJoinGang?.Invoke(player, GangId);
    }
}