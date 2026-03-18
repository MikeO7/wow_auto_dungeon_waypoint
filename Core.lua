local _, ADW = ...
local ADW_NAME = "AutoDungeonWaypoint"

-- ============================================================================
-- IMPORTANT: LINE ENDING WARNING
-- This file must be saved with CRLF (Windows) or LF (Unix) line endings.
-- Lone \r characters (legacy Mac) will corrupt the line parsing and hide code.
-- ============================================================================

-- API Compatibility for WoW 12.0.1+ (Midnight)
local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata) or function() return nil end

-- Expose to global for SavedVariables, debugging, and Bindings.xml
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
local lastStepAdvance = 0 -- Timestamp of last forward step
local lastMapChangeTime = 0
local lastMapID = nil

-- Forward declarations to prevent nil errors (SetWaypointStep, etc.)
local SetWaypointStep, UpdateToggleButton, UpdateStatusFrame, HideStatusFrame, ShowStatusFrame

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
local ADDON_COLOR = "|cFF00BFFF"  -- Bright sky blue
local WHITE       = "|cFFFFFFFF"
local GREEN       = "|cFF00FF00"
local RED         = "|cFFFF4444"
local YELLOW      = "|cFFFFCC00"
local GRAY        = "|cFF888888"
local CYAN        = "|cFF00FFFF"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_COLOR .. "[Auto Dungeon Waypoint]|r " .. msg)
end

-- ============================================================================
-- Logging
-- ============================================================================
local function Log(level, msg)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.Log then return end
    local db = AutoDungeonWaypointDB
    local entry = string.format("[%s][%s] %s", date("%Y-%m-%d %H:%M:%S"), level, msg)
    table.insert(db.Log, entry)
    while #db.Log > (db.LogMaxLines or 200) do
        table.remove(db.Log, 1)
    end
end

local function LogInfo(msg)  Log("INFO",  msg) end
local function LogWarn(msg)  Log("WARN",  msg) end
local function LogError(msg) Log("ERROR", msg) end

-- ============================================================================
-- Status Frame (HUD)
-- ============================================================================
local statusFrame = CreateFrame("Frame", "ADWStatusFrame", UIParent)
statusFrame:SetSize(300, 70)
statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
statusFrame:SetMovable(true)
statusFrame:EnableMouse(true)
statusFrame:RegisterForDrag("LeftButton")
statusFrame:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
statusFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then AutoDungeonWaypointDB.StatusFramePos = { point, relPoint, x, y } end
end)

local bg = statusFrame:CreateTexture(nil, "BACKGROUND")
bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
bg:SetAllPoints()
bg:SetVertexColor(0.02, 0.02, 0.05, 0.9)

local glass = statusFrame:CreateTexture(nil, "BORDER")
glass:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
glass:SetAllPoints()
glass:SetAlpha(0.05)
glass:SetBlendMode("ADD")

local border = statusFrame:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Common\\WhiteSecondary-1x1")
border:SetPoint("TOPLEFT")
border:SetPoint("BOTTOMRIGHT")
border:SetAlpha(0.2)
statusFrame.Border = border

local glow = statusFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
glow:SetBlendMode("ADD")
glow:SetPoint("TOPLEFT", -15, 15)
glow:SetPoint("BOTTOMRIGHT", 15, -15)
glow:SetVertexColor(0, 0.6, 1, 0.5)
glow:SetAlpha(0)
statusFrame.Glow = glow

local function PulseGlow()
    UIFrameFadeIn(glow, 0.15, 0, 0.6)
    C_Timer.After(0.2, function() UIFrameFadeOut(glow, 0.4, 0.6, 0) end)
end

local stepIcon = statusFrame:CreateTexture(nil, "OVERLAY")
stepIcon:SetSize(32, 32)
stepIcon:SetPoint("LEFT", statusFrame, "LEFT", 30, 0)
stepIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")

local titleText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
titleText:SetPoint("TOPLEFT", stepIcon, "TOPRIGHT", 12, -4)
titleText:SetTextColor(0.0, 0.9, 1.0)
titleText:SetText("Auto Dungeon Waypoint")

