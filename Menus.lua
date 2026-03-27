local _, ADW = ...

-- ============================================================================
-- Shared Menu Builders
-- Eliminates the 3x duplicated menu construction pattern.
-- ============================================================================

--- Populates a rootDescription with the sorted route list.
--- Used by the control bar List button, addon compartment, and LDB minimap icon.
---@param rootDescription table  MenuUtil root description
---@param includeSettings boolean  Whether to append an "Open Settings" entry
local function BuildRouteMenu(rootDescription, includeSettings)
    rootDescription:CreateTitle("|cFF00BFFFAll Dungeons|r")
    for _, key in ipairs(ADW.SortedRouteKeys) do
        rootDescription:CreateButton(ADW.RouteNames[key], function()
            ADW.StartRoute(key)
        end)
    end
    if includeSettings then
        rootDescription:CreateDivider()
        rootDescription:CreateButton("|cFFFFD100Open Settings|r", function()
            if ADW.settingsCategory then
                Settings.OpenToCategory(ADW.settingsCategory:GetID())
            end
        end)
    end
end

-- ============================================================================
-- Control Bar "List" Button
-- ============================================================================
ADW.SetMenuButtonOnClick(function(self)
    if MenuUtil then
        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            BuildRouteMenu(rootDescription, false)
        end)
    end
end)

-- ============================================================================
-- Addon Compartment (top-right minimap menu in Midnight+)
-- ============================================================================
function ADW_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        ADW.ToggleAutoRoute()
    else
        if MenuUtil then
            MenuUtil.CreateContextMenu(MinimapCluster or UIParent, function(owner, rootDescription)
                rootDescription:CreateTitle("|cFF00BFFFAuto Dungeon Waypoint|r")
                rootDescription:CreateButton("|cFFFFD100Toggle Auto-Routing|r", function()
                    ADW.ToggleAutoRoute()
                end)
                BuildRouteMenu(rootDescription, true)
            end)
        else
            ADW.ForcePrint("Addon compartment menu is unavailable. Type /adw list instead.")
        end
    end
end

-- ============================================================================
-- LDB / Minimap Icon
-- ============================================================================
function ADW.CreateLDBObject()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if not (LDB and LDBIcon) then return end

    local adwBroker = LDB:NewDataObject("AutoDungeonWaypoint", {
        type = "launcher",
        text = "Auto Dungeon Waypoint",
        icon = "Interface\\AddOns\\AutoDungeonWaypoint\\icon.tga",
        OnClick = function(self, button)
            if button == "LeftButton" then
                if MenuUtil then
                    MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
                        BuildRouteMenu(rootDescription, true)
                    end)
                end
            elseif button == "RightButton" then
                ADW.ToggleAutoRoute()
            elseif button == "MiddleButton" then
                ADW.StopRoute()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("Auto Dungeon Waypoint", 0.0, 0.75, 1.0)
            local routeKey = ADW.GetActiveRouteKey()
            if routeKey then
                tooltip:AddLine("Active: " .. (ADW.RouteNames[routeKey] or routeKey))
            end
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFD100Left-Click:|r Open route menu", 1, 1, 1)
            tooltip:AddLine("|cFFFFD100Right-Click:|r Toggle auto-routing", 1, 1, 1)
            if routeKey then
                tooltip:AddLine("|cFFFFD100Middle-Click:|r Cancel route", 1, 1, 1)
            end
        end,
    })
    LDBIcon:Register("AutoDungeonWaypoint", adwBroker, AutoDungeonWaypointDB.MinimapIcon)
end
