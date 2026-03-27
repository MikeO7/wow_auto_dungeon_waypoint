---
description: How to add a new dungeon route to the addon
---

# Add a New Dungeon Route

All changes are in `Data.lua` only. No other files need editing.

## Steps

1. Get the dungeon's **route key** (lowercase, no spaces, e.g., `"newdungeon"`)

2. Get the **Map IDs** and **coordinates** for each step. The player can use `/adw mapid` and `/adw pos` in-game to find these, or look them up on wowhead.com.

3. Add the display name to `ADW.RouteNames` in `Data.lua`:
```lua
ADW.RouteNames["newdungeon"] = "New Dungeon Name"
```

4. Add the route steps to `ADW.Routes` in `Data.lua`:
```lua
ADW.Routes["newdungeon"] = {
    { mapID = 2393, x = 0.4243, y = 0.5834, desc = "Take the portal near Wayfarer's Rest" },
    { mapID = 1234, x = 0.5810, y = 0.4260, desc = "Fly to the dungeon entrance" },
}
```

**Rules for steps:**
- `mapID` must be a valid WoW UiMapID (use `/adw mapid` in-game)
- `x` and `y` must be in the 0.0-1.0 range (map coordinates, NOT world coordinates)  
- `desc` is shown to the player in chat and the HUD
- The route data validator will catch missing fields or out-of-range coordinates at load time

5. Add the **LFG Activity ID** mapping to `ADW.LFGToRoute`:
```lua
ADW.LFGToRoute[XXXX] = "newdungeon"  -- Mythic Keystone
```

To find the Activity ID: enable `/adw debug` in-game, join a group for that dungeon, and the ID will print to chat. You may need multiple IDs (Normal, Heroic, Mythic, Mythic Keystone).

6. **That's it.** The sorted menu cache, context menus, and List command all update automatically. The data validator runs at startup to catch any errors.

## Verification

After making changes, sync to the game folder and `/reload`. Then:
- Type `/adw list` — the new dungeon should appear
- Type `/adw route newdungeon` — the route should start
- Click the "List" button — the dungeon should be in the menu
