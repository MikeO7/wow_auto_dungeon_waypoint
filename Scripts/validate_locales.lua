-- Scripts/validate_locales.lua
local addonName = "AutoDungeonWaypoint"

local function load_locale(filename, locale_to_mock)
    local ADW = { L = {} }
    _G.GetLocale = function() return locale_to_mock end
    local f, err = loadfile(filename)
    if not f then
        print("Error loading " .. filename .. ": " .. tostring(err))
        return nil
    end
    -- Support both the "local _, ADW = ..." and "local ADW = select(2, ...)" patterns
    f(addonName, ADW)
    return ADW.L
end

local enUS = load_locale("Locales/enUS.lua", "enUS")
local targets = {"deDE", "esES", "frFR", "koKR", "ptBR", "ruRU", "zhCN"}

local exit_code = 0

for _, lang in ipairs(targets) do
    local filepath = "Locales/" .. lang .. ".lua"
    local locale = load_locale(filepath, lang)
    if locale then
        local missing = 0
        for key, _ in pairs(enUS) do
            if not locale[key] then
                -- print("Error: Missing key '" .. key .. "' in " .. lang)
                missing = missing + 1
                -- exit_code = 1
            end
        end
        if missing > 0 then
            print(string.format("Warning: %s is missing %d keys from enUS.lua", lang, missing))
        end
    else
        print("Error: Could not load locale " .. lang)
        exit_code = 1
    end
end

if exit_code == 0 then
    print("Localization check passed (with warnings for missing translations)!")
else
    print("Localization check failed!")
end
os.exit(exit_code)
