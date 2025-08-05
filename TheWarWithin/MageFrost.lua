-- MageFrost.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "MAGE" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local spec = Hekili:NewSpecialization( 64 )

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
local FindUnitBuffByID, FindUnitDebuffByID = ns.FindUnitBuffByID, ns.FindUnitDebuffByID
-- local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
-- local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
-- local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)

-- spec:RegisterResource( Enum.PowerType.ArcaneCharges )
spec:RegisterResource( Enum.PowerType.Mana )

-- Talents
spec:RegisterTalents( {

    -- Mage
    accumulative_shielding         = {  62093,  382800, 1 }, -- Your barrier's cooldown recharges $s1% faster while the shield persists
    alter_time                     = {  62115,  342245, 1 }, -- Alters the fabric of time, returning you to your current location and health when cast a second time, or after $s1 sec. Effect negated by long distance or death
    arcane_warding                 = {  62114,  383092, 2 }, -- Reduces magic damage taken by $s1%
    barrier_diffusion              = {  62091,  455428, 1 }, -- Whenever one of your Barriers is removed, reduce its cooldown by $s1 sec
    blast_wave                     = {  62103,  157981, 1 }, -- Causes an explosion around yourself, dealing $s$s2 Fire damage to all enemies within $s3 yds, knocking them back, and reducing movement speed by $s4% for $s5 sec
    cryofreeze                     = {  62107,  382292, 2 }, -- While inside Ice Block, you heal for $s1% of your maximum health over the duration
    displacement                   = {  62095,  389713, 1 }, -- Teleports you back to where you last Blinked and heals you for $s1 million health. Only usable within $s2 sec of Blinking
    diverted_energy                = {  62101,  382270, 2 }, -- Your Barriers heal you for $s1% of the damage absorbed
    dragons_breath                 = { 101883,   31661, 1 }, -- Enemies in a cone in front of you take $s$s2 Fire damage and are disoriented for $s3 sec. Damage will cancel the effect
    energized_barriers             = {  62100,  386828, 1 }, -- When your barrier receives melee attacks, you have a $s1% chance to be granted Fingers of Frost. Casting your barrier removes all snare effects
    flow_of_time                   = {  62096,  382268, 2 }, -- The cooldowns of Blink and Shimmer are reduced by $s1 sec
    freezing_cold                  = {  62087,  386763, 1 }, -- Enemies hit by Cone of Cold are frozen in place for $s1 sec instead of snared. When your roots expire or are dispelled, your target is snared by $s2%, decaying over $s3 sec
    frigid_winds                   = {  62128,  235224, 2 }, -- All of your snare effects reduce the target's movement speed by an additional $s1%
    greater_invisibility           = {  93524,  110959, 1 }, -- Makes you invisible and untargetable for $s1 sec, removing all threat. Any action taken cancels this effect. You take $s2% reduced damage while invisible and for $s3 sec after reappearing
    ice_block                      = {  62122,   45438, 1 }, -- Encases you in a block of ice, protecting you from all attacks and damage for $s1 sec, but during that time you cannot attack, move, or cast spells. While inside Ice Block, you heal for $s2% of your maximum health over the duration. Causes Hypothermia, preventing you from recasting Ice Block for $s3 sec
    ice_cold                       = {  62085,  414659, 1 }, -- Ice Block now reduces all damage taken by $s1% for $s2 sec but no longer grants Immunity, prevents movement, attacks, or casting spells. Does not incur the Global Cooldown
    ice_floes                      = {  62105,  108839, 1 }, -- Makes your next Mage spell with a cast time shorter than $s1 sec castable while moving. Unaffected by the global cooldown and castable while casting
    ice_nova                       = {  62088,  157997, 1 }, -- Causes a whirl of icy wind around the enemy, dealing $s$s2 Frost damage to the target and all other enemies within $s3 yds, freezing them in place for $s4 sec. Damage reduced beyond $s5 targets
    ice_ward                       = {  62086,  205036, 1 }, -- Frost Nova now has $s1 charges
    improved_frost_nova            = {  62108,  343183, 1 }, -- Frost Nova duration is increased by $s1 sec
    incantation_of_swiftness       = {  62112,  382293, 2 }, -- Greater Invisibility increases your movement speed by $s1% for $s2 sec
    incanters_flow                 = {  62118,    1463, 1 }, -- Magical energy flows through you while in combat, building up to $s1% increased damage and then diminishing down to $s2% increased damage, cycling every $s3 sec
    inspired_intellect             = {  62094,  458437, 1 }, -- Arcane Intellect grants you an additional $s1% Intellect
    mass_barrier                   = {  62092,  414660, 1 }, -- Cast Ice Barrier on yourself and $s1 allies within $s2 yds
    mass_invisibility              = {  62092,  414664, 1 }, -- You and your allies within $s1 yards instantly become invisible for $s2 sec. Taking any action will cancel the effect. Does not affect allies in combat
    mass_polymorph                 = {  62106,  383121, 1 }, -- Transforms all enemies within $s1 yards into sheep, wandering around incapacitated for $s2 sec. While affected, the victims cannot take actions but will regenerate health very quickly. Damage will cancel the effect. Only works on Beasts, Humanoids and Critters
    master_of_time                 = {  62102,  342249, 1 }, -- Reduces the cooldown of Alter Time by $s1 sec. Alter Time resets the cooldown of Blink and Shimmer when you return to your original location
    mirror_image                   = {  62124,   55342, 1 }, -- Creates $s1 copies of you nearby for $s2 sec, which cast spells and attack your enemies. While your images are active damage taken is reduced by $s3%. Taking direct damage will cause one of your images to dissipate
    overflowing_energy             = {  62120,  390218, 1 }, -- Your spell critical strike damage is increased by $s1%. When your direct damage spells fail to critically strike a target, your spell critical strike chance is increased by $s2%, up to $s3% for $s4 sec. When your spells critically strike Overflowing Energy is reset
    quick_witted                   = {  62104,  382297, 1 }, -- Successfully interrupting an enemy with Counterspell reduces its cooldown by $s1 sec
    reabsorption                   = {  62125,  382820, 1 }, -- You are healed for $s1% of your maximum health whenever a Mirror Image dissipates due to direct damage
    reduplication                  = {  62125,  382569, 1 }, -- Mirror Image's cooldown is reduced by $s1 sec whenever a Mirror Image dissipates due to direct damage
    remove_curse                   = {  62116,     475, 1 }, -- Removes all Curses from a friendly target
    rigid_ice                      = {  62110,  382481, 1 }, -- Frost Nova can withstand $s1% more damage before breaking
    ring_of_frost                  = {  62088,  113724, 1 }, -- Summons a Ring of Frost for $s1 sec at the target location. Enemies entering the ring are incapacitated for $s2 sec. Limit $s3 targets. When the incapacitate expires, enemies are slowed by $s4% for $s5 sec
    shifting_power                 = {  62113,  382440, 1 }, -- Draw power from within, dealing $s$s2 Arcane damage over $s3 sec to enemies within $s4 yds. While channeling, your Mage ability cooldowns are reduced by $s5 sec over $s6 sec
    shimmer                        = {  62105,  212653, 1 }, -- Teleports you $s1 yds forward, unless something is in the way. Unaffected by the global cooldown and castable while casting
    slow                           = {  62097,   31589, 1 }, -- Reduces the target's movement speed by $s1% for $s2 sec
    spellsteal                     = {  62084,   30449, 1 }, -- Steals a beneficial magic effect from the target. This effect lasts a maximum of $s1 min
    supernova                      = { 101883,  157980, 1 }, -- Pulses arcane energy around the target enemy or ally, dealing $s$s2 Arcane damage to all enemies within $s3 yds, and knocking them upward. A primary enemy target will take $s4% increased damage
    tempest_barrier                = {  62111,  382289, 2 }, -- Gain a shield that absorbs $s1% of your maximum health for $s2 sec after you Blink
    temporal_velocity              = {  62099,  382826, 2 }, -- Increases your movement speed by $s1% for $s2 sec after casting Blink and $s3% for $s4 sec after returning from Alter Time
    time_manipulation              = {  62129,  387807, 1 }, -- Casting Ice Lance on Frozen targets reduces the cooldown of your loss of control abilities by $s1 sec
    tome_of_antonidas              = {  62098,  382490, 1 }, -- Increases Haste by $s1%
    tome_of_rhonin                 = {  62127,  382493, 1 }, -- Increases Critical Strike chance by $s1%
    volatile_detonation            = {  62089,  389627, 1 }, -- Greatly increases the effect of Blast Wave's knockback. Blast Wave's cooldown is reduced by $s1 sec
    winters_protection             = {  62123,  382424, 2 }, -- The cooldown of Ice Block is reduced by $s1 sec

    -- Frost
    bone_chilling                  = {  62167,  205027, 1 }, -- Whenever you attempt to chill a target, you gain Bone Chilling, increasing spell damage you deal by $s1% for $s2 sec, stacking up to $s3 times
    brain_freeze                   = {  62179,  190447, 1 }, -- Frostbolt has a $s1% chance to reset the remaining cooldown on Flurry and cause your next Flurry to deal $s2% increased damage
    chain_reaction                 = {  62161,  278309, 1 }, -- Your Ice Lances against frozen targets increase the damage of your Ice Lances by $s1% for $s2 sec, stacking up to $s3 times
    cold_front                     = {  62155,  382110, 1 }, -- Casting $s1 Frostbolts or Flurries summons a Frozen Orb that travels toward your target. Hitting an enemy player counts as double
    coldest_snap                   = {  62185,  417493, 1 }, -- Cone of Cold's cooldown is increased to $s1 sec and if Cone of Cold hits $s2 or more enemies it resets the cooldown of Frozen Orb and Comet Storm. In addition, Cone of Cold applies Winter's Chill to all enemies hit. Cone of Cold's cooldown can no longer be reduced by your cooldown reduction effects
    comet_storm                    = {  62182,  153595, 1 }, -- Calls down a series of $s2 icy comets on and around the target, that deals up to $s$s3 Frost damage to all enemies within $s4 yds of its impacts
    cryopathy                      = {  62152,  417491, 1 }, -- Each time you consume Fingers of Frost the damage of your next Ray of Frost is increased by $s1%, stacking up to $s2%. Icy Veins grants $s3 stacks instantly
    deaths_chill                   = { 101302,  450331, 1 }, -- While Icy Veins is active, damaging an enemy with Frostbolt increases spell damage by $s1%. Stacks up to $s2 times
    deep_shatter                   = {  62159,  378749, 2 }, -- Your Frostbolt deals $s1% additional damage to Frozen targets
    everlasting_frost              = {  81468,  385167, 1 }, -- Frozen Orb deals an additional $s1% damage and its duration is increased by $s2 sec
    fingers_of_frost               = {  62164,  112965, 1 }, -- Frostbolt has a $s1% chance and Frozen Orb damage has a $s2% to grant a charge of Fingers of Frost. Fingers of Frost causes your next Ice Lance to deal damage as if the target were frozen. Maximum $s3 charges
    flash_freeze                   = {  62168,  379993, 1 }, -- Each of your Icicles deals $s1% additional damage, and when an Icicle deals damage you have a $s2% chance to gain the Fingers of Frost effect
    flurry                         = {  62178,   44614, 1 }, -- Unleash a flurry of ice, striking the target $s2 times for a total of $s$s3 Frost damage. Each hit reduces the target's movement speed by $s4% for $s5 sec and applies Winter's Chill to the target. Winter's Chill causes the target to take damage from your spells as if it were frozen
    fractured_frost                = {  62151,  378448, 1 }, -- While Icy Veins is active, your Frostbolts hit up to $s1 additional targets and their damage is increased by $s2%
    freezing_rain                  = {  62150,  270233, 1 }, -- Frozen Orb makes Blizzard instant cast and increases its damage done by $s1% for $s2 sec
    freezing_winds                 = {  62184, 1216953, 1 }, -- Frozen Orb deals $s1% increased damage to units affected by your Blizzard
    frostbite                      = {  81467,  378756, 1 }, -- Gives your Chill effects a $s1% chance to freeze the target for $s2 sec
    frozen_orb                     = {  62177,   84714, 1 }, -- Launches an orb of swirling ice up to $s3 yds forward which deals up to $s$s4 Frost damage to all enemies it passes through over $s5 sec. Deals reduced damage beyond $s6 targets. Grants $s7 charge of Fingers of Frost when it first damages an enemy$s$s8 Enemies damaged by the Frozen Orb are slowed by $s9% for $s10 sec
    frozen_touch                   = {  62180,  205030, 1 }, -- Frostbolt grants you Fingers of Frost $s1% more often and Brain Freeze $s2% more often
    glacial_assault                = {  62183,  378947, 1 }, -- Your Comet Storm now applies Numbing Blast, increasing the damage enemies take from you by $s2% for $s3 sec. Additionally, Flurry has a $s4% chance each hit to call down an icy comet, crashing into your target and nearby enemies for $s$s5 Frost damage
    glacial_spike                  = {  62157,  199786, 1 }, -- Conjures a massive spike of ice, and merges your current Icicles into it. It impales your target, dealing $s$s2 million damage plus all of the damage stored in your Icicles, and freezes the target in place for $s3 sec. Damage may interrupt the freeze effect. Requires $s4 Icicles to cast. : Ice Lance no longer launches Icicles
    hailstones                     = {  62158,  381244, 1 }, -- Casting Ice Lance on Frozen targets has a $s1% chance to generate an Icicle
    ice_caller                     = {  62170,  236662, 1 }, -- Each time Blizzard deals damage, the cooldown of Frozen Orb is reduced by $s1 sec
    ice_lance                      = {  62176,   30455, 1 }, -- Quickly fling a shard of ice at the target, dealing $s$s2 Frost damage. Ice Lance damage is tripled against frozen targets
    icy_veins                      = {  62171,   12472, 1 }, -- Accelerates your spellcasting for $s1 sec, granting $s2% haste and preventing damage from delaying your spellcasts. Activating Icy Veins summons a water elemental to your side for its duration. The water elemental's abilities grant you Frigid Empowerment, increasing the Frost damage you deal by $s3%, up to $s4%
    lonely_winter                  = {  62173,  205024, 1 }, -- Frostbolt, Ice Lance, and Flurry deal $s1% increased damage
    permafrost_lances              = {  62169,  460590, 1 }, -- Frozen Orb increases Ice Lance's damage by $s1% for $s2 sec
    perpetual_winter               = {  62181,  378198, 1 }, -- Flurry now has $s1 charges
    piercing_cold                  = {  62166,  378919, 1 }, -- Frostbolt and Glacial Spike critical strike damage increased by $s1%
    ray_of_frost                   = {  62153,  205021, 1 }, -- Channel an icy beam at the enemy for $s2 sec, dealing $s$s3 Frost damage every $s4 sec and slowing movement by $s5%. Each time Ray of Frost deals damage, its damage and snare increases by $s6%. Generates $s7 charges of Fingers of Frost over its duration
    shatter                        = {  62165,   12982, 1 }, -- Multiplies the critical strike chance of your spells against frozen targets by $s1, and adds an additional $s2% critical strike chance
    slick_ice                      = {  62156,  382144, 1 }, -- While Icy Veins is active, each Frostbolt you cast reduces the cast time of Frostbolt by $s1% and increases its damage by $s2%, stacking up to $s3 times
    splintering_cold               = {  62162,  379049, 2 }, -- Frostbolt and Flurry have a $s1% chance to generate $s2 Icicles
    splintering_ray                = { 103771,  418733, 1 }, -- Ray of Frost deals $s1% of its damage to $s2 nearby enemies
    splitting_ice                  = {  62163,   56377, 1 }, -- Your Ice Lance and Icicles now deal $s1% increased damage, and hit a second nearby target for $s2% of their damage. Your Glacial Spike also hits a second nearby target for $s3% of its damage
    subzero                        = {  62160,  380154, 2 }, -- Your Frost spells deal $s1% more damage to targets that are rooted and frozen
    thermal_void                   = {  62154,  155149, 1 }, -- Icy Veins' duration is increased by $s1 sec. Your Ice Lances against frozen targets extend your Icy Veins by an additional $s2 sec and Glacial Spike extends it an addtional $s3 sec
    winters_blessing               = {  62174,  417489, 1 }, -- Your Haste is increased by $s1%. You gain $s2% more of the Haste stat from all sources
    wintertide                     = {  62172,  378406, 2 }, -- Damage from Frostbolt and Flurry increases the damage of your Icicles and Glacial Spike by $s1%. Stacks up to $s2 times

    -- Frostfire
    elemental_affinity             = {  94633,  431067, 1 }, -- The cooldown of Fire spells is reduced by $s1%
    excess_fire                    = {  94637,  438595, 1 }, -- Casting Comet Storm causes your next Ice Lance to explode in a Frostfire Burst, dealing $s$s2 Frostfire damage to nearby enemies. Damage reduced beyond $s3 targets. Frostfire Burst has an $s4% chance to grant Brain Freeze
    excess_frost                   = {  94639,  438600, 1 }, -- Consuming Excess Fire causes your next Flurry to also cast Ice Nova at $s1% effectiveness. Ice Novas cast this way do not freeze enemies in place. When you consume Excess Frost, the cooldown of Comet Storm is reduced by $s2 sec
    flame_and_frost                = {  94633,  431112, 1 }, -- Cold Snap additionally resets the cooldowns of your Fire spells
    flash_freezeburn               = {  94635,  431178, 1 }, -- Frostfire Empowerment grants you maximum benefit of Frostfire Mastery, refreshes its duration, and grants you Excess Frost and Excess Fire. Casting Combustion or Icy Veins grants you Frostfire Empowerment
    frostfire_bolt                 = {  94641,  431044, 1 }, -- Launches a bolt of frostfire at the enemy, causing $s$s3 Frostfire damage, slowing movement speed by $s4%, and causing an additional $s$s5 Frostfire damage over $s6 sec. Frostfire Bolt generates stacks for both Fire Mastery and Frost Mastery
    frostfire_empowerment          = {  94632,  431176, 1 }, -- Your Frost and Fire spells have a chance to activate Frostfire Empowerment, causing your next Frostfire Bolt to be instant cast, deal $s1% increased damage, explode for $s2% of its damage to nearby enemies
    frostfire_infusion             = {  94634,  431166, 1 }, -- Your Frost and Fire spells have a chance to trigger an additional bolt of Frostfire, dealing $s1 damage. This effect generates Frostfire Mastery when activated
    frostfire_mastery              = {  94636,  431038, 1 }, -- Your damaging Fire spells generate $s1 stack of Fire Mastery and Frost spells generate $s2 stack of Frost Mastery. Fire Mastery increases your haste by $s3%, and Frost Mastery increases your Mastery by $s4% for $s5 sec, stacking up to $s6 times each. Adding stacks does not refresh duration
    imbued_warding                 = {  94642,  431066, 1 }, -- Ice Barrier also casts a Blazing Barrier at $s1% effectiveness
    isothermic_core                = {  94638,  431095, 1 }, -- Comet Storm now also calls down a Meteor at $s1% effectiveness onto your target's location. Meteor now also calls down a Comet Storm at $s2% effectiveness onto your target location
    meltdown                       = {  94642,  431131, 1 }, -- You melt slightly out of your Ice Block and Ice Cold, allowing you to move slowly during Ice Block and increasing your movement speed over time. Ice Block and Ice Cold trigger a Blazing Barrier when they end
    severe_temperatures            = {  94640,  431189, 1 }, -- Casting damaging Frost or Fire spells has a high chance to increase the damage of your next Frostfire Bolt by $s1%, stacking up to $s2 times
    thermal_conditioning           = {  94640,  431117, 1 }, -- Frostfire Bolt's cast time is reduced by $s1%

    -- Spellslinger
    augury_abounds                 = {  94662,  443783, 1 }, -- Casting Icy Veins conjures $s1 Frost Splinters. During Icy Veins, whenever you conjure a Frost Splinter, you have a $s2% chance to conjure an additional Frost Splinter
    controlled_instincts           = {  94663,  444483, 1 }, -- While a target is under the effects of Blizzard, $s1% of the direct damage dealt by a Frost Splinter is also dealt to nearby enemies. Damage reduced beyond $s2 targets
    force_of_will                  = {  94656,  444719, 1 }, -- Gain $s1% increased critical strike chance. Gain $s2% increased critical strike damage
    look_again                     = {  94659,  444756, 1 }, -- Displacement has a $s1% longer duration and $s2% longer range
    phantasmal_image               = {  94660,  444784, 1 }, -- Your Mirror Image summons one extra clone. Mirror Image now reduces all damage taken by an additional $s1%
    reactive_barrier               = {  94660,  444827, 1 }, -- Your Ice Barrier can absorb up to $s1% more damage based on your missing Health. Max effectiveness when under $s2% health
    shifting_shards                = {  94657,  444675, 1 }, -- Shifting Power fires a barrage of $s1 Frost Splinters at random enemies within $s2 yds over its duration
    signature_spell                = {  94657,  470021, 1 }, -- Consuming Winter's Chill with Glacial Spike conjures $s1 additional Frost Splinters
    slippery_slinging              = {  94659,  444752, 1 }, -- You have $s1% increased movement speed during Alter Time
    spellfrost_teachings           = {  94655,  444986, 1 }, -- Direct damage from Frost Splinters reduces the cooldown of Frozen Orb by $s1 sec
    splintering_orbs               = {  94661,  444256, 1 }, -- Enemies damaged by your Frozen Orb conjure $s1 Frost Splinter, up to $s2. Frozen Orb damage is increased by $s3%
    splintering_sorcery            = {  94664,  443739, 1 }, -- When you consume Winter's Chill or Fingers of Frost, conjure a Frost Splinter. Frost Splinter:
    splinterstorm                  = {  94654,  443742, 1 }, -- Whenever you have $s2 or more active Embedded Frost Splinters, you automatically cast a Splinterstorm at your target. Splinterstorm: Shatter all Embedded Frost Splinters, dealing their remaining periodic damage instantly. Conjure a Frost Splinter for each Splinter shattered, then unleash them all in a devastating barrage, dealing $s$s5 Frost damage to your target for each Splinter in the Splinterstorm. Splinterstorm has a $s6% chance to grant Brain Freeze
    unerring_proficiency           = {  94658,  444974, 1 }, -- Each time you conjure a Frost Splinter, increase the damage of your next Ice Nova by $s1%. Stacks up to $s2 times
    volatile_magic                 = {  94658,  444968, 1 }, -- Whenever an Embedded Frost Splinter is removed, it explodes, dealing $s$s2 Frost damage to nearby enemies. Deals reduced damage beyond $s3 targets
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    concentrated_coolness          =  632, -- (198148) Frozen Orb's damage is increased by $s1% and is now castable at a location with a $s2 yard range but no longer moves
    ethereal_blink                 = 5600, -- (410939) Blink and Shimmer apply Slow at $s1% effectiveness to all enemies you Blink through. For each enemy you Blink through, the cooldown of Blink and Shimmer are reduced by $s2 sec, up to $s3 sec
    frost_bomb                     = 5496, -- (390612) Places a Frost Bomb on the target. After $s2 sec, the bomb explodes, dealing $s3 million Frost damage to the target and $s$s4 Frost damage to all other enemies within $s5 yards. All affected targets are slowed by $s6% for $s7 sec. If Frost Bomb is dispelled before it explodes, gain a charge of Brain Freeze
    ice_form                       =  634, -- (198144) Your body turns into Ice, increasing your Frostbolt damage done by $s1% and granting immunity to stun and knockback effects. Lasts $s2 sec
    ice_wall                       = 5390, -- (352278) Conjures an Ice Wall $s1 yards long that obstructs line of sight. The wall has $s2% of your maximum health and lasts up to $s3 sec
    icy_feet                       =   66, -- (407581) When your Frost Nova or Water Elemental's Freeze is dispelled or removed, become immune to snares for $s1 sec. This effect can only occur once every $s2 sec
    improved_mass_invisibility     = 5622, -- (415945) The cooldown of Mass Invisibility is reduced by $s1 min and can affect allies in combat
    master_shepherd                = 5581, -- (410248) While an enemy player is affected by your Polymorph or Mass Polymorph, your movement speed is increased by $s1% and your Versatility is increased by $s2%. Additionally, Polymorph and Mass Polymorph no longer heal enemies
    overpowered_barrier            = 5708, -- (1220739) Your barriers absorb $s2% more damage and have an additional effect, but last $s3 sec.  Ice Barrier If the barrier is fully absorbed, enemies within $s6 yds suffer $s$s7 Frost damage and are slowed by $s8% for $s9 sec
    ring_of_fire                   = 5490, -- (353082) Summons a Ring of Fire for $s1 sec at the target location. Enemies entering the ring are disoriented and burn for $s2% of their total health over $s3 sec
    snowdrift                      = 5497, -- (389794) Summon a strong Blizzard that surrounds you for $s2 sec that slows enemies by $s3% and deals $s$s4 Frost damage every $s5 sec. Enemies that are caught in Snowdrift for $s6 sec consecutively become Frozen in ice, stunned for $s7 sec
} )

