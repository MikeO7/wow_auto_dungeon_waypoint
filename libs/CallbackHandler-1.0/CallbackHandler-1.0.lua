-- CallbackHandler-1.0
-- License: Public Domain
-- https://repos.curseforge.com/wow/callbackhandler

local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

function CallbackHandler:New(target, RegisterName, UnregisterName, UnregisterAllName)
    RegisterName = RegisterName or "RegisterCallback"
    UnregisterName = UnregisterName or "UnregisterCallback"
    UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

    local events = setmetatable({}, meta)
    local registry = {recurse = 0, events = events}

    function registry:Fire(eventname, ...)
        local handlers = rawget(events, eventname)
        if not handlers or not next(handlers) then return end
        for obj, func in pairs(handlers) do
            if type(func) == "string" then
                obj[func](obj, eventname, ...)
            elseif func then
                func(eventname, ...)
            end
        end
    end

    target[RegisterName] = function(self, eventname, method, ...)
        if type(method) ~= "string" and type(method) ~= "function" then
            error("Usage: " .. RegisterName .. "(eventname, method): 'method' - Loss of function or method name expected.", 2)
        end
        if type(method) == "string" and type(self[method]) ~= "function" then
            error("Usage: " .. RegisterName .. "(eventname, method): 'method' - method '" .. tostring(method) .. "' not found on self.", 2)
        end
        events[eventname][self] = method or true
    end

    target[UnregisterName] = function(self, eventname)
        if rawget(events, eventname) then
            events[eventname][self] = nil
        end
    end

    target[UnregisterAllName] = function(self)
        for eventname, handlers in pairs(events) do
            handlers[self] = nil
        end
    end

    return registry
end