local stepText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
stepText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
stepText:SetPoint("RIGHT", statusFrame, "RIGHT", -10, 0)
stepText:SetJustifyH("LEFT")
stepText:SetWordWrap(true)
stepText:SetText("")
statusFrame:Hide()

function ADW.ToggleHUD(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then
        db.ShowStatusFrame = not db.ShowStatusFrame
    else
        db.ShowStatusFrame = enabled
    end
    
    if activeRoute and db.ShowStatusFrame then
        statusFrame:Show()
        UpdateStatusFrame(ADW.RouteNames[activeRouteKey] or activeRouteKey, activeRoute[currentStepIndex].desc, currentStepIndex, totalSteps)
    else
        HideStatusFrame()
    end
end

-- Global helpers for Bindings.xml
function ADW_ToggleHUD_Binding()
    ADW.ToggleHUD()
end

function ADW_Stop_Binding()
    if SlashCmdList["AUTODUNGEONWAYPOINT"] then
        SlashCmdList["AUTODUNGEONWAYPOINT"]("stop")
    end
end

statusFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Navigation HUD", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
statusFrame:SetScript("OnLeave", GameTooltip_Hide)

local pendingHideTimer = nil

function ShowStatusFrame()
    if pendingHideTimer then pendingHideTimer:Cancel() pendingHideTimer = nil end
    statusFrame:Show()
    statusFrame:SetAlpha(1)
end

function UpdateStatusFrame(title, desc, current, total)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.ShowStatusFrame then return end
    
    if AutoDungeonWaypointDB.CompactMode then
        titleText:SetText(string.format("|cFF00FF00%d/%d|r %s", current, total, title))
        stepText:SetText("")
        statusFrame:SetHeight(40)
    else
        titleText:SetText(title)
        stepText:SetText(string.format("|cFFFFD100Step %d/%d:|r %s", current, total, desc or ""))
        statusFrame:SetHeight(70)
    end
    
    if not statusFrame:IsShown() then ShowStatusFrame() end
end

function HideStatusFrame()
    if statusFrame:IsShown() then
        if pendingHideTimer then return end
        UIFrameFadeOut(statusFrame, 0.2, statusFrame:GetAlpha(), 0)
        pendingHideTimer = C_Timer.NewTimer(0.2, function() statusFrame:Hide() pendingHideTimer = nil end)
    end
end

-- ============================================================================
-- Control Bar
-- ============================================================================
local controlBar = CreateFrame("Frame", "ADWControlBar", UIParent)
controlBar:SetSize(210, 26)
controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
controlBar:SetMovable(true)
controlBar:EnableMouse(true)
controlBar:RegisterForDrag("LeftButton")
controlBar:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
controlBar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y } end
end)

local autoBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
autoBtn:SetSize(150, 26)
autoBtn:SetPoint("LEFT", controlBar, "LEFT", 0, 0)
autoBtn:SetNormalFontObject("GameFontNormalSmall")

local menuBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
menuBtn:SetSize(46, 26)
menuBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
menuBtn:SetText("List")

autoBtn:RegisterForDrag("LeftButton")
autoBtn:SetScript("OnDragStart", function() if IsShiftKeyDown() then controlBar:StartMoving() end end)
autoBtn:SetScript("OnDragStop", function()
    controlBar:StopMovingOrSizing()
    local point, _, relPoint, x, y = controlBar:GetPoint()
    if AutoDungeonWaypointDB then AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y } end
end)

menuBtn:RegisterForDrag("LeftButton")
menuBtn:SetScript("OnDragStart", function() if IsShiftKeyDown() then controlBar:StartMoving() end end)
menuBtn:SetScript("OnDragStop", function()
    controlBar:StopMovingOrSizing()
    local point, _, relPoint, x, y = controlBar:GetPoint()
    if AutoDungeonWaypointDB then AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y } end
end)

function UpdateToggleButton()
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

