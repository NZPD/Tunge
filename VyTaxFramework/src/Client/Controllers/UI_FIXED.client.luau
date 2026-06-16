repeat task.wait() until game:IsLoaded()

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Configuration = ReplicatedStorage:FindFirstChild("Configuration")
if not Configuration then
	warn("Configuration folder not found in ReplicatedStorage")
	return
end

local GamepassData = Configuration:FindFirstChild("Gamepasses")
local TeamData = Configuration:FindFirstChild("TeamInfo")
local TeamEvent = Configuration:FindFirstChild("TeamEvent")
local EC_EventFolder = ReplicatedStorage:FindFirstChild("Events")

local success, gamepassInfo = pcall(require, GamepassData)
local success2, teamInfo = pcall(require, TeamData)
if not success or not success2 then
	warn("Failed to load configuration data")
	return
end

local ReportEvent = ReplicatedStorage:FindFirstChild("reportSubmitter")
local CodeFunction = ReplicatedStorage:FindFirstChild("codeSubmitter")
local ECEvent = EC_EventFolder and EC_EventFolder:FindFirstChild("EC_Event")

local blurEffect = Lighting:FindFirstChild("UIBlur")
if blurEffect then
	blurEffect.Enabled = false
end

local MainUI = script.Parent
if not MainUI then return end

local UIButtons = MainUI:FindFirstChild("Buttons")
local TopFrame = MainUI:FindFirstChild("TOP")
local SettingsUI = MainUI:FindFirstChild("Settings")
local StoreUI = MainUI:FindFirstChild("Store")
local TeamsUI = MainUI:FindFirstChild("Teams")
local CodesUI = MainUI:FindFirstChild("Codes")
local ReportUI = MainUI:FindFirstChild("Report")
local ECPanelUI = MainUI:FindFirstChild("EC_PANEL")

if not UIButtons or not TopFrame or not SettingsUI or not StoreUI or not TeamsUI then
	warn("Core UI elements missing")
	return
end

local SettingsButton = UIButtons:FindFirstChild("Settings")
local ShopButton = UIButtons:FindFirstChild("Shop")
local TeamsButton = UIButtons:FindFirstChild("Teams")
local CashLabel = UIButtons:FindFirstChild("Cash")

local CodesButton = TopFrame:FindFirstChild("Codes")
local ReportButton = TopFrame:FindFirstChild("Report")
local ECButton = TopFrame:FindFirstChild("EC")

local CustomToggle = SettingsUI:FindFirstChild("CustomToggle")
local SettingsContainer = SettingsUI:FindFirstChild("Settings")
local SettingsTemplate = SettingsUI:FindFirstChild("Template")

local StoreMainFrame = StoreUI:FindFirstChild("MainFrame")
local StoreDescFrame = StoreUI:FindFirstChild("DescriptionFrame")
local StoreTemplate = StoreMainFrame and StoreMainFrame:FindFirstChild("Template")

local TeamsScrollingFrame = TeamsUI:FindFirstChild("ScrollingFrame")
local TeamsTemplate = TeamsUI:FindFirstChild("Template")

local currentGamepass = nil
local currentSettingData = nil
local blurEnabled = false

local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POS_ABOVE = UDim2.new(0.5, 0, -0.6, 0)
local POS_CENTER = UDim2.new(0.5, 0, 0.5, 0)
local POS_BELOW = UDim2.new(0.5, 0, 1.6, 0)

local function showBlur()
	if not blurEnabled then
		if blurEffect then blurEffect.Enabled = true end
		blurEnabled = true
	end
end

local function hideBlur()
	if blurEnabled then
		if blurEffect then blurEffect.Enabled = false end
		blurEnabled = false
	end
end

local activeTweens = {}

