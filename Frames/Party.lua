local UUFPLUS = _G.UUFPLUS

-- oUF element: dispel highlight for party/raid frames.
-- Only activates on frames that have self._dispelHighlight set (UUFPLUS frames).
local function UpdateDispelHighlight(self, event, unitArg)
    local highlight = self._dispelHighlight
    if not highlight then return end

    local unit = self.unit
    if not unit or not UnitExists(unit) then
        highlight:Hide()
        return
    end

    if not UnitIsFriend("player", unit) then
        highlight:Hide()
        return
    end

    local LibDispel = UUFPLUS.UUF and UUFPLUS.UUF.LD
    if not LibDispel then
        highlight:Hide()
        return
    end

    local dispelList = LibDispel:GetMyDispelTypes()
    local colorCurve = self._dispelColorCurve

    local i = 1
    while true do
        local name, _, _, debuffType = UnitDebuff(unit, i)
        if not name then break end
        if debuffType and debuffType ~= "" and dispelList[debuffType] then
            local color = colorCurve and colorCurve[debuffType]
            if color then
                highlight:SetVertexColor(color.r, color.g, color.b)
                highlight:Show()
                return
            end
        end
        i = i + 1
    end

    highlight:Hide()
end

local function EnableDispelHighlight(self)
    if not self._dispelHighlight then return end
    self:RegisterUnitEvent("UNIT_AURA", UpdateDispelHighlight)
    self:RegisterEvent("SPELLS_CHANGED", UpdateDispelHighlight, true)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", UpdateDispelHighlight, true)
    return true
end

local function DisableDispelHighlight(self)
    self:UnregisterEvent("UNIT_AURA", UpdateDispelHighlight)
    self:UnregisterEvent("SPELLS_CHANGED", UpdateDispelHighlight)
    self:UnregisterEvent("PLAYER_TALENT_UPDATE", UpdateDispelHighlight)
end

-- Register once at file-load time so the element is available for all spawned frames.
local oUF = _G.UUF and _G.UUF.oUF
if oUF then
    oUF:AddElement("UUFPlusDispelHighlight", UpdateDispelHighlight, EnableDispelHighlight, DisableDispelHighlight)
end

local function BuildDispelColorCurve(self)
    local oUF = UUFPLUS.oUF
    self._dispelColorCurve = {}
    if not (oUF and oUF.Enum and oUF.Enum.DispelType) then return end
    local dispelTypeMap = {
        Magic   = oUF.Enum.DispelType.Magic,
        Curse   = oUF.Enum.DispelType.Curse,
        Disease = oUF.Enum.DispelType.Disease,
        Poison  = oUF.Enum.DispelType.Poison,
        Bleed   = oUF.Enum.DispelType.Bleed,
    }
    for dispelType, index in pairs(dispelTypeMap) do
        local color = oUF.colors.dispel[index]
        if color then
            self._dispelColorCurve[dispelType] = color
        end
    end
end

local function CreatePartyFrame(self)
    local UUF = UUFPLUS.UUF
    local db = UUFPLUS.db.profile.Party
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
    health.colorClass = db.HealthBar.ColorByClass
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

    -- Heal/damage absorb prediction
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
            damageAbsorb      = absorbBar,
            damageAbsorbClampMode = 2,
            healAbsorb        = healAbsorbBar,
            healAbsorbClampMode   = 1,
            healAbsorbMode        = 1,
            incomingHealOverflow  = 1,
        }
    end

    -- Dispel highlight (texture over health bar; activated by UUFPlusDispelHighlight element)
    if db.DispelHighlight.Enabled then
        local highlight = health:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints(health)
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetBlendMode("BLEND")
        highlight:SetAlpha(0.75)
        highlight:Hide()
        self._dispelHighlight = highlight
        BuildDispelColorCurve(self)
    end

    -- Debuffs (dispel-type colored icons above frame)
    if db.Auras.Enabled then
        local debuffs = CreateFrame("Frame", nil, self)
        debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        debuffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 2)
        debuffs:SetHeight(db.Auras.Size + 4)
        debuffs.num           = db.Auras.NumDebuffs
        debuffs.size          = db.Auras.Size
        debuffs.spacing       = db.Auras.Spacing
        debuffs.initialAnchor = "BOTTOMLEFT"
        debuffs["growth-x"]   = "RIGHT"
        debuffs["growth-y"]   = "UP"
        debuffs.filter        = "HARMFUL|RAID"
        debuffs.showDebuffType = true
        debuffs.disableMouse  = true
        self.Debuffs = debuffs
    end

    -- Raid target indicator
    local raidMarker = self:CreateTexture(nil, "OVERLAY")
    raidMarker:SetSize(16, 16)
    raidMarker:SetPoint("TOPRIGHT", self, 2, 2)
    self.RaidTargetIndicator = raidMarker

    -- Name tag (left, truncated)
    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(UUF.Media.Font, 10, UUF.Media.FontFlag)
    nameText:SetPoint("LEFT", health, 2, 1)
    nameText:SetPoint("RIGHT", health, -22, 1)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    self:Tag(nameText, "[name]")

    -- Health percent tag (right)
    local hpText = health:CreateFontString(nil, "OVERLAY")
    hpText:SetFont(UUF.Media.Font, 9, UUF.Media.FontFlag)
    hpText:SetPoint("RIGHT", health, -2, -1)
    hpText:SetJustifyH("RIGHT")
    self:Tag(hpText, "[perhp]")

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

function UUFPLUS:SpawnPartyFrames()
    local oUF = UUFPLUS.oUF
    local db = UUFPLUS.db.profile.Party
    if not db.Enabled then return end

    local w, h = db.Frame.Width, db.Frame.Height
    local spacing = db.Frame.Spacing

    oUF:RegisterStyle("UUF_Plus_Party", function(self) CreatePartyFrame(self) end)
    oUF:SetActiveStyle("UUF_Plus_Party")

    UUFPLUS.PartyHeader = oUF:SpawnHeader(
        "UUF_Plus_PartyHeader",
        nil,
        "party,noraid",
        "showSolo",   db.ShowSolo,
        "showPlayer", db.ShowPlayer,
        "showRaid",   db.ShowInRaid,
        "point",      "LEFT",
        "xOffset",    w + spacing,
        "yOffset",    0,
        "maxColumns", 1,
        "unitsPerColumn", 5,
        "columnSpacing",  0,
        "columnAnchorPoint", "TOP",
        "oUF-initialConfigFunction", string.format([[
            self:SetWidth(%d)
            self:SetHeight(%d)
        ]], w, h)
    )

    local layout = db.Frame.Layout
    UUFPLUS.PartyHeader:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    UUFPLUS.PartyHeader:SetFrameStrata(db.Frame.FrameStrata)

    if db.HideBlizzard then
        UUFPLUS:HideBlizzardGroupFrames()
    end
end
