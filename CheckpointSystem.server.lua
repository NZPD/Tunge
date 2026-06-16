local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Store = DataStoreService:GetDataStore("Obby_Checkpoints_V3")

local Checkpoints = workspace:WaitForChild("Checkpoints")
local DefaultSpawn = workspace:WaitForChild("NoCheckPart")

local Data = {}

local function getStage(player)
	return Data[player.UserId] or 0
end

local function save(player)
	local stage = getStage(player)

	pcall(function()
		Store:SetAsync(tostring(player.UserId), stage)
	end)
end

local function load(player)
	local value = 0

	pcall(function()
		local data = Store:GetAsync(tostring(player.UserId))
		if typeof(data) == "number" then
			value = data
		end
	end)

	return value
end

local function getCheckpoint(stage)
	if stage <= 0 then
		return DefaultSpawn
	end

	local cp = Checkpoints:FindFirstChild(tostring(stage))
	if cp and cp:IsA("BasePart") then
		return cp
	end

	return DefaultSpawn
end

local function teleport(player, character)
	local stage = getStage(player)
	local cp = getCheckpoint(stage)

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hrp = character:WaitForChild("HumanoidRootPart", 5)
	end
	if not hrp then
		warn("No HumanoidRootPart found for", player.Name)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("No Humanoid found for", player.Name)
		return
	end

	-- Set PrimaryPart so we can use SetPrimaryPartCFrame
	character.PrimaryPart = hrp

	-- Anchor the root part to prevent physics from interfering
	hrp.Anchored = true

	-- Set CFrame with a small vertical offset directly
	hrp.CFrame = cp.CFrame + Vector3.new(0, 5, 0)

	-- Unanchor after a short delay to let the position settle
	task.delay(0.15, function()
		hrp.Anchored = false
	end)
end

local function setupCheckpoint(part)
	if not part:IsA("BasePart") then return end

	local number = tonumber(part.Name)
	if not number then return end

	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local current = getStage(player)

		if number <= current then return end

		Data[player.UserId] = number

		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local stageValue = ls:FindFirstChild("Stage")
			if stageValue then
				stageValue.Value = number
			end
		end

		task.spawn(function()
			save(player)
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	local stage = load(player)
	Data[player.UserId] = stage

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = stage
	stageValue.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		-- Wait for character to fully load
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then return end

		local humanoid = character:WaitForChild("Humanoid", 5)
		if not humanoid then return end

		-- Wait until the humanoid is no longer dead (spawning)
		repeat
			task.wait()
		until humanoid.Health > 0 or humanoid.Health == 0 and humanoid.MaxHealth > 0

		task.wait(0.3)
		teleport(player, character)
	end)

	-- Handle if player is already spawned (e.g. joining mid-game)
	if player.Character then
		task.wait(1)
		teleport(player, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	save(player)
	Data[player.UserId] = nil
end)

for _, v in ipairs(Checkpoints:GetChildren()) do
	setupCheckpoint(v)
end

Checkpoints.ChildAdded:Connect(setupCheckpoint)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		save(player)
	end
end)