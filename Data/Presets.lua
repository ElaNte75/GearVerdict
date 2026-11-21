local _, addon = ...
local presets = {}
addon.Presets = presets

-- One preset per specialization. The numbers live in Data\Presets\<Class>.lua (data only) and are
-- registered here. Every preset says where its numbers come from:
--   basis = "simulated": copied from a published simulation (MythicSim); still provisional.
--   basis = "guide": made from guide priority orders only; the spacing between stats is our guess.
presets.bySpec = {}

-- Caps at level 60 against a level 63 boss (MythicSim, client 1.60.1). 10 rating = 1%.
presets.caps = {
    melee = {
        ITEM_MOD_HIT_RATING_SHORT = { threshold = 80, after = 0 },
        ITEM_MOD_EXPERTISE_RATING_SHORT = { threshold = 65, after = 0 },
    },
    -- Hit counts for weapons and spells; the spell part keeps value until 16% (160 rating).
    hybrid = {
        ITEM_MOD_HIT_RATING_SHORT = { threshold = 160, after = 0 },
        ITEM_MOD_EXPERTISE_RATING_SHORT = { threshold = 65, after = 0 },
    },
    spell = {
        ITEM_MOD_HIT_RATING_SHORT = { threshold = 160, after = 0 },
    },
    none = {},
}

presets.basisText = {
    simulated = "Provisional weights from a simulation (MythicSim, level 60 raid boss), not a DPS promise.",
    guide = "Provisional weights from guide priority orders only, not simulated.",
}

function presets:Register(class, preset)
    local name = addon.SpecDetection:SpecName(preset.specID, class) or "?"
    preset.class = class
    preset.label = preset.label or (name .. " " .. class:sub(1, 1) .. class:sub(2):lower())
    preset.caps = preset.caps or self.caps.none
    self.bySpec[preset.specID] = preset
    return preset
end

function presets:BasisText(preset)
    return preset and self.basisText[preset.basis] or self.basisText.guide
end

-- Some servers (seen on Forever 2026-11-21) sometimes report an empty realm name. Then the choice is
-- found by character name alone, but only when exactly one saved character has that name.
local function characterKey()
    local name = UnitName("player") or "?"
    local realm = GetRealmName and GetRealmName()
    if realm and realm ~= "" then return name .. "-" .. realm end
    local found
    for key in pairs(GearVerdictDB.specChoices or {}) do
        if key:sub(1, #name + 1) == name .. "-" then
            if found then return name .. "-?" end
            found = key
        end
    end
    return found or (name .. "-?")
end

function presets:ManualSpecID()
    return GearVerdictDB.specChoices and GearVerdictDB.specChoices[characterKey()]
end

function presets:SetManualSpecID(id)
    GearVerdictDB.specChoices = GearVerdictDB.specChoices or {}
    GearVerdictDB.specChoices[characterKey()] = id
end

function presets:SelectedSpecID()
    return self:ManualSpecID()
end

function presets:IsSupported(id)
    local preset = self.bySpec[id]
    local _, class = UnitClass("player")
    return preset ~= nil and preset.class == class
end

function presets:Get()
    local id = self:SelectedSpecID()
    if not id then return nil, "Choose your specialization in /gv" end
    local preset = self.bySpec[id]
    if not preset then return nil, "Specialization not supported yet" end
    local _, class = UnitClass("player")
    if preset.class ~= class then return nil, "Choose your specialization in /gv" end
    return preset
end

function presets:Weight(key)
    if not self:Get() then return nil end
    return addon.Weights:Effective(self:SelectedSpecID(), key)
end
