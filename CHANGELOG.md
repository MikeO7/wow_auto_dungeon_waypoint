# Changelog

## v1.2.0
- **Global Smart Routing (Continent-Aware)**: The addon no longer gets "stuck" if you start a route from a different zone. It now detects your continent and automatically syncs to the first relevant step for your current location.
- Added `ADW.GetMapContinent` helper for smarter zone-to-continent mapping.

## v2.2.0 (UI/UX Overhaul)
- **Dual-Button Control Bar**: Replaced the single toggle button with a cleaner, two-part control unit. 
  - Left Button: Toggles Auto-Routing with clear color-coded state.
  - Right Button (☰): Opens the manual dungeon selection menu.
- **Improved Tooltips**: Tooltips now anchor better to avoid covering the dungeon selection list.
- **Enhanced Draggable Experience**: Dragging the bar moves both buttons together seamlessly.

## v2.1.1
- **Hotfix**: Properly fixed the `GetAddOnMetadata` crash for WoW 12.0.1 (Midnight) by introducing a reliable API compatibility fallback.

## v2.1.0 (The Polish Update)
- **Visual Refinement**: Thinner HUD border and cleaner "glass" backdrop for a more modern look.
- **HUD Animations**: Smooth fade-in effect when navigation starts.
- **Color-Coded Distance**: Distance text now turns yellow and green as you approach your target.
- **Reset Button**: Added a "Reset Positions" button in the options menu to restore default UI placement.
- **Polished Colors**: Tweaked UI colors for better readability and a premium feel.

## v2.0.0 (The Premium Update)
- **Live Distance Tracking**: The HUD now shows how many yards are left until the next waypoint in real-time.
- **Navigation Arrow**: A dynamic green arrow on the HUD now points directly toward your destination.
- **Interface Options Panel**: Added a dedicated settings menu under "Options > Addons" for easy configuration.
- **Keybindings Support**: You can now assign hotkeys to toggle the HUD or stop routes in the game's Keybindings menu.
- **Premium Audio**: Added a more satisfying sound cue upon reaching your dungeon destination.

## v1.1.1
- **Hotfix**: Fixed a crash caused by the `GetAddOnMetadata` function being removed in WoW 12.0.1. Switched to `C_AddOns.GetAddOnMetadata`.

## v1.1.0
- **Smart Routing**: The addon now detects your current location in the world when a route starts. If you are already in one of the zones on the path, it will automatically resume the route from your current position instead of always starting in Silvermoon.

## v1.0.9
- Added Manual Selection Dropdown: Right-click the ADW Toggle button to manually select a dungeon from the list.
- Updated tooltip with clear instructions for left-click (toggle) and right-click (manual select) actions.

## v1.0.8
- Fixed "green square" UI bug: Replaced unsupported UTF-8 icons on the toggle button with standard text labels for maximum compatibility.

## v1.0.7
- Fixed auto-routing for group creators: Navigation now triggers automatically when you list your own group.
- Added startup check: Automatically resume or start routes if already listed in LFG on login/reload.

## v1.0.6
- Improved UI persistence: HUD and Toggle button positions are now saved.
- Smarter navigation: Advanced zone-skipping logic when taking shortcuts.
- Robust initialization: Switched to `ADDON_LOADED` for better reliability.

## v1.0.5
- Updated interface version to 12.0.1 for WoW compatibility.

## v1.0.0 — Initial Release

- Automatic dungeon detection when joining M+ groups via Premade Group Finder
- Step-by-step waypoint routing from Silvermoon City to all 8 Season 1 M+ dungeons
- On-screen HUD showing current route step and dungeon name
- Draggable toggle button for quick auto-route on/off
- Sound notifications on step advancement and route completion
- Instant portal detection via zone change events
- Settings persist across sessions
- Slash commands: `/adw route`, `/adw list`, `/adw stop`, `/adw toggle`, `/adw debug`
