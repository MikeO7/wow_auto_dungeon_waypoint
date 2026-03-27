local _, ADW = ...

-- ============================================================================
-- UI Constants
-- ============================================================================
local ADDON_COLOR = "|cFF00BFFF"
local GREEN       = "|cFF00FF00"
local RED         = "|cFFFF4444"

-- ============================================================================
-- Status Frame (HUD)
-- ============================================================================
local statusFrame = CreateFrame("Frame", "ADWStatusFrame", UIParent)
statusFrame:SetSize(300, 70)
statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
statusFrame:SetMovable(true)
statusFrame:EnableMouse(true)
statusFrame:RegisterForDrag("LeftButton")
statusFrame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then self:StartMoving() end
end)
statusFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if AutoDungeonWaypointDB then
        AutoDungeonWaypointDB.StatusFramePos = { point, relPoint, x, y }
    end
end)

-- Background
local bg = statusFrame:CreateTexture(nil, "BACKGROUND")
bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
bg:SetAllPoints()
bg:SetVertexColor(0.02, 0.02, 0.05, 0.9)

-- Glass overlay
local glass = statusFrame:CreateTexture(nil, "BORDER")
glass:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
glass:SetAllPoints()
glass:SetAlpha(0.05)
glass:SetBlendMode("ADD")

-- Border
local border = statusFrame:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Common\\WhiteSecondary-1x1")
border:SetPoint("TOPLEFT")
border:SetPoint("BOTTOMRIGHT")
border:SetAlpha(0.2)
statusFrame.Border = border

-- Glow effect
local glow = statusFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
glow:SetBlendMode("ADD")
glow:SetPoint("TOPLEFT", -15, 15)
glow:SetPoint("BOTTOMRIGHT", 15, -15)
glow:SetVertexColor(0, 0.6, 1, 0.5)
glow:SetAlpha(0)
statusFrame.Glow = glow

--- Flash the glow effect around the HUD (used on step advancement).
function ADW.PulseGlow()
    UIFrameFadeIn(glow, 0.15, 0, 0.6)
    C_Timer.After(0.2, function() UIFrameFadeOut(glow, 0.4, 0.6, 0) end)
end

-- Step icon
local stepIcon = statusFrame:CreateTexture(nil, "OVERLAY")
stepIcon:SetSize(32, 32)
stepIcon:SetPoint("LEFT", statusFrame, "LEFT", 30, 0)
stepIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")

-- Title text
local titleText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
titleText:SetPoint("TOPLEFT", stepIcon, "TOPRIGHT", 12, -4)
titleText:SetTextColor(0.0, 0.9, 1.0)
titleText:SetText("Auto Dungeon Waypoint")

-- Step description text
local stepText = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
stepText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
stepText:SetPoint("RIGHT", statusFrame, "RIGHT", -10, 0)
stepText:SetJustifyH("LEFT")
stepText:SetWordWrap(true)
stepText:SetText("")
statusFrame:Hide()

-- Tooltip
statusFrame:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetText("Navigation HUD", 0.0, 0.75, 1.0)
    if ADW.HasActiveRoute() then
        local db = AutoDungeonWaypointDB
        if db and db.CompactMode then
            local desc = ADW.GetCurrentStepDesc()
            if desc then
                GameTooltip:AddLine("|cFFFFD100Current Step:|r " .. desc, 1, 1, 1, true)
            end
        end
        GameTooltip:AddLine("|cFFFFD100Right-Click:|r Cancel route", 1, 1, 1, true)
    end
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
statusFrame:SetScript("OnLeave", GameTooltip_Hide)

statusFrame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" and ADW.HasActiveRoute() then
        ADW.StopRoute()
    end
end)

-- ============================================================================
-- Status Frame API
-- ============================================================================
local pendingHideTimer = nil

--- Show the status frame immediately, cancelling any pending hide and fade animation.
function ADW.ShowStatusFrame()
    if pendingHideTimer then pendingHideTimer:Cancel() pendingHideTimer = nil end
    -- Stop any ongoing UIFrameFadeOut animation that would override our alpha
    if UIFrameFadeRemoveFrame then
        UIFrameFadeRemoveFrame(statusFrame)
    end
    statusFrame:Show()
    statusFrame:SetAlpha(1)
end

--- Update the HUD with current navigation info. Respects ShowStatusFrame setting.
---@param title string   Dungeon name
---@param desc string    Step description text
---@param current number Current step index
---@param total number   Total steps in route
function ADW.UpdateStatusFrame(title, desc, current, total)
    local db = AutoDungeonWaypointDB
    if not db or not db.ShowStatusFrame then return end

    if db.CompactMode then
        titleText:SetText(string.format("|cFF00FF00%d/%d|r %s", current, total, title))
        stepText:SetText("")
        statusFrame:SetHeight(40)
    else
        titleText:SetText(title)
        stepText:SetText(string.format("|cFFFFD100Step %d/%d:|r %s", current, total, desc or ""))
        statusFrame:SetHeight(70)
    end

    ADW.ShowStatusFrame()