local function tweenUI(frame, open)
	if not frame then return end
	frame.AnchorPoint = Vector2.new(0.5, 0.5)

	if activeTweens[frame] then
		activeTweens[frame]:Cancel()
		activeTweens[frame] = nil
	end

	if open then
		frame.Position = POS_ABOVE
		frame.Visible = true
		activeTweens[frame] = TweenService:Create(frame, TWEEN_INFO, {Position = POS_CENTER})
		activeTweens[frame].Completed:Once(function() activeTweens[frame] = nil end)
		activeTweens[frame]:Play()
		showBlur()
	else
		activeTweens[frame] = TweenService:Create(frame, TWEEN_INFO, {Position = POS_BELOW})
		activeTweens[frame].Completed:Once(function()
			frame.Visible = false
			frame.Position = POS_ABOVE
			activeTweens[frame] = nil
			hideBlur()
		end)
		activeTweens[frame]:Play()
	end
end

local function resetAllUI()
	SettingsUI.Visible = false
	StoreUI.Visible = false
	TeamsUI.Visible = false
	if CodesUI then CodesUI.Visible = false end
	if ReportUI then ReportUI.Visible = false end
	if ECPanelUI then ECPanelUI.Visible = false end
	currentGamepass = false
	currentSettingData = nil
	if CustomToggle then CustomToggle.Visible = false end
end

local function safeAnimatedClose(uiFrame)
	if not uiFrame then return end
	tweenUI(uiFrame, false)
end

local function closeAllAndOpen(uiFrame)
	resetAllUI()
	tweenUI(uiFrame, true)
end

local function setupCloseButton(uiFrame)
	if not uiFrame then return end
	local top = uiFrame:FindFirstChild("Top")
	local closeBtn = top and top:FindFirstChild("Close")
	if closeBtn then
		closeBtn.MouseButton1Click:Connect(function() safeAnimatedClose(uiFrame) end)
	end
end

local function loadTeams()
	if not TeamsTemplate or not TeamsScrollingFrame then return end
	local template = TeamsTemplate:Clone()
	template.Visible = true
	TeamsTemplate:Destroy()

	for name, data in teamInfo do
		local clone = template:Clone()
		clone.Name = name
		clone.Parent = TeamsScrollingFrame
		clone.Text = name:upper()

		local dropshadow = clone:FindFirstChild("DropShadowHolder")
		local logo = dropshadow and dropshadow:FindFirstChild("Logo")
		if logo and data.LogoID and type(data.LogoID) == "number" and data.LogoID > 0 then
			logo.Image = "rbxassetid://" .. tostring(data.LogoID)
			logo.Visible = true
			logo.BackgroundTransparency = 1
			logo.ZIndex = 10
		elseif logo then
			logo.Visible = false
		end

		clone.MouseButton1Click:Connect(function()
			if TeamEvent then TeamEvent:FireServer(name) end
		end)
	end
end

local function loadShop()
	if not StoreTemplate or not StoreMainFrame or not StoreDescFrame then return end
	local scrolling = StoreMainFrame:FindFirstChild("ScrollingFrame")
	if not scrolling then return end

	local template = StoreTemplate:Clone()
	template.Visible = true
	StoreTemplate:Destroy()

	for _, v in gamepassInfo do
		local clone = template:Clone()
		clone.Name = v.GamepassName
		clone.Parent = scrolling

		local dropshadow = clone:FindFirstChild("DropShadowHolder")
		local logo = dropshadow and dropshadow:FindFirstChild("Logo")
		if logo and v.GamepassIcon and type(v.GamepassIcon) == "number" and v.GamepassIcon > 0 then
			logo.Image = "rbxassetid://" .. tostring(v.GamepassIcon)
			logo.Visible = true
			logo.BackgroundTransparency = 1
			logo.ZIndex = 10
		elseif logo then
			logo.Visible = false
		end

		clone.MouseButton1Click:Connect(function()
			StoreDescFrame.Icon.Image = "rbxassetid://" .. tostring(v.GamepassIcon)
			StoreDescFrame.gName.Text = v.GamepassName
			StoreDescFrame.Description.Text = v.GamepassDescription
			StoreDescFrame.Purchase.Visible = true
			StoreDescFrame.Purchase.GamepassID = v.GamepassID
			currentGamepass = v
		end)
	end
end

