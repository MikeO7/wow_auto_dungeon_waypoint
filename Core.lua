local _, ADW = ...
local ADW_NAME = "AutoDungeonWaypoint"

-- API Compatibility for WoW 12.0.1+ (Midnight)
local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata) or function() return nil end

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
local tomtomUID = nil  -- Optional TomTom waypoint UID

-- Forward declarations (functions defined later but called earlier)
local UpdateToggleButton

-- ============================================================================
-- Defaults for SavedVariables
-- ============================================================================
local DEFAULTS = {
    AutoRouteEnabled = true,
    ShowStatusFrame = true,
    CompactMode = false,
    Log = {},       -- Persistent event log
    LogMaxLines = 200,
    StatusFramePos = nil,
    ToggleButtonPos = nil,
    MinimapIcon = { hide = false, minimapPos = 220 },
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
statusFrame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end)
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
    tileSize = 12,
    edgeSize = 12, -- Thinner border
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
})
statusFrame:SetBackdropColor(0, 0, 0, 0.75) -- Darker, cleaner glass look
statusFrame:SetBackdropBorderColor(0, 0.75, 1, 0.5) -- Softer blue border

-- Title line
local titleText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", statusFrame, "TOP", 0, -8)
titleText:SetTextColor(0.0, 0.75, 1.0)
titleText:SetText("Auto Dungeon Waypoint")

-- Step description line
local stepText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
stepText:SetPoint("TOP", titleText, "BOTTOM", 0, -4)
stepText:SetWidth(230)
stepText:SetWordWrap(true)
stepText:SetText("")

-- Distance line (left-aligned, where arrow used to be)
local distanceText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
distanceText:SetPoint("BOTTOMLEFT", statusFrame, "BOTTOMLEFT", 10, 8)
distanceText:SetTextColor(0.8, 0.8, 0.8)
distanceText:SetText("")

statusFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Navigation HUD", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
statusFrame:SetScript("OnLeave", GameTooltip_Hide)

-- Progress Bar
local progressBar = CreateFrame("StatusBar", nil, statusFrame)
progressBar:SetSize(260, 6)
progressBar:SetPoint("BOTTOM", statusFrame, "BOTTOM", 0, 4)
progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
progressBar:SetStatusBarColor(0, 0.75, 1, 0.9)
progressBar:SetMinMaxValues(0, 1)
progressBar:SetValue(0)
local progressBG = progressBar:CreateTexture(nil, "BACKGROUND")
progressBG:SetAllPoints()
progressBG:SetColorTexture(0, 0, 0, 0.4)

statusFrame:Hide()

local function UpdateStatusFrame(dungeonName, stepDesc, stepNum, stepTotal)
    if not AutoDungeonWaypointDB.ShowStatusFrame then return end
    
    local isCompact = AutoDungeonWaypointDB.CompactMode
    
    if dungeonName then
        titleText:SetText(ADDON_COLOR .. dungeonName .. "|r " .. GRAY .. "(Step " .. stepNum .. "/" .. stepTotal .. ")|r")
    end
    if stepDesc then
        stepText:SetText(stepDesc)
    end
    
    -- Update progress bar
    progressBar:SetMinMaxValues(0, stepTotal)
    progressBar:SetValue(stepNum)
    
    -- Compact mode: hide text, shrink frame
    if isCompact then
        titleText:Hide()
        stepText:Hide()
        statusFrame:SetHeight(44)
    else
        titleText:Show()
        stepText:Show()
        local textHeight = stepText:GetStringHeight() or 16
        statusFrame:SetHeight(math.max(70, 44 + textHeight))
    end
    
    -- Smooth fade in
    if not statusFrame:IsShown() then
        statusFrame:SetAlpha(0)
        statusFrame:Show()
        UIFrameFadeIn(statusFrame, 0.2, 0, 1)
    end
end

local function HideStatusFrame()
    if statusFrame:IsShown() then
        UIFrameFadeOut(statusFrame, 0.2, statusFrame:GetAlpha(), 0)
        C_Timer.After(0.2, function() statusFrame:Hide() end)
    end
end

-- ============================================================================
-- Map Utilities
-- ============================================================================
function ADW.GetMapContinent(mapID)
    if not mapID then return nil end
    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.mapType ~= 2 do -- MapType 2 is Continent
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    return mapInfo and mapInfo.mapID or nil
end

