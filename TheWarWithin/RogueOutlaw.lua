-- RogueOutlaw.lua
-- August 2025
-- Patch 11.2


if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "ROGUE" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local PTR = ns.PTR
local spec = Hekili:NewSpecialization( 260 )

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
local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
-- local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
-- local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)
local GetUnitChargedPowerPoints = GetUnitChargedPowerPoints
local FindPlayerAuraByID = ns.FindPlayerAuraByID
local min = ns.safeMin

spec:RegisterResource( Enum.PowerType.ComboPoints, {
    -- Gain 1 CP every 0.5 s while channeling Killing Spree
    killing_spree = {
        channel = "killing_spree",                     -- only active during the channel
        last = function ()                             -- time of the most recent tick
            local app  = state.buff.casting.applied    -- channel started here
            local tick = 0.5 * state.haste
            local t    = state.query_time
            return app + math.floor( ( t - app ) / tick ) * tick
        end,
        interval = function () return 0.5 * state.haste end,
        value    = 1,                                  -- add 1 combo-point per tick
    },
} )
spec:RegisterResource( Enum.PowerType.Energy, {
        blade_rush = {
            aura = "blade_rush",

            last = function ()
                local app = state.buff.blade_rush.applied
                local t = state.query_time

                return app + floor( t - app )
            end,

            interval = function() return class.auras.blade_rush.tick_time end,
            value = 5,
        },
    },
    nil, -- No replacement model.
    {    -- Meta function replacements.
        base_time_to_max = function( t )
            if buff.adrenaline_rush.up then
                if t.current > t.max - 50 then return 0 end
                return state:TimeToResource( t, t.max - 50 )
            end
        end,
        base_deficit = function( t )
            if buff.adrenaline_rush.up then
                return max( 0, ( t.max - 50 ) - t.current )
            end
        end,
    }
)

-- Talents
spec:RegisterTalents( {
    -- Rogue
    acrobatic_strikes              = {  90752,  455143, 1 }, -- Auto-attacks increase auto-attack damage and movement speed by $s1% for $s2 sec, stacking up to $s3%
    airborne_irritant              = {  90741,  200733, 1 }, -- Blind has $s1% reduced cooldown, $s2% reduced duration, and applies to all nearby enemies
    alacrity                       = {  90751,  193539, 2 }, -- Your finishing moves have a $s1% chance per combo point to grant $s2% Haste for $s3 sec, stacking up to $s4 times
    atrophic_poison                = {  90763,  381637, 1 }, -- Coats your weapons with a Non-Lethal Poison that lasts for $s1 |$s2hour:hrs;. Each strike has a $s3% chance of poisoning the enemy, reducing their damage by $s4% for $s5 sec
    blackjack                      = {  90686,  379005, 1 }, -- Enemies have $s1% reduced damage and healing for $s2 sec after Blind or Sap's effect on them ends
    blind                          = {  90684,    2094, 1 }, -- Blinds all enemies near the target, causing them to wander disoriented for $s1 sec. Damage may interrupt the effect. Limit $s2
    cheat_death                    = {  90742,   31230, 1 }, -- Fatal attacks instead reduce you to $s1% of your maximum health. For $s2 sec afterward, you take $s3% reduced damage. Cannot trigger more often than once per $s4 min
    cloak_of_shadows               = {  90697,   31224, 1 }, -- Provides a moment of magic immunity, instantly removing all harmful spell effects. The cloak lingers, causing you to resist harmful spells for $s1 sec
    cold_blood                     = {  90748,  382245, 1 }, -- Increases the critical strike chance of your next damaging ability by $s1%
    deadened_nerves                = {  90743,  231719, 1 }, -- Physical damage taken reduced by $s1%
    deadly_precision               = {  90760,  381542, 1 }, -- Increases the critical strike chance of your attacks that generate combo points by $s1%
    deeper_stratagem               = {  90750,  193531, 1 }, -- Gain $s1 additional max combo point. Your finishing moves that consume more than $s2 combo points have increased effects, and your finishing moves deal $s3% increased damage
    echoing_reprimand              = {  90638,  470669, 1 }, -- After consuming a supercharged combo point, your next Sinister Strike also strikes the target with an Echoing Reprimand dealing $s$s2 Physical damage
    elusiveness                    = {  90742,   79008, 1 }, -- Evasion also reduces damage taken by $s1%, and Feint also reduces non-area-of-effect damage taken by $s2%
    evasion                        = {  90764,    5277, 1 }, -- Increases your dodge chance by $s1% for $s2 sec
    featherfoot                    = {  94563,  423683, 1 }, -- Sprint increases movement speed by an additional $s1% and has $s2 sec increased duration
    fleet_footed                   = {  90762,  378813, 1 }, -- Movement speed increased by $s1%
    forced_induction               = {  90638,  470668, 1 }, -- Increase the bonus granted when a damaging finishing move consumes a supercharged combo point by $s1
    gouge                          = {  90741,    1776, 1 }, -- Gouges the eyes of an enemy target, incapacitating for $s1 sec. Damage may interrupt the effect. Must be in front of your target. Awards $s2 combo point
    graceful_guile                 = {  94562,  423647, 1 }, -- Feint has $s1 additional charge
    improved_ambush                = {  90692,  381620, 1 }, -- Ambush generates $s1 additional combo point
    improved_sprint                = {  90746,  231691, 1 }, -- Reduces the cooldown of Sprint by $s1 sec
    improved_wound_poison          = {  90637,  319066, 1 }, -- Wound Poison can now stack $s1 additional times
    iron_stomach                   = {  90744,  193546, 1 }, -- Increases the healing you receive from Crimson Vial, healing potions, and healthstones by $s1%
    leeching_poison                = {  90758,  280716, 1 }, -- Adds a Leeching effect to your Lethal poisons, granting you $s1% Leech
    lethality                      = {  90749,  382238, 2 }, -- Critical strike chance increased by $s1%. Critical strike damage bonus of your attacks that generate combo points increased by $s2%
    master_poisoner                = {  90636,  378436, 1 }, -- Increases the non-damaging effects of your weapon poisons by $s1%
    nimble_fingers                 = {  90745,  378427, 1 }, -- Energy cost of Feint and Crimson Vial reduced by $s1
    numbing_poison                 = {  90763,    5761, 1 }, -- Coats your weapons with a Non-Lethal Poison that lasts for $s1 |$s2hour:hrs;. Each strike has a $s3% chance of poisoning the enemy, clouding their mind and slowing their attack and casting speed by $s4% for $s5 sec
    recuperator                    = {  90640,  378996, 1 }, -- Slice and Dice heals you for up to $s1% of your maximum health per $s2 sec
    rushed_setup                   = {  90754,  378803, 1 }, -- The Energy costs of Kidney Shot, Cheap Shot, Sap, and Distract are reduced by $s1%
    shadowheart                    = { 101714,  455131, 1 }, -- Leech increased by $s1% while Stealthed
    shadowrunner                   = {  90687,  378807, 1 }, -- While Stealth or Shadow Dance is active, you move $s1% faster
    shiv                           = {  90740,    5938, 1 }, -- Attack with your off-hand, dealing $s$s2 Physical damage, dispelling all enrage effects and applying a concentrated form of your active Non-Lethal poison. Awards $s3 combo point
    soothing_darkness              = {  90691,  393970, 1 }, -- You are healed for $s1% of your maximum health over $s2 sec after activating Vanish
    stillshroud                    = {  94561,  423662, 1 }, -- Shroud of Concealment has $s1% reduced cooldown
    subterfuge                     = {  90688,  108208, 2 }, -- Abilities requiring Stealth can be used for $s1 sec after Stealth breaks. Combat benefits requiring Stealth persist for an additional $s2 sec after Stealth breaks
    supercharger                   = {  90639,  470347, 2 }, -- Roll the Bones supercharges $s1 combo point. Damaging finishing moves consume a supercharged combo point to function as if they spent $s2 additional combo points
    superior_mixture               = {  94567,  423701, 1 }, -- Crippling Poison reduces movement speed by an additional $s1%
    thistle_tea                    = {  90756,  381623, 1 }, -- Restore $s1 Energy. Mastery increased by $s2% for $s3 sec. When your Energy is reduced below $s4, drink a Thistle Tea
    thrill_seeking                 = {  90695,  394931, 1 }, -- Grappling Hook has $s1 additional charge
    tight_spender                  = {  90692,  381621, 1 }, -- Energy cost of finishing moves reduced by $s1%
    tricks_of_the_trade            = {  90686,   57934, 1 }, -- Redirects all threat you cause to the targeted party or raid member, beginning with your next damaging attack within the next $s1 sec and lasting $s2 sec
    unbreakable_stride             = {  90747,  400804, 1 }, -- Reduces the duration of movement slowing effects $s1%
    vigor                          = {  90759,   14983, 2 }, -- Increases your maximum Energy by $s1 and Energy regeneration by $s2%
    virulent_poisons               = {  90760,  381543, 1 }, -- Increases the damage of your weapon poisons by $s1%
    without_a_trace                = { 101713,  382513, 1 }, -- Vanish has $s1 additional charge

    -- Outlaw
    ace_up_your_sleeve             = {  90670,  381828, 1 }, -- Between the Eyes has a $s1% chance per combo point spent to grant $s2 combo points
    adrenaline_rush                = {  90659,   13750, 1 }, -- Increases your Energy regeneration rate by $s1%, your maximum Energy by $s2, and your attack speed by $s3% for $s4 sec
    ambidexterity                  = {  90660,  381822, 1 }, -- Main Gauche has an additional $s1% chance to strike while Blade Flurry is active
    audacity                       = {  90641,  381845, 1 }, -- Half-cost uses of Pistol Shot have a $s1% chance to make your next Ambush usable without Stealth. Chance to trigger this effect matches the chance for your Sinister Strike to strike an additional time
    blade_rush                     = {  90664,  271877, 1 }, -- Charge to your target with your blades out, dealing $s$s2 Physical damage to the target and $s3 to all other nearby enemies. While Blade Flurry is active, damage to non-primary targets is increased by $s4%. Generates $s5 Energy over $s6 sec
    blinding_powder                = {  90643,  256165, 1 }, -- Reduces the cooldown of Blind by $s1% and increases its range by $s2 yds
    combat_potency                 = {  90646,   61329, 1 }, -- Increases your Energy regeneration rate by $s1%
    combat_stamina                 = {  90648,  381877, 1 }, -- Stamina increased by $s1%
    count_the_odds                 = {  90655,  381982, 1 }, -- Ambush, Sinister Strike, and Dispatch have a $s1% chance to grant you a Roll the Bones combat enhancement buff you do not already have for $s2 sec
    crackshot                      = {  94565,  423703, 1 }, -- Entering Stealth refreshes the cooldown of Between the Eyes. Between the Eyes has no cooldown and also Dispatches the target for $s1% of normal damage when used from Stealth
    dancing_steel                  = {  90669,  272026, 1 }, -- Blade Flurry strikes $s1 additional enemies and its duration is increased by $s2 sec
    deft_maneuvers                 = {  90672,  381878, 1 }, -- Blade Flurry's initial damage is increased by $s1% and generates $s2 combo point per target struck
    devious_stratagem              = {  90679,  394321, 1 }, -- Gain $s1 additional max combo point. Your finishing moves that consume more than $s2 combo points have increased effects, and your finishing moves deal $s3% increased damage
    dirty_tricks                   = {  90645,  108216, 1 }, -- Cheap Shot, Gouge, and Sap no longer cost Energy
    fan_the_hammer                 = {  90666,  381846, 2 }, -- When Sinister Strike strikes an additional time, gain $s1 additional stack of Opportunity. Max $s2 stacks. Half-cost uses of Pistol Shot consume $s3 additional stack of Opportunity to fire $s4 additional shot. Additional shots generate $s5 fewer combo point and deal $s6% reduced damage
    fatal_flourish                 = {  90662,   35551, 1 }, -- Your off-hand attacks have a $s1% chance to generate $s2 Energy
    float_like_a_butterfly         = {  90755,  354897, 1 }, -- Restless Blades now also reduces the remaining cooldown of Evasion and Feint by $s1 sec per combo point spent
    ghostly_strike                 = {  90644,  196937, 1 }, -- Strikes an enemy, dealing $s$s2 Physical damage and causing the target to take $s3% increased damage from your abilities for $s4 sec. Awards $s5 combo point
    greenskins_wickers             = {  90665,  386823, 1 }, -- Between the Eyes has a $s1% chance per Combo Point to increase the damage of your next Pistol Shot by $s2%
    heavy_hitter                   = {  90642,  381885, 1 }, -- Attacks that generate combo points deal $s1% increased damage
    hidden_opportunity             = {  90675,  383281, 1 }, -- Effects that grant a chance for Sinister Strike to strike an additional time also apply to Ambush at $s1% of their value
    hit_and_run                    = {  90673,  196922, 1 }, -- Movement speed increased by $s1%
    improved_adrenaline_rush       = {  90654,  395422, 1 }, -- Generate full combo points when you gain Adrenaline Rush, and full Energy when it ends
    improved_between_the_eyes      = {  90671,  235484, 1 }, -- Critical strikes with Between the Eyes deal four times normal damage
    improved_main_gauche           = {  90668,  382746, 1 }, -- Main Gauche has an additional $s1% chance to strike
    keep_it_rolling                = {  90652,  381989, 1 }, -- Increase the remaining duration of your active Roll the Bones combat enhancements by $s1 sec
    killing_spree                  = {  94566,   51690, 1 }, -- Finishing move that unleashes a barrage of gunfire, striking random enemies within $s1 yards for Physical damage. Number of strikes increased per combo point. Restores $s2 combo point every $s3 sec. $s4 point : $s5 million over $s6 sec $s7 points: $s8 million over $s9 sec $s10 points: $s11 million over $s12 sec $s13 points: $s14 million over $s15 sec $s16 points: $s17 million over $s18 sec $s19 points: $s20 million over $s21 sec $s22 points: $s23 million over $s24 sec
    loaded_dice                    = {  90656,  256170, 1 }, -- Activating Adrenaline Rush causes your next Roll the Bones to grant at least two matches
    opportunity                    = {  90683,  279876, 1 }, -- Sinister Strike has a $s1% chance to hit an additional time, making your next Pistol Shot half cost and double damage
    precise_cuts                   = {  90667,  381985, 1 }, -- Blade Flurry damage is increased by an additional $s1% per missing target below its maximum
    precision_shot                 = {  90647,  428377, 1 }, -- Between the Eyes and Pistol Shot have $s1 yd increased range, and Pistol Shot reduces the the target's damage done to you by $s2%
    quick_draw                     = {  90663,  196938, 1 }, -- Half-cost uses of Pistol Shot granted by Sinister Strike now generate $s1 additional combo point, and deal $s2% additional damage
    retractable_hook               = {  90681,  256188, 1 }, -- Reduces the cooldown of Grappling Hook by $s1 sec, and increases its retraction speed
    riposte                        = {  90661,  344363, 1 }, -- Dodging an attack will trigger Mastery: Main Gauche. This effect may only occur once every $s1 sec
    ruthlessness                   = {  90680,   14161, 1 }, -- Your finishing moves have a $s1% chance per combo point spent to grant a combo point
    sleight_of_hand                = {  90651,  381839, 1 }, -- Roll the Bones has a $s1% increased chance of granting additional matches
    sting_like_a_bee               = {  90755,  131511, 1 }, -- Enemies disabled by your Cheap Shot or Kidney Shot take $s1% increased damage from all sources for $s2 sec
    summarily_dispatched           = {  90653,  381990, 2 }, -- When your Dispatch consumes $s1 or more combo points, Dispatch deals $s2% increased damage and costs $s3 less Energy for $s4 sec. Max $s5 stacks. Adding a stack does not refresh the duration
    swift_slasher                  = {  90649,  381988, 1 }, -- Slice and Dice grants additional attack speed equal to $s1% of your Haste
    take_em_by_surprise            = {  90676,  382742, 2 }, -- Haste increased by $s1% while Stealthed and for $s2 sec after breaking Stealth
    thiefs_versatility             = {  90753,  381619, 1 }, -- Versatility increased by $s1%
    triple_threat                  = {  90678,  381894, 1 }, -- Sinister Strike has a $s1% chance to strike with both weapons after it strikes an additional time
    underhanded_upper_hand         = {  90677,  424044, 1 }, -- Blade Flurry does not lose duration during Adrenaline Rush. Adrenaline Rush does not lose duration while Stealthed

    -- Fatebound
    chosens_revelry                = {  95138,  454300, 1 }, -- Leech increased by $s1% for each time your Fatebound Coin has flipped the same face in a row
    deal_fate                      = {  95107,  454419, 1 }, -- Sinister Strike and Ambush generate $s1 additional combo point when they strike an additional time
    deaths_arrival                 = {  95130,  454433, 1 }, -- Grappling Hook may be used a second time within $s1 sec with no cooldown, but its total cooldown is increased by $s2 sec
    delivered_doom                 = {  95119,  454426, 1 }, -- Damage dealt when your Fatebound Coin flips tails is increased by $s1% if there are no other enemies near the target. Each additional nearby enemy reduces this bonus by $s2%
    destiny_defined                = {  95114,  454435, 1 }, -- Sinister Strike has $s1% increased chance to strike an additional time and your Fatebound Coins flipped have an additional $s2% chance to match the same face as the last flip
    double_jeopardy                = {  95129,  454430, 1 }, -- Your first Fatebound Coin flip after breaking Stealth flips two coins that are guaranteed to match the same outcome
    edge_case                      = {  95139,  453457, 1 }, -- Activating Adrenaline Rush flips a Fatebound Coin and causes it to land on its edge, counting as both Heads and Tails
    fate_intertwined               = {  95120,  454429, 1 }, -- Fate Intertwined duplicates $s1% of Dispatch critical strike damage as Cosmic to $s2 additional nearby enemies. If there are no additional nearby targets, duplicate $s3% to the primary target instead
    fateful_ending                 = {  95127,  454428, 1 }, -- When your Fatebound Coin flips the same face for the seventh time in a row, keep the lucky coin to gain $s2% Agility until you leave combat for $s3 seconds. If you already have a lucky coin, it instead deals $s$s4 Cosmic damage to your target
    hand_of_fate                   = {  95125,  452536, 1 }, -- Flip a Fatebound Coin each time a finishing move consumes $s2 or more combo points. Heads increases the damage of your attacks by $s3%, lasting $s4 sec or until you flip Tails. Tails deals $s$s5 Cosmic damage to your target. For each time the same face is flipped in a row, Heads increases damage by an additional $s6% and Tails increases its damage by $s7%
    inevitabile_end                = {  95114,  454434, 1 }, -- Cold Blood now benefits the next two abilities but only applies to Dispatch. Fatebound Coins flipped by these abilities are guaranteed to match the same outcome as the last flip
    inexorable_march               = {  95130,  454432, 1 }, -- You cannot be slowed below $s1% of normal movement speed while your Fatebound Coin flips have an active streak of at least $s2 flips matching the same face
    mean_streak                    = {  95122,  453428, 1 }, -- Fatebound Coins flipped by Dispatch are $s1% more likely to match the same face as the last flip
    tempted_fate                   = {  95138,  454286, 1 }, -- You have a chance equal to your critical strike chance to absorb $s1% of any damage taken, up to a maximum chance of $s2%

    -- Trickster
    cloud_cover                    = {  95116,  441429, 1 }, -- Distract now also creates a cloud of smoke for $s1 sec. Cooldown increased to $s2 sec. Attacks from within the cloud apply Fazed
    coup_de_grace                  = {  95115,  441423, 1 }, -- After $s1 strikes with Unseen Blade, your next Dispatch will be performed as a Coup de Grace, functioning as if it had consumed $s2 additional combo points. If the primary target is Fazed, gain $s3 stacks of Flawless Form
    devious_distractions           = {  95133,  441263, 1 }, -- Killing Spree applies Fazed to any targets struck
    disorienting_strikes           = {  95118,  441274, 1 }, -- Killing Spree has $s1% reduced cooldown and allows your next $s2 strikes of Unseen Blade to ignore its cooldown
    dont_be_suspicious             = {  95134,  441415, 1 }, -- Blind and Shroud of Concealment have $s1% reduced cooldown. Pick Pocket and Sap have $s2 yd increased range
    flawless_form                  = {  95111,  441321, 1 }, -- Unseen Blade and Killing Spree increase the damage of your finishing moves by $s1% for $s2 sec. Multiple applications may overlap
    flickerstrike                  = {  95137,  441359, 1 }, -- Taking damage from an area-of-effect attack while Feint is active or dodging while Evasion is active refreshes your opportunity to strike with Unseen Blade. This effect may only occur once every $s1 sec
    mirrors                        = {  95141,  441250, 1 }, -- Feint reduces damage taken from area-of-effect attacks by an additional $s1%
    nimble_flurry                  = {  95128,  441367, 1 }, -- Blade Flurry damage is increased by $s1% while Flawless Form is active
    no_scruples                    = {  95116,  441398, 1 }, -- Finishing moves have $s1% increased chance to critically strike Fazed targets
    smoke                          = {  95141,  441247, 1 }, -- You take $s1% reduced damage from Fazed targets
    so_tricky                      = {  95134,  441403, 1 }, -- Tricks of the Trade's threat redirect duration is increased to $s1 hour
    surprising_strikes             = {  95121,  441273, 1 }, -- Attacks that generate combo points deal $s1% increased critical strike damage to Fazed targets
    thousand_cuts                  = {  95137,  441346, 1 }, -- Slice and Dice grants $s1% additional attack speed and gives your auto-attacks a chance to refresh your opportunity to strike with Unseen Blade
    unseen_blade                   = {  95140,  441146, 1 }, -- Sinister Strike and Ambush now also strike with an Unseen Blade dealing $s1 damage. Targets struck are Fazed for $s2 sec. Fazed enemies take $s3% more damage from you and cannot parry your attacks. This effect may occur once every $s4 sec
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    boarding_party                 =  853, -- (209752)
    control_is_king                =  138, -- (354406) Cheap Shot grants Slice and Dice for $s1 sec and Kidney Shot restores $s2 Energy per combo point spent
    dagger_in_the_dark             = 5549, -- (198675) Each second while Stealth is active, nearby enemies within $s1 yards take an additional $s2% damage from you for $s3 sec. Stacks up to $s4 times
    death_from_above               = 3619, -- (269513) Finishing move that empowers your weapons with energy to perform a deadly attack. You leap into the air and Dispatch your target on the way back down, with such force that it has a $s1% stronger effect
    dismantle                      =  145, -- (207777) Disarm the enemy, preventing the use of any weapons or shield for $s1 sec
    drink_up_me_hearties           =  139, -- (354425)
    maneuverability                =  129, -- (197000) Sprint has $s1% reduced cooldown and $s2% reduced duration
    preemptive_maneuver            = 5699, -- (1219122) Feint decreases your damage taken by an additional $s1% while stunned and its energy cost is reduced by $s2%
    smoke_bomb                     = 3483, -- (212182) Creates a cloud of thick smoke in an $s1 yard radius around the Rogue for $s2 sec. Enemies are unable to target into or out of the smoke cloud
    thick_as_thieves               = 1208, -- (221622) Tricks of the Trade now increases the friendly target's damage by $s1% for $s2 sec
    turn_the_tables                = 3421, -- (198020)
} )

