--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(script.Parent.Parent.Config.WeaponConfig)
local RemoteEvents = require(script.Parent.Parent.ReplicatedStorage.RemoteEvents)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local GunController = {}
local isInitialized = false

local state = {
	inMatch = false,
	currentWeapon = "DefaultSniper",
	ammo = 5,
	reserveAmmo = 25,
	isScoped = false,
	isADS = false,
	isReloading = false,
	canShoot = true,
	lastShotTime = 0,
	currentSpread = 0,
	recoilOffset = Vector2.new(0, 0),
	swayOffset = Vector2.new(0, 0),
	targetSway = Vector2.new(0, 0),
	isHoldingBreath = false,
	breatheTime = 0,
	breatheCooldownTime = 0,
}

local weaponConfig = WeaponConfig.Weapons[state.currentWeapon]

function GunController:Initialize()
	if isInitialized then
		return
	end
	isInitialized = true
	
	self:SetupInput()
	self:SetupRemotes()
	self:CreateGui()
	
	RunService.RenderStepped:Connect(function(deltaTime)
		self:UpdateSway(deltaTime)
		self:UpdateRecoil(deltaTime)
		self:UpdateBreathing(deltaTime)
		self:UpdateCamera(deltaTime)
	end)
end

function GunController:SetupInput()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		if not state.inMatch then
			return
		end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:Shoot()
		end
		
		if input.KeyCode == Enum.KeyCode.R then
			self:StartReload()
		end
		
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonR2 then
			if not state.isScoped then
				self:StartScope()
			end
		end
		
		if input.KeyCode == Enum.KeyCode.LeftControl then
			state.isHoldingBreath = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonR2 then
			self:EndScope()
		end
		
		if input.KeyCode == Enum.KeyCode.LeftControl then
			state.isHoldingBreath = false
		end
	end)
end

function GunController:SetupRemotes()
	RemoteEvents.MatchStateChanged.OnClientEvent:Connect(function(newState, matchId)
		if newState == "InProgress" then
			state.inMatch = true
			state.ammo = weaponConfig.MagazineSize
			state.reserveAmmo = weaponConfig.TotalAmmo
			self:ShowUI(true)
		elseif newState == "Ended" or newState == "WaitingForPlayers" then
			state.inMatch = false
			state.isScoped = false
			state.isADS = false
			camera.FieldOfView = 70
			self:ShowUI(false)
		end
	end)
	
	RemoteEvents.BulletHit.OnClientEvent:Connect(function(hitType, ...)
		local args = {...}
		if hitType == "Hit" then
			self:OnHit(args[1], args[2], args[3])
		elseif hitType == "Miss" then
			self:OnMiss(args[1])
		elseif hitType == "Damaged" then
			self:OnDamaged(args[1], args[2], args[3])
		end
	end)
	
	RemoteEvents.WeaponEquipped.OnClientEvent:Connect(function(weaponName)
		state.currentWeapon = weaponName
		weaponConfig = WeaponConfig.Weapons[weaponName]
		state.ammo = weaponConfig.MagazineSize
		state.reserveAmmo = weaponConfig.TotalAmmo
		self:UpdateAmmoDisplay()
	end)
	
	RemoteEvents.PlayerDied.OnClientEvent:Connect(function(message, killerName, killedName, headshot)
		self:AddKillFeedMessage(message, headshot)
	end)
end

function GunController:Shoot()
	if not state.canShoot or state.isReloading or state.isScoped then
		return
	end
	
	local currentTime = tick()
	if currentTime - state.lastShotTime < weaponConfig.FireRate then
		return
	end
	
	if state.ammo <= 0 then
		self:PlaySound("Empty")
		return
	end
	
	state.lastShotTime = currentTime
	state.ammo -= 1
	state.canShoot = false
	
	local spreadRad = math.rad(state.currentSpread)
	local spreadX = (math.random() - 0.5) * spreadRad * 2
	local spreadY = (math.random() - 0.5) * spreadRad * 2
	
	local origin = camera.CFrame.Position
	local direction = (camera.CFrame.LookVector + camera.CFrame.RightVector * spreadX + camera.CFrame.UpVector * spreadY).Unit
	
	RemoteEvents.FireBullet:FireServer(state.currentWeapon, origin, direction)
	
	state.currentSpread = math.min(state.currentSpread + weaponConfig.SpreadPerShot, weaponConfig.MaxSpread)
	
	self:ApplyRecoil()
	self:PlaySound("Fire")
	self:ShowMuzzleFlash()
	
	self:UpdateAmmoDisplay()
	
	task.delay(weaponConfig.ChamberTime, function()
		state.canShoot = true
	end)
end

