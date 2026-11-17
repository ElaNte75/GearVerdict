local _, addon = ...
local icon = {}
addon.MinimapIcon = icon

-- Minimap launcher made with LibDataBroker + LibDBIcon (embedded in Libs/), the standard way, so the
-- button works on its own around the minimap and is also collected by button bags such as the
-- Leatrix Plus "Combine addon buttons" bag. Saved in GearVerdictDB.options.minimap (LibDBIcon format).

local NAME = "GearVerdict"
icon.texture = "Interface/AddOns/GearVerdict/Media/icon"

function icon:DB()
    local options = GearVerdictDB.options
    if type(options.minimap) ~= "table" then options.minimap = { hide = false } end
    return options.minimap
end

function icon:Tooltip(tooltip)
    tooltip:AddLine("GearVerdict", 0.4, 0.8, 1)
    if addon.Presets:Get() then
        tooltip:AddLine(addon.PanelWidgets:SpecText(addon.Presets:SelectedSpecID()))
    else
        tooltip:AddLine("No specialization chosen", 1, 0.5, 0.25)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine("Click: open or close the Control Panel", 0.8, 0.8, 0.8)
    tooltip:AddLine("Drag: move it around the minimap", 0.8, 0.8, 0.8)
end

function icon:Initialize()
    if self.dbicon then return end
    local stub = _G.LibStub
    local broker = stub and stub("LibDataBroker-1.1", true)
    local dbicon = stub and stub("LibDBIcon-1.0", true)
    if not broker or not dbicon then return end
    local object = broker:NewDataObject(NAME, {
        type = "launcher",
        label = "GearVerdict",
        text = "GearVerdict",
        icon = self.texture,
        OnClick = function(_, button)
            if button == "LeftButton" or button == "RightButton" then SlashCmdList.GEARVERDICT("") end
        end,
        OnTooltipShow = function(tooltip) self:Tooltip(tooltip) end,
    })
    if not object then return end
    self.dbicon = dbicon
    dbicon:Register(NAME, object, self:DB())
end

function icon:IsShown()
    return not self:DB().hide
end

function icon:SetShown(shown)
    self:DB().hide = not shown
    if not self.dbicon then return end
    if shown then self.dbicon:Show(NAME) else self.dbicon:Hide(NAME) end
end
