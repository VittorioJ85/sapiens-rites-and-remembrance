-- Shared preview/server arithmetic. Integer comparisons preserve exact thresholds.
local rewards={minimumPopulation=25}
function rewards.calculate(attending,population)
    if population<rewards.minimumPopulation or attending*4<population then
        return {happiness=0,loyalty=0,workPercent=0,days=0,attending=attending,population=population}
    end
    local majority=attending*2>population
    return {happiness=majority and 2 or 1,loyalty=majority and 2 or 1,
        workPercent=math.floor(20*math.min(attending,population)/population+.5),
        days=attending*2<population and 1 or 3,attending=attending,population=population}
end
function rewards.describe(reward)
    if reward.population<rewards.minimumPopulation then return "At least 25 tribe members are required." end
    if reward.days==0 then return "Below 25% attendance: no bonus." end
    return string.format("+%d Happiness / +%d Loyalty / +%d%% work speed for %d game day%s",
        reward.happiness,reward.loyalty,reward.workPercent,reward.days,reward.days==1 and "" or "s")
end
return rewards
