if Killstreak_Initialized then return end
Killstreak_Initialized = true

-- Killstreak System with comprehensive detection for PvE and PvP kills

local STREAK_TIMEOUT        = 5
local BONUS_PERCENT         = 0.21
local TIER_BONUS_PERCENT    = 0.015
local MAX_LEVEL             = 80
local MAX_KILLSTREAK        = 50
local MAX_KILL_MULTIPLIER   = 15

local HONOR_STREAK_TIMEOUT  = 10
local HONOR_BASE_MULTIPLIER = 3 -- boosts base honor earned per kill for streak tracking
local HONOR_BONUS_PERCENT   = 0.45
local HONOR_TIER_BONUS      = 0.04
local MAX_HONOR_STREAK      = 50

local PARTY_MAX_MEMBERS     = 5
local PARTY_BONUS_PER_MEMBER= 0.125

local streakData = {}
local honorData  = {}
local playerAliveStatus = {}
local partyCache = {}
local partyCacheTime = {}

local WHITE = "|r"
local BRIGHT_GREEN = "|cff00ff00"
local YELLOW_GREEN = "|cffaaff00"
local YELLOW = "|cffffff00"
local ORANGE = "|cffff8800"
local RED_ORANGE = "|cffff4400"
local RED = "|cffff0000"
local DARK_RED = "|cffcc0000"
local BLOOD_RED = "|cff990000"
local CRIMSON = "|cff660000"
local DEEP_RED = "|cff440000"

local STREAK_TIERS = {
    [5] = {name = "(On Fire!)", color = BRIGHT_GREEN},
    [10] = {name = "(Rampage!)", color = YELLOW},
    [15] = {name = "(Dominating!)", color = ORANGE},
    [20] = {name = "(Unstoppable!)", color = RED_ORANGE},
    [25] = {name = "(Merciless!)", color = RED},
    [30] = {name = "(Killtacular!)", color = DARK_RED},
    [35] = {name = "(Apocalyptic!)", color = BLOOD_RED},
    [40] = {name = "(Godlike!)", color = CRIMSON},
    [45] = {name = "(Legendary!)", color = DEEP_RED},
    [50] = {name = "(Unfrigginbelievable!)", color = DEEP_RED}
}

local PVP_RANKS = {
    [5] = {alliance = "Private", horde = "Scout", color = BRIGHT_GREEN},
    [10] = {alliance = "Corporal", horde = "Grunt", color = YELLOW_GREEN},
    [15] = {alliance = "Sergeant", horde = "Sergeant", color = YELLOW},
    [20] = {alliance = "Master Sergeant", horde = "Senior Sergeant", color = ORANGE},
    [25] = {alliance = "Sergeant Major", horde = "First Sergeant", color = RED_ORANGE},
    [30] = {alliance = "Knight", horde = "Stone Guard", color = RED},
    [35] = {alliance = "Knight-Lieutenant", horde = "Blood Guard", color = DARK_RED},
    [40] = {alliance = "Knight-Captain", horde = "Legionnaire", color = BLOOD_RED},
    [45] = {alliance = "Knight-Champion", horde = "Centurion", color = CRIMSON},
    [50] = {alliance = "Lieutenant Commander", horde = "Champion", color = DEEP_RED}
}

local function IsValidPlayer(player)
    return player and player:IsPlayer() and player:IsInWorld()
end

local function GetKillstreakTier(kills)
    return math.floor((kills - 1) / 5)
end

local function GetHonorTier(kills)
    return math.floor((kills - 1) / 5)
end

local function GetStreakTierInfo(kills)
    local highestTier = nil
    for threshold, info in pairs(STREAK_TIERS) do
        if kills >= threshold then
            if not highestTier or threshold > highestTier then
                highestTier = threshold
            end
        end
    end
    return highestTier and STREAK_TIERS[highestTier] or nil
end

local function GetPvPRankInfo(kills, isAlliance)
    local highestRank = nil
    for threshold, info in pairs(PVP_RANKS) do
        if kills >= threshold then
            if not highestRank or threshold > highestRank then
                highestRank = threshold
            end
        end
    end
    if not highestRank then return nil end
    
    local rankInfo = PVP_RANKS[highestRank]
    local rankName = isAlliance and rankInfo.alliance or rankInfo.horde
    return {name = rankName, color = rankInfo.color}
end

local function GetPartyCount(player)
    if not IsValidPlayer(player) then return 1 end
    
    local guid = player:GetGUIDLow()
    if not guid then return 1 end
    
    local now = os.clock()
    if partyCache[guid] and partyCacheTime[guid] and (now - partyCacheTime[guid]) < 5 then
        return partyCache[guid]
    end
    
    local group = player.GetGroup and player:GetGroup() or nil
    if not group then 
        partyCache[guid] = 1
        partyCacheTime[guid] = now
        return 1 
    end
    
    local count = 1
    if group.GetMembersCount then
        local memberCount = group:GetMembersCount()
        if type(memberCount) == "number" and memberCount > 0 then 
            count = math.min(memberCount, PARTY_MAX_MEMBERS)
        end
    elseif group.GetMembers then
        local members = group:GetMembers()
        if type(members) == "table" then
            local memberCount = #members
            count = memberCount > 0 and math.min(memberCount, PARTY_MAX_MEMBERS) or 1
        end
    end
    
    partyCache[guid] = count
    partyCacheTime[guid] = now
    
    return count
