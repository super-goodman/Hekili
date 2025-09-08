-- Hekili.lua
-- July 2024

local addon, ns = ...
Hekili = LibStub("AceAddon-3.0"):NewAddon( "Hekili", "AceConsole-3.0", "AceSerializer-3.0" )
Hekili.Version = C_AddOns.GetAddOnMetadata( "Hekili", "Version" )
Hekili.Flavor = C_AddOns.GetAddOnMetadata( "Hekili", "X-Flavor" ) or "Retail"

local format = string.format
local insert, concat = table.insert, table.concat

local GetBuffDataByIndex, GetDebuffDataByIndex = C_UnitAuras.GetBuffDataByIndex, C_UnitAuras.GetDebuffDataByIndex
local UnpackAuraData = AuraUtil.UnpackAuraData
local RC = LibStub( "LibRangeCheck-3.0" )
local buildStr, _, _, buildNum = GetBuildInfo()

Hekili.CurrentBuild = buildNum

if Hekili.Version == ( "@" .. "project-version" .. "@" ) then
    Hekili.Version = format( "Dev-%s (%s)", buildStr, date( "%Y%m%d" ) )
    Hekili.IsDev = true
end

Hekili.AllowSimCImports = true

Hekili.IsRetail = function()
    return Hekili.Flavor == "Retail"
end

Hekili.IsWrath = function()
    return Hekili.Flavor == "Wrath"
end

Hekili.IsClassic = function()
    return Hekili.IsWrath()
end

Hekili.IsDragonflight = function()
    return buildNum >= 100000
end

Hekili.IsTWW = function()
    return buildNum >= 110000
end

Hekili.IsMidnight = function()
    return buildNum >= 120000
end

Hekili.BuiltFor = 110200
Hekili.GameBuild = buildStr

ns.PTR = buildNum > 110200
Hekili.IsPTR = ns.PTR

ns.Patrons = "|cFFFFD100目前的状态|r\n\n"
    .. "目前已经支持所有的专精，包括治疗！\n\n"
    .. "如果你发现奇怪的问题或建议，请在下方的QQ群联系管理提交。\n\n"
    .. "请不要提交默认优先级的问题（来自于SimulationCraft），它们将在发布后同步更新。谢谢！"

do
    local cpuProfileDB = {}

    function Hekili:ProfileCPU( name, func )
        cpuProfileDB[ name ] = func
    end

	ns.cpuProfile = cpuProfileDB

	local frameProfileDB = {}

	function Hekili:ProfileFrame( name, f )
		frameProfileDB[ name ] = f
	end

	ns.frameProfile = frameProfileDB
end


ns.lib = {
    Format = {}
}


-- 04072017:  Let's go ahead and cache aura information to reduce overhead.
ns.auras = {
    target = {
        buff = {},
        debuff = {}
    },
    player = {
        buff = {},
        debuff = {}
    }
}

Hekili.Class = {
    specs = {},
    num = 0,

    file = "NONE",
    initialized = false,

	resources = {},
	resourceAuras = {},
    talents = {},
    pvptalents = {},
	auras = {},
	auraList = {},
    powers = {},
	gear = {},
    setBonuses = {},

	knownAuraAttributes = {},

    stateExprs = {},
    stateFuncs = {},
    stateTables = {},

	abilities = {},
	abilityByName = {},
    abilityList = {},
    itemList = {},
    itemMap = {},
    itemPack = {
        lists = {
            items = {}
        }
    },

    packs = {},

    pets = {},
    totems = {},

    potions = {},
    potionList = {},

	hooks = {},
    range = 8,
	settings = {},
    stances = {},
	toggles = {},
	variables = {},
}
local class = Hekili.Class

Hekili.Scripts = {
    DB = {},
    Channels = {},
    PackInfo = {},
}

Hekili.State = {}

ns.hotkeys = {}
ns.keys = {}
ns.queue = {}
ns.targets = {}
ns.TTD = {}

ns.UI = {
    Displays = {},
    Buttons = {}
}

ns.debug = {}
ns.snapshots = {}


function Hekili:Query( ... )
	local output = ns

	for i = 1, select( '#', ... ) do
		output = output[ select( i, ... ) ]
    end

    return output
end


function Hekili:Run( ... )
	local n = select( "#", ... )
	local fn = select( n, ... )

	local func = ns

	for i = 1, fn - 1 do
		func = func[ select( i, ... ) ]
    end

    return func( select( fn, ... ) )
end


local debug = ns.debug
local active_debug
local current_display

local lastIndent = 0

function Hekili:SetupDebug( display )
    if not self.ActiveDebug then return end
    if not display then return end

    current_display = display

    debug[ current_display ] = debug[ current_display ] or {
        log = {},
        index = 1
    }
    active_debug = debug[ current_display ]
	active_debug.index = 1

	lastIndent = 0

	local pack = self.State.system.packName

    if not pack then return end

	self:Debug( "New Recommendations for [ %s ] requested at %s ( %.2f ); using %s( %s ) priority.", display, date( "%H:%M:%S"), GetTime(), self.DB.profile.packs[ pack ].builtIn and "built-in " or "", pack )
end


function Hekili:Debug( ... )
    if not self.ActiveDebug then return end
	if not active_debug then return end

	local indent, text = ...
	local start

	if type( indent ) ~= "number" then
		indent = lastIndent
		text = ...
		start = 2
	else
		lastIndent = indent
		start = 3
	end

	local prepend = format( indent > 0 and ( "%" .. ( indent * 4 ) .. "s" ) or "%s", "" )
	text = text:gsub("\n", "\n" .. prepend )
    text = format( "%" .. ( indent > 0 and ( 4 * indent ) or "" ) .. "s", "" ) .. text

    if select( start, ... ) ~= nil then
	    active_debug.log[ active_debug.index ] = format( text, select( start, ... ) )
    else
        active_debug.log[ active_debug.index ] = text
    end
    active_debug.index = active_debug.index + 1
end


local snapshots = ns.snapshots
local hasScreenshotted = false

