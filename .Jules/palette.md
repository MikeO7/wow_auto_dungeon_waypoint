## 2025-01-28 - Exposing Hidden Keyboard Interactions
**Learning:** Users often miss hidden interactions like Shift-drag to move HUD elements unless explicitly informed. While the statusFrame had this hint in a tooltip, the control bar buttons (autoBtn/menuBtn) did not, leaving their draggable nature undiscoverable.
**Action:** Always add `OnEnter` tooltips with clear text and keyboard hints for elements that support complex or hidden interactions like Shift-drag.

## 2025-01-28 - Discoverability for LDB/Minimap Icons
**Learning:** Minimap icons or LDB (LibDataBroker) data objects often support multiple interactions like right-click or middle-click, but these actions are completely invisible to the user. Without explicit tooltips, users miss out on quick toggles and shortcuts.
**Action:** Always document hidden interaction methods (like Right-Click or Middle-Click) directly inside the `OnTooltipShow` method of minimap icons and other interactive data broker objects.