local rtb_buff_list = {
    "broadside", "buried_treasure", "grand_melee", "ruthless_precision", "skull_and_crossbones", "true_bearing", "rtb_buff_1", "rtb_buff_2"
}

-- Auras
spec:RegisterAuras( {
    -- Talent: Energy regeneration increased by $w1%.  Maximum Energy increased by $w4.  Attack speed increased by $w2%.  $?$w5>0[Damage increased by $w5%.][]
    -- https://wowhead.com/beta/spell=13750
    adrenaline_rush = {
        id = 13750,
        duration = 20,
        max_stack = 1
    },
    -- Talent: Each strike has a chance of poisoning the enemy, reducing their damage by ${$392388s1*-1}.1% for $392388d.
    -- https://wowhead.com/beta/spell=381637
    atrophic_poison = {
        id = 381637,
        duration = 3600,
        max_stack = 1
    },
    -- Talent: Damage reduced by ${$W1*-1}.1%.
    -- https://wowhead.com/beta/spell=392388
    atrophic_poison_dot = {
        id = 392388,
        duration = 10,
        type = "Magic",
        max_stack = 1
    },
    alacrity = {
        id = 193538,
        duration = 15,
        max_stack = 5
    },
    audacity = {
        id = 386270,
        duration = 10,
        max_stack = 1,
    },
    -- $w2% increased critical strike chance.
    between_the_eyes = {
        id = 315341,
        duration = function() return 3 * effective_combo_points end,
        max_stack = 1
    },
    -- Talent: Attacks striking nearby enemies.
    -- https://wowhead.com/beta/spell=13877
    blade_flurry = {
        id = 13877,
        duration = function () return talent.dancing_steel.enabled and 13 or 10 end,
        max_stack = 1
    },
    -- Talent: Generates $s1 Energy every sec.
    -- https://wowhead.com/beta/spell=271896
    blade_rush = {
        id = 271896,
        duration = 5,
        tick_time = 1,
        max_stack = 1
    },
    coup_de_grace = {
        id = 462127,
        duration = 3600,
        max_stack = 1,
        generate = function( t )
            local eb = buff.escalating_blade
            if eb.up and eb.at_max_stacks then
                t.name = "coup_de_grace"
                t.count = 1
                t.expires = eb.expires
                t.applied = query_time
                t.caster = "player"
            else
                t.name = "coup_de_grace"
                t.count = 0
                t.expires = 0
                t.applied = 0
                t.caster = "nobody"
            end
        end
    },
    disorienting_strikes = {
        duration = 3600,
        max_stack = 2
    },
    double_jeopardy = {
        duration = 3600,
        max_stack = 1
    },
    echoing_reprimand = {
        id = 470671,
        duration = 30,
        max_stack = 1
    },
    escalating_blade = {
        id = 441786,
        duration = 3600,
        max_stack = 4
    },
    -- Taking 5% more damage from $auracaster.
    fazed = {
        id = 441224,
        duration = 10,
        max_stack = 1
    },
    flawless_form = {
        id = 441326,
        duration = 12,
        max_stack = 20
    },
    -- Talent: Taking $s3% increased damage from the Rogue's abilities.
    -- https://wowhead.com/beta/spell=196937
    ghostly_strike = {
        id = 196937,
        duration = 10,
        max_stack = 1
    },
    -- Suffering $w1 damage every $t1 sec.
    -- https://wowhead.com/beta/spell=154953
    internal_bleeding = {
        id = 154953,
        duration = 6,
        tick_time = 1,
        mechanic = "bleed",
        max_stack = 1
    },
    -- Increase the remaining duration of your active Roll the Bones combat enhancements by 30 sec.
    keep_it_rolling = {
        id = 381989
    },
    -- Killing Spree Blasting nearby enemies every $s1 sec. $s2 seconds remaining
    -- https://www.wowhead.com/spell=51690
    killing_spree = {
        id = 51690,
        duration = function () return 0.5 * effective_combo_points * haste end,
        tick_time = function () return 0.5 * haste end,
        max_stack = 1
    },
    -- Suffering $w4 Nature damage every $t4 sec.
    -- https://wowhead.com/beta/spell=385627
    kingsbane = {
        id = 385627,
        duration = 14,
        max_stack = 50
    },
    -- Talent: Leech increased by $s1%.
    -- https://wowhead.com/beta/spell=108211
    leeching_poison = {
        id = 108211,
        duration = 3600,
        max_stack = 1
    },
    -- Talent: Your next $?s5171[Slice and Dice will be $w1% more effective][Roll the Bones will grant at least two matches].
    -- https://wowhead.com/beta/spell=256171
    loaded_dice = {
        id = 256171,
        duration = 45,
        max_stack = 1,
        copy = 240837
    },
    -- Suffering $w1 Nature damage every $t1 sec.
    -- https://wowhead.com/beta/spell=286581
    nothing_personal = {
        id = 286581,
        duration = 20,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Your next Pistol Shot costs $s1% less Energy and deals $s3% increased damage.
    -- https://wowhead.com/beta/spell=195627
    opportunity = {
        id = 195627,
        duration = 12,
        max_stack = 6
    },
    -- Movement speed reduced by $s3%.
    -- https://wowhead.com/beta/spell=185763
    pistol_shot = {
        id = 185763,
        duration = 6,
        max_stack = 1
    },
    -- Incapacitated.
    -- https://wowhead.com/beta/spell=107079
    quaking_palm = {
        id = 107079,
        duration = 4,
        max_stack = 1
    },
    riposte = {
        id = 199754,
        duration = 10,
        max_stack = 1
    },
    sharpened_sabers = {
        id = 252285,
        duration = 15,
        max_stack = 2
    },
    soothing_darkness = {
        id = 393971,
        duration = 6,
        max_stack = 1
    },
    -- Movement speed increased by $w1%.$?s245751[    Allows you to run over water.][]
    -- https://wowhead.com/beta/spell=2983
    sprint = {
        id = 2983,
        duration = 8,
        max_stack = 1
    },
    subterfuge = {
        id = 115192,
        duration = function() return 3 * talent.subterfuge.rank end,
        max_stack = 1
    },
    -- Damage taken increased by $w1%.
    stinging_vulnerability = {
        id = 255909,
        duration = 6,
        max_stack = 1
    },
    summarily_dispatched = {
        id = 386868,
        duration = 8,
        max_stack = 5
    },
    -- Talent: Haste increased by $w1%.
    -- https://wowhead.com/beta/spell=385907
    take_em_by_surprise = {
        id = 385907,
        duration = function() return combat and 10 * talent.take_em_by_surprise.rank + 3 * talent.subterfuge.rank or 3600 end,
        max_stack = 1
    },
    -- Talent: Threat redirected from Rogue.
    -- https://wowhead.com/beta/spell=57934
    tricks_of_the_trade = {
        id = 57934,
        duration = 30,
        max_stack = 1
    },
    unseen_blade = {
        id = 459485,
        duration = 20,
        max_stack = 1
    },
    -- Real RtB buffs.
    broadside = {
        id = 193356,
        duration = 30
    },
    buried_treasure = {
        id = 199600,
        duration = 30
    },
    grand_melee = {
        id = 193358,
        duration = 30
    },
    ruthless_precision = {
        id = 193357,
        duration = 30
    },
    skull_and_crossbones = {
        id = 199603,
        duration = 30
    },
    true_bearing = {
        id = 193359,
        duration = 30
    },
    -- Fake buffs for forecasting.
    rtb_buff_1 = {
        duration = 30
    },
    rtb_buff_2 = {
        duration = 30
    },
    supercharged_combo_points = {
        -- todo: Find a way to find a true buff / ID for this as a failsafe? Currently fully emulated.
        duration = 3600,
        max_stack = function() return combo_points.max end,
        copy = { "supercharge", "supercharged", "supercharger" }
    },
    -- Roll the dice of fate, providing a random combat enhancement for 30 sec.
    roll_the_bones = {
        alias = rtb_buff_list,
        aliasMode = "longest", -- use duration info from the buff with the longest remaining time.
        aliasType = "buff",
        duration = 30
    },
    lethal_poison = {
        alias = { "instant_poison", "wound_poison" },
        aliasMode = "first",
        aliasType = "buff",
        duration = 3600
    },
    nonlethal_poison = {
        alias = { "numbing_poison", "crippling_poison", "atrophic_poison" },
        aliasMode = "first",
        aliasType = "buff",
        duration = 3600
    },

    -- Legendaries (Shadowlands)
    concealed_blunderbuss = {
        id = 340587,
        duration = 8,
        max_stack = 1
    },
    deathly_shadows = {
        id = 341202,
        duration = 15,
        max_stack = 1
    },
    greenskins_wickers = {
        id = 340573,
        duration = 15,
        max_stack = 1,
        copy = 394131
    },
    master_assassins_mark = {
        id = 340094,
        duration = 4,
        max_stack = 1,
        copy = "master_assassin_any"
    },

    -- Azerite
    snake_eyes = {
        id = 275863,
        duration = 30,
        max_stack = 1
    },
} )



local inStealth = false
local exitedStealth = 0

spec:RegisterEvent( "UPDATE_STEALTH", function()
    local stealthed = IsStealthed()
    if inStealth and not stealthed then exitedStealth = GetTime() end
    inStealth = stealthed
end )

local lastShot, numShots = 0, 0
local lastUnseenBlade, disorientStacks = 0, 0
local lastRoll = 0
local rollDuration = 30
local rtbApplicators = {
    roll_the_bones = true,
    ambush = true,
    dispatch = true,
    keep_it_rolling = true,
}
local restless_blades_list = {
    "adrenaline_rush",
    "between_the_eyes",
    "blade_flurry",
    "blade_rush",
    "ghostly_strike",
    "grappling_hook",
    "keep_it_rolling",
    "killing_spree",
    "roll_the_bones",
    "sprint",
    "vanish"
}

spec:RegisterCombatLogEvent( function( _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
    if sourceGUID ~= state.GUID then return end

    -- SPELL_CAST_SUCCESS
    if subtype == "SPELL_CAST_SUCCESS" then
        local now = GetTime()

        if spellID == 185763 and state.talent.fan_the_hammer.enabled then
            -- Opportunity: Fan the Hammer can queue 1-2 extra Pistol Shots.
            if now - lastShot > 0.5 then
                local oppoStacks = ( select( 3, FindPlayerAuraByID( 195627 ) ) or 1 ) - 1
                lastShot = now
                numShots = min( state.talent.fan_the_hammer.rank, oppoStacks, 2 )

                Hekili:ForceUpdate( "FAN_THE_HAMMER", true )
            else
                numShots = max( 0, numShots - 1 )
            end

            return
        end

        if spellID == 51690 and state.talent.disorienting_strikes.enabled then -- Killing Spree grants 2 stacks of Disorienting Strikes (hidden aura)
            disorientStacks = 2
            return
        end

        if spellID == 193315 or spellID == 8676 then -- Sinister Strike (193315) or Ambush (8676) consumes 1 Disorienting Strike stack.
            disorientStacks = disorientStacks - 1
            return
        end

        if spellID == 315508 then
            -- 1. ‑‑ compute pandemic before we overwrite rollDuration
            local elapsed    = now - lastRoll           -- time since previous roll
            local remaining  = max( 0, rollDuration - elapsed )   -- container time left
            local pandemic   = min( 9, max( 0, remaining ) )
            -- 2. ‑‑ reset container
            lastRoll     = now                          -- real start‑time
            rollDuration = 30 + pandemic                -- 30 s + up‑to‑9 s
            return
        end

        return
    end

    -- SPELL_DAMAGE
    if subtype == "SPELL_DAMAGE" then
        local now = GetTime()
        if spellID == 441144 then  -- Unseen Blade damage event.
            if disorientStacks < 0 then
                lastUnseenBlade = now
            end
        end
        return
    end

    if subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_REFRESH" or subtype == "SPELL_AURA_APPLIED_DOSE" then
        if exitedStealth > 0 and ( spellID == class.auras.fatebound_coin_heads.id or spellID == class.auras.fatebound_coin_tails.id ) then
            exitedStealth = 0
        end
    end
end )

spec:RegisterStateExpr( "rtb_buffs", function ()
    return buff.roll_the_bones.count
end )

spec:RegisterStateExpr( "last_unseen_blade", function ()
    return lastUnseenBlade
end )

spec:RegisterStateExpr( "disorient_stacks", function ()
    return disorientStacks
end )

spec:RegisterStateExpr( "unseen_blades_available", function ()
    local count = 0

    -- add 1 if the ICD is cooled down
    if state.query_time - lastUnseenBlade >= 20 then count = count + 1 end

    -- add the # of bypasses that are available
    if disorientStacks > 0 then count = count + disorientStacks end

    return count
end )

local TriggerUnseenBlade = setfenv( function( )
    if unseen_blades_available > 0 then
        -- Handle ICD vs bypass
        if disorient_stacks > 0 then
            disorient_stacks = disorient_stacks - 1
        else
            last_unseen_blade = query_time
            applyDebuff( "player", "unseen_blade" )
        end

        if buff.escalating_blade.stack < 4 then
            addStack( "escalating_blade" )
            if buff.escalating_blade.stack == 4 then applyBuff( "coup_de_grace" ) end
        end
        applyDebuff( "target", "fazed" )
        unseen_blades_available = unseen_blades_available - 1
    end
end, state )

spec:RegisterStateExpr( "rtb_primary_remains", function ()
    local baseTime = max( lastRoll or 0, action.roll_the_bones.lastCast or 0 )
    return max( 0, baseTime + rollDuration - query_time )
end )

--[[   local remains = 0

    for rtb, appliedBy in pairs( rtbAuraAppliedBy ) do
        if appliedBy == "roll_the_bones" then
            local bone = buff[ rtb ]
            if bone.up then remains = max( remains, bone.remains ) end
        end
    end

    return remains
end ) ]]

spec:RegisterStateExpr( "rtb_buffs_shorter", function ()
    local n = 0
    local primary = rtb_primary_remains

    for _, rtb in ipairs( rtb_buff_list ) do
        local bone = buff[ rtb ]
        if bone.up and bone.remains < primary - 0.2 then -- Slightly larger threshold
            n = n + 1
        end
    end
    return n
end )

spec:RegisterStateExpr( "rtb_buffs_normal", function ()
    local n = 0
    local primary = rtb_primary_remains
    local tolerance = 0.2  -- Threshold for "close enough"

    for _, rtb in ipairs( rtb_buff_list ) do
        local bone = buff[ rtb ]
        if bone.up and abs( bone.remains - primary ) <= tolerance then
            n = n + 1
        end
    end
    return n
end )

spec:RegisterStateExpr( "rtb_buffs_min_remains", function ()
    local r = 3600

    for _, rtb in ipairs( rtb_buff_list ) do
        local bone = buff[ rtb ].remains
        if bone > 0 then r = min( r, bone ) end
    end

    return r == 3600 and 0 or r
end )

spec:RegisterStateExpr( "rtb_buffs_max_remains", function ()
    local r = 0

    for _, rtb in ipairs( rtb_buff_list ) do
        local bone = buff[ rtb ]
        r = max( r, bone.remains )
    end

    return r
end )

spec:RegisterStateExpr( "rtb_buffs_longer", function ()
    local n = 0
    local primary = rtb_primary_remains

    for _, rtb in ipairs( rtb_buff_list ) do
        local bone = buff[ rtb ]
        if bone.up and bone.remains > primary + 0.2 then -- Slightly larger threshold
            n = n + 1
        end
    end
    return n
end )

spec:RegisterStateExpr( "rtb_buffs_will_lose", function ()
    local count = 0
    count = count + ( rtb_buffs_will_lose_buff.broadside and 1 or 0 )
    count = count + ( rtb_buffs_will_lose_buff.buried_treasure and 1 or 0 )
    count = count + ( rtb_buffs_will_lose_buff.grand_melee and 1 or 0 )
    count = count + ( rtb_buffs_will_lose_buff.ruthless_precision and 1 or 0 )
    count = count + ( rtb_buffs_will_lose_buff.skull_and_crossbones and 1 or 0 )
    count = count + ( rtb_buffs_will_lose_buff.true_bearing and 1 or 0 )
    return count
end )

spec:RegisterStateTable( "rtb_buffs_will_lose_buff", setmetatable( {}, {
    __index = function( t, k )
        return buff[ k ].up and buff[ k ].remains <= rtb_primary_remains + 0.1
    end
} ) )

spec:RegisterStateTable( "rtb_buffs_will_retain_buff", setmetatable( {}, {
    __index = function( t, k )
        return buff[ k ].up and not rtb_buffs_will_lose_buff[ k ]
    end
} ) )

spec:RegisterStateExpr( "cp_max_spend", function ()
    return combo_points.max
end )

spec:RegisterUnitEvent( "UNIT_POWER_UPDATE", "player", nil, function( event, unit, resource )
    if resource == "COMBO_POINTS" then
        Hekili:ForceUpdate( event, true )
    end
end )

spec:RegisterStateExpr( "mantle_duration", function ()
    return legendary.mark_of_the_master_assassin.enabled and 4 or 0
end )

spec:RegisterStateExpr( "master_assassin_remains", function ()
    if not legendary.mark_of_the_master_assassin.enabled then
        return 0
    end

    if stealthed.mantle then
        return cooldown.global_cooldown.remains + 4
    elseif buff.master_assassins_mark.up then
        return buff.master_assassins_mark.remains
    end

    return 0
end )

spec:RegisterStateExpr( "cp_gain", function ()
    return ( this_action and class.abilities[ this_action ].cp_gain or 0 )
end )

spec:RegisterStateExpr( "effective_combo_points", function ()
    local c = combo_points.current or 0

    if c > 0 and buff.supercharged_combo_points.up then
        c = c + ( talent.forced_induction.enabled and 3 or 2 )
    end

    return c
end )

-- We need to break stealth when we start combat from an ability.
spec:RegisterHook( "runHandler", function( ability )
    local a = class.abilities[ ability ]

    if stealthed.all and ( not a or a.startsCombat ) then
        if buff.stealth.up then
            setCooldown( "stealth", 2 )
            if buff.take_em_by_surprise.up then
                buff.take_em_by_surprise.expires = query_time + 10 * talent.take_em_by_surprise.rank
            end
            if talent.subterfuge.enabled then
                applyBuff( "subterfuge" )
            end
        end

        if legendary.mark_of_the_master_assassin.enabled and stealthed.mantle then
            applyBuff( "master_assassins_mark" )
        end

        removeBuff( "stealth" )
        removeBuff( "shadowmeld" )
        removeBuff( "vanish" )
    end
    if buff.cold_blood.up and ( ability == "ambush" or not talent.inevitable_end.enabled ) and ( not a or a.startsCombat ) then
        removeStack( "cold_blood" )
    end

    class.abilities.apply_poison = class.abilities[ action.apply_poison_actual.next_poison ]
end )

spec:RegisterHook( "spend", function( amt, resource )
    if amt > 0 and resource == "combo_points" then
        if amt >= 5 and talent.ruthlessness.enabled then gain( 1, "combo_points" ) end

        local cdr = amt * ( buff.true_bearing.up and 1.5 or 1 )

        for _, action in ipairs( restless_blades_list ) do
            reduceCooldown( action, cdr )
        end

        if talent.float_like_a_butterfly.enabled then
            reduceCooldown( "evasion", amt * 0.5 )
            reduceCooldown( "feint", amt * 0.5 )
        end

        if legendary.obedience.enabled and buff.flagellation_buff.up then
            reduceCooldown( "flagellation", amt )
        end
    end
end )

local ExpireAdrenalineRush = setfenv( function ()
    gain( energy.max, "energy" )
end, state )

for i = 1, 7 do
    spec:RegisterStateExpr( "supercharge_" .. i, function ()
        return buff.supercharged_combo_points.stack >= i
    end )
end

spec:RegisterHook( "reset_precast", function()
    -- Supercharged Combo Point handling
    local cPoints = GetUnitChargedPowerPoints( "player" )
    if talent.supercharger.enabled and cPoints then
        local charged = 0
        for _, point in pairs( cPoints ) do
            charged = charged + 1
        end
        if charged > 0 then applyBuff( "supercharged_combo_points", nil, charged ) end
    end

   -- if buff.killing_spree.up then setCooldown( "global_cooldown", max( gcd.remains, buff.killing_spree.remains ) ) end

    if buff.adrenaline_rush.up and talent.improved_adrenaline_rush.enabled then
        state:QueueAuraExpiration( "adrenaline_rush", ExpireAdrenalineRush, buff.adrenaline_rush.expires )
    end

    if buff.cold_blood.up then setCooldown( "cold_blood", action.cold_blood.cooldown ) end

    class.abilities.apply_poison = class.abilities[ action.apply_poison_actual.next_poison ]

    if talent.unseen_blade.enabled then

        -- Resync with real-data local variables first
        last_unseen_blade = nil
        disorient_stacks = nil

        -- Sync unseen blade ICD with gamestate
        local unseenBladeCD = 20 - ( query_time - last_unseen_blade )
        if unseenBladeCD > 0 then
            applyDebuff( "player", "unseen_blade", unseenBladeCD )
        else
            removeDebuff( "player", "unseen_blade" )
        end

        if Hekili.ActiveDebug then
            Hekili:Debug( "UB-Status: unseen_blades_available=%d DS=%d  ICD=%.1f",
              unseen_blades_available,
              disorient_stacks or 0,
              ( unseenBladeCD > 0 and unseenBladeCD or 0 )
            )
        end

        if prev[1].coup_de_grace and buff.escalating_blade.at_max_stacks then
            if set_bonus.tww3 >= 4 then
                local dur = 5 + ( gcd.max ) - ( query_time - action.coup_de_grace.lastCast )
                applyBuff( "tww3_trickster_4pc", dur )
                applyBuff( "escalating_blade", dur, 4 )
                applyBuff( "coup_de_grace", dur )
            end
        end

    end

    -- Debugging for Roll the Bones
    if Hekili.ActiveDebug and buff.roll_the_bones.up then
       -- local elapsed = query_time - lastRoll
       -- local remaining = max( 0, rollDuration - elapsed )
       -- local pandemic = min( 9, remaining )
       -- Hekili:Debug( "RTB: elapsed=%.2f  pandemic=%.2f  duration=%.2f",
       --               elapsed, pandemic, rollDuration )
        Hekili:Debug( "RTB   queueBase=%.2f (lastRoll=%.2f / lastCast=%.2f)  rollDur=%.2f",
                      max( lastRoll or 0, action.roll_the_bones.lastCast or 0 ),
                      lastRoll or 0,
                      action.roll_the_bones.lastCast or 0,
                      rollDuration )
        Hekili:Debug( "\nRoll the Bones Debugging:" )
        Hekili:Debug( " - lastRoll: %.2f", lastRoll )
        Hekili:Debug( " - rollDuration: %.2f", rollDuration )
        Hekili:Debug( " - rtb_primary_remains: %.2f", rtb_primary_remains )
        Hekili:Debug( " - Totals  | longer: %d  normal: %d  shorter: %d  willLose: %d",
        rtb_buffs_longer, rtb_buffs_normal, rtb_buffs_shorter, rtb_buffs_will_lose )

        local lenTol = 0.2                             -- length tolerance for "longer" and "shorter"
        local primary  = rtb_primary_remains
        Hekili:Debug(" - Buff Status (vs. %.2f):", rtb_primary_remains)

        for i = 1, #rtb_buff_list do
            local name = rtb_buff_list[i]
            local b = buff[name]
            if b.up then
                local diff = b.remains - primary
                local label = diff > lenTol and "longer"
                             or diff < -lenTol and "shorter"
                             or                     "normal"
                local lose = rtb_buffs_will_lose_buff[name] and "*" or " "  -- mark with * what buff will be lost
                Hekili:Debug("   %s %-20s %5.2f [%s]", lose, name, b.remains, label)
            end
        end
    end

    -- Fan the Hammer.
    if query_time - lastShot < 0.5 and numShots > 0 then
        local n = numShots * ( action.pistol_shot.cp_gain - 1 )

        if Hekili.ActiveDebug then Hekili:Debug( "Generating %d combo points from pending Fan the Hammer casts; removing %d stacks of Opportunity.", n, numShots ) end
        gain( n, "combo_points" )
        removeStack( "opportunity", numShots )
    end

    if talent.underhanded_upper_hand.enabled and buff.adrenaline_rush.up then
        -- Revisit for all Stealth effects (and then resume countdown upon breaking Stealth).
        if buff.subterfuge.up then
            buff.adrenaline_rush.expires = buff.adrenaline_rush.expires + buff.subterfuge.remains
        end
        if buff.blade_flurry.up then
            buff.blade_flurry.expires = buff.blade_flurry.expires + buff.adrenaline_rush.remains
        end
    end

    if talent.double_jeopardy.enabled then
        if exitedStealth > 0 then
            if Hekili.ActiveDebug then Hekili:Debug( "Double Jeopardy: Applying pseudobuff since Fatebound Coin not applied since exiting Stealth at %.2f.", exitedStealth ) end
            applyBuff( "double_jeopardy" )
        elseif stealthed.all then
            if Hekili.ActiveDebug then Hekili:Debug( "Double Jeopardy: Applying pseudobuff since we are Stealth.", exitedStealth ) end
            applyBuff( "double_jeopardy" )
        end
    end
end )

spec:RegisterGear( {
    -- The War Within
    tww3 = {
        items = { 237667, 237665, 237663, 237664, 237662 },
        auras = {
            tww3_trickster_4pc = {
                -- id = 999998,
                duration = 5,
                max_stack = 1,
                generate = function( t )
                    local cdg = buff.escalating_blade
                    local delta = query_time - action.coup_de_grace.lastCast
                    if set_bonus.tww3 >= 4 and cdg.up and cdg.at_max_stacks and delta < 5 then
                        -- Only treat this as the "trickster window" version if it's the 5s duration .. use 10s just as a safety net. The other version of the aura is 3600
                        t.name = "tww3_trickster_4pc"
                        t.count = 1
                        t.expires = cdg.expires
                        t.applied = cdg.expires - 5
                        t.caster = "player"
                    else
                        t.name = "tww3_trickster_4pc"
                        t.count = 0
                        t.expires = 0
                        t.applied = 0
                        t.caster = "nobody"
                    end
                end
            }
        },
    },
    tww2 = {
        items = { 229290, 229288, 229289, 229287, 229292 },
        auras = {
            -- 2-set
            winning_streak = {
                id = 1217078,
                duration = 3600,
                max_stack = 10
            }
        }
    },

    -- Dragonflight
    tier31 = {
        items = { 207234, 207235, 207236, 207237, 207239, 217208, 217210, 217206, 217207, 217209 }
    },
    tier30 = {
        items = { 202500, 202498, 202497, 202496, 202495 },
        auras = {
            soulrip = {
                id = 409604,
                duration = 8,
                max_stack = 1
            },
            soulripper = {
                id = 409606,
                duration = 15,
                max_stack = 1
            }
        }
    },
    tier29 = {
        items = { 200372, 200374, 200369, 200371, 200373 },
        auras = {
            vicious_followup = {
                id = 394879,
                duration = 15,
                max_stack = 1
            },
            brutal_opportunist = {
                id = 394888,
                duration = 15,
                max_stack = 1
            }
        }
    },

    -- Legion Legendary
    mantle_of_the_master_assassin = {
        items = { 144236 },
        auras = {
            master_assassins_initiative = {
                id = 235027,
                duration = 3600
            }
        }
    }
} )

-- Abilities
spec:RegisterAbilities( {
    -- Talent: Increases your Energy regeneration rate by $s1%, your maximum Energy by $s4, and your attack speed by $s2% for $d.
    adrenaline_rush = {
        id = 13750,
        cast = 0,
        cooldown = 180,
        gcd = "off",

        talent = "adrenaline_rush",
        startsCombat = true,
        texture = 136206,
        usable = function () return target.distance <= 10, "target must be nearby" end,
        toggle = "cooldowns",

        cp_gain = function () return talent.improved_adrenaline_rush.enabled and combo_points.max or 0 end,

        handler = function ()
            applyBuff( "adrenaline_rush" )
            if talent.improved_adrenaline_rush.enabled then
                gain( action.adrenaline_rush.cp_gain, "combo_points" )
                state:QueueAuraExpiration( "adrenaline_rush", ExpireAdrenalineRush, buff.adrenaline_rush.remains )
            end

            if talent.edge_case.enabled then
                addStack( "fatebound_coin_heads" )
                addStack( "fatebound_coin_tails" )
            end

            energy.regen = energy.regen * 1.6
            energy.max = energy.max + 50
            forecastResources( "energy" )

            if talent.loaded_dice.enabled then
                applyBuff( "loaded_dice" )
            end
            if talent.underhanded_upper_hand.enabled and buff.subterfuge.up then
                buff.adrenaline_rush.expires = buff.adrenaline_rush.expires + buff.subterfuge.remains
            end
            if azerite.brigands_blitz.enabled then
                applyBuff( "brigands_blitz" )
            end
        end
    },

    -- Finishing move that deals damage with your pistol, increasing your critical strike chance by $s2%.$?a235484[ Critical strikes with this ability deal four times normal damage.][];    1 point : ${$<damage>*1} damage, 3 sec;    2 points: ${$<damage>*2} damage, 6 sec;    3 points: ${$<damage>*3} damage, 9 sec;    4 points: ${$<damage>*4} damage, 12 sec;    5 points: ${$<damage>*5} damage, 15 sec$?s193531|((s394320|s394321)&!s193531)[;    6 points: ${$<damage>*6} damage, 18 sec][]$?s193531&(s394320|s394321)[;    7 points: ${$<damage>*7} damage, 21 sec][]
    between_the_eyes = {
        id = 315341,
        cast = 0,
        cooldown = function () return talent.crackshot.enabled and stealthed.rogue and 0 or 45 end,
        gcd = "totem",
        school = "physical",

        spend = function() return 25 * ( talent.tight_spender.enabled and 0.94 or 1 ) end,
        spendType = "energy",

        startsCombat = true,
        texture = 135610,

        usable = function() return combo_points.current > 0, "requires combo points" end,

        handler = function ()
            if talent.alacrity.rank > 1 and effective_combo_points > 9 then addStack( "alacrity" ) end

            applyBuff( "between_the_eyes" )

            if stealthed.rogue and talent.crackshot.enabled then
                spec.abilities.dispatch.handler()
            end

            if set_bonus.tier30_4pc > 0 and ( debuff.soulrip.up or active_dot.soulrip > 0 ) then
                removeDebuff( "target", "soulrip" )
                active_dot.soulrip = 0
                applyBuff( "soulripper" )
            end

            if azerite.deadshot.enabled then
                applyBuff( "deadshot" )
            end

            if legendary.greenskins_wickers.enabled or talent.greenskins_wickers.enabled and effective_combo_points >= 5 then
                applyBuff( "greenskins_wickers" )
            end

            if buff.double_jeopardy.up and combo_points.current > 4 then removeBuff( "double_jeopardy" ) end

            spend( combo_points.current, "combo_points" )
            removeStack( "supercharged_combo_points" )
        end
    },

    -- Strikes up to $?a272026[$331850i][${$331850i-3}] nearby targets for $331850s1 Physical damage$?a381878[ that generates 1 combo point per target][], and causes your single target attacks to also strike up to $?a272026[${$s3+$272026s3}][$s3] additional nearby enemies for $s2% of normal damage for $d.
    blade_flurry = {
        id = 13877,
        cast = 0,
        cooldown = 30,
        gcd = "totem",
        school = "physical",
        usable = function () return target.distance <= 10, "target must be nearby" end,
        spend = 15,
        spendType = "energy",

        startsCombat = true,

        cp_gain = function() return talent.deft_maneuvers.enabled and true_active_enemies or 0 end,
        handler = function ()
            applyBuff( "blade_flurry" )
            if talent.deft_maneuvers.enabled then gain( action.blade_flurry.cp_gain, "combo_points" ) end
            if talent.underhanded_upper_hand.enabled and buff.adrenaline_rush.up then buff.blade_flurry.expires = buff.blade_flurry.expires + buff.adrenaline_rush.remains end
        end
    },

    -- Talent: Charge to your target with your blades out, dealing ${$271881sw1*$271881s2/100} Physical damage to the target and $271881sw1 to all other nearby enemies.    While Blade Flurry is active, damage to non-primary targets is increased by $s1%.    |cFFFFFFFFGenerates ${$271896s1*$271896d/$271896t1} Energy over $271896d.
    blade_rush = {
        id = 271877,
        cast = 0,
        cooldown = 45,
        gcd = "totem",
        school = "physical",

        talent = "blade_rush",
        startsCombat = true,

        usable = function () return not settings.check_blade_rush_range or target.distance < ( talent.acrobatic_strikes.enabled and 9 or 6 ), "no gap-closer blade rush is on, target too far" end,

        handler = function ()
            applyBuff( "blade_rush" )
            setDistance( 5 )
        end
    },

    death_from_above = {
        id = 269513,
        cast = 0,
        cooldown = 30,
        gcd = "off",
        icd = 2,

        spend = function() return talent.tight_spender.enabled and 22.5 or 25 end,
        spendType = "energy",

        pvptalent = "death_from_above",
        startsCombat = true,

        usable = function() return combo_points.current > 0, "requires combo points" end,

        handler = function ()
            if buff.double_jeopardy.up and combo_points.current > 4 then removeBuff( "double_jeopardy" ) end
            spend( combo_points.current, "combo_points" )
            removeStack( "supercharged_combo_points" )
        end
    },

    dismantle = {
        id = 207777,
        cast = 0,
        cooldown = 45,
        gcd = "spell",

        spend = 25,
        spendType = "energy",

        pvptalent = "dismantle",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "dismantle" )
        end
    },

    dispatch = {
        id = 2098,
        cast = 0,
        cooldown = 0,
        gcd = "totem",
        school = "physical",

        spend = function() return 35 * ( talent.tight_spender.enabled and 0.94 or 1 ) - ( 5 * buff.summarily_dispatched.stack ) end,
        spendType = "energy",

        startsCombat = true,

        usable = function() return combo_points.current > 0, "requires combo points" end,
        nobuff = "coup_de_grace",

        handler = function ()
            removeBuff( "brutal_opportunist" )

            if talent.alacrity.rank > 1 and effective_combo_points > 9 then addStack( "alacrity" ) end

            if talent.summarily_dispatched.enabled and combo_points.current > 5 then
                addStack( "summarily_dispatched", ( buff.summarily_dispatched.up and buff.summarily_dispatched.remains or nil ), 1 )
            end


            if buff.slice_and_dice.up then
                buff.slice_and_dice.expires = buff.slice_and_dice.expires + combo_points.current * 3
            else applyBuff( "slice_and_dice", combo_points.current * 3 ) end

            if set_bonus.tier29_2pc > 0 then applyBuff( "vicious_followup" ) end

            if buff.double_jeopardy.up and combo_points.current > 4 then removeBuff( "double_jeopardy" ) end

            spend( combo_points.current, "combo_points" )
            removeStack( "supercharged_combo_points" )
        end,

        bind = "coup_de_grace"
    },

    -- Finishing move that dispatches the enemy, dealing damage per combo point:     1 point  : ${$m1*1} damage     2 points: ${$m1*2} damage     3 points: ${$m1*3} damage     4 points: ${$m1*4} damage     5 points: ${$m1*5} damage$?s193531|((s394320|s394321)&!s193531)[     6 points: ${$m1*6} damage][]$?s193531&(s394320|s394321)[     7 points: ${$m1*7} damage][]
    coup_de_grace = {
        id = 441776,
        cast = 0,
        cooldown = 0,
        gcd = "totem",
        school = "physical",
        known = 2098,

        spend = function() return 35 * ( talent.tight_spender.enabled and 0.94 or 1 ) - ( 5 * buff.summarily_dispatched.stack ) end,
        spendType = "energy",

        startsCombat = true,

        usable = function() return combo_points.current > 0, "requires combo points" end,
        buff = "coup_de_grace",
        talent = "coup_de_grace",

        handler = function ()
            spec.abilities.dispatch.handler()

            if debuff.fazed.up then addStack( "flawless_form", nil, 5 ) end

            if set_bonus.tww3 >= 4 and buff.tww3_trickster_4pc.down  then
                applyBuff( "coup_de_grace", ( 5 + gcd.max ) ) -- recast within 5 seconds
                applyBuff( "tww3_trickster_4pc", ( 5 + gcd.max ) )
                applyBuff( "escalating_blade", ( 5 + gcd.max ), 4 )
            else
                removeBuff( "coup_de_grace" )
                removeBuff( "escalating_blade" )
                removeBuff( "tww3_trickster_4pc" )
            end

            setCooldown( "global_cooldown", 1.2 * ( buff.adrenaline_rush.up and haste or 1) )
        end,

        bind = "dispatch"
    },

    -- Talent: Strikes an enemy, dealing $s1 Physical damage and causing the target to take $s3% increased damage from your abilities for $d.    |cFFFFFFFFAwards $s2 combo $lpoint:points;.|r
    ghostly_strike = {
        id = 196937,
        cast = 0,
        cooldown = 90,
        gcd = "off",
        school = "physical",

        spend = 30,
        spendType = "energy",

        talent = "ghostly_strike",
        startsCombat = true,

        cp_gain = function () return 1 + ( buff.broadside.up and 1 or 0 ) end,

        handler = function ()
            applyDebuff( "target", "ghostly_strike" )
            gain( action.ghostly_strike.cp_gain, "combo_points" )
        end
    },

     -- Talent: Launch a grappling hook and pull yourself to the target location.
    grappling_hook = {
        id = 195457,
        cast = 0,
        cooldown = function () return ( 1 - conduit.quick_decisions.mod * 0.01 ) * ( talent.retractable_hook.enabled and 45 or 60 ) end,
        gcd = "off",
        school = "physical",

        startsCombat = false,
        texture = 1373906,

        handler = function ()
        end
    },

    -- Talent: Increase the remaining duration of your active Roll the Bones combat enhancements by $s1 sec.
    keep_it_rolling = {
        id = 381989,
        cast = 0,
        cooldown = 360,
        gcd = "off",
        school = "physical",

        talent = "keep_it_rolling",
        startsCombat = true,

        toggle = "cooldowns",
        buff = "roll_the_bones",

        handler = function ()
           for _, v in pairs( rtb_buff_list ) do
                if buff[ v ].up then
                    -- Add 30 seconds but cap the total duration at 60 seconds.
                    local newExpires = buff[ v ].expires + 30
                    buff[ v ].expires = min( newExpires, query_time + 60 )

                    -- Optional Debugging
                    if Hekili.ActiveDebug then
                        Hekili:Debug( "Keep It Rolling applied to '%s': New expires = %.2f (capped at 60 seconds).", v, buff[ v ].expires )
                    end
                end
            end
        end
    },

    -- Talent: Teleport to an enemy within 10 yards, attacking with both weapons for a total of $<dmg> Physical damage over $d.    While Blade Flurry is active, also hits up to $s5 nearby enemies for $s2% damage.
    killing_spree = {
        id = 51690,
        cast = function () return 0.5 * effective_combo_points * haste end,
        channeled = true,
        tick_time = function () return 0.5 * haste end,
        cooldown = function () return 180 * ( talent.disorienting_strikes.enabled and 0.9 or 1 ) end,
        gcd = "spell",
        school = "physical",
        texture = 6735718,
        spend = function () return 45 * ( talent.tight_spender.enabled and 0.94 or 1 ) end,
        spendType = "energy",
        talent = "killing_spree",
        startsCombat = true,
        toggle = "cooldowns",
        usable = function() return combo_points.current > 0 and target.distance <= 8, "requires combo_points" end,
        handler = function ()

        end,

        -- No tick_time/tick, no finish-refund – resource model does it.
        start = function ()
            if buff.double_jeopardy.up and combo_points.current > 4 then removeBuff( "double_jeopardy" ) end

            applyBuff( "killing_spree" )
            spend( combo_points.current, "combo_points" )
            removeStack( "supercharged_combo_points" )
            if talent.disorienting_strikes.enabled then
                disorient_stacks = 2
                unseen_blades_available = unseen_blades_available + 2
            end
            if talent.flawless_form.enabled then addStack( "flawless_form" ) end
        end,
        finish = function() end,
    },

    -- Draw a concealed pistol and fire a quick shot at an enemy, dealing ${$s1*$<CAP>/$AP} Physical damage and reducing movement speed by $s3% for $d.    |cFFFFFFFFAwards $s2 combo $lpoint:points;.|r
    pistol_shot = {
        id = 185763,
        cast = 0,
        cooldown = 0,
        gcd = "totem",
        school = "physical",

        spend = function () return 40 - ( buff.opportunity.up and 20 or 0 ) end,
        spendType = "energy",

        startsCombat = true,

        cp_gain = function () return buff.shadow_blades.up and combo_points.max or ( 1 + ( buff.broadside.up and 1 or 0 ) + ( talent.quick_draw.enabled and buff.opportunity.up and 1 or 0 ) + ( buff.concealed_blunderbuss.up and 2 or 0 ) ) end,

        handler = function ()
            gain( action.pistol_shot.cp_gain, "combo_points" )

            removeBuff( "deadshot" )
            removeBuff( "concealed_blunderbuss" ) -- Generating 2 extra combo points is purely a guess.
            removeBuff( "greenskins_wickers" )
            
            if buff.opportunity.up then
                removeStack( "opportunity" )
                if set_bonus.tier29_4pc > 0 then applyBuff( "brutal_opportunist" ) end
            end

            -- If Fan the Hammer is talented, let's generate more.
            if talent.fan_the_hammer.enabled then
                local shots = min( talent.fan_the_hammer.rank, buff.opportunity.stack )
                gain( shots * ( action.pistol_shot.cp_gain - 1 ), "combo_points" )
                removeStack( "opportunity", shots )
            end
        end
    },

    -- Talent: Roll the dice of fate, providing a random combat enhancement for $d.
    roll_the_bones = {
        id = 315508,
        cast = 0,
        cooldown = 45,
        gcd = "totem",
        school = "physical",

        spend = 25,
        spendType = "energy",

        startsCombat = true,

        handler = function ()
            local pandemic = 0

            for _, name in pairs( rtb_buff_list ) do
                if rtb_buffs_will_lose_buff[ name ] then
                    pandemic = min( 9, max( pandemic, buff[ name ].remains ) )
                    removeBuff( name )
                end
            end

            if talent.supercharger.enabled then
                addStack( "supercharged_combo_points", nil, talent.supercharger.rank )
            end

            if azerite.snake_eyes.enabled then
                applyBuff( "snake_eyes", nil, 5 )
            end

            applyBuff( "rtb_buff_1", nil, 30 + pandemic )

            if buff.loaded_dice.up then
                applyBuff( "rtb_buff_2", nil, 30 + pandemic )
                removeBuff( "loaded_dice" )
            end

            if pvptalent.take_your_cut.enabled then
                applyBuff( "take_your_cut" )
            end

        end
    },


    shiv = {
        id = 5938,
        cast = 0,
        cooldown = 25,
        gcd = "totem",
        school = "physical",

        spend = function () return legendary.tiny_toxic_blade.enabled and 0 or 20 end,
        spendType = "energy",

        talent = "shiv",
        startsCombat = true,

        cp_gain = function () return 1 + ( buff.shadow_blades.up and 1 or 0 ) + ( buff.broadside.up and 1 or 0 ) end,

        handler = function ()
            gain( action.shiv.cp_gain, "combo_points" )
            removeDebuff( "target", "dispellable_enrage" )
        end
    },

    shroud_of_concealment = {
        id = 114018,
        cast = 0,
        cooldown = 360,
        gcd = "totem",
        school = "physical",

        startsCombat = false,

        toggle = "interrupts",

        handler = function ()
            applyBuff( "shroud_of_concealment" )
        end
    },

    ambush = {
        id = 8676,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        spend = 50,
        spendType = "energy",

        startsCombat = true,
        usable = function () return stealthed.ambush or buff.audacity.up, "requires stealth or audacity/blindside/sepsis_buff" end,

        cp_gain = function ()
            return 2 + ( buff.broadside.up and 1 or 0 ) + talent.improved_ambush.rank + ( buff.cold_blood.up and not talent.inevitable_end.enabled and 1 or 0 )
        end,

        handler = function ()
            gain( action.ambush.cp_gain, "combo_points" )
            if buff.audacity.up then removeBuff( "audacity" ) end
            if talent.unseen_blade.enabled then TriggerUnseenBlade() end

        end,

        copy = 430023,
        bind = "sinister_strike"
    },

    sinister_strike = {
        id = 193315,
        known = 1752,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        spend = 45,
        spendType = "energy",

        startsCombat = true,
        texture = 136189,


        cp_gain = function () return 1 + ( buff.broadside.up and 1 or 0 ) end,

        handler = function ()
            gain( action.sinister_strike.cp_gain, "combo_points" )
            removeStack( "snake_eyes" )
            if talent.unseen_blade.enabled then TriggerUnseenBlade() end
            if talent.echoing_reprimand.enabled then removeBuff( "echoing_reprimand" ) end

        end,

        copy = 1752,

        bind = "ambush"
    },

    smoke_bomb = {
        id = 212182,
        cast = 0,
        cooldown = 180,
        gcd = "spell",

        pvptalent = "smoke_bomb",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "smoke_bomb" )
        end
    },
} )

