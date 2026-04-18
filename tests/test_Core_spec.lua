-- tests/test_Core.lua
-- Busted spec for Core.lua

describe("AutoDungeonWaypoint Core", function()
    local addonName = "AutoDungeonWaypoint"
    local addonTable

    setup(function()
        -- 1. Mock WoW Globals and Dependencies
        _G.AutoDungeonWaypointDB = { AutoRouteEnabled = false }
        _G.DEFAULT_CHAT_FRAME = { AddMessage = function() end }
        _G.date = function() return "2024-01-01 00:00:00" end

        _G.C_Map = {
            GetBestMapForUnit = function() return nil end,
            GetPlayerMapPosition = function() return nil end,
            ClearUserWaypoint = function() end
        }
        _G.C_LFGList = {
            GetActiveEntryInfo = function() return nil end,
            HasActiveEntryInfo = function() return false end
        }
        _G.C_Minimap = { GetMinimapShape = function() return "ROUND" end }
        _G.IsInInstance = function() return false, "none" end
        _G.CreateFrame = function() return {
            SetScript = function() end, SetSize = function() end, SetPoint = function() end,
            SetWidth = function() end, SetHeight = function() end, SetAllPoints = function() end,
            SetAttribute = function() end, SetNormalFontObject = function() end, SetHighlightFontObject = function() end,
            CreateTexture = function() return {
                SetTexture = function() end, SetAllPoints = function() end, SetColorTexture = function() end,
                SetVertexColor = function() end, SetAlpha = function() end, SetBlendMode = function() end,
                SetTextureSliceMargins = function() end, SetTextureSliceMode = function() end,
                SetPoint = function() end, SetSize = function() end, SetTexCoord = function() end,
                SetDesaturated = function() end
            } end,
            CreateFontString = function() return {
                SetFontObject = function() end, SetPoint = function() end, SetText = function() end,
                GetStringWidth = function() return 0 end, SetJustifyH = function() end,
                SetTextColor = function() end, SetWordWrap = function() end
            } end,
            RegisterEvent = function() end, Show = function() end, Hide = function() end,
            IsShown = function() return false end,
            EnableMouse = function() end, RegisterForDrag = function() end, RegisterForClicks = function() end,
            SetMovable = function() end, SetUserPlaced = function() end, SetAlpha = function() end,
            SetBackdrop = function() end, SetBackdropColor = function() end, SetBackdropBorderColor = function() end,
            SetClampRectInsets = function() end, SetHitRectInsets = function() end,
            SetChecked = function() end, GetChecked = function() return false end,
            SetStatusBarTexture = function() end, SetMinMaxValues = function() end,
            SetValue = function() end, SetStatusBarColor = function() end,
            SetNormalTexture = function() end, SetPushedTexture = function() end,
            SetHighlightTexture = function() end, SetDisabledTexture = function() end,
            Enable = function() end, Disable = function() end,
            SetText = function() end, GetFontString = function() return {SetPoint = function() end} end,
            SetScrollChild = function() end,
            ClearAllPoints = function() end,
            CreateMaskTexture = function() return {SetTexture = function() end, SetAllPoints = function() end} end,
            SetDrawLayer = function() end, AddMaskTexture = function() end
        } end
        _G.Minimap = { GetSize = function() return 140, 140 end }
        _G.GameTooltip = {
            SetOwner = function() end, ClearLines = function() end,
            AddLine = function() end, Show = function() end, Hide = function() end
        }
        _G.PlaySound = function() end
        _G.GetTime = function() return 0 end
        _G.SlashCmdList = {}
        _G.C_Timer = { After = function() end, NewTicker = function() end }
        _G.UIErrorsFrame = { AddMessage = function() end }
        _G.C_Spell = { GetSpellInfo = function() return {name="test"} end }
        _G.C_PartyInfo = { IsPartyWalkIn = function() return false end }
        _G.C_ChatInfo = { SendAddonMessage = function() end, RegisterAddonMessagePrefix = function() return true end }
        _G.hooksecurefunc = function() end
        _G.UIParent = {}
        _G.InCombatLockdown = function() return false end
        _G.Sound_GameSystem_Get_Player_Gold = 1
        _G.MinimapCluster = {}
        _G.MinimapBackdrop = {}
        _G.GameTimeFrame = {}

        _G.GameFontNormal = {}
        _G.GameFontHighlight = {}
        _G.ChatFontNormal = {}
        _G.GameFontNormalSmall = {}
        _G.GameFontHighlightSmall = {}
        _G.UIPanelButtonTemplate = "UIPanelButtonTemplate"
        _G.UICheckButtonTemplate = "UICheckButtonTemplate"

        _G.SLASH_ADW1 = "/adw"
        _G.SLASH_ADW2 = "/autodungeonwaypoint"

        _G.GREEN = "|cFF00FF00"
        _G.RED = "|cFFFF0000"

        _G.StaticPopupDialogs = {}

        -- 2. Load the actual Core.lua file safely
        addonTable = {
            RouteNames = {},
            MapToDungeon = {},
            DefaultRoute = {}
        }

        _G.GetLocale = function() return "enUS" end

        local function LoadAddonFile(filename)
            local f, err = loadfile(filename)
            if not f then
                error("Error loading " .. filename .. ": " .. tostring(err))
            end
            f(addonName, addonTable)
        end

        LoadAddonFile("Locales/enUS.lua")
        LoadAddonFile("Data.lua")
        LoadAddonFile("Core.lua")
    end)

    before_each(function()
        -- Reset state before each test
        _G.AutoDungeonWaypointDB.AutoRouteEnabled = false
    end)

    describe("ToggleAutoRoute", function()
        it("should toggle to true when currently false", function()
            addonTable.ToggleAutoRoute(nil)
            assert.is_true(_G.AutoDungeonWaypointDB.AutoRouteEnabled)
        end)

        it("should toggle to false when currently true", function()
            _G.AutoDungeonWaypointDB.AutoRouteEnabled = true
            addonTable.ToggleAutoRoute(nil)
            assert.is_false(_G.AutoDungeonWaypointDB.AutoRouteEnabled)
        end)

        it("should explicitly enable when passing true", function()
            _G.AutoDungeonWaypointDB.AutoRouteEnabled = false
            addonTable.ToggleAutoRoute(true)
            assert.is_true(_G.AutoDungeonWaypointDB.AutoRouteEnabled)
        end)

        it("should explicitly disable when passing false", function()
            _G.AutoDungeonWaypointDB.AutoRouteEnabled = true
            addonTable.ToggleAutoRoute(false)
            assert.is_false(_G.AutoDungeonWaypointDB.AutoRouteEnabled)
        end)
    end)
end)
