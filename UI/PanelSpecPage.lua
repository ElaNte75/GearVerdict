local _, addon = ...
local page = {}
addon.PanelSpecPage = page

-- Specialization page: who the character is, which specialization to compare gear for (one at a time,
-- untick = none), and whether recommendations are active.

function page:Choose(id, checked)
    addon.Presets:SetManualSpecID(checked and id or nil)
    self:Update()
    addon:Refresh()
end

function page:Create(parent)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame = frame

    local characterLine = widgets:Section(frame, "Character")
    self.name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.name:SetPoint("TOPLEFT", characterLine, "BOTTOMLEFT", 0, -widgets.GAP_AFTER_LINE)
    self.details = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.details:SetPoint("LEFT", self.name, "RIGHT", 10, 0)
    widgets:PaintText(self.details, "note")

    local specLine, specLabel = widgets:Section(frame, "Specialization", self.name)
    widgets:Help(frame, specLabel, "Specialization",
        "Forever has no specializations of its own, so tell GearVerdict which role you play. "
        .. "Gear is compared with the stat weights of that role. Untick it to turn recommendations off.")
    self.checks = {}
    local anchor, gap = specLine, widgets.GAP_AFTER_LINE - 4
    -- Classes with talent builds pick a build from a list (UI/BuildPicker.lua) instead of a specialization.
    local useBuilds = addon.Builds and addon.BuildPicker and addon.Builds:List()
    if useBuilds then
        specLabel:SetText("Build")
        anchor = addon.BuildPicker:Create(frame, specLine, gap + 8)
    end
    for _, spec in ipairs(useBuilds and {} or addon.SpecDetection:ClassSpecs()) do
        local supported = addon.Presets:IsSupported(spec.id)
        local check = widgets:Check(frame, spec.name, anchor, gap, function(_, checked) self:Choose(spec.id, checked) end)
        check.specID = spec.id
        if not supported then
            check:Disable()
            check.extra = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            check.extra:SetPoint("LEFT", check.Text, "RIGHT", 8, 0)
            check.extra:SetText("not supported yet")
            local hover = CreateFrame("Frame", nil, frame)
            hover:SetPoint("TOPLEFT", check, "TOPLEFT")
            hover:SetPoint("BOTTOMRIGHT", check.extra, "BOTTOMRIGHT", 4, -4)
            hover:EnableMouse(true)
            widgets:Tooltip(hover, spec.name, "GearVerdict has no stat weights for " .. spec.name
                .. " yet, so it gives no recommendations for it.")
        end
        self.checks[#self.checks + 1] = check
        anchor, gap = check, widgets.GAP_NEXT_CHECK
    end
    if #self.checks == 0 and not useBuilds then
        anchor = widgets:Note(frame, "Your class is not supported yet.", specLine, widgets.GAP_AFTER_LINE)
    end

    local statusLine, statusLabel = widgets:Section(frame, "Status", anchor, widgets.GAP_SECTION - 4)
    widgets:Help(frame, statusLabel, "Status", addon.PanelStatPriority.helpText)
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.status:SetPoint("TOPLEFT", statusLine, "BOTTOMLEFT", 0, -widgets.GAP_AFTER_LINE)
    self.status:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
    self.status:SetJustifyH("LEFT")
    addon.PanelStatPriority:Create(frame, self.status)
    return frame
end

function page:Update()
    if not self.frame then return end
    local widgets = addon.PanelWidgets
    local className, classFile = UnitClass("player")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    self.name:SetText((GetUnitName and GetUnitName("player", true)) or UnitName("player") or "")
    if color then self.name:SetTextColor(color.r, color.g, color.b) end
    self.details:SetText("Level " .. (UnitLevel("player") or "?") .. " " .. widgets:ClassText(className))
    local chosen = addon.Presets:ManualSpecID()
    for _, check in ipairs(self.checks) do
        check:SetChecked(check.specID == chosen)
        widgets:UpdateCheck(check)
        if check.specID == chosen then check.Text:SetTextColor(widgets:ClassColor()) end
    end
    if addon.BuildPicker then addon.BuildPicker:Update() end
    local preset, reason = addon.Presets:Get()
    if preset then
        local build = addon.BuildPicker and addon.BuildPicker.frame and addon.Builds:Chosen()
        self.status:SetText("Active: " .. (build and (build.name .. " (gear as " .. widgets:SpecText(addon.Presets:SelectedSpecID()) .. ")")
            or widgets:SpecText(addon.Presets:SelectedSpecID())))
        self.status:SetTextColor(widgets:Color("good"))
    else
        self.status:SetText(reason == "Choose your specialization in /gv" and (addon.BuildPicker and addon.BuildPicker.frame and "Choose a build above to get recommendations." or "Choose a specialization above to get recommendations.")
            or reason or "No recommendations")
        self.status:SetTextColor(widgets:Color("bad"))
    end
    addon.PanelStatPriority:Update()
end