-- Override this for rechecking.
spec:RegisterAbility( "shadowmeld", {
    id = 58984,
    cast = 0,
    cooldown = 120,
    gcd = "off",

    usable = function () return boss and group end,
    handler = function ()
        applyBuff( "shadowmeld" )
    end
} )

spec:RegisterRanges( "pick_pocket", "kick", "blind", "shadowstep" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = true,
    nameplateRange = 10,
    rangeFilter = false,

    damage = true,
    damageExpiration = 6,

    potion = "tempered_potion",

    package = "狂徒Simc",
} )

local assassin = class.specs[ 259 ]

spec:RegisterSetting( "check_blade_rush_range", true, {
    name = strformat( "%s: Melee Only", Hekili:GetSpellLinkWithTexture( spec.abilities.blade_rush.id ) ),
    desc = strformat( "If checked, %s will not be recommended out of melee range.", Hekili:GetSpellLinkWithTexture( spec.abilities.blade_rush.id ) ),
    type = "toggle",
    width = "full"
} )

spec:RegisterSetting( "allow_shadowmeld", false, {
    name = strformat( "%s: Use in Groups", Hekili:GetSpellLinkWithTexture( 58984 ) ),
    desc = strformat( "If checked, %s may be recommended for Night Elves when its conditions are met.  Your stealth-based abilities can be used in %s, even if your action bar does not change.  " ..
    "%s can only be recommended in boss fights or when you are in a group, to avoid resetting combat.", Hekili:GetSpellLinkWithTexture( 58984 ), Hekili:GetSpellLinkWithTexture( 58984 ), Hekili:GetSpellLinkWithTexture( 58984 ) ),
    type = "toggle",
    width = "full",
    get = function () return not Hekili.DB.profile.specs[ 260 ].abilities.shadowmeld.disabled end,
    set = function ( _, val )
        Hekili.DB.profile.specs[ 260 ].abilities.shadowmeld.disabled = not val
    end,
} )

