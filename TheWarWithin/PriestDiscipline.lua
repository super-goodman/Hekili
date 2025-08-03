-- PriestDiscipline.lua
-- August 2025
-- Patch 11.2

if not Hekili.check then return end
if UnitClassBase( "player" ) ~= "PRIEST" then return end
SetCVar("autoSelfCast", 1)
local addon, ns = ...
local Hekili = _G[ addon ]
local class, state = Hekili.Class, Hekili.State
local spec = Hekili:NewSpecialization( 256 )

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

spec:RegisterResource( Enum.PowerType.Mana )

-- Talents
spec:RegisterTalents( {

    -- Priest
    angelic_bulwark                = {  82675,  108945, 1 }, -- When an attack brings you below $s1% health, you gain an absorption shield equal to $s2% of your maximum health for $s3 sec. Cannot occur more than once every $s4 sec
    angelic_feather                = {  82703,  121536, 1 }, -- Places a feather at the target location, granting the first ally to walk through it $s1% increased movement speed for $s2 sec. Only $s3 feathers can be placed at one time
    angels_mercy                   = {  82678,  238100, 1 }, -- Reduces the cooldown of Desperate Prayer by $s1 sec
    apathy                         = {  82689,  390668, 1 }, -- Your Mind Blast critical strikes reduce your target's movement speed by $s1% for $s2 sec
    benevolence                    = {  82676,  415416, 1 }, -- Increases the healing of your spells by $s1%
    binding_heals                  = {  82678,  368275, 1 }, -- $s1% of Flash Heal healing on other targets also heals you
    blessed_recovery               = {  82720,  390767, 1 }, -- After being struck by a melee or ranged critical hit, heal $s1% of the damage taken over $s2 sec
    body_and_soul                  = {  82706,   64129, 1 }, -- Power Word: Shield and Leap of Faith increase your target's movement speed by $s1% for $s2 sec
    cauterizing_shadows            = {  82687,  459990, 1 }, -- When your Shadow Word: Pain expires or is refreshed with less than $s1 sec remaining, a nearby ally within $s2 yards is healed for $s3
    crystalline_reflection         = {  82681,  373457, 2 }, -- Power Word: Shield instantly heals the target for $s1 and reflects $s2% of damage absorbed
    death_and_madness              = {  82711,  321291, 1 }, -- If your Shadow Word: Death fails to kill a target at or below $s1% health, its cooldown is reset. Cannot occur more than once every $s2 sec
    dispel_magic                   = {  82715,     528, 1 }, -- Dispels Magic on the enemy target, removing $s1 beneficial Magic effect
    divine_star                    = {  82682,  110744, 1 }, -- Throw a Divine Star forward $s2 yds, healing allies in its path for $s3 and dealing $s$s4 Holy damage to enemies. After reaching its destination, the Divine Star returns to you, healing allies and damaging enemies in its path again. Healing reduced beyond $s5 targets
    dominate_mind                  = {  82710,  205364, 1 }, -- Controls a mind up to $s1 level above yours for $s2 sec while still controlling your own mind. Does not work versus Demonic, Mechanical, or Undead beings or players. This spell shares diminishing returns with other disorienting effects
    essence_devourer               = {  82674,  415479, 1 }, -- Attacks from your Shadowfiend siphon life from enemies, healing a nearby injured ally for $s1. Attacks from your Mindbender siphon life from enemies, healing a nearby injured ally for $s2
    focused_mending                = {  82719,  372354, 1 }, -- Prayer of Mending does $s1% increased healing to the initial target
    from_darkness_comes_light      = {  82707,  390615, 1 }, -- Each time Shadow Word: Pain deals damage, the healing of your next Flash Heal is increased by $s1%, up to a maximum of $s2%
    halo                           = {  82682,  120517, 1 }, -- Creates a ring of Holy energy around you that quickly expands to a $s2 yd radius, healing allies for $s3 and dealing $s$s4 Holy damage to enemies. Healing reduced beyond $s5 targets
    holy_nova                      = {  82701,  132157, 1 }, -- An explosion of holy light around you deals up to $s$s2 Holy damage to enemies and up to $s3 healing to allies within $s4 yds, reduced if there are more than $s5 targets
    improved_fade                  = {  82686,  390670, 2 }, -- Reduces the cooldown of Fade by $s1 sec
    improved_flash_heal            = {  82714,  393870, 1 }, -- Increases healing done by Flash Heal by $s1%
    improved_purify                = {  82705,  390632, 1 }, -- Purify additionally removes all Disease effects
    inspiration                    = {  82696,  390676, 1 }, -- Reduces your target's physical damage taken by $s1% for $s2 sec after a critical heal with Flash Heal or Penance
    leap_of_faith                  = {  82716,   73325, 1 }, -- Pulls the spirit of a party or raid member, instantly moving them directly in front of you
    lights_inspiration             = {  82679,  373450, 2 }, -- Increases the maximum health gained from Desperate Prayer by $s1%
    manipulation                   = {  82672,  459985, 1 }, -- You take $s1% less damage from enemies affected by your Shadow Word: Pain
    mass_dispel                    = {  82699,   32375, 1 }, -- Dispels magic in a $s1 yard radius, removing all harmful Magic from $s2 friendly targets and $s3 beneficial Magic effect from $s4 enemy targets. Potent enough to remove Magic that is normally undispellable
    mental_agility                 = {  82698,  341167, 1 }, -- Reduces the mana cost of Purify and Mass Dispel by $s1% and Dispel Magic by $s2%
    mind_control                   = {  82710,     605, 1 }, -- Controls a mind up to $s1 level above yours for $s2 sec. Does not work versus Demonic, Undead, or Mechanical beings. Shares diminishing returns with other disorienting effects
    move_with_grace                = {  82702,  390620, 1 }, -- Reduces the cooldown of Leap of Faith by $s1 sec
    petrifying_scream              = {  82695,   55676, 1 }, -- Psychic Scream causes enemies to tremble in place instead of fleeing in fear
    phantasm                       = {  82556,  108942, 1 }, -- Activating Fade removes all snare effects
    phantom_reach                  = {  82673,  459559, 1 }, -- Increases the range of most spells by $s1%
    power_infusion                 = {  82694,   10060, 1 }, -- Infuses the target with power for $s1 sec, increasing haste by $s2%. Can only be cast on players
    power_word_life                = {  82676,  373481, 1 }, -- A word of holy power that heals the target for $s1 million. Only usable if the target is below $s2% health
    prayer_of_mending              = {  82718,   33076, 1 }, -- Places a ward on an ally that heals them for $s1 the next time they take damage, and then jumps to another ally within $s2 yds. Jumps up to $s3 times and lasts $s4 sec after each jump
    protective_light               = {  82707,  193063, 1 }, -- Casting Flash Heal on yourself reduces all damage you take by $s1% for $s2 sec
    psychic_voice                  = {  82695,  196704, 1 }, -- Reduces the cooldown of Psychic Scream by $s1 sec
    renew                          = {  82717,     139, 1 }, -- Fill the target with faith in the light, healing for $s1 over $s2 sec
    rhapsody                       = {  82700,  390622, 1 }, -- Every $s1 sec, the damage of your next Holy Nova is increased by $s2% and its healing is increased by $s3%. Stacks up to $s4 times
    sanguine_teachings             = {  82691,  373218, 1 }, -- Increases your Leech by $s1%
    sanlayn                        = {  82690,  199855, 1 }, --  Sanguine Teachings Sanguine Teachings grants an additional $s3% Leech.  Vampiric Embrace Reduces the cooldown of Vampiric Embrace by $s6 sec, increases its healing done by $s7%
    shackle_undead                 = {  82693,    9484, 1 }, -- Shackles the target undead enemy for $s1 sec, preventing all actions and movement. Damage will cancel the effect. Limit $s2
    shadow_word_death              = {  82712,   32379, 1 }, -- A word of dark binding that inflicts $s$s2 Shadow damage to your target. If your target is not killed by Shadow Word: Death, you take backlash damage equal to $s3% of your maximum health. Damage increased by $s4% to targets below $s5% health
    shadowfiend                    = {  82713,   34433, 1 }, -- Summons a shadowy fiend to attack the target for $s1 sec. Generates $s2% Mana each time the Shadowfiend attacks
    sheer_terror                   = {  82708,  390919, 1 }, -- Increases the amount of damage required to break your Psychic Scream by $s1%
    spell_warding                  = {  82720,  390667, 1 }, -- Reduces all magic damage taken by $s1%
    surge_of_light                 = {  82677,  109186, 1 }, -- Your healing spells and Smite have a $s1% chance to make your next Flash Heal instant and cost $s2% less mana. Stacks to $s3
    throes_of_pain                 = {  82709,  377422, 2 }, -- Shadow Word: Pain deals an additional $s1% damage. When an enemy dies while afflicted by your Shadow Word: Pain, you gain $s2% Mana
    tithe_evasion                  = {  82688,  373223, 1 }, -- Shadow Word: Death deals $s1% less damage to you
    translucent_image              = {  82685,  373446, 1 }, -- Fade reduces damage you take by $s1%
    twins_of_the_sun_priestess     = {  82683,  373466, 1 }, -- Power Infusion also grants you its effect at $s1% value when used on an ally. If no ally is targeted, it will grant its effect at $s2% value to a nearby ally, preferring damage dealers
    twist_of_fate                  = {  82684,  390972, 2 }, -- After damaging or healing a target below $s1% health, gain $s2% increased damage and healing for $s3 sec
    unwavering_will                = {  82697,  373456, 2 }, -- While above $s1% health, the cast time of your Flash Heal and Smite are reduced by $s2%
    vampiric_embrace               = {  82691,   15286, 1 }, -- Fills you with the embrace of Shadow energy for $s1 sec, causing you to heal a nearby ally for $s2% of any single-target Shadow spell damage you deal
    void_shield                    = {  82692,  280749, 1 }, -- When cast on yourself, $s1% of damage you deal refills your Power Word: Shield
    void_shift                     = {  82674,  108968, 1 }, -- Swap health percentages with your ally. Increases the lower health percentage of the two to $s1% if below that amount
    void_tendrils                  = {  82708,  108920, 1 }, -- Summons shadowy tendrils, rooting all enemies within $s1 yards for $s2 sec or until the tendril is killed
    words_of_the_pious             = {  82721,  377438, 1 }, -- For $s1 sec after casting Power Word: Shield, you deal $s2% additional damage and healing with Smite and Holy Nova

    -- Discipline
    abyssal_reverie                = {  82583,  373054, 2 }, -- Atonement heals for $s1% more when activated by Shadow spells
    atonement                      = {  82594,   81749, 1 }, -- Power Word: Shield, Flash Heal, Renew, Power Word: Radiance, and Power Word: Life apply Atonement to your target for $s1 sec. Your spell damage heals all targets affected by Atonement for $s2% of the damage done. Healing increased by $s3% when not in a raid
    blaze_of_light                 = {  82568,  215768, 2 }, -- The damage of Smite and Penance is increased by $s1%, and Penance increases or decreases your target's movement speed by $s2% for $s3 sec
    borrowed_time                  = {  82600,  390691, 2 }, -- Casting Power Word: Shield increases your Haste by $s1% for $s2 sec
    bright_pupil                   = {  82591,  390684, 1 }, -- Reduces the cooldown of Power Word: Radiance by $s1 sec
    castigation                    = {  82575,  193134, 1 }, -- Penance fires one additional bolt of holy light over its duration
    dark_indulgence                = {  82596,  372972, 1 }, -- Mind Blast has a $s1% chance to grant Power of the Dark Side and its mana cost is reduced by $s2%
    divine_aegis                   = {  82602,   47515, 1 }, -- Direct critical heals create a protective shield on the target, absorbing $s1% of the amount healed. Lasts $s2 sec
    divine_procession              = {  82599,  472361, 1 }, -- Smite extends the duration of an active Atonement by $s1 sec
    encroaching_shadows            = {  82590,  472568, 1 }, -- Shadow Word: Pain Spreads to $s1 nearby enemies when you cast Penance on the target
    enduring_luminescence          = {  82591,  390685, 1 }, -- Reduces the cast time of Power Word: Radiance by $s1% and causes it to apply Atonement at an additional $s2% of its normal duration
    eternal_barrier                = {  86730,  238135, 1 }, -- Power Word: Shield absorbs $s1% additional damage and lasts $s2 sec longer
    evangelism                     = {  82598,  472433, 1 }, -- Extends Atonement on all allies by $s1 sec and heals for $s2 million, split evenly among them
    expiation                      = {  82585,  390832, 2 }, -- Mind Blast and Shadow Word: Death consume $s1 sec of Shadow Word: Pain, dealing damage equal to $s2% of the amount consumed
    harsh_discipline               = {  82572,  373180, 2 }, -- Power Word: Radiance causes your next Penance to fire $s1 additional bolts, stacking up to $s2 charges
    indemnity                      = {  82576,  373049, 1 }, -- Atonements granted by Power Word: Shield last an additional $s1 sec
    inescapable_torment            = {  82586,  373427, 1 }, -- Penance, Mind Blast and Shadow Word: Death cause your Mindbender or Shadowfiend to teleport behind your target, slashing up to $s2 nearby enemies for $s$s3 Shadow damage and extending its duration by $s4 sec
    inner_focus                    = {  82601,  390693, 1 }, -- Flash Heal, Power Word: Shield, Penance, Power Word: Radiance, and Power Word: Life have a $s1% increased chance to critically heal
    lenience                       = {  82567,  238063, 1 }, -- Atonement reduces damage taken by $s1%
    lights_promise                 = {  82592,  322115, 1 }, -- Power Word: Radiance gains an additional charge
    luminous_barrier               = {  82564,  271466, 1 }, -- Create a shield on all allies within $s2 yards, absorbing $s$s3 million damage on each of them for $s4 sec. Absorption decreased beyond $s5 targets
    malicious_intent               = {  82580,  372969, 1 }, -- Increases the duration of Schism by $s1 sec
    mindbender                     = {  82584,  123040, 1 }, -- Summons a Mindbender to attack the target for $s1 sec. Generates $s2% Mana each time the Mindbender attacks
    overloaded_with_light          = {  82573,  421557, 1 }, -- Ultimate Penitence emits an explosion of light, healing up to $s1 allies around you for $s2 and applying Atonement at $s3% of normal duration
    pain_and_suffering             = {  82578,  390689, 2 }, -- Increases the damage of Shadow Word: Pain by $s1% and increases its duration by $s2 sec
    pain_suppression               = {  82587,   33206, 1 }, -- Reduces all damage taken by a friendly target by $s1% for $s2 sec. Castable while stunned
    pain_transformation            = {  82588,  372991, 1 }, -- Pain Suppression also heals your target for $s1% of their maximum health and applies Atonement
    painful_punishment             = {  82597,  390686, 1 }, -- Each Penance bolt extends the duration of Shadow Word: Pain on enemies hit by $s1 sec
    power_of_the_dark_side         = {  82595,  198068, 1 }, -- Shadow Word: Pain has a chance to empower your next Penance with Shadow, increasing its effectiveness by $s1%
    power_word_barrier             = {  82564,   62618, 1 }, -- Summons a holy barrier to protect all allies at the target location for $s1 sec, reducing all damage taken by $s2% and preventing damage from delaying spellcasting
    power_word_radiance            = {  82593,  194509, 1 }, -- A burst of light heals the target and $s1 injured allies within $s2 yards for $s3, and applies Atonement for $s4% of its normal duration
    protector_of_the_frail         = {  82588,  373035, 1 }, -- Pain Suppression gains an additional charge. Power Word: Shield reduces the cooldown of Pain Suppression by $s1 sec
    revel_in_darkness              = {  82566,  373003, 1 }, -- Shadow Word: Pain deals $s1% additional damage and spreads to $s2 additional target when you cast Penance to its target
    sanctuary                      = {  92225,  231682, 1 }, -- Smite prevents the next $s1 damage dealt by the enemy
    schism                         = {  82579,  424509, 1 }, -- Mind Blast fractures the enemy's mind, increasing your spell damage to the target by $s1% for $s2 sec
    shadow_covenant                = {  82581,  314867, 1 }, -- Casting Mindbender enters you into a shadowy pact, transforming Halo, Divine Star, and Penance into Shadow spells and increasing the damage and healing of your Shadow spells by $s1% while active
    shield_discipline              = {  82589,  197045, 1 }, -- When your Power Word: Shield is completely absorbed, you restore $s1% of your maximum mana
    twilight_corruption            = {  82582,  373065, 1 }, -- Shadow Covenant increases Shadow spell damage and healing by an additional $s1%
    twilight_equilibrium           = {  82571,  390705, 1 }, -- Your damaging Shadow spells increase the damage of your next Holy spell cast within $s1 sec by $s2%. Your damaging Holy spells increase the damage of your next Shadow spell cast within $s3 sec by $s4%
    ultimate_penitence             = {  82577,  421453, 1 }, -- Ascend into the air and unleash a massive barrage of Penance bolts, causing $s1 million Holy damage to enemies or $s2 million healing to allies over $s3 sec. While ascended, gain a shield for $s4% of your health. In addition, you are unaffected by knockbacks or crowd control effects
    void_summoner                  = {  82570,  390770, 1 }, -- Reduces the cooldown of Shadowfiend or Mindbender by $s1%
    weal_and_woe                   = {  82569,  390786, 1 }, -- Your Penance bolts increase the damage of your next Smite by $s1%, or the absorb of your next Power Word: Shield by $s2%. Stacks up to $s3 times

    -- Oracle
    assured_safety                 = {  94691,  440766, 1 }, -- Power Word: Shield casts apply $s1 stacks of Prayer of Mending to your target
    clairvoyance                   = {  94687,  428940, 1 }, -- Casting Premonition of Solace invokes Clairvoyance, expanding your mind and opening up all possibilities of the future.  Premonition of Clairvoyance Grants Premonition of Insight, Piety, and Solace at $s3% effectiveness
    desperate_measures             = {  94690,  458718, 1 }, -- Desperate Prayer lasts an additional $s1 sec. Angelic Bulwark's absorption effect is increased by $s2% of your maximum health
    divine_feathers                = {  94675,  440670, 1 }, -- Your Angelic Feathers increase movement speed by an additional $s1%. When an ally walks through your Angelic Feather, you are also granted $s2% of its effect
    fatebender                     = {  94700,  440743, 1 }, -- Increases the effects of Premonition by $s1%
    foreseen_circumstances         = {  94689,  440738, 1 }, -- Pain Suppression reduces damage taken by an additional $s1%
    miraculous_recovery            = {  94679,  440674, 1 }, -- Reduces the cooldown of Power Word: Life by $s1 sec and allows it to be usable on targets below $s2% health
    perfect_vision                 = {  94700,  440661, 1 }, -- Reduces the cooldown of Premonition by $s1 sec
    preemptive_care                = {  94674,  440671, 1 }, -- Increases the duration of Atonement and Renew by $s1 sec
    premonition                    = {  94683,  428924, 1 }, -- Gain access to a spell that gives you an advantage against your fate. Premonition rotates to the next spell when cast.  Premonition of Insight Reduces the cooldown of your next $s4 spell casts by $s5 sec.  Premonition of Piety Increases your healing done by $s8% and causes $s9% of overhealing on players to be redistributed to up to $s10 nearby allies for $s11 sec.  Premonition of Solace Your next single target healing spell grants your target a shield that absorbs $s$s14 million damage and reduces their damage taken by $s15% for $s16 sec
    preventive_measures            = {  94698,  440662, 1 }, -- Power Word: Shield absorbs $s2% additional damage$s$s3 All damage dealt by Penance, Smite and Holy Nova increased by $s4%
    prophets_will                  = {  94690,  433905, 1 }, -- Your Flash Heal and Power Word: Shield are $s1% more effective when cast on yourself
    save_the_day                   = {  94675,  440669, 1 }, -- For $s1 sec after casting Leap of Faith you may cast it a second time for free, ignoring its cooldown
    twinsight                      = {  94673,  440742, 1 }, -- $s1 additional Penance bolts are fired at an enemy within $s2 yards when healing an ally with Penance, or fired at an ally within $s3 yards when damaging an enemy with Penance
    waste_no_time                  = {  94679,  440681, 1 }, -- Premonition causes your next Power Word: Radiance cast to be instant and cost $s1% less mana

    -- Voidweaver
    collapsing_void                = {  94694,  448403, 1 }, -- Each time Penance damages or heals, Entropic Rift is empowered, increasing its damage and size by $s2%. After Entropic Rift ends it collapses, dealing $s$s3 Shadow damage split amongst enemy targets within $s4 yds
    dark_energy                    = {  94693,  451018, 1 }, -- While Entropic Rift is active, you move $s1% faster
    darkening_horizon              = {  94695,  449912, 1 }, -- Void Blast increases the duration of Entropic Rift by $s1 sec, up to a maximum of $s2 sec
    depth_of_shadows               = { 100212,  451308, 1 }, -- Shadow Word: Death has a high chance to summon a Shadowfiend for $s1 sec when damaging targets below $s2% health
    devour_matter                  = {  94668,  451840, 1 }, -- Shadow Word: Death consumes absorb shields from your target, dealing $s$s2 extra damage to them and granting you $s3% mana if a shield was present
    embrace_the_shadow             = {  94696,  451569, 1 }, -- You absorb $s1% of all magic damage taken. Absorbing Shadow damage heals you for $s2% of the amount absorbed
    entropic_rift                  = {  94684,  447444, 1 }, -- Mind Blast tears open an Entropic Rift that follows the enemy for $s2 sec. Enemies caught in its path suffer $s$s3 Shadow damage every $s4 sec while within its reach
    inner_quietus                  = {  94670,  448278, 1 }, -- Power Word: Shield absorbs $s1% additional damage
    no_escape                      = {  94693,  451204, 1 }, -- Entropic Rift slows enemies by up to $s1%, increased the closer they are to its center
    void_blast                     = {  94703,  450405, 1 }, -- Entropic Rift upgrades Smite into Void Blast while it is active. Void Blast: Sends a blast of cosmic void energy at the enemy, causing $s$s2 Shadow damage
    void_empowerment               = {  94695,  450138, 1 }, -- Summoning an Entropic Rift extends the duration of your $s1 shortest Atonements by $s2 sec
    void_infusion                  = {  94669,  450612, 1 }, -- Atonement healing with Void Blast is $s1% more effective
    void_leech                     = {  94696,  451311, 1 }, -- Every $s1 sec siphon an amount equal to $s2% of your health from an ally within $s3 yds if they are higher health than you
    voidheart                      = {  94692,  449880, 1 }, -- While Entropic Rift is active, your Atonement healing is increased by $s1%
    voidwraith                     = { 100212,  451234, 1 }, -- Transform your Shadowfiend or Mindbender into a Voidwraith. Voidwraith Summon a Voidwraith for $s3 sec that casts Void Flay from afar. Void Flay deals bonus damage to high health enemies, up to a maximum of $s4% if they are full health. Generates $s5% Mana each time the Voidwraith attacks
} )

