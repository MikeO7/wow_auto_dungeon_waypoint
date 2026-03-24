
## 2024-05-19 - Avoid Redundant Blizzard API Calls in Loops
**Learning:** Frequent polling loops (e.g., 4Hz routing ticker) should avoid redundant calls to expensive external APIs like `C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition(...)`. These were being called multiple times per tick.
**Action:** Pass pre-calculated results of API calls as arguments to helper functions, so the calls are made only once per tick. This reduces CPU time and possible stuttering.

## 2026-03-23 - Avoid String Concatenation for Cache Keys in Loops
**Learning:** Generating cache keys using string concatenation (e.g. `currentID .. "_" .. targetID`) inside high-frequency loops (like the 4Hz check in WoW addons) causes unnecessary memory allocations and triggers garbage collection micro-stutters over time.
**Action:** Use multi-dimensional (nested) tables (e.g., `Cache[currentID][targetID]`) for compound keys instead of string concatenation inside hot paths.
