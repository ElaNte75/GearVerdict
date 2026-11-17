local _, addon = ...
local frame = CreateFrame("Frame")
local initialized = false
local queued = false

local function refresh(cause)
    if not initialized then return end
    if queued then addon.Perf:Count("refreshMerged"); return end
    queued = true
    C_Timer.After(0.2, function()
        queued = false
        addon.Perf:Note(cause or "other")
        addon:Refresh()
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
frame:SetScript("OnEvent", function(_, event, arg, success)
    if event == "ADDON_LOADED" and arg == addon.name then
        GearVerdictDB = GearVerdictDB or {}
        GearVerdictDB.weightsBySpec = GearVerdictDB.weightsBySpec or {}
        GearVerdictDB.cache = GearVerdictDB.cache or {}
        GearVerdictDB.capsEnabled = GearVerdictDB.capsEnabled or false
        GearVerdictDB.options = GearVerdictDB.options or {}
        GearVerdictDB.specChoices = GearVerdictDB.specChoices or {}
        addon.Weights:Migrate()
        if addon.TalentAdvisor then addon.TalentAdvisor:Migrate() end
        if GearVerdictDB.build ~= select(2, GetBuildInfo()) then GearVerdictDB.cache = {} end
        GearVerdictDB.build = select(2, GetBuildInfo())
        addon.Diagnostics:Initialize()
        addon.Perf:Initialize()
        if not C_Item or not C_Item.GetItemStats then
            addon:Print("Required item API unavailable; prototype disabled.")
            return
        end
        initialized = true
        addon.MinimapIcon:Initialize()
        if addon.TalentHint then addon.TalentHint:Initialize() end
        if IsLoggedIn() then addon.Tooltips:Initialize() end
        if OpenAllBags then hooksecurefunc("OpenAllBags", function() refresh("OpenAllBags") end) end
        if ToggleBackpack then hooksecurefunc("ToggleBackpack", function() refresh("ToggleBackpack") end) end
        C_Timer.NewTicker(1, function()
            if initialized and not InCombatLockdown() then addon.Perf:Note("ticker"); addon:Refresh() end
        end)
    elseif initialized then
        if event == "ITEM_DATA_LOAD_RESULT" then addon.ItemData:Loaded(arg, success) end
        if event == "PLAYER_LOGIN" then
            addon.Tooltips:Initialize()
            if GearVerdictDB.confirmEnhancement and select(2, UnitClass("player")) == "SHAMAN"
                and not addon.Presets:ManualSpecID() then
                addon.Presets:SetManualSpecID(263)
            end
            GearVerdictDB.confirmEnhancement = nil
            addon:Print("Loaded. /gv opens the control panel.")
        end
        if event ~= "ITEM_DATA_LOAD_RESULT" and addon.ControlPanel then addon.ControlPanel:Update() end
        refresh(event)
    end
end)

SLASH_GEARVERDICT1 = "/gv"
SLASH_GEARVERDICT2 = "/gearverdict"
SlashCmdList.GEARVERDICT = function(message)
    if not initialized then addon:Print("Prototype is not initialized."); return end
    local command = strtrim(message or ""):lower()
    if addon.DebugCommand and addon.DebugCommand(command) then return end
    if command == "caps" then
        if UnitLevel("player") ~= 60 then
            addon:Print("Experimental caps are only available at level 60.")
            return
        end
        GearVerdictDB.capsEnabled = not GearVerdictDB.capsEnabled
        addon:Print("Experimental gear-only caps: " .. (GearVerdictDB.capsEnabled and "ON" or "OFF"))
        addon:Refresh()
    elseif command == "talent" or command:match("^talent%s+%d+$") then
        if not addon.TalentHint then
            addon:Print("Talent hint files are not loaded yet. Please exit and restart the game.")
            return
        end
        addon.TalentHint:Preview(tonumber(command:match("%d+")))
    else
        if not addon.ControlPanel or not addon.PanelWeightsPage or not addon.WeightTransferDialog then
            addon:Print("New window files are not loaded yet. Please exit and restart the game.")
            return
        end
        local ok, err = pcall(addon.ControlPanel.Toggle, addon.ControlPanel)
        if not ok then
            addon:Print("Window error: " .. tostring(err))
            addon.Diagnostics:Log("window-error", tostring(err))
        end
    end
end
