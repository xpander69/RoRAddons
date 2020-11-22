TargetInfoRing = {}
TargetInfoRingRing = Frame:Subclass("TargetInfoRingWindow")

-- settigns

local showRingOnSelf = true

local SETTINGS = {
    FriendlyTarget = {
        enabled = true,
        sound = false,
        color = {0, 255, 0},
        scale = 1,
        alpha = 0.5,
        baralpha = 0.8,
        dx = 0,
        dy = -10
    },
    EnemyTarget = {
        enabled = true,
        sound = false,
        color = {255, 0, 0},
        scale = 1,
        alpha = 0.5,
        baralpha = 0.8,
        dx = 0,
        dy = -10
    },
    MTarget = {
        enabled = false,
        sound = false,
        color = {255, 255, 255},
        scale = 0.5,
        alpha = 0.3,
        baralpha = 0.1,
        dx = 0,
        dy = -10
    }
}

TargetInfoRing.CareerColors = {
    [20180] = {r = 175, g = 206, b = 234}, -- | Archmage
    [20181] = {r = 126, g = 57, b = 96}, -- | Blackguard
    [20182] = {r = 51, g = 115, b = 21}, -- | Black Orc
    [20183] = {r = 255, g = 37, b = 10}, -- | Bright Wizard
    [20184] = {r = 147, g = 200, b = 120}, -- | Choppa
    [20185] = {r = 99, g = 109, b = 112}, -- | Chosen
    [20186] = {r = 204, g = 43, b = 211}, -- | Disciple of Khaine
    [20187] = {r = 232, g = 181, b = 128}, -- | Engineer
    [20188] = {r = 179, g = 1, b = 1}, -- | Slayer
    [20189] = {r = 155, g = 82, b = 65}, -- | Ironbreaker
    [20190] = {r = 246, g = 106, b = 19}, -- | Knight of the Blazing Sun
    [20191] = {r = 44, g = 81, b = 136}, -- | Magus
    [20192] = {r = 177, g = 136, b = 134}, -- | Marauder
    [20193] = {r = 246, g = 227, b = 148}, -- | Rune Priest
    [20194] = {r = 144, g = 142, b = 165}, -- | Shadow Warrior
    [20195] = {r = 147, g = 200, b = 120}, -- | Shaman
    [20196] = {r = 92, g = 24, b = 125}, -- | Sorcerer/Sorceress
    [20197] = {r = 60, g = 96, b = 48}, -- | Squig Herder
    [20198] = {r = 52, g = 96, b = 159}, -- | Swordmaster
    [20199] = {r = 237, g = 129, b = 100}, -- | Warrior Priest
    [20200] = {r = 227, g = 240, b = 246}, -- | White Lion
    [20201] = {r = 188, g = 106, b = 204}, -- | Witch Elf
    [20202] = {r = 150, g = 26, b = 18}, -- | Witch Hunter
    [20203] = {r = 144, g = 142, b = 145} -- | Zealot
}

-- locals

local WINDOWS = {
    ["selffriendlytarget"] = {
        infoWindowName = "FriendlyTargetInfo",
        anchorWindowName = "FriendlyTargetRingAnchor",
        id = nil
    },
    ["selfhostiletarget"] = {
        infoWindowName = "EnemyTargetInfo",
        anchorWindowName = "EnemyTargetRingAnchor",
        id = nil
    },
    ["mouseovertarget"] = {
        infoWindowName = "MTargetInfo",
        anchorWindowName = "MTargetRingAnchor",
        id = nil
    }
}

local cur_eid = nil
local cur_fid = nil
local cur_mid = nil
local GUI

local MIN_RANGE = 0
local MAX_RANGE = 65535

local TARGET_HOSTILE = 1
local TARGET_FRIENDLY = 2

function TargetInfoRing.Initialize()
    RegisterEventHandler(SystemData.Events.PLAYER_HOT_BAR_ENABLED_STATE_CHANGED,
                         "TargetInfoRing.UpdateRanges")
    RegisterEventHandler(SystemData.Events.PLAYER_TARGET_UPDATED,
                         "TargetInfoRing.UpdateTargets")
    -- RegisterEventHandler(SystemData.Events.PLAYER_POSITION_UPDATED, "TargetInfoRing.UpdateRange")

    TargetInfoRing.Settings = SETTINGS
    TargetInfoRing.Recreate()
end

function TargetInfoRing.UpdateTargets(targetClassification, targetId, targetType)
    -- if targetClassification ~= "mouseovertarget" then
    TargetInfo:UpdateFromClient()
    TargetInfoRing.UpdateRings(targetClassification) -- update ring visibility and attach them to world objects
    TargetInfoRing.UpdateData(targetClassification)
    -- end
