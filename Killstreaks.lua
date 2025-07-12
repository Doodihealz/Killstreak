if Killstreak_Initialized then return end
Killstreak_Initialized = true

local STREAK_TIMEOUT        = 5
local BONUS_PERCENT         = 0.21
local MAX_LEVEL             = 80
local MAX_KILLSTREAK        = 50

local HONOR_STREAK_TIMEOUT  = 5
local HONOR_BONUS_PERCENT   = 0.21
local MAX_HONOR_STREAK      = 50

local streakData = {}
local honorData  = {}

local green = "|cff00ff00"
local white = "|r"

local function ResetKillstreak(p, died)
    if p:GetLevel() >= MAX_LEVEL then return end
    local d = streakData[p:GetGUIDLow()]
    if not d then return end
    if died then
        p:SendBroadcastMessage("You've been killed. Streak has ended.")
    elseif d.kills > 1 and d.totalXP > 0 then
        local lvl   = p:GetLevel()
        local bonus = math.floor(d.totalXP * BONUS_PERCENT * d.kills * 0.5 * (1 + lvl / 100))
        p:GiveXP(bonus, lvl)
        p:SendBroadcastMessage("Killstreak ended! Bonus XP gained: " .. green .. bonus .. white)
    end
    streakData[p:GetGUIDLow()] = nil
end

local function ResetHonorStreak(p, died)
    local d = honorData[p:GetGUIDLow()]
    if not d then return end
    if not died and d.kills > 1 and d.totalHonor > 0 then
        local lvl   = p:GetLevel()
        local bonus = math.floor(d.totalHonor * (HONOR_BONUS_PERCENT + (lvl / 1000)))
        local new   = p:GetHonorPoints() + bonus
        p:SetHonorPoints(new)
        p:SaveToDB()
        p:SendBroadcastMessage("Honor awarded: " .. green .. bonus .. white)
    end
    honorData[p:GetGUIDLow()] = nil
end

local function OnGiveXP(_, player, amount, victim)
    if amount <= 0 or player:GetLevel() >= MAX_LEVEL then return end
    if victim and victim:IsPlayer() then return end
    if not victim or not victim:IsAlive() then return end
    local g, now = player:GetGUIDLow(), os.clock()
    local d = streakData[g]
    if not d then
        streakData[g] = { kills = 1, lastGainTime = now, totalXP = amount }
    else
        if d.kills >= MAX_KILLSTREAK then
            player:SendBroadcastMessage("Killstreak cap reached! Additional XP not adding.")
            return
        end
        d.kills, d.lastGainTime, d.totalXP = d.kills + 1, now, d.totalXP + amount
    end
    if streakData[g].kills > 1 then
        player:SendBroadcastMessage("Killstreak: " .. green .. streakData[g].kills .. white)
    end
end

local function OnKillPlayer(_, killer, killed)
    if not killer or not killed or not killer:IsPlayer() then return end
    local g, now    = killer:GetGUIDLow(), os.clock()
    local baseHonor = math.floor(killed:GetLevel() * 0.5 + 4)
    local d = honorData[g]
    if not d then
        honorData[g] = { kills = 1, lastGainTime = now, totalHonor = baseHonor }
    else
        if d.kills >= MAX_HONOR_STREAK then return end
        d.kills, d.lastGainTime, d.totalHonor = d.kills + 1, now, d.totalHonor + baseHonor
    end
    if honorData[g].kills > 1 then
        killer:SendBroadcastMessage("Honor-Streak: " .. green .. honorData[g].kills .. white .. " kills")
    end
end

local function PollKillstreakTimeout()
    local n = os.clock()
    for _, p in ipairs(GetPlayersInWorld()) do
        if p:GetLevel() < MAX_LEVEL then
            local d = streakData[p:GetGUIDLow()]
            if d and n - d.lastGainTime >= STREAK_TIMEOUT then
                ResetKillstreak(p, false)
            end
        end
    end
end

local function PollHonorStreakTimeout()
    local n = os.clock()
    for _, p in ipairs(GetPlayersInWorld()) do
        local d = honorData[p:GetGUIDLow()]
        if d and n - d.lastGainTime >= HONOR_STREAK_TIMEOUT then
            ResetHonorStreak(p, false)
        end
    end
end

local function OnKilled(_, killer, killed)
    if killed and killed:IsPlayer() and killed:GetLevel() < MAX_LEVEL then
        ResetKillstreak(killed, true)
    end
    if killed and killed:IsPlayer() then
        ResetHonorStreak(killed, true)
    end
end

local function OnPlayerDeath(_, player)
    if player:GetLevel() < MAX_LEVEL then
        ResetKillstreak(player, true)
    end
    ResetHonorStreak(player, true)
end

local function OnPlayerLogout(_, player)
    streakData[player:GetGUIDLow()] = nil
    honorData[player:GetGUIDLow()]  = nil
end

CreateLuaEvent(PollKillstreakTimeout, 1000, 0)
CreateLuaEvent(PollHonorStreakTimeout, 1000, 0)
RegisterPlayerEvent(12, OnGiveXP)
RegisterPlayerEvent(6,  OnKillPlayer)
RegisterPlayerEvent(6,  OnKilled)
RegisterPlayerEvent(8,  OnKilled)
RegisterPlayerEvent(40, OnPlayerDeath)
RegisterPlayerEvent(35, OnPlayerDeath)
RegisterPlayerEvent(4,  OnPlayerLogout)
