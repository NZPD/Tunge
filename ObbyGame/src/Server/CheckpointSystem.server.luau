local players = game:GetService("Players")
local datastoreservice = game:GetService("DataStoreService")
local checkpointdatastore = datastoreservice:GetDataStore("PlayerCheckpointData")

local checkpoints = workspace:FindFirstChild("Checkpoints")
if not checkpoints then
	checkpoints = Instance.new("Folder")
	checkpoints.Name = "Checkpoints"
	checkpoints.Parent = workspace
end

local touchedcheckpoints = {}
local playerstages = {}

local function saveplayerdata(userid, stagevalue)
	local s, e = pcall(function()
		checkpointdatastore:SetAsync(userid, stagevalue)
	end)
	if not s then
		warn("save failed " .. userid .. " " .. e)
	end
end

local function loadplayerdata(userid)
	local s, r = pcall(function()
		return checkpointdatastore:GetAsync(userid)
	end)
	if s and r and r > 0 then
		return r
	end
	return 0
end

local function getspawnpoint(stagevalue)
	if stagevalue and stagevalue > 0 then
		local p = checkpoints:FindFirstChild(tostring(stagevalue))
		if p then
			return p
		end
	end
	return workspace:FindFirstChild("NoCheckPart")
end

local function teleportcharacter(character, stagevalue)
	if not character or not character.Parent then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local spawnpoint = getspawnpoint(stagevalue)

	if spawnpoint then
		root.CFrame = spawnpoint.CFrame + Vector3.new(0, 5, 0)
	else
		root.CFrame = CFrame.new(0, 20, 0)
	end

	root.Anchored = true
	task.delay(0.5, function()
		if root and root.Parent then
			root.Anchored = false
		end
	end)
end

players.PlayerAdded:Connect(function(player)
	local stage = loadplayerdata(player.UserId)
	playerstages[player.UserId] = stage

	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	local sv = Instance.new("IntValue")
	sv.Name = "Stage"
	sv.Value = stage
	sv.Parent = ls

	player.CharacterAdded:Connect(function(character)
		local s = playerstages[player.UserId]
		if not s then
			s = 0
		end
		local root = character:WaitForChild("HumanoidRootPart", 15)
		if root then
			task.wait(0.5)
			teleportcharacter(character, s)
		end
	end)
end)

players.PlayerRemoving:Connect(function(player)
	local stage = playerstages[player.UserId]
	if stage then
		saveplayerdata(player.UserId, stage)
	end
	playerstages[player.UserId] = nil
end)

for _, checkpoint in pairs(checkpoints:GetChildren()) do
	if checkpoint:IsA("BasePart") then
		checkpoint.Touched:Connect(function(hit)
			local player = players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local char = hit.Parent
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then
				return
			end
			local num = tonumber(checkpoint.Name)
			if not num then
				return
			end
			local key = player.UserId .. "_" .. num
			local last = touchedcheckpoints[key]
			if last and tick() - last < 1 then
				return
			end
			touchedcheckpoints[key] = tick()
			local current = playerstages[player.UserId]
			if not current then
				current = 0
			end
			if num == current + 1 then
				playerstages[player.UserId] = num
				saveplayerdata(player.UserId, num)
				local ls = player:FindFirstChild("leaderstats")
				local sv = ls and ls:FindFirstChild("Stage")
				if sv then
					sv.Value = num
				end
			end
		end)
	end
end

checkpoints.ChildAdded:Connect(function(child)
	task.wait(0.5)
	if child:IsA("BasePart") then
		child.Touched:Connect(function(hit)
			local player = players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local char = hit.Parent
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then
				return
			end
			local num = tonumber(child.Name)
			if not num then
				return
			end
			local key = player.UserId .. "_" .. num
			local last = touchedcheckpoints[key]
			if last and tick() - last < 1 then
				return
			end
			touchedcheckpoints[key] = tick()
			local current = playerstages[player.UserId]
			if not current then
				current = 0
			end
			if num == current + 1 then
				playerstages[player.UserId] = num
				saveplayerdata(player.UserId, num)
				local ls = player:FindFirstChild("leaderstats")
				local sv = ls and ls:FindFirstChild("Stage")
				if sv then
					sv.Value = num
				end
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		for userid, stage in pairs(playerstages) do
			if players:GetPlayerByUserId(userid) then
				saveplayerdata(userid, stage)
			end
		end
	end
end)

game:BindToClose(function()
	for userid, stage in pairs(playerstages) do
		saveplayerdata(userid, stage)
	end
end)