local _, addon = ...
local toast = { queue = {}, frames = {}, known = nil, told = {} }
addon.UpgradeToast = toast

-- Upgrade notice: a small frame that pops up when an upgrade lands in the bags. Information only, no buttons.
-- Shown once per item, waits for the end of combat, up to 3 stacked, fades after Seconds() (10-60 s).
-- Hovering a notice shows the item's normal tooltip and pauses the countdown; the x closes it. Options page: on/off (options.upgradeToast, false = off),
-- Move (drag the first notice, saved in options.toastPoint), Test, Reset.

local FADE, MAX = 1, 3
local WIDTH, HEIGHT = 340, 66
toast.MIN_SECONDS, toast.MAX_SECONDS, toast.DEFAULT_SECONDS = 10, 60, 10

-- How long a notice stays before it fades (Options slider, 10-60 s).
function toast:Seconds()
    local options = GearVerdictDB and GearVerdictDB.options
    local value = options and tonumber(options.toastSeconds) or self.DEFAULT_SECONDS
    return math.max(self.MIN_SECONDS, math.min(self.MAX_SECONDS, value))
end

-- The x button: hides this notice now (and ends Move mode if it is the one being moved).
function toast:Close(frame)
    if self.moving and frame == self.frames[1] then
        self.moving = nil
        if addon.PanelOptionsPage and addon.PanelOptionsPage.frame then addon.PanelOptionsPage:Update() end
    end
    frame:Hide()
    GameTooltip:Hide()
    self:Flush()
end

function toast:Enabled()
    local options = GearVerdictDB and GearVerdictDB.options
    return not (options and options.upgradeToast == false)
end

-- Every item link in the bags (backpack + 4 bags), counted (two of the same item = 2).
function toast:BagLinks()
    local links = {}
    if not C_Container or not C_Container.GetContainerNumSlots then return links end
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then links[link] = (links[link] or 0) + 1 end
        end
    end
    return links
end

-- Called after every bag change: an item that was not in the bags before and is an upgrade gets a notice.
-- The first scan (login) only remembers what is already there.
function toast:Scan()
    local links = self:BagLinks()
    local before = self.known
    self.known = links
    if not before or not self:Enabled() then return end
    for link, count in pairs(links) do
        if count > (before[link] or 0) and not self.told[link] then
            local result = addon.Comparison:Evaluate(link)
            if addon.Comparison:IsUpgrade(result) then
                self.told[link] = true
                self:Push(link, result)
            end
        end
    end
end

function toast:Push(link, result)
    self.queue[#self.queue + 1] = { link = link, result = result }
    self:Flush()
end

function toast:Flush()
    if InCombatLockdown() then return end
    for index = 1, MAX do
        if #self.queue == 0 then return end
        local frame = self.frames[index] or self:Build(index)
        if not frame:IsShown() then self:Show(frame, table.remove(self.queue, 1)) end
    end
end

local function statName(key)
    local text = _G[key]
    return type(text) == "string" and text or key
end

-- What changes against the replaced item: up to 4 stats, gains first.
function toast:Changes(result)
    local entry = result.comparisons and result.comparisons[1]
    for _, candidate in ipairs(result.comparisons or {}) do
        if candidate.slot == result.slot then entry = candidate end
    end
    local old = entry and entry.previousLink and addon.ItemData:Get(entry.previousLink)
    local before, after = old and old.stats or {}, result.candidate.stats or {}
    local list = {}
    for key, value in pairs(after) do list[#list + 1] = { key = key, diff = value - (before[key] or 0) } end
    for key, value in pairs(before) do
        if after[key] == nil then list[#list + 1] = { key = key, diff = -value } end
    end
    table.sort(list, function(a, b) return a.diff > b.diff end)
    local parts = {}
    for _, change in ipairs(list) do
        if change.diff ~= 0 and #parts < 4 then
            local color = change.diff > 0 and "|cff4dff4d" or "|cffff5050"
            parts[#parts + 1] = string.format("%s%+d %s|r", color, change.diff, statName(change.key))
        end
    end
    return table.concat(parts, "   "), entry
end

function toast:Show(frame, item)
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(item.link)
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    frame.link = item.link
    frame.icon:SetTexture(icon)
    frame.name:SetText(name or item.link)
    frame.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
    local changes, entry = self:Changes(item.result)
    local versus = entry and entry.previousName and ("Upgrade for you  |cffffd100vs|r " .. entry.previousName)
        or "Upgrade for you  (empty slot)"
    if item.sample then versus = "Example notice (an item you wear)" end
    frame.versus:SetText(versus)
    frame.stats:SetText(changes)
    local percentMode = GearVerdictDB.options and GearVerdictDB.options.valueMode == "percent"
    local value = entry and (percentMode and entry.percent and string.format("%+.1f%%", entry.percent)
        or string.format("%+.2f pts", entry.delta)) or ""
    frame.value:SetText(value)
    frame.elapsed, frame.hover = 0, false
    frame:SetAlpha(1)
    frame:Show()
    local kit = SOUNDKIT and (SOUNDKIT.UI_EPICLOOT_TOAST or SOUNDKIT.LOOT_WINDOW_COIN_SOUND or SOUNDKIT.IG_BACKPACK_OPEN)
    if kit then pcall(PlaySound, kit) end
end

function toast:Build(index)
    local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    frame:SetSize(WIDTH, HEIGHT)
    self.frames[index] = frame
    self:Place(index)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    if index == 1 then
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) if toast.moving then self:StartMoving() end end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, relative, x, y = self:GetPoint(1)
            GearVerdictDB.options.toastPoint = { point = point, relative = relative, x = x, y = y }
            toast:Place(1)
        end)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        frame:SetBackdropColor(0.04, 0.05, 0.09, 0.94)
        frame:SetBackdropBorderColor(1, 0.82, 0.2, 1)
    end
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(42, 42)
    icon:SetPoint("LEFT", 12, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.icon = icon
    -- The bouncing arrow on the icon corner: the same arrow as in the bags.
    local holder = CreateFrame("Frame", nil, frame)
    holder:SetSize(16, 16)
    holder:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 6, -8)
    holder:SetFrameLevel(frame:GetFrameLevel() + 5)
    local arrow = addon.UpgradeIndicators:Build(holder)
    arrow:SetPoint("CENTER")
    local _, arrowColor = addon.UpgradeIndicators:Options()
    for _, texture in ipairs(arrow.fills) do texture:SetColorTexture(arrowColor.r, arrowColor.g, arrowColor.b, 1) end
    frame.arrow = arrow
    local function text(font, anchor, x, y)
        local line = frame:CreateFontString(nil, "OVERLAY", font)
        line:SetPoint("TOPLEFT", anchor, "TOPRIGHT", x, y)
        line:SetJustifyH("LEFT")
        return line
    end
    frame.name = text("GameFontNormalLarge", icon, 10, 2)
    frame.versus = text("GameFontHighlightSmall", icon, 10, -18)
    frame.stats = text("GameFontHighlightSmall", icon, 10, -32)
    frame.value = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.value:SetPoint("TOPRIGHT", -24, -10)
    frame.value:SetTextColor(0.3, 1, 0.3)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        self.hover = true
        self:SetAlpha(1)
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        self.hover = false
        GameTooltip:Hide()
    end)
    -- Small grey countdown (bottom right) and a discreet close button (top right).
    frame.countdown = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.countdown:SetPoint("BOTTOMRIGHT", -8, 6)
    frame.countdown:SetTextColor(0.55, 0.55, 0.55)
    local close = CreateFrame("Button", nil, frame)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetFrameLevel(frame:GetFrameLevel() + 6)
    local cross = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cross:SetPoint("CENTER")
    cross:SetText("x")
    cross:SetTextColor(0.55, 0.55, 0.55)
    close:SetScript("OnEnter", function() cross:SetTextColor(1, 1, 1) end)
    close:SetScript("OnLeave", function() cross:SetTextColor(0.55, 0.55, 0.55) end)
    close:SetScript("OnClick", function() toast:Close(frame) end)
    frame.close = close
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.bounce = (self.bounce or 0) + elapsed
        self.arrow:SetPoint("CENTER", 0, math.abs(math.sin(self.bounce * 5)) * 6)
        local hold = toast:Seconds()
        if toast.moving and self == toast.frames[1] then
            self.countdown:SetText("")
            return
        end
        self.countdown:SetText(self.elapsed < hold and (math.ceil(hold - self.elapsed) .. "s") or "")
        if self.hover then return end
        self.elapsed = self.elapsed + elapsed
        if self.elapsed > hold then
            local alpha = 1 - (self.elapsed - hold) / FADE
            if alpha <= 0 then
                self:Hide()
                toast:Flush()
            else
                self:SetAlpha(alpha)
            end
        end
    end)
    frame:Hide()
    return frame
