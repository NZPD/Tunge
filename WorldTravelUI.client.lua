local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
	warn("WorldTravelUI: This must be a LocalScript in StarterGui. LocalPlayer is nil!")
	return
end
local playerGui = player:WaitForChild("PlayerGui")

local openEvent = ReplicatedStorage:WaitForChild("OpenWorldUI")

local hasSquishAccess = false
local squishWorldId = 1234567890

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WorldTravelUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = true
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.IgnoreGuiInset = true

local openBtn = Instance.new("ImageButton")
openBtn.Size = UDim2.new(0, 60, 0, 60)
openBtn.Position = UDim2.new(1, -75, 0, 10)
openBtn.BackgroundTransparency = 0.3
openBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
openBtn.Image = "rbxassetid://5093544483"
openBtn.ImageColor3 = Color3.fromRGB(100, 60, 220)
openBtn.ImageTransparency = 0.3
openBtn.Parent = screenGui

local obCorner = Instance.new("UICorner", openBtn)
obCorner.CornerRadius = UDim.new(0, 14)

local obStroke = Instance.new("UIStroke", openBtn)
obStroke.Thickness = 2
obStroke.Color = Color3.fromRGB(120, 80, 255)
obStroke.Transparency = 0.2

local obIcon = Instance.new("ImageLabel")
obIcon.Size = UDim2.new(0.7, 0, 0.7, 0)
obIcon.Position = UDim2.new(0.15, 0, 0.15, 0)
obIcon.BackgroundTransparency = 1
obIcon.Image = "rbxassetid://18209589265"
obIcon.Parent = openBtn

local obLabel = Instance.new("TextLabel")
obLabel.Size = UDim2.new(0, 80, 0, 20)
obLabel.Position = UDim2.new(0.5, -40, 1, 4)
obLabel.BackgroundTransparency = 1
obLabel.Text = "WORLDS"
obLabel.TextColor3 = Color3.fromRGB(150, 130, 255)
obLabel.TextScaled = true
obLabel.Font = Enum.Font.GothamBold
obLabel.Parent = openBtn

openBtn.MouseEnter:Connect(function()
	TweenService:Create(openBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 65, 0, 65)}):Play()
	TweenService:Create(obStroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
end)

openBtn.MouseLeave:Connect(function()
	TweenService:Create(openBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 60, 0, 60)}):Play()
	TweenService:Create(obStroke, TweenInfo.new(0.2), {Transparency = 0.2}):Play()
end)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.ClipsDescendants = false
mainFrame.Visible = false
mainFrame.Parent = screenGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(5, 2, 20)
bg.Parent = mainFrame

local gradient1 = Instance.new("UIGradient")
gradient1.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 2, 20)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(15, 5, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 8, 50)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(15, 5, 40)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 2, 20))
}
gradient1.Parent = bg

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 50, 0, 50)
closeBtn.Position = UDim2.new(0, 20, 0, 20)
closeBtn.BackgroundTransparency = 0.5
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local cbCorner = Instance.new("UICorner", closeBtn)
cbCorner.CornerRadius = UDim.new(0, 12)

closeBtn.MouseButton1Click:Connect(function()
	closeUI()
end)

local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundTransparency = 1
overlay.Parent = mainFrame

local particles = {}
local particleCon

local function spawnParticles()
	for _, p in ipairs(particles) do
		p:Destroy()
	end
	particles = {}
	for i = 1, 80 do
		local s = math.random(1, 3)
		local d = Instance.new("Frame")
		d.Size = UDim2.new(0, s, 0, s)
		d.Position = UDim2.new(math.random(), 0, math.random(), 0)
		d.BackgroundColor3 = Color3.new(1, 1, 1)
		d.BackgroundTransparency = math.random(2, 8) / 10
		d.BorderSizePixel = 0
		d.Parent = overlay
		local c = Instance.new("UICorner", d)
		c.CornerRadius = UDim.new(1, 0)
		table.insert(particles, d)
	end
	if particleCon then particleCon:Disconnect() end
	particleCon = RunService.Heartbeat:Connect(function(dt)
		for _, d in ipairs(particles) do
			local pos = d.Position
			local nx = (pos.X.Scale + (math.random() - 0.5) * 0.02 * dt * 60) % 1
			local ny = (pos.Y.Scale + (math.random() - 0.5) * 0.01 * dt * 60) % 1
			d.Position = UDim2.new(nx, 0, ny, 0)
		end
	end)
