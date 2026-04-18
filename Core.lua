local addonName, ADW = ...

-- ============================================================================
-- IMPORTANT: LINE ENDING WARNING
-- This file must be saved with CRLF (Windows) or LF (Unix) line endings.
-- Lone \r characters (legacy Mac) will corrupt the line parsing and hide code.
-- ============================================================================

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
local lastPlayerX = nil
local lastPlayerY = nil
local isPlayerInInstance = false

-- Forward declarations to prevent nil errors (SetWaypointStep, etc.)
local SetWaypointStep, UpdateToggleButton, UpdateStatusFrame, HideStatusFrame, ShowStatusFrame, StartRoute, ClearRoute, GetKnownPortal

-- ============================================================================
-- Defaults for SavedVariables
-- ============================================================================
local DEFAULTS = {
    AutoRouteEnabled = true,
    ShowStatusFrame = true,
    ShowControlBar = true,
    ShowChatText = true,
    EnableSounds = true,
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

local function ForcePrint(msg)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_COLOR .. (ADW.L["HUD_TITLE"] or "[Auto Dungeon Waypoint]") .. "|r " .. msg)
end

local function Print(msg)
    if AutoDungeonWaypointDB and AutoDungeonWaypointDB.ShowChatText == false then return end
    ForcePrint(msg)
end

local function DebugPrint(msg)
    if debugMode then Print(msg) end
end

