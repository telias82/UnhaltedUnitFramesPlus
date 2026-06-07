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

local function CreateScrollFrame(parent)
    local AG = UUFPLUS.UUF and UUFPLUS.UUF.AG
    if not AG then return parent end
    local scroll = AG:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    parent:AddChild(scroll)
    return scroll
end

local function AddHeader(parent, text)
    local AG = UUFPLUS.UUF.AG
    local label = AG:Create("Heading")
    label:SetText(text)
    label:SetFullWidth(true)
    parent:AddChild(label)
end

local function AddToggle(parent, label, desc, get, set)
    local AG = UUFPLUS.UUF.AG
    local cb = AG:Create("CheckBox")
    cb:SetLabel(label)
    cb:SetDescription(desc)
    cb:SetValue(get())
    cb:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    cb:SetRelativeWidth(0.5)
    parent:AddChild(cb)
end

local function AddSlider(parent, label, min, max, step, get, set)
    local AG = UUFPLUS.UUF.AG
    local sl = AG:Create("Slider")
    sl:SetLabel(label)
    sl:SetSliderValues(min, max, step)
    sl:SetValue(get())
    sl:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    sl:SetRelativeWidth(0.5)
    parent:AddChild(sl)
end

local function AddDropdown(parent, label, list, listOrder, get, set)
    local AG = UUFPLUS.UUF.AG
    local dd = AG:Create("Dropdown")
    dd:SetLabel(label)
    dd:SetList(list, listOrder)
    dd:SetValue(get())
    dd:SetCallback("OnValueChanged", function(_, _, val) set(val) end)
    dd:SetRelativeWidth(0.5)
    parent:AddChild(dd)
end

