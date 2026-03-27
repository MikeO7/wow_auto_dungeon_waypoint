local _, ADW = ...
local ADW_NAME = "AutoDungeonWaypoint"

-- Expose to global for SavedVariables, debugging, and Bindings.xml
AutoDungeonWaypoint = ADW

-- Global binding localization strings (single source of truth)
BINDING_HEADER_ADW = "Auto Dungeon Waypoint"
BINDING_NAME_ADW_TOGGLEHUD = "Toggle Navigation HUD"
BINDING_NAME_ADW_STOP = "Cancel Route"

-- ============================================================================
-- State
-- ============================================================================
local activeRoute = nil
local activeRouteKey = nil
local currentStepIndex = 0
local totalSteps = 0
local checkTicker = nil
local debugMode = false
local tomtomUID = nil
local lastStepAdvance = 0
local lastMapChangeTime = 0
local lastMapID = nil

-- ============================================================================
-- Defaults for SavedVariables
-- ============================================================================
local DB_VERSION = 1  -- Increment when schema changes; migration code below

local DEFAULTS = {
    _dbVersion = DB_VERSION,
    AutoRouteEnabled = true,
    ShowStatusFrame = true,
    ShowControlBar = true,
    ShowChatText = true,
    CompactMode = false,
    Log = {},
    LogMaxLines = 200,
    StatusFramePos = nil,
    ToggleButtonPos = nil,
    MinimapIcon = { hide = false, minimapPos = 220 },
}

--- Run any needed migrations when DB version is behind.
local function MigrateDB(db)
    local ver = db._dbVersion or 0
    -- Example: if ver < 2 then ... db.NewField = defaultValue ... end
    db._dbVersion = DB_VERSION
end

-- ============================================================================
-- Utility: Print
-- ============================================================================
local ADDON_COLOR = "|cFF00BFFF"
local WHITE       = "|cFFFFFFFF"
local GREEN       = "|cFF00FF00"
local RED         = "|cFFFF4444"
local YELLOW      = "|cFFFFCC00"
local GRAY        = "|cFF888888"

function ADW.ForcePrint(msg)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_COLOR .. "[Auto Dungeon Waypoint]|r " .. msg)
end

function ADW.Print(msg)
    local db = AutoDungeonWaypointDB
    if db and db.ShowChatText == false then return end
    ADW.ForcePrint(msg)
end

local Print = ADW.Print
local ForcePrint = ADW.ForcePrint

-- ============================================================================
-- Logging
-- ============================================================================
local function Log(level, msg)
    local db = AutoDungeonWaypointDB
    if not db or not db.Log then return end
    local entry = string.format("[%s][%s] %s", date("%Y-%m-%d %H:%M:%S"), level, msg)
    table.insert(db.Log, entry)
    while #db.Log > (db.LogMaxLines or 200) do
        table.remove(db.Log, 1)
    end
end

local function LogInfo(msg)  Log("INFO",  msg) end
local function LogError(msg) Log("ERROR", msg) end

-- ============================================================================
-- State Accessors (used by UI.lua, Menus.lua)
-- ============================================================================
--- Returns true if a navigation route is currently active.
---@return boolean
function ADW.HasActiveRoute()
    return activeRoute ~= nil
end

--- Returns the route key of the currently active route, or nil.
---@return string|nil routeKey  e.g. "windrunner", "magisters"
function ADW.GetActiveRouteKey()
    return activeRouteKey
end

--- Returns route key, current step index, and total steps for the active route.
---@return string|nil routeKey
---@return number currentStep  (0 if no route)
---@return number totalSteps   (0 if no route)
function ADW.GetActiveRouteInfo()
    if activeRoute then
        return activeRouteKey, currentStepIndex, totalSteps
    end
    return nil, 0, 0
end

--- Returns the description text of the current navigation step, or nil.
---@return string|nil
function ADW.GetCurrentStepDesc()
    if activeRoute and activeRoute[currentStepIndex] then
        return activeRoute[currentStepIndex].desc
    end
    return nil
