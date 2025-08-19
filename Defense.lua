local addon, ns = ...
local Hekili = _G[addon]
local RC = LibStub( "LibRangeCheck-3.0" )
local UnitBuff, UnitDebuff = ns.UnitBuff, ns.UnitDebuff
Hekili.UnitDebuff = UnitDebuff
-- Hekili.UnitBuff = UnitBuff
Hekili.FindUnitBuffByID = ns.FindUnitBuffByID
local format = string.format
local insert, remove, wipe = table.insert, table.remove, table.wipe
Hekili.pingcheckstr = "|cff00ff00随机Hekili网络防盗版系统启动\n\n请在2分钟内于队伍/团队中说出：QQ群的开头名称中的任意一个字!\n\n并在副本结束后联系群内管理员并提供卡密为证明!\n\n否则，5分钟后我们会强制停止你的自动输出\n\n2H后强制冻结你的订阅卡密/战网!\n\n会有网络存档！请重视!\n\n非订阅者请无视!\n"
Hekili.pingcheckstr2 = "Hekili网络防盗版系统已启动,请按照聊天频道指示行动"
Hekili.excludeDispelWarning = false


local unitIDs = { "target", "targettarget", "focus", "focustarget", "boss1", "boss2", "boss3", "boss4", "boss5", "arena1", "arena2", "arena3", "arena4", "arena5" }

local lowHealthRangeSpell_magic_dps = {465827,473070,468813,460156,448791,428169,323393,1241693,1241693,426787,448888,1221532}

local lowHealthRangeSpell_physic_dps = {427609,448492,326409,349934,346742,438877,438476}

local targetMeSpell_magic_dps = {446649,448787,319941}

local targetMeSpell_physic_dps = {7629,446776,353312,352345}

local dot_magic_dps = {473713,468815,446368,446403,1236512,1236513,1236514,335338,344874,1240097,433740,461507,438618,448248,431365,426735,451119,434441,1217439,1236126,1239487,1219704,1226444}

local dot_physic_dps = {453461,427621,427635}

local lowHealthRangeSpell_magic = lowHealthRangeSpell_magic_dps

local lowHealthRangeSpell_physic = lowHealthRangeSpell_physic_dps

local targetMeSpell_magic = targetMeSpell_magic_dps

local targetMeSpell_physic = targetMeSpell_physic_dps

local dot_magic = dot_magic_dps

local dot_physic = dot_physic_dps


function Hekili.print(content)
    print(content)
end

function Hekili.GetFullName(target)
    local name, realm = UnitFullName(target)
    if realm and realm ~= "" then
        return name .. "-" .. realm
    else
        return name
    end
end

function Hekili.isEasyTankingBoss()
    local easyBossList = {"艾谢朗", "高阶裁决官阿丽兹", "P.O.S.T.总管", "隐修院长穆普雷", "索·阿兹密", "索·莉亚", "收割者吉卡塔尔", "拉夏南", "布朗派克男爵", "阿兹希卡", "撰魂师"}

    local boss = UnitName("boss1")
    if boss then
        for _, value in ipairs(easyBossList) do
            if boss == value then
                return true
            end
        end
    end
    return false
end

function Hekili.SendCommand(command)
    if UnitExists("target") then
        local target = Hekili.GetFullName("target")
        C_ChatInfo.SendAddonMessage("HEKILI_PING", command, "WHISPER", target)
        print("|cffff0000已向 " .. target .. " 发送" ..command.."指令")
    end
end

function Hekili.SendCommandByName(command,name)

    C_ChatInfo.SendAddonMessage("HEKILI_PING", command, "WHISPER", name)
    print("|cffff0000已向 " .. name .. " 发送" ..command.."指令")

end

do
    local excludedAuraSet = nil
    local lastOptionValue = nil
    function Hekili.isExcludedDespelAura(id)
        local optionValue = Hekili.DB.profile.toggles.autoHealing.excludeList

        if optionValue ~= lastOptionValue then
            excludedAuraSet = {}
            for segment in string.gmatch(optionValue, "([^,]+)") do
                local spellID = tonumber(segment:match("^%s*(.-)%s*$"))
                if spellID then
                    excludedAuraSet[spellID] = true
                end
            end
            lastOptionValue = optionValue
        end

        return excludedAuraSet and excludedAuraSet[id] or false
    end
