local marketplaceService = game:GetService("MarketplaceService")
local players = game:GetService("Players")
local serverStorage = game:GetService("ServerStorage")

local productId = 3604234208
local toolName = "SpeedCoil"

local cachedTool

local function getToolTemplate()
	if not cachedTool then
		cachedTool = serverStorage:FindFirstChild(toolName)
	end
	return cachedTool
end

local function giveToolToPlayer(player)
	local toolTemplate = getToolTemplate()
	if not toolTemplate then
		return false
	end

	local toolClone = toolTemplate:Clone()
	toolClone.Parent = player:WaitForChild("Backpack")
	return true
end

local function onProcessReceipt(receiptInfo)
	local player = players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotGranted
	end

	if receiptInfo.ProductId ~= productId then
		return Enum.ProductPurchaseDecision.NotGranted
	end

	local success = giveToolToPlayer(player)
	if not success then
		return Enum.ProductPurchaseDecision.NotGranted
	end

	return Enum.ProductPurchaseDecision.Granted
end

marketplaceService.ProcessReceipt = onProcessReceipt