end

local function GetPartyMultiplier(player)
    local partyCount = GetPartyCount(player)
    return 1 + (partyCount - 1) * PARTY_BONUS_PER_MEMBER
end

local function BuildPlayerLookup()
    local lookup = {}
    local players = GetPlayersInWorld()
    if type(players) ~= "table" then
        return lookup
    end
    for i = 1, #players do
        local player = players[i]
        if IsValidPlayer(player) then
            lookup[player:GetGUIDLow()] = player
        end
    end
    return lookup
end

local function CalculateKillstreakBonus(data, level, player)
    local tier = GetKillstreakTier(data.kills)
    local tierBonus = tier * TIER_BONUS_PERCENT
    local totalBonusPercent = BONUS_PERCENT + tierBonus
    local killMultiplier = math.min(data.kills, MAX_KILL_MULTIPLIER)
    local levelMultiplier = 1 + level / 200
    local partyMultiplier = player and GetPartyMultiplier(player) or 1
    
    return math.floor(data.totalXP * totalBonusPercent * killMultiplier * levelMultiplier * partyMultiplier)
end

local function CalculateHonorBonus(data, level)
    local tier = GetHonorTier(data.kills)
    local tierBonus = tier * HONOR_TIER_BONUS
    local totalBonusPercent = HONOR_BONUS_PERCENT + tierBonus + (level / 1000)
    
    return math.floor(data.totalHonor * totalBonusPercent)
end

local function ResetKillstreak(player, wasDeath)
    if not IsValidPlayer(player) or player:GetLevel() >= MAX_LEVEL then return end
    
    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end
    
    if wasDeath then
        if data.kills > 1 then
            player:SendBroadcastMessage(RED .. "You've been killed! Killstreak of " .. data.kills .. " ended." .. WHITE)
        end
    elseif data.kills > 1 and data.totalXP > 0 then
        local level = player:GetLevel()
        local bonus = CalculateKillstreakBonus(data, level, player)
        
        -- Calculate percentage of current level
        local currentXP = player:GetUInt32Value(1191) -- PLAYER_XP
        local maxXP = player:GetUInt32Value(1192) -- PLAYER_NEXT_LEVEL_XP
        local percentage = 0
        if maxXP > 0 then
            percentage = (bonus / maxXP) * 100
        end
        
        player:GiveXP(bonus)
        local message = "Killstreak finished, you gained " .. BRIGHT_GREEN .. bonus .. WHITE .. " experience"
        player:SendBroadcastMessage(message)
    end
    
    streakData[guid] = nil
end

local function ResetHonorStreak(player, wasDeath)
    if not IsValidPlayer(player) then return end
    
    local guid = player:GetGUIDLow()
    local data = honorData[guid]
    if not data then return end
    
    if wasDeath then
        if data.kills > 1 then
            player:SendBroadcastMessage(RED .. "Honor killstreak of " .. data.kills .. " ended!" .. WHITE)
        end
    elseif data.kills > 1 and data.totalHonor > 0 then
        local level = player:GetLevel()
        local bonus = CalculateHonorBonus(data, level)
        if player:HasAura(68652) then
            bonus = math.floor(bonus * 1.5)
        end
        local newHonor = player:GetHonorPoints() + bonus
        player:SetHonorPoints(newHonor)
        player:SaveToDB()
        player:SendBroadcastMessage("Honor streak bonus awarded: " .. BRIGHT_GREEN .. bonus .. WHITE)
    end
    
    honorData[guid] = nil
end

local function HandlePlayerDeath(player)
    if not IsValidPlayer(player) then return end
    
    local guid = player:GetGUIDLow()
    playerAliveStatus[guid] = false
    
    if player:GetLevel() < MAX_LEVEL then
        ResetKillstreak(player, true)
    end
    ResetHonorStreak(player, true)
end



local function OnGiveXP(event, player, amount, victim)
    if not IsValidPlayer(player) or amount <= 0 or player:GetLevel() >= MAX_LEVEL then return end
    
    if not victim then return end
    if victim:IsPlayer() then return end
    
    local guid = player:GetGUIDLow()
    local currentTime = os.clock()
    local data = streakData[guid]
    
    if not data then
        streakData[guid] = {
            kills = 1,
            lastGainTime = currentTime,
            totalXP = amount
        }
    else
        if data.kills >= MAX_KILLSTREAK then
            player:SendBroadcastMessage("Killstreak cap reached (" .. MAX_KILLSTREAK .. ")! Additional XP not counting toward streak.")
            return
        end
        
        data.kills = data.kills + 1
        data.lastGainTime = currentTime
        data.totalXP = data.totalXP + amount
    end
    
    local currentStreak = streakData[guid].kills
    if currentStreak > 1 then
        local message = "Killstreak: " .. BRIGHT_GREEN .. currentStreak .. WHITE
        local tierInfo = GetStreakTierInfo(currentStreak)
        
        if tierInfo then
            message = message .. " " .. tierInfo.color .. tierInfo.name .. WHITE
        end
        
        player:SendBroadcastMessage(message)
    end
