local _, addon = ...
local dialog = {}
addon.WeightTransferDialog = dialog

-- Small window over the Control Panel. Import: paste a Pawn string, see what would change, Apply.
-- Export: the weights of the chosen specialization as a Pawn string, selected and ready for Ctrl+C.

local WIDTH, HEIGHT = 470, 350

function dialog:Build()
    local widgets = addon.PanelWidgets
    local panel = addon.ControlPanel.frame
    local frame = CreateFrame("Frame", "GearVerdictWeightTransfer", panel)
    self.frame = frame
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", panel, "CENTER", 0, 0)
    frame:SetFrameLevel(panel:GetFrameLevel() + 40)
    frame:EnableMouse(true)
    frame:Hide()
    widgets:Background(frame, "frameBg")
    widgets:Border(frame)
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(36)
    widgets:Background(header, "headerBg")
    self.title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title:SetPoint("LEFT", 16, 0)
    widgets:PaintText(self.title, "title")

    self.help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.help:SetPoint("TOPLEFT", 16, -46)
    self.help:SetPoint("RIGHT", -16, 0)
    self.help:SetJustifyH("LEFT")
    widgets:PaintText(self.help, "note")

    local box = CreateFrame("Frame", nil, frame)
    box:SetPoint("TOPLEFT", 16, -78)
    box:SetPoint("RIGHT", -16, 0)
    box:SetHeight(84)
    local boxBg = box:CreateTexture(nil, "BACKGROUND", nil, 1)
    boxBg:SetAllPoints()
    boxBg:SetColorTexture(0, 0, 0, 0.8)
    local boxEdge = box:CreateTexture(nil, "BACKGROUND", nil, -1) -- drawn under the dark inside, shows only as a 1px frame
    boxEdge:SetPoint("TOPLEFT", -1, 1)
    boxEdge:SetPoint("BOTTOMRIGHT", 1, -1)
    boxEdge:SetColorTexture(0.42, 0.35, 0.18, 0.9)
    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -26, 6)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(0)
    edit:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    edit:SetWidth(WIDTH - 32 - 32)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(_, userInput)
        if userInput and self.mode == "import" then self:Check() end
    end)
    scroll:SetScrollChild(edit)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() edit:SetFocus() end)
    self.edit = edit

    self.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.summary:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
    self.summary:SetPoint("RIGHT", -16, 0)
    self.summary:SetHeight(140)
    self.summary:SetJustifyH("LEFT")
    self.summary:SetJustifyV("TOP")

    self.close = widgets:Button(frame, "Cancel", 84, function() self:Hide() end)
    self.close:SetPoint("BOTTOMRIGHT", -16, 14)
    self.apply = widgets:Button(frame, "Apply", 84, function() self:Apply() end)
    self.apply:SetPoint("RIGHT", self.close, "LEFT", -6, 0)
end

dialog.guide = "|cffffd100How to get a weight string|r\n"
    .. "- Many sites, simulators and addons can export stat weights as a \"Pawn string\". Look for an Export or Pawn button.\n"
    .. "- In the Pawn addon (on any character or game version): open Pawn, choose a scale and press Export.\n"
    .. "- Copy the whole text, from ( to ), and paste it in the box above.\n"
    .. "It looks like:  ( Pawn: v1: \"Name\": Strength=1.00, Agility=0.80, ... )\n"
    .. "|cffff7f40Weights made for retail WoW (for example Raidbots) may not fit Forever.|r"

local function list(keys)
    local names = {}
    for _, key in ipairs(keys) do names[#names + 1] = addon.Weights:Name(key) end
    return table.concat(names, ", ")
end

function dialog:Check()
    local result, problem = addon.WeightString:Parse(self.edit:GetText(), self.specID)
    self.result = result
    self.apply:SetEnabled(result ~= nil)
    if not result then
        local empty = self.edit:GetText():gsub("%s", "") == ""
        self.summary:SetText(empty and self.guide or ("|cffff7f40" .. problem .. "|r"))
        return
    end
    local changed, zero, lines = {}, {}, {}
    for _, change in ipairs(addon.WeightString:Changes(self.specID, result)) do
        if change.missing and change.old ~= 0 then
            zero[#zero + 1] = change.key
        elseif math.abs((change.old or 0) - change.new) > 0.0005 then
            changed[#changed + 1] = addon.Weights:Name(change.key) .. " " .. addon.Weights:Format(change.old)
                .. " > |cffffd100" .. addon.Weights:Format(change.new) .. "|r"
        end
    end
    lines[#lines + 1] = "|cff4dff4dRead " .. result.count .. " stats from \"" .. result.name .. "\".|r"
    if result.classMismatch then
        lines[#lines + 1] = "|cffff7f40This string is for " .. result.className .. ", not your class.|r"
    end
    lines[#lines + 1] = #changed > 0 and ("Changes: " .. table.concat(changed, ", ")) or "No value changes."
    if #zero > 0 then lines[#lines + 1] = "|cffffd100Not in the string, will become 0:|r " .. list(zero) end
    if #result.ignored > 0 then
        lines[#lines + 1] = "|cff8c8c8cNot used by GearVerdict (ignored): " .. table.concat(result.ignored, ", ") .. "|r"
    end
    if #result.invalid > 0 then
        lines[#lines + 1] = "|cffff7f40Could not read: " .. table.concat(result.invalid, ", ") .. "|r"
    end
    self.summary:SetText(table.concat(lines, "\n"))
end

function dialog:Apply()
    if not self.result or not self.specID then return end
    addon.WeightString:Apply(self.specID, self.result)
    addon:Print("Imported weights for " .. addon.PanelWidgets:SpecText(self.specID) .. ".")
    self:Hide()
    addon.PanelWeightsPage:Changed()
end

function dialog:Open(mode, specID)
    if not specID then return end
    if not self.frame then self:Build() end
    self.mode, self.specID, self.result = mode, specID, nil
    local specName = addon.PanelWidgets:SpecText(specID)
    if mode == "import" then
        self.title:SetText("Import weights - " .. specName)
        self.help:SetText("Paste a Pawn weight string below (Ctrl+V). You will see what changes before anything is saved.")
        self.edit:SetText("")
        self.summary:SetText(self.guide)
        self.apply:Show()
        self.apply:SetEnabled(false)
        self.close:SetText("Cancel")
        self.frame:Show()
        self.edit:SetFocus()
    else
        self.title:SetText("Export weights - " .. specName)
        self.help:SetText("Press Ctrl+C to copy. Paste it into another addon or keep it as a backup.")
        self.edit:SetText(addon.WeightString:Export(specID))
        self.summary:SetText("")
        self.apply:Hide()
        self.close:SetText("Close")
        self.frame:Show()
        self.edit:SetFocus()
        self.edit:HighlightText()
    end
end

function dialog:Hide()
    if self.frame then
        self.edit:ClearFocus()
        self.frame:Hide()
    end
end