end

local function clearParticles()
	if particleCon then
		particleCon:Disconnect()
		particleCon = nil
	end
	for _, d in ipairs(particles) do
		d:Destroy()
	end
	particles = {}
end

local worlds = {
	{
		name = "Sunshine & Rainbows",
		image = "rbxassetid://1015",
		color = Color3.fromRGB(255, 215, 0),
		accent = Color3.fromRGB(255, 160, 50),
		glow = Color3.fromRGB(255, 220, 120),
		description = "A bright and cheerful world full of color!",
		teleportPos = Vector3.new(0, 50, 0),
		placeId = nil,
		locked = false
	},
	{
		name = "Squish World",
		image = "rbxassetid://133",
		color = Color3.fromRGB(255, 80, 180),
		accent = Color3.fromRGB(200, 40, 140),
		glow = Color3.fromRGB(255, 140, 210),
		description = "Bouncy, squishy fun awaits!",
		teleportPos = Vector3.new(0, 50, 0),
		placeId = squishWorldId,
		locked = true
	}
}

local currentIndex = 1
local busy = false

local cx = Instance.new("Frame")
cx.Size = UDim2.new(0, 600, 0, 640)
cx.Position = UDim2.new(0.5, -300, 0.5, -330)
cx.BackgroundTransparency = 1
cx.Parent = mainFrame

local ring1 = Instance.new("ImageLabel")
ring1.Size = UDim2.new(0, 460, 0, 460)
ring1.Position = UDim2.new(0.5, -230, 0, 0)
ring1.BackgroundTransparency = 1
ring1.Image = "rbxassetid://5093544483"
ring1.ImageColor3 = worlds[1].glow
ring1.ImageTransparency = 0.5
ring1.ZIndex = 2
ring1.Parent = cx

local ring2 = Instance.new("ImageLabel")
ring2.Size = UDim2.new(0, 420, 0, 420)
ring2.Position = UDim2.new(0.5, -210, 0, 20)
ring2.BackgroundTransparency = 1
ring2.Image = "rbxassetid://5093544483"
ring2.ImageColor3 = Color3.new(1, 1, 1)
ring2.ImageTransparency = 0.7
ring2.ZIndex = 2
ring2.Parent = cx

local planet = Instance.new("ImageLabel")
planet.Size = UDim2.new(0, 340, 0, 340)
planet.Position = UDim2.new(0.5, -170, 0, 60)
planet.BackgroundTransparency = 1
planet.Image = worlds[1].image
planet.ZIndex = 3
planet.Parent = cx

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(0, 360, 0, 360)
shadow.Position = UDim2.new(0.5, -180, 0, 50)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://3479080437"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.7
shadow.ZIndex = 1
shadow.Parent = cx

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 540, 0, 120)
panel.Position = UDim2.new(0.5, -270, 0, 480)
panel.BackgroundTransparency = 0.2
panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
panel.Parent = cx

local pnlCorner = Instance.new("UICorner", panel)
pnlCorner.CornerRadius = UDim.new(0, 24)

local pnlBorder = Instance.new("UIStroke")
pnlBorder.Thickness = 2
pnlBorder.Color = worlds[1].color
pnlBorder.Transparency = 0.3
pnlBorder.Parent = panel

local pnlGlow = Instance.new("ImageLabel")
pnlGlow.Size = UDim2.new(1, 20, 1, 20)
pnlGlow.Position = UDim2.new(0.5, -10, 0.5, -10)
pnlGlow.BackgroundTransparency = 1
pnlGlow.Image = "rbxassetid://5093544483"
pnlGlow.ImageColor3 = worlds[1].glow
pnlGlow.ImageTransparency = 0.8
pnlGlow.ZIndex = 0
pnlGlow.Parent = panel

