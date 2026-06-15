local UUFPLUS = _G.UUFPLUS

local partyPreviews  = {}
local raidPreviews   = {}
local refreshPending = {}

local function ScheduleRefresh(dbKey)
    if refreshPending[dbKey] then return end
    refreshPending[dbKey] = true
    C_Timer.After(0, function()
        refreshPending[dbKey] = false
        if dbKey == "Party" then
            if #partyPreviews > 0 then
                UUFPLUS:HidePartyPreview()
                UUFPLUS:ShowPartyPreview()
            end
        else
            if #raidPreviews > 0 then
                UUFPLUS:HideRaidPreview()
                UUFPLUS:ShowRaidPreview()
            end
        end
    end)
end

function UUFPLUS:RefreshPreviewIfShown(dbKey)
    ScheduleRefresh(dbKey)
end

local PARTY_NAMES = { "Player 1", "Player 2", "Player 3", "Player 4", "Player 5" }
local RAID_NAMES  = {
    "Player 1",  "Player 2",  "Player 3",  "Player 4",  "Player 5",
    "Player 6",  "Player 7",  "Player 8",  "Player 9",  "Player 10",
    "Player 11", "Player 12", "Player 13", "Player 14", "Player 15",
    "Player 16", "Player 17", "Player 18", "Player 19", "Player 20",
    "Player 21", "Player 22", "Player 23", "Player 24", "Player 25",
    "Player 26", "Player 27", "Player 28", "Player 29", "Player 30",
    "Player 31", "Player 32", "Player 33", "Player 34", "Player 35",
    "Player 36", "Player 37", "Player 38", "Player 39", "Player 40",
}

local ROLE_COLORS = {
    TANK    = { 0.0,  0.44, 0.87 },
    HEALER  = { 0.67, 0.83, 0.45 },
    DAMAGER = { 0.78, 0.61, 0.43 },
}

local function GetPreviewRole(idx)
    if     idx == 1 then return "TANK"
    elseif idx == 2 then return "HEALER"
    else               return "DAMAGER"
    end
end

local ROLE_ATLAS = {
    TANK    = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
    HEALER  = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
    DAMAGER = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
}

local function ApplyRoleIcon(icon, role, size)
    icon:SetSize(size, size)
    local atlas = ROLE_ATLAS[role]
    if atlas then
        icon:SetAtlas(atlas)
        icon:Show()
    else
        icon:Hide()
    end
end

local function AddFakeAuras(f, auraDb, isDebuff, gap)
    local enabled = isDebuff and auraDb.Enabled or auraDb.BuffsEnabled
    if not enabled then return end

    local size    = auraDb.Size
    local spacing = auraDb.Spacing
    local num     = isDebuff and auraDb.NumDebuffs or auraDb.NumBuffs
    local layout  = isDebuff and auraDb.Layout or auraDb.BuffsLayout
    local gx      = isDebuff and (auraDb.GrowthX or "LEFT") or (auraDb.BuffsGrowthX or "RIGHT")

    local anchor    = layout[1] or (isDebuff and "BOTTOMRIGHT" or "BOTTOMLEFT")
    local relAnchor = layout[2] or anchor
    local xOff      = layout[3] or 0
    local yOff      = (layout[4] or 0) + (anchor:find("BOTTOM") and (gap or 0) or 0)

    local prev = nil
    for i = 1, num do
        local icon = f:CreateTexture(nil, "OVERLAY", nil, 2)
        icon:SetSize(size, size)
        if i == 1 then
            icon:SetPoint(anchor, f, relAnchor, xOff, yOff)
        elseif gx == "LEFT" then
            icon:SetPoint("RIGHT", prev, "LEFT", -spacing, 0)
        else
            icon:SetPoint("LEFT", prev, "RIGHT", spacing, 0)
        end
        icon:SetTexture([[Interface\Buttons\WHITE8X8]])
        if isDebuff then
            icon:SetVertexColor(0.85, 0.15, 0.15, 0.9)
        else
            icon:SetVertexColor(0.15, 0.55, 0.95, 0.9)
        end
        prev = icon
    end
end

