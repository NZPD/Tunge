local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local openEvent = ReplicatedStorage:FindFirstChild("OpenWorldUI")
if not openEvent then
	openEvent = Instance.new("RemoteEvent")
	openEvent.Name = "OpenWorldUI"
	openEvent.Parent = ReplicatedStorage
end

local teleportPart = script.Parent

teleportPart.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		character = character.Parent
		if character then
			humanoid = character:FindFirstChildWhichIsA("Humanoid")
		end
	end
	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			openEvent:FireClient(player)
		end
	end
end)