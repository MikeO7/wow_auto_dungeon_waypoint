## 2024-05-23 - Keybinding Localization for Discoverability
**Learning:** WoW keybindings without global localization strings (e.g., `BINDING_NAME_` and `BINDING_HEADER_`) display raw XML variable names in the default Key Bindings interface, resulting in poor UX and discoverability.
**Action:** Always provide explicit `BINDING_HEADER_` and `BINDING_NAME_` global string definitions when adding keybindings via `Bindings.xml` to ensure human-readable settings menus.

## 2026-03-24 - Explicit Hidden Mouse Interactions
**Learning:** Hidden mouse interactions like Right-Click or Middle-Click on HUD elements and minimap icons are not easily discoverable by users unless explicitly documented in their respective tooltips.
**Action:** Always document hidden interactions directly inside the `OnEnter` or `OnTooltipShow` methods of UI elements to ensure discoverability.

## 2024-05-20 - Fallback Access in Compact UIs and Settings Tooltips
**Learning:** When using compact UI modes that hide text, a tooltip is an essential fallback to maintain accessibility. Configuration panels also benefit greatly from explanatory tooltips.
**Action:** Always provide tooltip fallbacks when text is hidden for compactness, and attach tooltips to form/setting elements.

## 2026-03-30 - Replace Confusing Success Sounds
**Learning:** Sound ID 8659 is often perceived by users as an error or 'No' sound effect, leading to a confusing UX when used for positive states like route completion.
**Action:** Use universally recognized positive/success sounds (like `878` for `IG_QUEST_LIST_COMPLETE` or `5274` for quest complete) for completion events instead of ambiguous or error-sounding IDs.

## 2024-05-24 - Configuration Toggle Feedback
**Learning:** Non-visual configuration toggles (like sound or chat announcements) lack immediate user feedback when toggled, leading to uncertainty about whether the setting was actually changed.
**Action:** Always provide immediate, relevant feedback (e.g., a test sound or test chat message) when a user interacts with a configuration toggle.
