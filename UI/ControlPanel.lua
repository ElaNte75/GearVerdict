local _, addon = ...
local panel = {}
addon.ControlPanel = panel

-- The single GearVerdict window: header, left menu, one page at a time, footer with a note and Close.
-- Each page lives in its own module with :Create(parent, panel) returning its frame, and :Update().
-- Window behavior (options): windowPosition, lockWindow, hideInCombat, reopenAfterCombat.

local WIDTH, HEIGHT = 660, 552
local SIDEBAR, HEADER, FOOTER, PADDING = 172, 60, 48, 18
local LOGO = "Interface\\AddOns\\GearVerdict\\Media\\icon.tga"
local ICONS = "Interface\\Icons\\"
panel.contentWidth = WIDTH - SIDEBAR - 2 * PADDING

panel.pages = {
    { key = "spec", icon = "class", label = "Specialization", module = "PanelSpecPage",
      note = "Choose the specialization GearVerdict compares gear for." },
    { key = "options", icon = "INV_Misc_Spyglass_02", label = "Options", module = "PanelOptionsPage",
      note = "How upgrades look in your bags and in tooltips." },
    { key = "weights", icon = "INV_Misc_Note_01", label = "Custom Weights", module = "PanelWeightsPage",
      note = "How much each stat is worth for your specialization." },
    { key = "leveling", icon = "INV_Misc_Book_09", label = "Leveling", module = "PanelLevelingPage",
      note = "Help while leveling: which talent to take next." },
    { key = "interface", icon = "INV_Misc_Gear_01", label = "Interface", module = "PanelInterfacePage",
      note = "Colors of this window and how it behaves." },
    { key = "facts", icon = "INV_Misc_QuestionMark", label = "Facts", module = "PanelFactsPage",
      note = "What GearVerdict counts, what it does not, and how sure we are." },
}

local function options() return GearVerdictDB.options end

local function line(frame, width, height)
    local texture = frame:CreateTexture(nil, "BORDER")
    texture:SetSize(width, height)
    addon.PanelWidgets:Fill(texture, "divider")
    return texture
end

-- The page icon; "class" = the player's class emblem (round, from the game's class icons).
local function setIcon(texture, icon)
    local _, classFile = UnitClass("player")
    local coords = icon == "class" and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile]
    if coords then
        texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexture(ICONS .. (icon ~= "class" and icon or "INV_Misc_Book_11"))
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

local function navButton(parent, label, icon)
    local widgets = addon.PanelWidgets
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(30)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    widgets:Fill(highlight, "navHighlightBg")
    button.bar = button:CreateTexture(nil, "ARTWORK")
    button.bar:SetPoint("TOPLEFT")
    button.bar:SetPoint("BOTTOMLEFT")
    button.bar:SetWidth(3)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18, 18)
    button.icon:SetPoint("LEFT", 11, 0)
    setIcon(button.icon, icon)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
    button.text:SetPoint("RIGHT", -4, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetWordWrap(false)
    button.text:SetText(label)
    function button:SetSelected(selected)
        if selected then
            widgets:Fill(self.bg, "navSelectedBg", true)
            widgets:Fill(self.bar, "checked", true)
        else
            self.bg:SetColorTexture(0, 0, 0, 0)
        end
        self.bar:SetShown(selected)
        self.icon:SetDesaturated(not selected)
        self.icon:SetAlpha(selected and 1 or 0.75)
        self.text:SetTextColor(widgets:Color(selected and "navSelectedText" or "navText"))
    end
    button:SetSelected(false)
    return button
end

function panel:Select(key)
    self.selected = key
    for _, page in ipairs(self.pages) do
        local isSelected = page.key == key
        self.buttons[page.key]:SetSelected(isSelected)
        if self.frames[page.key] then self.frames[page.key]:SetShown(isSelected) end
        if isSelected then self.frame.subtitle:SetText(page.note) end
    end
    self:Update()
end

function panel:ApplyTheme()
    addon.PanelWidgets:ApplyTheme()
    if self.frame then self:Select(self.selected) end
end

function panel:Update()
    if not self.frame or not self.frame:IsShown() then return end
    for _, page in ipairs(self.pages) do
        local module = addon[page.module]
        if page.key == self.selected and module and module.Update then module:Update() end
    end
end

function panel:SavePosition()
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    options().windowPosition = { point = point, relativePoint = relativePoint, x = x, y = y }
end

function panel:RestorePosition()
    local position = options().windowPosition
    self.frame:ClearAllPoints()
    if position and position.point then
        self.frame:SetPoint(position.point, UIParent, position.relativePoint or position.point, position.x or 0, position.y or 0)
    else
        self.frame:SetPoint("CENTER")
    end
end

function panel:ResetPosition()
    options().windowPosition = nil
    if self.frame then self:RestorePosition() end
end

function panel:StartMoving()
    if not options().lockWindow then self.frame:StartMoving() end
end

function panel:StopMoving()
    self.frame:StopMovingOrSizing()
    if not options().lockWindow then self:SavePosition() end
end

-- Combat: hide if wanted, and open again afterwards only if it was open and the player wants that.
function panel:CombatStarted()
    if self.frame and self.frame:IsShown() and options().hideInCombat ~= false then
        self.hiddenByCombat = true
        self.frame:Hide()
    end
end

function panel:CombatEnded()
    if self.hiddenByCombat and options().reopenAfterCombat ~= false and self.frame then self.frame:Show() end
    self.hiddenByCombat = false
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if not GearVerdictDB or not GearVerdictDB.options then return end
    if event == "PLAYER_REGEN_DISABLED" then panel:CombatStarted() else panel:CombatEnded() end
end)