-- ============================================================================
-- SmartSync Engine
-- ============================================================================
function ADW.GetMapContinent(mapID)
    if not mapID then return nil end
    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and mapInfo.mapType ~= 2 do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end
    return mapInfo and mapInfo.mapID or nil
end

local function IsMapOrChild(currentID, targetID)
    if currentID == targetID then return true end
    local info = C_Map.GetMapInfo(currentID)
    local safety = 0
    while info and info.parentMapID and safety < 10 do
        if info.parentMapID == targetID then return true end
        info = C_Map.GetMapInfo(info.parentMapID)
        safety = safety + 1
    end
    return false
end

function ADW.GetBestStepIndex(route)
    if not route then return 1 end
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then return 1 end
    local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
    local currentCont = ADW.GetMapContinent(currentMapID)
    
    local bestIdx = currentStepIndex
    if bestIdx == 0 then bestIdx = 1 end
    local bestScore = -1
    local minDistSq = math.huge

    for i, step in ipairs(route) do
        local score = 0
        if step.mapID == currentMapID then
            score = 100 -- Exact match
        elseif IsMapOrChild(currentMapID, step.mapID) then
            score = 75 -- Parent match
        elseif ADW.GetMapContinent(step.mapID) == currentCont then
            score = 50 -- Continent match
        end

        if score > 0 then
            -- Prioritize higher score (Exact > Parent > Continent)
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
                -- Same score? Pick by distance if exact, else keep current
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

local function SyncRouteProgress()
    if not activeRoute then return end
    local best = ADW.GetBestStepIndex(activeRoute)
    if best ~= currentStepIndex then
        currentStepIndex = best
        SetWaypointStep(currentStepIndex)
    end
end

local function ClearRoute()
    C_Map.ClearUserWaypoint()
    if checkTicker then checkTicker:Cancel() checkTicker = nil end
    if tomtomUID and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomUID) end
    tomtomUID = nil activeRoute = nil activeRouteKey = nil currentStepIndex = 0 totalSteps = 0
    HideStatusFrame() UpdateToggleButton()
end

function SetWaypointStep(index)
    if not activeRoute or not activeRoute[index] then
        Print(GREEN .. "You have arrived! Route complete.|r")
        LogInfo("Route complete: " .. tostring(activeRouteKey))
        PlaySound(8659) ClearRoute() return
    end
    local step = activeRoute[index]
    local point = UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
    C_Map.SetUserWaypoint(point)
    
    -- Verify and Force SuperTrack
    if C_Map.HasUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        if debugMode then Print("DEBUG: SetUserWaypoint map=" .. step.mapID .. " [SUCCESS]") end
    else
        LogError("Failed to set Blizzard waypoint for map " .. tostring(step.mapID))
    end

    if TomTom and TomTom.AddWaypoint then
        if tomtomUID then TomTom:RemoveWaypoint(tomtomUID) end
        tomtomUID = TomTom:AddWaypoint(step.mapID, step.x, step.y, { title = step.desc, source = "ADW", persistent = false })
    end
    local dungeonName = ADW.RouteNames[activeRouteKey] or activeRouteKey
    local desc = step.desc
    local nextStep = activeRoute[index + 1]
    if nextStep and nextStep.mapID ~= step.mapID then
        desc = "|cFF00FFFF[PORTAL]|r " .. desc
    end
    
    Print(YELLOW .. "Step " .. index .. "/" .. totalSteps .. ":|r " .. WHITE .. desc .. "|r")
    LogInfo("ADVANCE: Step " .. index .. "/" .. totalSteps .. " (" .. desc .. ")")
    UpdateStatusFrame(dungeonName, desc, index, totalSteps)
    if index > 1 then PlaySound(850) end
end

local function ReApplyWaypointIfMissing()
    if not activeRoute or not activeRoute[currentStepIndex] then return end
    local step = activeRoute[currentStepIndex]
    
    local hasWaypoint = C_Map.HasUserWaypoint()
    local needsUpdate = not hasWaypoint
    
    if hasWaypoint then
        local waypoint = C_Map.GetUserWaypoint()
        if waypoint and waypoint.uiMapID ~= step.mapID then
            needsUpdate = true
        end
    end

    if needsUpdate then
        local point = UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
        C_Map.SetUserWaypoint(point)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        LogInfo("Waypoint enforced: Map=" .. step.mapID)
    end
    
    -- Always re-assert SuperTrack to stay ahead of other tracked objectives
    if C_Map.HasUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
