if Killstreak_Initialized then return end
Killstreak_Initialized = true

-- === CONFIGURATION ===
local ENABLE_KILLSTREAKS = true
local STREAK_TIMEOUT = 5 -- seconds
local BONUS_PERCENT = 0.025 -- 2.5% bonus per kill

local streakData = {}

local function ResetKillstreak(player, died)
    if not ENABLE_KILLSTREAKS or not player or not player:IsInWorld() then return end

    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end

    if data.kills > 1 and data.totalBonus > 0 then
    if died then
        player:SendBroadcastMessage("You died. Killstreak lost. No bonus XP awarded.")
    else
        local bonus = math.floor(data.totalBonus)
        player:GiveXP(bonus, player:GetLevel())
        player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonus .. "|r")
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
    local data = streakData[guid]

    local lastXP = data and data.lastXP or 0
    local gainedXP = math.max(0, currentXP - lastXP)
    if gainedXP == 0 then return end

    local bonus = gainedXP * BONUS_PERCENT

    local now = os.clock()
    if not data then
        data = {
            kills = 1,
            lastKill = now,
            lastXP = currentXP,
            totalBonus = bonus
        }
        streakData[guid] = data
    else
        data.kills = data.kills + 1
        data.lastKill = now
        data.lastXP = currentXP
        data.totalBonus = data.totalBonus + bonus
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

RegisterPlayerEvent(7, OnCreatureKill)
RegisterPlayerEvent(8, OnPlayerDie)
RegisterPlayerEvent(4, OnPlayerLogout)
