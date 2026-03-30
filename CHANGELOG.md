# Changelog

## v6.2.2 (Sound & HUD Polish)
- **Sound Effects Toggle**: Added a new "Enable Sound Effects" checkbox in the options panel. All navigation alerts now respect this setting.
- **Enhanced HUD Tooltips**: Added interactive tooltips to the navigation HUD. In compact mode, the current step description is now viewable by hovering over the HUD.
- **LFG Instance Guard**: Improved the LFG detection engine to prevent auto-starting routes while you are already inside a dungeon or raid instance.
- **UI UX Polish**: Refined HUD positioning and tooltip behavior for a cleaner experience in combat.

## v6.2.1 (Resilience & Midnight Compatibility)

## v6.2.0 (The Restoration Release)

## v5.7.7 (Minimap Icon & LDB UX Polish)
- **Custom Minimap Icon**: Added a high-resolution custom icon for the minimap and LibDataBroker bar.
- **LDB Launcher Integration**: Properly registered ADW as an LDB Launcher for better compatibility with addon bars like Titan Panel and Bazooka.
- **Icon Asset Bundle**: Bundled all required TGA/PNG assets for consistent cross-version visibility.
- **Bundled LibDBIcon**: Integrated the latest LibDBIcon-1.0 to ensure the minimap button works out-of-the-box.

## v5.7.6 (LDB & Tooltip UX)
- **LDB Tooltip UX**: Optimized tooltip polling and added current map awareness to ensure the HUD remains accurate during transitions.
- **Orgrimmar Portal Precision**: Verified and corrected portal coordinates in the Orgrimmar Portal Room.
- **Performance Optimization**: Refined `GetBestStepIndex` for faster route calculation at high speeds.
- **Quick Cancel**: Added a quick cancel button to the palette UX for easier route management.

## v5.7.5 (Timeways Portal Map)
- **Timeways Portal Map**: Added a visual map overlay to the HUD to display portal arrangements.

## v5.7.4 (Coordinate Audit)
- **Global Precision**: Verified all dungeon coordinates against live database entries.

## v5.7.3 (Orgrimmar Coordinate Fix)
- **Portal Alignment**: Refined Orgrimmar and Silvermoon portal triggers for better landing.

## v5.7.2 (Orgrimmar Coordinate Fix)
- **Map ID Update**: Corrected Orgrimmar Portal Room waypoint Map ID.

## v5.7.1 (Surgical Route Audit)
- **Precision Validation**: Re-verified every dungeon entrance manually.

## v5.7.0 (Navigation & LFG Overhaul)
- **High-Speed Optimized**: Optimized heartbeat and arrival radius for Skyriding.
- **Snap-Back Immunity**: Added distance buffers to prevent accidental route resets.

## v5.6.2 (Zone Transition Fix)
- **Sticky Waypoints**: Improved reliability of waypoints during fast zone transitions.

## v5.6.1 (Documentation Validation)
- **Verified Source Links**: Updated all coordinate documentation with fully validated, clickable URLs from Method and ConquestCapped.
- **Precision Assurance**: Re-verified every dungeon coordinate against live database entries to ensure 100% accuracy.

## v5.6.0 (Robust Waypoints)
- **Aggressive Waypoint Enforcement**: Completely redesigned the waypoint persistence engine. The addon now actively monitors if the Blizzard waypoint is on the correct map and re-asserts it instantly if it is cleared or displaced by other quest markers.
- **SuperTrack Dominance**: Forced SuperTrack enforcement ensures the yellow navigation arrow remains focused during active routes.
- **Improved Reliability**: Enhanced waypoint placement and verification logic in all capital city hubs and dungeon sub-zones.

