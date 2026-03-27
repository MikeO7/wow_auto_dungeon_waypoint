local _, ADW = ...

-- ============================================================================
-- Interface Options Panel
-- ============================================================================
function ADW.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "ADWOptionsPanel", UIParent)
    panel.name = "Auto Dungeon Waypoint"

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Auto Dungeon Waypoint Settings")

    -- Helper: create a standard checkbox
    local function CreateCheckbox(name, parent, anchor, label, tooltipTitle, tooltipBody, onClick, onShow)
        local check = CreateFrame("CheckButton", name, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
        _G[check:GetName() .. "Text"]:SetText(label)
        check:SetScript("OnClick", onClick)
        check:SetScript("OnShow", onShow)
        check:SetScript("OnEnter", function(self)
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetText(tooltipTitle, 1, 1, 1)
            GameTooltip:AddLine(tooltipBody, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", GameTooltip_Hide)
        return check
    end

    -- Auto-Routing
    local autoCheck = CreateCheckbox(
        "ADWAutoRoutingCheck", panel, title,
        "Enable Auto-Routing",
        "Enable Auto-Routing",
        "Automatically detects when you join a Mythic+ group and starts the route to the dungeon.",
        function(self) ADW.ToggleAutoRoute(self:GetChecked()) end,
        function(self) self:SetChecked(AutoDungeonWaypointDB.AutoRouteEnabled) end
    )
    -- First checkbox anchors to title with extra offset
    autoCheck:ClearAllPoints()
    autoCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)

    -- Show HUD
    local hudCheck = CreateCheckbox(
        "ADWShowHUDCheck", panel, autoCheck,
        "Show Navigation HUD",
        "Show Navigation HUD",
        "Displays a floating window with the current step's instructions.",
        function(self)
            AutoDungeonWaypointDB.ShowStatusFrame = self:GetChecked()
            if AutoDungeonWaypointDB.ShowStatusFrame then
                ADW.PreviewHUD()
            else
                ADW.HideStatusFrame()
            end
        end,
        function(self) self:SetChecked(AutoDungeonWaypointDB.ShowStatusFrame) end
    )

    -- Compact Mode
    local compactCheck = CreateCheckbox(
        "ADWCompactModeCheck", panel, hudCheck,
        "Compact HUD",
        "Compact HUD",
        "Hides the instructional text to save screen space. You can still read the text by hovering over the HUD.",
        function(self)
            AutoDungeonWaypointDB.CompactMode = self:GetChecked()
            if AutoDungeonWaypointDB.ShowStatusFrame then
                ADW.PreviewHUD()
            end
        end,
        function(self) self:SetChecked(AutoDungeonWaypointDB.CompactMode) end
    )

    -- Show Control Bar
    local controlBarCheck = CreateCheckbox(
        "ADWShowControlBarCheck", panel, compactCheck,
        "Show Control Bar",
        "Show Control Bar",
        "Shows the movable bar with Auto-Routing toggle and List buttons.",
        function(self)
            AutoDungeonWaypointDB.ShowControlBar = self:GetChecked()
            ADW.SetControlBarVisible(AutoDungeonWaypointDB.ShowControlBar)
        end,
        function(self) self:SetChecked(AutoDungeonWaypointDB.ShowControlBar ~= false) end
    )

    -- Chat Announcements
    local chatCheck = CreateCheckbox(
        "ADWShowChatTextCheck", panel, controlBarCheck,
        "Enable Chat Announcements",
        "Chat Announcements",
        "Shows text in your chat box when a route starts or a step advances.",
        function(self) AutoDungeonWaypointDB.ShowChatText = self:GetChecked() end,
        function(self) self:SetChecked(AutoDungeonWaypointDB.ShowChatText ~= false) end
    )

    -- Reset Positions button
    local resetBtn = CreateFrame("Button", "ADWResetBtn", panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 26)
    resetBtn:SetPoint("TOPLEFT", chatCheck, "BOTTOMLEFT", 0, -20)
    resetBtn:SetText("Reset Positions")
    resetBtn:SetScript("OnClick", function()
        AutoDungeonWaypointDB.StatusFramePos = nil
        AutoDungeonWaypointDB.ToggleButtonPos = nil
        ADW.ResetStatusFramePos()
        ADW.ResetControlBarPos()
        ADW.ForcePrint("HUD and Control Bar positions have been reset.")
    end)
    resetBtn:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetText("Reset Positions", 1, 1, 1)
        GameTooltip:AddLine("Restores the Navigation HUD and Control Bar to their default positions.", nil, nil, nil, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", GameTooltip_Hide)

    -- Register with the Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        ADW.settingsCategory = category
    else
        InterfaceOptions_AddCategory(panel)
    end
end
