# Auto Dungeon Waypoint

A World of Warcraft addon that automatically guides you to your Mythic+ dungeon, step by step. Join a group, and let Auto Dungeon Waypoint do the rest.

Built for the **WoW: Midnight** expansion (12.x).

---

## What It Does

When you join a Mythic+ group through the Premade Group Finder, Auto Dungeon Waypoint detects the dungeon and immediately sets a waypoint on your map. It walks you through each step — head to the portal room, take the right portal, fly to the entrance — and automatically advances to the next waypoint as you go.

No more alt-tabbing to look up dungeon locations. No more asking in group chat "where is this one again?"

## Supported Dungeons

| Dungeon | Expansion | Origin Zone |
|---|---|---|
| Windrunner Spire | Midnight | Eversong Woods |
| Maisara Caverns | Midnight | Zul'Aman |
| Magister's Terrace | Midnight | Isle of Quel'Danas |
| Nexus-Point Xenas | Midnight | Voidstorm |
| Algeth'ar Academy | Dragonflight | Thaldraszus |
| Seat of the Triumvirate | Legion | Eredath (Argus) |
| Skyreach | Warlords of Draenor | Spires of Arak |
| Pit of Saron | Wrath of the Lich King | Icecrown |

All routes start from **Silvermoon City** and guide you through the correct portal or city exit.

## Installation

1. Download or clone this repository
2. Copy the folder into your WoW addons directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/auto_dungeon_waypoint
   ```
3. Make sure the folder is named `auto_dungeon_waypoint` (must match the `.toc` filename prefix)
4. Restart WoW or type `/reload` if you're already logged in
5. Verify it's enabled in the AddOns menu on the character select screen

## How To Use

**Automatic mode (default):** Just join a Mythic+ group. The addon detects the dungeon and starts routing you there immediately. A small status frame appears at the top of your screen showing your current step.

**Manual mode:** Use the slash commands below to start a route yourself.

### Commands

| Command | What it does |
|---|---|
| `/adw` | Show all available commands |
| `/adw list` | List all supported dungeons and their route IDs |
| `/adw route <id>` | Manually start a route (e.g. `/adw route magisters`) |
| `/adw stop` | Cancel the current route |
| `/adw toggle` | Turn auto-routing on or off |
| `/adw hide` | Hide the on-screen toggle button |
| `/adw show` | Show the on-screen toggle button |
| `/adw debug` | Toggle debug mode (prints LFG Activity IDs — useful for development) |

### Route IDs

Use these with `/adw route`:

`windrunner` · `magisters` · `maisara` · `nexuspoint` · `algethar` · `seattriumvirate` · `skyreach` · `pitofsaron`

## How It Works

- Listens for the `LFG_LIST_JOINED_GROUP` event to detect when you join a premade group
- Queries `C_LFGList.GetSearchResultInfo` to identify the dungeon
- Sets a waypoint using `C_Map.SetUserWaypoint` and pins it to your screen with `C_SuperTrack`
- Polls your position every second and auto-advances to the next step when you arrive
- Also listens to `ZONE_CHANGED_NEW_AREA` so portal transitions are detected instantly

## Settings

Your auto-route toggle preference is saved between sessions. The on-screen toggle button is draggable — put it wherever you want and it'll stay put.

## Contributing

If you find incorrect coordinates or want to add intermediate steps to a route, the data lives in `Data.lua`. Each route is just an array of `{ mapID, x, y, desc }` entries. PRs welcome.

To find LFG Activity IDs for new dungeons, enable debug mode with `/adw debug` and join a group — the addon will print the Activity ID to chat.

## Known Limitations

- The LFG Activity ID mappings are placeholders until the official IDs are datamined. If auto-detection doesn't fire, use `/adw route <id>` manually and report the Activity ID from `/adw debug`.
- Routes assume you're starting in Silvermoon City. If you're already near the dungeon, just `/adw stop` and head in.

## License

MIT — do whatever you want with it.
