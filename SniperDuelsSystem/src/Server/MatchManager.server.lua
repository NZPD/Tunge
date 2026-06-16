--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local WeaponConfig = require(script.Parent.Parent.Config.WeaponConfig)
local RemoteEvents = require(script.Parent.Parent.ReplicatedStorage.RemoteEvents)

local MatchManager = {}
MatchManager.CurrentMatch = nil
MatchManager.PlayerStates = {}

local matchState = {
	WaitingForPlayers = "WaitingForPlayers",
	InProgress = "InProgress",
	Ended = "Ended",
}

local playerMatchData = {}

function MatchManager:GetPlayerData(player: Player)
	return playerMatchData[player]
end

function MatchManager:IsPlayerInMatch(player: Player)
	local data = playerMatchData[player]
	return data ~= nil and data.InMatch == true
end

function MatchManager:StartMatch()
	if MatchManager.CurrentMatch ~= nil then
		return
	end
	
	local matchId = tick()
	MatchManager.CurrentMatch = matchId
	
	RemoteEvents.MatchStateChanged:FireAllClients("InProgress", matchId)
	
	task.wait(1)
	
	for _, player in ipairs(Players:GetPlayers()) do
		if playerMatchData[player] == nil then
			self:AddPlayerToMatch(player)
		else
			local data = playerMatchData[player]
			data.InMatch = true
			data.Deaths = 0
			data.Kills = 0
			self:SpawnPlayer(player)
		end
	end
	
	Players.PlayerAdded:Connect(function(player)
		if MatchManager.CurrentMatch == matchId then
			self:AddPlayerToMatch(player)
		end
	end)
end

function MatchManager:AddPlayerToMatch(player: Player)
	local data = {
		InMatch = true,
		Kills = 0,
		Deaths = 0,
		Team = "None",
		CurrentWeapon = "DefaultSniper",
		RespawnTimer = nil,
	}
	playerMatchData[player] = data
	self:SpawnPlayer(player)
end

function MatchManager:SpawnPlayer(player: Player)
	local data = playerMatchData[player]
	if data == nil or not data.InMatch then
		return
	end
	
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character:BreakJoints()
	end
	
	task.wait(0.5)
	
	local spawnLocations = workspace:FindFirstChild("SpawnLocations")
	local spawnPoint = nil
	
	if spawnLocations then
		local children = spawnLocations:GetChildren()
		if #children > 0 then
			spawnPoint = children[math.random(1, #children)]
		end
	end
	
	local character = Instance.new("Model")
	character.Name = player.Name
	
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Anchored = false
	rootPart.CanCollide = false
	rootPart.Parent = character
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Anchored = false
	head.CanCollide = false
	head.Parent = character
	
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Anchored = false
	torso.CanCollide = false
	torso.Parent = character
	
	local humanoidRootPart = Instance.new("Weld")
	humanoidRootPart.Name = "HumanoidRootPartWeld"
	humanoidRootPart.Part0 = rootPart
	humanoidRootPart.Part1 = torso
	humanoidRootPart.Parent = rootPart
	
	if spawnPoint then
		rootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
	else
		rootPart.CFrame = CFrame.new(0, 10, 0)
	end
	
	local tool = Instance.new("Tool")
	tool.Name = "Sniper"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.Parent = character
	
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	character.Parent = workspace
	
	player.Character = character
	
	RemoteEvents.WeaponEquipped:FireClient(player, "DefaultSniper")
end

function MatchManager:OnPlayerDeath(killedPlayer: Player, killerPlayer: Player?, headshot: boolean)
	local killedData = playerMatchData[killedPlayer]
	if killedData == nil or not killedData.InMatch then
		return
	end
	
	killedData.Deaths += 1
	
	if killerPlayer then
		local killerData = playerMatchData[killerPlayer]
		if killerData then
			local killScore = 1
			if headshot then
				killScore = 2
			end
			killerData.Kills += killScore
		end
		
		local killMessage = killerPlayer.Name .. " killed " .. killedPlayer.Name
		if headshot then
			killMessage = killMessage .. " (HEADSHOT)"
		end
		
		RemoteEvents.PlayerDied:FireAllClients(killMessage, killerPlayer.Name, killedPlayer.Name, headshot)
	end
	
	if killedPlayer.Character then
		killedPlayer.Character:BreakJoints()
	end
	
	task.delay(WeaponConfig.RespawnTime, function()
		if playerMatchData[killedPlayer] and playerMatchData[killedPlayer].InMatch then
			self:SpawnPlayer(killedPlayer)
		end
	end)
end

function MatchManager:EndMatch()
	if MatchManager.CurrentMatch == nil then
		return
	end
	
	MatchManager.CurrentMatch = nil
	
	RemoteEvents.MatchStateChanged:FireAllClients("Ended", nil)
	
	for player, data in pairs(playerMatchData) do
		data.InMatch = false
		if player.Character then
			player.Character:BreakJoints()
		end
	end
end

function MatchManager:RemovePlayerFromMatch(player: Player)
	local data = playerMatchData[player]
	if data then
		data.InMatch = false
		if player.Character then
			player.Character:BreakJoints()
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	self:RemovePlayerFromMatch(player)
	playerMatchData[player] = nil
end)

return MatchManager