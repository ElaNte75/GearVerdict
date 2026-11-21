local _, addon = ...
addon.name = "GearVerdict"
addon.version = "0.1.0"
addon.modules = {}

function addon:Print(message)
    print("|cff66ccffGearVerdict:|r " .. message)
end

function addon:IsPublic(value)
    return not issecretvalue or not issecretvalue(value)
end

function addon:Refresh()
    if self.BagArrows then self.BagArrows:Refresh() end
    if self.BagnonAdapter then self.BagnonAdapter:Refresh() end
    if self.QuestArrows then self.QuestArrows:Refresh() end
    if self.DungeonJournalArrows then self.DungeonJournalArrows:Refresh() end
end

-- Optional local test tools (a separate addon that is not part of GearVerdict). Without them these do nothing.
local function none() end
addon.Diagnostics = { Log = none, Initialize = none, Inspect = none }
addon.Perf = { Count = none, Note = none, Initialize = none, Command = none }
if GearVerdictDebugTools then GearVerdictDebugTools.Attach(addon) end
