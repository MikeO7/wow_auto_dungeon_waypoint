-- LibDBIcon-1.0 (Minimal Embedded Version)
-- Creates a minimap button for a LibDataBroker data object
-- Based on LibDBIcon-1.0 by funkehdude
-- License: Public Domain

local DBICON_MAJOR, DBICON_MINOR = "LibDBIcon-1.0", 100
local lib = LibStub:NewLibrary(DBICON_MAJOR, DBICON_MINOR)
if not lib then return end

lib.objects = lib.objects or {}
lib.callbackRegistered = lib.callbackRegistered or {}

local function getAnchors(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return "CENTER" end
    local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
    local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
    return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter(self)
    if self.dataObject.OnTooltipShow then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint(getAnchors(self))
        self.dataObject.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end
end

local function onLeave(self)
    GameTooltip:Hide()
end

local function onClick(self, button)
    if self.dataObject.OnClick then
        self.dataObject.OnClick(self, button)
    end
end

local function updatePosition(button, db)
    local angle = math.rad(db.minimapPos or 220)
    local x, y, q = math.cos(angle), math.sin(angle), 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local isRound = (minimapShape == "ROUND") or
                    (minimapShape == "SQUARE" and false) or
                    (minimapShape == "CORNER-TOPRIGHT" and q == 4) or
                    (minimapShape == "CORNER-TOPLEFT" and q == 3) or
                    (minimapShape == "CORNER-BOTTOMRIGHT" and q == 2) or
                    (minimapShape == "CORNER-BOTTOMLEFT" and q == 1) or
                    (minimapShape == "SIDE-LEFT" and (q == 1 or q == 3)) or
                    (minimapShape == "SIDE-RIGHT" and (q == 2 or q == 4)) or
                    (minimapShape == "SIDE-TOP" and (q == 3 or q == 4)) or
                    (minimapShape == "SIDE-BOTTOM" and (q == 1 or q == 2)) or
                    (minimapShape == "TRICORNER-TOPRIGHT" and q ~= 1) or
                    (minimapShape == "TRICORNER-TOPLEFT" and q ~= 2) or
                    (minimapShape == "TRICORNER-BOTTOMRIGHT" and q ~= 3) or
                    (minimapShape == "TRICORNER-BOTTOMLEFT" and q ~= 4)
    local edge = isRound and 80 or 110
    button:SetPoint("CENTER", Minimap, "CENTER", x * edge, y * edge)
end

local function updateCoord(self)
    if self.dataObject.iconCoords then
        self.icon:SetTexCoord(unpack(self.dataObject.iconCoords))
    else
        self.icon:SetTexCoord(0, 1, 0, 1)
    end
end

local function onDragStart(self)
    self:LockHighlight()
    self.isMouseDown = true
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx)) % 360
        self.db.minimapPos = angle
        updatePosition(self, self.db)
    end)
end

local function onDragStop(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    self.isMouseDown = false
end

function lib:Register(name, dataObject, db)
    if self.objects[name] then return end
    if not db then db = {} end
    if db.minimapPos == nil then db.minimapPos = 220 end
    if db.hide == nil then db.hide = false end

    local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(31, 31)
    button:SetFrameLevel(8)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477) -- Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture(136430) -- Interface\\Minimap\\MiniMap-TrackingBorder
    overlay:SetPoint("TOPLEFT")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture(136467) -- Interface\\Minimap\\UI-Minimap-Background
    background:SetPoint("TOPLEFT", 7, -5)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetTexture(dataObject.icon or "Interface\\Icons\\INV_Misc_Map_01")
    icon:SetPoint("TOPLEFT", 7, -6)
    button.icon = icon
    button.dataObject = dataObject
    button.db = db
    button.UpdateCoord = updateCoord

    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnDragStop", onDragStop)

    self.objects[name] = button
    updatePosition(button, db)

    if db.hide then
        button:Hide()
    else
        button:Show()
    end
end

function lib:Show(name)
    if self.objects[name] then
        self.objects[name]:Show()
        self.objects[name].db.hide = false
    end
end

function lib:Hide(name)
    if self.objects[name] then
        self.objects[name]:Hide()
        self.objects[name].db.hide = true
    end
end

function lib:IsRegistered(name)
    return self.objects[name] and true or false
end

function lib:GetMinimapButton(name)
    return self.objects[name]
end