local function AddSharedTooltipLines(tooltip)
    local stateText = (AutoDungeonWaypointDB and AutoDungeonWaypointDB.AutoRouteEnabled) and "|cFF55FF55ON|r" or "|cFFFF5555OFF|r"
    tooltip:AddLine((ADW.L["AUTO_ROUTING"] or "Auto-Routing: ") .. stateText, 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine(ADW.L["LEFT_CLICK_MENU"] or "|cFFFFD100Left-Click:|r Open route menu", 1, 1, 1)
    tooltip:AddLine(ADW.L["RIGHT_CLICK_TOGGLE"] or "|cFFFFD100Right-Click:|r Toggle auto-routing", 1, 1, 1)
end

-- ============================================================================
-- Logging
-- ============================================================================
local function Log(level, msg)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.Log then return end
    local db = AutoDungeonWaypointDB
    -- Midnight Resilience: Wrap in pcall to prevent crashes when logging "secret" strings.
    -- If string conversion fails, we log a placeholder instead of crashing the addon.
    local success, formattedEntry = pcall(function()
        return string.format("[%s][%s] %s", date("%Y-%m-%d %H:%M:%S"), level, msg)
    end)
    
    if success then
        table.insert(db.Log, formattedEntry)
    else
        table.insert(db.Log, string.format("[%s][%s] ERROR: Message contains protected data.", date("%Y-%m-%d %H:%M:%S"), level))
    end
    
    while #db.Log > (db.LogMaxLines or 200) do
        table.remove(db.Log, 1)
    end
end

local function LogInfo(msg)  Log("INFO",  msg) end
local function LogWarn(msg)  Log("WARN",  msg) end

local function DebugLog(msg)
    if debugMode then LogInfo(msg) end
end
local function LogError(msg) Log("ERROR", msg) end

-- ============================================================================
-- Popups
-- ============================================================================
StaticPopupDialogs["ADW_CONFIRM_ROUTE"] = {
    text = ADDON_COLOR .. (ADW.L["CONFIRM_ROUTE_MSG"] or "[Auto Dungeon Waypoint]|r\n\n%s shared a route to %s.\n\nDo you want to start this route?"),
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data)
        StartRoute(data.routeKey, true)
    end,
    timeout = 30,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ============================================================================
-- UI Helpers (DRY)
-- ============================================================================
function ADW.ApplyGlassAesthetic(frame, hasBorder)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetAllPoints()
    bg:SetVertexColor(0.02, 0.02, 0.05, 0.9)
    frame.Background = bg

    local glass = frame:CreateTexture(nil, "BORDER")
    glass:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
    glass:SetAllPoints()
    glass:SetAlpha(0.05)
    glass:SetBlendMode("ADD")
    frame.Glass = glass

    if hasBorder then
        local border = frame:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Common\\WhiteSecondary-1x1")
        border:SetPoint("TOPLEFT")
        border:SetPoint("BOTTOMRIGHT")
        border:SetAlpha(0.2)
        frame.Border = border
    end
end

function ADW.MakeDraggable(frame, dbKey, parentFrame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    local target = parentFrame or frame
    local isDragging = false
    local originalAlpha = 1.0
    frame:SetScript("OnDragStart", function() 
        if IsShiftKeyDown() then
            isDragging = true
            originalAlpha = target:GetAlpha()
            target:StartMoving()
            target:SetAlpha(originalAlpha * 0.7)
        end
    end)
    frame:SetScript("OnDragStop", function()
        target:StopMovingOrSizing()
        if isDragging then
            target:SetAlpha(originalAlpha)
            isDragging = false
            if AutoDungeonWaypointDB and dbKey then
                local point, _, relPoint, x, y = target:GetPoint()
                AutoDungeonWaypointDB[dbKey] = { point, relPoint, x, y }
            end
        end
    end)
end

function ADW.SetTooltip(frame, title, body, extraInfo)
    frame:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetText(title, 0.0, 0.75, 1.0)
        if body then GameTooltip:AddLine(body, 1, 1, 1, true) end
        if extraInfo then GameTooltip:AddLine(extraInfo, 1, 0.8, 0, true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

function ADW.GenerateDungeonMenu(owner, rootDescription)
    rootDescription:CreateTitle(ADDON_COLOR .. (ADW.L["HUD_TITLE"] or "Auto Dungeon Waypoint") .. "|r")
    rootDescription:CreateButton(YELLOW .. (ADW.L["TOGGLE_AUTO_ROUTING"] or "Toggle Auto-Routing") .. "|r", function() ADW.ToggleAutoRoute() end)
    
    if activeRoute then
        rootDescription:CreateButton(RED .. (ADW.L["CANCEL_ACTIVE_ROUTE"] or "Cancel Active Route") .. "|r", function() ADW_Stop_Binding() end)
    end

    rootDescription:CreateDivider()
    
    local keys = {}
    for k in pairs(ADW.RouteNames) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return ADW.RouteNames[a] < ADW.RouteNames[b] end)
    
    for _, key in ipairs(keys) do
        local btnText = ADW.RouteNames[key]
        if key == activeRouteKey then
            btnText = "|cFF00FF00>|r " .. btnText .. " " .. GREEN .. (ADW.L["ACTIVE"] or "(Active)") .. "|r"
        end
        rootDescription:CreateButton(btnText, function() StartRoute(key) end)
    end
    
    rootDescription:CreateDivider()
    rootDescription:CreateButton(GRAY .. (ADW.L["OPEN_SETTINGS"] or "Open Settings") .. "|r", function()
        if ADW.settingsCategory then Settings.OpenToCategory(ADW.settingsCategory:GetID()) end 
    end)
end

function ADW.CreateConfigCheckbox(panel, label, dbKey, tooltipTitle, tooltipBody, callback)
    local check = CreateFrame("CheckButton", "ADW_"..dbKey.."_Check", panel, "UICheckButtonTemplate")
    local textLabel = _G[check:GetName() .. "Text"]
    textLabel:SetText(label)

    -- Expand hit area to include text
    local textWidth = textLabel:GetStringWidth() or 100
    check:SetHitRectInsets(0, -textWidth, 0, 0)

    check:SetScript("OnClick", function(self)
        AutoDungeonWaypointDB[dbKey] = self:GetChecked()
        if callback then callback(self:GetChecked()) end
    end)
    check:SetScript("OnShow", function(self)
        self:SetChecked(AutoDungeonWaypointDB[dbKey] ~= false)
    end)
    ADW.SetTooltip(check, tooltipTitle, tooltipBody)
    return check
end

-- ============================================================================
-- Status Frame (HUD)
-- ============================================================================
local statusFrame = CreateFrame("Frame", "ADWStatusFrame", UIParent)
statusFrame:SetSize(300, 70)
statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
ADW.ApplyGlassAesthetic(statusFrame, true)
ADW.MakeDraggable(statusFrame, "StatusFramePos")

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
titleText:SetText(ADW.L["HUD_TITLE"] or "Auto Dungeon Waypoint")

local stepText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
stepText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
stepText:SetPoint("RIGHT", statusFrame, "RIGHT", -10, 0)
stepText:SetJustifyH("LEFT")
stepText:SetWordWrap(true)
stepText:SetText("")

local progressBar = CreateFrame("StatusBar", "ADWProgressBar", statusFrame)
progressBar:SetPoint("BOTTOMLEFT", statusFrame, "BOTTOMLEFT", 6, 6)
progressBar:SetPoint("BOTTOMRIGHT", statusFrame, "BOTTOMRIGHT", -6, 6)
progressBar:SetHeight(4)
progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
progressBar:SetStatusBarColor(0, 0.75, 1, 0.8) -- Cyan

local progressBg = progressBar:CreateTexture(nil, "BACKGROUND")
progressBg:SetAllPoints()
progressBg:SetColorTexture(0, 0, 0, 0.5) -- Dark semi-transparent background track

progressBar:Hide()
statusFrame:Hide()

local closeBtn = CreateFrame("Button", nil, statusFrame, "UIPanelCloseButton")
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("TOPRIGHT", statusFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    if activeRoute then
        ADW_Stop_Binding()
    else
        HideStatusFrame()
    end
end)
closeBtn:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetText(ADW.L["CLOSE"] or "Close", 0.0, 0.75, 1.0)
    GameTooltip:AddLine(ADW.L["DISMISS_HUD"] or "Dismiss the navigation HUD.", 1, 1, 1, true)
    if activeRoute then
        GameTooltip:AddLine(ADW.L["CLOSE_WARNING"] or "WARNING: Closes the active route.", 1, 0.2, 0.2, true)
    end
    GameTooltip:Show()
end)
closeBtn:SetScript("OnLeave", GameTooltip_Hide)

-- ============================================================================
-- Portal Shortcut Button (Secure)
-- ============================================================================
local portalBtn = CreateFrame("Button", "ADWPortalButton", statusFrame, "SecureActionButtonTemplate")
portalBtn:SetSize(52, 52)
portalBtn:SetPoint("RIGHT", statusFrame, "LEFT", -12, 0)
ADW.ApplyGlassAesthetic(portalBtn, true)

-- Add a glow (more apparent)
local glow = portalBtn:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetAllPoints()
glow:SetAlpha(0.7)
portalBtn.Glow = glow

local portalIcon = portalBtn:CreateTexture(nil, "ARTWORK")
portalIcon:SetSize(42, 42)
portalIcon:SetPoint("CENTER")
portalIcon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalDalaran")
portalBtn.Icon = portalIcon

-- Add a "Teleport" label (more apparent)
local portalLabel = portalBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
portalLabel:SetPoint("BOTTOM", portalBtn, "TOP", 0, 4)
portalLabel:SetText(ADW.L["TELEPORT"] or "TELEPORT")
portalLabel:SetTextColor(0, 1, 1, 0.9) -- Cyan glow
portalBtn.Label = portalLabel

-- Add a "Shine" sweep effect
local shine = portalBtn:CreateTexture(nil, "OVERLAY")
shine:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
shine:SetBlendMode("ADD")
shine:SetSize(52, 52)
shine:SetPoint("CENTER")
shine:SetAlpha(0)
portalBtn.Shine = shine

local cd = CreateFrame("Cooldown", "ADWPortalCooldown", portalBtn, "CooldownFrameTemplate")
cd:SetAllPoints()
portalBtn.Cooldown = cd

portalBtn:SetAttribute("type", "macro")
portalBtn:RegisterForClicks("AnyUp", "AnyDown")

-- Pulsing Glow & Shimmer Animation
local TWO_PI = math.pi * 2
portalBtn:SetScript("OnUpdate", function(self, elapsed)
    if self:IsShown() then
        local now = GetTime()
        local phase = (now * 3) % TWO_PI
        local alpha = 0.3 + (math.sin(phase) * 0.4)
        self.Glow:SetAlpha(alpha)
        
        -- Shimmer effect every 4 seconds
        local shimmerPhase = (now % 4)
        if shimmerPhase < 0.5 then
            self.Shine:SetAlpha(shimmerPhase * 2)
            self.Shine:SetSize(52 + (shimmerPhase * 20), 52 + (shimmerPhase * 20))
        else
            self.Shine:SetAlpha(0)
        end
        
        -- Update Cooldown responsiveness (throttled to avoid table allocation spam in OnUpdate)
        self.cdTimer = (self.cdTimer or 0) + elapsed
        if self.cdTimer > 0.2 then
            self.cdTimer = 0
            if self.pID then
                local start, duration = 0, 0
                local cdInfo = C_Spell.GetSpellCooldown(self.pID)
                if cdInfo then
                    start, duration = cdInfo.startTime, cdInfo.duration
                end

                if start and duration > 0 then
                    -- Cooldown frame handles the spiral, we just handle the desaturation
                    if not self.Icon:IsDesaturated() then self.Icon:SetDesaturated(true) end
                else
                    if self.Icon:IsDesaturated() then self.Icon:SetDesaturated(false) end
                end
            end
        end
    end
end)


-- Hover Highlight
portalBtn:SetScript("OnEnter", function(self)
    self.Icon:SetVertexColor(1, 1, 0, 1) -- Light yellow highlight
    GameTooltip_SetDefaultAnchor(GameTooltip, self)

    local title = ADW.L["USE_TELEPORT"] or "Use Dungeon Teleport"
    if self.pID then
        local spellName = C_Spell.GetSpellName(self.pID)
        if spellName then
            title = spellName
        end
    end

    GameTooltip:SetText(title, 0.0, 0.75, 1.0)
    GameTooltip:AddLine(ADW.L["TELEPORT_CLICK"] or "Click to teleport directly to the dungeon entrance.", 1, 1, 1, true)
    GameTooltip:AddLine(ADW.L["TELEPORT_REQUIREMENT"] or "Requires the Mythic+ Keystone Hero teleport spell.", 1, 0.8, 0, true)
    GameTooltip:Show()
end)
portalBtn:SetScript("OnLeave", function(self)
    self.Icon:SetVertexColor(1, 1, 1, 1) -- Reset to white
    GameTooltip_Hide()
end)

portalBtn:Hide()

function ADW.ToggleHUD(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then
        db.ShowStatusFrame = not db.ShowStatusFrame
    else
        db.ShowStatusFrame = enabled
    end
    
    if activeRoute and db.ShowStatusFrame then
        statusFrame:Show()
        local stepDesc = ""
        local isPortal = false
        if currentStepIndex > 0 and activeRoute[currentStepIndex] then
            stepDesc = activeRoute[currentStepIndex].desc or ""
            local nextStep = activeRoute[currentStepIndex + 1]
            if nextStep and nextStep.mapID ~= activeRoute[currentStepIndex].mapID then
                stepDesc = "|cFF00FFFF[PORTAL]|r " .. stepDesc
                isPortal = true
            end
        end
        UpdateStatusFrame(ADW.RouteNames[activeRouteKey] or activeRouteKey, stepDesc, currentStepIndex, totalSteps, isPortal)
    else
        HideStatusFrame()
    end

    if db.ShowStatusFrame then
        Print((ADW.L["HUD_SHOWN"] or "Navigation HUD shown") .. GREEN .. "|r.")
    else
        Print((ADW.L["HUD_HIDDEN"] or "Navigation HUD hidden") .. RED .. "|r.")
    end
end

-- Keybinding localization strings for discoverability
BINDING_HEADER_ADW = ADW.L["BINDING_HEADER"] or "Auto Dungeon Waypoint"
BINDING_NAME_ADW_TOGGLEHUD = ADW.L["BINDING_TOGGLEHUD"] or "Toggle Navigation HUD"
BINDING_NAME_ADW_STOP = ADW.L["BINDING_STOP"] or "Cancel Route"

-- Global helpers for Bindings.xml
function ADW_ToggleHUD_Binding()
    ADW.ToggleHUD()
end

function ADW_Stop_Binding()
    ClearRoute()
    ForcePrint(ADW.L["ROUTE_CANCELLED"] or "Route cancelled.")
end

statusFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" and activeRoute then
        ADW_Stop_Binding()
    end
end)

statusFrame:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetText(ADW.L["HUD_TITLE"] or "Auto Dungeon Waypoint", 0.0, 0.75, 1.0)

    if AutoDungeonWaypointDB and AutoDungeonWaypointDB.CompactMode then
        local currentStepDesc = ""
        if activeRoute and activeRoute[currentStepIndex] then
            currentStepDesc = activeRoute[currentStepIndex].desc or ""
        elseif titleText:GetText() and (string.find(titleText:GetText(), ADW.L["HUD_PREVIEW"] or "HUD Preview")) then
            currentStepDesc = ADW.L["HUD_PREVIEW_DESC"] or "This is how the HUD looks."
        elseif titleText:GetText() and (string.find(titleText:GetText(), ADW.L["HUD_POSITIONING"] or "HUD Positioning")) then
            currentStepDesc = ADW.L["HUD_MOVE_DESC"] or "Hold SHIFT and drag to move this frame. Type /adw move again to hide."
        end
        if currentStepDesc ~= "" then
            GameTooltip:AddLine(currentStepDesc, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
        end
    end

    GameTooltip:AddLine(ADW.L["RIGHT_CLICK_CANCEL"] or "Right-click to cancel the active route.", 1, 1, 1, true)
    GameTooltip:AddLine(ADW.L["SHIFT_DRAG_MOVE"] or "Hold |cFFFFD100Shift|r and drag to move.", 1, 0.8, 0, true)
    GameTooltip:Show()
end)
statusFrame:SetScript("OnLeave", GameTooltip_Hide)

local pendingHideTimer = nil

function ShowStatusFrame()
    if pendingHideTimer then pendingHideTimer:Cancel() pendingHideTimer = nil end
    statusFrame:SetAlpha(1)
    statusFrame:Show()
end

function UpdateStatusFrame(title, desc, current, total, isPortal)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.ShowStatusFrame then return end
    if isPortal then stepIcon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalDalaran") else stepIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01") end
    
    -- Handle Portal Shortcut Button
    local pID, pName = GetKnownPortal(activeRoute)
    portalBtn.pID = pID -- Store for OnUpdate
    if pID and pName then
        if not InCombatLockdown() then
            portalBtn:SetAttribute("macrotext", "/cast " .. pName)
            local spellData = C_Spell.GetSpellInfo(pID)
            local sIcon = spellData and spellData.iconID
            if sIcon then portalBtn.Icon:SetTexture(sIcon) end
            
            -- Update Cooldown
            local start, duration = 0, 0
            local cdInfo = C_Spell.GetSpellCooldown(pID)
            if cdInfo then
                start, duration = cdInfo.startTime, cdInfo.duration
            end
            
            if start and duration > 0 then
                portalBtn.Cooldown:SetCooldown(start, duration)
                portalBtn.Icon:SetDesaturated(true)
            else
                portalBtn.Cooldown:Clear()
                portalBtn.Icon:SetDesaturated(false)
            end

            if not portalBtn:IsShown() then UIFrameFadeIn(portalBtn, 0.4, 0, 1) end
            portalBtn:Show()

        end
    else
        if not InCombatLockdown() then
            portalBtn:SetAttribute("macrotext", nil)
            portalBtn:Hide()
        end
    end
    
    if AutoDungeonWaypointDB.CompactMode then
        titleText:SetText(string.format("|cFF00FF00%d/%d|r %s", current, total, title))
        stepText:SetText("")
        statusFrame:SetHeight(40)
    else
        titleText:SetText(title)
        stepText:SetText(string.format("|cFFFFD100Step %d/%d:|r %s", current, total, desc or ""))
        statusFrame:SetHeight(70)
    end
    
    if total and total > 0 then
        progressBar:SetMinMaxValues(0, total)
        progressBar:SetValue(current or 0)
        progressBar:Show()
    else
        progressBar:Hide()
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
-- Timeways Portal Map (visual overlay)
-- ============================================================================
local portalMap = CreateFrame("Frame", "ADWPortalMap", statusFrame)
portalMap:SetSize(240, 50)
portalMap:SetPoint("TOP", statusFrame, "BOTTOM", 0, -4)
ADW.ApplyGlassAesthetic(portalMap)
portalMap:Hide()