end

-- ============================================================================
-- SmartSync Engine
-- ============================================================================
ADW.ContinentCache = {}
function ADW.GetMapContinent(mapID)
    if not mapID then return nil end
    if ADW.ContinentCache[mapID] ~= nil then return ADW.ContinentCache[mapID] end
    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.mapType ~= 2 do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    local contID = mapInfo and mapInfo.mapID or false
    ADW.ContinentCache[mapID] = contID
    return contID
end

ADW.MapParentCache = {}
local function IsMapOrChild(currentID, targetID)
    if currentID == targetID then return true end
    if not ADW.MapParentCache[currentID] then
        ADW.MapParentCache[currentID] = {}
    end
    if ADW.MapParentCache[currentID][targetID] ~= nil then
        return ADW.MapParentCache[currentID][targetID]
    end
    local info = C_Map.GetMapInfo(currentID)
    local safety = 0
    local isChild = false
    while info and info.parentMapID and safety < 10 do
        if info.parentMapID == targetID then isChild = true break end
        info = C_Map.GetMapInfo(info.parentMapID)
        safety = safety + 1
    end
    ADW.MapParentCache[currentID][targetID] = isChild
    return isChild
end

function ADW.GetBestStepIndex(route, currentMapID, pos)
    if not route then return 1 end

    if not currentMapID then
        currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then return 1 end
    end

    if not pos and pos ~= false then
        pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
    end

    local currentCont = ADW.GetMapContinent(currentMapID)

    local bestIdx = currentStepIndex
    if bestIdx == 0 then bestIdx = 1 end
    local bestScore = -1
    local minDistSq = math.huge

    for i, step in ipairs(route) do
        local score = 0
        if step.mapID == currentMapID then
            score = 100
        elseif IsMapOrChild(currentMapID, step.mapID) then
            score = 75
        elseif ADW.GetMapContinent(step.mapID) == currentCont then
            score = 50
        end

        if score > 0 then
            if score > bestScore then
                bestScore = score
                bestIdx = i
                minDistSq = math.huge
                if pos and step.mapID == currentMapID then
                    local dx = (pos.x - step.x) * 1000
                    local dy = (pos.y - step.y) * 1000
                    minDistSq = dx*dx + dy*dy
                end
            elseif score == bestScore then
                if pos and step.mapID == currentMapID then
                    local dx = (pos.x - step.x) * 1000
                    local dy = (pos.y - step.y) * 1000
                    local d2 = dx*dx + dy*dy
                    if d2 < minDistSq then
                        minDistSq = d2
                        bestIdx = i
                    end
                end
            end
        end
    end

    return bestIdx
end

-- ============================================================================
-- Navigation Engine
-- ============================================================================
local function ClearRoute()
    C_Map.ClearUserWaypoint()
    if checkTicker then checkTicker:Cancel() checkTicker = nil end
    if tomtomUID and TomTom and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(tomtomUID)
    end
    tomtomUID = nil
    activeRoute = nil
    activeRouteKey = nil
    currentStepIndex = 0
    totalSteps = 0
    ADW.HidePortalMap()
    ADW.HideStatusFrame()
    ADW.UpdateToggleButton()
end

