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
        usable = function () return target.distance <= 5, "target must be nearby" end,
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

spec:RegisterPack( "浩劫Simc", 20250831, [[Hekili:S3t2YnYrY9TmXglmAYHyaAqmA0Ac4qwAL9QqwRID069bh70SjqdWEjq3y7dsXnyWpa)N4Wp7pj7VdNv1x1rMvvae8ywXxe1GUoYkR8UQkZpn6t)0N(4IWIOp9d(d9Nm8lhozWOV803p8dF6Jf3Un6tFCB48Rcxb)pjHBG)7)3)Z)1)7)5)9hJ3mN9PBxNgUGne5PLzZHpdFOCDyrCAYxNfUS4tF8IY41f)UKpDH008HXJG(SnA(N(HjFXx8PpEz8Ifrvnkkhg5to5(Z)PlJU)8)uyg8FIlUmo5(Z)yuyEk83X3)DSr5KHF4KXJ(n3F(3gNeNF59N)nrN8JzLjrDF2V6Z)89N)VhLSkAz567p)pevKffwC)5ltHX(R(dDTE04Fd2GmYh(5)4wg4VOUx)0F6pbGZyafKLUmEnSW)v)kwBYzd9gO5xwuSn)38U3Tca9YlgmpDZ7YBrnZzOg2)E(7UyD6fVR4YOBcZUHVkF3xnN1KFmlonlU42VpoVi)DlIwgwUUa(7M0KlltkIYcUm8605dydY9FhBYvW83F(xNUztm83pEBYCaIgEA4WXFyrvJ)gyTa)w7kC09Fh8balfMfhEX6O861jdBxMd7dfzXjxfva)EycdjaBQrWpTcAszbFNbAFC5M7)Uqo8NpyBweSQViS44PV766H9TmAOP1J1OGCymsJxK)2Rdxx2(7dgn4YW8G5PPRxKEtsp5FoViSyqyYTbl2M37nDFloFq8gy34648Ofb5nWtaq(gTj8QOSDaY8PGmFCiZ3aK57cKby()51aF2Ay3UgZ3HWlsbYjygB)T7pVbcA2M(DjXfXWE)1r17p)q08O88WSBHTgOxxb)(64KOtk3Y3WYJxa)caWjlcZehyaqxhTjkPGtiD)5aL(V)B(9S97FUcqUjn7kyiwU8(ZxfLaKaZzqtYIyoQfgGea1fUG1eycag84L3YjtIH2CD8IYW1IRno0VSSOmlcWqqFCFtAuWCGbrJ0bW2Bcxe8xlJIsYd2WwHfr3DNud(lLjxTjmcywtHMeTkeA3QKOcLMTkkmBf8dlIYGD3THzrbxfDBUsRYcVokjTmp4Y0KOBdUO8V93IYuhPS4nazZIOFwRZfldtwfuK(ZXjkF7I1H5fBczKIJhoCOYxNxMXjNkGzniEr6ALVVnkBz8IygGby2)s08I0DJfab76Bd767g213jSRVdyxFkSRVbSRVrSRVfSR)db7UmpOigMXtd83gd8O1i48OIGlstkZhiQkGjRa03fmgA8Cxg9SvbGiRALfth(20TtZIGXgVV5XRIxhKUmy5AOZ4TjEZM0kLkbHLzHmTe1nd(4I48SYTfCXxFBjtwdxKqLAsadbcaIyYge7Jc6a6va0jgKcWzd5w4Aqc0aUYUayFcmj4O(J(199h8(Jclka5KGYpyJZ7O(9fBBEz2QOExuUC5GnrfHBsZ2EzAoSBvU17OXhpY3Z7y(xvwvdYzJ5rVV6JfmGDE46GSk7eGEF0OH8f5hzYZycWMFz08RQLE1P678FSvI(5SHc(VrCzFSrKjAM3()noZqLA5lzFMe7utX1POGrRnhtINz9lcAq56OyC2WQsHK2XXWxzmEt0FTmE72OfUOK7NIz4MXJbvaXv0hfYiZwfrmTvLBbnemwHCzfAHWKVmEEKbmhJhBCWPI8y9R26B1uwb910pD)8D3XBxsZ8fK3mDvKjZMoPhzlYG1kOb8SHdMCCJo6bxxB5zlbvDR861NCG4WMzPc(WYB(D31onr3gfCby8zZWFS)m1vCZetVxK3sHhYS6tCRztnD7IYOktbAiUbSUGrkUTNuRsy32AoeimVEnq1aC2RE9DYuHE9fSWt0OqrUQ29MAe)m)HEE3DxFNuxkmdJiMHr4ZaF79Bsl5BmQwWxTnX354BRL5v7ICZbfmTuOdClkdtegRfHamkmMKB6l4qraG9H(vVB3jXa0abluMkiy)cW(Glp32R7ZxcQxJyFDoyKAUaEJVZO(vPpInYE9mI3u3xOgFF7Jp6opFx5pMxZRSicm8ydiKdSmguuCdhzc26Wm74(ZJacxgpjZi6cMBWPBzAwzIfb3bhqJV5TBrnIEz4Ay64kUIa7Ra9YvQIst4dtnbqu4CW1zy6szGqKKuvWp4GQ)vaRlvZry2BbI145fth924Ltz9mG1XbHRxKbdwmiOJTsQ808)4J3cSO)57ph8O)BdxV(IWwjkBJs3YirxhDD061kQcrN6L5st9Bmm3819xv)RmN(R(5gJCcZWSEkozUSPiC5nzrjmgMa2uFv0aURF8pSADiiwcSFQml7wqeuV2TDUvlblct4IM6TA(IgkHPaHwRiOQPShyX11bS2mcmKjS4YG8BII2wH)Ka4TXGTpLBdwMfUI5L2BzHOzkGvFBfT6s2OuHByMwD20VCOXL8YO1bxeMbJweQjycFVx)2fNWV2QXJb9Bc)5J(IE9RS2jaie3ehLpBky(wCgyuqbyVp403XzHXlcGTCy8dxSaS1oTmbCoq9NJt6guSVo7lh6jauYw8vdw3DNcW47vRFxCnaMh27nkG90r9EJ6Cg9Zm2gpfm68ldtZRPnyiEmsgGeaNGPViPWI8P(iqCVI4nrZgPUtgMKeFzCLzSpkZBn)7)A0vXRJ)ZmwOnPmRyRjjhuXPLhun4dy(tXKYV48w7gkUKPrHrDd4qMCTALnvmJ)dGeO)fEFbQ8LfmXBcY6gOSCLNT2fS8kRJ1KKNT4YS41RBKCVmE1LfbvQZ0OLp9yn0K3XDuCS(ZIfNw)gZ82OpPHzDTRxnBwoGNG1pWJa8kfXj3cdG2wKICJfmsuc5nAT0hVLkgIAa1WnVcxmf8bf5zE9KPLoBCVfr8zamBlcM4GlGDZRQ2uQM6WSwLP1KtvgBpUMDfL7EMVbZFpBeGWUinpVx1cP7NvzGFcPSo9rgtpZxE1oB6OH04Ec8JQ8nq9cMraT2JQkN4hs5E)dQ43WOYa97WSWcaiyIz8MCM0HWKvvwGMLcUn)hkHpvf277p)75HaLzI0xdtS8V)pwlzH33V(B4XgD1kMje3eZA7LrR3E)5xX0DE(CyOl5CxUUEQK7uBGraqgWK7E2Oj9QMKwB6YFRHV1dHVNTLsONI7fELqaP9No(v5Tnqvf3WMVN7EmlO)RIxxzN4h3gxev5VmdzReq4tpH73f8DqNrexO8YOSmoMKHS5M13gzy24jbOk4W2qhLZMug(GMb3KKNgAZgwWnHzx1YDp1)KAud4qW8Ryg2gWN4Cd(bAVZU5NObjlZ(qJat59YAwksXvhtjTF2uBlNJjxnEOmX(QmXegYhiAayhHVIqfU9KTsEeTju1up)EQ2mbePYqIsS3ER(053OwKnflbthzEcRzpQWgeI9OZYIaPmG9MbmgvpR6F2TDYztu1HSpRkDuL2p1kuEc1NMnHETH4abdvLvMFzRwUYKlaZVxeWTILbcAGD)UaXeLbcvCiKtYdABuNoVtUv3PXM1CASvcU(T3gXgrEaOADr9Nya18qXwZow5fQILuJ0gxqTAuKA2huJZBLz2(dXLG3RjsZzap7AaxhuDmSKs2B2Fa7n80WH9qqtceD1Tc8SnE1kWu4oBm0PtvPe1WbAEgQJrEdfkH2i2zajPGxTNnCayQM8piy0PMXztfAAp7yqabQg2UUtpUN236o)wblH17Nq8KAo72wf5bAgRlgHjYMpB8qp950hzo93T50qZzZPxh17JkPgtGIo9ZtdzsFubwvoUcUJQEOosAaM9EXakxlhR(FVjLfkLYnwJMWmMlfMmNPDJZVvCb1KHQEbSUtuyrEr5c4VC7SGgZVVfcaG8531kMTjCbp68mTaIrwf1wXIqTRCiUmdOXATfDR7zT1D57UJmQITCz7H1veMq1rwkECN9WI)gNGroUvegbXcOfbpScKd9IpJ8OPQi4q2sGPJWKK0eGjPZUXG1w7ouHkLcMdfG1GmKHdMyBpVz0wNMEvEW8WKaWx21AXeBKwOdi24ztIuKQrz2F4RAXMz3Blw4hOLupHghAWQotrGzAn7A3atDuOTn9ynumIL11iHWaMz0bq3bFwBWmxuMLWIoZnmqThmvS5sqrGOiAKykR3bnIaLWz7a8AEaoGbmhb8Da8uI)ZeZESR4fdIpgc9IkU0DYc0ImTM)hgOVo15aV1qjs5f1irZ(1TKOMu)nyezEkl)gWuuKQCSDAvWZ4KadUbg8WKCE8YyJJnxkoBYXJpIs)MToxznTzkYJ8rjUgpSjieZVD(A(rJcZo0pGyi5QJ8hm5i(2H6x5rYvYhOU7AHvjdZMyQri0lgu9RWkiUr13OCtKZFIPI1kA0TO9UlmiSF3JA3Hg7F0KpRCHY8kXvRh3jaYS)vMbiaI0JHUGNskC)Dc0KSpsZhIJNyGlN6lubowI9FVi23p2xMltQgw(gnFHCG764XpefJwKD9E9q0q4FSbhoR06MpDypN8iLZsQVW1b)gu5hE85HDXHRNjx6W5Ymz4HbBDN2YKPzE3uFQJmF3f6sVxoLe2myVtlq75rEuK71LtG60D4bwaXcwyVYqqNjDQHDLua3CxgppUy20thECNdX13d4Jy(Q9gkNFAzrVyDm4hcRtMoMgTG0xVLweTzliSezD9aeWOFSPkyEueMgQhmvi9gHtIwZA4MaduMXV85823AuEEA5685HzcHqAompByB2xKvc)wCbdLvlOci(rCqYKYbB39f6nJ27ubBoZUD20Vy4j6B)1T6eT95kX0JM4q4lKDlKFnOovDZbXliN8MYMZGAwJALZItuKwYdYhSgxvB6NHZRA3plm)jQWT73UPQlwFWfSZw2mPksmc4amb1LMCpdlzAYQp0snZUtCCWlC9SrdgoQwePoQvzlAuR5iY8u6uAMo4SN3vQ6ssb2dZMhMaqvAgi5VyVO64SrJgou4bGmq4kGatIK3MC1V9nPawigTkkpnegQPJglyOMeysOrQnsOI8fvOAeg(tzxcysZV6mKvyW0q(kse66eLZ(ihFp)aDQ1ccQbd4mHkS)kNdPXG2mtWilQRwu7V7t87Jf)Da(OSQxXBNwH8vxnzyxNF8eYkNntizAP1RF)dZkI4azWIyTI9yE0uSp20E4dVzksV9LKSxFcsskBr7MiTdnhFpJF6xQUHHrw5Th0vBtz)kx6hYYdurIDtqy(JrkyP9E5khcuXjno560RGTIFgw1G86a2ivDkbBtVbqJXjllZJfUaV6tVmGov(WNeNl5R2D9l5jO2Pk5R3D7tSa7XC2(rMN8ZzhggtPiJeztCbF3R7bCCvy2IBHoVcujj2vS3hHWN1EELuRj2Lxam9yt1AshARu0GfAIAAvPNuuRF30m1S4nI8vg44P80G0HguhDxagyYwA8lKQbxCRIus73zV4hoGeMCRNYRpX0mpYYmJ4(U0mpsEM9uUqPJ8PUwTk)ank2WTXcDON4gXHgnvfTX(Uvl5f6a5hKg)3G2yyDGQnuLcsdKTqa5V3uqo88LuAszYTXr8hkwa0uqka0Q8nQuIgwbOeI(7nLOdpWlLMqScWVXK7c97dHkLqMk3bw3KkBM5hx6GbuU0QWUCgdKFsJKA06aNqDdbjRsHZdBgXOonQK6sJ3EGjgzyuSHfqj2TPqq47OxJd5GgrJjLFaJMJiAJTSuxljDtwfmnflCytiUyYUsfGWEZp6FMN1i3Yn5O1ZH43qBTbyR3(Hjew0TdGlEmyedocjoXmu4i(jeyCvyvKO5NKQdAfm)MzjeM66Umww0GTl3DucIVz8UxUT0RkgxCUJqGugc5Wm1ooZeP)KddmmI0jbfGOnZPC4MxANHKNBWhQb)LbdhKxfm0agXF(ZP98Oa0tMj9wMDB6p2nJPWnRF)TiYKf97f3bAA)HtCqqK2xs(pBmTDq7MGzCR3vjyqbYNkcglt(tb9YZOz0kzVPdN0lxMCQm2bnu0KspWbMMajrHqOLOUGFpLXCOiOim)kZhj3OjMU8MtiEyzewi6UCFC3YQe8B1QmT7C1O2aekF3DBukSg8riPG18Sv3w)OIhnc(AFh8veZ6PgUPzt)YH2USDNnDIw6EXYmHW366mPXK6tShoX1LV(1nr4sDSN5)gNcZGLl6ISqk9zM0wvhZvvKXq(zIs2PnRpVOvPc3UJlwtkzRGbcYt98VKTzGCvsqg6j66Pf6mpe3c5xMedxDOpODrOELH2kI2kdD(60I2mlQRSW6CWe00wyiOnsYgVu1bPt0g2ZjdL(YaP9jyrJqK0Jm8S60KYzN3nXS97G1PZVkb0dV(k9lSyvkDvPFkHEt(Jew)O0kcAsL5bl6hcKTkhOMf2cPGZOla5lh2ddpUkMDdT82nYv)FPqUIiR3DYv1ZdXa5QVJKR(kKRyXBw(JwjxnjcvzE2xYv7j)oJKR(7a5AtgsI8(pYA3H89pD6KUtLltmNIy6EvpLfOvPUuNcIQGU9n2s7AqSQ(7H49BtUFSlPTfu0yhBmz(iXYRhR6sAOCnYeUblA3JH6ukCAwq5w5lXq7e1Clqvf4z9Ts30q3bM5lcwa0rkjS42RxLVHrcnFTjEzAuoxh5El9yL4Dv9A)uFXApDspTBpR2JPy2iKSpcohLL3(IjqwKOQDfRDBLicNa5WkCFHihudDh5Q)QIC8VdphbA4(mkD1ppESj0I(TqhhVOUJzyiXEXL7akzP8ZuNtgnA4quDXmhF0)5oookHSNQD1OnHJC5PqJSfPfek91P5KFdFP7peFSjhx9B1T0lD40DD80w9Y9SNYO7oVcRJD36(wHzNmEYSHi5xGgPKJfECpIIJRL48HHcFV5Q8pB0h2nMasyB4tnSPWn9YbPPFpUDIo7HXtyaEenVRs3ZWdPXCFyOrKHI6uQTPthYZkopL7tQVkglGMODmQGxptFKFAl1cRrvzrVSpsBnDczth77nZ4wH0BerQDm16eQSXDTSvpcXLU109UG4YgJbqxVhjjlBPqeBVR3Pdh8EXdCH455sD4JTrhwz5z62NFy8Lqo7E(TDvShEL)H9kRQ8s8T3F(x9JFplhTDDm7onN3LaGtxuYY9KxeX82L1I8Y1fvFpPnRaxWs(VHn5HZgzwv588Q0h6x97)T3FE(8OeG4nLLg0veTHqUXQJebSn1j8D16S2zlktukc2ozdg9GNcprbCvzAep1JA)YuZ0ZKZhvcwtr4EnqiA9bg5dIPy2O8jsuXTFV9HTAjvW11YXuOqr9zVKHEDixZDPQ3j54H9S9IF0dGNHv(a0RYStRqmOg1R29r2EdZNPpYQRkgb1wbzIEv)yWyqrlPG4DxLbwwRYM2c1gHU3nzWe94ojULu))7rSKLTo8bVKv9c0aF8EJSnLz(gBbap0yHhcSy81e3aCiXZO99DR)wxD6z7BK3wH3Y(XoiUmrzzTi1SDyqPq1KA2CdH5aR9mdv3dt3Wl9BMDz8IcteS)qtgQQSyNwtnHLWCIBPfrrisGhclclavFnNi3NA(pi9MHvMyHSoGHSsLwOZoL6bzyXtcumNqusTKecvFgJydNEukC5PBB6b46x7w57rYcxpaxLvkQbnWV1e5H)Ujqq9j)3SD3K2jQ)3YpKE9m6MjK4Hj1uqjbZSGO6DM7UJTGARXo5dksHf2m8B(wd56ejp1RoocdpEu32TmirAcv6nqkKqG1JijzLAIXJL3yAs2u8zpNdhnjEdBwdjpN7CIDXnKHf(5NpmbIgycisMA2GQZ)j6D(dQCdl5lsm2ixKlqPK5zlbzqSFOzEK9ubcMnHV0xw4ksPIzxv4xoU5bZJ)TMq)I)19j8A8tgg1imXm)eQ5jYbSIiXzys0VskkFe(QsjkMMtIcgStKdFQPxm8PCxQXxgS1vtFE7eS0q(FU(FkXhJfbXYDmhqltEE2uFsqRLd75b0MrazeHPtGKtNguKiwAIjDYNhNqSPxZ9a53(cA8DWzRmh5GgZ6XVpn2PNi02R6QSTOB5EqBEiRsT4qGsh(z2sY2oKJbif5TvHcwMkZo7bt)ti01x349wVcuLjqWvUh4vl7TOM)5E1(5bHu3hqZSLcDcQ0gwY6Taz9rStcNEcWLC0elSdakH5Xk0pIBQhH9gy3Cp70dm3hoR545XmAXr3WBh8mTswiMq69zKvp766rv1Id3uuIDVKSMW3XhQhuzaaHSJgdi1ocVWTicUlCpegJsLf3itmw2oDzItn2wQ(IG2L8EIQydGb)wSiRWGWycJEeIShX2PHKsl12G54bHHrPvI7Q1AUed3EVbtuvpAHEO0OgI66EjkNk4ROggtneOPtubxhLUVTv52TMAsDwzuDD9(BJwFYhRqkDdZs9YHUW9u5GvFRvKxn132ndX5IqTYsbVqLUS79r5A7RqUV0lSP14KkkKYSv1La4Zg3w3mrkhwhJPeqfrsuk5jk(L6xmAgAPl2HcKm6nvzMTxmy(mRyxU3RkDu1bVyxkbJiMJ7s0cud0G866SPDf2nmQXEKYBpP1IGZWIoARKc6spM(6t1M(h(6B24h1LNR8LmYWDP6zvj4FpI5OHWUEiRBHMvp4EvfC8bO4aA9wk2z6Qtuc4ZJTBUYSPJesPTyZGNfluyvSjTIXNZs7jeO)0xm(eDzxtULzM1h3cYhnuH6eREmWeBM9iWF2P0Ct7zLP7eF9fHLN)XJ5sOFfSqv1yyhVmrlKFBr(0hWKPBzHj8Kd6374wYd4z2Mtd8Rt8sgQXEJBIBIYkQYweAXNJjJvoF4qFlANDQ3UzXzReVje9Z0tQES3rMhwpfJYEy4yAi5yZIj9ot6QHqn1UhkLN2kQOJMB(CvrfPap1CrO5dFuXuzLHx)IqysVSPBu6QM7FRE8oTBxGaln(7t4WzMJVhIErX4)GcaVwvf3LYY2bSQk(qnjvHEx6HoJT40nVXLf80rMs8ecX73ArX3BpRFE7l1b9U)Rv1rBa0bVQosAvmTYBdgvICmMkwk1gwm1E0kvx(ja0CABsFxTg1iD6RAMg)STsA1pzy1u3gD2jFzVVKod3zMMxn5pQXRxxgKj78vgnLtaJUJT(DFQ2sBCNWx9Q5MAPFtliYkNNNbJmj32iUdRQt1ESwvgHNQc0hHHvQ49EMuSzbptEVF1SSzhnWZGfENAlMj8S1M9xSb91rXZZwGbKUnIDbJq)iVV)CLHApl9HpEL6WZTzMVjVMIZzTgOu3Mf1YKY3H5UGRhlh7Slg0(OKhaqUPZ9b9a)6oPNoyWu1K1jmTPlhZUk3kQcuxnA3andr22wScTfjqtyoaupUryJBr2MirbjO45nKIqfZuaQsxPJds7utu25Tjr3oHdROB2V61K(fdpz8qZOI(UIlOnTNjOO24koWc6Xt5x2JJ8rQ6NyU7ThlYXclYJBwHSBvbldQfvLiKoAYWt8h24MNs5f17iSdD)KXF4fh(6bJR8nPgG3m3yBSV2NyEv3RJUKCF5jBhOzsKJRGIOoDRmHTPth6HunB9DjQF0It0ofu0Wr5GIJJ6pY0zOFOWF2IRNHB6Ld2sWLvsAnXlhSGvRmjwA0hrJjRq3NBlalTG3xZ(dQ6bmM0zXDkt2qXvaB(qtWTTb9AcHAL4l93EJ1NuKlhnfFKF2wPQljfy)rQ6clCpNo(ZVQlSkoZ2fXe9jqpE4tCva25Q6BBA801DltW1VSlHVM1zcDcjBloDe3t(9KK6Luz81cHuxn7vzzCWkxVYZ3bOC9IG0NkFhveNq5RR6NR1Sx510R1S3xRzVKC0VwZEDMc6o7vNrNQ9gVwZEDOyJzIk91A2Rfe0R1S3DPM9Act(sVM9AKk41A27FNuZEnTl)0uZEnbbpU1SxtZ8twn71iq8ixZEnn3VwZELu1(cOM9(anl6XXS(xREV2iD(7)Q3Rj6JlESREVMM8NZQ3RmC9sT69Ac79KvZt5W56Frv9E3Rsb6Rf432zEVQhOVii2DAZ6ZlY5xlWVpKc87RC1pkC1VwLF31YMQAaDjimFTu)skkX5s9Rd0SVwQFDHMv9yuSrZ(A9(1anR569RmnBXZs9(DFdK0UgXQQ)EqkQwuPDbuA1PJngHUNCK(xo0JUil)g6mytpPE85EnwwFq6B4joqTeWZjL0pahuceZcIj5wjZYFiKpTtb6dypwROoVm)furD2gW4ErDwBKCOe5yO3sV1zExvVNzp3f1zDqw95rIc2oCeOYd7UvuN16(tDrDwdaE4f1zTHel5PUdOKLYP7OLLp1f1zmiYAseczlYYA8auqN1gx9lTVYdSdB8CopiOrNnEOj0gXliOlpjcCVzlMhMx0SGTwrGDFlszjQo6vdK(BeKP3BEH787SX9zPgl7aJmjS9yxyQTjr4LdsBplm17pFTH(w8ewuQTAoa1w0JFrPwd0uFLGwanr7WubVEM(4ZurPgrcdAbUzz(HVOutK6eQSFJ(99146AvUgKxZXkU5MXn9dSen4I0KYCwAW4MWSBIlUmoHf3ZCO5SZMCUN0nWxc47z6zkRQarSGfclhYE2tPJTyi21XNUxKEZO82k1FbHthRoLQW6ouzG6GJRjE073PFJ02X3dKThZ(SPkwxxtmUBk5nyNHPN)LPU1h)XVAz1mE4j6ULH202xp5XQEnBDxH3vm)696EKY0reT9L7Zoxi8xZKPxsMuAJYWG7HUTQUKCkP0YgZMjGN3zvWy0qRqpRLTG6H30gFHW)kpnZAoMcIsUQipLkK6DUasW4YAqx6AeT(MBASrc(cIzcvYrjfhqZBBHOF0hS1eP8)Rcb)rJgmXMRcvyxSVjlIbpaiZQUmb0KjgV5iIGow7a2oRxKw1C4(Sr90PZv3bvi73p2jlQUqvlObAyt9s6Y7ZooNn32g1KY1yPa82nTuLUNDEA1ndE8D0jnlpcWHclqnP24ugzO8)ykQJ7xD3)WSMSKoLj0AJYAmDOflC2rQIxcGmsoYOER4aTyEXttPfL0QSCY4HwlnC6NqRbCYa0N4MtRqXtRyz3bpyv1RRLOacVSWTY0c5KA9n02DdwkF)1Pld)AbB7CSpB6eADhAomOJaV4288W1bRc)Brv6oDHgNZyA1W42uBImrrJXngCauZPjD)UCjP)rvMT590OV0MjsP7pHJxnMLA6JNXZuMe8FMTNLXMrlrPg5NiCMpEuIOknuRhDbZAdojKVyYCWU8MQXnfR8jTddkjIwKLreRRWz4WPrI7Cc5s1sM7D6eMP57HFW1zH19ZDcC0H2AbfGpLbWoURHoaSSdRh6XtlIuAZBsQj)5J8P2S31sM6J6MTQzioSD(E0c)jZUDd2m3ZmE89NqIhBT7WQz3p24Z(OLEodEm28S7XnH0g5FfjOEijfTcLw0fBJIcJ9Krb(5fgRjIvyzqzS1H3oBn)JaPQHmh2rJ39naBPu0NokQN4fMZB6ys1D4sw09ehKtkUToXiMvCnKUu9mwe7qcJHPYsYoNwwv5v25bGbMUBOSszI3eTHtMXTdwQ9)ZExnl3g5gHFw2drYuQIwskBVB2k7Md52wPYfNZwCSiLnxBQr1qYyVvPIp7byiN)a6F(AmZi7SRUzZP1x3aOrJgnA0ikVcpjN1bwCzEEz2jjmAeAhQZFRwdQwF5R7HsCX1OhK0XcDzchKW196GeOdOqNdQLCS2WRUI4jgACcq5jNr2)5LdMDnhSH9ov2xTnSgwQrzYyPMuLKBp1xsNVP1JtYD3uLfYGo6wX(x4vMjs)5LeP7N2eDPhoTjvoHWCgq05rlv(2wxf66cuyXKj4UbhAOb6Cpd)w4rkLwTVS7fvqYJj5tTrZqi6IQcve4awCLPa7ER)FuwG89lnRzzUj4sc9CvK0jDFMru)5jTP1k7xvAfmfRqAT(F(haZEcnHssvmnbM5LRtBDkVkA9tSQOoyno0hnOuMdOjeepGyDOt(My0RbLWGiR1BvVMMubF(I6MdBUCi2oTMUppA5vCP3PgeriDnjauddX5gjI9wkBlT8nV0rMxt88P1JK0l4npKFXMWDdj98st7PCy9OoOFK5rljCLCSN1AUDri7G9Po4hFSun6UIS3VXjrovNCNS9l0veIuwZMZfKypIkvqKwlLRZUDWfEbnUhBVxH)wOm5SWQgP4gIQBZklaejyd0I)XDKD31RWge)h8dtd6SpLNmZNWbZo5CH88iQVho3Ue6VLQm7mAerwx(osRqArU)B9MfTNcEV1OY638h85r9LTRP0Nuvu2Hdnk3r9eiuL75Ehe)oYaH5vB)7VCknMTtDDMGr0BznieLmZwodWddQd7q0X4UJFbpcHDKwR5dYyiTrgeLEHbNq3um9ip34Wx8UnIcYw0E5ES5PoJryc9AGxsaIBn5QiYzpc5XseyyUpQSDhVQED8JgXzAc8zvut4Pc2sNyRnAj)(OFZFsMrU5pJP8Z(1VDhfctA5uTkXY8(f8OYZHWKjajTSkiYPvJ0uy(1pvMB7)JyMsRNpSrRqC8YA)sgLeWGGxksNrT5yXOF0A5RJD2E32Q8oD6vZKtDTOnfqASimRIPTkeDprJxEfClz9XIfzg4XB8LS)wXIC0AUNPeHi(EzIfZORDbvRdDSDZKf7Nr6EKw4R4ht6LiR2N3vkjM7ujG1nEDnvoTIaLNt)x2egnYOnVHEe7FALVd(vpKY2u2EdRhP(FS7nSAaPBIX2S4CKyXKhbKtgOIIBj0N0T9N7uRBDy1YzrR(D6QF4RfGwN3Q5IuK5BYPP))rVtlh3PACLl1AUdS9ojPK4ol(eMpRvbMl(4jzp5sE04sQiYs3dYMEpvkFOxe22XjY5iz5ph8qwlMqks(ekFwfCNXa2w4IBa1VY(87cJ)Y9XEKhIM1yKvQRxnZr3UVjAjr5LDsUBl4Ymzg4iSLvU7iirppEqainxD6hF3(I79(()5YNjCgRn6UGEkqt6NtzSN98RzsZ2ouXVXoYjB6BMmX9eexCROSdXSt1WZaoEaG5qdB3Xg0qvstB5PDHU10Y(zhLOJHdip(TeVAnMPmkPJ0XEZp(efnarpNQYZaYvQpJFzjsnrPxsgcRNTVapLgw02ZLLnrJzKIpuD0hfD3vbAD(XSgPAzowxK4GOvO3jJwXPwXXQUw5pV8uTwBxX(vV9n(6cO7V6T)75tN)QP)41ZE7B(CwP1WTV9n)NpS6WI1BEiVy3Hf3LxCyX531uo7o)WIcFvc2pNEX28noAZ2VlFJpztpSWP97wfF7vh(1)LBu4WIx9thw8pZV3XVYpF(U2fh243Rkh47YBr2oE6EXSVmrLnevCZiwqtZOcVfGpPRlHBdjwLAdGdaB7AblbKbFguwba1hlopj4GIP8XtheBikrXe63jR8Lk8waMt)GKeRsTbWbGvupj6ZGYkaOCkFVwYYx0RvgTHpkYGysQgMgz4TaSbtt2LAdGdalGjkovVEbQvvp2QBnTLpgkXzfD12MMzS0IZo9jvSKbXKun4oYWBbydMCTl1gahawatVwNubbQ1jvSpZb0M07ZKkHNDbAMHnP6hEA8rNNnPObnQGRc7a7bjpBuLE9LdhwWRH9hfxKPZt1aZYlH00rQ5GpTb0rfCay17sOPbsQtBGCubxf2uxSduQtfEvGt1Zxq5ov4RbE20NULPy5vA6mJl6i4I2db7DSWOHABq3k2aJEdUIbTJ89uLwjIJ0UTcGWuzAUWyJVjKnOHMGCBaDeCb2YjNl39dvoFUfqfwtuKumUL6QjJn(Mq2GLGeKBdOJGlW(0mRjcHkRMOOVDd)EYy5xQwTgB8rqgVNYqiHegz0BjiZAhA8rqgVN6p76uTFFtzwDP1NrLx8())SRPk2)h9zu5fV)Fy0)hhTi1vhb8cCyrhbx8((Hr3FC0Gu7Da87zyrVb3)MoUMMNgk3dn(iid4BfRhB9cvwp24rDnXBqlTHfkYmWL(hZpz89xfjIh9wAgXtSbocAzWIvz5EqK4XGhXkoELM10XfDDCtD(mQCNk(ii3mZ(4tDSOnJAsqLBq05SDmhi2JM8KDSXhbzG4WWzHUFOMqVmKfAwYmWL(FqvY4JAHwHydCe0cTbF3u6brSqdhXCwELMpxJl664M68zu5ov8rqw1gkjjOYni6X2okZo57Y)0NY)SV(fTWNg2BpS4ZRkC)UJChBwFVdmpzhZn6dl(KZiXHfVB)Uk6UpVm1M3FFhQxU0t8YSDzVlB7QF6WVEyXF19Z3)7(cCczwrFUPKHwydfotx78MqRhRUHxpuIw0nW80YV5g4NmTFv538a(L)WQJZN2Eul6CJ1qjGxKVF5NpDntUl8H)9shsb3z3RwDVNBlJUk(rv11kkfU3TA3No1lNrZFEuXS0j6npOGvxPeQBVEvdQglMhI(2vo0HR2665ydRzQD1tQ0OWg8)(Nh8)d1G)vmRn8qXQBZ38USDgxIqClnvIdHrAXWKjcAL5VBw(aL1Fcsab3Po46tkY)VRlZ32vzUEM173CZdoVO3K9rU4uO(301MSOhgSDyYX0vguXomssabhPXt4xT6Fth2FT04fqkncMTNIS532F)h3KTA7UICF9K79zou87nGMzcuJZY3VkR49UFy5Qc3WZdzfRU5JR(DkfErIXziw2jGNNmYTUI1BCAZlx9fMgu7VJdRZ7M7C2NUzx(xwtz0HGeCWDROTD3Mm)23VE60P0Whteod0VpaSKHZeNlG3TEzzTE0nl83wD7UCMrzgk7WQxkgre9jNG5BSiBGNCQrnolrNCQqmodXMCIN6qYTo(jNXFhhw5jNKKGdU2KtgIWzG(KtwYWzc0KtjkpXksp8CU6NT)tg9VBUYoip5p8XBtEPp)BR8d(Ixm7V8I5x96lY25lOn38bFh)KlQF5wAvXBQ8CU0X2WlL)KlU(YzZNm5ss3Ellwox86JFCNFVe3M1SXK9pCXSgLbrz97)2qwXSIR6cvV9tLN9L(kEBXAVetWPGpdbkMBHJMRKZLBtrFUdOIjFm8AtAudXYEThIHn9DhvWbG1sFVg1qTKETH3HnHvhvWRHv8s)9H8J1B0BUnRyjZMwIOPJu)nX1xmLoOrfCvyNd07ttdKupcNG2WE73hvW58SkR45QnZacVfGnm6zxQnaoaSazEax(m0lqFUAZybElaBWWTDP2a4aWcKyIwv(GanPQtG(ETXcegG1FtgMgz4TaSbtt2LAdGdalGjkovVEbQvvVNuFBwpgj(0ZvBMeMuLMjx7sTbWbGfW0R1jvqGADs1t621WNujtBh29C1MHv985QndBxJ41vQ)jX7WEtFgvWbGvVlHMgiPoTbYrfCvytDXoqPgb()h7DSSBBJK8BXx4Afd7rIYAtgaBFypSa7Eix0Cw0YsY2crrsGKkZoab(BF7hK9ZQQUOE44fRacqseBwD1vxVRQBsAlLb5OtE(YeV3xWBa85BBMuCKNVTzsPg78TndtzngqUdCO7bE3bOZbUmc5eZL7ddQNVTz2l43ji3bnb7bE3bOZbUmItRZCISG65BBM9e(CGmFkvhsjeN7eGojvDQHphiZNs9)78uhq)GCMt9iWPEa9eYhi()tdxusRJm8c84cDoWLpT)4W7FA4GssDy43ZXf6w4ESVDhcX7Jn85azg(wH6X2bb1Z32mPVldsm4omJm1m0fTYNVTzsPR(ylpZfV3x4ZbYwj7Z32mho85azg5Hbtd9Hb19GkZsdn6W6WSC4fQ68Tnddn0SZy(r((G50c90WDFLN5I37l85a5K6qpFBZiphf1t)BDQJOZdoFCrh4m9N1uVpb3YnVF(tExNfM7YKEzxOG0YGV9Q2Z)Zbot)gJz6g0gkVBuTbyNQWt1fNZhL57eDX58EpF5joTDSMVoqp)WmFV30ZJ(892)(FPKCLZYGCFDQs5ZjJv)Rj)XKXoFtIf)3Voq(BnhM0j)JjJLhVWfcfjtgFPa6Q)ySmfEP082JpCV0(XBp(ZFkqB9zuD2FnBL6e986uHRsZBpOQV9ywsiny4Bp2tnqXSEHbI(xLog4jNtWV23722cg1dFEXQINMwwoTrZP6j(32pIPxm7AqANxH6Tn1lNP9YtOr87kla(iWtBQQua85LV8ADHz5C3BpoSVhAe9LhpADwUOQELyPu86U1I9aykh03yEj23OM)Th)KyM1422Yf)Oq(7dUX9RNTeP04LDQx6Ffhf8uKnaXyQxknjijEJMmwZ0nzS3PrEs9KVMtXJrVYYAzcXwmEl0CINnm(zQ9LWZoTDhd8kAsT1Ai29sXwtYekwwLtxoVyXpuFN8NpV6gPZfcY5TnYuaJWDt)lHSSUtJzFQhgh)8fvsl7f1Yp9(1vgGbHu3jLpZ1S0NiXKltiPOEy5I1QqHQeki)wlT0hHqLJsluyqem5chfDisf96GGXqubda60idlbcFldfIw0QVfT2Ur93c852a8zZ2jJRwuBhARpMY)1k5xeFPZHB3Uyoq)ZQriZaqIBoyu(HXh(qGytdgs05gqHZfYpO)ILY2fZwoDvrJTv5kEuWkwpW4fJZMiWZcnA6QyDPG)rk5fiqOz0npSD)ZSbnkuQarBKEOiAZ0shwMARptlH645OXbevQIxCqRjFGb6IzTJ7cVH6gYOrFIZZ5HBa50eg3IZjakUnig36bP26HgDHjuTjNcWhqTHQNqq5yRYoIjDKKT(VdYwdiC0Yvd8OqM6Jfx4fgUFTU1wwFcVrmVBcYssxwqefIw98LeYpIIcXYb4A88hhCocreUsVArLTIwThGWvaC4TAjQzvR46jsOKJy3Nbf7qS8zf(qhGve8chBCjn1Ys7jUw2uBUblE2AVtjIea3gAESQ3CfT(lG0AF)hSK4WF3t5ghIleAakXg4aZbspbQ(8(qlXKzzBvpAGor2g6jQC353b3D8VTpS7oH)oCaIXrx5gkgIXhRVV8ILcjGSbJ4OeqZzk8TgK1eq7Mddk4tTecTJH3Pt3swKxMaHPezK1e0pU3Y638Gj6a0vda5gVn7nUbJO35gmY35dgREoMLyiec4BalWHONOj6B2SHHP2tZgcDL95eli4tTSHMImOUkOhwCR6QGwHhMhnFZUNKPaCT0yFsKDGgzdZrKgzlDVjgTyzWpFkrpn2fgOUg7qUsnT4j6aoLySq9JeLdJLVbLnxAMoyPZV9oGyWHCdE4pC3XbFSNHccm(Ya1HUPvYQQd6kBxnQJqyhirEaUUIg6VS4W5HESDO4aIw4xuO4S0oahTDW18QLxo6bVdcDWrMGDBdAXv8rKcPBgijUln6zZizY1IMAd74pCmH2fc2ZdZYbthF0sa4vrQrFWQnB(wLWR21fFB5Qva5HisHawSTiUByL3Kfq737t6SLDLCFBcgdD4HmBci(OCO4GfnWlithjvjvE6IPXAfBFHa0JnvkPYrSPFa40N573k9TnB7lH67CRFX9r8BoW590kbZhTNm0A)XTQp0VxEHuZ4MLZRAx5O7oCS95uZQUS)bGydWrSW9now98DNN)URsjyy812ujPr1drXgUwns5ZKc80gB5OZWTDdicOKb3pT4514rvclDKkpNSKEUiu0jQTzBhwmNPC3ggiajpkAmO1MdAWeYnXtowSUbsybvMJVKDOMzyTTALTzjCVCY4QvBQDKHKTUqyUCce0YplOXuqd0m8bjObv(KolOb3F6ycA5WcAyz(nAmCf0szGkEYpkcAewQIDbINGgqyMHcA5kbn8grJi67my3WVhO3wUkMfB2MDRRH5(A7dNtrz4DZB7H2DaU)sm0JBQlfK3T(jzxvxi7CNk3Qk7KIet)b7I8ORnsrV7Ln5JJMtbdQSZCu764Tgg9UUH5dRRXaBahZxcVQTIPzIefK9dPtxtb1sKP7cgd2y(IdcQY3tBk8xLp3xWT1vErWClKY2uwORVsiDlno61GG5EWE28I5cbG10TKud3HT3SeyIz6MUE9YxxQ)kJa1jrEgjvqkUJ4KKhzVRBK8YmSYpTAPGFv1X7XXqdBgnlwOUvmIOP7UUb7c7Iv13mffTBKsbw76U1gpuVefq6aBbq4cOzbVl3puJDKyoSqYPz3GQuT3(dabn3rdH7K4vLgcpFEqEqce6BekJl0IMxP6tvhszWNPgOA8YHIcXn4KR7vtLpTEX33UOQgQsLSPOoAEaR6NtZ81YupOF)eUl1MuaWwWmqvcLht3IrlY9O5UA(GkzuK0F4zhXYe7Zv4nfkkfyvEcGVVHPgOBOEnv(m1SvuUR6vWQ24VJ0E2zmY(WWo2Uk1xD1aL8GccQoEfWOKYqayTBcit2pduc1tLZNnTQ2LyXCHrIbDqxwIzwpjXFlElKUcxJWNGRMtZnCTJlTgZxQFw2MSIjVVNtBUORRH2MgL3ckhRSb2J(s)GX2EkR0c2FXBlnqzBu237WYP)hGLtSsZOKW3Hv0hHnOqD34gb2lbQPLZMUwqW2uwUOXrxCRdGA(G1OreKK1XP(N(WI(IVgmME0NIZ42(UQ5)vXAe6jBoTvKoTGCJtiErLLAao1X0ZJcupZsrg)ein56eVYWCLpFAHyhkNI3T5GzOOCkZywDIsJwfpjd8YHC2ed2(f3f1PEHdf)o)Zn1NHDA6ELxtzSY9MCRaXRlkpOLKNkbJ1w9c9FUy11JNjgGGq4eOwG3AHsAM9HPRwvO)pfYJ9N(W)1cdNJ)hz4EMgoBqtKyBE5LvwZ3v4o93k)rK4qvYmsD4YSqo60SyOKoFrmBcrtRA4kMERzh30INfAgle7IlN7E4POORsE9z1flFon5kCtyZwP(k6qLTYM2nEKaBTyz5U1Oij075JwbSy4UbcZKNziNsiijOHcKw3ObLA94BaLzJJKuh)zYSesN8Q4hgKBp6ivXDyDViuqzUa4N9SmmIEip0MJqucf5ce3f2M1HVhmUlg8q7OZvziL7oxfXSKUZidf7AFT)56zaaB90UlZEVia4flUz6kHP(zVUugjZp0LMfmAgCFLF3iDpOuk(lKY1d2H2ejFjoXyALzsFfWv45RrtcdB(z09z(ZYtaQcir7fqPKhZqNRSvJ4NKS4kv2)Mg)uJFqEkQSKM69A8Cb5bBVurNL87Io149aRsrhY3bwsTbsriCZw2UMDyTYyIizmWd)KZaJcQBIGOtwn9C3ZF6P3zYCQorUtHrekTfMc2z(uC77MmvY5GDuWFba99g3L4s4enOpROwQTPegXIlBr3aNriYEOLauvO6cXBlY96(xbzvsx98BiM)34jq4NmDx)iOKyDuZErkpCntgsTgUtLf3EhMZYEcwJycRl5To7PiBPM4EiUSr7pfrUBtUxtJ7xLwoTNju7eijUR70bvyL6EAx5Azb()tPrtVbWGJ14mesAAGabsaQr5fkXkVtbgeb8StC(PGw4jwqezCg4iR4lYHwdAyp8PrKKoAN0kycz37dkJeD7iW3YnO20KAbJH)r2TM8ufBb398ltrCS2lI7vddsgAwpWtJW1ezYsq8o1IL1Yf6SP2jJGqJr9(mSSLxPE5iL)jtzJrethYUG7ogvt3vUunuSxAGHHGmejBdrHE5BHXXZ7D74QhcTZXrBI7mSKOn572r0UbZbpvkgrs3wOGOqm0M9jIfUrafSY1xI4VNxogdFxpvP9VzuGaCB1qagNMpgmVgWPoGOSrFqPhWn7emn5f)Rrly1k5XHAe0IvpKcVqs(ar10Ov7NLkzaoTCwuh8quGmkGgex8TeuSHEMmQMjM5Vl9X8PYDIFBz9Fb5iA1MDRQMnTemZ3bLlLOKyjDoNK9c)2RkvvMoy6j(ITdU6E0CG1v)yC13Z7u2Mhg4IaL)JuokLJ7zkY(gXMgD)devW9Ralu5NuCuknR)gK2eMUGPrY4ournTkOtRqnKMF)BX3LKG3qdePs2tLhEK1zP9BoHYQwttx5lpSp5jgTJwbv176OwSYcphEa1LqNNgdsfoceJcwlU4EG0f1j6vWLMk1lE(N7B6ONUrGVSR0ypMNG3WESnmoXPKnfwO3ie8Kp(t6ww4AqzocnXdXDwHEZoRtbYNMHoGrEa)YbF6O2CZ7cG(Kh8CpeiNbdt02MrxE44(bgla9)kKyyX5Hj64uysdDTK5zk1rphvg2d9TfSG3Tx1ua(7DFBZUFrSq0I)J8sFoK8eBzFOYFU2NJ2OoFDiURwXjQKGbkjfModwpyVuHuZzvXZLAKF6kT3t30FWBU1GaExgqoBqWgSqVN6UWP(1Yn)zvSxsQFVq7HMIcLOVzHo5nzrzh)Jd1dIebhm1WeNmH9rqtB7uLUah)HJAUY6jJFDX0v1VwiMXVd2kzwKrpYB2oRwbz3xuUlVO6vbLZoz6NRUIO8QoL3ewtDfx3XjC56FS8LnYduNiIn5GL)DZn0lfcGhswhrGPREryPUdtTSb9kpv3P8)x27kR52i3i8Vf9YusRQ1rMYYjpyXuj1(sQkjBQiN84krZdzwMMs1mKrXVWF7bhdWGUrFGHI6WoZlBC0aodoA0x4R)GFB43hCk)XIvwuR(BLYCfg1aPfd2DMC05Dys8GWt3NK67WRfgTh8SEqc8XXJmAAufB8J7OhUoS91oJMuhIaRWGO1K1GCS2Kvvyx1HE(jMYpYsrN4jPcmOq(KTO9kzxfF3OK9BN80SLRkjXz)aqn(p6DkcLOQWCzNl0ms0fO7FG(8hOp)nYKNCA7EXOTVc6B)aZzFvQe2OghZnqF(kkWHBf0ju(b6ZNE0(i2CHEpLnAhOp)cm1wK2tETSAlUsuZ(a95pqF(2vNb6Zpx0CG(8TVWsJeV4fUb6ZNrmCG(8paDVb6Z)q3XgOp)eDlLXp9VyXHxw3RyhkEerl8cfkErAhgOpFIo9a95VEG(8lQp01n4pQMEovPQ8CG(87j95lrhX9FX5i1QbrArPetEdSMFF1NXRmtCBP6(CzBSLOQ4jGmVFEynFPnnhH3XumhEpqw(Y6whil)x(9xppKLFP7Vg4i)YSlL7Ntz7V(bIJ8B7h(YyXEga1De2gVq7LXmexT7gWlWdT2CSUCyoi1dgkdE2OH)uOhxePBQkyqTIbvT5080oym(Bn9lwm7CTdg5n4yYIc8pAE5Fs9aV8pWl)Up5zLwX5DJ7bE5pzHqWjRXzfFWaV8tjd()T8Y)EX)1eSSII(lSSB1okcLNP3ZRutJHMFvqg5y2INxFL6W5Sxbdhc2I)7C68hRrrMo)79ULC2IxLE9h)IZZ7kuMFVOf9xKf1mEExZorpgqP(DMpOQ0AqYbU9DbpV7So1PnJNN3nU2A9PIYzEK9GckRe7SblE9bU0tMBOUa0ykkcwf0oJLhcIKLzqIDAJNqhp7nVhnuzA8y4PeRDA7UGCvQyeu8EKv1ZZrCWyU9ak0jrW9kDlgNQ0MQ)qSISLJfMMPB1KnW)QZPDjsZJiRjIZplnsUIkvpUKSw4uz5yvV4PoHqYuc77XOHjvgxUbFOJbzKhtjc8PrYljYHFkF4QyBDkrRYi5lSkRj2IvPrYkL5uPMOQpCJzfvU4nxaMFJ6LXl6X))mKjbVFFpDtBuHkcJtmub(kbL)i6DLqZMNF4hqcmXJN5cCSFXiU36B53EctyaflSQCDnrSjT8dZkF2IvJG28z(RvWdxHSiGHhTBqU5Z1lxTkCEj(dlA2KVIjNK0oW76(1chwwXM9WA4sCeJXKyUfhblekP9GZP(c3oWQCcKBowpGQentI9pk5L6(Za62GStwHCpR5ZtShZMjMrtSJBwU(BWpMCoe7iQCzS0jSwG4GMopUH(ZjKSh5J6iBFlujaGfs5DDq94uKLsgNj8dcG99NjL(8dwy9iMnVxjSHs9DPkAjslOoBxNXlLDgTOzNhwRmYDZ4ci02IF9HKk2LxQb5nbYsqcP3r3KaqyX(hSZqwo852VAMtAEZM720sKpPzmG3(bY504jLf8vxLBhZmZ0Rl1L0TgxWO)kU8GsVwBqmSKdzCR2P5ce)uNuKvySXjwAF9Mp5xKezvYteS7jYDLHadoInGtA3q3Bya8AFMDV4QT89LkEI9hL3s8mO)T)xpbJawhb74GMhfydxjpnE1sazcl8SU8FKIbcEfZcC97pkZq0HA5zu4oVV4tHRrhXKTR2iNcxahJLnRlE)ussSAXo2YM6T3RLIpDmx0kEqFLifz0YFN7FmYMJvZFZ4D8KPF56pBl8e3CVVDDz)k5QOm1tecDnT(Q7dt4uBf4SRfDGNgmfGyT2oyo8(UgLDxpyFV)K3pB41jQZLH2doX2TU3cNUM5tVBn8(fTvfpvgelysfaMvnazxbGuN7khWk)0HXka096ZBBeXBRC8)JM6UYJfq7oX52vatZ3DZvHF2UB(hD9b7AI5)oF56BdB9AB)FRTuEU6BRN(zZJtNZB72DDaBHJoLk)L6RahNNIlQmUka2T1ZNA0ynXig0mXmjyChiEVQo(sGdAuTmlRNP31s480tyXL9fNmkmZax)P7wVTXENc8WK6hwUXmLAxjBmBwgD97UFQAaRN68SFSqcbpbjg8XL2v4Zp3IFn)ENnqrIiwrxz8IB79MxHTJz(F(7HHJz5pmEaR)Pf9fvUzFcx2p8t8(3igrWiH7WxfQWGRu5cTohmZHv4mfgXL(ulQWch5ySgM(85Fm1TsjcwnrLotSL5xQCwOtnBR5bBURtFJz62)h8S5jJawO8djsMTUC2rQCjwfutlKxkYN4DR7unc2c6V1jyBiSt7KR3IFwb4IFc2ydZNfTo)lUk3C3nweG7QDZOcd76LBj0T(UTXVCAecmgX60IL8dMSEM9)K8U8jLn2K0vFqfJsDkb6l7lMSQzoA48VAAL2Mn34Y3xn682DZsJ1VhC9chsITkyMV0cjFtp18iZ)Y8pC361wTKnBAEtAh1ZeGuP9hApE(9tQDSkJV)UYZW1U5oBzd4VufSDI5Z7gtm3j2OdUN96ya4G6KALdi4iHl2H94cS17299M4pU7RFAcPJ36RHSQUQYuRfU9NUE29nXWP6HRDOfS)DBxjSiH3a00kqVy5k78Nv43emtIpweol1vsHXie2VzdSDKQmBmIZgf4AkrVFeO3VhbVawm4iCPsnUM3wgw3GQPm8BaX7mYrg0VMe(iHQbOs(NQjmSrdSr00ZcqE9pVY4TRDdi0XUMoJRjQIdsobH7)s0jRwP6uV)2yXlL3bXF26xLrm3ERG600Bw4QtFXgHQvZT5ZTTOH2DZh)1F5xT7s(V(oYd3v)fRE1fTX1TCQT3SE2sB7nDhJHOnZNmZR615pXIV52Czwxx(FwoBR19IUXMR3Vy7MT1Zntm3TGCtNvf3Jm0qw(nl38BHISJkxKvIsoiENCISJ0ezhPlYYrKG5nIwKLqPsy1P)Hnk7z)5xp6(PGSeGU)w4cAPEo7Nn8QQV9AlFLfYP0vNfDmn8RqzjgM4N)qAlXznfN4kZh179r0cA4xgO4EyIutBre4RejEAFbcySqOypZ8oGf0JdcgduUUxoj3rlFEtviCX4IRpXZffS3XNl6UbKgfzxPboa3yR9imxSABT7smknxMaSBQakmefAN(jeqdHTZXKDEI9guZcuWVP9rWm2NLzr4Jt7WO0buPLtAC2IfUwk5p12x3dP9b8uXHt3UNSEmnCGurAlmnvzy7takp8hX6X7YXfcotqKqUKxbKcWxqWVHUcG7gk5i)qfRv9f4A9bsR9dsLhQzk6Tvsa0Qme2YEFUUgrCB8NkrV3ujONqaGvVIgqhtb)baMlO0JGrjAuvIqPUTNd6ce44XBzb4YPWIP7yPEIWDzz3osfmMvey0K)w2xt3Jndml2HQbj7w)OqkWxlzobGWZXnfuyFFawVy0E0ThlP8EGqPSUpFMAann4(ykGKM2dlzd14cosa)uUVb2BWc(e4s8J3aBRWXeJlGMWmn7YmXWtz95tBRxBhOpy9Lr7eHHZQuaarXi5EyokhlIvsrkCCbLmLFRGW9idsBld((H6ceCEQ8WieV5LuXtvnMotWJdkeGOPBwX0ermWb2XqfPu5cx(5RcGhg3AVoWeLxUQk1v3uG4kCrJR4Qf0N0J4mkuvUrhMTzqF47VCGGJXESCrfilkvfxK2ojWHvgkFYVPV1ZH0M6TZjpohxMx(T96qlOSxafwjv0tkz0(mq2mUmcr24bwxFRrJU)aQP1IHYw8FQ1)JD38pBpFhqYTmVRyUK61qpGFnQBQSQmpwjRG4uD7)(WVkZi4HbtJ5FoUwo2tLg5Mcyusk49DI)y46H(KWoBIH8L7k4cZfKVtixCOqKfczqIuA9yO03SMuGNZoYR2rFxKH9usbnOphDw(KyOKloypaUXxuRqj1T0hYQBPtfgENeECuCn4xp7B8Cie)K9wGS6W0TkDssRP77e63MLUhGvxjZVAe)VIboxclgjPMs6IR8ic9Z(VrwMictgQX77E8K6i6oAPzUau3I1VfHrFampuT))HDLWm3OcYjpQkLc29PERY7EXwsJ1TdM36VmYrg7)D9wQMZ85CStqrDSsWxo9MqwoTYbyK)2wcv7UBV1mBKCIYvmAnY86K2P0dK745JwpcwUE5c9bbEQP9a4etGT8Ex1ZR6qrNHvYaJCFELTs(fbKsf1kJd08As3KlOpjDyNwIzg7quFI40INhorDJ5OZyJ(f6)9F1H22D3CLTrEWoCLTzE43Ar7acqgV7NBVsiEW4jYCNwQfZR94oYIRch0KIiZW((YsxGW5vevQL4ZiTATOT0CUqmrNenS1CB9iuu(w82TffZICSQDd57X8kS57cV)Ol4zYqvasXKbQmoR2JkmJ97TiFwkAPk)F(8RSxZuueEjXFgyB6c5MmoGg)csGe1iSGdPGg2c(NMv7jG2ecnHO45bMX8ptkNI)V27AB324gi63IFzXQye0yRO28GTEP)hjWX2OnannfrYnO9b)TxT3i5C7mZYvY1oTp1IODxtoC4C5mhouOfzVQErIG3CDtZ6TurNhQbO6H6krPsRulFrolMShNOX2KILKxhJH8k)bwq)6nVfYR1mNfS0Q1FYo2aYBoc(tuEPxqYyr)l0PRL5d4e1otHR8bq(y9ruf6D3MU321grxApIUCbJi47MhrRS2E(8AVcfnsqzZ093ogN14es)q(1GDCv4JHJTKPpTmWtgtAGJDSF7AzqKj0xklOLy)mxA24oFjvJ801fLaTvQMqOnM)7yDZtza01fpA1ZO8Qvjp5TzFcbM6PI4QwwPOT81IMewjEbyxrB8w(2QQQM(zpSxymtk9O2hfrYRCoADfuq2LxHyJgoISCTTZQhdyO8kkaGtViywPri(4nNYcrymXDMqG2aLY9TAGTanMPdGhi2bL7wb2Rml7YdLLEpYkuP2vua)8HAudJYvWvYUGwI13)lcJ57QGiJo7FMfPz0H94i3PtHvYhai50qosUwTXBzdlJIkBoH1LQVQPZtgQGzIt8oIP5ksqPk7qZsAghOandfTVvjWvIoe9S6NyJQCba2qPhcfU3SV8UZuHvNjp6kxhk(i5UXoid7GhpDoql38jBnCxotK7rQfRTJHYdMnqRFBcqBTghhz1A3ThgHFUtf(JF9Hd)BFApFz703k4wBhmfwPHv96HX2uRD(NEdTD1R37UETMEBxt6AOlYSbSWzhXuw8Ah)BbBx117xBhi0mI6lA4UnEKdvjuT1omRqVHm5IQ9Xap9l3Op1ds8fBBRRj8mZM(yRDQw9)3dYUh0dYw7GpYlnPNMiISRpDWjw7avsn7PsMAUO8kKxCJRSV)yT2JJYP)UPOiZkEF(AyCpcGz28n7e3YR87aeN99b09F7BRPFfVt37uF7P7Xl4SbzsksDsoIsjbMBdAFOSDnpoXbFHgXhGiBhTQ169nmW4ZbRRv2jeSwBOPn3W4ONeqMyLhaFk(hHMCFioZBQwsduvNz(JnbSvLUbK3nk2BDkeGhSCC3T3SBpBLz3(hU7W)TVG)hEJ77knpj4bxdxr)qTLp9SPjJsoVKD)EVghPraiSTHuniFWc9ecu(dezSm2rSLEYhnNXEeDnFVixN5g38gcR8cuzj1zTfuB06kcXwz1rBXWeKZ3W5Pw)iPK3g2(0(lxStSKxUmq7mm4n8qRicf0PTnWFXtCz7NNnsVnVDXW8UypQO24G96DzDLlw1zbnLnUHSFYR(KcJ7wxXTBlaMtQtzHDrW9VeFyYNF06e5hv9GZJriZz3lOE4DyrHM2LYg)3hTm1oK7iqGpMbgyoLcp4SHYdinQyiB1YYTZimIl4yXEjIlIR)AUxM8Me9uxRfyvwYMGnER0Qb3Pz98J)1UD38BF4xU5VVVCFJNzZLe45wwTujJtPjwNefCct2okCZGxTJi1jD6ajZ14HV3vJYdWzysDG7Mpo1w0MW(B9CYp5raFO9hxJ)DsRnzfvEOMDRPb8ImWzNfi7u)JmxA8Lkr8Njl9L7sFOn)YtgKTG4OtHJG8P3oIrmosTEsO0nWwZXjFlYL)MR95iHOL43ox4QkfmNKVvHNr(6mMFU(5yoLlOXQjrCi68)kLMxsMUsh9MXZtO(NS5TewF6hn88OiRYn6fBCcBTGgUWaUD9rYBt(0Uo4bpSk(hF9EwXPWOdUkGSxBqEDQ8RX4GKZij5fHHZPi7GeQfv8Xgd)awVgaJ(vDZ5UJVcNjhDFfas8JU)6WmYoG1jnMO5h0xfRSe0nRnYzrG9CYGSUUGs1RKi6mDeio7ZtPu7zW3B50Q2vQlJnCehw(LbOHbMKvqVX)2a8dTmLJ(zkePScTKzErjqFc(FeEYGs(mvukDIT4(nXovsgazo)3Lq0fXhaAX86htDqFKPogeTcTjx8R4ZKecv39LV8zEcEkxJG24BGTljfItY2amEVy8EB3)tpvs6j7zipi8uQDwhkFugvMgmCRXKjSpr3(cgA2B1OGq2T65MsA7uSktwS1PGjGENIaWUMLo3mSXCvIhoErCoTR61u3qH3SK((w442uZhlsDQcLY1QNynbi0bEtpfIHEEqP3RIwV)kKA1YlGI0lGSBRqdrqto6iz5Clqn4PSh5fpCnr(dCCyI7umyRZBiJPNzxJVGZOIEIUiRJi)VGJeIpuih9l0w7eMMxFZtgkQmA6KotSODGcr7S5IfeZ)LVFu97ATksNjTpsOuqsH3oIl3pi4KqtojKOffBM9TpB12xAuceOTQNVyZsiuj4ib89IeshFYlFxi(6oW9r2DJHTY2mtEopagVMnGKelj)s9xTXG2plaSP(0kF2vbVwidk1gZnaABJua8ZnmP0)BHI)Qr1EEOKH46AGw9Evmm4FZ5MHhmElDtwtbJQbyBJoGRBq6Qk1)ubTHc7kPMwi0JPTrr8WDXLZHpz0kMR0mAD1oUsvpUEX1K(MGQUMXexmF0kx(4qrbYbOSIguE5Er3Mx(Cfi4ISPMG3WzN)fGulxoVAAX6TU1nOuUY3tlh(uhlUD1C1S1n5y5S)4Pj4mj(p3ggoQkhZBdJ9vii07dzPwc)(uErCHXacQv3kJejVQkjUyA3hkb8Sm1Rh8C0Vixm7h7yhmUcWaEGuJQH(Y6iRQBTfufwV9fy7a9)ejjG(cHeqkfAtRh0OXGTewwg)SY51DxZAIicbjxUK7xdn6D2E8iS47ohpEmFvZdnhE85VoAQKjmCYXh1bwbNG0AdiGlmksxNrcw7qtDtbC8boU39kGkmWV3EcvBjpw4AZAsIzhhMcAtE(6cAYD3sEys(t7aeTXcYGQtiXPUVsFCNJBAqg)PsrUnukNco(WWJxuNY81EJz9TayR75EPcXNXyW29poBrR6zjn1xuIjh7dd4KRztJHA6BJcVAWZ1Uag2a3Jh2xlkDV2d7)1UBZ3dgD(5()L3)p]] )
