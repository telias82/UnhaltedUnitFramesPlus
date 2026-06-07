_G.UUFPLUS = _G.UUFPLUS or {}
local UUFPLUS = _G.UUFPLUS

local Defaults = {
    profile = {
        Party = {
            Enabled = true,
            HideBlizzard = true,
            ShowPlayer = false,
            ShowSolo = false,
            ShowInRaid = false,
            Frame = {
                Width = 120,
                Height = 40,
                Spacing = 5,
                FrameStrata = "LOW",
                Layout = { "BOTTOM", "CENTER", 0, 200 },
            },
            HealthBar = {
                ColorByClass = true,
                BackgroundAlpha = 0.8,
            },
            PowerBar = {
                Enabled = true,
                Height = 5,
            },
            HealPrediction = {
                Enabled = true,
                AbsorbColor = { 0.85, 0.85, 0.32, 0.8 },
                HealAbsorbColor = { 0.2, 0.2, 0.6, 0.8 },
            },
            DispelHighlight = {
                Enabled = true,
            },
            Auras = {
                Enabled = true,
                Size = 14,
                Spacing = 2,
                NumDebuffs = 3,
            },
            Range = {
                InRange = 1.0,
                OutOfRange = 0.5,
            },
        },
        Raid = {
            Enabled = true,
            HideBlizzard = true,
            ShowSolo = false,
            Frame = {
                Width = 72,
                Height = 36,
                SpacingX = 3,
                SpacingY = 3,
                Columns = 5,
                UnitsPerColumn = 5,
                FrameStrata = "LOW",
                Layout = { "TOPLEFT", "TOPLEFT", 20, -300 },
            },
            HealthBar = {
                ColorByClass = true,
                BackgroundAlpha = 0.8,
            },
            PowerBar = {
                Enabled = true,
                Height = 4,
            },
            HealPrediction = {
                Enabled = true,
                AbsorbColor = { 0.85, 0.85, 0.32, 0.8 },
                HealAbsorbColor = { 0.2, 0.2, 0.6, 0.8 },
            },
            DispelHighlight = {
                Enabled = true,
            },
            Auras = {
                Enabled = true,
                Size = 12,
                Spacing = 2,
                NumDebuffs = 3,
            },
            Range = {
                InRange = 1.0,
                OutOfRange = 0.5,
            },
        },
    },
}

function UUFPLUS:GetDefaultDB()
    return Defaults
end
