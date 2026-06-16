local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local COINS_PER_RE3 = 10
local COINS_FOR_WORLD_2 = 500
local RE3_TAG = "Re3"
local WORLD_2_PLACE_ID = 0

local playerCoins: { [number]: number } = {}
local touchConnections: { [Instance]: RBXScriptConnection } = {}

function CreateLeaderstats(player: Player)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		existing:Destroy()
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	if playerCoins[player.UserId] ~= nil then
		coins.Value = playerCoins[player.UserId]
	end

	local world = Instance.new("StringValue")
	world.Name = "World"
	world.Value = "World 1"
	world.Parent = leaderstats
end

function OnRe3Touched(otherPart: BasePart, re3Part: Instance)
	local model = otherPart.Parent
	if not model then return end

	local humanoid = model:FindFirstChild("Humanoid")
	if not humanoid or not humanoid:IsA("Humanoid") then return end

	local player = Players:GetPlayerFromCharacter(model)
	if not player then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue or not coinsValue:IsA("NumberValue") then return end

	coinsValue.Value += COINS_PER_RE3
	playerCoins[player.UserId] = coinsValue.Value

	if coinsValue.Value >= COINS_FOR_WORLD_2 then
		local worldValue = leaderstats:FindFirstChild("World")
		if worldValue then
			worldValue.Value = "World 2"

			local notification = Instance.new("Message")
			notification.Text = `You have {coinsValue.Value} coins! You can now go to World 2!`
			notification.Parent = player:WaitForChild("PlayerGui")

			task.delay(5, function()
				if notification and notification.Parent then
					notification:Destroy()
				end
			end)
		end
	end
end

function TeleportToWorld2(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	if not coinsValue then return end

	if coinsValue.Value < COINS_FOR_WORLD_2 then return end
	if WORLD_2_PLACE_ID == 0 then return end

	TeleportService:Teleport(WORLD_2_PLACE_ID, player)
end

function SetupRe3Part(re3Part: Instance)
	if not re3Part:IsA("BasePart") then return end

	re3Part.CanCollide = false
	re3Part.Anchored = true
	re3Part.Material = Enum.Material.Neon
	re3Part.Color = Color3.fromRGB(255, 170, 0)

	local existingConn = touchConnections[re3Part]
	if existingConn then
		existingConn:Disconnect()
	end

	local conn = re3Part.Touched:Connect(function(otherPart)
		OnRe3Touched(otherPart, re3Part)
	end)
	touchConnections[re3Part] = conn
end

function ScanForRe3Parts()
	for part, conn in touchConnections do
		conn:Disconnect()
	end
	table.clear(touchConnections)

	local re3Parts = CollectionService:GetTagged(RE3_TAG)
	for _, part in re3Parts do
		SetupRe3Part(part)
	end
end

function OnPlayerAdded(player: Player)
	CreateLeaderstats(player)

	local remote = Instance.new("RemoteEvent")
	remote.Name = "TeleportToWorld2"
	remote.Parent = player:WaitForChild("PlayerGui")
end

function OnPlayerRemoving(player: Player)
	playerCoins[player.UserId] = nil
end

function Init()
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end

	ScanForRe3Parts()

	CollectionService:GetInstanceAddedSignal(RE3_TAG):Connect(function(instance)
		SetupRe3Part(instance)
	end)

	CollectionService:GetInstanceRemovedSignal(RE3_TAG):Connect(function(instance)
		local conn = touchConnections[instance]
		if conn then
			conn:Disconnect()
			touchConnections[instance] = nil
		end
	end)

	local teleportFunction = Instance.new("RemoteFunction")
	teleportFunction.Name = "RequestWorld2Teleport"
	teleportFunction.Parent = script

	teleportFunction.OnServerInvoke = function(player: Player): (boolean, string)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return false, "No leaderstats found"
		end

		local coinsValue = leaderstats:FindFirstChild("Coins")
		if not coinsValue then
			return false, "No Coins value found"
		end

		if coinsValue.Value < COINS_FOR_WORLD_2 then
			return false, `You need {COINS_FOR_WORLD_2} coins! You have {coinsValue.Value}`
		end

		if WORLD_2_PLACE_ID == 0 then
			return false, "World 2 is not set up yet!"
		end

		TeleportToWorld2(player)
		return true, "Teleporting to World 2!"
	end
end

local success, err = pcall(Init)
if not success then
	warn(`[CoinWorldSystem] Failed to initialize: {err}`)
	error(`[CoinWorldSystem] Initialization failed: {err}`)
end