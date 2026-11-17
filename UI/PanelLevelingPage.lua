local _, addon = ...
local page = {}
addon.PanelLevelingPage = page

-- Leveling page: one master switch for everything that helps while leveling (off = all of it stays silent),
-- which site's talent order to follow, and a preview of the level-up talent hint. Future leveling helpers go here.

local function options() return GearVerdictDB.options end

function page:Create(parent)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame, self.guideChecks = frame, {}

    local mainLine, mainLabel = widgets:Section(frame, "Leveling helper")
    widgets:Help(frame, mainLabel, "Leveling helper",
        "One switch for everything on this page. When it is off, GearVerdict shows nothing about leveling.")
    self.enable = widgets:Check(frame, "Enable leveling helper", mainLine, widgets.GAP_AFTER_LINE - 4, function(_, checked)
        options().levelingEnabled = checked or nil
        self:Update()
    end)
    local mainNote = widgets:Note(frame, "Off: no level-up messages at all. The Preview below still works.", self.enable, 4)

    local guideLine, guideLabel = widgets:Section(frame, "Talent guide", mainNote, widgets.GAP_SECTION)
    widgets:Help(frame, guideLabel, "Talent guide",
        "Which website's talent order the hint follows. Both cover levels 10-60 for every specialization.")
    local choices = {
        { key = "icyveins", label = "Icy Veins  (default)", tip = "The talent order of the Icy Veins leveling guide for your "
            .. "specialization. Complete for every specialization." },
        { key = "wowhead", label = "Wowhead", tip = "The first build's \"Talent Order\" on Wowhead's talent page for your "
            .. "specialization. Where that page has none (Rogue, Warlock, Balance and Restoration Druid) Wowhead's "
            .. "leveling guide order is used." },
    }
    local anchor, gap = guideLine, widgets.GAP_AFTER_LINE - 4
    for _, choice in ipairs(choices) do
        local check = widgets:Check(frame, choice.label, anchor, gap, function()
            options().levelingGuide = choice.key
            self:Update()
        end)
        widgets:Tooltip(check, choice.label, choice.tip)
        check.guideKey = choice.key
        self.guideChecks[#self.guideChecks + 1] = check
        anchor, gap = check, widgets.GAP_NEXT_CHECK
    end

    local hintLine, hintLabel = widgets:Section(frame, "Talent hint on level-up", anchor, widgets.GAP_SECTION)
    widgets:Help(frame, hintLabel, "Talent hint on level-up",
        "When you reach a new level (10-60), a message in the middle of the screen and in chat tells you which "
        .. "talent to take next, following the chosen guide for your specialization. It reads your talents and, "
        .. "if you took other ones, steers you back onto the guide.")
    local preview = widgets:Button(frame, "Preview", 80, function()
        if addon.TalentHint then addon.TalentHint:Preview() else addon:Print("Talent hint files are not loaded; restart the game.") end
    end)
    preview:SetPoint("TOPLEFT", hintLine, "BOTTOMLEFT", 2, -(widgets.GAP_AFTER_LINE + 2))
    widgets:Tooltip(preview, "Preview", "Shows the suggestion for your current level now, and which way it was found "
        .. "(reading your talents or by level only). Works even when the helper is off. Same as /gv talent.")
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.status:SetPoint("LEFT", preview, "RIGHT", 12, 0)
    self.status:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    self.status:SetJustifyH("LEFT")
    self.status:SetWordWrap(false)
    return frame
end

function page:Update()
    if not self.frame then return end
    local widgets, advisor = addon.PanelWidgets, addon.TalentAdvisor
    self.enable:SetChecked(options().levelingEnabled and true or false)
    widgets:UpdateCheck(self.enable)
    local guide = advisor and advisor:GuideKey() or "icyveins"
    for _, check in ipairs(self.guideChecks) do
        check:SetChecked(check.guideKey == guide)
        widgets:UpdateCheck(check)
    end
    local specID = addon.Presets and addon.Presets:SelectedSpecID()
    if specID and addon.Presets:IsSupported(specID) then
        self.status:SetText("For: " .. widgets:SpecText(specID))
    else
        self.status:SetText("Choose your specialization first.")
    end
end
