local _, addon = ...
local page = {}
addon.PanelOptionsPage = page

-- Options page: where the upgrade arrow sits, its color (with a live preview), and what the tooltip shows.

local function options() return GearVerdictDB.options end

function page:Changed()
    self:Update()
    addon:Refresh()
end

function page:OpenColorPicker()
    local _, color = addon.UpgradeIndicators:Options()
    local previous = { r = color.r, g = color.g, b = color.b }
    local function apply()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        options().arrowColor = { r = r, g = g, b = b }
        self:Changed()
    end
    local function cancel()
        options().arrowColor = previous
        self:Changed()
    end
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({ r = color.r, g = color.g, b = color.b,
            hasOpacity = false, swatchFunc = apply, cancelFunc = cancel })
    else
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.func, ColorPickerFrame.cancelFunc = apply, cancel
        ColorPickerFrame.previousValues = previous
        ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
        ShowUIPanel(ColorPickerFrame)
    end
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
end

-- One-of-a-kind choices: clicking the ticked box keeps it ticked.
function page:Choice(frame, label, anchor, gap, key, value, tooltip)
    local check = addon.PanelWidgets:Check(frame, label, anchor, gap, function()
        options()[key] = value
        self:Changed()
    end)
    check.key, check.value = key, value
    if tooltip then addon.PanelWidgets:Tooltip(check, label, tooltip) end
    self.choices[#self.choices + 1] = check
    return check
end

function page:CreatePreview(frame, arrowLine)
    local widgets = addon.PanelWidgets
    local box = CreateFrame("Frame", nil, frame)
    box:SetSize(80, 80)
    box:SetPoint("TOPRIGHT", arrowLine, "BOTTOMRIGHT", -6, -widgets.GAP_AFTER_LINE)
    local icon = CreateFrame("Frame", nil, box)
    icon:SetSize(37, 37)
    icon:SetPoint("TOP", 0, -8)
    local texture = icon:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    texture:SetTexture("Interface\\Icons\\INV_Jewelry_Ring_03")
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local edge = icon:CreateTexture(nil, "BACKGROUND")
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0.42, 0.35, 0.18, 1)
    local label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", icon, "BOTTOM", 0, -8)
    widgets:PaintText(label, "note")
    label:SetText("Preview")
    self.previewIcon = icon
end

-- What the two arrows in the journal mean, always on screen: a small arrow of each color and its meaning.
function page:CreateLegend(frame, anchor)
    local legend = CreateFrame("Frame", nil, frame)
    legend:SetSize(400, 18)
    legend:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    self.legend, self.legendArrows = legend, {}
    local previous
    for _, entry in ipairs({ { key = "now", text = "Upgrade you can wear now" },
        { key = "goal", text = "Goal: an upgrade once you reach its level" } }) do
        local holder = CreateFrame("Frame", nil, legend)
        holder:SetSize(16, 16)
        if previous then holder:SetPoint("LEFT", previous, "RIGHT", 18, 0) else holder:SetPoint("LEFT") end
        local arrow = addon.UpgradeIndicators:Build(holder)
        arrow:SetPoint("CENTER", holder, "CENTER", 0, 0)
        local label = legend:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", holder, "RIGHT", 4, 0)
        label:SetText(entry.text)
        self.legendArrows[entry.key] = { arrow = arrow, label = label }
        previous = label
    end
end

function page:UpdateLegend(on)
    local _, color = addon.UpgradeIndicators:Options()
    local colors = { now = color, goal = addon.UpgradeIndicators.goalColor }
    for key, entry in pairs(self.legendArrows) do
        local c = colors[key]
        for _, texture in ipairs(entry.arrow.fills) do texture:SetColorTexture(c.r, c.g, c.b, 1) end
        entry.label:SetTextColor(c.r, c.g, c.b, 1)
    end
    self.legend:SetAlpha(on and 1 or 0.5)
end