local function loadSettings()
	local success, customSettings = pcall(require, script:FindFirstChild("CustomSettings"))
	if not success or not customSettings then
		warn("CustomSettings module not found")
		return
	end
	if not SettingsTemplate or not SettingsContainer then return end

	local template = SettingsTemplate:Clone()
	template.Visible = true
	SettingsTemplate:Destroy()

	for i, v in customSettings do
		local clone = template:Clone()
		clone.Parent = SettingsContainer
		clone.Text = v.SettingsName
		clone.Name = v.SettingsName
		clone.LinkedFunction.Value = i

		clone.MouseButton1Click:Connect(function()
			currentSettingData = {i, clone}
			local currentValue = clone.CurrentToggle.Value
			if CustomToggle then
				CustomToggle.Description.Text = v.SettingsDescription
				CustomToggle.Title.Text = v.SettingsName
				CustomToggle.Status.Text = "Status: " .. (currentValue and "ON" or "OFF")
				CustomToggle.Visible = true
			end
		end)
	end

	if CustomToggle then
		if CustomToggle.On then
			CustomToggle.On.MouseButton1Click:Connect(function()
				if not currentSettingData then return end
				CustomToggle.Status.Text = "Status: ON"
				local idx = currentSettingData[1]
				if customSettings[idx] then customSettings[idx].SettingsFunction(true) end
				currentSettingData[2].CurrentToggle.Value = true
			end)
		end
		if CustomToggle.Off then
			CustomToggle.Off.MouseButton1Click:Connect(function()
				if not currentSettingData then return end
				CustomToggle.Status.Text = "Status: OFF"
				local idx = currentSettingData[1]
				if customSettings[idx] then customSettings[idx].SettingsFunction(false) end
				currentSettingData[2].CurrentToggle.Value = false
			end)
		end
	end
end

if StoreDescFrame and StoreDescFrame:FindFirstChild("Purchase") then
	StoreDescFrame.Purchase.MouseButton1Click:Connect(function()
		if currentGamepass and currentGamepass.GamepassID then
			MarketplaceService:PromptGamePassPurchase(LocalPlayer, currentGamepass.GamepassID)
		end
	end)
end

setupCloseButton(TeamsUI)
setupCloseButton(SettingsUI)
setupCloseButton(StoreUI)
setupCloseButton(CodesUI)
setupCloseButton(ReportUI)
setupCloseButton(ECPanelUI)

if TeamsButton then
	TeamsButton.MouseButton1Click:Connect(function() closeAllAndOpen(TeamsUI) end)
end
if SettingsButton then
	SettingsButton.MouseButton1Click:Connect(function() closeAllAndOpen(SettingsUI) end)
end
if ShopButton then
	ShopButton.MouseButton1Click:Connect(function() closeAllAndOpen(StoreUI) end)
end
if CodesButton and CodesUI then
	CodesButton.MouseButton1Click:Connect(function() closeAllAndOpen(CodesUI) end)
end
if ReportButton and ReportUI then
	ReportButton.MouseButton1Click:Connect(function() closeAllAndOpen(ReportUI) end)
end
if ECButton and ECPanelUI then
	ECButton.MouseButton1Click:Connect(function() closeAllAndOpen(ECPanelUI) end)
end

local function updateReportUsers()
	if not ReportUI then return end
	local reportScrolling = ReportUI:FindFirstChild("Users") and ReportUI.Users:FindFirstChild("ScrollingFrame")
	if not reportScrolling then return end

	local template = reportScrolling:FindFirstChild("Template")
	if template and template:FindFirstChild("Template") then template = template.Template end
	if not template then return end

	for _, child in reportScrolling:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Template" then child:Destroy() end
	end

	for _, player in Players:GetPlayers() do
		local clone = template:Clone()
		clone.Parent = reportScrolling
		clone.Name = tostring(player.UserId)
		clone.Visible = true

		local s, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if s then clone.ImageLabel.Image = thumb end

		local rankText = clone:FindFirstChild("Rank")
		if rankText then
			local s2, rank = pcall(function() return player:GetRoleInGroup(35733760) end)
			rankText.Text = s2 and rank or ""
		end

		local usernameText = clone:FindFirstChild("Username")
		if usernameText then usernameText.Text = player.Name end

		local textBtn = clone:FindFirstChild("TextButton")
		if textBtn then
			textBtn.MouseButton1Click:Connect(function()
				local plrVal = ReportUI:FindFirstChild("PlrUserID")
				if plrVal then plrVal.Value = player.UserId end
			end)
		end
	end
