local _, addon = ...
local widgets = { painted = setmetatable({}, { __mode = "k" }) }
addon.PanelWidgets = widgets

-- Shared look of the GearVerdict Control Panel (layout and spacing follow the FarmWise Control Panel).
-- Colors come from the chosen theme; regions colored through Fill/Background/Border/PaintText are
-- remembered, so a theme change recolors them at once.

widgets.colors = {
    divider = { 1.0, 1.0, 1.0, 0.12 },
    navText = { 0.96, 0.96, 0.96, 1.0 },
    navHighlightBg = { 1.0, 1.0, 1.0, 0.06 },
    titleAccent = { 0.96, 0.96, 0.96, 1.0 },
    subtitle = { 0.85, 0.85, 0.85, 1.0 },
    unchecked = { 0.86, 0.86, 0.86, 1.0 },
    disabled = { 0.58, 0.58, 0.58, 1.0 },
    good = { 0.36, 1.0, 0.36, 1.0 },
    bad = { 1.0, 0.50, 0.25, 1.0 },
    warning = { 1.0, 0.82, 0.0, 1.0 },
    fieldBg = { 0.0, 0.0, 0.0, 0.35 },
    buttonBg = { 1.0, 1.0, 1.0, 0.06 },
    buttonHoverBg = { 1.0, 1.0, 1.0, 0.13 },
    buttonText = { 0.96, 0.96, 0.96, 1.0 },
    shadow = { 0.0, 0.0, 0.0, 0.45 },
}
-- Flat backdrop: one-pixel edge, plain fill (the look of the buttons, boxes and window edge).
local FLAT = { bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 }
local BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil

local function theme(name, bg, header, sidebar, border, title, selected, selectedText, line, checked, note)
    return { name = name, frameBg = { bg[1], bg[2], bg[3], 0.97 }, contentBg = { bg[1], bg[2], bg[3], 1 },
        headerBg = header, footerBg = header, sidebarBg = sidebar, border = border, title = title, section = title,
        navSelectedBg = selected, navSelectedText = selectedText, sectionLine = line, checked = checked, note = note }
end

widgets.themeOrder = { "gold", "frost", "emerald", "graphite", "arcane", "crimson" }
widgets.themes = {
    gold = theme("Gold", { 0.169, 0.125, 0.078 }, { 0.227, 0.169, 0.102, 1 }, { 0.141, 0.102, 0.063, 1 },
        { 0.788, 0.659, 0.353, 1 }, { 0.949, 0.820, 0.420, 1 }, { 1, 0.82, 0.02, 0.16 }, { 1, 0.902, 0.549, 1 },
        { 0.9, 0.706, 0.235, 0.45 }, { 1, 0.82, 0, 1 }, { 0.784, 0.733, 0.627, 1 }),
    frost = theme("Frost", { 0.075, 0.137, 0.227 }, { 0.106, 0.192, 0.322, 1 }, { 0.059, 0.114, 0.192, 1 },
        { 0.365, 0.608, 0.820, 1 }, { 0.498, 0.831, 1, 1 }, { 0.498, 0.831, 1, 0.17 }, { 0.769, 0.925, 1, 1 },
        { 0.498, 0.831, 1, 0.4 }, { 0.498, 0.831, 1, 1 }, { 0.663, 0.741, 0.831, 1 }),
    emerald = theme("Emerald", { 0.071, 0.165, 0.094 }, { 0.102, 0.227, 0.133, 1 }, { 0.055, 0.133, 0.075, 1 },
        { 0.310, 0.659, 0.357, 1 }, { 0.435, 0.878, 0.482, 1 }, { 0.435, 0.878, 0.482, 0.16 }, { 0.722, 0.961, 0.745, 1 },
        { 0.435, 0.878, 0.482, 0.38 }, { 0.435, 0.878, 0.482, 1 }, { 0.659, 0.776, 0.678, 1 }),
    graphite = theme("Graphite", { 0.165, 0.169, 0.184 }, { 0.212, 0.216, 0.235, 1 }, { 0.137, 0.141, 0.157, 1 },
        { 0.541, 0.545, 0.573, 1 }, { 0.941, 0.941, 0.941, 1 }, { 1, 1, 1, 0.12 }, { 1, 1, 1, 1 },
        { 1, 1, 1, 0.28 }, { 1, 0.82, 0, 1 }, { 0.710, 0.714, 0.733, 1 }),
    arcane = theme("Arcane", { 0.141, 0.086, 0.227 }, { 0.192, 0.118, 0.310, 1 }, { 0.114, 0.067, 0.188, 1 },
        { 0.604, 0.447, 0.839, 1 }, { 0.831, 0.702, 1, 1 }, { 0.745, 0.588, 1, 0.18 }, { 0.918, 0.851, 1, 1 },
        { 0.745, 0.588, 1, 0.4 }, { 0.878, 0.765, 1, 1 }, { 0.749, 0.690, 0.839, 1 }),
    crimson = theme("Crimson", { 0.180, 0.071, 0.078 }, { 0.247, 0.094, 0.106, 1 }, { 0.149, 0.055, 0.063, 1 },
        { 0.769, 0.337, 0.361, 1 }, { 1, 0.604, 0.549, 1 }, { 1, 0.471, 0.431, 0.16 }, { 1, 0.816, 0.788, 1 },
        { 1, 0.471, 0.431, 0.38 }, { 1, 0.702, 0.420, 1 }, { 0.816, 0.690, 0.678, 1 }),
}

