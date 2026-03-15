local _, ADW = ...

-- Expose to global for SavedVariables and debugging
AutoDungeonWaypoint = ADW

-- ============================================================================
-- State
-- ============================================================================
local activeRoute = nil
local activeRouteKey = nil
local currentStepIndex = 0
local totalSteps = 0
local checkTicker = nil
local debugMode = false

-- ============================================================================
-- Defaults for SavedVariables
-- ============================================================================
local DEFAULTS = {
    AutoRouteEnabled = true,
    ShowStatusFrame = true,
    Log = {},       -- Persistent event log
    LogMaxLines = 200,
    StatusFramePos = nil,
    ToggleButtonPos = nil,
}

-- ============================================================================
-- Utility: Print
-- ============================================================================
local ADDON_COLOR = "|cFF00BFFF"  -- Bright sky blue to match the "waypoint" theme
local WHITE       = "|cFFFFFFFF"
local GREEN       = "|cFF00FF00"
local RED         = "|cFFFF4444"
local YELLOW      = "|cFFFFCC00"
local GRAY        = "|cFF888888"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_COLOR .. "[Auto Dungeon Waypoint]|r " .. msg)
end

-- ============================================================================
-- Logging (persisted to SavedVariables, importable for investigation)
-- ============================================================================
local function Log(level, msg)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.Log then return end
    local db = AutoDungeonWaypointDB
    local entry = string.format("[%s][%s] %s", date("%Y-%m-%d %H:%M:%S"), level, msg)
    table.insert(db.Log, entry)
    -- Trim log to max size
    while #db.Log > (db.LogMaxLines or 200) do
        table.remove(db.Log, 1)
    end
end

local function LogInfo(msg)  Log("INFO",  msg) end
local function LogWarn(msg)  Log("WARN",  msg) end
local function LogError(msg) Log("ERROR", msg) end

-- ============================================================================
-- Status Frame (HUD widget showing current step)
-- ============================================================================
local statusFrame = CreateFrame("Frame", "ADWStatusFrame", UIParent, "BackdropTemplate")
statusFrame:SetSize(280, 60)
statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
statusFrame:SetMovable(true)
statusFrame:EnableMouse(true)
statusFrame:RegisterForDrag("LeftButton")
statusFrame:SetScript("OnDragStart", statusFrame.StartMoving)
statusFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then
        AutoDungeonWaypointDB.StatusFramePos = { point, relPoint, x, y }
    end
end)
statusFrame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
statusFrame:SetBackdropColor(0.02, 0.08, 0.15, 0.88)
statusFrame:SetBackdropBorderColor(0.0, 0.75, 1.0, 0.8) -- Blue border

-- Title line
local titleText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", statusFrame, "TOP", 0, -8)
titleText:SetTextColor(0.0, 0.75, 1.0)
titleText:SetText("Auto Dungeon Waypoint")

-- Step description line
local stepText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
stepText:SetPoint("TOP", titleText, "BOTTOM", 0, -4)
stepText:SetWidth(260)
stepText:SetWordWrap(true)
stepText:SetText("")

statusFrame:Hide()

local function UpdateStatusFrame(dungeonName, stepDesc, stepNum, stepTotal)
    if dungeonName then
        titleText:SetText(ADDON_COLOR .. dungeonName .. "|r " .. GRAY .. "(Step " .. stepNum .. "/" .. stepTotal .. ")|r")
    end
    if stepDesc then
        stepText:SetText(stepDesc)
    end
    local textHeight = stepText:GetStringHeight() or 16
    statusFrame:SetHeight(36 + textHeight)
    statusFrame:Show()
end

local function HideStatusFrame()
    statusFrame:Hide()
end

-- ============================================================================
-- Waypoint Engine
-- ============================================================================
local function ClearRoute()
    C_Map.ClearUserWaypoint()
    if checkTicker then
        checkTicker:Cancel()
        checkTicker = nil
    end
    activeRoute = nil
    activeRouteKey = nil
    currentStepIndex = 0
    totalSteps = 0
    HideStatusFrame()
end