local wName = Instance.new("TextLabel")
wName.Size = UDim2.new(1, -40, 0.5, 0)
wName.Position = UDim2.new(0, 20, 0.08, 0)
wName.BackgroundTransparency = 1
wName.Text = worlds[1].name
wName.TextColor3 = worlds[1].color
wName.TextScaled = true
wName.Font = Enum.Font.GothamBold
wName.TextXAlignment = Enum.TextXAlignment.Left
wName.ZIndex = 3
wName.Parent = panel

local wDesc = Instance.new("TextLabel")
wDesc.Size = UDim2.new(1, -40, 0.35, 0)
wDesc.Position = UDim2.new(0, 20, 0.55, 0)
wDesc.BackgroundTransparency = 1
wDesc.Text = worlds[1].description
wDesc.TextColor3 = Color3.fromRGB(160, 160, 220)
wDesc.TextScaled = true
wDesc.Font = Enum.Font.Gotham
wDesc.TextXAlignment = Enum.TextXAlignment.Left
wDesc.ZIndex = 3
wDesc.Parent = panel

local selPanel = Instance.new("Frame")
selPanel.Size = UDim2.new(0, 580, 0, 140)
selPanel.Position = UDim2.new(0.5, -290, 0.82, 0)
selPanel.BackgroundTransparency = 0.3
selPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
selPanel.Parent = mainFrame

local selCorner = Instance.new("UICorner", selPanel)
selCorner.CornerRadius = UDim.new(0, 28)

local selBorder = Instance.new("UIStroke")
selBorder.Thickness = 2
selBorder.Color = Color3.fromRGB(80, 60, 180)
selBorder.Transparency = 0.5
selBorder.Parent = selPanel

local selTitle = Instance.new("TextLabel")
selTitle.Size = UDim2.new(1, 0, 0, 30)
selTitle.Position = UDim2.new(0, 0, 0, 6)
selTitle.BackgroundTransparency = 1
selTitle.Text = "SELECT DESTINATION"
selTitle.TextColor3 = Color3.fromRGB(110, 100, 200)
selTitle.TextScaled = true
selTitle.Font = Enum.Font.GothamBold
selTitle.Parent = selPanel

local selInner = Instance.new("Frame")
selInner.Size = UDim2.new(1, 0, 0, 95)
selInner.Position = UDim2.new(0, 0, 0, 38)
selInner.BackgroundTransparency = 1
selInner.Parent = selPanel

local selList = Instance.new("UIListLayout")
selList.FillDirection = Enum.FillDirection.Horizontal
selList.HorizontalAlignment = Enum.HorizontalAlignment.Center
selList.VerticalAlignment = Enum.VerticalAlignment.Center
selList.Padding = UDim.new(0, 40)
selList.Parent = selInner

local btns = {}

