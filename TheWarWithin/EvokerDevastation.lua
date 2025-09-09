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
local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
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

local enkindleExpirations = {}

local fbEmpowerment, fbTriggerTime = 0, 0
FireBreaths = {}

spec:RegisterCombatLogEvent( function( _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, empoweredRank )
    if sourceGUID == state.GUID then
        if subtype == "SPELL_EMPOWER_END" and ( spellID == 357208 or spellID == 382266 ) then
            fbEmpowerment = empoweredRank
            fbTriggerTime = GetTime()
        end

        if subtype == "SPELL_DAMAGE" and spellID == 357209 and GetTime() - fbTriggerTime > 1 then
            -- We got a Fire Breath w/o empowering (i.e., Tip the Scales); assume maximum rank.
            fbEmpowerment = state.max_empower
        end

        if spellName == "Fire Breath" then
            FireBreaths[ #FireBreaths + 1 ] = {
                GetTime(), subtype, spellID, spellName, empoweredRank
            }
            local fbAura = { FindUnitDebuffByID( "target", class.auras.fire_breath_damage.id ) }
            if #fbAura > 0 then FireBreaths[ #FireBreaths + 1 ] = fbAura end
        end

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

        if state.talent.enkindle.enabled and spellID == class.auras.living_flame.id and ( subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_REFRESH" or subtype == "SPELL_AURA_APPLIED_DOSE" ) then
            enkindleExpirations[ destGUID ] = GetTime() + 8
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
        max_stack = 1,
        copy = { "enkindle_damage", "enkindle_dot" }
    },
    enkindle_heal = {
        id = 445740,
        duration = 8,
        tick_time = 2,
        max_stack = 1,
        copy = "enkindle_hot"
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
        copy = { "fire_breath_damage", "fire_breath_dot" },
        meta = {
            rank = function( t )
                local duration = t.duration
                if t.expires < query_time or duration == 0 then return 0 end
                return max( 1, 4 - ( floor( duration / 7.8 ) ) )
            end
        }
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

    for guid, expiration in pairs( enkindleExpirations ) do
        if expiration <= now then enkindleExpirations[ guid ] = nil
        else
            print( guid, expiration, expiration - now )
            if guid == target.unit then
                applyDebuff( "target", "enkindle", nil, expiration - now )
                debuff.enkindle.duration = 8
            else
                active_dot.enkindle = active_dot.enkindle + 1
                active_dot.enkindle_damage = active_dot.enkindle_damage + 1
                active_dot.enkindle_dot = active_dot.enkindle_dot + 1
            end
        end
    end

    dot.fire_breath_damage.rank = dot.fire_breath_damage.ticking and fbEmpowerment or 0

    if Hekili.ActiveDebug and active_dot.enkindle > 0 then
        Hekili:Debug( "Enkindles: %d; Target Enkindle: %.2f", active_dot.enkindle, debuff.enkindle.remains )
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
        --toggle_terrain = "none",
        --terrain = true,
        startsCombat = true,
        texture = 4622450,
        toggle = "cooldowns",
        notalent = "breath_of_eons",

        min_range = 20,
        max_range = 50,

        damage = function () return 2.30 * stat.spell_power end,

        usable = function() return settings.use_deep_breath and not moving, "settings.use_deep_breath is disabled" end,

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
            debuff.fire_breath.rank = empowerment_level

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

spec:RegisterSetting( "simplify_engulf", true, {
    name = strformat( "简化 %s", Hekili:GetSpellLinkWithTexture( spec.abilities.engulf.id ) ),
    type = "toggle",
    desc = strformat( "如果勾选，使用 %s 的条件将会放宽，从而导致更多的 %s 施放。", Hekili:GetSpellLinkWithTexture( spec.abilities.engulf.id ),
        spec.abilities.engulf.name ),
    width = "full"
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

spec:RegisterPack( "湮灭Simc", 20250903, [[Hekili:T3xBpYXXXb)BHFqhVtK3YB37okkbD0GKhzSeKLj4YyHGaFZo7m9E7yo7mJNxUJNaXc5eehzfBK3SHbsmsIcGnemKCmsasKLLI)XeYZ85t6VWtvv3Zm90t3Zm7E7rkzRpiQB3PNQRU669Q6EpO)b3)GHU2PSdEZbBny3TE5T2Tx)xE3R1)GHPNeXoyyKTZdSpe(Ja7zW)E6V5x97)EF0qVzo4JoXp02fHqsywSd84PPPrjVYvUYHEPtZg3ZjC2vs8ML5BN6fg4eBpjf)SZvg7ho(kPtzhBhFmmuVGRCdhCi3n2lm2l9K3Wljn5kUSj2z(PxHDu4dyXwUSJStsjq1lHWGXzE(PVwWbJ1Ug26LaelI5CWB2FNRc)9upxxgFWSe4T3CZ5JU)u28rVLDm8peEmF0qMDsi8)3E(RJqBZTE5n3A7xz(O749W5JaAs48r4Ws9IG)bF7ehBFwY8roHbUEiYLK)MxBZT7dV5nC)ozjPieIHHFZyMD605JyZIcpMfpJfapYLLYicq5Ro4AWRo8KaN5Jqse83EZUv5J7Vlbzx67J89MCY8r3o4Wm)jagXst9coSCWBDvyWVwaGD2(WBD334GH(ifg36y4)(MeFalWESpZ9GBEWqBcBGVkLfdV3jwjzXixGaRTsdpyiWJ4CIJpZk1gEgaT3e)gy7Jf7zZbXrmlwaBMhsFE19MpQ)8rxciBabliTxoStSsISd6jM95JE0JMpA95JoYgad8n9CSdSypmLf4A5cBuRvaa7aVzHjaeQ(UINoZojXY1lXliLDymWEuoQniOOIGxNM2TLrXjHbPwHtSMzFONt57ddyN5JEXwxjBWrOXztM0Zn2(WWa4Fy9IzZS9cqscqr69s7sGc4u99TMcC4mc7m(sxNth18kMjlRzICYLfI9I4B33wSqaUkC)(YZhLLaWo2o4bZhbafyvTJaUnhesWegItkT537Guq8Bj4IgS4CrdODGbDzhOnY)GEld1xZEgU83Ejw(BV4lFoh62DD5FH24MxRlImntirSQ3GLGuQH(JuYDwck5ontj72suh9ENUkWdyEkyMHz7No1cM3znQALpUK0WaMmEY)6EroPedQm0SsNgZsMg67Y1FBXTjxzcBqk0l4iVddH1myBWcFj8)hfYF4Qebmjhy7FiOe68CQbY)mWk3HKtcfe)cUNhgLfqSnf4MgYLb0byeMgzDODujtDmWMCmUsg7B)2SEUHhhu(WWXjEUEGUwU)bkp9TzrtpjU8lxNuYEiZIliqsO5wZqUzRzAEKByA9VugmWCKycoYpReq5F7gLuTQRsD7VFffRkftzHOtHw3jz)bdvHJQCH0KuDAg1OSoGLDel2ESNVQ)mGtUwJddYs6LE8XBBTtKt5u5YyrwJjhTr1EaqJZIsT8MCWWdDCZTaT3wRL658GKRV31wRQE)963KE0sBzkEpDR9NpcdD4w7lVwM4D40uRkw92ElHb1WKgvyQAUReO1x9AT1MXzKCcb9MalcqaXie6njd2IIzotX9sRuVzmsFlsBMz)qYq32vFXjqSlckAf)NQ8kQHh0iFVHvGkQwXhd2dzozP5y8ls(aMVQzjjSahajZIts7bXj68acdxNg1MLEhhdoaZSitHQre0g5tpvqlIvUj67DeQXBIpAWcij7AKKaEQffZoYcjQ9feacbQ(ajSGEASTNRf7isGj8iggrzpmevyXF18xNwztHNgNVOKee4mLBHUIjf)uIVxuskmnZQi3P79oyieMa4z5eedj)UkCYbNsfXK74J63qZaeZ)vnspGToncp7SBPWt(g36YU5kTb2O7RiHO41BLtVKXSIqz5yWPWauSDpHufAIkL6fb(3WYTxuLCLW8NG0PxYGsIKP2Pibd4XaUEvI9(Hy(fWDbhovhzA(weZVcP(cAfKSbv92p0IKNsudOqVSKepKqiwrmBDfT3dSge5Oc7eNWyNP4QInBmloXuqnQtHWoK8oGLR9mCdh12J5fbXbddHhPlWLHlAH2SImsWP45ZywcoJwKK2xRzgiiE7iMtAzQd2qei5UiBbS3End7TsWsx0nQH)iVD2kzCnJKW1AAPcOTBwm5GnTAi1g891kPya51liGRvq)aJSiPxHPLs(YwkYqkJPQg364WLi1DBkztsHHsbCv4y6KfY9mSlNJl12MrilObW0wvX9gQPErOU3gexV3ofj9J2(OKR8YDHhrnZkfCenU3CbJM(0J9kO(9adStYccaLC5RUdddDX0AsjWfEAimrdVfTo6VvxwiDbZntE14jsFJP4Ki8klP)8Vo7bGpNF75J(gHUEt8W9umBxEhgeIzX9EzJXeUsIuW3oHNxStiTlEWc2lbPb0hXx7yE2qO8fxnnWOWGIKRjvtfgbbafBFeZxWxwOufFrzVnA9nBqxPSPpHYazqdBgqm4COCjfOEjjFjkf)IbkwnDqvqDwaOD21Vf8vwZVy81bx5G8I9Wnw0IMgVbKEkiT7w1LGUAlAHnLW9CzTAE38QIqdkPkmclv0Czj(6gjtgCXxSvQQlusbVShGgx2KrR(gt3BZsuIcwqYufLSiZzkkFGA)ojmdjQbxmTqWHVmsWp7rL2GRrjIfpHHbopd0Y4bafrsLGmWHNG1lIksILKx11Y1xEupNfzWZnMM24vkutgWEyQvPMCUNg8TgRCZxumk97nqvKsNRZ89AtHOwj6MQ743mloimd2DEJ7i2VU9n56k3)EyitrKIWKWQ5a0GHOMsI)6A9CTWTvYPaZXiUbrmkCAiFUgZXEy(P1VPmsB)2zWMieNK3dux)3y4xAw20sunWuz7YjPHXZuwFddaBEGvW7aRZXEGmzu2SOARPeyuieOveYTPk2rLbGqa1ibnLgeJo5ur(JpMKJz((A08l)udowwv0yHlN4E5PNqYIvQ(Y00GVZk083AkqWpomZ3TqpjQ2eD3a9Za(QymEXEZhDFAkXkRydRLyu7bOvHfEm3jmtrt2wbF)IbTUJulQiMWoJVpecmiaMV4GVkaGfHraBlxj76JrDvbHPCH1xHBP4v4Q)udqRY08NMK7B3(mwecRBwZl2YiY8MnZla(dWmoO2ilpqljIwovG5NAzhpZqS1gto6g5CD6srAxYgALrnBgZ1dBUcA73g0J434RQlhSif0u4lnya5ny2rLg7fAXqEkqnwsEes3)TERT56GGLBnTp(CqWbFsfTQA1kUhfgA(q8ccagxUdVIxDDnps2RGQzcuWw3KY9s7m57CA22WSrBkSjz5eTjjWo2)elWdkVaAJJ2Qeos8Q71FnclQjXjY4dA(RkxSPSnEDsDxHmFzUgLsTAdZIC(iAq8NZyxi(hb(ZybChwEUk8oFdB0h79lbc5Vy4reP0uOGrNeRYdoK5eZavcPm0b11DP0PbCvpydn1ROWwNAQuQzVtE5Eui2FuKmm39VYrurjl3vdq(JfBQNxMWyUuMef87vDIBGXkA0cluvLgAenGxc5VQBIyj5w62ESHDxvxvR8o)j4M5ncC8iJJ3bXFU(EYA6uWL(8Gsinp3eRtPWCbyAykpaFKCakV5FibFTOiwa8XssQdy0Xs41nwVAnCl2CSqqevyXjYs1riesYFOHOcRkkL4as)G(eBx7irRZPBIQRB6cAupT28Qzm0ROqU5uB5sZFymJfqBiM8DUjv)3PMQCzmrKqwtQ4l4RQta58xnWwkRaNWEtUf3ON)h0qp8CDnEgQQ5GMzv)HRrH0siX3u17UQLPm(edRcQ2SIK2PRaTDH5UstBOJVORTRsE7HuvKN5BFckQNYBdZH3xs61gdSYEmfZj6n8WHumqyFR5dVumO58i7G80rgcISOVAhpLHVhbHJPhV)928635MBE9Hd386XHCXgJU(UuvB6cnKM7Cg4Mt(tJrtnpVZdr(CU5xtPCA(OT3vxjOdJOSNuUDKRpg)l)m0mr(cqB4PFnADUEhQBgSdDnEfr(ADOsCfJwn)5Flb(LNfjgIMG9SeAhgyvW8IauvPeJGQUhtXtfZRleNZbDKhIj2Bw2m45S0Jz4RtFT8B74kSlGbDvKi6KllssmbWBrH8pHNKk0IXmeJ6rutH4Gs6A0v08g3lYHtfZK1S10uqhLI8d3sZUBPF8vY(WlrStcNOHrnXZbt8TO7uxZu9elDJwshSTRBcx)BrQQQmVvsB1w92P1WKwR9OKmj8STWzjv1(DAtqP3A1yYxP1Cvts6TD9O6hHSLdpj2BY3My5lEpo0t8WyMb)sbtIjcwZGmmlJI4CZhucphPHXZqGsQ94jlOKHlVhFPQweKKYSD5aHGQt4SiF2dPMgxUf3l4tm4(W6gW5xLx(tD19)mQXb37K7gLc)hDJTIIbEjYGE1UTGZFwwbPQo5OVpQnQ2xLpqoTeAkFF1kOb(wZTznZ(b5jtafqaNBCXDv0dtjR2F3mMVVUchxz5D3JyrhfbH(XWqB5IKiqX(Vk2ZjTspiu3MUKnBPMQmVsK5VxwaLhCzSOwr(glpnzic(2so(vIZcBBq4iytKHVRvuOxcOnqXOO8iCWuE10aG)MztdPEDahlp9GRGEI2dqkQeKJZyTmUhdKqa3hDZlqOVhgbh1y8HhEiW(ve7urglgon8y8CMezJXBHEMuWbLtL4Tntt1yPXTly3n4byWB6YCFdoMs9TKgEJ4SaJZLDitBcYnpnVk1Qyl40KKY9oLhvHgFtRgLxmzZEiYdKqk4eBpWKE4HOav1qaLY)5mWwHVlexd4Xu4SchulukXIDbNeXA6eBJh5jz2(uo5OXwB8clxtE1M5S1AZE4fm4zvz8EM8ulx0QTCmOgEOUN0CYpL8AOsVQ1QZiBVyDG2n(M3o3pduIfClz(ikjUFDCWcdL1YGeR5d5IXYKaXzGgFZFmUnh6aG(gdVXDRfLRu5s05wE(KvRPVuJorJRxkTYLKHUwBJRuJ1TOMW9Ecl81tJKgpBZxovAy3Qfr0oB2TMI9Im4xjEI4iI5(3e9mFc1kgOl2yiGykGP)7(3H8z6sBV1d4bjU7914k2FiljPZ)1kmiFvBvw0wLMk64Y26DfjERH(UB9w6vonBpvlv2kRPYmvgWfy1392mtpJ3YTYARNZ6PZ74c1nXg6G)CDjZchtURHLh03dZjC)DHVGh)eLUikxtbGhf24zWLcJvmGOm8T4FtLMrrZAVVKqxHN1Aq48oQPPd4whAzL1vBSt1(2IFMkRogVaq)eV8X1fRnfjMA)uwPDn11BsT3hkf6AQkwxZhbvvYM0rHF)zTnpv5kLdmytWzopYXtLo(JIqbdFhPxuahjHZL79PdXAumgSsVzA4MJP6sYfKbIlejJh4yu9yS0WTya1(Q(V6rF5R)RmhqXsBKUILvTcYgYIIfeKJkMRjzjY7j08)Daw5OWYk4O2Icd4Nci5C71qJG0uSW8GlPQv(fxYtL4B5htWAH7xpDv1Z1w9CWsbePZ36MZhabFUOogaSDzBrq2Qg0nT)vtd3oDJfVSQpyj41LpHILtl1Qwz5SsA5G1nwrAj2hJZufDgnpub5(f56aREeh6RTShuyR1dvL7gZTUjwCJGuutU4iar0wtL00Cyy00GD3uPDmeXgCFm9XbGz4eYtOcNMCcrTY5HO5LEr8lhJj1K71U9H2yKzOreer57ci1(12VNgVP7CAdul2aTCn5IpVDpAIfAD91iyhkaZIwbshYjIcssxw9Mdr6Hs9aIUh3y0ecmuVfTsZpYlcQmkV0UD2JULqMU6iQQvrXeHrzRQMpAuuUqm0uBDnOdJPVS(uoLBDYPKn74wT6RUBhE1xmVGTQI239eu2zN7FjciBJ)FXX3RGzHEcQyopPoHcPE4RVlqj5FG8vB)7rYcMc4RAVy0Imr5(AEtzu3AQA7A0sMauQEZUsqsTl8kEGMMBPtD)b9q9DgOXKN1GT2(lZcC7smX0jxwZdLAUBvULBzNiA1EotIFrZtslqqnDeQR9veT4AKVn)0kj2NUCXFXRlooAr4U5Lohxx5XAJdbBHDEGi1QcvrZGvbf)ZcXYs4kaQBfZv(H0npWK4WzyxDOJfSAxOXVuW6H5yWX3lcxRRv3bP8gtDWARRVNFU(Gh9OkjCgORQDmP0uj9iCcxgO7C(1FC5SWgskB7UQqZGbFTWn6U1eVD4A4rBNsQO3Ofg8c2vSUot8sMku0LdArE2Pu2VLCjCKsuF5sjTH2cTH(utB7eANGX877JHoYHrspiMGlT3vuJu5YOZ)7r106YEt2Riybj9wRDbT6YeFDfM9UsNVGs6LR3hFPn0SOn03B3bwE88vmHw(AlcqQu9jBOhZsIozgM8H4eRJzJveBmfVwZUKWfo6QlLnB1U6S1kWkhABD1V(AoikRT0tfkd2WqMvXRwUIRzesUYpm01pljv1qOeHgIGnmUAqFcdXAMa0Nk1JSD(5fVsSvAQHHgyTZwvtJNPmlIJBJ8RJsfMKgQoxadIMY3k5eqGa1JhmfpkdX1IxCHzQApnbasVBocBcnAOuFcHfqlAIFyQ8NBg1xlVd8kSuiEtRbw44tYzm7AXS01OI4UmhQ9shu0NwLl(nK4a1N321BFsuoZp5lJiXLfAUR7c(0Z4ksGX6c7BBL8mwUWNANiLBpsCUjQcoGoTC0S1XEOJFMltNNa5dQV1m7Gm8Q(ScM0VhAqeSKCILBuIuk5X1MIePYlwYGx8sOm7v3kNC0q2plvt0ssGuDaxJOyReT2jkkMSOlawXyY9SGCpDkqqyjsTTPlcu)mSH5454atNbVZsa2m6QXelnDKnWZ5MdQ9lxdZhDFHzpr1J4Vlsl3PAaC3M3dk4lGAhKsXsHx7UHzJXEDfjuf4)LjuhtRsat4fpnf2tsrxrgo8k35McSuYTE(nwfGEFZ4cS(E8cNFJWB3uv7ft7GLxtu)Zhnr9FEQjAWZrnr9BstKoQs7cvdmmO(Drt0a9AIgSSAIg8Lenrd6crrXG(aDDTrUOgsmSaFfC1wS9JHy9HikkLL6GH)17GnQ2P7d2QGpv)svmHTzmRDsQmlFJ6rwVdS8TBARLfw)gxy9x2f2zuJXzxbhrC072(gpZ0RvFF(5PS82Dzq9B3au7azqh8NoxPrPcHg6HjbO0e6GAltvPoJTzMUbhov2341GWYejZKogtkH8s6vnIVUOMAp6iDxWhu9(luuyn(6sQ9BLQe2QLFStAkBEjZXLMJD)vlsHUUUoctmWLAA5OPAeV2e0vrSB1jVlrklDUre4kLTTJWBtjqYMJD5NSeYxZqSVP4VwXEe3LtS(Fbmp(ZBhAJdZl(ybCAQr2kmUQASDbfbg0IiWGLreyqh9qtAaTjcO1G2xoeb6Rveq7s(zLiqd9qyPU0)4r3PE8pe4xSCOSZ)SGn5lIAkvmV2qNCwQ)5pE03Oh)FgZ28fqTl1J)d(eOb2jC2yBTha)2pJKsRmmvaOroEoIuw2ppEiqQN5fhhgJ)iKmjgwdzX4jGiCwi8ThRFVX7Wag9RwcgpdXnFI8jTuz7vxjawaI2GMwapFE4cs0gSieTbLeTf)8)Z(UzErrm3EJPRcfKxorEsKtkHUSikMbSa76MdfWKCsGJSottZoGAwm)e4fP7LCbU2xxUvwULiV9u6VdVv57VRIBYFJtsNInYa5K8u7yxNq6SHI)wJfoF0(4DilEKQ5)UFLeoJvCPYaF0Bg8Qy9S5)IHrnco5(mHq90rxsTtT4ORMabLOXAsBunvJMZEsPU9xqF5Uuv(JmLnpUxOTzQeqvvjmnK76oy8i2nPEKk7ZC8WuVCmSrmDEzifiDfZoF9CZFzYX3jyaiW26mVGmSLuOeL3V8ZcaLOx9dNb1aRKjws1Ow6OmrP8RQyrJ(ryiLFNZ7Tn4yzDnxA2BBKaQ6DE7Y0v5LgZ8b1OW)KWZxwwa2Ig598F1XgCYSmgOPoGo4bukTIOlG429Pq9yzLFtGqr3MZxjKYNtx(d4fVaG60fin)IyipN(f3ndI37YyRuHXk7YFtEZvvqPlgo36INuS1qa4FDBooGT5dSUPZYb)cVgibR7Kb0Ma6YZPFVDF4gCzOdPdeLTOez4XaPWht6kYUeu5RSEIFOf1oljt5xNLy50COt6PlVfAKgD5m4f4eJNM)eE7P5YeFeMIBaFh)gDuSOkNJj5nASTK(aEv8cJZ)lQV4sK(fxmNMx9cBPuKxKgFnE7VaSHdwa2WblcBOMiI0RdPCzu7ef1(6yl9KMcN7pq3Hxzjb7afWEgC0JKrPRK8JNY8JSsMsmo1LJbJijr8eydSE2Xby3Y55iGET1TiV)hO7GwSaO3GoGEdwy0Bqf0Bj9hlhy5IKTfiRSZfMToHRS2SDv18LHkiUr(PNqd04Y28ryas0JVETPZyRtyE66RF66RoDvnW1VGxGFLiBWN1ZZnPwZ5sXtR5cA1lEhjp3LOPpZ2flVcYEwSnwBNSgKk3le7WBFGUdNYcOLWyaYY)(OwrDH(ad1evLEOQteUATYAKju35pOJm0gYQ1kJVUAD388pYNNjhzAn8LnlSU4oJ2V3w1(5pv5CUthi1(fhmEXybNtOmNXVuRkPtX9Tk(L54aDDSnItXSwViZQEPzvC)WDvfSR8s3J8WIFr7HobIf7fqp83RtYh28BhpXaZIa)BPhi1Qr9OOKVdDcaMHotMFfRUtcZbpQOSzj4XXV4cYk5yg4Czui)WlKsNZm0lAgYRcGNCq0d96fpG1tWFMH2eVJxe4eHjZOdOw6u8ss)Q4KG3XzjC)KhZoKsPhUGgZ4hPnB8OkKiUjy05U0csCXdlQebENd01i6DeU1(LDU4w9tx)C35l0oL7xDbqvl8H5d6A3YzlLU1k3fBLsje(RZDQoquSDCyrP43ko75w4(N0cHudx9oQDSUoP34nPRUJeWqIzzi)DWFO2ZFP5JUlS1N57lH1kxPuP5x6S5dym28FOlEc1XJJddEBMmXivZTfB9vG(Fq)icF5vDg9DLrSlDHlH7i5OuXfuw1RA2Hs3(kshZIAOsXZuBo)s(eD)UUv(u9)Acri01u2jZXhLZOIgExnyf5XTX2y3mYCG46kdOs4fFiQRyWUB9YBbgipg8s3d)TpC4t)OFXt(7FVp)t)NEY)XN(K)QF(fls9)fFY7(tF67)b))(zVZt)fFVh)XVZJ)K)5N(x)lFY79bp(39Ro9h)B()EN)I5V(V)d)W(p99)HWB)0p7dp9h9VFXCtv8KWt7QfrqFXh)XFYfLSLPzeF(N(U9p9dF)p)t)bRgWNNq7LbW8qwpXiwN)8vlOplymUplotMgXA5XS6NIZc2toEyeV5pDvc2ZcUIcUgrv6HRqGUeiAB1RrDAAD8l0uRZVDnZO2HvFIgODIg0QgaTJyvd(g2BAfWA1cO55RwqFwWyJs)ggZQFkolyVgnb1E6QeSNfCTUUa1hUcb6sGOTQWqzAAD8l0u3UcgZdR(eDvdAYQvXivDy1hW5kWbaFoa1N3OCT6TPXsHYaAbLFL5JUvyaOiHoUuHrmoYKWJX)IMYpZAR30s5fEHMk24EB9Oh10ZFHxOjyJVDtl4nUip8)Lf1pty(zdX7rBpVKbr5w4O0nG679RqGlXUUcH6ZBuUfjmDdOfuErLWguJnvZszLjHPb2vyu1SGnlH1nu)mH5NneNlHDnZAxnvwxn6zno068dnmHgRnSMz08yxOPSAfM1fRr1buh4VSzHNUraBEOl0e2rcylJDHMYMiG6gGM4b17VM2ACRzdQ2qwSzWyjO1mvMhRM5CBZ0SMxv6hYIndDCv1Yy1mN7yyo1wzs1jt)GwYzPjG3DyAOMQQB(NrmVFdyE)wX8D7a14StZ7YSSO0C9WCvtZ7YSSO08gc6O9yixKKuzyMohIwTVr388pQUki876mm6Rbg91cJh)B)5p(J)Bo9N8UN(V8ZEY)Z)5t(zFWPV3780)YpJxYGh)XF0J)SF3V)h)bF(N(dF8N99p9N(VD6)1pbhZF7)WJ)T)3N(t(1N(J(vp5t(hHHD6p4)9jV7VgWK5VovwumdfWF(6QfLqGojDSMeMuPw4EL4Gsy0968NxN0TYaTKJ7MGjMBM83tfEvE25iAEoc6wPaRynmMMKwI6QBjnzfcCj6Ij7qntR1886i8kd0DaDnZi3Vng5vgAEoc6wPaRyJ8MMKw416wUjwHaxIUyYTKfwPrDeELb6fbD7oryjq4Ud8wr5LGBURi8sa6fbD7U(YLaH7oWxeuURKHLaH7kOBfDxc5IUIUlbOpTT6dSeWSo6UYaDhq3vsUuAfH7UgIZvG)SIEykCLfw84Ce0N2wI4xrjQSveU762oxb(Zk6H(ScVec3NJGwIwycMRe5Kwr4UlAFUc8Nv0d9j8EjeUphbTeTWemxjYjTIWDx0(Cf4ptOhZF9tF3)UN8E)R80l94p57FTh)X)s5uyrJcVhmcN4HTY9bdTZsNggFWWHEZUf1wTh8)p]] )