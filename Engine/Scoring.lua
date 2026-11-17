local _, addon = ...
local scoring = {}
addon.Scoring = scoring

function scoring:Value(stats, preset)
    local score = 0
    for key in pairs(preset.weights) do
        local amount = stats[key] or 0
        local weight = addon.Presets:Weight(key) or 0
        local cap = GearVerdictDB.capsEnabled and UnitLevel("player") == 60 and preset.caps[key]
        if cap then
            score = score + math.min(amount, cap.threshold) * weight
                + math.max(0, amount - cap.threshold) * cap.after
        else
            score = score + amount * weight
        end
    end
    return score
end

function scoring:Delta(total, previous, candidate, preset)
    local changed = {}
    for key, value in pairs(total) do changed[key] = value end
    for key, value in pairs(previous.stats) do changed[key] = (changed[key] or 0) - value end
    for key, value in pairs(candidate.stats) do changed[key] = (changed[key] or 0) + value end
    return self:Value(changed, preset) - self:Value(total, preset)
end