-- Create a font string for each slot based on ADW.PortalLayout in Data.lua
local slotLabels = {}
if ADW.PortalLayout then
    for i, slot in ipairs(ADW.PortalLayout) do
        local xOff = (i - 3) * 40  -- spread slots across the frame
        local label = portalMap:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        label:SetPoint("CENTER", portalMap, "CENTER", xOff, 2)
        label:SetText(slot.circle)
        label:SetTextColor(0.5, 0.5, 0.5)
        slotLabels[i] = label
    end
end

-- Active portal name displayed below the circles
local activeLabel = portalMap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
activeLabel:SetPoint("BOTTOM", portalMap, "BOTTOM", 0, 5)
activeLabel:SetTextColor(0, 0.9, 0.7)
activeLabel:SetText("")

local function ShowPortalMap(routeKey)
    if not ADW.PortalLayout then return end
    for i, slot in ipairs(ADW.PortalLayout) do
        if slot.key == routeKey then
            slotLabels[i]:SetTextColor(0, 1, 0.7)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
            activeLabel:SetText("▲ " .. slot.name)
        elseif slot.key then
            slotLabels[i]:SetTextColor(0.65, 0.65, 0.65)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        else
            slotLabels[i]:SetTextColor(0.5, 0.5, 0.5)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        end
    end
    portalMap:Show()
end

local function HidePortalMap()
    portalMap:Hide()
end

-- ============================================================================
-- Control Bar
-- ============================================================================
local controlBar = CreateFrame("Frame", "ADWControlBar", UIParent)
controlBar:SetSize(210, 26)
controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
ADW.MakeDraggable(controlBar, "ToggleButtonPos")

local autoBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
autoBtn:SetSize(150, 26)
autoBtn:SetPoint("LEFT", controlBar, "LEFT", 0, 0)
autoBtn:SetNormalFontObject("GameFontNormalSmall")
ADW.MakeDraggable(autoBtn, "ToggleButtonPos", controlBar)
autoBtn:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    if activeRoute and activeRouteKey then
        local name = ADW.RouteNames[activeRouteKey] or activeRouteKey
        GameTooltip:SetText(name, 0.0, 0.75, 1.0)
        GameTooltip:AddLine(ADW.L["ACTIVE_ROUTE"] or "Active Route", 1, 1, 1, true)
    else
        local stateText = (AutoDungeonWaypointDB and AutoDungeonWaypointDB.AutoRouteEnabled) and "|cFF55FF55[ON]|r" or "|cFFFF5555[OFF]|r"
        GameTooltip:SetText((ADW.L["TOGGLE_AUTO_ROUTING"] or "Toggle Auto-Routing") .. " " .. stateText, 0.0, 0.75, 1.0)
        GameTooltip:AddLine(ADW.L["ENABLE_AUTO_ROUTING_DESC"] or "Click to enable/disable automatic dungeon detection.", 1, 1, 1, true)
    end
    GameTooltip:AddLine(ADW.L["SHIFT_DRAG_MOVE"] or "Hold |cFFFFD100Shift|r and drag to move.", 1, 0.8, 0, true)
    GameTooltip:Show()
