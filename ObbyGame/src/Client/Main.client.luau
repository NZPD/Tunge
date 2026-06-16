--!strict
-- Main.client.luau
-- Entry point for the Obby Framework client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Wait for shared modules to be available
local obbyShared = ReplicatedStorage:WaitForChild("ObbyShared")

local Types = require(obbyShared.Types)
local Constants = require(obbyShared.Constants)
local RemoteEvents = require(obbyShared.RemoteEvents)

local GuiController = require(script.Parent.GuiController)

-- Initialize GUI
local guiInitialized = GuiController.Init()
if not guiInitialized then
	warn("[Client] Failed to initialize GUI!")
end

-- Detect kill volumes and falling
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local function setupCharacter(char: Model)
	local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
	local humanoid = char:WaitForChild("Humanoid")

	-- Detect falling (Y position below kill zone)
	local lastY = humanoidRootPart.Position.Y

	local heartbeatConn = RunService.Heartbeat:Connect(function()
		if not humanoidRootPart or not humanoidRootPart.Parent then
			heartbeatConn:Disconnect()
			return
		end

		local currentY = humanoidRootPart.Position.Y
		if currentY < Constants.FALL_DETECTION_HEIGHT then
			-- Player fell off the map
			RemoteEvents.Fire(Constants.REMOTE_EVENTS.PLAYER_FELL)
			RemoteEvents.Fire(Constants.REMOTE_EVENTS.REQUEST_RESPAWN)
		end
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(function(newChar: Model)
	setupCharacter(newChar)
end)

-- Stage detection via Touch events on stage parts
local function onCharacterTouched(touchedPart: BasePart)
	if not touchedPart then return end

	-- Check if it's a stage part via tag
	local isStage = touchedPart:GetAttribute("StageNumber") ~= nil
	if isStage then
		local stageNumber = touchedPart:GetAttribute("StageNumber") :: number
		RemoteEvents.Fire(Constants.REMOTE_EVENTS.STAGE_REACHED, stageNumber)
	end

	-- Check if it's the finish line
	if touchedPart:GetAttribute("IsFinishLine") == true then
		RemoteEvents.Fire(Constants.REMOTE_EVENTS.PLAYER_FINISHED)
	end

	-- Check if it's a checkpoint
	if touchedPart:GetAttribute("IsCheckpoint") == true then
		RemoteEvents.Fire(Constants.REMOTE_EVENTS.CHECKPOINT_PASSED, touchedPart.Name)
	end
end

-- Connect touch detection when character loads
local function connectTouchDetection(char: Model)
	local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
	if humanoidRootPart then
		local touchConn = humanoidRootPart.Touched:Connect(onCharacterTouched)
		char:SetAttribute("TouchConnection", touchConn)
	end
end

if character then
	connectTouchDetection(character)
end

player.CharacterAdded:Connect(function(newChar: Model)
	-- Clean up old connection
	local oldChar = character
	if oldChar then
		local oldConn = oldChar:GetAttribute("TouchConnection")
		if oldConn then
			oldConn:Disconnect()
		end
	end
	character = newChar
	connectTouchDetection(newChar)
end)

print("[Client] Obby Framework client initialized!")