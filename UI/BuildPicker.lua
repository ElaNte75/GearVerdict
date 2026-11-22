local _, addon = ...
local picker = {}
addon.BuildPicker = picker

-- The build choice of the Specialization page (replaces the three specialization tick boxes, see Data/TalentBuilds.lua),
-- in two steps (2026-11-21): first the specialization (gear is always judged with its weights), then a variant of it
-- (Classic = the leveling guide, or one of the guide page's builds). Below: the Defense/Offense meter (Protection
-- builds), the weapon setup and a short description. (The talent-points bar was removed at the user's request.)
-- Talent placement (Place talents / Auto) lives on the Leveling page.

local ROW_HEIGHT = 22
local LABEL_WIDTH = 78
local BUTTON_GAP = 10
-- The two drop-downs share the page width equally (user request 2026-11-21).
local function buttonWidth()
    local width = addon.ControlPanel and addon.ControlPanel.contentWidth or 452
    return math.floor((width - 8 - BUTTON_GAP) / 2)
end

-- Defense <-> Offense meter (user request 2026-11-21) for every build except healers: the share of the build's talent
-- points in the defensive tree against the others, from the guide's own points (Builds:DefenseShare). Pure damage
-- builds show "Offense 100%". Its row is always reserved, so nothing below moves; for healers it stays empty.
function picker:BuildMeter(frame, anchor, gap)
    local widgets = addon.PanelWidgets
    -- Exactly as wide as the two drop-downs; the labels keep a fixed width, so "Offense 100%" stays inside.
    local total = 2 * buttonWidth() + BUTTON_GAP
    self.barWidth = total - 2 * (LABEL_WIDTH + 6)
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(total, 14)
    row:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    local left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    left:SetPoint("LEFT", 0, 0)
    left:SetWidth(LABEL_WIDTH)
    left:SetJustifyH("LEFT")
    widgets:PaintText(left, "note")
    local bar = CreateFrame("Frame", nil, row)
    bar:SetSize(self.barWidth, 6)
    bar:SetPoint("LEFT", row, "LEFT", LABEL_WIDTH + 6, 0)
    local track = bar:CreateTexture(nil, "ARTWORK")
    track:SetAllPoints()
    widgets:Fill(track, "sectionLine")
    -- The marker slides between Defense (left) and Offense (right), in the class color like the talent bar.
    local marker = bar:CreateTexture(nil, "ARTWORK", nil, 2)
    marker:SetSize(8, 14)
    local right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    right:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    right:SetWidth(LABEL_WIDTH)
    right:SetJustifyH("RIGHT")
    widgets:PaintText(right, "note")
    self.meter = { row = row, left = left, right = right, bar = bar, marker = marker }
    widgets:Tooltip(row, "Defense and offense", function()
        local share, points, total, tree = addon.Builds:DefenseShare(addon.Builds:Chosen())
        if not share then return nil end
        if not tree or points == 0 then
            return "A pure damage build: none of its " .. total .. " talent points are in a defensive tree."
        end
        return points .. " of " .. total .. " talent points are in the " .. tree .. " tree (defense); the other "
            .. (total - points) .. " are in the damage trees (offense). Counted from the guide's build."
    end)
    return row
end

-- "3 / 31 / 17" (the variant's talent points per tree) next to the "Variant" title, with the tree names
-- in its tooltip.
function picker:CreatePoints(frame, title)
    local widgets = addon.PanelWidgets
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetPoint("LEFT", title, "RIGHT", 10, 0)
    holder:SetSize(90, 14)
    self.points = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.points:SetPoint("LEFT", 0, 0)
    widgets:PaintText(self.points, "note")
    widgets:Tooltip(holder, "Talent points", function()
        local build = addon.Builds:Chosen()
        return build and build.trees and addon.Builds:TreesText(build) or nil
    end)
end

function picker:ShowPoints(build)
    if not self.points then return end
    local trees = build and build.trees
    self.points:SetText(trees and (trees[1] .. " / " .. trees[2] .. " / " .. trees[3]) or "")
end

function picker:ShowMeter(build)
    local meter = self.meter
    local share = build and addon.Builds:DefenseShare(build)
    meter.left:SetShown(share ~= nil)
    meter.right:SetShown(share ~= nil)
    meter.bar:SetShown(share ~= nil)
    if not share then return end
    local defense = math.floor(share * 100 + 0.5)
    meter.left:SetText(("Defense %d%%"):format(defense))
    meter.right:SetText(("Offense %d%%"):format(100 - defense))
    local r, g, b = addon.PanelWidgets:ClassColor()
    meter.marker:SetColorTexture(r, g, b, 1)
    meter.marker:ClearAllPoints()
    meter.marker:SetPoint("CENTER", meter.bar, "LEFT", self.barWidth * (1 - share), 0)
end

function picker:ShowBuild(build)
    if not self.frame then return end
    self:ShowMeter(build)
    self:ShowPoints(build)
    if not build then
        self.weapons:SetText("")
        self.description:SetText("Choose a specialization above to get gear recommendations and talent hints.")
        return
    end
    -- Weapons: only what to hold, in plain words; the guide's details (speed, named weapons) go in the description.
    local setup, detail = addon.Builds:WeaponSetup(build)
    self.weapons:SetText("Weapons: " .. setup)
    local description = build.description or ""
    if detail then description = description .. " Weapon: " .. detail .. "." end
    local keys = addon.Builds:KeyNames(build, 5)
    if #keys > 0 then description = description .. " Key talents: " .. table.concat(keys, ", ") .. "." end
    if build.classic then
        description = description .. (description ~= "" and " " or "") .. "Talents follow the "
            .. (addon.TalentAdvisor:GuideName() or "chosen") .. " leveling guide."
    end
    self.description:SetText(description)
end

function picker:Select(id)
    addon.Builds:Choose(id)
    self:Changed()
end

function picker:SelectSpec(specID)
    addon.Builds:ChooseSpec(specID)
    self:Changed()
end

function picker:Changed()
    self.specPopup:Hide()
    self.variantPopup:Hide()
    if addon.PanelSpecPage then addon.PanelSpecPage:Update() end
    if addon.PanelLevelingPage then addon.PanelLevelingPage:Update() end
    addon:Refresh()
end

-- A drop-down list under `button`; rows are filled on every open (Fill), so the variant list follows the spec.
function picker:Popup(frame, button, width)
    local widgets = addon.PanelWidgets
    local popup = CreateFrame("Frame", nil, frame)
    popup:SetFrameStrata("DIALOG")
    popup:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    popup:EnableMouse(true)
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    widgets:Fill(bg, "contentBg")
    widgets:Border(popup, 0)
    popup.rows = {}
    -- entries: { text, onClick, build (shown in the details while the mouse is over the row) }
    function popup.Fill(_, entries)
        for index, entry in ipairs(entries) do
            local row = popup.rows[index]
            if not row then
                row = widgets:Button(popup, "", width - 6, function(self) self.entry.onClick() end)
                row:SetPoint("TOPLEFT", 3, -3 - (index - 1) * ROW_HEIGHT)
                row:SetHeight(ROW_HEIGHT - 1)
                row:HookScript("OnEnter", function(self)
                    if self.entry.build ~= nil then picker:ShowBuild(self.entry.build or nil) end
                end)
                row:HookScript("OnLeave", function() picker:ShowBuild(addon.Builds:Chosen()) end)
                popup.rows[index] = row
            end
            row.entry = entry
            row:SetText(entry.text)
            row:Show()
        end
        for index = #entries + 1, #popup.rows do popup.rows[index]:Hide() end
        popup:SetSize(width, ROW_HEIGHT * #entries + 6)
    end
    popup:Hide()
    return popup
end

function picker:OpenSpecs()
    local entries = {}
    for _, spec in ipairs(addon.Builds:Specs()) do
        local id = spec.id
        entries[#entries + 1] = { text = spec.name, onClick = function() self:SelectSpec(id) end }
    end
    entries[#entries + 1] = { text = "None (no recommendations)", onClick = function() self:SelectSpec(nil) end, build = false }
    self.variantPopup:Hide()
    self.specPopup:Fill(entries)
    self.specPopup:SetShown(not self.specPopup:IsShown())
end

function picker:OpenVariants()
    local spec = addon.Builds:SpecOf(addon.Builds:Chosen())
    if not spec then return end
    local entries = {}
    for _, build in ipairs(addon.Builds:ForSpec(spec)) do
        local id = build.id
        entries[#entries + 1] = { text = addon.Builds:VariantName(build), onClick = function() self:Select(id) end, build = build }
    end
    self.specPopup:Hide()
    self.variantPopup:Fill(entries)
    self.variantPopup:SetShown(not self.variantPopup:IsShown())
end

-- Creates the picker under `anchor`; returns the last region so the page can continue below it.
function picker:Create(frame, anchor, gap)
    local widgets = addon.PanelWidgets
    self.frame = frame
    self.specLabel = widgets:Note(frame, "Specialization", anchor, gap)
    local width = buttonWidth()
    self.specButton = widgets:Button(frame, "", width, function() self:OpenSpecs() end)
    self.specButton:SetPoint("TOPLEFT", self.specLabel, "BOTTOMLEFT", 0, -4)
    self.specButton:SetHeight(28)
    self.variantButton = widgets:Button(frame, "", width, function() self:OpenVariants() end)
    self.variantButton:SetPoint("LEFT", self.specButton, "RIGHT", BUTTON_GAP, 0)
    self.variantButton:SetHeight(28)
    self.variantLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.variantLabel:SetPoint("BOTTOMLEFT", self.variantButton, "TOPLEFT", 0, 4)
    self.variantLabel:SetText("Variant")
    widgets:PaintText(self.variantLabel, "note")
    self.specPopup = self:Popup(frame, self.specButton, width)
    self.variantPopup = self:Popup(frame, self.variantButton, width)
    widgets:Tooltip(self.specButton, "Specialization", "The role you play. Gear is always compared with the stat "
        .. "weights of this specialization.")
    widgets:Tooltip(self.variantButton, "Variant", "Which build of this specialization you follow: Classic (the "
        .. "leveling guide's talent order) or one of the guide page's builds. The level-up hint follows its talents.")
    local meter = self:BuildMeter(frame, self.specButton, 14)
    self.weapons = widgets:Note(frame, "", meter, 10)
    self.weapons:SetWordWrap(false)
    -- Normal size (the large font pushed everything below it down); gold when the guide names weapons.
    self.weapons:SetFontObject(GameFontNormal)
    widgets:PaintText(self.weapons, "title")
    self.description = widgets:Note(frame, "", self.weapons, 10)
    self.description:SetWordWrap(true)
    self.description:SetHeight(62)
    return self.description
end

function picker:Update()
    if not self.frame then return end
    local build = addon.Builds:Chosen()
    local spec = addon.Builds:SpecOf(build)
    self.specButton:SetText(spec and (addon.SpecDetection:SpecName(spec) or "?") or "Choose")
    self.variantButton:SetText(build and addon.Builds:VariantName(build) or "-")
    self.variantButton:SetEnabled(build ~= nil)
    self.specPopup:Hide()
    self.variantPopup:Hide()
    self:ShowBuild(build)
end
