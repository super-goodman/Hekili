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

    -- Demon Hunter
    aldrachi_design                = {  90999,  391409, 1 }, -- Increases your chance to parry by $s1%
    aura_of_pain                   = {  90933,  207347, 1 }, -- Increases the critical strike chance of Immolation Aura by $s1%
    blazing_path                   = {  91008,  320416, 1 }, -- Fel Rush gains an additional charge
    bouncing_glaives               = {  90931,  320386, 1 }, -- Throw Glaive ricochets to $s1 additional target
    champion_of_the_glaive         = {  90994,  429211, 1 }, -- Throw Glaive has $s1 charges and $s2 yard increased range
    chaos_fragments                = {  95154,  320412, 1 }, -- Each enemy stunned by Chaos Nova has a $s1% chance to generate a Lesser Soul Fragment
    chaos_nova                     = {  90993,  179057, 1 }, -- Unleash an eruption of fel energy, dealing $s$s2 Chaos damage and stunning all nearby enemies for $s3 sec. Each enemy stunned by Chaos Nova has a $s4% chance to generate a Lesser Soul Fragment
    charred_warblades              = {  90948,  213010, 1 }, -- You heal for $s1% of all Fire damage you deal
    collective_anguish             = {  95152,  390152, 1 }, -- Eye Beam summons an allied Vengeance Demon Hunter who casts Fel Devastation, dealing $s$s3 Fire damage over $s4 sec$s$s5 Dealing damage heals you for up to $s6 health
    consume_magic                  = {  91006,  278326, 1 }, -- Consume $s1 beneficial Magic effect removing it from the target
    darkness                       = {  91002,  196718, 1 }, -- Summons darkness around you in an $s1 yd radius, granting friendly targets a $s2% chance to avoid all damage from an attack. Lasts $s3 sec. Chance to avoid damage increased by $s4% when not in a raid
    demon_muzzle                   = {  90928,  388111, 1 }, -- Enemies deal $s1% reduced magic damage to you for $s2 sec after being afflicted by one of your Sigils
    demonic                        = {  91003,  213410, 1 }, -- Eye Beam causes you to enter demon form for $s1 sec after it finishes dealing damage
    disrupting_fury                = {  90937,  183782, 1 }, -- Disrupt generates $s1 Fury on a successful interrupt
    erratic_felheart               = {  90996,  391397, 2 }, -- The cooldown of Fel Rush is reduced by $s1%
    felblade                       = {  95150,  232893, 1 }, -- Charge to your target and deal $s$s2 Fire damage. Demon Blades has a chance to reset the cooldown of Felblade. Generates $s3 Fury
    felfire_haste                  = {  90939,  389846, 1 }, -- Fel Rush increases your movement speed by $s1% for $s2 sec
    flames_of_fury                 = {  90949,  389694, 2 }, -- Sigil of Flame deals $s1% increased damage and generates $s2 additional Fury per target hit
    illidari_knowledge             = {  90935,  389696, 1 }, -- Reduces magic damage taken by $s1%
    imprison                       = {  91007,  217832, 1 }, -- Imprisons a demon, beast, or humanoid, incapacitating them for $s1 min. Damage may cancel the effect. Limit $s2
    improved_disrupt               = {  90938,  320361, 1 }, -- Increases the range of Disrupt to $s1 yds
    improved_sigil_of_misery       = {  90945,  320418, 1 }, -- Reduces the cooldown of Sigil of Misery by $s1 sec
    infernal_armor                 = {  91004,  320331, 2 }, -- Immolation Aura increases your armor by $s2% and causes melee attackers to suffer $s$s3 Fire damage
    internal_struggle              = {  90934,  393822, 1 }, -- Increases your mastery by $s1%
    live_by_the_glaive             = {  95151,  428607, 1 }, -- When you parry an attack or have one of your attacks parried, restore $s1% of max health and $s2 Fury. This effect may only occur once every $s3 sec
    long_night                     = {  91001,  389781, 1 }, -- Increases the duration of Darkness by $s1 sec
    lost_in_darkness               = {  90947,  389849, 1 }, -- Spectral Sight has $s1 sec reduced cooldown and no longer reduces movement speed
    master_of_the_glaive           = {  90994,  389763, 1 }, -- Throw Glaive has $s1 charges and snares all enemies hit by $s2% for $s3 sec
    pitch_black                    = {  91001,  389783, 1 }, -- Reduces the cooldown of Darkness by $s1 sec
    precise_sigils                 = {  95155,  389799, 1 }, -- All Sigils are now placed at your target's location
    pursuit                        = {  90940,  320654, 1 }, -- Mastery increases your movement speed
    quickened_sigils               = {  95149,  209281, 1 }, -- All Sigils activate $s1 second faster
    rush_of_chaos                  = {  95148,  320421, 2 }, -- Reduces the cooldown of Metamorphosis by $s1 sec
    shattered_restoration          = {  90950,  389824, 1 }, -- The healing of Shattered Souls is increased by $s1%
    sigil_of_misery                = {  90946,  207684, 1 }, -- Place a Sigil of Misery at the target location that activates after $s1 sec. Causes all enemies affected by the sigil to cower in fear, disorienting them for $s2 sec
    sigil_of_spite                 = {  90997,  390163, 1 }, -- Place a demonic sigil at the target location that activates after $s2 sec. Detonates to deal $s$s3 Chaos damage and shatter up to $s4 Lesser Soul Fragments from enemies affected by the sigil. Deals reduced damage beyond $s5 targets
    soul_rending                   = {  90936,  204909, 2 }, -- Leech increased by $s1%. Gain an additional $s2% leech while Metamorphosis is active
    soul_sigils                    = {  90929,  395446, 1 }, -- Afflicting an enemy with a Sigil generates $s1 Lesser Soul Fragment
    swallowed_anger                = {  91005,  320313, 1 }, -- Consume Magic generates $s1 Fury when a beneficial Magic effect is successfully removed from the target
    the_hunt                       = {  90927,  370965, 1 }, -- Charge to your target, striking them for $s$s3 Chaos damage, rooting them in place for $s4 sec and inflicting $s$s5 Chaos damage over $s6 sec to up to $s7 enemies in your path. The pursuit invigorates your soul, healing you for $s8% of the damage you deal to your Hunt target for $s9 sec
    unrestrained_fury              = {  90941,  320770, 1 }, -- Increases maximum Fury by $s1
    vengeful_bonds                 = {  90930,  320635, 1 }, -- Vengeful Retreat reduces the movement speed of all nearby enemies by $s1% for $s2 sec
    vengeful_retreat               = {  90942,  198793, 1 }, -- Remove all snares and vault away. Nearby enemies take $s$s2 Physical damage
    will_of_the_illidari           = {  91000,  389695, 1 }, -- Increases maximum health by $s1%

    -- Havoc
    a_fire_inside                  = {  95143,  427775, 1 }, -- Immolation Aura has $s1 additional charge, $s2% chance to refund a charge when used, and deals Chaos damage instead of Fire. You can have multiple Immolation Auras active at a time
    accelerated_blade              = {  91011,  391275, 1 }, -- Throw Glaive deals $s1% increased damage, reduced by $s2% for each previous enemy hit
    blind_fury                     = {  91026,  203550, 2 }, -- Eye Beam generates $s1 Fury every second, and its damage and duration are increased by $s2%
    burning_hatred                 = {  90923,  320374, 1 }, -- Immolation Aura generates an additional $s1 Fury over $s2 sec
    burning_wound                  = {  90917,  391189, 1 }, -- Demon Blades and Throw Glaive leave open wounds on your enemies, dealing $s$s2 Chaos damage over $s3 sec and increasing damage taken from your Immolation Aura by $s4%. May be applied to up to $s5 targets
    chaos_theory                   = {  91035,  389687, 1 }, -- Blade Dance causes your next Chaos Strike within $s1 sec to have a $s2-$s3% increased critical strike chance and will always refund Fury
    chaotic_disposition            = {  95147,  428492, 2 }, -- Your Chaos damage has a $s1% chance to be increased by $s2%, occurring up to $s3 total times
    chaotic_transformation         = {  90922,  388112, 1 }, -- When you activate Metamorphosis, the cooldowns of Blade Dance and Eye Beam are immediately reset
    critical_chaos                 = {  91028,  320413, 1 }, -- The chance that Chaos Strike will refund $s1 Fury is increased by $s2% of your critical strike chance
    cycle_of_hatred                = {  91032,  258887, 1 }, -- Activating Eye Beam reduces the cooldown of your next Eye Beam by $s1 sec, stacking up to $s2 sec
    dancing_with_fate              = {  91015,  389978, 2 }, -- The final slash of Blade Dance deals an additional $s1% damage
    dash_of_chaos                  = {  93014,  427794, 1 }, -- For $s1 sec after using Fel Rush, activating it again will dash back towards your initial location
    deflecting_dance               = {  93015,  427776, 1 }, -- You deflect incoming attacks while Blade Dancing, absorbing damage up to $s1% of your maximum health
    demon_blades                   = {  91019,  203555, 1 }, -- Your auto attacks deal an additional $s$s2 Shadow damage and generate $s3-$s4 Fury
    demon_hide                     = {  91017,  428241, 1 }, -- Magical damage increased by $s1%, and Physical damage taken reduced by $s2%
    desperate_instincts            = {  93016,  205411, 1 }, -- Blur now reduces damage taken by an additional $s1%. Additionally, you automatically trigger Blur with $s2% reduced cooldown and duration when you fall below $s3% health. This effect can only occur when Blur is not on cooldown
    essence_break                  = {  91033,  258860, 1 }, -- Slash all enemies in front of you for $s$s2 Chaos damage, and increase the damage your Chaos Strike and Blade Dance deal to them by $s3% for $s4 sec. Deals reduced damage beyond $s5 targets
    exergy                         = {  91021,  206476, 1 }, -- The Hunt and Vengeful Retreat increase your damage by $s1% for $s2 sec
    eye_beam                       = {  91018,  198013, 1 }, -- Blasts all enemies in front of you, dealing guaranteed critical strikes for up to $s$s2 Chaos damage over $s3 sec. Deals reduced damage beyond $s4 targets. When Eye Beam finishes fully channeling, your Haste is increased by an additional $s5% for $s6 sec
    fel_barrage                    = {  95144,  258925, 1 }, -- Unleash a torrent of Fel energy, rapidly consuming Fury to inflict $s$s2 Chaos damage to all enemies within $s3 yds, lasting $s4 sec or until Fury is depleted. Deals reduced damage beyond $s5 targets
    first_blood                    = {  90925,  206416, 1 }, -- Blade Dance deals $s$s2 Chaos damage to the first target struck
    furious_gaze                   = {  91025,  343311, 1 }, -- When Eye Beam finishes fully channeling, your Haste is increased by an additional $s1% for $s2 sec
    furious_throws                 = {  93013,  393029, 1 }, -- Throw Glaive now costs $s1 Fury and throws a second glaive at the target
    glaive_tempest                 = {  91035,  342817, 1 }, -- Launch two demonic glaives in a whirlwind of energy, causing $s$s2 Chaos damage over $s3 sec to all nearby enemies. Deals reduced damage beyond $s4 targets
    growing_inferno                = {  90916,  390158, 1 }, -- Immolation Aura's damage increases by $s1% each time it deals damage
    improved_chaos_strike          = {  91030,  343206, 1 }, -- Chaos Strike damage increased by $s1%
    improved_fel_rush              = {  93014,  343017, 1 }, -- Fel Rush damage increased by $s1%
    inertia                        = {  91021,  427640, 1 }, -- The Hunt and Vengeful Retreat cause your next Fel Rush or Felblade to empower you, increasing damage by $s1% for $s2 sec
    initiative                     = {  91027,  388108, 1 }, -- Damaging an enemy before they damage you increases your critical strike chance by $s1% for $s2 sec. Vengeful Retreat refreshes your potential to trigger this effect on any enemies you are in combat with
    inner_demon                    = {  91024,  389693, 1 }, -- Entering demon form causes your next Chaos Strike to unleash your inner demon, causing it to crash into your target and deal $s$s2 Chaos damage to all nearby enemies. Deals reduced damage beyond $s3 targets
    insatiable_hunger              = {  91019,  258876, 1 }, -- Demon's Bite deals $s1% more damage and generates $s2 to $s3 additional Fury
    isolated_prey                  = {  91036,  388113, 1 }, -- Chaos Nova, Eye Beam, and Immolation Aura gain bonuses when striking $s1 target.  Chaos Nova: Stun duration increased by $s4 sec.  Eye Beam: Deals $s7% increased damage.  Immolation Aura: Always critically strikes
    know_your_enemy                = {  91034,  388118, 2 }, -- Gain critical strike damage equal to $s1% of your critical strike chance
    looks_can_kill                 = {  90921,  320415, 1 }, -- Eye Beam deals guaranteed critical strikes
    mortal_dance                   = {  93015,  328725, 1 }, -- Blade Dance now reduces targets' healing received by $s1% for $s2 sec
    netherwalk                     = {  93016,  196555, 1 }, -- Slip into the nether, increasing movement speed by $s1% and becoming immune to damage, but unable to attack. Lasts $s2 sec
    ragefire                       = {  90918,  388107, 1 }, -- Each time Immolation Aura deals damage, $s1% of the damage dealt by up to $s2 critical strikes is gathered as Ragefire. When Immolation Aura expires you explode, dealing all stored Ragefire damage to nearby enemies
    relentless_onslaught           = {  91012,  389977, 1 }, -- Chaos Strike has a $s1% chance to trigger a second Chaos Strike
    restless_hunter                = {  91024,  390142, 1 }, -- Leaving demon form grants a charge of Fel Rush and increases the damage of your next Blade Dance by $s1%
    scars_of_suffering             = {  90914,  428232, 1 }, -- Increases Versatility by $s1% and reduces threat generated by $s2%
    screaming_brutality            = {  90919, 1220506, 1 }, -- Blade Dance automatically triggers Throw Glaive on your primary target for $s1% damage and each slash has a $s2% chance to Throw Glaive an enemy for $s3% damage
    serrated_glaive                = {  91013,  390154, 1 }, -- Enemies hit by Chaos Strike or Throw Glaive take $s1% increased damage from Chaos Strike and Throw Glaive for $s2 sec
    shattered_destiny              = {  91031,  388116, 1 }, -- The duration of your active demon form is extended by $s1 sec per $s2 Fury spent
    soulscar                       = {  91012,  388106, 1 }, -- Throw Glaive causes targets to take an additional $s1% of damage dealt as Chaos over $s2 sec
    tactical_retreat               = {  91022,  389688, 1 }, -- Vengeful Retreat has a $s1 sec reduced cooldown and generates $s2 Fury over $s3 sec
    trail_of_ruin                  = {  90915,  258881, 1 }, -- The final slash of Blade Dance inflicts an additional $s$s2 Chaos damage over $s3 sec
    unbound_chaos                  = {  91020,  347461, 1 }, -- The Hunt and Vengeful Retreat increase the damage of your next Fel Rush or Felblade by $s1%. Lasts $s2 sec

    -- Aldrachi Reaver
    aldrachi_tactics               = {  94914,  442683, 1 }, -- The second enhanced ability in a pattern shatters an additional Soul Fragment
    army_unto_oneself              = {  94896,  442714, 1 }, -- Felblade surrounds you with a Blade Ward, reducing damage taken by $s1% for $s2 sec
    art_of_the_glaive              = {  94915,  442290, 1 }, -- Consuming $s2 Soul Fragments or casting The Hunt converts your next Throw Glaive into Reaver's Glaive.  Reaver's Glaive: Throw a glaive enhanced with the essence of consumed souls at your target, dealing $s$s5 Physical damage and ricocheting to $s6 additional enemies. Begins a well-practiced pattern of glaivework, enhancing your next Chaos Strike and Blade Dance. The enhanced ability you cast first deals $s7% increased damage, and the second deals $s8% increased damage
    evasive_action                 = {  94911,  444926, 1 }, -- Vengeful Retreat can be cast a second time within $s1 sec
    fury_of_the_aldrachi           = {  94898,  442718, 1 }, -- When enhanced by Reaver's Glaive, Blade Dance casts $s1 additional glaive slashes to nearby targets. If cast after Chaos Strike, cast $s2 slashes instead
    incisive_blade                 = {  94895,  442492, 1 }, -- Chaos Strike deals $s1% increased damage
    incorruptible_spirit           = {  94896,  442736, 1 }, -- Each Soul Fragment you consume shields you for an additional $s1% of the amount healed
    keen_engagement                = {  94910,  442497, 1 }, -- Reaver's Glaive generates $s1 Fury
    preemptive_strike              = {  94910,  444997, 1 }, -- Throw Glaive deals $s$s2 Physical damage to enemies near its initial target
    reavers_mark                   = {  94903,  442679, 1 }, -- When enhanced by Reaver's Glaive, Chaos Strike applies Reaver's Mark, which causes the target to take $s1% increased damage for $s2 sec. Max $s3 stacks. Applies $s4 additional stack of Reaver's Mark If cast after Blade Dance
    thrill_of_the_fight            = {  94919,  442686, 1 }, -- After consuming both enhancements, gain Thrill of the Fight, increasing your attack speed by $s1% for $s2 sec and your damage and healing by $s3% for $s4 sec
    unhindered_assault             = {  94911,  444931, 1 }, -- Vengeful Retreat resets the cooldown of Felblade
    warblades_hunger               = {  94906,  442502, 1 }, -- Consuming a Soul Fragment causes your next Chaos Strike to deal $s1 additional Physical damage. Felblade consumes up to $s2 nearby Soul Fragments
    wounded_quarry                 = {  94897,  442806, 1 }, -- Expose weaknesses in the target of your Reaver's Mark, causing your Physical damage to any enemy to also deal $s1% of the damage dealt to your marked target as Chaos, and sometimes shatter a Lesser Soul Fragment

    -- Felscarred
    burning_blades                 = {  94905,  452408, 1 }, -- Your blades burn with Fel energy, causing your Chaos Strike, Throw Glaive, and auto-attacks to deal an additional $s1% damage as Fire over $s2 sec
    demonic_intensity              = {  94901,  452415, 1 }, -- Activating Metamorphosis greatly empowers Eye Beam, Immolation Aura, and Sigil of Flame$s$s2 Demonsurge damage is increased by $s3% for each time it previously triggered while your demon form is active
    demonsurge                     = {  94917,  452402, 1 }, -- Metamorphosis now also causes Demon Blades to generate $s2 additional Fury. While demon form is active, the first cast of each empowered ability induces a Demonsurge, causing you to explode with Fel energy, dealing $s$s3 Fire damage to nearby enemies. Deals reduced damage beyond $s4 targets
    enduring_torment               = {  94916,  452410, 1 }, -- The effects of your demon form persist outside of it in a weakened state, increasing Chaos Strike and Blade Dance damage by $s1%, and Haste by $s2%
    flamebound                     = {  94902,  452413, 1 }, -- Immolation Aura has $s1 yd increased radius and $s2% increased critical strike damage bonus
    focused_hatred                 = {  94918,  452405, 1 }, -- Demonsurge deals $s1% increased damage when it strikes a single target. Each additional target reduces this bonus by $s2%
    improved_soul_rending          = {  94899,  452407, 1 }, -- Leech granted by Soul Rending increased by $s1% and an additional $s2% while Metamorphosis is active
    monster_rising                 = {  94909,  452414, 1 }, -- Agility increased by $s1% while not in demon form
    pursuit_of_angriness           = {  94913,  452404, 1 }, -- Movement speed increased by $s1% per $s2 Fury
    set_fire_to_the_pain           = {  94899,  452406, 1 }, -- $s2% of all non-Fire damage taken is instead taken as Fire damage over $s3 sec$s$s4 Fire damage taken reduced by $s5%
    student_of_suffering           = {  94902,  452412, 1 }, -- Sigil of Flame applies Student of Suffering to you, increasing Mastery by $s1% and granting $s2 Fury every $s3 sec, for $s4 sec
    untethered_fury                = {  94904,  452411, 1 }, -- Maximum Fury increased by $s1
    violent_transformation         = {  94912,  452409, 1 }, -- When you activate Metamorphosis, the cooldowns of your Sigil of Flame and Immolation Aura are immediately reset
    wave_of_debilitation           = {  94913,  452403, 1 }, -- Chaos Nova slows enemies by $s1% and reduces attack and cast speed by $s2% for $s3 sec after its stun fades
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    blood_moon                     = 5433, -- (355995) Consume Magic now affects all enemies within $s1 yards of the target and generates a Lesser Soul Fragment. Each effect consumed has a $s2% chance to upgrade to a Greater Soul
    cleansed_by_flame              =  805, -- (205625) Immolation Aura dispels a magical effect on you when cast
    cover_of_darkness              = 1206, -- (357419) The radius of Darkness is increased by $s1 yds, and its duration by $s2 sec
    detainment                     =  812, -- (205596) Imprison's PvP duration is increased by $s1 sec, and targets become immune to damage and healing while imprisoned
    glimpse                        =  813, -- (354489) Vengeful Retreat provides immunity to loss of control effects, and reduces damage taken by $s1% until you land
    illidans_grasp                 = 5691, -- (205630) You strangle the target with demonic magic, stunning them in place and dealing $s$s2 Shadow damage over $s3 sec while the target is grasped. Can move while channeling. Use Illidan's Grasp again to toss the target to a location within $s4 yards
    rain_from_above                =  811, -- (206803) You fly into the air out of harm's way. While floating, you gain access to Fel Lance allowing you to deal damage to enemies below
    reverse_magic                  =  806, -- (205604) Removes all harmful magical effects from yourself and all nearby allies within $s1 yards, and sends them back to their original caster if possible
    sigil_mastery                  = 5523, -- (211489) Reduces the cooldown of your Sigils by an additional $s1%
    unending_hatred                = 1218, -- (213480) Taking damage causes you to gain Fury based on the damage dealt
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

