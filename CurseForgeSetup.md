# CurseForge Project Setup

Everything you need to fill out your CurseForge project page. Just copy-paste.

## Form Fields

*   **Project name:** Auto Dungeon Waypoint
*   **Logo:** Use `assets/logo_400.png`
*   **Summary:** Automatic step-by-step dungeon navigation for Mythic+. Join a group and get routed instantly — ETA timer, progress bar, party sharing, and more.
*   **Class:** Addons
*   **Main category:** Dungeons & Raids
*   **Additional categories:** Map & Minimap

---

## Description

*(Copy everything below into the CurseForge Description box)*

---

# Auto Dungeon Waypoint

**Stop alt-tabbing. Start running.**

Auto Dungeon Waypoint is a lightweight WoW addon that provides automatic, step-by-step navigation to every Mythic+ dungeon. Just join a group — the addon detects your dungeon and immediately starts guiding you there with on-screen waypoints, an ETA timer, and a progress bar.

No setup. No configuration. Works instantly.

---

## Why Players Love It

- **Zero-config auto-routing** — Join a Mythic+ group and navigation starts immediately. No buttons to press.
- **Live ETA timer** — See exactly how far away you are and when you'll arrive (e.g., `126yd (~8s)`).
- **Progress bar** — A sleek bar fills as you complete each step. Satisfying and informative.
- **It just works from anywhere** — Smart Routing detects your continent and syncs to the correct step, no matter where you are in the world.
- **Compact mode** — Toggle to a minimal HUD with just the arrow and distance. Perfect for experienced players.
- **Party sharing** — When you start a route, party members with the addon automatically sync up.
- **Recent routes** — Your last 5 dungeons appear at the top of the menu for quick access.
- **`/adw nearest`** — One command to start routing to the closest dungeon from wherever you are.

---

## Supported Dungeons (Season 1)

### Midnight Expansion
- Windrunner Spire (Eversong Woods)
- Magister's Terrace (Isle of Quel'Danas)
- Maisara Caverns (Zul'Aman)
- Nexus-Point Xenas (Voidstorm)

### Legacy M+ Rotation
- Algeth'ar Academy (Thaldraszus)
- Seat of the Triumvirate (Eredath / Argus)
- Skyreach (Spires of Arak)
- Pit of Saron (Icecrown)

All coordinates verified against method.gg, icy-veins.com, and wowhead.

---

## Commands

| Command | What It Does |
|---|---|
| `/adw` | Show all commands |
| `/adw list` | List all available dungeons |
| `/adw route <id>` | Start a specific route manually |
| `/adw nearest` | Auto-start the closest dungeon |
| `/adw stop` | Cancel the current route |
| `/adw toggle` | Toggle auto-routing on/off |
| `/adw compact` | Toggle compact HUD mode |
| `/adw hide` / `/adw show` | Hide or show the control bar |

---

## How It Works

1. You join a Mythic+ group through the Group Finder
2. The addon detects the dungeon via LFG Activity IDs
3. A waypoint appears on your map — head to the portal room, take the right portal, fly to the entrance
4. As you reach each waypoint, it automatically advances to the next step
5. When you enter the dungeon, the route auto-clears

That's it. No configuration needed.

---

## Premium Features at a Glance

- Smooth fade-in/out HUD with glassmorphism styling
- Color-coded distance (green < 40yd, yellow < 100yd)
- 5x per second tracking updates for buttery-smooth arrow rotation
- Shift-drag to reposition any UI element
- Route completion celebrates with a victory sound
- Full event log for troubleshooting (`/adw log`)
- Options panel in the game settings
- Keybinding support for Toggle HUD and Cancel Route

---

## Installation

Install via CurseForge app (recommended) or manually:

1. Download the latest release
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/AutoDungeonWaypoint`
3. Restart WoW or `/reload`

---

## FAQ

**Q: Does it work if I'm not in Silvermoon?**
A: Yes! Smart Routing detects your continent and syncs to the most relevant step automatically.

**Q: Can I add my own dungeon routes?**
A: Absolutely. Routes are defined in `Data.lua` as simple `{ mapID, x, y, desc }` tables. PRs welcome on GitHub.

**Q: Does it work with TomTom?**
A: Auto Dungeon Waypoint uses Blizzard's built-in waypoint system, so it works alongside TomTom without conflicts.

---

## Release Pipeline

Updates are deployed automatically via GitHub Actions when a version tag is pushed.

## Requirements

- **GitHub Secret**: `CF_API_KEY` (CurseForge API token)
- **Project ID**: Set in `.toc` as `## X-Curse-Project-ID: 1486357`
