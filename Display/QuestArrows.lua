local _, addon = ...
local quests = {}
addon.QuestArrows = quests

function quests:Refresh()
    local info = QuestInfoFrame
    if not info or not info.rewardsFrame or not info.rewardsFrame.RewardButtons then return end
    local getLink = info.questLog and GetQuestLogItemLink or GetQuestItemLink
    for _, button in pairs(info.rewardsFrame.RewardButtons) do
        button.gearVerdictAnchor = button.Icon
        addon.UpgradeIndicators:Set(button, false)
        local kind = button.type
        local index = button.GetID and button:GetID()
        if button:IsShown() and getLink and (kind == "choice" or kind == "reward") and index and index > 0 then
            local link = getLink(kind, index)
            local result = link and addon.Comparison:Evaluate(link)
            addon.UpgradeIndicators:Set(button, addon.Comparison:IsUpgrade(result))
        end
    end
end