-- Auras
spec:RegisterAuras( {
    apathy = {
        id = 390669,
        duration = 4,
        max_stack = 1
    },
    archangel = {
        id = 197862,
        duration = 15,
        max_stack = 1
    },
    atonement = {
        id = 194384,
        duration = 15,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    body_and_soul = {
        id = 65081,
        duration = 3,
        max_stack = 1
    },
    borrowed_time = {
        id = 390692,
        duration = 4,
        max_stack = 1
    },
    dark_archangel = {
        id = 197871,
        duration = 8,
        max_stack = 1
    },
    death_and_madness_debuff = {
        id = 322098,
        duration = 7,
        max_stack = 1
    },
    depth_of_the_shadows = {
        id = 390617,
        duration = 15,
        max_stack = 50
    },
    desperate_prayer = {
        id = 19236,
        duration = 10,
        tick_time = 1,
        max_stack = 1
    },
    dominate_mind = {
        id = 205364,
        duration = 30,
        max_stack = 1
    },
    fade = {
        id = 586,
        duration = 10,
        max_stack = 1
    },
    focused_will = {
        id = 45242,
        duration = 8,
        max_stack = 1
    },
    from_darkness_comes_light = {
        id = 390617,
        duration = 30,
        max_stack = 20
    },
    harsh_discipline = {
        id = 373183,
        duration = 30,
        max_stack = 2,
        copy = "harsh_discipline_ready"
    },
    inspiration = {
        id = 390677,
        duration = 15,
        max_stack = 1
    },
    leap_of_faith = {
        id = 73325,
        duration = 1.5,
        max_stack = 1
    },
    levitate = {
        id = 1706,
        duration = 600,
        max_stack = 1
    },
    -- Absorbs $w1 damage.
    luminous_barrier = {
        id = 271466,
        duration = 10.0,
        max_stack = 1,
        dot = "buff"
    },
    mind_control = {
        id = 605,
        duration = 30,
        max_stack = 1
    },
    mind_soothe = {
        id = 453,
        duration = 20,
        max_stack = 1
    },
    mind_vision = {
        id = 2096,
        duration = 60,
        max_stack = 1
    },
    mindgames = {
        id = 375901,
        duration = function() return talent.shattered_perceptions.enabled and 7 or 5 end,
        max_stack = 1
    },
    pain_suppression = {
        id = 33206,
        duration = 8,
        max_stack = 1,
        dot = "buff",
        shared = "player"
    },
    power_of_the_dark_side = {
        id = 198069,
        duration = 20,
        max_stack = 1
    },
    power_word_barrier = { -- TODO: Check for totem to help correct for remaining time.
        id = 81782,
        duration = 12,
        max_stack = 1
    },
    power_word_fortitude = {
        id = 21562,
        duration = 3600,
        max_stack = 1,
        shared = "player", -- use anyone's buff on the player
        dot = "buff",
        friendly = true
    },
    power_word_shield = {
        id = 17,
        duration = function() return 15 + ( 5 * talent.eternal_barrier.rank ) end,
        tick_time = 1,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    prayer_of_mending = {
        id = 41635,
        duration = 30,
        max_stack = 5,
        dot = "buff",
        friendly = true
    },
    --dc
    premonition_of_insight = {
        id = 428933,
        duration = 20,
        max_stack = 3
    },
    --qc active_hot.atonement
    premonition_of_piety = {
        id = 428930,
        duration = 15,
        max_stack = 1
    },
    --wj
    premonition_of_solace = {
        id = 428934,
        duration = 20,
        max_stack = 1
    },
    premonition_of_solace_absorb = {
        id = 443526,
        duration = 15,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    psychic_scream = {
        id = 8122,
        duration = 8,
        max_stack = 1
    },
    --[[purge_the_wicked = {
        id = 204213,
        duration = 20,
        tick_time = function () return 2 * haste end,
        max_stack = 1
    },--]]
    --[[rapture = {
        id = 47536,
        duration = 8,
        max_stack = 3
    },--]]
    renew = {
        id = 139,
        duration = 15,
        tick_time = 3,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    schism = {
        id = 214621,
        duration = function() return talent.malicious_intent.enabled and 15 or 9 end,
        max_stack = 1
    },
    shackle_undead = {
        id = 9484,
        duration = 50,
        max_stack = 1
    },
    shadow_covenant = {
        id = 322105,
        duration = 7,
        max_stack = 1
    },
    shadow_word_pain = {
        id = 589,
        duration = 16,
        tick_time = 2,
        max_stack = 1
    },
    shadowfiend = {
        id = 34433,
        duration = 15,
        type = "Magic",
        max_stack = 1,
        generate = function( t, auraType )
            if auraType == "debuff" then return end

            local remains = pet.shadowfiend.remains
            if remains == 0 then return end

            t.expires = query_time + remains
            t.applied = t.expires - 15
            t.count = 1
        end
    },
    mindbender = {
        duration = 15,
        max_stack = 1,
        generate = function( t, auraType )
            if auraType == "debuff" then return end

            local remains = pet.mindbender.remains
            if remains == 0 then return end

            t.expires = query_time + remains
            t.applied = t.expires - 15
            t.count = 1
        end
    },
    voidwraith = {
        duration = 15,
        max_stack = 1,
        generate = function( t, auraType )
            if auraType == "debuff" then return end

            local remains = pet.voidwraith.remains
            if remains == 0 then return end

            t.expires = query_time + remains
            t.applied = t.expires - 15
            t.count = 1
        end
    },
    shield_of_absolution = {
        id = 394624,
        duration = 15,
        max_stack = 1,
        dot = "buff",
        friendly = true
    },
    surge_of_light = {
        id = 114255,
        duration = 20,
        max_stack = 2
    },
    tools_of_the_cloth = {
        id = 390933,
        duration = 12,
        max_stack = 1
    },
    twilight_equilibrium_holy_amp = {
        id = 390706,
        duration = 6,
        max_stack = 1
    },
    twilight_equilibrium_shadow_amp = {
        id = 390707,
        duration = 6,
        max_stack = 1
    },
    twist_of_fate = {
        id = 390978,
        duration = 8,
        max_stack = 1
    },
    ultimate_penitence = {
        id = 421453,
        duration = 6,
        max_stack = 1,
        copy = 421454,
        dot = "buff",
        friendly = true
    },
    vampiric_embrace = {
        id = 15286,
        duration = 15,
        tick_time = 0.5,
        max_stack = 1
    },
    void_tendrils = {
        id = 108920,
        duration = 0.5,
        max_stack = 1
    },
    waste_no_time = {
        id = 440683,
        duration = 20,
        max_stack = 1
    },
    weal_and_woe = {
        id = 390787,
        duration = 20,
        max_stack = 7
    },
    words_of_the_pious = {
        id = 390933,
        duration = 12,
        max_stack = 1
    },
    wrath_unleashed = {
        id = 390782,
        duration = 15,
        max_stack = 1
    },
    light_weaving = {
        id = 394609,
        duration = 15,
        max_stack = 1
    },
} )

spec:RegisterGear({
    -- The War Within
    tww3 = {
        items = { 237710, 237708, 237709, 237712, 237707 },
        auras = {
            -- Oracle
            visionary_velocity = {
                id = 1239609,
                duration = 10,
                max_stack = 10
            },
            -- Voidweaver
            overflowing_void = {
                id = 1237615,
                duration = 3600,
                max_stack = 1
            },
        }
    },
    tww2 = {
        items = { 229334, 229332, 229337, 229335, 229333 }
    },
    tww1 = {
        items = { 212084, 212083, 212081, 212086, 212082 },
        auras = {
            darkness_from_light = {
                id = 455033,
                duration = 30,
                max_stack = 3
            }
        }
    },
    -- Dragonflight
    tier29 = {
        items = { 200327, 200329, 200324, 200326, 200328 }
    },
    tier30 = {
        items = { 202543, 202542, 202541, 202545, 202540 },
        auras = {
            radiant_providence = {
                id = 410638,
                duration = 3600,
                max_stack = 2
            }
        }
    },
    tier31 = {
        items = { 207279, 207280, 207281, 207282, 207284, 217202, 217204, 217205, 217201, 217203 }
    }
} )

spec:RegisterStateTable( "priest", {
    self_power_infusion = true
} )

local holy_schools = {
    holy = true,
    holyfire = true
}

local entropic_rift_expires = 0
local er_extensions = 0

spec:RegisterHook( "COMBAT_LOG_EVENT_UNFILTERED", function( _, subtype, _, sourceGUID, _, _, _, _, _, _, _, spellID )
    if sourceGUID ~= GUID then return end

    if ( subtype == "SPELL_AURA_APPLIED" or subtype == "SPELL_AURA_REFRESH" ) and spellID == 450193 then
        entropic_rift_expires = GetTime() + 8 -- Assuming it will re-refresh from VT ticks and be caught by SPELL_AURA_REFRESH.
        er_extensions = 0
        return

    elseif state.talent.darkening_horizon.enabled and subtype == "SPELL_CAST_SUCCESS" and er_extensions < 3 and spellID == 450405 and entropic_rift_expires > GetTime() then
        entropic_rift_expires = entropic_rift_expires + 1
        er_extensions = er_extensions + 1
    end

end, false )

spec:RegisterStateExpr( "rift_extensions", function()
    return er_extensions
end )

local premonitions = {
    insight = "premonition_of_insight",
    piety = "premonition_of_piety",
    solace = "premonition_of_solace",
    clairvoyance = "premonition_of_clairvoyance"
}

spec:RegisterHook( "reset_precast", function ()
    if talent.premonition.enabled then
        local charge = min( cooldown.premonition_of_insight.charge, cooldown.premonition_of_solace.charge, cooldown.premonition_of_piety.charge, cooldown.premonition_of_clairvoyance.charge )
        local start = max( cooldown.premonition_of_insight.recharge_began, cooldown.premonition_of_solace.recharge_began, cooldown.premonition_of_piety.recharge_began, cooldown.premonition_of_clairvoyance.recharge_began )
        local duration = talent.perfect_vision.enabled and 45 or 60

        for _, v in pairs( premonitions ) do
            local cd = cooldown[ v ]
            cd.charge = charge
            cd.recharge_began = start
            cd.duration = duration
            cd.recharge = duration
        end
    end

    if buff.voidheart.up then
        applyBuff( "entropic_rift", buff.voidheart.remains )
    elseif entropic_rift_expires > query_time then
        applyBuff( "entropic_rift", entropic_rift_expires - query_time )
    end

    rift_extensions = nil
end )

spec:RegisterHook( "TALENTS_UPDATED", function()
    -- For ability/cooldown, Mindbender takes precedent.
    local sf = talent.mindbender.enabled and "mindbender_actual" or talent.voidwraith.enabled and "voidwraith" or "shadowfiend"

    class.abilities.shadowfiend = class.abilities[ sf ]
    class.abilities.mindbender = class.abilities.mindbender_actual

    rawset( cooldown, "shadowfiend", cooldown[ sf ] )
    rawset( cooldown, "mindbender", cooldown.mindbender_actual )
    rawset( cooldown, "fiend", cooldown.shadowfiend )

    -- For totem/pet/buff, Voidwraith takes precedent.
    sf = talent.voidwraith.enabled and "voidwraith" or talent.mindbender.enabled and "mindbender" or "shadowfiend"

    class.totems.fiend = spec.totems[ sf ]
    totem.fiend = totem[ sf ]
    pet.fiend = pet[ sf ]
    buff.fiend = buff[ sf ]
end )

spec:RegisterTotems( {
    mindbender = {
        id = 136214,
        copy = "mindbender_actual"
    },
    shadowfiend = {
        id = 136199,
        copy = "shadowfiend_actual"
    },
    voidwraith = {
        id = 615099
    },
} )

spec:RegisterHook( "runHandler", function( action )
    if talent.twilight_equilibrium.enabled then
        local ability = class.abilities[ action ]
        if not ability then return end
        local school = ability.school

        if school and ability.damage then
            if holy_schools[ school ] and ( buff.twilight_equilibrium_holy_amp.up or buff.twilight_equilibrium_shadow_amp.down ) then
                removeBuff( "twilight_equilibrium_holy_amp" )
                applyBuff( "twilight_equilibrium_shadow_amp" )
            elseif school == "shadow" and ( buff.twilight_equilibrium_shadow_amp.up or buff.twilight_equilibrium_holy_amp.down )  then
                removeBuff( "twilight_equilibrium_shadow_amp" )
                applyBuff( "twilight_equilibrium_holy_amp" )
            end
        end
    end
end )

local InescapableTorment = setfenv( function ()
    if buff.mindbender.up then buff.mindbender.expires = buff.mindbender.expires + 0.7
    elseif buff.shadowfiend.up then buff.shadowfiend.expires = buff.shadowfiend.expires + 0.7
    elseif buff.voidwraith.up then buff.voidwraith.expires = buff.voidwraith.expires + 0.7
    end
end, state )

local insight_value = 7

spec:RegisterHook( "runHandler", function( a )
    -- Note: setCooldown will have already run in regular ability flow.
    if buff.premonition_of_insight.up then
        reduceCooldown( a, insight_value )
        removeStack( "premonition_of_insight" )
        if set_bonus.tww3 >= 4 and hero_tree.oracle then addStack( "visionary_velocity" ) end
    end
end )

local Solace = setfenv( function ()
    if buff.premonition_of_solace.down then return end
    applyBuff( "premonition_of_solace_absorb" )
    removeBuff( "premonition_of_solace" )
end, state )

-- Abilities
spec:RegisterAbilities( {
    archangel = {
        id = 197862,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "holy",

        pvptalent = "archangel",
        startsCombat = false,
        texture = 458225,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "archangel" )
        end,
    },


    dark_archangel = {
        id = 197871,
        cast = 0,
        cooldown = 60,
        gcd = "spell",
        school = "shadow",

        pvptalent = "dark_archangel",
        startsCombat = false,
        texture = 1445237,

        toggle = "cooldowns",

        handler = function ()
            applyBuff( "dark_arkangel" )
        end,
    },


    divine_star = {
        id = function() return buff.shadow_covenant.up and 122121 or 110744 end,
        known = 110744,
        flash = { 122121, 110744 },
        cast = 0,
        cooldown = 15,
        gcd = "spell",
        school = function() return buff.shadow_covenant.up and "shadow" or "holy" end,
        damage = 1,

        spend = 0.02,
        spendType = "mana",

        talent = "divine_star",
        startsCombat = true,
        texture = function() return buff.shadow_covenant.up and 631519 or 537026 end,

        handler = function ()
        end,

        copy = { 122121, 110744 }
    },


    evangelism = {
        id = 472433,
        cast = 0,
        cooldown = 90,
        gcd = "spell",
        school = "holy",

        talent = "evangelism",
        startsCombat = false,
        texture = 135895,

        toggle = "cooldowns",

        handler = function ()
            if buff.atonement.up then buff.atonement.expires = buff.atonement.expires + 6 end
        end,
    },


    flash_heal = {
        id = 2061,
        cast = 1.5,
        cooldown = 0,
        gcd = "spell",
        school = "holy",

        spend = function() return 0.04 * ( buff.surge_of_light.up and 0.5 or 1 )end,
        spendType = "mana",

        startsCombat = false,
        texture = 135907,

        handler = function ()
            removeBuff( "from_darkness_comes_light" )
            removeStack( "surge_of_light" )
            if talent.protective_light.enabled then applyBuff( "protective_light" ) end
            Solace()
            applyBuff( "atonement" )
        end,
    },


    halo = {
        id = function() return buff.shadow_covenant.up and 120644 or 120517 end,
        known = 120517,
        flash = { 120644, 120517 },
        cast = 1.5,
        cooldown = 40,
        gcd = "spell",
        school = function() return buff.shadow_covenant.up and "shadow" or "holy" end,
        damage = 1,

        spend = 0.03,
        spendType = "mana",

        talent = "halo",
        startsCombat = false,
        texture = function() return buff.shadow_covenant.up and 632353 or 632352 end,

        handler = function ()
        end,

        copy = { 120644, 120517 }
    },

    -- Embrace the light, reducing the mana cost of healing spells by $s1%.
    inner_light_and_shadow = {
        id = 356085,
        cast = 0,
        cooldown = 6,
        gcd = "spell",

        spend = 0.010,
        spendType = "mana",

        pvptalent = "inner_light_and_shadow",
        startsCombat = false,

        handler = function()
            if buff.inner_shadow.up then
                removeBuff( "inner_shadow" )
                applyBuff( "inner_light" )
            else
                removeBuff( "inner_light" )
                applyBuff( "inner_shadow" )
            end
        end,

        copy = { "inner_light", "inner_shadow", 355897, 355898 }

        -- Effects:
        -- #0: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': -10.0, 'target': TARGET_UNIT_CASTER, 'modifies': POWER_COST, }
        -- #1: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': -10.0, 'target': TARGET_UNIT_CASTER, 'modifies': IGNORE_SHAPESHIFT, }
        -- #2: { 'type': APPLY_AURA, 'subtype': ADD_PCT_MODIFIER, 'points': -10.0, 'target': TARGET_UNIT_CASTER, 'modifies': POWER_COST, }
        -- #3: { 'type': APPLY_AURA, 'subtype': OVERRIDE_ACTIONBAR_SPELLS_TRIGGERED, 'points': 355898.0, 'value': 355897, 'schools': ['physical', 'nature', 'frost', 'shadow'], 'value1': 2, 'target': TARGET_UNIT_CASTER, }
    },

    --[[ lights_wrath = {
        id = 373178,
        cast = function() return talent.wrath_unleashed.enabled and 1.5 or 2.5 end,
        cooldown = 90,
        gcd = "spell",
        school = "holyfire",
        damage = 1,

        talent = "lights_wrath",
        startsCombat = false,
        texture = 1271590,

        toggle = "cooldowns",

        handler = function ()
        end,
    }, ]]

    -- Talent: Create a shield on all allies within $A1 yards, absorbing $s1 damage on each of them for $d.; Absorption increased by $s2% when not in a raid.
    luminous_barrier = {
        id = 271466,
        cast = 0.0,
        cooldown = 180.0,
        gcd = "spell",

        spend = 0.040,
        spendType = 'mana',

        talent = "luminous_barrier",
        startsCombat = false,

        handler = function()
            applyBuff( "luminous_barrier" )
            active_dot.luminous_barrier = group_members
        end,
    },

    -- Talent: Summons a Mindbender to attack the target for $d.     |cFFFFFFFFGenerates ${$123051m1/100}.1% mana each time the Mindbender attacks.|r
    mindbender = {
        id = function() return state.spec.shadow and 200174 or 123040 end,
        known = 34433,
        flash = { 34433, 123040, 200174, 451235 },
        cast = 0,
        cooldown = 30,
        gcd = "spell",
        school = "shadow",

        talent = "mindbender",
        startsCombat = true,
        texture = 136214,

        handler = function ()
            local sf = talent.voidwraith.enabled and "voidwraith" or "mindbender"
            summonPet( sf, 12 )
            applyBuff( sf )
            if talent.shadow_covenant.enabled then applyBuff( "shadow_covenant" ) end
        end,

        bind = { "shadowfiend", "voidwraith" },

        copy = { "mindbender_actual", 123040, 200174 }
    },

    shadowfiend = {
        id = 34433,
        flash = { 34433, 123040, 200174, 451235 },
        cast = 0,
        cooldown = function() return talent.void_summoner.enabled and 90 or 180 end,
        gcd = "spell",
        school = "shadow",

        toggle = "cooldowns",

        notalent = function() return talent.mindbender.enabled and "mindbender" or "voidwraith" end,

        startsCombat = true,
        texture = 136199,

        handler = function ()
            summonPet( "shadowfiend" )
            applyBuff( "shadowfiend" )

            if talent.shadow_covenant.enabled then applyBuff( "shadow_covenant" ) end
        end,

        bind = { "mindbender", "voidwraith" },

        copy = "shadowfiend_actual"
    },

    voidwraith = {
        id = 451235,
        known = 34433,
        flash = { 34433, 123040, 200174, 451235 },
        cast = 0,
        cooldown = function() return talent.void_summoner.enabled and 90 or 180 end,
        gcd = "spell",
        school = "shadow",

        toggle = "cooldowns",

        talent = "voidwraith",
        notalent = "mindbender",

        startsCombat = true,
        texture = 615099,

        handler = function ()
            summonPet( "voidwraith" )
            applyBuff( "voidwraith" )

            if talent.shadow_covenant.enabled then applyBuff( "shadow_covenant" ) end
        end,

        bind = { "shadowfiend", "mindbender" }
    },

    mind_blast = {
        id = 8092,
        cast = 1.5,
        cooldown = 9,
        gcd = "spell",
        school = "shadow",
        damage = 1,

        spend = function() return talent.dark_indulgence.enabled and 0.0015 or 0.0025 end,
        spendType = "mana",

        startsCombat = true,
        texture = 136224,

        handler = function ()
            if talent.entropic_rift.enabled then
                applyBuff( "entropic_rift" )
                if talent.voidheart.enabled then applyBuff( "voidheart" ) end
            end
            if talent.manipulation.enabled then
                reduceCooldown( "mindgames", 0.5 * talent.manipulation.rank )
            end
            if talent.inescapable_torment.enabled then InescapableTorment() end

            local swp_reduction = 3 * talent.expiation.rank
            if swp_reduction > 0 then debuff.shadow_word_pain.expires = max( 0, debuff.shadow_word_pain.expires - swp_reduction ) end
        end,
    },

    -- Reduces all damage taken by a friendly target by $s1% for $d. Castable while stunned.
    pain_suppression = {
        id = 33206,
        cast = 0.0,
        charges = function() if talent.protector_of_the_frail.enabled then return 2 end end,
        cooldown = 180,
        recharge = function() if talent.protector_of_the_frail.enabled then return 180 end end,
        gcd = "off",

        spend = 0.016,
        spendType = 'mana',

        talent = "pain_suppression",
        startsCombat = false,

        handler = function()
            applyBuff( "pain_suppression" )

            if talent.pain_transformation.enabled then
                gain( 0.15 * health.max, "health" )
                applyBuff( "atonement" )
            end
        end,

        -- Effects:
        -- #0: { 'type': APPLY_AURA, 'subtype': MOD_DAMAGE_PERCENT_TAKEN, 'points': -40.0, 'schools': ['physical', 'holy', 'fire', 'nature', 'frost', 'shadow', 'arcane'], 'target': TARGET_UNIT_TARGET_ALLY, }

        -- Affected by:
        -- protector_of_the_frail[373035] #2: { 'type': APPLY_AURA, 'subtype': MOD_MAX_CHARGES, 'points': 1.0, 'target': TARGET_UNIT_CASTER, }
    },

    penance = {
        id = function() return buff.shadow_covenant.up and 400169 or 47540 end,
        known = 47540,
        flash = { 400169, 47540 },
        cast = 2,
        channeled = true,
        breakable = true,
        cooldown = 9,
        gcd = "spell",
        school = function() return buff.shadow_covenant.up and "shadow" or "holy" end,
        damage = 1,
        bolts = function() return 3 + talent.castigation.rank + ( buff.harsh_discipline.up and ( buff.harsh_discipline.stack * talent.harsh_discipline.rank ) or 0 ) end,

        spend = function()
            if buff.harsh_discipline.up then return 0 end
            return 0.016 * ( buff.inner_light.up and 0.9 or 1 )
        end,
        spendType = "mana",

        startsCombat = true,
        texture = function() return buff.shadow_covenant.up and 1394892 or 237545 end,

        start = function ()
            removeBuff( "power_of_the_dark_side" )
            removeStack( "harsh_discipline" )

            if set_bonus.tier29_4pc > 0 then applyBuff( "shield_of_absolution" ) end
            if talent.inescapable_torment.enabled then InescapableTorment() end
            if talent.manipulation.enabled then reduceCooldown( "mindgames", 0.5 * talent.manipulation.rank ) end

            if debuff.shadow_word_pain.up then
                if talent.painful_punishment.enabled then
                    debuff.shadow_word_pain.expires = debuff.shadow_word_pain.expires + ( 1.5 * spec.abilities.penance.bolts )
                end
                if talent.encroaching_shadows.enabled then
                    active_dot.shadow_word_pain = max( active_enemies, ( active_dot.shadow_word_pain + 2 + talent.revel_in_darkness.rank ) )
                end
            end

            Solace()

            if talent.weal_and_woe.enabled then
                addStack( "weal_and_woe", spec.abilities.penance.bolts )
            end
            if talent.void_summoner.enabled then
                reduceCooldown( "mindbender", 4 )
            end

            setCooldown( buff.shadow_covenant.up and "penance" or "dark_reprimand", action.penance.cooldown )
        end,

        copy = { 47540, 186720, 400169, "dark_reprimand" }

    },

    power_infusion = {
        id = 10060,
        cast = 0,
        cooldown = 120,
        gcd = "off",
        school = "holy",

        toggle = "cooldowns",
        talent = "power_infusion",
        startsCombat = false,
        indicator = function () return group and ( talent.twins_of_the_sun_priestess.enabled or legendary.twins_of_the_sun_priestess.enabled ) and "cycle" or nil end,

        handler = function ()
            applyBuff( "power_infusion" )
            stat.haste = stat.haste + 0.25
        end,
    },

    -- Summons a holy barrier to protect all allies at the target location for $d, reducing all damage taken by $81782s2% and preventing damage from delaying spellcasting.
    power_word_barrier = {
        id = 62618,
        cast = 0,
        cooldown = 180,
        gcd = "spell",
        school = "holy",

        spend = 0.04,
        spendType = "mana",

        talent = "power_word_barrier",
        startsCombat = false,

        handler = function()
            applyBuff( "power_word_barrier" )
        end,

        -- Effects:
        -- #0: { 'type': CREATE_AREATRIGGER, 'subtype': NONE, 'value': 1489, 'schools': ['physical', 'frost', 'arcane'], 'radius': 8.0, 'target': TARGET_UNIT_DEST_AREA_ALLY, }
    },

    purify = {
        id = 527,
        cast = 0,
        cooldown = 8,
        gcd = "spell",

        spend = function() return 0.013 * ( talent.mental_agility.enabled and 0.5 or 1 ) end,
        spendType = "mana",
        toggle = "defensives",
        startsCombat = false,
        texture = 135894,


        target = function ()
            if debuff.dispellable_magic.up then
                return debuff.dispellable_magic.caster
            elseif  debuff.dispellable_disease.up then
                return debuff.dispellable_disease.caster 
            elseif  Hekili:isMouseOverMemberDispelable("Magic") then
                return "mouseover"
            end
        end,
        usable = function ()
            return debuff.dispellable_magic.up or debuff.dispellable_disease.up and talent.improved_purify.enabled or Hekili:isMouseOverMemberDispelable("Magic"), "requires magic, dispellable curse"
        end,
        handler = function ()
            removeDebuff( "player", "dispellable_magic" )
            if talent.improved_purify.enabled then
                removeDebuff( "player", "dispellable_disease" )
            end
        end,
    },



    power_word_radiance = {
        id = 194509,
        cast = function() return ( buff.radiant_providence.up or buff.waste_no_time.up ) and 0 or ( 2 * ( talent.enduring_luminescence.enabled and 0.7 or 1 ) ) end,
        charges = function() if talent.lights_promise.enabled then return 2 end end,
        cooldown = function() return 18 - ( 3 * talent.bright_pupil.rank ) end,
        recharge = function() if talent.lights_promise.enabled then return 18 - ( 3 * talent.bright_pupil.rank ) end end,
        gcd = "spell",
        school = "radiant",

        spend = function() return 0.05 * ( buff.waste_no_time.up and 0.85 or 1 ) end,
        spendType = "mana",

        talent = "power_word_radiance",
        startsCombat = false,
        texture = 1386546,

        handler = function ()
            if buff.atonement.down then
                applyBuff( "atonement", ( ( talent.enduring_luminescence.enabled and 0.7 or 0.6 ) * class.auras.atonement.duration ) + ( buff.radiant_providence.up and 3 or 0 ) )
                active_dot.atonement = min( active_dot.atonement + 3, group_members )
            else
                active_dot.atonement = min( active_dot.atonement + 4, group_members )
            end

            if talent.harsh_discipline.enabled then addStack( "harsh_discipline" ) end

            if buff.radiant_providence.up then
                removeStack( "radiant_providence" )
            elseif buff.waste_no_time.up then
                removeStack( "waste_no_time" )
            end
        end,
    },

    power_word_shield = {
        id = 17,
        cast = 0,
        cooldown = 7.5,
        gcd = "spell",

        spend = 0.03,
        spendType = "mana",

        startsCombat = false,
        texture = 135940,
        hot_id = 17,

        handler = function ()
            applyBuff( "power_word_shield" )
            applyBuff( "atonement" )
            removeBuff( "weal_and_woe" )

            if talent.borrowed_time.enabled then
                applyBuff( "borrowed_time" )
            end

            if talent.words_of_the_pious.enabled then
                applyBuff( "words_of_the_pious" )
            end

            if talent.body_and_soul.enabled then
                applyBuff( "body_and_soul" )
            end
        end,
    },

    premonition_of_insight = {
        id = 428933,
        cast = 0,
        charges = 2,
        cooldown = function() return talent.perfect_vision.enabled and 45 or 60 end,
        recharge = function() return action.premonition_of_insight.cooldown end,
        gcd = "off",

        talent = "premonition",

        handler = function()
            applyBuff( "premonition_of_insight", nil, 3 )

            spendCharges( "premonition_of_clairvoyance", 1 )
            spendCharges( "premonition_of_piety", 1 )
            spendCharges( "premonition_of_solace", 1 )
        end,
    },

    premonition_of_clairvoyance = {
        id = 440725,
        cast = 0,
        charges = 2,
        cooldown = function() return talent.perfect_vision.enabled and 45 or 60 end,
        recharge = function() return action.premonition_of_insight.cooldown end,
        gcd = "off",

        talent = "premonition",

        handler = function()
            applyBuff( "premonition_of_insight" )
            applyBuff( "premonition_of_piety" )
            applyBuff( "premonition_of_solace" )

            spendCharges( "premonition_of_insight", 1 )
            spendCharges( "premonition_of_piety", 1 )
            spendCharges( "premonition_of_solace", 1 )
        end,
    },

    premonition_of_piety = {
        id = 428930,
        cast = 0,
        charges = 2,
        cooldown = function() return talent.perfect_vision.enabled and 45 or 60 end,
        recharge = function() return action.premonition_of_insight.cooldown end,
        gcd = "off",

        talent = "premonition",

        handler = function()
            applyBuff( "premonition_of_piety" )

            spendCharges( "premonition_of_clairvoyance", 1 )
            spendCharges( "premonition_of_insight", 1 )
            spendCharges( "premonition_of_solace", 1 )
            if set_bonus.tww3 >= 4 and hero_tree.oracle then addStack( "premonition_of_insight", nil, 2) end --self
        end,
    },

    premonition_of_solace = {
        id = 428934,
        cast = 0,
        charges = 2,
        cooldown = function() return talent.perfect_vision.enabled and 45 or 60 end,
        recharge = function() return action.premonition_of_insight.cooldown end,
        gcd = "off",

        talent = "premonition",

        handler = function()
            applyBuff( "premonition_of_solace" )

            spendCharges( "premonition_of_clairvoyance", 1 )
            spendCharges( "premonition_of_insight", 1 )
            spendCharges( "premonition_of_piety", 1 )
            if set_bonus.tww3 >= 4 and hero_tree.oracle then addStack( "premonition_of_insight", nil, 2) end --self
        end,
    },

    renew = {
        id = 139,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "holy",
        hot_id = 139,
        spend = 0.02,
        spendType = "mana",

        talent = "renew",
        startsCombat = false,
        texture = 135953,

        handler = function ()
            applyBuff( "renew" )
            Solace()

            applyBuff( "atonement" )
        end,
    },

    shadow_word_pain = {
        id = 589,
        cast = 0,
        cooldown = 0,
        gcd = "spell",
        school = "shadow",
        damage = 1,

        spend = 0,
        spendType = "mana",

        -- notalent = "purge_the_wicked",
        startsCombat = true,
        texture = 136207,
        cycle = "shadow_word_pain",

        handler = function ()
            applyDebuff( "target", "shadow_word_pain" )
        end,
    },

    smite = {
        id = function() return state.spec.discipline and talent.void_blast.enabled and buff.entropic_rift.up and 450215 or 585 end,
        known = 585,
        cast = function() return 1.5 * haste * ( set_bonus.tww3 >= 2 and state.spec.discipline and talent.void_blast.enabled and buff.entropic_rift.up and 0.8 or 1 ) end,
        cooldown = 0,
        gcd = "spell",
        school = "holy",
        damage = 1,

        spend = 0,
        spendType = "mana",

        startsCombat = true,
        texture = function()
            return buff.entropic_rift.up and 4914668 or 135924
        end,

        handler = function ()
            if talent.weal_and_woe.enabled then
                removeBuff( "weal_and_woe" )
            end
            if talent.manipulation.enabled then
                reduceCooldown( "mindgames", 0.5 * talent.manipulation.rank )
            end

            if talent.darkening_horizon.enabled and rift_extensions < 3 then
                buff.entropic_rift.expires = buff.entropic_rift.expires + 1
                if buff.voidheart.up then buff.voidheart.expires = buff.voidheart.expires + 1 end
                rift_extensions = rift_extensions + 1
            end

            if set_bonus.tww3 >= 4 and hero_tree.voidweaver then removeBuff( "overflowing_void" ) end
        end,

        copy = { 585, "void_blast", 450215, 450405, 450983 }
    },

    -- Ascend into the air and unleash a massive barrage of Penance bolts, causing $<penancedamage> Holy damage to enemies or $<penancehealing> healing to allies over $421434d.; While ascended, gain a shield for $s1% of your health. In addition, you are unaffected by knockbacks or crowd control effects.
    ultimate_penitence = {
        id = 421453,
        cast = 1.5,
        cooldown = 240,
        gcd = "spell",

        talent = "ultimate_penitence",
        startsCombat = true,

        handler = function()
            applyBuff( "ultimate_penitence" )
        end,

        -- Effects:
        -- #0: { 'type': DUMMY, 'subtype': NONE, 'target': TARGET_UNIT_TARGET_ANY, }
        -- #1: { 'type': UNKNOWN, 'subtype': NONE, 'points': 2.0, 'value': 852, 'schools': ['fire', 'frost', 'arcane'], 'target': TARGET_UNIT_CASTER, 'target2': TARGET_DEST_CASTER, }
        -- #2: { 'type': APPLY_AURA, 'subtype': SCHOOL_ABSORB, 'value': 127, 'schools': ['physical', 'holy', 'fire', 'nature', 'frost', 'shadow', 'arcane'], 'target': TARGET_UNIT_CASTER, }
    },
} )


-- spec:RegisterSetting( "experimental_msg", nil, {
--     type = "description",
--     name = "|cFFFF0000警告|r：插件中的治疗仅专注于DPS输出。这在单人游戏或在团队/副本中你的治疗不太关键的空闲时段更有用。使用时需自行承担风险。",
--     width = "full",
-- } )


spec:RegisterRanges( "penance", "smite", "dispel_magic" )

spec:RegisterOptions( {
    enabled = true,

    aoe = 3,
    cycle = false,

    nameplates = false,
    nameplateRange = 20,
    rangeFilter = false,

    damage = true,
    damageExpiration = 8,

    potion = "tempered_potion",

    package = "白戒律Simc",
} )


local flash_heal_str = Hekili:GetSpellLinkWithTexture( spec.abilities.flash_heal.id )

spec:RegisterSetting("flash_heal_pct", 80, {
    name = format("%s 生命值阈值", flash_heal_str),
    desc = format("若团中有目标生命值低于该百分比，插件会推荐使用%s。", flash_heal_str),
    type = "range",
    min = 0,
    max = 100,
    step = 1,
    width = "full",
} )

spec:RegisterStateExpr( "flash_heal_pct", function ()
    return settings.flash_heal_pct or 80
end )

local pain_suppression_pct = Hekili:GetSpellLinkWithTexture( spec.abilities.pain_suppression.id )

spec:RegisterSetting("pain_suppression_pct", 30, {
    name = format("%s 生命值阈值", pain_suppression_pct),
    desc = format("若团中有目标生命值低于该百分比，插件会推荐使用%s。", pain_suppression_pct),
    type = "range",
    min = 0,
    max = 100,
    step = 1,
    width = "full",
} )

spec:RegisterStateExpr( "pain_suppression_pct", function ()
    return settings.pain_suppression_pct or 30
end )

spec:RegisterSetting( "sw_death_protection", 50, {
    name = "|T136149:0|t暗言术：灭生命阈值",
    desc = "如果设置大于0，将不会在你生命值低于此百分比时推荐使用|T136149:0|t暗言术：灭。此选项能有效避免你自杀。",
    type = "range",
    min = 0,
    max = 100,
    step = 0.1,
    width = "full",
} )

local penance_pct = Hekili:GetSpellLinkWithTexture( spec.abilities.penance.id )

spec:RegisterSetting("penance_pct", 90, {
    name = format("进攻%s 团队生命值阈值", penance_pct),
    desc = format("当团队血量高于该阈值时，插件会推荐使用%s用于进攻。", penance_pct),
    type = "range",
    min = 0,
    max = 100,
    step = 1,
    width = "full",
} )

spec:RegisterStateExpr( "penance_pct", function ()
    return settings.penance_pct or 90
end )

spec:RegisterPack( "黑戒律Simc", 20250606, [[Hekili:vZZwZXrXv)BHhILeXArALwjfxoUkFlGDHahKbx4h2zNDME1o2ZoZM5IwjxuBzYfIldKaP(sLQasLqkGqOCcjpKe)b4KFmrsiEI)c5C6EU0tpDp30fhJf2R2UNZT(CV7P7Uy3R3Ddt9as3xO9cT7SWAlSuRfAV4Ql0U7gb7mM0DJX6g3wFt4do6JG)(B(Y3D)79R27F9MBynYahDhBxDtek(UHEgWmM4oXouV7g9dTSdUIt3(YqWkDae4pMyaFDNv6UXqlttcBUeFaUlUyR2tV60RU3h9No4V)MNb)4fp)p88x9vgf8kRTKBWfgC5B1PFWAlmr)cNFZGBU(T2(vxF0nF274FZBm6MWF2E9ZN8FV6ngzFZBT96358VkDE35I9VZcRFD)lGZ8cp)lVomC7rbVWTG)0hMpfXp8T2)dE)DF0VF3V8b79rV3E)1F7bF(VE3h(279oV1x)E)ugzD6P92)dU7EF8Jo4N)z79p)B7)l(J7DV)XUp8lp4tE9V(EVXE)Y39B)QxV7g2w(b(uXmzGEODa8XxGk2jo69TjMDVq3nm8SciEwGu7PM2Zt3YS7g6gbwUoGeo0ZAWoDdabv1Fitlq2ARnsFtld8rxs4rtaUULJMF44XEeFF63Kc0bwoMTSDNq8d0goU1yJGP9o70ElVW0ENAAVaRrKP9o30ElGCOdrZWex1qKTmpY6NdKaU0g6g0Ypa0kOWcPMTyFPEGRdzeXHHRo0HZXDg622ASFrdLUmzSgtbnc8iH0rbxx4ZB46AB6oXXhHWkkf5ZoTh8dLHgg6bpC4OwgUHiHdcL2t79AVMWWA9T2m7uMlM96hoyakxg56yrPk3bAwo(wBomOv4ygSKnNXwKGDOZGbQzvjlb8TmVSKbs2NuUaCo6cadYdj62bd1gR7fSJwSQWAIQcYxUiBP7SjbeXJqr6QkfPsv4((t7TKc4ogMQN2exptn)HweBte8RPstpDYE6Mw6oORQuCRqfeW(Y50V)EcOWDm4kJeKIRT0bycJIFYoKqTpPlFbtSSXfvnYpcCoA13Zculg6AVJM(OX01ro9bPt2FOoOCgnDkMIuBdiAoaDJ03IluBcSIiKP2e)0TIXj1NTN1ygWVEeyM27YPWzAplFgFz5S50EmOoTNP(iASLm8bBqkNi6N8WWjzKZhr8bctfCboeLheDBxopeOBdQFTIe9gUBbpn87XWilz(8UiHSrKanEYm6m5jsPmBy6A(W0O0MyCHYPTy3Jru3alcy0MXhLizJ6PzO4xIOBcsTaxqpiaCOKQoKs9JhQ7NrIAO7ObcfWgoH4xU2e)c8qmIoXaL2(AMHE6u3QJ03McDXGhi01nnla6TRb0fdSuo0zd0Ae4KuRVTUpOpSnXie00q)V1a1IoGle1vaMCErJuCn19Une)Ym0Etc4NvHI7yCP2OYmis6Io3RSulI8PU)nj6bdfeE5ybjpqEBPse0YItCctTS4ZrRk4aA6G0DKUPdKVNWK82Ke0IfNpjzV21WIPTSWovIFXL8nbm4xgFYnX6UA0wwOKkrDMwBHX)rxvLrFzMATPqzbkQefou32TmsJnNAttYcqmW211RaQAwfbcIb(0EZZf8vnbqZ98zM2BtdZwuhnzCFmlghaI9Yd044imGLoidop7fVuCYQqEDqwMwJOvG4oioqE8ZnHGWYn0gSnCiOfcgSk0NqbjnYFWqco22y0lkHmb0nrCpThlIm7BjBdzCytodKB(IDO04ITzuZIT6qPJ2ucZpkEi4ueWgYozPimcVRxGeWUQuOo)sTwQsaEwmZN541iarTgx(lTBuy2mlvxel6Hk1IN6PJfGHJ6t8ylbaHm)apgq1THK9jJGQt5sZYaIjauS(w6w2IXNsMCgsV(XWtul5LcLIhzrZbrK1ajgIbEyn3qXBbGcgwGN8OJx)fV0lEMunynY2JjgbOQilb0n3Ch2Yzuy0Nbd6IcTXEGATJ5Pr9vQWtNMMvGLboQzObZAr3pEehZ5TGVyGRhUgmHNBJrQwes0saGsrOgX2NeLPvuwrOeswsh1ujs32i0MAWoeTZgfAmKPteBudH)cgY0LeDeGg0d13c(BJqppyza1NsuKAnT3nir23YDhXmImjWsjedcMM1aEGYWpoLje6xGcuDNDen2Wzm2ZfwjcskUGReLwL7yMkmRvAqLapof0Ku7JwTtsRN1RJCdZSf8Z6oxTkd1D(zveBibwZjSSVHXqlFOSRRjKTitTQwPy1ajrAchCYcjJgr(CwP1Mrxpgyvm7iSRE1kJRgW(5ZRuMyi)SsyYAlfq7qD7j67aJb5JgfMyGLhAMVXnoZLeLoLKRmkLQvMFvxkvSi4ixqX1Jpv5QZWy0Oi7Rf4InRtdh6SvJqMRsLmiAKsmCX0lWfimQe6ZBYqItmGqdcDCcmAlUDIm)KrRxy39C2K0G13AL3C1xFZxpQXqK8bH05GmSwuqgCEtZiF(taN(yKM4zJbKqOalXiyKzFlIGNM1t2IlhEjzjNFeW4ZM0izPuNgFsAujrspKlF(NLRX3Zg)ZI0qivgNZtFcMbHubLhH9yAS4YvkSd9N0GDvJsoBmLKNBQgaoI5aLQK84mNEjfLONw9aSmgBAU3SzXSqJBWufBtZsYQy4iqVmX9fFz2Y8ZYpEn8Wki9UefkGtnamICVYEcGSFTQ6ObSpTuEz8nDGMZWph84ImA(wlGCyTQ3rsV4veg5sQYVM4GLkfx8lZMGR8qXeVvKED0(CrfSqk)xjcfMUoZeeJPRF50ywNonvKb6qvnWZ8YSsQ8hbm5m(XXUSCD4RbaRbJ4t3ajDAvj(bZd1PGfxyamUNLRqI(yJgG6jREnvQ6WI0mYvvrZC09SlomlYr5xORFzBs3FGe667MIqUHZ26QmQe)awMFrL(h3tM4LL(Gm95Uewtfz88Nlwmm)58Pfnm)5WXeQlMxYJTVjPoLeEUrvxLhuCwcjlf56Eq8oONHNVsb6(XlFOUj17oFZrkTaZKvP4wQH8R0TZmSFbRXIP(8syjEaP6g6HEJeB2dVCsA)twU(ByPS6rL3FXYlinzQswe3kZgqfVLfinx)TMunEOggTftQoQhg3as99mt7Djm5xAJaPjzt7cejia7Ege5gygxOujV0Ene7bv3JiKNnDV1ALt71FIzIrWYnkN6SG5jfdGLLUjONSgankJjLI7zJQsu(EMWxGh4fgvHOwhEgek7WnX0uIleypvY4GXMfl(kpmMt1omHvp0wC1pcfOQoQFJQbGrWzWFh9J7md(VuDzCiqt3b)c9TWFJYmWZfZl4iU4tGdhrBIP4OU)kl3Om5uUSuvbW6P1kkZopY(p18MM(cNfUmgurQ6lxR9HU5CyMMkuPDhoULcCfOKTJc1HlB0wExaxQAZ(kwpVmBLcQ)iQ9jy24rE0RPoreaYKRBcbikklQ6MLRv6rhMDP8Wkmlk8w9pcxf07mj7rtUSks1JYMrb89ib1P(zavZSjwp1oAApUFPo5rKxPk3X0HsmPMIjs8onQjSsH2tk5v0r6b)6enVIonQdHLj1vFurY39jEhtZiptur)eL3X3onpDPczRd1XKrsN3aDRmngpBtnmzj0t9lhHQgikAEkkLlkQD2EYKcjarK)TcMkU9avl8K6e26uPgtLpHbLD2w(MYF9HOxt8)HLyBRGaSD)9r(X3A0y8SKBzCAmxvWbb70I03fxQv25vxwRms2qA4J0gYcFyKl7OiZVpyX9MfpAk(PpEOpXSfORf5EYfi6rw3jQK44wNGtCSRVVf62umAuQirPtkz9IsA)YXdqrcdF83E)SHdLfbQ(9YQbHyJ00zHyJv7zkkXrzDJQmP(rBlXgjN1nf)PcGAL5wra7jMiWp(BT1knAl6lrOx8()oBrvJNX)Dzv)lwsMIgpX7Hpx0Dy1epyrUHb(wMeMRVSZivPpJQDcXHhXPeQdB8DaoZsJsuESZvoC5Kw31M6VT6NyzrSsZB3xrsIkLKqjD7qz6dfMEGIgbSYHlF46XNpE75Xk1)yBk5CnvLsBfLm5tPGDSMqIsw2QhPXGf302mRHC91ivo18oGLdCpPexCfPPcDYgxS5jJuKyVStgvL8iLpoxOJn4xTKOymt1eGZGaiyuy7wbVYn60nEiKr)pCeQvBEEufllQKgrUyuPBanQGud3YR28CoQaFCYhMz1MN5qf4NCnGqDfxvBvrEBdw9q8AqY3R80nGoxqY8mB2WKCJtPiXO3sISK8MCsnCt(AHxuYewWl0r578EMxk0vfdsBWVXIcNUutlcnGgmYc4BCYtJ5MN9fsdVJbAL5yNKCG5WsrSmUnn0ruPlEKbEe4X7JDbjDwm9beudcT1gh6y5pCe10nozRSL(u0mzqvkzYF4PKDedAYrEpZpPRhI4Mk6l8(gitHBzo3pzecz0e8NywW(Vg16szKe1nmLMu)c7xSxhksz3Ab039E6R8crJoBmkAluYsNKAX8z5E7VIPsUMuHKNyIehArwerKzXI7GFSQyu5ue2eSjRLBz5W1ed9DO5qUAQMRYNgGSKxsk9RP(QmPHuxgv2ckTkVZO4J6ES)Oou)rvyN7kY2mXqyn13)knKtZTouXwZOAPqmmwn0mtbjUfSuOPoeudzxUyCzK2cX(wRW4pnbXCAuN4knup6jtbpLL88gAGJ3yngUJ6RNEZaL42j9slzGRxGvqOPWJxWLcuKyQVR5o0m59DdTfBei19C2ziClKWU6wm0gGCeXlE4rGuNgv10cFfcnyzbSwMhv5fAJugm9kCrTA8Sfr04YEQ2Hc2EUQWCPVNh03wHJo2vaFiZQ2ktX9V0IlWQut2WinXfp3J4qO3JkQTOuDN7eD1(WoLXH4MTaSKDYfs0PKDD8qsIrQonMsWxoGoaIcoudZzHzRKE7mj5w0kRLi9Sfl2EiwhMPVPNJj4rko(952p60wAKCfKWEHU9pn8jismDs47tTC3Q0APa8r8KAIj6RcukQITB9HAMidShnNjv)AfzqmZALt7uYEz3Q09dZuzV8kdDXTR8AxzA67E)elSrc5xPe3xzr)lyPa0B3mj2BPZmkyepn4VJJbUDPm39m0FTRWl(4YVnglrlUQU8XaordE6r(sXvaOnEBQIz1Xgt2MMeD2XtYLg3q7OcaJNlZMkT6pj2uzOXS31qxmAbqLsxz5lLeJo5nGirxt2qNk7n2uSAqs9K0TqvJfD3Vf7OYH88s5ZTPSimhRuwM0GeiqHuHuhCOknXtzAZhPCyjjavwYChhesLIeDuJ(c1bBNxhuDz1NauwoDW2QthVz6Gh1mrjQzQlk)XKXq2A4ZDL8LJ(kSGVtaAnPkYC35EpMeLXavD5AL(2nwOgtU7LVJpdqvs6tUWqk1llRi)Jdsi2dyURyVtcKl4Dl3fX3XhnCSRqF8grHTNZcUIP9ZiqYnZxM0gVvOF0rzJ9AWI5Q7f6q3pvf3xp0KFPN5r9(U07ThxhtAT1(sJZZUS9YBMj0SKfeNvCRxZoTmnHjVWwy2T5NnV(LW8wIFEuJaHjSCg0kTxryA6A4R7Ar1)k9UUnZkY1aiqFnsWARO7wu(6Q4vGk(T69SSZIq8(PfKEjmlsK45iqcvg17hL9jG1JG4oFe3KaXsm4boR1h1gGuIFlIhTAr2fw(klSs3nMO7HNGbqF6G)8NS37E)V9REV9(8VAVF2hpt0L69m7DVFZbF4N(nFWDp4tE9DF4D39lEF8sb)(F6U)7)Y()F)))N7(JNE1V(bpO9sh8HVf8Wh8OhS)B)hodwdLdGo6bRXfc8tdRgDo6Mz2cVf9MNZMLodj3GEZ9DI29KzyR0hfG8zIbzl8AsF)79o7D)FhtwS7x8gRS7d)S9V)Dp4N8iM8GY3WQsyWq8kdm(QHFSN7alC3uPc8U)3]] )
spec:RegisterPack( "白戒律Simc", 20250620, [[Hekili:TVvBpUTXr4Fl(lg31piirjDNmG9b4RUiOh6zGcfedFFquRixjYesUcKlpDYiqi91yK3GBbkkQtk6lWTnTiaPTbfWTjU)z6PZx)u)l0zx(2sQDxkD(sHtVyByllUC2zFMzN5zMDVbTg8Qd6BJO4b31OPr3M9A2UrtJwDA1AqF68P4b9NISEd0e4dbiF4VF(V4zN9WF6Y)572313I905EeKntkrK4qlyeZiZ8Ird6pk21J(Tdgms2e0UBp4nMITGVU7od674ABJtglocKBRwnmwCWIdw(K)WZ)lF2YN8hp)V9UN9bF85V)J260N(2)73(NC2F9VV9)5lEmmMHlo4BE7V7Tp418PVwV2e6(J)wVE3r0EnNH2)2tOohD4RCh)tUVp9O75Fe)37F78FDpFVJE9to8btoY5KdFLd9p6K7eD3x9bhU)DMD435(oUNeD49IMD)hCF4D46Zh(Bp7J(eyIp9PV)5)(V3Yp4Z5F7tFVZ(Op80N9Rp9Z)KLp5Xl)Z)YZ)0FgmILp69E(J)HjA)G(EUr0igsfICzi2D5GpoanYdBpy)b9TcDP4qxa7g7gy3WJmdhrnDM2yQfDXWBERfdB1S5IHxFXWTwm8AlgokE84groiBYmtlYXGKcOnINUy4B(MfpFAi2Ne4sDjbMKXMtDX058bTTGKSiepqkbPsBSlgM)XXEEMHylhu4eSj11hNPe83eEnkYddtPpOTJG3ah2iD1KRc5cwym1ixncnrLrwu3JXMoeAdeLeG9HHxscJirrd6ZggjaqBCaE2ak4OvbUZgWuaNdnNrcTndr2UOaMxCHTq90TBgoidODdICN4WShmlFa20YEqFdME0wHEKAj5kYuKBGOsKJJsu2gjiz0IHGoLHHWxqByJfDrYfCdqtH)jkf0UrYRWTd7bsquF5kChL(PYXM9aP2TyDvyjzcR7lMWeCqzsBhLst5MJn3PNPc729Y3PxqU160lAEYWc8XOGjyiSIpdk2vjuSv9HkYv5czQCFQrtnBd3lDBywiiyR4Am6TZaxFYXUbte8HnDJmHnW(U4YouMJ8qru26U3vaxaHGvsJYWWHBCvgh4P1yOqRMxLHHiIhcYEXWb1KlUcGdwEi3WJjZ55YzOr1C)RhAiQXYs8gIr2Z)kiUPmJIdjocZbquODeh5QYwPa52W0gT6QCAdWXHipZO5bOPW8JdCyWlNUql1KpU8MFigAaKQbw3uhS50qxsysWe1KvYyybC6z6kmff0pzEuHoWsHypVHfjMLPRiVzHci45ux(5AOYlAb9MBgqogX1F10JGPLxKHtCi1mi2ptpb9Yizwl9yZrUtkpezPSVuwlcj)ldVTRIFcRAKhHVGvtcAtOeBO2tPkhD2KQMbsfBTAkntzOuASk1jYRRSq(sBgg2kHagsZi4YH1FbnmsRykYXf7XPIBOoZRu9g8WakCoMom9L)vzRGOy2oxyY9sRG6lJ1qXKZv(lET4YEoloCVsLIb28XHS8bEZLvAQ68tmnK6KkwOuO8IV1x05A5bBJruh(8RokVAF2JjUf0WPSo3mgf7r13zdqX5T)OWxko0D8Cz1NR5LG4ctXEM(OjUw6kPMTf1mkEkatrr8VPwNYoRgLjVCyGuv1YHhvDxHBW44Qtv1Waj5Kyr00xrSOT)MmBVGRdeZf(Jjm2yy)JFCnLdlS7zeKwIhGiIe7jU3jLYq5NxH1qMqss3AzoM5cbKls94YBfXEzrrH0d8I9eILdpR365fxSERmF6l4TCwjPBqxm8gDLgqBmjKcyQnwFTLvmn7kyAgJsEz1XXxXUUPOHng8)drugzf08uMsQJ)wEZJfciiL8Fmz9KmPZKMj93Lpu91pinPwd23AsjM2UjpSvo92YZUoUEgk2zrbV93atBTcV9YB5eOTNVmARxKgRFebrPQMuQowtD4YjX4dShcPZnZMJDe8FGyOU(CBlg8cWz0cuhM4sIlNufRx31Z3u3OkY)QI(lBPlVhRTtwaBs)p3wUJN6oN8Lpn5RwqBrZy02tYVgy3uGvO9oQZm91i7fazxPHrvtElHPGSdlsRMjTZeqSF149nkLevaIYO3WqJKQ(aA4yOWFUyfkKE9mv6StRW)TUc9kXUzDQovC5Tgk7QifJnxZ6kp9IxH3LGIxNYPI5JqnwL53Ug4Ks1wka2RUt1j3vu8mAkV9vGI0kvukR(ZQNY56TUuq4Szdi6W3yXqBq1xP9o2aPtM44cGBVdGfNzAXTRwCqpP9QBZ7HKOhsA5vaHUqcYYHv9wIiIkkY66Ib3Wbf9(cGP5wEzACeReBgkxLi6AgMARnigQXggZTL(WzBFrIIPoJqNnikNcV1vIVPMPTIke6vT1Yx8Od48(aAOMvQKnW3IfcSoTOAVCUWQMwEDxseqwdBAUFtnDtElLX1eCGsqjMiZXlLVux9SK0zika0YhFVHwgD)Vft3Qoynh4R2j28qG7DRSPD7IyURUZPgFw28KAes8ytL8oLchlEibgDlCQRt5wdBu2blyuZPRR54EuFqrxtYtzhGxJUIEFLw46c0iO1Ihcu7nUV8I9zCcYZdnXLyoIqPq(NiC4XUjrbARTlV15ND9kNQzclhPCKVv5gNwnDCkFtR4WWCYkgCQaPpXhDYkHcvZZXOyXx(Ml1wBdQ))H1BLlxv7QC4s(OzsABjUs65u1jVgp55VyzrvgyztROrAQURj5cgvENzhX6qx7JZ)LHBfzvAJQV(wBGVrNY7fYQej1b4U8JVODDnd9fPCWlwTET3qgCBGwv3mRTvIjUv1KPo1hrt6ETzu3TzEo81yIUOZsVUREnsuatf0gBRM2OkZYMDeXIEo1gMq4aBkDuWT7POw8KtRvPsVy1tfUkWMxDK8DC8nCmnqnzJTuV(t9BYcWvdZ3BMXLqLbUzj2xk7hGIxVQDBBz2N0WikSdD2qElcGFT2EfUQ8ZsJnsyvAZunMAuLLZlrnYqxJCUSADH8gp0rnxOl74CYjlCjhMtnJeDr5eq2AUupDuFblErUGhR4cl92D0r7DOtxgV1tfQUpU6fdbeGfXFeQ(RgcF(QE)eKMYT0X0R2zu)vAqyrU6LIq4HkUSdxsxTb5ej0T)sTs)vZBYrnmixn9I27Efley1S2uDxZgvPt6jqjulHdPB5vZeSM5BfHwkViFh1X4q(Dmk5NPUDmG17muyaSlmAq)ZE4Jw(o)QLF6xS8h97o9F8JBF6t)tN9oV15)GNT8H)8Z)nF8)6T((loGTPKm21dIwbZtm1HeM)tUhBgg8Fd]] )