end)
autoBtn:SetScript("OnLeave", GameTooltip_Hide)

local menuBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
menuBtn:SetSize(46, 26)
menuBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
menuBtn:SetText(ADW.L["LIST"] or "List")
ADW.MakeDraggable(menuBtn, "ToggleButtonPos", controlBar)
ADW.SetTooltip(menuBtn, ADW.L["LIST"] or "List", ADW.L["ROUTE_LIST_DESC"] or "Click to view and manually start routes.", ADW.L["SHIFT_DRAG_MOVE"] or "Hold |cFFFFD100Shift|r and drag to move.")

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

ADW.MapPosCache = { x = nil, y = nil, inst = nil, map = nil, pos = nil }
function ADW.GetPlayerMapPosition(mapID)
    if not mapID then return nil end
    local y, x, _, instanceID = UnitPosition("player")
    if not x then return C_Map.GetPlayerMapPosition(mapID, "player") end

    if x == ADW.MapPosCache.x and y == ADW.MapPosCache.y and instanceID == ADW.MapPosCache.inst and mapID == ADW.MapPosCache.map then
        return ADW.MapPosCache.pos
    end

    ADW.MapPosCache.x = x
    ADW.MapPosCache.y = y
    ADW.MapPosCache.inst = instanceID
    ADW.MapPosCache.map = mapID
    ADW.MapPosCache.pos = C_Map.GetPlayerMapPosition(mapID, "player")
    return ADW.MapPosCache.pos
end

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
    -- Use 2D table to avoid string concatenation in polling loop
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
    if safety >= 10 then DebugPrint("IsMapOrChild: depth limit reached for map " .. tostring(currentID) .. " -> " .. tostring(targetID)) end
    ADW.MapParentCache[currentID][targetID] = isChild
    return isChild
end

function ADW.GetBestStepIndex(route, currentMapID, pos)
    if not route then return 1 end

    -- Use provided map ID and position if passed (performance optimization),
    -- otherwise fetch them via Blizzard API.
    if not currentMapID then
        currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then 
            return (currentStepIndex and currentStepIndex > 0) and currentStepIndex or 1 
        end
    end

    local currentCont = ADW.GetMapContinent(currentMapID)
    
    local bestIdx = currentStepIndex
    if bestIdx == 0 then bestIdx = 1 end
    local bestScore = -1
    local minDistSq = math.huge
    local posFetched = (pos ~= nil)

    for i, step in ipairs(route) do
        local score = 0
        if step.mapID == currentMapID then
            score = 100 -- Exact match
        elseif bestScore <= 75 and IsMapOrChild(currentMapID, step.mapID) then
            score = 75 -- Parent match
        elseif bestScore <= 50 and ADW.GetMapContinent(step.mapID) == currentCont then
            score = 50 -- Continent match
        end

        if score > 0 then
            -- Prioritize higher score (Exact > Parent > Continent)
            if score > bestScore then
                bestScore = score
                bestIdx = i
                minDistSq = nil -- Lazy evaluate distance only if a tie occurs
            elseif score == bestScore then
                -- Same score? Pick by distance if exact, else keep current
                if step.mapID == currentMapID then
                    -- Lazy calculate previous best distance
                    if not minDistSq then
                        local prevStep = route[bestIdx]
                        if prevStep and prevStep.mapID == currentMapID then
                            if not posFetched then pos = ADW.GetPlayerMapPosition(currentMapID, "player"); posFetched = true end
                            if pos then
                                local bdx = (pos.x - prevStep.x) * 1000
                                local bdy = (pos.y - prevStep.y) * 1000
                                minDistSq = bdx*bdx + bdy*bdy
                            else
                                minDistSq = math.huge
                            end
                        else
                            minDistSq = math.huge
                        end
                    end

                    if not posFetched then pos = ADW.GetPlayerMapPosition(currentMapID, "player"); posFetched = true end
                    if pos then
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
    end
    
    return bestIdx, pos, posFetched
end

local function SyncRouteProgress(isZoneTransition)
    if not activeRoute then return end
    local best = ADW.GetBestStepIndex(activeRoute)
    if best ~= currentStepIndex then
        -- Respect forward-skip immunity: don't jump forward past portal steps
        if not isZoneTransition and best > currentStepIndex and GetTime() - lastStepAdvance < 8 then
            DebugPrint("DEBUG: SyncRouteProgress forward-skip blocked by immunity.")
            -- Still re-apply the current waypoint so the marker stays visible
            SetWaypointStep(currentStepIndex)
            return
        end
        currentStepIndex = best
        SetWaypointStep(currentStepIndex)
    end
end

function ClearRoute()
    DebugPrint("DEBUG: ClearRoute called (Active:" .. tostring(activeRouteKey) .. ")")
    C_Map.ClearUserWaypoint()
    if checkTicker then checkTicker:Cancel() checkTicker = nil end
    if tomtomUID and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomUID) end
    tomtomUID = nil
    activeRoute = nil
    activeRouteKey = nil
    currentStepIndex = 0
    totalSteps = 0
    lastStepAdvance = 0
    lastMapChangeTime = 0
    lastPlayerX = nil
    lastPlayerY = nil
    
    if not InCombatLockdown() then
        portalBtn:SetAttribute("macrotext", nil)
        portalBtn:Hide()
    end
    
    HidePortalMap()
    HideStatusFrame()
    UpdateToggleButton()
end

function GetKnownPortal(route)
    if not route then return nil, nil end
    
    -- Try by ID first
    if route.portalID then
        local id = route.portalID
        local known = C_Spell.IsSpellKnown(id)
        
        if known then
            local name = C_Spell.GetSpellName(id)
            return id, name
        end
    end
    
    -- Try by names/variations
    if route.portalName then
        local variations = type(route.portalName) == "table" and route.portalName or { route.portalName }
        for _, name in ipairs(variations) do
            local sID = C_Spell.GetSpellIDForSpellIdentifier(name)
            
            if sID then
                local known = C_Spell.IsSpellKnown(sID)
                
                if known then
                    local realName = C_Spell.GetSpellName(sID) or name
                    return sID, realName
                end
            end
        end
    end
    return nil, nil
end

local function CompleteRoute()
    Print(GREEN .. (ADW.L["ARRIVED"] or "You have arrived! Route complete.") .. "|r")
    LogInfo("Route complete: " .. tostring(activeRouteKey))
    if AutoDungeonWaypointDB and AutoDungeonWaypointDB.EnableSounds ~= false then
        PlaySound(878)
    end
    ClearRoute()
end

function SetWaypointStep(index)
    if not activeRoute or not activeRoute[index] then
        CompleteRoute()
        return
    end
    local step = activeRoute[index]
    -- Cache UiMapPoint so it isn't repeatedly allocated during the ticker
    step.uiMapPoint = step.uiMapPoint or UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
    C_Map.SetUserWaypoint(step.uiMapPoint)
    
    -- Verify and Force SuperTrack
    if C_Map.HasUserWaypoint() then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        DebugPrint("DEBUG: SetUserWaypoint map=" .. step.mapID .. " [SUCCESS]")
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
    local isPortal = false
    if nextStep and nextStep.mapID ~= step.mapID then
        desc = "|cFF00FFFF[PORTAL]|r " .. desc
        isPortal = true
    end
    
    Print(YELLOW .. (string.format(ADW.L["STEP_X_Y"] or "Step %d/%d:", index, totalSteps)) .. "|r " .. WHITE .. desc .. "|r")
    LogInfo(string.format("ADVANCE: Step %d/%d (%s)", index, totalSteps, desc))
    UpdateStatusFrame(dungeonName, desc, index, totalSteps, isPortal)
    if index > 1 and AutoDungeonWaypointDB and AutoDungeonWaypointDB.EnableSounds ~= false then
        PlaySound(850)
    end

    -- Show/hide Timeways portal map
    if step.mapID == ADW.TIMEWAYS_MAP_ID and activeRouteKey then
        ShowPortalMap(activeRouteKey)
    else
        HidePortalMap()
    end
