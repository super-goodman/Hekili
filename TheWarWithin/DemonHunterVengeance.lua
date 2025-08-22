-- DemonHunterVengeance.lua
-- August 2025
-- Patch 11.2

-- TODO: Support soul_fragments.total, .inactive
if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "DEMONHUNTER" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local spec = Hekili:NewSpecialization( 581 )

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
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
-- local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
-- local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)

spec:RegisterResource( Enum.PowerType.Fury, {
    -- Immolation Aura now grants 8 up front, then 2 per second
    immolation_aura = {
        aura    = "immolation_aura",

        last = function ()
            local app = state.buff.immolation_aura.applied
            local t = state.query_time

            return app + floor( t - app )
        end,

        interval = 1,
        value = 2
    },
    -- 5 fury every 2 seconds for 8 seconds
    student_of_suffering = {
        aura    = "student_of_suffering",

        last = function ()
            local app = state.buff.student_of_suffering.applied
            local t = state.query_time

            return app + floor( t - app )
        end,

        interval = 2,
        value = 5
    },
} )

-- Talents
spec:RegisterTalents( {

    -- Demon Hunter
    aldrachi_design                = {  90999,  391409, 1 }, -- Increases your chance to parry by $s1%
    aura_of_pain                   = {  90933,  207347, 1 }, -- Increases the critical strike chance of Immolation Aura by $s1%
    blazing_path                   = {  91008,  320416, 1 }, -- Infernal Strike gains an additional charge
    bouncing_glaives               = {  90931,  320386, 1 }, -- Throw Glaive ricochets to $s1 additional target
    champion_of_the_glaive         = {  90994,  429211, 1 }, -- Throw Glaive has $s1 charges and $s2 yard increased range
    chaos_fragments                = {  95154,  320412, 1 }, -- Each enemy stunned by Chaos Nova has a $s1% chance to generate a Lesser Soul Fragment
    chaos_nova                     = {  90993,  179057, 1 }, -- Unleash an eruption of fel energy, dealing $s$s2 Chaos damage and stunning all nearby enemies for $s3 sec. Each enemy stunned by Chaos Nova has a $s4% chance to generate a Lesser Soul Fragment
    charred_warblades              = {  90948,  213010, 1 }, -- You heal for $s1% of all Fire damage you deal
    collective_anguish             = {  95152,  390152, 1 }, -- Fel Devastation summons an allied Havoc Demon Hunter who casts Eye Beam, dealing $s$s2 Chaos damage over $s3 sec. Deals reduced damage beyond $s4 targets
    consume_magic                  = {  91006,  278326, 1 }, -- Consume $s1 beneficial Magic effect removing it from the target
    darkness                       = {  91002,  196718, 1 }, -- Summons darkness around you in an $s1 yd radius, granting friendly targets a $s2% chance to avoid all damage from an attack. Lasts $s3 sec. Chance to avoid damage increased by $s4% when not in a raid
    demon_muzzle                   = {  90928,  388111, 1 }, -- Enemies deal $s1% reduced magic damage to you for $s2 sec after being afflicted by one of your Sigils
    demonic                        = {  91003,  213410, 1 }, -- Fel Devastation causes you to enter demon form for $s1 sec after it finishes dealing damage
    disrupting_fury                = {  90937,  183782, 1 }, -- Disrupt generates $s1 Fury on a successful interrupt
    erratic_felheart               = {  90996,  391397, 2 }, -- The cooldown of Infernal Strike is reduced by $s1%
    felblade                       = {  95150,  232893, 1 }, -- Charge to your target and deal $s$s2 Fire damage. Fracture has a chance to reset the cooldown of Felblade. Generates $s3 Fury
    felfire_haste                  = {  90939,  389846, 1 }, -- Infernal Strike increases your movement speed by $s1% for $s2 sec
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

    -- Vengeance
    agonizing_flames               = {  90971,  207548, 1 }, -- Immolation Aura increases your movement speed by $s1% and its duration is increased by $s2%
    ascending_flame                = {  90960,  428603, 1 }, -- Sigil of Flame's initial damage is increased by $s1%. Multiple applications of Sigil of Flame may overlap
    bulk_extraction                = {  90956,  320341, 1 }, -- Demolish the spirit of all those around you, dealing $s$s2 Fire damage to nearby enemies and extracting up to $s3 Lesser Soul Fragments, drawing them to you for immediate consumption
    burning_alive                  = {  90959,  207739, 1 }, -- Every $s1 sec, Fiery Brand spreads to one nearby enemy
    burning_blood                  = {  90987,  390213, 1 }, -- Fire damage increased by $s1%
    calcified_spikes               = {  90967,  389720, 1 }, -- You take $s1% reduced damage after Demon Spikes ends, fading by $s2% per second
    chains_of_anger                = {  90964,  389715, 1 }, -- Increases the duration of your Sigils by $s1 sec and radius by $s2 yds
    charred_flesh                  = {  90962,  336639, 2 }, -- Immolation Aura damage increases the duration of your Fiery Brand and Sigil of Flame by $s1 sec
    cycle_of_binding               = {  90963,  389718, 1 }, -- Sigil of Flame reduces the cooldown of your Sigils by $s1 sec
    darkglare_boon                 = {  90985,  389708, 1 }, -- When Fel Devastation finishes fully channeling, it refreshes $s1-$s2% of its cooldown and refunds $s3-$s4 Fury
    deflecting_spikes              = {  90989,  321028, 1 }, -- Demon Spikes also increases your Parry chance by $s1% for $s2 sec
    down_in_flames                 = {  90961,  389732, 1 }, -- Fiery Brand has $s1 sec reduced cooldown and $s2 additional charge
    extended_spikes                = {  90966,  389721, 1 }, -- Increases the duration of Demon Spikes by $s1 sec
    fallout                        = {  90972,  227174, 1 }, -- Immolation Aura's initial burst has a chance to shatter Lesser Soul Fragments from enemies
    feast_of_souls                 = {  90969,  207697, 1 }, -- Soul Cleave heals you for an additional $s1 over $s2 sec
    feed_the_demon                 = {  90983,  218612, 1 }, -- Consuming a Soul Fragment reduces the remaining cooldown of Demon Spikes by $s1 sec
    fel_devastation                = {  90991,  212084, 1 }, -- Unleash the fel within you, damaging enemies directly in front of you for $s$s3 Fire damage over $s4 sec$s$s5 Causing damage also heals you for up to $s6 health
    fel_flame_fortification        = {  90955,  389705, 1 }, -- You take $s1% reduced magic damage while Immolation Aura is active
    fiery_brand                    = {  90951,  204021, 1 }, -- Brand an enemy with a demonic symbol, instantly dealing $s$s3 Fire damage and $s$s4 Fire damage over $s5 sec. The enemy's damage done to you is reduced by $s6% for $s7 sec
    fiery_demise                   = {  90958,  389220, 2 }, -- Fiery Brand also increases Fire damage you deal to the target by $s1%
    focused_cleave                 = {  90975,  343207, 1 }, -- Soul Cleave deals $s1% increased damage to your primary target
    fracture                       = {  90970,  263642, 1 }, -- Rapidly slash your target for $s$s2 Physical damage, and shatter $s3 Lesser Soul Fragments from them. Generates $s4 Fury
    frailty                        = {  90990,  389958, 1 }, -- Enemies struck by Sigil of Flame are afflicted with Frailty for $s1 sec. You heal for $s2% of all damage you deal to targets with Frailty
    illuminated_sigils             = {  90961,  428557, 1 }, -- Sigil of Flame has $s1 sec reduced cooldown and $s2 additional charge. You have $s3% increased chance to parry attacks from enemies afflicted by your Sigil of Flame
    last_resort                    = {  90979,  209258, 1 }, -- Sustaining fatal damage instead transforms you to Metamorphosis form. This may occur once every $s1 min
    meteoric_strikes               = {  90953,  389724, 1 }, -- Reduce the cooldown of Infernal Strike by $s1 sec
    painbringer                    = {  90976,  207387, 2 }, -- Consuming a Soul Fragment reduces all damage you take by $s1% for $s2 sec. Multiple applications may overlap
    perfectly_balanced_glaive      = {  90968,  320387, 1 }, -- Reduces the cooldown of Throw Glaive by $s1 sec
    retaliation                    = {  90952,  389729, 1 }, -- While Demon Spikes is active, melee attacks against you cause the attacker to take $s$s2 Physical damage. Generates high threat
    revel_in_pain                  = {  90957,  343014, 1 }, -- When Fiery Brand expires on your primary target, you gain a shield that absorbs up $s1 damage for $s2 sec, based on your damage dealt to them while Fiery Brand was active
    roaring_fire                   = {  90988,  391178, 1 }, -- Fel Devastation heals you for up to $s1% more, based on your missing health
    ruinous_bulwark                = {  90965,  326853, 1 }, -- Fel Devastation heals for an additional $s1%, and $s2% of its healing is converted into an absorb shield for $s3 sec
    shear_fury                     = {  90970,  389997, 1 }, -- Shear generates $s1 additional Fury
    sigil_of_chains                = {  90954,  202138, 1 }, -- Place a Sigil of Chains at the target location that activates after $s1 sec. All enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by $s2% for $s3 sec
    sigil_of_silence               = {  90988,  202137, 1 }, -- Place a Sigil of Silence at the target location that activates after $s1 sec. Silences all enemies affected by the sigil for $s2 sec
    soul_barrier                   = {  90956,  263648, 1 }, -- Shield yourself for $s1 sec, absorbing $s2 damage. Consumes all available Soul Fragments to add $s3 to the shield per fragment
    soul_carver                    = {  90982,  207407, 1 }, -- Carve into the soul of your target, dealing $s$s3 Fire damage and an additional $s$s4 Fire damage over $s5 sec. Immediately shatters $s6 Lesser Soul Fragments from the target and $s7 additional Lesser Soul Fragment every $s8 sec
    soul_furnace                   = {  90974,  391165, 1 }, -- Every $s1 Soul Fragments you consume increases the damage of your next Soul Cleave or Spirit Bomb by $s2%
    soulcrush                      = {  90980,  389985, 1 }, -- Multiple applications of Frailty may overlap. Soul Cleave applies Frailty to your primary target for $s1 sec
    soulmonger                     = {  90973,  389711, 1 }, -- When consuming a Soul Fragment would heal you above full health it shields you instead, up to a maximum of $s1
    spirit_bomb                    = {  90978,  247454, 1 }, -- Consume up to $s2 available Soul Fragments then explode, damaging nearby enemies for $s$s3 Fire damage per fragment consumed, and afflicting them with Frailty for $s4 sec, causing you to heal for $s5% of damage you deal to them. Deals reduced damage beyond $s6 targets
    stoke_the_flames               = {  90984,  393827, 1 }, -- Fel Devastation damage increased by $s1%
    void_reaver                    = {  90977,  268175, 1 }, -- Frailty now also reduces all damage you take from afflicted targets by $s1%. Enemies struck by Soul Cleave are afflicted with Frailty for $s2 sec
    volatile_flameblood            = {  90986,  390808, 1 }, -- Immolation Aura generates $s1-$s2 Fury when it deals critical damage. This effect may only occur once per $s3 sec
    vulnerability                  = {  90981,  389976, 2 }, -- Frailty now also increases all damage you deal to afflicted targets by $s1%

    -- Aldrachi Reaver
    aldrachi_tactics               = {  94914,  442683, 1 }, -- The second enhanced ability in a pattern shatters an additional Soul Fragment
    army_unto_oneself              = {  94896,  442714, 1 }, -- Felblade surrounds you with a Blade Ward, reducing damage taken by $s1% for $s2 sec
    art_of_the_glaive              = {  94915,  442290, 1 }, -- Consuming $s2 Soul Fragments or casting The Hunt converts your next Throw Glaive into Reaver's Glaive.  Reaver's Glaive: Throw a glaive enhanced with the essence of consumed souls at your target, dealing $s$s5 Physical damage and ricocheting to $s6 additional enemies. Begins a well-practiced pattern of glaivework, enhancing your next Fracture and Soul Cleave. The enhanced ability you cast first deals $s7% increased damage, and the second deals $s8% increased damage
    evasive_action                 = {  94911,  444926, 1 }, -- Vengeful Retreat can be cast a second time within $s1 sec
    fury_of_the_aldrachi           = {  94898,  442718, 1 }, -- When enhanced by Reaver's Glaive, Soul Cleave casts $s1 additional glaive slashes to nearby targets. If cast after Fracture, cast $s2 slashes instead
    incisive_blade                 = {  94895,  442492, 1 }, -- Soul Cleave deals $s1% increased damage
    incorruptible_spirit           = {  94896,  442736, 1 }, -- Each Soul Fragment you consume shields you for an additional $s1% of the amount healed
    keen_engagement                = {  94910,  442497, 1 }, -- Reaver's Glaive generates $s1 Fury
    preemptive_strike              = {  94910,  444997, 1 }, -- Throw Glaive deals $s$s2 Physical damage to enemies near its initial target
    reavers_mark                   = {  94903,  442679, 1 }, -- When enhanced by Reaver's Glaive, Fracture applies Reaver's Mark, which causes the target to take $s1% increased damage for $s2 sec. Max $s3 stacks. Applies $s4 additional stack of Reaver's Mark If cast after Soul Cleave
    thrill_of_the_fight            = {  94919,  442686, 1 }, -- After consuming both enhancements, gain Thrill of the Fight, increasing your attack speed by $s1% for $s2 sec and your damage and healing by $s3% for $s4 sec
    unhindered_assault             = {  94911,  444931, 1 }, -- Vengeful Retreat resets the cooldown of Felblade
    warblades_hunger               = {  94906,  442502, 1 }, -- Consuming a Soul Fragment causes your next Fracture to deal $s1 additional Physical damage
    wounded_quarry                 = {  94897,  442806, 1 }, -- Expose weaknesses in the target of your Reaver's Mark, causing your Physical damage to any enemy to also deal $s1% of the damage dealt to your marked target as Chaos, and sometimes shatter a Lesser Soul Fragment

    -- Felscarred
    burning_blades                 = {  94905,  452408, 1 }, -- Your blades burn with Fel energy, causing your Soul Cleave, Throw Glaive, and auto-attacks to deal an additional $s1% damage as Fire over $s2 sec
    demonic_intensity              = {  94901,  452415, 1 }, -- Activating Metamorphosis greatly empowers Fel Devastation, Immolation Aura, and Sigil of Flame$s$s2 Demonsurge damage is increased by $s3% for each time it previously triggered while your demon form is active
    demonsurge                     = {  94917,  452402, 1 }, -- Metamorphosis now also greatly empowers Soul Cleave and Spirit Bomb. While demon form is active, the first cast of each empowered ability induces a Demonsurge, causing you to explode with Fel energy, dealing $s$s2 Fire damage to nearby enemies. Deals reduced damage beyond $s3 targets
    enduring_torment               = {  94916,  452410, 1 }, -- The effects of your demon form persist outside of it in a weakened state, increasing maximum health by $s1% and Armor by $s2%
    flamebound                     = {  94902,  452413, 1 }, -- Immolation Aura has $s1 yd increased radius and $s2% increased critical strike damage bonus
    focused_hatred                 = {  94918,  452405, 1 }, -- Demonsurge deals $s1% increased damage when it strikes a single target. Each additional target reduces this bonus by $s2%
    improved_soul_rending          = {  94899,  452407, 1 }, -- Leech granted by Soul Rending increased by $s1% and an additional $s2% while Metamorphosis is active
    monster_rising                 = {  94909,  452414, 1 }, -- Agility increased by $s1% while not in demon form
    pursuit_of_angriness           = {  94913,  452404, 1 }, -- Movement speed increased by $s1% per $s2 Fury
    set_fire_to_the_pain           = {  94899,  452406, 1 }, -- $s2% of all non-Fire damage taken is instead taken as Fire damage over $s3 sec$s$s4 Fire damage taken reduced by $s5%
    student_of_suffering           = {  94902,  452412, 1 }, -- Sigil of Flame applies Student of Suffering to you, increasing Mastery by $s1% and granting $s2 Fury every $s3 sec, for $s4 sec
    untethered_fury                = {  94904,  452411, 1 }, -- Maximum Fury increased by $s1
    violent_transformation         = {  94912,  452409, 1 }, -- When you activate Metamorphosis, the cooldowns of your Sigil of Flame and Fel Devastation are immediately reset
    wave_of_debilitation           = {  94913,  452403, 1 }, -- Chaos Nova slows enemies by $s1% and reduces attack and cast speed by $s2% for $s3 sec after its stun fades
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    blood_moon                     = 5434, -- (355995) Consume Magic now affects all enemies within $s1 yards of the target and generates a Lesser Soul Fragment. Each effect consumed has a $s2% chance to upgrade to a Greater Soul
    cleansed_by_flame              =  814, -- (205625) Immolation Aura dispels a magical effect on you when cast
    cover_of_darkness              = 5520, -- (357419) The radius of Darkness is increased by $s1 yds, and its duration by $s2 sec
    demonic_trample                = 3423, -- (205629) Transform to demon form, moving at $s2% increased speed for $s3 sec, knocking down all enemies in your path and dealing $s$s4 Physical damage. During Demonic Trample you are unaffected by snares but cannot cast spells or use your normal attacks. Shares charges with Infernal Strike
    detainment                     = 3430, -- (205596) Imprison's PvP duration is increased by $s1 sec, and targets become immune to damage and healing while imprisoned
    everlasting_hunt               =  815, -- (205626) Dealing damage increases your movement speed by $s1% for $s2 sec
    glimpse                        = 5522, -- (354489) Vengeful Retreat provides immunity to loss of control effects, and reduces damage taken by $s1% until you land
    illidans_grasp                 =  819, -- (205630) You strangle the target with demonic magic, stunning them in place and dealing $s$s2 Shadow damage over $s3 sec while the target is grasped. Can move while channeling. Use Illidan's Grasp again to toss the target to a location within $s4 yards
    jagged_spikes                  =  816, -- (205627) While Demon Spikes is active, melee attacks against you cause Physical damage equal to $s1% of the damage taken back to the attacker
    lay_in_wait                    = 5716, -- (1235091) Sigil of Misery has $s1 charges and now lays in wait for up to $s2 sec at your selected location until an enemy approaches
    rain_from_above                = 5521, -- (206803) You fly into the air out of harm's way. While floating, you gain access to Fel Lance allowing you to deal damage to enemies below
    reverse_magic                  = 3429, -- (205604) Removes all harmful magical effects from yourself and all nearby allies within $s1 yards, and sends them back to their original caster if possible
    sigil_mastery                  = 1948, -- (211489) Reduces the cooldown of your Sigils by an additional $s1%
    tormentor                      = 1220, -- (207029) You focus the assault on this target, increasing their damage taken by $s1% for $s2 sec. Each unique player that attacks the target increases the damage taken by an additional $s3%, stacking up to $s4 times. Your melee attacks refresh the duration of Focused Assault
    unending_hatred                = 3727, -- (213480) Taking damage causes you to gain Fury based on the damage dealt
} )