end

local function CheckDistance()
    if not activeRoute then return end
    ReApplyWaypointIfMissing()
    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then return end

    if currentMapID ~= lastMapID then
        lastMapID = currentMapID
        lastMapChangeTime = GetTime()
        if debugMode then Print("DEBUG: Map change detected. Buffer active.") end
    end
    if debugMode then Print(string.format("DEBUG: Map: %d | Step: %d", currentMapID, currentStepIndex)) end
    local bestIdx = ADW.GetBestStepIndex(activeRoute)
    if bestIdx > currentStepIndex then
        LogInfo(string.format("SmartSync: SKIP FORWARD from %d to %d (Map: %d)", currentStepIndex, bestIdx, currentMapID))
        currentStepIndex = bestIdx
        SetWaypointStep(currentStepIndex)
        return
    elseif bestIdx < currentStepIndex then
        local currentStep = activeRoute[currentStepIndex]
        if currentStep and currentMapID ~= currentStep.mapID then
            -- 1. Immunity Period: Don't snap back for 5 seconds after an advance.
            if GetTime() - lastStepAdvance < 5 then
                if debugMode then Print("DEBUG: Snap-back immunity active.") end
                return
            end

            local isPriorMap = false
            for i = 1, currentStepIndex - 1 do
                if activeRoute[i].mapID == currentMapID then isPriorMap = true break end
            end
            if isPriorMap then
                -- 2. Buffer: If we are still very close to the previous step, stay on the current one.
                local priorStep = activeRoute[currentStepIndex - 1]
                if pos and priorStep and priorStep.mapID == currentMapID then
                    local ddx = (pos.x - priorStep.x) * 1000
                    local ddy = (pos.y - priorStep.y) * 1000
                    local dSq = ddx*ddx + ddy*ddy
                    if dSq < 400.0 then -- ~100 yards buffer
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
    local step = activeRoute[currentStepIndex]
    if not step then return end
    if currentMapID == step.mapID then
        local pos = C_Map.GetPlayerMapPosition(currentMapID, "player")
        if pos then
            local dx = (pos.x - step.x) * 1000
            local dy = (pos.y - step.y) * 1000
            local distSq = dx * dx + dy * dy
            if debugMode then Print(string.format("DEBUG: Step %d DistSq: %.2f (Target: < 10.0) Map: %d", currentStepIndex, distSq, currentMapID)) end
            if distSq < 10.0 then
                -- Buffer Check: If we just changed maps, wait 3 seconds before allowing arrival.
                if GetTime() - lastMapChangeTime < 3 then
                    if debugMode then Print("DEBUG: Arrival ignored (Map change buffer active)") end
                    return
                end

                local nextStep = activeRoute[currentStepIndex + 1]
                -- STICKY LOGIC: If next step is stay-on-map, advance normally.
                -- If next step is CROSS-MAP, only advance if we are ALREADY on that map (i.e. we just ported).
                local shouldAdvance = true
                if nextStep and nextStep.mapID ~= step.mapID then
                    if currentMapID ~= nextStep.mapID then
                        shouldAdvance = false -- Stay on portal marker until map change
                        if not step.stickyMsgShown then
                            Print(CYAN .. "Arrived at portal location. Marker will remain until you enter the portal.|r")
                            step.stickyMsgShown = true
                        end
                    end
                end

                if shouldAdvance then
                    LogInfo(string.format("ARRIVAL: Step %d reached (DistSq: %.2f)", currentStepIndex, distSq))
                    if currentStepIndex < totalSteps then
                        currentStepIndex = currentStepIndex + 1
                        lastStepAdvance = GetTime()
                        SetWaypointStep(currentStepIndex)
                        UpdateToggleButton() PulseGlow()
                    else
                        Print(GREEN .. "You have arrived! Route complete.|r")
                        LogInfo("Route complete: " .. tostring(activeRouteKey))
                        PlaySound(8659) ClearRoute()
                    end
                end
            end
        end
    else
    end