end

--- Fade out and hide the status frame.
function ADW.HideStatusFrame()
    if statusFrame:IsShown() then
        if pendingHideTimer then return end
        UIFrameFadeOut(statusFrame, 0.2, statusFrame:GetAlpha(), 0)
        pendingHideTimer = C_Timer.NewTimer(0.2, function()
            statusFrame:Hide()
            pendingHideTimer = nil
        end)
    end
end

function ADW.RestoreStatusFramePos()
    local db = AutoDungeonWaypointDB
    if db and db.StatusFramePos then
        local p = db.StatusFramePos
        local ok = pcall(function()
            statusFrame:ClearAllPoints()
            statusFrame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end)
        if not ok then
            db.StatusFramePos = nil
            statusFrame:ClearAllPoints()
            statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
        end
    end
end

function ADW.ResetStatusFramePos()
    statusFrame:ClearAllPoints()
    statusFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
end

function ADW.IsStatusFrameShown()
    return statusFrame:IsShown()
end

function ADW.ShowStatusFrameForPositioning()
    ADW.UpdateStatusFrame("HUD Positioning", "Hold SHIFT and drag to move this frame. Type /adw move again to hide.", 1, 1)
    statusFrame:Show()
    statusFrame:SetAlpha(1)
end

function ADW.PreviewHUD()
    ADW.UpdateStatusFrame("HUD Preview", "This is how the HUD looks.", 1, 5)
    statusFrame:Show()
    statusFrame:SetAlpha(1)
end

-- ============================================================================
-- Timeways Portal Map (visual overlay)
-- ============================================================================
ADW.TIMEWAYS_MAP_ID = 2266

local portalMap = CreateFrame("Frame", "ADWPortalMap", statusFrame)
portalMap:SetSize(240, 50)
portalMap:SetPoint("TOP", statusFrame, "BOTTOM", 0, -4)
portalMap:Hide()

local pmBg = portalMap:CreateTexture(nil, "BACKGROUND")
pmBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
pmBg:SetAllPoints()
pmBg:SetVertexColor(0.02, 0.02, 0.05, 0.9)

local pmGlass = portalMap:CreateTexture(nil, "BORDER")
pmGlass:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
pmGlass:SetAllPoints()
pmGlass:SetAlpha(0.05)
pmGlass:SetBlendMode("ADD")

-- Portal slot data
local PORTAL_SLOTS = {
    { key = "skyreach",        name = "Skyreach",       circle = "①" },
    { key = "pitofsaron",      name = "Pit of Saron",   circle = "②" },
    { key = nil,               name = nil,              circle = "·"  },
    { key = "algethar",        name = "Algeth'ar",      circle = "④" },
    { key = "seattriumvirate", name = "Seat of Tri.",   circle = "⑤" },
}

local slotLabels = {}
for i, slot in ipairs(PORTAL_SLOTS) do
    local xOff = (i - 3) * 40
    local label = portalMap:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER", portalMap, "CENTER", xOff, 2)
    label:SetText(slot.circle)
    label:SetTextColor(0.25, 0.25, 0.25)
    slotLabels[i] = label
end

local activeLabel = portalMap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
activeLabel:SetPoint("BOTTOM", portalMap, "BOTTOM", 0, 5)
activeLabel:SetTextColor(0, 0.9, 0.7)
activeLabel:SetText("")

--- Show the Timeways portal map overlay, highlighting the given route.
---@param routeKey string  Route key to highlight (e.g. "skyreach")
function ADW.ShowPortalMap(routeKey)
    for i, slot in ipairs(PORTAL_SLOTS) do
        if slot.key == routeKey then
            slotLabels[i]:SetTextColor(0, 1, 0.7)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
            activeLabel:SetText("▲ " .. slot.name)
        elseif slot.key then
            slotLabels[i]:SetTextColor(0.3, 0.3, 0.3)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        else
            slotLabels[i]:SetTextColor(0.15, 0.15, 0.15)
            slotLabels[i]:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        end
    end
    portalMap:Show()
end

function ADW.HidePortalMap()
    portalMap:Hide()
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

local function OnControlBarDragStart()
    if IsShiftKeyDown() then controlBar:StartMoving() end
end

local function OnControlBarDragStop()
    controlBar:StopMovingOrSizing()
    local point, _, relPoint, x, y = controlBar:GetPoint()
    if AutoDungeonWaypointDB then
        AutoDungeonWaypointDB.ToggleButtonPos = { point, relPoint, x, y }
    end