end


function Hekili:getCurrentSpelling(unit)
    local _, _, _, startTimeMS, endTimeMS, _, _, _, spellId = UnitCastingInfo(unit)

    if not spellId then
        _, _, _, startTimeMS, endTimeMS, _, _, spellId = UnitChannelInfo(unit)
        if not spellId then return 0, 0 end
        local now = GetTime() * 1000  
        local duration = endTimeMS - startTimeMS
        local elapsed = now - startTimeMS
        local remaining = duration - elapsed
        local percentRemaining = remaining / duration*100
        return spellId, percentRemaining
    else
        local now = GetTime() * 1000
        local duration = endTimeMS - startTimeMS
        local elapsed = now - startTimeMS
        local remaining = duration - elapsed
        local percentRemaining = remaining / duration*100
        return spellId, percentRemaining
    end

    return 0, 0

end

function Hekili:getSpellingTarget()
    if not Hekili.DB.profile.toggles.interrupts.value2 and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
                local remainingTime = (endTimeMS / 1000) - GetTime()
                if remainingTime <= (Hekili.DB.profile.toggles.interrupts.castRemainingThreshold or 1) then
                    return unit
                end
            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                return unit
            end
        end


    end
    return "none"

end


function Hekili:isTargetSpellingMagicRangeSpell()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
                for _, v in ipairs(lowHealthRangeSpell_magic) do
                    local remainingTime = (endTimeMS / 1000) - GetTime()
                    if v == spellId and remainingTime <= 1 then
                        return true
                    end
                end

            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                local now = GetTime() * 1000  
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration
                for _, v in ipairs(lowHealthRangeSpell_magic) do
                    if v == spellID and percentRemaining > 0.3 then
                        return true
                    end
                end

            end
        end


    end
    return false

end

function Hekili:isTargetSpelling()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
            if spellID then
                local now = GetTime() * 1000  
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration * 100
                if percentRemaining < 90 then
                    return true
                end


            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                local now = GetTime() * 1000  
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration
                if percentRemaining < 90 then
                    return true
                end

            end
        end
    end
    return false

end

function Hekili:isTargetSpellingPhysicRangeSpell()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
                for _, v in ipairs(lowHealthRangeSpell_physic) do
                    local remainingTime = (endTimeMS / 1000) - GetTime()
                    if v == spellId and remainingTime <= 1 then
                        return true
                    end
                end

            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                local now = GetTime() * 1000  
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration

                for _, v in ipairs(lowHealthRangeSpell_physic) do
                    if v == spellID and percentRemaining > 0.3 then
                        return true
                    end
                end

            end

        end

    end
    return false

end

function Hekili:isTargetSpellingMagicTargetMeSpell()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and UnitIsUnit(unit .. "target", "player") and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
                local remainingTime = (endTimeMS / 1000) - GetTime()
                if Hekili.State.health.pct <= 40 and remainingTime <= 0.4 then return true end
                for _, v in ipairs(targetMeSpell_magic) do
                    if v == spellId  then
                        return true
                    end
                end

            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                local now = GetTime() * 1000  
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration
                if Hekili.State.health.pct <= 40 and  percentRemaining > 0.3 then return true end
                for _, v in ipairs(targetMeSpell_magic) do
                    if v == spellID then
                        return true
                    end
                end

            end
        end

    end
    return false

end

function Hekili:isTargetSpellingPhysicTargetMeSpell()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and UnitIsUnit(unit .. "target", "player") and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
          
                for _, v in ipairs(targetMeSpell_physic) do
                    if v == spellId then
                        return true
                    end
                end

            end

            local name, displayName, textureID, startTimeMS, endTimeMS, isTradeskill, notInterruptible, spellID, isEmpowered, numEmpowerStages = UnitChannelInfo(unit)
            if spellID then
                local now = GetTime() * 1000  -- 当前时间，单位：毫秒
                local duration = endTimeMS - startTimeMS
                local elapsed = now - startTimeMS
                local remaining = duration - elapsed
                local percentRemaining = remaining / duration

                for _, v in ipairs(targetMeSpell_physic) do
                    if v == spellID and percentRemaining > 0.3 then
                        return true
                    end
                end

            end
        end

    end
    return false

end


