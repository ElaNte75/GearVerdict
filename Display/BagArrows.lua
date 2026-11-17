local _, addon = ...
local bags = {}
addon.BagArrows = bags

function bags:UpdateButton(button, container)
    if not button then return end
    addon.UpgradeIndicators:Set(button, false)
    if not button.IsShown or not button:IsShown() then return end
    if button.IsCached and button:IsCached() then return end
    local bag = button.GetBag and button:GetBag() or (button.GetBagID and button:GetBagID())
        or (container and container.GetID and container:GetID())
    local slot = button.GetID and button:GetID()
    if type(bag) ~= "number" or type(slot) ~= "number" or slot < 1 then return end
    local link = C_Container.GetContainerItemLink(bag, slot)
    local result = link and addon.Comparison:Evaluate(link)
    addon.UpgradeIndicators:Set(button, addon.Comparison:IsUpgrade(result))
end

function bags:Refresh()
    addon.UpgradeIndicators:HideAll()
    local containers = {}
    if ContainerFrameCombinedBags then containers[#containers + 1] = ContainerFrameCombinedBags end
    for index = 1, 13 do
        local frame = _G["ContainerFrame" .. index]
        if frame then containers[#containers + 1] = frame end
    end
    local count = 0
    for _, container in ipairs(containers) do
        if container:IsShown() then
            if container.EnumerateValidItems then
                for _, button in container:EnumerateValidItems() do
                    count = count + 1
                    self:UpdateButton(button, container)
                end
            elseif container.Items then
                for _, button in pairs(container.Items) do
                    count = count + 1
                    self:UpdateButton(button, container)
                end
            else
                for _, button in ipairs({ container:GetChildren() }) do
                    if button.GetBagID or (button.GetName and (button:GetName() or ""):match("Item%d+$")) then
                        count = count + 1
                        self:UpdateButton(button, container)
                    end
                end
            end
        end
    end
    self.lastButtonCount = count
end