local function SetWaypointStep(index)
    if not activeRoute or not activeRoute[index] then
        Print(GREEN .. "You have arrived! Route complete.|r")
        LogInfo("Route complete: " .. tostring(activeRouteKey))
        PlaySound(SOUNDKIT.READY_CHECK)
        ClearRoute()
        return
    end

    local step = activeRoute[index]
    local point = UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    local dungeonName = ADW.RouteNames[activeRouteKey] or activeRouteKey
    Print(YELLOW .. "Step " .. index .. "/" .. totalSteps .. ":|r " .. WHITE .. step.desc .. "|r")
    LogInfo(string.format("Step %d/%d for %s: %s (mapID=%d, x=%.4f, y=%.4f)", index, totalSteps, dungeonName, step.desc, step.mapID, step.x, step.y))
    UpdateStatusFrame(dungeonName, step.desc, index, totalSteps)

    if index > 1 then
        PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN)
    end
end

local function CheckDistance()
    if not activeRoute then return end

    local step = activeRoute[currentStepIndex]
    if not step then return end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then return end

    if currentMapID == step.mapID then
        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        if pos then
            local dx = pos.x - step.x
            local dy = pos.y - step.y
            if (dx * dx + dy * dy) < 0.0004 then
                currentStepIndex = currentStepIndex + 1
                SetWaypointStep(currentStepIndex)
            end
        end
    else
        local nextStep = activeRoute[currentStepIndex + 1]
        if nextStep and currentMapID == nextStep.mapID then
            currentStepIndex = currentStepIndex + 1
            SetWaypointStep(currentStepIndex)
        end
    end
end

local function StartRoute(routeKey)
    local route = ADW.Routes[routeKey]
    if not route then
        Print(RED .. "No route found for:|r " .. tostring(routeKey) .. ". Type " .. YELLOW .. "/adw list|r to see all routes.")
        LogWarn("StartRoute failed: unknown key '" .. tostring(routeKey) .. "'")
        return
    end

    ClearRoute()
    activeRoute = route
    activeRouteKey = routeKey
    totalSteps = #route

    -- Smart Routing: Detect if we are already in one of the route zones
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local bestStep = 1
    if currentMapID then
        for i = 1, totalSteps do
            if activeRoute[i].mapID == currentMapID then
                bestStep = i
            end
        end
    end
    currentStepIndex = bestStep

    local dungeonName = ADW.RouteNames[routeKey] or routeKey
    local msg = GREEN .. "Starting route to " .. dungeonName .. " (" .. totalSteps .. " steps)|r"
    if currentStepIndex > 1 then
        msg = msg .. GRAY .. " — resuming from step " .. currentStepIndex .. "|r"
    end
    Print(msg)
    
    LogInfo("Route started: " .. dungeonName .. " (Entry Step: " .. currentStepIndex .. "/" .. totalSteps .. ")")
    SetWaypointStep(currentStepIndex)
    checkTicker = C_Timer.NewTicker(1, CheckDistance)
end

-- ============================================================================
-- Toggle Button
-- ============================================================================
local toggleBtn = CreateFrame("Button", "ADWToggleButton", UIParent, "UIPanelButtonTemplate")
toggleBtn:SetSize(160, 26)
toggleBtn:SetPoint("TOP", UIParent, "TOP", 0, -20)
toggleBtn:SetMovable(true)
toggleBtn:EnableMouse(true)
toggleBtn:RegisterForDrag("LeftButton")
toggleBtn:SetScript("OnDragStart", toggleBtn.StartMoving)
toggleBtn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then
        AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y }
    end
end)
toggleBtn:SetNormalFontObject("GameFontNormalSmall")
toggleBtn:SetHighlightFontObject("GameFontHighlightSmall")

local function UpdateToggleButton()
    if not AutoDungeonWaypointDB then return end
    if AutoDungeonWaypointDB.AutoRouteEnabled then
        toggleBtn:SetText("|cFF00FF00[ON]|r ADW: Auto")
    else
        toggleBtn:SetText("|cFFFF4444[OFF]|r ADW: Auto")
    end
end

