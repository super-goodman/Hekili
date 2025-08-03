-- DruidBalance.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "DRUID" then return end

local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local PTR = ns.PTR
local spec = Hekili:NewSpecialization( 102 )

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
-- local IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
local IsSpellKnownOrOverridesKnown = C_SpellBook.IsSpellInSpellBook
local IsActiveSpell = ns.IsActiveSpell

-- Specialization-specific local functions (if any)
local GetSpellBookItemName = function( index, bookType )
    local spellBank = ( bookType == BOOKTYPE_SPELL ) and Enum.SpellBookSpellBank.Player or Enum.SpellBookSpellBank.Pet;
    return C_SpellBook.GetSpellBookItemName( index, spellBank );
end

spec:RegisterResource( Enum.PowerType.Rage )
spec:RegisterResource( Enum.PowerType.LunarPower, {
    fury_of_elune = {
        aura = "fury_of_elune_ap",

        last = function ()
            local app = state.buff.fury_of_elune_ap.applied
            local t = state.query_time

            return app + floor( ( t - app ) * 2 ) * 0.5
        end,

        interval = 0.5,
        value = 2.5
    },

    celestial_infusion = {
        aura = "celestial_infusion",

        last = function ()
            local app = state.buff.celestial_infusion.applied
            local t = state.query_time

            return app + floor( ( t - app ) * 2 ) * 0.5
        end,

        interval = 0.5,
        value = 2.5
    },

    natures_balance = {
        talent = "natures_balance",

        last = function ()
            local app = state.combat
            local t = state.query_time

            return app + floor( ( t - app ) / 2 ) * 2
        end,

        interval = 3,
        value = 2,
    }
} )
spec:RegisterResource( Enum.PowerType.Mana )
spec:RegisterResource( Enum.PowerType.ComboPoints )
spec:RegisterResource( Enum.PowerType.Energy )

-- Talents
spec:RegisterTalents( {

    -- Druid
    aessinas_renewal               = {  82232,  474678, 1 }, -- When a hit deals more than $s1% of your maximum health, instantly heal for $s2% of your health. This effect cannot occur more than once every $s3 seconds
    astral_influence               = {  82210,  197524, 1 }, -- Increases the range of all of your spells by $s1 yards
    circle_of_the_heavens          = { 104078,  474541, 1 }, -- Magical damage dealt by your spells increased by $s1%
    circle_of_the_wild             = { 104078,  474530, 1 }, -- Physical damage dealt by your abilities increased by $s1%
    cyclone                        = {  82229,   33786, 1 }, -- Tosses the enemy target into the air, disorienting them but making them invulnerable for up to $s1 sec. Only one target can be affected by your Cyclone at a time
    feline_swiftness               = {  82236,  131768, 1 }, -- Increases your movement speed by $s1%
    fluid_form                     = {  82246,  449193, 1 }, -- Shred, Rake, and Skull Bash can be used in any form and shift you into Cat Form, if necessary. Mangle can be used in any form and shifts you into Bear Form. Wrath and Starfire shift you into Moonkin Form, if known
    forestwalk                     = {  82243,  400129, 1 }, -- Casting Regrowth increases your movement speed and healing received by $s1% for $s2 sec
    frenzied_regeneration          = {  82220,   22842, 1 }, -- Heals you for $s1% health over $s2 sec, and increases healing received by $s3%
    gale_winds                     = { 104079,  400142, 1 }, -- Increases Typhoon's radius by $s1% and its range by $s2 yds
    grievous_wounds                = {  82239,  474526, 1 }, -- Rake, Rip, and Thrash damage increased by $s1%
    heart_of_the_wild              = {  82231,  319454, 1 }, -- Abilities not associated with your specialization are substantially empowered for $s1 sec. Feral: Gain $s2 Combo Point every $s3 sec while in Cat Form and Physical damage increased by $s4%. Guardian: Bear Form gives an additional $s5% Stamina, multiple uses of Ironfur may overlap, and Frenzied Regeneration has $s6 charges. Restoration: Healing increased by $s7%, and mana costs reduced by $s8%
    hibernate                      = {  82211,    2637, 1 }, -- Forces the enemy target to sleep for up to $s2 sec$s$s3 Any damage will awaken the target. Only one target can be forced to hibernate at a time. Only works on Beasts and Dragonkin
    improved_barkskin              = { 104085,  327993, 1 }, -- Barkskin's duration is increased by $s1 sec
    improved_stampeding_roar       = {  82230,  288826, 1 }, -- Cooldown reduced by $s1 sec
    incapacitating_roar            = {  82237,      99, 1 }, -- Shift into Bear Form and invoke the spirit of Ursol to let loose a deafening roar, incapacitating all enemies within $s1 yards for $s2 sec. Damage may cancel the effect
    incessant_tempest              = { 104079,  400140, 1 }, -- Reduces the cooldown of Typhoon by $s1 sec
    innervate                      = { 100175,   29166, 1 }, -- Infuse a friendly healer with energy, allowing them to cast spells without spending mana for $s1 sec
    instincts_of_the_claw          = { 104081,  449184, 1 }, -- Ferocious Bite and Maul damage increased by $s1%
    ironfur                        = {  82227,  192081, 1 }, -- Increases armor by $s1 for $s2 sec
    killer_instinct                = {  82225,  108299, 2 }, -- Physical damage and Armor increased by $s1%
    light_of_the_sun               = { 104083,  202918, 1 }, -- Reduces the remaining cooldown on Solar Beam by $s1 sec when it interrupts the primary target
    lingering_healing              = {  82240,  231040, 1 }, -- Rejuvenation's duration is increased by $s1 sec. Regrowth's duration is increased by $s2 sec when cast on yourself
    lore_of_the_grove              = { 104080,  449185, 1 }, -- Moonfire and Sunfire damage increased by $s1%
    lycaras_inspiration            = {  92229, 1232897, 1 }, -- You gain a bonus while in each form inspired by the breadth of your Druidic knowledge: No Form: $s1% Magic Damage Cat Form: $s2% Stamina Bear Form: $s3% Movement Speed Moonkin Form: $s4% Area damage taken reduction
    lycaras_teachings              = {  82233,  378988, 2 }, -- You gain $s1% of a stat while in each form: No Form: Haste Cat Form: Critical Strike Bear Form: Versatility Moonkin Form: Mastery
    maim                           = {  82221,   22570, 1 }, -- Finishing move that causes Physical damage and stuns the target. Damage and duration increased per combo point: $s1 point : $s2 damage, $s3 sec $s4 points: $s5 damage, $s6 sec $s7 points: $s8 damage, $s9 sec $s10 points: $s11 damage, $s12 sec $s13 points: $s14 damage, $s15 sec
    mass_entanglement              = {  82207,  102359, 1 }, -- Roots the target and all enemies within $s1 yards in place for $s2 sec. Damage may interrupt the effect. Usable in all shapeshift forms
    matted_fur                     = { 100177,  385786, 1 }, -- When you use Barkskin or Survival Instincts, absorb $s1 damage for $s2 sec
    mighty_bash                    = {  82237,    5211, 1 }, -- Invokes the spirit of Ursoc to stun the target for $s1 sec. Usable in all shapeshift forms
    moonkin_form                   = {  82208,   24858, 1 }, -- Shapeshift into Moonkin Form, increasing the damage of your spells by $s1% and your armor by $s2%, and granting protection from Polymorph effects. While in this form, single-target attacks against you have a $s3% chance to make your next Starfire instant. The act of shapeshifting frees you from movement impairing effects
    natural_recovery               = {  82206,  377796, 1 }, -- Healing you receive is increased by $s1%
    natures_vigil                  = {  82244,  124974, 1 }, -- For $s1 sec, all single-target damage also heals a nearby friendly target for $s2% of the damage done
    nurturing_instinct             = {  82214,   33873, 2 }, -- Magical damage and healing increased by $s1%
    oakskin                        = { 100176,  449191, 1 }, -- Survival Instincts and Barkskin reduce damage taken by an additional $s1%
    perfectlyhoned_instincts       = { 104082, 1213597, 1 }, -- Well-Honed Instincts can trigger up to once every $s1 sec
    primal_fury                    = {  82224,  159286, 1 }, -- While in Cat Form, when you critically strike with an attack that generates a combo point, you gain an additional combo point. Damage over time cannot trigger this effect. Mangle critical strike damage increased by $s1%
    rake                           = {  82199,    1822, 1 }, -- Rake the target for $s$s3 Bleed damage and an additional $s$s4 Bleed damage over $s5 sec. While stealthed, Rake will also stun the target for $s6 sec and deal $s7% increased damage. Awards $s8 combo point
    rejuvenation                   = {  82217,     774, 1 }, -- Heals the target for $s1 over $s2 sec
    remove_corruption              = {  82241,    2782, 1 }, -- Nullifies corrupting effects on the friendly target, removing all Curse and Poison effects
    renewal                        = {  82232,  108238, 1 }, -- Instantly heals you for $s1% of maximum health. Usable in all shapeshift forms
    rip                            = {  82222,    1079, 1 }, -- Finishing move that causes Bleed damage over time. Lasts longer per combo point. $s1 point : $s2 over $s3 sec $s4 points: $s5 over $s6 sec $s7 points: $s8 over $s9 sec $s10 points: $s11 over $s12 sec $s13 points: $s14 over $s15 sec
    soothe                         = {  82229,    2908, 1 }, -- Soothes the target, dispelling all enrage effects
    stampeding_roar                = {  82234,  106898, 1 }, -- Shift into Bear Form and let loose a wild roar, increasing the movement speed of all friendly players within $s1 yards by $s2% for $s3 sec
    starfire                       = {  82201,  194153, 1 }, -- Call down a burst of energy, causing $s$s3 Arcane damage to the target, and $s$s4 Arcane damage to all other enemies within $s5 yards. Deals reduced damage beyond $s6 targets. Generates $s7 Astral Power
    starlight_conduit              = { 100223,  451211, 1 }, -- Wrath, Starsurge, and Starfire damage increased by $s1%
    starsurge                      = {  82202,   78674, 1 }, -- Launch a surge of stellar energies at the target, dealing $s$s2 Astral damage
    sunfire                        = {  93714,   93402, 1 }, -- A quick beam of solar light burns the enemy for $s$s3 Nature damage and then an additional $s$s4 Nature damage over $s5 sec to the primary target and all enemies within $s6 yards. Generates $s7 Astral Power
    symbiotic_relationship         = { 100173,  474750, 1 }, -- Form a bond with an ally. Your self-healing also heals your bonded ally for $s1% of the amount healed. Your healing to your bonded ally also heals you for $s2% of the amount healed
    thick_hide                     = {  82228,   16931, 1 }, -- Reduces all damage taken by $s1%
    thrash                         = {  82223,  106832, 1 }, -- Thrash all nearby enemies, dealing immediate physical damage and periodic bleed damage. Damage varies by shapeshift form
    tiger_dash                     = {  82198,  252216, 1 }, -- Shift into Cat Form and increase your movement speed by $s1%, reducing gradually over $s2 sec
    typhoon                        = {  82209,  132469, 1 }, -- Blasts targets within $s1 yards in front of you with a violent Typhoon, knocking them back and reducing their movement speed by $s2% for $s3 sec. Usable in all shapeshift forms
    ursine_vigor                   = { 100174,  377842, 1 }, -- For $s1 sec after shifting into Bear Form, your health and armor are increased by $s2%
    ursocs_spirit                  = {  82219,  449182, 1 }, -- Stamina increased by $s1%. Stamina in Bear Form is increased by an additional $s2%
    ursols_vortex                  = {  82207,  102793, 1 }, -- Conjures a vortex of wind for $s1 sec at the destination, reducing the movement speed of all enemies within $s2 yards by $s3%. The first time an enemy attempts to leave the vortex, winds will pull that enemy back to its center. Usable in all shapeshift forms
    verdant_heart                  = {  82218,  301768, 1 }, -- Frenzied Regeneration and Barkskin increase all healing received by $s1%
    wellhoned_instincts            = {  82235,  377847, 1 }, -- When you fall below $s1% health, you cast Frenzied Regeneration, up to once every $s2 sec
    wild_charge                    = {  82198,  102401, 1 }, -- Fly to a nearby ally's position
    wild_growth                    = {  82205,   48438, 1 }, -- Heals up to $s1 injured allies within $s2 yards of the target for $s3 over $s4 sec. Healing starts high and declines over the duration

    -- Balance
    aetherial_kindling             = {  88209,  327541, 1 }, -- Casting Starfall extends the duration of active Moonfires and Sunfires by $s1 sec, up to $s2 sec
    astral_communion               = {  88235,  450598, 1 }, -- Increases maximum Astral Power by $s1. Entering Eclipse reduces the Astral Power cost of your next Starsurge or Starfall by $s2
    astral_smolder                 = {  88204,  394058, 1 }, -- Your Starfire and Wrath damage has a $s1% chance to cause the target to languish for an additional $s2% of your spell's damage over $s3 sec
    astronomical_impact            = {  88232,  468960, 1 }, -- The critical strike damage of your Astral spells is increased by $s1%
    balance_of_all_things          = {  88214,  394048, 2 }, -- Entering Eclipse increases your critical strike chance with Arcane or Nature spells by $s1%, decreasing by $s2% every $s3 sec
    celestial_alignment            = {  88215,  194223, 1 }, -- Celestial bodies align, maintaining both Eclipses and granting $s1% haste for $s2 sec
    convoke_the_spirits            = {  88206,  391528, 1 }, -- Call upon the spirits for an eruption of energy, channeling a rapid flurry of $s1 Druid spells and abilities over $s2 sec. You will cast Starsurge, Starfall, Moonfire, Wrath, Regrowth, Rejuvenation, Rake, and Thrash on appropriate nearby targets, favoring your current shapeshift form
    cosmic_rapidity                = {  88227,  400059, 2 }, -- Your Moonfire, Sunfire, and Stellar Flare deal damage $s1% more frequently
    crashing_star                  = { 103847,  468978, 1 }, -- Shooting Stars has a $s2% chance to instead call down a Crashing Star, dealing $s$s3 Astral damage to the target and generating $s4 Astral Power
    denizen_of_the_dream           = {  88234,  394065, 1 }, -- Your Moonfire and Sunfire have a chance to summon a Faerie Dragon to assist you in battle for $s1 sec
    eclipse                        = {  88223,   79577, 1 }, -- Casting $s1 Starfires empowers Wrath for $s2 sec. Casting $s3 Wraths empowers Starfire for $s4 sec.  Eclipse (Solar) Nature spells deal $s7% additional damage and Wrath damage is increased by $s8%.  Eclipse (Lunar) Arcane spells deal $s11% additional damage and the damage Starfire deals to nearby enemies is increased by $s12%
    elunes_guidance                = {  88228,  393991, 1 }, --  Incarnation: Chosen of Elune Reduces the Astral Power cost of Starsurge by $s3, and the Astral Power cost of Starfall by $s4.  Convoke the Spirits Cooldown is reduced by $s7% and its duration and number of spells cast is reduced by $s8%. Convoke the Spirits has an increased chance to use an exceptional spell or ability
    force_of_nature                = {  88210,  205636, 1 }, -- Summons a stand of $s1 Treants for $s2 sec which immediately taunt and attack enemies in the targeted area. Generates $s3 Astral Power
    fury_of_elune                  = {  88224,  202770, 1 }, -- Calls down a beam of pure celestial energy that follows the enemy, dealing up to $s$s2 Astral damage over $s3 sec within its area. Damage reduced on secondary targets. Generates $s4 Astral Power over its duration
    hail_of_stars                  = { 103846,  469004, 1 }, -- Casting a free Starsurge or Starfall grants Solstice for $s1 sec
    harmony_of_the_heavens         = {  88218,  450558, 1 }, -- Starsurge or Starfall increase your current Eclipse's Arcane or Nature damage bonus by an additional $s1%, up to $s2%
    incarnation_chosen_of_elune    = {  88206,  102560, 1 }, -- An improved Moonkin Form that grants both Eclipses, any learned Celestial Alignment bonuses, and $s1% critical strike chance. Lasts $s2 sec. You may shapeshift in and out of this improved Moonkin Form for its duration
    natures_balance                = {  88226,  202430, 1 }, -- While in combat you generate $s1 Astral Power every $s2 sec. While out of combat your Astral Power rebalances to $s3 instead of depleting to empty
    natures_grace                  = {  88208,  450347, 1 }, -- When Eclipse ends or when you enter combat, enter a Dreamstate, reducing the cast time of your next $s1 Starfires or Wraths by $s2%
    new_moon                       = {  88224,  274281, 1 }, -- Deals $s$s2 Astral damage to the target and empowers New Moon to become Half Moon. Generates $s3 Astral Power
    orbit_breaker                  = {  88199,  383197, 1 }, -- Every $s1th Shooting Star calls down a Full Moon at $s2% effectiveness upon its target
    orbital_strike                 = {  88221,  390378, 1 }, -- Incarnation: Chosen of Elune blasts all enemies in a targeted area for $s$s2 Astral damage and applies Stellar Flare to them. Reduces the cooldown of Incarnation: Chosen of Elune by $s3 sec
    power_of_goldrinn              = {  88200,  394046, 1 }, -- Starsurge has a chance to summon the Spirit of Goldrinn, which immediately deals $s$s2 Astral damage to the target
    radiant_moonlight              = {  88213,  394121, 1 }, -- New Moon, Half Moon, and Full Moon deal $s1% increased damage. Full Moon becomes Full Moon once more before resetting to New Moon. Fury of Elune deals $s2% increased damage and its cooldown is reduced by $s3 sec
    rattle_the_stars               = {  88236,  393954, 1 }, -- Starsurge and Starfall deal $s1% increased damage and their cost is reduced by $s2%
    shooting_stars                 = {  88225,  202342, 1 }, -- Moonfire and Sunfire damage over time has a chance to call down a falling star, dealing $s$s2 Astral damage and generating $s3 Astral Power
    solar_beam                     = {  88231,   78675, 1 }, -- Summons a beam of solar light over an enemy target's location, interrupting the target and silencing all enemies within the beam. Lasts $s1 sec
    solstice                       = {  88203,  343647, 1 }, -- During the first $s1 sec of every Eclipse, Shooting Stars fall $s2% more often
    soul_of_the_forest             = {  88212,  114107, 1 }, -- Solar Eclipse increases Wrath's Astral Power generation by $s1% and Lunar Eclipse increases Starfire's damage and Astral Power generation by $s2% for each target hit beyond the first, up to $s3%
    starlord                       = {  88207,  202345, 2 }, -- Starsurge and Starfall grant you $s1% Haste for $s2 sec. Stacks up to $s3 times. Gaining a stack does not refresh the duration
    starweaver                     = {  88236,  393940, 1 }, -- Starsurge has a $s1% chance to make Starfall free. Starfall has a $s2% chance to make Starsurge free
    stellar_amplification          = {  88229,  450212, 1 }, -- Starsurge increases the damage the target takes from your periodic effects and Shooting Stars by $s1% for $s2 sec. Reapplying this effect extends its duration, up to $s3 sec
    stellar_flare                  = {  91048,  202347, 1 }, -- Burns the target for $s$s2 Astral damage, and then an additional $s3 damage over $s4 sec. If dispelled, causes $s5 damage to the dispeller and blasts them upwards. Generates $s6 Astral Power
    sundered_firmament             = {  88199,  394094, 1 }, -- Every other Eclipse creates a Fury of Elune at $s1% effectiveness that follows your current target for $s2 sec
    sunseeker_mushroom             = {  88202,  468936, 1 }, -- Sunfire damage has a chance to grow a magical mushroom at a target's location. After $s3 sec, the mushroom detonates, dealing $s$s4 Nature damage and then an additional $s$s5 Nature damage over $s6 sec. Affected targets are slowed by $s7%. Generates up to $s8 Astral Power based on targets hit
    touch_the_cosmos               = {  88222,  450356, 1 }, -- Casting Wrath in an Eclipse has a $s1% chance to make your next Starsurge or Starfall free. Casting Starfire in an Eclipse has a $s2% chance to make your next Starsurge or Starfall free
    twin_moons                     = {  88201,  279620, 1 }, -- Moonfire deals $s1% increased damage and also hits another nearby enemy within $s2 yds of the target
    umbral_embrace                 = {  88216,  393760, 1 }, -- Wrath and Starfire have a $s1% chance to cause your next Wrath or Starfire cast during an Eclipse to become Astral and deal $s2% additional damage
    umbral_inspiration             = {  88217,  450418, 1 }, -- Consuming Umbral Embrace increases the damage of your Moonfire, Sunfire, Stellar Flare, Shooting Stars, and Starfall by $s1% for $s2 sec
    umbral_intensity               = {  88219,  383195, 1 }, -- Solar Eclipse increases the damage of Wrath by an additional $s1%. Lunar Eclipse increases Starfire's damage by $s2% and the damage it deals to nearby enemies by an additional $s3%
    waning_twilight                = {  88220,  393956, 1 }, -- When you have $s1 periodic effects from your spells on a target, your damage and healing on them are increased by $s2%
    warrior_of_elune               = {  88210,  202425, 1 }, -- Your next $s1 Starfires are instant cast and generate $s2% increased Astral Power
    whirling_stars                 = {  88221,  468743, 1 }, -- Incarnation: Chosen of Elune's cooldown is reduced to $s1 seconds and it has two charges, but its duration is reduced by $s2%
    wild_mushroom                  = {  88202,   88747, 1 }, -- Grow a magical mushroom at the target enemy's location. After $s3 sec, the mushroom detonates, dealing $s$s4 Nature damage and then an additional $s$s5 Nature damage over $s6 sec. Affected targets are slowed by $s7%. Generates up to $s8 Astral Power based on targets hit
    wild_surges                    = {  91048,  406890, 1 }, -- Your Wrath and Starfire chance to critically strike is increased by $s1% and they generate $s2 additional Astral Power

    -- Elunes Chosen
    arcane_affinity                = {  94586,  429540, 1 }, -- All Arcane damage from your spells and abilities is increased by $s1%
    astral_insight                 = {  94585,  429536, 1 }, -- Incarnation: Chosen of Elune increases Arcane damage from spells and abilities by $s1% while active. Increases the duration and number of spells cast by Convoke the Spirits by $s2%
    atmospheric_exposure           = {  94607,  429532, 1 }, -- Enemies damaged by Full Moon or Fury of Elune take $s1% increased damage from you for $s2 sec
    boundless_moonlight            = {  94608,  424058, 1 }, --  Fury of Elune Fury of Elune now ends with a flash of energy, blasting nearby enemies for $s$s5 Astral damage.  Full Moon Full Moon calls down $s8 Minor Moons that deal $s$s9 Astral damage and generate $s10 Astral Power
    elunes_grace                   = {  94597,  443046, 1 }, -- Using Wild Charge while in Bear Form or Moonkin Form incurs a $s1 sec shorter cooldown
    glistening_fur                 = {  94594,  429533, 1 }, -- Bear Form and Moonkin Form reduce Arcane damage taken by $s1% and all other magic damage taken by $s2%
    lunar_amplification            = {  94596,  429529, 1 }, -- Each non-Arcane damaging ability you use increases the damage of your next Arcane damaging ability by $s1%, stacking up to $s2 times
    lunar_calling                  = {  94590,  429523, 1 }, -- Starfire deals $s1% increased damage to its primary target, but no longer triggers Solar Eclipse
    lunar_insight                  = {  94588,  429530, 1 }, -- Moonfire deals $s1% additional damage
    lunation                       = {  94586,  429539, 1 }, -- Your Arcane abilities reduce the cooldown of Fury of Elune by $s1 sec and the cooldown of New Moon, Half Moon, and Full Moon by $s2 sec
    moon_guardian                  = {  94598,  429520, 1 }, -- Moonfire and Starfire generate $s1 additional Astral Power
    moondust                       = {  94597,  429538, 1 }, -- Enemies affected by Moonfire are slowed by $s1%
    stellar_command                = {  94590,  429668, 1 }, -- Increases the damage of Fury of Elune by $s1% and the damage of Full Moon by $s2%
    the_eternal_moon               = {  94587,  424113, 1 }, -- Further increases the power of Boundless Moonlight.  Fury of Elune The flash of energy now generates $s3 Astral Power and its damage is increased by $s4%.  Full Moon New Moon and Half Moon now also call down $s7 Minor Moon
    the_light_of_elune             = {  94585,  428655, 1 }, -- Moonfire damage has a chance to call down a Fury of Elune to follow your target for $s2 sec.  Fury of Elune Calls down a beam of pure celestial energy, dealing $s$s5 Astral damage over $s6 sec within its area. Generates $s7 Astral Power over its duration

    -- Keeper Of The Grove
    blooming_infusion              = {  94601,  429433, 1 }, -- Every $s1 Regrowths you cast makes your next Wrath, Starfire, or Entangling Roots instant and increases damage it deals by $s2%. Every $s3 Starsurges or Starfalls you cast makes your next Regrowth or Entangling roots instant
    bounteous_bloom                = {  94591,  429215, 1 }, -- Your Force of Nature treants generate $s1 Astral Power every $s2 sec
    cenarius_might                 = {  94604,  455797, 1 }, -- Entering Eclipse increases your Haste by $s1% for $s2 sec
    control_of_the_dream           = {  94592,  434249, 1 }, -- Time elapsed while your major abilities are available to be used or at maximum charges is subtracted from that ability's cooldown after the next time you use it, up to $s1 seconds. Affects Force of Nature, Incarnation: Chosen of Elune, and Convoke the Spirits
    dream_surge                    = {  94600,  433831, 1 }, -- Force of Nature grants $s2 charges of Dream Burst, causing your next Wrath or Starfire to explode on the target, dealing $s$s3 Nature damage to nearby enemies. Damage reduced above $s4 targets
    durability_of_nature           = {  94605,  429227, 1 }, -- Your Force of Nature treants have $s1% increased health
    early_spring                   = {  94591,  428937, 1 }, -- Force of Nature cooldown reduced by $s1 sec
    expansiveness                  = {  94602,  429399, 1 }, -- Your maximum mana is increased by $s1% and your maximum Astral Power is increased by $s2
    groves_inspiration             = {  94595,  429402, 1 }, -- Wrath and Starfire damage increased by $s1%. Regrowth and Wild Growth healing increased by $s2%
    harmony_of_the_grove           = {  94606,  428731, 1 }, -- Each of your Force of Nature treants increases damage your spells deal by $s1% while active
    potent_enchantments            = {  94595,  429420, 1 }, -- Orbital Strike applies Stellar Flare for $s1 additional sec and deals $s2% increased damage. Whirling Stars reduces the cooldown of Incarnation: Chosen of Elune by an additional $s3 sec
    power_of_nature                = {  94605,  428859, 1 }, -- Your Force of Nature treants no longer taunt and deal $s1% increased melee damage
    power_of_the_dream             = {  94592,  434220, 1 }, -- Force of Nature grants an additional stack of Dream Burst
    protective_growth              = {  94593,  433748, 1 }, -- Your Regrowth protects you, reducing damage you take by $s1% while your Regrowth is on you
    treants_of_the_moon            = {  94599,  428544, 1 }, -- Your Force of Nature treants cast Moonfire on nearby targets about once every $s1 sec
} )