end

local function ReApplyWaypointIfMissing()
    if not activeRoute or not activeRoute[currentStepIndex] then return end
    local step = activeRoute[currentStepIndex]
    
    local hasWaypoint = C_Map.HasUserWaypoint()
    if not hasWaypoint then
        step.uiMapPoint = step.uiMapPoint or UiMapPoint.CreateFromCoordinates(step.mapID, step.x, step.y)
        C_Map.SetUserWaypoint(step.uiMapPoint)
        hasWaypoint = C_Map.HasUserWaypoint()
        if hasWaypoint then
            LogInfo("Waypoint enforced automatically")
        else
            LogError("Failed to re-apply waypoint for map " .. tostring(step.mapID))
        end
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

    -- Early return if player is completely stationary to avoid redundant table allocs and GC stutters
    local currentY, currentX = UnitPosition("player")
    if currentMapID == lastMapID and currentX == lastPlayerX and currentY == lastPlayerY then
        return
    end
    lastPlayerX = currentX
    lastPlayerY = currentY

    -- Update map change buffer
    if currentMapID ~= lastMapID then
        lastMapID = currentMapID
        lastMapChangeTime = now
        DebugPrint("DEBUG: Map change detected. Buffer active.")
    end

    DebugPrint(string.format("DEBUG: Map: %d | Step: %d", currentMapID, currentStepIndex))
    
    local bestIdx, pos, posFetched = ADW.GetBestStepIndex(activeRoute, currentMapID, nil)
    
    -- 1. Handle Forward Progress (Skipping steps via SmartSync)
    if bestIdx > currentStepIndex then
        -- Forward-skip immunity: Don't allow SmartSync to jump forward within 8s of a step advance.
        if now - lastStepAdvance < 8 then
            DebugPrint("DEBUG: Forward-skip immunity active (" .. bestIdx .. " blocked).")
        else
            LogInfo(string.format("SmartSync: SKIP FORWARD from %d to %d (Map: %d)", currentStepIndex, bestIdx, currentMapID))
            currentStepIndex = bestIdx
            SetWaypointStep(currentStepIndex)
        end
        return
    end

    -- 2. Handle Snap-back (Player moved back to a previous map/zone)
    if bestIdx < currentStepIndex then
        -- Snap-back immunity: Don't snap back for 5s after an advance.
        if now - lastStepAdvance < 5 then
            DebugPrint("DEBUG: Snap-back immunity active.")
            return
        end

        local isPriorMap = false
        for i = 1, currentStepIndex - 1 do
            if activeRoute[i].mapID == currentMapID then isPriorMap = true break end
        end

        if isPriorMap then
            -- Buffer: If we are still very close to the previous step's location, stay on the current step.
            local priorStep = activeRoute[currentStepIndex - 1]
            if priorStep and priorStep.mapID == currentMapID then
                if not posFetched then pos = ADW.GetPlayerMapPosition(currentMapID, "player"); posFetched = true end
                if pos then
                    local dx = (pos.x - priorStep.x) * 1000
                    local dy = (pos.y - priorStep.y) * 1000
                    if (dx*dx + dy*dy) < 400.0 then -- ~100 yards buffer
                        DebugPrint("DEBUG: Near Step " .. (currentStepIndex-1) .. " - ignoring snap-back.")
                        return
                    end
                end
            end

            LogInfo(string.format("SmartSync: SNAP BACK from %d to %d (Map: %d)", currentStepIndex, bestIdx, currentMapID))
            currentStepIndex = bestIdx
            SetWaypointStep(currentStepIndex)
            return
        end
    end

    -- 3. Handle Arrival (Current step target reached)
    if currentMapID == step.mapID then
        -- Arrival Buffer: If we just changed maps, wait 3s before allowing arrival.
        -- Optimization: Check this BEFORE fetching map position to avoid unnecessary table allocations.
        if now - lastMapChangeTime < 3 then
            -- Note: Removed debug print here to prevent 4Hz spam during the 3-second buffer.
            return
        end

        if not posFetched then pos = ADW.GetPlayerMapPosition(currentMapID, "player"); posFetched = true end
        if pos then
            local dx = (pos.x - step.x) * 1000
            local dy = (pos.y - step.y) * 1000
            local distSq = dx * dx + dy * dy

            if distSq < 10.0 then -- Threshold for "arrival"
                LogInfo(string.format("ARRIVAL: Step %d reached (DistSq: %.2f)", currentStepIndex, distSq))
                if currentStepIndex < totalSteps then
                    currentStepIndex = currentStepIndex + 1
                    lastStepAdvance = now
                    SetWaypointStep(currentStepIndex)
                    UpdateToggleButton()
                    PulseGlow()
                else
                    CompleteRoute()
                end
            end
        end
    end
end

function StartRoute(routeKey, skipBroadcast)
    if not routeKey then return end
    if activeRouteKey == routeKey then 
        DebugPrint("DEBUG: StartRoute called for already active route " .. routeKey .. " - skipping.")
        return 
    end
    
    local route = ADW.Routes[routeKey]
    if not route then
        -- Sentinel: Prevent UI injection via malicious routeKey strings (e.g. from chat)
        local safeKey = tostring(routeKey):gsub("|", "||")
        Print(RED .. (ADW.L["NO_ROUTE_FOUND"] or "No route found for:|r ") .. safeKey)
        return
    end

    -- Synchronous State Purge
    DebugPrint("DEBUG: Atomic switch to " .. routeKey)
    C_Map.ClearUserWaypoint()
    if checkTicker then checkTicker:Cancel() end
    if tomtomUID and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(tomtomUID) end
    
    -- Atomic State Setup
    activeRoute = route
    activeRouteKey = routeKey
    totalSteps = #route
    currentStepIndex = ADW.GetBestStepIndex(route)
    lastStepAdvance = GetTime()
    lastMapChangeTime = 0
    lastPlayerX = nil
    lastPlayerY = nil
    
    local dungeonName = ADW.RouteNames[routeKey] or routeKey
    local msg = GREEN .. string.format(ADW.L["STARTING_ROUTE"] or "Starting route to %s (%d steps)", dungeonName, totalSteps) .. "|r"
    if currentStepIndex > 1 then msg = msg .. GRAY .. string.format(ADW.L["SYNCED_STEP"] or " — sync'd to step %d", currentStepIndex) .. "|r" end
    Print(msg)
    
    if AutoDungeonWaypointDB and AutoDungeonWaypointDB.EnableSounds ~= false then
        PlaySound(846)
    end
    
    -- Portal Detection
    local pID, pName = GetKnownPortal(route)
    if pID and pName then
        if not InCombatLockdown() then
            portalBtn:SetAttribute("macrotext", "/cast " .. pName)
            local spellData = C_Spell.GetSpellInfo(pID)
            local sIcon = spellData and spellData.iconID
            if sIcon then portalBtn.Icon:SetTexture(sIcon) end
            UIFrameFadeIn(portalBtn, 0.4, 0, 1)
            portalBtn:Show()
        end
        Print(CYAN .. (ADW.L["SHORTCUT"] or "[Shortcut]") .. "|r " .. WHITE .. (ADW.L["PORTAL_DETECTED"] or "Dungeon portal detected. Click the icon on your HUD to use it!") .. "|r")
    else
        if not InCombatLockdown() then
            portalBtn:SetAttribute("macrotext", nil)
            portalBtn:Hide()
        end
    end
    
    SetWaypointStep(currentStepIndex)
    UpdateToggleButton()
    
    checkTicker = C_Timer.NewTicker(0.25, CheckDistance)
    
    if IsInGroup() and not skipBroadcast then
        local channel = IsInRaid() and "RAID" or "PARTY"
        C_ChatInfo.SendAddonMessage("ADW", "ROUTE:" .. routeKey, channel)
    end
end

