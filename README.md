# Auto Dungeon Waypoint

**Automatic step-by-step Mythic+ dungeon navigation for World of Warcraft: Midnight.**

Join a group → get routed instantly → arrive at the dungeon entrance.

[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/auto-dungeon-waypoint)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/MikeO7/wow_auto_dungeon_waypoint)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What It Does

When you join a Mythic+ group through the Group Finder, Auto Dungeon Waypoint **automatically detects the dungeon** and starts a step-by-step route with on-screen waypoints. It guides you through the portal room, the right portal, the flight path, and straight to the dungeon entrance — then auto-clears when you zone in.

No more alt-tabbing. No more asking "where is this one again?"

---

## Features

| Feature | Description |
|---------|-------------|
| 🚀 **Auto-Routing** | Detects dungeon on group join — zero input required |
| 🗺️ **Smart Routing** | Works from anywhere — syncs to the correct step based on your location |
| 📡 **Party Sharing** | Automatically shares routes with party members |
| 📍 **`/adw nearest`** | Auto-start the closest dungeon route |
| 🔲 **Compact Mode** | Minimal HUD with just step counter + title |
| 🎨 **Premium UI** | Glassmorphism HUD, color-coded steps, smooth animations |
| 🗼 **Timeways Map** | Visual portal overlay when routing through The Timeways |
| ⌨️ **Keybindings** | Assign hotkeys for HUD toggle and route cancel |

---

## Supported Dungeons

### Midnight Season 1
| Dungeon | Zone |
|---------|------|
| Windrunner Spire | Eversong Woods |
| Magister's Terrace | Isle of Quel'Danas |
| Maisara Caverns | Zul'Aman |
| Nexus-Point Xenas | Voidstorm |

### Legacy M+ Rotation
| Dungeon | Zone |
|---------|------|
| Algeth'ar Academy | Thaldraszus |
| Seat of the Triumvirate | Eredath (Argus) |
| Skyreach | Spires of Arak |
| Pit of Saron | Icecrown |

All coordinates verified against method.gg, icy-veins.com, and wowhead.

---

## Commands

| Command | Description |
|---------|-------------|
| `/adw` | Show all commands |
| `/adw list` | List available dungeons |
| `/adw route <id>` | Start a specific route |
| `/adw nearest` | Start the closest dungeon route |
| `/adw stop` | Cancel current route |
| `/adw toggle` | Toggle auto-routing |
| `/adw hide` | Hide all UI elements |
| `/adw show` | Restore all UI elements |
| `/adw move` | Toggle HUD for positioning |
| `/adw version` | Show addon version |
| `/adw log` | Show recent log entries |
| `/adw reset` | Reset all settings to defaults |
| `/adw debug` | Toggle debug mode |
| `/adw mapid` | Show current map ID |
| `/adw pos` | Show current position |

**Route IDs:** `windrunner` · `magisters` · `maisara` · `nexuspoint` · `algethar` · `seattriumvirate` · `skyreach` · `pitofsaron`

---

## Installation

**CurseForge (recommended):** Search "Auto Dungeon Waypoint" in the CurseForge app.

**Manual:**
1. Download the latest release from [Releases](https://github.com/MikeO7/wow_auto_dungeon_waypoint/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/AutoDungeonWaypoint`
3. Restart WoW or `/reload`

---

## How It Works

1. Listens for `LFG_LIST_JOINED_GROUP` to detect dungeon groups
2. Matches Activity IDs to verified dungeon routes
3. Sets waypoints via `C_Map.SetUserWaypoint` + `C_SuperTrack`
4. Polls position 4x/second for smooth arrow tracking and auto-advancement
5. Auto-clears the route when you enter the dungeon instance

---

## Architecture

```
Data.lua       — Route definitions, LFG mappings, sorted key cache
Core.lua       — State management, navigation engine, events, slash commands
UI.lua         — HUD frame, control bar, Timeways portal map
Options.lua    — Interface settings panel
Menus.lua      — Context menus (List button, addon compartment, LDB)
Bindings.xml   — Keybinding definitions
```

---

## Contributing

Routes are defined in `Data.lua` as simple arrays:
```lua
{ mapID = 2395, x = 0.3560, y = 0.7880, desc = "Windrunner Spire entrance is here" }
```

To find Activity IDs for new dungeons, enable `/adw debug` and join a group — the ID will print to chat.

PRs welcome!

## License

MIT — do whatever you want with it.