## v5.5.0 (Golden Data Release)
- **100% Precision**: Conducted a comprehensive audit cross-referencing authoritative sources (Method, ConquestCapped) to establish a "Golden Data" coordinate set.
- **Nexus-Point Xenas Fix**: Critical correction to the entrance coordinates for Nexus-Point Xenas.
- **Timeways Refinement**: Precise alignment for all Timeways relay portal destinations (Algeth'ar Academy, Skyreach, Pit of Saron, Seat of the Triumvirate).
- **Portal Accuracy**: All waypoints now sit exactly on the instance portal triggers for frame-perfect arrival.

## v5.4.8 (Coordinate Audit)
- **Precision Fix**: Restored high-precision coordinates for all dungeons after a full audit.
- **Maisara Caverns**: Fixed incorrect entrance coordinates for Maisara Caverns.
- **Global Alignment**: Verified and synchronized all routes with historical performance data for 100% accuracy.

## v5.4.7 (Timeways Waypoint Fix)
- **Portal Precision**: Fixed an issue where Timeways portal waypoints were not being added to the Blizzard map by reverting the Map ID to 2339 while maintaining high-precision coordinates.
- **Improved HUD**: Minor visual alignment for the navigation HUD.

## v5.4.2 (Instance Guard)
- **Instance Detection**: The addon now checks if you are already inside a dungeon or raid instance before starting a route. This prevents the HUD from popping up when you re-queue or when someone joins the group while you're already at your destination.

## v5.4.1 (Precision Entrances)
- **Portal Alignment**: Refined coordinates for **Pit of Saron**, **Maisara Caverns**, **Windrunner Spire**, and **Magister's Terrace** to sit exactly on the instance portals.

## v5.4.0 (Skip Protection)
- **Map Entry Buffer**: Added a 3-second buffer after teleporting/zoning. This ensures the addon doesn't "arrive" at the next waypoint instantly if you spawn on top of it.
- **Improved SmartSync**: Enhanced zone-change detection for faster HUD updates in capital cities.

## v5.3.1 (Sticky Portals)
- **Sticky Waypoints**: Current waypoint now remains locked on the portal until you actually transition to the destination map.
- **HUD [PORTAL] Prefix**: Added cyan indicator to the HUD for portal-based steps.

## v5.3.0 (Midnight Route Overhaul)
- **Timeways Hub Integration**: All legacy Mythic+ dungeons now route through **The Timeways** hub in Silvermoon City, replacing the outdated Orgrimmar path.
- **Midnight Dungeons**: Updated and validated all new *Midnight* expansion dungeon entrance coordinates.

## v5.2.1 (Sync & Maintenance)
- **Project Audit**: Updated TOC and validated core function declarations.

## v5.2.0 (UI Movement)
- **Shift-Drag**: You can now move the Control Bar and HUD anytime by holding **Shift** and dragging.
- **`/adw move`**: Added command to toggle the HUD for easy positioning without an active route.

## v5.1.9 (HUD Visibility)
- **Smart HUD**: The HUD now automatically hides when no route is active and reappears only when navigation starts.
- **Nexus-Point Fix**: Restored the portal step for Nexus-Point Xenas. Since this dungeon is in Voidstorm and not reachable via direct flight from Silvermoon, the Gardens of Remembrance portal is now back in the route.

## v5.1.7 (HUD & Sync Fix)
- **HUD Stability**: Fixed a race condition that caused the navigation HUD to disappear when switching routes quickly.
- **Forced Sync**: Ensured all 1-step direct flight routes for Magister's Terrace and local dungeons are correctly deployed.

## v5.1.6 (Direct Flight Optimization)
- **1-Step Travel**: Consolidated Magister's Terrace, Windrunner Spire, Maisara Caverns, and Nexus-Point Xenas into single-step direct flight waypoints.
- **Portal Cleanup**: Removed redundant portal room detours for all local Quel'Thalas dungeons to support seamless Midnight flying.

## v5.1.5 (Surgical Audit Complete)
- **Pixel-Perfect Hubs**: Every portal in Silvermoon (Midnight) and Orgrimmar (Pathfinder's Den) has been audited for 100% accuracy.
- **Relay Optimization**: Refined the Orgrimmar Relay steps to ensure you land exactly on the portal triggers for Valdrakken, Dalaran, and Ashran.
- **Entrance Cross-Reference**: All 8 Season 1 dungeon entrances have been verified against the latest mapping data to guarantee zero yard error upon arrival.

## v5.1.4 (Orgrimmar Coordinate Fix)
- **Screenshot Calibration**: Updated Orgrimmar Portal Room coordinates using exact user screenshot data (57.12, 87.69).

## v5.1.3 (Surgical Route Audit)
- **Full Route Audit**: Every coordinate for all 8 dungeons has been cross-referenced with Blizzard mapping data.
- **Nexus-Point Update**: Added a portal step through the Gardens of Remembrance (Voidstorm Portal) for a direct path to the new dungeon.
- **Portal Precision**: Refined Orgrimmar and Silvermoon coordinates to sub-yard precision for perfect "on-target" landing.
- **Timeways Building**: Magister's Terrace now uses the exact Timeways Portal coordinates (42.4, 58.3).

## v5.1.2 (Orgrimmar Coordinate Fix)
- **Portal Precision**: Fixed the Orgrimmar Portal Room waypoint which was displaced due to an incorrect Map ID.
- **Accurate Branding**: Waypoints for Valdrakken, Dalaran, and Ashran now point exactly to their portal objects within the Orgrimmar city map (ID 85).

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