end

-- Position: the first notice sits where the player put it (Options "Move"), default top center;
-- the others stack under it.
function toast:Place(index)
    local frame = self.frames[index]
    if not frame then return end
    frame:ClearAllPoints()
    if index > 1 then
        frame:SetPoint("TOP", self.frames[index - 1], "BOTTOM", 0, -6)
        return
    end
    local saved = GearVerdictDB and GearVerdictDB.options and GearVerdictDB.options.toastPoint
    if saved and saved.point then
        frame:SetPoint(saved.point, UIParent, saved.relative or saved.point, saved.x or 0, saved.y or 0)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
end

-- Options "Center": same height as now, centered left-right on the screen.
function toast:CenterHorizontally()
    local frame = self.frames[1] or self:Build(1)
    local top, screenTop = frame:GetTop(), UIParent:GetTop()
    local y = top and screenTop and (top - screenTop) or -150
    GearVerdictDB.options.toastPoint = { point = "TOP", relative = "TOP", x = 0, y = y }
    for index in ipairs(self.frames) do self:Place(index) end
end

function toast:ResetPosition()
    GearVerdictDB.options.toastPoint = nil
    for index in ipairs(self.frames) do self:Place(index) end
end

-- An example notice (Options "Test" and "Move"): a real upgrade from the bags if there is one,
-- otherwise an equipped item shown as an example.
function toast:Sample()
    for link in pairs(self:BagLinks()) do
        local result = addon.Comparison:Evaluate(link)
        if addon.Comparison:IsUpgrade(result) then return { link = link, result = result } end
    end
    for slot = 1, 18 do
        local link = GetInventoryItemLink("player", slot)
        local item = link and addon.ItemData:Get(link)
        if item then return { link = link, sample = true, result = { comparisons = {}, candidate = item } } end
    end
end

function toast:Test()
    local item = self:Sample()
    if not item then return false end
    local frame = self.frames[1] or self:Build(1)
    self:Show(frame, item)
    return true
end

-- Move mode: the first notice stays on screen and can be dragged; switching off hides it.
function toast:SetMoving(on)
    self.moving = on and true or nil
    local frame = self.frames[1] or self:Build(1)
    if on then
        if not self:Test() then
            frame.link = nil
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            frame.name:SetText("Upgrade notice")
            frame.versus:SetText("Drag me where you want the notices")
            frame.stats:SetText("")
            frame.value:SetText("")
            frame.elapsed, frame.hover = 0, false
            frame:SetAlpha(1)
            frame:Show()
        end
    else
        frame:Hide()
        self:Flush()
    end
end
