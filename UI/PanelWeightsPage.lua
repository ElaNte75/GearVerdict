local _, addon = ...
local page = { rows = {} }
addon.PanelWeightsPage = page

-- Custom Weights page: the weights of the chosen specialization, each with its default value, the
-- player's value and a reset button. Import/Export open WeightTransferDialog.

local ROW_HEIGHT = 22
-- Columns are measured from the RIGHT edge of the table, so the table always fits its page:
-- [stat ......... default | box | reset]
local RESET_SIZE, BOX_WIDTH, GAP = 16, 58, 6
local BOX_RIGHT = RESET_SIZE + 2 + GAP            -- box right edge, from the table right edge
local DEFAULT_RIGHT = BOX_RIGHT + BOX_WIDTH + 18  -- default value right edge

local function specID()
    local preset = addon.Presets:Get()
    return preset and addon.Presets:SelectedSpecID()
end

StaticPopupDialogs.GEARVERDICT_RESET_WEIGHTS = {
    text = "Put every weight of %s back to its default value?",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, data)
        addon.Weights:ResetAll(data)
        page:Changed()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function page:Changed()
    self:Update()
    addon:Refresh()
end

function page:Commit(row)
    local spec = specID()
    if not spec then return end
    local value = tonumber(row.box:GetText())
    if addon.Weights:Set(spec, row.key, value) then
        self.error:SetText("")
        self:Changed()
    else
        self.error:SetText("Use a number from 0 to 1000. " .. addon.Weights:Name(row.key) .. " was not changed.")
        self:Update()
    end
end

function page:Row(index)
    local row = self.rows[index]
    if row then return row end
    local widgets = addon.PanelWidgets
    row = CreateFrame("Frame", nil, self.content)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -4 - (index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", self.header, "RIGHT")
    local stripe = row:CreateTexture(nil, "BACKGROUND")
    stripe:SetPoint("TOPLEFT")
    stripe:SetPoint("BOTTOMRIGHT", -(BOX_RIGHT - 4), 0) -- ends just after the input box
    stripe:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.03 or 0)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.default = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.default:SetPoint("RIGHT", -DEFAULT_RIGHT, 0)
    row.label:SetPoint("LEFT", 4, 0)
    row.label:SetPoint("RIGHT", row.default, "LEFT", -8, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.default:SetTextColor(widgets:Color("disabled"))
    row.box = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.box:SetSize(BOX_WIDTH, 18)
    row.box:SetPoint("RIGHT", -BOX_RIGHT, 0)
    row.box:SetTextInsets(0, 6, 0, 0)
    row.box:SetAutoFocus(false)
    row.box:SetJustifyH("RIGHT")
    row.box:SetMaxLetters(8)
    row.box:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    row.box:SetScript("OnEscapePressed", function(box)
        box:SetText(addon.Weights:Format(addon.Weights:Effective(specID(), row.key)))
        box:ClearFocus()
    end)
    row.box:SetScript("OnEditFocusLost", function() self:Commit(row) end)
    row.reset = CreateFrame("Button", nil, row)
    row.reset:SetSize(RESET_SIZE, RESET_SIZE)
    row.reset:SetPoint("RIGHT", -2, 0)
    row.reset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    row.reset:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    row.reset:SetScript("OnClick", function()
        addon.Weights:Reset(specID(), row.key)
        self:Changed()
    end)
    widgets:Tooltip(row.reset, "Reset", "Put this weight back to its default value.")
    self.rows[index] = row
    return row
end

function page:Create(parent, panel)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame = frame
    self.empty = widgets:Note(frame, "Choose a supported specialization on the Specialization page first. "
        .. "Each specialization keeps its own weights.", frame, -2)
    self.empty:ClearAllPoints()
    self.empty:SetPoint("TOPLEFT", 0, -4)
    self.empty:SetPoint("RIGHT", -8, 0)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -22, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize((panel and panel.contentWidth or 358) - 24, 10)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(math.max(width, 10)) end)
    self.scroll, self.content = scroll, content

    local warning = CreateFrame("Frame", nil, content)
    warning:SetPoint("TOPLEFT", 0, -2)
    warning:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    warning:SetHeight(56)
    local tint = warning:CreateTexture(nil, "BACKGROUND")
    tint:SetAllPoints()
    tint:SetColorTexture(1, 0.82, 0, 0.08)
    local bar = warning:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("BOTTOMLEFT")
    bar:SetWidth(2)
    bar:SetColorTexture(1, 0.82, 0, 0.8)
    local text = warning:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", 10, -7)
    text:SetPoint("RIGHT", -8, 0)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetTextColor(widgets:Color("warning"))
    text:SetText("Careful: these numbers decide every upgrade arrow and tooltip. If you are not sure what you "
        .. "are doing, leave them as they are. Weights from sites made for retail WoW (such as Raidbots) may not fit Forever.")
    -- the box grows with its text, so a bigger font or UI scale never pushes the text out of it
    local function fitWarning()
        local height = math.ceil((text:GetStringHeight() or 0) + 14)
        if height > 20 then warning:SetHeight(height) end
    end
    warning:SetScript("OnSizeChanged", fitWarning)
    warning:SetScript("OnShow", fitWarning)
    self.warning = warning

    self.title = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.title:SetPoint("TOPLEFT", warning, "BOTTOMLEFT", 0, -44)
    widgets:PaintText(self.title, "section")
    local import = widgets:Button(content, "Import", 80, function() addon.WeightTransferDialog:Open("import", specID()) end)
    local export = widgets:Button(content, "Export", 80, function() addon.WeightTransferDialog:Open("export", specID()) end)
    local resetAll = widgets:Button(content, "Reset all", 86, function()
        local spec = specID()
        if spec then StaticPopup_Show("GEARVERDICT_RESET_WEIGHTS", addon.PanelWidgets:SpecText(spec), nil, spec) end
    end)
    import:SetPoint("TOPLEFT", warning, "BOTTOMLEFT", 0, -10)
    export:SetPoint("LEFT", import, "RIGHT", 6, 0)
    resetAll:SetPoint("LEFT", export, "RIGHT", 6, 0)
    widgets:Tooltip(import, "Import weights", "Paste a Pawn weight string (from Raidbots, Wowhead, a simulator or "
        .. "another addon). You see the changes before they are applied.")
    widgets:Tooltip(export, "Export weights", "Get these weights as a Pawn string, to keep a copy or share them.")
    self.resetAll = resetAll

    local line = content:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -8)
    line:SetPoint("RIGHT", content, "RIGHT", -4, 0)
    line:SetHeight(1)
    widgets:Fill(line, "sectionLine")
    self.header = CreateFrame("Frame", nil, content)
    self.header:SetHeight(16)
    self.header:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -6)
    self.header:SetPoint("RIGHT", line, "RIGHT")
    local function heading(textValue, x, justify)
        local label = self.header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        if justify == "RIGHT" then label:SetPoint("RIGHT", self.header, "RIGHT", -x, 0) else label:SetPoint("LEFT", x, 0) end
        label:SetText(textValue)
        return label
    end
    local statHeading = heading("Stat", 4)
    widgets:Help(self.header, statHeading, "Stat weights",
        "How many points one point of a stat is worth. An item's score is the sum of its stats times these weights; "
        .. "a higher weight makes that stat more important. Values from 0 to 1000.")
    heading("Default", DEFAULT_RIGHT, "RIGHT")
    heading("Yours", BOX_RIGHT + 6, "RIGHT")

    self.error = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.error:SetTextColor(1, 0.3, 0.3)
    self.error:SetJustifyH("LEFT")
    self.footnote = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.footnote:SetJustifyH("LEFT")
    widgets:PaintText(self.footnote, "note")
    self:SetFootnote(nil)
    return frame