-- PvP Talents
spec:RegisterPvpTalents( {
    celestial_guardian             =  180, -- (233754)
    crescent_burn                  =  182, -- (200567)
    deep_roots                     =  834, -- (233755)
    dying_stars                    =  822, -- (410544)
    faerie_swarm                   =  836, -- (209749) Swarms the target with Faeries, disarming the enemy, preventing the use of any weapons or shield and reducing movement speed by $s1% for $s2 sec
    high_winds                     = 5383, -- (200931) Increases the range of Cyclone, Typhoon, and Entangling Roots by $s1 yds
    malornes_swiftness             = 5515, -- (236147) Your Travel Form movement speed while within a Battleground or Arena is increased by $s1% and you always move at $s2% movement speed while in Travel Form
    master_shapeshifter            = 5604, -- (411266)
    moon_and_stars                 =  184, -- (233750)
    moonkin_aura                   =  185, -- (209740)
    owlkin_adept                   = 5407, -- (354541)
    protector_of_the_grove         = 3728, -- (209730)
    star_burst                     = 3058, -- (356517)
    thorns                         = 3731, -- (1217017) Casting Barkskin sprouts thorns on you for $s2 sec. When victim to melee attacks, thorns deals $s$s3 Nature damage back to the attacker. Attackers also have their movement speed reduced by $s4% for $s5 sec
    tireless_pursuit               = 5646, -- (377801) For $s1 sec after leaving Cat Form or Travel Form, you retain up to $s2% movement speed
} )

spec:RegisterPower( "lively_spirit", 279642, {
    id = 279648,
    duration = 20,
    max_stack = 1,
} )

local mod_circle_hot = setfenv( function( x )
    return x
end, state )

local mod_circle_dot = setfenv( function( x )
    return x
end, state )