end

local function StartRoute(routeKey)
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
    if currentStepIndex > 1 then msg = msg .. GRAY .. " — sync'd to step " .. currentStepIndex .. "|r" end
    Print(msg)
    LogInfo("Route started: " .. dungeonName .. " (Step: " .. currentStepIndex .. "/" .. totalSteps .. ")")
    PlaySound(846) SetWaypointStep(currentStepIndex) UpdateToggleButton()
    checkTicker = C_Timer.NewTicker(0.1, CheckDistance)
    if IsInGroup() then C_ChatInfo.SendAddonMessage("ADW", "ROUTE:" .. routeKey, "PARTY") end
end

function ADW.ToggleAutoRoute(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then db.AutoRouteEnabled = not db.AutoRouteEnabled else db.AutoRouteEnabled = enabled end
    UpdateToggleButton()
    if db.AutoRouteEnabled then Print("Auto-Routing " .. GREEN .. "enabled|r.")
    else Print("Auto-Routing " .. RED .. "disabled|r.") ClearRoute() end
end

-- ============================================================================
-- Options, Menus, Slash
-- ============================================================================
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "ADWOptionsPanel", UIParent)
    panel.name = "Auto Dungeon Waypoint"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16) title:SetText("Auto Dungeon Waypoint Settings")
    local autoCheck = CreateFrame("CheckButton", "ADWAutoRoutingCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    autoCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    _G[autoCheck:GetName() .. "Text"]:SetText("Enable Auto-Routing")
    autoCheck:SetScript("OnClick", function(self) ADW.ToggleAutoRoute(self:GetChecked()) end)
    autoCheck:SetScript("OnShow", function(self) self:SetChecked(AutoDungeonWaypointDB.AutoRouteEnabled) end)
    local hudCheck = CreateFrame("CheckButton", "ADWShowHUDCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    hudCheck:SetPoint("TOPLEFT", autoCheck, "BOTTOMLEFT", 0, -8)
    _G[hudCheck:GetName() .. "Text"]:SetText("Show Navigation HUD")
    hudCheck:SetScript("OnClick", function(self)
        AutoDungeonWaypointDB.ShowStatusFrame = self:GetChecked()
        if activeRoute and AutoDungeonWaypointDB.ShowStatusFrame then statusFrame:Show() else statusFrame:Hide() end
    end)
    hudCheck:SetScript("OnShow", function(self) self:SetChecked(AutoDungeonWaypointDB.ShowStatusFrame) end)
    local compactCheck = CreateFrame("CheckButton", "ADWCompactModeCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    compactCheck:SetPoint("TOPLEFT", hudCheck, "BOTTOMLEFT", 0, -8)
    _G[compactCheck:GetName() .. "Text"]:SetText("Compact HUD")
    compactCheck:SetScript("OnClick", function(self)
        AutoDungeonWaypointDB.CompactMode = self:GetChecked()
        if activeRoute then UpdateStatusFrame(ADW.RouteNames[activeRouteKey] or activeRouteKey, nil, currentStepIndex, totalSteps) end
    end)
    compactCheck:SetScript("OnShow", function(self) self:SetChecked(AutoDungeonWaypointDB.CompactMode) end)
    local resetBtn = CreateFrame("Button", "ADWResetBtn", panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 26) resetBtn:SetPoint("TOPLEFT", compactCheck, "BOTTOMLEFT", 0, -20) resetBtn:SetText("Reset Positions")
    resetBtn:SetScript("OnClick", function()
        AutoDungeonWaypointDB.StatusFramePos = nil AutoDungeonWaypointDB.ToggleButtonPos = nil
        statusFrame:ClearAllPoints() statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
        controlBar:ClearAllPoints() controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else InterfaceOptions_AddCategory(panel) end
end

local adwMenuFrame = CreateFrame("Frame", "ADWMenuFrame", UIParent, "UIDropDownMenuTemplate")
local function ADWMenu_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF00BFFFAll Dungeons|r" info.isTitle = true info.notCheckable = true
    UIDropDownMenu_AddButton(info)
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

autoBtn:SetScript("OnClick", function() ADW.ToggleAutoRoute() end)
menuBtn:SetScript("OnClick", function(self)
    UIDropDownMenu_Initialize(adwMenuFrame, ADWMenu_Initialize, "MENU")
    ToggleDropDownMenu(1, nil, adwMenuFrame, self, 0, 0)
end)

SLASH_AUTODUNGEONWAYPOINT1 = "/adw"
SLASH_AUTODUNGEONWAYPOINT2 = "/autodungeonwaypoint"
SlashCmdList["AUTODUNGEONWAYPOINT"] = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)
    if cmd == "route" and arg then StartRoute(arg)
    elseif cmd == "stop" then ClearRoute() Print("Route cancelled.")
    elseif cmd == "toggle" then ADW.ToggleAutoRoute()
    elseif cmd == "list" then
        Print("Available routes:")
        for key, name in pairs(ADW.RouteNames) do
            local steps = ADW.Routes[key] and #ADW.Routes[key] or 0
            Print("  " .. YELLOW .. key .. "|r — " .. WHITE .. name .. "|r " .. GRAY .. "(" .. steps .. " steps)|r")
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
        if bestKey then StartRoute(bestKey) else Print(RED .. "No nearby dungeon routes found.|r") end
    elseif cmd == "move" then
        if statusFrame:IsShown() then
            HideStatusFrame()
            Print("HUD hidden.")
        else
            UpdateStatusFrame("HUD Positioning", "Hold SHIFT and drag to move this frame. Type /adw move again to hide.", 1, 1)
            statusFrame:Show()
            statusFrame:SetAlpha(1)
            Print("HUD shown for positioning.")
        end
    elseif cmd == "debug" then
        debugMode = not debugMode
        Print("Debug mode " .. (debugMode and GREEN .. "enabled|r" or RED .. "disabled|r"))
    elseif cmd == "mapid" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        local info = C_Map.GetMapInfo(currentMapID)
        Print("Current Map ID: " .. (currentMapID or "nil") .. " (" .. (info and info.name or "Unknown") .. ")")
        if info and info.parentMapID then
            local pInfo = C_Map.GetMapInfo(info.parentMapID)
            Print("Parent Map ID: " .. info.parentMapID .. " (" .. (pInfo and pInfo.name or "Unknown") .. ")")
        end
    else
        Print("Commands: /adw route <id>, /adw list, /adw nearest, /adw stop, /adw toggle, /adw move, /adw mapid")
    end
end

-- ============================================================================
-- LFG Processor
-- ============================================================================
function ADW.ProcessActivityID(activityID, isSilent)
    if not activityID then return end
    
    -- Prevent auto-routing if already inside a dungeon or raid
    local _, instanceType = IsInInstance()
    if instanceType == "party" or instanceType == "raid" then
        LogInfo("ProcessActivityID: Already in instance (" .. instanceType .. "), skipping.")
        return
    end

    local routeKey = ADW.LFGToRoute[activityID]
    LogInfo("ProcessActivityID: ID=" .. tostring(activityID) .. " Key=" .. tostring(routeKey))
    if not routeKey then
        local info = C_LFGList.GetActivityInfoTable(activityID)
        if info and info.fullName then
            LogInfo("ProcessActivityID: Name=" .. info.fullName)
            local lowerName = info.fullName:lower():gsub("[%p%s]", "")
            for key, name in pairs(ADW.RouteNames) do
                local cleanTarget = name:lower():gsub("[%p%s]", "")
                if lowerName:find(cleanTarget, 1, true) then routeKey = key break end
            end
        end
    end
    if routeKey then
        if activeRouteKey == routeKey then return end
        local name = ADW.RouteNames[routeKey] or routeKey
        if not isSilent then Print(GREEN .. "Dungeon detected:|r " .. WHITE .. name .. "|r — auto-starting!") end
        StartRoute(routeKey)
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
    if event == "ADDON_LOADED" and arg1 == "AutoDungeonWaypoint" then
        if not AutoDungeonWaypointDB then AutoDungeonWaypointDB = {} end
        for k, v in pairs(DEFAULTS) do if AutoDungeonWaypointDB[k] == nil then AutoDungeonWaypointDB[k] = v end end
        if AutoDungeonWaypointDB.StatusFramePos then
            local p = AutoDungeonWaypointDB.StatusFramePos
            statusFrame:ClearAllPoints() statusFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end
        if AutoDungeonWaypointDB.ToggleButtonPos then
            local p = AutoDungeonWaypointDB.ToggleButtonPos
            controlBar:ClearAllPoints() controlBar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end
        UpdateToggleButton() CreateOptionsPanel()
        local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
        local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LDBIcon and not LDBIcon.GetButtonList then
            LDBIcon.GetButtonList = function(self)
                local t = {} if self.objects then for name in pairs(self.objects) do table.insert(t, name) end end
                return t
            end
        end
        if LDBIcon and not LDBIcon.RegisterCallback then
            local CallbackHandler = LibStub and LibStub("CallbackHandler-1.0", true)
            if CallbackHandler then CallbackHandler:New(LDBIcon) end
        end
        if LDB and LDBIcon then
            local adwBroker = LDB:NewDataObject("AutoDungeonWaypoint", {
                type = "launcher", text = "Auto Dungeon Waypoint", icon = "Interface\\Icons\\INV_Misc_Map_01",
                OnClick = function(_, button)
                    if button == "LeftButton" then
                        UIDropDownMenu_Initialize(adwMenuFrame, ADWMenu_Initialize, "MENU")
                        ToggleDropDownMenu(1, nil, adwMenuFrame, "cursor", 0, 0)
                    elseif button == "RightButton" then ADW.ToggleAutoRoute() end
                end,
                OnTooltipShow = function(tooltip)
                    tooltip:SetText("Auto Dungeon Waypoint", 0.0, 0.75, 1.0)
                    if activeRoute then tooltip:AddLine("Active: " .. (ADW.RouteNames[activeRouteKey] or activeRouteKey)) end
                end,
            })
            LDBIcon:Register("AutoDungeonWaypoint", adwBroker, AutoDungeonWaypointDB.MinimapIcon)
        end
        self:UnregisterEvent("ADDON_LOADED") return
    end
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
                Print(GREEN .. "Entered dungeon! Route cleared.|r") ClearRoute()
            elseif activeRoute then SetWaypointStep(currentStepIndex) end
        end
        return
    end
    if event == "LFG_LIST_JOINED_GROUP" then
        local searchResultID = ...
        if searchResultID and AutoDungeonWaypointDB.AutoRouteEnabled then
            local info = C_LFGList.GetSearchResultInfo(searchResultID)
            if info and info.activityID then ADW.ProcessActivityID(info.activityID) end
        end
        return
    end
    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        if AutoDungeonWaypointDB.AutoRouteEnabled then
            local activeEntry = C_LFGList.GetActiveEntryInfo()
            LogInfo("LFG_LIST_ACTIVE_ENTRY_UPDATE: Found=" .. tostring(activeEntry ~= nil))
            if activeEntry and activeEntry.activityIDs then
                for _, id in ipairs(activeEntry.activityIDs) do
                    ADW.ProcessActivityID(id)
                end
            end
        end
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then if activeRoute then SyncRouteProgress() end return end
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == "ADW" and sender ~= UnitName("player") and AutoDungeonWaypointDB.AutoRouteEnabled then
            local cmd, routeKey = strsplit(":", message, 2)
            if cmd == "ROUTE" and routeKey and ADW.Routes[routeKey] and activeRouteKey ~= routeKey then
                Print(sender .. " shared a route to " .. (ADW.RouteNames[routeKey] or routeKey))
                StartRoute(routeKey)
            end
        end
    end
end)
