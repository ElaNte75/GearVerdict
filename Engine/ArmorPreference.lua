local _, addon = ...
local preference = {}
addon.ArmorPreference = preference

-- Armor between two pieces for the same slot (2026-11-21, agreed with the user):
-- Armor counts in the score itself (Engine/Scoring.lua ArmorWeight, from the game's armor formula), so the
-- score decides. The old "heavier armor type wins within 10%" rule is gone. One tie rule stays: when the
-- stats are equal (within TIE), the piece with more Armor wins, with the reason "More armor: +N".
-- Rings, necks and trinkets have no Armor, so nothing changes for them.
preference.TIE = 0.01
local ARMOR = "RESISTANCE0_NAME"

-- candidate/previous: items from ItemData (previous nil = empty slot); delta: score change.
-- Returns upgrade (bool) and, when the Armor tie rule decided it, a reason { kind = "armor", amount = 34 }.
function preference:Judge(candidate, previous, delta)
    if not previous then return true end
    if delta > self.TIE then return true end
    if delta >= -self.TIE then
        local gain = (candidate.stats[ARMOR] or 0) - (previous.stats[ARMOR] or 0)
        if gain > 0 then return true, { kind = "armor", amount = gain } end
    end
    return false
end

-- The short tooltip line for a reason, or nil.
function preference:ReasonText(reason)
    if not reason then return nil end
    if reason.kind == "armor" then return "More armor: +" .. reason.amount end
    return nil
end
