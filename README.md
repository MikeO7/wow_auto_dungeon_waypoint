# Auto Dungeon Waypoint

### Stop alt-tabbing for dungeon locations. Start running keys.

You join a Mythic+ group. The addon detects the dungeon. A waypoint appears on your screen — portal room, correct portal, flight path, dungeon entrance. Step by step, hands-free, until you zone in.

That's it. That's the whole addon.

[![CurseForge](https://img.shields.io/badge/CurseForge-Download-orange)](https://www.curseforge.com/wow/addons/auto-dungeon-waypoint)
[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/MikeO7/wow_auto_dungeon_waypoint)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why People Use This

If you've ever:
- Joined a key and had **no idea** where the dungeon entrance was
- Spent 2 minutes flying in the wrong direction while your group waited
- Alt-tabbed to Wowhead mid-flight to look up "Seat of the Triumvirate entrance location"
- Whispered the party leader "where do I go" and felt the shame

This addon makes all of that disappear. You queue, you get accepted, you follow the arrow. Done.

---

## How It Works

1. **You join a Mythic+ group** through the Premade Group Finder
2. **The addon auto-detects** which dungeon the group is for
3. **A step-by-step route appears** on your screen with Blizzard's built-in waypoint arrow
4. **You follow the arrow** — through portals, across zones, straight to the entrance
5. **It auto-clears** the moment you zone into the dungeon

No setup. No configuration. No clicking. It just works.

---

## Features

**Zero-Click Auto-Routing** — Detects the dungeon the instant you join a group. No buttons to press, no menus to open.

**🆕 SMART PORTAL SHORTCUTS** — *Stop searching your spellbook!* Whenever you have a Mythic+ teleport known for your current route, a pulsing, high-visibility button instantly appears on your HUD. One click and you're there. Secure, combat-safe, and tuned for all 11.0.x / 12.0.x portals.

**Smart Location Sync** — Start from anywhere in the world. The addon figures out where you are and picks up the route from the right step. Hearth to Silvermoon mid-route? It adapts.

**Party Sharing** — When you start a route, it automatically broadcasts to party members running the addon. Everyone gets the same waypoints.

**Streamlined Menu** — Flattened dungeon selection for lightning-fast navigation. No more submenus—just one clean list with active route indicators.

**Compact Mode** — Don't want a big HUD? Toggle compact mode for just the arrow and distance. Clean and minimal.

**Skyriding Optimized** — Tuned for 830% Skyriding speed with fast heartbeat polling and generous arrival radius. No "snap-back" issues at high speed.

**`/adw nearest`** — Not sure which dungeon is closest? This command figures it out and starts routing you there.

**Timeways Portal Map** — Visual overlay showing all four Timeways portals with the active one highlighted. Never pick the wrong portal again.

**Sound Cues** — Audio feedback on step completion and route finish. Toggle it off if you prefer silence.

---

## Supported Dungeons (Midnight Season 1)

Every coordinate has been verified against [Method](https://www.method.gg), [Icy Veins](https://www.icy-veins.com), and [Wowhead](https://www.wowhead.com). Sub-yard precision on all entrance locations.

### Midnight Dungeons
| Dungeon | Zone | Route |
|---------|------|-------|
| **Windrunner Spire** | Eversong Woods | Direct flight |
| **Magister's Terrace** | Isle of Quel'Danas | Direct flight |
| **Maisara Caverns** | Zul'Aman | Direct flight |
| **Nexus-Point Xenas** | Voidstorm | Portal → flight |

### Legacy M+ (via Timeways)
| Dungeon | Zone | Route |
|---------|------|-------|
| **Algeth'ar Academy** | Thaldraszus | Timeways portal → flight |
| **Seat of the Triumvirate** | Eredath (Argus) | Timeways portal → flight |
| **Skyreach** | Spires of Arak | Timeways portal → flight |
| **Pit of Saron** | Icecrown | Timeways portal → flight |

---

## Slash Commands

```
/adw              Show all commands
/adw list         Browse available dungeons
/adw route <id>   Start a specific route manually
/adw nearest      Route to the closest dungeon
/adw stop         Cancel the current route
/adw toggle       Turn auto-routing on/off
/adw hide         Hide HUD, control bar, and chat
/adw move         Show/hide HUD for repositioning
/adw mapid        Print your current Map ID
/adw pos          Print your current coordinates
/adw debug        Toggle debug mode
```

**Route IDs:** `windrunner` · `magisters` · `maisara` · `nexuspoint` · `algethar` · `seattriumvirate` · `skyreach` · `pitofsaron`

---

## Install

**CurseForge (recommended):**
Search "Auto Dungeon Waypoint" in the CurseForge app, or [click here to download](https://www.curseforge.com/wow/addons/auto-dungeon-waypoint).

**Manual install:**
1. Grab the latest `.zip` from [GitHub Releases](https://github.com/MikeO7/wow_auto_dungeon_waypoint/releases)
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/AutoDungeonWaypoint`
3. Restart WoW or type `/reload`

---

## Works With

- **TomTom** — If installed, waypoints are automatically mirrored to TomTom for minimap pins
- **Titan Panel / Bazooka** — Full LibDataBroker launcher support
- **Minimap Button Bag (MBB)** — Custom icon shows up correctly
- **ElvUI / Bartender / etc.** — No UI conflicts

---

## FAQ

**Does it work for both Horde and Alliance?**
Routes are built from Silvermoon City, which is the Midnight expansion hub for all players.

**Does it work if I'm not in Silvermoon when I join the group?**
Yes. Smart Routing detects your current zone and skips ahead to the correct step. You can be anywhere.

**Does everyone in my group need it?**
No. It works solo. But if party members also have it, routes are shared automatically via addon messaging.

**Will it conflict with my other addons?**
Unlikely. It uses Blizzard's native waypoint and SuperTrack systems. The portal shortcut is a secure action button that works safely in combat. No taint issues, no frame hooking.

**Does it use any external data or make network requests?**
No. Everything is local. Coordinates are baked into the addon.

---

## Contributing

Routes live in [`Data.lua`](Data.lua) as simple coordinate arrays:

```lua
{ mapID = 2395, x = 0.3560, y = 0.7880, desc = "Windrunner Spire entrance" }
```

Want to add a dungeon? Enable `/adw debug`, join a group for that dungeon, and grab the Activity ID from chat. PRs are welcome.

---

## License

[MIT](LICENSE) — Use it, fork it, learn from it. Do whatever you want.