function page:Create(parent)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame, self.choices = frame, {}

    local arrowLine, arrowLabel = widgets:Section(frame, "Upgrade arrow")
    widgets:Help(frame, arrowLabel, "Upgrade arrow",
        "A small arrow on items in your bags and on quest rewards that would be an upgrade for you.")
    self:CreatePreview(frame, arrowLine)
    local right = self:Choice(frame, "Top right corner of the item", arrowLine, widgets.GAP_AFTER_LINE - 4, "arrowPosition", "TOPRIGHT")
    local left = self:Choice(frame, "Top left corner of the item", right, widgets.GAP_NEXT_CHECK, "arrowPosition", "TOPLEFT")

    local swatch = CreateFrame("Button", nil, frame)
    swatch:SetSize(20, 20)
    swatch:SetPoint("TOPLEFT", left, "BOTTOMLEFT", 3, -8)
    local swatchEdge = swatch:CreateTexture(nil, "BACKGROUND")
    swatchEdge:SetAllPoints()
    swatchEdge:SetColorTexture(0, 0, 0, 1)
    self.swatch = swatch:CreateTexture(nil, "ARTWORK")
    self.swatch:SetPoint("TOPLEFT", 2, -2)
    self.swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    swatch:SetScript("OnClick", function() self:OpenColorPicker() end)
    widgets:Tooltip(swatch, "Arrow color", "Click to choose any color.")
    local colorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    colorLabel:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
    colorLabel:SetText("Arrow color")
    local change = widgets:Button(frame, "Change", 62, function() self:OpenColorPicker() end)
    change:SetPoint("LEFT", colorLabel, "RIGHT", 12, 0)
    local default = widgets:Button(frame, "Default", 62, function()
        options().arrowColor = nil
        self:Changed()
    end)
    default:SetPoint("LEFT", change, "RIGHT", 6, 0)
    widgets:Tooltip(default, "Default color", "Back to the original dark green.")

    local valueLine, valueLabel = widgets:Section(frame, "Tooltip value", swatch, widgets.GAP_SECTION + 4)
    widgets:Help(frame, valueLabel, "Tooltip value",
        "What the number next to an upgrade in the item tooltip means. It is a score from the stat weights, "
        .. "not a DPS gain.")
    local points = self:Choice(frame, "Points  (example: +0.95 pts)", valueLine, widgets.GAP_AFTER_LINE - 4, "valueMode", "points",
        "How many weight points the new item adds over the one it replaces. The same scale for every slot.")
    local percent = self:Choice(frame, "Percent  (example: +43.2%)", points, widgets.GAP_NEXT_CHECK, "valueMode", "percent",
        "How much better than the item it replaces, in percent. Empty slots and items worth 0 points still show points.")
    local journalLine, journalLabel = widgets:Section(frame, "Dungeon Journal", percent, widgets.GAP_SECTION + 4)
    widgets:Help(frame, journalLabel, "Dungeon Journal",
        "Works with the separate DungeonJournal addon: the upgrade arrow also appears on the items bosses drop "
        .. "and on quest rewards shown in the journal.\n\n"
        .. "|cff1ab826Green arrow|r (or the color you chose above): an upgrade you can wear now.\n"
        .. "|cffffb81aGold arrow|r: a goal. It will be an upgrade, but your level is still too low to wear it. "
        .. "Its tooltip shows the level you need. How far ahead to look is set with \"Goals up to\" below.\n\n"
        .. "Items with random stats (\"of the Bear\" and similar) are judged by their base stats only.")
    self.journal = widgets:Check(frame, "Show upgrade arrows in the Dungeon Journal", journalLine,
        widgets.GAP_AFTER_LINE - 4, function(_, checked)
            options().dungeonJournalArrows = checked
            self:Changed()
        end)
    local journal = addon.DungeonJournalArrows
    local aheadLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    aheadLabel:SetPoint("TOPLEFT", self.journal, "BOTTOMLEFT", 4, -8)
    aheadLabel:SetText("Goals up to")
    self.aheadLabel = aheadLabel
    self.ahead = widgets:Slider(frame, 0, journal and journal.MAX_LEVELS_AHEAD or 10, 1, 140,
        function() return journal and journal:LevelsAhead() or 0 end,
        function(value)
            options().dungeonJournalLevelsAhead = value
            addon:Refresh()
        end,
        function(value)
            if value == 0 then return "only what I can wear now" end
            return value == 1 and "1 level above me" or (value .. " levels above me")
        end)
    self.ahead:SetPoint("LEFT", aheadLabel, "RIGHT", 30, 0)
    widgets:Help(frame, aheadLabel, "Goals",
        "Items you cannot wear yet, up to this many levels above you, get a gold arrow in the journal, "
        .. "so you know what to come back for. Bags and quest rewards are not affected.")
    self.aheadWarning = widgets:Note(frame, "The higher you set this, the more items will look like upgrades: "
        .. "gear made for higher levels is almost always better than what you wear now, so in dungeons far "
        .. "above you nearly everything may get an arrow.", aheadLabel, 10)
    widgets:PaintText(self.aheadWarning, "warning")
    self.aheadWarning:SetPoint("TOPLEFT", aheadLabel, "BOTTOMLEFT", -4, -10)
    self:CreateLegend(frame, self.aheadWarning)
    self.journalNote = widgets:Note(frame, "", self.legend, 6)
    widgets:PaintText(self.journalNote, "bad")
    return frame
end

function page:Update()
    if not self.frame then return end
    local position, color = addon.UpgradeIndicators:Options()
    local current = { arrowPosition = position, valueMode = options().valueMode == "percent" and "percent" or "points" }
    for _, check in ipairs(self.choices) do
        check:SetChecked(current[check.key] == check.value)
        addon.PanelWidgets:UpdateCheck(check)
    end
    self.swatch:SetColorTexture(color.r, color.g, color.b, 1)
    -- Dungeon Journal: usable only when that addon is loaded (checked every time the page is shown).
    local journal = addon.DungeonJournalArrows
    local available = journal and journal:Available()
    local on = available and journal:Enabled()
    if available then self.journal:Enable() else self.journal:Disable() end
    self.journal:SetChecked(on and true or false)
    addon.PanelWidgets:UpdateCheck(self.journal)
    self.ahead:Refresh()
    self.ahead:EnableMouse(on and true or false)
    self.ahead:SetAlpha(on and 1 or 0.4)
    self.aheadLabel:SetTextColor(addon.PanelWidgets:Color(on and "unchecked" or "disabled"))
    self.aheadWarning:SetAlpha(on and 1 or 0.5)
    self:UpdateLegend(on)
    self.journalNote:SetText(available and ""
        or "The DungeonJournal addon is not installed or not enabled, so these options are switched off.")
    addon.UpgradeIndicators:Preview(self.previewIcon)
end
