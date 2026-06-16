--!strict
-- ObbyService.server.luau
-- Core server-side service managing game state, player progression, and stage logic

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")

local Types = require(ReplicatedStorage.ObbyShared.Types)
local Constants = require(ReplicatedStorage.ObbyShared.Constants)
local RemoteEvents = require(ReplicatedStorage.ObbyShared.RemoteEvents)

local ObbyService = {}
ObbyService.__index = ObbyService

-- Configuration
local config: Types.ObbyConfig = Constants.DEFAULT_CONFIG

-- State
local playerProgress: { [number]: Types.PlayerProgress } = {}
local gameState: Types.GameState = "Waiting"
local timerThreads: { [number]: thread } = {}
local stageParts: { Types.StageData } = {}
local checkpoints: { [number]: CFrame } = {}
local finishLineCFrame: CFrame?
local spawnPoint: CFrame?
local gameStartTime: number = 0
local checkpointdatastore = DataStoreService:GetDataStore("PlayerCheckpointData")
local touchedcheckpoints: { [string]: number } = {}
local playersavedstage: { [number]: number } = {}

-- Internal connections
local connections: { RBXScriptConnection } = {}

local function savecheckpoint(userid: number, stagevalue: number)
	local s, e = pcall(function()
		checkpointdatastore:SetAsync(userid, stagevalue)
	end)
	if not s then
		warn("save checkpoint failed " .. userid .. " " .. e)
	end
end

local function loadcheckpoint(userid: number): number
	local s, r = pcall(function()
		return checkpointdatastore:GetAsync(userid)
	end)
	if s and r and r > 0 then
		return r
	end
	return 0
end

local function getspawnlocation(stagevalue: number): BasePart?
	if stagevalue > 0 then
		local c = Workspace:FindFirstChild("Checkpoints")
		if c then
			local p = c:FindFirstChild(tostring(stagevalue))
			if p and p:IsA("BasePart") then
				return p
			end
		end
	end
	local n = Workspace:FindFirstChild("NoCheckPart")
	if n and n:IsA("BasePart") then
		return n
	end
	return nil
end

--[[
	Initializes the ObbyService. Must be called before use.
]]
function ObbyService.Init(): boolean
	print("[ObbyService] Initializing...")

	-- Build stage data from workspace
	local success = ObbyService._BuildStageData()
	if not success then
		warn("[ObbyService] Failed to build stage data!")
		return false
	end

	-- Get spawn point
	local spawnFolder = Workspace:FindFirstChild(Constants.WORKSPACE_FOLDERS.SPAWN_POINT)
	if spawnFolder and spawnFolder:IsA("Folder") then
		local spawnPart = spawnFolder:FindFirstChildWhichIsA("Part")
		if spawnPart then
			spawnPoint = spawnPart.CFrame
			spawnPart.Transparency = 0.8
			spawnPart.Anchored = true
			spawnPart.CanCollide = false
			print(`[ObbyService] Spawn point set at {spawnPoint}`)
		end
	end

	-- Get finish line
	local finishFolder = Workspace:FindFirstChild(Constants.WORKSPACE_FOLDERS.FINISH_LINE)
	if finishFolder and finishFolder:IsA("Folder") then
		local finishPart = finishFolder:FindFirstChildWhichIsA("Part")
		if finishPart then
			finishLineCFrame = finishPart.CFrame
			finishPart.BrickColor = BrickColor.new("Bright yellow")
			finishPart.Material = Enum.Material.Neon
			print("[ObbyService] Finish line located")
		end
	end

	-- Set up kill volumes
	ObbyService._SetupKillVolumes()

	-- Setup checkpoint detection
	local checkpointsfolder = Workspace:FindFirstChild("Checkpoints")
	if checkpointsfolder then
		local function setupcheckpoint(c: Instance)
			if not c:IsA("BasePart") then
				return
			end
			c.Touched:Connect(function(hit: Instance)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local char = hit.Parent
				local hum = char:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then
					return
				end
				local num = tonumber(c.Name)
				if not num then
					return
				end
				local key = player.UserId .. "_" .. num
				local last = touchedcheckpoints[key]
				if last and tick() - last < 1 then
					return
				end
				touchedcheckpoints[key] = tick()
				local saved = playersavedstage[player.UserId] or 0
				if num == saved + 1 then
					playersavedstage[player.UserId] = num
					savecheckpoint(player.UserId, num)
					local progress = playerProgress[player.UserId]
					if progress then
						progress.CurrentStage = num
					end
				end
			end)
		end
		for _, c in checkpointsfolder:GetChildren() do
			setupcheckpoint(c)
		end
		checkpointsfolder.ChildAdded:Connect(function(child: Instance)
			task.wait(0.2)
			setupcheckpoint(child)
		end)
	end

	-- Connect player events
	local playerAddedConn = Players.PlayerAdded:Connect(function(player: Player)
		ObbyService._OnPlayerAdded(player)
	end)
	table.insert(connections, playerAddedConn)

	local playerRemovingConn = Players.PlayerRemoving:Connect(function(player: Player)
		ObbyService._OnPlayerRemoving(player)
	end)
	table.insert(connections, playerRemovingConn)

	-- Connect remote events
	RemoteEvents.Init()

	RemoteEvents.OnServerEvent(Constants.REMOTE_EVENTS.REQUEST_RESPAWN, function(player: Player)
		ObbyService._RespawnPlayer(player)
	end)

	RemoteEvents.OnServerEvent(Constants.REMOTE_EVENTS.STAGE_REACHED, function(player: Player, stageNumber: number)
		ObbyService._OnStageReached(player, stageNumber)
	end)

	RemoteEvents.OnServerEvent(Constants.REMOTE_EVENTS.PLAYER_FINISHED, function(player: Player)
		ObbyService._OnPlayerFinished(player)
	end)

	RemoteEvents.OnServerInvoke("GetLeaderboard", function(player: Player)
		return ObbyService._GetLeaderboardData()
	end)

	-- Handle existing players
	for _, player in Players:GetPlayers() do
		ObbyService._OnPlayerAdded(player)
	end

	print("[ObbyService] Initialized successfully")
	return true
