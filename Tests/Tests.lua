local addon = {}
local where = { MinimapIcon = "UI", BagArrows = "Display", BagnonAdapter = "Display", Bootstrap = "Core", Comparison = "Engine", ControlPanel = "UI", Core = "Core", Eligibility = "Engine", ItemData = "Engine", PanelInterfacePage = "UI", PanelFactsPage = "UI", PanelOptionsPage = "UI", PanelSpecPage = "UI", PanelStatPriority = "UI", PanelWeightsPage = "UI", PanelWidgets = "UI", Presets = "Data", QuestArrows = "Display", RingPlacement = "Display", Scoring = "Engine", SpecDetection = "Data", StatNormalization = "Engine", Tooltips = "Display", UpgradeIndicators = "Display", WeightString = "Data", WeightTransferDialog = "UI", Weights = "Data", TalentOrders = "Data", TalentOrdersWowhead = "Data", PanelLevelingPage = "UI", TalentAdvisor = "Engine", TalentHint = "Display", Warrior = "Data/Presets", Paladin = "Data/Presets", Hunter = "Data/Presets", Rogue = "Data/Presets", Priest = "Data/Presets", Shaman = "Data/Presets", Mage = "Data/Presets", Warlock = "Data/Presets", Druid = "Data/Presets" }
local function path(name) return where[name] .. "/" .. name .. ".lua" end
local files = { "Bootstrap", "SpecDetection", "Presets", "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid", "Weights", "WeightString", "TalentOrders", "TalentOrdersWowhead", "TalentAdvisor", "TalentHint", "StatNormalization", "ItemData", "Scoring", "Eligibility", "Comparison", "RingPlacement", "Tooltips", "UpgradeIndicators", "BagArrows", "BagnonAdapter", "QuestArrows", "PanelWidgets", "ControlPanel", "PanelStatPriority", "PanelSpecPage", "PanelOptionsPage", "PanelLevelingPage", "PanelWeightsPage", "PanelInterfacePage", "PanelFactsPage", "WeightTransferDialog", "MinimapIcon", "Core" }
for _, name in ipairs(files) do assert(loadfile(path(name))) end
for _, name in ipairs({ "Bootstrap", "SpecDetection", "Presets", "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid", "Weights", "WeightString", "TalentOrders", "TalentOrdersWowhead", "TalentAdvisor", "TalentHint", "StatNormalization", "ItemData", "Scoring", "Eligibility", "Comparison", "RingPlacement", "Tooltips", "UpgradeIndicators", "BagArrows", "BagnonAdapter", "QuestArrows", "PanelStatPriority" }) do
    assert(loadfile(path(name)))("GearVerdict", addon)
end
local tests = 0
-- Older checks below were written against the first Enhancement prototype numbers; keep them on a fixed
-- test copy so later data changes do not break engine tests. The real preset is checked at the end.
local realEnhancement = addon.Presets.bySpec[263]
addon.Presets.bySpec[263] = {
    specID = 263, class = "SHAMAN", label = "Enhancement Shaman", basis = "guide",
    weights = {
        ITEM_MOD_HIT_RATING_SHORT = 2, ITEM_MOD_EXPERTISE_RATING_SHORT = 1.8, ITEM_MOD_INTELLECT_SHORT = 1,
        ITEM_MOD_SPELL_POWER_SHORT = 0.85, ITEM_MOD_STRENGTH_SHORT = 0.7, ITEM_MOD_SPELL_PENETRATION_SHORT = 0.5,
        ITEM_MOD_HASTE_RATING_SHORT = 0.4, ITEM_MOD_CRIT_RATING_SHORT = 0.35, ITEM_MOD_AGILITY_SHORT = 0.3,
        ITEM_MOD_SPIRIT_SHORT = 0.1, ITEM_MOD_STAMINA_SHORT = 0.05, ITEM_MOD_ATTACK_POWER_SHORT = 0.3,
    },
    caps = {
        ITEM_MOD_HIT_RATING_SHORT = { threshold = 80, after = 0.5 },
        ITEM_MOD_EXPERTISE_RATING_SHORT = { threshold = 65, after = 0 },
    },
}
local function check(value, message)
    assert(value, message)
    tests = tests + 1
