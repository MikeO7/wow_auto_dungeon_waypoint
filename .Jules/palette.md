## 2026-03-24 - Explicit Hidden Mouse Interactions
**Learning:** Hidden mouse interactions like Right-Click or Middle-Click on HUD elements and minimap icons are not easily discoverable by users unless explicitly documented in their respective tooltips.
**Action:** Always document hidden interactions directly inside the `OnEnter` or `OnTooltipShow` methods of UI elements to ensure discoverability.

## 2024-05-20 - Fallback Access in Compact UIs and Settings Tooltips
**Learning:** When using compact UI modes that hide text, a tooltip is an essential fallback to maintain accessibility. Configuration panels also benefit greatly from explanatory tooltips.
**Action:** Always provide tooltip fallbacks when text is hidden for compactness, and attach tooltips to form/setting elements.
