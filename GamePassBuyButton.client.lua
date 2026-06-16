local gamepassId = 3604233735
local marketplaceService = game:GetService("MarketplaceService")
local players = game:GetService("Players")

local player = players.LocalPlayer
local button = script.Parent
local clickSound = button:FindFirstChild("ClickSound")

if not player then
	return
end

button.MouseButton1Up:Connect(function()
	if clickSound then
		clickSound:Play()
	end
	marketplaceService:PromptGamePassPurchase(player, gamepassId)
end)