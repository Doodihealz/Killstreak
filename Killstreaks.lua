if Killstreak_Initialized then return end
Killstreak_Initialized = true

-- ######################################################
-- Killstreak Bonus XP Script for AzerothCore (Eluna)
-- ######################################################

-- === CONFIGURATION ===
local ENABLE_KILLSTREAKS = true -- Toggle system ON/OFF
local STREAK_TIMEOUT = 5        -- Seconds before streak expires

local RANK_MULTIPLIER = {
    [0] = 1.0,   -- Normal
    [1] = 1.25,  -- Elite
    [2] = 1.5,   -- Rare Elite
    [3] = 2.0,   -- World Boss
    [4] = 1.25   -- Rare
}

-- XP bonus scale based on kill count
-- Formula: base + (kills ^ exponent) * multiplier, capped to max
-- BASE_SCALE is the minimum bonus (e.g., 0.1 = 10%)
-- SCALE_MULTIPLIER controls how quickly the bonus grows
-- SCALE_EXPONENT defines the curve sharpness (lower = faster early growth)
-- MAX_SCALE is the absolute cap on bonus XP (e.g., 1.0 = 100%)
local BASE_SCALE = 0.1
local SCALE_MULTIPLIER = 0.03
local SCALE_EXPONENT = 0.7
local MAX_SCALE = 1.0

local TIMER_EVENT_ID = 50001

-- ######################################################

local streakData = {}

local function ResetKillstreak(player, died)
    if not ENABLE_KILLSTREAKS or not player or not player:IsInWorld() then return end

    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end

    if data.kills > 1 and data.totalXP > 0 then
        if died then
            player:SendBroadcastMessage("You died. Killstreak lost. No bonus XP awarded.")
        else
            local scale = math.min(MAX_SCALE, BASE_SCALE + (data.kills ^ SCALE_EXPONENT) * SCALE_MULTIPLIER)
            local bonusXP = math.floor(data.totalXP * scale)
            player:GiveXP(bonusXP, player:GetLevel())
            player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonusXP .. "|r")
        end
    end

    player:RemoveEventsById(TIMER_EVENT_ID)
    streakData[guid] = nil
end

local function UpdateKillstreakTimer(_, _, _, player)
    if not ENABLE_KILLSTREAKS or not player or not player:IsInWorld() then return end

    local data = streakData[player:GetGUIDLow()]
    if data and os.clock() - data.lastKill >= STREAK_TIMEOUT then
        ResetKillstreak(player, false)
    end
end

local function OnCreatureKill(_, killer, killed)
    if not ENABLE_KILLSTREAKS or not killer or not killer:IsPlayer() then return end
    local player = killer:ToPlayer()
    if not player or not player:IsInWorld() or not killed then return end

    local guid = player:GetGUIDLow()
    local currentXP = player:GetXP()

    local data = streakData[guid]
    if not data then
        data = {
            kills = 0,
            lastKill = os.clock(),
            totalXP = 0,
            lastXP = currentXP,
            timerActive = false
        }
        streakData[guid] = data
    end

    if not data.timerActive then
        player:RegisterEvent(UpdateKillstreakTimer, 1000, 0, player, TIMER_EVENT_ID)
        data.timerActive = true
    end

    local gainedXP = math.max(0, currentXP - data.lastXP)
    if gainedXP == 0 then return end

    local rank = killed:GetRank()
    local scale = RANK_MULTIPLIER[rank] or 1.0

    data.kills = data.kills + 1
    data.lastKill = os.clock()
    data.totalXP = data.totalXP + (gainedXP * scale)
    data.lastXP = currentXP

    if data.kills > 1 then
        player:SendBroadcastMessage("Killstreak: " .. data.kills)
    end
end

local function ClearPlayerData(_, player)
    if not ENABLE_KILLSTREAKS or not player then return end
    ResetKillstreak(player, true)
end

local function OnLogout(_, player)
    if not ENABLE_KILLSTREAKS or not player then return end
    player:RemoveEventsById(TIMER_EVENT_ID)
    streakData[player:GetGUIDLow()] = nil
end

RegisterPlayerEvent(7, OnCreatureKill)
RegisterPlayerEvent(8, ClearPlayerData)
RegisterPlayerEvent(4, OnLogout)