end

-- creating windows
function TargetInfoRing.Recreate()
    for unit, _ in pairs(TargetInfoRing.Settings) do
        if (unit ~= "version") then
            TargetInfoRing.CreateRing(unit)
        end
    end
end

function TargetInfoRing.CreateRing(unit)
    local anchor = unit .. "Ring" .. "Anchor"
    local info = unit .. "Info"
    local ring = info .. "Ring"
    local settings = TargetInfoRing.Settings[unit]

    if (DoesWindowExist(anchor)) then
        DestroyWindow(info)
    else
        -- create anchor window to which info window is attached
        CreateWindowFromTemplate(anchor,
                                 "EA_DynamicImage_DefaultSeparatorRight", "Root")
        WindowSetDimensions(anchor, 1, 1)
    end

    -- create info window that contains ring, status bar and labels
    CreateWindowFromTemplate(info, "TargetInfoRingWindow", anchor)
    WindowClearAnchors(info)
    WindowAddAnchor(info, "top", anchor, "top", settings.dx, settings.dy)

    -- setup ring
    DynamicImageSetTexture(ring, "TargetInfoRing", 0, 0)
    DynamicImageSetTextureDimensions(ring, 256, 256)
    WindowSetDimensions(ring, 100, 100)
    WindowSetScale(ring, settings.scale)
    WindowSetAlpha(ring, settings.alpha)
    WindowSetTintColor(ring, unpack(settings.color))

    -- setup status bar
    StatusBarSetMaximumValue(info .. "StatusBar", 100)
    StatusBarSetForegroundTint(info .. "StatusBar", unpack(settings.color))
    StatusBarSetBackgroundTint(info .. "StatusBar", 0, 0, 0)

    WindowSetShowing(anchor, false)
end

-- rings

function TargetInfoRing.UpdateRing(anchor_wname, cur_id, id, enabled)
    if (cur_id) then
        DetachWindowFromWorldObject(anchor_wname, cur_id)
    end
    WindowSetShowing(anchor_wname, false)
    if (id > 0 and (id ~= GameData.Player.worldObjNum or showRingOnSelf)) then
        MoveWindowToWorldObject(anchor_wname, id, 1)
        AttachWindowToWorldObject(anchor_wname, id)
        if (enabled) then
            WindowSetShowing(anchor_wname, true)
        else
            WindowSetShowing(anchor_wname, false)
        end
    end
end

function TargetInfoRing.UpdateRings(targetClassification)
    local id = TargetInfo:UnitEntityId(targetClassification)
    local w = WINDOWS[targetClassification].anchorWindowName
    if targetClassification == "selffriendlytarget" then
        if (id ~= cur_fid) then
            TargetInfoRing.UpdateRing(w, cur_fid, id, TargetInfoRing.Settings
                                          .FriendlyTarget.enabled)
            cur_fid = id
        end
    elseif targetClassification == "selfhostiletarget" then
        if (id ~= cur_eid) then
            TargetInfoRing.UpdateRing(w, cur_eid, id, TargetInfoRing.Settings
                                          .EnemyTarget.enabled)
            cur_eid = id
        end
    elseif targetClassification == "mouseovertarget" and
        TargetInfoRing.Settings.MTarget.enabled then
        if (id ~= cur_mid) then
            if (id > 0 and (id ~= GameData.Player.worldObjNum)) then
                DetachWindowFromWorldObject(w, cur_mid)
                AttachWindowToWorldObject(w, id)
                -- TargetInfoRing.UpdateRing(w, cur_mid, id,
                --   TargetInfoRing.Settings.MTarget.enabled)
                cur_mid = id
            end
        end
    end
end

-- names

function TargetInfoRing.UpdateData(targetClassification)
    TargetInfoRing.UpdateRange(targetClassification)
    -- TargetInfoRing.UpdateHP(targetClassification)

    local t = TargetInfo.m_Units[targetClassification]
    local w = WINDOWS[targetClassification].infoWindowName
    if targetClassification == "mouseovertarget" then
        if t and t.entityid > 0 and t.entityid ~= GameData.Player.worldObjNum then
            TargetInfoRing.SetHP(w, t)
            TargetInfoRing.SetName(w, t)
            WindowSetAlpha(w .. "Status", 0.5)
        end
        return
    end
    if t then
        TargetInfoRing.SetName(w, t)
        TargetInfoRing.SetHP(w, t)
    end
end

