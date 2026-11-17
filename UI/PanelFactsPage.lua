local _, addon = ...
local page = {}
addon.PanelFactsPage = page

-- Facts page: plain statements about what GearVerdict does, what it does not, and how sure we are.
-- Text only; edit the `sections` table below when something is verified or changes.

local TAG = {
    checked = "|cff4dd94d[checked in game]|r",
    unverified = "|cffffd100[not verified yet]|r",
    gap = "|cffff8a3d[known gap]|r",
}

local sections = {
    { title = "Status", entries = {
        { text = "GearVerdict is in beta. The numbers are provisional and some rules are guesses. "
            .. "Every item below says how sure we are: " .. TAG.checked .. " we saw it work, " .. TAG.unverified
            .. " built but not seen working yet, " .. TAG.gap .. " we know it is missing or simplified." },
    } },
    { title = "What is compared", entries = {
        { title = "Base stats of the item", tag = "checked",
          text = "The stats the game reports for an item: Strength, Agility, Stamina, ratings, Spell Power, Healing, "
            .. "Mp5 and the passive \"Equip:\" bonuses that the game lists as numbers." },
        { title = "Newer stat names", tag = "unverified",
          text = "Defense, Dodge, Parry, Block and Armor Penetration are known from other versions of the game. "
            .. "We have not yet seen them on a Forever item." },
        { title = "Where arrows and tooltip lines appear", tag = "checked",
          text = "Bagnon bags, quest rewards and item tooltips. Blizzard's own bags are built but not seen working yet; "
            .. "other bag addons are not supported." },
        { title = "Tooltips of unloaded items", tag = "unverified",
          text = "If the game has not loaded an item yet, the tooltip shows nothing. Hover it again after a moment." },
    } },
    { title = "What is NOT counted", entries = {
        { title = "Armor and Stamina in damage specializations", tag = "gap",
          text = "Their weights come from a simulation that only measures damage, and Armor and Stamina do not "
            .. "raise damage. So they are worth zero there, even if they matter to you while leveling. "
            .. "You can change this on the Custom Weights page." },
        { title = "Weapons, trinkets, shields, relics", tag = "gap",
          text = "Not evaluated at all. Their value depends on speed and special effects that need separate rules." },
        { title = "Special effects", tag = "gap",
          text = "\"Use:\" effects, procs, set bonuses, gems and enchants are ignored. Only the item's own base stats count." },
    } },
    { title = "Where the weights come from", entries = {
        { title = "Damage specializations", tag = "unverified",
          text = "MythicSim numbers for the Forever client against a level 63 boss. They are not a promise of "
            .. "damage, and we do not know yet how well they fit lower levels." },
        { title = "Healers and tanks", tag = "unverified",
          text = "Guide priority orders only. The spacing between the numbers was chosen by the developer, "
            .. "because no simulation exists for them." },
        { title = "Healing items", tag = "unverified",
          text = "Healers count Spell Power at half the value of Healing. We do not know yet whether items with "
            .. "only Spell Power also heal." },
        { title = "Hit and expertise caps", tag = "unverified",
          text = "Experimental and off by default. Gear only: talents, racials and buffs are not included." },
    } },
    { title = "Rules about who can wear what", entries = {
        { title = "Armor types and levels", tag = "unverified",
          text = "Classic rules are assumed (for example mail and plate at level 40). The game's own check still applies "
            .. "when you try to equip." },
        { title = "Specialization", tag = "checked",
          text = "Forever has no specializations, so you choose one yourself on the Specialization page." },
    } },
    { title = "Report a problem", entries = {
        { text = "If a result looks wrong to you, tell the developer what you expected and which items were compared. "
            .. "Every odd case helps to decide which weights to change." },
    } },
}

function page:Create(parent, panel)
    local widgets = addon.PanelWidgets
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    self.frame = frame

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -22, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize((panel and panel.contentWidth or 358) - 24, 10)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, width) content:SetWidth(math.max(width, 10)) end)
    self.scroll, self.content = scroll, content

    local previous
    for index, section in ipairs(sections) do
        local line = widgets:Section(content, section.title, previous, index > 1 and widgets.GAP_SECTION - 4 or nil)
        previous = line
        for _, entry in ipairs(section.entries) do
            local text = entry.text
            if entry.title then
                text = "|cffffffff" .. entry.title .. "|r  " .. TAG[entry.tag] .. "\n" .. text
            end
            previous = widgets:Note(content, text, previous, 6)
            previous:SetWordWrap(true)
            self.last = previous
        end
    end
    return frame
end

function page:Update()
    if not self.frame or not self.last then return end
    -- Size the scrolling area to the text once it has been laid out.
    C_Timer.After(0, function()
        local top, bottom = self.content:GetTop(), self.last:GetBottom()
        if top and bottom then self.content:SetHeight(math.max(top - bottom + 12, 10)) end
    end)
end
