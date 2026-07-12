local UUFPLUS = _G.UUFPLUS

local function ApplyRaidPowerVisibility(child)
    local pdb = UUFPLUS.db.profile.Raid.PowerBar
    if not child.Power or not child.Health then return end
    local role = child.unit and UnitGroupRolesAssigned(child.unit) or "NONE"
    local show = pdb.Enabled and (not pdb.HealerOnly or role == "HEALER")
    child.Power:SetShown(show)
    local gap = show and (pdb.Height + 1) or 0
    child.Health:ClearAllPoints()
    child.Health:SetPoint("TOPLEFT", child, 1, -1)
    child.Health:SetPoint("BOTTOMRIGHT", child, -1, 1 + gap)
    local db = UUFPLUS.db.profile.Raid
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

local function UpdateStatusText(frame, unit)
    local txt = frame._statusTxt
    if not txt then return end
    if not UnitIsConnected(unit) then
        txt:SetText("Offline")
        txt:SetTextColor(0.8, 0.8, 0.8)
        txt:Show()
    elseif UnitIsGhost(unit) then
        txt:SetText("Ghost")
        txt:SetTextColor(0.6, 0.4, 0.8)
        txt:Show()
    elseif UnitIsDead(unit) then
        txt:SetText("Dead")
        txt:SetTextColor(0.75, 0.2, 0.2)
        txt:Show()
    elseif UnitIsAFK(unit) then
        txt:SetText("AFK")
        txt:SetTextColor(0.8, 0.8, 0.2)
        txt:Show()
    else
        txt:Hide()
    end
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

