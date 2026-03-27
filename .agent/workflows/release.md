---
description: How to release a new version to GitHub and CurseForge
---

# Release a New Version

// turbo-all

## Steps

1. Decide the version number. Use semantic versioning:
   - **Patch** (6.0.1): Bug fixes, coordinate tweaks
   - **Minor** (6.1.0): New features, new dungeons
   - **Major** (7.0.0): Breaking changes, architecture overhauls

2. Update the version in `AutoDungeonWaypoint.toc`:
```
## Version: X.Y.Z
```

3. Add a changelog entry at the TOP of `CHANGELOG.md`:
```markdown
## vX.Y.Z (Short Title)
- **Feature Name**: Description of what changed.
```

4. Commit all changes:
```bash
git add -A
git commit -m "Release vX.Y.Z — Short description"
```

5. Create a git tag:
```bash
git tag vX.Y.Z
```

6. Push everything:
```bash
git push origin main --tags
```

7. The GitHub Actions workflow (`.github/workflows/release.yml`) will automatically:
   - Package the addon using BigWigsMods/packager
   - Create a GitHub Release
   - Upload to CurseForge (requires `CF_API_KEY` secret)

## Post-Release

- Verify the release appears on [GitHub Releases](https://github.com/MikeO7/wow_auto_dungeon_waypoint/releases)
- Verify it appears on [CurseForge](https://www.curseforge.com/wow/addons/auto-dungeon-waypoint)
- Sync the updated addon to the local game folder:
  `World of Warcraft/_retail_/Interface/AddOns/AutoDungeonWaypoint/`
