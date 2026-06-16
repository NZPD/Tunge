local players = game:GetService("Players")

local part = script.Parent

local player_checkpoints = {}

local function to_int(value)
	return math.floor(value * 1000) / 1000
end

local function teleport_to_checkpoint(character, data)
	if not character or not data then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local root_part = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root_part then return end

	task.wait(0.1)

	root_part.CFrame = data.cframe
	humanoid:MoveTo(data.position)
end

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end

	local cframe = part.CFrame
	local rotation = cframe - cframe.Position
	local spawn_cframe = rotation + (cframe.Position + Vector3.new(0, 3, 0))

	player_checkpoints[player] = {
		cframe = spawn_cframe,
		position = Vector3.new(
			to_int(spawn_cframe.Position.X),
			to_int(spawn_cframe.Position.Y),
			to_int(spawn_cframe.Position.Z)
		),
	}

	player.RespawnLocation = part

	print(("[Checkpoint] %s saved checkpoint at %s"):format(player.Name, tostring(part.Name)))
end)

players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		teleport_to_checkpoint(character, player_checkpoints[player])
	end)
end)

for _, player in ipairs(players:GetPlayers()) do
	local data = player_checkpoints[player]
	if data and player.Character then
		teleport_to_checkpoint(player.Character, data)
	end
end