-- Soul fragments metatable - Havoc DH (simpler than Vengeance due to limited real data)
spec:RegisterStateTable( "soul_fragments", setmetatable( {

    reset = setfenv( function()
        -- For Havoc - use spell cast count from Reaver hero tree talent
        soul_fragments.active = GetSpellCastCount( 232893 ) or 0
        soul_fragments.inactive = 0  -- Havoc doesn't track inactive fragments reliably
    end, state ),

    queueFragments = setfenv( function( count, extraTime )
        -- Simple virtual tracking for simulation purposes only
        count = count or 1
        soul_fragments.inactive = soul_fragments.inactive + count
    end, state ),

    consumeFragments = setfenv( function()
        -- Consume all active fragments
        gain( 20 * soul_fragments.active, "fury" )
        soul_fragments.active = 0
    end, state ),

}, {
    __index = function( t, k )
        if k == "total" then
            return ( rawget( t, "active" ) or 0 ) + ( rawget( t, "inactive" ) or 0 )
        elseif k == "active" then
            return rawget( t, "active" ) or 0
        elseif k == "inactive" then
            return rawget( t, "inactive" ) or 0
        end

        return 0
    end
} ) )

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

local DemonsurgeHardcast = false

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID == GUID then
        if spellID == 228532 then
            -- Consumed
            soul_fragments.reset()
        end
        if subtype == "SPELL_CAST_SUCCESS" then
            if spellID == 198793 and talent.initiative.enabled then
                wipe( initiative_actual )
            elseif spellID == 228537 then
                -- Generated
                soul_fragments.reset()
            elseif ( spellID == 191427 or spellID == 200166 ) and state.talent.demonic_intensity.enabled then
                DemonsurgeHardcast = true
            end
        elseif state.set_bonus.tier30_2pc > 0 and subtype == "SPELL_AURA_APPLIED" and spellID == 408737 then
            furySpent = max( 0, furySpent - 175 )
        elseif state.talent.initiative.enabled and subtype == "SPELL_DAMAGE" then
            initiative_actual[ destGUID ] = true
        elseif subtype == "SPELL_AURA_REMOVED" and spellID == 162264 then
            DemonsurgeHardcast = false
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
spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237691, 237689, 237694, 237692, 237690 },
        auras = {
            -- Fel-Scarred
            -- Havoc
            demon_soul_tww3 = {
                id = 1238676,
                duration = 10,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229316, 229314, 229319, 229317, 229315 },
        auras = {
            winning_streak = {
                id = 1217011,
                duration = 3600,
                max_stack = 10
            },
            necessary_sacrifice = {
                id = 1217055,
                duration = 15,
                max_stack = 10
            },
            winning_streak_temporary = {
                id = 1220706,
                duration = 7,
                max_stack = 10
            }
        }
    },
    tww1 = {
        items = { 212068, 212066, 212065, 212064, 212063 },
        auras = {
            blade_rhapsody = {
                id = 454628,
                duration = 12,
                max_stack = 1
            }
        }
    },
    -- Dragonflight
    tier31 = {
        items = { 207261, 207262, 207263, 207264, 207266, 217228, 217230, 217226, 217227, 217229 }
    },
    tier30 = {
        items = { 202527, 202525, 202524, 202523, 202522 },
        auras = {
            seething_fury = {
                id = 408737,
                duration = 6,
                max_stack = 1
            },
            seething_potential = {
                id = 408754,
                duration = 60,
                max_stack = 5
            }
        }
    },
    tier29 = {
        items = { 200345, 200347, 200342, 200344, 200346 },
        auras = {
            seething_chaos = {
                id = 394934,
                duration = 6,
                max_stack = 1
            }
        }
    },
    -- Legacy Tier Sets
    tier21 = {
        items = { 152121, 152123, 152119, 152118, 152120, 152122 },
        auras = {
            havoc_t21_4pc = {
                id = 252165,
                duration = 8
            }
        }
    },
    tier20 = { items = { 147130, 147132, 147128, 147127, 147129, 147131 } },
    tier19 = { items = { 138375, 138376, 138377, 138378, 138379, 138380 } },
    -- Class Hall Set
    class = { items = { 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722 } },
    -- Legion/Trinkets/Legendaries
    convergence_of_fates = { items = { 140806 } },
    achor_the_eternal_hunger = { items = { 137014 } },
    anger_of_the_halfgiants = { items = { 137038 } },
    cinidaria_the_symbiote = { items = { 133976 } },
    delusions_of_grandeur = { items = { 144279 } },
    kiljaedens_burning_wish = { items = { 144259 } },
    loramus_thalipedes_sacrifice = { items = { 137022 } },
    moarg_bionic_stabilizers = { items = { 137090 } },
    prydaz_xavarics_magnum_opus = { items = { 132444 } },
    raddons_cascading_eyes = { items = { 137061 } },
    sephuzs_secret = { items = { 132452 } },
    the_sentinels_eternal_refuge = { items = { 146669 } },
    soul_of_the_slayer = { items = { 151639 } },
    chaos_theory = { items = { 151798 } },
    oblivions_embrace = { items = { 151799 } }
} )

