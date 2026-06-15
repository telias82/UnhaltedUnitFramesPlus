local UUFPLUS = _G.UUFPLUS
local UnhaltedUnitFramesPlus = LibStub("AceAddon-3.0"):NewAddon("UnhaltedUnitFramesPlus")

local function MigrateProfile(profile)
    for _, key in ipairs({ "Party", "Raid" }) do
        local a = profile[key] and profile[key].Auras
        if a then
            -- Reset stale buff defaults that pointed to BOTTOMRIGHT/LEFT growth.
            if a.BuffsEnabled == false then a.BuffsEnabled = nil end
            if a.BuffsLayout and a.BuffsLayout[1] == "BOTTOMRIGHT" and a.BuffsLayout[2] == "BOTTOMRIGHT" then
                a.BuffsLayout = nil
            end
            if a.BuffsGrowthX == "LEFT" then a.BuffsGrowthX = nil end
        end
    end
end

function UnhaltedUnitFramesPlus:OnInitialize()
    UUFPLUS.UUF = _G.UUF
    UUFPLUS.oUF = _G.UUF.oUF
    UUFPLUS.db = LibStub("AceDB-3.0"):New("UUFPLUSDB", UUFPLUS:GetDefaultDB(), true)
    MigrateProfile(UUFPLUS.db.profile)
    UUFPLUS:RegisterGUIExtensions()
end

function UnhaltedUnitFramesPlus:OnEnable()
    -- Spawning is handled by the PLAYER_LOGIN handler below; keeping this
    -- empty prevents taint propagation from Clicked's shared AceAddon library.
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self)
        -- Inline fallback in case OnInitialize hasn't run yet
        if not UUFPLUS.UUF and _G.UUF then
            UUFPLUS.UUF = _G.UUF
            UUFPLUS.oUF = _G.UUF.oUF
        end
        if not UUFPLUS.db then
            UUFPLUS.db = LibStub("AceDB-3.0"):New("UUFPLUSDB", UUFPLUS:GetDefaultDB(), true)
            MigrateProfile(UUFPLUS.db.profile)
            UUFPLUS:RegisterGUIExtensions()
        end
        UUFPLUS:SpawnPartyFrames()
        UUFPLUS:SpawnRaidFrames()
        self:SetScript("OnEvent", nil)
    end)
end

function UUFPLUS:HideBlizzardGroupFrames()
    if UUFPLUS._blizzardFramesHidden then return end
    UUFPLUS._blizzardFramesHidden = true

    -- Parenting Blizzard frames to a hidden frame prevents any Show() call from
    -- making them visible — more robust than HookScript("OnShow").
    local hiddenParent = CreateFrame("Frame", nil, UIParent)
    hiddenParent:Hide()

    local function SuppressFrame(frame)
        if not frame then return end
        frame:UnregisterAllEvents()
        frame:SetParent(hiddenParent)
    end

    SuppressFrame(CompactRaidFrameManager)
    SuppressFrame(CompactRaidFrameContainer)

    -- CompactPartyFrame is protected; SetParent causes taint.
    -- RegisterStateDriver keeps it hidden at the secure layer.
    if _G.CompactPartyFrame then
        _G.CompactPartyFrame:UnregisterAllEvents()
        RegisterStateDriver(_G.CompactPartyFrame, "visibility", "hide")
    end

    -- Re-suppress on Blizzard update hooks in case they recreate the frames.
    if CompactRaidFrameManager_UpdateShown then
        hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
            SuppressFrame(CompactRaidFrameManager)
        end)
    end

    if CompactRaidFrameContainer_UpdateShown then
        hooksecurefunc("CompactRaidFrameContainer_UpdateShown", function()
            SuppressFrame(CompactRaidFrameContainer)
        end)
    end

    -- Catch late Blizzard initialization after zone transitions.
    local suppress = CreateFrame("Frame")
    suppress:RegisterEvent("GROUP_ROSTER_UPDATE")
    suppress:RegisterEvent("RAID_ROSTER_UPDATE")
    suppress:RegisterEvent("PLAYER_ENTERING_WORLD")
    suppress:SetScript("OnEvent", function(self, event)
        SuppressFrame(CompactRaidFrameManager)
        SuppressFrame(CompactRaidFrameContainer)
        C_Timer.After(0.5, function()
            SuppressFrame(CompactRaidFrameManager)
            SuppressFrame(CompactRaidFrameContainer)
        end)
        C_Timer.After(2, function()
            SuppressFrame(CompactRaidFrameManager)
            SuppressFrame(CompactRaidFrameContainer)
        end)
    end)

    C_Timer.After(0.5, function()
        SuppressFrame(CompactRaidFrameManager)
        SuppressFrame(CompactRaidFrameContainer)
    end)
    C_Timer.After(2, function()
        SuppressFrame(CompactRaidFrameManager)
        SuppressFrame(CompactRaidFrameContainer)
    end)
end