function ADW.ToggleAutoRoute(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then db.AutoRouteEnabled = not db.AutoRouteEnabled else db.AutoRouteEnabled = enabled end
    UpdateToggleButton()
    if db.AutoRouteEnabled then Print((ADW.L["AUTO_ROUTING"] or "Auto-Routing ") .. GREEN .. (ADW.L["ENABLED"] or "enabled") .. "|r.")
    else Print((ADW.L["AUTO_ROUTING"] or "Auto-Routing ") .. RED .. (ADW.L["DISABLED"] or "disabled") .. "|r.") ClearRoute() end
end

-- ============================================================================
-- Options, Menus, Slash
-- ============================================================================
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "ADWOptionsPanel", UIParent)
    panel.name = "Auto Dungeon Waypoint"
    
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16) 
    title:SetText(ADW.L["SETTINGS_TITLE"] or "Auto Dungeon Waypoint Settings")
    
    local autoCheck = ADW.CreateConfigCheckbox(panel, ADW.L["ENABLE_AUTO_ROUTING"] or "Enable Auto-Routing", "AutoRouteEnabled",
        ADW.L["AUTO_ROUTING"] or "Auto-Routing", ADW.L["ENABLE_AUTO_ROUTING_DESC"] or "Automatically detects when you join a Mythic+ group and starts the route.", function(val) ADW.ToggleAutoRoute(val) end)
    autoCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

    local hudCheck = ADW.CreateConfigCheckbox(panel, ADW.L["SHOW_HUD"] or "Show Navigation HUD", "ShowStatusFrame",
        ADW.L["HUD_TITLE"] or "Auto Dungeon Waypoint", ADW.L["SHOW_HUD_DESC"] or "Displays a floating window with the current step's instructions.", function(val)
            if val then UpdateStatusFrame(ADW.L["HUD_PREVIEW"] or "HUD Preview", ADW.L["HUD_PREVIEW_DESC"] or "This is how the HUD looks.", 1, 5) statusFrame:Show() statusFrame:SetAlpha(1)
            else HideStatusFrame() end
        end)
    hudCheck:SetPoint("TOPLEFT", autoCheck, "BOTTOMLEFT", 0, -8)

    local compactCheck = ADW.CreateConfigCheckbox(panel, ADW.L["COMPACT_HUD"] or "Compact HUD", "CompactMode",
        ADW.L["COMPACT_HUD"] or "Compact HUD", ADW.L["COMPACT_HUD_DESC"] or "Hides the instructional text to save screen space.", function()
            if AutoDungeonWaypointDB.ShowStatusFrame then UpdateStatusFrame(ADW.L["HUD_PREVIEW"] or "HUD Preview", ADW.L["HUD_PREVIEW_DESC"] or "This is how the HUD looks.", 1, 5) end
        end)
    compactCheck:SetPoint("TOPLEFT", hudCheck, "BOTTOMLEFT", 20, -4)

    hudCheck:HookScript("OnClick", function(self)
        local isEnabled = self:GetChecked()
        compactCheck:SetEnabled(isEnabled)
        if isEnabled then compactCheck:SetAlpha(1) else compactCheck:SetAlpha(0.5) end
    end)
    compactCheck:HookScript("OnShow", function(self)
        local isEnabled = AutoDungeonWaypointDB.ShowStatusFrame ~= false
        self:SetEnabled(isEnabled)
        if isEnabled then self:SetAlpha(1) else self:SetAlpha(0.5) end
    end)

    local controlBarCheck = ADW.CreateConfigCheckbox(panel, ADW.L["SHOW_CONTROL_BAR"] or "Show Control Bar", "ShowControlBar",
        ADW.L["SHOW_CONTROL_BAR"] or "Show Control Bar", ADW.L["SHOW_CONTROL_BAR_DESC"] or "Shows the movable bar with Auto-Routing toggle and List buttons.", function(val)
            if val then controlBar:Show() else controlBar:Hide() end
        end)
    controlBarCheck:SetPoint("TOPLEFT", compactCheck, "BOTTOMLEFT", -20, -8)

    local chatCheck = ADW.CreateConfigCheckbox(panel, ADW.L["ENABLE_CHAT"] or "Enable Chat Announcements", "ShowChatText",
        ADW.L["ENABLE_CHAT"] or "Enable Chat Announcements", ADW.L["ENABLE_CHAT_DESC"] or "Shows text in your chat box when a route starts or a step advances.",
        function(val) if val then DEFAULT_CHAT_FRAME:AddMessage(ADDON_COLOR .. (ADW.L["HUD_TITLE"] or "[Auto Dungeon Waypoint]") .. "|r " .. (ADW.L["CHAT_ENABLED_MSG"] or "Chat announcements enabled.")) end end)
    chatCheck:SetPoint("TOPLEFT", controlBarCheck, "BOTTOMLEFT", 0, -8)

    local soundCheck = ADW.CreateConfigCheckbox(panel, ADW.L["ENABLE_SOUND"] or "Enable Sound Effects", "EnableSounds",
        ADW.L["ENABLE_SOUND"] or "Enable Sound Effects", ADW.L["ENABLE_SOUND_DESC"] or "Plays a sound when a route starts, a step advances, or you arrive at your destination.",
        function(val) if val then PlaySound(846) end end)
    soundCheck:SetPoint("TOPLEFT", chatCheck, "BOTTOMLEFT", 0, -8)

    local resetBtn = CreateFrame("Button", "ADWResetBtn", panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 26) 
    resetBtn:SetPoint("TOPLEFT", soundCheck, "BOTTOMLEFT", 0, -20)
    resetBtn:SetText(ADW.L["RESET_POSITIONS"] or "Reset Positions")
    resetBtn:SetScript("OnClick", function()
        AutoDungeonWaypointDB.StatusFramePos = nil AutoDungeonWaypointDB.ToggleButtonPos = nil
        statusFrame:ClearAllPoints() statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
        controlBar:ClearAllPoints() controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
        ForcePrint(ADW.L["POSITIONS_RESET_MSG"] or "HUD and Control Bar positions have been reset.")
    end)
    ADW.SetTooltip(resetBtn, ADW.L["RESET_POSITIONS"] or "Reset Positions", ADW.L["RESET_POSITIONS_DESC"] or "Restores the Navigation HUD and Control Bar to their default positions.")
    
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ADW.settingsCategory = category
    else InterfaceOptions_AddCategory(panel) end
end

autoBtn:SetScript("OnClick", function() ADW.ToggleAutoRoute() end)
menuBtn:SetScript("OnClick", function(self)
    if MenuUtil then MenuUtil.CreateContextMenu(self, ADW.GenerateDungeonMenu) end
end)

