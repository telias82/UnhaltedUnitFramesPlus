_G.UUFPLUS = _G.UUFPLUS or {}

-- Spell IDs for externals and personal defensives shown on party/raid buff icons.
-- Sourced from Cell's MoP indicator spell list (Indicator_DefaultSpells_Mists.lua).
_G.UUFPLUS.CooldownBuffSpells = {
    -- ── EXTERNALS ─────────────────────────────────────────────────────────────
    -- Death Knight
    [51052]  = true, -- Anti-Magic Zone

    -- Druid
    [102342] = true, -- Ironbark

    -- Monk
    [116849] = true, -- Life Cocoon
    [115213] = true, -- Zen Meditation (external component)

    -- Paladin
    [1022]   = true, -- Hand of Protection
    [6940]   = true, -- Hand of Sacrifice
    [1038]   = true, -- Hand of Salvation
    [31821]  = true, -- Aura Mastery

    -- Priest
    [33206]  = true, -- Pain Suppression
    [47788]  = true, -- Guardian Spirit
    [62618]  = true, -- Power Word: Barrier

    -- Rogue
    [114018] = true, -- Shroud of Concealment

    -- Shaman
    [98007]  = true, -- Spirit Link Totem
    [8178]   = true, -- Grounding Totem

    -- Warrior
    [97463]  = true, -- Rallying Cry
    [147833] = true, -- Safeguard
    [46947]  = true, -- Intervene
    [114028] = true, -- Mass Spell Reflection
    [114030] = true, -- Vigilance

    -- ── DEFENSIVES ────────────────────────────────────────────────────────────
    -- Death Knight
    [48707]  = true, -- Anti-Magic Shell
    [48792]  = true, -- Icebound Fortitude
    [49028]  = true, -- Rune Tap
    [55233]  = true, -- Vampiric Blood
    [49039]  = true, -- Lichborne

    -- Druid
    [22812]  = true, -- Barkskin
    [61336]  = true, -- Survival Instincts
    [106922] = true, -- Might of Ursoc

    -- Hunter
    [19263]  = true, -- Deterrence

    -- Mage
    [45438]  = true, -- Ice Block
    [113862] = true, -- Enhanced Invisibility
    [108978] = true, -- Alter Time
    [115610] = true, -- Temporal Shield

    -- Monk
    [131523] = true, -- Zen Meditation (self channel)
    [115203] = true, -- Fortifying Brew
    [122278] = true, -- Dampen Harm
    [122783] = true, -- Diffuse Magic
    [125174] = true, -- Touch of Karma

    -- Paladin
    [498]    = true, -- Divine Protection
    [642]    = true, -- Divine Shield
    [31850]  = true, -- Ardent Defender
    [86659]  = true, -- Guardian of Ancient Kings

    -- Priest
    [47585]  = true, -- Dispersion
    [27827]  = true, -- Spirit of Redemption

    -- Rogue
    [1966]   = true, -- Feint
    [5277]   = true, -- Evasion
    [31224]  = true, -- Cloak of Shadows
    [73651]  = true, -- Recuperate

    -- Shaman
    [114893] = true, -- Stone Bulwark Totem
    [108271] = true, -- Astral Shift

    -- Warlock
    [104773] = true, -- Unending Resolve
    [108359] = true, -- Dark Regeneration

    -- Warrior
    [871]    = true, -- Shield Wall
    [12975]  = true, -- Last Stand
    [23920]  = true, -- Spell Reflection
    [118038] = true, -- Die by the Sword
    [55694]  = true, -- Enraged Regeneration
}
