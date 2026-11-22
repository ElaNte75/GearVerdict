local _, addon = ...
local data = { pending = {}, observed = {} }
addon.ItemData = data

function data:BaseLink(link)
    if type(link) ~= "string" or not addon:IsPublic(link) then return nil end
    local payload = link:match("item:([%d:%-]+)")
    if not payload then return nil end
    local fields = { strsplit(":", payload) }
    for index = 2, 6 do fields[index] = "0" end
    return "item:" .. table.concat(fields, ":")
end

function data:Get(link)
    if not addon:IsPublic(link) then return nil, "Restricted item data" end
    local key = self:BaseLink(link)
    if not key then return nil, "Unknown item" end
    local name, loadedLink, quality, level, required, kind, subtype, stack, equipLoc, icon, price, classID, subclassID = C_Item.GetItemInfo(key)
    if not name then
        local id = tonumber(key:match("item:(%d+)"))
        if id and (not self.pending[id] or time() - self.pending[id] > 30) then
            self.pending[id] = time()
            C_Item.RequestLoadItemDataByID(id)
        end
        return nil, "Item data unavailable"
    end
    if classID ~= 2 and classID ~= 4 then return nil, "Not equipment" end
    local stats = C_Item.GetItemStats(key)
    if type(stats) ~= "table" or not next(stats) then return nil, "No readable base stats" end
    local clean = {}
    for stat, value in pairs(stats) do
        if not addon:IsPublic(value) then return nil, "Restricted stats" end
        if type(value) == "number" then clean[stat] = value end
    end
    local normalized, reason = addon.StatNormalization:Apply(clean)
    if not normalized then return nil, reason end
    clean = normalized
    local item = { key = key, name = name, stats = clean, equipLoc = equipLoc,
        classID = classID, subclassID = subclassID, required = required, quality = quality }
    GearVerdictDB.cache[key] = { stats = clean, equipLoc = equipLoc, seen = time() }
    if not self.observed[key] then
        self.observed[key] = true
        addon.Diagnostics:Log("item", key .. " " .. name)
        for stat, value in pairs(clean) do addon.Diagnostics:Log("base", stat .. "=" .. value) end
    end
    return item
end

function data:Loaded(id, success)
    if success then self.pending[id] = nil end
end
