local marketplaceService = game:GetService("MarketplaceService")
local players = game:GetService("Players")

local productId = 0000000000
local cooldownTime = 5

local cooldowns = {}

local function killAllPlayers(sourcePlayer)
	for _, otherPlayer in ipairs(players:GetPlayers()) do
		if otherPlayer ~= sourcePlayer then
			local character = otherPlayer.Character
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
				end
			end
		end
	end
end

local function onCooldown(playerId)
	local lastUsed = cooldowns[playerId]
	if not lastUsed then
		return false
	end
	return os.time() - lastUsed < cooldownTime
end

local function onProcessReceipt(receiptInfo)
	local player = players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		warn("[KillAllHandler] Receipt from unknown player (UserId: " .. receiptInfo.PlayerId .. ")")
		return Enum.ProductPurchaseDecision.NotGranted
	end

	if receiptInfo.ProductId ~= productId then
		return Enum.ProductPurchaseDecision.NotGranted
	end

	if onCooldown(receiptInfo.PlayerId) then
		print("[KillAllHandler] " .. player.Name .. " tried to buy kill all on cooldown - refunded")
		return Enum.ProductPurchaseDecision.Granted
	end

	cooldowns[receiptInfo.PlayerId] = os.time()

	killAllPlayers(player)

	print("[KillAllHandler] " .. player.Name .. " purchased kill all - killed everyone")

	return Enum.ProductPurchaseDecision.Granted
end

local function validateSetup()
	if productId == 0 or productId == 0000000000 then
		warn("[KillAllHandler] WARNING: productId is still set to the default value! Set it to your actual dev product ID.")
	else
		print("[KillAllHandler] Ready - Product ID: " .. productId)
	end
end

marketplaceService.ProcessReceipt = onProcessReceipt

validateSetup()

print("[KillAllHandler] Initialized - listening for purchases")