function ADW.ToggleAutoRoute(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then
        db.AutoRouteEnabled = not db.AutoRouteEnabled
    else
        db.AutoRouteEnabled = enabled
    end
    
    UpdateToggleButton()
    
    if db.AutoRouteEnabled then
        Print("Auto-Routing " .. GREEN .. "enabled|r.")
    else
        Print("Auto-Routing " .. RED .. "disabled|r. Use " .. YELLOW .. "/adw route <id>|r to route manually.")
        ClearRoute()
    end
end

-- ============================================================================
-- Manual Route Dropdown
-- ============================================================================
local adwMenuFrame = CreateFrame("Frame", "ADWMenuFrame", UIParent, "UIDropDownMenuTemplate")

local function ADWMenu_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF00BFFFSelect Dungeon (Manual)|r"
    info.isTitle = true
    info.notCheckable = true
    UIDropDownMenu_AddButton(info)

    -- Alphabetical sort of route names
    local keys = {}
    for k in pairs(ADW.RouteNames) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return ADW.RouteNames[a] < ADW.RouteNames[b] end)

    for _, key in ipairs(keys) do
        info = UIDropDownMenu_CreateInfo()
        info.text = ADW.RouteNames[key]
        info.func = function() StartRoute(key) end
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)
    end
end

toggleBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
toggleBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        ADW.ToggleAutoRoute()
    else
        UIDropDownMenu_Initialize(adwMenuFrame, ADWMenu_Initialize, "MENU")
        ToggleDropDownMenu(1, nil, adwMenuFrame, self, 0, 0)
    end
end)

toggleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Auto Dungeon Waypoint", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Left-Click: Toggle auto-routing.", 1, 1, 1, true)
    GameTooltip:AddLine("Right-Click: Select dungeon manually.", 0, 1, 0, true)
    GameTooltip:AddLine("Drag: Reposition button.", 0.5, 0.5, 0.5, true)
    GameTooltip:Show()
end)
toggleBtn:SetScript("OnLeave", GameTooltip_Hide)

-- ============================================================================
-- Slash Commands
-- ============================================================================
SLASH_AUTODUNGEONWAYPOINT1 = "/adw"
SLASH_AUTODUNGEONWAYPOINT2 = "/autodungeonwaypoint"
SlashCmdList["AUTODUNGEONWAYPOINT"] = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)

    if cmd == "route" and arg then
        LogInfo("Manual route command: " .. arg)
        StartRoute(arg)

    elseif cmd == "stop" then
        LogInfo("Route manually cancelled.")
        ClearRoute()
        Print("Route cancelled.")

    elseif cmd == "toggle" then
        ADW.ToggleAutoRoute()

    elseif cmd == "list" then
        Print("Available routes:")
        for key, name in pairs(ADW.RouteNames) do
            local steps = ADW.Routes[key] and #ADW.Routes[key] or 0
            Print("  " .. YELLOW .. key .. "|r — " .. WHITE .. name .. "|r " .. GRAY .. "(" .. steps .. " steps)|r")
        end

    elseif cmd == "log" then
        local db = AutoDungeonWaypointDB
        if arg == "clear" then
            db.Log = {}
            Print("Log cleared.")
        else
            local log = db and db.Log or {}
            local count = #log
            if count == 0 then
                Print("Log is empty.")
            else
                local start = math.max(1, count - 19) -- show last 20 entries
                Print(GRAY .. "--- Log " .. start .. "-" .. count .. " of " .. count .. " entries ---  (" .. YELLOW .. "/adw log clear|r to wipe)")
                for i = start, count do
                    DEFAULT_CHAT_FRAME:AddMessage(GRAY .. log[i] .. "|r")
                end
            end
        end

    elseif cmd == "debug" then
        debugMode = not debugMode
        LogInfo("Debug mode toggled: " .. (debugMode and "ON" or "OFF"))
        Print("Debug mode: " .. (debugMode and (GREEN .. "ON|r") or (RED .. "OFF|r")))

    elseif cmd == "hide" then
        toggleBtn:Hide()
        Print("Toggle button hidden. Use " .. YELLOW .. "/adw show|r to restore.")

    elseif cmd == "show" then
        toggleBtn:Show()

    else
        Print("Commands:")
        Print("  " .. YELLOW .. "/adw route <id>|r — Start a route (see " .. YELLOW .. "/adw list|r)")
        Print("  " .. YELLOW .. "/adw list|r — Show all available dungeon routes")
        Print("  " .. YELLOW .. "/adw stop|r — Cancel the current route")
        Print("  " .. YELLOW .. "/adw toggle|r — Toggle auto-routing on/off")
        Print("  " .. YELLOW .. "/adw log|r — Show recent log entries")
        Print("  " .. YELLOW .. "/adw log clear|r — Clear the log")
        Print("  " .. YELLOW .. "/adw hide|r / " .. YELLOW .. "/adw show|r — Hide/show toggle button")
    end
