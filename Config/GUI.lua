local UUFPLUS = _G.UUFPLUS

local AnchorPoints = {
    { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center",
      RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom", BOTTOMRIGHT = "Bottom Right" },
    { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" },
}

local FrameStrataList = {
    { BACKGROUND = "Background", LOW = "Low", MEDIUM = "Medium", HIGH = "High" },
    { "BACKGROUND", "LOW", "MEDIUM", "HIGH" },
}

local GrowthXList = {
    { LEFT = "Left", RIGHT = "Right" },
    { "LEFT", "RIGHT" },
}

local GrowthYList = {
    { UP = "Up", DOWN = "Down" },
    { "UP", "DOWN" },
}

-- ── widget helpers ────────────────────────────────────────────────────────────

local function AG() return UUFPLUS.UUF.AG end

local function CreateScrollFrame(parent)
    local scroll = AG():Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    parent:AddChild(scroll)
    return scroll
end

local function AddHeader(parent, text)
    local h = AG():Create("Heading")
    h:SetText(text)
    h:SetFullWidth(true)
    parent:AddChild(h)
end

local function AddToggle(parent, label, desc, get, set)
    local cb = AG():Create("CheckBox")
    cb:SetLabel(label)
    cb:SetDescription(desc or "")
    cb:SetValue(get())
    cb:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    cb:SetRelativeWidth(0.5)
    parent:AddChild(cb)
end

local function AddSlider(parent, label, min, max, step, get, set)
    local sl = AG():Create("Slider")
    sl:SetLabel(label)
    sl:SetSliderValues(min, max, step)
    sl:SetValue(get())
    sl:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    sl:SetRelativeWidth(0.5)
    parent:AddChild(sl)
end

local function AddEditBox(parent, label, get, set)
    local eb = AG():Create("EditBox")
    eb:SetLabel(label)
    eb:SetText(get())
    eb:SetCallback("OnEnterPressed", function(_, _, val) set(val) end)
    eb:SetRelativeWidth(1)
    parent:AddChild(eb)
end

local function AddDropdown(parent, label, list, listOrder, get, set)
    local dd = AG():Create("Dropdown")
    dd:SetLabel(label)
    dd:SetList(list, listOrder)
    dd:SetValue(get())
    dd:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    dd:SetRelativeWidth(0.5)
    parent:AddChild(dd)
end

local function AddColorPicker(parent, label, getR, getG, getB, onChange)
    local cp = AG():Create("ColorPicker")
    cp:SetLabel(label)
    cp:SetColor(getR(), getG(), getB())
    cp:SetCallback("OnValueConfirmed", function(_, _, r, g, b)
        onChange(r, g, b)
    end)
    cp:SetRelativeWidth(0.5)
    parent:AddChild(cp)
end

local function AddSpacer(parent)
    local sp = AG():Create("Label")
    sp:SetText(" ")
    sp:SetRelativeWidth(0.5)
    parent:AddChild(sp)
end

-- ── live update functions ─────────────────────────────────────────────────────

local editOverlays = {}

local function IterateChildren(header, fn)
    for i = 1, header:GetNumChildren() do
        local child = select(i, header:GetChildren())
        if child and child.unit then fn(child) end
    end
end

local function UpdateFrames(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local db = UUFPLUS.db.profile[dbKey]
    local powerH = db.PowerBar.Enabled and db.PowerBar.Height or 0

    IterateChildren(header, function(child)
        child:SetFrameStrata(db.Frame.FrameStrata)

        if child.Health then
            child.Health.colorClass    = db.HealthBar.ColorByClass
            child.Health.colorReaction = db.HealthBar.ColorByClass
            if child.Health.bg then
                child.Health.bg:SetVertexColor(0.15, 0.15, 0.15, db.HealthBar.BackgroundAlpha)
            end
            child.Health:ClearAllPoints()
            child.Health:SetPoint("TOPLEFT", child, 1, -1)
            child.Health:SetPoint("BOTTOMRIGHT", child, -1, 1 + (powerH > 0 and powerH + 1 or 0))
        end

        if child.Power then
            child.Power:SetHeight(db.PowerBar.Height)
            local show
            if db.PowerBar.HealerOnly and child.unit then
                show = db.PowerBar.Enabled and UnitGroupRolesAssigned(child.unit) == "HEALER"
            else
                show = db.PowerBar.Enabled
            end
            child.Power:SetShown(show)
            if child.Health and db.PowerBar.HealerOnly then
                local gap = (show and db.PowerBar.Height > 0) and (db.PowerBar.Height + 1) or 0
                child.Health:ClearAllPoints()
                child.Health:SetPoint("TOPLEFT", child, 1, -1)
                child.Health:SetPoint("BOTTOMRIGHT", child, -1, 1 + gap)
            end
        end

        if child.Range then
            child.Range.insideAlpha  = db.Range.InRange
            child.Range.outsideAlpha = db.Range.OutOfRange
        end

        if child.Debuffs then
            child.Debuffs.num     = db.Auras.NumDebuffs
            child.Debuffs.size    = db.Auras.Size
            child.Debuffs.spacing = db.Auras.Spacing
            child.Debuffs:SetSize(
                (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumDebuffs,
                db.Auras.Size + db.Auras.Spacing
            )
        end

        if child.Buffs then
            child.Buffs.num     = db.Auras.NumBuffs
            child.Buffs.size    = db.Auras.Size
            child.Buffs.spacing = db.Auras.Spacing
            child.Buffs:SetSize(
                (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumBuffs,
                db.Auras.Size + db.Auras.Spacing
            )
        end

        if child.UpdateAllElements then
            child:UpdateAllElements("UpdateFrames")
        end
    end)
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateAuras(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local db = UUFPLUS.db.profile[dbKey]
    local gx  = db.Auras.GrowthX or "LEFT"
    local gy  = db.Auras.GrowthY or "UP"
    local ia  = (gy == "UP" and "BOTTOM" or "TOP") .. (gx == "LEFT" and "RIGHT" or "LEFT")
    local bgx = db.Auras.BuffsGrowthX or gx
    local bgy = db.Auras.BuffsGrowthY or gy
    local bia = (bgy == "UP" and "BOTTOM" or "TOP") .. (bgx == "LEFT" and "RIGHT" or "LEFT")

    IterateChildren(header, function(child)
        if child.Debuffs then
            local AL = db.Auras.Layout
            local ap = AL[1] or "BOTTOMRIGHT"
            child.Debuffs:ClearAllPoints()
            child.Debuffs:SetPoint(ap, child, AL[2] or ap, AL[3] or 0, AL[4] or 0)
            child.Debuffs:SetSize(
                (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumDebuffs,
                db.Auras.Size + db.Auras.Spacing
            )
            child.Debuffs.initialAnchor = ia
            child.Debuffs.growthX       = gx
            child.Debuffs.growthY       = gy
        end

        if child.Buffs then
            local BL = db.Auras.BuffsLayout
            local bp = BL[1] or "BOTTOMLEFT"
            child.Buffs:ClearAllPoints()
            child.Buffs:SetPoint(bp, child, BL[2] or bp, BL[3] or 0, BL[4] or 0)
            child.Buffs:SetSize(
                (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumBuffs,
                db.Auras.Size + db.Auras.Spacing
            )
            child.Buffs.initialAnchor  = bia
            child.Buffs.growthX        = bgx
            child.Buffs.growthY        = bgy
            child.Buffs.onlyShowPlayer = true
        end

        if child.UpdateAllElements then
            child:UpdateAllElements("UpdateAuras")
        end
    end)
end

local function UpdateAuraVisibility(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local db = UUFPLUS.db.profile[dbKey]

    IterateChildren(header, function(child)
        local debuffs = child._debuffsContainer
        if debuffs then
            if db.Auras.Enabled then
                child.Debuffs = debuffs
                debuffs:Show()
                if child.UpdateAllElements then child:UpdateAllElements("UpdateAuras") end
            else
                child.Debuffs = nil
                debuffs:Hide()
            end
        end

        local buffs = child._buffsContainer
        if buffs then
            if db.Auras.BuffsEnabled then
                child.Buffs = buffs
                buffs:Show()
                if child.UpdateAllElements then child:UpdateAllElements("UpdateAuras") end
            else
                child.Buffs = nil
                buffs:Hide()
            end
        end
    end)
end

local function UpdateLayout(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local layout = UUFPLUS.db.profile[dbKey].Frame.Layout
    header:ClearAllPoints()
    header:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateFrameSize(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header or InCombatLockdown() then return end
    local db = UUFPLUS.db.profile[dbKey]
    local w, h = db.Frame.Width, db.Frame.Height

    IterateChildren(header, function(child)
        child:SetSize(w, h)
    end)

    if dbKey == "Party" then
        header:SetAttribute("yOffset", -db.Frame.Spacing)
    elseif dbKey == "Raid" then
        header:SetAttribute("yOffset", -db.Frame.SpacingY)
        header:SetAttribute("columnSpacing", db.Frame.SpacingX)
    end
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function ToggleEditOverlay(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end

    if editOverlays[dbKey] then
        editOverlays[dbKey]:Hide()
        editOverlays[dbKey] = nil
        return
    end

    local db = UUFPLUS.db.profile[dbKey]
    local overlay = CreateFrame("Frame", nil, UIParent)
    local w, h = header:GetWidth(), header:GetHeight()
    overlay:SetSize(math.max(w, 80), math.max(h, 24))
    overlay:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetMovable(true)
    overlay:SetClampedToScreen(true)
    overlay:EnableMouse(true)

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 0.8, 0, 0.25)

    local lbl = overlay:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(UUFPLUS.UUF.Media.Font, 8, UUFPLUS.UUF.Media.FontFlag)
    lbl:SetPoint("CENTER")
    lbl:SetText("|cFFFFCC00" .. dbKey .. "|r\nDrag  •  Right-click done")
    lbl:SetJustifyH("CENTER")

    local function saveAndMove(self)
        local point, _, relPoint, x, y = self:GetPoint()
        db.Frame.Layout[1] = point
        db.Frame.Layout[2] = relPoint or "CENTER"
        db.Frame.Layout[3] = math.floor(x + 0.5)
        db.Frame.Layout[4] = math.floor(y + 0.5)
        header:ClearAllPoints()
        header:SetPoint(point, UIParent, relPoint or "CENTER", x, y)
    end

    overlay:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self:StartMoving()
        elseif button == "RightButton" then
            self:StopMovingOrSizing()
            saveAndMove(self)
            self:Hide()
            editOverlays[dbKey] = nil
        end
    end)
    overlay:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        saveAndMove(self)
    end)

    editOverlays[dbKey] = overlay
end

local function UpdateTags(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local db  = UUFPLUS.db.profile[dbKey]
    local UUF = UUFPLUS.UUF

    IterateChildren(header, function(child)
        if child._tagName then
            local t = db.Tags.Name
            child:Tag(child._tagName, t.Tag)
            child._tagName:SetFont(UUF.Media.Font, t.FontSize, UUF.Media.FontFlag)
            child._tagName:SetTextColor(t.Colour[1], t.Colour[2], t.Colour[3])
            local L = t.Layout
            child._tagName:ClearAllPoints()
            child._tagName:SetPoint(L[1], child.Health, L[2], L[3], L[4])
            child._tagName:SetJustifyH(L[1]:find("RIGHT") and "RIGHT" or "LEFT")
            child._tagName:UpdateTag()
        end
        if child._tagHP then
            local t = db.Tags.HP
            child:Tag(child._tagHP, t.Tag)
            child._tagHP:SetFont(UUF.Media.Font, t.FontSize, UUF.Media.FontFlag)
            child._tagHP:SetTextColor(t.Colour[1], t.Colour[2], t.Colour[3])
            local L = t.Layout
            child._tagHP:ClearAllPoints()
            child._tagHP:SetPoint(L[1], child.Health, L[2], L[3], L[4])
            child._tagHP:SetJustifyH(L[1]:find("RIGHT") and "RIGHT" or "LEFT")
            child._tagHP:UpdateTag()
        end
    end)
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateOfflineText(dbKey)
    local db  = UUFPLUS.db.profile[dbKey]
    local UUF = UUFPLUS.UUF
    local SL  = db.StatusText and db.StatusText.Layout
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if header then
        IterateChildren(header, function(child)
            if child._statusTxt then
                child._statusTxt:SetFont(UUF.Media.Font, db.OfflineFontSize or 10, UUF.Media.FontFlag)
                if SL then
                    child._statusTxt:ClearAllPoints()
                    child._statusTxt:SetPoint(SL[1] or "CENTER", child, SL[2] or "CENTER", SL[3] or 0, SL[4] or 0)
                end
            end
        end)
    end
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateReadyCheck(dbKey)
    local db = UUFPLUS.db.profile[dbKey]
    local RC = db.ReadyCheck
    local RL = RC and RC.Layout
    local sz = (RC and RC.Size) or 16
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if header and RL then
        IterateChildren(header, function(child)
            local rci = child.ReadyCheckIndicator
            if rci then
                rci:SetSize(sz, sz)
                rci:ClearAllPoints()
                rci:SetPoint(RL[1] or "CENTER", child, RL[2] or "CENTER", RL[3] or 0, RL[4] or 0)
            end
        end)
    end
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateTargetGlow(dbKey)
    local db   = UUFPLUS.db.profile[dbKey]
    local tDb  = db.Indicators.Target
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if header then
        IterateChildren(header, function(child)
            if child._targetGlow then
                if tDb then
                    local C = tDb.Colour
                    child._targetGlow:SetBackdropBorderColor(C[1], C[2], C[3], C[4] or 1)
                end
                if tDb and tDb.Enabled and child.unit and UnitIsUnit(child.unit, "target") then
                    child._targetGlow:SetAlpha(1)
                else
                    child._targetGlow:SetAlpha(0)
                end
            end
        end)
    end
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function UpdateIndicators(dbKey)
    local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
    if not header then return end
    local db = UUFPLUS.db.profile[dbKey]

    IterateChildren(header, function(child)
        local health = child.Health

        local function applyIndicator(el, indDb)
            if not el or not health then return end
            el:SetSize(indDb.Size, indDb.Size)
            el:ClearAllPoints()
            local L = indDb.Layout
            el:SetPoint(L[1] or "TOPLEFT", health, L[2] or L[1] or "TOPLEFT", L[3] or 0, L[4] or 0)
        end

        applyIndicator(child.LeaderIndicator,    db.Indicators.Leader)
        applyIndicator(child.AssistantIndicator, db.Indicators.Assistant)
        applyIndicator(child.RaidRoleIndicator,  db.Indicators.RaidRole)
        applyIndicator(child.GroupRoleIndicator, db.Indicators.GroupRole)

        -- Raid target marker anchors to _highContainer, not health
        local rtEl = child.RaidTargetIndicator
        local rtDb = db.Indicators.RaidTargetMarker
        if rtEl and rtDb and child._highContainer then
            rtEl:SetSize(rtDb.Size, rtDb.Size)
            rtEl:ClearAllPoints()
            local L = rtDb.Layout
            rtEl:SetPoint(L[1] or "TOPRIGHT", child._highContainer, L[2] or "TOPRIGHT", L[3] or 2, L[4] or 2)
        end

        -- Fire Override functions so each indicator respects the current Enabled state.
        if child.UpdateAllElements then
            child:UpdateAllElements("UpdateIndicators")
        end
    end)
    UUFPLUS:RefreshPreviewIfShown(dbKey)
end

local function ScaleFrames(dbKey, newScale)
    local db = UUFPLUS.db.profile[dbKey]
    local oldScale = db.Scale or 1.0
    if math.abs(newScale - oldScale) < 0.001 then return end
    local r = newScale / oldScale
    db.Scale = newScale

    local function si(v) return math.max(1, math.floor(v * r + 0.5)) end

    db.Frame.Width  = si(db.Frame.Width)
    db.Frame.Height = si(db.Frame.Height)
    if dbKey == "Party" then
        db.Frame.Spacing = si(db.Frame.Spacing)
    else
        db.Frame.SpacingX = si(db.Frame.SpacingX)
        db.Frame.SpacingY = si(db.Frame.SpacingY)
    end

    db.PowerBar.Height = si(db.PowerBar.Height)

    db.Auras.Size    = si(db.Auras.Size)
    db.Auras.Spacing = si(db.Auras.Spacing)

    db.Tags.Name.FontSize = si(db.Tags.Name.FontSize)
    if db.Tags.HP then
        db.Tags.HP.FontSize = si(db.Tags.HP.FontSize)
    end

    for _, ind in pairs(db.Indicators) do
        ind.Size = si(ind.Size)
    end

    UpdateFrameSize(dbKey)
    UpdateFrames(dbKey)
    UpdateTags(dbKey)
    UpdateIndicators(dbKey)
    UpdateAuras(dbKey)
end

-- ── tab renderers ─────────────────────────────────────────────────────────────

local function RenderFrameTab(container, dbKey)
    local db = UUFPLUS.db.profile[dbKey]

    AddHeader(container, "Master Scale")

    AddSlider(container, "Scale", 0.25, 4.0, 0.05,
        function() return db.Scale or 1.0 end,
        function(v) ScaleFrames(dbKey, v) end)

    AddHeader(container, "General")

    AddToggle(container, "Enabled", "Show " .. dbKey .. " frames",
        function() return db.Enabled end,
        function(v)
            db.Enabled = v
            local header = dbKey == "Party" and UUFPLUS.PartyHeader or UUFPLUS.RaidHeader
            if header then header:SetShown(v) end
        end)

    AddToggle(container, "Hide Blizzard Frames", "Hide Blizzard's default group frames",
        function() return db.HideBlizzard end,
        function(v) db.HideBlizzard = v end)

    AddSlider(container, "Width", 40, 400, 1,
        function() return db.Frame.Width end,
        function(v) db.Frame.Width = v; UpdateFrameSize(dbKey) end)

    AddSlider(container, "Height", 12, 200, 1,
        function() return db.Frame.Height end,
        function(v) db.Frame.Height = v; UpdateFrameSize(dbKey) end)

    AddDropdown(container, "Frame Strata", FrameStrataList[1], FrameStrataList[2],
        function() return db.Frame.FrameStrata end,
        function(v) db.Frame.FrameStrata = v; UpdateFrames(dbKey) end)

    AddHeader(container, "Position")

    AddDropdown(container, "Anchor Point", AnchorPoints[1], AnchorPoints[2],
        function() return db.Frame.Layout[1] end,
        function(v) db.Frame.Layout[1] = v; UpdateLayout(dbKey) end)

    AddDropdown(container, "Relative Anchor", AnchorPoints[1], AnchorPoints[2],
        function() return db.Frame.Layout[2] end,
        function(v) db.Frame.Layout[2] = v; UpdateLayout(dbKey) end)

    AddSlider(container, "X Offset", -2000, 2000, 1,
        function() return db.Frame.Layout[3] end,
        function(v) db.Frame.Layout[3] = v; UpdateLayout(dbKey) end)

    AddSlider(container, "Y Offset", -2000, 2000, 1,
        function() return db.Frame.Layout[4] end,
        function(v) db.Frame.Layout[4] = v; UpdateLayout(dbKey) end)

    do
        local btn = AG():Create("Button")
        btn:SetText("Drag to Reposition")
        btn:SetFullWidth(true)
        btn:SetCallback("OnClick", function() ToggleEditOverlay(dbKey) end)
        container:AddChild(btn)
    end

    AddHeader(container, "Spacing")

    if dbKey == "Party" then
        AddToggle(container, "Show Player", "Include your own frame in the party group",
            function() return db.ShowPlayer end,
            function(v)
                db.ShowPlayer = v
                local h = UUFPLUS.PartyHeader
                if h and not InCombatLockdown() then h:SetAttribute("showPlayer", v) end
            end)

        AddToggle(container, "Show when Solo", "Show frame when not in a group",
            function() return db.ShowSolo end,
            function(v)
                db.ShowSolo = v
                local h = UUFPLUS.PartyHeader
                if h and not InCombatLockdown() then h:SetAttribute("showSolo", v) end
            end)

        AddToggle(container, "Show in Raid", "Show party header when in a raid",
            function() return db.ShowInRaid end,
            function(v)
                db.ShowInRaid = v
                local h = UUFPLUS.PartyHeader
                if h then h:SetVisibility(v and "party" or "party,noraid") end
            end)

        AddSlider(container, "Frame Spacing", 0, 30, 1,
            function() return db.Frame.Spacing end,
            function(v) db.Frame.Spacing = v; UpdateFrameSize(dbKey) end)
    end

    if dbKey == "Raid" then
        AddSlider(container, "Columns", 1, 8, 1,
            function() return db.Frame.Columns end,
            function(v)
                db.Frame.Columns = v
                local h = UUFPLUS.RaidHeader
                if h and not InCombatLockdown() then h:SetAttribute("maxColumns", v) end
            end)

        AddSlider(container, "Units per Column", 1, 40, 1,
            function() return db.Frame.UnitsPerColumn end,
            function(v)
                db.Frame.UnitsPerColumn = v
                local h = UUFPLUS.RaidHeader
                if h and not InCombatLockdown() then h:SetAttribute("unitsPerColumn", v) end
            end)

        AddSlider(container, "Horizontal Spacing", 0, 20, 1,
            function() return db.Frame.SpacingX end,
            function(v) db.Frame.SpacingX = v; UpdateFrameSize(dbKey) end)

        AddSlider(container, "Vertical Spacing", 0, 20, 1,
            function() return db.Frame.SpacingY end,
            function(v) db.Frame.SpacingY = v; UpdateFrameSize(dbKey) end)
    end
end

local function RenderHealthTab(container, dbKey)
    local db = UUFPLUS.db.profile[dbKey]

    AddHeader(container, "Health Bar")

    AddToggle(container, "Color by Class", "Color health bar by class or reaction",
        function() return db.HealthBar.ColorByClass end,
        function(v) db.HealthBar.ColorByClass = v; UpdateFrames(dbKey) end)

    AddSlider(container, "Background Alpha", 0, 1, 0.01,
        function() return db.HealthBar.BackgroundAlpha end,
        function(v) db.HealthBar.BackgroundAlpha = v; UpdateFrames(dbKey) end)

    AddHeader(container, "Power Bar")

    AddToggle(container, "Enabled", "Show power bar (requires /reload to add if not present)",
        function() return db.PowerBar.Enabled end,
        function(v) db.PowerBar.Enabled = v; UpdateFrames(dbKey) end)

    AddToggle(container, "Healer Only", "Show power bar only for healers",
        function() return db.PowerBar.HealerOnly end,
        function(v) db.PowerBar.HealerOnly = v; UpdateFrames(dbKey) end)

    AddSlider(container, "Height", 2, 20, 1,
        function() return db.PowerBar.Height end,
        function(v) db.PowerBar.Height = v; UpdateFrames(dbKey) end)

    AddHeader(container, "Range Fader")

    AddSlider(container, "In-Range Alpha", 0, 1, 0.01,
        function() return db.Range.InRange end,
        function(v) db.Range.InRange = v; UpdateFrames(dbKey) end)

    AddSlider(container, "Out-of-Range Alpha", 0, 1, 0.01,
        function() return db.Range.OutOfRange end,
        function(v) db.Range.OutOfRange = v; UpdateFrames(dbKey) end)
end

local function RenderAbsorbsTab(container, dbKey)
    local db = UUFPLUS.db.profile[dbKey]

    AddHeader(container, "Absorbs / Heal Prediction")

    AddToggle(container, "Enabled", "Show absorb and heal-absorb bars (requires /reload to add)",
        function() return db.HealPrediction.Enabled end,
        function(v) db.HealPrediction.Enabled = v end)

    AddHeader(container, "Dispel Highlight")

    AddToggle(container, "Enabled", "Overlay dispellable debuffs with a colored highlight",
        function() return db.DispelHighlight.Enabled end,
        function(v) db.DispelHighlight.Enabled = v end)
end

local function RenderAurasTab(container, dbKey)
    local db = UUFPLUS.db.profile[dbKey]

    -- Debuffs ----------------------------------------------------------------
    AddHeader(container, "Debuff Icons")

    AddToggle(container, "Enabled", "Show dispel-type debuff icons",
        function() return db.Auras.Enabled end,
        function(v) db.Auras.Enabled = v; UpdateAuraVisibility(dbKey) end)

    AddSlider(container, "Icon Size", 8, 32, 1,
        function() return db.Auras.Size end,
        function(v) db.Auras.Size = v; UpdateFrames(dbKey) end)

    AddSlider(container, "Icon Spacing", 0, 10, 1,
        function() return db.Auras.Spacing end,
        function(v) db.Auras.Spacing = v; UpdateFrames(dbKey) end)

    AddSlider(container, "Max Debuffs", 1, 10, 1,
        function() return db.Auras.NumDebuffs end,
        function(v) db.Auras.NumDebuffs = v; UpdateFrames(dbKey) end)

    AddDropdown(container, "Anchor From", AnchorPoints[1], AnchorPoints[2],
        function() return db.Auras.Layout[1] or "BOTTOMRIGHT" end,
        function(v) db.Auras.Layout[1] = v; UpdateAuras(dbKey) end)

    AddDropdown(container, "Anchor To (frame)", AnchorPoints[1], AnchorPoints[2],
        function() return db.Auras.Layout[2] or "BOTTOMRIGHT" end,
        function(v) db.Auras.Layout[2] = v; UpdateAuras(dbKey) end)

    AddSlider(container, "X Offset", -200, 200, 1,
        function() return db.Auras.Layout[3] or 0 end,
        function(v) db.Auras.Layout[3] = v; UpdateAuras(dbKey) end)

    AddSlider(container, "Y Offset", -200, 200, 1,
        function() return db.Auras.Layout[4] or 0 end,
        function(v) db.Auras.Layout[4] = v; UpdateAuras(dbKey) end)

    AddHeader(container, "Debuff Growth Direction")

    AddDropdown(container, "Horizontal", GrowthXList[1], GrowthXList[2],
        function() return db.Auras.GrowthX or "LEFT" end,
        function(v) db.Auras.GrowthX = v; UpdateAuras(dbKey) end)

    AddDropdown(container, "Vertical", GrowthYList[1], GrowthYList[2],
        function() return db.Auras.GrowthY or "UP" end,
        function(v) db.Auras.GrowthY = v; UpdateAuras(dbKey) end)

    -- Buffs ------------------------------------------------------------------
    AddHeader(container, "Buff Icons")

    AddToggle(container, "Enabled", "Show buff icons",
        function() return db.Auras.BuffsEnabled end,
        function(v) db.Auras.BuffsEnabled = v; UpdateAuraVisibility(dbKey) end)

    AddSlider(container, "Max Buffs", 1, 10, 1,
        function() return db.Auras.NumBuffs end,
        function(v) db.Auras.NumBuffs = v; UpdateFrames(dbKey) end)

    AddDropdown(container, "Anchor From", AnchorPoints[1], AnchorPoints[2],
        function() return db.Auras.BuffsLayout[1] or "BOTTOMLEFT" end,
        function(v) db.Auras.BuffsLayout[1] = v; UpdateAuras(dbKey) end)

    AddDropdown(container, "Anchor To (frame)", AnchorPoints[1], AnchorPoints[2],
        function() return db.Auras.BuffsLayout[2] or "BOTTOMLEFT" end,
        function(v) db.Auras.BuffsLayout[2] = v; UpdateAuras(dbKey) end)

    AddSlider(container, "X Offset", -200, 200, 1,
        function() return db.Auras.BuffsLayout[3] or 0 end,
        function(v) db.Auras.BuffsLayout[3] = v; UpdateAuras(dbKey) end)

    AddSlider(container, "Y Offset", -200, 200, 1,
        function() return db.Auras.BuffsLayout[4] or 0 end,
        function(v) db.Auras.BuffsLayout[4] = v; UpdateAuras(dbKey) end)

    AddHeader(container, "Buff Growth Direction")

    AddDropdown(container, "Horizontal", GrowthXList[1], GrowthXList[2],
        function() return db.Auras.BuffsGrowthX or "RIGHT" end,
        function(v) db.Auras.BuffsGrowthX = v; UpdateAuras(dbKey) end)

    AddDropdown(container, "Vertical", GrowthYList[1], GrowthYList[2],
        function() return db.Auras.BuffsGrowthY or db.Auras.GrowthY or "UP" end,
        function(v) db.Auras.BuffsGrowthY = v; UpdateAuras(dbKey) end)
end

-- ── indicator sub-tab builder ─────────────────────────────────────────────────

local function RenderOneIndicator(container, dbKey, indKey, label)
    local db = UUFPLUS.db.profile[dbKey]
    local ind = db.Indicators[indKey]

    AddHeader(container, label)

    AddToggle(container, "Enabled", "Show this indicator",
        function() return ind.Enabled end,
        function(v) ind.Enabled = v; UpdateIndicators(dbKey) end)

    if indKey == "GroupRole" then
        AddToggle(container, "Hide DPS Icon", "Show role icon only for tanks and healers",
            function() return ind.HideDPS end,
            function(v) ind.HideDPS = v; UpdateIndicators(dbKey) end)
        AddToggle(container, "Hide in Combat", "Hide role icon while in combat",
            function() return ind.HideInCombat end,
            function(v) ind.HideInCombat = v; UpdateIndicators(dbKey) end)
    end

    AddSlider(container, "Size", 6, 32, 1,
        function() return ind.Size end,
        function(v) ind.Size = v; UpdateIndicators(dbKey) end)

    AddDropdown(container, "Anchor From", AnchorPoints[1], AnchorPoints[2],
        function() return ind.Layout[1] end,
        function(v) ind.Layout[1] = v; UpdateIndicators(dbKey) end)

    AddDropdown(container, "Anchor To (health bar)", AnchorPoints[1], AnchorPoints[2],
        function() return ind.Layout[2] end,
        function(v) ind.Layout[2] = v; UpdateIndicators(dbKey) end)

    AddSlider(container, "X Offset", -100, 100, 1,
        function() return ind.Layout[3] end,
        function(v) ind.Layout[3] = v; UpdateIndicators(dbKey) end)

    AddSlider(container, "Y Offset", -100, 100, 1,
        function() return ind.Layout[4] end,
        function(v) ind.Layout[4] = v; UpdateIndicators(dbKey) end)
end

local function RenderRaidMarkerTab(container, dbKey)
    local db  = UUFPLUS.db.profile[dbKey]
    local mDb = db.Indicators.RaidTargetMarker

    AddHeader(container, "Raid Target Marker")

    AddSlider(container, "Size", 8, 40, 1,
        function() return mDb.Size end,
        function(v) mDb.Size = v; UpdateIndicators(dbKey) end)

    AddDropdown(container, "Anchor From", AnchorPoints[1], AnchorPoints[2],
        function() return mDb.Layout[1] end,
        function(v) mDb.Layout[1] = v; UpdateIndicators(dbKey) end)

    AddDropdown(container, "Anchor To (frame)", AnchorPoints[1], AnchorPoints[2],
        function() return mDb.Layout[2] end,
        function(v) mDb.Layout[2] = v; UpdateIndicators(dbKey) end)

    AddSlider(container, "X Offset", -100, 100, 1,
        function() return mDb.Layout[3] end,
        function(v) mDb.Layout[3] = v; UpdateIndicators(dbKey) end)

    AddSlider(container, "Y Offset", -100, 100, 1,
        function() return mDb.Layout[4] end,
        function(v) mDb.Layout[4] = v; UpdateIndicators(dbKey) end)
end

local function RenderTargetIndicatorTab(container, dbKey)
    local tDb = UUFPLUS.db.profile[dbKey].Indicators.Target

    AddHeader(container, "Target Highlight")

    AddToggle(container, "Enabled", "Show a glow border around the targeted unit's frame",
        function() return tDb.Enabled end,
        function(v) tDb.Enabled = v; UpdateTargetGlow(dbKey) end)

    AddColorPicker(container, "Glow Color",
        function() return tDb.Colour[1] end,
        function() return tDb.Colour[2] end,
        function() return tDb.Colour[3] end,
        function(r, g, b)
            tDb.Colour[1], tDb.Colour[2], tDb.Colour[3] = r, g, b
            UpdateTargetGlow(dbKey)
        end)
end

local function RenderIndicatorsTab(outerContainer, dbKey)
    local tabs = {
        { text = "Target",      value = "Target"     },
        { text = "Group Role",  value = "GroupRole"  },
        { text = "Leader",      value = "Leader"      },
        { text = "Assistant",   value = "Assistant"   },
        { text = "Raid Role",   value = "RaidRole"    },
        { text = "Raid Marker", value = "RaidMarker"  },
    }
    local labels = {
        GroupRole = "Group Role (Tank/Healer/DPS)",
        Leader    = "Leader Icon",
        Assistant = "Assistant Icon",
        RaidRole  = "Raid Role (MT/MA)",
    }

    local tg = AG():Create("TabGroup")
    tg:SetTabs(tabs)
    tg:SetFullWidth(true)
    tg:SetFullHeight(true)
    tg:SetLayout("Fill")
    tg:SetCallback("OnGroupSelected", function(widget, _, selected)
        widget:ReleaseChildren()
        local scroll = CreateScrollFrame(widget)
        if selected == "Target" then
            RenderTargetIndicatorTab(scroll, dbKey)
        elseif selected == "RaidMarker" then
            RenderRaidMarkerTab(scroll, dbKey)
        else
            RenderOneIndicator(scroll, dbKey, selected, labels[selected])
        end
        scroll:DoLayout()
    end)
    outerContainer:AddChild(tg)
    tg:SelectTab("Target")
end

-- ── tag sub-tab builder ───────────────────────────────────────────────────────

local function RenderOneTag(container, dbKey, tagKey, label)
    local db = UUFPLUS.db.profile[dbKey]
    local t  = db.Tags[tagKey]

    AddHeader(container, label)

    AddEditBox(container, "Tag Expression",
        function() return t.Tag end,
        function(v) t.Tag = v; UpdateTags(dbKey) end)

    AddSlider(container, "Font Size", 6, 24, 1,
        function() return t.FontSize end,
        function(v) t.FontSize = v; UpdateTags(dbKey) end)

    AddColorPicker(container, "Text Color",
        function() return t.Colour[1] end,
        function() return t.Colour[2] end,
        function() return t.Colour[3] end,
        function(r, g, b)
            t.Colour[1], t.Colour[2], t.Colour[3] = r, g, b
            UpdateTags(dbKey)
        end)

    AddSpacer(container)

    AddHeader(container, "Position (relative to health bar)")

    AddDropdown(container, "Anchor From", AnchorPoints[1], AnchorPoints[2],
        function() return t.Layout[1] end,
        function(v) t.Layout[1] = v; UpdateTags(dbKey) end)

    AddDropdown(container, "Anchor To (health bar)", AnchorPoints[1], AnchorPoints[2],
        function() return t.Layout[2] end,
        function(v) t.Layout[2] = v; UpdateTags(dbKey) end)

    AddSlider(container, "X Offset", -500, 500, 1,
        function() return t.Layout[3] end,
        function(v) t.Layout[3] = v; UpdateTags(dbKey) end)

    AddSlider(container, "Y Offset", -100, 100, 1,
        function() return t.Layout[4] end,
        function(v) t.Layout[4] = v; UpdateTags(dbKey) end)
end

local function RenderTagsTab(outerContainer, dbKey)
    local tabs = {
        { text = "Name",        value = "Name"        },
        { text = "Status Text", value = "StatusText"  },
        { text = "Ready Check", value = "ReadyCheck"  },
    }
    if dbKey == "Party" then
        table.insert(tabs, 2, { text = "HP", value = "HP" })
    end

    local labels = { Name = "Name Tag", HP = "Health / Absorb Tag" }

    local tg = AG():Create("TabGroup")
    tg:SetTabs(tabs)
    tg:SetFullWidth(true)
    tg:SetFullHeight(true)
    tg:SetLayout("Fill")
    tg:SetCallback("OnGroupSelected", function(widget, _, selected)
        widget:ReleaseChildren()
        local scroll = CreateScrollFrame(widget)
        if selected == "StatusText" then
            AddHeader(scroll, "Status Text (Offline / Dead / Ghost / AFK)")
            AddSlider(scroll, "Font Size", 6, 24, 1,
                function() return UUFPLUS.db.profile[dbKey].OfflineFontSize or 10 end,
                function(v) UUFPLUS.db.profile[dbKey].OfflineFontSize = v; UpdateOfflineText(dbKey) end)
            AddHeader(scroll, "Position (relative to frame)")
            AddDropdown(scroll, "Anchor From", AnchorPoints[1], AnchorPoints[2],
                function() return UUFPLUS.db.profile[dbKey].StatusText.Layout[1] or "CENTER" end,
                function(v) UUFPLUS.db.profile[dbKey].StatusText.Layout[1] = v; UpdateOfflineText(dbKey) end)
            AddDropdown(scroll, "Anchor To (frame)", AnchorPoints[1], AnchorPoints[2],
                function() return UUFPLUS.db.profile[dbKey].StatusText.Layout[2] or "CENTER" end,
                function(v) UUFPLUS.db.profile[dbKey].StatusText.Layout[2] = v; UpdateOfflineText(dbKey) end)
            AddSlider(scroll, "X Offset", -200, 200, 1,
                function() return UUFPLUS.db.profile[dbKey].StatusText.Layout[3] or 0 end,
                function(v) UUFPLUS.db.profile[dbKey].StatusText.Layout[3] = v; UpdateOfflineText(dbKey) end)
            AddSlider(scroll, "Y Offset", -200, 200, 1,
                function() return UUFPLUS.db.profile[dbKey].StatusText.Layout[4] or 0 end,
                function(v) UUFPLUS.db.profile[dbKey].StatusText.Layout[4] = v; UpdateOfflineText(dbKey) end)
        elseif selected == "ReadyCheck" then
            AddHeader(scroll, "Ready Check Indicator")
            AddSlider(scroll, "Size", 8, 40, 1,
                function() return UUFPLUS.db.profile[dbKey].ReadyCheck.Size or 16 end,
                function(v) UUFPLUS.db.profile[dbKey].ReadyCheck.Size = v; UpdateReadyCheck(dbKey) end)
            AddHeader(scroll, "Position (relative to frame)")
            AddDropdown(scroll, "Anchor From", AnchorPoints[1], AnchorPoints[2],
                function() return UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[1] or "CENTER" end,
                function(v) UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[1] = v; UpdateReadyCheck(dbKey) end)
            AddDropdown(scroll, "Anchor To (frame)", AnchorPoints[1], AnchorPoints[2],
                function() return UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[2] or "CENTER" end,
                function(v) UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[2] = v; UpdateReadyCheck(dbKey) end)
            AddSlider(scroll, "X Offset", -200, 200, 1,
                function() return UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[3] or 0 end,
                function(v) UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[3] = v; UpdateReadyCheck(dbKey) end)
            AddSlider(scroll, "Y Offset", -200, 200, 1,
                function() return UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[4] or 0 end,
                function(v) UUFPLUS.db.profile[dbKey].ReadyCheck.Layout[4] = v; UpdateReadyCheck(dbKey) end)
        else
            RenderOneTag(scroll, dbKey, selected, labels[selected])
        end
        scroll:DoLayout()
    end)
    outerContainer:AddChild(tg)
    tg:SelectTab("Name")
end

-- ── top-level tab group per frame type ───────────────────────────────────────

local function RenderGroupFrameTabs(outerContainer, dbKey)
    local tabs = {
        { text = "Frame",       value = "frame"      },
        { text = "Health",      value = "health"     },
        { text = "Absorbs",     value = "absorbs"    },
        { text = "Auras",       value = "auras"      },
        { text = "Indicators",  value = "indicators" },
        { text = "Tags",        value = "tags"       },
    }

    local tg = AG():Create("TabGroup")
    tg:SetTabs(tabs)
    tg:SetFullWidth(true)
    tg:SetFullHeight(true)
    tg:SetLayout("Fill")
    tg:SetCallback("OnGroupSelected", function(widget, _, selected)
        widget:ReleaseChildren()
        if selected == "frame" then
            local scroll = CreateScrollFrame(widget)
            RenderFrameTab(scroll, dbKey)
            scroll:DoLayout()
        elseif selected == "health" then
            local scroll = CreateScrollFrame(widget)
            RenderHealthTab(scroll, dbKey)
            scroll:DoLayout()
        elseif selected == "absorbs" then
            local scroll = CreateScrollFrame(widget)
            RenderAbsorbsTab(scroll, dbKey)
            scroll:DoLayout()
        elseif selected == "auras" then
            local scroll = CreateScrollFrame(widget)
            RenderAurasTab(scroll, dbKey)
            scroll:DoLayout()
        elseif selected == "indicators" then
            RenderIndicatorsTab(widget, dbKey)
        elseif selected == "tags" then
            RenderTagsTab(widget, dbKey)
        end
    end)
    outerContainer:AddChild(tg)
    tg:SelectTab("frame")
end

-- ── registration ──────────────────────────────────────────────────────────────

function UUFPLUS:RegisterGUIExtensions()
    local UUF = UUFPLUS.UUF
    if not UUF then return end
    UUF.GUITabExtensions = UUF.GUITabExtensions or {}
    table.insert(UUF.GUITabExtensions, {
        tab    = { text = "Party", value = "UUFPlus_Party" },
        render = function(wrapper) RenderGroupFrameTabs(wrapper, "Party") end,
        onShow = function() UUFPLUS:ShowPartyPreview() end,
        onHide = function() UUFPLUS:HidePartyPreview() end,
    })
    table.insert(UUF.GUITabExtensions, {
        tab    = { text = "Raid", value = "UUFPlus_Raid" },
        render = function(wrapper) RenderGroupFrameTabs(wrapper, "Raid") end,
        onShow = function() UUFPLUS:ShowRaidPreview() end,
        onHide = function() UUFPLUS:HideRaidPreview() end,
    })
end
