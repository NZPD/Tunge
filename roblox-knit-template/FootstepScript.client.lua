local players = game:GetService("Players")
local run_service = game:GetService("RunService")

local player = players.LocalPlayer
local footstep_sound_id = "rbxassetid://132354901314863"
local step_interval = 0.45
local run_interval = 0.3

local function setup_character(character)
	if not character then return end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	local root_part = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root_part then return end

	local sound = Instance.new("Sound")
	sound.SoundId = footstep_sound_id
	sound.Volume = 0.5
	sound.Parent = root_part

	local last_step_time = 0

	local function play_footstep()
		local now = tick()
		local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
		local interval = speed > 20 and run_interval or step_interval

		if now - last_step_time >= interval then
			last_step_time = now
			sound:Play()
		end
	end

	humanoid.Running:Connect(function(speed)
		if speed > 0 then
			play_footstep()
		end
	end)

	run_service.Heartbeat:Connect(function()
		local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
		if speed > 0 then
			play_footstep()
		end
	end)
end

if player.Character then
	setup_character(player.Character)
end

player.CharacterAdded:Connect(setup_character)