function panel:Build()
    local widgets = addon.PanelWidgets
    options().debugWindowSize, options().debugSidebarWidth = nil, nil
    local frame = CreateFrame("Frame", "GearVerdictControlPanel", UIParent)
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() self:StartMoving() end)
    frame:SetScript("OnDragStop", function() self:StopMoving() end)
    frame:SetScript("OnShow", function() self:Update() end)
    frame:SetScript("OnHide", function()
        if addon.WeightTransferDialog then addon.WeightTransferDialog:Hide() end
    end)
    frame:Hide()
    self:RestorePosition()
    tinsert(UISpecialFrames, "GearVerdictControlPanel")
    widgets:Background(frame, "frameBg")
    widgets:Border(frame)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER)
    widgets:Background(header, "headerBg")
    local footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT")
    footer:SetHeight(FOOTER)
    widgets:Background(footer, "footerBg")
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", 0, -HEADER)
    sidebar:SetPoint("BOTTOMLEFT", 0, FOOTER)
    sidebar:SetWidth(SIDEBAR)
    widgets:Background(sidebar, "sidebarBg")
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT")
    content:SetPoint("BOTTOMRIGHT", 0, FOOTER)
    widgets:Background(content, "contentBg")
    local headerLine = frame:CreateTexture(nil, "BORDER")
    headerLine:SetHeight(1)
    widgets:Fill(headerLine, "sectionLine")
    headerLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT")
    headerLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT")
    local footerLine = line(frame, WIDTH, 1)
    footerLine:SetPoint("TOPLEFT", footer, "TOPLEFT")
    footerLine:SetPoint("TOPRIGHT", footer, "TOPRIGHT")
    local sidebarLine = line(frame, 1, HEIGHT - HEADER - FOOTER)
    sidebarLine:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT")
    sidebarLine:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT")

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(38, 38)
    logo:SetPoint("LEFT", 14, 0)
    logo:SetTexture(LOGO)
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -3)
    widgets:PaintText(title, "title")
    title:SetText("GearVerdict")
    local accent = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    accent:SetPoint("LEFT", title, "RIGHT", 6, 0)
    widgets:PaintText(accent, "titleAccent")
    accent:SetText("Control Panel")
    frame.subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    frame.subtitle:SetPoint("RIGHT", header, "RIGHT", -14, 0)
    frame.subtitle:SetJustifyH("LEFT")
    frame.subtitle:SetWordWrap(false)
    widgets:PaintText(frame.subtitle, "subtitle")
    local version = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("TOPRIGHT", -16, -16)
    widgets:PaintText(version, "note")
    version:SetText("v" .. addon.version)

    local close = widgets:Button(footer, "Close", 90, function() frame:Hide() end)
    close:SetPoint("RIGHT", -16, 0)
    local footerNote = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerNote:SetPoint("LEFT", 18, 0)
    footerNote:SetPoint("RIGHT", close, "LEFT", -12, 0)
    footerNote:SetJustifyH("LEFT")
    footerNote:SetWordWrap(false)
    widgets:PaintText(footerNote, "note")
    footerNote:SetText("Changes apply right away.")

    local inset = CreateFrame("Frame", nil, content)
    inset:SetPoint("TOPLEFT", PADDING, -PADDING + 2)
    inset:SetPoint("BOTTOMRIGHT", -PADDING, PADDING - 4)
    self.inset = inset
    self.buttons, self.frames = {}, {}
    local previous
    for index, page in ipairs(self.pages) do
        local button = navButton(sidebar, page.label, page.icon)
        if index == 1 then button:SetPoint("TOPLEFT", 0, -14) else button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2) end
        button:SetPoint("RIGHT", sidebar, "RIGHT", -1, 0)
        button:SetScript("OnClick", function() self:Select(page.key) end)
        self.buttons[page.key], previous = button, button
        local module = addon[page.module]
        if module then
            local pageFrame = module:Create(inset, self)
            pageFrame:Hide()
            self.frames[page.key] = pageFrame
        end
    end
end

function panel:Toggle(key)
    if not self.frame then self:Build() end
    if self.frame:IsShown() and not key then
        self.frame:Hide()
        return
    end
    self.hiddenByCombat = false
    if key or not self.selected then self:Select(key or "spec") end
    self.frame:Show()
end