function TargetInfoRing.SetName(windowname, target)
    local careerline = tostring(target.level)
    local nameline = target.name
    local careercolor = {r = 255, g = 255, b = 255}

    if target.battleLevel ~= target.level then
        careerline = careerline .. "(" .. tostring(target.battleLevel) .. ")"
    end
    careerline = towstring(careerline)
    local tiername
    if target.tier == 3 then
        tiername = L"Lord"
    elseif target.tier == 2 then
        tiername = L"Hero"
    elseif target.tier == 1 then
        tiername = L"Champion"
    end

    if target.tier > 0 then
        careerline = tiername .. L" " .. careerline
    end

    if target.career > 0 then
        local careerIcon = Icons.GetCareerIconIDFromCareerLine(target.career)
        nameline = nameline .. L" <icon" .. towstring(careerIcon) .. L">"
        careerline = target.careerName .. L" " .. careerline
        local ccolor = TargetInfoRing.CareerColors[careerIcon]
        careercolor = ccolor
    else
        careerline = towstring(target.npcTitle) .. L" " .. careerline
    end

    LabelSetText(windowname .. "Name", nameline)
    LabelSetTextColor(windowname .. "Name", target.relationshipColor.r,
                      target.relationshipColor.g, target.relationshipColor.b)

    LabelSetText(windowname .. "CareerTitle", careerline)
    LabelSetTextColor(windowname .. "CareerTitle", careercolor.r, careercolor.g,
                      careercolor.b)
end

function TargetInfoRing.SetHP(windowname, target)
    local healthPercent = target.healthPercent

    if healthPercent >= 50 then
        LabelSetTextColor(windowname .. "HP", 255, 255, 255)
    elseif healthPercent >= 20 then
        LabelSetTextColor(windowname .. "HP", 255, 120, 120)
    else
        LabelSetTextColor(windowname .. "HP", 255, 0, 0)
    end
    LabelSetText(windowname .. "HP", towstring(healthPercent) .. L"%")
    StatusBarSetCurrentValue(windowname .. "StatusBar", healthPercent)
end

-- range
function TargetInfoRing.UpdateRanges()
    local lmin_r_f, lmax_r_f, lmin_r_h, lmax_r_h = TargetInfoRing.GetRanges()
    rangeText, color = TargetInfoRing.GetRangeTextColor(lmin_r_f, lmax_r_f)
    local w = WINDOWS.selffriendlytarget.infoWindowName
    TargetInfoRing.SetRange(w, rangeText, color)
    TargetInfoRing.SetRingScaleFromRange(w, lmin_r_f, lmax_r_f)
    w = WINDOWS.selfhostiletarget.infoWindowName
    rangeText, color = TargetInfoRing.GetRangeTextColor(lmin_r_h, lmax_r_h)
    TargetInfoRing.SetRange(w, rangeText, color)
    TargetInfoRing.SetRingScaleFromRange(w, lmin_r_h, lmax_r_h)
end

function TargetInfoRing.UpdateRange(targetClassification)
    local rangeText, color
    local w = WINDOWS[targetClassification].infoWindowName
    if targetClassification == "selffriendlytarget" then
        local lmin_r, lmax_r = TargetInfoRing.GetRange(TARGET_FRIENDLY)
        rangeText, color = TargetInfoRing.GetRangeTextColor(lmin_r, lmax_r)
        TargetInfoRing.SetRange(w, rangeText, color)
        TargetInfoRing.SetRingScaleFromRange(w, lmin_r, lmax_r)
    elseif targetClassification == "selfhostiletarget" then
        local lmin_r, lmax_r = TargetInfoRing.GetRange(TARGET_HOSTILE)
        rangeText, color = TargetInfoRing.GetRangeTextColor(lmin_r, lmax_r)
        TargetInfoRing.SetRange(w, rangeText, color)
        TargetInfoRing.SetRingScaleFromRange(w, lmin_r, lmax_r)
    end
end

function TargetInfoRing.SetRange(window, rangetext, color)
    LabelSetText(window .. "Range", towstring(rangetext))
    LabelSetTextColor(window .. "Range", unpack(color))
end

function TargetInfoRing.SetRingScaleFromRange(window, minrange, maxrange)
    local scale = 1
    if maxrange > 500 then
        scale = 1
    elseif maxrange > 100 then
        scale = 1.1
    elseif maxrange > 90 then
        scale = 1.2
    elseif maxrange > 82 then
        scale = 1.3
    elseif maxrange > 60 then
        scale = 1.4
    else
        scale = 1.5
    end
    WindowSetScale(window .. "Ring", scale)
