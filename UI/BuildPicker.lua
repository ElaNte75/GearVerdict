local _, addon = ...
local picker = {}
addon.BuildPicker = picker

-- The build list of the Specialization page (replaces the three specialization tick boxes, see Data/TalentBuilds.lua):
-- a drop-down with every build in the guide's order, then a bar of the build's talent points per tree, the trees in
-- words, the weapons (only when the guide names them), a short description of what the guide says and the source.

local ROW_HEIGHT = 20
local BAR_WIDTH = 300

-- Talent points per tree as one bar of three parts (class color, lighter for the second and third tree).
function picker:BuildTreeBar(frame, anchor, gap)
    local widgets = addon.PanelWidgets
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    label:SetText("Talent points")
    widgets:PaintText(label, "note")
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetSize(BAR_WIDTH, 10)
    bar:SetPoint("LEFT", label, "RIGHT", 8, 0)
    local track = bar:CreateTexture(nil, "ARTWORK")
    track:SetAllPoints()
    widgets:Fill(track, "sectionLine")
    self.parts = {}
    for index = 1, 3 do
        local part = bar:CreateTexture(nil, "ARTWORK", nil, 1)
        part:SetHeight(10)
        self.parts[index] = part
    end
    self.bar = bar
    return label
end

function picker:ShowTrees(build)
    local trees = build and build.trees
    local total = trees and (trees[1] + trees[2] + trees[3]) or 0
    local r, g, b = addon.PanelWidgets:ClassColor()
    local shades = { 1, 0.6, 0.35 }
    local x = 0
    for index, part in ipairs(self.parts) do
        local width = total > 0 and BAR_WIDTH * trees[index] / total or 0
        part:ClearAllPoints()
        part:SetPoint("TOPLEFT", self.bar, "TOPLEFT", x, 0)
        part:SetWidth(math.max(width, 0.01))
        part:SetColorTexture(r, g, b, shades[index])
        part:SetShown(width > 0)
        x = x + width
    end
end

function picker:ShowBuild(build)
    if not self.frame then return end
    self:ShowTrees(build)
    if not build then
        self.trees:SetText("")
        self.weapons:SetText("")
        self.source:SetText("")
        self.description:SetText("Choose a build above to get gear recommendations and talent hints.")
        return
    end
    -- Weapons only when the guide names them for this build.
    self.weapons:SetText(build.weapons and ("Weapons: " .. build.weapons) or "")
    local text = addon.Builds:TreesText(build)
    if not build.classic then
        text = text .. "  |  gear as " .. (addon.SpecDetection:SpecName(build.gearSpec) or "?")
    end
    self.trees:SetText(text)
    local description = build.description or ""
    local keys = addon.Builds:KeyNames(build, 5)
    if #keys > 0 then description = description .. " Key talents (named by the guide): " .. table.concat(keys, ", ") .. "." end
    self.description:SetText(description)
    if build.classic then
        self.source:SetText("Talent order: from the " .. (addon.TalentAdvisor:GuideName() or "chosen") .. " leveling guide")
    else
        self.source:SetText("Source: " .. (build.source or "Wowhead"))
    end
end

function picker:ShowPlaceResult(result)
    local widgets = addon.PanelWidgets
    local text = result.text or ""
    if result.placed and result.placed > 0 and result.opened == false then text = text .. " Press Y to open the talents." end
    self.placeNote:SetText(text)
    self.placeNote:SetTextColor(widgets:Color(result.status == "ok" and "good" or (result.placed or 0) > 0 and "warning" or "bad"))
end

function picker:Place()
    self:ShowPlaceResult(addon.TalentPlacer:Run())
end

function picker:ToggleAuto()
    local options = GearVerdictDB.options
    options.autoPlaceTalents = not options.autoPlaceTalents or nil
    self:Update()
end

function picker:Select(id)
    addon.Builds:Choose(id)
    self.popup:Hide()
    if addon.PanelSpecPage then addon.PanelSpecPage:Update() end
    addon:Refresh()
end

