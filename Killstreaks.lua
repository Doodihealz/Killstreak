if Killstreak_Initialized then return end
Killstreak_Initialized = true

local STREAK_TIMEOUT   = 5
local BONUS_PERCENT    = 0.21
local MAX_LEVEL        = 80
local MAX_KILLSTREAK   = 50

local streakData = {}

local function ResetKillstreak(player, died)
    if player:GetLevel() >= MAX_LEVEL then return end
    local guid = player:GetGUIDLow()
    local data = streakData[guid]
    if not data then return end

    if died then
        if type(player.SendBroadcastMessage) == "function" then
            player:SendBroadcastMessage("You've been killed. Streak has ended.")
        end
    elseif data.kills > 1 and data.totalXP > 0 then
        local bonus = math.floor(data.totalXP * BONUS_PERCENT * data.kills * 0.5)
        player:GiveXP(bonus, player:GetLevel())
        if type(player.SendBroadcastMessage) == "function" then
            player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonus .. "|r")
        end
    end
    streakData[guid] = nil
end

local function OnGiveXP(event, player, amount, victim)
    if amount <= 0 or player:GetLevel() >= MAX_LEVEL then return end
    if not victim or not victim:IsAlive() then return end

    local guid = player:GetGUIDLow()
    local now  = os.clock()
    local data = streakData[guid]

    if not data then
        streakData[guid] = { kills = 1, lastGainTime = now, totalXP = amount }
    else
        if data.kills >= MAX_KILLSTREAK then
            if type(player.SendBroadcastMessage) == "function" then
                player:SendBroadcastMessage("Killstreak cap reached! Additional XP not adding.")
            end
            return
        end
        data.kills        = data.kills + 1
        data.lastGainTime = now
        data.totalXP      = data.totalXP + amount
    end

    if streakData[guid].kills > 1 and type(player.SendBroadcastMessage) == "function" then
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

local function OnKilled(event, killer, killed)
    if killed and killed:IsPlayer() and killed:GetLevel() < MAX_LEVEL then
        ResetKillstreak(killed, true)
    end
end

local function OnPlayerDeath(event, player, ...)
    if player:GetLevel() < MAX_LEVEL then
        ResetKillstreak(player, true)
    end
end

local function OnPlayerLogout(event, player)
    streakData[player:GetGUIDLow()] = nil
end

CreateLuaEvent(PollKillstreakTimeout, 1000, 0)
RegisterPlayerEvent(12, OnGiveXP)
RegisterPlayerEvent(6,  OnKilled)
RegisterPlayerEvent(8,  OnKilled)
RegisterPlayerEvent(40, OnPlayerDeath)
RegisterPlayerEvent(35, OnPlayerDeath)
RegisterPlayerEvent(4,  OnPlayerLogout)