end

controlBar:SetScript("OnDragStart", OnControlBarDragStart)
controlBar:SetScript("OnDragStop", OnControlBarDragStop)

-- Auto-routing toggle button
local autoBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
autoBtn:SetSize(150, 26)
autoBtn:SetPoint("LEFT", controlBar, "LEFT", 0, 0)
autoBtn:SetNormalFontObject("GameFontNormalSmall")
autoBtn:SetScript("OnClick", function() ADW.ToggleAutoRoute() end)
autoBtn:RegisterForDrag("LeftButton")
autoBtn:SetScript("OnDragStart", OnControlBarDragStart)
autoBtn:SetScript("OnDragStop", OnControlBarDragStop)

autoBtn:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetText("Toggle Auto-Routing", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Click to enable/disable automatic dungeon detection.", 1, 1, 1, true)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
autoBtn:SetScript("OnLeave", GameTooltip_Hide)

-- List / menu button
local menuBtn = CreateFrame("Button", nil, controlBar, "UIPanelButtonTemplate")
menuBtn:SetSize(46, 26)
menuBtn:SetPoint("LEFT", autoBtn, "RIGHT", 4, 0)
menuBtn:SetText("List")
menuBtn:RegisterForDrag("LeftButton")
menuBtn:SetScript("OnDragStart", OnControlBarDragStart)
menuBtn:SetScript("OnDragStop", OnControlBarDragStop)

menuBtn:SetScript("OnEnter", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetText("Route List", 0.0, 0.75, 1.0)
    GameTooltip:AddLine("Click to view and manually start routes.", 1, 1, 1, true)
    GameTooltip:AddLine("Hold |cFFFFD100Shift|r and drag to move.", 1, 1, 1, true)
    GameTooltip:Show()
end)
menuBtn:SetScript("OnLeave", GameTooltip_Hide)

-- Menu button click is set up in Menus.lua via ADW.SetMenuButtonOnClick
function ADW.SetMenuButtonOnClick(handler)
    menuBtn:SetScript("OnClick", handler)
end

function ADW.GetMenuButton()
    return menuBtn
end

-- ============================================================================
-- Control Bar API
-- ============================================================================
--- Update the auto-routing toggle button text to reflect current state.
function ADW.UpdateToggleButton()
    local db = AutoDungeonWaypointDB
    if not db then return end
    if db.AutoRouteEnabled then
        local routeKey, stepIdx, steps = ADW.GetActiveRouteInfo()
        if routeKey then
            local name = ADW.RouteNames[routeKey] or routeKey
            local short = string.sub(name, 1, 14)
            autoBtn:SetText("|cFF55FF55" .. stepIdx .. "/" .. steps .. "|r " .. short)
        else
            autoBtn:SetText("|cFF55FF55[ON]|r Auto-Routing")
        end
    else
        autoBtn:SetText("|cFFFF5555[OFF]|r Auto-Routing")
    end
end

function ADW.RestoreControlBarPos()
    local db = AutoDungeonWaypointDB
    if db and db.ToggleButtonPos then
        local p = db.ToggleButtonPos
        local ok = pcall(function()
            controlBar:ClearAllPoints()
            controlBar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        end)
        if not ok then
            db.ToggleButtonPos = nil
            controlBar:ClearAllPoints()
            controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
        end
    end
end

function ADW.ResetControlBarPos()
    controlBar:ClearAllPoints()
    controlBar:SetPoint("TOP", UIParent, "TOP", 0, -20)
end

function ADW.SetControlBarVisible(visible)
    if visible then controlBar:Show() else controlBar:Hide() end
end

function ADW.IsControlBarVisible()
    return controlBar:IsShown()
end

-- ============================================================================
-- HUD Toggle (exposed for keybindings)
-- ============================================================================
--- Toggle or set HUD visibility. Updates SavedVariables.
---@param enabled boolean|nil  true/false to set, nil to toggle
function ADW.ToggleHUD(enabled)
    local db = AutoDungeonWaypointDB
    if enabled == nil then
        db.ShowStatusFrame = not db.ShowStatusFrame
    else
        db.ShowStatusFrame = enabled
    end

    if ADW.HasActiveRoute() and db.ShowStatusFrame then
        statusFrame:Show()
        local routeKey, stepIdx, steps = ADW.GetActiveRouteInfo()
        local desc = ADW.GetCurrentStepDesc()
        ADW.UpdateStatusFrame(ADW.RouteNames[routeKey] or routeKey, desc, stepIdx, steps)
    else
        ADW.HideStatusFrame()
    end

    if db.ShowStatusFrame then
        ADW.Print("Navigation HUD " .. GREEN .. "shown|r.")
    else
        ADW.Print("Navigation HUD " .. RED .. "hidden|r.")
    end
end