-- Auras
spec:RegisterAuras( {
    active_blizzard = {
        duration = function () return 15 * haste end,
        max_stack = 1,
        generate = function( t )
            if query_time - action.blizzard.lastCast < 15 * haste then
                t.count = 1
                t.applied = action.blizzard.lastCast
                t.expires = t.applied + ( 15 * haste )
                t.caster = "player"
                return
            end

            t.count = 0
            t.applied = 0
            t.expires = 0
            t.caster = "nobody"
        end,

    },

    active_comet_storm = {
        duration = 2.6,
        max_stack = 1,
        generate = function( t )
            if query_time - action.comet_storm.lastCast < 2.6 then
                t.count = 1
                t.applied = action.comet_storm.lastCast
                t.expires = t.applied + 2.6
                t.caster = "player"
                return
            end

            t.count = 0
            t.applied = 0
            t.expires = 0
            t.caster = "nobody"
        end,
    },
    arcane_power = {
        id = 12042,
        duration = 15,
        type = "Magic",
        max_stack = 1,
    },
    -- Talent: Movement speed reduced by $s2%.
    -- https://wowhead.com/beta/spell=157981
    blast_wave = {
        id = 157981,
        duration = 6,
        type = "Magic",
        max_stack = 1
    },
    -- Blinking.
    -- https://wowhead.com/beta/spell=1953
    blink = {
        id = 1953,
        duration = 0.3,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=12486
    blizzard = {
        id = 12486,
        duration = 3,
        mechanic = "snare",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Spell damage done increased by ${$W1}.1%.
    -- https://wowhead.com/beta/spell=205766
    bone_chilling = {
        id = 205766,
        duration = 8,
        max_stack = 10
    },
    brain_freeze = {
        id = 190446,
        duration = 15,
        max_stack = 1,
    },
    chain_reaction = {
        id = 278310,
        duration = 10,
        max_stack = 5,
    },
    -- Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=205708
    chilled = {
        id = 205708,
        duration = 8,
        max_stack = 1
    },
    cold_front = {
        id = 382113,
        duration = 30,
        max_stack = 30
    },
    cold_front_ready = {
        id = 382114,
        duration = 30,
        max_stack = 1
    },
    -- Movement speed reduced by $s1%.
    -- https://wowhead.com/beta/spell=212792
    cone_of_cold = {
        id = 212792,
        duration = 5,
        max_stack = 1
    },
    cryopathy = {
        id = 417492,
        duration = 60,
        max_stack = 16,
    },
    deaths_chill = {
        id = 454371,
        duration = function() return buff.icy_veins.up and buff.icy_veins.remains or spec.auras.icy_veins.duration end,
        max_stack = 15
    },
    -- Talent: Disoriented.
    -- https://wowhead.com/beta/spell=31661
    dragons_breath = {
        id = 31661,
        duration = 4,
        type = "Magic",
        max_stack = 1
    },
    embedded_frost_splinter = {
        id = 443740,
        duration = 18,
        max_stack = 8
    },
    excess_frost = {
        id = 438611,
        duration = 30,
        max_stack = 2,
        meta = {
            stack = function() return max( 0, ( state.buff.excess_frost.stack - ( action.flurry.in_flight and 1 or 0 ) ) ) end,
            stacks = function() return max( 0, ( state.buff.excess_frost.stack - ( action.flurry.in_flight and 1 or 0 ) ) ) end,
            react = function() return max( 0, ( state.buff.excess_frost.stack - ( action.flurry.in_flight and 1 or 0 ) ) ) end,
        }
    },
    fingers_of_frost = {
        id = 44544,
        duration = 15,
        max_stack = 2
    },
    fof_consumed = {
        -- Virtual buff to track if FoF is consumed (by Ice Lance) so we know whether to (virtually) consume Winter's Chill stacks.
        -- Appears to only happen during the addon's forecasting, need to determine if we need to also apply this buff in reset_precast to avoid recommendation flicker between IL cast and impact.
        -- Duration = 0.1 + max_range[ 40 ] / velocity[ 47 ]
        duration = 0.95,
        max_stack = 2
    },
    fire_mastery = {
        id = 431040,
        duration = 14,
        max_stack = 6
    },
    -- Talent: Movement slowed by $w1%.
    -- https://wowhead.com/beta/spell=228354
    flurry = {
        id = 228354,
        duration = 1,
        type = "Magic",
        max_stack = 1
    },
    focus_magic = {
        id = 321358,
        duration = 1800,
        max_stack = 1,
        friendly = true,
    },
    focus_magic_buff = {
        id = 321363,
        duration = 10,
        max_stack = 1,
    },
    freeze = {
        id = 33395,
        duration = 8,
        max_stack = 1,
        shared = "pet"
    },
    greater_invisibility_defense = {
        id = 113862,
        duration = 6,
        max_stack = 1,
    },
    
    -- Talent: Blizzard is instant cast and deals $s2% increased damage.
    -- https://wowhead.com/beta/spell=270232
    freezing_rain = {
        id = 270232,
        duration = 12,
        max_stack = 1
    },
    frigid_empowerment = {
        id = 417488,
        duration = 60,
        max_stack = 5
    },
    -- Frozen in place.
    -- https://wowhead.com/beta/spell=122
    frost_nova = {
        id = 122,
        duration = 10,
        type = "Magic",
        max_stack = 1,
        copy = 235235
    },
    frost_mastery = {
        id = 431039,
        duration = 14,
        max_stack = 6
    },
    -- Talent: Frozen.
    -- https://wowhead.com/beta/spell=378760
    frostbite = {
        id = 378760,
        duration = 4,
        mechanic = "root",
        type = "Magic",
        max_stack = 1
    },
    frostbolt = {
        id = 59638,
        duration = 4,
        type = "Magic",
        max_stack = 1,
    },
    frostfire_bolt = {
        id = 468655,
        duration = 8,
        max_stack = 1
    },
    frozen_orb = {
        duration = function() return 10 + 2 * talent.everlasting_frost.rank end,
        max_stack = 1,
        generate = function( t )
            if query_time - action.frozen_orb.lastCast < t.duration then
                t.count = 1
                t.applied = action.frozen_orb.lastCast
                t.expires = t.applied + t.duration
                t.caster = "player"
                return
            end

            t.count = 0
            t.applied = 0
            t.expires = 0
            t.caster = "nobody"
        end,
    },
    -- Talent: Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=289308
    frozen_orb_snare = {
        id = 289308,
        duration = 3,
        max_stack = 1,
    },
    -- Talent: Frozen in place.
    -- https://wowhead.com/beta/spell=228600
    glacial_spike = {
        id = 228600,
        duration = 4,
        type = "Magic",
        max_stack = 1
    },
    glacial_spike_usable = {
        id = 199844,
        duration = 60,
        max_stack = 1
    },
    -- Talent: Absorbs $w1 damage.  Melee attackers slowed by $205708s1%.$?s235297[  Armor increased by $s3%.][]
    -- https://wowhead.com/beta/spell=11426
    ice_barrier = {
        id = 11426,
        duration = 60,
        type = "Magic",
        max_stack = 1
    },
    -- Frostbolt damage done increased by $m1%. Immune to stun and knockback effects.
    -- https://wowhead.com/beta/spell=198144
    ice_form = {
        id = 198144,
        duration = 12,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Frozen.
    -- https://wowhead.com/beta/spell=157997
    ice_nova = {
        id = 157997,
        duration = 2,
        type = "Magic",
        max_stack = 1
    },
    icicles = {
        id = 205473,
        duration = 60,
        max_stack = 5,
    },
    -- Talent: Haste increased by $w1% and immune to pushback.
    -- https://wowhead.com/beta/spell=12472
    icy_veins = {
        id = 12472,
        duration = function() return talent.thermal_void.enabled and 30 or 25 end,
        type = "Magic",
        max_stack = 1
    },
    incanters_flow = {
        id = 116267,
        duration = 3600,
        max_stack = 5,
        meta = {
            stack = function() return state.incanters_flow_stacks end,
            stacks = function() return state.incanters_flow_stacks end,
        }
    },
    preinvisibility = {
        id = 66,
        duration = 3,
        max_stack = 1,
    },
    invisibility = {
        id = 32612,
        duration = 20,
        max_stack = 1
    },
    -- Talent: Incapacitated. Cannot attack or cast spells.  Increased health regeneration.
    -- https://wowhead.com/beta/spell=383121
    mass_polymorph = {
        id = 383121,
        duration = 60,
        mechanic = "polymorph",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=391104
    mass_slow = {
        id = 391104,
        duration = 15,
        mechanic = "snare",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Damage taken is reduced by $s3% while your images are active.
    -- https://wowhead.com/beta/spell=55342
    mirror_image = {
        id = 55342,
        duration = 40,
        max_stack = 3,
        generate = function ()
            local mi = buff.mirror_image

            if action.mirror_image.lastCast > 0 and query_time < action.mirror_image.lastCast + 40 then
                mi.count = 1
                mi.applied = action.mirror_image.lastCast
                mi.expires = mi.applied + 40
                mi.caster = "player"
                return
            end

            mi.count = 0
            mi.applied = 0
            mi.expires = 0
            mi.caster = "nobody"
        end,
    },
    numbing_blast = {
        id = 417490,
        duration = 6,
        max_stack = 1
    },
    permafrost_lances = {
        id = 455122,
        duration = 15,
        max_stack = 1
    },
    polymorph = {
        id = 118,
        duration = 60,
        max_stack = 1
    },
    -- Talent: Movement slowed by $w1%.  Taking $w2 Frost damage every $t2 sec.
    -- https://wowhead.com/beta/spell=205021
    ray_of_frost = {
        id = 205021,
        duration = 5,
        type = "Magic",
        max_stack = 1
    },
    shatter = {
        id = 12982,
    },
    -- Talent: Every $t1 sec, deal $382445s1 Nature damage to enemies within $382445A1 yds and reduce the remaining cooldown of your abilities by ${-$s2/1000} sec.
    -- https://wowhead.com/beta/spell=382440
    shifting_power = {
        id = 382440,
        duration = 4,
        tick_time = 1,
        type = "Magic",
        max_stack = 1,
        copy = 314791
    },
    -- Talent: Shimmering.
    -- https://wowhead.com/beta/spell=212653
    shimmer = {
        id = 212653,
        duration = 0.65,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Cast time of Frostbolt reduced by $s1% and its damage is increased by $s2%.
    -- https://wowhead.com/beta/spell=382148
    slick_ice = {
        id = 382148,
        duration = 60,
        max_stack = 5,
        copy = 327509
    },
    -- Talent: Movement speed reduced by $w1%.
    -- https://wowhead.com/beta/spell=31589
    slow = {
        id = 31589,
        duration = 15,
        mechanic = "snare",
        type = "Magic",
        max_stack = 1
    },
    slow_fall = {
        id = 130,
        duration = 30,
        max_stack = 1,
    },
    -- Talent: Absorbs $w1 damage.
    -- https://wowhead.com/beta/spell=382290
    tempest_barrier = {
        id = 382290,
        duration = 15,
        type = "Magic",
        max_stack = 1
    },
    winters_chill = {
        id = 228358,
        duration = 8,
        type = "Magic",
        max_stack = 2
    },
    wintertide = {
        id = 1222865,
        duration = 15,
        max_stack = 4
    },

    frozen = {
        duration = 1,

        meta = {
            spell = function( t )
                if debuff.winters_chill.up and remaining_winters_chill > 0 then return debuff.winters_chill end
                local spell = debuff.frost_nova

                if debuff.frostbite.remains     > spell.remains then spell = debuff.frostbite     end
                if debuff.freeze.remains        > spell.remains then spell = debuff.freeze        end
                if debuff.glacial_spike.remains > spell.remains then spell = debuff.glacial_spike end

                return spell
            end,

            up = function( t )
                return t.spell.up
            end,
            down = function( t )
                return t.spell.down
            end,
            applied = function( t )
                return t.spell.applied
            end,
            expires = function( t )
                return t.spell.expires
            end,
            remains = function( t )
                return t.spell.remains
            end,
            count = function(t )
                return t.spell.count
            end,
            stack = function( t )
                return t.spell.stack
            end,
            stacks = function( t )
                return t.spell.stacks
            end,
        }
    },

    -- Azerite Powers (overrides)
    frigid_grasp = {
        id = 279684,
        duration = 20,
        max_stack = 1,
    },
    overwhelming_power = {
        id = 266180,
        duration = 25,
        max_stack = 25,
    },
    tunnel_of_ice = {
        id = 277904,
        duration = 300,
        max_stack = 3
    },

    -- Legendaries
    expanded_potential = {
        id = 327495,
        duration = 300,
        max_stack = 1
    },
} )

spec:RegisterPet( "water_elemental", 208441, "icy_veins", function() return talent.thermal_void.enabled and 30 or 25 end )

spec:RegisterStateExpr( "fingers_of_frost_active", function ()
    return false
end )

spec:RegisterStateFunction( "fingers_of_frost", function( active )
    fingers_of_frost_active = active
end )

local wc_spenders = {
    frostbolt = true,
    glacial_spike = true,
    ice_lance = true,
    frostfire_bolt = true,
}

spec:RegisterStateExpr( "remaining_winters_chill", function ()
    local wc = debuff.winters_chill
    local stacks, remains = wc.stack, wc.remains

    if stacks == 0 or remains == 0 then
        if Hekili.ActiveDebug then Hekili:Debug( "Remaining Winters Chill(%s): No stacks or remaining time.", this_action ) end
        return 0
    end

    if this_action == "ice_lance" and action.ice_lance.time_since > 0.3 and
            ( action.frostbolt.in_flight or action.glacial_spike.in_flight or action.frostfire_bolt.in_flight ) then
        -- Credit back the stack of Winter's Chill that these will consume so you can double-dip with Ice Lance.
        stacks = stacks + 1
    end

    local ability = class.abilities[ this_action ]
    local cast = ability and ability.cast or 0

    if remains < cast then
        if Hekili.ActiveDebug then Hekili:Debug( "Remaining Winters Chill(%s): No time to cast.", this_action ) end
        return 0
    end

    if stacks > 1 and remains < 0.1 + cast + gcd.max then
        if Hekili.ActiveDebug then
            Hekili:Debug( "Remaining Winters Chill(%s): Stacks reduced as cast time + GCD (%.2f) exceeds remaining time (%.2f).", this_action, 0.1 + cast + gcd.max, remains )
        end
        stacks = stacks - 1
    end

    local projectiles = 0
    local fof_consumed = buff.fof_consumed.remains

    for spender in pairs( wc_spenders ) do
        local a = action[ spender ]
        local in_flight_remains = a.in_flight_remains
        if in_flight_remains > 0 and in_flight_remains < remains then
            if spender == "ice_lance" and fof_consumed > in_flight_remains then
                if Hekili.ActiveDebug then Hekili:Debug( "Remaining Winters Chill(%s): Ice Lance in flight, but FoF consumed before it hits.", this_action ) end
            else
                if Hekili.ActiveDebug then Hekili:Debug( "Remaining Winters Chill(%s): Added %s projectile.", this_action, spender ) end
                projectiles = projectiles + 1
            end
        end
    end

    local result = max( 0, stacks - projectiles )

    if Hekili.ActiveDebug then
        Hekili:Debug( "Remaining Winters Chill(%s): FoF Consumed[%s], Winter's Chill[%d => %d, %.2f vs. %.2f], Projectiles[%d]; Value[%d]",
            this_action, buff.fof_consumed.up and "true" or "false",
            wc.stack, stacks, remains, cast,
            projectiles,
            result )
    end
    return result
end )

spec:RegisterStateTable( "ground_aoe", {
    frozen_orb = setmetatable( {}, {
        __index = setfenv( function( t, k )
            if k == "remains" then
                return buff.frozen_orb.remains
            end
        end, state )
    } ),

    blizzard = setmetatable( {}, {
        __index = setfenv( function( t, k )
            if k == "remains" then return buff.active_blizzard.remains end
        end, state )
    } )
} )

spec:RegisterStateExpr( "freezable", function ()
    return not target.is_boss or target.level < level + 3
end )

spec:RegisterStateTable( "frost_info", {
    last_target_actual = "nobody",
    last_target_virtual = "nobody",
    watching = true,

    -- real_brain_freeze = false,
    -- virtual_brain_freeze = false
} )

local lastCometCast = 0
local lastAutoComet = 0

local latestFingersLance = 0 -- Sorry, Lance
local numLances = 0
local lanceRemoved, lanceICD = 0, 0.3 -- Only count one Ice Lance impact per lanceICD seconds.

local numFingers = 0

local auraChanged = {
    SPELL_AURA_APPLIED = true,
    SPELL_AURA_REFRESH = true,
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_APPLIED_DOSE = true,
    SPELL_AURA_REMOVED_DOSE = true
}

local auraSpent = {
    SPELL_AURA_REMOVED = true,
    SPELL_AURA_REMOVED_DOSE = true
}

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID == GUID then
        if subtype == "SPELL_CAST_SUCCESS" then
            if spellID == 116 then frost_info.last_target_actual = destGUID
            elseif spellID == 30455 then
                -- There appears to be a consistent ~0.1s delay between Ice Lance's cast and Fingers of Frost being consumed.
                local fof = GetPlayerAuraBySpellID( 44544 )

                if fof then
                    latestFingersLance = GetTime() + 1
                    numLances = numLances + 1
                    numFingers = numFingers + 1
                end
            end
        end

        if spellID == 44544 and auraSpent[ subtype ] then
            -- Decrement numberr of FoF stacks to remove.
            numFingers = max( 0, numFingers - 1 )
        end

        local now = GetTime()

        if subtype == "SPELL_DAMAGE" and spellID == 30455 and now - lanceRemoved > lanceICD then
            numLances = max( 0, numLances - 1 )
            if numLances == 0 then latestFingersLance = 0 end
        end

        if state.talent.glacial_spike.enabled and ( spellID == 205473 or spellID == 199844 ) and auraChanged[ subtype ] then
            Hekili:ForceUpdate( "ICICLES_CHANGED", true )
        end

        if spellID == 44544 and auraSpent[ subtype ] then
            local fof = GetPlayerAuraBySpellID( 44544 )
            pendingFinger = false

            -- print( "Fingers of Frost: ", subtype, spellID, spellName, fof and fof.expires or 0, fof and max( 1, fof.applications ) or 0, pendingFinger )
        end

        if ( spellID == 153595 or spellID == 153596 ) then
            local t = GetTime()

            if subtype == "SPELL_CAST_SUCCESS" then
                lastCometCast = t
            elseif subtype == "SPELL_DAMAGE" and t - lastCometCast > 3 and t - lastAutoComet > 3 then
                -- TODO:  Revisit strategy for detecting auto comets.
                lastAutoComet = t
            end
        end
    end
end, false )

spec:RegisterStateExpr( "brain_freeze_active", function ()
    return buff.brain_freeze.up -- frost_info.virtual_brain_freeze
end )

spec:RegisterStateTable( "rotation", setmetatable( {},
{
    __index = function( t, k )
        if k == "standard" then return true end
        return false
    end,
} ) )

spec:RegisterStateTable( "incanters_flow", {
    changed = 0,
    count = 0,
    direction = 0,

    startCount = 0,
    startTime = 0,
    startIndex = 0,

    values = {
        [0] = { 0, 1 },
        { 1, 1 },
        { 2, 1 },
        { 3, 1 },
        { 4, 1 },
        { 5, 0 },
        { 5, -1 },
        { 4, -1 },
        { 3, -1 },
        { 2, -1 },
        { 1, 0 }
    },

    f = CreateFrame( "Frame" ),
    fRegistered = false,

    reset = setfenv( function ()
        if talent.incanters_flow.enabled then
            if not incanters_flow.fRegistered then
                Hekili:ProfileFrame( "Incanters_Flow_Frost", incanters_flow.f )
                -- One-time setup.
                incanters_flow.f:RegisterUnitEvent( "UNIT_AURA", "player" )
                incanters_flow.f:SetScript( "OnEvent", function ()
                    -- Check to see if IF changed.
                    if state.talent.incanters_flow.enabled then
                        local flow = state.incanters_flow
                        local name, _, count = FindUnitBuffByID( "player", 116267, "PLAYER" )
                        local now = GetTime()

                        if name then
                            if count ~= flow.count then
                                if count == 1 then flow.direction = 0
                                elseif count == 5 then flow.direction = 0
                                else flow.direction = ( count > flow.count ) and 1 or -1 end

                                flow.changed = now
                                flow.count = count
                            end
                        else
                            flow.count = 0
                            flow.changed = now
                            flow.direction = 0
                        end
                    end
                end )

                incanters_flow.fRegistered = true
            end

            if now - incanters_flow.changed >= 1 then
                if incanters_flow.count == 1 and incanters_flow.direction == 0 then
                    incanters_flow.direction = 1
                    incanters_flow.changed = incanters_flow.changed + 1
                elseif incanters_flow.count == 5 and incanters_flow.direction == 0 then
                    incanters_flow.direction = -1
                    incanters_flow.changed = incanters_flow.changed + 1
                end
            end

            if incanters_flow.count == 0 then
                incanters_flow.startCount = 0
                incanters_flow.startTime = incanters_flow.changed + floor( now - incanters_flow.changed )
                incanters_flow.startIndex = 0
            else
                incanters_flow.startCount = incanters_flow.count
                incanters_flow.startTime = incanters_flow.changed + floor( now - incanters_flow.changed )
                incanters_flow.startIndex = 0

                for i, val in ipairs( incanters_flow.values ) do
                    if val[1] == incanters_flow.count and val[2] == incanters_flow.direction then incanters_flow.startIndex = i; break end
                end
            end
        else
            incanters_flow.count = 0
            incanters_flow.changed = 0
            incanters_flow.direction = 0
        end
    end, state ),
} )

spec:RegisterStateExpr( "bf_flurry", function () return false end )
spec:RegisterStateExpr( "comet_storm_remains", function () return buff.active_comet_storm.remains end )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237721, 237719, 237718, 237716, 237717 },
        auras = {
            -- Spellslinger
            -- Spherical Sorcery Your spell damage is increased by $s1% $s2 seconds remaining
            -- https://www.wowhead.com/spell=1247525
            spherical_sorcery = {
                id = 1247525,
                duration = 10,
                max_stack = 1
            },
            -- Frostfire
            -- Frost mage version
            ignite = {
                id = 1236160,
                duration = 9,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229346, 229344, 229342, 229343, 229341 },
        auras = {
            extended_bankroll = {
                id = 1216914,
                duration = 30,
                max_stack = 1
            }
        }
    },
    -- Dragonflight
    tier31 = {
        items = { 207288, 207289, 207290, 207291, 207293, 217232, 217234, 217235, 217231, 217233 }
    },
    tier30 = {
        items = { 202554, 202552, 202551, 202550, 202549 }
    },
    tier29 = {
        items = { 200318, 200320, 200315, 200317, 200319 },
        auras = {
            touch_of_ice = {
                id = 394994,
                duration = 6,
                max_stack = 1
            }
        }
    }
} )

local BrainFreeze = setfenv( function()
    if talent.perpetual_winter.enabled then gainCharges( "flurry", 1 ) else setCooldown( "flurry", 0 ) end
    applyBuff( "brain_freeze" )
end, state )

spec:RegisterHook( "reset_precast", function ()
    frost_info.last_target_virtual = frost_info.last_target_actual

    local fof_remains = max( 0, latestFingersLance - query_time )
    if fof_remains > 0 then
        applyBuff( "fof_consumed", fof_remains, numLances )
        if Hekili.ActiveDebug then Hekili:Debug( "Applied fof_consumed for %.2f seconds with %d stacks.", fof_remains, numLances ) end
    end

    if numFingers > 0 then
        removeStack( "fingers_of_frost", numFingers )
        if Hekili.ActiveDebug then Hekili:Debug( "Removed %d stacks of fingers_of_frost due to buffed ice_lances in flight.", numFingers ) end
    end

    if Hekili.ActiveDebug then Hekili:Debug( "Buffed Ice Lances in-flight: %d, FoF Consumed stacks: %d, FoF Consumed Remains: %.2f, Remaining FoF: %d", numLances, buff.fof_consumed.stack, buff.fof_consumed.remains, buff.fingers_of_frost.stack ) end

    if action.flurry.in_flight then
        if Hekili.ActiveDebug then Hekili:Debug( "Flurry is in-flight, keep Winter's Chill stacks at 2." ) end
        applyDebuff( "target", "winters_chill", nil, 2 )
    end

    -- Icicles take a second to get used.
    if not state.talent.glacial_spike.enabled and action.ice_lance.time_since < gcd.max then removeBuff( "icicles" ) end

    incanters_flow.reset()

    local remaining_pet = class.auras.icy_veins.duration - action.icy_veins.time_since
    if remaining_pet > 0 then
        summonPet( "water_elemental", remaining_pet )
    end

    if  active_dot.glacial_spike > 0 and debuff.glacial_spike.down or
        active_dot.winters_chill > 0 and debuff.winters_chill.down or
        active_dot.freeze > 0 and debuff.freeze.down or
        active_dot.frostbite > 0 and debuff.frostbite.down or
        active_dot.frost_nova > 0 and debuff.frost_nova.down then
        active_dot.frozen = active_dot.frozen + 1
    end

    -- Trigger expr function for debug text.
    if Hekili.ActiveDebug then spec.stateExprs.remaining_winters_chill() end
end )

spec:RegisterHook( "runHandler", function( action )

    local ability = class.abilities[ action ]

    if buff.ice_floes.up and ability and ability.cast > 0 and ability.cast < 10 then removeStack( "ice_floes" ) end

    if talent.frostfire_mastery.enabled and ability then
        if ability.school == "fire" or ability.school == "frostfire" then
            if buff.fire_mastery.up then applyBuff( "fire_mastery", buff.fire_mastery.remains, min( spec.auras.fire_mastery.max_stack, buff.fire_mastery.stack + 1 ) )
            else addStack( "fire_mastery" ) end
        end
        if ability.school == "frost" or ability.school == "frostfire" then
            if buff.frost_mastery.up then applyBuff( "frost_mastery", buff.frost_mastery.remains, min( spec.auras.frost_mastery.max_stack, buff.frost_mastery.stack + 1 ) )
            else applyBuff( "frost_mastery" ) end
        end
    end

end )

Hekili:EmbedDisciplinaryCommand( spec )

-- Abilities
spec:RegisterAbilities( {

    -- Blasts enemies within 12 yds of you for 45 Frost damage and freezes them in place for 6 sec. Damage may interrupt the freeze effect.
    frost_nova = {
        id = 122,
        cast = 0,
        charges = function () if talent.ice_ward.enabled then return 2 end end,
        cooldown = 30,
        recharge = function () if talent.ice_ward.enabled then return 30 end end,
        gcd = "spell",
        school = "frost",

        spend = 0.02,
        spendType = "mana",

        startsCombat = true,

        usable = function () return target.distance < 12, "target out of range" end,
        handler = function ()
            applyDebuff( "target", "frost_nova" )
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            if legendary.grisly_icicle.enabled then applyDebuff( "target", "grisly_icicle" ) end
        end,
    },

    -- Ice shards pelt the target area, dealing 986 Frost damage over 7.1 sec and reducing movement speed by 60% for 3 sec. Each time Blizzard deals damage, the cooldown of Frozen Orb is reduced by 0.50 sec.
    blizzard = {
        id = 190356,
        cast = function () return buff.freezing_rain.up and 0 or 2 * haste end,
        cooldown = 15,
        hasteCD = true,
        gcd = "spell",
        school = "frost",
        spend = 0.02,
        spendType = "mana",
        terrain = true,
        toggle_terrain = "player",
        startsCombat = true,

        velocity = 20,

        usable = function ()
            if not buff.freezing_rain.up and moving and settings.prevent_hardcasts and action.blizzard.cast_time > buff.ice_floes.remains then return false, "prevent_hardcasts during movement and ice_floes is down" end
            return true
        end,

        handler = function ()
            applyDebuff( "target", "blizzard" )
            applyBuff( "active_blizzard" )

        end,
    },

    -- Resets the cooldown of your Ice Barrier, Frost Nova, $?a417493[][Cone of Cold, ]Ice Cold, and Ice Block.
    cold_snap = {
        id = 235219,
        cast = 0,
        cooldown = 300,
        gcd = "off",
        school = "physical",

        startsCombat = false,
        toggle = "defensives",

        handler = function ()
            setCooldown( "ice_barrier", 0 )
            setCooldown( "frost_nova", 0 )
            if not talent.coldest_snap.enabled then setCooldown( "cone_of_cold", 0 ) end
            setCooldown( "ice_cold", 0 )
            setCooldown( "ice_block", 0 )
        end,
    },

    -- Calls down a series of 7 icy comets on and around the target, that deals up to 3,625 Frost damage to all enemies within 6 yds of its impacts.
    comet_storm = {
        id = 153595,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "frost",
        toggle = "essences",
        spend = 0.01,
        spendType = "mana",

        talent = "comet_storm",
        startsCombat = false,

        flightTime = 2.6,

        handler = function ()
            applyBuff( "active_comet_storm" )
        end,

        impact = function ()
            -- noop.
        end,
    },


    -- Targets in a cone in front of you take 383 Frost damage and have movement slowed by 70% for 5 sec.
    cone_of_cold = {
        id = 120,
        cast = 0,
        cooldown = function() return talent.coldest_snap.enabled and 45 or 12 end,
        gcd = "spell",
        school = "frost",

        spend = 0.04,
        spendType = "mana",

        startsCombat = true,

        usable = function () return not settings.check_cone_range or target.distance <= 9, strformat( "check_cone_range enabled and distance is %d", target.distance ) end,
        handler = function ()
            applyDebuff( "target", talent.freezing_cold.enabled and "freezing_cold" or "cone_of_cold" )
            active_dot.cone_of_cold = max( active_enemies, active_dot.cone_of_cold )
            removeDebuffStack( "target", "winters_chill" )

            if talent.coldest_snap.enabled then
                if true_active_enemies >= 3 then
                    setCooldown( "frozen_orb", 0 )
                    setCooldown( "comet_storm", 0 )
                end
                applyDebuff( "target", "winters_chill" )
                active_dot.winters_chill = max( active_enemies, active_dot.winters_chill )
            end
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
        end,
    },

    -- Unleash a flurry of ice, striking the target 3 times for a total of 1,462 Frost damage. Each hit reduces the target's movement speed by 80% for 1 sec and applies Winter's Chill to the target. Winter's Chill causes the target to take damage from your spells as if it were frozen.
    flurry = {
        id = 44614,
        cast = 0,
        charges = function() if talent.perpetual_winter.enabled then return 2 end end,
        cooldown = 30,
        recharge = function() if talent.perpetual_winter.enabled then return 30 end end,
        gcd = "spell",
        school = "frost",

        spend = 0.01,
        spendType = "mana",

        talent = "flurry",
        startsCombat = true,
        flightTime = 0.5,

        handler = function ()
            removeBuff( "brain_freeze" )
            applyDebuff( "target", "winters_chill", nil, 2 )
            if Hekili.ActiveDebug then Hekili:Debug( "Winter's Chill applied by Flurry." ) end
            applyDebuff( "target", "flurry" )

            if buff.expanded_potential.up then removeBuff( "expanded_potential" )
            elseif legendary.sinful_delight.enabled then gainChargeTime( "mirrors_of_torment", 4 )
            end

            if buff.cold_front_ready.up then
                spec.abilities.frozen_orb.handler()
                removeBuff( "cold_front_ready" )
            end

            if talent.cold_front.enabled or legendary.cold_front.enabled then
                if buff.cold_front.stack < 29 then addStack( "cold_front" )
                else
                    removeBuff( "cold_front" )
                    applyBuff( "cold_front_ready" )
                end
            end

            applyDebuff( "target", "flurry" )
            addStack( "icicles" )
            if talent.glacial_spike.enabled and buff.icicles.stack == buff.icicles.max_stack then
                applyBuff( "glacial_spike_usable" )
            end

            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            removeBuff( "ice_floes" )
        end,

        impact = function()
            -- This wipes out the effect of a prior projectile impacting and wiping out a stack when Flurry will re-max it.
            if Hekili.ActiveDebug then Hekili:Debug( "Winter's Chill reapplied by Flurry impact." ) end
            applyDebuff( "target", "winters_chill", nil, 2 )
            applyDebuff( "target", "flurry" )
            applyBuff( "bone_chilling", nil, 3 )
            if talent.frostfire_mastery.enabled then
                if buff.frost_mastery.up then applyBuff( "frost_mastery", buff.frost_mastery.expires, min( buff.frost_mastery.stacks + 3, 6) )
                else applyBuff( "frost_mastery", nil, 3 ) end
                if buff.excess_frost.up then
                    removeStack( "excess_frost" )
                    spec.abilities.ice_nova.handler()
                    reduceCooldown( "comet_storm", 3 )
                end
            end
        end,

        copy = 228354 -- ID of the Flurry impact.
    },

    -- Places a Frost Bomb on the target. After 5 sec, the bomb explodes, dealing 2,713 Frost damage to the target and 1,356 Frost damage to all other enemies within 10 yards. All affected targets are slowed by 80% for 4 sec.
    frost_bomb = {
        id = 390612,
        cast = 1.33,
        cooldown = 15,
        gcd = "spell",
        school = "frost",

        spend = 0.01,
        spendType = "mana",

        pvptalent = "frost_bomb",
        startsCombat = false,
        texture = 609814,

        handler = function ()
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
        end,
    },

    -- Launches a bolt of frost at the enemy, causing 890 Frost damage and slowing movement speed by 60% for 8 sec.
    frostbolt = {
        id = 116,
        cast = function ()
            if buff.frostfire_empowerment.up then return 0 end
            return 2 * ( 1 - 0.04 * buff.slick_ice.stack ) * haste
        end,
        cooldown = 0,
        gcd = "spell",
        school = "frost",

        spend = 0.02,
        spendType = "mana",

        notalent = "frostfire_bolt",
        startsCombat = true,
        velocity = 35,

        max_targets = function() return talent.fractured_frost.enabled and buff.icy_veins.up and min( 3, active_enemies ) or 1 end,

        usable = function ()
            if moving and settings.prevent_hardcasts and action.frostbolt.cast_time > buff.ice_floes.remains then return false, "prevent_hardcasts during movement and ice_floes is down" end
            return true
        end,

        handler = function ()
            addStack( "icicles" )

            if buff.frostfire_empowerment.up then
                if talent.flash_freezeburn.enabled then
                    applyBuff( "frost_mastery", nil, 6 )
                    addStack( "excess_frost" )
                    applyBuff( "fire_mastery", nil, 6 )
                    addStack( "excess_fire" )
                end
                removeBuff( "frostfire_empowerment" )
            end

            if talent.glacial_spike.enabled and buff.icicles.stack == buff.icicles.max_stack then
                applyBuff( "glacial_spike_usable" )
            end

            if talent.deaths_chill.enabled and buff.icy_veins.up then
                addStack( "deaths_chill", buff.icy_veins.remains, action.frostbolt.max_targets )
            end


            if buff.cold_front_ready.up then
                spec.abilities.frozen_orb.handler()
                removeBuff( "cold_front_ready" )
            end

            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            if talent.slick_ice.enabled or legendary.slick_ice.enabled then addStack( "slick_ice" ) end

            if talent.cold_front.enabled or legendary.cold_front.enabled then
                if buff.cold_front.stack < 29 then addStack( "cold_front" )
                else
                    removeBuff( "cold_front" )
                    applyBuff( "cold_front_ready" )
                end
            end

            if azerite.tunnel_of_ice.enabled then
                if frost_info.last_target_virtual == target.unit then
                    addStack( "tunnel_of_ice" )
                else
                    removeBuff( "tunnel_of_ice" )
                end
                frost_info.last_target_virtual = target.unit
            end
        end,

        impact = function ()
            applyDebuff( "target", "chilled" )
            if not action.flurry.in_flight then removeDebuffStack( "target", "winters_chill" ) end
        end,

        bind = "frostfire_bolt",
        copy = { 116, 228597 }
    },


    -- Launches a bolt of frost at the enemy, causing 890 Frost damage and slowing movement speed by 60% for 8 sec.
    frostfire_bolt = {
        id = 431044,
        cast = function ()
            if buff.frostfire_empowerment.up then return 0 end
            return 2 * ( 1 - 0.04 * buff.slick_ice.stack ) * haste
        end,
        cooldown = 0,
        gcd = "spell",
        school = "frostfire",

        spend = 0.02,
        spendType = "mana",

        talent = "frostfire_bolt",
        startsCombat = true,
        velocity = 35,

        max_targets = function() return talent.fractured_frost.enabled and buff.icy_veins.up and min( 3, active_enemies ) or 1 end,

        usable = function ()
            if moving and settings.prevent_hardcasts and action.frostfire_bolt.cast_time > buff.ice_floes.remains then return false, "prevent_hardcasts during movement and ice_floes is down" end
            return true
        end,

        handler = function ()
            addStack( "icicles" )

            if buff.frostfire_empowerment.up then
                if talent.flash_freezeburn.enabled then
                    applyBuff( "frost_mastery", nil, 6 )
                    addStack( "excess_frost" )
                    applyBuff( "fire_mastery", nil, 6 )
                    addStack( "excess_fire" )
                end
                removeBuff( "frostfire_empowerment" )
            end

            if talent.glacial_spike.enabled and buff.icicles.stack == buff.icicles.max_stack then
                applyBuff( "glacial_spike_usable" )
            end

            if talent.deaths_chill.enabled and buff.icy_veins.up then
                addStack( "deaths_chill", buff.icy_veins.remains, action.frostfire_bolt.max_targets )
            end


            if buff.cold_front_ready.up then
                spec.abilities.frozen_orb.handler()
                removeBuff( "cold_front_ready" )
            end

            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            if talent.slick_ice.enabled or legendary.slick_ice.enabled then addStack( "slick_ice" ) end

            if talent.cold_front.enabled or legendary.cold_front.enabled then
                if buff.cold_front.stack < 29 then addStack( "cold_front" )
                else
                    removeBuff( "cold_front" )
                    applyBuff( "cold_front_ready" )
                end
            end

            if azerite.tunnel_of_ice.enabled then
                if frost_info.last_target_virtual == target.unit then
                    addStack( "tunnel_of_ice" )
                else
                    removeBuff( "tunnel_of_ice" )
                end
                frost_info.last_target_virtual = target.unit
            end
        end,

        impact = function ()
            applyDebuff( "target", "chilled" )
            if not action.flurry.in_flight then removeDebuffStack( "target", "winters_chill" ) end
            applyDebuff( "target", "frostfire_bolt" )
        end,

        bind = "frostbolt"
    },

    -- Launches an orb of swirling ice up to 40 yards forward which deals up to 5,687 Frost damage to all enemies it passes through. Deals reduced damage beyond 8 targets. Grants 1 charge of Fingers of Frost when it first damages an enemy. While Frozen Orb is active, you gain Fingers of Frost every 2 sec. Enemies damaged by the Frozen Orb are slowed by 40% for 3 sec.
    frozen_orb = {
        id = 84714,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "frost",

        spend = 0.01,
        spendType = "mana",

        talent = "frozen_orb",
        startsCombat = true,

        toggle = "essences",
        -- velocity = 20,
        flightTime = 12,

        handler = function ()
            applyBuff( "frozen_orb" )
            if talent.freezing_rain.enabled then applyBuff( "freezing_rain" ) end
            if talent.permafrost_lances.enabled then applyBuff( "permafrost_lances" ) end
        end,

        impact = function() end,

        --[[ Not modeling because you can throw it off in a random direction and get no procs.  Just react.
        impact = function ()
            addStack( "fingers_of_frost" )
            applyDebuff( "target", "frozen_orb_snare" )
        end, ]]

        copy = 198149
    },

    -- Conjures a massive spike of ice, and merges your current Icicles into it. It impales your target, dealing 3,833 damage plus all of the damage stored in your Icicles, and freezes the target in place for 4 sec. Damage may interrupt the freeze effect. Requires 5 Icicles to cast. Passive: Ice Lance no longer launches Icicles.
    glacial_spike = {
        id = 199786,
        cast = 2.75,
        cooldown = 0,
        gcd = "spell",
        school = "frost",

        spend = 0.01,
        spendType = "mana",

        talent = "glacial_spike",
        startsCombat = true,
        velocity = 40,

        usable = function()
            if moving and settings.prevent_hardcasts and action.glacial_spike.cast_time > buff.ice_floes.remains then return false, "prevent_hardcasts during movement and ice_floes is down" end
            return buff.icicles.stack == 5 or buff.glacial_spike_usable.up, "requires 5 icicles or glacial_spike!"
        end,

        handler = function ()
            removeBuff( "icicles" )
            removeBuff( "glacial_spike_usable" )

            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            if talent.thermal_void.enabled and buff.icy_veins.up then buff.icy_veins.expires = buff.icy_veins.expires + ( debuff.frozen.up and 4 or 1 ) end
        end,

        impact = function()
            applyDebuff( "target", "glacial_spike" )
            if not action.flurry.in_flight then removeDebuffStack( "target", "winters_chill" ) end
        end,

        copy = 228600
    },

    -- Shields you with ice, absorbing 5,674 damage for 1 min. Melee attacks against you reduce the attacker's movement speed by 60%.
    ice_barrier = {
        id = 11426,
        cast = 0,
        cooldown = 25,
        gcd = "spell",
        school = "frost",

        spend = 0.03,
        spendType = "mana",

        talent = "ice_barrier",
        startsCombat = false,
        toggle = "defensives",
        handler = function ()
            applyBuff( "ice_barrier" )
            if legendary.triune_ward.enabled then
                applyBuff( "blazing_barrier" )
                applyBuff( "prismatic_barrier" )
            end
        end,
    },

    -- Quickly fling a shard of ice at the target, dealing 477 Frost damage. Ice Lance damage is tripled against frozen targets.
    ice_lance = {
        id = 30455,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "frost",

        spend = 0.01,
        spendType = "mana",

        talent = "ice_lance",
        startsCombat = true,
        velocity = 47,

        aura = function()
            if buff.fingers_of_frost.up then return end
            return "frozen"
        end,

        cycle_to = function()
            if buff.fingers_of_frost.up then return end
            return true
        end,

        handler = function ()
            applyDebuff( "target", "chilled" )

            if not talent.glacial_spike.enabled then removeStack( "icicles" ) end
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end

            if azerite.whiteout.enabled then
                cooldown.frozen_orb.expires = max( 0, cooldown.frozen_orb.expires - 0.5 )
            end

            if buff.fingers_of_frost.up or debuff.frozen.up then
                if talent.chain_reaction.enabled then addStack( "chain_reaction" ) end
                if talent.thermal_void.enabled and buff.icy_veins.up then
                    buff.icy_veins.expires = buff.icy_veins.expires + 0.5
                    pet.water_elemental.expires = buff.icy_veins.expires
                end

                if buff.fingers_of_frost.up then
                    removeStack( "fingers_of_frost" )
                    addStack( "fof_consumed" )
                end

                if talent.hailstones.enabled then
                    addStack( "icicles" )
                    if talent.glacial_spike.enabled and buff.icicles.stack_pct == 100 then
                        applyBuff( "glacial_spike_usable" )
                    end
                end

                if talent.cryopathy.enabled then addStack( "cryopathy" ) end
                if set_bonus.tier29_4pc > 0 then applyBuff( "touch_of_ice" ) end
            end
        end,

        impact = function ()
            removeDebuff( "target", "frozen" )

            if talent.frostfire_mastery.enabled then
                if buff.excess_fire.up then
                    removeStack( "excess_fire" )
                    addStack( "excess_frost" )
                    -- BrainFreeze() currently nerfed to 50% chance, cannot predict
                end
            end

            if buff.fof_consumed.up then
                if Hekili.ActiveDebug then Hekili:Debug( "Fingers of Frost consumed by Ice Lance." ) end
                removeStack( "fof_consumed" )
            else
                if action.flurry.in_flight then
                    if Hekili.ActiveDebug then Hekili:Debug( "Winter's Chill not consumed by Ice Lance because Flurry is in-flight." ) end
                else
                    if Hekili.ActiveDebug then Hekili:Debug( "Winter's Chill consumed by Ice Lance." ) end
                    removeDebuffStack( "target", "winters_chill" )
                end
            end
        end,

        copy = 228598
    },

    -- Talent: Causes a whirl of icy wind around the enemy, dealing 1,226 Frost damage to the target and reduced damage to all other enemies within 8 yards, and freezing them in place for 2 sec.
    ice_nova = {
        id = 157997,
        cast = 0,
        cooldown = 25,
        gcd = "spell",
        school = "frost",

        talent = "ice_nova",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "ice_nova" )
        end,
    },

    -- Conjures an Ice Wall 30 yards long that obstructs line of sight. The wall has 40% of your maximum health and lasts up to 15 sec.
    ice_wall = {
        id = 352278,
        cast = 1.33,
        cooldown = 90,
        gcd = "spell",
        school = "frost",

        spend = 0.08,
        spendType = "mana",

        pvptalent = "ice_wall",
        startsCombat = false,
        texture = 4226156,

        toggle = "interrupts",

        handler = function ()
        end,
    },

    -- Accelerates your spellcasting for 25 sec, granting 30% haste and preventing damage from delaying your spellcasts. Activating Icy Veins grants a charge of Brain Freeze and Fingers of Frost.
    icy_veins = {
        id = function ()
            return pvptalent.ice_form.enabled and 198144 or 12472
        end,
        cast = 0,
        cooldown = function () return ( essence.vision_of_perfection.enabled and 0.87 or 1 ) * 180 end,
        gcd = "off",
        school = "frost",

        toggle = "cooldowns",

        startsCombat = true,

        handler = function ()
            summonPet( "water_elemental" )

            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
            if talent.cryopathy.enabled then addStack( "cryopathy", nil, 10 ) end

            if talent.flash_freezeburn.enabled then applyBuff( "frostfire_empowerment" ) end

            if pvptalent.ice_form.enabled then applyBuff( "ice_form" )
            else
                if buff.icy_veins.down then stat.haste = stat.haste + 0.30 end
                applyBuff( "icy_veins" )
            end

            if azerite.frigid_grasp.enabled then
                applyBuff( "frigid_grasp", 10 )
                addStack( "fingers_of_frost" )
            end
        end,

        copy = { 12472, 198144, "ice_form" }
    },

    -- Channel an icy beam at the enemy for 4.4 sec, dealing 1,479 Frost damage every 0.9 sec and slowing movement by 70%. Each time Ray of Frost deals damage, its damage and snare increases by 10%. Generates 2 charges of Fingers of Frost over its duration.
    ray_of_frost = {
        id = 205021,
        cast = 5,
        channeled = true,
        cooldown = 60,
        gcd = "spell",
        school = "frost",

        spend = 0.02,
        spendType = "mana",

        talent = "ray_of_frost",
        startsCombat = true,
        texture = 1698700,

        toggle = "cooldowns",

        start = function ()
            applyDebuff( "target", "ray_of_frost" )
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
        end,
    },

    -- Summons a Ring of Frost for 10 sec at the target location. Enemies entering the ring are incapacitated for 10 sec. Limit 10 targets. When the incapacitate expires, enemies are slowed by 65% for 4 sec.
    ring_of_frost = {
        id = 113724,
        cast = 2,
        cooldown = 45,
        gcd = "spell",
        school = "frost",

        spend = 0.08,
        spendType = "mana",

        talent = "ring_of_frost",
        startsCombat = false,

        handler = function ()
        end,
    },

    -- Talent: Draw power from the Night Fae, dealing 2,168 Nature damage over 3.6 sec to enemies within 18 yds. While channeling, your Mage ability cooldowns are reduced by 12 sec over 3.6 sec.
    shifting_power = {
        id = function() return talent.shifting_power.enabled and 382440 or 314791 end,
        cast = 4,
        channeled = true,
        cooldown = 60,
        gcd = "spell",
        school = "nature",
        toggle = "cooldowns",

        spend = 0.05,
        spendType = "mana",

        startsCombat = true,


        usable = function ()
            if moving and settings.prevent_hardcasts and action.shifting_power.cast_time > buff.ice_floes.remains then return false, "prevent_hardcasts during movement and ice_floes is down" end
            return true
        end,

        cdr = function ()
            return - action.shifting_power.execute_time / action.shifting_power.tick_time * ( -3 + conduit.discipline_of_the_grove.time_value )
        end,

        full_reduction = function ()
            return - action.shifting_power.execute_time / action.shifting_power.tick_time * ( -3 + conduit.discipline_of_the_grove.time_value )
        end,

        start = function ()
            applyBuff( "shifting_power" )
        end,

        tick = function ()
            local seen = {}
            for _, a in pairs( spec.abilities ) do
                if not seen[ a.key ] and ( not talent.coldest_snap.enabled or a.key ~= "cone_of_cold" ) then
                    reduceCooldown( a.key, 3 )
                    seen[ a.key ] = true
                end
            end
        end,

        finish = function ()
            removeBuff( "shifting_power" )
        end,

        copy = { 382440, 314791 }
    },

    -- Summon a strong Blizzard that surrounds you for 6 sec that slows enemies by 80% and deals 246 Frost damage every 1 sec. Enemies that are caught in Snowdrift for 3 sec consecutively become Frozen in ice, stunned for 4 sec.
    snowdrift = {
        id = 389794,
        cast = 1.33,
        cooldown = 60,
        gcd = "spell",
        school = "frost",

        spend = 0.02,
        spendType = "mana",

        pvptalent = "snowdrift",
        startsCombat = true,
        texture = 135783,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "snowdrift" )
            if talent.bone_chilling.enabled then addStack( "bone_chilling" ) end
        end,
    },

    splinterstorm = {

    }, -- TODO: Support action.splinterstorm.in_flight

    --[[ Summons a Water Elemental to follow and fight for you.
    water_elemental = {
        id = 31687,
        cast = 1.5,
        cooldown = 30,
        gcd = "spell",
        school = "frost",

        spend = 0.03,
        spendType = "mana",

        startsCombat = false,

        notalent = "lonely_winter",
        nomounted = true,

        usable = function () return not pet.alive, "must not have a pet" end,
        handler = function ()
            summonPet( "water_elemental" )
        end,

        copy = "summon_water_elemental"
    }, ]]

    -- Water Elemental Abilities
    freeze = {
        id = 33395,
        known = true,
        cast = 0,
        cooldown = 25,
        gcd = "off",
        school = "frost",
        dual_cast = true,

        startsCombat = true,

        usable = function ()
            if target.is_boss then return false, "target is a boss" end
            if not pet.water_elemental.alive then return false, "requires water elemental" end
            return true
        end,

        handler = function ()
            applyDebuff( "target", "freeze" )
        end
    },

    water_jet = {
        id = 135029,
        known = true,
        cast = 0,
        cooldown = 20,
        gcd = "off",
        school = "frost",

        startsCombat = true,
        usable = function ()
            if not settings.manual_water_jet then return false, "requires manual water jet setting" end
            return pet.water_elemental.alive, "requires a living water elemental"
        end,
        handler = function()
            BrainFreeze()
        end
    }
} )

