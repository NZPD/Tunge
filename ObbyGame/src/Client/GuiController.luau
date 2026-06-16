--!strict
-- GuiController.luau
-- Client-side GUI management for the Obby Framework

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Types = require(ReplicatedStorage.ObbyShared.Types)
local Constants = require(ReplicatedStorage.ObbyShared.Constants)
local RemoteEvents = require(ReplicatedStorage.ObbyShared.RemoteEvents)

local GuiController = {}
GuiController.__index = GuiController

-- Main GUI references
local screenGui: ScreenGui?
local mainFrame: Frame?
local timerLabel: TextLabel?
local stageLabel: TextLabel?
local notificationFrame: Frame?
local notificationLabel: TextLabel?
local leaderboardFrame: ScrollingFrame?
local leaderboardList: UIListLayout?
local leaderboardEntries: { [number]: Frame } = {}

local connections: { RBXScriptConnection } = {}
local gameActive: boolean = false
local startTime: number = 0
local notificationQueue: { string } = {}
local isNotifying: boolean = false

--[[
	Initializes the GUI controller.
]]
function GuiController.Init(): boolean
	print("[GuiController] Initializing...")

	local success, err = pcall(function()
		GuiController._CreateMainGUI()
		GuiController._SetupRemoteEvents()
		GuiController._CreateLeaderboardUI()
	end)

	if not success then
		warn(`[GuiController] Init failed: {err}`)
		return false
	end

	print("[GuiController] Initialized!")
	return true
end

