local UUFPLUS = _G.UUFPLUS

local function ApplyPartyPowerVisibility(child)
    local pdb = UUFPLUS.db.profile.Party.PowerBar
    if not child.Power or not child.Health then return end
    local role = child.unit and UnitGroupRolesAssigned(child.unit) or "NONE"
    local show = pdb.Enabled and (not pdb.HealerOnly or role == "HEALER")
    child.Power:SetShown(show)
    local gap = show and (pdb.Height + 1) or 0
    child.Health:ClearAllPoints()
    child.Health:SetPoint("TOPLEFT", child, 1, -1)
    child.Health:SetPoint("BOTTOMRIGHT", child, -1, 1 + gap)
    local db = UUFPLUS.db.profile.Party
    local debuffs = child._debuffsContainer
    if debuffs then
        local AL = db.Auras.Layout
        local ap = AL[1] or "BOTTOMRIGHT"
        debuffs:ClearAllPoints()
        debuffs:SetPoint(ap, child, AL[2] or ap, AL[3] or 0, (AL[4] or 0) + (ap:find("BOTTOM") and gap or 0))
    end
    local buffs = child._buffsContainer
    if buffs then
        local BL = db.Auras.BuffsLayout
        local bp = BL[1] or "BOTTOMLEFT"
        buffs:ClearAllPoints()
        buffs:SetPoint(bp, child, BL[2] or bp, BL[3] or 0, (BL[4] or 0) + (bp:find("BOTTOM") and gap or 0))
    end
end

local function FilterAura(element, unit, data)
    if data.duration == 0 then return end
    if (element.onlyShowPlayer and data.isPlayerAura) or not element.onlyShowPlayer then
        return true
    end
end

local function FilterCooldownBuff(element, unit, data)
    return UUFPLUS.CooldownBuffSpells[data.spellId] == true
end

local ROLE_ATLAS = {
    TANK    = "UI-LFG-RoleIcon-Tank-Micro-GroupFinder",
    HEALER  = "UI-LFG-RoleIcon-Healer-Micro-GroupFinder",
    DAMAGER = "UI-LFG-RoleIcon-DPS-Micro-GroupFinder",
}

local function ApplyRoleTexture(el, role)
    local atlas = ROLE_ATLAS[role]
    if atlas then el:SetAtlas(atlas) end
end

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

local function SetupStripeOverlay(bar, healthBar, isReverse)
    local clipFrame = CreateFrame("Frame", nil, bar)
    clipFrame:SetFrameLevel(bar:GetFrameLevel() + 1)
    clipFrame:SetWidth(0.01)
    if isReverse then
        clipFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT")
        clipFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
    else
        clipFrame:SetPoint("TOPLEFT", bar, "TOPLEFT")
        clipFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT")
    end
    local tex = clipFrame:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\RaidFrame\\Shield-Overlay")
    tex:SetAllPoints(clipFrame)
    clipFrame:Show()
    bar.StripeClipFrame = clipFrame
    local function refresh(self)
        local cf = self.StripeClipFrame
        if not cf or not cf:IsShown() then return end
        local lo, hi = self:GetMinMaxValues()
        local w = healthBar:GetWidth()
        local val = self:GetValue()
        if w <= 0 or hi <= lo or val <= lo then cf:SetWidth(0.01); return end
        cf:SetWidth(math.max(0.01, w * (val - lo) / (hi - lo)))
    end
    bar:HookScript("OnValueChanged", refresh)
    bar:HookScript("OnSizeChanged",  refresh)
end

