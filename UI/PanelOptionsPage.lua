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
    local note = widgets:Note(frame, "Changes apply right away to your bags, quest rewards and tooltips.", percent, 10)

    local talentLine, talentLabel = widgets:Section(frame, "Level-up hint", note, widgets.GAP_SECTION - 4)
    widgets:Help(frame, talentLabel, "Level-up hint",
        "When you reach a new level (10-60), a message in the middle of the screen and in chat tells you which "
        .. "talent to take next, following the Icy Veins leveling guide for your chosen specialization. "
        .. "If you took other talents, it steers you back onto the guide.")
    self.talentCheck = widgets:Check(frame, "Suggest next talent on level-up", talentLine, widgets.GAP_AFTER_LINE - 4,
        function(_, checked)
            options().talentHint = checked or nil
            self:Update()
        end)
    local previewButton = widgets:Button(frame, "Preview", 70, function()
        if addon.TalentHint then addon.TalentHint:Preview() else addon:Print("Talent hint files are not loaded; restart the game.") end
    end)
    previewButton:SetPoint("LEFT", self.talentCheck.Text, "RIGHT", 14, 0)
    widgets:Tooltip(previewButton, "Preview", "Shows the suggestion for your current level now, and which way it was found "
        .. "(reading your talents or by level only). Works even when the option is off. Same as /gv talent.")
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
    if self.talentCheck then
        self.talentCheck:SetChecked(options().talentHint and true or false)
        addon.PanelWidgets:UpdateCheck(self.talentCheck)
    end
    addon.UpgradeIndicators:Preview(self.previewIcon)
end
