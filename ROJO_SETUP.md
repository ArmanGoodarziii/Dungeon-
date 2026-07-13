# Rojo setup

Rojo CLI 7.7.0 and the matching Studio plugin are installed.

To convert the current Studio place without altering it:

1. In Roblox Studio, use **File → Save to File As…** and save the open place as `Dungeon.rbxl` in this project folder.
2. Run:

   ```powershell
   rojo syncback default.project.json --input Dungeon.rbxl --non-interactive
   ```

3. This project intentionally syncs `ServerScriptService` only. The saved `Dungeon.rbxl` remains the source of truth for the map, Workspace models, and assets. This avoids altering the existing game hierarchy, which contains duplicate direct Workspace instance names that cannot be represented safely by Rojo's folder format.

4. Start a sync server with:

   ```powershell
   rojo serve default.project.json
   ```

5. In Studio, open `Dungeon.rbxl`, then connect through the Rojo plugin before making further script edits.

The project maps `ServerScriptService` into `src/ServerScriptService` while preserving the complete place file unchanged.
