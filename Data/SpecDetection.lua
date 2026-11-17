local _, addon = ...
local detection = {}
addon.SpecDetection = detection

-- Forever has no specializations, so every class gets our own list (in talent tree order).
-- The ids follow the retail specialization ids so saved choices stay stable; Druid has two Feral entries.
detection.classSpecs = {
    WARRIOR = { { id = 71, name = "Arms" }, { id = 72, name = "Fury" }, { id = 73, name = "Protection" } },
    PALADIN = { { id = 65, name = "Holy" }, { id = 66, name = "Protection" }, { id = 70, name = "Retribution" } },
    HUNTER = { { id = 253, name = "Beast Mastery" }, { id = 254, name = "Marksmanship" }, { id = 255, name = "Survival" } },
    ROGUE = { { id = 259, name = "Assassination" }, { id = 260, name = "Combat" }, { id = 261, name = "Subtlety" } },
    PRIEST = { { id = 256, name = "Discipline" }, { id = 257, name = "Holy" }, { id = 258, name = "Shadow" } },
    SHAMAN = { { id = 262, name = "Elemental" }, { id = 263, name = "Enhancement" }, { id = 264, name = "Restoration" } },
    MAGE = { { id = 62, name = "Arcane" }, { id = 63, name = "Fire" }, { id = 64, name = "Frost" } },
    WARLOCK = { { id = 265, name = "Affliction" }, { id = 266, name = "Demonology" }, { id = 267, name = "Destruction" } },
    DRUID = { { id = 102, name = "Balance" }, { id = 103, name = "Feral Cat" }, { id = 104, name = "Feral Bear" },
        { id = 105, name = "Restoration" } },
}

function detection:ClassSpecs(class)
    if not class then class = select(2, UnitClass("player")) end
    return self.classSpecs[class] or {}
end

function detection:SpecName(id, class)
    for _, spec in ipairs(self:ClassSpecs(class)) do
        if spec.id == id then return spec.name end
    end
end
