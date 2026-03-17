# Changelog

## v5.1.1 (Midnight Expansion Alignment)
- **Silvermoon Hub Revamp**: Aligned all routes with the redesigned Silvermoon City in the *Midnight* expansion.
- **Orgrimmar Relay**: Added a necessary hop through the Orgrimmar Portal Room for all legacy dungeons (Valdrakken, Dalaran, Ashran), reflecting the new Silvermoon-to-Orgrimmar link.
- **New Portal Coordinates**: Updated coordinates for the new Silvermoon Portal Room (Wayfarer's Rest area) and Timeways Building (for Isle of Quel'Danas).
- **Legion/BFA Routes Fixed**: Corrected waypoint paths for Seat of the Triumvirate and other legacy portals that moved in the capital city redesign.
- **Improved Flight Logic**: Fixed South Gate exit steps for local Quel'Thalas dungeons.

## v5.1.0 (Navigation & LFG Overhaul)
- **High-Speed Optimized**: Optimized heartbeat (0.1s) and arrival radius (25yd) for Skyriding at 830% speed.
- **Loop Prevention**: Consolidated simple routes to single-step targets to eliminate "snap-back" loops.
- **LFG Detection Fix**: Updated engine to handle modern WoW's `activityIDs` table and improved name matching (ignores punctuation).
- **SuperTrack Enforcement**: Waypoints now forcefully re-assert focus to stay visible over quest objectives.
- **Snap-Back Immunity**: Added 5s immunity and 100-yard buffer to prevent accidental route resets.
- **New Debug Tool**: Added `/adw debuglog` to view real-time internal status in chat.
- **Clean UI**: Removed distance meter and navigation arrows for a more streamlined HUD.
- **Stability**: Fixed random nil errors in `SetWaypointStep` during zone transitions.

## v4.3.5 (Zone Transition Fix)
- **Sticky Waypoints**: Implemented a "heartbeat" check that ensures the Blizzard and TomTom waypoints are re-applied if cleared by zone transitions, continent boundaries, or loading screens.
- **Improved Map Sync**: Enhanced `ZONE_CHANGED_NEW_AREA` and `PLAYER_ENTERING_WORLD` handlers to bridge loading screens more reliably.

## v4.3.4 (Final Binding Fix)
- **Binding Fix**: Standardized `Bindings.xml` to fix "Unrecognized XML attribute" and duplicate header warnings.
- **Global Strings**: Added `BINDING_HEADER_ADW` and name strings for better menu readability.

## v4.3.3 (Stability Fix)
- **Sound Stability**: Replaced `SOUNDKIT` constants with numeric sound IDs. This fixes a "bad argument #1" error on route completion that occurred in some game versions where the constants were missing.

## v4.3.1 (Cleanup & Fixes)
- **Removed Recent Routes**: Simplified the UI by removing the "Recent" section and underlying history tracking.
- **Fixed Binding Warnings**: Resolved "Binding header ADW was attempted to be loaded more than once" warning in `Bindings.xml`.
- **Code Optimization**: General cleanup and removal of unused state variables.

## v1.2.0
- **Global Smart Routing (Continent-Aware)**: The addon no longer gets "stuck" if you start a route from a different zone. It now detects your continent and automatically syncs to the first relevant step for your current location.
- Added `ADW.GetMapContinent` helper for smarter zone-to-continent mapping.

## v4.2.1 (Bug Fix)
- **Critical Fix**: Resolved a Lua "nil value" error when using the `/adw toggle` command or the auto-route button. This was caused by a forward-declaration issue in `Core.lua`.

## v4.2.0 (Minimap Button)
- **Minimap Button**: Added a proper minimap icon via LibDBIcon. Left-click opens the dungeon selection menu, right-click toggles auto-routing. Draggable around the minimap edge.
- Embedded LibStub, CallbackHandler-1.0, LibDataBroker-1.1, and LibDBIcon-1.0 as bundled libraries (no external dependencies needed).

## v4.1.0 (Navigation Upgrade)
- **Removed Janky Custom Arrow**: The broken HUD arrow with inaccurate rotation has been removed. Blizzard's built-in super-tracked waypoint arrow handles this perfectly.
- **Optional TomTom Integration**: If you have TomTom installed, Auto Dungeon Waypoint will automatically add waypoints to TomTom for minimap pins and TomTom's directional arrow. No configuration needed — it just detects TomTom and uses it.
- **Cleaner HUD**: Distance text repositioned for a cleaner look without the arrow taking up space.

## v4.0.1 (Route Data Fix)
- **Critical Fix**: Corrected the Nexus-Point Xenas entrance coordinates — the previous data was pointing to the wrong location entirely (Y: 15.8 → 61.75).
- Validated all 8 dungeon route coordinates against online sources (method.gg, icy-veins, arcaneintellect, conquestcapped).

## v4.0.0 (The Experience Update)
- **ETA Timer**: Distance text now shows estimated arrival time based on your movement speed (e.g., `126yd (~8s)`).
- **Progress Bar**: Animated bar at the bottom of the HUD fills as you complete route steps.
- **Compact Mode**: Toggle minimal HUD (arrow + distance + progress bar only) via `/adw compact` or Options Panel.
- **`/adw nearest`**: Automatically detects and starts the closest dungeon route from your current location.
- **Route History**: Your last 5 used routes appear in a "Recent" section at the top of the List menu for quick access.
- **Party Sharing**: Starting a route automatically broadcasts it to party members who also have the addon.
- **Improved Sounds**: Added a distinct "route starting" audio cue.

## v3.0.0 (Quality Overhaul)
- **Bug Fixes**:
  - Fixed `Bindings.xml` referencing a local variable that caused silent failures.
  - Removed dead `toggleBtn` frame that was invisibly consuming resources.
  - Distance text and navigation arrow now properly clear on route completion.
  - HUD now smoothly fades out instead of snapping off.
- **UX Improvements**:
  - Distance/arrow updates 5x per second (up from 1x) for silky-smooth tracking.
  - Auto-clears the route when you enter a dungeon instance — no manual `/adw stop` needed.
  - Button now shows live step progress (e.g., `2/3 Windrunner`) when a route is active.
- **Code Cleanup**: Removed dead code, duplicate section headers, and stale version string. Removed WoWInterface placeholder from TOC.

## v2.3.0 (Movement Update)
- **Shift-Drag Movement**: You can now move any part of the UI (buttons or HUD) by holding **Shift** and dragging with the left mouse button.
- **Enhanced HUD Interaction**: Added tooltips to the HUD and clarified movement instructions in button tooltips to prevent accidental dragging.

## v2.2.3
- **Hotfix**: Resolved a startup warning regarding the binding header being loaded more than once. Removed redundant definitions from the Lua core to favor the XML system.

## v2.2.2
- **UI Glitch Fixes**: 
  - Replaced the unsupported menu symbol with the word "List" to ensure it shows up on all clients.
  - Swapped the navigation arrow for a cleaner "Quest Pointer" style.
  - Refined the arrow's rotation math for much more accurate tracking.
  - Widened the control bar to prevent text clipping.

## v2.2.1
- **Hotfix**: Fixed a LUA_WARNING caused by malformed XML in `Bindings.xml`. Added the required XML declaration and standardized attributes.

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
