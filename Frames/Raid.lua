local UUFPLUS = _G.UUFPLUS

local function CreateRaidFrame(self)
    local UUF = UUFPLUS.UUF
    local db = UUFPLUS.db.profile.Raid
    local powerH = db.PowerBar.Enabled and db.PowerBar.Height or 0

    -- Background
    self:SetBackdrop(UUF.BACKDROP)
    self:SetBackdropColor(0, 0, 0, 0.85)
    self:SetBackdropBorderColor(0, 0, 0, 1)

    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetStatusBarTexture(UUF.Media.Foreground)
    health:SetPoint("TOPLEFT", self, 1, -1)
    health:SetPoint("BOTTOMRIGHT", self, -1, 1 + (powerH > 0 and powerH + 1 or 0))
    health.frequentUpdates = true
    health.colorClass    = db.HealthBar.ColorByClass
    health.colorReaction = db.HealthBar.ColorByClass

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints(health)
    healthBG:SetTexture(UUF.Media.Background)
    healthBG:SetVertexColor(0.15, 0.15, 0.15, db.HealthBar.BackgroundAlpha)
    health.bg = healthBG
    self.Health = health

    -- Power bar
    if db.PowerBar.Enabled then
        local power = CreateFrame("StatusBar", nil, self)
        power:SetStatusBarTexture(UUF.Media.Foreground)
        power:SetPoint("BOTTOMLEFT", self, 1, 1)
        power:SetPoint("BOTTOMRIGHT", self, -1, 1)
        power:SetHeight(powerH)
        power.frequentUpdates = true
        power.colorPower = true

        local powerBG = power:CreateTexture(nil, "BACKGROUND")
        powerBG:SetAllPoints(power)
        powerBG:SetTexture(UUF.Media.Background)
        powerBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        power.bg = powerBG
        self.Power = power
    end

    -- Damage absorb prediction
    if db.HealPrediction.Enabled then
        local absorbColor = db.HealPrediction.AbsorbColor
        local absorbBar = CreateFrame("StatusBar", nil, health)
        absorbBar:SetPoint("TOPRIGHT", health, "TOPRIGHT", 0, 0)
        absorbBar:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", 0, 0)
        absorbBar:SetWidth(200)
        absorbBar:SetStatusBarTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Atrocity.tga")
        absorbBar:SetStatusBarColor(absorbColor[1], absorbColor[2], absorbColor[3], absorbColor[4])
        absorbBar:SetReverseFill(true)

        local healAbsorbColor = db.HealPrediction.HealAbsorbColor
        local healAbsorbBar = CreateFrame("StatusBar", nil, health)
        healAbsorbBar:SetPoint("TOPRIGHT", health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        healAbsorbBar:SetPoint("BOTTOMRIGHT", health:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
        healAbsorbBar:SetWidth(200)
        healAbsorbBar:SetStatusBarTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Atrocity.tga")
        healAbsorbBar:SetStatusBarColor(healAbsorbColor[1], healAbsorbColor[2], healAbsorbColor[3], healAbsorbColor[4])
        healAbsorbBar:SetReverseFill(true)

        self.HealthPrediction = {
            damageAbsorb          = absorbBar,
            damageAbsorbClampMode = 2,
            healAbsorb            = healAbsorbBar,
            healAbsorbClampMode   = 1,
            healAbsorbMode        = 1,
            incomingHealOverflow  = 1,
        }
    end

    -- Dispel highlight (reuses the element registered in Party.lua)
    if db.DispelHighlight.Enabled then
        local highlight = health:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints(health)
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetBlendMode("BLEND")
        highlight:SetAlpha(0.75)
        highlight:Hide()
        self._dispelHighlight = highlight

        -- Build color table
        self._dispelColorCurve = {}
        local oUF = UUFPLUS.oUF
        if oUF and oUF.Enum and oUF.Enum.DispelType then
            local dispelTypeMap = {
                Magic   = oUF.Enum.DispelType.Magic,
                Curse   = oUF.Enum.DispelType.Curse,
                Disease = oUF.Enum.DispelType.Disease,
                Poison  = oUF.Enum.DispelType.Poison,
                Bleed   = oUF.Enum.DispelType.Bleed,
            }
            for dispelType, index in pairs(dispelTypeMap) do
                local color = oUF.colors.dispel[index]
                if color then self._dispelColorCurve[dispelType] = color end
            end
        end
    end

    -- Debuffs above the frame
    if db.Auras.Enabled then
        local debuffs = CreateFrame("Frame", nil, self)
        debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        debuffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)
        debuffs:SetHeight(db.Auras.Size + 4)
        debuffs.num            = db.Auras.NumDebuffs
        debuffs.size           = db.Auras.Size
        debuffs.spacing        = db.Auras.Spacing
        debuffs.initialAnchor  = "BOTTOMLEFT"
        debuffs["growth-x"]    = "RIGHT"
        debuffs["growth-y"]    = "UP"
        debuffs.filter         = "HARMFUL|RAID"
        debuffs.showDebuffType = true
        debuffs.disableMouse   = true
        self.Debuffs = debuffs
    end

    -- Raid target indicator
    local raidMarker = self:CreateTexture(nil, "OVERLAY")
    raidMarker:SetSize(12, 12)
    raidMarker:SetPoint("TOPRIGHT", self, 2, 2)
    self.RaidTargetIndicator = raidMarker

    -- Name tag (truncated, small font)
    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(UUF.Media.Font, 9, UUF.Media.FontFlag)
    nameText:SetPoint("LEFT", health, 2, 0)
    nameText:SetPoint("RIGHT", health, -2, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    self:Tag(nameText, "[name]")

    -- Range fader
    self.Range = {
        insideAlpha  = db.Range.InRange,
        outsideAlpha = db.Range.OutOfRange,
    }

    -- Click bindings
    self:RegisterForClicks("AnyUp")
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "togglemenu")
    self:HookScript("OnEnter", UnitFrame_OnEnter)
    self:HookScript("OnLeave", UnitFrame_OnLeave)
end

function UUFPLUS:SpawnRaidFrames()
    local oUF = UUFPLUS.oUF
    local db = UUFPLUS.db.profile.Raid
    if not db.Enabled then return end

    local w, h       = db.Frame.Width, db.Frame.Height
    local sx, sy     = db.Frame.SpacingX, db.Frame.SpacingY
    local cols       = db.Frame.Columns
    local upc        = db.Frame.UnitsPerColumn

    oUF:RegisterStyle("UUF_Plus_Raid", function(self) CreateRaidFrame(self) end)
    oUF:SetActiveStyle("UUF_Plus_Raid")

    UUFPLUS.RaidHeader = oUF:SpawnHeader(
        "UUF_Plus_RaidHeader",
        nil,
        "raid",
        "showSolo",          db.ShowSolo,
        "showPlayer",        true,
        "showRaid",          true,
        "point",             "TOP",
        "xOffset",           0,
        "yOffset",           -(h + sy),
        "maxColumns",        cols,
        "unitsPerColumn",    upc,
        "columnSpacing",     sx,
        "columnAnchorPoint", "LEFT",
        "groupingOrder",     "1,2,3,4,5,6,7,8",
        "groupBy",           "GROUP",
        "oUF-initialConfigFunction", string.format([[
            self:SetWidth(%d)
            self:SetHeight(%d)
        ]], w, h)
    )

    local layout = db.Frame.Layout
    UUFPLUS.RaidHeader:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    UUFPLUS.RaidHeader:SetFrameStrata(db.Frame.FrameStrata)

    -- HideBlizzard is shared with party; only call once (party handles it if enabled there too)
    if db.HideBlizzard and not (UUFPLUS.db.profile.Party.Enabled and UUFPLUS.db.profile.Party.HideBlizzard) then
        UUFPLUS:HideBlizzardGroupFrames()
    end
end