local function BuildDummyFrame(db, name, role)
    local UUF    = UUFPLUS.UUF
    local w, h   = db.Frame.Width, db.Frame.Height
    local powerH = db.PowerBar.Enabled and db.PowerBar.Height or 0

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetBackdrop(UUF.BACKDROP)
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:SetFrameStrata(db.Frame.FrameStrata)

    local showPower = db.PowerBar.Enabled and (not db.PowerBar.HealerOnly or role == "HEALER")
    local healthGap = showPower and (powerH > 0 and powerH + 1 or 0) or 0

    local health = CreateFrame("StatusBar", nil, f)
    health:SetStatusBarTexture(UUF.Media.Foreground)
    health:SetPoint("TOPLEFT",     f,  1,  -1)
    health:SetPoint("BOTTOMRIGHT", f, -1,   1 + healthGap)
    health:SetMinMaxValues(0, 100)
    health:SetValue(75)
    local rc = ROLE_COLORS[role] or ROLE_COLORS.DAMAGER
    health:SetStatusBarColor(rc[1], rc[2], rc[3])

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints(health)
    healthBG:SetTexture(UUF.Media.Background)
    healthBG:SetVertexColor(0.15, 0.15, 0.15, db.HealthBar.BackgroundAlpha)

    if showPower then
        local power = CreateFrame("StatusBar", nil, f)
        power:SetStatusBarTexture(UUF.Media.Foreground)
        power:SetPoint("BOTTOMLEFT",  f,  1, 1)
        power:SetPoint("BOTTOMRIGHT", f, -1, 1)
        power:SetHeight(powerH)
        power:SetMinMaxValues(0, 100)
        power:SetValue(60)
        power:SetStatusBarColor(0.0, 0.44, 1.0)
        local powerBG = power:CreateTexture(nil, "BACKGROUND")
        powerBG:SetAllPoints(power)
        powerBG:SetTexture(UUF.Media.Background)
        powerBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    end

    do
        local t  = db.Tags.Name
        local fs = health:CreateFontString(nil, "OVERLAY")
        fs:SetFont(UUF.Media.Font, t.FontSize, UUF.Media.FontFlag)
        local L  = t.Layout
        fs:SetPoint(L[1], health, L[2], L[3], L[4])
        fs:SetJustifyH(L[1]:find("RIGHT") and "RIGHT" or "LEFT")
        fs:SetWordWrap(false)
        local C = t.Colour
        fs:SetTextColor(C[1], C[2], C[3])
        fs:SetText(name)
    end

    if db.Tags and db.Tags.HP then
        local t  = db.Tags.HP
        local fs = health:CreateFontString(nil, "OVERLAY")
        fs:SetFont(UUF.Media.Font, t.FontSize, UUF.Media.FontFlag)
        local L  = t.Layout
        fs:SetPoint(L[1], health, L[2], L[3], L[4])
        fs:SetJustifyH(L[1]:find("RIGHT") and "RIGHT" or "LEFT")
        fs:SetWordWrap(false)
        local C = t.Colour
        fs:SetTextColor(C[1], C[2], C[3])
        fs:SetText("75%")
    end

    if db.Indicators and db.Indicators.GroupRole and db.Indicators.GroupRole.Enabled then
        local indDb = db.Indicators.GroupRole
        local L     = indDb.Layout
        local icon  = health:CreateTexture(nil, "OVERLAY", nil, 2)
        icon:SetPoint(L[1] or "BOTTOMRIGHT", health, L[2] or L[1] or "BOTTOMRIGHT", L[3] or 0, L[4] or 0)
        if role == "DAMAGER" and indDb.HideDPS then
            icon:Hide()
        else
            ApplyRoleIcon(icon, role, indDb.Size)
        end
    end

    if db.Auras then
        AddFakeAuras(f, db.Auras, true,  healthGap)
        AddFakeAuras(f, db.Auras, false, healthGap)
    end

    return f
end

function UUFPLUS:IsPartyPreviewShown()
    return #partyPreviews > 0
end

function UUFPLUS:IsRaidPreviewShown()
    return #raidPreviews > 0
end

