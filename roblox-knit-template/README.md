# Knit Framework Template

A ready-to-expand Knit framework template for Roblox with a **UserChecker** service included.

## Setup in Roblox Studio

1. **Install Knit** — Get `Knit` from the Toolbox or install via Wally (`sleitnick/knit`). Place it in `ReplicatedStorage`.
2. **Server Setup:**
   - Insert a `Script` into `ServerScriptService` → paste `KnitInit.server.lua`
   - Create a folder `ServerScriptService/Services` — add `UserChecker.server.lua` here
3. **Client Setup:**
   - Insert a `LocalScript` into `StarterPlayer/StarterPlayerScripts` → paste `KnitInit.client.lua`
   - Create a folder `StarterPlayer/StarterPlayerScripts/Controllers` — add controllers here
4. **Shared:** Create `ReplicatedStorage/Shared/Modules` for shared utilities.

## Folder Structure

```
ReplicatedStorage/
  Knit                     (framework model)
  Shared/
    Modules/

ServerScriptService/
  KnitInit.server.lua
  Services/
    UserChecker.server.lua

StarterPlayer/
  StarterPlayerScripts/
    KnitInit.client.lua
    Controllers/
      PlayerInfo.client.lua
```

## UserChecker Service

The built-in `UserChecker` service lets you manage whitelisted users:

| Method | Description |
|--------|-------------|
| `UserChecker:IsWhitelisted(player)` | Check if a player is whitelisted (server) |
| `UserChecker:GetUserData(player)` | Get cached user data table |
| `UserChecker:KickNonWhitelisted(player, reason?)` | Kick players not on the whitelist |
| `UserChecker:AddWhitelist(userId, rank?)` | Add a user ID to the whitelist |
| `UserChecker:RemoveWhitelist(userId)` | Remove a user ID from the whitelist |
| `UserChecker:IsUserVerified()` | Client method — check own verification status |
| `UserChecker:GetUserData()` | Client method — get own user data |

### Adding users to the whitelist

Edit the `whitelistedUsers` table in `UserChecker.server.lua`:

```lua
local whitelistedUsers = {
	["123456789"] = { rank = "Admin" },
	["987654321"] = { rank = "Moderator" },
}
```

Or add them at runtime from another service:

```lua
local UserChecker = Knit.GetService("UserChecker")
UserChecker:AddWhitelist("111222333", "VIP")
```

## Expanding

- Add new services in `ServerScriptService/Services/` — they auto-register via `Knit.AddServices`.
- Add new controllers in `StarterPlayer/StarterPlayerScripts/Controllers/`.
- Use `Knit.GetService("ServiceName")` from controllers or other services.