local function SetWaypointStep(index)
    if not activeRoute or not activeRoute[index] then
        Print(GREEN .. "You have arrived! Route complete.|r")
        LogInfo("Route complete: " .. tostring(activeRouteKey))
        PlaySound(8659)
        ClearRoute()
        return
    end

    local step = activeRoute[index]
    step.uiMapPoint = step.uiMapPoint or UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
    C_Map.SetUserWaypoint(step.uiMapPoint)

    if C_Map.HasUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        if debugMode then Print("DEBUG: SetUserWaypoint map=" .. step.mapID .. " [SUCCESS]") end
    else
        LogError("Failed to set Blizzard waypoint for map " .. tostring(step.mapID))
    end

    if TomTom and TomTom.AddWaypoint then
        if tomtomUID then TomTom:RemoveWaypoint(tomtomUID) end
        tomtomUID = TomTom:AddWaypoint(step.mapID, step.x, step.y, {
            title = step.desc, source = "ADW", persistent = false
        })
    end

    local dungeonName = ADW.RouteNames[activeRouteKey] or activeRouteKey
    local desc = step.desc
    local nextStep = activeRoute[index + 1]
    if nextStep and nextStep.mapID ~= step.mapID then
        desc = "|cFF00FFFF[PORTAL]|r " .. desc
    end

    Print(YELLOW .. "Step " .. index .. "/" .. totalSteps .. ":|r " .. WHITE .. desc .. "|r")
    LogInfo("ADVANCE: Step " .. index .. "/" .. totalSteps .. " (" .. desc .. ")")
    ADW.UpdateStatusFrame(dungeonName, desc, index, totalSteps)
    if index > 1 then PlaySound(850) end

    -- Show/hide Timeways portal map
    if step.mapID == ADW.TIMEWAYS_MAP_ID and activeRouteKey then
        ADW.ShowPortalMap(activeRouteKey)
    else
        ADW.HidePortalMap()
    end
end

local function SyncRouteProgress()
    if not activeRoute then return end
    local best = ADW.GetBestStepIndex(activeRoute)
    if best ~= currentStepIndex then
        if best > currentStepIndex and GetTime() - lastStepAdvance < 8 then
            if debugMode then Print("DEBUG: SyncRouteProgress forward-skip blocked by immunity.") end
            SetWaypointStep(currentStepIndex)
            return
        end
        currentStepIndex = best
        SetWaypointStep(currentStepIndex)
    end
end

local function ReApplyWaypointIfMissing()
    if not activeRoute or not activeRoute[currentStepIndex] then return end
    local step = activeRoute[currentStepIndex]

    local hasWaypoint = C_Map.HasUserWaypoint()
    if not hasWaypoint then
        step.uiMapPoint = step.uiMapPoint or UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
        C_Map.SetUserWaypoint(step.uiMapPoint)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        hasWaypoint = true
        LogInfo("Waypoint enforced automatically")
    end

    if hasWaypoint and not C_SuperTrack.IsSuperTrackingUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
end