-- Auras
spec:RegisterAuras( {
    astral_communion = {
        id = 450599,
        duration = 15,
        max_stack = 1
    },
    astral_smolder = {
        id = 394061,
        duration = 6,
        max_stack = 1
    },
    -- Talent: Critical strike chance with Nature spells increased $w1%.
    -- https://wowhead.com/beta/spell=394049
    balance_of_all_things_nature = {
        id = 394049,
        duration = 10,
        max_stack = 10,
        copy = 339943
    },
    -- Talent: Critical strike chance with Arcane spells increased $w1%.
    -- https://wowhead.com/beta/spell=394050
    balance_of_all_things_arcane = {
        id = 394050,
        duration = 10,
        max_stack = 10,
        copy = 339946
    },
    -- All damage taken reduced by $w1%.
    -- https://wowhead.com/beta/spell=22812
    barkskin = {
        id = 22812,
        duration = 8,
        type = "Magic",
        max_stack = 1
    },
    -- Armor increased by $w4%.  Stamina increased by $1178s2%.  Immune to Polymorph effects.
    -- https://wowhead.com/beta/spell=5487
    bear_form = {
        id = 5487,
        duration = 3600,
        type = "Magic",
        max_stack = 1
    },
    -- Generate $343216s1 combo $lpoint:points; every $t1 sec. Combo point generating abilities generate $s2 additional combo $lpoint:points;. Finishing moves restore up to $405189u combo points generated over the cap. All attack and ability damage is increased by $s3%.
    berserk = {
        id = 106951,
        duration = 15.0,
        max_stack = 1,
    },
    -- Your next Wrath, Starfire, or Entangling Roots is instant and deals $w2% increased damage.
    blooming_infusion = {
        id = 429474,
        duration = 12.0,
        max_stack = 1,
    },
    blooming_infusion_regrowth = {
        id = 429438,
        duration = 12.0,
        max_stack = 1,
    },
    -- Autoattack damage increased by $w4%.  Immune to Polymorph effects.  Movement speed increased by $113636s1% and falling damage reduced.
    -- https://wowhead.com/beta/spell=768
    cat_form = {
        id = 768,
        duration = 3600,
        type = "Magic",
        max_stack = 1

        -- Affected by:
        -- druid[137009] #3: { 'type': APPLY_AURA, 'subtype': MOD_GLOBAL_COOLDOWN_BY_HASTE_REGEN, 'sp_bonus': 0.25, 'points': 100.0, 'value': 11, 'schools': ['physical', 'holy', 'nature'], 'target': TARGET_UNIT_CASTER, }
        -- starfall[191034] #1: { 'type': APPLY_AURA, 'subtype': CAST_WHILE_WALKING, 'target': TARGET_UNIT_CASTER, }
        -- starfall[344869] #1: { 'type': APPLY_AURA, 'subtype': CAST_WHILE_WALKING, 'target': TARGET_UNIT_CASTER, }
    },
    -- Talent: Both Eclipses active. Haste increased by $w2%.
    -- https://wowhead.com/beta/spell=194223
    celestial_alignment = {
        id = 194223,
        duration = function () return 15 * ( talent.whirling_stars.enabled and 0.8 or 1 ) + ( conduit.precise_alignment.mod * 0.001 ) end,
        type = "Magic",
        max_stack = 1,
        copy = 383410

        -- Affected by:
        -- orbital_strike[390378] #0: { 'type': APPLY_AURA, 'subtype': OVERRIDE_ACTIONBAR_SPELLS, 'spell': 383410, 'value': 194223, 'schools': ['physical', 'holy', 'fire', 'nature', 'shadow'], 'value1': 2, 'target': TARGET_UNIT_CASTER, }
        -- orbital_strike[390378] #2: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'points': -60000.0, 'target': TARGET_UNIT_CASTER, 'modifies': COOLDOWN, }
    },
    ca_inc = {}, -- stub for celestial vs. incarnation
    -- Heals $w1 damage every $t1 seconds.
    -- https://wowhead.com/beta/spell=102352
    cenarion_ward = {
        id = 102352,
        duration = 8,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Haste increased by $w1%.
    cenarius_might = {
        id = 455801,
        duration = 6.0,
        max_stack = 1,
    },
    -- Talent / Covenant (Night Fae): Every 0.25 sec, casting Wild Growth, Swiftmend, Moonfire, Wrath, Regrowth, Rejuvenation, Rake or Thrash on appropriate nearby targets.
    -- https://wowhead.com/beta/spell=391528
    convoke_the_spirits = {
        id = 391528,
        duration = function() return talent.astral_insight.enabled and 5 or 4 end,
        tick_time = 0.25,
        max_stack = 99,
        copy = 323764
    },
    -- Heals $w1 damage every $t1 seconds.
    -- https://wowhead.com/beta/spell=200389
    cultivation = {
        id = 200389,
        duration = 6,
        max_stack = 1
    },
    -- Talent: Disoriented and invulnerable.
    -- https://wowhead.com/beta/spell=33786
    cyclone = {
        id = 33786,
        duration = 5,
        mechanic = "banish",
        type = "Magic",
        max_stack = 1

        -- Affected by:
        -- cat_form[3025] #3: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'points': -500.0, 'target': TARGET_UNIT_CASTER, 'modifies': GLOBAL_COOLDOWN, }
        -- heart_of_the_wild[319454] #12: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': -30.0, 'target': TARGET_UNIT_CASTER, 'modifies': CAST_TIME, }
    },
    -- Increased movement speed by $s1% while in Cat Form.
    -- https://wowhead.com/beta/spell=1850
    dream_burst = {
        id = 433832,
        duration = 30,
        type = "Magic",
        max_stack = function() return talent.power_of_the_dream.enabled and 4 or 3 end,
    },
    dash = {
        id = 1850,
        duration = 10,
        type = "Magic",
        max_stack = 1
    },
    -- Arcane spells deal $w1% additional damage$?<$w5>0>[, area effect damage increased $w5%,][] and Starfire's critical strike chance is increased by $w2%.
    -- https://wowhead.com/beta/spell=48518
    eclipse_lunar = {
        id = 48518,
        duration = 15, --self
        max_stack = 1,
    },
    -- Nature spells deal $w1% additional damage$?<$w5>0>[, Astral Power generation increased $w5%,][] and Wrath's damage is increased by $w2%.
    -- https://wowhead.com/beta/spell=48517
    eclipse_solar = {
        id = 48517,
        duration = 15, --self
        max_stack = 1,
    },
    -- Rooted.$?<$w2>0>[ Suffering $w2 Nature damage every $t2 sec.][]
    -- https://wowhead.com/beta/spell=339
    entangling_roots = {
        id = 339,
        duration = 30,
        tick_time = 2,
        mechanic = "root",
        type = "Magic",
        max_stack = 1
    },
    faerie_swarm = {
        id = 209749,
        duration = 5,
        max_stack = 1
    },
    force_of_nature = { -- TODO: Is a totem?  Summon?
        id = 205644,
        duration = 15,
        max_stack = 1,
    },
    forestwalk = {
        id = 400129,
        duration = 6.0,
        max_stack = 1
    },
    -- Bleeding for $w1 damage every $t sec.
    -- https://wowhead.com/beta/spell=391140
    frenzied_assault = {
        id = 391140,
        duration = 8,
        tick_time = 2,
        mechanic = "bleed",
        max_stack = 1
    },
    -- Talent: Healing $w1% health every $t1 sec.
    -- https://wowhead.com/beta/spell=22842
    frenzied_regeneration = {
        id = 22842,
        duration = 3,
        tick_time = 1,
        max_stack = 1
    },
    -- Movement speed reduced by $s2%. Suffering $w1 Nature damage every $t1 sec.
    fungal_growth = {
        id = 81281,
        duration = 10,
        tick_time = 2,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Generating ${$m3/10/$t3*$d} Astral Power over $d.
    -- https://wowhead.com/beta/spell=202770
    fury_of_elune_ap = {
        id = 202770,
        duration = 8,
        tick_time = 0.5,
        max_stack = 1,

        generate = function ( t )
            local applied = action.fury_of_elune.lastCast

            if applied and now - applied < 8 then
                t.count = 1
                t.expires = applied + 8
                t.applied = applied
                t.caster = "player"
                return
            end

            t.count = 0
            t.expires = 0
            t.applied = 0
            t.caster = "nobody"
        end,

        copy = "fury_of_elune"

        -- Affected by:
        -- mastery_astral_invocation[393014] #0: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'sp_bonus': 0.6, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- mastery_astral_invocation[393014] #1: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'sp_bonus': 0.6, 'target': TARGET_UNIT_CASTER, 'modifies': PERIODIC_DAMAGE_HEALING, }
        -- mastery_astral_invocation[393014] #2: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'sp_bonus': 0.6, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- mastery_astral_invocation[393014] #3: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'sp_bonus': 0.6, 'target': TARGET_UNIT_CASTER, 'modifies': PERIODIC_DAMAGE_HEALING, }
        -- moonfire[164812] #2: { 'type': APPLY_AURA, 'subtype': MOD_SPELL_DAMAGE_FROM_CASTER, 'target': TARGET_UNIT_TARGET_ENEMY, }
        -- moonfire[164812] #3: { 'type': APPLY_AURA, 'subtype': MOD_SPELL_DAMAGE_FROM_CASTER, 'target': TARGET_UNIT_TARGET_ENEMY, }
        -- sunfire[164815] #2: { 'type': APPLY_AURA, 'subtype': MOD_SPELL_DAMAGE_FROM_CASTER, 'radius': 8.0, 'target': TARGET_DEST_TARGET_ENEMY, 'target2': TARGET_UNIT_DEST_AREA_ENEMY, }
        -- sunfire[164815] #3: { 'type': APPLY_AURA, 'subtype': MOD_SPELL_DAMAGE_FROM_CASTER, 'radius': 8.0, 'target': TARGET_DEST_TARGET_ENEMY, 'target2': TARGET_UNIT_DEST_AREA_ENEMY, }
        -- radiant_moonlight[394121] #0: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'points': -15000.0, 'target': TARGET_UNIT_CASTER, 'modifies': COOLDOWN, }
        -- radiant_moonlight[394121] #2: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 50.0, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- balance_of_all_things[394049] #0: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'target': TARGET_UNIT_CASTER, 'modifies': CRIT_CHANCE, }
        -- eclipse_solar[48517] #0: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': 15.0, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- eclipse_solar[48517] #2: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'target': TARGET_UNIT_CASTER, 'modifies': DAMAGE_HEALING, }
        -- eclipse_solar[48517] #3: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'target': TARGET_UNIT_CASTER, 'modifies': PERIODIC_DAMAGE_HEALING, }
    },
    -- Taunted.
    -- https://wowhead.com/beta/spell=6795
    growl = {
        id = 6795,
        duration = 3,
        mechanic = "taunt",
        max_stack = 1
    },
    harmony_of_the_grove = {
        id = 428735,
        duration = 10,
        max_stack = 1
    },
    -- Talent: Abilities not associated with your specialization are substantially empowered.
    -- https://wowhead.com/beta/spell=319454
    heart_of_the_wild = {
        id = 319454,
        duration = 45,
        tick_time = 2,
        max_stack = 1,
        copy = { 108291, 108292, 108293, 108294 }
    },
    -- Talent: Asleep.
    -- https://wowhead.com/beta/spell=2637
    hibernate = {
        id = 2637,
        duration = 40,
        mechanic = "sleep",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Incapacitated.
    -- https://wowhead.com/beta/spell=99
    incapacitating_roar = {
        id = 99,
        duration = 3,
        mechanic = "incapacitate",
        max_stack = 1

        -- Affected by:
        -- druid[137009] #3: { 'type': APPLY_AURA, 'subtype': MOD_GLOBAL_COOLDOWN_BY_HASTE_REGEN, 'sp_bonus': 0.25, 'points': 100.0, 'value': 11, 'schools': ['physical', 'holy', 'nature'], 'target': TARGET_UNIT_CASTER, }
        -- astral_influence[197524] #2: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'points': 3.0, 'target': TARGET_UNIT_CASTER, 'modifies': RADIUS, }
        -- starfall[191034] #1: { 'type': APPLY_AURA, 'subtype': CAST_WHILE_WALKING, 'target': TARGET_UNIT_CASTER, }
        -- starfall[344869] #1: { 'type': APPLY_AURA, 'subtype': CAST_WHILE_WALKING, 'target': TARGET_UNIT_CASTER, }
    },
    -- Talent: Both Eclipses active. Critical strike chance increased by $w2%$?s194223[ and haste increased by $w1%][].
    -- https://wowhead.com/beta/spell=102560
    incarnation = {
        id = 102560,
        duration = function () return 16 + ( conduit.precise_alignment.mod * 0.001 ) end, --self
        max_stack = 1,
        copy = "incarnation_chosen_of_elune",

        -- Affected by:
        -- druid[137009] #3: { 'type': APPLY_AURA, 'subtype': MOD_GLOBAL_COOLDOWN_BY_HASTE_REGEN, 'sp_bonus': 0.25, 'points': 100.0, 'value': 11, 'schools': ['physical', 'holy', 'nature'], 'target': TARGET_UNIT_CASTER, }
        -- elunes_guidance[393991] #4: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER_BY_LABEL, 'points': -80.0, 'target': TARGET_UNIT_CASTER, 'modifies': EFFECT_3_VALUE, }
        -- elunes_guidance[393991] #5: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER_BY_LABEL, 'points': -100.0, 'target': TARGET_UNIT_CASTER, 'modifies': EFFECT_4_VALUE, }
        -- orbital_strike[390378] #1: { 'type': APPLY_AURA, 'subtype': OVERRIDE_ACTIONBAR_SPELLS, 'spell': 390414, 'value': 102560, 'schools': ['shadow'], 'value1': 2, 'target': TARGET_UNIT_CASTER, }
        -- orbital_strike[390378] #2: { 'type': APPLY_AURA, 'subtype': ADD_FLAT_MODIFIER, 'points': -60000.0, 'target': TARGET_UNIT_CASTER, 'modifies': COOLDOWN, }
    },
    -- Movement speed slowed by $w1%.$?e1[ Healing taken reduced by $w2%.][]
    -- https://wowhead.com/beta/spell=58180
    infected_wounds = {
        id = 58180,
        duration = 12,
        max_stack = 1
    },
    -- Talent: Mana costs reduced $w1%.
    -- https://wowhead.com/beta/spell=29166
    innervate = {
        id = 29166,
        duration = 10,
        type = "Magic",
        max_stack = 1
        -- Affected by:
        -- cat_form[768] #1: { 'type': APPLY_AURA, 'subtype': MOD_IGNORE_SHAPESHIFT, 'target': TARGET_UNIT_CASTER, }
        -- bear_form[5487] #1: { 'type': APPLY_AURA, 'subtype': MOD_IGNORE_SHAPESHIFT, 'target': TARGET_UNIT_CASTER, }
    },
    -- Talent: Armor increased by ${$w1*$AGI/100}.
    -- https://wowhead.com/beta/spell=192081
    ironfur = {
        id = 192081,
        duration = 7,
        type = "Magic",
        max_stack = 1
    },
    -- The damage of your next Arcane ability is increased by $w1%.
    lunar_amplification = {
        id = 431250,
        duration = 45.0,
        max_stack = 1,
    },
    -- Versatility increased by $w1%.
    -- https://wowhead.com/beta/spell=1126
    mark_of_the_wild = {
        id = 1126,
        duration = 3600,
        type = "Magic",
        max_stack = 1,
        shared = "player"
    },
    -- Talent: Rooted.
    -- https://wowhead.com/beta/spell=102359
    mass_entanglement = {
        id = 102359,
        duration = 10,
        tick_time = 2,
        mechanic = "root",
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Absorbs $w1 damage.
    -- https://wowhead.com/beta/spell=385787
    matted_fur = {
        id = 385787,
        duration = 8,
        max_stack = 1
    },
    -- Talent: Stunned.
    -- https://wowhead.com/beta/spell=5211
    mighty_bash = {
        id = 5211,
        duration = 4,
        mechanic = "stun",
        max_stack = 1
    },
    -- PvP Talent: Entering an Eclipse summons a beam of light at your location granting you 50% reduction in silence and interrupts for 6 sec.
    -- https://www.wowhead.com/spell=234084
    moon_and_stars = {
        id = 234084,
        duration = 6,
        max_stack = 1
    },
    -- Suffering $w2 Arcane damage every $t2 seconds.$?$w8<0[; Movement slowed by $w8%.][]
    moonfire = {
        id = 164812,
        duration = function () return mod_circle_dot( level > 13 and 22 or 18 ) end,
        tick_time = function () return mod_circle_dot( 2 ) * ( 1 - 0.125 * talent.cosmic_rapidity.rank ) * haste end,
        type = "Magic",
        max_stack = 1,
        copy = { 155625, "moonfire_dmg" }
    },
    -- PvP Talent: Starsurge grants 4% spell critical strike chance to 8 allies within 40 yards for 18 sec, stacking up to 3 times.
    -- https://www.wowhead.com/spell=209746
    moonkin_aura = {
        id = 209746,
        duration = 18,
        max_stack = 3
    },
    -- Spell damage increased by $s9%.; Immune to Polymorph effects.$?$w3>0[; Armor increased by $w3%.][]$?$w12<0[; Arcane damage taken reduced by $w13% and all other magic damage taken reduced by $w12%.][]
    moonkin_form = {
        id = 24858,
        duration = 3600,
        type = "Magic",
        max_stack = 1,
        copy = 197625
    },
    -- Talent: $?s137012[Single-target healing also damages a nearby enemy target for $w3% of the healing done][Single-target damage also heals a nearby friendly target for $w3% of the damage done].
    -- https://wowhead.com/beta/spell=124974
    natures_vigil = {
        id = 124974,
        duration = 15,
        tick_time = 0.5,
        max_stack = 1
    },
    orbit_breaker = {
        id = 329970,
        duration = 3600,
        max_stack = 20
    },
    -- Your next Starfire is instant cast$?s354541[ or your next Cyclone or Entangling Roots cast time is reduced by $s2%.][.]
    -- https://wowhead.com/beta/spell=157228
    owlkin_frenzy = {
        id = 157228,
        duration = 10,
        type = "Magic",
        max_stack = function () return pvptalent.owlkin_adept.enabled and 2 or 1 end
    },
    parting_skies = {
        id = 395110,
        duration = 60,
        max_stack = 1,
    },
    -- All damage taken reduced by $w1%.
    protective_growth = {
        id = 433749,
        duration = 3600,
        max_stack = 1,
    },
    -- Stealthed.
    -- https://wowhead.com/beta/spell=5215
    prowl_base = {
        id = 5215,
        duration = 3600,
        multiplier = function() return talent.pouncing_strikes.enabled and 1.6 or 1 end,
    },
    prowl_incarnation = {
        id = 102547,
        duration = 3600,
        multiplier = function() return talent.pouncing_strikes.enabled and 1.6 or 1 end,
    },
    prowl = {
        alias = { "prowl_base", "prowl_incarnation" },
        aliasMode = "first",
        aliasType = "buff",
        duration = 3600
    },
    -- Cost of Starsurge and Starfall reduced by $w1%, and their damage increased by $w2%.
    -- https://wowhead.com/beta/spell=393955
    rattled_stars = {
        id = 393955,
        duration = 6,
        max_stack = 2,
        copy = "rattle_the_stars"
    },
    -- Heals $w2 every $t2 sec.
    -- https://wowhead.com/beta/spell=8936
    regrowth = {
        id = 8936,
        duration = function () return mod_circle_hot( 12 ) end,
        tick_time =  function () return mod_circle_hot( 2 ) end,
        type = "Magic",
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
     -- Healing $w1 every $t1 sec.
    rejuvenation = {
        id = 774,
        duration = 12.0,
        pandemic = true,
        max_stack = 1,
    },
    -- Healing $w1 every $t1 sec.
    -- https://wowhead.com/beta/spell=155777
    rejuvenation_germination = {
        id = 155777,
        duration = 12,
        type = "Magic",
        max_stack = 1
    },
    -- Healing $s1 every $t sec.
    -- https://wowhead.com/beta/spell=364686
    renewing_bloom = {
        id = 364686,
        duration = 8,
        max_stack = 1
    },
    -- Bleeding for $w1 damage every $t1 sec.
    rip = {
        id = 1079,
        duration = 4.0,
        tick_time = 2.0,
        pandemic = true,
        max_stack = 1,
    },
    rising_light_falling_night_day = {
        id = 417714,
        duration = 3600,
        max_stack = 1
    },
    rising_light_falling_night_night = {
        id = 417715,
        duration = 3600,
        max_stack = 1
    },
    -- Talent: Silenced.
    -- https://wowhead.com/beta/spell=81261
    solar_beam = {
        id = 81261,
        duration = 3600,
        max_stack = 1,
    },
    -- Talent: Interrupted.
    -- https://wowhead.com/beta/spell=78675
    solar_beam_silence = { -- Silence.
        id = 78675,
        duration = 8,
        max_stack = 1
    },
    solstice = {
        id = 343648,
        duration = 6,
        max_stack = 1,
    },
    -- Heals $w1 damage every $t1 seconds.
    -- https://wowhead.com/beta/spell=207386
    spring_blossoms = {
        id = 207386,
        duration = 6,
        max_stack = 1
    },
    stag_form = {
        id = 210053,
        duration = 3600,
        max_stack = 1,
        generate = function ()
            local form = GetShapeshiftForm()
            local stag = form and form > 0 and select( 4, GetShapeshiftFormInfo( form ) )

            local sf = buff.stag_form

            if stag == 210053 then
                sf.count = 1
                sf.applied = now
                sf.expires = now + 3600
                sf.caster = "player"
                return
            end

            sf.count = 0
            sf.applied = 0
            sf.expires = 0
            sf.caster = "nobody"
        end,
        copy = "mount_form"
    },
     -- Movement speed increased by $s1%.
     stampeding_roar = {
        id = 106898,
        duration = 8.0,
        max_stack = 1,
    },
    -- Talent: Calling down falling stars on nearby enemies.
    -- https://wowhead.com/beta/spell=191034
    starfall = {
        id = 191034,
        duration = 8,
        tick_time = 1.0,
        type = "Magic",
        max_stack = 20,
        copy = 393040
    },
    starlord = {
        id = 279709,
        duration = 20,
        max_stack = 3,
    },
    starweavers_warp = { -- free Starfall.
        id = 393942,
        duration = 30,
        max_stack = 1,
    },
    starweavers_weft = { -- free Starsurge.
        id = 393944,
        duration = 30,
        max_stack = 1,
    },
    -- Damage over time from $@auracaster increased by $w1%.
    stellar_amplification = {
        id = 450214,
        duration = 5.0,
        max_stack = 1,
    },
    -- Talent: Suffering $w2 Astral damage every $t2 sec.
    -- https://wowhead.com/beta/spell=202347
    stellar_flare = {
        id = 202347,
        duration = function () return mod_circle_dot( 24 ) end,
        tick_time = function () return mod_circle_dot( 2 ) * ( 1 - 0.125 * talent.cosmic_rapidity.rank ) * haste end,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Suffering $w2 Nature damage every $t2 seconds.
    -- https://wowhead.com/beta/spell=164815
    sunfire = {
        id = 164815,
        duration = function () return mod_circle_dot( 18 ) end,
        tick_time = function () return mod_circle_dot( 2 ) * ( 1 - 0.125 * talent.cosmic_rapidity.rank ) * haste end,
        type = "Magic",
        max_stack = 1
    },
    -- Bleeding for $w1 damage every $t1 seconds.
    -- https://wowhead.com/beta/spell=391356
    tear = {
        id = 391356,
        duration = 8,
        tick_time = 2,
        mechanic = "bleed",
        max_stack = 1
    },
    -- Melee attackers take Nature damage when hit and their movement speed is slowed by $232559s1% for $232559d.
    -- https://wowhead.com/beta/spell=305497
    thorns = {
        id = 305497,
        duration = 12,
        max_stack = 1
    },
    -- Talent: Increased movement speed by $s1% while in Cat Form, reducing gradually over time.
    -- https://wowhead.com/beta/spell=252216
    tiger_dash = {
        id = 252216,
        duration = 5,
        type = "Magic",
        max_stack = 1
    },
    touch_the_cosmos = {
        id = 450360,
        duration = 15,
        max_stack = 1,
        copy = { "touch_the_cosmos_starfall", "touch_the_cosmos_starsurge" }
    },
    -- Immune to Polymorph effects.  Movement speed increased.
    -- https://wowhead.com/beta/spell=783
    travel_form = {
        id = 783,
        duration = 3600,
        type = "Magic",
        max_stack = 1
    },
    treant_form = {
        id = 114282,
        duration = 3600,
        max_stack = 1,
    },
    -- Talent: Dazed.
    -- https://wowhead.com/beta/spell=61391
    typhoon = {
        id = 61391,
        duration = 6,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Your next Wrath of Starfire deals Astral damage and deals $w1% additional damage.
    -- https://wowhead.com/beta/spell=393763
    umbral_embrace = {
        id = 393763,
        duration = 15,
        max_stack = 1
    },
    -- Moonfire, Sunfire, Stellar Flare, Shooting Stars, and Starfall damage increased by $w1%
    umbral_inspiration = {
        id = 450419,
        duration = 6.0,
        max_stack = 1,
    },
    ursine_vigor = {
        id = 340541,
        duration = 4,
        max_stack = 1
    },
    -- Movement speed slowed by $s1% and winds impeding movement.
    -- https://wowhead.com/beta/spell=102793
    ursols_vortex = {
        id = 102793,
        duration = 10,
        type = "Magic",
        max_stack = 1
    },
    -- Talent: Starfire is instant cast and generates $s2% increased Astral Power.
    -- https://wowhead.com/beta/spell=202425
    warrior_of_elune = {
        id = 202425,
        duration = 25,
        type = "Magic",
        max_stack = 3
    },
    -- Talent: Flying to an ally's position.
    -- https://wowhead.com/beta/spell=102401
    wild_charge = {
        id = 102401,
        duration = 0.5,
        max_stack = 1
    },
    -- Talent: Heals $w1 damage every $t1 sec.
    -- https://wowhead.com/beta/spell=48438
    wild_growth = {
        id = 48438,
        duration = 7,
        type = "Magic",
        max_stack = 1
    },

    -- Legendaries
    celestial_infusion = {
        id = 367907,
        duration = 8,
        max_stack = 1
    },
    oath_of_the_elder_druid = {
        id = 338643,
        duration = 60,
        max_stack = 1
    },
    oneths_perception = {
        id = 339800,
        duration = 30,
        max_stack = 1,
    },
    oneths_clear_vision = {
        id = 339797,
        duration = 30,
        max_stack = 1,
    },
    primordial_arcanic_pulsar = {
        id = 393961,
        duration = 3600,
        max_stack = 100,
        copy = 338825
    },
    timeworn_dreambinder = {
        id = 340049,
        duration = 6,
        max_stack = 2,
    },
} )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237685, 237680, 237683, 237681, 237682 },
        auras = {
            -- Elunes Chosen
            gathering_moonlight = {
                id = 1236989,
                duration = 20,
                max_stack = 15
            },
            moonlight_suffusion = {
                id = 1236990,
                duration = 12,
                max_stack = 15
            },
            -- Keeper of the Grove
            -- Dryad A dryad is assisting you! $s1 seconds remaining
            -- https://www.wowhead.com/spell=1236556
            dryad = {
                id = 1236556,
                duration = 5, -- 10 for balance
                max_stack = 1
            },
            -- Dryad's Favor The healing of your next Swiftmend is increased by $s1 and it splashes $s2% of its healing done to nearby allies, reduced beyond $s3 targets. $s4 seconds remaining
            -- https://www.wowhead.com/spell=1236807
            dryads_favor = {
                id = 1236807,
                duration = 45,
                max_stack = 2
            },
            -- New tier set hot version
            -- https://www.wowhead.com/spell=1236573
            tranquility = {
                id = 1236573,
                duration = 8,
                max_stack = 5
            },
            -- New tier set version on dryad
            starfall = {
                id = 1236607,
                duration = 10,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229310, 229308, 229306, 229307, 229305 }
    },
    tww1 = {
        items = { 212059, 212057, 212056, 212055, 212054 }
    },
    -- Dragonflight
    tier31 = {
        items = { 207252, 207253, 207254, 207255, 207257 },
        auras = {
            dreamstate = {
                id = 424248,
                duration = 3600,
                max_stack = 2,
                copy = 450346
            }
        }
    },
    tier30 = {
        items = { 202518, 202516, 202515, 202514, 202513 }
    },
    tier29 = {
        items = { 200351, 200353, 200354, 200355, 200356, 217193, 217195, 217191, 217192, 217194 },
        auras = {
            gathering_starstuff = {
                id = 394412,
                duration = 15,
                max_stack = 3
            },
            touch_the_cosmos = {
                id = 394414,
                duration = 15,
                max_stack = 1
            }
        }
    },

    -- Legacy
    tier21 = {
        items = { 152127, 152129, 152125, 152124, 152126, 152128 },
        auras = {
            solar_solstice = {
                id = 252767,
                duration = 6,
                max_stack = 1
            }
        }
    },
    tier20 = { items = { 147136, 147138, 147134, 147133, 147135, 147137 } },
    tier19 = { items = { 138330, 138336, 138366, 138324, 138327, 138333 } },
    class = { items = { 139726, 139728, 139723, 139730, 139725, 139729, 139727, 139724 } },
    impeccable_fel_essence = { items = { 137039 } },
    oneths_intuition = {
        items = { 137092 },
        auras = {
            oneths_intuition = {
                id = 209406,
                duration = 3600,
                max_stacks = 1
            },
            oneths_overconfidence = {
                id = 209407,
                duration = 3600,
                max_stacks = 1
            }
        }
    },
    radiant_moonlight = { items = { 151800 } },
    the_emerald_dreamcatcher = {
        items = { 137062 },
        auras = {
            the_emerald_dreamcatcher = {
                id = 224706,
                duration = 5,
                max_stack = 2
            }
        }
    }
} )

-- Adaptive Swarm Stuff
do
    local applications = {
        SPELL_AURA_APPLIED = true,
        SPELL_AURA_REFRESH = true,
        SPELL_AURA_APPLIED_DOSE = true
    }

    local casts = { SPELL_CAST_SUCCESS = true }

    local removals = {
        SPELL_AURA_REMOVED = true,
        SPELL_AURA_BROKEN = true,
        SPELL_AURA_BROKEN_SPELL = true,
        SPELL_AURA_REMOVED_DOSE = true,
        SPELL_DISPEL = true
    }

    local deaths = {
        UNIT_DIED       = true,
        UNIT_DESTROYED  = true,
        UNIT_DISSIPATES = true,
        PARTY_KILL      = true,
        SPELL_INSTAKILL = true,
    }

    local spellIDs = {
        [325733] = true,
        [325889] = true,
        [325748] = true,
        [325891] = true,
        [325727] = true
    }

    local flights = {}
    local pending = {}
    local swarms = {}

    -- Flow:  Cast -> In Flight -> Application -> Ticks -> Removal -> In Flight -> Application -> Ticks -> Removal -> ...
    -- If the swarm target dies, it will jump again.
    local insert, remove = table.insert, table.remove

    function Hekili:EmbedAdaptiveSwarm( s )
        s:RegisterCombatLogEvent( function( _, subtype, _,  sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName )
            if not state.covenant.necrolord and not state.talent.adaptive_swarm.enabled then return end

            if sourceGUID == state.GUID and spellIDs[ spellID ] then
                -- On cast, we need to show we have a cast-in-flight.
                if casts[ subtype ] then
                    local dot

                    if bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 then
                        dot = "adaptive_swarm_damage"
                    else
                        dot = "adaptive_swarm_heal"
                    end

                    insert( flights, { destGUID, 3, GetTime() + 5, dot } )

                -- On application, we need to store the GUID of the unit so we can get the stacks and expiration time.
                elseif applications[ subtype ] and #flights > 0 then
                    local n, flight

                    for i, v in ipairs( flights ) do
                        if v[1] == destGUID then
                            n = i
                            flight = v
                            break
                        end
                        if not flight and v[1] == "unknown" then
                            n = i
                            flight = v
                        end
                    end

                    if flight then
                        local swarm = swarms[ destGUID ]
                        local now = GetTime()

                        if swarm and swarm.expiration > now then
                            swarm.stacks = swarm.stacks + flight[2]
                            swarm.dot = bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 and "adaptive_swarm_damage" or "adaptive_swarm_heal"
                            swarm.expiration = now + class.auras[ swarm.dot ].duration
                        else
                            swarms[ destGUID ] = {}
                            swarms[ destGUID ].stacks = flight[2]
                            swarms[ destGUID ].dot = bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 and "adaptive_swarm_damage" or "adaptive_swarm_heal"
                            swarms[ destGUID ].expiration = now + class.auras[ swarms[ destGUID ].dot ].duration
                        end
                        remove( flights, n )
                    else
                        swarms[ destGUID ] = {}
                        swarms[ destGUID ].stacks = 3 -- We'll assume it's fresh.
                        swarms[ destGUID ].dot = bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 and "adaptive_swarm_damage" or "adaptive_swarm_heal"
                        swarms[ destGUID ].expiration = GetTime() + class.auras[ swarms[ destGUID ].dot ].duration
                    end

                elseif removals[ subtype ] then
                    -- If we have a swarm for this, remove it.
                    local swarm = swarms[ destGUID ]

                    if swarm then
                        swarms[ destGUID ] = nil

                        if swarm.stacks > 1 then
                            local dot

                            if bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 then
                                dot = "adaptive_swarm_heal"
                            else
                                dot = "adaptive_swarm_damage"
                            end

                            insert( flights, { "unknown", swarm.stacks - 1, GetTime() + 5, dot } )

                        end
                    end
                end

            elseif swarms[ destGUID ] and deaths[ subtype ] then
                -- If we have a swarm for this, remove it.
                local swarm = swarms[ destGUID ]

                if swarm then
                    swarms[ destGUID ] = nil

                    if swarm.stacks > 1 then
                        if bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 then
                            dot = "adaptive_swarm_heal"
                        else
                            dot = "adaptive_swarm_damage"
                        end

                        insert( flights, { "unknown", swarm.stacks - 1, GetTime() + 5, dot } )

                    end
                end
            end
        end )

        function s.GetActiveSwarms()
            return swarms
        end

        function s.GetPendingSwarms()
            return pending
        end

        function s.GetInFlightSwarms()
            return flights
        end

        local flySwarm, landSwarm

        landSwarm = setfenv( function( aura )
            if aura.key == "adaptive_swarm_heal_in_flight" then
                applyBuff( "adaptive_swarm_heal", 12, min( 5, buff.adaptive_swarm_heal.stack + aura.count ) )
                buff.adaptive_swarm_heal.expires = query_time + 12
                state:QueueAuraEvent( "adaptive_swarm", flySwarm, buff.adaptive_swarm_heal.expires, "AURA_EXPIRATION", buff.adaptive_swarm_heal )
            else
                applyDebuff( "target", "adaptive_swarm_damage", 12, min( 5, debuff.adaptive_swarm_damage.stack + aura.count ) )
                debuff.adaptive_swarm_damage.expires = query_time + 12
                state:QueueAuraEvent( "adaptive_swarm", flySwarm, debuff.adaptive_swarm_damage.expires, "AURA_EXPIRATION", debuff.adaptive_swarm_damage )
            end
        end, state )

        flySwarm = setfenv( function( aura )
            if aura.key == "adaptive_swarm_heal" then
                applyBuff( "adaptive_swarm_heal_in_flight", 5, aura.count - 1 )
                state:QueueAuraEvent( "adaptive_swarm", landSwarm, query_time + 5, "AURA_EXPIRATION", buff.adaptive_swarm_heal_in_flight )
            else
                applyBuff( "adaptive_swarm_damage_in_flight", 5, aura.count - 1 )
                state:QueueAuraEvent( "adaptive_swarm", landSwarm, query_time + 5, "AURA_EXPIRATION", buff.adaptive_swarm_damage_in_flight )
            end
        end, state )

        s.SwarmOnReset = setfenv( function()
            for k, v in pairs( swarms ) do
                if v.expiration + 0.1 <= now then swarms[ k ] = nil end
            end

            for i = #flights, 1, -1 do
                if flights[i][3] + 0.1 <= now then remove( flights, i ) end
            end

            local target = UnitGUID( "target" )
            local tSwarm = swarms[ target ]

            if not UnitIsFriend( "target", "player" ) and tSwarm and tSwarm.expiration > now then
                applyDebuff( "target", "adaptive_swarm_damage", tSwarm.expiration - now, tSwarm.stacks )
                debuff.adaptive_swarm_damage.expires = tSwarm.expiration

                if tSwarm.stacks > 1 then
                    state:QueueAuraEvent( "adaptive_swarm", flySwarm, tSwarm.expiration, "AURA_EXPIRATION", debuff.adaptive_swarm_damage )
                end
            end

            if buff.adaptive_swarm_heal.up and buff.adaptive_swarm_heal.stack > 1 then
                state:QueueAuraEvent( "adaptive_swarm", flySwarm, buff.adaptive_swarm_heal.expires, "AURA_EXPIRATION", buff.adaptive_swarm_heal )
            else
                for k, v in pairs( swarms ) do
                    if k ~= target and v.dot == "adaptive_swarm_heal" then
                        applyBuff( "adaptive_swarm_heal", v.expiration - now, v.stacks )
                        buff.adaptive_swarm_heal.expires = v.expiration

                        if v.stacks > 1 then
                            state:QueueAuraEvent( "adaptive_swarm", flySwarm, buff.adaptive_swarm_heal.expires, "AURA_EXPIRATION", buff.adaptive_swarm_heal )
                        end
                    end
                end
            end

            local flight

            for i, v in ipairs( flights ) do
                if not flight or v[3] > now and v[3] > flight then flight = v end
            end

            if flight then
                local dot = flight[4] .. "_in_flight"
                applyBuff( dot, flight[3] - now, flight[2] )
                state:QueueAuraEvent( dot, landSwarm, flight[3], "AURA_EXPIRATION", buff[ dot ] )
            end

            Hekili:Debug( "Swarm Info:\n   Damage - %.2f remains, %d stacks.\n   Dmg In Flight - %.2f remains, %d stacks.\n   Heal - %.2f remains, %d stacks.\n   Heal In Flight - %.2f remains, %d stacks.\n   Count Dmg: %d, Count Heal: %d.", dot.adaptive_swarm_damage.remains, dot.adaptive_swarm_damage.stack, buff.adaptive_swarm_damage_in_flight.remains, buff.adaptive_swarm_damage_in_flight.stack, buff.adaptive_swarm_heal.remains, buff.adaptive_swarm_heal.stack, buff.adaptive_swarm_heal_in_flight.remains, buff.adaptive_swarm_heal_in_flight.stack, active_dot.adaptive_swarm_damage, active_dot.adaptive_swarm_heal )
        end, state )

        function Hekili:DumpSwarmInfo()
            local line = "Flights:"
            for k, v in pairs( flights ) do
                line = line .. " " .. k .. ":" .. table.concat( v, ":" )
            end
            print( line )

            line = "Pending:"
            for k, v in pairs( pending ) do
                line = line .. " " .. k .. ":" .. v
            end
            print( line )

            line = "Swarms:"
            for k, v in pairs( swarms ) do
                line = line .. " " .. k .. ":" .. v.stacks .. ":" .. v.expiration
            end
            print( line )
        end

        -- Druid - Necrolord - 325727 - adaptive_swarm       (Adaptive Swarm)
        spec:RegisterAbility( "adaptive_swarm", {
            id = function() return talent.adaptive_swarm.enabled and 391888 or 325727 end,
            cast = 0,
            cooldown = 25,
            gcd = "spell",

            spend = 0.05,
            spendType = "mana",

            startsCombat = true,

            -- For Feral, we want to put Adaptive Swarm on the highest health enemy.
            indicator = function ()
                if state.spec.feral and active_enemies > 1 and target.time_to_die < longest_ttd then return "cycle" end
            end,

            handler = function ()
                applyDebuff( "target", "adaptive_swarm_dot", nil, 3 )
                if soulbind.kevins_oozeling.enabled then applyBuff( "kevins_oozeling" ) end
            end,

            copy = { "adaptive_swarm_damage", "adaptive_swarm_heal", 325727, 325733, 325748, 391888 },

            auras = {
                -- Suffering $w1 Shadow damage every $t1 sec and damage over time from $@auracaster increased by $w2%.
                -- https://wowhead.com/beta/spell=325733
                adaptive_swarm_dot = {
                    id = 325733,
                    duration = 12,
                    tick_time = 2,
                    type = "Magic",
                    max_stack = 5,
                    copy = { 391889, "adaptive_swarm_damage" }
                },
                -- Restoring $w1 health every $t1 sec and healing over time from $@auracaster increased by $w2%.
                -- https://wowhead.com/beta/spell=325748
                adaptive_swarm_hot = {
                    id = 325748,
                    duration = 12,
                    max_stack = 5,
                    dot = "buff",
                    copy = { 391891, "adaptive_swarm_heal" }
                },
                adaptive_swarm_damage_in_flight = {
                    duration = 5,
                    max_stack = 5
                },
                adaptive_swarm_heal_in_flight = {
                    duration = 5,
                    max_stack = 5,
                },
                adaptive_swarm = {
                    alias = { "adaptive_swarm_damage", "adaptive_swarm_heal" },
                    aliasMode = "first", -- use duration info from the first buff that's up, as they should all be equal.
                    aliasType = "any",
                },
                adaptive_swarm_in_flight = {
                    alias = { "adaptive_swarm_damage", "adaptive_swarm_heal" },
                    aliasMode = "shortest", -- use duration info from the first buff that's up, as they should all be equal.
                    aliasType = "any",
                },
            }
        } )
    end
end

Hekili:EmbedAdaptiveSwarm( spec )

spec:RegisterStateFunction( "break_stealth", function ()
    removeBuff( "shadowmeld" )
    if buff.prowl.up then
        setCooldown( "prowl", 6 )
        removeBuff( "prowl" )
    end
end )

-- Function to remove any form currently active.
spec:RegisterStateFunction( "unshift", function()
    if conduit.tireless_pursuit.enabled and ( buff.cat_form.up or buff.travel_form.up ) then applyBuff( "tireless_pursuit" ) end

    removeBuff( "cat_form" )
    removeBuff( "bear_form" )
    removeBuff( "travel_form" )
    removeBuff( "moonkin_form" )
    removeBuff( "travel_form" )
    removeBuff( "aquatic_form" )
    removeBuff( "stag_form" )
    removeBuff( "celestial_guardian" )

    if legendary.oath_of_the_elder_druid.enabled and debuff.oath_of_the_elder_druid_icd.down and talent.restoration_affinity.enabled then
        applyBuff( "heart_of_the_wild" )
        applyDebuff( "player", "oath_of_the_elder_druid_icd" )
    end
end )

local affinities = {
    bear_form = "guardian_affinity",
    cat_form = "feral_affinity",
    moonkin_form = "balance_affinity",
}

-- Function to apply form that is passed into it via string.
spec:RegisterStateFunction( "shift", function( form )
    if conduit.tireless_pursuit.enabled and ( buff.cat_form.up or buff.travel_form.up ) then applyBuff( "tireless_pursuit" ) end

    removeBuff( "cat_form" )
    removeBuff( "bear_form" )
    removeBuff( "travel_form" )
    removeBuff( "moonkin_form" )
    removeBuff( "travel_form" )
    removeBuff( "aquatic_form" )
    removeBuff( "stag_form" )
    applyBuff( form )

    if affinities[ form ] and legendary.oath_of_the_elder_druid.enabled and debuff.oath_of_the_elder_druid_icd.down then
        applyBuff( "heart_of_the_wild" )
        applyDebuff( "player", "oath_of_the_elder_druid_icd" )
    end

    if form == "bear_form" and pvptalent.celestial_guardian.enabled then
        applyBuff( "celestial_guardian" )
    end
end )

spec:RegisterStateExpr( "energize_amount", function ()
    local ability = class.abilities[ this_action ]
    local amount = ability and ability.energize_amount

    if not amount then return 0 end
    return -amount
end )

spec:RegisterHook( "runHandler", function( ability )
    local a = class.abilities[ ability ]

    if not a or a.startsCombat then
        break_stealth()
    end
end )

--[[ This is intended to cause an AP reset on entering an encounter, but it's not working.
    spec:RegisterHook( "start_combat", function( action )
    if boss and astral_power.current > 50 then
        spend( astral_power.current - 50, "astral_power" )
    end
end ) ]]

spec:RegisterHook( "pregain", function( amt, resource, overcap, clean )
    if buff.memory_of_lucid_dreams.up then
        if amt > 0 and resource == "astral_power" then
            return amt * 2, resource, overcap, true
        end
    end
end )

spec:RegisterHook( "prespend", function( amt, resource, overcap, clean )
    if buff.memory_of_lucid_dreams.up then
        if amt < 0 and resource == "astral_power" then
            return amt * 2, resource, overcap, true
        end
    end
end )

local check_for_ap_overcap = setfenv( function( ability )
    local a = ability or this_action
    if not a then return true end

    a = action[ a ]
    if not a then return true end

    local cost = 0
    if a.spendType == "astral_power" then cost = a.cost end

    return astral_power.current - cost + ( talent.shooting_stars.enabled and 4 or 0 ) + ( talent.natures_balance.enabled and ceil( execute_time / 2 ) or 0 ) < astral_power.max
end, state )

spec:RegisterStateExpr( "ap_check", function() return check_for_ap_overcap() end )

-- Simplify lookups for AP abilities consistent with SimC.
local ap_checks = {
    "force_of_nature", "full_moon", "half_moon", "incarnation", "moonfire", "new_moon", "starfall", "starfire", "starsurge", "sunfire", "wrath"
}

for i, lookup in ipairs( ap_checks ) do
    spec:RegisterStateExpr( lookup, function ()
        return action[ lookup ]
    end )
end

spec:RegisterStateExpr( "active_moon", function ()
    return "new_moon"
end )

local ExitEclipse = setfenv( function()
    eclipse.state = "IN_NONE"
    eclipse.reset_stacks()
    if talent.dreamstate.enabled then applyBuff( "dreamstate", nil, 2 ) end
    if Hekili.ActiveDebug then Hekili:Debug( "Expire Eclipse: %s - Starfire(%d), Wrath(%d), Solar(%.2f), Lunar(%.2f)", eclipse.state, eclipse.starfire_counter, eclipse.wrath_counter, buff.eclipse_solar.remains, buff.eclipse_lunar.remains ) end
end, state )

spec:RegisterStateTable( "eclipse", setmetatable( {
    -- IN_SOLAR, IN_LUNAR, IN_BOTH, IN_NONE
    state = "IN_NONE",
    wrath_counter = 2,
    starfire_counter = state.talent.lunar_calling.enabled and 0 or 2, -- With the talent, the starfire counter API call is hard-set to return 0 and cannot be changed

    reset = setfenv( function()
        -- Refresh/sync current gamestate during reset_precast
        eclipse.starfire_counter = GetSpellCastCount( 197628 ) or 0
        eclipse.wrath_counter    = GetSpellCastCount(   5176 ) or 0

        if buff.eclipse_solar.up and buff.eclipse_lunar.up then
            eclipse.state = "IN_BOTH"
            state:QueueAuraExpiration( "ca_inc", ExitEclipse, buff.ca_inc.expires )
        elseif buff.eclipse_solar.up then
            eclipse.state = "IN_SOLAR"
            state:QueueAuraExpiration( "eclipse_solar", ExitEclipse, buff.eclipse_solar.expires )
        elseif buff.eclipse_lunar.up then
            eclipse.state = "IN_LUNAR"
            state:QueueAuraExpiration( "eclipse_lunar", ExitEclipse, buff.eclipse_lunar.expires )
        else
            eclipse.state = "IN_NONE"
        end
    end, state ),

    reset_stacks = setfenv( function()
        -- Fresh out of any eclipse
        eclipse.wrath_counter = 2
        eclipse.starfire_counter = talent.lunar_calling.enabled and 0 or 2
    end, state ),

    trigger_eclipse = setfenv( function( eclipseType, duration )
        -- Both are forcibly set to 0 in-game when you enter any eclipse (or both)
        eclipse.wrath_counter = 0
        eclipse.starfire_counter = 0
        -- Clear out any old aura queues and overwrite them down below. This might matter as eclipses do not currently extend, they overwrite with a fresh copy
        state:RemoveAuraExpiration( "eclipse_lunar" )
        state:RemoveAuraExpiration( "eclipse_solar" )
        state:RemoveAuraExpiration( "ca_inc" )
        local partingSkies = 1
        -- These interactions, it matters which type of eclipse
        if eclipseType == "both" then
            eclipse.state = "IN_BOTH"
            applyBuff( "eclipse_solar", duration )
            applyBuff( "eclipse_lunar", duration )
            state:QueueAuraExpiration( "ca_inc", ExitEclipse, buff.ca_inc.expires )
            if talent.balance_of_all_things.enabled then
                applyBuff( "balance_of_all_things_nature" )
                applyBuff( "balance_of_all_things_arcane" )
            end
            partingSkies = 2 -- overwrite to 2 if its a double eclipse
        elseif eclipseType == "lunar" then
            eclipse.state = "IN_LUNAR"
            applyBuff( "eclipse_lunar", duration )
            state:QueueAuraExpiration( "eclipse_lunar", ExitEclipse, buff.eclipse_lunar.expires )
            if talent.balance_of_all_things.enabled then applyBuff( "balance_of_all_things_arcane" ) end
        else
            eclipse.state = "IN_SOLAR"
            applyBuff( "eclipse_solar", duration )
            state:QueueAuraExpiration( "eclipse_solar", ExitEclipse, buff.eclipse_solar.expires )
            if talent.balance_of_all_things.enabled then applyBuff( "balance_of_all_things_nature" ) end
        end

        -- There interactions happen regardless of eclipse type
        if talent.astral_communion.enabled then applyBuff( "astral_communion" ) end
        if talent.solstice.enabled then applyBuff( "solstice" ) end
        if talent.cenarius_might.enabled then applyBuff( "cenarius_might" ) end
        if talent.parting_skies.enabled then
            if partingSkies == 2 then -- Trigger spell. If buff is up, refresh it
                applyDebuff( "target", "fury_of_elune", 8 )
                applyBuff( "fury_of_elune_ap", 8 )
                if buff.parting_skies.up then
                    buff.parting_skies.remains = spec.auras.parting_skies.duration
                end
            else
                if buff.parting_skies.up then
                    removeBuff( "parting_skies" )
                    applyDebuff( "target", "fury_of_elune", 8 )
                    applyBuff( "fury_of_elune_ap", 8 )
                else applyBuff( "parting_skies" )
                end
            end
        end
        -- Legacy
        if set_bonus.tier29_4pc > 0 then applyBuff( "touch_the_cosmos" ) end

    end, state ),

    advance = setfenv( function( spell )

        if spell == "wrath" then
            eclipse.wrath_counter = eclipse.wrath_counter - 1
            if eclipse.wrath_counter == 0 then eclipse.trigger_eclipse( "lunar", 15 ) end
        elseif spell == "starfire" then
            eclipse.starfire_counter = eclipse.starfire_counter - 1
            if eclipse.starfire_counter == 0 then eclipse.trigger_eclipse( "solar", 15 ) end
        end

    end, state ),

}, {
    __index = function( t, k )
        -- any_next
        if k == "any_next" then
            return eclipse.state == "IN_NONE"
        -- in_any
        elseif k == "in_any" or k == "in_eclipse" then
            return eclipse.state ~= "IN_NONE"
        elseif k == "in_none" then
            return eclipse.state == "IN_NONE"
        -- in_solar
        elseif k == "in_solar" then
            return eclipse.state == "IN_SOLAR"
        -- in_lunar
        elseif k == "in_lunar" then
            return eclipse.state == "IN_LUNAR"
        -- in_both
        elseif k == "in_both" then
            return eclipse.state == "IN_BOTH"
        -- solar_in
        elseif k == "solar_in" then
            return eclipse.starfire_counter
        -- solar_in_2
        elseif k == "solar_in_2" then
            return eclipse.starfire_counter == 2
        -- solar_in_1
        elseif k == "solar_in_1" then
            return eclipse.starfire_counter == 1
        -- lunar_in
        elseif k == "lunar_in" then
            return eclipse.wrath_counter
        -- lunar_in_2
        elseif k == "lunar_in_2" then
            return eclipse.wrath_counter == 2
        -- lunar_in_1
        elseif k == "lunar_in_1" then
            return eclipse.wrath_counter == 1
        elseif k == "remains" then
            return eclipse.state == "IN_NONE" and 0 or max( buff.eclipse_solar.remains, buff.eclipse_lunar.remains )
        end
    end
} ) )

spec:RegisterStateTable( "druid", setmetatable( {},{
    __index = function( t, k )
        if k == "catweave_bear" then return false
        elseif k == "owlweave_bear" then return false
        elseif k == "primal_wrath" then return debuff.rip
        elseif k == "lunar_inspiration" then return debuff.moonfire_cat
        elseif k == "no_cds" then return not toggle.cooldowns
        elseif k == "delay_berserking" then return settings.delay_berserking
        elseif rawget( debuff, k ) ~= nil then return debuff[ k ] end
        return false
    end
} ) )

local LycarasHandler = setfenv( function ()
    if buff.travel_form.up then state:RunHandler( "stampeding_roar" )
    elseif buff.moonkin_form.up then state:RunHandler( "starfall" )
    elseif buff.bear_form.up then state:RunHandler( "barkskin" )
    elseif buff.cat_form.up then state:RunHandler( "primal_wrath" )
    else state:RunHandler( "wild_growth" ) end
end, state )

local SinfulHysteriaHandler = setfenv( function ()
    applyBuff( "ravenous_frenzy_sinful_hysteria" )
end, state )

spec:RegisterPet( "treants",
    103822,
    "force_of_nature",
    10,
    103822 )

spec:RegisterTotem( "treants", 103822 )

local TreantMoonfires = setfenv( function()
    for i = 1, 3 do -- # of treants
        spec.abilities.moonfire.handler()
    end
end, state )


spec:RegisterHook( "reset_precast", function ()
    if IsActiveSpell( class.abilities.new_moon.id ) then active_moon = "new_moon"
    elseif IsActiveSpell( class.abilities.half_moon.id ) then active_moon = "half_moon"
    elseif IsActiveSpell( class.abilities.full_moon.id ) then active_moon = "full_moon"
    else active_moon = nil end

    -- UGLY
    if talent.incarnation.enabled then
        rawset( cooldown, "ca_inc", cooldown.incarnation )
        rawset( buff, "ca_inc", buff.incarnation )
    else
        rawset( cooldown, "ca_inc", cooldown.celestial_alignment )
        rawset( buff, "ca_inc", buff.celestial_alignment )
    end

    --[[ Needs more work
    if pet.treants.up then
        local tick, expires = action.force_of_nature.lastCast, pet.treants.expires
		local tick2 = tick + 6
		tick = tick + 2
            if tick > query_time and tick < expires then
                state:QueueAuraEvent( "treant_moonfires", TreantMoonfires, tick, "AURA_TICK" )
            end
        end
    end
    --]]

    if talent.fungal_growth.enabled and query_time - action.wild_mushroom.lastCast < 1 then
        if debuff.fungal_growth.up then debuff.fungal_growth.expires = action.wild_mushroom.lastCast + 7
        else applyDebuff( "target", "wild_growth", 7 ) end
    end

    if buff.warrior_of_elune.up then
        setCooldown( "warrior_of_elune", 3600 )
    end

    eclipse.reset() -- sync all eclipse components with gamestate

    --[[ if buff.lycaras_fleeting_glimpse.up then
        state:QueueAuraExpiration( "lycaras_fleeting_glimpse", LycarasHandler, buff.lycaras_fleeting_glimpse.expires )
    end ]]

    if legendary.sinful_hysteria.enabled and buff.ravenous_frenzy.up then
        state:QueueAuraExpiration( "ravenous_frenzy", SinfulHysteriaHandler, buff.ravenous_frenzy.expires )
    end
end )

spec:RegisterHook( "step", function()
    if Hekili.ActiveDebug then Hekili:Debug( "Eclipse State: %s, Wrath: %d, Starfire: %d; Lunar: %.2f, Solar: %.2f\n", eclipse.state or "NOT SET", eclipse.wrath_counter, eclipse.starfire_counter, buff.eclipse_lunar.remains, buff.eclipse_solar.remains ) end
end )

spec:RegisterHook( "spend", function( amt, resource )
    if legendary.primordial_arcanic_pulsar.enabled and resource == "astral_power" and amt > 0 then
        local v1 = ( buff.primordial_arcanic_pulsar.v1 or 0 ) + amt

        if v1 >= 300 then
            applyBuff( talent.incarnation.enabled and "incarnation" or "celestial_alignment", 9 )
            v1 = v1 - 300
        end

        if v1 > 0 then
            applyBuff( "primordial_arcanic_pulsar", nil, max( 1, floor( amt / 30 ) ) )
            buff.primordial_arcanic_pulsar.v1 = v1
        else
            removeBuff( "primordial_arcanic_pulsar" )
        end
    end
end )

-- Abilities
spec:RegisterAbilities( {

    rebirth ={
        id = 20484,
        charges = 5,
        recharge = 600,
        cast = 1.5,
        target = "mouseover",
        cooldown = 600,
        gcd = "spell",
        spend = 30,
        spendType = "rage",
        usable = function ()
            return Hekili:isMouseOverMemberDead() and Hekili.resurrectionCount(20484) >= 1
        end,

        handler = function ()
        end
    },

    barkskin = {
        id = 22812,
        cast = 0,
        cooldown = function () return 60 * ( 1 - 0.15 * talent.survival_of_the_fittest.rank ) * ( 1 + ( conduit.tough_as_bark.mod * 0.01 ) ) end,
        gcd = "off",
        school = "nature",

        startsCombat = false,

        toggle = "defensives",
        defensive = true,

        handler = function ()
            applyBuff( "barkskin" )

            if legendary.the_natural_orders_will.enabled and buff.bear_form.up then
                applyBuff( "ironfur" )
                applyBuff( "frenzied_regeneration" )
            end

            if talent.matted_fur.enabled then applyBuff( "matted_fur" ) end
        end
    },

    -- Shapeshift into Bear Form, increasing armor by $m4% and Stamina by $1178s2%, granting protection from Polymorph effects, and increasing threat generation.    The act of shapeshifting frees you from movement impairing effects.
    bear_form = {
        id = 5487,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        spend = -25,
        spendType = "rage",

        startsCombat = false,

        essential = true,
        noform = "bear_form",

        handler = function ()
            shift( "bear_form" )
            if talent.ursine_vigor.enabled or conduit.ursine_vigor.enabled then applyBuff( "ursine_vigor" ) end
        end,
    },

    -- Go Berserk for $d. While Berserk:; Generate $343216s1 combo $lpoint:points; every $t1 sec. Combo point generating abilities generate $s2 additional combo $lpoint:points;. Finishing moves restore up to $405189u combo points generated over the cap.; All attack and ability damage is increased by $s3%.
    berserk = {
        id = 106951,
        cast = 0.0,
        cooldown = 180.0,
        gcd = "off",

        startsCombat = false,

        handler = function()
            applyBuff( "berserk" )
        end
    },

    -- Shapeshift into Cat Form, increasing auto-attack damage by $s4%, movement speed by $113636s1%, granting protection from Polymorph effects, and reducing falling damage.    The act of shapeshifting frees you from movement impairing effects.
    cat_form = {
        id = 768,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        noform = "cat_form",

        handler = function ()
            shift( "cat_form" )
            if pvptalent.master_shapeshifter.enabled and talent.feral_affinity.enabled then
                applyBuff( "master_shapeshifter_feral" )
            end
        end,
    },

    -- Talent: Celestial bodies align, maintaining both Eclipses and granting $s1% haste for $d.
    -- TODO: Revisit if Orbital Strike needs its own button.
    celestial_alignment = {
        id = function() return talent.orbital_strike.enabled and 383410 or 194223 end,
        cast = 0,
        charges = function () if talent.whirling_stars.enabled then return 2 end end,
        cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * ( talent.whirling_stars.enabled and ( talent.potent_enchantmeents.enabled and 90 or 100 ) or 180 ) - 60 * talent.orbital_strike.rank end,
        recharge = function () if talent.whirling_stars.enabled then return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * 100 - 60 * talent.orbital_strike.rank end end,
        gcd = "off",
        school = "astral",

        talent = "celestial_alignment",
        notalent = "incarnation",
        startsCombat = true,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "celestial_alignment" )
            if set_bonus.tww2 >= 2 then summonTotem( "wild_mushroom" ) end
            stat.haste = stat.haste + 0.1

            eclipse.trigger_eclipse( "both", 15 ) --self

            if pvptalent.moon_and_stars.enabled then applyBuff( "moon_and_stars" ) end
        end,

        copy = { 194223, 383410, "ca_inc" }
    },

    -- Talent / Covenant (Night_Fae): Call upon the Night Fae for an eruption of energy, channeling a rapid flurry of $s2 Druid spells and abilities over $d.    You will cast $?a24858|a197625[Starsurge, Starfall,]?a768[Ferocious Bite, Shred, Tiger's Fury,]?a5487[Mangle, Ironfur,][Wild Growth, Swiftmend,] Moonfire, Wrath, Regrowth, Rejuvenation, Rake, and Thrash on appropriate nearby targets, favoring your current shapeshift form.
    convoke_the_spirits = {
        id = function() return talent.convoke_the_spirits.enabled and 391528 or 323764 end,
        cast = function() return 4 * ( legendary.celestial_spirits.enabled and 0.75 or 1 ) * ( talent.ashamanes_guidance.enabled and 0.75 or 1 ) end,
        channeled = true,
        cooldown = function() return 120 * ( legendary.celestial_spirits.enabled and 0.5 or 1 ) * ( talent.ashamanes_guidance.enabled and 0.5 or 1 ) end,
        gcd = "spell",
        school = "nature",

        talent = function()
            if covenant.night_fae then return end
            return "convoke_the_spirits"
        end,
        startsCombat = true,

        toggle = "cooldowns",

        disabled = function ()
            return not talent.convoke_the_spirits.enabled and covenant.night_fae and not IsSpellKnownOrOverridesKnown( 323764 ), "you have not finished your night_fae covenant intro"
        end,

        finish = function ()
            -- Can we safely assume anything is going to happen?
            if state.spec.feral then
                applyBuff( "tigers_fury" )
                if target.maxR < 8 then
                    gain( 5, "combo_points" )
                end
            elseif state.spec.guardian then
            elseif state.spec.balance then
            end
        end,

        copy = { 391528, 323764 }
    },

    -- Talent: Tosses the enemy target into the air, disorienting them but making them invulnerable for up to $d. Only one target can be affected by your Cyclone at a time.
    cyclone = {
        id = 33786,
        cast = function() return 1.7 * ( buff.heart_of_the_wild.up and 0.7 or 1 ) * haste end,
        cooldown = 0,
        gcd = "spell",
        school = "nature",

        spend = 0.1,
        spendType = "mana",

        talent = "cyclone",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "cyclone" )
        end,
    },

    -- Shift into Cat Form and increase your movement speed by $s1% while in Cat Form for $d.
    dash = {
        id = 1850,
        cast = 0,
        cooldown = 120,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            if buff.cat_form.down then shift( "cat_form" ) end
            applyBuff( "dash" )
        end,
    },

    -- Roots the target in place for $d. Damage may cancel the effect.$?s33891[    |C0033AA11Tree of Life: Instant cast.|R][]
    entangling_roots = {
        id = 339,
        cast = function () return pvptalent.owlkin_adept.enabled and buff.owlkin_frenzy.up and 0.85 or 1.7 * haste end,
        cooldown = 0,
        gcd = "spell",

        spend = 0.06,
        spendType = "mana",

        startsCombat = true,
        texture = 136100,

        handler = function ()
            applyDebuff( "target", "entangling_roots" )
            removeBuff( "natures_swiftness" )
        end,
    },

    faerie_swarm = {
        id = 209749,
        cast = 0.0,
        cooldown = 30.0,
        gcd = "spell",

        startsCombat = true,
        pvptalent = "faerie_swarm",

        handler = function()
            applyDebuff( "target", "faerie_swarm" )
        end,
    },

    -- Talent: Summons a stand of $s1 Treants for $248280d which immediately taunt and attack enemies in the targeted area.    |cFFFFFFFFGenerates ${$m5/10} Astral Power.|r
    force_of_nature = {
        id = 205636,
        cast = 0,
        cooldown = function() return talent.early_spring.enabled and 45 or 60 end,
        gcd = "spell",
        school = "nature",
        spend = -20,
        spendType = "astral_power",

        talent = "force_of_nature",
        startsCombat = true,

        toggle = "cooldowns",
        ap_check = function() return check_for_ap_overcap( "force_of_nature" ) end,

        handler = function ()
            summonPet( "treants", 10 )
            if talent.harmony_of_the_grove.enabled then applyBuff( "harmony_of_the_grove" ) end
            if talent.dream_surge.enabled then applyBuff( "dream_burst") end
            -- queue aura ticks +2, +8 3 moonfires, actually triggers the handler
            state:QueueAuraEvent( "treant_moonfires", TreantMoonfires, query_time + 2, "AURA_TICK" )
            state:QueueAuraEvent( "treant_moonfires", TreantMoonfires, query_time + 8, "AURA_TICK" )
        end,
    },


    full_moon = {
        id = 274283,
        known = 274281,
        flash = 274281,
        cast = 3,
        charges = 3,
        cooldown = 20,
        recharge = 20,
        gcd = "spell",

        spend = -48,
        spendType = "astral_power",

        texture = 1392542,
        startsCombat = true,

        talent = "new_moon",
        bind = "half_moon",

        ap_check = function() return check_for_ap_overcap( "full_moon" ) end,
        energize_amount = function() return action.full_moon.spend * -1 end,

        usable = function () return active_moon == "full_moon" end,
        handler = function ()
            spendCharges( "new_moon", 1 )
            spendCharges( "half_moon", 1 )

            if talent.radiant_moonlight.disabled or ( action.half_moon.lastCast < action.full_moon.lastCast ) then
                active_moon = "new_moon"
            end

        end,
    },

    -- [428655] Moonfire damage has a chance to call down a Fury of Elune to follow your target for ${$s2/1000} sec.; $@spellicon202770 $@spellname202770; Calls down a beam of pure celestial energy, dealing $<dmg> Astral damage over ${$s2/1000} sec within its area.; Generates $?a137010[${$202770m4/$202770t4*$s2/10000} Rage][${$202770m3/$202770t3*$s2/10000} Astral Power] over its duration.
    fury_of_elune = {
        id = 202770,
        cast = 0,
        cooldown = function() return talent.radiant_moonlight.enabled and 45 or 60 end,
        gcd = "spell",

        -- toggle = "cooldowns",

        startsCombat = true,
        texture = 132123,

        handler = function ()
            if not buff.moonkin_form.up then unshift() end
            applyDebuff( "target", "fury_of_elune_ap" )
        end,
    },

    -- Taunts the target to attack you.
    growl = {
        id = 6795,
        cast = 0,
        cooldown = 8,
        gcd = "off",
        school = "physical",

        startsCombat = true,

        handler = function ()
            applyBuff( "growl" )
        end,
    },

    half_moon = {
        id = 274282,
        known = 274281,
        flash = 274281,
        cast = 2,
        charges = 3,
        cooldown = 20,
        recharge = 20,
        gcd = "spell",

        spend = -20,
        spendType = "astral_power",

        texture = 1392543,
        startsCombat = true,

        talent = "new_moon",
        bind = { "new_moon", "full_moon" },

        ap_check = function() return check_for_ap_overcap( "half_moon" ) end,

        usable = function () return active_moon == "half_moon" end,
        handler = function ()
            spendCharges( "new_moon", 1 )
            spendCharges( "full_moon", 1 )

            active_moon = "full_moon"
        end,
    },

    -- Talent: Abilities not associated with your specialization are substantially empowered for $d.$?!s137013[    |cFFFFFFFFBalance:|r Magical damage increased by $s1%.][]$?!s137011[    |cFFFFFFFFFeral:|r Physical damage increased by $s4%.][]$?!s137010[    |cFFFFFFFFGuardian:|r Bear Form gives an additional $s7% Stamina, multiple uses of Ironfur may overlap, and Frenzied Regeneration has ${$s9+1} charges.][]$?!s137012[    |cFFFFFFFFRestoration:|r Healing increased by $s10%, and mana costs reduced by $s12%.][]
    heart_of_the_wild = {
        id = 319454,
        cast = 0,
        cooldown = function () return 300 * ( 1 - ( conduit.born_of_the_wilds.mod * 0.01 ) ) end,
        gcd = "spell",

        toggle = "cooldowns",
        talent = "heart_of_the_wild",

        startsCombat = true,
        texture = 135879,

        handler = function ()
            applyBuff( "heart_of_the_wild" )

            if talent.feral_affinity.enabled then
                shift( "cat_form" )
            elseif talent.guardian_affinity.enabled then
                shift( "bear_form" )
            elseif talent.restoration_affinity.enabled then
                unshift()
            end
        end,
    },

    -- Talent: Forces the enemy target to sleep for up to $d.  Any damage will awaken the target.  Only one target can be forced to hibernate at a time.  Only works on Beasts and Dragonkin.
    hibernate = {
        id = 2637,
        cast = function() return 1.5 * ( buff.heart_of_the_wild.up and 0.7 or 1 ) * haste end,
        cooldown = 0,
        gcd = "spell",
        school = "nature",

        spend = 0.06,
        spendType = "mana",

        talent = "hibernate",
        startsCombat = false,

        handler = function ()
            applyDebuff( "target", "hibernate" )
        end,
    },

    -- Talent: Shift into Bear Form and invoke the spirit of Ursol to let loose a deafening roar, incapacitating all enemies within $A1 yards for $d. Damage will cancel the effect.
    incapacitating_roar = {
        id = 99,
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "physical",

        talent = "incapacitating_roar",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "incapacitating_roar" )
        end,
    },

    -- An improved Moonkin Form that grants both Eclipses, any learned Celestial Alignment bonuses, $?a429536[$s6% increased Arcane damage, ][]and $s2% critical strike chance.; Lasts $d. You may shapeshift in and out of this improved Moonkin Form for its duration.
    incarnation = {
        id = function() return talent.orbital_strike.enabled and 390414 or 102560 end,
        charges = function () if talent.whirling_stars.enabled then return 2 end end, --self
        cast = 0,
        cooldown = function () return ( essence.vision_of_perfection.enabled and 0.85 or 1 ) * ( talent.whirling_stars.enabled and ( talent.potent_enchantmeents.enabled and 90 or 100 ) or 180 ) - 60 * talent.orbital_strike.rank end,
        gcd = "off",

        spend = -40,
        spendType = "astral_power",

        toggle = "cooldowns",

        startsCombat = true,
        texture = 571586,

        talent = "incarnation",

        handler = function ()
            shift( "moonkin_form" )
            if set_bonus.tww2 >= 2 then summonTotem( "wild_mushroom" ) end

            applyBuff( "incarnation" )
            stat.crit = stat.crit + 0.10
            stat.haste = stat.haste + 0.10

            eclipse.trigger_eclipse( "both", 15 ) --self

            if pvptalent.moon_and_stars.enabled then applyBuff( "moon_and_stars" ) end
        end,

        copy = { "incarnation_chosen_of_elune", "Incarnation", 102560, 390414 },
    },

    -- Talent: Infuse a friendly healer with energy, allowing them to cast spells without spending mana for $d.$?s326228[    If cast on somebody else, you gain the effect at $326228s1% effectiveness.][]
    innervate = {
        id = 29166,
        cast = 0,
        cooldown = 180,
        gcd = "off",
        school = "nature",

        talent = "innervate",
        startsCombat = true,
        texture = 136048,

        toggle = "cooldowns",

        usable = function () return group end,
        handler = function ()
            active_dot.innervate = 1
        end,
    },

    -- Talent: Increases armor by ${$s1*$AGI/100} for $d.$?a231070[ Multiple uses of this ability may overlap.][]
    ironfur = {
        id = 192081,
        cast = 0,
        cooldown = 0.5,
        gcd = "off",
        school = "nature",

        spend = 40,
        spendType = "rage",

        talent = "ironfur",
        startsCombat = false,

        handler = function ()
            applyBuff( "ironfur" )
        end,
    },

    -- Talent: Finishing move that causes Physical damage and stuns the target. Damage and duration increased per combo point:       1 point  : ${$s2*1} damage, 1 sec     2 points: ${$s2*2} damage, 2 sec     3 points: ${$s2*3} damage, 3 sec     4 points: ${$s2*4} damage, 4 sec     5 points: ${$s2*5} damage, 5 sec
    maim = {
        id = 22570,
        cast = 0,
        cooldown = 30,
        gcd = "totem",
        school = "physical",

        spend = 30,
        spendType = "energy",

        talent = "maim",
        startsCombat = true,

        usable = function () return combo_points.current > 0, "requires combo points" end,
        handler = function ()
            applyDebuff( "target", "maim" )
            spend( combo_points.current, "combo_points" )
        end,
    },

    -- Mangle the target for $s2 Physical damage.$?a231064[ Deals $s3% additional damage against bleeding targets.][]    |cFFFFFFFFGenerates ${$m4/10} Rage.|r
    mangle = {
        id = 33917,
        cast = 0,
        cooldown = 6,
        gcd = "spell",
        school = "physical",

        spend = -10,
        spendType = "rage",

        startsCombat = true,
        texture = 132135,

        form = function()
            if talent.fluid_form.enabled then return end
            return "bear_form"
        end,

        handler = function ()
        end,
    },

    -- Infuse a friendly target with the power of the wild, increasing their Versatility by $s1% for 60 minutes.    If target is in your party or raid, all party and raid members will be affected.
    mark_of_the_wild = {
        id = 1126,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "nature",
        essential = true,

        spend = 0.01,
        spendType = "mana",

        startsCombat = false,
        nobuff = "mark_of_the_wild",

        handler = function ()
            applyBuff( "mark_of_the_wild" )
        end,
    },

    -- Talent: Roots the target and all enemies within $A1 yards in place for $d. Damage may interrupt the effect. Usable in all shapeshift forms.
    mass_entanglement = {
        id = 102359,
        cast = 0,
        cooldown = function () return 30 * ( 1 - ( conduit.born_of_the_wilds.mod * 0.01 ) ) end,
        gcd = "spell",
        school = "nature",

        talent = "mass_entanglement",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "mass_entanglement" )
            active_dot.mass_entanglement = max( active_dot.mass_entanglement, active_enemies )
        end,
    },

    -- Talent: Invokes the spirit of Ursoc to stun the target for $d. Usable in all shapeshift forms.
    mighty_bash = {
        id = 5211,
        cast = 0,
        cooldown = function () return 60 * ( 1 - ( conduit.born_of_the_wilds.mod * 0.01 ) ) end,
        gcd = "spell",
        school = "physical",

        talent = "mighty_bash",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "mighty_bash" )
        end,
    },

    -- A quick beam of lunar light burns the enemy for $164812s1 Arcane damage and then an additional $164812o2 Arcane damage over $164812d$?s238049[, and causes enemies to deal $238049s1% less damage to you.][.]$?a372567[    Hits a second target within $279620s1 yds of the first.][]$?s197911[    |cFFFFFFFFGenerates ${$m3/10} Astral Power.|r][]
    moonfire = {
        id = 8921,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "arcane",

        spend = function () return talent.moon_guardian.enabled and -8 or -6 end,
        spendType = "astral_power",

        readyTime = function () if state.spec.balance and talent.treants_of_the_moon.enabled then return pet.treants.remains end end,

        startsCombat = true,

        cycle = "moonfire",

        ap_check = function() return check_for_ap_overcap( "moonfire" ) end,
        energize_amount = function() return action.moonfire.spend * -1 end,

        handler = function ()
            if not buff.moonkin_form.up and not buff.bear_form.up then unshift() end
            applyDebuff( "target", "moonfire" )

            if talent.twin_moons.enabled and active_enemies > 1 then
                active_dot.moonfire = min( active_enemies, active_dot.moonfire + 1 )
            end
        end,
    },

    -- Talent: Shapeshift into $?s114301[Astral Form][Moonkin Form], increasing the damage of your spells by $s9% and your armor by $m3%, and granting protection from Polymorph effects.$?a231042[    While in this form, single-target attacks against you have a $h% chance to make your next Starfire instant.][]    The act of shapeshifting frees you from movement impairing effects.
    moonkin_form = {
        id = function() return state.spec.restoration and 197625 or 24858 end,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        noform = "moonkin_form",
        essential = true,

        handler = function ()
            shift( "moonkin_form" )
        end,

        copy = { 24858, 197625 }
    },

    -- Talent: For $d, $?s137012[all single-target healing also damages a nearby enemy target for $s3% of the healing done][all single-target damage also heals a nearby friendly target for $s3% of the damage done].
    natures_vigil = {
        id = 124974,
        cast = 0,
        cooldown = 90,
        gcd = "off",
        school = "nature",

        talent = "natures_vigil",
        startsCombat = false,

        toggle = "defensives",
        usable = function()
            local hp = health.percent or 100
            local vd = settings.vigil_damage or 50
            return hp <= vd, strformat( "health %d%% must be under %d%%", hp, vd )
        end,

        handler = function ()
            applyBuff( "natures_vigil" )
        end,
    },

    -- Talent: Deals $m1 Astral damage to the target and empowers New Moon to become Half Moon.     |cFFFFFFFFGenerates ${$m3/10} Astral Power.|r
    new_moon = {
        id = 274281,
        cast = 1,
        charges = 3,
        cooldown = 20,
        recharge = 20,
        gcd = "totem",
        school = "astral",

        spend = -10,
        spendType = "astral_power",

        talent = "new_moon",
        startsCombat = true,
        bind = { "half_moon", "full_moon" },

        ap_check = function() return check_for_ap_overcap( "new_moon" ) end,

        usable = function () return active_moon == "new_moon" end,
        handler = function ()
            spendCharges( "half_moon", 1 )
            spendCharges( "full_moon", 1 )

            active_moon = "half_moon"
        end,
    },

    -- Shift into Cat Form and enter stealth.
    prowl = {
        id = 5215,
        cast = 0,
        cooldown = 6,
        gcd = "off",
        school = "physical",

        startsCombat = false,

        usable = function ()
            if time > 0 and ( not boss or not buff.shadowmeld.up ) then return false, "cannot stealth in combat"
            elseif buff.prowl.up then return false, "player is already prowling" end
            return true
        end,

        handler = function ()
            shift( "cat_form" )
            applyBuff( "prowl" )
        end,

        copy = 102547
    },


    -- Heals a friendly target for $s1 and another ${$o2*$<mult>} over $d.$?s231032[ Initial heal has a $231032s1% increased chance for a critical effect if the target is already affected by Regrowth.][]$?s24858|s197625[ Usable while in Moonkin Form.][]$?s33891[    |C0033AA11Tree of Life: Instant cast.|R][]
    regrowth = {
        id = 8936,
        cast = function() return buff.blooming_infusion_regrowth.up and 0 or 1.5 * haste end,
        cooldown = 0,
        gcd = "spell",
        school = "nature",

        spend = function() return 0.10 * ( 1 - 0.08 * buff.abundance.stack ) end,
        spendType = "mana",

        startsCombat = false,

        handler = function ()
            if buff.moonkin_form.down then unshift() end
            applyBuff( "regrowth" )
            if talent.forestwalk.enabled then applyBuff( "forestwalk" ) end
        end,
    },

    -- Talent: Heals the target for $o1 over $d.$?s155675[    You can apply Rejuvenation twice to the same target.][]$?s33891[    |C0033AA11Tree of Life: Healing increased by $5420s5% and Mana cost reduced by $5420s4%.|R][]
    rejuvenation = {
        id = 774,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "nature",

        spend = 0.05,
        spendType = "mana",

        talent = "rejuvenation",
        startsCombat = false,

        handler = function ()
            if buff.moonkin_form.down then unshift() end
            applyBuff( "rejuvenation" )
        end,
    },

    -- Talent: Nullifies corrupting effects on the friendly target, removing all Curse and Poison effects.
    remove_corruption = {
        id = 2782,
        cast = 0,
        cooldown = 8,
        gcd = "spell",
        school = "arcane",
        toggle = "defensives",
        spend = 0.10,
        spendType = "mana",
        indicator = function ()
             return debuff.dispellable_poison.caster or debuff.dispellable_curse.caster
        end,
        talent = "remove_corruption",
        startsCombat = false,

        usable = function ()
            return debuff.dispellable_curse.up or debuff.dispellable_poison.up, "requires dispellable curse or poison"
        end,

        handler = function ()
            removeDebuff( "player", "dispellable_curse" )
            removeDebuff( "player", "dispellable_poison" )
        end,
    },

    -- Talent: Instantly heals you for $s1% of maximum health. Usable in all shapeshift forms.
    renewal = {
        id = 108238,
        cast = 0,
        cooldown = 90,
        gcd = "off",
        school = "nature",

        talent = "renewal",
        startsCombat = false,

        toggle = "defensives",

        handler = function ()
            gain( health.max * 0.2, "health" )
        end,
    },

    -- Talent: You charge and bash the target's skull, interrupting spellcasting and preventing any spell in that school from being cast for $93985d.
    skull_bash = {
        id = 106839,
        cast = 0,
        cooldown = 15,
        gcd = "off",
        school = "physical",

        talent = "skull_bash",
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
        end,
    },

    -- Talent: Summons a beam of solar light over an enemy target's location, interrupting the target and silencing all enemies within the beam.  Lasts $d.
    solar_beam = {
        id = 78675,
        cast = 0,
        cooldown = 60,
        gcd = "off",
        school = "nature",

        spend = 0.168,
        spendType = "mana",

        talent = "solar_beam",
        startsCombat = true,

        toggle = "interrupts",

        debuff = "casting",
        readyTime = state.timeToInterrupt,

        handler = function ()
            interrupt()
            -- trigger 97547, 97547, 97547
            applyBuff( "solar_beam" )
        end,
    },

    -- Talent: Soothes the target, dispelling all enrage effects.
    soothe = {
        id = 2908,
        cast = 0,
        cooldown = 10,
        gcd = "spell",
        school = "nature",
        toggle = "defensives",
        spend = 0.056,
        spendType = "mana",

        talent = "soothe",
        startsCombat = true,

        usable = function () return buff.dispellable_enrage.up end,
        handler = function ()
            if buff.moonkin_form.down then unshift() end
            removeBuff( "dispellable_enrage" )
        end,
    },


    stag_form = {
        id = 210053,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 1394966,

        noform = "travel_form",
        handler = function ()
            shift( "stag_form" )
        end,
    },

    -- Talent: Let loose a wild roar, increasing the movement speed of all friendly players within $A1 yards by $s1% for $d.
    stampeding_roar = {
        id = 106898,
        cast = 0,
        cooldown = function () return 120 - ( talent.improved_stampeding_roar.enabled and 60 or 0 ) end,
        gcd = "spell",
        school = "physical",

        talent = "stampeding_roar",
        startsCombat = false,

        toggle = "interrupts",

        handler = function ()
            applyBuff( "stampeding_roar" )
            if buff.bear_form.down and buff.cat_form.down then
                shift( "bear_form" )
            end
        end,

        copy = { 77761, 77764 }
    },

    -- Talent: Calls down waves of falling stars upon enemies within $50286A1 yds, dealing $<damage> Astral damage over $191034d. Multiple uses of this ability may overlap.$?s327541[    Extends the duration of active Moonfires and Sunfires by $327541s1 sec.][]
    starfall = {
        id = 191034,
        cast = 0,
        cooldown = function () return talent.stellar_drift.enabled and 12 or 0 end,
        gcd = "spell",
        school = "astral",

        spend = function ()
            if buff.oneths_perception.up or buff.starweavers_warp.up or buff.touch_the_cosmos.up then return 0 end
            return ( 50 - ( buff.incarnation.up and talent.elunes_guidance.enabled and 10 or 0 ) - ( buff.touch_the_cosmos.up and 5 or 0 ) - ( buff.astral_communion.up and 15 or 0 ) ) * ( 1 - 0.05 * buff.rattled_stars.stack ) * ( 1 - 0.1 * buff.timeworn_dreambinder.stack )
        end,
        spendType = "astral_power",

        startsCombat = true,
        texture = 236168,

        ap_check = function() return check_for_ap_overcap( "starfall" ) end,

        handler = function ()
            if talent.hail_of_stars.enabled and ( buff.oneths_perception.up or buff.starweavers_warp.up or buff.touch_the_cosmos.up ) then
                applyBuff( "solstice", 3 )
            end

            if buff.starweavers_warp.up then removeBuff( "starweavers_warp" )
            else removeBuff( "touch_the_cosmos" ) end

            if talent.rattle_the_stars.enabled then addStack( "rattled_stars" ) end
            if talent.starlord.enabled then
                if buff.starlord.stack < 3 then stat.haste = stat.haste + 0.04 end
                addStack( "starlord", buff.starlord.remains > 0 and buff.starlord.remains or nil, 1 )
            end

            if set_bonus.tier29_2pc > 0 then
                addStack( "gathering_starstuff" )
            end

            applyBuff( "starfall" )
            if level > 53 then
                if debuff.moonfire.up then debuff.moonfire.expires = debuff.moonfire.expires + 4 end
                if debuff.sunfire.up then debuff.sunfire.expires = debuff.sunfire.expires + 4 end
            end

            removeBuff( "oneths_perception" )

            if legendary.timeworn_dreambinder.enabled then
                addStack( "timeworn_dreambinder", nil, 1 )
            end
        end,
    },

    -- Call down a burst of energy, causing $s1 Arcane damage to the target, and $?a429523[${($m1*$m3/100)/(1+$429523s1/100)}][${$m1*$m3/100}] Arcane damage to all other enemies within $A1 yards. Deals reduced damage beyond $s5 targets.; Generates ${$m2/10} Astral Power.
    starfire = {
        id = function () return state.spec.balance and 194153 or 197628 end,
        known = function () return state.spec.balance and IsPlayerSpell( 194153 ) or IsPlayerSpell( 197628 ) end,
        cast = function ()
            if buff.blooming_infusion.up or buff.warrior_of_elune.up or buff.owlkin_frenzy.up then return 0 end
            return haste * 2.25 * ( buff.dreamstate.up and 0.6 or 1 )
        end,
        cooldown = 0,
        gcd = "spell",
        usable = function () if settings.stop_moving and moving then return false, "moving" end end,
        spend = function () return ( -8 + ( talent.wild_surges.enabled and -2 or 0 ) + ( talent.moon_guardian.enabled and -2 or 0 ) + ( set_bonus.tww1 >= 4 and -2 or 0 ) ) * ( talent.soul_of_the_forest.enabled and buff.eclipse_lunar.up and 1.2 or 1 ) * ( buff.warrior_of_elune.up and 1.3 or 1 ) end,
        spendType = "astral_power",

        startsCombat = true,
        texture = 135753,

        ap_check = function() return check_for_ap_overcap( "starfire" ) end,

        talent = "starfire",

        energize_amount = function() return action.starfire.spend * -1 end,

        handler = function ()
            if talent.fluid_form.enabled and not buff.moonkin_form.up then unshift() end

            removeBuff( "gathering_starstuff" )
            if talent.natures_grace.enabled and buff.dreamstate.up then removeStack( "dreamstate" ) end
            if talent.dream_surge.enabled and buff.dream_burst.up then removeStack( "dream_burst" ) end
            if talent.lunar_calling.disabled then eclipse.advance( "starfire" ) end

            if buff.blooming_infusion.up then
                removeBuff( "blooming_infusion" )
            elseif buff.warrior_of_elune.up then
                removeStack( "warrior_of_elune" )
                if buff.warrior_of_elune.down then
                    setCooldown( "warrior_of_elune", 45 )
                end
            elseif buff.owlkin_frenzy.up then
                removeStack( "owlkin_frenzy" )
            end

            if azerite.dawning_sun.enabled then applyBuff( "dawning_sun" ) end
        end,

        finish = function ()
            if talent.fluid_form.enabled and buff.moonkin_form.down then shift( "moonkin_form" ) end
        end,

        copy = { 194153, 197628 }
    },


    starsurge = {
        id = 78674,
        cast = 0,
        cooldown = function() return state.spec.balance and 0 or ( talent.starlight_conduit.enabled and 6 or 10 ) end,
        gcd = "spell",

        spend = function ()
            if not state.spec.balance then return ( talent.starlight_conduit.enabled and 0.003 or 0.006 ) end
            if buff.oneths_clear_vision.up or buff.starweavers_weft.up or buff.touch_the_cosmos.up then return 0 end
            return ( 40 - ( buff.incarnation.up and talent.elunes_guidance.enabled and 8 or 0 ) - ( buff.touch_the_cosmos.up and 5 or 0 ) - ( buff.astral_communion.up and 15 or 0 ) ) * ( 1 - 0.05 * buff.rattled_stars.stack ) * ( 1 - 0.1 * buff.timeworn_dreambinder.stack )
        end,
        spendType = function ()
            if not state.spec.balance then return "mana" end
            return "astral_power"
        end,

        startsCombat = true,
        texture = 135730,
        talent = "starsurge",

        ap_check = function() return check_for_ap_overcap( "starsurge" ) end,

        handler = function ()
            if buff.bear_form.up or buff.cat_form.up then unshift() end

            if not state.spec.balance then return end

            if talent.hall_of_stars.enabled and ( buff.oneths_clear_vision.up or buff.starweavers_weft.up or buff.touch_the_cosmos.up ) then
                applyBuff( "solstice", 3 )
            end

            if buff.starweavers_weft.up then removeBuff( "starweavers_weft" )
            else removeBuff( "touch_the_cosmos" ) end

            if talent.rattle_the_stars.enabled then addStack( "rattled_stars" ) end
            if talent.starlord.enabled then
                if buff.starlord.stack < 3 then stat.haste = stat.haste + 0.04 end
                addStack( "starlord", buff.starlord.remains > 0 and buff.starlord.remains or nil, 1 )
            end
            if talent.stellar_amplification.enabled then
                if debuff.stellar_amplification.up and buff.stellar_amplification.duration < 20 then
                    buff.stellar_amplification.duration = buff.stellar_amplification.duration + 5
                    buff.stellar_amplification.expires = buff.stellar_amplification.expires + 5
                else
                    applyDebuff( "target", "stellar_amplification" )
                end
            end

            if set_bonus.tier29_2pc > 0 then
                addStack( "gathering_starstuff" )
            end

            removeBuff( "oneths_clear_vision" )
            -- removeBuff( "sunblaze" ) --self

            if pvptalent.moonkin_aura.enabled then
                addStack( "moonkin_aura", nil, 1 )
            end

            if azerite.arcanic_pulsar.enabled then
                addStack( "arcanic_pulsar" )
                if buff.arcanic_pulsar.stack == 9 then
                    removeBuff( "arcanic_pulsar" )
                    applyBuff( "ca_inc", 6 )
                    eclipse.trigger_both( 6 )
                end
            end

            if legendary.timeworn_dreambinder.enabled then
                addStack( "timeworn_dreambinder", nil, 1 )
            end
        end,

        copy = { 78674, 197626 },

    },

    -- Talent: Burns the target for $s1 Astral damage, and then an additional $o2 damage over $d.    |cFFFFFFFFGenerates ${$m3/10} Astral Power.|r
    stellar_flare = {
        id = 202347,
        cast = 1.5,
        cooldown = 0,
        gcd = "spell",
        school = "astral",

        spend = -12,
        spendType = "astral_power",

        talent = "stellar_flare",
        startsCombat = true,

        ap_check = function() return check_for_ap_overcap( "stellar_flare" ) end,

        handler = function ()
            applyDebuff( "target", "stellar_flare" )
        end,
    },

    -- Talent: A quick beam of solar light burns the enemy for $164815s1 Nature damage and then an additional $164815o2 Nature damage over $164815d$?s231050[ to the primary target and all enemies within $164815A2 yards][].$?s137013[    |cFFFFFFFFGenerates ${$m3/10} Astral Power.|r][]
    sunfire = {
        id = 93402,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "nature",

        spend = -6,
        spendType = "astral_power",

        startsCombat = true,
        texture = 236216,

        cycle = "sunfire",

        ap_check = function()
            return astral_power.current - action.sunfire.cost + ( talent.shooting_stars.enabled and 4 or 0 ) + ( talent.natures_balance.enabled and ceil( execute_time / 1.5 ) or 0 ) < astral_power.max
        end,

        readyTime = function()
            return mana[ "time_to_" .. ( 0.12 * mana.max ) ]
        end,

        handler = function ()
            if buff.bear_form.up or buff.cat_form.up then unshift() end
            spend( 0.12 * mana.max, "mana" ) -- I want to see AP in mouseovers.
            applyDebuff( "target", "sunfire" )
            if talent.improved_sunfire.enabled then active_dot.sunfire = active_enemies end
        end,
    },

    -- Talent: Consumes a Regrowth, Wild Growth, or Rejuvenation effect to instantly heal an ally for $s1.$?a383192[    Swiftmend heals the target for $383193o1 over $383193d.][]
    swiftmend = {
        id = 18562,
        cast = 0,
        cooldown = 15,
        gcd = "spell",
        school = "nature",

        spend = 0.10,
        spendType = "mana",

        talent = "swiftmend",
        startsCombat = false,

        handler = function ()
            if buff.moonkin_form.down then unshift() end
            gain( health.max * 0.1, "health" )
        end,
    },

    -- Sprout thorns for $d on the friendly target. When victim to melee attacks, thorns deals $305496s1 Nature damage back to the attacker.    Attackers also have their movement speed reduced by $232559s1% for $232559d.
    thorns = {
        id = 305497,
        cast = 0,
        cooldown = 45,
        gcd = "totem",
        school = "nature",

        spend = 0.12,
        spendType = "mana",

        pvptalent = function ()
            if essence.conflict_and_strife.enabled then return end
            return "thorns"
        end,
        startsCombat = false,
        texture = 136104,

        handler = function ()
            applyBuff( "thorns" )
        end,
    },

    -- Talent: Shift into Cat Form and increase your movement speed by $s1%, reducing gradually over $d.
    tiger_dash = {
        id = 252216,
        cast = 0,
        cooldown = 45,
        gcd = "spell",
        school = "physical",

        talent = "tiger_dash",
        startsCombat = false,

        handler = function ()
            shift( "cat_form" )
            applyBuff( "tiger_dash" )
        end,
    },

    -- Shapeshift into a travel form appropriate to your current location, increasing movement speed on land, in water, or in the air, and granting protection from Polymorph effects.    The act of shapeshifting frees you from movement impairing effects.$?a159456[    Land speed increased when used out of combat. This effect is disabled in battlegrounds and arenas.][]
    travel_form = {
        id = 783,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "physical",

        startsCombat = false,

        noform = "travel_form",
        handler = function ()
            shift( "travel_form" )
        end,
    },


    treant_form = {
        id = 114282,
        cast = 0,
        cooldown = 0,
        gcd = "spell",

        startsCombat = false,
        texture = 132145,

        handler = function ()
            shift( "treant_form" )
        end,
    },

    -- Talent: Blasts targets within $61391a1 yards in front of you with a violent Typhoon, knocking them back and dazing them for $61391d. Usable in all shapeshift forms.
    typhoon = {
        id = 132469,
        cast = 0,
        cooldown = function() return 30 - 5 * talent.incessant_tempest.rank end,
        gcd = "spell",
        school = "nature",

        talent = "typhoon",
        startsCombat = true,

        handler = function ()
            applyDebuff( "target", "typhoon" )
            if target.maxR < 15 then setDistance( target.distance + 5 ) end
        end,
    },

    -- Talent: Conjures a vortex of wind for $d at the destination, reducing the movement speed of all enemies within $A1 yards by $s1%. The first time an enemy attempts to leave the vortex, winds will pull that enemy back to its center.  Usable in all shapeshift forms.
    ursols_vortex = {
        id = 102793,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "nature",

        talent = "ursols_vortex",
        startsCombat = false,

        handler = function ()
            applyDebuff( "target", "ursols_vortex" )
        end,
    },

    -- Talent: Your next $n Starfires are instant cast and generate $s2% increased Astral Power.
    warrior_of_elune = {
        id = 202425,
        cast = 0,
        cooldown = 45,
        gcd = "off",
        school = "arcane",

        talent = "warrior_of_elune",
        startsCombat = false,

        handler = function ()
            applyBuff( "warrior_of_elune", nil, 3 )
        end,
    },

    -- Talent: Bound backward away from your enemies.
    wild_charge = {
        id = function ()
            if buff.bear_form.up then return 16979
            elseif buff.cat_form.up then return 49376
            elseif buff.moonkin_form.up then return 102383 end
            return 102401
        end,
        known = 102401,
        cast = 0,
        cooldown = 15,
        gcd = "off",
        school = "physical",

        talent = "wild_charge",
        startsCombat = false,

        usable = function () return target.exists and target.distance > 7, "target must be 8+ yards away" end,

        handler = function ()
            if buff.bear_form.up then target.maxR = 5; applyDebuff( "target", "immobilized" )
            elseif buff.cat_form.up then target.maxR = 5; applyDebuff( "target", "dazed" )
            elseif buff.moonkin_form.up then setDistance( target.maxR + 10 ) end
        end,

        copy = { 49376, 16979, 102401, 102383 }
    },

    -- Talent: Heals up to $s2 injured allies within $A1 yards of the target for $o1 over $d. Healing starts high and declines over the duration.$?s33891[    |C0033AA11Tree of Life: Affects $33891s3 additional $ltarget:targets;.|R][]
    wild_growth = {
        id = 48438,
        cast = 1.5,
        cooldown = 10,
        gcd = "spell",
        school = "nature",

        spend = 0.15,
        spendType = "mana",

        talent = "wild_growth",
        startsCombat = false,

        handler = function ()
            unshift()
            applyBuff( "wild_growth" )
        end,
    },

    -- Talent: Grow a magical mushroom at the target enemy's location. After $d, the mushroom detonates, dealing $88751s1 Nature damage and generating up to $88751s2 Astral Power based on targets hit.
    wild_mushroom = {
        id = 88747,
        cast = 0,
        charges = 3,
        cooldown = 30,
        recharge = 30,
        gcd = "spell",
        school = "nature",

        talent = "wild_mushroom",
        startsCombat = false,
        notalent = "sunseeker_mushroom",

        handler = function ()
            summonTotem( "wild_mushroom" )
            if talent.fungal_growth.enabled then
                if debuff.fungal_growth.up then debuff.fungal_growth.expires = query_time + 7
                else applyDebuff( "target", "fungal_growth", 7 ) end
            end
        end,
    },

    -- Hurl a ball of energy at the target, dealing $s1 Nature damage.$?a197911[    |cFFFFFFFFGenerates ${$m2/10} Astral Power.|r][]
    wrath = {
        id = 190984,
        known = function () return state.spec.balance and IsPlayerSpell( 190984 ) or IsPlayerSpell( 5176 ) end,
        cast = function ()
            if buff.blooming_infusion.up then return 0 end
            return haste * 1.5 * ( buff.dreamstate.up and 0.6 or 1 )
        end,
        cooldown = 0,
        gcd = "spell",
        usable = function () if settings.stop_moving and moving then return false, "moving" end end,
        spend = function ()
            if state.spec.balance then return -1 * (  6 + ( talent.wild_surges.enabled and 2 or 0 ) + ( set_bonus.tww1 >= 4 and 2 or 0 ) ) * ( talent.soul_of_the_forest.enabled and buff.eclipse_solar.up and 1.6 or 1 ) end
            return 0.002
        end,
        spendType = function()
            if state.spec.balance then return "astral_power" end
            return "mana"
        end,

        startsCombat = function() return action.wrath.in_flight end,
        texture = 535045,

        ap_check = function () return check_for_ap_overcap( "solar_wrath" ) end,

        velocity = 20,

        impact = function ()
            if talent.dream_surge.enabled and buff.dream_burst.up then removeStack( "dream_burst" ) end
        end,

        energize_amount = function() return action.wrath.spend * -1 end,

        handler = function ()
            if talent.fluid_form.enabled and not buff.moonkin_form.up then unshift() end

            removeBuff( "blooming_infusion" )
            removeBuff( "gathering_starstuff" )
            if talent.natures_grace.enabled and buff.dreamstate.up then removeStack( "dreamstate" ) end

            eclipse.advance( "wrath" )

            removeBuff( "dawning_sun" )
            if azerite.sunblaze.enabled then applyBuff( "sunblaze" ) end
        end,

        finish = function ()
            if talent.fluid_form.enabled and buff.moonkin_form.down then shift( "moonkin_form" ) end
        end,

        copy = { "solar_wrath", 5176 }
    },
} )