function UUFPLUS:ShowPartyPreview()
    if #partyPreviews > 0 then return end
    local db      = UUFPLUS.db.profile.Party
    local spacing = db.Frame.Spacing
    local layout  = db.Frame.Layout

    local function onDragStop()
        local anchor = partyPreviews[1]
        if not anchor then return end
        anchor:StopMovingOrSizing()
        local point, _, relPoint, x, y = anchor:GetPoint()
        if not point then return end
        db.Frame.Layout[1] = point
        db.Frame.Layout[2] = relPoint or point
        db.Frame.Layout[3] = math.floor(x + 0.5)
        db.Frame.Layout[4] = math.floor(y + 0.5)
        if UUFPLUS.PartyHeader then
            UUFPLUS.PartyHeader:ClearAllPoints()
            UUFPLUS.PartyHeader:SetPoint(point, UIParent, relPoint or point, x, y)
        end
    end

    local prev = nil
    for i = 1, 5 do
        local f = BuildDummyFrame(db, PARTY_NAMES[i], GetPreviewRole(i))
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        if i == 1 then
            f:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
            f:SetMovable(true)
            f:SetClampedToScreen(true)
            f:SetScript("OnDragStart", function(self) self:StartMoving() end)
            f:SetScript("OnDragStop",  function(self) onDragStop() end)
        else
            f:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
            f:SetScript("OnDragStart", function(self) partyPreviews[1]:StartMoving() end)
            f:SetScript("OnDragStop",  function(self) onDragStop() end)
        end
        table.insert(partyPreviews, f)
        prev = f
    end
end

function UUFPLUS:HidePartyPreview()
    for _, f in ipairs(partyPreviews) do f:Hide() end
    partyPreviews = {}
end

function UUFPLUS:ShowRaidPreview()
    if #raidPreviews > 0 then return end
    local db     = UUFPLUS.db.profile.Raid
    local w, h   = db.Frame.Width, db.Frame.Height
    local sx, sy = db.Frame.SpacingX, db.Frame.SpacingY
    local cols   = db.Frame.Columns
    local upc    = db.Frame.UnitsPerColumn
    local layout = db.Frame.Layout

    local function onDragStop()
        local anchor = raidPreviews[1]
        if not anchor then return end
        anchor:StopMovingOrSizing()
        local point, _, relPoint, x, y = anchor:GetPoint()
        if not point then return end
        db.Frame.Layout[1] = point
        db.Frame.Layout[2] = relPoint or point
        db.Frame.Layout[3] = math.floor(x + 0.5)
        db.Frame.Layout[4] = math.floor(y + 0.5)
        if UUFPLUS.RaidHeader then
            UUFPLUS.RaidHeader:ClearAllPoints()
            UUFPLUS.RaidHeader:SetPoint(point, UIParent, relPoint or point, x, y)
        end
    end

    -- Invisible container lets the whole grid share the header's anchor point.
    local container = CreateFrame("Frame", nil, UIParent)
    container:SetSize(
        cols * w + math.max(0, cols - 1) * sx,
        upc  * h + math.max(0, upc  - 1) * sy)
    container:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self) self:StartMoving() end)
    container:SetScript("OnDragStop",  function(self) onDragStop() end)
    table.insert(raidPreviews, container)

    local idx = 0
    for col = 0, cols - 1 do
        local colRef = nil
        for row = 0, upc - 1 do
            idx = idx + 1
            if idx > 40 then break end
            local f = BuildDummyFrame(db, RAID_NAMES[idx] or ("P" .. idx), GetPreviewRole(idx))
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", function(self) raidPreviews[1]:StartMoving() end)
            f:SetScript("OnDragStop",  function(self) onDragStop() end)
            if row == 0 then
                f:SetPoint("TOPLEFT", container, "TOPLEFT", col * (w + sx), 0)
                colRef = f
            else
                f:SetPoint("TOP", colRef, "BOTTOM", 0, -sy)
                colRef = f
            end
            table.insert(raidPreviews, f)
        end
        if idx >= 40 then break end
    end
end

function UUFPLUS:HideRaidPreview()
    for _, f in ipairs(raidPreviews) do f:Hide() end
    raidPreviews = {}
end