end

function TargetInfoRing.GetRangeTextColor(lmin_r, lmax_r)
    local RangeText
    local color = {255, 255, 255}
    if lmax_r > 500 then
        RangeText = L"N/A"
        color = {255, 0, 0}
    else
        RangeText = towstring(lmin_r) .. L"-" .. towstring(lmax_r) .. L"ft"
    end
    return RangeText, color
end

function TargetInfoRing.GetRanges()
    -- First step: get current abilities
    -- TODO: (MrAngel) have to link some morales too
    local CurrentAbilities = GetAbilityTable(GameData.AbilityType.STANDARD)
    local Result_min_f = MIN_RANGE
    local Result_min_h = MIN_RANGE
    local Result_max_f = MAX_RANGE
    local Result_max_h = MAX_RANGE

    for abilityId, abilityData in pairs(CurrentAbilities) do
        if abilityData.targetType == TARGET_FRIENDLY then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            -- if isValid and maxRange~=0 then
            if maxRange ~= 0 then
                if isValid then
                    Result_max_f = math.min(Result_max_f, maxRange)
                    Result_min_f = math.max(Result_min_f, minRange)
                else
                    -- Result_max = math.min(Result_max, maxRange)
                    Result_min_f = math.max(Result_min_f, maxRange)
                end
            end
        elseif abilityData.targetType == TARGET_HOSTILE then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            -- if isValid and maxRange~=0 then
            if maxRange ~= 0 then
                if isValid then
                    Result_max_h = math.min(Result_max_h, maxRange)
                    Result_min_h = math.max(Result_min_h, minRange)
                else
                    -- Result_max = math.min(Result_max, maxRange)
                    Result_min_h = math.max(Result_min_h, maxRange)
                end
            end
        end
    end

    for abilityId, abilityData in pairs(GetAbilityTable(
                                            GameData.AbilityType.GRANTED)) do
        if abilityData.targetType == TARGET_FRIENDLY then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_f = math.min(Result_max_f, maxRange)
                Result_min_f = math.max(Result_min_f, minRange)
            end
        elseif abilityData.targetType == TARGET_HOSTILE then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_h = math.min(Result_max_h, maxRange)
                Result_min_h = math.max(Result_min_h, minRange)
            end
        end
    end

    for abilityId, abilityData in pairs(GetAbilityTable(
                                            GameData.AbilityType.MORALE)) do
        if abilityData.targetType == TARGET_FRIENDLY then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_f = math.min(Result_max_f, maxRange)
                Result_min_f = math.max(Result_min_f, minRange)
            end
        elseif abilityData.targetType == TARGET_HOSTILE then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_h = math.min(Result_max_h, maxRange)
                Result_min_h = math.max(Result_min_h, minRange)
            end
        end
    end

    -- Final step: return result
    return Result_min_f, Result_max_f, Result_min_h, Result_max_h
end

function TargetInfoRing.GetRange(targetType)
    -- First step: get current abilities
    -- TODO: (MrAngel) have to link some morales too
    local CurrentAbilities = GetAbilityTable(GameData.AbilityType.STANDARD)
    local Result_min_f = MIN_RANGE
    local Result_max_f = MAX_RANGE

    for abilityId, abilityData in pairs(CurrentAbilities) do
        if abilityData.targetType == targetType then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            -- if isValid and maxRange~=0 then
            if maxRange ~= 0 then
                if isValid then
                    Result_max_f = math.min(Result_max_f, maxRange)
                    Result_min_f = math.max(Result_min_f, minRange)
                else
                    -- Result_max = math.min(Result_max, maxRange)
                    Result_min_f = math.max(Result_min_f, maxRange)
                end
            end
        end
    end

    for abilityId, abilityData in pairs(GetAbilityTable(
                                            GameData.AbilityType.GRANTED)) do
        if abilityData.targetType == targetType then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_f = math.min(Result_max_f, maxRange)
                Result_min_f = math.max(Result_min_f, minRange)
            end
        end
    end

    for abilityId, abilityData in pairs(GetAbilityTable(
                                            GameData.AbilityType.MORALE)) do
        if abilityData.targetType == targetType then
            local isValid, hasTarget = IsTargetValid(abilityId)
            local minRange, maxRange = GetAbilityRanges(abilityId)
            if isValid and maxRange ~= 0 then
                Result_max_f = math.min(Result_max_f, maxRange)
                Result_min_f = math.max(Result_min_f, minRange)
            end
        end
    end

    -- Final step: return result
    return Result_min_f, Result_max_f, Result_min_h, Result_max_h
end