spec:RegisterRanges( "frostbolt", "polymorph", "fire_blast" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = true,
    nameplateRange = 20,
    rangeFilter = false,

    damage = true,
    damageExpiration = 6,

    potion = "tempered_potion",

    package = "冰法Simc",
} )


spec:RegisterSetting( "prevent_hardcasts", true, {
    name = strformat( "%s, %s, %s: 移动时仅瞬发", 
        Hekili:GetSpellLinkWithTexture( spec.abilities.blizzard.id ),
        Hekili:GetSpellLinkWithTexture( spec.abilities.glacial_spike.id ),
        Hekili:GetSpellLinkWithTexture( spec.abilities.frostbolt.id )
    ),
    desc = strformat( "如果勾选，当你在移动时，不会推荐非瞬发的 %s 和 %s。\n\n如果 %s 被天赋强化并且处于激活状态，" ..
                      "并且施法会在 %s 效果结束之前完成，那么会有一个例外情况。",
        Hekili:GetSpellLinkWithTexture( spec.abilities.blizzard.id ),
        Hekili:GetSpellLinkWithTexture( spec.abilities.glacial_spike.id ),
        Hekili:GetSpellLinkWithTexture( spec.abilities.frostbolt.id ),
        Hekili:GetSpellLinkWithTexture( 108839 ),
        Hekili:GetSpellLinkWithTexture( 108839 )
    ),
    type = "toggle",
    width = "full"
} )

