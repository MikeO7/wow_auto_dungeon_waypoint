-- Scripts/validate_waypoints.lua
local addonName = "AutoDungeonWaypoint"
local ADW = { L = {} }

-- Mock L for Data.lua
setmetatable(ADW.L, { __index = function(_, key) return key end })

local function load_file(filename)
    local f, err = loadfile(filename)
    if not f then
        print("Error loading " .. filename .. ": " .. tostring(err))
        os.exit(1)
    end
    f(addonName, ADW)
end

-- We need to load Data.lua, but it might depend on ADW.L being populated
-- Since we just want to check coordinates, our mock __index should be enough.
load_file("Data.lua")

local exit_code = 0

local function check_step(route_key, step_idx, step)
    if type(step) ~= "table" then return end
    if step.x and (step.x < 0 or step.x > 1) then
        print(string.format("Error: Invalid x coordinate %.4f in route '%s' step %d", step.x, route_key, step_idx))
        exit_code = 1
    end
    if step.y and (step.y < 0 or step.y > 1) then
        print(string.format("Error: Invalid y coordinate %.4f in route '%s' step %d", step.y, route_key, step_idx))
        exit_code = 1
    end
end

if ADW.Routes then
    for route_key, route in pairs(ADW.Routes) do
        for i, step in ipairs(route) do
            check_step(route_key, i, step)
        end
    end
end

if ADW.CommonSteps then
    for step_key, step in pairs(ADW.CommonSteps) do
        check_step("CommonSteps." .. step_key, 0, step)
    end
end

if exit_code == 0 then
    print("Waypoint validation passed!")
else
    print("Waypoint validation failed!")
end
os.exit(exit_code)