for i, world in ipairs(worlds) do
	local wc = Instance.new("Frame")
	wc.Size = UDim2.new(0, 105, 0, 105)
	wc.BackgroundTransparency = 1
	wc.Parent = selInner

	local wg = Instance.new("ImageLabel")
	wg.Size = UDim2.new(0, 105, 0, 105)
	wg.Position = UDim2.new(0.5, -52, 0.5, -52)
	wg.BackgroundTransparency = 1
	wg.Image = "rbxassetid://5093544483"
	wg.ImageColor3 = world.color
	wg.ImageTransparency = i == currentIndex and 0.1 or 0.9
	wg.ZIndex = 1
	wg.Parent = wc

	local wb = Instance.new("ImageButton")
	wb.Size = UDim2.new(0, 85, 0, 85)
	wb.Position = UDim2.new(0.5, -42, 0.5, -42)
	wb.BackgroundTransparency = 1
	wb.Image = world.image
	wb.ZIndex = 2
	wb.Parent = wc

	local ws = Instance.new("UIStroke")
	ws.Thickness = 3
	ws.Parent = wb

	if world.locked and not hasSquishAccess then
		wb.ImageColor3 = Color3.new(0.3, 0.3, 0.3)
		wb.ImageTransparency = 0.4
		ws.Color = Color3.fromRGB(80, 40, 40)
		ws.Transparency = 0.4

		local lockIcon = Instance.new("TextLabel")
		lockIcon.Size = UDim2.new(1, 0, 1, 0)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Text = "🔒"
		lockIcon.TextScaled = true
		lockIcon.Font = Enum.Font.GothamBold
		lockIcon.ZIndex = 3
		lockIcon.Parent = wb
	else
		ws.Color = i == currentIndex and Color3.fromRGB(0, 255, 159) or Color3.fromRGB(60, 60, 60)
		ws.Transparency = i == currentIndex and 0 or 0.7
	end

	wb.MouseButton1Click:Connect(function()
		if busy or currentIndex == i then return end
		if world.locked and not hasSquishAccess then
			local hint = Instance.new("TextLabel")
			hint.Size = UDim2.new(0, 300, 0, 40)
			hint.Position = UDim2.new(0.5, -150, 0.6, 0)
			hint.BackgroundTransparency = 0.5
			hint.BackgroundColor3 = Color3.new(0, 0, 0)
			hint.Text = "Touch the Teleporter to unlock!"
			hint.TextColor3 = Color3.fromRGB(255, 100, 100)
			hint.TextScaled = true
			hint.Font = Enum.Font.GothamBold
			hint.ZIndex = 10
			hint.Parent = mainFrame
			local hc = Instance.new("UICorner", hint)
			hc.CornerRadius = UDim.new(0, 12)
			TweenService:Create(hint, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 40)}):Play()
			task.wait(2)
			TweenService:Create(hint, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.wait(0.3)
			hint:Destroy()
			return
		end
		currentIndex = i
		selectWorld()
	end)

	wb.MouseEnter:Connect(function()
		if currentIndex ~= i and not busy then
			if world.locked and not hasSquishAccess then return end
			TweenService:Create(wb, TweenInfo.new(0.2), {Size = UDim2.new(0, 91, 0, 91)}):Play()
			TweenService:Create(wg, TweenInfo.new(0.2), {ImageTransparency = 0.3}):Play()
		end
	end)

	wb.MouseLeave:Connect(function()
		if currentIndex ~= i and not busy then
			TweenService:Create(wb, TweenInfo.new(0.2), {Size = UDim2.new(0, 85, 0, 85)}):Play()
			TweenService:Create(wg, TweenInfo.new(0.2), {ImageTransparency = 0.9}):Play()
		end
	end)

	table.insert(btns, {wb, wg, ws})
end

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0, 230, 0, 80)
tpBtn.Position = UDim2.new(1, -280, 0.5, -40)
tpBtn.BackgroundTransparency = 0.05
tpBtn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
tpBtn.Text = "T E L E P O R T"
tpBtn.TextColor3 = Color3.new(1, 1, 1)
tpBtn.TextScaled = true
tpBtn.Font = Enum.Font.GothamBold
tpBtn.Parent = mainFrame

local tpCorner = Instance.new("UICorner", tpBtn)
tpCorner.CornerRadius = UDim.new(0, 22)

local tpBorder = Instance.new("UIStroke")
tpBorder.Thickness = 3
tpBorder.Color = Color3.fromRGB(255, 120, 120)
tpBorder.Transparency = 0.3
tpBorder.Parent = tpBtn

tpBtn.MouseEnter:Connect(function()
	TweenService:Create(tpBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 245, 0, 87), BackgroundTransparency = 0}):Play()
end)

tpBtn.MouseLeave:Connect(function()
	TweenService:Create(tpBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 230, 0, 80), BackgroundTransparency = 0.05}):Play()
end)

