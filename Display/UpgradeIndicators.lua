local _, addon = ...
local indicators = { frames = setmetatable({}, { __mode = "k" }) }
addon.UpgradeIndicators = indicators
indicators.defaultColor = { r = 0.1, g = 0.72, b = 0.15 }
-- Dungeon Journal items that are a goal (wearable a few levels from now): always gold.
indicators.goalColor = { r = 1.0, g = 0.72, b = 0.1 }

function indicators:Options()
    local options = GearVerdictDB and GearVerdictDB.options or {}
    local position = options.arrowPosition == "TOPLEFT" and "TOPLEFT" or "TOPRIGHT"
    return position, options.arrowColor or self.defaultColor
end

function indicators:Apply(frame, button, goal)
    local position, color = self:Options()
    if goal then color = self.goalColor end
    -- Wide buttons (quest rewards) name the icon to attach to, so the arrow sits on the icon corner.
    local target = button.gearVerdictAnchor or button
    local key = position .. color.r .. "," .. color.g .. "," .. color.b .. tostring(target)
    if frame.appliedKey == key then return end
    frame.appliedKey = key
    frame:ClearAllPoints()
    frame:SetPoint(position, target, position, position == "TOPLEFT" and -3 or 3, 3)
    for _, texture in ipairs(frame.fills) do texture:SetColorTexture(color.r, color.g, color.b, 1) end
end

function indicators:Set(button, visible, goal)
    local frame = self.frames[button]
    if not visible then
        if frame then frame:Hide() end
        return
    end
    if not frame then
        frame = self:Build(button)
        self.frames[button] = frame
    end
    self:Apply(frame, button, goal)
    frame:Show()
end

function indicators:Build(button)
    local frame = CreateFrame("Frame", nil, button)
    frame:SetSize(16, 16)
    frame:SetFrameLevel(button:GetFrameLevel() + 10)
    frame:EnableMouse(false)
    frame.fills = {}
    local function rect(sublevel, fill, width, height, top)
        local texture = frame:CreateTexture(nil, "OVERLAY", nil, sublevel)
        if fill then frame.fills[#frame.fills + 1] = texture else texture:SetColorTexture(0, 0, 0, 0.9) end
        texture:SetSize(width, height)
        texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 8 - width / 2, top)
    end
    for row = 1, 7 do
        local first = row == 1 and 1 or 0
        rect(1, false, 2 * row + 2, 1 + first, -row + first)
        rect(2, true, 2 * row, 1, -row)
    end
    rect(1, false, 16, 1, -8)
    rect(1, false, 8, 8, -8)
    rect(2, true, 6, 7, -8)
    return frame
end

-- The arrow drawn on a preview icon in the Control Panel; not touched by bag refreshes.
function indicators:Preview(button)
    button.gearVerdictPreview = button.gearVerdictPreview or self:Build(button)
    self:Apply(button.gearVerdictPreview, button)
    button.gearVerdictPreview:Show()
end

function indicators:HideAll()
    for _, frame in pairs(self.frames) do frame:Hide() end
end
