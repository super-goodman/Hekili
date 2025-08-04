-- EvokerDevastation.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "EVOKER" then return end
SetCVar("empowerTapControls", 0)
local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local spec = Hekili:NewSpecialization( 1467 )

---- Local function declarations for increased performance
-- Strings
local strformat = string.format
-- Tables
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe
-- Math
local abs, ceil, floor, max, sqrt = math.abs, math.ceil, math.floor, math.max, math.sqrt

-- Common WoW APIs, comment out unneeded per-spec
-- local GetSpellCastCount = C_Spell.GetSpellCastCount
-- local GetSpellInfo = C_Spell.GetSpellInfo
-- local GetSpellInfo = ns.GetUnpackedSpellInfo
-- local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
-- local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
-- local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
-- local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
-- local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)

spec:RegisterResource( Enum.PowerType.Essence )
spec:RegisterResource( Enum.PowerType.Mana )

-- Talents
spec:RegisterTalents( {

    -- Evoker
    aerial_mastery                 = {  93352,  365933, 1 }, -- Hover gains $s1 additional charge
    ancient_flame                  = {  93271,  369990, 1 }, -- Casting Emerald Blossom or Verdant Embrace reduces the cast time of your next Living Flame by $s1%
    attuned_to_the_dream           = {  93292,  376930, 2 }, -- Your healing done and healing received are increased by $s1%
    blast_furnace                  = {  93309,  375510, 1 }, -- Fire Breath's damage over time lasts $s1 sec longer
    bountiful_bloom                = {  93291,  370886, 1 }, -- Emerald Blossom heals $s1 additional allies
    cauterizing_flame              = {  93294,  374251, 1 }, -- Cauterize an ally's wounds, removing all Bleed, Poison, Curse, and Disease effects. Heals for $s1 upon removing any effect
    clobbering_sweep               = { 103844,  375443, 1 }, -- Tail Swipe's cooldown is reduced by $s1 min
    draconic_legacy                = {  93300,  376166, 1 }, -- Your Stamina is increased by $s1%
    enkindled                      = {  93295,  375554, 2 }, -- Living Flame deals $s1% more damage and healing
    expunge                        = {  93306,  365585, 1 }, -- Expunge toxins affecting an ally, removing all Poison effects
    extended_flight                = {  93349,  375517, 2 }, -- Hover lasts $s1 sec longer
    exuberance                     = {  93299,  375542, 1 }, -- While above $s1% health, your movement speed is increased by $s2%
    fire_within                    = {  93345,  375577, 1 }, -- Renewing Blaze's cooldown is reduced by $s1 sec
    foci_of_life                   = {  93345,  375574, 1 }, -- Renewing Blaze restores you more quickly, causing damage you take to be healed back over $s1 sec
    forger_of_mountains            = {  93270,  375528, 1 }, -- Landslide's cooldown is reduced by $s1 sec, and it can withstand $s2% more damage before breaking
    heavy_wingbeats                = { 103843,  368838, 1 }, -- Wing Buffet's cooldown is reduced by $s1 min
    inherent_resistance            = {  93355,  375544, 2 }, -- Magic damage taken reduced by $s1%
    innate_magic                   = {  93302,  375520, 2 }, -- Essence regenerates $s1% faster
    instinctive_arcana             = {  93310,  376164, 2 }, -- Your Magic damage done is increased by $s1%
    landslide                      = {  93305,  358385, 1 }, -- Conjure a path of shifting stone towards the target location, rooting enemies for $s1 sec. Damage may cancel the effect
    leaping_flames                 = {  93343,  369939, 1 }, -- Fire Breath causes your next Living Flame to strike $s1 additional target per empower level
    lush_growth                    = {  93347,  375561, 2 }, -- Green spells restore $s1% more health
    natural_convergence            = {  93312,  369913, 1 }, -- Disintegrate channels $s1% faster
    obsidian_bulwark               = {  93289,  375406, 1 }, -- Obsidian Scales has an additional charge
    obsidian_scales                = {  93304,  363916, 1 }, -- Reinforce your scales, reducing damage taken by $s1%. Lasts $s2 sec
    oppressing_roar                = {  93298,  372048, 1 }, -- Let out a bone-shaking roar at enemies in a cone in front of you, increasing the duration of crowd controls that affect them by $s1% in the next $s2 sec
    overawe                        = {  93297,  374346, 1 }, -- Oppressing Roar removes $s1 Enrage effect from each enemy, and its cooldown is reduced by $s2 sec
    panacea                        = {  93348,  387761, 1 }, -- Emerald Blossom and Verdant Embrace instantly heal you for $s1 when cast
    potent_mana                    = {  93715,  418101, 1 }, -- Source of Magic increases the target's healing and damage done by $s1%
    protracted_talons              = {  93307,  369909, 1 }, -- Azure Strike damages $s1 additional enemy
    quell                          = {  93311,  351338, 1 }, -- Interrupt an enemy's spellcasting and prevent any spell from that school of magic from being cast for $s1 sec
    recall                         = {  93301,  371806, 1 }, -- You may reactivate Deep Breath within $s1 sec after landing to travel back in time to your takeoff location
    regenerative_magic             = {  93353,  387787, 1 }, -- Your Leech is increased by $s1%
    renewing_blaze                 = {  93354,  374348, 1 }, -- The flames of life surround you for $s1 sec. While this effect is active, $s2% of damage you take is healed back over $s3 sec
    rescue                         = {  93288,  370665, 1 }, -- Swoop to an ally and fly with them to the target location. Clears movement impairing effects from you and your ally
    scarlet_adaptation             = {  93340,  372469, 1 }, -- Store $s1% of your effective healing, up to $s2. Your next damaging Living Flame consumes all stored healing to increase its damage dealt
    sleep_walk                     = {  93293,  360806, 1 }, -- Disorient an enemy for $s1 sec, causing them to sleep walk towards you. Damage has a chance to awaken them
    source_of_magic                = {  93344,  369459, 1 }, -- Redirect your excess magic to a friendly healer for $s1 |$s2hour:hrs;. When you cast an empowered spell, you restore $s3% of their maximum mana per empower level. Limit $s4
    spatial_paradox                = {  93351,  406732, 1 }, -- Evoke a paradox for you and a friendly healer, allowing casting while moving and increasing the range of most spells by $s1% for $s2 sec. Affects the nearest healer within $s3 yds, if you do not have a healer targeted
    tailwind                       = {  93290,  375556, 1 }, -- Hover increases your movement speed by $s1% for the first $s2 sec
    terror_of_the_skies            = {  93342,  371032, 1 }, -- Deep Breath stuns enemies for $s1 sec
    time_spiral                    = {  93351,  374968, 1 }, -- Bend time, allowing you and your allies within $s1 yds to cast their major movement ability once in the next $s2 sec, even if it is on cooldown
    tip_the_scales                 = {  93350,  370553, 1 }, -- Compress time to make your next empowered spell cast instantly at its maximum empower level
    twin_guardian                  = {  93287,  370888, 1 }, -- Rescue protects you and your ally from harm, absorbing damage equal to $s1% of your maximum health for $s2 sec
    unravel                        = {  93308,  368432, 1 }, -- Sunder an enemy's protective magic, dealing $s$s2 Spellfrost damage to absorb shields
    verdant_embrace                = {  93341,  360995, 1 }, -- Fly to an ally and heal them for $s1, or heal yourself for the same amount
    walloping_blow                 = {  93286,  387341, 1 }, -- Wing Buffet and Tail Swipe knock enemies further and daze them, reducing movement speed by $s1% for $s2 sec
    zephyr                         = {  93346,  374227, 1 }, -- Conjure an updraft to lift you and your $s1 nearest allies within $s2 yds into the air, reducing damage taken from area-of-effect attacks by $s3% and increasing movement speed by $s4% for $s5 sec

    -- Devastation
    animosity                      = {  93330,  375797, 1 }, -- Casting an empower spell extends the duration of Dragonrage by $s1 sec, up to a maximum of $s2 sec
    arcane_intensity               = {  93274,  375618, 2 }, -- Disintegrate deals $s1% more damage
    arcane_vigor                   = {  93315,  386342, 1 }, -- Casting Shattering Star grants Essence Burst
    azure_celerity                 = {  93325, 1219723, 1 }, -- Disintegrate ticks $s1 additional time, but deals $s2% less damage
    azure_essence_burst            = {  93333,  375721, 1 }, -- Azure Strike has a $s1% chance to cause an Essence Burst, making your next Disintegrate or Pyre cost no Essence
    burnout                        = {  93314,  375801, 1 }, -- Fire Breath damage has $s1% chance to cause your next Living Flame to be instant cast, stacking $s2 times
    catalyze                       = {  93280,  386283, 1 }, -- While channeling Disintegrate your Fire Breath on the target deals damage $s1% more often
    causality                      = {  93366,  375777, 1 }, -- Disintegrate reduces the remaining cooldown of your empower spells by $s1 sec each time it deals damage. Pyre reduces the remaining cooldown of your empower spells by $s2 sec per enemy struck, up to $s3 sec
    charged_blast                  = {  93317,  370455, 1 }, -- Your Blue damage increases the damage of your next Pyre by $s1%, stacking $s2 times
    dense_energy                   = {  93284,  370962, 1 }, -- Pyre's Essence cost is reduced by $s1
    dragonrage                     = {  93331,  375087, 1 }, -- Erupt with draconic fury and exhale Pyres at $s1 enemies within $s2 yds. For $s3 sec, Essence Burst's chance to occur is increased to $s4%, and you gain the maximum benefit of Mastery: Giantkiller regardless of targets' health
    engulfing_blaze                = {  93282,  370837, 1 }, -- Living Flame deals $s1% increased damage and healing, but its cast time is increased by $s2 sec
    essence_attunement             = {  93319,  375722, 1 }, -- Essence Burst stacks $s1 times
    eternity_surge                 = {  93275,  359073, 1 }, -- Focus your energies to release a salvo of pure magic, dealing $s$s2 Spellfrost damage to an enemy. Damages additional enemies within $s3 yds when empowered. I: Damages $s4 enemies. II: Damages $s5 enemies. III: Damages $s6 enemies
    eternitys_span                 = {  93320,  375757, 1 }, -- Eternity Surge and Shattering Star hit twice as many targets
    event_horizon                  = {  93318,  411164, 1 }, -- Eternity Surge's cooldown is reduced by $s1 sec
    eye_of_infinity                = {  93318,  411165, 1 }, -- Eternity Surge deals $s1% increased damage to your primary target
    feed_the_flames                = {  93313,  369846, 1 }, -- After casting $s1 Pyres, your next Pyre will explode into a Firestorm. In addition, Pyre and Disintegrate deal $s2% increased damage to enemies within your Firestorm
    firestorm                      = {  93278,  368847, 1 }, -- An explosion bombards the target area with white-hot embers, dealing $s$s2 Fire damage to enemies over $s3 sec
    focusing_iris                  = {  93315,  386336, 1 }, -- Shattering Star's damage taken effect lasts $s1 sec longer
    font_of_magic                  = {  93279,  411212, 1 }, -- Your empower spells' maximum level is increased by $s1, and they reach maximum empower level $s2% faster
    heat_wave                      = {  93281,  375725, 2 }, -- Fire Breath deals $s1% more damage
    honed_aggression               = {  93329,  371038, 2 }, -- Azure Strike and Living Flame deal $s1% more damage
    imminent_destruction           = {  93326,  370781, 1 }, -- Deep Breath reduces the Essence costs of Disintegrate and Pyre by $s1 and increases their damage by $s2% for $s3 sec after you land
    imposing_presence              = {  93332,  371016, 1 }, -- Quell's cooldown is reduced by $s1 sec
    inner_radiance                 = {  93332,  386405, 1 }, -- Your Living Flame and Emerald Blossom are $s1% more effective on yourself
    iridescence                    = {  93321,  370867, 1 }, -- Casting an empower spell increases the damage of your next $s1 spells of the same color by $s2% within $s3 sec
    lay_waste                      = {  93273,  371034, 1 }, -- Deep Breath's damage is increased by $s1%
    onyx_legacy                    = {  93327,  386348, 1 }, -- Deep Breath's cooldown is reduced by $s1 min
    power_nexus                    = {  93276,  369908, 1 }, -- Increases your maximum Essence to $s1
    power_swell                    = {  93322,  370839, 1 }, -- Casting an empower spell increases your Essence regeneration rate by $s1% for $s2 sec
    pyre                           = {  93334,  357211, 1 }, -- Lob a ball of flame, dealing $s$s2 Fire damage to the target and nearby enemies
    ruby_embers                    = {  93282,  365937, 1 }, -- Living Flame deals $s1 damage over $s2 sec to enemies, or restores $s3 health to allies over $s4 sec. Stacks $s5 times
    ruby_essence_burst             = {  93285,  376872, 1 }, -- Your Living Flame has a $s1% chance to cause an Essence Burst, making your next Disintegrate or Pyre cost no Essence
    scintillation                  = {  93324,  370821, 1 }, -- Disintegrate has a $s1% chance each time it deals damage to launch a level $s2 Eternity Surge at $s3% power
    scorching_embers               = {  93365,  370819, 1 }, -- Fire Breath causes enemies to take up to $s1% increased damage from your Red spells, increased based on its empower level
    shattering_star                = {  93316,  370452, 1 }, -- Exhale bolts of concentrated power from your mouth at $s2 enemies for $s$s3 Spellfrost damage that cracks the targets' defenses, increasing the damage they take from you by $s4% for $s5 sec. Grants Essence Burst
    snapfire                       = {  93277,  370783, 1 }, -- Pyre and Living Flame have a $s1% chance to cause your next Firestorm to be instantly cast without triggering its cooldown, and deal $s2% increased damage
    spellweavers_dominance         = {  93323,  370845, 1 }, -- Your damaging critical strikes deal $s1% damage instead of the usual $s2%
    titanic_wrath                  = {  93272,  386272, 1 }, -- Essence Burst increases the damage of affected spells by $s1%
    tyranny                        = {  93328,  376888, 1 }, -- During Deep Breath and Dragonrage you gain the maximum benefit of Mastery: Giantkiller regardless of targets' health
    volatility                     = {  93283,  369089, 2 }, -- Pyre has a $s1% chance to flare up and explode again on a nearby target

    -- Flameshaper
    burning_adrenaline             = {  94946,  444020, 1 }, -- Engulf quickens your pulse, reducing the cast time of your next spell by $s1%. Stacks up to $s2 charges
    conduit_of_flame               = {  94949,  444843, 1 }, -- Critical strike chance against targets above $s1% health increased by $s2%
    consume_flame                  = {  94922,  444088, 1 }, -- Engulf consumes $s1 sec of Fire Breath from the target, detonating it and damaging all nearby targets equal to $s2% of the amount consumed, reduced beyond $s3 targets
    draconic_instincts             = {  94931,  445958, 1 }, -- Your wounds have a small chance to cauterize, healing you for $s1% of damage taken. Occurs more often from attacks that deal high damage
    engulf                         = {  94950,  443328, 1 }, -- Engulf your target in dragonflame, damaging them for $s1 Fire or healing them for $s2. For each of your periodic effects on the target, effectiveness is increased by $s3%. Requires Fire Breath to be active on the target
    enkindle                       = {  94956,  444016, 1 }, -- Essence abilities are enhanced with Flame, dealing $s1% of healing or damage done as Fire over $s2 sec
    expanded_lungs                 = {  94956,  444845, 1 }, -- Fire Breath's damage over time is increased by $s1%. Dream Breath's heal over time is increased by $s2%
    flame_siphon                   = {  99857,  444140, 1 }, -- Engulf reduces the cooldown of Fire Breath by $s1 sec
    fulminous_roar                 = {  94923, 1218447, 1 }, -- Fire Breath deals its damage $s1% more often
    lifecinders                    = {  94931,  444322, 1 }, -- Renewing Blaze also applies to your target or $s1 nearby injured ally at $s2% value
    red_hot                        = {  94945,  444081, 1 }, -- Engulf gains $s1 additional charge and deals $s2% increased damage and healing
    shape_of_flame                 = {  94937,  445074, 1 }, -- Tail Swipe and Wing Buffet scorch enemies and blind them with ash, causing their next attack within $s1 sec to miss
    titanic_precision              = {  94920,  445625, 1 }, -- Living Flame and Azure Strike have $s1 extra chance to trigger Essence Burst when they critically strike
    trailblazer                    = {  94937,  444849, 1 }, -- Hover and Deep Breath travel $s1% faster, and Hover travels $s2% further

    -- Scalecommander
    bombardments                   = {  94936,  434300, 1 }, -- Mass Disintegrate marks your primary target for destruction for the next $s2 sec. You and your allies have a chance to trigger a Bombardment when attacking marked targets, dealing $s$s3 Volcanic damage split amongst all nearby enemies
    diverted_power                 = {  94928,  441219, 1 }, -- Bombardments have a chance to generate Essence Burst
    extended_battle                = {  94928,  441212, 1 }, -- Essence abilities extend Bombardments by $s1 sec
    hardened_scales                = {  94933,  441180, 1 }, -- Obsidian Scales reduces damage taken by an additional $s1%
    maneuverability                = {  94941,  433871, 1 }, -- Deep Breath can now be steered in your desired direction. In addition, Deep Breath burns targets for $s$s2 Volcanic damage over $s3 sec
    mass_disintegrate              = {  94939,  436335, 1 }, -- Empower spells cause your next Disintegrate to strike up to $s1 targets. When striking fewer than $s2 targets, Disintegrate damage is increased by $s3% for each missing target
    melt_armor                     = {  94921,  441176, 1 }, -- Deep Breath causes enemies to take $s1% increased damage from Bombardments and Essence abilities for $s2 sec
    menacing_presence              = {  94933,  441181, 1 }, -- Knocking enemies up or backwards reduces their damage done to you by $s1% for $s2 sec
    might_of_the_black_dragonflight = {  94952,  441705, 1 }, -- Black spells deal $s1% increased damage
    nimble_flyer                   = {  94943,  441253, 1 }, -- While Hovering, damage taken from area of effect attacks is reduced by $s1%
    onslaught                      = {  94944,  441245, 1 }, -- Entering combat grants a charge of Burnout, causing your next Living Flame to cast instantly
    slipstream                     = {  94943,  441257, 1 }, -- Deep Breath resets the cooldown of Hover
    unrelenting_siege              = {  94934,  441246, 1 }, -- For each second you are in combat, Azure Strike, Living Flame, and Disintegrate deal $s1% increased damage, up to $s2%
    wingleader                     = {  94953,  441206, 1 }, -- Bombardments reduce the cooldown of Deep Breath by $s1 sec for each target struck, up to $s2 sec
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    chrono_loop                    = 5456, -- (383005) Trap the enemy in a time loop for $s1 sec. Afterwards, they are returned to their previous location and health. Cannot reduce an enemy's health below $s2%
    divide_and_conquer             = 5556, -- (384689) Deep Breath forms curtains of fire, preventing line of sight to enemies outside its walls and burning enemies who walk through them for $s$s2 Fire damage. Lasts $s3 sec
    dreamwalkers_embrace           = 5617, -- (415651) Verdant Embrace tethers you to an ally, increasing movement speed by $s1% and slowing and siphoning $s2 life from enemies who come in contact with the tether. The tether lasts up to $s3 sec or until you move more than $s4 yards away from your ally
    nullifying_shroud              = 5467, -- (1241352) Verdant Embrace wreathes you in arcane energy, preventing the next full loss of control effect against you. Lasts $s1 sec
    obsidian_mettle                = 5460, -- (378444) While Obsidian Scales is active you gain immunity to interrupt, silence, and pushback effects
    scouring_flame                 = 5462, -- (378438) Fire Breath burns away $s1 beneficial Magic effect per empower level from all targets
    swoop_up                       = 5466, -- (370388) Grab an enemy and fly with them to the target location
    time_stop                      = 5464, -- (378441) Freeze an ally's timestream for $s1 sec. While frozen in time they are invulnerable, cannot act, and auras do not progress. You may reactivate Time Stop to end this effect early
    unburdened_flight              = 5469, -- (378437) Hover makes you immune to movement speed reduction effects
} )

