local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinWorldGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 120)
frame.Position = UDim2.new(0, 10, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local dragging = false
local dragStart: Vector2?
local startPos: UDim2?

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

frame.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - (dragStart or Vector2.new(0, 0))
		frame.Position = UDim2.new(
			startPos?.X.Scale or 0,
			(startPos?.X.Offset or 0) + delta.X,
			startPos?.Y.Scale or 0,
			(startPos?.Y.Offset or 0) + delta.Y
		)
	end
end)

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, 0, 0, 30)
coinLabel.Position = UDim2.new(0, 0, 0, 5)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinLabel.TextSize = 18
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Parent = frame

local worldLabel = Instance.new("TextLabel")
worldLabel.Name = "WorldLabel"
worldLabel.Size = UDim2.new(1, 0, 0, 20)
worldLabel.Position = UDim2.new(0, 0, 0, 35)
worldLabel.BackgroundTransparency = 1
worldLabel.Text = "World 1"
worldLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
worldLabel.TextSize = 14
worldLabel.Font = Enum.Font.Gotham
worldLabel.Parent = frame

local teleportButton = Instance.new("TextButton")
teleportButton.Name = "TeleportButton"
teleportButton.Size = UDim2.new(1, -20, 0, 35)
teleportButton.Position = UDim2.new(0, 10, 0, 75)
teleportButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
teleportButton.Text = "Go to World 2 (500 coins)"
teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportButton.TextSize = 14
teleportButton.Font = Enum.Font.GothamBold
teleportButton.BorderSizePixel = 0
teleportButton.Visible = false
teleportButton.Parent = frame

teleportButton.MouseEnter:Connect(function()
	teleportButton.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
end)
teleportButton.MouseLeave:Connect(function()
	teleportButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
end)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
})
gradient.Parent = teleportButton

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = teleportButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 170, 0)
stroke.Thickness = 1
stroke.Transparency = 0.7
stroke.Parent = frame

local function UpdateUI()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local coinsValue = leaderstats:FindFirstChild("Coins")
	local worldValue = leaderstats:FindFirstChild("World")

	if coinsValue then
		coinLabel.Text = `Coins: {coinsValue.Value}`
		if coinsValue.Value >= 500 then
			teleportButton.Visible = true
			teleportButton.Text = "Go to World 2!"
		else
			teleportButton.Visible = false
		end
	end

	if worldValue then
		worldLabel.Text = `{worldValue.Value}`
	end
end

teleportButton.MouseButton1Click:Connect(function()
	teleportButton.Text = "Teleporting..."
	teleportButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	teleportButton.Active = false

	local teleportFunction = script.Parent.Parent:FindFirstChild("CoinWorldSystem")
	if teleportFunction then
		teleportFunction = teleportFunction:FindFirstChild("RequestWorld2Teleport")
	end

	if teleportFunction and teleportFunction:IsA("RemoteFunction") then
		local success, message = teleportFunction:InvokeServer()
		if not success then
			teleportButton.Text = message or "Can't teleport!"
			teleportButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			task.delay(2, function()
				teleportButton.Text = "Go to World 2!"
				teleportButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
				teleportButton.Active = true
			end)
		end
	else
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coinsValue = leaderstats:FindFirstChild("Coins")
			if coinsValue and coinsValue.Value >= 500 then
				teleportButton.Text = "Teleporting..."
			else
				teleportButton.Text = "Not enough coins!"
				task.delay(2, function()
					teleportButton.Text = "Go to World 2!"
					teleportButton.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
					teleportButton.Active = true
				end)
			end
		end
	end
end)

local function OnLeaderstatsChanged()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = player:WaitForChild("leaderstats", 10)
	end

	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue then
			coinsValue:GetPropertyChangedSignal("Value"):Connect(UpdateUI)
		end

		local worldValue = leaderstats:FindFirstChild("World")
		if worldValue then
			worldValue:GetPropertyChangedSignal("Value"):Connect(UpdateUI)
		end
		UpdateUI()
	end
end

OnLeaderstatsChanged()

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	OnLeaderstatsChanged()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		screenGui.Enabled = not screenGui.Enabled
	end
end)