local function CreateRaidFrame(self)
    local UUF = UUFPLUS.UUF
    local db = UUFPLUS.db.profile.Raid
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

    -- Status text (Offline / Dead / Ghost / AFK) shown centered on the frame.
    -- Parented to health so it renders above all child frames.
    local statusTxt = health:CreateFontString(nil, "OVERLAY")
    statusTxt:SetFont(UUF.Media.Font, db.OfflineFontSize or 10, UUF.Media.FontFlag)
    local SL = db.StatusText and db.StatusText.Layout
    statusTxt:SetPoint(SL and SL[1] or "CENTER", self, SL and SL[2] or "CENTER", SL and SL[3] or 0, SL and SL[4] or 0)
    statusTxt:Hide()
    self._statusTxt = statusTxt

    -- PostUpdateColor fires on UNIT_CONNECTION and health colour changes.
    -- Forces bar to full when offline; delegates label to UpdateStatusText.
    health.PostUpdateColor = function(element, unit, color)
        if not UnitIsConnected(unit) then
            local max = UnitHealthMax(unit)
            if max > 0 then
                element:SetMinMaxValues(0, max)
                element:SetValue(max)
            end
        end
        UpdateStatusText(element.__owner, unit)
    end

    self:RegisterUnitEvent("UNIT_HEALTH", function(frame) UpdateStatusText(frame, frame.unit) end)
    self:RegisterUnitEvent("UNIT_FLAGS",  function(frame) UpdateStatusText(frame, frame.unit) end)

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
            ApplyRaidPowerVisibility(self)
        end)

        local powerBG = power:CreateTexture(nil, "BACKGROUND")
        powerBG:SetAllPoints(power)
        powerBG:SetTexture(UUF.Media.Background)
        powerBG:SetVertexColor(0.1, 0.1, 0.1, 0.8)
        power.bg = powerBG
        self.Power = power
    end

    -- Heal prediction + absorb overlay. oUF's HealthPrediction element owns all
    -- event handling via Override; UpdateSize sets the heal bar width only
    -- (absorb uses SetAllPoints and doesn't need it).
    if db.HealPrediction.Enabled then
        local healthFill = health:GetStatusBarTexture()

        -- Incoming heal bar — ATTACH, clipped at health bar boundary
        local healBar = CreateFrame("StatusBar", nil, health)
        healBar:SetPoint("TOPLEFT",    healthFill, "TOPRIGHT",    0, 0)
        healBar:SetPoint("BOTTOMLEFT", healthFill, "BOTTOMRIGHT", 0, 0)
        healBar:SetWidth(0.01)
        healBar:SetFrameLevel(health:GetFrameLevel() + 1)
        healBar:SetStatusBarTexture(UUF.Media.Foreground)
        healBar:SetStatusBarColor(0.3, 1.0, 0.3, 0.6)
        healBar:Hide()

        -- Absorb bar — SUF over-absorb style, above the heal bar
        local absorbBar = CreateFrame("StatusBar", nil, health)
        absorbBar:SetAllPoints(health)
        absorbBar:SetReverseFill(true)
        absorbBar:SetFrameLevel(health:GetFrameLevel() + 2)
        absorbBar:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Overlay")
        local fillTex = absorbBar:GetStatusBarTexture()
        if fillTex then
            fillTex:SetTexture("Interface\\RaidFrame\\Shield-Overlay", "REPEAT", "REPEAT")
            if fillTex.SetVertTile  then fillTex:SetVertTile(true)  end
            if fillTex.SetHorizTile then fillTex:SetHorizTile(true) end
        end
        absorbBar:SetMinMaxValues(0, 1)
        absorbBar:SetValue(0)
        absorbBar:Hide()

        local absorbGlow = absorbBar:CreateTexture(nil, "OVERLAY")
        absorbGlow:SetTexture("Interface\\RaidFrame\\Shield-Overshield")
        absorbGlow:SetBlendMode("ADD")
        absorbGlow:SetWidth(6)
        absorbGlow:Hide()

        local lastHP, lastMaxHP, lastHeal, lastAbsorb = -1, -1, -1, -1

        self.HealthPrediction = {
            healingAll   = healBar,
            damageAbsorb = absorbBar,
            UpdateSize = function(frame)
                local barW = frame.Health:GetWidth()
                if barW > 0 then healBar:SetWidth(barW) end
            end,
            Override = function(frame, event, unit)
                if frame.unit ~= unit then return end
                local hp     = UnitHealth(unit)
                local maxHP  = UnitHealthMax(unit)
                local heal   = math.min(UnitGetIncomingHeals(unit) or 0, maxHP - hp)
                local amount = UnitGetTotalAbsorbs(unit) or 0

                if hp == lastHP and maxHP == lastMaxHP and heal == lastHeal and amount == lastAbsorb then return end
                lastHP = hp; lastMaxHP = maxHP; lastHeal = heal; lastAbsorb = amount

                -- Incoming heals — clamped to missing HP so it never extends past the bar
                if heal > 0 and maxHP > 0 then
                    healBar:SetMinMaxValues(0, maxHP)
                    healBar:SetValue(heal)
                    healBar:Show()
                else
                    healBar:Hide()
                end

                -- Damage absorbs (SUF over-absorb)
                if amount <= 0 or maxHP <= 0 then
                    absorbBar:Hide(); absorbGlow:Hide(); return
                end
                local overAbsorb = math.min(amount - (maxHP - hp), maxHP)
                absorbBar:SetMinMaxValues(0, maxHP)
                absorbBar:SetValue(math.max(0, overAbsorb))
                absorbBar:Show()
                local barW = frame.Health:GetWidth()
                if barW > 0 then
                    local barOffset
                    if overAbsorb > 0 then
                        barOffset = (overAbsorb / maxHP) * barW
                    else
                        barOffset = math.max(0, maxHP - hp - amount) / maxHP * barW
                    end
                    -- SetPoint replaces an existing point of the same name; ClearAllPoints not needed
                    absorbGlow:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", -barOffset + 4, 0)
                    absorbGlow:SetPoint("TOPRIGHT",    absorbBar, "TOPRIGHT",    -barOffset + 4, 0)
                    absorbGlow:Show()
                end
            end,
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

    -- Target glow border (hidden until PLAYER_TARGET_CHANGED fires)
    do
        local tDb = db.Indicators.Target
        local tglow = CreateFrame("Frame", nil, self, "BackdropTemplate")
        tglow:SetFrameLevel(highContainer:GetFrameLevel() + 1)
        tglow:SetBackdrop({
            edgeFile = "Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Glow.tga",
            edgeSize = 3,
            insets   = { left = -3, right = -3, top = -3, bottom = -3 },
        })
        tglow:SetBackdropColor(0, 0, 0, 0)
        local C = tDb and tDb.Colour or { 1, 1, 0, 1 }
        tglow:SetBackdropBorderColor(C[1], C[2], C[3], C[4] or 1)
        tglow:SetPoint("TOPLEFT",     self, "TOPLEFT",     -3,  3)
        tglow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT",  3, -3)
        tglow:SetAlpha(0)
        self._targetGlow = tglow
    end

    -- Raid target indicator (on highContainer so it always renders on top)
    do
        local mDb = db.Indicators.RaidTargetMarker
        local L   = mDb.Layout
        local raidMarker = highContainer:CreateTexture(nil, "OVERLAY")
        raidMarker:SetSize(mDb.Size, mDb.Size)
        raidMarker:SetPoint(L[1] or "TOPRIGHT", highContainer, L[2] or "TOPRIGHT", L[3] or 2, L[4] or 2)
        self.RaidTargetIndicator = raidMarker
    end

    -- Ready check indicator (oUF element handles events and fade animation)
    do
        local RC = db.ReadyCheck
        local RL = RC and RC.Layout
        local sz = (RC and RC.Size) or 14
        local rci = highContainer:CreateTexture(nil, "OVERLAY")
        rci:SetSize(sz, sz)
        rci:SetPoint(RL and RL[1] or "CENTER", self, RL and RL[2] or "CENTER", RL and RL[3] or 0, RL and RL[4] or 0)
        self.ReadyCheckIndicator = rci
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

            local grDb = db.Indicators.GroupRole
            if not grDb.Enabled then el:Hide(); return end
            if grDb.HideInCombat and UnitAffectingCombat("player") then el:Hide(); return end

            if role == "TANK" or role == "HEALER" then
                ApplyRoleTexture(el, role)
                el:Show()
            elseif role == "DAMAGER" then
                if not grDb.HideDPS then
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

    oUF:RegisterStyle("UUF_Plus_Raid", function(self)
        local ok, err = pcall(CreateRaidFrame, self)
        if not ok then print("|cFFFF4444UUF+|r Raid style error:", err) end
    end)
    oUF:SetActiveStyle("UUF_Plus_Raid")

    UUFPLUS.RaidHeader = oUF:SpawnHeader(
        "UUF_Plus_RaidHeader",
        nil,
        "showSolo",          db.ShowSolo,
        "showPlayer",        true,
        "showRaid",          true,
        "point",             "TOP",
        "xOffset",           0,
        "yOffset",           -sy,
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
    UUFPLUS.RaidHeader:SetVisibility("raid")

    local layout = db.Frame.Layout
    UUFPLUS.RaidHeader:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
    UUFPLUS.RaidHeader:SetFrameStrata(db.Frame.FrameStrata)

    if db.HideBlizzard then
        UUFPLUS:HideBlizzardGroupFrames()
    end

    -- Explicit role-change listener: forces power bar show/hide whenever group
    -- roles update.
    do
        local function sweepRaidPower()
            local h = UUFPLUS.RaidHeader
            if not h then return end
            local children = {h:GetChildren()}
            for i = 1, #children do
                local child = children[i]
                if child and child.unit then
                    ApplyRaidPowerVisibility(child)
                end
            end
        end

        local roleFrame = CreateFrame("Frame")
        roleFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        roleFrame:SetScript("OnEvent", sweepRaidPower)

        -- Delayed sweeps catch roles that arrive after the initial GROUP_ROSTER_UPDATE.
        C_Timer.After(2, sweepRaidPower)
        C_Timer.After(5, sweepRaidPower)
    end

    -- Re-enforce saved position after SecureGroupHeader's internal layout update,
    -- which can reset the header's anchor on group/zone changes.
    do
        local function enforceRaidPos()
            if InCombatLockdown() then return end
            local h = UUFPLUS.RaidHeader
            if not h then return end
            local layout = UUFPLUS.db.profile.Raid.Frame.Layout
            h:ClearAllPoints()
            h:SetPoint(layout[1], UIParent, layout[2], layout[3], layout[4])
        end
        local _raidPosPending = false
        local posFrame = CreateFrame("Frame")
        posFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        posFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        posFrame:SetScript("OnEvent", function()
            if not _raidPosPending then
                _raidPosPending = true
                C_Timer.After(0, function()
                    _raidPosPending = false
                    enforceRaidPos()
                end)
            end
        end)
    end

    -- Sweep group role icons on combat state change
    do
        local function sweepRaidRoleIcons()
            local h = UUFPLUS.RaidHeader
            if not h then return end
            local children = {h:GetChildren()}
            for i = 1, #children do
                local child = children[i]
                if child and child.GroupRoleIndicator and child.GroupRoleIndicator.Override then
                    child.GroupRoleIndicator.Override(child, "PLAYER_REGEN_DISABLED")
                end
            end
        end
        local combatFrame = CreateFrame("Frame")
        combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        combatFrame:SetScript("OnEvent", sweepRaidRoleIcons)
    end
end