end

-- ============================================================================
-- LFG Activity Processor
-- ============================================================================
function ADW.ProcessActivityID(activityID, isSilent)
    if not activityID then return end
    
    local routeKey = ADW.LFGToRoute[activityID]
    if routeKey then
        -- Avoid restarting the same route if it's already active
        if activeRouteKey == routeKey then return end

        local name = ADW.RouteNames[routeKey] or routeKey
        if not isSilent then
            Print(GREEN .. "Dungeon detected:|r " .. WHITE .. name .. "|r — auto-starting route!")
        end
        LogInfo("Auto-route triggered for: " .. name .. (isSilent and " (Silent/Startup)" or ""))
        StartRoute(routeKey)
    else
        if not isSilent then
            LogWarn("No route for ActivityID=" .. tostring(activityID))
            if debugMode then
                Print(GRAY .. "[Debug] Unmapped Activity ID: " .. tostring(activityID) .. "|r")
            end
        end
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

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == "AutoDungeonWaypoint" then
        if not AutoDungeonWaypointDB then
            AutoDungeonWaypointDB = {}
        end
        for k, v in pairs(DEFAULTS) do
            if AutoDungeonWaypointDB[k] == nil then
                AutoDungeonWaypointDB[k] = v
            end
        end
        
        -- Restore positions
        if AutoDungeonWaypointDB.StatusFramePos then
            local p = AutoDungeonWaypointDB.StatusFramePos
            statusFrame:ClearAllPoints()
            statusFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end
        if AutoDungeonWaypointDB.ToggleButtonPos then
            local p = AutoDungeonWaypointDB.ToggleButtonPos
            toggleBtn:ClearAllPoints()
            toggleBtn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end

        UpdateToggleButton()
        LogInfo("Addon loaded. Version " .. (GetAddOnMetadata("AutoDungeonWaypoint", "Version") or "1.0.5") .. ". AutoRoute=" .. tostring(AutoDungeonWaypointDB.AutoRouteEnabled))
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        Print("Loaded — Type " .. YELLOW .. "/adw|r for help or " .. YELLOW .. "/adw list|r to see routes.")
        
        -- Check if already listed (e.g. after a reload)
        if AutoDungeonWaypointDB.AutoRouteEnabled then
            local activeEntry = C_LFGList.GetActiveEntryInfo()
            if activeEntry and activeEntry.activityID then
                ADW.ProcessActivityID(activeEntry.activityID, true)
            end
        end

        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        return
    end

    if event == "LFG_LIST_JOINED_GROUP" then
        if not AutoDungeonWaypointDB.AutoRouteEnabled then return end

        local searchResultID = ...
        if not searchResultID then return end

        local info = C_LFGList.GetSearchResultInfo(searchResultID)
        if info and info.activityID then
            LogInfo("LFG joined (SearchResultID=" .. tostring(searchResultID) .. ")")
            ADW.ProcessActivityID(info.activityID)
        end
        return
    end

    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        if not AutoDungeonWaypointDB.AutoRouteEnabled then return end

        local activeEntry = C_LFGList.GetActiveEntryInfo()
        if activeEntry and activeEntry.activityID then
            LogInfo("LFG active entry update (Creator context)")
            ADW.ProcessActivityID(activeEntry.activityID)
        end
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        if not activeRoute then return end

        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then return end

        -- Scan forward for the furthest reached step in this map
        local furthestIndex = currentStepIndex
        for i = currentStepIndex + 1, totalSteps do
            if activeRoute[i].mapID == currentMapID then
                furthestIndex = i
            end
        end

        if furthestIndex > currentStepIndex then
            LogInfo(string.format("Zone change detected. Skipping from step %d to %d (MapID %d)", currentStepIndex, furthestIndex, currentMapID))
            currentStepIndex = furthestIndex
            SetWaypointStep(currentStepIndex)
        end
        return
    end
end)
