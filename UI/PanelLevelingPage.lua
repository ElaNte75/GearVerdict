local _, addon = ...
local page = {}
addon.PanelLevelingPage = page

-- Leveling page: one master switch for everything that helps while leveling (off = all of it stays silent),
-- which site's talent order to follow, a preview of the level-up talent hint, and talent placement (Place talents /
-- Auto, moved here from the Specialization page 2026-11-21). Future leveling helpers go here.

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
        "When you reach a new level (10-60), a message in the middle of the screen tells you which "
        .. "talent to take next, following the chosen guide for your specialization. It reads your talents and, "
        .. "if you took other ones, steers you back onto the guide.")
    local preview = widgets:Button(frame, "Preview", 80, function()
        if addon.TalentHint then addon.TalentHint:Preview() else addon:Print("Talent hint files are not loaded; restart the game.") end
    end)
    preview:SetPoint("TOPLEFT", hintLine, "BOTTOMLEFT", 2, -(widgets.GAP_AFTER_LINE + 2))
    widgets:Tooltip(preview, "Preview", "Shows the message now, with your next talent point "
        .. "(of a later level if everything up to now is taken). Works even when the helper is off. Same as /gv talent.")
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.status:SetPoint("LEFT", preview, "RIGHT", 12, 0)
    self.status:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    self.status:SetJustifyH("LEFT")
    self.status:SetWordWrap(false)

    local timeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeLabel:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -16)
    timeLabel:SetText("Message stays")
    local hint = addon.TalentHint
    self.seconds = widgets:Slider(frame, hint and hint.MIN_SECONDS or 10, hint and hint.MAX_SECONDS or 60, 5, 160,
        function() return hint and hint:ShowSeconds() or 20 end,
        function(value) options().levelingBannerSeconds = value end,
        function(value) return value .. " s" end)
    self.seconds:SetPoint("LEFT", timeLabel, "RIGHT", 14, 0)
    widgets:Tooltip(self.seconds, "Message stays", "How long the level-up message stays on screen: 10 seconds to 1 minute.")

    -- Talent placement (Engine/TalentPlacer.lua): never presses Apply, it only fills the talent window.
    local placeLine, placeLabel = widgets:Section(frame, "Talent placement", timeLabel, widgets.GAP_SECTION)
    widgets:Help(frame, placeLabel, "Talent placement",
        "Puts your unspent talent points into the talent window in the order of the build chosen on the "
        .. "Specialization page. It never presses Apply: you check the points and apply them yourself.")
    self.place = widgets:Button(frame, "Place talents", 110, function() self:Place() end)
    self.place:SetPoint("TOPLEFT", placeLine, "BOTTOMLEFT", 2, -(widgets.GAP_AFTER_LINE + 2))
    widgets:Tooltip(self.place, "Place talents", "Puts your unspent talent points into the talent window, in the "
        .. "order of your build, and opens it. It never presses Apply: you check the points and apply them yourself "
        .. "(Reset in the talent window undoes them).")
    self.auto = widgets:Button(frame, "", 90, function() self:ToggleAuto() end)
    self.auto:SetPoint("LEFT", self.place, "RIGHT", 8, 0)
    widgets:Tooltip(self.auto, "Auto placement", "When on, each new talent point is placed for you and the talent "
        .. "window opens. It still never presses Apply. Works while the leveling helper is on.")
    self.placeNote = widgets:Note(frame, "", self.place, 9)
    self.placeNote:SetWordWrap(false)
    return frame
end

function page:ShowPlaceResult(result)
    local widgets = addon.PanelWidgets
    local text = result.text or ""
    if result.placed and result.placed > 0 and result.opened == false then text = text .. " Press Y to open the talents." end
    self.placeNote:SetText(text)
    self.placeNote:SetTextColor(widgets:Color(result.status == "ok" and "good" or (result.placed or 0) > 0 and "warning" or "bad"))
end

function page:Place()
    self:ShowPlaceResult(addon.TalentPlacer:Run())
end

function page:ToggleAuto()
    options().autoPlaceTalents = not options().autoPlaceTalents or nil
    self:Update()
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
    self.seconds:Refresh()
    if self.place then
        self.auto:SetText("Auto: " .. (options().autoPlaceTalents and "on" or "off"))
        self.place:SetEnabled(addon.Builds ~= nil and addon.Builds:Chosen() ~= nil)
    end
    local specID = addon.Presets and addon.Presets:SelectedSpecID()
    local build = addon.Builds and addon.Builds:Chosen()
    if build and build.order and specID and addon.Presets:IsSupported(specID) then
        self.status:SetText("Following build: " .. build.name .. " (its own talent order)")
    elseif specID and addon.Presets:IsSupported(specID) then
        self.status:SetText("For: " .. widgets:SpecText(specID))
    else
        self.status:SetText("Choose your specialization first.")
    end
end
