local _, ADW = ...

-- Global strings for BindingsUI (must be defined before Bindings.xml loads)
_G["BINDING_HEADER_ADW"] = "Auto Dungeon Waypoint"
_G["BINDING_NAME_ADW_TOGGLEHUD"] = "Toggle HUD"
_G["BINDING_NAME_ADW_STOP"] = "Stop Route"

-- We will store everything in the ADW namespace.
-- Route Database
-- Each route is an array of steps: { mapID, x, y, desc }
-- ROUTES ARE DYNAMIC: They can have any number of steps (1, 3, 10, etc.)
-- All routes assume the player starts in Silvermoon City (UiMapID 2393)
-- ============================================================================

ADW.RouteNames = {
    windrunner      = "Windrunner Spire",
    magisters       = "Magister's Terrace",
    maisara         = "Maisara Caverns",
    nexuspoint      = "Nexus-Point Xenas",
    algethar        = "Algeth'ar Academy",
    seattriumvirate = "Seat of the Triumvirate",
    skyreach        = "Skyreach",
    pitofsaron      = "Pit of Saron",
}

ADW.Routes = {
    -- =========================================================================
    -- Midnight Expansion Dungeons (Optimized for Speed)
    -- =========================================================================

    -- Windrunner Spire: Silvermoon -> Eversong
    ["windrunner"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Silvermoon Portal Room (Wayfarer's Rest)" },
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Exit via South Gate (Shepherd's Gate)" },
        { mapID = 2395, x = 0.3563, y = 0.7887, desc = "Fly to the Spire Entrance in Eversong Woods" },
    },

    -- Magister's Terrace: Silvermoon -> Timeways -> Isle
    ["magisters"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Silvermoon Portal Room (Wayfarer's Rest)" },
        { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the Isle of Quel'Danas portal (Timeways Building)" },
        { mapID = 2424, x = 0.6239, y = 0.1455, desc = "Fly to the Magister's Terrace entrance" },
    },

    -- Maisara Caverns: Silvermoon -> Eversong
    ["maisara"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Silvermoon Portal Room (Wayfarer's Rest)" },
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Exit via South Gate (Shepherd's Gate)" },
        { mapID = 2437, x = 0.4393, y = 0.3971, desc = "Fly to the Caverns entrance" },
    },

    -- Nexus-Point Xenas: West Silvermoon -> Voidstorm -> Entrance
    ["nexuspoint"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Silvermoon Portal Room (Wayfarer's Rest)" },
        { mapID = 2393, x = 0.3528, y = 0.6565, desc = "Take the Voidstorm Portal (Gardens of Remembrance)" },
        { mapID = 2405, x = 0.5362, y = 0.3545, desc = "Fly to the Nexus-Point Xenas entrance" },
    },

    -- =========================================================================
    -- Legacy Mythic+ Dungeons (Orgrimmar Relay required)
    -- =========================================================================

    -- Algeth'ar Academy: Silvermoon -> Orgrimmar -> Valdrakken -> Entrance
    ["algethar"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Take the Orgrimmar portal (Portal Room)" },
        { mapID = 85,   x = 0.5712, y = 0.8769, desc = "Take the Valdrakken portal (Orgrimmar Portal Room)" },
        { mapID = 2025, x = 0.5810, y = 0.4260, desc = "Fly North-East from Valdrakken to the Tower" },
    },

    -- Seat of the Triumvirate: Silvermoon -> Orgrimmar -> Dalaran -> Entrance
    ["seattriumvirate"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Take the Orgrimmar portal (Portal Room)" },
        { mapID = 85,   x = 0.5712, y = 0.8769, desc = "Take the Azsuna/Dalaran portal (Orgrimmar Portal Room)" },
        { mapID = 882,  x = 0.2186, y = 0.5718, desc = "Take Argus portal (Krasus' Landing) -> Entrance" },
    },

    -- Skyreach: Silvermoon -> Orgrimmar -> Ashran -> Entrance
    ["skyreach"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Take the Orgrimmar portal (Portal Room)" },
        { mapID = 85,   x = 0.5712, y = 0.8769, desc = "Take the Ashran portal (Orgrimmar Portal Room)" },
        { mapID = 542,  x = 0.3557, y = 0.3349, desc = "Fly directly South to the Skyreach entrance" },
    },

    -- Pit of Saron: Silvermoon -> Orgrimmar -> Dalaran -> Entrance
    ["pitofsaron"] = {
        { mapID = 2393, x = 0.5333, y = 0.6624, desc = "Take the Orgrimmar portal (Portal Room)" },
        { mapID = 85,   x = 0.5712, y = 0.8769, desc = "Take the Dalaran portal (Orgrimmar Portal Room)" },
        { mapID = 118,  x = 0.5458, y = 0.9143, desc = "Fly South-East to Icecrown Citadel (Frozen Halls)" },
    },
}

-- LFG Activity ID -> Route Key mapping
ADW.LFGToRoute = {
    [1143] = "magisters",       -- Magister's Terrace (Normal)
    [1144] = "magisters",       -- Magister's Terrace (Heroic)
    [1145] = "magisters",       -- Magister's Terrace (Timewalking)
    [1541] = "windrunner",      -- Windrunner Spire (Mythic)
    [1542] = "windrunner",      -- Windrunner Spire (Mythic Keystone)
    [1759] = "magisters",       -- Magisters' Terrace (Mythic)
    [1760] = "magisters",       -- Magisters' Terrace (Mythic Keystone)
    [1764] = "maisara",         -- Maisara Caverns (Mythic Keystone)
    [1768] = "nexuspoint",      -- Nexus-Point Xenas (Mythic Keystone)
    [1160] = "algethar",        -- Algeth'ar Academy (Mythic Keystone)
    [ 486] = "seattriumvirate", -- Seat of the Triumvirate (Mythic Keystone)
    [ 182] = "skyreach",        -- Skyreach (Mythic Keystone)
    [1770] = "pitofsaron",      -- Pit of Saron (Mythic Keystone)
}
