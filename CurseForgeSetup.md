# CurseForge Project Setup

Here is everything you need to fill out the **Create Project** form on CurseForge.

## Form Details

*   **Project name**
    Auto Dungeon Waypoint

*   **Logo**
    Use `assets/logo_400.png` included in this repository.

*   **Summary**
    Automatically route, step-by-step, to any Mythic+ dungeon immediately upon joining a group.

*   **Class**
    Addons

*   **Main category**
    Dungeons & Raids

*   **Additional categories**
    Map & Minimap

## Description
*(Copy and paste the markdown below into the CurseForge Description box)*

---

**Auto Dungeon Waypoint** is a lightweight, zero-configuration addon that provides automatic, step-by-step navigation to Mythic+ dungeons the moment you join a group.

Tired of tabbing out to check which portal leads to which zone, or what flight path to take? Auto Dungeon Waypoint does it for you. 

### Features
* **Zero Input Required**: The moment you join a Premade Group for a Mythic Keystone dungeon, the addon automatically detects the dungeon and sets your first waypoint.
* **Step-by-Step Navigation**: Routes are broken down intelligently. It guides you to the correct portal room, then to the flight path or zone boundary, and finally to the dungeon entrance itself—so the waypoint is always visible on your *current* map.
* **Smart Advancement**: As you reach each waypoint, the addon detects your proximity or zone change and instantly updates the route to the next step, complete with an on-screen HUD and an audio cue.
* **Midnight Expansion Ready**: Fully supports all Season 1 Midnight dungeons, as well as the legacy Mythic+ rotation dungeons, always starting seamlessly from Silvermoon City.
* **In-Game Toggle**: Don't want directions this time? A sleek toggle button on your HUD lets you turn automation on and off with a single click.

### Slash Commands
* `/adw route <dungeon>` - Manually start a route (e.g. `/adw route windrunner`)
* `/adw stop` - Stop the current route and clear waypoints
* `/adw toggle` - Turn automatic routing upon joining a group on or off
* `/adw list` - Show all available dungeon route names
* `/adw hide` / `/adw show` - Hide or show the route UI HUD
* `/adw log` - View recent addon events if you need to troubleshoot

---

## How to Release Updates (Automated)

1. **Update the Version**: Change `## Version:` in `AutoDungeonWaypoint.toc`.
2. **Push a Tag**: Push a version tag to GitHub to trigger the release pipeline:
   ```bash
   git add -A && git commit -m "Release v1.0.1"
   git tag v1.0.1
   git push origin main --tags
   ```
3. **Verify**: The GitHub Action will automatically package the addon, create a GitHub Release with the zip attached, and publish directly to your CurseForge project.

---

## Project Setup Requirements

- **GitHub Secret**: You must add your CurseForge token as a GitHub Secret named `CF_API_KEY`.
- **Project ID**: Ensure `## X-Curse-Project-ID: 1486357` is set in your `.toc` file.

