--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local RemoteEvents = require(ReplicatedStorage.SniperDuelsRemotes)
local WeaponConfig = require(ReplicatedStorage:FindFirstChild("Config") or script.Parent.Parent.Config.WeaponConfig)

local function onClientStart()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	
	local success, gunController = pcall(function()
		return require(script.GunController)
	end)
	
	if not success then
		warn("Failed to load GunController")
	end
	
	RemoteEvents.ClientReady:FireServer()
	
	task.wait(1)
	
	if gunController then
		gunController:Initialize()
	end
	
	UserInputService.MouseIconEnabled = false
end

local gui = Instance.new("ScreenGui")
gui.Name = "Loader"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0, 50)
loadingLabel.Position = UDim2.new(0, 0, 0.5, -25)
loadingLabel.BackgroundTransparency = 1
loadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingLabel.TextScaled = true
loadingLabel.Font = Enum.Font.GothamBold
loadingLabel.Text = "Waiting for match..."
loadingLabel.Parent = gui

task.delay(1, function()
	onClientStart()
	gui:Destroy()
end)