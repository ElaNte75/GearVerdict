local _, addon = ...
local hint = {}
addon.TalentHint = hint

-- Shows the talent suggestion: three centered lines in the middle of the screen, no background (title,
-- level line, small countdown). How long it stays is chosen on the Leveling page (10-60 s, default 20).
-- Nothing goes to chat. The choice itself is made in Engine\TalentAdvisor.lua.

hint.SHOW_SECONDS, hint.MIN_SECONDS, hint.MAX_SECONDS = 20, 10, 60
hint.WAIT_SECONDS = 6
hint.TITLE = "GearVerdict"
hint.PREVIEW_TITLE = "GearVerdict Preview"

local function enabled()
    return addon.TalentAdvisor and addon.TalentAdvisor:Enabled() or false
end

-- Seconds the message stays on screen (Leveling page slider).
function hint:ShowSeconds()
    local value = tonumber(GearVerdictDB and GearVerdictDB.options and GearVerdictDB.options.levelingBannerSeconds)
    if not value then return self.SHOW_SECONDS end
    return math.max(self.MIN_SECONDS, math.min(self.MAX_SECONDS, math.floor(value + 0.5)))
end

function hint:CreateBanner()
    if self.banner then return self.banner end
    local banner = CreateFrame("Frame", nil, UIParent)
    banner:SetSize(520, 62)
    banner:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    banner:SetFrameStrata("DIALOG")
    banner:EnableMouse(false)
    -- No background: title, level line and a small countdown line, all centered.
    banner.title = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    banner.title:SetPoint("TOP", 0, -6)
    banner.main = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    banner.main:SetPoint("TOP", banner.title, "BOTTOM", 0, -6)
    banner.main:SetWidth(460)
    banner.timer = banner:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    banner.timer:SetPoint("TOP", banner.main, "BOTTOM", 0, -5)
    banner:SetScript("OnUpdate", function(frame)
        local left = (frame.hideAt or 0) - GetTime()
        if left <= 0 then frame:Hide(); return end
        local seconds = math.ceil(left)
        if seconds ~= frame.shownSeconds then
            frame.shownSeconds = seconds
            frame.timer:SetText(("closes in %ds"):format(seconds))
        end
    end)
    banner:Hide()
    self.banner = banner
    return banner
end

function hint:ShowBanner(text, title)
    local banner = self:CreateBanner()
    banner.title:SetText(title or self.TITLE)
    banner.main:SetText(text)
    banner.hideAt = GetTime() + self:ShowSeconds()
    banner.shownSeconds = nil
    banner:Show()
end

-- Banner for a finished suggestion (status "ok"): title + level line only. Nothing goes to chat.
function hint:Display(result)
    self:ShowBanner(result.text)
end

-- Level-up flow. The point may arrive a moment after the level, so wait briefly and listen for the change.
function hint:TryPending()
    local pending = self.pending
    if not pending then return end
    if GetTime() > pending.expires then self.pending = nil; return end
    local result = addon.TalentAdvisor:Suggest(pending.level)
    if result.status == "ok" then
        self.pending = nil
        self:Display(result)
    elseif result.status ~= "nopoints" then
        self.pending = nil
    end
end

function hint:OnLevelUp(level)
    if not enabled() then return end
    local started = GetTime()
    self.pending = { level = tonumber(level) or UnitLevel(), expires = started + self.WAIT_SECONDS }
    C_Timer.After(1, function() self:TryPending() end)
    C_Timer.After(self.WAIT_SECONDS + 0.5, function()
        if self.pending and self.pending.expires == started + self.WAIT_SECONDS then self.pending = nil end
    end)
end

function hint:Initialize()
    if self.frame then return end
    local frame = CreateFrame("Frame")
    self.frame = frame
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    pcall(frame.RegisterEvent, frame, "CHARACTER_POINTS_CHANGED")
    frame:SetScript("OnEvent", function(_, event, arg)
        if event == "PLAYER_LEVEL_UP" then
            self:OnLevelUp(arg)
        elseif self.pending then
            C_Timer.After(0.3, function() self:TryPending() end)
        end
    end)
end

-- Preview: same banner with the title "GearVerdict Preview". It shows the next guide point (even one of a
-- later level when everything up to now is taken), else the reason there is none.
function hint:PreviewText(result)
    if result.status == "ok" then return result.text end
    return "No talent hint: " .. (result.why or result.status or "?")
end

function hint:Preview(level)
    local result = addon.TalentAdvisor:Suggest(level, { preview = true })
    self:ShowBanner(self:PreviewText(result), self.PREVIEW_TITLE)
    return result
end
