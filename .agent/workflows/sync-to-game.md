---
description: How to sync the addon from the Git repo to the local WoW game folder
---

# Sync Addon to Game

// turbo-all

Copies the addon files from the GitHub repo to the WoW game installation folder.

## Prerequisites

Set these paths for your system:
- `REPO_DIR` = path to your cloned `wow_auto_dungeon_waypoint` repo
- `WOW_ADDON_DIR` = `<WoW Install>/World of Warcraft/_retail_/Interface/AddOns/AutoDungeonWaypoint`

## Steps

1. Run the sync command (adjust paths for your machine):
```powershell
robocopy "<REPO_DIR>" "<WOW_ADDON_DIR>" /MIR /XD .git .github .Jules .agent /XF .gitignore .pkgmeta README.md CHANGELOG.md LICENSE CurseForgeSetup.md ARCHITECTURE.md icon.png icon64.png *.md
```

2. In-game, type `/reload` to load the updated addon.

3. Verify by typing `/adw version` — the version should match the `.toc` file.

## Notes
- The `/MIR` flag mirrors the directory (adds new files, removes deleted ones)
- The `/XD` and `/XF` flags exclude non-addon files that WoW doesn't need
- The `libs/` folder IS included (required for LibDBIcon minimap button)