function GunController:StartReload()
	if state.isReloading or state.ammo >= weaponConfig.MagazineSize or state.reserveAmmo <= 0 then
		return
	end
	
	state.isReloading = true
	RemoteEvents.ReloadStarted:FireServer(state.currentWeapon)
	self:PlaySound("ReloadStart")
	self:ShowReloadUI(true)
	
	task.spawn(function()
		if weaponConfig.ReloadType == "SingleRound" then
			local roundsToReload = math.min(weaponConfig.MagazineSize - state.ammo, state.reserveAmmo)
			for i = 1, roundsToReload do
				task.wait(weaponConfig.SingleReloadTime)
				if not state.isReloading then
					break
				end
				state.ammo += 1
				state.reserveAmmo -= 1
				self:UpdateAmmoDisplay()
				self:PlaySound("Chamber")
			end
		else
			task.wait(weaponConfig.ReloadTime)
			local roundsNeeded = weaponConfig.MagazineSize - state.ammo
			local roundsToReload = math.min(roundsNeeded, state.reserveAmmo)
			state.ammo += roundsToReload
			state.reserveAmmo -= roundsToReload
			self:UpdateAmmoDisplay()
		end
		
		state.isReloading = false
		self:PlaySound("ReloadEnd")
		self:ShowReloadUI(false)
	end)
end

function GunController:StartScope()
	if not state.inMatch then
		return
	end
	state.isScoped = true
	self:ShowScopeOverlay(true)
	RemoteEvents.ScopeChanged:FireServer(true)
end

function GunController:EndScope()
	state.isScoped = false
	self:ShowScopeOverlay(false)
	camera.FieldOfView = 70
	RemoteEvents.ScopeChanged:FireServer(false)
end

function GunController:ApplyRecoil()
	local recoilV = weaponConfig.RecoilVertical
	local recoilH = (math.random() - 0.5) * weaponConfig.RecoilHorizontal * 2
	state.recoilOffset = state.recoilOffset + Vector2.new(recoilH, recoilV)
end

function GunController:UpdateRecoil(deltaTime: number)
	if state.recoilOffset.Magnitude > 0 then
		local recovery = weaponConfig.RecoilRecoverySpeed * deltaTime
		if state.recoilOffset.Magnitude <= recovery then
			state.recoilOffset = Vector2.new(0, 0)
		else
			state.recoilOffset = state.recoilOffset - state.recoilOffset.Unit * recovery
		end
	end
end

function GunController:UpdateSway(deltaTime: number)
	local mouseDelta = UserInputService:GetMouseDelta()
	local swayMultiplier = weaponConfig.SwayAmount
	
	if state.isHoldingBreath then
		swayMultiplier = swayMultiplier * weaponConfig.BreatheSwayMultiplier
	end
	
	state.targetSway = Vector2.new(
		-mouseDelta.X * swayMultiplier,
		-mouseDelta.Y * swayMultiplier
	)
	
	state.swayOffset = state.swayOffset:Lerp(state.targetSway, weaponConfig.SwaySmoothing * deltaTime)
end

function GunController:UpdateBreathing(deltaTime: number)
	if state.isHoldingBreath and state.breatheCooldownTime <= 0 then
		state.breatheTime += deltaTime
		if state.breatheTime >= weaponConfig.BreatheHoldDuration then
			state.isHoldingBreath = false
			state.breatheCooldownTime = weaponConfig.BreatheCooldown
			state.breatheTime = 0
		end
	end
	
	if state.breatheCooldownTime > 0 then
		state.breatheCooldownTime -= deltaTime
	end
end

function GunController:UpdateCamera(deltaTime: number)
	if not state.inMatch then
		return
	end
	
	local totalOffset = state.recoilOffset + state.swayOffset
	local offsetCFrame = camera.CFrame * CFrame.Angles(
		math.rad(-totalOffset.Y),
		math.rad(-totalOffset.X),
		0
	)
	camera.CFrame = offsetCFrame
	
	if state.isScoped then
		local targetFOV = weaponConfig.ZoomFOV
		camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 0.1
	end
end

function GunController:OnHit(targetName: string, damage: number, headshot: boolean)
	self:ShowHitmarker(false)
	self:UpdateAmmoDisplay()
end

function GunController:OnMiss(hitPosition: Vector3)
	self:ShowHitmarker(true)
end

function GunController:OnDamaged(damage: number, origin: Vector3, direction: Vector3)
	self:ShowDamageVignette(damage)
end

function GunController:PlaySound(soundName: string)
	local soundId = weaponConfig.Sounds[soundName]
	if not soundId then
		return
	end
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = player.PlayerGui
	sound:Play()
	
	game:GetService("Debris"):AddItem(sound, 2)
end

