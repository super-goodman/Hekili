-- WarlockDestruction.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "WARLOCK" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local PTR = ns.PTR
local spec = Hekili:NewSpecialization( 267 )

---- Local function declarations for increased performance
-- Strings
local strformat = string.format
-- Tables
local insert, remove, sort, wipe = table.insert, table.remove, table.sort, table.wipe
-- Math
local abs, ceil, floor, max, sqrt = math.abs, math.ceil, math.floor, math.max, math.sqrt

-- Common WoW APIs, comment out unneeded per-spec
local GetSpellCastCount = C_Spell.GetSpellCastCount
-- local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetSpellInfo = C_Spell.GetSpellInfo
-- local GetSpellInfo = ns.GetUnpackedSpellInfo
-- local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
-- local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
-- local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)
local GetSpellTexture = C_Spell.GetSpellTexture
local Glyphed = C_SpellBook.IsSpellInSpellBook

spec:RegisterResource( Enum.PowerType.SoulShards, {
    infernal = {
        aura = "infernal",

        last = function ()
            local app = state.buff.infernal.applied
            local t = state.query_time

            return app + floor( ( t - app ) * 2 ) * 0.5
        end,

        interval = 0.5,
        value = 0.1
    },

    chaos_shards = {
        aura = "chaos_shards",

        last = function ()
            local app = state.buff.chaos_shards.applied
            local t = state.query_time

            return app + floor( ( t - app ) * 2 ) * 0.5
        end,

        interval = 0.5,
        value = 0.2,
    },

    immolate = {
        aura = "immolate",
        debuff = true,

        last = function ()
            local app = state.debuff.immolate.applied
            local t = state.query_time
            local tick = state.debuff.immolate.tick_time

            return app + floor( ( t - app ) / tick ) * tick
        end,

        interval = function () return state.debuff.immolate.tick_time end,
        value = 0.1
    },

    blasphemy = {
        aura = "blasphemy",

        last = function ()
            local app = state.buff.blasphemy.applied
            local t = state.query_time

            return app + floor( ( t - app ) * 2 ) * 0.5
        end,

        interval = 0.5,
        value = 0.1
    },
    -- TODO: Summon Overfiend from Avatar of Destruction
}, setmetatable( {
    actual = nil,
    max = nil,
    active_regen = 0,
    inactive_regen = 0,
    forecast = {},
    times = {},
    values = {},
    fcount = 0,
    regen = 0,
    regenerates = false,
}, {
    __index = function( t, k )
        if k == 'count' or k == 'current' then return t.actual

        elseif k == 'actual' then
            t.actual = UnitPower( "player", Enum.PowerType.SoulShards, true ) / 10
            return t.actual

        elseif k == 'max' then
            t.max = UnitPowerMax( "player", Enum.PowerType.SoulShards, true ) / 10
            return t.max

        else
            local amount = k:match( "time_to_(%d+)" )
            amount = amount and tonumber( amount )

            if amount then return state:TimeToResource( t, amount ) end
        end
    end
} ) )

spec:RegisterResource( Enum.PowerType.Mana )