-- Distances every page uses (pixels, downwards).
widgets.GAP_AFTER_LINE = 6
widgets.GAP_NEXT_CHECK = -2
widgets.GAP_SECTION = 16

function widgets:ThemeKey()
    local key = GearVerdictDB and GearVerdictDB.options and GearVerdictDB.options.theme
    return self.themes[key] and key or "gold"
end

local function color(name)
    local value = widgets.themes[widgets:ThemeKey()][name] or widgets.colors[name]
    return value[1], value[2], value[3], value[4] or 1
end
widgets.Color = function(_, name) return color(name) end

local function paint(region, name, kind)
    if kind == "text" then
        region:SetTextColor(color(name))
    elseif kind == "border" then
        if region.SetBackdropBorderColor then region:SetBackdropBorderColor(color(name)) end
    else
        region:SetColorTexture(color(name))
    end
end

function widgets:Paint(region, name, kind)
    self.painted[region] = { name = name, kind = kind }
    paint(region, name, kind)
end

-- untracked = colored once, not by theme changes (for regions whose color is chosen elsewhere).
function widgets:Fill(texture, name, untracked)
    if untracked then paint(texture, name) else self:Paint(texture, name) end
end

function widgets:PaintText(fontString, name)
    self:Paint(fontString, name, "text")
end

-- Controls that color themselves (buttons, checkboxes) are listed here and redrawn on a theme change.
widgets.repaint = setmetatable({}, { __mode = "k" })

function widgets:ApplyTheme()
    for region, entry in pairs(self.painted) do paint(region, entry.name, entry.kind) end
    for control in pairs(self.repaint) do control:Repaint() end
end

-- The window edge: a thin line in the theme color, a soft shadow outside it and a bright stripe on top.
function widgets:Border(frame, inset)
    local border = CreateFrame("Frame", nil, frame, BACKDROP)
    border:SetPoint("TOPLEFT", -(inset or 0), inset or 0)
    border:SetPoint("BOTTOMRIGHT", inset or 0, -(inset or 0))
    border:SetFrameLevel(frame:GetFrameLevel() + 20)
    if border.SetBackdrop then
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        self:Paint(border, "border", "border")
    end
    local shadow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shadow:SetPoint("TOPLEFT", -4, 4)
    shadow:SetPoint("BOTTOMRIGHT", 4, -4)
    self:Fill(shadow, "shadow")
    local stripe = border:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", -1, -1)
    stripe:SetHeight(2)
    self:Fill(stripe, "title")
    return border