spec:RegisterSetting( "check_cone_range", true, {
    name = strformat( "%s: 范围检测", Hekili:GetSpellLinkWithTexture( spec.abilities.cone_of_cold.id ) ),
    desc = strformat( "如果勾选，当你距离目标超过10码时，%s 将不会被推荐。\n\n" ..
        "如果你与目标超出距离范围，此设置可能会适得其反，因为它会浪费来自 %s 的冷却时间重置效果。",
        Hekili:GetSpellLinkWithTexture( spec.abilities.cone_of_cold.id ),
        spec.abilities.cone_of_cold.name ),
    type = "toggle",
    width = "full"
} )

spec:RegisterPack( "冰霜Simc", 20250606, [[Hekili:T31xpUnsY9plchGSM12YIASgBFqAcqYtXazFzsEvC4q1AeHLiviPg7zHGWMeKlhwKaKaKGaKeGGna5WHdB(dW9YMf3I8Hj2oopLVcP6U5F6UzxnBsXz3jE3x21dz3vxD1v)R(vv3sAUZ8F)5xSWlLm)thpA8KrN54mC8OrpZzY8lsVDlz(fB98FL31W)i0Bd8FF3p7F)9)6)Mlc24tF1TRJ8wqfrs0UyF41Rst3M8tFYtUoiD1URg6hT5jjbB2T2lnik0p2Bzk9V9FY8lUAxW60F3W5xPD8h985x4TlDvu88lGb73bKCWIfeEZjjWGtB(JhD2Jhn5NE4Y)GTuzC4LhEj)Xp9XJD0(4rNP5XN(4t116t1l7XpE8ZGhdkQZWrhUKAkoC5owJMFX6GK0eQbXFnX7gI7YLWF8PmRmj07Q1KfZ)THxghKsId8aBS3Asy6WfeV0vjU(RcwVEywdpCz)dxE1ULlhg4FR7nKGWKHXKnEW))WLNF4YxWAWGS2ijHKuyr7WLtpC5tpC5(9gAYmwta507WLE(0fPHlJJssxgetCVkAD6WGq3LRdUEv6HlpbwtyTz(fYnAEkS8HohxgtiFg95SbABm5g3R9xawVRx75h4T2nzBWRiIYgApHkZtpszYEj3MfeET7RdcHUNzbyZ9rSwSGWSpsVE4IOxhMBzyYpA5s2yKPEfQBGpXnm6gpQc)uuf2Okw3qSC9U44BPdWe0byqHZsa47Li4dmH7dadsM3MKcu6UDsNyUgiTCi7NWveHxd4dKu3K0O4nYUxft4ZUZNWmHqEJpjjXLQPd3TT6ZPtd4f60WNH7Ks324kUN1zex1I9cwuklbRavGpNkqHnAFgj0nk(kXbbA1lqhwMIZCHORIWqfMpLYmhupwFV1RjX52IYX7Q1bF2N5fVGoeoJmpgkwEWbzsPGK3CtLgokOjFoNsrg7DlSfHVyWKioMtMni35JSzB0RjXBOZ(mBrpTR8Mq4CWHJ8JIwt3bGav7W34u0QYfvDnBGORRGVrPJl1fQqyITqvANuvGIgrejk1KkIS0eLSkyzkDvJzCzMiCaq(kc0A6YBH0PlgSne69aKrzx7f6ZDLMOSfrCLsABc8NEre3KeRcd7dgascymd92kfgUN(fVmxPb4yAk4DL9v2HaBnCI2Lq9SfkIZRXhCkJUGrMaNt3RnrA91pkKqxQOMLMeIFGPiY2Hm3m2ahBmll4Kua3J7HlBe0ht)oLUIEoj4ugYwd2fsIJzBJJJwcy6Kq)BL8(td2a62Jlyik6xmCThSHzxcTPtlGWSThGl(Z0R1Nzvqq8yVOH64EGzVwokPXGHpVUH6oJdVZ46jXtBtvw81rGppY2len2ISrKT2g4dKzds2UM5vYnPYErOo2vnrYoZvc7JJJJrlj3mxcIZ2pxx4h(lL3xleQN7TclOElUvY4wL7do0PDuhaDxHn5d5W1NlPrvKG5O14iQDA0ACiZobSReBwdVGQuc(uh1Ckk88bGcx(F4stKNNoVlVWhBIUHq5pYjvSjin4AwrnkiwuyN3swVojL4TwzChl2kyMdc01FxCcrPDwrZKWXsfDvoBK4M41ly0ymhYkB)cWCYdcbaGKfHexb6F6QHB9byJPWQXQTUx7TvEfoRtMdYOxqI761m6st083QFBrSh4K6Ym6UB8UoWphGp(AagBJMxTikT6dffZ2v3MGjhX3vkO8NkSDBJhKvHGfcpr26SqBcIJJIDdaTLuAIyV6Aa7bKIBq4nbjbxfSoi9w3fKLKWe1Mw4YiMP(9wJNWu2CCEdgVmOJv3UnkDfK8xGNIj5hGg2CL1mJgdgvZqqoJhjs(fi4M3SFqB11nV4XrGWl1vI4UQoxhrS2C7R5S66YY(HZxQRmhAk(t1NBOSFgQnD7k7xTrPBsX2WJh3YATHh(Y2PRqsCgr0TJq8h)1sdhEUljN)IkmMXRKw2zAvxX06OJ6W2QnzrXBSOeswx8MJfgTE11UduY8OuVwQIwZxXRUmGJKO3nSeFAmIlhousRlrGcuko4YaZPld7lpnd8sz8O7UobdmdFRQOvMzsRFUOI8wZb9CFSAh41jYoW9E619(3v1bP2dg4oR2ENj4SHuAVZYnj8jqZQSNHcpzQeOSHSPNw43LvtQ6KvPgpQWwfifnOgpSc08X494OuLwICePOCc(EoW8D1rNyf3e7cm3r0F(XB6rNpHp2u((H7n9adMi3NwJL1ecsDNGtxfQyCdsUHES)1KyZXs5UXvqHVtQHfiPRirJdjF3qI2ke1mdakz5AYwPljlBIbmow29scW4aBD52rv0oTe3ub7AbVn6f(57B(A1DBBMLlhR4R1o2y1DPMQ5Al1dTUy8earChvI9L3qKBqvMW6BDb9SOuDIiAYxGPwWYu62quL3A3EBGKwd63ORrZZ1ttvcp8kf)iERAJoR(Q8HS(WCwfO0qGwZ0knc9AljTLwwO6kKEek9fUV6UTMGhnTrU7Ult4mkhiP1cEBIMTjvQAUudfGhS1KRq94o5IgHtAOo6On7OxQ7wjFejGyOelhXMkTJuDxK3ooHaCEB2ryYYOhD5XbzIqvLRy0DdJkNN1GeCwqw6TdEU69vYpAhBKOhETczmP8NKUtgYTt1TKZklfGc8xrIJ2L4Mg7fMSjifgOsjI1anXv5sKA1cdOnFJxON7vE0MlKnaY7nMxanu2nKT3SfS0e62BUdmhFkjnoWNAOTLiA51cZQSa4JPLc3FrI5asfbcKiskcnsf9nWE2qYMac1xgqhonFkdSObdO2jD8Uqu1kJUTnrWALM1s1Iv92sDdpKxpHiOnt9ASoL9rrWQiCnqzkiC0(fXYYCBoE4rOCTuZuQcV5aSTATKFuLnuTkplCZXLRxDA)Ig)YdzoAD9JFlhC26sPgyeG1Os04rMxPowmnitaignGZxjQMxSVhWkLgefym7RwMbvxOiGEscr4aWVXduE4T0)16DW)d86Op01ySn3cfcyQNiCosSQtySIezmnbN81re1sZv88krLls2Zqe5Red2lKrS2fj0YfOdcCSUy1LsLgfMFlcZQjiQyux3iVz76OKS4OY3QBM)dn5xLP8zQMfonjvAq0OOAwiY7ikPfHvQOKeDz3mfMJJz1JJEli)Kdxs(d3fSDlzbKTYTBafMsN71KResITm)5mUT83XPPM7coKUBjzRxwDzqLArfzmrzw4ZtsnnBSssSYSCLLiNpSzAFA21LB0LNjwARZUQP8ImPPyZskyzr7WfOZOj6KOGYft2gfNk(jMJUGxy3nu0qh1CMrSsY5zlAwvSrAyDx47VzljEjG556L4tcxaBdU1nHeVBJg8gtkRDg)cY54dRgqICL9QDXaydGi9QWOxdVJMBXDOsQz40KDqruiV0LEGhFA0BccLIQYkmxw1g5swUTgz)BQ4YLd(2O0m8VAkbLExEkSYgV3WaIgN7HwTEmNkxRwre0mPQJzFbyC2XXq)k5ioyl)H)EEH78wd(6RO3JA6nkkAdVwMZg9Odx(6vb(RG)Ef8QKGnGASlHq38KM9qVflIcHU7fggLw1QdZTrdhRnwY08qsyNIqizxmTwn3cb3sODCfngHe6UwzAUUJn3netpmNzGPDdcv9gmNUqx2KuYLVy326OOfUl3rxZKcEwxrRmDuiMWDRFtQZebRtHEcWCK4xr5LwqVwKaaBEOofKUyqu7jWRemY0CQRWcqm7WpIoOOsvcRaDc2XgCusT94rS9ax((64rEkcn5pEpEe880STw9Yhpsnr56UJhX4D69ioHeLDnY3LgrKtB(OGF)44tQ5cdDmhabEWPJWTv7iv3veQJpaI6(QKPJkyVCKmZfSxOcl)4hqmv)JpU(aIzZUAdx1alHjKrUB6hSJ25XR(94HbhE4b3aIJ2YSVmahD28lETxmDWsMFXh(x(fV7V6l(F)n)DV7F738U)0)5h4Vi5bV7N)3(HV8x()8p85F4x8h92V(ZF7383)H)SF17(IF5B)p)xF)F9)X)1N)hF4L)3F1xn(dF5Fo0Vp8TF17)l(NEqACq4RiPOPGx(z3IBrFWB)6V5b2M4(dE)x9LSH9WlF)p)V8DFX)ixzF738ZCE6B)6F17)Ip)d)jFlxRznJ99fGpyNEkTAMrldwxCBGtgwunXho7jQf08Wl11Q8Ag9iAEgZSRkLpIvHZzoJPkDMqbrjEUGIpx8CafFEEAhghA8oO)S7KuiLdhJ3VYJC7r86ipZ5rblN1t8q963JLEBTYc8OO9v(05e7MszP59INgH0ORTG39P9Sm1YZNDA)E8IVx7qiKUsRghlhg(5tjBhTCiQv2fhHtJNaZg3m70rnswoqfh)tZnwZgxR0zb9Tq7BKzXwHAPmzNcJfZEbqLHCp4zprUfcQIygW91NA95VO)aKSLN(I97rE1Sx0VhxlqtF(ev9KHbwsnxqnfpJK(d0ZBz)(E4xFYt6pqkO95oJ2VNIrDs)EOxtY(gUKlGa6B6ARaVxZ0JNYkDIvKABFewyv7CEsTYDVNMCIrKzFA(7poBvrFU7N)CTADEY5pkJaXSrwOe90MsU0YNeFW(ieDMnQpkp4971pv15BvUiYuETUdiMDg7kAV0NJnaJHKBTg5LNyRG7DzA073Rl1zTBukggQGgyml4ZNSFVHSFpPV1gdXBYNWeq52bITsQrGsEafwyPujMnr3IjJ2V2LKDB7RlLbJcPfUEyBuKGznM6C)E6s5PQyLpiqrctAqRfXL0dBnOx17JNK)HoWmDBOQUZqtomGRK1odvdKv2ibgz3xJN13CHs0nvAzmbzj8DDGbv9))phDOYCPbHiQUk0bXjKfQyWIbwgTOWpu5JPiYq8DBKef79rGIJjPw4Ny01UZWZRZDPDGNM0yzeuEYMwsYwlR4DgiFlxRXSEyMI8KtkJfjI4Mbcxb52a885ZCMCIMPQoWvuigidcD1PuRCpg3T(OvTT6a1oS9Jg5SgnjZmP7lYylILmfiHuFRo)zAxpl((8U6lpAM15db)dkz3rRWzmoVcNXYelmMJC22xKSezV94yORo5q8fSI1E)YqjfFKArb02VV07wGDR43bo6SfnLASCvaEOZKZXBVUXRRqT7gGetEV6CC0xp3SBlRyOc)fwxGzMHikjroY)0th)WXJ(eKRozw0IkxgZ97h0RYLWC)EePCIGdw1yf09CgE9ybQy6VOLtzj98t(j532HCRYIixSY8N6L8QkehN68CyEXwb9JVDBAGVl8004DzsnVz)wSMasg24ZCdcjVbKpaoEdj(AaAL4Uii)FQ0lag2lmLvi)LrqlaIjbj0d2PWxE6GmqgLjl5ne)DPexkE8dD(Km0crqKtm7wiVMG4nmEuFknq0a7ouWZQDZz0eX(HCXqpF2PJpjd8vZMEGXAtpaQZNmQMzn(DVuanuNQGBCmpGvVhL3rdK01QKfab8mKQMjVx8BlPbL4fQ9OOj4DAkfoyJ3B(KXQ1R90861cBjpCzNEJhv1ZsizQaNoA4yLduyQWjkO1gICBdPISIKWYrTnRGgSSSvWQGzbH3e9k6T)h2gecQmTZ85adEaqQwUlrCDw(XzrHAICbODazcCWaF5KDB2KfbHk7QVsjkhx2L3PYkVHKFlgn5xIqGBkYUgNjAT50KSyAI6lKViKsrvZpNShE3vbRNIZ08P1xblmD1yfQqsHruc6ZIPltyrBkritNI93OkqBe2GQCGNoblLYwnfhSf7(8yrHU6cLMZ1OjfPrCuvk0uDvksz3sL0(eFVyMFCw5kf)QFL8b1liRsSrFxvt8cBf2XwaHSjsRQ1KOKBAos3jhFqz3eTtc9t33BZYN7GkGsxKhg(kGMtF4(p(DJobIJhIVIy(EhNV6e7yb7niXMbE2Mj7rH43zAEZH9Rm0ne7x32TkbaQ0OJkkGf7WpgazTBv6ceSA0Bzym)8BrvxSZqsyTc)qucnOq3TzNuZuMsBdUeX1c1nTYLJtDsxJtq2bhQV)kBRqujZf1vEzu88pnuEnw(4kID32QbR1wsAr7dZqBVcAf)S7WcplQlnLxvVQAvBRhTYAwxFEfNHtc5mlpTcrnuZ5YiHmBb5CB3TyfKPwRhYgmRlzE(ZY0t2xEecoOeHVMjq7e7JSMUxkDITs3YIE6o8wQeUr4YcpwRqv)MFGkU8VajG93wkfEKg6P2HoTyRzI2k2nJ9iiK0Maago13JHK1XovAo3Q8rSHuQY7MviOv7wlYUTW00OlvtEVAk6691SwZNpDf4LGvf5sFZyeES(L3J2I1jZNMVptAynUztF6lTZ9xQRDLpJQ(G44W(eg8WJL9Bd8cOkWjvh)UGvBXCPZy0MlXAzZwTlwH52iwRA0RMcy2H0rZvHUYFvyXtLCwHpsTeZeC)l(eRrntf)AbJ0GyHFOGrAsXp2Vkwz5FGop)Sri9N2YSFPALOik(ZYB)YFtqNol73du9st8h(wQ4Q2X(6hbjnx5h9xwmZk)8EsVevA(P9C)ELFwpPOAQ)KEwTV5px9NYZtWMOcFqinnrR8dEk)X1(JDAPzQ4h607D2GCTdz(J8tW7h)2fDtceBe(gwNXJ4vCAy5VJUFez6yFKVN))b]] )

spec:RegisterPack( "冰霜官方一键宏Simc", 20250612, [[Hekili:TZZ2UTXXz)SqeaArBhwUuIkwaKSa9UgGMBuVMlxUCO4cThy3dsMbeeQjiNmsQtqnslAdqqk(tqqGJZ)LogoTpmvsw(Q8k0VzM9WmZoZWLuYjQX9gFyNz(onFNNHZaJb)(b7p2kgn4nA3QDNw7ASxtJD2E3wBpy)45Zqd2FML9Hwha)dFlp4pp7D))F(N9zN9O)65F63F6Jp55p4rN9O7VVJNnEMZDdSgJHyuqsOnm7Jdo2nXAW(JsCCJ)T(dgvgzBV9o70zW(wjXtdclwXuNXJr0fGIaGFX39LyS8Sh81p)KhC6JFYZp5TE(78rc0Xp(0p887)XN(p)7x8EFZz37RF27)UND)pb(4zV39p9P)FN(4)05FWF(8p9BF23(bNDVp)I3(hgSVRtuCeMITDrwhHmNmb(pVbrQG8Tg5Igp43adg6eJcDaYAsic9M4VVCy9LdNfIoY8a7XnnAEGRLTJLRz0mNdbg3Yo2jWpD(ObXahFjHjzWqKNLJVJ)bMh74dlpY0EQJR7YH9woSfzgJrJsMmPj3WnhhCSpz0APWpyYecosjVCY1Xgz6hCKfMG3wnb7CW0ytkTeTCy)LdnaKVybqFwoJlGMDGhk2mkoi0ddWDWaSqWe8MiFZGWrSibMvhLO1oiWfZjnDSNBEecWDtrAayX8zvGbztBlIWi2Yf5h3KHqBMIAk)Kdm2zicTgLbyO1CqgBcKquSciYnLsGSqqfn1zsmEhFwWXOqqcfdJfGmJI0RPMZAUGbeq6(wZkOeQQGmrvYSmUHrrKH7PCbZyfRLx8RsI1rQaBmYkEAM6kNaJOolzhV7YH7XmdoaefdoTaSbwfgD4KM2b(iSyhlwwhRYT0zyIjIcwHBWcEPHmNcASX4qVC72xO(lK7uyNvPVL4JcdjQRHbtCSDq(2Z507ID8aA7vxoKc(MS7inDTav1Ki8u7MBQw1vakxVMCQUtL88Sl7Sy9DXnnW8ZZj25alY8YmbZTwNHCDJIrwUcaVn7SGTLaiyJDsyesyEQ1iyC)HO8oRz1UTyPD3XedE97yPwwiZrwWwgkSimXuG(JN2CMDmSpaQktNzEaanozB6I07YwoGi4qn25y0SrL7cp0Y)aWviwOB6zDGJn1ym2k8ay3ZtYqJdIl)rwWmB68ivWHDScaL9vglCpROiwj0UBSeYZjmmi00bOwuHiIm0bHGppemM)roroJCCDINBognb5hjo1CvM8pFDw4XWYyH3RTjcVu)AtNpliEkk0ZXsqK8sOGnJyXc17Sjcv9UGmA3InyfeqkBAVul1LXx04iqKRvwVXMLQTM0AQiazIsw1OsVmNu(QcZobMmo)QCGJZZMi1LNHgVrRRLVnkn3dCId48)xPMJQQk5YSzZRtTAPKYv5W6Ll3DQqzPJ4uyHvtM1MqZIdLHYm1OxuPzxQEkojwd9QwBMXS6012IZ4IzNrOaobRqUjAnEEM1xvjpENxzk5)VoYC9OJmW(H9yPnBiBLXWUUnKKvqsKzme)mckqcimoNGbrrY0jGQ82U9YH3A5qCYd3C5q0FiXz2m04MrZMdzrtezhJgXyMuyHMgWHog1v)rwa6a6R5Oa34OzwP9RqjuZdtOlogUu02cA9YNw728H74JtWdrAefAxvvjbLOLwuPjlNurzDAgAyLck)OP7kg7LjB0aqJwDKbrgIlenlimMTLm4n8C5UkcOpT1nCYCfsjEVtSIvbzKetOCZmVzOWji7ytRiBK)yiG7CZiuyINKkM1rSvt4NrGAqReh)ze7OKqiuh4Y9q)GJHXWDN)firkbDsIIK3BdR4jqk0MXb31XNRbrKq)extzqMFUARtwdxTxbYHI9W)T2Ig1OYJDR4zDxIJO2zAOL9TUnJVvHcSsHQSkSY9Z6MegoNEUgHoZOF83z5NybrnSNIl)aqAyGhnBPETU9YHhp1XEk8)Ncdf54bKbKMe24jo9JwJhhabuST89dIll1bERvtkhHjdiSkYh55GIOL41gtV7PGE9rjH4qEZ9TMfHx4uC2OCE3Lct9z2S(QHQOdG0bnQ1D3ovpmJjbXPjSepYoNbxl9g5gem2CscEpJRvDgQtGqN2kHX053D1gPgDyKo50j4MdfEieTHqCBZfB3jer4drwGldaS8mkglKTTCDlLfqvQ6yvN6WkoxHAkRUJjTsP2Kg82Kz5wjVWtcWQx5YsRqbNSPyTzNWq1Rq7Q9qdU6RqBNx6QqtDfvvnXC(k0uhg8ArfAAcUETTDqdu37MyCS4jwjUXdepoh7GeI6aU3EcUo5oqhUwwZpprRv9j8VYAQKKwyAQKqEd(o4P7z5BzoYcp95mwOYhxR2l2K7i0SJMbMdiC67uZqQUbePWXghdHrCbHnmP)ht8nRGE)kmPeiZPMPvfpB)KIZkcCCfQAvmt1Ii(GWrdnXfiYfAsmjgsPkzSSxWr4aRYy6WeFLKvAitjzdE1qzBizX2erjz(XPaSHK3AttP3Pb9zZT(etVSm538nXIgrLNB4vnXTHuMqFY0Nt6gTxskoyDjRukkD3uD6kRMC28nn6zRKNI7gI)ne5K9LckqRdwTeXAJzCo3r0yAqglqerWpFPOAwHqDIq9oqOnxxeaDjr2yi3GzaCrXfRpRjB4)LBc8xGwh(JMAJTzMtqq5frXuISqv5N5M8QjXZlvUJvICRwtEvsh1lvpjg3kZEtTbXk6dktRpeWh(0SAOkB2l7n6JRmosZtyULAczWElAXX91ZiRiBqQrKwfYRQ9c1QNVy2lu1)t9zUbUZ8aNudkoCMn6ORRsPf)0DY1x9NllrgPvMKF7fM4gGevnY)EUCOK)bnLwmIvKY0ccPrBu2FgX4)9Z6oOANg4YjO3wKuDsLGrmae6UZCdICOfeWFh9ibcXDBqGL3vuSq3c4Mez)4iyldpPSBAoG9JTcXBOrd2)IV9Ro7tU3p(0)2zF3tp7D(YBavpCJZE))YfFXx)8p7Kl(Q)4Pp(KtFs6Li)0)1Jo)bF))(K3A5R)Sh(W2x8fFiSUl(HhE(h9pUbeB2)quSYdMO4Efq1AVXPp(j3OQhNXno)HFbbTlF9ZF)p(S795uI90N8Ug7C6J)MZV3jx82)aLQjtdhXpyIJBECLOM5rCVvVFLyq)LVUSzLfA)2yl)Evls(Tjzb0ZOnMutbkak2ANz)oBTYSFpRfSArT6fiV(wocsWhhDDfLLEBAUw9mUTZKE1yl8TEnsBfxjSa9i8A5RGLDzcPUrxfTqmoSlnPW68wv97TD9A0euxjkyk4BJWtfrdTgoE5yfrXkHDEzoRnd0R96jNUuyQIikpV31xy1R9kHoj6CfO(1sSuvGwryssYQcCpJtLMunyIVLIiCmucByT6BjVLTlwut9rm0O(wCPz03O1IfyB)g1RP8OeQRPDMaaQRRbLW4sypAXhyglViL6kAaD5fNLSa)YRjP6gfWSo(iaEvkCv0()(3rkvN1F)BNgoUxRkqe1K2vFUTpUYMQRi1SETQRSoSflKZQnKZgPBIeIxQ6GuvYCOIx3wABtF)olwOP98nQxz0Yx)cB0NYvnWPmkxxDRALB3ohPktdUb2gTG2yc2SH6Y8q4NAfAr6))M1QlXlRHQn)A)Pr)MxtIMprf93l1bDIM4amFVyf69w3PrHfc7V4SflKFG(D3lDKY)8063ZOtdjSQm7fLAnqWmz)QZKb3nZk6sRJUckrZVASky12f8yT6z1)1KkMZ)zlktDJXPuX4q69vTofmVHVah8k6D3U9TA36MkUnIPAKLUFJlwSvTs3RXfluafqdvDeGUgTzmmlpC72f6)YV7IDjU7FLxj7(bKjvghyQQAXyROdl5VPRXDa(IO0yhoFwSJnuAkKnyskuZM2VMmfaYUohq088r3fGpStdv4dv8b6sJDY(NcRc0PS8Jj1dojaMHjK)CeURazZRr3Ts1Ceyw0Dr2jXitSY1TmUPKFabn0RwWVNOqBODR6yVEkDEySx9TKSmJwDyxNI7AjutvBqxqoO7BaoOx3Ux0VtRvW1QVoJejGAsrTWrpclF1eFbHiUBQiXXfOzWL8oDv0lGOgIypXvKpf1lQl2DGN1DVzBXYt2oR8eWKC5WR0lrOiDs78EgR3TvZ2c1L2LPWuPYqfxGpmilbjvP2Sj7GAKSKDWYoZC8pk4qC)jbZaFGKXlMYde3dGNQjjrS7Z8FonW36axW1o4zcuWaD5OepV0iiyyxEiHaRuyxCnflns(fduNEzDvoHKB1y0rQmp)Igkoa)DlKpnV8gUS6Yf4VzxsHG8eDUkZPrAwtYjgHSMxvk38sIYzOWo(1Ik)kwgBWrM1j7xuNIsgV8QbLaZp76cLOO1uHqIGPqRqInKYsiwTWJfcRrXcBImB9igbrMcek6)sWhjN4HTkynzltcVw60vBihQRR5yTYNPTq09Bz0PVAy0q0(bF6JPBDKtrKXzp75nQCrK7sRSb5k(MRhi1KvhoFS8(SzfWauXJaedUStseK7vekfNtOs2ICaHSYksFSRULy5fUEDrjBvRR(X1n31I8tUSnxptYzPdcd5wRLC(xPDf5Uh3S9fULE5zgob0vMBRmyD15YkN6KFyOP2ocrNZpIuSEC(lCJIjeY842Oyk5pqncMb8pQe93TLI1JNz6RRcNxo2NsM6fVJfD7L(gwihASpwlyWvEH1LJbokx4HQHyJw6jPak6w2ZrXIfcpffyLvXNHIYRn77Ip)enuXOmN8UogT0J0b9ZR8b6OqmL)4CCTtgKrDk4FfpBm)YxUiJjuiJuBWAavItssSzXB)YVGeDKN3l7bVXU7qUJrd(pd]] )


--该Simc用途为适配官方一键宏，提供自动爆发，减伤与打断等功能