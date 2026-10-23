# Collapse Frontier — Godot 4 prototype

An original Android-oriented 3D sandbox prototype inspired by the broad genre of physics/destruction sandboxes. It does **not** include copied Collapsion source code, maps, models, textures, or exact UI.

## Open it
1. Install Godot 4.x on a computer.
2. Extract the ZIP.
3. In Godot, import/open the folder containing `project.godot`.
4. Press F6/F5 to run.

## Included in this early prototype
- 3D test arena and simple cover blocks
- Player movement and mouse-look
- God mode / basic fly movement toggle
- Slow-motion toggle
- Red/Blue teams
- NPCs that seek hostile targets, fire, reload, and seek rudimentary cover
- Commander NPC chance and reinforcements on a 15–30 second cooldown
- NPC weapon pickup drops and a player pickup raycast
- Five additional player weapon slots
- Respawn-at-death-position panel and five-second immunity timer
- NPC-only damage model (the player has no fall-damage handler)

## Important limitations
This is a **starter prototype, not a finished game or APK**. The current NPC collapse is only a visual placeholder, not a true articulated ragdoll. Weapons are simplified raycast hits; there are no authentic weapon animations or full ballistic simulation yet. Vehicles, planes, destructible voxel buildings, real reload animations, mobile touch sticks/buttons, save scenes, and high-quality models still need implementation. The reinforcements currently spawn NPCs; vehicle/plane reinforcements are a future feature. Use a desktop Godot 4 editor to build/export an Android APK.

## Reference and credit
Original game: [Collapsion Sandbox on Google Play](https://play.google.com/store/apps/details?id=com.kuzheren.Collapsion)

This is an unofficial personal prototype, not affiliated with or endorsed by the original developer. Credit/linking does not itself grant permission to reuse their copyrighted assets or code. Add only original or properly licensed assets.