end

function widgets:Background(frame, name)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    self:Fill(texture, name)
    return texture
end

-- A small title with a thin line under it. Returns the line: what belongs to the section goes under it.
function widgets:Section(page, title, anchor, gap)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if anchor then
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or self.GAP_SECTION))
    else
        label:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -2)
    end
    label:SetJustifyH("LEFT")
    self:PaintText(label, "section")
    label:SetText(title)
    local line = page:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    line:SetPoint("RIGHT", page, "RIGHT", -4, 0)
    line:SetHeight(1)
    self:Fill(line, "sectionLine")
    return line, label
end

-- A short explanation in small grey text, wrapped inside the page.
function widgets:Note(page, text, anchor, gap)
    local note = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or 6))
    note:SetPoint("RIGHT", page, "RIGHT", -8, 0)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    self:PaintText(note, "note")
    note:SetText(text or "")
    return note
end

function widgets:Tooltip(frame, title, text)
    frame:HookScript("OnEnter", function(owner)
        local body = type(text) == "function" and text() or text
        if not body or body == "" then return end
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "", 1, 1, 1)
        GameTooltip:AddLine(body, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A small "?" that explains something while the mouse is over it.
function widgets:Help(parent, region, title, text)
    local help = CreateFrame("Button", nil, parent)
    help:SetSize(15, 15)
    help:SetPoint("LEFT", region, "RIGHT", 6, 0)
    local ring = help:CreateTexture(nil, "ARTWORK")
    ring:SetPoint("TOPLEFT", 1, -1)
    ring:SetPoint("BOTTOMRIGHT", -1, 1)
    ring:SetColorTexture(1, 1, 1, 0.12)
    help.label = help:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    help.label:SetPoint("CENTER", 0, 0)
    help.label:SetText("?")
    self:PaintText(help.label, "section")
    local hover = help:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(ring)
    hover:SetColorTexture(1, 1, 1, 0.2)
    self:Tooltip(help, title, text)
    return help
end

-- Every mention of the class or a specialization is written in the class color.
function widgets:ClassColor()
    local _, classFile = UnitClass("player")
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if classColor then return classColor.r, classColor.g, classColor.b end
    return 1, 1, 1
end

function widgets:ClassText(text)
    local r, g, b = self:ClassColor()
    return string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5), text or "")
end

-- "Enhancement Shaman" in the class color.
function widgets:SpecText(specID)
    local className = UnitClass("player")
    return self:ClassText((addon.SpecDetection:SpecName(specID) or "?") .. (className and (" " .. className) or ""))
end

function widgets:UpdateCheck(check)
    if check:IsEnabled() then
        check:SetAlpha(1)
        check.Text:SetTextColor(color(check:GetChecked() and "checked" or "unchecked"))
    else
        check:SetAlpha(0.45)
        check.Text:SetTextColor(color("disabled"))
    end
    if check.Repaint then check:Repaint() end
end

