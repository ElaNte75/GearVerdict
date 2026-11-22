local _, addon = ...
local merchant = { buttons = {} }
addon.MerchantArrows = merchant

-- Upgrade arrows on the items a vendor sells (added 2026-11-21 at the user's request).
-- The vendor window shows MERCHANT_ITEMS_PER_PAGE items per page in the buttons
-- MerchantItem<N>ItemButton; the item on button N is vendor index (page - 1) * per page + N.
-- The buyback tab is left alone (those items were the player's own).

local function perPage()
    return tonumber(MERCHANT_ITEMS_PER_PAGE) or 10
end

function merchant:HideAll()
    for _, button in pairs(self.buttons) do addon.UpgradeIndicators:Set(button, false) end
end

function merchant:Refresh()
    self:Hook()
    local frame = MerchantFrame
    if not frame or not frame.IsShown or not frame:IsShown() or not GetMerchantItemLink then
        self:HideAll()
        return
    end
    if frame.selectedTab and frame.selectedTab ~= 1 then
        self:HideAll()
        return
    end
    local page = tonumber(frame.page) or 1
    local count = GetMerchantNumItems and GetMerchantNumItems() or 0
    for slot = 1, perPage() do
        local button = _G["MerchantItem" .. slot .. "ItemButton"]
        if button then
            self.buttons[slot] = button
            local index = (page - 1) * perPage() + slot
            local link = index <= count and button:IsVisible() and GetMerchantItemLink(index) or nil
            local result = link and addon.Comparison:Evaluate(link) or nil
            addon.UpgradeIndicators:Set(button, addon.Comparison:IsUpgrade(result))
        end
    end
end

function merchant:Hook()
    if self.hooked or not hooksecurefunc then return end
    self.hooked = true
    local update = function() self:Refresh() end
    if MerchantFrame_UpdateMerchantInfo then hooksecurefunc("MerchantFrame_UpdateMerchantInfo", update) end
    if MerchantFrame_UpdateBuybackInfo then hooksecurefunc("MerchantFrame_UpdateBuybackInfo", update) end
    if MerchantFrame and MerchantFrame.HookScript then MerchantFrame:HookScript("OnHide", function() self:HideAll() end) end
end
