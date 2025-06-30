if Killstreak_Initialized then return end
Killstreak_Initialized = true

local STREAK_TIMEOUT = 5
local BONUS_PERCENT = 0.21
local MAX_LEVEL = 80

local streakData = {}

local function ResetKillstreak(player, died)
    if player:GetLevel() >= MAX_LEVEL then return end

    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end

    if data.kills > 1 and data.totalXP > 0 then
        if died then
            player:SendBroadcastMessage("You died. Killstreak lost. No bonus XP awarded.")
        else
            local avgXP = data.totalXP / data.kills
            local bonus = math.floor(avgXP * data.kills * BONUS_PERCENT)
            player:GiveXP(bonus, player:GetLevel())
            player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonus .. "|r")
        end
    end

    streakData[guid] = nil
end

local function OnGiveXP(event, player, amount, victim)
    if amount <= 0 or player:GetLevel() >= MAX_LEVEL then return end

    local guid = player:GetGUIDLow()
    local now = os.clock()
    local data = streakData[guid]

    if not data then
        streakData[guid] = {
            kills = 1,
            lastGainTime = now,
            totalXP = amount,
        }
    else
        data.kills = data.kills + 1
        data.lastGainTime = now
        data.totalXP = data.totalXP + amount
    end

    if streakData[guid].kills > 1 then
        player:SendBroadcastMessage("Killstreak: |cff00ff00" .. streakData[guid].kills .. "|r")
    end
end

local function PollKillstreakTimeout(eventId, delay, repeats)
    local now = os.clock()
    for _, player in pairs(GetPlayersInWorld()) do
        if player:GetLevel() < MAX_LEVEL then
            local data = streakData[player:GetGUIDLow()]
            if data and now - data.lastGainTime >= STREAK_TIMEOUT then
                ResetKillstreak(player, false)
            end
        end
    end
end

local function OnPlayerDie(_, player)
    if player:GetLevel() < MAX_LEVEL then
        ResetKillstreak(player, true)
    end
end

local function OnPlayerLogout(_, player)
    streakData[player:GetGUIDLow()] = nil
end

CreateLuaEvent(PollKillstreakTimeout, 1000, 0)
RegisterPlayerEvent(12, OnGiveXP)
RegisterPlayerEvent(8, OnPlayerDie)
RegisterPlayerEvent(4, OnPlayerLogout)
