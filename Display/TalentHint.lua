local _, addon = ...
local hint = {}
addon.TalentHint = hint

-- Shows the talent suggestion: a small banner in the middle of the screen (20 seconds, with a countdown
-- and an X to close it earlier) and the same line in chat. The choice itself is made in
-- Engine\TalentAdvisor.lua. Also provides the preview report.

hint.SHOW_SECONDS = 20
hint.WAIT_SECONDS = 6
hint.OFF_PATH_TEXT = "You are off the guide path; following it from here."

local function enabled()
    return GearVerdictDB and GearVerdictDB.options and GearVerdictDB.options.talentHint and true or false
end

function hint:CreateBanner()
    if self.banner then return self.banner end
    local banner = CreateFrame("Frame", nil, UIParent)
    banner:SetSize(520, 54)
    banner:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    banner:SetFrameStrata("DIALOG")
    banner:EnableMouse(true)
    local background = banner:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.7)
    local edge = banner:CreateTexture(nil, "BORDER")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetHeight(2)
    edge:SetColorTexture(1, 0.82, 0, 1)
    banner.main = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    banner.main:SetPoint("TOP", 0, -9)
    banner.main:SetWidth(460)
    banner.note = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    banner.note:SetPoint("TOP", banner.main, "BOTTOM", 0, -4)
    banner.note:SetWidth(460)
    -- X in the top-right corner: close it yourself once you have read it.
    local close = CreateFrame("Button", nil, banner, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() banner:Hide() end)
    banner.close = close
    -- Countdown in the bottom-right corner, updated about once per second.
    banner.timer = banner:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    banner.timer:SetPoint("BOTTOMRIGHT", -6, 5)
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

function hint:ShowBanner(text, note)
    local banner = self:CreateBanner()
    banner.main:SetText("GearVerdict \226\128\148 " .. text)
    banner.note:SetText(note or "")
    banner:SetHeight(note and 78 or 62)
    banner.hideAt = GetTime() + self.SHOW_SECONDS
    banner.shownSeconds = nil
    banner:Show()
end

-- Banner + chat for a finished suggestion (status "ok").
function hint:Display(result)
    local note = result.off and result.mode == "talents" and self.OFF_PATH_TEXT or nil
    self:ShowBanner(result.text, note)
    addon:Print(result.text)
    if note then addon:Print(note) end
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

-- Lines of the preview report (also used by tests).
function hint:Report(result)
    local lines = {}
    local mode = result.mode == "talents" and "reading your real talents"
        or result.mode == "level" and "by level only (fallback: your talents could not be used)" or "none"
    lines[#lines + 1] = ("Talent hint preview for level %d. Mode: %s."):format(result.level or 0, mode)
    local read = result.read
    if read then
        lines[#lines + 1] = ("Read: %d talents, %d points spent, unspent points: %s, guide talents found by name: %d.")
            :format(read.talents, read.spent, read.unspent == nil and "unknown" or tostring(read.unspent),
                result.matched or 0)
    else
        lines[#lines + 1] = "Read: nothing (the talent functions are missing or empty)."
    end
    if result.status == "ok" then
        lines[#lines + 1] = result.text
        if result.off and result.mode == "talents" then lines[#lines + 1] = self.OFF_PATH_TEXT end
    else
        lines[#lines + 1] = "No suggestion: " .. (result.why or result.status)
    end
    if result.why and result.status == "ok" then lines[#lines + 1] = result.why end
    if read and read.unspent == 0 then lines[#lines + 1] = "You have no unspent talent points right now." end
    return lines
end

function hint:Preview(level)
    local result = addon.TalentAdvisor:Suggest(level, { preview = true })
    for _, line in ipairs(self:Report(result)) do addon:Print(line) end
    if result.status == "ok" then
        self:ShowBanner(result.text, result.off and result.mode == "talents" and self.OFF_PATH_TEXT or nil)
    end
    return result
end
