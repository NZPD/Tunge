local Loader = require(game:GetService("ReplicatedStorage").VyTax.Loader)

local framework = Loader.new()

framework:LoadServices(
	script.Parent.Services
)

framework:Start()

game:GetService("Players").PlayerAdded:Connect(function(player)
	print(("[VyTax] %s joined the game"):format(player.Name))
end)

task.spawn(function()
	while task.wait(300) do
		local count = 0
		for _ in game:GetService("Players"):GetPlayers() do count += 1 end
		print(("[VyTax] Players online: %d"):format(count))
	end
end)