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
## 2026-04-03 - Dynamic Status Rendering
**Learning:** State-dependent UI visuals (like portal icons and text prefixes) should be derived dynamically during render, rather than relying on one-time event injections, to prevent context loss on UI reload or toggle.
**Action:** Always compute derived state at the time of rendering when updating HUD elements.

## 2026-04-05 - Explicit Visual Controls Over Hidden Interactions
**Learning:** While tooltips can document hidden interactions (like right-clicking a tracker frame to dismiss it), relying solely on hidden interactions reduces usability and discoverability for users who don't read tooltips.
**Action:** Always provide an explicit, recognizable visual control (such as a standard `[X]` close button) for common destructive/dismissive actions, while keeping the hidden interaction as a power-user shortcut.

## 2024-04-06 - [Context Menu & Addon Compartment Active State Discoverability]
**Learning:** In World of Warcraft addons, context menus and addon compartment tooltips often hide active states or require slash commands for cancellation, leading to poor discoverability. Modifying the generated menu to dynamically display an `(Active)` label and providing a dedicated "Cancel Active Route" button (and advertising the Middle-Click shortcut in tooltips) significantly improves the interaction loop.
**Action:** When implementing WoW UI context menus or compartment dropdowns, always ensure that any active system state is visually apparent in the menu items and that immediate, explicit control options (like cancel/stop) are injected directly into the UI rather than relying on slash commands.

## 2024-04-07 - Dependent Configuration State Feedback
**Learning:** Configuration panels containing dependent sub-settings (e.g., "Compact HUD" needing "Show Navigation HUD") often leave users confused if the child setting is toggled while the parent is off and produces no effect.
**Action:** Always visually indent dependent child settings, and dynamically disable (`SetEnabled(false)`) and dim (`SetAlpha(0.5)`) them when their parent setting is disabled to clearly indicate their inactive state.

## 2026-04-08 - Multi-step Process Progress Indicator
**Learning:** For multi-step routing, users may lack context regarding their progression and how many steps are remaining, leading to friction. Adding a visible progress indicator provides immediate context and improves confidence in multi-step workflows.
**Action:** Always include a visual progress indicator (like a progress bar) when users are navigating through a multi-step sequence or wizard.

## 2024-04-09 - Expanded Checkbox Hit Areas
**Learning:** In standard UI frameworks (like WoW's `UICheckButtonTemplate`), the associated text labels often do not inherently expand the component's clickable area, violating WCAG principles for target sizing and causing accessibility friction for users relying on pointer precision.
**Action:** Always verify if text labels are enclosed within the interactive hit area boundaries. Use `SetHitRectInsets` (or equivalent CSS/HTML `<label>` wrapping) to extend the clickable target zone across the descriptive text.