-- Support 'in_firestorm' virtual debuff.
local firestorm_enemies = {}
local firestorm_last = 0
local firestorm_cast = 368847
local firestorm_tick = 369374

local eb_col_casts = 0
local animosityExtension = 0 -- Maintained by CLEU

spec:RegisterCombatLogEvent( function( _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID == state.GUID then
        if subtype == "SPELL_CAST_SUCCESS" then
            if spellID == firestorm_cast then
                wipe( firestorm_enemies )
                firestorm_last = GetTime()
                return
            elseif spellID == spec.abilities.emerald_blossom.id then
                eb_col_casts = ( eb_col_casts + 1 ) % 3
                return
            elseif spellID == 375087 then  -- Dragonrage
                animosityExtension = 0
                return
            end

            if state.talent.animosity.enabled and animosityExtension < 4 then
                -- Empowered spell casts increment this extension tracker by 1
                for _, ability in pairs( class.abilities ) do
                    if ability.empowered and spellID == ability.id then
                        animosityExtension = animosityExtension + 1
                        break
                    end
                end
            end
        end

        if subtype == "SPELL_DAMAGE" and spellID == firestorm_tick then
            local n = firestorm_enemies[ destGUID ]

            if n then
                firestorm_enemies[ destGUID ] = n + 1
                return
            else
                firestorm_enemies[ destGUID ] = 1
            end
            return
        end
    end
end )

spec:RegisterStateExpr( "cycle_of_life_count", function()
    return eb_col_casts
end )

-- Auras
spec:RegisterAuras( {
    -- Talent: The cast time of your next Living Flame is reduced by $w1%.
    -- https://wowhead.com/beta/spell=375583
    ancient_flame = {
        id = 375583,
        duration = 3600,
        max_stack = 1
    },
    -- Damage taken has a chance to summon air support from the Dracthyr.
    bombardments = {
        id = 434473,
        duration = 6.0,
        pandemic = true,
        max_stack = 1
    },
    -- Next spell cast time reduced by $s1%.
    burning_adrenaline = {
        id = 444019,
        duration = 15.0,
        max_stack = 2
    },
    -- Talent: Next Living Flame's cast time is reduced by $w1%.
    -- https://wowhead.com/beta/spell=375802
    burnout = {
        id = 375802,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Your next Pyre deals $s1% more damage.
    -- https://wowhead.com/beta/spell=370454
    charged_blast = {
        id = 370454,
        duration = 30,
        max_stack = 20
    },
    chrono_loop = {
        id = 383005,
        duration = 5,
        max_stack = 1
    },
    cycle_of_life = {
        id = 371877,
        duration = 15,
        max_stack = 1
    },
    --[[ Suffering $w1 Volcanic damage every $t1 sec.
    -- https://wowhead.com/beta/spell=353759
    deep_breath = {
        id = 353759,
        duration = 1,
        tick_time = 0.5,
        type = "Magic",
        max_stack = 1
    }, -- TODO: Effect of impact on target. ]]
    -- Spewing molten cinders. Immune to crowd control.
    -- https://wowhead.com/beta/spell=357210
    deep_breath = {
        id = 357210,
        duration = 6,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Spellfrost damage every $t1 sec.
    -- https://wowhead.com/beta/spell=356995
    disintegrate = {
        id = 356995,
        duration = function () return 3 * ( talent.natural_convergence.enabled and 0.8 or 1 ) * ( buff.burning_adrenaline.up and 0.7 or 1 ) end,
        tick_time = function () return spec.auras.disintegrate.duration / ( 4 + talent.azure_celerity.rank ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Essence Burst has a $s2% chance to occur.$?s376888[    Your spells gain the maximum benefit of Mastery: Giantkiller regardless of targets' health.][]
    -- https://wowhead.com/beta/spell=375087
    dragonrage = {
        id = 375087,
        duration = 18,
        max_stack = 1
    },
    -- Releasing healing breath. Immune to crowd control.
    -- https://wowhead.com/beta/spell=359816
    dream_flight = {
        id = 359816,
        duration = 6,
        type = "Magic",
        max_stack = 1
    },
    -- Healing for $w1 every $t1 sec.
    -- https://wowhead.com/beta/spell=363502
    dream_flight_hot = {
        id = 363502,
        duration = 15,
        type = "Magic",
        max_stack = 1,
        dot = "buff"
    },
    -- When $@auracaster casts a non-Echo healing spell, $w2% of the healing will be replicated.
    -- https://wowhead.com/beta/spell=364343
    echo = {
        id = 364343,
        duration = 15,
        max_stack = 1
    },
    -- Healing and restoring mana.
    -- https://wowhead.com/beta/spell=370960
    emerald_communion = {
        id = 370960,
        duration = 5,
        max_stack = 1
    },
    enkindle = {
        id = 444017,
        duration = 8,
        type = "Magic",
        tick_time = 2,
        max_stack = 1
    },
    -- Your next Disintegrate or Pyre costs no Essence.
    -- https://wowhead.com/beta/spell=359618
    essence_burst = {
        id = 359618,
        duration = 15,
        max_stack = function() return talent.essence_attunement.enabled and 2 or 1 end
    },
    eternity_surge_x3 = { -- TODO: This is the channel with 3 ranks.
        id = 359073,
        duration = 2.5,
        max_stack = 1
    },
    eternity_surge_x4 = { -- TODO: This is the channel with 4 ranks.
        id = 382411,
        duration = 3.25,
        max_stack = 1
    },
    eternity_surge = {
        alias = { "eternity_surge_x4", "eternity_surge_x3" },
        aliasMode = "first",
        aliasType = "buff",
        duration = 3.25
    },
    feed_the_flames_stacking = {
        id = 405874,
        duration = 120,
        max_stack = 9
    },
    feed_the_flames_pyre = {
        id = 411288,
        duration = 60,
        max_stack = 1
    },
    fire_breath = {
        id = 357209,
        duration = function ()
            local base = 26 + 4 * talent.blast_furnace.rank
            base = base - 6 * empowerment_level
            return base
        end,
        -- TODO: damage = function () return 0.322 * stat.spell_power * action.fire_breath.spell_targets * ( talent.heat_wave.enabled and 1.2 or 1 ) * ( debuff.shattering_star.up and 1.2 or 1 ) end,
        type = "Magic",
        max_stack = 1,
        copy = { "fire_breath_damage", "fire_breath_dot" }
    },
    firestorm = { -- TODO: Check for totem?
        id = 369372,
        duration = 6,
        max_stack = 1
    },
    -- Increases the damage of Fire Breath by $s1%.
    -- https://wowhead.com/beta/spell=377087
    full_belly = {
        id = 377087,
        duration = 600,
        type = "Magic",
        max_stack = 1
    },
    -- Movement speed increased by $w2%.$?e0[ Area damage taken reduced by $s1%.][]; Evoker spells may be cast while moving. Does not affect empowered spells.$?e9[; Immune to movement speed reduction effects.][]
    hover = {
        id = 358267,
        duration = function () return talent.extended_flight.enabled and 10 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    -- Essence costs of Disintegrate and Pyre are reduced by $s1, and their damage increased by $s2%.
    imminent_destruction = {
        id = 411055,
        duration = 12,
        max_stack = 1
    },
    in_firestorm = {
        duration = 6,
        max_stack = 1,
        generate = function( t )
            t.name = class.auras.firestorm.name

            if firestorm_last + 6 > query_time and firestorm_enemies[ target.unit ] then
                t.applied = firestorm_last
                t.duration = 6
                t.expires = firestorm_last + 6
                t.count = 1
                t.caster = "player"
                return
            end

            t.applied = 0
            t.duration = 0
            t.expires = 0
            t.count = 0
            t.caster = "nobody"
        end
    },
    -- Your next Blue spell deals $s1% more damage.
    -- https://wowhead.com/beta/spell=386399
    iridescence_blue = {
        id = 386399,
        duration = 10,
        max_stack = 2
    },
    -- Your next Red spell deals $s1% more damage.
    -- https://wowhead.com/beta/spell=386353
    iridescence_red = {
        id = 386353,
        duration = 10,
        max_stack = 2
    },
    -- Talent: Rooted.
    -- https://wowhead.com/beta/spell=355689
    landslide = {
        id = 355689,
        duration = 15,
        mechanic = "root",
        type = "Magic",
        max_stack = 1
    },
    leaping_flames = {
        id = 370901,
        duration = 30,
        max_stack = function() return max_empower end
    },
    -- Sharing $s1% of healing to an ally.
    -- https://wowhead.com/beta/spell=373267
    lifebind = {
        id = 373267,
        duration = 5,
        max_stack = 1
    },
    -- Burning for $w2 Fire damage every $t2 sec.
    -- https://wowhead.com/beta/spell=361500
    living_flame = {
        id = 361500,
        duration = 12,
        type = "Magic",
        max_stack = 3,
        copy = { "living_flame_dot", "living_flame_damage" }
    },
    -- Healing for $w2 every $t2 sec.
    -- https://wowhead.com/beta/spell=361509
    living_flame_hot = {
        id = 361509,
        duration = 12,
        type = "Magic",
        max_stack = 3,
        dot = "buff",
        copy = "living_flame_heal"
    },
    --
    -- https://wowhead.com/beta/spell=362980
    mastery_giantkiller = {
        id = 362980,
        duration = 3600,
        max_stack = 1
    },
    -- $?e0[Suffering $w1 Volcanic damage every $t1 sec.][]$?e1[ Damage taken from Essence abilities and bombardments increased by $s2%.][]
    melt_armor = {
        id = 441172,
        duration = 12.0,
        tick_time = 2.0,
        max_stack = 1
    },
    -- Damage done to $@auracaster reduced by $s1%.
    menacing_presence = {
        id = 441201,
        duration = 8.0,
        max_stack = 1
    },
    -- Talent: Armor increased by $w1%. Magic damage taken reduced by $w2%.$?$w3=1[  Immune to interrupt and silence effects.][]
    -- https://wowhead.com/beta/spell=363916
    obsidian_scales = {
        id = 363916,
        duration = 12,
        max_stack = 1
    },
    -- Talent: The duration of incoming crowd control effects are increased by $s2%.
    -- https://wowhead.com/beta/spell=372048
    oppressing_roar = {
        id = 372048,
        duration = 10,
        max_stack = 1
    },
    -- Talent: Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=370898
    permeating_chill = {
        id = 370898,
        duration = 3,
        mechanic = "snare",
        max_stack = 1
    },
    power_swell = {
        id = 376850,
        duration = 4,
        max_stack = 1
    },
    -- Talent: $w1% of damage taken is being healed over time.
    -- https://wowhead.com/beta/spell=374348
    renewing_blaze = {
        id = 374348,
        duration = function() return talent.foci_of_life.enabled and 4 or 8 end,
        max_stack = 1
    },
    -- Talent: Restoring $w1 health every $t1 sec.
    -- https://wowhead.com/beta/spell=374349
    renewing_blaze_heal = {
        id = 374349,
        duration = function() return talent.foci_of_life.enabled and 4 or 8 end,
        max_stack = 1
    },
    recall = {
        id = 371807,
        duration = 10,
        max_stack = function () return talent.essence_attunement.enabled and 2 or 1 end
    },
    -- Talent: About to be picked up!
    -- https://wowhead.com/beta/spell=370665
    rescue = {
        id = 370665,
        duration = 1,
        max_stack = 1
    },
    -- Next attack will miss.
    shape_of_flame = {
        id = 445134,
        duration = 4.0,
        max_stack = 1
    },
    -- Healing for $w1 every $t1 sec.
    -- https://wowhead.com/beta/spell=366155
    reversion = {
        id = 366155,
        duration = 12,
        max_stack = 1
    },
    scarlet_adaptation = {
        id = 372470,
        duration = 3600,
        max_stack = 1
    },
    -- Talent: Taking $w3% increased damage from $@auracaster.
    -- https://wowhead.com/beta/spell=370452
    shattering_star = {
        id = 370452,
        duration = function () return talent.focusing_iris.enabled and 6 or 4 end,
        type = "Magic",
        max_stack = 1,
        copy = "shattering_star_debuff"
    },
    -- Talent: Asleep.
    -- https://wowhead.com/beta/spell=360806
    sleep_walk = {
        id = 360806,
        duration = 20,
        mechanic = "sleep",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Your next Firestorm is instant cast and deals $s2% increased damage.
    -- https://wowhead.com/beta/spell=370818
    snapfire = {
        id = 370818,
        duration = 10,
        max_stack = 1
    },
    -- Talent: $@auracaster is restoring mana to you when they cast an empowered spell.
    -- https://wowhead.com/beta/spell=369459
    source_of_magic = {
        id = 369459,
        duration = 3600,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    -- Able to cast spells while moving and spell range increased by $s4%.
    spatial_paradox = {
        id = 406732,
        duration = 10.0,
        tick_time = 1.0,
        max_stack = 1
    },
    -- Talent:
    -- https://wowhead.com/beta/spell=370845
    spellweavers_dominance = {
        id = 370845,
        duration = 3600,
        max_stack = 1
    },
    -- Movement speed reduced by $s2%.
    -- https://wowhead.com/beta/spell=368970
    tail_swipe = {
        id = 368970,
        duration = 4,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=372245
    terror_of_the_skies = {
        id = 372245,
        duration = 3,
        mechanic = "stun",
        max_stack = 1
    },
    -- Talent: May use Death's Advance once, without incurring its cooldown.
    -- https://wowhead.com/beta/spell=375226
    time_spiral = {
        id = 375226,
        duration = 10,
        max_stack = 1
    },
    time_stop = {
        id = 378441,
        duration = 5,
        max_stack = 1
    },
    -- Talent: Your next empowered spell casts instantly at its maximum empower level.
    -- https://wowhead.com/beta/spell=370553
    tip_the_scales = {
        id = 370553,
        duration = 3600,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Absorbing $w1 damage.
    -- https://wowhead.com/beta/spell=370889
    twin_guardian = {
        id = 370889,
        duration = 5,
        max_stack = 1
    },
    unrelenting_siege = {
        id = 441248,
        duration = 3600,
        max_stack = 15,
        meta = {
            stack = function( t )
                return max( t.count, min( 15, time ) )
            end
        }
    },
    -- Movement speed reduced by $s2%.
    -- https://wowhead.com/beta/spell=357214
    wing_buffet = {
        id = 357214,
        duration = 4,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Damage taken from area-of-effect attacks reduced by $w1%.  Movement speed increased by $w2%.
    -- https://wowhead.com/beta/spell=374227
    zephyr = {
        id = 374227,
        duration = 8,
        max_stack = 1
    }
} )

local lastEssenceTick = 0

do
    local previous = 0

    spec:RegisterUnitEvent( "UNIT_POWER_UPDATE", "player", nil, function( event, unit, power )
        if power == "ESSENCE" then
            local value, cap = UnitPower( "player", Enum.PowerType.Essence ), UnitPowerMax( "player", Enum.PowerType.Essence )

            if value == cap then
                lastEssenceTick = 0

            elseif lastEssenceTick == 0 and value < cap or lastEssenceTick ~= 0 and value > previous then
                lastEssenceTick = GetTime()
            end

            previous = value
        end
    end )
end

spec:RegisterStateExpr( "empowerment_level", function()
    return buff.tip_the_scales.down and args.empower_to or max_empower
end )

-- This deserves a better fix; when args.empower_to = "maximum" this will cause that value to become max_empower (i.e., 3 or 4).
spec:RegisterStateExpr( "maximum", function()
    return max_empower
end )

spec:RegisterStateExpr( "animosity_extension", function() return animosityExtension end )

spec:RegisterHook( "runHandler", function( action )
    local ability = class.abilities[ action ]
    local color = ability.color

    if color == "blue" then
        if buff.iridescence_blue.up then removeStack( "iridescence_blue" ) end
        if talent.charged_blast.enabled then
            addStack( "charged_blast", nil, ( min( active_enemies, ability.spell_targets ) ) )
        end

    elseif color == "red" then
       if buff.iridescence_red.up then removeStack( "iridescence_red" ) end

    end

    if ability.empowered then
        if talent.animosity.enabled and animosity_extension < 4 then
            animosity_extension = animosity_extension + 1
            buff.dragonrage.expires = buff.dragonrage.expires + 5
        end

        if talent.enkindle.enabled then applyDebuff( "target", "enkindle" ) end

        if talent.iridescence.enabled and color then
            local iridescenceBuffType = "iridescence_" .. color -- Constructs "iridescence_red", "iridescence_blue", etc.
            applyBuff( iridescenceBuffType, nil, 2 ) -- Apply the dynamically determined buff with 2 stacks.
        end

        if talent.mass_disintegrate.enabled then
            addStack( "mass_disintegrate_stacks" )
        end

        if talent.power_swell.enabled then applyBuff( "power_swell" ) end -- TODO: Modify Essence regen rate.

        if buff.tip_the_scales.up then
            removeBuff( "tip_the_scales" )
            setCooldown( "tip_the_scales", spec.abilities.tip_the_scales.cooldown )
        end

        removeBuff( "jackpot" )

    end

    if ability.spendType == "essence" then
        removeStack( "essence_burst" )
        if talent.enkindle.enabled then
            applyDebuff( "target", "enkindle" )
        end
        if talent.extended_battle.enabled then
            if debuff.bombardments.up then debuff.bombardments.expires = debuff.bombardments.expires + 1 end
        end
    end
end )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237658, 237656, 237655, 237654, 237653 },
        auras = {
            -- Flameshaper
            inner_flame = {
                id = 1236776,
                duration = 12,
                max_stack = 2
            },
            -- Scalecommander
            draconic_inspiration = {
                id = 1237241,
                duration = 30,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229283, 229281, 229279, 229280, 229278 },
        auras = {
            jackpot = {
                id = 1217769,
                duration = 40,
                max_stack = 2
            }
        }
    },
    -- Dragonflight
    tier31 = {
        items = { 207225, 207226, 207227, 207228, 207230 },
        auras = {
            emerald_trance = {
                id = 424155,
                duration = 10,
                max_stack = 5,
                copy = { "emerald_trance_stacking", 424402 }
            }
        }
    },
    tier30 = {
        items = { 202491, 202489, 202488, 202487, 202486, 217178, 217180, 217176, 217177, 217179 },
        auras = {
            obsidian_shards = {
                id = 409776,
                duration = 8,
                tick_time = 2,
                max_stack = 1
            },
            blazing_shards = {
                id = 409848,
                duration = 5,
                max_stack = 1
            }
        }
    },
    tier29 = {
        items = { 200381, 200383, 200378, 200380, 200382 },
        auras = {
            limitless_potential = {
                id = 394402,
                duration = 6,
                max_stack = 1
            }
        }
    }
} )

-- Pets
spec:RegisterPets({
    dracthyr_commando = {
        id = 219827,
        spell = "deep_breath",
        duration = 30,
    },
})

local EmeraldTranceTick = setfenv( function()
    addStack( "emerald_trance" )
end, state )

local EmeraldBurstTick = setfenv( function()
    addStack( "essence_burst" )
end, state )

local ExpireDragonrage = setfenv( function()
    buff.emerald_trance.expires = query_time + 5 * buff.emerald_trance.stack
    for i = 1, buff.emerald_trance.stack do
        state:QueueAuraEvent( "emerald_trance", EmeraldBurstTick, query_time + i * 5, "AURA_PERIODIC" )
    end
end, state )

local QueueEmeraldTrance = setfenv( function()
    local tick = buff.dragonrage.applied + 6
    while( tick < buff.dragonrage.expires ) do
        if tick > query_time then state:QueueAuraEvent( "dragonrage", EmeraldTranceTick, tick, "AURA_PERIODIC" ) end
        tick = tick + 6
    end
    if set_bonus.tier31_4pc > 0 then
        state:QueueAuraExpiration( "dragonrage", ExpireDragonrage, buff.dragonrage.expires )
    end
end, state )

-- Perhaps a bit overkill for current Devastation, but scalable and easy to modify
local GenerateEssenceBurst = setfenv( function ( baseChance, targets )

    local burstChance = baseChance or 0
    if not targets then targets = 1 end

    burstChance = burstChance * ( 1 + ( buff.inner_flame.stack * 0.5 ) ) -- TWW3 Flameshaper set

    if buff.dragonrage.up then
        burstChance = burstChance + 1
    end

    if burstChance >= 1 then
        addStack( "essence_burst" )
    end

end, state )

spec:RegisterHook( "reset_precast", function()
    animosity_extension = nil
    cycle_of_life_count = nil

    max_empower = talent.font_of_magic.enabled and 4 or 3

    if essence.current < essence.max and lastEssenceTick > 0 then
        local partial = min( 0.99, ( query_time - lastEssenceTick ) * essence.regen )
        gain( partial, "essence" )
        if Hekili.ActiveDebug then Hekili:Debug( "Essence increased to %.2f from passive regen.", partial ) end
    end

    if buff.dragonrage.up and set_bonus.tier31_2pc > 0 then
        QueueEmeraldTrance()
    end
end )

spec:RegisterStateTable( "evoker", setmetatable( {},{
    __index = function( t, k )
        if k == "use_early_chaining" then k = "use_early_chain" end
        local val = state.settings[ k ]
        if val ~= nil then return val end
        return false
    end
} ) )

local empowered_cast_time

do
    local stages = {
        1,
        1.75,
        2.5,
        3.25
    }

    empowered_cast_time = setfenv( function( n )
        if buff.tip_the_scales.up then return 0 end
        local power_level = n or args.empower_to or class.abilities[ this_action ].empowerment_default or max_empower

        -- Is this also impacting Eternity Surge?
        if settings.fire_breath_fixed > 0 then
            power_level = min( settings.fire_breath_fixed, power_level )
        end

        return stages[ power_level ] * ( talent.font_of_magic.enabled and 0.8 or 1 ) * ( buff.burning_adrenaline.up and 0.7 or 1 ) * haste
    end, state )
end

-- Support SimC expression release.dot_duration
spec:RegisterStateTable( "release", setmetatable( {},{
    __index = function( t, k )
        if k == "dot_duration" then return spec.auras.fire_breath.duration
        else return 0 end
    end
} ) )

-- Abilities
spec:RegisterAbilities( {
    -- Project intense energy onto 3 enemies, dealing 1,161 Spellfrost damage to them.
    azure_strike = {
        id = 362969,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",

        -- spend = 0.009,
        -- spendType = "mana",

        startsCombat = true,

        minRange = 0,
        maxRange = 25,

        damage = function () return stat.spell_power * 0.755 * ( debuff.shattering_star.up and 1.2 or 1 ) end, -- PvP multiplier = 1.
        critical = function() return stat.crit + conduit.spark_of_savagery.mod end,
        critical_damage = function () return talent.tyranny.enabled and 2.2 or 2 end,
        spell_targets = function() return talent.protracted_talons.enabled and 3 or 2 end,

        handler = function ()
            if talent.azure_essence_burst.enabled then GenerateEssenceBurst( 0.15, 1 ) end
            if talent.charged_blast.enabled then addStack( "charged_blast", nil, min( active_enemies, spell_targets.azure_strike ) ) end
        end
    },

    -- Weave the threads of time, reducing the cooldown of a major movement ability for all party and raid members by 15% for 1 |4hour:hrs;.
    blessing_of_the_bronze = {
        id = 364342,
        cast = 0,
        cooldown = 15,
        gcd = "spell",
        school = "arcane",
        color = "bronze",

        spend = 0.01,
        spendType = "mana",

        startsCombat = false,
        nobuff = "blessing_of_the_bronze",

        handler = function ()
            applyBuff( "blessing_of_the_bronze" )
            applyBuff( "blessing_of_the_bronze_evoker")
        end
    },

    -- Talent: Cauterize an ally's wounds, removing all Bleed, Poison, Curse, and Disease effects. Heals for 4,480 upon removing any effect.
    cauterizing_flame = {
        id = 374251,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "fire",
        color = "red",

        spend = 0.014,
        spendType = "mana",
        target = function ()
            return debuff.dispellable_poison.caster or debuff.dispellable_curse.caster or debuff.dispellable_disease.caster
        end,
        talent = "cauterizing_flame",
        startsCombat = true,
        toggle = "defensives",
        healing = function () return 3.50 * stat.spell_power end,

        usable = function()
            return buff.dispellable_poison.up or buff.dispellable_curse.up or buff.dispellable_disease.up, "requires dispellable effect"
        end,

        handler = function ()
            removeBuff( "dispellable_poison" )
            removeBuff( "dispellable_curse" )
            removeBuff( "dispellable_disease" )
            health.current = min( health.max, health.current + action.cauterizing_flame.healing )
            if talent.everburning_flame.enabled and debuff.fire_breath.up then debuff.fire_breath.expires = debuff.fire_breath.expires + 1 end
        end
    },

    -- Take in a deep breath and fly to the targeted location, spewing molten cinders dealing 6,375 Volcanic damage to enemies in your path. Removes all root effects. You are immune to movement impairing and loss of control effects while flying.
    deep_breath = {
        id = function ()
            if buff.recall.up then return 371807 end
            if talent.maneuverability.enabled then return 433874 end
            return 357210
        end,
        cast = 0,
        cooldown = function ()
            return talent.onyx_legacy.enabled and 60 or 120
        end,
        gcd = "spell",
        school = "firestorm",
        color = "black",
        toggle_terrain = "none",
        startsCombat = true,
        texture = 4622450,
        toggle = "cooldowns",
        notalent = "breath_of_eons",

        min_range = 20,
        max_range = 50,

        damage = function () return 2.30 * stat.spell_power end,

        usable = function() return settings.use_deep_breath, "settings.use_deep_breath is disabled" end,

        handler = function ()
            if buff.recall.up then
                removeBuff( "recall" )
            else
                setCooldown( "global_cooldown", 4 * haste ) -- TODO: Check.
                applyBuff( "recall", 9 )
                buff.recall.applied = query_time + 6
            end

            if talent.terror_of_the_skies.enabled then applyDebuff( "target", "terror_of_the_skies" ) end

            if set_bonus.tww3_scalecommander >= 4 then applyBuff( "draconic_inspiration" ) end
        end,

        copy = { "recall", 371807, 357210, 433874 }
    },

    -- Tear into an enemy with a blast of blue magic, inflicting 4,930 Spellfrost damage over 2.1 sec, and slowing their movement speed by 50% for 3 sec.
    disintegrate = {
        id = 356995,
        cast = function() return 3 * ( talent.natural_convergence.enabled and 0.8 or 1 ) * ( buff.burning_adrenaline.up and 0.7 or 1 ) end,
        channeled = true,
        cooldown = 0,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",

        spend = function () return buff.essence_burst.up and 0 or ( buff.imminent_destruction.up and 2 or 3 ) end,
        spendType = "essence",

        cycle = function() if talent.bombardments.enabled and buff.mass_disintegrate_stacks.up then return "bombardments" end end,
        usable = function() if moving and buff.hover.down and buff.spatial_paradox.down then return false, "disabled while moving" end end,
        startsCombat = true,

        damage = function () return 2.28 * stat.spell_power * ( 1 + 0.08 * talent.arcane_intensity.rank ) * ( talent.energy_loop.enabled and 1.2 or 1 ) * ( debuff.shattering_star.up and 1.2 or 1 ) end,
        critical = function () return stat.crit + conduit.spark_of_savagery.mod end,
        critical_damage = function () return talent.tyranny.enabled and 2.2 or 2 end,
        spell_targets = function() if buff.mass_disintegrate_stacks.up then return min( active_enemies, ( buff.draconic_inspiration.up and 5 or 3 ) ) end
            return 1
        end,

        min_range = 0,
        max_range = 25,

        start = function ()
            -- Many Color, Essence and Empower interactions have been moved to the runHandler hook
            applyDebuff( "target", "disintegrate" )
            if buff.mass_disintegrate_stacks.up then
                if talent.bombardments.enabled then applyDebuff( "target", "bombardments" ) end
                removeStack( "mass_disintegrate_stacks" )
            end

            removeStack( "burning_adrenaline" )

            -- Legacy
            if set_bonus.tier30_2pc > 0 then applyDebuff( "target", "obsidian_shards" ) end

        end,

        tick = function ()
            if talent.causality.enabled then
                reduceCooldown( "fire_breath", 0.5 )
                reduceCooldown( "eternity_surge", 0.5 )
            end
            if talent.charged_blast.enabled then addStack( "charged_blast" ) end
        end
    },

    -- Talent: Erupt with draconic fury and exhale Pyres at 3 enemies within 25 yds. For 14 sec, Essence Burst's chance to occur is increased to 100%, and you gain the maximum benefit of Mastery: Giantkiller regardless of targets' health.
    dragonrage = {
        id = 375087,
        cast = 0,
        cooldown = 120,
        gcd = "off",
        school = "physical",
        color = "red",

        talent = "dragonrage",
        startsCombat = true,

        toggle = "cooldowns",

        spell_targets = function () return min( 3, active_enemies ) end,
        damage = function () return action.living_pyre.damage * action.dragonrage.spell_targets end,

        handler = function ()

            for i = 1, ( max( 3, active_enemies ) ) do
                spec.abilities.pyre.handler()
            end
            applyBuff( "dragonrage" )

            if set_bonus.tww2 >= 2 then
            -- spec.abilities.shattering_star.handler()
            -- Except essence burst, so we can't use the handler.
                applyDebuff( "target", "shattering_star" )
                if talent.charged_blast.enabled then addStack( "charged_blast", nil, min( action.shattering_star.spell_targets, active_enemies ) ) end
            end

            -- Legacy
            if set_bonus.tier31_2pc > 0 then
                QueueEmeraldTrance()
            end
        end
    },

    -- Grow a bulb from the Emerald Dream at an ally's location. After 2 sec, heal up to 3 injured allies within 10 yds for 2,208.
    emerald_blossom = {
        id = 355913,
        cast = 0,
        cooldown = function()
            if talent.dream_of_spring.enabled or state.spec.preservation and level > 57 then return 0 end
            return 30.0 * ( talent.interwoven_threads.enabled and 0.9 or 1 )
        end,
        gcd = "spell",
        school = "nature",
        color = "green",

        spend = 0.14,
        spendType = "mana",

        startsCombat = false,

        healing = function () return 2.5 * stat.spell_power end,

        handler = function ()
            if state.spec.preservation then
                removeBuff( "ouroboros" )
                if buff.stasis.stack == 1 then applyBuff( "stasis_ready" ) end
                removeStack( "stasis" )
            end

            removeBuff( "nourishing_sands" )

            if talent.ancient_flame.enabled then applyBuff( "ancient_flame" ) end
            if talent.causality.enabled then reduceCooldown( "essence_burst", 1 ) end
            if talent.cycle_of_life.enabled then
                if cycle_of_life_count > 1 then
                    cycle_of_life_count = 0
                    applyBuff( "cycle_of_life" )
                else
                    cycle_of_life_count = cycle_of_life_count + 1
                end
            end
            if talent.dream_of_spring.enabled and buff.ebon_might.up then buff.ebon_might.expires = buff.ebon_might.expires + 1 end
        end
    },

    -- Engulf your target in dragonflame, damaging them for $443329s1 Fire or healing them for $443330s1. For each of your periodic effects on the target, effectiveness is increased by $s1%.
    engulf = {
        id = 443328,
        color = 'red',
        cast = 0.0,
        cooldown = 27,
        hasteCD = true,
        charges = function() return talent.red_hot.enabled and 2 or nil end,
        recharge = function() return talent.red_hot.enabled and 27 or nil end,
        gcd = "spell",
        toggle = "essences",
        spend = 0.050,
        spendType = 'mana',

        talent = "engulf",
        debuff = "fire_breath",
        startsCombat = true,

        velocity = 80,

        handler = function()
            -- Assume damage occurs.
            if talent.burning_adrenaline.enabled then addStack( "burning_adrenaline" ) end
            if talent.flame_siphon.enabled then reduceCooldown( "fire_breath", 6 ) end
            if talent.consume_flame.enabled and debuff.fire_breath.up then debuff.fire_breath.expires = max( query_time, debuff.fire_breath.expires - 2 ) end
            if set_bonus.tww3 >= 2 then addStack( "inner_flame" ) end
        end,

        impact = function() end,

        copy = { "engulf_damage", "engulf_healing", 443329, 443330 }
    },

    -- Talent: Focus your energies to release a salvo of pure magic, dealing 4,754 Spellfrost damage to an enemy. Damages additional enemies within 12 yds of the target when empowered. I: Damages 1 enemy. II: Damages 2 enemies. III: Damages 3 enemies.
    eternity_surge = {
        id = function() return talent.font_of_magic.enabled and 382411 or 359073 end,
        known = 359073,
        cast = empowered_cast_time,
        -- channeled = true,
        empowered = true,
        empowerment_default = function()
            local n = min( max_empower, active_enemies / ( talent.eternitys_span.enabled and 2 or 1 ) )
            if n % 1 > 0 then n = n + 0.5 end
            if Hekili.ActiveDebug then Hekili:Debug( "Eternity Surge empowerment level, cast time: %.2f, %.2f", n, empowered_cast_time( n ) ) end
            return n
        end,
        toggle = "essences",
        cooldown = function() return 30 - ( 3 * talent.event_horizon.rank ) end,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",
        usable = function()  
            if target.distance > 20 then
                return false, "out of range, disabled"
            end
            if moving then
                return false, "disabled while moving"
            end
        end,

        talent = "eternity_surge",
        startsCombat = true,

        spell_targets = function () return min( active_enemies, ( talent.eternitys_span.enabled and 2 or 1 ) * empowerment_level ) end,
        damage = function () return spell_targets.eternity_surge * 3.4 * stat.spell_power end,

        handler = function ()
            -- Many Color, Essence and Empower interactions have been moved to the runHandler hook

            -- TODO: Determine if we need to model projectiles instead.
            if talent.charged_blast.enabled then addStack( "charged_blast", nil, spell_targets.eternity_surge ) end

            if set_bonus.tier29_2pc > 0 then applyBuff( "limitless_potential" ) end
            if set_bonus.tier30_4pc > 0 then applyBuff( "blazing_shards" ) end
        end,

        copy = { 382411, 359073 }
    },

    -- Talent: Expunge toxins affecting an ally, removing all Poison effects.
    expunge = {
        id = 365585,
        cast = 0,
        cooldown = 8,
        gcd = "spell",
        school = "nature",
        color = "green",
        usable = function () return debuff.dispellable_poison.up, "requires dispellable_poison" end,
        spend = 0.10,
        spendType = "mana",
        target = function ()
            return debuff.dispellable_poison.caster 
        end,
        talent = "expunge",
        startsCombat = false,
        toggle = "defensives",
        buff = "dispellable_poison",

        handler = function ()
            removeBuff( "dispellable_poison" )
        end
    },

    -- Inhale, stoking your inner flame. Release to exhale, burning enemies in a cone in front of you for 8,395 Fire damage, reduced beyond 5 targets. Empowering causes more of the damage to be dealt immediately instead of over time. I: Deals 2,219 damage instantly and 6,176 over 20 sec. II: Deals 4,072 damage instantly and 4,323 over 14 sec. III: Deals 5,925 damage instantly and 2,470 over 8 sec. IV: Deals 7,778 damage instantly and 618 over 2 sec.
    fire_breath = {
        id = function() return talent.font_of_magic.enabled and 382266 or 357208 end,
        known = 357208,
        cast = empowered_cast_time,
        -- channeled = true,
        empowered = true,
        cooldown = function() return 30 * ( talent.interwoven_threads.enabled and 0.9 or 1 ) end,
        cooldown_estimate = function()
            if not talent.flame_siphon.enabled then return end
            if not talent.red_hot.enabled and cooldown.engulf.remains < action.fire_breath.cooldown then return action.fire_breath.cooldown - cooldown.engulf.remains end
            if cooldown.engulf.time_to_max_charges < action.fire_breath.cooldown then return action.fire_breath.cooldown - 12 end
            return action.fire_breath.cooldown - 6
        end,
        gcd = "spell",
        school = "fire",
        color = "red",
        usable = function()  
            if target.distance > 25 then
                return false, "settings.use_deep_breath is disabled"
            end
            if moving then
                return false, "disabled while moving"
            end
        end,
        toggle = "essences",
        spend = 0.026,
        spendType = "mana",

        startsCombat = true,
        caption = function()
            local power_level = settings.fire_breath_fixed
            if power_level > 0 then return power_level end
        end,

        spell_targets = function () return active_enemies end,
        damage = function () return 1.334 * stat.spell_power * ( 1 + 0.1 * talent.blast_furnace.rank ) * ( debuff.shattering_star.up and 1.2 or 1 ) end,
        critical = function () return stat.crit + conduit.spark_of_savagery.mod end,
        critical_damage = function () return talent.tyranny.enabled and 2.2 or 2 end,

        handler = function()
            -- Many Color, Essence and Empower interactions have been moved to the runHandler hook
            if talent.leaping_flames.enabled then applyBuff( "leaping_flames", nil, empowerment_level ) end
            if talent.mass_eruption.enabled then applyBuff( "mass_eruption_stacks" ) end -- ???

            applyDebuff( "target", "fire_breath" )
            -- applyDebuff( "target", "fire_breath_damage" ) -- This was causing Fire Breath durations to be wonky.

            if set_bonus.tier29_2pc > 0 then applyBuff( "limitless_potential" ) end
            if set_bonus.tier30_4pc > 0 then applyBuff( "blazing_shards" ) end
        end,

        copy = { 382266, 357208 }
    },

    -- Talent: An explosion bombards the target area with white-hot embers, dealing 2,701 Fire damage to enemies over 12 sec.
    firestorm = {
        id = 368847,
        cast = function() return buff.snapfire.up and 0 or 2 end,
        cooldown = function() return buff.snapfire.up and 0 or 20 end,
        gcd = "spell",
        school = "fire",
        color = "red",
        toggle = "essences",
        talent = "firestorm",
        startsCombat = true,
        usable = function()  if moving and buff.hover.down and buff.spatial_paradox.down then return false, "disabled while moving" end end,
        min_range = 0,
        max_range = 25,
        terrain = true,
        spell_targets = function () return active_enemies end,
        damage = function () return action.firestorm.spell_targets * 0.276 * stat.spell_power * 7 end,

        handler = function ()
            if buff.snapfire.up then
                removeBuff( "snapfire" )
                setCooldown( "firestorm", max( 0, action.firestorm.cooldown - action.firestorm.time_since ) ) -- Attempt to avoid (false) CD reset from Snapfire
            end
            applyDebuff( "target", "in_firestorm" )
            if talent.everburning_flame.enabled and debuff.fire_breath.up then debuff.fire_breath.expires = debuff.fire_breath.expires + 1 end
        end
    },

    -- Increases haste by 30% for all party and raid members for 40 sec. Allies receiving this effect will become Exhausted and unable to benefit from Fury of the Aspects or similar effects again for 10 min.
    fury_of_the_aspects = {
        id = 390386,
        cast = 0,
        cooldown = 300,
        gcd = "off",
        school = "arcane",

        spend = 0.04,
        spendType = "mana",

        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "fury_of_the_aspects" )
            applyDebuff( "player", "exhaustion" )
        end
    },

    -- Launch yourself and gain $s2% increased movement speed for $<dura> sec.; Allows Evoker spells to be cast while moving. Does not affect empowered spells.
    hover = {
        id = 358267,
        cast = 0,
        charges = function()
            local actual = 1 + ( talent.aerial_mastery.enabled and 1 or 0 ) + ( buff.time_spiral.up and 1 or 0 )
            if actual > 1 then return actual end
        end,
        usable = function()  if moving then return false, "disabled while moving" end end,
        cooldown = 35,
        recharge = function()
            local actual = 1 + ( talent.aerial_mastery.enabled and 1 or 0 ) + ( buff.time_spiral.up and 1 or 0 )
            if actual > 1 then return 35 end
        end,
        gcd = "off",
        school = "physical",

        startsCombat = true,

        handler = function ()
            applyBuff( "hover" )
        end
    },

    -- Talent: Conjure a path of shifting stone towards the target location, rooting enemies for 30 sec. Damage may cancel the effect.
    landslide = {
        id = 358385,
        cast = function() return ( talent.engulfing_blaze.enabled and 2.5 or 2 ) * ( buff.burnout.up and 0 or 1 ) end,
        cooldown = function() return 90 - ( talent.forger_of_mountains.enabled and 30 or 0 ) end,
        gcd = "spell",
        school = "firestorm",
        color = "black",

        spend = 0.014,
        spendType = "mana",

        talent = "landslide",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
        end
    },

    -- Send a flickering flame towards your target, dealing 2,625 Fire damage to an enemy or healing an ally for 3,089.
    living_flame = {
        id = 361469,
        cast = function() return ( talent.engulfing_blaze.enabled and 2.3 or 2 ) * ( buff.ancient_flame.up and 0.6 or 1 ) * haste end,
        cooldown = 0,
        gcd = "spell",
        school = "fire",
        color = "red",
        usable = function() if moving and buff.hover.down and buff.spatial_paradox.down then return false, "disabled while moving" end end,
        spend = 0.12,
        spendType = "mana",

        velocity = 45,
        startsCombat = true,

        damage = function () return 1.61 * stat.spell_power * ( talent.engulfing_blaze.enabled and 1.4 or 1 ) end,
        healing = function () return 2.75 * stat.spell_power * ( talent.engulfing_blaze.enabled and 1.4 or 1 ) * ( 1 + 0.03 * talent.enkindled.rank ) * ( talent.inner_radiance.enabled and 1.3 or 1 ) end,
        spell_targets = function () return buff.leaping_flames.up and min( active_enemies, 1 + buff.leaping_flames.stack ) end,

        handler = function ()
            -- Many Color, Essence and Empower interactions have been moved to the runHandler hook
            if buff.burnout.up then removeStack( "burnout" )
            else removeBuff( "ancient_flame" ) end

            if talent.ruby_embers.enabled then applyDebuff( "target", "living_flame" ) end

            if talent.essence_burst.enabled then GenerateEssenceBurst( 0.2, max( 2, ( group or health.percent < 100 and 2 or 1 ), action.living_flame.spell_targets ) ) end

            removeBuff( "leaping_flames" )
            removeBuff( "scarlet_adaptation" )
        end,

        impact = function()
            if talent.ruby_embers.enabled then addStack( "living_flame" ) end
        end,

        copy = "living_flame_damage"
    },

    -- Talent: Reinforce your scales, reducing damage taken by 30%. Lasts 12 sec.
    obsidian_scales = {
        id = 363916,
        cast = 0,
        charges = function() return talent.obsidian_bulwark.enabled and 2 or nil end,
        cooldown = 90,
        recharge = function() return talent.obsidian_bulwark.enabled and 90 or nil end,
        gcd = "off",
        school = "firestorm",
        color = "black",

        talent = "obsidian_scales",
        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            applyBuff( "obsidian_scales" )
        end
    },

    -- Let out a bone-shaking roar at enemies in a cone in front of you, increasing the duration of crowd controls that affect them by $s2% in the next $d.$?s374346[; Removes $s1 Enrage effect from each enemy.][]
    oppressing_roar = {
        id = 372048,
        cast = 0,
        cooldown = function() return 120 - 30 * talent.overawe.rank end,
        gcd = "spell",
        school = "physical",
        color = "black",

        talent = "oppressing_roar",
        startsCombat = true,

        toggle = "interrupts",

        handler = function ()
            applyDebuff( "target", "oppressing_roar" )
            if talent.overawe.enabled and debuff.dispellable_enrage.up then
                removeDebuff( "target", "dispellable_enrage" )
                reduceCooldown( "oppressing_roar", 20 )
            end
        end
    },

    -- Talent: Lob a ball of flame, dealing 1,468 Fire damage to the target and nearby enemies.
    pyre = {
        id = 357211,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "fire",
        color = "red",

        spend = function()
            if buff.essence_burst.up then return 0 end
            return 3 - talent.dense_energy.rank - ( buff.imminent_destruction.up and 1 or 0 )
        end,
        spendType = "essence",
        timeToReadyOverride = function()
            return buff.essence_burst.up and 0 or nil -- Essence Burst makes the spell ready immediately.
        end,

        talent = "pyre",
        startsCombat = true,

        handler = function ()
            -- Many Color, Essence and Empower interactions have been moved to the runHandler hook
            removeBuff( "feed_the_flames_pyre" )

            if talent.causality.enabled then
                reduceCooldown( "fire_breath", min( 2, true_active_enemies * 0.4 ) )
                reduceCooldown( "eternity_surge", min( 2, true_active_enemies * 0.4 ) )
            end
            if talent.feed_the_flames.enabled then
                if buff.feed_the_flames_stacking.stack == 8 then
                    applyBuff( "feed_the_flames_pyre" )
                    removeBuff( "feed_the_flames_stacking" )
                else
                    addStack( "feed_the_flames_stacking" )
                end
            end
            removeBuff( "charged_blast" )

            -- Legacy
            if set_bonus.tier30_2pc > 0 then applyDebuff( "target", "obsidian_shards" ) end
        end
    },

    -- Talent: Interrupt an enemy's spellcasting and preventing any spell from that school of magic from being cast for 4 sec.
    quell = {
        id = 351338,
        cast = 0,
        cooldown = function () return talent.imposing_presence.enabled and 20 or 40 end,
        gcd = "off",
        school = "physical",
        toggle = "interrupts",
        talent = "quell",
        startsCombat = true,
        target = function () 
            if not UnitExists("focus") then
                return debuff.casting_target.caster
            else
                return debuff.casting_focus.caster
            end
        end,
        usable = function () return state.readyToInterrupt() and target.distance <= 25, "readyToInterrupt" end,

        handler = function ()
            interrupt()
        end
    },

    -- Talent: The flames of life surround you for 8 sec. While this effect is active, 100% of damage you take is healed back over 8 sec.
    renewing_blaze = {
        id = 374348,
        cast = 0,
        cooldown = function () return talent.fire_within.enabled and 60 or 90 end,
        gcd = "off",
        school = "fire",
        color = "red",

        talent = "renewing_blaze",
        startsCombat = false,

        toggle = "defensives",

        -- TODO: o Pyrexia would increase all heals by 20%.

        handler = function ()
            if talent.everburning_flame.enabled and debuff.fire_breath.up then debuff.fire_breath.expires = debuff.fire_breath.expires + 1 end
            applyBuff( "renewing_blaze" )
            applyBuff( "renewing_blaze_heal" )
        end
    },

    -- Talent: Swoop to an ally and fly with them to the target location.
    rescue = {
        id = 370665,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "physical",

        talent = "rescue",
        startsCombat = false,
        toggle = "interrupts",

        usable = function() return not solo, "requires an ally" end,

        handler = function ()
            if talent.twin_guardian.enabled then applyBuff( "twin_guardian" ) end
        end
    },

    action_return = {
        id = 361227,
        cast = 10,
        cooldown = 0,
        school = "arcane",
        gcd = "spell",
        color = "bronze",

        spend = 0.01,
        spendType = "mana",

        startsCombat = true,
        texture = 4622472,

        handler = function ()
        end,

        copy = "return"
    },

    -- Talent: Exhale a bolt of concentrated power from your mouth for 2,237 Spellfrost damage that cracks the target's defenses, increasing the damage they take from you by 20% for 4 sec.
    shattering_star = {
        id = 370452,
        cast = 0,
        cooldown = 20,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",
        usable = function() return not moving, "use_unravel setting is OFF" end,
        talent = "shattering_star",
        startsCombat = true,

        spell_targets = function () return min( active_enemies, talent.eternitys_span.enabled and 2 or 1 ) end,
        damage = function () return 1.6 * stat.spell_power end,
        critical = function () return stat.crit + conduit.spark_of_savagery.mod end,
        critical_damage = function () return talent.tyranny.enabled and 2.2 or 2 end,

        handler = function ()
            applyDebuff( "target", "shattering_star" )
            if talent.arcane_vigor.enabled then GenerateEssenceBurst( 1, 1 ) end
            if talent.charged_blast.enabled then addStack( "charged_blast", nil, min( action.shattering_star.spell_targets, active_enemies ) ) end
            if set_bonus.tww2 >= 4 then addStack( "jackpot" ) end
        end
    },

    -- Talent: Disorient an enemy for 20 sec, causing them to sleep walk towards you. Damage has a chance to awaken them.
    sleep_walk = {
        id = 360806,
        cast = function() return 1.7 + ( talent.dream_catcher.enabled and 0.2 or 0 ) end,
        cooldown = function() return talent.dream_catcher.enabled and 0 or 15.0 end,
        gcd = "spell",
        school = "nature",
        color = "green",

        spend = 0.01,
        spendType = "mana",

        talent = "sleep_walk",
        startsCombat = true,

        toggle = "interrupts",

        handler = function ()
            applyDebuff( "target", "sleep_walk" )
        end
    },

    -- Talent: Redirect your excess magic to a friendly healer for 30 min. When you cast an empowered spell, you restore 0.25% of their maximum mana per empower level. Limit 1.
    source_of_magic = {
        id = 369459,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",

        talent = "source_of_magic",
        startsCombat = false,

        handler = function ()
            active_dot.source_of_magic = 1
        end
    },

    -- Evoke a paradox for you and a friendly healer, allowing casting while moving and increasing the range of most spells by $s4% for $d.; Affects the nearest healer within $407497A1 yds, if you do not have a healer targeted.
    spatial_paradox = {
        id = 406732,
        color = 'bronze',
        cast = 0.0,
        cooldown = 180,
        gcd = "off",

        talent = "spatial_paradox",
        startsCombat = true,
        toggle = "cooldowns",

        handler = function()
            applyBuff( "spatial_paradox" )
        end,

    },

    swoop_up = {
        id = 370388,
        cast = 0,
        cooldown = 90,
        gcd = "spell",

        pvptalent = "swoop_up",
        startsCombat = true,
        texture = 4622446,

        toggle = "cooldowns",

        handler = function ()
        end
    },

    tail_swipe = {
        id = 368970,
        cast = 0,
        cooldown = function() return 180 - ( talent.clobbering_sweep.enabled and 120 or 0 ) end,
        gcd = "spell",

        startsCombat = true,
        toggle = "interrupts",

        handler = function()
            if talent.menacing_presence.enabled then applyDebuff( "target", "menacing_presence" ) end
            if talent.walloping_blow.enabled then applyDebuff( "target", "walloping_blow" ) end
        end
    },

    -- Talent: Bend time, allowing you and your allies to cast their major movement ability once in the next 10 sec, even if it is on cooldown.
    time_spiral = {
        id = 374968,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        school = "arcane",
        color = "bronze",

        talent = "time_spiral",
        startsCombat = false,

        toggle = "interrupts",

        handler = function ()
            applyBuff( "time_spiral" )
            active_dot.time_spiral = group_members
            setCooldown( "hover", 0 )
        end
    },

    time_stop = {
        id = 378441,
        cast = 0,
        cooldown = 120,
        gcd = "off",
        icd = 1,

        pvptalent = "time_stop",
        startsCombat = true,
        texture = 4631367,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "target", "time_stop" )
        end
    },

    -- Talent: Compress time to make your next empowered spell cast instantly at its maximum empower level.
    tip_the_scales = {
        id = 370553,
        cast = 0,
        cooldown = 120,
        gcd = "off",
        school = "arcane",
        color = "bronze",

        talent = "tip_the_scales",
        startsCombat = true,

        toggle = "cooldowns",
        nobuff = "tip_the_scales",

        handler = function ()
            applyBuff( "tip_the_scales" )
        end
    },

    -- Talent: Sunder an enemy's protective magic, dealing 6,991 Spellfrost damage to absorb shields.
    unravel = {
        id = 368432,
        cast = 0,
        cooldown = 9,
        gcd = "spell",
        school = "spellfrost",
        color = "blue",

        spend = 0.01,
        spendType = "mana",

        talent = "unravel",
        startsCombat = true,
        debuff = "all_absorbs",
        spell_targets = 1,

        usable = function() return settings.use_unravel, "use_unravel setting is OFF" end,

        handler = function ()
            removeDebuff( "all_absorbs" )
            if buff.iridescence_blue.up then removeStack( "iridescence_blue" ) end
            if talent.charged_blast.enabled then addStack( "charged_blast" ) end
        end
    },

    -- Talent: Fly to an ally and heal them for 4,557.
    verdant_embrace = {
        id = 360995,
        cast = 0,
        cooldown = 24,
        gcd = "spell",
        school = "nature",
        color = "green",
        icd = 0.5,

        spend = 0.10,
        spendType = "mana",

        talent = "verdant_embrace",
        startsCombat = false,

        usable = function()
            return settings.use_verdant_embrace, "use_verdant_embrace setting is off"
        end,

        handler = function ()
            if talent.ancient_flame.enabled then applyBuff( "ancient_flame" ) end
        end
    },

    wing_buffet = {
        id = 357214,
        cast = 0,
        cooldown = function() return 180 - ( talent.heavy_wingbeats.enabled and 120 or 0 ) end,
        gcd = "spell",

        startsCombat = true,

        handler = function()
            if talent.menacing_presence.enabled then applyDebuff( "target", "menacing_presence" ) end
            if talent.walloping_blow.enabled then applyDebuff( "target", "walloping_blow" ) end
        end,
    },

    -- Talent: Conjure an updraft to lift you and your 4 nearest allies within 20 yds into the air, reducing damage taken from area-of-effect attacks by 20% and increasing movement speed by 30% for 8 sec.
    zephyr = {
        id = 374227,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        school = "physical",

        talent = "zephyr",
        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            applyBuff( "zephyr" )
            active_dot.zephyr = min( 5, group_members )
        end
    },
} )

spec:RegisterSetting( "dragonrage_pad", 0.5, {
    name = strformat( "%s: %s 缓冲", Hekili:GetSpellLinkWithTexture( spec.abilities.dragonrage.id ), Hekili:GetSpellLinkWithTexture( spec.talents.animosity[2] ) ),
    type = "range",
    desc = strformat( "如果设置大于0，则会分配额外的时间，以确保在 %s 持续时使用 %s 和 %s，减少无法延长它的风险。"
        .. "\n\n如果没有 %s 天赋支撑，这个设置将被忽略。", Hekili:GetSpellLinkWithTexture( spec.abilities.fire_breath.id ),
        Hekili:GetSpellLinkWithTexture( spec.abilities.eternity_surge.id ), Hekili:GetSpellLinkWithTexture( spec.abilities.dragonrage.id ),
        Hekili:GetSpellLinkWithTexture( spec.talents.animosity[2] ) ),
    min = 0,
    max = 1.5,
    step = 0.05,
    width = "full",
} )

spec:RegisterStateExpr( "dr_padding", function()
    return talent.animosity.enabled and settings.dragonrage_pad or 0
end )

spec:RegisterSetting( "use_deep_breath", true, {
    name = strformat( "使用 %s", Hekili:GetSpellLinkWithTexture( spec.abilities.deep_breath.id ) ),
    type = "toggle",
    desc = strformat( "如果勾选，可能会推荐使用 %s，这将迫使你的角色选择一个目的地进行移动。"
        .. "默认情况下，&s 需要【爆发】开关处于激活状态。\n\n"
        .. "如果不勾选，|W%s|w 将永远不会被推荐，如果一直不使用，可能会导致DPS损失。",
        Hekili:GetSpellLinkWithTexture( spec.abilities.deep_breath.id ), spec.abilities.deep_breath.name, spec.abilities.deep_breath.name ),
    width = "full",
} )

spec:RegisterSetting( "use_unravel", false, {
    name = strformat( "使用 %s", Hekili:GetSpellLinkWithTexture( spec.abilities.unravel.id ) ),
    type = "toggle",
    desc = strformat( "如果勾选，若你的目标拥有减伤盾，%s 可能会被推荐。默认情况下，|W%s|w 需要|cFFFFD100【打断】|r 开关处于激活状态。",
        Hekili:GetSpellLinkWithTexture( spec.abilities.unravel.id ), spec.abilities.unravel.name ),
    width = "full",
} )

spec:RegisterSetting( "fire_breath_fixed", 0, {
    name = strformat( "%s: 授权", Hekili:GetSpellLinkWithTexture( spec.abilities.fire_breath.id ) ),
    type = "range",
    desc = strformat( "如果设置为 |cffffd1000|r，%s 将根据优先级列表被推荐不同的授权级别。\n\n"
        .. "要强制使用特定等级的 %s，请将其设置为 1、2、3 或 4。\n\n"
        .. "如果所选授权级别超过了您的最大值，则将使用最大值。", Hekili:GetSpellLinkWithTexture( spec.abilities.fire_breath.id ),
        spec.abilities.fire_breath.name ),
    min = 0,
    max = 4,
    step = 1,
    width = "full"
} )

spec:RegisterSetting( "use_early_chain", false, {
    name = strformat( "%s: 链接通道", Hekili:GetSpellLinkWithTexture( spec.abilities.disintegrate.id ) ),
    type = "toggle",
    desc = strformat( "如果勾选，%s 可能会在正在引导|W%s|w 时被推荐，用于延长通道。",
        Hekili:GetSpellLinkWithTexture( spec.abilities.disintegrate.id ), spec.abilities.disintegrate.name ),
    width = "full"
} )

spec:RegisterSetting( "use_clipping", false, {
    name = strformat( "%s: 中断通道", Hekili:GetSpellLinkWithTexture( spec.abilities.disintegrate.id ) ),
    type = "toggle",
    desc = strformat( "如果勾选，在 %s 期间可能会打断通道推荐其他技能。", Hekili:GetSpellLinkWithTexture( spec.abilities.disintegrate.id ) ),
    width = "full",
} )

spec:RegisterSetting( "use_verdant_embrace", false, {
    name = strformat( "%s: %s", Hekili:GetSpellLinkWithTexture( spec.abilities.verdant_embrace.id ), Hekili:GetSpellLinkWithTexture( spec.talents.ancient_flame[2] ) ),
    type = "toggle",
    desc = strformat( "如果勾选，%s 可能被推荐用于 %s。", spec.abilities.verdant_embrace.name, spec.auras.ancient_flame.name ),
    width = "full"
} )

spec:RegisterRanges( "azure_strike" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    gcdSync = false,

    nameplates = true,
    nameplateRange = 20,--self
    rangeChecker = 20,

    damage = true,
    damageDots = true,
    damageOnScreen = true,
    damageExpiration = 8,

    potion = "tempered_potion",

    package = "湮灭Simc",
} )


spec:RegisterPack( "湮灭Simc", 20250608, [[Hekili:S3x)VXrYvI93IWID0mIKJ40KuswrKgIIsR39wVRGgTEXbdZM9mtpZ0M90D7(dYLlig4lb5IpN7q(6moGeJCXb4oyCW25qcqIpF25(JjAL38t(FH8EVQQURQ6Q)ygsQD3y)dET40v)Qx9Q33Vxv9Xdo(LhpCItQ7XFG12w7T992(b9h8125E7o44HPxe5E8WiNXN6md(hbolG)7R)h(f)2)KF(qVfJXhDHFOZeeejHzXJHhppnnk5H39UZ8sNNnQ)4Wf3nXBrMVtQxyW4yNPP4Fp(UJ8dhD305UN7eFomuVG76gmZlW9UJ9DssSxeojZ3n5Uor(4)Z29SWtDJ7pok64HJY88tF3GJhzcX3zN9aKjYD8XFWGDV39beYBYex2GDtaCgh8wBV7wd25Hlp5B6CQ7YtEAWSm)PlpzASNBWe)lwEIxWYtg(YLV3Y3Jn8D2ANTHHdR6NS8KpkcNw5hATxnpCqXBMXE4jDtJ9co1nTN842Eh24gNpU8hATL1dGh(Yp(JHr46KecONL2W2DRT)ABznqBUsKF6aenFSVF45lp5OyNzHbW)XLTAF8h(0IHE)TSU)MlpbELT3L))JZ)hXbjqOcxWNh53bxaVCoaWp2jg(p026Xd99sstqwex8)(bedNBGZiF3jhF4XdDgJCgWpL6gh4LEHDswmYT5Uik8C3y70WJhc8IJVySVRDQd8maAFa(lXEWR45WaXzU2UbUl8q07r7V8KblpzJLNK647gK2xa7e7KiNG(8zF5jxEjSxS8KZCaWa)s)Xob2UFskWeypbwbDYbGtG3IWeacQVl)Plqo2jEjEbPUZIbsuXO6rqrhbpGM2DKrXPHbP2HtTx4mZBCX7ddy3LNCNgxj9yi0OSPt7pjFRTFS7chVaKKauK(3FpcuG0HVV9CNeKvStnV0bm6OHxPAYsNQiNm5VyVi229t5leGnc3VbUSSea2XobNU8eaOPavlkY3BmcjycdXjL287FCkiYVgCrwRoxKfTdy1MDGMi)w9xhQFv7zRZgaq22zniB7S6KngN9oTLSDRMKc60grT63aqSQV1ASfu1(2AUdS7ASdSB97aTJ0yAFA32QGbW80JhUWl1BgzipxrEo6)jrzbeENV0miLwGZZDD8tN3pACkdtMhzpZjQy3igWZZ9cMzpY35tD7pj88GIhgokXBIhqztgdiDI2t)u3O5xex8JDjTkZCTz7GeRLq9nsoTxy4rtctl)JYGbMJKQGJ8ZkaK4x7vq1uxLMeq)dumvkM2cXKe1FGKPsYyOktcoj1KlykgMp0f8zhuX5GwMJaczySWBXcywOSSEXCDnRzmQ)4WqFK01FQxSR9OyxhyBsrxD(iu1lkg0XdbVfadftTNnEcPouGzPEr2qyfc(d112Z8XTFClpHPqmmiPFs6g7F35HN5gVPeq3FWMEt3p2XBce7bPEfgXc8F4f8O715w0kJElyr1bEbbQDW(B3FVlVKRonX3lkjfwGlknMLNirQNI2vacnJwb8ttrYEya8uULGE1z)ozUtksYbE5eGrrBzFeyvfagGRJzR)05lp5B5nlmUpZnDk0IHGBoGh7aLb)FbUzPXo(i7o8UEP4R5d)jaEWNnc7IcrCgn9jVL3LlH4MK4gmg2DZIta6qkefj5hKHhUW5tS5dq1DahaHdCTpJq1cFDRZoQehvzJOYiPydACy845iHZDXi34etoD4sXhQ8e20jEswc(eBmokK5DIlTiLzUNKftgojdU0MFVYokGSFCuwvmHpntZaj8y3XZrvb2PEiVJIWIPzeC)aIgovemHgRX7cH9c(0a7ReDawybtq2aaYSyIrEb8FXCdFsiJBfc2pNXe8Cpae1GXDrygImz(aiaDvWqphzwy8BWR9IbKV77TQBDM82XWEIWhYm)fEbHzj2XHoXv7wMe1wJOm0zsrsb(GqVe0FPUptaxyHeIb4omB8PjeZ49w1vKL8kQwEGBv290Sin89fGK70SGaGwZMmG8hgobzeN6K5NYLxh(eI8F)2GSnJD6BraKFqv(2sKsnK(DiQ7dN5ep9Hlp5B)nCp1Z377S8K3f5YcUDkPmcdgmf0TbHh6nLZGn1pB0iCd999odKBxEcOvFbgaj80Bd)mSc8XC4CUdQ1kli1ZNZrhaEIddhwNGUxoHcdSKI8KTFRRkdSSA2ifecpOF8mxFUCypHBa4B4gCQxWeF3QhUQEU8XRL3GUYdYl2djGOEtdb9i9uqfXeYsRbGuT6oUFevO1cvZCp2GmQfQjB6BK)6JcrvfaEn1B28uB1i02wMqY0IQzAZM)Z1szRaf5kT1GOS2BPK6unLIe5)ARrCCwAmxfBlSXKCo4cNH9w5NQqVQ1qJkl2kNJkw2p6OWMwrm8TxZ6hphfmzwiiHz0GcZPduqe(P4exqkeCiHMsmSBhyTeJ8klpzHB45KoSbBVgK)bFzM83sciLSmyZcDfle0i6MNgnYWnHKONzK5JUKVBbHPmTNpKPh(He)7GQYdRpPv1EQpLTF1qdYIb7Fa0E)NXnP80dzG(OxaOYNerAwtcXX2yma1LRmZ(qk5M4w15KzpkFgO72WBumxJyypA(ex)vLbrNpnd2obF29ovF9)4HFLzztlXQIwazytsdJxOZCf4efbSspdwNJ8alRrzlIkTMsGrHqGwrMYSeL1mcbQYjDzbbt52Y1j2)cBq9TxGT3umOoWtlUPIhT)GoeEusKIrLsi)Jue0nhfhz6WssoxenNqKSPzr2PZAKVzQqZLVJa7K2axKT3enY)hHUHqoQCKRBekalCsrju1jWd5QBWqu7kCpyb4Dk8padKaZBg9g5HHUW1p12jEryCXpbrwLblyNrGFxPx0JruvdFMNFJVPdAY(OIvhl6VZO94Q8Mp6IyD5NHUJJXWcsDXin6oHcl13150EgCWpNntpSRsSAY7dNfIvAexq9zLsOyekA8zs5JD9zbWQO0xehHR7eIwqQc1T)pOkF(BI3M4QlBmAn5rBhNvfBD6rcO6FoUt94GXEKzyYhBjNWNdECj8zMCc)qmfACRqGfN50pItkQQH9hj4Rff5ga)zb9cy08Tz)HnwQqdScomSGTrOlyrKf1rWfnfpScpivfGbg(yFxqizItukzc34evwH(TkzEPCQdkYXOGAtvf1Mvr9zXUUb0gsvbqvJnz0u87ab7HEkOPOwgJYzGaXTOCyLO(mDQiHtv5OBd2jlJtvl7kfEIMqpLDrDF90w)vqMW3S2eD(K4lQy1qPkLh7SP8LgcgysCtlEBHii(V8ZqXErWqgT0)1jLrDBmlNKb)hqI6h81vFbJbzLp6EAl1Vfh)ybtd(SGOjRu(Np3nqezCbYYKwhroRhFkj(so(rwNa3l8wKTaEUB65U4Rt)S8BpEcxvWfYzkkbdJFwqymbWNqEpnDQlMEEujXceJ6tutUKbIw21NR5A3leWrrZyj1lMSCwiOk4dgUTHD3ctXkoYDFITM7LgmQPEJXCrWRNUKsdvh54QouTg4mzscZsW(5rWkpVcKH8(B7(7QydRWUVPmLP5cGQvqtIR7Wn(P7yzR2e06gadA51QKQgt83(Pt8O0yISLdVi2B63Hy5ZFpg0t8WOVa)maTFjIe)KHHWZJysmi4HGtwaxXceOKF9Sirly4eDLaU5b7TPUyIbrGqqDC4IiFxicJh)83h)Raa)q4MZNuHfJUvGZpIkfRXSBFf14G7D5XdDhjxgMeBhfd8syksAZwIm3J0eLVHPUBlhgRH8(QMdZSOuwsawq9KfrHrXaWG1eCVdDDqsH93ldI01uUxlweGq2ZpZn6SiiscxmcjMGhcuSsyXEJtvkDuzprKmslv7BroufVxwaL)PJvR9Dv2YJc5(jQWBNN(ZxG1ec8(BcsSrYHpljOyEscNnd2ZiNQIbYvIi16dNJD01q3ih0Ptm3N5Bxh56JPGpIYbaRP2kCIZbJB1zetZombdhscuy33Gajg8o(mNar6Jdbp3WncWIb(EeeoNE8rVyRdE2HBDWWHBDqCiZ7PkZ1sz2gjpq0ewKtGzodEP03XDHP(8fwBWQf9pvvjNe09TxDP9RwEhE3(LymZv17G0og5uJZcQCYCcDRn)o19UjPmFFyEK2uLIFNyY4)qSWZjKMsollGWZMHSkQHpiLLUfGrh)jGpXa9oCrUD9CTBUXtaolmZRXoJ16QKu2ASMwjSu1qRR7zK9QQSUAHIqJfIuYqBnPgvFBL3Gu90tUQsbT09O(dFQW4pQribliYhgHuFMgaCzI(JbcQUS0sH7djuqAoGUF)WryTCz5iegBQuv5McBJSuAbrX5KT4jZXoqaKkEiajwLyOY(LWsmeOG4dy1g2K7yLmHuPpgDAYjLBvH7UfXDvL7Zcz9McKxpmntpPoNdvCLRiY8oYCuv4H4ofCR0lwQHgm4LL4fQm9Dadb6jJ4XGA)4WXW894Hp(51NgpfoXkOxRNFjALuYEIZcvxty(djOR02Gs9CY7)s1X4faOhRQa9K97G9y7CVXm54rteYhp(7Lr50LCcbPw6YgVf2QZ)rWElZ3qw)qp3jEYyhE2oK2foFUNVayOjwMfjwiwG2ymDi9P6EEAaAhN7Bjh)5vG3jEefyvr3yaXLXc5BdRTpLzCFVxAqaSoU)UvRaIjbP3bcYBB7AEiSIULqfqAB2qKBXATq6yQd52JucLzqFl9IOyY1HECpM1DduTWfsBDuhYtckhDOQkt0Viudh9)E5Zye3DkiUlp5Da1yWovS3e0rTjsVU0ccvSsUunl2ZLLCSCN8BxAV6wY)dGCpGtmr3xL8mQgstNATSv8Uvwy58uJvzLqR1ggdi8aaqMCj9aKuRKNhthvYTAP4(BNN1126xV0dw2pf2zX8FaHsehg5rNfdMxbuFRqDjvSiNirGNZf9xa4tbLs(qygIp3dJkKa5Zo861t3RCRXLlY144QS1HYhrHzWkAm7MyaQTu5130ALDfXOpig68S38EXz2fU692NX31hnYzNgApXZL7XVvT5FPJGJT8BoyVMdIzBJYx1fVWQ6mD1fOSXM)7gDNcFzWvf7rHbzj9tp)Cl7DJgtVbHvFxafGWKLqwlJDqZkzM8rnBM8aYmPEgBzwOqVfykJ8iVWDti3XrhgNsNIRNE4MsgCiYfUkX3fDD4jhP74cDgZOWcgMxmBEJUP7krQHIKRMaDh8u6O2ovhnetuaWA69PuAaGP7ddWKjmMgmAIDCwCmfu4uM7BS(k1NE(ds2GPcgyqq9XU0)CscdPyDzy6CSJq2z7KRFJPRT6BLDyJzGRIKUzdHYQ7Mt9h2mYno7eVO5Hb6kI7wTYHhOMx4ABhLv1SDLnAGOX)QtLrozr3ZDXkQXDp9CPjLB43ld5QMfs2XZB1VBBD7s5ZfDl4OdFcM1RPUXO(j986c(NJdK1AfvFOd6krK))Nd9vQhjm00asMzkIaMOC6bJPKV2kSFxUskcBHR(8xD(IjyX0lJPMYPWYfzD1QKlAviOlNP9DBvmmszhg7AIud1MpF50u7fOUCUwAFLUv2NbsAeRCMu83S(HYj33H1)NQTm)aJv2K6zMs9NIlZsZtoeJtoivyZCSdRK2vfaHmRIHP5ikEFHLo6my)Ynl6(DSqDcRzSZ1Hi6qV0BJ)4ixQ5KNGnR3mh0GgAPdru2UasTF3J6Big(wNekJ1tSszK0AkVVH2355xGlMDF5gKQ1DW)F(rjjVPBONGskSnuMYvCBa(5NdSnS)GC74OxOP10KdV7sVPWRsJKbE0tsk9K6bitgqR9eFWrcTSwvu8vzeKQ3693ZuWBxxAguhHQUjnnXvkHMla3ScHCHzJ(VVVARiv1ygiRYMr56sQR3QLBJ6V6ET4vVJWDDkIZsTmY1qe630U41tFNseqIyYVL54xwxV607u6Q9LwYFp2jUSuF1iEx1(uQHaflOgIgvQ8EGElm1C2rKfX2tcsg6VRA79jfhCm00uQ7vg17AYRLbRZ6qYvN1lWADRMSi3WwhJPaNV(WZwdUaXlpe0W0d5npEEMW4BhBM)VyzNghnR9jCfTseUUe6oXHGDhn7IBOufJY7hsfu8poeRz6eoqNOyB3pKoTS8BHKxAItlVi5u)dZV9yWsSm23lcxRDklJ3HAZ4d23QtxZDJ5bwxEj9AIA9a0v9wvwAQKEeoHRd0hFZ1IOcwytPlz324xhndv4ykUrxvqHTxjHWGTPobwt9qdm45SRymGt9sMZDcraAEPYi8Ex5KqlvIOILcoQQQPunTQPXoQLsPj4ZiMPdgms6dgm2y)7QRiEtuf8(uP5X((o3sIKEl(Xswxxg)Nvy2BlDwpXxLBLvKAuvZqxttI(my5nI0onLw(gyfOA9N38e1vW)OlwqhG6e7ZDhvkiiJf)OCYrhuC8ZyMmkGkylpmwnCqUXf030AorBwBRPWxCIHJAigCdWA3TPN0yNETllFI8w6qL0yOK9cIyGleWLVDYfaBaQ9kyoWhzOTIn4xuZEu1isVNaHRcnQPG4Cweq3rIFyQ8F3ggHUs6h5VPTLno(KszBPHKXyQ1KWDzgu7NAL3TMfl(Es6A1cstXpJg7)Pk4Lym0LwHr4f7afX2(5EL09kVy5lMkQDHs20lOjZDsKk9lTuQJGHdOvlhd7QUFYy)SjUMmnkg0a7fobzy3YOGjd6J7q2fjLaxtAcPAVqbpV6XODBbzO6IIFqHMJgsDKUNOgKoBKy1mXqVyQOpz8XimXs(PnhiiUOPxr)CpbbQFM7MImJGjbH1Pya7fDlFHfRiYb41Miavr10Xdckx)pVDfzVlsl3vnldpL1tz4lGkmKsmtU7RtcZgHDIbsOYX)njupGFzBqUZstHZuQ6ddhE3ND4sPRfbM)TSQRaO3hgNJ1VGvLIhh(utTkJMYkR1x50GBgLtd(sQYjRVavonOoLtMiynlVzvXGg0gLtwMvozTQkNS(kIYjR2qm0m7BvxlFHedBWJIjglb15qCWG32fIxTW9GUTWCvZ0DRTZ5pnVu5tyt21AMKkZQxRQLUTGvVzRDnSWgu7cBW6UWUIAkUP159gsFw595ViLL3PndAqZ2KAgiwTWRBHsJcfcgAIWMdWq)AitPAMnz5UgFp123yDnRDvKSQ0XuLsiVK(QXf2g1u7ZAufbUjDDMXAIL(5hTTOy3Zqks)bY9)81l)yR0uw)sMHl1hQ)JYZISEBiSppHbBu3YPx5CVI34wHulXqoCIuwQPe44kLjQZWgYKAoFe7eNcnY9tQ)dzVw(EeZluSqIbUESN3m0gfkQIzoCYBbZADBvZy7kkcy1GiG16icy1spZKgqtIagnO9vdrGbgfbmUKFtjcuxx7MRl93F0DAg)db(fBwFY9MGn5lJAk1mVwtZdxO)53F03yg)FdZ28LqTlLJ)lLAnXAQyGK72hx91eAB6yKULtUVsw7B1LbkU(1Hsrf8ASt9m2D(61BrQpDvVT9zNgIy(XHi)I2hXOSG07YMJ6V29viNFfI(1LDkNDsWB)5uB1qxnKaLBvpjNygvV78RPSfFvLO1sk2XA39H1Kt0kOeDl0FyQSrxNFtluwZRYD6pJmQhd((s5vFTixdQljwRn56A8BqXvKG1itUjQ6bYzeCTiRw1fLFfK1gL5ruTjA)(xRF(jUPj(xbk8o1feznwDjB2qutJdxmYznV1LK8gbtBpgyksBl5QYxepeCpAHxCCymYanngwdzXyV5hUie(1Zn7pL3SaxIJdZbj5b6fYN1znxYmzGEfiAw1Ta(I5HRirZAviAwfeTv66mIiAUFVmVOi3j9hr3UDO)NjYtICHemz4JpdydJzAo0atYfbJL1iv1SdOMTRFc8IG99CC1OPK1BjY6QYb7Yoq(d2tZfZV5fPZXgZJsSfDA4dPRXMTwEYldzNGtp8ktc7CnSLax4MFpbc)j9LpdD)87Yo0o0nfjMYlcH6BIUK6KAZqxdQ1LOXgk1tPWz6uzfpk0992MBKf9a2uCSY44E7MMPcaPQsyEilDBqaFX4Xnqp7Ih5o2dlxY5WgX8LfPbePRyr2lxI9nPKvnftAiSTUWlidTWq17EqXFZbuIz1pmg0kyLQILu3irlLjkKF1flQn2)UlBifn3i7T1KmOYAUmS3wlbupJAnltRYlnY1huJc)NewnUYcWwo0n2eFxWflYCbn1b0vZbvgQi6kRV58aOXH(uXn9hLrAbFfxkFjD5UHxSAaQtNzp2LHbJgkD3RXFVnXwdgZV9e2BYAw4CkD(Wzwx8KYhE)LN8nCy4a22QW6gVgcxeoXBQhD3zZpMQyI6h0FVpPhtgAMh)k1H60f8UunpVq4JLaLyL1N)nr04SKmNDxOJDfZy6i6oH1sOsJUyg8cghJEKLWA36jU8)eMIhd)g7U)MVOkMJPItzKJK(awZ4qx2b0)I6ZBuGsOGqqZvVqgle55LE3qg6wb2qRvGn0AvydnKftZ6qkwgLoQ(nVo22mPjpHCeyxD3yncwlnWEfC0JKrJZgDH95ZD9JStMtmoLLJbJijrSIodSEoXby3F7nMd9sRBET6j0B1DPsDVRb0ZALrplf0Bn9htamHiztjFw25IQToHRSMSDPA(cFKuiz9ehzsdqHjtZgHeeuD7U3s(9WKQhqTEAgyEA0djsZG2G89E2TfFf(OEtUP0yDrYFAjxovVinL8uxIwEJVRvCvcFtUTvANReKkO98DuknaLoR1RGwGkdaw(lYQI6aZb(ziQjZq1KiQA)RultxQHZSDlzGROstxB8XDuPu(N5ZsTKmTg(X6foxDNnh0FB9mxP5k4lOYpmq6ljgn2L8lle2LsBbDkEaz(JDz1MA4SlJ4uSBJxeXQx6T53VZ3td7kU0SNwCPqrxRISlqX5GdsKpQIB3A(aZIa)xPhi1rW9POGFgDI1wGolkUv83nXDmEWoDxKG3SJ5x9TjN7copgfYoSDP0Hih9s2f5vXVdzOdGEO4zcEKMWR)ryc(gcCIWKfHSlXo8(s5E4KG3Lfjm)Gh5oJYXiUGgv8DieVqozv6XK7qRiXfp5Rse4Dj4AYFOwa3sFlPZVvUtnCOcB9fsDM6xAhoq1BgHQZ0QArHkxh1cPbcpvClAKXQ(u1NHathMSH022q27a8z5V0YtEoSjK57lrb0Utvt1pQBJWULhDMIRyCuCyWN6ktwtnCU3kVcY)IxQKpAkj3SJMiluUoYXrlDlzIhnnbkXUAmt1pGzdhOMsz(b0ReQK)m9ANvSJz62CQ4PKxOg)8FzDFTDsb(OD6gnvfHYyLus5RUiVgqMJ53xVavIUDbbPwR92EpWU7WZb)Hbej54HF(p)V9Z(39d)D)6)JF2)TF9N9V8V52C1(j3(Z(b)vF(p5N()9h)9)8)2)Kx9l)(V6x9F6Z)x939z)WF6R(N(fV(V8F4)Z3)F(Y373(Z(z785)K)C4L)8FZp71)f)xfVC)YnkZTF1V8xDBj7mLE(V7x)dg86F2p539R)ZU2bna2MGPCF8RdpLNDdIM3GGUrkWG(4jCfuHDH9KOK8SrPc4QguBr8wojkoOUcaVuU00bC5bCJcCjI(UnbvJBKgEEze(Ad0TaDRwkzqtsjxBO5niOBKcy1gg4QguBr8wojnjLufWBGr20aUrbUerFVMGABv3vgHV2a9QGUTNiSgiC7bEJO8AiQ0weEna9QGUTxz8AGWTh4Rck3wYWAGWTf0nIURHCrBr31a0sO79UUGzz09Ad0TaDlv9bDGwEaRbc3Ene3Oa)nf94(xxIh3GGwIwufmBGwyAaRbc3EDB3Oa)nf94bnXo3wH7BqqlrlQcMxlYjnIWTx0(gf4VPOhFTMyNBRW9niOLOfvbZRf5Kgr42lAFJc83i0JLVNEUXYBa1wMCSbvGBySYugpZ7JdDKZWiktqVAGxubV1bWmQ2fvI1INF9c6RcgJ5a1HDTVwjwlpMR)P4QG9u5XQeVzp96eSxfCftQDLOk9WRrGUgiAtDnSb9e1p(vAQnvDztAMmnSYtKvfggBsdGXrCDd(A2BAeWg1cy45xVG(QGXvk9xXyU(NIRc2BqtqPNEDc2RcUwwxG(dVgb6AGOnQWOStQRQcMAM6MvWu9WkprMJyFT8z7gf4VUPKmSwq9lAu2tVRVnyPqBanGYpC5jpjmauKq39EHrUmKjH1jk3UQUiQt36wkV9Bx8tLB5993(YlR75V9BxhSX3UUfCVBZAsL1f1Vsy(vdX7tBpMZ7XAfXC59(RrG)6MsvZAb1VOr5gKWmnGgq5vvcZQeBQHLY1MeMbyRWOAybxTew7q9ReMF1qCMeM5Shv7zCXGE2khAz(HAMWkpHcgMXQh7knLxXSG8BRkfl1E6mmigTceWAMWwsaBySR0uE1tX4aZ(Rz8KwyydQ0qwTzOYdcHHPQ6XAyoRQ9KACvzEiR2m0YvvdJ1WCEL6kJ226hxTzbv7wxVF0sOZ6Nv25vO(fIYiVrMVMsMtvn5tlOxTVT1UAZYAUROd9QPs1oYBK5RPDLQQXFlOxRGSYvAwACxPDq)6tw5QpFR3Usl5IVI7kTCwwZDLvH396yxzvMVM2vQji)MZzZQKu4kMPBGSdnOYWQ8pRSjF83AnmgyagdmcJx9p(38QF5)6x)J(bV()8p(Z(F9F)Z(X)0x)d)(F()IFdReDV6x(ZF1V5F63(x(t)D)6)8x9B(tF9F1)Lx))4hHJ5FZ)(x9p()81)O)(x)x8l(SF1)byyV(p7)9N9d(7bmz57rhwgmJGyraF9p4F7N9d)Rzva8v)Q)0V2R(L)DYtaHdhp0jlDEy8Xdh6T4j4nvt4up84K8wV1YtMNMgL8W7E3zEPZZgbXXS4UjElY8jE)XXottX)E8DHhSWln5Uaj)CNy8Cw7fC3hthCGNZp0xVVxcma2hrk7jUN5KWpfi01JX7HZ2hfXcxBcDFTXoT2is9q8dHzmERpy9a8s(ZI9DZ7(7oAVjtEaUqzNrHK(5v5CJ9VRiMp2xxi(oHi1kBsYb7xSLvUUafrOvUeFgFMuoUn(CkJYgFcUFj)aVgsRQ2ynES)wbAILrAIPALumXLRkHXNzKMONLDJprLM0CQM1g76stKVFB4eeJ3xmThu4jrDZWO9PZljhKd2S4ejU)293BZ8VfZvmBG0Xn6DqZQSEYpOW1qFUdEx6CNb7ry(n9v3sBq(c5)vC)O5KZEdMw5gsoRPCZUkedRRmXOuE0UbZayd5rZuA0i2V)W9YYxXUxwwfwyX91sjd61K2onbOkZ1MUzw1lb4vajTmJK1MBrng7wGKgsO3QGKsxVlC8C7v51TUAVE(LSIPns98TPTXuzoYwfeWQceWyc)0i6xliGqQtxDSLS64bskJVvLMMQsn9LxwTcCjn4gddU3D6A4Lrb4E3PQxvoMZEh0vYIzRNIbAtrDH1Us2(ktU9MwyFZGBG7iVpucpZbxB2Fk)KYBqL826oLEeqyaI6n(g3J(6387CxLTotAmm5()gw3rvvPHXGmb1EDQuw2sGn7VtBwdvCLOCni0xjtvhPvT)z(hitPWRmf0hPwCHL0MvN8fzIWBY(BFh5R4xC2(93lGK2LSc5RAKn5ck7FpKhHUprwvqG3wj5Gz3vcmkxoj5WyBjyGjUPz4GH1JWbmn6Bh5X5nY9N3laZlKn7At2lyAgEPpyVDU(LdALVeAx7j5HZiq7bO09T0VYtU8YBv6soH4sB5frsfyM6LsYM871cG0v8fUU8vIcJC(ThErS30Vdl0(54hUtWt9y8JcXmkWfiY4Sakceygtr)0Ppi7SasWBCe4FX)Q8WfTO5dFbWlFuml)Mmric4mHGxcTAHnQyh0HCUsNeHWzyeJdN99PFwSN708mmmjdILahBfC4JmEjSyES0TJImHkhFzFC7lUTv6uesOYnTIz4MFbLKVDmqAwYFANU3s5olPGdr6MkPclwY3skQB63sFAaNiLNLoLNdKwQOUeu4aKFxKXMfqlB)L9LBv(RhcY0GCdNhgFkTfX(gXJQ)w48jElYwG6MsbnHbIyyLE7Xt4jB5IWS4cTWaZcyrmmMa4tqvWUtNsrmk(O4kf7wjPtTVWj6QakFnXJ(DK)yxu3biTcbifxmKTEqVd(6fds(RcrXi6XKQExshZYtEkxneiaZS09UC9njSGwbQXf3g1U7CMJNpJUd6HOfTIgIcfFWALRblxhhYNYw3Qk1qobIhwA9IFh7nUguEGHpuIvsRJGxYgmuz7nrIb3BbyDd(h2tG9R4m6Dv1Px4nLr5kXgZ97aYYUbJDrV48g7LEW(d4Fk(5paw)XjP4cOBSJ3eB3ZiDUtMKa66pyFgERaBXeENT7VBUKXcxWdrNyWARq6acK2ndK(DgXtQmcQIpLchS)oSK(8TFkO7sKKgj9P5Q9zM1sin5Gw0Sysnh9Dqodf(y5YjFqWdHi8as6ceOKpaPKQ5jYjTmd)2ZGAibQuQRZePecHPyY39tatip)9v0Tw5MOQT3ITX8LG6oMbUQUgwTpA3E1pLYwqRGLOKO6b7JFr4anlfbPO4dJbKVJzJUVilINz4fo5ESHSq(a5e3vM7efDH8k47L5kzeg(bm)j2S)023ljLT0waK7zKr2nbMFVXc3bE(zUrNfzpEU74t7ClCMKHfpFlmwQVH7PathWh9cuF)cxMnyex99q3NPVWqHZMbREmBAXXWAjjVqwZdph(VUroGlnUO1AXnH17XtsUVd8JrHPm7PdFjtDeOcEj7deUZiMs8q8B3nXmduskDH43ZIZCW0(tmMHrG0aZVA89iiCo94JEXwh8Sd36GHd36G4qHphflxy256O6w2POlVSmlwpWwznAOU8s(3RhThzZ)zCe6cWw9Gjc8vUJY3IJhTZEnVhZdSrrMkolO8arhIL5ckPePriKKY33E8h(uHDaKpij9F2Yt(Wi0SkBFhxUOT2PuedOrtYxkhEwDN5hocTfrMB5H)WErh0plx0G1Hlpz5jh6KT4jucBxEI1dX69eCB0OFilbSpJXr8bUzGVBs(KcRuyjOr(3C8fJ9HGqPVgwjmsqxtI3GoeHCBmOBW1(mVzHXfoUWnkNyNe5e0rLk(iqvChvhP0rlMFESm2tFMnv8httvFNY2eAHvtn)gqgoHFyUy5dbprjF1s6y0zmtMm5w6yoHctwTMk3HysgcmeOzdHRFuvbgdBBpE4JFUovPWlvHVcjbor4VslnZOVoqu1RZwu25wD4A0NeMkt5SzjNixPExUzA(n3xkPkKuOVH1DuFMxaGhO8kZ67Jh)9Y8IDvQfIkl8BTdWd)hrXQuerbvvthE47seRZN75lagQ6JP9G5LliDIxhG9b)4wEYPbOswU9w(ALnSzoXJiFB5r8ZCnoHeA2WA7tzkD37L1UzubNtPWfk4(u(cMDWULFelYUeSqwfPqtZv5hLB69od6BzkE1EmYUmbEWdrRnix3rhQQ)bTQGQlO)3lFgJeSJmjGf(li4be1yWGiyWBIemKIuavvrwLkcgSWVknsPzD2thrAFuu2FWaGCGMIbZlLwRDQqrLyKEXy12gJEHMlRR)bHsxX0LxY94b5KKKi6PVg08w5LEa)7tb6igwg7Rni)JnO8hAqEzVOq1IaR8ez6zeVd4nd5QjWnfFUh69ibYNDO(eR(9AF1Sqxx8rf8wveIfWx2WiKaHHjqOjv5tmMo9Vm7lZe36yBdjng8f(QzhRwZysHaqkjWT((uI3sdTN45c(tyziqLoMg5G9m79Z2m7iKanQcKXn5rEa4MqUcG2JM6JkaF6HBkjAsRvmhL47I6dFYr6AJrLXdjxsqytor(u2sTj9JTXZcdbgsFJuFKHhaXqytp8kTHD5Lqyl2JcdYs6NE(5w27gnML6OVlaAWlxocy1R1kVFu1kVpyBg)7tOCLl)5if4HhI(JdBXEFk5TnqO)q6BKolX6OUyED)5F85e1h3NE(ds2GP9airOQex6FoHFKSWuQjYc9oBxYhG1tHBl1RyURneWZyyGyEOlSEjLawHkcuLODIx08WasZFzXJhuKAaNKe43sWiTMHHu1RgL4CtAYjw99y9bviRPpc5XUFBRBxk4Du3(rh(ekVRqavaVQEq8GJh4a)e9nagBIjzIC6JUNzDQAJPKsNcNnP9ZVK70CpM4NQzm2fMD9lSBzqxUE2N2P1ap6Iy3C3QzIVtShHYAmncGcyRogdfsSHis0XUg9dJZO9riV030bLopsIfLjV)KdrNpdsf6Sh7evIgi9sMyFi0VKeatXzIK1Usdbu3LZ6jLKqUaELqm3sF9dJ()UtxrvB2y7(d4EMseKJi39fAgrXgRxIjnlGPhdZoOq7hRQzcpo9sVn(JyplbV8eq7PZmhubOOrJylx0j139O(nWq1CKDLYHz1CxWs75xGO4UVCdsTYo4)pla(VvOpV1xPNmWIcWFmg0riNnylmj0H(S)Gm7coOxblBxDhi2DlMLvtRe0XVCH2ZYrKkDiwycvlIWd0YmYD2U)93R3vqaP43ue(61XiBjWT2eNoNZ1G3f7BvZZgi0HCW(D3zRgiJfdDVAh6DS6vsnTzBWRKh8xFwA7jiOcVGqGFRYUk1wJSQ2jK8b69FMqiW31jIfoplnfNGFhU9M(qEdaMhoeS5eaERUz()If2ooAwU2DfL5czpfL3ehssiq81j7kLHZKpPcAdF240D(FPs0ng1KGlFp(BA4ZBroZPtWypKBHWgkKm6N5KgUPuke2k0)OBVBqBXoUHXv13BMo7)4qmBQte1huXoMF4mSx0zPTzyPOcQ1(fi57fa))urRTP)YgB7g6OH0Nk)qXtacuNupqw)G9TuQL0cW05csrEWbcjDrk56TzE(31G8yFViKO3XueIRX0aCsTDWvPItp4LDBYymalJIA5coO3St9sMZnPiYEOiPJROOIWIbhkD0euQmHzf9qXJz8)8CEWJP3J(si(EsDpsDkmNf76gOugjjrkUzBDXSogCDS2fVHfRAWH4qb7vFktv3ZamDeSJGeB2Irf2oFAwmUPf7DAjcl3pXNYvGcYqOgurfeJPUXcRUdLvjFVX8Y)hkYSKCts7IfPqvv8MfFcYrbUYBQ6mDd2WyK1YjLuPCKDQmiUYMm0cp)GU7iMmLCcTXU3Xio0RSnrHEo8d4VCZLvsQoV8KdugMoY3X8IS1KyR2qITW(p0mrUQ1Nv)2U80jex3RWDAZkCNn2PQv4TmTJxzukvtr2FN(wTKMOt8UUjj7wJYsdROsQ5RIFNRAqonsQ6fy5zoMNO5qTKnFxgqLvqmDexVSikiLvHKwp9Gc6wvUW2Nx)wzNpKI6BVYPkdnaQOl1yEHBhoVZxy4CxSs7ojGNyHP5Nb8hTVskBQGzVx7wBwFHT2AXsRDlbMd2LYb)vuPDV2kaRlQT)GExFRnR6xBRTc7vy1vbZHPgP46BDtICg5RbxeQKCS(ARV60JRXf)U5veLAxYHiAMqQK5T)d4I3SzyQ5180nh6K7RO1KfUXo(yspctsGqNknaT2gMpXhw0f5dZWdAeLPiIkwaIK0nkvFsanIWWdcMLO4QDsrx2wQ7lmhpZJUNEBpGXyMV9r6ye7efDRR(y0xntPJQMOj6wEsxw)lHNWzo9VN2cuRoOLWEdX1DLk)jR3ScdKYvRi9EyfP6V8KpM(Rx(XF8qlrpbI)VaE1kLA4akZMqqCxWdmlkex9Wu2xBrwzjnx1a5LYbKuz0yHp(UtXgUatGcj5WBbjkwFwL)O2Ma(x8wGnKTJj3rWf5UL6XSXSJwk5lIZ54YmVtMEXa91yD(J0TkdGQwSyWl3IwcIO2aRAtwd7PQlrQHh7OBMCAgOrk2LLSsk1AvuTBb8bntrUJtDNSXUSk2I1rsul1pi0JolTDFwMpEqtYG)9lcX(dBygezVoVED2xn7lLaS2XauRCvYA0sGBDAwqWffhwGzHHtWMRHAiyop6WN0YnolLYAPtxRnu8gxS1UqEhI0(WzoXywflAsZ3f5zPcJJ3dcNYQK3Msnv5u)SrJqv4VpLeaUs7nPNE7juPg8Xk1EUdk9cUw75RKis1c9Mxcr2Mnq1ElDfU8YbIm4A5zpxjPupw1Rdnk5muO3GwsJ28zuGbc3GtPJkC9VNyusLexPvAODqPFbelM0N1bOv6sI(YSWm89U8s1oCy)D2gr3ABxuJ4VbruUIHs9JQqdr1onOXuUw7yFzLCxMovNLXnUNXgr5llBtGS1hpNoGlKnhsGgnrXmaJcJ4zxjXfLep5LeyWZ0i2PeXS2SyHB45662QlfpYvnG9ZjNthfCAnl9lTkQScgHgty2(wfPHuTVxQvViLrrqdeDTlGhLH8CnY61y2L3a3oExYlfQKmO(XhYy8Fyj5HAYY4Bq6tTR7dfPbhZmoRvMoKTQOtS0NerQTXQgPT40ZfSbxjRkqhtENL7e2wv56wV7WRtt5CQ)wyRbVAOVs6MFJI(m2Ta6GzqnR3ipWAAu2ct24RSZMneaBrRdqMDX(hazw5MClfqtfTeJPQ1A4egjLbBLwOPUox5Tm0Lhmp7ptpWS6QiMwLWOcrX14(O9hWM)Akh0QvgQMGw19oIXcyX28Xlgg0tlxmqcWkiQTfI((uDfiIMzqOyxuNLsB9cSOO3f6Jz)KkpxEmneh)yim)yL2id7rP)FL3vZUTnmm4NLEjigBy12T9wspmGUDCh6o3a3fV5a0My4KT1nuSN9jkAkjlrXQ05MnKHEZ2YH08hrXF(QThLWnl(Zequjl3Rp0X)CXwvmtCPn6gX8kQItk9DDjNq32kx0eQEP8ftJ6oSNhmyu1q9s9ySrVGArNLNjMTR9Rfox8)9xZ61B4P7gwRnWx(7vhpXTkBXDA7wgF9fck1EKkZBC8Y(B57HnuP9ep9AI2JtZyLCDXMUGFk3jQMMWj1Ja77TAx999ZJ0aC)jI))H9w4SciwouKAxDxD7MoB3WDXJpoLlmWYCUCk7DaDV1CEoBV7Bsq055zjWPkNZDv3bGlsvlS1)6gLuehx8qwMVhKePcmjvF0bZVO8yO3esddxqHzPzEEzpsI9AkdpqBQH5guPcOlHly4caDhCnFOUdcpLgBnCo)W1cPd78HDm2vy2dHfaSStRZzAJMLB(QoBnWxIF5Gzz70TlUoXARmPUS6Z6KVD91N(U36M(h84TyNIRiVp0zOAlQBilOamaKMgVyPLBkhS0ap32uAr1Wzn0bMtmpvVqLkHS3E46oUr4n6nG(zcy)sHYm5zr1zCtWmSfNHzaOZGEbU4oLptYaUtUKhZh7EaVkJb6yiyvZfPTyr(Nl9l(L95Twz2JHMpj6uoDj4sHPLAPUIYZUwGzLyO01BltxVTyu0Bd)NN6lVEB5lLEBre92qMusuwYCZcj92Ya92iOIvu9wguM8aP3wkXqjO3cmYc1MHlhKYuxKmtYNlhcEM2hNYCLYqkqAwGNhPVgG2uudnoSxnnpqri2IOeBrQe7ZYmACmWhvJ4SdGQ(zI(Vf8ikA)ifbGPKxB0tFLosiichDk77xNfRw11ScyjQZB0XfPNstCzM3pgEeC2T11RW7)0VTB3qdaH99iAFpSmNbrxTpGchTrOJuocM0brnKMtHaChv0JXCidYUvgo)nftoPTR(Ba)Pe6o5Xz)vgfDfjqYtMkDsOzx4vVc1rJol)vXOTSN4GmXLNL8YZsbq(lz5zP82W27jipzrK6dT8SWxEYqYhu55XGfjhHzG03XrU9pND4XGLhhHnYYT)k2B4FK0ZcFtZpT(HwaSb5UPs42PIL57MShcc1M6Q7ubd1(PDZM30U4lv9vcz4tI4jO(gBUD7QLRQw7MSF8o)SUT5h9qp40oy45xGDTwFVWHPmEX9ExgAbTbxWDPQ34wU1sx3Uy8kzryCpQ()iohPTJrg(MDQ)U53)]] )
