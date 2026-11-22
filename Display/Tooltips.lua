local _, addon = ...
local tooltips = { seen = setmetatable({}, { __mode = "k" }), sold = setmetatable({}, { __mode = "k" }), tracked = setmetatable({}, { __mode = "k" }) }
addon.Tooltips = tooltips

function tooltips:Track(tooltip)
    if self.tracked[tooltip] or not tooltip.HookScript then return end
    self.tracked[tooltip] = true
    local clear = function(frame) self.seen[frame] = nil self.sold[frame] = nil end
    tooltip:HookScript("OnTooltipCleared", clear)
    tooltip:HookScript("OnHide", clear)
    tooltip:HookScript("OnShow", function(frame)
        if not self.seen[frame] then return end
        addon.Diagnostics:Log("tooltip-geometry", "width=" .. tostring(frame.GetWidth and frame:GetWidth())
            .. " height=" .. tostring(frame.GetHeight and frame:GetHeight())
            .. " bottom=" .. tostring(frame.GetBottom and frame:GetBottom()))
    end)
end

function tooltips:Process(tooltip)
    if not GearVerdictDB or not tooltip.GetItem then return end
    self:Track(tooltip)
    local _, link = tooltip:GetItem()
    if not link or not addon:IsPublic(link) then return end
    -- Quest reward chosen only for its vendor price (QuestSellCoin).
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local price = owner and owner.gearVerdictSell
    if price and self.sold[tooltip] ~= link and addon.QuestSellCoin then
        self.sold[tooltip] = link
        tooltip:AddLine(" ")
        tooltip:AddLine("GearVerdict: best to sell " .. addon.QuestSellCoin:Format(price), 1, 0.82, 0)
    end
    if self.seen[tooltip] == link then return end
    local name, _, _, _, _, _, _, _, equipLoc, _, _, classID = C_Item.GetItemInfo(link)
    if not name or (classID ~= 2 and classID ~= 4) or not equipLoc or equipLoc == "" then return end
    self.seen[tooltip] = link
    local journal = addon.DungeonJournalArrows
    local levelsAhead = journal and journal:IsRow(owner) and journal:LevelsAhead() or nil
    local result, reason = addon.Comparison:Evaluate(link, levelsAhead)
    addon.Diagnostics:Log("comparison", link .. " " .. (result
        and ("slot=" .. result.slot .. " delta=" .. result.delta) or tostring(reason)))
    if result then
        local previousLink = GetInventoryItemLink("player", result.slot)
        addon.Diagnostics:Log("replacement", "slot=" .. result.slot .. " previous=" .. (previousLink or "empty"))
        for stat, value in pairs(result.candidate.stats) do
            addon.Diagnostics:Log("candidate-stat", stat .. "=" .. value .. " weight=" .. tostring(addon.Presets:Weight(stat)))
        end
    end
    if result and result.belowQuality and addon.Comparison:BeatsEquipped(result) then
        tooltip:AddLine(" ")
        tooltip:AddLine("GearVerdict: ignored, item quality is below your setting", 0.62, 0.62, 0.62)
        return
    end
    if not addon.Comparison:IsUpgrade(result) then return end
    if addon.RingPlacement then addon.RingPlacement:Remember(link, result.slot) end
    tooltip:AddLine(" ")
    tooltip:AddLine("GearVerdict", 0.4, 0.8, 1)
    local _, classFile = UnitClass("player")
    local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    local preset = addon.Presets:Get()
    -- A chosen hybrid build is named (e.g. "Protection: Fury-Prot"); its gear still uses the gearSpec weights.
    local build = addon.Builds and addon.Builds:Chosen()
    local label = build and not build.classic and addon.Builds:DisplayName(build) or (preset and preset.label) or "Enhancement Shaman"
    tooltip:AddLine(label, classColor and classColor.r or 0.8,
        classColor and classColor.g or 0.8, classColor and classColor.b or 0.8)
    if result.goal then
        local gold = addon.UpgradeIndicators.goalColor
        tooltip:AddLine("Goal: wearable at level " .. result.goal, gold.r, gold.g, gold.b)
    end
    local percentMode = GearVerdictDB.options and GearVerdictDB.options.valueMode == "percent"
    for _, entry in ipairs(result.comparisons) do
        if entry.empty then
            tooltip:AddLine("Upgrade", 0.3, 1, 0.3)
        elseif entry.upgrade then
            local quality = entry.previousLink and select(3, C_Item.GetItemInfo(entry.previousLink))
            local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
            local right = percentMode and entry.percent and string.format("%+.1f%%", entry.percent)
                or string.format("%+.2f pts", entry.delta)
            -- Won only by the Armor tie rule (equal stats, more Armor): the stat value is not a gain, so it is gold.
            local vr, vg, vb = 0.3, 1, 0.3
            if entry.armorReason or entry.weaponReason then vr, vg, vb = 1, 0.82, 0 end
            tooltip:AddDoubleLine("|cffffd100vs|r " .. (entry.previousName or ("Slot " .. entry.slot)), right,
                color and color.r or 0.85, color and color.g or 0.85, color and color.b or 0.85, vr, vg, vb)
            local reason = addon.ArmorPreference and addon.ArmorPreference:ReasonText(entry.armorReason)
            if reason then tooltip:AddLine("  " .. reason, 0.3, 1, 0.3) end
        end
        if entry.upgrade or entry.empty then
            if entry.partner then tooltip:AddLine("  With " .. entry.partner .. " from bags", 0.3, 1, 0.3) end
            local specName = preset and addon.SpecDetection:SpecName(preset.specID, classFile)
            local weaponReason = addon.WeaponData and addon.WeaponData:ReasonText(entry.weaponReason, specName)
            if weaponReason then tooltip:AddLine("  " .. weaponReason, 0.3, 1, 0.3) end
        end
        addon.Diagnostics:Log("slot-comparison", "slot=" .. entry.slot .. " empty=" .. tostring(entry.empty)
            .. " delta=" .. entry.delta .. " percent=" .. tostring(entry.percent))
    end
    addon.Diagnostics:Log("tooltip-layout", "mode=synchronous rows=" .. #result.comparisons
        .. " lines=" .. tostring(tooltip.NumLines and tooltip:NumLines()))
end

function tooltips:Initialize()
    if self.initialized then return end
    if TooltipDataProcessor and Enum.TooltipDataType then
        self.initialized = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            self:Process(tooltip)
        end)
    end
end