function GunController:CreateGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SniperDuelsUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player.PlayerGui
	
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 0, 0, 0)
	crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
	crosshair.BackgroundTransparency = 1
	crosshair.Parent = screenGui
	
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.BackgroundColor3 = WeaponConfig.Crosshair.DefaultColor
		line.BackgroundTransparency = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Parent = crosshair
		
		local cSize = WeaponConfig.Crosshair.Size
		local cGap = WeaponConfig.Crosshair.Gap
		local cThick = WeaponConfig.Crosshair.Thickness
		
		if i == 1 then
			line.Size = UDim2.new(0, cThick, 0, cSize)
			line.Position = UDim2.new(0.5, 0, 0.5, -(cGap + cSize))
		elseif i == 2 then
			line.Size = UDim2.new(0, cThick, 0, cSize)
			line.Position = UDim2.new(0.5, 0, 0.5, cGap)
		elseif i == 3 then
			line.Size = UDim2.new(0, cSize, 0, cThick)
			line.Position = UDim2.new(0.5, -(cGap + cSize), 0.5, 0)
		elseif i == 4 then
			line.Size = UDim2.new(0, cSize, 0, cThick)
			line.Position = UDim2.new(0.5, cGap, 0.5, 0)
		end
	end
	
	if WeaponConfig.Crosshair.DotEnabled then
		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.Size = UDim2.new(0, WeaponConfig.Crosshair.DotSize, 0, WeaponConfig.Crosshair.DotSize)
		dot.Position = UDim2.new(0.5, -WeaponConfig.Crosshair.DotSize / 2, 0.5, -WeaponConfig.Crosshair.DotSize / 2)
		dot.BackgroundColor3 = WeaponConfig.Crosshair.DefaultColor
		dot.BackgroundTransparency = 0
		dot.Parent = crosshair
	end
	
	local ammoFrame = Instance.new("Frame")
	ammoFrame.Name = "AmmoDisplay"
	ammoFrame.Size = UDim2.new(0, 200, 0, 50)
	ammoFrame.Position = UDim2.new(0.5, -100, 0.9, 0)
	ammoFrame.BackgroundTransparency = 1
	ammoFrame.Parent = screenGui
	
	local ammoLabel = Instance.new("TextLabel")
	ammoLabel.Name = "AmmoText"
	ammoLabel.Size = UDim2.new(1, 0, 1, 0)
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammoLabel.TextScaled = true
	ammoLabel.Font = Enum.Font.GothamBold
	ammoLabel.Text = "5 / 25"
	ammoLabel.TextStrokeTransparency = 0.5
	ammoLabel.Parent = ammoFrame
	
	local hitmarker = Instance.new("Frame")
	hitmarker.Name = "Hitmarker"
	hitmarker.Size = UDim2.new(0, 0, 0, 0)
	hitmarker.Position = UDim2.new(0.5, 0, 0.5, 0)
	hitmarker.BackgroundTransparency = 1
	hitmarker.Visible = false
	hitmarker.Parent = screenGui
	
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Name = "HitLine" .. i
		line.BackgroundColor3 = WeaponConfig.Hitmarker.BaseColor
		line.Size = UDim2.new(0, 12, 0, 2)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		
		local angle = (i - 1) * 90 + WeaponConfig.Hitmarker.SpreadAngle
		line.Rotation = angle
		line.Parent = hitmarker
	end
	
	local scopeOverlay = Instance.new("Frame")
	scopeOverlay.Name = "ScopeOverlay"
	scopeOverlay.Size = UDim2.new(1, 0, 1, 0)
	scopeOverlay.BackgroundTransparency = 1
	scopeOverlay.Visible = false
	scopeOverlay.ZIndex = 10
	scopeOverlay.Parent = screenGui
	
	local scopeBorder = Instance.new("Frame")
	scopeBorder.Name = "ScopeBorder"
	scopeBorder.Size = UDim2.new(1, 0, 1, 0)
	scopeBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	scopeBorder.BackgroundTransparency = 0.6
	scopeBorder.ZIndex = 11
	scopeBorder.Parent = scopeOverlay
	
	local scopeCircle = Instance.new("ImageLabel")
	scopeCircle.Name = "ScopeCircle"
	scopeCircle.Size = UDim2.new(0.5, 0, 0.5, 0)
	scopeCircle.Position = UDim2.new(0.25, 0, 0.25, 0)
	scopeCircle.BackgroundTransparency = 1
	scopeCircle.Image = "rbxassetid://1234567890"
	scopeCircle.ZIndex = 12
	scopeCircle.Parent = scopeOverlay
	
	local killFeed = Instance.new("Frame")
	killFeed.Name = "KillFeed"
	killFeed.Size = UDim2.new(0, 300, 0, 200)
	killFeed.Position = UDim2.new(0.02, 0, 0.02, 0)
	killFeed.BackgroundTransparency = 1
	killFeed.Parent = screenGui
	
	local reloadBar = Instance.new("Frame")
	reloadBar.Name = "ReloadBar"
	reloadBar.Size = UDim2.new(0, 200, 0, 4)
	reloadBar.Position = UDim2.new(0.5, -100, 0.85, 0)
	reloadBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	reloadBar.BackgroundTransparency = 0.5
	reloadBar.Visible = false
	reloadBar.Parent = screenGui
	
	local reloadProgress = Instance.new("Frame")
	reloadProgress.Name = "ReloadProgress"
	reloadProgress.Size = UDim2.new(0, 0, 1, 0)
	reloadProgress.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	reloadProgress.Parent = reloadBar
	
	local damageVignette = Instance.new("Frame")
	damageVignette.Name = "DamageVignette"
	damageVignette.Size = UDim2.new(1, 0, 1, 0)
	damageVignette.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	damageVignette.BackgroundTransparency = 1
	damageVignette.Visible = false
	damageVignette.ZIndex = 5
	damageVignette.Parent = screenGui
	
	state.screenGui = screenGui