SLASH_AUTODUNGEONWAYPOINT1 = "/adw"
SLASH_AUTODUNGEONWAYPOINT2 = "/autodungeonwaypoint"
SlashCmdList["AUTODUNGEONWAYPOINT"] = function(msg)
    local cmd, arg = strsplit(" ", (msg or ""):lower(), 2)
    if cmd == "route" and arg then StartRoute(arg)
    elseif cmd == "stop" then ClearRoute() ForcePrint(ADW.L["ROUTE_CANCELLED"] or "Route cancelled.")
    elseif cmd == "toggle" then ADW.ToggleAutoRoute()
    elseif cmd == "hide" then
        if AutoDungeonWaypointDB then
            AutoDungeonWaypointDB.ShowStatusFrame = false
            AutoDungeonWaypointDB.ShowControlBar = false
            AutoDungeonWaypointDB.ShowChatText = false
            HideStatusFrame()
            controlBar:Hide()
            local hudCheck  = _G["ADW_ShowStatusFrame_Check"]
            local barCheck  = _G["ADW_ShowControlBar_Check"]
            local chatCheck = _G["ADW_ShowChatText_Check"]
            if hudCheck  then hudCheck:SetChecked(false)  end
            if barCheck  then barCheck:SetChecked(false)  end
            if chatCheck then chatCheck:SetChecked(false) end
            ForcePrint(ADW.L["HUD_BAR_CHAT_HIDDEN"] or "HUD, Control Bar, and Chat Text hidden.")
        end
    elseif cmd == "list" then
        ForcePrint(ADW.L["AVAILABLE_ROUTES"] or "Available routes:")
        for key, name in pairs(ADW.RouteNames) do
            local steps = ADW.Routes[key] and #ADW.Routes[key] or 0
            ForcePrint("  " .. YELLOW .. key .. "|r — " .. WHITE .. name .. "|r " .. GRAY .. "(" .. steps .. " steps)|r")
        end
    elseif cmd == "nearest" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if not currentMapID then return end
        local pos = ADW.GetPlayerMapPosition(currentMapID, "player")
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
        if bestKey then StartRoute(bestKey) else ForcePrint(RED .. (ADW.L["NO_NEARBY_DUNGEONS"] or "No nearby dungeon routes found.") .. "|r") end
    elseif cmd == "move" then
        if statusFrame:IsShown() then
            HideStatusFrame()
            ForcePrint(ADW.L["HUD_HIDDEN_MSG"] or "HUD hidden.")
        else
            UpdateStatusFrame(ADW.L["HUD_POSITIONING"] or "HUD Positioning", ADW.L["HUD_MOVE_DESC"] or "Hold SHIFT and drag to move this frame. Type /adw move again to hide.", 1, 1)
            statusFrame:Show()
            statusFrame:SetAlpha(1)
            ForcePrint(ADW.L["HUD_SHOWN_POS"] or "HUD shown for positioning.")
        end
    elseif cmd == "debug" then
        debugMode = not debugMode
        ForcePrint((ADW.L["DEBUG_MODE"] or "Debug mode ") .. (debugMode and GREEN .. (ADW.L["ENABLED"] or "enabled") .. "|r" or RED .. (ADW.L["DISABLED"] or "disabled") .. "|r"))
    elseif cmd == "mapid" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        local info = C_Map.GetMapInfo(currentMapID)
        ForcePrint(string.format(ADW.L["CURRENT_MAP_ID"] or "Current Map ID: %s (%s)", (currentMapID or "nil"), (info and info.name or (ADW.L["UNKNOWN"] or "Unknown"))))
        if info and info.parentMapID then
            local pInfo = C_Map.GetMapInfo(info.parentMapID)
            ForcePrint(string.format(ADW.L["PARENT_MAP_ID"] or "Parent Map ID: %d (%s)", info.parentMapID, (pInfo and pInfo.name or (ADW.L["UNKNOWN"] or "Unknown"))))
        end
    elseif cmd == "pos" then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        if currentMapID then
            local pos = ADW.GetPlayerMapPosition(currentMapID, "player")
            if pos then
                ForcePrint(string.format(ADW.L["POSITION_FORMAT"] or "Position: mapID=%d  x=%.4f  y=%.4f", currentMapID, pos.x, pos.y))
            else
                ForcePrint(RED .. (ADW.L["NO_POS_MAP"] or "Cannot get position on this map.") .. "|r")
            end
        else
            ForcePrint(RED .. (ADW.L["NO_MAP_DETECTED"] or "No map detected.") .. "|r")
        end
    elseif cmd == "portal" then
        if not activeRoute then ForcePrint(RED .. (ADW.L["NO_ACTIVE_ROUTE"] or "No active route.") .. "|r") return end
        
        ForcePrint(string.format(ADW.L["DIAGNOSTIC_FOR"] or "Diagnostic for: %s", YELLOW .. (ADW.RouteNames[activeRouteKey] or activeRouteKey) .. "|r"))
        
        local checkIDs = {}
        if activeRoute.portalID then table.insert(checkIDs, activeRoute.portalID) end
        
        local checkNames = {}
        if activeRoute.portalName then
            if type(activeRoute.portalName) == "table" then
                for _, n in ipairs(activeRoute.portalName) do table.insert(checkNames, n) end
            else
                table.insert(checkNames, activeRoute.portalName)
            end
        end

        if #checkIDs == 0 and #checkNames == 0 then
            ForcePrint(RED .. (ADW.L["NO_PORTAL_DATA"] or "This route has no portal data assigned.") .. "|r")
            return
        end

        for _, id in ipairs(checkIDs) do
            local name = C_Spell.GetSpellName(id) or "ID:"..id
            local isKnown = C_Spell.IsSpellKnown(id)
            ForcePrint(string.format("  - ID %d (%s): %s", id, name, (isKnown and GREEN .. (ADW.L["KNOWN"] or "KNOWN") or RED .. (ADW.L["UNKNOWN"] or "UNKNOWN"))))
        end

        for _, n in ipairs(checkNames) do
            local sID = C_Spell.GetSpellIDForSpellIdentifier(n)
            local isKnown = false
            if sID then
                isKnown = C_Spell.IsSpellKnown(sID)
            end
            ForcePrint(string.format("  - Name '%s': %s", n, (sID and (isKnown and GREEN .. string.format(ADW.L["KNOWN_WITH_ID"] or "KNOWN (%s)", sID) or YELLOW .. string.format(ADW.L["FOUND_NOT_KNOWN"] or "FOUND (%s) BUT NOT KNOWN", sID)) or RED .. (ADW.L["NOT_FOUND"] or "NOT FOUND"))))
        end

        ForcePrint("  - " .. (ADW.L["VISIBLE"] or "Button Visible") .. ": " .. (portalBtn:IsShown() and GREEN .. (ADW.L["VISIBLE"] or "YES") or RED .. (ADW.L["HIDDEN"] or "NO")))
        ForcePrint("  - " .. (ADW.L["COMBAT_LOCKDOWN"] or "Combat Lockdown") .. ": " .. (InCombatLockdown() and RED .. (ADW.L["VISIBLE"] or "YES") or GREEN .. (ADW.L["HIDDEN"] or "NO")))
        ForcePrint("  - " .. (ADW.L["SECURE_MACRO"] or "Secure Macro") .. ": " .. tostring(portalBtn:GetAttribute("macrotext") or "nil"))
        
        local p, r, rp, x, y = portalBtn:GetPoint()
        ForcePrint(string.format(ADW.L["POSITIONING"] or "  - Positioning: %s to %s offset (%.1f, %.1f)", p or "nil", rp or "nil", x or 0, y or 0))
    else
        ForcePrint(ADW.L["HELP_COMMANDS"] or "Commands: /adw route <id>, /adw list, /adw stop, /adw nearest, /adw portal, /adw debug, /adw move, /adw mapid, /adw pos")
    end
end

function ADW_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        ADW.ToggleAutoRoute()
    elseif buttonName == "MiddleButton" then
        if activeRoute then
            ADW_Stop_Binding()
        end
    elseif MenuUtil then
        MenuUtil.CreateContextMenu(MinimapCluster or UIParent, ADW.GenerateDungeonMenu)
    else
        ForcePrint(ADW.L["COMPARTMENT_UNAVAILABLE"] or "Addon compartment menu is unavailable. Type /adw list instead.")
    end
end

function ADW_OnAddonCompartmentEnter(_, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, button)
    local stateText = AutoDungeonWaypointDB.AutoRouteEnabled and "|cFF55FF55[ON]|r" or "|cFFFF5555[OFF]|r"
    GameTooltip:SetText("Auto Dungeon Waypoint " .. stateText, 0.0, 0.75, 1.0)
    if activeRoute then
        GameTooltip:AddLine("Active: " .. (ADW.RouteNames[activeRouteKey] or activeRouteKey))
    end
    GameTooltip:AddLine(" ")
    AddSharedTooltipLines(GameTooltip)
    if activeRoute then
        GameTooltip:AddLine(ADW.L["MIDDLE_CLICK_CANCEL"] or "|cFFFFD100Middle-Click:|r Cancel route", 1, 1, 1)
    end
    GameTooltip:Show()
end