-- Talents
spec:RegisterTalents( {

    -- Warlock
    abyss_walker                   = {  71954,  389609, 1 }, -- Using Demonic Circle: Teleport or your Demonic Gateway reduces all damage you take by $s1% for $s2 sec
    accrued_vitality               = {  71953,  386613, 2 }, -- Drain Life heals for $s1% of the amount drained over $s2 sec
    amplify_curse                  = {  71934,  328774, 1 }, -- Your next Curse of Exhaustion, Curse of Tongues or Curse of Weakness cast within $s1 sec is amplified. Curse of Exhaustion Reduces the target's movement speed by an additional $s2%. Curse of Tongues Increases casting time by an additional $s3%. Curse of Weakness Enemy is unable to critically strike
    banish                         = {  71944,     710, 1 }, -- Banishes an enemy Demon, Aberration, or Elemental, preventing any action for $s1 sec. Limit $s2. Casting Banish again on the target will cancel the effect
    burning_rush                   = {  71949,  111400, 1 }, -- Increases your movement speed by $s1%, but also damages you for $s2% of your maximum health every $s3 sec. Movement impairing effects may not reduce you below $s4% of normal movement speed. Lasts until canceled
    curses_of_enfeeblement         = {  71951,  386105, 1 }, -- Grants access to the following abilities: Curse of Tongues: Forces the target to speak in Demonic, increasing the casting time of all spells by $s3% for $s4 min. Curses: A warlock can only have one Curse active per target. Curse of Exhaustion: Reduces the target's movement speed by $s7% for $s8 sec. Curses: A warlock can only have one Curse active per target
    dark_accord                    = {  71956,  386659, 1 }, -- Reduces the cooldown of Unending Resolve by $s1 sec
    dark_pact                      = {  71936,  108416, 1 }, -- Sacrifices $s1% of your current health to shield you for $s2% of the sacrificed health plus an additional $s3 for $s4 sec. Usable while suffering from control impairing effects
    darkfury                       = {  71941,  264874, 1 }, -- Reduces the cooldown of Shadowfury by $s1 sec and increases its radius by $s2 yards
    demon_skin                     = {  71952,  219272, 2 }, -- Your Soul Leech absorption now ly recharges at a rate of $s1% of maximum health every $s2 sec, and may now absorb up to $s3% of maximum health. Increases your armor by $s4%
    demonic_circle                 = { 100941,  268358, 1 }, -- Summons a Demonic Circle for $s1 min. Cast Demonic Circle: Teleport to teleport to its location and remove all movement slowing effects. You also learn:  Demonic Circle: Teleport Teleports you to your Demonic Circle and removes all movement slowing effects
    demonic_embrace                = {  71930,  288843, 1 }, -- Stamina increased by $s1%
    demonic_fortitude              = {  71922,  386617, 1 }, -- Increases you and your pets' maximum health by $s1%
    demonic_gateway                = {  71955,  111771, 1 }, -- Creates a demonic gateway between two locations. Activating the gateway transports the user to the other gateway. Each player can use a Demonic Gateway only once per $s1 sec
    demonic_inspiration            = {  71928,  386858, 1 }, -- Increases the attack speed of your primary pet by $s1%. Increases Grimoire of Sacrifice damage by $s2%
    demonic_resilience             = {  71917,  389590, 2 }, -- Reduces the chance you will be critically struck by $s2%$s$s3 All damage your primary demon takes is reduced by $s4%
    demonic_tactics                = {  71925,  452894, 1 }, -- Your spells have a $s1% increased chance to deal a critical strike. You gain $s2% more of the Critical Strike stat from all sources
    fel_armor                      = {  71950,  386124, 2 }, -- When Soul Leech absorbs damage, $s2% of damage taken is absorbed and spread out over $s3 sec$s$s4 Reduces damage taken by $s5%
    fel_domination                 = {  71931,  333889, 1 }, -- Your next Imp, Voidwalker, Incubus, Succubus, Felhunter, or Felguard Summon spell is free and has its casting time reduced by $s1%
    fel_pact                       = {  71932,  386113, 1 }, -- Reduces the cooldown of Fel Domination by $s1 sec
    fel_synergy                    = {  71924,  389367, 2 }, -- Soul Leech also heals you for $s1% and your pet for $s2% of the absorption it grants
    fiendish_stride                = {  71948,  386110, 1 }, -- Reduces the damage dealt by Burning Rush by $s1%. Burning Rush increases your movement speed by an additional $s2%
    frequent_donor                 = {  71937,  386686, 1 }, -- Reduces the cooldown of Dark Pact by $s1 sec
    horrify                        = {  71916,   56244, 1 }, -- Your Fear causes the target to tremble in place instead of fleeing in fear
    howl_of_terror                 = {  71947,    5484, 1 }, -- Let loose a terrifying howl, causing $s1 enemies within $s2 yds to flee in fear, disorienting them for $s3 sec. Damage may cancel the effect
    ichor_of_devils                = {  71937,  386664, 1 }, -- Dark Pact sacrifices only $s1% of your current health for the same shield value
    lifeblood                      = {  71940,  386646, 2 }, -- When you use a Healthstone, gain $s1% Leech for $s2 sec
    mortal_coil                    = {  71947,    6789, 1 }, -- Horrifies an enemy target into fleeing, incapacitating for $s1 sec and healing you for $s2% of maximum health
    nightmare                      = {  71916,  386648, 1 }, -- Increases the amount of damage required to break your fear effects by $s1%
    pact_of_gluttony               = {  71926,  386689, 1 }, -- Healthstones you conjure for yourself are now Demonic Healthstones and can be used multiple times in combat. Demonic Healthstones cannot be traded.  Demonic Healthstone Instantly restores $s3% health. $s4 sec cooldown
    resolute_barrier               = {  71915,  389359, 2 }, -- Attacks received that deal at least $s1% of your health decrease Unending Resolve's cooldown by $s2 sec. Cannot occur more than once every $s3 sec
    sargerei_technique             = {  93179,  405955, 2 }, -- Incinerate damage increased by $s1%
    shadowflame                    = {  71941,  384069, 1 }, -- Slows enemies in a $s1 yard cone in front of you by $s2% for $s3 sec
    shadowfury                     = {  71942,   30283, 1 }, -- Stuns all enemies within $s1 yds for $s2 sec
    socrethars_guile               = {  93178,  405936, 2 }, -- Immolate damage increased by $s1%
    soul_conduit                   = {  71939,  215941, 1 }, -- Every Soul Shard you spend has a $s1% chance to be refunded
    soul_leech                     = {  71933,  108370, 1 }, -- All single-target damage done by you and your minions grants you and your pet shadowy shields that absorb $s1% of the damage dealt, up to $s2% of maximum health
    soul_link                      = {  71923,  108415, 2 }, -- $s1% of all damage you take is taken by your demon pet instead. While Grimoire of Sacrifice is active, your Stamina is increased by $s2%
    soulburn                       = {  71957,  385899, 1 }, -- Consumes a Soul Shard, unlocking the hidden power of your spells. Demonic Circle: Teleport: Increases your movement speed by $s1% and makes you immune to snares and roots for $s2 sec. Demonic Gateway: Can be cast instantly. Drain Life: Gain an absorb shield equal to the amount of healing done for $s3 sec. This shield cannot exceed $s4% of your maximum health. Health Funnel: Restores $s5% more health and reduces the damage taken by your pet by $s6% for $s7 sec. Healthstone: Increases the healing of your Healthstone by $s8% and increases your maximum health by $s9% for $s10 sec
    strength_of_will               = {  71956,  317138, 1 }, -- Unending Resolve reduces damage taken by an additional $s1%
    sweet_souls                    = {  71927,  386620, 1 }, -- Your Healthstone heals you for an additional $s1% of your maximum health. Any party or raid member using a Healthstone also heals you for that amount
    swift_artifice                 = {  71918,  452902, 1 }, -- Reduces the cast time of Soulstone and Create Healthstone by $s1%
    teachings_of_the_black_harvest = {  71938,  385881, 1 }, -- Your primary pets gain a bonus effect. Imp: Successful Singe Magic casts grant the target $s1% damage reduction for $s2 sec. Voidwalker: Reduces the cooldown of Shadow Bulwark by $s3 sec. Felhunter: Reduces the cooldown of Devour Magic by $s4 sec. Sayaad: Reduces the cooldown of Seduction by $s5 sec and causes the target to walk faster towards the demon
    teachings_of_the_satyr         = {  71935,  387972, 1 }, -- Reduces the cooldown of Amplify Curse by $s1 sec
    wrathful_minion                = {  71946,  386864, 1 }, -- Increases the damage done by your primary pet by $s1%. Increases Grimoire of Sacrifice damage by $s2%

    -- Destruction
    ashen_remains                  = {  71969,  387252, 1 }, -- Chaos Bolt, Shadowburn, and Incinerate deal $s1% increased damage to targets afflicted by Wither
    avatar_of_destruction          = { 101998,  456975, 1 }, -- Consuming Ritual of Ruin summons an Overfiend for $s1 sec.  Summon Overfiend Generates $s4 Soul Shard Fragment every $s5 sec and casts Chaos Bolt at $s6% effectiveness at its summoner's target
    backdraft                      = {  72067,  196406, 1 }, -- Conflagrate reduces the cast time of your next Incinerate, Chaos Bolt, or Soul Fire by $s1%. Maximum $s2 charges
    backlash                       = {  71983,  387384, 1 }, -- Increases your critical strike chance by $s1%. Physical attacks against you have a $s2% chance to make your next Incinerate instant cast. This effect can only occur once every $s3 sec
    blistering_atrophy             = { 101996,  456939, 1 }, -- Increases the damage of Shadowburn by $s1%. The critical strike chance of Shadowburn is increased by an additional $s2% when damaging a target that is at or below $s3% health
    burn_to_ashes                  = {  71964,  387153, 1 }, -- Chaos Bolt and Rain of Fire increase the damage of your next $s1 Incinerates by $s2%. Shadowburn increases the damage of your next Incinerate by $s3%. Stacks up to $s4 times
    cataclysm                      = {  71974,  152108, 1 }, -- Calls forth a cataclysm at the target location, dealing $s$s2 Shadowflame damage to all enemies within $s3 yards and afflicting them with Wither
    channel_demonfire              = {  72064,  196447, 1 }, -- Launches $s3 bolts of felfire over $s4 sec at random targets afflicted by your Wither within $s5 yds. Each bolt deals $s$s6 Fire damage to the target and $s$s7 Fire damage to nearby enemies
    chaos_incarnate                = {  71966,  387275, 1 }, -- Chaos Bolt, Rain of Fire, and Shadowburn always gain at least $s1% of the maximum benefit from your Mastery: Chaotic Energies
    conflagrate                    = {  72068,   17962, 1 }, -- Triggers an explosion on the target, dealing $s$s2 Fire damage. Reduces the cast time of your next Incinerate or Chaos Bolt by $s3% for $s4 sec. Generates $s5 Soul Shard Fragments
    conflagration_of_chaos         = {  72061,  387108, 1 }, -- Conflagrate and Shadowburn have a $s1% chance to guarantee your next cast of the ability to critically strike, and increase its damage by your critical strike chance
    crashing_chaos                 = {  71960,  417234, 1 }, -- Summon Infernal increases the damage of your next $s1 casts of Chaos Bolt by $s2% or your next $s3 casts of Rain of Fire by $s4%
    decimation                     = { 101997,  456985, 1 }, -- When your direct damaging abilities deal a critical strike, they have a chance to reset the cooldown of Soul Fire and reduce the cast time of your next Soul Fire by $s1%
    demonfire_infusion             = {  72064, 1214442, 1 }, -- Periodic damage from Wither has a $s1% chance to fire a Demonfire bolt at $s2% increased effectiveness. Incinerate has a $s3% chance to fire a Demonfire bolt at $s4% increased effectiveness
    demonfire_mastery              = { 101993,  456946, 1 }, -- Increases the damage of Channel Demonfire by $s1% and it deals damage $s2% faster
    devastation                    = {  72066,  454735, 1 }, -- Increases the critical strike chance of your Destruction spells by $s1%
    diabolic_embers                = {  71968,  387173, 1 }, -- Incinerate now generates $s1% additional Soul Shard Fragments
    dimension_ripper               = { 102003,  457025, 1 }, -- Periodic damage dealt by Wither has a $s1% chance to tear open a Dimensional Rift
    dimensional_rift               = { 102003,  387976, 1 }, -- Rips a hole in time and space, opening a random portal that damages your target: Shadowy Tear Deals $s$s6 Shadow damage over $s7 sec. Unstable Tear Deals $s$s10 Chaos damage over $s11 sec. Chaos Tear Fires a Chaos Bolt, dealing $s$s14 Chaos damage. This Chaos Bolt always critically strikes and your critical strike chance increases its damage. Generates $s15 Soul Shard Fragments
    emberstorm                     = {  72062,  454744, 1 }, -- Increases the damage done by your Fire spells by $s1% and reduces the cast time of your Incinerate spell by $s2%
    eradication                    = {  71984,  196412, 1 }, -- Chaos Bolt and Shadowburn increases the damage you deal to the target by $s1% for $s2 sec
    explosive_potential            = {  72059,  388827, 1 }, -- Reduces the cooldown of Conflagrate by $s1 sec
    fiendish_cruelty               = { 101994,  456943, 1 }, -- When Shadowburn fails to kill a target that is at or below $s1% health, its cooldown is reduced by $s2 sec
    fire_and_brimstone             = {  71982,  196408, 1 }, -- Incinerate now also hits all enemies near your target for $s1% damage
    flashpoint                     = {  71972,  387259, 1 }, -- When your Wither deals periodic damage to a target above $s1% health, gain $s2% Haste for $s3 sec. Stacks up to $s4 times
    grimoire_of_sacrifice          = {  71971,  108503, 1 }, -- Sacrifices your demon pet for power, gaining its command demon ability, and causing your spells to sometimes also deal $s1 additional Shadow damage. Lasts until canceled or until you summon a demon pet
    havoc                          = {  71979,   80240, 1 }, -- Marks a target with Havoc for $s1 sec, causing your single target spells to also strike the Havoc victim for $s2% of the damage dealt
    improved_chaos_bolt            = { 101992,  456951, 1 }, -- Increases the damage of Chaos Bolt by $s1% and reduces its cast time by $s2 sec
    improved_conflagrate           = {  72065,  231793, 1 }, -- Conflagrate gains an additional charge
    indiscriminate_flames          = { 101995,  457114, 1 }, -- Backdraft increases the damage of your next Chaos Bolt by $s1% and increases the critical strike chance of your next Incinerate or Soul Fire by $s2%
    internal_combustion            = {  71980,  266134, 1 }, -- Chaos Bolt consumes up to $s1 sec of Wither's damage over time effect on your target, instantly dealing that much damage
    master_ritualist               = {  71962,  387165, 1 }, -- Ritual of Ruin requires $s1 less Soul Shards spent
    mayhem                         = {  71979,  387506, 1 }, -- Your single target spells have a $s1% chance to apply Havoc to a nearby enemy for $s2 sec.  Havoc Marks a target with Havoc for $s5 sec, causing your single target spells to also strike the Havoc victim for $s6% of the damage dealt
    power_overwhelming             = {  71965,  387279, 1 }, -- Consuming Soul Shards increases your Mastery by $s1% for $s2 sec for each shard spent. Gaining a stack does not refresh the duration
    pyrogenics                     = {  71975,  387095, 1 }, -- Enemies affected by your Rain of Fire take $s1% increased damage from your Fire spells
    raging_demonfire               = {  72063,  387166, 1 }, -- Channel Demonfire fires an additional $s1 bolts. Each bolt increases the remaining duration of Wither on all targets hit by $s2 sec
    rain_of_chaos                  = {  71960,  266086, 1 }, -- While your initial Infernal is active, every Soul Shard you spend has a $s1% chance to summon an additional Infernal that lasts $s2 sec
    rain_of_fire_ground            = {  72069,    5740, 1 }, -- Calls down a rain of hellfire the target location, dealing $s$s2 Fire damage over $s3 sec to enemies in the area. This spell is cast at a selected location
    rain_of_fire_targeted          = {  72069, 1214467, 1 }, -- Calls down a rain of hellfire upon your target, dealing $s$s2 Fire damage over $s3 sec to enemies in the area. This spell is cast at your target
    reverse_entropy                = {  71980,  205148, 1 }, -- Your spells have a chance to grant you $s1% Haste for $s2 sec
    ritual_of_ruin                 = {  71970,  387156, 1 }, -- Every $s1 Soul Shards spent grants Ritual of Ruin, making your next Chaos Bolt or Rain of Fire consume no Soul Shards and have its cast time reduced by $s2%
    roaring_blaze                  = {  72065,  205184, 1 }, -- Conflagrate increases your Soul Fire, Wither, Incinerate, and Conflagrate damage to the target by $s1% for $s2 sec
    rolling_havoc                  = {  71961,  387569, 1 }, -- Each time your spells duplicate from Havoc, gain $s1% increased damage for $s2 sec. Stacks up to $s3 times
    ruin                           = {  71967,  387103, 1 }, -- Increases the critical strike damage of your Destruction spells by $s1%
    scalding_flames                = {  71973,  388832, 1 }, -- Increases the damage of Wither by $s1% and its duration by $s2 sec
    shadowburn                     = {  72060,   17877, 1 }, -- Blasts a target for $s$s2 Shadowflame damage, gaining $s3% critical strike chance on targets that have $s4% or less health. Restores $s5 Soul Shard and refunds a charge if the target dies within $s6 sec
    soul_fire                      = {  71978,    6353, 1 }, -- Burns the enemy's soul, dealing $s$s2 Fire damage and applying Wither. Generates $s3 Soul Shard
    summon_infernal                = {  71985,    1122, 1 }, -- Summons an Infernal from the Twisting Nether, impacting for $s$s2 Fire damage and stunning all enemies in the area for $s3 sec. The Infernal will serve you for $s4 sec, dealing $s5 damage to all nearby enemies every $s6 sec and generating $s7 Soul Shard Fragment every $s8 sec
    summoners_embrace              = {  71971,  453105, 1 }, -- Increases the damage dealt by your spells and your demon by $s1%
    unstable_rifts                 = { 102427,  457064, 1 }, -- Bolts from Dimensional Rift now deal $s1% of damage dealt to nearby enemies as Fire damage

    -- Diabolist
    abyssal_dominion               = {  94831,  429581, 1 }, -- Summon Infernal becomes empowered, dealing $s1% increased damage. When your Summon Infernal ends, it fragments into two smaller Infernals at $s2% effectiveness that lasts $s3 sec
    annihilans_bellow              = {  94836,  429072, 1 }, -- Howl of Terror cooldown is reduced by $s1 sec and range is increased by $s2 yds
    cloven_souls                   = {  94849,  428517, 1 }, -- Enemies damaged by your Overlord have their souls cloven, increasing damage taken by you and your pets by $s1% for $s2 sec
    cruelty_of_kerxan              = {  94848,  429902, 1 }, -- Summon Infernal grants Diabolic Ritual and reduces its duration by $s1 sec
    diabolic_ritual                = {  94855,  428514, 1 }, -- Casting Chaos Bolt, Rain of Fire, or Shadowburn grants Diabolic Ritual for $s1 sec. If Diabolic Ritual is already active, its duration is reduced by $s2 sec instead. When Diabolic Ritual expires you gain Demonic Art, causing your next Chaos Bolt, Rain of Fire, or Shadowburn to summon an Overlord, Mother of Chaos, or Pit Lord that unleashes a devastating attack against your enemies
    flames_of_xoroth               = {  94833,  429657, 1 }, -- Fire damage increased by $s1% and damage dealt by your demons is increased by $s2%
    gloom_of_nathreza              = {  94843,  429899, 1 }, -- Enemies marked by your Havoc take $s1% increased damage from your single target spells
    infernal_bulwark               = {  94852,  429130, 1 }, -- Unending Resolve grants Soul Leech equal to $s1% of your maximum health and increases the maximum amount Soul Leech can absorb by $s2% for $s3 sec
    infernal_machine               = {  94848,  429917, 1 }, -- Spending Soul Shards on damaging spells while your Infernal is active decreases the duration of Diabolic Ritual by $s1 additional sec
    infernal_vitality              = {  94852,  429115, 1 }, -- Unending Resolve heals you for $s1% of your maximum health over $s2 sec
    ruination                      = {  94830,  428522, 1 }, -- Summoning a Pit Lord causes your next Chaos Bolt to become Ruination.  Ruination Call down a demon-infested meteor from the depths of the Twisting Nether, dealing $s$s4 Chaos damage on impact to all enemies within $s5 yds of the target and summoning $s6 Diabolic Imp. Damage is further increased by your critical strike chance and is reduced beyond $s7 targets
    secrets_of_the_coven           = {  94826,  428518, 1 }, -- Mother of Chaos empowers your next Incinerate to become Infernal Bolt.  Infernal Bolt Hurl a bolt enveloped in the infernal flames of the abyss, dealing $s$s4 Fire damage to your enemy target and generating $s5 Soul Shards
    souletched_circles             = {  94836,  428911, 1 }, -- You always gain the benefit of Soulburn when casting Demonic Circle: Teleport, increasing your movement speed by $s1% and making you immune to snares and roots for $s2 sec
    touch_of_rancora               = {  94856,  429893, 1 }, -- Demonic Art increases the damage of your next Chaos Bolt, Rain of Fire, or Shadowburn by $s1% and reduces its cast time by $s2%. Casting Chaos Bolt reduces the duration of Diabolic Ritual by $s3 additional sec

    -- Hellcaller
    aura_of_enfeeblement           = {  94822,  440059, 1 }, -- While Unending Resolve is active, enemies within $s1 yds are affected by Curse of Tongues and Curse of Weakness at $s2% effectiveness
    blackened_soul                 = {  94837,  440043, 1 }, -- Spending Soul Shards on damaging spells will further corrupt enemies affected by your Wither, increasing its stack count by $s2. Each time Wither gains a stack it has a chance to collapse, consuming a stack every $s3 sec to deal $s$s4 Shadowflame damage to its host until $s5 stack remains
    bleakheart_tactics             = {  94854,  440051, 1 }, -- Wither damage increased $s1%. When Wither gains a stack from Blackened Soul, it has a chance to gain an additional stack
    curse_of_the_satyr             = {  94822,  440057, 1 }, -- Curse of Weakness is empowered and transforms into Curse of the Satyr.  Curse of the Satyr Increases the time between an enemy's attacks by $s3% and the casting time of all spells by $s4% for $s5 min. Curses: A warlock can only have one Curse active per target
    hatefury_rituals               = {  94854,  440048, 1 }, -- Wither deals $s1% increased periodic damage but its duration is $s2% shorter
    illhoofs_design                = {  94835,  440070, 1 }, -- Sacrifice $s1% of your maximum health. Soul Leech now absorbs an additional $s2% of your maximum health
    malevolence                    = {  94842,  442726, 1 }, -- Dark magic erupts from you and corrupts your soul for $s2 sec, causing enemies suffering from your Wither to take $s$s3 Shadowflame damage and increase its stack count by $s4. While corrupted your Haste is increased by $s5% and spending Soul Shards on damaging spells grants $s6 additional stack of Wither
    mark_of_perotharn              = {  94844,  440045, 1 }, -- Critical strike damage dealt by Wither is increased by $s1%. Wither has a chance to gain a stack when it critically strikes. Stacks gained this way do not activate Blackened Soul
    mark_of_xavius                 = {  94834,  440046, 1 }, -- Wither damage increased by $s1%. Blackened Soul deals $s2% increased damage per stack of Wither
    seeds_of_their_demise          = {  94829,  440055, 1 }, -- After Wither reaches $s2 stacks or when its host reaches $s3% health, Wither deals $s$s4 Shadowflame damage to its host every $s5 sec until $s6 stack remains. When Blackened Soul deals damage, you have a chance to gain $s7 stacks of Flashpoint
    wither                         = {  94840,  445468, 1 }, -- Bestows a vile malediction upon the target, burning the sinew and muscle of its host, dealing $s$s4 Shadowflame damage immediately and an additional $s$s5 Shadowflame damage over $s6 sec$s$s7 Periodic damage generates $s8 Soul Shard Fragment and has a $s9% chance to generate an additional $s10 on critical strikes. Replaces Immolate
    xalans_cruelty                 = {  94845,  440040, 1 }, -- Shadow damage dealt by your spells and abilities is increased by $s1% and your Shadow spells gain $s2% more critical strike chance from all sources
    xalans_ferocity                = {  94853,  440044, 1 }, -- Fire damage dealt by your spells and abilities is increased by $s1% and your Fire spells gain $s2% more critical strike chance from all sources
    zevrims_resilience             = {  94835,  440065, 1 }, -- Dark Pact heals you for $s1 every $s2 sec while active
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    bane_of_havoc                  =  164, -- (461917) Replaces Havoc. Curses the ground with a demonic bane, causing all of your single target spells to also strike targets marked with the bane for $s1% of the damage dealt. Lasts $s2 sec
    bloodstones                    = 5696, -- (1218692) Your Healthstones are replaced with Bloodstones which increase their user's haste by $s1% for $s2 sec instead of healing
    bonds_of_fel                   = 5401, -- (353753) Encircle enemy players with Bonds of Fel. If any affected player leaves the $s2 yd radius they explode, dealing $s$s3 Fire damage split amongst all nearby enemies
    fel_fissure                    =  157, -- (200586) Chaos Bolt creates a $s1 yd wide eruption of Felfire under the target, reducing movement speed by $s2% and reducing all healing received by $s3% on all enemies within the fissure. Lasts $s4 sec
    gateway_mastery                = 5382, -- (248855) Increases the range of your Demonic Gateway by $s1 yards, and reduces the cast time by $s2%. Reduces the time between how often players can take your Demonic Gateway by $s3 sec
    impish_instincts               = 5580, -- (409835) Taking direct Physical damage reduces the cooldown of Demonic Circle by $s1 sec. Cannot occur more than once every $s2 sec
    nether_ward                    = 3508, -- (212295) Surrounds the caster with a shield that lasts $s1 sec, reflecting all harmful spells cast on you
    shadow_rift                    = 5393, -- (353294) Conjure a Shadow Rift at the target location lasting $s1 sec. Enemy players within the rift when it expires are teleported to your Demonic Circle. Must be within $s2 yds of your Demonic Circle to cast
    soul_rip                       = 5607, -- (410598) Fracture the soul of up to $s1 target players within $s2 yds into the shadows, reducing their damage done by $s3% and healing received by $s4% for $s5 sec. Souls are fractured up to $s6 yds from the player's location. Players can retrieve their souls to remove this effect
} )