tpBtn.MouseButton1Click:Connect(function()
	if busy then return end
	local world = worlds[currentIndex]
	if world.locked and not hasSquishAccess then
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(0, 300, 0, 40)
		hint.Position = UDim2.new(0.5, -150, 0.6, 0)
		hint.BackgroundTransparency = 0.5
		hint.BackgroundColor3 = Color3.new(0, 0, 0)
		hint.Text = "Touch the Teleporter to unlock!"
		hint.TextColor3 = Color3.fromRGB(255, 100, 100)
		hint.TextScaled = true
		hint.Font = Enum.Font.GothamBold
		hint.ZIndex = 10
		hint.Parent = mainFrame
		local hc = Instance.new("UICorner", hint)
		hc.CornerRadius = UDim.new(0, 12)
		TweenService:Create(hint, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 300, 0, 40)}):Play()
		task.wait(2)
		TweenService:Create(hint, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.3)
		hint:Destroy()
		return
	end
	busy = true

	tpBtn.Text = "TRAVELING..."
	TweenService:Create(tpBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()

	local nf = Instance.new("Frame")
	nf.AnchorPoint = Vector2.new(0.5, 0.5)
	nf.Size = UDim2.new(0, 0, 0, 0)
	nf.Position = UDim2.new(0.5, 0, 0.38, 0)
	nf.BackgroundTransparency = 0.25
	nf.BackgroundColor3 = Color3.new(0, 0, 0)
	nf.ZIndex = 20
	nf.Parent = mainFrame

	local nfCorner = Instance.new("UICorner", nf)
	nfCorner.CornerRadius = UDim.new(0, 26)

	local nfBorder = Instance.new("UIStroke")
	nfBorder.Thickness = 2
	nfBorder.Color = world.color
	nfBorder.Transparency = 0.1
	nfBorder.Parent = nf

	local nfGlow = Instance.new("ImageLabel")
	nfGlow.Size = UDim2.new(1, 30, 1, 30)
	nfGlow.Position = UDim2.new(0.5, -15, 0.5, -15)
	nfGlow.BackgroundTransparency = 1
	nfGlow.Image = "rbxassetid://5093544483"
	nfGlow.ImageColor3 = world.color
	nfGlow.ImageTransparency = 0.6
	nfGlow.ZIndex = 19
	nfGlow.Parent = nf

	local nt1 = Instance.new("TextLabel")
	nt1.Size = UDim2.new(1, -50, 0.5, 0)
	nt1.Position = UDim2.new(0, 25, 0.1, 0)
	nt1.BackgroundTransparency = 1
	nt1.Text = "Traveling to " .. world.name
	nt1.TextColor3 = world.color
	nt1.TextScaled = true
	nt1.Font = Enum.Font.GothamBold
	nt1.ZIndex = 21
	nt1.Parent = nf

	local nt2 = Instance.new("TextLabel")
	nt2.Size = UDim2.new(1, -50, 0.35, 0)
	nt2.Position = UDim2.new(0, 25, 0.55, 0)
	nt2.BackgroundTransparency = 1
	nt2.Text = "Hold on tight!"
	nt2.TextColor3 = Color3.fromRGB(180, 180, 240)
	nt2.TextScaled = true
	nt2.Font = Enum.Font.Gotham
	nt2.ZIndex = 21
	nt2.Parent = nf

	TweenService:Create(nf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 110)}):Play()
	TweenService:Create(nfGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

	task.wait(1.5)

	if world.placeId and world.placeId ~= game.PlaceId then
		TeleportService:TeleportAsync(world.placeId, {player})
	else
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(world.teleportPos)
		end
		TweenService:Create(nf, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.3)
		nf:Destroy()
		tpBtn.Text = "T E L E P O R T"
		TweenService:Create(tpBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
		busy = false
		closeUI()
	end
end)

function unlockSquishWorld()
	hasSquishAccess = true
	worlds[2].locked = false

	for i, pair in ipairs(btns) do
		local b, g = pair[1], pair[2]
		if i == 2 then
			b.ImageColor3 = Color3.new(1, 1, 1)
			b.ImageTransparency = 0
			local lockLabel = b:FindFirstChildOfClass("TextLabel")
			if lockLabel then lockLabel:Destroy() end
			b.UIStroke.Color = currentIndex == 2 and Color3.fromRGB(0, 255, 159) or Color3.fromRGB(60, 60, 60)
			b.UIStroke.Transparency = currentIndex == 2 and 0 or 0.7
			g.ImageColor3 = worlds[2].color
			g.ImageTransparency = currentIndex == 2 and 0.1 or 0.9
		end
	end

	local unlockNotif = Instance.new("TextLabel")
	unlockNotif.Size = UDim2.new(0, 0, 0, 50)
	unlockNotif.Position = UDim2.new(0.5, 0, 0.15, 0)
	unlockNotif.BackgroundTransparency = 0.4
	unlockNotif.BackgroundColor3 = Color3.new(0, 0, 0)
	unlockNotif.Text = "Squish World Unlocked!"
	unlockNotif.TextColor3 = worlds[2].color
	unlockNotif.TextScaled = true
	unlockNotif.Font = Enum.Font.GothamBold
	unlockNotif.ZIndex = 10
	unlockNotif.Parent = mainFrame
	local uc = Instance.new("UICorner", unlockNotif)
	uc.CornerRadius = UDim.new(0, 16)
	TweenService:Create(unlockNotif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 350, 0, 50)}):Play()
	task.wait(2.5)
	TweenService:Create(unlockNotif, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0)}):Play()
	task.wait(0.3)
	unlockNotif:Destroy()