local function CheckDistance()
    if not activeRoute then return end
    ReApplyWaypointIfMissing()
    local step = activeRoute[currentStepIndex]
    if not step then return end

    local now = GetTime()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then return end

    if currentMapID ~= lastMapID then
        lastMapID = currentMapID
        lastMapChangeTime = now
        if debugMode then Print("DEBUG: Map change detected. Buffer active.") end
    end

    local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
    if debugMode then
        Print(string.format("DEBUG: Map: %d | Step: %d", currentMapID, currentStepIndex))
    end

    local bestIdx = ADW.GetBestStepIndex(activeRoute, currentMapID, pos)
    if bestIdx > currentStepIndex then
        if now - lastStepAdvance < 8 then
            if debugMode then Print("DEBUG: Forward-skip immunity active (" .. bestIdx .. " blocked).") end
        else
            LogInfo(string.format("SmartSync: SKIP FORWARD from %d to %d (Map: %d)", currentStepIndex, bestIdx, currentMapID))
            currentStepIndex = bestIdx
            SetWaypointStep(currentStepIndex)
        end
        return
    elseif bestIdx < currentStepIndex then
        if currentMapID ~= step.mapID then
            if now - lastStepAdvance < 5 then
                if debugMode then Print("DEBUG: Snap-back immunity active.") end
                return
            end

            local isPriorMap = false
            for i = 1, currentStepIndex - 1 do
                if activeRoute[i].mapID == currentMapID then isPriorMap = true break end
            end
            if isPriorMap then
                local priorStep = activeRoute[currentStepIndex - 1]
                if pos and priorStep and priorStep.mapID == currentMapID then
                    local ddx = (pos.x - priorStep.x) * 1000
                    local ddy = (pos.y - priorStep.y) * 1000
                    local dSq = ddx*ddx + ddy*ddy
                    if dSq < 400.0 then
                        if debugMode then Print(string.format("DEBUG: Near Step %d (DistSq: %.2f) - ignoring snap-back.", currentStepIndex-1, dSq)) end
                        return
                    end
                end

                LogInfo(string.format("SmartSync: SNAP BACK from %d to %d (Map: %d)", currentStepIndex, bestIdx, currentMapID))
                currentStepIndex = bestIdx
                SetWaypointStep(currentStepIndex)
                return
            end
        end
    end

    if currentMapID == step.mapID then
        if pos then
            local dx = (pos.x - step.x) * 1000
            local dy = (pos.y - step.y) * 1000
            local distSq = dx * dx + dy * dy
            if debugMode then Print(string.format("DEBUG: Step %d DistSq: %.2f (Target: < 10.0) Map: %d", currentStepIndex, distSq, currentMapID)) end
            if distSq < 10.0 then
                if now - lastMapChangeTime < 3 then
                    if debugMode then Print("DEBUG: Arrival ignored (Map change buffer active)") end
                    return
                end

                LogInfo(string.format("ARRIVAL: Step %d reached (DistSq: %.2f)", currentStepIndex, distSq))
                if currentStepIndex < totalSteps then
                    currentStepIndex = currentStepIndex + 1
                    lastStepAdvance = now
                    SetWaypointStep(currentStepIndex)
                    ADW.UpdateToggleButton()
                    ADW.PulseGlow()
                else
                    Print(GREEN .. "You have arrived! Route complete.|r")
                    LogInfo("Route complete: " .. tostring(activeRouteKey))
                    PlaySound(8659)
                    ClearRoute()
                end
            end
        end
    end
end

-- ============================================================================
-- Public Route API
-- ============================================================================
--- Start navigating to a dungeon.
--- Clears any existing route, sets waypoints, starts the distance-check ticker.
---@param routeKey string  Key from ADW.Routes (e.g. "windrunner")
function ADW.StartRoute(routeKey)
    local route = ADW.Routes[routeKey]
    if not route then
        Print(RED .. "No route found for:|r " .. tostring(routeKey))
        return
    end
    ClearRoute()
    activeRoute = route
    activeRouteKey = routeKey
    totalSteps = #route
    currentStepIndex = ADW.GetBestStepIndex(route)

    local dungeonName = ADW.RouteNames[routeKey] or routeKey
    local msg = GREEN .. "Starting route to " .. dungeonName .. " (" .. totalSteps .. " steps)|r"
    if currentStepIndex > 1 then
        msg = msg .. GRAY .. " — sync'd to step " .. currentStepIndex .. "|r"
    end
    Print(msg)
    LogInfo("Route started: " .. dungeonName .. " (Step: " .. currentStepIndex .. "/" .. totalSteps .. ")")
    PlaySound(846)
    SetWaypointStep(currentStepIndex)
    ADW.UpdateToggleButton()

    checkTicker = C_Timer.NewTicker(0.25, CheckDistance)
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage("ADW", "ROUTE:" .. routeKey, "PARTY")
    end
end

--- Stop the current route and clear all waypoints.
function ADW.StopRoute()
    ClearRoute()
    ForcePrint("Route cancelled.")
end

