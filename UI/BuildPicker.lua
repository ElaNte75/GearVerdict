local _, addon = ...
local picker = {}
addon.BuildPicker = picker

-- The build list of the Specialization page (replaces the three specialization tick boxes for classes that
-- have builds, see Data/TalentBuilds.lua): a drop-down with every build, then a defense<->offense meter,
-- the talent points per tree and a short description of the highlighted build.

local ROW_HEIGHT = 22
local METER_WIDTH = 250

-- Draws the meter: Defense on the left, Offense on the right, filled up to the build's value.
function picker:BuildMeter(frame, anchor, gap)
    local widgets = addon.PanelWidgets
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    label:SetText("Defense")
    widgets:PaintText(label, "note")
    local right = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    right:SetText("Offense")
    widgets:PaintText(right, "note")
    local bar = CreateFrame("Frame", nil, frame)
    bar:SetSize(METER_WIDTH, 10)
    bar:SetPoint("LEFT", label, "RIGHT", 8, 0)
    right:SetPoint("LEFT", bar, "RIGHT", 8, 0)
    -- Theme colors: a dark track, a filled part from the left up to the build's value, a bright marker.
    local track = bar:CreateTexture(nil, "ARTWORK")
    track:SetAllPoints()
    local fill = bar:CreateTexture(nil, "ARTWORK", nil, 1)
    fill:SetPoint("TOPLEFT")
    fill:SetSize(1, 10)
    -- Like the stat bars: the class color on a dark track, so it matches the chosen theme.
    widgets:Fill(track, "sectionLine")
    fill:SetColorTexture(widgets:ClassColor())
    local marker = bar:CreateTexture(nil, "OVERLAY")
    marker:SetSize(4, 18)
    widgets:Fill(marker, "title")
    marker:SetPoint("CENTER", bar, "LEFT", METER_WIDTH / 2, 0)
    self.fill = fill
    self.marker, self.bar = marker, bar
    return label
end

function picker:ShowBuild(build)
    if not self.frame then return end
    if not build then
        self.trees:SetText("")
        self.weapons:SetText("")
        self.source:SetText("")
        self.description:SetText("Choose a build above to get gear recommendations and talent hints.")
        self.marker:Hide()
        self.fill:Hide()
        return
    end
    local x = METER_WIDTH * addon.Builds:Offense(build) / 100
    self.marker:Show()
    self.marker:ClearAllPoints()
    self.marker:SetPoint("CENTER", self.bar, "LEFT", x, 0)
    self.fill:Show()
    self.fill:SetColorTexture(addon.PanelWidgets:ClassColor())
    self.fill:SetWidth(math.max(x, 1))
    self.weapons:SetText(build.weapons and ("Weapons: " .. build.weapons) or "")
    local text = "Talents " .. addon.Builds:TreesText(build)
    if build.classic then
        text = text .. "  |  follows your leveling guide"
    else
        local gear = addon.SpecDetection:SpecName(build.gearSpec) or "?"
        text = text .. "  |  gear as " .. gear
    end
    self.trees:SetText(text)
    local text = build.description or ""
    local keys = addon.Builds:KeyNames(build, 4)
    if #keys > 0 then text = text .. " Key talents: " .. table.concat(keys, ", ") .. "." end
    self.description:SetText(text)
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
    -- Most defense first, most offense last (same direction as the meter); equal values keep the data order.
    local builds = {}
    for index, build in ipairs(addon.Builds:List() or {}) do builds[index] = { build = build, index = index } end
    table.sort(builds, function(a, b)
        local x, y = addon.Builds:Offense(a.build), addon.Builds:Offense(b.build)
        if x ~= y then return x < y end
        return a.index < b.index
    end)
    local popup = CreateFrame("Frame", nil, frame)
    popup:SetFrameStrata("DIALOG")
    popup:SetSize(206, ROW_HEIGHT * (#builds + 1) + 6)
    popup:SetPoint("TOPLEFT", self.button, "BOTTOMLEFT", 0, -2)
    popup:EnableMouse(true)
    local bg = popup:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    widgets:Fill(bg, "contentBg")
    widgets:Border(popup, 0)
    popup.rows = {}
    local function row(index, text, id)
        local button = widgets:Button(popup, text, 200, function() self:Select(id) end)
        button:SetPoint("TOPLEFT", 3, -3 - (index - 1) * ROW_HEIGHT)
        button:SetHeight(ROW_HEIGHT - 2)
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
    self.button = widgets:Button(frame, "", 190, function() self.popup:SetShown(not self.popup:IsShown()) end)
    self.button:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -gap)
    self.popup = self:BuildPopup(frame)
    -- Talent placement (Engine/TalentPlacer.lua): never presses Apply, it only fills the talent window.
    self.place = widgets:Button(frame, "Place talents", 120, function() self:Place() end)
    self.place:SetPoint("LEFT", self.button, "RIGHT", 8, 0)
    widgets:Tooltip(self.place, "Place talents", "Puts your unspent talent points into the talent window, in the "
        .. "order of this build, and opens it. It never presses Apply: you check the points and apply them yourself "
        .. "(Reset in the talent window undoes them).")
    self.auto = widgets:Button(frame, "", 100, function() self:ToggleAuto() end)
    self.auto:SetPoint("LEFT", self.place, "RIGHT", 8, 0)
    widgets:Tooltip(self.auto, "Auto placement", "When on, each new talent point is placed for you and the talent "
        .. "window opens. It still never presses Apply. Works while the leveling helper is on (Leveling page).")
    self.placeNote = widgets:Note(frame, "", self.button, 9)
    self.placeNote:SetWordWrap(false)
    local meterLabel = self:BuildMeter(frame, self.placeNote, 12)
    self.trees = widgets:Note(frame, "", meterLabel, 16)
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
