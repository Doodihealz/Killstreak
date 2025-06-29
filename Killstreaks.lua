if Killstreak_Initialized then return end
Killstreak_Initialized = true

local ENABLE_KILLSTREAKS = true
local STREAK_TIMEOUT = 5
local BONUS_PERCENT = 0.14

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
            local bonus = math.floor(data.totalXP * BONUS_PERCENT)
            player:GiveXP(bonus, player:GetLevel())
            player:SendBroadcastMessage("Killstreak ended! Bonus XP gained: |cff00ff00" .. bonus .. "|r")
        end
    end

    streakData[guid] = nil
end

local function PollXPTracker(eventId, delay, repeats)
    for _, player in pairs(GetPlayersInWorld()) do
        if player and player:IsInWorld() then
            local guid = player:GetGUIDLow()
            local currentXP = player:GetXP()
            local now = os.clock()
            local data = streakData[guid]

            if not data then
                streakData[guid] = {
                    kills = 0,
                    lastXP = currentXP,
                    lastGainTime = now,
                    totalXP = 0,
                    locked = false
                }
            else
                local gainedXP = currentXP - data.lastXP

                if gainedXP > 0 and not data.locked then
                    data.kills = data.kills + 1
                    data.totalXP = data.totalXP + gainedXP
                    data.lastGainTime = now
                    data.locked = true

                    if data.kills > 1 then
                        player:SendBroadcastMessage("Killstreak: |cff00ff00" .. data.kills .. "|r")
                    end
                elseif gainedXP == 0 then
                    data.locked = false
                end

                data.lastXP = currentXP

                if now - data.lastGainTime >= STREAK_TIMEOUT then
                    ResetKillstreak(player, false)
                end
            end
        end
    end
end

local function OnPlayerDie(_, player)
    if ENABLE_KILLSTREAKS and player then
        ResetKillstreak(player, true)
    end
end

local function OnPlayerLogout(_, player)
    if ENABLE_KILLSTREAKS and player then
        streakData[player:GetGUIDLow()] = nil
    end
end

CreateLuaEvent(PollXPTracker, 250, 0)

RegisterPlayerEvent(8, OnPlayerDie)
RegisterPlayerEvent(4, OnPlayerLogout)
