## 2024-05-19 - Avoid Redundant Blizzard API Calls in Loops
**Learning:** Frequent polling loops (e.g., 4Hz routing ticker) should avoid redundant calls to expensive external APIs like `C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition(...)`. These were being called multiple times per tick.
**Action:** Pass pre-calculated results of API calls as arguments to helper functions, so the calls are made only once per tick. This reduces CPU time and possible stuttering.

## 2026-03-23 - Avoid String Concatenation for Cache Keys in Loops
**Learning:** Generating cache keys using string concatenation (e.g. `currentID .. "_" .. targetID`) inside high-frequency loops (like the 4Hz check in WoW addons) causes unnecessary memory allocations and triggers garbage collection micro-stutters over time.
**Action:** Use multi-dimensional (nested) tables (e.g., `Cache[currentID][targetID]`) for compound keys instead of string concatenation inside hot paths.

## 2024-05-20 - Cache string processing in frequent loops
**Learning:** Performing string manipulation functions like `lower` and `gsub` inside loops running on repetitive event triggers (e.g. `LFG_LIST_ACTIVE_ENTRY_UPDATE`) creates unnecessary string allocations. This generates garbage for the Lua garbage collector and can result in micro-stutters.
**Action:** Cache the resulting strings from repeated parsing operations (like mapping an unknown LFG activity ID) and early-return if the result is already known to prevent redundant text matching.

## 2024-05-21 - Avoid Unnecessary Garbage in Frequent Callbacks
**Learning:** High-frequency event handlers, such as `LFG_LIST_ACTIVE_ENTRY_UPDATE` or `ProcessActivityID`, may trigger many times a second. Performing string concatenation inside these callbacks generates useless string allocations for the Lua garbage collector and can result in micro-stutters.
**Action:** Remove or conditionally wrap debug logging and string-building inside extremely frequent event handlers or data processors. Additionally, order `return` or short-circuit checks properly to skip heavy operations (like `IsInInstance`) if already cached or known.

## 2026-03-28 - Cache Global State to Optimize Callbacks
**Learning:** High-frequency event handlers like LFG_LIST_ACTIVE_ENTRY_UPDATE can cause micro-stutters when making redundant Blizzard API calls like `IsInInstance()`.
**Action:** When caching global state like `IsInInstance()` to optimize high-frequency handlers in World of Warcraft addons, update the cache during the `PLAYER_ENTERING_WORLD` event to safely handle teleports, logins, and UI reloads.

## 2024-05-22 - Avoid Table Allocations in LFG Handlers
**Learning:** Blizzard APIs that return tables (like C_LFGList.GetActiveEntryInfo()) allocate memory and should be avoided inside high-frequency event handlers if the result is going to be discarded anyway.
**Action:** Add early returns (e.g., checking isPlayerInInstance) before calling API functions that return tables in high-frequency event handlers.

## 2026-03-29 - Lazy Load Blizzard APIs in Polling Loops
**Learning:** Avoid unnecessary Blizzard API calls (e.g., `C_Map.GetPlayerMapPosition`) in high-frequency loops (like `CheckDistance`) if the results are only needed under certain conditions. Unconditional API calls can create useless string allocations for the Lua garbage collector and result in micro-stutters.
**Action:** Lazy-load these values to reduce garbage collection micro-stutters.

## 2024-05-23 - Prevent Redundant Falsey Cache Misses in Loops
**Learning:** When lazy-loading Blizzard API results in Lua loops (e.g., `pos = pos or C_Map.GetPlayerMapPosition(...)`), the caching mechanism fails if the API correctly returns `nil` (e.g., when coordinates are unavailable). This causes the expensive API call to be redundantly executed on every subsequent iteration or conditionally later in the same execution tick.
**Action:** Use an explicit boolean flag (e.g., `posFetched`) alongside the cached variable to track whether the API has already been called during the current execution context, guaranteeing it runs exactly once even if it returns `nil`.

## 2024-05-24 - Short-circuit evaluations in routing scores safely
**Learning:** When optimizing scoring loops with branch-pruning or short-circuiting in Lua (such as `ADW.GetBestStepIndex`), ensure that threshold comparisons use `<=` (e.g., `bestScore <= 75`) instead of `<` if the algorithm relies on secondary tie-breakers (like distance comparisons) for equal scores. Strict less-than comparisons will introduce functional regressions by skipping valid tie scenarios.
**Action:** Allow fallback scoring branch evaluation if the best score is less than *or equal* to the maximum possible score for that branch so that tie-breaker logic inside the loop body operates correctly.