spec:RegisterSetting( "solo_vanish", true, {
    name = strformat( "Allow %s When Solo", Hekili:GetSpellLinkWithTexture( 1856 ) ),  -- Vanish
    desc = strformat( "If enabled, %s can be recommended even when you are alone, |cFFFF0000which may reset combat|r.", Hekili:GetSpellLinkWithTexture( 1856 ) ),
    type = "toggle",
    width = "full"
} )

spec:RegisterSetting( "vanish_charges_reserved", 0, {
    name = strformat( "Reserve %s Charges", Hekili:GetSpellLinkWithTexture( 1856 ) ),
    desc = strformat( "If set above zero, %s will not be recommended if it would leave you with fewer than this number of (fractional) charges.", Hekili:GetSpellLinkWithTexture( 1856 ) ),
    type = "range",
    min = 0,
    max = 2,
    step = 0.1,
    width = 1.5
} )

spec:RegisterSetting( "sinister_clash", -0.5, {
    name = strformat( "%s: Clash Buffer", Hekili:GetSpellLinkWithTexture( spec.abilities.sinister_strike.id ) ),
    desc = strformat( "If set below zero, %s will not be recommended when a higher priority ability is available within the time specified.\n\n"
        .. "Example: %s is ready in 0.3 seconds.  |W%s|w is ready immediately.  Clash Buffer is set to |W|cFF00B4FF-0.5s|r.|w  |W%s|w will not "
        .. "be recommended as it pretends to be unavailable for 0.5 seconds.\n\n"
        .. "Recommended: |cFF00B4FF-0.5s|r", Hekili:GetSpellLinkWithTexture( spec.abilities.sinister_strike.id ),
        Hekili:GetSpellLinkWithTexture( assassin.abilities.ambush.id ), spec.abilities.sinister_strike.name, spec.abilities.sinister_strike.name ),
    type = "range",
    min = -3,
    max = 3,
    step = 0.1,
    get = function () return Hekili.DB.profile.specs[ 260 ].abilities.sinister_strike.clash end,
    set = function ( _, val )
        Hekili.DB.profile.specs[ 260 ].abilities.sinister_strike.clash = val
    end,
    width = 1.5,
} )