--[[
	Creates the main GUI elements.
]]
function GuiController._CreateMainGUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ObbyGUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Main container
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = screenGui

	-- Top bar (timer, stage info)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 60)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topBar.BackgroundTransparency = 0.5
	topBar.BorderSizePixel = 0
	topBar.Parent = mainFrame

	-- Timer label (left side)
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0, 200, 1, 0)
	timerLabel.Position = UDim2.new(0, 20, 0, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "0:00.00"
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextSize = 32
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Parent = topBar

	-- Stage label (right side)
	stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(0, 300, 1, 0)
	stageLabel.Position = UDim2.new(1, -320, 0, 0)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "Stage: 1 / 10"
	stageLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	stageLabel.TextSize = 24
	stageLabel.TextXAlignment = Enum.TextXAlignment.Right
	stageLabel.Font = Enum.Font.GothamBold
	stageLabel.Parent = topBar

	-- Status label (center)
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(0, 300, 1, 0)
	statusLabel.Position = UDim2.new(0.5, -150, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "WAITING FOR START"
	statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	statusLabel.TextSize = 20
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = topBar

	-- Notification frame (center of screen)
	notificationFrame = Instance.new("Frame")
	notificationFrame.Name = "NotificationFrame"
	notificationFrame.Size = UDim2.new(0, 400, 0, 80)
	notificationFrame.Position = UDim2.new(0.5, -200, 0.4, -40)
	notificationFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	notificationFrame.BackgroundTransparency = 0.8
	notificationFrame.BorderSizePixel = 0
	notificationFrame.Visible = false
	notificationFrame.Parent = mainFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = notificationFrame

	notificationLabel = Instance.new("TextLabel")
	notificationLabel.Name = "NotificationLabel"
	notificationLabel.Size = UDim2.new(1, -20, 1, -20)
	notificationLabel.Position = UDim2.new(0, 10, 0, 10)
	notificationLabel.BackgroundTransparency = 1
	notificationLabel.Text = ""
	notificationLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notificationLabel.TextSize = 24
	notificationLabel.TextWrapped = true
	notificationLabel.Font = Enum.Font.GothamBold
	notificationLabel.Parent = notificationFrame

	-- Start countdown overlay
	local startOverlay = Instance.new("Frame")
	startOverlay.Name = "StartOverlay"
	startOverlay.Size = UDim2.new(1, 0, 1, 0)
	startOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	startOverlay.BackgroundTransparency = 0.6
	startOverlay.Visible = false
	startOverlay.Parent = mainFrame

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(1, 0, 1, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "3"
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextSize = 120
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.Parent = startOverlay
end

--[[
	Creates the leaderboard UI.
]]
function GuiController._CreateLeaderboardUI()
	-- Leaderboard panel
	local lbPanel = Instance.new("Frame")
	lbPanel.Name = "LeaderboardPanel"
	lbPanel.Size = UDim2.new(0, 300, 0, 400)
	lbPanel.Position = UDim2.new(0, 20, 0.5, -200)
	lbPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lbPanel.BackgroundTransparency = 0.7
	lbPanel.BorderSizePixel = 0
	lbPanel.Parent = mainFrame

	local lbCorner = Instance.new("UICorner")
	lbCorner.CornerRadius = UDim.new(0, 12)
	lbCorner.Parent = lbPanel

	local lbTitle = Instance.new("TextLabel")
	lbTitle.Name = "LBTitle"
	lbTitle.Size = UDim2.new(1, -20, 0, 40)
	lbTitle.Position = UDim2.new(0, 10, 0, 10)
	lbTitle.BackgroundTransparency = 1
	lbTitle.Text = "🏆 Leaderboard"
	lbTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
	lbTitle.TextSize = 22
	lbTitle.Font = Enum.Font.GothamBold
	lbTitle.Parent = lbPanel

	leaderboardFrame = Instance.new("ScrollingFrame")
	leaderboardFrame.Name = "LBEntries"
	leaderboardFrame.Size = UDim2.new(1, -20, 1, -60)
	leaderboardFrame.Position = UDim2.new(0, 10, 0, 50)
	leaderboardFrame.BackgroundTransparency = 1
	leaderboardFrame.BorderSizePixel = 0
	leaderboardFrame.ScrollBarThickness = 4
	leaderboardFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	leaderboardFrame.Parent = lbPanel

	leaderboardList = Instance.new("UIListLayout")
	leaderboardList.Padding = UDim.new(0, 4)
	leaderboardList.SortOrder = Enum.SortOrder.LayoutOrder
	leaderboardList.Parent = leaderboardFrame
end

--[[
	Sets up remote event listeners.
]]
function GuiController._SetupRemoteEvents()
	RemoteEvents.Init()

	RemoteEvents.OnClientEvent(Constants.REMOTE_EVENTS.GAME_STATE_CHANGED, function(state: string)
		GuiController._OnGameStateChanged(state :: Types.GameState)
	end)

	RemoteEvents.OnClientEvent(Constants.REMOTE_EVENTS.SYNC_PROGRESS, function(progress: Types.PlayerProgress)
		GuiController._UpdateProgress(progress)
	end)

	RemoteEvents.OnClientEvent(Constants.REMOTE_EVENTS.PLAYER_FINISHED, function(finalTime: number, isNewBest: boolean)
		GuiController._ShowFinishNotification(finalTime, isNewBest)
	end)

	RemoteEvents.OnClientEvent(Constants.REMOTE_EVENTS.LEADERBOARD_UPDATE, function(data: { Types.LeaderboardEntry })
		GuiController._UpdateLeaderboard(data)
	end)

	-- Timer update loop
	local heartbeatConn = RunService.Heartbeat:Connect(function()
		GuiController._UpdateTimer()
	end)
	table.insert(connections, heartbeatConn)

	-- Respawn keybind (R key)
	local inputConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.R and gameActive then
			RemoteEvents.Fire(Constants.REMOTE_EVENTS.REQUEST_RESPAWN)
		end
	end)
	table.insert(connections, inputConn)
end

--[[
	Handles game state changes.
]]
function GuiController._OnGameStateChanged(state: Types.GameState)
	local statusLabel = mainFrame and mainFrame:FindFirstChild("TopBar"):FindFirstChild("StatusLabel")
	if not statusLabel then return end

	if state == "Waiting" then
		gameActive = false
		statusLabel.Text = "⏳ WAITING FOR START"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		timerLabel.Text = "0:00.00"
		stageLabel.Text = "Stage: 0 / 10"
		GuiController._ShowNotification("Waiting for players...", 3)
	elseif state == "Playing" then
		gameActive = true
		startTime = tick()
		statusLabel.Text = "🟢 PLAYING"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		GuiController._ShowNotification("GO! 🏃‍♂️", 2)
	elseif state == "Finished" then
		gameActive = false
		statusLabel.Text = "🏁 FINISHED"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 50)
	end
end

--[[
	Updates the timer display.
]]
function GuiController._UpdateTimer()
	if not gameActive or not timerLabel then return end

	local elapsed = tick() - startTime
	local minutes = math.floor(elapsed / 60)
	local seconds = elapsed % 60
	timerLabel.Text = string.format("%d:%05.2f", minutes, seconds)
end

--[[
	Updates the progress display.
]]
function GuiController._UpdateProgress(progress: Types.PlayerProgress)
	if not stageLabel then return end
	stageLabel.Text = `Stage: {progress.CurrentStage} / {Constants.DEFAULT_CONFIG.TotalStages}`
	GuiController._ShowNotification(`Stage {progress.CurrentStage} cleared! ✨`, 2)
end

--[[
	Shows the finish notification.
]]
function GuiController._ShowFinishNotification(finalTime: number, isNewBest: boolean)
	local minutes = math.floor(finalTime / 60)
	local seconds = finalTime % 60
	local timeStr = string.format("%d:%05.2f", minutes, seconds)
	local message = isNewBest and `🏆 New Best! {timeStr}!` or `Finished! Time: {timeStr}`
	GuiController._ShowNotification(message, 5)
end

--[[
	Shows a notification on screen.
]]
function GuiController._ShowNotification(text: string, duration: number)
	if not notificationLabel or not notificationFrame then return end

	notificationLabel.Text = text
	notificationFrame.Visible = true

	-- Cancel any existing hide
	task.delay(duration, function()
		if notificationFrame then
			notificationFrame.Visible = false
		end
	end)
end

--[[
	Updates the leaderboard UI.
]]
function GuiController._UpdateLeaderboard(data: { Types.LeaderboardEntry })
	if not leaderboardFrame then return end

	-- Clear existing entries
	for _, entry in leaderboardEntries do
		entry:Destroy()
	end
	table.clear(leaderboardEntries)

	-- Create new entries
	for rank, entry in data do
		if rank > 10 then break end -- Top 10

		local entryFrame = Instance.new("Frame")
		entryFrame.Name = `Entry_{rank}`
		entryFrame.Size = UDim2.new(1, 0, 0, 36)
		entryFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		entryFrame.BackgroundTransparency = 0.9
		entryFrame.BorderSizePixel = 0
		entryFrame.Parent = leaderboardFrame

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "Rank"
		rankLabel.Size = UDim2.new(0, 30, 1, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Text = `#{rank}`
		rankLabel.TextColor3 = rank <= 3 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(200, 200, 200)
		rankLabel.TextSize = 18
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.Parent = entryFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -120, 1, 0)
		nameLabel.Position = UDim2.new(0, 35, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = entry.PlayerName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.Parent = entryFrame

		local timeLabel = Instance.new("TextLabel")
		timeLabel.Name = "Time"
		timeLabel.Size = UDim2.new(0, 80, 1, 0)
		timeLabel.Position = UDim2.new(1, -85, 0, 0)
		timeLabel.BackgroundTransparency = 1
		local mins = math.floor(entry.FinalTime / 60)
		local secs = entry.FinalTime % 60
		timeLabel.Text = string.format("%d:%05.2f", mins, secs)
		timeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		timeLabel.TextSize = 16
		timeLabel.Font = Enum.Font.GothamBold
		timeLabel.Parent = entryFrame

		leaderboardEntries[rank] = entryFrame
	end

	-- Update canvas size
	leaderboardFrame.CanvasSize = UDim2.new(0, 0, 0, #data * 40)
end

--[[
	Shows a countdown with overlay.
]]
function GuiController.ShowCountdown(seconds: number)
	local mainFrame = mainFrame
	if not mainFrame then return end

	local startOverlay = mainFrame:FindFirstChild("StartOverlay") :: Frame?
	if not startOverlay then return end

	local countdownLabel = startOverlay:FindFirstChild("CountdownLabel") :: TextLabel?
	if not countdownLabel then return end

	startOverlay.Visible = true

	coroutine.wrap(function()
		for i = seconds, 0, -1 do
			countdownLabel.Text = i > 0 and tostring(i) or "GO!"
			countdownLabel.TextColor3 = i > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 255, 100)
			task.wait(1)
		end
		startOverlay.Visible = false
	end)()
end

--[[
	Cleans up the GUI controller.
]]
function GuiController.Destroy()
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
	for _, conn in connections do
		conn:Disconnect()
	end
	table.clear(connections)
	table.clear(leaderboardEntries)
end

return GuiController