local UUFPLUS = _G.UUFPLUS
local UnhaltedUnitFramesPlus = LibStub("AceAddon-3.0"):NewAddon("UnhaltedUnitFramesPlus")

function UnhaltedUnitFramesPlus:OnInitialize()
    UUFPLUS.UUF = _G.UUF
    UUFPLUS.oUF = _G.UUF.oUF
    UUFPLUS.db = LibStub("AceDB-3.0"):New("UUFPLUSDB", UUFPLUS:GetDefaultDB(), true)
    UUFPLUS:RegisterGUIExtensions()
end

function UnhaltedUnitFramesPlus:OnEnable()
    UUFPLUS:SpawnPartyFrames()
    UUFPLUS:SpawnRaidFrames()
end

function UUFPLUS:HideBlizzardGroupFrames()
    if UUFPLUS._blizzardFramesHidden then return end
    UUFPLUS._blizzardFramesHidden = true
    if CompactRaidFrameManager then
        CompactRaidFrameManager:UnregisterAllEvents()
        CompactRaidFrameManager:Hide()
    end
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:UnregisterAllEvents()
        CompactRaidFrameContainer:Hide()
    end
    if CompactRaidFrameManager_UpdateShown then
        hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
            if CompactRaidFrameContainer then
                CompactRaidFrameContainer:Hide()
            end
        end)
    end
end
