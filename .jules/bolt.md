
## 2024-05-19 - Avoid Redundant Blizzard API Calls in Loops
**Learning:** Frequent polling loops (e.g., 4Hz routing ticker) should avoid redundant calls to expensive external APIs like `C_Map.GetBestMapForUnit("player")` and `C_Map.GetPlayerMapPosition(...)`. These were being called multiple times per tick.
**Action:** Pass pre-calculated results of API calls as arguments to helper functions, so the calls are made only once per tick. This reduces CPU time and possible stuttering.