spec:RegisterHook( "TALENTS_UPDATED", function()
    talent.rain_of_fire = talent.rain_of_fire_targeted.enabled and talent.rain_of_fire_targeted or talent.rain_of_fire_ground
end )

-- Auras
spec:RegisterAuras( {
    active_havoc = {
        duration = function () return talent.mayhem.enabled and class.auras.mayhem.duration or class.auras.havoc.duration end,
        max_stack = 1,

        generate = function( ah )
            ah.duration = class.auras.havoc.duration

            if talent.mayhem.enabled and active_dot.mayhem > 0 then
                ah.count = 1
                ah.applied = last_havoc
                ah.expires = last_havoc + ah.duration
                ah.caster = "player"
            elseif pvptalent.bane_of_havoc.enabled and debuff.bane_of_havoc.up and query_time - last_havoc < ah.duration then
                ah.count = 1
                ah.applied = last_havoc
                ah.expires = last_havoc + ah.duration
                ah.caster = "player"
                return
            elseif not pvptalent.bane_of_havoc.enabled and active_dot.havoc > 0 and query_time - last_havoc < ah.duration then
                ah.count = 1
                ah.applied = last_havoc
                ah.expires = last_havoc + ah.duration
                ah.caster = "player"
                return
            end

            ah.count = 0
            ah.applied = 0
            ah.expires = 0
            ah.caster = "nobody"
        end
    },
    -- Going to need to keep an eye on this.  active_dot.bane_of_havoc won't work due to no SPELL_AURA_APPLIED event.
    bane_of_havoc = {
        id = 200548,
        duration = function () return level > 53 and 12 or 10 end,
        max_stack = 1,
        generate = function( boh )
            boh.applied = action.bane_of_havoc.lastCast
            boh.expires = boh.applied > 0 and ( boh.applied + boh.duration ) or 0
        end,
    },

    accrued_vitality = {
        id = 386614,
        duration = 10,
        max_stack = 1,
        copy = 339298
    },
    -- Talent: Next Curse of Tongues, Curse of Exhaustion or Curse of Weakness is amplified.
    -- https://wowhead.com/beta/spell=328774
    amplify_curse = {
        id = 328774,
        duration = 15,
        max_stack = 1
    },
    -- Time between attacks increased $w1% and casting speed increased by $w2%.
    aura_of_enfeeblement = {
        id = 449587,
        duration = 8.0,
        max_stack = 1,
    },
    backdraft = {
        id = 117828,
        duration = 10,
        type = "Magic",
        max_stack = 2,
    },
    -- Talent: Your next Incinerate is instant cast.
    -- https://wowhead.com/beta/spell=387385
    backlash = {
        id = 387385,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Invulnerable, but unable to act.
    -- https://wowhead.com/beta/spell=710
    banish = {
        id = 710,
        duration = 30,
        mechanic = "banish",
        type = "Magic",
        max_stack = 1
    },
    blasphemy = {
        id = 367680,
        duration = 8,
        max_stack = 1,
    },
    -- Talent: Incinerate damage increased by $w1%.
    -- https://wowhead.com/beta/spell=387154
    burn_to_ashes = {
        id = 387154,
        duration = 20,
        max_stack = 6
    },
    -- Talent: Movement speed increased by $s1%.
    -- https://wowhead.com/beta/spell=111400
    burning_rush = {
        id = 111400,
        duration = 3600,
        max_stack = 1
    },
    -- Talent:
    -- https://wowhead.com/beta/spell=196447
    channel_demonfire = {
        id = 196447,
        duration = function() return 3 * ( 1 - 0.35 * talent.demonfire_mastery.rank ) * haste end,
        tick_time = function() return 3 * ( 1 - 0.35 * talent.demonfire_mastery.rank ) * ( 1 - 0.12 * talent.raging_demonfire.rank ) * haste end,
        type = "Magic",
        max_stack = 1
    },
    -- Damage taken from you and your pets is increased by $s1%.
    cloven_soul = {
        id = 434424,
        duration = 15.0,
        max_stack = 1
    },
    conflagrate = {
        id = 265931,
        duration = 8,
        type = "Magic",
        max_stack = 1,
        copy = "roaring_blaze"
    },
    conflagration_of_chaos_cf = {
        id = 387109,
        duration = 20,
        max_stack = 1
    },
    conflagration_of_chaos_sb = {
        id = 387110,
        duration = 20,
        max_stack = 1
    },
    -- Suffering $w1 Shadow damage every $t1 sec.
    -- https://wowhead.com/beta/spell=146739
    corruption = {
        id = 146739,
        duration = 14,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    crashing_chaos = {
        id = 417282,
        duration = 45,
        max_stack = 8,
    },
    -- Movement speed slowed by $w1%.
    -- https://wowhead.com/beta/spell=334275
    curse_of_exhaustion = {
        id = 334275,
        duration = 12,
        mechanic = "snare",
        type = "Magic",
        max_stack = 1
    },
    -- Speaking Demonic increasing casting time by $w1%.
    -- https://wowhead.com/beta/spell=1714
    curse_of_tongues = {
        id = 1714,
        duration = 60,
        type = "Magic",
        max_stack = 1
    },
    -- Time between attacks increased by $w1%. $?e1[Chance to critically strike reduced by $w2%.][]
    -- https://wowhead.com/beta/spell=702
    curse_of_weakness = {
        id = 702,
        duration = 120,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Absorbs $w1 damage.
    -- https://wowhead.com/beta/spell=108416
    dark_pact = {
        id = 108416,
        duration = 20,
        max_stack = 1
    },
    -- Damage of $?s137046[Incinerate]?s198590[Drain Soul]?a137044&!s137046[Demonbolt][Shadow Bolt] increased by $w2%.
    -- https://wowhead.com/beta/spell=325299
    decimating_bolt = {
        id = 325299,
        duration = 45,
        type = "Magic",
        max_stack = 3
    },
    -- The cast time of your next Soul Fire is reduced by $s1%.
    decimation = {
        id = 457555,
        duration = 10.0,
        max_stack = 1,
    },
    demonic_art_mother_of_chaos = {
        id = 432794,
        duration = 60,
        max_stack = 1,
        copy = { "demonic_art_mother", "art_mother" }
    },
    demonic_art_overlord = {
        id = 428524,
        duration = 60,
        max_stack = 1,
        copy = "art_overlord",
    },
    demonic_art_pit_lord = {
        id = 432795,
        duration = 60,
        max_stack = 1,
        copy = "art_pit_lord",
    },
    demonic_art = {
        alias = { "demonic_art_overlord", "demonic_art_mother_of_chaos", "demonic_art_pit_lord" },
        aliasMode = "first",
        aliasType = "buff"
    },
    -- [428524] Your next Soul Shard spent summons an Overlord that unleashes a devastating attack.
    diabolic_ritual_overlord = {
        id = 431944,
        duration = 20.0,
        max_stack = 1,
        copy = "ritual_overlord"
    },
    diabolic_ritual_mother_of_chaos = {
        id = 432815,
        duration = 20.0,
        max_stack = 1,
        copy = "ritual_mother"
    },
    diabolic_ritual_pit_lord = {
        id = 432816,
        duration = 20.0,
        max_stack = 1,
        copy = "ritual_pit_lord"
    },
    diabolic_ritual = {
        alias = { "diabolic_ritual_overlord", "diabolic_ritual_mother_of_chaos", "diabolic_ritual_pit_lord" },
        aliasMode = "first",
        aliasType = "buff"
    },
    -- Talent:
    -- https://wowhead.com/beta/spell=268358
    demonic_circle = {
        id = 268358,
        duration = 3600,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Attack speed increased by $w1%.
    -- https://wowhead.com/beta/spell=386861
    demonic_inspiration = {
        id = 386861,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, _, count, _, duration, expires, caster = FindUnitBuffByID( "pet", 386861 )

            if name then
                t.name = name
                t.count = count
                t.expires = expires
                t.applied = expires - duration
                t.caster = caster
                return
            end

            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end,
    },
    -- Movement speed increased by $w1%.
    -- https://wowhead.com/beta/spell=339412
    demonic_momentum = {
        id = 339412,
        duration = 5,
        max_stack = 1
    },
    -- Damage done increased by $w2%.
    -- https://wowhead.com/beta/spell=171982
    demonic_synergy = {
        id = 171982,
        duration = 15,
        max_stack = 1
    },
    -- Doomed to take $w1 Shadow damage.
    -- https://wowhead.com/beta/spell=603
    doom = {
        id = 603,
        duration = 20,
        tick_time = 20,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $s1 Shadow damage every $t1 seconds.  Restoring health to the Warlock.
    -- https://wowhead.com/beta/spell=234153
    drain_life = {
        id = 234153,
        duration = function () return 5 * haste * ( legendary.claw_of_endereth.enabled and 0.5 or 1 ) end,
        tick_time = function () return haste * ( legendary.claw_of_endereth.enabled and 0.5 or 1 ) end,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Shadow damage every $t1 seconds.
    -- https://wowhead.com/beta/spell=198590
    drain_soul = {
        id = 198590,
        duration = 5,
        tick_time = 1,
        type = "Magic",
        max_stack = 1
    },
    -- Healing for $m1% of maximum health every $t1 sec.; Spell casts are not delayed by taking damage.
    empowered_healthstone = {
        id = 262080,
        duration = 6.0,
        max_stack = 1,
    },
    -- Talent: Damage taken from the Warlock increased by $s1%.
    -- https://wowhead.com/beta/spell=196414
    eradication = {
        id = 196414,
        duration = 7,
        max_stack = 1
    },
    -- Controlling Eye of Kilrogg.  Detecting Invisibility.
    -- https://wowhead.com/beta/spell=126
    eye_of_kilrogg = {
        id = 126,
        duration = 45,
        type = "Magic",
        max_stack = 1
    },
    -- $w1 damage is being delayed every $387846t1 sec.; Damage Remaining: $w2
    fel_armor = {
        id = 387847,
        duration = 5,
        max_stack = 1,
        copy = 387846
    },
    -- Talent: Imp, Voidwalker, Succubus, Felhunter, or Felguard casting time reduced by $/1000;S1 sec.
    -- https://wowhead.com/beta/spell=333889
    fel_domination = {
        id = 333889,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Haste increased by $w1%.
    -- https://wowhead.com/beta/spell=387263
    flashpoint = {
        id = 387263,
        duration = 10,
        max_stack = 3
    },
    -- Talent: Sacrificed your demon pet to gain its command demon ability.    Your spells sometimes deal additional Shadow damage.
    -- https://wowhead.com/beta/spell=196099
    grimoire_of_sacrifice = {
        id = 196099,
        duration = 3600,
        max_stack = 1
    },
    -- Taking $s2% increased damage from the Warlock. Haunt's cooldown will be reset on death.
    -- https://wowhead.com/beta/spell=48181
    haunt = {
        id = 48181,
        duration = 18,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Spells cast by the Warlock also hit this target for $s1% of normal initial damage.
    -- https://wowhead.com/beta/spell=80240
    havoc = {
        id = 80240,
        duration = function()
            if talent.mayhem.enabled then return 5 end
            return 15
        end,
        type = "Magic",
        max_stack = 1
    },
    -- Transferring health.
    -- https://wowhead.com/beta/spell=755
    health_funnel = {
        id = 755,
        duration = 5,
        tick_time = 1,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Disoriented.
    -- https://wowhead.com/beta/spell=5484
    howl_of_terror = {
        id = 5484,
        duration = 20,
        mechanic = "flee",
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Fire damage every $t1 sec.$?a339892[   Damage taken by Chaos Bolt and Incinerate increased by $w2%.][]
    -- https://wowhead.com/beta/spell=157736
    immolate = {
        id = 157736,
        duration = function() return ( 18 + 3 * talent.scalding_flames.rank ) * haste end,
        tick_time = function() return 3 * haste end,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Shadow damage every $t1 sec.
    -- https://wowhead.com/beta/spell=322170
    impending_catastrophe = {
        id = 322170,
        duration = 12,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Every $s1 Soul Shards spent grants Ritual of Ruin, making your next Chaos Bolt or Rain of Fire consume no Soul Shards and have its cast time reduced by $387157s3%.
    -- https://wowhead.com/beta/spell=387158
    impending_ruin = {
        id = 387158,
        duration = 3600,
        max_stack = 15
    },
    infernal = {
        duration = 30,
        generate = function( inf )
            if pet.infernal.alive then
                inf.count = 1
                inf.applied = pet.infernal.expires - 30
                inf.expires = pet.infernal.expires
                inf.caster = "player"
                return
            end

            inf.count = 0
            inf.applied = 0
            inf.expires = 0
            inf.caster = "nobody"
        end,
    },
    infernal_awakening = {
        id = 22703,
        duration = 2,
        max_stack = 1,
    },
    infernal_bolt = {
        id = 433891,
        duration = 20,
        max_stack = 1
    },
    -- Soul Leech can absorb an additional $s1% of your maximum health.
    infernal_bulwark = {
        id = 434561,
        duration = 8.0,
        max_stack = 1,
    },
    -- Healing for ${$s1*($d/$t1)}% of your maximum health over $d.
    infernal_vitality = {
        id = 434559,
        duration = 10.0,
        max_stack = 1,
    },
    -- Inflicts Shadow damage.
    laserbeam = {
        id = 212529,
        duration = 0.0,
        max_stack = 1,
    },
    -- Talent: Leech increased by $w1%.
    -- https://wowhead.com/beta/spell=386647
    lifeblood = {
        id = 386647,
        duration = 20,
        max_stack = 1
    },
    -- Haste increased by $w1% and $?s324536[Malefic Rapture grants $w2 additional stack of Wither to targets affected by Unstable Affliction.][Chaos Bolt grants $w3 additional stack of Wither.]; All of your active Withers are acute.
    malevolence = {
        id = 442726,
        duration = 20.0,
        max_stack = 1,
    },
    -- Talent: Incapacitated.
    -- https://wowhead.com/beta/spell=6789
    mortal_coil = {
        id = 6789,
        duration = 3,
        type = "Magic",
        max_stack = 1
    },
    -- Reflecting all spells.
    -- https://wowhead.com/beta/spell=212295
    nether_ward = {
        id = 212295,
        duration = 3,
        type = "Magic",
        max_stack = 1
    },
    -- Movement speed increased by $s3%.
    -- https://wowhead.com/beta/spell=30151
    pursuit = {
        id = 30151,
        duration = 8,
        max_stack = 1
    },
    -- Talent: Fire damage taken increased by $s1%.
    -- https://wowhead.com/beta/spell=387096
    pyrogenics = {
        id = 387096,
        duration = 2,
        type = "Magic",
        max_stack = 1
    },
    rain_of_chaos = {
        id = 266087,
        duration = 30,
        max_stack = 1
    },
    -- Talent: $42223s1 Fire damage every $5740t2 sec.
    -- https://wowhead.com/beta/spell=5740
    rain_of_fire = {
        id = 5740,
        duration = 8,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Haste increased by $s1%.
    -- https://wowhead.com/beta/spell=266030
    reverse_entropy = {
        id = 266030,
        duration = 8,
        type = "Magic",
        max_stack = 1
    },
    ritual_overlord = {

    },
    ritual_mother = {

    },
    ritual_pit_lord = {},
    -- Your next Chaos Bolt or Rain of Fire cost no Soul Shards and has its cast time reduced by 50%.
    ritual_of_ruin = {
        id = 387157,
        duration = 30,
        max_stack = 1
    },
    --
    -- https://wowhead.com/beta/spell=698
    ritual_of_summoning = {
        id = 698,
        duration = 120,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Damage increased by $W1%.
    -- https://wowhead.com/beta/spell=387570
    rolling_havoc = {
        id = 387570,
        duration = 6,
        max_stack = 5
    },
    ruination = {
        id = 433885,
        duration = 20,
        max_stack = 1
    },
    -- Covenant: Suffering $w2 Arcane damage every $t2 sec.
    -- https://wowhead.com/beta/spell=312321
    scouring_tithe = {
        id = 312321,
        duration = 18,
        type = "Magic",
        max_stack = 1
    },
    -- Disoriented.
    -- https://wowhead.com/beta/spell=6358
    seduction = {
        id = 6358,
        duration = 30,
        mechanic = "sleep",
        type = "Magic",
        max_stack = 1
    },
    -- Embeded with a demon seed that will soon explode, dealing Shadow damage to the caster's enemies within $27285A1 yards, and applying Corruption to them.    The seed will detonate early if the target is hit by other detonations, or takes $w3 damage from your spells.
    -- https://wowhead.com/beta/spell=27243
    seed_of_corruption = {
        id = 27243,
        duration = 12,
        type = "Magic",
        max_stack = 1
    },
    -- Maximum health increased by $s1%.
    -- https://wowhead.com/beta/spell=17767
    shadow_bulwark = {
        id = 17767,
        duration = 20,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: If the target dies and yields experience or honor, Shadowburn restores ${$245731s1/10} Soul Shard and refunds a charge.
    -- https://wowhead.com/beta/spell=17877
    shadowburn = {
        id = 17877,
        duration = 5,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Slowed by $w1% for $d.
    -- https://wowhead.com/beta/spell=384069
    shadowflame = {
        id = 384069,
        duration = 6,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=30283
    shadowfury = {
        id = 30283,
        duration = 3,
        mechanic = "stun",
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Shadow damage every $t1 sec and siphoning life to the casting Warlock.
    -- https://wowhead.com/beta/spell=63106
    siphon_life = {
        id = 63106,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    -- Absorbs $w1 damage.
    -- https://wowhead.com/beta/spell=108366
    soul_leech = {
        id = 108366,
        duration = 15,
        max_stack = 1
    },
    -- Talent: $s1% of all damage taken is split with the Warlock's summoned demon.    The Warlock is healed for $s2% and your demon is healed for $s3% of all absorption granted by Soul Leech.
    -- https://wowhead.com/beta/spell=108446
    soul_link = {
        id = 108446,
        duration = 3600,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $s2 Nature damage every $t2 sec.
    -- https://wowhead.com/beta/spell=386997
    soul_rot = {
        id = 386997,
        duration = 8,
        type = "Magic",
        max_stack = 1,
        copy = 325640
    },
    --
    -- https://wowhead.com/beta/spell=246985
    soul_shards = {
        id = 246985,
        duration = 3600,
        max_stack = 1
    },
    -- Talent: Consumes a Soul Shard, unlocking the hidden power of your spells.    |cFFFFFFFFDemonic Circle: Teleport|r: Increases your movement speed by $387633s1% and makes you immune to snares and roots for $387633d.    |cFFFFFFFFDemonic Gateway|r: Can be cast instantly.    |cFFFFFFFFDrain Life|r: Gain an absorb shield equal to the amount of healing done for $387630d. This shield cannot exceed $387630s1% of your maximum health.    |cFFFFFFFFHealth Funnel|r: Restores $387626s1% more health and reduces the damage taken by your pet by ${$abs($387641s1)}% for $387641d.    |cFFFFFFFFHealthstone|r: Increases the healing of your Healthstone by $387626s2% and increases your maximum health by $387636s1% for $387636d.
    -- https://wowhead.com/beta/spell=387626
    soulburn = {
        id = 387626,
        duration = 3600,
        max_stack = 1
    },
    soulburn_demonic_circle = {
        id = 387633,
        duration = 8,
        max_stack = 1,
    },
    soulburn_drain_life = {
        id = 394810,
        duration = 30,
        max_stack = 1,
    },
    soulburn_health_funnel = {
        id = 387641,
        duration = 10,
        max_stack = 1,
    },
    soulburn_healthstone = {
        id = 387636,
        duration = 12,
        max_stack = 1,
    },
    -- Soul stored by $@auracaster.
    -- https://wowhead.com/beta/spell=20707
    soulstone = {
        id = 20707,
        duration = 900,
        max_stack = 1
    },
    -- $@auracaster's subject.
    -- https://wowhead.com/beta/spell=1098
    subjugate_demon = {
        id = 1098,
        duration = 300,
        mechanic = "charm",
        type = "Magic",
        max_stack = 1
    },
    --
    -- https://wowhead.com/beta/spell=101508
    the_codex_of_xerrath = {
        id = 101508,
        duration = 3600,
        max_stack = 1
    },
    tormented_souls = {
        duration = 3600,
        max_stack = 20,
        generate = function( t )
            local n = GetSpellCastCount( 386256 )

            if n > 0 then
                t.applied = query_time
                t.duration = 3600
                t.expires = t.applied + 3600
                t.count = n
                t.caster = "player"
                return
            end

            t.applied = 0
            t.duration = 0
            t.expires = 0
            t.count = 0
            t.caster = "nobody"
        end,
        copy = "tormented_soul"
    },
    -- Damage dealt by your demons increased by $w1%.
    -- https://wowhead.com/beta/spell=339784
    tyrants_soul = {
        id = 339784,
        duration = 15,
        max_stack = 1
    },
    -- Dealing $w1 Shadowflame damage every $t1 sec for $d.
    -- https://wowhead.com/beta/spell=273526
    umbral_blaze = {
        id = 273526,
        duration = 6,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    unending_breath = {
        id = 5697,
        duration = 600,
        max_stack = 1,
    },
    -- Damage taken reduced by $w3%  Immune to interrupt and silence effects.
    -- https://wowhead.com/beta/spell=104773
    unending_resolve = {
        id = 104773,
        duration = 8,
        max_stack = 1
    },
    -- Suffering $w2 Shadow damage every $t2 sec. If dispelled, will cause ${$w2*$s1/100} damage to the dispeller and silence them for $196364d.
    -- https://wowhead.com/beta/spell=316099
    unstable_affliction = {
        id = 316099,
        duration = 16,
        type = "Magic",
        max_stack = 1
    },
    -- Suffering $w1 Shadow damage every $t1 sec.
    -- https://wowhead.com/beta/spell=386931
    vile_taint = {
        id = 386931,
        duration = 10,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Damage done increased by $w1%.
    -- https://wowhead.com/beta/spell=386865
    wrathful_minion = {
        id = 386865,
        duration = 8,
        max_stack = 1,
        generate = function( t )
            local name, _, count, _, duration, expires, caster = FindUnitBuffByID( "pet", 386865 )

            if name then
                t.name = name
                t.count = count
                t.expires = expires
                t.applied = expires - duration
                t.caster = caster
                return
            end

            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end,
    },
    -- Suffering $w1 Shadowflame damage every $t1 sec.$?a339892[ ; Damage taken by Chaos Bolt and Incinerate increased by $w2%.][]
    wither = {
        id = 445474,
        duration = function() return ( 18.0 + 3 * talent.scalding_flames.rank ) * ( 1 - 0.15 * talent.hatefury_rituals.rank ) end,
        tick_time = 3.0,
        pandemic = true,
        max_stack = 8,
    },

    -- Azerite Powers
    chaos_shards = {
        id = 287660,
        duration = 2,
        max_stack = 1
    },

    -- Conduit
    combusting_engine = {
        id = 339986,
        duration = 30,
        max_stack = 1
    },

    -- Legendary
    odr_shawl_of_the_ymirjar = {
        id = 337164,
        duration = function () return class.auras.havoc.duration end,
        max_stack = 1
    },
} )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237700, 237698, 237703, 237701, 237699 },
        auras = {
            -- Diabolist
            demonic_oculus = {
                id = 1238810,
                duration = 60,
                max_stack = 3
            },
            demonic_intelligence= {
                id = 1239569,
                duration = 10,
                max_stack = 3
            },
            -- Hellcaller
            maintained_withering = {
                id = 1239577,
                duration = 8,
                max_stack = 1
            }
        }
    },
    tww2 = {
        items = { 229325, 229323, 229328, 229326, 229324 },
        auras = {
            jackpot = {
                id = 1217798,
                duration = 10,
                max_stack = 1
            }
        }
    },
    -- Dragonflight
    tier31 = {
        items = { 207270, 207271, 207272, 207273, 207275 },
        auras = {
            searing_bolt = {
                id = 423886,
                duration = 10,
                max_stack = 1
            }
        }
    },
    tier30 = {
        items = { 202534, 202533, 202532, 202536, 202531 },
        auras = {
            umbrafire_embers = {
                id = 409652,
                duration = 13,
                max_stack = 8
            }
        }
    },
    tier29 = {
        items = { 200336, 200338, 200333, 200335, 200337, 217212, 217214, 217215, 217211, 217213 },
        auras = {
            chaos_maelstrom = {
                id = 394679,
                duration = 10,
                max_stack = 1
            }
        }
    }
} )

spec:RegisterHook( "runHandler", function( a )
    if talent.rolling_havoc.enabled and havoc_active and not debuff.havoc.up and action[ a ].startsCombat then
        addStack( "rolling_havoc" )
    end
end )

spec:RegisterHook( "spend", function( amt, resource )
    if resource == "soul_shards" then
        if amt > 0 then
            if legendary.wilfreds_sigil_of_superior_summoning.enabled then reduceCooldown( "summon_infernal", amt * 1.5 ) end

            local ArtConsumed = false

            if buff.art_overlord.up then
                summon_demon( "overlord", 2 )
                removeBuff( "art_overlord" )
                ArtConsumed = true
            end

            if buff.art_mother.up then
                summon_demon( "mother_of_chaos", 6 )
                removeBuff( "art_mother" )
                if talent.secrets_of_the_coven.enabled then applyBuff( "infernal_bolt" ) end
                ArtConsumed = true
            end

            if buff.art_pit_lord.up then
                summon_demon( "pit_lord", 5 )
                removeBuff( "art_pit_lord" )
                if talent.ruination.enabled then applyBuff( "ruination" ) end
                ArtConsumed = true
            end

            if ArtConsumed and set_bonus.tww3 >= 2 then
                local oculi = buff.demonic_oculus.stack or 0
                removeBuff( "demonic_oculus" )
                if set_bonus.tww3 >= 4 then
                    addStack( "demonic_intelligence", oculi )
                end
            end

            if talent.diabolic_ritual.enabled then
                if buff.diabolic_ritual.down then applyBuff( "diabolic_ritual" )
                else
                    if buff.ritual_overlord.up then buff.ritual_overlord.expires = buff.ritual_overlord.expires - amt; if buff.ritual_overlord.down then applyBuff( "art_overlord" ) end end
                    if buff.ritual_mother.up then buff.ritual_mother.expires = buff.ritual_mother.expires - amt; if buff.ritual_mother.down then applyBuff( "art_mother" ) end end
                    if buff.ritual_pit_lord.up then buff.ritual_pit_lord.expires = buff.ritual_pit_lord.expires - amt; if buff.ritual_pit_lord.down then applyBuff( "art_pit_lord" ) end end
                end
            end

            if talent.grand_warlocks_design.enabled then reduceCooldown( "summon_infernal", amt * 1.5 ) end
            if talent.power_overwhelming.enabled then addStack( "power_overwhelming", ( buff.power_overwhelming.up and buff.power_overwhelming.remains or nil ), amt ) end
            if talent.ritual_of_ruin.enabled then
                addStack( "impending_ruin", nil, amt )
                if buff.impending_ruin.stack > 15 - ceil( 2.5 * talent.master_ritualist.rank ) then
                    applyBuff( "ritual_of_ruin" )
                    removeBuff( "impending_ruin" )
                end
            end
        elseif amt < 0 and floor( soul_shard ) < floor( soul_shard + amt ) then
            if talent.demonic_inspiration.enabled then applyBuff( "demonic_inspiration" ) end
            if talent.wrathful_minion.enabled then applyBuff( "wrathful_minion" ) end
        end
    end
end )

spec:RegisterHook( "advance_end", function( time )
    if buff.art_mother.expires > query_time - time and buff.art_mother.down then
        summon_demon( "mother_of_chaos", 6 )
        removeBuff( "art_mother" )
        if talent.secrets_of_the_coven.enabled then applyBuff( "infernal_bolt" ) end
    end
end )

local lastTarget
local lastMayhem = 0

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID == GUID then
        if subtype == "SPELL_CAST_SUCCESS" and destGUID ~= nil and destGUID ~= "" then
            lastTarget = destGUID
        elseif state.talent.mayhem.enabled and subtype == "SPELL_AURA_APPLIED" and spellID == 80240 then
            lastMayhem = GetTime()
        end
    end
end, false )

spec:RegisterStateExpr( "last_havoc", function ()
    if talent.mayhem.enabled then return lastMayhem end
    return pvptalent.bane_of_havoc.enabled and action.bane_of_havoc.lastCast or action.havoc.lastCast
end )

spec:RegisterStateExpr( "havoc_remains", function ()
    return buff.active_havoc.remains
end )

spec:RegisterStateExpr( "havoc_active", function ()
    return buff.active_havoc.up
end )

spec:RegisterStateExpr( "demonic_art", function ()
    return buff.demonic_art_overlord.up or buff.demonic_art_mother.up or buff.demonic_art_pit_lord.up
end )

spec:RegisterStateExpr( "diabolic_ritual", function ()
    return buff.ritual_overlord.up or buff.ritual_mother.up or buff.ritual_pit_lord.up
end )

spec:RegisterHook( "TimeToReady", function( wait, action )
    local ability = action and class.abilities[ action ]

    if ability and ability.spend and ability.spendType == "soul_shards" and ability.spend > soul_shard then
        wait = 3600
    end

    return wait
end )

spec:RegisterStateExpr( "soul_shard", function () return soul_shards.current end )

local SUMMON_DEMON_TEXT

spec:RegisterHook( "reset_precast", function ()
    last_havoc = nil
    soul_shards.actual = nil

    class.abilities.summon_pet = class.abilities[ settings.default_pet ]

    if not SUMMON_DEMON_TEXT then
        local summon_demon = GetSpellInfo( 180284 )
        SUMMON_DEMON_TEXT = summon_demon and summon_demon.name or "Summon Demon"
        class.abilityList.summon_pet = "|T136082:0|t |cff00ccff[" .. SUMMON_DEMON_TEXT .. "]|r"
    end

    for i = 1, 5 do
        local up, _, start, duration, id = GetTotemInfo( i )

        if up and id == 136219 then
            summonPet( "infernal", start + duration - now )
            break
        end
    end

    if pvptalent.bane_of_havoc.enabled then
        class.abilities.havoc = class.abilities.bane_of_havoc
    else
        class.abilities.havoc = class.abilities.real_havoc
    end

    if IsActiveSpell( 433891 ) then
        applyBuff( "infernal_bolt" )
    end
end )

spec:RegisterCycle( function ()
    if active_enemies == 1 then return end

    -- For Havoc, we want to cast it on a different target.
    if this_action == "havoc" and class.abilities.havoc.key == "havoc" then return "cycle" end

    if ( debuff.havoc.up or FindUnitDebuffByID( "target", 80240, "PLAYER" ) ) and not legendary.odr_shawl_of_the_ymirjar.enabled then
        return "cycle"
    end
end )

-- Fel Imp          58959
spec:RegisterPet( "imp",
    function() return Glyphed( 112866 ) and 58959 or 416 end,
    "summon_imp",
    3600 )

-- Voidlord         58960
spec:RegisterPet( "voidwalker",
    function() return Glyphed( 112867 ) and 58960 or 1860 end,
    "summon_voidwalker",
    3600 )

-- Observer         58964
spec:RegisterPet( "felhunter",
    function() return Glyphed( 112869 ) and 58964 or 417 end,
    "summon_felhunter",
    3600 )

-- Fel Succubus     120526
-- Shadow Succubus  120527
-- Shivarra         58963
spec:RegisterPet( "sayaad",
    function()
        if Glyphed( 240263 ) then return 120526
        elseif Glyphed( 240266 ) then return 120527
        elseif Glyphed( 112868 ) then return 58963
        elseif Glyphed( 365349 ) then return 184600
        end
        return 1863
    end,
    "summon_sayaad",
    3600,
    "incubus", "succubus" )

-- Wrathguard       58965
spec:RegisterPet( "felguard",
    function() return Glyphed( 112870 ) and 58965 or 17252 end,
    "summon_felguard",
    3600 )

-- Abilities
spec:RegisterAbilities( {
    -- Calls forth a cataclysm at the target location, dealing $s1 Shadowflame damage to all enemies within $A1 yards and afflicting them with $?a445465[Wither][Immolate].
    cataclysm = {
        id = 152108,
        cast = 1.6, --self
        cooldown = 30,
        gcd = "spell",
        school = "shadowflame",
        terrain = true,
        spend = 0.01,
        spendType = "mana",

        --talent = "cataclysm", temporary
        startsCombat = true,

        usable = function()
            return settings.cataclysm_ttd == 0 or fight_remains >= settings.cataclysm_ttd, strformat( "cataclysm_ttd[%d] < fight_remains[%d]", settings.cataclysm_ttd, fight_remains )
        end,

        handler = function ()
            local applies = talent.wither.enabled and "wither" or "immolate"
            applyDebuff( "target", applies )
            active_dot[ applies ] = max( active_dot[ applies ], true_active_enemies )
            removeDebuff( "target", "combusting_engine" )
        end,
    },

    -- Launches $s1 bolts of felfire over $d at random targets afflicted by your $?a445465[Wither][Immolate] within $196449A1 yds. Each bolt deals $196448s1 Fire damage to the target and $196448s2 Fire damage to nearby enemies.
    channel_demonfire = {
        id = 196447,
        cast = function() return class.auras.channel_demonfire.duration end,
        channeled = true,
        cooldown = 25,
        gcd = "spell",
        school = "fire",

        spend = 0.015,
        spendType = "mana",

        talent = "channel_demonfire",
        startsCombat = true,

        usable = function () return active_dot[ talent.wither.enabled and "wither" or "immolate" ] > 0 end,

        start = function()
            removeBuff( "umbrafire_embers" )
        end

        -- With raging_demonfire, this will extend Immolates but it's not worth modeling for the addon ( 0.2s * 17-20 ticks ).
    },

    -- Talent: Unleashes a devastating blast of chaos, dealing a critical strike for 8,867 Chaos damage. Damage is further increased by your critical strike chance.
    chaos_bolt = {
        id = 116858,
        cast = function () return ( 3 - 0.5 * talent.improved_chaos_bolt.rank )
            * ( buff.ritual_of_ruin.up and 0.5 or 1 )
            * ( buff.backdraft.up and 0.7 or 1 )
            * haste
        end,
        cooldown = 0,
        gcd = "spell",
        school = "chromatic",

        spend = function ()
            if buff.ritual_of_ruin.up then return 0 end
            return 2
        end,
        spendType = "soul_shards",

        startsCombat = true,
        nobuff = "ruination",
        cycle = function () return talent.eradication.enabled and "eradication" or nil end,

        texture = 236291,
        velocity = 16,

        handler = function ()
            removeStack( "crashing_chaos" )
            if buff.ritual_of_ruin.up then
                removeBuff( "ritual_of_ruin" )
                if talent.avatar_of_destruction.enabled then applyBuff( "blasphemy" ) end
            else
                removeStack( "backdraft" )
            end
            if debuff.wither.up then
                applyDebuff( "target", "wither", nil, debuff.wither.stack + 1 + ( buff.malevolence.up and 1 or 0 ) )
            end
            if talent.burn_to_ashes.enabled then
                addStack( "burn_to_ashes", nil, 2 )
            end
            if talent.eradication.enabled then
                applyDebuff( "target", "eradication" )
                active_dot.eradication = max( active_dot.eradication, active_dot.bane_of_havoc )
            end
            if talent.internal_combustion.enabled and debuff.immolate.up then
                if debuff.immolate.remains <= 5 then removeDebuff( "target", "immolate" )
                else debuff.immolate.expires = debuff.immolate.expires - 5 end
            end
            if set_bonus.tww3_diabolist >= 2 then
                addStack( "demonic_oculus" )
            end
        end,

        impact = function() end,

        bind = "ruination"
    },

    --[[ Commands your demon to perform its most powerful ability. This spell will transform based on your active pet. Felhunter: Devour Magic Voidwalker: Shadow Bulwark Incubus/Succubus: Seduction Imp: Singe Magic
    command_demon = {
        id = 119898,
        cast = 0,
        cooldown = 0,
        gcd = "off",
        school = "physical",

        startsCombat = false,

        handler = function ()
        end,
    }, ]]

    -- Talent: Triggers an explosion on the target, dealing 3,389 Fire damage. Reduces the cast time of your next Incinerate or Chaos Bolt by 30% for 10 sec. Generates 5 Soul Shard Fragments.
    conflagrate = {
        id = 17962,
        cast = 0,
        charges = function() return talent.improved_conflagrate.enabled and 3 or 2 end,
        cooldown = function() return talent.explosive_potential.enabled and 11 or 13 end,
        recharge = function() return talent.explosive_potential.enabled and 11 or 13 end,
        gcd = "spell",
        school = "fire",

        spend = 0.01,
        spendType = "mana",

        talent = "conflagrate",
        startsCombat = true,
        cycle = function () return talent.roaring_blaze.enabled and "conflagrate" or nil end,

        handler = function ()
            gain( 0.5, "soul_shards" )
            addStack( "backdraft" )

            removeBuff( "conflagration_of_chaos_cf" )

            if talent.decimation.enabled and target.health_pct < 50 then reduceCooldown( "soulfire", 5 ) end
            if talent.roaring_blaze.enabled then
                applyDebuff( "target", "conflagrate" )
                active_dot.conflagrate = max( active_dot.conflagrate, active_dot.bane_of_havoc )
            end
            if conduit.combusting_engine.enabled then
                applyDebuff( "target", "combusting_engine" )
            end
        end,
    },

    -- Corrupts the target, causing $s3 Shadow damage and $?a196103[$146739s1 Shadow damage every $146739t1 sec.][an additional $146739o1 Shadow damage over $146739d.]
    corruption = {
        id = 172,
        cast = 0,
        cooldown = 0.0,
        gcd = "spell",

        spend = 0.010,
        spendType = 'mana',

        startsCombat = true,

        handler = function()
            applyDebuff( "target", "corruption" )
        end,

        -- Effects:
        -- #0: { 'type': TRIGGER_SPELL, 'subtype': NONE, 'trigger_spell': 146739, 'target': TARGET_UNIT_TARGET_ENEMY, }
        -- #1: { 'type': DUMMY, 'subtype': NONE, }
        -- #2: { 'type': SCHOOL_DAMAGE, 'subtype': NONE, 'sp_bonus': 0.138, 'pvp_multiplier': 1.25, 'variance': 0.05, 'target': TARGET_UNIT_TARGET_ENEMY, }

        -- Affected by:
        -- destruction_warlock[137046] #12: { 'type': APPLY_AURA, 'subtype': OVERRIDE_ACTIONBAR_SPELLS, 'spell': 348, 'target': TARGET_UNIT_CASTER, }
        -- mark_of_perotharn[440045] #0: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 10.0, 'target': TARGET_UNIT_CASTER, 'modifies': SHOULD_NEVER_SEE_15, }
        -- xalans_cruelty[440040] #0: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 10.0, 'target': TARGET_UNIT_CASTER, 'modifies': CRIT_CHANCE, }
        -- xalans_cruelty[440040] #2: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 2.0, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- xalans_cruelty[440040] #3: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 2.0, 'target': TARGET_UNIT_CASTER, 'modifies': PERIODIC_DAMAGE_HEALING, }
        -- absolute_corruption[196103] #1: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 15.0, 'target': TARGET_UNIT_CASTER, 'modifies': PERIODIC_DAMAGE_HEALING, }
        -- wither[445465] #0: { 'type': APPLY_AURA, 'subtype': OVERRIDE_ACTIONBAR_SPELLS, 'spell': 445468, 'value1': 3, 'target': TARGET_UNIT_CASTER, }
    },

    --[[ Creates a Healthstone that can be consumed to restore 25% health. When you use a Healthstone, gain 7% Leech for 20 sec.
    create_healthstone = {
        id = 6201,
        cast = 3,
        cooldown = 0,
        gcd = "spell",
        school = "shadow",

        spend = 0.02,
        spendType = "mana",

        startsCombat = false,

        handler = function ()
        end,
    }, ]]


    -- Talent: Rips a hole in time and space, opening a random portal that damages your target: Shadowy Tear Deals 15,954 Shadow damage over 14 sec. Unstable Tear Deals 13,709 Chaos damage over 6 sec. Chaos Tear Fires a Chaos Bolt, dealing 4,524 Chaos damage. This Chaos Bolt always critically strikes and your critical strike chance increases its damage. Generates 3 Soul Shard Fragments.
    dimensional_rift = {
        id = 387976,
        cast = 0,
        charges = 3,
        cooldown = 45,
        recharge = 45,
        gcd = "spell",
        school = "chaos",

        spend = -0.3,
        spendType = "soul_shards",

        talent = "dimensional_rift",
        startsCombat = true,
    },

    --[[ Summons an Eye of Kilrogg and binds your vision to it. The eye is stealthed and moves quickly but is very fragile.
    eye_of_kilrogg = {
        id = 126,
        cast = 2,
        cooldown = 0,
        gcd = "spell",
        school = "shadow",

        spend = 0.03,
        spendType = "mana",

        startsCombat = false,

        handler = function ()
            applyBuff( "eye_of_kilrogg" )
        end,
    }, ]]


    -- Talent: Sacrifices your demon pet for power, gaining its command demon ability, and causing your spells to sometimes also deal 1,678 additional Shadow damage. Lasts 1 |4hour:hrs; or until you summon a demon pet.
    grimoire_of_sacrifice = {
        id = 108503,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "shadow",

        talent = "grimoire_of_sacrifice",
        startsCombat = true,
        essential = true,

        nobuff = "grimoire_of_sacrifice",

        usable = function () return pet.active, "requires a pet to sacrifice" end,
        handler = function ()
            if pet.felhunter.alive then dismissPet( "felhunter" )
            elseif pet.imp.alive then dismissPet( "imp" )
            elseif pet.succubus.alive then dismissPet( "succubus" )
            elseif pet.voidawalker.alive then dismissPet( "voidwalker" ) end
            applyBuff( "grimoire_of_sacrifice" )
        end,
    },

    -- Talent: Marks a target with Havoc for 15 sec, causing your single target spells to also strike the Havoc victim for 60% of normal initial damage.
    havoc = {
        id = 80240,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "shadow",

        spend = 0.02,
        spendType = "mana",

        talent = "havoc",
        startsCombat = true,
        indicator = function () return active_enemies > 1 and ( lastTarget == "lastTarget" or target.unit == lastTarget ) and "cycle" or nil end,
        cycle = "havoc",

        bind = "bane_of_havoc",

        usable = function()
            if pvptalent.bane_of_havoc.enabled then return false, "pvptalent bane_of_havoc enabled" end
            return talent.cry_havoc.enabled or active_enemies > 1, "requires cry_havoc or multiple targets"
        end,

        handler = function ()
            if class.abilities.havoc.indicator == "cycle" then
                active_dot.havoc = active_dot.havoc + 1
                if legendary.odr_shawl_of_the_ymirjar.enabled then active_dot.odr_shawl_of_the_ymirjar = 1 end
            else
                applyDebuff( "target", "havoc" )
                if legendary.odr_shawl_of_the_ymirjar.enabled then applyDebuff( "target", "odr_shawl_of_the_ymirjar" ) end
            end
            applyBuff( "active_havoc" )
        end,

        copy = "real_havoc",
    },


    bane_of_havoc = {
        id = 200546,
        cast = 0,
        cooldown = 45,
        gcd = "spell",

        startsCombat = true,
        cycle = "DoNotCycle",

        bind = "havoc",

        pvptalent = "bane_of_havoc",
        usable = function () return active_enemies > 1, "requires multiple targets" end,

        handler = function ()
            applyDebuff( "target", "bane_of_havoc" )
            active_dot.bane_of_havoc = active_enemies
            applyBuff( "active_havoc" )
        end,
    },

    -- Talent: Let loose a terrifying howl, causing 5 enemies within 10 yds to flee in fear, disorienting them for 20 sec. Damage may cancel the effect.
    howl_of_terror = {
        id = 5484,
        cast = 0,
        cooldown = 40,
        gcd = "spell",
        school = "shadow",

        talent = "howl_of_terror",
        startsCombat = false,

        handler = function ()
            applyDebuff( "target", "howl_of_terror" )
        end,
    },

    -- Burns the enemy, causing 1,559 Fire damage immediately and an additional 9,826 Fire damage over 24 sec. Periodic damage generates 1 Soul Shard Fragment and has a 50% chance to generate an additional 1 on critical strikes.
    immolate = {
        id = 348,
        cast = 1.5,
        cooldown = 0,
        gcd = "spell",
        school = "fire",

        spend = 0.015,
        spendType = "mana",

        startsCombat = true,
        cycle = function () return not debuff.immolate.refreshable and "immolate" or nil end,
        notalent = function() return state.spec.destruction and talent.wither.enabled and "wither" or nil end,

        usable = function()
            return settings.low_ttd_dot == 0 or fight_remains >= settings.low_ttd_dot, strformat( "low_ttd_dot[%d] < fight_remains[%d]", settings.low_ttd_dot, fight_remains )
        end,

        handler = function ()
            applyDebuff( "target", "immolate" )
            active_dot.immolate = max( active_dot.immolate, active_dot.bane_of_havoc )
            removeDebuff( "target", "combusting_engine" )
            if talent.flashpoint.enabled and target.health_pct > 80 then addStack( "flashpoint" ) end
        end,

        bind = function() return state.spec.destruction and talent.wither.enabled and "wither" or nil end,
    },

    -- Draws fire toward the enemy, dealing 3,794 Fire damage. Generates 2 Soul Shard Fragments and an additional 1 on critical strikes.
    incinerate = {
        id = 29722,
        cast = function ()
            if buff.chaotic_inferno.up then return 0 end
            return 2 * haste
                * ( buff.backdraft.up and 0.7 or 1 )
        end,
        cooldown = 0,
        gcd = "spell",
        school = "fire",

        spend = 0.015,
        spendType = "mana",

        startsCombat = true,
        nobuff = "infernal_bolt",

        handler = function ()
            removeBuff( "chaotic_inferno" )
            removeStack( "backdraft" )
            removeStack( "burn_to_ashes" )
            removeStack( "decimating_bolt" )

            if talent.decimation.enabled and target.health_pct < 50 then reduceCooldown( "soulfire", 5 ) end

            -- Using true_active_enemies for resource predictions' sake.
            gain( ( 0.2 + ( 0.125 * ( true_active_enemies - 1 ) * talent.fire_and_brimstone.rank ) )
                * ( legendary.embers_of_the_diabolic_raiment.enabled and 2 or 1 )
                * ( talent.diabolic_embers.enabled and 2 or 1 ), "soul_shards" )
        end,

        bind = "infernal_bolt"
    },

    infernal_bolt = {
        id = 434506,
        cast = function ()
            if buff.chaotic_inferno.up then return 0 end
            return 2 * haste
                * ( buff.backdraft.up and 0.7 or 1 )
        end,
        cooldown = 0,
        gcd = "spell",
        school = "fire",

        startsCombat = true,
        buff = "infernal_bolt",

        handler = function ()
            removeBuff( "infernal_bolt" )
            removeBuff( "chaotic_inferno" )
            removeStack( "backdraft" )
            removeStack( "burn_to_ashes" )
            removeStack( "decimating_bolt" )

            if talent.decimation.enabled and target.health_pct < 50 then reduceCooldown( "soulfire", 5 ) end

            -- Using true_active_enemies for resource predictions' sake.
            gain( 3, "soul_shards" )
        end,

        bind = "incinerate"
    },

    -- [430014] Dark magic erupts from you and corrupts your soul for $442726d, causing enemies suffering from your Wither to take $446285s1 Shadowflame damage and increase its stack count by $s1.; While corrupted your Haste is increased by $442726s1% and spending Soul Shards on damaging spells grants $s2 additional stack of Wither.
    malevolence = {
        id = 442726,
        cast = 0.0,
        cooldown = 60.0,
        gcd = "spell",

        spend = 0.010,
        spendType = 'mana',

        talent = "malevolence",
        startsCombat = true,

        handler = function ()
            applyBuff( "malevolence")
            if debuff.wither.up then applyDebuff( "target", "wither", debuff.wither.remains, debuff.wither.stack + 6 + ( set_bonus.tww3 >= 2 and 2 or 0 ) ) end
            if set_bonus.tww3 >= 4 then
                addStack( "backdraft", 2 )
                applyBuff( "maintained_withering" )
            end

        end,
    },

    -- Calls down a rain of hellfire, dealing ${$42223m1*8} Fire damage over $d to enemies in the area.
    rain_of_fire = {
        id = function() return talent.rain_of_fire_targeted.enabled and 1214467 or 5740 end,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "fire",

        spend = function ()
            if buff.ritual_of_ruin.up then return 0 end
            return 3
        end,
        spendType = "soul_shards",

        terrain = true,
        usable = function() return raid_event.adds.remains > 4 end,
        talent = "rain_of_fire",
        startsCombat = true,

        handler = function ()
            removeStack( "crashing_chaos" )
            if buff.ritual_of_ruin.up then
                removeBuff( "ritual_of_ruin" )
                if talent.avatar_of_destruction.enabled then applyBuff( "blasphemy" ) end
            end
            if talent.burn_to_ashes.enabled then
                addStack( "burn_to_ashes", nil, 2 )
            end
            if set_bonus.tww3_diabolist >= 2 then
                addStack( "demonic_oculus" )
            end
        end,

        copy = { 5740, 1214467 }
    },

    --[[ Begins a ritual that sacrifices a random participant to summon a doomguard. Requires the caster and 4 additional party members to complete the ritual.
    ritual_of_doom = {
        id = 342601,
        cast = 0,
        cooldown = 3600,
        gcd = "spell",
        school = "shadow",

        spend = 1,
        spendType = "soul_shards",

        startsCombat = false,

        toggle = "cooldowns",

        handler = function ()
        end,
    },

    -- Begins a ritual to create a summoning portal, requiring the caster and 2 allies to complete. This portal can be used to summon party and raid members.
    ritual_of_summoning = {
        id = 698,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        school = "shadow",

        spend = 0.05,
        spendType = "mana",

        startsCombat = false,

        toggle = "cooldowns",

        handler = function ()
        end,
    }, ]]

    ruination = {
        id = 434635,
        known = 116858,
        cast = function () return 1.5
            * ( buff.ritual_of_ruin.up and 0.5 or 1 )
            * ( buff.backdraft.up and 0.7 or 1 )
            * haste
        end,
        cooldown = 0,
        gcd = "spell",
        school = "chromatic",

        startsCombat = true,
        buff = "ruination",
        cycle = function () return talent.eradication.enabled and "eradication" or nil end,

        texture = 135800,
        velocity = 16,

        handler = function ()
            removeStack( "crashing_chaos" )
            if buff.ritual_of_ruin.up then
                removeBuff( "ritual_of_ruin" )
                if talent.avatar_of_destruction.enabled then applyBuff( "blasphemy" ) end
            else
                removeStack( "backdraft" )
            end
            if debuff.wither.up then
                applyDebuff( "target", "wither", nil, debuff.wither.stack + 1 + ( buff.malevolence.up and 1 or 0 ) )
            end
            if talent.burn_to_ashes.enabled then
                addStack( "burn_to_ashes", nil, 2 )
            end
            if talent.eradication.enabled then
                applyDebuff( "target", "eradication" )
                active_dot.eradication = max( active_dot.eradication, active_dot.bane_of_havoc )
            end
            if talent.internal_combustion.enabled and debuff.immolate.up then
                if debuff.immolate.remains <= 5 then removeDebuff( "target", "immolate" )
                else debuff.immolate.expires = debuff.immolate.expires - 5 end
            end
            -- summon_demon( "diabolic_imp", 1 )
            removeBuff( "ruination" )
        end,

        impact = function() end,

        bind = "chaos_bolt"
    },

    -- Conjure a Shadow Rift at the target location lasting $d. Enemy players within the rift when it expires are teleported to your Demonic Circle.; Must be within $s2 yds of your Demonic Circle to cast.
    shadow_rift = {
        id = 353294,
        cast = 0.0,
        cooldown = 60.0,
        gcd = "spell",

        spend = 0.010,
        spendType = 'mana',

        startsCombat = false,
        pvptalent = "shadow_rift",
    },

    -- Blasts a target for $s1 Shadowflame damage, gaining $s3% critical strike chance on targets that have $s4% or less health.; Restores ${$245731s1/10} Soul Shard and refunds a charge if the target dies within $d.
    shadowburn = {
        id = 17877,
        cast = 0,
        charges = 2,
        cooldown = 12,
        recharge = 12,
        gcd = "spell",
        school = "shadowflame",

        spend = 1,
        spendType = "soul_shards",

        talent = "shadowburn",
        startsCombat = true,
        cycle = "shadowburn",
        nodebuff = "shadowburn",

        handler = function ()
            -- gain( 0.3, "soul_shards" )
            applyDebuff( "target", "shadowburn" )
            active_dot.shadowburn = max( active_dot.shadowburn, active_dot.bane_of_havoc )

            removeBuff( "conflagration_of_chaos_sb" )

            if talent.burn_to_ashes.enabled then
                addStack( "burn_to_ashes" )
            end
            if talent.eradication.enabled then
                applyDebuff( "target", "eradication" )
                active_dot.eradication = max( active_dot.eradication, active_dot.bane_of_havoc )
            end
            if set_bonus.tww3_diabolist >= 2 then
                addStack( "demonic_oculus" )
            end
        end,
    },

    -- Burns the enemy's soul, dealing $s1 Fire damage and applying $?a445465[Wither][Immolate].; Generates ${$281490s1/10} Soul Shard.
    soul_fire = {
        id = 6353,
        cast = function () return 4 * ( buff.decimation.up and 0.2 or 1 ) * haste end,
        cooldown = 45,
        gcd = "spell",
        school = "fire",

        spend = 0.02,
        spendType = "mana",

        talent = "soul_fire",
        startsCombat = true,
        aura = function() return talent.wither.enabled and "wither" or "immolate" end,

        handler = function ()
            removeBuff( "decimation" )
            gain( 1, "soul_shards" )
            applyDebuff( "target", talent.wither.enabled and "wither" or "immolate" ) -- Add stack?
        end,
    },

    -- Talent: Summons an Infernal from the Twisting Nether, impacting for 1,582 Fire damage and stunning all enemies in the area for 2 sec. The Infernal will serve you for 30 sec, dealing 1,160 damage to all nearby enemies every 1.6 sec and generating 1 Soul Shard Fragment every 0.5 sec.
    summon_infernal = {
        id = 1122,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        school = "shadow",

        spend = 0.02,
        spendType = "mana",

        talent = "summon_infernal",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            summonPet( "infernal", 30 )
            if talent.rain_of_chaos.enabled then applyBuff( "rain_of_chaos" ) end
            if talent.crashing_chaos.enabled then applyBuff( "crashing_chaos", nil, 8 ) end
            if set_bonus.tww2 >= 2 then applyBuff( "jackpot" ) end
        end,
    },

    -- Bestows a vile malediction upon the target, burning the sinew and muscle of its host, dealing $s1 Shadowflame damage immediately and an additional $445474o1 Shadowflame damage over $445474d.$?s137046[; Periodic damage generates 1 Soul Shard Fragment and has a $s2% chance to generate an additional 1 on critical strikes.; Replaces Immolate.][; Replaces Corruption.]
    wither = {
        id = 445468,
        known = function() return talent.wither.enabled end,
        cast = 0.0,
        cooldown = 0.0,
        gcd = "spell",
        school = "fire",

        spend = 0.015,
        spendType = 'mana',

        talent = "wither",
        startsCombat = true,

        usable = function()
            return settings.low_ttd_dot == 0 or fight_remains >= settings.low_ttd_dot, strformat( "low_ttd_dot[%d] < fight_remains[%d]", settings.low_ttd_dot, fight_remains )
        end,

        handler = function ()
            applyDebuff( "target", "wither" )
        end,

        bind = "immolate"
    },
} )

spec:RegisterRanges( "corruption", "subjugate_demon", "mortal_coil" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = true,
    nameplateRange = 20,
    rangeFilter = false,


    damage = true,
    damageDots = false,
    damageExpiration = 6,

    potion = "tempered_potion",

    package = "毁灭Simc",
} )

spec:RegisterSetting( "default_pet", "summon_sayaad", {
    name = "|T136082:0|t 首选恶魔",
    desc = "如果你没有激活的宠物，指定应该召唤哪个恶魔。",
    type = "select",
    values = function()
        return {
            summon_felhunter = class.abilityList.summon_felhunter,
            summon_sayaad = class.abilityList.summon_sayaad,
            summon_imp = class.abilityList.summon_imp,
            summon_voidwalker = class.abilityList.summon_voidwalker,
        }
    end,
    width = "normal"
} )

spec:RegisterSetting( "cleave_apl", false, {
    name = "\n\n毁灭术士能够使用漏斗伤害机制。前往 |cFFFFD100快捷切换|r 了解如何开启和关闭此机制。" ..
        "如果启用漏斗伤害，默认优先级会建议在AOE状态时，使用混乱箭对重要目标造成更多伤害。\n\n",
    desc = "",
    type = "description",
    fontSize = "medium",
    width = "full",
} )

--[[
spec:RegisterVariable( "cleave_apl", function()
    if settings.cleave_apl ~= nil then return settings.cleave_apl end
    return false
end )
--]]

--[[ Retired 2023-02-20.
spec:RegisterSetting( "fixed_aoe_3_plus", false, {
    name = "需要3个以上目标才AOE",
    desc = function()
        return "如果勾选，默认的优先级只有在你面对3个以上目标时，才会进入AOE的指令列表（包括|T" .. ( GetSpellTexture( 5740 ) ) .. ":0|t火焰之雨）。\n\n" ..
        "在多目标战斗的模拟中，该设置会明显导致DPS损失。不过在实际战斗场景中，特别是当你与两个移动的目标战斗时，它们不会一直站在你的火雨里。"
    end,
    type = "toggle",
    width = "full",
} ) ]]

spec:RegisterSetting( "havoc_macro_text", nil, {
    name = "当|T460695:0|t浩劫和|TInterface\\Addons\\Hekili\\Textures\\Cycle:0|t图标同时显示时，插件建议你在不同的目标上施放浩劫（不是切换目标）。鼠标指向宏对此很有效，下面是一个例子。",
    type = "description",
    width = "full",
    fontSize = "medium"
} )

spec:RegisterSetting( "havoc_macro", nil, {
    name = "|T460695:0|t浩劫指向宏",
    type = "input",
    width = "full",
    multiline = 2,
    get = function () return "#showtooltip\n/use [@mouseover,harm,nodead][] " .. class.abilities.havoc.name end,
    set = function () end,
} )

spec:RegisterSetting( "immolate_macro_text", nil, {
    name = function () return "当|T" .. GetSpellTexture( 348 ) .. ":0|t献祭和|TInterface\\Addons\\Hekili\\Textures\\Cycle:0|t图标同时显示时，插件建议你在不同的目标上施放献祭（不是切换目标）。鼠标指向宏对此很有效，下面是一个例子。" end,
    type = "description",
    width = "full",
    fontSize = "medium"
} )

spec:RegisterSetting( "immolate_macro", nil, {
    name = function () return "|T" .. GetSpellTexture( 348 ) .. ":0|t献祭指向宏" end,
    type = "input",
    width = "full",
    multiline = 2,
    get = function () return "#showtooltip\n/use [@mouseover,harm,nodead][] " .. class.abilities.immolate.name end,
    set = function () end,
} )

spec:RegisterSetting( "low_ttd_dot", 11, {
    name = function () return string.format( "%s: 敌人死亡时间", Hekili:GetSpellLinkWithTexture( state.talent.wither.enabled and spec.auras.wither.id or spec.auras.immolate.id ) ) end,
    type = "range",
    desc = function () return string.format( "如果设置大于0，除非你的目标 / 敌人至少还能存活设置的秒数，否则不会推荐使用 %s。", Hekili:GetSpellLinkWithTexture( state.talent.wither.enabled and spec.auras.wither.id or spec.auras.immolate.id ) ) end,
    min = 0,
    max = 21,
    step = 0.5,
    width = "full",
} )

spec:RegisterSetting( "cataclysm_ttd", 11, {
    name = function () return string.format( "%s: 敌人死亡时间", Hekili:GetSpellLinkWithTexture( spec.abilities.cataclysm.id ) ) end,
    type = "range",
    desc = function () return string.format( "如果设置大于0，除非你的目标 / 敌人至少还能存活设置的秒数，否则不会推荐使用 %s。", Hekili:GetSpellLinkWithTexture( spec.abilities.cataclysm.id ) ) end,
    min = 0,
    max = 21,
    step = 0.5,
    width = "full",
} )


spec:RegisterPack( "毁灭Simc", 20250812, [[Hekili:T3v4VXno29)w8hIZmj1tgjhN4SWXf3TahWT461dW791rJSgn2crJ0ajnoRpemy3ROTBx0dOfOafOTafBb6Hdh2R3x3Uyp0)yAsU0pT)l0hjLOiP4JKZ4zSD2Zabjowup(479iF)479i1iVrF8OtMewfp6N6p0)GHh6T)GHp2F4bpD0jvxopE0jZdJEr4zWpKfod(73(7)S)4N97ojzwe5rxMMhoHqIY8ffrWJpVQAE5h8OhDws15loDqu(ShvMmBrAyvsEwur40kY)p6rJo50fjPv)4SrNQP)9E6bhm6KWfvNNxm6eOZ(qGYjtMeZAECj05KMV3Wd3ZZ)dwo(h8Z(jlh)ZNti0YpQ5jdpeEYjxMfTC8lb2b(zGqnpg(Ztm849H)O5XJojnPSQKmIJsJdVig(PFkvggNfEAA8Kr)q4jfjvXfjHaphErEuqyuvYfXlhV7YXSFrr8SWKSYLJpE54ZIMmyw4NasWQIKOkc1oH8c5zaHcttdy)Nas)Y69aMIGsQrWl4R095ZbIfx1sMlcbMbEk5Nsxa)tuEE6K8xMnGsJbC25ONVC8blh)QxTCCvyACwfWzxEE8SbnuNqQ6UFoqJaqRd)15HftkjCY(OcIElhVZYX8(TCXSzWykjBACrwy6GfZz96o8owTf1uD54(TJRzqtVihAoy4b9(Jv69MMXeuBhMHQuRclolUAqvYS4GQ8GjjXun7HqFEjyLeWEEjr1cS5bOcPjXqVKa2lfckVOZdZldonpTI8Ypb9LpDX0PdMehLmJovduQafOShmCB1tmL8JzJWUVJGHqTH5YXpy5y)MH6Ky67eLNnnn8Scy6w7lDm8sXFsC0IkyidYc6lO3uRD4r5SPjfun4tr0GK5FXfIJ2AftswfvJeaRZC6Is6GGRCydD2FMKxnGrLw(DpQXom6yDZGwjnq3GPPjNDEfDCFK07hfctbzJp4Dho4X02qeN66e4D3N9uCUOB)llgzSWb0ru32UOKmEBuq9KSBBeUTcfcN0A5ZFoNDEiVlAFOWi(ylsZ(2MtqF4oA6eUiN0C2BRF(ZHoBK0ki2m2j9SBQy1AzFhSwUH1Kxd6WNzYrr9qUihCBLDwWPPH)IyjT10fGBXIyqja0SE4OFflImstdpSrapb8lMNcl5c9)IW0MFnBDr5NfmlNiMcYNgq1(scATVq(fXfP5ftS3Y5jvbYTKzhXhq9Be5nUYh0X9BRdJ21MjIAVHMK1TgqNhc)7PlkYg4I4TEnTA3bXfHtsIm5dzxUAvSTIk1DSm5AxXPdkcqvhYTgrTcdcgkUUtAsuDtpLGTkMAYfwvKp)8lLilPLtP22sJWdfCLXfHu5ooQqQmRXizAqXIKma0bMlFpv8DTecfcJKp5Nnuu(xapOJGOTVBECJlzpCmDBHExreQIOBR23ksDCyA9mB33fgKmysTtauWB2ozuhUxIbd99Pmkfsy7ogQcJsVSCMiVtALk0QoqPkcpJy6tXGk7OzxUNIeqwNkH57HxrxM76MlAMljW3d3bMKEllloTLZPJxvucTJxvSW7p4a(y0e6wHoNoURkGT)LQvfJ76Is)tHDupHSvy6wnwL12Lql7P6fTPvnQjvJwzn40IyG8uOJM0WhHHHNpOLEVQKOxadDbues4y42Ni4yAFUOGx0T4MbzKejK3KR4wc0ICIzjQxAze4eSMIw0q(dfNcRSIMYezFC3k28nElhYZEuqB7jpvyscD3nbrNg4xHSznbvZEgFvr4uKz(dLwvnjlkjlUb2KpUxxP5PKP5W6ftsierbLs9QIDM)l7is0ZVQ3xFCVVCUimnn)LbfWB5xfuopoBsCbZlKND(P(jZVSi)S4SKOsPNwVEOWtrr3jnHsRNw15LMCCRa1KnRcxUBqaIdHO1qjVw6zPxAgNR1qqXbHEbuFddeC8iAcUZUObWtRNeF8WkzyYOrHf0ORS8sCGDmpOvRIuugtN)tLGk1b3GYkThk26jW6lzLWpcRDvKmTsTXptSXnJqwpl3Y9X3pgBhxLn7nhKgb8F1E0PZi7drw6v)oO7iCFpzELVSNeJc89mqtEgdOP5OChhMwD(G5K4nc8Y5ZdolCE7YDtclErWCO)gqScA)9lYG1QignaqK80lIBFmm4lcZGnFclNb7fDgannQzVAehNbZ08iWHC3FPizGD0vIrhXN1sOMFRGffFWOlY7)PPirLPzgpGKywPo7g(kqZVCwizh3LbVm(urH38yY2b0TiHhBdD6BazTp)HTctHoOiEEEbGveax(cgL2NhdiLjtWCp)hpeD)(EKNvpn808Yskv00oyAEDcZugNAmBAKivWMgErCLNcUD(IS8LviVWfD21bAwkinJtK6ojWl4LjG(mnVewqh4pbW1DA78IKCGJUC5ygQcTe0pi(tIsxmrGVypzqLpSZHYGg)aSN3t65CFesBUWmJ4t5xh8UWnl2XKWCxlm0rU0x97awPvEtmkl7WhTpFwygfqET0bHcbtwWIMffBThZAwXaeMCwMMxjyrPj5CkwD(xlwD(RRvNpQzmQvNNfRoV1YQZB7z1PJHUIwD(wS68TA15V2wD(JmKu2216uSupzbyAKd9iaPHMmC9yrx9Pv8nPyKgUSSKEbznn634n18SdhSHal75XrvXtumMMxeFbr6mWt9nDEUz)rAseD3feuuNROQXDBpCvJpIQbBURr177pQg19JPk4BuveMja2hZKgDv7VGccJv6dgbV3K9dEmj7eUI2hXrJkTZm(IID2ik6wqmKsJ2G5CuNYLrTpar)Gdq2tRXArbpGiizLToQtgsQRUyWBy9pKy02txKyLJul3(MjCiTRvGDqD5iSlAqipGppqBF1oK95YdTpwr10NBGRpCWsow1X5(2cEQxtdumbE8aKWQIT(w3cfqsWZ1(BDXUg7mFtgHgf51T)MuGJhfjgANG4S4zjXLIHPQ3D5GwWNKXCqlSqNuAsXtThUyxXuQJOfRVWtRMTfU7PeJ4KzZlYViEsGyzpjOl0X7(ItICKo90tQ2IYYL4JRjTviSiVgO6VepqK4L)IkjPHQapQWgkUdDtAf4gnPmfhJqRiQdmbux8gkBHoS2t5lfiebuF9XGry9c1yYoODtk9ne52kZv1aUDS2GMsXzb4(iPToSYcwRMkVQfWiSWBykOYBP9uIIjFMqk(9fJxBnWX5XDcSSs3AVmGRYp7mW5W0feJbXA7LvAZbHZt1bHXbclVfCc6vYA01l11(WKssNFEoPbG5vjR0UlsMZO7pyrvoPYuJwo(NKtJF508ILJ)Hus9XmYaMejz8)3YXNaWGbFxIJgL9bOdAWkmK8nnK83EdjFDdj)2HKQZ36HuYu9dQUcNYlZKQsAN3MSWEXANaEpdBIQTvSKWseHo047zRp5P0LQZcItlHb4qYcF1krpDUlxrbLVDbf2Mw9VbeuA7t3euQ(6xHjj0P2Qb4xAIWju78qaCjSr6KPKzcYM)1tKHHsozscjj3q7ZQpQhPWYVK)l4bjJ0oWXn8FBNCLsMCP3oNf0bDUHxHbO)T2bOVWaSd8GBIrO)wDeQ6SDfgHuJ0xEEcW(ue3Gt9qyMuvCqsef4G4G9hrwM(Ve49FEzS44KmDQSrtYoNqKF1csRINonoI0OlZxq2Kwg0Qxgs(BIaH2eIyQg5GwJ16GBRfq1kmu93Sdv)n)q1xAOUgyzA1QDJxDpJOoO74XJbCxxJltold4qa2nyIYsgWLSAmNTiQMjfuB5wwiFA9VQQXNory4SbVsIFOsORaOmFlsOUGymiH8VviH81iHqW4r8Z7EkfW9TJKEljp)wD()ixs4s)MkP1Jk9hoGvATcuwgrkV9AiDj98mY2E6XD4rTOQ0XJDsfPnEuDJa48ONapAf8mDnLqYQlNMtwpQDXQWIyHLNyOK1y40KAp05n1GJ84tJOz1YthA7Iy0jGnDRUA1JmiNgUGuOqmAJaq1WuBUqePwab1YGN9SM9C2ZsynCjWk9fhv8cOJY(RoSro7lujEstVqhwdhm0tEEQ(MEePPp7zsmTyXSrzC8OYulroRizwEsbjvmbLHWJbmpXDdeI2Mr3hpE0A0f3hFHyRiKsbIKm3Y5o2w(RyDWbhOp8Up1sGZEi)jTbEUEJWnb4yF5ARv5K6IhAiThbw1OEPIoOmoQjg(0qbFJwgZYX97LHjvkzA4wBby3FPALeoCG)b6scaj6C6Im07pJZNZJ0FBO8etR3TiE9yT6eKyrA40L7(DrG(GBtLihqzE8qMZZ9XoBOdyV4AGQxgcSBmHacIo3hC6VdfWtD1nFWQXZVJAA47rJZpTyHhoWt8ayvVwDtEzXwdNbmKms0q693qKMA6xGF8hvxUhpNtgsxRuIDwVtDeYzJMt8wCugp7Cn8GAoxKM0iZoDAQiBX)5whUh1K3PDv1knsFHl9bUpAp(7GLbyHd3ADsZnM8Qv6ickFE621QSuyHaTzVY4XCUzTCbCi0vHA3M2QMNpVHlBt0NCgj3ePr8jI0DZMHY27Rce4D9fKl3LB(LoLBE9l))C6vnaAI77e8snn7o747SJVwTJ3L5HG7h4i(vcfQ1TUAbYtkP1TNyD5CwBip8sNXdbGDC3eR21yawD41wZGYZ0y4ZBVAKKoP2U42xerkIicRa10Yt6yODrqGvx8LA7uNr6kvALYNOnDrPsDDkL9l2aESxl(r1PT9fKW1trevJDwTDJVIIszCkFFqGJcvlhOp2n4Nz)BSlPSMfs49KOVfr0AEhO2JITuv50cmvVDyNyHPa08ou(gr5JaXx1QgxV7HC7015(fGVcGMcw22nkXMq3GDhl8EI2rEr5NSwQe8WLsDkmp)LXfK59lkBCmOXDnTm9HzDTEzuUNjQmEDd09QaysZHbabCMlazWDyB4G7V2BZ0Ywi7Ce7nz6ZCYDJnbab57Xi2EM3MpVAeTJzPZnfWvugDHlvvFTZ(RXtQqpNQD(hilXKxzA7O3nOf9q0ysx6b2UgdWUCfDeskclynZAekheMnj40IKzLv5zwU1KWI(THlxbfAuFuWpIh621PgND(MuOXys7bI3sbistrkIX9FUUf9gHe0FXSFQyuRlPC2ZBRkk)Nlww9nOsJJkalHMAdjk)I4SU6wPTxW9GHVhmnDBFH8Olv(VDVTy0Kcr7dw(6bAUxyiml2(v7WQoZNbrNQljB2zvTSsTAXHYhDp7N)rQEGm3zO4iq5WnRlDu2zEMtJPP5KQqR()iJK5rlTuXk9BoKYWpSZZntShUPLk9PmOdeSVG)In2WTEeRsYUu11HZQ271MzBYX07fAW1xiBTS277iH2ZXc1ID(t6lW)2P9XQZ1B7a5l0bDjtDtpPxBP0993j9whUB1j9U07R(KERu99cn46lKTEenUkt61vbPB0j9Q3IlmqUnWAAG4Y37a9IJknp6fQ72afSoag)NDr88lMheDEmbNoB)PfHjtgTYFOmeUgZ0G8tA7QD2pTyMKeRvyHtiNbMqGtfQvfm6iWYKc8td0pPQH9Jppb4qaJnPwRj)i7urKEjX0kmRKSvbaZj9awquxKkYA6usKcNwKpB54t(X)fF4FgbKDf5vtYQykDAnxxgs2O70fz0rtyAs1LdCCG2kp1eCcpPrz9xqfnWeDsVMtUnm04UXPxoHE9KvzQ6ACycYZjfrzBpQuMJgkCfDL5OMaYzDJZ2USxB7hXvPVvuxBSckJn4n(TVG8h00Yyzd)3Q(GOOlCkvAkdGoA5nZNVIUI67(mNKTQFCm2kFMtAmlAlYkdNE(M8DGEhJBYK8iYrbOjF(ou)d1bh77pFdn6CZfjDViOCfgGJvapRZ9uqMEx9MS5RBkJ1DUBUTD4tdbN90uYvOSMXpBexZSMIRsPpueOvKJ1pueAS51NHErKyILaH1kP47zFkkWbXTJBDPZE4Tne77GF(18du16NNltfFXnGd(TURDdNcmjTCxlCN1ZRKP8rkDxByd0ypOnbR7BjfTRi2pxy9BtqenOOCzOSLm44jKVQPOEW2NPsqzWrE2tiWfxtx4)97c9q1)ZTST1EStBR9HuO1pqgEA)Lg(2fSVOkSRJgfL4JfBTTK(7(NwcHRImPu2sjdELLgD98HnqUuhmKoEAKJmEaA525k50uTwbqk6YwUyEo9FngTZRyNXNcGEF070SsH702hk06tJlkJliLgJC0PzZj7E55B9fBqUIZSoZPTI52oZCmEVge1oZ9SSDmurCNMNpjy6IIlfKAD7NJT9kxDPSGWL3b6ck97rcxYkL0bJZYwDVXvx0QXaM3r6ch(1Qi(77lvecBtUSQGGglmnDuDYRaN(epKJQ)k0p8qYz3VidyjyIW7(D)638p(fF33(V8MF)3(M)6)Z7ttEW9FZN)p)UV838)9V9PV7x)zV(R)0x)n)RV7V93(MV4386)N)R3(p9F))(P)YLF0F8R(k)39L)9WB(U)Wx92F1)X9Bs6N8xeJ7)6V(BUVY95c)zF33(5EV9R(YV7B)7SrsUWOEWRs2opFlsAGSBCAE9WU7RLMEguyE2uyyK0mBQ55Brs7GeyLP51d7(4nLrqx2DJrAb29GnLiOl7UXiDd7U8Jux6JFt364YF6LGYxhu6MnXFMRkLU3RBQKTZZDva6BGB9TXTyK0m3Q55Dj9tSPUBCMIQV5nyRsCbJ)nivVry5py54pmpdalqb)KppM1(s2vr29rQ)UYD7zQ3U394)kS6o65dF1RS2O7Dpt9YZh2)(lPxhJRlBALbCJlTXKdOI9NABPx9ktDnORLYgK4cwkBqQEJWYRQXTFhRgn92wW4wtVyY42n20kd4gxAJjzg3hI7ct(k3vJpmLg01s5z4ECmrCDnOlX9gUvPUhUGb96RvJmcVTA6tSnr4EFAPTA6tmCWZlYJgeMDzWK5LOUR03OnDVivdPRc13a4WmrBDx2S6MMORzA6jmi(oiJWA0MUxSQjWO(gaJPjABxtG3mn9egs51Wd32L6c(prjlzxb1hTTQ4004OkD7BqPfRaB7g9nSVeekVwOL3Uu3U42ZQ4qBlwb22n67S42csRDqbOJbU5vVch2JzCp2o9a9FqpVhoCWbpaX0cEUgsqUdN73)4EM3qHTJRu3(2ZAF7v33nWbVgLLp6guw2TV3KYYb6cfutZDns4BWLeCnmlRfXF7keRo3P6DS8DS8Thw2IdOE9Oh(o4FeZ4MXi30)HE93556ETh2J3ySTnVhAlQPr)(23GE)(7UESnW3nVO8BANTSt7x9Q1uyEJllxvHH5Wp2367VNvxyhpSpWy2OZX(dBC(Rx0)iBI(TPD8JSsem7yRS9vWo2oTXSJT(M34YYvvyClYmMfTq951yT26QRjnzTi(BTLNN1IQ3XY3XY3Ey5RiWjnD122HJBo7xl2(k4WXoTTdCc5nVXLLRQWWCQTwhpoQXDWDpoocC6gWo2nN9RfBFfSJTtB7aNU(TJDtwUQcJBrMX0aw92p)F4nFX)olAvV(B(BE2R)6F7B)Ip9D)v)bw8QORVtVEsIiNEHNs(mENpnHCWfP1e6O)))]] )