end

function selectWorld()
	busy = true
	local world = worlds[currentIndex]

	planet.Image = world.image
	wName.Text = world.name
	wName.TextColor3 = world.color
	wDesc.Text = world.description
	ring1.ImageColor3 = world.glow
	pnlBorder.Color = world.color
	pnlGlow.ImageColor3 = world.glow
	shadow.ImageColor3 = Color3.new(0, 0, 0)

	TweenService:Create(ring1, TweenInfo.new(0.8), {ImageTransparency = 0.3}):Play()
	TweenService:Create(pnlBorder, TweenInfo.new(0.5), {Transparency = 0.2}):Play()
	TweenService:Create(planet, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 320)}):Play()
	task.wait(0.12)
	TweenService:Create(planet, TweenInfo.new(0.3), {Size = UDim2.new(0, 340, 0, 340)}):Play()

	for i, pair in ipairs(btns) do
		local b, g = pair[1], pair[2]
		local sel = i == currentIndex
		if not (worlds[i].locked and not hasSquishAccess) then
			b.UIStroke.Color = sel and Color3.fromRGB(0, 255, 159) or Color3.fromRGB(60, 60, 60)
			b.UIStroke.Transparency = sel and 0 or 0.7
			TweenService:Create(b, TweenInfo.new(0.25), {Size = sel and UDim2.new(0, 91, 0, 91) or UDim2.new(0, 85, 0, 85)}):Play()
			TweenService:Create(g, TweenInfo.new(0.4), {
				ImageTransparency = sel and 0.1 or 0.9,
				ImageColor3 = sel and world.color or g.ImageColor3
			}):Play()
		end
	end

	task.wait(0.4)
	busy = false
end

function closeUI()
	busy = true
	clearParticles()
	local t = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0, 0, 1.2, 0)})
	t:Play()
	t.Completed:Connect(function()
		mainFrame.Visible = false
		mainFrame.Position = UDim2.new(0, 0, 0, 0)
		busy = false
	end)
end

local function openUI()
	spawnParticles()
	mainFrame.Visible = true
	mainFrame.Position = UDim2.new(0, 0, -1.2, 0)
	TweenService:Create(mainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
end

openEvent.OnClientEvent:Connect(function()
	unlockSquishWorld()
end)

openBtn.MouseButton1Click:Connect(openUI)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
		closeUI()
	end
end)