--- Toggle or set the auto-routing feature.
---@param enabled boolean|nil  true/false to set, nil to toggle
function ADW.ToggleAutoRoute(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then
        db.AutoRouteEnabled = not db.AutoRouteEnabled
    else
        db.AutoRouteEnabled = enabled
    end
    ADW.UpdateToggleButton()
    if db.AutoRouteEnabled then
        Print("Auto-Routing " .. GREEN .. "enabled|r.")
    else
        Print("Auto-Routing " .. RED .. "disabled|r.")
        ClearRoute()
    end
end

-- Global helpers for Bindings.xml
function ADW_ToggleHUD_Binding()
    ADW.ToggleHUD()
end

function ADW_Stop_Binding()
    ADW.StopRoute()
end

-- ============================================================================
-- LFG Processor
-- ============================================================================
--- Process an LFG Activity ID and start a route if one matches.
--- Called automatically on group join/create events.
---@param activityID number  WoW LFG Activity ID
---@param isSilent boolean|nil  If true, suppress "Dungeon detected" chat message
function ADW.ProcessActivityID(activityID, isSilent)
    if not activityID then return end

    local routeKey = ADW.LFGToRoute[activityID]

    if routeKey == false then return end

    if routeKey == nil then
        local info = C_LFGList.GetActivityInfoTable(activityID)
        if info and info.fullName then
            if debugMode then LogInfo("ProcessActivityID: Name=" .. info.fullName) end
            local lowerName = info.fullName:lower():gsub("[%p%s]", "")

            ADW.RouteNamesClean = ADW.RouteNamesClean or {}

            for key, name in pairs(ADW.RouteNames) do
                local cleanTarget = ADW.RouteNamesClean[key]
                if not cleanTarget then
                    cleanTarget = name:lower():gsub("[%p%s]", "")
                    ADW.RouteNamesClean[key] = cleanTarget
                end

                if lowerName:find(cleanTarget, 1, true) then
                    routeKey = key
                    break
                end
            end
        end
        ADW.LFGToRoute[activityID] = routeKey or false
    end

    if not routeKey or activeRouteKey == routeKey then return end

    local _, instanceType = IsInInstance()
    if instanceType == "party" or instanceType == "raid" then
        if debugMode then LogInfo("ProcessActivityID: Already in instance (" .. instanceType .. "), skipping.") end
        return
    end

    if debugMode then LogInfo("ProcessActivityID: ID=" .. tostring(activityID) .. " Key=" .. tostring(routeKey)) end

    local name = ADW.RouteNames[routeKey] or routeKey
    if not isSilent then
        Print(GREEN .. "Dungeon detected:|r " .. WHITE .. name .. "|r — auto-starting!")
    end
    ADW.StartRoute(routeKey)
end

-- ============================================================================
-- Slash Commands
-- ============================================================================
SLASH_AUTODUNGEONWAYPOINT1 = "/adw"
SLASH_AUTODUNGEONWAYPOINT2 = "/autodungeonwaypoint"
SlashCmdList["AUTODUNGEONWAYPOINT"] = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)

    if cmd == "route" and arg then
        ADW.StartRoute(arg)

    elseif cmd == "stop" then
        ADW.StopRoute()

    elseif cmd == "toggle" then
        ADW.ToggleAutoRoute()

    elseif cmd == "hide" then
        local db = AutoDungeonWaypointDB
        if db then
            db.ShowStatusFrame = false
            db.ShowControlBar = false
            db.ShowChatText = false
            ADW.HideStatusFrame()
            ADW.SetControlBarVisible(false)
            ForcePrint("HUD, Control Bar, and Chat Text hidden. Use /adw show to restore.")
        end

    elseif cmd == "show" then
        local db = AutoDungeonWaypointDB
        if db then
            db.ShowStatusFrame = true
            db.ShowControlBar = true
            db.ShowChatText = true
            ADW.SetControlBarVisible(true)
            if ADW.HasActiveRoute() then
                local routeKey, stepIdx, steps = ADW.GetActiveRouteInfo()
                local desc = ADW.GetCurrentStepDesc()
                ADW.UpdateStatusFrame(ADW.RouteNames[routeKey] or routeKey, desc, stepIdx, steps)
            end
            ForcePrint("HUD, Control Bar, and Chat Text restored.")
        end

    elseif cmd == "list" then
        ForcePrint("Available routes:")
        for _, key in ipairs(ADW.SortedRouteKeys) do
            local name = ADW.RouteNames[key]
            local steps = ADW.Routes[key] and #ADW.Routes[key] or 0
            ForcePrint("  " .. YELLOW .. key .. "|r — " .. WHITE .. name .. "|r " .. GRAY .. "(" .. steps .. " steps)|r")
        end

    elseif cmd == "nearest" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then return end
        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        local bestKey, bestDist = nil, math.huge
        for key, route in pairs(ADW.Routes) do
            local step1 = route[1]
            if step1 and step1.mapID == currentMapID and pos then
                local ddx = (pos.x - step1.x) * 1000
                local ddy = (pos.y - step1.y) * 1000
                local d = ddx*ddx + ddy*ddy
                if d < bestDist then bestDist = d bestKey = key end
            end
        end
        if bestKey then
            ADW.StartRoute(bestKey)
        else
            ForcePrint(RED .. "No nearby dungeon routes found.|r")
        end

    elseif cmd == "move" then
        if ADW.IsStatusFrameShown() then
            ADW.HideStatusFrame()
            ForcePrint("HUD hidden.")
        else
            ADW.ShowStatusFrameForPositioning()
            ForcePrint("HUD shown for positioning.")
        end

    elseif cmd == "debug" then
        debugMode = not debugMode
        ForcePrint("Debug mode " .. (debugMode and GREEN .. "enabled|r" or RED .. "disabled|r"))

    elseif cmd == "mapid" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then
            ForcePrint(RED .. "No map detected.|r")
            return
        end
        local info = C_Map.GetMapInfo(currentMapID)
        ForcePrint("Current Map ID: " .. currentMapID .. " (" .. (info and info.name or "Unknown") .. ")")
        if info and info.parentMapID then
            local pInfo = C_Map.GetMapInfo(info.parentMapID)
            ForcePrint("Parent Map ID: " .. info.parentMapID .. " (" .. (pInfo and pInfo.name or "Unknown") .. ")")
        end

    elseif cmd == "pos" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if currentMapID then
            local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
            if pos then
                ForcePrint(string.format("Position: mapID=%d  x=%.4f  y=%.4f", currentMapID, pos.x, pos.y))
            else
                ForcePrint(RED .. "Cannot get position on this map.|r")
            end
        else
            ForcePrint(RED .. "No map detected.|r")
        end

    elseif cmd == "version" then
        local version = C_AddOns and C_AddOns.GetAddOnMetadata(ADW_NAME, "Version") or "unknown"
        ForcePrint("Version: " .. WHITE .. version .. "|r")

    elseif cmd == "log" then
        local db = AutoDungeonWaypointDB
        if not db or not db.Log or #db.Log == 0 then
            ForcePrint("Log is empty.")
        else
            ForcePrint("Recent log entries (last 10):")
            local start = math.max(1, #db.Log - 9)
            for i = start, #db.Log do
                ForcePrint("  " .. GRAY .. db.Log[i] .. "|r")
            end
        end

    elseif cmd == "reset" then
        AutoDungeonWaypointDB = nil
        ClearRoute()
        ForcePrint("All settings have been reset. Type /reload to apply.")

    else
        ForcePrint("Commands:")
        ForcePrint("  " .. YELLOW .. "/adw route <id>|r — Start a specific route")
        ForcePrint("  " .. YELLOW .. "/adw list|r — List available dungeons")
        ForcePrint("  " .. YELLOW .. "/adw nearest|r — Start the closest route")
        ForcePrint("  " .. YELLOW .. "/adw stop|r — Cancel current route")
        ForcePrint("  " .. YELLOW .. "/adw toggle|r — Toggle auto-routing")
        ForcePrint("  " .. YELLOW .. "/adw hide|r — Hide all UI elements")
        ForcePrint("  " .. YELLOW .. "/adw show|r — Restore all UI elements")
        ForcePrint("  " .. YELLOW .. "/adw move|r — Toggle HUD for positioning")
        ForcePrint("  " .. YELLOW .. "/adw version|r — Show addon version")
        ForcePrint("  " .. YELLOW .. "/adw log|r — Show recent log entries")
        ForcePrint("  " .. YELLOW .. "/adw reset|r — Reset all settings")
        ForcePrint("  " .. YELLOW .. "/adw debug|r — Toggle debug mode")
        ForcePrint("  " .. YELLOW .. "/adw mapid|r — Show current map ID")
        ForcePrint("  " .. YELLOW .. "/adw pos|r — Show current position")
    end
end

-- ============================================================================
-- Event Handling
-- ============================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("LFG_LIST_JOINED_GROUP")
eventFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix("ADW")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...

    -- ========================================================================
    -- ADDON_LOADED: Initialize SavedVariables, restore UI, register LDB
    -- ========================================================================
    if event == "ADDON_LOADED" and arg1 == ADW_NAME then
        if not AutoDungeonWaypointDB then AutoDungeonWaypointDB = {} end
        local db = AutoDungeonWaypointDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        MigrateDB(db)

        -- Restore saved positions
        ADW.RestoreStatusFramePos()
        ADW.RestoreControlBarPos()

        -- Control bar visibility
        if db.ShowControlBar == false then
            ADW.SetControlBarVisible(false)
        else
            ADW.SetControlBarVisible(true)
        end

        ADW.UpdateToggleButton()
        ADW.CreateOptionsPanel()
        ADW.CreateLDBObject()

        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    -- ========================================================================
    -- PLAYER_ENTERING_WORLD: Login/reload detection, instance clearing
    -- ========================================================================
    if event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if isLogin or isReload then
            Print("Loaded — Type /adw list to see routes.")
            if AutoDungeonWaypointDB.AutoRouteEnabled then
                local activeEntry = C_LFGList.GetActiveEntryInfo()
                if activeEntry and activeEntry.activityIDs then
                    for _, id in ipairs(activeEntry.activityIDs) do
                        ADW.ProcessActivityID(id, true)
                    end
                end
            end
        else
            local _, instanceType = IsInInstance()
            if (instanceType == "party" or instanceType == "raid") and activeRoute then
                Print(GREEN .. "Entered dungeon! Route cleared.|r")
                ClearRoute()
            elseif activeRoute then
                SyncRouteProgress()
            end
        end
        return
    end

    -- ========================================================================
    -- LFG Events: Auto-detect dungeon on group join
    -- ========================================================================
    if event == "LFG_LIST_JOINED_GROUP" then
        local searchResultID = ...
        if searchResultID and AutoDungeonWaypointDB.AutoRouteEnabled then
            local info = C_LFGList.GetSearchResultInfo(searchResultID)
            if info and info.activityID then
                ADW.ProcessActivityID(info.activityID)
            end
        end
        return
    end

    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        if AutoDungeonWaypointDB.AutoRouteEnabled then
            local activeEntry = C_LFGList.GetActiveEntryInfo()
            if activeEntry and activeEntry.activityIDs then
                for _, id in ipairs(activeEntry.activityIDs) do
                    ADW.ProcessActivityID(id)
                end
            end
        end
        return
    end

    -- ========================================================================
    -- Zone Change: Re-sync route progress
    -- ========================================================================
    if event == "ZONE_CHANGED_NEW_AREA" then
        if activeRoute then SyncRouteProgress() end
        return
    end

    -- ========================================================================
    -- Party Sync: Route sharing between addon users
    -- ========================================================================
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == "ADW" and sender ~= UnitName("player") and AutoDungeonWaypointDB.AutoRouteEnabled then
            local cmd, routeKey = strsplit(":", message, 2)
            if cmd == "ROUTE" and routeKey and ADW.Routes[routeKey] and activeRouteKey ~= routeKey then
                Print(sender .. " shared a route to " .. (ADW.RouteNames[routeKey] or routeKey))
                ADW.StartRoute(routeKey)
            end
        end
    end
end)
