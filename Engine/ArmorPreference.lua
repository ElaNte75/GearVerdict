local _, addon = ...
local preference = {}
addon.ArmorPreference = preference

-- Heavier armor preference (agreed with the user 2026-11-20). Between two pieces for the same slot:
--   a heavier armor type (cloth < leather < mail < plate) wins when its stats are at most MARGIN weaker,
--   a lighter type only wins when its stats are more than MARGIN better,
--   same type and equal stats: more Armor wins.
-- Only pieces the player can already wear reach this point (Eligibility). Cloaks have no armor type
-- that matters, but on equal stats more Armor wins. Rings, necks and trinkets keep the plain comparison.
preference.MARGIN = 0.10
preference.TIE = 0.01
preference.names = { "Cloth", "Leather", "Mail", "Plate" }
local ARMOR = "RESISTANCE0_NAME"

function preference:Type(item)
    if not item or item.classID ~= 4 or item.equipLoc == "INVTYPE_CLOAK" then return nil end
    local kind = item.subclassID
    if kind and kind >= 1 and kind <= 4 then return kind end
    return nil
end

-- candidate/previous: items from ItemData (previous nil = empty slot); delta: stat score change;
-- oldScore: stat score of the equipped piece. Returns upgrade (bool) and, when armor decided it,
-- a reason { kind = "heavier", name = "Mail" } or { kind = "armor", amount = 34 }.
function preference:Judge(candidate, previous, delta, oldScore)
    if not previous then return true end
    local plain = delta > self.TIE
    if candidate.equipLoc == "INVTYPE_CLOAK" and previous.equipLoc == "INVTYPE_CLOAK" then
        -- Cloaks (user choice 2026-11-21): equal stats -> more Armor wins.
        if not plain and delta >= -self.TIE then
            local gain = (candidate.stats[ARMOR] or 0) - (previous.stats[ARMOR] or 0)
            if gain > 0 then return true, { kind = "armor", amount = gain } end
        end
        return plain
    end
    local new, old = self:Type(candidate), self:Type(previous)
    if not new or not old then return plain end
    local margin = math.max(oldScore or 0, 0) * self.MARGIN
    if new > old then
        if plain then return true end
        if delta >= -margin then return true, { kind = "heavier", name = self.names[new] } end
        return false
    elseif new < old then
        return delta > math.max(margin, self.TIE)
    end
    if not plain and delta >= -self.TIE then
        local gain = (candidate.stats[ARMOR] or 0) - (previous.stats[ARMOR] or 0)
        if gain > 0 then return true, { kind = "armor", amount = gain } end
    end
    return plain
end

-- The short tooltip line for a reason, or nil.
function preference:ReasonText(reason)
    if not reason then return nil end
    if reason.kind == "heavier" then return "Heavier armor: " .. reason.name end
    if reason.kind == "armor" then return "More armor: +" .. reason.amount end
    return nil
end
