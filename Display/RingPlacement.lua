local _, addon = ...
local placement = { maxAge = 30, delay = 0.4 }
addon.RingPlacement = placement

local function itemID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

function placement:Remember(link, slot)
    if slot ~= 11 and slot ~= 12 then self.pending = nil; return end
    local keep = GetInventoryItemLink("player", slot == 11 and 12 or 11)
    self.pending = keep and { id = itemID(link), link = link, slot = slot, keep = keep, time = GetTime() } or nil
end

function placement:EquipmentChanged(slot)
    local pending = self.pending
    if not pending or (slot ~= 11 and slot ~= 12) then return end
    if GetTime() - pending.time > self.maxAge then self.pending = nil; return end
    if itemID(GetInventoryItemLink("player", slot)) ~= pending.id then return end
    self.pending = nil
    if slot == pending.slot or InCombatLockdown() then return end
    addon.Diagnostics:Log("ring-placement", "wrong slot=" .. slot .. " target=" .. pending.slot)
    C_Timer.After(self.delay, function()
        if InCombatLockdown() then return end
        EquipItemByName(pending.keep, slot)
        C_Timer.After(self.delay, function()
            if not InCombatLockdown() then EquipItemByName(pending.link, pending.slot) end
        end)
    end)
end

if CreateFrame then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:SetScript("OnEvent", function(_, _, slot) placement:EquipmentChanged(slot) end)
end