-- A checkbox with its label: a flat dark box with a square in the theme color when ticked.
-- anchor = what it goes under (a section line or the previous checkbox).
function widgets:Check(page, label, anchor, gap, onClick)
    local check = CreateFrame("CheckButton", nil, page)
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -(gap or 0))
    check.box = CreateFrame("Frame", nil, check, BACKDROP)
    check.box:SetSize(16, 16)
    check.box:SetPoint("CENTER")
    if check.box.SetBackdrop then check.box:SetBackdrop(FLAT) end
    check.mark = check.box:CreateTexture(nil, "OVERLAY")
    check.mark:SetSize(8, 8)
    check.mark:SetPoint("CENTER")
    check.Text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.Text:SetPoint("LEFT", check, "RIGHT", 2, 1)
    check.Text:SetText(label)
    check:SetHitRectInsets(0, -math.max(40, (check.Text:GetStringWidth() or 0) + 6), 0, 0)
    function check:Repaint()
        local active = self:IsEnabled() and (self.hover or self:GetChecked())
        if self.box.SetBackdropColor then
            self.box:SetBackdropColor(color("fieldBg"))
            self.box:SetBackdropBorderColor(color(active and "checked" or "sectionLine"))
        end
        self.mark:SetColorTexture(color(self:IsEnabled() and "checked" or "disabled"))
        self.mark:SetShown(self:GetChecked() and true or false)
    end
    check:SetScript("OnEnter", function(self) self.hover = true; self:Repaint() end)
    check:SetScript("OnLeave", function(self) self.hover = false; self:Repaint() end)
    hooksecurefunc(check, "SetChecked", function(self) self:Repaint() end)
    check:SetScript("OnClick", function(self)
        if onClick then onClick(self, self:GetChecked() and true or false) end
        widgets:UpdateCheck(self)
    end)
    self.repaint[check] = true
    check:Repaint()
    return check
end

-- A flat button: dark fill, thin edge in the theme color, lighter while the mouse is over it.
function widgets:Button(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, BACKDROP)
    button:SetSize(width or 90, 24)
    if button.SetBackdrop then button:SetBackdrop(FLAT) end
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 4, 0)
    label:SetPoint("RIGHT", -4, 0)
    label:SetWordWrap(false)
    button:SetFontString(label)
    button:SetText(text)
    function button:Repaint()
        local enabled = self:IsEnabled()
        if self.SetBackdropColor then
            self:SetBackdropColor(color(enabled and self.hover and "buttonHoverBg" or "buttonBg"))
            self:SetBackdropBorderColor(color(enabled and (self.hover and "checked" or "sectionLine") or "divider"))
        end
        label:SetTextColor(color(enabled and (self.hover and "title" or "buttonText") or "disabled"))
    end
    button:SetScript("OnEnter", function(self) self.hover = true; self:Repaint() end)
    button:SetScript("OnLeave", function(self) self.hover = false; self:Repaint() end)
    button:SetScript("OnEnable", function(self) self:Repaint() end)
    button:SetScript("OnDisable", function(self) self.hover = false; self:Repaint() end)
    button:SetScript("OnMouseDown", function(self) if self:IsEnabled() then label:SetPoint("LEFT", 5, -1); label:SetPoint("RIGHT", -3, -1) end end)
    button:SetScript("OnMouseUp", function() label:SetPoint("LEFT", 4, 0); label:SetPoint("RIGHT", -4, 0) end)
    if onClick then button:SetScript("OnClick", onClick) end
    self.repaint[button] = true
    button:Repaint()
    return button
end

-- Flat slider: thin track, fill in the theme color up to the handle, value shown at the right.
-- get() returns the current value, set(value) stores it; format(value) gives the text at the right.
function widgets:Slider(parent, minValue, maxValue, step, width, get, set, format)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetSize(width or 180, 16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:EnableMouse(true)
    slider:SetHitRectInsets(0, 0, -4, -4)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(4)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    self:Fill(track, "divider")
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    self:Fill(thumb, "checked")
    slider:SetThumbTexture(thumb)
    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", track, "LEFT")
    fill:SetPoint("RIGHT", thumb, "CENTER")
    self:Fill(fill, "sectionLine")
    local value = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    self:PaintText(value, "checked")
    local updating = false
    slider:SetScript("OnValueChanged", function(_, raw)
        if updating then return end
        local rounded = math.floor(raw / step + 0.5) * step
        set(rounded)
        value:SetText(format and format(rounded) or tostring(rounded))
    end)
    function slider:Refresh()
        updating = true
        local current = get()
        self:SetValue(current)
        value:SetText(format and format(current) or tostring(current))
        updating = false
    end
    return slider
end
