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

    -- Windrunner Spire: Silvermoon South Gate -> Entrance
    ["windrunner"] = {
        { mapID = 2395, x = 0.3560, y = 0.7880, desc = "Fly to the Spire Entrance in Eversong Woods" },
    },

    -- Magister's Terrace: Silvermoon North Gate -> Entrance
    ["magisters"] = {
        { mapID = 2424, x = 0.6240, y = 0.1450, desc = "Fly to the Magister's Terrace entrance" },
    },

    -- Maisara Caverns: Silvermoon South Gate -> Entrance
    ["maisara"] = {
        { mapID = 2437, x = 0.4390, y = 0.3970, desc = "Fly to the Caverns entrance" },
    },

    -- Nexus-Point Xenas: West Silvermoon Portal -> Entrance
    ["nexuspoint"] = {
        { mapID = 2405, x = 0.6475, y = 0.6175, desc = "Fly to the Nexus-Point Xenas entrance" },
    },

    -- =========================================================================
    -- Legacy Mythic+ Dungeons (Optimized for Speed)
    -- =========================================================================

    -- Algeth'ar Academy: Portal Room Valdrakken -> Entrance
    ["algethar"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Take the Valdrakken portal in the Portal Room" },
        { mapID = 2025, x = 0.5820, y = 0.4240, desc = "Fly North-East from Valdrakken to the Tower" },
    },

    -- Seat of the Triumvirate: Portal Room Dalaran (Legion) -> Entrance
    ["seattriumvirate"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Take the Dalaran (Legion) portal" },
        { mapID = 882,  x = 0.2230, y = 0.5610, desc = "Take Argus portal (Krasus' Landing) -> Entrance" },
    },

    -- Skyreach: Portal Room Ashran -> Entrance
    ["skyreach"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Take the Ashran portal in the Portal Room" },
        { mapID = 542,  x = 0.3550, y = 0.3350, desc = "Fly directly South to the Skyreach entrance" },
    },

    -- Pit of Saron: Portal Room Dalaran (Northrend) -> Entrance
    ["pitofsaron"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Take the Dalaran (Northrend) portal" },
        { mapID = 118,  x = 0.5380, y = 0.8710, desc = "Fly South-East to Icecrown Citadel (Frozen Halls)" },
    },
}

-- LFG Activity ID -> Route Key mapping
ADW.LFGToRoute = {
    [1143] = "magisters",       -- Magister's Terrace (Normal)
    [1144] = "magisters",       -- Magister's Terrace (Heroic)
    [1145] = "magisters",       -- Magister's Terrace (Timewalking)
    [1542] = "windrunner",      -- Windrunner Spire (Mythic Keystone)
    [1760] = "magisters",       -- Magisters' Terrace (Mythic Keystone)
    [1764] = "maisara",         -- Maisara Caverns (Mythic Keystone)
    [1768] = "nexuspoint",      -- Nexus-Point Xenas (Mythic Keystone)
    [1160] = "algethar",        -- Algeth'ar Academy (Mythic Keystone)
    [ 486] = "seattriumvirate", -- Seat of the Triumvirate (Mythic Keystone)
    [ 182] = "skyreach",        -- Skyreach (Mythic Keystone)
    [1770] = "pitofsaron",      -- Pit of Saron (Mythic Keystone)
}