spec:RegisterPack( "狂徒Simc", 20250828, [[Hekili:DZtBVXTr69BXFXw6K06DxzP4eyBaBN4y78MRKtZhkQ4ol5S7slUKmCiLIkcwKEf9AUC3H2E9coG2G2McChcoK76HwG20Cj39JPskUFk)f6ZZZmC4mKd5UYjbfOagwsKZlpZZ7Vn8Gbh84d2pGLZp41h2F4o9F((d61F3T3D42hSF(jP8d2pL5FiBk8lXS5W))v)OV)z)(F6(HZ9XxDsuclaxcrsrMp86z55PIx4QxDAy(SIX98tMFvr48IiwEysSFgBso(3(xDCuY4RMpJFml7yyOHXx92(4qEuwyswy(jVAOixC1a(ewru(vZsMwW9skYJyh3tq794IWO8heFWy3G)b7ZkYNLKDW(aOExaUcdc4YrZfW03ARfJE8m(IrVfld(pcewmAFotKa)C7fpexUT6F9TgU7lSy0TF0RcV8Ky)fJG5nMnHD9NBs1y6VdmM7fMjYLd9HlEy3R)WY5ETTgIZfHXfJEZu8Ku9QbdB9v93T(Rqa71twmAEsg8h3nPiDXOa43E5mMp8J7umTC2BV1WTBzH3ERbvGtH1RgSvFeCUDAA0jWUeke8a7rkwmAT8zS4dHF5bpG)40e)17rthok9LB6aG80Bh1d7)8aYBZfJGFoOV6No3E5qX5)OKqabkkFkqE2roX(d0tmlFSxgpljkAXO8J5SdngnEe2Jls5(aP6vFXfJEJuEmhOqcEEEy80QHsqYRXEsc8Ym(rHIqCFhnjlzUAJ0dT)Z)cvKHjHXHIz4s6NeheM3X021ey(Jz48akhauhpJhtZxegWZqWA0DYFj45aBemcGIEOywsE5s9CBn86Vqt2Td2pcfIqPZJOfh(TxNK35XSXr8GdUdiLqsD6rqshzHPYhwctfcqbaCiqCHiNfhWYaApkbgaNnyNFR3ABqaao)JtkIHxXIoMDc8kwEoFEAo8B5j4tdNgxDsLNMxEwIihzP2ppl8qoqn)tUp)WWOW)uKxoiCsiYNrB9KKiK364zWAfekWZqJ5JelqPZCoaKeUV3b7dhOCanYaTu8CVXjXfIE5hF82EtkHyVHPGO9LrCEsuqYXX9MkxwpbTQ9YZa9pz85SqKAEtGLJgEolIhNxFWLO3CqP0fbDBGarCdOUtIAbCcE8lX3639kHrreZX(PzCUgBlr2ZGdsfUMWFs2kItkewNK4QZlmzCB3d0zgXfWlFeGgjEE5yr4(iUfUCnypaPmVCyV7nPc0F33DXOlPrnhkHrpbcILyMfJwNqFRrJuJZhZbXvEShywWJFcx0lJZcoHg54Ijt6LPGoV0sGRNMKCRfJUMCVffP8m)zSSPCVb27u3KFBa3nnfwpKSU9fHS(4SqqEnNxJe2K(bY0fMeTWjnhdsmIbr)rO(DrcGcKI7LcH6nBZA8dof(yK4cCCrbOcsJEnlhwK8k6DE1z6YlJwBkwzpetQ329ljusKj46qrQxa3Bkbg5HZ5EIWy0w2na5Vb91eSAuvnO5DnKQs0RRDrOxMOF2yssdrG(maVi5ResbsWreatvKrkAKKgqTdrTuuMgkgpoeTkjcZLIFZzVJXAscPSyK2cQWO1PM2nlQHgPkpf9Muefb6OuS(icdqvaMANVTLaKdCCcQN4YOfVPZYRuoEdAV0hQV3IrxxsfYrgiwu(mp4emx0L1i54e5jXCB(p8X9sr7L3av)uTAGsJmUav6jn75j9w1Ad7qFCy8rHttqkjWCItc)zAI8LFBcaTP5GfnLLf(D5wdO)5G7itjU1Uq(WEohCYY7OqwuRqaicEnPel6)00tiz4b9raiM75dqY16cFpHhgN31Ipl1BkkWzVbd3PYAaTe9KgVK83zSyGXh8NcKdMZMgQ4OZroXCV5oEvqsEZhAUmPZor026y(UQfQ8PRxdvaNw0LuY4gibY7K)V2iT1p9AGCwoddNypPpUOFF3bhi4eO0TxP29(smLTlqO3X0tLUX0frQtOqB0ziyPz)ioQeauQb6mVp4kHYLL9RSfNPbouV6jjfLkdJseCcwXjmOeKr3zrfQGg)OIaurcozsNyi4DxqiO5c1lcbuIgHELhSNPHqeMcsIVsUEpDmhW4xmlhuFdVFh5(kxOAE5yPZCO0QIKFGutkKNDVKjEqWpbv6jnhJbEOUtqAcIhIp8KOdYexjF9rGMbCk9KddSjDe3lf2l(CKt7ge4tCU6LcmSyPr(AdDBUCOHrY2unT6Sb1j5LmIC4)X)6vtyb4b)fdrZ40ORZ4y6E7d2tZZaNyY24jySZo4QxbYKtsGebt6tIiGZlaGTEOlqRcj(YwU6Y5PG2wpfJQfDUgPwsGh2LRjRow3edT9wxtHE2e)Pelw53zsmY)to2GZrblmmJbGta4cS4DrpReCm4vuOJ4HWttRHrPq1TYjtCNkf0TYFoyqJahAfBIyTDEwXALbvHiU7)gocQYM)1hDhZebpuJ1KS22S0YWKubtj1Xj1cjXf3jdgngt)Mod1sjb9yiwtySCwwD8ElsVRgxO1OAvAWPOGdw3Y1Jg)4YZv5OVu7rSvBeuG1JvN1IuPHsIO0L9r28Xfn8B)o4S4zugjUpiVUyuQkzIlgDBAcLeT7tjdet(tAswErmmel8ScjjZzOxIXOAGQyfbmF8neS3QPubMvimMePZ01G83OihXEsTGWWqxH20iwUk20YqevNSW)moMvj5AxLcezG(VzSGtb8hXcurooTGbE3KZ5bvgyfyEwKbzeZlYbZHxnmlJhXHWkYvbL4aHvctwiocLeekaydqGuGEeijmi7QZhacKoidnWakHfjDbFmcZ9e5m)dLo(vHXnjhQbCdhVc1WOETTILUOQRxTnTbmOX0USwMc0IKipm)CovAFBfdZIrB0cEDdmIXyLFD3NbEUGbZJzdSadPZASyGPPzj(MRlzLug(xjBVoRbSJyHrKVeo43NWK5EzgTNw86QrO52D8UvrAX8L1ueutqQnZIeTWBsurw2jTPE3bwDtBrgI1LCM8UpsRkxjNCpATXSNau6nkD7N8iTsEukhkWvLpbFasikqD85KufJ05FSA9lILA6V9EiPGmi4iHAk8yaFceKbdKfbdoclCOCsEqarZdrxIV1nPSEjfH8tMpobcCecoOsjTI1xIHdYGfJckjd4k0o5CjZe5zKyNon02bD425ys4eYqu2wJabGCy5FOuRyKyKb37X3F9nBqei7VJ5LjNcXYeTtHyrpzoMR8GbRjrfnL)2fOJ94mibj2CyJGngt9ImWJPxCcGjoghxOpUC3uN2ktIZgonoUEReY1iK1wTKvvDAmDlRcA1pKaKbk62UpJQNgsX)Eif51fqpetrmq(EkPwK2sH0Hg8fvOD(7KgMTk6F0NPwu(RuGSw72fq06Ymm049MULouHnFUNrS5kJ)SrrKQA0FtkNJa7SYZqPEQb4JuOAW0)8I5RaYCvufVwBm4k2ZbetDfp4Bxa6k8cYyhxT8TY1)9wk37gsUxDcgBQqtn7sVkbp8f1Il46xyc1dMuMqDPYdhKSCD54As4gZiftyYCL5PAZs3Vm54bWi6evkKniN04u77FeImH4iqSznF()grrLqvpeo9QiO6NNXNIabqDg0BNM49kEavgjCtFnIv2ftHXRD6bHdFau0ZNVTCuAwCGAu03end3Oa42wKr5nh(nlDUobZwXXH4YuA6PryyMoXIa6G(TX5LKGzLVS)iQvWVOOXKMiCueBWtkWMiqK4c8iV44hjJlfEvG8Cy6KN2)UUd1bS(6fZFheUjGVECwxGqHAeugUEuyqTg7t1grr7PAYJotjnGO8K)HhMH7MzowLjCnq9mudafnTgnApU65sKDAc4KbHFxlgishvebYrseU2AEySuiILVEpJSaVTRWgS1fbHMLLvGLSZU4SYc4rSVIW5YsdfIdwc7AxyZNXY7vDIoeefD5mTfR8JoINEuQN)moYikLgZyHbicbCgK4r6GqyGOnkVGdphtsPehzw8nzAnXFlQGtjXBPSBDPI6wsFf2qVmHZHyJoIh4jznxbRux2OCdWQTtFcmvNp5Q4P7Rdx(zT8tPTznCx8tP8Hjs5ONEBr6z3IuE3mwz1jZVShqSXlDvtE3(4FbIGBnxAPD6cLczUUlfZL9hJHdJBnOSbzK1dfrqOKgIHuMk3AOuSA)szXATcJo5)KLB8Oc)kCwX53rYlqPkuxReOuqZqLAvDa1iay7TMWiaUk(d5QyZFu3ZXLZFSwdEtRYK)8eQDJkYXs6kIMtWkLBDpuW8ACG3CEu9I13yKJlYcbbnaNZefzlB0IdXAvJRTFgOqLswBZPyIBPCpwR0hD5WxNkQ8deUCUWIzTEge1wbW1zZsx7MWKvGllPyQYcbAwWS1VKXMYn1l3e4mu1AKMDlNmmpaLMQC54r1811nQbJ5fw1UCfC6RWknFzgD1Ug4eCD7P6nLDWWg2ESA41beKeyGnpjld0HrBX2MEFOEFArKOMRhV(GRzoWiSepcVNuemDoUs1g7oMJDmBkwmiPI0go0KsTGgy(x7sJgyWUNe19lW)YAdQJxK4nWcgpBc3p3Jj8XEAl2)epbpRyE1I2XyC4WHH7in98rd5EQkaDW(DwKQAPuY5cmOM)gonqvzeQR6xOgIz5jmFTZSCHoqvt0(rzCGDaKBVTESy9yk75hvaz6S9TXR8G92WSop9SBPhzqdzmznoXC8HoVj3bknx3nbnDfWMZMcgm6iPA1RE1Zk20oH3oqxTHqQ3qbUrislIMbnBHD6k9tnyyAePrLpB1iKRiL2joJeldBRRJQ3TEXhYZfRIey7Hew2jjHk4TTELc9yD4Qkk3wGlZzbEVDbNhJ1vnM6g(VDaTDkrco2bhQw0wckYGqM9O23Ylmij6BjWzGgEAUdouszrw3N8T(nJpjKRY8)RZrbwWaVyo6gys8uzn4yMnjzCagZvvtMi99tLrajSuOxtiKA9sEGDZjyu(uvs7x1QDB56TQt)mYCVUEUJHnBsX0M9P3kHAh2VI81YbYHEllm8RIP1NuDa65IP)qkkPsgSSLvRYVbADpib1XqAsccfYiFb8)WykLABjlOICv047NueF4Cgevo45i4A6uMNC)AuhYgTtSkPy0lBBvmR54oxae4ov4Vwbqh6fTWGVOmri1U5aOU2cvZUtQWAwXvNNukPBkCx(GEZycmT359yXN4fKkUaNnK5qeLG6evlOHBJ6N4iyNAJz4ZaGp8BxaFO0uagaqxTxqDRuwKP7QslJaB0GQMXRUZe6qsFGYIg6BWMudxZqza7esYpIYzm1zoQ2ExfHPD)DRD8OE)DlifCO3hg6YmBLzuswLerdvCYEaPTcd3vPdVCzpf3Ayg1vsTCt7RBKqHw2ZvETUClLeTSqh2npTUFLL3TdnueKualN3t4jPSSGtmv92DVuV8UKEyx20TB(6LeBAJ7advoUCjXozYKTM6h0Zz)KOROeHKCx0VQICtkQ1v6om3OEFatClxvaBV8xBj41UWxL5(BPuUvL4029zOz10RNKoJkA4Sww3QQsST5LKaOFX1RgfLIS9P3iX0tkYKXvmgc)DcIYLzkJOpa(w2AAG49RLGrTwm30GPLlig2ccf9e0uXGyNRNynfVTmkJEKHUXbLV5zVXnQ0H6OfmgA0cgMNiP2r7sOBuOyZTZQKUOOaqi7kmSAoJ5Ie9kWqKsa75STKvxVgStCaF927X3rcwyxKGfC0zRhJcR4wYd01C8ygUffX5HLHLb6yXjTlU8vtlzmI)qTEsUJ7k71bAgVrqqRDaEvdKu1AMXjzZXTWOdsA(sk542tKea3DPo5CxMoet0WrsHWvyNzfrCrNzmZi5s1cB2HJioGaYvkuSAcDHzL2d3uQ6uKmNRhrzl3rk)QAffKDvNtqQFpNXWw)SsRSSHrvJzvpl6Qu1wInDELLOIyZ95cbldRaDZlPPz3pPcAV0faukJ4uXUkq2qzO3i5UYpcQ4fBTmxDCa1bXy)rdwLlsHazB2S0DeTsBr13vJd6Cc1mzCzdlgTou6(NT0ucRBvaeJbXeDOuZBuIeFwhBH(6veBvXdTTZ6xRpzAIQxYAPRAZalHsRWLCw4TSUK(zWyb7wBfjTT(US1lMx5fVSm(u3xTpTBsT26Mvb7kR9qJBONrL36iF1UtfD9uF)nKA5tiMjr83rwH3sbeszKK4vj)JRA1D9UQPomYmO0JD)kAvDN(PYmPYPaHY7ulXsOMTxzWQx(nweDTULs7iuaD4cDinsmDxeh4w97ZDlBwBbjSUflNsNBxv)OLl0Dz)DyDpSl1jhbVI4ftqMWKj60NGzyljZSOtsQsP7dLnHWM1wyk(sJUxr(WYwFN8OOQQMwnIQI51yUvDw8JzyifxHd(vChmgJckHq8gS7(aku0zJYuYfSYrm6Gz28(CVIC1lpvzR(UUcHM2IOZfayxR2bC5G8Yw1lsD(D2nwLwBV4DFVPAH6DqH(4EPvf4Q6rKCGT0Jp3BmeKSIL0zhNvpsttCI6FolmPooTzmqdYCEu9QM8YybjXlGNpl3F2wmD9E2xpdmOBU)S4quBo6yM6lPb684lwepLNed6zkVmCQNSxsb(HereIEF6lD(CEywgoKAFroOcnHmR9wP6(wsERhcDLYqNT2wBrWkJXYrgYOqKuXYj9Bu3SQyWdLDytIJR9sV2Qim9baipXJY2WTkdBXj82E7oPcnmjjiQqKB3alnfQRoPQRJDZ6aJlLheJ(j1lx8UwddC(JNDiflP9WEoZHnjmJtRy9rDDRAih7J5wMf55tTfG9q70b2)FBk67iRrRyI5h2PVK)FqM5Vy51ULeYpSn3v(oiJ8xmawLi(YopORE)e0v5PelSlPxzxlScA(6kvRD1HUVum2ntMFZLgDhjgsji9sNqvjVuerCyiy9nWWrFLoSg9CBRkvRrawsQFDbnYMoOeI3eBaDFok3QKIZ4Y2rNUSuOUxddwRe2C5XBSwLBev2p18svQSPpSBlC)rAzfaKk0gOBkfnd3vE964saelnej039YH37X3VYtDkgo3xaacz)YzyTXbf823udRBcZgg3)3f6Bk8gg2fRNd9vjIo3zFU9lnJrC57A5tBJ7WBZ4IgyyTCQ(e7DmenpErP0nTF98)14eDH6M8CDi)lR1nUxzIwCQ8WHgatrYwuh0HKQvorWpHm5YM32lCI(KwlvYxUDQ2nhEztm(TUPzbhQDqDK9z7c6i5ElZCPp6YqKJVxyY2Aa8(ZFg98Yk5qFvJONqAvyi)jUZ9mpLtJsgJFGygOLDRq6wxodlhuA9(e2TAVwUH0K3hUubIrVoxxwb6fiBRL0PZp2zwHdxfdCLaowowIFVSBpZnQuRJkSrQoKDzSSeT03FnZ27VEHAi5RwU58A5phFR0m(AFOdpS77s4L6wy2oethdQkukTyVlR2wmawE8Q1ABngsMhV7L4yKFxpV(WDpy)Jzz4NIcG34P)6F5z)TFWx)f)9N9V(fN9x(lUImoMRC27)ZF6h)j)pF0790F5F(PF27D6N)p80)QF1zFWNC6F43C(p7)6)(9((lE4x9PF6WN(X)yyQp9l)0Z)j)lxrAJY8BghC2VYPF2NFfRhELV(lE)bN)PF8x)f)qADo939lo9Z(rN)HV)5)JF0z)N)BN9rFY5FW790)IVuccN(z)6t)Y)Wx9Z(KV(l(XN(L)GZ)5)ZN)V)H4y(R)PN(7(po)d)TN)t(nN95)DWWo)h(7p79)Ta4S4Hut)B)1R7HlEy9Jk5O5kEs316Kw6bxtpoPJBhEKw)Wdl9Z5CPB6BO9s7491w6Mhy)Gv94UDlhxNfYS(z29GAEWDVjTuT06N(vDtg2)7ok3WbFNr6o)9)Bo7d(NK0Tt)8FWG(N(z)ktXcAyyLV5(GC9U9XgPwWdEdPc(i2Xy7BMmjeVneKwGd(Fd]] )

--spec:RegisterPack( "狂徒官方一键宏Simc",  20250612, [[Hekili:TVtBVnYX59BrOa8eHKOjPiVCxHOaSUK4xR7HJxJ)MwUC3HKR5YDz3xKSkiiU6GKyFnPoP1iTOTabUOjWiW25RxmoN(JPs6U7t(VqFEMz2DNz2zwskD35KGad5tA3zN559xNNJBD89pUVRDc543PDZ2DBEZw3UrRBU)(T(oh3p5S5KJ7p32zQ9y4xcSNb))N8p9bx8h(xU4l)3V8x(7p)rp4zFYxEXx(X99M5GR8m)qBxChJdtJCGvFA4P(P2h3FyQNFYBeC8qDhwZoWHfpN4ap(MnpU)epxxcBTKyyFF6V7xJhWt(Kp7zp4to)rF1ZEWh8SF0ptbe(Mh)tV8J)5N)h(pF6p53EXd)SN8H)4l(4Fb8Wl(jF85p()58h9pF5h9VE5V8lEYx8rx8WF1t)HF9X999ItIPaBcX2pzc8RVdLCqcSh6tCp(OJ7B7K4fgCCFNqFxRH(HHUmGkYBo7f95FBF4rjKipaxpXg(hydAmYlWlEILtyGRhD1jW)13XnUQtY2ncEQVxaXkknEIYXDNqaqcpniE5GLd(BS9csGFwo4vZ)OLdUh8vlh4nc(jb(bwzqi8l4(FcPXYb)DXWISHN4hE6Yb35UWco1lb(K3y28OWtiUW2DVgIi0wlhmmD0OgkGwJ05lhuB5GTxoawHrSE5GflORiX2NeK0WJFmwQBhNySCqDGm9oTVs0N3aq70yVGXYOZUlherCSJtW)qM4y7hrSDplJajtAKidvrdwBCdwRt4SHHwZdbMhC(h0B5G20NBMmJ0J9nqpgpjmoX)mR4KiVPefYXR7ngySZJ8cbSaWXxJT4Ld6txnGSXfuIWrJ2BSJliI0A5GV)9FDeC88DJXnGmIebyzixykfLHWVdjwZSF)YelfKeW65wWcTa18axMibNMnYoWkzcXAI9SzKOgr2btxo4qaiqSUJbSogWPGevDr6dzG5O0iytbyEijGmcb1rrHZae3jk03hrwq)jCgaaPWtbQrWusIegSDXJtA1WlUrm9tTchznl)dP4r2QABAv1P8xkZDuk8YS3WzTDnGKd9TDjwJ8tJIotbvlu9pcxeWVORcWl4rT3bjUrJjjY8eG2dho)nanoxYJczINwJiYmy3zCouMayDiKEtdq6uczULxIfI6GYNcW(UuZl2GSJDsAKnq97YotqRe(GD5YtVfSjmPQ7X2gWW0ecGpNfMci2qg(cCvuzgbp6sy7dJ5ENWuk)hxYFRRRm2hLm0cxCSvqy0mekqcqxkbi)Dlhap7MiQ(DUYOAyAYvdBrLj7aGj2zh2xyabyqEhziphROguqm4wF7Gb7ZHDMzwkVBInAyLYwq7cEW(sDmGkH3lnzIpjgw(Dbt0EX0xa4)rrqOeXEOSn8x3pkf(LJiGtMGXvrv2VkQIGWE2UNzaN(0ioSynpduKEDcaewd5Wat192k04W5GAgjPGyN5we)n)uc1SIceKRRbg92)2uRf7q9QAcMQ(dKGYQx6yWyRR1mIpzvqXW0ipWTwc4RmonAvRoEkALd3BWyyC8WWasC5prrW7hWPuOGckh5GkZWYNG(INr1l48z7i0Z1eWTnxek5OBGEPGdKmZZby)2bJj7IMp8CMWDUfGU9MdqJh9mgEwEGcV1BGH7amklweUmbh7HGJCRS9e51TAAqHIAWhDHrruJwQVh1Xdvl4iCH)1aosdj50CvUCK0Kioif3KclMcFSsyHzi((V77cAcGuQqurQWgt59uccC4ByonTp1gbqsYPe0UCZ9ALbUq4wJOus4dWykG9f8W5tjYyypOsTgdk7spZa8Jq7iad3dpg8Se51dj0aYSJarcyZ60kwWfGSloscI5PXnso902wDM7Oyparhl)q0(fAsOvweS5HVQJ7tDd2L5TVyRWWze9t2Pnp01wMID95gZHfWon4RqCfTlOx8OyJiJTJCzgwrDexGUJNdWP6NoNe5mbddiQigpgF22pomJBllbWOzc8(o8ZCx8Ft4mFd7Ti3fWJZY0HPmAgZT1gZu3wYVn3apYI2UkUuRwQjKO4puipKkKDYICGVhXc4TsImTmf5(kLgO2eYfia(iqs77tGy6tym1xhKpRuobJegeKJIO(rBL5fhSifkk0WeNEBWHec1Fxph04jEAreUIpAyQQ1VJiJhKXEDAk8quyZNhgLKgqZ(itCWXoixsJFavT3m0ibJUDecuh1)vU3DFL7FKAoQRHyIQ6p1BLp9SSCHJI6Uxi3e9S1Ag(WAMei57gRUgwHf0KR4EkKSyPaz2ALXYSL(WzYexvt5ssS8(SCDIZCshdcP(U8SchsYm3dwBOUw5vwbfGCZcdCci)IghkYkf2kqGaOqePVQrwjNGSQjrJiojw2XGBfx7ahiFxsu6mvja2hsCBqTSGK(HHOfqaRhHQncwcqkjJugz75wOvwXHHuht5QnZ216VpfmnIwCcO146AbBDfangvqZjGaKPuYoXgldJMYJeaUMJJTJoBxeOWDkYTq3KZv8(hi5Xh9dO7Kq6j35UmvsqY6ecMWv5YpH1OkXBgrshLRga(WjrtqxRUwPZbQTf(hsQc5QFdHpDu6yszffdfIPmL20hi6uOnVWmSIRzEPyORS4VutpSmzoKxEKiV4PmZ1GDhkbvLCHMWtdqXaKqtI4gUzjz5XtTQpqTjmRYqAUaYIw0FTiB0(igXLTznlgdSHGNN0al2VBHfbTAjvMj0CAZugazfJWtdETZkyzYVoNRrf3rUaqMS9HirGLql4qdqe0zAEgTmxUMRGkTOT840zVKYnut19AYnCOi(iFY7Zswitdik1pZRAHToCxZ4Cz1blVSX2yEqBaLMtfDa(6uW2AIoTIxO6pRhPNzCXkngBmaYauZdE1cuBT24JC0AAinYlqhsxVkwIb8YkC0ii34eBA1OnL7x8eBqTasHwTXaVgjaiaoOWuIZK9ysu0i4Y)cioP7tCMe4HW0z0YQaNlgEge4tkKcByaaCoCTE(tUhevi8KyVzX0CKrVVZ8IIWLKjNY3hmPlS7nYztwrH6z2pZv1zudbDCvEjLYyktuw9e1uJEAdi4LTK5TGMidan0k1G0TXyLmttyL)bvwlcjOarylSXq7yIf6RXkj0Iwl6dZkoMw4vn5mh5c8tBYJFACsESGgDtJodYDtlyJttb8ZPkZdP)lci08ckOwWXAnkfR0BbWHlRJ0YaVdKOP0Y2jVSUIlBKxeH3Tk5vDtXvbH2qItG8XTqbq1LwPhU3MKvN1z2JdO)blYqAmfObDK69EPyAjyC(y(FUHOXtQLyxV4O05juVwTdO1hypQ7UIcXZuiFV0GPZSrOmec7bYP1IDELzBSetP5troJelv4ot7sUZhak6UsMDxnrlAe(qkyLEL(UKr2P(06CX1)I5giaTxQxha)MPPduAXuP(q0QXe7yla3sAaXRz5opE1XB2UPa2f7hMajKY3WwfOB(tq0t1MVYIAFfG82pFH82SoU6Yi1666Qel5EK88vWAFuuSWTdar4ts9bdomwdy6zMhTkzbSsABNuxWTFwdL10gt5itWuEykcHbfgEzryaQKyDrad9ZOXP4HlMDc5PjJjHjCUt9CMQRxHsEJV7jK5Nm3Yzcbf9zwj5epGS5GEZxtVLZaX2X2z2ZuZBCTkf(AKzmY)f7MydGD65Ggu4nWANLLB)6SHsDDDhTzlZc2mZFdTBqnflemBxK6FFPE1TASuUtO4Pi3k09OfMzpAqrBsaH8kDLrbXQThoYAeKxO8AYAZQV9P06ba2yMPwJR1GnuRO8(2PU2o4lZ9qIpv8R4ux1s8t98lKLdQLH((X6iZ6Gh1)nLIH6FijJxjQ9AZu26NPHYuaUtoDz5G3LRsG1yGerlzeHGFFLfJIvhkgqXHM2mi7v5OjdaK(y6fhGwPvPohO5cFySLPvQzH3ren9GSYE7NB7c3NDZkB7iBwnbJcthZTRHgZeD6qlf7mssL5TiyBqOWSsbxjIacwav9cUgrIU5MIkYf0Kxj7ih7amgXii4m1Boa3SAdUNID69kQN2U450Jk0ykguj7sT6sT6WFFezmjOOhskW08u)yIs4xSg8KTqF0TxS17L6oEgf6LxBBPqeThJgcqc40y5vcFiwnqQ)QCVH5aZ85(NH2PIX)sowqfA6Qllx2MwD10mvz8mPNcOf(gu6aWN2681KJdQxoiTBq5ssTw3BNv1UGILiwexXxRn7a0JVI44r59Kb1Nl1N9DKRooGJGeKVUYWnKaw7jM6maqqItNruR2oeWbX1d8JGTVdcZkjVrRHz3)IaY7Ni1Wvy)BOZ9ygJrTxhkrgQNMyI7BYKAjU)vJpVzqulMELqSqvDncJG02blkN4z7lcEtyz3o3jHftBNMYHMa2tAIwbaOXbS)0rNszEUFe6nJY8MpzU1y75Qhq7UfipDlAWcfL53N2rDl2ficYWb55SylW7seK4t5x5gMu(HIBZ8jNfBAFeFxXgL906kKIetfUPcoH2YJ)99jVFPQOqZjllAbFiCdA04Hb8ktWtcgliFyKOByMih2A8x9UVn88uAae89d(kA7u5BRxmtBeImncLc99a5jWT6lIQNxzP0wr1bfBuUA0XQ1HRQGjRlufW8Ynvk9WIcpvvhTYdavZ7zIWglmJuPCmCVtLYDAJ5b6jXve4JI85QsMB9bOvX2xdUwnH7OQyka10KbaVYkhO5v0CFyVUwfYt6OfQ(9FbrlwpH4cIgM01OuFliah1ic2UGMHRAiEdwS8tDMEgGPEbckwkRbFRvITNFSyls6kinRSw8(qPU26AxE5JFDudRRJHO6V)BBgYwRdpHVIe7PagoZAierAAeKivCjdLS(KRzDIL0nNAO4hAJD)89cW7wNqsTq0AjFpH7WF8upG(5IX15ytRxkRrwNMNObErGn5dtTzVnWzii)EMi3OXDXuHtiZWstHHkoje7Zq2Us3o2DZnhaLlGfTF)AVANcPodEgPjFBim3Dvp2SlKeEpccUbTIYOxyQh4rEryTM5xxLrjyV4O3iPZuUw3fsigAv5AQouHxjX2f3jt9UObQk5piU6wD5fZS8DvE5GMR)fxQQ4d1k6P)EBXUJhUs36F1gsNDdqy1rrKvPSNyKZeX6MSz8ekXw4(4Gw9ekky1djHwCwjllf8IEjLgb)kMfKiA9w9f0ir7NXHapxeDm2RC1BrGP0y1cUIWG9qQolnjomuEQYhLSeZQwvS3SI78hdE5gc1cO8o9rhobqmMUt0EQXUYCRU3i3Ij2ILrMAhKxpMkSaohoBylYgum54WZkriSrHrwy2M4gLjuNNnLWqzvCcjmi4u7i8IecBXt)IFZf)Ih(np()4IF3JV4h9RVHJB8nU4d)3E6N(zp7)6bp938pE(JEW5FfFSXo))9lV8t(9)Fp4dw(Mp5Z)8op9t)PW390V(ZV8N9FFJSUuyyyqUX5p6RUXQMyKB8np(dBD5N)PFZJ)OQpedZsI8HyArLpK23YaQO2VfvSO071S332agu9ER59k79Y38Yp8NFXd)vm(25F1p(wN)OF7Lp8bp9h(1m(hDvG8aycomQyydHC8h5HvGpRSE5PTVtVxrSmxlFtDRamZzH9EJvYpZvWs)xZZ)B3sLkOx7LV5Ff4W8pjRTJECvjFkD48UEJ6TIIVutV7SALlMwnJLMrp8jx1jtG3gUPRgPBToiDfNkvo5A2mYCyVqKKUTpFA5O4UJnDu8V1x58I6JTlR2(mQ0wIDJS2w0lsHWELLCiBpuZqCxAh26TTXudwSqxJdpSx7DkXDOB9oLAsy9ASaRpShezgs)(ZXwyzMIRwFcofxKQEypX2zUxR92wQRq1uZRBXIC(LqllxSilTnX2uwVMrwBTTvRdXIfAAdz96Rw0eIhGYAF(3qTvF2zEle1jKBc8k3cgpsAhmFfVq8CvBivSs8CLBDgEaAA71H9A1DhX2DPzhOn6s85k91s8vsTXcTjsH9xAZ)EHTFq8qJvF02LHkLwB7TmYawSyRv4yOoZm9ONVZX(AGoMWMv5it0yWb9AxZezrRo2l2bsxfRLNvEePLaErdzfgKkpE6h2IIlx)Xnxf(yt1ocxBVIKnaWR6efQZcWqDCZPa(Ap84QWN4iItTujoq5GBv2zQBqYpa4J0Z(BVzbxfzuc3eXN8YU0Gv2fWRFT8N17M5iW1A(OvMW7nbSoSxNAQW4b88kU2W1lH52EZW191HR1kfIwntLHl7vQZ5esT(wDyJvjdYXCXQ7N8aOMfPRcYZvUoC)BxFNTxr1ifwKUjex41AMkCH3AysWfwrvt)nUmfBqB0yrRs6uYWtuaQxtbdoR3y1(NoZ88QPdLNgsb1P8XG8GETQTDLZ(8bDxSO4dfMM2d60U(gtH)Z)bx(kXz2oNcdM4GmK0tWB1Qi8rftN11YC7Mf8M4CSwx2DXFz(IxAA(IxnRCRk5LIQzulJYd3BEiMICNAAwynzPdZ5eVQVLhBUK3ZTm53i)Dk(pzYpVuheyvgX6wHwglsmD6flWMyutQbgaHPDnPkpP9ykp)TR723LV7886E5oaULd2GwUGIkuQV98fwoYUer6RyjkLixWhTllJw0U2QgY2d3VzbLAJMAZxgZqBjtcYtsRufzkjDuB7QMI2A6AbkVOw6NAwiDG61QUwpBov8Ao7RQei9Lys8AsOHoPwZWApVevRGyTPGD(TmuhFERkb4cV4cvfDRsybZq7FunhPLkyromuzzhRTL2zkvXYrr91VIdhQ(YvKvFldJl6HDkbgY7cBInZRqM48HQ1C)(nPM75AU6QdMkuMn5NLEt(WEQ(M857SuD9KgPtkf9f9OAwTxttdizb9S8qbYuFREOnpSDxTuFbFTR7ewAcbI3LonH9Yg6XQa5I6XvUL5gI5OzLXCOC4TxVdVCp1xXHtju5x3IcGHPb3t6sASB2DXOhw)t5vIfZr0VL6oHMuZVTg5vZpRty5lMRikT6v3qJNh3BUmq6VC95ww66ZvWFeDakfl5w6cErWSV(BrNXs3LflyhXqM0FV5oSv3MLku4HnnNPmtY7L(9D7kteP0OQU4Bl1CTsUExMT1awR(oULfe)ZP7S2MapgVkBh0sVhJBjzk8p2Mae9OEEWNxRe6kffQX4M324T0VqpRC9iQdbcFvTaK3pFdt1HHWRYdcR(Mq4QoC9YPJSgPrCTp0YmhZ19H3Y1I7cbJSwAEmoO0JZNfJAMNRNxK4KzHNA59Fv8E8dsuuCWWWmWVviMNIId71Ll5yE6jG1uV0IKpMvjw)8u6BJiABPNQXFQMjziRgFANXbwurzysXv4ccptyqg31NnmE96GytX0gEqVonZU(uTAQFFOtAO5nGnQIzBs7U8MANpEI12U0GjI1hvZqjUyHYajUyr5HrS83M9C1HqSo9sgF8))]] )