-- .luacheckrc
-- Configuration for Luacheck

-- Global variables
globals = {
    "ADW", "L", -- Our addon globals
    "GetLocale", "CreateFrame", "UIParent", "SlashCmdList", "DEFAULT_CHAT_FRAME", "date",
    "C_Map", "C_LFGList", "C_Minimap", "IsInInstance", "Minimap", "GameTooltip", "PlaySound",
    "GetTime", "C_Timer", "UIErrorsFrame", "C_Spell", "C_PartyInfo", "C_ChatInfo", "hooksecurefunc",
    "InCombatLockdown", "Sound_GameSystem_Get_Player_Gold", "MinimapCluster", "MinimapBackdrop",
    "GameTimeFrame", "GameFontNormal", "GameFontHighlight", "ChatFontNormal", "GameFontNormalSmall",
    "GameFontHighlightSmall", "UIPanelButtonTemplate", "UICheckButtonTemplate", "SLASH_ADW1", "SLASH_ADW2",
    "StaticPopupDialogs", "AutoDungeonWaypointDB", "UnitPosition",
    "BINDING_HEADER_ADW", "BINDING_NAME_ADW_TOGGLEHUD", "BINDING_NAME_ADW_STOP",
    "InterfaceOptions_AddCategory", "MenuUtil", "strsplit", "LibStub", "Ambiguate",
    "UnitIsUnit", "StaticPopup_Show", "GameTooltip_SetDefaultAnchor", "GameTooltip_Hide",
    "strmatch", "GetMinimapShape", "GetCursorPosition", "AddonCompartmentFrame", "WOW_PROJECT_ID", "WOW_PROJECT_MAINLINE",
    "SLASH_AUTODUNGEONWAYPOINT1", "SLASH_AUTODUNGEONWAYPOINT2", "ADW_OnAddonCompartmentClick", "ADW_Stop_Binding",
    "ADW_OnAddonCompartmentEnter", "ADW_OnAddonCompartmentLeave", "GREEN", "RED",
    "YES", "NO", "IsShiftKeyDown", "Settings", "UIFrameFadeIn", "UIFrameFadeOut", "ADW_ToggleHUD_Binding",
    "TomTom", "UiMapPoint", "C_SuperTrack", "IsInGroup", "IsInRaid", "AutoDungeonWaypoint"
}

-- Standard Lua globals (to be safe)
std = "lua51"

-- Ignore specific warnings
-- 113: Accessing an undefined global variable
-- 212: Unused argument
-- 542: Empty if branch
-- 111: Setting an undefined global variable
-- 011: Syntax error (not usually ignored, but listed for reference)
-- 631: Line is too long
-- 611: Line contains only whitespace
-- 612: Line contains trailing whitespace
-- 411: Shadowing a local variable
-- 412: Shadowing an upvalue
-- 422: Shadowing an upvalue argument
-- 211: Unused local variable
-- 431: Shadowing an upvalue
-- 432: Shadowing an upvalue argument
-- 311: Value assigned to a local variable is unused
ignore = { "212", "542", "631", "611", "612", "411", "412", "422", "211", "431", "432", "311" }

-- Per-file overrides
files["Locales/*.lua"] = {
    ignore = { "111", "113" } -- Localization files often set/access globals
}

files["Scripts/*.lua"] = {
    std = "lua51",
    globals = { "loadfile", "os", "print", "string", "table", "ipairs", "pairs", "type", "tostring", "setmetatable" }
}

files["tests/*.lua"] = {
    globals = { "describe", "it", "before_each", "after_each", "setup", "teardown", "pending", "assert", "spy", "stub", "mock", "luaunit" }
}

-- Exclude libraries from linting
exclude_files = { "libs" }
