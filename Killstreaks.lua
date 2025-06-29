if Killstreak_Initialized then return end
Killstreak_Initialized = true

-- === CONFIGURATION ===
local ENABLE_KILLSTREAKS = true
local STREAK_TIMEOUT = 5

local RANK_MULTIPLIER = {
    [0] = 1.0,
    [1] = 1.25,
    [2] = 1.5,
    [3] = 2.0,
    [4] = 1.25
}

local BASE_SCALE = 0.1            -- Minimum XP bonus
local PER_KILL_SCALE = 0.025      -- XP increase per additional kill
local BONUS_FLAT_SCALE = 0.05     -- Flat extra bonus
local MAX_SCALE = 1.0             -- Max bonus XP multiplier

local streakData = {}

local function ResetKillstreak(player, died)
    if not ENABLE_KILLSTREAKS or not player or not player:IsInWorld() then return end

    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end

    if data.kills > 1 and data.rawXP > 0 then
        if died then
            player:SendBroadcastMessage("You died. Killstreak lost. No bonus XP awarded.")
        else
            -- Base 5%, +6% per extra kill after first, capped to 30%
            local scale = math.min(0.30, 0.05 + ((data.kills - 1) * 0.06))
            local bonusXP = math.floor(data.rawXP * scale)
            player:GiveXP(bonusXP, player:GetLevel())
            player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonusXP .. "|r")
        end
    end

    streakData[guid] = nil
end

local function OnCreatureKill(_, killer, killed)
    if not ENABLE_KILLSTREAKS or not killer or not killer:IsPlayer() then return end
    local player = killer:ToPlayer()
    if not player or not player:IsInWorld() or not killed then return end

    local guid = player:GetGUIDLow()
    local currentXP = player:GetXP()
    local lastXP = streakData[guid] and streakData[guid].lastXP or 0
    local gainedXP = math.max(0, currentXP - lastXP)

    if gainedXP == 0 then return end

    local now = os.clock()

    local data = streakData[guid]
    if not data then
        data = {
            kills = 1,
            lastKill = now,
            rawXP = gainedXP,
            lastXP = currentXP
        }
        streakData[guid] = data
    else
        data.kills = data.kills + 1
        data.lastKill = now
        data.rawXP = data.rawXP + gainedXP
        data.lastXP = currentXP
    end

    if data.kills > 1 then
        player:SendBroadcastMessage("Killstreak: |cff00ff00" .. data.kills .. "|r")
    end
end

local function OnPlayerDie(_, player)
    if not ENABLE_KILLSTREAKS or not player then return end
    ResetKillstreak(player, true)
end

local function OnPlayerLogout(_, player)
    if not ENABLE_KILLSTREAKS or not player then return end
    streakData[player:GetGUIDLow()] = nil
end

local function GlobalKillstreakTimerCheck(eventId, delay, repeats)
    local now = os.clock()
    for guid, data in pairs(streakData) do
        if data and now - data.lastKill >= STREAK_TIMEOUT then
            local player = GetPlayerByGUID(guid)
            if player and player:IsInWorld() then
                ResetKillstreak(player, false)
            end
        end
    end
end

CreateLuaEvent(GlobalKillstreakTimerCheck, 1000, 0)

RegisterPlayerEvent(7, OnCreatureKill) -- OnKill
RegisterPlayerEvent(8, OnPlayerDie)    -- OnDie
RegisterPlayerEvent(4, OnPlayerLogout) -- OnLogout