end

--[[
	Builds stage data from parts in the Stages folder.
]]
function ObbyService._BuildStageData(): boolean
	local stagesFolder = Workspace:FindFirstChild(Constants.WORKSPACE_FOLDERS.STAGES)
	if not stagesFolder or not stagesFolder:IsA("Folder") then
		warn("[ObbyService] No Stages folder found in Workspace! Auto-generating stages.")
		return false
	end

	local stagePartsList = stagesFolder:GetChildren()
	table.sort(stagePartsList, function(a: Instance, b: Instance): boolean
		return a.Name < b.Name
	end)

	for _, part in stagePartsList do
		if part:IsA("BasePart") then
			local stageData: Types.StageData = {
				StageNumber = #stageParts + 1,
				PartCFrame = part.CFrame,
				PartSize = part.Size,
				BrickColor = part.BrickColor,
				Material = part.Material,
				CheckpointPosition = part.CFrame * CFrame.new(0, 0, -8),
				IsFinishLine = false,
			}
			table.insert(stageParts, stageData)
			CollectionService:AddTag(part, Constants.TAGS.STAGE_PART)

			-- Add checkpoint position relative to each stage
			local checkpointsFolder = Workspace:FindFirstChild(Constants.WORKSPACE_FOLDERS.CHECKPOINTS)
			if checkpointsFolder and checkpointsFolder:IsA("Folder") then
				local checkpointPart = checkpointsFolder:FindFirstChild(part.Name .. "Checkpoint")
				if checkpointPart and checkpointPart:IsA("BasePart") then
					checkpoints[stageData.StageNumber] = checkpointPart.CFrame
					CollectionService:AddTag(checkpointPart, Constants.TAGS.CHECKPOINT)
				end
			end
		end
	end

	print(`[ObbyService] Built {#stageParts} stages from workspace`)
	return #stageParts > 0
end

--[[
	Sets up kill volume detection.
]]
function ObbyService._SetupKillVolumes()
	local killFolder = Workspace:FindFirstChild("KillVolumes")
	if not killFolder then
		killFolder = Instance.new("Folder")
		killFolder.Name = "KillVolumes"
		killFolder.Parent = Workspace
	end

	for _, child in killFolder:GetChildren() do
		if child:IsA("BasePart") then
			CollectionService:AddTag(child, Constants.TAGS.KILL_VOLUME)
		end
	end

	-- Create default kill volume if none exist
	if #killFolder:GetChildren() == 0 then
		local killVolume = Instance.new("Part")
		killVolume.Name = "DefaultKillVolume"
		killVolume.Size = Vector3.new(500, 5, 500)
		killVolume.CFrame = CFrame.new(0, Constants.FALL_DETECTION_HEIGHT + 2.5, 0)
		killVolume.Anchored = true
		killVolume.CanCollide = false
		killVolume.Transparency = 1
		killVolume.Parent = killFolder
		CollectionService:AddTag(killVolume, Constants.TAGS.KILL_VOLUME)
		print("[ObbyService] Created default kill volume")
	end
end

--[[
	Handles a player joining the game.
]]
function ObbyService._OnPlayerAdded(player: Player)
	print(`[ObbyService] Player joined: {player.Name}`)

	local savedstage = loadcheckpoint(player.UserId)
	playersavedstage[player.UserId] = savedstage

	-- Initialize player progress
	playerProgress[player.UserId] = {
		Player = player,
		CurrentStage = savedstage > 0 and savedstage or 1,
		StartTime = 0,
		BestTime = nil,
		StageTimes = {},
		TotalCheckpointsPassed = 0,
		Completed = false,
	}

	-- Spawn player at their saved location
	ObbyService._TeleportToSpawn(player, savedstage)

	-- Start game automatically if enough players
	if gameState == "Waiting" and #Players:GetPlayers() >= 1 then
		task.delay(Constants.DEFAULT_CONFIG.AutoStartCountdown, function()
			ObbyService._StartGame()
		end)
	end

	-- Notify client
	RemoteEvents.Fire(Constants.REMOTE_EVENTS.PLAYER_JOINED, player, player.Name)