function Hekili:isPlayerHasMagicDot()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for _, v in ipairs(dot_magic) do
        local has, duration_pct = Hekili:isPlayerAuraExist(v)
        if has and (duration_pct <= 0.85 and duration_pct > 0.2 or Hekili.State.health.pct <= 40) then
            return true
        end
    end
    return false

end


function Hekili:isPlayerHasPhysicDot()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence and UnitName("boss1") == "无堕者哈夫" then return false end
    for _, v in ipairs(dot_physic) do
        local has, duration_pct = Hekili:isPlayerAuraExist(v)
        if has and (duration_pct <= 0.85 and duration_pct > 0.25 or Hekili.State.health.pct <= 40)  then
            return true
        end
    end
    return false

end

function Hekili:isTargetSpellingPhysicTargetMeReflectableSpell()
    if not Hekili.DB.profile.toggles.autoDefendence.defendence then return false end
    for unit, guid in pairs(Hekili.npGUIDs) do
        if UnitExists( unit ) and UnitIsUnit(unit .. "target", "player") and not UnitIsDead( unit ) and UnitCanAttack( "player", unit ) and UnitHealth( unit ) > 1 and not UnitIsPlayer( unit ) and UnitAffectingCombat(unit)  then
            local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(unit)
            if spellId then
                local remainingTime = (endTimeMS / 1000) - GetTime()
                if remainingTime <= 0.7 and not notInterruptible then return true end
            end
        end

    end
    return false

end

function Hekili:isMouseOverGroupMember()
    local mouseover = GetMouseFoci()[1]
    if not mouseover then return false end
    if not mouseover.unit then return false end
    if string.find(mouseover.unit, "raid") or string.find(mouseover.unit, "party") or string.find(mouseover.unit, "player") then return true end
    return false
end

function Hekili:isMouseOverMemberDispelable(type)
    local i = 1
    local name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitDebuff( "mouseover" , i )

    while( name ) do
        if debuffType == type and UnitIsFriend("player","mouseover")  then if Hekili:isMouseOverGroupMember() then return true  end end
        i = i + 1
        name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitDebuff( "mouseover" , i )
    end
    return false
end


local function getSpellCooldown(spell)
    local start = C_Spell.GetSpellCooldown(spell)
    if start then
        if start.startTime >= 0 and start.duration < 1.5 then
            return true
        else
            return false
        end
    end
    
end


function Hekili.resurrectionCount(spellId)
    local charges = C_Spell.GetSpellCharges(spellId)
    if not charges then if getSpellCooldown(391054) then return 1 else return 0 end end
    return charges.currentCharges
end

function Hekili:isMouseOverMemberDead()
    if not UnitExists("mouseover") and not UnitIsDead("mouseover") or not Hekili.DB.profile.toggles.autoRevive.value then return false end
    local i = 1
    local s = false
    local name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitDebuff( "mouseover" , i )

    while( name ) do
        if spellId == 160029 and UnitIsFriend("player","mouseover") then s = true  break end
        i = i + 1
        name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitDebuff( "mouseover" , i )
    end

    return not s and Hekili:isMouseOverGroupMember() 
end

function Hekili.isPetSpec()
    local spec = Hekili.State.spec.id
    if spec == 253 or spec == 252 or spec == 266 or spec == 265 or spec == 257 or spec == 64 then
        return true
    end
    return false
end

function Hekili:GetTotalEnemyCombatHealth(num)
    local totalHealth = 0

    for i = 1, num do
        local unit = "nameplate"..i
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitAffectingCombat(unit) then
            totalHealth = totalHealth + (UnitHealth(unit) or 0)
        end
        if UnitName("target") == "训练假人" or UnitName("target") == "普通坦克假人" or UnitName("target") == "顺劈训练假人" or UnitName("target") == "藻拳" then
            totalHealth = totalHealth + 50000000
        end
    end

    return totalHealth
end

