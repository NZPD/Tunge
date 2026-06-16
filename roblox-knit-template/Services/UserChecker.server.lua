local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage:FindFirstChild("Knit"))

local UserChecker = Knit.CreateService({
	Name = "UserChecker",
	Client = {
		IsUserVerified = Knit.CreateMethod(),
		GetUserData = Knit.CreateMethod(),
	},
})

local whitelistedUsers = {
	["123456789"] = { rank = "Admin", joined = os.time() },
	["987654321"] = { rank = "Moderator", joined = os.time() },
}

local userCache = {}

function UserChecker:KnitStart()
	print("[UserChecker] Started — monitoring player joins")

	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerJoin(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:HandlePlayerJoin(player)
	end
end

function UserChecker:HandlePlayerJoin(player)
	local userId = tostring(player.UserId)
	local whitelisted = whitelistedUsers[userId]

	userCache[player] = {
		UserId = userId,
		Name = player.Name,
		DisplayName = player.DisplayName,
		IsWhitelisted = whitelisted ~= nil,
		Rank = whitelisted and whitelisted.rank or "Guest",
		JoinedAt = whitelisted and whitelisted.joined or os.time(),
	}

	if whitelisted then
		print(("[UserChecker] %s (%s) is whitelisted — Rank: %s"):format(player.Name, userId, whitelisted.rank))
	else
		print(("[UserChecker] %s (%s) is a guest user"):format(player.Name, userId))
	end
end

function UserChecker:GetUserData(player)
	return userCache[player]
end

function UserChecker:IsWhitelisted(player)
	local data = userCache[player]
	return data and data.IsWhitelisted or false
end

function UserChecker:KickNonWhitelisted(player, reason)
	if not self:IsWhitelisted(player) then
		player:Kick(reason or "You are not whitelisted on this server.")
	end
end

function UserChecker:AddWhitelist(userId, rank)
	userId = tostring(userId)
	whitelistedUsers[userId] = { rank = rank or "Member", joined = os.time() }

	for player, data in pairs(userCache) do
		if data.UserId == userId then
			data.IsWhitelisted = true
			data.Rank = rank or "Member"
			print(("[UserChecker] Updated whitelist for %s → %s"):format(player.Name, rank))
			break
		end
	end
end

function UserChecker:RemoveWhitelist(userId)
	userId = tostring(userId)
	whitelistedUsers[userId] = nil

	for player, data in pairs(userCache) do
		if data.UserId == userId then
			data.IsWhitelisted = false
			data.Rank = "Guest"
			print(("[UserChecker] Removed whitelist for %s"):format(player.Name))
			break
		end
	end
end

function UserChecker.Client:IsUserVerified(player)
	local data = userCache[player]
	return data and data.IsWhitelisted or false
end

function UserChecker.Client:GetUserData(player)
	return userCache[player]
end

return UserChecker