spec:RegisterRanges( "moonfire", "entangling_roots", "growl", "shred" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = true,
    nameplateRange = 20,
    rangeFilter = false,

    damage = true,
    damageDots = true,
    damageExpiration = 6,

    potion = "tempered_potion",

    package = "平衡Simc",
} )


-- spec:RegisterSetting( "vigil_damage", 50, {
--     name = strformat( "%s 伤害阈值", Hekili:GetSpellLinkWithTexture( spec.abilities.natures_vigil.id ) ),
--     desc = strformat( "如果设置小于100%%，|W%s|w 可能只在你的生命值下降到指定百分比以下才会被推荐。\n\n"
--         .. "默认情况下，|W%s|w 需要|cFFFFD100【防御】|r 开关处于激活状态。", spec.abilities.natures_vigil.name, spec.abilities.natures_vigil.name ),
--     type = "range",
--     min = 1,
--     max = 100,
--     step = 1,
--     width = "full"
-- } )

-- spec:RegisterSetting( "starlord_cancel", false, {
--     name = strformat( "%s |TInterface\\Addons\\Hekili\\Textures\\Cancel:0|t 取消", Hekili:GetSpellLinkWithTexture( spec.auras.starlord.id ) ),
--     desc = strformat( "如果选中，可能会建议取消|TInterface\\Addons\\Hekili\\Textures\\Cancel:0|t 你的 %s 。取消它可以让你在全部持续时间内，通过 %s 和 %s 堆叠层数。\n\n"
--         .. "你可能需要 |cFFFFD100/cancelaura %s|r 的宏，来处理在战斗中的这个操作。", spec.auras.starlord.name, Hekili:GetSpellLinkWithTexture( spec.abilities.starsurge.id ),
--         Hekili:GetSpellLinkWithTexture( spec.abilities.starfall.id ), spec.auras.starlord.name ),
--     icon = 462651,
--     iconCoords = { 0.1, 0.9, 0.1, 0.9 },
--     type = "toggle",
--     width = "full"
-- } )
local bear_form = Hekili:GetSpellLinkWithTexture( spec.abilities.bear_form.id )

