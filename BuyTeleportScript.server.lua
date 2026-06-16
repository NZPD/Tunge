local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local dev_product_id = 3604818416

local teleport_part: BasePart? = workspace:WaitForChild("End") :: BasePart?

local function teleportPlayer(player: Player)
	if not teleport_part then
		warn("Teleport part not found in workspace!")
		return
	end

	local character = player.Character
	if not character then
		task.wait(2)
		character = player.Character
	end

	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("Player's character or HumanoidRootPart not found!")
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	rootPart.CFrame = teleport_part.CFrame
end

local function processReceipt(receiptInfo: MarketplaceService.ProcessReceipt)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductType == Enum.ProductType.DeveloperProduct and receiptInfo.ProductId == dev_product_id then
		teleportPlayer(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.ProcessReceipt = processReceipt
print("Developer product teleporter script loaded. Product ID:", dev_product_id)