-- Abilities that may trigger Demonsurge.
local demonsurge = {
    demonic = { "annihilation", "death_sweep" },
    hardcast = { "abyssal_gaze", "consuming_fire", "sigil_of_doom" },
}

-- Map old demonsurge names to current ability names due to SimC APL
local demonsurge_spell_map = {
    abyssal_gaze = "eye_beam",
    sigil_of_doom = "sigil_of_flame",
    consuming_fire = "immolation_aura"
}

local demonsurgeLastSeen = setmetatable( {}, {
    __index = function( t, k ) return rawget( t, k ) or 0 end,
})

spec:RegisterHook( "reset_precast", function ()
    -- Call soul fragments reset first
    soul_fragments.reset()

    -- Debug snapshot for soul_fragments (Havoc)
    if Hekili.ActiveDebug then
        Hekili:Debug( "Soul Fragments (Havoc) - Active: %d, Inactive: %d, Total: %d",
            soul_fragments.active or 0,
            soul_fragments.inactive or 0,
            soul_fragments.total or 0
        )
    end

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
        if DemonsurgeHardcast then
            applyBuff( "demonsurge_hardcast", metaRemains )
            for _, name in ipairs( demonsurge.hardcast ) do
                local ability_name = demonsurge_spell_map[name] or name
                if class.abilities[ ability_name ] and IsSpellOverlayed( class.abilities[ ability_name ].id ) then
                    applyBuff( "demonsurge_" .. name, metaRemains )
                end
            end

            -- The Demonsurge buff does not actually get applied in-game until ~500ms after
            -- the empowered ability is cast. Pretend that it's applied instantly for any
            -- APL conditions that check `buff.demonsurge.stack`.

            local pending = 0

            for _, list in pairs( demonsurge ) do
                for _, name in ipairs( list ) do
                    local ability_name = demonsurge_spell_map[name] or name
                    local hasPending = buff[ "demonsurge_" .. name ].down and abs( action[ ability_name ].lastCast - demonsurgeLastSeen[ name ] ) < 0.7 and action[ ability_name ].lastCast > buff.demonsurge.applied
                    if hasPending then pending = pending + 1 end
                    --[[
                    if Hekili.ActiveDebug then
                        Hekili:Debug( " - " .. ( hasPending and "PASS: " or "FAIL: " ) ..
                            "buff.demonsurge_" .. name .. ".down[" .. ( buff[ "demonsurge_" .. name ].down and "true" or "false" ) .. "] & " ..
                            "@( action." .. ability_name .. ".lastCast[" .. action[ ability_name ].lastCast .. "] - lastSeen." .. name .. "[" .. demonsurgeLastSeen[ name ] .. "] ) < 0.7 & " ..
                            "action." .. ability_name .. ".lastCast[" .. action[ ability_name ].lastCast .. "] > buff.demonsurge.applied[" .. buff.demonsurge.applied .. "]" )
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
        id = function() return buff.demonsurge_hardcast.up and 452497 or 198013 end,
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
        -- nobuff = function () return talent.demonic_intensity.enabled and "metamorphosis" or nil end,
        texture = function() return buff.demonsurge_hardcast.up and 136149 or 1305156 end,

        start = function()
            if buff.demonsurge_abyssal_gaze.up then
                removeBuff( "demonsurge_abyssal_gaze" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            applyBuff( "eye_beam" )
            if talent.demonic.enabled then TriggerDemonic() end
            if talent.cycle_of_hatred.enabled then
                reduceCooldown( "eye_beam", 5 * talent.cycle_of_hatred.rank * buff.cycle_of_hatred.stack )
                addStack( "cycle_of_hatred" )
            end
            removeBuff( "seething_potential" )
        end,

        finish = function()
            if talent.furious_gaze.enabled then applyBuff( "furious_gaze" ) end
        end,

        bind = "abyssal_gaze",
        copy = { 452497, 198013, "abyssal_gaze" }
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
                if buff.art_of_the_glaive.stack + soul_fragments.active >= 6 then
                    applyBuff( "reavers_glaive" )
                else
                    addStack( "art_of_the_glaive", soul_fragments.active )
                end
                addStack( "warblades_hunger", soul_fragments.active )
            end
            soul_fragments.consumeFragments()
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
        -- startsCombat = function() if prev[1].sigil_of_flame then return true else return false end end,

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
                setCooldown( "blade_dance", 0 )
                setCooldown( "death_sweep", 0 )
            end

            if talent.demonsurge.enabled then
                local metaRemains = buff.metamorphosis.remains

                for _, name in ipairs( demonsurge.demonic ) do
                    applyBuff( "demonsurge_" .. name, metaRemains )
                end

                if talent.violent_transformation.enabled then
                    setCooldown( "sigil_of_flame", 0 )
                    gainCharges( "immolation_aura", 1 )
                    if talent.demonic_intensity.enabled then
                        gainCharges( "consuming_fire", 1 )
                    end
                end

                if talent.demonic_intensity.enabled then
                    removeBuff( "demonsurge" )
                    applyBuff( "demonsurge_hardcast", metaRemains )

                    for _, name in ipairs( demonsurge.hardcast ) do
                        applyBuff( "demonsurge_" .. name, metaRemains )
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
        id = function()
            if buff.demonsurge_hardcast.up then
                return talent.precise_sigils.enabled and 469991 or 452490
            else
                return talent.precise_sigils.enabled and 389810 or 204596
            end
        end,
        known = 204596,
        cast = 0,
        cooldown = function() return ( pvptalent.sigil_of_mastery.enabled and 0.75 or 1 ) * 30 end,
        gcd = "spell",
        school = function() return buff.demonsurge_hardcast.up and "chaos" or "fire" end,
        usable = function () return target.distance <= 7, "target must be nearby" end,
        toggle_terrain = "player",
        spend = -30,
        spendType = "fury",

        startsCombat = false,
        texture = function() return buff.demonsurge_hardcast.up and 1121022 or 1344652 end,

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_flame.lastCast + activation_time end,

        handler = function ()
            if buff.demonsurge_sigil_of_doom.up then
                removeBuff( "demonsurge_sigil_of_doom" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
        end,

        impact = function()
            if buff.demonsurge_hardcast.up then
                applyDebuff( "target", "sigil_of_doom" )
                active_dot.sigil_of_doom = active_enemies
            else
                applyDebuff( "target", "sigil_of_flame" )
                active_dot.sigil_of_flame = active_enemies
            end
            if talent.soul_sigils.enabled then soul_fragments.queueFragments( 1 ) end
            if talent.student_of_suffering.enabled then applyBuff( "student_of_suffering" ) end
            if talent.flames_of_fury.enabled then gain( talent.flames_of_fury.rank * active_enemies, "fury" ) end
            if talent.initiative.enabled and debuff.initiative_tracker.down then applyBuff( "initiative" ) end
        end,

        copy = { 204596, 389810, 452490, 469991, "sigil_of_doom" },
        bind = "sigil_of_doom"
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
            soul_fragments.queueFragments( talent.soul_sigils.enabled and 4 or 3 )
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
        usable = function () return target.distance <= 7 and settings.retreat_filler, "target must be nearby" end,
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

spec:RegisterSetting( "fel_rush_charges", 2, {
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

spec:RegisterSetting( "retreat_and_return", "felblade", {
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

spec:RegisterPack( "浩劫Simc", 20250814, [[Hekili:S3ZAZnYTr(BrvQWJJ0kUKdfxVoNiVYND8L4YNJRSoXF4QSJgroKASiNHzESYYLk9B)AG5fE0naif1JnrFXYlh8Or)cD3aO7po6J)0h)WIWIOp(d(d9Nm89JgpWF8zF8df3Un6JFyB48Rdxb)pjHBG)7Fk8tPZz)6TRtdxW6AEAz2C4lFiEt56WI40KVolCzXh)WLLXRl(ZjF8sKHF8xoXh662O5F8hM8fFXh)WvXlwev12OCyco907V4NUk6(l(5Wm4)exCvCY9x8HOW8u4VJV)7yd2PdF)PJg)hU)IVj60FmRmjs4N9HF(VTLnXlU)ILPWG8t)8pdJWya4ZsxgVga5F3V7(lUQOyB(F4TVDfmfLxoyE6M3M3UsMZwjS)983E560lFBXvr3eMDdhAE7xnN1KFmlonlU42VpoVi)TlIwgwUUa(7M0KRktkIYcUIHYgWgK7)o2mQGOU)IVoDZMy4VF42K5aup8SWHJF)IQg)nWca(T2L1O7)o4d3FXFpmlo8Y1r51logwPmhWxfzXjxhva)EycBLd0Gi4NwbnPSGJbH2hxU5(VlKd)5d2MfbR6ldloz6B)u9W(gg1EA9ynkihgJ04f5V5tHRlB)9bJgCvyEW8001lsVjPN8pNxewmim52GfBZ7Du33IZheVbibFkopArqEd8eamArBcVokBhGmFkiZhhY8naz(UazaM))EnirSgO21y(oeErkWobZy7VD)fnqqdz6pNexed0(pfvtF(HO5r55Hz3cKgOxxd)(64KOtl3Yjy5XlGFba4KfHzIdmaORJ2eLuWzKU)cG9(V8n)fg9(xRaKBsZUggILlV)IvrjalWCg0KSiMJAHbibqDHlynbMaqqmE5TC2KyOnFkErz4AX1gh6xwwuMfbyiOpUtKgfmheq0yDaS9MWfb)ZYOOK8GnSvyr0D3j1GFPm56nHr5fzPqtIwfcTBvsuHsZwffMTc(Hfrza1DBywuW1r3MR0QSWpfLKwMhCvAs0Tbxw(B)wuM6iLfVbyBwe9RADUyzyYQGI0Fnor5BxUomVytiJvC8WHdv(68Ymo7ubmRbXlsxR89TrzlJxeZamaZ(lrZls3nraeSRVnSRVByxFNWU(oGD9PWU(gWU(gXU(wWU(peS7Y8GIyygplWFBmiJwJGZJkcUmnPmFG4wbmDfW(sbJHgp3LrpBvaOYQEZIPdFt62PzrWyJ3384vXRdsxgSCn0z82eVztA1MkbHLzHSDjQBg8XfX5zLBl4QV(2sMUgUkHQ9gbmeOaiIPBqSpkOdOxbqNyqkaNnSBHRbnqd4B2fa0jyR7J7p6333FW7ooSOa0tcB(beoVJ73xST5LzRI6Dz5YLd2eveUjnB7vP5a1QCR3XJpzKVN3j8VQSQgKZgZJFx1hlya78W1bzrfzrGk9YThpAiFr(bM(mMcS5xfn)6ATxDB9DXp2Qr)c2qb)3iUUp2iYunZB))lxyOAB5RyFMe7uZX1TrbJxBoMgpZ7ViSdkFpkMKnSQuyPDCm8vgJJI(NLXB3gTWLn5(PygUz8yylG4k(JczKz7grSDRk3c7qWefYL3qleM8LXZJmG5yYyJdotugRFfPVDNYkOVM)P7NV7oE7sAMVG8MPRInz20j9iBrgSwHDapF4GjN0Sh9aqb2QOLLDmu1TYRxFYbIdBM1k4dlV53Dx70eDBuWLrHBAg(t8NPUIBMyAArElhEiZQprsZMA(2fLrvMc0WCdyDbJuCJMuVLWUrAoeimVEnq1aCXRE9DYuHE9fSWt0OqrPQwAtnIFM)qpV7URVtBxkmdJiMHr4ZaN8(nPLCcJQf8vKjoLJtwlZROICZbfmTuOdClkdtegRfHamkmMKe9fCOiaW(q)QP2DAmGDGGfkBliGEbyFWLNB7195RGTxJyFDoyKAUaEJtzu)Q0hXgzVEgXBQ0fQX33(4Js55uL)wETSYIiWWJnGsoWYyyJIB4itWwhMzh3FreW4YKjzgrxWCxnDlBNvMArWDWb04BE7wuJOxgUgMo(gxrG9vW(YvBfLMWhMAgGOW5xbmfG)omqissRk48Bq1)kG1LQ5im7naZA88IPJEt8YPSEgW64GW1lYGblgu0XwjvEA()9HBbr0)X9xaEE)THRxFzyRgLTrPBzSORJ(u061kBfIo1lZLM6Jmm3819xv)R3FXFT(NBmYjmdZ6P4K5YMIW13KfLWeycyt91rd4U(X)WQ1HGAjW(PYSSBbvq9Aj7CRwcweMWvn1B18fnCctbgTwvqvtzpWIRpfWAZiWqMWIRcYVjkABf(tcG3gd2(uUnyzw4kMxAVHfmLPaw9nv8QlzJsfUHzA15t)YHgxYlJwhCzygmArOMGj89E9BxCc)A7oEmOFt4VE8x0RFL1obaJ4M4O8ztbZ3IZaJcka79bN(ojlmEraqYHXpCXcWw70YeW5a1FooPBqX(6SVCONaqjBXxnyD3DkaJVx9(7IRbW8WEhPa2th17i15m6xzInEky05xfMMxZBWq8ySmalaodtFrwHf5t9rG4EfXBIMnsLsgMKeFvCLzSpkZBT87Fk6641X)dMi0MuMvS1SKdQK0YdQg8bm)PyA5xCrRDdfxX2rHXDd4qMET6nBQeg)panq)p8(cC5llyQ3e01nqz5kpBTly5vwNOjPmBXvzXRx3O5Ez8QRkcQ2otJx(St0qtEN0XXX6plwCA9BmZBJ(KgM11UE1Iz5aEcw)GmciRueNClmaAKif9glySOe6B0APpElvme1aQHBEfUAk4dk6Z86jZlD(4ElI4Zay2wemXbxcuZRRikvtDyw7MP1StvgBpUwCfv6EMVbZFpFeGWUmnpVx1cP7NvfGFc5So7rgtpZxE1oB6OH04Ec8JQ(ny7fmJaAThvvpXpKY9(h2IFdJld2FhMfwaabtmJ3KZ0oeMSQYc0SuWT5)Aj8PQWEF)fFppeOmtK(AyIL)9)ZAnl8((1Fdp2ORwXmH4MywBVkA927V4A2ENxmhg6sU0LRRNk9om6ptH75JM0RA0BnMlVhIqnJErSje3f7kjCjKFNWOmnb2hIB1Y3Z99Lfr)vXRRmc8dBJlIQCgMHjvI27zNYDQc(oSHqexJ7YOSmoAIHj52S3g2x24jbOkiO24cLZMug(Gw61KALggVg5RnHzx3k6o1)0AudyT)8RzwTgWN4Cdo5zVZU5eOb1gZEFJ2qzAzT8cPUOtOuLpBQTLZjKRgpujuFvjucR0deTUdOIT6oeTQt1yn)EQw9aCIYtNs0ZydTMwO6feBkwcg)X8LvZIsbQaIfLZYIa9eGfJbmPrpR7GSBKRztu3fyFwv6OkTFQvT6eQpnBc9AdXfagQkRm)Q29PktUemGEra3ougiOb297cLsugO5WHGgjpOTXn6IoLt)96OAD)f1H1Qr70F82i2iYdHuRtM)edOMhk2A254Uqv3JASY4AJvJdudDqnsTvgk7pexnDVMyfNbcMRbCDq1bPsQ(UH(awm4PHd7HGMey6QBf4BA8QvGXSDwjOZNQYjQHd08TthJCefkH2m0zalPGFPNpCaySL8piy2OM5vtfAAp7yqabQg4TUZ)TN236obwbBz17xFLiBhMCB7U1bAMBlgJiYMpB8qp950hzo93T50qZzZPxh37JkRgtHIo)ZtdBsFufwvUEcouQESms7am7DIHeUwpw9)EtklyiLBSgpGzmNcmzZslHZVvDb1KHU9cycNOYI8IYfWF5gtbnMFJjeaa5tGRvnBJd)p6YmQrPexurTvSym7QeIlZaA0sBr36(gBLkF3DKXfSvk7WzcvhBP4bw2dlcACgg5ipryeelKueYWkqo0l(mYJhQIIdzlbMocttstiIKo9fdwBT7qfQwkyouawd6qgoyInAEZOTon968G5HjbG3OR1IQ1inN)ji8SjPf4vLXF4lwXMz3tkwCdOvqpHg1zWyotHozATuA3atDgMTn9enmlIb11iHWaM1Zbq3b)rBWmxwMLWcRYnmqThmvS5sq)VOMzKGbR3bnAVsCODaEnpahWiDJa(oaEkbUzIzVXvCEbX1cHErfq5ovaAHuwZTdd8xN5CeZA4ePCEAKO1(6gquZQFegtMNYYVbmf1Kkh3M291zssGD2GaEysopqxSXXMNeNp5KXhtTTMToxzeTzoYJ9rzUgpSjadZVD(A(zAcZo0pGzi56J9hm5yo5q9R8qWk56t3LKWQMHztm1ie(fd74RikisO6BuVjYbhX2z1kA0TW0UlciSF3JI6qJ9pEYNvEozEL4QrJ7eaz2TkZaear6b)wWbjfP)ofAsMfP56WjtmiLt9fQGclj(Vxm77N4lZtjv7jpsZfihKUoz8dzJrl6UENEKziCl2GFMv76MpDypNCeLlsQVW1b)gu57F8LHDXpRNjp5WLYmz4HbBDN2kKPzE3uFQZ6E3v6stlNscBgS3PfO98ipdX96wfqDYn84jGyblqRmeRzsNAy3LeW72LXZJlMn9SHN05hC9f49yMlAhr58tRi6LRJb)qyDY0rWOfB(AsAr0MTGYsK11dqbJ(5DQG5rryAOEWuH0BeocznRHBIhqzg)wJZBFRr55PLRZNhMje5O5W8SHrSVmRe(T4cgkRwrfW8J4GKPnhSDPvOjgTxgc2CMD7SPFXWt1j)1T6un6CLA6rtCiQfYUfYV)sNPsCq8cYjVPS5mOM1OwLS4mfPL8y7bRXv1M(z4yQ29JaZFIkC7(1sQ6gXhCj7CJnZQIeJaoatWDPP3ZWsMMT69TCZSlZgh8cxpB0GHJQvrQJAvirJAnhrwMsNtZ05L98UsvxskWEy28WeaQsZan)f7fxhxmA0WHcVCJbc3DdysK82KV9BFtBaleAwLnpnegQPJglyOMeysSJuBaqfLlQq1ic8NXU9UKMF1ziRWGPH8v0i01jkN9roAE(54uVliSnyaxiur8x54hng0MzcgzrDNGA)DFIFFS4VdWhLv9kE70QKV6ofduD(PsiV5SzgjtlTE97FywreNddwGQvShZJMJ9XM3dF4nZr6TVSK96tWsszlA3ePDw540m(HEP6gggBL3EWxTnL9RCTFilpylsSlacZFmsflTxOw5qGkoPXjFk9AGu8RWQg0xhWgPQdhyB6naAmozzzESWnVvF6Lb0PYN5K4CjFNSRFcob1ovjFVSBFBeyVcZ2pY8KFo7mWyBkYyr2exWPEDV8IRdZwCl05vWwsIDf7Hni8zT3fj1AIDNfatp2uTM0H2QnAWcnrnVQ0BbQ1VBAHAw8gr(kdC8uEtp6qdQJUladmzln(nj1GlUvrkP97SNQdhqctU1t5zJyAMhzzMrCFxAMhjpZEk3e0r(u3hwLFGgfB4syHo0tCJ5qJNQI3yFj1sEHoq(LKX)nOngwhO7gQYbPbYwyG83BoihE3rknPm524i(l8kaAkOfaAv(gvordRaugr)9Mt0HxMLstiwb43gYDH)9HWLsOtL7aRBALnl8JRDWakxAvyxpJb2pPrsnADGtOUHGK3sHldBgXOonQS6sJ3EGjgzyuSHfqz2TTHGW3rV9gYbnIgtk)Ydnhr0gBzPUns6MSkyAkw4WMqCPJDLlar8MF0)mpRrUCBYrRNdXhrBTbyR3(Hjew0TdGlEmyedocjoXmu4i(jeyCvyvLO53sQd7ky(XUsOm1vQmw6VGrL7okbXh7D3tUw65aJRo3riqk1ECyMAhNzI8wYHbggr6KGcq0MYtoCZlTZqYZn4d1GFzWWb5vbdnGX8N)CAppka9KzsVLz32(h7MXu4M1V)wezYI(9s6anF9Wzoiys7lP)NnM2oODtWmU17QmmOa5tfdJLj)PGF5z0mAL0U0Ht7LltovQ2GgkAYfh4attGKOqi0AuxWVEYyoueueMFT5JKB0etxEZjepAmcleDxVpUBzvk(TAvM2DUAuBacLVYUnBkSg8riPG18Sv3w)AGhnc(AFh8veZ6PgPPzt)YH2USDNpDIwEAXYmHi366mPjK6tqdN46Yx)6MiCPo2ZexJtHzWYfDrwjL(mtARQJjzkYyi)mXj7eX6ZlEvQWT74I10MSvWab7PEItY2mqUkjyd9eD90cFMhIBH8ltIHRo071UiuVkqBfrBvGoFDArBkb1vryDjycEAlce0gjztwQ6G0jAd7vKHYFzG1(uSOriY6rgEwDEs50Q7Myg9oyD68RtG9HxFT(fwSkxSQ0pLqVj)rcRFuAfbpPY8Gf9db2wLduZIyHuWz0vG8Ld7HHhxfZUHwE7g7Q))UWUIOR3D2v1ZdXa7QVJSR(kSRyXBw(JwzxnPcvzE2x2v7zToJSR(7a7AtQnI8(pYA3H89pD2KUtLltmFHy6EvpLfOvPUuN7GQGU9n2s7AqSQ(7H4zBtsp2LuYckAStmMmxJy51JvDjnuUgzc3GfT7XqDUaonlOCR8LyODIAUfOQk8S(ePBAO7aZ8fbla(iLmnC71RY3WiHMO1eVmnkNRJCVLESs8UQETFQVyTNnPN2TNv7XumBesshbxIYYBFXeilYu1UI1UTseHtGCyfUVqKdQHUJC1Fvro(3HNC)mCFgLU6NNm2eAr)wOJJxuPyggsSxC5oGswk)605SrJgoeDVyMJp6)CNehLs2Z0UA0MWrU8uOrirAbHsFDAoN3Wx6(dXhBYXv)wDl9shoBxhpTvVCp7Pm6UlRW6y3TUVvz2PJNmBisAfOrl5yHh3JO64AnoVFOW3BUk)Zg9(DtiGe2g(udBkstVCqA63JBN4ZEyYegGhrZ7Q27z4H0yU3p0iYqz7ukY0zd5jdNNs6K6RIXcOjAhJk41Z0h5N2sTYA0TSOx2hRTMoLSPJ99MzKui9grKAhBBDITSXDTSDFeIlDRP7DbXLnwnVs(TD1kgEnNH9mHQCZ5n3FXx9JFpl3I9Py2LYnVl1ZMUOKLyeVmI5UgRf5LRlQ(EsB(OTGL2zdBYaKncDvzB7Qex5x9x(J3Fr(8Oea7NYsa3kYMi4lwfmiGLXUMWqDnPuYwSGOyqltZtr(LefWvfkjERc1owOMJHjNpQedMI2PAGqC7tmFPqSLGyMB4kPsrUTFV9LzAjfM11YXuOqrfYVKHEDixZE)Qh634H9S9Kv0JaLHv(a07IRtRqmOg1TS9r5uJWNPpYQOhgb1wV6fDl8XqWGIxsbXBMHWGhr8STK45lJZAk3iuA3Kbt0dCIijP()3JyjlBEZdEjR6gJb549gzBkJYn2caEOXcpeyX4ZHTb4qCiV9bkR)ynD6DNBu2wr2YECZfxMOISw0A2omOCOAAnBUIRCG1EQnQ7LvB4PQnZUoErLjc2FOPdvvxStRPg)QnN5rArueQe4XGbXjfwdvFoIixiy(pi9OxvMyHNnVH0QKwSFoJ6ffyXuyumNqy(SK88uFhEydNUB2U82Jn9cs9R9l6DiPrQhGVEkPt)g43AMOWF3uiO(M1Bi3n5nH6)T8lbxpLKzcjEyYTcuAWmRiQMYC3DSfuB1DjFqrkSWMHF1TAyxNi5Qzv80n86hDJAzqJ0eQ3NVumnaRhrYsi1mJNityAYws8zpNdhnzocBwdjpN7CMjXnKHf55NpmbYoWeqKm3SHTo)VOP8hu9gws4HyIrUOxGAtMNTm8ab9qZ8i75YcmBcFPVSW3iLkOtvHF5KMx8n(3AIDj(x)0EK705hTjQryIPUiuZtKp9wIm)Gjv)kPw7r4RkLWWzolayWoro8PMFSWNYDP6szWwxT9ZBNGLgYBX1)tj5ySJtVChZDXYSNNp1Ne0ALWEEaTzeqgry6ey505bfzILMysN85XjeB61Cpq(XBGgFhCXkZroOXSE8leID(jID7vDv2w0TCpOnpKvPwCiq5d)mBjzJc5yasrECqOGLPYdZEi0)ecD91nEV1RavDcesL7bE1cTf18p3RsnpiK6(aAMTuOtrL2WswNaiRmFDA40ZGRKJMybjaqjmpwH(rCvZiS3a7QNzNFG5(W5nNVmMrlo6gE7GNPvS8WusVpJS6HVwpQQwC42gLyxSgRzSC8H6bLh7ry7OXasTJWlClQG7c3dHXOuPHmYm7KTxJjXBU0wUQIG3L8IoQydGb)wSORWGYycJEeIShb50qwvLImyoEqyyu6nXD1AnxIHBVJWuv1JwPhkpQHOUUxQYPc(kQHXudbA(WuW1rPlmAvYjRPAiNvkNLurb9QghaiT2sVnVCo(TrRp9dv4XUzEPET7w4UzCWkgZkQ4M6B7nc4CftwzPGxvnx29MGCT9v0dUw24NPQWz9cUIJPmBvDXO98XTf5rKY60jyBkOILikQ5UuMHmwxg5dU9cyYNz1LX9EvPJQo41LrjyeXcCxcqGASfKxxNpTRgKHXW1Juf7PTgbCowarBL0PRsw6RpvZ4F4RVzJFuxEUk6XydjT1svF9EeDrdby9qwz9mRv396E34dq5RZIfJI3BjNyaWNhB3rLzthjK9vXMbpl2IWkUqALlUhQE8N(YfNOZ5AQRmlJ(4wY4OHku3v1J2LyZShR9ZpJwAAplIAN6RViS8sfEmxc9RGfQcCc7GKjAH8ZGXN(OKmDFkmHNCyB9oPL8aEsy5Sa)6CeKHYb34MiKOSIQmbHw95yYOIZho0Nn15SBmYUylzRgVje9Z0R)DS3XMhwpfBXEy4yAi5eZQj9ox6sGqn1Uh0KN2I)NJwz(Cv8)Oap10MN5JzuXczLHx)kpyAFzt3D0vn30w9iBA3UabrAQSWR1nSD0mhFpK9ffJ0dka8AbaCxQGyhWca4d1Kuf(DP3Kl2It38gxwWthzkhjiezFRLTDV9SuVTVCh0u)xlaH2aOdEbiK0Qy6nVnyujYbwQyPuBaVu7rRwD5l7FZ5Qj9D1YPI05SQzA8Z2kPD)jdRM62Olo5l79L0P1oZ08QP)rnY866GmzNVYOPCwx0DS1V7Z0wAJ7u(Qx4XuRszAX(v5K7myKjjzJ42QQov7XAvzeEQQLCegwPI37zAJnl4zYB4RMLn7ObEgSW7mBXmHNyXS)2mOV4jEE2cmG09oSlye6hU99xOmu7zv67XRQ8DHnZ8n51uCoR1aN62SOwHuofM7cUESCSlUyy3hLNSoYDAUpSpWVVt7PdgmvnzDktB6YjSlTTYwbQRgT7AMHaABlwH2IeOjmhaQN0OSXTaAtKtBe245isvOIpQDvTR0XbPDQjQq620OBNXHvFi7x9Ur)IHNoEOzurFxXf0M2ZuuuBCfhyH9Xt5xRJJ9rkqLyU7ThlYXclYtAwHS7pblzFfvLZEoEYWt9h24MNsLW07ySJx)0XV)fh(6bJR8nTnaVzUj2yFTpX8QUxhFjjD5jJc0mjYXvqrvNUvMaz6SHEifEvFxI6hT6eTd)enCuoSXXX9hz60Xpu4pBX1ZWD6YbBj46kjTM4LdwWQvMeln6JOXKvO7ZLeGLbR7Rz)bvPRft7SiLYKnu8nGnFOj422GEHGqTs8L(RSX6JhYLJMIpYpBRu1LKcS)iviCfUEsN85xHWvfNz7kxI(yNhp8jUG16CbOTnJt6k1YeC9zz1M9GrGFjv)xTqw7k2RklJdwDEvE(oa15veK(u5BmI4ekFNp)CTyVkVMETyV(AXELuI(1I9QZCq3zVS(5urB41I9QdvPktCPVwSxTGGETyVUlf7vtyYx6f7vJCbVwSx)xKI9QjQ8ttXE1ee84wSxnnZpzf7vJaXJCXE10C)AXEvAR2xaf71hOzrpoM1)AzF1gRZ)6x2xnXFC5JDzF10K)Cw2xLHRxQL9vtyVNSILjhox)VvL919Qgs(ALHTDM3Rcj5lcMDNiwFEXo)ALH9HuzyFvQ(rrQ(1Yd7UwVnvdOlbJ5R1iwsvjoxJyDGN91AeRl8SQhJInE2xluSg4znxOyL5zlEwkuS7BGK21iwv93dsLDLkjiGYRoDSXi09KJ0)YHE0vN3JOtJm9K6XN7fNx9bPVHhCa1sapxqs)CyqzqmRiMuALm76HW(0ofOpN8yTQb8Y8xqvdyBaJ7vdyTrYHstJHEl9YJ5Dv9wF9CxnG1bz1hRiky7WrGkpS7w1awR7p1vdyna4HxnG1gsSKw6oGswkN8Hww(uxnGXGiRP0hesKL14bOsaRnU6xHELN7g245CwjqJpB8qtOnI7ZFx(ieKEZwmpmVOzbBTuY6ojszjQo6vdK(l2JTV38c3L3zJ7ZsX51bbzsy7XUIgBtJWlhK2EwrJ3F5Ad9T4jSAgB1Caks0JF1mwd0uFZEwanr7WubVEM(4Zu1mgrddAHLzz(HVAgtKidQSFJ(12146AvM)JxRVkU5MXn9dSen4Y0KYCwsP4MWSBIlUkoHf3ZCO5SZMCUN0nWxc47z6rdRUbIyHcewoK9SNshBXqSRJpDVi9Mr5LoQ)E(MowDkvH1DOI80bhupb970VrA74RZX2tlF2ufRRRzg3Tn5nyNHPhJLPU1h)POAz1mE4P6ULH2023Y4jQEnBLQW7kMF9EDpzy6iI2(o6zNle(BlY076skjozyW9qjRQljNsrSSXSzc4zbwfmgn0k0ZADlOE4nTXxi8VYt6RMJPGOMRk2tPcyENlGecUSg0L8erRR4MgBKGVGyMqLEus1b0Y2wy6h9EBnrkB8QWWF8ObtS5Qqf2f7BYQyWdaYSQltanBIXBoIiOJ1oqSZ6fPvnxPpBupD(CvkOcB)(jozzRl0Tf0anSPEjDz1zhNZMBBJAkYASuaE7MwQsMZopT6Mbp(o6uyLhb4qHfOMuBskJmu2Dmf1X9RE3FywtwsUXe7AJkAmDOflC2rUIxcGmsgROMuCGwmV45P0IsAvohz8qRLKn9tO1aoza6tCZPvO4PvSS7GhSU1RR1jacVSWTY0c7KADf02Ddwk771Txg(1c225yF(0j07DO5WGoc8YBZZdxhSk83IQ270fECUGPvdJBt0iYmfng3yWbqnNM097YLuWNXc0VrFPnZKs3FchVAml10hpNN3kjK)mBpltmJwJsnYpr4mF8OurvAOgl6cM1gCsOFXK5GDzXuJefRYjTddklIwKLruRRiz4WPrI7Cc5s1sE0D6eMP57HFW15e19ZDcC0H2AbfGpJbWos1qhawUA1d94PfrkTzXi1uX8X(ue7DTuL(OsSvndXbY57ql4Mm72nyZCpZ4X3DkjES1UdRMD)yJp7JwY3m4XyZZUh3esBS)vSG6HKu0kuAvxmcffg7jJd8ZlmwteRWYNXyRdVD2A(hbwvd5XRJhV7eaBj4ZNooQN4fMZeDmT6oCjl6EIdYPO2wNyeZrTgsEPEgRKCiHXWurczNtsQQYk78aWat3nuwP8SBI3WjZ42jl1uUxH1WzBGfxKMYVDsgOgQ6HK6RTful)YZ7HsC8yxpiPQ0o5ECqcJFqhKaEafKoOwuA9oudumEIH7Oaa)KZ6WF))S31xZTXTr8pl5HkzknvHK2Xj1Pj9H(wMm9f3(uNAXZIuYS2uhNJhJTNrd)S3dh59pG9p)wC3P4gR3S5T63UayXIDbwSalQzVa27uND1cy1VWFYKXsnPkjxm1xsNVP1JtYD3ufPrVo6w79VWB(sG(Zlis3pTj6spJztQCcH5mGOZJwQ8TTUk01fi)IjJ3Dd23qd05E6)n)JukUkrz3lQGKhtYNAJMHq0fvfQpVES4ktBS7nU)rz5Q3T0SML5MnxsONRIKoP7ZmIQbpPnTwz)QsRGPyfsR1)tFpy2tOjusQIXjWmVJCARt5urRFNtf1bRXH(ObLYCanHG458QdDY3eJEnO4VjYA9w1RPjv(LVOU5WMlhITtRP7ZdwEtv6DQbrSLUMeaQHHWCJeXElLTLw(Mx6iZljEmZ6rs659ceYVyJF0qsVXZ0Ek7xDO96hzEcr8xjh7TLMlkczhSp1b)WdLQr3MLC3McjQq1jTq2(z6kcrmRzZ5csOhrLkisRLY1z3EZfEgnUhBVxH)YKm5m)QgPyar1TzLfaceSbAX)WoYUr9keG4FJFyAqN9P8aw(ioy2jNlKNhr9D)52Lq)LuDsNrJiW6Y3qAfsBN7)sVzr7PGZBnQS(nDRlpQVSDnL(KQIseo0OCl1dsqvUN7Cq8Bi3imNA7F9ftPXSDQRZSze9ww92IsMzlNb4Hb1HDi6yC3XpVNeWosR18bzmK2adIsV3FtOBkMEYLBC4lmAJGnzliwUhAE4XyegFVg4LeG9TMCve5ShH8yj8mm3hv2UJxvVv9bJ4mnb(SkQz7P8cPtS1gSKFF0V5pjZa38NXu(z)9VDhSfM0YPAvIL59l4bLNdHjtasAzvqKtRgPPW8RFQm329hXmLwpFydwH44L1(fmkjGBcEPiDgvWXI7(rRLVo2z7CBRY70Pxnto11cckG0yHFwftBvi4EIgU8kyiz9XIfzg4XB8LS)wXICWAUNPSdr89YelMrx7cQwh6y7Mjl2pJ09iTTVIFmPxISAFExPKyUtLaw3411u50k8uEo9Fzty0aJ28g6rS)Pv(o4x9qkBtz7nSEK6)XU3WQbKUjgBZIZbIftEeqozGAxClH(KUT7CNADRdRwoly1Vtx9dxTa068wnxKcmFton9)p6DA54ovJRCPwZDGTJKKsI7S4JF(SwTXCHhpj7jxYJgxsfrw6Eqc69uP8HEryBhNiNJKL)S3ZkTycPi5tO8zvWDgdyHWf2aQFZ75JcJ)Y9XEKhIM1yKvQRxnZr3UVz3scYl7OC3wWLzYmWriKvU7iirpp(MaqAU60p(29z3789)JLpA3mwB0Db90gnPFoLHE2ZVMjnB7qfFGDKt20dMmYycclUvu2HyIu1)mGdhayo0W2DSEnuL00wEANVBnTSF2rj642bKg(YExTgZugL0r6yV5hFc2narpNQYZaYvQpJFzjsnrPxsgcRNTVapLgw0I5Ysq0ygP43Qo6JIU7QaTo)ywJuTmhRlsCq0AR3j3TItTIJvDTYFE5PATwE2(vV51U6cyXF1B(hZNo)7M(dZE(BE9htkTgU7nV(F(UvhwSEZ20S8dlUnn7WIZVTPC2D(HfzUQeSBo9IDPBkOnzFE6gxYMEyrH2FXQ47U6WV8RfJchw8DV6WI)E69f8R8ZNN3U4Wg(EvvaEEAlYY5P7zZ(0ev2quXndybnnJk8wa(KUUeUnKyvQnaoaSTRfSeq69zqzfau3EX5ibhumLpE6GydrjkMq)oALVyH3cWC6hKKyvQnaoaSI6jbFguwbaLt57Lsw(cETYOn8rrgetI1W0idVfGnyAYUuBaCaybmrXP61lqTQ6XwDRPT8XqjoROR220mJLwC2PpPILmiMeRb3rgElaBWKRDP2a4aWcy616KkiqToPI9zoG2KEFMuj8SlqZm8jv)RIyW26843XWQheHQ4jpS4Fx4zV)0M)ZpEyrrSxzF(WILR35c3yznKFVulaWZlq3(5ztmkLJk4QWoWoLYZgvPxFf2Hf8Ay)bX1T686pWSILpnDKAo4JBaDubhaw9UeAAGK64gihvWvHn21pbL6yHxf4yDMguUJf(AGNn9XBLpwEfNoZ4IocUO9qWoClmAO2g0TInWO3G7miFmOEXRLCZyM42ls(YVsRBYrA3ohGnuZ0uSXgFtiBqXpc52a6i4ceCmxWb9dvUOdeqfwtuKumUf7IuJn(Mq2GbMiKBdOJGlqeLM1eHqLvtu0LXHp6rw(fRvRXgFeKX7PmS5vcJm6TeKzTdn(iiJ3t91Uov7xIvMvxA9zu5fV))RDnvX()GpJkV49)dJ()4OfPU6iGxGdl6i4I33pm6(JJgKAVdGFpdl6DXvpSn6owXa3(l6cSjda(Didn(iid40gRRG9cvwxb5rDnXZWlTflkYmWL(VhLY47UnweV7V0mINydCe0KJfZ9Y9Gi7Fe(oSXXR4mtpUORJBSZNrL7yXhb5Mz2hFTNfTzutcQCdIoNTJ5a7vQjxKhB8rqgydE4Sq3puJOxgYcnlzg4s)pynz8rTqRqSbocAH2GtHk9GiwOH3HFwEfNZCJl664g78zu5ow8rqw1gkjjOYni6H2oktq7Bt)Whs)OReoTWLj67oS4JRYwv6HEbBwx4zEUJSk30)qHrIdlE7(8k6UpTm7U3FFhQxU0r8YK8K3MSB1Ro8lhw8Nl(57)SRgVqMy4NBkFWfIuPW0vUZeA9y1186Hs0Igz0Jl)MBGFY0(7k)M7XV0TRooFA3rTOZnwgPaEuc)5F60nT5w)3(4llqY7AlF1Q7lJ0mOAeeuyBROu4QhRDLcvVFkn)5b1ZZcrV5nvS6w1qDb(RAq1yX8w83U4PoCLxyhhBynt57EsLgf2G)3(0G)FOg8VIzTHTzRUjDZBtYnUeHyinvIdHrAX9Fte0kZFxVClL1FcsabVqDOOpjl93wxM7KRsk6zwVFZ1Bl8IEtY752Nc1)MU2Kf9WGTdtEZILbvSdJKeqWrA8e(vR(30H9pxA8cifmbZovr28F3F)73KSAxEwQRK6DxsbkUydOzMa14S8Uvjz3v8dlxLvm8SnjB11VF1NPu4fjgNHyP9aEc4i36YwVPqBE5QpX0GA)DCyl8U52c7txNN(P1ugDiibh8Iv02LVjXf((ZNoDkn8HeHZa9Reblz4mHkRTO5ddLDy1le3re9jNG5hTiBGNCQrnolrNCQqmodXMCINtsYTo(jNHFhhw5jNKKGdU2KtgIWzG(KtwYWzc0KtjkpXksp8kC1pz)hm6F3CLiip5p8XluFPp)7Q8d(INn7p9S5x9YlsYD10NRFNRJFYf1pEnTk6pvEox6yRFDjyYfp)YzZNm5ss3ElRxqx8YJFm3flXnjnbMSF7fZAugeL1V9ldzfZkUQlu92pvE2x6R4nzRDsmbN8(meOyUfoAUsoxUnf85oGkMvZWRnPrnel7vmedBEbpQGdaRL(EnQHAj9kG3HntyhvWRHv8Ep(U0JLC1RVjjBjtqlb00rQ)I4gCgth0OcUkSZb69PPbsQhHtqBylaaJk4CEwLK9ub3zaH3cWgg9Sl1gahawGmpGlFg6fOpvWDSaVfGny42UuBaCaybsmrRkFqGgvbAqpwBSncdW6VjdtJm8wa2GPj7sTbWbGfWefNQxVa1QQ3JQVnRhJeF6PcUtetQIZKRDP2a4aWcy616KkiqToP6rnCn8jvY0gWo9BvXtfCNEbUkSdStPdBnXzubVgwXRwv)Zl4H9wjnQGdaRExcnnqsDCdKJk4QWg76NGsDSWRcCSotdk3XcFnW9PG78)yVJTDBBLJFl(fvRyyFKOSoXhaB)qlqbAFiVOZZIw3ITqKLeiPs6biWF7DVqUxNz2H6IJlQacqsexo7SZo3Nzx6XjYWY3r(kX50cDoWLlfITd3h5ReNtl0TW98fUtAj4Jo8BfKBbJ)EG3Ta6CGlJGJXco4WG65lCN9c(TcYTqbZEG3Ta6CGlJikBnNilOE(c3zpHphiZNs1IKxX5ArOvsvNA4ZbY8Pu))op1b05kN5upcCQhq3R8bI))0WfL06idVapUqNdC5t7po8(NgoOKuhg(9CCHUpCth225lCNfmDAd1vWdcQNVWDsFDoKyWTygzQYPnQ7pFH7KYiWXwEMlEVVWNdKTs2NVWDoC4ZbYmsWdMg6ddQ7bvMLgA0H1Iz5WlS25lChgAOzNH)J8vIZPf6PH7(kpZfV3x4ZbYj1HE(c3rEusQM83AvtHNfCebJoZD6pUTEFi2LBE)8N8UrpmxNlD7CHcsld(c8Apcuh4m9BmMPBq7P(2r16JDWkpv3DqFuMVt0Dh0798LL4ahYA(Ab98dZ89Etpp6Z3B)7)1RnjaPFMVovP854rcX2x2umE0OLV(pgps97J)ZXJC(ovl(VFPV83QpDTJ)7JhjpVLleQvgp6sXCP(JXov4T0ZBp94dsRjV90p)PyrOp0UZ(RzRuhXPxMiCCAEZj39TN6Kes9h82tDvdumRxyGO)DlKbEY5e8la)UTnGr9WVUyv(0jfftQ1JQEI)1FKy6fZUgK25vOSBt1YzAF(e6hFvzpWhbMUPSubWVU85xQYnlN7F7Pb98qJOVg9rRZIfLvRelL8x2TwShat5a(G0RW(AL(V90NeZSg32wS475YFV)nUFr1LiLgVSt9s)78PGNISbigt1sPbcjXBOGHtXcoEK3XZEC14VKrXJrVY60WeITy8wOzepBq8Zu7lHhMC7og4DwLAR1qS7MIT(Jdt4Lj4dvpSyXAvyhLcLrFRbt9riuU00SCgebJRZrnccpx3wW2naLTdGonup7xIYvWqDJfT6zrRTBu)TaFUnaF2SD8OYfv2H24pN8FTAN4VKoITD7I5a9wRgHmdajg1Gr5hYC4dbIdmyir9BTcNZxp5vbYwUDXSLtwLxBhtUIhgSInBvrlNydpUkNwk4sKIkbS9A2zZdB2LmBddd59rKO1dfrJGwgWY6A9czjupphnoG48uCC9BmBcmqxmRzCx4nu3GWuyxaO4HBazjeg3IJYgf36hJBDHuojF9gxhiuGjNcWhqTHQNqqPvRknIjvOvrZtdWOkyR)Dx26PXSUhlETlm84A9Knm4e2TnVBIfFsJ7im8rAa4ZVNDez4J52X1E5po4CRHicLE1IkbfTAparOa4WB1suRNgHYtKOhxHRyRjczRpJyYaXaNRW3fowQsAWKL2rCTOP2wdw2S1oNs4iaU1u7yvRzgQmgHtqRVdHw77MqG(nouzi8buOnWFKdKWcu429HOIj2Y28D0a7IfuXUTnBtb0CXUZFGS74FhIGfnvCOiUXTGy)X6kRauftwopFX3L2iMmFUVjS70GiCiYeLQ8kNJEallAWksS2foqJWAcO4ZLeO997EDwj6e5ijq8grwynXgJ72R(npyYnaf1aqUHLYElR)q69S(d998GXQNJnjgIFaogWcCiAiY6X0(MLbeKRsYg2h1tptU3vxs0dYVvDjrRMjZJMVz3uzUWwlTLNeD6BqhOJCIcDctKsJurH7n44PflniP)CkXUW4TBWoKRIZtlEkdbxJOytVeLddj3GYMlBZ3nS0oJsedlYzWJIrGnac08Ya9DUjaYQld6UCxnQJqqfiXvaUUIg6VSyP5HES9v4aIf4xu4081kaXFk5O)Deo6GRh23l5TWPvIIyXEGDlfMgxRhijklnPztCyYLGHuJIvYLYDjsrbthx0m445PUwCF1MnFRu49268VTC1kGKiejVJfykI7cwXjzDI(JEKolzxjp0KdWqhwitfaIpghkoyrd86o0ssvsDJUyASsVMxia9ytLsQ7dB67do9D897K(wMT5Lq99TXV2Ei(9g48DADCzd3tgAT)0wfe63llxQ7zZY5LnRC0DhoM2Q96n20vRrS(4iw4(ghJA(UJZF3Trnhm(RuYHfHCZc5qu7HRZJu6nP6aAlTC0O4wZDIWfziBql8EnEmJWYoPsHjlzRlcfSI6K0MHfZ3k3THbcqsHIgdAj0GgmHuv8KJfjBG8xqb04l3hQ3gwxSwvCNe(wkcgE1Mkhziz97XYgtJQSZcAmf0ansFqcAqvgP1cAWTSnMGwgSGgwgDJgdxbTuMVIN8JIGgHDSyhK4jObeJzOGwMsqdVBSic9UdSt6piJxVu2iN5vtkEErL4hVkMfB2MDRRG5(Q5EV9uuhD3SYEOL339xIHECNnPG8U1tLnACUSbBkDllSt(rmTmRlYJU2if9Eq2looAofmOYgOrTRJ3Fu076gMpSwNcSpzmFF8k3Uuvp7kvtb60Hsq9fy6MvXGnMVdHGQ890Mc)T6Z9fC7WKNfm3cPSnf572c1xzPXrVUKlZd2ZMNpxiaSMUZHQ5oSTqLScont3K1Rx(Ys93EeOg(XZiPcsXTfMK8iBNBJKxhdR80vlf8RQMapocByZODIfQBeJWe27PmiPWUWw5u9Lurr7gQuG1SUBSXd1YpbKoW(GdPWygW7Y9h1)fPNdlKC6jnOAn7T)aqqZC0q4ojE1GHWZNhL9wVqFJqzCUw08kvZA6qkd(41avLwouuiUbNSBVAI8PvlED7IYkOAnYMI6O5bSUDo9CxdtD)E9s4UutkdGECOQekpMUfJwK5rZD18fv0hiP)WJtHLj2NRWBkuukWQ4eaFFdt1q3q9QRRzQzlVyx5lGvLXFhP54KyK9HHDSDvQVfRbk5bfeunMkGrjLHaWAZeqMSFCOeQNkMpBszLlXI5cJedAHUSeZSEsI)c9MlDfUcHpbxnNMB4AhxAnMVu)SSBwftEppN2CrxxdT1DlUfuowzdShDxVGX2CWJ0c235TLgOSnk76Ty507dWYjwPzFCnZjxrFe2Gc1DJBeyVeOMumBYAbbBtrXIAhDXToaQ5dwJgrqswhN6D6dl6oFnym9OpfNXT9CvZ)RI1i0t2mARiTAb5gNq8IQtQb4uetppkq9mlfz8tG0KRt8kdYu(8PfIDOCkE36ZpHIYPmJz1jknALpvg4Ld5SogS9lURAdYUiQBWUjP437F4H(mSttpO8AQdRCVj3kq86IYdAj5PuWyTvVq)NlwD9OzIbiieobQf4TgwlXmBYQv56)tU8SVPpbCnWW5mWrgUNPDY6xhj2MNFEL18DjUt)nYFejouLmJuNWklKJo0jgkPZ3jZ6q00QgUIP3A2Xnj)RcnJ5IDXLZDyJ6YNUUzRufeD0VwXn7EjsSQ2jUy3AQ5nGTa31nygZogsGecsIqOqK11xqjnV9Aq5S4O)0XmMmZE0jCk(Hb5JJo6sCNm3lcfu2ga(zpT5dPhYJn51dLqrUaXD7SED471H7IbpCm68lgs5U3v5jljYoKHpDTVg7m9maGTEAKLzCxe06If3mzLW88SxwkJ(471fBfkceC)BF3iDpQuK9lKY1f2j0ejmbpzwjuJjFXejsHiT5ygJCLLQf3KKbxPWE3u7lz8dYsrvL0qVxJNBcpA73j6mzFF0XBUlyLeArojWs8mqA8G7gYM1SdRuhMishg4HFcuGrb1rMVUVX5se66p907mDCQGqMtXlekPfQ(3z(iApEKU)9)Q8O)kDHLolAWM)9xfqFUWDPWeE7c6CjQ5zBUBrmZYw0nWdeI08zjaL5Q2f828mVE0vqBLexpNfIfcmM)d)IN768aLyRJU1ls5kQzYqkkW9Q0T29W8Q1t6AityDjV1zxfzl1e3fXpnANOisYAY9AAC)Q0cRDnXeNajXDiN27FRu30DfRLvI)hslLEdGbhRXdiK8PabcKijJsGtIvERIgic4DoXjscAHNybrKAyGZvIVihAXIHDRNgrs6DDstHjKDFiOEp09naFZ3GAttQfmg(hzFBYsvveCFYVmfXXAViUPkmizOT9a3ncxtKz1aXfvlwwjxOZMyNmccng17ZWYwE1KLJu(Nm13frmDa7kJ7yunDZ1s1xWE5RfgcY4ISDUe6fhfghpV3TLREi0odhTjUVRsI2KVBlr7Amh(uJ0is62RdevmH2SpraW1cOGLy(se)98sgy476PkT3nddeGBkBbW408XGjZaoFbe135dk9aURKGPjp7FPpbRwjlouJGEH6Xu4fsghik7fTA)oPYiGtVHf1QnevYIcObbhFlbfBGNjJYzIz(vPpMtl2j(TLv)fKJOLB2TQC2KcWuuhuxtIAxL05Cs2l8BdQuLd6GPN4l2w4Q7rZbwx9JXLjpRvPyEqGlcu(ps5OugUNPi7BeBA0f6pQY4xbwrXpP4OuAw)niTjmDbtJKXTsIAAvqNwHAin)H3IV05aVOeiYFSNkp8iR7K2V5ekRAmnDLV8W(KCy0wpfuvVRJAXkl8C4buxcDEAmiv4iqmkyT4I7bsBuNOxbxAkPU45FUNP1BAhb(Y2sJ9yEcEd75RW4eNs2uyHEJqWt(4pP7TGRbL5i0epa3zf6n7oTkq(0m0bmY95x32th1MBExa0N8ON7Ha5myqI(Rm6IVg3pWybO)xHedlopirRHctAOlGmptPo65OYWEOVTGv5U5UEcWFVhA6k9lIfIw8FKxrXHKNyl7du(Z18C0oQ5ldWD1korLemqjPW0zW6r7D7JAolZ)AHg5NSs790n96)MBniG3LbKZ6hSbl07PU0yQEPyZpkJ9ss975Ap0uuOen4k0rKPtu2X)4q9GirWbtniXriyFe002ovPlWXF4OUGSYTnziVaUXYvhv4E2j2EVZYieoteVrfPhVMaM17T9q0MLk3Wu3hx75Q2TlmtwVJ2MVHYfv5t3SExPKE9Jjf)yz1llxlp)6Lc7BY78JzwyaEWvP5Gc5Fjs1cUK7h01gsfusNVeK0HGlaNYr8)l7DK1BBJC(3IFrqkbjWsooafi2ffOV2IIM2xJmJeTTwBDerQM17d63ENdo3Fxus2XjTVSRri1Wz(UVNBj7DGHLVYm9FyIjHjVi(qMBfizuQnHlJn4EJsVDf2aG4EtLFyIRSx3zUu(lvxTXwvq9L0d1ibCAnKdEX5Pi0mHTYQYPGojSs)wW8I4(GDGaKHKmei2MNAdXRwOwOXKyAgaSg)NjkfXW1I4exS9tvSWnR9JR6i2t9bS4degQbozy0MJXiEZU3hretyIs7Hom0(Ij6dmeQ9dnd2L2TK5XLKGEyPribeAz5XnUi2waPQmaofv8u4MSDGIucbVtXd2yRQEZdOvWWcffObc0QM0FmSB1WsBjQ1go(cA5aMhLy4FNZ6SqjrmTCXhnvAbw9hq5ymrb(aDYtYsgLfcCf9qPf6cOxatNprhiX1mMrhGOgpS0FgQlzhr4ruIScbN5najJpNmgPnuaaosYykEMcWYwcphrzHbiIp1IaOAkIRTk)KV)(Ozlj0rGl5cTRT7zfFZOJrG5dI1OK8Pno83ltRcsafboHvysZxRxC5IgasOAjhacrPZ441L5sj2FT0ILmUMoisZoN6Lda8HShoIsh2(zOkicBPvRZG(02V)9l4KpmjlCRbzAPHBnTrhtwLSx8szXVTiVXcAfYT7QJ7vqtu2MBd6wfy024xtdmd8EXYHu7s59TpUBBxoPWyD7EwInKwQrn2XJB3ENIU2gUf4luRSoL8V0Lp2938pnjKngeyxlOWaYF0PYeWGc3uf2zPibc6eujcLFoS38A7mgHZWgoxU5AOvNPhhAIqiA7vgJGZOxJvhbsTomL6BUpQwKN8b7HVYZYt1kZK84LyZIlFJXUY0DqkJpPuH273U4rJb66ysBlQW5vlPyq(GHQh94nY94YW2JTI((E4IIFl9Gz8nUkXXL7W7R0ZOpfdQIrTDXQ0rq1BI6KeG9oG8T5X8aOYkr(vtynokpqneiJiVxOUJjpdq(msbs6agSonAEC1w)el0sR5Ql1RtBYh8cnppg6Gywbtw8SwiXwCpnr5lKXbMNBwLp8ddLETJMlFO7FLVr5o8lBUyjNLWCSzspzF4R0A4OgyIy)R55BG0PoG60gM6ayZe6SPEyQbu6lVz9x8Z6xA)nRVv9N6xB)n60GPVa4DrcurBOVC6)W76m6(7kvj1gYSBR3QlOI9MlZzZG9F9UwTZj21l1jTiuGWm8G11oD)ChHZYQTzDi6etTr1Hh(2UfZEqBt8ud8Oj3EoZATsDYAAQ2(00Mk1(82fjx1WYxYoEm6mloXMzrgbyx7g)TrBZdzIi8wjk00hrEaXBfdhgXkcyY5mzej42x2eZaYuAROQdDwAO4MY7KvCxIrfu6I22)BnmniIB)bbPE9nnniI(otUFSpfVJVgSpUzZPv8yFgxeDjupfdo6UG(aIX0PC2bpGG0lIOQi7q0X1NgMFMmWoTxbx)InYiKJRgueR(FfAVUrW7OFGDo3Oc38fDTk(dGnbkjQ4E2dRoTZELUt1pBtGca924(RrJ8qdwfawnnthjvThLsgzN3KeWGNNkq6PUDaXXKr8KRxAeeFWW3b7MWcj0uJ3Jvk4ezbdaS1dJ70)qjj0Q)WZ4FMupyIDRNwj0LC4SRbPp9pMlejXvWF8hcVBSs(jVLczsKqUJphRVQh9gePttYIp45mFbihCMdeXOD9fD0Bq0wRd5(KN8XMWGEfxo(iccfkXrKyY(0O)d(L08rPN(xz2ykDB3TZLpDgiA1AgLnxvi9euyOpulaKSbVupw6viA(KTkXjHXiNIJ5Oelrb4qdqA59Do0Ar2T19TFX1qibrZOx9iEwFDFftJD7Sv8meNBGQHlORZf(WGEjUrg4wm(8PaLP1)XTXS3nHpr)6YfBn4(Il(nkNNe5ylYbtHbTL2oigzvWwMrRBoc7w0VE4gtrt0a0S3fD6nmHT)x(oi62TvRSYPIVFPkqC4wmXwoxdK0Mz4gc1dR(KAU7GdPJNzkaIdPBdprbr31RUOU8txFk4YwVqyvEX1jM)S1dQeiua6MJUdEzckYpBqpiqucxFOdEzIpYHWtjVdEDXrHV)DrIy0NYMxaOZsOeUyWImMT22JzdtQi9tExMeidG7XHprxYpWrw5nff8dgmn7xDbI(csJ(S6eV48yRdO6zaACZq5bmlQOvW(jJ6hOlYTO8w4IrH0Xq0Yk3iE5C2ntFMIYzqABnGtYL)u8WL2Z6bS)HfLJSLvck8G7JGfR8LrjvU09QDhoFa8Zr6q2NgZvXOg)zbSrBiwS2INVChGfFTYkP8KEGW1(L5hcLDhcCAgWAw28guWJYqEtcSqfiWbolxwQMGIia9otKIV5fLuXIL(DnGPct6JwVCbCXn9gSgXsfoekiiQ5h)1UfqvAiKBav2us4NPSGLqlzK0SGMvmJZb3KdY99hVwX4dytyQ4lSgqlXftsDLcRdCiQnhb5HvwRjrulkYDsaKk5AWGU6j2(45ujM4egpRe5eax6J9yaB6yHfiNfOBEX1Osf0k(qE1)TPhb(8hIlIS8ZRsiHyr)pyAYnL7M3TubtAEF762oFoppsmbU(JmBt9JIdNP6SXWSqntVsQFmRXLiYV8ONYawFbvaRJZBDobXBcurAIXgdzPlCFKKSIVbrp(4PdBfkrI2fic81lKLRRuH35L8LmwI9NPzjEbK)EOjKhKJlv9ircZPS04vBSYiq8Ow8F4rAKiBQ)QaHG90sy7k3QF2Tv7ES1huq)VzrZ2DBAZjhZGNIBhx4ct8ngi3yZSLw9htE)hn)BkdxRM9W07RAAT1iV99cXLk0p7LHMQ0JJrol41L7KpHXV1jLoRTZd5X(JHxQOuK1R7BSMaNE)VA0M3DJgR3wB0JA6M6zRxLEHW2j9fk2EcaQHsSqDgxSCZ21)Nfn6U4OU621BxSB50nvZuKFpO)6dkRjdnFG3IGOkFONR2eGvtXTw)TDl2SPEoZALb6(8M6zl0meZUVwJbuV((B(S7NT)M)rypOXjQ)BTP1LSCfDV)FR6Uv1kP1F(PvZUx94yyE32oSbMQ2DZGISipgyyzWNGIfkX9zduF64AIYRsSDISJE(uy4I7LaHx9FPUPcTWrNItrpqzB4ORjcv3OmYG)1cng(cf7A7clVtBkjrhAC)npAAaUgB)UP(F)D3XrH(DNNe8VE0tOhkK6UGdkQPpJO9tpG3UI51evgXT7RMkW432T6HLvkFd3UwF5DEx10LDSnd8briWIRed7BmZcbgEuFSYUjNhx8tdZLW0Np)yQp)y6pVecRgVqNkD3pgtN52uZ3PEGU)iDYB(6JD)d3R(4OeyDhkOWmZtNflevzyTADCHTBJYcinf(GujT3V22lbtvUw7kZVc8o0lL(gWFRr56qqb7G4BYp7eXFwuITm88FD9odgA9QUwA1lWqJVmOqd(DxJfDQicukXcsXI(bM2MTAv0AzJxQ)vIX(ZnF3Pkou1Bcf)EE0(Tvp2K3MV)7MoQT51ktxxQK5T)MfkTFF3SlmnqRwatTsgHMQw32UQ)s9hMUlwlLSPT59GdyMIaYNQpUEtL2iM9DZMOhTfqHb2vxn7E785tVjQRdNPIc5xxtnZ0(zhB9n61YrwH)th6(ZiUFps(WOBUKld1V4YsUJs4lKzkFOZOukl)VkWx0PDiVUjJnGLzLgFX(KkbUBfRH7tDIG9K4RrCv2e7qdIZUFiWMt1VMfxXVGL7dAbuu4yE6InJzUKYe56K2edmqYLqzr5txsqI7sLa1qEW)Sjep7I0N5pp0TjflzJ9C7TRWkSOJc2p3CslOZ0XeaGBIjmn0aRboUQtn8bj0PXTcMGKYnIJp91dxf(2qc)2ONhwUiJGjhJTGnAr6gISfQXOEgfXOmeNrjsEncBYOtdNcr49iGLH7QeekAbY(bhcwH7FH(7sS3w0LvZN(TD11R0t2JvZnMqO3q(xq7u6mTMBDO80KtlxOtvz2B18GYCXNulYDk965lbSfJjVYSDBnbEOD9Q6PlMV(XyBG6S7FQZooaVb94SIJtPvac95hWTrpA4YC(dY8QGinZYNeiVtmUhcVmi3E9qU53T1WH3LQ3cZ2bng39ELEqQDbWg2MrflLS92yP7ne)tG2BJl3BJGy60)CNDCmdJkWhqHqTFWdFumD5x(SLMgGqn35ZVws6EQO1YY6L8sdCi7HN1Mfec(cjaYP3NCcj4lP2XLEL(E7w90IAJpRtvVVsIP6vBwIWcXFAr5GkoThblu26i70oM50oILl4qz9KYCvQnbWdFFEOGvWL57QCfMIKoIlfLdTMDSflDMJ5iBD7G2LIwN4HYyaoGyv4G1PMjKjFtcugA)aY0MzpYrcyhZTMYaQySTIvFx8IrEpuwaYDwpLcZbcsJd7Kg7pmpbPRVse9pjLDNaNMWkEQlLihiqIMDIAbQdtpPjGGpQQ0C4HwIGNrz2R9xE0GBaiQFbL6sTyu2yKEi2HZgN1t8co9s0jjG9dWWarlhtUk6bbiivvBE1VMyPxilrXzOW8L8pkj81SBNX(TZM6T3UyUPSm2SD9VvpRDTrEDXyLZhe2Q2BRu64Bx)7lw98Ul9BY0VzlqzN62D3vxT9ofsBUEWu2SPAB90hQFQ55DFQDb3UrX(8TavXQFlVDXYPZwpV(3FX2LHVylq1LgW0koxnHX9kUXNu2h(h)rQrqXHpPCBomtExCqIcYY6xF80pNkq8Ra8Cv8Q)W8Lw22tSTchHVa)GCNwUubi6ZwGYy2rr)1hRAAxQRlPTxCUUFlFz43Y)STa1CSBlILDD(9ACA4X2YAvAHahYEe8GA0DvBEbgdeIcHgUyjWbcU94okAl7o20oZZSxWVJ5ykI5cb2jDs7(tNtASu4KCv8SUzyotTK9ail9HThcBd8CM0tqfRSX4DkvjOm6GGsSY(W(85LGYiiRU5QAUrP6tqBKd2zNJBMsRFliRepq6yRz05vt0KIrlfksrIgToJDl1y17nw5mVcfDjrxwQv4YrQoPBW7FJSnmhJDhKJrAhUOosMwwPa0kyLiijUUhi8sualbnp77WDveMLHlYLuSuNLZpTCHMkC6JRN9WQgL2LhCVwj5QgjdViaHaQ4Dqtyg0ltWmv(XX8BnJTllDzYz3ZLsdl51k4DaJLKkxFFCDBeRtlqVZKXFn5)ZFjK)cuL8rXFbLheP8xt6f)1ey(lSW2w8os5V4uwv(Xpj8x9QGlLXFb4izo)1ed)fE9VX2rmfSpNSgU6dXM5aDzI4s(i5mimeeXKfO7cnk(KCcZr6bwMa)327QP324Mj8VLCzHLdsRZA70CWrhkEV0t5srp(QiBjfiuhBd9rDDpOF7Dj3DjNz481UYWXOTOhAGnnxYHZ3C4ZuwMaWFs5S)8bU5O39ABN7kYyixJxMmgpxT)LwcrIHxeOAZfJdk38WwRtFPF21tEOVgQU6IH5XqvqBWJz0DEIxWUoE3ayQgltslcKvUk2yXbviKd8Ux(b6L3vwvEwLRBIGc1P51jbGPgkOGM)ekaSryXL)I0Ny9yX8(UFfwQ2qOhUGhk23t1Oh7k65Tf8rnl)K4FDVLMs3roqVM02jlcvSI5rygZKqJCWJPu(K5PKlB(tomYk1rwlKUIckIUWBXoVvwwaMig9g6Hdfsw1qALkz3NgNJJsXlwPaXnw2(fisuUHKKHWEyYieQu0tO09PEfTHGr1LqudueBC6roqWDSKQepnKQHTPDWWj4)Q2Ex4itfJYLxjIVvhOePbSf9gpdu)BfMM8VUzJfGJMnOBaW2pDhoCP7dpVx1ka1dasHL5gsmSd9iv2deoL1d5ZSPO7GA1uC49Ws3qnf)MTaTgwGVx)tCng84vWnMoMJJO9OWieHPQCykIHrYryoAkh2Uv4odul5BSnTgefuEEgeTTc3VpwxGIZt(dJq9bnzMgKI0pq3hQ95a57Y2Nqwr0SAXNlWC1sVCG4qsN968saTMYV8mFU6IAygYMsnC1c7t6BKmku53OJGyg2h(HZhO4yCla3Wfiljvfi8GrdVH(aEcLqa9IUqH67dI8YJ5oJe25X3w0SLXNfD3RJoHbk7ZPTb2e5yE0U2pEjfV7O1gzAOyeVI7paU37WeM73mBplowBVgrpI0A0CFtdd5M5RzHtMIyLGbIkh)OTtELVTWyg(7XZUlUezRJPXHK02Zy4Tf6N460tA5f(mN9NgbLjgP(H9XuYk0RiYAG5W0VbV0TAcw4jO1aNtxX2jh1nxnTavXElfGAzCkXWnmVppvqwflr3sdS9vMIs9Ot2bQet97plvQ2c8G9Lqc3VMQkr7o1Uq0L0IWk912RndFeZvm4W1jqoioqfP5Mbpgn0Fr5DRoqb7q5UUIsKRTNWWwktsPA8hhEZTtJyWzvofdR4AqjxLEI)5PcO7NOL8JNrgBgxgdSBFeDytubygTOY25SxbBhgGQvw7O5o61WbevJI7E1LpPLIU6HwCUzdXNjAN9z7gzdujPCAOdWQANPx0YLw)99qL6zKsG2dEdb97SCtvznaqrsJSqjAP3ImEkln5Dg)jN3IQITIFakhnRm1V3v0f7cOXZlvVQbqrOqbz2PwyTA0S0ILn9fZQ7kX7jOzPfQlJO48UhF8C8SOdTBNNG2nsssqBY(ysvwrPZ)mszodc2(DBCLzOQycq02mcuOph6xtIY1nfMDo1vNZT042Bh1fJdx5YOPiDsW(s7k9uISL4KgWNeSoCIu2bbJCabiGn(1V4M5B3roz2UB)IM)FmZsn)fn)T39vukpmV2eVt0jWrp4eebDCURjLYhZUWFgTRyRClmN4I1anHa(e0Lcmj(TGH1RhcgAsZ1RShETkR5owqu0kk01syYbJMQNitOYDS0UEllVK(M1R85JEiSOzeO0wiBbFch3S8Oo)aQylTsSl1CrRqi0rdscge011oOjiII2DA74lYEjypJLt2GupAj325SMNH2Z5M(bkI5bKD(hyQRoDTyDYIXnp7il0RlLbXPGNHJZCZCPBrxK5RYX3Pyc9lLRXbG7b9GxCFU70LU15Uye8bjg9OQRmh(8i6tG4wAylo5W2vijJyDlLeh5GS9yc2NVxf(frzIffOr)LiMvtvg68TijHlToUzDUJtf61pTD78BN915)1sOWJLUZJXXZPKcQcTol1ZAeOGHBYYEHlJWCJiR1XPYrWCvwx0OJNxb7chACwFaxb6wHom6AzPV3SGE9X0DgFhQkcNGPhSr3kQfxodhYjvYZEPYMQ4XO2vfWMQ5rVlH)IPDufrPGcxSzIsrF94LSw7vQemcfvSadVm7AJPYEl91Oo3PP(zp(PfuVWsCzPcIBYlYBYbWZioDX9yoKlvLv9K436PSboL5cDY3xXZEDV(cY)vEt6U5N(GGLh1AQufPU5UtrKcC5I1klMSEBi9GnNIpSzjPUe1ZoOrD80)zeS0gMFHwwhP6SmwjjRiK8CweIqkRfJyY6C)q9wHvUfrwZCMs8JWyYZUTcLlUmLCEMe)l8PNYKogZ6ykvJE2o9nItwu2nhRNZfo2tBGSNpoNszUiRkLly)kx(z)wT32hsQX64CsMc8DPvUkOGjPf0A9pTOXsw(XGHCe3PQPldWLmWEPdEeI9tHot1SGstVmCr15OuHau)EPPmN(7lZtNhBaAhMFI5rFBNI2cUjZKyr3jP0uT4(7)gnapMk4qo)g66LkjI90whvLky9Et4F8TqLvhSP7ZccnKAJZb4qlUk)GIBUwTPUnrZsWxB3RcM(sY0n7JFkjo57MjbIoG6MZQI(vKAo29MGoMRIk(8gVrn5kJoDaclP5xkzUvJzY8CpvUc5AYlmNGAQdS2EuFbQrbrPs9o1799pcQ2yRlaq4fBVP5devjD9M9n)S17WLoE)Wk6o24vYXxBbSopLTiF0lx5Ivtoxk(nk68vQ0gX0RSMWUszdXhORM2rn7Vkpwf7uHGiBHFWX2oYvQJQb9evkDfT0B6epJpVDujIYrZ5ZjM)n3DRTF7amuNEUVIQIuSRLFsxE5(XIAsOkheI3lfBGprgz22)RLCVuRLCl7Q4)uOq85NS(JER9XhAie3)TRNVJR6hTFMq72iGeIb724FxS7np)UNMT4HTPZveaXnOo48V1TuAMRyxIK2bo321rnxT(2DrfXndz)oqtEg1mv7q5TespYvqBdGAqbSsi1O2MA4O3yZS6RrR(JTrFl1blWJsU96wowb4gNBOcOknZCMahC(PbGe7Cd4AmwhZnebq(hpiwCPhZV(Z32eRyOfGEa1zPB2(9D330plRmPN5(xszMQJRg2(PJv8CBhQ(DHGoAyZd3RqSvZ2CWTboXnmv3Um4Cv0yZHVC4l)6N)FFoiL8NTlKhVFZVhASRRo02y5xFty1C3I1HX3SCAuOTB58fT9(1isYT6POWvZ566)y9I9bvA59wC1VA)U9Bw2qyUFfRqxqRmxD0mawwXohd6SYOJqxowFSSAaHoZCkXYwBXYwBZYk1CMkhepllJsL(tNH3aZTIrS(HBGFrQ7TCvpu4JUzP5B)DZxNfAamno3nF)TnJ9Su5Gi4eo2RlK1tQpNelOT)3))Vp]] )