end

local function updateECUsers()
	if not ECPanelUI then return end
	local ecScrolling = ECPanelUI:FindFirstChild("Users") and ECPanelUI.Users:FindFirstChild("ScrollingFrame")
	if not ecScrolling then return end

	local template = ecScrolling:FindFirstChild("Template")
	if not template then return end

	for _, child in ecScrolling:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Template" then child:Destroy() end
	end

	for _, player in Players:GetPlayers() do
		local clone = template:Clone()
		clone.Parent = ecScrolling
		clone.Name = tostring(player.UserId)
		clone.Visible = true

		local s, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size352x352)
		end)
		if s then clone.ImageLabel.Image = thumb end

		local rankText = clone:FindFirstChild("Rank")
		if rankText then
			local s2, rank = pcall(function() return player:GetRoleInGroup(35733760) end)
			rankText.Text = s2 and rank or ""
		end

		local usernameText = clone:FindFirstChild("Username")
		if usernameText then usernameText.Text = player.Name end

		local textBtn = clone:FindFirstChild("TextButton")
		if textBtn then
			textBtn.MouseButton1Click:Connect(function()
				local selectedVal = clone:FindFirstChild("Selected")
				if selectedVal then selectedVal.Value = not selectedVal.Value end
			end)
		end

		local selectedVal = clone:FindFirstChild("Selected")
		if selectedVal then
			selectedVal.Value = false
			selectedVal:GetPropertyChangedSignal("Value"):Connect(function()
				TweenService:Create(clone, TWEEN_INFO, {
					Transparency = selectedVal.Value and 0.4 or 0.6,
					BackgroundColor3 = selectedVal.Value and Color3.new(0.184, 0.184, 0.184) or Color3.new(0.035, 0.035, 0.035)
				}):Play()
			end)
		end
	end
end

-- Report System
if ReportUI then
	local reportScrolling = ReportUI:FindFirstChild("Users") and ReportUI.Users:FindFirstChild("ScrollingFrame")
	local reportPopup = ReportUI:FindFirstChild("Result")
	local reportInput = ReportUI:FindFirstChild("Input")
	local reportReasonBox = reportInput and reportInput:FindFirstChild("TextBox")
	local reportSubmitBtn = reportInput and reportInput:FindFirstChild("TextButton")
	local reportRefreshBtn = reportInput and reportInput:FindFirstChild("Refresh")

	task.spawn(function() pcall(updateReportUsers) end)

	if reportRefreshBtn then
		reportRefreshBtn.MouseButton1Click:Connect(function() pcall(updateReportUsers) end)
	end

	if reportSubmitBtn and reportReasonBox then
		reportSubmitBtn.MouseButton1Click:Connect(function()
			local cooldown = LocalPlayer:FindFirstChild("Cooldowns") and LocalPlayer.Cooldowns:FindFirstChild("ReportCooldown")
			if cooldown and cooldown.Value then
				if reportPopup then
					reportPopup.Visible = true
					local textLabel = reportPopup:FindFirstChild("text")
					if textLabel then textLabel.Text = "You are clicking too fast!" end
				end
				return
			end

			local plrVal = ReportUI:FindFirstChild("PlrUserID")
			local targetID = plrVal and plrVal.Value
			local reason = reportReasonBox.Text
			if not targetID or reason == "" or reason == "Reason" then return end
			if ReportEvent then ReportEvent:FireServer(targetID, reason) end
			reportReasonBox.Text = ""
			safeAnimatedClose(ReportUI)
		end)
	end

	if reportPopup then
		local popupBtn = reportPopup:FindFirstChild("TextButton")
		if popupBtn then
			popupBtn.MouseButton1Click:Connect(function() reportPopup.Visible = false end)
		end
	end
end