end

function page:SetFootnote(preset)
    self.footnote:SetText(addon.Presets:BasisText(preset) .. " Changed values are gold. Press Enter or click "
        .. "elsewhere to save a value.")
end

function page:Update()
    if not self.frame then return end
    self:SetFootnote(addon.Presets:Get())
    local widgets = addon.PanelWidgets
    local spec = specID()
    self.empty:SetShown(not spec)
    self.scroll:SetShown(spec ~= nil)
    if not spec then return end
    self.title:SetText("Weights for " .. widgets:SpecText(spec))
    local keys = addon.Weights:Keys(spec)
    for index, key in ipairs(keys) do
        local row = self:Row(index)
        local custom = addon.Weights:IsCustom(spec, key)
        row.key = key
        row.label:SetText(addon.Weights:Name(key))
        row.label:SetTextColor(widgets:Color(custom and "checked" or "unchecked"))
        row.default:SetText(addon.Weights:Format(addon.Weights:Default(spec, key)))
        if not row.box:HasFocus() then
            row.box:SetText(addon.Weights:Format(addon.Weights:Effective(spec, key)))
            row.box:SetCursorPosition(0)
        end
        row.box:SetTextColor(widgets:Color(custom and "checked" or "titleAccent"))
        row.reset:SetShown(custom)
        row:Show()
    end
    for index = #keys + 1, #self.rows do self.rows[index]:Hide() end
    local last = self.rows[#keys]
    local below = last or self.header
    self.error:ClearAllPoints()
    self.error:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 4, -8)
    self.error:SetPoint("RIGHT", self.content, "RIGHT", -8, 0)
    self.footnote:ClearAllPoints()
    self.footnote:SetPoint("TOPLEFT", self.error, "BOTTOMLEFT", 0, -4)
    self.footnote:SetPoint("RIGHT", self.content, "RIGHT", -8, 0)
    self.resetAll:SetEnabled(addon.Weights:HasCustom(spec))
    local height = (self.warning:GetHeight() or 56) + 44 + 26 + 22 + #keys * ROW_HEIGHT + 70
    self.content:SetHeight(height)
    local needed = height > (self.scroll:GetHeight() or 0) + 1
    if self.scroll.ScrollBar then self.scroll.ScrollBar:SetShown(needed) end
    if not needed then self.scroll:SetVerticalScroll(0) end
end