local function ClearRoute()
    C_Map.ClearUserWaypoint()
    if checkTicker then
        checkTicker:Cancel()
        checkTicker = nil
    end
    -- Remove TomTom waypoint if it exists
    if tomtomUID and TomTom and TomTom.RemoveWaypoint then
        TomTom:RemoveWaypoint(tomtomUID)
    end
    tomtomUID = nil
    activeRoute = nil
    activeRouteKey = nil
    currentStepIndex = 0
    totalSteps = 0
    distanceText:SetText("")
    HideStatusFrame()
    UpdateToggleButton() -- Refresh button label
end

local function SetWaypointStep(index)
    if not activeRoute or not activeRoute[index] then
        Print(GREEN .. "You have arrived! Route complete.|r")
        LogInfo("Route complete: " .. tostring(activeRouteKey))
        PlaySound(SOUNDKIT.UI_RAID_BOSS_DEFEATED_LG) -- Satisfying completion sound
        ClearRoute()
        return
    end

    local step = activeRoute[index]
    local point = UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    
    -- Optional TomTom integration (soft dependency)
    if TomTom and TomTom.AddWaypoint then
        -- Clear previous TomTom waypoint
        if tomtomUID and TomTom.RemoveWaypoint then
            TomTom:RemoveWaypoint(tomtomUID)
        end
        tomtomUID = TomTom:AddWaypoint(step.mapID, step.x, step.y, {
            title = step.desc,
            source = "ADW",
            persistent = false,
        })
    end

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
            -- 1. Calculate Distance
            local dx = (pos.x - step.x) * 1000 -- Approximate scaling for yards
            local dy = (pos.y - step.y) * 1000
            local distSq = dx * dx + dy * dy
            local yards = math.floor(math.sqrt(distSq) * 7.5) -- Multiplier for yards-conversion
            
            -- Color-coded distance + ETA for better feedback
            local speed = GetUnitSpeed("player") or 0
            local etaStr
            if speed > 0.5 then
                local eta = math.ceil(yards / speed)
                if eta > 60 then
                    etaStr = string.format("%dm%ds", math.floor(eta/60), eta%60)
                else
                    etaStr = eta .. "s"
                end
            else
                etaStr = "stopped"
            end
            
            if yards < 40 then
                distanceText:SetTextColor(0, 1, 0) -- Green
            elseif yards < 100 then
                distanceText:SetTextColor(1, 0.8, 0) -- Yellow
            else
                distanceText:SetTextColor(0.8, 0.8, 0.8) -- Gray/White
            end
            
            distanceText:SetText(tostring(yards) .. "yd (" .. etaStr .. ")")

            -- 2. Check for Arrival
            if distSq < 0.04 then -- Trigger distance
                currentStepIndex = currentStepIndex + 1
                SetWaypointStep(currentStepIndex)
                UpdateToggleButton() -- Refresh step progress
            end
        end
    else
        distanceText:SetText("")
        
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

    local currentMapID = C_Map.GetBestMapForUnit("player")
    local currentContinentID = ADW.GetMapContinent(currentMapID)
    local bestStep = 1
    
    if currentMapID then
        -- 1. Try to find an exact map match (highest accuracy)
        local exactMatch = nil
        for i = 1, totalSteps do
            if activeRoute[i].mapID == currentMapID then
                exactMatch = i
            end
        end
        
        if exactMatch then
            bestStep = exactMatch
        elseif currentContinentID then
            -- 2. Fall back to the first step on this continent
            for i = 1, totalSteps do
                if ADW.GetMapContinent(activeRoute[i].mapID) == currentContinentID then
                    bestStep = i
                    break
                end
            end
        end
    end
    
    currentStepIndex = bestStep

    local dungeonName = ADW.RouteNames[routeKey] or routeKey
    local msg = GREEN .. "Starting route to " .. dungeonName .. " (" .. totalSteps .. " steps)|r"
    if currentStepIndex > 1 then
        msg = msg .. GRAY .. " — sync'd to step " .. currentStepIndex .. "|r"
    end
    Print(msg)
    
    LogInfo("Route started: " .. dungeonName .. " (Entry Step: " .. currentStepIndex .. "/" .. totalSteps .. ")")
    PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN) -- Distinct "route starting" sound
    SetWaypointStep(currentStepIndex)
    UpdateToggleButton() -- Show step progress on button
    checkTicker = C_Timer.NewTicker(0.2, CheckDistance) -- 5x/sec for smooth tracking

    
    -- Broadcast to party
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage("ADW", "ROUTE:" .. routeKey, "PARTY")
    end
end

-- ============================================================================
-- Toggle UI (Dual-Button Control Bar)
-- ============================================================================
local controlBar = CreateFrame("Frame", "ADWControlBar", UIParent)
controlBar:SetSize(210, 26) -- Widened for better label fit
controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
controlBar:SetMovable(true)
controlBar:EnableMouse(true)
controlBar:RegisterForDrag("LeftButton")
controlBar:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then
        self:StartMoving()
    end
