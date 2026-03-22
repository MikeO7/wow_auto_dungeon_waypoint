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
    -- Midnight Expansion Dungeons (Direct Flight Access)
    -- =========================================================================

    -- Windrunner Spire: Direct Flight from Silvermoon
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations
    ["windrunner"] = {
        { mapID = 2395, x = 0.3563, y = 0.7887, desc = "Fly directly to the Spire Entrance in Eversong Woods" },
    },

    -- Magister's Terrace: Direct Flight from Silvermoon
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations
    ["magisters"] = {
        { mapID = 2424, x = 0.6239, y = 0.1455, desc = "Fly directly to the Magister's Terrace entrance (Isle)" },
    },

    -- Maisara Caverns: Direct Flight from Silvermoon
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations
    ["maisara"] = {
        { mapID = 2437, x = 0.4393, y = 0.3971, desc = "Fly directly to the Caverns entrance" },
    },

    -- Nexus-Point Xenas: Silvermoon -> Voidstorm Portal -> Entrance
    -- Source: https://www.conquestcapped.com/midnight-dungeons-season-1-dungeon-entrances-locations/
    ["nexuspoint"] = {
        { mapID = 2393, x = 0.3530, y = 0.6550, desc = "Take the Voidstorm Portal (Gardens of Remembrance)" },
        { mapID = 2405, x = 0.6500, y = 0.6170, desc = "Fly directly to the Nexus-Point Xenas entrance" },
    },

    -- =========================================================================
    -- Legacy Mythic+ Dungeons (Timeways Relay)
    -- =========================================================================

    -- Algeth'ar Academy: Silvermoon -> Timeways -> Entrance
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations (Timeways Hub)
    ["algethar"] = {
        { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the Timeways Portal (near Wayfarer's Rest)" },
        { mapID = 2266, x = 0.7030, y = 0.7188, desc = "Take the Algeth'ar Academy portal" },
        { mapID = 2025, x = 0.5810, y = 0.4260, desc = "Fly North-East to the Academy entrance" },
    },

    -- Seat of the Triumvirate: Silvermoon -> Timeways -> Entrance
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations (Timeways Hub)
    ["seattriumvirate"] = {
        { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the Timeways Portal (near Wayfarer's Rest)" },
        { mapID = 2266, x = 0.6090, y = 0.6884, desc = "Take the Seat of the Triumvirate portal" },
        { mapID = 882,  x = 0.2186, y = 0.5718, desc = "Fly to the Triumvirate entrance" },
    },

    -- Skyreach: Silvermoon -> Timeways -> Entrance
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations (Timeways Hub)
    ["skyreach"] = {
        { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the Timeways Portal (near Wayfarer's Rest)" },
        { mapID = 2266, x = 0.6478, y = 0.4468, desc = "Take the Skyreach portal" },
        { mapID = 542,  x = 0.3557, y = 0.3349, desc = "Fly South-East to the Skyreach entrance" },
    },

    -- Pit of Saron: Silvermoon -> Timeways -> Entrance
    -- Source: https://www.method.gg/guides/midnight-season-1-dungeon-locations (Timeways Hub)
    ["pitofsaron"] = {
        { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the Timeways Portal (near Wayfarer's Rest)" },
        { mapID = 2266, x = 0.7372, y = 0.4811, desc = "Take the Pit of Saron portal" },
        { mapID = 118,  x = 0.5458, y = 0.9143, desc = "Fly to the Frozen Halls (Pit of Saron)" },
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