spec:RegisterSetting("bear_trans", false, {
    name = strformat("%s：防御性使用", bear_form),
    desc = format("启用后，%s 将在玩家没有任何减伤技能时被推荐(需要手动操作自己变回来！)",
    bear_form, bear_form),
    type = "toggle",
    width = "full",
} )

spec:RegisterStateExpr( "bear_trans", function()
    return settings.bear_trans
end )

spec:RegisterSetting( "stop_moving", true, {
    name = strformat( "移动施法" ),
    desc = strformat( "如果选中，星火术与愤怒将不会在移动中释放"),
    icon = 462651,
    iconCoords = { 0.1, 0.9, 0.1, 0.9 },
    type = "toggle",
    width = "full"
} )

spec:RegisterStateExpr( "stop_moving", function()
    return settings.stop_moving
end )
-- Starlord Cancel Override
class.specs[0].abilities.cancel_buff.funcs.usable = setfenv( function ()
    if not settings.starlord_cancel and args.buff_name == "starlord" then return false, "starlord cancel option disabled" end
    return args.buff_name ~= nil, "no buff name detected"
end, state )

--[[ spec:RegisterSetting( "delay_berserking", false, {
    name = strformat( "Delay %s", Hekili:GetSpellLinkWithTexture( class.specs[ 0 ].auras.berserking.id ) ),
    desc = strformat( "If checked, the default priority will attempt to adjust the timing of %s to be consistent with simmed %s usage.",
        Hekili:GetSpellLinkWithTexture( class.specs[ 0 ].auras.berserking.id ), Hekili:GetSpellLinkWithTexture( class.specs[ 0 ].auras.power_infusion.id ) ),
    type = "toggle",
    width = "full",
} ) ]]