end

function GunController:ShowUI(visible: boolean)
	if state.screenGui then
		state.screenGui.Enabled = visible
	end
end

function GunController:UpdateAmmoDisplay()
	local ammoText = state.screenGui:FindFirstChild("AmmoDisplay")
	if ammoText then
		local label = ammoText:FindFirstChild("AmmoText")
		if label then
			label.Text = state.ammo .. " / " .. state.reserveAmmo
		end
	end
end

function GunController:ShowHitmarker(miss: boolean)
	local hitmarker = state.screenGui:FindFirstChild("Hitmarker")
	if not hitmarker then
		return
	end
	
	hitmarker.Visible = true
	local duration = WeaponConfig.Hitmarker.Duration
	
	for _, child in ipairs(hitmarker:GetChildren()) do
		if child:IsA("Frame") then
			if miss then
				child.BackgroundColor3 = WeaponConfig.Hitmarker.BaseColor
			else
				child.BackgroundColor3 = WeaponConfig.Hitmarker.BaseColor
			end
		end
	end
	
	task.delay(duration, function()
		hitmarker.Visible = false
	end)
end

function GunController:ShowScopeOverlay(visible: boolean)
	local scopeOverlay = state.screenGui:FindFirstChild("ScopeOverlay")
	if scopeOverlay then
		scopeOverlay.Visible = visible
	end
end

function GunController:ShowReloadUI(visible: boolean)
	local reloadBar = state.screenGui:FindFirstChild("ReloadBar")
	if reloadBar then
		reloadBar.Visible = visible
	end
end

function GunController:ShowMuzzleFlash()
	local flash = Instance.new("Frame")
	flash.Name = "MuzzleFlash"
	flash.Size = UDim2.new(0.2, 0, 0.2, 0)
	flash.Position = UDim2.new(0.4, 0, 0.4, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
	flash.BackgroundTransparency = 0.3
	flash.ZIndex = 2
	flash.Parent = state.screenGui
	
	task.delay(weaponConfig.MuzzleFlashDuration, function()
		flash:Destroy()
	end)
end

function GunController:ShowDamageVignette(damage: number)
	local vignette = state.screenGui:FindFirstChild("DamageVignette")
	if not vignette then
		return
	end
	
	local intensity = math.min(1, damage / 50)
	vignette.BackgroundTransparency = 1 - intensity * 0.7
	vignette.Visible = true
	
	task.delay(0.3, function()
		vignette.BackgroundTransparency = 1
		vignette.Visible = false
	end)
end

function GunController:AddKillFeedMessage(message: string, headshot: boolean)
	local killFeed = state.screenGui:FindFirstChild("KillFeed")
	if not killFeed then
		return
	end
	
	local killMessage = Instance.new("TextLabel")
	killMessage.Size = UDim2.new(1, 0, 0, 30)
	killMessage.BackgroundTransparency = 1
	killMessage.TextColor3 = headshot and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 255, 255)
	killMessage.TextXAlignment = Enum.TextXAlignment.Left
	killMessage.TextStrokeTransparency = 0.5
	killMessage.Font = Enum.Font.GothamBold
	killMessage.TextSize = 16
	killMessage.Text = message
	killMessage.Parent = killFeed
	
	local messageCount = 0
	for _, child in ipairs(killFeed:GetChildren()) do
		if child:IsA("TextLabel") then
			messageCount += 1
		end
	end
	
	if messageCount > WeaponConfig.KillFeed.MaxMessages then
		local oldest = killFeed:GetChildren()[1]
		if oldest then
			oldest:Destroy()
		end
	end
	
	task.delay(WeaponConfig.KillFeed.Duration, function()
		killMessage:Destroy()
	end)
end

GunController:Initialize()

return GunController