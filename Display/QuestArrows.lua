local _, addon = ...
local quests = {}
addon.QuestArrows = quests

function quests:Refresh()
    local info = QuestInfoFrame
    if not info or not info.rewardsFrame or not info.rewardsFrame.RewardButtons then return end
    local getLink = info.questLog and GetQuestLogItemLink or GetQuestItemLink
    local choices = {}
    for _, button in pairs(info.rewardsFrame.RewardButtons) do
        button.gearVerdictAnchor = button.Icon
        addon.UpgradeIndicators:Set(button, false)
        button.gearVerdictSell = nil
        if addon.QuestSellCoin then addon.QuestSellCoin:Show(button, false) end
        local kind = button.type
        local index = button.GetID and button:GetID()
        if button:IsShown() and getLink and (kind == "choice" or kind == "reward") and index and index > 0 then
            local link = getLink(kind, index)
            local result, reason = nil, nil
            if link then result, reason = addon.Comparison:Evaluate(link) end
            local upgrade = addon.Comparison:IsUpgrade(result)
            addon.UpgradeIndicators:Set(button, upgrade)
            if kind == "choice" then
                local price = link and select(11, C_Item.GetItemInfo(link))
                if price and index and not info.questLog and GetQuestItemInfo then
                    local count = select(3, GetQuestItemInfo(kind, index))
                    if type(count) == "number" and count > 1 then price = price * count end
                end
                choices[#choices + 1] = { button = button, price = price, upgrade = upgrade,
                    loading = reason == "Item data unavailable" }
            end
        end
    end
    if addon.QuestSellCoin then addon.QuestSellCoin:Update(choices) end
end