-- Event Coordinator System
if ECPanelUI then
	local ecScrolling = ECPanelUI:FindFirstChild("Users") and ECPanelUI.Users:FindFirstChild("ScrollingFrame")
	local ecResult = ECPanelUI:FindFirstChild("Result")
	local ecInput = ECPanelUI:FindFirstChild("Input")

	task.spawn(function()
		pcall(updateECUsers)
		if ecInput then
			local refreshBtn = ecInput:FindFirstChild("REFRESH")
			if refreshBtn then refreshBtn.MouseButton1Click:Connect(function() pcall(updateECUsers) end) end
		end
	end)

	if ecInput then
		local cancelBtn = ecInput:FindFirstChild("Cancel")
		if cancelBtn then
			cancelBtn.MouseButton1Click:Connect(function()
				if ecResult then
					ecResult.Visible = true
					ecResult.text.Text = "Cancelled Event!"
				end
				for _, frame in ecScrolling:GetChildren() do
					if frame:IsA("Frame") and frame:FindFirstChild("Selected") then frame.Selected.Value = false end
				end
			end)
		end

		local logBtn = ecInput:FindFirstChild("LOG")
		if logBtn then
			logBtn.MouseButton1Click:Connect(function()
				if not LocalPlayer:IsInGroup(35707664) then
					if ecResult then
						ecResult.Visible = true
						ecResult.text.Text = "403 Unauthorized! Please wait for the RobloxAPI to register you."
					end
					return
				end

				local selectedUsers = {}
				for _, user in ecScrolling:GetChildren() do
					if user:IsA("Frame") then
						local selectedVal = user:FindFirstChild("Selected")
						if selectedVal and selectedVal.Value then
							table.insert(selectedUsers, tonumber(user.Name) or user.Name)
						end
					end
				end

				local coHost = ecInput:FindFirstChild("TextBox") and ecInput.TextBox.Text or ""
				if ECEvent then ECEvent:FireServer(selectedUsers, coHost) end
				if ecInput.TextBox then ecInput.TextBox.Text = "" end
				safeAnimatedClose(ECPanelUI)
			end)
		end
	end

	if ECEvent then
		ECEvent.OnClientEvent:Connect(function(reply)
			if ecResult then
				ecResult.Visible = true
				ecResult.text.Text = reply
			end
		end)
	end

	if ecResult then
		local resultBtn = ecResult:FindFirstChild("TextButton")
		if resultBtn then resultBtn.MouseButton1Click:Connect(function() ecResult.Visible = false end) end
	end
end

local function refreshAll()
	pcall(function()
		if ReportUI then updateReportUsers() end
		if ECPanelUI then updateECUsers() end
	end)
end

Players.PlayerAdded:Connect(refreshAll)
Players.PlayerRemoving:Connect(refreshAll)

-- Code System
if CodesUI then
	local codeInputBox = CodesUI:FindFirstChild("TextBox")
	local codeSubmitBtn = CodesUI:FindFirstChild("Submit")

	if codeSubmitBtn and codeInputBox then
		codeSubmitBtn.MouseButton1Click:Connect(function()
			local code = codeInputBox.Text
			if code == "" or code == "Enter Code Here" then return end
			if CodeFunction then
				local success, response = pcall(function() return CodeFunction:InvokeServer(code) end)
				if success then
					codeInputBox.Text = response or ""
					task.wait(1.5)
					codeInputBox.Text = ""
				else
					codeInputBox.Text = "Error processing code"
					task.wait(1.5)
					codeInputBox.Text = ""
				end
			end
		end)
	end
end

-- Cash Display
if CashLabel and CashLabel:IsA("TextLabel") then
	local hiddenStats = LocalPlayer:WaitForChild("HiddenStats", 10)
	if hiddenStats then
		local cashValue = hiddenStats:WaitForChild("Cash", 10)
		if cashValue then
			cashValue:GetPropertyChangedSignal("Value"):Connect(function()
				if CashLabel then CashLabel.Text = "Cash: $" .. tostring(cashValue.Value) end
			end)
			CashLabel.Text = "Cash: $" .. tostring(cashValue.Value)
		end
	end
end

task.spawn(function()
	loadTeams()
	loadShop()
	loadSettings()
end)