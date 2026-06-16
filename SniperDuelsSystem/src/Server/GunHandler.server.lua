--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")

local WeaponConfig = require(script.Parent.Parent.Config.WeaponConfig)
local RemoteEvents = require(script.Parent.Parent.ReplicatedStorage.RemoteEvents)
local MatchManager = require(script.MatchManager)

local GunHandler = {}

local bulletCache = {}
local activeBullets = {}

function GunHandler:FireWeapon(player: Player, weaponName: string, origin: Vector3, direction: Vector3)
	local matchData = MatchManager:GetPlayerData(player)
	if not matchData or not matchData.InMatch then
		return
	end
	
	local weaponConfig = WeaponConfig.Weapons[weaponName]
	if not weaponConfig then
		return
	end
	
	local character = player.Character
	if not character then
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	local bulletSpeed = weaponConfig.BulletSpeed
	local maxDistance = weaponConfig.MaxDistance
	local bulletDrop = weaponConfig.BulletDrop
	local baseDamage = weaponConfig.BaseDamage
	
	local hitResult, hitPosition, hitNormal = self:RaycastBullet(origin, direction, maxDistance, player)
	
	local targetPlayer = nil
	local hitPart = nil
	local headshot = false
	
	if hitResult then
		hitPart = hitResult.Instance
		if hitPart and hitPart.Parent then
			local model = hitPart.Parent
			if model:IsA("Model") then
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player and otherPlayer.Character == model then
						targetPlayer = otherPlayer
						if hitPart.Name == "Head" then
							headshot = true
						end
						break
					end
				end
			end
		end
	end
	
	if targetPlayer then
		local distance = (origin - hitPosition).Magnitude
		local damage = self:CalculateDamage(baseDamage, distance, weaponConfig, headshot)
		
		local targetCharacter = targetPlayer.Character
		if targetCharacter then
			local humanoid = targetCharacter:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:TakeDamage(damage)
				RemoteEvents.BulletHit:FireClient(player, "Hit", targetPlayer.Name, damage, headshot)
				RemoteEvents.BulletHit:FireClient(targetPlayer, "Damaged", damage, origin, direction)
				
				if humanoid.Health <= 0 then
					MatchManager:OnPlayerDeath(targetPlayer, player, headshot)
				end
			end
		end
	else
		RemoteEvents.BulletHit:FireClient(player, "Miss", hitPosition)
	end
	
	self:CreateBulletTrail(origin, hitPosition or origin + direction * maxDistance)
end

function GunHandler:RaycastBullet(origin: Vector3, direction: Vector3, maxDist: number, shooter: Player)
	local currentPos = origin
	local currentDir = direction.Unit
	local stepDistance = 50
	local gravity = workspace.Gravity * 0.2
	local steps = math.ceil(maxDist / stepDistance)
	
	for i = 1, steps do
		local targetPos = currentPos + currentDir * stepDistance
		local t = (i / steps)
		targetPos = targetPos - Vector3.new(0, gravity * t * t * 0.5, 0)
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		local filter = {shooter.Character}
		params.FilterDescendantsInstances = filter
		
		local result = workspace:Raycast(currentPos, targetPos - currentPos, params)
		
		if result then
			return result, result.Position, result.Normal
		end
		
		currentPos = targetPos
		currentDir = (targetPos - origin).Unit
	end
	
	local finalPos = currentPos + currentDir * stepDistance
	finalPos = finalPos - Vector3.new(0, gravity * steps * steps * 0.5, 0)
	
	return nil, finalPos, Vector3.new(0, 1, 0)
end

function GunHandler:CalculateDamage(baseDamage: number, distance: number, config: any, headshot: boolean)
	local falloffStart = config.DamageFalloffStart
	local falloffEnd = config.DamageFalloffEnd
	local minDamage = config.MinDamage
	
	local damageMultiplier = 1
	
	if distance > falloffStart then
		local falloffRange = falloffEnd - falloffStart
		if falloffRange > 0 then
			local distancePastStart = math.max(0, distance - falloffStart)
			local falloffFactor = math.min(1, distancePastStart / falloffRange)
			damageMultiplier = 1 - (1 - (minDamage / baseDamage)) * falloffFactor
		end
	end
	
	local finalDamage = baseDamage * damageMultiplier
	
	if headshot then
		finalDamage = finalDamage * config.HeadshotMultiplier
	end
	
	return finalDamage
end

function GunHandler:CreateBulletTrail(origin: Vector3, hitPos: Vector3)
	local trail = Instance.new("Part")
	trail.Name = "BulletTrail"
	trail.Size = Vector3.new(0.1, 0.1, (origin - hitPos).Magnitude)
	trail.CFrame = CFrame.new(origin, hitPos) * CFrame.new(0, 0, -(origin - hitPos).Magnitude / 2)
	trail.Anchored = true
	trail.CanCollide = false
	trail.Transparency = 0.5
	trail.Material = Enum.Material.Neon
	trail.Color = Color3.fromRGB(255, 255, 200)
	trail.Parent = workspace
	
	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = trail
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = trail
	attachment1.Position = Vector3.new(0, 0, trail.Size.Z)
	
	local trailEffect = Instance.new("Trail")
	trailEffect.Attachment0 = attachment0
	trailEffect.Attachment1 = attachment1
	trailEffect.Lifetime = 0.1
	trailEffect.Transparency = NumberSequence.new(0.4, 1)
	trailEffect.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
	trailEffect.Parent = trail
	
	Debris:AddItem(trail, 0.3)
end

RemoteEvents.FireBullet.OnServerEvent:Connect(function(player, weaponName, origin, direction)
	GunHandler:FireWeapon(player, weaponName, origin, direction)
end)

return GunHandler