end

local function OnKillPlayer(event, killer, killed)
    if not IsValidPlayer(killer) or not IsValidPlayer(killed) then return end
    
    HandlePlayerDeath(killed)
    
    local guid = killer:GetGUIDLow()
    local currentTime = os.clock()
    local baseHonor = math.max(1, math.floor((killed:GetLevel() * 0.8 + 5) * HONOR_BASE_MULTIPLIER))
    
    local data = honorData[guid]
    if not data then
        honorData[guid] = {
            kills = 1,
            lastGainTime = currentTime,
            totalHonor = baseHonor
        }
    else
        if data.kills >= MAX_HONOR_STREAK then
            killer:SendBroadcastMessage("Honor killstreak cap reached (" .. MAX_HONOR_STREAK .. ")!")
            return
        end
        
        data.kills = data.kills + 1
        data.lastGainTime = currentTime
        data.totalHonor = data.totalHonor + baseHonor
    end
    
    local currentStreak = honorData[guid].kills
    if currentStreak > 1 then
        local isAlliance = killer:GetTeam() == 0
        local rankInfo = GetPvPRankInfo(currentStreak, isAlliance)
        
        local message = "Honor Killstreak: " .. BRIGHT_GREEN .. currentStreak .. WHITE .. " player kills"
        
        if rankInfo then
            message = message .. " " .. rankInfo.color .. "(" .. rankInfo.name .. "!)" .. WHITE
        end
        
        killer:SendBroadcastMessage(message)
    end
end

local function OnPlayerLogin(event, player)
    if not IsValidPlayer(player) then return end
    local guid = player:GetGUIDLow()
    playerAliveStatus[guid] = not player:IsDead()
end

local function OnPlayerLogout(event, player)
    if not player then return end
    
    local guid = player:GetGUIDLow()
    
    if player:GetLevel() < MAX_LEVEL then
        ResetKillstreak(player, false)
    else
        streakData[guid] = nil
    end
    ResetHonorStreak(player, false)
    playerAliveStatus[guid] = nil
    
    -- Clean up party cache for this player
    if guid then
        partyCache[guid] = nil
        partyCacheTime[guid] = nil
    end
end

local function OnResurrect(event, player)
    if not IsValidPlayer(player) then return end
    local guid = player:GetGUIDLow()
    playerAliveStatus[guid] = true
end

local function CheckPlayerDeaths()
    for _, player in ipairs(GetPlayersInWorld()) do
        if IsValidPlayer(player) then
            local guid = player:GetGUIDLow()
            local isDead = player:IsDead()
            local wasAlive = playerAliveStatus[guid]
            
            if wasAlive ~= false and isDead then
                HandlePlayerDeath(player)
            end
            
            playerAliveStatus[guid] = not isDead
        end
    end
end

local function PollKillstreakTimeout()
    local currentTime = os.clock()
    local toRemove = {}
    local playersByGuid = BuildPlayerLookup()
    
    for guid, data in pairs(streakData) do
        if currentTime - data.lastGainTime >= STREAK_TIMEOUT then
            local player = playersByGuid[guid]
            if player then
                ResetKillstreak(player, false)
            end
            table.insert(toRemove, guid)
        end
    end
    
    for _, guid in ipairs(toRemove) do
        streakData[guid] = nil
    end
    
    -- Clean up old party cache entries
    local partyCacheRemove = {}
    for guid, cacheTime in pairs(partyCacheTime) do
        if currentTime - cacheTime > 60 then
            partyCacheRemove[#partyCacheRemove + 1] = guid
        end
    end
    
    for i = 1, #partyCacheRemove do
        local guid = partyCacheRemove[i]
        partyCache[guid] = nil
        partyCacheTime[guid] = nil
    end
end

local function PollHonorStreakTimeout()
    local currentTime = os.clock()
    local toRemove = {}
    local playersByGuid = BuildPlayerLookup()
    
    for guid, data in pairs(honorData) do
        if currentTime - data.lastGainTime >= HONOR_STREAK_TIMEOUT then
            local player = playersByGuid[guid]
            if player then
                ResetHonorStreak(player, false)
            end
            table.insert(toRemove, guid)
        end
    end
    
    for _, guid in ipairs(toRemove) do
        honorData[guid] = nil
    end
end

CreateLuaEvent(PollKillstreakTimeout, 2000, 0)
CreateLuaEvent(PollHonorStreakTimeout, 2000, 0)
CreateLuaEvent(CheckPlayerDeaths, 1000, 0)

RegisterPlayerEvent(12, OnGiveXP)
RegisterPlayerEvent(6,  OnKillPlayer)
RegisterPlayerEvent(3,  OnPlayerLogin)
RegisterPlayerEvent(4,  OnPlayerLogout)
RegisterPlayerEvent(36, OnResurrect)