-- Build the common settings section shared between party and raid tabs.
local function CreateGroupFrameSettings(container, dbKey)
    local db = UUFPLUS.db.profile[dbKey]
    local AG = UUFPLUS.UUF.AG

    -- === Frame ===
    AddHeader(container, "Frame")

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
        function(v) db.Frame.Width = v end)

    AddSlider(container, "Height", 12, 200, 1,
        function() return db.Frame.Height end,
        function(v) db.Frame.Height = v end)

    AddDropdown(container, "Frame Strata", FrameStrataList[1], FrameStrataList[2],
        function() return db.Frame.FrameStrata end,
        function(v) db.Frame.FrameStrata = v end)

    -- Position inputs
    AddHeader(container, "Position (requires /reload to apply)")

    AddDropdown(container, "Anchor Point", AnchorPoints[1], AnchorPoints[2],
        function() return db.Frame.Layout[1] end,
        function(v) db.Frame.Layout[1] = v end)

    AddDropdown(container, "Relative Anchor", AnchorPoints[1], AnchorPoints[2],
        function() return db.Frame.Layout[2] end,
        function(v) db.Frame.Layout[2] = v end)

    AddSlider(container, "X Offset", -2000, 2000, 1,
        function() return db.Frame.Layout[3] end,
        function(v) db.Frame.Layout[3] = v end)

    AddSlider(container, "Y Offset", -2000, 2000, 1,
        function() return db.Frame.Layout[4] end,
        function(v) db.Frame.Layout[4] = v end)

    -- === Health Bar ===
    AddHeader(container, "Health Bar")

    AddToggle(container, "Color by Class", "Color health bar by unit class/reaction",
        function() return db.HealthBar.ColorByClass end,
        function(v) db.HealthBar.ColorByClass = v end)

    AddSlider(container, "Background Alpha", 0, 1, 0.01,
        function() return db.HealthBar.BackgroundAlpha end,
        function(v) db.HealthBar.BackgroundAlpha = v end)

    -- === Power Bar ===
    AddHeader(container, "Power Bar")

    AddToggle(container, "Enabled", "Show power bar below health",
        function() return db.PowerBar.Enabled end,
        function(v) db.PowerBar.Enabled = v end)

    AddSlider(container, "Height", 2, 20, 1,
        function() return db.PowerBar.Height end,
        function(v) db.PowerBar.Height = v end)

    -- === Absorbs ===
    AddHeader(container, "Absorbs / Heal Prediction")

    AddToggle(container, "Enabled", "Show damage absorb and heal absorb bars",
        function() return db.HealPrediction.Enabled end,
        function(v) db.HealPrediction.Enabled = v end)

    -- === Dispel Highlight ===
    AddHeader(container, "Dispel Highlight")

    AddToggle(container, "Enabled", "Highlight dispellable debuffs with a colored overlay",
        function() return db.DispelHighlight.Enabled end,
        function(v) db.DispelHighlight.Enabled = v end)

    -- === Auras ===
    AddHeader(container, "Debuff Icons")

    AddToggle(container, "Enabled", "Show dispel-type debuff icons above frames",
        function() return db.Auras.Enabled end,
        function(v) db.Auras.Enabled = v end)

    AddSlider(container, "Icon Size", 8, 32, 1,
        function() return db.Auras.Size end,
        function(v) db.Auras.Size = v end)

    AddSlider(container, "Icon Spacing", 0, 10, 1,
        function() return db.Auras.Spacing end,
        function(v) db.Auras.Spacing = v end)

    AddSlider(container, "Max Debuffs", 1, 10, 1,
        function() return db.Auras.NumDebuffs end,
        function(v) db.Auras.NumDebuffs = v end)

    -- === Range ===
    AddHeader(container, "Range Fader")

    AddSlider(container, "In-Range Alpha", 0, 1, 0.01,
        function() return db.Range.InRange end,
        function(v) db.Range.InRange = v end)

    AddSlider(container, "Out-of-Range Alpha", 0, 1, 0.01,
        function() return db.Range.OutOfRange end,
        function(v) db.Range.OutOfRange = v end)

    -- Spacing (party only)
    if dbKey == "Party" then
        AddHeader(container, "Layout")

        AddToggle(container, "Show Player in Party", "Include the player frame in the party group",
            function() return db.ShowPlayer end,
            function(v) db.ShowPlayer = v end)

        AddToggle(container, "Show when Solo", "Show party frame when you have no group",
            function() return db.ShowSolo end,
            function(v) db.ShowSolo = v end)

        AddToggle(container, "Show in Raid", "Show party header when you are in a raid",
            function() return db.ShowInRaid end,
            function(v) db.ShowInRaid = v end)

        AddSlider(container, "Frame Spacing", 0, 30, 1,
            function() return db.Frame.Spacing end,
            function(v) db.Frame.Spacing = v end)
    end

    -- Raid-specific layout options
    if dbKey == "Raid" then
        AddHeader(container, "Raid Layout")

        AddSlider(container, "Columns", 1, 8, 1,
            function() return db.Frame.Columns end,
            function(v) db.Frame.Columns = v end)

        AddSlider(container, "Units per Column", 1, 40, 1,
            function() return db.Frame.UnitsPerColumn end,
            function(v) db.Frame.UnitsPerColumn = v end)

        AddSlider(container, "Horizontal Spacing", 0, 20, 1,
            function() return db.Frame.SpacingX end,
            function(v) db.Frame.SpacingX = v end)

        AddSlider(container, "Vertical Spacing", 0, 20, 1,
            function() return db.Frame.SpacingY end,
            function(v) db.Frame.SpacingY = v end)
    end

    local note = AG:Create("Label")
    note:SetText("|cFFFFCC00Note:|r Most layout changes require |cFF8080FF/reload|r to take effect.")
    note:SetFullWidth(true)
    container:AddChild(note)
end

local function RenderPartyTab(wrapper)
    local scroll = CreateScrollFrame(wrapper)
    CreateGroupFrameSettings(scroll, "Party")
    scroll:DoLayout()
end

local function RenderRaidTab(wrapper)
    local scroll = CreateScrollFrame(wrapper)
    CreateGroupFrameSettings(scroll, "Raid")
    scroll:DoLayout()
end

function UUFPLUS:RegisterGUIExtensions()
    local UUF = UUFPLUS.UUF
    if not UUF then return end
    UUF.GUITabExtensions = UUF.GUITabExtensions or {}
    table.insert(UUF.GUITabExtensions, {
        tab    = { text = "Party", value = "UUFPlus_Party" },
        render = RenderPartyTab,
    })
    table.insert(UUF.GUITabExtensions, {
        tab    = { text = "Raid", value = "UUFPlus_Raid" },
        render = RenderRaidTab,
    })
end