-- Auras
spec:RegisterAuras( {
    -- $w1 Soul Fragments consumed. At $?a212612[$442290s1~][$442290s2~], Reaver's Glaive is available to cast.
    art_of_the_glaive = {
        id = 444661,
        duration = 30.0,
        --self
        max_stack = 90,
    },
    -- Damage taken reduced by $s1%.
    blade_ward = {
        id = 442715,
        duration = 5.0,
        max_stack = 1,
    },
    -- Versatility increased by $w1%.
    -- https://wowhead.com/beta/spell=355894
    blind_faith = {
        id = 355894,
        duration = 20,
        max_stack = 1
    },
    -- Taking $w1 Chaos damage every $t1 seconds.  Damage taken from $@auracaster's Immolation Aura increased by $s2%.
    -- https://wowhead.com/beta/spell=391191
    burning_wound = {
        id = 391191,
        duration = 15,
        tick_time = 3,
        max_stack = 1
    },
    calcified_spikes = {
        id = 391171,
        duration = 12,
        max_stack = 1
    },
    -- https://www.wowhead.com/spell=1490
    chaos_brand = {
        id = 1490,
        duration = 3600,
        max_stack = 1,
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=179057
    chaos_nova = {
        id = 179057,
        duration = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Talent:
    -- https://wowhead.com/beta/spell=196718
    darkness = {
        id = 196718,
        duration = function() return ( talent.long_night.enabled and 11 or 8 ) + ( talent.cover_of_darkness.enabled and 2 or 0 ) end,
        max_stack = 1
    },
    demon_soul = {
        id = 347765,
        duration = 15,
        max_stack = 1,
    },
    -- Armor increased by ${$W2*$AGI/100}.$?s321028[  Parry chance increased by $w1%.][]
    -- https://wowhead.com/beta/spell=203819
    demon_spikes = {
        id = 203819,
        duration = function() return 8 + talent.extended_spikes.rank end,
        max_stack = 1
    },
    -- https://www.wowhead.com/spell=452416
    -- Demonsurge Damage of your next Demonsurge is increased by 10%.
    demonsurge = {
        id = 452416,
        duration = 12,
        max_stack = 6,
    },
    -- Fake buffs for demonsurge damage procs
    demonsurge_hardcast = {},
    demonsurge_consuming_fire = {},
    demonsurge_fel_desolation = {},
    demonsurge_sigil_of_doom = {},
    demonsurge_soul_sunder = {},
    demonsurge_spirit_burst = {},
    -- Vengeful Retreat may be cast again.
    evasive_action = {
        id = 444929,
        duration = 3.0,
        max_stack = 1,
    },
    feast_of_souls = {
        id = 207693,
        duration = 6,
        max_stack = 1
    },
    -- Talent:
    -- https://wowhead.com/beta/spell=212084
    fel_devastation = {
        id = 212084,
        duration = 2,
        tick_time = 0.2,
        max_stack = 1
    },
    fel_flame_fortification = {
        id = 393009,
        duration = function () return class.auras.immolation_aura.duration end,
        max_stack = 1
    },
    -- Talent: Movement speed increased by $w1%.
    -- https://wowhead.com/beta/spell=389847
    felfire_haste = {
        id = 389847,
        duration = 8,
        max_stack = 1
    },
    -- Talent: Branded, taking $w3 Fire damage every $t3 sec, and dealing $204021s1% less damage to $@auracaster$?s389220[ and taking $w2% more Fire damage from them][].
    -- https://wowhead.com/beta/spell=207744
    fiery_brand = {
        id = 207771,
        duration = 12,
        type = "Magic",
        max_stack = 1,
        copy = "fiery_brand_dot"
    },
    -- Talent: Battling a demon from the Theater of Pain...
    -- https://wowhead.com/beta/spell=391430
    fodder_to_the_flame = {
        id = 391430,
        duration = 25,
        max_stack = 1,
        copy = 329554
    },
    -- Talent: $@auracaster is healed for $w1% of all damage they deal to you.$?$w3!=0[  Dealing $w3% reduced damage to $@auracaster.][]$?$w4!=0[  Suffering $w4% increased damage from $@auracaster.][]
    -- https://wowhead.com/beta/spell=247456
    frailty = {
        id = 247456,
        duration = 5,
        tick_time = 1,
        type = "Magic",
        max_stack = 1
    },
    glaive_flurry = {
        id = 442435,
        duration = 30,
        max_stack = 1
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
    immolation_aura = {
        id = 258920,
        duration = function () return talent.agonizing_flames.enabled and 9 or 6 end,
        tick_time = 1,
        max_stack = 1
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
    -- Talent: Movement speed reduced by $s1%.
    -- https://wowhead.com/beta/spell=213405
    master_of_the_glaive = {
        id = 213405,
        duration = 6,
        mechanic = "snare",
        max_stack = 1
    },
    -- Maximum health increased by $w2%.  Armor increased by $w8%.  $?s235893[Versatility increased by $w5%. ][]$?s263642[Fracture][Shear] generates $w4 additional Fury and one additional Lesser Soul Fragment.
    -- https://wowhead.com/beta/spell=187827
    metamorphosis = {
        id = 187827,
        duration = 15,
        max_stack = 1,
        -- This copy is for SIMC compatability while avoiding managing a virtual buff
        copy = "demonsurge_demonic"
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
    -- Agility increased by $w1%.
    monster_rising = {
        id = 452550,
        duration = 3600,
        max_stack = 1
    },
    painbringer = {
        id = 212988,
        duration = 6,
        max_stack = 30
    },
    -- $w3
    pursuit_of_angriness = {
        id = 452404,
        duration = 0.0,
        tick_time = 1.0,
        max_stack = 1,
    },
    reavers_glaive = {
    },
    reavers_mark = {
        id = 442624,
        duration = 20,
        max_stack = function() return set_bonus.tww3 >=4 and 2 or 1 end
    },
    rending_strike = {
        id = 442442,
        duration = 30,
        max_stack = 1
    },
    ruinous_bulwark = {
        id = 326863,
        duration = 10,
        max_stack = 1
    },
    -- Taking $w1 Fire damage every $t1 sec.
    set_fire_to_the_pain = {
        id = 453286,
        duration = 6.0,
        tick_time = 1.0,
        max_stack = 1,
    },
    -- Talent: Movement slowed by $s1%.
    -- https://wowhead.com/beta/spell=204843
    sigil_of_chains = {
        id = 204843,
        duration = function () return 6 + ( 2 * talent.chains_of_anger.rank ) end,
        type = "Magic",
        max_stack = 1
    },
    sigil_of_doom = {
        id = 462030,
        duration = 8,
        max_stack = 1
    },
    sigil_of_doom_active = {
        id = 452490,
        duration = 2,
        max_stack = 1
    },
    -- Talent: Sigil of Flame is active.
    -- https://wowhead.com/beta/spell=204596
    sigil_of_flame_active = {
        id = 204596,
        duration = 2,
        max_stack = 1,
        copy = 389810
    },
    -- Talent: Suffering $w2 $@spelldesc395020 damage every $t2 sec.
    -- https://wowhead.com/beta/spell=204598
    sigil_of_flame = {
        id = 204598,
        duration = function () return 6 + ( 2 * talent.chains_of_anger.rank ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Disoriented.
    -- https://wowhead.com/beta/spell=207685
    sigil_of_misery_debuff = {
        id = 207685,
        duration = function () return 15 + ( 2 * talent.chains_of_anger.rank ) end,
        mechanic = "flee",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Silenced.
    -- https://wowhead.com/beta/spell=204490
    sigil_of_silence = {
        id = 204490,
        duration = function () return 4 + ( 2 * talent.chains_of_anger.rank ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Absorbs $w1 damage.
    -- https://wowhead.com/beta/spell=263648
    soul_barrier = {
        id = 263648,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Suffering $s1 Fire damage every $t1 sec.
    -- TODO: Trigger more Lesser Soul Fragments...
    -- https://wowhead.com/beta/spell=207407
    soul_carver = {
        id = 207407,
        duration = 3,
        tick_time = 1,
        max_stack = 1
    },
    -- Consume to heal for $210042s1% of your maximum health.
    -- https://wowhead.com/beta/spell=203795
    soul_fragment = {
        id = 203795,
        duration = 20,
        max_stack = 5
    },
    soul_fragments = {
        id = 203981,
        duration = 3600,
        max_stack = 5,
    },
    -- Talent: $w1 Soul Fragments consumed. At $u, the damage of your next Soul Cleave is increased by $391172s1%.
    -- https://wowhead.com/beta/spell=391166
    soul_furnace_stack = {
        id = 391166,
        duration = 30,
        max_stack = 9,
        copy = 339424
    },
    soul_furnace = {
        id = 391172,
        duration = 30,
        max_stack = 1,
        copy = "soul_furnace_damage_amp"
    },
    -- Suffering $w1 Chaos damage every $t1 sec.
    -- https://wowhead.com/beta/spell=390181
    soulrend = {
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
    -- Talent:
    -- https://wowhead.com/beta/spell=247454
    spirit_bomb = {
        id = 247454,
        duration = 1.5,
        max_stack = 1
    },
    spirit_of_the_darkness_flame = {
        id = 337542,
        duration = 3600,
        max_stack = 15
    },
    -- Mastery increased by ${$w1*$mas}.1%. ; Generating $453236s1 Fury every $t2 sec.
    student_of_suffering = {
        id = 453239,
        duration = 6,
        max_stack = 1
    },
    -- Talent: Suffering $w1 $@spelldesc395042 damage every $t1 sec.
    -- https://wowhead.com/beta/spell=345335
    the_hunt_dot = {
        id = 370969,
        duration = 6,
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
        duration = 20.0,
        max_stack = 1,
        copy = "thrill_of_the_fight_attack_speed"
    },
    thrill_of_the_fight_damage = {
        id = 1227062,
        duration = 10,
        max_stack = 1
    },
    -- Taunted.
    -- https://wowhead.com/beta/spell=185245
    torment = {
        id = 185245,
        duration = 3,
        max_stack = 1
    },
    -- Talent: Movement speed reduced by $s1%.
    -- https://wowhead.com/beta/spell=198813
    vengeful_retreat = {
        id = 198813,
        duration = 3,
        max_stack = 1
    },
    void_reaver = {
        id = 268178,
        duration = 12,
        max_stack = 1,
    },
    -- Your next $?a212612[Chaos Strike]?s263642[Fracture][Shear] will deal $442507s1 additional Physical damage.
    warblades_hunger = {
        id = 442503,
        duration = 30.0,
        max_stack = 1,
    },

    -- PvP Talents
    demonic_trample = {
        id = 205629,
        duration = 3,
        max_stack = 1,
    },
    everlasting_hunt = {
        id = 208769,
        duration = 3,
        max_stack = 1,
    },
    focused_assault = { -- Tormentor.
        id = 206891,
        duration = 6,
        max_stack = 5,
    },
    illidans_grasp = {
        id = 205630,
        duration = 6,
        type = "Magic",
        max_stack = 1,
    },
} )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237691, 237689, 237694, 237692, 237690 },
        auras = {
            -- Fel-Scarred
            -- Vengeance
            demon_soul = {
                id = 1238675,
                duration = 15,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229316, 229314, 229319, 229317, 229315 }
    },
    -- Dragonflight
    tier31 = {
        items = { 207261, 207262, 207263, 207264, 207266, 217228, 217230, 217226, 217227, 217229 },
        auras = {
            fiery_resolve = {
                id = 425653,
                duration = 8,
                max_stack = 5
            }
        }
    },
    tier30 = {
        items = { 202527, 202525, 202524, 202523, 202522 },
        auras = {
            fires_of_fel = {
                id = 409645,
                duration = 6,
                max_stack = 1
            },
            recrimination = {
                id = 409877,
                duration = 30,
                max_stack = 1
            }
        }
    },
    tier29 = {
        items = { 200345, 200347, 200342, 200344, 200346 },
        auras = {
            decrepit_souls = {
                id = 394958,
                duration = 8,
                max_stack = 1
            }
        }
    },
    -- Legacy Tier Sets
    tier21 = { items = { 152121, 152123, 152119, 152118, 152120, 152122 } },
    tier20 = { items = { 147130, 147132, 147128, 147127, 147129, 147131 } },
    tier19 = { items = { 138375, 138376, 138377, 138378, 138379, 138380 } },

    -- Class Hall
    class = { items = { 139715, 139716, 139717, 139718, 139719, 139720, 139721, 139722 } },
    -- Notable Trinkets
    convergence_of_fates = { items = { 140806 } }
} )

-- Local table for real fragment storage (accessible by combat log)
local true_inactive_fragments = {}

-- To support SimC soul_fragments expressions
spec:RegisterStateTable( "soul_fragments", setmetatable( {

    activation_delay = 1.25, -- Maxiumum delay before fragments become active
    virtual_fragments = {}, -- Virtual table

    reset = setfenv( function()
        soul_fragments.active = buff.soul_fragments.stack or 0
        soul_fragments.inactive = #true_inactive_fragments
    end, state ),

    queueFragments = setfenv( function( count, timeStamp, extraTime )
        -- Add individual fragments to REAL table (for combat log events)
        count = count or 1
        extraTime = extraTime or 0
        timeStamp = timeStamp + soul_fragments.activation_delay + extraTime

        for i = 1, count do
            insert( true_inactive_fragments, timeStamp )
            timeStamp = timeStamp + 0.05 -- ensure unique timestamps
        end
    end, state ),

    activateFragment = setfenv( function()
        -- Activate a fragment from REAL storage (convert inactive to active)
        if #true_inactive_fragments > 0 then
            local earliest_index = 1
            local earliest_time = true_inactive_fragments[1]

            for i = 2, #true_inactive_fragments do
                if true_inactive_fragments[i] < earliest_time then
                    earliest_time = true_inactive_fragments[i]
                    earliest_index = i
                end
            end

            remove( true_inactive_fragments, earliest_index )
            addStack( "soul_fragments" )
        end
    end, state ),

    purgeQueued = setfenv( function()
        wipe( true_inactive_fragments )
        soul_fragments.virtual_fragments = {}
    end, state ),

    consumeFragments = setfenv( function( amt )
        if talent.soul_furnace.enabled then
            local overflow = buff.soul_furnace_stack.stack + amt
            if overflow >= 10 then
                applyBuff( "soul_furnace" )
                overflow = overflow - 10
                if overflow > 0 then -- stacks carry over past 10 to start a new stack
                    applyBuff( "soul_furnace_stack", nil, overflow )
                end
            else
                addStack( "soul_furnace_stack", nil, amt )
            end
        end
        -- Reaver Tree
        if talent.art_of_the_glaive.enabled then
            addStack( "art_of_the_glaive", nil, amt )
            if  buff.art_of_the_glaive.stack == 20 then
                removeBuff( "art_of_the_glaive" )
                applyBuff( "reavers_glaive" )
            end
        end
        if talent.warblades_hunger.enabled then
            addStack( "warblades_hunger", nil, amt )
        end

        gainChargeTime( "demon_spikes", ( 0.35 * talent.feed_the_demon.rank * amt ) )
        buff.soul_fragments.count = max( 0, buff.soul_fragments.stack - amt )
    end, state ),

}, {
    __index = function( t, k )
        if k == "total" then
            return ( rawget( t, "active" ) or 0 ) + ( rawget( t, "inactive" ) or 0 )
        elseif k == "active" then
            return rawget( t, "active" ) or 0
        elseif k == "inactive" then
            return rawget( t, "inactive" ) or 0
        elseif k == "time_to_next" then
            -- Find the earliest activation time from real fragments
            local earliest_time = nil
            local current_time = query_time

            for i, activation_time in ipairs( true_inactive_fragments ) do
                -- Convert real time to simulation time
                local sim_activation_time = activation_time - GetTime() + current_time
                if sim_activation_time > current_time then
                    if not earliest_time or sim_activation_time < earliest_time then
                        earliest_time = sim_activation_time
                    end
                end
            end

            return earliest_time and ( earliest_time - current_time ) or 0
        end

        return 0
    end
} ) )

spec:RegisterStateExpr( "last_infernal_strike", function ()
    return action.infernal_strike.lastCast
end )

spec:RegisterStateExpr( "activation_time", function()
    return talent.quickened_sigils.enabled and 1 or 2
end )

-- Variable to track the total bonus timed earned on fiery brand from immolation aura.
local bonus_time_from_immo_aura = 0
-- Variable to track the GUID of the initial target
local initial_fiery_brand_guid = ""

local sigilList = {
    sigil_of_flame = { 204596, 389810, 452490, 469991 },
    sigil_of_misery = { 207684, 389813 },
    sigil_of_spite = { 390163, 389815 },
    sigil_of_silence = { 202137, 389809 },
    sigil_of_chains = { 202138, 389807 }
}

local DemonsurgeHardcast = false

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _ , subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID ~= GUID then return end

    if spellID == 187827 and state.talent.demonic_intensity.enabled then
        if subtype == "SPELL_CAST_SUCCESS" then
            DemonsurgeHardcast = true
        elseif subtype == "SPELL_AURA_REMOVED" then
            DemonsurgeHardcast = false
        end
    end

    if state.talent.charred_flesh.enabled and subtype == "SPELL_DAMAGE" and spellID == 258922 and destGUID == initial_fiery_brand_guid then
        bonus_time_from_immo_aura = bonus_time_from_immo_aura + ( 0.25 * state.talent.charred_flesh.rank )

    elseif subtype == "SPELL_CAST_SUCCESS" then
        if state.talent.charred_flesh.enabled and spellID == 204021 then
            bonus_time_from_immo_aura = 0
            initial_fiery_brand_guid = destGUID
        end

        if spellID == 204255 then
            soul_fragments.activateFragment()
        elseif spellID == 263642 then
            -- Fracture:  Generate 2-3 frags
            local timeStamp = GetTime()
            local metaActive = GetPlayerAuraBySpellID( 187827 )
            local frags = 2 + ( metaActive and 1 or 0 )
            soul_fragments.queueFragments( frags, timeStamp )
        elseif spellID == 203782 then
            -- Shear:  Generate 1-2 frags
            local timeStamp = GetTime()
            local metaActive = GetPlayerAuraBySpellID( 187827 )
            local frags = 1 + ( metaActive and 1 or 0 )
            soul_fragments.queueFragments( frags, timeStamp )
        end

        -- Sigils: Generate 1 frag
        local foundSigil = false
        for _, spellIDs in pairs( sigilList ) do
            for _, id in ipairs( spellIDs ) do
                if spellID == id then
                    foundSigil = true
                    break
                end
            end
            if foundSigil then break end
        end
        if foundSigil then
            local timeStamp = GetTime()
            -- Pass in sigil activation time as additional delay to the spawning
            soul_fragments.queueFragments( 1, timeStamp, state.activation_time )
        end

        -- We consumed or generated a fragment for real, so let's purge the inactive queue.
    elseif spellID == 203981 and soul_fragments.inactive > 0 and ( subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_APPLIED_DOSE" ) then
        soul_fragments.inactive = max( 0, soul_fragments.inactive - 1 )
    end
end, false )

-- Abilities that may trigger Demonsurge.
local demonsurge = {
    demonic = { "soul_sunder", "spirit_burst" },
    hardcast = { "consuming_fire", "fel_desolation", "sigil_of_doom" },
}

-- Map old demonsurge names to current ability names due to SimC APL
local demonsurge_spell_map = {
    soul_sunder = "soul_cleave",
    spirit_burst = "spirit_bomb",
    fel_desolation = "fel_devastation",
    sigil_of_doom = "sigil_of_flame"
}

spec:RegisterHook( "reset_precast", function ()
    -- Call the reset function to sync with real game state and process activations
    soul_fragments.reset()

    -- Debug snapshot for soul_fragments
    if Hekili.ActiveDebug then

        local real_times = {}
        for i, activation_time in ipairs( true_inactive_fragments ) do
            insert( real_times, strformat( "%.2fs", activation_time - GetTime() ) )
        end
        local real_str = #real_times > 0 and table.concat( real_times, ", " ) or "none"

        Hekili:Debug( "Soul Fragments - Active: %d, Inactive: %d, Total: %d, Buff Stack: %d, Next: %.2fs, Real: [%s]",
            soul_fragments.active or 0,
            soul_fragments.inactive or 0,
            soul_fragments.total or 0,
            buff.soul_fragments.stack or 0,
            soul_fragments.time_to_next or 0,
            real_str
        )
    end

    if buff.demonic_trample.up then
        setCooldown( "global_cooldown", max( cooldown.global_cooldown.remains, buff.demonic_trample.remains ) )
    end

    if buff.illidans_grasp.up then
        setCooldown( "illidans_grasp", 0 )
    end


    if IsSpellKnownOrOverridesKnown( 442294 ) or IsSpellOverlayed( 442294 ) then
        applyBuff( "reavers_glaive" )
        if Hekili.ActiveDebug then Hekili:Debug( "Applied Reaver's Glaive." ) end
    end

    if talent.demonsurge.enabled and buff.metamorphosis.up then
        local metaRemains = buff.metamorphosis.remains

        for _, name in ipairs( demonsurge.demonic ) do
            local ability_name = demonsurge_spell_map[name] or name
            if class.abilities[ ability_name ] and IsSpellOverlayed( class.abilities[ ability_name ].id ) then
                applyBuff( "demonsurge_" .. name, metaRemains )
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
        end

        if Hekili.ActiveDebug then
            Hekili:Debug( "Demonsurge status:\n" ..
                " - Hardcast " .. ( buff.demonsurge_hardcast.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Demonic " .. ( buff.demonsurge_demonic.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Consuming Fire " .. ( buff.demonsurge_consuming_fire.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Fel Desolation " .. ( buff.demonsurge_fel_desolation.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Sigil of Doom " .. ( buff.demonsurge_sigil_of_doom.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Soul Sunder " .. ( buff.demonsurge_soul_sunder.up and "ACTIVE" or "INACTIVE" ) .. "\n" ..
                " - Spirit Burst " .. ( buff.demonsurge_spirit_burst.up and "ACTIVE" or "INACTIVE" ) )
            end
        end

    fiery_brand_dot_primary_expires = nil
    fury_spent = nil
end )

spec:RegisterHook( "spend", function( amt, resource )
    if set_bonus.tier31_4pc == 0 or amt < 0 or resource ~= "fury" then return end

    fury_spent = fury_spent + amt
    if fury_spent > 40 then
        reduceCooldown( "sigil_of_flame", floor( fury_spent / 40 ) )
        fury_spent = fury_spent % 40
    end
end )

-- approach that actually calculated time remaining of fiery_brand via combat log. last modified 1/27/2023.
spec:RegisterStateExpr( "fiery_brand_dot_primary_expires", function()
    return action.fiery_brand.lastCast + bonus_time_from_immo_aura + class.auras.fiery_brand.duration
end )

spec:RegisterStateExpr( "fiery_brand_dot_primary_remains", function()
    return max( 0, fiery_brand_dot_primary_expires - query_time )
end )

spec:RegisterStateExpr( "fiery_brand_dot_primary_ticking", function()
    return fiery_brand_dot_primary_remains > 0
end )

local furySpent = 0

local FURY = Enum.PowerType.Fury
local lastFury = -1

spec:RegisterUnitEvent( "UNIT_POWER_FREQUENT", "player", nil, function( event, unit, powerType )
    if powerType == "FURY" and state.set_bonus.tier31_4pc > 0 then
        local current = UnitPower( "player", FURY )

        if current < lastFury - 3 then
            furySpent = ( furySpent + lastFury - current )
        end

        lastFury = current
    end
end )

spec:RegisterStateExpr( "fury_spent", function ()
    if set_bonus.tier31_4pc == 0 then return 0 end
    return furySpent
end )


local TriggerDemonic = setfenv( function()
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
                if set_bonus.tww3 >= 4 then
                    addStack( "demonsurge" )
                    applyBuff( "demon_soul" )
                end
            end
        end
    else
        applyBuff( "metamorphosis", demonicExtension )
        if talent.inner_demon.enabled then applyBuff( "inner_demon" ) end
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

    tank_combat_wait= {
        name = "坦克战斗介入",
        listName = '|T134376:0|t |cff00ccff[坦克战斗介入]|r',
        indicator = "wait",
        texture = 134376,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        essential = true
    },

    -- Talent: Demolish the spirit of all those around you, dealing $s1 Fire damage to nearby enemies and extracting up to $s2 Lesser Soul Fragments, drawing them to you for immediate consumption.
    bulk_extraction = {
        id = 320341,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "fire",

        talent = "bulk_extraction",
        startsCombat = true,
        texture = 136194,

        toggle = "cooldowns",

        handler = function ()
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
        texture = 135795,

        handler = function ()
            applyDebuff( "target", "chaos_nova" )
        end,
    },

    -- Talent: Consume $m1 beneficial Magic effect removing it from the target$?s320313[ and granting you $s2 Fury][].
    consume_magic = {
        id = 278326,
        cast = 0,
        cooldown = 10,
        gcd = "spell",
        school = "chromatic",

        talent = "consume_magic",
        startsCombat = false,

        toggle = "interrupts",
        buff = "dispellable_magic",

        handler = function ()
            removeBuff( "dispellable_magic" )
            if talent.swallowed_anger.enabled then gain( 20, "fury" ) end
        end,
    },

    -- Summons darkness around you in a$?a357419[ 12 yd][n 8 yd] radius, granting friendly targets a $209426s2% chance to avoid all damage from an attack. Lasts $d.; Chance to avoid damage increased by $s3% when not in a raid.
    darkness = {
        id = 196718,
        cast = 0,
        cooldown = function() return talent.pitch_black.enabled and 180 or 300 end,
        gcd = "spell",
        school = "physical",

        talent = "darkness",
        startsCombat = false,
        texture = 1305154,

        toggle = "defensives",

        handler = function ()
            last_darkness = query_time
            applyBuff( "darkness" )
        end,
    },

    -- Surge with fel power, increasing your Armor by ${$203819s2*$AGI/100}$?s321028[, and your Parry chance by $203819s1%, for $203819d][].
    demon_spikes = {
        id = 203720,
        cast = 0,
        charges = 2,
        cooldown = 20,
        recharge = 20,
        hasteCD = true,

        icd = 1.5,
        gcd = "off",
        school = "physical",

        startsCombat = false,

        toggle = "defensives",
        defensive = true,

        handler = function ()
            if talent.calcified_spikes.enabled and buff.demon_spikes.up then applyBuff( "calcified_spikes" ) end
            applyBuff( "demon_spikes", buff.demon_spikes.remains + buff.demon_spikes.duration )
        end,
    },

    demonic_trample = {
        id = 205629,
        cast = 0,
        charges = 2,
        cooldown = 12,
        recharge = 12,
        gcd = "spell",
        icd = 0.8,

        pvptalent = "demonic_trample",
        nobuff = "demonic_trample",

        startsCombat = false,
        texture = 134294,
        nodebuff = "rooted",

        handler = function ()
            spendCharges( "infernal_strike", 1 )
            setCooldown( "global_cooldown", 3 )
            applyBuff( "demonic_trample" )
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
        interrupt = true,
        target = function () 
            if not UnitExists("focus") then
                return debuff.casting_target.caster
            else
                return debuff.casting_focus.caster
            end
        end,
        usable = function () return state.readyToInterrupt() and target.distance <= 10, "readyToInterrupt" end,
        handler = function ()
            if talent.disrupting_fury.enabled then gain( 30, "fury" ) end
            interrupt()
        end,
    },

    -- Talent: Unleash the fel within you, damaging enemies directly in front of you for ${$212105s1*(2/$t1)} Fire damage over $d.$?s320639[ Causing damage also heals you for up to ${$212106s1*(2/$t1)} health.][]
    fel_devastation = {
		id = function() return buff.demonsurge_hardcast.up and 452486 or 212084 end,
        cast = 2,
        channeled = true,
        cooldown = 40,
        fixedCast = true,
        gcd = "spell",
        school = "fire",
        usable = function () return target.distance <= 7, "target must be nearby" end,
        spend = 50,
        spendType = "fury",
        toggle = "defensives",
        talent = "fel_devastation",
        startsCombat = true,
        texture = function() return buff.demonsurge_hardcast.up and 135798 or 1450143 end,

        start = function ()
            if buff.demonsurge_fel_desolation.up then
                removeBuff( "demonsurge_fel_desolation" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            applyBuff( "fel_devastation" )
            if talent.demonic.enabled then TriggerDemonic() end
        end,

        finish = function ()
            if talent.darkglare_boon.enabled then
                gain( 15, "fury" )
                reduceCooldown( "fel_devastation", 6 )
            end
            if talent.ruinous_bulwark.enabled then applyBuff( "ruinous_bulwark" ) end
        end,

        bind = "fel_desolation",
        copy = { 452486, 212084 }
    },

    -- Talent: Charge to your target and deal $213243sw2 $@spelldesc395020 damage.    $?s203513[Shear has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r]?a203555[Demon Blades has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r][Demon's Bite has a chance to reset the cooldown of Felblade.    |cFFFFFFFFGenerates $213243s3 Fury.|r]
    felblade = {
        id = 232893,
        cast = 0,
        cooldown = 15,
        hasteCD = true,
        gcd = "spell",
        school = "physical",

        spend = -40,
        spendType = "fury",
        usable = function ()
            return not moving and target.distance <= 5, "moving"
        end,
        talent = "felblade",
        startsCombat = true,
        nodebuff = "rooted",

        handler = function ()
            setDistance( 5 )
        end,
    },

    -- Talent: Brand an enemy with a demonic symbol, instantly dealing $sw2 Fire damage$?s320962[ and ${$207771s3*$207744d} Fire damage over $207744d][]. The enemy's damage done to you is reduced by $s1% for $207744d.
    fiery_brand = {
        id = 204021,
        cast = 0,
        charges = function() return talent.down_in_flames.enabled and 2 or nil end,
        cooldown = function() return ( talent.down_in_flames.enabled and 48 or 60 ) + ( conduit.fel_defender.mod * 0.001 ) end,
        recharge = function() return talent.down_in_flames.enabled and ( 48 + ( conduit.fel_defender.mod * 0.001 ) ) or nil end,
        gcd = "spell",
        school = "fire",

        talent = "fiery_brand",
        startsCombat = true,
        toggle = "defensives",
        readyTime = function ()
            if ( settings.brand_charges or 1 ) == 0 then return end
            return ( ( 1 + ( settings.brand_charges or 1 ) ) - cooldown.fiery_brand.charges_fractional ) * cooldown.fiery_brand.recharge
        end,

        handler = function ()
            applyDebuff( "target", "fiery_brand_dot" )
            fiery_brand_dot_primary_expires = query_time + class.auras.fiery_brand.duration
            removeBuff( "spirit_of_the_darkness_flame" )

            --if talent.charred_flesh.enabled then applyBuff( "charred_flesh" ) end
        end,
    },

    -- Talent: Rapidly slash your target for ${$225919sw1+$225921sw1} Physical damage, and shatter $s1 Lesser Soul Fragments from them.    |cFFFFFFFFGenerates $s4 Fury.|r
    fracture = {
        id = 263642,
        cast = 0,
        charges = 2,
        cooldown = 4.5,
        recharge = 4.5,
        hasteCD = true,
        gcd = "spell",
        school = "physical",

        spend = function() return ( buff.metamorphosis.up and -45 or -25 ) end,
        spendType = "fury",

        talent = "fracture",
        bind = "shear",
        startsCombat = true,

        handler = function ()
            if buff.glaive_flurry.down and buff.rending_strike.up then
                applyBuff( "thrill_of_the_fight" )
                applyBuff( "thrill_of_the_fight_damage" )
            end
            spec.abilities.shear.handler()
            addStack( "soul_fragments", nil, 1 )

        end,
    },

    illidans_grasp = {
        id = function () return debuff.illidans_grasp.up and 208173 or 205630 end,
        known = 205630,
        cast = 0,
        channeled = true,
        cooldown = function () return buff.illidans_grasp.up and ( 54 + buff.illidans_grasp.remains ) or 0 end,
        gcd = "off",

        pvptalent = "illidans_grasp",
        aura = "illidans_grasp",
        breakable = true,

        startsCombat = true,
        texture = function () return buff.illidans_grasp.up and 252175 or 1380367 end,

        start = function ()
            if buff.illidans_grasp.up then removeBuff( "illidans_grasp" )
            else applyBuff( "illidans_grasp" ) end
        end,

        copy = { 205630, 208173 }
    },

    -- Engulf yourself in flames, $?a320364 [instantly causing $258921s1 $@spelldesc395020 damage to enemies within $258921A1 yards and ][]radiating ${$258922s1*$d} $@spelldesc395020 damage over $d.$?s320374[    |cFFFFFFFFGenerates $<havocTalentFury> Fury over $d.|r][]$?(s212612 & !s320374)[    |cFFFFFFFFGenerates $<havocFury> Fury.|r][]$?s212613[    |cFFFFFFFFGenerates $<vengeFury> Fury over $d.|r][]
    immolation_aura = {
        id = function() return buff.demonsurge_hardcast.up and 452487 or 258920 end,
        flash = { 452487, 258920 },
        cast = 0,
        cooldown = 15,
        hasteCD = true,

        gcd = "spell",
        school = "fire",
        texture = function() return buff.demonsurge_hardcast.up and 135794 or 1344649 end,
        -- nobuff = "demonsurge_hardcast",

        spend = -8,
        spendType = "fury",
        startsCombat = true,

        handler = function ()
            applyBuff( "immolation_aura" )
            if legendary.fel_flame_fortification.enabled then applyBuff( "fel_flame_fortification" ) end
            if pvptalent.cleansed_by_flame.enabled then
                removeDebuff( "player", "reversible_magic" )
            end

            if talent.fallout.enabled then
                addStack( "soul_fragments", nil, active_enemies < 3 and 1 or 2 )
            end

            -- Fel-Scarred
            if buff.demonsurge_consuming_fire.up then
                removeBuff( "demonsurge_consuming_fire" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end

        end,

        tick = function ()
            if talent.charred_flesh.enabled then
                if debuff.fiery_brand.up then applyDebuff( "target", debuff.fiery_brand.remains + 0.25 * talent.charred_flesh.rank ) end
                if debuff.sigil_of_flame.up then applyDebuff( "target", debuff.sigil_of_flame.remains + 0.25 * talent.charred_flesh.rank ) end
            end
        end,

        bind = "consuming_fire",
        copy = "consuming_fire"
    },

    --[[consuming_fire = {
        id = 452487,
        known = 258920,
        cast = 0,
        cooldown = 15,
        hasteCD = true,
        gcd = "spell",
        school = "fire",
        texture = 135794,

        spend = -8,
        spendType = "fury",
        startsCombat = true,
        talent = "demonic_intensity",
        buff = "demonsurge_hardcast",

        handler = function ()
            applyBuff( "immolation_aura" )
            if legendary.fel_flame_fortification.enabled then applyBuff( "fel_flame_fortification" ) end
            if pvptalent.cleansed_by_flame.enabled then
                removeDebuff( "player", "reversible_magic" )
            end

            if talent.fallout.enabled then
                addStack( "soul_fragments", nil, active_enemies < 3 and 1 or 2 )
            end
            if buff.demonsurge_consuming_fire.up then
                removeBuff( "demonsurge_consuming_fire" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
        end,

        bind = "immolation_aura",
    },--]]

    -- Talent: Imprisons a demon, beast, or humanoid, incapacitating them for $d. Damage will cancel the effect. Limit 1.
    imprison = {
        id = 217832,
        cast = 0,
        cooldown = function () return pvptalent.detainment.enabled and 60 or 45 end,
        gcd = "spell",
        school = "shadow",

        talent = "imprison",
        startsCombat = false,

        handler = function ()
            applyDebuff( "target", "imprison" )
        end,
    },

    -- Leap through the air toward a targeted location, dealing $189112s1 Fire damage to all enemies within $189112a1 yards.
    infernal_strike = {
        id = 189110,
        cast = 0,
        charges = function() return talent.blazing_path.enabled and 2 or nil end,
        cooldown = function() return ( 20 - ( 10 * talent.meteoric_strikes.rank ) ) * ( 1 - 0.1 * talent.erratic_felheart.rank ) end,
        recharge = function() return talent.blazing_path.enabled and ( 20 - ( 10 * talent.meteoric_strikes.rank ) ) * ( 1 - 0.1 * talent.erratic_felheart.rank ) or nil end,
        usable = function () return false, "target must be nearby" end,
        toggle_terrain = "player",
        gcd = "off",
        school = "physical",
        icd = function () return gcd.max + 0.1 end,

        startsCombat = false,
        nodebuff = "rooted",
        terrain = true,
        readyTime = function ()
            if ( settings.infernal_charges or 1 ) == 0 then return end
            return ( ( 1 + ( settings.infernal_charges or 1 ) ) - cooldown.infernal_strike.charges_fractional ) * cooldown.infernal_strike.recharge
        end,

        handler = function ()
            setDistance( 5 )
            spendCharges( "demonic_trample", 1 )

            if talent.felfire_haste.enabled or conduit.felfire_haste.enabled then applyBuff( "felfire_haste" ) end
        end,
    },

    -- Transform to demon form for $d, increasing current and maximum health by $s2% and Armor by $s8%$?s235893[. Versatility increased by $s5%][]$?s321067[. While transformed, Shear and Fracture generate one additional Lesser Soul Fragment][]$?s321068[ and $s4 additional Fury][].
    metamorphosis = {
        id = 187827,
        cast = 0,
        cooldown = function() return ( 180 - ( 30 * talent.rush_of_chaos.rank) ) end,
        gcd = "off",
        school = "chaos",

        startsCombat = false,
        usable = function () return health.pct <= 20, "not low health" end,
        toggle = "defensives",
        toggle_terrain = "player",
        handler = function ()
            applyBuff( "metamorphosis", buff.metamorphosis.remains + 15 )
            gain( health.max * 0.4, "health" )

            if talent.demonsurge.enabled then
                local metaRemains = buff.metamorphosis.remains

                for _, name in ipairs( demonsurge.demonic ) do
                    applyBuff( "demonsurge_" .. name, metaRemains )
                end

                if talent.violent_transformation.enabled then
                    setCooldown( "sigil_of_flame", 0 )
                    setCooldown( "fel_devastation", 0 )
                end

                if talent.demonic_intensity.enabled then
                    removeBuff( "demonsurge" )
                    applyBuff( "demonsurge_hardcast", metaRemains )

                    for _, name in ipairs( demonsurge.hardcast ) do
                        applyBuff( "demonsurge_" .. name, metaRemains )
                    end
                    if set_bonus.tww3 >= 4 then
                        addStack( "demonsurge" )
                        applyBuff( "demon_soul" )
                    end
                end
            end
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

        buff = "reversible_magic",

        handler = function ()
            if debuff.reversible_magic.up then removeDebuff( "player", "reversible_magic" ) end
        end,
    },

    -- Shears an enemy for $s1 Physical damage, and shatters $?a187827[two Lesser Soul Fragments][a Lesser Soul Fragment] from your target.    |cFFFFFFFFGenerates $m2 Fury.|r
    shear = {
        id = function() return talent.fracture.enabled and 263642 or 203782 end,
        cast = 0,
        cooldown = function() return talent.fracture.enabled and ( 4.5 * haste ) or 0 end,
        charges  = function() return talent.fracture.enabled and 2 or nil end,
        recharge = function() return talent.fracture.enabled and ( 4.5 * haste ) or nil end,
        gcd = "spell",
        school = "physical",

        spend = function () return -1 * ( 10 + ( 10 * talent.shear_fury.rank ) + ( 15 * talent.fracture.rank ) + ( buff.metamorphosis.up and 20 or 0 ) ) end,

        startsCombat = true,

        texture = function() return talent.fracture.enabled and 1388065 or 1344648 end,

        handler = function ()
            if buff.rending_strike.up then -- Reaver stuff
                local cleaved = talent.fury_of_the_aldrachi.enabled and buff.glaive_flurry.down
                applyDebuff( "target", "reavers_mark", nil, cleaved and ( set_bonus.tww3 >=4 and 3 or 2 ) or 1 )
                removeBuff( "rending_strike" )
                if talent.thrill_of_the_fight.enabled and cleaved then
                    applyBuff( "thrill_of_the_fight" )
                    applyBuff( "thrill_of_the_fight_damage" )
                end
            end

            -- Legacy
            if buff.recrimination.up then
                applyDebuff( "target", "fiery_brand", 6 )
                removeBuff( "recrimination" )
            end
            local frags = 1 + ( buff.metamorphosis.up and 1 or 0 ) + ( talent.fracture.enabled and 1 or 0 )
            addStack( "soul_fragments", nil, frags )
        end,

        bind = "shear",
        copy = { 263642, 203782 }
    },

    -- Talent: Place a Sigil of Chains at the target location that activates after $d.    All enemies affected by the sigil are pulled to its center and are snared, reducing movement speed by $204843s1% for $204843d.
    sigil_of_chains = {
        id = function() return talent.precise_sigils.enabled and 389807 or 202138 end,
        known = 202138,
        cast = 0,
        cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 90 end,
        gcd = "spell",
        school = "physical",

        talent = "sigil_of_chains",
        startsCombat = false,

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_chains.lastCast + activation_time end,
        impact = function ()
            applyDebuff( "target", "sigil_of_chains" )
        end,

        copy = { 202138, 389807 }
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
        cooldown = function() return ( pvptalent.sigil_of_mastery.enabled and 0.75 or 1 ) * 30 - ( talent.illuminated_sigils.enabled and 5 or 0 ) end,
        charges = function () return talent.illuminated_sigils.enabled and 2 or 1 end,
        recharge = function() return ( pvptalent.sigil_of_mastery.enabled and 0.75 or 1 ) * 30 - ( talent.illuminated_sigils.enabled and 5 or 0 ) end,
        gcd = "spell",
        icd = function() return 0.25 + activation_time end,
        school = function() return buff.demonsurge_hardcast.up and "chaos" or "fire" end,

        spend = -30,
        spendType = "fury",
        toggle = "essences",
        terrain = true,
        usable = function () return target.distance <= 10 and not moving, "target must be nearby" end,
        toggle_terrain = "player",
        startsCombat = true,
        texture = function() return buff.demonsurge_hardcast.up and 1121022 or 1344652 end,

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_flame.lastCast + activation_time end,

        handler = function ()
            if buff.demonsurge_sigil_of_doom.up then
                removeBuff( "demonsurge_sigil_of_doom" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            if talent.cycle_of_binding.enabled then
                for sigil, _ in pairs( sigilList ) do
                    reduceCooldown( sigil, 5 )
                end
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
            if talent.soul_sigils.enabled then addStack( "soul_fragments", nil, 1 ) end
            if talent.student_of_suffering.enabled then applyBuff( "student_of_suffering" ) end
            if talent.flames_of_fury.enabled then gain( talent.flames_of_fury.rank * active_enemies, "fury" ) end
            if talent.frailty.enabled then
                if talent.soulcrush.enabled and debuff.frailty.up then
                    -- Soulcrush allows for multiple applications of Frailty.
                    applyDebuff( "target", "frailty", nil, debuff.frailty.stack + 1 )
                else
                    applyDebuff( "target", "frailty" )
                end
                active_dot.frailty = active_enemies
            end
        end,

        bind = "sigil_of_doom",
        copy = { 204596, 389810, 452490, 469991, "sigil_of_doom" }
    },


    -- Talent: Place a Sigil of Misery at your location that activates after $d.    Causes all enemies affected by the sigil to cower in fear. Targets are disoriented for $207685d.
    sigil_of_misery = {
        id = function () return talent.precise_sigils.enabled and 389813 or 207684 end,
        known = 207684,
        cast = 0,
        cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 120 - ( talent.improved_sigil_of_misery.enabled and 30 or 0 ) end,
        gcd = "spell",
        school = "physical",

        talent = "sigil_of_misery",
        startsCombat = false,

        toggle = "interrupts",

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_misery.lastCast + activation_time end,

        impact = function ()
            applyDebuff( "target", "sigil_of_misery_debuff" )
        end,

        copy = { 207684, 389813 }
    },

    sigil_of_silence = {
        id = function () return talent.precise_sigils.enabled and 389809 or 202137 end,
        known = 202137,
        cast = 0,
        cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 60 end,
        gcd = "spell",

        startsCombat = true,
        texture = 1418288,

        toggle = "interrupts",

        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_silence.lastCast + activation_time end,

        usable = function () return debuff.casting.remains > activation_time end,

        impact = function()
            interrupt()
            applyDebuff( "target", "sigil_of_silence" )
        end,

        copy = { 202137, 389809 },

        auras = {
            -- Conduit, applies after SoS expires.
            demon_muzzle = {
                id = 339589,
                duration = 6,
                max_stack = 1
            }
        }
    },

    -- Place a demonic sigil at the target location that activates after $d.; Detonates to deal $389860s1 Chaos damage and shatter up to $s3 Lesser Soul Fragments from enemies affected by the sigil. Deals reduced damage beyond $s1 targets.
    sigil_of_spite = {
        id = function () return talent.precise_sigils.enabled and 389815 or 390163 end,
        known = 390163,
        cast = 0.0,
        cooldown = function () return ( pvptalent.sigil_mastery.enabled and 0.75 or 1 ) * 60 end,
        gcd = "spell",
        usable = function () return target.distance <= 7 and not moving, "target must be nearby" end,
        talent = "sigil_of_spite",
        startsCombat = false,
        toggle_terrain = "player",
        flightTime = function() return activation_time end,
        delay = function() return activation_time end,
        placed = function() return query_time < action.sigil_of_spite.lastCast + activation_time end,
        toggle = "cooldowns",
        impact = function()
            addStack( "soul_fragments", nil, talent.soul_sigils.enabled and 4 or 3 )
        end,
        terrain = true,
        copy = { 390163, 389815 }
    },

    -- Talent: Shield yourself for $d, absorbing $<baseAbsorb> damage.    Consumes all Soul Fragments within 25 yds to add $<fragmentAbsorb> to the shield per fragment.
    soul_barrier = {
        id = 263648,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "shadow",

        talent = "soul_barrier",
        startsCombat = false,


        toggle = "defensives",

        handler = function ()

            soul_fragments.consumeFragments( buff.soul_fragments.stack )
            applyBuff( "soul_barrier" )

        end,
    },

    -- Talent: Carve into the soul of your target, dealing ${$s2+$214743s1} Fire damage and an additional $o1 Fire damage over $d.  Immediately shatters $s3 Lesser Soul Fragments from the target and $s4 additional Lesser Soul Fragment every $t1 sec.
    soul_carver = {
        id = 207407,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "fire",

        talent = "soul_carver",
        startsCombat = true,

        handler = function ()
            addStack( "soul_fragments", nil, 3 )
            applyBuff( "soul_carver" )
        end,
    },

    -- Viciously strike up to $228478s2 enemies in front of you for $228478s1 Physical damage and heal yourself for $s4.    Consumes up to $s3 available Soul Fragments$?s321021[ and heals you for an additional $s5 for each Soul Fragment consumed][].
    soul_cleave = {
		id = function() return buff.demonsurge_demonic.up and talent.improved_soul_rending.enabled and 452436 or 228477 end,
        known = 228477,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        spend = 30,
        spendType = "fury",

        startsCombat = true,
        texture = function() return buff.demonsurge_demonic.up and talent.improved_soul_rending.enabled and 1355117 or 1344653 end,

        handler = function ()
            removeBuff( "soul_furnace" )
            if buff.demonsurge_soul_sunder.up then
                removeBuff( "demonsurge_soul_sunder" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end

            --
            if buff.glaive_flurry.up then -- Reaver stuff
                removeBuff( "glaive_flurry" )
                if talent.thrill_of_the_fight.enabled and buff.rending_strike.down then
                    applyBuff( "thrill_of_the_fight" )
                    applyBuff( "thrill_of_the_fight_damage" )
                end
            end

            if talent.feast_of_souls.enabled then applyBuff( "feast_of_souls" ) end
            if talent.soulcrush.enabled then
                if debuff.frailty.up then
                    -- Soulcrush allows for multiple applications of Frailty.
                    applyDebuff( "target", "frailty", 8, debuff.frailty.stack + 1 )
                else
                    applyDebuff( "target", "frailty", 8 )
                end
            end
            if talent.void_reaver.enabled then active_dot.frailty = true_active_enemies end

            soul_fragments.consumeFragments( min( 2, buff.soul_fragments.stack ) )

            if legendary.fiery_soul.enabled then reduceCooldown( "fiery_brand", 2 * min( 2, buff.soul_fragments.stack ) ) end
        end,

        bind = "soul_cleave",
        copy = { 228477, 452436 },
    },

    -- Allows you to see enemies and treasures through physical barriers, as well as enemies that are stealthed and invisible. Lasts $d.    Attacking or taking damage disrupts the sight.
    spectral_sight = {
        id = 188501,
        cast = 0,
        cooldown = function() return 30 - ( 5 * talent.lost_in_darkness.rank ) end,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        handler = function ()
            applyBuff( "spectral_sight" )
        end,
    },

    -- Talent: Consume up to $s2 available Soul Fragments then explode, damaging nearby enemies for $247455s1 Fire damage per fragment consumed, and afflicting them with Frailty for $247456d, causing you to heal for $247456s1% of damage you deal to them. Deals reduced damage beyond $s3 targets.
    spirit_bomb = {
		id = function() return talent.demonsurge.enabled and buff.metamorphosis.up and 452437 or 247454 end,
        known = 247454,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "fire",

        spend = 40,
        spendType = "fury",

        talent = "spirit_bomb",
        startsCombat = false,
        buff = function() if soul_fragments.inactive == 0 then return "soul_fragments" end end,
        usable = function () return target.distance <= 7, "target must be nearby" end,
        handler = function ()
            if buff.demonsurge_spirit_burst.up then
                removeBuff( "demonsurge_spirit_burst" )
                if talent.demonic_intensity.enabled then addStack( "demonsurge" ) end
            end
            if talent.soulcrush.enabled and debuff.frailty.up then
                -- Soulcrush allows for multiple applications of Frailty.
                applyDebuff( "target", "frailty", nil, debuff.frailty.stack + 1 )
            else
                applyDebuff( "target", "frailty" )
            end
            active_dot.frailty = active_enemies
            removeBuff( "soul_furnace" )
            soul_fragments.consumeFragments( min( 5, buff.soul_fragments.stack ) )
        end,


        bind = "spirit_bomb",
        copy = { 247454, 452437 }
    },

    -- Talent / Covenant (Night Fae): Charge to your target, striking them for $370966s1 $@spelldesc395042 damage, rooting them in place for $370970d and inflicting $370969o1 $@spelldesc395042 damage over $370969d to up to $370967s2 enemies in your path.     The pursuit invigorates your soul, healing you for $?c1[$370968s1%][$370968s2%] of the damage you deal to your Hunt target for $370966d.
    the_hunt = {
        id = function() return talent.the_hunt.enabled and 370965 or 323639 end,
        cast = 1,
        cooldown = function() return talent.the_hunt.enabled and 90 or 180 end,
        gcd = "spell",
        school = "nature",
        usable = function () return target.distance <= 5 and not moving, "target must be nearby" end,
        startsCombat = true,
        toggle = "cooldowns",
        nodebuff = "rooted",

        handler = function ()
            applyDebuff( "target", "the_hunt" )
            applyDebuff( "target", "the_hunt_dot" )
            setDistance( 5 )

            if legendary.blazing_slaughter.enabled then
                applyBuff( "immolation_aura" )
                applyBuff( "blazing_slaughter" )
            end
            -- Hero Talents
            if talent.art_of_the_glaive.enabled then applyBuff( "reavers_glaive" ) end

        end,

        copy = { 370965, 323639 }
    },

    reavers_glaive = {
        id = 442294,
        cast = 0,
        charges = function() return 1 + talent.champion_of_the_glaive.rank + talent.master_of_the_glaive.rank end,
        cooldown = function() return talent.perfectly_balanced_glaive.enabled and 3 or 9 end,
        recharge = function() if ( talent.champion_of_the_glaive.rank + talent.master_of_the_glaive.rank ) > 0 then
            return ( talent.perfectly_balanced_glaive.enabled and 3 or 9 ) end
            end,
        gcd = "spell",
        school = "physical",
        known = 442290,
        usable = function ()
            return fight_remains > 15, "fight ends"
        end,
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

    -- Throw a demonic glaive at the target, dealing $337819s1 Physical damage. The glaive can ricochet to $?$s320386[${$337819x1-1} additional enemies][an additional enemy] within 10 yards.
    throw_glaive = {
        id = 204157,
        cast = 0,
        charges = function() return 1 + talent.champion_of_the_glaive.rank + talent.master_of_the_glaive.rank end,
        cooldown = function() return talent.perfectly_balanced_glaive.enabled and 3 or 9 end,
        recharge = function() if ( talent.champion_of_the_glaive.rank + talent.master_of_the_glaive.rank ) > 0 then
            return ( talent.perfectly_balanced_glaive.enabled and 3 or 9 ) end
            end,
        gcd = "spell",
        school = "physical",

        -- spend = function() return talent.furious_throws.enabled and 25 or nil end,
        -- spendType = function() return talent.furious_throws.enabled and "fury" or nil end,

        startsCombat = true,
        nobuff = "reavers_glaive",

        handler = function ()
            if talent.master_of_the_glaive.enabled then applyDebuff( "target", "master_of_the_glaive" ) end
            if set_bonus.tier31_4pc > 0 then reduceCooldown( "the_hunt", 2 ) end
        end,

        bind = "reavers_glaive"
    },

    -- Taunts the target to attack you.
    torment = {
        id = 185245,
        cast = 0,
        cooldown = 8,
        gcd = "off",
        school = "shadow",

        startsCombat = false,
        nopvptalent = "tormentor",

        handler = function ()
            applyDebuff( "target", "torment" )
        end,
    },

    tormentor = {
        id = 207029,
        cast = 0,
        cooldown = 20,
        gcd = "spell",

        startsCombat = true,
        texture = 1344654,

        pvptalent = "tormentor",

        handler = function ()
            applyDebuff( "target", "focused_assault" )
        end,
    },

    -- Talent: Remove all snares and vault away. Nearby enemies take $198813s2 Physical damage$?s320635[ and have their movement speed reduced by $198813s1% for $198813d][].$?a203551[    |cFFFFFFFFGenerates ${($203650s1/5)*$203650d} Fury over $203650d if you damage an enemy.|r][]
    vengeful_retreat = {
        id = 198793,
        cast = 0,
        cooldown = 25,
        gcd = "spell",

        startsCombat = true,
        nodebuff = "rooted",
        talent = "vengeful_retreat",

        readyTime = function ()
            if settings.recommend_movement then return 0 end
            return 3600
        end,

        handler = function ()
            if talent.evasive_action.enabled and buff.evasive_action.down then
                applyBuff( "evasive_action" )
                setCooldown( "vengeful_retreat", 0 )
            end
            if talent.vengeful_bonds.enabled and action.chaos_strike.in_range then -- 20231116: and target.within8 then
                applyDebuff( "target", "vengeful_retreat" )
            end

            if talent.unhindered_assault.enabled then setCooldown( "felblade", 0 ) end
            if pvptalent.glimpse.enabled then applyBuff( "glimpse" ) end
        end,
    }
} )

spec:RegisterRanges( "disrupt", "fiery_brand", "torment", "throw_glaive", "the_hunt" )

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

    package = "复仇Simc",
} )



spec:RegisterSetting("combat_delay", 3, {
    name = "战斗延迟介入",
    desc = "如果该值不等于0, 则允许战斗后延迟该值-X秒后再推荐技能,推荐值为6\n\n它同样会在x/2秒后当玩家停止不动时开始推荐技能\n\n它也同样会在玩家站定不动时自动开始介入",
    type = "range",
    min = 0,
    max = 20,
    step = 1,
    width = "full"
} )

spec:RegisterStateExpr( "combat_delay", function ()
    return settings.combat_delay or 0
end )

spec:RegisterSetting( "infernal_charges", 1, {
    name = strformat( "储存 %s 资源", Hekili:GetSpellLinkWithTexture( 189110 ) ),
    desc = strformat( "如果设置大于0，当使用 %s 后使你剩余很少的资源，它将不会被推荐。", Hekili:GetSpellLinkWithTexture( 189110 ) ),
    type = "range",
    min = 0,
    max = 2,
    step = 0.1,
    width = "full"
} )


spec:RegisterSetting( "brand_charges", 0, {
    name = strformat( "储存 %s 的消耗", Hekili:GetSpellLinkWithTexture( spec.abilities.fiery_brand.id ) ),
    desc = strformat( "如果设置大于0，将不会推荐使用 %s，能够减少你的资源消耗。", Hekili:GetSpellLinkWithTexture( spec.abilities.fiery_brand.id ) ),
    type = "range",
    min = 0,
    max = 2,
    step = 0.1,
    width = "full"
} )

spec:RegisterPack( "复仇Simc", 20250822, [[Hekili:T3ZA3XrXv(BrFyLNXepwDlngLCS1Eyz3KnCI9zpRYMCGpmTAntRrD0mtR0Dps2CYzoMWgSnG5rcGDiSlbwmqaJHaeq4x8Jz1ms(t8xi1JUQUQQRx9mJmYe2nNe5PQUQ79w331TQQHtJFEJLB5Ng04mUZ5wFUfDDR5CcN5NZTXYPNBZGglVPFZn8Bd(JE(Db)3dFNlV7TUWYHDBcB6CDI8BbhIKO(XnbnVEA6Mj)OJF82HPR3F1AnJ6E8KWU974Ngg1RzS)APW)DZJ3y5v7h2j9N2RXQYM)5CCaJ5MbnBCM6lc(Z1dB1ka33GKMqO49279U6W3(P3DNZp8gV((V7tn8JV9WF31(5hB)l8bdF23F4fEXDV978lFKzg8ydESrVX5hET7m6s)HH3(8JU4vh9Axz4T(I9)63C3B9CGpPY9U1v3)gVZWF3NDVR8rv)MB)87FJ7U3DUXOx493)YV0U7CZtCSfb)4Ox7R29UF9Ol9CGbF)N61hD(paoYd)tV9O346dFN)Y()TN7BU9R)lF0FgC6)Y)6OlDxaGT7ophQteyfpK0Ep8AxB)7E3Hx7cJUYFEVF7odV9xT7ox4Ex4Lh9PF1O)2tn6ZVl8JF0)RnEKFXV4h)t3ko8N8i)hN9e)NoX)BH)Si3Mp6J09jon4)C6F1PFYtF6)1N80R(Ro7Ptod4pa)4J729j6Eg4F(4)Khb8)1n9j2E7h)jw)XEITp9t2(hdhyN6n39wxdaIJU05h9gxcqAauGH7SZ9(l3c(3V0hp8YF2Wx8J)bdwz0l(739wFXU3(1ZWTx49gEXVatGhD1pE4l9U79kV)U38fa0xWVm8gF2(F9vb)(EV6FCV)NZV3hDPHFYRn8I3eoox5pFpWkb6d371)Vxnkj5hGNCW)c)Z37PVt28aOYV9hYoWa64n(mmGJG7NfVG9VhSryNqWaCVR(PdV7BHrdW61Ep9FC4L)KH)(Nhq9h(AF5EVYFLNXy)p)n3)Z))W)l4YlEHf9JG5t4RX4fCY3DNBb4127IpZWx8L)raucb(umhagZpxcg8a)9ON987)03bIt7Ct2peXtE93I(Vb8cdwzVN6d376VlSjmMa(rmuaOCyOa(hV4v3)MFiqWloATWoaXTglVvqCcq0Ii(4SyJL32pUxyV2jnwE)p6Dh(YplKxdjDCK1soYWlEL9FR3hSqaMEip6n)tycZUF9ng9kF1))5)TdES9U(1D2)TEEWNT)DU(Ol)2ae9rJ6bMO0GwdwjAZGyK0CYGvc7nyLJuXVj8FwljSDyhVO18wRdqtrTMXHPEB2m9HQK63jOxAn)(X(WM30pSxTGE(R2jO1rpr1Q)toZn3rgSsA0uySooCSQHqH55WHJKgh2BJG0Ao1ctQLg1na(5DcBVEAIxRGTIGt7ralu0oMQTNFZTVOdyn8BU9LiKmLZxZOOoTI2UxTw9XeoXPPyhoyhDWiByyDZ)Q4GUaACc)OkPDRb5XySzbyxfdQTRQA7PeKq18zGUlRdhSJUzIKJbkVK2TgKhJXMaWdEmr1uBghaCCyv)ul1wTGcqAD)eV(jbER2FT1ebhU2kIM6gs4NuZhOGkm9CYgwU2NUd9KaXD9tsdIvdXK2NUd9KaXqBBaMBT0z2(m9NIjb6xhsuuc34wNMd7KaRqdSkbvuJtXbvdGwxH(q1sYUtYqQwCts7t3HEsGyPIBsAF6o0tceRumtrFM(tXKa9se5k060CyNeyTOqNyJtXbvfGMfz5REXr)VVXWV8th(gVpowiS58D35J29oFni4oqGx7ENNbex4Op7vH9bfO5Ox9tgD5Bm8M)bq3aXrp8IFca0aEjSYXgSceoqrpDXxA4Z(MyVf29MpJZ87UZhWodiGOXY(9txpkUXYlh29rBSCNWK0eyUkIB7b8WytWFEgu6pWXC0y51c6SAh)wGWQYIOOX)sJuqGvS9jSB3iCYm8GXGi0155gUyWF1pwy4sBS86b(Dsx3lmnOBcfiY7dDaW9ljnQhymGOEqCOp5NRbchAWkNCWkSJMx66XbjRdC0cJUE4C2WnHemsYeg2BRW2rq)j712d(rW)3nJWnonbG5vaa(DA7hhEqo1aYF3GuFEgagijFQO(Rkgl66(XTdsqZVtoOdh1UrXBUEusiiYBOKr0AR51Uzl4KiHONptzX0UwiqXliwKUHjbKyAhSYSdwPc6)K1lii5f2ddmjC9JczlDQbR01)SE0FO6Gv(n)MbRaH1Tc8AfrMSvJ97b(wq3Nd0jgw38wPlxcyeTVKfjobHfyfe4jGfehaIDWiW0VAGudbOnr9s6dWjVKndH5ey1(XjP16VjHoTfG9b(11A63d0huZyCpjQFhpGiz7UaQysnmPatQwa3dWNJnbYUssIwbTCd6ba7b2ip7Gvo6GvCre2QCuocCbcFr)IEbeccFj971kiMbFMjdM0H5tpyhccn7e4VvGmH0CyhdyzmKnph4tGRURg2RfqQnNLmdWkkibqH0aAKReWJ2pfiXdbK3wKc2ekKW6AAeaSaJ4PqO4Swq(QkHrfbGu(yP0atZlGab0XSfuCb4tm)iBdGjUS4hdCWbcs1nQhjZUdNUbtGR9qdqHkcooH9S2Y4y1Z)lXOmykF4Xc1NQGdb9Z1BzHPeggbwnRfuHwgJgZWOSdA0daXafSrXE0KNqydL3TK0(TaKm9DcyPqPACTAiSZK2A9JphsUMo7uAQFsc0ufShETd6He4H6QDCNJr4xT6EzTaqlO2gjwdYehYmgGhE9glP4GjTwyDBbNnOz)0aV0WUbimolp3z4liqaKQWAf6Ns12cOjdi6TQFZn8wnaSag4bHkDM2vRG7W9seNccwsOEvKpyy5YHcbZCqsdzCYqP(tIBJW9KbQ6J4(RhQRGFgbZiqUO)efmNQ2MrjwymrTxciMm339PZ25LbBhCf6GsxmuBNDMd7QUL74WIgnujZXHdyMcyFMC6PepZ(HwKudN5kljrYe5iM(eofXctOAxzgFkqDbkaFamoCPJjD94OT9A3XhmufJbnXlZ0l1tovX7keOphs6YpHbER3VxQUCePl0y(GO5CCKRB1LoGzs4C98eC9KrMNVBpS1RQPOKPLe8R7h0RzGENGPlXaTyZZ6bfR3NGrlO36(GblBDm3dE8khGq1po(CKqKrTehGSsaCPnoCJaCqDun7gg6z0ogvzhjIlBe5c1AOPOMn4LKzwnkxL1ILLOM0rH3sDt)oD8W)dpyUZ4YGgZkS3AHD6GTrysC(qmQZWCtsrRP0D8GccrvnBYVEZt53EcDkvOR2VEnuFvKo5CbgYQX4of01fTUwvwEiveQurRuMtTQ1joCErNSed(sTIbQ6)6u1)LFUjUqsJcqmeAvjpYCYkK5dOimpd)mJgDM81EaJpwiENHma9097g2ZpnOLhYNa(TkWyGwZYSDc87MGUecX5kI(TktTGwEysz5Oc5odGWcAwaeRq7QFsZm5g8U0q7vUkwt9CwLHtH6izcHjeI2sROOUIRWlG2QYSz7x3pS5gb9KSkuvID4IuuJP80inYiozSde(APt14J86qB1bSzwcRcknzwcf4uSrz1pkJaQjy8hQegvSxtWuompHIk0hGOAZ8DKYfZ3Qj0E96G1eDhMaPkZwSKs(CrYL5fMyh08jguSzkfPSleIAIveNVJ2WpyuSKVlDf0uq9DjbWEd0oMczns5SZRD7Ky9dQISL6Seb8qe9)q2ItWJLOKemNoPZISbc5Wrt822rhYHKfPMRhRCHWrruNmorXw8oWGLybr9UHsbsA2fDuBIxoGpRX1tMPJFJDDwW6GKpJtDlslGtj2pTIBvSnCMZY71p7cvuVauEouMjf1MHuszZTnRCxGe2BLAPaf1aHoboQvdB75hr1NOZaWsfCXYDGMDN3rTzgQ2MfMyMFglOM2fYPnbtHwsrlx8UxwwpJNqkKYMZyk)2NgcJeRzQx4AQZnkmUhrBUJfvvpLOeKbvIpc2tWWMLyOARR6nAsBTvuVupwDlQu44Q26LEv5thfdUQTKaz7be)1cBgMsmulxmZvDqA6OjeIwfzRHtGCM2mR4wxWCM0cHuTjkdBJsrooXiAtLMNXYuHMQi0YtQI8S)ip38YsLoFbUPkv6POA)axogYscteaoscyQXcY6h8V60pt(yRapq4lDdZIf3b1TSKZYjVjJwu(PyjArbj2c0nT6CZExuIJJKMGLXBMpb74NX3llJhMh9u5N6aQROAB)(DJvzr7SE55GAmHMzLXd9DnG(YA)(DJsrF3C03GZXcPAcvKS5KgXerHKlbQW973rQuj57kURi5tlxLht(wJ1CnzKBfMe3FtP7mOw1yiJ(q9rBeKWK1Xuq4ruxyWXpdJtMtHp7NkRsZKjFfhOKfJSw1RFxWG6Vn6drMXsYPTlpNkwxGvynSUoYYZft4GSwxuvM2qv86btjSvMbnxBT6LN2dD7x4sNISHHZi1bgRWcXGZmJfZFqHfJlkigigef8B1AC4rYslflwuXuQRwsDFYR1RJrtyVfiK6KdsLpXUfacrPJ)5qGz3OTasX54muS2lRxB7hImVRRUnuoWkA54e78wnXQD(Fg4bXioYlnoav0gjasxmtg6rZ(sIZooHIS)cUYkH)(meysmjIEnxpO5gKaw4QlJ4(9uUf2(Msj2bi8xAGDTSZPIFSgxgHHQPtVmW3F2detrP9sgECMCNhG6eGsMQQi(ok2WdjZ65DJ4QO6UqJY5OKA5ktw)(00P27ztu7SOTKPsQygw5jLZrXsf7Aau5AoAXTSQ2PBlbyuOHFla1kCM3wOMMUYjbWlMmAcSZwdAsuVJ4L0JFJH36Ifgo1AS42I4oNmpdlrHAWsrBf1hIxXD9colG0fO0RilwDYhRm7Qn43(LTYZ4HWKIt7pzpJaAANt1IMfJHkpI0t)TNOQVon4t2rmm)kXj0QoCl2yCA3oi2lc0(ADI2wLtqwq3luJnQO7IZz(w9aVgu8y3poN5ijtfQMTgKU6Lg51kmG2mTYfAfKrpW4Ax)4nqbGHhHKndakIXJtcR8zwYZ4xPDy8VtIxuJpfrysYjqyHE(eSqS8RhZK1klnSEMnLcUSzMBuTIj0u6hJ2eE4ojH5SQLK6dDlIX(putf5qG0l4SGLxMc1uM)CMD5gqrCQ5GSxwbrLaWdChVWhKDchXr5TYwqRasqTcvrhVisr1Dg1hM1bMeAwSpqPr2tJby6NRw9IB3VGV9MjIY8xqprCEeaOoOwwEtB2LEZ0AkgEm9BYk1lWYtgK5fIbYGC8urDfucKSKqUmpr(wcYpgP46kd8Z5PXQmHWHZHMtdf76GqkgPMcu3bSkXkLVkfhWS9)kTnY2j0Oa8NkSthIAoSfQw(D9BhWf2(If(qbfkzqgDHIS97fuvt47t6ap0Ju6xQ4wZxKi7AIi7AIi7(p0ezxerwDjgmjKdnoJrwfvF6B1uFacxefz7bUMGHCZNqXIRG786OVQjlSjZcjcViDaseur9mqGkzEleunPz3ILKLqwgfxICGOVzywXzl4W6s4fai6SwyVw1c8toNh8(ff4jqy2Udx8tCC4lKmZ3Gh2SpJYKlQO3VnSJuYzDQIPiy2lwMUL434zAvfLQD3RPAEYcLMaEQyCTPuefBo3sivNHPGaWzPmlZu(D6e1pvEAOf3Ohw2gvfUPWw7REx51ScQbbojb(lJs1tIS1tLnvYyWWzBJY1zn6WXshM99MGaZyMssuFvsI(HzCVkJ5)hydF6beomwsSwNSZmEphRhqMLVo0saEiT6rYNoABfQOBELRg8hGn7wUIjfLQGw4mWMRqwIn760nPqy)EfKYT9CiaH4EbEWKj7G2TAnf5KrJ86ymYkXzzxWhhozvyfxu4EWjzopdtMpomczAksnBo8C)J2sZuIUR2Fj1Xa99eDDe9kcEnci2)ZmbblHYVA)oB4bS)KvzfiQV66iOI0yAQBPxLC3fhLXdQdo3wRWChqWY8i5medRFx290ntp)gbb9a9TnaMHC65Q5pAU2fmLx8ciqjfWpfIrGqDccAX60PfS2hMzJToUmkx)m5CkkYKG6eXmBPzXyDXGpReW98w7PB7(cp0j)EwOsXcLVCA6QMaDB6bxK1Eu(WMW4Ym08e2uyIFWGNKE5Y3RzzkVhIUt5PqQQISi5kWgyQ(AYGjv3bRu6A24O56EfXRdiMXb4AYlBPumtiIJ4yczZYk)xWEVvA6TWUXPemHzJgJL4tTmHrt8oSvZ9sGQWmQq3Kx2kIQa(Y2i7Ompzt0jRlo8LKBXtW482N5oLoSnV2R(JIjaecHI)k3HxJEqVCuCqxMx79T3KmJly(sxiJRUFV1dHhisqmE(jjWQpoFdvjW8wa16bargWsDkGhovwoENx7vuxPWfPnjCO2yWugAl7jsrDmpMeqym1urxTozJNSvKS1)X(B7H25FpucPXcGpGV7)m23fdlkpT2O1fTHfrk(ZzP46HkJvQR1CgXBX7uG5vhkIvhXFkP2gvklO2fVXFYS4kCzkRnzblUE5hd0qUQIf0ELCzHRcuRUI8fY1Lzu5hAS22pgrHtGUe0oiM1uFDfiIARGA2GvhL5nAbn3I3crOddnuBa5lWFqjjqn)U0UGKlAVS6qJVFC30EzNms(ESi30j)4pUa3giB4EoSXyDmeZ1ylK2viPeR)NlkkzVpFifUNGOH94qHFUQU0p3)tXlHMLiUGMn8BH2eWob42xTtuul2Y9LwVWzahktkLgNDj4KRGPc2PGChvsp5QqjlK6sjZN(clkBcyjjMCzxQlO8v4RsaS8v(Keau9PVsWhznzRNQbroOAdUiRERhFCrCtMlGm62f6Pa2OO(R1GnZjBCfV2uHdTScJwpHYnZtP1aczXeFbrA21FDqbt2PEAbjGTcS7gVsRSecOxWZAUERKkmlJYv(tOgm8pwfimHGJcMhbfWBtakQH9Fw0rWQcwYNCzQsG2YQaB9O9IwjtzpWAlKkTmRnWBRGZwjWoom1ggrHZZVwmS8LS9dNj9M7Lg1E9bpMB2yDEQHNoeOYxo2UYoqVT8J3a4avCaiOQOEY8SqlumMNjlGZZrD)(tTxzNUufvXTfu8SqwGjotIvi7pkzAIkjh1exDtfRE7XbUN(hGpMRPE9W(yEkXyG9dOJXx(9RhfbS9u8velvCsYmHLKRENVxyUCtxQKIU2ssoZnE0KXrzP0SW6BAJI3RALhYVVjpxe6luA5Jb0F4tIwcEw(SFWfEf95JKgVwH6c3SBhzjtHvkNnT1LrBHf5aqcix(0tip)p8jB)Oktte5UJwlqnMMXlERYj49DX8zsC7K5w0daHTA6NDRFkOP1QK1wHjhrhLCxHGJwDgIt2JZJCctXNkCTWvMR)nyZQvnqR0JCn(I0hP3YGvKMXynuf3hqPkPskGvlzp190Sjl4dP74VgwsgXEMhMStX0ffRo5R1QF5yZwK1FR)ifwKUHdNQ4UXvOcJTAkXmooKTtuwNp2G8xlRJAKGv1wAwQKAe2sobU3wrfl)QV4(5zbuLfOCmAjtydRf3dmQTsWRQfqiHEpMEHZrVZuPCFJKRWuXHkIUsZzyY(y6jUS3z0sMMxv(gQjtUSMJmMy4k2FcbieJX05(IVNQfiekErk4PbMXCDhkIYJY5((MkPIln7ZCf6ez6PiHSv0vkZ72qvL048lC1ujvribEvC(4zUFodHUc0f96O0bwifjqjLiSye1)fQRft65PVSUOYAPu9amJHXywZkGrfPbNDzdFWsCurAV50bPI4WEo4zURqPdcluzcoQM78MKZ0FHYbuGXq8m9ZanJhJX4Eha8Dtgd3sYy4iJXWzkZyGUhckucMugd5R5f3QNE9cIbo(Me2jeU5iO4jX6PunePARAtQcYfYbMIxPT6QcZz0T(KTCRBpsjSmv0EiTvNPhuZ48OXFzpx40Jjf0QmMb3vLLLsvnVPAgqvWUSjGK1Dwgjgc04k0QFTDQ8AzXQws0Te9Di3Mkfkfo1MPAlvvZdmzzqXJog7YO8rY23ZE9DaUWPVhzUmtuGOHCOUcrZef0wP9Mokbz0Jk2CsbuhEFvbECD5QqeLflWE11hAX7xoxMAyu7jcH5H5nvBzHor26QuSlOScX8i7qlOrTp(t6WkMhzdPalpENfTAQ2IiDSu20q2f7I2fbUzabsMVju0tTvgbktIfnhLA2PKQywxRAyPOiHMEUJ0u8Pw4JZjz3(b(mCZyMql2BOlI(FjNbxK7vrVu9yxzKBiNCX9qyO4TTAbThqKkYsCrXl6o(8eYxCH51MVMpPkVBTgsLV0trq3Y9C0TG2dtInA4nT5pkFmJQY4z1m69nJZaGWE7M7)KbV7Mr7veefuuUXEZJLDQZqBrzGNlcd5Fn1Qz(N5uN3nFQvA(dXXcAVZXYjBQFMufvvjW)YKpERcrcqiCwK3Rs7w)Qy371N1o1QLGB)R1NCxKOh3Tfu7IKCh(NDcKiOEOBRgajMvyqg(dD3cQD(r6AWHwePUApSuPJqWBzRFJVQBXZjM4Q)biIB)logzf8aeym9y0l5X3RsjdW9qxi0kmIwxmZiuAwzEx9(UlzZyU(KcNSNdvBGtzWc7yuTHLpIG1v7lO9pTE11MpKXqvKXNz7cOIaBiCqwK3vynhdl2RgRX68yXvs0PsUl5l)XDIBilEdQNQ79PQY3Fx0uDSUhryUlAiIFkFxbqTk5(vjFnT4vLI27cG7lyiCzY2K9KF9Fq()B83)d]] )
--spec:RegisterPack( "复仇Simc(仅打断)", 20250420, [[Hekili:LbvtRTnquW)ojuOyPGk(QsTBtnvkMSnuSo8kRK2yT26l0Uc54d(uDvstDAGekfF2L6gi0t9ITP)AKKvp5)cDLtGCi7U8yyEZmlVhibVdq2yob0LRjRutrs(5s1LKKvae)0qcGcXw9XDfaFSNOMpBs2Yue1ZANSLJlo)6IVD3UvQo1naBxLMlLXzBJLCco2LlG6B)gIp20Lyd7diSfNg4lKqzrXHCO6IcJiwbEM4N6W8rhoeCe)degJ4BrGhCMGJ8P(DzacqSG4irhusqIBmgqMXux(B8RYGfsSaDL6sI4I5obrpQYHABt2kYMWSau5V)r2QVNp(S1l(PyoxFZ8SfxwC(f5FEE5FVopDXZoG0N6sxp9JLP3kyVFtSz1xY)0K)nEs(vNDpFE6xZwn79QJAnQv(SFv(NlkUCE5KR2SA6OwV84(QnB82dhq2d1SDB5JQFqYlmDcqQQEgAINwpTHAAngQz2BGgtxaeKDK9m80RGDETQ44Xnss6y40YirBy3xTDLa))d]] )