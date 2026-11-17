local _, addon = ...
local page = {}
addon.PanelInterfacePage = page

-- Interface page: color theme of the Control Panel and how the window behaves.

local function options() return GearVerdictDB.options end

function page:Create(parent, panel)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame, self.panel, self.themeChecks = frame, panel, {}

    local themeLine, themeLabel = widgets:Section(frame, "Color theme")
    widgets:Help(frame, themeLabel, "Color theme", "Colors of this window only. Bag arrows and tooltips keep their own colors.")
    local columnWidth = math.floor((panel.contentWidth or 358) / 2)
    local columnAnchor = {}
    for index, key in ipairs(widgets.themeOrder) do
        local themeData = widgets.themes[key]
        local column = index <= 3 and 1 or 2
        local anchor = columnAnchor[column]
        local check = widgets:Check(frame, themeData.name, anchor or themeLine,
            anchor and widgets.GAP_NEXT_CHECK or widgets.GAP_AFTER_LINE - 4, function()
                options().theme = key
                panel:ApplyTheme()
            end)
        if not anchor and column == 2 then
            check:ClearAllPoints()
            check:SetPoint("TOPLEFT", themeLine, "BOTTOMLEFT", columnWidth, -(widgets.GAP_AFTER_LINE - 4))
            frame:SetScript("OnSizeChanged", function(_, width)
                check:SetPoint("TOPLEFT", themeLine, "BOTTOMLEFT", math.floor(width / 2), -(widgets.GAP_AFTER_LINE - 4))
            end)
        end
        local swatch = frame:CreateTexture(nil, "ARTWORK")
        swatch:SetSize(28, 10)
        check.swatch = swatch
        local bg, accent = themeData.headerBg, themeData.title
        swatch:SetColorTexture(bg[1], bg[2], bg[3], 1)
        local stripe = frame:CreateTexture(nil, "OVERLAY")
        stripe:SetSize(28, 3)
        stripe:SetPoint("BOTTOM", swatch, "BOTTOM")
        stripe:SetColorTexture(accent[1], accent[2], accent[3], 1)
        check.themeKey = key
        self.themeChecks[#self.themeChecks + 1] = check
        columnAnchor[column] = check
    end
    -- color samples line up in one column per side, just after the longest name of that side
    local longest = { 0, 0 }
    for index, check in ipairs(self.themeChecks) do
        local column = index <= 3 and 1 or 2
        longest[column] = math.max(longest[column], check.Text:GetStringWidth() or 0)
    end
    for index, check in ipairs(self.themeChecks) do
        local column = index <= 3 and 1 or 2
        check.swatch:SetPoint("LEFT", check, "RIGHT", math.ceil(math.max(longest[column], 50)) + 12, 0)
    end

    local windowLine = widgets:Section(frame, "Window", columnAnchor[1], widgets.GAP_SECTION)
    self.hide = widgets:Check(frame, "Hide this window during combat", windowLine, widgets.GAP_AFTER_LINE - 4, function(_, checked)
        options().hideInCombat = checked
        self:Update()
    end)
    self.reopen = widgets:Check(frame, "Open it again after combat", self.hide, widgets.GAP_NEXT_CHECK, function(_, checked)
        options().reopenAfterCombat = checked
    end)
    widgets:Tooltip(self.reopen, "Open it again after combat",
        "Only if the window was open when the fight started. Off: it stays closed until you type /gv.")
    self.lock = widgets:Check(frame, "Lock the window position", self.reopen, widgets.GAP_NEXT_CHECK, function(_, checked)
        options().lockWindow = checked
    end)
    widgets:Tooltip(self.lock, "Lock the window position", "The window cannot be dragged, so it does not move by accident.")
    self.minimap = widgets:Check(frame, "Show the minimap icon", self.lock, widgets.GAP_NEXT_CHECK, function(_, checked)
        addon.MinimapIcon:SetShown(checked)
    end)
    widgets:Tooltip(self.minimap, "Show the minimap icon", "An extra button by the minimap that opens and closes this "
        .. "window. Off by default: GearVerdict is always in the game's addon menu next to the minimap.")
    local reset = widgets:Button(frame, "Reset position", 110, function() panel:ResetPosition() end)
    reset:SetPoint("TOPLEFT", self.minimap, "BOTTOMLEFT", 4, -6)
    widgets:Tooltip(reset, "Reset position", "Move the window back to the middle of the screen.")
    return frame
end

function page:Update()
    if not self.frame then return end
    local widgets = addon.PanelWidgets
    local current = widgets:ThemeKey()
    for _, check in ipairs(self.themeChecks) do
        check:SetChecked(check.themeKey == current)
        widgets:UpdateCheck(check)
    end
    local hide = options().hideInCombat ~= false
    self.hide:SetChecked(hide)
    self.reopen:SetChecked(options().reopenAfterCombat ~= false)
    self.reopen:SetEnabled(hide)
    self.lock:SetChecked(options().lockWindow == true)
    self.minimap:SetChecked(addon.MinimapIcon:IsShown())
    for _, check in ipairs({ self.hide, self.reopen, self.lock, self.minimap }) do widgets:UpdateCheck(check) end
end