function Hekili:SaveDebugSnapshot( dispName )
    local snapped = false
    local formatKey = ns.formatKey
    local state = Hekili.State

	for k, v in pairs( debug ) do
		if not dispName or dispName == k then
			for i = #v.log, v.index, -1 do
				v.log[ i ] = nil
			end

            -- Store previous spell data.
            local prevString = "\nprevious_spells:"

            -- Skip over the actions in the "prev" table that were added to computed the next recommended ability in the queue.
            local i, j = ( #state.predictions + 1 ), 1
            local spell = state.prev[i].spell or "no_action"

            if spell == "no_action" then
                prevString = prevString .. "  no history available"
            else
                local numHistory = #state.prev.history
                while i <= numHistory and spell ~= "no_action" do
                    prevString = format( "%s\n   %d - %s", prevString, j, spell )
                    i, j = i + 1, j + 1
                    spell = state.prev[i].spell or "no_action"
                end
            end
            prevString = prevString .. "\n\n"

            insert( v.log, 1, prevString )

            -- Store aura data.
            local auraString = "\n### Auras ###\n"

            local now = GetTime()
            local playerBuffs = {}
            local pbOrder = {}

            local longestKey, longestName = 0, 0

            AuraUtil.ForEachAura( "player", "HELPFUL", nil, function( aura )
                if aura.isFromPlayerOrPlayerPet then
                    local model = class.auras[ aura.spellId ]
                    local key = model and model.key or formatKey( aura.name )

                    local offset = 0
                    local newKey = key

                    while( playerBuffs[ newKey ] ) do
                        offset = offset + 1
                        newKey = format( "%s_%d", key, offset )
                    end

                    if newKey ~= key then key = newKey end

                    pbOrder[ #pbOrder + 1 ] = key
                    longestKey = max( longestKey, key:len() )
                    longestName = max( longestName, aura.name:len() )

                    playerBuffs[ key ] = {}
                    local elem = playerBuffs[ key ]

                    elem.spellId = aura.spellId
                    elem.key = key
                    elem.name = aura.name

                    elem.count = aura.applications > 0 and aura.applications or 1
                    elem.remains = aura.expirationTime > 0 and ( aura.expirationTime - now ) or 3600

                    local scraped = state.auras.player.buff[ model and model.key or key ]
                    if scraped and scraped.applied > 0 then
                        elem.sCount = scraped.count > 0 and scraped.count or 1
                        elem.sRemains = scraped.expires > 0 and ( scraped.expires - now ) or 3600
                    end
                end
            end, true )

            for token, caught in pairs( state.auras.player.buff ) do
                if not playerBuffs[ token ] and caught.expires > 0 then
                    playerBuffs[ token ] = {
                        spellId = caught.id,
                        key = caught.key,
                        name = "",

                        count = 0,
                        remains = 0,

                        sCount = caught.count > 0 and caught.count or 1,
                        sRemains = caught.expires > 0 and ( caught.expires - now ) or 3600
                    }

                    pbOrder[ #pbOrder + 1 ] = token
                    longestKey = max( longestKey, token:len() )
                end
            end

            sort( pbOrder )


            local playerDebuffs = {}
            local pdOrder = {}

            AuraUtil.ForEachAura( "player", "HARMFUL", nil, function( aura )
                local model = class.auras[ aura.spellId ]
                local key = model and model.key or formatKey( aura.name )

                local offset = 0
                local newKey = key

                while( playerDebuffs[ newKey ] ) do
                    offset = offset + 1
                    newKey = format( "%s_%d", key, offset )
                end
                if newKey ~= key then key = newKey end

                pdOrder[ #pdOrder + 1 ] = key
                longestKey = max( longestKey, key:len() )
                longestName = max( longestName, aura.name:len() )

                playerDebuffs[ key ] = {}
                local elem = playerDebuffs[ key ]

                elem.spellId = aura.spellId
                elem.key = key
                elem.name = aura.name

                elem.count = aura.applications > 0 and aura.applications or 1
                elem.remains = aura.expirationTime > 0 and ( aura.expirationTime - now ) or 3600

                local scraped = state.auras.player.debuff[ model and model.key or key ]
                if scraped and scraped.applied > 0 then
                    elem.sCount = scraped.count > 0 and scraped.count or 1
                    elem.sRemains = scraped.expires > 0 and ( scraped.expires - now ) or 3600
                end
            end, true )

            for token, caught in pairs( state.auras.player.debuff ) do
                if not playerDebuffs[ token ] and caught.expires > 0 then
                    playerDebuffs[ token ] = {
                        spellId = caught.id,
                        key = caught.key,
                        name = "",

                        count = 0,
                        remains = 0,

                        sCount = caught.count > 0 and caught.count or 1,
                        sRemains = caught.expires > 0 and ( caught.expires - now ) or 3600
                    }

                    pdOrder[ #pdOrder + 1 ] = token
                    longestKey = max( longestKey, token:len() )
                end
            end

            sort( pdOrder )


            local targetBuffs = {}
            local tbOrder = {}

            AuraUtil.ForEachAura( "target", "HELPFUL", nil, function( aura )
                local model = class.auras[ aura.spellId ]
                local key = model and model.key or formatKey( aura.name )

                local offset = 0
                local newKey = key

                while( targetBuffs[ newKey ] ) do
                    offset = offset + 1
                    newKey = format( "%s_%d", key, offset )
                end
                if newKey ~= key then key = newKey end

                tbOrder[ #tbOrder + 1 ] = key
                longestKey = max( longestKey, key:len() )
                longestName = max( longestName, aura.name:len() )

                targetBuffs[ key ] = {}
                local elem = targetBuffs[ key ]

                elem.spellId = aura.spellId
                elem.key = key
                elem.name = aura.name

                elem.count = aura.applications > 0 and aura.applications or 1
                elem.remains = aura.expirationTime > 0 and ( aura.expirationTime - now ) or 3600

                local scraped = state.auras.target.buff[ model and model.key or key ]
                if scraped and scraped.applied > 0 then
                    elem.sCount = scraped.count > 0 and scraped.count or 1
                    elem.sRemains = scraped.expires > 0 and ( scraped.expires - now ) or 3600
                end
            end, true )

            for token, caught in pairs( state.auras.target.buff ) do
                if not targetBuffs[ token ] and caught.expires > 0 then
                    targetBuffs[ token ] = {
                        spellId = caught.id,
                        key = caught.key,
                        name = "",

                        count = 0,
                        remains = 0,

                        sCount = caught.count > 0 and caught.count or 1,
                        sRemains = caught.expires > 0 and ( caught.expires - now ) or 3600
                    }

                    tbOrder[ #tbOrder + 1 ] = token
                    longestKey = max( longestKey, token:len() )
                end
            end

            sort( tbOrder )


            local targetDebuffs = {}
            local tdOrder = {}

            AuraUtil.ForEachAura( "target", "HARMFUL", nil, function( aura )
                if aura.isFromPlayerOrPlayerPet then
                    local model = class.auras[ aura.spellId ]
                    local key = model and model.key or formatKey( aura.name )

                    local offset = 0
                    local newKey = key

                    while( targetDebuffs[ newKey ] ) do
                        offset = offset + 1
                        newKey = format( "%s_%d", key, offset )
                    end
                    if newKey ~= key then key = newKey end

                    tdOrder[ #tdOrder + 1 ] = key
                    longestKey = max( longestKey, key:len() )
                    longestName = max( longestName, aura.name:len() )

                    targetDebuffs[ key ] = {}
                    local elem = targetDebuffs[ key ]

                    elem.spellId = aura.spellId
                    elem.key = key
                    elem.name = aura.name

                    elem.count = aura.applications > 0 and aura.applications or 1
                    elem.remains = aura.expirationTime > 0 and ( aura.expirationTime - now ) or 3600

                    local scraped = state.auras.target.debuff[ model and model.key or key ]
                    if scraped and scraped.applied > 0 then
                        elem.sCount = scraped.count > 0 and scraped.count or 1
                        elem.sRemains = scraped.expires > 0 and ( scraped.expires - now ) or 3600
                    end
                end
            end, true )

            for token, caught in pairs( state.auras.target.debuff ) do
                if not targetDebuffs[ token ] and caught.expires > 0 then
                    targetDebuffs[ token ] = {
                        spellId = caught.id,
                        key = caught.key,
                        name = "",

                        count = 0,
                        remains = 0,

                        sCount = caught.count > 0 and caught.count or 1,
                        sRemains = caught.expires > 0 and ( caught.expires - now ) or 3600
                    }

                    tdOrder[ #tdOrder + 1 ] = token
                    longestKey = max( longestKey, token:len() )
                end
            end

            sort( tdOrder )

            local header = "     n  | ID      | Token" .. string.rep( " ", longestKey - 4 ) .. " | Name" .. string.rep( " ", longestName - 4 ) .. " | A. Count | A. Remains | S. Count | S. Remains\n"
                .. "    --- | ------- | " .. string.rep( "-", longestKey + 1 ) .. " | " .. string.rep( "-", longestName ) .. " | -------- | ---------- | -------- | ----------"


            if #pbOrder > 0 then
                auraString = auraString .. "\nplayer_buffs:\n" .. header

                for i, token in ipairs( pbOrder ) do
                    local aura = playerBuffs[ token ]

                    auraString = format( "%s\n     %-2d | %7d | %s%-" .. longestKey .. "s | %-" .. longestName .. "s | %8d | %10.2f | %8d | %10.2f",
                        auraString, i, class.auras[ token ] and class.auras[ token ].id or -1, ( class.auras[ token ] and " " or "*" ), token, aura.name, aura.count, aura.remains, aura.sCount or -1, aura.sRemains or - 1 )
                end

            else
                auraString = auraString .. "\nplayer_buffs: none"
            end

            if #pdOrder > 0 then
                auraString = auraString .. "\n\nplayer_debuffs:\n" .. header

                for i, token in ipairs( pdOrder ) do
                    local aura = playerDebuffs[ token ]

                    auraString = format( "%s\n     %-2d | %7d | %s%-" .. longestKey .. "s | %-" .. longestName .. "s | %8d | %10.2f | %8d | %10.2f",
                        auraString, i, class.auras[ token ] and class.auras[ token ].id or -1, ( class.auras[ token ] and " " or "*" ), token, aura.name, aura.count, aura.remains, aura.sCount or -1, aura.sRemains or - 1 )
                end
            else
                auraString = auraString .. "\n\nplayer_debuffs: none"
            end

            if #tbOrder > 0 then
                auraString = auraString .. "\n\ntarget_buffs:\n" .. header

                for i, token in ipairs( tbOrder ) do
                    local aura = targetBuffs[ token ]
                    local model = class.auras[ token ]

                    auraString = format( "%s\n     %-2d | %7d | %s%-" .. longestKey .. "s | %-" .. longestName .. "s | %8d | %10.2f | %8d | %10.2f",
                        auraString, i, model and model.id or -1, model and " " or "*", token, aura.name, aura.count, aura.remains, aura.sCount or -1, aura.sRemains or - 1 )
                end

            else
                auraString = auraString .. "\n\ntarget_buffs: none"
            end

            if #tdOrder > 0 then
                auraString = auraString .. "\n\ntarget_debuffs:\n" .. header

                for i, token in ipairs( tdOrder ) do
                    local aura = targetDebuffs[ token ]

                    auraString = format( "%s\n     %-2d | %7d | %s%-" .. longestKey .. "s | %-" .. longestName .. "s | %8d | %10.2f | %8d | %10.2f",
                        auraString, i, class.auras[ token ] and class.auras[ token ].id or -1, ( class.auras[ token ] and " " or "*" ), token, aura.name, aura.count, aura.remains, aura.sCount or -1, aura.sRemains or - 1 )
                end

            else
                auraString = auraString .. "\n\ntarget_debuffs: none"
            end


            insert( v.log, 1, auraString )
            insert( v.log, 1, "\n### Targets ###\n\ndetected_targets:  " .. ( Hekili.TargetDebug or "no data" ) )
            insert( v.log, 1, self:GenerateProfile() )


            local performance
            local pInfo = HekiliEngine.threadUpdates

            -- TODO: Include # of active displays, number of icons displayed.

            if pInfo then
                performance = string.format( "\n\nPerformance\n"
                    .. "|| Updates || Updates / sec || Avg. Work || Avg. Time || Avg. Frames || Peak Work || Peak Time || Peak Frames || FPS || Work Cap ||\n"
                    .. "|| %7d || %13.2f || %9.2f || %9.2f || %11.2f || %9.2f || %9.2f || %11.2f || %3d || %8.2f ||",
                    pInfo.updates, pInfo.updatesPerSec, pInfo.meanWorkTime, pInfo.meanClockTime, pInfo.meanFrames, pInfo.peakWorkTime, pInfo.peakClockTime, pInfo.peakFrames, GetFramerate() or 0, Hekili.maxFrameTime or 0 )
            end

            if performance then insert( v.log, performance ) end

            local custom = ""

            local pack = self.DB.profile.packs[ state.system.packName ]
            if not pack.builtIn then
                custom = format( " |cFFFFA700(*%s[%d])|r", state.spec.name, state.spec.id )
            end

            local overview = format( "%s%s; %s|r", state.system.packName, custom, dispName or state.display )
            local recs = Hekili.DisplayPool[ dispName or state.display ].Recommendations

            for i, rec in ipairs( recs ) do
                if not rec.actionName then
                    if i == 1 then
                        overview = format( "%s - |cFF666666N/A|r", overview )
                    end
                    break
                end
                overview = format( "%s%s%s|cFFFFD100(%0.2f)|r", overview, ( i == 1 and " - " or ", " ), rec.actionName, rec.time )
            end

            insert( v.log, 1, overview )

            local snap = {
                header = "|cFFFFD100[" .. date( "%H:%M:%S" ) .. "]|r " .. overview,
                log = concat( v.log, "\n" ),
                data = ns.tableCopy( v.log ),
                recs = {}
            }

            insert( snapshots, snap )
            snapped = true
		end
    end

    -- Limit screenshot to once per login.
    if snapped then
        if Hekili.DB.profile.screenshot and ( not hasScreenshotted or Hekili.ManualSnapshot ) then
            Screenshot()
            hasScreenshotted = true
        end
        return true
    end

    return false
end

Hekili.Snapshots = ns.snapshots



ns.Tooltip = CreateFrame( "GameTooltip", "HekiliTooltip", UIParent, "GameTooltipTemplate" )
Hekili:ProfileFrame( "HekiliTooltip", ns.Tooltip )


Hekili.check = true
Hekili.Snapshots = ns.snapshots
Hekili.forceStealth = false
Hekili.forceStealth_count = 0
Hekili.autocastAction = nil
Hekili.autocastAction_check = false
Hekili.oneShotCast = false
Hekili.cycle_state = false
Hekili.stopautocast = false
Hekili.autoCastEnabled = false
Hekili.store = ""
Hekili.wa_indicator = false
Hekili.wa_timer_active = false
--Hekili.MajorToggle = true
--Hekili.SecondaryToggle = true

SLASH_AUTOCAST1 = "/autocast"

local hekili_autocast = CreateFrame("Frame")
local lastTime = 0  
local lastTime_ = 0  

hekili_autocast:RegisterEvent("ADDON_ACTION_FORBIDDEN")
hekili_autocast:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

hekili_autocast:SetScript("OnEvent", function(self, event, arg1)
      if event == "ADDON_ACTION_FORBIDDEN" then
         StaticPopup1:Hide()
      elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if Hekili.stopautocast and arg1 == "player" then
            Hekili.autoCastEnabled = true
            Hekili.stopautocast = false
            --print("插入中")
        end
      end
      
end)

Hekili.last_empower_time = GetTime()

hekili_autocast:SetScript("OnUpdate", function()
    local now = GetTime()
    local action = Hekili.autocastAction


    if not Hekili.DB.profile.toggles.autocast.speedRange then
        Hekili.DB.profile.toggles.autocast.speedRange = 0.3
    end
    if  action ~= nil then
        if action.delay == nil  then
            action.delay = 0
        end

    end
    if Hekili.wa_indicator and not Hekili.wa_timer_active then
        Hekili.wa_timer_active = true
    
        C_Timer.After(1, function()
            Hekili.wa_indicator = false
            Hekili.wa_timer_active = false
        end)
    end


    local cutoff = Hekili.DB.profile.toggles.autocast.cutoff
    local gcd_remains = getGCDRemains()
    if  Hekili.DB.profile.toggles.oneButtonRaotaion.value and Hekili.autoCastEnabled and not cutoff  and not tempStopMode() and (action.delay > gcd_remains + 0.2 or not action.actionName) and gcd_remains < 0.5 then
        autoHPPotion()
        local next_id_ = C_AssistedCombat.GetNextCastSpell()
        local next_id = FindBaseSpellByID(next_id_)
        local action_ = GetSpellLinkByID(next_id)
        if next_id and isInBattle(action_) and not IsMounted() and not IsInTravelForm() and not isInVehicle()  and not UnitIsDead( "player" ) then
            restartAttack()
            
            swapTarget()
            local _, _, _, _, _, _, _, ChannellingID = UnitChannelInfo("player")
            local meleeRange = Hekili.DB.profile.toggles.oneButtonRaotaion.targetRange 
            if not ChannellingID or ChannellingID == 115175 then
                if action_.terrain and Hekili:isMeleeSpec() and Hekili.getDistance("target") <= meleeRange then
                    CastSpellByID(1229376)
                elseif action_.terrain and not Hekili:isMeleeSpec() then
                    CastSpellByID(1229376)
                elseif Hekili:isMeleeSpec() and Hekili.getDistance("target") <= meleeRange then
                    CastSpellByID(next_id,"cursor")
                elseif not Hekili:isMeleeSpec() then
                    CastSpellByID(next_id,"cursor")
                end
            end
        end
  
    end


    if Hekili.autoCastEnabled and action ~= nil and not cutoff  and not tempStopMode() and isOfficialOpen() then
        autoHPPotion()
        if ((now - lastTime >= Hekili.DB.profile.toggles.autocast.speedRange/3 and action.gcd == "spell" and action.listName ~= "precombat" and not isFormationSpell(action)) or (now - lastTime >= 1 and (action.listName == "precombat" or isFormationSpell(action))) or (action.gcd ~= "spell" or isOfficialOpen()) and Hekili.autocastAction_check) and action.indicator ~= "wait" then  
     
           -- and action.delay < 0.5 
          
            if action.actionName ~= nil and isInBattle(action) and not IsMounted() and not IsInTravelForm() and not isInVehicle() and not UnitIsDead( "player" ) then

                local cast_ID, type = GetSpellIDByName(action)
                local _, _, _, _, _, _, _, ChannellingID = UnitChannelInfo("player")

                quickStopSpelling(action)
                restartAttack()
                swapTarget()
                if action.indicator then
                    if action.indicator == "cancel" then

                        SpellStopCasting()
                        return
                    end
                end

                Hekili.cycle_state = false
                if action.indicator == "cycle" and Hekili.State.settings.cycle and isInGCD() then
                    local isMelee = Hekili:isMeleeSpec()
                    TargetNearestEnemy()

                    if (Hekili.State.target.distance <= 5 and isMelee or Hekili.State.target.distance <= 30 and not isMelee) and UnitAffectingCombat("target") then
                        Hekili.cycle_state = true
                    else
                        TargetLastEnemy()
                    end
                    return
                else
                    Hekili.cycle_state = true
                end

                if type == 1 and action.empower_to == nil and (not ChannellingID or isSkippingChannelLock(ChannellingID)) and action.delay < 0.5 then
      
                    local name = GetLocalizedSpellName(cast_ID)
                    if action.toy then
                        UseToyByName(name)
                        return
                    end
                    -- print(name)
                    --print(action.target)
                    if Hekili.forceStealth == true  then
                        Hekili.forceStealth = false
                    end

                    if Hekili.cycle_state and action.indicator == "cycle" or action.indicator ~= "cycle"  then
                        if action.target then
                            if action.target ~= "none"  then
                    
                                if UnitExists("mouseover") and UnitIsFriend("player", "mouseover") and not isDispelAction(action.actionName) and isHealer() and Hekili:isMouseOverGroupMember() then
                                    CastSpellByName(name, "mouseover")
                                    CastSpellByName(name, action.target)
                                    return
                                else
                                    CastSpellByName(name, action.target)
                                    return
                                end
                                action.target = "cursor"
                            end
              
                        end

                        if Hekili.DB.profile.toggles.officialAuto.value and action.terrain then
                            local next_id_ = C_AssistedCombat.GetNextCastSpell()
                            local next_id = FindBaseSpellByID(next_id_)
                            if next_id == cast_ID and  UnitName("boss1") ~= "拉夏南" then
                                CastSpellByID(1229376)
                                return
                            end
                        end
                        local errorCast_state = errorCast(name)
                        if errorCast_state == false then
                            local terrain = Hekili.DB.profile.specs[ Hekili.State.spec.id ].abilities[action.actionName].toggle_terrain
                            if terrain == "default" or not terrain then
                                if action.toggle_terrain == "none" then
                                    CastSpellByName(name)
                                elseif action.toggle_terrain == "mouseover" and not Hekili:isMouseOverGroupMember() then
                                    if not UnitExists(action.toggle_terrain) then
                                        CastSpellByName(name)
                                    else
                                        CastSpellByName(name, action.toggle_terrain)
                                    end
                                elseif action.toggle_terrain == "focus" then
                                    if not UnitExists(action.toggle_terrain) then
                                        CastSpellByName(name)
                                    else
                                        CastSpellByName(name, action.toggle_terrain)
                                    end
                                elseif terrain == "random" and getGCDRemains() < 0.1 then
                                    local m = "/cast [@mouseover,exists,harm,nodead][@target]" .. name
                                    ClearTarget()
                                    TargetNearestEnemy()
                                    C_Macro.RunMacroText(m,1)
                                    TargetLastEnemy() 
                                    StartAttack()
                                else
                                    CastSpellByName(name, action.toggle_terrain)
                                end
                            else
                                if terrain == "none" then
                                    CastSpellByName(name,"cursor")
                                elseif terrain == "mouseover"  then
                                    if not UnitExists(terrain) then
                                        CastSpellByName(name,"cursor")
                                    else
                                        CastSpellByName(name, terrain)
                                    end
                                elseif terrain == "focus" then
                                  
                                    if not UnitExists(terrain) then
                                        CastSpellByName(name,"cursor")
                                    else
                                        CastSpellByName(name, terrain)
                                    end
                                elseif terrain == "random" and getGCDRemains() < 0.1 then
                                    local m = "/cast [@mouseover,exists,harm,nodead][@target]" .. name
                                    ClearTarget()
                                    TargetNearestEnemy()
                                    C_Macro.RunMacroText(m,1)
                                    TargetLastEnemy() 
                                    StartAttack()
                                else
                                    CastSpellByName(name, terrain)
                                end
                            end
                        end
                        Hekili.cycle_state = false
                    end

                    autoCooldowns()

                    Hekili.autocastAction_check = false
                    stealthCheck(name)
                elseif type == 1 and action.empower_to ~= nil and not isChanneling("player") then
                        local name = GetLocalizedSpellName(cast_ID)
                        local chargeLevel = GetCurrentEmpowerStage("player")
                        if Hekili.State.empowerment.hold == 0 and Hekili.empower_startTime == 0 and action.delay < 0.2 then
                            --print("startCharge"..tostring(chargeLevel))
                            CastSpellByName(name)
             
                        elseif chargeLevel >= action.empower_to  then
                            --print("finishCharge"..tostring(chargeLevel))
                            CastSpellByName(name)
                        
                        end
                        Hekili.empower_startTime = 0
                        chargeLevel = 0
                        Hekili.autocastAction_check = false
                    
                elseif type == 2 and not ChannellingID and not isCasting("player") then
                    local name = GetLocalizedItemName(cast_ID)
                    C_Item.UseItemByName(name, "cursor")
                    C_Item.UseItemByName(cast_ID, "cursor")
                    Hekili.autocastAction_check = false
                end


            end
            lastTime = now
        end
    end




    if Hekili.oneShotCast and Hekili.autocastAction_check and action ~= nil then
      
        if action.actionName ~= nil and IsMounted() == false and IsInTravelForm() == false  and not isInVehicle() then
  
            local cast_ID, type = GetSpellIDByName(action)
            local _, _, _, _, _, _, _, ChannellingID = UnitChannelInfo("player")
            quickStopSpelling(action)
            restartAttack()
            swapTarget()
            if action.indicator then
                if action.indicator == "cancel" then
                    SpellStopCasting()
                    return
                end
            end

            Hekili.cycle_state = false
            if action.indicator == "cycle" and Hekili.State.settings.cycle then
                local isMelee = Hekili:isMeleeSpec()
                TargetNearestEnemy()

                if (Hekili.State.target.distance <= 5 and isMelee or Hekili.State.target.distance <= 30 and not isMelee) and UnitAffectingCombat("target") then
                    Hekili.cycle_state = true
                else
                    TargetLastEnemy()
                end
                return
            else
                Hekili.cycle_state = true
            end
            
            if type == 1 and action.empower_to == nil and (not ChannellingID or isSkippingChannelLock(ChannellingID)) and action.delay < 0.5   then
                local name = GetLocalizedSpellName(cast_ID)
                if action.toy then
                    UseToyByName(name)
                    return
                end
                if Hekili.cycle_state and action.indicator == "cycle" or action.indicator ~= "cycle"  then
                    if action.target then
                        if action.target ~= "none"  then
                            if UnitExists("mouseover") and UnitIsFriend("player", "mouseover") and not isDispelAction(action.actionName) and isHealer() then
                                if Hekili:isMouseOverGroupMember() then
                                    CastSpellByName(name, "mouseover")
                                    CastSpellByName(name, action.target)
                                    Hekili.oneShotCast = false
                                    return  
                                end
                            else
                                CastSpellByName(name, action.target)
                                Hekili.oneShotCast = false
                                return  
                            end
                        action.target = "target"
                        end
                    
                    end

                    local errorCast_state = errorCast(name)
                    if errorCast_state == false then
                        local terrain = Hekili.DB.profile.specs[ Hekili.State.spec.id ].abilities[action.actionName].toggle_terrain
                        if terrain == "default" or not terrain then
                            if action.toggle_terrain == "none" then
                                CastSpellByName(name)
                            elseif action.toggle_terrain == "mouseover" or action.toggle_terrain == "focus" then
                                if not UnitExists(action.toggle_terrain) then
                                    CastSpellByName(name)
                                else
                                    CastSpellByName(name, action.toggle_terrain)
                                end
                            elseif terrain == "random" and getGCDRemains() < 0.1 then
                                local m = "/cast [@mouseover,exists,harm,nodead][@target]" .. name
                                ClearTarget()
                                TargetNearestEnemy()
                                C_Macro.RunMacroText(m,1)
                                TargetLastEnemy() 
                                StartAttack()
                            else
                                CastSpellByName(name, action.toggle_terrain)
                            end
                        else
               
                            if terrain == "none" then
                                CastSpellByName(name)
                            elseif terrain == "mouseover" or terrain == "focus" then
                                if not UnitExists(terrain) then
                                    CastSpellByName(name)
                                else
                                    CastSpellByName(name, terrain)
                                end
                            elseif terrain == "random"  then
                                local m = "/cast [@mouseover,exists,harm,nodead][@target]" .. name
                                ClearTarget()
                                TargetNearestEnemy()
                                C_Macro.RunMacroText(m,1)
                                TargetLastEnemy() 
                                StartAttack()
                            else
                                CastSpellByName(name, terrain)
                            end
                        end
                    end
                    Hekili.oneShotCast = false
                    Hekili.cycle_state = false
                end

                autoCooldowns()
     

                Hekili.autocastAction_check = false
    

            elseif type == 1 and action.empower_to ~= nil and not isChanneling("player") then
                local name = GetLocalizedSpellName(cast_ID)
                local chargeLevel = GetCurrentEmpowerStage("player")
            
                if Hekili.State.empowerment.hold == 0 and Hekili.empower_startTime == 0 and action.delay < 0.1 then
                    CastSpellByName(name)
                    Hekili.autocastAction_check = false 
                    Hekili.oneShotCast = false
                elseif chargeLevel >= action.empower_to  then
                    CastSpellByName(name)
                    Hekili.autocastAction_check = false  
                    Hekili.oneShotCast = false

                end
                chargeLevel = 0
                Hekili.empower_startTime = 0
                Hekili.autocastAction_check = false
            elseif type == 2 and not ChannellingID and not isCasting("player") then
                local name = GetLocalizedItemName(cast_ID)
                C_Item.UseItemByName(name,"cursor")
                C_Item.UseItemByName(cast_ID, "cursor")
                Hekili.oneShotCast = false
                Hekili.autocastAction_check = false
            end
            
            
            
        end
        Hekili.oneShotCast = false
    end
    
end)

function autoCooldowns()
    local inInstance, instanceType = IsInInstance()
    if instanceType == "party" or instanceType == "raid" then
        if Hekili.DB.profile.toggles.autoCooldowns.value and not Hekili:isHealerSpec() and not Hekili:isTankSpec() then
            if Hekili:GetTotalEnemyCombatHealth(30) >=  Hekili.DB.profile.toggles.autoCooldowns.threshold*UnitHealthMax("player") then
                Hekili:FireToggle("cooldowns","on", false)
            else
                Hekili:FireToggle("cooldowns","off", false)
            end
            return
        end
    
        if Hekili.DB.profile.toggles.autoCooldowns.value2 and not Hekili:isHealerSpec() and not Hekili:isTankSpec() then
            if Hekili:GetTotalEnemyCombatHealth(30) <= Hekili.DB.profile.toggles.autoCooldowns.threshold*UnitHealthMax("player") then
                Hekili:FireToggle("cooldowns","off", false)
            end
        end
    end

    
end

function isInVehicle()
    local _, _, _, _,_, _, _, instanceID, _, _ = GetInstanceInfo()
    if instanceID == 2441 then
        return false
    end

    return UnitInVehicle("player")
end

function autoHPPotion()
    if UnitHealth("player")/UnitHealthMax("player")*100 <= Hekili.DB.profile.toggles.autoHPPotion.autoHPPotion_threshold and Hekili.DB.profile.toggles.autoHPPotion.value then
        if Hekili.State.action.invigorating_healing_potion.known and Hekili.State.cooldown.invigorating_healing_potion.up then
            C_Item.UseItemByName("焕生治疗药水")
            C_Item.UseItemByName(244839)
            C_Item.UseItemByName(244825)
            C_Item.UseItemByName(244838)
            return
        end

        if Hekili.State.action.algari_healing_potion.known and Hekili.State.cooldown.algari_healing_potion.up then
            C_Item.UseItemByName("阿加治疗药水")
            C_Item.UseItemByName(211880)
            C_Item.UseItemByName(211879)
            C_Item.UseItemByName(211878)
            return
        end

        local item = Hekili.State.talent.pact_of_gluttony.enabled and 224464 or 5512
        if  C_Item.GetItemCount( item ) ~= 0  and C_Item.IsUsableItem( item ) then
            C_Item.UseItemByName(item)
            return
        end
    end
end



function quickStopSpelling(action)
    local spec = GetCurrentSpec()
    local name = action.actionName
    if Hekili.State.boss and not Hekili:isMeleeSpec() then
        Hekili.DB.profile.specs[ Hekili.State.spec.id ].nameplates = false
    else
        Hekili.DB.profile.specs[ Hekili.State.spec.id ].nameplates = true
    end
    if Hekili.autocastAction.cancelSpell then
        local spellName, _, _, _, startTime, endTime, _, spellID, isEmpowered = UnitChannelInfo("player")
        local essential = false
        if spellName and not isEmpowered then
            if spellID == 12051 or spellID == 382440  then
                essential = true
            end
        else
            essential = false
        end 
        if (isCasting("player") or isChanneling("player")) and essential and not Hekili:isTankSpec() and not Hekili:isHealerSpec()  then
            SpellStopCasting()
        end
    
    end
    if spec == "火焰" then
        local hot_streak = Hekili:isPlayerAuraExist(48108 )
        if Hekili:isPlayerAuraExist(383874 ) and isCasting("player") then
            SpellStopCasting()
        end
    
        -- if  Hekili.State.prev[1].spell == "scorch" and hot_streak then
        --     SpellStopCasting()
        -- end
        -- if (name == "fire_blast" or name == "phoenix_flames") and Hekili:isPlayerAuraExist(48107 ) and isCasting("player") and Hekili.State.cooldown.combustion.remains > then
        --     SpellStopCasting()
        -- end

        if Hekili:isPlayerAuraExist(190319 ) and isCasting("player") and hot_streak then
            SpellStopCasting()
        end

        local spellName, _, _, _, startTime, endTime, _, spellID = UnitCastingInfo("player")
        if spellName == "炎爆术" or spellName == "烈焰风暴" then
            SpellStopCasting()
        end 
        -- if name == "fire_blast"  and isCasting("player") and hot_streak then
        --     SpellStopCasting()
        -- elseif name == "phoenix_flames"  and isCasting("player") and hot_streak  then
        --     SpellStopCasting()
        -- end

        -- if ( name == "flamestrike" or name == "pyroblast" ) and hot_streak and isCasting("player") then
        --     SpellStopCasting()
        -- end

    -- elseif spec == "恶魔" or spec == "恶魔学识" then
    --     PetAttack()
    -- elseif spec == "射击" or spec == "野兽控制"  or spec == "生存"  then
        -- if Hekili:isPlayerAuraExist(5384) then
        --     Hekili.autoCastEnabled = false
        -- end
        -- if name == "aimed_shot" and isCasting("player")  then
            
        --     local spellName, _, _, _, startTime, endTime, _, spellID = UnitCastingInfo("player")
     
        --     if spellName == "稳固射击" and not Hekili.State.moving and Hekili.State.focus.current > 35 then
        --         print(action.delay)
        --         SpellStopCasting()
        --     end 
        -- end
    end
    
end

function isSkippingChannelLock(channelID)
    if channelID == 115175 or channelID == 263165 or channelID == 5143 or channelID == 15407 then
        return true
    else
        return false
    end
end

function isFormationSpell(action)
    return action.formation or false
end

function isOfficialOpen()
   return ( Hekili.DB.profile.toggles.oneButtonRaotaion.value2 and Hekili.DB.profile.toggles.oneButtonRaotaion.value or not Hekili.DB.profile.toggles.oneButtonRaotaion.value)
end

function errorCast(name)

    local spec = GetCurrentSpec()
    --rint(spec)
    if name == "剑刃风暴" then
        CastSpellByID(227847)
        return true
    elseif name == "假死"  then
        CastSpellByName("假死")
        Hekili:Notify( "喵！自动假死驱散！动一下！", 6 )
        return true
    elseif name == "精神鞭笞"  then
        CastSpellByName("精神鞭笞")
        CastSpellByName("精神鞭笞：狂")
        return true
    elseif name == "精神鞭笞：狂"  then
        CastSpellByName("精神鞭笞：狂")
        CastSpellByName("精神鞭笞")
        return true
    elseif name == "圣言祭礼"  then
        CastSpellByName("圣言祭礼")
        UseInventoryItem(16)
        return true
    elseif name == "顺劈斩"  then
        CastSpellByName("顺劈斩")
        CastSpellByName("旋风斩")
        return true
    elseif name == "吸血鬼打击" and spec == "邪恶" then
        CastSpellByName("吸血鬼打击")
        CastSpellByName("天灾打击")
        return true
    elseif name == "吸血鬼打击" and spec == "鲜血" then
        --CastSpellByID(433895)
        CastSpellByName("吸血鬼打击")
        CastSpellByName("心脏打击")
        return true
    elseif name == "圣光之锤" and spec == "惩戒"  then
        --CastSpellByID(433895)
        CastSpellByName("圣光之锤")
        CastSpellByName("灰烬觉醒")
        return true
        
    elseif name == "圣光之锤" and spec == "防护"  then
        --CastSpellByID(433895)
        CastSpellByName("圣光之锤")
        CastSpellByName("提尔之眼")
        return true

    elseif name == "圣洁武器"  then
        --CastSpellByID(433895)
        CastSpellByName("圣洁武器","player")
        CastSpellByName("神圣壁垒","player")
        return true
    elseif name == "神圣壁垒"  then
        --CastSpellByID(433895)
        CastSpellByName("神圣壁垒","player")
        CastSpellByName("圣洁武器","player")
        
        return true
    elseif name == "回归"  or name == "深呼吸"  then
        if not Hekili:isPlayerAuraExist(433874) then
            --CastSpellByID(433895)
            CastSpellByName("空间悖论")
            --CastSpellByName("回归")
            CastSpellByName("深呼吸")
        end

        return true
    elseif name == "浴血奋战"   then
        --CastSpellByID(433895)
        CastSpellByName("浴血奋战")
        CastSpellByName("暴怒")
        return true
    elseif name == "风暴打击"  and spec == "增强"  then
        --CastSpellByID(433895)
        CastSpellByName("风暴打击")
        CastSpellByName("风暴打击")
        --CastSpellByName("涌动图腾")
        return true
    elseif name == "暗影魔" or name == "虚空幽灵" or name == "摧心魔"  then
        --CastSpellByID(433895)
        CastSpellByName("暗影魔")
        CastSpellByName("虚空幽灵")
        CastSpellByName("摧心魔")
        return true
    elseif name == "虚空冲击"  then
        --CastSpellByID(433895)
        CastSpellByName("虚空冲击")
        CastSpellByName("惩击")
        return true
    elseif name == "惩击"  then
        --CastSpellByID(433895)
        CastSpellByName("惩击")
        CastSpellByName("虚空冲击")
        return true
    elseif name == "惩击" or name == "暗影冲击" and spec == "戒律" then
        --CastSpellByID(433895)
        CastSpellByName("惩击")
        CastSpellByName("暗影冲击")
        return true
    -- elseif name == "苦修" and spec == "戒律" then
    --     --CastSpellByID(433895)
    --     CastSpellByName("苦修")
    --     CastSpellByName("黑暗训斥")
    --     return true
    -- elseif name == "黑暗训斥" and spec == "戒律" then
    --     --CastSpellByID(433895)
    --     CastSpellByName("黑暗训斥")
    --     CastSpellByName("苦修")
    --     return true
    elseif name == "心灵震爆" or name == "暗影冲击" and spec == "暗影" then
        --CastSpellByID(433895)
        CastSpellByName("心灵震爆")
        CastSpellByName("暗影冲击")
        return true
    elseif name == "怒击"   then
        --CastSpellByID(433895)
        CastSpellByName("怒击")
        CastSpellByName("碎甲猛击")

        return true
    -- elseif name == "消失"   then
    --     if not isInGCD() then
    --         CastSpellByName("消失")
    --     end
    --     return true
    elseif name == "影遁"   then
        if not isInGCD() then
            CastSpellByName("影遁")
        end
        return true
    -- elseif name == "火焰冲击"  then
    --     if not Hekili:isPlayerAuraExist(48108) and not isCasting("player") and not isInGCD() then
    --         last_scorch_time = GetTime()
    --         CastSpellByName("火焰冲击")
    --     end
    --     return true
    elseif name == "燃烧"   then
        --if not isCasting("player") then
            CastSpellByName("燃烧")
        --end
        return true
    -- elseif name == "火球术" or name == "灼烧" or name == "不死鸟之焰" then
    --     local hot_streak =  Hekili:isPlayerAuraExist(48108 )
    --     if not isCasting("player") and not hot_streak and GetTime() - last_scorch_time > 0.2 then
    --         CastSpellByName(name)
    --     end
    --     return true

    end
    return false
end

function isHealer()
    local spec = GetCurrentSpec()
    if spec == "戒律" or spec == "恢复" or spec == "神圣" or spec == "恩护" or spec == "织雾"then
        return true
    end
    return false
end

function gcdCheck(gcd)
    if isInGCD() and gcd == "spell" then
        return false
    elseif isInGCD() and gcd == "off" then
        return true
    else
        return true
    end
end

function selfTerrainCast(name)
    if name == "涌动图腾" then
        CastSpellByName(name,"player")
        return true
    elseif name == "破坏者" then
        CastSpellByName(name,"player")
        return true
    elseif name == "爆炸酒桶" then
        CastSpellByName(name,"player")
        return true
    elseif name == "枯萎凋零" then
        CastSpellByName(name,"player")
        return true
    elseif name == "烈焰咒符" then
        CastSpellByName(name,"player")
        return true
    elseif name == "怨念咒符" then
        CastSpellByName(name,"player")
        return true
    elseif name == "末日咒符" then
        CastSpellByName(name,"player")
        return true
    elseif name == "恶魔变形" then
        CastSpellByName(name,"player")
        return true
    elseif name == "亵渎" then
        CastSpellByName(name,"player")
        return true
    elseif name == "最终清算" then
        CastSpellByName(name,"player")
        return true
    elseif name == "勇士之矛" then
        CastSpellByName(name,"player")
        return true
    end
    return false
end


function isDispelAction(action)
    if action == "purify" and action == "cleanse" and action == "detox" and action == "natures_cure" and action == "cleanse_spirit" then
        return true
    end
    return false
end

function isInBattle(action)
    if action then
         return (UnitAffectingCombat("player") or Hekili:isTankInBattle() or Hekili.forceStealth or Hekili.DB.profile.toggles.oneshot.value2 or not action.startsCombat and action.listName == "precombat") and not UnitIsGhost("player")
    else
        return (UnitAffectingCombat("player") or Hekili:isTankInBattle() or Hekili.forceStealth or Hekili.DB.profile.toggles.oneshot.value2) and not UnitIsGhost("player")
    end
   
end

function isInSafeState()
    if Hekili:isPlayerAuraExist(113862) or Hekili:isPlayerAuraExist(199483) or Hekili:isPlayerAuraExist(5384) then
        return true
    end
    return false
end

function swapTarget()
    if not UnitExists("target") or UnitIsDead("target") then
        local s, unit = Hekili:isTankInBattle()
        if s then
            AssistUnit(unit)
            if not UnitAffectingCombat("target") then
                ClearTarget()
            end
        end
    end

end

function Hekili:isPlayerAuraExist(auraId)

    local aura = C_UnitAuras.GetPlayerAuraBySpellID(auraId)
    if aura then
       
        local remainingTime = aura.expirationTime - GetTime()
        local totalTime = aura.duration  
        local percentage = (remainingTime / totalTime)
        
        return true, percentage  
    else return false, 0
    end
end

function IsInTravelForm()

    local formID = GetShapeshiftFormID()

    return formID == 3 or formID == 27 
 end




function IsTalentSelected(nodeID)

    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then
        return false 
    end

    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo then
        return false 
    end

    return nodeInfo.currentRank > 0
end

Hekili.empower_startTime = 0

function GetCurrentEmpowerStage()

    local stages = {}
    local state = Hekili.State
    local numStages = 3
    local totalEmpowerTime = 0
    if state.spec.id == 1467 then
        if state.talent.font_of_magic.enabled then
            numStages = numStages + 1
        end
    end
    for stage = 1, numStages do
        local ms = GetUnitEmpowerStageDuration("player", stage-1)
        if ms then
            stages[stage] = ms * 0.001
            totalEmpowerTime = totalEmpowerTime  + ms
           --print(string.format("Stage %d duration: %.2f 秒", stage, ms ))
        else
           break
        end
    end
    --print(string.format("total Stage duration: %.2f 秒", totalEmpowerTime ))
    if totalEmpowerTime ~= 0 then
        local name, _, _, startTimeMs, endTimeMs, _, _, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo("player")
        --print(spellID)
        if spellID == 1217413 then
            startTimeMs = startTimeMs+100
        end
        if name then
            Hekili.empower_startTime = startTimeMs * 0.001
        end
        --print(string.format("start_time: %.2f 秒", Hekili.empower_startTime ))
        for stage = 1, numStages do
            if stage == 1 then
                stages[stage] = Hekili.empower_startTime + stages[stage] 
            else
                stages[stage] = stages[stage]  + stages[stage-1]
            end
            
            --print(string.format("Stage %d duration: %.2f 秒", stage, stages[stage] ))
        end
        for stage = numStages, 1, -1 do
            if GetTime() >= stages[stage] then
                return stage
            end
        end

    end
    return 0

 end



function stealthCheck(name)

    if name == "消失" or name == "影遁" then
        Hekili.forceStealth = true
    end
    
end

function restartAttack()
    local spec = GetCurrentSpec()
    if spec ==  "踏风" or spec ==  "狂暴" or spec ==  "武器" or spec ==  "惩戒" 
    or spec ==  "生存" or spec ==  "奇袭" or spec ==  "狂徒" or spec ==  "敏锐" 
    or spec ==  "冰霜" or spec ==  "邪恶" or spec ==  "增强" or spec ==  "野性" 
    or spec ==  "浩劫" or spec ==  "射击" or spec ==  "生存" or spec ==  "野兽控制"
    or spec ==  "复仇" or spec ==  "防御" or spec ==  "酒仙" or spec ==  "守护" or spec ==  "鲜血" or spec ==  "防护" or spec ==  "神圣" or spec ==  "织雾" then
        local isAutoAttacking = C_Spell.IsCurrentSpell(6603) -- 6603 是自动攻击的技能 ID
        if not isAutoAttacking and UnitAffectingCombat("player") then
            if spec ==  "射击" or spec ==  "生存" or spec ==  "野兽控制" then
                if Hekili.State.buff.feign_death.down then
                    StartAttack("target")
                end
            else
                StartAttack("target")
            end

        end
    end
end

function Hekili:isMeleeSpec()
    local spec = Hekili:GetSpec().name
    local spec_id = Hekili:GetSpec().id
    if spec ==  "踏风" or spec ==  "狂怒" or spec ==  "武器" or spec ==  "惩戒" 
    or spec ==  "生存" or spec ==  "奇袭" or spec ==  "狂徒" or spec ==  "敏锐" 
    or spec ==  "冰霜" and spec_id ~= 64 or spec ==  "邪恶" or spec ==  "增强" or spec ==  "野性" 
    or spec ==  "浩劫" or spec ==  "生存" or spec ==  "复仇" or spec ==  "防御" 
    or spec ==  "酒仙" or spec ==  "守护" or spec ==  "鲜血" or spec ==  "防护" or spec ==  "神圣" or spec ==  "织雾" then
        return true
    else
        return false
    end
end

function Hekili:isTankSpec()
    local spec = GetCurrentSpec()
    if  spec ==  "复仇" or spec ==  "防御" 
    or spec ==  "酒仙" or spec ==  "守护" or spec ==  "鲜血" or spec ==  "防护" then
        return true
    else
        return false
    end
end

function Hekili:isHealerSpec()
    local spec = GetCurrentSpec()
    if  spec ==  "织雾" or spec ==  "恢复" 
    or spec ==  "戒律" or spec ==  "神圣" or spec ==  "恩护"  then
        return true
    else
        return false
    end
end


function Hekili:isInRaidInstance()
    local _, zone, _, _, _, _, _, instanceID = GetInstanceInfo()
    if instanceID then
        if instanceID == 2769 then
            return true
        else
            return false
        end
    end

end
function isInGCD()
    local cd = C_Spell.GetSpellCooldown(61304) 
    local now = GetTime()
    local remains = (cd.startTime + cd.duration) - now
    if remains < 0 then
       remains = 0
    end
    return remains > 0, remains
end

function getGCDRemains()
    local cd = C_Spell.GetSpellCooldown(61304) 
    local now = GetTime()
    local remains = (cd.startTime + cd.duration) - now
    if remains < 0 then
       remains = 0
    end
    return remains
end

function GetCurrentSpec()
    local currentSpec = GetSpecialization()
    if currentSpec then
        local _, currentSpecName = GetSpecializationInfo(currentSpec)
        return currentSpecName
    end
    return nil
end

function GetLocalizedSpellName(spellID)
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        return spellInfo.name  
    else
        return nil 
    end
end


function GetLocalizedItemName(itemID)
    local itemName = C_Item.GetItemInfo(itemID) 
    if itemName then
        return itemName 
    else
        return nil  
    end
end

--1法术 2物品 3打断
function GetSpellIDByName(ability)


    if ability.actionID and ability.actionID > 10 and not ability.item then
        return ability.actionID, 1
    end
    
    local item = Hekili.Class.abilities[ability.actionName]

    if item.item then
        return item.item, 2  
    end

    return nil  
end



function GetSpellLinkByID(id)
   
    local ability = Hekili.Class.abilities[id]
    if ability.id and ability.id > 10 then
       
       return ability
       
    end
 end

local HekiliPingFrame = CreateFrame("Frame")
HekiliPingFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix("HEKILI_PING")

local function SendPing(channel)
    C_ChatInfo.SendAddonMessage("HEKILI_PING", "ping", channel)
    print("你发送了 ping，等待回应...")
end




SLASH_HEKILIPING1 = "/autohekili"
SlashCmdList["HEKILIPING"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local channel
    if IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        channel = "PARTY"
    end
    if args[1] == "ping" then
        SendPing(channel)
    elseif args[1] == "ping1" then
        Hekili.SendCommand("ping")
    elseif args[1] == "pingByName" and args[2] then
        Hekili.SendCommandByName("ping",args[2])
    elseif args[1] == "check1" then
        Hekili.SendCommand("check")
    elseif args[1] == "freeze"  then
        Hekili.SendCommand("freeze")
    elseif args[1] == "unfreeze"  then
        Hekili.SendCommand("unfreeze")
    elseif args[1] == "freezeByName" and args[2] then
        Hekili.SendCommandByName("freeze",args[2])
    elseif args[1] == "unfreezeByName" and args[2] then
        Hekili.SendCommandByName("unfreeze",args[2])
    elseif args[1] == "jump"  then
        Hekili.SendCommand("jump")
    elseif args[1] == "jumpByName" and args[2] then
        Hekili.SendCommandByName("jump",args[2])
    elseif args[1] == "follow"  then
        Hekili.SendCommand("follow")
    elseif args[1] == "check" then
        C_ChatInfo.SendAddonMessage("HEKILI_PING", "check", channel)
        print("|cffff0000你发送了 check")
    end
end

HekiliPingFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix ~= "HEKILI_PING" then return end
    if sender ~= Hekili.GetFullName("player") then
        if message == "ping" then

            local simc = Hekili.DB.profile.specs[ Hekili.State.spec.id ].package
            local toggle = Hekili.autoCastEnabled
            C_ChatInfo.SendAddonMessage("HEKILI_PING",  tostring(simc).." Toggle: "..tostring(toggle), "WHISPER", sender)

        elseif message == "check" then
            Hekili:Notify(Hekili.pingcheckstr2)
            print(Hekili.pingcheckstr)
        elseif message == "freeze" then
            Hekili.DB.profile.toggles.autocast.cutoff = true
        elseif message == "unfreeze" then
            Hekili.DB.profile.toggles.autocast.cutoff = false
        elseif message == "jump" then
            JumpOrAscendStart()
        elseif message == "follow" then
            local playerName = sender:match("([^%-]+)")
            local m = "/follow ".. playerName
            C_Macro.RunMacroText(m, 2)
        elseif message ~= nil then
        
            print("|cff00ff00" .. sender .. "  Profile: ".. message)
        end
    end
end)


function isInterrupt(spellName)
    local interruptSpell = {"mind_freeze", "disrupt", "skull_bash", "solar_beam", "counter_shot", "counterspell", "spear_hand_strike", "rebuke", "silence", "kick", "wind_shear", "spell_lock", "pummel","quell"}
    for _, i in ipairs(interruptSpell) do
        if i == spellName then
            return true
        end
    end
    return false
end

function isChanneling(unit)
    local spellName, _, _, _, startTime, endTime, _, spellID, isEmpowered = UnitChannelInfo(unit)
    if spellName and not isEmpowered then
        return true, spellName
    else
        return false, nil
    end 
end

function isEmpowerment(spellName)
    if spellName == "切削之风" or spellName == "火焰吐息" or spellName == "永恒之涌" or spellName == "精神之花" or spellName == "梦境吐息" or spellName == "地壳激变" then
        return true
    else
        return false
    end
end

function isCasting(unit)
    local spellName, _, _, _, startTime, endTime, _, spellID = UnitCastingInfo(unit)
    if spellName and not isEmpowerment(spellName) then
        return true
    else
        return false
    end 
end

function GetVisibleNameplateCountInRange(spellIdentifier)
    local nameplates = C_NamePlate.GetNamePlates()
    local count = 0
    for _, nameplate in ipairs(nameplates) do
        local unit = nameplate.unitFrame.unit  
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local inRange = C_Spell.IsSpellInRange(spellIdentifier, unit)
            if inRange then
                count = count + 1
            end
        end
    end

    return count 
end

function Hekili.getDistance(unitToken)
    local minR, maxR = RC:GetRange( unitToken )
    minR = minR or 5
    maxR = maxR or 10
    return (minR + maxR) / 2 or 7.5
end

do
    local timeStamp = 0
    function tempStopMode()
        local toggle = Hekili.DB.profile.toggles.tempStopMode.value
        local toggle2 = Hekili.DB.profile.toggles.tempStopMode.value2
        local threshold = Hekili.DB.profile.toggles.tempStopMode.threshold or 0.1
        if not toggle then return false end

        if IsKeyPressed() and not Hekili.wa_indicator then
            timeStamp = GetTime() + getGCDRemains() + threshold
            if toggle2 then
                SpellStopCasting()
            end
        end

        if GetTime() > timeStamp then
            Hekili.wa_indicator = false
            timeStamp = 0
            return false
        end
        return true
    end
end

function IsKeyPressed()
    local toggle = Hekili.DB.profile.toggles.tempStopMode.value
    if not toggle then return false end
    local input_keys = Hekili.DB.profile.toggles.tempStopMode.excludeList
    for key in string.gmatch(input_keys, "[^,%s]+") do
 
        if IsKeyDown(key) and not IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown() then
            return true
        end

        -- Alt + Key
        if IsAltKeyDown() and IsKeyDown(key) then
            return true
        end

        -- Shift + Key
        if IsShiftKeyDown() and IsKeyDown(key) then
            return true
        end

        -- Ctrl + Key
        if IsControlKeyDown() and IsKeyDown(key) then
            return true
        end
    end

    return false
end


 function Hekili:isMoveKeyPressed()
    local keys = {"W", "A", "S", "D"}
    for _, key in ipairs(keys) do
        if IsKeyDown(key) then
            return true
        end
    end
    return false
 end

SlashCmdList["AUTOCAST"] = function(msg)

    if msg == "on" then
        --Hekili.autoCastEnabled = true
        Hekili.oneShotCast = true
        --print("自动施法已启用")
    elseif msg == "off" then
        Hekili.autoCastEnabled = false
        Hekili.oneShotCast = false
        Hekili.stopautocast = true
        --print("自动施法已禁用")
    else
        Hekili.autoCastEnabled = not Hekili.autoCastEnabled
        if Hekili.autoCastEnabled then
            --print("一键模式自动施法已启用")
            Hekili:FireToggle("autocast","on", true)
        else
            Hekili:FireToggle("autocast","off", true)
            --print("一键模式自动施法已禁用")
        end
        --Hekili.autoCastEnabled = false
    end

end

