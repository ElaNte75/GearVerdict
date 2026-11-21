local _, addon = ...
local journal = { rows = setmetatable({}, { __mode = "k" }) }
addon.DungeonJournalArrows = journal

-- Upgrade arrows on the item rows of the separate DungeonJournal addon (ForeverDungeonJournal).
-- That addon is not changed: every item row (boss loot, crafted items, quest rewards in the journal)
-- passes through its FDJ.UpdateFavouriteIndicator(row, itemID), which we hook to learn the rows.
-- The row keeps its item in row.item[1] (item ID) and its picture in row.icon.
-- Options: GearVerdictDB.options.dungeonJournalArrows (nil/true = on, false = off) and
-- dungeonJournalLevelsAhead (0-10, nil = 5): items up to that many levels above the player get a gold
-- "goal" arrow. Without the DungeonJournal addon everything here stays off.
journal.DEFAULT_LEVELS_AHEAD, journal.MAX_LEVELS_AHEAD = 5, 10

function journal:Available()
    local namespace = _G.ForeverDungeonJournal_NS
    return type(namespace) == "table" and type(namespace.UpdateFavouriteIndicator) == "function"
end

function journal:Enabled()
    local options = GearVerdictDB and GearVerdictDB.options
    return self:Available() and (not options or options.dungeonJournalArrows ~= false)
end

function journal:LevelsAhead()
    local options = GearVerdictDB and GearVerdictDB.options
    local value = tonumber(options and options.dungeonJournalLevelsAhead) or self.DEFAULT_LEVELS_AHEAD
    return math.max(0, math.min(self.MAX_LEVELS_AHEAD, math.floor(value + 0.5)))
end

-- True for an item row of the journal (its tooltip then also shows goals).
function journal:IsRow(frame)
    return frame ~= nil and self.rows[frame] == true and self:Enabled()
end

local function itemID(row)
    local item = row.item
    local id = type(item) == "table" and tonumber(item[1])
    return id and id > 0 and id or nil
end

function journal:UpdateRow(row)
    if not row then return end
    row.gearVerdictAnchor = row.icon or row.gearVerdictAnchor
    local id = itemID(row)
    if not id or not self:Enabled() or not row.IsVisible or not row:IsVisible() then
        addon.UpgradeIndicators:Set(row, false)
        return
    end
    local result = addon.Comparison:Evaluate("item:" .. id, self:LevelsAhead())
    addon.UpgradeIndicators:Set(row, addon.Comparison:IsUpgrade(result), result and result.goal)
end

function journal:Hook()
    if self.hooked or not hooksecurefunc or not self:Available() then return end
    self.hooked = true
    hooksecurefunc(_G.ForeverDungeonJournal_NS, "UpdateFavouriteIndicator", function(row)
        if type(row) ~= "table" then return end
        self.rows[row] = true
        self:UpdateRow(row)
    end)
end

-- Called with every GearVerdict refresh (also the one-second ticker), so items whose data
-- arrives a moment later get their arrow then.
function journal:Refresh()
    self:Hook()
    for row in pairs(self.rows) do self:UpdateRow(row) end
end
