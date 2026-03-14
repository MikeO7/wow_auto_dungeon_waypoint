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
    -- =========================================================================
    -- Midnight Expansion Dungeons
    -- =========================================================================

    -- Windrunner Spire: Silvermoon South → Eversong Woods → Entrance
    -- Validated: entrance at /way #2395 35.5 78.8 (icy-veins, method.gg)
    ["windrunner"] = {
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Head to the south gate (Shepherd's Gate) of Silvermoon City" },
        { mapID = 2395, x = 0.4800, y = 0.5500, desc = "You're in Eversong Woods — fly south-west toward the spire" },
        { mapID = 2395, x = 0.3560, y = 0.7880, desc = "Windrunner Spire entrance is here" },
    },

    -- Magister's Terrace: Silvermoon North → Isle of Quel'Danas → Entrance
    -- Validated: Isle of Quel'Danas is directly NORTH of Silvermoon, no portal needed (games.gg)
    ["magisters"] = {
        { mapID = 2393, x = 0.5000, y = 0.1500, desc = "Head to the north gate of Silvermoon City toward the Isle of Quel'Danas" },
        { mapID = 2424, x = 0.5000, y = 0.5000, desc = "You're on the Isle of Quel'Danas — fly north-east to the Terrace" },
        { mapID = 2424, x = 0.6240, y = 0.1450, desc = "Magister's Terrace entrance is here" },
    },

    -- Maisara Caverns: Silvermoon South → Eversong Woods → Zul'Aman → Entrance
    -- Validated: entrance at /way #2437 43.93 39.71 (method.gg)
    ["maisara"] = {
        { mapID = 2393, x = 0.5510, y = 0.7030, desc = "Head to the south gate (Shepherd's Gate) of Silvermoon City" },
        { mapID = 2395, x = 0.7200, y = 0.4500, desc = "You're in Eversong Woods — fly east toward Zul'Aman" },
        { mapID = 2437, x = 0.4390, y = 0.3970, desc = "Maisara Caverns entrance is here" },
    },

    -- Nexus-Point Xenas: Silvermoon Voidstorm Portal → Voidstorm → Entrance
    -- Validated: entrance at /way #2405 63.9 15.8 (conquestcapped.com)
    ["nexuspoint"] = {
        { mapID = 2393, x = 0.3528, y = 0.6565, desc = "Take the Voidstorm Portal on the west side of Silvermoon" },
        { mapID = 2405, x = 0.5000, y = 0.3000, desc = "You're in Voidstorm — fly north toward the dungeon" },
        { mapID = 2405, x = 0.6390, y = 0.1580, desc = "Nexus-Point Xenas entrance is here" },
    },

    -- =========================================================================
    -- Legacy Mythic+ Dungeons
    -- =========================================================================

    -- Algeth'ar Academy: Silvermoon Portal Room → Valdrakken → Thaldraszus → Entrance
    -- Validated: short dragonriding flight NE of Valdrakken, entrance at 58.2 42.4 (arcaneintellect.com)
    ["algethar"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Portal Room and take the Valdrakken portal" },
        { mapID = 2112, x = 0.5800, y = 0.4800, desc = "You're in Valdrakken — fly north-east into Thaldraszus" },
        { mapID = 2025, x = 0.5820, y = 0.4240, desc = "Algeth'ar Academy entrance is at the base of the tower" },
    },

    -- Seat of the Triumvirate: Silvermoon → Dalaran (Legion) → Argus portal → Eredath → Entrance
    -- Validated: entrance at 22.3 56.1, western Eredath (youtube, fandom). Argus portal is on Krasus' Landing in Dalaran.
    -- Note: Requires Argus questline to be completed to unlock the Argus portal in Dalaran.
    ["seattriumvirate"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Portal Room and take the Dalaran (Legion) portal" },
        { mapID = 1536, x = 0.5070, y = 0.3670, desc = "You're in Dalaran — head to Krasus' Landing and take the Argus portal" },
        { mapID = 882,  x = 0.2230, y = 0.5610, desc = "Seat of the Triumvirate entrance is here — far west of Eredath through Triad's Conservatory" },
    },

    -- Skyreach: Silvermoon Portal Room → Ashran → Spires of Arak → Entrance
    -- Validated: Ashran portal exists, flying in Draenor no longer requires Pathfinder — fly directly south (quora.com)
    -- Entrance at /way Spires of Arak 35 33 (youtube)
    ["skyreach"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Portal Room and take the Ashran portal" },
        { mapID = 588,  x = 0.5000, y = 0.8000, desc = "You're in Ashran — fly directly south into Spires of Arak (no Pathfinder needed)" },
        { mapID = 542,  x = 0.3550, y = 0.3350, desc = "Skyreach entrance is here" },
    },

    -- Pit of Saron: Silvermoon Portal Room → Dalaran (WotLK) → Icecrown → Entrance
    -- Validated: Fly south-east from Dalaran into Icecrown. Pit of Saron is in the Frozen Halls side entrance of Icecrown Citadel.
    -- Entrance near /way Icecrown 53.8 87.1 (arcaneintellect.com)
    ["pitofsaron"] = {
        { mapID = 2393, x = 0.5330, y = 0.6610, desc = "Go to the Portal Room and take the Dalaran (Northrend) portal" },
        { mapID = 125,  x = 0.6700, y = 0.4500, desc = "You're in Dalaran (Northrend) — fly south-east to Icecrown" },
        { mapID = 118,  x = 0.5380, y = 0.8710, desc = "Pit of Saron is inside Icecrown Citadel — enter via the Frozen Halls side entrance" },
    },
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
