local _, addon = ...
local adapter = { hookedGroups = setmetatable({}, { __mode = "k" }) }
addon.BagnonAdapter = adapter

function adapter:Refresh()
    self.lastButtonCount = 0
    local frames = Bagnon and Bagnon.Frames
    if not frames or not frames.Get then return end
    if not self.hookedFrames and hooksecurefunc then
        self.hookedFrames = true
        hooksecurefunc(frames, "Show", function() addon.Perf:Note("bagnon-show"); addon:Refresh() end)
    end
    for _, id in ipairs({ "inventory", "bank" }) do
        local frame = frames:Get(id)
        local group = frame and frame.ItemGroup
        if group and group.buttons then
            if not self.hookedGroups[group] and hooksecurefunc and group.Layout then
                self.hookedGroups[group] = true
                hooksecurefunc(group, "Layout", function() addon.Perf:Note("bagnon-layout"); addon:Refresh() end)
            end
            for _, button in pairs(group.buttons) do
                addon.UpgradeIndicators:Set(button, false)
                if frame:IsShown() and not frame:IsCached() and not button:IsCached() then
                    self.lastButtonCount = self.lastButtonCount + 1
                    addon.BagArrows:UpdateButton(button)
                end
            end
        end
    end
end