end
function UnitClass() return "Shaman", "SHAMAN" end
function UnitLevel() return 60 end
function UnitName() return "Tester" end
function GetRealmName() return "Realm" end
function time() return 100 end
local clock = 0
function GetTime() return clock end
function GetBuildInfo() return "1.60.1", "70938", "", 16001 end
function strsplit(separator, value)
    local result = {}
    for field in (value .. separator):gmatch("(.-)" .. separator) do result[#result + 1] = field end
    return table.unpack(result)
end
GearVerdictDB = { weights = { ITEM_MOD_STRENGTH_SHORT = 0.9 }, cache = {}, capsEnabled = false }
addon.Weights:Migrate()
check(GearVerdictDB.weights == nil and addon.Weights:Custom(263, "ITEM_MOD_STRENGTH_SHORT") == 0.9,
    "Old single weight set moves to Enhancement")
addon.Weights:ResetAll(263)
addon.Presets:SetManualSpecID(263)
check(addon.Diagnostics.Log and addon.Perf.Note and addon.DebugCommand == nil,
    "Without the separate test tools the addon runs with silent placeholders")
local base = addon.ItemData:BaseLink("|Hitem:123:99:1:2:3:4:-7:0:60:0:0:0:1:456|h[Test]|h")
check(base == "item:123:0:0:0:0:0:-7:0:60:0:0:0:1:456", "Strip only enchant and gems; retain variant")
local preset = addon.Presets:Get()
local hit = "ITEM_MOD_HIT_RATING_SHORT"
local intellect = "ITEM_MOD_INTELLECT_SHORT"
check(addon.Scoring:Value({ [intellect] = 10 }, preset) == 10, "Intellect score")
GearVerdictDB.capsEnabled = true
check(addon.Scoring:Value({ [hit] = 90 }, preset) == 165, "Hit above cap keeps reduced value")
local delta = addon.Scoring:Delta({ [hit] = 75, [intellect] = 20 },
    { stats = { [intellect] = 10 } }, { stats = { [hit] = 15 } }, preset)
check(math.abs(delta - 5) < 0.0001, "Cap crossing and lost intellect must both count")
addon.Weights:Set(263, intellect, 0)
check(addon.Scoring:Value({ [intellect] = 10 }, preset) == 0, "Zero custom weight")
addon.Weights:ResetAll(263)
local requested = 0
C_Item = {
    GetItemInfo = function() return nil end,
    RequestLoadItemDataByID = function() requested = requested + 1 end,
}
check(addon.ItemData:Get("item:777") == nil, "Unknown item has no score")
addon.ItemData:Get("item:777")
check(requested == 1, "Pending load deduplicated")
C_Item.GetItemInfo = function() return "Test", "item:123", 2, 10, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD", 0, 0, 4, 1 end
C_Item.IsEquippableItem = function() return true end
C_Item.GetItemUniquenessByID = function() return false end
C_TooltipInfo = { GetHyperlink = function()
    return { lines = { { leftText = "Test", leftColor = { r = 1, g = 1, b = 1 } } } }
end }
C_Item.GetItemStats = function() return { [intellect] = 5 } end
local item = addon.ItemData:Get("item:123:99:1:2:3:4")
check(item.stats[intellect] == 5, "Base stats read")
check(GearVerdictDB.cache[item.key].stats[intellect] == 5, "Base stats cached")
function GetInventoryItemLink(_, slot) if slot == 1 then return "item:123" end end
local equipped = addon.ItemData:Get("item:123")
local originalGet = addon.ItemData.Get
addon.ItemData.Get = function(_, link)
    if link == "item:123" then return equipped end
    return { key = link, stats = { [intellect] = 10 }, equipLoc = "INVTYPE_HEAD", classID = 4, subclassID = 1, required = 1 }
end
local result = addon.Comparison:Evaluate("item:456")
check(result and result.delta == 5, "Compare against equipped item")
check(addon.Comparison:Evaluate("item:123") == nil, "Equipped item is not an upgrade")
local normalClass = UnitClass
function UnitClass() return "Mage", "MAGE" end
check(addon.Presets:Get() == nil, "Another class never uses the Shaman spec choice")
UnitClass = normalClass
GearVerdictDB.capsEnabled = false
function GetInventoryItemLink(_, slot)
    if slot == 11 then return "ring-strong" end
    if slot == 12 then return "ring-weak" end
end
addon.ItemData.Get = function(_, link)
    local values = { ["ring-strong"] = 20, ["ring-weak"] = 5, ["ring-new"] = 10 }
    return { key = link, stats = { [intellect] = values[link] }, equipLoc = "INVTYPE_FINGER", classID = 4, subclassID = 0, required = 1 }
end
local ring = addon.Comparison:Evaluate("ring-new")
check(ring and ring.slot == 12 and ring.delta == 5, "Ring compares both slots and chooses weaker replacement")
check(#ring.comparisons == 2 and ring.comparisons[1].delta == -10 and ring.comparisons[2].delta == 5,
    "Both ring replacement results are retained, including non-upgrade")
check(ring.comparisons[2].percent == 100 and ring.comparisons[1].percent == -50,
    "Percentages use each replaced ring score, not character score")
check(addon.Comparison:Evaluate("ring-strong") == nil, "Equipped ring does not recommend itself")
local ringGet = addon.ItemData.Get
addon.ItemData.Get = function(self, link)
    local value = ringGet(self, link)
    if link == "ring-new" then value.stats[intellect] = 40 end
    return value
end
local bothRings = addon.Comparison:Evaluate("ring-new")
check(bothRings.comparisons[1].upgrade and bothRings.comparisons[2].upgrade,
    "Upgrade over both rings retains two independent upgrade lines")
GearVerdictDB.capsEnabled = true
local cappedRing = addon.Comparison:Evaluate("ring-new")
check(cappedRing.comparisons[1].percent == nil and cappedRing.comparisons[2].percent == nil,
    "Cap-aware comparisons do not show misleading per-item score percentages")
GearVerdictDB.capsEnabled = false
addon.ItemData.Get = originalGet
addon.ItemData:Loaded(777, false)
C_Item.GetItemInfo = function() return nil end
addon.ItemData:Get("item:777")
check(requested == 1, "Failed loads retain retry cooldown")
addon.Presets:SetManualSpecID(71)
check(addon.Presets:Get() == nil, "A spec of another class is rejected")
local originalEvaluate = addon.Comparison.Evaluate
local evaluations, lines = 0, {}
addon.Comparison.Evaluate = function()
    evaluations = evaluations + 1
    return nil, "Confirm Enhancement in /gv settings"
end
local tooltip = {
    GetItem = function() return "Test", "item:999" end,
    AddLine = function(_, text) lines[#lines + 1] = text end,
    AddDoubleLine = function(_, left, right) lines[#lines + 1] = left .. " | " .. right end,
}
local function hover(classID, equipLoc)
    addon.Tooltips.seen[tooltip] = nil
    C_Item.GetItemInfo = function()
        return "Test", "item:999", 1, 1, 1, "", "", 1, equipLoc, 0, 0, classID, 0
    end
    addon.Tooltips:Process(tooltip)
end
hover(0, "")
check(#lines == 0 and evaluations == 0, "Consumables must not show annotations or evaluate")
hover(12, "")
check(#lines == 0 and evaluations == 0, "Quest items must not show annotations or evaluate")
hover(4, "")
check(#lines == 0 and evaluations == 0, "Non-equippable armor-class items must stay hidden")
C_Item.GetItemInfo = function() return nil end
addon.Tooltips:Process(tooltip)
check(#lines == 0 and evaluations == 0, "Unknown equipment type must stay hidden")
hover(4, "INVTYPE_HEAD")
check(#lines == 0 and evaluations == 1, "Unavailable specialization stays silent")
addon.Tooltips:Process(tooltip)
check(#lines == 0 and evaluations == 1, "Repeated tooltip callbacks do not duplicate evaluation")
hover(2, "INVTYPE_2HWEAPON")
check(evaluations == 2, "Weapons retain unsupported-item guidance")
addon.Comparison.Evaluate = function()
    return { delta = 0, slot = 1, candidate = { stats = { RESISTANCE0_NAME = 33 } } }
end
addon.Tooltips.seen[tooltip] = nil
addon.Tooltips:Process(tooltip)
addon.Comparison.Evaluate = originalEvaluate
check(#lines == 0, "Zero-score equipment stays silent")
addon.Presets:SetManualSpecID(263)
local power, damage = "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"
local normalized = addon.StatNormalization:Apply({ [damage] = 6, ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18 })
check(normalized[power] == 6 and normalized[damage] == nil, "Legacy spell damage maps to spell power")
check(normalized.ITEM_MOD_SPELL_HEALING_DONE_SHORT == 18, "Healing stays separate")
check(addon.StatNormalization:Apply({ [damage] = 6, [power] = 6 })[power] == 6, "Equivalent aliases do not double count")
check(addon.StatNormalization:Apply({ [damage] = 6, [power] = 8 }) == nil, "Ambiguous spell stats receive no recommendation")
check(addon.Scoring:Value(normalized, preset) == 6 * 0.85, "Mapped spell damage uses existing weight only")
local skullScore = addon.Scoring:Value({ [intellect] = 3, ITEM_MOD_STAMINA_SHORT = 3 }, preset)
local sealScore = addon.Scoring:Value({ ITEM_MOD_STAMINA_SHORT = 8, ITEM_MOD_ATTACK_POWER_SHORT = 6 }, preset)
local fistScore = addon.Scoring:Value({ ITEM_MOD_STRENGTH_SHORT = 4, ITEM_MOD_AGILITY_SHORT = 4 }, preset)
check(math.abs(skullScore - sealScore - 0.95) < 0.0001, "Screenshot Skull Ring is +0.95 over Seal of Sylvanas")
check(math.abs(skullScore - fistScore + 0.85) < 0.0001, "Screenshot Skull Ring is -0.85 versus Band of the Fist")
C_Item.GetItemStats = function() return { [damage] = 6 } end
check(addon.ItemData:Get("item:901").stats[power] == 6, "Item reads apply normalization")
local eligible = { classID = 4, subclassID = 1, equipLoc = "INVTYPE_HEAD", required = 1 }
check(addon.Eligibility:Check("item:901", eligible), "Usable armor passes requirements")
eligible.required = 61
check(not addon.Eligibility:Check("item:901", eligible), "Higher level rejected")
eligible.required = 1
eligible.subclassID = 4
check(not addon.Eligibility:Check("item:901", eligible), "Plate rejected for Shaman")
eligible.subclassID = 3
local normalLevel = UnitLevel
function UnitLevel() return 25 end
check(not addon.Eligibility:Check("item:901", eligible), "Mail rejected below 40")
UnitLevel = normalLevel
eligible.subclassID = 1
C_Item.IsEquippableItem = function() return false end
check(not addon.Eligibility:Check("item:901", eligible), "Client equipping restrictions respected")
C_Item.IsEquippableItem = function() return true end
local normalTooltip = C_TooltipInfo.GetHyperlink
C_TooltipInfo.GetHyperlink = function()
    return { lines = { { rightText = "Requires another class", rightColor = { r = 1, g = 0.1, b = 0.1 } } } }
end
check(not addon.Eligibility:Check("item:901", eligible), "Red class/race/skill requirements rejected")
C_TooltipInfo.GetHyperlink = function() return nil end
check(not addon.Eligibility:Check("item:901", eligible), "Unloaded requirement data rejected")
C_TooltipInfo.GetHyperlink = normalTooltip
C_Item.GetItemUniquenessByID = function(link)
    if link == "ring-new" or link == "ring-strong" then return true, "Test category", 1, 77 end
    return false
end
check(not addon.Eligibility:CanReplace("ring-new", 12), "Cannot keep another item in same unique-equipped category")
check(addon.Eligibility:CanReplace("ring-new", 11), "May replace existing unique-equipped category")
C_Item.GetItemUniquenessByID = function() return nil end
check(not addon.Eligibility:CanReplace("ring-new", 11), "Unknown uniqueness rejected")
C_Item.GetItemUniquenessByID = function() return true end
local inventoryForUnique = GetInventoryItemLink
function GetInventoryItemLink(_, slot) if slot == 11 then return "item:901" end end
check(not addon.Eligibility:CanReplace("item:901", 12), "Uncategorized unique item cannot be duplicated")
check(addon.Eligibility:CanReplace("item:901", 11), "Uncategorized unique item can replace itself")
check(addon.Eligibility:CanReplace("item:902", 12), "Different uncategorized unique items do not conflict")
GetInventoryItemLink = inventoryForUnique
C_Item.GetItemUniquenessByID = nil
check(not addon.Eligibility:CanReplace("item:901", 11), "Missing uniqueness API fails safely")
C_Item.GetItemUniquenessByID = function() return false end
addon.Presets:SetManualSpecID(263)
local currentLink = "item:901"
C_Item.GetItemInfo = function(link)
    return "Test", link, 2, 10, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD", 0, 0, 4, 1
end
C_Item.GetItemStats = function(link)
    return { [intellect] = link:match("902") and 5 or 10 }
end
function GetInventoryItemLink(_, slot) if slot == 1 then return "item:902" end end
C_Container = { GetContainerItemLink = function() return currentLink end }
local texture = {
    SetSize = function() end, ClearAllPoints = function() end,
    SetPoint = function(self, point, _, _, x, y) self.point, self.x, self.y = point, x, y end,
    SetFrameLevel = function() end, EnableMouse = function() end,
    Show = function(self) self.visible = true end, Hide = function(self) self.visible = false end,
    IsShown = function(self) return self.visible end,
    CreateTexture = function() return {
        SetColorTexture = function() end, SetSize = function() end,
        SetPoint = function() end, SetRotation = function() end,
    } end,
}
function CreateFrame() return texture end
local button = {
    IsShown = function() return true end, GetBagID = function() return 0 end,
    GetID = function() return 1 end, GetFrameLevel = function() return 1 end,
}
tooltip.GetItem = function() return "Test", currentLink end
local function compareDisplays(expected, message)
    lines = {}
    addon.Tooltips.seen[tooltip] = nil
    addon.Tooltips:Process(tooltip)
    addon.BagArrows:UpdateButton(button, {})
    check((#lines > 0) == expected and (texture.visible == true) == expected, message)
end
compareDisplays(true, "Tooltip and bag both mark positive usable upgrade")
check(#lines == 4 and lines[2] == "GearVerdict" and lines[3] == "Enhancement Shaman", "Tooltip separates addon title and spec from item text")
check(lines[4]:find("^|cffffd100vs|r Test | %+") and lines[4]:find(" pts$"), "Tooltip row shows versus replaced item and points only")
C_Item.IsEquippableItem = function() return false end
compareDisplays(false, "Both hide unusable item and clear old arrow")
C_Item.IsEquippableItem = function() return true end
currentLink = "item:902"
compareDisplays(false, "Both hide equipped item")
currentLink = "item:903"
C_Item.GetItemStats = function() return { [intellect] = 5 } end
compareDisplays(false, "Both hide equal-score item")
C_Item.GetItemStats = function(link) return { [intellect] = link:match("902") and 5 or 2 } end
compareDisplays(false, "Both hide lower-score item")
C_Item.GetItemStats = function() return { [intellect] = 10 } end
C_TooltipInfo.GetHyperlink = function()
    return { lines = { { leftText = "Requires reputation", leftColor = { r = 1, g = 0, b = 0 } } } }
end
compareDisplays(false, "Both hide unmet requirements")
C_TooltipInfo.GetHyperlink = normalTooltip
C_Item.GetItemStats = function(link) return { [damage] = link:match("902") and 3 or 6 } end
compareDisplays(true, "Both compare legacy spell damage for candidate and equipped item")
C_Item.GetItemStats = function(link)
    if link:match("902") then return { [power] = 3 } end
    return { [damage] = 6, [power] = 8 }
end
compareDisplays(false, "Both reject ambiguous spell damage rather than guessing")
C_Item.GetItemStats = function() return { [intellect] = 10 } end
addon.Presets:SetManualSpecID(71)
compareDisplays(false, "Both hide wrong specialization")
addon.Presets:SetManualSpecID(263)
C_Item.GetItemInfo = function(link)
    return "Weapon", link, 2, 10, 1, "Weapon", "Staff", 1, "INVTYPE_2HWEAPON", 0, 0, 2, 10
end
compareDisplays(false, "Both hide unsupported weapon")
C_Item.GetItemInfo = function(link)
    return "Trinket", link, 2, 10, 1, "Armor", "Misc", 1, "INVTYPE_TRINKET", 0, 0, 4, 0
end
compareDisplays(false, "Both hide unsupported trinket")
C_Item.GetItemInfo = function(link)
    return "Hooded Cowl", link, 2, 10, 1, "Armor", "Cloth", 1, "INVTYPE_HEAD", 0, 0, 4, 1
end
C_Item.GetItemStats = function() return { RESISTANCE0_NAME = 33 } end
function GetInventoryItemLink() return nil end
compareDisplays(true, "Armor-only hood upgrades empty head slot in tooltip and bag")
check(lines[4] == "Upgrade", "Empty slot shows only Upgrade, not zero points or invented percent")
local empty = addon.Comparison:Evaluate(currentLink)
check(empty.empty and empty.delta == 0 and empty.comparisons[1].percent == nil, "Empty-slot upgrade does not invent a score")
C_Item.IsEquippableItem = function() return false end
compareDisplays(false, "Empty slot never bypasses usability checks")
C_Item.IsEquippableItem = function() return true end
addon.Comparison.Evaluate = function() return ring end
lines = {}
addon.Tooltips.seen[tooltip] = nil
addon.Tooltips:Process(tooltip)
check(#lines == 4 and lines[4]:find("vs|r ", 1, true) and lines[4]:find("+5.00 pts", 1, true),
    "Only the improved ring is listed; the stronger ring is omitted")
addon.Comparison.Evaluate = function() return bothRings end
lines = {}
addon.Tooltips.seen[tooltip] = nil
addon.Tooltips:Process(tooltip)
check(#lines == 5 and lines[4]:find("vs|r ", 1, true) and lines[5]:find("vs|r ", 1, true), "Upgrade over both rings shows two versus rows")
local addLine, specColor = tooltip.AddLine, nil
RAID_CLASS_COLORS = { SHAMAN = { r = 0, g = 0.44, b = 0.87 } }
tooltip.AddLine = function(self, text, r, g, b)
    if text == "Enhancement Shaman" then specColor = { r, g, b } end
    addLine(self, text)
end
lines = {}
addon.Tooltips.seen[tooltip] = nil
addon.Tooltips:Process(tooltip)
check(specColor and specColor[1] == 0 and specColor[2] == 0.44 and specColor[3] == 0.87, "Spec line uses class color")
tooltip.AddLine, RAID_CLASS_COLORS = addLine, nil
addon.Comparison.Evaluate = originalEvaluate
local timers, shows, callback, hooks = 0, 0, nil, {}
C_Timer = { After = function() timers = timers + 1 end }
tooltip.Show = function() shows = shows + 1 end
tooltip.HookScript = function(_, name, handler) hooks[name] = handler end
tooltip.NumLines = function() return #lines end
TooltipDataProcessor = { AddTooltipPostCall = function(_, handler) callback = handler end }
Enum = { TooltipDataType = { Item = 0 } }
addon.Tooltips:Initialize()
lines = { "Item", "Other addon" }
addon.Tooltips.seen[tooltip] = nil
callback(tooltip)
check(#lines == 6 and lines[4] == "GearVerdict", "Shared item-tooltip hook appends our section during native layout")
callback(tooltip)
check(#lines == 6 and timers == 0 and shows == 0, "Tooltip never schedules delayed writes, forces Show or duplicates rows")
hooks.OnTooltipCleared(tooltip)
lines = { "Quest reward" }
callback(tooltip)
check(#lines == 5, "Same item is annotated again after tooltip is cleared")
local customHooks = {}
local customTooltip = {
    GetItem = tooltip.GetItem, AddLine = tooltip.AddLine, AddDoubleLine = tooltip.AddDoubleLine,
    HookScript = function(_, name, handler) customHooks[name] = handler end,
}
lines = { "Custom shop or chat tooltip" }
callback(customTooltip)
check(#lines == 5 and customHooks.OnTooltipCleared and customHooks.OnHide,
    "Previously unknown tooltip frames receive source-independent annotation and lifecycle hooks")
customHooks.OnHide(customTooltip)
check(addon.Tooltips.seen[customTooltip] == nil, "Hidden custom tooltip cannot retain stale item state")
currentLink = "item:904"
ContainerFrameCombinedBags = {
    IsShown = function() return true end,
    EnumerateValidItems = function() return ipairs({ button }) end,
}
addon.BagArrows:Refresh()
check(addon.BagArrows.lastButtonCount == 1 and texture.visible, "Modern bag enumeration attaches independent indicator")
ContainerFrameCombinedBags = nil
local legacyButton = {
    IsShown = button.IsShown, GetFrameLevel = button.GetFrameLevel,
    GetID = button.GetID, GetName = function() return "ContainerFrame1Item1" end,
}
ContainerFrame1 = {
    IsShown = function() return true end, GetID = function() return 0 end,
    GetChildren = function() return legacyButton end,
}
addon.BagArrows:Refresh()
check(addon.BagArrows.lastButtonCount == 1 and addon.UpgradeIndicators.frames[legacyButton],
    "Legacy bag buttons without GetBagID are discovered")
ContainerFrame1 = nil
button.type = "reward"
QuestInfoFrame = { questLog = false, rewardsFrame = { RewardButtons = { button } } }
function GetQuestItemLink(kind, index) if kind == "reward" and index == 1 then return currentLink end end
addon.QuestArrows:Refresh()
check(texture.visible, "Quest rewards receive our independent arrow")
C_Item.IsEquippableItem = function() return false end
addon.QuestArrows:Refresh()
check(not texture.visible, "Quest reward arrow clears when unusable")
C_Item.IsEquippableItem = function() return true end
QuestInfoFrame = nil
local bagnonButton = {
    IsShown = button.IsShown, GetFrameLevel = button.GetFrameLevel, GetID = button.GetID,
    GetBag = function() return 0 end, IsCached = function() return false end,
}
local bagnonFrame = {
    IsShown = function() return true end, IsCached = function() return false end,
    ItemGroup = { buttons = { bagnonButton } },
}
Bagnon = { Frames = { Get = function(_, id) if id == "inventory" then return bagnonFrame end end } }
addon:Refresh()
check(addon.BagnonAdapter.lastButtonCount == 1 and texture.visible,
    "Full refresh updates Bagnon GetBag buttons without any mouse-over")
bagnonFrame.IsCached = function() return true end
addon:Refresh()
check(addon.BagnonAdapter.lastButtonCount == 0 and not texture.visible,
    "Cached Bagnon characters never receive current-player arrows")
bagnonFrame.IsCached = function() return false end
bagnonFrame.ItemGroup.Layout = function() end
Bagnon.Frames.Show = function() end
function hooksecurefunc(object, method, handler)
    local original = object[method]
    object[method] = function(...)
        original(...)
        handler(...)
    end
end
addon:Refresh()
C_Item.IsEquippableItem = function() return false end
bagnonFrame.ItemGroup:Layout()
check(not texture.visible, "Bagnon layout/filter changes automatically clear obsolete arrows")
C_Item.IsEquippableItem = function() return true end
Bagnon.Frames:Show()
check(texture.visible, "Opening Bagnon automatically updates arrows before any tooltip")
bagnonButton.IsCached = function() return true end
addon:Refresh()
check(not texture.visible, "Cached Bagnon button is excluded even inside a live frame")
Bagnon = nil
addon:Refresh()
check(addon.BagnonAdapter.lastButtonCount == 0, "Addon works normally when Bagnon is absent")
addon.Presets:SetManualSpecID(999)
local _, unsupported = addon.Presets:Get()
check(unsupported == "Specialization not supported yet", "Unsupported spec gives no recommendations")
addon.Presets:SetManualSpecID(nil)
local _, unchosen = addon.Presets:Get()
check(unchosen == "Choose your specialization in /gv", "No chosen spec asks for a choice")
addon.Presets:SetManualSpecID(263)
check(addon.Presets:Get() == addon.Presets.bySpec[263], "Chosen Enhancement gives recommendations")
GearVerdictDB.specChoices["Other-Realm"] = 262
check(addon.Presets:ManualSpecID() == 263, "Spec choice is stored per character")
check(#addon.SpecDetection:ClassSpecs() == 3 and addon.SpecDetection:SpecName(264) == "Restoration",
    "Shaman offers its three talent trees")
local arrow = addon.UpgradeIndicators.frames[button]
arrow.fills[1].SetColorTexture = function(self, r, g, b) self.color = { r, g, b } end
GearVerdictDB.options = { arrowPosition = "TOPLEFT", arrowColor = { r = 1, g = 0.8, b = 0 } }
addon.UpgradeIndicators:Set(button, true)
check(arrow.point == "TOPLEFT" and arrow.x == -3 and arrow.y == 3, "Arrow moves to chosen top-left corner")
check(arrow.fills[1].color[1] == 1 and arrow.fills[1].color[2] == 0.8, "Arrow uses chosen color")
GearVerdictDB.options = {}
addon.UpgradeIndicators:Set(button, true)
check(arrow.point == "TOPRIGHT" and arrow.x == 3 and arrow.fills[1].color[2] == 0.72, "Defaults restore top-right dark green arrow")
addon.Comparison.Evaluate = function() return ring end
GearVerdictDB.options.valueMode = "percent"
lines = {}
addon.Tooltips.seen[tooltip] = nil
addon.Tooltips:Process(tooltip)
check(lines[4] and lines[4]:find("+100.0%", 1, true), "Percent option shows percent in tooltip")
GearVerdictDB.options = {}
addon.Comparison.Evaluate = originalEvaluate
local equipped, equips, delayed = { [11] = "item:501", [12] = "item:502" }, {}, {}
GetInventoryItemLink = function(_, slot) return equipped[slot] end
C_Timer = { After = function(_, callback) delayed[#delayed + 1] = callback end }
function InCombatLockdown() return false end
function EquipItemByName(link, slot) equips[#equips + 1] = link .. ">" .. slot end
local function runDelayed()
    while #delayed > 0 do table.remove(delayed, 1)() end
end
local rings = addon.RingPlacement
rings:Remember("item:777", 12)
equipped[11] = "item:777"
rings:EquipmentChanged(11)
runDelayed()
check(equips[1] == "item:501>11" and equips[2] == "item:777>12",
    "Ring equipped into wrong slot is moved to the compared slot, keeping the better ring")
equips = {}
rings:Remember("item:777", 11)
rings:EquipmentChanged(11)
runDelayed()
check(#equips == 0 and rings.pending == nil, "Ring already in compared slot is left alone")
equipped[11] = "item:501"
rings:Remember("item:777", 12)
clock = 100
equipped[11] = "item:777"
rings:EquipmentChanged(11)
check(#delayed == 0, "Old hover does not move rings")
clock = 0
rings:Remember("item:777", 12)
function InCombatLockdown() return true end
rings:EquipmentChanged(11)
check(#delayed == 0, "No ring moves during combat")
function InCombatLockdown() return false end
equipped[12] = nil
rings:Remember("item:777", 11)
check(rings.pending == nil, "Empty other ring slot needs no correction")

-- Per-spec weights
local W = addon.Weights
local realElemental = addon.Presets.bySpec[262]
addon.Presets.bySpec[262] = { weights = { [intellect] = 2 }, label = "Elemental Test" }
check(W:Set(263, intellect, 1.5) and W:Effective(263, intellect) == 1.5, "Custom weight stored for Enhancement")
check(W:Effective(262, intellect) == 2, "Other specialization keeps its own weights")
check(W:Set(263, intellect, 1) and not W:IsCustom(263, intellect) and not W:HasCustom(263), "Value equal to default is not stored")
check(not W:Set(263, intellect, -1) and not W:Set(263, intellect, 2000) and not W:Set(263, intellect, nil), "Invalid values rejected")
check(not W:Set(263, "ITEM_MOD_UNKNOWN", 1), "Stats outside the preset rejected")
W:Set(263, intellect, 1.23456)
check(W:Custom(263, intellect) == 1.235 and W:Format(1.235) == "1.235" and W:Format(2) == "2.00", "Rounding and display")
W:Reset(263, intellect)
check(not W:HasCustom(263), "Single reset removes the custom value")
local keys = W:Keys(263)
check(keys[1] == hit and keys[#keys] == "ITEM_MOD_STAMINA_SHORT", "Stats listed most important first")
addon.Presets.bySpec[262] = realElemental
-- Pawn strings
local WS = addon.WeightString
local parsed = WS:Parse('( Pawn: v1: "Test Enh": Class=Shaman, Spec=Enhancement, Intellect=1.2, HitRating=2.5, SpellDamage=0.7, SpellPower=0.9, Dps=3.1, Agility=abc )', 263)
check(parsed and parsed.count == 3 and parsed.values[intellect] == 1.2 and parsed.values[hit] == 2.5, "Pawn string read")
check(parsed.values.ITEM_MOD_SPELL_POWER_SHORT == 0.9, "SpellPower preferred over SpellDamage")
check(#parsed.ignored == 1 and parsed.ignored[1] == "Dps" and #parsed.invalid == 1, "Unused and unreadable stats reported")
check(not parsed.classMismatch, "Same class gives no warning")
local alias = WS:Parse('( Pawn: v1: "A": SpellDamage=0.7 )', 263)
check(alias.values.ITEM_MOD_SPELL_POWER_SHORT == 0.7, "SpellDamage alone counts as spell power")
check(WS:Parse('( Pawn: v1: "W": Class=Warrior, Strength=1 )', 263).classMismatch, "Other class warned")
local none, why = WS:Parse("hello", 263)
check(none == nil and why:find("not a Pawn"), "Non-Pawn text refused")
check(WS:Parse('( Pawn: v2: "X": Strength=1 )', 263) == nil, "Unknown version refused")
check(WS:Parse('( Pawn: v1: "X": Dps=1 )', 263) == nil, "String without usable stats refused")
check(WS:Parse('( Pawn: v1: "X": Strength=1 )', 999) == nil, "Unsupported spec gets nothing")
WS:Apply(263, parsed)
check(W:Effective(263, intellect) == 1.2 and W:Effective(263, "ITEM_MOD_STAMINA_SHORT") == 0, "Apply sets values; missing stats become 0")
local exported = WS:Export(263)
check(exported:find('^%( Pawn: v1: "GearVerdict Enhancement": Class=Shaman, Spec=Enhancement,') and exported:find("Intellect=1.2")
    and not exported:find("Stamina="), "Export writes Pawn string without zero stats")
local again = WS:Parse(exported, 263)
local same = true
for _, key in ipairs(W:Keys(263)) do
    if math.abs((again.values[key] or 0) - W:Effective(263, key)) > 0.0005 then same = false end
end
check(same, "Exported string imports back to the same weights")
W:ResetAll(263)
check(not W:HasCustom(263) and W:Effective(263, intellect) == 1, "Reset all restores defaults")

-- Real presets for every class
addon.Presets.bySpec[263] = realEnhancement
local P, D, E = addon.Presets, addon.SpecDetection, addon.Eligibility
local specCount, allValid = 0, true
for class, specs in pairs(D.classSpecs) do
    for _, spec in ipairs(specs) do
        specCount = specCount + 1
        local preset = P.bySpec[spec.id]
        local ok = preset and preset.class == class and preset.specID == spec.id and P.basisText[preset.basis]
            and type(preset.source) == "string" and preset.source ~= "" and type(preset.label) == "string"
            and type(preset.caps) == "table" and next(preset.weights) ~= nil
        if ok then
            for key, value in pairs(preset.weights) do
                if not W.names[key] or not WS.exportNames[key] or type(value) ~= "number" or value < 0 then ok = false end
            end
        end
        if not ok then allValid = false; print("Bad preset: " .. class .. " " .. spec.name) end
    end
end
check(specCount == 28 and allValid, "All 28 specs of the nine classes have a complete, labeled preset")
check(P.bySpec[103].label == "Feral Cat Druid" and P.bySpec[253].label == "Beast Mastery Hunter"
    and D:SpecName(104, "DRUID") == "Feral Bear", "Preset labels use spec and class names")
check(P.bySpec[263].basis == "simulated" and P.bySpec[263].weights.ITEM_MOD_EXPERTISE_RATING_SHORT == 4.06
    and W:Keys(263)[1] == "ITEM_MOD_EXPERTISE_RATING_SHORT", "Enhancement uses the MythicSim numbers")
check(P.bySpec[257].basis == "guide" and P:BasisText(P.bySpec[257]) ~= P:BasisText(P.bySpec[263]),
    "Guide-only presets are labeled differently from simulated ones")
check(P.bySpec[64].caps.ITEM_MOD_HIT_RATING_SHORT.threshold == 160 and P.bySpec[71].caps.ITEM_MOD_HIT_RATING_SHORT.threshold == 80,
    "Spell hit cap 160 for casters, melee hit cap 80 for melee")
function UnitClass() return "Priest", "PRIEST" end
check(not P:IsSupported(263) and P:IsSupported(257) and #D:ClassSpecs() == 3, "Spec list and support follow the player class")
P:SetManualSpecID(257)
check(P:Get() == P.bySpec[257], "Holy Priest gets its own preset")
check(addon.Scoring:Value({ ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18, [power] = 6 }, P:Get()) == 21,
    "Healing items score healing plus half weight spell power")
local heal = WS:Parse('( Pawn: v1: "H": Class=Priest, Healing=1.1, Mp5=0.4, Ap=0.3 )', 257)
check(heal and heal.values.ITEM_MOD_SPELL_HEALING_DONE_SHORT == 1.1 and heal.values.ITEM_MOD_MANA_REGENERATION_SHORT == 0.4
    and heal.ignored[1] == "Ap", "Pawn strings read Healing and Mp5; stats unused by the spec are ignored")
check(WS:Export(257):find("Healing=1", 1, true) and WS:Export(257):find("Mp5=0.5", 1, true), "Export writes new stat names")
local armor = { classID = 4, subclassID = 2, equipLoc = "INVTYPE_CHEST", required = 1 }
check(not E:Check("item:901", armor), "Leather rejected for a cloth class")
armor.subclassID = 1
check(E:Check("item:901", armor), "Cloth accepted for a cloth class")
function UnitClass() return "Warrior", "WARRIOR" end
function UnitLevel() return 39 end
armor.subclassID = 3
check(E:Check("item:901", armor), "Warrior wears mail before 40")
armor.subclassID = 4
check(not E:Check("item:901", armor), "Warrior plate waits for level 40")
function UnitLevel() return 40 end
check(E:Check("item:901", armor), "Warrior plate from level 40")
function UnitClass() return "Druid", "DRUID" end
armor.subclassID = 3
check(not E:Check("item:901", armor), "Druid never wears mail")
function UnitClass() return "Hunter", "HUNTER" end
check(E:Check("item:901", armor), "Hunter mail from level 40")
armor.subclassID = 6
check(not E:Check("item:901", armor), "Shields stay unsupported")
-- Stat priority bars on the Specialization page
function UnitClass() return "Shaman", "SHAMAN" end
P:SetManualSpecID(263)
local SP = addon.PanelStatPriority
local bars = SP:Entries(263)
check(#bars == 10 and bars[1].name == "Expertise" and bars[1].share == 1 and bars[#bars].name == "Armor Pen."
    and math.abs(bars[2].share - 2.2 / 4.06) < 0.0001, "Priority bars: strongest first, length relative to the first")
W:Set(263, "ITEM_MOD_AGILITY_SHORT", 5)
W:Set(263, "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT", 0)
bars = SP:Entries(263)
check(bars[1].name == "Agility" and bars[1].custom and #bars == 9, "Priority bars follow custom weights and hide zero stats")
W:ResetAll(263)
check(SP:CapsText(P.bySpec[263]):find("16%% %(160%) for spells") and SP:CapsText(P.bySpec[71]) == "Caps: Hit 8% (80 rating), Expertise 6.5% (65 rating)."
    and SP:CapsText(P.bySpec[257]) == nil, "Caps line fits the spec")
-- Talent hint on level-up (data, steering, display)
local TA, TH = addon.TalentAdvisor, addon.TalentHint
local guides = addon.TalentGuides
for _, guide in ipairs({ "wowhead", "icyveins" }) do
    local specCount = 0
    for _, list in pairs(addon.SpecDetection.classSpecs) do
        for _, spec in ipairs(list) do
            specCount = specCount + 1
            local steps = TA:Steps(spec.id, guide)
            check(steps and #steps == 51, guide .. " guide has 51 points for spec " .. spec.id)
            local ranks, lastLevel, ids = {}, 9, {}
            for _, step in ipairs(steps) do
                check(step.level == lastLevel + 1, "Guide levels continuous for spec " .. spec.id)
                lastLevel = step.level
                check(step.rank == (ranks[step.talent] or 0) + 1 and step.rank <= step.max,
                    "Guide ranks go up by one and never exceed the maximum: " .. guide .. " " .. spec.id .. " " .. step.talent)
                check(type(step.spellID) == "number" and step.spellID > 0 and (ids[step.talent] == nil or ids[step.talent] == step.spellID),
                    "Every guide talent has one spell id: " .. guide .. " " .. spec.id .. " " .. step.talent)
                ranks[step.talent], ids[step.talent] = step.rank, step.spellID
            end
            check(lastLevel == 60, "Guide ends at level 60 for spec " .. spec.id)
        end
    end
    check(specCount == 28, "All 28 specs have a " .. guide .. " guide")
end
check(guides.icyveins[103] == guides.icyveins[104] and guides.wowhead[103] ~= guides.wowhead[104],
    "Icy Veins: Feral Cat and Bear share one guide; Wowhead has one each")
local fury = TA:Steps(72, "icyveins")
check(fury[19].talent == "Dual Wield Specialization" and fury[19].level == 28 and fury[19].rank == 4 and fury[19].spellID == 23584
    and fury[19].max == 5 and TA:TreeName("beast-mastery") == "Beast Mastery", "Fury level 28 step transcribed correctly")
local enh = TA:Steps(263, "wowhead")
check(enh[20].talent == "Flurry" and enh[20].level == 29 and enh[20].rank == 5 and enh[20].spellID == 16256,
    "Wowhead Enhancement: level 29 = Flurry 5/5")

-- Settings: default guide, master switch, migration of the old Options checkbox
GearVerdictDB.options = GearVerdictDB.options or {}
check(TA:GuideKey() == "icyveins" and TA:GuideName() == "Icy Veins", "Default guide is Icy Veins")
GearVerdictDB.options.levelingGuide = "nonsense"
check(TA:GuideKey() == "icyveins", "Unknown guide falls back to Icy Veins")
GearVerdictDB.options.talentHint = true
TA:Migrate()
check(GearVerdictDB.options.levelingEnabled == true and GearVerdictDB.options.talentHint == nil, "Old talent option moves to the master switch")
GearVerdictDB.options.talentHint, GearVerdictDB.options.levelingEnabled = false, nil
TA:Migrate()
check(GearVerdictDB.options.levelingEnabled == nil and GearVerdictDB.options.talentHint == nil, "Old option off: master switch stays off")

-- Mock of Forever's modern talent tree (C_ClassTalents / C_Traits). mockTree rows: { spell, name, rank }.
local mockTree, mockUnspent, spellNames = nil, nil, {}
C_ClassTalents = {
    GetActiveConfigID = function() return mockTree and 4355200 or nil end,
    HasUnspentTalentPoints = function() return (mockUnspent or 0) > 0 end,
}
C_Traits = {
    GetConfigInfo = function() return { treeIDs = { 1082 } } end,
    GetTreeNodes = function() local nodes = {} for index = 1, #mockTree do nodes[index] = index end return nodes end,
    GetNodeInfo = function(_, node)
        local row = mockTree[node]
        return { currentRank = row[3], maxRanks = 5, activeEntry = row.noActive and nil or { entryID = node * 10 },
            entryIDs = { node * 10 } }
    end,
    GetEntryInfo = function(_, entryID) return { definitionID = entryID + 1 } end,
    GetDefinitionInfo = function(definitionID) return { spellID = mockTree[(definitionID - 1) / 10][1] } end,
    GetTreeCurrencyInfo = function()
        if mockUnspent == nil then return {} end
        return { { quantity = mockUnspent, spent = 0, maxQuantity = 0 } }
    end,
}
C_Spell = { GetSpellName = function(spellID) return spellNames[spellID] end }
local furySpells = {}
for _, step in ipairs(fury) do furySpells[step.talent] = step.spellID end
local function talents(ranks, skip)
    local tree = {}
    local all = { "Cruelty", "Unbridled Wrath", "Furious Precision", "Enrage", "Dual Wield Specialization", "Death Wish",
        "Flurry", "Deflection" }
    for _, name in ipairs(all) do
        if name ~= skip then
            tree[#tree + 1] = { furySpells[name] or 12000 + #tree, name, ranks[name] or 0 }
            spellNames[tree[#tree][1]] = name
        end
    end
    tree[#tree + 1] = { 999001, "Unrelated Talent", ranks.Unrelated or 0 }
    spellNames[999001] = "Unrelated Talent"
    return tree
end
local function levelAs(level) UnitLevel = function() return level end end
function UnitClass() return "Warrior", "WARRIOR" end
P:SetManualSpecID(72)
GearVerdictDB.options.levelingEnabled = true
GearVerdictDB.options.levelingGuide = "icyveins"

-- On the guide path: levels 10-27 done (18 points), level 28 point unspent
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, ["Furious Precision"] = 3, Enrage = 2, ["Dual Wield Specialization"] = 3 })
mockUnspent = 1
local read = TA:Read()
check(read and read.talents == 9 and read.spent == 18 and read.unspent == 1 and read.bySpell[23584] == 3
    and read.ranks["dual wield specialization"] == 3, "Talent tree is read through C_Traits")
local r = TA:Suggest(28)
check(r.status == "ok" and r.mode == "talents" and r.step.talent == "Dual Wield Specialization" and r.step.rank == 4
    and not r.off and r.text == "Level 28: Dual Wield Specialization (4/5)", "On the path: next guide step")
-- Missed points: the player skipped Furious Precision; guide steps are filled first
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, Enrage = 2, ["Dual Wield Specialization"] = 5 })
r = TA:Suggest(28)
check(r.step.talent == "Furious Precision" and r.step.rank == 1 and r.step.level == 20, "Missed guide points are filled first")
-- A guide talent that is not in the tree is skipped
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, Enrage = 2, ["Dual Wield Specialization"] = 3 }, "Furious Precision")
r = TA:Suggest(28)
check(r.status == "ok" and r.step.talent == "Dual Wield Specialization" and r.step.rank == 4, "Guide talents missing from the tree are skipped")
-- Name as backup when the spell id differs
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, ["Furious Precision"] = 3, Enrage = 2, ["Dual Wield Specialization"] = 3 })
mockTree[5][1] = 777777
spellNames[777777] = "Dual Wield Specialization"
r = TA:Suggest(28)
check(r.mode == "talents" and r.step.talent == "Dual Wield Specialization" and r.step.rank == 4 and not r.off,
    "A talent with another spell id is still found by name")
-- activeEntry missing: the first entry is used
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, ["Furious Precision"] = 3, Enrage = 2, ["Dual Wield Specialization"] = 3 })
mockTree[1].noActive = true
check(TA:Read().bySpell[furySpells.Cruelty] == 5, "A node without an active entry is read from its first entry")
-- Off-path point (Unrelated Talent) is reported, hint keeps following the guide
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, ["Furious Precision"] = 3, Enrage = 2, Unrelated = 1, ["Dual Wield Specialization"] = 2 })
r = TA:Suggest(28)
check(r.off and r.step.talent == "Dual Wield Specialization" and r.step.rank == 3, "Off-path talents noticed, guide still followed")
check(TH:PreviewText(r) == r.text, "Preview shows the suggestion")
-- No unspent points: silent at level-up, preview still works and says so
mockUnspent = 0
r = TA:Suggest(28)
check(r.status == "nopoints" and r.text == nil, "No unspent points: no hint")
r = TA:Suggest(28, { preview = true })
check(r.status == "ok" and r.read.unspent == 0, "Preview works without points")
-- Unspent points from HasUnspentTalentPoints when the currency gives nothing
mockUnspent = nil
check(TA:Read().unspent == 0, "No currency info and no unspent points: 0")
-- Fallback: no talent config -> by level
mockUnspent = 1
mockTree = nil
r = TA:Suggest(28)
check(r.mode == "level" and r.step.talent == "Dual Wield Specialization" and r.step.level == 28, "Unreadable tree falls back to the level")
check(TH:PreviewText(r) == "Level 28: Dual Wield Specialization (4/5)", "Fallback text has the same form")
-- Fallback: API missing completely
local savedTraits = C_Traits
C_Traits = nil
mockTree = talents({})
r = TA:Suggest(30)
check(r.mode == "level" and r.step.talent == "Death Wish", "Missing talent functions fall back to the level")
C_Traits = savedTraits
-- Fallback: nothing in the tree matches the guide
mockTree = { { 999001, "Unrelated Talent", 1 }, { 999002, "Other", 0 } }
spellNames[999002] = "Other"
r = TA:Suggest(28)
check(r.mode == "level" and r.status == "ok", "A tree without any guide talent falls back to the level")
-- Limits and switches
mockTree = talents({})
check(TA:Suggest(61).status == "range" and TA:Suggest(9).status == "range", "Nothing above 60 or below 10")
check(TA:Suggest(60).status == "ok" and TA:Suggest(60).mode == "talents", "Level 60 is covered")
P:SetManualSpecID(nil)
check(TA:Suggest(28).status == "nospec", "No chosen spec: no hint")
P:SetManualSpecID(72)
GearVerdictDB.options.levelingEnabled = nil
check(TA:Suggest(28).status == "off" and TA:Suggest(28, { preview = true }).status == "ok", "Helper off: silent, preview still works")
GearVerdictDB.options.levelingEnabled = true
function UnitClass() return "Mage", "MAGE" end
check(TA:Suggest(28).status == "nospec", "A spec of another class gives no hint")
-- Wowhead guide: the user's Enhancement case (19 points like Wowhead's first 19, level 29 -> Flurry 5/5)
function UnitClass() return "Shaman", "SHAMAN" end
P:SetManualSpecID(263)
GearVerdictDB.options.levelingGuide = "wowhead"
mockTree = {}
local enhRanks = { ["Thundering Strikes"] = 5, ["Mental Dexterity"] = 3, ["Ancestral Knowledge"] = 3, ["Shamanistic Focus"] = 1,
    ["Elemental Weapons"] = 3, Flurry = 4 }
local seenEnh = {}
for _, step in ipairs(enh) do
    if not seenEnh[step.talent] then
        seenEnh[step.talent] = true
        mockTree[#mockTree + 1] = { step.spellID, step.talent, enhRanks[step.talent] or 0 }
        spellNames[step.spellID] = step.talent
    end
end
r = TA:Suggest(29)
check(r.status == "ok" and r.mode == "talents" and r.text == "Level 29: Flurry (5/5)" and not r.off,
    "Wowhead Enhancement: 19 points read, next is Flurry 5/5")
check(TA:Suggest(28).status == "done", "Level 28 with everything taken: no level-up hint")
r = TA:Suggest(28, { preview = true })
check(r.status == "ok" and r.ahead and TH:PreviewText(r) == "Level 29: Flurry (5/5)",
    "Preview at 28 with everything taken shows the next point (level 29)")
GearVerdictDB.options.levelingGuide = "icyveins"
function UnitClass() return "Warrior", "WARRIOR" end
P:SetManualSpecID(72)

-- Level-up flow: point arrives late
local shown, printed, delayedCalls, titles = {}, {}, {}, {}
TH.ShowBanner = function(_, text, title) shown[#shown + 1] = text; titles[#shown] = title or TH.TITLE end
addon.Print = function(_, text) printed[#printed + 1] = text end
C_Timer = { After = function(_, callback) delayedCalls[#delayedCalls + 1] = callback end }
mockTree = talents({ Cruelty = 5, ["Unbridled Wrath"] = 5, ["Furious Precision"] = 3, Enrage = 2, ["Dual Wield Specialization"] = 3 })
mockUnspent = 0
clock = 100
TH:OnLevelUp(28)
delayedCalls[1]()
check(#shown == 0 and TH.pending, "Level-up without the point yet: waits")
mockUnspent = 1
clock = 102
TH.frame = nil
TH:TryPending()
check(#shown == 1 and shown[1]:find("Dual Wield Specialization") and #printed == 0 and not TH.pending,
    "Point arrives late: one banner, nothing in chat")
check(titles[1] == "GearVerdict", "Level-up banner title is GearVerdict")
check(TH:ShowSeconds() == 20, "Message stays 20 seconds by default")
GearVerdictDB.options.levelingBannerSeconds = 45
check(TH:ShowSeconds() == 45, "Message time follows the slider")
GearVerdictDB.options.levelingBannerSeconds = 500
check(TH:ShowSeconds() == 60, "Message time never above 1 minute")
GearVerdictDB.options.levelingBannerSeconds = 2
check(TH:ShowSeconds() == 10, "Message time never below 10 seconds")
GearVerdictDB.options.levelingBannerSeconds = nil
TH:Preview(28)
check(titles[2] == "GearVerdict Preview" and shown[2] == "Level 28: Dual Wield Specialization (4/5)" and #printed == 0,
    "Preview banner title says Preview, nothing in chat")
GearVerdictDB.options.levelingEnabled = nil
TH:OnLevelUp(29)
check(not TH.pending, "Helper off: level-up does nothing")
GearVerdictDB.options.levelingGuide = nil
C_ClassTalents, C_Traits, C_Spell = nil, nil, nil
function UnitClass() return "Shaman", "SHAMAN" end
print("PASS: " .. tests .. " assertions; all addon files parse")
