local _, addon = ...
local weapons = { speeds = {} }
addon.WeaponData = weapons

-- Weapon helpers: which hand an item goes to, its speed, what setup two hands form, the DPS part of a
-- setup's value and the per-spec judgement (fit to the guide, then speed). Rules agreed 2026-11-20.
weapons.DPS = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"
weapons.FIT_MARGIN = 0.10
weapons.SPEED_MARGIN = 0.05
weapons.TIE = 0.01

local kinds = {
    INVTYPE_2HWEAPON = "twohand", INVTYPE_WEAPON = "one", INVTYPE_WEAPONMAINHAND = "main",
    INVTYPE_WEAPONOFFHAND = "offweapon", INVTYPE_SHIELD = "offitem", INVTYPE_HOLDABLE = "offitem",
    INVTYPE_RANGED = "ranged", INVTYPE_RANGEDRIGHT = "ranged", INVTYPE_THROWN = "ranged",
}

function weapons:Kind(item)
    return item and kinds[item.equipLoc]
end

function weapons:Handles(equipLoc)
    return kinds[equipLoc] ~= nil
end

function weapons:CanDualWield()
    return type(CanDualWield) == "function" and CanDualWield() and true or false
end

-- Main-hand capable / off-hand capable kinds.
function weapons:IsMain(kind) return kind == "one" or kind == "main" end
function weapons:IsOff(kind, dual)
    return kind == "offitem" or ((kind == "offweapon" or kind == "one") and dual)
end

-- Weapon speed from the item tooltip ("Speed 3.60"); nil when it cannot be read.
function weapons:Speed(link, item)
    local key = item and item.key or link
    if self.speeds[key] ~= nil then return self.speeds[key] or nil end
    local found = false
    local info = C_TooltipInfo and C_TooltipInfo.GetHyperlink and C_TooltipInfo.GetHyperlink(link)
    local label = SPEED or "Speed"
    for _, line in ipairs(info and info.lines or {}) do
        for _, text in ipairs({ line.rightText, line.leftText }) do
            if type(text) == "string" and addon:IsPublic(text) and text:find(label, 1, true) then
                local number = text:match("(%d+[%.,]%d+)")
                if number then found = tonumber((number:gsub(",", "."))) or false end
            end
            if found then break end
        end
        if found then break end
    end
    self.speeds[key] = found
    addon.Diagnostics:Log("weapon-speed", tostring(key) .. " speed=" .. tostring(found))
    return found or nil
end

-- Setup formed by a main-hand and an off-hand item (either may be nil).
function weapons:Setup(main, off)
    if main and self:Kind(main) == "twohand" then return "twohand" end
    if off and self:Kind(off) == "offitem" then return "shield" end
    if off then return "dual" end
    return "single"
end

function weapons:Fits(guide, main, off)
    if guide.types then
        for _, item in ipairs({ main, off }) do
            if item and item.classID == 2 and not guide.types[item.subclassID] then return false end
        end
    end
    if not guide.setups then return true end
    local setup = self:Setup(main, off)
    if setup == "single" then return guide.setups.dual or guide.setups.shield or false end
    return guide.setups[setup] == true
end

-- Speed in the points (agreed 2026-11-21): a weapon off the spec's preferred speed keeps less of its DPS
-- value, SPEED_STEP (1%) per 0.1 s away, at most SPEED_MAX. Unreadable speed = no change.
weapons.SPEED_STEP = 0.01
weapons.SPEED_MAX = 0.5

function weapons:SpeedFactor(item, slow, fast)
    if not item or item.classID ~= 2 or not item.speed then return 1 end
    local gap = 0
    if slow then gap = math.max(0, slow - item.speed) end
    if fast then gap = math.max(0, item.speed - fast) end
    return 1 - math.min(self.SPEED_MAX, gap * 10 * self.SPEED_STEP)
end

-- DPS part of a setup's value (stats are scored by Scoring).
function weapons:DpsValue(guide, main, off, ranged)
    local value = 0
    if ranged then
        return (guide.ranged or 0) * (ranged.stats[self.DPS] or 0) * self:SpeedFactor(ranged, guide.rangedSlow)
    end
    local weight = guide.melee or 0
    if main then
        value = value + weight * (main.stats[self.DPS] or 0) * self:SpeedFactor(main, guide.mainSlow, guide.mainFast)
    end
    if off then
        value = value + weight * addon.WeaponGuide.OFFHAND * (off.stats[self.DPS] or 0)
            * self:SpeedFactor(off, nil, guide.offFast)
    end
    return value
end

local function within(speed, slow, fast)
    if not speed then return nil end
    if slow then return speed >= slow end
    if fast then return speed <= fast end
    return nil
end

-- true = every preferred speed met, false = one missed, nil = no preference or unreadable.
function weapons:SpeedFit(guide, main, off, ranged)
    if ranged then return within(ranged.speed, guide.rangedSlow) end
    local result
    for _, pair in ipairs({ { main, guide.mainSlow, guide.mainFast }, { off, nil, guide.offFast } }) do
        local item = pair[1]
        if item and item.classID == 2 then
            local ok = within(item.speed, pair[2], pair[3])
            if ok == false then return false end
            if ok then result = true end
        end
    end
    return result
end

-- new / old: { main =, off = } or { ranged = }; delta: value change; oldScore: value of the old setup.
-- Returns upgrade (bool) and, when the guide decided it, a reason { kind = "fits", setup = } / { kind = "speed", speed = }.
function weapons:Judge(guide, new, old, delta, oldScore)
    local plain = delta > self.TIE
    local base = math.max(oldScore or 0, 0)
    if not new.ranged then
        local fitNew, fitOld = self:Fits(guide, new.main, new.off), self:Fits(guide, old.main, old.off)
        if fitNew and not fitOld then
            if plain then return true end
            if delta >= -base * self.FIT_MARGIN then
                return true, { kind = "fits", setup = self:Setup(new.main, new.off) }
            end
            return false
        elseif fitOld and not fitNew then
            return delta > math.max(base * self.FIT_MARGIN, self.TIE)
        end
    end
    local speedNew, speedOld = self:SpeedFit(guide, new.main, new.off, new.ranged),
        self:SpeedFit(guide, old.main, old.off, old.ranged)
    if speedNew == true and speedOld == false then
        if plain then return true end
        local item = new.ranged or new.main
        if delta >= -base * self.SPEED_MARGIN then return true, { kind = "speed", speed = item and item.speed } end
        return false
    elseif speedNew == false and speedOld == true then
        return delta > math.max(base * self.SPEED_MARGIN, self.TIE)
    end
    return plain
end

function weapons:ReasonText(reason, specName)
    if not reason then return nil end
    if reason.kind == "fits" then
        return "Fits " .. (specName or "spec") .. ": " .. (addon.WeaponGuide.setupNames[reason.setup] or reason.setup)
    end
    if reason.kind == "speed" and reason.speed then return string.format("Preferred speed: %.2f", reason.speed) end
    return nil
end
