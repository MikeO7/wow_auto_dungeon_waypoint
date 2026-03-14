local _, ADW = ...

-- We will store everything in the ADW namespace.
-- Route Database
-- Each route is an array of steps: { mapID, x, y, desc }
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
    -- Midnight Expansion Dungeons
    ["windrunner"] = {
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Exit Silvermoon City south towards Eversong Woods" },
        { mapID = 2395, x = 0.3560, y = 0.7880, desc = "Fly to Windrunner Spire entrance" }
    },
    ["magisters"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Main Portal Room and take the Quel'Danas portal" },
        { mapID = 2424, x = 0.6240, y = 0.1450, desc = "Fly to Magister's Terrace entrance" }
    },
    ["maisara"] = {
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Exit Silvermoon City south towards Eversong Woods" },
        { mapID = 2437, x = 0.4390, y = 0.3970, desc = "Fly east to Maisara Caverns entrance in Zul'Aman" }
    },
    ["nexuspoint"] = {
        { mapID = 2393, x = 0.3528, y = 0.6565, desc = "Go to the Voidstorm Portal on the west side of the city" },
        { mapID = 2405, x = 0.6470, y = 0.6170, desc = "Fly to Nexus-Point Xenas entrance" }
    },

    -- Legacy Mythic+ Dungeons
    ["algethar"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Main Portal Room and take the Valdrakken portal" },
        { mapID = 2025, x = 0.5810, y = 0.4260, desc = "Fly to Algeth'ar Academy entrance in Thaldraszus" }
    },
    ["seattriumvirate"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Main Portal Room and take the Dalaran (Legion) portal" },
        { mapID = 882, x = 0.2180, y = 0.5710, desc = "Travel to Seat of the Triumvirate entrance on Eredath" }
    },
    ["skyreach"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Main Portal Room and take the Ashran portal" },
        { mapID = 542, x = 0.3550, y = 0.3350, desc = "Fly to Skyreach entrance in Spires of Arak" }
    },
    ["pitofsaron"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Main Portal Room and take the Dalaran (WotLK) portal" },
        { mapID = 118, x = 0.5450, y = 0.9140, desc = "Fly to Pit of Saron entrance in Icecrown" }
    }
}

-- LFG Activity ID -> Route Key mapping
-- Mythic Keystone (difficulty = 4) Activity IDs sourced from premade-groups-filter Activity.lua
ADW.LFGToRoute = {
    [1542] = "windrunner",      -- Windrunner Spire (Mythic Keystone)
    [1760] = "magisters",       -- Magisters' Terrace (Mythic Keystone)
    [1764] = "maisara",         -- Maisara Caverns (Mythic Keystone)
    [1768] = "nexuspoint",      -- Nexus-Point Xenas (Mythic Keystone)
    [1160] = "algethar",        -- Algeth'ar Academy (Mythic Keystone)
    [ 486] = "seattriumvirate", -- Seat of the Triumvirate (Mythic Keystone)
    [ 182] = "skyreach",        -- Skyreach (Mythic Keystone)
    [1770] = "pitofsaron",      -- Pit of Saron (Mythic Keystone)
}
