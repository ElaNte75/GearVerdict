local _, addon = ...
local placer = {}
addon.TalentPlacer = placer

-- Places the next unspent talent points in the talent window, following the chosen build (or the leveling
-- guide of the chosen specialization). It only STAGES the points (C_Traits.PurchaseRank): it never commits or
-- applies them. The player checks the talent window and presses Apply themselves; Reset there undoes it.
-- Manual: the "Place talents" button of the Specialization page. Auto (option autoPlaceTalents, only while the
-- leveling helper is on): when a talent point arrives, place it and open the talent window.

placer.MIN_AUTO_INTERVAL = 3

local function options() return GearVerdictDB and GearVerdictDB.options or {} end

-- Steps of the chosen build (hybrid: its own order) or of the guide for the chosen specialization.
function placer:Steps()
    local build = addon.Builds and addon.Builds:Chosen()
    if build and build.order then return addon.Builds:Steps(build), build end
    local spec = addon.Presets and addon.Presets:SelectedSpecID()
    return spec and addon.TalentAdvisor:Steps(spec) or nil, build
end

-- Pure: the steps that would be placed now, in order, simulated on a copy of the read talents.
function placer:Plan(steps, level, read, limit)
    local copy = { bySpell = {}, ranks = {}, names = read.names }
    for key, value in pairs(read.bySpell) do copy.bySpell[key] = value end
    for key, value in pairs(read.ranks) do copy.ranks[key] = value end
    local plan = {}
    while #plan < limit do
        local step = addon.TalentAdvisor:Steer(steps, level, copy)
        if not step then break end
        plan[#plan + 1] = step
        if copy.bySpell[step.spellID] ~= nil then copy.bySpell[step.spellID] = step.rank end
        copy.ranks[step.talent:lower()] = step.rank
    end
    return plan
end

-- Result: { status, placed, step (the one that failed), text }.
-- status: "ok", "nobuild", "unreadable", "unsupported", "nopoints", "done", "failed".
function placer:Place()
    local result = { placed = 0 }
    local steps = self:Steps()
    if not steps then
        result.status, result.text = "nobuild", "Choose a build first."
        return result
    end
    local read = addon.TalentAdvisor:Read()
    if not read or not read.configID then
        result.status, result.text = "unreadable", "Your talents could not be read."
        return result
    end
    if not C_Traits or not C_Traits.PurchaseRank then
        result.status, result.text = "unsupported", "This client cannot place talents for you."
        return result
    end
    if (read.unspent or 0) <= 0 then
        result.status, result.text = "nopoints", "No unspent talent points."
        return result
    end
    local plan = self:Plan(steps, UnitLevel("player") or 0, read, read.unspent)
    if #plan == 0 then
        result.status, result.text = "done", "Everything the build wants up to your level is taken."
        return result
    end
    for _, step in ipairs(plan) do
        local node = read.nodes[step.spellID] or read.byName[step.talent:lower()]
        local ok, bought
        if node then ok, bought = pcall(C_Traits.PurchaseRank, read.configID, node.nodeID) end
        if not node or not ok or bought == false then
            result.status, result.step = "failed", step
            result.text = ("Placed %d, then stopped at %s (%d/%d)."):format(result.placed, step.talent, step.rank, step.max)
            return result
        end
        result.placed = result.placed + 1
    end
    result.status = "ok"
    result.text = ("Placed %d point%s. Check the talent window and press Apply."):format(result.placed,
        result.placed == 1 and "" or "s")
    return result
end

local windows = { "PlayerSpellsFrame", "ClassTalentFrame", "TalentFrame" }
local function windowShown()
    for _, name in ipairs(windows) do
        local frame = _G[name]
        if frame and frame.IsShown and frame:IsShown() then return true end
    end
    return false
end

-- Opens the talent window (the Y key), whichever name this client gives it. Returns true when it is open.
function placer:OpenWindow()
    if windowShown() then return true end
    for _, name in ipairs({ "Blizzard_PlayerSpells", "Blizzard_ClassTalentUI", "Blizzard_TalentUI" }) do
        local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
        if load then pcall(load, name) end
    end
    local attempts = {
        function() return PlayerSpellsUtil and PlayerSpellsUtil.OpenToClassTalentsTab and PlayerSpellsUtil.OpenToClassTalentsTab() end,
        function() return ToggleTalentFrame and ToggleTalentFrame() end,
        function() return ToggleClassTalentFrame and ToggleClassTalentFrame() end,
    }
    for _, attempt in ipairs(attempts) do
        if pcall(attempt) and windowShown() then return true end
    end
    return windowShown()
end

-- The button: place, then open the window when something was placed.
function placer:Run()
    local result = self:Place()
    if result.placed > 0 then result.opened = self:OpenWindow() end
    return result
end

function placer:AutoEnabled()
    return options().autoPlaceTalents and addon.TalentAdvisor:Enabled() and true or false
end

-- Auto: called when a talent point (or a level) arrives.
function placer:OnPointsChanged()
    if not self:AutoEnabled() or self.busy then return end
    if InCombatLockdown and InCombatLockdown() then
        self.waiting = true
        return
    end
    local now = GetTime()
    if self.last and now - self.last < self.MIN_AUTO_INTERVAL then return end
    self.busy = true
    C_Timer.After(0.5, function()
        self.busy, self.last = false, GetTime()
        if not self:AutoEnabled() then return end
        local result = self:Run()
        if result.placed > 0 and addon.BuildPicker and addon.BuildPicker.ShowPlaceResult then
            addon.BuildPicker:ShowPlaceResult(result)
        end
    end)
end

function placer:Initialize()
    if self.frame then return end
    local frame = CreateFrame("Frame")
    self.frame = frame
    frame:RegisterEvent("PLAYER_LEVEL_UP")
    pcall(frame.RegisterEvent, frame, "CHARACTER_POINTS_CHANGED")
    pcall(frame.RegisterEvent, frame, "PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if self.waiting then
                self.waiting = false
                self:OnPointsChanged()
            end
        else
            -- the new point can arrive a moment after the level
            C_Timer.After(1.2, function() self:OnPointsChanged() end)
        end
    end)
end
