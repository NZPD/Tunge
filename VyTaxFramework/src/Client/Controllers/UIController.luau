local Maid = require(game:GetService("ReplicatedStorage").VyTax.Maid)
local Signal = require(game:GetService("ReplicatedStorage").VyTax.Signal)

local UIController = {}
UIController.__index = UIController

function UIController.new(): typeof(UIController)
	return setmetatable({}, UIController)
end

function UIController:_init()
	self._maid = Maid.new()
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "VyTaxUI"
	self.ScreenGui.IgnoreGuiInset = true
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.Parent = self.Player:WaitForChild("PlayerGui")
	self._maid:GiveTask(self.ScreenGui)
end

function UIController:_start()
	print("[VyTax] UIController started for", self.Player.Name)
end

function UIController:CreateFrame(name: string, properties: {}): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	for prop, value in properties do
		frame[prop] = value
	end
	frame.Parent = self.ScreenGui
	self._maid:GiveTask(frame)
	return frame
end

function UIController:CreateButton(name: string, parent: Instance, properties: {}): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	for prop, value in properties do
		button[prop] = value
	end
	button.Parent = parent
	return button
end

function UIController:CreateLabel(name: string, parent: Instance, properties: {}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	for prop, value in properties do
		label[prop] = value
	end
	label.Parent = parent
	return label
end

function UIController:Notify(title: string, message: string, duration: number?)
	duration = duration or 3
	local frame = self:CreateFrame("Notification", {
		Size = UDim2.new(0, 300, 0, 80),
		Position = UDim2.new(0.5, -150, 0, 20),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	})
	frame.ZIndex = 10

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 18
	titleLabel.Parent = frame

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Position = UDim2.new(0, 0, 0, 30)
	msgLabel.Size = UDim2.new(1, 0, 0, 50)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text = message
	msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msgLabel.Font = Enum.Font.Gotham
	msgLabel.TextSize = 14
	msgLabel.TextWrapped = true
	msgLabel.Parent = frame

	task.delay(duration, function()
		frame:TweenPosition(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true, function()
			frame:Destroy()
		end)
	end)
end

function UIController:Destroy()
	self._maid:DoCleaning()
end

return UIController.new()