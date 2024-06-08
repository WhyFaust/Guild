namespace Guild{
    public record class Gang
    (
        string name,
        int ServerId,
        int CreateDate,
        int endDate,
        List<UserInfo> MembersList,
        List<Skill> SkillList,
        int exp = 0,
        int DatabaseID = -1
    )
    {
        public string Name {get; set; } = name;
        public int Exp {get; set; } = exp;
        public int EndDate {get; set; } = endDate;
    };
    
    public record class Skill
    (
        string Name,
        int level,
        int MaxLevel,
        int Price
    )
    {
        public int Level {get; set; } = level;
    };
}