local function CreatePartyFrame(self)
    local UUF = UUFPLUS.UUF
    local db = UUFPLUS.db.profile.Party
    local powerH = db.PowerBar.Enabled and db.PowerBar.Height or 0

    -- Background (BackdropTemplate required on modern engine)
    local bg = CreateFrame("Frame", nil, self, "BackdropTemplate")
    bg:SetAllPoints(self)
    bg:SetBackdrop(UUF.BACKDROP)
    bg:SetBackdropColor(0, 0, 0, 0.85)
    bg:SetBackdropBorderColor(0, 0, 0, 1)

    -- Health bar
    local health = CreateFrame("StatusBar", nil, self)
    health:SetStatusBarTexture(UUF.Media.Foreground)
    local healthGap = (powerH > 0 and not db.PowerBar.HealerOnly) and (powerH + 1) or 0
    health:SetPoint("TOPLEFT", self, 1, -1)
    health:SetPoint("BOTTOMRIGHT", self, -1, 1 + healthGap)
    health.smoothing       = (Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Linear) or 1
    health.colorClass        = db.HealthBar.ColorByClass
    health.colorReaction     = db.HealthBar.ColorByClass
    health.colorDisconnected = true

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints(health)
    healthBG:SetTexture(UUF.Media.Background)
    healthBG:SetVertexColor(0.15, 0.15, 0.15, db.HealthBar.BackgroundAlpha)
    health.bg = healthBG

    -- "Offline" text shown centered on the frame when the unit disconnects.
    -- Must be parented to health (a child Frame) so it renders above all child frames.
    local offlineTxt = health:CreateFontString(nil, "OVERLAY")
    offlineTxt:SetFont(UUF.Media.Font, db.OfflineFontSize or 10, UUF.Media.FontFlag)
    offlineTxt:SetPoint("CENTER", self, "CENTER")
    offlineTxt:SetText("Offline")
    offlineTxt:SetTextColor(0.8, 0.8, 0.8)
    offlineTxt:Hide()
    self._offlineTxt = offlineTxt

    -- PostUpdateColor fires on every color update including UNIT_CONNECTION.
    -- Forces the bar to full and shows/hides the offline label.
    health.PostUpdateColor = function(element, unit, color)
        local connected = UnitIsConnected(unit)
        element.__owner._offlineTxt:SetShown(not connected)
        if not connected then
            local max = UnitHealthMax(unit)
            if max > 0 then
                element:SetMinMaxValues(0, max)
                element:SetValue(max)
            end
        end
    end

    self.Health = health

    -- Power bar
    if db.PowerBar.Enabled then
        local power = CreateFrame("StatusBar", nil, self)
        power:SetStatusBarTexture(UUF.Media.Foreground)
        power:SetPoint("BOTTOMLEFT", self, 1, 1)
        power:SetPoint("BOTTOMRIGHT", self, -1, 1)
        power:SetHeight(powerH)
        power.colorPower = true
        power.smoothing = (Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Linear) or 1

        self:HookScript("OnShow", function(self)
            ApplyPartyPowerVisibility(self)
        end)

        local powerBG = power:CreateTexture(nil, "BACKGROUND")
        powerBG:SetAllPoints(power)
        powerBG:SetTexture(UUF.Media.Background)
        powerBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        power.bg = powerBG
        self.Power = power
    end

    -- Absorb / heal-absorb prediction (children of health, ATTACH mode)
    if db.HealPrediction.Enabled then
        local absorbColor = db.HealPrediction.AbsorbColor
        local absorbBar = CreateFrame("StatusBar", nil, health)
        absorbBar:SetPoint("TOPLEFT",    health:GetStatusBarTexture(), "TOPRIGHT",    0, 0)
        absorbBar:SetPoint("BOTTOMLEFT", health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        absorbBar:SetWidth(200)
        absorbBar:SetStatusBarTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Atrocity.tga")
        absorbBar:SetStatusBarColor(absorbColor[1], absorbColor[2], absorbColor[3], absorbColor[4])
        SetupStripeOverlay(absorbBar, health, false)
        health.DamageAbsorb = absorbBar

        local healAbsorbColor = db.HealPrediction.HealAbsorbColor
        local healAbsorbBar = CreateFrame("StatusBar", nil, health)
        healAbsorbBar:SetPoint("TOPRIGHT",    health:GetStatusBarTexture(), "TOPLEFT",    0, 0)
        healAbsorbBar:SetPoint("BOTTOMRIGHT", health:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
        healAbsorbBar:SetWidth(200)
        healAbsorbBar:SetStatusBarTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Atrocity.tga")
        healAbsorbBar:SetStatusBarColor(healAbsorbColor[1], healAbsorbColor[2], healAbsorbColor[3], healAbsorbColor[4])
        healAbsorbBar:SetReverseFill(true)
        SetupStripeOverlay(healAbsorbBar, health, true)
        health.HealAbsorb = healAbsorbBar

        -- Clamp absorb bars so they never extend beyond the frame boundary.
        health.PostUpdate = function(element, unit, cur, max, lossPerc)
            if element.DamageAbsorb then
                local raw = UnitGetTotalAbsorbs(unit) or 0
                element.DamageAbsorb:SetValue(math.min(raw, math.max(0, max - cur)))
            end
            if element.HealAbsorb then
                local raw = (UnitGetTotalHealAbsorbs and UnitGetTotalHealAbsorbs(unit)) or 0
                element.HealAbsorb:SetValue(math.min(raw, math.max(0, cur)))
            end
        end
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

    -- Debuffs (always created; hidden and detached from oUF when disabled)
    do
        local AL = db.Auras.Layout
        local ap = AL[1] or "BOTTOMRIGHT"
        local gx = db.Auras.GrowthX or "LEFT"
        local gy = db.Auras.GrowthY or "UP"
        local ia = (gy == "UP" and "BOTTOM" or "TOP") .. (gx == "LEFT" and "RIGHT" or "LEFT")
        local debuffs = CreateFrame("Frame", nil, self)
        debuffs:SetPoint(ap, self, AL[2] or ap, AL[3] or 0, (AL[4] or 0) + (ap:find("BOTTOM") and healthGap or 0))
        debuffs:SetSize(
            (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumDebuffs,
            db.Auras.Size + db.Auras.Spacing
        )
        debuffs.num            = db.Auras.NumDebuffs
        debuffs.size           = db.Auras.Size
        debuffs.spacing        = db.Auras.Spacing
        debuffs.initialAnchor  = ia
        debuffs.growthX        = gx
        debuffs.growthY        = gy
        debuffs.filter         = "HARMFUL|RAID"
        debuffs.showDebuffType = true
        debuffs.tooltipAnchor  = "ANCHOR_CURSOR"
        debuffs.FilterAura     = FilterAura
        self._debuffsContainer = debuffs
        if db.Auras.Enabled then
            self.Debuffs = debuffs
        else
            debuffs:Hide()
        end
    end

    -- Buffs (always created; hidden and detached from oUF when disabled)
    do
        local BL = db.Auras.BuffsLayout
        local bp = BL[1] or "BOTTOMRIGHT"
        local gx = db.Auras.BuffsGrowthX or db.Auras.GrowthX or "LEFT"
        local gy = db.Auras.BuffsGrowthY or db.Auras.GrowthY or "UP"
        local ia = (gy == "UP" and "BOTTOM" or "TOP") .. (gx == "LEFT" and "RIGHT" or "LEFT")
        local buffs = CreateFrame("Frame", nil, self)
        buffs:SetPoint(bp, self, BL[2] or bp, BL[3] or 0, (BL[4] or 0) + (bp:find("BOTTOM") and healthGap or 0))
        buffs:SetSize(
            (db.Auras.Size + db.Auras.Spacing) * db.Auras.NumBuffs,
            db.Auras.Size + db.Auras.Spacing
        )
        buffs.num            = db.Auras.NumBuffs
        buffs.size           = db.Auras.Size
        buffs.spacing        = db.Auras.Spacing
        buffs.initialAnchor  = ia
        buffs.growthX        = gx
        buffs.growthY        = gy
        buffs.filter         = "HELPFUL"
        buffs.tooltipAnchor  = "ANCHOR_CURSOR"
        buffs.FilterAura     = FilterCooldownBuff
        self._buffsContainer = buffs
        if db.Auras.BuffsEnabled then
            self.Buffs = buffs
        else
            buffs:Hide()
        end
    end

    -- High-level overlay container — sits above all child frames (health, power, etc.)
    local highContainer = CreateFrame("Frame", nil, self)
    highContainer:SetAllPoints(self)
    highContainer:SetFrameLevel(self:GetFrameLevel() + 100)
    self._highContainer = highContainer

    -- Raid target indicator (on highContainer so it always renders on top)
    do
        local mDb = db.Indicators.RaidTargetMarker
        local L   = mDb.Layout
        local raidMarker = highContainer:CreateTexture(nil, "OVERLAY")
        raidMarker:SetSize(mDb.Size, mDb.Size)
        raidMarker:SetPoint(L[1] or "TOPRIGHT", highContainer, L[2] or "TOPRIGHT", L[3] or 2, L[4] or 2)
        self.RaidTargetIndicator = raidMarker
    end

    -- Leader indicator
    do
        local indDb = db.Indicators.Leader
        local L = indDb.Layout
        local leaderIcon = health:CreateTexture(nil, "OVERLAY", nil, 2)
        leaderIcon:SetSize(indDb.Size, indDb.Size)
        leaderIcon:SetPoint(L[1] or "TOPLEFT", health, L[2] or L[1] or "TOPLEFT", L[3] or 0, L[4] or 0)
        leaderIcon.Override = function(frame, event)
            local el = frame.LeaderIndicator
            if not db.Indicators.Leader.Enabled then el:Hide(); return end
            if not IsInGroup() then el:Hide(); return end
            if UnitIsGroupLeader(frame.unit) or UnitLeadsAnyGroup(frame.unit) then
                el:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
                el:Show()
            else
                el:Hide()
            end
        end
        self.LeaderIndicator = leaderIcon
    end

    -- Assistant indicator
    do
        local indDb = db.Indicators.Assistant
        local L = indDb.Layout
        local assistIcon = health:CreateTexture(nil, "OVERLAY", nil, 2)
        assistIcon:SetSize(indDb.Size, indDb.Size)
        assistIcon:SetPoint(L[1] or "TOPLEFT", health, L[2] or L[1] or "TOPLEFT", L[3] or 0, L[4] or 0)
        assistIcon.Override = function(frame, event)
            local el = frame.AssistantIndicator
            if not db.Indicators.Assistant.Enabled then el:Hide(); return end
            if not IsInGroup() then el:Hide(); return end
            if UnitIsGroupAssistant(frame.unit) and not UnitIsGroupLeader(frame.unit) then
                el:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
                el:Show()
            else
                el:Hide()
            end
        end
        self.AssistantIndicator = assistIcon
    end

    -- Raid role indicator (MT/MA)
    do
        local indDb = db.Indicators.RaidRole
        local L = indDb.Layout
        local raidRoleIcon = health:CreateTexture(nil, "OVERLAY", nil, 2)
        raidRoleIcon:SetSize(indDb.Size, indDb.Size)
        raidRoleIcon:SetPoint(L[1] or "TOPLEFT", health, L[2] or L[1] or "TOPLEFT", L[3] or 0, L[4] or 0)
        raidRoleIcon.Override = function(frame, event)
            local el = frame.RaidRoleIndicator
            if not db.Indicators.RaidRole.Enabled then el:Hide(); return end
            local unit = frame.unit
            if UnitInRaid(unit) and not UnitHasVehicleUI(unit) then
                if GetPartyAssignment("MAINTANK", unit) then
                    el:SetTexture([[Interface\GroupFrame\UI-Group-MainTankIcon]])
                    el:Show()
                elseif GetPartyAssignment("MAINASSIST", unit) then
                    el:SetTexture([[Interface\GroupFrame\UI-Group-MainAssistIcon]])
                    el:Show()
                else
                    el:Hide()
                end
            else
                el:Hide()
            end
        end
        self.RaidRoleIndicator = raidRoleIcon
    end

    -- Group role (tank/healer/dps)
    do
        local indDb = db.Indicators.GroupRole
        local L = indDb.Layout
        local groupRoleIcon = health:CreateTexture(nil, "OVERLAY", nil, 2)
        groupRoleIcon:SetSize(indDb.Size, indDb.Size)
        groupRoleIcon:SetPoint(L[1] or "BOTTOMRIGHT", health, L[2] or L[1] or "BOTTOMRIGHT", L[3] or 0, L[4] or 0)
        groupRoleIcon.Override = function(frame, event)
            local el = frame.GroupRoleIndicator
            local role = UnitGroupRolesAssigned(frame.unit)

            -- Update power bar first, before any early returns
            if frame.Power then
                frame.Power:SetShown(db.PowerBar.Enabled and (not db.PowerBar.HealerOnly or role == "HEALER"))
            end

            if not db.Indicators.GroupRole.Enabled then el:Hide(); return end

            if role == "TANK" or role == "HEALER" then
                ApplyRoleTexture(el, role)
                el:Show()
            elseif role == "DAMAGER" then
                if not db.Indicators.GroupRole.HideDPS then
                    ApplyRoleTexture(el, role)
                    el:Show()
                else
                    el:Hide()
                end
            else
                el:Hide()
            end
        end
        self.GroupRoleIndicator = groupRoleIcon
    end

    -- Name tag
    local nameTag = db.Tags.Name
    local nameText = health:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(UUF.Media.Font, nameTag.FontSize, UUF.Media.FontFlag)
    local NL = nameTag.Layout
    nameText:SetPoint(NL[1], health, NL[2], NL[3], NL[4])
    nameText:SetJustifyH(NL[1]:find("RIGHT") and "RIGHT" or "LEFT")
    nameText:SetWordWrap(false)
    local NC = nameTag.Colour
    nameText:SetTextColor(NC[1], NC[2], NC[3])
    self:Tag(nameText, nameTag.Tag)
    self._tagName = nameText

    -- HP tag
    local hpTag = db.Tags.HP
    local hpText = health:CreateFontString(nil, "OVERLAY")
    hpText:SetFont(UUF.Media.Font, hpTag.FontSize, UUF.Media.FontFlag)
    local HL = hpTag.Layout
    hpText:SetPoint(HL[1], health, HL[2], HL[3], HL[4])
    hpText:SetJustifyH(HL[1]:find("RIGHT") and "RIGHT" or "LEFT")
    hpText:SetWordWrap(false)
    local HC = hpTag.Colour
    hpText:SetTextColor(HC[1], HC[2], HC[3])
    self:Tag(hpText, hpTag.Tag)
    self._tagHP = hpText

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
    local yOff  = -spacing

    oUF:RegisterStyle("UUF_Plus_Party", function(self)
        local ok, err = pcall(CreatePartyFrame, self)
        if not ok then print("|cFFFF4444UUF+|r Party style error:", err) end
    end)
    oUF:SetActiveStyle("UUF_Plus_Party")

    UUFPLUS.PartyHeader = oUF:SpawnHeader(
        "UUF_Plus_PartyHeader",
        nil,
        "showParty",  true,
        "showSolo",   db.ShowSolo,
        "showPlayer", db.ShowPlayer,
        "point",      "TOP",
        "xOffset",    0,
        "yOffset",    yOff,
        "maxColumns", 1,
        "unitsPerColumn", 5,
        "columnSpacing",  0,
        "columnAnchorPoint", "LEFT",
        "groupBy",       "ASSIGNEDROLE",
        "groupingOrder", "TANK,HEALER,DAMAGER,NONE",
        "sortMethod",    "NAME",
        "oUF-initialConfigFunction", string.format([[
            self:SetWidth(%d)
            self:SetHeight(%d)
        ]], w, h)
    )
    UUFPLUS.PartyHeader:SetVisibility(db.ShowInRaid and "party" or "party,noraid")

    local layout = db.Frame.Layout
    UUFPLUS.PartyHeader:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    UUFPLUS.PartyHeader:SetFrameStrata(db.Frame.FrameStrata)

    if db.HideBlizzard then
        UUFPLUS:HideBlizzardGroupFrames()
    end

    -- Explicit role-change listener for power bar visibility
    do
        local function sweepPartyPower()
            local h = UUFPLUS.PartyHeader
            if not h then return end
            for i = 1, h:GetNumChildren() do
                local child = select(i, h:GetChildren())
                if child and child.unit then
                    ApplyPartyPowerVisibility(child)
                end
            end
        end

        local roleFrame = CreateFrame("Frame")
        roleFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        roleFrame:SetScript("OnEvent", sweepPartyPower)

        C_Timer.After(2, sweepPartyPower)
        C_Timer.After(5, sweepPartyPower)
    end

    -- Re-enforce saved position after SecureGroupHeader's internal layout update,
    -- which can reset the header's anchor on group/zone changes.
    do
        local function enforcePartyPos()
            if InCombatLockdown() then return end
            local h = UUFPLUS.PartyHeader
            if not h then return end
            local layout = UUFPLUS.db.profile.Party.Frame.Layout
            h:ClearAllPoints()
            h:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
        end
        local posFrame = CreateFrame("Frame")
        posFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        posFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        posFrame:SetScript("OnEvent", function() C_Timer.After(0, enforcePartyPos) end)
    end
end
