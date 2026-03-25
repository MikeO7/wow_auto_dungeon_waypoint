
## 2024-05-19 - Avoid Redundant Blizzard API Calls in Loops
**Learning:** Frequent polling loops (e.g., 4Hz routing ticker) should avoid redundant calls to expensive external APIs like `C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition(...)`. These were being called multiple times per tick.
**Action:** Pass pre-calculated results of API calls as arguments to helper functions, so the calls are made only once per tick. This reduces CPU time and possible stuttering.

## 2026-03-23 - Avoid String Concatenation for Cache Keys in Loops
**Learning:** Generating cache keys using string concatenation (e.g. `currentID .. "_" .. targetID`) inside high-frequency loops (like the 4Hz check in WoW addons) causes unnecessary memory allocations and triggers garbage collection micro-stutters over time.
**Action:** Use multi-dimensional (nested) tables (e.g., `Cache[currentID][targetID]`) for compound keys instead of string concatenation inside hot paths.

## 2024-05-20 - Cache string processing in frequent loops
**Learning:** Performing string manipulation functions like `lower` and `gsub` inside loops running on repetitive event triggers (e.g. `LFG_LIST_ACTIVE_ENTRY_UPDATE`) creates unnecessary string allocations. This generates garbage for the Lua garbage collector and can result in micro-stutters.
**Action:** Cache the resulting strings from repeated parsing operations (like mapping an unknown LFG activity ID) and early-return if the result is already known to prevent redundant text matching.
