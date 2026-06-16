local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:FindFirstChild("Knit"))

local PlayerInfo = Knit.CreateController({
	Name = "PlayerInfo",
})

function PlayerInfo:KnitStart()
	local UserChecker = Knit.GetService("UserChecker")

	local verified = UserChecker:IsUserVerified()
	print(("[PlayerInfo] Am I verified? %s"):format(tostring(verified)))

	local userData = UserChecker:GetUserData()
	if userData then
		print(("[PlayerInfo] UserId: %s, Rank: %s, Whitelisted: %s"):format(
			userData.UserId,
			userData.Rank,
			tostring(userData.IsWhitelisted)
		))
	end
end

return PlayerInfo