function ADW_OnAddonCompartmentLeave(_, button)
    GameTooltip_Hide()
end

-- ============================================================================
-- LFG Processor
-- ============================================================================
ADW.LFGRouteCache = {}  -- runtime name-fuzzy-match cache (never mutates the static LFGToRoute table)

function ADW.ProcessActivityID(activityID, isSilent)
    if not activityID then return end

    if isPlayerInInstance then
        return
    end

    -- Check static lookup first, then the runtime fuzzy-match cache
    local routeKey = ADW.LFGToRoute[activityID]
    if routeKey == nil then
        routeKey = ADW.LFGRouteCache[activityID]
    end

    -- If we've already determined this ID has no matching route, skip
    if routeKey == false then return end

    if routeKey == nil then
        local info = C_LFGList.GetActivityInfoTable(activityID)
        if info and info.fullName then
            DebugLog("ProcessActivityID: Name=" .. info.fullName)
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
        -- Cache result without mutating the static LFGToRoute data table
        ADW.LFGRouteCache[activityID] = routeKey or false
    end

    if not routeKey or activeRouteKey == routeKey then return end

    DebugLog("ProcessActivityID: ID=" .. tostring(activityID) .. " Key=" .. tostring(routeKey))

    local name = ADW.RouteNames[routeKey] or routeKey
    if not isSilent then Print(GREEN .. (ADW.L["DUNGEON_DETECTED"] or "Dungeon detected: ") .. "|r " .. WHITE .. name .. "|r " .. (ADW.L["AUTO_STARTING"] or "— auto-starting!")) end
    StartRoute(routeKey)
end

local function CheckInitialActivities(isSilent)
    if not AutoDungeonWaypointDB or not AutoDungeonWaypointDB.AutoRouteEnabled or isPlayerInInstance then return end

    -- Performance Optimization: Check boolean HasActiveEntryInfo before GetActiveEntryInfo
    -- to prevent redundant table allocations when no entry exists.
    if not C_LFGList.HasActiveEntryInfo() then return end
    local activeEntry = C_LFGList.GetActiveEntryInfo()
    if activeEntry and activeEntry.activityIDs then
        for _, id in ipairs(activeEntry.activityIDs) do
            ADW.ProcessActivityID(id, isSilent)
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
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix("ADW")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
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
        if AutoDungeonWaypointDB.ShowControlBar == false then
            controlBar:Hide()
        else
            controlBar:Show()
        end
        UpdateToggleButton() CreateOptionsPanel()
        
        -- Check if we are already in a group with an active activity on load
        CheckInitialActivities(true)

        local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
        local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
        if LDB and LDBIcon then
            local adwBroker = LDB:NewDataObject("AutoDungeonWaypoint", {
                type = "launcher", text = "Auto Dungeon Waypoint", icon = "Interface\\AddOns\\AutoDungeonWaypoint\\icon.tga",
                OnClick = function(self, button)
                    if button == "LeftButton" then
                        if MenuUtil then MenuUtil.CreateContextMenu(self, ADW.GenerateDungeonMenu) end
                    elseif button == "RightButton" then ADW.ToggleAutoRoute()
                    elseif button == "MiddleButton" then ADW_Stop_Binding() end
                end,
                OnTooltipShow = function(tooltip)
                    local stateText = AutoDungeonWaypointDB.AutoRouteEnabled and "|cFF55FF55[ON]|r" or "|cFFFF5555[OFF]|r"
                    tooltip:SetText((ADW.L["HUD_TITLE"] or "Auto Dungeon Waypoint") .. " " .. stateText, 0.0, 0.75, 1.0)
                    if activeRoute then tooltip:AddLine((ADW.L["ACTIVE_ROUTE"] or "Active: ") .. (ADW.RouteNames[activeRouteKey] or activeRouteKey)) end
                    tooltip:AddLine(" ")
                    AddSharedTooltipLines(tooltip)
                    if activeRoute then tooltip:AddLine(ADW.L["MIDDLE_CLICK_CANCEL"] or "|cFFFFD100Middle-Click:|r Cancel route", 1, 1, 1) end
                end,
            })
            LDBIcon:Register("AutoDungeonWaypoint", adwBroker, AutoDungeonWaypointDB.MinimapIcon)
        end
        self:UnregisterEvent("ADDON_LOADED") return
    end
    if event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        local _, instanceType = IsInInstance()
        isPlayerInInstance = (instanceType == "party" or instanceType == "raid")

        if isLogin or isReload then
            Print(ADW.L["LOADED_MSG"] or "Loaded — Type /adw list to see routes.")
        else
            if isPlayerInInstance and activeRoute then
                Print(GREEN .. (ADW.L["ENTERED_DUNGEON"] or "Entered dungeon! Route cleared.") .. "|r") ClearRoute()
            elseif activeRoute then
                -- After a zone transition, re-sync position instead of blindly re-setting
                SyncRouteProgress(true)
            end
        end
        return
    end
    if event == "LFG_LIST_JOINED_GROUP" then
        local searchResultID = ...
        if searchResultID and AutoDungeonWaypointDB.AutoRouteEnabled and not isPlayerInInstance then
            local info = C_LFGList.GetSearchResultInfo(searchResultID)
            if info and info.activityID then ADW.ProcessActivityID(info.activityID) end
        end
        return
    end
    if event == "LFG_LIST_ACTIVE_ENTRY_UPDATE" then
        if AutoDungeonWaypointDB.AutoRouteEnabled and not isPlayerInInstance then
            -- Performance Optimization: Check boolean HasActiveEntryInfo before GetActiveEntryInfo
            -- to prevent redundant table allocations and GC stutters on high-frequency events.
            if C_LFGList.HasActiveEntryInfo() then
                local activeEntry = C_LFGList.GetActiveEntryInfo()
                if activeEntry and activeEntry.activityIDs then
                    for _, id in ipairs(activeEntry.activityIDs) do
                        ADW.ProcessActivityID(id)
                    end
                end
            end
        end
        return
    end
    if event == "ZONE_CHANGED_NEW_AREA" then if activeRoute then SyncRouteProgress(false) end return end
    if event == "PLAYER_REGEN_ENABLED" then
        if activeRoute and activeRouteKey then
            local currentStep = activeRoute[currentStepIndex]
            if currentStep then
                local dungeonName = ADW.RouteNames[activeRouteKey] or activeRouteKey
                local isPortal = false
                local nextStep = activeRoute[currentStepIndex + 1]
                if nextStep and nextStep.mapID ~= currentStep.mapID then isPortal = true end
                UpdateStatusFrame(dungeonName, currentStep.desc, currentStepIndex, totalSteps, isPortal)
            end
        end
        return
    end
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix ~= "ADW" or not AutoDungeonWaypointDB.AutoRouteEnabled then return end

        -- Trusted channels only to prevent unauthenticated route hijacking via WHISPER/SAY/etc.
        if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "GUILD" then return end
        
        -- Midnight Resilience: Robust self-filter using UnitIsUnit (handles cross-realm name nuances)
        if UnitIsUnit(sender, "player") then return end
        
        local safeSender = Ambiguate(sender, "none")
        local cmd, routeKey = strsplit(":", message, 2)
        if cmd == "ROUTE" and routeKey and ADW.Routes[routeKey] and activeRouteKey ~= routeKey then
            -- Sentinel: Prevent DoS via popup spam (rate limit: 1 request per 10s per sender)
            ADW.PopupRateLimits = ADW.PopupRateLimits or {}
            local now = GetTime()
            if ADW.PopupRateLimits[safeSender] and (now - ADW.PopupRateLimits[safeSender]) < 10 then
                return
            end
            ADW.PopupRateLimits[safeSender] = now

            local dungeonName = ADW.RouteNames[routeKey] or routeKey
            StaticPopup_Show("ADW_CONFIRM_ROUTE", CYAN .. safeSender .. "|r", WHITE .. dungeonName .. "|r", { routeKey = routeKey })
        end
    end
end)
