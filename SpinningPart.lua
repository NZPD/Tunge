local part = script.Parent
local rotationSpeed = 45
local riders = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

RunService.Heartbeat:Connect(function(deltaTime)
	local rotation = CFrame.Angles(0, math.rad(rotationSpeed * deltaTime), 0)
	part.CFrame = part.CFrame * rotation

	local angularVelocity = math.rad(rotationSpeed)
	for player, velocity in pairs(riders) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local relativePos = part.CFrame:PointToObjectSpace(hrp.Position)
			local radius = Vector3.new(-relativePos.Z, 0, relativePos.X)
			local tangentialVelocity = radius * angularVelocity
			velocity.VectorVelocity = part.CFrame:VectorToWorldSpace(tangentialVelocity)
		end
	end
end)

part.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	local player = Players:GetPlayerFromCharacter(character)
	if not player or riders[player] then return end

	if humanoidRootPart:FindFirstChild("SpinVelocity") then return end

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "SpinVelocity"
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.VectorVelocity = Vector3.new()
	velocity.MaxForce = 10000
	velocity.Parent = humanoidRootPart

	riders[player] = velocity

	character.Humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Freefall or
		   newState == Enum.HumanoidStateType.Jumping or
		   newState == Enum.HumanoidStateType.Physics then
			velocity:Destroy()
			riders[player] = nil
		end
	end)
end)