spec:RegisterPack( "平衡Simc",20250616, [[Hekili:T3v3UnYr25NfHflhYrdPy3uuYYqIgZ6mbWdCSnSCwFrWkYMKfj7iYUz6FKgzqq4KGK4yKaKaeGaKeGGjazXIfojxKB8A4f5HjZ4m5k)kKt9t3Dvvxv1fPOMmRxDJLhwN(uN6uN68ZxvD1x4CXNCX5J9sqx8bUTD72(i3UTC64EsNoxCEYnlrxC(sVrx6nf(Fc8wa)3x(R(pF1ZF(5(lgHB6M5HEJXSiomnAe08SKKLXV9bhm1pzw6WwJcxCqS)I05Ej(HbJI8MKG)3Joy48WHhKmdDTx01aP(bh84rys(Oi)Wi)KBEF)4K4dghL6pU)qV5EbJqTIjD6Wu)5jVxWfdvk3ohEX5EPjZcJU4CqiFxqI8hpgrjhfdppM8MTpQPB73E9amjW)9MGrRFAwdohPPH2QBORUgoSPBxLn0Pzh1DENMohk2WG6jr(bxIswpyuyWyFSokUbh9Da6)KmsM4)muCrJTFlOXpgTCU3i06bx5f57nCoqWaSkF9a0O5(lJHwwGs8sWnb)2ZwgHIJX9chF6s4ZIWRakgI8IGEkmAX6bXjPtMq(hRheeEn3t4IfRp9tHrbYlomy9a31dsxINWYiYLQ2(y0vOiq0RJ5bcgGnaXlm6sVOW0GXXmMFDKhwIdxIcqreoCyZ2o86xoMFyth3MUyj48L3SWlobfb8XFXYiyaSafKKrLdDKjWGb1ppnyIFeQrgvTB6Ecq1VR)Zwp4XF4twp4jm9wr7hjXLhTEG34)W04eCVLngMdJ05(bt5EUoAe)2uX3XPv7wDl(X2hbmg(RJd9VUoQF(2N009TasW)9eTK02Hss7dz)L9ioTz)TlJf66L3ceeOPFpVOlHPgWoawpVEWN6pFCgfhthIFc53XMnFkzT(fNphV8g73ybyrpL4Ca(xFaXBKhXrWfNhHg6hLm7IZrbyBZXx8tUibwTlsc2MS)OWOO0L0FsG4o8ehhgccOefhIPO4xoFe48bbRta)giV5jZATCeyCE66bN0UGtbEjPWQK(x5p1FoMlDTJlNTEWHT5L(aW)hHbhzndMTS)uVLRhudwjcl(Ane0(Xx6h0AC41bKFU(6brEbtr9JxIMpV)cVP(GFKvRG5hVOPOK(lu004WKY)ipBwo7MyD8HVTcgL9RnkgXzclEiFS0qoNgW)sFS7fETa5hta5joBikRx622KoH(ZzCwqxTPkLnCWtBqYyQdvyhfgohlkTMaMcFMpAC)i0uShoYcIwriVX3q0FGBdWkFme8c0Cj4izt8sNNKVKrPLJ0yoDjSeacMmkb)q5Q7rEG0s)h9XRkPRn7td2JF6sl6IdNd8eAAHQvBkfL9wp4JUcT8QL9hndn6sYGFpS9L)4nxO4CzOybCglirmOX8J8z(g(dEceFbn(NrIyoDkejzW7NgG9lL5sFGp4g7A4Vt88bgcZ2HRharehbrraVx0OqpZLFSL4VarMuDjdlwq1wZXmUVFqFhvoicXtgOKcXnl4m()BEk8NJwp4aialXyAgog26b7Jn(MdruAL5aklZigN5jjmAOFs)HGn0LOOccEiXiT1IWqsqUwj(JUehtc3qD26eXhnoXdpJ1J0U7XRh0KmuFiJyWAigyccSViw7nin5EOKQ)N(4p(9E8p59FY5KHkBMCPhKPb4)2lEPkNGvRKYxanYdu1JAnjf0wWS1m8A0(SzM3HFHwiKLA)Wj9PAqyj2cp)GyEHcyfAYee0LxrwZPWvv1cwDI9nBQ46z(r4a)9bvzuCXCb2Xqbvq6DxfEji1ZWEw8b7ljslgSkOKnqigIthnU1cVNrNiOp7e)PZs6ZtKDCdSN6Sj9EpEc1pNaS1Plr(kg8jrHZXZmy(ogS9wum6BK5Rotp3c8lKgdCllXxiaqBQCwbvouQmrshUoK97TsCALpU2IbB9nE8Ub2g12nIzZYKnoLgjklWNvYsDBTvoLOQzpbYFo5)PEjB1M4uDj6KdQGZfIBd6O2itnQZ2YoTXgUwXOmuBhmVDAf9bBHitURI0JicTKQu)dsZEP6fCULwT5U9MX3VA7n7vBQMA3YoDRxTPsg21R2u1hAwTPH0QxT5QA1wdLJfL5hqZcNKghJmCrcC5NfHZaQFoWt4CHERnoxO8L(YSlZCSCYjSvWGsqyDmiHErbeLnuirymkaVKgbPAJewotZL1HA4zohmG02TClMtif31cpx3pjS)yFezsWPDMSUhUwUOqW)fc16seAjkkZTY0ic(yy2quPGzZIWGBeAoplzHmoLuXNSXQ4HHXut4YQYU5PfjoplV2rYmPhgQcUeH2fJBHoutM4u1DxzneBLTGAYP9gRNygd0AZWfzcweIjztl4IAgeJR9jcxMerQ6qSNQNBsLUyyK3CqTLGcI9tUPvKxWLcoVJdtZd6aJxuCcNzQCTPNFtK)KFgPp(Pm5gQqMcE7y7GSLxLb9pmfrgPeLLmobvRSyqPqQWepkW1KJrVBACFVOrEWAowPH7Nd7IkAzZVeA5fWHHEj9j)AmraD1IEqUdKGqS)dQYLzWP3W3PlpMsrXOiCHUKUspqfct)uBrLaueLgOfFcVqePx0HmHPNnoHcWdgYHWfd9skHk6cVOlZSPU2F(yvWJQOtXf8dJ)saRjuO68Ba)REX9xGXHNIbLMIvNmhVXmeCLKQstbsBs4xvcNOQnf5Yndnhwg5dR78M7pnaJVUq(q7TzbliG2H3KjQTLaqa8wBQqAQAXUnp7et8vhOqEJhRMHAydpqufPLodMeXunKS9mm1srZ(XTcVYpW7z4P6OrPry9jA6u1KgNVjk9VgnKn4afzC2iKmwD0HGZUye5AEe5A)iY1(redRv8YzzCwhQ09eNlxbOaHLD5(T5(zb0yaXHLHjvGZzQQeMYdIYzJleaTeMnkw1irVC8Oh)HprgmvfUxeG491NIGdmAweAZ4pdmfhQEz41OOwJrt8h5Z22GIKtlWIKM9TuFar0mb3CgGQ89AeAceyEgnkDnUnBqm)YM4W8mnaTuQJ4Y6I5ndY7YlijoZZpU7mK4cHPEuim5H7T)4ftZ6bRZgRJqHcMYQLrgetgud3mAoktEWlFu4WlxbNUt1D0S0KuihqWzOHAbt2V19ZQIZQ6Ns1TlEg3bhAHGQQMuHxv1R7v4rtvPtwZpopPkRTOGrLDMvWLjPr3KNLHY0UfCyAUCKSKPy9sFY(Uj4S8yHQn0ZMSzzcWxG3SeePq)CV7Er4tDJOGRlrsfRvJtcxc2Uxr2hjO7O)VCz91vzw3MwKPJLQmblLOTfHMRleukimGvaRvHK0e(ndagP4wLarPCuvh9NFatHv3Ybrd1rpD05eesuAoEhFNa)hKHILy42ia7IMAKPEOD5X2HfIoEbOB53WYg8StJjUgV6oYoNuyyugtkvWIObO5UB8oz1J6ahxscRlkhuyhTrG7tHTAhiG4(8wSbIwcOlvF(M7w9T5t2vbWMB7xR7EYRHbGbaPlJZRktT9ZbS0KbNKKSpjsydHGH6W7TMDlZQzR9DpdPBvyB3mhc5Y6a76hXksK6jIZo9PsjIXJ2Se0b9jDPu(SOICssxAt2kuHpNXT4cjXh1kpuMU4u6ZXJEGuaAVg5DfP6EVOL5qptAnjmD0mIkEuieRjUFwXDczeXxXNR(ubl3FOjjLyuCkOrjCsaiV8(qcap9LyxxtMCc54XI4IW)zuER6MBlsI02z)FaUtdcMAkwfsMweokPbORjfRjp3DiprZ8MprjvD5PIKAHkQ0FKq3JCK0UQpEF8CAHbbU)I04zrHHlYmfWLhojnykyjaALRtMLDqV4Y(K)5i9O(0LQAoXONjx9EMQE)ye8PqORkt6EeROk3SgHEXM9RrRdj3t4NpzN7q(5Ye2bP04P1SYZ5RWb5mxDR6GJQcOUy0OloVDlh(Q(8zB2qSYdsQ2QdfXj88pzZMqTjsu5cyafYXLgwdlP1TOYVDpwKgrE8nayr1bzPsu3k6sggYkG7Qc3Z1m67LKviZqOAgPbgCnf8PdFrBGXtAOlxuwLi1zv4gBbDBZqP0sS2SOA4ncRTTg7ojS2KZNZG9PLinjNXMj7GncPj9UV31G0u7ocPPTBdC2YbHUm417Uu)2EPElC6zyhCy1BiVEehMCQ)Nb0TimnirtU62aQ49yhvTawvP83JD0oc6L7Xo6ESJ2ASJ0V)d0jE1(ypvTxz(ABL3om9f1Qd7g1GYyaA)SA5aQNhgnU8(PL3c74RHt4txua5CCmM7CEcLAYEqxIo2KE6BCjJAawm7Skl)IkjKVFPt8Pjm1Qixc98shApA39tD7f2wCQaAMtsAalxMJjR2K2xnDta6ZIs0mxaPnrTm3zWeA(S8I(k7a9qD6F95jT5zSjLAMozjl0HPWl8N(ZC06YbF7UsERvgHCkMv8Ig6zOrPjioOVnbCEPhOXUsTuGpPz4g)Tn9sbISMbfvh6)CYUYDBGS2XWUeOVUAnhJTQRbIu)NCLpecQxEFzurM6oOHWRnS(D(PUOR(oQqtTy8RF)DQcYiJj50rFaRQauVmA6c2xC1zlJPEh9HNmHcQ66M7i8A4RgOzgCpkWZva12p6JFs)393j7o9r(8WAt94zZ6CpBeAzyuc3lmU7jS1c630i5fLCVGxCkbr5tb82wJ9K4BcWgcerbBwgs(Rb0vz114izNz6OvNLpMin(laZC87JoSMBekySxWOB6dJH0fQPhNC4i8YK0y6nMXc)KeuKn1gVjv9QrbfppmHBWBauwgnU6uqkoP2LgWUBOcYTkfu1flBZ4M8woOdT2HySudW0hZp0Rgl8Q3YZcEqQ4kM9EpKn1BdYuCvMlVlUnYCxWpcuGRCrAxPKt01nbE4WcOGz43oOiLRYuBmwY8wgHao)qBNIPr(ErW1lLExdUL9rMEtNcrbw67iDORIvaVo0HkEFnUL9Hf6qT7JqiyNJssWi6eLo8gELhVdrPl(d(nbtBaSZOlxQrVlB0LbQ(UWwftfLulcxM54Yez(Kmdd0FuQ)YLOXT0OyPDF1uvZsqhCBNN0H80IQDUHlBBdtbDkMcueIMKxeobD8)KDBb6CezJTdWVHIxC(R(3(5V8V9l)(V9F4L)hF7l)Z(xFa76v6bV8l(7F1Z)f)V)tF(R(5)XV4R)8x8n)JV6V4x(YV8x8I)R)9V7V7x9F)5)jRF6)Zx9vDF1Z)RGN9v)6V67(R)xE71dExykcfLGXIjCjBl5bb1hmJFWr)yUB0N9zPaQ528jRzL3Kppu1T4ZdRtM6vC)90RU7XnDFi1YO4g7PrJh6E4dwtULJEWrh8gOS1IOIpMxf)Gm3mLbB)bV4R)Mhyam(h89F7x48DF1Z)(V9VmB2BNXAGT7CEEV4EV4EV4Elfxi4OboIBDRe1QzBLIz5nBtKJkA3wrDlyDLI7wmtzR4UfSUsXDlub2kUBbRVxCVxC3sXTKNMsTUvIA1SvNywrsU13Z4gPVA1EvVn6RwLllg2fXtzWk)q3vReQl4uBE697yxV0RGiDaNSVt3hAXXIOrT6Akx)S2RwPTnNvR01uhGLg8sAJOx3sz3Q5TA3oHPPmjz4bVALf9DDBMnpTdqhYFE96cwmnDA34hB85ZeLg9u94gg3BaRByPfPHER2TqlFQb(cM4G0zIGJ6jOs0rm4zPHEdAxo75YEoTWe6E75n1OZS9C5jHnG1BS9C5EB3ypxMVs2ZkiqV9SCKYgnkjLsrOQTNiC6zGUCFSY7JvULcZ))6B5a7CaSnXkTK1BSVL7JvEV98DR9S6yLwY6n2E(3AIv2A9tx)u5nPj)ksCB2MgoGN43PszqNeARCr26yPUBJoz2RLUnQRepJek6djckZ8J0awGEvJBvQgDS0ovJb62OUYKQrfbsmVSrNxiABm3QaWeUdpm4rV0XgUjB9rJEh1SUWHd(h72ilrYTMhha8GUlBo7mSzlpjT74nhOu2W0QHPF7e2Q5B1c6wGCO1c7wW7nuGRg)WTtyRMVzcA51NX2gnW5WQNITZEuXGCNXB(zelyA12KBNWwnFRwq3c7rRf2TG3BOaxTn52jSvZx9260J6RL276ML3j5pyG56pCMk6ideVrDQMt4PIEuhL2Ma2UildZm3wfyveVrDQvkqJuA7osTH(zUJyBL7h3TQmH3Ax4h4oITCJCD8BBRcy9t)UV4V5LF5)m1D1l(M)8JFXx)l)UV8ZF1F6VM6ZIqf5AKCe(O)5IF7fcN4pp)94iUvErE7F2bY389RF6p6hL92Risz(DLZJyxmeN5(i)jNL9gxu6wUVgRLIB1(1pvPeWDj6lY6CyClZ8cOtkyFJAKkCL(GuQSpZW(5r4tn5z83j9pICpLFwoWmLVLoQL1MV(7c)vR4V)7TrgebHIjfTPZg8FflOFSfxt)QWoenp8AYbsoJzX0cxgIOh((fEjJMr)oZ(asDrjGGdsYwirHlpZB8yYmUYLVGAHpAHY6mLOr0doBm78OIloEScyhiOUAeu9felrJsb1vsqZfvqaLV8yOck2Y8r0V7fWWeeqj710L88O4lcA1CU4R3Pa)3J)7dAT9iNM6NInO2vFYo5KmYBofrRd1hFQBTSBXK55FYojDD(NSs(bL48j3BdhtvBZb8v5HNDhEOz1lVsN)CMmNhsqlOHN(o50O7WDRxhjDlPW6unB8LrGMTdG0FtzJUUB3GRTcc(Q2paZ7dqTBvFVvW)FRH93Y9X2iS)Q3fll58MI6)D0Myv1EyTjBH12Tdw3jBG19gSQmyFTEKoUJ2LQQ2KQnzpQU9BrLHqULd9LVyqo0ynX5RtbJ79ZnVnKdFJhw3PPYWPpSDlxSsP0(b0ZPDT67z8LoD1ktVxAnAyymZmlKh443HRAIdXUqKorvjV5LGUV3HTBC7KzowRjnMEGnenVZDWNJpHculPKYUUey9CMkkv3DKXPVJqBI3YcANkqf3KFSEiRqv(7DGvRuFB62RtZ6m6v(LCi3tx5BoxdMhC36m8J6Q)udUVb64)mdIRWbR6)O3J8Eb(X)(FW6bp(JEF55dFQvk6zGkkagByUZYzfFdBaJ1jP45rCPckFTV5hIfxSacKZxWoyCwEbGtxEUi9TbKknEHiHALeMR65u5Zd1b9uIr9J)WNuuLkW1SsHyNHIZAli6CMo1kFv1wt6UF80879XA7PuzXf5ZV8NTSEcPDR)ZvwVonKgchKzSskJ8Us6v2PG5hUtvDTSCkNx(IIe3)iz(KvX3JeUINOZZ2VLU1YRMsXvdM0I7MEJu(fKQ3rw4ESdlWNUGcqZ43txzLv6oymwERV)HUUuLQunOk0ejkrB5Lrv7kJ9SClrT(zeUU)WpLIl4APhr(YfNSgwveQA6d(D6X5HHeFeQ6v8tLWt1zBMbNBxIh2Ilf4AS7g4nWwt1tR0VRoVT1LUSDxTYG7knEvXPXY5lR0Dv7g7eDdekfUO5U28uQY4xvb59MNoRY0oAw3nlRypHpBunAQYqOK4iTIuyEqwrvoDufvH2TcOEYRMSW5YwdV1(oTTT32k8VSQkW97(Ah9QQ0X6RBWT9Da2e7gXrrLNI1aMpxUFx9ZMc8F)JBK7puSyWAgGLWgtJEAdPLzw0eQQuT4B0K7ifUL58hvxDeb1LSCMdOcveSiDPPqi0oxX3MOcVCm3EQt)KLjifo(KsxITSYsn9XhsfBj3jEQ5l7QguJSuktGYkFQITCeswuZsFgH0OUXbFnnr8Bev8xAon7gdv(3ZVYmlN6Z85kBq4gbKeCv3nnyT90(r7XI4xMvsMwDPgpaf4qO1gOxD9WeycHGsQDswrSAvP3qHfuqJldeHDr7NGwWQTvC)o1LQkZLGMlfPEUNOS2CDGq2O0rpGkAJjZaQopmGol(sTsNzBylKDtBwnxRk2H4gk0WAGYqD6J5pf9(wAtEI8zs8vjx2wGt3nydJhPDMx)rEsIqnZm6tJXCQk3QbPRWGuX0I0U6BZG00XXQM(CC0moQCHh3LaiEWy09tnZUO1CRVXVvj6Y8MKmLy0evw0IIUMlXmbtxzBbEJjXu2ylp30rxdHvTcN6JTKH3fJBxE7RD(4291Z4w(MMJK6tHDV4zI40okdfCMB7A4dLICs46ytvdMkYlMwkGj)(GeDsT9Q6I5dsFTckQvzcsUTn6TxLYQdvzXcLF(NuWG4enO(Oone1z(ld8Wzhl2bVgr1wAKvnmk3b9Pj0vPCeSPfaa1S3AdweGDjmPy(XvkZnKeABXQnFeubSSvAfxfARsYND4SsjDRGzL8O2HYQM5BRrSSsfUzallwr9gbELwUoBdKj55EHsVvxoHQT8PxHWZTJpuox1xHmjj4EakVhGY7bO8nkakfxFkVtxD3x1I)tv5MqLNSkGp0K)Pm4vsOFTFQLZJIpXvN2ztYyO47yK9bqesU41ACAbDHnZLfNoyUevKpVsYr4vdFQ1pFLB)LL7oDtAt9oEFbG4mQteThYbwTyWZDAC6Dwh51WhkX7mKrXS2(GGsr7K7eSdhDoJ4oFmujihd2BLiiThbcN0QE8FyHKGcvyBdeiSXTAuLdG8pOgvwTjgM2CKSVvsM4RYJFJPCXu(1qA)6SwZsTSebQyzJhQAVMY0v1Z810PH8A0Bbe(0sOTFFf0(1l6uxdzvRQWBzzidU(IFV4T75SdIqd9JWeOUrOqd8uDuu6srxMfKHfPWqqfOPXS3RMR8N6tcGw8r0)0tAR5HIG51R9Kj)Sd1r)qVOlJV0pq(bOFG(zViFmAArtHoYlykosb2h9cVP(JYobU9xi9ZWCJ4pW)OlNDtSQNn73lEy6V0q3iq9Rdj5NjGeJbeOyG1TTQbf9NeEHfZcvv9OY6ragLVCjPtBoOiGPTpZhng8dnfVWKVSrrtqSmcRVurVXPqvVBBKFfBP75N8Oy0OZA3YH89K4I)Vp]] )

spec:RegisterPack( "平衡官方一键宏Simc",20250620, [[Hekili:TZZwVTXXv)BXiiuCLSOixDXrfskWj1peHahJq30hkcxUC5qYfICx2Dxkzvqq4MGK4yK0KGAKVI2ce4IMIGchNh6logoT)y(KKLFY)f6zMzVm7SZm7skk3KwbdyjT7zp3MZT5mxAuRXnBuVTzaQX11RQVE1n0xVsT1QTz1nBup4WHOg1hAATNzx4xCmha))XF))407F)JF4F4KV87p6r3(z37Hh)WpRU9almKh231SngJ(UJ8SaOpW9G(JmBuV1i7(bVHtJwciw11Rwd(IHiRgxVwv9g17z3UnIclYhW7PF3xJjWtV338SBFVJE0JF2TFVN9bFkhl88N8jN8zF(r)Z)0PF0F)47(np9oF4XF2xap84p6Zo6j)1JE0V7Kp(3FYx(Tp9B)4JV7xD67)dnQ332pWhZSd9qwUdAzga)X1jketRaBxNg1hy6TNHBhJGEiJdS73UrDKJzR(O2nETgbGqGHn5jjFMRRZE2ogDC9g0OULNDaYZg0cLN08stAgy2h5euP)HwMEM(gdqTTdmXFyLqunP54XSq2P)i72eKLaH2KMLM0S1OoDQ0cz6rFBB3dCWYLdYWc4vDmpUkhp6oe01OGeMDFtG3G3I)T(JGFKqyluFKFGTzFdZ(2DDgGFwmhuILfTDaHXHifgw9C9roy1gQ)ihuAPQThilvCCbg0NqBdQzf5jguSHz71MA2Ukl6a2yKpYiWZ2zpebHRlaHMTBlgHsqdZqz4JQeuRspyqedfEWiwTK8AB)kU7B7yEl8qTN1ipS(e1TRyq9hE4atFGi(ghGAfkCGI0pscjYAnSeTX5KePRwI0lUePxCjcBRgGD47yoQFIJiJ4LWPCw9JWMganTcWFuS0Bz2hSBj)Hb2vN6WhQgWFDShC0x472hWj8QbC(58(qjSciT3yF0W9hcw9iR9I0aEM2TNEMAGDGDxIp0S5bSXKMRmPjeifOrpSkFsZLI9qbNZrEiFJwM9nDSy8ktaX1RLDGrlpK5EiVeawe8ADdQGdQ1X2dvjW2ccU1L8IYHXGs)P(bMyDXoK3RFLjnxg(bbEcWGEgIQa8WOHKazAKxPVgnEVN9qQ89RUgeye1(DN08ME2D7I8M08nh5yc)4Aw9Th6dINnyEEa8ZoM2ewnWDstC0Cq4N08x6zg0BsZBbu(DU6B)gx91EZRvN1vyOPVV9(idt)HYcqOwFB562hhYTILPbeaSsNrGIhOEptVUGlM9aGZ26vN0mgoWC1cHdmshmQ4HgyA7KkoiGkuNoiGK7tcIlXpxnJLkpZb9S9GucDnGrfpFz5ySCD23DpejtN)qBWaNd0eHvaKHcciUtA21QDLbM3IoMs)2o2D7fyWcuXWgyAU60q9Dybu(ycG2ARt4VeHpWZTFuM(2GzCMuTGonspxjDq0jn3EsZQu(mhOQrHsfiRYqqMudXY1miSLNA5DkSnknFyZLZcw7rEKGHu2PG8s5IARSfrvh(fi7(KFPCgBvGVQvLOtwjhmNWUAuPwjsvQZMrIQnL(kk5HsZHXTTYHgHoIH8DEGUbHP5uLY)qZ2hgJAvoC6z820NDZ4l82(XT3MOH2zKOZS3MiEyE7TjIgs82KaA(EB6I820eklcRpGwQmPIWqWWvYZuFMhUcidqVc1bgwu8vM6AHID95rxK5y2Itc9GbLqk)4cnhxTOYIRrn8uxdgaA1k6jJj4HAqZcJ1gbUgTTrKbbS1jLxb9vpKNle)cHQShcne5ffwPRN7(ikAiQuWSzGRZHPEDCb3PQ4Ktf)ktTkULRp1eoRQC94YIspoZ77WzMac9AvzkeAEi3PiOKkXPQ7151qHE2PutBo1QPO((GNdJbEIGGbr6ASPtDJAf4JNfLhEcxeMAvI5u5ylQrdA5bZ622ja54BhCyfptN9sf723DuCohqCr(m9UrJFQw1p0ZUZ7sOX7eY3WSyrd7BAHH)aB8mPqrt7AakWmGcd6wGFfmpQqjouJb0hgHiskwxvR6uRSOZXNoxvSuGN3CqpqJ5By6zzcUCHtYCPOUGje2WHxcSSmylxZadYt9jmO8Mneh)GTdvH2BYT7RTEIS1c55J8WtzMqk(MgMqQud)utrHnrWBKJ0Eiy6IiuHVLff5B9jnkRgFJh8rwnQxTcddCGPDaTFnK(OOSzn9qM9d6vzOfO02ck3Q3qJUMdf19sC0)ik0Xd58BSrTbLAxKdYlURi8ApvmhwxiG3y7sl2)c42dT6JIu8evDc)7HaEXVh1ApSqrbHPxg7Ueo(tRizdMGxHUKq4ltNa)iVsmdOiaabPM0obW2agJ2d6grHchuB1u5BvLCiemW2MliXvFRRPQP3(JI0MZfDhnAhNczfs56AcgXe0LobJZZfo7NQJQ0HurAoEp(c1TsA9uI6Cw8NND5degzntvz0AfeS4dXYoUJlmR0rTne1OSi(GPWTPG(mFvo0LVOufEe(bUdblK9j9pfOe9xzW46IkbtLLSmmkyCoivlM5xRlpulBVGEIwIReqaSJRdYZBuyqHuaVA6UP7cwHCqWBPjjpXKMBwnbtrTUEF7U29fzWjpBZAvz5Eh0bM9fzPmfPRm92ZhYLtwRTOybqTxDXt6d7MpWSRTfB58gde8kWZp7dzrZWEh6ldpSVlbrrpvJPYJqMvLrAC(3uRWc(Hba)4hjI86L1RQsNiyDjthMT4kLPu4PVGZyA1QPNvQWQlINel3kOgqkmsrDejU5klJivNqid3zZbLZKCkPmTaH7d7Lu(iss0p(zgu)MQY5xKuRc7b0uK9CUMiC6QCOG5)KM(8fC(pz5HpVZ)jlV7mN)twSQZE(VWbnbEZPS6VXBFnJx)NhTLx4xb7IOcJ64bZ3ctN21lGzXr13m35rkVBFmH554pb(R5WXYMRQ819oh0m0L8tf(gHDrmvmYC2merU4PHXEaeEdVGPgM(wiN2MowhAaYWObIHhhVXchECKpndhusuaETLPdAZRvVtIcYVVBaJWRWPnegDzkib7TImcS(uQG0ZtbL)6Oue5wxuqJO9LbeYZbdTpRrjZdzlvlVCC53qWeCq6JRFyJDJSgksp5XoYvzAajtpo1efmlC)oHgH7FN)HoMdbfjYPhU7vEmf9kdaboHITvZy9Z3UEMWuZMsIzTRsOsMnp0zKgIMq0lgDOUahKxe6qbBaRZinW6q(gwhMBZfmPrbb4fNWBuRdzN)g)Bs0ASbk52XkSv4knX22uFMs0Dkff4Sj)KtIIQrYzX5sVOvQZxt45nJSiq)6r2dhIAxrIjgL85dL6k6tQVvVkEimtF0zMXMcv9QjQAbPOj1fTpiW4)mCF5c11v)aO6pCp0Bu)0V9VD8xC3N)K)4XF3to(d(6fc3KElC8D()o9(FZZ(Z3(0)2V9OhD7JEC4EV9O)1dp5EF)))TFVj7(0h8G1o9(Fc8TN(dp4Kp9V8ZM081HHcKxaU8E3HHZ9cyuBWoDHnEzMDV2sQ35AlPAxRTOODS2ILLTx12PS(vwwFr(DNMM2I6RTWeY2kBHnw5hH8wfIkEdwv8crXrYU)aw4Oh94fuS)bw45p5o1o5b3)5p5JJg9MBOgq7ChNxWUxWUxWUNr2fscQaJ43otSA(Onx2m7otjngf8(IYQZaQZLDNHrQIYUZaQZLDNbvqrz3za1xWUxWUZi7MjstM3otSA(OvgBMtrULVKYDf24Xxk)DF54XX8II9D4wH71Uf1hpo18c2QiF9sRwmQStcqY6sYs1wFXcSBy1kvwY8X3U64XsFxTXJL9QvbuQikzry9YfK3l04wPZgZSmpir9dE84cq7Yfz0CRvb4q29lxoLfZY1QQ9Yk)(iwrBhrFUc5EkqTwbTivqTsNbT8wkWlyIdCNka2yNuQezadrw0KBqRZypNnYzbmHUWEEAn6uBpNDqykq9uBpNLAZh75S4LZEwaaYTN5ZuQPLHl5Yqv6sP7DEutxUix5f5kNrM5)SXwwPybaMLCLfe1tDSLlYvEH985R9S4CLfe1tT98)ZKRSYKDNSl)I0eFPMuWLPzDjnEIDPi5B6uQ3LDs2YqPS7pcE0lfUPIuP3JecObhafVzbYvn65PAKHYIPAua3urkvQgraWH8SgDMUOcAUPpfnmHzhfcr0ZSn9xo0)qBNnwUCQ9A)lRRfvi5mJJvaCiZbZWQDbf31opTpvGC5B(hbesbWtfrLSdIeqrzqwuh85HvSAKxufyEapveTqkqLqMLCxj)fwi)LS5CcTmnsvg(odPHEL5rVEpNqlJKldFZAwMj7EYD(8JV7xrdxD0J)WRC0J(7NC3BF67)d0yweOAu3CuqpxVKRQTHEUDSXNet6ofXVsCLelT9k8xiAt29LEj6XzIhY4D))Ld3BVBRFz7oBhDiyZC5Nvk8njx2zt2vihWC3QLg1X9kilYtQppb9ALeDkfesZOjyCz8EMAB2dc6Ljhx1TJR(p7E2Uu07SLF8XhpM9ArRi8q6z6eYfvPJgShMx6vOeKdShAsZwO(Uhq2wBriZNMDSfIUdphygy1BsZ62dE9fijFdagh4KzGJChUTz72KrCH(WGAHnLHWIz4GjDy8qzU2LtUpXWkG5aJQlHrLx1fhmczuDognMvbgK)CgqzuSL5LPh)xqmbgKZED0qwCKC5LLpMtofyPW)LyVkZkDjYwZBxSb1C7I4Axc(IVnUy500dsm3nxH6VIS1WeUTRMJB3k58l3oumKNZF6MB9QXWiB7)jxhXDHwesujTmvzlkk2uR)PslspFBn6m18M86KK6oiv6mr7zQXrN5ggvWvarzdJEHUwHNtT)mVUFonn)C26955sRpVWGvKb7l0fd8CQ)M51EZPP7MN9MBQiLB2uFXod8PglLE8AlW4EPyZBffMRTy5AllmD6IvROJvkz6K0o1QwQ8LuE2Kgpw1jxqttHmhAwWl44D)FP0I46qMU0QswZRu6(DwRQ2zJNzqTKYy2bSHOftohUQHsnRZmkPWVnstePIWSF0Ri3mrXMEVAQ3rkKo)QVqjxXrHuiA2NS3VtJhl(oDANvxUCi8cVjNIJ0L9wCsH5bZTAeRuN)1O0skGJ9kuIuapO6VXBqorjV9V46tAE1B8M8Jh2uRu0TavKdiByShwZQ7bGwZ2PZi84iEshcpWGSIyYrsnf4SZchmoZ6auBDwSWDVhr5gtxuQjaLASANA5(9WKByabFXdDzFK12vRulCMox9TUwYusbQf2)cSfWLtDaLP0V4nPUuCv(co)8CgDlBAj82MzNnkGB7QHbKLfScEn(KhXjKHN87ZMmMTz()3UUuKQu8m4Pj4YaB22pf3ISABi1BJ2imf33aSnwHsjMCMfNc2zVrbYI5itNiSUoXXm5q(xk8S(pfMcI(6O)HdMroS)PADeqyaN46PTdqdcD2t3vhPIknRRKZr4o6BkmyLSQY0Y0GvkR1MKPwuR)br3FpPCN604fG3v1soM3kOpyAc0WsITlmvqYxrp6ItZxepsIpe5rn6J2ZlfYdx)hLV6oCakzKrExju35HZKqQNsifmSW17YIiKQw5PsYNqQe5ixhpMJ)pwyuwMAj1vPk5esZo3rztCAh9QHopXfulYIonRl5C)MY0L3wG1yk9SNcDpNwPtlLxBQEBpJi88qU1zTVM7YT(lg5M)mZtwwQe7(0njERvfMkyB9QLWTENVhRYqtEcto9uGoRCvX9boAZsxkVZY(4X5brPClqsVQYO9IuwRsvwHPYRFZee4hKxHOHDeA84u1kQo(Icza0KGfN6pxymqnoMUOL1Y0tlLvWMREpVct54VIvskf0xavKsi05rbPPSGkC9O5oekVC0iuKS(CWepPxlJYEj3fYOiWWcb5UyuYltD9ksZWgD75T1MvL8rHxMICGV9AYGp6ocK)dO3VIHlfp79iyPYzUvfJA3g3Lh44XCxCGGdDMBsXSFB0Z5Veb1KjbI3qdjxvI4qhjc26vfju0hLAlhen708LQclb4myXCceHmjaG8l(qT0MGyEC7vecVYHqrRon5PCniHCTJ04Fp]] )