function picker:BuildPopup(frame)
    local widgets = addon.PanelWidgets
    -- In the guide's order: classic builds first, then each specialization's Wowhead builds as the page lists them.
    local builds = {}
    for index, build in ipairs(addon.Builds:List() or {}) do builds[index] = { build = build } end
    local popup = CreateFrame("Frame", nil, frame)
    popup:SetFrameStrata("DIALOG")
    popup:SetSize(256, ROW_HEIGHT * (#builds + 1) + 6)
    popup:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, -2)
    popup:EnableMouse(true)
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    widgets:Fill(bg, "contentBg")
    widgets:Border(popup, 0)
    popup.rows = {}
    local function row(index, text, id)
        local button = widgets:Button(popup, text, 250, function() self:Select(id) end)
        button:SetPoint("TOPLEFT", 3, -3 - (index - 1) * ROW_HEIGHT)
        button:SetHeight(ROW_HEIGHT - 1)
        button:HookScript("OnEnter", function() self:ShowBuild(id and addon.Builds:Find(id) or nil) end)
        button:HookScript("OnLeave", function() self:ShowBuild(addon.Builds:Chosen()) end)
        popup.rows[#popup.rows + 1] = button
    end
    for index, entry in ipairs(builds) do row(index, entry.build.name, entry.build.id) end
    row(#builds + 1, "None (no recommendations)", nil)
    popup:Hide()
    return popup
end

-- Creates the picker under `anchor`; returns the last region so the page can continue below it.
function picker:Create(frame, anchor, gap)
    local widgets = addon.PanelWidgets
    self.frame = frame
    self.button = widgets:Button(frame, "", 230, function() self.popup:SetShown(not self.popup:IsShown()) end)
    self.button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    self.popup = self:BuildPopup(frame)
    -- Talent placement (Engine/TalentPlacer.lua): never presses Apply, it only fills the talent window.
    self.place = widgets:Button(frame, "Place talents", 100, function() self:Place() end)
    self.place:SetPoint("LEFT", self.button, "RIGHT", 8, 0)
    widgets:Tooltip(self.place, "Place talents", "Puts your unspent talent points into the talent window, in the "
        .. "order of this build, and opens it. It never presses Apply: you check the points and apply them yourself "
        .. "(Reset in the talent window undoes them).")
    self.auto = widgets:Button(frame, "", 90, function() self:ToggleAuto() end)
    self.auto:SetPoint("LEFT", self.place, "RIGHT", 8, 0)
    widgets:Tooltip(self.auto, "Auto placement", "When on, each new talent point is placed for you and the talent "
        .. "window opens. It still never presses Apply. Works while the leveling helper is on (Leveling page).")
    self.placeNote = widgets:Note(frame, "", self.button, 9)
    self.placeNote:SetWordWrap(false)
    local barLabel = self:BuildTreeBar(frame, self.placeNote, 12)
    self.trees = widgets:Note(frame, "", barLabel, 10)
    self.trees:SetWordWrap(false)
    self.weapons = widgets:Note(frame, "", self.trees, 8)
    self.weapons:SetWordWrap(false)
    -- The most important line: larger, in the theme's title color (gold in the gold theme).
    self.weapons:SetFontObject(GameFontNormalLarge)
    widgets:PaintText(self.weapons, "title")
    self.description = widgets:Note(frame, "", self.weapons, 10)
    self.description:SetWordWrap(true)
    self.description:SetHeight(50)
    self.source = widgets:Note(frame, "", self.description, 2)
    self.source:SetWordWrap(false)
    widgets:Tooltip(self.button, "Build", "Pick the talent build you play. Gear is compared for the specialization "
        .. "the build is based on, and the level-up hint follows the build's own talent order.")
    return self.source
end

function picker:Update()
    if not self.frame then return end
    local build = addon.Builds:Chosen()
    self.button:SetText(build and build.name or "Choose a build")
    self.auto:SetText("Auto: " .. (GearVerdictDB.options.autoPlaceTalents and "on" or "off"))
    self.place:SetEnabled(build ~= nil)
    self.popup:Hide()
    self:ShowBuild(build)
end