end

--[[
	Handles a player leaving the game.
]]
function ObbyService._OnPlayerRemoving(player: Player)
	print(`[ObbyService] Player left: {player.Name}`)
	local saved = playersavedstage[player.UserId]
	if saved then
		savecheckpoint(player.UserId, saved)
	end
	playerProgress[player.UserId] = nil
	playersavedstage[player.UserId] = nil
	RemoteEvents.FireAll(Constants.REMOTE_EVENTS.PLAYER_LEFT, player.Name)

	-- Check if game should end
	if #Players:GetPlayers() == 0 and gameState == "Playing" then
		ObbyService._EndGame()
	end
end

--[[
	Starts the game for all players.
]]
function ObbyService._StartGame()
	if gameState ~= "Waiting" then return end

	print("[ObbyService] Starting game!")
	gameState = "Playing"
	gameStartTime = tick()

	-- Reset all players
	for userId, progress in playerProgress do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			progress.CurrentStage = 1
			progress.StartTime = gameStartTime
			progress.StageTimes = {}
			progress.TotalCheckpointsPassed = 0
			progress.Completed = false
			RemoteEvents.Fire(Constants.REMOTE_EVENTS.GAME_STATE_CHANGED, player, "Playing")
			RemoteEvents.Fire(Constants.REMOTE_EVENTS.SYNC_PROGRESS, player, progress)
		end
	end

	-- Start timer updates
	RemoteEvents.FireAll(Constants.REMOTE_EVENTS.GAME_STATE_CHANGED, "Playing")
end

--[[
	Ends the current game.
]]
function ObbyService._EndGame()
	print("[ObbyService] Ending game!")
	gameState = "Finished"

	RemoteEvents.FireAll(Constants.REMOTE_EVENTS.GAME_STATE_CHANGED, "Finished")

	task.wait(5)
	gameState = "Waiting"
	RemoteEvents.FireAll(Constants.REMOTE_EVENTS.GAME_STATE_CHANGED, "Waiting")

	-- Teleport all players back to spawn
	for _, player in Players:GetPlayers() do
		ObbyService._TeleportToSpawn(player)
	end
end

--[[
	Teleports a player to the spawn point or saved checkpoint.
]]
function ObbyService._TeleportToSpawn(player: Player, savedstage: number?)
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		return
	end

	if savedstage and savedstage > 0 then
		local target = getspawnlocation(savedstage)
		if target then
			humanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
			humanoidRootPart.Anchored = true
			task.delay(0.4, function()
				if humanoidRootPart and humanoidRootPart.Parent then
					humanoidRootPart.Anchored = false
				end
			end)
			return
		end
	end

	if spawnPoint then
		humanoidRootPart.CFrame = spawnPoint
	else
		local target = getspawnlocation(0)
		if target then

	for userId, progress in playerProgress do
		if progress.Completed and progress.BestTime then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				table.insert(leaderboard, {
					PlayerName = player.Name,
					PlayerUserId = userId,
					FinalTime = progress.BestTime,
					StagesCompleted = progress.CurrentStage,
					TotalCheckpoints = progress.TotalCheckpointsPassed,
				})
			end
		end
	end

	-- Sort by time (fastest first)
	table.sort(leaderboard, function(a: Types.LeaderboardEntry, b: Types.LeaderboardEntry): boolean
		return a.FinalTime < b.FinalTime
	end)

	return leaderboard
end

--[[
	Gets the current game state.
]]
function ObbyService.GetGameState(): Types.GameState
	return gameState
end

--[[
	Gets player progress for a specific player.
]]
function ObbyService.GetPlayerProgress(player: Player): Types.PlayerProgress?
	return playerProgress[player.UserId]
end

--[[
	Gets current configuration.
]]
function ObbyService.GetConfig(): Types.ObbyConfig
	return config
end

--[[
	Updates service configuration.
]]
function ObbyService.UpdateConfig(newConfig: Types.ObbyConfig)
	config = newConfig
end

--[[
	Gets stage data for auto-generation on the client.
]]
function ObbyService.GetStageData(): { Types.StageData }
	return stageParts
end

--[[
	Cleans up the service.
]]
function ObbyService.Destroy()
	for _, conn in connections do
		conn:Disconnect()
	end
	table.clear(connections)
	table.clear(playerProgress)
	table.clear(stageParts)
	table.clear(checkpoints)
	gameState = "Waiting"
end

return ObbyService