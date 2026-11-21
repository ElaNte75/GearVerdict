local _, addon = ...
local sell = { frames = setmetatable({}, { __mode = "k" }) }
addon.QuestSellCoin = sell

-- Quest reward choice where nothing is an upgrade (agreed with the user 2026-11-21): the reward that
-- sells for the most gets a gold coin on its icon corner (same corner as the arrow) and a tooltip line.
-- Only used when there are at least two choices and none of them is an upgrade.
sell.TEXTURE = "Interface\\MoneyFrame\\UI-GoldIcon"

-- entries: { button, price (copper, total for the stack) or nil while item data is missing,
--            upgrade (bool), loading (bool) } for every "choice" reward button.
-- Returns the winning price (or nil) so tests can look at it; buttons get gearVerdictSell = price or nil.
function sell:Pick(entries)
    local best
    if #entries >= 2 then
        local blocked = false
        for _, entry in ipairs(entries) do
            if entry.upgrade or entry.loading or not entry.price then blocked = true end
        end
        if not blocked then
            for _, entry in ipairs(entries) do
                if entry.price > 0 and (not best or entry.price > best) then best = entry.price end
            end
        end
    end
    local winners = {}
    for _, entry in ipairs(entries) do
        winners[entry.button] = best ~= nil and entry.price == best
    end
    return best, winners
end

function sell:Build(button)
    local frame = CreateFrame("Frame", nil, button)
    frame:SetSize(16, 16)
    frame:SetFrameLevel(button:GetFrameLevel() + 10)
    frame:EnableMouse(false)
    frame.texture = frame:CreateTexture(nil, "OVERLAY")
    frame.texture:SetAllPoints(frame)
    frame.texture:SetTexture(self.TEXTURE)
    return frame
end

function sell:Show(button, visible)
    local frame = self.frames[button]
    if not visible then
        if frame then frame:Hide() end
        return
    end
    if not frame then
        frame = self:Build(button)
        self.frames[button] = frame
    end
    local position = addon.UpgradeIndicators:Options()
    local target = button.gearVerdictAnchor or button
    if frame.appliedKey ~= position .. tostring(target) then
        frame.appliedKey = position .. tostring(target)
        frame:ClearAllPoints()
        frame:SetPoint(position, target, position, position == "TOPLEFT" and -3 or 3, 3)
    end
    frame:Show()
end

function sell:Update(entries)
    local best, winners = self:Pick(entries)
    for _, entry in ipairs(entries) do
        local win = winners[entry.button] == true
        entry.button.gearVerdictSell = win and best or nil
        self:Show(entry.button, win)
    end
end

function sell:Format(price)
    if GetCoinTextureString then return GetCoinTextureString(price) end
    return price .. " copper"
end
