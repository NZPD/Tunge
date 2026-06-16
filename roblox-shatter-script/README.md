# Roblox Part Crack Effect (Lua)

A single Lua script that makes any part **crack like glass on its surface** when touched by a player, and return to normal when they leave.

## Installation

1. Insert a part into Workspace
2. Insert → Object → `Script` as a child of that part
3. Paste the contents of `ShatterScript.lua` into it
4. Done

## How it works

- Player touches the part → the part turns into glass visually and branching **crack patterns** appear across its surface
- Cracks spread outward from multiple starting points in random branching tree patterns (similar to real cracked glass)
- Small glass chips appear near crack origins
- Player leaves the part → all cracks disappear and the part returns to its original appearance
- Only the player who touched it triggers the effect
- No RemoteEvents needed — everything runs on the server
- Configurable constants at the top of the script (crack count, color, transparency, reflectance, etc.)