do
    local friendGuids ={}
    local friendGuids_dead ={}
    function Hekili:getGroupFriendUnits()
        local self_id = UnitGUID( "player" )
        friendGuids[ "player" ] = self_id
        if GetNumGroupMembers() < 1 then 
            return friendGuids
        end
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local unit = "raid" .. i
                if UnitExists(unit) and UnitIsFriend("player",unit) and UnitInRange(unit) then
                    if not UnitIsDead(unit) then
                        local id = UnitGUID( unit )
                        friendGuids[ unit ] = id
                    else
                        local id = UnitGUID( unit )
                        friendGuids_dead[ unit ] = id
                    end
    
                end

                
            end
        elseif IsInGroup() then

            for i = 1, GetNumGroupMembers() do
                local unit = "party" .. i
                if UnitExists(unit) and  UnitIsFriend( "player", unit ) and UnitInRange(unit)  then
                    if not UnitIsDead(unit) then
                        local id = UnitGUID( unit )
                        friendGuids[ unit ] = id
                    else
                        local id = UnitGUID( unit )
                        friendGuids_dead[ unit ] = id
                    end
                end
            end

        end

        return friendGuids, friendGuids_dead
    end


    
    function Hekili:getHealthPct(unit)
        if Hekili.State.instance_id == 2662 then
            return UnitHealth(unit) / (UnitHealthMax(unit) + UnitGetTotalHealAbsorbs(unit) ) * 100
        end
        return UnitHealth(unit) / UnitHealthMax(unit) * 100
    end

    function Hekili:findLowestHpUnit()
        local group = Hekili:getGroupFriendUnits()
        if not group then return "none" end
    
        local lowestHealthPct = math.huge
        local lowestUnit = nil
        local fullHealthUnits = {}
        local tank_gap = Hekili.DB.profile.toggles.autoHealing.tank_gap
        for unit, guid in pairs(friendGuids) do
            if UnitExists(unit)  then
                local pct = Hekili:getHealthPct(unit)
    
                if pct < 100 then
                    if pct < lowestHealthPct then
                        if UnitGroupRolesAssigned(unit) == "TANK"  then
                            if pct <= tank_gap then
                                lowestHealthPct = pct
                                lowestUnit = unit
                            end
                        else
                            lowestHealthPct = pct
                            lowestUnit = unit
                        end
                    end
                else
                    table.insert(fullHealthUnits, unit)
                end
            end
        end
    
        friendGuids = {}
    
        -- 所有人都是满血，随机返回一个
        if not lowestUnit and #fullHealthUnits > 0 then
            local i = math.random(1, #fullHealthUnits)
            return fullHealthUnits[i]
        end
    
        return lowestUnit or "none"
    end

    function Hekili.findDeaduUnit() 
        local _, dead = Hekili:getGroupFriendUnits()
        local dead_list = {}
        if not dead then return "none" end
        friendGuids = {}
        friendGuids_dead = {}
        local i = 0
        for k, v in pairs(dead) do
            i = i + 1
            dead_list[i] = k
         end
        return dead_list, i
    end

    function Hekili:findInjuredGroupNumber(gap)
        if not Hekili:getGroupFriendUnits() then return 0 end
        local count = 0
        
        for unit, guid in pairs(friendGuids) do
            if not UnitIsDead(unit) and Hekili:getHealthPct(unit) <= gap then
                count = count + 1
            end
        end
        friendGuids ={}

        return count  
    end

    function Hekili:findActiveHotNumber(id)
        if not Hekili:getGroupFriendUnits() then return 0 end
        local count_ = 0
        for unit, guid in pairs(friendGuids) do
            local i = 1
            local name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitBuff( unit , i )

            while( name ) do
                if spellId == id then 
                    count_ = count_ + 1
                    break

                end
                i = i + 1
                name, _, count, debuffType, duration, expirationTime, _, canDispel, _, spellId = UnitBuff( unit , i )
            end
        end
        friendGuids ={}
       
        return count_
    end

    function Hekili:findTankUnit()
        if not Hekili:getGroupFriendUnits() then return 0 end
        for unit, guid in pairs(friendGuids) do
            if UnitGroupRolesAssigned(unit) == "TANK" and UnitInRange(unit) then
                return unit
            end
            
        end
        friendGuids ={}
        return "none"
    end

    function Hekili:isTankInBattle()
        local unit = Hekili:findTankUnit()
        if unit == "none" then
            return false, nil
        else

            if UnitAffectingCombat(unit)    then
                local targetUnit = unit .. "target"
                if UnitExists(targetUnit) and UnitAffectingCombat(targetUnit) then
                    return true, unit
                else
                    return false, nil
                end
                
            end

        end
        return false, nil
    end

end

