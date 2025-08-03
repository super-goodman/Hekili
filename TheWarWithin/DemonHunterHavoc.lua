-- DemonHunterHavoc.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "DEMONHUNTER" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local PTR = ns.PTR
local spec = Hekili:NewSpecialization( 577 )

---- Local function declarations for increased performance
-- Strings
local strformat = string.format
-- Tables
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe
-- Math
local abs, ceil, floor, max, sqrt = math.abs, math.ceil, math.floor, math.max, math.sqrt

-- Common WoW APIs, comment out unneeded per-spec
local GetSpellCastCount = C_Spell.GetSpellCastCount
-- local GetSpellInfo = C_Spell.GetSpellInfo
-- local GetSpellInfo = ns.GetUnpackedSpellInfo
-- local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
-- local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
-- local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)

spec:RegisterResource( Enum.PowerType.Fury, {
    mainhand_fury = {
        talent = "demon_blades",
        swing = "mainhand",

        last = function ()
            local swing = state.swings.mainhand
            local t = state.query_time

            return swing + floor( ( t - swing ) / state.swings.mainhand_speed ) * state.swings.mainhand_speed
        end,

        interval = "mainhand_speed",

        stop = function () return state.time == 0 or state.swings.mainhand == 0 end,
        value = function () return state.talent.demonsurge.enabled and state.buff.metamorphosis.up and 10 or 7 end,
    },

    offhand_fury = {
        talent = "demon_blades",
        swing = "offhand",

        last = function ()
            local swing = state.swings.offhand
            local t = state.query_time

            return swing + floor( ( t - swing ) / state.swings.offhand_speed ) * state.swings.offhand_speed
        end,

        interval = "offhand_speed",

        stop = function () return state.time == 0 or state.swings.offhand == 0 end,
        value = function () return state.talent.demonsurge.enabled and state.buff.metamorphosis.up and 10 or 7 end,
    },

    -- Immolation Aura now grants 20 up front, then 4 per second with burning hatred talent.
    immolation_aura = {
        talent  = "burning_hatred",
        aura    = "immolation_aura",

        last = function ()
            local app = state.buff.immolation_aura.applied
            local t = state.query_time

            return app + floor( t - app )
        end,

        interval = 1,
        value = 4
    },

    student_of_suffering = {
        talent  = "student_of_suffering",
        aura    = "student_of_suffering",

        last = function ()
            local app = state.buff.student_of_suffering.applied
            local t = state.query_time

            return app + floor( t - app )
        end,

        interval = function () return spec.auras.student_of_suffering.tick_time end,
        value = 5
    },

    tactical_retreat = {
        talent  = "tactical_retreat",
        aura    = "tactical_retreat",

        last = function ()
            local app = state.buff.tactical_retreat.applied
            local t = state.query_time

            return app + floor( t - app )
        end,

        interval = function() return class.auras.tactical_retreat.tick_time end,
        value = 8
    },

    eye_beam = {
        talent = "blind_fury",
        aura   = "eye_beam",

        last = function ()
            local app = state.buff.eye_beam.applied
            local t = state.query_time

            return app + floor( ( t - app ) / state.haste ) * state.haste
        end,

        interval = function() return state.haste end,
        value = function() return 20 * state.talent.blind_fury.rank end
    },
} )

-- Talents
spec:RegisterTalents( {
    -- DemonHunter
    aldrachi_design          = {  90999, 391409, 1 }, -- Increases your chance to parry by 3%.
    aura_of_pain             = {  90933, 207347, 1 }, -- Increases the critical strike chance of Immolation Aura by 6%.
    blazing_path             = {  91008, 320416, 1 }, -- Fel Rush gains an additional charge.
    bouncing_glaives         = {  90931, 320386, 1 }, -- Throw Glaive ricochets to 1 additional target.
    champion_of_the_glaive   = {  90994, 429211, 1 }, -- Throw Glaive has 2 charges and 10 yard increased range.
    chaos_fragments          = {  95154, 320412, 1 }, -- Each enemy stunned by Chaos Nova has a 30% chance to generate a Lesser Soul Fragment.
    chaos_nova               = {  90993, 179057, 1 }, -- Unleash an eruption of fel energy, dealing 7,335 Chaos damage and stunning all nearby enemies for 2 sec.
    charred_warblades        = {  90948, 213010, 1 }, -- You heal for 3% of all Fire damage you deal.
    collective_anguish       = {  95152, 390152, 1 }, -- Eye Beam summons an allied Vengeance Demon Hunter who casts Fel Devastation, dealing 43,890 Fire damage over 2.2 sec. Dealing damage heals you for up to 3,188 health.
    consume_magic            = {  91006, 278326, 1 }, -- Consume 1 beneficial Magic effect removing it from the target.
    darkness                 = {  91002, 196718, 1 }, -- Summons darkness around you in an 8 yd radius, granting friendly targets a 15% chance to avoid all damage from an attack. Lasts 8 sec. Chance to avoid damage increased by 100% when not in a raid.
    demon_muzzle             = {  90928, 388111, 1 }, -- Enemies deal 8% reduced magic damage to you for 8 sec after being afflicted by one of your Sigils.
    demonic                  = {  91003, 213410, 1 }, -- Eye Beam causes you to enter demon form for 5 sec after it finishes dealing damage.
    disrupting_fury          = {  90937, 183782, 1 }, -- Disrupt generates 30 Fury on a successful interrupt.
    erratic_felheart         = {  90996, 391397, 2 }, -- The cooldown of Fel Rush is reduced by 10%.
    felblade                 = {  95150, 232893, 1 }, -- Charge to your target and deal 22,671 Fire damage. Demon Blades has a chance to reset the cooldown of Felblade. Generates 40 Fury.
    felfire_haste            = {  90939, 389846, 1 }, -- Fel Rush increases your movement speed by 10% for 8 sec.
    flames_of_fury           = {  90949, 389694, 2 }, -- Sigil of Flame deals 35% increased damage and generates 1 additional Fury per target hit.
    illidari_knowledge       = {  90935, 389696, 1 }, -- Reduces magic damage taken by 5%.
    imprison                 = {  91007, 217832, 1 }, -- Imprisons a demon, beast, or humanoid, incapacitating them for 1 min. Damage may cancel the effect. Limit 1.
    improved_disrupt         = {  90938, 320361, 1 }, -- Increases the range of Disrupt to 10 yds.
    improved_sigil_of_misery = {  90945, 320418, 1 }, -- Reduces the cooldown of Sigil of Misery by 30 sec.
    infernal_armor           = {  91004, 320331, 2 }, -- Immolation Aura increases your armor by 20% and causes melee attackers to suffer 2,212 Fire damage.
    internal_struggle        = {  90934, 393822, 1 }, -- Increases your mastery by 4.5%.
    live_by_the_glaive       = {  95151, 428607, 1 }, -- When you parry an attack or have one of your attacks parried, restore 2% of max health and 10 Fury. This effect may only occur once every 5 sec.
    long_night               = {  91001, 389781, 1 }, -- Increases the duration of Darkness by 3 sec.
    lost_in_darkness         = {  90947, 389849, 1 }, -- Spectral Sight has 5 sec reduced cooldown and no longer reduces movement speed.
    master_of_the_glaive     = {  90994, 389763, 1 }, -- Throw Glaive has 2 charges and snares all enemies hit by 50% for 6 sec.
    pitch_black              = {  91001, 389783, 1 }, -- Reduces the cooldown of Darkness by 120 sec.
    precise_sigils           = {  95155, 389799, 1 }, -- All Sigils are now placed at your target's location.
    pursuit                  = {  90940, 320654, 1 }, -- Mastery increases your movement speed.
    quickened_sigils         = {  95149, 209281, 1 }, -- All Sigils activate 1 second faster.
    rush_of_chaos            = {  95148, 320421, 2 }, -- Reduces the cooldown of Metamorphosis by 30 sec.
    shattered_restoration    = {  90950, 389824, 1 }, -- The healing of Shattered Souls is increased by 10%.
    sigil_of_misery          = {  90946, 207684, 1 }, -- Place a Sigil of Misery at the target location that activates after 1 sec. Causes all enemies affected by the sigil to cower in fear, disorienting them for 15 sec.
    sigil_of_spite           = {  90997, 390163, 1 }, -- Place a demonic sigil at the target location that activates after 1 sec. Detonates to deal 120,957 Chaos damage and shatter up to 3 Lesser Soul Fragments from enemies affected by the sigil. Deals reduced damage beyond 5 targets.
    soul_rending             = {  90936, 204909, 2 }, -- Leech increased by 6%. Gain an additional 6% leech while Metamorphosis is active.
    soul_sigils              = {  90929, 395446, 1 }, -- Afflicting an enemy with a Sigil generates 1 Lesser Soul Fragment.
    swallowed_anger          = {  91005, 320313, 1 }, -- Consume Magic generates 20 Fury when a beneficial Magic effect is successfully removed from the target.
    the_hunt                 = {  90927, 370965, 1 }, -- Charge to your target, striking them for 153,784 Chaos damage, rooting them in place for 1.5 sec and inflicting 119,447 Chaos damage over 6 sec to up to 5 enemies in your path. The pursuit invigorates your soul, healing you for 10% of the damage you deal to your Hunt target for 20 sec.
    unrestrained_fury        = {  90941, 320770, 1 }, -- Increases maximum Fury by 20.
    vengeful_bonds           = {  90930, 320635, 1 }, -- Vengeful Retreat reduces the movement speed of all nearby enemies by 70% for 3 sec.
    vengeful_retreat         = {  90942, 198793, 1 }, -- Remove all snares and vault away. Nearby enemies take 2,865 Physical damage.
    will_of_the_illidari     = {  91000, 389695, 1 }, -- Increases maximum health by 5%.

    -- Havoc
    a_fire_inside            = {  95143, 427775, 1 }, -- Immolation Aura has 1 additional charge, 30% chance to refund a charge when used, and deals Chaos damage instead of Fire. You can have multiple Immolation Auras active at a time.
    accelerated_blade        = {  91011, 391275, 1 }, -- Throw Glaive deals 60% increased damage, reduced by 30% for each previous enemy hit.
    blind_fury               = {  91026, 203550, 2 }, -- Eye Beam generates 40 Fury every second, and its damage and duration are increased by 10%.
    burning_hatred           = {  90923, 320374, 1 }, -- Immolation Aura generates an additional 40 Fury over 10 sec.
    burning_wound            = {  90917, 391189, 1 }, -- Demon Blades and Throw Glaive leave open wounds on your enemies, dealing 20,193 Chaos damage over 15 sec and increasing damage taken from your Immolation Aura by 40%. May be applied to up to 3 targets.
    chaos_theory             = {  91035, 389687, 1 }, -- Blade Dance causes your next Chaos Strike within 8 sec to have a 14-30% increased critical strike chance and will always refund Fury.
    chaotic_disposition      = {  95147, 428492, 2 }, -- Your Chaos damage has a 7.77% chance to be increased by 17%, occurring up to 3 total times.
    chaotic_transformation   = {  90922, 388112, 1 }, -- When you activate Metamorphosis, the cooldowns of Blade Dance and Eye Beam are immediately reset.
    critical_chaos           = {  91028, 320413, 1 }, -- The chance that Chaos Strike will refund 20 Fury is increased by 30% of your critical strike chance.
    cycle_of_hatred          = {  91032, 258887, 1 }, -- Activating Eye Beam reduces the cooldown of your next Eye Beam by 5.0 sec, stacking up to 20 sec.
    dancing_with_fate        = {  91015, 389978, 2 }, -- The final slash of Blade Dance deals an additional 25% damage.
    dash_of_chaos            = {  93014, 427794, 1 }, -- For 2 sec after using Fel Rush, activating it again will dash back towards your initial location.
    deflecting_dance         = {  93015, 427776, 1 }, -- You deflect incoming attacks while Blade Dancing, absorbing damage up to 15% of your maximum health.
    demon_blades             = {  91019, 203555, 1 }, -- Your auto attacks deal an additional 3,423 Shadow damage and generate 7-12 Fury.
    demon_hide               = {  91017, 428241, 1 }, -- Magical damage increased by 3%, and Physical damage taken reduced by 5%.
    desperate_instincts      = {  93016, 205411, 1 }, -- Blur now reduces damage taken by an additional 10%. Additionally, you automatically trigger Blur with 50% reduced cooldown and duration when you fall below 35% health. This effect can only occur when Blur is not on cooldown.
    essence_break            = {  91033, 258860, 1 }, -- Slash all enemies in front of you for 75,406 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by 80% for 4 sec. Deals reduced damage beyond 8 targets.
    exergy                   = {  91021, 206476, 1 }, -- The Hunt and Vengeful Retreat increase your damage by 5% for 20 sec.
    eye_beam                 = {  91018, 198013, 1 }, -- Blasts all enemies in front of you, for up to 322,392 Chaos damage over 1.8 sec. Deals reduced damage beyond 5 targets. When Eye Beam finishes fully channeling, your Haste is increased by an additional 10% for 10 sec.
    fel_barrage              = {  95144, 258925, 1 }, -- Unleash a torrent of Fel energy, rapidly consuming Fury to inflict 9,316 Chaos damage to all enemies within 12 yds, lasting 8 sec or until Fury is depleted. Deals reduced damage beyond 5 targets.
    first_blood              = {  90925, 206416, 1 }, -- Blade Dance deals 60,036 Chaos damage to the first target struck.
    furious_gaze             = {  91025, 343311, 1 }, -- When Eye Beam finishes fully channeling, your Haste is increased by an additional 10% for 10 sec.
    furious_throws           = {  93013, 393029, 1 }, -- Throw Glaive now costs 25 Fury and throws a second glaive at the target.
    glaive_tempest           = {  91035, 342817, 1 }, -- Launch two demonic glaives in a whirlwind of energy, causing 80,232 Chaos damage over 3 sec to all nearby enemies. Deals reduced damage beyond 8 targets.
    growing_inferno          = {  90916, 390158, 1 }, -- Immolation Aura's damage increases by 10% each time it deals damage.
    improved_chaos_strike    = {  91030, 343206, 1 }, -- Chaos Strike damage increased by 10%.
    improved_fel_rush        = {  93014, 343017, 1 }, -- Fel Rush damage increased by 20%.
    inertia                  = {  91021, 427640, 1 }, -- The Hunt and Vengeful Retreat cause your next Fel Rush or Felblade to empower you, increasing damage by 18% for 5 sec.
    initiative               = {  91027, 388108, 1 }, -- Damaging an enemy before they damage you increases your critical strike chance by 10% for 5 sec. Vengeful Retreat refreshes your potential to trigger this effect on any enemies you are in combat with.
    inner_demon              = {  91024, 389693, 1 }, -- Entering demon form causes your next Chaos Strike to unleash your inner demon, causing it to crash into your target and deal 56,855 Chaos damage to all nearby enemies. Deals reduced damage beyond 5 targets.
    insatiable_hunger        = {  91019, 258876, 1 }, -- Demon's Bite deals 50% more damage and generates 5 to 10 additional Fury.
    isolated_prey            = {  91036, 388113, 1 }, -- Chaos Nova, Eye Beam, and Immolation Aura gain bonuses when striking 1 target.  Chaos Nova: Stun duration increased by 2 sec.  Eye Beam: Deals 30% increased damage.  Immolation Aura: Always critically strikes.
    know_your_enemy          = {  91034, 388118, 2 }, -- Gain critical strike damage equal to 40% of your critical strike chance.
    looks_can_kill           = {  90921, 320415, 1 }, -- Eye Beam deals guaranteed critical strikes.
    mortal_dance             = {  93015, 328725, 1 }, -- Blade Dance now reduces targets' healing received by 50% for 6 sec.
    netherwalk               = {  93016, 196555, 1 }, -- Slip into the nether, increasing movement speed by 100% and becoming immune to damage, but unable to attack. Lasts 6 sec.
    ragefire                 = {  90918, 388107, 1 }, -- Each time Immolation Aura deals damage, 30% of the damage dealt by up to 3 critical strikes is gathered as Ragefire. When Immolation Aura expires you explode, dealing all stored Ragefire damage to nearby enemies.
    relentless_onslaught     = {  91012, 389977, 1 }, -- Chaos Strike has a 10% chance to trigger a second Chaos Strike.
    restless_hunter          = {  91024, 390142, 1 }, -- Leaving demon form grants a charge of Fel Rush and increases the damage of your next Blade Dance by 50%.
    scars_of_suffering       = {  90914, 428232, 1 }, -- Increases Versatility by 4% and reduces threat generated by 8%.
    screaming_brutality      = {  90919, 1220506, 1 }, -- Blade Dance automatically triggers Throw Glaive on your primary target for 100% damage and each slash has a 50% chance to Throw Glaive an enemy for 35% damage.
    serrated_glaive          = {  91013, 390154, 1 }, -- Enemies hit by Chaos Strike or Throw Glaive take 15% increased damage from Chaos Strike and Throw Glaive for 15 sec.
    shattered_destiny        = {  91031, 388116, 1 }, -- The duration of your active demon form is extended by 0.1 sec per 12 Fury spent.
    soulscar                 = {  91012, 388106, 1 }, -- Throw Glaive causes targets to take an additional 80% of damage dealt as Chaos over 6 sec.
    tactical_retreat         = {  91022, 389688, 1 }, -- Vengeful Retreat has a 5 sec reduced cooldown and generates 80 Fury over 10 sec.
    trail_of_ruin            = {  90915, 258881, 1 }, -- The final slash of Blade Dance inflicts an additional 19,218 Chaos damage over 4 sec.
    unbound_chaos            = {  91020, 347461, 1 }, -- The Hunt and Vengeful Retreat increase the damage of your next Fel Rush or Felblade by 300%. Lasts 12 sec.

    -- Aldrachi Reaver
    aldrachi_tactics         = {  94914, 442683, 1 }, -- The second enhanced ability in a pattern shatters an additional Soul Fragment.
    army_unto_oneself        = {  94896, 442714, 1 }, -- Felblade surrounds you with a Blade Ward, reducing damage taken by 10% for 5 sec.
    art_of_the_glaive        = {  94915, 442290, 1, "aldrachi_reaver" }, -- Consuming 6 Soul Fragments or casting The Hunt converts your next Throw Glaive into Reaver's Glaive.  Reaver's Glaive: Throw a glaive enhanced with the essence of consumed souls at your target, dealing 46,361 Physical damage and ricocheting to 3 additional enemies. Begins a well-practiced pattern of glaivework, enhancing your next Chaos Strike and Blade Dance. The enhanced ability you cast first deals 10% increased damage, and the second deals 20% increased damage.
    evasive_action           = {  94911, 444926, 1 }, -- Vengeful Retreat can be cast a second time within 3 sec.
    fury_of_the_aldrachi     = {  94898, 442718, 1 }, -- When enhanced by Reaver's Glaive, Blade Dance casts 3 additional glaive slashes to nearby targets. If cast after Chaos Strike, cast 6 slashes instead.
    incisive_blade           = {  94895, 442492, 1 }, -- Chaos Strike deals 10% increased damage.
    incorruptible_spirit     = {  94896, 442736, 1 }, -- Each Soul Fragment you consume shields you for an additional 15% of the amount healed.
    keen_engagement          = {  94910, 442497, 1 }, -- Reaver's Glaive generates 20 Fury.
    preemptive_strike        = {  94910, 444997, 1 }, -- Throw Glaive deals 3,443 Physical damage to enemies near its initial target.
    reavers_mark             = {  94903, 442679, 1 }, -- When enhanced by Reaver's Glaive, Chaos Strike applies Reaver's Mark, which causes the target to take 7% increased damage for 20 sec. If cast after Blade Dance, Reaver's Mark is increased to 14%.
    thrill_of_the_fight      = {  94919, 442686, 1 }, -- After consuming both enhancements, gain Thrill of the Fight, increasing your attack speed by 15% for 20 sec and your damage and healing by 20% for 10 sec.
    unhindered_assault       = {  94911, 444931, 1 }, -- Vengeful Retreat resets the cooldown of Felblade.
    warblades_hunger         = {  94906, 442502, 1 }, -- Consuming a Soul Fragment causes your next Chaos Strike to deal 6,886 additional Physical damage. Felblade consumes up to 5 nearby Soul Fragments.
    wounded_quarry           = {  94897, 442806, 1 }, -- Expose weaknesses in the target of your Reaver's Mark, causing your Physical damage to any enemy to also deal 20% of the damage dealt to your marked target as Chaos.

    -- Fel-Scarred
    burning_blades           = {  94905, 452408, 1 }, -- Your blades burn with Fel energy, causing your Chaos Strike, Throw Glaive, and auto-attacks to deal an additional 50% damage as Fire over 6 sec.
    demonic_intensity        = {  94901, 452415, 1 }, -- Activating Metamorphosis greatly empowers Eye Beam, Immolation Aura, and Sigil of Flame. Demonsurge damage is increased by 10% for each time it previously triggered while your demon form is active.
    demonsurge               = {  94917, 452402, 1, "felscarred" }, -- Metamorphosis now also causes Demon Blades to generate 5 additional Fury. While demon form is active, the first cast of each empowered ability induces a Demonsurge, causing you to explode with Fel energy, dealing 28,790 Fire damage to nearby enemies.
    enduring_torment         = {  94916, 452410, 1 }, -- The effects of your demon form persist outside of it in a weakened state, increasing Chaos Strike and Blade Dance damage by 15%, and Haste by 5%.
    flamebound               = {  94902, 452413, 1 }, -- Immolation Aura has 2 yd increased radius and 30% increased critical strike damage bonus.
    focused_hatred           = {  94918, 452405, 1 }, -- Demonsurge deals 50% increased damage when it strikes a single target. Each additional target reduces this bonus by 10%.
    improved_soul_rending    = {  94899, 452407, 1 }, -- Leech granted by Soul Rending increased by 2% and an additional 2% while Metamorphosis is active.
    monster_rising           = {  94909, 452414, 1 }, -- Agility increased by 8% while not in demon form.
    pursuit_of_angriness     = {  94913, 452404, 1 }, -- Movement speed increased by 1% per 10 Fury.
    set_fire_to_the_pain     = {  94899, 452406, 1 }, -- 5% of all non-Fire damage taken is instead taken as Fire damage over 6 sec. Fire damage taken reduced by 10%.
    student_of_suffering     = {  94902, 452412, 1 }, -- Sigil of Flame applies Student of Suffering to you, increasing Mastery by 18.0% and granting 5 Fury every 2 sec, for 6 sec.
    untethered_fury          = {  94904, 452411, 1 }, -- Maximum Fury increased by 50.
    violent_transformation   = {  94912, 452409, 1 }, -- When you activate Metamorphosis, the cooldowns of your Sigil of Flame and Immolation Aura are immediately reset.
    wave_of_debilitation     = {  94913, 452403, 1 }, -- Chaos Nova slows enemies by 60% and reduces attack and cast speed 15% for 5 sec after its stun fades.
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    blood_moon        = 5433, -- (355995)
    cleansed_by_flame =  805, -- (205625)
    cover_of_darkness = 1206, -- (357419)
    detainment        =  812, -- (205596)
    glimpse           =  813, -- (354489)
    illidans_grasp    = 5691, -- (205630) You strangle the target with demonic magic, stunning them in place and dealing 120,508 Shadow damage over 5 sec while the target is grasped. Can move while channeling. Use Illidan's Grasp again to toss the target to a location within 20 yards.
    rain_from_above   =  811, -- (206803) You fly into the air out of harm's way. While floating, you gain access to Fel Lance allowing you to deal damage to enemies below.
    reverse_magic     =  806, -- (205604) Removes all harmful magical effects from yourself and all nearby allies within 10 yards, and sends them back to their original caster if possible.
    sigil_mastery     = 5523, -- (211489)
    unending_hatred   = 1218, -- (213480)
} )

