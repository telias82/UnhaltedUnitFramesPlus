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
            Scale = 1.0,
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
                HealerOnly = false,
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
                Layout = { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 },
                GrowthX = "LEFT",
                GrowthY = "UP",
                BuffsEnabled = true,
                NumBuffs = 3,
                BuffsLayout = { "BOTTOMLEFT", "BOTTOMLEFT", 0, 0 },
                BuffsGrowthX = "RIGHT",
                BuffsGrowthY = "UP",
            },
            Range = {
                InRange = 1.0,
                OutOfRange = 0.5,
            },
            Indicators = {
                GroupRole       = { Enabled = true, Size = 20, Layout = { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 }, HideDPS = false, HideInCombat = false },
                Leader          = { Enabled = true, Size = 12, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                Assistant       = { Enabled = true, Size = 12, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                RaidRole        = { Enabled = true, Size = 12, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                RaidTargetMarker = { Size = 16, Layout = { "TOPRIGHT", "TOPRIGHT", 2, 2 } },
                Target          = { Enabled = true, Colour = { 1, 1, 0, 1 } },
            },
            Tags = {
                Name = { Tag = "[name]",         FontSize = 10, Colour = { 1, 1, 1 }, Layout = { "LEFT",  "LEFT",  2,  1  } },
                HP   = { Tag = "[perhp:absorb]",  FontSize = 9,  Colour = { 1, 1, 1 }, Layout = { "RIGHT", "RIGHT", -2, -1 } },
            },
            OfflineFontSize = 10,
            StatusText = { Layout = { "CENTER", "CENTER", 0, 0 } },
            ReadyCheck = { Size = 16, Layout = { "CENTER", "CENTER", 0, 0 } },
        },
        Raid = {
            Enabled = true,
            HideBlizzard = true,
            ShowSolo = false,
            Scale = 1.0,
            Frame = {
                Width = 72,
                Height = 36,
                SpacingX = 3,
                SpacingY = 3,
                Columns = 8,
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
                HealerOnly = false,
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
                Layout = { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 },
                GrowthX = "LEFT",
                GrowthY = "UP",
                BuffsEnabled = true,
                NumBuffs = 3,
                BuffsLayout = { "BOTTOMLEFT", "BOTTOMLEFT", 0, 0 },
                BuffsGrowthX = "RIGHT",
                BuffsGrowthY = "UP",
            },
            Range = {
                InRange = 1.0,
                OutOfRange = 0.5,
            },
            Indicators = {
                GroupRole        = { Enabled = true, Size = 16, Layout = { "BOTTOMRIGHT", "BOTTOMRIGHT", 0, 0 }, HideDPS = false, HideInCombat = false },
                Leader           = { Enabled = true, Size = 10, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                Assistant        = { Enabled = true, Size = 10, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                RaidRole         = { Enabled = true, Size = 10, Layout = { "TOPLEFT",     "TOPLEFT",     0, 0 } },
                RaidTargetMarker = { Size = 12, Layout = { "TOPRIGHT", "TOPRIGHT", 2, 2 } },
                Target           = { Enabled = true, Colour = { 1, 1, 0, 1 } },
            },
            Tags = {
                Name = { Tag = "[name]", FontSize = 9, Colour = { 1, 1, 1 }, Layout = { "LEFT", "LEFT", 2, 0 } },
            },
            OfflineFontSize = 10,
            StatusText = { Layout = { "CENTER", "CENTER", 0, 0 } },
            ReadyCheck = { Size = 14, Layout = { "CENTER", "CENTER", 0, 0 } },
        },
    },
}

function UUFPLUS:GetDefaultDB()
    return Defaults
end