end)
controlBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then
        AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y }
    end
end)

-- 1. Auto-Route Toggle Button
local autoBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
autoBtn:SetSize(150, 26)
autoBtn:SetPoint("LEFT", controlBar, "LEFT", 0, 0)
autoBtn:SetNormalFontObject("GameFontNormalSmall")
autoBtn:SetHighlightFontObject("GameFontHighlightSmall")

-- 2. Menu Button (Select Dungeon)
local menuBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
menuBtn:SetSize(46, 26) -- Slightly wider for "List" text
menuBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
menuBtn:SetText("List")

UpdateToggleButton = function()
    if not AutoDungeonWaypointDB then return end
    if AutoDungeonWaypointDB.AutoRouteEnabled then
        if activeRoute and activeRouteKey then
            local name = ADW.RouteNames[activeRouteKey] or activeRouteKey
            local short = string.sub(name, 1, 14)
            autoBtn:SetText("|cFF55FF55" .. currentStepIndex .. "/" .. totalSteps .. "|r " .. short)
        else
            autoBtn:SetText("|cFF55FF55[ON]|r Auto-Routing")
        end
    else
        autoBtn:SetText("|cFFFF5555[OFF]|r Auto-Routing")
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
-- Options Panel
-- ============================================================================
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "ADWOptionsPanel", UIParent)
    panel.name = "Auto Dungeon Waypoint"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Auto Dungeon Waypoint Settings")

    -- Auto-Routing Toggle
    local autoCheck = CreateFrame("CheckButton", "ADWAutoRoutingCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    autoCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    _G[autoCheck:GetName() .. "Text"]:SetText("Enable Auto-Routing")
    autoCheck:SetScript("OnClick", function(self)
        ADW.ToggleAutoRoute(self:GetChecked())
    end)
    autoCheck:SetScript("OnShow", function(self)
        self:SetChecked(AutoDungeonWaypointDB.AutoRouteEnabled)
    end)

    -- Show HUD Toggle
    local hudCheck = CreateFrame("CheckButton", "ADWShowHUDCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    hudCheck:SetPoint("TOPLEFT", autoCheck, "BOTTOMLEFT", 0, -8)
    _G[hudCheck:GetName() .. "Text"]:SetText("Show Navigation HUD")
    hudCheck:SetScript("OnClick", function(self)
        AutoDungeonWaypointDB.ShowStatusFrame = self:GetChecked()
        if activeRoute and AutoDungeonWaypointDB.ShowStatusFrame then statusFrame:Show() else statusFrame:Hide() end
    end)
    hudCheck:SetScript("OnShow", function(self)
        self:SetChecked(AutoDungeonWaypointDB.ShowStatusFrame)
    end)

    -- Compact Mode Toggle
    local compactCheck = CreateFrame("CheckButton", "ADWCompactModeCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    compactCheck:SetPoint("TOPLEFT", hudCheck, "BOTTOMLEFT", 0, -8)
    _G[compactCheck:GetName() .. "Text"]:SetText("Compact HUD (arrow + distance only)")
    compactCheck:SetScript("OnClick", function(self)
        AutoDungeonWaypointDB.CompactMode = self:GetChecked()
        if activeRoute then
            UpdateStatusFrame(ADW.RouteNames[activeRouteKey] or activeRouteKey, nil, currentStepIndex, totalSteps)
        end
    end)
    compactCheck:SetScript("OnShow", function(self)
        self:SetChecked(AutoDungeonWaypointDB.CompactMode)
    end)

    -- Reset Positions Button
    local resetBtn = CreateFrame("Button", "ADWResetBtn", panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 26)
    resetBtn:SetPoint("TOPLEFT", compactCheck, "BOTTOMLEFT", 0, -20)
    resetBtn:SetText("Reset Positions")
    resetBtn:SetScript("OnClick", function()
        AutoDungeonWaypointDB.StatusFramePos = nil
        AutoDungeonWaypointDB.ToggleButtonPos = nil
        statusFrame:ClearAllPoints()
        statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
        controlBar:ClearAllPoints()
        controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
        Print("Positions reset to default.")
    end)

    -- Register with WoW
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end

-- ============================================================================
-- Manual Route Dropdown
-- ============================================================================
local adwMenuFrame = CreateFrame("Frame", "ADWMenuFrame", UIParent, "UIDropDownMenuTemplate")

local function ADWMenu_Initialize(self, level)
    -- All Routes
    local info = UIDropDownMenu_CreateInfo()
    info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF00BFFFAll Dungeons|r"
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

autoBtn:RegisterForDrag("LeftButton")
autoBtn:SetScript("OnDragStart", function() if IsShiftKeyDown() then controlBar:StartMoving() end end)
autoBtn:SetScript("OnDragStop", function() controlBar:StopMovingOrSizing() end)
autoBtn:SetScript("OnClick", function() ADW.ToggleAutoRoute() end)
autoBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Auto-Route Toggle", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Click to enable/disable automatic|ndungeon waypoint detection.", 1, 1, 1, true)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
autoBtn:SetScript("OnLeave", GameTooltip_Hide)

menuBtn:RegisterForDrag("LeftButton")
menuBtn:SetScript("OnDragStart", function() if IsShiftKeyDown() then controlBar:StartMoving() end end)
menuBtn:SetScript("OnDragStop", function() controlBar:StopMovingOrSizing() end)
menuBtn:SetScript("OnClick", function(self)
    UIDropDownMenu_Initialize(adwMenuFrame, ADWMenu_Initialize, "MENU")
    ToggleDropDownMenu(1, nil, adwMenuFrame, self, 0, 0)
end)
menuBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Manual Selection", 0, 0.75, 1)
    GameTooltip:AddLine("Browse and start a route|nto any dungeon manually.", 1, 1, 1, true)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
menuBtn:SetScript("OnLeave", GameTooltip_Hide)

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
        controlBar:Hide()
        Print("Control bar hidden. Use " .. YELLOW .. "/adw show|r to restore.")

    elseif cmd == "show" then
        controlBar:Show()

    elseif cmd == "compact" then
        AutoDungeonWaypointDB.CompactMode = not AutoDungeonWaypointDB.CompactMode
        Print("Compact HUD: " .. (AutoDungeonWaypointDB.CompactMode and (GREEN .. "ON|r") or (RED .. "OFF|r")))
        if activeRoute then
            UpdateStatusFrame(ADW.RouteNames[activeRouteKey] or activeRouteKey, nil, currentStepIndex, totalSteps)
        end

    elseif cmd == "nearest" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then
            Print(RED .. "Cannot determine your location.|r")
            return
        end
        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        local bestKey, bestDist = nil, math.huge
        for key, route in pairs(ADW.Routes) do
            local step1 = route[1]
            if step1 and step1.mapID == currentMapID and pos then
                local ddx = (pos.x - step1.x) * 1000
                local ddy = (pos.y - step1.y) * 1000
                local d = ddx*ddx + ddy*ddy
                if d < bestDist then
                    bestDist = d
                    bestKey = key
                end
            end
        end
        -- Fallback: try continent matching
        if not bestKey then
            local currentContinent = ADW.GetMapContinent(currentMapID)
            for key, route in pairs(ADW.Routes) do
                local step1 = route[1]
                if step1 and ADW.GetMapContinent(step1.mapID) == currentContinent then
                    bestKey = key
                    break
                end
            end
        end
        if bestKey then
            Print("Nearest dungeon: " .. WHITE .. (ADW.RouteNames[bestKey] or bestKey) .. "|r")
            StartRoute(bestKey)
        else
            Print(RED .. "No nearby dungeon routes found.|r")
        end

    else
        Print("Commands:")
        Print("  " .. YELLOW .. "/adw route <id>|r — Start a route (see " .. YELLOW .. "/adw list|r)")
        Print("  " .. YELLOW .. "/adw list|r — Show all available dungeon routes")
        Print("  " .. YELLOW .. "/adw nearest|r — Start the closest dungeon route")
        Print("  " .. YELLOW .. "/adw stop|r — Cancel the current route")
        Print("  " .. YELLOW .. "/adw toggle|r — Toggle auto-routing on/off")
        Print("  " .. YELLOW .. "/adw compact|r — Toggle compact HUD mode")
        Print("  " .. YELLOW .. "/adw log|r — Show recent log entries")
        Print("  " .. YELLOW .. "/adw log clear|r — Clear the log")
        Print("  " .. YELLOW .. "/adw hide|r / " .. YELLOW .. "/adw show|r — Hide/show control bar")
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
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

-- Register addon message prefix for party sharing
C_ChatInfo.RegisterAddonMessagePrefix("ADW")

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
            controlBar:ClearAllPoints()
            controlBar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end

        UpdateToggleButton()
        CreateOptionsPanel()
        
        -- Minimap button via LibDBIcon
        local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
        local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LDB and LDBIcon then
            local adwBroker = LDB:NewDataObject("AutoDungeonWaypoint", {
                type = "launcher",
                text = "Auto Dungeon Waypoint",
                icon = "Interface\\Icons\\INV_Misc_Map_01",
                OnClick = function(_, button)
                    if button == "LeftButton" then
                        -- Open dungeon selector menu
                        UIDropDownMenu_Initialize(adwMenuFrame, ADWMenu_Initialize, "MENU")
                        ToggleDropDownMenu(1, nil, adwMenuFrame, "cursor", 0, 0)
                    elseif button == "RightButton" then
                        -- Toggle auto-routing
                        ADW.ToggleAutoRoute()
                    end
                end,
                OnTooltipShow = function(tooltip)
                    tooltip:SetText("Auto Dungeon Waypoint", 0.0, 0.75, 1.0)
                    if activeRoute and activeRouteKey then
                        local name = ADW.RouteNames[activeRouteKey] or activeRouteKey
                        tooltip:AddLine("|cFF55FF55Active:|r " .. name .. " (" .. currentStepIndex .. "/" .. totalSteps .. ")", 1, 1, 1)
                    else
                        tooltip:AddLine("No active route", 0.5, 0.5, 0.5)
                    end
                    tooltip:AddLine(" ")
                    tooltip:AddLine("|cFFFFD100Left-Click:|r Select a dungeon", 0.8, 0.8, 0.8)
                    tooltip:AddLine("|cFFFFD100Right-Click:|r Toggle auto-routing", 0.8, 0.8, 0.8)
                end,
            })
            LDBIcon:Register("AutoDungeonWaypoint", adwBroker, AutoDungeonWaypointDB.MinimapIcon)
            LogInfo("Minimap button registered via LibDBIcon.")
        end
        
        LogInfo("Addon loaded. Version " .. (GetAddOnMetadata(ADW_NAME, "Version") or "4.2.0") .. ". AutoRoute=" .. tostring(AutoDungeonWaypointDB.AutoRouteEnabled))
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        
        -- First load: show welcome message and check for existing LFG listing
        if isLogin or isReload then
            Print("Loaded — Type " .. YELLOW .. "/adw|r for help or " .. YELLOW .. "/adw list|r to see routes.")
            if AutoDungeonWaypointDB.AutoRouteEnabled then
                local activeEntry = C_LFGList.GetActiveEntryInfo()
                if activeEntry and activeEntry.activityID then
                    ADW.ProcessActivityID(activeEntry.activityID, true)
                end
            end
        else
            -- Subsequent zone transitions: auto-clear when entering a dungeon instance
            local _, instanceType = IsInInstance()
            if (instanceType == "party" or instanceType == "raid") and activeRoute then
                local name = ADW.RouteNames[activeRouteKey] or activeRouteKey or "dungeon"
                Print(GREEN .. "You've entered " .. name .. "! Route cleared.|r")
                PlaySound(SOUNDKIT.UI_RAID_BOSS_DEFEATED_LG)
                ClearRoute()
            end
        end
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
        local currentContinentID = ADW.GetMapContinent(currentMapID)

        -- 1. Exact map sync (farthest match in this map)
        local furthestIndex = currentStepIndex
        for i = currentStepIndex + 1, totalSteps do
            if activeRoute[i].mapID == currentMapID then
                furthestIndex = i
            end
        end

        -- 2. Continent sync (if we changed zones but didn't match exactly, 
        -- see if we are on a relevant continent further down the route)
        if furthestIndex == currentStepIndex and currentContinentID then
            for i = currentStepIndex + 1, totalSteps do
                if ADW.GetMapContinent(activeRoute[i].mapID) == currentContinentID then
                    furthestIndex = i
                    break
                end
            end
        end

        if furthestIndex > currentStepIndex then
            LogInfo(string.format("Zone/Continent sync detected. Jumping from step %d to %d (MapID %d)", currentStepIndex, furthestIndex, currentMapID))
            currentStepIndex = furthestIndex
            SetWaypointStep(currentStepIndex)
        end
        return
    end

    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix ~= "ADW" then return end
        if sender == UnitName("player") then return end -- Ignore own messages
        if not AutoDungeonWaypointDB.AutoRouteEnabled then return end
        
        local cmd, routeKey = strsplit(":", message, 2)
        if cmd == "ROUTE" and routeKey and ADW.Routes[routeKey] then
            if activeRouteKey == routeKey then return end -- Already on this route
            local name = ADW.RouteNames[routeKey] or routeKey
            Print(ADDON_COLOR .. sender .. "|r shared a route to " .. WHITE .. name .. "|r — auto-starting!")
            LogInfo("Party route shared by " .. sender .. ": " .. name)
            StartRoute(routeKey)
        end
        return
    end
end)