-- Auras
spec:RegisterAuras( {
    -- $w1 Soul Fragments consumed. At $?a212612[$442290s1~][$442290s2~], Reaver's Glaive is available to cast.
    art_of_the_glaive = {
        id = 444661,
        duration = 30.0,
        max_stack = 6
    },
    -- Dodge chance increased by $s2%.
    -- https://wowhead.com/beta/spell=188499
    blade_dance = {
        id = 188499,
        duration = 1,
        max_stack = 1
    },
    -- Damage taken reduced by $s1%.
    blade_ward = {
        id = 442715,
        duration = 5.0,
        max_stack = 1
    },
    blazing_slaughter = {
        id = 355892,
        duration = 12,
        max_stack = 20
    },
    -- Versatility increased by $w1%.
    -- https://wowhead.com/beta/spell=355894
    blind_faith = {
        id = 355894,
        duration = 20,
        max_stack = 1
    },
    -- Dodge increased by $s2%. Damage taken reduced by $s3%.
    -- https://wowhead.com/beta/spell=212800
    blur = {
        id = 212800,
        duration = 10,
        max_stack = 1
    },
    -- https://www.wowhead.com/spell=453177
    burning_blades = {
        id = 453177,
        duration = 6,
        max_stack = 1
    },
    -- Talent: Taking $w1 Chaos damage every $t1 seconds.  Damage taken from $@auracaster's Immolation Aura increased by $s2%.
    -- https://wowhead.com/beta/spell=391191
    burning_wound_391191 = {
        id = 391191,
        duration = 15,
        tick_time = 3,
        max_stack = 1
    },
    burning_wound_346278 = {
        id = 346278,
        duration = 15,
        tick_time = 3,
        max_stack = 1
    },
    burning_wound = {
        alias = { "burning_wound_391191", "burning_wound_346278" },
        aliasMode = "first",
        aliasType = "buff"
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=179057
    chaos_nova = {
        id = 179057,
        duration = function () return talent.isolated_prey.enabled and active_enemies == 1 and 4 or 2 end,
        type = "Magic",
        max_stack = 1
    },
    chaos_theory = {
        id = 390195,
        duration = 8,
        max_stack = 1
    },
    chaotic_blades = {
        id = 337567,
        duration = 8,
        max_stack = 1
    },
    cycle_of_hatred = {
        id = 1214887,
        duration = 3600,
        max_stack = 4
    },
    darkness = {
        id = 196718,
        duration = function () return pvptalent.cover_of_darkness.enabled and 10 or 8 end,
        max_stack = 1
    },
    death_sweep = {
        id = 210152,
        duration = 1,
        max_stack = 1
    },
    -- https://www.wowhead.com/spell=427901
    -- Deflecting Dance Absorbing 1180318 damage.
    deflecting_dance = {
        id = 427901,
        duration = 1,
        max_stack = 1
    },
    demon_soul = {
        id = 347765,
        duration = 15,
        max_stack = 1
    },
    -- https://www.wowhead.com/spell=452416
    -- Demonsurge Damage of your next Demonsurge is increased by 40%.
    demonsurge = {
        id = 452416,
        duration = 12,
        max_stack = 10
    },
    -- Fake buffs for demonsurge damage procs
    demonsurge_abyssal_gaze = {},
    demonsurge_annihilation = {},
    demonsurge_consuming_fire = {},
    demonsurge_death_sweep = {},
    demonsurge_hardcast = {},
    demonsurge_sigil_of_doom = {},
    -- TODO: This aura determines sigil pop time.
    elysian_decree = {
        id = 390163,
        duration = function () return talent.quickened_sigils.enabled and 1 or 2 end,
        max_stack = 1,
        copy = "sigil_of_spite"
    },
    -- https://www.wowhead.com/spell=453314
    -- Enduring Torment Chaos Strike and Blade Dance damage increased by 10%. Haste increased by 5%.
    enduring_torment = {
        id = 453314,
        duration = 3600,
        max_stack = 1
    },
    essence_break = {
        id = 320338,
        duration = 4,
        max_stack = 1,
        copy = "dark_slash" -- Just in case.
    },
    -- Vengeful Retreat may be cast again.
    evasive_action = {
        id = 444929,
        duration = 3.0,
        max_stack = 1,
    },
    -- https://wowhead.com/beta/spell=198013
    eye_beam = {
        id = 198013,
        duration = function () return 2 * ( 1 + 0.1 * talent.blind_fury.rank ) * haste end,
        generate = function( t )
            if buff.casting.up and buff.casting.v1 == 198013 then
                t.applied  = buff.casting.applied
                t.duration = buff.casting.duration
                t.expires  = buff.casting.expires
                t.stack    = 1
                t.caster   = "player"
                forecastResources( "fury" )
                return
            end

            t.applied  = 0
            t.duration = class.auras.eye_beam.duration
            t.expires  = 0
            t.stack    = 0
            t.caster   = "nobody"
        end,
        tick_time = 0.2,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Unleashing Fel.
    -- https://wowhead.com/beta/spell=258925
    fel_barrage = {
        id = 258925,
        duration = 8,
        tick_time = 0.25,
        max_stack = 1
    },
    -- Legendary.
    fel_bombardment = {
        id = 337849,
        duration = 40,
        max_stack = 5,
    },
    -- Legendary
    fel_devastation = {
        id = 333105,
        duration = 2,
        max_stack = 1,
    },
    furious_gaze = {
        id = 343312,
        duration = 10,
        max_stack = 1,
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=211881
    fel_eruption = {
        id = 211881,
        duration = 4,
        max_stack = 1
    },
    -- Talent: Movement speed increased by $w1%.
    -- https://wowhead.com/beta/spell=389847
    felfire_haste = {
        id = 389847,
        duration = 8,
        max_stack = 1,
        copy = 338804
    },
    -- Branded, dealing $204021s1% less damage to $@auracaster$?s389220[ and taking $w2% more Fire damage from them][].
    -- https://wowhead.com/beta/spell=207744
    fiery_brand = {
        id = 207744,
        duration = 10,
        max_stack = 1
    },
    -- Talent: Battling a demon from the Theater of Pain...
    -- https://wowhead.com/beta/spell=391430
    fodder_to_the_flame = {
        id = 391430,
        duration = 25,
        max_stack = 1,
        copy = { 329554, 330910 }
    },
    -- The demon is linked to you.
    fodder_to_the_flame_chase = {
        id = 328605,
        duration = 3600,
        max_stack = 1,
    },
    -- This is essentially the countdown before the demon despawns (you can Imprison it for a long time).
    fodder_to_the_flame_cooldown = {
        id = 342357,
        duration = 120,
        max_stack = 1,
    },
    -- Falling speed reduced.
    -- https://wowhead.com/beta/spell=131347
    glide = {
        id = 131347,
        duration = 3600,
        max_stack = 1
    },
    -- Burning nearby enemies for $258922s1 $@spelldesc395020 damage every $t1 sec.$?a207548[    Movement speed increased by $w4%.][]$?a320331[    Armor increased by $w5%. Attackers suffer $@spelldesc395020 damage.][]
    -- https://wowhead.com/beta/spell=258920
    immolation_aura_1 = {
        id = 258920,
        duration = function() return talent.felfire_heart.enabled and 8 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    immolation_aura_2 = {
        id = 427912,
        duration = function() return talent.felfire_heart.enabled and 8 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    immolation_aura_3 = {
        id = 427913,
        duration = function() return talent.felfire_heart.enabled and 8 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    immolation_aura_4 = {
        id = 427914,
        duration = function() return talent.felfire_heart.enabled and 8 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    immolation_aura_5 = {
        id = 427915,
        duration = function() return talent.felfire_heart.enabled and 8 or 6 end,
        tick_time = 1,
        max_stack = 1
    },
    immolation_aura = {
        alias = { "immolation_aura_1", "immolation_aura_2", "immolation_aura_3", "immolation_aura_4", "immolation_aura_5" },
        aliasMode = "longest",
        aliasType = "buff",
        max_stack = 5
    },
    -- Talent: Incapacitated.
    -- https://wowhead.com/beta/spell=217832
    imprison = {
        id = 217832,
        duration = 60,
        mechanic = "sap",
        type = "Magic",
        max_stack = 1
    },
    -- Damage done increased by $w1%.
    inertia = {
        id = 427641,
        duration = 5,
        max_stack = 1,
    },
    -- https://www.wowhead.com/spell=1215159
    -- Inertia Your next Fel Rush or Felblade increases your damage by 18% for 5 sec.
    inertia_trigger = {
        id = 1215159,
        duration = 12,
        max_stack = 1,
    },
    initiative = {
        id = 391215,
        duration = 5,
        max_stack = 1
    },
    initiative_tracker = {
        duration = 3600,
        max_stack = 1
    },
    inner_demon = {
        id = 337313,
        duration = 10,
        max_stack = 1,
        copy = 390145
    },
    -- Talent: Movement speed reduced by $s1%.
    -- https://wowhead.com/beta/spell=213405
    master_of_the_glaive = {
        id = 213405,
        duration = 6,
        mechanic = "snare",
        max_stack = 1
    },
    -- Chaos Strike and Blade Dance upgraded to $@spellname201427 and $@spellname210152.  Haste increased by $w4%.$?s235893[  Versatility increased by $w5%.][]$?s204909[  Leech increased by $w3%.][]
    -- https://wowhead.com/beta/spell=162264
    metamorphosis = {
        id = 162264,
        duration = 20,
        max_stack = 1,
        -- This copy is for SIMC compatibility while avoiding managing a virtual buff.
        copy = "demonsurge_demonic"
    },
    exergy = {
        id = 208628,
        duration = 30, -- extends up to 30
        max_stack = 1,
        copy = "momentum"
    },
    -- Agility increased by $w1%.
    monster_rising = {
        id = 452550,
        duration = 3600,
        max_stack = 1,
    },
    -- Stunned.
    -- https://wowhead.com/beta/spell=200166
    metamorphosis_stun = {
        id = 200166,
        duration = 3,
        type = "Magic",
        max_stack = 1
    },
    -- Dazed.
    -- https://wowhead.com/beta/spell=247121
    metamorphosis_daze = {
        id = 247121,
        duration = 3,
        type = "Magic",
        max_stack = 1
    },
    misery_in_defeat = {
        id = 391369,
        duration = 5,
        max_stack = 1,
    },
    -- Talent: Healing effects received reduced by $w1%.
    -- https://wowhead.com/beta/spell=356608
    mortal_dance = {
        id = 356608,
        duration = 6,
        max_stack = 1
    },
    -- Talent: Immune to damage and unable to attack.  Movement speed increased by $s3%.
    -- https://wowhead.com/beta/spell=196555
    netherwalk = {
        id = 196555,
        duration = 6,
        max_stack = 1
    },
    -- $w3
    pursuit_of_angriness = {
        id = 452404,
        duration = 0.0,
        tick_time = 1.0,
        max_stack = 1,
    },
    ragefire = {
        id = 390192,
        duration = 30,
        max_stack = 1,
    },
    rain_from_above_immune = {
        id = 206803,
        duration = 1,
        tick_time = 1,
        max_stack = 1,
        copy = "rain_from_above_launch"
    },
    rain_from_above = { -- Gliding/floating.
        id = 206804,
        duration = 10,
        max_stack = 1
    },
    reavers_glaive = {
        -- no id, fake buff
        duration = 3600,
        max_Stack = 1
    },
    restless_hunter = {
        id = 390212,
        duration = 12,
        max_stack = 1
    },
    -- Damage taken from Chaos Strike and Throw Glaive increased by $w1%.
    serrated_glaive = {
        id = 390155,
        duration = 15,
        max_stack = 1,
    },
    -- Taking $w1 Fire damage every $t1 sec.
    set_fire_to_the_pain = {
        id = 453286,
        duration = 6.0,
        tick_time = 1.0,
    },
    -- Movement slowed by $s1%.
    -- https://wowhead.com/beta/spell=204843
    sigil_of_chains = {
        id = 204843,
        duration = function() return 6 + talent.extended_sigils.rank + ( talent.precise_sigils.enabled and 2 or 0 ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Suffering $w2 $@spelldesc395020 damage every $t2 sec.
    -- https://wowhead.com/beta/spell=204598
    sigil_of_flame = {
        id = 204598,
        duration = function() return ( talent.felfire_heart.enabled and 8 or 6 ) + talent.extended_sigils.rank + ( talent.precise_sigils.enabled and 2 or 0 ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Sigil of Flame is active.
    -- https://wowhead.com/beta/spell=389810
    sigil_of_flame_active = {
        id = 389810,
        duration = function () return talent.quickened_sigils.enabled and 1 or 2 end,
        max_stack = 1,
        copy = 204596
    },
    -- Talent: Disoriented.
    -- https://wowhead.com/beta/spell=207685
    sigil_of_misery_debuff = {
        id = 207685,
        duration = function() return 15 + talent.extended_sigils.rank + ( talent.precise_sigils.enabled and 2 or 0 ) end,
        mechanic = "flee",
        type = "Magic",
        max_stack = 1
    },
    sigil_of_misery = { -- TODO: Model placement pop.
        id = 207684,
        duration = function () return talent.quickened_sigils.enabled and 1 or 2 end,
        max_stack = 1
    },
    -- Silenced.
    -- https://wowhead.com/beta/spell=204490
    sigil_of_silence_debuff = {
        id = 204490,
        duration = function() return 6 + talent.extended_sigils.rank + ( talent.precise_sigils.enabled and 2 or 0 ) end,
        type = "Magic",
        max_stack = 1
    },
    sigil_of_silence = { -- TODO: Model placement pop.
        id = 202137,
        duration = function () return talent.quickened_sigils.enabled and 1 or 2 end,
        max_stack = 1
    },
    -- Consume to heal for $210042s1% of your maximum health.
    -- https://wowhead.com/beta/spell=203795
    soul_fragment = {
        id = 203795,
        duration = 20,
        max_stack = 1
    },
    -- Talent: Suffering $w1 Chaos damage every $t1 sec.
    -- https://wowhead.com/beta/spell=390181
    soulscar = {
        id = 390181,
        duration = 6,
        tick_time = 2,
        max_stack = 1
    },
    -- Can see invisible and stealthed enemies.  Can see enemies and treasures through physical barriers.
    -- https://wowhead.com/beta/spell=188501
    spectral_sight = {
        id = 188501,
        duration = 10,
        max_stack = 1
    },
    -- Mastery increased by ${$w1*$mas}.1%. ; Generating $453236s1 Fury every $t2 sec.
    student_of_suffering = {
        id = 453239,
        duration = 6,
        tick_time = 2.0,
        max_stack = 1,
    },
    tactical_retreat = {
        id = 389890,
        duration = 8,
        tick_time = 1,
        max_stack = 1
    },
    -- Talent: Suffering $w1 $@spelldesc395042 damage every $t1 sec.
    -- https://wowhead.com/beta/spell=345335
    the_hunt_dot = {
        id = 370969,
        duration = function() return set_bonus.tier31_4pc > 0 and 12 or 6 end,
        tick_time = 2,
        type = "Magic",
        max_stack = 1,
        copy = 345335
    },
    -- Talent: Marked by the Demon Hunter, converting $?c1[$345422s1%][$345422s2%] of the damage done to healing.
    -- https://wowhead.com/beta/spell=370966
    the_hunt = {
        id = 370966,
        duration = 30,
        max_stack = 1,
        copy = 323802
    },
    the_hunt_root = {
        id = 370970,
        duration = 1.5,
        max_stack = 1,
        copy = 323996
    },
    -- Attack Speed increased by $w1%
    thrill_of_the_fight = {
        id = 442695,
        duration = 20,
        max_stack = 1,
        copy = "thrill_of_the_fight_attack_speed",
    },
    thrill_of_the_fight_damage = {
        id = 442688,
        duration = 10,
        max_stack = 1,
    },
    -- Taunted.
    -- https://wowhead.com/beta/spell=185245
    torment = {
        id = 185245,
        duration = 3,
        max_stack = 1
    },
    -- Talent: Suffering $w1 Chaos damage every $t1 sec.
    -- https://wowhead.com/beta/spell=258883
    trail_of_ruin = {
        id = 258883,
        duration = 4,
        tick_time = 1,
        type = "Magic",
        max_stack = 1
    },
    unbound_chaos = {
        id = 347462,
        duration = 20,
        max_stack = 1,
        -- copy = "inertia_trigger"
    },
    vengeful_retreat_movement = {
        duration = 1,
        max_stack = 1,
        generate = function( t )
            if action.vengeful_retreat.lastCast > query_time - 1 then
                t.applied  = action.vengeful_retreat.lastCast
                t.duration = 1
                t.expires  = action.vengeful_retreat.lastCast + 1
                t.stack    = 1
                t.caster   = "player"
                return
            end

            t.applied  = 0
            t.duration = 1
            t.expires  = 0
            t.stack    = 0
            t.caster   = "nobody"
        end,
    },
    -- Talent: Movement speed reduced by $s1%.
    -- https://wowhead.com/beta/spell=198813
    vengeful_retreat = {
        id = 198813,
        duration = 3,
        max_stack = 1,
        copy = "vengeful_retreat_snare"
    },
    -- Your next $?a212612[Chaos Strike]?s263642[Fracture][Shear] will deal $442507s1 additional Physical damage.
    warblades_hunger = {
        id = 442503,
        duration = 30.0,
        max_stack = 1,
    },

    -- Conduit
    exposed_wound = {
        id = 339229,
        duration = 10,
        max_stack = 1,
    },

    -- PvP Talents
    chaotic_imprint_shadow = {
        id = 356656,
        duration = 20,
        max_stack = 1,
    },
    chaotic_imprint_nature = {
        id = 356660,
        duration = 20,
        max_stack = 1,
    },
    chaotic_imprint_arcane = {
        id = 356658,
        duration = 20,
        max_stack = 1,
    },
    chaotic_imprint_fire = {
        id = 356661,
        duration = 20,
        max_stack = 1,
    },
    chaotic_imprint_frost = {
        id = 356659,
        duration = 20,
        max_stack = 1,
    },
    -- Conduit
    demonic_parole = {
        id = 339051,
        duration = 12,
        max_stack = 1
    },
    glimpse = {
        id = 354610,
        duration = 8,
        max_stack = 1,
    },
} )

spec:RegisterStateExpr( "soul_fragments", function ()
    return GetSpellCastCount(232893) -- only works with Reaver hero tree
end )

spec:RegisterStateTable( "fragments", {
    real = 0,
    realTime = 0,
} )

spec:RegisterStateFunction( "queue_fragments", function( num, extraTime )
    fragments.real = fragments.real + num
    fragments.realTime = GetTime() + 1.25 + ( extraTime or 0 )
end )

spec:RegisterStateFunction( "purge_fragments", function()
    fragments.real = 0
    fragments.realTime = 0
end )

spec:RegisterStateExpr( "activation_time", function()
    return talent.quickened_sigils.enabled and 1 or 2
end )

local furySpent = 0

local FURY = Enum.PowerType.Fury
local lastFury = -1

spec:RegisterUnitEvent( "UNIT_POWER_FREQUENT", "player", nil, function( event, unit, powerType )
    if powerType == "FURY" and state.set_bonus.tier30_2pc > 0 then
        local current = UnitPower( "player", FURY )

        if current < lastFury - 3 then
            furySpent = ( furySpent + lastFury - current )
        end

        lastFury = current
    end
end )

spec:RegisterStateExpr( "fury_spent", function ()
    if set_bonus.tier30_2pc == 0 then return 0 end
    return furySpent
end )

local queued_frag_modifier = 0
local initiative_actual, initiative_virtual = {}, {}

local death_events = {
    UNIT_DIED               = true,
    UNIT_DESTROYED          = true,
    UNIT_DISSIPATES         = true,
    PARTY_KILL              = true,
    SPELL_INSTAKILL         = true,
}

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID == GUID then
        if subtype == "SPELL_CAST_SUCCESS" then
            if spellID == 198793 and talent.initiative.enabled then
                wipe( initiative_actual )
            end

        elseif spellID == 203981 and fragments.real > 0 and ( subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_APPLIED_DOSE" ) then
            fragments.real = fragments.real - 1

        elseif state.set_bonus.tier30_2pc > 0 and subtype == "SPELL_AURA_APPLIED" and spellID == 408737 then
            furySpent = max( 0, furySpent - 175 )

        elseif state.talent.initiative.enabled and subtype == "SPELL_DAMAGE" then
            initiative_actual[ destGUID ] = true
        end
    elseif destGUID == GUID and ( subtype == "SPELL_DAMAGE" or subtype == "SPELL_PERIODIC_DAMAGE" ) then
        initiative_actual[ sourceGUID ] = true

    elseif death_events[ subtype ] then
        initiative_actual[ destGUID ] = nil
    end
end, false )

spec:RegisterEvent( "PLAYER_REGEN_ENABLED", function()
    wipe( initiative_actual )
end )

spec:RegisterHook( "UNIT_ELIMINATED", function( id )
    initiative_actual[ id ] = nil
end )

-- Gear Sets
spec:RegisterGear( "tier29", 200345, 200347, 200342, 200344, 200346 )
spec:RegisterAura( "seething_chaos", {
    id = 394934,
    duration = 6,
    max_stack = 1
} )

-- Tier 30
spec:RegisterGear( "tier30", 202527, 202525, 202524, 202523, 202522 )
-- 2 pieces (Havoc) : Every 175 Fury you spend, gain Seething Fury, increasing your Agility by 8% for 6 sec.
-- TODO: Track Fury spent toward Seething Fury.  New expressions: seething_fury_threshold, seething_fury_spent, seething_fury_deficit.
spec:RegisterAura( "seething_fury", {
    id = 408737,
    duration = 6,
    max_stack = 1
} )
-- 4 pieces (Havoc) : Each time you gain Seething Fury, gain 15 Fury and the damage of your next Eye Beam is increased by 15%, stacking 5 times.
spec:RegisterAura( "seething_potential", {
    id = 408754,
    duration = 60,
    max_stack = 5
} )

spec:RegisterGear( "tier31", 207261, 207262, 207263, 207264, 207266, 217228, 217230, 217226, 217227, 217229 )
-- (2) Blade Dance automatically triggers Throw Glaive on your primary target for $s3% damage and each slash has a $s2% chance to Throw Glaive an enemy for $s1% damage.
-- (4) Throw Glaive reduces the remaining cooldown of The Hunt by ${$s1/1000}.1 sec, and The Hunt's damage over time effect lasts ${$s2/1000} sec longer.

spec:RegisterGear( "tww2", 229316, 229314, 229319, 229317, 229315 )

spec:RegisterAuras( {
    -- 2-set
    -- Winning Streak! Increase the DPS of Blade Dance and Chaos Strike by 3% stacking pu to 10 times. Blade Dance and Chaos Strike have 15% chance of removing Winning Streak! .
    winning_streak = {
        id = 1217011,
        duration = 3600,
        max_stack = 10
        },
    --4-set
    -- Winning Streak persists for 7s after being cancelled. Entering Demon Form sacrifices all Winning Streak! stacks to gain 0% (?) Crit Strike Chance per stack consumed. Lasts 15s
    necessary_sacrifice = {
    id = 1217055,
    duration = 15,
    max_stack = 10
    },
    -- https://www.wowhead.com/spell=1220706
    -- Winning Streak! Ending a Winning Streak! Blade Dance and Chaos Strike damage increased by 6%.
    winning_streak_temporary = {
        id = 1220706,
        duration = 7,
        max_stack = 10
    },

} )

spec:RegisterGear( "tww1", 212068, 212066, 212065, 212064, 212063 )
spec:RegisterAura( "blade_rhapsody", {
    id = 454628,
    duration = 12,
    max_stack = 1
} )

-- Abilities that may trigger Demonsurge.
local demonsurge = {
    demonic = { "annihilation", "death_sweep" },
    hardcast = { "abyssal_gaze", "consuming_fire", "sigil_of_doom" },
}

local demonsurgeLastSeen = setmetatable( {}, {
    __index = function( t, k ) return rawget( t, k ) or 0 end,
})

spec:RegisterHook( "reset_precast", function ()
    wipe( initiative_virtual )
    active_dot.initiative_tracker = 0

    for k, v in pairs( initiative_actual ) do
        initiative_virtual[ k ] = v

        if k == target.unit then
            applyDebuff( "target", "initiative_tracker" )
        else
            active_dot.initiative_tracker = active_dot.initiative_tracker + 1
        end
    end

    --[[ 20250301: Legacy items from Legion that reduce the cooldown of Metamorphosis.
    local rps = 0

    if equipped.convergence_of_fates then
        rps = rps + ( 3 / ( 60 / 4.35 ) )
    end

    if equipped.delusions_of_grandeur then
        -- From SimC model, 1/13/2018.
        local fps = 10.2 + ( talent.demonic.enabled and 1.2 or 0 )

        -- SimC uses base haste, we'll use current since we recalc each time.
        fps = fps / haste

        -- Chaos Strike accounts for most Fury expenditure.
        fps = fps + ( ( fps * 0.9 ) * 0.5 * ( 40 / 100 ) )

        rps = rps + ( fps / 30 ) * ( 1 )
    end
    --]]

    if IsSpellKnownOrOverridesKnown( 442294 ) then
        applyBuff( "reavers_glaive" )
        if Hekili.ActiveDebug then Hekili:Debug( "Applied Reaver's Glaive." ) end
    end

    if talent.demonsurge.enabled and buff.metamorphosis.up then
        local metaRemains = buff.metamorphosis.remains

        for _, name in ipairs( demonsurge.demonic ) do
            if IsSpellOverlayed( class.abilities[ name ].id ) then
                applyBuff( "demonsurge_" .. name, metaRemains )
                demonsurgeLastSeen[ name ] = query_time
            end
        end
        if talent.demonic_intensity.enabled then
            local metaApplied = buff.metamorphosis.applied - 0.2
            if action.metamorphosis.lastCast >= metaApplied or action.abyssal_gaze.lastCast >= metaApplied then
                applyBuff( "demonsurge_hardcast", metaRemains )
            end
            for _, name in ipairs( demonsurge.hardcast ) do
                if IsSpellOverlayed( class.abilities[ name ].id ) then
                    applyBuff( "demonsurge_" .. name, metaRemains )
                    demonsurgeLastSeen[ name ] = query_time
                end
            end

            -- The Demonsurge buff does not actually get applied in-game until ~500ms after
            -- the empowered ability is cast. Pretend that it's applied instantly for any
            -- APL conditions that check `buff.demonsurge.stack`.

            local pending = 0

            for _, list in pairs( demonsurge ) do
                for _, name in ipairs( list ) do
                    local hasPending = buff[ "demonsurge_" .. name ].down and abs( action[ name ].lastCast - demonsurgeLastSeen[ name ] ) < 0.7 and action[ name ].lastCast > buff.demonsurge.applied
                    if hasPending then pending = pending + 1 end
                    --[[
                    if Hekili.ActiveDebug then
                        Hekili:Debug( " - " .. ( hasPending and "PASS: " or "FAIL: " ) ..
                            "buff.demonsurge_" .. name .. ".down[" .. ( buff[ "demonsurge_" .. name ].down and "true" or "false" ) .. "] & " ..
                            "@( action." .. name .. ".lastCast[" .. action[ name ].lastCast .. "] - lastSeen." .. name .. "[" .. demonsurgeLastSeen[ name ] .. "] ) < 0.7 & " ..
                            "action." .. name .. ".lastCast[" .. action[ name ].lastCast .. "] > buff.demonsurge.applied[" .. buff.demonsurge.applied .. "]" )
                    end
                    --]]
                end
            end
            if pending > 0 then
                addStack( "demonsurge", nil, pending )
            end
            if Hekili.ActiveDebug then
                Hekili:Debug( " - buff.demonsurge.stack[" .. buff.demonsurge.stack - pending .. " + " .. pending .. "]" )
            end
        end

        if Hekili.ActiveDebug then
            Hekili:Debug( "Demonsurge status:\n" ..
                " - Hardcast " .. ( buff.demonsurge_hardcast.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Demonic " .. ( buff.demonsurge_demonic.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Abyssal Gaze " .. ( buff.demonsurge_abyssal_gaze.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Annihilation " .. ( buff.demonsurge_annihilation.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Consuming Fire " .. ( buff.demonsurge_consuming_fire.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Death Sweep " .. ( buff.demonsurge_death_sweep.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Sigil of Doom " .. ( buff.demonsurge_sigil_of_doom.up and "ACTIVE" or "INACTIVE" ) )
        end
    end

    fury_spent = nil
end )

spec:RegisterHook( "runHandler", function( action )
    local ability = class.abilities[ action ]

    if ability.startsCombat and not debuff.initiative_tracker.up then
        applyBuff( "initiative" )
        applyDebuff( "target", "initiative_tracker" )
    end
end )

spec:RegisterHook( "spend", function( amt, resource )
    if set_bonus.tier30_2pc == 0 or amt < 0 or resource ~= "fury" then return end

    fury_spent = fury_spent + amt
    if fury_spent > 175 then
        fury_spent = fury_spent - 175
        applyBuff( "seething_fury" )
        if set_bonus.tier30_4pc > 0 then
            gain( 15, "fury" )
            applyBuff( "seething_potential" )
        end
    end
end )

spec:RegisterGear( "tier19", 138375, 138376, 138377, 138378, 138379, 138380 )
spec:RegisterGear( "tier20", 147130, 147132, 147128, 147127, 147129, 147131 )
spec:RegisterGear( "tier21", 152121, 152123, 152119, 152118, 152120, 152122 )
    spec:RegisterAura( "havoc_t21_4pc", {
        id = 252165,
        duration = 8
    } )

spec:RegisterGear( "class", 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722 )

spec:RegisterGear( "convergence_of_fates", 140806 )

spec:RegisterGear( "achor_the_eternal_hunger", 137014 )
spec:RegisterGear( "anger_of_the_halfgiants", 137038 )
spec:RegisterGear( "cinidaria_the_symbiote", 133976 )
spec:RegisterGear( "delusions_of_grandeur", 144279 )
spec:RegisterGear( "kiljaedens_burning_wish", 144259 )
spec:RegisterGear( "loramus_thalipedes_sacrifice", 137022 )
spec:RegisterGear( "moarg_bionic_stabilizers", 137090 )
spec:RegisterGear( "prydaz_xavarics_magnum_opus", 132444 )
spec:RegisterGear( "raddons_cascading_eyes", 137061 )
spec:RegisterGear( "sephuzs_secret", 132452 )
spec:RegisterGear( "the_sentinels_eternal_refuge", 146669 )

spec:RegisterGear( "soul_of_the_slayer", 151639 )
spec:RegisterGear( "chaos_theory", 151798 )
spec:RegisterGear( "oblivions_embrace", 151799 )


-- do
--     local wasWarned = false

--     spec:RegisterEvent( "PLAYER_REGEN_DISABLED", function ()
--         if state.talent.demon_blades.enabled and not state.settings.demon_blades_acknowledged and not wasWarned then
--             Hekili:Notify( "|cFFFF0000WARNING!|r  Fury from Demon Blades is forecasted very conservatively.\nSee /hekili > Havoc for more information." )
--             wasWarned = true
--         end
--     end )
-- end

local TriggerDemonic = setfenv( function( )
    local demonicExtension = 7

    if buff.metamorphosis.up then
        buff.metamorphosis.expires = buff.metamorphosis.expires + demonicExtension
        -- Fel-Scarred
        if talent.demonsurge.enabled then
            local metaExpires = buff.metamorphosis.expires

            for _, name in ipairs( demonsurge.demonic ) do
                local aura = buff[ "demonsurge_" .. name ]
                if aura.up then aura.expires = metaExpires end
            end

            if talent.demonic_intensity.enabled and buff.demonsurge_hardcast.up then
                buff.demonsurge_hardcast.expires = metaExpires

                for _, name in ipairs( demonsurge.hardcast ) do
                    local aura = buff[ "demonsurge_" .. name ]
                    if aura.up then aura.expires = metaExpires end
                end
            end
        end
    else
        applyBuff( "metamorphosis", demonicExtension )
        if talent.inner_demon.enabled then applyBuff( "inner_demon" ) end
        stat.haste = stat.haste + 20
        -- Fel-Scarred
        if talent.demonsurge.enabled then
            local metaRemains = buff.metamorphosis.remains

            for _, name in ipairs( demonsurge.demonic ) do
                applyBuff( "demonsurge_" .. name, metaRemains )
            end
        end
    end

end, state )

-- Abilities
spec:RegisterAbilities( {
    annihilation = {
        id = 201427,
        known = 162794,
        flash = { 201427, 162794 },
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        spend = 40,
        spendType = "fury",

        startsCombat = true,
        texture = 1303275,

        bind = "chaos_strike",
        buff = "metamorphosis",

        handler = function ()
            spec.abilities.chaos_strike.handler()
            -- Fel-Scarred
            if buff.demonsurge_annihilation.up then
                removeBuff( "demonsurge_annihilation" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
        end,
    },

    -- Strike $?a206416[your primary target for $<firstbloodDmg> Chaos damage and ][]all nearby enemies for $<baseDmg> Physical damage$?s320398[, and increase your chance to dodge by $193311s1% for $193311d.][. Deals reduced damage beyond $199552s1 targets.]
    blade_dance = {
        id = 188499,
        flash = { 188499, 210152 },
        cast = 0,
        cooldown = 10,
        hasteCD = true,
        gcd = "spell",
        school = "physical",

        spend = function() return 35 * ( buff.blade_rhapsody.up and 0.5 or 1 ) end,
        spendType = "fury",

        startsCombat = true,

        bind = "death_sweep",
        nobuff = "metamorphosis",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        handler = function ()
            -- Standard and Talents
            applyBuff( "blade_dance" )
            removeBuff( "restless_hunter" )
            setCooldown( "death_sweep", action.blade_dance.cooldown )
            if talent.chaos_theory.enabled then applyBuff( "chaos_theory" ) end
            if talent.deflecting_dance.enabled then applyBuff( "deflecting_dance" ) end
            if talent.screaming_brutality.enabled then spec.abilities.throw_glaive.handler() end
            if talent.mortal_dance.enabled then applyDebuff( "target", "mortal_dance" ) end

            -- TWW
            if set_bonus.tww1 >= 2 then removeBuff( "blade_rhapsody") end

            -- Hero Talents
            if buff.glaive_flurry.up then
                removeBuff( "glaive_flurry" )
                -- bugs: Thrill of the Fight doesn't apply without Fury of the Aldrachi and (maybe) Reaver's Mark.
                if talent.thrill_of_the_fight.enabled and talent.reavers_mark.enabled and buff.rending_strike.down then
                    applyBuff( "thrill_of_the_fight" )
                    applyBuff( "thrill_of_the_fight_damage" )
                end
            end
        end,

        copy = "blade_dance1"
    },

    -- Increases your chance to dodge by $212800s2% and reduces all damage taken by $212800s3% for $212800d.
    blur = {
        id = 198589,
        cast = 0,
        cooldown = function () return 60 + ( conduit.fel_defender.mod * 0.001 ) end,
        gcd = "off",
        school = "physical",

        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            applyBuff( "blur" )
        end,
    },

    -- Talent: Unleash an eruption of fel energy, dealing $s2 Chaos damage and stunning all nearby enemies for $d.$?s320412[    Each enemy stunned by Chaos Nova has a $s3% chance to generate a Lesser Soul Fragment.][]
    chaos_nova = {
        id = 179057,
        cast = 0,
        cooldown = 45,
        gcd = "spell",
        school = "chromatic",

        spend = 25,
        spendType = "fury",

        talent = "chaos_nova",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            applyDebuff( "target", "chaos_nova" )
        end,
    },

    -- Slice your target for ${$222031s1+$199547s1} Chaos damage. Chaos Strike has a ${$min($197125h,100)}% chance to refund $193840s1 Fury.
    chaos_strike = {
        id = 162794,
        flash = { 162794, 201427 },
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "chaos",

        spend = 40,
        spendType = "fury",

        startsCombat = true,

        bind = "annihilation",
        nobuff = "metamorphosis",

        cycle = function () return ( talent.burning_wound.enabled or legendary.burning_wound.enabled ) and "burning_wound" or nil end,

        handler = function ()
            removeBuff( "inner_demon" )
            if buff.chaos_theory.up then
                gain( 20, "fury" )
                removeBuff( "chaos_theory" )
            end

            -- Reaver
            if buff.rending_strike.up then
                removeBuff( "rending_strike" )
                -- Fun fact: Reaver's Mark's Blade Dance -> Chaos Strike -> 2 stacks doesn't work without Fury of the Aldrachi talented (note that Blade Dance doesn't light up as empowered in-game).
                local danced = talent.fury_of_the_aldrachi.enabled and buff.glaive_flurry.down
                applyDebuff( "target", "reavers_mark", nil, danced and 2 or 1 )

                if talent.thrill_of_the_fight.enabled and danced then
                    applyBuff( "thrill_of_the_fight" )
                    applyBuff( "thrill_of_the_fight_damage" )
                end
            end
            removeBuff( "warblades_hunger" )

            -- Legacy
            removeBuff( "chaotic_blades" )
        end,
    },

    -- Talent: Consume $m1 beneficial Magic effect removing it from the target$?s320313[ and granting you $s2 Fury][].
    consume_magic = {
        id = 278326,
        cast = 0,
        cooldown = 10,
        gcd = "spell",
        school = "chromatic",

        startsCombat = false,
        talent = "consume_magic",

        toggle = "interrupts",

        usable = function () return buff.dispellable_magic.up end,
        handler = function ()
            removeBuff( "dispellable_magic" )
            if talent.swallowed_anger.enabled then gain( 20, "fury" ) end
        end,
    },

    -- Summons darkness around you in a$?a357419[ 12 yd][n 8 yd] radius, granting friendly targets a $209426s2% chance to avoid all damage from an attack. Lasts $d.; Chance to avoid damage increased by $s3% when not in a raid.
    darkness = {
        id = 196718,
        cast = 0,
        cooldown = 300,
        gcd = "spell",
        school = "physical",

        talent = "darkness",
        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            applyBuff( "darkness" )
        end,
    },


    death_sweep = {
        id = 210152,
        known = 188499,
        flash = { 210152, 188499 },
        cast = 0,
        cooldown = 9,
        hasteCD = true,
        gcd = "spell",

        spend = function() return 35 * ( buff.blade_rhapsody.up and 0.5 or 1 ) end,
        spendType = "fury",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        startsCombat = true,
        texture = 1309099,

        bind = "blade_dance",
        buff = "metamorphosis",

        handler = function ()
            setCooldown( "blade_dance", action.death_sweep.cooldown )
            spec.abilities.blade_dance.handler()
            applyBuff( "death_sweep" )

            -- Fel-Scarred
            if buff.demonsurge_death_sweep.up then
                removeBuff( "demonsurge_death_sweep" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
        end,
    },

    -- Quickly attack for $s2 Physical damage.    |cFFFFFFFFGenerates $?a258876[${$m3+$258876s3} to ${$M3+$258876s4}][$m3 to $M3] Fury.|r
    demons_bite = {
        id = 162243,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        spend = function () return talent.insatiable_hunger.enabled and -25 or -20 end,
        spendType = "fury",

        startsCombat = true,

        notalent = "demon_blades",
        cycle = function () return ( talent.burning_wound.enabled or legendary.burning_wound.enabled ) and "burning_wound" or nil end,

        handler = function ()
            if talent.burning_wound.enabled then applyDebuff( "target", "burning_wound" ) end
        end,
    },

    -- Interrupts the enemy's spellcasting and locks them from that school of magic for $d.|cFFFFFFFF$?s183782[    Generates $218903s1 Fury on a successful interrupt.][]|r
    disrupt = {
        id = 183752,
        cast = 0,
        cooldown = 15,
        gcd = "off",
        school = "chromatic",

        startsCombat = true,

        toggle = "interrupts",
        target = function () 
            if not UnitExists("focus") then
                return debuff.casting_target.caster
            else
                return debuff.casting_focus.caster
            end
        end,
        usable = function () return state.readyToInterrupt() and target.distance <= 10, "readyToInterrupt" end,

        handler = function ()
            interrupt()
            if talent.disrupting_fury.enabled then gain( 30, "fury" ) end
        end,
    },

    -- Talent: Slash all enemies in front of you for $s1 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by $320338s1% for $320338d. Deals reduced damage beyond $s2 targets.
    essence_break = {
        id = 258860,
        cast = 0,
        cooldown = 40,
        gcd = "spell",
        school = "chromatic",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        talent = "essence_break",
        startsCombat = true,
        toggle = "essences",
        handler = function ()
            applyDebuff( "target", "essence_break" )
            active_dot.essence_break = max( 1, active_enemies )
        end,

        copy = "dark_slash"
    },

    -- Blasts all enemies in front of you,$?s320415[ dealing guaranteed critical strikes][] for up to $<dmg> Chaos damage over $d. Deals reduced damage beyond $s5 targets.$?s343311[; When Eye Beam finishes fully channeling, your Haste is increased by an additional $343312s1% for $343312d.][]
    eye_beam = {
        id = 198013,
        cast = function () return ( talent.blind_fury.enabled and 3 or 2 ) * haste end,
        channeled = true,
        cooldown = 40,
        gcd = "spell",
        school = "chromatic",
        toggle = "essences",
        spend = 30,
        spendType = "fury",
        usable = function () return target.distance <= 5, "target must be nearby" end,
        talent = "eye_beam",
        startsCombat = true,
        nobuff = function () return talent.demonic_intensity.enabled and "metamorphosis" or nil end,

        start = function()
            applyBuff( "eye_beam" )
            if talent.demonic.enabled then TriggerDemonic() end
            if talent.cycle_of_hatred.enabled then
                reduceCooldown( "eye_beam", 5 * talent.cycle_of_hatred.rank * buff.cycle_of_hatred.stack )
                addStack( "cycle_of_hatred" )
            end
            removeBuff( "seething_potential" )
            setCooldown( "abyssal_gaze", action.eye_beam.cooldown )
        end,

        finish = function()
            if talent.furious_gaze.enabled then applyBuff( "furious_gaze" ) end
        end,

        bind = "abyssal_gaze"
    },

    abyssal_gaze = {
        id = 452497,
        known = 198013,
        cast = function () return ( talent.blind_fury.enabled and 3 or 2 ) * haste end,
        channeled = true,
        cooldown = 40,
        gcd = "spell",
        school = "chromatic",
        usable = function () return target.distance <= 10, "target must be nearby" end,
        spend = 30,
        spendType = "fury",

        talent = "demonic_intensity",
        buff = "demonsurge_hardcast",
        startsCombat = true,

        start = function()
            applyBuff( "eye_beam" )
            if talent.demonic.enabled then TriggerDemonic() end
            if talent.cycle_of_hatred.enabled then
                reduceCooldown( "abyssal_gaze", 5 * talent.cycle_of_hatred.rank * buff.cycle_of_hatred.stack )
                addStack( "cycle_of_hatred" )
            end
            if buff.demonsurge_abyssal_gaze.up then
                removeBuff( "demonsurge_abyssal_gaze" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            removeBuff( "seething_potential" )
            setCooldown( "eye_beam", action.abyssal_gaze.cooldown )
        end,

        finish = function() spec.abilities.eye_beam.finish() end,

        bind = "eye_beam"
    },

    -- Talent: Unleash a torrent of Fel energy over $d, inflicting ${(($d/$t1)+1)*$258926s1} Chaos damage to all enemies within $258926A1 yds. Deals reduced damage beyond $258926s2 targets.
    fel_barrage = {
        id = 258925,
        cast = 3,
        channeled = true,
        cooldown = 90,
        gcd = "spell",
        school = "chromatic",

        spend = 10,
        spendType = "fury",

        talent = "fel_barrage",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "fel_barrage" )
        end,
    },

    -- Impales the target for $s1 Chaos damage and stuns them for $d.
    fel_eruption = {
        id = 211881,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "chromatic",

        spend = 10,
        spendType = "fury",

        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "fel_eruption" )
        end,
    },


    fel_lance = {
        id = 206966,
        cast = 1,
        cooldown = 0,
        gcd = "spell",

        pvptalent = "rain_from_above",
        buff = "rain_from_above",

        startsCombat = true,
    },

    -- Rush forward, incinerating anything in your path for $192611s1 Chaos damage.
    fel_rush = {
        id = 195072,
        cast = 0,
        charges = function() return talent.blazing_path.enabled and 2 or nil end,
        cooldown = function () return ( legendary.erratic_fel_core.enabled and 7 or 10 ) * ( 1 - 0.1 * talent.erratic_felheart.rank ) end,
        recharge = function () return talent.blazing_path.enabled and ( ( legendary.erratic_fel_core.enabled and 7 or 10 ) * ( 1 - 0.1 * talent.erratic_felheart.rank ) ) or nil end,
        gcd = "off",
        icd = 0.5,
        school = "physical",

        startsCombat = true,
        nodebuff = "rooted",

        readyTime = function ()
            if prev[1].fel_rush then return 3600 end
            if ( settings.fel_rush_charges or 1 ) == 0 then return end
            return ( ( 1 + ( settings.fel_rush_charges or 1 ) ) - cooldown.fel_rush.charges_fractional ) * cooldown.fel_rush.recharge
        end,

        handler = function ()
            setDistance( 5 )
            setCooldown( "global_cooldown", 0.25 )

            if buff.unbound_chaos.up then removeBuff( "unbound_chaos" ) end
            if buff.inertia_trigger.up then
                removeBuff( "inertia_trigger" )
                applyBuff( "inertia" )
            end
            if conduit.felfire_haste.enabled then applyBuff( "felfire_haste" ) end
        end,
    },

    -- Talent: Charge to your target and deal $213243sw2 $@spelldesc395020 damage.    $?s203513[Shear has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r]
    felblade = {
        id = 232893,
        cast = 0,
        cooldown = 15,
        hasteCD = true,
        gcd = "spell",
        school = "physical",
        usable = function () return target.distance <= 15, "target must be nearby" end,
        spend = -40,
        spendType = "fury",

        talent = "felblade",
        startsCombat = true,
        nodebuff = "rooted",

        handler = function ()
            setDistance( 5 )
            if buff.unbound_chaos.up then removeBuff( "unbound_chaos" ) end
            if buff.inertia_trigger.up then
                removeBuff( "inertia_trigger" )
                applyBuff( "inertia" )
            end
            if talent.warblades_hunger.enabled then
                if buff.art_of_the_glaive.stack + soul_fragments >= 6 then
                    applyBuff( "reavers_glaive" )
                else
                    addStack( "art_of_the_glaive", soul_fragments )
                end
                addStack( "warblades_hunger", soul_fragments )
            end
        end,
    },

    -- Talent: Launch two demonic glaives in a whirlwind of energy, causing ${14*$342857s1} Chaos damage over $d to all nearby enemies. Deals reduced damage beyond $s2 targets.
    glaive_tempest = {
        id = 342817,
        cast = 0,
        cooldown = 25,
        gcd = "spell",
        school = "magic",

        spend = 30,
        spendType = "fury",

        talent = "glaive_tempest",
        startsCombat = true,

        handler = function ()
        end,
    },

    -- Engulf yourself in flames, $?a320364 [instantly causing $258921s1 $@spelldesc395020 damage to enemies within $258921A1 yards and ][]radiating ${$258922s1*$d} $@spelldesc395020 damage over $d.$?s320374[    |cFFFFFFFFGenerates $<havocTalentFury> Fury over $d.|r][]$?(s212612 & !s320374)[    |cFFFFFFFFGenerates $<havocFury> Fury.|r][]$?s212613[    |cFFFFFFFFGenerates $<vengeFury> Fury over $d.|r][]
    immolation_aura = {
        id = function() return buff.demonsurge_hardcast.up and 452487 or 258920 end,
        known = 258920,
        cast = 0,
        cooldown = 30,
        hasteCD = true,
        charges = function()
            if talent.a_fire_inside.enabled then return 2 end
        end,
        recharge = function()
            if talent.a_fire_inside.enabled then return 30 * haste end
        end,
        gcd = "spell",
        school = function() return talent.a_fire_inside.enabled and "chaos" or "fire" end,
        texture = function() return buff.demonsurge_hardcast.up and 135794 or 1344649 end,

        spend = -20,
        spendType = "fury",
        startsCombat = false,

        handler = function ()
            applyBuff( "immolation_aura" )
            if talent.ragefire.enabled then applyBuff( "ragefire" ) end

            if buff.demonsurge_consuming_fire.up then
                removeBuff( "demonsurge_consuming_fire" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
        end,

        copy = { 258920, 427917, "consuming_fire", 452487 }
    },

    -- Talent: Imprisons a demon, beast, or humanoid, incapacitating them for $d. Damage will cancel the effect. Limit 1.
    imprison = {
        id = 217832,
        cast = 0,
        gcd = "spell",
        school = "shadow",

        talent = "imprison",
        startsCombat = false,

        handler = function ()
            applyDebuff( "target", "imprison" )
        end,
    },

    -- Leap into the air and land with explosive force, dealing $200166s2 Chaos damage to enemies within 8 yds, and stunning them for $200166d. Players are Dazed for $247121d instead.    Upon landing, you are transformed into a hellish demon for $162264d, $?s320645[immediately resetting the cooldown of your Eye Beam and Blade Dance abilities, ][]greatly empowering your Chaos Strike and Blade Dance abilities and gaining $162264s4% Haste$?(s235893&s204909)[, $162264s5% Versatility, and $162264s3% Leech]?(s235893&!s204909[ and $162264s5% Versatility]?(s204909&!s235893)[ and $162264s3% Leech][].
    metamorphosis = {
        id = 191427,
        cast = 0,
        cooldown = function () return ( 180 - ( 30 * talent.rush_of_chaos.rank ) )  end,
        gcd = "spell",
        school = "physical",

        startsCombat = true,
        terrain = true,
        toggle = "cooldowns",
        toggle_terrain = "player",
        handler = function ()
            applyBuff( "metamorphosis", buff.metamorphosis.remains + 20 )
            setDistance( 5 )
            stat.haste = stat.haste + 20

            if talent.chaotic_transformation.enabled then
                setCooldown( "eye_beam", 0 )
                setCooldown( "abyssal_gaze", 0 )
                setCooldown( "blade_dance", 0 )
                setCooldown( "death_sweep", 0 )
            end

            if talent.demonsurge.enabled then
                local metaRemains = buff.metamorphosis.remains

                for _, name in ipairs( demonsurge.demonic ) do
                    applyBuff( "demonsurge_ " .. name, metaRemains )
                end

                if talent.violent_transformation.enabled then
                    setCooldown( "sigil_of_flame", 0 )
                    gainCharges( "immolation_aura", 1 )
                    if talent.demonic_intensity.enabled then
                        gainCharges( "consuming_fire", 1 )
                        setCooldown( "sigil_of_doom", 0 )
                    end
                end

                if talent.demonic_intensity.enabled then
                    removeBuff( "demonsurge" )
                    applyBuff( "demonsurge_hardcast", metaRemains )

                    for _, name in ipairs( demonsurge.hardcast ) do
                        applyBuff( "demonsurge_ " .. name, metaRemains )
                    end
                end
            end

            -- Legacy
            if covenant.venthyr then
                applyDebuff( "target", "sinful_brand" )
                active_dot.sinful_brand = active_enemies
            end
        end,

        -- We need to alias to spell ID 200166 to catch SPELL_CAST_SUCCESS for Metamorphosis.
        copy = 200166
    },

    -- Talent: Slip into the nether, increasing movement speed by $s3% and becoming immune to damage, but unable to attack. Lasts $d.
    netherwalk = {
        id = 196555,
        cast = 0,
        cooldown = 180,
        gcd = "spell",
        school = "physical",

        talent = "netherwalk",
        startsCombat = false,

        toggle = "interrupts",

        handler = function ()
            applyBuff( "netherwalk" )
            setCooldown( "global_cooldown", buff.netherwalk.remains )
        end,
    },


    rain_from_above = {
        id = 206803,
        cast = 0,
        cooldown = 60,
        gcd = "spell",

        pvptalent = "rain_from_above",

        startsCombat = false,
        texture = 1380371,

        handler = function ()
            applyBuff( "rain_from_above" )
        end,
    },


    reverse_magic = {
        id = 205604,
        cast = 0,
        cooldown = 60,
        gcd = "spell",

        -- toggle = "cooldowns",
        pvptalent = "reverse_magic",

        startsCombat = false,
        texture = 1380372,

        debuff = "reversible_magic",

        handler = function ()
            if debuff.reversible_magic.up then removeDebuff( "player", "reversible_magic" ) end
        end,
    },


    -- Talent: Place a Sigil of Flame at your location that activates after $d.    Deals $204598s1 Fire damage, and an additional $204598o3 Fire damage over $204598d, to all enemies affected by the sigil.    |CFFffffffGenerates $389787s1 Fury.|R
    sigil_of_flame = {
        id = function() return talent.precise_sigils.enabled and 389810 or 204596 end,
        known = 204596,
        cast = 0,
        cooldown = function() return ( pvptalent.sigil_of_mastery.enabled and 0.75 or 1 ) * 30 end,
        gcd = "spell",
        school = "fire",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        toggle_terrain = "player",
        spend = -30,
        spendType = "fury",

        startsCombat = false,
        texture = 1344652,
        nobuff = "demonsurge_hardcast",

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_flame.lastCast + activation_time end,
        terrain = true,
        impact = function()
            applyDebuff( "target", "sigil_of_flame" )
            active_dot.sigil_of_flame = active_enemies
            if talent.soul_sigils.enabled then addStack( "soul_fragments", nil, 1 ) end
            if talent.student_of_suffering.enabled then applyBuff( "student_of_suffering" ) end
            if talent.flames_of_fury.enabled then gain( talent.flames_of_fury.rank * active_enemies, "fury" ) end
        end,

        copy = { 204596, 389810 },
        bind = "sigil_of_doom"
    },

    sigil_of_doom = {
        id = function () return talent.precise_sigils.enabled and 469991 or 452490 end,
        known = 204596,
        cast = 0,
        cooldown = function() return ( pvptalent.sigil_of_mastery.enabled and 0.75 or 1 ) * 30 end,
        gcd = "spell",
        school = "chaos",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        toggle_terrain = "player",
        spend = -30,
        spendType = "fury",

        talent = "demonic_intensity",
        buff = "demonsurge_hardcast",
        terrain = true,
        startsCombat = false,
        texture = 1121022,

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_doom.lastCast + activation_time end,

        handler = function ()
            if buff.demonsurge_sigil_of_doom.up then
                removeBuff( "demonsurge_sigil_of_doom" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            -- Sigil of Doom and Sigil of Flame share a cooldown.
            setCooldown( "sigil_of_flame", action.sigil_of_doom.cooldown )
        end,

        impact = function()
            applyDebuff( "target", "sigil_of_doom" )
            active_dot.sigil_of_doom = active_enemies
            if talent.soul_sigils.enabled then addStack( "soul_fragments", nil, 1 ) end
            if talent.student_of_suffering.enabled then applyBuff( "student_of_suffering" ) end
            if talent.flames_of_fury.enabled then gain( talent.flames_of_fury.rank * active_enemies, "fury" ) end
        end,

        copy = { 452490, 469991 },
        bind = "sigil_of_flame"
    },

    -- Talent: Place a Sigil of Misery at your location that activates after $d.    Causes all enemies affected by the sigil to cower in fear. Targets are disoriented for $207685d.
    sigil_of_misery = {
        id = function () return talent.precise_sigils.enabled and 389813 or 207684 end,
        known = 207684,
        cast = 0,
        cooldown = function () return 120 * ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) end,
        gcd = "spell",
        school = "physical",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        toggle_terrain = "player",
        talent = "sigil_of_misery",
        startsCombat = false,

        toggle = "interrupts",

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_misery.lastCast + activation_time end,

        impact = function()
            applyDebuff( "target", "sigil_of_misery_debuff" )
        end,

        copy = { 207684, 389813 }
    },

    -- Place a demonic sigil at the target location that activates after $d.; Detonates to deal $389860s1 Chaos damage and shatter up to $s3 Lesser Soul Fragments from
    sigil_of_spite = {
        id = function () return talent.precise_sigils.enabled and 389815 or 390163 end,
        known = 390163,
        cast = 0.0,
        cooldown = function() return 60 * ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) end,
        gcd = "spell",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        toggle_terrain = "player",
        talent = "sigil_of_spite",
        startsCombat = true,
        toggle = "cooldowns",
        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_spite.lastCast + activation_time end,
        terrain = true,
        impact = function ()
            addStack( "soul_fragments", nil, talent.soul_sigils.enabled and 4 or 3 )
        end,

        copy = { 389815, 390163 }
    },

    -- Allows you to see enemies and treasures through physical barriers, as well as enemies that are stealthed and invisible. Lasts $d.    Attacking or taking damage disrupts the sight.
    spectral_sight = {
        id = 188501,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        handler = function ()
            applyBuff( "spectral_sight" )
        end,
    },

    -- Talent / Covenant (Night Fae): Charge to your target, striking them for $370966s1 $@spelldesc395042 damage, rooting them in place for $370970d and inflicting $370969o1 $@spelldesc395042 damage over $370969d to up to $370967s2 enemies in your path.     The pursuit invigorates your soul, healing you for $?c1[$370968s1%][$370968s2%] of the damage you deal to your Hunt target for $370966d.
    the_hunt = {
        id = function() return talent.the_hunt.enabled and 370965 or 323639 end,
        cast = 1,
        cooldown = function() return talent.the_hunt.enabled and 90 or 180 end,
        gcd = "spell",
        school = "nature",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        startsCombat = true,
        toggle = "cooldowns",
        nodebuff = "rooted",

        handler = function ()
            applyDebuff( "target", "the_hunt" )
            applyDebuff( "target", "the_hunt_dot" )
            setDistance( 5 )

            if talent.exergy.enabled then
                applyBuff( "exergy", min( 30, buff.exergy.remains + 20 ) )
            elseif talent.inertia.enabled then -- talent choice node, only 1 or the other
                applyBuff( "inertia_trigger" )
            end
            if talent.unbound_chaos.enabled then applyBuff( "unbound_chaos" ) end

            -- Hero Talents
            if talent.art_of_the_glaive.enabled then applyBuff( "reavers_glaive" ) end

            -- Legacy
            if legendary.blazing_slaughter.enabled then
                applyBuff( "immolation_aura" )
                applyBuff( "blazing_slaughter" )
            end
        end,

        copy = { 370965, 323639 }
    },

    -- Throw a demonic glaive at the target, dealing $337819s1 Physical damage. The glaive can ricochet to $?$s320386[${$337819x1-1} additional enemies][an additional enemy] within 10 yards.
    throw_glaive = {
        id = 185123,
        known = 185123,
        cast = 0,
        charges = function () return talent.champion_of_the_glaive.enabled and 2 or nil end,
        cooldown = 9,
        recharge = function () return talent.champion_of_the_glaive.enabled and 9 or nil end,
        gcd = "spell",
        school = "physical",

        spend = function() return talent.furious_throws.enabled and 25 or 0 end,
        spendType = "fury",

        startsCombat = true,
        nobuff = "reavers_glaive",

        readyTime = function ()
            if ( settings.throw_glaive_charges or 1 ) == 0 then return end
            return ( ( 1 + ( settings.throw_glaive_charges or 1 ) ) - cooldown.throw_glaive.charges_fractional ) * cooldown.throw_glaive.recharge
        end,

        handler = function ()
            if talent.burning_wound.enabled then applyDebuff( "target", "burning_wound" ) end
            if talent.champion_of_the_glaive.enabled then applyDebuff( "target", "master_of_the_glaive" ) end
            if talent.serrated_glaive.enabled then applyDebuff( "target", "serrated_glaive" ) end
            if talent.soulscar.enabled then applyDebuff( "target", "soulscar" ) end
            if set_bonus.tier31_4pc > 0 then reduceCooldown( "the_hunt", 2 ) end
        end,

        bind = "reavers_glaive"
    },

    reavers_glaive = {
        id = 442294,
        cast = 0,
        charges = function () return talent.champion_of_the_glaive.enabled and 2 or nil end,
        cooldown = 9,
        recharge = function () return talent.champion_of_the_glaive.enabled and 9 or nil end,
        gcd = "spell",
        school = "physical",
        known = 442290,

        spend = function() return talent.keen_engagement.enabled and -20 or nil end,
        spendType = function() return talent.keen_engagement.enabled and "fury" or nil end,

        startsCombat = true,
        buff = "reavers_glaive",

        handler = function ()
            removeBuff( "reavers_glaive" )
            if talent.master_of_the_glaive.enabled then applyDebuff( "target", "master_of_the_glaive" ) end
            applyBuff( "rending_strike" )
            applyBuff( "glaive_flurry" )
        end,

        bind = "throw_glaive"
    },

    -- Taunts the target to attack you.
    torment = {
        id = 185245,
        cast = 0,
        cooldown = 8,
        gcd = "off",
        school = "shadow",

        startsCombat = false,

        handler = function ()
            applyBuff( "torment" )
        end,
    },

    -- Talent: Remove all snares and vault away. Nearby enemies take $198813s2 Physical damage$?s320635[ and have their movement speed reduced by $198813s1% for $198813d][].$?a203551[    |cFFFFFFFFGenerates ${($203650s1/5)*$203650d} Fury over $203650d if you damage an enemy.|r][]
    vengeful_retreat = {
        id = 198793,
        cast = 0,
        cooldown = function () return talent.tactical_retreat.enabled and 20 or 25 end,
        gcd = "off",

        startsCombat = true,
        nodebuff = "rooted",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        readyTime = function ()
            if settings.retreat_and_return == "fel_rush" or settings.retreat_and_return == "either" and not talent.felblade.enabled then
                return max( 0, cooldown.fel_rush.remains - 1 )
            end
            if settings.retreat_and_return == "felblade" and talent.felblade.enabled then
                return max( 0, cooldown.felblade.remains - 0.4 )
            end
            if settings.retreat_and_return == "either" then
                return max( 0, min( cooldown.felblade.remains, cooldown.fel_rush.remains ) - 1 )
            end
        end,

        handler = function ()

            -- Standard effects/Talents
            applyBuff( "vengeful_retreat_movement" )
            if cooldown.fel_rush.remains < 1 then setCooldown( "fel_rush", 1 ) end
            if talent.vengeful_bonds.enabled then
                applyDebuff( "target", "vengeful_retreat" )
                applyDebuff( "target", "vengeful_retreat_snare" )
            end

            if talent.tactical_retreat.enabled then applyBuff( "tactical_retreat" ) end
            if talent.exergy.enabled then
                applyBuff( "exergy", min( 30, buff.exergy.remains + 20 ) )
            elseif talent.inertia.enabled then -- talent choice node, only 1 or the other
                applyBuff( "inertia_trigger" )
            end
            if talent.unbound_chaos.enabled then applyBuff( "unbound_chaos" ) end

            -- Hero Talents
            if talent.unhindered_assault.enabled then setCooldown( "felblade", 0 ) end
            if talent.evasive_action.enabled then
                if buff.evasive_action.down then applyBuff( "evasive_action" )
                else
                    removeBuff( "evasive_action" )
                    setCooldown( "vengeful_retreat", 0 )
                end
            end

            -- PvP
            if pvptalent.glimpse.enabled then applyBuff( "glimpse" ) end
        end,
    }
} )

spec:RegisterRanges( "disrupt", "felblade", "fel_eruption", "torment", "throw_glaive", "the_hunt" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = true,
    nameplateRange = 10,
    rangeFilter = false,

    damage = true,
    damageExpiration = 8,

    potion = "tempered_potion",

    package = "浩劫Simc",
} )

spec:RegisterSetting( "demon_blades_text", nil, {
    name = function()
        return strformat( "|cFFFF0000警告！|r  如果使用 %s 天赋，来自自动攻击的怒气将被保守地预测，并只在实际获得时更新。"
            .. "这样预测可能会导致怒气消耗突然出现，因此不能保证在下一次近战攻击有足够的怒气。"
            .. "", Hekili:GetSpellLinkWithTexture( 203555 ) )
    end,
    type = "description",
    width = "full"
} )

spec:RegisterSetting( "demon_blades_acknowledged", false, {
    name = function()
        return strformat( "我明白来自 %s 的怒气是不可预测的。", Hekili:GetSpellLinkWithTexture( 203555 ) )
    end,
    desc = function()
        return strformat( "如果勾选，在战斗时 %s 将不会触发警告。", Hekili:GetSpellLinkWithTexture( 203555 ) )
    end,
    type = "toggle",
    width = "full",
    arg = function() return false end,
} )

-- Fel Rush
spec:RegisterSetting( "fel_rush_head", nil, {
    name = Hekili:GetSpellLinkWithTexture( 195072, 20 ),
    type = "header"
} )

spec:RegisterSetting( "fel_rush_warning", nil, {
    name = strformat( "当 %s, %s, 或者 %s 天赋需要使用 %s。如果不希望|W%s|w 被推荐来触发这些天赋的收益，你可能需要考虑使用其他的天赋。"
        .. "\n\n"
        .. "你可以保留|W%s|w的资源，以确保总是留给你可使用的资源，但如果不使用|W%s|w，最终可能会导致损失DPS。"
        .. "", Hekili:GetSpellLinkWithTexture( 388113 ), Hekili:GetSpellLinkWithTexture( 206476 ), Hekili:GetSpellLinkWithTexture( 347461 ),
        Hekili:GetSpellLinkWithTexture( 195072 ), spec.abilities.fel_rush.name, spec.abilities.fel_rush.name, spec.abilities.fel_rush.name ),
    type = "description",
    width = "full",
} )

spec:RegisterSetting( "fel_rush_charges", 0, {
    name = strformat( "储存 %s 资源", Hekili:GetSpellLinkWithTexture( 195072 ) ),
    desc = strformat( "如果设置大于0，当使用 %s 将使你剩余很少的资源，它将不会被推荐。", Hekili:GetSpellLinkWithTexture( 195072 ) ),
    type = "range",
    min = 0,
    max = 2,
    step = 0.1,
    width = "full"
} )

-- Throw Glaive
spec:RegisterSetting( "throw_glaive_head", nil, {
    name = Hekili:GetSpellLinkWithTexture( 185123, 20 ),
    type = "header"
} )

spec:RegisterSetting("throw_glaive_charges_text", nil, {
    name = strformat(
        "你可以预留 %s 的充能，以确保它在需要时始终可用。" ..
        "如果设置为你的最大充能数（当你点出 %s 或 %s 时为2，否则为1），|W%s|w 将永远不会被推荐使用。" ..
        "在适当的时机未能使用 |W%s|w 可能会影响你的 DPS。",
        Hekili:GetSpellLinkWithTexture(185123),
        Hekili:GetSpellLinkWithTexture(389763),
        Hekili:GetSpellLinkWithTexture(429211),
        spec.abilities.throw_glaive.name,
        spec.abilities.throw_glaive.name
    ),
    type = "description",
    width = "full",
})

spec:RegisterSetting( "throw_glaive_charges", 0, {
    name = strformat( "保留 %s 的充能数", Hekili:GetSpellLinkWithTexture( 185123 ) ),
    desc = strformat( "若该值大于0，当使用 %s 会导致你剩余（含部分）充能低于该值时，将不会推荐使用它。", Hekili:GetSpellLinkWithTexture( 185123 ) ),
    type = "range",
    min = 0,
    max = 2,
    step = 0.1,
    width = "full"
} )


-- Vengeful Retreat
spec:RegisterSetting( "retreat_head", nil, {
    name = Hekili:GetSpellLinkWithTexture( 198793, 20 ),
    type = "header"
} )

spec:RegisterSetting( "retreat_warning", nil, {
    name = strformat( "当 %s, %s, 或者 %s 天赋需要使用 %s。如果不希望|W%s|w 被推荐来触发这些天赋的收益，你可能需要考虑使用其他的天赋。"
        .. "", Hekili:GetSpellLinkWithTexture( 388108 ),Hekili:GetSpellLinkWithTexture( 206476 ),
        Hekili:GetSpellLinkWithTexture( 389688 ), Hekili:GetSpellLinkWithTexture( 198793 ), spec.abilities.vengeful_retreat.name ),
    type = "description",
    width = "full",
} )

spec:RegisterSetting( "retreat_and_return", "off", {
    name = strformat( "%s: %s 和 %s", Hekili:GetSpellLinkWithTexture( 198793 ), Hekili:GetSpellLinkWithTexture( 195072 ), Hekili:GetSpellLinkWithTexture( 232893 ) ),
    desc = function()
        return strformat( "启用后，除非使用 %s 或 %s 能够快速返回你当前的目标，否则 %s 将|cFFFF0000不会|r 被推荐。"
            .. "适用于所有|W%s|w 和 |W%s|w 的推荐，无论天赋如何。\n\n"
            .. "如果|W%s|w 没有天赋支撑，将忽略它的冷却时间。\n\n"
            .. "该选项并不保证|W%s|w 和 |W%s|w 会在|W%s|w 后被首先推荐，但会确保其中之一立即可用。",
            Hekili:GetSpellLinkWithTexture( 198793 ), Hekili:GetSpellLinkWithTexture( 195072 ), Hekili:GetSpellLinkWithTexture( 232893 ),
            spec.abilities.fel_rush.name, spec.abilities.vengeful_retreat.name, spec.abilities.felblade.name,
            spec.abilities.fel_rush.name, spec.abilities.felblade.name, spec.abilities.vengeful_retreat.name )
    end,
    type = "select",
    values = {
        off = "禁用（默认）",
        fel_rush = "需要 " .. Hekili:GetSpellLinkWithTexture( 195072 ),
        felblade = "需要 " .. Hekili:GetSpellLinkWithTexture( 232893 ),
        either = "其中之一 " .. Hekili:GetSpellLinkWithTexture( 195072 ) .. " 或 " .. Hekili:GetSpellLinkWithTexture( 232893 )
    },
    width = "full"
} )

spec:RegisterSetting( "retreat_filler", false, {
    name = strformat( "%s：填充和移动", Hekili:GetSpellLinkWithTexture( 198793 ) ),
    desc = function()
        return strformat( "启用后，%s 可被推荐为填充技能或用于运动战。\n\n"
            .. "这种推荐可能发生在有天赋支撑时，其他技能处于冷却，或你在攻击范围之外时。",
            Hekili:GetSpellLinkWithTexture( 198793 ), Hekili:GetSpellLinkWithTexture( 203555 ) )
    end,
    type = "toggle",
    width = "full"
} )


spec:RegisterPack( "浩劫Simc", 20250730, [[Hekili:S316VrYXX9)w4h8E7sIB1UdjVtk4idItqaS(G(qOZx5YH7oKCc3DNvZm7DIchwiLa7il)iVKHbsmcIcGnusKDmSrIvSLI(JXhPo)j9Vq6EE2pQh9mC5D8IoabrEC6P7QRUQQR6xvDpho8WV5HhmXpn4W3WBG3UdE1b70FWUEBV7UhEq6flco8Gf(Jp3)uXVm3FM4)F1)1)2LV))XbHZglF0ftJ8Ni7IKOLXJfp(WdoEz400VX8dpgQF9g8AI2Uiy8HVXU3)(hEWzHtMeK32GerpoCyFVvV(Qx)Y3)dV8Z)wFXp9D)Ip4JU8V9h80F9V6jFYp4YV9V83)bF3V8tF3RZtp8GPHjPjsA(KKrJJIMoj6rZf)Z3iJvem3)4Pbto8RF4bJJdtdId9p8GURos8FLTTFWfbJooWFw)4Gz(HZtwD0(7T6iVbRoQtwd3y1rP(tdMN2pijjy(yrRJd8pVFrFV6Oh)4vhnj44LNCIrlwUy1r9Y6MShEsW0rh7hhly)9LJC5ae7hozuWdLJG)Kjj9dfpz)vhTZG8UgOf1u6QJE18wvtLQdtfnMtg(JtdFyWOG5bZcdYFDVSNP3dJpZpknC8O0y)5jNefpZpnmAU(e(4OKKS(8KWtplDuff9GvhT9aTPD485bXJMemt0fQt76XloijDQG1n6SLZfRr1duhLLPJN6pjy0eFb7vB(F64j9N5)wRoAtXiNtBlIdE4i5FFy)jb(PNnk5rbb5Rf50v9qhkOT0qFTHKDbpN(pliosWIcc67pDsS)4ZcfCb)hgexWGKZ9SzDYY4tfuEnLuWg6v2tp0xixk66(rlelnfm40WzbztWH7kA6Hhix7IMF4bZcs9NffV4SOKWKdtfkKuc60SV8HpJs162mj3oK6iRdDJSPz(RNCMFQGQdMi4tjPHZVqVlQ51cP7KXcP7AH6VIQB196REXRRunuyQlklHisa9CuFPRlQmDqLwRu50FKkVRYsHoduza9Npp8SWP5ljvkPRj90Tr1tPwV3fDQvoRruVQPKfrz)uqc7yqcrIwLeKw30YzO83MUu8JG3Cz4Ifbsg3KrV5YGG5jJM5px6kq(Ox1aXkRynvSgVmjx4EwOuJ2OvjN7hp5crNCQqcWSlscpDEq6OOtgLEwWOfXHrXxy0K)ILZpFMVqGoosqibN6lOg5lz0Std8JpnoC(KG4Krjl8JdgDEWfjgTAMW1bHUZ0OXNpprifFUXZJfsNZLZNZIMhCXOJx(2VDqCgtAuU3tsxFc9NkMVHZpxWhfS4DnyXvIdw8pBxsu3wkuOMjnOyyzixJV6Hvwrlfc31u6grDiVPiswgBpvm76NoSV4HqccgTZRF1ghtwgNPnLjmpSWQludvPSY2THwtpZpz0YeHaUGGRmSQ8C3OTHUsBdDN2gAtB9G0NLVU3awB8dhG8aQf08be0wq(YPCqT7YDldeaq(uinFpePzeLDvr6nuv04mE40ch(cm3IMX82zbhobvJ(Thixw6iqfBgJXj413hHxRBY0WQHlCzi6bIjyAB(AYyhY1NUXuXukD2YIvd7H7hr5YKbpxS68QyRoa7zPUgLBz(bWbuc6ovHn(8NuecPQdsmEQd6LnH1gVkos1MiEdQ4dqZob341q4gyBpR5TJ1EyLJg6BlgXHdqgsKT6DBeXEz5aAcGqTTVmzSHncsbv3pHdwyiPJE9ycOHwd5U5ENk7FMWD6XV7gN80UQrzZzmWQniwITAhQ7Mv6yvERB4LMB(GKPwiuaMgLQSKlLlmJ32qUW72PCbObXRLCHPhzTsUaBJhR24GCH3AvUazhpi5cVm5c847i8klNQkw2NejdwxgsSCsgFE2awSZwrFO(4kR7QH6R8yJqW1E)tN6lTeQseRRWfwNrXO(xy38SCoUC(XrlNpzKeQLefVFv3yvUOF6PbXMeVlG6Hm7jL)3tcDJITcXUPs0yYeCmJk3vbhxW2Rrqwi2TpCQCZ(KfHz()NkrvhcmDj8(XHlYFT)0GP39GCm5Q7RX(tNok)FmscrFoq9fXnRcvpjcMvEpnmxain60tftMYxUAAABHTuMQ6jWGNWc0lNJv6ii1pj1F855i3S6OTQ6)K0Lte)mJ3kEdXKB(P1dtD78hDsOWheXcy4evegDNVMTohtJ3uXGPRNWOgv4NjT6N52xsXEVY1iNyfDi3T8U6W97LpcauRw0de60km2tcMMPhbHt2Zbw3(zsqph5C6SMrXltodcFldVSTdOQStIxoNsUv(IqioyX6H2ubZiGgYl5wqKCbv3sg0ViPr2pWJJPkzHAVMbDGVzAz8Q0MWFGv2T6bUplTGH24uzI)KPcoVj8rDrT3znNvKK64iH0Xb6qJyribz6zhALAg6X2E(XV4qz3q37epLT2fUqFAWjlfAmbsFrfc6sxKJo5ezwwK7Kca1JLqU7msCPYYykCzrfsqRX8Rgjm7b75rM4aeElMOE1sxmROrZLjdXlZPerKxSt77dhHLc0oKGbxZLkxRHqGPM)qzg0q5DhTylWZGKYmdelggpwv7QSDzgLiC)(8aqywS0fq8jQ2Qtys0ur8GtgTio4cOgKjuLTjh5wU7LfSnTYLchSEofoBwuEsdh5lITgeLG6P1jlJVq4Y4jHJdtZ0FKjJElfx1Lny0PbZZwI6k3jsS11RaL)shLMZPZ(LE4u5(C2WM17DAKVj7vHkbduMmrtXzwQN(QbIfi(fSSP4w6I(TXTkSnT0S4I4sjb8aUjUPQWkiEPqs(ZV)Gm37KvgqZMxDB6uJYtILv1mWDlS(MRPlI0nsiVlF8M5ONCxqr9EeMiWDhhb1lHMGuvq0rYS6NVnnVyIH4Xq3dG7MJzkBfqObI4VdLfltQCcMMGfbHhTnkgF5JwMnFJ9NRwuneOO8IilgrBfpmecwdnCnU6QQP39G1CK2utTfQoMvMMVUe71THTJjbVLSKknzp2UOne3nwdDVhqkyWY5yJTRiyG8Xmz0jX5eT)0C)t7pyOgiOWREqyVRIyxC0JkGnnBYJ7GkkiKIb5wlJHE2RIaWqCxpBTUr(UzzU7Q4VRF8y)5cwvuCCqgwPPQqCrwJVy()tf5auftH7gxfJVelxBCEW9CTA(UZaydqSG3rL64woRvbLMfbmu03n3AOGRGAace2ikh)4Z4DnPauAKgi2AxZFWli47v2sgsxDd45EMRHdcKk5kQQx4wdxRYwbZ2OGKiDsEueZ1QqI1f1RXxCcRgeajRahAhMfSMnFbtCvXlJNfdCwtxBRg5pdgt0HwrLbG6rZaddFJ0wQzbxS4S7bXYeDiqutv26eGW45kSrh8DA7IUMwjWOTpCTwcktaWvVjrrZya8bIqqsoMUAhmgAWzPBJMS6acdNIJSQubdcuOssMZm1kv3YnaK6VVMIuEBgSJCMGSy1MgAioVgGRNumqwNvyHW74LXZfbbn6rwG0by3uxyfkWwCVxuC8YbtcegEP2PfjMYgM6SR7EASAf1KP1zvGl(xOsGafjzt2j8Uq06VYo3Dta2o3aK1meHYspVeKNHOv)IWOYCEDGMkHkY8eHf3c2JIA3XxKK4pD0P(VTseOq2qug8Q41avE1BO3a9oukAn64q5jvqVDMgm5pgjPXldup4e5vJsEeD(GHYX3NN4pnjWOuu(Zte(CLgjfefS8zcv3vhfEYQJEK8phNv6tY14GqrSoXRoks8iXVj(LSqkxDu2HjTpiLAfkipfMTGkcDDI00woEMgR254jiCfyzCbiPy6SfptZJS9QQoSkavJpviqpoRPWNSldg2FubU8Ro6pldyE1PEEFbfnk)uNc7Qowb)yJELr2cVF5Bzft0EaGHULnMwJfBSKcNhojMX2dhwlfo0)Ad49CHlqU6JgyMCGkpO2C1gTh6o11rLoNo0Ei5v19HaLw7Ql9njNc9yM5DucqsnfNMy)ZSN5ZcIf3XhMnj1PaDfFsRcPNfhonZbCjKm55eEI)mkfKDYK6rNE9kFSnQvy9yEraSzzHSrd1O97w7BhXr7TNsRHPDa7BtsGsvRPTsK3YJ1RifDBUfdLWtWogTfp2Y(mmORpOKzWc7B2J9JRoAgf1ZBr5hUF1rHhWBnTmeyKjbWv2YIHa(KQPOFeRvCX0GN8mrdzNNBRK18whRTdBEh2joIScqfg9lxmPbq4wDL16A9UkMT117AtRkfv1jUkOxz7HMwK(A5)0ll93fd1BUmC85sVlhLb4IsDKsvt2u4vuNx96T8ZMI21EKIKhrHzkyWgEpqaobSoq9gbYUqgY1nrQonYRgduxAMfWILLX0PEPZdHcboSiTItbv)ya)zndm7s3K9lpyfoakyZWzHgBC28w(mQyD5CEVO4gvbpOsfR8mHnsEhcefojVhbAHNsl08kbUhs1p3DID0fRAZVy0KfGpVCkusIKNFjB30YSuZCKNkUZrGODpeA376r7qNjVRfTBeXHtNf3sFnAXXjQdHPffJgUKDecudHT2x4NsXSkdfNrzU5Mab8kra6GbMIAm2inCui22WnCWJYQzNOc9modEenkws1YFo7(iSZxnqGz8igjLwettgtELL3PdqvupotJIoxOE6pF05cpMbDdYmR0itxMQKPDhxeHqs5XfHRyuAo)u91CdhD9qnO3yBxU1S9bLp1GtYHn5kR9)QMIxGWAVYwulME4oyF9ZZdujBAFKbYzXnOQprKyTGmK2voleVjDLdQ4mV5GUezIZmHikpD7Wu31bvGoOoVsti4ojZMti2JwrNx602l4oT1aauutbNhEGjuME3dcftmWOQhzJthJxtXSgh9BpCFFaS7STgieovGhv1YRhUFjgNxL9yoWkLoCSbIhYyPh3d3vHBolNQcqfGrMgmBrqswrq6H7CrJpNtBJV5jShv1gufS3WSRZczjiNGJEsYybvmtkADC8sXFlm14w0un)1fOtISTlTHxL9wmll6TX3PK2PhJn6ZPTSJ4YQJEvIeeTT74rPM4mwhwCqlsREDX3hRbBA7Q3kDAXP9yBM8(1MY2EnbEx55uGAbJitN4w12oZuC5ZXROHTzYK3lAfZpXckKXgc1zMWvFrJXqp7vRC5TzICTnQlUFkhkJWL)moGel)dmoguS7xzudIexjlCi7YFLZOzuqT0jR3HXAHhhZIUowwJ1YqATXaTK75wJRrgwR1G1WxBZeMnL1HQg6ycwYim)m30Ywzils1vML7nO(7ngqQneSu2crLdWhtCICzLHOqeG5(BAvgcykXMbKa77bx1UkDxE7bQIIoDH7JDyfCKv23U4TTEf(JsGgtqjyp1LdjpOr1wBZSsYUrLA3vg9d9CsrQxVkRXf5mFkoYPnSkLAocPCITSBzxHlTlwAHBmQOYU93vJ)wTlL5Iou0mQAvRDG6766gAqU2xTvJlOIzdIX1zurUiOW9pYimt4(EiU(KKqjdLHfZFlLkg5rswgQgmhtfOG6W1sjQEfZRq4SjPlva1(w1iyhMYAOjBtzArc0roZesySdbHfDIYCPcyG6842uDcuJjAqhtfJtdoZEMjhvl2bqISJj0o0FEuOdpANgdLQ1AHNEC0Oh1G2EhOc6v7HGy726RltwPeguOUNALGyzrBncjPMDcBujjQiayB4UzNf4(DG9U4ljAz2PqdSYcWrTS5BhuTaEZJGjrg653sqtyPYma((dgolwDoWP8NRz5uxv6ExetqScc4B4cEzw1PfO)32I3S5ZgIK5c3zzJJTegJpf)H0l(pdSK020cdk4PBONiTT3AX(JyXfYGeSxV5zwSENqeeLtLp7e)LttRGWR6DctIxUi1KHAWpD(ewbxGxvxVsVs2V4jbps83eor4p(8rN5NKMxKSBwgwIAVLFtgBfxVT3FQNpKHEL5SDRsvFJtpzXztq8g3RUrPY53y)66sr2VBM7oI(LmDML1tLf7T8U(B1rlKNxVKGXrZNODyNkYfjeCq8m1UW1aMjmg2qFQ7Y48GXc5zFbLK4lMccRJA9JGggDC08LjYtHZJ8JFuy6zHZhLe4NiywEJ2zX4mnvngW3muoH3EBjwQ5t9uPyFGKNEsuCvw1LhIX5blLjVx2VIF8gLuZQJoOKCuzzY(B7TfJAyWyqaL45BBW(v8kFpHQgDwuo6DJeEpuwJf6fcHqgdQr6TaESkQ2tMQmO8lXKEnmWnSEopSOFyjmwy)tIwkyLRos(bzyz25xTCH8mXRho)0I13Ljz)UVyPp1pT2UOYl4pFI8)P0x5Hew1e1L9jzJ7iHeNOLqyOPrLheSWpo7RUqUqW080VLrzYV4c5x7gYbkiOwqXQk(KjUDS0Lc1TmqVMinQ6pA0S2G4(MuBGrjoTBK6CR4leBNfn7y)uOuXWRxOlTgoBrC0ddtKN4JaFbRlC5Srl8hlKoox)O3MAwLrTCpcnP2gp8EAdFZTMQp7X(8uP3k6pWF6TL8R8NEtb)u(b2NXHZgnoAsWBzOa81Nk2(skHOBUvmAYZBUuvvrrSu3Sud5BuTLrHsQQn5SAzi3S9DL7si8rrwocz65c(uSAhlwdNgmtSlKFfp3uKrQr0oR46IlSRxEny9YZ91lpxxV8mxVaeGlzgM22KmJ4au2HYrGxi8x5l3bdQmbHeFHUxD3xTLM(BB6Wy9HzZ0LXIRJoApgnIIjg5d9s2dB45Uuny56Riohs22Z9lglqCL0J5gRAwTpIrkBD4sYiB)5SNaBx9LdtObWrgIo9SfpQnFvlGCxMnQoZ4TYUMSGbgOTN(JN3tP9nNrvHq6WfkxT8Qff3KmgIlOqE76RQv5EwCX1J5tAhkU3X3YonUwiJZMkQMMLWMKH(MLH411QeSEkv(RCRGbaUGm1Ke13McenIgRLsy4H)dtWTHjuxi0J1GKgYWeAsDjoD3TCs7GahEoPDiTfN42DSFxkkH4ZuqTgjtk4CkxD0JLSBGVG)6zBze7dFIdUlr)D3d2zVgCL6r4uwlwsXDPbY8EtgMyRBCdUB9oyx2O353SE15oaOGxBr0dHX5pHi)qfchxJJPhGsKoxf6AcGztYwSDKDQA7q5SVHpfiBTkvfWU9xSlivKYvs3wqaCnFQOKPn5ZIRJ8Uw9g01OLWttOC2Wz6M8(lHl)B2sxA0CtQGaRzdAIBPxV6q60fY9ajXzS09QvPt2so61(QR76GONLL5SRXknHJX5ziS8X4LmIEc1Os5OJNLdRZmNl4ErD7uQDHe0kuGj8qZScuRAk6h4ef)WRP4I8IffpAjy57ZtJA1hLNwFpwitflgDAqFSuaPI)KbBe1dkKQEmW(G5foc0bawYorYm(o43ERmfsmiLbQDrOBW4MH5yaRgrIKamVYtXnq47Ud20TBKD)TmlRrGT)zkxfqok0cD9GyxtumEyGZrn9DcFZ3Qs7z4GQQoK4ccft6ZuHN6UzAhuN)ScGt9ctH9RIcEGA6sfiUK3WpTDC9nq9gXyLXu2TtEHxzmYiupxGmQFEYQm9L)fwB3sxO6uhmp4zA8bv1yADxPyHo)rkhVvJ2wFEQLIBVQ2IT5DfpU9k2PZGBbthGYBe36i7m62WcKPffNpy9UPTyDAbPI3RAgSZa0TqxBLB2Roah9a6ciKAnDNCPuVNVlQM(VqeKwJNqQEhApP6W1GhKxYWDuMAz7qHUtphBCtqEYDzELTZR)R9nVz8TUslg6KB8Phw9rb)M(mWAf4VEi5ywEzrkL9R8xg1O8fCq7ZUIdqzvUu664PvPFnosxvhtKBDCxSixqEnZdGkbEYQkfoEXvHbVzpOp8RuLTRANMxpJYUURdG6W7(8ERS)Ws7ej0dgsLYpppTnt8DHYY92AaIqE()qVipuTEvARz8fJNMvvDN5lwiNuwoO7PhwcERm(63ZbbLYiZ(rsXSvQNKP8g1tJPqLCUUea2unlPPOEia(JK4L2CSQT7EeHAx0Sl2U0LMADjSsyiqwfW1xEHB4ODUcT1SjpylTW9cdPL9ZZhcIyh2T7NJk3v)b42BaR41RCtqrpK1EgLIbssnR)ZCYc7B8MASewbZEgSomFa2t7yVaRoyQTOfsSQUQYxGNYDxySvsmQDCAxU9PoaLKOdD9ps8D4qo)bGyFPTqUMos9UB9L0aBPYpDgFl4XZ1)aOr5CeDkTB3PZVlbU)StYo8SlxSPDB4KrV2pi(0ouZr7oShpbd1MPtFtg0z94ZU2LOaRTvx2jxAxcK)RYO4NK7aC9eZlwH2DzZXA32jn0vYI3YLCOTjaORvykYGW9lOsO4jqGPivQ6C70D5SO69mz2vLOeBf3nhT(iXk13MAdCTBIZL0oaayeYqVpqyMSjAEZv1FzU62EVLSCMd4svv3gKL8FV6E75YfLGdQpqPNYnXI9D4kaxLgYydKbfRSCyI8H8r230d7sKzsIChXQfXItffZFV6ZJhLQOb0iwR(SHgA64KoMBgHDz)DqM5qxOC8zlukCOOvuOMXYFj7gCn7c02j7xMbiWWLvBQvciKMnGUyFjZV7T6l9dWXqZihIY1dYmh4QNqEgaIUzdejR6FmGi60MoZfuyv3rY8JllE0JCdbWLi0wood2Sji2Z4glEktXd5I3f0gFbFqSPptGnFf(EOGiLMDHCnO2XeWCQIExL3TiIHxXcX9on)kmPHFNLXx4Fr7s1LqAfYrj1ueRF17quzO))VjVAmnEEUMuu1VVJKjgTB2S0DVUkmLAUBimidWP2A7MMybuZ7kSwWYdRlzL9j7AGwaS(wtLNaD5L3dBzS(6ySUhKARPHJfMj8NNCsu8SCW409(e)(xR4BEbNlloug78EmcgrgrLVxzpKaYc2f8C6)HSxo0K1gpL4oBak56duFFxREMhXZ22(zaBWQguSdqeyIUmKnTRTALIEo9hL5V6Q811Lqga)0eRtqT9qM0tHqW02uwgXto26qDJOmmj4L7wjeGOw4GPFWVn8fxdca56KV82RU4HWUvlQAGm)BJLq)iV7cLItZcLAkgTk5C)4jxi6KtfUgy2fWxpqAnH(AZOQzK3yg1ZPq590YOPrJpFUi81PNB8CIltJ6rc8E0izrW4qryHf3NgqPvSs6XIXA7oc)XxSq5J(ikQPmsc0gIX5Cn2Afn27PgJ2PC1onreYIKbSQSq8YOwGgQszLTBJvMF9TK51xsWv244VtwSMdosBixlwq02qBARhK6V81lDOK8UMf5b8bQs4xVCqbr7mxugq(ei9RvHMaBfqvKEdvnqoRkoTWHVaZTOzmVDwWHtq1OFHXuwUNCfBgJXbKi3kyw1SLAy1WfUme9aXemnAFnzSd56t3yQykLoBzXQH9WC9ucDrHHDDEoqsmlxD0Vn8W85wRYLqS6QKvccJdY7hVCA0yKbY9Ncq9wB4QvgKg3G6DjJMrzFO6eC1JCAP6YIdgaRNJGuougblNQyooOoDR86t7MDmJwQEK2T)hMXZA6eDyHsAujTI49YnmPInQq5VPIsv8(5AtCm3Y6fuz9icLdLscd01ndLqcYSRHKmmcynR2SGc3bpoeeNSqCj92IFwUrEoBS(fpxTyCMcwSekrD1ouLnbhAhuavYl0ZxjeGQC720HcWc6vY7UQ6RvgdCg94xh52ryxvy20Dj0o6U8MvR3xWBZUTdH7ea3uSAdAKVv7ywnIgXf6M2Ox(jdkzAuQI8auYgneA8UDk0aAD6Aj0yABQvcnEnsOXdwObZFzR2S2eAiULMnfA8ysJlBYFU5Y15RPIKOkCGyxwl03elApZ8Q8CnIaY6eyg1)IDVVgpelQjsu5SMINwDw5cxwWkKDA6TRt9Ys(jEYPlEWm6InVgk45cu7sL37ozPpuspYh)gEd82DW93w4o6J8ZURNeEL)0F2p9Y)U3)l)0)Xl)p)0l)w)K7Cs9h797C579JE6h(r)(F8780F67(Kp5DEYV5F6P)1)7x((F0t(8F(vFW)ZV7D(lx96FXh)X7(0p87jE)N(zF8vF))17uQAJaSXDEYN8BUJXwD2n6l)03B4vF8h(LF63HEqamgRpaqn4gTZfDSZ9AXYjANw(8wqWU21oqUYnNYKS9NFHz)P9m3jtUUSCVWg0LoiSH1ixhea3fnLMBVWwR6C2vp7Txr70MkS1IU2bYfxYyy7e247scHT79SWYg2G0y27nyxRSYb3NRzfqSbPX23Ub7AfEY9X5j6EtdWpmAGnbd35Tyr8gSRz5faHJcOV0sErlw8Ub7Ah4fTWuVReCR6CwsUvUc5kj3QoxHKhoC9XjSP51zV7crZTDfXoGTUpj2ceTpxl6Zu9o3UjUVdl1OGGKbWqH1sNhVwyl5MSVvfg946u3vmbi51yV7crZfDbLguB7tkniS(CT4DavVZPb5U)yuJItAqKT05XRfEMCt23LcJp53(tEYN8DV6h(Ex9p)JV8x)lV8h)rx9(VZt)R(SC4tEYN8ZEYN95FXh8rF5N(9EYN9TV6h9VC1V6hkBZFZF)t(T)3x9d)fx99)5x(B(hen7QVZ)7LV3VqqARE9mOIeYAIF71TrOXrGz0NP)bRo6poA(ddIZ(qkgTiixLkz1rsumVJ6zOy)DgSL1zNyZUd6V7xRaK9ED6wXoWUgl2FVCyPQprWLVYwIEQdm4GD0rPDVHp(XBa3Yh)y07ZHh)4kIdmnN96u9CqyuRFSzIg2FpbPVvbtyZUoC(MQ7l4t61d2RKLENvzFuXCCL4vE5kXn3krFi9UQVkGUQ(H71b9hLpaNpyEbBRCegSBYG7Ylyp4B)SWRoIbbRUvagk0M2ObeP6tagpSw2OHdmr8adgC7A0qvxXkqtM6hA3P78SWXeIbXnHa6M2Ob0jHaYw2OHZbHaI21OHctiW8HgDQTj0IpPIoAaTjUVuy)h6dJ9MDh(1661)EBQ(HWU3MD7Q(oAF(R7awKa92C7Tg61R3w5PNe6dD9M3l)HaFGR3C4GYn4PP1x52bT2NqOit5xVqnbSoy0axL4YroaOcjHayaQzUpqn2J)BWUwjYwcnrkMoudCLG9CJPJ3m3hOgduXnyxxY0TTuPCKBD0A1ltdEtYmzlwSAbb7Ax7a5YHauJZmjFx(Y0G7wNZU61cZXTGGDTRDGC5aSVXcB8D5ltdoFxF1ltdofp5LPbNJxSMsBgBEuDDX7gSRDGx0ct9UsWTQZzj5w5kKRKCR6CfsE4ZqaJqgRwnfUz7DEgulKTBdj7AF7cbZ54ivgoBBFsLHtS(0njVgHsfQuEl03Vz7D(fYwSddaj))XEpT72ihh5ZIqaMqU6l(HyYUoI0y9UzVyhhF58E(YpcCKOihTIyPij4qUYlaH(zqq(19gK)FpbhUNhF55iv19m90D1v1Dtsj5nab(hEfNz6U6QRU(UQ(bBStbGJPf52t5fFmdr5f19lPVF94o62ixPHngIieYDxhZDb5oHPsJyeM4)oB3CS)6jfA0tkTf22e)5bZXupMJTnPyupOKUKwgq(bC0tbOJjcl05NDDmdD(jKtAcF(r4D2U5y)T5k0ON05NTnTFEW8XYJ5y)3)PkTFu3mEj6n62p3E5gj4znuu4E9ZYnBslvumjfuZSd0XBYR5Pwf6R9CMonHzIn3ngUmv8gpBwo6GuPtEYh19uMWJcS2Hx7V)PAu3p86JaSE)x93)l)3)))1)MMi)h))(ZTB)J)V)p2CHuV2F6Tlwo)6jyJX7N9ZU)YBwTArXND6PVBYQBwFfm63EAXKBxRdq8OLdVEf(3Jo9QPZV60v3KF3WL3bV6KzN(svwK97Xi(nz1h)Aq(uXPLH0)uvKP199WlUz4hMp6eCqU)RWz87wOp(RBEt4GD)LVDYTVcyl97gUCe8xVaR5BSY2b(FVO91T70BiU80PTwXjMuV6W(NwXz4iSPu0Ven1(cuw58jJlos17)6xZFFsSeyAlMMosttc5jfGkU)YVy6WrVFkG4U)s45McHVqJFUb2Nn)wDnaxu(YFPPqSrHeWB(n5JYlkgI9zqSk5Fp87tboIhJLPnWJTyYy4xavhMnge0BnWaGon)28zRuB5BX6x3Sj4qX((ZEZgNxqkhBiVMqQXqElwVfqhjtEPSflWoClqbh2xpFbtIiYRfDbk7oe6iTvlWLV7cGQT80A)whnFr)L5fa1a736MHK8VdjRsSoVcpC8KILRxSsF()p(BYF)KPt((7V8YL56wTa8jRMFHolxUeOibA8zZTjnZhFc(XWxdCVYhcKVFXAvnRF)L)bSPbuDOaMevLWJkYamXwnrp(aD)O8zagyEHggQbnoq4i8CZfJg3V9rLpCY19VDYSpRSQ(Vsp3xCho1v8HpcENY8YX55zmj4tMvheW5LpVrXI8PtR6afd(8Un3la(a9FceixGnrKheySplmE)LVrDViuEDBJAwUa7bifajcWDYIyWLsSsJoKeeiaRoS5dpPN4wpsjbLAr(FobxuD7ITCb9YdznFtoEFHyZdxZ7D9IcTeUcx2Zdb(kGYT5YOfN(4vjsPrPsUwnGd7SWU6NBMPFXzvt4ffvZN(laygOgMTgmgZsEokLQaqhDGjDKEh91QgBgi9aonPATzMfhkBsD6tFQRq9VhQeVyjQY6dusOgoZASgpe4iAnMIOcN2RwjQ4GGnA3S6h7MbuB20WrQa9PopKBKBMv)kufXg0PL14ZK)veo2HhFF1hHXxTR8DQDcubQCq9d4uoYV7AGotHmv9Be80xoSRIuOZHhb)lLHEZWFav4O4KAU4dx6HY1Tk6sC91dNcZioZVnhKqP0At)TQrQKgaTQxFFzHqrUdP9Y1WPm1FDb(j65y4YJWMN9OvatlGTK81XPwOXB)iqc)9kvcFZWPtVAO5e3I85lqQ0P5FaylHuIXM6RlCM6dcm34)bt)ll)97V8BlFqn2RVNO1jZg5YotDEKPLHR5uPBQpGW11lbZExVOU0eSB3lWVJ27wsm0hO1mwfRNYmHEkovO7Ija3Z1lWB0I3HYwdjW1i4rtLq)0JSUdI14sKD(59FrRGKxwn7Dw2(wp3QEwSBr8LyHZRQ4JFzwd3cuzqFsZC6q2g50Mn(nXP6bL7PdErl7ISHTov2SHamDAUzJAR2EnaIKYoObTUAYoGoN5)aEmRjbJQ6ssL0siINJediz4jWAyt6mUOFhgiod1KAqB6oP9LAZJY8sPx)wqUoAJtjL4jKwH1uqnauWW4lnYHxDdkecpnOiKnYN0hD)5aT()M6BbI7Rv9Pml2Ju(IUZMzb7UYQpklEgF1nlNmDAfZEDFCtlb0Jw(Sd9qtnpSMIRQrx59DDrnCQFpAjsv)EvA75DbqadG3weHpZyKevG)K3B2H)nlbOk9ucGAuQRWZwdEaH)xtsnQDE3mXU9v5upCPr(Bj5KspWbDlpUYE6Eqh76yJILBdimN20h8l0ZUpHevN9iJKrKbAzrgDntzxbYS50bWKx10J9FZCLbeQlYJzyNhCQQjiIg2vm52c1fZ0S3P1bD58BHt3RHhP9j19x(1kNQGkj9kyID)9FvjJc13(QxR82Y7E3uLVOW39M8PlU)Y3RUoogbd9A1HLuxpA2ikdTa(NN3UxME0nQZvKXCgf3deKPGpIRf7AvmKKBqdk5MBFGdbTaNloGP73z4st74DdaI9aD6Ub97CSqhUZ7ibVkIxyRQaa41bcWsfbQaZ1lidoXypCGOuXv8eXbeV4nRrewZK1EeJYidCUGYAgL5JF3ymixNEuu2USQ8rvE)K5iCpPhnON8AZxB9Vn)U5yVrCvTJmb2zQ1H(eQ(XA)aR01rDWercRgQm)e47TE0Q1lZPkvskWzFTr9SnM7Sx1QcwWwkyFERtaPaU)qh5cqwxUWL)rKYyguQcK9DGFV7TYDYzEpR2vZwcz9)UkJhltNd0ACmu1xmEH3ZQaXSgwpGAYzTod12UY8Ad62QPpC1HbU6SlWLVPWBbCvQhBNw1NOldtOwgQFxhT8uixhhLZZs4V)aYnR2JoooJJZYiglke4qHMAia6eiVQNaOSlMGV8mvHbbwP6VJxQcWkC7Hk2nhyoiaBGtQyxoiIfCvJ205ZFpqtoC2fGAjt9SwPDQB84KyaEV(n9EVyTFnnEnKI3OsHYSb7fOllWSHBm5ncRr40A9al1AkmV6HT9Sd8BMJoEcTT7OkPflwoFub8xFC(AqSc6DrLV(rFdD8Q5hR9r0xAetcQbcYjluEPQkOz44HweIx72yg2G92z9GRmkeu18ZQJr6D3D3jOmXRMVQOksPW)g0NFX8LRoDCNrDNn53(HXV9)6JV(Q)JXfdFDXYV406iFgt8DLgJEh0k3UhQUtWb1WXy5LX6i)0opXn3jpf(3LVg2XDYAW4Xe)pW7GeXznBVQoKb4b0DqmGFcGhXCOEbpqsvt7PujQQtRiq3iixdg3HHYv(xkYKmCTFkYKMH2w7C4wQmV8(1(dsYld7KlhLm(uf7yMtUDnMqYznHOKrNueRpBoIHY5LsmmYix66Lv53UiheB7dL7b)dFFHqWJsxeMUFL9nLndaAesal)jQKReF)IATElgbJ7T4w1vlxd)2KvFeeARVDRrhXYWwpe7Gy(JwMWZiSqNNFdEof)yVn7jk8awbvPsbXWPojo(Xey55vSONcuWRxQpgYPbBVdj60Jc3PhFbRBG8ieIcMrLjqlrPhcTKLjIEUH216MzFaERSxAPJpQLEGXNQtDzS)j5skcSpCjO9lavZxcSJxTtKxQa31Uvl7eTZY9SWK4OvPsDHgbwn9XOHxsXsUr5d1g3A3TznLUdykiMWyAl9IQMvv0ZWq0l5wRNxB7T1G57X7M1Vh)LonRKAqeELDAU3R02(C15gJoOoJdS0CG359yArtStKfXAfYhDC)H9nvO)C94yysHGQ32OHu4f4VT1T(9UU)oR9ZCg9q0VQPmn32sUzOQ9dF2)8qi2qGsustW6jIqJkt8btIl1hFymAUdKF6BbCfBoMLhi0JZb74oNihetSUj5kXKzFy(7bm(palvGBSQ4EsnFjSHyUXr7COfZVd2dMm761ftSIOUpSZSu73PLekYnHlix7wUjDrG7w3nBIDNOB9gUfqK9dys0jRhlNQSXUd0TEdVYJY6zcPplZ9EUe2edSaOi0TASPpEsln0pv8mUs2jL9ueB9AYggOkwa9y51HGtZm3CyZhAYSscndBVQANtfGAMNxnX4JpO(52v8wtscSfAMzQ6vNzMXgxNz2TwvbMjou(dAJAxWAom5hKrXbcqhnc(9sJUq4iIYv6PDilmgLhLhaJ6SkIV5fGQWzKAsWpGDgPHGC5qOo0egXqNgAgu6mE7aMGPWHtglWslh7uM1ZzJiJRv)Yys3el1vdmNKkGDo4DLKSWeYUid7CJ3RzIZMB80kNEw94kJu3EbDsstqiS2XE2zxDM5NDY0yktGubabzvpDZVrA2omLr9WO88YkLvrzkadnCil06FwteZ1FWdXXMvj(MuHLSa5tL8YitEm2iFciYKrWirH5XQePMtm4fRgweS4EK0DoYqg2zJT7fkYK92vwn4DrRPm40A)jplvH)K6ehjUZSgmgGk5yCrkAlztrse(fFp0Tbo6CqvT2pQo6kbK8De5QUpuyh1oAseJwcEkStlrJfz3Z68KUNXWwj99SoB5EgF3IGlsCU7zCAu5(W9zpJTCze3ZQYXzXOJOLwq2C2Jy0OsQF(uFK)2zUzMZVADVmV7M1TT2pQ))pe51K4gXNKPoAKyPRDEeXp2w(rZZ7iLLS48LxSEHRRrmtK5QsHWFWs4IW1is5lMoWmA8fJbkusbrA82BNaJeBTzy7KpI5fUFTDMaO(sFhzs5gYKpPShVoJCuNmX20sYZECZLChwlVrkoOb(CMqfsx)DeQQNaHfXjcsh2neAXpM084f6MsGHKKCaBlk5A30xuf922TAXk77fTcvBvYY(oZ3l3HHOO5khZwuGr0psTKMrZwoEEqO7xMrg90PNXp8yJGxdBJJ72BqlMCdTIFuxR8BXMXNjy8wpVktkg0(5BhHQiS16Pg2iu8F6G08dz7(rNzRYKcOGr4bubPNhKdovWJeA(SwQeX(PeptZlLiGMTeFk4Lf6Hk7OlziYkwqEz)mV10XIVA3onheCRWjVnCEpu0PGyXGXovmSzuJ)Fdwn2xVwLKH6eQDCzRf7O7V8L)(V((lxM)HjyyUkQlsZ5JxJv31v5RuLI5Y8I1txPF(mtLBQYf3HvfxvLJc0LYUUMWE5)(V2QjF47pbMfVPNz0Z49s7800MM2qb8Kw6wva9ovNlsbv1cyTqggp8enX4LIwEyp3HjD)Vi2lH1ftaCz22GkTNxH0UiKve1jIERt6z2ejX(oPKk4HYOSsAbB1j4Mbg9FIHHeQNxkM4zDIuwt1Vzxoi3tlFf3Y(DBLfl7x8ieAeyLFIBtrr9BHTy0a3CqnRjv7c7YkcJqp8CmJvdbQgQfBt6K5MiJcJrAjrlrq8X4vi7FT(QZvXinDFj29UEN0Z3lj2BjvC28tQ(xn)2RuDpLoGyR8PGWN1f3OBCpfcii3memocQrm2PEg7Szt4SWVoRT32rMLFcJvUMCc2ZYY0sZ2GhDiKUX9aR9cL9ereMsMHHD57XuQkiMkGnE91BYcVZcKeAdIZc1(SkJy56sOIWQlP1KIrRJYTbjSeoXPCSHGumAIg6hYxMKYLmXwzQonX6cecNbNLsDrWO(hlMZYdyrkzrQ2eCdNVDXPKxWHY1ZQuM)xGUR(HZ4oshQOc(Jw6gD2ogc0ehVA7E(6PfJgUuOagsNjeGe3NYzGejteSmn6OIKdCPaZVW8Wk3u3SXDspz1CaNmOvO(cW59Cmlv7LAEgd7im9Gm3cfabp)YEcPWFmTwOEqjLI)rgaJWbijOJr8k)htkTGaYf)Cze3dktHiL9ihrvmLM(jR8jeW5uwl8ImK8NI2zehwLoY8pZ2TCkOGlIHQhSfD)h(PAxCtGYPaS6UGkNfuQURTQ7Gn2KUTrB(v120VXcOVMmA76aD8GY)0rHhol532UEGlH3597icAMZo)0aAdeGm6UIb4m7)(eeHSuLFw80K1nLXyT0NNuoj7)F6IGDCkrbjxu7lJ56K09iW(G4IVCs0vvmPeilyfQ5kTdNTEcHUg(kmz04IE0lbYKeH8i7TSktKOU9Ss64R)MmX(SQyhjS(aU3JKhTnBQFeGSqBlGVtibBeeXXLWnX3oufrzvO74KtUTi1LEDkqooo7YiNwX8NO4aU8kWR5FM2qTxTMegYozmGZ7jyrseoG1gMlO)JuPDkw2CXsbAPeDMFj6N(wpmI4cNKlrySiaREPFK)(yGofHe(pSnUCOYudoNSwkP4MTSd44rLjZTJL4mGJXISjWVuK8pgREFsdbBFdWYmfN0DthDsZvSX68YgU9BYNE8B1iLOnW6eDoZ1f9tR)vx3wr6A5fXRX2joFB)86cR2yAAV)NaTj0szD13Bc6MF75DpSIiC16XW)xX)aEZ8LaJ2d5yg3KSQz0qjf7uOM44PjNjWFCqMCWyp2WL(CUo7GHBGOcfmRpQUJ7)6Bq3h1LhDni0y8tTt1PgJDXJdpnnGZiHDtv4mPWM(zDBAP3i3(s0maoQiD7iSNeba)8elAQd632QVcWndrt(dfAt(usv97rOs89SAsRs(nyLz6rWN17DjTGsIoOd98JT6kjN5(MPIEYXAtQvaw8nJedp(w0w0aKPwqeD4LpMAixplqMH5kfCBB4vQVAlTeysb(2GgtGM1F0eljKKtXn0VPkgFfgqSgjudXUlmT23K361twTJbQ(emhKOo(HUA88ewGdQX4u0mMNbcG5aq9Wk6J0eNju3ev7b0ZDuAP47IiDAdDYg9lBDC3wHHRgPcyYm(HJCn1zWPgyxDt(CLjWpRtRJ9iuOlWDTfLLa98ZA0oKUDpuR99OzP5DotHg9JCJSdw(KblevkOWst2e3qYURus5F0Exl72gXWa)BkStqnIBs6PUFc9uU7Iu000EOja5rbA)67UR3hIuZqkPDDmSRrofBVsususKdjNnx6Hl93)m6bKoA(hob3lYgEGvZTnXEBi5i77i6ElWnwe8yoS9wU8O1beBzLh2EPHy4mqBBgxWR8S)lH5uwJOLgRB5PqynqHLbRieG0uMon9hopSXW))GrFJXoB5cMCgCWMHU0cpLjg2KGpw5wv)qnOXfLDrRQAj6QUmehrKtSsxMaVWjLZ3aEHt2Hs0xpXlCr8XcBI7efWDIc481lorbCotqNOaUCOaoZzYzGg2CTrloKri6scI8Bzu0w8HLP1MgSUgQjtM1Qk5s99kHvrMK(FIWQmjEkWHEVDmtvcloh7mtLjdtzT4SZPGk5ItEuqv6jotitAp(fhz0jLp2eajg7kZL0Z2YHBQgw5Hivy4EPOZBe6Q5J)ee(TlAIOEnC4(ThF8xErrTT)c8Qw8WEydAhFKfqWOiMm0ROE5fVpg0C7OHFUsn0pcATpkshF5yiP4NRoeWPg7IiiUXV2wg3wJgxIJ(KO4H71jlHAgJlT3hMQeTZxQxrhBtfOQEcUc)TT5gXqNGdvOp(or6QryvY4FH6JQqa9fJ(jetPz5yocKLo7gAseJu2f09pQDcNTE11E5KY2PD03jZdbCeUQVnyPjlMzAJAOOJ(DIePCClG6Cvy6rc3vAP)eL1(YAohU6i(9dJdCA36w(5vxZJvzKhzrdLB)6FE(5ABzU)2)E3wp2qkT2XbLNVb9wskKIMNbT8Kpryyx7i8NFIeOb)0cZJfA2wWRpHUPOhckMPLLuLnPmZUaQ67i8KkbYAx8UKHfghDfuutjygh5YgY9b0PaV8PQHDrExjg80rDjLD9aEEQFqAlWxjE3gBVCcBGA5EjMG(dNuoNf7nvIYnbQt5nvlqh7oAjen0i6Y3kbfIpcNAsHMuSwYsAh(e3elgs9P)MKsrWoOMr(vkVOoLlkv3rh8gnLvxO7e(hHQWfJqJZSLXRE7MEPDiqmfh62JDqmy(vAQSvuQU0(UaKRLwngnyBRA13bk9QLyxjJcgcQ7bZcIw3PneB4RTVhvBscvVDNJwzzm90)tejv6AqsLc3B21C2aGeDQsZNcpokWKZcAsl3j)0v(x99HbGcoZuvyODWEWyLi9Ecbo1tjUP4nEgoFZkLdpZhPiOLeZcN1WVjY2mIjXznPCryIDFUDZXkLSGn5EbESTD(lJeyFzcKPdEPe99hFVcHXM6Eik)ecV5791SyvqUvfzYrOHx9FmOnukPdJX(GUSkOA5Kf7rxf2JBZWy2iT)dh5JsK1uaGjQy3RwJJ0phOadWfW37QntjcZt6qlBAWG6duSjVU8XY(ACh5rdwo9tII5vSkjoaZhhoXHxLyMxW(PT3QidjXABI3D22SbbmJFMQnEoyqfKk2n1ISJfO4bxKZw4u9TBvsCaUjVYG7TiKfJ6mqvGRrwKhJhQDPMR6lXYAkW)RLufs)K0JoT5MK6qnORS4)aMNjd7mlYXmP7e2(QEEQX15oRalOvgWDR4xXpOTWtrl48Lq)LjtG7BEgzuVsOeS9616UuP0SQZmWQlikzt0NE3nS(7WynrGPMWRdT5kKn3C7RV8JhFAZnF(Npu7LYZ390VVBZl1)T5F)]] )