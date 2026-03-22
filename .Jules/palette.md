## 2025-01-28 - Exposing Hidden Keyboard Interactions
**Learning:** Users often miss hidden interactions like Shift-drag to move HUD elements unless explicitly informed. While the statusFrame had this hint in a tooltip, the control bar buttons (autoBtn/menuBtn) did not, leaving their draggable nature undiscoverable.
**Action:** Always add `OnEnter` tooltips with clear text and keyboard hints for elements that support complex or hidden interactions like Shift-drag.
