local _, addon = ...
local priority = {}
addon.PanelStatPriority = priority

-- Stat priority block inside the Status section of the Specialization page: the stats of the active specialization, most
-- important first, each with a bar showing its importance compared with the first one. No numbers:
-- the weights themselves live on the Custom Weights page.

local ROW_HEIGHT = 12
local NAME_WIDTH = 100
local COLUMN_GAP = 16

-- Short names so a name and its bar fit in half the page.
priority.shortNames = {
    ITEM_MOD_HIT_RATING_SHORT = "Hit", ITEM_MOD_EXPERTISE_RATING_SHORT = "Expertise",
    ITEM_MOD_CRIT_RATING_SHORT = "Crit", ITEM_MOD_HASTE_RATING_SHORT = "Haste",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Ranged AP", ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "Armor Pen.",
    ITEM_MOD_SPELL_PENETRATION_SHORT = "Spell Pen.", ITEM_MOD_MANA_REGENERATION_SHORT = "Mana per 5",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "Defense", ITEM_MOD_DODGE_RATING_SHORT = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT = "Parry", ITEM_MOD_BLOCK_RATING_SHORT = "Block",
}

-- The stats the addon really uses (custom values included), zero weights left out, strongest first.
function priority:Entries(specID)
    local weights = addon.Weights
    local entries, top = {}, 0
    for _, key in ipairs(weights:Keys(specID)) do
        local value = weights:Effective(specID, key) or 0
        if value > 0 then
            entries[#entries + 1] = { key = key, name = priority.shortNames[key] or weights:Name(key), value = value, custom = weights:IsCustom(specID, key) }
            if value > top then top = value end
        end
    end
    -- Armor counts too (Engine/Scoring.lua ArmorWeight, from the game's armor formula; changes with level/health/armor).
    -- Its value is per point of Armor, so its bar is short: items carry many points of it.
    local armor = addon.Scoring and addon.Scoring:ArmorWeight() or 0
    if armor > 0 and specID == addon.Presets:SelectedSpecID() then
        entries[#entries + 1] = { key = "RESISTANCE0_NAME", name = "Armor (per pt)", value = armor }
        if armor > top then top = armor end
    end
    table.sort(entries, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.name < b.name
    end)
    for _, entry in ipairs(entries) do entry.share = entry.value / top end
    return entries
end

function priority:CapsText(preset)
    local caps = preset and preset.caps or {}
    local hit, expertise = caps.ITEM_MOD_HIT_RATING_SHORT, caps.ITEM_MOD_EXPERTISE_RATING_SHORT
    local parts = {}
    if hit and preset.caps == addon.Presets.caps.hybrid then
        parts[#parts + 1] = "Hit 8% (80 rating) for weapons, 16% (160) for spells"
    elseif hit then
        parts[#parts + 1] = string.format("Hit %g%% (%d rating)", hit.threshold / 10, hit.threshold)
    end
    if expertise then
        parts[#parts + 1] = string.format("Expertise %g%% (%d rating)", expertise.threshold / 10, expertise.threshold)
    end
    if #parts == 0 then return nil end
    return "Caps (counted only at level 60 with caps turned on): " .. table.concat(parts, ", ") .. "."
end

priority.basisShort = {
    simulated = "Provisional, from a simulation (MythicSim).",
    guide = "Provisional, from guide orders only.",
}

local function setFill(track)
    local width = track:GetWidth() or 0
    track.fill:SetWidth(math.max(1, width * (track.share or 0)))
end

local function createRow(self, index)
    local row = CreateFrame("Frame", nil, self.box)
    row:SetHeight(ROW_HEIGHT)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 0, 0)
    row.name:SetWidth(NAME_WIDTH)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.track = CreateFrame("Frame", nil, row)
    row.track:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
    row.track:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.track:SetHeight(8)
    local back = row.track:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    addon.PanelWidgets:Fill(back, "sectionLine")
    row.track.fill = row.track:CreateTexture(nil, "ARTWORK")
    row.track.fill:SetPoint("TOPLEFT")
    row.track.fill:SetPoint("BOTTOMLEFT")
    row.track:SetScript("OnSizeChanged", setFill)
    self.rows[index] = row
    return row
end

priority.helpText = "Below the active specialization: its stats, most important first. A longer bar means a "
    .. "more important stat. These are the weights GearVerdict uses for arrows and tooltips; names in gold were "
    .. "changed by you on the Custom Weights page. Your choice is saved for this character only."

function priority:Create(page, anchor)
    self.box = CreateFrame("Frame", nil, page)
    self.box:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    self.box:SetPoint("RIGHT", page, "RIGHT", -8, 0)
    self.box:SetHeight(ROW_HEIGHT)
    self.note = addon.PanelWidgets:Note(page, "", self.box, 10)
    self.rows = {}
end

function priority:Update()
    if not self.box then return end
    local preset = addon.Presets:Get()
    local shown = preset ~= nil
    for _, region in ipairs({ self.box, self.note }) do
        if shown then region:Show() else region:Hide() end
    end
    if not shown then return end
    local widgets = addon.PanelWidgets
    local entries = self:Entries(addon.Presets:SelectedSpecID())
    local perColumn = math.max(1, math.ceil(#entries / 2))
    local r, g, b = widgets:ClassColor()
    for index, entry in ipairs(entries) do
        local row = self.rows[index] or createRow(self, index)
        local column, place = math.floor((index - 1) / perColumn), (index - 1) % perColumn
        row:ClearAllPoints()
        row:SetPoint("TOP", self.box, "TOP", 0, -place * ROW_HEIGHT)
        if column == 0 then
            row:SetPoint("LEFT", self.box, "LEFT", 0, 0)
            row:SetPoint("RIGHT", self.box, "CENTER", -COLUMN_GAP / 2, 0)
        else
            row:SetPoint("LEFT", self.box, "CENTER", COLUMN_GAP / 2, 0)
            row:SetPoint("RIGHT", self.box, "RIGHT", 0, 0)
        end
        row.name:SetText(index .. ". " .. entry.name)
        row.name:SetTextColor(widgets:Color(entry.custom and "checked" or "unchecked"))
        row.track.fill:SetColorTexture(r, g, b, 1)
        row.track.share = entry.share
        setFill(row.track)
        row:Show()
    end
    for index = #entries + 1, #self.rows do self.rows[index]:Hide() end
    self.box:SetHeight(perColumn * ROW_HEIGHT)
    local caps = self:CapsText(preset)
    self.note:SetText(self.basisShort[preset.basis] .. (caps and (" " .. caps) or ""))
end
