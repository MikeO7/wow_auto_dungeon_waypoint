# Architecture — Auto Dungeon Waypoint

> **Quick orientation for LLMs and contributors.** Read this file first before making any changes.

## What This Addon Does

A World of Warcraft addon that automatically navigates players to Mythic+ dungeon entrances. When a player joins a group via the LFG Group Finder, the addon detects the dungeon, starts a step-by-step route with Blizzard waypoints, and auto-advances through each step as the player travels.

## File Map

```
AutoDungeonWaypoint.toc  — Load manifest. Controls file load ORDER (critical).
Data.lua                 — Route database. ALL dungeon data lives here.
Core.lua                 — Brain. State, navigation engine, events, slash commands.
UI.lua                   — Eyes. All visual frames (HUD, ControlBar, PortalMap).
Options.lua              — Settings panel in Interface > Addons.
Menus.lua                — Context menus (List button, addon compartment, LDB icon).
Bindings.xml             — Keybinding definitions (auto-loaded by WoW, NOT in .toc).
libs/                    — Embedded libraries (LibStub, LibDataBroker, LibDBIcon).
```

### Load Order (matters!)

```
Data.lua → Core.lua → UI.lua → Options.lua → Menus.lua
```

Each file depends on APIs defined in files loaded before it. `Data.lua` has zero dependencies. `Core.lua` depends on `Data.lua`. UI/Options/Menus depend on both.

## Key Concepts

### The ADW Namespace
All addon code shares a single Lua table: `ADW` (passed via `local _, ADW = ...`).
- **Data.lua** populates: `ADW.Routes`, `ADW.RouteNames`, `ADW.LFGToRoute`, `ADW.SortedRouteKeys`
- **Core.lua** populates: `ADW.StartRoute()`, `ADW.StopRoute()`, `ADW.Print()`, state accessors
- **UI.lua** populates: `ADW.UpdateStatusFrame()`, `ADW.HideStatusFrame()`, `ADW.UpdateToggleButton()`
- **Menus.lua** populates: `ADW.CreateLDBObject()`, `ADW_OnAddonCompartmentClick()`

### Routes
A route is an ordered array of steps. Each step is: `{ mapID = <number>, x = <0-1>, y = <0-1>, desc = <string> }`.
Routes live in `Data.lua` under `ADW.Routes["key"]`. Every key must also have a display name in `ADW.RouteNames["key"]`.

### Navigation Flow
1. **Detection**: LFG event fires → `ProcessActivityID()` maps activity to route key
2. **Start**: `StartRoute(key)` → sets `activeRoute`, starts 0.25s ticker
3. **Tick**: `CheckDistance()` runs 4x/sec → checks player pos vs step target
4. **Advance**: When player is within threshold → advance to next step → set new waypoint
5. **Complete**: Last step reached or player zones into instance → `ClearRoute()`

### SavedVariables
User settings persist in `AutoDungeonWaypointDB` (declared in .toc).
- Schema changes use the `DB_VERSION` / `MigrateDB()` system in Core.lua
- When adding new settings: add to `DEFAULTS` table, increment `DB_VERSION`, add migration

## How To: Common Tasks

### Add a New Dungeon

1. **Edit `Data.lua` only.** Add to three places:
   ```lua
   -- 1. Display name
   ADW.RouteNames["newdungeon"] = "New Dungeon Name"
   
   -- 2. Route steps (1-N steps, first step is where player starts traveling)
   ADW.Routes["newdungeon"] = {
       { mapID = XXXX, x = 0.XXXX, y = 0.XXXX, desc = "Step description" },
   }
   
   -- 3. LFG Activity ID mapping (use /adw debug to find these)
   ADW.LFGToRoute[ACTIVITY_ID] = "newdungeon"
   ```
2. The route data validator will catch any missing fields or bad coordinates at load time.
3. `SortedRouteKeys` and menus update automatically — no other files need changes.

### Add a New Setting

1. Add default value to `DEFAULTS` in `Core.lua`
2. Increment `DB_VERSION` and add migration in `MigrateDB()`
3. Add checkbox in `Options.lua` using the `CreateCheckbox()` helper
4. Use `AutoDungeonWaypointDB.YourSetting` to read it anywhere

### Add a New Slash Command

1. Add the handler in the `SlashCmdList` function in `Core.lua` (around line 505)
2. Add it to the help text at the bottom of the same function
3. Update `README.md` command table

### Release a New Version

1. Update version in `AutoDungeonWaypoint.toc` (`## Version:`)
2. Add entry to top of `CHANGELOG.md`
3. Commit, tag with `git tag v X.Y.Z`, push with `--tags`
4. GitHub Actions (`.github/workflows/release.yml`) handles CurseForge upload

## WoW API Quick Reference

These are the critical WoW APIs this addon uses:

| API | Purpose |
|-----|---------|
| `C_Map.GetBestMapForUnit("player")` | Get player's current map ID |
| `C_Map.GetPlayerMapPosition(mapID, "player")` | Get player's x,y on a map (0-1 range) |
| `C_Map.SetUserWaypoint(uiMapPoint)` | Set the yellow Blizzard waypoint |
| `C_SuperTrack.SetSuperTrackedUserWaypoint(true)` | Force the navigation arrow |
| `C_LFGList.GetSearchResultInfo(id)` | Get dungeon info when joining a group |
| `C_LFGList.GetActiveEntryInfo()` | Get info when listing your own group |
| `C_Timer.NewTicker(interval, callback)` | Repeating timer (our 0.25s polling loop) |
| `IsInInstance()` | Detect when player zones into dungeon |

## Conventions

- **Public API**: Functions on `ADW.*` are the cross-module interface
- **Local functions**: File-private logic (e.g., `CheckDistance`, `ClearRoute`)
- **Naming**: camelCase for locals, PascalCase for `ADW.*` functions
- **Colors**: Use the color constants in Core.lua (`GREEN`, `RED`, `YELLOW`, etc.)
- **Printing**: Use `ADW.Print()` (respects chat toggle) or `ADW.ForcePrint()` (always shows)
- **Logging**: Use `LogInfo()` / `LogError()` for persistent event log
